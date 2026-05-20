/datum/cy_skill_perk/physical/spirit_endurance
	skill_type = /datum/cy_skill/spirit/endurance

/datum/cy_skill_perk/physical/spirit_endurance/level_1
	id = "spirit_endurance_1"
	level = 1
	name = "Spirit Endurance 1"
	desc_template = "No -{value_1}% pain-collapse threshold penalty."
	effects = list(
		"level" = 1,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/spirit_endurance/level_2
	id = "spirit_endurance_2"
	level = 2
	name = "Spirit Endurance 2"
	desc_template = "Pain-collapse threshold +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/spirit_endurance/level_3
	id = "spirit_endurance_3"
	level = 3
	name = "Spirit Endurance 3"
	desc_template = "{value_1}% chance to ignore pain from received damage."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/spirit_endurance/level_4
	id = "spirit_endurance_4"
	level = 4
	name = "Spirit Endurance 4"
	desc_template = "Stagger and disorientation duration -{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/spirit_endurance/level_5
	id = "spirit_endurance_5"
	level = 5
	name = "Spirit Endurance 5"
	desc_template = "Pain collapse becomes {value_1}-second immobilize instead."
	effects = list(
		"level" = 5,
		"value_1" = 2
	)

/datum/cy_skill_perk/physical/spirit_endurance/level_6
	id = "spirit_endurance_6"
	level = 6
	name = "Spirit Endurance 6"
	desc_template = "Pain does not affect the character."
	effects = list(
		"level" = 6,
	)
