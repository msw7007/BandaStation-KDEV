/datum/cy_skill_perk/physical/throwing
	skill_type = /datum/cy_skill/perception/throwing

/datum/cy_skill_perk/physical/throwing/level_1
	id = "throwing_1"
	level = 1
	name = "Throwing 1"
	desc_template = "No -{value_1}% untrained throw accuracy penalty."
	effects = list(
		"level" = 1,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/throwing/level_2
	id = "throwing_2"
	level = 2
	name = "Throwing 2"
	desc_template = "Throw accuracy +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/throwing/level_3
	id = "throwing_3"
	level = 3
	name = "Throwing 3"
	desc_template = "Aimed throw bonus works +{value_1} tiles farther."
	effects = list(
		"level" = 3,
		"value_1" = 5
	)

/datum/cy_skill_perk/physical/throwing/level_4
	id = "throwing_4"
	level = 4
	name = "Throwing 4"
	desc_template = "Aimed throw/charge time -{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/throwing/level_5
	id = "throwing_5"
	level = 5
	name = "Throwing 5"
	desc_template = "{value_1}% chance that thrown ammo is not spent or thrown weapon is not damaged."
	effects = list(
		"level" = 5,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/throwing/level_6
	id = "throwing_6"
	level = 6
	name = "Throwing 6"
	desc_template = "Aimed throw can be activated while moving."
	effects = list(
		"level" = 6,
	)
