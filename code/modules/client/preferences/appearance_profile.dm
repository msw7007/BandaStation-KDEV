#define MAX_APPEARANCE_FLAVOR_LEN 4096
#define APPEARANCE_DESCRIPTOR_COUNT 4

#define APPEARANCE_DESCRIPTOR_NONE "plain"
#define APPEARANCE_DESCRIPTOR_TALL "tall"
#define APPEARANCE_DESCRIPTOR_SHORT "short"
#define APPEARANCE_DESCRIPTOR_ATHLETIC "athletic"
#define APPEARANCE_DESCRIPTOR_SLENDER "slender"
#define APPEARANCE_DESCRIPTOR_STOCKY "stocky"
#define APPEARANCE_DESCRIPTOR_GRACEFUL "graceful"
#define APPEARANCE_DESCRIPTOR_ROUGH "rough"
#define APPEARANCE_DESCRIPTOR_ELEGANT "elegant"
#define APPEARANCE_DESCRIPTOR_WEARY "weary"
#define APPEARANCE_DESCRIPTOR_ALERT "alert"
#define APPEARANCE_DESCRIPTOR_SCARRED "scarred"
#define APPEARANCE_DESCRIPTOR_TIDY "tidy"
#define APPEARANCE_DESCRIPTOR_UNKEMPT "unkempt"
#define APPEARANCE_DESCRIPTOR_SOFT "soft"
#define APPEARANCE_DESCRIPTOR_SHARP "sharp"

#define SPRITE_SIZE_SMALL "Small"
#define SPRITE_SIZE_MEDIUM "Medium"
#define SPRITE_SIZE_LARGE "Large"

#define SPRITE_WIDTH_NARROW "Narrow"
#define SPRITE_WIDTH_MEDIUM "Medium"
#define SPRITE_WIDTH_WIDE "Wide"

/datum/preference/text/flavor_text
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "flavor_text"
	maximum_value_length = MAX_APPEARANCE_FLAVOR_LEN

/datum/preference/text/flavor_text/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["flavor_text"] = value

/datum/preference/text/hidden_flavor_text
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hidden_flavor_text"
	maximum_value_length = MAX_APPEARANCE_FLAVOR_LEN

/datum/preference/text/hidden_flavor_text/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["hidden_flavor_text"] = value

/datum/preference/text/silicon_flavor_text
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "silicon_flavor_text"
	maximum_value_length = MAX_APPEARANCE_FLAVOR_LEN
	should_update_preview = FALSE

/datum/preference/text/silicon_flavor_text/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/choiced/appearance_descriptor
	abstract_type = /datum/preference/choiced/appearance_descriptor
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	can_randomize = FALSE
	var/descriptor_index = 0

/datum/preference/choiced/appearance_descriptor/init_possible_values()
	return list(
		APPEARANCE_DESCRIPTOR_NONE,
		APPEARANCE_DESCRIPTOR_TALL,
		APPEARANCE_DESCRIPTOR_SHORT,
		APPEARANCE_DESCRIPTOR_ATHLETIC,
		APPEARANCE_DESCRIPTOR_SLENDER,
		APPEARANCE_DESCRIPTOR_STOCKY,
		APPEARANCE_DESCRIPTOR_GRACEFUL,
		APPEARANCE_DESCRIPTOR_ROUGH,
		APPEARANCE_DESCRIPTOR_ELEGANT,
		APPEARANCE_DESCRIPTOR_WEARY,
		APPEARANCE_DESCRIPTOR_ALERT,
		APPEARANCE_DESCRIPTOR_SCARRED,
		APPEARANCE_DESCRIPTOR_TIDY,
		APPEARANCE_DESCRIPTOR_UNKEMPT,
		APPEARANCE_DESCRIPTOR_SOFT,
		APPEARANCE_DESCRIPTOR_SHARP,
	)

/datum/preference/choiced/appearance_descriptor/apply_to_human(mob/living/carbon/human/target, value)
	if(!islist(target.dna.features["appearance_descriptors"]))
		target.dna.features["appearance_descriptors"] = list()

	var/list/descriptors = target.dna.features["appearance_descriptors"]
	while(length(descriptors) < APPEARANCE_DESCRIPTOR_COUNT)
		descriptors += APPEARANCE_DESCRIPTOR_NONE

	descriptors[descriptor_index] = value

/datum/preference/choiced/appearance_descriptor/first
	savefile_key = "appearance_descriptor_1"
	descriptor_index = 1

/datum/preference/choiced/appearance_descriptor/first/create_default_value()
	return APPEARANCE_DESCRIPTOR_NONE

/datum/preference/choiced/appearance_descriptor/second
	savefile_key = "appearance_descriptor_2"
	descriptor_index = 2

/datum/preference/choiced/appearance_descriptor/second/create_default_value()
	return APPEARANCE_DESCRIPTOR_ALERT

/datum/preference/choiced/appearance_descriptor/third
	savefile_key = "appearance_descriptor_3"
	descriptor_index = 3

/datum/preference/choiced/appearance_descriptor/third/create_default_value()
	return APPEARANCE_DESCRIPTOR_TIDY

/datum/preference/choiced/appearance_descriptor/fourth
	savefile_key = "appearance_descriptor_4"
	descriptor_index = 4

/datum/preference/choiced/appearance_descriptor/fourth/create_default_value()
	return APPEARANCE_DESCRIPTOR_SOFT

/datum/preference/choiced/sprite_size
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_size"
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	can_randomize = FALSE

/datum/preference/choiced/sprite_size/init_possible_values()
	return list(
		SPRITE_SIZE_SMALL,
		SPRITE_SIZE_MEDIUM,
		SPRITE_SIZE_LARGE,
	)

/datum/preference/choiced/sprite_size/create_default_value()
	return SPRITE_SIZE_MEDIUM

/datum/preference/choiced/sprite_size/apply_to_human(mob/living/carbon/human/target, value)
	var/static/list/size_values = list(
		SPRITE_SIZE_SMALL = 0.9,
		SPRITE_SIZE_MEDIUM = RESIZE_DEFAULT_SIZE,
		SPRITE_SIZE_LARGE = 1.1,
	)

	target.set_sprite_size(size_values[value] || RESIZE_DEFAULT_SIZE)
	target.dna.features["sprite_size"] = value

/datum/preference/choiced/sprite_width
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_width"
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	can_randomize = FALSE

/datum/preference/choiced/sprite_width/init_possible_values()
	return list(
		SPRITE_WIDTH_NARROW,
		SPRITE_WIDTH_MEDIUM,
		SPRITE_WIDTH_WIDE,
	)

/datum/preference/choiced/sprite_width/create_default_value()
	return SPRITE_WIDTH_MEDIUM

/datum/preference/choiced/sprite_width/apply_to_human(mob/living/carbon/human/target, value)
	var/static/list/width_values = list(
		SPRITE_WIDTH_NARROW = 0.9,
		SPRITE_WIDTH_MEDIUM = RESIZE_DEFAULT_SIZE,
		SPRITE_WIDTH_WIDE = 1.1,
	)

	target.set_sprite_width(width_values[value] || RESIZE_DEFAULT_SIZE)
	target.dna.features["sprite_width"] = value

/datum/preference/color/tts_voice_color
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "tts_voice_color"
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/color/tts_voice_color/create_default_value()
	return COLOR_WHITE

/datum/preference/color/tts_voice_color/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["tts_voice_color"] = value
	var/datum/component/tts_component/tts_component = target.GetComponent(/datum/component/tts_component)
	if(tts_component)
		tts_component.voice_color = value

#undef MAX_APPEARANCE_FLAVOR_LEN
#undef APPEARANCE_DESCRIPTOR_COUNT

#undef APPEARANCE_DESCRIPTOR_NONE
#undef APPEARANCE_DESCRIPTOR_TALL
#undef APPEARANCE_DESCRIPTOR_SHORT
#undef APPEARANCE_DESCRIPTOR_ATHLETIC
#undef APPEARANCE_DESCRIPTOR_SLENDER
#undef APPEARANCE_DESCRIPTOR_STOCKY
#undef APPEARANCE_DESCRIPTOR_GRACEFUL
#undef APPEARANCE_DESCRIPTOR_ROUGH
#undef APPEARANCE_DESCRIPTOR_ELEGANT
#undef APPEARANCE_DESCRIPTOR_WEARY
#undef APPEARANCE_DESCRIPTOR_ALERT
#undef APPEARANCE_DESCRIPTOR_SCARRED
#undef APPEARANCE_DESCRIPTOR_TIDY
#undef APPEARANCE_DESCRIPTOR_UNKEMPT
#undef APPEARANCE_DESCRIPTOR_SOFT
#undef APPEARANCE_DESCRIPTOR_SHARP

#undef SPRITE_SIZE_SMALL
#undef SPRITE_SIZE_MEDIUM
#undef SPRITE_SIZE_LARGE

#undef SPRITE_WIDTH_NARROW
#undef SPRITE_WIDTH_MEDIUM
#undef SPRITE_WIDTH_WIDE
