/*!
This subsystem mostly exists to populate and manage the skill singletons.
*/

SUBSYSTEM_DEF(skills)
	name = "Skills"
	ss_flags = SS_NO_FIRE
	///Dictionary of skill.type || skill ref
	var/list/all_skills = list()
	///List of level names with index corresponding to skill level
	var/list/level_names = list("None", "Novice", "Apprentice", "Journeyman", "Expert", "Master", "Legendary") //List of skill level names. Note that indexes can be accessed like so: level_names[SKILL_LEVEL_NOVICE]
	///Cyberpunk character skill level names. Stored one-based, level 0 is index 1.
	var/list/character_level_names = CHARACTER_SKILL_LEVEL_NAMES

/datum/controller/subsystem/skills/Initialize()
	InitializeSkills()
	return SS_INIT_SUCCESS

///Ran on initialize, populates the skills dictionary
/datum/controller/subsystem/skills/proc/InitializeSkills()
	for(var/type in GLOB.skill_types)
		var/datum/skill/ref = new type
		all_skills[type] = ref
