
/datum/ai_controller
	var/datum/cy_npc_profile/cy_npc_profile
	var/cy_npc_role
	var/cy_npc_faction_id
	var/cy_npc_level = CY_NPC_LEVEL_BASIC
	var/cy_npc_state = CY_NPC_STATE_CALM
	var/cy_npc_capabilities = 0
	var/list/cy_npc_orders
	var/cy_npc_next_strategy_tick = 0
	var/cy_npc_next_threat_scan = 0
	var/cy_npc_active = TRUE
	var/cy_npc_phantom = FALSE
	var/turf/cy_npc_last_known_turf
	var/cy_npc_last_phase

/datum/ai_controller/proc/cy_npc_apply_profile(profile_type)
	var/datum/cy_npc_profile/profile
	if(ispath(profile_type, /datum/cy_npc_profile))
		profile = new profile_type
	else if(istype(profile_type, /datum/cy_npc_profile))
		profile = profile_type
	if(!profile)
		return FALSE
	return profile.apply_to_controller(src)

/datum/ai_controller/proc/cy_npc_set_state(new_state)
	if(cy_npc_state == new_state)
		return
	cy_npc_state = new_state
	blackboard[BB_CY_NPC_STATE] = new_state

/datum/ai_controller/proc/cy_npc_enqueue_order(datum/cy_npc_order/order)
	if(!order)
		return FALSE
	LAZYADD(cy_npc_orders, order)
	cy_npc_sort_orders()
	blackboard[BB_CY_NPC_ORDER] = order
	return TRUE

/datum/ai_controller/proc/cy_npc_make_order(order_type, atom/target, list/data)
	var/datum/cy_npc_order/order = new(order_type, target, data)
	cy_npc_enqueue_order(order)
	return order

/datum/ai_controller/proc/cy_npc_sort_orders()
	if(length(cy_npc_orders) < 2)
		return
	for(var/i in 1 to length(cy_npc_orders) - 1)
		for(var/j in i + 1 to length(cy_npc_orders))
			var/datum/cy_npc_order/left = cy_npc_orders[i]
			var/datum/cy_npc_order/right = cy_npc_orders[j]
			if(right.priority > left.priority)
				cy_npc_orders[i] = right
				cy_npc_orders[j] = left

/datum/ai_controller/proc/cy_npc_current_order()
	if(!length(cy_npc_orders))
		return null
	return cy_npc_orders[1]

/datum/ai_controller/proc/cy_npc_clear_finished_orders()
	if(!length(cy_npc_orders))
		return
	for(var/datum/cy_npc_order/order as anything in cy_npc_orders.Copy())
		if(order.status == CY_NPC_ORDER_DONE || order.status == CY_NPC_ORDER_FAILED)
			cy_npc_orders -= order
			qdel(order)
	if(!length(cy_npc_orders))
		blackboard -= BB_CY_NPC_ORDER

/datum/ai_controller/proc/cy_npc_strategy_tick(seconds_per_tick)
	if(!cy_npc_profile || QDELETED(pawn))
		return
	if(world.time < cy_npc_next_strategy_tick)
		return
	cy_npc_next_strategy_tick = world.time + max(1, cy_npc_profile.reaction_delay)
	cy_npc_last_known_turf = get_turf(pawn)
	cy_npc_update_phantom_state()
	cy_npc_apply_schedule()
	cy_npc_scan_for_threats()
	cy_npc_clear_finished_orders()
	var/datum/cy_npc_order/order = cy_npc_current_order()
	if(!order)
		cy_npc_assign_default_order()
		order = cy_npc_current_order()
	if(order)
		order.process(src, seconds_per_tick)
	cy_npc_clear_finished_orders()

/datum/ai_controller/proc/cy_npc_update_phantom_state()
	if(!cy_npc_profile?.phantom_allowed || !(cy_npc_capabilities & CY_NPC_CAP_PHANTOM))
		cy_npc_phantom = FALSE
		cy_npc_active = TRUE
		return
	if(isnull(our_cells))
		cy_npc_phantom = FALSE
		cy_npc_active = TRUE
		return
	cy_npc_phantom = should_idle()
	cy_npc_active = !cy_npc_phantom
	if(cy_npc_phantom)
		cy_npc_set_state(CY_NPC_STATE_PHANTOM)

/datum/ai_controller/proc/cy_npc_apply_schedule()
	if(!(cy_npc_capabilities & CY_NPC_CAP_SCHEDULE))
		return
	var/list/schedule = blackboard[BB_CY_NPC_SCHEDULE]
	if(!length(schedule))
		return
	var/phase = SSai_controllers.cy_npc_current_day_phase()
	blackboard[BB_CY_NPC_CURRENT_PHASE] = phase
	if(cy_npc_last_phase == phase)
		return
	cy_npc_last_phase = phase
	var/list/phase_data = schedule[phase]
	if(!islist(phase_data))
		return
	var/order_type = phase_data["order"]
	if(!order_type)
		return
	var/atom/order_target = phase_data["target"] || blackboard[BB_CY_NPC_HOME]
	cy_npc_make_order(order_type, order_target, list("priority" = phase_data["priority"] || -10, "patrol_points" = phase_data["patrol_points"]))

/datum/ai_controller/proc/cy_npc_scan_for_threats()
	if(world.time < cy_npc_next_threat_scan)
		return
	cy_npc_next_threat_scan = world.time + max(5, cy_npc_profile?.reaction_delay || 1 SECONDS)
	if(!(cy_npc_capabilities & (CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED | CY_NPC_CAP_GRAB | CY_NPC_CAP_SIGNAL)))
		return
	var/turf/source_turf = get_turf(pawn)
	if(!source_turf)
		return
	var/range = cy_npc_profile?.threat_scan_range || 7
	for(var/mob/living/nearby_mob in oview(range, source_turf))
		if(QDELETED(nearby_mob) || nearby_mob.stat == DEAD)
			continue
		if(!cy_npc_should_attack(nearby_mob))
			continue
		blackboard[BB_CY_NPC_THREAT] = nearby_mob
		var/order_type = (cy_npc_role == CY_NPC_ROLE_POLICE || cy_npc_role == CY_NPC_ROLE_CORPORATE) ? CY_NPC_ORDER_CAPTURE : CY_NPC_ORDER_ATTACK
		cy_npc_make_order(order_type, nearby_mob, list("priority" = 40, "timeout" = 30 SECONDS))
		cy_npc_alert_allies(nearby_mob, "threat")
		return

/datum/ai_controller/proc/cy_npc_should_attack(mob/living/target_mob)
	if(!target_mob || target_mob == pawn)
		return FALSE
	var/datum/ai_controller/target_controller = target_mob.ai_controller
	if(target_controller?.cy_npc_faction_id)
		return SSai_controllers.cy_npc_relation(cy_npc_faction_id, target_controller.cy_npc_faction_id) <= CY_NPC_REL_ENEMY
	if(cy_npc_role == CY_NPC_ROLE_BANDIT || cy_npc_role == CY_NPC_ROLE_HOSTILE_ANIMAL)
		return TRUE
	return FALSE

/datum/ai_controller/proc/cy_npc_assign_default_order()
	switch(cy_npc_role)
		if(CY_NPC_ROLE_CIVILIAN, CY_NPC_ROLE_GOVERNMENT_WORKER, CY_NPC_ROLE_CORPORATE_WORKER)
			if(blackboard[BB_CY_NPC_WORK_TARGET])
				cy_npc_make_order(CY_NPC_ORDER_WORK, blackboard[BB_CY_NPC_WORK_TARGET], list("priority" = 0))
			else if(blackboard[BB_CY_NPC_PATROL])
				cy_npc_make_order(CY_NPC_ORDER_PATROL, null, list("priority" = 0, "patrol_points" = blackboard[BB_CY_NPC_PATROL]))
			else
				cy_npc_make_order(CY_NPC_ORDER_IDLE, null, list("priority" = -100))
		if(CY_NPC_ROLE_DRONE, CY_NPC_ROLE_REPAIR_DRONE, CY_NPC_ROLE_MEDICAL_DRONE)
			if(blackboard[BB_CY_NPC_HOME])
				cy_npc_make_order(CY_NPC_ORDER_RETURN_HOME, blackboard[BB_CY_NPC_HOME], list("priority" = -50))
			else
				cy_npc_make_order(CY_NPC_ORDER_IDLE, null, list("priority" = -100))
		if(CY_NPC_ROLE_CORPORATE, CY_NPC_ROLE_POLICE)
			if(blackboard[BB_CY_NPC_PATROL])
				cy_npc_make_order(CY_NPC_ORDER_PATROL, null, list("priority" = 0, "patrol_points" = blackboard[BB_CY_NPC_PATROL]))
			else
				cy_npc_make_order(CY_NPC_ORDER_GUARD, blackboard[BB_CY_NPC_HOME], list("priority" = 0))
		if(CY_NPC_ROLE_BANDIT, CY_NPC_ROLE_HOSTILE_ANIMAL)
			cy_npc_make_order(CY_NPC_ORDER_SEARCH, blackboard[BB_CY_NPC_HOME], list("priority" = -20, "radius" = cy_npc_profile?.threat_scan_range || 7))
		else
			cy_npc_make_order(CY_NPC_ORDER_IDLE, null, list("priority" = -100))

/datum/ai_controller/proc/cy_npc_try_interact(atom/target, combat_mode = null, list/modifiers = null)
	if(!target || QDELETED(target))
		return FALSE
	if(prob(cy_npc_profile?.error_chance || 0))
		return FALSE
	return ai_interact(target, combat_mode, modifiers || list())

/datum/ai_controller/proc/cy_npc_try_ability(atom/target, list/data)
	// Concrete demons, implants, grenades, medical tools and other ability implementations
	// are owned by their feature modules. The AI layer only exposes a stable hook.
	return FALSE

/datum/ai_controller/proc/cy_npc_try_heal(mob/living/target_mob, list/data)
	if(!(cy_npc_capabilities & CY_NPC_CAP_MEDICAL) || !target_mob)
		return FALSE
	return cy_npc_try_interact(target_mob, FALSE, data)

/datum/ai_controller/proc/cy_npc_try_repair(atom/target_atom, list/data)
	if(!(cy_npc_capabilities & CY_NPC_CAP_REPAIR) || !target_atom)
		return FALSE
	return cy_npc_try_interact(target_atom, FALSE, data)

/datum/ai_controller/proc/cy_npc_try_restrain(mob/living/target_mob, list/data)
	if(!(cy_npc_capabilities & CY_NPC_CAP_RESTRAIN) || !target_mob)
		return FALSE
	return cy_npc_try_interact(target_mob, TRUE, list(CTRL_CLICK = TRUE))

/datum/ai_controller/proc/cy_npc_try_pickup(atom/movable/target_atom, list/data)
	if(!(cy_npc_capabilities & CY_NPC_CAP_HANDS) || !target_atom)
		return FALSE
	return cy_npc_try_interact(target_atom, FALSE, data)

/datum/ai_controller/proc/cy_npc_try_drop(atom/target_atom, list/data)
	return TRUE

/datum/ai_controller/proc/cy_npc_try_equip(atom/movable/target_atom, list/data)
	if(!(cy_npc_capabilities & CY_NPC_CAP_EQUIPMENT) || !target_atom)
		return FALSE
	return cy_npc_try_interact(target_atom, FALSE, data)

/datum/ai_controller/proc/cy_npc_alert_allies(atom/threat, message)
	if(!cy_npc_faction_id)
		return
	var/turf/source_turf = get_turf(pawn)
	if(!source_turf)
		return
	var/radius = cy_npc_profile?.group_radius || 7
	for(var/mob/living/nearby_mob in oview(radius, source_turf))
		var/datum/ai_controller/nearby_controller = nearby_mob.ai_controller
		if(!nearby_controller?.cy_npc_profile)
			continue
		if(nearby_controller.cy_npc_faction_id != cy_npc_faction_id)
			continue
		nearby_controller.blackboard[BB_CY_NPC_LAST_SIGNAL] = list("message" = message, "target" = threat, "source" = pawn, "time" = world.time)
		if(threat)
			var/order_type = (nearby_controller.cy_npc_role == CY_NPC_ROLE_POLICE || nearby_controller.cy_npc_role == CY_NPC_ROLE_CORPORATE) ? CY_NPC_ORDER_CAPTURE : CY_NPC_ORDER_ATTACK
			nearby_controller.cy_npc_make_order(order_type, threat, list("priority" = 50, "timeout" = 30 SECONDS))

/datum/ai_controller/proc/cy_npc_snapshot()
	var/datum/cy_npc_order/temp_order = cy_npc_current_order()
	return list(
		"pawn" = "[pawn]",
		"role" = cy_npc_role,
		"faction" = cy_npc_faction_id,
		"level" = cy_npc_level,
		"state" = cy_npc_state,
		"phantom" = cy_npc_phantom,
		"active" = cy_npc_active,
		"orders" = length(cy_npc_orders),
		"current_order" = temp_order?.order_type,
		"z" = cy_npc_last_known_turf?.z,
	)

/mob/living
	var/cy_npc_profile_type

/mob/living/proc/cy_npc_setup(profile_type, list/patrol_points, atom/home, atom/work_target)
	cy_npc_profile_type = profile_type
	if(!ai_controller)
		return FALSE
	var/datum/ai_controller/controller = ai_controller
	if(!controller.cy_npc_apply_profile(profile_type))
		return FALSE
	if(patrol_points)
		controller.blackboard[BB_CY_NPC_PATROL] = patrol_points.Copy()
	if(home)
		controller.blackboard[BB_CY_NPC_HOME] = home
	if(work_target)
		controller.blackboard[BB_CY_NPC_WORK_TARGET] = work_target
	return TRUE

/mob/living/proc/cy_npc_order(order_type, atom/target, list/data)
	if(!ai_controller)
		return null
	var/datum/ai_controller/controller = ai_controller
	return controller.cy_npc_make_order(order_type, target, data)
