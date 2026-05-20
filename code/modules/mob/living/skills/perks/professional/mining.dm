/datum/cy_skill_perk/professional/mining
	skill_type = /datum/cy_skill/professional/mining

/datum/cy_skill_perk/professional/mining/level_1
	id = "mining_1"
	level = 1
	name = "Mining 1"
	desc_template = "No mining time penalty and no extra empty-yield penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/mining/level_2
	id = "mining_2"
	level = 2
	name = "Mining 2"
	desc_template = "Mining time -{value_1}%; pick use pulls you to the mined tile; drill starts faster."
	effects = list(
		"level" = 2,
		"value_1" = 25
	)

/datum/cy_skill_perk/professional/mining/level_3
	id = "mining_3"
	level = 3
	name = "Mining 3"
	desc_template = "{value_1}% chance to turn empty yield into resource; {value_2}% chance to duplicate mined resource."
	effects = list(
		"level" = 3,
		"value_1" = 2,
		"value_2" = 10
	)

/datum/cy_skill_perk/professional/mining/level_4
	id = "mining_4"
	level = 4
	name = "Mining 4"
	desc_template = "Can see ore richness; rich ore improves empty-yield conversion."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/professional/mining/level_5
	id = "mining_5"
	level = 5
	name = "Mining 5"
	desc_template = "+{value_1}% base empty-to-resource chance; resource duplication chance rises to {value_2}%."
	effects = list(
		"level" = 5,
		"value_1" = 1,
		"value_2" = 25
	)

/datum/cy_skill_perk/professional/mining/level_6
	id = "mining_6"
	level = 6
	name = "Mining 6"
	desc_template = "Mining speed reduced to {value_1}% of base time; drills and picks do not break; drill primes instantly and uses {value_2}% less energy."
	effects = list(
		"level" = 6,
		"value_1" = 25,
		"value_2" = 25
	)
