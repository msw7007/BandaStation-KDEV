/datum/cy_skill_perk/professional/cooking
	skill_type = /datum/cy_skill/professional/cooking

/datum/cy_skill_perk/professional/cooking/level_1
	id = "cooking_1"
	level = 1
	name = "Cooking 1"
	desc_template = "No cooking time and burn penalty; spoil penalty remains."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/cooking/level_2
	id = "cooking_2"
	level = 2
	name = "Cooking 2"
	desc_template = "Cooking time becomes {value_1}%; {value_2}% chance for level-{value_3} positive food effect."
	effects = list(
		"level" = 2,
		"value_1" = 75,
		"value_2" = 15,
		"value_3" = 1
	)

/datum/cy_skill_perk/professional/cooking/level_3
	id = "cooking_3"
	level = 3
	name = "Cooking 3"
	desc_template = "Compatible ingredients can raise positive effect up to level {value_1} or spoil the food."
	effects = list(
		"level" = 3,
		"value_1" = 3
	)

/datum/cy_skill_perk/professional/cooking/level_4
	id = "cooking_4"
	level = 4
	name = "Cooking 4"
	desc_template = "Examine food composition, spoilage and effect strength; compatible ingredients reduce spoil chance by {value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 30
	)

/datum/cy_skill_perk/professional/cooking/level_5
	id = "cooking_5"
	level = 5
	name = "Cooking 5"
	desc_template = "{value_1}% chance not to consume a cooking resource; positive food effect gains at least +{value_2} level."
	effects = list(
		"level" = 5,
		"value_1" = 10,
		"value_2" = 1
	)

/datum/cy_skill_perk/professional/cooking/level_6
	id = "cooking_6"
	level = 6
	name = "Cooking 6"
	desc_template = "Cooking time becomes {value_1}%; successful prep has {value_2}% chance to release level-{value_3} effect gas."
	effects = list(
		"level" = 6,
		"value_1" = 20,
		"value_2" = 30,
		"value_3" = 1
	)
