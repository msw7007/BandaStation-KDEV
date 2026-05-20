/datum/cy_skill_perk/professional/gardening
	skill_type = /datum/cy_skill/professional/gardening

/datum/cy_skill_perk/professional/gardening/level_1
	id = "gardening_1"
	level = 1
	name = "Gardening 1"
	desc_template = "No seed-ruin penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/gardening/level_2
	id = "gardening_2"
	level = 2
	name = "Gardening 2"
	desc_template = "Plant germination speed +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 15
	)

/datum/cy_skill_perk/professional/gardening/level_3
	id = "gardening_3"
	level = 3
	name = "Gardening 3"
	desc_template = "Can see possible mutation paths for the examined plant."
	effects = list(
		"level" = 3,
	)

/datum/cy_skill_perk/professional/gardening/level_4
	id = "gardening_4"
	level = 4
	name = "Gardening 4"
	desc_template = "Watering and feeding effectiveness +{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 25
	)

/datum/cy_skill_perk/professional/gardening/level_5
	id = "gardening_5"
	level = 5
	name = "Gardening 5"
	desc_template = "Harvesting leaf, fruit or stem has {value_1}% chance to create an extra copy."
	effects = list(
		"level" = 5,
		"value_1" = 20
	)

/datum/cy_skill_perk/professional/gardening/level_6
	id = "gardening_6"
	level = 6
	name = "Gardening 6"
	desc_template = "Expected mutations show fruit/leaf/stem reagent contents in advance."
	effects = list(
		"level" = 6,
	)
