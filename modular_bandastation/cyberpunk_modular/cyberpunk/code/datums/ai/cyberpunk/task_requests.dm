// CP13 city task request layer.
// This is a producer/dispatcher shim over tg AI controllers, not a separate AI core.

/mob/living/var/next_cyberpunk_corporate_trespass_report = 0

/datum/cyberpunk_ai_task_request
	var/task_type = CP_AI_TASK_WORK
	var/atom/source
	var/atom/target
	var/atom/cargo
	var/contract_id
	var/atom/return_point
	var/required_capabilities = 0
	var/faction
	var/priority = 0
	var/duration = 30 SECONDS
	var/created_at = 0
	var/failure_reason

/datum/cyberpunk_ai_task_request/New(new_task_type, atom/new_source, atom/new_target, atom/new_cargo, new_contract_id, new_duration = 30 SECONDS, atom/new_return_point, new_required_capabilities = 0, new_faction = null)
	task_type = new_task_type || CP_AI_TASK_WORK
	source = new_source
	target = new_target
	cargo = new_cargo
	contract_id = new_contract_id
	duration = new_duration
	return_point = new_return_point
	required_capabilities = new_required_capabilities
	faction = new_faction
	created_at = world.time

/datum/cyberpunk_ai_task_request/proc/is_valid()
	if(QDELETED(source) || QDELETED(target) || QDELETED(cargo) || QDELETED(return_point))
		failure_reason = "target deleted"
		return FALSE
	if(task_type in list(CP_AI_TASK_DELIVERY, CP_AI_TASK_CONTRACT, CP_AI_TASK_CARGO))
		if(!target)
			failure_reason = "missing delivery target"
			return FALSE
	return TRUE

/datum/cyberpunk_ai_task_request/proc/can_use_controller(datum/ai_controller/controller)
	if(!controller?.pawn || QDELETED(controller.pawn))
		return FALSE
	if(controller.blackboard_key_exists(BB_CP_CITY_TASK))
		return FALSE
	if(required_capabilities && ((controller.blackboard[BB_CP_AI_CAPABILITIES] || 0) & required_capabilities) != required_capabilities)
		return FALSE
	if(!isnull(faction) && controller.blackboard[BB_CP_AI_FACTION] && controller.blackboard[BB_CP_AI_FACTION] != faction)
		return FALSE
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || living_pawn.client || living_pawn.stat == DEAD)
		return FALSE
	return TRUE

/datum/cyberpunk_ai_task_request/proc/score_controller(datum/ai_controller/controller)
	var/turf/pawn_turf = get_turf(controller.pawn)
	var/turf/source_turf = get_turf(source || target)
	if(!pawn_turf || !source_turf)
		return 0
	var/level_bonus = (controller.blackboard[BB_CP_AI_LEVEL] || 1) * 10
	return priority + level_bonus + controller.cyberpunk_role_task_weight(task_type) - get_dist(pawn_turf, source_turf)

/datum/cyberpunk_ai_task_request/proc/dispatch()
	if(!is_valid())
		return FALSE
	var/datum/ai_controller/best_controller
	var/best_score = -INFINITY
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		var/datum/ai_controller/controller = candidate.ai_controller
		if(!can_use_controller(controller))
			continue
		var/current_score = score_controller(controller)
		if(current_score <= best_score)
			continue
		best_score = current_score
		best_controller = controller
	if(!best_controller)
		failure_reason = "no available city AI"
		return FALSE
	best_controller.cyberpunk_assign_city_task(task_type, source, target, cargo, contract_id, duration, return_point)
	return TRUE

/proc/cyberpunk_dispatch_ai_task(datum/cyberpunk_ai_task_request/request)
	return request?.dispatch()

/proc/cyberpunk_request_ai_delivery(atom/source, atom/target, atom/cargo, contract_id = null, atom/return_point = null, required_capabilities = CP_AI_CAP_CARGO_SLOT)
	var/datum/cyberpunk_ai_task_request/request = new /datum/cyberpunk_ai_task_request(
		CP_AI_TASK_DELIVERY,
		source,
		target,
		cargo,
		contract_id,
		30 SECONDS,
		return_point,
		required_capabilities,
	)
	var/succeeded = request.dispatch()
	qdel(request)
	return succeeded

/proc/cyberpunk_request_ai_repair(atom/target, atom/source = null)
	var/datum/cyberpunk_ai_task_request/request = new /datum/cyberpunk_ai_task_request(
		CP_AI_TASK_REPAIR,
		source,
		target,
		null,
		null,
		2 MINUTES,
		source,
		CP_AI_CAP_REPAIR,
	)
	var/succeeded = request.dispatch()
	qdel(request)
	return succeeded

/proc/cyberpunk_request_ai_evacuate(mob/living/target, atom/destination, atom/source = null)
	if(!target || !destination)
		return FALSE
	var/datum/cyberpunk_ai_task_request/request = new /datum/cyberpunk_ai_task_request(
		CP_AI_TASK_DELIVERY,
		source || target,
		destination,
		target,
		null,
		2 MINUTES,
		source,
		CP_AI_CAP_HANDS,
	)
	var/succeeded = request.dispatch()
	qdel(request)
	return succeeded

/proc/cyberpunk_request_avi_delivery(atom/pickup, atom/dropoff, list/cargo_atoms)
	var/turf/pickup_turf = get_turf(pickup)
	var/turf/dropoff_turf = get_turf(dropoff)
	if(!pickup_turf || !dropoff_turf || !length(cargo_atoms))
		return FALSE
	var/obj/vehicle/ridden/cyberpunk/avi/avi = new(pickup_turf)
	if(!avi.start_cyberpunk_avi_delivery(pickup_turf, dropoff_turf, cargo_atoms))
		qdel(avi)
		return FALSE
	return TRUE

/proc/cyberpunk_request_mule_delivery(atom/pickup, atom/dropoff, list/cargo_atoms)
	var/turf/pickup_turf = get_turf(pickup)
	var/turf/dropoff_turf = get_turf(dropoff)
	if(!pickup_turf || !dropoff_turf || pickup_turf.z != dropoff_turf.z || !length(cargo_atoms))
		return FALSE
	var/obj/vehicle/ridden/cyberpunk/cargo/mule = new(pickup_turf)
	if(!mule.start_cyberpunk_mule_delivery(pickup_turf, dropoff_turf, cargo_atoms))
		qdel(mule)
		return FALSE
	return TRUE

/proc/cyberpunk_starlight_delivery_cost(transport, list/cargo_atoms)
	var/base_cost = transport == "mule" ? 35 : 75
	return base_cost + max(1, length(cargo_atoms)) * 15

/proc/cyberpunk_request_starlight_delivery(mob/living/customer, atom/pickup, atom/dropoff, list/cargo_atoms, transport = "avi")
	if(!pickup || !dropoff || !length(cargo_atoms))
		return FALSE
	transport = lowertext("[transport]")
	var/cost = cyberpunk_starlight_delivery_cost(transport, cargo_atoms)
	if(customer)
		var/datum/bank_account/customer_account = customer.get_bank_account()
		if(!customer_account || !customer_account.adjust_money(-cost, "Starlight [transport] delivery"))
			to_chat(customer, span_warning("Unable to pay Starlight delivery fee ([cost][MONEY_SYMBOL])."))
			return FALSE
	var/succeeded = transport == "mule" ? cyberpunk_request_mule_delivery(pickup, dropoff, cargo_atoms) : cyberpunk_request_avi_delivery(pickup, dropoff, cargo_atoms)
	if(!succeeded)
		if(customer)
			customer.get_bank_account()?.adjust_money(cost, "Starlight delivery refund")
		return FALSE
	SScyberpunk_corporations.record_cyberpunk_corporate_activity("starlight", "route", max(1, length(cargo_atoms)), cost, "manual [transport] delivery")
	return TRUE

/proc/cyberpunk_find_security_delivery_turf()
	for(var/area/security_area as anything in GLOB.areas)
		if(!istype(security_area, /area/cyberpunk/city/security))
			continue
		for(var/turf/security_turf as anything in cyberpunk_area_turfs(security_area))
			if(security_turf && !isclosedturf(security_turf) && !isspaceturf(security_turf))
				return security_turf
	return null

/proc/cyberpunk_is_police_custody_area(atom/location)
	var/area/current_area = get_area(location)
	return istype(current_area, /area/station/security) || istype(current_area, /area/cyberpunk/city/security) || istype(current_area, /area/cyberpunk/city/civic/police)

/proc/cyberpunk_find_security_record_for_mob(mob/living/person)
	if(!person || !GLOB.manifest)
		return null
	var/person_name = ckey(person.real_name || person.name)
	if(!person_name)
		return null
	for(var/datum/record/crew/record as anything in GLOB.manifest.general)
		if(record && ckey(record.name) == person_name)
			return record
	return null

/proc/cyberpunk_notify_ai_cargo_delivered(atom/cargo, mob/living/courier)
	if(!cargo || QDELETED(cargo))
		return FALSE
	if(hascall(cargo, "on_cyberpunk_ai_delivered"))
		return call(cargo, "on_cyberpunk_ai_delivered")(courier)
	return FALSE

/mob/living/proc/on_cyberpunk_ai_delivered(mob/living/courier)
	if(!istype(courier, /mob/living/carbon/human/cyberpunk_npc/security))
		return FALSE
	if(!cyberpunk_is_police_custody_area(src))
		return FALSE
	var/datum/record/crew/record = cyberpunk_find_security_record_for_mob(src)
	if(!record || !(record.wanted_status in list(WANTED_ARREST, WANTED_SUSPECT)))
		return FALSE
	record.wanted_status = WANTED_PRISONER
	update_matching_security_huds(record.name)
	return TRUE

/// Explicit city-AI threat hook for systems that own the hostile event.
/datum/ai_controller/proc/cyberpunk_report_threat(atom/threat, level = 1, reason = "threat")
	if(!threat || QDELETED(threat))
		return FALSE
	level = max(1, round(level))
	var/current_level = blackboard[BB_CP_THREAT_LEVEL] || 0
	if(level < current_level && blackboard[BB_CP_THREAT_TARGET])
		return FALSE
	set_blackboard_key(BB_CP_THREAT_TARGET, threat)
	set_blackboard_key(BB_CP_THREAT_LEVEL, level)
	if(reason)
		set_blackboard_key(BB_CP_CITY_TASK_RESULT, "threat: [reason]")
	return TRUE

/datum/ai_controller/proc/cyberpunk_call_for_help(atom/threat, reason = "help")
	var/mob/living/living_pawn = pawn
	if(!istype(living_pawn))
		return FALSE
	for(var/mob/living/candidate as anything in view(12, living_pawn))
		var/datum/ai_controller/controller = candidate.ai_controller
		if(!controller || controller == src || !controller.cyberpunk_has_capability(CP_AI_CAP_COMBAT))
			continue
		controller.cyberpunk_report_threat(threat, (blackboard[BB_CP_THREAT_LEVEL] || 1) + 1, reason)
	living_pawn.say("Need backup.")
	return TRUE

/mob/living/proc/cyberpunk_report_ai_threat(atom/threat, level = 1, reason = "threat")
	return ai_controller?.cyberpunk_report_threat(threat, level, reason)

/proc/cyberpunk_city_ai_mobs()
	var/list/results = list()
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(candidate.ai_controller)
			results += candidate
	return results

/proc/cyberpunk_ai_is_city_managed(mob/living/candidate)
	return candidate?.ai_controller?.blackboard_key_exists(BB_CP_AI_ROLE_PROFILE)

/proc/cyberpunk_is_safe_zone(atom/location)
	var/area/current_area = get_area(location)
	return current_area?.cyberpunk_safe_zone

/mob/living/proc/cyberpunk_report_violence_by(mob/living/attacker, level = 2)
	if(!attacker || attacker == src || QDELETED(attacker) || stat == DEAD)
		return FALSE
	return cyberpunk_report_city_violence(attacker, get_turf(src), cyberpunk_is_safe_zone(src), level)

/proc/cyberpunk_ai_ref(atom/target)
	return target ? REF(target) : null

/proc/cyberpunk_turf_is_clear_for_city_spawn(turf/target)
	if(!target || target.density || isclosedturf(target) || isspaceturf(target) || isgroundlessturf(target))
		return FALSE
	for(var/atom/movable/content as anything in target)
		if(content.density)
			return FALSE
	return TRUE

/proc/cyberpunk_turf_is_city_district_ground(turf/target)
	if(!cyberpunk_turf_is_clear_for_city_spawn(target))
		return FALSE
	return istype(get_area(target), /area/cyberpunk/city/district)

/proc/cyberpunk_random_turf_in_area_type(area_type, list/near_mobs, min_distance = 0, max_distance = INFINITY)
	var/list/candidates = list()
	for(var/area/current_area as anything in GLOB.areas)
		if(!istype(current_area, area_type))
			continue
		for(var/turf/current_turf as anything in cyberpunk_area_turfs(current_area))
			if(!cyberpunk_turf_is_clear_for_city_spawn(current_turf))
				continue
			if(length(near_mobs))
				var/near_someone = FALSE
				for(var/mob/living/nearby as anything in near_mobs)
					var/dist = get_dist(current_turf, nearby)
					if(dist >= min_distance && dist <= max_distance)
						near_someone = TRUE
						break
				if(!near_someone)
					continue
			candidates += current_turf
	if(!length(candidates))
		return null
	return pick(candidates)

/proc/cyberpunk_random_city_roam_turf(mob/living/carbon/human/cyberpunk_npc/npc, min_distance = 4, max_distance = 14)
	if(!npc)
		return null
	var/list/candidates = list()
	var/area/current_area = get_area(npc)
	if(istype(current_area, /area/cyberpunk/city/district))
		for(var/turf/current_turf as anything in cyberpunk_area_turfs(current_area))
			if(!cyberpunk_turf_is_city_district_ground(current_turf))
				continue
			var/turf_distance = get_dist(npc, current_turf)
			if(turf_distance < min_distance || turf_distance > max_distance)
				continue
			candidates += current_turf
	if(length(candidates))
		return pick(candidates)
	return cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, list(npc), min_distance, max_distance)

/proc/cyberpunk_turf_is_city_road_ground(turf/target)
	if(!cyberpunk_turf_is_clear_for_city_spawn(target))
		return FALSE
	return istype(get_area(target), /area/cyberpunk/city/road)

/obj/effect/cyberpunk_traffic_node
	name = "city traffic node"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/node_kind = "pedestrian"
	var/list/linked_nodes = list()
	var/obj/machinery/cyberpunk_traffic_light/traffic_light

/obj/effect/cyberpunk_traffic_node/Initialize(mapload)
	. = ..()
	for(var/obj/machinery/cyberpunk_traffic_light/light in get_turf(src))
		traffic_light = light
		break
	SScyberpunk_city_ai?.traffic_nodes += src

/obj/effect/cyberpunk_traffic_node/Destroy()
	SScyberpunk_city_ai?.traffic_nodes -= src
	linked_nodes = null
	traffic_light = null
	return ..()

/obj/effect/cyberpunk_traffic_node/proc/link_to(obj/effect/cyberpunk_traffic_node/other)
	if(!other || other == src)
		return FALSE
	linked_nodes |= other
	other.linked_nodes |= src
	return TRUE

/obj/effect/cyberpunk_traffic_node/proc/pedestrian_can_enter()
	return !traffic_light || traffic_light.pedestrian_green

/obj/effect/cyberpunk_traffic_node/proc/vehicle_can_enter()
	return !traffic_light || !traffic_light.pedestrian_green

/obj/effect/cyberpunk_traffic_node/vehicle
	node_kind = "vehicle"

/obj/machinery/cyberpunk_traffic_light
	name = "city traffic light"
	desc = "An automated city signal that alternates pedestrian and vehicle flow."
	icon = 'icons/obj/tram/crossing_signal.dmi'
	icon_state = "green"
	anchored = TRUE
	density = FALSE
	var/pedestrian_green = TRUE
	var/next_switch_at = 0
	var/switch_interval = 20 SECONDS

/obj/machinery/cyberpunk_traffic_light/Initialize(mapload)
	. = ..()
	next_switch_at = world.time + rand(5 SECONDS, switch_interval)
	SScyberpunk_city_ai?.traffic_lights += src
	update_cyberpunk_traffic_light_icon()

/obj/machinery/cyberpunk_traffic_light/Destroy()
	SScyberpunk_city_ai?.traffic_lights -= src
	return ..()

/obj/machinery/cyberpunk_traffic_light/proc/process_cyberpunk_traffic_light()
	if(world.time < next_switch_at)
		return
	pedestrian_green = !pedestrian_green
	next_switch_at = world.time + switch_interval
	update_cyberpunk_traffic_light_icon()

/obj/machinery/cyberpunk_traffic_light/proc/update_cyberpunk_traffic_light_icon()
	icon_state = pedestrian_green ? "green" : "red"
	set_light(1.5, 0.8, pedestrian_green ? COLOR_GREEN : COLOR_RED)

/obj/effect/cyberpunk_traffic_vehicle
	name = "city traffic"
	desc = "A lightweight city traffic proxy."
	icon = 'icons/obj/toys/car.dmi'
	icon_state = "car"
	anchored = FALSE
	density = FALSE
	var/obj/effect/cyberpunk_traffic_node/vehicle/current_node
	var/obj/effect/cyberpunk_traffic_node/vehicle/target_node
	var/obj/effect/cyberpunk_traffic_node/vehicle/previous_node
	var/next_move_at = 0
	var/route_hops = 0
	var/max_route_hops = 18

/obj/effect/cyberpunk_traffic_vehicle/Initialize(mapload, obj/effect/cyberpunk_traffic_node/vehicle/start_node)
	. = ..()
	current_node = start_node
	if(current_node)
		forceMove(get_turf(current_node))
	color = pick("#54d6ff", "#ffcf54", "#ff6b6b", "#b28cff", "#d7dde8")
	SScyberpunk_city_ai?.traffic_vehicles += src
	pick_next_node()

/obj/effect/cyberpunk_traffic_vehicle/Destroy()
	SScyberpunk_city_ai?.traffic_vehicles -= src
	current_node = null
	target_node = null
	previous_node = null
	return ..()

/obj/effect/cyberpunk_traffic_vehicle/proc/pick_next_node()
	if(!current_node || !length(current_node.linked_nodes))
		target_node = null
		return FALSE
	var/list/candidates = list()
	for(var/obj/effect/cyberpunk_traffic_node/vehicle/candidate as anything in current_node.linked_nodes)
		if(istype(candidate) && candidate != previous_node)
			candidates += candidate
	if(!length(candidates))
		for(var/obj/effect/cyberpunk_traffic_node/vehicle/candidate as anything in current_node.linked_nodes)
			if(istype(candidate))
				candidates += candidate
	target_node = length(candidates) ? pick(candidates) : null
	return !!target_node

/obj/effect/cyberpunk_traffic_vehicle/proc/process_cyberpunk_traffic()
	if(world.time < next_move_at)
		return
	next_move_at = world.time + 1 SECONDS
	if(!target_node || QDELETED(target_node))
		pick_next_node()
		return
	if(!target_node.vehicle_can_enter())
		return
	if(get_dist(src, target_node) <= 0)
		previous_node = current_node
		current_node = target_node
		route_hops++
		if(route_hops >= max_route_hops)
			qdel(src)
			return
		pick_next_node()
		return
	var/turf/next_turf = get_step(src, get_dir(src, target_node))
	if(next_turf && !cyberpunk_turf_is_city_road_ground(next_turf) && get_dist(src, target_node) > 1)
		current_node = SScyberpunk_city_ai?.nearest_traffic_node(src, "vehicle", 4)
		pick_next_node()
		return
	if(next_turf && SScyberpunk_city_ai?.traffic_turf_blocked(next_turf, src))
		return
	dir = get_dir(src, target_node)
	step_towards(src, target_node)

/proc/cyberpunk_goap_extend_traffic_world_state(datum/ai_controller/controller, list/state)
	if(controller.blackboard[BB_CP_CITY_TASK] != "traffic_roam")
		return
	state["traffic_task"] = TRUE
	var/obj/effect/cyberpunk_traffic_node/target_node = controller.blackboard[BB_CP_ROUTE_TARGET]
	if(istype(target_node) && !target_node.pedestrian_can_enter())
		state["traffic_clear"] = FALSE

/proc/cyberpunk_goap_extend_traffic_actions(list/actions)
	actions += new /datum/cyberpunk_goap_action("wait_traffic_light", list("traffic_task" = TRUE, "target_exists" = TRUE, "traffic_clear" = FALSE), list("traffic_clear" = TRUE), 1)

/proc/cyberpunk_goap_queue_traffic_action(datum/ai_controller/controller, action_id)
	if(action_id != "wait_traffic_light")
		return FALSE
	controller.queue_behavior(/datum/ai_behavior/cyberpunk_wait_traffic_light)
	return TRUE

/datum/ai_behavior/cyberpunk_wait_traffic_light
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_wait_traffic_light/perform(seconds_per_tick, datum/ai_controller/controller)
	var/obj/effect/cyberpunk_traffic_node/target_node = controller.blackboard[BB_CP_ROUTE_TARGET]
	if(!istype(target_node) || target_node.pedestrian_can_enter())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	controller.set_blackboard_key(BB_CP_CITY_TASK_RESULT, "waiting for pedestrian green")
	return AI_BEHAVIOR_DELAY

SUBSYSTEM_DEF(cyberpunk_city_ai)
	name = "Cyberpunk City AI"
	wait = 5 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	ss_flags = SS_NO_INIT
	var/max_bystanders = 18
	var/max_runners = 4
	var/max_workers = 5
	var/max_security = 6
	var/max_corporate_specialists_per_corp = 1
	var/max_traffic_nodes = 48
	var/max_traffic_lights = 12
	var/max_traffic_vehicles = 4
	var/traffic_interest_range = 24
	var/traffic_network_ready = FALSE
	var/list/traffic_nodes = list()
	var/list/traffic_lights = list()
	var/list/traffic_vehicles = list()
	var/city_vendors_enabled = TRUE
	var/list/vendor_home_points = list()

/datum/controller/subsystem/cyberpunk_city_ai/fire(resumed)
	var/list/active_players = list()
	for(var/mob/living/player as anything in GLOB.player_list)
		if(player.client && player.stat != DEAD)
			active_players += player
	if(!length(active_players))
		return
	ensure_traffic_network()
	process_traffic_lights()
	maintain_traffic_vehicles(active_players)
	process_traffic_vehicles(active_players)
	maintain_bystanders(active_players)
	maintain_runners(active_players)
	maintain_workers(active_players)
	maintain_security()
	maintain_corporate_specialists(active_players)
	process_city_vendors(active_players)
	process_city_needs(active_players)
	process_corporate_specialist_work(active_players)
	process_corporate_trespass(active_players)
	maintain_roaming(active_players)
	process_ambient_speech(active_players)

/datum/controller/subsystem/cyberpunk_city_ai/proc/ensure_traffic_network()
	if(traffic_network_ready)
		return
	traffic_network_ready = TRUE
	if(length(traffic_nodes))
		link_traffic_nodes()
		return
	create_automatic_traffic_network()
	link_traffic_nodes()

/datum/controller/subsystem/cyberpunk_city_ai/proc/create_automatic_traffic_network()
	for(var/area/current_area as anything in GLOB.areas)
		if(!istype(current_area, /area/cyberpunk/city/district))
			continue
		for(var/turf/current_turf as anything in cyberpunk_area_turfs(current_area))
			if(length(traffic_lights) >= max_traffic_lights)
				break
			if(!cyberpunk_turf_is_city_district_ground(current_turf))
				continue
			var/road_adjacent = FALSE
			for(var/direction in list(NORTH, SOUTH, EAST, WEST))
				if(istype(get_area(get_step(current_turf, direction)), /area/cyberpunk/city/road))
					road_adjacent = TRUE
					break
			if(!road_adjacent || ((current_turf.x + current_turf.y) % 7) || nearest_traffic_light(current_turf, 6))
				continue
			var/obj/machinery/cyberpunk_traffic_light/light = new(current_turf)
			var/obj/effect/cyberpunk_traffic_node/node = new(current_turf)
			node.traffic_light = light
	for(var/area/current_area as anything in GLOB.areas)
		if(!istype(current_area, /area/cyberpunk/city/road))
			continue
		for(var/turf/current_turf as anything in cyberpunk_area_turfs(current_area))
			if(length(traffic_nodes) >= max_traffic_nodes)
				break
			if(!cyberpunk_turf_is_city_road_ground(current_turf) || ((current_turf.x + current_turf.y) % 6) || nearest_traffic_node(current_turf, "vehicle", 5))
				continue
			var/obj/effect/cyberpunk_traffic_node/vehicle/node = new(current_turf)
			node.traffic_light = nearest_traffic_light(current_turf, 3)

/datum/controller/subsystem/cyberpunk_city_ai/proc/link_traffic_nodes()
	for(var/obj/effect/cyberpunk_traffic_node/node as anything in traffic_nodes)
		if(QDELETED(node))
			continue
		node.linked_nodes = list()
	for(var/obj/effect/cyberpunk_traffic_node/node as anything in traffic_nodes)
		if(QDELETED(node))
			continue
		if(!node.traffic_light)
			node.traffic_light = nearest_traffic_light(node, node.node_kind == "vehicle" ? 3 : 0)
		var/list/candidates = list()
		for(var/obj/effect/cyberpunk_traffic_node/other as anything in traffic_nodes)
			if(QDELETED(other) || node == other || node.node_kind != other.node_kind || node.z != other.z)
				continue
			if(get_dist(node, other) > (node.node_kind == "vehicle" ? 8 : 12))
				continue
			if(node.node_kind == "vehicle" && node.x != other.x && node.y != other.y)
				continue
			candidates += other
		for(var/i in 1 to min(3, length(candidates)))
			var/obj/effect/cyberpunk_traffic_node/best_node
			var/best_distance = INFINITY
			for(var/obj/effect/cyberpunk_traffic_node/candidate as anything in candidates)
				var/distance = get_dist(node, candidate)
				if(distance >= best_distance)
					continue
				best_node = candidate
				best_distance = distance
			if(!best_node)
				break
			node.link_to(best_node)
			candidates -= best_node

/datum/controller/subsystem/cyberpunk_city_ai/proc/nearest_traffic_light(atom/location, max_distance = 8)
	var/obj/machinery/cyberpunk_traffic_light/best_light
	var/best_distance = INFINITY
	for(var/obj/machinery/cyberpunk_traffic_light/light as anything in traffic_lights)
		if(QDELETED(light) || light.z != location.z)
			continue
		var/distance = get_dist(location, light)
		if(distance > max_distance || distance >= best_distance)
			continue
		best_light = light
		best_distance = distance
	return best_light

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_traffic_lights()
	for(var/obj/machinery/cyberpunk_traffic_light/light as anything in traffic_lights)
		if(QDELETED(light))
			traffic_lights -= light
			continue
		light.process_cyberpunk_traffic_light()

/datum/controller/subsystem/cyberpunk_city_ai/proc/traffic_turf_blocked(turf/target_turf, atom/ignore)
	if(!target_turf)
		return TRUE
	for(var/obj/effect/cyberpunk_traffic_vehicle/vehicle as anything in target_turf)
		if(vehicle != ignore)
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_city_ai/proc/traffic_near_players(atom/location, list/active_players)
	if(!location || !length(active_players))
		return FALSE
	for(var/mob/living/player as anything in active_players)
		if(player.z == location.z && get_dist(player, location) <= traffic_interest_range)
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_traffic_vehicles(list/active_players)
	var/live_count = 0
	for(var/obj/effect/cyberpunk_traffic_vehicle/vehicle as anything in traffic_vehicles)
		if(!QDELETED(vehicle))
			live_count++
	if(live_count >= max_traffic_vehicles)
		return
	var/list/vehicle_nodes = list()
	for(var/obj/effect/cyberpunk_traffic_node/vehicle/node as anything in traffic_nodes)
		if(istype(node) && length(node.linked_nodes) && traffic_near_players(node, active_players) && !traffic_turf_blocked(get_turf(node), null))
			vehicle_nodes += node
	if(length(vehicle_nodes))
		new /obj/effect/cyberpunk_traffic_vehicle(null, pick(vehicle_nodes))

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_traffic_vehicles(list/active_players)
	for(var/obj/effect/cyberpunk_traffic_vehicle/vehicle as anything in traffic_vehicles)
		if(QDELETED(vehicle))
			traffic_vehicles -= vehicle
			continue
		if(!traffic_near_players(vehicle, active_players))
			qdel(vehicle)
			continue
		vehicle.process_cyberpunk_traffic()

/datum/controller/subsystem/cyberpunk_city_ai/proc/count_city_npcs(typepath)
	var/count = 0
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/npc = candidate
		if(istype(npc, typepath) && npc.stat != DEAD)
			count++
	return count

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_bystanders(list/active_players)
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/bystander)
	if(current_count >= max_bystanders)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, active_players, 6, 18)
	if(!spawn_turf)
		return
	new /mob/living/carbon/human/cyberpunk_npc/bystander(spawn_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_runners(list/active_players)
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/runner)
	if(current_count >= max_runners)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, active_players, 8, 20)
	if(spawn_turf)
		new /mob/living/carbon/human/cyberpunk_npc/runner(spawn_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_workers(list/active_players)
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/worker)
	if(current_count >= max_workers)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, active_players, 8, 20)
	if(spawn_turf)
		new /mob/living/carbon/human/cyberpunk_npc/worker(spawn_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_city_needs(list/active_players)
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/worker))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/worker/worker = candidate
		if(!can_roam(worker))
			continue
		var/atom/repair_target = find_nearby_city_repair_target(worker)
		if(repair_target)
			worker.ai_controller.cyberpunk_assign_city_task(CP_AI_TASK_REPAIR, worker, repair_target, null, null, 30 SECONDS, worker)

/datum/controller/subsystem/cyberpunk_city_ai/proc/find_nearby_city_repair_target(mob/living/carbon/human/cyberpunk_npc/worker)
	for(var/atom/movable/candidate as anything in view(8, worker))
		if(!candidate.uses_integrity || QDELETED(candidate))
			continue
		if(candidate.get_integrity() >= candidate.max_integrity)
			continue
		var/area/current_area = get_area(candidate)
		if(!istype(current_area, /area/cyberpunk/city))
			continue
		return candidate
	return null

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_security()
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/security)
	if(current_count >= max_security)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/security)
	if(!spawn_turf)
		return
	var/mob/living/carbon/human/cyberpunk_npc/security/security_npc = new(spawn_turf)
	var/turf/patrol_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district)
	if(patrol_turf)
		cyberpunk_order_city_ai(security_npc, CP_AI_TASK_PATROL, spawn_turf, patrol_turf, null)

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_corporate_specialists(list/active_players)
	for(var/corporation_id in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT))
		if(count_corporate_specialists(corporation_id) >= max_corporate_specialists_per_corp)
			continue
		if(!find_corporate_data_terminal(corporation_id))
			continue
		var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(corporate_area_type(corporation_id), active_players, 0, INFINITY) || cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, active_players, 8, 20)
		if(!spawn_turf)
			continue
		var/specialist_type = corporate_specialist_type(corporation_id)
		if(specialist_type)
			new specialist_type(spawn_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/count_corporate_specialists(corporation_id)
	var/count = 0
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/corporate_specialist))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/corporate_specialist/specialist = candidate
		if(QDELETED(specialist) || specialist.stat == DEAD)
			continue
		if(specialist.cyberpunk_corporation_id == corporation_id)
			count++
	return count

/datum/controller/subsystem/cyberpunk_city_ai/proc/corporate_specialist_type(corporation_id)
	switch(corporation_id)
		if(CYBERPUNK_CORP_BENN)
			return /mob/living/carbon/human/cyberpunk_npc/corporate_specialist/benn
		if(CYBERPUNK_CORP_RYAZNOV)
			return /mob/living/carbon/human/cyberpunk_npc/corporate_specialist/ryaznov
		if(CYBERPUNK_CORP_STARLIGHT)
			return /mob/living/carbon/human/cyberpunk_npc/corporate_specialist/starlight
	return null

/datum/controller/subsystem/cyberpunk_city_ai/proc/corporate_area_type(corporation_id)
	switch(corporation_id)
		if(CYBERPUNK_CORP_BENN)
			return /area/cyberpunk/city/corporate/benn
		if(CYBERPUNK_CORP_RYAZNOV)
			return /area/cyberpunk/city/corporate/ryaznov
		if(CYBERPUNK_CORP_STARLIGHT)
			return /area/cyberpunk/city/corporate/starlight
	return /area/cyberpunk/city/corporate

/datum/controller/subsystem/cyberpunk_city_ai/proc/find_corporate_data_terminal(corporation_id, atom/nearby = null)
	var/obj/machinery/computer/corporate_data_terminal/best_terminal
	var/best_distance = INFINITY
	for(var/obj/machinery/computer/corporate_data_terminal/terminal as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/corporate_data_terminal))
		if(QDELETED(terminal) || terminal.corporation_id != corporation_id)
			continue
		if(!nearby)
			return terminal
		var/distance = get_dist(nearby, terminal)
		if(distance >= best_distance)
			continue
		best_terminal = terminal
		best_distance = distance
	return best_terminal

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_corporate_specialist_work(list/active_players)
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/corporate_specialist))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/corporate_specialist/specialist = candidate
		if(QDELETED(specialist) || !specialist.cyberpunk_corporation_id || !can_roam(specialist))
			continue
		var/obj/machinery/computer/corporate_data_terminal/terminal = find_corporate_data_terminal(specialist.cyberpunk_corporation_id, specialist)
		if(!terminal)
			continue
		specialist.ai_controller.cyberpunk_assign_city_task(CP_AI_TASK_WORK, null, terminal, null, null, 2 MINUTES, terminal)

/proc/cyberpunk_corporate_area_id(atom/location)
	var/area/current_area = get_area(location)
	if(!istype(current_area, /area/cyberpunk))
		return null
	var/area/cyberpunk/cyber_area = current_area
	if(!cyber_area.cyberpunk_corporate_protected || cyber_area.cyberpunk_corporate_public)
		return null
	return cyber_area.cyberpunk_corporation_id || cyber_area.cyberpunk_world_owner

/proc/cyberpunk_living_has_corporate_zone_access(mob/living/person, corporation_id)
	if(!istype(person) || !corporation_id)
		return FALSE
	if(istype(person, /mob/living/carbon/human/cyberpunk_npc/security))
		return TRUE
	for(var/access_level in list("basic", "agent", "specialist", "head"))
		if(person.has_cyberpunk_crypto_access(cyberpunk_corporation_access_id(corporation_id, access_level)))
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_corporate_trespass(list/active_players)
	for(var/mob/living/person as anything in GLOB.mob_living_list)
		if(QDELETED(person) || person.stat == DEAD || world.time < person.next_cyberpunk_corporate_trespass_report)
			continue
		var/corporation_id = cyberpunk_corporate_area_id(person)
		if(!corporation_id || cyberpunk_living_has_corporate_zone_access(person, corporation_id))
			continue
		var/turf/public_turf = find_corporate_public_turf(corporation_id, person)
		if(!public_turf)
			continue
		person.next_cyberpunk_corporate_trespass_report = world.time + 30 SECONDS
		var/mob/living/carbon/human/cyberpunk_npc/security/security = find_nearby_corporate_security(person)
		if(security)
			cyberpunk_order_city_ai(security, CP_AI_TASK_GUARD, person, public_turf, person)
		report_corporate_trespass_to_police(person, corporation_id)

/datum/controller/subsystem/cyberpunk_city_ai/proc/find_corporate_public_turf(corporation_id, atom/origin)
	var/turf/best_turf
	var/best_distance = INFINITY
	for(var/area/current_area as anything in GLOB.areas)
		if(!istype(current_area, /area/cyberpunk))
			continue
		var/area/cyberpunk/cyber_area = current_area
		if(cyber_area.cyberpunk_corporate_protected && !cyber_area.cyberpunk_corporate_public)
			continue
		if(cyber_area.cyberpunk_corporation_id && cyber_area.cyberpunk_corporation_id != corporation_id)
			continue
		if(!istype(cyber_area, /area/cyberpunk/city/district) && !cyber_area.cyberpunk_corporate_public)
			continue
		for(var/turf/current_turf as anything in cyberpunk_area_turfs(cyber_area))
			if(!cyberpunk_turf_is_clear_for_city_spawn(current_turf))
				continue
			var/distance = origin ? get_dist(origin, current_turf) : 0
			if(distance >= best_distance)
				continue
			best_turf = current_turf
			best_distance = distance
	return best_turf

/datum/controller/subsystem/cyberpunk_city_ai/proc/find_nearby_corporate_security(atom/origin)
	var/mob/living/carbon/human/cyberpunk_npc/security/best_security
	var/best_distance = INFINITY
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/security))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/security/security = candidate
		if(QDELETED(security) || security.stat == DEAD || !security.ai_controller || security.ai_controller.blackboard_key_exists(BB_CP_CITY_TASK))
			continue
		var/distance = get_dist(origin, security)
		if(distance >= best_distance)
			continue
		best_security = security
		best_distance = distance
	return best_security

/datum/controller/subsystem/cyberpunk_city_ai/proc/report_corporate_trespass_to_police(mob/living/person, corporation_id)
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		var/datum/ai_controller/controller = candidate.ai_controller
		if(!controller || controller.blackboard[BB_CP_AI_ROLE_PROFILE] != CP_AI_ROLE_POLICE)
			continue
		controller.cyberpunk_report_threat(person, 2, "[corporation_id] corporate trespass")

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_roaming(list/active_players)
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/npc = candidate
		if(!can_roam(npc))
			continue
		if(assign_traffic_roam(npc))
			continue
		var/turf/roam_turf = cyberpunk_random_city_roam_turf(npc)
		if(!roam_turf)
			continue
		npc.ai_controller.cyberpunk_assign_city_task(CP_AI_TASK_PATROL, null, roam_turf, null, null, rand(1 SECONDS, 3 SECONDS))

/datum/controller/subsystem/cyberpunk_city_ai/proc/assign_traffic_roam(mob/living/carbon/human/cyberpunk_npc/npc)
	if(!traffic_network_ready || istype(npc, /mob/living/carbon/human/cyberpunk_npc/security))
		return FALSE
	var/obj/effect/cyberpunk_traffic_node/current_node = nearest_traffic_node(npc, "pedestrian", 14)
	if(!current_node || !length(current_node.linked_nodes))
		return FALSE
	var/list/candidates = list()
	for(var/obj/effect/cyberpunk_traffic_node/candidate as anything in current_node.linked_nodes)
		if(istype(candidate) && candidate.node_kind == "pedestrian")
			candidates += candidate
	if(!length(candidates))
		return FALSE
	var/obj/effect/cyberpunk_traffic_node/target_node = pick(candidates)
	npc.ai_controller.cyberpunk_assign_city_task("traffic_roam", current_node, target_node, null, null, rand(1 SECONDS, 3 SECONDS))
	return TRUE

/datum/controller/subsystem/cyberpunk_city_ai/proc/nearest_traffic_node(atom/location, node_kind, max_distance = 12)
	var/obj/effect/cyberpunk_traffic_node/best_node
	var/best_distance = INFINITY
	for(var/obj/effect/cyberpunk_traffic_node/node as anything in traffic_nodes)
		if(QDELETED(node) || node.node_kind != node_kind || node.z != location.z)
			continue
		var/distance = get_dist(location, node)
		if(distance > max_distance || distance >= best_distance)
			continue
		best_node = node
		best_distance = distance
	return best_node

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_ambient_speech(list/active_players)
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/npc = candidate
		npc.cyberpunk_try_ambient_speech(active_players)

/datum/controller/subsystem/cyberpunk_city_ai/proc/can_roam(mob/living/carbon/human/cyberpunk_npc/npc)
	if(!npc || QDELETED(npc) || npc.cyberpunk_stationary_npc || npc.client || npc.stat != CONSCIOUS)
		return FALSE
	if(istype(npc, /mob/living/carbon/human/cyberpunk_npc/vendor))
		return FALSE
	if(!(npc.mobility_flags & MOBILITY_MOVE) || npc.pulledby || npc.buckled)
		return FALSE
	var/datum/ai_controller/controller = npc.ai_controller
	if(!controller || controller.blackboard_key_exists(BB_CP_CITY_TASK) || controller.blackboard_key_exists(BB_CP_THREAT_TARGET))
		return FALSE
	if(controller.blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return FALSE
	return TRUE

/datum/controller/subsystem/cyberpunk_city_ai/proc/nearest_vendor_home(atom/location, max_distance = 18)
	var/turf/location_turf = get_turf(location)
	if(!location_turf)
		return null
	var/turf/best_turf
	var/best_distance = INFINITY
	for(var/obj/effect/landmark/cyberpunk_npc_trader_home/home as anything in vendor_home_points)
		if(QDELETED(home) || home.z != location_turf.z)
			continue
		var/distance = get_dist(location_turf, home)
		if(distance > max_distance || distance >= best_distance)
			continue
		best_turf = get_turf(home)
		best_distance = distance
	return best_turf

/datum/controller/subsystem/cyberpunk_city_ai/proc/city_vendors_should_open()
	var/phase = SScyberpunk_round?.cyberpunk_round_phase
	return city_vendors_enabled && phase != "night"

/datum/controller/subsystem/cyberpunk_city_ai/proc/close_city_vendors()
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/vendor))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/vendor/vendor = candidate
		if(!QDELETED(vendor))
			vendor.cyberpunk_set_vendor_open(FALSE)

/datum/controller/subsystem/cyberpunk_city_ai/proc/process_city_vendors(list/active_players)
	var/should_open = city_vendors_should_open()
	var/current_day = SScyberpunk_round?.cyberpunk_round_day || 1
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/vendor))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/vendor/vendor = candidate
		if(QDELETED(vendor) || !vendor.cyberpunk_vendor_night_cycle)
			continue
		vendor.cyberpunk_vendor_restock(current_day)
		ensure_vendor_points(vendor)
		var/turf/target_turf = should_open ? vendor.cyberpunk_vendor_stall_turf : vendor.cyberpunk_vendor_home_turf
		if(!target_turf)
			continue
		var/at_target = get_dist(vendor, target_turf) <= 1
		vendor.cyberpunk_set_vendor_open(should_open && at_target)
		if(at_target || !vendor.ai_controller || vendor.ai_controller.blackboard_key_exists(BB_CP_CITY_TASK))
			continue
		vendor.ai_controller.cyberpunk_assign_city_task(CP_AI_TASK_PATROL, null, target_turf, null, null, 2 MINUTES, target_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/ensure_vendor_points(mob/living/carbon/human/cyberpunk_npc/vendor/vendor)
	if(!vendor.cyberpunk_vendor_stall_turf)
		vendor.cyberpunk_vendor_stall_turf = get_turf(vendor)
	if(!vendor.cyberpunk_vendor_home_turf)
		vendor.cyberpunk_vendor_home_turf = nearest_vendor_home(vendor.cyberpunk_vendor_stall_turf, 18) || cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, null, 0, INFINITY) || vendor.cyberpunk_vendor_stall_turf

/proc/cyberpunk_order_city_ai(mob/living/npc, task_type, atom/source, atom/target, atom/cargo)
	var/datum/ai_controller/controller = npc?.ai_controller
	if(!controller)
		return FALSE
	if(task_type == CP_AI_TASK_REPAIR)
		if(!target?.uses_integrity)
			return FALSE
		controller.cyberpunk_assign_city_task(CP_AI_TASK_REPAIR, null, target, null, null, 2 MINUTES, source)
		return TRUE
	if(task_type == CP_AI_TASK_FLEE)
		controller.cyberpunk_report_threat(target || source, 3, "manual order")
		return TRUE
	if(task_type == CP_AI_TASK_GUARD)
		var/turf/security_turf = target ? get_turf(target) : cyberpunk_find_security_delivery_turf()
		var/mob/living/escort_target = cargo
		if(!security_turf || !istype(escort_target))
			return FALSE
		controller.cyberpunk_assign_city_task(CP_AI_TASK_GUARD, escort_target, security_turf, escort_target, null, 2 MINUTES, source || security_turf)
		return TRUE
	if(task_type == CP_AI_TASK_DELIVERY)
		controller.cyberpunk_assign_city_task(CP_AI_TASK_DELIVERY, source || cargo, target, cargo, null, 2 MINUTES, source)
		return TRUE
	if(task_type == CP_AI_TASK_PATROL)
		controller.cyberpunk_assign_city_task(CP_AI_TASK_PATROL, null, target, null, null, 2 SECONDS, source)
		return TRUE
	if(task_type == CP_AI_TASK_EMERGENCY_RESPONSE)
		controller.cyberpunk_assign_city_task(CP_AI_TASK_EMERGENCY_RESPONSE, null, target, null, null, 2 SECONDS, source)
		controller.set_blackboard_key(BB_CP_CITY_TASK_RESULT, "responding to council emergency")
		return TRUE
	return FALSE

/datum/cyberpunk_city_ai_console
	var/mob/living/owner

/datum/cyberpunk_city_ai_console/New(mob/living/new_owner)
	owner = new_owner

/datum/cyberpunk_city_ai_console/Destroy(force)
	owner = null
	return ..()

/datum/cyberpunk_city_ai_console/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_city_ai_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkCityAI", "AI Debug Command")
		ui.open()

/datum/cyberpunk_city_ai_console/ui_data(mob/user)
	var/list/data = list()
	var/list/ai = list()
	for(var/mob/living/npc as anything in cyberpunk_city_ai_mobs())
		var/datum/ai_controller/controller = npc.ai_controller
		var/atom/target = controller.blackboard[BB_CP_ROUTE_TARGET] || controller.blackboard[BB_CP_CARGO_RECEIVER]
		var/atom/threat = controller.blackboard[BB_CP_THREAT_TARGET]
		var/turf/location = get_turf(npc) || controller.blackboard[BB_CP_PHANTOM_APPROX_TURF]
		var/list/goap_plan = controller.blackboard[BB_CP_GOAP_PLAN]
		ai += list(list(
			"ref" = cyberpunk_ai_ref(npc),
			"name" = npc.name,
			"type" = "[npc.type]",
			"managed" = cyberpunk_ai_is_city_managed(npc),
			"role" = controller.blackboard[BB_CP_AI_ROLE_PROFILE] || "unknown",
			"capabilities" = controller.blackboard[BB_CP_AI_CAPABILITIES] || 0,
			"task" = controller.blackboard[BB_CP_CITY_TASK] || "idle",
			"state" = controller.blackboard[BB_CP_CITY_TASK_STATE] || "-",
			"successCondition" = controller.blackboard[BB_CP_CITY_TASK_SUCCESS_CONDITION] || "-",
			"failureCondition" = controller.blackboard[BB_CP_CITY_TASK_FAILURE_CONDITION] || "-",
			"cargoType" = controller.blackboard[BB_CP_CARGO_TYPE] || "-",
			"cargoAmount" = controller.blackboard[BB_CP_CARGO_AMOUNT] || 0,
			"goapAction" = controller.blackboard[BB_CP_GOAP_CURRENT_ACTION] || "-",
			"goapPlan" = islist(goap_plan) && length(goap_plan) ? jointext(goap_plan, " -> ") : "-",
			"phantom" = controller.blackboard[BB_CP_PHANTOM_STATE] || "-",
			"phantomHealth" = controller.blackboard[BB_CP_PHANTOM_HEALTH_STATE] || "-",
			"phantomRisk" = controller.blackboard[BB_CP_PHANTOM_RISK_RESULT] || "-",
			"zMethod" = controller.blackboard[BB_CP_ROUTE_Z_METHOD] || "-",
			"proxy" = controller.blackboard[BB_CP_ROUTE_OBSERVATION_PROXY] || "-",
			"location" = location ? "[location.x],[location.y],[location.z]" : "-",
			"target" = target ? "[target]" : "-",
			"threat" = threat ? "[threat]" : "-",
			"health" = npc.maxHealth ? round((npc.health / npc.maxHealth) * 100) : 0,
		))
	data["ai"] = ai
	data["trafficNodes"] = length(SScyberpunk_city_ai?.traffic_nodes || list())
	data["trafficLights"] = length(SScyberpunk_city_ai?.traffic_lights || list())
	data["trafficVehicles"] = length(SScyberpunk_city_ai?.traffic_vehicles || list())
	data["cityVendorsEnabled"] = SScyberpunk_city_ai?.city_vendors_enabled
	var/vendor_count = 0
	var/open_vendors = 0
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		if(!istype(candidate, /mob/living/carbon/human/cyberpunk_npc/vendor))
			continue
		var/mob/living/carbon/human/cyberpunk_npc/vendor/vendor = candidate
		if(QDELETED(vendor))
			continue
		vendor_count++
		if(vendor.cyberpunk_vendor_active)
			open_vendors++
	data["vendorCount"] = vendor_count
	data["openVendors"] = open_vendors
	data["safeZone"] = cyberpunk_is_safe_zone(user)
	var/turf/user_turf = get_turf(user)
	data["userLocation"] = user_turf ? "[user_turf.x],[user_turf.y],[user_turf.z]" : "-"
	return data

/datum/cyberpunk_city_ai_console/proc/get_selected_ai(list/params)
	var/ref = params["ai"]
	if(!ref || ref == "auto")
		return null
	var/mob/living/npc = locate(ref)
	if(!npc?.ai_controller)
		return null
	return npc

/datum/cyberpunk_city_ai_console/proc/order_ai_or_dispatch(mob/living/npc, task_type, atom/source, atom/target, atom/cargo)
	if(npc)
		return cyberpunk_order_city_ai(npc, task_type, source, target, cargo)
	switch(task_type)
		if(CP_AI_TASK_REPAIR)
			return cyberpunk_request_ai_repair(target, source)
		if(CP_AI_TASK_DELIVERY)
			if(isliving(cargo))
				return cyberpunk_request_ai_evacuate(cargo, target, source)
			return cyberpunk_request_ai_delivery(cargo || source, target, cargo, null, source, CP_AI_CAP_HANDS)
		if(CP_AI_TASK_GUARD)
			return cyberpunk_request_ai_evacuate(cargo, target, source)
		if(CP_AI_TASK_PATROL)
			var/datum/cyberpunk_ai_task_request/request = new /datum/cyberpunk_ai_task_request(CP_AI_TASK_PATROL, source, target, null, null, 30 SECONDS, source, 0)
			var/succeeded = request.dispatch()
			qdel(request)
			return succeeded
		if(CP_AI_TASK_EMERGENCY_RESPONSE)
			var/datum/cyberpunk_ai_task_request/request = new /datum/cyberpunk_ai_task_request(CP_AI_TASK_EMERGENCY_RESPONSE, source, target, null, null, 30 SECONDS, source, CP_AI_CAP_COMBAT)
			request.priority = 100
			var/succeeded = request.dispatch()
			qdel(request)
			return succeeded
	return FALSE

/datum/cyberpunk_city_ai_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!istype(user))
		return TRUE
	var/mob/living/npc = get_selected_ai(params)
	var/atom/target
	var/atom/cargo
	switch(action)
		if("refresh")
			return TRUE
		if("toggle_vendors")
			if(SScyberpunk_city_ai)
				SScyberpunk_city_ai.city_vendors_enabled = !SScyberpunk_city_ai.city_vendors_enabled
				if(!SScyberpunk_city_ai.city_vendors_enabled)
					SScyberpunk_city_ai.close_city_vendors()
			return TRUE
		if("threat")
			target = tgui_input_list(user, "Threat target.", "City AI", view(12, user))
			if(!target)
				return TRUE
			if(npc)
				npc.cyberpunk_report_ai_threat(target, 2, "manual order")
			else
				cyberpunk_report_city_violence(target, get_turf(target), TRUE, 3)
		if("repair")
			target = tgui_input_list(user, "Damaged target.", "City AI", view(12, user))
			if(!target)
				return TRUE
			if(!order_ai_or_dispatch(npc, CP_AI_TASK_REPAIR, user, target, null))
				to_chat(user, span_warning("No available repair AI."))
		if("evacuate")
			cargo = tgui_input_list(user, "Mob to evacuate.", "City AI", view(12, user))
			if(!isliving(cargo))
				return TRUE
			target = tgui_input_list(user, "Destination beacon/point.", "City AI", view(12, user))
			if(!target)
				return TRUE
			if(!order_ai_or_dispatch(npc, CP_AI_TASK_DELIVERY, cargo, target, cargo))
				to_chat(user, span_warning("No available evacuation AI."))
		if("escort")
			cargo = tgui_input_list(user, "Restrained mob.", "City AI", view(12, user))
			if(!isliving(cargo))
				return TRUE
			var/mob/living/escort_target = cargo
			if(!HAS_TRAIT(escort_target, TRAIT_RESTRAINED))
				to_chat(user, span_warning("Target is not restrained."))
				return TRUE
			target = tgui_input_list(user, "Destination, or cancel to use security.", "City AI", view(12, user))
			target ||= cyberpunk_find_security_delivery_turf()
			if(!target || !order_ai_or_dispatch(npc, CP_AI_TASK_GUARD, user, target, cargo))
				to_chat(user, span_warning("No available escort AI."))
		if("deliver")
			cargo = tgui_input_list(user, "Object to deliver.", "City AI", view(12, user))
			if(!isobj(cargo))
				return TRUE
			target = tgui_input_list(user, "Destination beacon/point.", "City AI", view(12, user))
			if(!target)
				return TRUE
			if(!order_ai_or_dispatch(npc, CP_AI_TASK_DELIVERY, cargo, target, cargo))
				to_chat(user, span_warning("No available delivery AI."))
		if("avi_delivery")
			var/obj/item/cyberpunk_delivery_beacon/beacon = tgui_input_list(user, "Delivery beacon.", "Starlight Delivery", view(12, user))
			if(!istype(beacon))
				return TRUE
			beacon.open_cyberpunk_delivery_menu(user)
		if("patrol")
			target = tgui_input_list(user, "Point to patrol.", "City AI", view(12, user))
			if(!target)
				return TRUE
			if(!order_ai_or_dispatch(npc, CP_AI_TASK_PATROL, user, target, null))
				to_chat(user, span_warning("No available patrol AI."))
	SStgui.update_uis(src)
	return TRUE

/mob/living/verb/cyberpunk_city_ai_panel()
	set name = "AI Debug Panel"
	set desc = "Show AI state and issue debug orders."
	set category = "IC"

	var/datum/cyberpunk_city_ai_console/console = new(src)
	console.ui_interact(src)

/mob/living/verb/cyberpunk_issue_city_ai_order()
	set name = "Test Starlight Beacon"
	set desc = "Create and activate a Starlight delivery beacon for testing."
	set category = "IC"

	var/obj/item/cyberpunk_delivery_beacon/beacon = new(get_turf(src))
	put_in_hands(beacon)
	beacon.open_cyberpunk_delivery_menu(src)

/proc/cyberpunk_report_city_violence(atom/threat, atom/location, safe_zone = FALSE, level = null)
	if(!threat)
		return FALSE
	var/handled = FALSE
	var/threat_level = isnull(level) ? (safe_zone ? 3 : 2) : level
	SScyberpunk_round?.record_cyberpunk_district_violence(location || threat, threat_level, safe_zone ? "safe-zone violence" : "district violence")
	for(var/mob/living/candidate as anything in GLOB.mob_living_list)
		var/datum/ai_controller/controller = candidate.ai_controller
		if(!controller?.cyberpunk_has_capability(CP_AI_CAP_COMBAT))
			continue
		if(!safe_zone && location && get_dist(candidate, location) > 12)
			continue
		controller.cyberpunk_report_threat(threat, threat_level, safe_zone ? "safe-zone violence" : "nearby violence")
		handled = TRUE
	return handled

/obj/item/cyberpunk_delivery_beacon
	name = "Starlight delivery beacon"
	desc = "A compact route beacon for paid Starlight cargo delivery."
	icon = 'icons/obj/machines/beacon.dmi'
	icon_state = "beacon"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/cyberpunk_delivery_beacon/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	open_cyberpunk_delivery_menu(user)

/obj/item/cyberpunk_delivery_beacon/proc/open_cyberpunk_delivery_menu(mob/living/living_user)
	if(!istype(living_user))
		return
	var/transport = tgui_input_list(living_user, "Transport type.", "Starlight Delivery", list("AVI", "Mule"))
	if(!transport)
		return
	var/use_mode = tgui_input_list(living_user, "Beacon role.", "Starlight Delivery", list("This beacon is pickup", "This beacon is dropoff"))
	if(!use_mode)
		return
	var/atom/pickup
	var/atom/dropoff
	if(use_mode == "This beacon is pickup")
		pickup = src
		dropoff = tgui_input_list(living_user, "Dropoff beacon/point.", "Starlight Delivery", view(12, living_user))
	else
		dropoff = src
		pickup = tgui_input_list(living_user, "Pickup beacon/source.", "Starlight Delivery", view(12, living_user))
	if(!pickup || !dropoff)
		return
	var/cargo_count = tgui_input_number(living_user, "How many cargo objects?", "Starlight Delivery", 1, 1, 8)
	if(!cargo_count)
		return
	var/list/cargo_atoms = list()
	for(var/i in 1 to cargo_count)
		var/atom/movable/selected_cargo = tgui_input_list(living_user, "Cargo #[i].", "Starlight Delivery", view(12, living_user))
		if(!selected_cargo)
			continue
		cargo_atoms += selected_cargo
	if(!length(cargo_atoms))
		return
	var/cost = cyberpunk_starlight_delivery_cost(lowertext(transport), cargo_atoms)
	if(tgui_alert(living_user, "Start [transport] delivery for [cost][MONEY_SYMBOL]?", "Starlight Delivery", list("Yes", "No")) != "Yes")
		return
	if(cyberpunk_request_starlight_delivery(living_user, pickup, dropoff, cargo_atoms, lowertext(transport)))
		to_chat(living_user, span_notice("Starlight accepts the delivery route."))
	else
		to_chat(living_user, span_warning("Starlight delivery request failed."))
