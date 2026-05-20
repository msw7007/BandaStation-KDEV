/datum/cy_skill_perk/physical/fast_code
	skill_type = /datum/cy_skill/intelligence/fast_code

/datum/cy_skill_perk/physical/fast_code/level_1
	id = "fast_code_1"
	level = 1
	name = "Fast Code 1"
	desc_template = "No -{value_1}% demon preparation speed penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/fast_code/level_2
	id = "fast_code_2"
	level = 2
	name = "Fast Code 2"
	desc_template = "Demon preparation speed +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/fast_code/level_3
	id = "fast_code_3"
	level = 3
	name = "Fast Code 3"
	desc_template = "Activated demon recovery time -{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/fast_code/level_4
	id = "fast_code_4"
	level = 4
	name = "Fast Code 4"
	desc_template = "After successful demon use, {value_1}% chance next demon preparation is {value_2}% shorter."
	effects = list(
		"level" = 4,
		"value_1" = 25,
		"value_2" = 50
	)

/datum/cy_skill_perk/physical/fast_code/level_5
	id = "fast_code_5"
	level = 5
	name = "Fast Code 5"
	desc_template = "After failed demon use, {value_1}% chance demon cooldown resets."
	effects = list(
		"level" = 5,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/fast_code/level_6
	id = "fast_code_6"
	level = 6
	name = "Fast Code 6"
	desc_template = "Demon use has {value_1}% chance to make next demon instant."
	effects = list(
		"level" = 6,
		"value_1" = 25
	)
