/datum/cy_skill_holder
	/// Usually a /mob/living, later can be a phantom NPC profile datum.
	var/datum/owner

	/// Stat storage used for stat-limited physical skills.
	var/datum/cy_stat_holder/stat_holder

	/// Assoc list: skill typepath = level.
	var/list/skill_levels = list()

/datum/cy_skill_holder/New(datum/new_owner, datum/cy_stat_holder/new_stat_holder)
	. = ..()
	owner = new_owner
	stat_holder = new_stat_holder

/datum/cy_skill_holder/Destroy()
	owner = null
	stat_holder = null
	skill_levels = null
	return ..()

/datum/cy_skill_holder/proc/is_valid_skill(skill_type)
	return ispath(skill_type, /datum/cy_skill)

/datum/cy_skill_holder/proc/get_skill_level(skill_type)
	if(!is_valid_skill(skill_type))
		return CY_SKILL_MINIMUM_LEVEL

	return skill_levels[skill_type] || CY_SKILL_MINIMUM_LEVEL

/datum/cy_skill_holder/proc/get_stat_limited_skill_total(stat_type, replacing_skill_type = null, replacing_level = null)
	var/datum/cy_stat/stat = get_cy_stat_datum(stat_type)
	if(!stat)
		return 0

	var/total = 0
	for(var/skill_type in stat.limited_skills)
		if(skill_type == replacing_skill_type)
			total += replacing_level
		else
			total += get_skill_level(skill_type)

	return total

/datum/cy_skill_holder/proc/can_set_skill_level(skill_type, level)
	if(!is_valid_skill(skill_type))
		return FALSE

	level = clamp(round(level), CY_SKILL_MINIMUM_LEVEL, CY_SKILL_MAXIMUM_LEVEL)

	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return FALSE

	if(!skill.limited_by_stat)
		return TRUE

	if(!skill.governing_stat)
		return TRUE

	if(!stat_holder)
		return FALSE

	var/stat_capacity = stat_holder.get_stat(skill.governing_stat)
	var/current_total = get_stat_limited_skill_total(skill.governing_stat, skill_type, level)

	return current_total <= stat_capacity

/datum/cy_skill_holder/proc/set_skill_level(skill_type, level, ignore_stat_limit = FALSE)
	if(!is_valid_skill(skill_type))
		return FALSE

	level = clamp(round(level), CY_SKILL_MINIMUM_LEVEL, CY_SKILL_MAXIMUM_LEVEL)

	if(!ignore_stat_limit && !can_set_skill_level(skill_type, level))
		return FALSE

	if(!level)
		skill_levels -= skill_type
	else
		skill_levels[skill_type] = level

	return TRUE

/datum/cy_skill_holder/proc/adjust_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	return set_skill_level(skill_type, get_skill_level(skill_type) + amount, ignore_stat_limit)

/datum/cy_skill_holder/proc/get_check_chance(stat_type, skill_type = null, difficulty = 0)
	if(!stat_holder)
		return CY_CHECK_MINIMUM_CHANCE

	var/stat_value = stat_holder.get_stat(stat_type)
	var/skill_level = skill_type ? get_skill_level(skill_type) : CY_SKILL_MINIMUM_LEVEL
	var/luck_value = stat_holder.get_stat(/datum/cy_stat/luck)

	var/chance = (stat_value * CY_STAT_VALUE_PER_POINT)
	chance += (skill_level * CY_SKILL_VALUE_PER_LEVEL)
	chance += (luck_value * CY_LUCK_PERCENT_PER_POINT)
	chance -= difficulty

	return clamp(round(chance), CY_CHECK_MINIMUM_CHANCE, CY_CHECK_MAXIMUM_CHANCE)
