/obj/item/clothing/gloves
	name = "gloves"
	gender = PLURAL //Carn: for grammarically correct text-parsing
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/clothing/gloves.dmi'
	inhand_icon_state = "greyscale_gloves"
	lefthand_file = 'icons/mob/inhands/clothing/gloves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing/gloves_righthand.dmi'
	abstract_type = /obj/item/clothing/gloves
	greyscale_colors = null
	greyscale_config_inhand_left = /datum/greyscale_config/gloves_inhand_left
	greyscale_config_inhand_right = /datum/greyscale_config/gloves_inhand_right
	siemens_coefficient = 0.5
	body_parts_covered = HANDS
	slot_flags = ITEM_SLOT_GLOVES
	drop_sound = 'sound/items/handling/glove_drop.ogg'
	pickup_sound = 'sound/items/handling/glove_pick_up.ogg'
	attack_verb_continuous = list("challenges")
	attack_verb_simple = list("challenge")
	strip_delay = 2 SECONDS
	equip_delay_other = 4 SECONDS
	article = "a pair of"

	// Path variable. If defined, will produced the type through interaction with wirecutters.
	var/cut_type = null
	/// Used for handling bloody gloves leaving behind bloodstains on objects. Will be decremented whenever a bloodstain is left behind, and be incremented when the gloves become bloody.
	var/transfer_blood = 0

/obj/item/clothing/gloves/apply_fantasy_bonuses(bonus)
	. = ..()
	siemens_coefficient = modify_fantasy_variable("siemens_coefficient", siemens_coefficient, -bonus / 10)

/obj/item/clothing/gloves/remove_fantasy_bonuses(bonus)
	siemens_coefficient = reset_fantasy_variable("siemens_coefficient", siemens_coefficient)
	return ..()

/obj/item/clothing/gloves/cyberpunk
	name = "modular gloves"
	desc = "Cyberpunk modular gloves with small module bays for protection and grip systems."
	icon_state = "black"
	cyberpunk_equipment_form = "gloves"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_base_price = 70
	cyberpunk_rarity = "common"
	cyberpunk_active_wear = 1
	cyberpunk_spoil_behavior = "broken"
	armor_type = /datum/armor/none
	max_integrity = 90

/obj/item/clothing/gloves/cyberpunk/Initialize(mapload)
	. = ..()
	setup_cyberpunk_equipment("gloves", cyberpunk_equipment_material, list("lining" = 1, "utility" = 1, "mobility" = 1))

/obj/item/clothing/gloves/cyberpunk/wood
	name = "laminated wood modular gloves"
	cyberpunk_equipment_material = "wood"

/obj/item/clothing/gloves/cyberpunk/ceramic
	name = "ceramic modular gloves"
	cyberpunk_equipment_material = "ceramic"

/obj/item/clothing/gloves/cyberpunk/plasteel
	name = "plasteel modular gloves"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/gloves/cyberpunk/composite
	name = "smart composite modular gloves"
	cyberpunk_equipment_material = "composite"

/obj/item/clothing/gloves/cyberpunk/benn_grip
	name = "Benn modular grip gloves"
	cyberpunk_manufacturer = "Benn"
	cyberpunk_equipment_material = "composite"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/mobility_servo, /datum/cyberpunk_item_module/sensor_bus)

/obj/item/clothing/gloves/cyberpunk/ryaznov_knuckle
	name = "Ryaznov modular knuckle gloves"
	cyberpunk_manufacturer = "Ryaznov"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/impact_gel, /datum/cyberpunk_item_module/armor_plate)

/obj/item/clothing/gloves/cyberpunk/tech
	name = "tech modular gloves"
	cyberpunk_equipment_material = "composite"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/grounding_bus, /datum/cyberpunk_item_module/sensor_bus, /datum/cyberpunk_item_module/mobility_servo)

/obj/item/clothing/gloves/cyberpunk/patrol
	name = "patrol modular gloves"
	cyberpunk_equipment_material = "ceramic"
	cyberpunk_rarity = "common"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/trauma_mesh, /datum/cyberpunk_item_module/impact_gel)

/obj/item/clothing/gloves/wash(clean_types)
	. = ..()
	if((clean_types & CLEAN_TYPE_BLOOD) && transfer_blood > 0)
		transfer_blood = 0
		. |= COMPONENT_CLEANED|COMPONENT_CLEANED_GAIN_XP

/obj/item/clothing/gloves/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("\the [src] are forcing [user]'s hands around [user.p_their()] neck! It looks like the gloves are possessed!"))
	return OXYLOSS

/obj/item/clothing/gloves/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file, bodyshape = NONE)
	. = ..()
	if(isinhands)
		return
	if(damaged_clothes)
		. += mutable_appearance('icons/effects/item_damage.dmi', "damagedgloves")

/obj/item/clothing/gloves/separate_worn_overlays(mutable_appearance/standing, mutable_appearance/draw_target, isinhands, icon_file, bodyshape = NONE)
	. = ..()
	if (isinhands)
		return
	var/blood_overlay = get_blood_overlay("glove", bodyshape)
	if (blood_overlay)
		. += blood_overlay

/obj/item/clothing/gloves/update_clothes_damaged_state(damaged_state = CLOTHING_DAMAGED)
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_worn_gloves()

/obj/item/clothing/gloves/proc/can_cut_with(obj/item/tool)
	if(!cut_type)
		return FALSE
	if(icon_state != initial(icon_state))
		return FALSE // We don't want to cut dyed gloves.
	return TRUE

/obj/item/clothing/gloves/attackby(obj/item/tool, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return
	if(tool.tool_behaviour != TOOL_WIRECUTTER && !tool.get_sharpness())
		return
	if (!can_cut_with(tool))
		return
	balloon_alert(user, "cutting off fingertips...")

	if(!do_after(user, 3 SECONDS, target=src, extra_checks = CALLBACK(src, PROC_REF(can_cut_with), tool)))
		return
	balloon_alert(user, "cut fingertips off")
	qdel(src)
	user.put_in_hands(new cut_type)
	return TRUE
