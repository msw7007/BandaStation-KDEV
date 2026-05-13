/mob/living/proc/ensure_cy_stat_holder() as /datum/cy_stat_holder
	if(!cy_stat_holder)
		cy_stat_holder = new(src)

	return cy_stat_holder

/mob/living/proc/ensure_cy_skill_holder() as /datum/cy_skill_holder
	if(!cy_skill_holder)
		var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
		cy_skill_holder = new(src, stats)

	return cy_skill_holder

/mob/living/proc/get_cy_stat(stat_type, include_modifiers = TRUE)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_stat(stat_type, include_modifiers)

/mob/living/proc/get_cy_base_stat(stat_type)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_base_stat(stat_type)

/mob/living/proc/set_cy_base_stat(stat_type, value)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_base_stat(stat_type, value)

/mob/living/proc/adjust_cy_base_stat(stat_type, amount)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.adjust_base_stat(stat_type, amount)

/mob/living/proc/get_cy_stat_experience(stat_type)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_stat_experience(stat_type)

/mob/living/proc/adjust_cy_stat_experience(stat_type, amount, apply_level = TRUE)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.adjust_stat_experience(stat_type, amount, apply_level)

/mob/living/proc/set_cy_stat_modifier(stat_type, source, amount)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_stat_modifier(stat_type, source, amount)

/mob/living/proc/clear_cy_stat_modifier(stat_type, source)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.clear_stat_modifier(stat_type, source)

/mob/living/proc/get_cy_skill_level(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_level(skill_type)

/mob/living/proc/set_cy_skill_level(skill_type, level, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_level(skill_type, level, ignore_stat_limit)

/mob/living/proc/adjust_cy_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_skill_level(skill_type, amount, ignore_stat_limit)

/mob/living/proc/get_cy_skill_experience(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_experience(skill_type)

/mob/living/proc/set_cy_skill_experience(skill_type, experience, apply_level = TRUE, ignore_stat_limit = FALSE, auto_level_limit = CY_SKILL_AUTO_LEVEL_LIMIT)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_experience(skill_type, experience, apply_level, ignore_stat_limit, auto_level_limit)

/mob/living/proc/adjust_cy_skill_experience(skill_type, amount, apply_level = TRUE, ignore_stat_limit = FALSE, auto_level_limit = CY_SKILL_AUTO_LEVEL_LIMIT)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_skill_experience(skill_type, amount, apply_level, ignore_stat_limit, auto_level_limit)

/mob/living/proc/award_cy_raw_skill_experience(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.award_raw_skill_experience(skill_type, amount, ignore_stat_limit)

/mob/living/proc/adjust_cy_distributable_experience(amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_distributable_experience(amount)

/mob/living/proc/spend_cy_distributable_experience_on_skill(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.spend_distributable_experience_on_skill(skill_type, amount, ignore_stat_limit)

/mob/living/proc/process_cy_awake_training_experience(seconds_per_tick, mood_modifier = 1)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.process_awake_training_experience(seconds_per_tick, mood_modifier)

/mob/living/proc/set_cy_experience_multiplier(source, amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_experience_multiplier(source, amount)

/mob/living/proc/copy_cy_skill_progress_from(mob/living/source)
	if(!source)
		return FALSE
	var/datum/cy_skill_holder/source_skills = source.ensure_cy_skill_holder()
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.copy_progress_from(source_skills)

/mob/living/proc/get_cy_skill_perk_check_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_check_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_experience_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_experience_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_work_speed_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_work_speed_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_quality_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_quality_bonus(skill_type)

/mob/living/proc/get_cy_skill_speed_multiplier(skill_type)
	var/level_modifier = get_cy_skill_level(skill_type) * 0.08
	var/perk_modifier = get_cy_skill_perk_work_speed_bonus(skill_type) * 0.01
	return max(0.35, 1 - level_modifier - perk_modifier)

/mob/living/proc/get_cy_skill_probability_bonus(skill_type)
	return (get_cy_skill_level(skill_type) * CY_SKILL_VALUE_PER_LEVEL) + get_cy_skill_perk_check_bonus(skill_type)

/mob/living/proc/get_cy_skill_value_modifier(skill_type)
	return get_cy_skill_level(skill_type) + get_cy_skill_perk_quality_bonus(skill_type)

/mob/living/proc/get_cy_check_chance(stat_type, skill_type = null, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_check_chance(stat_type, skill_type, difficulty)

/mob/living/proc/get_cy_skill_check_chance(skill_type, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_check_chance(skill_type, difficulty)

/mob/living/proc/get_cy_skill_check_experience(skill_type, difficulty = 0, success = TRUE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_check_experience(skill_type, difficulty, success)

/mob/living/proc/award_cy_skill_check_experience(skill_type, difficulty = 0, success = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.award_skill_check_experience(skill_type, difficulty, success, ignore_stat_limit)

/mob/living/proc/perform_cy_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.perform_check(stat_type, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/perform_cy_skill_check(skill_type, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || !skill.governing_stat)
		return null
	return skills.perform_check(skill.governing_stat, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/roll_cy_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.roll_check(stat_type, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/roll_cy_skill_check(skill_type, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.roll_skill_check(skill_type, difficulty, grant_experience, ignore_stat_limit)
