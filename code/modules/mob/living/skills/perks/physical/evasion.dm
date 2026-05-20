/datum/cy_skill_perk/physical/evasion
	skill_type = /datum/cy_skill/dexterity/evasion

/datum/cy_skill_perk/physical/evasion/level_1
	id = "evasion_1"
	level = 1
	name = "Evasion 1"
	desc_template = "No +{value_1}% balance-loss chance after successful dodge."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/evasion/level_2
	id = "evasion_2"
	level = 2
	name = "Evasion 2"
	desc_template = "Successful dodge stamina cost -{value_1}%, failed dodge cost -{value_2}%."
	effects = list(
		"level" = 2,
		"value_1" = 20,
		"value_2" = 10
	)

/datum/cy_skill_perk/physical/evasion/level_3
	id = "evasion_3"
	level = 3
	name = "Evasion 3"
	desc_template = "Dodge success chance +{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 15
	)

/datum/cy_skill_perk/physical/evasion/level_4
	id = "evasion_4"
	level = 4
	name = "Evasion 4"
	desc_template = "{value_1}% chance that a dodged grab makes the attacker grab themselves."
	effects = list(
		"level" = 4,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/evasion/level_5
	id = "evasion_5"
	level = 5
	name = "Evasion 5"
	desc_template = "Can dodge unseen attackers; successful dodge does not move the dodger."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/evasion/level_6
	id = "evasion_6"
	level = 6
	name = "Evasion 6"
	desc_template = "Successful dodge has {value_1}% chance to hide you from attacker for {value_2} second; can dodge throws and shots."
	effects = list(
		"level" = 6,
		"value_1" = 20,
		"value_2" = 1
	)
