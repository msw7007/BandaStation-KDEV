#define BODY_HEIGHT_SHORTEST "Shortest"
#define BODY_HEIGHT_SHORT "Short"
#define BODY_HEIGHT_MEDIUM "Medium"
#define BODY_HEIGHT_TALL "Tall"
#define BODY_HEIGHT_TALLER "Taller"

/datum/preference/choiced/body_height
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	savefile_key = "body_height"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE

/datum/preference/choiced/body_height/init_possible_values()
	return list(
		BODY_HEIGHT_SHORTEST,
		BODY_HEIGHT_SHORT,
		BODY_HEIGHT_MEDIUM,
		BODY_HEIGHT_TALL,
		BODY_HEIGHT_TALLER,
	)

/datum/preference/choiced/body_height/create_default_value()
	return BODY_HEIGHT_MEDIUM

/datum/preference/choiced/body_height/apply_to_human(mob/living/carbon/human/target, value)
	var/static/list/height_values = list(
		BODY_HEIGHT_SHORTEST = HUMAN_HEIGHT_SHORTEST,
		BODY_HEIGHT_SHORT = HUMAN_HEIGHT_SHORT,
		BODY_HEIGHT_MEDIUM = HUMAN_HEIGHT_MEDIUM,
		BODY_HEIGHT_TALL = HUMAN_HEIGHT_TALL,
		BODY_HEIGHT_TALLER = HUMAN_HEIGHT_TALLER,
	)

	target.set_mob_height(height_values[value] || HUMAN_HEIGHT_MEDIUM)

#undef BODY_HEIGHT_SHORTEST
#undef BODY_HEIGHT_SHORT
#undef BODY_HEIGHT_MEDIUM
#undef BODY_HEIGHT_TALL
#undef BODY_HEIGHT_TALLER
