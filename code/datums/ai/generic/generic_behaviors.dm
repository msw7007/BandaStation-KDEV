
/datum/ai_behavior/resist/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	living_pawn.ai_controller.set_blackboard_key(BB_RESISTING, TRUE)
	living_pawn.execute_resist()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/battle_screech
	///List of possible screeches the behavior has
	var/list/screeches

/datum/ai_behavior/battle_screech/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	INVOKE_ASYNC(living_pawn, TYPE_PROC_REF(/mob, emote), pick(screeches))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Moves to target then finishes
/datum/ai_behavior/move_to_target
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT

/datum/ai_behavior/move_to_target/perform(seconds_per_tick, datum/ai_controller/controller)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED


/datum/ai_behavior/break_spine
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH
	action_cooldown = 0.7 SECONDS
	var/give_up_distance = 10

/datum/ai_behavior/break_spine/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/break_spine/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/mob/living/batman = controller.blackboard[target_key]
	var/mob/living/big_guy = controller.pawn //he was molded by the darkness

	if(QDELETED(batman) || get_dist(batman, big_guy) >= give_up_distance)
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED

	if(batman.stat != CONSCIOUS)
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

	big_guy.start_pulling(batman)
	big_guy.face_atom(batman)

	batman.visible_message(span_warning("[batman] gets a slightly too tight hug from [big_guy]!"), span_userdanger("You feel your body break as [big_guy] embraces you!"))

	for(var/zone in GLOB.all_body_zones - BODY_ZONE_HEAD)
		batman.apply_damage(15, BRUTE, zone, wound_bonus = 35)

	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/break_spine/finish_action(datum/ai_controller/controller, succeeded, target_key)
	if(succeeded)
		var/mob/living/bane = controller.pawn
		if(QDELETED(bane)) // pawn can be null at this point
			return ..()
		bane.stop_pulling()
		controller.clear_blackboard_key(target_key)
	return ..()

/// Use in hand the currently held item
/datum/ai_behavior/use_in_hand
	behavior_flags = AI_BEHAVIOR_MOVE_AND_PERFORM


/datum/ai_behavior/use_in_hand/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/pawn = controller.pawn
	var/obj/item/held = pawn.get_active_held_item()
	if(!held)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	pawn.activate_hand()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/// Use the currently held item, or unarmed, on a weakref to an object in the world
/datum/ai_behavior/use_on_object
	required_distance = 1
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/use_on_object/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	if(target == controller.pawn) // this can sometimes end up as ourselves, in which case there is no reason to move
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/use_on_object/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.ai_interact(target = target, combat_mode = FALSE)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/give
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH


/datum/ai_behavior/give/setup(datum/ai_controller/controller, target_key)
	. = ..()
	set_movement_target(controller, controller.blackboard[target_key])

/datum/ai_behavior/give/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/mob/living/pawn = controller.pawn
	var/obj/item/held_item = pawn.get_active_held_item()
	var/atom/target = controller.blackboard[target_key]

	if(!held_item) //if held_item is null, we pretend that action was successful
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	if(QDELETED(target) || !target.IsReachableBy(pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/mob/living/living_target = target
	if(!isliving(living_target)) // target should reasonably only ever be set to a living mob
		stack_trace("Tried to give an item to a non-living target!")
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/perform_flags = try_to_give_item(controller, living_target, held_item)
	if(perform_flags & AI_BEHAVIOR_FAILED)
		return perform_flags
	controller.PauseAi(1.5 SECONDS)
	living_target.visible_message(
		span_info("[pawn] starts trying to give [held_item] to [living_target]!"),
		span_warning("[pawn] tries to give you [held_item]!")
	)
	if(!do_after(pawn, 1 SECONDS, living_target))
		return AI_BEHAVIOR_DELAY | perform_flags

	perform_flags |= try_to_give_item(controller, living_target, held_item, actually_give = TRUE)
	return AI_BEHAVIOR_DELAY | perform_flags

/datum/ai_behavior/give/proc/try_to_give_item(datum/ai_controller/controller, mob/living/target, obj/item/held_item, actually_give)
	if(QDELETED(held_item) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/has_left_pocket = target.can_equip(held_item, ITEM_SLOT_LPOCKET)
	var/has_right_pocket = target.can_equip(held_item, ITEM_SLOT_RPOCKET)
	var/has_valid_hand

	for(var/hand_index in target.get_empty_held_indexes())
		if(target.can_put_in_hand(held_item, hand_index))
			has_valid_hand = TRUE
			break

	if(!has_left_pocket && !has_right_pocket && !has_valid_hand)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(!actually_give)
		return AI_BEHAVIOR_DELAY

	if(!has_valid_hand || prob(50))
		target.equip_to_slot_if_possible(held_item, (!has_left_pocket ? ITEM_SLOT_RPOCKET : (prob(50) ? ITEM_SLOT_LPOCKET : ITEM_SLOT_RPOCKET)))
	else
		target.put_in_hands(held_item)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/give/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

/datum/ai_behavior/consume
	action_cooldown = 2 SECONDS

/datum/ai_behavior/consume/perform(seconds_per_tick, datum/ai_controller/controller, target_key, hunger_timer_key)
	var/mob/living/living_pawn = controller.pawn
	var/obj/item/target = controller.blackboard[target_key]
	if(QDELETED(target) || !living_pawn.is_holding(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.ai_interact(target = living_pawn, combat_mode = FALSE)

	return AI_BEHAVIOR_DELAY | (is_content(living_pawn, target) ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_behavior/consume/finish_action(datum/ai_controller/controller, succeeded, target_key, hunger_timer_key)
	. = ..()
	if(!succeeded)
		return
	controller.set_blackboard_key(hunger_timer_key, world.time + rand(12 SECONDS, 60 SECONDS))

	var/mob/living/living_pawn = controller.pawn
	var/obj/item/target = controller.blackboard[target_key]
	if(!QDELETED(target) && !DOING_INTERACTION_WITH_TARGET(living_pawn, target))
		controller.clear_blackboard_key(target_key)
		living_pawn.dropItemToGround(target) // drops empty drink glasses
	for(var/obj/item/trash/trash in living_pawn.held_items)
		living_pawn.dropItemToGround(trash) // drops spawned trash items

/// Check if the target is fully consumed, or being actively consumed, or if we're just bored of eating it
/datum/ai_behavior/consume/proc/is_content(mob/living/living_pawm, obj/item/target)
	if(QDELETED(target))
		return TRUE
	if(DOING_INTERACTION_WITH_TARGET(living_pawm, target))
		return TRUE
	if(target.reagents?.total_volume <= 0)
		return TRUE
	// Even if we don't finish it all we can randomly decide to be done
	return prob(10)

// navigate to target item and pick it up if we can
/datum/ai_behavior/navigate_to_and_pick_up
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH
	action_cooldown = 2 SECONDS

/datum/ai_behavior/navigate_to_and_pick_up/setup(datum/ai_controller/controller, target_key, drop_held = TRUE)
	. = ..()
	set_movement_target(controller, controller.blackboard[target_key])

/datum/ai_behavior/navigate_to_and_pick_up/setup(datum/ai_controller/controller, target_key, drop_held = TRUE)
	var/mob/living/living_pawn = controller.pawn
	var/obj/item/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(living_pawn.is_holding(target)) // already in hands
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	if(!target.IsReachableBy(living_pawn)) // can't reach it, despite being adjacent
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(living_pawn.get_active_held_item()) // something is in our hands already
		if(!drop_held || !living_pawn.dropItemToGround(living_pawn.get_active_held_item()))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.ai_interact(target, combat_mode = FALSE)
	return AI_BEHAVIOR_DELAY | (target.loc == living_pawn ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/**
 * Drops items in hands, very important for future behaviors that require the pawn to grab stuff
 */
/datum/ai_behavior/drop_item

/datum/ai_behavior/drop_item/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	var/list/my_held_items = living_pawn.held_items - GetBestWeapon(controller, null, living_pawn.held_items)
	if(!length(my_held_items))
		return AI_BEHAVIOR_FAILED | AI_BEHAVIOR_DELAY
	living_pawn.dropItemToGround(pick(my_held_items))
	return AI_BEHAVIOR_SUCCEEDED | AI_BEHAVIOR_DELAY

/// This behavior involves attacking a target.
/datum/ai_behavior/attack
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/attack/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !isturf(living_pawn.loc))
		return AI_BEHAVIOR_DELAY

	var/atom/movable/attack_target = controller.blackboard[BB_ATTACK_TARGET]
	if(!attack_target || !can_see(living_pawn, attack_target, length = controller.blackboard[BB_VISION_RANGE]))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/mob/living/living_target = attack_target
	if(istype(living_target) && (living_target.stat == DEAD))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	set_movement_target(controller, living_target)
	attack(controller, living_target)
	return AI_BEHAVIOR_DELAY

/datum/ai_behavior/attack/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.clear_blackboard_key(BB_ATTACK_TARGET)

/// A proc representing when the mob is pushed to actually attack the target. Again, subtypes can be used to represent different attacks from different animals, or it can be some other generic behavior
/datum/ai_behavior/attack/proc/attack(datum/ai_controller/controller, mob/living/living_target)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return
	living_pawn.ClickOn(living_target, list())

/// This behavior involves attacking a target.
/datum/ai_behavior/follow
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM

/datum/ai_behavior/follow/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !isturf(living_pawn.loc))
		return AI_BEHAVIOR_DELAY

	var/atom/movable/follow_target = controller.blackboard[BB_FOLLOW_TARGET]
	if(!follow_target || get_dist(living_pawn, follow_target) > controller.blackboard[BB_VISION_RANGE])
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/mob/living/living_target = follow_target
	if(istype(living_target) && (living_target.stat == DEAD))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	set_movement_target(controller, living_target)
	return AI_BEHAVIOR_DELAY

/datum/ai_behavior/follow/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.clear_blackboard_key(BB_FOLLOW_TARGET)

/datum/ai_behavior/perform_emote

/datum/ai_behavior/perform_emote/perform(seconds_per_tick, datum/ai_controller/controller, emote, speech_sound)
	. = ..()
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_INSTANT
	living_pawn.manual_emote(emote)
	if(speech_sound) // Only audible emotes will pass in a sound
		playsound(living_pawn, speech_sound, 80, vary = TRUE, pressure_affected =TRUE, ignore_walls = FALSE)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/perform_speech

/datum/ai_behavior/perform_speech/perform(seconds_per_tick, datum/ai_controller/controller, speech, speech_sound)
	. = ..()

	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_INSTANT
	living_pawn.say(speech, forced = "AI Controller")
	if(speech_sound)
		playsound(living_pawn, speech_sound, 80, vary = TRUE)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/perform_speech_radio

/datum/ai_behavior/perform_speech_radio/perform(seconds_per_tick, datum/ai_controller/controller, speech, obj/item/radio/speech_radio, list/try_channels = list(RADIO_CHANNEL_COMMON))
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !istype(speech_radio) || QDELETED(speech_radio) || !length(try_channels))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	speech_radio.talk_into(living_pawn, speech, pick(try_channels))
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

// Cyberpunk city task behaviors. They intentionally use tg AI controller
// blackboard/movement and do not introduce a separate AI core.

/proc/cyberpunk_city_cardinal_dir_to(atom/source, atom/target)
	var/direction = get_dir(source, target)
	if(direction & NORTH)
		return NORTH
	if(direction & SOUTH)
		return SOUTH
	if(direction & EAST)
		return EAST
	if(direction & WEST)
		return WEST
	return 0

/proc/cyberpunk_city_find_climb_obstacle(mob/living/living_pawn, atom/target)
	if(!istype(living_pawn) || QDELETED(target))
		return null
	var/direction = cyberpunk_city_cardinal_dir_to(living_pawn, target)
	if(!direction)
		return null
	var/turf/next_turf = get_step(living_pawn, direction)
	if(!next_turf || next_turf.density)
		return null
	for(var/atom/movable/obstacle as anything in next_turf)
		if(obstacle.density && !(obstacle.flags_1 & ON_BORDER_1) && HAS_TRAIT(obstacle, TRAIT_CLIMBABLE))
			return obstacle
	return null

/datum/ai_behavior/cyberpunk_set_task_state

/datum/ai_behavior/cyberpunk_set_task_state/perform(seconds_per_tick, datum/ai_controller/controller, new_state)
	controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, new_state)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/cyberpunk_complete_task

/datum/ai_behavior/cyberpunk_complete_task/perform(seconds_per_tick, datum/ai_controller/controller, result = "completed")
	controller.cyberpunk_complete_city_task(result)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/cyberpunk_fail_task

/datum/ai_behavior/cyberpunk_fail_task/perform(seconds_per_tick, datum/ai_controller/controller, reason = "failed")
	controller.cyberpunk_fail_city_task(reason)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/cyberpunk_climb_obstacle
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_climb_obstacle/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !isturf(living_pawn.loc))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/atom/target = controller.blackboard[target_key]
	var/atom/movable/obstacle = cyberpunk_city_find_climb_obstacle(living_pawn, target)
	if(!obstacle)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/direction = cyberpunk_city_cardinal_dir_to(living_pawn, target)
	var/original_density = obstacle.density
	obstacle.set_density(FALSE)
	var/succeeded = step(living_pawn, direction)
	obstacle.set_density(original_density)
	return AI_BEHAVIOR_DELAY | (succeeded ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_behavior/cyberpunk_pickup_cargo
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_pickup_cargo/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/atom/cargo = controller.blackboard[BB_CP_CARGO]
	if(QDELETED(cargo))
		controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_LOST)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/obj/item/cargo_item = cargo
	if(istype(cargo_item))
		if(living_pawn.is_holding(cargo_item))
			controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
			controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
		if(!cargo_item.IsReachableBy(living_pawn))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		if(!controller.cyberpunk_has_capability(CP_AI_CAP_HANDS))
			controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
			controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
		if(living_pawn.get_active_held_item())
			living_pawn.dropItemToGround(living_pawn.get_active_held_item())
		if(!living_pawn.put_in_hands(cargo_item))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	else if(isliving(cargo))
		var/mob/living/cargo_mob = cargo
		if(living_pawn.pulling == cargo_mob)
			controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
			controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
		if(!controller.cyberpunk_has_capability(CP_AI_CAP_HANDS) || !cargo_mob.Adjacent(living_pawn))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		living_pawn.start_pulling(cargo_mob, supress_message = TRUE)
		if(living_pawn.pulling != cargo_mob)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	else if(!controller.cyberpunk_has_capability(CP_AI_CAP_CARGO_SLOT))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
	controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/cyberpunk_deliver_cargo
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_deliver_cargo/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/atom/receiver = controller.blackboard[BB_CP_CARGO_RECEIVER]
	if(!receiver)
		receiver = controller.blackboard[BB_CP_ROUTE_TARGET]
	if(QDELETED(receiver))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/atom/cargo = controller.blackboard[BB_CP_CARGO]
	var/obj/item/cargo_item = cargo
	var/contract_id = controller.blackboard[BB_CP_CONTRACT_ID]
	if(istype(cargo_item))
		if(contract_id)
			cargo_item.cyberpunk_contract_id = contract_id
		var/mob/living/receiver_mob = receiver
		if(istype(receiver_mob) && living_pawn.is_holding(cargo_item) && receiver_mob.Adjacent(living_pawn))
			receiver_mob.put_in_hands(cargo_item)
		else if(living_pawn.is_holding(cargo_item))
			living_pawn.dropItemToGround(cargo_item)
			cargo_item.forceMove(get_turf(receiver))
		else if(get_turf(cargo_item) != get_turf(receiver))
			cargo_item.forceMove(get_turf(receiver))
		SSeconomy?.record_cyberpunk_contract_item_in_hands(living_pawn, cargo_item)
		if(istype(receiver_mob))
			SSeconomy?.record_cyberpunk_contract_item_in_hands(receiver_mob, cargo_item)
		cyberpunk_notify_ai_cargo_delivered(cargo_item, living_pawn)
	else if(isliving(cargo))
		var/mob/living/cargo_mob = cargo
		if(living_pawn.pulling == cargo_mob)
			living_pawn.stop_pulling()
		var/turf/receiver_turf = get_turf(receiver)
		if(receiver_turf && get_dist(cargo_mob, receiver_turf) > 1)
			cargo_mob.forceMove(receiver_turf)
		cyberpunk_notify_ai_cargo_delivered(cargo_mob, living_pawn)

	var/datum/cyberpunk_contract/contract = controller.blackboard[BB_CP_CONTRACT_REF]
	if(!contract && contract_id)
		contract = SSeconomy?.get_cyberpunk_contract(contract_id)
	if(contract)
		contract.add_history("[living_pawn.real_name || living_pawn.name] AI delivery reached [receiver]")
		contract.check_nearby_target(living_pawn)

	controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_DELIVERED)
	if(controller.blackboard_key_exists(BB_CP_ROUTE_RETURN_POINT))
		controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_RETURNING)
	else
		controller.cyberpunk_complete_city_task("cargo delivered")
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/cyberpunk_use_z_transition
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_use_z_transition/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/target_z = controller.blackboard[BB_CP_ROUTE_TARGET_Z]
	var/next_state = controller.blackboard[BB_CP_ROUTE_PHASE]
	if(!next_state)
		next_state = CP_AI_TASK_ROUTE_TO_TARGET
	if(!target_z || living_pawn.z == target_z)
		controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, next_state)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	var/atom/transition = controller.blackboard[BB_CP_ROUTE_Z_TRANSITION]
	if(QDELETED(transition))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/obj/structure/ladder/ladder = transition
	if(istype(ladder))
		ladder.travel(living_pawn, target_z > living_pawn.z)
	else
		var/direction = target_z > living_pawn.z ? UP : DOWN
		if(!living_pawn.zMove(direction, z_move_flags = ZMOVE_FLIGHT_FLAGS))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(living_pawn.z == target_z)
		controller.clear_blackboard_key(BB_CP_ROUTE_Z_TRANSITION)
		controller.set_blackboard_key(BB_CP_ROUTE_CURRENT_Z, living_pawn.z)
		controller.set_blackboard_key(BB_CP_CITY_TASK_STATE, next_state)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

/datum/ai_behavior/cyberpunk_work_task
	action_cooldown = 1 SECONDS

/datum/ai_behavior/cyberpunk_work_task/perform(seconds_per_tick, datum/ai_controller/controller)
	if(controller.blackboard[BB_CP_CITY_TASK] == CP_AI_TASK_REPAIR)
		var/atom/repair_target = controller.blackboard[BB_CP_ROUTE_TARGET]
		if(!repair_target?.uses_integrity)
			controller.cyberpunk_fail_city_task("repair target invalid")
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		if(repair_target.get_integrity() < repair_target.max_integrity)
			repair_target.repair_damage(max(5, round(repair_target.max_integrity * 0.05)))
			if(repair_target.get_integrity() < repair_target.max_integrity)
				return AI_BEHAVIOR_DELAY
		controller.cyberpunk_complete_city_task("repair completed")
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	var/finish_at = controller.blackboard[BB_CP_CITY_TASK_FINISH_AT]
	if(finish_at && world.time < finish_at)
		var/atom/target = controller.blackboard[BB_CP_ROUTE_TARGET]
		if(target && controller.cyberpunk_has_capability(CP_AI_CAP_USE_TERMINAL))
			controller.ai_interact(target, combat_mode = FALSE)
		return AI_BEHAVIOR_DELAY

	var/datum/cyberpunk_contract/contract = controller.blackboard[BB_CP_CONTRACT_REF]
	var/mob/living/living_pawn = controller.pawn
	if(contract && istype(living_pawn))
		contract.check_nearby_target(living_pawn)
	controller.cyberpunk_complete_city_task("work finished")
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

//song behaviors

/datum/ai_behavior/setup_instrument

/datum/ai_behavior/setup_instrument/perform(seconds_per_tick, datum/ai_controller/controller, song_instrument_key, song_lines_key)
	var/obj/item/instrument/song_instrument = controller.blackboard[song_instrument_key]
	var/datum/song/song = song_instrument.song
	var/song_lines = controller.blackboard[song_lines_key]

	//just in case- it won't do anything if the instrument isn't playing
	song.stop_playing()
	song.ParseSong(new_song = song_lines)
	song.repeat = 10
	song.volume = song.max_volume - 10
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/play_instrument

/datum/ai_behavior/play_instrument/perform(seconds_per_tick, datum/ai_controller/controller, song_instrument_key)
	var/obj/item/instrument/song_instrument = controller.blackboard[song_instrument_key]
	var/datum/song/song = song_instrument.song

	song.start_playing(controller.pawn)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/find_nearby

/datum/ai_behavior/find_nearby/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/list/possible_targets = list()
	for(var/atom/thing in view(2, controller.pawn))
		if(!thing.mouse_opacity)
			continue
		if(thing.IsObscured())
			continue
		if(isitem(thing))
			var/obj/item/item = thing
			if(item.item_flags & ABSTRACT)
				continue
		possible_targets += thing
	if(!possible_targets.len)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(target_key, pick(possible_targets))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
