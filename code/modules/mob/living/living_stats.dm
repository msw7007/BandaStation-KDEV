/mob/living/proc/ensure_cy_stat_holder() as /datum/cy_stat_holder
	if(!cy_stat_holder)
		cy_stat_holder = new(src)

	return cy_stat_holder

/mob/living/proc/get_cy_stat(stat_type, include_modifiers = TRUE)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_stat(stat_type, include_modifiers)

/mob/living/proc/set_cy_base_stat(stat_type, value)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_base_stat(stat_type, value)

/mob/living/proc/set_cy_stat_modifier(stat_type, source, amount)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_stat_modifier(stat_type, source, amount)

/mob/living/proc/clear_cy_stat_modifier(stat_type, source)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.clear_stat_modifier(stat_type, source)
