/// Basetype with normal parameters
/datum/ai_controller/basic_controller/simple
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk

/// The most basic AI tree which just finds a guy and then runs at them to click them
/datum/ai_controller/basic_controller/simple/simple_hostile
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Find a target, walk at target, attack intervening obstacles
/datum/ai_controller/basic_controller/simple/simple_hostile_obstacles
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Find a target, walk at target, attack intervening obstacles
/datum/ai_controller/basic_controller/simple/simple_ranged
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/datum/ai_controller/basic_controller/simple/simple_ranged_retaliate
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/// Find a target, walk towards it AND shoot it
/datum/ai_controller/basic_controller/simple/simple_skirmisher
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Use an ability on target on cooldown
/datum/ai_controller/basic_controller/simple/simple_ability
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
	)

/datum/ai_controller/basic_controller/simple/simple_ability_retaliate
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
	)

/// Use an ability on target on cooldown, then try to punch them
/datum/ai_controller/basic_controller/simple/simple_ability_melee
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Use an ability on target on cooldown, then try to shoot them
/datum/ai_controller/basic_controller/simple/simple_ability_ranged
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/ranged_skirmish,
	)

/// Fight back if attacked
/datum/ai_controller/basic_controller/simple/simple_retaliate
	ai_traits = DEFAULT_AI_FLAGS | STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Get pissed at random people for no reason
/datum/ai_controller/basic_controller/simple/simple_capricious
	ai_traits = DEFAULT_AI_FLAGS | STOP_MOVING_WHEN_PULLED
	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/capricious_retaliate,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Runs away from anyone it sees
/datum/ai_controller/basic_controller/simple/simple_fearful
	ai_traits = PASSIVE_AI_FLAGS
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_nearest_target_to_flee,
		/datum/ai_planning_subtree/flee_target,
	)

/// Cyberpunk generic city worker/controller shell.
/datum/ai_controller/basic_controller/simple/cyberpunk_city
	idle_behavior = /datum/idle_behavior/cyberpunk_phantom
	planning_subtrees = list(
		/datum/ai_planning_subtree/generic_resist,
		/datum/ai_planning_subtree/cyberpunk_city_task,
	)
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_CP_AI_ROLE_PROFILE = CP_AI_ROLE_CIVILIAN,
		BB_CP_AI_CAPABILITIES = CP_AI_CAP_HANDS | CP_AI_CAP_USE_CONTRACTS,
		BB_CP_AI_LEVEL = 1,
		BB_CP_PHANTOM_ENABLED = TRUE,
		BB_CP_PHANTOM_PROFILE = CP_AI_PHANTOM_PROFILE_LIGHT,
		BB_CP_PHANTOM_STATE = CP_AI_PHANTOM_INACTIVE,
	)

/datum/ai_controller/basic_controller/simple/cyberpunk_city/worker
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_CP_AI_ROLE_PROFILE = CP_AI_ROLE_WORKER,
		BB_CP_AI_CAPABILITIES = CP_AI_CAP_HANDS | CP_AI_CAP_CARGO_SLOT | CP_AI_CAP_USE_TERMINAL | CP_AI_CAP_USE_CONTRACTS | CP_AI_CAP_REPAIR,
		BB_CP_AI_LEVEL = 2,
		BB_CP_PHANTOM_ENABLED = TRUE,
		BB_CP_PHANTOM_PROFILE = CP_AI_PHANTOM_PROFILE_LIGHT,
		BB_CP_PHANTOM_STATE = CP_AI_PHANTOM_INACTIVE,
	)

/datum/ai_controller/basic_controller/simple/cyberpunk_city/corporate
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_CP_AI_ROLE_PROFILE = CP_AI_ROLE_CORPORATE,
		BB_CP_AI_CAPABILITIES = CP_AI_CAP_HANDS | CP_AI_CAP_USE_TERMINAL | CP_AI_CAP_USE_CONTRACTS,
		BB_CP_AI_LEVEL = 2,
		BB_CP_PHANTOM_ENABLED = TRUE,
		BB_CP_PHANTOM_PROFILE = CP_AI_PHANTOM_PROFILE_LIGHT,
		BB_CP_PHANTOM_STATE = CP_AI_PHANTOM_INACTIVE,
	)

/datum/ai_controller/basic_controller/simple/cyberpunk_city/runner
	idle_behavior = /datum/idle_behavior/cyberpunk_phantom/runner
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_CP_AI_ROLE_PROFILE = CP_AI_ROLE_CIVILIAN,
		BB_CP_AI_CAPABILITIES = CP_AI_CAP_HANDS,
		BB_CP_AI_LEVEL = 1,
		BB_CP_PHANTOM_ENABLED = TRUE,
		BB_CP_PHANTOM_PROFILE = CP_AI_PHANTOM_PROFILE_LIGHT,
		BB_CP_PHANTOM_STATE = CP_AI_PHANTOM_INACTIVE,
	)

/datum/ai_controller/basic_controller/simple/cyberpunk_city/security
	planning_subtrees = list(
		/datum/ai_planning_subtree/generic_resist,
		/datum/ai_planning_subtree/cyberpunk_security_response,
		/datum/ai_planning_subtree/flee_target/from_flee_key,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/cyberpunk_city_task,
	)
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_CP_AI_ROLE_PROFILE = CP_AI_ROLE_CORP_SECURITY,
		BB_CP_AI_CAPABILITIES = CP_AI_CAP_HANDS | CP_AI_CAP_COMBAT | CP_AI_CAP_USE_TERMINAL | CP_AI_CAP_USE_CONTRACTS,
		BB_CP_AI_LEVEL = 3,
		BB_CP_PHANTOM_ENABLED = TRUE,
		BB_CP_PHANTOM_PROFILE = CP_AI_PHANTOM_PROFILE_HEAVY,
		BB_CP_PHANTOM_STATE = CP_AI_PHANTOM_INACTIVE,
	)

/// Runs away when attacked
/datum/ai_controller/basic_controller/simple/simple_skittish
	ai_traits = PASSIVE_AI_FLAGS
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_nearest_thing_which_attacked_me_to_flee,
		/datum/ai_planning_subtree/flee_target,
	)

/// Does what it is told and protects da boss
/datum/ai_controller/basic_controller/simple/simple_goon
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_PET_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/escape_captivity,
		/datum/ai_planning_subtree/pet_planning,
	)

/// Literally does nothing except random speedh
/datum/ai_controller/basic_controller/talk
	idle_behavior = null
	planning_subtrees = list(
		/datum/ai_planning_subtree/random_speech/blackboard,
	)
