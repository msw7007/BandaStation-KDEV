/datum/cy_skill_perk/physical/weakspot_analysis
	skill_type = /datum/cy_skill/perception/weakspot_analysis

/datum/cy_skill_perk/physical/weakspot_analysis/level_1
	id = "weakspot_analysis_1"
	level = 1
	name = "Weakspot Analysis 1"
	desc_template = "No +{value_1}% untrained critical-hit failure chance."
	effects = list(
		"level" = 1,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/weakspot_analysis/level_2
	id = "weakspot_analysis_2"
	level = 2
	name = "Weakspot Analysis 2"
	desc_template = "{value_1}% chance that hit becomes empowered and final damage +{value_2}%."
	effects = list(
		"level" = 2,
		"value_1" = 10,
		"value_2" = 20
	)

/datum/cy_skill_perk/physical/weakspot_analysis/level_3
	id = "weakspot_analysis_3"
	level = 3
	name = "Weakspot Analysis 3"
	desc_template = "Unprotected-zone hits have {value_1}% chance to become crushing and apply or upgrade tier-{value_2} critical wound."
	effects = list(
		"level" = 3,
		"value_1" = 50,
		"value_2" = 1
	)

/datum/cy_skill_perk/physical/weakspot_analysis/level_4
	id = "weakspot_analysis_4"
	level = 4
	name = "Weakspot Analysis 4"
	desc_template = "Any critical wound inflicted immobilizes the target for {value_1} seconds."
	effects = list(
		"level" = 4,
		"value_1" = 2
	)

/datum/cy_skill_perk/physical/weakspot_analysis/level_5
	id = "weakspot_analysis_5"
	level = 5
	name = "Weakspot Analysis 5"
	desc_template = "Empowered/crushing hits have {value_1}% chance to ignore covering armor."
	effects = list(
		"level" = 5,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/weakspot_analysis/level_6
	id = "weakspot_analysis_6"
	level = 6
	name = "Weakspot Analysis 6"
	desc_template = "Crushing head hit has {value_1}% chance to paralyze for {value_2} seconds."
	effects = list(
		"level" = 6,
		"value_1" = 25,
		"value_2" = 2
	)
