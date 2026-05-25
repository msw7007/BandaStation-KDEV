/datum/preference/choiced/species_feature/tail_felinid
	savefile_key = "feature_cat_tail"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	main_feature_name = "Cat tail"
	should_generate_icons = TRUE
	can_randomize = FALSE
	relevant_organ = /obj/item/organ/tail/cat

/datum/preference/choiced/species_feature/tail_felinid/icon_for(value)
	var/datum/sprite_accessory/cat_tail = get_accessory_for_value(value)
	var/datum/universal_icon/final_icon = uni_icon('icons/blanks/32x32.dmi', "nothing")

	if(isnull(cat_tail) || cat_tail.icon_state == SPRITE_ACCESSORY_NONE)
		return final_icon

	var/tail_icon_state = "m_tail_cat_[cat_tail.icon_state]_FRONT"
	if(!icon_exists(cat_tail.icon, tail_icon_state))
		tail_icon_state = "m_tail_cat_default_FRONT"

	if(icon_exists(cat_tail.icon, tail_icon_state))
		var/datum/universal_icon/tail_icon = uni_icon(cat_tail.icon, tail_icon_state)
		tail_icon.blend_color(COLOR_DARK_BROWN, ICON_MULTIPLY)
		final_icon.blend_icon(tail_icon, ICON_OVERLAY)

	return final_icon

/datum/preference/choiced/species_feature/felinid_ears
	savefile_key = "feature_cat_ears"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	main_feature_name = "Cat ears"
	should_generate_icons = TRUE
	can_randomize = FALSE
	relevant_organ = /obj/item/organ/ears/cat

/datum/preference/choiced/species_feature/felinid_ears/icon_for(value)
	var/static/datum/universal_icon/head_icon
	if(isnull(head_icon))
		head_icon = uni_icon('icons/mob/human/bodyparts_greyscale.dmi', "human_head_m")
		head_icon.blend_color(skintone2hex("caucasian1"), ICON_MULTIPLY)

	var/datum/sprite_accessory/cat_ears = get_accessory_for_value(value)
	var/datum/universal_icon/final_icon = head_icon.copy()

	if(!isnull(cat_ears) && cat_ears.icon_state != SPRITE_ACCESSORY_NONE)
		var/ears_icon_state = "m_ears_[cat_ears.icon_state]_FRONT"
		if(icon_exists(cat_ears.icon, ears_icon_state))
			var/datum/universal_icon/ears_icon = uni_icon(cat_ears.icon, ears_icon_state)
			ears_icon.blend_color(COLOR_DARK_BROWN, ICON_MULTIPLY)
			final_icon.blend_icon(ears_icon, ICON_OVERLAY)

		var/inner_ears_icon_state = "m_earsinner_[cat_ears.icon_state]_FRONT"
		if(icon_exists(cat_ears.icon, inner_ears_icon_state))
			final_icon.blend_icon(uni_icon(cat_ears.icon, inner_ears_icon_state), ICON_OVERLAY)

	final_icon.crop(10, 19, 22, 31)
	final_icon.scale(32, 32)

	return final_icon
