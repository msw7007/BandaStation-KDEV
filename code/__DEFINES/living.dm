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

// Used in living mob offset list for determining pixel offsets
#define PIXEL_W_OFFSET "w"
#define PIXEL_X_OFFSET "x"
#define PIXEL_Y_OFFSET "y"
#define PIXEL_Z_OFFSET "z"

/// CyberPunk actor stat bounds.
#define CY_STAT_MINIMUM 1
#define CY_STAT_MAXIMUM 20
#define CY_STAT_DEFAULT 5

/// Check math from the character design block.
#define CY_STAT_VALUE_PER_POINT 5
#define CY_SKILL_VALUE_PER_LEVEL 10
#define CY_LUCK_PERCENT_PER_POINT 2.5

#define CY_CHECK_MINIMUM_CHANCE 1
#define CY_CHECK_MAXIMUM_CHANCE 99

#define CY_SKILL_MINIMUM_LEVEL 0
#define CY_SKILL_MAXIMUM_LEVEL 6

#define CY_SKILL_LEVEL_UNTRAINED 0
#define CY_SKILL_LEVEL_BEGINNER 1
#define CY_SKILL_LEVEL_SKILLED 2
#define CY_SKILL_LEVEL_TRAINED 3
#define CY_SKILL_LEVEL_EXPERT 4
#define CY_SKILL_LEVEL_PROFESSIONAL 5
#define CY_SKILL_LEVEL_MASTER 6

#define CY_SKILL_EXPERIENCE_PER_LEVEL 100
