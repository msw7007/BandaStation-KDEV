/datum/cy_skill_check_result
	var/success = FALSE
	var/chance = CY_CHECK_MINIMUM_CHANCE
	var/experience_awarded = 0
	var/difficulty = 0
	var/stat_type
	var/skill_type

/datum/cy_skill_holder
	/// Usually a /mob/living, later can be a phantom NPC profile datum.
	var/datum/owner

	/// Stat storage used for stat-limited physical skills.
	var/datum/cy_stat_holder/stat_holder

	/// Assoc list: skill typepath = level.
	var/list/skill_levels = list()

	/// Assoc list: skill typepath = stored experience.
	var/list/skill_experience = list()

	/// Assoc list: skill typepath = list(perk typepath = perk datum instance).
	var/list/granted_skill_perks = list()

/datum/cy_skill_holder/New(datum/new_owner, datum/cy_stat_holder/new_stat_holder)
	. = ..()
	owner = new_owner
	stat_holder = new_stat_holder

/datum/cy_skill_holder/Destroy()
	owner = null
	stat_holder = null
	skill_levels = null
	skill_experience = null
	if(granted_skill_perks)
		for(var/skill_type in granted_skill_perks)
			var/list/skill_perks = granted_skill_perks[skill_type]
			if(!islist(skill_perks))
				continue
			QDEL_LIST(skill_perks)
		granted_skill_perks.Cut()
	granted_skill_perks = null
	return ..()

/datum/cy_skill_holder/proc/is_valid_skill(skill_type)
	return ispath(skill_type, /datum/cy_skill)

/datum/cy_skill_holder/proc/get_skill_level(skill_type)
	if(!is_valid_skill(skill_type))
		return CY_SKILL_MINIMUM_LEVEL

	return skill_levels[skill_type] || CY_SKILL_MINIMUM_LEVEL

/datum/cy_skill_holder/proc/get_skill_max_level(skill_type)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return CY_SKILL_MINIMUM_LEVEL

	return skill.max_level

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

	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return FALSE

	level = clamp(round(level), CY_SKILL_MINIMUM_LEVEL, skill.max_level)

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

	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return FALSE

	level = clamp(round(level), CY_SKILL_MINIMUM_LEVEL, skill.max_level)

	if(!ignore_stat_limit && !can_set_skill_level(skill_type, level))
		return FALSE

	var/old_level = get_skill_level(skill_type)
	if(old_level == level)
		return TRUE

	if(!level)
		skill_levels -= skill_type
	else
		skill_levels[skill_type] = level

	sync_skill_experience_to_level(skill_type, level)
	refresh_skill_perks(skill_type, old_level, level)
	return TRUE

/datum/cy_skill_holder/proc/adjust_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	return set_skill_level(skill_type, get_skill_level(skill_type) + amount, ignore_stat_limit)

/datum/cy_skill_holder/proc/sync_skill_experience_to_level(skill_type, level)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return

	var/current_experience = get_skill_experience(skill_type)
	var/minimum_experience = level * CY_SKILL_EXPERIENCE_PER_LEVEL
	var/maximum_experience = ((level + 1) * CY_SKILL_EXPERIENCE_PER_LEVEL) - 1
	if(level >= skill.max_level)
		maximum_experience = INFINITY

	if(current_experience < minimum_experience)
		skill_experience[skill_type] = minimum_experience
	else if(current_experience > maximum_experience)
		skill_experience[skill_type] = maximum_experience

/datum/cy_skill_holder/proc/get_skill_experience(skill_type)
	if(!is_valid_skill(skill_type))
		return 0

	return skill_experience[skill_type] || 0

/datum/cy_skill_holder/proc/get_skill_level_from_experience(skill_type, experience)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return CY_SKILL_MINIMUM_LEVEL

	var/level = round(experience / CY_SKILL_EXPERIENCE_PER_LEVEL)
	if(level * CY_SKILL_EXPERIENCE_PER_LEVEL > experience)
		level--

	return clamp(level, CY_SKILL_MINIMUM_LEVEL, skill.max_level)

/datum/cy_skill_holder/proc/set_skill_experience(skill_type, experience, apply_level = TRUE, ignore_stat_limit = FALSE)
	if(!is_valid_skill(skill_type))
		return FALSE

	experience = max(0, round(experience))
	if(!experience)
		skill_experience -= skill_type
	else
		skill_experience[skill_type] = experience

	if(apply_level)
		set_skill_level(skill_type, get_skill_level_from_experience(skill_type, experience), ignore_stat_limit)

	return TRUE

/datum/cy_skill_holder/proc/adjust_skill_experience(skill_type, amount, apply_level = TRUE, ignore_stat_limit = FALSE)
	return set_skill_experience(skill_type, get_skill_experience(skill_type) + amount, apply_level, ignore_stat_limit)

/datum/cy_skill_holder/proc/get_check_chance(stat_type, skill_type = null, difficulty = 0)
	if(!stat_holder)
		return CY_CHECK_MINIMUM_CHANCE

	var/stat_value = stat_holder.get_stat(stat_type)
	var/skill_level = skill_type ? get_skill_level(skill_type) : CY_SKILL_MINIMUM_LEVEL
	var/luck_value = stat_holder.get_stat(/datum/cy_stat/luck)

	var/chance = (stat_value * CY_STAT_VALUE_PER_POINT)
	chance += (skill_level * CY_SKILL_VALUE_PER_LEVEL)
	chance += (luck_value * CY_LUCK_PERCENT_PER_POINT)
	if(skill_type)
		chance = modify_check_chance_by_perks(skill_type, chance)
	chance -= difficulty

	return clamp(round(chance), CY_CHECK_MINIMUM_CHANCE, CY_CHECK_MAXIMUM_CHANCE)

/datum/cy_skill_holder/proc/get_skill_check_chance(skill_type, difficulty = 0)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || !skill.governing_stat)
		return CY_CHECK_MINIMUM_CHANCE

	return get_check_chance(skill.governing_stat, skill_type, difficulty)

/datum/cy_skill_holder/proc/get_skill_check_experience(skill_type, difficulty = 0, success = TRUE)
	if(!is_valid_skill(skill_type))
		return 0

	var/base_experience = CY_SKILL_CHECK_EXPERIENCE_BASE + max(0, round(difficulty / CY_SKILL_CHECK_EXPERIENCE_DIFFICULTY_DIVISOR))
	base_experience *= success ? CY_SKILL_CHECK_EXPERIENCE_SUCCESS_MULTIPLIER : CY_SKILL_CHECK_EXPERIENCE_FAILURE_MULTIPLIER
	base_experience = modify_experience_gain_by_perks(skill_type, base_experience)

	return max(1, round(base_experience))

/datum/cy_skill_holder/proc/award_skill_check_experience(skill_type, difficulty = 0, success = TRUE, ignore_stat_limit = FALSE)
	var/experience = get_skill_check_experience(skill_type, difficulty, success)
	if(!experience)
		return 0

	if(!adjust_skill_experience(skill_type, experience, TRUE, ignore_stat_limit))
		return 0

	return experience

/datum/cy_skill_holder/proc/perform_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_check_result/result = new
	result.stat_type = stat_type
	result.skill_type = skill_type
	result.difficulty = difficulty
	result.chance = get_check_chance(stat_type, skill_type, difficulty)
	result.success = prob(result.chance)
	if(grant_experience && skill_type)
		result.experience_awarded = award_skill_check_experience(skill_type, difficulty, result.success, ignore_stat_limit)

	return result

/datum/cy_skill_holder/proc/roll_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_check_result/result = perform_check(stat_type, skill_type, difficulty, grant_experience, ignore_stat_limit)
	return result.success

/datum/cy_skill_holder/proc/roll_skill_check(skill_type, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || !skill.governing_stat)
		return FALSE

	return roll_check(skill.governing_stat, skill_type, difficulty, grant_experience, ignore_stat_limit)

/datum/cy_skill_holder/proc/get_granted_perk_list(skill_type)
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!perk_list)
		perk_list = list()
		granted_skill_perks[skill_type] = perk_list

	return perk_list

/datum/cy_skill_holder/proc/get_skill_perk_check_bonus(skill_type)
	var/bonus = 0
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return bonus
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		bonus += perk.check_bonus

	return bonus

/datum/cy_skill_holder/proc/modify_check_chance_by_perks(skill_type, chance)
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return chance
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		chance = perk.modify_check_chance(chance)

	return chance

/datum/cy_skill_holder/proc/get_skill_perk_experience_bonus(skill_type)
	var/bonus = 0
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return bonus
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		bonus += perk.experience_bonus

	return bonus

/datum/cy_skill_holder/proc/modify_experience_gain_by_perks(skill_type, experience)
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return experience
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		experience = perk.modify_experience_gain(experience)

	return experience

/datum/cy_skill_holder/proc/get_skill_perk_work_speed_bonus(skill_type)
	var/bonus = 0
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return bonus
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		bonus = perk.modify_work_speed_modifier(bonus)

	return bonus

/datum/cy_skill_holder/proc/get_skill_perk_quality_bonus(skill_type)
	var/bonus = 0
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return bonus
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		bonus = perk.modify_quality_modifier(bonus)

	return bonus

/datum/cy_skill_holder/proc/grant_skill_perk(skill_type, perk_type)
	if(!is_valid_skill(skill_type) || !ispath(perk_type, /datum/cy_skill_perk))
		return FALSE

	var/list/perk_list = get_granted_perk_list(skill_type)
	if(perk_list[perk_type])
		return FALSE

	var/datum/cy_skill_perk/perk = new perk_type
	perk.skill_type = skill_type
	perk_list[perk_type] = perk

	if(isliving(owner))
		perk.on_gain(owner)

	return TRUE

/datum/cy_skill_holder/proc/remove_skill_perk(skill_type, perk_type)
	if(!is_valid_skill(skill_type) || !ispath(perk_type, /datum/cy_skill_perk))
		return FALSE

	var/list/perk_list = granted_skill_perks[skill_type]
	if(!perk_list)
		return FALSE

	var/datum/cy_skill_perk/perk = perk_list[perk_type]
	if(!perk)
		return FALSE

	if(isliving(owner))
		perk.on_loss(owner)

	perk_list -= perk_type
	qdel(perk)
	return TRUE

/datum/cy_skill_holder/proc/refresh_skill_perks(skill_type, old_level, new_level)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return

	if(new_level > old_level)
		for(var/current_level in (old_level + 1) to new_level)
			for(var/perk_type in skill.get_perks_for_level(current_level))
				grant_skill_perk(skill_type, perk_type)
		return

	if(new_level < old_level)
		for(var/current_level in old_level to (new_level + 1) step -1)
			for(var/perk_type in skill.get_perks_for_level(current_level))
				remove_skill_perk(skill_type, perk_type)
