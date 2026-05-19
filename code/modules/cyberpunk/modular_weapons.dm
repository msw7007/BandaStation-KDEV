// Lightweight content catalogue for the CyberPunk modular weapon core.
// These items deliberately do not depend on research, equipment components or machinery upgrades yet.

/obj/item/cy_modular_weapon
	name = "modular weapon frame"
	desc = "A weapon frame built around replaceable combat modules."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "sword"
	inhand_icon_state = "sword"
	cy_item_kind = CY_ITEM_KIND_MODULAR
	cy_item_function = CY_ITEM_FUNCTION_ACTIVE
	cy_size_category = WEIGHT_CLASS_NORMAL
	cy_controlled_item = TRUE
	cy_style_tags = list(CY_ITEM_STYLE_TAG_COMBAT)
	cy_market_value = 100
	force = 2
	attack_speed = CLICK_CD_MELEE
	block_chance = 0
	max_integrity = 120
	var/list/cy_default_module_types

/obj/item/cy_modular_weapon/Initialize(mapload)
	. = ..()
	if(length(cy_default_module_types))
		for(var/module_type in cy_default_module_types)
			var/obj/item/cy_module/module = new module_type(src)
			if(!cy_install_module(module, null, FALSE))
				qdel(module)
	cy_rebuild_item_stats()

/obj/item/cy_modular_weapon/light_blade
	name = "modular light blade"
	desc = "A fast modular blade assembled from a light grip, short cutting element and balance module."
	icon_state = "shortsword"
	inhand_icon_state = "knife"
	cy_market_value = 160
	w_class = WEIGHT_CLASS_NORMAL
	cy_default_module_types = list(
		/obj/item/cy_module/melee_handle/light_grip,
		/obj/item/cy_module/attacking_element/short_blade,
		/obj/item/cy_module/balancer/agile,
	)

/obj/item/cy_modular_weapon/combat_blade
	name = "modular combat blade"
	desc = "A practical modular cutting weapon with a hardened blade and basic guard."
	icon_state = "sword"
	inhand_icon_state = "sword"
	cy_market_value = 230
	cy_default_module_types = list(
		/obj/item/cy_module/melee_handle/combat_grip,
		/obj/item/cy_module/attacking_element/long_blade,
		/obj/item/cy_module/guard/basic,
	)

/obj/item/cy_modular_weapon/heavy_chopper
	name = "modular heavy chopper"
	desc = "A heavy modular blade that trades speed and accuracy for impact."
	icon_state = "cultblade"
	inhand_icon_state = "cultblade"
	cy_size_category = CY_ITEM_SIZE_LARGE
	cy_market_value = 320
	force = 4
	attack_speed = CLICK_CD_MELEE + 2
	cy_default_module_types = list(
		/obj/item/cy_module/melee_handle/heavy_grip,
		/obj/item/cy_module/attacking_element/axe_head,
		/obj/item/cy_module/guard/reinforced,
	)

/obj/item/cy_modular_weapon/impact_baton
	name = "modular impact baton"
	desc = "A blunt modular weapon built for control, guard and non-precision strikes."
	icon = 'icons/obj/weapons/baton.dmi'
	icon_state = "classic_baton"
	inhand_icon_state = "classic_baton"
	cy_market_value = 190
	cy_default_module_types = list(
		/obj/item/cy_module/melee_handle/combat_grip,
		/obj/item/cy_module/attacking_element/impact_head,
		/obj/item/cy_module/guard/basic,
	)

/obj/item/cy_modular_weapon/polearm
	name = "modular polearm"
	desc = "A long modular melee weapon with a piercing head and stabilizing grip."
	icon_state = "spear"
	inhand_icon_state = "spear"
	cy_size_category = CY_ITEM_SIZE_LARGE
	cy_market_value = 260
	attack_speed = CLICK_CD_MELEE + 1
	cy_default_module_types = list(
		/obj/item/cy_module/melee_handle/long_grip,
		/obj/item/cy_module/attacking_element/spear_tip,
		/obj/item/cy_module/balancer/stabilized,
	)

/obj/item/cy_modular_weapon/ranged_frame
	name = "modular ranged frame"
	desc = "A non-final ranged weapon frame. Its modules are priced and classified, but firing integration is handled later."
	icon = 'icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "pistol"
	inhand_icon_state = "gun"
	cy_size_category = WEIGHT_CLASS_NORMAL
	cy_market_value = 240
	force = 5
	cy_default_module_types = list(
		/obj/item/cy_module/ranged_handle/pistol_frame,
		/obj/item/cy_module/classic_core/mechanical,
		/obj/item/cy_module/barrel/short,
		/obj/item/cy_module/trigger/standard,
		/obj/item/cy_module/magazine/compact,
	)

/obj/item/cy_modular_weapon/ranged_frame/carbine
	name = "modular carbine frame"
	desc = "A longer ballistic modular frame with a reinforced receiver and extended barrel."
	icon = 'icons/obj/weapons/guns/wide_guns.dmi'
	icon_state = "laser_carbine"
	inhand_icon_state = "laser_carbine"
	cy_size_category = CY_ITEM_SIZE_LARGE
	cy_market_value = 390
	force = 7
	cy_default_module_types = list(
		/obj/item/cy_module/ranged_handle/long_frame,
		/obj/item/cy_module/classic_core/mechanical,
		/obj/item/cy_module/receiver/reinforced,
		/obj/item/cy_module/barrel/long,
		/obj/item/cy_module/trigger/standard,
		/obj/item/cy_module/magazine/extended,
	)

/obj/item/cy_modular_weapon/ranged_frame/energy
	name = "modular energy frame"
	desc = "A non-final energy weapon frame carrying a converter, matrix and charge module."
	icon = 'icons/obj/weapons/guns/energy.dmi'
	icon_state = "laser_pistol"
	inhand_icon_state = "laser"
	cy_market_value = 420
	cy_default_module_types = list(
		/obj/item/cy_module/ranged_handle/pistol_frame,
		/obj/item/cy_module/energy_converter/basic,
		/obj/item/cy_module/matrix/focused,
		/obj/item/cy_module/magazine/cell,
	)

/obj/item/cy_module/melee_handle/light_grip
	name = "light melee grip"
	desc = "A light grip for compact melee weapons."
	cy_accuracy_mod = 3
	cy_speed_mod = -1
	cy_market_value_mod = 35

/obj/item/cy_module/melee_handle/combat_grip
	name = "combat melee grip"
	desc = "A balanced grip for everyday combat weapons."
	cy_force_mod = 1
	cy_accuracy_mod = 1
	cy_market_value_mod = 45

/obj/item/cy_module/melee_handle/heavy_grip
	name = "heavy melee grip"
	desc = "A reinforced grip for high-impact weapons."
	cy_force_mod = 3
	cy_accuracy_mod = -3
	cy_speed_mod = 2
	cy_guard_mod = 2
	cy_market_value_mod = 65

/obj/item/cy_module/melee_handle/long_grip
	name = "long melee grip"
	desc = "An extended grip for two-handed or reach-oriented weapons."
	cy_force_mod = 1
	cy_accuracy_mod = 2
	cy_speed_mod = 1
	cy_guard_mod = 3
	cy_market_value_mod = 55

/obj/item/cy_module/attacking_element/short_blade
	name = "short blade element"
	desc = "A compact cutting element for fast weapons."
	cy_force_mod = 8
	cy_accuracy_mod = 4
	cy_speed_mod = -1
	cy_armor_penetration_mod = 3
	cy_market_value_mod = 80

/obj/item/cy_module/attacking_element/long_blade
	name = "long blade element"
	desc = "A standard hardened blade element."
	cy_force_mod = 12
	cy_accuracy_mod = 1
	cy_armor_penetration_mod = 5
	cy_market_value_mod = 110

/obj/item/cy_module/attacking_element/axe_head
	name = "chopper head element"
	desc = "A heavy chopping element."
	cy_force_mod = 18
	cy_accuracy_mod = -6
	cy_speed_mod = 3
	cy_armor_penetration_mod = 2
	cy_market_value_mod = 140
	cy_intent_force_mults = list(CY_ITEM_INTENT_CHOP = 1.2)

/obj/item/cy_module/attacking_element/impact_head
	name = "impact head element"
	desc = "A blunt impact element."
	cy_force_mod = 10
	cy_guard_mod = 4
	cy_damage_type = BRUTE
	cy_market_value_mod = 90
	cy_intent_accuracy_mods = list(CY_ITEM_INTENT_STAB = -10, CY_ITEM_INTENT_PIERCE = -10)

/obj/item/cy_module/attacking_element/spear_tip
	name = "spear tip element"
	desc = "A piercing element for reach weapons."
	cy_force_mod = 11
	cy_accuracy_mod = 3
	cy_armor_penetration_mod = 10
	cy_market_value_mod = 115
	cy_intent_ap_mods = list(CY_ITEM_INTENT_PIERCE = 15, CY_ITEM_INTENT_STAB = 8)

/obj/item/cy_module/attacking_coating/monomolecular
	name = "monomolecular edge coating"
	desc = "A precision coating that improves penetration and price."
	cy_force_mod = 2
	cy_armor_penetration_mod = 8
	cy_market_value_mod = 130
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/attacking_coating/shock
	name = "shock coating"
	desc = "A powered contact coating that shifts the weapon toward burn damage."
	cy_force_mod = 1
	cy_damage_type = BURN
	cy_market_value_mod = 115
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/balancer/agile
	name = "agile balancer"
	desc = "A compact balance module for faster handling."
	cy_accuracy_mod = 2
	cy_speed_mod = -1
	cy_market_value_mod = 45

/obj/item/cy_module/balancer/stabilized
	name = "stabilized balancer"
	desc = "A balance module that favors control over raw speed."
	cy_accuracy_mod = 4
	cy_guard_mod = 2
	cy_market_value_mod = 60

/obj/item/cy_module/guard/basic
	name = "basic guard"
	desc = "A simple hand guard."
	cy_guard_mod = 8
	cy_market_value_mod = 45

/obj/item/cy_module/guard/reinforced
	name = "reinforced guard"
	desc = "A heavier guard that can absorb more punishment."
	cy_guard_mod = 15
	cy_speed_mod = 1
	cy_market_value_mod = 80

/obj/item/cy_module/ranged_handle/pistol_frame
	name = "pistol weapon frame"
	desc = "A compact ranged weapon frame."
	cy_accuracy_mod = 2
	cy_speed_mod = -1
	cy_market_value_mod = 80

/obj/item/cy_module/ranged_handle/long_frame
	name = "long weapon frame"
	desc = "A larger ranged weapon frame for carbine and rifle builds."
	cy_accuracy_mod = 4
	cy_speed_mod = 1
	cy_market_value_mod = 120

/obj/item/cy_module/classic_core/mechanical
	name = "mechanical firing core"
	desc = "A classic ballistic firing core."
	cy_force_mod = 2
	cy_market_value_mod = 90

/obj/item/cy_module/energy_converter/basic
	name = "basic energy converter"
	desc = "A converter module for energy weapon frames."
	cy_force_mod = 3
	cy_damage_type = BURN
	cy_market_value_mod = 140

/obj/item/cy_module/barrel/short
	name = "short barrel"
	desc = "A compact barrel for close range builds."
	cy_force_mod = 3
	cy_accuracy_mod = -1
	cy_speed_mod = -1
	cy_armor_penetration_mod = 3
	cy_market_value_mod = 70

/obj/item/cy_module/barrel/long
	name = "long barrel"
	desc = "A longer barrel for accurate controlled fire."
	cy_force_mod = 4
	cy_accuracy_mod = 5
	cy_speed_mod = 1
	cy_armor_penetration_mod = 6
	cy_market_value_mod = 120

/obj/item/cy_module/barrel/heavy
	name = "heavy barrel"
	desc = "A reinforced barrel for high-pressure builds."
	cy_force_mod = 7
	cy_accuracy_mod = 2
	cy_speed_mod = 2
	cy_armor_penetration_mod = 8
	cy_market_value_mod = 170

/obj/item/cy_module/trigger/standard
	name = "standard trigger group"
	desc = "A basic trigger group for classic ranged frames."
	cy_accuracy_mod = 1
	cy_market_value_mod = 55

/obj/item/cy_module/trigger/hair
	name = "hair trigger group"
	desc = "A fast trigger group that is less forgiving."
	cy_accuracy_mod = -2
	cy_speed_mod = -2
	cy_market_value_mod = 90

/obj/item/cy_module/magazine/compact
	name = "compact magazine module"
	desc = "A small feed module for compact ranged frames."
	cy_speed_mod = -1
	cy_market_value_mod = 55

/obj/item/cy_module/magazine/extended
	name = "extended magazine module"
	desc = "A larger feed module for sustained fighting."
	cy_speed_mod = 1
	cy_market_value_mod = 95

/obj/item/cy_module/magazine/cell
	name = "weapon power cell module"
	desc = "A power storage module for energy weapon frames."
	cy_force_mod = 1
	cy_market_value_mod = 110

/obj/item/cy_module/receiver/lightweight
	name = "lightweight receiver"
	desc = "A lighter receiver that improves handling."
	cy_accuracy_mod = 1
	cy_speed_mod = -1
	cy_market_value_mod = 85

/obj/item/cy_module/receiver/reinforced
	name = "reinforced receiver"
	desc = "A durable receiver for heavier ranged builds."
	cy_force_mod = 2
	cy_guard_mod = 2
	cy_market_value_mod = 130

/obj/item/cy_module/matrix/focused
	name = "focused energy matrix"
	desc = "An energy matrix tuned for accurate burns."
	cy_force_mod = 5
	cy_accuracy_mod = 4
	cy_armor_penetration_mod = 5
	cy_damage_type = BURN
	cy_market_value_mod = 180

/obj/item/cy_module/matrix/overcharged
	name = "overcharged energy matrix"
	desc = "An unstable energy matrix that favors raw output."
	cy_force_mod = 9
	cy_accuracy_mod = -4
	cy_speed_mod = 2
	cy_armor_penetration_mod = 8
	cy_damage_type = BURN
	cy_market_value_mod = 240

/obj/item/cy_module/extra/reflex_sight
	name = "reflex sight"
	desc = "A compact sight module."
	cy_accuracy_mod = 4
	cy_market_value_mod = 75

/obj/item/cy_module/extra/compensator
	name = "compensator module"
	desc = "A muzzle control module."
	cy_accuracy_mod = 2
	cy_speed_mod = -1
	cy_market_value_mod = 70

/obj/item/cy_module/extra/suppressor
	name = "suppressor module"
	desc = "A low-profile attachment for discreet ranged builds."
	cy_force_mod = -1
	cy_accuracy_mod = 1
	cy_market_value_mod = 95
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT)
