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
