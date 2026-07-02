GLOBAL_LIST_INIT(attribute_types, subtypesof(/datum/attribute))

/datum/attribute
	var/id = "attribute"
	var/name = "Attribute"
	var/description = "A character attribute."
	var/base_value = ATTRIBUTE_DEFAULT
	var/value = ATTRIBUTE_DEFAULT
	var/super_mode = FALSE

/datum/attribute/New(starting_value = ATTRIBUTE_DEFAULT)
	. = ..()
	set_value(starting_value)

/datum/attribute/proc/set_value(new_value)
	value = clamp(round(new_value), ATTRIBUTE_MINIMUM, ATTRIBUTE_MAXIMUM)
	update_super_mode()
	return value

/datum/attribute/proc/adjust_value(amount)
	return set_value(value + amount)

/datum/attribute/proc/update_super_mode()
	super_mode = value >= ATTRIBUTE_SUPER_THRESHOLD
	return super_mode

/datum/attribute/strength
	id = ATTRIBUTE_STRENGTH
	name = "Strength"
	description = "Raw physical power and force."

/datum/attribute/dexterity
	id = ATTRIBUTE_DEXTERITY
	name = "Dexterity"
	description = "Speed, agility and fine movement."

/datum/attribute/perception
	id = ATTRIBUTE_PERCEPTION
	name = "Perception"
	description = "Awareness, precision and weak point reading."

/datum/attribute/intelligence
	id = ATTRIBUTE_INTELLIGENCE
	name = "Intelligence"
	description = "Code, hacking and technical reasoning."

/datum/attribute/spirit
	id = ATTRIBUTE_SPIRIT
	name = "Spirit"
	description = "Survival, endurance and compatibility."

/datum/attribute/charisma
	id = ATTRIBUTE_CHARISMA
	name = "Charisma"
	description = "Social presence, style and inspiration."
