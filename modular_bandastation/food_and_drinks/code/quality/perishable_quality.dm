/datum/component/perishable
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/decomp_weakref
	var/in_cold_zone = FALSE

/datum/component/perishable/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	var/datum/component/decomposition/decomp = parent.GetComponent(/datum/component/decomposition)
	if(!decomp)
		return COMPONENT_INCOMPATIBLE
	decomp_weakref = WEAKREF(decomp)

/datum/component/perishable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_FOOD_GET_EXTRA_COMPLEXITY, PROC_REF(on_get_complexity))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	apply_cold_state(force = TRUE)

/datum/component/perishable/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_FOOD_GET_EXTRA_COMPLEXITY, COMSIG_ATOM_EXAMINE))

/datum/component/perishable/proc/on_moved(datum/source, atom/old_loc)
	SIGNAL_HANDLER
	apply_cold_state()

/datum/component/perishable/proc/apply_cold_state(force = FALSE)
	var/datum/component/decomposition/decomp = decomp_weakref?.resolve()
	if(!decomp)
		return
	var/now_cold = is_cold_zone(parent)
	if(now_cold == in_cold_zone && !force)
		return
	in_cold_zone = now_cold
	if(in_cold_zone)
		decomp.remove_timer()
	else if(decomp.handled)
		decomp.start_timer()

/datum/component/perishable/proc/get_penalty()
	var/datum/component/decomposition/decomp = decomp_weakref?.resolve()
	if(!decomp || !decomp.original_time)
		return 0
	var/progress = decomp.get_time() / decomp.original_time
	if(progress < PERISH_PROGRESS_GROSS)
		return PERISH_PENALTY_ROTTEN
	if(progress < PERISH_PROGRESS_STALE)
		return PERISH_PENALTY_GROSS
	if(progress < PERISH_PROGRESS_FRESH)
		return PERISH_PENALTY_STALE
	return 0

/datum/component/perishable/proc/on_get_complexity(datum/source, list/extra_complexity)
	SIGNAL_HANDLER
	extra_complexity[1] += get_penalty()

/datum/component/perishable/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(in_cold_zone)
		examine_list += span_notice("В холоде [parent.declent_ru(NOMINATIVE)] не портится.")
		return
	if(get_penalty() < 0)
		var/datum/component/edible/edible = parent.GetComponent(/datum/component/edible)
		if(edible)
			examine_list += span_notice("Категория свежести: [food_quality_5tier(edible.get_recipe_complexity())].")
