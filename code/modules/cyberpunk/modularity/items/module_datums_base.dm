// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/datum/cyberpunk_item_module
	var/name = "item module"
	var/manufacturer = "independent"
	var/quality = 100
	var/module_slot = "utility"
	var/module_tier = 1
	var/weight_delta = 0
	var/integrity_delta = 0
	var/slowdown_delta = 0
	var/force_multiplier = 1
	var/attack_speed_multiplier = 1
	var/armour_penetration_delta = 0
	var/guard_delta = 0
	var/list/armor_delta
	var/applied_weight_delta = 0
	var/applied_integrity_delta = 0
	var/applied_force_multiplier = 1
	var/applied_attack_speed_multiplier = 1
	var/applied_armour_penetration_delta = 0
	var/applied_guard_delta = 0
	var/list/previous_damage_profile
	var/active_ability_name
	var/active_ability_description
	var/active_cooldown = 30 SECONDS
	var/active_duration = 8 SECONDS
	var/list/active_armor_delta
	var/active_slowdown_delta = 0
	var/active_stamina_restore = 0
	var/active_brute_heal = 0
	var/active_burn_heal = 0
	var/active_extinguish = FALSE
	var/active_next_use = 0
	var/gun_spread_delta = 0
	var/gun_fire_delay_multiplier = 1
	var/gun_projectile_damage_multiplier_delta = 0
	var/gun_projectile_wound_bonus_delta = 0
	var/gun_projectile_speed_multiplier_delta = 0
	var/gun_magazine_type
	var/gun_ammo_type
	var/list/gun_energy_ammo_types
	var/gun_caliber
	var/weapon_form_override
	var/list/allowed_weapon_forms
	var/list/melee_damage_profile
	var/melee_stamina_damage_delta = 0
	var/melee_burn_damage_delta = 0
	var/melee_shock_chance_delta = 0
	var/module_variant = "standard"

/datum/cyberpunk_item_module/proc/get_effective_scale()
	return 1 + max(0, module_tier - 1) * 0.15

/datum/cyberpunk_item_module/proc/apply_cyberpunk_module_variant()
	switch(module_variant)
		if("lightweight")
			weight_delta -= 1
			integrity_delta -= 5
			force_multiplier = 1 + ((force_multiplier - 1) * 0.85)
			attack_speed_multiplier *= 0.92
			gun_fire_delay_multiplier *= 0.92
			gun_spread_delta += 1
			fit_armor_delta_modifier(-2)
			if(active_cooldown)
				active_cooldown = round(active_cooldown * 0.9)
		if("reinforced")
			weight_delta += 1
			integrity_delta += 20
			force_multiplier *= 1.06
			attack_speed_multiplier *= 1.08
			gun_fire_delay_multiplier *= 1.08
			guard_delta += 5
			melee_stamina_damage_delta += 2
			fit_armor_delta_modifier(3)
			if(active_duration)
				active_duration = round(active_duration * 1.15)
		if("precision")
			armour_penetration_delta += 4
			gun_spread_delta -= 4
			gun_projectile_speed_multiplier_delta += 0.05
			guard_delta += 2
			force_multiplier *= 0.98
			gun_fire_delay_multiplier *= 1.03
			melee_shock_chance_delta += 4

/datum/cyberpunk_item_module/proc/fit_armor_delta_modifier(amount)
	if(!amount)
		return
	if(!length(armor_delta))
		if(module_slot in list("plate", "lining", "shell", "visor", "guard"))
			armor_delta = list(MELEE = amount, BULLET = amount, LASER = amount)
		return
	for(var/armor_key in armor_delta)
		armor_delta[armor_key] += amount

/datum/cyberpunk_item_module/proc/has_active_ability()
	return !!active_ability_name

/datum/cyberpunk_item_module/proc/get_active_cooldown()
	return max(1 SECONDS, round(active_cooldown / get_effective_scale()))

/datum/cyberpunk_item_module/proc/get_active_duration()
	return max(1 SECONDS, round(active_duration * get_effective_scale()))

/datum/cyberpunk_item_module/proc/activate(obj/item/equipment, mob/living/user)
	if(!has_active_ability() || !equipment || !user)
		return FALSE
	if(world.time < active_next_use)
		to_chat(user, span_warning("[active_ability_name] is recharging for [DisplayTimeText(active_next_use - world.time, round_seconds_to = 1)]."))
		return FALSE
	if(!(equipment in user.get_all_contents()))
		to_chat(user, span_warning("You need to wear or hold [equipment] to activate [active_ability_name]."))
		return FALSE
	var/effect_scale = get_effective_scale()
	var/list/scaled_armor = list()
	for(var/armor_key in active_armor_delta)
		scaled_armor[armor_key] = round(active_armor_delta[armor_key] * effect_scale)
	var/scaled_slowdown = active_slowdown_delta ? active_slowdown_delta * effect_scale : 0
	if(length(scaled_armor) || scaled_slowdown)
		equipment.add_cyberpunk_module_active(src, scaled_armor, scaled_slowdown, get_active_duration())
	if(active_stamina_restore)
		user.adjust_stamina_loss(-round(active_stamina_restore * effect_scale), forced = TRUE)
	if(active_brute_heal)
		user.adjust_brute_loss(-round(active_brute_heal * effect_scale), forced = TRUE)
	if(active_burn_heal)
		user.adjust_fire_loss(-round(active_burn_heal * effect_scale), forced = TRUE)
	if(active_extinguish)
		user.extinguish_mob()
		user.adjust_fire_stacks(-round(4 * effect_scale))
	active_next_use = world.time + get_active_cooldown()
	user.visible_message(span_notice("[user] activates [active_ability_name] on [equipment]."), span_notice("You activate [active_ability_name] on [equipment]. [active_ability_description]"))
	return TRUE

/datum/cyberpunk_item_module/proc/can_install(obj/item/target, mob/living/user)
	if(length(allowed_weapon_forms) && target?.cyberpunk_weapon_form)
		var/effective_form = target.get_cyberpunk_effective_weapon_form()
		var/base_form = target.cyberpunk_weapon_form
		if(!(effective_form in allowed_weapon_forms) && !(base_form in allowed_weapon_forms))
			return FALSE
	return istype(target) && target.can_accept_cyberpunk_module(src)

/datum/cyberpunk_item_module/proc/apply_weapon_stats(obj/item/target)
	if(!target)
		return
	var/effect_scale = get_effective_scale()
	if(weight_delta)
		target.w_class = clamp(target.w_class + round(weight_delta * effect_scale), WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(force_multiplier != 1)
		target.force *= 1 + ((force_multiplier - 1) * effect_scale)
	if(attack_speed_multiplier != 1)
		target.attack_speed *= 1 + ((attack_speed_multiplier - 1) * effect_scale)
	if(armour_penetration_delta)
		target.armour_penetration += round(armour_penetration_delta * effect_scale)
	if(guard_delta)
		target.cyberpunk_guard_value = target.get_cyberpunk_guard_value() + round(guard_delta * effect_scale)
	if(length(melee_damage_profile))
		target.cyberpunk_damage_profile = melee_damage_profile.Copy()
	if(melee_stamina_damage_delta)
		target.cyberpunk_melee_module_stamina_damage += round(melee_stamina_damage_delta * effect_scale)
	if(melee_burn_damage_delta)
		target.cyberpunk_melee_module_burn_damage += round(melee_burn_damage_delta * effect_scale)
	if(melee_shock_chance_delta)
		target.cyberpunk_melee_module_shock_chance += round(melee_shock_chance_delta * effect_scale)
	var/obj/item/gun/gun = target
	if(istype(gun))
		if(gun_spread_delta)
			gun.spread = max(0, gun.spread + round(gun_spread_delta * effect_scale))
		if(gun_fire_delay_multiplier != 1)
			gun.fire_delay = max(0, round(gun.fire_delay * (1 + ((gun_fire_delay_multiplier - 1) * effect_scale))))
		if(gun_projectile_damage_multiplier_delta)
			gun.projectile_damage_multiplier += gun_projectile_damage_multiplier_delta * effect_scale
		if(gun_projectile_wound_bonus_delta)
			gun.projectile_wound_bonus += round(gun_projectile_wound_bonus_delta * effect_scale)
		if(gun_projectile_speed_multiplier_delta)
			gun.projectile_speed_multiplier += gun_projectile_speed_multiplier_delta * effect_scale
		if(gun_magazine_type && ("accepted_magazine_type" in gun.vars))
			gun.vars["accepted_magazine_type"] = gun_magazine_type
		if(gun_magazine_type && ("spawn_magazine_type" in gun.vars))
			gun.vars["spawn_magazine_type"] = gun_magazine_type
		if(gun_ammo_type && ("ammo_type" in gun.vars))
			gun.vars["ammo_type"] = gun_ammo_type
		if(length(gun_energy_ammo_types) && ("ammo_type" in gun.vars))
			gun.vars["ammo_type"] = gun_energy_ammo_types.Copy()
		if(gun_caliber && ("caliber" in gun.vars))
			gun.vars["caliber"] = gun_caliber
		var/obj/item/gun/energy/energy_gun = target
		if(istype(energy_gun) && length(gun_energy_ammo_types))
			energy_gun.select = 1
			energy_gun.update_ammo_types()
			energy_gun.recharge_newshot(TRUE)
			energy_gun.update_appearance()

/datum/cyberpunk_item_module/proc/on_install(obj/item/target, mob/living/user)
	if(!target)
		return
	target.cyberpunk_quality = max(target.cyberpunk_quality, quality)
	if(target.cyberpunk_equipment_form)
		target.recalculate_cyberpunk_equipment_stats()
		return
	if(target.cyberpunk_weapon_form)
		target.recalculate_cyberpunk_weapon_stats()
		return
	var/effect_scale = get_effective_scale()
	if(weight_delta)
		applied_weight_delta = round(weight_delta * effect_scale)
		target.w_class = clamp(target.w_class + applied_weight_delta, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(integrity_delta && target.uses_integrity)
		applied_integrity_delta = round(integrity_delta * effect_scale)
		target.modify_max_integrity(max(1, target.max_integrity + applied_integrity_delta), FALSE)
	if(force_multiplier != 1)
		applied_force_multiplier = 1 + ((force_multiplier - 1) * effect_scale)
		target.force *= applied_force_multiplier
	if(attack_speed_multiplier != 1)
		applied_attack_speed_multiplier = 1 + ((attack_speed_multiplier - 1) * effect_scale)
		target.attack_speed *= applied_attack_speed_multiplier
	if(armour_penetration_delta)
		applied_armour_penetration_delta = round(armour_penetration_delta * effect_scale)
		target.armour_penetration += applied_armour_penetration_delta
	if(guard_delta)
		applied_guard_delta = round(guard_delta * effect_scale)
		target.cyberpunk_guard_value = target.get_cyberpunk_guard_value() + applied_guard_delta
	if(length(armor_delta))
		var/datum/armor/current_armor = target.get_armor()
		var/list/scaled_armor_delta = list()
		for(var/armor_key in armor_delta)
			scaled_armor_delta[armor_key] = round(armor_delta[armor_key] * effect_scale)
		target.set_armor(current_armor.generate_new_with_modifiers(scaled_armor_delta))

/datum/cyberpunk_item_module/proc/on_remove(obj/item/target, mob/living/user)
	if(!target)
		return
	if(target.cyberpunk_equipment_form)
		target.recalculate_cyberpunk_equipment_stats()
		return
	if(target.cyberpunk_weapon_form)
		target.recalculate_cyberpunk_weapon_stats()
		return
	if(applied_weight_delta)
		target.w_class = clamp(target.w_class - applied_weight_delta, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(applied_integrity_delta && target.uses_integrity)
		target.modify_max_integrity(max(1, target.max_integrity - applied_integrity_delta), FALSE)
	if(applied_force_multiplier != 1)
		target.force /= applied_force_multiplier
	if(applied_attack_speed_multiplier != 1)
		target.attack_speed /= applied_attack_speed_multiplier
	if(applied_armour_penetration_delta)
		target.armour_penetration -= applied_armour_penetration_delta
	if(applied_guard_delta)
		target.cyberpunk_guard_value = max(0, target.get_cyberpunk_guard_value() - applied_guard_delta)
	if(length(armor_delta))
		var/datum/armor/current_armor = target.get_armor()
		var/list/inverse_armor_delta = list()
		for(var/armor_key in armor_delta)
			inverse_armor_delta[armor_key] = -armor_delta[armor_key]
		target.set_armor(current_armor.generate_new_with_modifiers(inverse_armor_delta))
