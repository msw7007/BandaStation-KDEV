/datum/cy_skill_perk/professional/construction
	skill_type = /datum/cy_skill/professional/construction

/datum/cy_skill_perk/professional/construction/level_1
	id = "construction_1"
	level = 1
	name = "Construction 1"
	desc_template = "No construction/repair time and structure health penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/construction/level_2
	id = "construction_2"
	level = 2
	name = "Construction 2"
	desc_template = "Repair time -{value_1}%, construction speed +{value_2}%."
	effects = list(
		"level" = 2,
		"value_1" = 20,
		"value_2" = 20
	)

/datum/cy_skill_perk/professional/construction/level_3
	id = "construction_3"
	level = 3
	name = "Construction 3"
	desc_template = "Built structure health +{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/professional/construction/level_4
	id = "construction_4"
	level = 4
	name = "Construction 4"
	desc_template = "Attacks against structures deal +{value_1}% structure damage."
	effects = list(
		"level" = 4,
		"value_1" = 100
	)

/datum/cy_skill_perk/professional/construction/level_5
	id = "construction_5"
	level = 5
	name = "Construction 5"
	desc_template = "Can reinforce structures for extra resources by +{value_2}% health; {value_1}% chance not to consume construction resource."
	effects = list(
		"level" = 5,
		"value_1" = 30,
		"value_2" = 20
	)

/datum/cy_skill_perk/professional/construction/level_6
	id = "construction_6"
	level = 6
	name = "Construction 6"
	desc_template = "Deconstructing structures has {value_1}% chance to drop extra material."
	effects = list(
		"level" = 6,
		"value_1" = 30
	)
