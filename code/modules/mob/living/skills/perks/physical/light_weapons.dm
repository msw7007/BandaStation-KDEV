/datum/cy_skill_perk/physical/light_weapons
	skill_type = /datum/cy_skill/dexterity/light_weapons

/datum/cy_skill_perk/physical/light_weapons/level_1
	id = "light_weapons_1"
	level = 1
	name = "Light Weapons 1"
	desc_template = "No -{value_1}% reload speed and +{value_2}% energy-use penalty."
	effects = list(
		"level" = 1,
		"value_1" = 30,
		"value_2" = 20
	)

/datum/cy_skill_perk/physical/light_weapons/level_2
	id = "light_weapons_2"
	level = 2
	name = "Light Weapons 2"
	desc_template = "Melee/butt attack cooldown adds +{value_1}% dexterity."
	effects = list(
		"level" = 2,
		"value_1" = 50
	)

/datum/cy_skill_perk/physical/light_weapons/level_3
	id = "light_weapons_3"
	level = 3
	name = "Light Weapons 3"
	desc_template = "{value_1}% chance for a free repeat shot or strike."
	effects = list(
		"level" = 3,
		"value_1" = 25
	)

/datum/cy_skill_perk/physical/light_weapons/level_4
	id = "light_weapons_4"
	level = 4
	name = "Light Weapons 4"
	desc_template = "Hip-fire while running has no accuracy/spread penalty."
	effects = list(
		"level" = 4,
	)

/datum/cy_skill_perk/physical/light_weapons/level_5
	id = "light_weapons_5"
	level = 5
	name = "Light Weapons 5"
	desc_template = "Reload and weapon swap do not start cooldown for non-two-handed weapons."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/physical/light_weapons/level_6
	id = "light_weapons_6"
	level = 6
	name = "Light Weapons 6"
	desc_template = "Can attack and shoot during other long actions."
	effects = list(
		"level" = 6,
	)
