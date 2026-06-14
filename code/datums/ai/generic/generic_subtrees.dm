/**
 * Generic Instrument Subtree, For your pawn playing instruments
 *
 * Requires at least a living mob that can hold items.
 *
 * relevant blackboards:
 * * BB_SONG_INSTRUMENT - set by this subtree, is the song datum the pawn plays music from.
 * * BB_SONG_LINES - not set by this subtree, is the song loaded into the song datum.
 */
/datum/ai_planning_subtree/generic_play_instrument/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/obj/item/instrument/song_player = controller.blackboard[BB_SONG_INSTRUMENT]

	if(!song_player)
		controller.queue_behavior(/datum/ai_behavior/find_and_set/in_hands, BB_SONG_INSTRUMENT, /obj/item/instrument)
		return //we can't play a song since we do not have an instrument

	var/list/parsed_song_lines = splittext(controller.blackboard[BB_SONG_LINES], "\n")
	popleft(parsed_song_lines) //remove BPM as it is parsed out
	if(!compare_list(song_player.song.lines, parsed_song_lines) || !song_player.song.repeat)
		controller.queue_behavior(/datum/ai_behavior/setup_instrument, BB_SONG_INSTRUMENT, BB_SONG_LINES)

	if(!song_player.song.playing) //we may stop playing if we weren't playing before, were setting up dk theme, or ran out of repeats (also causing setup behavior)
		controller.queue_behavior(/datum/ai_behavior/play_instrument, BB_SONG_INSTRUMENT)

/datum/ai_planning_subtree/generic_play_instrument/end_planning

/datum/ai_planning_subtree/generic_play_instrument/end_planning/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if (controller.blackboard_key_exists(BB_SONG_INSTRUMENT))
		return SUBTREE_RETURN_FINISH_PLANNING // Don't plan anything else if we're playing an instrument


/**
 * Generic Resist Subtree, resist if it makes sense to!
 *
 * Requires nothing beyond a living pawn, makes sense on a good amount of mobs since anything can get buckled.
 *
 * relevant blackboards:
 * * None!
 */
/datum/ai_planning_subtree/generic_resist/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/living_pawn = controller.pawn

	if(SHOULD_RESIST(living_pawn) && SPT_PROB(RESIST_SUBTREE_PROB, seconds_per_tick))
		controller.queue_behavior(/datum/ai_behavior/resist) //BRO IM ON FUCKING FIRE BRO
		return SUBTREE_RETURN_FINISH_PLANNING //IM NOT DOING ANYTHING ELSE BUT EXTINGUISH MYSELF, GOOD GOD HAVE MERCY.

/**
 * Generic Hunger Subtree,
 *
 * Requires at least a living mob that can hold items.
 *
 * relevant blackboards:
 * * BB_NEXT_HUNGRY - set by this subtree, is when the controller is next hungry
 */
/datum/ai_planning_subtree/generic_hunger

/datum/ai_planning_subtree/generic_hunger/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/living_pawn = controller.pawn
	if(living_pawn.nutrition > NUTRITION_LEVEL_HUNGRY)
		return

	var/next_eat = controller.blackboard[BB_NEXT_HUNGRY]
	if(!next_eat)
		//inits the blackboard timer
		next_eat = world.time + rand(0, 30 SECONDS)
		controller.set_blackboard_key(BB_NEXT_HUNGRY, next_eat)

	if(world.time < next_eat)
		return

	// find food
	var/atom/food_target = controller.blackboard[BB_FOOD_TARGET]
	if(isnull(food_target))
		controller.queue_behavior(/datum/ai_behavior/find_and_set/food_or_drink/to_eat, BB_FOOD_TARGET, /obj/item, 2)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(living_pawn.is_holding(food_target))
		controller.queue_behavior(/datum/ai_behavior/consume, BB_FOOD_TARGET, BB_NEXT_HUNGRY)
	// it's been moved since we found it
	else if(!isturf(food_target.loc))
		// someone took it. we will fight over it!
		if(isliving(food_target.loc) && will_fight_for_food(food_target.loc, living_pawn, controller))
			controller.add_blackboard_key_assoc(BB_MONKEY_ENEMIES, food_target.loc, MONKEY_FOOD_HATRED_AMOUNT)
		// eh, find something else
		else
			controller.clear_blackboard_key(BB_FOOD_TARGET)
		return SUBTREE_RETURN_FINISH_PLANNING
	else
		controller.queue_behavior(/datum/ai_behavior/navigate_to_and_pick_up, BB_FOOD_TARGET, TRUE)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/generic_hunger/proc/will_fight_for_food(mob/living/thief, mob/living/monkey, datum/ai_controller/controller)
	if(controller.blackboard[BB_MONKEY_AGGRESSIVE])
		return TRUE
	if(controller.blackboard[BB_MONKEY_TAMED])
		return FALSE
	return prob(100 * ((NUTRITION_LEVEL_HUNGRY - monkey.nutrition) / NUTRITION_LEVEL_HUNGRY))

/**
 * Cyberpunk city task subtree.
 *
 * This is a thin task router over tg AI behaviors/movement. Task data stays in
 * the controller blackboard, while physical actions remain behaviors.
 */
/datum/ai_planning_subtree/cyberpunk_city_task/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/task = controller.blackboard[BB_CP_CITY_TASK]
	if(!task)
		return

	var/task_state = controller.blackboard[BB_CP_CITY_TASK_STATE]
	switch(task_state)
		if(CP_AI_TASK_ROUTE_TO_SOURCE)
			var/atom/source = controller.blackboard[BB_CP_CARGO_SOURCE]
			var/turf/source_turf = get_turf(source)
			var/turf/source_route_pawn_turf = get_turf(controller.pawn)
			if(QDELETED(source))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "source missing")
			else if(source_turf && source_route_pawn_turf && source_turf.z != source_route_pawn_turf.z && controller.cyberpunk_prepare_z_transition(CP_AI_TASK_ROUTE_TO_SOURCE))
				return SUBTREE_RETURN_FINISH_PLANNING
			else if(get_dist(controller.pawn, source) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, CP_AI_TASK_PICKUP)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_CARGO_SOURCE)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_PICKUP)
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_pickup_cargo)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_ROUTE_TO_TARGET)
			var/atom/target = controller.blackboard[BB_CP_CARGO_RECEIVER]
			if(!target)
				target = controller.blackboard[BB_CP_ROUTE_TARGET]
			var/turf/target_turf = get_turf(target)
			var/turf/target_route_pawn_turf = get_turf(controller.pawn)
			if(QDELETED(target))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "target missing")
			else if(target_turf && target_route_pawn_turf && target_turf.z != target_route_pawn_turf.z && controller.cyberpunk_prepare_z_transition(CP_AI_TASK_ROUTE_TO_TARGET))
				return SUBTREE_RETURN_FINISH_PLANNING
			else if(get_dist(controller.pawn, target) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, controller.blackboard[BB_CP_CARGO] ? CP_AI_TASK_DROPOFF : CP_AI_TASK_WORKING)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, controller.blackboard[BB_CP_CARGO_RECEIVER] ? BB_CP_CARGO_RECEIVER : BB_CP_ROUTE_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_ROUTE_TO_Z_TRANSITION)
			var/atom/transition = controller.blackboard[BB_CP_ROUTE_Z_TRANSITION]
			if(QDELETED(transition))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "z transition missing")
			else if(get_dist(controller.pawn, transition) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, CP_AI_TASK_USE_Z_TRANSITION)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_ROUTE_Z_TRANSITION)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_USE_Z_TRANSITION)
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_use_z_transition)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_DROPOFF)
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_deliver_cargo)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_WORKING)
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_work_task)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_RETURNING)
			var/atom/return_point = controller.blackboard[BB_CP_ROUTE_RETURN_POINT]
			if(QDELETED(return_point) || get_dist(controller.pawn, return_point) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_complete_task, "returned")
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_ROUTE_RETURN_POINT)
			return SUBTREE_RETURN_FINISH_PLANNING

		if(CP_AI_TASK_CREATED)
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, CP_AI_TASK_WORKING)
			return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/cyberpunk_security_response

/datum/ai_planning_subtree/cyberpunk_security_response/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller.cyberpunk_has_capability(CP_AI_CAP_COMBAT))
		return
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || living_pawn.stat == DEAD)
		return
	var/atom/threat = controller.blackboard[BB_CP_THREAT_TARGET]
	if(QDELETED(threat))
		controller.clear_blackboard_key(BB_CP_THREAT_TARGET)
		controller.clear_blackboard_key(BB_CP_THREAT_LEVEL)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_BASIC_MOB_FLEE_TARGET)
		return
	if(living_pawn.maxHealth > 0 && living_pawn.health <= living_pawn.maxHealth * 0.2)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.set_blackboard_key(BB_BASIC_MOB_FLEE_TARGET, threat)
		return
	controller.clear_blackboard_key(BB_BASIC_MOB_FLEE_TARGET)
	if(living_pawn.maxHealth > 0 && living_pawn.health <= living_pawn.maxHealth * 0.5)
		controller.cyberpunk_call_for_help(threat, "wounded")
	var/mob/living/threat_mob = threat
	if(istype(threat_mob) && HAS_TRAIT(threat_mob, TRAIT_RESTRAINED) && !istype(get_area(threat_mob), /area/station/security))
		var/turf/security_turf = cyberpunk_find_security_delivery_turf()
		if(security_turf && !controller.blackboard_key_exists(BB_CP_CITY_TASK))
			controller.cyberpunk_assign_city_task(CP_AI_TASK_GUARD, threat_mob, security_turf, threat_mob, null, 2 MINUTES, security_turf)
			return SUBTREE_RETURN_FINISH_PLANNING
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, threat)
