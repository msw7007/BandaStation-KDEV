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

/datum/cy_skill_perk/professional
	name = "Professional perk"
	id = "professional_perk"
	desc = "A profession-focused skill perk."

/datum/cy_skill_perk/professional/New()
	. = ..()
	desc = get_effect_summary()

/datum/cy_skill_perk/professional/apprentice
	name = "Apprentice practice"
	id = "professional_apprentice"
	level = 1
	experience_bonus = 5
	work_speed_bonus = 2

/datum/cy_skill_perk/professional/journeyman
	name = "Journeyman rhythm"
	id = "professional_journeyman"
	level = 2
	experience_bonus = 5
	work_speed_bonus = 4

/datum/cy_skill_perk/professional/reliable
	name = "Reliable hands"
	id = "professional_reliable"
	level = 3
	check_bonus = 4
	quality_bonus = 5

/datum/cy_skill_perk/professional/specialist
	name = "Specialist workflow"
	id = "professional_specialist"
	level = 4
	work_speed_bonus = 6
	quality_bonus = 5

/datum/cy_skill_perk/professional/expert
	name = "Expert standards"
	id = "professional_expert"
	level = 5
	check_bonus = 6
	quality_bonus = 10

/datum/cy_skill_perk/professional/master
	name = "Master craft"
	id = "professional_master"
	level = 6
	check_bonus = 8
	experience_bonus = 10
	work_speed_bonus = 8
	quality_bonus = 15

/datum/cy_skill_perk/professional/medicine/reliable
	name = "Steady diagnosis"
	id = "medicine_reliable"
	level = 3
	check_bonus = 6
	quality_bonus = 5

/datum/cy_skill_perk/professional/medicine/expert
	name = "Trauma discipline"
	id = "medicine_expert"
	level = 5
	check_bonus = 8
	work_speed_bonus = 4
	quality_bonus = 10

/datum/cy_skill_perk/professional/chemistry/reliable
	name = "Clean batch"
	id = "chemistry_reliable"
	level = 3
	check_bonus = 5
	quality_bonus = 8

/datum/cy_skill_perk/professional/chemistry/master
	name = "Controlled reaction"
	id = "chemistry_master"
	level = 6
	check_bonus = 8
	work_speed_bonus = 6
	quality_bonus = 18

/datum/cy_skill_perk/professional/electricity/specialist
	name = "Live circuit habit"
	id = "electricity_specialist"
	level = 4
	check_bonus = 5
	work_speed_bonus = 8

/datum/cy_skill_perk/professional/electricity/master
	name = "Grid authority"
	id = "electricity_master"
	level = 6
	check_bonus = 8
	work_speed_bonus = 10
	quality_bonus = 10

/datum/cy_skill_perk/professional/construction/specialist
	name = "Frame discipline"
	id = "construction_specialist"
	level = 4
	work_speed_bonus = 8
	quality_bonus = 8

/datum/cy_skill_perk/professional/construction/master
	name = "Load-bearing instinct"
	id = "construction_master"
	level = 6
	check_bonus = 6
	work_speed_bonus = 8
	quality_bonus = 18

/datum/cy_skill_perk/professional/invention/reliable
	name = "Prototype loop"
	id = "invention_reliable"
	level = 3
	experience_bonus = 8
	quality_bonus = 6

/datum/cy_skill_perk/professional/invention/master
	name = "Breakthrough pattern"
	id = "invention_master"
	level = 6
	check_bonus = 8
	experience_bonus = 12
	quality_bonus = 15

/datum/cy_skill_perk/professional/analysis/reliable
	name = "Pattern read"
	id = "analysis_reliable"
	level = 3
	check_bonus = 8
	work_speed_bonus = 4

/datum/cy_skill_perk/professional/analysis/master
	name = "Forensic sweep"
	id = "analysis_master"
	level = 6
	check_bonus = 12
	work_speed_bonus = 8

/datum/cy_skill_perk/professional/mining/specialist
	name = "Ore sense"
	id = "mining_specialist"
	level = 4
	work_speed_bonus = 8
	quality_bonus = 5

/datum/cy_skill_perk/professional/mining/master
	name = "Deep vein instinct"
	id = "mining_master"
	level = 6
	check_bonus = 8
	work_speed_bonus = 10
	experience_bonus = 8

/datum/cy_skill_perk/professional/driving/reliable
	name = "Smooth handling"
	id = "driving_reliable"
	level = 3
	check_bonus = 4
	work_speed_bonus = 6

/datum/cy_skill_perk/professional/driving/master
	name = "Traffic ghost"
	id = "driving_master"
	level = 6
	check_bonus = 8
	work_speed_bonus = 12

/datum/cy_skill_perk/professional/cooking/reliable
	name = "Balanced prep"
	id = "cooking_reliable"
	level = 3
	work_speed_bonus = 4
	quality_bonus = 10

/datum/cy_skill_perk/professional/cooking/master
	name = "Signature dish"
	id = "cooking_master"
	level = 6
	work_speed_bonus = 8
	quality_bonus = 20

/datum/cy_skill_perk/professional/gardening/reliable
	name = "Green thumb"
	id = "gardening_reliable"
	level = 3
	experience_bonus = 6
	quality_bonus = 8

/datum/cy_skill_perk/professional/gardening/master
	name = "Cultivar keeper"
	id = "gardening_master"
	level = 6
	experience_bonus = 10
	work_speed_bonus = 6
	quality_bonus = 18

/datum/cy_skill_perk/professional/music/reliable
	name = "Clean phrasing"
	id = "music_reliable"
	level = 3
	experience_bonus = 8
	quality_bonus = 6

/datum/cy_skill_perk/professional/music/master
	name = "Stage control"
	id = "music_master"
	level = 6
	check_bonus = 8
	experience_bonus = 12
	quality_bonus = 12

// Prepared stat-linked perk shells. These are intentionally not assigned to physical skill trees yet.
/datum/cy_skill_perk/stat_linked
	name = "Prepared stat perk"
	id = "stat_linked_prepared"
	desc = "Prepared stat-linked perk hook. Not assigned to any skill tree yet."
	var/stat_path
	var/skill_path

/datum/cy_skill_perk/stat_linked/New()
	. = ..()
	desc = get_effect_summary()

/datum/cy_skill_perk/stat_linked/get_effect_summary()
	return ..()

/datum/cy_skill_perk/stat_linked/level_1
	name = "Stat practice"
	id = "stat_linked_1"
	level = 1
	check_bonus = 2
	experience_bonus = 2

/datum/cy_skill_perk/stat_linked/level_2
	name = "Stat routine"
	id = "stat_linked_2"
	level = 2
	check_bonus = 3
	work_speed_bonus = 2

/datum/cy_skill_perk/stat_linked/level_3
	name = "Stat discipline"
	id = "stat_linked_3"
	level = 3
	check_bonus = 4
	experience_bonus = 4
	work_speed_bonus = 3

/datum/cy_skill_perk/stat_linked/level_4
	name = "Stat specialization"
	id = "stat_linked_4"
	level = 4
	check_bonus = 5
	work_speed_bonus = 5
	quality_bonus = 2

/datum/cy_skill_perk/stat_linked/level_5
	name = "Stat expertise"
	id = "stat_linked_5"
	level = 5
	check_bonus = 7
	experience_bonus = 6
	work_speed_bonus = 6
	quality_bonus = 3

/datum/cy_skill_perk/stat_linked/level_6
	name = "Stat mastery"
	id = "stat_linked_6"
	level = 6
	check_bonus = 10
	experience_bonus = 8
	work_speed_bonus = 8
	quality_bonus = 5

/datum/cy_skill_perk/stat_linked/strength/power_melee
	name = "Power melee stat hook"
	id = "stat_power_melee_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/power_melee

/datum/cy_skill_perk/stat_linked/strength/heavy_weapons
	name = "Heavy weapons stat hook"
	id = "stat_heavy_weapons_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/heavy_weapons

/datum/cy_skill_perk/stat_linked/strength/grappling
	name = "Grappling stat hook"
	id = "stat_grappling_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/grappling

/datum/cy_skill_perk/stat_linked/strength/toughness
	name = "Toughness stat hook"
	id = "stat_toughness_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/toughness

/datum/cy_skill_perk/stat_linked/dexterity/fast_melee
	name = "Fast melee stat hook"
	id = "stat_fast_melee_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/fast_melee

/datum/cy_skill_perk/stat_linked/dexterity/light_weapons
	name = "Light weapons stat hook"
	id = "stat_light_weapons_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/light_weapons

/datum/cy_skill_perk/stat_linked/dexterity/acrobatics
	name = "Acrobatics stat hook"
	id = "stat_acrobatics_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/acrobatics

/datum/cy_skill_perk/stat_linked/dexterity/evasion
	name = "Evasion stat hook"
	id = "stat_evasion_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/evasion

/datum/cy_skill_perk/stat_linked/perception/precise_melee
	name = "Precise melee stat hook"
	id = "stat_precise_melee_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/precise_melee

/datum/cy_skill_perk/stat_linked/perception/throwing
	name = "Throwing stat hook"
	id = "stat_throwing_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/throwing

/datum/cy_skill_perk/stat_linked/perception/weakspot_analysis
	name = "Weakspot analysis stat hook"
	id = "stat_weakspot_analysis_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/weakspot_analysis

/datum/cy_skill_perk/stat_linked/perception/concentration
	name = "Concentration stat hook"
	id = "stat_concentration_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/concentration

/datum/cy_skill_perk/stat_linked/intelligence/improved_code
	name = "Improved code stat hook"
	id = "stat_improved_code_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/improved_code

/datum/cy_skill_perk/stat_linked/intelligence/fast_code
	name = "Fast code stat hook"
	id = "stat_fast_code_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/fast_code

/datum/cy_skill_perk/stat_linked/intelligence/hacking
	name = "Hacking stat hook"
	id = "stat_hacking_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/hacking

/datum/cy_skill_perk/stat_linked/intelligence/composure
	name = "Composure stat hook"
	id = "stat_intelligence_composure_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/composure

/datum/cy_skill_perk/stat_linked/spirit/survival
	name = "Survival stat hook"
	id = "stat_survival_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/survival

/datum/cy_skill_perk/stat_linked/spirit/endurance
	name = "Endurance stat hook"
	id = "stat_spirit_endurance_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/endurance

/datum/cy_skill_perk/stat_linked/spirit/athletics
	name = "Athletics stat hook"
	id = "stat_athletics_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/athletics

/datum/cy_skill_perk/stat_linked/spirit/compatibility
	name = "Compatibility stat hook"
	id = "stat_compatibility_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/compatibility

/datum/cy_skill_perk/stat_linked/charisma/stealth
	name = "Stealth stat hook"
	id = "stat_stealth_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/stealth

/datum/cy_skill_perk/stat_linked/charisma/theft
	name = "Theft stat hook"
	id = "stat_theft_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/theft

/datum/cy_skill_perk/stat_linked/charisma/inspiration
	name = "Inspiration stat hook"
	id = "stat_inspiration_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/inspiration

/datum/cy_skill_perk/stat_linked/charisma/style
	name = "Style stat hook"
	id = "stat_style_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/style
