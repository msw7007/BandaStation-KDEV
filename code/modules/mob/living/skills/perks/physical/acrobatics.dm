/datum/cy_skill_perk/physical/acrobatics
	skill_type = /datum/cy_skill/dexterity/acrobatics

/datum/cy_skill_perk/physical/acrobatics/level_1
	id = "acrobatics_1"
	level = 1
	name = "Acrobatics 1"
	desc_template = "Sprint-jump unlocked."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/physical/acrobatics/level_2
	id = "acrobatics_2"
	level = 2
	name = "Acrobatics 2"
	desc_template = "Long climb and vault actions are {value_1}% shorter."
	effects = list(
		"level" = 2,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/acrobatics/level_3
	id = "acrobatics_3"
	level = 3
	name = "Acrobatics 3"
	desc_template = "Jump can weaken grabs; jump/climb stamina cost -{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/acrobatics/level_4
	id = "acrobatics_4"
	level = 4
	name = "Acrobatics 4"
	desc_template = "After acrobatics, gain +{value_1}% movement speed for {value_2} seconds."
	effects = list(
		"level" = 4,
		"value_1" = 15,
		"value_2" = 30
	)

/datum/cy_skill_perk/physical/acrobatics/level_5
	id = "acrobatics_5"
	level = 5
	name = "Acrobatics 5"
	desc_template = "+{value_1}% movement speed; sprint-jump no longer overshoots extra distance."
	effects = list(
		"level" = 5,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/acrobatics/level_6
	id = "acrobatics_6"
	level = 6
	name = "Acrobatics 6"
	desc_template = "Acrobatics are instant; can jump between Z-levels without fall damage."
	effects = list(
		"level" = 6,
	)
