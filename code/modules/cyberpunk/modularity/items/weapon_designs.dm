// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/datum/design/cyberpunk_weapon
	name = "Cyberpunk Modular Weapon"
	desc = "A Cyberpunk 13 modular weapon frame."
	id = "cyberpunk_weapon"
	build_type = PROTOLATHE | AUTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
//CYBERPUNK BUILD - rebuild and delete before release
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/cyberpunk_weapon/revolver_frame
	name = "Modular Revolver Frame"
	id = "cyberpunk_revolver_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk

/datum/design/cyberpunk_weapon/knife_frame
	name = "Modular Physical Melee Base"
	id = "cyberpunk_knife_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk

/datum/design/cyberpunk_weapon/energy_melee_base
	name = "Modular Energy Melee Base"
	id = "cyberpunk_energy_melee_base"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/energy

/datum/design/cyberpunk_weapon/pistol_frame
	name = "Modular Pistol Frame"
	id = "cyberpunk_pistol_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk

/datum/design/cyberpunk_weapon/smg_frame
	name = "Modular Ballistic Weapon Base"
	id = "cyberpunk_smg_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk

/datum/design/cyberpunk_weapon/rifle_frame
	name = "Modular Rifle Frame"
	id = "cyberpunk_rifle_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk

/datum/design/cyberpunk_weapon/shotgun_frame
	name = "Modular Shotgun Frame"
	id = "cyberpunk_shotgun_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/shotgun/cyberpunk

/datum/design/cyberpunk_weapon/sniper_frame
	name = "Modular Sniper Frame"
	id = "cyberpunk_sniper_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/rifle/boltaction/cyberpunk

/datum/design/cyberpunk_weapon/assault_frame
	name = "Modular Assault Rifle Frame"
	id = "cyberpunk_assault_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/ar/cyberpunk

/datum/design/cyberpunk_weapon/lmg_frame
	name = "Modular Machine Gun Frame"
	id = "cyberpunk_lmg_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/l6_saw/cyberpunk

/datum/design/cyberpunk_weapon/rocket_frame
	name = "Modular Rocket Launcher Frame"
	id = "cyberpunk_rocket_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 14, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rocketlauncher/cyberpunk

/datum/design/cyberpunk_weapon/energy_frame
	name = "Modular Energy Weapon Base"
	id = "cyberpunk_energy_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/energy/laser/cyberpunk

/datum/design/cyberpunk_weapon/revolver_frame_polymer
	name = "Polymer Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/polymer

/datum/design/cyberpunk_weapon/revolver_frame_ceramic
	name = "Ceramic Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/revolver_frame_plasteel
	name = "Plasteel Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/revolver_frame_composite
	name = "Composite Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/composite

/datum/design/cyberpunk_weapon/knife_frame_polymer
	name = "Polymer Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/polymer

/datum/design/cyberpunk_weapon/knife_frame_ceramic
	name = "Ceramic Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/knife_frame_plasteel
	name = "Plasteel Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/knife_frame_composite
	name = "Composite Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/composite

/datum/design/cyberpunk_weapon/pistol_frame_polymer
	name = "Polymer Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/polymer

/datum/design/cyberpunk_weapon/pistol_frame_ceramic
	name = "Ceramic Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/pistol_frame_plasteel
	name = "Plasteel Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/pistol_frame_composite
	name = "Composite Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/composite

/datum/design/cyberpunk_weapon/smg_frame_polymer
	name = "Polymer Modular SMG Frame"
	id = "cyberpunk_smg_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/polymer

/datum/design/cyberpunk_weapon/smg_frame_ceramic
	name = "Ceramic Modular SMG Frame"
	id = "cyberpunk_smg_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/smg_frame_plasteel
	name = "Plasteel Modular SMG Frame"
	id = "cyberpunk_smg_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/smg_frame_composite
	name = "Composite Modular SMG Frame"
	id = "cyberpunk_smg_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/composite

/datum/design/cyberpunk_weapon/rifle_frame_polymer
	name = "Polymer Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 8, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/polymer

/datum/design/cyberpunk_weapon/rifle_frame_ceramic
	name = "Ceramic Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/rifle_frame_plasteel
	name = "Plasteel Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/rifle_frame_composite
	name = "Composite Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/composite

/datum/design/cyberpunk_weapon/sentinel_revolver
	name = "Sentinel Modular Revolver"
	id = "cyberpunk_sentinel_revolver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/sentinel

/datum/design/cyberpunk_weapon/bruiser_revolver
	name = "Bruiser Modular Revolver"
	id = "cyberpunk_bruiser_revolver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/bruiser

/datum/design/cyberpunk_weapon/sidearm_pistol
	name = "Sidearm Modular Pistol"
	id = "cyberpunk_sidearm_pistol"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/sidearm

/datum/design/cyberpunk_weapon/handcannon_pistol
	name = "Handcannon Modular Pistol"
	id = "cyberpunk_handcannon_pistol"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/handcannon

/datum/design/cyberpunk_weapon/sprinter_smg
	name = "Sprinter Modular SMG"
	id = "cyberpunk_sprinter_smg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/sprinter

/datum/design/cyberpunk_weapon/breacher_smg
	name = "Breacher Modular SMG"
	id = "cyberpunk_breacher_smg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/breacher

/datum/design/cyberpunk_weapon/marksman_rifle
	name = "Marksman Modular Rifle"
	id = "cyberpunk_marksman_rifle"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/marksman

/datum/design/cyberpunk_weapon/patrol_rifle
	name = "Patrol Modular Rifle"
	id = "cyberpunk_patrol_rifle"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 11, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/patrol

/datum/design/cyberpunk_weapon/room_clearer_shotgun
	name = "Room-Clearer Modular Shotgun"
	id = "cyberpunk_room_clearer_shotgun"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/shotgun/cyberpunk/room_clearer

/datum/design/cyberpunk_weapon/longwatch_sniper
	name = "Longwatch Modular Sniper"
	id = "cyberpunk_longwatch_sniper"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 13, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/boltaction/cyberpunk/longwatch

/datum/design/cyberpunk_weapon/streetline_assault
	name = "Streetline Modular Assault Rifle"
	id = "cyberpunk_streetline_assault"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/ar/cyberpunk/streetline

/datum/design/cyberpunk_weapon/suppressor_lmg
	name = "Suppressor Modular LMG"
	id = "cyberpunk_suppressor_lmg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 16, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/l6_saw/cyberpunk/suppressor

/datum/design/cyberpunk_weapon/punchline_launcher
	name = "Punchline Modular Rocket Launcher"
	id = "cyberpunk_punchline_launcher"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 18, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 5, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/rocketlauncher/cyberpunk/punchline

/datum/design/cyberpunk_weapon/radiant_laser
	name = "Radiant Modular Laser"
	id = "cyberpunk_radiant_laser"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 11, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/energy/laser/cyberpunk/radiant

/datum/design/cyberpunk_weapon/plasma_arc
	name = "Plasma Arc Modular Projector"
	id = "cyberpunk_plasma_arc"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/energy/laser/cyberpunk/plasma

/datum/design/cyberpunk_weapon/razor_knife
	name = "Razor Modular Knife"
	id = "cyberpunk_razor_knife"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/razor

/datum/design/cyberpunk_weapon/puncture_knife
	name = "Puncture Modular Knife"
	id = "cyberpunk_puncture_knife"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/puncture

/datum/design/cyberpunk_weapon/breaker_club
	name = "Breaker Modular Club"
	id = "cyberpunk_breaker_club"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/club

/datum/design/cyberpunk_weapon/linebreaker_sword
	name = "Linebreaker Modular Two-Handed Sword"
	id = "cyberpunk_linebreaker_sword"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_sword

/datum/design/cyberpunk_weapon/piledriver_hammer
	name = "Pile-Driver Modular Two-Handed Hammer"
	id = "cyberpunk_piledriver_hammer"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_hammer

/datum/design/cyberpunk_weapon/streetcutter_axe
	name = "Street-Cutter Modular Axe"
	id = "cyberpunk_streetcutter_axe"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/axe

/datum/design/cyberpunk_weapon/gatecrack_axe
	name = "Gatecrack Modular Two-Handed Axe"
	id = "cyberpunk_gatecrack_axe"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_axe

/datum/design/cyberpunk_weapon/needlepoint_rapier
	name = "Needlepoint Modular Rapier"
	id = "cyberpunk_needlepoint_rapier"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/rapier

/datum/design/cyberpunk_weapon/longreach_spear
	name = "Longreach Modular Spear"
	id = "cyberpunk_longreach_spear"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/spear

/datum/design/cyberpunk_weapon/crowdline_staff
	name = "Crowdline Modular Staff"
	id = "cyberpunk_crowdline_staff"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/staff

/datum/design/cyberpunk_weapon/hotline_energy_blade
	name = "Hotline Modular Energy Blade"
	id = "cyberpunk_hotline_energy_blade"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/energy_blade

/datum/design/cyberpunk_weapon/crowdline_shock_staff
	name = "Crowdline Modular Shock Staff"
	id = "cyberpunk_crowdline_shock_staff"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/shock_staff
