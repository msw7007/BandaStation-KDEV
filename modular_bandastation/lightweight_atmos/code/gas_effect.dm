/datum/gas_effect
	var/id = "abstract"
	var/name = "gas"
	var/color = "#888888"
	var/icon_state = "cloud"

	var/density_type = GAS_DENSITY_NEUTRAL

	var/spread_threshold = 5
	var/spread_rate = 0.4
	var/decay_rate = 1
	var/temperature_delta = 0

	var/list/filter_tags

	var/visible = TRUE
	var/affects_underwater = FALSE
	var/touch_on_cross = TRUE

	var/alarm_flags = CLOUD_ALARM_NONE
	var/alarm_threshold = LIGHTWEIGHT_ATMOS_ALARM_THRESHOLD

	var/visibility_modifier = 0

	var/scrubbable = TRUE

	var/list/default_chemicals = null

/datum/gas_effect/New()
	. = ..()
	if(!filter_tags)
		filter_tags = list()

/datum/gas_effect/proc/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	return

/datum/gas_effect/proc/on_touch(atom/movable/AM, amount, seconds_per_tick)
	return

/datum/gas_effect/proc/on_decay(turf/T, amount)
	return

/datum/gas_effect/proc/is_filtered_by(list/tags)
	if(!length(tags) || !length(filter_tags))
		return FALSE
	if(GAS_FILTER_ANY in tags)
		return TRUE
	for(var/tag in filter_tags)
		if(!(tag in tags))
			return FALSE
	return TRUE

/datum/gas_effect/proc/apply_chemicals_on_breathe(mob/living/carbon/breather, list/chem_pool, amount, seconds_per_tick)
	if(!length(chem_pool) || !breather?.reagents)
		return
	var/dose_scale = LIGHTWEIGHT_ATMOS_CHEM_BREATH_FRACTION * seconds_per_tick * min(amount, GAS_EFFECT_PER_TICK_MAX) / max(GAS_EFFECT_PER_TICK_MAX, 1)
	for(var/reagent_path in chem_pool)
		var/dose = chem_pool[reagent_path] * dose_scale
		if(dose <= 0)
			continue
		breather.reagents.add_reagent(reagent_path, dose)

/datum/gas_effect/proc/apply_chemicals_on_touch(atom/movable/AM, list/chem_pool, amount, seconds_per_tick)
	if(!length(chem_pool))
		return
	var/mob/living/L = AM
	if(!istype(L) || !L.reagents)
		return
	var/dose_scale = LIGHTWEIGHT_ATMOS_CHEM_TOUCH_FRACTION * seconds_per_tick * min(amount, GAS_EFFECT_PER_TICK_MAX) / max(GAS_EFFECT_PER_TICK_MAX, 1)
	for(var/reagent_path in chem_pool)
		var/dose = chem_pool[reagent_path] * dose_scale
		if(dose <= 0)
			continue
		L.reagents.add_reagent(reagent_path, dose, no_react = TRUE)
	L.reagents.expose(L, TOUCH, 0.5)
