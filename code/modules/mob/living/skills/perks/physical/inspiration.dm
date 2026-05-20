/datum/cy_skill_perk/physical/inspiration
	skill_type = /datum/cy_skill/charisma/inspiration

/datum/cy_skill_perk/physical/inspiration/level_1
	id = "inspiration_1"
	level = 1
	name = "Inspiration 1"
	desc_template = "Training/music effects are no longer reduced to {value_1}%."
	effects = list(
		"level" = 1,
		"value_1" = 50,
		"training_effect_percent" = 50
	)

/datum/cy_skill_perk/physical/inspiration/level_2
	id = "inspiration_2"
	level = 2
	name = "Inspiration 2"
	desc_template = "Can choose a cohort affected by effects; max {value_1} people."
	effects = list(
		"level" = 2,
		"value_1" = 2
	)

/datum/cy_skill_perk/physical/inspiration/level_3
	id = "inspiration_3"
	level = 3
	name = "Inspiration 3"
	desc_template = "Effectiveness +{value_1}%; cohort size {value_2}."
	effects = list(
		"level" = 3,
		"value_1" = 25,
		"value_2" = 3,
		"cohort_limit" = 3
	)

/datum/cy_skill_perk/physical/inspiration/level_4
	id = "inspiration_4"
	level = 4
	name = "Inspiration 4"
	desc_template = "Protection timer for cohort members +{value_1}%; cohort size {value_2}."
	effects = list(
		"level" = 4,
		"value_1" = 20,
		"value_2" = 4,
		"effectiveness_bonus" = 25,
		"cohort_limit" = 4
	)

/datum/cy_skill_perk/physical/inspiration/level_5
	id = "inspiration_5"
	level = 5
	name = "Inspiration 5"
	desc_template = "Cohort mood gains +{value_1}% of maximum from effects; cohort size {value_2}."
	effects = list(
		"level" = 5,
		"value_1" = 20,
		"value_2" = 6,
		"protection_timer_bonus" = 20,
		"cohort_limit" = 6
	)

/datum/cy_skill_perk/physical/inspiration/level_6
	id = "inspiration_6"
	level = 6
	name = "Inspiration 6"
	desc_template = "Affected characters do not lose consciousness; cohort size {value_1}."
	effects = list(
		"level" = 6,
		"value_1" = 8,
		"cohort_mood_max_bonus" = 20,
		"cohort_limit" = 8
	)
