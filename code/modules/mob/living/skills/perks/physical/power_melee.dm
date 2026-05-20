/datum/cy_skill_perk/physical/power_melee
	skill_type = /datum/cy_skill/strength/power_melee

/datum/cy_skill_perk/physical/power_melee/level_1
	id = "power_melee_1"
	level = 1
	name = "Power Melee 1"
	desc_template = "No -{value_1}% untrained punch-force penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/power_melee/level_2
	id = "power_melee_2"
	level = 2
	name = "Power Melee 2"
	desc_template = "+{value_1}% strength value when calculating hand/implant punch force."
	effects = list(
		"level" = 2,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/power_melee/level_3
	id = "power_melee_3"
	level = 3
	name = "Power Melee 3"
	desc_template = "On hit or parry, deal extra equipment pressure equal to {value_1}% strength."
	effects = list(
		"level" = 3,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/power_melee/level_4
	id = "power_melee_4"
	level = 4
	name = "Power Melee 4"
	desc_template = "On hit, {value_1}% chance to stagger the target."
	effects = list(
		"level" = 4,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/power_melee/level_5
	id = "power_melee_5"
	level = 5
	name = "Power Melee 5"
	desc_template = "Hitting a staggered target has {value_1}% chance to stun."
	effects = list(
		"level" = 5,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/power_melee/level_6
	id = "power_melee_6"
	level = 6
	name = "Power Melee 6"
	desc_template = "Hitting a stunned target has {value_1}% chance to uppercut and knock down."
	effects = list(
		"level" = 6,
		"value_1" = 50
	)
