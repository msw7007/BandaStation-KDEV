/proc/generate_icon_with_head_accessory(datum/sprite_accessory/sprite_accessory, y_offset = 0)
	var/static/datum/universal_icon/head_icon
	if (isnull(head_icon))
		head_icon = uni_icon('icons/mob/human/bodyparts_greyscale.dmi', "human_head_m")
		head_icon.blend_color(skintone2hex("caucasian1"), ICON_MULTIPLY)

	var/datum/universal_icon/final_icon = head_icon.copy()
	if (!isnull(sprite_accessory) && sprite_accessory.icon_state != SPRITE_ACCESSORY_NONE)
		ASSERT(istype(sprite_accessory))

		var/datum/universal_icon/head_accessory_icon = uni_icon(sprite_accessory.icon, sprite_accessory.icon_state)
		if(y_offset)
			head_accessory_icon.shift(NORTH, y_offset)
		head_accessory_icon.blend_color(COLOR_DARK_BROWN, ICON_MULTIPLY)
		final_icon.blend_icon(head_accessory_icon, ICON_OVERLAY)

	final_icon.crop(10, 19, 22, 31)
	final_icon.scale(32, 32)

	return final_icon

/datum/preference/color/eye_color
	priority = PREFERENCE_PRIORITY_BODYPARTS
	savefile_key = "eye_color"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	relevant_head_flag = HEAD_EYECOLOR

/datum/preference/color/eye_color/apply_to_human(mob/living/carbon/human/target, value)
	var/hetero = target.eye_color_heterochromatic
	target.eye_color_left = value
	if(!hetero)
		target.eye_color_right = value

	var/obj/item/organ/eyes/eyes_organ = target.get_organ_by_type(/obj/item/organ/eyes)
	if (!eyes_organ || !istype(eyes_organ))
		return

	if (!initial(eyes_organ.eye_color_left))
		eyes_organ.eye_color_left = value

	if(hetero) // Don't override the snowflakes please
		return

	if (!initial(eyes_organ.eye_color_right))
		eyes_organ.eye_color_right = value
	eyes_organ.refresh()

/datum/preference/color/eye_color/create_default_value()
	return random_eye_color()

/datum/preference/choiced/facial_hairstyle
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	savefile_key = "facial_style_name"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Лицевая растительность"
	should_generate_icons = TRUE
	relevant_head_flag = HEAD_FACIAL_HAIR

/datum/preference/choiced/facial_hairstyle/init_possible_values()
	return assoc_to_keys_features(SSaccessories.facial_hairstyles_list)

/datum/preference/choiced/facial_hairstyle/icon_for(value)
	return generate_icon_with_head_accessory(SSaccessories.facial_hairstyles_list[value])

/datum/preference/choiced/facial_hairstyle/apply_to_human(mob/living/carbon/human/target, value)
	target.set_facial_hairstyle(value, update = FALSE)

/datum/preference/choiced/facial_hairstyle/create_default_value()
	return /datum/sprite_accessory/facial_hair/shaved::name

/datum/preference/choiced/facial_hairstyle/create_informed_default_value(datum/preferences/preferences)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/species_type = preferences.read_preference(/datum/preference/choiced/species)
	var/datum/species/species_real = GLOB.species_prototypes[species_type]
	if(!gender || !species_real || !species_real.sexes)
		return ..()

	var/picked_beard = random_facial_hairstyle(gender)
	var/datum/sprite_accessory/beard_style = SSaccessories.facial_hairstyles_list[picked_beard]
	if(!beard_style || !beard_style.natural_spawn || beard_style.locked) // Invalid, go with god(bald)
		return ..()

	return picked_beard

/datum/preference/choiced/facial_hairstyle/compile_constant_data()
	var/list/data = ..()

	data[SUPPLEMENTAL_FEATURE_KEY] = /datum/preference/color/facial_hair_color::savefile_key

	return data

/datum/preference/color/facial_hair_color
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE // Need to happen after hair oclor is set so we can match by default
	savefile_key = "facial_hair_color"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	relevant_head_flag = HEAD_FACIAL_HAIR

/datum/preference/color/facial_hair_color/apply_to_human(mob/living/carbon/human/target, value)
	target.set_facial_haircolor(value, update = FALSE)

/datum/preference/color/facial_hair_color/create_informed_default_value(datum/preferences/preferences)
	return preferences.read_preference(/datum/preference/color/hair_color) || random_hair_color()

/datum/preference/choiced/facial_hair_gradient
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "facial_hair_gradient"
	relevant_head_flag = HEAD_FACIAL_HAIR
	can_randomize = FALSE

/datum/preference/choiced/facial_hair_gradient/init_possible_values()
	return assoc_to_keys_features(SSaccessories.facial_hair_gradients_list)

/datum/preference/choiced/facial_hair_gradient/apply_to_human(mob/living/carbon/human/target, value)
	target.set_facial_hair_gradient_style(new_style = value, update = FALSE)

/datum/preference/choiced/facial_hair_gradient/create_default_value()
	return /datum/sprite_accessory/gradient/none::name

/datum/preference/color/facial_hair_gradient
	priority = PREFERENCE_PRORITY_LATE_BODY_TYPE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "facial_hair_gradient_color"
	relevant_head_flag = HEAD_FACIAL_HAIR

/datum/preference/color/facial_hair_gradient/apply_to_human(mob/living/carbon/human/target, value)
	target.set_facial_hair_gradient_color(new_color = value, update = FALSE)

/datum/preference/color/facial_hair_gradient/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE
	return preferences.read_preference(/datum/preference/choiced/facial_hair_gradient) != /datum/sprite_accessory/gradient/none::name

/datum/preference/color/hair_color
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	savefile_key = "hair_color"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	relevant_head_flag = HEAD_HAIR

/datum/preference/color/hair_color/has_relevant_feature(datum/preferences/preferences)
	return ..() || (/datum/quirk/item_quirk/bald::name in preferences.all_quirks)

/datum/preference/color/hair_color/apply_to_human(mob/living/carbon/human/target, value)
	target.set_haircolor(value, update = FALSE)

/datum/preference/color/hair_color/create_informed_default_value(datum/preferences/preferences)
	return random_hair_color()

/datum/preference/choiced/hairstyle
	priority = PREFERENCE_PRIORITY_BODY_TYPE // Happens after gender so we can picka hairstyle based on that
	savefile_key = "hairstyle_name"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	main_feature_name = "Прическа"
	should_generate_icons = TRUE
	relevant_head_flag = HEAD_HAIR

/datum/preference/choiced/hairstyle/has_relevant_feature(datum/preferences/preferences)
	return ..() || (/datum/quirk/item_quirk/bald::name in preferences.all_quirks)

/datum/preference/choiced/hairstyle/init_possible_values()
	cyberpunk_ensure_custom_hair_accessory()
	return assoc_to_keys_features(SSaccessories.hairstyles_list)

/datum/preference/choiced/hairstyle/deserialize(input, datum/preferences/preferences)
	cyberpunk_ensure_custom_hair_accessory()
	if(preferences)
		cyberpunk_register_custom_hair_designs(preferences.cyberpunk_read_custom_hair_designs())
	if(istext(input) && findtext(input, "Custom:") == 1)
		input = "Custom Hair"
	return ..()

/datum/preference/choiced/hairstyle/icon_for(value)
	if(value == "Custom Hair")
		return uni_icon('icons/obj/art/artstuff.dmi', "palette")
	var/datum/sprite_accessory/hair/hairstyle = SSaccessories.hairstyles_list[value]
	return generate_icon_with_head_accessory(hairstyle, hairstyle?.y_offset)

/datum/preference/choiced/hairstyle/apply_to_human(mob/living/carbon/human/target, value)
	target.set_hairstyle(value, update = FALSE)

/datum/preference/choiced/hairstyle/create_default_value()
	return /datum/sprite_accessory/hair/bald::name

/datum/preference/choiced/hairstyle/create_informed_default_value(datum/preferences/preferences)
	var/gender = preferences.read_preference(/datum/preference/choiced/gender)
	var/species_type = preferences.read_preference(/datum/preference/choiced/species)
	var/datum/species/species_real = GLOB.species_prototypes[species_type]
	if(!gender || !species_real || !species_real.sexes)
		return ..()

	var/picked_hair = random_hairstyle(gender)
	var/datum/sprite_accessory/hair_style = SSaccessories.hairstyles_list[picked_hair]
	if(!hair_style || !hair_style.natural_spawn || hair_style.locked) // Invalid, go with god(bald)
		return ..()

	return picked_hair

/datum/preference/choiced/hairstyle/compile_constant_data()
	var/list/data = ..()

	data[SUPPLEMENTAL_FEATURE_KEY] = /datum/preference/color/hair_color::savefile_key

	return data

/datum/preference/choiced/hair_gradient
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient"
	relevant_head_flag = HEAD_HAIR
	can_randomize = FALSE

/datum/preference/choiced/hair_gradient/init_possible_values()
	return assoc_to_keys_features(SSaccessories.hair_gradients_list)

/datum/preference/choiced/hair_gradient/apply_to_human(mob/living/carbon/human/target, value)
	target.set_hair_gradient_style(new_style = value, update = FALSE)

/datum/preference/choiced/hair_gradient/create_default_value()
	return /datum/sprite_accessory/gradient/none::name

/datum/preference/color/hair_gradient
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "hair_gradient_color"
	relevant_head_flag = HEAD_HAIR

/datum/preference/color/hair_gradient/apply_to_human(mob/living/carbon/human/target, value)
	target.set_hair_gradient_color(new_color = value, update = FALSE)

/datum/preference/color/hair_gradient/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE
	return preferences.read_preference(/datum/preference/choiced/hair_gradient) != /datum/sprite_accessory/gradient/none::name

/datum/preference/choiced/species_feature/human_tattoo
	abstract_type = /datum/preference/choiced/species_feature/human_tattoo
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_FEATURES
	should_generate_icons = TRUE

/datum/preference/choiced/species_feature/human_tattoo/icon_for(value)
	var/datum/sprite_accessory/sprite_accessory = get_accessory_for_value(value)
	var/datum/universal_icon/final_icon = uni_icon('icons/mob/human/bodyparts_greyscale.dmi', "human_chest_m")
	final_icon.blend_color(skintone2hex("caucasian1"), ICON_MULTIPLY)

	if(sprite_accessory?.icon_state != SPRITE_ACCESSORY_NONE)
		var/datum/universal_icon/tattoo_icon = uni_icon(
			sprite_accessory.icon,
			"male_[sprite_accessory.icon_state]_chest",
		)
		tattoo_icon.blend_color(COLOR_ALMOST_BLACK, ICON_MULTIPLY)
		final_icon.blend_icon(tattoo_icon, ICON_OVERLAY)

	final_icon.crop(10, 8, 22, 23)
	final_icon.scale(26, 32)
	final_icon.crop(-2, 1, 29, 32)
	return final_icon

/datum/preference/choiced/species_feature/human_tattoo/compile_constant_data()
	var/list/data = ..()
	data[SUPPLEMENTAL_FEATURE_KEY] = /datum/preference/color/human_tattoo_color::savefile_key
	return data

/datum/preference/choiced/species_feature/human_tattoo/head_1
	savefile_key = "feature_human_tattoo_head_1"
	main_feature_name = "Tattoo: Head 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_1

/datum/preference/choiced/species_feature/human_tattoo/head_2
	savefile_key = "feature_human_tattoo_head_2"
	main_feature_name = "Tattoo: Head 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_2

/datum/preference/choiced/species_feature/human_tattoo/head_3
	savefile_key = "feature_human_tattoo_head_3"
	main_feature_name = "Tattoo: Head 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_3

/datum/preference/choiced/species_feature/human_tattoo/head_4
	savefile_key = "feature_human_tattoo_head_4"
	main_feature_name = "Tattoo: Head 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_4

/datum/preference/choiced/species_feature/human_tattoo/head_5
	savefile_key = "feature_human_tattoo_head_5"
	main_feature_name = "Tattoo: Head 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_5

/datum/preference/choiced/species_feature/human_tattoo/head_6
	savefile_key = "feature_human_tattoo_head_6"
	main_feature_name = "Tattoo: Head 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/head_6

/datum/preference/choiced/species_feature/human_tattoo/chest_1
	savefile_key = "feature_human_tattoo_chest_1"
	main_feature_name = "Tattoo: Torso 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_1

/datum/preference/choiced/species_feature/human_tattoo/chest_2
	savefile_key = "feature_human_tattoo_chest_2"
	main_feature_name = "Tattoo: Torso 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_2

/datum/preference/choiced/species_feature/human_tattoo/chest_3
	savefile_key = "feature_human_tattoo_chest_3"
	main_feature_name = "Tattoo: Torso 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_3

/datum/preference/choiced/species_feature/human_tattoo/chest_4
	savefile_key = "feature_human_tattoo_chest_4"
	main_feature_name = "Tattoo: Torso 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_4

/datum/preference/choiced/species_feature/human_tattoo/chest_5
	savefile_key = "feature_human_tattoo_chest_5"
	main_feature_name = "Tattoo: Torso 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_5

/datum/preference/choiced/species_feature/human_tattoo/chest_6
	savefile_key = "feature_human_tattoo_chest_6"
	main_feature_name = "Tattoo: Torso 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_6

/datum/preference/choiced/species_feature/human_tattoo/l_arm_1
	savefile_key = "feature_human_tattoo_l_arm_1"
	main_feature_name = "Tattoo: Left Arm 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_1

/datum/preference/choiced/species_feature/human_tattoo/l_arm_2
	savefile_key = "feature_human_tattoo_l_arm_2"
	main_feature_name = "Tattoo: Left Arm 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_2

/datum/preference/choiced/species_feature/human_tattoo/l_arm_3
	savefile_key = "feature_human_tattoo_l_arm_3"
	main_feature_name = "Tattoo: Left Arm 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_3

/datum/preference/choiced/species_feature/human_tattoo/l_arm_4
	savefile_key = "feature_human_tattoo_l_arm_4"
	main_feature_name = "Tattoo: Left Arm 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_4

/datum/preference/choiced/species_feature/human_tattoo/l_arm_5
	savefile_key = "feature_human_tattoo_l_arm_5"
	main_feature_name = "Tattoo: Left Arm 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_5

/datum/preference/choiced/species_feature/human_tattoo/l_arm_6
	savefile_key = "feature_human_tattoo_l_arm_6"
	main_feature_name = "Tattoo: Left Arm 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_6

/datum/preference/choiced/species_feature/human_tattoo/r_arm_1
	savefile_key = "feature_human_tattoo_r_arm_1"
	main_feature_name = "Tattoo: Right Arm 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_1

/datum/preference/choiced/species_feature/human_tattoo/r_arm_2
	savefile_key = "feature_human_tattoo_r_arm_2"
	main_feature_name = "Tattoo: Right Arm 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_2

/datum/preference/choiced/species_feature/human_tattoo/r_arm_3
	savefile_key = "feature_human_tattoo_r_arm_3"
	main_feature_name = "Tattoo: Right Arm 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_3

/datum/preference/choiced/species_feature/human_tattoo/r_arm_4
	savefile_key = "feature_human_tattoo_r_arm_4"
	main_feature_name = "Tattoo: Right Arm 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_4

/datum/preference/choiced/species_feature/human_tattoo/r_arm_5
	savefile_key = "feature_human_tattoo_r_arm_5"
	main_feature_name = "Tattoo: Right Arm 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_5

/datum/preference/choiced/species_feature/human_tattoo/r_arm_6
	savefile_key = "feature_human_tattoo_r_arm_6"
	main_feature_name = "Tattoo: Right Arm 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_6

/datum/preference/choiced/species_feature/human_tattoo/l_leg_1
	savefile_key = "feature_human_tattoo_l_leg_1"
	main_feature_name = "Tattoo: Left Leg 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_1

/datum/preference/choiced/species_feature/human_tattoo/l_leg_2
	savefile_key = "feature_human_tattoo_l_leg_2"
	main_feature_name = "Tattoo: Left Leg 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_2

/datum/preference/choiced/species_feature/human_tattoo/l_leg_3
	savefile_key = "feature_human_tattoo_l_leg_3"
	main_feature_name = "Tattoo: Left Leg 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_3

/datum/preference/choiced/species_feature/human_tattoo/l_leg_4
	savefile_key = "feature_human_tattoo_l_leg_4"
	main_feature_name = "Tattoo: Left Leg 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_4

/datum/preference/choiced/species_feature/human_tattoo/l_leg_5
	savefile_key = "feature_human_tattoo_l_leg_5"
	main_feature_name = "Tattoo: Left Leg 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_5

/datum/preference/choiced/species_feature/human_tattoo/l_leg_6
	savefile_key = "feature_human_tattoo_l_leg_6"
	main_feature_name = "Tattoo: Left Leg 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_6

/datum/preference/choiced/species_feature/human_tattoo/r_leg_1
	savefile_key = "feature_human_tattoo_r_leg_1"
	main_feature_name = "Tattoo: Right Leg 1"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_1

/datum/preference/choiced/species_feature/human_tattoo/r_leg_2
	savefile_key = "feature_human_tattoo_r_leg_2"
	main_feature_name = "Tattoo: Right Leg 2"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_2

/datum/preference/choiced/species_feature/human_tattoo/r_leg_3
	savefile_key = "feature_human_tattoo_r_leg_3"
	main_feature_name = "Tattoo: Right Leg 3"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_3

/datum/preference/choiced/species_feature/human_tattoo/r_leg_4
	savefile_key = "feature_human_tattoo_r_leg_4"
	main_feature_name = "Tattoo: Right Leg 4"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_4

/datum/preference/choiced/species_feature/human_tattoo/r_leg_5
	savefile_key = "feature_human_tattoo_r_leg_5"
	main_feature_name = "Tattoo: Right Leg 5"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_5

/datum/preference/choiced/species_feature/human_tattoo/r_leg_6
	savefile_key = "feature_human_tattoo_r_leg_6"
	main_feature_name = "Tattoo: Right Leg 6"
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_6

/datum/preference/color/human_tattoo_color
	savefile_key = "human_tattoo_color"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SUPPLEMENTAL_FEATURES
	relevant_body_markings = /datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_1

/datum/preference/color/human_tattoo_color/create_default_value()
	return COLOR_ALMOST_BLACK

/datum/preference/color/human_tattoo_color/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features[FEATURE_HUMAN_TATTOO_COLOR] = value

/datum/preference/color/human_tattoo_color/is_accessible(datum/preferences/preferences)
	return ..()
