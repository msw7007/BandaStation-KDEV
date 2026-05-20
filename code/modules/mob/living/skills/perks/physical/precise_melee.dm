/datum/cy_skill_perk/physical/precise_melee
	skill_type = /datum/cy_skill/perception/precise_melee

/datum/cy_skill_perk/physical/precise_melee/level_1
	id = "precise_melee_1"
	level = 1
	name = "Precise Melee 1"
	desc_template = "No -{value_1}% untrained hit accuracy penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/precise_melee/level_2
	id = "precise_melee_2"
	level = 2
	name = "Precise Melee 2"
	desc_template = "+{value_1}% perception value when calculating hand/implant accuracy."
	effects = list(
		"level" = 2,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/precise_melee/level_3
	id = "precise_melee_3"
	level = 3
	name = "Precise Melee 3"
	desc_template = "Hand hit has {value_1}% chance to apply extra pain."
	effects = list(
		"level" = 3,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/precise_melee/level_4
	id = "precise_melee_4"
	level = 4
	name = "Precise Melee 4"
	desc_template = "Leg hits have {value_1}% chance to slow; arm hits have {value_2}% chance to disable the arm briefly."
	effects = list(
		"level" = 4,
		"value_1" = 50,
		"value_2" = 20
	)

/datum/cy_skill_perk/physical/precise_melee/level_5
	id = "precise_melee_5"
	level = 5
	name = "Precise Melee 5"
	desc_template = "Head hits have {value_1}% chance to disorient."
	effects = list(
		"level" = 5,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/precise_melee/level_6
	id = "precise_melee_6"
	level = 6
	name = "Precise Melee 6"
	desc_template = "Limb proc chances +{value_1}%; torso hits can immobilize."
	effects = list(
		"level" = 6,
		"value_1" = 10
	)
