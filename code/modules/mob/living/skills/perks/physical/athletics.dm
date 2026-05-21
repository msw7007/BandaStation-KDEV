/datum/cy_skill_perk/physical/athletics
	skill_type = /datum/cy_skill/spirit/athletics

/datum/cy_skill_perk/physical/athletics/level_1
	id = "athletics_1"
	level = 1
	name = "Athletics 1"
	desc_template = "No +{value_1}% stamina cost penalty for running or combat."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/athletics/level_2
	id = "athletics_2"
	level = 2
	name = "Athletics 2"
	desc_template = "Stamina reserve +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/athletics/level_2/on_gain(mob/living/owner)
	. = ..()
	var/multiplier = 1 + (get_val("value_1", 20) * 0.01)
	owner.max_stamina *= multiplier
	owner.cy_force_reserve_max *= multiplier
	owner.cy_force_reserve = min(owner.cy_force_reserve_max, owner.cy_force_reserve * multiplier)

/datum/cy_skill_perk/physical/athletics/level_2/on_loss(mob/living/owner)
	. = ..()
	var/multiplier = 1 + (get_val("value_1", 20) * 0.01)
	owner.max_stamina /= multiplier
	owner.cy_force_reserve_max /= multiplier
	owner.cy_force_reserve = min(owner.cy_force_reserve_max, owner.cy_force_reserve)

/datum/cy_skill_perk/physical/athletics/level_3
	id = "athletics_3"
	level = 3
	name = "Athletics 3"
	desc_template = "Carrying heavy things no longer slows movement."
	effects = list(
		"level" = 3,
	)

/datum/cy_skill_perk/physical/athletics/level_4
	id = "athletics_4"
	level = 4
	name = "Athletics 4"
	desc_template = "+{value_1}% sprint speed while stamina reserve is above {value_2}%."
	effects = list(
		"level" = 4,
		"value_1" = 20,
		"value_2" = 80
	)

/datum/cy_skill_perk/physical/athletics/level_5
	id = "athletics_5"
	level = 5
	name = "Athletics 5"
	desc_template = "Each reserve point restores {value_1} stamina if stamina is below {value_2}%."
	effects = list(
		"level" = 5,
		"value_1" = "2-3",
		"value_2" = 60
	)

/datum/cy_skill_perk/physical/athletics/level_6
	id = "athletics_6"
	level = 6
	name = "Athletics 6"
	desc_template = "Stamina regeneration delay -{value_1}%."
	effects = list(
		"level" = 6,
		"value_1" = 70
	)
