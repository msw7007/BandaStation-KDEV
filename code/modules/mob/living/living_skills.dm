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
	if(stat_type == /datum/cy_stat/intelligence)
		var/intelligence_chance = get_cy_intelligence_success_chance() + (skill_level * CY_SKILL_VALUE_PER_LEVEL) + (luck_value * CY_LUCK_PERCENT_PER_POINT) - difficulty
		return clamp(round(intelligence_chance), CY_CHECK_MINIMUM_CHANCE, CY_CHECK_MAXIMUM_CHANCE)
	var/chance = (stat_value * CY_STAT_VALUE_PER_POINT) + (skill_level * CY_SKILL_VALUE_PER_LEVEL) + (luck_value * CY_LUCK_PERCENT_PER_POINT) - difficulty
	return clamp(round(chance), CY_CHECK_MINIMUM_CHANCE, CY_CHECK_MAXIMUM_CHANCE)

/proc/cy_hyperbola_value(value, x1, y1, x2, y2, x3, y3, minimum = -INFINITY, maximum = INFINITY)
	value = max(0.1, value)
	var/delta_21 = x2 - x1
	var/delta_32 = x3 - x2
	var/rise_21 = y2 - y1
	var/rise_32 = y3 - y2
	if(!delta_21 || !delta_32 || !rise_32)
		return clamp(y2, minimum, maximum)
	var/ratio = rise_21 / rise_32
	var/denominator = ratio * delta_32 - delta_21
	if(!denominator)
		return clamp(y2, minimum, maximum)
	var/offset = (delta_21 * x3 - ratio * delta_32 * x1) / denominator
	var/amplitude = rise_21 * (x1 + offset) * (x2 + offset) / delta_21
	var/limit = y1 + amplitude / (x1 + offset)
	return clamp(limit - amplitude / (value + offset), minimum, maximum)

/mob/living/proc/get_cy_stat_zone_accuracy()
	return round(cy_hyperbola_value(get_cy_stat(/datum/cy_stat/perception), 1, 1, 12, 75, 20, 99, 1, 99))

/mob/living/proc/get_cy_strength_melee_damage_multiplier()
	return cy_hyperbola_value(get_cy_stat(/datum/cy_stat/strength), 1, 0.75, 12, 1.25, 20, 1.75, 0.5, 2)

/mob/living/proc/get_cy_dexterity_action_delay_multiplier()
	return cy_hyperbola_value(get_cy_stat(/datum/cy_stat/dexterity), 1, 1.5, 12, 1, 20, 0.5, 0.35, 2)

/mob/living/proc/get_cy_intelligence_success_chance()
	return round(cy_hyperbola_value(get_cy_stat(/datum/cy_stat/intelligence), 1, 10, 12, 100, 20, 120, 1, 100))

/mob/living/proc/get_cy_intelligence_action_delay_multiplier()
	var/intelligence = get_cy_stat(/datum/cy_stat/intelligence)
	if(intelligence <= 12)
		return 1
	return cy_hyperbola_value(intelligence, 12, 1, 16, 0.75, 20, 0.5, 0.35, 1)

/mob/living/proc/get_cy_spirit_resistance_percent()
	return round(cy_hyperbola_value(get_cy_stat(/datum/cy_stat/spirit), 1, 1, 12, 50, 20, 75, 0, 75))

/mob/living/proc/get_cy_spirit_effect_multiplier()
	return 1 - (get_cy_spirit_resistance_percent() * 0.01)

/mob/living/proc/get_cy_charisma_bonus_chance()
	return round(cy_hyperbola_value(get_cy_stat(/datum/cy_stat/charisma), 1, 1, 12, 30, 20, 40, 1, 40))

/mob/living/proc/get_cy_charisma_check_bonus()
	return prob(get_cy_charisma_bonus_chance()) ? 10 : 0

/mob/living/proc/get_cy_aimed_hit_zone(mob/living/carbon/target, base_zone, list/blacklisted_parts)
	if(!istype(target))
		return base_zone
	if(!islist(blacklisted_parts))
		blacklisted_parts = list()

	var/checked_zone = check_zone(base_zone)
	if(checked_zone && !(checked_zone in blacklisted_parts) && target.get_bodypart(checked_zone) && prob(get_cy_stat_zone_accuracy()))
		return checked_zone

	return target.get_random_valid_zone(null, blacklisted_parts = blacklisted_parts)

/mob/living/proc/perform_cy_skill_check(skill_type, difficulty, experience_modifier = 1)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || isnull(difficulty))
		return FALSE

	var/success = TRUE
	if(!skill.governing_stat)
		return FALSE
	var/check_chance = get_cy_check_chance(skill.governing_stat, skill_type, difficulty)
	if(skill.governing_stat == /datum/cy_stat/charisma)
		check_chance += get_cy_charisma_check_bonus()
	success = prob(check_chance)
	award_cy_raw_skill_experience(skill_type, max(0, difficulty), experience_modifier)
	return success

/mob/living/proc/perform_cy_random_skill_check(list/skill_types, difficulty, experience_modifier = 1)
	if(!length(skill_types))
		return FALSE

	var/list/valid_skill_types = list()
	for(var/skill_type in skill_types)
		if(get_cy_skill_datum(skill_type))
			valid_skill_types += skill_type

	if(!length(valid_skill_types))
		return FALSE

	return perform_cy_skill_check(pick(valid_skill_types), difficulty, experience_modifier)
