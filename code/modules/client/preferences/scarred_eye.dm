/datum/preference/choiced/scarred_eye
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	savefile_key = "scarred_eye"
	savefile_identifier = PREFERENCE_CHARACTER

/datum/preference/choiced/scarred_eye/init_possible_values()
	return GLOB.scarred_eye_choice

/datum/preference/choiced/scarred_eye/create_default_value()
	return "Random"

/datum/preference/choiced/scarred_eye/is_accessible(datum/preferences/preferences)
	. = ..()
	if (!.)
		return FALSE

	return /datum/quirk/item_quirk/scarred_eye::name in preferences.all_quirks

/datum/preference/choiced/scarred_eye/apply_to_human(mob/living/carbon/human/target, value)
	var/obj/item/organ/eyes/eyes = target.get_organ_slot(ORGAN_SLOT_EYES)
	if (isnull(eyes))
		return

	eyes.fix_scar(RIGHT_EYE_SCAR)
	eyes.fix_scar(LEFT_EYE_SCAR)

	if (value == "Double")
		eyes.apply_scar(RIGHT_EYE_SCAR)
		eyes.apply_scar(LEFT_EYE_SCAR)
		return

	var/eye_side = value
	switch (eye_side)
		if ("Random")
			eye_side = pick(RIGHT_EYE_SCAR, LEFT_EYE_SCAR)
		if ("Right Eye")
			eye_side = RIGHT_EYE_SCAR
		if ("Left Eye")
			eye_side = LEFT_EYE_SCAR

	eyes.apply_scar(eye_side)
