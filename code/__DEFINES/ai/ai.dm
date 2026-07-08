#define GET_AI_BEHAVIOR(behavior_type) SSai_behaviors.ai_behaviors[behavior_type]
#define GET_TARGETING_STRATEGY(targeting_type) SSai_behaviors.targeting_strategies[targeting_type]
#define GET_TARGET_PRIORITY_STRATEGY(targeting_type) SSai_behaviors.target_priority_strategies[targeting_type]
#define HAS_AI_CONTROLLER_TYPE(thing, type) istype(thing?.ai_controller, type)

//AI controller flags
//If you add a new status, be sure to add it to the ai_controllers subsystem's ai_controllers_by_status list.
///The AI is currently active.
#define AI_STATUS_ON "ai_on"
///The AI is currently offline for any reason.
#define AI_STATUS_OFF "ai_off"
///The AI is currently in idle mode.
#define AI_STATUS_IDLE "ai_idle"

//Flags returned by get_able_to_run()
///pauses AI processing
#define AI_UNABLE_TO_RUN (1<<1)
///bypass canceling our actions on set_ai_status()
#define AI_PREVENT_CANCEL_ACTIONS (1<<2)

///For JPS pathing, the maximum length of a path we'll try to generate. Should be modularized depending on what we're doing later on
#define AI_MAX_PATH_LENGTH 30 // 30 is possibly overkill since by default we lose interest after 14 tiles of distance, but this gives wiggle room for weaving around obstacles
#define AI_BOT_PATH_LENGTH 60
#define AI_MULEBOT_PATH_LENGTH 150 //we making a pilgramage sometimes...

// How far should we, by default, be looking for interesting things to de-idle?
#define AI_DEFAULT_INTERESTING_DIST 10

///Cooldown on planning if planning failed last time

#define AI_FAILED_PLANNING_COOLDOWN (1.5 SECONDS)

///Flags for ai_behavior new()
#define AI_CONTROLLER_INCOMPATIBLE (1<<0)

//Return flags for ai_behavior/perform()
///Update this behavior's cooldown
#define AI_BEHAVIOR_DELAY (1<<0)
///Finish the behavior successfully
#define AI_BEHAVIOR_SUCCEEDED (1<<1)
///Finish the behavior unsuccessfully
#define AI_BEHAVIOR_FAILED (1<<2)

#define AI_BEHAVIOR_INSTANT (NONE)

///Does this task require movement from the AI before it can be performed?
#define AI_BEHAVIOR_REQUIRE_MOVEMENT (1<<0)
///Does this require the current_movement_target to be adjacent and in reach?
#define AI_BEHAVIOR_REQUIRE_REACH (1<<1)
///Does this task let you perform the action while you move closer? (Things like moving and shooting)
#define AI_BEHAVIOR_MOVE_AND_PERFORM (1<<2)
///Does finishing this task not null the current movement target?
#define AI_BEHAVIOR_KEEP_MOVE_TARGET_ON_FINISH (1<<3)
///Does this behavior NOT block planning?
#define AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION (1<<4)

///AI flags
/// Don't move if being pulled
#define STOP_MOVING_WHEN_PULLED (1<<0)
/// Continue processing even if dead
#define CAN_ACT_WHILE_DEAD (1<<1)
/// Stop processing while in a progress bar
#define PAUSE_DURING_DO_AFTER (1<<2)
/// Continue processing while in stasis
#define CAN_ACT_IN_STASIS (1<<3)
/// Continue processing while aggressively grabbed
#define CAN_ACT_WHILE_GRABBED (1<<4)

/// Flags we expect for most AI controllers
#define DEFAULT_AI_FLAGS (PAUSE_DURING_DO_AFTER | CAN_ACT_WHILE_GRABBED)
/// Flags for passive mobs that are easy to push around
#define PASSIVE_AI_FLAGS (PAUSE_DURING_DO_AFTER | STOP_MOVING_WHEN_PULLED)

// Cyberpunk city AI role profiles.
#define CP_AI_ROLE_WORKER "worker"
#define CP_AI_ROLE_CIVILIAN "civilian"
#define CP_AI_ROLE_POLICE "police"
#define CP_AI_ROLE_CORPORATE "corporate"
#define CP_AI_ROLE_CORP_SECURITY "corp_security"
#define CP_AI_ROLE_BANDIT "bandit"
#define CP_AI_ROLE_ANTAG "antag"
#define CP_AI_ROLE_SERVICE "service"
#define CP_AI_ROLE_CONTRACTOR "contractor"

// Cyberpunk city AI capability bitfield.
#define CP_AI_CAP_HANDS (1<<0)
#define CP_AI_CAP_CARGO_SLOT (1<<1)
#define CP_AI_CAP_USE_TERMINAL (1<<2)
#define CP_AI_CAP_USE_CONTRACTS (1<<3)
#define CP_AI_CAP_Z_MOVE (1<<4)
#define CP_AI_CAP_CLIMB (1<<5)
#define CP_AI_CAP_FLY (1<<6)
#define CP_AI_CAP_COMBAT (1<<7)
#define CP_AI_CAP_REPAIR (1<<8)

// Cyberpunk city task types.
#define CP_AI_TASK_IDLE "idle"
#define CP_AI_TASK_PATROL "patrol"
#define CP_AI_TASK_WORK "work"
#define CP_AI_TASK_DELIVERY "delivery"
#define CP_AI_TASK_CONTRACT "contract"
#define CP_AI_TASK_CARGO "cargo"
#define CP_AI_TASK_GUARD "guard"
#define CP_AI_TASK_REPAIR "repair"
#define CP_AI_TASK_RETURN "return"
#define CP_AI_TASK_FLEE "flee"

// Cyberpunk city task states / route phases.
#define CP_AI_TASK_CREATED "created"
#define CP_AI_TASK_ROUTE_TO_SOURCE "route_to_source"
#define CP_AI_TASK_PICKUP "pickup"
#define CP_AI_TASK_ROUTE_TO_TARGET "route_to_target"
#define CP_AI_TASK_ROUTE_TO_Z_TRANSITION "route_to_z_transition"
#define CP_AI_TASK_USE_Z_TRANSITION "use_z_transition"
#define CP_AI_TASK_DROPOFF "dropoff"
#define CP_AI_TASK_WORKING "working"
#define CP_AI_TASK_RETURNING "returning"
#define CP_AI_TASK_COMPLETED "completed"
#define CP_AI_TASK_FAILED "failed"

// Cyberpunk cargo states.
#define CP_AI_CARGO_NONE "none"
#define CP_AI_CARGO_WAITING "waiting"
#define CP_AI_CARGO_CARRIED "carried"
#define CP_AI_CARGO_DELIVERED "delivered"
#define CP_AI_CARGO_LOST "lost"

// Cyberpunk phantom states.
#define CP_AI_PHANTOM_INACTIVE "inactive"
#define CP_AI_PHANTOM_TRAVELING "traveling"
#define CP_AI_PHANTOM_WORKING "working"
#define CP_AI_PHANTOM_WAITING "waiting"
#define CP_AI_PHANTOM_FAILED "failed"
#define CP_AI_PHANTOM_COMPLETED "completed"

// Cyberpunk phantom simulation profiles.
#define CP_AI_PHANTOM_PROFILE_LIGHT "light"
#define CP_AI_PHANTOM_PROFILE_HEAVY "heavy"

//Base Subtree defines

///This subtree should cancel any further planning, (Including from other subtrees)
#define SUBTREE_RETURN_FINISH_PLANNING 1

//Generic subtree defines

/// default search range (tiles, passed to oview) when using find_and_set
#define SEARCH_TACTIC_DEFAULT_RANGE 7
/// probability that the pawn should try resisting out of restraints
#define RESIST_SUBTREE_PROB 50
///macro for whether it's appropriate to resist right now, used by resist subtree
#define SHOULD_RESIST(source) (source.on_fire || source.buckled || HAS_TRAIT(source, TRAIT_RESTRAINED) || (source.pulledby && source.pulledby.grab_state > GRAB_PASSIVE))
///macro for whether the pawn can act, used generally to prevent some horrifying ai disasters
#define IS_DEAD_OR_INCAP(source) (source.incapacitated || source.stat)

GLOBAL_LIST_INIT(all_radial_directions, list(
	"NORTH" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH),
	"NORTHEAST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTHEAST),
	"EAST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = EAST),
	"SOUTHEAST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTHEAST),
	"SOUTH" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH),
	"SOUTHWEST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTHWEST),
	"WEST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = WEST),
	"NORTHWEST" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTHWEST)
))
