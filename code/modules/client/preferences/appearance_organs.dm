#define APPEARANCE_ORGAN_MIN_SIZE 0
#define APPEARANCE_ORGAN_MAX_SIZE 4

/datum/preference/numeric/appearance_organ_size
	abstract_type = /datum/preference/numeric/appearance_organ_size
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	minimum = APPEARANCE_ORGAN_MIN_SIZE
	maximum = APPEARANCE_ORGAN_MAX_SIZE
	step = 1
	can_randomize = FALSE
	var/organ_slot
	var/organ_type
	var/toggle_preference

/datum/preference/numeric/appearance_organ_size/create_default_value()
	return 1

/datum/preference/numeric/appearance_organ_size/apply_to_human(mob/living/carbon/human/target, value)
	var/enabled = TRUE
	var/list/current_organs = target.dna.features["appearance_organs"]
	if(toggle_preference && islist(current_organs) && islist(current_organs[organ_slot]))
		enabled = current_organs[organ_slot]["enabled"]
	if(toggle_preference)
		var/read_enabled = target.client?.prefs?.read_preference(toggle_preference)
		if(!isnull(read_enabled))
			enabled = read_enabled
	target.set_appearance_organ(organ_slot, organ_type, value, enabled)

/datum/preference/numeric/appearance_organ_size/breasts
	savefile_key = "breasts_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_BREASTS
	organ_type = /obj/item/organ/appearance_feature/breasts

/datum/preference/numeric/appearance_organ_size/penis
	savefile_key = "penis_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_PENIS
	organ_type = /obj/item/organ/appearance_feature/penis
	toggle_preference = /datum/preference/toggle/appearance_organ_enabled/penis

/datum/preference/numeric/appearance_organ_size/testicles
	savefile_key = "testicles_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_TESTICLES
	organ_type = /obj/item/organ/appearance_feature/testicles

/datum/preference/numeric/appearance_organ_size/butt
	savefile_key = "butt_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_BUTT
	organ_type = /obj/item/organ/appearance_feature/butt

/datum/preference/numeric/appearance_organ_size/belly
	savefile_key = "belly_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_BELLY
	organ_type = /obj/item/organ/appearance_feature/belly

/datum/preference/numeric/appearance_organ_size/vagina
	savefile_key = "vagina_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_VAGINA
	organ_type = /obj/item/organ/appearance_feature/vagina
	toggle_preference = /datum/preference/toggle/appearance_organ_enabled/vagina

/datum/preference/numeric/appearance_organ_size/anus
	savefile_key = "anus_size"
	organ_slot = ORGAN_SLOT_EXTERNAL_ANUS
	organ_type = /obj/item/organ/appearance_feature/anus

/datum/preference/toggle/appearance_organ_enabled
	abstract_type = /datum/preference/toggle/appearance_organ_enabled
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	default_value = FALSE
	can_randomize = FALSE
	var/size_preference
	var/organ_slot
	var/organ_type

/datum/preference/toggle/appearance_organ_enabled/apply_to_human(mob/living/carbon/human/target, value)
	var/size = target.client?.prefs?.read_preference(size_preference)
	if(isnull(size))
		size = 1
	target.set_appearance_organ(organ_slot, organ_type, size, value)

/datum/preference/toggle/appearance_organ_enabled/penis
	savefile_key = "penis_enabled"
	size_preference = /datum/preference/numeric/appearance_organ_size/penis
	organ_slot = ORGAN_SLOT_EXTERNAL_PENIS
	organ_type = /obj/item/organ/appearance_feature/penis

/datum/preference/toggle/appearance_organ_enabled/vagina
	savefile_key = "vagina_enabled"
	size_preference = /datum/preference/numeric/appearance_organ_size/vagina
	organ_slot = ORGAN_SLOT_EXTERNAL_VAGINA
	organ_type = /obj/item/organ/appearance_feature/vagina

#undef APPEARANCE_ORGAN_MIN_SIZE
#undef APPEARANCE_ORGAN_MAX_SIZE
