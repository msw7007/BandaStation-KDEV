// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/datum/cyberpunk_item_module/melee_core
	name = "melee core"
	module_slot = "core"
	integrity_delta = 20

/datum/cyberpunk_item_module/melee_core/t2
	name = "melee core T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_core/t3
	name = "melee core T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_blade
	name = "blade element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "twohand_sword", "axe", "twohand_axe")
	weapon_form_override = "knife"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 1)
	force_multiplier = 1.15
	armour_penetration_delta = 5

/datum/cyberpunk_item_module/melee_blade/t2
	name = "blade element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_blade/t3
	name = "blade element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_blade/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_blade/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_spike
	name = "spike element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "rapier", "spear")
	weapon_form_override = "rapier"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 1)
	force_multiplier = 1.05
	armour_penetration_delta = 10

/datum/cyberpunk_item_module/melee_spike/t2
	name = "spike element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_spike/t3
	name = "spike element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_spike/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_spike/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_head
	name = "weighted head"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "club", "twohand_hammer", "staff")
	weapon_form_override = "club"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.2
	attack_speed_multiplier = 1.1

/datum/cyberpunk_item_module/melee_head/t2
	name = "weighted head T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_head/t3
	name = "weighted head T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_head/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_head/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_knife_element
	name = "knife attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife")
	weapon_form_override = "knife"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.65, BODYPART_DAMAGE_PIERCE = 0.35)
	force_multiplier = 1.08
	attack_speed_multiplier = 0.9
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/melee_knife_element/t2
	name = "knife attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_knife_element/t3
	name = "knife attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_club_element
	name = "club attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "club")
	weapon_form_override = "club"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.2
	attack_speed_multiplier = 1.08
	guard_delta = 6

/datum/cyberpunk_item_module/melee_club_element/t2
	name = "club attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_club_element/t3
	name = "club attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_sword_element
	name = "two-handed sword attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_sword")
	weapon_form_override = "twohand_sword"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.75, BODYPART_DAMAGE_PIERCE = 0.25)
	weight_delta = 2
	force_multiplier = 1.35
	attack_speed_multiplier = 1.18
	armour_penetration_delta = 8
	guard_delta = 12

/datum/cyberpunk_item_module/melee_twohand_sword_element/t2
	name = "two-handed sword attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_sword_element/t3
	name = "two-handed sword attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_hammer_element
	name = "two-handed hammer attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_hammer")
	weapon_form_override = "twohand_hammer"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 3
	force_multiplier = 1.55
	attack_speed_multiplier = 1.35
	armour_penetration_delta = 12
	guard_delta = 8

/datum/cyberpunk_item_module/melee_twohand_hammer_element/t2
	name = "two-handed hammer attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_hammer_element/t3
	name = "two-handed hammer attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_axe_element
	name = "axe attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "axe")
	weapon_form_override = "axe"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.85, BODYPART_DAMAGE_BLUNT = 0.15)
	weight_delta = 1
	force_multiplier = 1.25
	attack_speed_multiplier = 1.1
	armour_penetration_delta = 6

/datum/cyberpunk_item_module/melee_axe_element/t2
	name = "axe attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_axe_element/t3
	name = "axe attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_axe_element
	name = "two-handed axe attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_axe")
	weapon_form_override = "twohand_axe"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.8, BODYPART_DAMAGE_BLUNT = 0.2)
	weight_delta = 3
	force_multiplier = 1.48
	attack_speed_multiplier = 1.3
	armour_penetration_delta = 10
	guard_delta = 6

/datum/cyberpunk_item_module/melee_twohand_axe_element/t2
	name = "two-handed axe attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_axe_element/t3
	name = "two-handed axe attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_rapier_element
	name = "rapier attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "rapier")
	weapon_form_override = "rapier"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 0.9, BODYPART_DAMAGE_SLASH = 0.1)
	force_multiplier = 1.02
	attack_speed_multiplier = 0.85
	armour_penetration_delta = 14
	guard_delta = 5

/datum/cyberpunk_item_module/melee_rapier_element/t2
	name = "rapier attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_rapier_element/t3
	name = "rapier attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_spear_element
	name = "spear attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "spear")
	weapon_form_override = "spear"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 0.75, BODYPART_DAMAGE_BLUNT = 0.25)
	weight_delta = 2
	force_multiplier = 1.22
	attack_speed_multiplier = 1.05
	armour_penetration_delta = 12
	guard_delta = 10

/datum/cyberpunk_item_module/melee_spear_element/t2
	name = "spear attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_spear_element/t3
	name = "spear attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_staff_element
	name = "staff attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "staff")
	weapon_form_override = "staff"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.12
	attack_speed_multiplier = 0.95
	guard_delta = 18

/datum/cyberpunk_item_module/melee_staff_element/t2
	name = "staff attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_staff_element/t3
	name = "staff attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/guard
	name = "guard"
	module_slot = "guard"
	guard_delta = 15
	weight_delta = 1

/datum/cyberpunk_item_module/guard/t2
	name = "guard T2"
	module_tier = 2

/datum/cyberpunk_item_module/guard/t3
	name = "guard T3"
	module_tier = 3

/datum/cyberpunk_item_module/balancer
	name = "balancer"
	module_slot = "balance"
	attack_speed_multiplier = 0.9
	guard_delta = 5

/datum/cyberpunk_item_module/balancer/t2
	name = "balancer T2"
	module_tier = 2

/datum/cyberpunk_item_module/balancer/t3
	name = "balancer T3"
	module_tier = 3

/datum/cyberpunk_item_module/shock_coating
	name = "shock weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "club", "twohand_sword", "twohand_hammer", "axe", "twohand_axe", "rapier", "spear", "staff")
	melee_stamina_damage_delta = 8
	melee_shock_chance_delta = 18
	armour_penetration_delta = 2

/datum/cyberpunk_item_module/shock_coating/t2
	name = "shock weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/shock_coating/t3
	name = "shock weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/thermal_coating
	name = "thermal weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "club", "twohand_sword", "twohand_hammer", "axe", "twohand_axe", "rapier", "spear", "staff")
	melee_damage_profile = list(BODYPART_DAMAGE_HEAT = 0.35, BODYPART_DAMAGE_SLASH = 0.65)
	melee_burn_damage_delta = 4
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/thermal_coating/t2
	name = "thermal weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/thermal_coating/t3
	name = "thermal weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/serrated_coating
	name = "serrated weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "twohand_sword", "axe", "twohand_axe", "rapier", "spear")
	force_multiplier = 1.08
	armour_penetration_delta = 3
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.8, BODYPART_DAMAGE_PIERCE = 0.2)

/datum/cyberpunk_item_module/serrated_coating/t2
	name = "serrated weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/serrated_coating/t3
	name = "serrated weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/firearm_core
	name = "firearm core"
	module_slot = "core"
	integrity_delta = 15
	guard_delta = 5

/datum/cyberpunk_item_module/firearm_core/t2
	name = "firearm core T2"
	module_tier = 2

/datum/cyberpunk_item_module/firearm_core/t3
	name = "firearm core T3"
	module_tier = 3

/datum/cyberpunk_item_module/heavy_barrel
	name = "heavy barrel"
	module_slot = "barrel"
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.12
	gun_projectile_wound_bonus_delta = 4
	gun_spread_delta = 3
	gun_fire_delay_multiplier = 1.1

/datum/cyberpunk_item_module/heavy_barrel/t2
	name = "heavy barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/heavy_barrel/t3
	name = "heavy barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/long_barrel
	name = "long barrel"
	module_slot = "barrel"
	weight_delta = 1
	gun_spread_delta = -5
	gun_projectile_speed_multiplier_delta = 0.12
	gun_fire_delay_multiplier = 1.05

/datum/cyberpunk_item_module/long_barrel/t2
	name = "long barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/long_barrel/t3
	name = "long barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/revolver_barrel
	name = "revolver barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "revolver")
	weapon_form_override = "revolver"
	gun_spread_delta = -2

/datum/cyberpunk_item_module/revolver_barrel/t2
	name = "revolver barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/revolver_barrel/t3
	name = "revolver barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_barrel
	name = "pistol barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "pistol")
	weapon_form_override = "pistol"
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/pistol_barrel/t2
	name = "pistol barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_barrel/t3
	name = "pistol barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/smg_barrel
	name = "SMG barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "smg")
	weapon_form_override = "smg"
	gun_fire_delay_multiplier = 0.9
	gun_spread_delta = 3

/datum/cyberpunk_item_module/smg_barrel/t2
	name = "SMG barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/smg_barrel/t3
	name = "SMG barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/rifle_barrel
	name = "rifle barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "rifle")
	weapon_form_override = "rifle"
	weight_delta = 1
	gun_spread_delta = -4
	gun_projectile_speed_multiplier_delta = 0.05

/datum/cyberpunk_item_module/rifle_barrel/t2
	name = "rifle barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/rifle_barrel/t3
	name = "rifle barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/shotgun_barrel
	name = "shotgun barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "shotgun")
	weapon_form_override = "shotgun"
	weight_delta = 1
	gun_spread_delta = 8
	gun_projectile_wound_bonus_delta = 4

/datum/cyberpunk_item_module/shotgun_barrel/t2
	name = "shotgun barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/shotgun_barrel/t3
	name = "shotgun barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/sniper_barrel
	name = "sniper barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "sniper")
	weapon_form_override = "sniper"
	weight_delta = 2
	gun_spread_delta = -12
	gun_fire_delay_multiplier = 1.2
	gun_projectile_speed_multiplier_delta = 0.15

/datum/cyberpunk_item_module/sniper_barrel/t2
	name = "sniper barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/sniper_barrel/t3
	name = "sniper barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/assault_barrel
	name = "assault barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "assault")
	weapon_form_override = "assault"
	weight_delta = 1
	gun_spread_delta = 2
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/assault_barrel/t2
	name = "assault barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/assault_barrel/t3
	name = "assault barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/lmg_barrel
	name = "machine gun barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "lmg")
	weapon_form_override = "lmg"
	weight_delta = 2
	gun_spread_delta = 6
	gun_fire_delay_multiplier = 0.85

/datum/cyberpunk_item_module/lmg_barrel/t2
	name = "machine gun barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/lmg_barrel/t3
	name = "machine gun barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/rocket_barrel
	name = "launcher tube"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "rocket")
	weapon_form_override = "rocket"
	weight_delta = 3
	gun_fire_delay_multiplier = 1.15

/datum/cyberpunk_item_module/rocket_barrel/t2
	name = "launcher tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/rocket_barrel/t3
	name = "launcher tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/cylinder_50
	name = ".50 revolver cylinder"
	module_slot = "action"
	allowed_weapon_forms = list("revolver")
	weight_delta = 1
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder
	gun_ammo_type = /obj/item/ammo_casing/a50ae
	gun_caliber = CALIBER_50AE
	gun_fire_delay_multiplier = 1.25
	gun_projectile_damage_multiplier_delta = 0.2
	gun_projectile_wound_bonus_delta = 6

/datum/cyberpunk_item_module/cylinder_50/t2
	name = ".50 revolver cylinder T2"
	module_tier = 2

/datum/cyberpunk_item_module/cylinder_50/t3
	name = ".50 revolver cylinder T3"
	module_tier = 3

/datum/cyberpunk_item_module/cylinder_357
	name = ".357 revolver cylinder"
	module_slot = "action"
	allowed_weapon_forms = list("revolver")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder
	gun_ammo_type = /obj/item/ammo_casing/c357
	gun_caliber = CALIBER_357
	gun_projectile_damage_multiplier_delta = 0.05

/datum/cyberpunk_item_module/cylinder_357/t2
	name = ".357 revolver cylinder T2"
	module_tier = 2

/datum/cyberpunk_item_module/cylinder_357/t3
	name = ".357 revolver cylinder T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_magwell_9mm
	name = "9mm pistol magwell"
	module_slot = "action"
	allowed_weapon_forms = list("pistol")
	gun_magazine_type = /obj/item/ammo_box/magazine/m9mm
	gun_ammo_type = /obj/item/ammo_casing/c9mm
	gun_caliber = CALIBER_9MM
	gun_projectile_damage_multiplier_delta = -0.05
	gun_fire_delay_multiplier = 0.9

/datum/cyberpunk_item_module/pistol_magwell_9mm/t2
	name = "9mm pistol magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_magwell_9mm/t3
	name = "9mm pistol magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_magwell_10mm
	name = "10mm pistol magwell"
	module_slot = "action"
	allowed_weapon_forms = list("pistol")
	gun_magazine_type = /obj/item/ammo_box/magazine/m10mm
	gun_ammo_type = /obj/item/ammo_casing/c10mm
	gun_caliber = CALIBER_10MM
	gun_projectile_damage_multiplier_delta = 0.05
	gun_fire_delay_multiplier = 1.05

/datum/cyberpunk_item_module/pistol_magwell_10mm/t2
	name = "10mm pistol magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_magwell_10mm/t3
	name = "10mm pistol magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/smg_magwell_9mm
	name = "9mm SMG magwell"
	module_slot = "action"
	allowed_weapon_forms = list("smg")
	gun_magazine_type = /obj/item/ammo_box/magazine/smgm9mm
	gun_ammo_type = /obj/item/ammo_casing/c9mm
	gun_caliber = CALIBER_9MM
	gun_fire_delay_multiplier = 0.85
	gun_spread_delta = 3

/datum/cyberpunk_item_module/smg_magwell_9mm/t2
	name = "9mm SMG magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/smg_magwell_9mm/t3
	name = "9mm SMG magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/rifle_magwell_223
	name = ".223 rifle magwell"
	module_slot = "action"
	allowed_weapon_forms = list("rifle")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.12
	gun_projectile_speed_multiplier_delta = 0.1
	gun_fire_delay_multiplier = 1.15

/datum/cyberpunk_item_module/rifle_magwell_223/t2
	name = ".223 rifle magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/rifle_magwell_223/t3
	name = ".223 rifle magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/shotgun_tube
	name = "shotgun tube"
	module_slot = "action"
	allowed_weapon_forms = list("shotgun")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/shot/lethal
	gun_ammo_type = /obj/item/ammo_casing/shotgun
	gun_caliber = CALIBER_SHOTGUN
	weight_delta = 1
	gun_spread_delta = 10
	gun_fire_delay_multiplier = 1.2
	gun_projectile_wound_bonus_delta = 5

/datum/cyberpunk_item_module/shotgun_tube/t2
	name = "shotgun tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/shotgun_tube/t3
	name = "shotgun tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/sniper_chamber
	name = "sniper chamber"
	module_slot = "action"
	allowed_weapon_forms = list("sniper")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 1
	gun_spread_delta = -10
	gun_fire_delay_multiplier = 1.35
	gun_projectile_damage_multiplier_delta = 0.22
	gun_projectile_wound_bonus_delta = 8
	gun_projectile_speed_multiplier_delta = 0.18

/datum/cyberpunk_item_module/sniper_chamber/t2
	name = "sniper chamber T2"
	module_tier = 2

/datum/cyberpunk_item_module/sniper_chamber/t3
	name = "sniper chamber T3"
	module_tier = 3

/datum/cyberpunk_item_module/assault_magwell_223
	name = ".223 assault magwell"
	module_slot = "action"
	allowed_weapon_forms = list("assault")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	gun_fire_delay_multiplier = 0.95
	gun_spread_delta = 4
	gun_projectile_damage_multiplier_delta = 0.04

/datum/cyberpunk_item_module/assault_magwell_223/t2
	name = ".223 assault magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/assault_magwell_223/t3
	name = ".223 assault magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/lmg_feed_223
	name = ".223 belt feed"
	module_slot = "action"
	allowed_weapon_forms = list("lmg")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 2
	gun_fire_delay_multiplier = 0.8
	gun_spread_delta = 8
	gun_projectile_damage_multiplier_delta = -0.05

/datum/cyberpunk_item_module/lmg_feed_223/t2
	name = ".223 belt feed T2"
	module_tier = 2

/datum/cyberpunk_item_module/lmg_feed_223/t3
	name = ".223 belt feed T3"
	module_tier = 3

/datum/cyberpunk_item_module/rocket_tube
	name = "rocket launch tube"
	module_slot = "action"
	allowed_weapon_forms = list("rocket")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/rocketlauncher
	gun_ammo_type = /obj/item/ammo_casing/rocket
	weight_delta = 3
	gun_fire_delay_multiplier = 1.25
	gun_projectile_damage_multiplier_delta = 0.1

/datum/cyberpunk_item_module/rocket_tube/t2
	name = "rocket launch tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/rocket_tube/t3
	name = "rocket launch tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/laser_emitter
	name = "laser emitter"
	module_slot = "barrel"
	allowed_weapon_forms = list("energy", "laser")
	weapon_form_override = "laser"
	gun_energy_ammo_types = list(/obj/item/ammo_casing/energy/lasergun)
	gun_projectile_speed_multiplier_delta = 0.08
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/laser_emitter/t2
	name = "laser emitter T2"
	module_tier = 2

/datum/cyberpunk_item_module/laser_emitter/t3
	name = "laser emitter T3"
	module_tier = 3

/datum/cyberpunk_item_module/plasma_emitter
	name = "plasma emitter"
	module_slot = "barrel"
	allowed_weapon_forms = list("energy", "plasma")
	weapon_form_override = "plasma"
	gun_energy_ammo_types = list(/obj/item/ammo_casing/energy/plasma)
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.16
	gun_projectile_wound_bonus_delta = 6
	gun_fire_delay_multiplier = 1.2

/datum/cyberpunk_item_module/plasma_emitter/t2
	name = "plasma emitter T2"
	module_tier = 2

/datum/cyberpunk_item_module/plasma_emitter/t3
	name = "plasma emitter T3"
	module_tier = 3

/datum/cyberpunk_item_module/precision_receiver
	name = "precision receiver"
	module_slot = "receiver"
	gun_spread_delta = -8
	gun_projectile_speed_multiplier_delta = 0.08
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/precision_receiver/t2
	name = "precision receiver T2"
	module_tier = 2

/datum/cyberpunk_item_module/precision_receiver/t3
	name = "precision receiver T3"
	module_tier = 3

/datum/cyberpunk_item_module/damage_trigger
	name = "overpressure trigger"
	module_slot = "trigger"
	gun_projectile_damage_multiplier_delta = 0.1
	gun_fire_delay_multiplier = 1.08

/datum/cyberpunk_item_module/damage_trigger/t2
	name = "overpressure trigger T2"
	module_tier = 2

/datum/cyberpunk_item_module/damage_trigger/t3
	name = "overpressure trigger T3"
	module_tier = 3

/datum/cyberpunk_item_module/speed_trigger
	name = "short-reset trigger"
	module_slot = "trigger"
	gun_fire_delay_multiplier = 0.85
	gun_spread_delta = 2

/datum/cyberpunk_item_module/speed_trigger/t2
	name = "short-reset trigger T2"
	module_tier = 2

/datum/cyberpunk_item_module/speed_trigger/t3
	name = "short-reset trigger T3"
	module_tier = 3

/datum/cyberpunk_item_module/reflex_sight
	name = "reflex sight"
	module_slot = "sight"
	weight_delta = 0
	gun_spread_delta = -6

/datum/cyberpunk_item_module/reflex_sight/t2
	name = "reflex sight T2"
	module_tier = 2

/datum/cyberpunk_item_module/reflex_sight/t3
	name = "reflex sight T3"
	module_tier = 3

/datum/cyberpunk_item_module/tactical_light
	name = "tactical light"
	module_slot = "underbarrel"
	weight_delta = 1
	gun_spread_delta = -2
	active_ability_name = "weapon light"
	active_ability_description = "The underslung light floods the target area."
	active_cooldown = 12 SECONDS
	active_duration = 6 SECONDS

/datum/cyberpunk_item_module/tactical_light/t2
	name = "tactical light T2"
	module_tier = 2

/datum/cyberpunk_item_module/tactical_light/t3
	name = "tactical light T3"
	module_tier = 3
