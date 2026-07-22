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
 * This is a small GOAP router over tg AI behaviors/movement. Task data stays in
 * the controller blackboard, while physical actions remain behaviors.
 */
/datum/ai_planning_subtree/cyberpunk_city_task/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/static/datum/cyberpunk_goap_planner/city_task_planner = new
	var/task = controller.blackboard[BB_CP_CITY_TASK]
	if(!task)
		return

	city_task_planner.queue_next_action(controller)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/cyberpunk_goap_planner
	var/max_depth = 8
	var/list/actions

/datum/cyberpunk_goap_planner/proc/queue_next_action(datum/ai_controller/controller)
	normalize_task(controller)

	var/task_state = controller.blackboard[BB_CP_CITY_TASK_STATE]
	if(task_state == CP_AI_TASK_ROUTE_TO_Z_TRANSITION)
		set_current_action(controller, "route_to_z_transition")
		queue_action(controller, "route_to_z_transition")
		return
	if(task_state == CP_AI_TASK_USE_Z_TRANSITION)
		set_current_action(controller, "use_z_transition")
		queue_action(controller, "use_z_transition")
		return

	var/list/world_state = build_world_state(controller)
	var/signature = state_signature(world_state)
	var/list/action_plan = cached_plan(controller, signature)
	if(!action_plan)
		action_plan = build_plan(controller, world_state)
		controller.override_blackboard_key(BB_CP_GOAP_PLAN, action_plan.Copy())
		controller.set_blackboard_key(BB_CP_GOAP_PLAN_SIGNATURE, signature)
	if(!length(action_plan))
		controller.clear_blackboard_key(BB_CP_GOAP_CURRENT_ACTION)
		controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "no city GOAP plan")
		return

	var/current_action = action_plan[1]
	set_current_action(controller, current_action)
	queue_action(controller, current_action)

/datum/cyberpunk_goap_planner/proc/normalize_task(datum/ai_controller/controller)
	var/task = controller.blackboard[BB_CP_CITY_TASK]
	var/atom/cargo = controller.blackboard[BB_CP_CARGO]
	if(!controller.blackboard[BB_CP_CARGO_SOURCE] && cargo && is_delivery_task(task))
		controller.set_blackboard_key(BB_CP_CARGO_SOURCE, cargo)
		controller.set_blackboard_key(BB_CP_ROUTE_SOURCE, cargo)

/datum/cyberpunk_goap_planner/proc/is_delivery_task(task)
	return task in list(CP_AI_TASK_DELIVERY, CP_AI_TASK_CONTRACT, CP_AI_TASK_CARGO, CP_AI_TASK_GUARD)

/datum/cyberpunk_goap_planner/proc/set_current_action(datum/ai_controller/controller, action_id)
	controller.set_blackboard_key(BB_CP_GOAP_CURRENT_ACTION, action_id)

/datum/cyberpunk_goap_planner/proc/cached_plan(datum/ai_controller/controller, signature)
	var/list/known_plan = controller.blackboard[BB_CP_GOAP_PLAN]
	if(controller.blackboard[BB_CP_GOAP_PLAN_SIGNATURE] != signature || !islist(known_plan) || !length(known_plan))
		return null
	return known_plan.Copy()

/datum/cyberpunk_goap_planner/proc/build_plan(datum/ai_controller/controller, list/start_state)
	if(!start_state)
		start_state = build_world_state(controller)
	var/list/open_nodes = list(list(
		"state" = start_state,
		"plan" = list(),
		"cost" = 0,
	))
	var/list/visited = list()

	while(length(open_nodes))
		var/list/node = open_nodes[1]
		open_nodes.Cut(1, 2)
		var/list/node_state = node["state"]
		var/list/node_plan = node["plan"]
		var/node_cost = node["cost"] || 0
		var/signature = state_signature(node_state)
		if(visited[signature])
			continue
		visited[signature] = TRUE

		if(goal_satisfied(node_state))
			return node_plan
		if(length(node_plan) >= max_depth)
			continue

		for(var/datum/cyberpunk_goap_action/action as anything in get_actions())
			if(!action.preconditions_met(node_state))
				continue
			var/list/next_state = action.apply_effects(node_state)
			var/list/next_plan = node_plan.Copy()
			next_plan += action.id
			var/list/next_node = list(
				"state" = next_state,
				"plan" = next_plan,
				"cost" = node_cost + action.cost,
			)
			insert_node(open_nodes, next_node)
	return list()

/datum/cyberpunk_goap_planner/proc/insert_node(list/open_nodes, list/new_node)
	var/new_cost = new_node["cost"] || 0
	for(var/index in 1 to length(open_nodes))
		var/list/existing_node = open_nodes[index]
		if(new_cost < (existing_node["cost"] || 0))
			open_nodes.Insert(index, list(new_node))
			return
	open_nodes += list(new_node)

/datum/cyberpunk_goap_planner/proc/build_world_state(datum/ai_controller/controller)
	var/list/state = list()
	var/task = controller.blackboard[BB_CP_CITY_TASK]
	var/task_state = controller.blackboard[BB_CP_CITY_TASK_STATE]
	var/atom/source = controller.blackboard[BB_CP_CARGO_SOURCE]
	var/atom/target = controller.blackboard[BB_CP_CARGO_RECEIVER] || controller.blackboard[BB_CP_ROUTE_TARGET]
	var/atom/cargo = controller.blackboard[BB_CP_CARGO]
	var/atom/return_point = controller.blackboard[BB_CP_ROUTE_RETURN_POINT]
	var/finish_at = controller.blackboard[BB_CP_CITY_TASK_FINISH_AT]
	var/mob/living/living_pawn = controller.pawn

	state["task_exists"] = TRUE
	state["delivery_task"] = is_delivery_task(task)
	state["work_task"] = !state["delivery_task"]
	state["source_needed"] = state["delivery_task"] && !!source
	state["target_needed"] = state["delivery_task"] || !!target
	state["cargo_needed"] = state["delivery_task"]
	state["source_exists"] = source && !QDELETED(source)
	state["target_exists"] = target && !QDELETED(target)
	state["cargo_exists"] = cargo && !QDELETED(cargo)
	state["return_exists"] = !!return_point && !QDELETED(return_point)
	state["no_return"] = !return_point || QDELETED(return_point)
	state["at_source"] = source && !QDELETED(source) && get_dist(controller.pawn, source) <= 1
	state["at_target"] = target && !QDELETED(target) && get_dist(controller.pawn, target) <= 1
	state["at_return"] = return_point && !QDELETED(return_point) && get_dist(controller.pawn, return_point) <= 1
	state["has_cargo"] = controller.blackboard[BB_CP_CARGO_STATUS] == CP_AI_CARGO_CARRIED
	state["delivered"] = controller.blackboard[BB_CP_CARGO_STATUS] == CP_AI_CARGO_DELIVERED
	state["cargo_lost"] = controller.blackboard[BB_CP_CARGO_STATUS] == CP_AI_CARGO_LOST
	state["timed_out"] = finish_at && world.time >= finish_at
	state["worked"] = FALSE
	state["complete"] = FALSE
	state["failed"] = FALSE

	var/obj/item/cargo_item = cargo
	if(istype(living_pawn) && istype(cargo_item) && living_pawn.is_holding(cargo_item))
		state["has_cargo"] = TRUE
	var/mob/living/cargo_mob = cargo
	if(istype(living_pawn) && istype(cargo_mob) && living_pawn.pulling == cargo_mob)
		state["has_cargo"] = TRUE

	state["traffic_clear"] = TRUE
	cyberpunk_goap_extend_traffic_world_state(controller, state)

	if(task_state == CP_AI_TASK_WORKING && !target)
		state["at_target"] = TRUE
	return state

/datum/cyberpunk_goap_planner/proc/get_actions()
	if(actions)
		return actions
	actions = list(
		new /datum/cyberpunk_goap_action("fail_source_missing", list("source_needed" = TRUE, "source_exists" = FALSE), list("failed" = TRUE), 0),
		new /datum/cyberpunk_goap_action("fail_target_missing", list("target_needed" = TRUE, "target_exists" = FALSE), list("failed" = TRUE), 0),
		new /datum/cyberpunk_goap_action("fail_cargo_missing", list("cargo_needed" = TRUE, "cargo_exists" = FALSE), list("failed" = TRUE), 0),
		new /datum/cyberpunk_goap_action("fail_cargo_lost", list("cargo_needed" = TRUE, "cargo_lost" = TRUE), list("failed" = TRUE), 0),
		new /datum/cyberpunk_goap_action("fail_task_timeout", list("timed_out" = TRUE), list("failed" = TRUE), 0),
		new /datum/cyberpunk_goap_action("route_to_source", list("source_needed" = TRUE, "source_exists" = TRUE, "has_cargo" = FALSE, "at_source" = FALSE), list("at_source" = TRUE), 4),
		new /datum/cyberpunk_goap_action("pickup_cargo", list("source_needed" = TRUE, "cargo_needed" = TRUE, "source_exists" = TRUE, "cargo_exists" = TRUE, "has_cargo" = FALSE, "at_source" = TRUE), list("has_cargo" = TRUE), 1),
		new /datum/cyberpunk_goap_action("pickup_cargo", list("source_needed" = FALSE, "cargo_needed" = TRUE, "cargo_exists" = TRUE, "has_cargo" = FALSE), list("has_cargo" = TRUE), 1),
		new /datum/cyberpunk_goap_action("route_to_target", list("delivery_task" = TRUE, "target_exists" = TRUE, "has_cargo" = TRUE, "at_target" = FALSE), list("at_target" = TRUE), 4),
		new /datum/cyberpunk_goap_action("dropoff_cargo", list("delivery_task" = TRUE, "target_exists" = TRUE, "cargo_exists" = TRUE, "has_cargo" = TRUE, "at_target" = TRUE), list("delivered" = TRUE), 1),
		new /datum/cyberpunk_goap_action("return_to_point", list("delivery_task" = TRUE, "delivered" = TRUE, "return_exists" = TRUE, "at_return" = FALSE), list("at_return" = TRUE), 3),
		new /datum/cyberpunk_goap_action("complete_task", list("delivery_task" = TRUE, "delivered" = TRUE, "at_return" = TRUE), list("complete" = TRUE), 0),
		new /datum/cyberpunk_goap_action("complete_task", list("delivery_task" = TRUE, "delivered" = TRUE, "no_return" = TRUE), list("complete" = TRUE), 0),
		new /datum/cyberpunk_goap_action("route_to_target", list("work_task" = TRUE, "target_needed" = TRUE, "target_exists" = TRUE, "traffic_clear" = TRUE, "at_target" = FALSE), list("at_target" = TRUE), 4),
		new /datum/cyberpunk_goap_action("work_task", list("work_task" = TRUE, "target_needed" = TRUE, "target_exists" = TRUE, "at_target" = TRUE), list("worked" = TRUE), 1),
		new /datum/cyberpunk_goap_action("work_task", list("work_task" = TRUE, "target_needed" = FALSE), list("worked" = TRUE), 1),
		new /datum/cyberpunk_goap_action("complete_task", list("work_task" = TRUE, "worked" = TRUE), list("complete" = TRUE), 0),
	)
	cyberpunk_goap_extend_traffic_actions(actions)
	return actions

/datum/cyberpunk_goap_planner/proc/goal_satisfied(list/state)
	return state["complete"] || state["failed"]

/datum/cyberpunk_goap_planner/proc/state_signature(list/state)
	var/list/parts = list()
	var/list/keys = list()
	for(var/key in state)
		keys += key
	keys = sort_list(keys)
	for(var/key in keys)
		parts += "[key]=[state[key]]"
	return jointext(parts, ";")

/datum/cyberpunk_goap_planner/proc/queue_action(datum/ai_controller/controller, action_id)
	if(cyberpunk_goap_queue_traffic_action(controller, action_id))
		return
	var/task_state = controller.blackboard[BB_CP_CITY_TASK_STATE]
	switch(action_id)
		if("fail_source_missing")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "source missing")
		if("fail_target_missing")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "target missing")
		if("fail_cargo_missing")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "cargo missing")
		if("fail_cargo_lost")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "cargo lost")
		if("fail_task_timeout")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "task timed out")
		if("route_to_source")
			var/atom/source = controller.blackboard[BB_CP_CARGO_SOURCE]
			var/turf/source_turf = get_turf(source)
			var/turf/source_route_pawn_turf = get_turf(controller.pawn)
			if(QDELETED(source))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "source missing")
			else if(source_turf && source_route_pawn_turf && source_turf.z != source_route_pawn_turf.z && controller.cyberpunk_prepare_z_transition(CP_AI_TASK_ROUTE_TO_SOURCE))
				return SUBTREE_RETURN_FINISH_PLANNING
			else if(get_dist(controller.pawn, source) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, CP_AI_TASK_PICKUP)
			else if(cyberpunk_city_find_climb_obstacle(controller.pawn, source))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_climb_obstacle, BB_CP_CARGO_SOURCE)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_CARGO_SOURCE)

		if("pickup_cargo")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_pickup_cargo)

		if("route_to_target")
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
			else if(cyberpunk_city_find_climb_obstacle(controller.pawn, target))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_climb_obstacle, controller.blackboard[BB_CP_CARGO_RECEIVER] ? BB_CP_CARGO_RECEIVER : BB_CP_ROUTE_TARGET)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, controller.blackboard[BB_CP_CARGO_RECEIVER] ? BB_CP_CARGO_RECEIVER : BB_CP_ROUTE_TARGET)

		if("route_to_z_transition")
			var/atom/transition = controller.blackboard[BB_CP_ROUTE_Z_TRANSITION]
			if(QDELETED(transition))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_fail_task, "z transition missing")
			else if(get_dist(controller.pawn, transition) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_set_task_state, CP_AI_TASK_USE_Z_TRANSITION)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_ROUTE_Z_TRANSITION)

		if("use_z_transition")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_use_z_transition)

		if("dropoff_cargo")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_deliver_cargo)

		if("work_task")
			controller.queue_behavior(/datum/ai_behavior/cyberpunk_work_task)

		if("return_to_point")
			var/atom/return_point = controller.blackboard[BB_CP_ROUTE_RETURN_POINT]
			if(QDELETED(return_point) || get_dist(controller.pawn, return_point) <= 1)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_complete_task, "returned")
			else if(cyberpunk_city_find_climb_obstacle(controller.pawn, return_point))
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_climb_obstacle, BB_CP_ROUTE_RETURN_POINT)
			else
				controller.queue_behavior(/datum/ai_behavior/travel_towards/adjacent, BB_CP_ROUTE_RETURN_POINT)

		if("complete_task")
			if(task_state == CP_AI_TASK_RETURNING)
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_complete_task, "returned")
			else
				controller.queue_behavior(/datum/ai_behavior/cyberpunk_complete_task)

/datum/cyberpunk_goap_action
	var/id
	var/list/preconditions = list()
	var/list/effects = list()
	var/cost = 1

/datum/cyberpunk_goap_action/New(new_id, list/new_preconditions, list/new_effects, new_cost = 1)
	id = new_id
	preconditions = new_preconditions || list()
	effects = new_effects || list()
	cost = max(0, new_cost)

/datum/cyberpunk_goap_action/proc/preconditions_met(list/state)
	for(var/key in preconditions)
		if(!!state[key] != !!preconditions[key])
			return FALSE
	return TRUE

/datum/cyberpunk_goap_action/proc/apply_effects(list/state)
	var/list/new_state = state.Copy()
	for(var/key in effects)
		new_state[key] = effects[key]
	return new_state

/datum/ai_planning_subtree/cyberpunk_security_response

/datum/ai_planning_subtree/cyberpunk_security_response/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller.cyberpunk_has_capability(CP_AI_CAP_COMBAT))
		return
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || living_pawn.stat == DEAD)
		return
	var/atom/threat = controller.blackboard[BB_CP_THREAT_TARGET]
	var/mob/living/checked_threat = threat
	if(QDELETED(threat) || (istype(checked_threat) && checked_threat.stat == DEAD))
		controller.clear_blackboard_key(BB_CP_THREAT_TARGET)
		controller.clear_blackboard_key(BB_CP_THREAT_LEVEL)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.clear_blackboard_key(BB_BASIC_MOB_FLEE_TARGET)
		controller.clear_blackboard_key(BB_TEMPORARILY_IGNORE_FACTION)
		return
	if(living_pawn.maxHealth > 0 && living_pawn.health <= living_pawn.maxHealth * 0.2)
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		controller.set_blackboard_key(BB_BASIC_MOB_FLEE_TARGET, threat)
		return
	controller.clear_blackboard_key(BB_BASIC_MOB_FLEE_TARGET)
	if(living_pawn.maxHealth > 0 && living_pawn.health <= living_pawn.maxHealth * 0.5)
		controller.cyberpunk_call_for_help(threat, "wounded")
	var/mob/living/threat_mob = threat
	if(istype(threat_mob) && HAS_TRAIT(threat_mob, TRAIT_RESTRAINED) && !cyberpunk_is_police_custody_area(threat_mob))
		var/turf/security_turf = cyberpunk_find_security_delivery_turf()
		if(security_turf && !controller.blackboard_key_exists(BB_CP_CITY_TASK))
			controller.cyberpunk_assign_city_task(CP_AI_TASK_GUARD, threat_mob, security_turf, threat_mob, null, 2 MINUTES, security_turf)
			return SUBTREE_RETURN_FINISH_PLANNING
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, threat)
	// City NPCs and their targets usually share the default neutral faction, so without this
	// the basic targeting strategy treats the threat as an ally and the melee attack never fires.
	controller.set_blackboard_key(BB_TEMPORARILY_IGNORE_FACTION, TRUE)
