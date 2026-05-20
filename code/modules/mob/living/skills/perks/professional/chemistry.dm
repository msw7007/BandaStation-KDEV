/datum/cy_skill_perk/professional/chemistry
	skill_type = /datum/cy_skill/professional/chemistry

/datum/cy_skill_perk/professional/chemistry/level_1
	id = "chemistry_1"
	level = 1
	name = "Chemistry 1"
	desc_template = "Reaction tick instability reduced to {value_1}% random acidity/temperature drift."
	effects = list(
		"level" = 1,
		"value_1" = 2
	)

/datum/cy_skill_perk/professional/chemistry/level_2
	id = "chemistry_2"
	level = 2
	name = "Chemistry 2"
	desc_template = "Can identify simple chemicals; no untrained penalty."
	effects = list(
		"level" = 2,
	)

/datum/cy_skill_perk/professional/chemistry/level_3
	id = "chemistry_3"
	level = 3
	name = "Chemistry 3"
	desc_template = "Reaction temperature drift -{value_1}%, reaction speed +{value_2}%."
	effects = list(
		"level" = 3,
		"value_1" = 5,
		"value_2" = 5
	)

/datum/cy_skill_perk/professional/chemistry/level_4
	id = "chemistry_4"
	level = 4
	name = "Chemistry 4"
	desc_template = "Can identify compound chemicals by smell; reaction speed +{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 5
	)

/datum/cy_skill_perk/professional/chemistry/level_5
	id = "chemistry_5"
	level = 5
	name = "Chemistry 5"
	desc_template = "Can examine chemical purity; starting temperature drift -{value_1}%."
	effects = list(
		"level" = 5,
		"value_1" = 5
	)

/datum/cy_skill_perk/professional/chemistry/level_6
	id = "chemistry_6"
	level = 6
	name = "Chemistry 6"
	desc_template = "Critical mass explosion delayed by {value_1}%; all chemicals gain +{value_2}% purity and effectiveness."
	effects = list(
		"level" = 6,
		"value_1" = 10,
		"value_2" = 25
	)
