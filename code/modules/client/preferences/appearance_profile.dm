#define BODY_SHAPE_AVERAGE "average"
#define BODY_SHAPE_LEAN "lean"
#define BODY_SHAPE_STOCKY "stocky"
#define BODY_SHAPE_SOFT "soft"
#define BODY_SHAPE_ANGULAR "angular"

/proc/body_descriptor_choices()
	return list(
		"scarred",
		"clean",
		"wiry",
		"heavy",
		"elegant",
		"tired",
		"nervous",
		"calm",
		"augmented",
		"unremarkable",
	)

/proc/incognito_adjective_choices()
	return list("unknown", "masked", "hooded", "armored", "quiet", "rough", "slender", "broad")

/proc/incognito_noun_choices()
	return list("figure", "stranger", "person", "silhouette", "operator", "worker", "merc")

/proc/voice_adjective_choices()
	return list("unknown", "raspy", "soft", "sharp", "low", "cold", "warm", "metallic")

/proc/voice_noun_choices()
	return list("voice", "speaker", "whisper", "tone", "accent", "murmur")

/datum/preference/numeric/sprite_size
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_size"
	minimum = 0.85
	maximum = 1.15
	step = 0.01

/datum/preference/numeric/sprite_size/create_default_value()
	return 1

/datum/preference/numeric/sprite_size/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_size = value
	target.apply_preference_sprite_scale()

/datum/preference/numeric/sprite_height
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_height"
	minimum = 0.9
	maximum = 1.1
	step = 0.01

/datum/preference/numeric/sprite_height/create_default_value()
	return 1

/datum/preference/numeric/sprite_height/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_height = value
	target.apply_preference_sprite_scale()

/datum/preference/numeric/sprite_width
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_width"
	minimum = 0.9
	maximum = 1.1
	step = 0.01

/datum/preference/numeric/sprite_width/create_default_value()
	return 1

/datum/preference/numeric/sprite_width/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_width = value
	target.apply_preference_sprite_scale()

/datum/preference/choiced/body_shape
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "body_shape"

/datum/preference/choiced/body_shape/init_possible_values()
	return list(BODY_SHAPE_AVERAGE, BODY_SHAPE_LEAN, BODY_SHAPE_STOCKY, BODY_SHAPE_SOFT, BODY_SHAPE_ANGULAR)

/datum/preference/choiced/body_shape/create_default_value()
	return BODY_SHAPE_AVERAGE

/datum/preference/choiced/body_shape/apply_to_human(mob/living/carbon/human/target, value)
	target.body_shape = value

/datum/preference/choiced/appearance_descriptor
	abstract_type = /datum/preference/choiced/appearance_descriptor
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	randomize_by_default = FALSE
	should_update_preview = FALSE
	var/descriptor_index = 1

/datum/preference/choiced/appearance_descriptor/init_possible_values()
	return body_descriptor_choices()

/datum/preference/choiced/appearance_descriptor/create_default_value()
	return "unremarkable"

/datum/preference/choiced/appearance_descriptor/apply_to_human(mob/living/carbon/human/target, value)
	LAZYINITLIST(target.appearance_descriptors)
	target.appearance_descriptors.len = max(target.appearance_descriptors.len, 4)
	target.appearance_descriptors[descriptor_index] = value

/datum/preference/choiced/appearance_descriptor/one
	savefile_key = "appearance_descriptor_1"
	descriptor_index = 1

/datum/preference/choiced/appearance_descriptor/two
	savefile_key = "appearance_descriptor_2"
	descriptor_index = 2

/datum/preference/choiced/appearance_descriptor/three
	savefile_key = "appearance_descriptor_3"
	descriptor_index = 3

/datum/preference/choiced/appearance_descriptor/four
	savefile_key = "appearance_descriptor_4"
	descriptor_index = 4

/datum/preference/text/flavor_text
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "flavor_text"
	maximum_value_length = 1024
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/text/flavor_text/apply_to_human(mob/living/carbon/human/target, value)
	target.flavor_text = value

/datum/preference/choiced/incognito_adjective
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "incognito_adjective"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/incognito_adjective/init_possible_values()
	return incognito_adjective_choices()

/datum/preference/choiced/incognito_adjective/create_default_value()
	return "unknown"

/datum/preference/choiced/incognito_adjective/apply_to_human(mob/living/carbon/human/target, value)
	target.incognito_adjective = value

/datum/preference/choiced/incognito_noun
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "incognito_noun"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/incognito_noun/init_possible_values()
	return incognito_noun_choices()

/datum/preference/choiced/incognito_noun/create_default_value()
	return "figure"

/datum/preference/choiced/incognito_noun/apply_to_human(mob/living/carbon/human/target, value)
	target.incognito_noun = value

/datum/preference/choiced/voice_adjective
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_adjective"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/voice_adjective/init_possible_values()
	return voice_adjective_choices()

/datum/preference/choiced/voice_adjective/create_default_value()
	return "unknown"

/datum/preference/choiced/voice_adjective/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_adjective = value

/datum/preference/choiced/voice_noun
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_noun"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/voice_noun/init_possible_values()
	return voice_noun_choices()

/datum/preference/choiced/voice_noun/create_default_value()
	return "voice"

/datum/preference/choiced/voice_noun/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_noun = value

/datum/preference/color/voice_color
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_color"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/color/voice_color/create_default_value()
	return "c8c8c8"

/datum/preference/color/voice_color/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_color = "#[value]"

#undef BODY_SHAPE_AVERAGE
#undef BODY_SHAPE_LEAN
#undef BODY_SHAPE_STOCKY
#undef BODY_SHAPE_SOFT
#undef BODY_SHAPE_ANGULAR
