/datum/cy_skill_perk/physical/fast_melee
	skill_type = /datum/cy_skill/dexterity/fast_melee

/datum/cy_skill_perk/physical/fast_melee/level_1
	id = "fast_melee_1"
	level = 1
	name = "Fast Melee 1"
	desc_template = "No -{value_1}% untrained attack-speed penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/fast_melee/level_2
	id = "fast_melee_2"
	level = 2
	name = "Fast Melee 2"
	desc_template = "+{value_1}% dexterity value when calculating hand/implant attack cooldown."
	effects = list(
		"level" = 2,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/fast_melee/level_3
	id = "fast_melee_3"
	level = 3
	name = "Fast Melee 3"
	desc_template = "{value_1}% chance for a free kick after a normal punch."
	effects = list(
		"level" = 3,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/fast_melee/level_4
	id = "fast_melee_4"
	level = 4
	name = "Fast Melee 4"
	desc_template = "{value_1}% chance to counter-kick after successful dodge or parry."
	effects = list(
		"level" = 4,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/fast_melee/level_5
	id = "fast_melee_5"
	level = 5
	name = "Fast Melee 5"
	desc_template = "After a successful kick, hand attack cooldown is reduced by {value_1}%."
	effects = list(
		"level" = 5,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/fast_melee/level_6
	id = "fast_melee_6"
	level = 6
	name = "Fast Melee 6"
	desc_template = "Normal hits have {value_1}% and kicks have {value_2}% chance to briefly stun."
	effects = list(
		"level" = 6,
		"value_1" = 25,
		"value_2" = 10
	)
