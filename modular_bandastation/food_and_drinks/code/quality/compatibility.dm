GLOBAL_LIST_INIT(foodtype_synergies, list(
	list(MEAT, VEGETABLES),
	list(MEAT, GRAIN),
	list(SEAFOOD, VEGETABLES),
	list(SEAFOOD, GRAIN),
	list(FRUIT, SUGAR),
	list(NUTS, SUGAR),
	list(GRAIN, DAIRY),
	list(EGG, DAIRY),
	list(EGG, VEGETABLES),
	list(VEGETABLES, DAIRY),
	list(BREAKFAST, EGG),
	list(BREAKFAST, GRAIN),
))

GLOBAL_LIST_INIT(foodtype_antagonisms, list(
	list(DAIRY, FRUIT),
	list(DAIRY, ALCOHOL),
	list(ORANGES, DAIRY),
	list(SUGAR, RAW),
	list(PINEAPPLE, MEAT),
	list(GROSS, MEAT),
	list(GROSS, FRUIT),
	list(GROSS, VEGETABLES),
	list(GROSS, DAIRY),
	list(GROSS, SEAFOOD),
	list(GROSS, GRAIN),
	list(GROSS, SUGAR),
	list(GORE, DAIRY),
	list(GORE, GRAIN),
	list(BUGS, DAIRY),
	list(BUGS, SUGAR),
))

/obj/item/food
	/// Last reagent-effect multiplier applied by CP13 quality scaling. Used to keep repeated quality updates idempotent.
	var/cyberpunk_quality_effect_multiplier = 1

/proc/calculate_food_compat_bonus(foodtypes)
	if(!foodtypes)
		return 0
	var/bonus = 0
	for(var/list/pair as anything in GLOB.foodtype_synergies)
		if((foodtypes & pair[1]) && (foodtypes & pair[2]))
			bonus += COMPAT_SYNERGY_BONUS
	var/penalty = 0
	for(var/list/pair as anything in GLOB.foodtype_antagonisms)
		if((foodtypes & pair[1]) && (foodtypes & pair[2]))
			penalty += COMPAT_ANTAGONISM_PENALTY
	bonus = min(bonus, COMPAT_BONUS_CAP)
	penalty = max(penalty, COMPAT_PENALTY_CAP)
	return bonus + penalty

/proc/cyberpunk_food_quality_from_components(list/components)
	if(!length(components))
		return 0
	var/total_quality = 0
	var/quality_sources = 0
	for(var/atom/component as anything in components)
		if(!istype(component, /obj/item/food))
			continue
		var/obj/item/food/food_component = component
		var/datum/component/edible/edible = food_component.GetComponent(/datum/component/edible)
		if(!edible)
			continue
		total_quality += edible.get_recipe_complexity()
		quality_sources++
	if(!quality_sources)
		return 0
	return clamp(round(total_quality / quality_sources), -CY_FOOD_INHERITED_QUALITY_CAP, CY_FOOD_INHERITED_QUALITY_CAP)

/proc/cyberpunk_apply_food_pipeline(obj/item/food/result, mob/living/cooker = null, list/components = null, include_cooker = TRUE)
	if(!istype(result))
		return
	var/inherited_quality = cyberpunk_food_quality_from_components(components)
	if(inherited_quality)
		result.AddElement(/datum/element/quality_food_ingredient, inherited_quality)
	if(include_cooker && cooker)
		var/quality_bonus = cooker.get_cyberpunk_cooking_quality_bonus()
		if(quality_bonus > 0)
			result.AddElement(/datum/element/quality_food_ingredient, quality_bonus)
		var/compatibility_bonus = cooker.get_cyberpunk_cooking_compatibility_bonus(result)
		if(compatibility_bonus)
			result.AddElement(/datum/element/quality_food_ingredient, compatibility_bonus)
	result.cyberpunk_update_quality_effects()

/obj/item/food/proc/cyberpunk_update_quality_effects()
	if(!reagents?.total_volume)
		return
	var/datum/component/edible/edible = GetComponent(/datum/component/edible)
	if(!edible)
		return
	var/quality = edible.get_recipe_complexity()
	var/new_multiplier = clamp(1 + quality * CY_FOOD_QUALITY_EFFECT_PER_POINT, CY_FOOD_QUALITY_EFFECT_MIN, CY_FOOD_QUALITY_EFFECT_MAX)
	if(new_multiplier == cyberpunk_quality_effect_multiplier)
		return
	var/ratio = new_multiplier / cyberpunk_quality_effect_multiplier
	cyberpunk_quality_effect_multiplier = new_multiplier
	var/list/consumable_reagents = list()
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		if(ispath(reagent.type, /datum/reagent/consumable))
			consumable_reagents |= reagent.type
	for(var/reagent_type as anything in consumable_reagents)
		reagents.multiply(ratio, reagent_type)

/obj/item/food/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	var/mob/living/living_crafter = isliving(crafter) ? crafter : null
	cyberpunk_apply_food_pipeline(src, living_crafter, components)

/obj/item/food/OnCreatedFromProcessing(mob/living/user, obj/item/work_tool, list/chosen_option, atom/original_atom)
	. = ..()
	var/list/components
	if(original_atom)
		components = list(original_atom)
	// Core processing already applies cook and compatibility bonuses; keep this pass to inherited ingredient quality and effect scaling.
	cyberpunk_apply_food_pipeline(src, null, components, include_cooker = FALSE)

/datum/component/ingredient_compatibility
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/ingredient_compatibility/Initialize()
	if(!istype(parent, /obj/item/food))
		return COMPONENT_INCOMPATIBLE

/datum/component/ingredient_compatibility/RegisterWithParent()
	RegisterSignal(parent, COMSIG_FOOD_GET_EXTRA_COMPLEXITY, PROC_REF(on_get_complexity))

/datum/component/ingredient_compatibility/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_FOOD_GET_EXTRA_COMPLEXITY)

/datum/component/ingredient_compatibility/proc/on_get_complexity(datum/source, list/extra_complexity)
	SIGNAL_HANDLER
	var/obj/item/food/food = parent
	extra_complexity[1] += calculate_food_compat_bonus(food.foodtypes)
