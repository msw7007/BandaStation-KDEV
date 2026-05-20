/datum/cy_skill_perk/professional/medicine
	skill_type = /datum/cy_skill/professional/medicine

/datum/cy_skill_perk/professional/medicine/level_1
	id = "medicine_1"
	level = 1
	name = "Medicine 1"
	desc_template = "No visual examine penalty; no surgery failure penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/medicine/level_2
	id = "medicine_2"
	level = 2
	name = "Medicine 2"
	desc_template = "+{value_1}% base surgery success, +{value_2}% surgery step speed."
	effects = list(
		"level" = 2,
		"value_1" = 20,
		"value_2" = 15
	)

/datum/cy_skill_perk/professional/medicine/level_3
	id = "medicine_3"
	level = 3
	name = "Medicine 3"
	desc_template = "Advanced surgeries unlocked at {value_1}% failure risk; +{value_2}% surgery step speed."
	effects = list(
		"level" = 3,
		"value_1" = 50,
		"value_2" = 20
	)

/datum/cy_skill_perk/professional/medicine/level_4
	id = "medicine_4"
	level = 4
	name = "Medicine 4"
	desc_template = "+{value_1}% total surgery success, self-surgery allowed, infection chance -{value_2}%."
	effects = list(
		"level" = 4,
		"value_1" = 30,
		"value_2" = 25
	)

/datum/cy_skill_perk/professional/medicine/level_5
	id = "medicine_5"
	level = 5
	name = "Medicine 5"
	desc_template = "Specialized surgeries unlocked; +{value_1}% base surgery success; environment no longer affects infection chance."
	effects = list(
		"level" = 5,
		"value_1" = 20
	)

/datum/cy_skill_perk/professional/medicine/level_6
	id = "medicine_6"
	level = 6
	name = "Medicine 6"
	desc_template = "Environment no longer affects surgery speed or failure chance; all tool compatibility +{value_1}%."
	effects = list(
		"level" = 6,
		"value_1" = 30
	)
