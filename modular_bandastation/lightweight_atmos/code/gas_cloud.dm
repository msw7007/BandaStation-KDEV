/obj/effect/gas_cloud
	name = "gas cloud"
	desc = "A swirling patch of vapour."
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	anchored = TRUE
	plane = ABOVE_GAME_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 140
	layer = FLY_LAYER

	var/datum/gas_effect/effect
	var/amount = 0
	var/temperature = T20C
	var/last_spread = 0
	var/next_spread_at = 0
	var/list/chemicals = null
	var/next_secondary_effect_at = 0

/obj/effect/gas_cloud/Initialize(mapload, datum/gas_effect/effect_singleton, start_amount = 25, start_temperature = T20C, list/start_chemicals = null)
	. = ..()
	if(!istype(effect_singleton))
		stack_trace("gas_cloud spawned without a valid effect")
		return INITIALIZE_HINT_QDEL
	effect = effect_singleton
	amount = start_amount
	temperature = start_temperature
	if(length(start_chemicals))
		chemicals = start_chemicals.Copy()
	else if(length(effect.default_chemicals))
		chemicals = effect.default_chemicals.Copy()
	name = effect.name
	desc = "A swirling cloud of [effect.name]."
	if(effect.visible)
		add_atom_colour(effect.color, FIXED_COLOUR_PRIORITY)
		icon_state = effect.icon_state
	else
		alpha = 0
	SSgas_effects.register_cloud(src)
	var/turf/T = loc
	if(isturf(T))
		RegisterSignal(T, COMSIG_ATOM_ENTERED, PROC_REF(on_turf_entered))

/obj/effect/gas_cloud/Destroy()
	if(SSgas_effects)
		SSgas_effects.unregister_cloud(src)
	if(isturf(loc))
		UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	effect = null
	return ..()

/obj/effect/gas_cloud/proc/on_turf_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!effect || amount <= 0)
		return
	if(effect.touch_on_cross)
		effect.on_touch(AM, amount, 1)
		if(length(chemicals) || length(effect.default_chemicals))
			effect.apply_chemicals_on_touch(AM, chemicals || effect.default_chemicals, amount, 1)

/obj/effect/gas_cloud/proc/can_merge(datum/gas_effect/incoming)
	return effect == incoming

/obj/effect/gas_cloud/proc/merge(amount_to_add, temperature_to_blend = T20C, list/chems_to_add = null)
	if(amount_to_add <= 0)
		return
	var/total = amount + amount_to_add
	temperature = ((temperature * amount) + (temperature_to_blend * amount_to_add)) / total
	amount = total
	if(length(chems_to_add))
		if(!chemicals)
			chemicals = list()
		for(var/reagent_path in chems_to_add)
			chemicals[reagent_path] = (chemicals[reagent_path] || 0) + chems_to_add[reagent_path]

/obj/effect/gas_cloud/proc/shrink_chemicals(new_amount, old_amount)
	if(!length(chemicals) || old_amount <= 0)
		return
	if(new_amount <= 0)
		chemicals = null
		return
	var/keep = new_amount / old_amount
	for(var/reagent_path in chemicals)
		chemicals[reagent_path] *= keep

/obj/effect/gas_cloud/proc/split_chemicals(fraction)
	if(!length(chemicals) || fraction <= 0)
		return null
	var/list/out = list()
	for(var/reagent_path in chemicals)
		var/portion = chemicals[reagent_path] * fraction
		if(portion <= 0)
			continue
		out[reagent_path] = portion
		chemicals[reagent_path] -= portion
	return out

/obj/effect/gas_cloud/proc/get_pressure()
	if(!effect)
		return 0
	return amount / max(effect.tile_capacity, 1)

/obj/effect/gas_cloud/proc/spread_to_neighbour()
	if(amount < effect.spread_threshold || get_pressure() < effect.pressure_spread_threshold)
		return 0
	var/turf/T = loc
	if(!isturf(T))
		return 0
	var/area/source_area = T.loc
	if(!isarea(source_area))
		source_area = null
	var/list/candidates = list()
	for(var/dir in GLOB.cardinals)
		var/turf/N = get_step(T, dir)
		if(!N)
			continue
		if(!cloud_can_pass(T, N))
			continue
		var/flow_weight = get_cloud_flow_weight(T, N, source_area, effect)
		for(var/i in 1 to flow_weight)
			candidates += N
	if(effect.density_type != GAS_DENSITY_NEUTRAL)
		var/dz = (effect.density_type == GAS_DENSITY_LIGHT) ? 1 : -1
		var/turf/V = locate(T.x, T.y, T.z + dz)
		if(V && cloud_can_pass(T, V))
			candidates += V
			candidates += V
	if(!length(candidates))
		return 0
	var/turf/target = pick(candidates)
	var/pressure_excess = max(get_pressure() - effect.pressure_spread_threshold, 0.1)
	var/chunk = amount * effect.spread_rate * min(pressure_excess, 1)
	if(chunk <= 0)
		return 0
	var/old_amount = amount
	amount -= chunk
	var/list/chunk_chems = split_chemicals(chunk / old_amount)
	var/obj/effect/gas_cloud/existing = locate(/obj/effect/gas_cloud) in target
	if(existing && existing.can_merge(effect))
		existing.merge(chunk, temperature, chunk_chems)
		return chunk
	if(!effect.affects_underwater && is_water_turf(target))
		return chunk
	spawn_gas_cloud(target, effect.type, chunk, temperature, chunk_chems)
	return chunk

/proc/get_cloud_flow_weight(turf/source, turf/target, area/source_area, datum/gas_effect/effect)
	. = 1
	if(!source || !target || !source_area || !effect?.vent_flow_weight)
		return
	var/source_dist
	var/target_dist
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrub as anything in source_area.air_scrubbers)
		if(QDELETED(scrub) || !scrub.on || !scrub.is_operational)
			continue
		source_dist = get_dist(source, scrub)
		target_dist = get_dist(target, scrub)
		if(target_dist < source_dist)
			. += effect.vent_flow_weight
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/pump as anything in source_area.air_vents)
		if(QDELETED(pump) || !pump.on || !pump.is_operational)
			continue
		source_dist = get_dist(source, pump)
		target_dist = get_dist(target, pump)
		if(target_dist < source_dist)
			. += max(1, round(effect.vent_flow_weight * 0.5))

/proc/cloud_can_pass(turf/source, turf/target)
	if(!target || target.density)
		return FALSE
	for(var/obj/O in target)
		if(O.density)
			if(istype(O, /obj/machinery/door))
				var/obj/machinery/door/D = O
				if(D.density)
					return FALSE
			else
				return FALSE
	return TRUE
