/datum/cy_skill_perk/physical/intelligence_composure
	skill_type = /datum/cy_skill/intelligence/composure

/datum/cy_skill_perk/physical/intelligence_composure/level_1
	id = "intelligence_composure_1"
	level = 1
	name = "Intelligence Composure 1"
	desc_template = "No +{value_1}% repeated negative-status chance."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/intelligence_composure/level_2
	id = "intelligence_composure_2"
	level = 2
	name = "Intelligence Composure 2"
	desc_template = "Negative status duration -{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/intelligence_composure/level_3
	id = "intelligence_composure_3"
	level = 3
	name = "Intelligence Composure 3"
	desc_template = "On negative status, {value_1}% chance to gain +{value_2}% movement for {value_3} seconds."
	effects = list(
		"level" = 3,
		"value_1" = 10,
		"value_2" = 10,
		"value_3" = 5
	)

/datum/cy_skill_perk/physical/intelligence_composure/level_4
	id = "intelligence_composure_4"
	level = 4
	name = "Intelligence Composure 4"
	desc_template = "Each negative effect loses {value_1}% of effect and becomes {value_2}% slowdown."
	effects = list(
		"level" = 4,
		"value_1" = 20,
		"value_2" = 5
	)

/datum/cy_skill_perk/physical/intelligence_composure/level_5
	id = "intelligence_composure_5"
	level = 5
	name = "Intelligence Composure 5"
	desc_template = "Negative effect efficiency -{value_1}%."
	effects = list(
		"level" = 5,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/intelligence_composure/level_6
	id = "intelligence_composure_6"
	level = 6
	name = "Intelligence Composure 6"
	desc_template = "Can fully block a negative effect on cooldown."
	effects = list(
		"level" = 6,
	)
