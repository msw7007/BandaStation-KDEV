#define LIP_STYLE_NONE "None"
#define LIP_STYLE_FULL "Full"
#define LIP_STYLE_UPPER "Upper"
#define LIP_STYLE_LOWER "Lower"

/datum/preference/choiced/lip_style
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	savefile_key = "lip_style"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE

/datum/preference/choiced/lip_style/init_possible_values()
	return list(
		LIP_STYLE_NONE,
		LIP_STYLE_FULL,
		LIP_STYLE_UPPER,
		LIP_STYLE_LOWER,
	)

/datum/preference/choiced/lip_style/create_default_value()
	return LIP_STYLE_NONE

/datum/preference/choiced/lip_style/apply_to_human(mob/living/carbon/human/target, value)
	target.update_lips(get_lip_style(value), target.lip_color, null, update = FALSE)

/datum/preference/choiced/lip_style/proc/get_lip_style(value)
	switch(value)
		if(LIP_STYLE_FULL)
			return "lipstick"
		if(LIP_STYLE_UPPER)
			return "lipstick_upper"
		if(LIP_STYLE_LOWER)
			return "lipstick_lower"

	return null

/datum/preference/color/lip_color
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	savefile_key = "lip_color"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE

/datum/preference/color/lip_color/create_default_value()
	return COLOR_WHITE

/datum/preference/color/lip_color/is_accessible(datum/preferences/preferences)
	if(!..(preferences))
		return FALSE

	return preferences.read_preference(/datum/preference/choiced/lip_style) != LIP_STYLE_NONE

/datum/preference/color/lip_color/apply_to_human(mob/living/carbon/human/target, value)
	target.update_lips(target.lip_style, value, null, update = FALSE)

#undef LIP_STYLE_NONE
#undef LIP_STYLE_FULL
#undef LIP_STYLE_UPPER
#undef LIP_STYLE_LOWER
