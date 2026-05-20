/datum/cy_skill_perk/physical/heavy_weapons
	skill_type = /datum/cy_skill/strength/heavy_weapons

/datum/cy_skill_perk/physical/heavy_weapons/level_1
	id = "heavy_weapons_1"
	level = 1
	name = "Heavy Weapons 1"
	desc_template = "No -{value_1}% movement speed penalty while holding weapons."
	effects = list(
		"level" = 1,
		"value_1" = 30
	)

/datum/cy_skill_perk/physical/heavy_weapons/level_2
	id = "heavy_weapons_2"
	level = 2
	name = "Heavy Weapons 2"
	desc_template = "Melee weapon and butt hits add +{value_1}% strength to force."
	effects = list(
		"level" = 2,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/heavy_weapons/level_3
	id = "heavy_weapons_3"
	level = 3
	name = "Heavy Weapons 3"
	desc_template = "{value_1}% chance to break enemy parry and deal direct damage with weapon hits."
	effects = list(
		"level" = 3,
		"value_1" = 20
	)

/datum/cy_skill_perk/physical/heavy_weapons/level_4
	id = "heavy_weapons_4"
	level = 4
	name = "Heavy Weapons 4"
	desc_template = "Firearm deviation -{value_1}%; melee weapon stamina cost -{value_2}%."
	effects = list(
		"level" = 4,
		"value_1" = 30,
		"value_2" = 20
	)

/datum/cy_skill_perk/physical/heavy_weapons/level_5
	id = "heavy_weapons_5"
	level = 5
	name = "Heavy Weapons 5"
	desc_template = "Weapon hits, including throws, gain +{value_1}% chance for tier-{value_2} critical wound."
	effects = list(
		"level" = 5,
		"value_1" = 20,
		"value_2" = 2
	)

/datum/cy_skill_perk/physical/heavy_weapons/level_6
	id = "heavy_weapons_6"
	level = 6
	name = "Heavy Weapons 6"
	desc_template = "Heavy firearm movement deviation reduced to {value_1}%; melee weapons have {value_2}% chance to knock down."
	effects = list(
		"level" = 6,
		"value_1" = 10,
		"value_2" = 10
	)
