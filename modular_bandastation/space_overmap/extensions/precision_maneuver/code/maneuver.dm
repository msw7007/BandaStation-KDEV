/** Final actor/drive interlock shared by launch and native movement commit. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/can_maneuver(mob/living/user)
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/datum/stationtrauma_overmap/space/navigation = ship?.overmap
	return can_use(user) && navigation && !navigation.docked && !navigation.ship_docking && !length(navigation.carrier_docks) \
		&& (!ship.precision_move || ship.precision_move == pending_move) \
		&& !navigation.jump_target && !navigation.helm_engaged && !navigation.approach_started && !navigation.planning \
		&& ((!navigation.preparing && !navigation.relocating) || (pending_move && ship.precision_move == pending_move)) \
		&& navigation.speed <= ST_NAV_STOPPED_SPEED && world.time >= cooldown_until

/** Prepare a private site only after the actor accepts the fresh collision quote. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/placeLandingSpot()
	var/mob/living/operator = current_user
	if(pending_move || loading_site || !can_maneuver(operator))
		return FALSE
	var/obj/docking_port/stationary/port = make_target()
	if(!port)
		return FALSE
	var/datum/stationtrauma_overmap_site/space/site = target_site()
	var/datum/shuttle_impact/plan = new(vessel(), port, site.landing)
	if(!plan.build())
		to_chat(operator, span_warning(plan.problem || "Invalid landing footprint."))
		qdel(plan)
		qdel(port, force = TRUE)
		return FALSE
	var/revision = ++operation_revision
	pending_move = plan
	operator_ref = WEAKREF(operator)
	var/cost = maneuver_cost(plan)
	var/answer = tgui_alert(operator, "Collision: [round(plan.collision_percent, 0.1)]%. Energy: [round(cost / 1000)] kJ. [site.landing ? "Planetary over-budget impacts can wreck the hull." : "Station collision limit: 20%."]", "Precision manoeuvre", list("Jump", "Cancel"), timeout = 30 SECONDS)
	if(QDELETED(src))
		return FALSE
	if(answer != "Jump" || revision != operation_revision || pending_move != plan || !can_maneuver(operator) || target_site() != site || !site.berth || site.berth.z != port.z || site.landing != plan.planetary || charge < cost || !plan.validate())
		cancel_maneuver()
		return FALSE
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/datum/stationtrauma_overmap/space/navigation = ship.overmap
	if(ship.precision_site)
		navigation.sites -= ship.precision_site.id
		QDEL_NULL(ship.precision_site)
	var/datum/stationtrauma_overmap_site/space/precision/landing = new
	landing.id = "precision_[REF(port)]"
	landing.name = site.name
	landing.pos_x = site.pos_x
	landing.pos_y = site.pos_y
	landing.landing = site.landing
	landing.physical_docking = !site.landing
	landing.berth = port
	port.area_type = site.berth.area_type
	ship.precision_site = landing
	navigation.sites[landing.id] = landing
	navigation.selected_destination = landing.id
	navigation.preparing = TRUE
	ship.precision_move = plan
	drive_status = "Manoeuvre charging"
	remove_eye_control(operator)
	if(length(plan.impact_tiles))
		for(var/mob/listener as anything in SSmobs.clients_by_zlevel[port.z])
			to_chat(listener, span_userdanger("Emergency shuttle arrival in [DisplayTimeText(SHUTTLE_MANEUVER_TIME)]! Clear the marked landing zone!"))
		ship.create_ripples(port, SHUTTLE_MANEUVER_TIME)
	maneuver_timer = addtimer(CALLBACK(src, PROC_REF(finish_maneuver), revision), SHUTTLE_MANEUVER_TIME, TIMER_STOPPABLE)
	return TRUE

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/maneuver_cost(datum/shuttle_impact/plan)
	return SHUTTLE_MANEUVER_BASE_ENERGY + length(plan.pairs) * SHUTTLE_MANEUVER_TILE_ENERGY + length(plan.impact_tiles) * SHUTTLE_MANEUVER_IMPACT_ENERGY

/** Called by native movement only after its yielding preflight and second docking check. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/commit_maneuver(revision)
	var/mob/living/operator = operator_ref?.resolve()
	var/datum/stationtrauma_overmap_site/space/site = target_site()
	if(QDELETED(src) || operation_revision != revision || !pending_move || !can_maneuver(operator) || charge < maneuver_cost(pending_move) || !site?.berth || site.berth.z != pending_move.target.z || site.landing != pending_move.planetary || !pending_move.validate())
		return FALSE
	var/cost = maneuver_cost(pending_move)
	if(!pending_move.commit())
		return FALSE
	charge -= cost
	return TRUE

/** Retain local ownership through native yields; cancellation cannot interrupt an already copied hull. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/finish_maneuver(revision)
	maneuver_timer = null
	if(revision != operation_revision || !pending_move)
		return
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/datum/shuttle_impact/plan = pending_move
	var/datum/stationtrauma_overmap_site/space/precision/landing = ship?.precision_site
	if(!ship || !landing || !can_maneuver(operator_ref?.resolve()) || !plan.validate())
		cancel_maneuver()
		return
	var/datum/stationtrauma_overmap/space/navigation = ship.overmap
	var/success = FALSE
	var/exception/movement_failure
	try
		success = navigation.relocate(plan.target, CALLBACK(src, PROC_REF(commit_maneuver), revision))
	catch(var/exception/failure)
		movement_failure = failure
	success = success && !QDELETED(ship) && !QDELETED(navigation) && !QDELETED(landing)
	if(!QDELETED(ship))
		ship.precision_move = null
	if(!QDELETED(navigation))
		navigation.preparing = FALSE
	if(success)
		navigation.docked = landing
		landing.docking_owner = navigation
		navigation.pos_x = landing.pos_x
		navigation.pos_y = landing.pos_y
		navigation.stop("Precision landing complete")
		plan.aftermath()
	if(!QDELETED(src))
		pending_move = null
		operator_ref = null
		cooldown_until = success ? world.time + SHUTTLE_MANEUVER_COOLDOWN : cooldown_until
		drive_status = success ? "Landed" : "Manoeuvre cancelled"
	if(!success && !QDELETED(landing))
		if(!QDELETED(navigation))
			navigation.sites -= landing.id
		if(!QDELETED(ship))
			ship.precision_site = null
		qdel(landing)
	qdel(plan)
	if(movement_failure)
		throw movement_failure

/** Discard only this console's uncommitted reservation; never destroy a docked destination under the hull. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/cancel_maneuver()
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = pending_move?.ship || vessel()
	if(ship?.overmap?.relocating)
		return FALSE
	operation_revision++
	deltimer(maneuver_timer)
	maneuver_timer = null
	loading_site = FALSE
	if(pending_move)
		var/site_owns_port = ship?.precision_site?.berth == pending_move.target
		if(ship)
			if(ship.precision_move == pending_move)
				ship.precision_move = null
				ship.remove_ripples()
				if(ship.overmap)
					ship.overmap.preparing = FALSE
			if(site_owns_port && ship.overmap?.docked != ship.precision_site)
				ship.overmap?.sites.Remove(ship.precision_site.id)
				QDEL_NULL(ship.precision_site)
		if(!site_owns_port && pending_move.target)
			qdel(pending_move.target, force = TRUE)
		QDEL_NULL(pending_move)
	operator_ref = null
	drive_status = "Idle"
	return TRUE
