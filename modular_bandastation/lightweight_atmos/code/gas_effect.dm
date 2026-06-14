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
	var/tile_capacity = LIGHTWEIGHT_ATMOS_TILE_CAPACITY
	var/pressure_spread_threshold = LIGHTWEIGHT_ATMOS_PRESSURE_SPREAD_THRESHOLD
	var/outdoor_decay_multiplier = LIGHTWEIGHT_ATMOS_OUTDOOR_DECAY_MULTIPLIER
	var/vent_flow_weight = LIGHTWEIGHT_ATMOS_VENT_FLOW_WEIGHT

	var/list/filter_tags

	var/visible = TRUE
	var/affects_underwater = FALSE
	var/touch_on_cross = TRUE

	var/alarm_flags = CLOUD_ALARM_NONE
	var/alarm_threshold = LIGHTWEIGHT_ATMOS_ALARM_THRESHOLD

	var/visibility_modifier = 0

	var/scrubbable = TRUE
	var/pressure_override = null

	var/list/default_chemicals = null

	/// Minimum cloud temperature needed to turn this effect into a fire cloud.
	/// Null means this effect itself is not flammable; chemical clouds can still
	/// ignite from their reagent contents.
	var/ignition_temperature = null
	var/ignition_amount_multiplier = 1

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

/datum/gas_effect/proc/on_process_cloud(obj/effect/gas_cloud/cloud, turf/T, area/A, seconds_per_tick)
	return

/datum/gas_effect/proc/get_ignition_temperature(obj/effect/gas_cloud/cloud)
	. = ignition_temperature
	var/list/chem_pool = cloud?.chemicals || default_chemicals
	if(!length(chem_pool))
		return
	for(var/reagent_path in chem_pool)
		var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_path]
		if(!reagent || isnull(reagent.burning_temperature))
			continue
		if(isnull(.) || reagent.burning_temperature < .)
			. = reagent.burning_temperature

/datum/gas_effect/proc/get_ignition_strength(obj/effect/gas_cloud/cloud)
	. = max(cloud?.amount * ignition_amount_multiplier, 0)
	var/list/chem_pool = cloud?.chemicals || default_chemicals
	if(!length(chem_pool))
		return
	for(var/reagent_path in chem_pool)
		var/datum/reagent/reagent = GLOB.chemical_reagents_list[reagent_path]
		if(!reagent || isnull(reagent.burning_temperature))
			continue
		. += chem_pool[reagent_path] * max(reagent.burning_volume, 0.1)

/datum/gas_effect/proc/try_ignite_cloud(obj/effect/gas_cloud/cloud)
	if(!cloud || cloud.effect != src || istype(src, /datum/gas_effect/fire))
		return FALSE
	var/cloud_ignition_temperature = get_ignition_temperature(cloud)
	if(isnull(cloud_ignition_temperature) || cloud.temperature < cloud_ignition_temperature)
		return FALSE
	var/fire_amount = get_ignition_strength(cloud)
	if(fire_amount <= 0)
		return FALSE
	cloud.amount = max(cloud.amount, min(fire_amount, tile_capacity * 2))
	cloud.chemicals = null
	return cloud.change_effect(/datum/gas_effect/fire)

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
