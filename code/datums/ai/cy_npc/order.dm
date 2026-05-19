/datum/cy_npc_order
	var/order_type = CY_NPC_ORDER_IDLE
	var/status = CY_NPC_ORDER_PENDING
	var/priority = 0
	var/atom/target
	var/turf/target_turf
	var/list/patrol_points
	var/patrol_index = 1
	var/started_at = 0
	var/timeout = 0
	var/message
	var/data

/datum/cy_npc_order/New(new_order_type, atom/new_target, list/new_data)
	. = ..()
	if(new_order_type)
		order_type = new_order_type
	if(new_target)
		target = new_target
		target_turf = get_turf(new_target)
	if(new_data)
		data = new_data.Copy()
		if(isnum(data["priority"]))
			priority = data["priority"]
		if(isnum(data["timeout"]))
			timeout = data["timeout"]
		if(data["message"])
			message = data["message"]
		if(islist(data["patrol_points"]))
			patrol_points = data["patrol_points"]
		if(data["target_turf"])
			target_turf = get_turf(data["target_turf"])

/datum/cy_npc_order/proc/start(datum/ai_controller/controller)
	status = CY_NPC_ORDER_RUNNING
	started_at = world.time
	controller.blackboard[BB_CY_NPC_ORDER] = src
	return TRUE

/datum/cy_npc_order/proc/expired()
	return timeout && started_at && world.time > started_at + timeout

/datum/cy_npc_order/proc/finish(datum/ai_controller/controller, success = TRUE)
	status = success ? CY_NPC_ORDER_DONE : CY_NPC_ORDER_FAILED
	if(controller?.blackboard[BB_CY_NPC_ORDER] == src)
		controller.blackboard -= BB_CY_NPC_ORDER
	return status

/datum/cy_npc_order/proc/get_contract()
	var/contract_id = data?["contract_id"]
	if(!contract_id)
		return null
	return SScy_business?.get_contract(contract_id)

/datum/cy_npc_order/process(datum/ai_controller/controller, seconds_per_tick)
	if(!controller || QDELETED(controller.pawn))
		status = CY_NPC_ORDER_FAILED
		return status
	if(status == CY_NPC_ORDER_PENDING)
		start(controller)
	if(expired())
		return finish(controller, FALSE)

	switch(order_type)
		if(CY_NPC_ORDER_IDLE)
			controller.cy_npc_set_state(CY_NPC_STATE_CALM)
			return CY_NPC_ORDER_RUNNING
		if(CY_NPC_ORDER_WAIT, CY_NPC_ORDER_HOLD_POSITION)
			controller.cy_npc_set_state(CY_NPC_STATE_ORDERED)
			return CY_NPC_ORDER_RUNNING
		if(CY_NPC_ORDER_MOVE)
			return process_move(controller)
		if(CY_NPC_ORDER_RETURN_HOME)
			return process_return_home(controller)
		if(CY_NPC_ORDER_PATROL)
			return process_patrol(controller)
		if(CY_NPC_ORDER_WORK)
			return process_work(controller)
		if(CY_NPC_ORDER_GUARD)
			return process_guard(controller)
		if(CY_NPC_ORDER_ATTACK)
			return process_attack(controller)
		if(CY_NPC_ORDER_AIM)
			return process_aim(controller)
		if(CY_NPC_ORDER_TAKE_COVER)
			return process_take_cover(controller)
		if(CY_NPC_ORDER_FLEE)
			return process_flee(controller)
		if(CY_NPC_ORDER_CAPTURE)
			return process_capture(controller)
		if(CY_NPC_ORDER_RESTRAIN)
			return process_restrain(controller)
		if(CY_NPC_ORDER_CARRY)
			return process_carry(controller)
		if(CY_NPC_ORDER_DELIVER, CY_NPC_ORDER_ESCORT)
			return process_deliver(controller)
		if(CY_NPC_ORDER_USE_OBJECT, CY_NPC_ORDER_USE_ITEM)
			return process_use(controller)
		if(CY_NPC_ORDER_HEAL)
			return process_heal(controller)
		if(CY_NPC_ORDER_REPAIR)
			return process_repair(controller)
		if(CY_NPC_ORDER_PICKUP)
			return process_pickup(controller)
		if(CY_NPC_ORDER_DROP)
			return process_drop(controller)
		if(CY_NPC_ORDER_EQUIP)
			return process_equip(controller)
		if(CY_NPC_ORDER_SEARCH)
			return process_search(controller)
		if(CY_NPC_ORDER_DISARM)
			return process_disarm(controller)
		if(CY_NPC_ORDER_SIGNAL)
			return process_signal(controller)
		if(CY_NPC_ORDER_ABILITY)
			return process_ability(controller)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/get_destination()
	return target_turf || get_turf(target) || get_turf(data?["destination"])

/datum/cy_npc_order/proc/process_move(datum/ai_controller/controller)
	var/turf/destination = get_destination()
	if(!destination)
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_ORDERED)
	if(controller.cy_npc_phantom)
		controller.cy_npc_last_known_turf = destination
		return finish(controller, TRUE)
	if(get_dist(controller.pawn, destination) <= 1)
		controller.set_movement_target(src, null)
		return finish(controller, TRUE)
	controller.set_movement_target(src, destination)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_return_home(datum/ai_controller/controller)
	target = target || controller.blackboard[BB_CY_NPC_HOME]
	target_turf = get_turf(target)
	controller.cy_npc_set_state(CY_NPC_STATE_RETURNING)
	return process_move(controller)

/datum/cy_npc_order/proc/process_patrol(datum/ai_controller/controller)
	if(!length(patrol_points))
		var/list/blackboard_patrol = controller.blackboard[BB_CY_NPC_PATROL]
		if(islist(blackboard_patrol))
			patrol_points = blackboard_patrol
	if(!length(patrol_points))
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_ORDERED)
	var/atom/current_point = patrol_points[patrol_index]
	if(!current_point)
		patrol_index = 1
		current_point = patrol_points[patrol_index]
	var/turf/destination = get_turf(current_point)
	if(!destination)
		patrol_index++
		if(patrol_index > length(patrol_points))
			patrol_index = 1
		return CY_NPC_ORDER_RUNNING
	if(controller.cy_npc_phantom)
		controller.cy_npc_last_known_turf = destination
		patrol_index++
		if(patrol_index > length(patrol_points))
			patrol_index = 1
		return CY_NPC_ORDER_RUNNING
	if(get_dist(controller.pawn, destination) <= 1)
		patrol_index++
		if(patrol_index > length(patrol_points))
			patrol_index = 1
		return CY_NPC_ORDER_RUNNING
	controller.set_movement_target(src, destination)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_work(datum/ai_controller/controller)
	var/atom/work_target = target || controller.blackboard[BB_CY_NPC_WORK_TARGET]
	if(!work_target)
		controller.cy_npc_set_state(CY_NPC_STATE_WORKING)
		return CY_NPC_ORDER_RUNNING
	controller.cy_npc_set_state(CY_NPC_STATE_WORKING)
	if(get_dist(controller.pawn, work_target) > 1)
		controller.set_movement_target(src, work_target)
		return CY_NPC_ORDER_RUNNING
	controller.set_movement_target(src, null)
	controller.cy_npc_try_interact(work_target)
	var/datum/cy_contract/contract = get_contract()
	if(contract && contract.contract_type == CY_CONTRACT_CONSTRUCTION)
		contract.metadata["ai_worked"] = TRUE
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_guard(datum/ai_controller/controller)
	controller.cy_npc_set_state(CY_NPC_STATE_ALERT)
	var/atom/guard_target = target || controller.blackboard[BB_CY_NPC_HOME]
	if(guard_target && get_dist(controller.pawn, guard_target) > 4)
		controller.set_movement_target(src, guard_target)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_attack(datum/ai_controller/controller)
	var/mob/living/living_target = target
	if(!istype(living_target) || QDELETED(living_target) || living_target.stat == DEAD)
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_COMBAT)
	controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] = living_target
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
	else
		controller.set_movement_target(src, null)
		controller.cy_npc_try_interact(living_target, TRUE, list())
		var/datum/cy_contract/contract = get_contract()
		if(contract && contract.contract_type == CY_CONTRACT_ELIMINATION)
			contract.metadata["last_ai_attacker"] = REF(controller.pawn)
	if(controller.cy_npc_level >= CY_NPC_LEVEL_TRAINED && prob(20 + controller.cy_npc_level * 10))
		controller.cy_npc_make_order(CY_NPC_ORDER_TAKE_COVER, living_target, list("priority" = priority - 1, "timeout" = 3 SECONDS))
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_aim(datum/ai_controller/controller)
	if(!(controller.cy_npc_capabilities & CY_NPC_CAP_AIM))
		return finish(controller, FALSE)
	controller.blackboard[BB_CY_NPC_AIM_TARGET] = target
	return process_attack(controller)

/datum/cy_npc_order/proc/process_take_cover(datum/ai_controller/controller)
	if(!(controller.cy_npc_capabilities & CY_NPC_CAP_COVER))
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_COMBAT)
	var/turf/best_cover
	for(var/obj/structure/cover in view(5, controller.pawn))
		if(cover.density)
			best_cover = get_turf(cover)
			break
	if(best_cover)
		controller.blackboard[BB_CY_NPC_COVER_TARGET] = best_cover
		controller.set_movement_target(src, best_cover)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_flee(datum/ai_controller/controller)
	controller.cy_npc_set_state(CY_NPC_STATE_FLEEING)
	if(target)
		controller.blackboard[BB_BASIC_MOB_FLEE_TARGET] = target
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_capture(datum/ai_controller/controller)
	if(!(controller.cy_npc_capabilities & CY_NPC_CAP_GRAB))
		return finish(controller, FALSE)
	var/mob/living/living_target = target
	if(!istype(living_target) || QDELETED(living_target))
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_COMBAT)
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
		return CY_NPC_ORDER_RUNNING
	if(living_target.stat != CONSCIOUS || living_target.IsParalyzed() || living_target.IsUnconscious())
		controller.cy_npc_try_restrain(living_target, data)
		controller.cy_npc_try_interact(living_target, FALSE, data)
		var/atom/destination = data?["destination"]
		if(destination)
			controller.cy_npc_make_order(CY_NPC_ORDER_DELIVER, living_target, list("priority" = priority - 1, "destination" = destination, "timeout" = timeout || 1 MINUTES))
	else
		controller.cy_npc_try_interact(living_target, TRUE, list(CTRL_CLICK = TRUE))
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_restrain(datum/ai_controller/controller)
	controller.cy_npc_set_state(CY_NPC_STATE_RESTRAINING)
	var/mob/living/living_target = target
	if(!istype(living_target))
		return finish(controller, FALSE)
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
		return CY_NPC_ORDER_RUNNING
	return finish(controller, controller.cy_npc_try_restrain(living_target, data))

/datum/cy_npc_order/proc/process_carry(datum/ai_controller/controller)
	if(!(controller.cy_npc_capabilities & CY_NPC_CAP_CARRY))
		return finish(controller, FALSE)
	var/mob/living/living_target = target
	if(!istype(living_target))
		return finish(controller, FALSE)
	controller.blackboard[BB_CY_NPC_CARRY_TARGET] = living_target
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
		return CY_NPC_ORDER_RUNNING
	controller.cy_npc_try_interact(living_target, FALSE, data)
	if(ismovable(living_target) && ismob(controller.pawn))
		var/mob/living/living_pawn = controller.pawn
		living_pawn.start_pulling(living_target, supress_message = TRUE)
	return finish(controller, TRUE)

/datum/cy_npc_order/proc/process_deliver(datum/ai_controller/controller)
	var/atom/destination = data?["destination"] || controller.blackboard[BB_CY_NPC_DELIVERY_TARGET]
	if(!destination)
		return process_move(controller)
	controller.cy_npc_set_state(CY_NPC_STATE_DELIVERING)
	if(target && get_dist(controller.pawn, target) <= 1)
		controller.blackboard[BB_CY_NPC_CARRY_TARGET] = target
	target_turf = get_turf(destination)
	var/result = process_move(controller)
	if(status == CY_NPC_ORDER_DONE || get_dist(controller.pawn, destination) <= 1)
		controller.cy_npc_try_drop(destination, list("item" = controller.blackboard[BB_CY_NPC_CARRY_TARGET], "destination" = destination))
		return finish(controller, TRUE)
	return result

/datum/cy_npc_order/proc/process_use(datum/ai_controller/controller)
	if(!target || QDELETED(target))
		return finish(controller, FALSE)
	if(get_dist(controller.pawn, target) > 1)
		controller.set_movement_target(src, target)
		return CY_NPC_ORDER_RUNNING
	controller.cy_npc_try_interact(target)
	return finish(controller, TRUE)

/datum/cy_npc_order/proc/process_heal(datum/ai_controller/controller)
	var/mob/living/living_target = target
	if(!istype(living_target))
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_HELPING)
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
		return CY_NPC_ORDER_RUNNING
	return finish(controller, controller.cy_npc_try_heal(living_target, data))

/datum/cy_npc_order/proc/process_repair(datum/ai_controller/controller)
	if(!target)
		return finish(controller, FALSE)
	controller.cy_npc_set_state(CY_NPC_STATE_REPAIRING)
	if(get_dist(controller.pawn, target) > 1)
		controller.set_movement_target(src, target)
		return CY_NPC_ORDER_RUNNING
	var/success = controller.cy_npc_try_repair(target, data)
	var/datum/cy_contract/contract = get_contract()
	if(contract && success)
		contract.metadata["last_ai_repair"] = world.time
	return finish(controller, success)

/datum/cy_npc_order/proc/process_pickup(datum/ai_controller/controller)
	var/atom/movable/movable_target = target
	if(!istype(movable_target))
		return finish(controller, FALSE)
	if(get_dist(controller.pawn, movable_target) > 1)
		controller.set_movement_target(src, movable_target)
		return CY_NPC_ORDER_RUNNING
	return finish(controller, controller.cy_npc_try_pickup(movable_target, data))

/datum/cy_npc_order/proc/process_drop(datum/ai_controller/controller)
	return finish(controller, controller.cy_npc_try_drop(target, data))

/datum/cy_npc_order/proc/process_equip(datum/ai_controller/controller)
	var/atom/movable/movable_target = target
	if(!istype(movable_target))
		return finish(controller, FALSE)
	if(get_dist(controller.pawn, movable_target) > 1)
		controller.set_movement_target(src, movable_target)
		return CY_NPC_ORDER_RUNNING
	return finish(controller, controller.cy_npc_try_equip(movable_target, data))

/datum/cy_npc_order/proc/process_search(datum/ai_controller/controller)
	controller.cy_npc_set_state(CY_NPC_STATE_SEARCHING)
	var/atom/center = target || controller.blackboard[BB_CY_NPC_SEARCH_CENTER] || controller.blackboard[BB_CY_NPC_HOME]
	if(!center)
		return CY_NPC_ORDER_RUNNING
	var/radius = data?["radius"] || controller.cy_npc_profile?.threat_scan_range || 7
	var/turf/center_turf = get_turf(center)
	var/datum/cy_contract/contract = get_contract()
	if(contract && get_dist(controller.pawn, center_turf || controller.pawn) <= radius)
		contract.metadata["recon_scanned"] = TRUE
		return finish(controller, TRUE)
	if(!center_turf)
		return CY_NPC_ORDER_RUNNING
	if(get_dist(controller.pawn, center_turf) > radius)
		controller.set_movement_target(src, center_turf)
	return CY_NPC_ORDER_RUNNING

/datum/cy_npc_order/proc/process_disarm(datum/ai_controller/controller)
	var/mob/living/living_target = target
	if(!istype(living_target))
		return finish(controller, FALSE)
	if(get_dist(controller.pawn, living_target) > 1)
		controller.set_movement_target(src, living_target)
		return CY_NPC_ORDER_RUNNING
	return finish(controller, controller.cy_npc_try_interact(living_target, TRUE, list(CTRL_CLICK = TRUE)))

/datum/cy_npc_order/proc/process_signal(datum/ai_controller/controller)
	controller.blackboard[BB_CY_NPC_LAST_SIGNAL] = list("message" = message, "time" = world.time, "target" = target)
	controller.cy_npc_remember_event(CY_NPC_EVENT_ALARM, target, message)
	controller.cy_npc_alert_allies(target, message)
	return finish(controller, TRUE)

/datum/cy_npc_order/proc/process_ability(datum/ai_controller/controller)
	if(!(controller.cy_npc_capabilities & (CY_NPC_CAP_DEMONS | CY_NPC_CAP_IMPLANTS)))
		return finish(controller, FALSE)
	return finish(controller, controller.cy_npc_try_ability(target, data))
