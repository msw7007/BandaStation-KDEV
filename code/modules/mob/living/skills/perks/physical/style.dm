/datum/cy_skill_perk/physical/style
	skill_type = /datum/cy_skill/charisma/style

/datum/cy_skill_perk/physical/style/level_1
	id = "style_1"
	level = 1
	name = "Style 1"
	desc_template = "No {value_1}% mood-loss chance from being watched or mirrored."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/style/level_2
	id = "style_2"
	level = 2
	name = "Style 2"
	desc_template = "Observers gain +{value_1}% mood when looking at you."
	effects = list(
		"level" = 2,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/style/level_3
	id = "style_3"
	level = 3
	name = "Style 3"
	desc_template = "Can see a person's general mood."
	effects = list(
		"level" = 3,
	)

/datum/cy_skill_perk/physical/style/level_4
	id = "style_4"
	level = 4
	name = "Style 4"
	desc_template = "If someone repeats your non-combat interaction, they gain +{value_1}% mood for {value_2} minutes and need growth is reduced by {value_3}%."
	effects = list(
		"level" = 4,
		"value_1" = 20,
		"value_2" = 2,
		"value_3" = 50
	)

/datum/cy_skill_perk/physical/style/level_5
	id = "style_5"
	level = 5
	name = "Style 5"
	desc_template = "Critical hits give observers mood and +{value_1}% damage if you have not damaged them in {value_2} minutes."
	effects = list(
		"level" = 5,
		"value_1" = 25,
		"value_2" = 10
	)

/datum/cy_skill_perk/physical/style/level_6
	id = "style_6"
	level = 6
	name = "Style 6"
	desc_template = "When dealing damage, you can blind the target for {value_1} seconds; can see mood reasons."
	effects = list(
		"level" = 6,
		"value_1" = 2
	)
