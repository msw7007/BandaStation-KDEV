GLOBAL_LIST_INIT(cy_stat_types, list(
	/datum/cy_stat/strength,
	/datum/cy_stat/dexterity,
	/datum/cy_stat/perception,
	/datum/cy_stat/intelligence,
	/datum/cy_stat/spirit,
	/datum/cy_stat/charisma,
	/datum/cy_stat/luck,
))

GLOBAL_LIST_EMPTY(cy_stat_datums)

/proc/get_cy_stat_datum(stat_type) as /datum/cy_stat
	if(!ispath(stat_type, /datum/cy_stat))
		return null

	var/datum/cy_stat/stat = GLOB.cy_stat_datums[stat_type]
	if(!stat)
		stat = new stat_type
		GLOB.cy_stat_datums[stat_type] = stat

	return stat

/datum/cy_stat
	/// Player-facing name.
	var/name = "Unknown stat"

	/// Short machine-readable id for logs/save/UI.
	var/id = "unknown"

	/// Description for later UI.
	var/desc = ""

	/// Physical/general skills limited by this stat.
	/// Weapon and professional skills should not be here.
	var/list/limited_skills = list()

/datum/cy_stat/proc/limits_skill(skill_type)
	return skill_type in limited_skills
