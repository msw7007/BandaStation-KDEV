/datum/skill/physical
	abstract_type = /datum/skill/physical
	skill_kind = CHARACTER_SKILL_KIND_PHYSICAL
	point_pool = CHARACTER_SKILL_POOL_ATTRIBUTE
	max_character_level = PHYSICAL_SKILL_MAX_LEVEL
	max_perk_rank = PHYSICAL_PERK_MAX_RANK
	requires_sequential_perks = TRUE

/datum/skill_perk/physical
	max_rank = PHYSICAL_PERK_MAX_RANK

/datum/skill_perk/professional
	max_rank = PROFESSIONAL_PERK_MAX_RANK

/// Shared Cyberpunk 13 object/machinery skill adapter layer.
/// These procs intentionally do not own object behavior; callsites decide when a
/// construction, repair, dismantle, damage, salvage, or diagnostic action applies.
/mob/living/proc/get_cyberpunk_skill_perk_bonus(skill_path, perk_index, effect_key = null)
	if(!mind)
		return 0
	return mind.get_character_perk_effectiveness(skill_path, perk_index, effect_key)

/mob/living/proc/get_cyberpunk_structure_work_speed_modifier(atom/target, action = "work")
	var/highest_bonus = 0

	if(target?.is_cyberpunk_structure_target())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5))

	if(istype(target, /obj/machinery))
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5))

	switch(target?.get_cyberpunk_structure_category())
		if("mobile_structure")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 1))
		if("foldable_structure")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 1))
		if("nonmobile_mechanism")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5), get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3))

	switch(action)
		if("build", "assemble", "construction")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 1))
		if("dismantle", "disassemble", "deconstruct")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 2))
			if(target?.is_cyberpunk_recently_analyzed())
				highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3))
		if("repair")
			highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3))

	return max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_structure_time_multiplier(atom/target, action = "work")
	return 1 / get_cyberpunk_structure_work_speed_modifier(target, action)

/mob/living/proc/get_cyberpunk_structure_integrity_bonus(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return 0
	return get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 1)

/mob/living/proc/get_cyberpunk_structure_reinforcement_bonus(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return 0
	return get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 3)

/mob/living/proc/get_cyberpunk_structure_repair_bonus(atom/target)
	if(!target?.is_cyberpunk_repair_target())
		return 0
	var/highest_bonus = get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5)
	if(istype(target, /obj/machinery))
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3), get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5))
	return round(highest_bonus * 0.5)

/mob/living/proc/get_cyberpunk_machine_service_amount(atom/target, base_amount = 10)
	if(!istype(target, /obj/machinery))
		return base_amount
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
	)
	if(target?.is_cyberpunk_recently_analyzed())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2))
	return base_amount * (1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_machine_module_time_multiplier(atom/target)
	if(!istype(target, /obj/machinery))
		return 1
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
	)
	if(target?.is_cyberpunk_recently_analyzed())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2))
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_machine_diagnostic_depth(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return 0
	return max(
		get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_HACKING, 6),
	)

/mob/living/proc/can_cyberpunk_analyze_by_examine(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return FALSE
	return get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2) > 0 || get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3) > 0

/mob/living/proc/get_cyberpunk_machine_failure_mask_chance(atom/target)
	if(!istype(target, /obj/machinery))
		return 0
	return get_cyberpunk_skill_perk_bonus(SKILL_HACKING, 5)

/mob/living/proc/get_cyberpunk_machine_shock_multiplier(atom/target)
	if(!istype(target, /obj/machinery))
		return 1
	var/electric_safety = get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 3)
	if(electric_safety <= 0)
		return 1
	return clamp(electric_safety * 0.01, 0, 1)

/mob/living/proc/get_cyberpunk_mobile_structure_pull_force(atom/target, base_force)
	if(!target || target.get_cyberpunk_structure_category() != "mobile_structure")
		return base_force
	var/athletics_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 2, "value_2"),
		get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 3),
	)
	if(athletics_bonus <= 0)
		return base_force
	return base_force * (1 + athletics_bonus * 0.01)

/mob/living/proc/get_cyberpunk_structure_damage_bonus(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return 0
	return get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 2)

/mob/living/proc/get_cyberpunk_structure_salvage_bonus(atom/target)
	if(!target?.is_cyberpunk_structure_target())
		return 0
	var/analysis_bonus = target.is_cyberpunk_recently_analyzed() ? get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3) : 0
	return max(analysis_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 5))

/mob/living/proc/get_cyberpunk_structure_salvage_amount(atom/target, base_amount)
	if(base_amount <= 0)
		return base_amount
	var/bonus = get_cyberpunk_structure_salvage_bonus(target)
	if(bonus <= 0)
		return base_amount
	var/scaled_amount = base_amount * (1 + bonus * 0.01)
	var/whole_amount = FLOOR(scaled_amount, 1)
	if(prob((scaled_amount - whole_amount) * 100))
		whole_amount++
	return max(base_amount, whole_amount)

/mob/living/proc/get_cyberpunk_driving_fuel_multiplier()
	return max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_DRIVING, 1) * 0.01)

/mob/living/proc/get_cyberpunk_driving_speed_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_DRIVING, 2) * 0.01)

/mob/living/proc/get_cyberpunk_driving_reaction_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_DRIVING, 3) * 0.01)

/mob/living/proc/get_cyberpunk_driving_maneuver_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_DRIVING, 4) * 0.01)

/mob/living/proc/get_cyberpunk_driving_brake_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_DRIVING, 5) * 0.01)

/mob/living/proc/get_cyberpunk_vehicle_repair_time_multiplier(atom/target)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
	)
	if(target?.is_cyberpunk_recently_analyzed())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3))
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_vehicle_repair_amount(atom/target, base_amount = 15)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
	)
	return base_amount * (1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_machine_diagnostic_data(atom/target)
	if(!target)
		return list()
	return target.get_cyberpunk_diagnostic_data(src)

/mob/living/proc/get_cyberpunk_medical_scan_time_multiplier(atom/target, base_time = 10 SECONDS)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2),
	)
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_medical_scan_depth(atom/target, base_depth = 0)
	var/analysis_depth = 0
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2) > 0)
		analysis_depth = max(analysis_depth, 1)
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3) > 0)
		analysis_depth = max(analysis_depth, 2)
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 4) > 0)
		analysis_depth = max(analysis_depth, 3)
	return max(base_depth, analysis_depth)

/mob/living/proc/get_cyberpunk_surgery_time_multiplier()
	var/speed_bonus = get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 3)
	return 1 / max(0.1, 1 + speed_bonus * 0.01)

/mob/living/proc/get_cyberpunk_surgery_failure_reduction(datum/surgery_operation/operation)
	var/tier = 1
	if(operation)
		if(operation.time >= 10 SECONDS || (operation.operation_flags & OPERATION_LOCKED))
			tier = 3
		else if(operation.time >= 4 SECONDS || (operation.operation_flags & OPERATION_NOTABLE))
			tier = 2
	switch(tier)
		if(1)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_1")
		if(2)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_2")
		if(3)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_3")
	return 0

/mob/living/proc/get_cyberpunk_surgery_sterility_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 4)

/mob/living/proc/get_cyberpunk_self_surgery_success_chance(datum/surgery_operation/operation)
	var/tier = 1
	if(operation)
		if(operation.time >= 10 SECONDS || (operation.operation_flags & OPERATION_LOCKED))
			tier = 3
		else if(operation.time >= 4 SECONDS || (operation.operation_flags & OPERATION_NOTABLE))
			tier = 2
	switch(tier)
		if(1)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 5, "value_1")
		if(2)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 5, "value_2")
		if(3)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 5, "value_3")
	return 0

/mob/living/proc/get_cyberpunk_chemistry_ph_drift_multiplier()
	return max(0, 1 - get_cyberpunk_skill_perk_bonus(SKILL_CHEMISTRY, 1) * 0.01)

/mob/living/proc/get_cyberpunk_chemistry_overheat_bonus()
	return get_cyberpunk_skill_perk_bonus(SKILL_CHEMISTRY, 2)

/mob/living/proc/get_cyberpunk_chemistry_speed_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_CHEMISTRY, 3) * 0.01)

/mob/living/proc/get_cyberpunk_chemistry_yield_multiplier()
	return max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_CHEMISTRY, 4) * 0.01)

/mob/living/proc/get_cyberpunk_chemistry_purity_range_bonus()
	return get_cyberpunk_skill_perk_bonus(SKILL_CHEMISTRY, 5)

/mob/living/proc/get_cyberpunk_mining_time_multiplier()
	return 1 / max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_MINING, 1) * 0.01)

/mob/living/proc/get_cyberpunk_mining_ore_amount(base_amount, drill = FALSE)
	if(base_amount <= 0)
		return base_amount
	var/amount = base_amount
	var/resource_bonus = drill ? get_cyberpunk_skill_perk_bonus(SKILL_MINING, 2) : 0
	if(resource_bonus > 0)
		var/scaled_amount = base_amount * (1 + resource_bonus * 0.01)
		amount = FLOOR(scaled_amount, 1)
		if(prob((scaled_amount - amount) * 100))
			amount++
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_MINING, 5)))
		amount++
	return max(base_amount, amount)

/mob/living/proc/get_cyberpunk_mining_hidden_resource_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_MINING, 3)

/mob/living/proc/get_cyberpunk_cooking_manual_time_multiplier()
	return 1 / max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 1, "value_1") * 0.01)

/mob/living/proc/get_cyberpunk_cooking_machine_time_multiplier()
	return 1 / max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 1, "value_2") * 0.01)

/mob/living/proc/get_cyberpunk_cooking_spoil_reduction()
	return get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 3)

/mob/living/proc/get_cyberpunk_cooking_quality_bonus()
	return round(get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 4, "value_2"))

/mob/living/proc/get_cyberpunk_cooking_resource_save_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 4, "value_1")

/mob/living/proc/get_cyberpunk_cooking_smell_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 5, "value_1")

/mob/living/proc/get_cyberpunk_cooking_smell_mood_bonus()
	return get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 5, "value_2")

/mob/living/proc/get_cyberpunk_cooking_compatibility_bonus(obj/item/food/food)
	if(!food?.foodtypes)
		return 0
	var/compatibility = calculate_food_compat_bonus(food.foodtypes)
	if(compatibility > 0)
		var/compatibility_cap = round(get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 2, "value_1") * 0.25)
		return min(compatibility, max(2, compatibility_cap))
	if(compatibility < 0)
		var/spoil_chance = max(0, get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 2, "value_2") - get_cyberpunk_cooking_spoil_reduction())
		if(prob(spoil_chance))
			return compatibility
	return 0

/mob/living/proc/get_cyberpunk_gardening_growth_multiplier()
	return max(1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_GARDENING, 2) * 0.01)

/mob/living/proc/get_cyberpunk_gardening_care_multiplier()
	return max(1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_GARDENING, 3) * 0.01)

/mob/living/proc/get_cyberpunk_gardening_extra_harvest_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_GARDENING, 4)

/mob/living/proc/get_cyberpunk_gardening_safe_mutation_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_GARDENING, 5)

/mob/living/proc/get_cyberpunk_gardening_plant_ruin_chance()
	return max(0, 20 - get_cyberpunk_skill_perk_bonus(SKILL_GARDENING, 1))

/mob/living/proc/get_cyberpunk_stamina_cost_multiplier(source)
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 1)
	var/spirit_reduction = max(0, get_attribute_value(ATTRIBUTE_SPIRIT) - ATTRIBUTE_DEFAULT) * 2
	return max(0.1, 1 + (reduction - spirit_reduction) * 0.01)

/mob/living/proc/get_cyberpunk_incoming_damage_multiplier(damagetype)
	if(damagetype == STAMINA)
		return 1
	var/reduction = abs(get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 1))
	reduction += get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 6, "value_1")
	reduction += max(0, get_attribute_value(ATTRIBUTE_STRENGTH) - ATTRIBUTE_DEFAULT)
	return max(0.1, 1 - reduction * 0.01)

/obj/item/proc/get_cyberpunk_weapon_skill()
	if(istype(src, /obj/item/gun))
		if(w_class >= WEIGHT_CLASS_BULKY)
			return SKILL_HEAVY_RANGED
		if(w_class <= WEIGHT_CLASS_SMALL)
			return SKILL_LIGHT_RANGED
		return SKILL_MEDIUM_RANGED
	var/item_sharpness = get_sharpness()
	if(item_sharpness & SHARP_POINTY)
		return w_class >= WEIGHT_CLASS_BULKY ? SKILL_HEAVY_PIERCING : SKILL_LIGHT_PIERCING
	if(item_sharpness & SHARP_EDGED)
		return w_class >= WEIGHT_CLASS_BULKY ? SKILL_HEAVY_SLASHING : SKILL_LIGHT_SLASHING
	return w_class >= WEIGHT_CLASS_BULKY ? SKILL_HEAVY_BLUNT : SKILL_LIGHT_BLUNT

/mob/living/proc/get_cyberpunk_weapon_damage_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	var/multiplier = 1
	var/weapon_skill = weapon.get_cyberpunk_weapon_skill()
	if(weapon_skill)
		multiplier *= mind.get_weapon_skill_damage_multiplier(weapon_skill)
	multiplier *= 1 + (max(get_attribute_value(ATTRIBUTE_STRENGTH), get_attribute_value(ATTRIBUTE_DEXTERITY), get_attribute_value(ATTRIBUTE_PERCEPTION)) - ATTRIBUTE_DEFAULT) * 0.01
	var/heavy_bonus = weapon.w_class >= WEIGHT_CLASS_BULKY ? get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 2) : 0
	var/precise_bonus = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 2)
	return multiplier * (1 + max(heavy_bonus, precise_bonus) * 0.01)

/mob/living/proc/get_cyberpunk_weapon_cooldown_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	var/multiplier = 1
	var/weapon_skill = weapon.get_cyberpunk_weapon_skill()
	if(weapon_skill)
		multiplier *= mind.get_weapon_skill_cooldown_multiplier(weapon_skill)
	if(weapon.w_class >= WEIGHT_CLASS_BULKY)
		multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 4, "value_2") * 0.01)
	else
		multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 2) * 0.01)
	return max(0.1, multiplier)

/mob/living/proc/get_cyberpunk_unarmed_damage_multiplier()
	var/power_bonus = get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 1)
	var/precision_bonus = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 1)
	var/attribute_bonus = max(0, get_attribute_value(ATTRIBUTE_STRENGTH) - ATTRIBUTE_DEFAULT) * 2
	return 1 + (max(power_bonus, precision_bonus) + attribute_bonus) * 0.01

/mob/living/proc/apply_cyberpunk_unarmed_zone_effect(mob/living/target, zone)
	if(!target || get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4) <= 0)
		return FALSE
	switch(zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			if(prob(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_1")))
				target.Knockdown(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_2") * 1 SECONDS)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			target.dropItemToGround(target.get_active_held_item())
			target.Stun(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_3") * 1 SECONDS)
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES)
			target.set_confusion_if_lower(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_4") * 1 SECONDS)
	return TRUE

/mob/living/proc/get_cyberpunk_grapple_control_bonus()
	return max(
		get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 5),
	)

/mob/living/proc/can_cyberpunk_grapple_action(mob/living/target, action, zone = null)
	if(!target || pulling != target || grab_state < GRAB_AGGRESSIVE)
		return FALSE
	switch(action)
		if("furniture_throw", "limb_slam")
			return get_character_perk_rank(SKILL_GRAPPLING, 2) > 0
		if("wrestling_launch")
			return get_character_perk_rank(SKILL_GRAPPLING, 3) > 0
		if("special_limb")
			return get_character_perk_rank(SKILL_GRAPPLING, 4) > 0
		if("neck_throw", "choke")
			return zone == BODY_ZONE_PRECISE_NECK && grab_state >= GRAB_NECK && get_character_perk_rank(SKILL_GRAPPLING, 5) > 0
		if("neck_back_slam", "spine_knee")
			return zone == BODY_ZONE_PRECISE_NECK && grab_state >= GRAB_NECK && get_character_perk_rank(SKILL_GRAPPLING, 6) > 0
	return FALSE

/mob/living/proc/perform_cyberpunk_grapple_furniture_throw(mob/living/target, obj/structure/furniture)
	if(!istype(furniture) || !can_cyberpunk_grapple_action(target, "furniture_throw"))
		return FALSE
	if(!istype(furniture, /obj/structure/table) && !istype(furniture, /obj/structure/chair) && !istype(furniture, /obj/structure/bed))
		return FALSE
	var/turf/destination = get_turf(furniture)
	if(!destination)
		return FALSE
	target.throw_at(destination, max(1, get_dist(target, destination)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG, callback = CALLBACK(src, PROC_REF(finish_cyberpunk_grapple_furniture_throw), target, furniture))
	target.apply_damage(20, STAMINA)
	stop_pulling()
	log_combat(src, target, "grapple threw", null, "onto [furniture]")
	return TRUE

/mob/living/proc/finish_cyberpunk_grapple_furniture_throw(mob/living/target, obj/structure/furniture)
	if(QDELETED(target) || QDELETED(furniture))
		return FALSE
	var/turf/furniture_turf = get_turf(furniture)
	if(!furniture_turf)
		return FALSE
	target.forceMove(furniture_turf)
	target.Knockdown(2 SECONDS)
	target.apply_damage(12, BRUTE)
	if(istype(furniture, /obj/structure/chair) || istype(furniture, /obj/structure/bed))
		furniture.buckle_mob(target, force = TRUE, check_loc = FALSE)
	else if(istype(furniture, /obj/structure/table))
		target.set_resting(TRUE, TRUE)
	return TRUE

/mob/living/proc/perform_cyberpunk_wrestling_launch(mob/living/target, turf/destination)
	if(!istype(destination) || !can_cyberpunk_grapple_action(target, "wrestling_launch"))
		return FALSE
	target.throw_at(destination, max(1, get_dist(target, destination)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG)
	target.Knockdown(2 SECONDS)
	target.apply_damage(30, STAMINA)
	if(prob(35))
		Knockdown(1 SECONDS)
	stop_pulling()
	log_combat(src, target, "wrestling launched")
	return TRUE

/mob/living/proc/perform_cyberpunk_neck_throw(mob/living/target, atom/destination)
	if(!destination || !can_cyberpunk_grapple_action(target, "neck_throw", BODY_ZONE_PRECISE_NECK))
		return FALSE
	target.throw_at(destination, max(1, get_dist(target, destination)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG)
	target.Knockdown(2 SECONDS)
	target.apply_damage(20, STAMINA)
	stop_pulling()
	log_combat(src, target, "neck threw")
	return TRUE

/mob/living/proc/apply_cyberpunk_grapple_limb_impact_effect(mob/living/target, zone)
	if(!can_cyberpunk_grapple_action(target, "limb_slam", zone))
		return FALSE
	var/control_bonus = get_cyberpunk_grapple_control_bonus()
	target.apply_damage(round(10 * (1 + control_bonus * 0.01)), STAMINA)
	switch(zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			target.Knockdown(2 SECONDS)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			var/obj/item/held_item = target.get_active_held_item() || target.get_inactive_held_item()
			if(held_item)
				target.dropItemToGround(held_item)
		if(BODY_ZONE_PRECISE_EYES)
			target.adjust_temp_blindness(2 SECONDS)
			target.adjust_eye_blur(4 SECONDS)
		if(BODY_ZONE_PRECISE_EARS)
			target.sound_damage(0, 4 SECONDS)
		if(BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_NECK, BODY_ZONE_HEAD)
			target.apply_damage(10, STAMINA)
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_special(mob/living/target, zone)
	if(!can_cyberpunk_grapple_action(target, "special_limb", zone))
		return FALSE
	apply_cyberpunk_grapple_limb_impact_effect(target, zone)
	if(zone == BODY_ZONE_CHEST)
		target.Knockdown(1 SECONDS)
		target.apply_damage(20, STAMINA)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] twists [target.declent_ru(ACCUSATIVE)] in a painful hold!"), span_danger("You twist [target.declent_ru(ACCUSATIVE)] in a painful hold!"), null, COMBAT_MESSAGE_RANGE, target)
	log_combat(src, target, "used grapple special", null, "zone [zone]")
	return TRUE

/mob/living/proc/perform_cyberpunk_neck_choke(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "choke", BODY_ZONE_PRECISE_NECK))
		return FALSE
	target.apply_damage(12, OXY)
	target.apply_damage(35, STAMINA)
	log_combat(src, target, "choked")
	return TRUE

/mob/living/proc/perform_cyberpunk_spine_knee(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "spine_knee", BODY_ZONE_PRECISE_NECK))
		return FALSE
	target.Stun(2 SECONDS)
	target.apply_damage(25, STAMINA)
	if(prob(65))
		stop_pulling()
		Knockdown(1 SECONDS)
	log_combat(src, target, "kneed spine")
	return TRUE

/mob/living/proc/perform_cyberpunk_neck_back_slam(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "neck_back_slam", BODY_ZONE_PRECISE_NECK))
		return FALSE
	var/turf/behind = get_step(src, REVERSE_DIR(dir)) || get_turf(src)
	target.forceMove(behind)
	setDir(REVERSE_DIR(dir))
	target.Knockdown(3 SECONDS)
	Knockdown(2 SECONDS)
	target.apply_damage(15, BRUTE)
	target.apply_damage(35, STAMINA)
	stop_pulling()
	log_combat(src, target, "neck back slammed")
	return TRUE

/mob/living/proc/apply_cyberpunk_machine_wear(obj/machinery/machine, amount = 1, source = null)
	if(!machine || amount <= 0)
		return FALSE
	return machine.apply_cyberpunk_machine_wear(amount, source, src)
