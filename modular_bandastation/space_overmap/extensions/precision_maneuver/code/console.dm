/** Separate precision console; all long-range flight remains on the existing overmap helm. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision
	name = "precision manoeuvre control"
	desc = "A short-range positioning drive and landing camera."
	icon_screen = "shuttle"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/shuttle_maneuver
	req_access = list(ACCESS_CENT_GENERAL)
	shuttleId = "precision_vessel"
	view_range = 9
	locked_traits = list(ZTRAIT_RESERVED, ZTRAIT_CENTCOM)
	/// Stored joules are paid for from the real cable grid below the console.
	var/charge = 0
	/// Crew switch for drawing energy from the local grid.
	var/charging = FALSE
	/// Earliest allowed start after a successful arrival.
	var/cooldown_until = 0
	/// Known overmap site ID, never a client-supplied physical coordinate.
	var/selected_site_id
	/// Destination map loading is exclusive until its revision changes.
	var/loading_site = FALSE
	/// One operation owns its plan, timer and actor. Changes to selection invalidate an outstanding async request.
	var/operation_revision = 0
	/// Owned until cancellation or the native move's cleanup.
	var/datum/shuttle_impact/pending_move
	/// Actor whose access and physical reach are rechecked at commit.
	var/datum/weakref/operator_ref
	/// Stoppable approach timer; native movement itself cannot be interrupted halfway.
	var/maneuver_timer
	/// Preview scans are limited independently from camera movement.
	var/preview_after = 0
	/// Cached display result only, never authorises movement.
	var/last_preview = SHUTTLE_DOCKER_BLOCKED
	/// Server-owned drive status shown by TGUI.
	var/drive_status = "Idle"

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/post_machine_initialize()
	. = ..()
	begin_processing()

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/on_set_is_operational(old_value)
	. = ..()
	if(is_operational)
		begin_processing()

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/Destroy()
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = pending_move?.ship || shuttle_port
	if(ship?.overmap?.relocating)
		// The already committed native move owns its local plan until cleanup returns.
		pending_move = null
	else
		cancel_maneuver()
	operator_ref = null
	shuttle_port = null
	return ..()

/** Resolve only the ship physically containing this console, not another hull with a matching name. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/vessel()
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = SSshuttle.get_containing_shuttle(src)
	return istype(ship) && ship.is_in_shuttle_bounds(src) ? ship : null

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/can_use(mob/living/user)
	return !QDELETED(user) && anchored && !panel_open && !(machine_stat & (BROKEN|NOPOWER)) && allowed(user) && can_interact(user) && vessel()

/** No map-wide processing: one local power node and the current camera actor. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/process(seconds_per_tick)
	if(current_user && !can_use(current_user))
		remove_eye_control(current_user)
	if(!charging || seconds_per_tick <= 0 || pending_move || machine_stat & (NOPOWER|BROKEN) || panel_open)
		return
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	if(!ship?.overmap)
		return
	var/turf/tile = get_turf(src)
	var/obj/structure/cable/cable = tile.get_cable_node(CABLE_LAYER_2)
	var/datum/powernet/grid = cable?.powernet
	if(!grid)
		return
	var/maximum = SHUTTLE_MANEUVER_BASE_ENERGY + max(1, ship.hull_mass) * (SHUTTLE_MANEUVER_TILE_ENERGY + SHUTTLE_MANEUVER_IMPACT_ENERGY)
	var/received = min(SHUTTLE_MANEUVER_CHARGE_POWER * seconds_per_tick, max(0, grid.avail - grid.load), max(0, maximum - charge))
	grid.load += received
	charge += received

/** Use only known destinations in the same system and within short-range approach distance. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/target_site(id = selected_site_id)
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/datum/stationtrauma_overmap/space/navigation = ship?.overmap
	var/datum/stationtrauma_overmap_site/space/site = navigation?.sites[id]
	if(QDELETED(site) || site.failed || site.host || istype(site, /datum/stationtrauma_overmap_site/space/precision) || !navigation.knows_site(site))
		return null
	if(navigation.distance_to(site) > SHUTTLE_MANEUVER_RANGE + navigation.radius + site.radius)
		return null
	return site.berth || site.awaits_map() ? site : null

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/attack_hand(mob/user, list/modifiers)
	ui_interact(user)

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(!can_use(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShuttleManeuver", name)
		ui.open()

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/ui_data(mob/user)
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/list/targets = list()
	var/datum/stationtrauma_overmap/space/navigation = ship?.overmap
	if(navigation)
		for(var/list/record as anything in navigation.known_sites())
			var/datum/stationtrauma_overmap_site/space/site = target_site(record["id"])
			if(site)
				targets += list(list("id" = site.id, "name" = navigation.site_label(site), "planet" = site.landing))
	var/required = SHUTTLE_MANEUVER_BASE_ENERGY + max(1, ship?.hull_mass || 0) * SHUTTLE_MANEUVER_TILE_ENERGY
	return list(
		"targets" = targets,
		"selected" = selected_site_id,
		"charge" = charge,
		"required" = required,
		"charging" = charging,
		"busy" = !!pending_move || loading_site,
		"cooldown" = max(0, (cooldown_until - world.time) / (1 SECONDS)),
		"status" = drive_status,
		"ready" = !!navigation && !navigation.docked && !navigation.preparing && !navigation.relocating && !navigation.helm_engaged && navigation.speed <= ST_NAV_STOPPED_SPEED,
	)

/obj/machinery/computer/camera_advanced/shuttle_docker/precision/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !can_use(ui.user))
		return .
	switch(action)
		if("charge")
			charging = !charging
			return TRUE
		if("select")
			if(pending_move || loading_site || !istext(params["id"]) || !target_site(params["id"]))
				return FALSE
			selected_site_id = params["id"]
			operation_revision++
			unset_machine()
			begin_processing()
			QDEL_NULL(eyeobj)
			return TRUE
		if("aim")
			if(!pending_move && !loading_site)
				INVOKE_ASYNC(src, PROC_REF(aim), ui.user)
			return TRUE
		if("cancel")
			return cancel_maneuver()
	return FALSE

/** Deferred destination loading is followed by the same permission, selection and proximity checks. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/aim(mob/living/user)
	var/datum/stationtrauma_overmap_site/space/site = target_site()
	if(!site || !can_use(user) || pending_move || loading_site || (current_user && current_user != user))
		return FALSE
	loading_site = TRUE
	drive_status = "Loading destination"
	var/revision = operation_revision
	site.load_map()
	UNTIL(QDELETED(src) || QDELETED(site) || !site.loading_map || revision != operation_revision)
	if(QDELETED(src) || revision != operation_revision)
		return FALSE
	loading_site = FALSE
	if(!can_use(user) || target_site() != site || QDELETED(site.berth))
		drive_status = "Destination unavailable"
		return FALSE
	shuttle_port = vessel()
	z_lock = list(site.berth.z)
	if(!eyeobj && !CreateEye())
		return FALSE
	if(current_user && current_user != user)
		return FALSE
	give_eye_control(user)
	eyeobj.setLoc(site.entrance || get_turf(site.berth), TRUE)
	drive_status = "Select landing position"
	return TRUE

/** Preview at a bounded rate; actual placement never trusts the cached preview. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/checkLandingSpot()
	if(world.time < preview_after)
		return last_preview
	preview_after = world.time + SHUTTLE_MANEUVER_PREVIEW_INTERVAL
	var/obj/docking_port/stationary/preview = make_target()
	if(!preview)
		return SHUTTLE_DOCKER_BLOCKED
	var/datum/stationtrauma_overmap_site/space/site = target_site()
	var/datum/shuttle_impact/plan = new(vessel(), preview, site?.landing)
	last_preview = plan.build() ? SHUTTLE_DOCKER_LANDING_CLEAR : SHUTTLE_DOCKER_BLOCKED
	var/mob/eye/camera/remote/shuttle_docker/eye = eyeobj
	for(var/image/picture as anything in eye.placement_images)
		var/list/offset = eye.placement_images[picture]
		picture.loc = locate(eye.x + offset[1], eye.y + offset[2], eye.z)
		picture.icon_state = "white"
		picture.color = last_preview == SHUTTLE_DOCKER_BLOCKED ? COLOR_RED : plan.impact_tiles[picture.loc] ? COLOR_YELLOW : COLOR_GREEN
	for(var/image/picture as anything in eye.extra_images)
		var/list/offset = eye.extra_images[picture]
		picture.loc = locate(eye.x + offset[1], eye.y + offset[2], eye.z)
	qdel(plan)
	qdel(preview, force = TRUE)
	return last_preview

/** Unregistered temporary port; creation exposes neither arbitrary Z-levels nor public docking destinations. */
/obj/machinery/computer/camera_advanced/shuttle_docker/precision/proc/make_target()
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship = vessel()
	var/datum/stationtrauma_overmap_site/space/site = target_site()
	if(!ship || !eyeobj || !site?.berth || eyeobj.z != site.berth.z || SSmapping.level_has_any_trait(eyeobj.z, locked_traits))
		return null
	var/obj/docking_port/stationary/port = new /obj/docking_port/stationary
	port.unregister()
	port.width = ship.width
	port.height = ship.height
	port.dwidth = ship.dwidth
	port.dheight = ship.dheight
	port.setDir(eyeobj.dir)
	port.forceMove(locate(eyeobj.x - x_offset, eyeobj.y - y_offset, eyeobj.z))
	return port

/obj/item/circuitboard/computer/shuttle_maneuver
	name = "precision manoeuvre control"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/camera_advanced/shuttle_docker/precision
