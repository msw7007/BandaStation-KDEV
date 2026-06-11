/proc/spawn_gas_cloud(turf/T, effect_path, amount = 25, temperature = T20C, list/chemicals = null)
	if(!isturf(T))
		T = get_turf(T)
	if(!isturf(T))
		return null
	if(!ispath(effect_path, /datum/gas_effect))
		stack_trace("spawn_gas_cloud called with non-effect path [effect_path]")
		return null
	var/datum/gas_effect/effect = SSgas_effects.get_effect_singleton(effect_path)
	if(!effect)
		return null
	if(!effect.affects_underwater && is_water_turf(T))
		return null
	if(T.density)
		return null
	var/obj/effect/gas_cloud/existing = locate(/obj/effect/gas_cloud) in T
	if(existing?.can_merge(effect))
		existing.merge(amount, temperature, chemicals)
		return existing
	if(length(SSgas_effects.active_clouds) >= LIGHTWEIGHT_ATMOS_MAX_CLOUDS)
		return null
	return new /obj/effect/gas_cloud(T, effect, amount, temperature, chemicals)

/proc/spawn_gas_cloud_radial(turf/center, effect_path, total_amount = 100, radius = 2, temperature = T20C, list/chemicals = null)
	if(!isturf(center))
		center = get_turf(center)
	if(!isturf(center))
		return
	var/list/tiles = list(center)
	for(var/turf/T in RANGE_TURFS(radius, center))
		if(T == center)
			continue
		if(T.density)
			continue
		if(!cloud_can_pass(center, T))
			continue
		tiles += T
	var/per_tile = total_amount / length(tiles)
	var/list/per_tile_chems = null
	if(length(chemicals))
		per_tile_chems = list()
		for(var/reagent_path in chemicals)
			per_tile_chems[reagent_path] = chemicals[reagent_path] / length(tiles)
	for(var/turf/T in tiles)
		spawn_gas_cloud(T, effect_path, per_tile, temperature, per_tile_chems ? per_tile_chems.Copy() : null)

/proc/spawn_chemical_cloud(turf/T, list/chemicals, amount = 30, temperature = T20C, effect_path = /datum/gas_effect/chemical)
	if(!length(chemicals))
		return null
	return spawn_gas_cloud(T, effect_path, amount, temperature, chemicals)

/proc/clear_gas_clouds(turf/T, effect_path = null)
	for(var/obj/effect/gas_cloud/C in T)
		if(!effect_path || istype(C.effect, effect_path))
			qdel(C)

/proc/dump_gas_mixture_as_cloud(turf/T, datum/gas_mixture/mix, mole_multiplier = 0.2)
	if(!isturf(T))
		T = get_turf(T)
	if(!isturf(T) || !mix)
		return 0
	var/total_moles = 0
	for(var/gas_path in mix.gases)
		total_moles += mix.gases[gas_path][MOLES]
	if(total_moles < 1)
		return 0
	var/list/seen = list()
	var/spawned = 0
	for(var/gas_path in mix.gases)
		var/moles = mix.gases[gas_path][MOLES]
		if(moles < 0.5)
			continue
		var/effect_path = atmos_legacy_gas_path_to_effect(gas_path)
		if(!effect_path)
			effect_path = /datum/gas_effect/smoke
		if(seen[effect_path])
			continue
		seen[effect_path] = TRUE
		var/amount = moles * mole_multiplier
		if(amount < 1)
			continue
		spawn_gas_cloud(T, effect_path, amount, mix.temperature)
		spawned++
	return spawned

/proc/release_gas_mixture_to_lightweight_atmos(turf/T, datum/gas_mixture/source, target_pressure = ONE_ATMOSPHERE, release_rate = 1)
	if(!isturf(T))
		T = get_turf(T)
	if(!isturf(T) || !source)
		return FALSE
	var/total_moles = source.total_moles()
	if(total_moles <= 0)
		return FALSE
	var/pressure_scale = clamp(target_pressure / max(ONE_ATMOSPHERE, 1), 0.05, 4)
	var/moles_to_release = min(total_moles, max(0.1, total_moles * 0.08 * pressure_scale * release_rate))
	var/datum/gas_mixture/removed = source.remove(moles_to_release)
	if(!removed)
		return FALSE
	return dump_gas_mixture_as_cloud(T, removed)

/proc/collect_lightweight_atmos_to_gas_mixture(turf/T, datum/gas_mixture/target, amount = 20, list/filter_gases = null)
	if(!isturf(T))
		T = get_turf(T)
	if(!isturf(T) || !target || amount <= 0)
		return FALSE
	var/transferred = FALSE
	for(var/obj/effect/gas_cloud/cloud in T)
		if(QDELETED(cloud) || !cloud.effect || cloud.amount <= 0)
			continue
		var/gas_path = atmos_gas_effect_to_legacy_gas_path(cloud.effect)
		if(!gas_path)
			continue
		if(length(filter_gases) && !(gas_path in filter_gases))
			continue
		var/cloud_amount = min(cloud.amount, amount)
		if(cloud_amount <= 0)
			continue
		var/old_amount = cloud.amount
		cloud.amount -= cloud_amount
		cloud.shrink_chemicals(cloud.amount, old_amount)
		target.adjust_gas(gas_path, cloud_amount / 0.2)
		transferred = TRUE
		if(cloud.amount <= LIGHTWEIGHT_ATMOS_CLOUD_FLOOR)
			qdel(cloud)
	amount *= 0.2
	var/area/A = T.loc
	if(isarea(A) && (!length(filter_gases) || /datum/gas/oxygen in filter_gases))
		var/taken_o2 = A.consume_oxygen(min(A.oxygen_level, amount * 0.001))
		if(taken_o2 > 0)
			target.adjust_gas(/datum/gas/oxygen, taken_o2 / AREA_AIR_O2_PER_BREATH)
			transferred = TRUE
	if(isarea(A) && (!length(filter_gases) || /datum/gas/carbon_dioxide in filter_gases))
		var/taken_co2 = min(A.co2_level, amount * 0.001)
		if(taken_co2 > 0)
			A.scrub_co2(taken_co2)
			target.adjust_gas(/datum/gas/carbon_dioxide, taken_co2 / AREA_AIR_CO2_PER_BREATH)
			transferred = TRUE
	return transferred

/proc/lightweight_atmos_scan_gasmix(atom/target)
	var/turf/T = get_turf(target)
	if(!T)
		return null
	var/datum/gas_mixture/scan = new /datum/gas_mixture(LIGHTWEIGHT_ATMOS_TILE_CAPACITY)
	scan.temperature = T20C
	var/area/A = T.loc
	if(isarea(A))
		var/total_air_moles = (ONE_ATMOSPHERE * scan.volume) / (R_IDEAL_GAS_EQUATION * scan.temperature)
		var/o2_ratio = clamp(O2STANDARD * A.oxygen_level, 0, 1)
		var/co2_ratio = clamp(A.co2_level * 0.05, 0, 0.5)
		var/n2_ratio = max(0, 1 - o2_ratio - co2_ratio)
		if(o2_ratio > 0)
			scan.adjust_gas(/datum/gas/oxygen, total_air_moles * o2_ratio)
		if(n2_ratio > 0)
			scan.adjust_gas(/datum/gas/nitrogen, total_air_moles * n2_ratio)
		if(co2_ratio > 0)
			scan.adjust_gas(/datum/gas/carbon_dioxide, total_air_moles * co2_ratio)
	for(var/obj/effect/gas_cloud/cloud in T)
		if(QDELETED(cloud) || !cloud.effect)
			continue
		var/gas_path = atmos_gas_effect_to_legacy_gas_path(cloud.effect)
		if(gas_path)
			scan.adjust_gas(gas_path, max(cloud.amount, 0) / 0.2)
		if(cloud.effect.pressure_override != null)
			T.set_lightweight_pressure_hazard(cloud.effect.pressure_override, LIGHTWEIGHT_ATMOS_PRESSURE_HAZARD_EXPIRE)
		scan.temperature = max(scan.temperature, cloud.temperature)
	var/pressure_override = get_lightweight_pressure_override(T)
	if(pressure_override != null)
		var/current_pressure = scan.return_pressure()
		if(current_pressure > 0)
			var/pressure_ratio = pressure_override / current_pressure
			for(var/gas_path in scan.gases)
				scan.gases[gas_path][MOLES] *= pressure_ratio
	return scan

/proc/lightweight_atmos_scan_parser(atom/target, name = "Location Reading")
	return gas_mixture_parser(lightweight_atmos_scan_gasmix(target), name)

/proc/atmos_gas_effect_to_legacy_gas_path(datum/gas_effect/effect)
	if(!effect)
		return null
	switch(effect.type)
		if(/datum/gas_effect/oxygen)
			return /datum/gas/oxygen
		if(/datum/gas_effect/co2)
			return /datum/gas/carbon_dioxide
		if(/datum/gas_effect/n2o)
			return /datum/gas/nitrous_oxide
		if(/datum/gas_effect/plasma)
			return /datum/gas/plasma
		if(/datum/gas_effect/smoke)
			return /datum/gas/water_vapor
		if(/datum/gas_effect/freeze)
			return /datum/gas/freon
		if(/datum/gas_effect/tox, /datum/gas_effect/chemical, /datum/gas_effect/biohazard)
			return /datum/gas/bz
	return null

/proc/atmos_legacy_gas_path_to_effect(datum/gas/gas_path)
	if(!ispath(gas_path, /datum/gas))
		return null
	switch(gas_path)
		if(/datum/gas/oxygen)
			return /datum/gas_effect/oxygen
		if(/datum/gas/plasma)
			return /datum/gas_effect/plasma
		if(/datum/gas/carbon_dioxide)
			return /datum/gas_effect/co2
		if(/datum/gas/nitrous_oxide)
			return /datum/gas_effect/n2o
		if(/datum/gas/water_vapor)
			return /datum/gas_effect/smoke
		if(/datum/gas/freon, /datum/gas/halon)
			return /datum/gas_effect/freeze
		if(/datum/gas/tritium, /datum/gas/miasma, /datum/gas/bz, /datum/gas/healium, /datum/gas/nitrium, /datum/gas/hydrogen)
			return /datum/gas_effect/tox
	return null

/proc/atmos_legacy_gas_id_to_effect(key)
	switch(key)
		if("o2", "oxygen")
			return /datum/gas_effect/oxygen
		if("plasma", "plas", "tox")
			return /datum/gas_effect/plasma
		if("co2", "carbon_dioxide")
			return /datum/gas_effect/co2
		if("n2o", "nitrous_oxide")
			return /datum/gas_effect/n2o
		if("water_vapor", "h2o")
			return /datum/gas_effect/smoke
		if("freon", "frezon", "halon")
			return /datum/gas_effect/freeze
		if("tritium", "miasma", "bz", "healium", "nitrium", "hydrogen")
			return /datum/gas_effect/tox
	return null
