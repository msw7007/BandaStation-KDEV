/datum/cy_skill_perk/professional/invention
	skill_type = /datum/cy_skill/professional/invention

/datum/cy_skill_perk/professional/invention/level_1
	id = "invention_1"
	level = 1
	name = "Invention 1"
	desc_template = "No item creation/repair time and item health penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/invention/level_2
	id = "invention_2"
	level = 2
	name = "Invention 2"
	desc_template = "Creation explosion chance reduced from {value_1}% to {value_2}%."
	effects = list(
		"level" = 2,
		"value_1" = 20,
		"value_2" = 0
	)

/datum/cy_skill_perk/professional/invention/level_3
	id = "invention_3"
	level = 3
	name = "Invention 3"
	desc_template = "Disassembly speed +{value_1}%, assembly speed +{value_2}%."
	effects = list(
		"level" = 3,
		"value_1" = 30,
		"value_2" = 10
	)

/datum/cy_skill_perk/professional/invention/level_4
	id = "invention_4"
	level = 4
	name = "Invention 4"
	desc_template = "Can reconfigure an item without dismantling it."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/professional/invention/level_5
	id = "invention_5"
	level = 5
	name = "Invention 5"
	desc_template = "Assembly speed +{value_1}%, created item health +{value_2}%."
	effects = list(
		"level" = 5,
		"value_1" = 30,
		"value_2" = 30
	)

/datum/cy_skill_perk/professional/invention/level_6
	id = "invention_6"
	level = 6
	name = "Invention 6"
	desc_template = "{value_1}% chance to create a copy without spending resources; disassembly speed +{value_2}%."
	effects = list(
		"level" = 6,
		"value_1" = 4,
		"value_2" = 40
	)
