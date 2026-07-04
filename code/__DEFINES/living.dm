// living_flags
/// Simple mob trait, indicating it may follow continuous move actions controlled by code instead of by user input.
#define MOVES_ON_ITS_OWN (1<<0)
/// Always does *deathgasp when they die
/// If unset mobs will only deathgasp if supplied a death sound or custom death message
#define ALWAYS_DEATHGASP (1<<1)
/**
 * For carbons, this stops bodypart overlays being added to bodyparts from calling mob.update_body_parts().
 * This is useful for situations like initialization or species changes, where
 * update_body_parts() is going to be called ONE time once everything is done.
 */
#define STOP_OVERLAY_UPDATE_BODY_PARTS (1<<2)
/// Nutrition changed last life tick, so we should bulk update this tick
#define QUEUE_NUTRITION_UPDATE (1<<3)
/// Blood volume or status has changed since the last [proc/update_blood_effects] call.
/// Nowhere near guaranteed to happen only once per life tick, or at all.
#define BLOOD_UPDATE_QUEUED (1<<4)
/// This mob can have blood, cached value of [proc/can_have_blood]
#define LIVING_CAN_HAVE_BLOOD (1<<5)

/// Getter for a mob/living's lying angle, otherwise protected
#define GET_LYING_ANGLE(mob) (UNLINT(mob.lying_angle))
/// Checks if the mob can have blood
#define CAN_HAVE_BLOOD(mob) (mob.living_flags & LIVING_CAN_HAVE_BLOOD)
/// Queues a blood update for the next life tick for the mob
#define QUEUE_BLOOD_UPDATE(mob) mob.living_flags |= BLOOD_UPDATE_QUEUED

// Core living resource defaults and costs.
#define STAMINA_DEFAULT 100
#define ENERGY_POOL_DEFAULT 100
#define NEED_LEVEL_DEFAULT 350
#define TIRENESS_DEFAULT 450
#define CHROMITY_DEFAULT 50
#define CHROMITY_OVERHEAT_DEFAULT 0
#define CHROMITY_OVERHEAT_DECAY 1

#define STEALTH_CHAMELEON_MAX 100
#define STEALTH_CHAMELEON_HIDDEN_CAP 99
#define STEALTH_CHAMELEON_FADE_RATE 8
#define STEALTH_CHAMELEON_LIGHT_RATE 14
#define STEALTH_ALPHA_MINIMUM 35
#define STEALTH_ALPHA_MAXIMUM 190
#define STEALTH_SOUND_MUTE_THRESHOLD 70
#define STEALTH_BASE_EQUIPMENT_WEIGHT_LIMIT 16
#define STEALTH_DAMAGE_MULTIPLIER_MIN 1.1
#define STEALTH_DAMAGE_MULTIPLIER_MAX 1.5
#define WALL_HUG_CHAMELEON_BONUS 20
#define WALL_HUG_SLOWDOWN 0.5
#define WALL_HUG_ENERGY_RECOVERY 1

#define HEARING_WALL_SPEECH_RANGE 10
#define HEARING_WALL_WHISPER_RANGE 4
#define LISTEN_NORMAL_WALL_RANGE 10
#define LISTEN_WHISPER_WALL_RANGE 3
#define LISTEN_WHISPER_OPEN_RANGE 6
#define LISTEN_HEARING_QUIRK_BONUS 2
#define LISTEN_HEARING_QUIRK_INTENT_BONUS 5
#define HEARING_OTHER_Z_RANGE 6
#define SPEECH_HEARING_NONE 0
#define SPEECH_HEARING_CLEAR 1
#define SPEECH_HEARING_MUFFLED 2

#define FOCUS_LOOK_MAX_TILES 6
#define FOCUS_LOOK_PIXEL_MULTIPLIER 32

#define STAMINA_COST_PROGRESS_TICK 5
#define STAMINA_COST_JUMP 10
#define STAMINA_COST_DODGE 5
#define STAMINA_COST_PARRY 3
#define STAMINA_COST_ATTACK 3
#define STAMINA_COST_RUN_TILE 3
#define STAMINA_REGEN_DELAY (10 SECONDS)
#define STAMINA_REGEN_INTERVAL 4
#define STAMINA_REGEN_AMOUNT 5
#define STAMINA_ENERGY_RESERVE_COST 1
#define STAMINA_ENERGY_RESERVE_RECOVERY 10
#define ENERGY_POOL_RECOVERY_INTERVAL 5
#define ENERGY_POOL_WALL_HUG_INTERVAL 10
#define STAMINA_SPEND_XP_MULTIPLIER 0.5
#define BODY_STYLE_UPDATE_INTERVAL 10
#define CYBERPSYCHOSIS_OVERHEAT_RATIO 1
#define CYBERPSYCHOSIS_MIN_MOOD -30
#define CYBERPSYCHOSIS_COOLDOWN (1 MINUTES)
#define CYBERPSYCHOSIS_DURATION (10 MINUTES)
#define CYBERPSYCHOSIS_ATTRIBUTE_TARGET 15
#define CYBERPSYCHOSIS_AI_TICK (0.5 SECONDS)
#define CYBERPSYCHOSIS_IMPLANT_TICK (1 SECONDS)
#define CYBERPSYCHOSIS_VIEW_RANGE 7
#define HYSTERIA_RANDOM_WALK_DURATION (20 SECONDS)
#define HYSTERIA_RANDOM_WALK_TICK (0.5 SECONDS)
#define STAMINA_LOW_RUN_THRESHOLD 0.1
#define STAMINA_LOW_RUN_SLOWDOWN 0.25
#define STAMINA_JUMP_COLLISION_KNOCKDOWN (2 SECONDS)
#define STAMINA_SPRINT_BREATHLESS_TIME (5 SECONDS)
#define STAMINA_SPRINT_COLLISION_KNOCKDOWN (3 SECONDS)
#define STAMINA_SPRINT_RESERVE_KNOCKDOWN (8 SECONDS)

#define BODY_STATE_TRAIT "body_state"
#define CYBERPSYCHOSIS_TRAIT "cyberpsychosis"
#define HYSTERIA_TRAIT "hysteria"

// Used in living mob offset list for determining pixel offsets
#define PIXEL_W_OFFSET "w"
#define PIXEL_X_OFFSET "x"
#define PIXEL_Y_OFFSET "y"
#define PIXEL_Z_OFFSET "z"
