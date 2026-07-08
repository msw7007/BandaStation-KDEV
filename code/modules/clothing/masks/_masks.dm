/obj/item/clothing/mask
	name = "mask"
	icon = 'icons/obj/clothing/masks.dmi'
	lefthand_file = 'icons/mob/inhands/clothing/masks_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing/masks_righthand.dmi'
	abstract_type = /obj/item/clothing/mask
	body_parts_covered = HEAD
	slot_flags = ITEM_SLOT_MASK
	strip_delay = 4 SECONDS
	equip_delay_other = 4 SECONDS
	visor_vars_to_toggle = NONE

	var/adjusted_flags = null
	///Did we install a filtering cloth?
	var/has_filter = FALSE
	/// If defined, what voice should we override with if TTS is active?
	var/voice_override
	/// If set to true, activates the radio effect on TTS. Used for sec hailers, but other masks can utilize it for their own vocal effect.
	var/use_radio_beeps_tts = FALSE
	/// The unique sound effect of dying while wearing this
	var/unique_death
	/// Define posibiliaty of mask to be adjusted
	var/can_be_adjusted = TRUE // BANDASTATION EDIT - Surgery mask fix

// BANDASTATION ADDITION START - Surgery mask fix
/obj/item/clothing/mask/Initialize(mapload)
	. = ..()
	if(!can_be_adjusted)
		if(islist(actions_types))
			actions_types -= list(/datum/action/item_action/toggle)
		else
			actions_types = list()
// BANDASTATION ADDITION END - Surgery mask fix

/obj/item/clothing/mask/cyberpunk
	name = "modular mask"
	desc = "A Cyberpunk modular mask shell for light facial protection and utility modules."
	icon_state = "gas_mask"
	cyberpunk_equipment_form = "mask"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_base_price = 80
	cyberpunk_rarity = "common"
	cyberpunk_active_wear = 1
	cyberpunk_spoil_behavior = "broken"
	armor_type = /datum/armor/none
	max_integrity = 90

/obj/item/clothing/mask/cyberpunk/Initialize(mapload)
	. = ..()
	setup_cyberpunk_equipment("mask", cyberpunk_equipment_material, list("lining" = 1, "utility" = 1, "active" = 1))

/obj/item/clothing/mask/cyberpunk/wood
	name = "laminated wood modular mask"
	cyberpunk_equipment_material = "wood"

/obj/item/clothing/mask/cyberpunk/ceramic
	name = "ceramic modular mask"
	cyberpunk_equipment_material = "ceramic"

/obj/item/clothing/mask/cyberpunk/plasteel
	name = "plasteel modular mask"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/mask/cyberpunk/composite
	name = "smart composite modular mask"
	cyberpunk_equipment_material = "composite"

/obj/item/clothing/mask/cyberpunk/starlight_filter
	name = "Starlight modular filter mask"
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/chemseal_lining, /datum/cyberpunk_item_module/sensor_bus)

/obj/item/clothing/mask/cyberpunk/sealed
	name = "sealed modular mask"
	cyberpunk_equipment_material = "composite"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/chemseal_lining/t2, /datum/cyberpunk_item_module/insulation_lining, /datum/cyberpunk_item_module/medfoam_injector)

/obj/item/clothing/mask/cyberpunk/street
	name = "street modular mask"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_rarity = "common"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/trauma_mesh, /datum/cyberpunk_item_module/sensor_bus)

/obj/item/clothing/mask/attack_self(mob/user)
	if((clothing_flags & VOICEBOX_TOGGLABLE))
		clothing_flags ^= (VOICEBOX_DISABLED)
		var/status = !(clothing_flags & VOICEBOX_DISABLED)
		to_chat(user, span_notice("You turn the voice box in [src] [status ? "on" : "off"]."))

/obj/item/clothing/mask/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file, bodyshape = NONE)
	. = ..()
	if(isinhands || !(body_parts_covered & HEAD))
		return
	if(damaged_clothes)
		. += mutable_appearance('icons/effects/item_damage.dmi', "damagedmask")

/obj/item/clothing/mask/separate_worn_overlays(mutable_appearance/standing, mutable_appearance/draw_target, isinhands, icon_file, bodyshape = NONE)
	. = ..()
	if (isinhands || !(body_parts_covered & HEAD))
		return
	var/blood_overlay = get_blood_overlay("mask", bodyshape)
	if (blood_overlay)
		. += blood_overlay

/obj/item/clothing/mask/update_clothes_damaged_state(damaged_state = CLOTHING_DAMAGED)
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_worn_mask()

//Proc that moves gas/breath masks out of the way, disabling them and allowing pill/food consumption
/obj/item/clothing/mask/visor_toggling(mob/living/user)
	// BANDASTATION ADDITION START - Surgery mask fix
	if(!can_be_adjusted)
		return
	// BANDASTATION ADDITION END - Surgery mask fix

	. = ..()
	if(up)
		if(adjusted_flags)
			slot_flags = adjusted_flags
	else
		slot_flags = initial(slot_flags)

/obj/item/clothing/mask/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state || initial(post_init_icon_state) || initial(icon_state)][up ? "_up" : ""]"

/**
 * Proc called in lungs.dm to act if wearing a mask with filters, used to reduce the filters durability, return a changed gas mixture depending on the filter status
 * Arguments:
 * * breath - the gas mixture of the breather
 */
/obj/item/clothing/mask/proc/consume_filter(datum/gas_mixture/breath)
	return breath
