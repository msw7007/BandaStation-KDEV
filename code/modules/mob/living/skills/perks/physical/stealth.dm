/datum/cy_skill_perk/physical/stealth
	skill_type = /datum/cy_skill/charisma/stealth

/datum/cy_skill_perk/physical/stealth/level_1
	id = "stealth_1"
	level = 1
	name = "Stealth 1"
	desc_template = "No shadow-chameleon untrained penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/physical/stealth/level_2
	id = "stealth_2"
	level = 2
	name = "Stealth 2"
	desc_template = "Can move in shadow without losing {value_1}% chameleon."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/stealth/level_3
	id = "stealth_3"
	level = 3
	name = "Stealth 3"
	desc_template = "Chameleon strengthens to {value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 60
	)

/datum/cy_skill_perk/physical/stealth/level_4
	id = "stealth_4"
	level = 4
	name = "Stealth 4"
	desc_template = "Required light level for chameleon is reduced by {value_1}%; stealth movement is faster."
	effects = list(
		"level" = 4,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/stealth/level_5
	id = "stealth_5"
	level = 5
	name = "Stealth 5"
	desc_template = "Stealth attacks gain x1.{value_1} multiplier."
	effects = list(
		"level" = 5,
		"value_1" = 5
	)

/datum/cy_skill_perk/physical/stealth/level_6
	id = "stealth_6"
	level = 6
	name = "Stealth 6"
	desc_template = "Chameleon reaches {value_1}% in shadow and {value_2}% in light; can run in stealth."
	effects = list(
		"level" = 6,
		"value_1" = 90,
		"value_2" = 70
	)
