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
	/// Extra edible items stacked onto this food as free-form additions.
	var/list/cyberpunk_food_additions

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

/proc/cyberpunk_food_average_quality(list/foods)
	if(!length(foods))
		return 0
	var/total_quality = 0
	var/quality_sources = 0
	for(var/obj/item/food/food as anything in foods)
		if(!istype(food))
			continue
		var/datum/component/edible/edible = food.GetComponent(/datum/component/edible)
		if(!edible)
			continue
		total_quality += edible.get_recipe_complexity()
		quality_sources++
	if(!quality_sources)
		return 0
	return clamp(round(total_quality / quality_sources), -CY_FOOD_INHERITED_QUALITY_CAP, CY_FOOD_INHERITED_QUALITY_CAP)

/obj/item/food/proc/cyberpunk_refresh_added_foodtypes()
	var/combined_foodtypes = initial(foodtypes)
	for(var/obj/item/food/addition as anything in cyberpunk_food_additions)
		if(!istype(addition))
			continue
		combined_foodtypes |= addition.foodtypes
	foodtypes = combined_foodtypes

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

/datum/component/cyberpunk_food_quality_model
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/cyberpunk_food_quality_model/Initialize()
	if(!istype(parent, /obj/item/food))
		return COMPONENT_INCOMPATIBLE

/datum/component/cyberpunk_food_quality_model/RegisterWithParent()
	RegisterSignal(parent, COMSIG_FOOD_GET_EXTRA_COMPLEXITY, PROC_REF(on_get_complexity))
	RegisterSignal(parent, COMSIG_FOOD_EATEN, PROC_REF(on_eaten))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/cyberpunk_food_quality_model/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_FOOD_GET_EXTRA_COMPLEXITY, COMSIG_FOOD_EATEN, COMSIG_ATOM_EXAMINE))

/datum/component/cyberpunk_food_quality_model/proc/on_get_complexity(datum/source, list/extra_complexity)
	SIGNAL_HANDLER
	var/obj/item/food/food = parent
	if(!HAS_TRAIT(food, TRAIT_FOOD_CHEF_MADE))
		extra_complexity[1] += max(initial(food.crafting_complexity), FOOD_QUALITY_NORMAL)
	if(length(food.cyberpunk_food_additions))
		extra_complexity[1] += cyberpunk_food_average_quality(food.cyberpunk_food_additions)

/datum/component/cyberpunk_food_quality_model/proc/on_eaten(datum/source, mob/living/eater, mob/living/feeder, bitecount, bitesize)
	SIGNAL_HANDLER
	if(!istype(eater))
		return
	var/obj/item/food/food = parent
	var/datum/component/edible/edible = food.GetComponent(/datum/component/edible)
	if(!edible)
		return
	var/quality = edible.get_perceived_food_quality(eater)
	if(quality >= 0)
		return
	if(quality <= PERISH_PENALTY_GROSS)
		eater.reagents?.add_reagent(/datum/reagent/toxin/bad_food, abs(quality))
	if(quality <= PERISH_PENALTY_ROTTEN && iscarbon(eater) && prob(20 + abs(quality) * 10))
		var/mob/living/carbon/carbon_eater = eater
		carbon_eater.vomit(VOMIT_CATEGORY_DEFAULT, lost_nutrition = 5)

/datum/component/cyberpunk_food_quality_model/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/obj/item/food/food = parent
	var/datum/component/edible/edible = food.GetComponent(/datum/component/edible)
	if(edible)
		examine_list += span_notice("Качество: [food_quality_5tier(edible.get_recipe_complexity())].")
	if(length(food.cyberpunk_food_additions))
		var/list/addition_names = list()
		for(var/obj/item/food/addition as anything in food.cyberpunk_food_additions)
			addition_names += addition.declent_ru(NOMINATIVE)
		examine_list += span_notice("Дополнения: [english_list(addition_names, and_text = " и ", comma_text = ", ")].")

/datum/component/cyberpunk_food_additions
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/max_additions = 6

/datum/component/cyberpunk_food_additions/Initialize(max_additions = 6)
	if(!istype(parent, /obj/item/food))
		return COMPONENT_INCOMPATIBLE
	src.max_additions = max_additions

/datum/component/cyberpunk_food_additions/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(on_food_exited))
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(on_parent_qdeleting))
	RegisterSignal(parent, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, PROC_REF(on_requesting_context_from_item))
	var/atom/atom_parent = parent
	atom_parent.flags_1 |= HAS_CONTEXTUAL_SCREENTIPS_1

/datum/component/cyberpunk_food_additions/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_ATTACKBY, COMSIG_ATOM_EXITED, COMSIG_QDELETING, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM))

/datum/component/cyberpunk_food_additions/proc/can_add(obj/item/food/ingredient)
	var/obj/item/food/food = parent
	if(HAS_TRAIT(food, TRAIT_INGREDIENTS_HOLDER))
		return FALSE
	if(!istype(ingredient) || ingredient == food)
		return FALSE
	if(ingredient.loc == food)
		return FALSE
	if(length(food.cyberpunk_food_additions) >= max_additions)
		return FALSE
	return TRUE

/datum/component/cyberpunk_food_additions/proc/on_attackby(datum/source, obj/item/food/ingredient, mob/living/user, list/modifiers)
	SIGNAL_HANDLER
	if(!can_add(ingredient))
		return
	var/obj/item/food/food = parent
	if(!user.transferItemToLoc(ingredient, food))
		return COMPONENT_NO_AFTERATTACK
	LAZYADD(food.cyberpunk_food_additions, ingredient)
	food.vis_contents += ingredient
	ingredient.vis_flags |= VIS_INHERIT_PLANE
	ingredient.pixel_w = rand(-4, 4)
	ingredient.pixel_z = min(6, 2 + length(food.cyberpunk_food_additions))
	ingredient.pixel_x = 0
	ingredient.pixel_y = 0
	if(food.reagents && ingredient.reagents)
		food.reagents.maximum_volume += ingredient.reagents.maximum_volume
		ingredient.reagents.trans_to(food, ingredient.reagents.total_volume)
	food.cyberpunk_refresh_added_foodtypes()
	SEND_SIGNAL(ingredient, COMSIG_ITEM_USED_AS_INGREDIENT, food)
	SEND_SIGNAL(food, COMSIG_FOOD_INGREDIENT_ADDED, ingredient.GetComponent(/datum/component/edible))
	food.cyberpunk_update_quality_effects()
	food.name = "[initial(food.name)] с дополнениями"
	to_chat(user, span_notice("Вы добавляете [ingredient.declent_ru(ACCUSATIVE)] к [food.declent_ru(DATIVE)]."))
	return COMPONENT_NO_AFTERATTACK

/datum/component/cyberpunk_food_additions/proc/on_food_exited(datum/source, atom/movable/gone)
	SIGNAL_HANDLER
	var/obj/item/food/food = parent
	if(!(gone in food.cyberpunk_food_additions))
		return
	LAZYREMOVE(food.cyberpunk_food_additions, gone)
	food.vis_contents -= gone
	var/obj/item/food/gone_food = gone
	if(istype(gone_food))
		gone_food.vis_flags &= ~VIS_INHERIT_PLANE
		gone_food.pixel_x = gone_food.pixel_w
		gone_food.pixel_y = gone_food.pixel_z
		gone_food.pixel_w = 0
		gone_food.pixel_z = 0
	food.cyberpunk_refresh_added_foodtypes()
	food.cyberpunk_update_quality_effects()

/datum/component/cyberpunk_food_additions/proc/on_parent_qdeleting(datum/source)
	SIGNAL_HANDLER
	var/obj/item/food/food = parent
	for(var/obj/item/food/addition as anything in food.cyberpunk_food_additions)
		qdel(addition)

/datum/component/cyberpunk_food_additions/proc/on_requesting_context_from_item(datum/source, list/context, obj/item/held_item, mob/user)
	SIGNAL_HANDLER
	if(!istype(held_item, /obj/item/food) || !can_add(held_item))
		return NONE
	context[SCREENTIP_CONTEXT_LMB] = "Добавить [held_item]"
	return CONTEXTUAL_SCREENTIP_SET

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
