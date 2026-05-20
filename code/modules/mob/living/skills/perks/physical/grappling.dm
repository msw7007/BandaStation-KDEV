/datum/cy_skill_perk/physical/grappling
	skill_type = /datum/cy_skill/strength/grappling

/datum/cy_skill_perk/physical/grappling/level_1
	id = "grappling_1"
	level = 1
	name = "Grappling 1"
	desc_template = "No +{value_1}% self-fall chance on failed grab."
	effects = list(
		"level" = 1,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/grappling/level_2
	id = "grappling_2"
	level = 2
	name = "Grappling 2"
	desc_template = "Can grab with both hands for power moves."
	effects = list(
		"level" = 2,
	)

/datum/cy_skill_perk/physical/grappling/level_3
	id = "grappling_3"
	level = 3
	name = "Grappling 3"
	desc_template = "Two-handed grabs add +{value_1}% strength to grappling level."
	effects = list(
		"level" = 3,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/grappling/level_4
	id = "grappling_4"
	level = 4
	name = "Grappling 4"
	desc_template = "Grab use and grab strengthening cost less stamina."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/physical/grappling/level_5
	id = "grappling_5"
	level = 5
	name = "Grappling 5"
	desc_template = "One-handed grab can pain-lock; two-handed grab can knock down and throw farther."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/grappling/level_6
	id = "grappling_6"
	level = 6
	name = "Grappling 6"
	desc_template = "One-handed grabs gain strength; body throws farther; two-handed grabbed target is staggered."
	effects = list(
		"level" = 6,
	)
