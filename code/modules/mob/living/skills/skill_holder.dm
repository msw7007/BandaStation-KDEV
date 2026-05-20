/datum/cy_skill_holder
	/// Usually a /mob/living, later can be a phantom NPC profile datum.
	var/datum/owner

	/// Stat storage used for stat-limited physical skills.
	var/datum/cy_stat_holder/stat_holder

	/// Assoc list: skill typepath = level.
	var/list/skill_levels = list()

	/// Assoc list: skill typepath = stored experience.
	var/list/skill_experience = list()

	/// Assoc list: skill typepath = highest level digested through comfortable sleep.
	var/list/skill_level_gates = list()

	/// General character experience converted into character levels during comfortable sleep.
	var/general_experience = 0

	/// Character level. Visible to admins only.
	var/character_level = 1

	/// Points spent to raise characteristics.
	var/stat_points = 0

	/// Points spent to raise skills. Kept under the old var name for compatibility.
	var/distributable_experience = 0

	/// Decisecond accumulator for passive awake training experience.
	var/awake_training_experience_timer = 0

	/// Assoc list of temporary experience multipliers keyed by source.
	var/list/experience_multiplier_reasons = list()

	/// Assoc list: skill typepath = list(perk typepath = perk datum instance).
	var/list/granted_skill_perks = list()

/datum/cy_skill_holder/New(datum/new_owner, datum/cy_stat_holder/new_stat_holder)
	. = ..()
	owner = new_owner
	stat_holder = new_stat_holder

/datum/cy_skill_holder/Destroy()
	clear_skill_perks()
	owner = null
	stat_holder = null
	skill_levels = null
	skill_experience = null
	skill_level_gates = null
	general_experience = 0
	character_level = 0
	stat_points = 0
	experience_multiplier_reasons = null
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
	skill_level_gates[skill_type] = max(skill_level_gates[skill_type] || level, level)

	var/minimum_experience = get_total_experience_for_level(level)
	if(get_skill_experience(skill_type) < minimum_experience)
		skill_experience[skill_type] = minimum_experience
	refresh_skill_perks(skill_type, old_level, level)
	return TRUE

/datum/cy_skill_holder/proc/adjust_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	return set_skill_level(skill_type, get_skill_level(skill_type) + amount, ignore_stat_limit)

/datum/cy_skill_holder/proc/copy_progress_from(datum/cy_skill_holder/source)
	if(!source)
		return FALSE

	clear_skill_perks()

	skill_levels = source.skill_levels?.Copy() || list()
	skill_experience = source.skill_experience?.Copy() || list()
	skill_level_gates = source.skill_level_gates?.Copy() || list()
	general_experience = source.general_experience
	character_level = source.character_level
	stat_points = source.stat_points
	distributable_experience = source.distributable_experience
	awake_training_experience_timer = source.awake_training_experience_timer
	for(var/skill_type in skill_levels)
		refresh_skill_perks(skill_type, CY_SKILL_MINIMUM_LEVEL, skill_levels[skill_type])
	return TRUE
