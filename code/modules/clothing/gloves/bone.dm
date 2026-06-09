/obj/item/clothing/gloves/bracer
	name = "bone bracers"
	desc = "For when you're expecting to get slapped on the wrist. Offers modest protection to your arms."
	icon_state = "bracers"
	inhand_icon_state = null
	strip_delay = 4 SECONDS
	equip_delay_other = 2 SECONDS
	body_parts_covered = ARMS
	cold_protection = ARMS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	armor_type = /datum/armor/gloves_bracer
	custom_materials = list(/datum/material/bone = SHEET_MATERIAL_AMOUNT * 2)

/obj/item/clothing/gloves/bracer/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/adjust_fishing_difficulty, 2)

/obj/item/clothing/gloves/bracer/cyberpunk
	name = "modular bracers"
	desc = "Cyberpunk modular arm bracers. Their final protection depends on material and installed modules."
	cyberpunk_equipment_form = "bracers"
	cyberpunk_equipment_material = "fabric"
	cyberpunk_base_price = 90
	cyberpunk_rarity = "common"
	cyberpunk_active_wear = 1
	cyberpunk_spoil_behavior = "broken"
	armor_type = /datum/armor/none
	custom_materials = null
	max_integrity = 110
	w_class = WEIGHT_CLASS_SMALL

/obj/item/clothing/gloves/bracer/cyberpunk/Initialize(mapload)
	. = ..()
	setup_cyberpunk_equipment("bracers", cyberpunk_equipment_material, list("plate" = 1, "utility" = 1, "mobility" = 1))

/obj/item/clothing/gloves/bracer/cyberpunk/wood
	name = "laminated wood modular bracers"
	cyberpunk_equipment_material = "wood"

/obj/item/clothing/gloves/bracer/cyberpunk/ceramic
	name = "ceramic modular bracers"
	cyberpunk_equipment_material = "ceramic"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/gloves/bracer/cyberpunk/plasteel
	name = "plasteel modular bracers"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "rare"

/obj/item/clothing/gloves/bracer/cyberpunk/composite
	name = "smart composite modular bracers"
	cyberpunk_equipment_material = "composite"
	cyberpunk_rarity = "uncommon"

/obj/item/clothing/gloves/bracer/cyberpunk/guard
	name = "guard modular bracers"
	cyberpunk_equipment_material = "ceramic"
	cyberpunk_rarity = "uncommon"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/armor_plate, /datum/cyberpunk_item_module/trauma_mesh, /datum/cyberpunk_item_module/sensor_bus)

/obj/item/clothing/gloves/bracer/cyberpunk/bulwark
	name = "bulwark modular bracers"
	cyberpunk_equipment_material = "plasteel"
	cyberpunk_rarity = "rare"
	cyberpunk_initial_module_types = list(/datum/cyberpunk_item_module/armor_plate/t2, /datum/cyberpunk_item_module/impact_gel, /datum/cyberpunk_item_module/reactive_hardener)

/datum/armor/gloves_bracer
	melee = 15
	bullet = 25
	laser = 15
	energy = 15
	bomb = 20
	bio = 10
