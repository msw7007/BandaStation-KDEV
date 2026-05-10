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

	/// Stat typepath used in checks and stat capacity limits.
	var/governing_stat = null

	/// If TRUE, this skill counts against governing stat capacity.
	/// Physical/stat skills use TRUE.
	/// Weapon and professional skills should use FALSE.
	var/limited_by_stat = TRUE

	/// Assoc/list indexed by skill level.
	/// Can hold strings, datum paths, or /datum/cy_skill_perk paths.
	var/list/perks_by_level = list()

/datum/cy_skill/proc/get_perks_for_level(level)
	if(!length(perks_by_level))
		return list()

	return perks_by_level[level] || list()
