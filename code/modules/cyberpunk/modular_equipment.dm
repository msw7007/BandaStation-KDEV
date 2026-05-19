// Core modular equipment frames. Content catalogues can add more bases/materials/modules without changing equip logic.

/obj/item/cy_modular_equipment
	name = "modular equipment frame"
	desc = "A wearable frame assembled from replaceable equipment modules."
	icon = 'icons/obj/clothing/suits/armor.dmi'
	icon_state = "armor"
	worn_icon_state = "armor"
	cy_item_kind = CY_ITEM_KIND_MODULAR
	cy_item_function = CY_ITEM_FUNCTION_PROTECTIVE
	cy_size_category = CY_ITEM_SIZE_MEDIUM
	cy_market_value = 120
	max_integrity = 150
	var/list/cy_default_module_types

/obj/item/cy_modular_equipment/Initialize(mapload)
	. = ..()
	if(length(cy_default_module_types))
		for(var/module_type in cy_default_module_types)
			var/obj/item/cy_module/module = new module_type(src)
			if(!cy_install_module(module, null, FALSE))
				qdel(module)
	cy_rebuild_item_stats()

/obj/item/cy_modular_equipment/underlayer
	name = "modular underlayer"
	desc = "A modular base layer worn in the uniform slot."
	icon = 'icons/obj/clothing/under/color.dmi'
	icon_state = "grey"
	worn_icon_state = "grey"
	cy_default_module_types = list(/obj/item/cy_module/equipment_base/underlayer, /obj/item/cy_module/equipment_material/ho_shi_fiber)

/obj/item/cy_modular_equipment/oversuit
	name = "modular oversuit"
	desc = "A modular outer layer for plates, linings and active packs."
	cy_size_category = CY_ITEM_SIZE_LARGE
	cy_default_module_types = list(/obj/item/cy_module/equipment_base/oversuit, /obj/item/cy_module/equipment_material/tyazhmarsh_laminate)

/obj/item/cy_modular_equipment/gloves
	name = "modular gloves"
	desc = "A paired modular hand protection frame."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "black"
	worn_icon_state = "black"
	cy_size_category = CY_ITEM_SIZE_SMALL
	cy_default_module_types = list(/obj/item/cy_module/equipment_base/gloves, /obj/item/cy_module/equipment_material/ho_shi_fiber)

/obj/item/cy_modular_equipment/boots
	name = "modular boots"
	desc = "A paired modular foot protection frame."
	icon = 'icons/obj/clothing/shoes.dmi'
	icon_state = "jackboots"
	worn_icon_state = "jackboots"
	cy_size_category = CY_ITEM_SIZE_SMALL
	cy_default_module_types = list(/obj/item/cy_module/equipment_base/boots, /obj/item/cy_module/equipment_material/ho_shi_fiber)

/obj/item/cy_modular_equipment/helmet
	name = "modular helmet"
	desc = "A modular head protection frame."
	icon = 'icons/obj/clothing/head/helmet.dmi'
	icon_state = "helmet"
	worn_icon_state = "helmet"
	cy_size_category = CY_ITEM_SIZE_SMALL
	cy_default_module_types = list(/obj/item/cy_module/equipment_base/helmet, /obj/item/cy_module/equipment_material/tyazhmarsh_laminate)

/obj/item/cy_module/equipment_base/underlayer
	name = "underlayer equipment base"
	cy_module_equipment_slot_flags = ITEM_SLOT_ICLOTHING
	cy_module_body_parts_covered = CHEST|GROIN|ARM_LEFT|ARM_RIGHT|LEG_LEFT|LEG_RIGHT

/obj/item/cy_module/equipment_base/oversuit
	name = "oversuit equipment base"
	cy_module_equipment_slot_flags = ITEM_SLOT_OCLOTHING
	cy_module_body_parts_covered = CHEST|GROIN|ARM_LEFT|ARM_RIGHT|LEG_LEFT|LEG_RIGHT

/obj/item/cy_module/equipment_base/gloves
	name = "paired glove base"
	cy_module_equipment_slot_flags = ITEM_SLOT_GLOVES
	cy_module_body_parts_covered = HAND_LEFT|HAND_RIGHT

/obj/item/cy_module/equipment_base/boots
	name = "paired boot base"
	cy_module_equipment_slot_flags = ITEM_SLOT_FEET
	cy_module_body_parts_covered = FOOT_LEFT|FOOT_RIGHT

/obj/item/cy_module/equipment_base/helmet
	name = "helmet equipment base"
	cy_module_equipment_slot_flags = ITEM_SLOT_HEAD
	cy_module_body_parts_covered = HEAD
