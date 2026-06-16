// CP13 city task request layer.
// This is a producer/dispatcher shim over tg AI controllers, not a separate AI core.

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
	return priority + level_bonus - get_dist(pawn_turf, source_turf)

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
		if(!istype(security_area, /area/cyberpunk_city/security))
			continue
		for(var/turf/security_turf as anything in cyberpunk_area_turfs(security_area))
			if(security_turf && !isclosedturf(security_turf) && !isspaceturf(security_turf))
				return security_turf
	return null

/proc/cyberpunk_notify_ai_cargo_delivered(atom/cargo, mob/living/courier)
	if(!cargo || QDELETED(cargo))
		return FALSE
	if(hascall(cargo, "on_cyberpunk_ai_delivered"))
		return call(cargo, "on_cyberpunk_ai_delivered")(courier)
	return FALSE

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

/area
	/// City AI uses this to decide whether violence should trigger a broad security response.
	var/cyberpunk_safe_zone = FALSE
	/// CP13 world tags used by the storyteller, contracts, NPCs and map tooling.
	var/list/cyberpunk_world_tags
	/// Optional owner key for corporate/government territory logic.
	var/cyberpunk_world_owner
	/// Coarse violence response: none, weak, normal, high.
	var/cyberpunk_violence_control = "normal"
	/// Stable CP13 district id used by the storyteller and city systems.
	var/cyberpunk_district_id
	/// Display name for CP13 district analytics. Defaults to area name.
	var/cyberpunk_district_name
	/// Coarse district kind: street, safe, security, wasteland, corporate, etc.
	var/cyberpunk_district_kind = "generic"
	/// Numeric district bucket. The city core expects 1-9 until final map names are assigned.
	var/cyberpunk_district_index = 0
	/// Grid direction inside a city z-level: nw, n, ne, w, c, e, sw, s, se.
	var/cyberpunk_district_direction
	/// Passive danger added to storyteller district pressure.
	var/cyberpunk_district_base_danger = 0
	/// Round-local violence score reported by city AI and combat hooks.
	var/cyberpunk_round_violence_score = 0
	/// Round-local damage amount associated with violent incidents in this area.
	var/cyberpunk_round_damage_taken = 0
	/// Round-local severe incident counter.
	var/cyberpunk_round_critical_events = 0
	/// World time of last recorded violent incident.
	var/cyberpunk_round_last_violence_at = 0

/area/cyberpunk_city
	name = "Cyberpunk City"
	cyberpunk_district_id = "city"
	cyberpunk_district_name = "Cyberpunk City"
	cyberpunk_district_kind = "city"

/area/cyberpunk_city/street
	name = "Cyberpunk City Street"
	cyberpunk_district_id = "street"
	cyberpunk_district_name = "Cyberpunk City Street"
	cyberpunk_district_kind = "street"
	cyberpunk_district_base_danger = 5
	cyberpunk_world_tags = list("road")

/area/cyberpunk_city/safe
	name = "Cyberpunk City Safe Zone"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "safe"
	cyberpunk_district_name = "Cyberpunk City Safe Zone"
	cyberpunk_district_kind = "safe"
	cyberpunk_violence_control = "high"

/area/cyberpunk_city/security
	name = "Cyberpunk City Security"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "security"
	cyberpunk_district_name = "Cyberpunk City Security"
	cyberpunk_district_kind = "security"
	cyberpunk_world_tags = list("government")
	cyberpunk_world_owner = "government"
	cyberpunk_violence_control = "high"

/area/cyberpunk_city/wasteland
	name = "Cyberpunk City Wasteland"
	cyberpunk_district_id = "wasteland"
	cyberpunk_district_name = "Wasteland"
	cyberpunk_district_kind = "wasteland"
	cyberpunk_district_base_danger = 20
	cyberpunk_violence_control = "none"

/area/cyberpunk_city/district
	name = "Cyberpunk City District"
	cyberpunk_district_kind = "district"
	cyberpunk_district_base_danger = 8

/area/cyberpunk_city/district/district_01
	name = "Аква Квин"
	cyberpunk_district_id = "aqua_queen"
	cyberpunk_district_name = "Аква Квин"
	cyberpunk_district_kind = "marine"
	cyberpunk_district_index = 1
	cyberpunk_district_direction = "nw"
	cyberpunk_district_base_danger = 7

/area/cyberpunk_city/district/district_02
	name = "Нортфилд"
	cyberpunk_district_id = "northfield"
	cyberpunk_district_name = "Нортфилд"
	cyberpunk_district_kind = "port"
	cyberpunk_district_index = 2
	cyberpunk_district_direction = "n"
	cyberpunk_district_base_danger = 9

/area/cyberpunk_city/district/district_03
	name = "Чейсвинд"
	cyberpunk_district_id = "chasewind"
	cyberpunk_district_name = "Чейсвинд"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 3
	cyberpunk_district_direction = "ne"
	cyberpunk_district_base_danger = 18

/area/cyberpunk_city/district/district_04
	name = "Гранд Плаза"
	cyberpunk_district_id = "grand_plaza"
	cyberpunk_district_name = "Гранд Плаза"
	cyberpunk_district_kind = "government"
	cyberpunk_district_index = 4
	cyberpunk_district_direction = "w"
	cyberpunk_district_base_danger = 4

/area/cyberpunk_city/district/district_05
	name = "Даунтаун"
	cyberpunk_district_id = "downtown"
	cyberpunk_district_name = "Даунтаун"
	cyberpunk_district_kind = "residential"
	cyberpunk_district_index = 5
	cyberpunk_district_direction = "c"
	cyberpunk_district_base_danger = 6

/area/cyberpunk_city/district/district_06
	name = "Истбук"
	cyberpunk_district_id = "eastbook"
	cyberpunk_district_name = "Истбук"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 6
	cyberpunk_district_direction = "e"
	cyberpunk_district_base_danger = 18

/area/cyberpunk_city/district/district_07
	name = "Чайнатаун"
	cyberpunk_district_id = "chinatown"
	cyberpunk_district_name = "Чайнатаун"
	cyberpunk_district_kind = "ben"
	cyberpunk_district_index = 7
	cyberpunk_district_direction = "sw"
	cyberpunk_district_base_danger = 10

/area/cyberpunk_city/district/district_08
	name = "Блайтфорт"
	cyberpunk_district_id = "blightfort"
	cyberpunk_district_name = "Блайтфорт"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 8
	cyberpunk_district_direction = "s"
	cyberpunk_district_base_danger = 18

/area/cyberpunk_city/district/district_09
	name = "Веллрок"
	cyberpunk_district_id = "wellrock"
	cyberpunk_district_name = "Веллрок"
	cyberpunk_district_kind = "industrial"
	cyberpunk_district_index = 9
	cyberpunk_district_direction = "se"
	cyberpunk_district_base_danger = 12

/area/cyberpunk_city/metro
	name = "Cyberpunk City Metro"
	cyberpunk_district_id = "metro"
	cyberpunk_district_name = "Metro"
	cyberpunk_district_kind = "metro"
	cyberpunk_world_tags = list("metro", "underground")
	cyberpunk_district_base_danger = 8

/area/cyberpunk_city/road
	name = "Cyberpunk City Road"
	cyberpunk_district_id = "road"
	cyberpunk_district_name = "Road"
	cyberpunk_district_kind = "road"
	cyberpunk_world_tags = list("road")
	cyberpunk_district_base_danger = 6

/area/cyberpunk_city/canals
	name = "Cyberpunk City Canals"
	cyberpunk_district_id = "canals"
	cyberpunk_district_name = "Canals"
	cyberpunk_district_kind = "canals"
	cyberpunk_world_tags = list("canals", "underground")
	cyberpunk_district_base_danger = 12

/area/cyberpunk_city/warehouse
	name = "Cyberpunk City Warehouse"
	cyberpunk_district_id = "warehouse"
	cyberpunk_district_name = "Warehouse"
	cyberpunk_district_kind = "warehouse"
	cyberpunk_world_tags = list("warehouse")
	cyberpunk_district_base_danger = 10

/area/cyberpunk_city/corporate
	name = "Corporate Territory"
	cyberpunk_district_id = "corporate"
	cyberpunk_district_name = "Corporate Territory"
	cyberpunk_district_kind = "corporate"
	cyberpunk_world_tags = list("corporate")
	cyberpunk_violence_control = "high"
	cyberpunk_district_base_danger = 5

/area/cyberpunk_city/corporate/benn
	name = "Benn Territory"
	cyberpunk_district_id = "benn"
	cyberpunk_district_name = "Benn Territory"
	cyberpunk_world_owner = "benn"

/area/cyberpunk_city/corporate/ryaznov
	name = "Ryaznov Territory"
	cyberpunk_district_id = "ryaznov"
	cyberpunk_district_name = "Ryaznov Territory"
	cyberpunk_world_owner = "ryaznov"

/area/cyberpunk_city/corporate/starlight
	name = "Starlight Territory"
	cyberpunk_district_id = "starlight"
	cyberpunk_district_name = "Starlight Territory"
	cyberpunk_world_owner = "starlight"

/area/cyberpunk_city/government
	name = "Government Territory"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "government"
	cyberpunk_district_name = "Government Territory"
	cyberpunk_district_kind = "government"
	cyberpunk_world_tags = list("government")
	cyberpunk_world_owner = "government"
	cyberpunk_violence_control = "high"
	cyberpunk_district_base_danger = 3

/area/cyberpunk_city/slums
	name = "Cyberpunk City Slums"
	cyberpunk_district_id = "slums"
	cyberpunk_district_name = "Slums"
	cyberpunk_district_kind = "slums"
	cyberpunk_world_tags = list("slums")
	cyberpunk_violence_control = "weak"
	cyberpunk_district_base_danger = 18

/area/cyberpunk_city/roof
	name = "Cyberpunk City Roof"
	cyberpunk_district_id = "roof"
	cyberpunk_district_name = "Roof"
	cyberpunk_district_kind = "roof"
	cyberpunk_world_tags = list("roof")
	cyberpunk_district_base_danger = 11

/area/cyberpunk_city/underground
	name = "Cyberpunk City Underground"
	cyberpunk_district_id = "underground"
	cyberpunk_district_name = "Underground"
	cyberpunk_district_kind = "underground"
	cyberpunk_world_tags = list("underground")
	cyberpunk_violence_control = "weak"
	cyberpunk_district_base_danger = 14

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
	if(!target || target.density || isclosedturf(target) || isspaceturf(target))
		return FALSE
	for(var/atom/movable/content as anything in target)
		if(content.density)
			return FALSE
	return TRUE

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

SUBSYSTEM_DEF(cyberpunk_city_ai)
	name = "Cyberpunk City AI"
	wait = 15 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	var/max_bystanders = 18
	var/max_security = 6

/datum/controller/subsystem/cyberpunk_city_ai/fire(resumed)
	var/list/active_players = list()
	for(var/mob/living/player as anything in GLOB.player_list)
		if(player.client && player.stat != DEAD)
			active_players += player
	if(!length(active_players))
		return
	maintain_bystanders(active_players)
	maintain_security()

/datum/controller/subsystem/cyberpunk_city_ai/proc/count_city_npcs(typepath)
	var/count = 0
	for(var/mob/living/carbon/human/cyberpunk_npc/npc as anything in GLOB.mob_living_list)
		if(istype(npc, typepath) && npc.stat != DEAD)
			count++
	return count

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_bystanders(list/active_players)
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/bystander)
	if(current_count >= max_bystanders)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk_city/street, active_players, 6, 18)
	if(!spawn_turf)
		return
	new /mob/living/carbon/human/cyberpunk_npc/bystander(spawn_turf)

/datum/controller/subsystem/cyberpunk_city_ai/proc/maintain_security()
	var/current_count = count_city_npcs(/mob/living/carbon/human/cyberpunk_npc/security)
	if(current_count >= max_security)
		return
	var/turf/spawn_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk_city/security)
	if(!spawn_turf)
		return
	var/mob/living/carbon/human/cyberpunk_npc/security/security_npc = new(spawn_turf)
	var/turf/patrol_turf = cyberpunk_random_turf_in_area_type(/area/cyberpunk_city/street)
	if(patrol_turf)
		cyberpunk_order_city_ai(security_npc, CP_AI_TASK_PATROL, spawn_turf, patrol_turf, null)

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
		controller.cyberpunk_assign_city_task(CP_AI_TASK_PATROL, null, target, null, null, 30 SECONDS, source)
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
		ai += list(list(
			"ref" = cyberpunk_ai_ref(npc),
			"name" = npc.name,
			"type" = "[npc.type]",
			"managed" = cyberpunk_ai_is_city_managed(npc),
			"role" = controller.blackboard[BB_CP_AI_ROLE_PROFILE] || "unknown",
			"capabilities" = controller.blackboard[BB_CP_AI_CAPABILITIES] || 0,
			"task" = controller.blackboard[BB_CP_CITY_TASK] || "idle",
			"state" = controller.blackboard[BB_CP_CITY_TASK_STATE] || "-",
			"phantom" = controller.blackboard[BB_CP_PHANTOM_STATE] || "-",
			"location" = location ? "[location.x],[location.y],[location.z]" : "-",
			"target" = target ? "[target]" : "-",
			"threat" = threat ? "[threat]" : "-",
			"health" = npc.maxHealth ? round((npc.health / npc.maxHealth) * 100) : 0,
		))
	data["ai"] = ai
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
	SScyberpunk_round?.record_cyberpunk_district_violence(location || threat, threat_level, safe_zone ? "safe-zone violence" : "street violence")
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
