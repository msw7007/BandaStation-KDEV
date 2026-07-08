// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/datum/design/cyberpunk_item_module
	name = "Starlight Item Module"
	desc = "A Starlight modular component shell for Cyberpunk 13 weapons and protective equipment."
	id = "starlight_item_module"
	build_type = PROTOLATHE | AUTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
//CYBERPUNK BUILD - rebuild and delete before release
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/cyberpunk_item_module/melee_core
	name = "Starlight Melee Core"
	id = "starlight_melee_core"
	build_path = /obj/item/cyberpunk_item_module/melee_core

/datum/design/cyberpunk_item_module/melee_blade
	name = "Starlight Blade Element"
	id = "starlight_blade_element"
	build_path = /obj/item/cyberpunk_item_module/melee_blade

/datum/design/cyberpunk_item_module/melee_spike
	name = "Starlight Spike Element"
	id = "starlight_spike_element"
	build_path = /obj/item/cyberpunk_item_module/melee_spike

/datum/design/cyberpunk_item_module/melee_head
	name = "Starlight Weighted Head"
	id = "starlight_weighted_head"
	build_path = /obj/item/cyberpunk_item_module/melee_head

/datum/design/cyberpunk_item_module/guard
	name = "Starlight Weapon Guard"
	id = "starlight_weapon_guard"
	build_path = /obj/item/cyberpunk_item_module/guard

/datum/design/cyberpunk_item_module/balancer
	name = "Starlight Weapon Balancer"
	id = "starlight_weapon_balancer"
	build_path = /obj/item/cyberpunk_item_module/balancer

/datum/design/cyberpunk_item_module/melee_knife_element
	name = "Starlight Knife Attacking Element"
	id = "starlight_knife_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_knife_element

/datum/design/cyberpunk_item_module/melee_club_element
	name = "Starlight Club Attacking Element"
	id = "starlight_club_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_club_element

/datum/design/cyberpunk_item_module/melee_twohand_sword_element
	name = "Starlight Two-Handed Sword Attacking Element"
	id = "starlight_twohand_sword_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_sword_element

/datum/design/cyberpunk_item_module/melee_twohand_hammer_element
	name = "Starlight Two-Handed Hammer Attacking Element"
	id = "starlight_twohand_hammer_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_hammer_element

/datum/design/cyberpunk_item_module/melee_axe_element
	name = "Starlight Axe Attacking Element"
	id = "starlight_axe_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_axe_element

/datum/design/cyberpunk_item_module/melee_twohand_axe_element
	name = "Starlight Two-Handed Axe Attacking Element"
	id = "starlight_twohand_axe_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_axe_element

/datum/design/cyberpunk_item_module/melee_rapier_element
	name = "Starlight Rapier Attacking Element"
	id = "starlight_rapier_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_rapier_element

/datum/design/cyberpunk_item_module/melee_spear_element
	name = "Starlight Spear Attacking Element"
	id = "starlight_spear_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_spear_element

/datum/design/cyberpunk_item_module/melee_staff_element
	name = "Starlight Staff Attacking Element"
	id = "starlight_staff_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_staff_element

/datum/design/cyberpunk_item_module/shock_coating
	name = "Starlight Shock Weapon Coating"
	id = "starlight_shock_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shock_coating

/datum/design/cyberpunk_item_module/thermal_coating
	name = "Starlight Thermal Weapon Coating"
	id = "starlight_thermal_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/thermal_coating

/datum/design/cyberpunk_item_module/serrated_coating
	name = "Starlight Serrated Weapon Coating"
	id = "starlight_serrated_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/serrated_coating

/datum/design/cyberpunk_item_module/firearm_core
	name = "Starlight Firearm Core"
	id = "starlight_firearm_core"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/firearm_core

/datum/design/cyberpunk_item_module/heavy_barrel
	name = "Starlight Heavy Barrel"
	id = "starlight_heavy_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel

/datum/design/cyberpunk_item_module/long_barrel
	name = "Starlight Long Barrel"
	id = "starlight_long_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/long_barrel

/datum/design/cyberpunk_item_module/revolver_barrel
	name = "Starlight Revolver Barrel"
	id = "starlight_revolver_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel

/datum/design/cyberpunk_item_module/pistol_barrel
	name = "Starlight Pistol Barrel"
	id = "starlight_pistol_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel

/datum/design/cyberpunk_item_module/smg_barrel
	name = "Starlight SMG Barrel"
	id = "starlight_smg_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/smg_barrel

/datum/design/cyberpunk_item_module/rifle_barrel
	name = "Starlight Rifle Barrel"
	id = "starlight_rifle_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel

/datum/design/cyberpunk_item_module/shotgun_barrel
	name = "Starlight Shotgun Barrel"
	id = "starlight_shotgun_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel

/datum/design/cyberpunk_item_module/sniper_barrel
	name = "Starlight Sniper Barrel"
	id = "starlight_sniper_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel

/datum/design/cyberpunk_item_module/assault_barrel
	name = "Starlight Assault Barrel"
	id = "starlight_assault_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/assault_barrel

/datum/design/cyberpunk_item_module/lmg_barrel
	name = "Starlight Machine Gun Barrel"
	id = "starlight_lmg_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel

/datum/design/cyberpunk_item_module/rocket_barrel
	name = "Starlight Launcher Tube"
	id = "starlight_launcher_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel

/datum/design/cyberpunk_item_module/cylinder_50
	name = "Starlight .50 Cylinder"
	id = "starlight_cylinder_50"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/cylinder_50

/datum/design/cyberpunk_item_module/cylinder_357
	name = "Starlight .357 Cylinder"
	id = "starlight_cylinder_357"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/cylinder_357

/datum/design/cyberpunk_item_module/pistol_magwell_9mm
	name = "Starlight 9mm Pistol Magwell"
	id = "starlight_pistol_magwell_9mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm

/datum/design/cyberpunk_item_module/pistol_magwell_10mm
	name = "Starlight 10mm Pistol Magwell"
	id = "starlight_pistol_magwell_10mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm

/datum/design/cyberpunk_item_module/smg_magwell_9mm
	name = "Starlight 9mm SMG Magwell"
	id = "starlight_smg_magwell_9mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm

/datum/design/cyberpunk_item_module/rifle_magwell_223
	name = "Starlight .223 Rifle Magwell"
	id = "starlight_rifle_magwell_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223

/datum/design/cyberpunk_item_module/shotgun_tube
	name = "Starlight Shotgun Tube"
	id = "starlight_shotgun_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube

/datum/design/cyberpunk_item_module/sniper_chamber
	name = "Starlight Sniper Chamber"
	id = "starlight_sniper_chamber"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber

/datum/design/cyberpunk_item_module/assault_magwell_223
	name = "Starlight .223 Assault Magwell"
	id = "starlight_assault_magwell_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223

/datum/design/cyberpunk_item_module/lmg_feed_223
	name = "Starlight .223 Belt Feed"
	id = "starlight_lmg_feed_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223

/datum/design/cyberpunk_item_module/rocket_tube
	name = "Starlight Rocket Launch Tube"
	id = "starlight_rocket_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rocket_tube

/datum/design/cyberpunk_item_module/laser_emitter
	name = "Starlight Laser Emitter"
	id = "starlight_laser_emitter"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/laser_emitter

/datum/design/cyberpunk_item_module/plasma_emitter
	name = "Starlight Plasma Emitter"
	id = "starlight_plasma_emitter"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter

/datum/design/cyberpunk_item_module/precision_receiver
	name = "Starlight Precision Receiver"
	id = "starlight_precision_receiver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/precision_receiver

/datum/design/cyberpunk_item_module/damage_trigger
	name = "Starlight Overpressure Trigger"
	id = "starlight_damage_trigger"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/damage_trigger

/datum/design/cyberpunk_item_module/speed_trigger
	name = "Starlight Short-Reset Trigger"
	id = "starlight_speed_trigger"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/speed_trigger

/datum/design/cyberpunk_item_module/reflex_sight
	name = "Starlight Reflex Sight"
	id = "starlight_reflex_sight"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/reflex_sight

/datum/design/cyberpunk_item_module/tactical_light
	name = "Starlight Tactical Light"
	id = "starlight_tactical_light"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/tactical_light

/datum/design/cyberpunk_item_module/firearm_core/t2
	name = "Starlight Firearm Core T2"
	id = "starlight_firearm_core_t2"
	build_path = /obj/item/cyberpunk_item_module/firearm_core/t2

/datum/design/cyberpunk_item_module/firearm_core/t3
	name = "Starlight Firearm Core T3"
	id = "starlight_firearm_core_t3"
	build_path = /obj/item/cyberpunk_item_module/firearm_core/t3

/datum/design/cyberpunk_item_module/heavy_barrel/t2
	name = "Starlight Heavy Barrel T2"
	id = "starlight_heavy_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel/t2

/datum/design/cyberpunk_item_module/heavy_barrel/t3
	name = "Starlight Heavy Barrel T3"
	id = "starlight_heavy_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel/t3

/datum/design/cyberpunk_item_module/long_barrel/t2
	name = "Starlight Long Barrel T2"
	id = "starlight_long_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/long_barrel/t2

/datum/design/cyberpunk_item_module/long_barrel/t3
	name = "Starlight Long Barrel T3"
	id = "starlight_long_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/long_barrel/t3

/datum/design/cyberpunk_item_module/cylinder_50/t2
	name = "Starlight .50 Cylinder T2"
	id = "starlight_cylinder_50_t2"
	build_path = /obj/item/cyberpunk_item_module/cylinder_50/t2

/datum/design/cyberpunk_item_module/cylinder_50/t3
	name = "Starlight .50 Cylinder T3"
	id = "starlight_cylinder_50_t3"
	build_path = /obj/item/cyberpunk_item_module/cylinder_50/t3

/datum/design/cyberpunk_item_module/cylinder_357/t2
	name = "Starlight .357 Cylinder T2"
	id = "starlight_cylinder_357_t2"
	build_path = /obj/item/cyberpunk_item_module/cylinder_357/t2

/datum/design/cyberpunk_item_module/cylinder_357/t3
	name = "Starlight .357 Cylinder T3"
	id = "starlight_cylinder_357_t3"
	build_path = /obj/item/cyberpunk_item_module/cylinder_357/t3

/datum/design/cyberpunk_item_module/pistol_magwell_9mm/t2
	name = "Starlight 9mm Pistol Magwell T2"
	id = "starlight_pistol_magwell_9mm_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm/t2

/datum/design/cyberpunk_item_module/pistol_magwell_9mm/t3
	name = "Starlight 9mm Pistol Magwell T3"
	id = "starlight_pistol_magwell_9mm_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm/t3

/datum/design/cyberpunk_item_module/pistol_magwell_10mm/t2
	name = "Starlight 10mm Pistol Magwell T2"
	id = "starlight_pistol_magwell_10mm_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm/t2

/datum/design/cyberpunk_item_module/pistol_magwell_10mm/t3
	name = "Starlight 10mm Pistol Magwell T3"
	id = "starlight_pistol_magwell_10mm_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm/t3

/datum/design/cyberpunk_item_module/smg_magwell_9mm/t2
	name = "Starlight 9mm SMG Magwell T2"
	id = "starlight_smg_magwell_9mm_t2"
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm/t2

/datum/design/cyberpunk_item_module/smg_magwell_9mm/t3
	name = "Starlight 9mm SMG Magwell T3"
	id = "starlight_smg_magwell_9mm_t3"
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm/t3

/datum/design/cyberpunk_item_module/rifle_magwell_223/t2
	name = "Starlight .223 Rifle Magwell T2"
	id = "starlight_rifle_magwell_223_t2"
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223/t2

/datum/design/cyberpunk_item_module/rifle_magwell_223/t3
	name = "Starlight .223 Rifle Magwell T3"
	id = "starlight_rifle_magwell_223_t3"
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223/t3

/datum/design/cyberpunk_item_module/precision_receiver/t2
	name = "Starlight Precision Receiver T2"
	id = "starlight_precision_receiver_t2"
	build_path = /obj/item/cyberpunk_item_module/precision_receiver/t2

/datum/design/cyberpunk_item_module/precision_receiver/t3
	name = "Starlight Precision Receiver T3"
	id = "starlight_precision_receiver_t3"
	build_path = /obj/item/cyberpunk_item_module/precision_receiver/t3

/datum/design/cyberpunk_item_module/damage_trigger/t2
	name = "Starlight Overpressure Trigger T2"
	id = "starlight_damage_trigger_t2"
	build_path = /obj/item/cyberpunk_item_module/damage_trigger/t2

/datum/design/cyberpunk_item_module/damage_trigger/t3
	name = "Starlight Overpressure Trigger T3"
	id = "starlight_damage_trigger_t3"
	build_path = /obj/item/cyberpunk_item_module/damage_trigger/t3

/datum/design/cyberpunk_item_module/speed_trigger/t2
	name = "Starlight Short-Reset Trigger T2"
	id = "starlight_speed_trigger_t2"
	build_path = /obj/item/cyberpunk_item_module/speed_trigger/t2

/datum/design/cyberpunk_item_module/speed_trigger/t3
	name = "Starlight Short-Reset Trigger T3"
	id = "starlight_speed_trigger_t3"
	build_path = /obj/item/cyberpunk_item_module/speed_trigger/t3

/datum/design/cyberpunk_item_module/reflex_sight/t2
	name = "Starlight Reflex Sight T2"
	id = "starlight_reflex_sight_t2"
	build_path = /obj/item/cyberpunk_item_module/reflex_sight/t2

/datum/design/cyberpunk_item_module/reflex_sight/t3
	name = "Starlight Reflex Sight T3"
	id = "starlight_reflex_sight_t3"
	build_path = /obj/item/cyberpunk_item_module/reflex_sight/t3

/datum/design/cyberpunk_item_module/tactical_light/t2
	name = "Starlight Tactical Light T2"
	id = "starlight_tactical_light_t2"
	build_path = /obj/item/cyberpunk_item_module/tactical_light/t2

/datum/design/cyberpunk_item_module/tactical_light/t3
	name = "Starlight Tactical Light T3"
	id = "starlight_tactical_light_t3"
	build_path = /obj/item/cyberpunk_item_module/tactical_light/t3

/datum/design/cyberpunk_item_module/revolver_barrel/t2
	name = "Starlight Revolver Barrel T2"
	id = "starlight_revolver_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel/t2

/datum/design/cyberpunk_item_module/revolver_barrel/t3
	name = "Starlight Revolver Barrel T3"
	id = "starlight_revolver_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel/t3

/datum/design/cyberpunk_item_module/pistol_barrel/t2
	name = "Starlight Pistol Barrel T2"
	id = "starlight_pistol_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel/t2

/datum/design/cyberpunk_item_module/pistol_barrel/t3
	name = "Starlight Pistol Barrel T3"
	id = "starlight_pistol_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel/t3

/datum/design/cyberpunk_item_module/smg_barrel/t2
	name = "Starlight SMG Barrel T2"
	id = "starlight_smg_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/smg_barrel/t2

/datum/design/cyberpunk_item_module/smg_barrel/t3
	name = "Starlight SMG Barrel T3"
	id = "starlight_smg_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/smg_barrel/t3

/datum/design/cyberpunk_item_module/rifle_barrel/t2
	name = "Starlight Rifle Barrel T2"
	id = "starlight_rifle_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel/t2

/datum/design/cyberpunk_item_module/rifle_barrel/t3
	name = "Starlight Rifle Barrel T3"
	id = "starlight_rifle_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel/t3

/datum/design/cyberpunk_item_module/shotgun_barrel/t2
	name = "Starlight Shotgun Barrel T2"
	id = "starlight_shotgun_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel/t2

/datum/design/cyberpunk_item_module/shotgun_barrel/t3
	name = "Starlight Shotgun Barrel T3"
	id = "starlight_shotgun_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel/t3

/datum/design/cyberpunk_item_module/sniper_barrel/t2
	name = "Starlight Sniper Barrel T2"
	id = "starlight_sniper_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel/t2

/datum/design/cyberpunk_item_module/sniper_barrel/t3
	name = "Starlight Sniper Barrel T3"
	id = "starlight_sniper_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel/t3

/datum/design/cyberpunk_item_module/assault_barrel/t2
	name = "Starlight Assault Barrel T2"
	id = "starlight_assault_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/assault_barrel/t2

/datum/design/cyberpunk_item_module/assault_barrel/t3
	name = "Starlight Assault Barrel T3"
	id = "starlight_assault_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/assault_barrel/t3

/datum/design/cyberpunk_item_module/lmg_barrel/t2
	name = "Starlight Machine Gun Barrel T2"
	id = "starlight_lmg_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel/t2

/datum/design/cyberpunk_item_module/lmg_barrel/t3
	name = "Starlight Machine Gun Barrel T3"
	id = "starlight_lmg_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel/t3

/datum/design/cyberpunk_item_module/rocket_barrel/t2
	name = "Starlight Launcher Tube T2"
	id = "starlight_launcher_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel/t2

/datum/design/cyberpunk_item_module/rocket_barrel/t3
	name = "Starlight Launcher Tube T3"
	id = "starlight_launcher_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel/t3

/datum/design/cyberpunk_item_module/shotgun_tube/t2
	name = "Starlight Shotgun Tube T2"
	id = "starlight_shotgun_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube/t2

/datum/design/cyberpunk_item_module/shotgun_tube/t3
	name = "Starlight Shotgun Tube T3"
	id = "starlight_shotgun_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube/t3

/datum/design/cyberpunk_item_module/sniper_chamber/t2
	name = "Starlight Sniper Chamber T2"
	id = "starlight_sniper_chamber_t2"
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber/t2

/datum/design/cyberpunk_item_module/sniper_chamber/t3
	name = "Starlight Sniper Chamber T3"
	id = "starlight_sniper_chamber_t3"
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber/t3

/datum/design/cyberpunk_item_module/assault_magwell_223/t2
	name = "Starlight .223 Assault Magwell T2"
	id = "starlight_assault_magwell_223_t2"
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223/t2

/datum/design/cyberpunk_item_module/assault_magwell_223/t3
	name = "Starlight .223 Assault Magwell T3"
	id = "starlight_assault_magwell_223_t3"
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223/t3

/datum/design/cyberpunk_item_module/lmg_feed_223/t2
	name = "Starlight .223 Belt Feed T2"
	id = "starlight_lmg_feed_223_t2"
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223/t2

/datum/design/cyberpunk_item_module/lmg_feed_223/t3
	name = "Starlight .223 Belt Feed T3"
	id = "starlight_lmg_feed_223_t3"
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223/t3

/datum/design/cyberpunk_item_module/rocket_tube/t2
	name = "Starlight Rocket Launch Tube T2"
	id = "starlight_rocket_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/rocket_tube/t2

/datum/design/cyberpunk_item_module/rocket_tube/t3
	name = "Starlight Rocket Launch Tube T3"
	id = "starlight_rocket_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/rocket_tube/t3

/datum/design/cyberpunk_item_module/laser_emitter/t2
	name = "Starlight Laser Emitter T2"
	id = "starlight_laser_emitter_t2"
	build_path = /obj/item/cyberpunk_item_module/laser_emitter/t2

/datum/design/cyberpunk_item_module/laser_emitter/t3
	name = "Starlight Laser Emitter T3"
	id = "starlight_laser_emitter_t3"
	build_path = /obj/item/cyberpunk_item_module/laser_emitter/t3

/datum/design/cyberpunk_item_module/plasma_emitter/t2
	name = "Starlight Plasma Emitter T2"
	id = "starlight_plasma_emitter_t2"
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter/t2

/datum/design/cyberpunk_item_module/plasma_emitter/t3
	name = "Starlight Plasma Emitter T3"
	id = "starlight_plasma_emitter_t3"
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter/t3
