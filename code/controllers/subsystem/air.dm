SUBSYSTEM_DEF(air)
	name = "Atmospherics"
	dependencies = list(
		/datum/controller/subsystem/mapping,
		/datum/controller/subsystem/atoms,
	)
	priority = FIRE_PRIORITY_AIR
	wait = 0.5 SECONDS
	ss_flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/cached_cost = 0

	var/cost_atoms = 0
	var/cost_turfs = 0
	var/cost_hotspots = 0
	var/cost_groups = 0
	var/cost_highpressure = 0
	var/cost_superconductivity = 0
	var/cost_pipenets = 0
	var/cost_atmos_machinery = 0
	var/cost_rebuilds = 0
	var/cost_adjacent = 0

	var/list/excited_groups = list()
	var/list/active_turfs = list()
	var/list/hotspots = list()
	var/list/networks = list()
	var/list/rebuild_queue = list()
	//Subservient to rebuild queue
	var/list/expansion_queue = list()
	/// List of turfs to recalculate adjacent turfs on before processing
	var/list/adjacent_rebuild = list()
	/// A list of machines that will be processed when currentpart == SSAIR_ATMOSMACHINERY. Use SSair.begin_processing_machine and SSair.stop_processing_machine to add and remove machines.
	var/list/obj/machinery/atmos_machinery = list()

	var/list/pipe_init_dirs_cache = list()
	//atmos singletons
	var/list/gas_reactions = list()
	var/list/atmos_gen
	var/list/planetary = list() //Lets cache static planetary mixes
	/// List of gas string -> canonical gas mixture
	var/list/strings_to_mix = list()

	/// Cyberpunk-lite atmos: normal breathable air is assumed; only special gas clouds are simulated.
	var/cy_lite_atmos = TRUE
	/// Cyberpunk-lite zone atmos: tracks non-baseline gases by area/z instead of by tile.
	var/cy_lite_zoned_atmos = TRUE
	var/list/cy_gas_clouds = list()
	var/list/cy_gas_clouds_by_turf = list()
	var/list/cy_atmos_zones = list()
	var/list/cy_atmos_zones_by_key = list()
	var/list/cy_active_atmos_zones = list()
	var/list/cy_zone_link_rebuild_queue = list()
	var/cost_cy_clouds = 0
	var/cost_cy_zones = 0
	var/cost_cy_zone_links = 0
	var/cy_zone_cascade_limit = 64


	//Special functions lists
	var/list/turf/active_super_conductivity = list()
	var/list/turf/open/high_pressure_delta = list()
	var/list/atom_process = list()
	/// Reactions which will contribute to a hotspot's size.
	var/list/hotspot_reactions

	/// A cache of objects that perisists between processing runs when resumed == TRUE. Dangerous, qdel'd objects not cleared from this may cause runtimes on processing.
	var/list/currentrun = list()
	var/currentpart = SSAIR_PIPENETS

	var/map_loading = TRUE
	var/list/queued_for_activation
	var/display_all_groups = FALSE

	var/list/reaction_handbook
	var/list/gas_handbook


/datum/controller/subsystem/air/stat_entry(msg)
	msg += "\n  Cost:{"
	msg += "CL:[round(cost_cy_zone_links,1)]|"
	msg += "CZ:[round(cost_cy_zones,1)]|"
	msg += "LC:[round(cost_cy_clouds,1)]|"
	msg += "AT:[round(cost_turfs,1)]|"
	msg += "HS:[round(cost_hotspots,1)]|"
	msg += "EG:[round(cost_groups,1)]|"
	msg += "HP:[round(cost_highpressure,1)]|"
	msg += "SC:[round(cost_superconductivity,1)]|"
	msg += "PN:[round(cost_pipenets,1)]|"
	msg += "AM:[round(cost_atmos_machinery,1)]|"
	msg += "AO:[round(cost_atoms, 1)]|"
	msg += "RB:[round(cost_rebuilds,1)]|"
	msg += "AJ:[round(cost_adjacent,1)]|"
	msg += "} "
	msg += "\n  Count:{CL:[cy_zone_link_rebuild_queue.len]|CZ:[cy_atmos_zones.len]/[cy_active_atmos_zones.len]|LC:[cy_gas_clouds.len]|AT:[active_turfs.len]|"
	msg += "HS:[hotspots.len]|"
	msg += "EG:[excited_groups.len]|"
	msg += "HP:[high_pressure_delta.len]|"
	msg += "SC:[active_super_conductivity.len]|"
	msg += "PN:[networks.len]|"
	msg += "AM:[atmos_machinery.len]|"
	msg += "AO:[atom_process.len]|"
	msg += "RB:[rebuild_queue.len]|"
	msg += "EP:[expansion_queue.len]|"
	msg += "AJ:[adjacent_rebuild.len]|"
	msg += "AT/MS:[round((cost ? active_turfs.len/cost : 0),0.1)]"
	msg += "}"
	return ..()


/datum/controller/subsystem/air/Initialize()
	map_loading = FALSE
	gas_reactions = init_gas_reactions()
	hotspot_reactions = init_hotspot_reactions()

	if(cy_lite_atmos)
		// Keep gas definitions, machinery datums and analyzer data available, but do not build the full LINDA tile/pipenets simulation.
		setup_atmos_machinery()
		if(cy_lite_zoned_atmos)
			setup_cy_lite_zones()
		atmos_handbooks_init()
		return SS_INIT_SUCCESS

	setup_allturfs()
	setup_atmos_machinery()
	setup_pipenets()
	setup_turf_visuals()
	process_adjacent_rebuild()
	atmos_handbooks_init()
	return SS_INIT_SUCCESS


/datum/controller/subsystem/air/fire(resumed = FALSE)
	var/timer = TICK_USAGE_REAL

	if(cy_lite_atmos)
		cost_adjacent = 0
		if(length(adjacent_rebuild))
			timer = TICK_USAGE_REAL
			process_cy_lite_adjacent_rebuild()
			cost_adjacent = TICK_USAGE_REAL - timer
			if(state != SS_RUNNING)
				return
		if(length(cy_zone_link_rebuild_queue))
			timer = TICK_USAGE_REAL
			process_cy_zone_link_rebuilds()
			cost_cy_zone_links = MC_AVERAGE(cost_cy_zone_links, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))
			if(state != SS_RUNNING)
				return
		timer = TICK_USAGE_REAL
		process_cy_lite_zones(resumed)
		cost_cy_zones = MC_AVERAGE(cost_cy_zones, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))
		if(state != SS_RUNNING)
			return
		timer = TICK_USAGE_REAL
		process_cy_lite_clouds(resumed)
		cost_cy_clouds = MC_AVERAGE(cost_cy_clouds, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))
		return

	//Rebuilds can happen at any time, so this needs to be done outside of the normal system
	cost_rebuilds = 0
	cost_adjacent = 0

	// We need to have a solid setup for turfs before fire, otherwise we'll get massive runtimes and strange behavior
	if(length(adjacent_rebuild))
		timer = TICK_USAGE_REAL
		process_adjacent_rebuild()
		//This does mean that the apperent rebuild costs fluctuate very quickly, this is just the cost of having them always process, no matter what
		cost_adjacent = TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return

	// Every time we fire, we want to make sure pipenets are rebuilt. The game state could have changed between each fire() proc call
	// and anything missing a pipenet can lead to unintended behaviour at worse and various runtimes at best.
	if(length(rebuild_queue) || length(expansion_queue))
		timer = TICK_USAGE_REAL
		process_rebuilds()
		//This does mean that the apperent rebuild costs fluctuate very quickly, this is just the cost of having them always process, no matter what
		cost_rebuilds = TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return

	if(currentpart == SSAIR_PIPENETS || !resumed)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_pipenets(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_pipenets = MC_AVERAGE(cost_pipenets, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_ATMOSMACHINERY

	if(currentpart == SSAIR_ATMOSMACHINERY)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_atmos_machinery(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_atmos_machinery = MC_AVERAGE(cost_atmos_machinery, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_ACTIVETURFS

	if(currentpart == SSAIR_ACTIVETURFS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_active_turfs(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_turfs = MC_AVERAGE(cost_turfs, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_HOTSPOTS

	if(currentpart == SSAIR_HOTSPOTS) //We do this before excited groups to allow breakdowns to be independent of adding turfs while still *mostly preventing mass fires
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_hotspots(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_hotspots = MC_AVERAGE(cost_hotspots, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_EXCITEDGROUPS

	if(currentpart == SSAIR_EXCITEDGROUPS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_excited_groups(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_groups = MC_AVERAGE(cost_groups, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_HIGHPRESSURE

	if(currentpart == SSAIR_HIGHPRESSURE)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_high_pressure_delta(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_highpressure = MC_AVERAGE(cost_highpressure, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_SUPERCONDUCTIVITY

	if(currentpart == SSAIR_SUPERCONDUCTIVITY)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_super_conductivity(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_superconductivity = MC_AVERAGE(cost_superconductivity, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE
		currentpart = SSAIR_PROCESS_ATOMS

	if(currentpart == SSAIR_PROCESS_ATOMS)
		timer = TICK_USAGE_REAL
		if(!resumed)
			cached_cost = 0
		process_atoms(resumed)
		cached_cost += TICK_USAGE_REAL - timer
		if(state != SS_RUNNING)
			return
		cost_atoms = MC_AVERAGE(cost_atoms, TICK_DELTA_TO_MS(cached_cost))
		resumed = FALSE


	currentpart = SSAIR_PIPENETS
	SStgui.update_uis(SSair) //Lightning fast debugging motherfucker

/datum/controller/subsystem/air/Recover()
	excited_groups = SSair.excited_groups
	active_turfs = SSair.active_turfs
	hotspots = SSair.hotspots
	networks = SSair.networks
	rebuild_queue = SSair.rebuild_queue
	expansion_queue = SSair.expansion_queue
	adjacent_rebuild = SSair.adjacent_rebuild
	atmos_machinery = SSair.atmos_machinery
	pipe_init_dirs_cache = SSair.pipe_init_dirs_cache
	gas_reactions = SSair.gas_reactions
	atmos_gen = SSair.atmos_gen
	planetary = SSair.planetary
	active_super_conductivity = SSair.active_super_conductivity
	high_pressure_delta = SSair.high_pressure_delta
	atom_process = SSair.atom_process
	currentrun = SSair.currentrun
	queued_for_activation = SSair.queued_for_activation
	cy_gas_clouds = SSair.cy_gas_clouds
	cy_gas_clouds_by_turf = SSair.cy_gas_clouds_by_turf
	cy_atmos_zones = SSair.cy_atmos_zones
	cy_atmos_zones_by_key = SSair.cy_atmos_zones_by_key
	cy_active_atmos_zones = SSair.cy_active_atmos_zones
	cy_zone_link_rebuild_queue = SSair.cy_zone_link_rebuild_queue


/datum/controller/subsystem/air/proc/cy_zone_key(area/source_area, z_level)
	if(!source_area || !z_level)
		return null
	return "[REF(source_area)]:[z_level]"

/datum/controller/subsystem/air/proc/get_cy_atmos_zone(turf/source_turf)
	if(!cy_lite_zoned_atmos || !source_turf)
		return null
	var/area/source_area = get_area(source_turf)
	if(!source_area)
		return null
	var/key = cy_zone_key(source_area, source_turf.z)
	var/datum/cy_atmos_zone/zone = cy_atmos_zones_by_key[key]
	if(zone)
		return zone
	zone = new /datum/cy_atmos_zone(source_area, source_turf.z)
	cy_atmos_zones += zone
	cy_atmos_zones_by_key[key] = zone
	return zone

/datum/controller/subsystem/air/proc/setup_cy_lite_zones()
	cy_atmos_zones = list()
	cy_atmos_zones_by_key = list()
	cy_active_atmos_zones = list()
	cy_zone_link_rebuild_queue = list()
	for(var/area/source_area as anything in GLOB.areas)
		if(!source_area?.has_contained_turfs())
			continue
		for(var/z_level in 1 to world.maxz)
			var/list/z_turfs = source_area.get_turfs_by_zlevel(z_level)
			if(!length(z_turfs))
				continue
			var/open_count = 0
			for(var/turf/open/open_turf as anything in z_turfs)
				if(open_turf.blocks_air || open_turf.density)
					continue
				open_count++
			if(!open_count)
				continue
			var/datum/cy_atmos_zone/zone = new /datum/cy_atmos_zone(source_area, z_level, open_count)
			cy_atmos_zones += zone
			cy_atmos_zones_by_key[cy_zone_key(source_area, z_level)] = zone
	for(var/datum/cy_atmos_zone/zone as anything in cy_atmos_zones)
		zone.discover_neighbors()
	for(var/datum/cy_atmos_zone/zone as anything in cy_atmos_zones)
		if(zone.needs_cascade())
			activate_cy_atmos_zone(zone)

/datum/controller/subsystem/air/proc/activate_cy_atmos_zone(datum/cy_atmos_zone/zone)
	if(!zone || zone.active)
		return
	zone.active = TRUE
	cy_active_atmos_zones += zone

/datum/controller/subsystem/air/proc/deactivate_cy_atmos_zone(datum/cy_atmos_zone/zone)
	if(!zone || !zone.active)
		return
	zone.active = FALSE
	cy_active_atmos_zones -= zone

/datum/controller/subsystem/air/proc/assume_cy_lite_air(turf/source_turf, datum/gas_mixture/giver)
	if(!source_turf || !giver || !cy_lite_zoned_atmos)
		return FALSE
	var/datum/cy_atmos_zone/zone = get_cy_atmos_zone(source_turf)
	if(!zone)
		return FALSE
	return zone.assume_air(giver)

/datum/controller/subsystem/air/proc/process_cy_lite_zones(resumed = FALSE)
	if(!cy_lite_zoned_atmos)
		return
	if(!resumed)
		currentrun = cy_active_atmos_zones.Copy()
	var/list/run = currentrun
	var/processed = 0
	while(length(run) && processed < cy_zone_cascade_limit)
		var/datum/cy_atmos_zone/zone = run[length(run)]
		run.len--
		if(QDELETED(zone))
			cy_active_atmos_zones -= zone
			continue
		zone.process_zone(wait * 0.1)
		processed++
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_cy_lite_adjacent_rebuild()
	var/list/queue = adjacent_rebuild
	while(length(queue))
		var/turf/currT = queue[1]
		queue.Cut(1, 2)
		if(!currT)
			continue
		currT.immediate_calculate_adjacent_turfs()
		queue_cy_zone_link_rebuild(currT)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/queue_cy_zone_link_rebuild(turf/source_turf)
	if(!cy_lite_zoned_atmos || !source_turf)
		return
	var/datum/cy_atmos_zone/zone = get_cy_atmos_zone(source_turf)
	if(zone)
		cy_zone_link_rebuild_queue[zone] = TRUE
	for(var/turf/nearby as anything in source_turf.atmos_adjacent_turfs)
		var/datum/cy_atmos_zone/nearby_zone = get_cy_atmos_zone(nearby)
		if(nearby_zone)
			cy_zone_link_rebuild_queue[nearby_zone] = TRUE

/datum/controller/subsystem/air/proc/process_cy_zone_link_rebuilds()
	while(length(cy_zone_link_rebuild_queue))
		var/datum/cy_atmos_zone/zone
		for(var/datum/cy_atmos_zone/queued_zone as anything in cy_zone_link_rebuild_queue)
			zone = queued_zone
			break
		cy_zone_link_rebuild_queue -= zone
		if(QDELETED(zone))
			continue
		zone.discover_neighbors()
		if(zone.needs_cascade())
			activate_cy_atmos_zone(zone)
		if(MC_TICK_CHECK)
			return

/datum/cy_atmos_zone
	var/area/source_area
	var/z_level = 1
	var/turf_count = 1
	var/datum/gas_mixture/air
	var/datum/gas_mixture/baseline_air
	var/list/neighbors = list()
	var/active = FALSE
	var/spread_ratio = 0.08
	var/decay_ratio = 0.002
	var/minimum_moles = 0.01

/datum/cy_atmos_zone/New(area/new_area, new_z_level, new_turf_count = 1)
	. = ..()
	source_area = new_area
	z_level = new_z_level
	turf_count = max(new_turf_count, 1)
	air = build_baseline_air()
	baseline_air = air.copy()

/datum/cy_atmos_zone/Destroy()
	if(SSair)
		SSair.deactivate_cy_atmos_zone(src)
	source_area = null
	neighbors = null
	QDEL_NULL(air)
	QDEL_NULL(baseline_air)
	return ..()

/datum/cy_atmos_zone/proc/build_baseline_air()
	var/list/z_turfs = source_area?.get_turfs_by_zlevel(z_level)
	var/datum/gas_mixture/result = new /datum/gas_mixture(CELL_VOLUME)
	var/temperature_total = 0
	var/open_count = 0
	for(var/turf/open/open_turf as anything in z_turfs)
		if(open_turf.blocks_air || open_turf.density)
			continue
		var/datum/gas_mixture/turf_air = open_turf.create_gas_mixture()
		for(var/gas_id in turf_air.gases)
			result.adjust_gas(gas_id, turf_air.gases[gas_id][MOLES])
		temperature_total += turf_air.temperature
		open_count++
	if(!open_count)
		return SSair.parse_gas_string(OPENTURF_DEFAULT_ATMOS, /datum/gas_mixture/turf)
	for(var/gas_id in result.gases)
		result.gases[gas_id][MOLES] /= open_count
	result.temperature = temperature_total / open_count
	result.garbage_collect()
	return result

/datum/cy_atmos_zone/proc/discover_neighbors()
	if(!source_area)
		return
	var/had_effect = has_effect()
	var/datum/gas_mixture/new_baseline = build_baseline_air()
	if(baseline_air)
		baseline_air.copy_from(new_baseline)
	else
		baseline_air = new_baseline
	if(!air)
		air = baseline_air.copy()
	else if(!had_effect)
		air.copy_from(baseline_air)
	neighbors = list()
	var/list/z_turfs = source_area.get_turfs_by_zlevel(z_level)
	var/open_count = 0
	for(var/turf/open/open_turf as anything in z_turfs)
		if(open_turf.blocks_air || open_turf.density)
			continue
		open_count++
		open_turf.immediate_calculate_adjacent_turfs()
		for(var/turf/open/nearby as anything in open_turf.atmos_adjacent_turfs)
			var/datum/cy_atmos_zone/neighbor = SSair.get_cy_atmos_zone(nearby)
			if(neighbor && neighbor != src)
				neighbors |= neighbor
	turf_count = max(open_count, 1)

/datum/cy_atmos_zone/proc/assume_air(datum/gas_mixture/giver)
	if(!giver || !air)
		return FALSE
	var/list/giver_gases = giver.gases
	for(var/gas_id in giver_gases)
		var/moles = giver_gases[gas_id][MOLES]
		if(moles)
			air.adjust_gas(gas_id, moles / turf_count)
	if(abs(giver.temperature - air.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		air.temperature = (air.temperature + giver.temperature) * 0.5
	if(has_effect())
		SSair.activate_cy_atmos_zone(src)
	return TRUE

/datum/cy_atmos_zone/proc/remove_air(amount)
	if(!air)
		return null
	var/datum/gas_mixture/sample = air.copy()
	var/datum/gas_mixture/removed = sample.remove(amount)
	if(!removed)
		return null
	for(var/gas_id in removed.gases)
		air.adjust_gas(gas_id, -(removed.gases[gas_id][MOLES] / turf_count))
	air.garbage_collect()
	if(has_effect())
		SSair.activate_cy_atmos_zone(src)
	return removed

/datum/cy_atmos_zone/proc/has_effect()
	if(!air || !baseline_air)
		return FALSE
	if(abs(air.temperature - baseline_air.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		return TRUE
	var/list/all_gases = air.gases | baseline_air.gases
	for(var/gas_id in all_gases)
		air.assert_gas(gas_id)
		baseline_air.assert_gas(gas_id)
		if(abs(air.gases[gas_id][MOLES] - baseline_air.gases[gas_id][MOLES]) > minimum_moles)
			return TRUE
	air.garbage_collect()
	baseline_air.garbage_collect()
	return FALSE

/datum/cy_atmos_zone/proc/needs_cascade()
	if(!length(neighbors) || !air)
		return FALSE
	for(var/datum/cy_atmos_zone/neighbor as anything in neighbors)
		if(QDELETED(neighbor) || !neighbor.air)
			continue
		if(abs(air.temperature - neighbor.air.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			return TRUE
		var/list/all_gases = air.gases | neighbor.air.gases
		for(var/gas_id in all_gases)
			air.assert_gas(gas_id)
			neighbor.air.assert_gas(gas_id)
			if(abs(air.gases[gas_id][MOLES] - neighbor.air.gases[gas_id][MOLES]) > minimum_moles)
				return TRUE
		air.garbage_collect()
		neighbor.air.garbage_collect()
	return FALSE

/datum/cy_atmos_zone/proc/process_zone(seconds_per_tick)
	if(!has_effect() && !needs_cascade())
		SSair.deactivate_cy_atmos_zone(src)
		return
	decay(seconds_per_tick)
	cascade()
	if(!has_effect() && !needs_cascade())
		SSair.deactivate_cy_atmos_zone(src)

/datum/cy_atmos_zone/proc/decay(seconds_per_tick)
	if(!baseline_air || !air)
		return
	var/ratio = min(decay_ratio * max(seconds_per_tick, 1), 1)
	var/list/all_gases = air.gases | baseline_air.gases
	for(var/gas_id in all_gases)
		air.assert_gas(gas_id)
		baseline_air.assert_gas(gas_id)
		air.gases[gas_id][MOLES] += (baseline_air.gases[gas_id][MOLES] - air.gases[gas_id][MOLES]) * ratio
	air.garbage_collect()
	baseline_air.garbage_collect()
	if(abs(air.temperature - baseline_air.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		air.temperature += (baseline_air.temperature - air.temperature) * min(ratio * 4, 1)

/datum/cy_atmos_zone/proc/cascade()
	if(!length(neighbors))
		return
	for(var/datum/cy_atmos_zone/neighbor as anything in neighbors)
		if(QDELETED(neighbor))
			neighbors -= neighbor
			continue
		share_with(neighbor)

/datum/cy_atmos_zone/proc/share_with(datum/cy_atmos_zone/neighbor)
	var/moved = FALSE
	var/list/all_gases = air.gases | neighbor.air.gases
	for(var/gas_id in all_gases)
		air.assert_gas(gas_id)
		neighbor.air.assert_gas(gas_id)
		var/our_moles = air.gases[gas_id][MOLES]
		var/their_moles = neighbor.air.gases[gas_id][MOLES]
		var/delta = (our_moles - their_moles) * spread_ratio
		if(abs(delta) <= minimum_moles)
			continue
		air.gases[gas_id][MOLES] -= delta
		neighbor.air.gases[gas_id][MOLES] += delta
		moved = TRUE
	air.garbage_collect()
	neighbor.air.garbage_collect()
	if(abs(air.temperature - neighbor.air.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/temp_delta = (air.temperature - neighbor.air.temperature) * spread_ratio
		air.temperature -= temp_delta
		neighbor.air.temperature += temp_delta
		moved = TRUE
	if(moved && neighbor.has_effect())
		SSair.activate_cy_atmos_zone(neighbor)


/datum/controller/subsystem/air/proc/register_cy_gas_cloud(datum/cy_gas_cloud/cloud)
	if(!cloud)
		return
	cy_gas_clouds |= cloud

/datum/controller/subsystem/air/proc/unregister_cy_gas_cloud(datum/cy_gas_cloud/cloud)
	if(!cloud)
		return
	cy_gas_clouds -= cloud
	for(var/turf/T as anything in cloud.turf_contents)
		unregister_cy_gas_cloud_from_turf(cloud, T)

/datum/controller/subsystem/air/proc/register_cy_gas_cloud_on_turf(datum/cy_gas_cloud/cloud, turf/T)
	if(!cloud || !T)
		return
	var/list/clouds = cy_gas_clouds_by_turf[T]
	if(!clouds)
		clouds = list()
		cy_gas_clouds_by_turf[T] = clouds
	clouds |= cloud

/datum/controller/subsystem/air/proc/unregister_cy_gas_cloud_from_turf(datum/cy_gas_cloud/cloud, turf/T)
	if(!cloud || !T)
		return
	var/list/clouds = cy_gas_clouds_by_turf[T]
	if(!clouds)
		return
	clouds -= cloud
	if(!length(clouds))
		cy_gas_clouds_by_turf.Remove(T)

/datum/controller/subsystem/air/proc/create_cy_gas_cloud(turf/origin, gas_id, amount = 1, density = 0, pressure = 1, temperature = T20C, spread_threshold = 0.25, decay_rate = 0.03)
	if(!origin || !gas_id || amount <= 0)
		return null
	return new /datum/cy_gas_cloud(origin, gas_id, amount, density, pressure, temperature, spread_threshold, decay_rate)

/datum/controller/subsystem/air/proc/get_cy_lite_air(turf/source_turf)
	var/datum/cy_atmos_zone/zone = get_cy_atmos_zone(source_turf)
	if(zone?.air)
		return zone.air
	return source_turf.create_gas_mixture()

/datum/controller/subsystem/air/proc/get_cy_lite_analyzable_air(turf/source_turf)
	var/datum/cy_atmos_zone/zone = get_cy_atmos_zone(source_turf)
	var/datum/gas_mixture/air_sample = zone?.air ? zone.air.copy() : source_turf.create_gas_mixture()
	var/list/clouds = cy_gas_clouds_by_turf[source_turf]
	if(length(clouds))
		for(var/datum/cy_gas_cloud/cloud as anything in clouds)
			cloud.add_to_breath(source_turf, air_sample)
	air_sample.garbage_collect()
	return air_sample

/datum/controller/subsystem/air/proc/get_cy_lite_breath(turf/source_turf, amount)
	var/datum/cy_atmos_zone/zone = get_cy_atmos_zone(source_turf)
	var/datum/gas_mixture/breath = zone?.remove_air(amount)
	if(!breath)
		var/datum/gas_mixture/background = source_turf.create_gas_mixture()
		breath = background.remove(amount)
	var/list/clouds = cy_gas_clouds_by_turf[source_turf]
	if(!length(clouds))
		return breath
	for(var/datum/cy_gas_cloud/cloud as anything in clouds)
		cloud.add_to_breath(source_turf, breath)
	breath.garbage_collect()
	return breath

/datum/controller/subsystem/air/proc/process_cy_lite_clouds(resumed = FALSE)
	if(!resumed)
		currentrun = cy_gas_clouds.Copy()
	var/list/run = currentrun
	while(length(run))
		var/datum/cy_gas_cloud/cloud = run[length(run)]
		run.len--
		if(QDELETED(cloud))
			cy_gas_clouds -= cloud
			continue
		cloud.process(wait * 0.1)
		if(MC_TICK_CHECK)
			return

/datum/cy_gas_cloud
	var/gas_id = /datum/gas/plasma
	var/list/turf_contents = list()
	var/density = 0
	var/pressure = 1
	var/temperature = T20C
	var/spread_threshold = 0.25
	var/decay_rate = 0.03
	var/breath_ratio = 0.08

/datum/cy_gas_cloud/New(turf/origin, new_gas_id, amount = 1, new_density = 0, new_pressure = 1, new_temperature = T20C, new_spread_threshold = 0.25, new_decay_rate = 0.03)
	. = ..()
	gas_id = new_gas_id
	density = new_density
	pressure = max(new_pressure, 0)
	temperature = max(new_temperature, TCMB)
	spread_threshold = max(new_spread_threshold, 0)
	decay_rate = max(new_decay_rate, 0)
	set_turf_amount(origin, amount)
	SSair.register_cy_gas_cloud(src)

/datum/cy_gas_cloud/Destroy()
	SSair.unregister_cy_gas_cloud(src)
	turf_contents = null
	return ..()

/datum/cy_gas_cloud/proc/get_turf_amount(turf/T)
	if(!turf_contents || !T)
		return 0
	return turf_contents[T] || 0

/datum/cy_gas_cloud/proc/set_turf_amount(turf/T, amount)
	if(!T)
		return
	if(amount <= 0)
		remove_turf(T)
		return
	if(!turf_contents[T])
		SSair.register_cy_gas_cloud_on_turf(src, T)
	turf_contents[T] = amount

/datum/cy_gas_cloud/proc/remove_turf(turf/T)
	if(!T || !turf_contents || !turf_contents[T])
		return
	turf_contents.Remove(T)
	SSair.unregister_cy_gas_cloud_from_turf(src, T)

/datum/cy_gas_cloud/proc/can_spread(turf/from_turf, turf/to_turf)
	if(!from_turf || !to_turf || to_turf.density)
		return FALSE
	if(islava(to_turf))
		return FALSE
	return TRUE

/datum/cy_gas_cloud/process(seconds_per_tick)
	if(!length(turf_contents))
		qdel(src)
		return
	var/list/pending_add = list()
	var/list/pending_remove = list()
	for(var/turf/T as anything in turf_contents.Copy())
		var/content = get_turf_amount(T)
		content = max(0, content - decay_rate * max(seconds_per_tick, 1))
		if(content <= 0.01)
			pending_remove += T
			continue
		if(content >= spread_threshold && pressure > 0)
			var/share = min(content * 0.20 * pressure, content * 0.5)
			var/list/spread_targets = list()
			for(var/dir in GLOB.cardinals)
				var/turf/target = get_step(T, dir)
				if(can_spread(T, target))
					spread_targets += target
			if(density)
				var/turf/vertical = locate(T.x, T.y, T.z + (density > 0 ? -1 : 1))
				if(can_spread(T, vertical))
					spread_targets += vertical
			if(length(spread_targets))
				var/share_each = share / length(spread_targets)
				content -= share
				for(var/turf/spread_turf as anything in spread_targets)
					pending_add[spread_turf] = (pending_add[spread_turf] || 0) + share_each
			turf_contents[T] = content
	for(var/turf/remove_turf as anything in pending_remove)
		remove_turf(remove_turf)
	for(var/turf/add_turf as anything in pending_add)
		set_turf_amount(add_turf, get_turf_amount(add_turf) + pending_add[add_turf])
	if(!length(turf_contents))
		qdel(src)

/datum/cy_gas_cloud/proc/add_to_breath(turf/T, datum/gas_mixture/breath)
	if(!T || !breath)
		return
	var/content = get_turf_amount(T)
	if(content <= 0)
		return
	breath.adjust_gas(gas_id, max(0.01, content * breath_ratio))
	if(abs(breath.temperature - temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		breath.temperature = (breath.temperature + temperature) * 0.5

/datum/controller/subsystem/air/proc/process_adjacent_rebuild(init = FALSE)
	var/list/queue = adjacent_rebuild

	while (length(queue))
		var/turf/currT = queue[1]
		var/goal = queue[currT]
		queue.Cut(1,2)

		currT.immediate_calculate_adjacent_turfs()
		if(goal == MAKE_ACTIVE)
			add_to_active(currT)
		else if(goal == KILL_EXCITED)
			add_to_active(currT, TRUE)

		if(init)
			CHECK_TICK
		else
			if(MC_TICK_CHECK)
				break

/datum/controller/subsystem/air/proc/process_pipenets(resumed = FALSE)
	if (!resumed)
		src.currentrun = networks.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/datum/thing = currentrun[currentrun.len]
		currentrun.len--
		if(thing)
			thing.process()
		else
			networks.Remove(thing)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/add_to_rebuild_queue(obj/machinery/atmospherics/atmos_machine)
	if(istype(atmos_machine, /obj/machinery/atmospherics) && !atmos_machine.rebuilding)
		rebuild_queue += atmos_machine
		atmos_machine.rebuilding = TRUE

/datum/controller/subsystem/air/proc/add_to_expansion(datum/pipeline/line, starting_point)
	var/list/new_packet = new(SSAIR_REBUILD_QUEUE)
	new_packet[SSAIR_REBUILD_PIPELINE] = line
	new_packet[SSAIR_REBUILD_QUEUE] = list(starting_point)
	expansion_queue += list(new_packet)

/datum/controller/subsystem/air/proc/remove_from_expansion(datum/pipeline/line)
	for(var/list/packet in expansion_queue)
		if(packet[SSAIR_REBUILD_PIPELINE] == line)
			expansion_queue -= packet
			return

/datum/controller/subsystem/air/proc/process_atoms(resumed = FALSE)
	if(!resumed)
		src.currentrun = atom_process.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/atom/talk_to = currentrun[currentrun.len]
		currentrun.len--
		if(!talk_to)
			return
		talk_to.process_exposure()
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_atmos_machinery(resumed = FALSE)
	if (!resumed)
		src.currentrun = atmos_machinery.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/obj/machinery/M = currentrun[currentrun.len]
		currentrun.len--
		if(!M)
			atmos_machinery -= M
		if(M.process_atmos(wait * 0.1) == PROCESS_KILL)
			stop_processing_machine(M)
		if(MC_TICK_CHECK)
			return


/datum/controller/subsystem/air/proc/process_super_conductivity(resumed = FALSE)
	if (!resumed)
		src.currentrun = active_super_conductivity.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/turf/T = currentrun[currentrun.len]
		currentrun.len--
		T.super_conduct()
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_hotspots(resumed = FALSE)
	if (!resumed)
		src.currentrun = hotspots.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/obj/effect/hotspot/H = currentrun[currentrun.len]
		currentrun.len--
		if (H)
			H.process()
		else
			hotspots -= H
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_high_pressure_delta(resumed = FALSE)
	while (high_pressure_delta.len)
		var/turf/open/T = high_pressure_delta[high_pressure_delta.len]
		high_pressure_delta.len--
		T.high_pressure_movements()
		T.pressure_difference = 0
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_active_turfs(resumed = FALSE)
	//cache for sanic speed
	var/fire_count = times_fired
	if (!resumed)
		src.currentrun = active_turfs.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/turf/open/T = currentrun[currentrun.len]
		currentrun.len--
		if (T)
			T.process_cell(fire_count)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_excited_groups(resumed = FALSE)
	if (!resumed)
		src.currentrun = excited_groups.Copy()
	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	while(currentrun.len)
		var/datum/excited_group/EG = currentrun[currentrun.len]
		currentrun.len--
		var/volatile_reaction = EG.turf_reactions & VOLATILE_REACTION
		EG.breakdown_cooldown++
		if(!volatile_reaction)
			EG.dismantle_cooldown++
		if(EG.breakdown_cooldown >= EXCITED_GROUP_BREAKDOWN_CYCLES && !volatile_reaction)
			EG.self_breakdown(poke_turfs = TRUE)
		else if(EG.dismantle_cooldown >= EXCITED_GROUP_DISMANTLE_CYCLES && !(EG.turf_reactions & (REACTING | STOP_REACTIONS)))
			EG.dismantle()
		EG.turf_reactions = NONE
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/air/proc/process_rebuilds()
	//Yes this does mean rebuilding pipenets can freeze up the subsystem forever, but if we're in that situation something else is very wrong
	var/list/currentrun = rebuild_queue
	while(currentrun.len || length(expansion_queue))
		while(currentrun.len && !length(expansion_queue)) //If we found anything, process that first
			var/obj/machinery/atmospherics/remake = currentrun[currentrun.len]
			currentrun.len--
			if (!remake)
				continue
			remake.rebuild_pipes()
			if (MC_TICK_CHECK)
				return

		var/list/queue = expansion_queue
		while(queue.len)
			var/list/pack = queue[queue.len]
			//We operate directly with the pipeline like this because we can trust any rebuilds to remake it properly
			var/datum/pipeline/linepipe = pack[SSAIR_REBUILD_PIPELINE]
			var/list/border = pack[SSAIR_REBUILD_QUEUE]
			expand_pipeline(linepipe, border)
			if(state != SS_RUNNING) //expand_pipeline can fail a tick check, we shouldn't let things get too fucky here
				return

			linepipe.building = FALSE
			queue.len--
			if (MC_TICK_CHECK)
				return

///Rebuilds a pipeline by expanding outwards, while yielding when sane
/datum/controller/subsystem/air/proc/expand_pipeline(datum/pipeline/net, list/border)
	while(border.len)
		var/obj/machinery/atmospherics/borderline = border[border.len]
		border.len--

		var/list/result = borderline.pipeline_expansion(net)
		if(!length(result))
			continue
		for(var/obj/machinery/atmospherics/considered_device in result)
			if(!istype(considered_device, /obj/machinery/atmospherics/pipe))
				considered_device.set_pipenet(net, borderline)
				net.add_machinery_member(considered_device)
				continue
			var/obj/machinery/atmospherics/pipe/item = considered_device
			if(net.members.Find(item))
				continue
			if(item.parent)
				var/static/pipenetwarnings = 10
				if(pipenetwarnings > 0)
					log_mapping("build_pipeline(): [item.type] added to a pipenet while still having one. (pipes leading to the same spot stacking in one turf) around [AREACOORD(item)].")
					pipenetwarnings--
					if(pipenetwarnings == 0)
						log_mapping("build_pipeline(): further messages about pipenets will be suppressed")

			net.members += item
			border += item

			net.air.volume += item.volume
			item.replace_pipenet(item.parent, net)

			if(item.air_temporary)
				net.air.merge(item.air_temporary)
				item.air_temporary = null

		if (MC_TICK_CHECK)
			return

///Removes a turf from processing, and causes its excited group to clean up so things properly adapt to the change
/datum/controller/subsystem/air/proc/remove_from_active(turf/open/T)
	active_turfs -= T
	if(currentpart == SSAIR_ACTIVETURFS)
		currentrun -= T
	#ifdef VISUALIZE_ACTIVE_TURFS //Use this when you want details about how the turfs are moving, display_all_groups should work for normal operation
	T.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_VIBRANT_LIME)
	#endif
	if(istype(T))
		T.excited = FALSE
		if(T.excited_group)
			//If this fires during active turfs it'll cause a slight removal of active turfs, as they breakdown if they have no excited group
			//The group also expands by a tile per rebuild on each edge, suffering
			T.excited_group.garbage_collect() //Kill the excited group, it'll reform on its own later

///Puts an active turf to sleep so it doesn't process. Do this without cleaning up its excited group.
/datum/controller/subsystem/air/proc/sleep_active_turf(turf/open/T)
	active_turfs -= T
	if(currentpart == SSAIR_ACTIVETURFS)
		currentrun -= T
	#ifdef VISUALIZE_ACTIVE_TURFS
	T.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_VIBRANT_LIME)
	#endif
	if(istype(T))
		T.excited = FALSE

///Adds a turf to active processing, handles duplicates. Call this with blockchanges == TRUE if you want to nuke the assoc excited group
/datum/controller/subsystem/air/proc/add_to_active(turf/open/activate, blockchanges = FALSE)
	if(istype(activate) && activate.air)
		activate.significant_share_ticker = 0
		if(blockchanges && activate.excited_group) //This is used almost exclusivly for shuttles, so the excited group doesn't stay behind
			activate.excited_group.garbage_collect() //Nuke it
		if(activate.excited) //Don't keep doing it if there's no point
			return
		#ifdef VISUALIZE_ACTIVE_TURFS
		activate.add_atom_colour(COLOR_VIBRANT_LIME, TEMPORARY_COLOUR_PRIORITY)
		#endif
		activate.excited = TRUE
		active_turfs += activate
	else if(activate.flags_1 & INITIALIZED_1)
		for(var/turf/neighbor as anything in activate.atmos_adjacent_turfs)
			add_to_active(neighbor, TRUE)
	else if(map_loading)
		if(queued_for_activation)
			queued_for_activation[activate] = activate
	else
		activate.requires_activation = TRUE

/datum/controller/subsystem/air/StartLoadingMap()
	LAZYINITLIST(queued_for_activation)
	map_loading = TRUE

/datum/controller/subsystem/air/StopLoadingMap()
	map_loading = FALSE
	for(var/T in queued_for_activation)
		add_to_active(T, TRUE)
	queued_for_activation.Cut()

/datum/controller/subsystem/air/proc/setup_allturfs()
	var/list/active_turfs = src.active_turfs
	times_fired++

	// Clear active turfs - faster than removing every single turf in the world
	// one-by-one, and Initalize_Atmos only ever adds `src` back in.
	#ifdef VISUALIZE_ACTIVE_TURFS
	for(var/jumpy in active_turfs)
		var/turf/active = jumpy
		active.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_VIBRANT_LIME)
	#endif
	active_turfs.Cut()
	// We compare this against turf.current cycle using <= to ensure O(n)
	// It defaults to 0, so we start at -1
	var/time = -1

	var/list/turf/open/difference_check = list()
	for(var/turf/setup as anything in ALL_TURFS())
		if (!setup.init_air)
			continue
		// We pass the tick as the current step so if we sleep the step changes
		// This way we can make setting up adjacent turfs O(n) rather then O(n^2)
		setup.Initalize_Atmos(time)
		// We assert that we'll only get open turfs here
		difference_check += setup
		if(CHECK_TICK)
			time--

	// Now we're gonna compare for differences
	// Taking advantage of current cycle being set to negative before this run to do A->B B->A prevention
	for(var/turf/open/potential_diff as anything in difference_check)
		// I can't use 0 here, so we're gonna do this instead. If it ever breaks I'll eat my shoe
		potential_diff.current_cycle = -INFINITY
		for(var/turf/open/enemy_tile as anything in potential_diff.atmos_adjacent_turfs)
			// If it's already been processed, then it's already talked to us
			if(enemy_tile.current_cycle == -INFINITY)
				continue
			// .air instead of .return_air() because we can guarantee that the proc won't do anything
			if(potential_diff.air.compare(enemy_tile.air, MOLES))
				//testing("Active turf found. Return value of compare(): [T.air.compare(enemy_tile.air, MOLES)]")
				if(!potential_diff.excited)
					potential_diff.excited = TRUE
					SSair.active_turfs += potential_diff
				if(!enemy_tile.excited)
					enemy_tile.excited = TRUE
					SSair.active_turfs += enemy_tile
				// No sense continuing to iterate
				break
		CHECK_TICK

	if(active_turfs.len)
		var/starting_ats = active_turfs.len
		sleep(world.tick_lag)
		var/timer = world.timeofday

		log_mapping("There are [starting_ats] active turfs at roundstart caused by a difference of the air between the adjacent turfs. \
		To locate these active turfs, go into the \"Debug\" tab of your stat-panel. Then hit the verb that says \"Mapping Verbs - Enable\". \
		Now, you can see all of the associated coordinates using \"Mapping -> Show roundstart AT list\" verb.")

		for(var/turf/T in active_turfs)
			GLOB.active_turfs_startlist += T

		//now lets clear out these active turfs
		var/list/turfs_to_check = active_turfs.Copy()
		do
			var/list/new_turfs_to_check = list()
			for(var/turf/open/T in turfs_to_check)
				new_turfs_to_check += T.resolve_active_graph()
			CHECK_TICK

			active_turfs += new_turfs_to_check
			turfs_to_check = new_turfs_to_check
		while (turfs_to_check.len)

		var/ending_ats = active_turfs.len
		for(var/thing in excited_groups)
			var/datum/excited_group/EG = thing
			EG.self_breakdown(roundstart = TRUE)
			EG.dismantle()
			CHECK_TICK

		log_active_turfs() // invoke this here so we can count the time it takes to run this proc as "wasted time", quite simple honestly.

		var/msg = "HEY! LISTEN! [DisplayTimeText(world.timeofday - timer, 0.00001)] were wasted processing [starting_ats] turf(s) (connected to [ending_ats - starting_ats] other turfs) with atmos differences at round start."
		to_chat(world, span_boldannounce("[msg]"))
		warning(msg)

/// Logs all active turfs at roundstart to the mapping log so it can be readily accessed.
/datum/controller/subsystem/air/proc/log_active_turfs()
// sadly this has to be here because we can't realistically expect that all active turfs will be resolved in every possible situation when running through CI.
// In an ideal world, we would have absolutely zero active turfs 99.99% of the time, but that's not the case. `log_mapping()` during world initialize triggers a CI fail.
#ifdef UNIT_TESTS
	return
#else
	// Associated lists, left-hand-side is the z-level or z-trait, right-hand-side is the number of active turfs associated with that.
	var/list/tally_by_level = list()
	// Discriminate for certain z-traits, stuff like "Linkage" is not helpful.
	var/list/tally_by_level_trait = list(
		ZTRAIT_AWAY = 0,
		ZTRAIT_CENTCOM = 0,
		ZTRAIT_ICE_RUINS = 0,
		ZTRAIT_ICE_RUINS_UNDERGROUND  = 0,
		ZTRAIT_ISOLATED_RUINS = 0,
		ZTRAIT_LAVA_RUINS = 0,
		ZTRAIT_MINING = 0,
		ZTRAIT_RESERVED = 0,
		ZTRAIT_SPACE_RUINS = 0,
		ZTRAIT_STATION = 0,
	)

	var/list/message_to_log = list()

	message_to_log += "\nAll that follows is a turf with an active air difference at roundstart. To clear this, make sure that all of the turfs listed below are connected to a turf with the same air contents.\n\
		In an ideal world, this list should have enough information to help you locate the active turf(s) in question. Unfortunately, this might not be an ideal world.\n\
		If the round is still ongoing, you can use the \"Mapping -> Show roundstart AT list\" verb to see exactly what active turfs were detected. Otherwise, good luck."

	for(var/turf/active_turf as anything in GLOB.active_turfs_startlist)
		var/turf_z = active_turf.z
		var/datum/space_level/level = SSmapping.z_list[turf_z]
		var/list/level_traits = list()
		for(var/trait in level.traits)
			if(!isnull(tally_by_level_trait[trait]))
				level_traits += trait
				tally_by_level_trait[trait]++

		// so we can pass along the area type for the log, making it much easier to locate the active turf for a mapper assuming all area types are unique. This is only really a problem for stuff like ruin areas.
		var/area/turf_area = get_area(active_turf)
		message_to_log += "Active turf: [AREACOORD(active_turf)] ([turf_area.type]). Turf type: [active_turf.type]. Relevant Z-Trait(s): [english_list(level_traits)]."

		tally_by_level["[turf_z]"]++

	// Following is so we can detect which rounds were "problematic" as far as active turfs go.
	SSblackbox.record_feedback("amount", "overall_roundstart_active_turfs", length(GLOB.active_turfs_startlist))

	for(var/z_level in tally_by_level)
		var/level_turf_count = tally_by_level[z_level]
		if(level_turf_count == 0) // no point logging it
			continue
		message_to_log += "Z-Level [z_level] has [level_turf_count] active turf(s)."
		SSblackbox.record_feedback("tally", "roundstart_active_turfs_per_z", level_turf_count, z_level)

	for(var/z_trait in tally_by_level_trait)
		var/trait_turf_count = tally_by_level_trait[z_trait]
		if(trait_turf_count == 0)
			continue
		message_to_log += "Z-Level trait [z_trait] has [trait_turf_count] active turf(s)."
		SSblackbox.record_feedback("amount", "roundstart_active_turfs_for_trait_[z_trait]", trait_turf_count)

	message_to_log += "End of active turf list."
	log_mapping(message_to_log.Join("\n"))
#endif

/turf/open/proc/resolve_active_graph()
	. = list()
	var/datum/excited_group/EG = excited_group
	if (blocks_air || !air)
		return
	if (!EG)
		EG = new
		EG.add_turf(src)

	for (var/turf/open/ET in atmos_adjacent_turfs)
		if (ET.blocks_air || !ET.air)
			continue

		var/ET_EG = ET.excited_group
		if (ET_EG)
			if (ET_EG != EG)
				EG.merge_groups(ET_EG)
				EG = excited_group //merge_groups() may decide to replace our current EG
		else
			EG.add_turf(ET)
		if (!ET.excited)
			ET.excited = TRUE
			. += ET

/turf/open/space/resolve_active_graph()
	return list()

/datum/controller/subsystem/air/proc/setup_atmos_machinery()
	for (var/obj/machinery/atmospherics/AM in atmos_machinery)
		AM.atmos_init()
		CHECK_TICK

//this can't be done with setup_atmos_machinery() because
// all atmos machinery has to initialize before the first
// pipenet can be built.
/datum/controller/subsystem/air/proc/setup_pipenets()
	for (var/obj/machinery/atmospherics/AM in atmos_machinery)
		var/list/targets = AM.get_rebuild_targets()
		for(var/datum/pipeline/build_off as anything in targets)
			build_off.build_pipeline_blocking(AM)
		CHECK_TICK

GLOBAL_LIST_EMPTY(colored_turfs)
GLOBAL_LIST_EMPTY(colored_images)
/datum/controller/subsystem/air/proc/setup_turf_visuals()
	for(var/sharp_color in GLOB.contrast_colors)
		var/list/add_to = list()
		GLOB.colored_turfs += list(add_to)
		for(var/offset in 0 to SSmapping.max_plane_offset)
			var/obj/effect/overlay/atmos_excited/suger_high = new()
			SET_PLANE_W_SCALAR(suger_high, HIGH_GAME_PLANE, offset)
			add_to += suger_high
			var/image/shiny = new('icons/effects/effects.dmi', suger_high, "atmos_top")
			SET_PLANE_W_SCALAR(shiny, HIGH_GAME_PLANE, offset)
			shiny.color = sharp_color
			GLOB.colored_images += shiny

/datum/controller/subsystem/air/proc/setup_template_machinery(list/atmos_machines)
	var/obj/machinery/atmospherics/AM
	for(var/A in 1 to atmos_machines.len)
		AM = atmos_machines[A]
		AM.atmos_init()
		CHECK_TICK

	for(var/A in 1 to atmos_machines.len)
		AM = atmos_machines[A]
		var/list/targets = AM.get_rebuild_targets()
		for(var/datum/pipeline/build_off as anything in targets)
			build_off.build_pipeline_blocking(AM)
		CHECK_TICK


/datum/controller/subsystem/air/proc/get_init_dirs(type, dir, init_dir)

	if(!pipe_init_dirs_cache[type])
		pipe_init_dirs_cache[type] = list()

	if(!pipe_init_dirs_cache[type]["[init_dir]"])
		pipe_init_dirs_cache[type]["[init_dir]"] = list()

	if(!pipe_init_dirs_cache[type]["[init_dir]"]["[dir]"])
		var/obj/machinery/atmospherics/temp = new type(null, FALSE, dir, init_dir)
		pipe_init_dirs_cache[type]["[init_dir]"]["[dir]"] = temp.get_init_directions()
		qdel(temp)

	return pipe_init_dirs_cache[type]["[init_dir]"]["[dir]"]

/datum/controller/subsystem/air/proc/generate_atmos()
	atmos_gen = list()
	for(var/T in subtypesof(/datum/atmosphere))
		var/datum/atmosphere/atmostype = T
		atmos_gen[initial(atmostype.id)] = new atmostype

/// Takes a gas string, returns the matching mutable gas_mixture
/datum/controller/subsystem/air/proc/parse_gas_string(gas_string, gastype = /datum/gas_mixture)
	var/datum/gas_mixture/cached = strings_to_mix["[gas_string]-[gastype]"]

	if(cached)
		if(istype(cached, /datum/gas_mixture/immutable))
			return cached
		return cached.copy()

	var/datum/gas_mixture/canonical_mix = new gastype()
	// We set here so any future key changes don't fuck us
	strings_to_mix["[gas_string]-[gastype]"] = canonical_mix
	gas_string = preprocess_gas_string(gas_string)

	var/list/gases = canonical_mix.gases
	var/list/gas = params2list(gas_string)
	if(gas["TEMP"])
		canonical_mix.temperature = text2num(gas["TEMP"])
		canonical_mix.temperature_archived = canonical_mix.temperature
		gas -= "TEMP"
	else // if we do not have a temp in the new gas mix lets assume room temp.
		canonical_mix.temperature = T20C
	for(var/id in gas)
		var/path = id
		if(!ispath(path))
			path = gas_id2path(path) //a lot of these strings can't have embedded expressions (especially for mappers), so support for IDs needs to stick around
		ADD_GAS(path, gases)
		gases[path][MOLES] = text2num(gas[id])

	if(istype(canonical_mix, /datum/gas_mixture/immutable))
		return canonical_mix
	return canonical_mix.copy()

/datum/controller/subsystem/air/proc/preprocess_gas_string(gas_string)
	if(!atmos_gen)
		generate_atmos()
	if(!atmos_gen[gas_string])
		return gas_string
	var/datum/atmosphere/mix = atmos_gen[gas_string]
	return mix.gas_string

/**
 * Adds a given machine to the processing system for SSAIR_ATMOSMACHINERY processing.
 *
 * Arguments:
 * * machine - The machine to start processing. Can be any /obj/machinery.
 */
/datum/controller/subsystem/air/proc/start_processing_machine(obj/machinery/machine)
	if(machine.atmos_processing)
		return
	if(QDELETED(machine))
		stack_trace("We tried to add a garbage collecting machine to SSair. Don't")
		return
	machine.atmos_processing = TRUE
	atmos_machinery += machine

/**
 * Removes a given machine to the processing system for SSAIR_ATMOSMACHINERY processing.
 *
 * Arguments:
 * * machine - The machine to stop processing.
 */
/datum/controller/subsystem/air/proc/stop_processing_machine(obj/machinery/machine)
	if(!machine.atmos_processing)
		return
	machine.atmos_processing = FALSE
	atmos_machinery -= machine

	// If we're currently processing atmos machines, there's a chance this machine is in
	// the currentrun list, which is a cache of atmos_machinery. Remove it from that list
	// as well to prevent processing qdeleted objects in the cache.
	if(currentpart == SSAIR_ATMOSMACHINERY)
		currentrun -= machine

/datum/controller/subsystem/air/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/controller/subsystem/air/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosControlPanel")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/controller/subsystem/air/ui_data(mob/user)
	var/list/data = list()
	data["excited_groups"] = list()
	for(var/datum/excited_group/group in excited_groups)
		var/turf/T = group.turf_list[1]
		var/area/target = get_area(T)
		var/max = 0
		#ifdef TRACK_MAX_SHARE
		for(var/who in group.turf_list)
			var/turf/open/lad = who
			max = max(lad.max_share, max)
		#endif
		data["excited_groups"] += list(list(
			"jump_to" = REF(T), //Just go to the first turf
			"group" = REF(group),
			"area" = target.name,
			"breakdown" = group.breakdown_cooldown,
			"dismantle" = group.dismantle_cooldown,
			"size" = group.turf_list.len,
			"should_show" = group.should_display,
			"max_share" = max
		))
	data["active_size"] = active_turfs.len
	data["hotspots_size"] = hotspots.len
	data["excited_size"] = excited_groups.len
	data["conducting_size"] = active_super_conductivity.len
	data["frozen"] = can_fire
	data["show_all"] = display_all_groups
	data["fire_count"] = times_fired
	#ifdef TRACK_MAX_SHARE
	data["display_max"] = TRUE
	#else
	data["display_max"] = FALSE
	#endif
	data["showing_user"] = user.hud_used.atmos_debug_overlays
	return data

/datum/controller/subsystem/air/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !check_rights_for(usr.client, R_DEBUG))
		return
	switch(action)
		if("move-to-target")
			var/turf/target = locate(params["spot"])
			if(!target)
				return
			usr.forceMove(target)
		if("toggle-freeze")
			can_fire = !can_fire
			return TRUE
		if("toggle_show_group")
			var/datum/excited_group/group = locate(params["group"])
			if(!group)
				return
			group.should_display = !group.should_display
			if(display_all_groups)
				return TRUE
			if(group.should_display)
				group.display_turfs()
			else
				group.hide_turfs()
			return TRUE
		if("toggle_show_all")
			display_all_groups = !display_all_groups
			for(var/datum/excited_group/group in excited_groups)
				if(display_all_groups)
					group.display_turfs()
				else if(!group.should_display) //Don't flicker yeah?
					group.hide_turfs()
			return TRUE
		if("toggle_user_display")
			var/mob/user = ui.user
			user.hud_used.atmos_debug_overlays = !user.hud_used.atmos_debug_overlays
			if(user.hud_used.atmos_debug_overlays)
				user.client.images += GLOB.colored_images
			else
				user.client.images -= GLOB.colored_images
			return TRUE
