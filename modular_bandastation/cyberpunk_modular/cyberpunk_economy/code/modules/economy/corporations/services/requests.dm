//CYBERPUNK CORPORATIONS - service request queue.

#define BB_CP_SERVICE_Z_EDGE "cp_service_z_edge"
#define BB_CP_SERVICE_Z_REJECTED "cp_service_z_rejected"
#define BB_CP_SERVICE_TARGET_Z "cp_service_target_z"

/mob/living/basic/cyberpunk_corporate_agent
	name = "corporate field agent"
	desc = "A short-term corporate representative dispatched to close a paid service request."
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = "nanotrasen"
	health = 60
	maxHealth = 60
	speed = 0
	density = FALSE
	basic_mob_flags = DEL_ON_DEATH
	habitable_atmos = null
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	ai_controller = null
	var/corporation_id
	var/service_id
	var/agent_title = "field agent"
	var/service_lifetime = 35 SECONDS

/mob/living/basic/cyberpunk_corporate_agent/Initialize(mapload, new_corporation_id, new_service_id, customer_name)
	. = ..()
	corporation_id = new_corporation_id
	service_id = new_service_id
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(corporation)
		name = "[corporation.name] [agent_title]"
		desc = "A temporary [corporation.name] representative assigned to service '[service_id]' for [customer_name || "a client"]."
		add_atom_colour(cyberpunk_corporate_agent_color(corporation_id), FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, service_lifetime)

/datum/cyberpunk_corporation
	var/list/observation_targets = list()
	var/list/personal_service_days = list()
	var/observation_vendor_cursor = 0
	var/list/service_sources = list()

/obj/machinery/proc/register_cyberpunk_service_source()
	var/area/territory = get_area(src)
	var/corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(src))
	corporation_id ||= cyberpunk_corporate_area_id(src) || territory?.cyberpunk_world_owner
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(corporation)
		corporation.service_sources[REF(src)] = WEAKREF(src)

/proc/cyberpunk_needs_technical_service(obj/target)
	if(!target || QDELETED(target))
		return FALSE
	if((target.resistance_flags & ON_FIRE) || (target.uses_integrity && target.get_integrity() < target.max_integrity))
		return TRUE
	var/obj/machinery/machine = target
	if(istype(machine) && machine.cyberpunk_machine_wear > 0)
		return TRUE
	var/obj/item/forcefield_projector/projector = target
	if(istype(projector) && projector.shield_integrity < projector.max_shield_integrity)
		return TRUE
	var/obj/machinery/modular_shield_generator/shield = target
	return istype(shield) && shield.stored_strength < shield.max_strength

/proc/cyberpunk_service_business(atom/location)
	for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
		var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
		if(business?.owner_character_key && business.contains_atom(location))
			return business
	return null

/proc/cyberpunk_service_apartment(atom/location)
	var/area/location_area = get_area(location)
	for(var/apartment_id in SScyberpunk_property.cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.get_cyberpunk_apartment(apartment_id)
		if(apartment?.owner_character_key && apartment.get_apartment_area() == location_area)
			return apartment
	return null

/proc/cyberpunk_service_covers_premises(obj/machinery/source, atom/target, datum/cyberpunk_business/business, datum/cyberpunk_apartment/apartment)
	var/obj/machinery/vending/vendor = source
	if(!istype(vendor) || !vendor.is_operational || !vendor.has_corporate_vending_module() || vendor.cyberpunk_corporate_vendor_id != CYBERPUNK_CORP_RYAZNOV || get_area(source) != get_area(target))
		return FALSE
	if(business?.owner_character_key && business.contains_atom(source) && business.contains_atom(target))
		return TRUE
	return apartment?.owner_character_key && apartment.get_apartment_area() == get_area(source)

/datum/cyberpunk_corporation/proc/is_ryaznov_service_product(obj/target)
	return id == CYBERPUNK_CORP_RYAZNOV && SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(target)) == id

/// Two local searches per corporation and fire, rather than a global patient/machine scan.
/datum/cyberpunk_corporation/proc/process_service_observation()
	if(!service_auto_enabled || !length(service_sources))
		return
	var/observation_edict = id == CYBERPUNK_CORP_BENN ? "benn_med_observation" : "ryaznov_tech_observation"
	if((id != CYBERPUNK_CORP_BENN && id != CYBERPUNK_CORP_RYAZNOV) || !has_edict(observation_edict))
		return
	for(var/target_key in observation_targets.Copy())
		if(observation_targets[target_key] <= world.time)
			observation_targets -= target_key
	var/list/vendors = service_sources.Copy()
	for(var/search_index in 1 to min(2, length(vendors)))
		observation_vendor_cursor = (observation_vendor_cursor % length(vendors)) + 1
		var/datum/weakref/vendor_ref = vendors[vendors[observation_vendor_cursor]]
		var/obj/machinery/vendor = vendor_ref?.resolve()
		if(!vendor)
			service_sources -= vendors[observation_vendor_cursor]
			continue
		if(!vendor.is_operational)
			continue
		var/obj/machinery/vending/vending_source = vendor
		if(istype(vending_source) && (!vending_source.has_corporate_vending_module() || vending_source.cyberpunk_corporate_vendor_id != id))
			continue
		if(id == CYBERPUNK_CORP_BENN)
			for(var/mob/living/customer in view(7, vendor))
				if(customer.stat == DEAD || customer.health >= customer.maxHealth || !customer.get_bank_account())
					continue
				if(dispatch_observation_drone(vendor, customer, customer))
					break
		else
			var/datum/cyberpunk_business/client_business = cyberpunk_service_business(vendor)
			var/datum/cyberpunk_apartment/client_apartment = cyberpunk_service_apartment(vendor)
			var/dispatched = FALSE
			for(var/mob/living/customer in view(7, vendor))
				var/obj/item/held = customer.get_active_held_item()
				if(cyberpunk_needs_technical_service(held) && (is_ryaznov_service_product(held) || cyberpunk_service_covers_premises(vendor, held, client_business, client_apartment)))
					if(dispatch_observation_drone(vendor, held, customer, client_business = client_business, client_apartment = client_apartment))
						dispatched = TRUE
						break
			if(dispatched)
				continue
			for(var/obj/target in view(7, vendor))
				if(!cyberpunk_needs_technical_service(target))
					continue
				var/mob/living/customer = isliving(target.loc) ? target.loc : null
				if(is_ryaznov_service_product(target) || cyberpunk_service_covers_premises(vendor, target, client_business, client_apartment))
					if(dispatch_observation_drone(vendor, target, customer, client_business = client_business, client_apartment = client_apartment))
						break

/datum/cyberpunk_corporation/proc/dispatch_observation_drone(atom/source, atom/target, mob/living/customer, personal = FALSE, datum/cyberpunk_business/client_business, datum/cyberpunk_apartment/client_apartment)
	var/turf/source_turf = get_turf(source)
	var/turf/target_turf = get_turf(target)
	if(!source_turf || !target_turf || observation_targets[REF(target)] > world.time)
		return FALSE
	if(agents_available <= 0)
		return FALSE
	if(!dispatch_agent("autonomous observation", 3 MINUTES))
		return FALSE
	observation_targets[REF(target)] = world.time + 3 MINUTES
	var/mob/living/basic/cyberpunk_corporate_agent/service_drone/drone = new(get_turf(source), id, id == CYBERPUNK_CORP_BENN ? "medical" : "technical", customer?.real_name)
	drone.target_ref = WEAKREF(target)
	drone.source_ref = WEAKREF(source)
	if(cyberpunk_service_covers_premises(source, target, client_business, client_apartment))
		if(client_business)
			drone.business_ref = WEAKREF(client_business)
		if(client_apartment)
			drone.apartment_ref = WEAKREF(client_apartment)
	if(customer)
		drone.customer_ref = WEAKREF(customer)
	drone.free_personal_service = personal
	drone.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	return TRUE

/datum/cyberpunk_corporation/proc/request_daily_observation_drone(mob/living/customer)
	if(!is_subscribed(customer) || !has_edict(id == CYBERPUNK_CORP_BENN ? "benn_med_observation" : "ryaznov_tech_observation"))
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	var/current_day = SScyberpunk_round?.cyberpunk_round_day || 1
	if(!character_key || personal_service_days[character_key] == current_day)
		return FALSE
	var/atom/target = customer
	if(id == CYBERPUNK_CORP_RYAZNOV)
		target = customer.get_active_held_item()
		if(!cyberpunk_needs_technical_service(target))
			for(var/obj/candidate in range(1, customer))
				if(cyberpunk_needs_technical_service(candidate))
					target = candidate
					break
		if(!cyberpunk_needs_technical_service(target))
			return FALSE
	for(var/vendor_key in service_sources)
		var/datum/weakref/vendor_ref = service_sources[vendor_key]
		var/obj/machinery/vendor = vendor_ref?.resolve()
		if(!vendor?.is_operational)
			continue
		var/obj/machinery/vending/vending_source = vendor
		if(istype(vending_source) && (!vending_source.has_corporate_vending_module() || vending_source.cyberpunk_corporate_vendor_id != id))
			continue
		if(dispatch_observation_drone(vendor, target, customer, TRUE))
			personal_service_days[character_key] = current_day
			return TRUE
	return FALSE

/mob/living/basic/cyberpunk_corporate_agent/service_drone
	name = "corporate service drone"
	icon = 'icons/mob/silicon/aibots.dmi'
	icon_state = "medbot_generic_idle"
	service_lifetime = 2 MINUTES
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_service_drone
	movement_type = FLYING
	var/datum/weakref/target_ref
	var/datum/weakref/source_ref
	var/datum/weakref/customer_ref
	var/datum/weakref/business_ref
	var/datum/weakref/apartment_ref
	var/free_personal_service = FALSE

/mob/living/basic/cyberpunk_corporate_agent/service_drone/Initialize(mapload, new_corporation_id, new_service_id, customer_name)
	. = ..()
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	if(corporation_id == CYBERPUNK_CORP_RYAZNOV)
		icon_state = "repairbot1"

/mob/living/basic/cyberpunk_corporate_agent/service_drone/proc/complete_treatment()
	var/atom/target = target_ref?.resolve()
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/mob/living/customer = customer_ref?.resolve()
	var/datum/cyberpunk_business/business = business_ref?.resolve()
	var/datum/cyberpunk_apartment/apartment = apartment_ref?.resolve()
	var/held_by_customer = customer && target?.loc == customer && customer.Adjacent(src)
	if(!target || !corporation || (!target.IsReachableBy(src) && !held_by_customer))
		return FALSE
	if(!corporation.has_edict(corporation_id == CYBERPUNK_CORP_BENN ? "benn_med_observation" : "ryaznov_tech_observation"))
		return FALSE
	var/cost = 0
	if(corporation_id == CYBERPUNK_CORP_BENN)
		var/mob/living/patient = target
		if(!istype(patient) || patient.stat == DEAD || patient.health >= patient.maxHealth)
			return FALSE
		patient.heal_ordered_damage(corporation.is_subscribed(patient) ? 60 : 35, list(BRUTE, BURN, TOX, OXY))
		cost = corporation.get_service_cost("medical", patient)
	else
		var/obj/repair_target = target
		if(!cyberpunk_needs_technical_service(repair_target))
			return FALSE
		var/covered_premises = cyberpunk_service_covers_premises(source_ref?.resolve(), repair_target, business, apartment)
		if(!covered_premises)
			business = null
			apartment = null
		if(!free_personal_service && !corporation.is_ryaznov_service_product(repair_target) && !covered_premises)
			return FALSE
		var/repair_amount = customer && corporation.is_subscribed(customer) ? 80 : 45
		repair_target.extinguish()
		if(repair_target.uses_integrity)
			var/obj/item/item_target = repair_target
			if(istype(item_target))
				item_target.repair_cyberpunk_item(repair_amount, customer)
			else
				repair_target.repair_damage(repair_amount)
		var/obj/machinery/machine = repair_target
		if(istype(machine))
			machine.repair_cyberpunk_machine_wear(repair_amount, customer)
		var/obj/item/forcefield_projector/projector = repair_target
		if(istype(projector))
			projector.shield_integrity = min(projector.max_shield_integrity, projector.shield_integrity + repair_amount)
		var/obj/machinery/modular_shield_generator/shield = repair_target
		if(istype(shield))
			shield.stored_strength = min(shield.max_strength, shield.stored_strength + repair_amount)
		cost = customer || covered_premises ? corporation.get_service_cost("technical", customer) : 0
	if(free_personal_service)
		cost = 0
	if(cost)
		var/datum/bank_account/account = business?.get_account()
		if(!account && apartment)
			account = SScyberpunk_corporations.get_cyberpunk_apartment_owner_account(apartment)
		if(!business && !apartment)
			account = customer?.get_bank_account()
		if(account?.adjust_money(-cost, "[corporation.name] observation service"))
			corporation.add_funds(cost, "observation service")
		else
			corporation.add_history("unpaid observation invoice: [cost] for [customer?.real_name || business?.name || apartment?.name]")
		business?.add_history("Ryaznov observation service invoice: [cost][MONEY_SYMBOL]")
		apartment?.add_history("Ryaznov observation service invoice: [cost][MONEY_SYMBOL]")
		account?.bank_card_talk("[corporation.name]: service invoice [cost][MONEY_SYMBOL].")
	visible_message(span_notice("[src] completes service for [target]."))
	corporation.add_data(corporation.get_primary_data_type(), 2, "observation service")
	QDEL_IN(src, 1 SECONDS)
	return TRUE

/datum/ai_controller/basic_controller/simple/cyberpunk_service_drone
	idle_behavior = null
	can_idle = FALSE
	ai_movement = /datum/ai_movement/jps/cyberpunk_service
	max_target_distance = 64
	planning_subtrees = list(/datum/ai_planning_subtree/cyberpunk_service_drone)

/datum/ai_movement/jps/cyberpunk_service
	maximum_length = 64
	max_pathing_attempts = 3

/datum/ai_planning_subtree/cyberpunk_service_drone/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/turf/target_turf = get_turf(target)
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(!target_turf || !pawn_turf)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(controller.blackboard[BB_CP_SERVICE_TARGET_Z] != target_turf.z)
		controller.set_blackboard_key(BB_CP_SERVICE_TARGET_Z, target_turf.z)
		controller.clear_blackboard_key(BB_CP_SERVICE_Z_REJECTED)
	if(pawn_turf.z != target_turf.z)
		controller.queue_behavior(/datum/ai_behavior/cyberpunk_service_z_route)
	else
		controller.queue_behavior(/datum/ai_behavior/cyberpunk_service_drone)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/cyberpunk_service_drone
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH
	required_distance = 1
	action_cooldown = 3 SECONDS

/datum/ai_behavior/cyberpunk_service_drone/setup(datum/ai_controller/controller)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, isliving(target.loc) ? target.loc : target)

/datum/ai_behavior/cyberpunk_service_drone/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/basic/cyberpunk_corporate_agent/service_drone/drone = controller.pawn
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/turf/target_turf = get_turf(target)
	var/turf/drone_turf = get_turf(drone)
	if(target_turf && target_turf.z != drone_turf?.z)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | (drone.complete_treatment() ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_behavior/cyberpunk_service_drone/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/turf/target_turf = get_turf(target)
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(!succeeded && target_turf && target_turf.z != pawn_turf?.z)
		return
	controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)

/// Registered physical links only. The normal tg JPS movement handles each horizontal leg.
/proc/cyberpunk_service_z_edges()
	var/list/edges = list()
	for(var/obj/structure/ladder/ladder as anything in GLOB.ladders)
		if(QDELETED(ladder) || !get_turf(ladder))
			continue
		for(var/obj/structure/ladder/destination as anything in list(ladder.up, ladder.down))
			var/turf/exit = get_turf(destination)
			if(!exit || exit.z == ladder.z)
				continue
			edges += list(list("entry" = get_turf(ladder), "exit" = exit, "link" = ladder, "up" = destination == ladder.up))
	for(var/obj/structure/stairs/stair as anything in GLOB.stairs)
		if(QDELETED(stair) || !stair.isTerminator())
			continue
		var/turf/lower = get_turf(stair)
		var/turf/upper = get_step_multiz(stair, stair.dir | UP)
		var/turf/opening = get_step_multiz(stair, UP)
		if(!lower || !upper || !opening)
			continue
		edges += list(list("entry" = lower, "exit" = upper, "link" = stair, "up" = TRUE))
		edges += list(list("entry" = opening, "exit" = lower, "link" = stair, "up" = FALSE))
	return edges

/proc/cyberpunk_service_z_edge_key(list/edge)
	var/turf/exit = edge["exit"]
	return "[REF(edge["entry"])]>[exit?.z]"

/proc/cyberpunk_travel_z_edge(mob/living/traveler, list/edge)
	var/turf/entry = edge?["entry"]
	var/turf/exit = edge?["exit"]
	if(!entry || !exit || QDELETED(traveler) || get_turf(traveler) != entry)
		return FALSE
	var/obj/structure/ladder/ladder = edge["link"]
	var/obj/structure/stairs/stair = edge["link"]
	if(istype(ladder) && !QDELETED(ladder))
		var/obj/structure/ladder/destination = edge["up"] ? ladder.up : ladder.down
		if(get_turf(destination) != exit || (SEND_SIGNAL(traveler, COMSIG_LADDER_TRAVEL, ladder, destination, edge["up"]) & LADDER_TRAVEL_BLOCK))
			return FALSE
		// Use ladder movement and signals, without opening the player's radial menu for an NPC.
		traveler.zMove(target = exit, z_move_flags = ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
	else if(istype(stair) && !QDELETED(stair))
		if(edge["up"])
			stair.stair_ascend(traveler)
		else if(traveler.can_z_move(DOWN, entry, exit, z_move_flags = ZMOVE_STAIRS_FLAGS))
			traveler.zMove(DOWN, target = exit, z_move_flags = ZMOVE_STAIRS_FLAGS|ZMOVE_INCLUDE_PULLED)
	else if(edge["flight"])
		traveler.zMove(edge["up"] ? UP : DOWN, target = exit, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	return get_turf(traveler) == exit

/// Mapping stacks bound the search, but every flight link still needs an actual open passage.
/proc/cyberpunk_service_flight_edges(atom/movable/traveler, turf/start, list/edges)
	for(var/level in SSmapping.get_connected_levels(start.z))
		var/turf/origin = locate(start.x, start.y, level)
		for(var/turf/open/entry in range(7, origin))
			for(var/direction in list(UP, DOWN))
				var/turf/exit = get_step_multiz(entry, direction)
				if(exit && traveler.can_z_move(direction, entry, exit, z_move_flags = ZMOVE_FLIGHT_FLAGS))
					edges += list(list("entry" = entry, "exit" = exit, "flight" = TRUE, "up" = direction == UP))
	return edges

/// Count physical Z transitions. Being in the same mapping stack does not imply a usable passage.
/proc/cyberpunk_service_z_distance(start_z, target_z, list/edges, list/rejected)
	var/list/visited = list()
	var/list/pending = list(start_z)
	var/list/distances = list("[start_z]" = 0)
	while(length(pending))
		var/current_z = pending[1]
		pending.Cut(1, 2)
		if(current_z == target_z)
			return distances["[current_z]"]
		if(visited["[current_z]"])
			continue
		visited["[current_z]"] = TRUE
		for(var/list/edge as anything in edges)
			var/turf/entry = edge["entry"]
			var/turf/exit = edge["exit"]
			if(entry?.z == current_z && exit && isnull(distances["[exit.z]"]) && !rejected?[cyberpunk_service_z_edge_key(edge)])
				distances["[exit.z]"] = distances["[current_z]"] + 1
				pending |= exit.z
	return INFINITY

/proc/cyberpunk_service_z_connected(start_z, target_z, list/edges, list/rejected)
	return cyberpunk_service_z_distance(start_z, target_z, edges, rejected) < INFINITY

/proc/cyberpunk_service_z_next_edge(turf/start, turf/target, list/edges, list/rejected)
	var/list/best
	var/best_cost = INFINITY
	var/list/hops_by_z = list()
	for(var/list/edge as anything in edges)
		var/turf/entry = edge["entry"]
		var/turf/exit = edge["exit"]
		if(!entry || !exit || entry.z != start.z || rejected?[cyberpunk_service_z_edge_key(edge)])
			continue
		var/hops = hops_by_z["[exit.z]"]
		if(isnull(hops))
			hops = cyberpunk_service_z_distance(exit.z, target.z, edges, rejected)
			hops_by_z["[exit.z]"] = hops
		var/cost = hops * (world.maxx + world.maxy + 1) + get_dist(start, entry)
		if(hops < INFINITY && cost < best_cost)
			best = edge
			best_cost = cost
	return best

/datum/ai_behavior/cyberpunk_service_z_route
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 0
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_service_z_route/setup(datum/ai_controller/controller)
	. = ..()
	var/mob/living/pawn = controller.pawn
	var/turf/target = get_turf(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET])
	var/turf/start = get_turf(pawn)
	if(!target || !start || start.z == target.z)
		return FALSE
	var/list/rejected = controller.blackboard[BB_CP_SERVICE_Z_REJECTED]
	var/list/edges = cyberpunk_service_z_edges()
	cyberpunk_service_flight_edges(pawn, start, edges)
	var/list/best = cyberpunk_service_z_next_edge(start, target, edges, rejected)
	if(!best)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		return FALSE
	controller.override_blackboard_key(BB_CP_SERVICE_Z_EDGE, best)
	set_movement_target(controller, best["entry"])

/datum/ai_behavior/cyberpunk_service_z_route/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/pawn = controller.pawn
	var/list/edge = controller.blackboard[BB_CP_SERVICE_Z_EDGE]
	var/turf/entry = edge?["entry"]
	var/turf/exit = edge?["exit"]
	if(!entry || !exit || QDELETED(pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(pawn.z == exit.z)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	if(get_turf(pawn) != entry)
		return AI_BEHAVIOR_DELAY
	return AI_BEHAVIOR_DELAY | (cyberpunk_travel_z_edge(pawn, edge) ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_behavior/cyberpunk_service_z_route/finish_action(datum/ai_controller/controller, succeeded)
	var/list/edge = controller.blackboard[BB_CP_SERVICE_Z_EDGE]
	var/turf/exit = edge?["exit"]
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(exit && pawn_turf?.z == exit.z)
		succeeded = TRUE
	if(!succeeded && edge)
		controller.set_blackboard_key_assoc_lazylist(BB_CP_SERVICE_Z_REJECTED, cyberpunk_service_z_edge_key(edge), TRUE)
	controller.clear_blackboard_key(BB_CP_SERVICE_Z_EDGE)
	return ..()

/mob/living/basic/cyberpunk_corporate_agent/proc/announce_service(mob/living/customer, service_label)
	if(!customer || QDELETED(customer))
		return FALSE
	visible_message(span_notice("[src] confirms [service_label || service_id] service for [customer]."))
	return TRUE

/mob/living/basic/cyberpunk_corporate_agent/benn
	agent_title = "clinical agent"
	icon_state = "medical"

/mob/living/basic/cyberpunk_corporate_agent/ryaznov
	agent_title = "industrial agent"
	icon_state = "engineer"

/mob/living/basic/cyberpunk_corporate_agent/starlight
	agent_title = "courier agent"
	icon_state = "assistant"

/mob/living/basic/cyberpunk_corporate_agent/government
	agent_title = "civic agent"
	icon_state = "officer"

/datum/cyberpunk_corporate_service_request
	var/id = 0
	var/corporation_id
	var/corporation_name
	var/service_id
	var/service_label
	var/customer_name
	var/customer_key
	var/cost = 0
	var/status = CYBERPUNK_CORP_SERVICE_CREATED
	var/created_at = 0
	var/completed_at = 0
	var/datum/weakref/customer_ref
	var/list/history = list()

/datum/cyberpunk_corporate_service_request/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_corporate_service_request/proc/complete()
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation?.dispatch_agent("manual service: [service_id]", 3 MINUTES))
		add_history("completion failed: no free corporate agents")
		return FALSE
	var/mob/living/customer = customer_ref?.resolve()
	if(!customer || QDELETED(customer))
		add_history("completion failed: customer unavailable")
		return FALSE
	var/success = FALSE
	switch(corporation_id)
		if(CYBERPUNK_CORP_BENN)
			success = cyberpunk_complete_benn_service(WEAKREF(customer), corporation_id, service_id)
		if(CYBERPUNK_CORP_RYAZNOV)
			success = cyberpunk_complete_ryaznov_service(WEAKREF(customer), corporation_id, service_id)
		if(CYBERPUNK_CORP_STARLIGHT)
			success = cyberpunk_complete_starlight_service(WEAKREF(customer), corporation_id, service_id)
	if(!success)
		add_history("completion failed during service execution")
		return FALSE
	status = CYBERPUNK_CORP_SERVICE_COMPLETED
	completed_at = world.time
	add_history("completed")
	return TRUE

/datum/cyberpunk_corporate_service_request/proc/cancel(reason = "cancelled")
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	status = CYBERPUNK_CORP_SERVICE_CANCELLED
	add_history(reason)
	return TRUE

/datum/cyberpunk_corporate_service_request/proc/outsource()
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/datum/cyberpunk_contract/contract = corporation?.create_service_outsource_contract(src)
	return !!contract

/datum/cyberpunk_corporate_service_request/proc/to_ui_data()
	return list(
		"id" = id,
		"corporationId" = corporation_id,
		"corporation" = corporation_name,
		"serviceId" = service_id,
		"service" = service_label || service_id,
		"customer" = customer_name,
		"cost" = cost,
		"status" = status,
		"age" = created_at ? DisplayTimeText(world.time - created_at) : "unknown",
		"history" = history,
	)

/datum/controller/subsystem/cyberpunk_corporations/proc/create_cyberpunk_corporate_service_request(datum/cyberpunk_corporation/corporation, mob/living/customer, service_id, cost = 0)
	if(!corporation || !customer)
		return null
	var/datum/cyberpunk_corporate_service_request/request = new
	request.id = next_cyberpunk_corporate_service_request_id++
	request.corporation_id = corporation.id
	request.corporation_name = corporation.name
	request.service_id = service_id
	request.service_label = corporation.get_service_label(service_id)
	request.customer_name = customer.real_name || customer.name
	request.customer_key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	request.cost = max(0, round(cost))
	request.created_at = world.time
	request.customer_ref = WEAKREF(customer)
	request.add_history("created by [request.customer_name]")
	cyberpunk_corporate_service_requests["[request.id]"] = request
	corporation.add_history("service request #[request.id] queued: [service_id] for [request.customer_name]")
	return request

/datum/controller/subsystem/cyberpunk_corporations/proc/find_cyberpunk_corporate_agent(corporation_id, service_id, mob/living/customer)
	if(!customer || QDELETED(customer))
		return null
	for(var/mob/living/basic/cyberpunk_corporate_agent/agent in range(1, customer))
		if(agent.corporation_id == corporation_id && agent.service_id == service_id && agent.stat != DEAD && agent.Adjacent(customer))
			return agent
	return null

/proc/cyberpunk_spawn_service_agent(corporation_id, service_id, mob/living/customer, service_label = null)
	// Legacy confirmation hook: never conjure a representative beside a distant client.
	var/mob/living/basic/cyberpunk_corporate_agent/agent = SScyberpunk_corporations.find_cyberpunk_corporate_agent(corporation_id, service_id, customer)
	agent?.announce_service(customer, service_label || service_id)
	return agent

/proc/cyberpunk_corporate_agent_color(corporation_id)
	switch(lowertext(trim("[corporation_id]")))
		if(CYBERPUNK_CORP_BENN)
			return COLOR_GREEN
		if(CYBERPUNK_CORP_RYAZNOV)
			return COLOR_ORANGE
		if(CYBERPUNK_CORP_STARLIGHT)
			return COLOR_CYAN
		if(CYBERPUNK_CORP_GOVERNMENT)
			return COLOR_RED
	return COLOR_WHITE

/proc/cyberpunk_corporate_agent_type(corporation_id)
	switch(lowertext(trim("[corporation_id]")))
		if(CYBERPUNK_CORP_BENN)
			return /mob/living/basic/cyberpunk_corporate_agent/benn
		if(CYBERPUNK_CORP_RYAZNOV)
			return /mob/living/basic/cyberpunk_corporate_agent/ryaznov
		if(CYBERPUNK_CORP_STARLIGHT)
			return /mob/living/basic/cyberpunk_corporate_agent/starlight
		if(CYBERPUNK_CORP_GOVERNMENT)
			return /mob/living/basic/cyberpunk_corporate_agent/government
	return /mob/living/basic/cyberpunk_corporate_agent

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporate_service_request(request_id)
	return cyberpunk_corporate_service_requests["[request_id]"]

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporate_service_requests_ui(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	var/list/requests = list()
	for(var/request_id in cyberpunk_corporate_service_requests)
		var/datum/cyberpunk_corporate_service_request/request = cyberpunk_corporate_service_requests[request_id]
		if(request?.corporation_id != corporation_id)
			continue
		requests += list(request.to_ui_data())
	return requests

/datum/cyberpunk_corporation/proc/get_service_label(service_id)
	for(var/list/service as anything in get_available_services_ui())
		if(service["id"] == service_id)
			return service["label"]
	return service_id

#undef BB_CP_SERVICE_Z_EDGE
#undef BB_CP_SERVICE_Z_REJECTED
#undef BB_CP_SERVICE_TARGET_Z
