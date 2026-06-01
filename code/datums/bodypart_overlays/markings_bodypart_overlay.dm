/// For body markings applied on the species, which need some extra code
/datum/bodypart_overlay/simple/body_marking
	layers = EXTERNAL_ADJACENT
	/// Listen to the gendercode, if the limb is bimorphic
	var/use_gender = FALSE
	/// Which dna feature key to draw from
	var/dna_feature_key

	/// BANDASTATION ADDITION START - Species
	/// Which dna color feature use to color the markings
	var/dna_color_feature_key
	/// BANDASTATION ADDITION START - Species

	/// Which bodyparts do we apply ourselves to?
	var/list/applies_to = list(
		/obj/item/bodypart/arm/left,
		/obj/item/bodypart/arm/right,
		/obj/item/bodypart/chest,
		/obj/item/bodypart/head,
		/obj/item/bodypart/leg/left,
		/obj/item/bodypart/leg/right,
	)

/// Get the accessory list from SSaccessories. Used in species.dm to get the right sprite
/datum/bodypart_overlay/simple/body_marking/proc/get_accessory(name)
	CRASH("get_accessories() not overriden on [type] !")

/datum/bodypart_overlay/simple/body_marking/set_appearance(name, set_color)
	var/datum/sprite_accessory/accessory = get_accessory(name)
	if(isnull(accessory))
		return

	icon = accessory.icon
	icon_state = accessory.icon_state
	use_gender = accessory.gender_specific
	draw_color = accessory.color_src ? set_color : null

/datum/bodypart_overlay/simple/body_marking/generate_icon_cache(obj/item/bodypart/limb)
	. = ..()
	. += use_gender
	. += draw_color

/datum/bodypart_overlay/simple/body_marking/can_draw_on_bodypart(obj/item/bodypart/bodypart_owner, mob/living/carbon/owner, is_husked = FALSE)
	return ..() && icon_state != SPRITE_ACCESSORY_NONE

/datum/bodypart_overlay/simple/body_marking/get_image(layer, obj/item/bodypart/limb)
	var/gender_string = (use_gender && limb.is_dimorphic) ? (limb.gender == MALE ? MALE : FEMALE + "_") : "" //we only got male and female sprites
	return mutable_appearance(icon, gender_string + icon_state + "_" + limb.body_zone, layer = layer)

/datum/bodypart_overlay/simple/body_marking/get_accessory(name)
	return SSaccessories.feature_list[dna_feature_key][name]

/datum/bodypart_overlay/simple/body_marking/moth
	dna_feature_key = FEATURE_MOTH_MARKINGS

/datum/bodypart_overlay/simple/body_marking/lizard
	dna_feature_key = FEATURE_LIZARD_MARKINGS
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo
	dna_color_feature_key = FEATURE_HUMAN_TATTOO_COLOR
	blocks_emissive = EMISSIVE_BLOCK_NONE
	var/tattoo_layer = 1

/datum/bodypart_overlay/simple/body_marking/human_tattoo/get_image(layer, obj/item/bodypart/limb)
	. = ..(layer, limb)
	var/image/tattoo_image = .
	tattoo_image.layer += tattoo_layer * 0.001

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/head_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_HEAD_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/head)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/chest_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_CHEST_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/chest)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_arm_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_ARM_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/arm/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_arm_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_ARM_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/arm/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/l_leg_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_L_LEG_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/leg/left)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_1
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_1
	tattoo_layer = 1
	applies_to = list(/obj/item/bodypart/leg/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_2
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_2
	tattoo_layer = 2
	applies_to = list(/obj/item/bodypart/leg/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_3
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_3
	tattoo_layer = 3
	applies_to = list(/obj/item/bodypart/leg/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_4
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_4
	tattoo_layer = 4
	applies_to = list(/obj/item/bodypart/leg/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_5
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_5
	tattoo_layer = 5
	applies_to = list(/obj/item/bodypart/leg/right)

/datum/bodypart_overlay/simple/body_marking/human_tattoo/r_leg_6
	dna_feature_key = FEATURE_HUMAN_TATTOO_R_LEG_6
	tattoo_layer = 6
	applies_to = list(/obj/item/bodypart/leg/right)
