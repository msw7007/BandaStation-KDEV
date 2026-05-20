/datum/cy_skill_perk/professional/analysis
	skill_type = /datum/cy_skill/professional/analysis

/datum/cy_skill_perk/professional/analysis/level_1
	id = "analysis_1"
	level = 1
	name = "Analysis 1"
	desc_template = "No analysis time penalty and no result skip penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/analysis/level_2
	id = "analysis_2"
	level = 2
	name = "Analysis 2"
	desc_template = "Analysis speed +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 25
	)

/datum/cy_skill_perk/professional/analysis/level_3
	id = "analysis_3"
	level = 3
	name = "Analysis 3"
	desc_template = "Destroying an analyzed object has {value_1}% chance to produce its material."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/professional/analysis/level_4
	id = "analysis_4"
	level = 4
	name = "Analysis 4"
	desc_template = "Material chance rises to {value_1}%; analysis speed +{value_2}%."
	effects = list(
		"level" = 4,
		"value_1" = 50,
		"value_2" = 25
	)

/datum/cy_skill_perk/professional/analysis/level_5
	id = "analysis_5"
	level = 5
	name = "Analysis 5"
	desc_template = "Analyzed items can satisfy crafting ingredient requirements when their composition matches."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/professional/analysis/level_6
	id = "analysis_6"
	level = 6
	name = "Analysis 6"
	desc_template = "{value_1}% chance to extract technology/blueprint from analyzed structures or items."
	effects = list(
		"level" = 6,
		"value_1" = 20
	)
