/datum/cy_skill_perk/physical/theft
	skill_type = /datum/cy_skill/charisma/theft

/datum/cy_skill_perk/physical/theft/level_1
	id = "theft_1"
	level = 1
	name = "Theft 1"
	desc_template = "No automatic theft message to everyone in {value_1} tile."
	effects = list(
		"level" = 1,
		"value_1" = 1
	)

/datum/cy_skill_perk/physical/theft/level_2
	id = "theft_2"
	level = 2
	name = "Theft 2"
	desc_template = "{value_1}% chance victim misses theft message in shadow; {value_2}% in light."
	effects = list(
		"level" = 2,
		"value_1" = 50,
		"value_2" = 25
	)

/datum/cy_skill_perk/physical/theft/level_3
	id = "theft_3"
	level = 3
	name = "Theft 3"
	desc_template = "Victim does not see theft attempt if perception is below triple theft level."
	effects = list(
		"level" = 3,
	)

/datum/cy_skill_perk/physical/theft/level_4
	id = "theft_4"
	level = 4
	name = "Theft 4"
	desc_template = "Theft is instant."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/physical/theft/level_5
	id = "theft_5"
	level = 5
	name = "Theft 5"
	desc_template = "Theft is possible while moving."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/theft/level_6
	id = "theft_6"
	level = 6
	name = "Theft 6"
	desc_template = "Can steal all equipment slots."
	effects = list(
		"level" = 6,
	)
