/datum/cy_skill_perk/physical/concentration
	skill_type = /datum/cy_skill/perception/concentration

/datum/cy_skill_perk/physical/concentration/level_1
	id = "concentration_1"
	level = 1
	name = "Concentration 1"
	desc_template = "No +{value_1}% weapon loss or parry-failure chance."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/concentration/level_2
	id = "concentration_2"
	level = 2
	name = "Concentration 2"
	desc_template = "Parry success chance +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 15
	)

/datum/cy_skill_perk/physical/concentration/level_3
	id = "concentration_3"
	level = 3
	name = "Concentration 3"
	desc_template = "{value_1}% chance that parrying weapon is not damaged."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/concentration/level_4
	id = "concentration_4"
	level = 4
	name = "Concentration 4"
	desc_template = "Dual-weapon parry no longer has -{value_1}% penalty."
	effects = list(
		"level" = 4,
		"value_1" = 15
	)

/datum/cy_skill_perk/physical/concentration/level_5
	id = "concentration_5"
	level = 5
	name = "Concentration 5"
	desc_template = "Parrying opens enemy defense; next hit is guaranteed."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/concentration/level_6
	id = "concentration_6"
	level = 6
	name = "Concentration 6"
	desc_template = "Clinch uses both strength and perception to decide weapon throw distance."
	effects = list(
		"level" = 6,
	)
