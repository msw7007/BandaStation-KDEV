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

/datum/cy_skill_perk/proc/on_gain(mob/living/owner)
	return

/datum/cy_skill_perk/proc/on_loss(mob/living/owner)
	return

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
