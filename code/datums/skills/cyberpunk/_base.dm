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

/mob/living/proc/apply_cyberpunk_machine_wear(obj/machinery/machine, amount = 1, source = null)
	if(!machine || amount <= 0)
		return FALSE
	return machine.apply_cyberpunk_machine_wear(amount, source, src)
