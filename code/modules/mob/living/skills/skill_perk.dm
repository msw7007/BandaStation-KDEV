/datum/cy_skill_perk
	/// Player-facing name.
	var/name = "Unknown perk"

	/// Short machine-readable id for logs/save/UI.
	var/id = "unknown"

	/// Description for later UI.
	var/desc = ""

	/// Skill level this perk belongs to.
	var/level = CY_SKILL_LEVEL_UNTRAINED

	/// Skill typepath this perk belongs to. Optional, but useful for UI/logs.
	var/skill_type = null

	/// Percent bonus this perk contributes to checks for its skill.
	var/check_bonus = 0

	/// Percent bonus this perk contributes to future skill experience gains.
	var/experience_bonus = 0

	/// Percent bonus this perk contributes to work/crafting/action speed.
	var/work_speed_bonus = 0

	/// Percent bonus this perk contributes to result quality/reliability.
	var/quality_bonus = 0

/datum/cy_skill_perk/proc/on_gain(mob/living/owner)
	return

/datum/cy_skill_perk/proc/on_loss(mob/living/owner)
	return

/datum/cy_skill_perk/proc/modify_check_chance(chance)
	return chance + check_bonus

/datum/cy_skill_perk/proc/modify_experience_gain(experience)
	return experience * (1 + (experience_bonus / 100))

/datum/cy_skill_perk/proc/modify_work_speed_modifier(modifier)
	return modifier + work_speed_bonus

/datum/cy_skill_perk/proc/modify_quality_modifier(modifier)
	return modifier + quality_bonus

/datum/cy_skill_perk/proc/get_effect_summary()
	var/list/parts = list()
	if(check_bonus)
		parts += "+[check_bonus]% skill checks"
	if(experience_bonus)
		parts += "+[experience_bonus]% skill experience"
	if(work_speed_bonus)
		parts += "+[work_speed_bonus]% work speed"
	if(quality_bonus)
		parts += "+[quality_bonus]% result quality"

	if(!length(parts))
		return "Unlocks the next skill rank."

	return english_list(parts)

/proc/cy_generic_skill_perk_for_level(level)
	switch(level)
		if(1)
			return /datum/cy_skill_perk/generic/level_1
		if(2)
			return /datum/cy_skill_perk/generic/level_2
		if(3)
			return /datum/cy_skill_perk/generic/level_3
		if(4)
			return /datum/cy_skill_perk/generic/level_4
		if(5)
			return /datum/cy_skill_perk/generic/level_5
		if(6)
			return /datum/cy_skill_perk/generic/level_6

	return /datum/cy_skill_perk/generic/level_1

/datum/cy_skill_perk/generic
	name = "Skill perk"
	id = "skill_perk"
	desc = "A generic character setup perk backing a skill level."

/datum/cy_skill_perk/generic/New()
	. = ..()
	check_bonus = level * CY_SKILL_PERK_CHECK_BONUS_PER_LEVEL
	experience_bonus = level * CY_SKILL_PERK_EXPERIENCE_BONUS_PER_LEVEL
	work_speed_bonus = level * CY_SKILL_PERK_WORK_SPEED_BONUS_PER_LEVEL
	quality_bonus = level * CY_SKILL_PERK_QUALITY_BONUS_PER_LEVEL
	desc = get_effect_summary()

/datum/cy_skill_perk/generic/level_1
	name = "Initiate"
	id = "level_1"
	level = 1

/datum/cy_skill_perk/generic/level_2
	name = "Operator"
	id = "level_2"
	level = 2

/datum/cy_skill_perk/generic/level_3
	name = "Specialist"
	id = "level_3"
	level = 3

/datum/cy_skill_perk/generic/level_4
	name = "Expert"
	id = "level_4"
	level = 4

/datum/cy_skill_perk/generic/level_5
	name = "Professional"
	id = "level_5"
	level = 5

/datum/cy_skill_perk/generic/level_6
	name = "Master"
	id = "level_6"
	level = 6
