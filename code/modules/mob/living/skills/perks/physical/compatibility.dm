/datum/cy_skill_perk/physical/compatibility
	skill_type = /datum/cy_skill/spirit/compatibility

/datum/cy_skill_perk/physical/compatibility/level_1
	id = "compatibility_1"
	level = 1
	name = "Compatibility 1"
	desc_template = "No +{value_1}% implant pain and {value_2}% overload-per-minute penalty."
	effects = list(
		"level" = 1,
		"value_1" = 20,
		"value_2" = 1
	)

/datum/cy_skill_perk/physical/compatibility/level_2
	id = "compatibility_2"
	level = 2
	name = "Compatibility 2"
	desc_template = "Implant reserve before pain +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/compatibility/level_3
	id = "compatibility_3"
	level = 3
	name = "Compatibility 3"
	desc_template = "Implant overload effects -{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/compatibility/level_4
	id = "compatibility_4"
	level = 4
	name = "Compatibility 4"
	desc_template = "Implant effectiveness and power +{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/compatibility/level_5
	id = "compatibility_5"
	level = 5
	name = "Compatibility 5"
	desc_template = "Implant overload or reserve overflow causes slowdown instead of pain."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/compatibility/level_6
	id = "compatibility_6"
	level = 6
	name = "Compatibility 6"
	desc_template = "Implants do not cause pain."
	effects = list(
		"level" = 6,
	)
