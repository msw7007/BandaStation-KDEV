/obj/item/clothing/accessory/gloves_accessory
	name = "gloves accessory"
	abstract_type = /obj/item/clothing/accessory/gloves_accessory
	desc = "An accessory that can be worn on gloves."
	icon = 'modular_bandastation/objects/icons/obj/items/rings.dmi'
	worn_icon = 'modular_bandastation/objects/icons/mob/inhands/rings-hands.dmi'
	slot_flags = ITEM_SLOT_GLOVES
	attachment_slot = HANDS
	icon_state_is_worn = FALSE
	body_parts_covered = 0
	icon_state = "ringgold"
	worn_icon_state = "gring"

/obj/item/clothing/accessory/gloves_accessory/can_attach_accessory(obj/item/clothing/gloves/attach_to, mob/living/user)
	if(!istype(attach_to))
		CRASH("[type] - can_attach_accessory called with an invalid item to attach to. (got: [attach_to])")

	if(atom_storage && attach_to.atom_storage)
		if(user)
			attach_to.balloon_alert(user, "несовместимо с этим!")
		return FALSE

	if(attachment_slot && !(attach_to.body_parts_covered & attachment_slot))
		if(user)
			attach_to.balloon_alert(user, "нельзя надеть сюда!")
		return FALSE

	if(length(attach_to.attached_accessories) >= attach_to.max_number_of_accessories)
		if(user)
			attach_to.balloon_alert(user, "слишком много аксессуаров!")
		return FALSE

	return TRUE

/obj/item/clothing/accessory/gloves_accessory/update_greyscale()
	. = ..()

	var/obj/item/clothing/gloves/attached_to = loc

	if(!istype(attached_to))
		return

	var/mob/living/carbon/human/wearer = attached_to.loc

	if(!istype(wearer))
		return

	attached_to.update_accessory_overlay()

/obj/item/clothing/accessory/gloves_accessory/try_attach(obj/item/clothing/gloves/attach_to, mob/living/attacher)
	. = ..()
	if(!minimize_when_attached)
		return
	pixel_z = -pixel_z
	return .

/obj/item/clothing/accessory/gloves_accessory/on_uniform_equipped(obj/item/clothing/gloves/source, mob/living/user, slot)
	if(slot & source.slot_flags)
		accessory_equipped(source, user)

/obj/item/clothing/accessory/gloves_accessory/on_uniform_dropped(obj/item/clothing/gloves/source, mob/living/user)
	accessory_dropped(source, user)

/obj/item/clothing/accessory/gloves_accessory/accessory_equipped(obj/item/clothing/gloves/clothes, mob/living/user)
	equipped(user, user.get_slot_by_item(clothes))
	user.update_clothing(ITEM_SLOT_GLOVES)
	return

/obj/item/clothing/accessory/gloves_accessory/accessory_dropped(obj/item/clothing/gloves/clothes, mob/living/user)
	dropped(user)
	return

// MARK: rings
/obj/item/clothing/accessory/gloves_accessory/ring
	icon = 'modular_bandastation/objects/icons/obj/items/rings.dmi'
	worn_icon = 'modular_bandastation/objects/icons/mob/inhands/rings-hands.dmi'
	name = "gold ring"
	desc = "Маленькое золотое колечко, размером, чтобы надеть на палец."
	gender = NEUTER
	w_class = WEIGHT_CLASS_TINY
	icon_state = "ringgold"
	inhand_icon_state = null
	worn_icon_state = "gring"
	strip_delay = 4 SECONDS
	clothing_traits = list(TRAIT_FINGERPRINT_PASSTHROUGH)
	resistance_flags = FIRE_PROOF
	siemens_coefficient = 1

/obj/item/clothing/accessory/gloves_accessory/ring/diamond
	name = "diamond ring"
	desc = "Дорогое кольцо, украшенное бриллиантом. В разных культурах такие кольца использовались для ухаживания уже тысячелетия."
	icon_state = "ringdiamond"
	worn_icon_state = "dring"

/obj/item/clothing/accessory/gloves_accessory/ring/silver
	name = "silver ring"
	desc = "Маленькое серебряное колечко, размером, чтобы надеть на палец."
	icon_state = "ringsilver"
	worn_icon_state = "sring"

// MARK: cyberpunk bracers
/obj/item/clothing/accessory/gloves_accessory/bracer
	name = "modular bracers"
	desc = "Cyberpunk modular arm bracers. Their final protection depends on material and installed modules."
	icon = 'icons/obj/clothing/gloves.dmi'
	worn_icon = 'icons/mob/clothing/hands.dmi'
	icon_state = "bracers"
	worn_icon_state = "bracers"
	icon_state_is_worn = FALSE
	minimize_when_attached = FALSE
	attachment_slot = HANDS
	body_parts_covered = ARMS
	cold_protection = ARMS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	armor_type = /datum/armor/none
	inhand_icon_state = null
	strip_delay = 4 SECONDS
	equip_delay_other = 2 SECONDS
	w_class = WEIGHT_CLASS_SMALL
	cyberpunk_equipment_form = "bracers"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_base_price = 90
	cyberpunk_rarity = "common"
	cyberpunk_active_wear = 1
	cyberpunk_spoil_behavior = "broken"
	max_integrity = 110

/obj/item/clothing/accessory/gloves_accessory/bracer/Initialize(mapload)
	. = ..()
	setup_cyberpunk_equipment("bracers", cyberpunk_equipment_material, list("plate" = 1, "utility" = 1, "mobility" = 1))

/obj/item/clothing/accessory/gloves_accessory/bracer/wood
	name = "laminated wood modular bracers"
	cyberpunk_equipment_material = "wood"

/obj/item/clothing/accessory/gloves_accessory/bracer/ceramic
	name = "ceramic modular bracers"
	cyberpunk_equipment_material = "ceramic"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/accessory/gloves_accessory/bracer/plasteel
	name = "plasteel modular bracers"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "rare"

/obj/item/clothing/accessory/gloves_accessory/bracer/composite
	name = "smart composite modular bracers"
	cyberpunk_equipment_material = "composite"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/accessory/gloves_accessory/bracer/guard
	name = "guard modular bracers"
	cyberpunk_equipment_material = "ceramic"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/armor_plate, /datum/cyberpunk_item_module/trauma_mesh, /datum/cyberpunk_item_module/sensor_bus)

/obj/item/clothing/accessory/gloves_accessory/bracer/bulwark
	name = "bulwark modular bracers"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "rare"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/armor_plate/t2, /datum/cyberpunk_item_module/impact_gel, /datum/cyberpunk_item_module/reactive_hardener)
