/*
AI controllers are a datumized form of AI that simulates the input a player would otherwise give to a atom. What this means is that these datums
have ways of interacting with a specific atom and control it. They posses a blackboard with the information the AI knows and has, and will plan behaviors it will try to execute through
multiple modular subtrees with behaviors
*/

/obj/effect/cyberpunk_phantom_body
	name = "suspended NPC context"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE

/obj/effect/cyberpunk_phantom_body/Destroy()
	// The controller owns the body, not this disposable location context.
	for(var/atom/movable/occupant as anything in contents)
		occupant.forceMove(get_turf(src))
	return ..()

/datum/ai_controller
	///The atom this controller is controlling
	var/atom/pawn
	/**
	 * This is a list of variables the AI uses and can be mutated by actions.
	 *
	 * When an action is performed you pass this list and any relevant keys for the variables it can mutate.
	 *
	 * DO NOT set values in the blackboard directly, and especially not if you're adding a datum reference to this!
	 * Use the setters, this is important for reference handing.
	 */
	var/list/blackboard = list()

	///Bitfield of traits for this AI to handle extra behavior
	var/ai_traits = DEFAULT_AI_FLAGS
	///Current actions planned to be performed by the AI in the upcoming plan
	var/list/planned_behaviors = list()
	///Current actions being performed by the AI.
	var/list/current_behaviors = list()
	///Current actions and their respective last time ran as an assoc list.
	var/list/behavior_cooldowns = list()
	///Current status of AI (OFF/ON)
	var/ai_status
	///Current movement target of the AI, generally set by decision making.
	var/atom/current_movement_target
	///Identifier for what last touched our movement target, so it can be cleared conditionally
	var/movement_target_source
	///Stored arguments for behaviors given during their initial creation
	var/list/behavior_args = list()
	///Tracks recent pathing attempts, if we fail too many in a row we fail our current plans.
	var/consecutive_pathing_attempts
	///Can the AI remain in control if there is a client?
	var/continue_processing_when_client = FALSE
	///distance to give up on target
	var/max_target_distance = 14
	///All subtrees this AI has available, will run them in order, so make sure they're in the order you want them to run. On initialization of this type, it will start as a typepath(s) and get converted to references of ai_subtrees found in SSai_controllers when init_subtrees() is called
	var/list/planning_subtrees

	///The idle behavior this AI performs when it has no actions.
	var/datum/idle_behavior/idle_behavior = null
	///our current cell grid
	var/datum/cell_tracker/our_cells

	// Movement related things here
	///Reference to the movement datum we use. Is a type on initialize but becomes a ref afterwards.
	var/datum/ai_movement/ai_movement = /datum/ai_movement/dumb
	///Delay between movements. This is on the controller so we can keep the movement datum singleton
	var/movement_delay = 0.1 SECONDS

	// The variables below are fucking stupid and should be put into the blackboard at some point.
	///AI paused time
	var/paused_until = 0
	///Can this AI idle?
	var/can_idle = TRUE
	///What distance should we be checking for interesting things when considering idling/deidling? Defaults to AI_DEFAULT_INTERESTING_DIST
	var/interesting_dist = AI_DEFAULT_INTERESTING_DIST
	/// TRUE if we're able to run, FALSE if we aren't
	/// Should not be set manually, override get_able_to_run() instead
	/// Make sure you hook update_able_to_run() in setup_able_to_run() to whatever parameters changing that you added
	/// Otherwise we will not pay attention to them changing
	var/able_to_run = FALSE
	/// are we even able to plan?
	var/able_to_plan = TRUE
	/// Invisible location context for a suspended city NPC; never owns/deletes its contents.
	var/obj/effect/cyberpunk_phantom_body/phantom_body
	var/phantom_medical_at = 0
	var/phantom_bleed_rate
	var/phantom_breath_seconds = 0
	var/processing_phantom_medicine = FALSE
	var/phantom_route_generation = 0
	/// are we currently on failed planning timeout?
	var/on_failed_planning_timeout = FALSE


/datum/ai_controller/New(atom/new_pawn)
	change_ai_movement_type(ai_movement)
	init_subtrees()

	if(idle_behavior)
		idle_behavior = SSidle_ai_behaviors.idle_behaviors[idle_behavior]

	if(!isnull(new_pawn)) // unit tests need the ai_controller to exist in isolation due to list schenanigans i hate it here
		PossessPawn(new_pawn)

/datum/ai_controller/Destroy(force)
	UnpossessPawn(FALSE)
	if(ai_status)
		GLOB.ai_controllers_by_status[ai_status] -= src
		for(var/datum/controller/subsystem/ai_controllers/controller_subsystem in Master.subsystems)
			if(controller_subsystem.planning_status == ai_status)
				controller_subsystem.currentrun -= src
				break
	our_cells = null
	set_movement_target(type, null)
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)
	return ..()

///Sets the current movement target, with an optional param to override the movement behavior
/datum/ai_controller/proc/set_movement_target(source, atom/target, datum/ai_movement/new_movement)
	if(current_movement_target)
		UnregisterSignal(current_movement_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PREQDELETED))
	if(!isnull(target) && !isatom(target))
		stack_trace("[pawn]'s current movement target is not an atom, rather a [target.type]! Did you accidentally set it to a weakref?")
		CancelActions()
		return
	movement_target_source = source
	current_movement_target = target
	if(!isnull(current_movement_target))
		RegisterSignal(current_movement_target, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement_target_move))
		RegisterSignal(current_movement_target, COMSIG_PREQDELETED, PROC_REF(on_movement_target_delete))
	if(new_movement)
		change_ai_movement_type(new_movement)

///Overrides the current ai_movement of this controller with a new one
/datum/ai_controller/proc/change_ai_movement_type(datum/ai_movement/new_movement)
	ai_movement = SSai_movement.movement_types[new_movement]

///Completely replaces the planning_subtrees with a new set based on argument provided, list provided must contain specifically typepaths
/datum/ai_controller/proc/replace_planning_subtrees(list/typepaths_of_new_subtrees)
	planning_subtrees = typepaths_of_new_subtrees
	init_subtrees()

///Loops over the subtrees in planning_subtrees and looks at the ai_controllers to grab a reference, ENSURE planning_subtrees ARE TYPEPATHS AND NOT INSTANCES/REFERENCES BEFORE EXECUTING THIS
/datum/ai_controller/proc/init_subtrees()
	if(!LAZYLEN(planning_subtrees))
		return
	var/list/temp_subtree_list = list()
	for(var/subtree in planning_subtrees)
		var/subtree_instance = GLOB.ai_subtrees[subtree]
		temp_subtree_list += subtree_instance
	planning_subtrees = temp_subtree_list

///Proc to move from one pawn to another, this will destroy the target's existing controller.
/datum/ai_controller/proc/PossessPawn(atom/new_pawn)
	SHOULD_CALL_PARENT(TRUE)
	if(pawn) //Reset any old signals
		UnpossessPawn(FALSE)

	if(istype(new_pawn.ai_controller)) //Existing AI, kill it.
		QDEL_NULL(new_pawn.ai_controller)

	if(TryPossessPawn(new_pawn) & AI_CONTROLLER_INCOMPATIBLE)
		qdel(src)
		CRASH("[src] attached to [new_pawn] but these are not compatible!")

	pawn = new_pawn
	pawn.ai_controller = src

	var/turf/pawn_turf = get_turf(pawn)
	if(pawn_turf)
		GLOB.ai_controllers_by_zlevel[pawn_turf.z] += src

	SEND_SIGNAL(src, COMSIG_AI_CONTROLLER_POSSESSED_PAWN)

	reset_ai_status()
	RegisterSignal(pawn, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_changed_z_level))
	RegisterSignal(pawn, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_changed))
	RegisterSignal(pawn, COMSIG_MOB_LOGIN, PROC_REF(on_sentience_gained))
	RegisterSignal(pawn, COMSIG_QDELETING, PROC_REF(on_pawn_qdeleted))
	RegisterSignal(pawn, COMSIG_EVLOGGING_ENABLED, PROC_REF(on_pawn_evlogging_enabled))
	RegisterSignal(pawn, COMSIG_EVLOGGING_DISABLED, PROC_REF(on_pawn_evlogging_disabled))
	update_able_to_run()
	setup_able_to_run()

	our_cells = new(interesting_dist, interesting_dist, 1)
	set_new_cells()

	RegisterSignal(pawn, COMSIG_MOVABLE_MOVED, PROC_REF(update_grid))

/datum/ai_controller/proc/update_grid(datum/source, datum/spatial_grid_cell/new_cell)
	SIGNAL_HANDLER

	set_new_cells()
	if(current_movement_target)
		check_target_max_distance()

/datum/ai_controller/proc/on_movement_target_move(atom/source)
	SIGNAL_HANDLER
	check_target_max_distance()

/datum/ai_controller/proc/on_movement_target_delete(atom/source)
	SIGNAL_HANDLER
	set_movement_target(source = type, target = null)

/datum/ai_controller/proc/check_target_max_distance()
	if(get_dist(current_movement_target, pawn) > max_target_distance)
		CancelActions()

/datum/ai_controller/proc/set_new_cells()
	if(isnull(our_cells))
		return

	var/turf/our_turf = get_turf(pawn)
	if(phantom_body)
		our_turf = blackboard[BB_CP_PHANTOM_APPROX_TURF]

	if(isnull(our_turf))
		return

	var/list/cell_collections = our_cells.recalculate_cells(our_turf)

	for(var/datum/old_grid as anything in cell_collections[2])
		UnregisterSignal(old_grid, list(SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)))

	for(var/datum/spatial_grid_cell/new_grid as anything in cell_collections[1])
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_enter))
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_exit))

	recalculate_idle()

/datum/ai_controller/proc/should_idle()
	if(!can_idle || isnull(our_cells))
		return FALSE
	for(var/datum/spatial_grid_cell/grid as anything in our_cells.member_cells)
		if(locate(/mob/living) in grid.client_contents)
			return FALSE
	return TRUE

/// Configures the Cyberpunk city AI profile on top of the normal tg AI controller.
/datum/ai_controller/proc/cyberpunk_setup_profile(role_profile = CP_AI_ROLE_CIVILIAN, capabilities = CP_AI_CAP_HANDS, ai_level = 1, faction, phantom_profile = CP_AI_PHANTOM_PROFILE_LIGHT)
	set_blackboard_key(BB_CP_AI_ROLE_PROFILE, role_profile)
	set_blackboard_key(BB_CP_AI_CAPABILITIES, capabilities)
	set_blackboard_key(BB_CP_AI_LEVEL, max(1, ai_level))
	if(!isnull(faction))
		set_blackboard_key(BB_CP_AI_FACTION, faction)
	set_blackboard_key(BB_CP_PHANTOM_ENABLED, TRUE)
	set_blackboard_key(BB_CP_PHANTOM_PROFILE, phantom_profile)
	if(!blackboard_key_exists(BB_CP_PHANTOM_STATE))
		set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_INACTIVE)
	cyberpunk_ensure_phantom_idle_behavior()

/// Gives profiled Cyberpunk NPCs an idle processor even when their normal controller did not define one.
/datum/ai_controller/proc/cyberpunk_ensure_phantom_idle_behavior()
	if(!blackboard[BB_CP_PHANTOM_ENABLED] || idle_behavior)
		return
	idle_behavior = SSidle_ai_behaviors?.idle_behaviors[/datum/idle_behavior/cyberpunk_phantom]

/// Returns TRUE when this controller profile allows a specific city action.
/datum/ai_controller/proc/cyberpunk_has_capability(capability)
	return !!(blackboard[BB_CP_AI_CAPABILITIES] & capability)

/datum/ai_controller/proc/cyberpunk_is_delivery_task(task_type)
	return task_type in list(CP_AI_TASK_DELIVERY, CP_AI_TASK_CONTRACT, CP_AI_TASK_CARGO, CP_AI_TASK_GUARD)

/datum/ai_controller/proc/cyberpunk_cargo_type_text(atom/cargo)
	if(!cargo)
		return null
	return "[cargo.type]"

/datum/ai_controller/proc/cyberpunk_cargo_amount(atom/cargo)
	if(!cargo)
		return 0
	return 1

/datum/ai_controller/proc/cyberpunk_task_success_condition(task_type)
	if(cyberpunk_is_delivery_task(task_type))
		return "cargo delivered to receiver"
	if(task_type == CP_AI_TASK_REPAIR)
		return "target repaired"
	if(task_type == CP_AI_TASK_PATROL)
		return "route completed"
	if(task_type == CP_AI_TASK_EMERGENCY_RESPONSE)
		return "emergency response completed"
	if(task_type == CP_AI_TASK_FLEE)
		return "threat escaped"
	return "task timer completed"

/datum/ai_controller/proc/cyberpunk_task_failure_condition(task_type)
	if(cyberpunk_is_delivery_task(task_type))
		return "cargo, source, receiver, route, or carrier lost"
	if(task_type == CP_AI_TASK_REPAIR)
		return "repair target missing or unreachable"
	if(task_type == CP_AI_TASK_PATROL)
		return "patrol route unavailable"
	if(task_type == CP_AI_TASK_EMERGENCY_RESPONSE)
		return "emergency target missing or route unavailable"
	if(task_type == CP_AI_TASK_FLEE)
		return "escape route unavailable"
	return "target missing, route unavailable, or task timed out"

/datum/ai_controller/proc/cyberpunk_role_task_weight(task_type)
	var/role = blackboard[BB_CP_AI_ROLE_PROFILE]
	switch(role)
		if(CP_AI_ROLE_WORKER)
			if(task_type in list(CP_AI_TASK_WORK, CP_AI_TASK_REPAIR, CP_AI_TASK_CARGO, CP_AI_TASK_DELIVERY))
				return 20
		if(CP_AI_ROLE_CONTRACTOR)
			if(task_type in list(CP_AI_TASK_CONTRACT, CP_AI_TASK_DELIVERY, CP_AI_TASK_CARGO))
				return 25
		if(CP_AI_ROLE_POLICE, CP_AI_ROLE_CORP_SECURITY)
			if(task_type in list(CP_AI_TASK_GUARD, CP_AI_TASK_PATROL, CP_AI_TASK_FLEE, CP_AI_TASK_EMERGENCY_RESPONSE))
				return 20
		if(CP_AI_ROLE_CORPORATE, CP_AI_ROLE_SERVICE)
			if(task_type in list(CP_AI_TASK_WORK, CP_AI_TASK_DELIVERY))
				return 10
		if(CP_AI_ROLE_BANDIT, CP_AI_ROLE_ANTAG)
			if(task_type in list(CP_AI_TASK_GUARD, CP_AI_TASK_FLEE))
				return 10
	return 0

/// Assigns a compact city task through the blackboard. Use subtrees/behaviors to execute it.
/datum/ai_controller/proc/cyberpunk_assign_city_task(task_type, atom/source, atom/target, atom/cargo, contract_id, duration = 30 SECONDS, atom/return_point)
	cyberpunk_clear_city_task()
	clear_blackboard_key(BB_CP_CITY_TASK_RESULT)
	clear_blackboard_key(BB_CP_CITY_TASK_FAILURE_REASON)
	if(!source && cargo && cyberpunk_is_delivery_task(task_type))
		source = cargo
	set_blackboard_key(BB_CP_CITY_TASK, task_type)
	set_blackboard_key(BB_CP_CITY_TASK_STATE, source ? CP_AI_TASK_ROUTE_TO_SOURCE : (target ? CP_AI_TASK_ROUTE_TO_TARGET : CP_AI_TASK_WORKING))
	set_blackboard_key(BB_CP_CITY_TASK_FINISH_AT, world.time + duration)
	set_blackboard_key(BB_CP_CITY_TASK_DURATION, duration)
	set_blackboard_key(BB_CP_CITY_TASK_SUCCESS_CONDITION, cyberpunk_task_success_condition(task_type))
	set_blackboard_key(BB_CP_CITY_TASK_FAILURE_CONDITION, cyberpunk_task_failure_condition(task_type))
	set_blackboard_key(BB_CP_CITY_TASK_EXPECTED_RESULT, cyberpunk_task_success_condition(task_type))
	if(source)
		set_blackboard_key(BB_CP_CARGO_SOURCE, source)
		set_blackboard_key(BB_CP_ROUTE_SOURCE, source)
	if(target)
		set_blackboard_key(BB_CP_CARGO_RECEIVER, target)
		set_blackboard_key(BB_CP_ROUTE_TARGET, target)
	if(cargo)
		set_blackboard_key(BB_CP_CARGO, cargo)
		set_blackboard_key(BB_CP_CARGO_TYPE, cyberpunk_cargo_type_text(cargo))
		set_blackboard_key(BB_CP_CARGO_AMOUNT, cyberpunk_cargo_amount(cargo))
		set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_WAITING)
	if(contract_id)
		set_blackboard_key(BB_CP_CONTRACT_ID, contract_id)
		var/datum/cyberpunk_contract/contract = SSeconomy?.get_cyberpunk_contract(contract_id)
		if(contract)
			set_blackboard_key(BB_CP_CONTRACT_REF, contract)
	if(return_point)
		set_blackboard_key(BB_CP_ROUTE_RETURN_POINT, return_point)
	var/turf/current_turf = get_turf(pawn)
	var/turf/target_turf = get_turf(target)
	if(current_turf)
		set_blackboard_key(BB_CP_ROUTE_CURRENT_Z, current_turf.z)
	if(target_turf)
		set_blackboard_key(BB_CP_ROUTE_TARGET_Z, target_turf.z)
	set_blackboard_key(BB_CP_ROUTE_Z_METHOD, CP_AI_ROUTE_Z_METHOD_NONE)
	reset_ai_status()

/// Clears volatile task/route state while preserving last result/debug fields.
/datum/ai_controller/proc/cyberpunk_clear_city_task()
	phantom_route_generation++
	cyberpunk_materialize_phantom("task finished")
	var/static/list/city_task_blackboard_keys = list(
		BB_CP_CITY_TASK,
		BB_CP_CITY_TASK_STATE,
		BB_CP_CITY_TASK_FINISH_AT,
		BB_CP_CITY_WORK_STARTED,
		BB_CP_CITY_TASK_DURATION,
		BB_CP_CITY_TASK_SUCCESS_CONDITION,
		BB_CP_CITY_TASK_FAILURE_CONDITION,
		BB_CP_CITY_TASK_EXPECTED_RESULT,
		BB_CP_CONTRACT_ID,
		BB_CP_CONTRACT_REF,
		BB_CP_CARGO,
		BB_CP_CARGO_TYPE,
		BB_CP_CARGO_AMOUNT,
		BB_CP_CARGO_SOURCE,
		BB_CP_CARGO_RECEIVER,
		BB_CP_CARGO_STATUS,
		BB_CP_ROUTE_SOURCE,
		BB_CP_ROUTE_TARGET,
		BB_CP_ROUTE_RETURN_POINT,
		BB_CP_ROUTE_PHASE,
		BB_CP_ROUTE_TARGET_Z,
		BB_CP_ROUTE_Z_TRANSITION,
		BB_CP_ROUTE_Z_EDGE,
		BB_CP_ROUTE_Z_REJECTED,
		BB_CP_ROUTE_Z_METHOD,
		BB_CP_ROUTE_VISIBLE,
		BB_CP_ROUTE_OBSERVATION_PROXY,
		BB_CP_GOAP_PLAN,
		BB_CP_GOAP_CURRENT_ACTION,
		BB_CP_GOAP_PLAN_SIGNATURE,
		BB_CP_PHANTOM_FINISH_AT,
		BB_CP_PHANTOM_PATH,
		BB_CP_PHANTOM_PATH_PENDING,
		BB_CP_PHANTOM_Z_EDGE,
		BB_CP_PHANTOM_Z_REJECTED,
		BB_CP_PHANTOM_NEXT_TICK,
		BB_CP_PHANTOM_ACCUMULATED_SECONDS,
		BB_CP_PHANTOM_RISK_RESULT,
	)
	for(var/blackboard_key as anything in city_task_blackboard_keys)
		clear_blackboard_key(blackboard_key)
	set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_INACTIVE)

/// Marks the current city task as complete.
/datum/ai_controller/proc/cyberpunk_complete_city_task(result = "completed")
	cyberpunk_record_contract_task_result(TRUE, result)
	set_blackboard_key(BB_CP_CITY_TASK_RESULT, result)
	cyberpunk_clear_city_task()
	reset_ai_status()

/// Marks the current city task as failed.
/datum/ai_controller/proc/cyberpunk_fail_city_task(reason = "failed")
	cyberpunk_record_contract_task_result(FALSE, reason)
	set_blackboard_key(BB_CP_CITY_TASK_FAILURE_REASON, reason)
	cyberpunk_clear_city_task()
	reset_ai_status()

/datum/ai_controller/proc/cyberpunk_record_contract_task_result(succeeded, reason)
	var/datum/cyberpunk_contract/contract = blackboard[BB_CP_CONTRACT_REF]
	if(!contract && blackboard[BB_CP_CONTRACT_ID])
		contract = SSeconomy?.get_cyberpunk_contract(blackboard[BB_CP_CONTRACT_ID])
	if(!contract)
		return FALSE
	var/mob/living/living_pawn = pawn
	if(succeeded)
		if(istype(living_pawn))
			contract.check_nearby_target(living_pawn)
		return contract.complete("AI task: [reason]")
	return contract.fail("AI task: [reason]")

/// TRUE when the controller should keep logical city-task processing while physically idle.
/datum/ai_controller/proc/cyberpunk_should_process_phantom(check_chemistry = TRUE)
	if(!blackboard[BB_CP_PHANTOM_ENABLED])
		return FALSE
	if(!cyberpunk_can_suspend_body(check_chemistry))
		return FALSE
	cyberpunk_ensure_phantom_idle_behavior()
	if(!blackboard_key_exists(BB_CP_CITY_TASK))
		return FALSE
	var/mob/living/living_pawn = pawn
	var/waiting_for_recovery = phantom_body && istype(living_pawn) && living_pawn.stat != CONSCIOUS
	if((!able_to_run || on_failed_planning_timeout) && !waiting_for_recovery)
		return FALSE
	if(cyberpunk_is_observable())
		set_blackboard_key(BB_CP_ROUTE_VISIBLE, TRUE)
		return FALSE
	if(blackboard[BB_CP_ROUTE_VISIBLE])
		clear_blackboard_key(BB_CP_ROUTE_VISIBLE)
	return blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE || should_idle()

/// Only opt-in carbon/basic NPCs may suspend; players and interactive bodies never do.
/datum/ai_controller/proc/cyberpunk_can_suspend_body(check_chemistry = TRUE)
	var/mob/living/living_pawn = pawn
	if(!istype(living_pawn) || living_pawn.client || living_pawn.ckey || living_pawn.mind?.key)
		return FALSE
	if(living_pawn.stat == DEAD || (living_pawn.stat != CONSCIOUS && !phantom_body) || living_pawn.pulledby || living_pawn.buckled || length(living_pawn.do_afters))
		return FALSE
	if(living_pawn.is_exhausted_by_needs() || HAS_TRAIT(living_pawn, TRAIT_STASIS) || HAS_TRAIT(living_pawn, TRAIT_NO_TRANSFORM))
		return FALSE
	if(isliving(blackboard[BB_CP_CARGO]))
		return FALSE
	if(phantom_body && (!get_turf(phantom_body) || !blackboard[BB_CP_PHANTOM_APPROX_TURF]))
		return FALSE
	if(!iscarbon(living_pawn) && !isbasicmob(living_pawn))
		return FALSE
	return !check_chemistry || cyberpunk_can_compact_chemistry(living_pawn)

/// Digestion, blends and reagents with behavioral effects need a physical NPC.
/datum/ai_controller/proc/cyberpunk_can_compact_chemistry(mob/living/living_pawn)
	var/mob/living/carbon/carbon_pawn = living_pawn
	if(!istype(carbon_pawn))
		return !living_pawn.reagents?.total_volume

	var/obj/item/organ/stomach/stomach = carbon_pawn.get_organ_slot(ORGAN_SLOT_STOMACH)
	if(stomach?.reagents?.total_volume)
		if(stomach.reagents.is_reacting || (stomach.organ_flags & ORGAN_FAILING))
			return FALSE
		for(var/datum/reagent/stomach_chem as anything in stomach.reagents.reagent_list)
			if(stomach_chem.metabolization_rate > 0 && stomach_chem.volume > LAZYACCESS(stomach.food_reagents, stomach_chem.type))
				return FALSE

	var/datum/reagents/bloodstream = carbon_pawn.reagents
	if(!bloodstream?.total_volume)
		return TRUE
	if(bloodstream.is_reacting || length(bloodstream.reagent_list) != 1)
		return FALSE

	var/datum/reagent/medicine = bloodstream.reagent_list[1]
	if(medicine.type != /datum/reagent/medicine/omnizine && medicine.type != /datum/reagent/medicine/omnizine/protozine)
		return FALSE
	if(medicine.overdosed || medicine.overdosed_crit || (medicine.overdose_threshold && medicine.volume >= medicine.overdose_threshold))
		return FALSE
	if(medicine.overdose_crit_threshold && medicine.volume >= medicine.overdose_crit_threshold)
		return FALSE

	var/obj/item/organ/liver/liver = carbon_pawn.get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver?.type != /obj/item/organ/liver || (liver.organ_flags & ORGAN_FAILING) || (liver.organ_condition_flags & ORGAN_CONDITION_CIRRHOSIS))
		return FALSE
	return !HAS_TRAIT(carbon_pawn, TRAIT_LIVERLESS_METABOLISM)

/// Hidden NPCs do not need full AI cadence. Light profiles are cheaper; heavy profiles still advance more often.
/datum/ai_controller/proc/cyberpunk_phantom_tick_interval()
	return blackboard[BB_CP_PHANTOM_PROFILE] == CP_AI_PHANTOM_PROFILE_HEAVY ? 5 SECONDS : 15 SECONDS

/datum/ai_controller/proc/cyberpunk_phantom_failure_chance()
	var/ai_level = max(1, blackboard[BB_CP_AI_LEVEL] || 1)
	var/base_chance = blackboard[BB_CP_PHANTOM_PROFILE] == CP_AI_PHANTOM_PROFILE_HEAVY ? 8 : 15
	return max(0, base_chance - (ai_level * 3))

/datum/ai_controller/proc/cyberpunk_set_observation_proxy(reason)
	set_blackboard_key(BB_CP_ROUTE_OBSERVATION_PROXY, reason || "observable")
	set_blackboard_key(BB_CP_ROUTE_VISIBLE, TRUE)

/// Returns TRUE if players, cameras, or direct cross-Z exposure can observe this pawn/phantom route.
/datum/ai_controller/proc/cyberpunk_is_observable()
	var/list/turfs_to_check = cyberpunk_observation_turfs()
	for(var/turf/checking_turf as anything in turfs_to_check)
		if(!checking_turf)
			continue
		for(var/mob/living/viewer as anything in SSmobs.clients_by_zlevel[checking_turf.z])
			if(viewer.client && get_dist(viewer, checking_turf) <= interesting_dist && (can_see(viewer, checking_turf, interesting_dist) || get_dist(viewer, checking_turf) <= 7))
				cyberpunk_set_observation_proxy(viewer.z == checking_turf.z ? "client line of sight" : "client cross-z line of sight")
				return TRUE
		for(var/mob/dead/observer/viewer as anything in SSmobs.dead_players_by_zlevel[checking_turf.z])
			if(viewer.client && get_dist(viewer, checking_turf) <= interesting_dist)
				cyberpunk_set_observation_proxy("observer")
				return TRUE
		if(SScameras?.is_visible_by_cameras(checking_turf))
			cyberpunk_set_observation_proxy("camera observation")
			return TRUE
		if(SEND_SIGNAL(checking_turf, COMSIG_TURF_AI_OBSERVABLE, pawn))
			cyberpunk_set_observation_proxy("proximity sensor or field")
			return TRUE
	return FALSE

/// Turfs that can reveal a profiled city AI. Includes same XY adjacent Z for open shafts/bridges.
/datum/ai_controller/proc/cyberpunk_observation_turfs()
	var/list/turfs_to_check = list()
	var/turf/current_turf = get_turf(pawn)
	if(phantom_body || !current_turf)
		current_turf = blackboard[BB_CP_PHANTOM_APPROX_TURF]
	if(current_turf)
		turfs_to_check += current_turf
		var/turf/above = get_step_multiz(current_turf, UP)
		var/turf/below = get_step_multiz(current_turf, DOWN)
		if(above)
			turfs_to_check += above
		if(below)
			turfs_to_check += below
	var/atom/route_target = blackboard[BB_CP_ROUTE_TARGET]
	var/turf/target_turf = get_turf(route_target)
	if(target_turf)
		turfs_to_check |= target_turf
	for(var/route_key in list(BB_CP_CARGO_SOURCE, BB_CP_CARGO_RECEIVER, BB_CP_ROUTE_RETURN_POINT, BB_CP_ROUTE_Z_TRANSITION))
		var/atom/route_atom = blackboard[route_key]
		var/turf/route_turf = get_turf(route_atom)
		if(route_turf)
			turfs_to_check |= route_turf
			var/turf/route_above = get_step_multiz(route_turf, UP)
			var/turf/route_below = get_step_multiz(route_turf, DOWN)
			if(route_above)
				turfs_to_check |= route_above
			if(route_below)
				turfs_to_check |= route_below
	return turfs_to_check

/// Finds a nearby vertical transition that can move toward target_z.
/datum/ai_controller/proc/cyberpunk_find_z_transition(target_z)
	var/turf/current_turf = get_turf(pawn)
	if(!current_turf || !target_z || current_turf.z == target_z)
		return null

	var/atom/best_transition
	var/best_distance = INFINITY
	for(var/obj/structure/ladder/ladder as anything in GLOB.ladders)
		if(ladder.z != current_turf.z)
			continue
		if(target_z > current_turf.z && !ladder.up)
			continue
		if(target_z < current_turf.z && !ladder.down)
			continue
		var/distance = get_dist(current_turf, ladder)
		if(distance < best_distance)
			best_distance = distance
			best_transition = ladder

	for(var/obj/structure/stairs/stair as anything in GLOB.stairs)
		if(stair.z != current_turf.z)
			continue
		var/turf/up_target = get_step_multiz(stair, UP)
		var/turf/down_target = get_step_multiz(stair, DOWN)
		if(target_z > current_turf.z && !up_target)
			continue
		if(target_z < current_turf.z && !down_target)
			continue
		var/distance = get_dist(current_turf, stair)
		if(distance < best_distance)
			best_distance = distance
			best_transition = stair
	return best_transition

/// Sets the route state to a usable vertical transition if the target is on another Z.
/datum/ai_controller/proc/cyberpunk_prepare_z_transition(next_state)
	var/turf/current_turf = get_turf(pawn)
	var/atom/route_target
	if(next_state == CP_AI_TASK_ROUTE_TO_SOURCE)
		route_target = blackboard[BB_CP_CARGO_SOURCE]
	else if(next_state == CP_AI_TASK_RETURNING)
		route_target = blackboard[BB_CP_ROUTE_RETURN_POINT]
	else
		route_target = blackboard[BB_CP_CARGO_RECEIVER]
	if(!route_target)
		route_target = blackboard[BB_CP_ROUTE_TARGET]
	var/turf/target_turf = get_turf(route_target)
	if(!current_turf || !target_turf || current_turf.z == target_turf.z)
		return FALSE
	var/list/edge = cyberpunk_service_z_next_edge(current_turf, target_turf, cyberpunk_city_z_edges(current_turf, target_turf), blackboard[BB_CP_ROUTE_Z_REJECTED])
	if(!edge)
		cyberpunk_fail_city_task("no z transition")
		return TRUE
	var/atom/transition = edge["link"]
	if(istype(transition, /obj/structure/ladder))
		set_blackboard_key(BB_CP_ROUTE_Z_METHOD, CP_AI_ROUTE_Z_METHOD_LADDER)
	else if(istype(transition, /obj/structure/stairs))
		set_blackboard_key(BB_CP_ROUTE_Z_METHOD, CP_AI_ROUTE_Z_METHOD_STAIRS)
	else
		set_blackboard_key(BB_CP_ROUTE_Z_METHOD, CP_AI_ROUTE_Z_METHOD_FLY)
	override_blackboard_key(BB_CP_ROUTE_Z_EDGE, edge)
	set_blackboard_key(BB_CP_ROUTE_Z_TRANSITION, edge["entry"])
	set_blackboard_key(BB_CP_ROUTE_TARGET_Z, target_turf.z)
	set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_Z_TRANSITION)
	set_blackboard_key(BB_CP_ROUTE_PHASE, next_state)
	return TRUE

/datum/ai_controller/proc/cyberpunk_city_z_edges(turf/start, turf/target)
	var/list/edges = list()
	for(var/list/edge as anything in cyberpunk_service_z_edges())
		if(istype(edge["link"], /obj/structure/ladder) && !(cyberpunk_has_capability(CP_AI_CAP_HANDS) || cyberpunk_has_capability(CP_AI_CAP_CLIMB)))
			continue
		edges += list(edge)
	var/atom/movable/traveler = pawn
	if(cyberpunk_has_capability(CP_AI_CAP_FLY))
		cyberpunk_service_flight_edges(traveler, start, edges)
		cyberpunk_service_flight_edges(traveler, target, edges)
	return edges

/datum/ai_controller/proc/cyberpunk_city_turf()
	return phantom_body ? blackboard[BB_CP_PHANTOM_APPROX_TURF] : get_turf(pawn)

/datum/ai_controller/proc/cyberpunk_city_adjacent(atom/target)
	var/turf/start = cyberpunk_city_turf()
	var/turf/destination = get_turf(target)
	return start && destination && start.z == destination.z && get_dist(start, destination) <= 1

/datum/ai_controller/proc/cyberpunk_has_city_cargo()
	var/mob/living/carrier = pawn
	var/atom/cargo = blackboard[BB_CP_CARGO]
	if(!istype(carrier) || !cargo || QDELETED(cargo))
		return FALSE
	if(isitem(cargo))
		return carrier.is_holding(cargo) || (cargo.loc == carrier && (phantom_body || cyberpunk_has_capability(CP_AI_CAP_CARGO_SLOT)))
	return isliving(cargo) && carrier.pulling == cargo && cyberpunk_city_adjacent(cargo)

/datum/ai_controller/proc/cyberpunk_pickup_city_cargo()
	if(cyberpunk_has_city_cargo())
		return TRUE
	var/mob/living/carrier = pawn
	var/atom/cargo = blackboard[BB_CP_CARGO]
	if(!istype(carrier) || !cargo || QDELETED(cargo) || !cyberpunk_city_adjacent(cargo))
		return FALSE
	if(phantom_body)
		phantom_body.forceMove(cyberpunk_city_turf())
	var/obj/item/item = cargo
	if(istype(item))
		if(item.anchored || ismob(item.loc) || (phantom_body && !isturf(item.loc)) || !item.IsReachableBy(phantom_body || carrier))
			return FALSE
		if(phantom_body || (!cyberpunk_has_capability(CP_AI_CAP_HANDS) && cyberpunk_has_capability(CP_AI_CAP_CARGO_SLOT)))
			if(!cyberpunk_has_capability(CP_AI_CAP_HANDS) && !cyberpunk_has_capability(CP_AI_CAP_CARGO_SLOT))
				return FALSE
			item.forceMove(carrier)
			return item.loc == carrier
		if(!cyberpunk_has_capability(CP_AI_CAP_HANDS))
			return FALSE
		if(carrier.get_active_held_item())
			carrier.dropItemToGround(carrier.get_active_held_item())
		return carrier.put_in_hands(item)
	if(isliving(cargo) && !phantom_body && cyberpunk_has_capability(CP_AI_CAP_HANDS))
		carrier.start_pulling(cargo, supress_message = TRUE)
		return carrier.pulling == cargo
	return FALSE

/// Inventory handoff is local. A lost cargo reference never authorizes moving the item.
/datum/ai_controller/proc/cyberpunk_deliver_city_cargo()
	var/atom/receiver = blackboard[BB_CP_CARGO_RECEIVER] || blackboard[BB_CP_ROUTE_TARGET]
	if(!cyberpunk_has_city_cargo() || !cyberpunk_city_adjacent(receiver))
		return FALSE
	var/mob/living/carrier = pawn
	var/atom/cargo = blackboard[BB_CP_CARGO]
	if(phantom_body)
		phantom_body.forceMove(cyberpunk_city_turf())
	if(!receiver.IsReachableBy(phantom_body || carrier))
		return FALSE
	var/obj/item/item = cargo
	if(istype(item))
		if(carrier.is_holding(item))
			if(!carrier.dropItemToGround(item))
				return FALSE
		else
			item.forceMove(get_turf(carrier))
		var/mob/living/recipient = receiver
		if(istype(recipient) && recipient.put_in_hands(item))
			return TRUE
		var/turf/destination = get_turf(receiver)
		return get_turf(item) == destination || item.Move(destination, get_dir(item, destination))
	if(isliving(cargo))
		carrier.stop_pulling()
		return cyberpunk_city_adjacent(cargo)
	return FALSE

/// Starts compact city-task processing.
/datum/ai_controller/proc/cyberpunk_enter_phantom()
	if(!cyberpunk_should_process_phantom())
		return FALSE
	if(blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return TRUE
	set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_WAITING)
	set_blackboard_key(BB_CP_PHANTOM_STARTED_AT, world.time)
	set_blackboard_key(BB_CP_PHANTOM_LAST_TICK, world.time)
	var/turf/current_turf = get_turf(pawn)
	if(current_turf)
		set_blackboard_key(BB_CP_PHANTOM_APPROX_TURF, current_turf)
		set_blackboard_key(BB_CP_ROUTE_CURRENT_Z, current_turf.z)
	var/mob/living/living_pawn = pawn
	if(istype(living_pawn))
		set_blackboard_key(BB_CP_PHANTOM_HEALTH_VALUE, round(living_pawn.health))
		set_blackboard_key(BB_CP_PHANTOM_HEALTH_STATE, living_pawn.stat == DEAD ? "dead" : "[round(living_pawn.health)]/[living_pawn.maxHealth]")
		CancelActions()
		able_to_plan = FALSE
		phantom_medical_at = world.time
		phantom_bleed_rate = living_pawn.get_bleed_rate()
		phantom_breath_seconds = 0
		phantom_body = new(current_turf)
		living_pawn.forceMove(phantom_body)
	set_blackboard_key(BB_CP_PHANTOM_NEXT_TICK, world.time + cyberpunk_phantom_tick_interval())
	set_blackboard_key(BB_CP_PHANTOM_ACCUMULATED_SECONDS, 0)
	return TRUE

/// Ends compact processing because the pawn became observable or the task needs physical actions.
/datum/ai_controller/proc/cyberpunk_materialize_phantom(reason = "observable")
	if(!blackboard[BB_CP_PHANTOM_STATE] || blackboard[BB_CP_PHANTOM_STATE] == CP_AI_PHANTOM_INACTIVE)
		return FALSE
	phantom_route_generation++
	for(var/key in list(BB_CP_PHANTOM_PATH, BB_CP_PHANTOM_PATH_PENDING, BB_CP_PHANTOM_Z_EDGE, BB_CP_PHANTOM_Z_REJECTED, BB_CP_PHANTOM_FINISH_AT))
		clear_blackboard_key(key)
	var/mob/living/living_pawn = pawn
	var/turf/approx_turf = blackboard[BB_CP_PHANTOM_APPROX_TURF]
	cyberpunk_process_phantom_health(force = TRUE)
	set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_INACTIVE)
	if(istype(living_pawn) && approx_turf && !QDELETED(living_pawn) && (isnull(living_pawn.loc) || living_pawn.loc == phantom_body))
		living_pawn.forceMove(approx_turf)
	QDEL_NULL(phantom_body)
	phantom_bleed_rate = null
	able_to_plan = check_able_to_plan()
	cyberpunk_materialize_phantom_cargo()
	set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_INACTIVE)
	cyberpunk_set_observation_proxy(reason)
	if(reason)
		set_blackboard_key(BB_CP_CITY_TASK_RESULT, "materialized: [reason]")
	return TRUE

/datum/ai_controller/proc/cyberpunk_materialize_phantom_cargo()
	if(blackboard[BB_CP_CARGO_STATUS] != CP_AI_CARGO_CARRIED)
		return FALSE
	var/mob/living/living_pawn = pawn
	if(!istype(living_pawn))
		return FALSE
	var/atom/cargo = blackboard[BB_CP_CARGO]
	if(QDELETED(cargo))
		set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_LOST)
		return FALSE
	var/turf/pawn_turf = get_turf(living_pawn)
	var/obj/item/cargo_item = cargo
	if(istype(cargo_item))
		if(living_pawn.is_holding(cargo_item))
			return TRUE
		if(cargo_item.loc != living_pawn)
			set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_LOST)
			return FALSE
		if(cyberpunk_has_capability(CP_AI_CAP_HANDS))
			// Keep the tracked cargo atom intact and avoid the blocking stack-merge path during teardown.
			var/hand = living_pawn.get_empty_held_index_for_side(LEFT_HANDS) || living_pawn.get_empty_held_index_for_side(RIGHT_HANDS)
			if(hand && living_pawn.put_in_hand(cargo_item, hand))
				SSeconomy.record_cyberpunk_contract_item_in_hands(living_pawn, cargo_item)
				return TRUE
		if(cyberpunk_has_capability(CP_AI_CAP_CARGO_SLOT))
			return TRUE
		if(pawn_turf)
			cargo_item.forceMove(pawn_turf)
		set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_LOST)
		return FALSE
	var/mob/living/cargo_mob = cargo
	if(istype(cargo_mob))
		return living_pawn.pulling == cargo_mob && cyberpunk_city_adjacent(cargo_mob)
	return FALSE

/datum/ai_controller/proc/cyberpunk_process_phantom_health(force = FALSE)
	var/mob/living/living_pawn = pawn
	if(!istype(living_pawn) || QDELETED(living_pawn) || processing_phantom_medicine || living_pawn.client || living_pawn.ckey || living_pawn.mind?.key)
		return FALSE
	var/can_compact_chemistry = cyberpunk_can_compact_chemistry(living_pawn)
	if(!can_compact_chemistry && !force)
		cyberpunk_materialize_phantom("chemistry needs physical processing")
		return FALSE

	var/elapsed_seconds = (world.time - phantom_medical_at) / (1 SECONDS)
	if(elapsed_seconds <= 0 || (!force && elapsed_seconds < 5))
		return TRUE

	processing_phantom_medicine = TRUE
	var/turf/virtual_turf = blackboard[BB_CP_PHANTOM_APPROX_TURF]
	var/unsafe_environment = virtual_turf && (isspaceturf(virtual_turf) || is_water_turf(virtual_turf))
	var/needs_environment = living_pawn.on_fire || unsafe_environment
	if(needs_environment && !force)
		elapsed_seconds = min(elapsed_seconds, cyberpunk_phantom_tick_interval() / (1 SECONDS))

	var/mob/living/carbon/carbon_pawn = living_pawn
	var/active_medicine = can_compact_chemistry && istype(carbon_pawn) && carbon_pawn.reagents?.total_volume
	if(active_medicine && !force)
		elapsed_seconds = FLOOR(elapsed_seconds, SSMOBS_DT)
	phantom_medical_at += elapsed_seconds * (1 SECONDS)

	if(active_medicine && living_pawn.stat != DEAD && !HAS_TRAIT(living_pawn, TRAIT_STASIS) && !HAS_TRAIT(living_pawn, TRAIT_NO_TRANSFORM))
		cyberpunk_advance_phantom_medicine(carbon_pawn, elapsed_seconds)
	if(virtual_turf && phantom_body && get_turf(phantom_body) != virtual_turf)
		phantom_body.forceMove(virtual_turf)
	if(!QDELETED(living_pawn))
		if(needs_environment)
			cyberpunk_phantom_medical_step(living_pawn, elapsed_seconds)
		else
			cyberpunk_advance_phantom_injury(living_pawn, elapsed_seconds)
	processing_phantom_medicine = FALSE
	if(QDELETED(living_pawn))
		return FALSE
	set_blackboard_key(BB_CP_PHANTOM_HEALTH_VALUE, living_pawn.health)
	set_blackboard_key(BB_CP_PHANTOM_HEALTH_STATE, living_pawn.stat == DEAD ? "dead" : "[round(living_pawn.health)]/[living_pawn.maxHealth]")
	if(!force)
		if(living_pawn.stat == DEAD)
			cyberpunk_materialize_phantom("death on the route")
			return FALSE
		if(needs_environment && !cyberpunk_can_compact_chemistry(living_pawn))
			cyberpunk_materialize_phantom("chemistry needs physical processing")
			return FALSE
	return TRUE

/// Integrates a simple medicine's healing and consumption over elapsed time.
/datum/ai_controller/proc/cyberpunk_advance_phantom_medicine(mob/living/carbon/body, elapsed_seconds)
	var/datum/reagent/medicine/omnizine/medicine = body.reagents.reagent_list[1]
	var/circulation = 1
	if(body.stat == HARD_CRIT && body.undergoing_cardiac_arrest())
		circulation = CARBON_HARDCRIT_CIRCULATION_METABOLISM_MULTIPLIER

	var/step_seconds = SSMOBS_DT * circulation
	var/volume_per_step = medicine.get_metabolization_amount(body, step_seconds)
	if(volume_per_step <= 0)
		return

	var/full_steps = FLOOR(elapsed_seconds / SSMOBS_DT, 1)
	var/partial_seconds = (elapsed_seconds - full_steps * SSMOBS_DT) * circulation
	var/full_volume = min(medicine.volume, volume_per_step * full_steps)
	var/partial_volume = min(medicine.volume - full_volume, volume_per_step * partial_seconds / step_seconds)
	var/exposure = REM * (full_volume * step_seconds + partial_volume * partial_seconds)
	medicine.current_cycle += min(full_steps, CEILING(medicine.volume / volume_per_step, 1)) + (partial_volume > 0)
	var/health_changed = medicine.heal_damage(body, exposure)
	if(!QDELETED(body) && !QDELETED(medicine))
		body.reagents.remove_reagent(medicine.type, full_volume + partial_volume)
	if(!QDELETED(body) && health_changed)
		body.updatehealth()

/// Advance the consequences of existing injuries without running the pawn's body cycle.
/datum/ai_controller/proc/cyberpunk_advance_phantom_injury(mob/living/living_pawn, elapsed_seconds)
	if(living_pawn.stat == DEAD || HAS_TRAIT(living_pawn, TRAIT_STASIS))
		return
	var/mob/living/carbon/carbon_pawn = living_pawn
	if(!istype(carbon_pawn))
		var/mob/living/basic/basic_pawn = living_pawn
		if(istype(basic_pawn) && basic_pawn.staminaloss > 0)
			basic_pawn.adjust_stamina_loss(-basic_pawn.stamina_recovery * elapsed_seconds, forced = TRUE)
		return

	if(isnull(phantom_bleed_rate))
		phantom_bleed_rate = carbon_pawn.get_bleed_rate()
	if(phantom_bleed_rate > 0 && carbon_pawn.can_bleed())
		var/blood_lost = phantom_bleed_rate * elapsed_seconds
		var/elapsed_bleed_ticks = FLOOR(elapsed_seconds / SSMOBS_DT, 1)
		if(elapsed_bleed_ticks > 0)
			var/bleed_rate_before = carbon_pawn.get_bleed_rate()
			for(var/obj/item/bodypart/limb as anything in carbon_pawn.get_bodyparts())
				if(limb.generic_bleedstacks)
					limb.adjustBleedStacks(-elapsed_bleed_ticks, 0)
			phantom_bleed_rate = carbon_pawn.get_bleed_rate()
			blood_lost -= max(0, bleed_rate_before - phantom_bleed_rate) * elapsed_seconds * 0.5
		carbon_pawn.adjust_blood_volume(-max(0, blood_lost))
		if(carbon_pawn.get_blood_volume(apply_modifiers = TRUE) < BLOOD_VOLUME_SURVIVE && !HAS_TRAIT(carbon_pawn, TRAIT_NODEATH))
			carbon_pawn.death()
			return

	if(carbon_pawn.undergoing_cardiac_arrest())
		carbon_pawn.adjust_oxy_loss(CARBON_HARDCRIT_OXYLOSS_RATE * elapsed_seconds, updating_health = FALSE, forced = TRUE)
	if(carbon_pawn.oxygenation < 100 || carbon_pawn.get_blood_volume(apply_modifiers = TRUE) < BLOOD_VOLUME_SAFE || carbon_pawn.get_organ_loss(ORGAN_SLOT_LUNGS) > 0)
		carbon_pawn.handle_oxygenation(elapsed_seconds)
		carbon_pawn.updatehealth()

/// Applies breathing and temperature effects without invoking the body's Life proc.
/datum/ai_controller/proc/cyberpunk_phantom_medical_step(mob/living/living_pawn, elapsed_seconds)
	if(QDELETED(living_pawn))
		return FALSE
	if(living_pawn.stat == DEAD || HAS_TRAIT(living_pawn, TRAIT_STASIS))
		return TRUE
	if(HAS_TRAIT(living_pawn, TRAIT_NO_TRANSFORM))
		return FALSE
	var/mob/living/carbon/carbon_pawn = living_pawn
	SEND_SIGNAL(living_pawn, COMSIG_LIVING_PHANTOM_TEMPERATURE, elapsed_seconds)
	if(QDELETED(living_pawn))
		return FALSE
	if(istype(carbon_pawn))
		phantom_breath_seconds += elapsed_seconds
		var/breath_ticks = carbon_pawn.failed_last_breath ? 1 : carbon_pawn.get_cyberpunk_breath_tick_interval()
		if(phantom_breath_seconds >= breath_ticks * SSMOBS_DT)
			carbon_pawn.breathe(phantom_breath_seconds / breath_ticks)
			phantom_breath_seconds = 0
	else
		living_pawn.handle_breathing(elapsed_seconds)
	if(QDELETED(living_pawn))
		return FALSE
	var/datum/gas_mixture/environment = lightweight_atmos_scan_gasmix(living_pawn)
	if(environment)
		living_pawn.handle_environment(environment, elapsed_seconds)
	if(QDELETED(living_pawn))
		return FALSE
	var/mob/living/carbon/human/human_pawn = carbon_pawn
	if(istype(human_pawn) && human_pawn.dna)
		human_pawn.dna.species.handle_body_temperature(human_pawn, elapsed_seconds)

	if(QDELETED(living_pawn))
		return FALSE
	cyberpunk_advance_phantom_injury(living_pawn, elapsed_seconds)
	if(!QDELETED(living_pawn))
		living_pawn.updatehealth()
	return !QDELETED(living_pawn)

/// Processes one phantom task tick. This intentionally stays in the tg idle behavior path.
/datum/ai_controller/proc/cyberpunk_process_phantom(seconds_per_tick)
	if(!cyberpunk_enter_phantom())
		cyberpunk_materialize_phantom()
		return FALSE
	if(!cyberpunk_process_phantom_health())
		return TRUE
	var/mob/living/recovering_pawn = pawn
	if(recovering_pawn.stat != CONSCIOUS)
		// Physical incapacity pauses work/travel, but not wound progression or contract deadlines.
		for(var/timer_key in list(BB_CP_PHANTOM_FINISH_AT, BB_CP_CITY_TASK_FINISH_AT))
			var/finish_at = blackboard[timer_key]
			if(finish_at)
				set_blackboard_key(timer_key, finish_at + seconds_per_tick * (1 SECONDS))
		return TRUE

	var/accumulated_seconds = (blackboard[BB_CP_PHANTOM_ACCUMULATED_SECONDS] || 0) + seconds_per_tick
	var/next_tick = blackboard[BB_CP_PHANTOM_NEXT_TICK]
	if(next_tick && world.time < next_tick)
		set_blackboard_key(BB_CP_PHANTOM_ACCUMULATED_SECONDS, accumulated_seconds)
		return TRUE

	set_blackboard_key(BB_CP_PHANTOM_NEXT_TICK, world.time + cyberpunk_phantom_tick_interval())
	set_blackboard_key(BB_CP_PHANTOM_ACCUMULATED_SECONDS, 0)
	set_blackboard_key(BB_CP_PHANTOM_LAST_TICK, world.time)
	var/failure_chance = cyberpunk_phantom_failure_chance()
	if(failure_chance && prob(failure_chance))
		set_blackboard_key(BB_CP_PHANTOM_RISK_RESULT, "failed route risk ([failure_chance]%)")
		cyberpunk_fail_city_task("phantom route risk")
		return TRUE
	set_blackboard_key(BB_CP_PHANTOM_RISK_RESULT, failure_chance ? "passed route risk ([failure_chance]%)" : "no route risk")
	var/task_state = blackboard[BB_CP_CITY_TASK_STATE]
	var/delivery_task = cyberpunk_is_delivery_task(blackboard[BB_CP_CITY_TASK])
	if(task_state != CP_AI_TASK_WORKING && blackboard[BB_CP_CITY_TASK_FINISH_AT] && world.time >= blackboard[BB_CP_CITY_TASK_FINISH_AT])
		cyberpunk_fail_city_task("task timed out")
		return TRUE
	if(blackboard[BB_CP_CARGO_STATUS] == CP_AI_CARGO_CARRIED && !cyberpunk_has_city_cargo())
		cyberpunk_fail_city_task("cargo lost while profiled")
		return TRUE
	switch(task_state)
		if(CP_AI_TASK_ROUTE_TO_SOURCE)
			cyberpunk_process_phantom_route(BB_CP_CARGO_SOURCE, delivery_task ? CP_AI_TASK_PICKUP : CP_AI_TASK_ROUTE_TO_TARGET)
		if(CP_AI_TASK_ROUTE_TO_TARGET)
			cyberpunk_process_phantom_route(BB_CP_CARGO_RECEIVER, delivery_task ? CP_AI_TASK_DROPOFF : CP_AI_TASK_WORKING)
		if(CP_AI_TASK_RETURNING)
			cyberpunk_process_phantom_route(BB_CP_ROUTE_RETURN_POINT, CP_AI_TASK_COMPLETED)
		if(CP_AI_TASK_WORKING)
			cyberpunk_work_city_task(max(1, accumulated_seconds))
		if(CP_AI_TASK_PICKUP)
			if(!cyberpunk_pickup_city_cargo())
				cyberpunk_fail_city_task("cargo unavailable at phantom pickup")
				return TRUE
			set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
			set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
			cyberpunk_prepare_phantom_route(BB_CP_CARGO_RECEIVER)
		if(CP_AI_TASK_DROPOFF)
			var/atom/cargo = blackboard[BB_CP_CARGO]
			var/atom/receiver = blackboard[BB_CP_CARGO_RECEIVER] || blackboard[BB_CP_ROUTE_TARGET]
			if(!cyberpunk_city_adjacent(receiver))
				set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_ROUTE_TO_TARGET)
				return TRUE
			if(!cyberpunk_deliver_city_cargo())
				cyberpunk_fail_city_task("phantom cargo handoff failed")
				return TRUE
			var/mob/living/living_pawn = pawn
			cyberpunk_notify_ai_cargo_delivered(cargo, living_pawn)
			set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_DELIVERED)
			if(blackboard[BB_CP_ROUTE_RETURN_POINT])
				set_blackboard_key(BB_CP_CITY_TASK_STATE, CP_AI_TASK_RETURNING)
			else
				cyberpunk_complete_city_task("phantom cargo delivered")
	return TRUE

/// Queue the native JPS search from the virtual position, without materializing or blocking an AI tick.
/datum/ai_controller/proc/cyberpunk_prepare_phantom_route(target_key)
	var/atom/target = blackboard[target_key]
	if(!target && target_key == BB_CP_CARGO_RECEIVER)
		target = blackboard[BB_CP_ROUTE_TARGET]
	var/turf/current_turf = get_turf(pawn)
	if(phantom_body || !current_turf)
		current_turf = blackboard[BB_CP_PHANTOM_APPROX_TURF]
	var/turf/target_turf = get_turf(target)
	if(!current_turf || !target_turf)
		cyberpunk_fail_city_task("route target disappeared")
		return
	var/turf/leg_target = target_turf
	var/min_distance = 1
	clear_blackboard_key(BB_CP_PHANTOM_Z_EDGE)
	if(current_turf.z != target_turf.z)
		var/list/edges = cyberpunk_city_z_edges(current_turf, target_turf)
		var/list/edge = cyberpunk_service_z_next_edge(current_turf, target_turf, edges, blackboard[BB_CP_PHANTOM_Z_REJECTED])
		if(!edge)
			cyberpunk_fail_city_task("no accessible phantom z transition")
			return
		set_blackboard_key(BB_CP_PHANTOM_Z_EDGE, edge)
		set_blackboard_key(BB_CP_ROUTE_Z_TRANSITION, edge["entry"])
		leg_target = edge["entry"]
		min_distance = 0
	set_blackboard_key(BB_CP_ROUTE_TARGET_Z, target_turf.z)
	set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_TRAVELING)
	var/generation = ++phantom_route_generation
	set_blackboard_key(BB_CP_PHANTOM_PATH_PENDING, TRUE)
	var/datum/callback/on_path = CALLBACK(src, PROC_REF(cyberpunk_phantom_path_ready), generation)
	if(get_dist(current_turf, leg_target) <= min_distance)
		on_path.Invoke(list(current_turf))
		return
	var/atom/movable/moving_pawn = pawn
	var/list/access = get_access()
	var/datum/pathfind/jps/path = new
	path.setup(moving_pawn, access, max(world.maxx, world.maxy) * 2, !HAS_TRAIT(pawn, TRAIT_SPACEWALK), null, list(on_path), leg_target, min_distance, FALSE, DIAGONAL_REMOVE_CLUNKY)
	path.start = current_turf
	if(path.start())
		SSpathfinder.run_pathfind(path)
	else
		qdel(path)

/datum/ai_controller/proc/cyberpunk_phantom_path_ready(generation, list/path)
	if(generation != phantom_route_generation || !phantom_body || !blackboard[BB_CP_PHANTOM_PATH_PENDING])
		return
	clear_blackboard_key(BB_CP_PHANTOM_PATH_PENDING)
	if(!length(path))
		var/list/edge = blackboard[BB_CP_PHANTOM_Z_EDGE]
		if(edge)
			set_blackboard_key_assoc_lazylist(BB_CP_PHANTOM_Z_REJECTED, cyberpunk_service_z_edge_key(edge), TRUE)
			clear_blackboard_key(BB_CP_PHANTOM_Z_EDGE)
			return
		cyberpunk_fail_city_task("no walkable phantom route")
		return
	set_blackboard_key(BB_CP_PHANTOM_PATH, path)
	set_blackboard_key(BB_CP_PHANTOM_FINISH_AT, world.time + max(1, length(path) - 1) * (1 SECONDS))

/// Resolves a phantom travel phase.
/datum/ai_controller/proc/cyberpunk_process_phantom_route(target_key, next_state)
	if(blackboard[BB_CP_PHANTOM_PATH_PENDING])
		return
	if(!blackboard[BB_CP_PHANTOM_FINISH_AT])
		cyberpunk_prepare_phantom_route(target_key)
		return
	var/list/path = blackboard[BB_CP_PHANTOM_PATH]
	if(length(path))
		var/path_index = clamp(length(path) - ceil(max(0, blackboard[BB_CP_PHANTOM_FINISH_AT] - world.time) / (1 SECONDS)), 1, length(path))
		var/previous_index = max(1, path.Find(blackboard[BB_CP_PHANTOM_APPROX_TURF]))
		var/datum/can_pass_info/pass_info = new(pawn, get_access())
		for(var/index in (previous_index + 1) to path_index)
			var/turf/previous = path[index - 1]
			var/turf/next = path[index]
			if(!next || next.density || previous.LinkBlockedWithAccess(next, pass_info))
				cyberpunk_fail_city_task("phantom route became blocked")
				return
		var/turf/progress = path[path_index]
		if(!progress || progress.density)
			cyberpunk_fail_city_task("phantom route became blocked")
			return
		set_blackboard_key(BB_CP_PHANTOM_APPROX_TURF, progress)
		set_new_cells()
	if(world.time < blackboard[BB_CP_PHANTOM_FINISH_AT])
		return
	var/atom/target = blackboard[target_key]
	var/turf/target_turf = get_turf(target)
	if(!target_turf && target_key == BB_CP_CARGO_RECEIVER)
		target_turf = get_turf(blackboard[BB_CP_ROUTE_TARGET])
	if(!target_turf)
		cyberpunk_fail_city_task("route target disappeared")
		return
	clear_blackboard_key(BB_CP_PHANTOM_FINISH_AT)
	clear_blackboard_key(BB_CP_PHANTOM_PATH)
	var/list/edge = blackboard[BB_CP_PHANTOM_Z_EDGE]
	if(edge)
		var/turf/entry = edge["entry"]
		var/turf/exit = edge["exit"]
		var/obj/structure/ladder/ladder = edge["link"]
		var/obj/structure/stairs/stair = edge["link"]
		var/atom/movable/moving_pawn = pawn
		var/valid = entry && exit && !exit.density
		if(istype(ladder))
			valid = valid && !QDELETED(ladder) && get_turf(edge["up"] ? ladder.up : ladder.down) == exit
		else if(istype(stair))
			valid = valid && !QDELETED(stair) && stair.isTerminator()
			var/turf/opening = get_step_multiz(stair, UP)
			if(edge["up"])
				valid = valid && moving_pawn.can_z_move(UP, entry, opening, z_move_flags = ZMOVE_ALLOW_BUCKLED)
			else
				valid = valid && moving_pawn.can_z_move(DOWN, entry, exit, z_move_flags = ZMOVE_STAIRS_FLAGS)
		else
			valid = valid && moving_pawn.can_z_move(edge["up"] ? UP : DOWN, entry, exit, z_move_flags = ZMOVE_FLIGHT_FLAGS)
		clear_blackboard_key(BB_CP_PHANTOM_Z_EDGE)
		if(valid)
			set_blackboard_key(BB_CP_PHANTOM_APPROX_TURF, exit)
			set_blackboard_key(BB_CP_ROUTE_CURRENT_Z, exit.z)
			set_new_cells()
		else
			set_blackboard_key_assoc_lazylist(BB_CP_PHANTOM_Z_REJECTED, cyberpunk_service_z_edge_key(edge), TRUE)
		return
	var/turf/arrival = blackboard[BB_CP_PHANTOM_APPROX_TURF]
	if(arrival?.z != target_turf.z || get_dist(arrival, target_turf) > 1)
		return
	set_blackboard_key(BB_CP_ROUTE_CURRENT_Z, arrival.z)
	clear_blackboard_key(BB_CP_PHANTOM_Z_REJECTED)
	if(next_state == CP_AI_TASK_COMPLETED)
		cyberpunk_complete_city_task("phantom route completed")
		return
	set_blackboard_key(BB_CP_CITY_TASK_STATE, next_state)

/datum/ai_controller/proc/recalculate_idle(datum/exited)
	if(ai_status == AI_STATUS_OFF)
		return

	var/distance = INFINITY
	if(islist(exited))
		var/list/exited_list = exited
		distance = get_dist(pawn, exited_list[1])
	else if(isatom(exited))
		var/atom/exited_atom = exited
		distance = get_dist(pawn, exited_atom)

	if(distance <= interesting_dist) //is our target in between interesting cells?
		return

	if(should_idle())
		if(blackboard[BB_CP_ROUTE_VISIBLE])
			clear_blackboard_key(BB_CP_ROUTE_VISIBLE)
		set_ai_status(AI_STATUS_IDLE)

/datum/ai_controller/proc/on_client_enter(datum/source, list/target_list)
	SIGNAL_HANDLER

	if (!(locate(/mob/living) in target_list))
		return

	addtimer(CALLBACK(src, PROC_REF(cyberpunk_materialize_after_client_enter)), 0)

/datum/ai_controller/proc/cyberpunk_materialize_after_client_enter()
	if(ai_status == AI_STATUS_IDLE)
		cyberpunk_materialize_phantom("client entered interest range")
		set_ai_status(AI_STATUS_ON)

/datum/ai_controller/proc/on_client_exit(datum/source, datum/exited)
	SIGNAL_HANDLER

	recalculate_idle(exited)

/// Sets the AI on or off based on current conditions, call to reset after you've manually disabled it somewhere
/datum/ai_controller/proc/reset_ai_status()
	set_ai_status(get_expected_ai_status())

/**
 * Gets the AI status we expect the AI controller to be on at this current moment.
 * Returns AI_STATUS_OFF if it's inhabited by a Client and shouldn't be, if it's dead and cannot act while dead, or is on a z level without clients.
 * Returns AI_STATUS_ON otherwise.
 */
/datum/ai_controller/proc/get_expected_ai_status()
	if(blackboard[BB_CP_PHANTOM_STATE] && blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return AI_STATUS_IDLE
	if (isnull(get_turf(pawn)))
		return AI_STATUS_OFF

	if (!ismob(pawn))
		return AI_STATUS_ON

	var/mob/living/mob_pawn = pawn
	if(!continue_processing_when_client && mob_pawn.client)
		return AI_STATUS_OFF

	if(mob_pawn.stat == DEAD)
		if(ai_traits & CAN_ACT_WHILE_DEAD)
			return AI_STATUS_ON
		return AI_STATUS_OFF

	var/turf/pawn_turf = get_turf(mob_pawn)
#ifdef TESTING
	if(!pawn_turf)
		CRASH("AI controller [src] controlling pawn ([pawn]) is not on a turf.")
#endif
	if(on_failed_planning_timeout || !able_to_run)
		return AI_STATUS_OFF
	if(!length(SSmobs.clients_by_zlevel[pawn_turf.z]))
		// Keep the idle scheduler available so a city task can resume once physical chemistry clears.
		return cyberpunk_should_process_phantom(check_chemistry = FALSE) ? AI_STATUS_IDLE : AI_STATUS_OFF
	if(should_idle())
		return AI_STATUS_IDLE
	return AI_STATUS_ON

///Called when the AI controller pawn changes z levels, we check if there's any clients on the new one and wake up the AI if there is.
/datum/ai_controller/proc/on_changed_z_level(atom/source, turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	SIGNAL_HANDLER
	if (ismob(pawn))
		var/mob/mob_pawn = pawn
		if((mob_pawn?.client && !continue_processing_when_client))
			return
	if(old_turf)
		GLOB.ai_controllers_by_zlevel[old_turf.z] -= src
	if(isnull(new_turf))
		return
	GLOB.ai_controllers_by_zlevel[new_turf.z] += src
	reset_ai_status()

///Abstract proc for initializing the pawn to the new controller
/datum/ai_controller/proc/TryPossessPawn(atom/new_pawn)
	return

///Proc for deinitializing the pawn to the old controller
/datum/ai_controller/proc/UnpossessPawn(destroy)
	SHOULD_CALL_PARENT(TRUE)
	if(isnull(pawn))
		return // instantiated without an applicable pawn, fine
	cyberpunk_materialize_phantom("controller released")

	SEND_SIGNAL(src, COMSIG_AI_CONTROLLER_UNPOSSESSED_PAWN)
	set_ai_status(AI_STATUS_OFF)
	UnregisterSignal(pawn, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT, COMSIG_MOB_STATCHANGE, COMSIG_QDELETING, COMSIG_EVLOGGING_ENABLED))
	clear_able_to_run()
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)
	var/turf/pawn_turf = get_turf(pawn)
	if(pawn_turf)
		GLOB.ai_controllers_by_zlevel[pawn_turf.z] -= src
	remove_from_unplanned_controllers()
	pawn.ai_controller = null
	pawn = null
	if(destroy)
		qdel(src)

/datum/ai_controller/proc/setup_able_to_run()
	// paused_until is handled by PauseAi() manually
	RegisterSignals(pawn, list(SIGNAL_ADDTRAIT(TRAIT_AI_PAUSED), SIGNAL_REMOVETRAIT(TRAIT_AI_PAUSED)), PROC_REF(update_able_to_run))

/datum/ai_controller/proc/clear_able_to_run()
	UnregisterSignal(pawn, list(SIGNAL_ADDTRAIT(TRAIT_AI_PAUSED), SIGNAL_REMOVETRAIT(TRAIT_AI_PAUSED)))

/datum/ai_controller/proc/update_able_to_run()
	SIGNAL_HANDLER
	var/run_flags = get_able_to_run()
	if(run_flags & AI_UNABLE_TO_RUN)
		able_to_run = FALSE
		GLOB.move_manager.stop_looping(pawn) //stop moving
	else
		able_to_run = TRUE
	set_ai_status(get_expected_ai_status(), run_flags)

///Returns TRUE if the ai controller can actually run at the moment, FALSE otherwise
/datum/ai_controller/proc/get_able_to_run()
	if(HAS_TRAIT(pawn, TRAIT_AI_PAUSED))
		return AI_UNABLE_TO_RUN
	if(world.time < paused_until)
		return AI_UNABLE_TO_RUN
	return NONE

///Can this pawn interact with objects?
/datum/ai_controller/proc/ai_can_interact()
	SHOULD_CALL_PARENT(TRUE)
	return !QDELETED(pawn)

///Interact with objects
/datum/ai_controller/proc/ai_interact(target, combat_mode, list/modifiers)
	if(!ai_can_interact())
		return FALSE

	var/atom/final_target = isdatum(target) ? target : blackboard[target] //incase we got a blackboard key instead

	if(QDELETED(final_target))
		return FALSE
	var/params = list2params(modifiers)
	var/mob/living/living_pawn = pawn
	if(isnull(combat_mode))
		living_pawn.ClickOn(final_target, params)
		return TRUE

	var/old_combat_mode = living_pawn.combat_mode
	living_pawn.set_combat_mode(combat_mode)
	living_pawn.ClickOn(final_target, params)
	living_pawn.set_combat_mode(old_combat_mode)
	return TRUE

///Runs any actions that are currently running
/datum/ai_controller/process(seconds_per_tick)

	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)

		// Convert the current behaviour action cooldown to realtime seconds from deciseconds.current_behavior
		// Then pick the max of this and the seconds_per_tick passed to ai_controller.process()
		// Action cooldowns cannot happen faster than seconds_per_tick, so seconds_per_tick should be the value used in this scenario.
		var/action_seconds_per_tick = max(current_behavior.get_cooldown(src) * 0.1, seconds_per_tick)

		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT))
			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			ProcessBehavior(action_seconds_per_tick, current_behavior)
			return

		if(isnull(current_movement_target))
			fail_behavior(current_behavior)
			return

		///Stops pawns from performing such actions that should require the target to be adjacent.
		var/atom/movable/moving_pawn = pawn
		var/can_reach = !(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_REACH) || current_movement_target.IsReachableBy(moving_pawn)
		if(can_reach && current_behavior.required_distance >= get_dist(moving_pawn, current_movement_target)) ///Are we close enough to engage?
			if(ai_movement.moving_controllers[src] == current_movement_target) //We are close enough, if we're moving stop.
				ai_movement.stop_moving_towards(src)

			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			ProcessBehavior(action_seconds_per_tick, current_behavior)
			return

		if(ai_movement.moving_controllers[src] != current_movement_target) //We're too far, if we're not already moving start doing it.
			ai_movement.start_moving_towards(src, current_movement_target, current_behavior.required_distance) //Then start moving

		if(current_behavior.behavior_flags & AI_BEHAVIOR_MOVE_AND_PERFORM) //If we can move and perform then do so.
			if(behavior_cooldowns[current_behavior] > world.time) //Still on cooldown
				continue
			ProcessBehavior(action_seconds_per_tick, current_behavior)
			return

///This is where you decide what actions are taken by the AI.
/datum/ai_controller/proc/SelectBehaviors(seconds_per_tick)
	SHOULD_NOT_SLEEP(TRUE) //Fuck you don't sleep in procs like this.
	planned_behaviors.Cut()

	for(var/datum/ai_planning_subtree/subtree as anything in planning_subtrees)
		if(subtree.SelectBehaviors(src, seconds_per_tick) == SUBTREE_RETURN_FINISH_PLANNING)
			break

	SEND_SIGNAL(src, COMSIG_AI_CONTROLLER_PICKED_BEHAVIORS, current_behaviors, planned_behaviors)
	for(var/datum/ai_behavior/forgotten_behavior as anything in current_behaviors - planned_behaviors)
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[type]
		if(stored_arguments)
			arguments += stored_arguments
		forgotten_behavior.finish_action(arglist(arguments))

	if(IS_EVLOGGING)
		var/list/event_text = list()
		event_text += "New plan starting!"

		for(var/datum/ai_behavior/behavior in planned_behaviors)
			event_text += "Queued behavior [behavior.type]"

		EVLOG_TEXT(src, EVLOG_CATEGORY_AI_DECISIONMAKING, jointext(event_text, "\n"))

///This proc handles changing ai status, and starts/stops processing if required.
/datum/ai_controller/proc/set_ai_status(new_ai_status, additional_flags = NONE)
	if(ai_status == new_ai_status)
		return FALSE //no change

	//remove old status, if we've got one
	if(ai_status)
		GLOB.ai_controllers_by_status[ai_status] -= src
		for(var/datum/controller/subsystem/ai_controllers/controller_subsystem in Master.subsystems)
			if(controller_subsystem.planning_status == ai_status)
				controller_subsystem.currentrun -= src
				break
	remove_from_unplanned_controllers()
	stop_previous_processing()
	ai_status = new_ai_status
	GLOB.ai_controllers_by_status[new_ai_status] += src
	if(ai_status == AI_STATUS_OFF)
		if(!(additional_flags & AI_PREVENT_CANCEL_ACTIONS))
			CancelActions()
		return
	if(!length(current_behaviors))
		add_to_unplanned_controllers()
		return
	start_ai_processing()

/datum/ai_controller/proc/start_ai_processing()
	switch(ai_status)
		if(AI_STATUS_ON)
			START_PROCESSING(SSai_behaviors, src)
		if(AI_STATUS_IDLE)
			START_PROCESSING(SSidle_ai_behaviors, src)

/datum/ai_controller/proc/stop_previous_processing()
	switch(ai_status)
		if(AI_STATUS_ON)
			STOP_PROCESSING(SSai_behaviors, src)
		if(AI_STATUS_IDLE)
			STOP_PROCESSING(SSidle_ai_behaviors, src)

/datum/ai_controller/proc/PauseAi(time)
	paused_until = world.time + time
	update_able_to_run()
	addtimer(CALLBACK(src, PROC_REF(update_able_to_run)), time)

/datum/ai_controller/proc/add_to_unplanned_controllers()
	if(isnull(ai_status) || ai_status == AI_STATUS_OFF || isnull(idle_behavior))
		return
	GLOB.unplanned_controllers[ai_status][src] = TRUE

/datum/ai_controller/proc/remove_from_unplanned_controllers()
	if(isnull(ai_status) || ai_status == AI_STATUS_OFF)
		return
	GLOB.unplanned_controllers[ai_status] -= src
	for(var/datum/controller/subsystem/unplanned_controllers/potential_holder as anything in GLOB.unplanned_controller_subsystems)
		if(potential_holder.target_status == ai_status)
			potential_holder.current_run -= src

/datum/ai_controller/proc/modify_cooldown(datum/ai_behavior/behavior, new_cooldown)
	behavior_cooldowns[behavior] = new_cooldown

///Call this to add a behavior to the stack.
/datum/ai_controller/proc/queue_behavior(behavior_type, ...)
	var/datum/ai_behavior/behavior = GET_AI_BEHAVIOR(behavior_type)
	if(!behavior)
		CRASH("Behavior [behavior_type] not found.")
	var/list/arguments = args.Copy()
	arguments[1] = src

	if(current_behaviors[behavior]) ///It's still in the plan, don't add it again to current_behaviors but do keep it in the planned behavior list so its not cancelled
		planned_behaviors[behavior] = TRUE
		return

	if(!behavior.setup(arglist(arguments)))
		return

	var/should_exit_unplanned = !length(current_behaviors)
	planned_behaviors[behavior] = TRUE
	current_behaviors[behavior] = TRUE

	arguments.Cut(1, 2)
	if(length(arguments))
		behavior_args[behavior_type] = arguments
	else
		behavior_args -= behavior_type

	if(!(behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION)) //this one blocks planning!
		able_to_plan = FALSE

	if(should_exit_unplanned)
		exit_unplanned_mode()

	SEND_SIGNAL(src, AI_CONTROLLER_BEHAVIOR_QUEUED(behavior_type), arguments)

/datum/ai_controller/proc/check_able_to_plan()
	if(blackboard[BB_CP_PHANTOM_STATE] && blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return FALSE
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION)) //We have a behavior that blocks planning
			return FALSE
	return TRUE

/datum/ai_controller/proc/dequeue_behavior(datum/ai_behavior/behavior)
	current_behaviors -= behavior
	able_to_plan = check_able_to_plan()
	if(!length(current_behaviors))
		enter_unplanned_mode()

/datum/ai_controller/proc/exit_unplanned_mode()
	remove_from_unplanned_controllers()
	start_ai_processing()

/datum/ai_controller/proc/enter_unplanned_mode()
	add_to_unplanned_controllers()
	stop_previous_processing()

/datum/ai_controller/proc/ProcessBehavior(seconds_per_tick, datum/ai_behavior/behavior)
	var/list/arguments = list(seconds_per_tick, src)
	var/list/stored_arguments = behavior_args[behavior.type]
	if(stored_arguments)
		arguments += stored_arguments

	var/process_flags = behavior.perform(arglist(arguments))
	if(process_flags & AI_BEHAVIOR_DELAY)
		behavior_cooldowns[behavior] = world.time + behavior.get_cooldown(src)
	if(process_flags & AI_BEHAVIOR_FAILED)
		arguments[1] = src
		arguments[2] = FALSE
		behavior.finish_action(arglist(arguments))
	else if (process_flags & AI_BEHAVIOR_SUCCEEDED)
		arguments[1] = src
		arguments[2] = TRUE
		behavior.finish_action(arglist(arguments))

/datum/ai_controller/proc/CancelActions()
	if(!length(current_behaviors))
		return
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		fail_behavior(current_behavior)
	EVLOG_TEXT(src, EVLOG_CATEGORY_AI_DECISIONMAKING, "Actions were cancelled!")

/datum/ai_controller/proc/fail_behavior(datum/ai_behavior/current_behavior)
	var/list/arguments = list(src, FALSE)
	var/list/stored_arguments = behavior_args[current_behavior.type]
	if(stored_arguments)
		arguments += stored_arguments
	current_behavior.finish_action(arglist(arguments))

/// Turn the controller on or off based on if you're alive, we only register to this if the flag is present so don't need to check again
/datum/ai_controller/proc/on_stat_changed(mob/living/source, new_stat)
	SIGNAL_HANDLER
	reset_ai_status()
	update_able_to_run()

/datum/ai_controller/proc/on_sentience_gained()
	SIGNAL_HANDLER
	cyberpunk_materialize_phantom("player connected")
	UnregisterSignal(pawn, COMSIG_MOB_LOGIN)
	if(!continue_processing_when_client)
		set_ai_status(AI_STATUS_OFF) //Can't do anything while player is connected
	RegisterSignal(pawn, COMSIG_MOB_LOGOUT, PROC_REF(on_sentience_lost))

/datum/ai_controller/proc/on_sentience_lost()
	SIGNAL_HANDLER
	UnregisterSignal(pawn, COMSIG_MOB_LOGOUT)
	set_ai_status(AI_STATUS_IDLE) //Can't do anything while player is connected
	RegisterSignal(pawn, COMSIG_MOB_LOGIN, PROC_REF(on_sentience_gained))

// Turn the controller off if the pawn has been qdeleted
/datum/ai_controller/proc/on_pawn_qdeleted()
	SIGNAL_HANDLER
	set_ai_status(AI_STATUS_OFF)
	set_movement_target(type, null)
	if(ai_movement.moving_controllers[src])
		ai_movement.stop_moving_towards(src)

/// Use this proc to define how your controller defines what access the pawn has for the sake of pathfinding. Return the access list you want to use
/datum/ai_controller/proc/get_access()
	if(!isliving(pawn))
		return
	var/mob/living/living_pawn = pawn
	return living_pawn.get_access()

///Returns the minimum required distance to preform one of our current behaviors. Honestly this should just be cached or something but fuck you
/datum/ai_controller/proc/get_minimum_distance()
	var/minimum_distance = max_target_distance
	// right now I'm just taking the shortest minimum distance of our current behaviors, at some point in the future
	// we should let whatever sets the current_movement_target also set the min distance and max path length
	// (or at least cache it on the controller)
	for(var/datum/ai_behavior/iter_behavior as anything in current_behaviors)
		if(iter_behavior.required_distance < minimum_distance)
			minimum_distance = iter_behavior.required_distance
	return minimum_distance

/datum/ai_controller/proc/planning_failed()
	on_failed_planning_timeout = TRUE
	set_ai_status(get_expected_ai_status())
	addtimer(CALLBACK(src, PROC_REF(resume_planning)), AI_FAILED_PLANNING_COOLDOWN)

/datum/ai_controller/proc/resume_planning()
	on_failed_planning_timeout = FALSE
	set_ai_status(get_expected_ai_status())

/// Returns true if we have a blackboard key with the provided key and it is not qdeleting
/datum/ai_controller/proc/blackboard_key_exists(key)
	var/datum/key_value = blackboard[key]
	if (isdatum(key_value))
		return !QDELETED(key_value)
	if (islist(key_value))
		return length(key_value) > 0
	return !!key_value

/**
 * Used to manage references to datum by AI controllers
 *
 * * tracked_datum - something being added to an ai blackboard
 * * key - the associated key
 */
#define TRACK_AI_DATUM_TARGET(tracked_datum, key) do { \
	if(isweakref(tracked_datum)) { \
		var/datum/weakref/_bad_weakref = tracked_datum; \
		stack_trace("Weakref (Actual datum: [_bad_weakref.resolve()]) found in ai datum blackboard! \
			This is an outdated method of ai reference handling, please remove it."); \
	}; \
	else if(isdatum(tracked_datum)) { \
		var/datum/_tracked_datum = tracked_datum; \
		if(QDELETED(_tracked_datum)) { \
			stack_trace("Tried to track a qdeleted datum ([_tracked_datum]) in ai datum blackboard (key: [key])! \
				Please ensure that we are not doing this by adding handling where necessary."); \
			return; \
		}; \
		else if(!HAS_TRAIT_FROM(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]")) { \
			RegisterSignal(_tracked_datum, COMSIG_QDELETING, PROC_REF(sig_remove_from_blackboard), override = TRUE); \
			ADD_TRAIT(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]"); \
		}; \
	}; \
} while(FALSE)

/**
 * Used to clear previously set reference handing by AI controllers
 *
 * * tracked_datum - something being removed from an ai blackboard
 * * key - the associated key
 */
#define CLEAR_AI_DATUM_TARGET(tracked_datum, key) do { \
	if(isdatum(tracked_datum)) { \
		var/datum/_tracked_datum = tracked_datum; \
		REMOVE_TRAIT(_tracked_datum, TRAIT_AI_TRACKING, "[REF(src)]_[key]"); \
		if(!HAS_TRAIT(_tracked_datum, TRAIT_AI_TRACKING)) { \
			UnregisterSignal(_tracked_datum, COMSIG_QDELETING); \
		}; \
	}; \
} while(FALSE)

/// Used for above to track all the keys that have registered a signal
#define TRAIT_AI_TRACKING "tracked_by_ai"

/**
 * Sets the key to the passed "thing".
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/set_blackboard_key(key, thing)
	// Assume it is an error when trying to set a value overtop a list
	if(islist(blackboard[key]))
		CRASH("set_blackboard_key attempting to set a blackboard value to key [key] when it's a list!")
	// Don't do anything if it's already got this value
	if (blackboard[key] == thing)
		return

	// Clear existing values
	if(!isnull(blackboard[key]))
		clear_blackboard_key(key)

	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] = thing
	post_blackboard_key_set(key)

/**
 * Helper to force a key to be a certain thing no matter what's already there
 *
 * Useful for if you're overriding a list with a new list entirely,
 * as otherwise it would throw a runtime error from trying to override a list
 *
 * Not necessary to use if you aren't dealing with lists, as set_blackboard_key will clear the existing value
 * in that case already, but may be useful for clarity.
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/override_blackboard_key(key, thing)
	if(blackboard[key] == thing)
		return

	clear_blackboard_key(key)
	set_blackboard_key(key, thing)

/**
 * Sets the key at index thing to the passed value
 *
 * Assumes the key value is already a list, if not throws an error.
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/set_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		CRASH("set_blackboard_key_assoc called on non-list key [key]!")
	// Don't do anything if it's already got this value
	if (blackboard[key][thing] == value)
		return

	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] = value
	post_blackboard_key_set(key)

/**
 * Similar to [proc/set_blackboard_key_assoc] but operates under the assumption the key is a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/set_blackboard_key_assoc_lazylist(key, thing, value)
	LAZYINITLIST(blackboard[key])
	// Don't do anything if it's already got this value
	if (blackboard[key][thing] == value)
		return

	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] = value
	post_blackboard_key_set(key)

/**
 * Called after we set a blackboard key, forwards signal information.
 */
/datum/ai_controller/proc/post_blackboard_key_set(key)
	if (isnull(pawn))
		return
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_SET(key), key)

/**
 * Adds the passed "thing" to the associated key
 *
 * Works with lists or numbers, but not lazylists.
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/add_blackboard_key(key, thing)
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] += thing

/**
 * Similar to [proc/add_blackboard_key], but performs an insertion rather than an add
 * Throws an error if the key is not a list already, intended only for use with lists
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/insert_blackboard_key(key, thing)
	if(!islist(blackboard[key]))
		CRASH("insert_blackboard_key called on non-list key [key]!")
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] |= thing

/**
 * Adds the passed "thing" to the associated key, assuming key is intended to be a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/add_blackboard_key_lazylist(key, thing)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] += thing

/**
 * Similar to [proc/insert_blackboard_key_lazylist], but performs an insertion / or rather than an add
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/insert_blackboard_key_lazylist(key, thing)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	blackboard[key] |= thing

/**
 * Adds the value to the inner list at key with the inner key set to "thing"
 * Throws an error if the key is not a list already, intended only for use with lists
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/add_blackboard_key_assoc(key, thing, value)
	if(!islist(blackboard[key]))
		CRASH("add_blackboard_key_assoc called on non-list key [key]!")
	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] += value


/**
 * Similar to [proc/add_blackboard_key_assoc], assuming key is intended to be a lazylist (so it will create a list)
 * More dangerous / easier to override values, only use when you want to use a lazylist
 *
 * * key - A blackboard key, with its value set to a list
 * * thing - a value which becomes the inner list value's key
 * * value - what to set the inner list's value to
 */
/datum/ai_controller/proc/add_blackboard_key_assoc_lazylist(key, thing, value)
	LAZYINITLIST(blackboard[key])
	TRACK_AI_DATUM_TARGET(thing, key)
	TRACK_AI_DATUM_TARGET(value, key)
	blackboard[key][thing] += value

/**
 * Clears the passed key, resetting it to null
 *
 * Not intended for use with list keys - use [proc/remove_thing_from_blackboard_key] if you are removing a value from a list at a key
 *
 * * key - A blackboard key
 */
/datum/ai_controller/proc/clear_blackboard_key(key)
	if(isnull(blackboard[key]))
		return
	if(pawn && (SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_PRECLEAR(key))))
		return
	CLEAR_AI_DATUM_TARGET(blackboard[key], key)
	blackboard[key] = null
	if(isnull(pawn))
		return
	SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(key))

/**
 * Remove the passed thing from the associated blackboard key
 *
 * Intended for use with lists, if you're just clearing a reference from a key use [proc/clear_blackboard_key]
 *
 * * key - A blackboard key
 * * thing - a value to set the blackboard key to.
 */
/datum/ai_controller/proc/remove_thing_from_blackboard_key(key, thing)
	var/associated_value = blackboard[key]
	if(isnull(associated_value))
		return
	if(thing == associated_value)
		stack_trace("remove_thing_from_blackboard_key was called un-necessarily in a situation where clear_blackboard_key would suffice. ")
		clear_blackboard_key(key)
		return

	if(!islist(associated_value))
		CRASH("remove_thing_from_blackboard_key called with an invalid \"thing\" argument ([thing]). \
			(The associated value of the passed key is not a list and is also not the passed thing, meaning it is clearing an unintended value.)")

	for(var/inner_key in associated_value)
		if(inner_key == thing)
			// flat list
			CLEAR_AI_DATUM_TARGET(thing, key)
			associated_value -= thing
			return
		else if(associated_value[inner_key] == thing)
			// assoc list
			CLEAR_AI_DATUM_TARGET(thing, key)
			associated_value -= inner_key
			return

	CRASH("remove_thing_from_blackboard_key called with an invalid \"thing\" argument ([thing]). \
		(The passed value is not tracked in the passed list.)")

///removes a tracked object from a lazylist
/datum/ai_controller/proc/remove_from_blackboard_lazylist_key(key, thing)
	var/lazylist = blackboard[key]
	if(isnull(lazylist))
		return
	for(var/key_index in lazylist)
		if(thing == key_index || lazylist[key_index] == thing)
			CLEAR_AI_DATUM_TARGET(thing, key)
			lazylist -= key_index
			break
	if(!LAZYLEN(lazylist))
		clear_blackboard_key(key)

/// Signal proc to go through every key and remove the datum from all keys it finds
/datum/ai_controller/proc/sig_remove_from_blackboard(datum/source)
	SIGNAL_HANDLER

	var/list/list/remove_queue = list(blackboard)
	var/index = 1
	while(index <= length(remove_queue))
		var/list/next_to_clear = remove_queue[index]
		for(var/inner_value in next_to_clear)
			// We are a lists of lists, add the next value to the queue so we can handle references in there
			// (But we only need to bother checking the list if it's not empty.)
			if(islist(inner_value) && length(inner_value))
				UNTYPED_LIST_ADD(remove_queue, inner_value)

			// We found the value that's been deleted. Clear it out from this list
			else if(inner_value == source)
				next_to_clear -= inner_value

			//if this is the case stop here. This means the list isn't associative (because an assoc list couldnt have a key for a number!)
			if(isnum(inner_value))
				continue

			var/associated_value = next_to_clear[inner_value]
			if(!associated_value) //This wasn't an associated list! we lied! its all been a trick. Try again next time.
				continue
			// We are an assoc lists of lists, the list at the next value so we can handle references in there
			// (But again, we only need to bother checking the list if it's not empty.)
			if(islist(associated_value) && length(associated_value))
				UNTYPED_LIST_ADD(remove_queue, associated_value)

			// We found the value that's been deleted, it was an assoc value. Clear it out entirely
			else if(associated_value == source)
				next_to_clear -= inner_value
				SEND_SIGNAL(pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(inner_value))

		index += 1

/// When the pawn gets DF_EVLOGGING, propagate it to this controller too.
/datum/ai_controller/proc/on_pawn_evlogging_enabled(datum/source)
	SIGNAL_HANDLER
	enable_evlogging(pawn)

/// When the pawn gets DF_EVLOGGING disabled, propagate it to this controller too.
/datum/ai_controller/proc/on_pawn_evlogging_disabled(datum/source)
	SIGNAL_HANDLER
	disable_evlogging(pawn)

///Register for an event being added so we can update track info
/datum/ai_controller/enable_evlogging()
	. = ..()
	RegisterSignal(src, COMSIG_EVLOG_EVENT_ADDED, PROC_REF(on_evlog_event_added))

///Unregister the evlog event added event, as we're no longer updating track info
/datum/ai_controller/disable_evlogging()
	. = ..()
	UnregisterSignal(src, COMSIG_EVLOG_EVENT_ADDED)

/// Called whenever an event is logged for this controller. Attaches a snapshot of current behaviors and blackboard state to the event via track_info.
/datum/ai_controller/proc/on_evlog_event_added(datum/source, datum/event_logger_track/track, list/event_data)
	SIGNAL_HANDLER
	var/list/track_info = list()

	var/list/current_behavior_info = list()
	for(var/datum/ai_behavior/behavior in planned_behaviors)
		if(behavior in current_behaviors) //Not really ideal; we should find a better way to do this.
			current_behavior_info += "ACTIVE: [span_bold("[behavior.type]")]"
		else
			current_behavior_info += "[behavior.type]"
	EVLOG_TRACK_INFO_ENTRY(track_info, "Behaviors", "Current Behavior", jointext(current_behavior_info, "\n"))

	for(var/blackboard_key_name, blackboard_value in blackboard)
		var/value_string
		if(isatom(blackboard_value))
			value_string = "[blackboard_value]"
		else if(islist(blackboard_value))
			var/list/blackboard_list = blackboard_value
			value_string = length(blackboard_list) ? jointext(blackboard_list, "\n") : "Empty List"
		else if(isnull(blackboard_value))
			value_string = "null"
		else // I think I covered all cases?
			value_string = "[blackboard_value]"
		EVLOG_TRACK_INFO_ENTRY(track_info, "Blackboard", blackboard_key_name, value_string)

	event_data["track_info"] = track_info


#undef TRACK_AI_DATUM_TARGET
#undef CLEAR_AI_DATUM_TARGET
#undef TRAIT_AI_TRACKING
