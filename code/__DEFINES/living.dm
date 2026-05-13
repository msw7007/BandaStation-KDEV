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
#define CY_SKILL_EXPERIENCE_PER_LEVEL 50

#define CY_SKILL_LEVEL_UNTRAINED 0
#define CY_SKILL_LEVEL_BEGINNER 1
#define CY_SKILL_LEVEL_SKILLED 2
#define CY_SKILL_LEVEL_TRAINED 3
#define CY_SKILL_LEVEL_EXPERT 4
#define CY_SKILL_LEVEL_PROFESSIONAL 5
#define CY_SKILL_LEVEL_MASTER 6

#define CY_EXPERIENCE_THRESHOLD_BASE 100
#define CY_EXPERIENCE_THRESHOLD_PER_LEVEL 50
#define CY_SKILL_AUTO_LEVEL_LIMIT 2
#define CY_SKILL_CHECK_EXPERIENCE_BASE 5
#define CY_SKILL_CHECK_EXPERIENCE_DIFFICULTY_DIVISOR 10
#define CY_SKILL_CHECK_EXPERIENCE_SUCCESS_MULTIPLIER 1
#define CY_SKILL_CHECK_EXPERIENCE_FAILURE_MULTIPLIER 0.5
#define CY_SKILL_EXPERIENCE_SHARE 0.75
#define CY_STAT_EXPERIENCE_SHARE 0.25
#define CY_AWAKE_TRAINING_EXPERIENCE_INTERVAL (5 MINUTES)
#define CY_AWAKE_TRAINING_EXPERIENCE_AMOUNT 1
#define CY_NEED_STAGE_LOW 1
#define CY_NEED_STAGE_CRITICAL 2
#define CY_NEED_STAGE_EMPTY 3
#define CY_MOOD_MINIMUM -15
#define CY_MOOD_MAXIMUM 15
#define CY_MOOD_STAT_STEP 5
#define CY_MOOD_NEGATIVE_SLOWDOWN_PER_STEP 0.25
#define CY_MOOD_POSITIVE_ACTIONSPEED_PER_STEP -0.15
#define CY_SKILL_PERK_CHECK_BONUS_PER_LEVEL 2
#define CY_SKILL_PERK_EXPERIENCE_BONUS_PER_LEVEL 5
#define CY_SKILL_PERK_WORK_SPEED_BONUS_PER_LEVEL 1
#define CY_SKILL_PERK_QUALITY_BONUS_PER_LEVEL 1
#define CY_CLEANING_BEAUTY_EXPERIENCE_ADJUSTMENT -15
#define CY_CLEANING_GENERIC_WASH_EXPERIENCE 1.5
#define CY_FISHING_DIFFICULTY_EXPERIENCE_MULTIPLIER 0.015
#define CY_FISHING_EXPERIENCE_PER_SECOND (CY_EXPERIENCE_THRESHOLD_BASE * 25 / (15 MINUTES * 0.1))
#define CY_MINING_BOULDER_SIZE_EXPERIENCE 10
#define CY_ATHLETICS_MISC_EXPERIENCE 5

#define CY_WEAPON_SKILL_DAMAGE_PER_LEVEL 0.10
#define CY_WEAPON_SKILL_COOLDOWN_PER_LEVEL 0.05
#define CY_WEAPON_SKILL_DEFENSE_BYPASS_PER_LEVEL 5
#define CY_DEFAULT_FOV_DEGREES 100
#define CY_STEALTH_CHAMELEON_MAX 100
#define CY_STEALTH_LIGHT_PENALTY_MAX 45
#define CY_STEALTH_MOVE_PENALTY 15
#define CY_STEALTH_WEIGHT_PENALTY_PER_CLASS 4
#define CY_STEALTH_ATTACK_DAMAGE_BONUS 0.25
#define CY_OUT_OF_FOV_DAMAGE_BONUS 0.20
#define CY_HEALTH_CRIT_THRESHOLD 0
#define CY_HEALTH_CLINICAL_DEATH_THRESHOLD -100
#define CY_HEALTH_FINAL_DEATH_THRESHOLD -200
#define CY_CLINICAL_ORGAN_DAMAGE_PER_SECOND 0.25
#define CY_IMPLANT_OVERHEAT_DECAY_PER_SECOND 1
#define CY_IMPLANT_OVERHEAT_PSYCHIC_PER_SECOND 0.1
#define CY_IMPLANT_OVERHEAT_PAIN_PER_SECOND 0.05
#define CY_IMPLANT_CORP_MISMATCH_OVERHEAT_MULTIPLIER 1.5
#define CY_IMPLANT_CORP_MISMATCH_FAILURE_MODIFIER 10
#define CY_DAEMON_CORP_MISMATCH_CAST_MULTIPLIER 1.35
#define CY_DAEMON_CORP_MISMATCH_EFFECTIVENESS_MULTIPLIER 0.75

// Skillchip categories are not part of the removed legacy skill subsystem.
#define SKILLCHIP_CATEGORY_GENERAL "general"
#define SKILLCHIP_CATEGORY_JOB "job"

// Cyberpunk character compatibility aliases used by older integration callsites.
#ifndef CY_MOOD_VALUE_PER_LEVEL
#define CY_MOOD_VALUE_PER_LEVEL CY_MOOD_STAT_STEP
#endif
#ifndef CY_MOOD_LUCK_PER_STEP
#define CY_MOOD_LUCK_PER_STEP 1
#endif
#ifndef CY_MOOD_NEGATIVE_SPEED_PER_STEP
#define CY_MOOD_NEGATIVE_SPEED_PER_STEP CY_MOOD_NEGATIVE_SLOWDOWN_PER_STEP
#endif
#ifndef CY_PAIN_THRESHOLD
#define CY_PAIN_THRESHOLD 200
#endif
#ifndef CY_PAIN_MOVESPEED_DIVISOR
#define CY_PAIN_MOVESPEED_DIVISOR 150
#endif
#ifndef CY_PAIN_ACTIONSPEED_DIVISOR
#define CY_PAIN_ACTIONSPEED_DIVISOR 200
#endif
#ifndef CY_PAIN_MAX_MOVESPEED_SLOWDOWN
#define CY_PAIN_MAX_MOVESPEED_SLOWDOWN 3
#endif
#ifndef CY_PAIN_MAX_ACTIONSPEED_SLOWDOWN
#define CY_PAIN_MAX_ACTIONSPEED_SLOWDOWN 2
#endif

