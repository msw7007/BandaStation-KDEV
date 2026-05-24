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
