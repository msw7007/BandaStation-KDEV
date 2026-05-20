/mob/living/proc/ensure_cy_skill_holder() as /datum/cy_skill_holder
	if(!cy_skill_holder)
		var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
		cy_skill_holder = new(src, stats)

	return cy_skill_holder

/mob/living/proc/get_cy_skill_level(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_level(skill_type)

/mob/living/proc/set_cy_skill_level(skill_type, level, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_level(skill_type, level, ignore_stat_limit)

/mob/living/proc/adjust_cy_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_skill_level(skill_type, amount, ignore_stat_limit)

/mob/living/proc/copy_cy_skill_progress_from(mob/living/source)
	if(!source)
		return FALSE
	var/datum/cy_skill_holder/source_skills = source.ensure_cy_skill_holder()
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.copy_progress_from(source_skills)

/mob/living/proc/get_cy_check_chance(stat_type, skill_type = null, difficulty = 0)
	var/stat_value = get_cy_stat(stat_type)
	var/skill_level = skill_type ? get_cy_skill_level(skill_type) : CY_SKILL_MINIMUM_LEVEL
	var/luck_value = get_cy_stat(/datum/cy_stat/luck)
	var/chance = (stat_value * CY_STAT_VALUE_PER_POINT) + (skill_level * CY_SKILL_VALUE_PER_LEVEL) + (luck_value * CY_LUCK_PERCENT_PER_POINT) - difficulty
	if(skill_type)
		chance += get_cy_skill_perk_check_bonus(skill_type)
	return clamp(round(chance), CY_CHECK_MINIMUM_CHANCE, CY_CHECK_MAXIMUM_CHANCE)

/mob/living/proc/perform_cy_skill_check(skill_type, difficulty, experience_modifier = 1)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || isnull(difficulty))
		return FALSE

	var/success = TRUE
	if(!skill.governing_stat)
		return FALSE
	success = prob(get_cy_check_chance(skill.governing_stat, skill_type, difficulty))
	award_cy_raw_skill_experience(skill_type, max(0, difficulty), experience_modifier)
	return success
