/datum/cy_skill_perk/physical/hacking
	skill_type = /datum/cy_skill/intelligence/hacking

/datum/cy_skill_perk/physical/hacking/level_1
	id = "hacking_1"
	level = 1
	name = "Hacking 1"
	desc_template = "No +{value_1}% hacking-chain break penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/hacking/level_2
	id = "hacking_2"
	level = 2
	name = "Hacking 2"
	desc_template = "Hacking-chain break chance -{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/hacking/level_3
	id = "hacking_3"
	level = 3
	name = "Hacking 3"
	desc_template = "Hacking timer +{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/hacking/level_4
	id = "hacking_4"
	level = 4
	name = "Hacking 4"
	desc_template = "Remote hacking unlocked."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/physical/hacking/level_5
	id = "hacking_5"
	level = 5
	name = "Hacking 5"
	desc_template = "On failure, {value_1}% chance alarm does not trigger."
	effects = list(
		"level" = 5,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/hacking/level_6
	id = "hacking_6"
	level = 6
	name = "Hacking 6"
	desc_template = "Successful hack has {value_1}% chance to grant instant-hack charge."
	effects = list(
		"level" = 6,
		"value_1" = 10
	)
