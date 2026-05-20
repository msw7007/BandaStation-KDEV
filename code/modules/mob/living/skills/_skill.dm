GLOBAL_LIST_EMPTY(cy_skill_datums)

/proc/get_cy_skill_datum(skill_type) as /datum/cy_skill
	if(!ispath(skill_type, /datum/cy_skill))
		return null

	var/datum/cy_skill/skill = GLOB.cy_skill_datums[skill_type]
	if(!skill)
		skill = new skill_type
		GLOB.cy_skill_datums[skill_type] = skill

	return skill

/datum/cy_skill
	/// Player-facing name.
	var/name = "Unknown skill"

	/// Short machine-readable id for logs/save/UI.
	var/id = "unknown"

	/// Description for later UI.
	var/desc = ""

	/// Category marker for UI/filtering: physical, weapon, professional, etc.
	var/category = "physical"

	/// Stat typepath used in checks and stat capacity limits.
	var/governing_stat = null

	/// If TRUE, this skill counts against governing stat capacity.
	/// Physical/stat skills use TRUE.
	/// Weapon and professional skills should use FALSE.
	var/limited_by_stat = TRUE

	/// Maximum level for this skill.
	/// Physical and professional skills use 6. Weapon skills use 5.
	var/max_level = CY_SKILL_MAXIMUM_LEVEL

	/// Assoc/list indexed by skill level.
	/// Can hold /datum/cy_skill_perk paths.
	var/list/perks_by_level = list()

/datum/cy_skill/New()
	. = ..()
	var/list/specific_perks = list()
	for(var/current_level in 1 to max_level)
		var/perk_type = get_specific_perk_for_level(current_level)
		if(perk_type)
			specific_perks["[current_level]"] = list(perk_type)

	if(length(specific_perks))
		perks_by_level = specific_perks
		return

	if(length(perks_by_level))
		return

	perks_by_level = list()
	for(var/current_level in 1 to max_level)
		perks_by_level["[current_level]"] = list(cy_generic_skill_perk_for_level(current_level))

/datum/cy_skill/proc/get_specific_perk_for_level(level)
	if(category != "physical" && category != "professional")
		return null
	if(!id || id == "unknown")
		return null

	return text2path("/datum/cy_skill_perk/[category]/[id]/level_[level]")

/datum/cy_skill/proc/get_perks_for_level(level)
	if(!length(perks_by_level))
		return list()

	var/list/perks = perks_by_level["[level]"]
	if(!length(perks))
		return list()

	return perks

/datum/cy_skill/proc/get_all_perks_up_to_level(level)
	var/list/all_perks = list()
	for(var/current_level in 1 to min(level, max_level))
		for(var/perk_type in get_perks_for_level(current_level))
			all_perks += perk_type

	return all_perks


/proc/get_all_cy_skill_types()
	var/list/result = list()
	if(length(GLOB.cy_physical_skill_types))
		result += GLOB.cy_physical_skill_types
	if(length(GLOB.cy_weapon_skill_types))
		result += GLOB.cy_weapon_skill_types
	if(length(GLOB.cy_professional_skill_types))
		result += GLOB.cy_professional_skill_types

	if(length(result))
		return result

	result = subtypesof(/datum/cy_skill)
	result -= /datum/cy_skill/weapon
	result -= /datum/cy_skill/professional
	return result

/proc/get_cy_skill_level_name(level)
	switch(clamp(round(level), CY_SKILL_MINIMUM_LEVEL, CY_SKILL_MAXIMUM_LEVEL))
		if(CY_SKILL_LEVEL_UNTRAINED)
			return "Untrained"
		if(CY_SKILL_LEVEL_BEGINNER)
			return "Beginner"
		if(CY_SKILL_LEVEL_SKILLED)
			return "Skilled"
		if(CY_SKILL_LEVEL_TRAINED)
			return "Trained"
		if(CY_SKILL_LEVEL_EXPERT)
			return "Expert"
		if(CY_SKILL_LEVEL_PROFESSIONAL)
			return "Professional"
		if(CY_SKILL_LEVEL_MASTER)
			return "Master"

	return "Unknown"
