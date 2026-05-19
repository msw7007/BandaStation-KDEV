// Corporate module catalogue. These are content-ready parts without research-node gating.

/obj/item/cy_module/Initialize(mapload)
	. = ..()
	if(isnull(cy_market_value))
		cy_market_value = max(1, cy_market_value_mod)

/obj/item/cy_module/melee_handle/san_yon_precision
	name = "San Yon precision grip"
	desc = "A high-tolerance melee grip tuned for accurate strikes."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_accuracy_mod = 6
	cy_speed_mod = -1
	cy_guard_mod = -1
	cy_market_value_mod = 120
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/melee_handle/ishikawa_silent
	name = "Ishikawa silent grip"
	desc = "A dampened grip for discreet, fast handling."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa
	cy_accuracy_mod = 3
	cy_speed_mod = -2
	cy_force_mod = -1
	cy_market_value_mod = 110
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/melee_handle/tyazhmarsh_crusher
	name = "Tyazhmarsh crusher grip"
	desc = "An overbuilt grip for heavy blows."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_force_mod = 5
	cy_accuracy_mod = -5
	cy_speed_mod = 3
	cy_guard_mod = 4
	cy_market_value_mod = 135
	cy_style_tags = list(CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/attacking_element/san_yon_needle
	name = "San Yon needle edge"
	desc = "A piercing element built around precise wound channels."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_force_mod = 9
	cy_accuracy_mod = 6
	cy_speed_mod = -1
	cy_armor_penetration_mod = 16
	cy_market_value_mod = 180
	cy_intent_ap_mods = list(CY_ITEM_INTENT_STAB = 12, CY_ITEM_INTENT_PIERCE = 24)
	cy_intent_force_mults = list(CY_ITEM_INTENT_CHOP = 0.8)

/obj/item/cy_module/attacking_element/kowalski_hardened
	name = "Kowalski hardened blade"
	desc = "A reliable hardened blade that keeps its edge under abuse."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_force_mod = 13
	cy_accuracy_mod = 1
	cy_guard_mod = 2
	cy_armor_penetration_mod = 7
	cy_market_value_mod = 155

/obj/item/cy_module/attacking_element/tesla_arc
	name = "Tesla arc striker"
	desc = "A powered striker that converts contact into burning discharge."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_force_mod = 10
	cy_accuracy_mod = -1
	cy_armor_penetration_mod = 10
	cy_damage_type = BURN
	cy_market_value_mod = 210
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/attacking_coating/ishikawa_signature_mask
	name = "Ishikawa signature mask coating"
	desc = "A coating package tuned for low-profile illegal work."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa
	cy_accuracy_mod = 2
	cy_speed_mod = -1
	cy_market_value_mod = 160
	cy_black_market_only = TRUE
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/balancer/ho_shi_reflex
	name = "Ho Shi reflex balancer"
	desc = "A speed-focused balancer that makes the weapon feel lighter than it is."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_accuracy_mod = 2
	cy_speed_mod = -3
	cy_guard_mod = -2
	cy_market_value_mod = 145

/obj/item/cy_module/guard/kowalski_lockguard
	name = "Kowalski lockguard"
	desc = "A dense guard designed to keep working after impacts."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_guard_mod = 22
	cy_speed_mod = 2
	cy_market_value_mod = 135

/obj/item/cy_module/ranged_handle/san_yon_marksman
	name = "San Yon marksman frame"
	desc = "A ranged frame with tight ergonomics and strict tolerances."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_accuracy_mod = 7
	cy_speed_mod = 1
	cy_market_value_mod = 190
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/ranged_handle/blackrock_control
	name = "Blackrock control frame"
	desc = "A security frame tuned for controlled handling over maximum output."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_accuracy_mod = 4
	cy_guard_mod = 5
	cy_force_mod = -1
	cy_market_value_mod = 160

/obj/item/cy_module/ranged_handle/tyazhmarsh_heavy
	name = "Tyazhmarsh heavy frame"
	desc = "A brutal frame for weapons that do not care about comfort."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_force_mod = 5
	cy_accuracy_mod = -5
	cy_speed_mod = 3
	cy_market_value_mod = 180

/obj/item/cy_module/barrel/san_yon_longshot
	name = "San Yon longshot barrel"
	desc = "A precision barrel for accurate single shots."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_force_mod = 4
	cy_accuracy_mod = 9
	cy_speed_mod = 2
	cy_armor_penetration_mod = 12
	cy_market_value_mod = 220

/obj/item/cy_module/barrel/tyazhmarsh_breacher
	name = "Tyazhmarsh breacher barrel"
	desc = "A short overpressure barrel for violent close work."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_force_mod = 10
	cy_accuracy_mod = -7
	cy_speed_mod = 1
	cy_armor_penetration_mod = 10
	cy_market_value_mod = 210

/obj/item/cy_module/trigger/ho_shi_burst
	name = "Ho Shi burst trigger"
	desc = "A fast trigger package with a demanding reset."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_accuracy_mod = -3
	cy_speed_mod = -4
	cy_market_value_mod = 170

/obj/item/cy_module/trigger/blackrock_safe
	name = "Blackrock governor trigger"
	desc = "A restricted trigger group favoring stable security handling."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_accuracy_mod = 4
	cy_speed_mod = 1
	cy_guard_mod = 2
	cy_market_value_mod = 130

/obj/item/cy_module/magazine/trans_travel_feed
	name = "Trans Travel logistics feed"
	desc = "A mass-produced feed module that favors capacity and serviceability."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_force_mod = -1
	cy_speed_mod = 1
	cy_market_value_mod = 120
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE)

/obj/item/cy_module/receiver/kowalski_sealed
	name = "Kowalski sealed receiver"
	desc = "A rugged receiver for bad weather, dust and poor maintenance."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_force_mod = 2
	cy_guard_mod = 6
	cy_speed_mod = 1
	cy_market_value_mod = 185

/obj/item/cy_module/matrix/tesla_lance
	name = "Tesla lance matrix"
	desc = "A forceful energy matrix with high penetration and heat."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_force_mod = 10
	cy_accuracy_mod = -2
	cy_armor_penetration_mod = 16
	cy_damage_type = BURN
	cy_market_value_mod = 280

/obj/item/cy_module/matrix/san_yon_cleanburn
	name = "San Yon cleanburn matrix"
	desc = "A precise matrix with controlled thermal bloom."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_force_mod = 5
	cy_accuracy_mod = 8
	cy_armor_penetration_mod = 8
	cy_damage_type = BURN
	cy_market_value_mod = 260

/obj/item/cy_module/extra/blackrock_tracker
	name = "Blackrock target tracker"
	desc = "A smart sight package that favors controlled target acquisition."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_accuracy_mod = 7
	cy_speed_mod = 1
	cy_market_value_mod = 170

/obj/item/cy_module/extra/ishikawa_ghostkit
	name = "Ishikawa ghostkit"
	desc = "A discreet attachment package with illegal masking hardware."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa
	cy_accuracy_mod = 2
	cy_speed_mod = -1
	cy_market_value_mod = 210
	cy_black_market_only = TRUE
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/equipment_base/san_yon_underlayer
	name = "San Yon precision underlayer"
	desc = "A light equipment base for agile armor assemblies."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_module_equipment_slot_flags = ITEM_SLOT_ICLOTHING
	cy_module_body_parts_covered = CHEST|GROIN|ARM_LEFT|ARM_RIGHT|LEG_LEFT|LEG_RIGHT
	cy_armor_class_mod = 1
	cy_integrity_transfer_mod = -0.05
	cy_style_mod = 2
	cy_market_value_mod = 140
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE)

/obj/item/cy_module/equipment_base/kowalski_carrier
	name = "Kowalski load carrier"
	desc = "A heavy carrier base for armor and field equipment."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_module_equipment_slot_flags = ITEM_SLOT_OCLOTHING
	cy_module_body_parts_covered = CHEST|GROIN|ARM_LEFT|ARM_RIGHT|LEG_LEFT|LEG_RIGHT
	cy_armor_class_mod = 2
	cy_integrity_transfer_mod = -0.1
	cy_style_mod = 1
	cy_market_value_mod = 150
	cy_style_tags = list(CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/equipment_material/ho_shi_fiber
	name = "Ho Shi reflex fiber"
	desc = "A fast, flexible equipment material."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_guard_mod = -1
	cy_armor_class_mod = 1
	cy_integrity_transfer_mod = -0.08
	cy_style_mod = 2
	cy_market_value_mod = 130

/obj/item/cy_module/equipment_material/tyazhmarsh_laminate
	name = "Tyazhmarsh dense laminate"
	desc = "A heavy laminate for obvious protection."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_armor_class_mod = 3
	cy_integrity_transfer_mod = -0.16
	cy_style_mod = -1
	cy_market_value_mod = 165
	cy_style_tags = list(CY_ITEM_STYLE_TAG_COMBAT)

/obj/item/cy_module/equipment_plate/ceramic_light
	name = "light ceramic plate"
	desc = "A low-weight plate that softens direct hits."
	cy_armor_class_mod = 2
	cy_integrity_transfer_mod = -0.08
	cy_damage_absorption = list(BRUTE = 4, BURN = 2)
	cy_market_value_mod = 120

/obj/item/cy_module/equipment_plate/kowalski_hardplate
	name = "Kowalski hardplate"
	desc = "A rugged plate with strong brute absorption."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_armor_class_mod = 4
	cy_integrity_transfer_mod = -0.15
	cy_damage_absorption = list(BRUTE = 8, BURN = 2)
	cy_market_value_mod = 210

/obj/item/cy_module/equipment_plate/tesla_ablative
	name = "Tesla ablative plate"
	desc = "An energy-resistant plate with moderate kinetic performance."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_armor_class_mod = 3
	cy_integrity_transfer_mod = -0.12
	cy_damage_absorption = list(BRUTE = 3, BURN = 9)
	cy_market_value_mod = 230

/obj/item/cy_module/equipment_lining/samanthas_comfort
	name = "Samantha's Care comfort lining"
	desc = "A social-grade lining focused on mood and wear comfort."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/samanthas_care
	cy_style_mod = 4
	cy_integrity_transfer_mod = -0.04
	cy_market_value_mod = 140
	cy_style_tags = list(CY_ITEM_STYLE_TAG_LUXURY, CY_ITEM_STYLE_TAG_CORPORATE)

/obj/item/cy_module/equipment_lining/ishikawa_shadow
	name = "Ishikawa shadow lining"
	desc = "A dark low-signature lining for discreet armor."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa
	cy_style_mod = 2
	cy_integrity_transfer_mod = -0.06
	cy_market_value_mod = 170
	cy_style_tags = list(CY_ITEM_STYLE_TAG_STREET)

/obj/item/cy_module/equipment_active/blackrock_stabilizer
	name = "Blackrock stabilizer pack"
	desc = "An active equipment module that favors control and stability."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_armor_class_mod = 1
	cy_guard_mod = 5
	cy_market_value_mod = 260

/obj/item/cy_module/equipment_active/tesla_discharge
	name = "Tesla discharge pack"
	desc = "An active pack built around force and thermal discharge."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_armor_class_mod = 2
	cy_damage_absorption = list(BURN = 6)
	cy_market_value_mod = 320
	cy_black_market_only = TRUE

/obj/item/cy_module/rig_connector/trans_travel_bus
	name = "Trans Travel rig bus"
	desc = "A standardized connector for mass-produced rigs."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_style_mod = 1
	cy_market_value_mod = 130

/obj/item/cy_module/rig_connector/ben_medical_bus
	name = "Ben medical rig bus"
	desc = "A clean connector package for medical and diagnostic rigs."
	manufacturer_organization = /datum/cy_organization/corporation/ben
	cy_style_mod = 2
	cy_damage_absorption = list(BURN = 2)
	cy_market_value_mod = 160
	cy_style_tags = list(CY_ITEM_STYLE_TAG_CORPORATE)

/obj/item/cy_vehicle_part/drive/wheel/ho_shi_street
	name = "Ho Shi street wheel assembly"
	desc = "A fast road wheel assembly with sharp acceleration and limited offroad tolerance."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_part_max_integrity = 75
	cy_part_integrity = 75
	cy_mass = 28
	cy_max_speed = 4.4
	cy_acceleration = 0.19
	cy_turn_rate = 8
	cy_road_grip = 1.45
	cy_offroad_grip = 0.35
	cy_lateral_grip = 0.30
	cy_stable_slip_limit = 0.22
	cy_drift_retention = 0.86
	cy_market_value = 260

/obj/item/cy_vehicle_part/drive/wheel/trans_travel_courier
	name = "Trans Travel courier wheel assembly"
	desc = "A reliable fleet wheel assembly made for city routes."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_part_max_integrity = 95
	cy_part_integrity = 95
	cy_mass = 34
	cy_max_speed = 3.9
	cy_acceleration = 0.16
	cy_turn_rate = 7
	cy_road_grip = 1.30
	cy_offroad_grip = 0.55
	cy_lateral_grip = 0.27
	cy_stable_slip_limit = 0.25
	cy_drift_retention = 0.82
	cy_market_value = 210

/obj/item/cy_vehicle_part/drive/track/tyazhmarsh_bulldog
	name = "Tyazhmarsh Bulldog track assembly"
	desc = "Heavy tracks for rough ground and controlled mass."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_part_max_integrity = 160
	cy_part_integrity = 160
	cy_mass = 95
	cy_max_speed = 2.8
	cy_acceleration = 0.12
	cy_turn_rate = 4.2
	cy_road_grip = 0.85
	cy_offroad_grip = 1.15
	cy_lateral_grip = 0.42
	cy_stable_slip_limit = 0.50
	cy_drift_retention = 0.62
	cy_market_value = 340

/obj/item/cy_vehicle_part/drive/flight/tesla_hover
	name = "Tesla hover lift"
	desc = "A costly lift assembly with smooth retention and weak crash tolerance."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_part_max_integrity = 70
	cy_part_integrity = 70
	cy_mass = 45
	cy_max_speed = 3.9
	cy_acceleration = 0.17
	cy_turn_rate = 6.2
	cy_lateral_grip = 0.15
	cy_stable_slip_limit = 0.38
	cy_drift_retention = 0.94
	cy_market_value = 420

/obj/item/cy_vehicle_part/suspension/blackrock_interceptor
	name = "Blackrock interceptor suspension"
	desc = "A control-focused suspension package for security response cars."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_part_max_integrity = 130
	cy_part_integrity = 130
	cy_brake_force = 0.88
	cy_lateral_grip = 0.36
	cy_engine_response = 1.7
	cy_maneuverability = 3.4
	cy_stable_slip_limit = 0.24
	cy_drift_retention = 0.80
	cy_mass = 90
	cy_market_value = 300

/obj/item/cy_vehicle_part/suspension/kowalski_endurance
	name = "Kowalski endurance suspension"
	desc = "A rugged suspension package that survives hard impacts."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_part_max_integrity = 220
	cy_part_integrity = 220
	cy_brake_force = 0.62
	cy_lateral_grip = 0.25
	cy_engine_response = 0.8
	cy_maneuverability = 2
	cy_stable_slip_limit = 0.40
	cy_drift_retention = 0.72
	cy_mass = 145
	cy_market_value = 280

/obj/item/cy_vehicle_part/hull/san_yon_light
	name = "San Yon light hull"
	desc = "A light hull shell for speed and low mass."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_part_max_integrity = 140
	cy_part_integrity = 140
	cy_mass = 230
	cy_drag = 0.025
	cy_turn_loss_mult = 0.34
	cy_market_value = 360

/obj/item/cy_vehicle_part/hull/kowalski_riot
	name = "Kowalski riot hull"
	desc = "A city-control hull with heavy protection and miserable agility."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_part_max_integrity = 430
	cy_part_integrity = 430
	cy_mass = 820
	cy_drag = 0.065
	cy_turn_loss_mult = 0.72
	cy_marks_civilian_modified = TRUE
	cy_blocks_autocharge = TRUE
	cy_market_value = 520

/obj/item/cy_vehicle_part/engine/ho_shi_overdrive
	name = "Ho Shi overdrive engine"
	desc = "A nervous electric engine with excellent response and poor durability."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_part_max_integrity = 85
	cy_part_integrity = 85
	cy_engine_type = CY_VEHICLE_ENGINE_ENERGY
	cy_max_speed = 3.5
	cy_acceleration = 0.45
	cy_engine_response = 7
	cy_explosion_chance = 5
	cy_market_value = 410

/obj/item/cy_vehicle_part/engine/trans_travel_fleet
	name = "Trans Travel fleet engine"
	desc = "A serviceable fleet engine with predictable behavior."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_part_max_integrity = 135
	cy_part_integrity = 135
	cy_engine_type = CY_VEHICLE_ENGINE_BATTERY
	cy_max_speed = 3
	cy_acceleration = 0.34
	cy_engine_response = 5
	cy_explosion_chance = 4
	cy_blocks_autocharge = TRUE
	cy_market_value = 280

/obj/item/cy_vehicle_part/engine/tyazhmarsh_torque
	name = "Tyazhmarsh torque engine"
	desc = "A fuel engine with high torque, heat and legal problems."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_part_max_integrity = 150
	cy_part_integrity = 150
	cy_engine_type = CY_VEHICLE_ENGINE_FUEL
	cy_max_speed = 3.6
	cy_acceleration = 0.48
	cy_engine_response = 6
	cy_explosion_chance = 18
	cy_blocks_autocharge = TRUE
	cy_marks_civilian_modified = TRUE
	cy_market_value = 460

/obj/item/cy_machinery_module
	name = "machinery module"
	desc = "A ready machinery upgrade module. It is not tied to a research node yet."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_SMALL
	cy_item_kind = CY_ITEM_KIND_PREFAB
	cy_item_function = CY_ITEM_FUNCTION_ACTIVE
	cy_market_value = 100
	var/cy_machine_speed_mult = 1
	var/cy_machine_power_mult = 1
	var/cy_machine_quality_bonus = 0
	var/cy_machine_reliability_bonus = 0
	var/cy_machine_output_bonus = 0
	var/cy_machine_heat_bonus = 0
	var/cy_machine_illegal = FALSE
	var/cy_machine_module_slot = "generic"
	var/cy_machine_enables_sales = FALSE
	var/cy_machine_enables_network = FALSE
	var/cy_machine_enables_storage = FALSE
	var/cy_machine_enables_payment = FALSE
	var/icon/cy_overlay_icon = 'icons/mob/rideables/vehicles.dmi'
	var/cy_overlay_state = "clowncar"
	var/cy_overlay_layer_offset = 0.01
	var/cy_overlay_pixel_x = 0
	var/cy_overlay_pixel_y = 0
	var/cy_overlay_color

/obj/item/cy_machinery_module/proc/cy_get_overlay_appearance(base_layer = OBJ_LAYER)
	if(!cy_overlay_icon || !cy_overlay_state)
		return null
	var/mutable_appearance/overlay = mutable_appearance(cy_overlay_icon, cy_overlay_state, base_layer + cy_overlay_layer_offset)
	overlay.pixel_x = cy_overlay_pixel_x
	overlay.pixel_y = cy_overlay_pixel_y
	if(cy_overlay_color)
		overlay.color = cy_overlay_color
	return overlay

/obj/item/cy_machinery_module/examine(mob/user)
	. = ..()
	. += span_notice("Machine profile: speed x[cy_machine_speed_mult], power x[cy_machine_power_mult], quality +[cy_machine_quality_bonus], output +[cy_machine_output_bonus].")
	if(cy_machine_reliability_bonus)
		. += span_notice("Reliability: +[cy_machine_reliability_bonus].")
	if(cy_machine_illegal)
		. += span_warning("This module is not intended for civilian installation.")

/obj/item/cy_machinery_module/ben_diagnostic
	name = "Ben diagnostic co-processor"
	desc = "A medical-grade diagnostic module that improves quality and reliability."
	manufacturer_organization = /datum/cy_organization/corporation/ben
	cy_machine_speed_mult = 1.05
	cy_machine_power_mult = 1.05
	cy_machine_quality_bonus = 1
	cy_machine_reliability_bonus = 3
	cy_market_value = 220

/obj/item/cy_machinery_module/sales
	name = "sales bay module"
	desc = "A vending bay module. The final UI will expose sale lists through this."
	cy_machine_module_slot = "sales"
	cy_machine_enables_sales = TRUE
	cy_machine_enables_storage = TRUE
	cy_machine_output_bonus = 1
	cy_market_value = 160

/obj/item/cy_machinery_module/payment
	name = "payment terminal module"
	desc = "A payment module for credit-based automated machines."
	cy_machine_module_slot = "payment"
	cy_machine_enables_payment = TRUE
	cy_machine_reliability_bonus = 1
	cy_market_value = 140

/obj/item/cy_machinery_module/network
	name = "network terminal module"
	desc = "A network module for remote catalogue, account and city-system links."
	cy_machine_module_slot = "network"
	cy_machine_enables_network = TRUE
	cy_machine_power_mult = 1.1
	cy_machine_reliability_bonus = -1
	cy_market_value = 180

/obj/item/cy_machinery_module/storage
	name = "storage cassette module"
	desc = "A removable storage cassette for automated machines."
	cy_machine_module_slot = "storage"
	cy_machine_enables_storage = TRUE
	cy_machine_output_bonus = 2
	cy_market_value = 150

/obj/item/cy_machinery_module/san_yon_precision
	name = "San Yon precision controller"
	desc = "A controller for slow, accurate production and analysis."
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon
	cy_machine_speed_mult = 0.9
	cy_machine_power_mult = 1.1
	cy_machine_quality_bonus = 2
	cy_machine_reliability_bonus = 2
	cy_market_value = 280

/obj/item/cy_machinery_module/ho_shi_cycle
	name = "Ho Shi cycle accelerator"
	desc = "A speed module that pushes machinery harder."
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi
	cy_machine_speed_mult = 1.35
	cy_machine_power_mult = 1.3
	cy_machine_reliability_bonus = -1
	cy_market_value = 260

/obj/item/cy_machinery_module/kowalski_redundancy
	name = "Kowalski redundancy block"
	desc = "A rugged block that lowers failure risk at the cost of cycle speed."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	cy_machine_speed_mult = 0.92
	cy_machine_power_mult = 1.15
	cy_machine_reliability_bonus = 5
	cy_machine_output_bonus = 1
	cy_market_value = 250

/obj/item/cy_machinery_module/tyazhmarsh_industrial
	name = "Tyazhmarsh industrial driver"
	desc = "A crude high-output machinery driver."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tyazhmarsh
	cy_machine_speed_mult = 1.15
	cy_machine_power_mult = 1.55
	cy_machine_output_bonus = 3
	cy_machine_heat_bonus = 3
	cy_machine_reliability_bonus = -2
	cy_machine_illegal = TRUE
	cy_market_value = 330

/obj/item/cy_machinery_module/tesla_power
	name = "Tesla power harmonizer"
	desc = "A power module that cuts active draw, but adds heat sensitivity."
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla
	cy_machine_speed_mult = 1.05
	cy_machine_power_mult = 0.72
	cy_machine_heat_bonus = 2
	cy_machine_reliability_bonus = 1
	cy_market_value = 310

/obj/item/cy_machinery_module/blackrock_governor
	name = "Blackrock process governor"
	desc = "A secure governor for predictable, controlled machinery behavior."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/blackrock
	cy_machine_speed_mult = 0.95
	cy_machine_power_mult = 0.95
	cy_machine_quality_bonus = 1
	cy_machine_reliability_bonus = 4
	cy_market_value = 240

/obj/item/cy_machinery_module/trans_travel_mass
	name = "Trans Travel mass-production scheduler"
	desc = "A scheduling module for larger output and higher wear."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_machine_speed_mult = 1.2
	cy_machine_power_mult = 1.2
	cy_machine_output_bonus = 2
	cy_machine_reliability_bonus = -1
	cy_market_value = 230

/obj/item/cy_machinery_module/samanthas_interface
	name = "Samantha's Care comfort interface"
	desc = "A user-facing interface module that favors stable outcomes over throughput."
	manufacturer_organization = /datum/cy_organization/corporation/starlight/samanthas_care
	cy_machine_speed_mult = 0.98
	cy_machine_power_mult = 1
	cy_machine_quality_bonus = 1
	cy_machine_reliability_bonus = 2
	cy_style_value = 4
	cy_style_tags = list(CY_ITEM_STYLE_TAG_LUXURY, CY_ITEM_STYLE_TAG_CORPORATE)
	cy_market_value = 210
