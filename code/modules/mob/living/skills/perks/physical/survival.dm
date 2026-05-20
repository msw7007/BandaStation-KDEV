/datum/cy_skill_perk/physical/survival
	skill_type = /datum/cy_skill/spirit/survival

/datum/cy_skill_perk/physical/survival/level_1
	id = "survival_1"
	level = 1
	name = "Survival 1"
	desc_template = "No +{value_1}% hunger/thirst/sleep rate penalty."
	effects = list(
		"level" = 1,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/survival/level_2
	id = "survival_2"
	level = 2
	name = "Survival 2"
	desc_template = "Food, water and sleep effectiveness +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/survival/level_3
	id = "survival_3"
	level = 3
	name = "Survival 3"
	desc_template = "Sleepiness no longer slows the character."
	effects = list(
		"level" = 3,
	)

/datum/cy_skill_perk/physical/survival/level_4
	id = "survival_4"
	level = 4
	name = "Survival 4"
	desc_template = "Hunger and thirst advance {value_1}% slower."
	effects = list(
		"level" = 4,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/survival/level_5
	id = "survival_5"
	level = 5
	name = "Survival 5"
	desc_template = "Hunger and thirst penalties work at only {value_1}% when reducing stats."
	effects = list(
		"level" = 5,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/survival/level_6
	id = "survival_6"
	level = 6
	name = "Survival 6"
	desc_template = "Health and organs regenerate by themselves."
	effects = list(
		"level" = 6,
	)
