/datum/cy_skill_perk/physical/toughness
	skill_type = /datum/cy_skill/strength/toughness

/datum/cy_skill_perk/physical/toughness/level_1
	id = "toughness_1"
	level = 1
	name = "Toughness 1"
	desc_template = "No +{value_1}% incoming damage penalty."
	effects = list(
		"level" = 1,
		"value_1" = 10
	)

/datum/cy_skill_perk/physical/toughness/level_2
	id = "toughness_2"
	level = 2
	name = "Toughness 2"
	desc_template = "Internal organ health +{value_1}%."
	effects = list(
		"level" = 2,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/toughness/level_2/on_gain(mob/living/owner)
	. = ..()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbon_owner = owner
	var/health_multiplier = 1 + (get_val("value_1", 20) * 0.01)
	for(var/obj/item/organ/organ as anything in carbon_owner.organs)
		organ.maxHealth *= health_multiplier

/datum/cy_skill_perk/physical/toughness/level_2/on_loss(mob/living/owner)
	. = ..()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbon_owner = owner
	var/health_multiplier = 1 + (get_val("value_1", 20) * 0.01)
	for(var/obj/item/organ/organ as anything in carbon_owner.organs)
		organ.maxHealth /= health_multiplier

/datum/cy_skill_perk/physical/toughness/level_3
	id = "toughness_3"
	level = 3
	name = "Toughness 3"
	desc_template = "Stagger duration -{value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/toughness/level_4
	id = "toughness_4"
	level = 4
	name = "Toughness 4"
	desc_template = "Limb critical-wound thresholds +{value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/toughness/level_5
	id = "toughness_5"
	level = 5
	name = "Toughness 5"
	desc_template = "Incoming grabs automatically lose {value_1}% strength."
	effects = list(
		"level" = 5,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/toughness/level_6
	id = "toughness_6"
	level = 6
	name = "Toughness 6"
	desc_template = "Character takes {value_1}% less damage."
	effects = list(
		"level" = 6,
		"value_1" = 20
	)
