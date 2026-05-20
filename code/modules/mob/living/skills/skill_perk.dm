/datum/cy_skill_perk
	/// Player-facing name.
	var/name = "Unknown perk"

	/// Short machine-readable id for logs/save/UI.
	var/id = "unknown"

	/// Description for later UI.
	var/desc = ""

	/// Description template. Values are expanded from effects with {effect_key} placeholders.
	var/desc_template = ""

	/// Skill level this perk belongs to.
	var/level = CY_SKILL_LEVEL_UNTRAINED

	/// Skill typepath this perk belongs to. Optional, but useful for UI/logs.
	var/skill_type = null

	/// Assoc list of effect key = number/text/bool. Runtime code reads concrete values from here.
	var/list/effects = list()

/datum/cy_skill_perk/New()
	. = ..()
	if(!desc)
		desc = get_effect_summary()

/proc/cy_skill_perk_trait(skill_type, level)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return null

	return "cy_skill_perk_[skill.id]_[clamp(round(level), CY_SKILL_MINIMUM_LEVEL, skill.max_level)]"

/datum/cy_skill_perk/proc/on_gain(mob/living/owner)
	var/perk_trait = cy_skill_perk_trait(skill_type, level)
	if(perk_trait)
		ADD_TRAIT(owner, perk_trait, CY_SKILL_PERK_TRAIT)
	return

/datum/cy_skill_perk/proc/on_loss(mob/living/owner)
	var/perk_trait = cy_skill_perk_trait(skill_type, level)
	if(perk_trait)
		REMOVE_TRAIT(owner, perk_trait, CY_SKILL_PERK_TRAIT)
	return

/datum/cy_skill_perk/proc/get_trait()
	return cy_skill_perk_trait(skill_type, level)

/datum/cy_skill_perk/proc/has_effect(effect_key)
	return !isnull(effects?[effect_key])

/datum/cy_skill_perk/proc/get_value(effect_key = null, default = 0)
	if(isnull(effect_key))
		return default
	if(isnull(effects?[effect_key]))
		return default
	return effects[effect_key]

/datum/cy_skill_perk/proc/get_val(effect_key = "value_1", default = 0)
	return get_value(effect_key, default)

/datum/cy_skill_perk/proc/get_effect_summary()
	if(desc_template)
		var/result = desc_template
		for(var/effect_key in effects)
			result = replacetext(result, "{[effect_key]}", "[get_val(effect_key)]")
		return result
	return desc || "Unlocks a skill perk."

/datum/cy_skill_perk/proc/apply_skill_context()
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(skill)
		if(!name || name == "Unknown perk")
			name = "[skill.name] [level]"
		if(!id || id == "unknown")
			id = "[skill.id]_[level]"
	desc = get_effect_summary()
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

/datum/cy_skill_perk/generic/New()
	. = ..()
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

/datum/cy_skill_perk/professional
	name = "Professional perk"
	id = "professional_perk"
	desc = "A profession-focused skill perk."

/datum/cy_skill_perk/physical
	name = "Physical perk"
	id = "physical_perk"
	desc = "A stat-linked skill perk."
