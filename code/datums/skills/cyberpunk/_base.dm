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

/mob/living/proc/get_cyberpunk_crafting_time_multiplier(datum/crafting_recipe/recipe)
	if(!recipe || !mind)
		return 1
	var/highest_bonus = 0
	if(ispath(recipe.result, /obj/machinery))
		highest_bonus = max(
			highest_bonus,
			get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
			get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
			get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
		)
	else if(ispath(recipe.result, /obj/structure) || ispath(recipe.result, /turf))
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5))
	else if(ispath(recipe.result, /obj/item/food) || istype(recipe, /datum/crafting_recipe/food))
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_COOKING, 1, "value_2"))
	else if(ispath(recipe.result, /obj/item))
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 1))
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/reward_cyberpunk_crafting_experience(datum/crafting_recipe/recipe)
	if(!recipe || !mind)
		return
	if(ispath(recipe.result, /obj/machinery))
		reward_character_check_experience(SKILL_ELECTRICS, 4, FALSE, 1)
		reward_character_check_experience(SKILL_INVENTION, 3, FALSE, 1)
	else if(ispath(recipe.result, /obj/structure) || ispath(recipe.result, /turf))
		reward_character_check_experience(SKILL_CONSTRUCTION, 4, FALSE, 1)
	else if(ispath(recipe.result, /obj/item/food) || istype(recipe, /datum/crafting_recipe/food))
		reward_character_check_experience(SKILL_COOKING, 4, FALSE, 1)
	else if(ispath(recipe.result, /obj/item))
		reward_character_check_experience(SKILL_INVENTION, 3, FALSE, 1)

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
	if(!target?.is_cyberpunk_analysis_target())
		return FALSE
	return get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2) > 0 || get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3) > 0

/mob/living/proc/get_cyberpunk_item_analysis_depth(obj/item/target)
	if(!istype(target))
		return 0
	var/depth = 0
	if(target.is_cyberpunk_recently_analyzed())
		depth = max(depth, 1)
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2) > 0)
		depth = max(depth, 1)
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3) > 0)
		depth = max(depth, 2)
	if(get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 4) > 0)
		depth = max(depth, 3)
	return depth

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
	return analysis_bonus

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

/mob/living/proc/get_cyberpunk_item_module_time_multiplier(obj/item/target)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
	)
	if(target?.is_cyberpunk_recently_analyzed())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3))
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_item_repair_time_multiplier(obj/item/target)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
	)
	if(target?.is_cyberpunk_recently_analyzed())
		highest_bonus = max(highest_bonus, get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 3))
	return 1 / max(0.1, 1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_item_repair_amount(obj/item/target, base_amount = 20)
	var/highest_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 3),
		get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 5),
		get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 5),
	)
	return base_amount * (1 + highest_bonus * 0.01)

/mob/living/proc/get_cyberpunk_machine_diagnostic_data(atom/target)
	if(!target)
		return list()
	return target.get_cyberpunk_diagnostic_data(src)

/mob/living/proc/get_cyberpunk_analysis_time_multiplier()
	return 1 / max(0.1, 1 + get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 1) * 0.01)

/proc/get_cyberpunk_science_techweb()
	return locate(/datum/techweb/science) in SSresearch.techwebs

/mob/living/proc/try_cyberpunk_analysis_research_reward(atom/target, chance, require_new_type = FALSE)
	if(!target || !mind || chance <= 0)
		return FALSE
	if(require_new_type)
		if(mind.cyberpunk_analyzed_typepaths[target.type])
			return FALSE
		mind.cyberpunk_analyzed_typepaths[target.type] = TRUE
	if(!prob(chance))
		return FALSE
	var/datum/techweb/science/science_web = get_cyberpunk_science_techweb()
	if(!science_web)
		return FALSE
	var/list/matching_designs = list()
	var/list/locked_designs = list()
	for(var/design_id in SSresearch.techweb_designs)
		if(science_web.researched_designs[design_id])
			continue
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		if(!design?.build_path)
			continue
		locked_designs += design_id
		if(design.build_path == target.type)
			matching_designs += design_id
	if(length(matching_designs))
		var/design_id = pick(matching_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		if(science_web.add_design_by_id(design_id, TRUE))
			to_chat(src, span_notice("Your analysis reconstructs the design pattern for [design.name]."))
			reward_character_check_experience(SKILL_ANALYSIS, 5, FALSE, 2)
			return TRUE
	var/list/available_nodes = list()
	for(var/node_id in science_web.available_nodes)
		if(!science_web.researched_nodes[node_id])
			available_nodes += node_id
	if(length(available_nodes))
		var/node_id = pick(available_nodes)
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
		if(science_web.research_node_id(node_id, TRUE, FALSE, FALSE, target))
			to_chat(src, span_notice("Your analysis unlocks a useful technology pattern: [node.display_name]."))
			reward_character_check_experience(SKILL_ANALYSIS, 5, FALSE, 2)
			return TRUE
	if(length(locked_designs))
		var/design_id = pick(locked_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		if(science_web.add_design_by_id(design_id, TRUE))
			to_chat(src, span_notice("Your analysis reconstructs the design pattern for [design.name]."))
			reward_character_check_experience(SKILL_ANALYSIS, 5, FALSE, 2)
			return TRUE
	return FALSE

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
	var/tier = operation?.get_cyberpunk_step_severity() || SURGERY_STEP_SEVERITY_BASIC
	switch(tier)
		if(SURGERY_STEP_SEVERITY_BASIC)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_1")
		if(SURGERY_STEP_SEVERITY_ADVANCED)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_2")
		if(SURGERY_STEP_SEVERITY_RARE)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 2, "value_3")
	return 0

/mob/living/proc/get_cyberpunk_surgery_sterility_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 4)

/mob/living/proc/get_cyberpunk_self_surgery_success_chance(datum/surgery_operation/operation)
	var/tier = operation?.get_cyberpunk_step_severity() || SURGERY_STEP_SEVERITY_BASIC
	switch(tier)
		if(SURGERY_STEP_SEVERITY_BASIC)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 5, "value_1")
		if(SURGERY_STEP_SEVERITY_ADVANCED)
			return get_cyberpunk_skill_perk_bonus(SKILL_SURGERY, 5, "value_2")
		if(SURGERY_STEP_SEVERITY_RARE)
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

/mob/living/proc/get_cyberpunk_mining_resource_quality()
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_MINING, 4, "value_3")))
		return 5
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_MINING, 4, "value_2")))
		return 4
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_MINING, 4, "value_1")))
		return 3
	return 0

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
	if(has_character_giga_perk(ATTRIBUTE_SPIRIT) && prob(get_character_skill_level(SKILL_ATHLETICS) * 15))
		return 0
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

/mob/living/proc/get_cyberpunk_knockdown_duration_multiplier()
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 3)
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/roll_cyberpunk_fortitude_knockdown_resist()
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 6, "value_2")
	if(has_character_giga_perk(ATTRIBUTE_STRENGTH))
		chance = max(chance, get_character_skill_level(SKILL_FORTITUDE) * 15)
	return chance > 0 && prob(chance)

/mob/living/proc/get_cyberpunk_fortitude_organ_health_multiplier()
	return 1 + get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 2) * 0.01

/mob/living/proc/apply_cyberpunk_fortitude_starting_organs()
	return

/mob/living/carbon/apply_cyberpunk_fortitude_starting_organs()
	if(!mind)
		return
	var/multiplier = get_cyberpunk_fortitude_organ_health_multiplier()
	if(multiplier <= 1)
		return
	for(var/obj/item/organ/organ as anything in organs)
		if(!HAS_TRAIT(organ, TRAIT_CLIENT_STARTING_ORGAN))
			continue
		if(organ.cyberpunk_fortitude_starting_health_applied)
			continue
		organ.maxHealth = round(organ.maxHealth * multiplier)
		organ.high_threshold = round(organ.high_threshold * multiplier)
		organ.low_threshold = round(organ.low_threshold * multiplier)
		organ.cyberpunk_fortitude_starting_health_applied = TRUE

/mob/living/proc/get_cyberpunk_fortitude_wound_threshold_multiplier()
	return 1 + get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 4) * 0.01

/mob/living/proc/get_cyberpunk_fortitude_incoming_grab_durability_multiplier()
	return max(0, 1 - get_cyberpunk_skill_perk_bonus(SKILL_FORTITUDE, 5) * 0.01)

/obj/item/proc/get_cyberpunk_weapon_skill()
	if(cyberpunk_weapon_skill)
		return cyberpunk_weapon_skill
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

/obj/item/proc/is_cyberpunk_heavy_weapon()
	var/weapon_skill = get_cyberpunk_weapon_skill()
	return (weapon_skill in list(SKILL_HEAVY_RANGED, SKILL_HEAVY_SLASHING, SKILL_HEAVY_BLUNT, SKILL_HEAVY_PIERCING, SKILL_CHOPPING))

/obj/item/proc/is_cyberpunk_combat_weapon()
	return force > 0 || istype(src, /obj/item/gun)

/mob/living/proc/get_cyberpunk_heavy_weapon_move_bonus()
	if(!mind || !combat_mode)
		return 0
	var/bonus = get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 1)
	if(bonus <= 0)
		return 0
	for(var/obj/item/held_item as anything in held_items)
		if(!held_item || !held_item.is_cyberpunk_combat_weapon())
			continue
		return bonus * 0.01
	return 0

/mob/living/proc/get_cyberpunk_heavy_weapon_equipment_damage(obj/item/weapon)
	if(!weapon || !mind || !weapon.is_cyberpunk_heavy_weapon())
		return 0
	var/bonus = get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 3)
	if(bonus <= 0)
		return 0
	return max(0, get_attribute_value(ATTRIBUTE_STRENGTH)) * bonus * 0.01

/mob/living/proc/roll_cyberpunk_heavy_weapon_wound(obj/item/weapon)
	if(!weapon || !mind)
		return FALSE
	if(has_character_giga_perk(ATTRIBUTE_STRENGTH) && weapon.is_cyberpunk_combat_weapon())
		return prob(max(5, get_character_skill_level(SKILL_HEAVY_WEAPON) * 15))
	if(!weapon.is_cyberpunk_heavy_weapon())
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 5)
	return chance > 0 && prob(chance)

/mob/living/proc/get_cyberpunk_wounding_type_from_hit(damagetype, sharpness, armor_flag, brute_type = null, burn_type = null)
	if(damagetype == BURN)
		return WOUND_BURN
	if(brute_type == BODYPART_DAMAGE_SLASH || (sharpness & SHARP_EDGED))
		return WOUND_SLASH
	if(brute_type == BODYPART_DAMAGE_PIERCE || (sharpness & SHARP_POINTY) || armor_flag == BULLET)
		return WOUND_PIERCE
	return WOUND_BLUNT

/mob/living/proc/apply_cyberpunk_heavy_weapon_armor_effects(mob/living/attacker, obj/item/weapon, def_zone, armor_flag, armour_penetration, damagetype, sharpness = NONE, brute_type = null, burn_type = null)
	return

/mob/living/carbon/human/apply_cyberpunk_heavy_weapon_armor_effects(mob/living/attacker, obj/item/weapon, def_zone, armor_flag, armour_penetration, damagetype, sharpness = NONE, brute_type = null, burn_type = null)
	if(!attacker || attacker == src || !weapon)
		return
	var/obj/item/bodypart/hit_part = get_bodypart(check_hit_limb_zone_name(def_zone))
	if(!hit_part)
		return
	var/equipment_damage = attacker.get_cyberpunk_heavy_weapon_equipment_damage(weapon)
	var/can_force_wound = attacker.roll_cyberpunk_heavy_weapon_wound(weapon)
	if(equipment_damage <= 0 && !can_force_wound)
		return
	if(equipment_damage > 0)
		var/guard_bonus = consume_cyberpunk_inspiration_guard("equipment protection")
		if(guard_bonus > 0)
			equipment_damage *= max(0, 1 - guard_bonus * 0.01)
	var/pierced_armor = FALSE
	for(var/obj/item/clothing/clothes as anything in get_clothing_on_part(hit_part))
		if(!clothes || clothes.get_integrity() <= 0)
			continue
		var/armor_rating = clothes.get_armor_rating(armor_flag)
		if(armor_rating <= 0)
			continue
		if(equipment_damage > 0)
			clothes.take_damage_zone(hit_part.body_zone, equipment_damage, damagetype == BURN ? BURN : BRUTE, 0)
		if(armour_penetration > armor_rating)
			pierced_armor = TRUE
	if(!pierced_armor || !can_force_wound)
		if(can_force_wound && attacker.has_character_giga_perk(ATTRIBUTE_STRENGTH))
			cause_wound_of_type_and_severity(WOUND_BLUNT, hit_part, WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_SEVERE, wound_source = weapon)
		return
	var/wounding_type = attacker.get_cyberpunk_wounding_type_from_hit(damagetype, sharpness, armor_flag, brute_type, burn_type)
	cause_wound_of_type_and_severity(wounding_type, hit_part, WOUND_SEVERITY_MODERATE, wound_source = weapon)

/mob/living/proc/get_cyberpunk_weapon_damage_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	if(weapon.cyberpunk_broken)
		return 0
	var/multiplier = 1
	var/weapon_skill = weapon.get_cyberpunk_weapon_skill()
	if(weapon_skill)
		multiplier *= mind.get_weapon_skill_damage_multiplier(weapon_skill)
	multiplier *= 1 + (max(get_attribute_value(ATTRIBUTE_STRENGTH), get_attribute_value(ATTRIBUTE_DEXTERITY), get_attribute_value(ATTRIBUTE_PERCEPTION)) - ATTRIBUTE_DEFAULT) * 0.01
	var/heavy_bonus = weapon.w_class >= WEIGHT_CLASS_BULKY ? get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 2) : 0
	var/precise_bonus = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 2)
	var/corporate_multiplier = weapon.get_cyberpunk_synergy_multiplier(src)
	return multiplier * (1 + max(heavy_bonus, precise_bonus) * 0.01) * corporate_multiplier

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
	var/corporate_multiplier = weapon.get_cyberpunk_synergy_multiplier(src)
	if(corporate_multiplier > 1)
		multiplier /= corporate_multiplier
	var/ho_shi = weapon.get_cyberpunk_base_effect_strength(src, "ho_shi")
	if(ho_shi > 0 && !istype(weapon, /obj/item/gun))
		multiplier *= max(0.1, 1 - 0.1 * ho_shi)
	return max(0.1, multiplier)

/mob/living/proc/get_cyberpunk_gun_fire_delay_multiplier(obj/item/gun/gun)
	if(!gun)
		return 1
	var/multiplier = get_cyberpunk_weapon_cooldown_multiplier(gun)
	if(gun.w_class >= WEIGHT_CLASS_BULKY)
		multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 6, "value_1") * 0.01)
	else
		multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 4, "value_1") * 0.01)
	var/ho_shi = gun.get_cyberpunk_base_effect_strength(src, "ho_shi")
	if(ho_shi > 0)
		multiplier *= max(0.1, 1 - 0.1 * ho_shi)
	return max(0.1, multiplier)

/mob/living/proc/get_cyberpunk_gun_spread_multiplier(obj/item/gun/gun)
	if(!gun)
		return 1
	var/reduction = 0
	if(gun.w_class >= WEIGHT_CLASS_BULKY)
		reduction = max(get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 4, "value_1"), get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 6, "value_1"))
	var/sun_yon = gun.get_cyberpunk_base_effect_strength(src, "sun_yon")
	if(sun_yon > 0)
		reduction = max(reduction, 10 * sun_yon)
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/roll_cyberpunk_weapon_free_repeat(obj/item/weapon)
	if(!weapon || !mind)
		return FALSE
	if(has_character_giga_perk(ATTRIBUTE_DEXTERITY) && weapon.is_cyberpunk_combat_weapon())
		return prob(get_character_skill_level(SKILL_LIGHT_WEAPON) * 15)
	if(get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 3) <= 0)
		return FALSE
	if(weapon.w_class > WEIGHT_CLASS_NORMAL)
		return FALSE
	return prob(get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 3))

/mob/proc/try_cyberpunk_light_weapon_do_after_interrupt_resist(atom/target, atom/original_loc)
	return FALSE

/mob/living/try_cyberpunk_light_weapon_do_after_interrupt_resist(atom/target, atom/original_loc)
	if(!mind || loc != original_loc)
		return FALSE
	if(target && target != src && !Adjacent(target))
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 6)
	return chance > 0 && prob(chance)

/mob/proc/get_cyberpunk_do_after_action_cooldown_multiplier()
	return 1

/mob/living/get_cyberpunk_do_after_action_cooldown_multiplier()
	if(!do_after_count())
		return 1
	if(get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 6) <= 0)
		return 1
	return 0.5

/mob/living/proc/get_cyberpunk_reload_time_multiplier(obj/item/gun/gun)
	if(!gun || !mind)
		return 1
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 1)
	if(gun.w_class >= WEIGHT_CLASS_BULKY)
		reduction = max(reduction, get_cyberpunk_skill_perk_bonus(SKILL_HEAVY_WEAPON, 4, "value_2"))
	return max(0.25, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_rack_delay_multiplier(obj/item/gun/gun)
	if(!gun || !mind)
		return 1
	var/reduction = max(
		get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 1),
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 3, "value_2"),
	)
	return max(0.25, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_draw_time_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 5, "value_1")
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_gunpoint_time_multiplier(obj/item/gun/gun)
	if(!gun || !mind)
		return 1
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 3, "value_2")
	return max(0.25, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_gunpoint_range(obj/item/gun/gun)
	if(!gun || !mind)
		return GUNPOINT_SHOOTER_STRAY_RANGE
	return GUNPOINT_SHOOTER_STRAY_RANGE + round(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 1))

/mob/living/proc/get_cyberpunk_gunpoint_damage_multiplier(obj/item/gun/gun)
	if(!gun || !mind)
		return 1
	var/damage_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 2),
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 4),
	)
	return 1 + damage_bonus * 0.01

/mob/living/proc/can_cyberpunk_move_while_aiming(obj/item/gun/gun)
	return gun && get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 6) > 0

/mob/living/proc/get_cyberpunk_charged_intent_time_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	var/reduction = max(
		get_cyberpunk_skill_perk_bonus(SKILL_LIGHT_WEAPON, 4, "value_2"),
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 3, "value_2"),
	)
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_charged_intent_damage_multiplier(obj/item/weapon)
	if(!weapon || !mind)
		return 1
	var/damage_bonus = max(
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 2),
		get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 4),
	)
	return 1 + damage_bonus * 0.01

/mob/living/proc/get_cyberpunk_charged_intent_followup_bonus(obj/item/weapon)
	if(!weapon || !mind)
		return 0
	return get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 5)

/mob/living/proc/roll_cyberpunk_precise_weapon_disarm(obj/item/weapon)
	if(!weapon || !mind)
		return FALSE
	if(!iscarbon(src))
		return FALSE
	if(weapon.w_class >= WEIGHT_CLASS_BULKY)
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_WEAPON, 6)
	if(chance <= 0)
		return FALSE
	return prob(chance)

/mob/living/proc/try_cyberpunk_giga_perception_blind(mob/living/target, skill_path)
	if(!target || target == src || !has_character_giga_perk(ATTRIBUTE_PERCEPTION))
		return FALSE
	var/blind_chance = (mind?.get_character_skill_level(skill_path) || 0) * 15
	if(blind_chance <= 0 || !prob(blind_chance))
		return FALSE
	target.adjust_temp_blindness_up_to(2 SECONDS, 10 SECONDS)
	to_chat(src, span_notice("Your eagle-eyed strike blinds [target.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/proc/get_cyberpunk_electric_shock_multiplier()
	var/electric_safety = get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 3)
	if(electric_safety <= 0)
		return 1
	return clamp(electric_safety * 0.01, 0.1, 1)

/mob/living/proc/get_cyberpunk_electric_chain_multiplier()
	var/chain_safety = get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 4)
	if(chain_safety <= 0)
		return 1
	return clamp(chain_safety * 0.01, 0.1, 1)

/mob/living/proc/get_cyberpunk_electric_wire_stun_cap()
	var/wire_stun = get_cyberpunk_skill_perk_bonus(SKILL_ELECTRICS, 2)
	if(wire_stun <= 0)
		return 0
	return wire_stun * 1 SECONDS

/mob/living/proc/get_cyberpunk_construction_welding_hazard_chance()
	var/hazard_chance = get_cyberpunk_skill_perk_bonus(SKILL_CONSTRUCTION, 4)
	if(hazard_chance <= 0)
		return 100
	return clamp(hazard_chance, 0, 100)

/mob/living/proc/roll_cyberpunk_construction_welding_hazard(atom/target, obj/item/tool)
	if(!target || !tool || get_eye_protection() >= FLASH_PROTECTION_WELDER)
		return FALSE
	if(!prob(get_cyberpunk_construction_welding_hazard_chance()))
		return FALSE
	if(prob(50))
		flash_act(FLASH_PROTECTION_WELDER, visual = TRUE, length = 2 SECONDS)
		to_chat(src, span_warning("Яркая вспышка сварки бьет по глазам."))
	else
		apply_damage(4, BURN, get_active_hand(), wound_bonus = CANT_WOUND)
		to_chat(src, span_warning("Горячая искра обжигает руку."))
	return TRUE

/mob/living/proc/get_cyberpunk_invention_quality_bonus()
	var/quality_bonus = get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 4)
	if(quality_bonus <= 0)
		return 0
	return round(quality_bonus / 25)

/mob/living/proc/get_cyberpunk_invention_resource_save_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_INVENTION, 5)

/mob/living/proc/apply_cyberpunk_invention_quality_bonus(obj/item/created)
	if(!created)
		return FALSE
	var/quality_bonus = get_cyberpunk_invention_quality_bonus()
	if(quality_bonus <= 0)
		return FALSE
	var/base_quality = created.resource_quality || 3
	created.set_resource_quality(clamp(base_quality + quality_bonus, 1, 5))
	return TRUE

/mob/living/proc/get_cyberpunk_unarmed_damage_multiplier()
	var/power_bonus = get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 1)
	power_bonus += get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 2)
	var/precision_bonus = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 1)
	precision_bonus += get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 2)
	var/attribute_bonus = max(0, get_attribute_value(ATTRIBUTE_STRENGTH) - ATTRIBUTE_DEFAULT) * 2
	return 1 + (max(power_bonus, precision_bonus) + attribute_bonus) * 0.01

/mob/living/proc/apply_cyberpunk_unarmed_zone_effect(mob/living/target, zone)
	if(!target || get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4) <= 0)
		return FALSE
	var/zone_bonus = 0
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 5, "value_1")))
		zone_bonus += get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 5, "value_2")
	zone_bonus += get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 6, "value_1")
	switch(zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			if(prob(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_1") + zone_bonus))
				target.Knockdown(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_2") * 1 SECONDS)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			if(prob(50 + zone_bonus))
				target.dropItemToGround(target.get_active_held_item())
			target.Stun(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_3") * 1 SECONDS)
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES)
			target.set_confusion_if_lower(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 4, "value_4") * 1 SECONDS)
			try_cyberpunk_giga_perception_blind(target, SKILL_PRECISE_UNARMED)
		if(BODY_ZONE_CHEST)
			if(prob(get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 6, "value_2")))
				target.Knockdown(2 SECONDS)
	return TRUE

/mob/living/proc/apply_cyberpunk_precise_unarmed_pain(mob/living/carbon/target, obj/item/bodypart/affecting, damage_done)
	if(!target || !affecting || damage_done <= 0)
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_PRECISE_UNARMED, 3)
	if(chance <= 0)
		return FALSE
	var/list/pain_check = get_character_perk_check_result(SKILL_PRECISE_UNARMED, 3, probability = chance)
	if(!pain_check?["passed"])
		return FALSE
	affecting.add_bodypart_pain(damage_done)
	to_chat(src, span_notice("Your precise strike doubles the pain in [target.declent_ru(GENITIVE)] [parse_zone(affecting.body_zone)]."))
	to_chat(target, span_warning("[capitalize(src.declent_ru(NOMINATIVE))]'s precise strike sends sharp pain through your [parse_zone(affecting.body_zone)]."))
	return TRUE

/mob/living/proc/get_cyberpunk_fast_unarmed_attack_cooldown(charged_intent = null)
	if(has_character_giga_perk(ATTRIBUTE_DEXTERITY) && prob(get_character_skill_level(SKILL_FAST_UNARMED) * 15))
		return 0
	var/cooldown = charged_intent == "kick" ? 1.5 SECONDS : 1.3 SECONDS
	cooldown -= get_character_skill_level(SKILL_FAST_UNARMED) * (0.1 SECONDS)
	var/speed_bonus = get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 1)
	if(charged_intent != "kick")
		speed_bonus += get_attribute_value(ATTRIBUTE_DEXTERITY) * get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 2) * 0.01
	if(speed_bonus > 0)
		cooldown *= max(0.1, 1 - speed_bonus * 0.01)
	return max(0.2 SECONDS, round(cooldown))

/mob/living/proc/can_cyberpunk_kick()
	return world.time >= cyberpunk_next_kick

/mob/living/proc/start_cyberpunk_kick_cooldown()
	cyberpunk_next_kick = world.time + get_cyberpunk_fast_unarmed_attack_cooldown("kick")

/mob/living/proc/try_cyberpunk_fast_unarmed_ignore_kick_attack_cooldown()
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 3)
	if(chance <= 0)
		return FALSE
	var/list/cooldown_check = get_character_perk_check_result(SKILL_FAST_UNARMED, 3, probability = chance)
	if(!cooldown_check?["passed"])
		return FALSE
	to_chat(src, span_notice("Your kick leaves you ready to strike again."))
	return TRUE

/mob/living/proc/try_cyberpunk_fast_unarmed_prepare_free_hand_attack()
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 4)
	if(chance <= 0)
		return FALSE
	var/list/stamina_check = get_character_perk_check_result(SKILL_FAST_UNARMED, 4, probability = chance)
	if(!stamina_check?["passed"])
		return FALSE
	cyberpunk_fast_unarmed_free_hand_attack = TRUE
	to_chat(src, span_notice("Your kick sets up a stamina-free hand strike."))
	return TRUE

/mob/living/proc/consume_cyberpunk_fast_unarmed_free_hand_attack()
	if(!cyberpunk_fast_unarmed_free_hand_attack)
		return FALSE
	cyberpunk_fast_unarmed_free_hand_attack = FALSE
	to_chat(src, span_notice("Your fast unarmed rhythm saves the stamina for this strike."))
	return TRUE

/mob/living/proc/apply_cyberpunk_fast_unarmed_kick_effects(mob/living/target, target_was_staggered)
	if(!target)
		return FALSE
	adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	var/turf/target_start_turf = get_turf(target)
	disarm(target)
	if(target_was_staggered)
		var/knocked_down = target.Knockdown(SHOVE_KNOCKDOWN_HUMAN, daze_amount = 3 SECONDS)
		if(knocked_down)
			to_chat(src, span_notice("Ваш пинок сбивает [target.declent_ru(ACCUSATIVE)] с ног."))
	if(has_character_giga_perk(ATTRIBUTE_DEXTERITY) && prob(get_character_skill_level(SKILL_ACROBATICS) * 15))
		target.Knockdown(SHOVE_KNOCKDOWN_HUMAN, daze_amount = 3 SECONDS)
		to_chat(src, span_notice("Your acrobatic strike drops [target.declent_ru(ACCUSATIVE)]."))
	if(get_attribute_value(ATTRIBUTE_STRENGTH) >= 10 && target != src)
		var/throw_dir = get_dir(src, target) || dir
		if(throw_dir)
			var/throw_distance = max(0, 2 - get_dist(target_start_turf, get_turf(target)))
			if(throw_distance > 0)
				var/turf/throw_target = get_edge_target_turf(target, throw_dir)
				target.safe_throw_at(throw_target, throw_distance, 1, src, gentle = FALSE)
				to_chat(src, span_notice("Сила пинка отбрасывает [target.declent_ru(ACCUSATIVE)]."))
	var/stagger_chance = get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 5)
	if(stagger_chance > 0)
		var/list/stagger_check = get_character_perk_check_result(SKILL_FAST_UNARMED, 5, probability = stagger_chance)
		if(stagger_check?["passed"])
			target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
			to_chat(src, span_notice("Your kick knocks [target.declent_ru(ACCUSATIVE)] off balance."))
	var/stun_chance = get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 6, "value_1")
	if(target_was_staggered && stun_chance > 0)
		var/list/stun_check = get_character_perk_check_result(SKILL_FAST_UNARMED, 6, probability = stun_chance)
		if(stun_check?["passed"])
			target.Stun(get_cyberpunk_skill_perk_bonus(SKILL_FAST_UNARMED, 6, "value_2") * 1 SECONDS)
			to_chat(src, span_notice("Your kick stuns [target.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/proc/apply_cyberpunk_power_unarmed_effects(mob/living/target)
	if(!target)
		return FALSE
	if(has_character_giga_perk(ATTRIBUTE_STRENGTH) && prob(get_character_skill_level(SKILL_POWER_UNARMED) * 15) && iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		var/obj/item/bodypart/hit_part = carbon_target.get_bodypart(check_hit_limb_zone_name(zone_selected || BODY_ZONE_CHEST))
		if(hit_part)
			carbon_target.cause_wound_of_type_and_severity(WOUND_BLUNT, hit_part, WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_SEVERE, wound_source = "power unarmed strike")
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 4)))
		target.adjust_staggered_up_to(4 SECONDS, 10 SECONDS)
	if(target.has_status_effect(/datum/status_effect/staggered) && prob(get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 5)))
		target.Stun(2 SECONDS)
	if(target.IsStun() && prob(get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 6)))
		target.visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] uppercuts [target.declent_ru(ACCUSATIVE)]!"))
		target.Knockdown(3 SECONDS)
		target.apply_damage(10, STAMINA)
	return TRUE

/mob/living/proc/get_cyberpunk_power_unarmed_parry_wear_damage()
	var/wear_bonus = get_cyberpunk_skill_perk_bonus(SKILL_POWER_UNARMED, 3)
	if(wear_bonus <= 0)
		return 0
	var/wear_damage = round(get_attribute_value(ATTRIBUTE_STRENGTH) * wear_bonus * 0.01)
	if(wear_damage <= 0)
		return 0
	return wear_damage

/mob/living/proc/apply_cyberpunk_power_unarmed_parry_wear(obj/item/blocking_item)
	if(!blocking_item || QDELETED(blocking_item))
		return 0
	var/wear_damage = get_cyberpunk_power_unarmed_parry_wear_damage()
	if(wear_damage <= 0)
		return 0
	blocking_item.take_damage(wear_damage, BRUTE, MELEE, FALSE)
	return wear_damage

/mob/living/proc/get_cyberpunk_grapple_control_bonus()
	if(grab_state == GRAB_AGGRESSIVE)
		return get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 5)
	return 0

/mob/living/proc/get_cyberpunk_grapple_power_damage_multiplier()
	var/damage_bonus = grab_state >= GRAB_TWOHANDED ? get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 2, "value_2") : get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 2, "value_1")
	return 1 + damage_bonus * 0.01

/mob/living/proc/cyberpunk_grapple_suplex_self_save()
	return prob(get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 6, "value_2"))

/mob/living/proc/get_cyberpunk_grapple_unarmed_damage(zone = BODY_ZONE_CHEST, multiplier = 1)
	var/base_damage = 10
	var/obj/item/bodypart/active_part = get_active_hand()
	if(active_part)
		base_damage = max(1, round((active_part.unarmed_damage_low + active_part.unarmed_damage_high) * 0.5))
	return round(base_damage * get_cyberpunk_unarmed_damage_multiplier() * multiplier)

/mob/living/proc/get_cyberpunk_grapple_trip_chance()
	switch(grab_state)
		if(GRAB_PASSIVE)
			return 10
		if(GRAB_AGGRESSIVE)
			return 30
		if(GRAB_TWOHANDED to GRAB_KILL)
			return 50
	return 0

/mob/living/proc/get_cyberpunk_grapple_disarm_chance()
	switch(grab_state)
		if(GRAB_PASSIVE)
			return 20
		if(GRAB_AGGRESSIVE)
			return 40
		if(GRAB_TWOHANDED to GRAB_KILL)
			return 60
	return 0

/mob/living/proc/get_cyberpunk_grapple_action_bonus()
	if(grab_state == GRAB_AGGRESSIVE)
		return get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 5)
	return 0

/mob/living/proc/roll_cyberpunk_grapple_action_success(mob/living/target, base_chance)
	if(!istype(target))
		return FALSE
	var/grapple_check = get_character_skill_level(SKILL_GRAPPLING)
	var/fortitude_check = target.get_character_skill_level(SKILL_FORTITUDE)
	var/chance = base_chance + ((grapple_check - fortitude_check) * 10) + get_cyberpunk_grapple_action_bonus()
	return prob(clamp(chance, 5, 95))

/mob/living/proc/try_cyberpunk_wrestling_launch_click(atom/target_atom)
	if(!isturf(target_atom) || !is_cyberpunk_grabbing_living())
		return FALSE
	var/mob/living/grappled_target = pulling
	return perform_cyberpunk_wrestling_launch(grappled_target, target_atom)

/proc/get_cyberpunk_cardinal_dir_between(atom/start, atom/end)
	if(!start || !end)
		return NONE
	var/delta_x = end.x - start.x
	var/delta_y = end.y - start.y
	if(abs(delta_x) >= abs(delta_y) && delta_x)
		return delta_x > 0 ? EAST : WEST
	if(delta_y)
		return delta_y > 0 ? NORTH : SOUTH
	return NONE

/atom/proc/is_cyberpunk_grapple_hard_target()
	return density

/turf/closed/is_cyberpunk_grapple_hard_target()
	return TRUE

/obj/structure/is_cyberpunk_grapple_hard_target()
	return TRUE

/obj/machinery/is_cyberpunk_grapple_hard_target()
	return TRUE

/mob/living/is_cyberpunk_grapple_hard_target()
	return TRUE

/mob/living/proc/has_cyberpunk_unlock(skill, perk_index)
	return CYBERPUNK_UNLOCKED(get_character_perk_rank(skill, perk_index) > 0)

/mob/living/proc/has_cyberpunk_trait_unlock(trait)
	return CYBERPUNK_UNLOCKED(HAS_TRAIT(src, trait))

/mob/living/proc/fail_cyberpunk_grapple_action(message)
	to_chat(src, span_warning(message))
	return TRUE

/mob/living/proc/can_cyberpunk_grapple_action(mob/living/target, action, zone = null)
	if(!target || pulling != target || grab_state < GRAB_AGGRESSIVE)
		return FALSE
	switch(action)
		if("furniture_throw", "limb_slam")
			return TRUE
		if("wrestling_launch")
			return has_cyberpunk_unlock(SKILL_GRAPPLING, 2)
		if("special_limb")
			var/grabbed_zone = normalize_cyberpunk_grab_zone(cyberpunk_grab_zone)
			var/action_zone = normalize_cyberpunk_grab_zone(zone)
			return has_cyberpunk_unlock(SKILL_PRECISE_UNARMED, 2) && (grabbed_zone == action_zone || is_cyberpunk_grab_zone_torso(grabbed_zone))
		if("choke")
			return zone == BODY_ZONE_PRECISE_NECK && normalize_cyberpunk_grab_zone(cyberpunk_grab_zone) == BODY_ZONE_PRECISE_NECK && grab_state >= GRAB_TWOHANDED
		if("spine_knee")
			return zone == BODY_ZONE_PRECISE_NECK && (normalize_cyberpunk_grab_zone(cyberpunk_grab_zone) == BODY_ZONE_PRECISE_NECK || normalize_cyberpunk_grab_zone(zone_selected) == BODY_ZONE_PRECISE_NECK) && grab_state >= GRAB_TWOHANDED && has_cyberpunk_unlock(SKILL_POWER_UNARMED, 2)
		if("neck_back_slam")
			return zone == BODY_ZONE_PRECISE_NECK && normalize_cyberpunk_grab_zone(cyberpunk_grab_zone) == BODY_ZONE_PRECISE_NECK && grab_state >= GRAB_TWOHANDED && has_cyberpunk_unlock(SKILL_GRAPPLING, 2)
	return FALSE

/mob/living/proc/try_cyberpunk_grapple_attack(mob/living/target, list/modifiers)
	if(LAZYACCESS(modifiers, RIGHT_CLICK) && target != pulling && isliving(pulling))
		var/mob/living/pulled_target = pulling
		return perform_cyberpunk_double_headbutt(pulled_target, target)
	if(!target || pulling != target)
		return FALSE
	var/held_zone = normalize_cyberpunk_grab_zone(cyberpunk_grab_zone)
	var/targeted_zone = normalize_cyberpunk_grab_zone(zone_selected)
	var/action_zone = is_cyberpunk_grab_zone_torso(held_zone) ? targeted_zone : held_zone
	if(!action_zone)
		action_zone = BODY_ZONE_CHEST
	if(LAZYACCESS(modifiers, CTRL_CLICK) && held_zone == BODY_ZONE_PRECISE_NECK)
		return perform_cyberpunk_neck_choke(target)
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		return perform_cyberpunk_spine_knee(target)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(targeted_zone == BODY_ZONE_PRECISE_NECK)
			if(!can_cyberpunk_grapple_action(target, "spine_knee", BODY_ZONE_PRECISE_NECK))
				return fail_cyberpunk_grapple_action("Вы не знаете, как выполнить перелом шеи из этого захвата.")
			return perform_cyberpunk_spine_knee(target)
		if(held_zone == BODY_ZONE_PRECISE_NECK)
			if(grab_state >= GRAB_TWOHANDED)
				return perform_cyberpunk_neck_back_slam(target)
			return perform_cyberpunk_grapple_special(target, action_zone)
		if(!is_cyberpunk_grab_zone_torso(held_zone) && held_zone != targeted_zone)
			return fail_cyberpunk_grapple_action("Выбранная зона не совпадает с зоной захвата.")
		if(is_cyberpunk_grab_zone_torso(action_zone))
			if(grab_state >= GRAB_TWOHANDED)
				return perform_cyberpunk_german_suplex(target)
			if(grab_state >= GRAB_AGGRESSIVE && combat_mode && move_intent == MOVE_INTENT_RUN)
				return perform_cyberpunk_grapple_pounce(target)
			if(can_cyberpunk_grapple_action(target, "special_limb", action_zone))
				return perform_cyberpunk_grapple_self_drag(target)
			return fail_cyberpunk_grapple_action("Вы не знаете, как использовать этот захват торса.")
		if(is_cyberpunk_grab_zone_arm(action_zone))
			if(can_cyberpunk_grapple_action(target, "special_limb", action_zone))
				return perform_cyberpunk_grapple_disarm(target)
			return fail_cyberpunk_grapple_action("Вы не знаете, как выполнить залом руки.")
		if(is_cyberpunk_grab_zone_leg(action_zone))
			if(can_cyberpunk_grapple_action(target, "special_limb", action_zone))
				return perform_cyberpunk_grapple_trip(target)
			return fail_cyberpunk_grapple_action("Вы не знаете, как выполнить подсечку из этого захвата.")
		if(is_cyberpunk_grab_zone_head(action_zone))
			if(can_cyberpunk_grapple_action(target, "special_limb", action_zone))
				return perform_cyberpunk_grapple_special(target, action_zone)
			return fail_cyberpunk_grapple_action("Вы не знаете, как воздействовать на эту зону головы.")
		if(can_cyberpunk_grapple_action(target, "special_limb", action_zone))
			return perform_cyberpunk_grapple_special(target, action_zone)
		return fail_cyberpunk_grapple_action("Вы не знаете, как использовать этот захват.")
	if(can_cyberpunk_grapple_action(target, "choke", BODY_ZONE_PRECISE_NECK))
		return perform_cyberpunk_neck_choke(target)
	return FALSE

/mob/living/proc/perform_cyberpunk_grapple_table_drop(mob/living/target, obj/structure/table/table)
	if(!istype(table) || !target || pulling != target)
		return FALSE
	if(grab_state >= GRAB_AGGRESSIVE)
		return perform_cyberpunk_grapple_hard_impact(target, table)
	if(combat_mode)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] shoves [target.declent_ru(ACCUSATIVE)] onto [table.declent_ru(ACCUSATIVE)]!"), span_danger("You shove [target.declent_ru(ACCUSATIVE)] onto [table.declent_ru(ACCUSATIVE)]!"), null, COMBAT_MESSAGE_RANGE, target)
		target.forceMove(table.loc)
		target.Knockdown(2 SECONDS)
		target.apply_damage(round(20 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
		stop_pulling()
		return TRUE
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] places [target.declent_ru(ACCUSATIVE)] onto [table.declent_ru(ACCUSATIVE)]."), span_notice("You place [target.declent_ru(ACCUSATIVE)] onto [table.declent_ru(ACCUSATIVE)]."))
	target.forceMove(table.loc)
	target.set_resting(TRUE, TRUE)
	stop_pulling()
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_drop_onto(mob/living/target, atom/solid)
	if(!target || pulling != target || !solid)
		return FALSE
	if(isturf(solid) && !combat_mode)
		var/turf/closed/wall = solid
		if(istype(wall))
			return perform_cyberpunk_grapple_wall_pin(target, wall)
	if(combat_mode && solid.is_cyberpunk_grapple_hard_target())
		return perform_cyberpunk_grapple_hard_impact(target, solid)
	return FALSE

/mob/living/proc/perform_cyberpunk_grapple_wall_pin(mob/living/target, turf/closed/wall)
	if(!istype(wall))
		return FALSE
	var/old_grab_state = grab_state
	var/old_grab_zone = cyberpunk_grab_zone
	var/old_grab_durability = cyberpunk_grab_durability
	var/old_grab_max_durability = cyberpunk_grab_max_durability
	var/turf/user_turf = get_turf(src)
	var/turf/pin_turf
	var/best_dist = 999
	for(var/check_dir in GLOB.cardinals)
		var/turf/candidate = get_step(wall, check_dir)
		if(!candidate || candidate.density)
			continue
		var/candidate_dist = get_dist(user_turf, candidate)
		if(candidate_dist >= best_dist)
			continue
		pin_turf = candidate
		best_dist = candidate_dist
	if(!pin_turf)
		pin_turf = user_turf
	if(!pin_turf)
		return FALSE
	var/wall_dir = get_dir(pin_turf, wall)
	if(!wall_dir || ISDIAGONALDIR(wall_dir))
		return FALSE
	forceMove(pin_turf)
	target.forceMove(pin_turf)
	restore_cyberpunk_grapple_after_positioning(target, old_grab_state, old_grab_zone, old_grab_durability, old_grab_max_durability)
	reset_pull_offsets(target, TRUE)
	target.setDir(REVERSE_DIR(wall_dir))
	target.start_leaning(wall, 11)
	visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] pins [target.declent_ru(ACCUSATIVE)] against [wall.declent_ru(ACCUSATIVE)]."), span_warning("You pin [target.declent_ru(ACCUSATIVE)] against [wall.declent_ru(ACCUSATIVE)]."), null, COMBAT_MESSAGE_RANGE, target)
	target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	log_combat(src, target, "wall pinned", null, "against [wall]")
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_self_drag(mob/living/target, living_shield = FALSE)
	if(!target || pulling != target)
		return FALSE
	if(!ishuman(src) || !iscarbon(target) || buckled || target.buckled)
		return FALSE
	var/mob/living/carbon/human/carrier = src
	var/mob/living/carbon/carried = target
	var/carry_mode
	var/buckle_flags = CARRIER_NEEDS_ARM
	var/lying_angle = (dir & (EAST|WEST)) ? LYING_ANGLE_EAST : LYING_ANGLE_WEST
	if(living_shield && grab_state >= GRAB_AGGRESSIVE)
		carry_mode = "living_shield"
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] turns [target.declent_ru(ACCUSATIVE)] into a living shield!"), span_danger("You turn [target.declent_ru(ACCUSATIVE)] into a living shield!"), null, COMBAT_MESSAGE_RANGE, target)
		carried.resting = FALSE
		carried.update_resting()
		carried.set_body_position(STANDING_UP)
		carried.set_lying_angle(0)
	else
		carry_mode = "front_carry"
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] lifts [target.declent_ru(ACCUSATIVE)] into their arms."), span_notice("You lift [target.declent_ru(ACCUSATIVE)] into your arms."), null, COMBAT_MESSAGE_RANGE, target)
		carried.set_lying_down(lying_angle)
	carrier.cyberpunk_carry_mode = carry_mode
	if(!carrier.buckle_mob(carried, TRUE, TRUE, buckle_flags))
		carrier.cyberpunk_carry_mode = null
		return FALSE
	if(carrier.pulling == carried)
		carrier.stop_pulling()
	if(carry_mode == "living_shield")
		carrier.buckle_lying = 0
		carried.resting = FALSE
		carried.update_resting()
		carried.set_body_position(STANDING_UP)
		carried.set_lying_angle(0)
	return TRUE

/mob/living/proc/restore_cyberpunk_grapple_after_positioning(mob/living/target, old_grab_state, old_grab_zone, old_grab_durability, old_grab_max_durability)
	if(!istype(target) || QDELETED(target))
		return FALSE
	pulling = target
	target.set_pulledby(src)
	setGrabState(old_grab_state)
	cyberpunk_grab_zone = old_grab_zone
	cyberpunk_grab_durability = old_grab_durability
	cyberpunk_grab_max_durability = old_grab_max_durability
	update_cyberpunk_grab_hold_items()
	update_pull_movespeed()
	update_pull_hud_icon()
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_hard_impact(mob/living/target, atom/solid)
	if(!solid || !target || pulling != target)
		return FALSE
	var/zone = cyberpunk_grab_zone || zone_selected || BODY_ZONE_CHEST
	var/damage_multiplier = get_cyberpunk_grapple_power_damage_multiplier()
	if(is_cyberpunk_grab_zone_torso(zone))
		damage_multiplier *= 0.5
	var/brute_damage = round(18 * damage_multiplier)
	var/stamina_damage = round(35 * damage_multiplier)
	var/obj/item/bodypart/impacted = target.get_bodypart(zone) || target.get_bodypart(BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] slams [target.declent_ru(ACCUSATIVE)] against [solid.declent_ru(ACCUSATIVE)]!"), span_danger("You slam [target.declent_ru(ACCUSATIVE)] against [solid.declent_ru(ACCUSATIVE)]!"), null, COMBAT_MESSAGE_RANGE, target)
	target.apply_damage(brute_damage, BRUTE, impacted)
	target.apply_damage(stamina_damage, STAMINA)
	apply_cyberpunk_grapple_limb_impact_effect(target, zone)
	if(is_cyberpunk_grab_zone_mouth(zone) && ishuman(target))
		var/mob/living/carbon/human/human_target = target
		human_target.force_say()
	if(ismovable(solid))
		var/atom/movable/movable_solid = solid
		movable_solid.take_damage(max(5, brute_damage))
	playsound(target, 'sound/effects/bang.ogg', 80, TRUE)
	log_combat(src, target, "grapple slammed", null, "against [solid]")
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_furniture_throw(mob/living/target, obj/structure/furniture)
	if(!istype(furniture) || !can_cyberpunk_grapple_action(target, "furniture_throw"))
		return FALSE
	if(!istype(furniture, /obj/structure/table) && !istype(furniture, /obj/structure/chair) && !istype(furniture, /obj/structure/bed))
		return FALSE
	var/turf/destination = get_turf(furniture)
	if(!destination)
		return FALSE
	var/damage_multiplier = get_cyberpunk_grapple_power_damage_multiplier()
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] throws [target.declent_ru(ACCUSATIVE)] into [furniture.declent_ru(ACCUSATIVE)]!"), span_danger("You throw [target.declent_ru(ACCUSATIVE)] into [furniture.declent_ru(ACCUSATIVE)]!"), null, COMBAT_MESSAGE_RANGE, target)
	target.throw_at(destination, max(1, get_dist(target, destination)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG, callback = CALLBACK(src, PROC_REF(finish_cyberpunk_grapple_furniture_throw), target, furniture, damage_multiplier))
	apply_cyberpunk_grapple_limb_impact_effect(target, cyberpunk_grab_zone)
	target.apply_damage(round(20 * damage_multiplier), STAMINA)
	stop_pulling()
	log_combat(src, target, "grapple threw", null, "onto [furniture]")
	return TRUE

/mob/living/proc/try_cyberpunk_grapple_furniture_click(atom/target_atom)
	if(!istype(target_atom, /obj/structure) || !isliving(pulling))
		return FALSE
	var/mob/living/grappled_target = pulling
	var/obj/structure/furniture = target_atom
	return perform_cyberpunk_grapple_furniture_throw(grappled_target, furniture)

/mob/living/proc/perform_cyberpunk_double_headbutt(mob/living/held_target, mob/living/clicked_target)
	if(!held_target || !clicked_target || held_target == clicked_target || pulling != held_target || grab_state < GRAB_AGGRESSIVE)
		return FALSE
	if(!Adjacent(held_target) || !Adjacent(clicked_target))
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] smashes [held_target.declent_ru(ACCUSATIVE)] and [clicked_target.declent_ru(ACCUSATIVE)] forehead-first into each other!"), span_danger("You smash [held_target.declent_ru(ACCUSATIVE)] and [clicked_target.declent_ru(ACCUSATIVE)] forehead-first into each other!"), null, COMBAT_MESSAGE_RANGE, held_target)
	var/damage = round(12 * get_cyberpunk_grapple_power_damage_multiplier())
	held_target.apply_damage(damage, BRUTE, BODY_ZONE_HEAD)
	clicked_target.apply_damage(damage, BRUTE, BODY_ZONE_HEAD)
	held_target.apply_damage(20, STAMINA)
	clicked_target.apply_damage(20, STAMINA)
	held_target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	clicked_target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	log_combat(src, held_target, "double headbutted", clicked_target)
	return TRUE

/mob/living/proc/finish_cyberpunk_grapple_furniture_throw(mob/living/target, obj/structure/furniture, damage_multiplier = 1)
	if(QDELETED(target) || QDELETED(furniture))
		return FALSE
	var/turf/furniture_turf = get_turf(furniture)
	if(!furniture_turf)
		return FALSE
	target.forceMove(furniture_turf)
	target.Knockdown(2 SECONDS)
	target.apply_damage(round(12 * damage_multiplier), BRUTE)
	if(istype(furniture, /obj/structure/chair) || istype(furniture, /obj/structure/bed))
		furniture.buckle_mob(target, force = TRUE, check_loc = FALSE)
	else if(istype(furniture, /obj/structure/table))
		target.set_resting(TRUE, TRUE)
	return TRUE

/mob/living/proc/perform_cyberpunk_wrestling_launch(mob/living/target, turf/destination)
	if(!istype(destination) || !can_cyberpunk_grapple_action(target, "wrestling_launch"))
		return FALSE
	if(!roll_cyberpunk_grapple_action_success(target, 50))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to launch [target.declent_ru(ACCUSATIVE)] from the grab."), span_warning("You fail to launch [target.declent_ru(ACCUSATIVE)] from the grab."), null, COMBAT_MESSAGE_RANGE, target)
		log_combat(src, target, "attempted wrestling launch")
		return TRUE
	var/launch_dir = get_cyberpunk_cardinal_dir_between(target, destination)
	if(!launch_dir)
		launch_dir = get_cyberpunk_cardinal_dir_between(src, destination)
	if(!launch_dir)
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] forces [target.declent_ru(ACCUSATIVE)] into a stumbling wrestling run!"), span_danger("You force [target.declent_ru(ACCUSATIVE)] into a wrestling run!"), null, COMBAT_MESSAGE_RANGE, target)
	target.cyberpunk_wrestling_launch_dir = launch_dir
	target.cyberpunk_wrestling_launch_rebounded = FALSE
	target.cyberpunk_wrestling_launch_until = world.time + 4 SECONDS
	stop_pulling()
	target.setDir(launch_dir)
	target.continue_cyberpunk_wrestling_launch(src, launch_dir, 6, FALSE)
	log_combat(src, target, "wrestling launched")
	return TRUE

/mob/living/proc/continue_cyberpunk_wrestling_launch(mob/living/launcher, launch_dir, steps_left, rebounded)
	if(QDELETED(src) || stat == DEAD || steps_left <= 0 || !launch_dir)
		cyberpunk_wrestling_launch_until = max(cyberpunk_wrestling_launch_until, world.time + 2 SECONDS)
		return
	cyberpunk_wrestling_launch_dir = launch_dir
	cyberpunk_wrestling_launch_rebounded = rebounded
	cyberpunk_wrestling_launch_until = world.time + 2 SECONDS
	var/turf/current_turf = get_turf(src)
	var/turf/next_turf = get_step(current_turf, launch_dir)
	if(!next_turf)
		finish_cyberpunk_wrestling_launch_impact(launcher, current_turf, rebounded)
		return
	if(next_turf.density)
		if(!rebounced_cyberpunk_wrestling_launch_from_wall(launcher, next_turf, launch_dir, rebounded))
			finish_cyberpunk_wrestling_launch_impact(launcher, next_turf, rebounded)
		return
	for(var/atom/movable/blocker as anything in next_turf)
		if(blocker == src)
			continue
		if(blocker.density && !blocker.CanPass(src, launch_dir))
			finish_cyberpunk_wrestling_launch_impact(launcher, blocker, rebounded)
			return
	if(!Move(next_turf, launch_dir))
		finish_cyberpunk_wrestling_launch_impact(launcher, next_turf, rebounded)
		return
	setDir(launch_dir)
	addtimer(CALLBACK(src, PROC_REF(continue_cyberpunk_wrestling_launch), launcher, launch_dir, steps_left - 1, rebounded), 0.2 SECONDS)

/mob/living/proc/rebounced_cyberpunk_wrestling_launch_from_wall(mob/living/launcher, turf/hit_wall, launch_dir, rebounded)
	if(rebounded || !istype(hit_wall, /turf/closed))
		return FALSE
	var/rebound_dir = REVERSE_DIR(launch_dir)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] rebounds from [hit_wall.declent_ru(ACCUSATIVE)] and staggers back!"), span_userdanger("You hit [hit_wall.declent_ru(ACCUSATIVE)] and rebound back!"))
	setDir(rebound_dir)
	addtimer(CALLBACK(src, PROC_REF(continue_cyberpunk_wrestling_launch), launcher, rebound_dir, 6, TRUE), 0.2 SECONDS)
	return TRUE

/mob/living/proc/finish_cyberpunk_wrestling_launch_impact(mob/living/launcher, atom/impact_target, rebounded)
	cyberpunk_wrestling_launch_until = max(cyberpunk_wrestling_launch_until, world.time + 2 SECONDS)
	Knockdown(2 SECONDS)
	var/damage = 10
	if(istype(launcher))
		damage = launcher.get_attribute_value(ATTRIBUTE_STRENGTH) + launcher.get_cyberpunk_grapple_unarmed_damage(BODY_ZONE_HEAD)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] crashes head-first into [impact_target.declent_ru(ACCUSATIVE)]!"), span_userdanger("You crash head-first into [impact_target.declent_ru(ACCUSATIVE)]!"))
	apply_damage(damage, BRUTE, BODY_ZONE_HEAD)
	apply_damage(round(damage * 0.5), STAMINA)
	log_combat(launcher, src, "wrestling launch impact", null, "against [impact_target]")

/mob/living/proc/try_cyberpunk_wrestling_elbow_check(mob/living/target)
	if(!target || target.cyberpunk_wrestling_launch_until < world.time)
		return FALSE
	if(get_dist(src, target) > 1)
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] cuts [target.declent_ru(ACCUSATIVE)] down with an elbow check!"), span_danger("You cut [target.declent_ru(ACCUSATIVE)] down with an elbow check!"), null, COMBAT_MESSAGE_RANGE, target)
	target.Knockdown(2 SECONDS)
	target.apply_damage(round(get_cyberpunk_grapple_unarmed_damage(BODY_ZONE_HEAD, 0.75)), STAMINA)
	target.cyberpunk_wrestling_launch_until = 0
	target.cyberpunk_wrestling_launch_dir = NONE
	log_combat(src, target, "elbow checked wrestling launch")
	return TRUE

/mob/living/proc/perform_cyberpunk_neck_throw(mob/living/target, atom/destination)
	if(!destination || !target || pulling != target || grab_state < GRAB_TWOHANDED)
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] throws [target.declent_ru(ACCUSATIVE)] from a two-handed grab!"), span_danger("You throw [target.declent_ru(ACCUSATIVE)] from a two-handed grab!"), null, COMBAT_MESSAGE_RANGE, target)
	target.throw_at(destination, max(1, get_dist(target, destination)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG)
	target.apply_damage(round(20 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
	stop_pulling()
	log_combat(src, target, "two-handed grab threw")
	return TRUE

/mob/living/proc/apply_cyberpunk_grapple_limb_impact_effect(mob/living/target, zone)
	if(!can_cyberpunk_grapple_action(target, "limb_slam", zone))
		return FALSE
	var/control_bonus = get_cyberpunk_grapple_control_bonus()
	var/damage_multiplier = get_cyberpunk_grapple_power_damage_multiplier()
	target.apply_damage(round(10 * (1 + control_bonus * 0.01) * damage_multiplier), STAMINA)
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
		if(BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_NOSE, BODY_ZONE_PRECISE_NECK, BODY_ZONE_HEAD)
			target.apply_damage(round(10 * damage_multiplier), STAMINA)
			target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
		if(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_ABDOMEN)
			target.apply_damage(round(15 * damage_multiplier), STAMINA)
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_special(mob/living/target, zone)
	if(!can_cyberpunk_grapple_action(target, "special_limb", zone))
		return FALSE
	if(is_cyberpunk_grab_zone_torso(cyberpunk_grab_zone) && is_cyberpunk_grab_zone_torso(zone))
		return FALSE
	if(!roll_cyberpunk_grapple_action_success(target, 50))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to force [target.declent_ru(ACCUSATIVE)] into a painful hold."), span_warning("You fail to force [target.declent_ru(ACCUSATIVE)] into a painful hold."), null, COMBAT_MESSAGE_RANGE, target)
		log_combat(src, target, "attempted grapple special", null, "zone [zone]")
		return TRUE
	apply_cyberpunk_grapple_limb_impact_effect(target, zone)
	if(zone == BODY_ZONE_CHEST || zone == BODY_ZONE_PRECISE_ABDOMEN)
		target.Knockdown(1 SECONDS)
		target.apply_damage(round(20 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
	var/list/hold_messages = get_cyberpunk_grapple_special_messages(target, zone)
	visible_message(span_danger(hold_messages[1]), span_danger(hold_messages[2]), null, COMBAT_MESSAGE_RANGE, target)
	log_combat(src, target, "used grapple special", null, "zone [zone]")
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_pounce(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_AGGRESSIVE || !is_cyberpunk_grab_zone_torso())
		return FALSE
	var/pounce_dir = get_dir(src, target)
	if(!pounce_dir || ISDIAGONALDIR(pounce_dir))
		pounce_dir = dir
	var/turf/next_turf = get_step(src, pounce_dir)
	if(next_turf && !next_turf.is_blocked_turf(source_atom = src))
		Move(next_turf, pounce_dir)
	target.forceMove(get_turf(src))
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] drives [target.declent_ru(ACCUSATIVE)] down in a grapple pounce!"), span_danger("You drive [target.declent_ru(ACCUSATIVE)] down in a grapple pounce!"), null, COMBAT_MESSAGE_RANGE, target)
	target.Knockdown(2 SECONDS, ignore_canstun = TRUE)
	Knockdown(1 SECONDS, ignore_canstun = TRUE)
	target.apply_damage(round(25 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
	stop_pulling()
	log_combat(src, target, "grapple pounced")
	return TRUE

/mob/living/proc/get_cyberpunk_grapple_special_messages(mob/living/target, zone)
	switch(zone)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			return list("[capitalize(declent_ru(NOMINATIVE))] wrenches [target.declent_ru(GENITIVE)] arm, forcing the grip open!", "You wrench [target.declent_ru(GENITIVE)] arm and force their grip open!")
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			return list("[capitalize(declent_ru(NOMINATIVE))] sweeps [target.declent_ru(GENITIVE)] leg out from the grab!", "You sweep [target.declent_ru(GENITIVE)] leg out from the grab!")
		if(BODY_ZONE_HEAD)
			return list("[capitalize(declent_ru(NOMINATIVE))] crushes [target.declent_ru(GENITIVE)] head between both hands!", "You crush [target.declent_ru(GENITIVE)] head between your hands!")
		if(BODY_ZONE_PRECISE_EYES)
			return list("[capitalize(declent_ru(NOMINATIVE))] digs fingers toward [target.declent_ru(GENITIVE)] eyes!", "You dig your fingers toward [target.declent_ru(GENITIVE)] eyes!")
		if(BODY_ZONE_PRECISE_EARS)
			return list("[capitalize(declent_ru(NOMINATIVE))] twists [target.declent_ru(GENITIVE)] ear and breaks their balance!", "You twist [target.declent_ru(GENITIVE)] ear and break their balance!")
		if(BODY_ZONE_PRECISE_MOUTH)
			return list("[capitalize(declent_ru(NOMINATIVE))] pulls [target.declent_ru(GENITIVE)] tongue in the grab!", "You pull [target.declent_ru(GENITIVE)] tongue in the grab!")
		if(BODY_ZONE_PRECISE_NOSE)
			return list("[capitalize(declent_ru(NOMINATIVE))] crushes [target.declent_ru(GENITIVE)] nose in the grab!", "You crush [target.declent_ru(GENITIVE)] nose in the grab!")
		if(BODY_ZONE_PRECISE_NECK)
			return list("[capitalize(declent_ru(NOMINATIVE))] twists [target.declent_ru(GENITIVE)] neck into a painful hold!", "You twist [target.declent_ru(GENITIVE)] neck into a painful hold!")
		if(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_ABDOMEN)
			return list("[capitalize(declent_ru(NOMINATIVE))] drives [target.declent_ru(ACCUSATIVE)] down by the torso!", "You drive [target.declent_ru(ACCUSATIVE)] down by the torso!")
	return list("[capitalize(declent_ru(NOMINATIVE))] twists [target.declent_ru(ACCUSATIVE)] in a painful hold!", "You twist [target.declent_ru(ACCUSATIVE)] in a painful hold!")

/mob/living/proc/perform_cyberpunk_grapple_trip(mob/living/target)
	if(!target || pulling != target)
		return FALSE
	var/chance = get_cyberpunk_grapple_trip_chance()
	var/damage = round(get_cyberpunk_grapple_unarmed_damage(BODY_ZONE_L_LEG, 0.5) * get_cyberpunk_grapple_power_damage_multiplier())
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] tries to knock [target.declent_ru(ACCUSATIVE)] off balance from the grab!"), span_danger("You try to knock [target.declent_ru(ACCUSATIVE)] off balance from the grab!"), null, COMBAT_MESSAGE_RANGE, target)
	target.apply_damage(damage, STAMINA)
	if(roll_cyberpunk_grapple_action_success(target, chance))
		target.Knockdown(2 SECONDS)
		to_chat(src, span_danger("You knock [target.declent_ru(ACCUSATIVE)] off balance."))
		log_combat(src, target, "grapple tripped")
	else
		to_chat(src, span_warning("You fail to knock [target.declent_ru(ACCUSATIVE)] off balance."))
		to_chat(target, span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to knock you off balance."))
		log_combat(src, target, "attempted grapple trip")
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_disarm(mob/living/target)
	if(!target || pulling != target)
		return FALSE
	var/obj/item/held_item = target.get_active_held_item() || target.get_inactive_held_item()
	if(!held_item)
		to_chat(src, span_warning("[capitalize(target.declent_ru(NOMINATIVE))] is not holding anything."))
		return TRUE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] twists [target.declent_ru(GENITIVE)] arm, trying to take [held_item.declent_ru(ACCUSATIVE)]!"), span_danger("You try to take [held_item.declent_ru(ACCUSATIVE)] from [target.declent_ru(GENITIVE)] grip!"), null, COMBAT_MESSAGE_RANGE, target)
	if(!roll_cyberpunk_grapple_action_success(target, get_cyberpunk_grapple_disarm_chance()))
		to_chat(src, span_warning("You fail to take [held_item.declent_ru(ACCUSATIVE)] from [target.declent_ru(GENITIVE)] grip."))
		to_chat(target, span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to take [held_item.declent_ru(ACCUSATIVE)] from your grip."))
		log_combat(src, target, "attempted grapple disarm", null, "[held_item]")
		return TRUE
	if(target.dropItemToGround(held_item, TRUE))
		if(!put_in_hands(held_item))
			held_item.forceMove(get_turf(target))
		to_chat(src, span_danger("You take [held_item.declent_ru(ACCUSATIVE)] from [target.declent_ru(GENITIVE)] grip."))
		log_combat(src, target, "grapple disarmed", null, "[held_item]")
	return TRUE

/mob/living/proc/perform_cyberpunk_grapple_head_control(mob/living/target)
	if(!target || pulling != target)
		return FALSE
	if(!roll_cyberpunk_grapple_action_success(target, 50))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to control [target.declent_ru(GENITIVE)] head."), span_warning("You fail to control [target.declent_ru(GENITIVE)] head."), null, COMBAT_MESSAGE_RANGE, target)
		log_combat(src, target, "attempted grapple head control")
		return TRUE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] squeezes [target.declent_ru(GENITIVE)] head!"), span_danger("You squeeze [target.declent_ru(GENITIVE)] head!"), null, COMBAT_MESSAGE_RANGE, target)
	target.sound_damage(0, 5 SECONDS)
	target.adjust_staggered_up_to(1 SECONDS, 4 SECONDS)
	if(grab_state >= GRAB_TWOHANDED)
		target.apply_damage(round(get_cyberpunk_grapple_unarmed_damage(BODY_ZONE_HEAD, 1.1) * get_cyberpunk_grapple_power_damage_multiplier()), BRUTE, BODY_ZONE_HEAD)
	log_combat(src, target, "grapple head controlled")
	return TRUE

/mob/living/proc/perform_cyberpunk_neck_choke(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "choke", BODY_ZONE_PRECISE_NECK))
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] chokes [target.declent_ru(ACCUSATIVE)]!"), span_danger("You choke [target.declent_ru(ACCUSATIVE)]!"), null, COMBAT_MESSAGE_RANGE, target)
	target.apply_damage(12, OXY)
	target.apply_damage(35, STAMINA)
	log_combat(src, target, "choked")
	return TRUE

/mob/living/proc/perform_cyberpunk_spine_knee(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "spine_knee", BODY_ZONE_PRECISE_NECK))
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] drives [target.declent_ru(ACCUSATIVE)] spine-first into a knee!"), span_danger("You drive [target.declent_ru(ACCUSATIVE)] spine-first into your knee!"), null, COMBAT_MESSAGE_RANGE, target)
	target.Stun(2 SECONDS)
	target.apply_damage(round(25 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
	if(prob(65))
		stop_pulling()
		adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	log_combat(src, target, "kneed spine")
	return TRUE

/mob/living/proc/perform_cyberpunk_german_suplex(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_TWOHANDED || is_cyberpunk_grab_zone_head(cyberpunk_grab_zone))
		return FALSE
	if(!roll_cyberpunk_grapple_action_success(target, 50))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to suplex [target.declent_ru(ACCUSATIVE)]."), span_warning("You fail to suplex [target.declent_ru(ACCUSATIVE)]."), null, COMBAT_MESSAGE_RANGE, target)
		log_combat(src, target, "attempted german suplex")
		return TRUE
	var/turf/behind = get_step(src, REVERSE_DIR(dir)) || get_turf(src)
	if(!behind)
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] throws [target.declent_ru(ACCUSATIVE)] backward in a suplex!"), span_danger("You throw [target.declent_ru(ACCUSATIVE)] backward in a suplex!"), null, COMBAT_MESSAGE_RANGE, target)
	var/old_density = density
	density = FALSE
	target.throw_at(behind, max(1, get_dist(target, behind)), 2, src, spin = TRUE, force = MOVE_FORCE_STRONG)
	target.Knockdown(3 SECONDS)
	target.apply_damage(round(35 * get_cyberpunk_grapple_power_damage_multiplier()), STAMINA)
	addtimer(CALLBACK(src, PROC_REF(restore_cyberpunk_grapple_density), old_density), 0.5 SECONDS)
	stop_pulling()
	log_combat(src, target, "german suplexed")
	return TRUE

/mob/living/proc/restore_cyberpunk_grapple_density(old_density)
	density = old_density

/mob/living/proc/perform_cyberpunk_neck_back_slam(mob/living/target)
	if(!can_cyberpunk_grapple_action(target, "neck_back_slam", BODY_ZONE_PRECISE_NECK))
		return FALSE
	var/turf/behind = get_step(src, REVERSE_DIR(dir)) || get_turf(src)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] slams [target.declent_ru(ACCUSATIVE)] down behind them!"), span_danger("You slam [target.declent_ru(ACCUSATIVE)] down behind you!"), null, COMBAT_MESSAGE_RANGE, target)
	target.forceMove(behind)
	setDir(REVERSE_DIR(dir))
	target.Knockdown(3 SECONDS)
	Knockdown(2 SECONDS)
	var/damage_multiplier = get_cyberpunk_grapple_power_damage_multiplier()
	target.apply_damage(round(15 * damage_multiplier), BRUTE)
	target.apply_damage(round(35 * damage_multiplier), STAMINA)
	stop_pulling()
	log_combat(src, target, "neck back slammed")
	return TRUE

/mob/living/proc/apply_cyberpunk_machine_wear(obj/machinery/machine, amount = 1, source = null)
	if(!machine || amount <= 0)
		return FALSE
	return machine.apply_cyberpunk_machine_wear(amount, source, src)
