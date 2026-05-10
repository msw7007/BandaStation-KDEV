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

/mob/living/proc/get_cy_check_chance(stat_type, skill_type = null, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_check_chance(stat_type, skill_type, difficulty)

/mob/living/proc/get_cy_skill_check_chance(skill_type, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_check_chance(skill_type, difficulty)
