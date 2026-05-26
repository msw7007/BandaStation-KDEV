#define BODY_SHAPE_AVERAGE "average"
#define BODY_SHAPE_LEAN "lean"
#define BODY_SHAPE_STOCKY "stocky"
#define BODY_SHAPE_SOFT "soft"
#define BODY_SHAPE_ANGULAR "angular"
#define CORP_ALIGN_NONE "none"
#define CORP_ALIGN_SUN_YON "sun_yon"
#define CORP_ALIGN_ISHIKAWA "ishikawa"
#define CORP_ALIGN_HO_SHI "ho_shi"
#define CORP_ALIGN_KOWALSKI "kowalski"
#define CORP_ALIGN_TYAZHMARSH "tyazhmarsh"
#define CORP_ALIGN_TESLA_SCIENCE "tesla_science"
#define CORP_ALIGN_BLACKROCK_INVESTIGATE "blackrock_investigate"
#define CORP_ALIGN_TRANS_TRAVEL "trans_travel"
#define CORP_ALIGN_SAMANTHAS_KEIR "samanthas_keir"

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

/proc/corp_align_choices()
	return list(
		CORP_ALIGN_NONE = "Независимый",
		CORP_ALIGN_SUN_YON = "Сан Йон Корпорейшн",
		CORP_ALIGN_ISHIKAWA = "Ишикава Индастриз",
		CORP_ALIGN_HO_SHI = "Хо Ши Текнолоджис",
		CORP_ALIGN_KOWALSKI = "Ковальски и Ко",
		CORP_ALIGN_TYAZHMARSH = "ТяжМарш Продакшен",
		CORP_ALIGN_TESLA_SCIENCE = "Тесла Саенс",
		CORP_ALIGN_BLACKROCK_INVESTIGATE = "Блэкрок Инвестигейт",
		CORP_ALIGN_TRANS_TRAVEL = "Транс Трэвел",
		CORP_ALIGN_SAMANTHAS_KEIR = "Самантас Кеир",
	)

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

/datum/preference/choiced/corp_align
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "corp_align"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/corp_align/init_possible_values()
	return assoc_to_keys(corp_align_choices())

/datum/preference/choiced/corp_align/create_default_value()
	return CORP_ALIGN_NONE

/datum/preference/choiced/corp_align/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = corp_align_choices()
	return data

/datum/preference/choiced/corp_align/apply_to_human(mob/living/carbon/human/target, value)
	target.corp_align = value == CORP_ALIGN_NONE ? null : value
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = target.get_organ_slot(ORGAN_SLOT_NEURAL_IMPLANT)
	if(istype(neural_interface))
		neural_interface.corp_manufacturer = value == CORP_ALIGN_NONE ? initial(neural_interface.corp_manufacturer) : value

#undef BODY_SHAPE_AVERAGE
#undef BODY_SHAPE_LEAN
#undef BODY_SHAPE_STOCKY
#undef BODY_SHAPE_SOFT
#undef BODY_SHAPE_ANGULAR
#undef CORP_ALIGN_NONE
#undef CORP_ALIGN_SUN_YON
#undef CORP_ALIGN_ISHIKAWA
#undef CORP_ALIGN_HO_SHI
#undef CORP_ALIGN_KOWALSKI
#undef CORP_ALIGN_TYAZHMARSH
#undef CORP_ALIGN_TESLA_SCIENCE
#undef CORP_ALIGN_BLACKROCK_INVESTIGATE
#undef CORP_ALIGN_TRANS_TRAVEL
#undef CORP_ALIGN_SAMANTHAS_KEIR
