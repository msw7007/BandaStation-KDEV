// ============================================================================
// /obj/effect/gas_cloud — a single patch of dangerous air on a turf.
//
// Cheap: one obj per active patch, processed by SSgas_effects. No turf-wide
// processing, no neighbour scans for inactive areas.
// ============================================================================

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

	/// Singleton effect describing what kind of gas this is.
	var/datum/gas_effect/effect
	/// Current amount (think "moles", but abstract).
	var/amount = 0
	/// Local temperature in K (informational).
	var/temperature = T20C
	/// World time of last spread tick (rate-limit spreading).
	var/last_spread = 0
	/// How many ticks until next allowed spread (set on each spread).
	var/next_spread_at = 0

/obj/effect/gas_cloud/Initialize(mapload, datum/gas_effect/effect_singleton, start_amount = 25, start_temperature = T20C)
	. = ..()
	if(!istype(effect_singleton))
		stack_trace("gas_cloud spawned without a valid effect")
		return INITIALIZE_HINT_QDEL
	effect = effect_singleton
	amount = start_amount
	temperature = start_temperature
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
	if(effect?.touch_on_cross && amount > 0)
		effect.on_touch(AM, amount, 1)

/// Returns TRUE if this cloud is the right type for merging with an incoming spawn.
/obj/effect/gas_cloud/proc/can_merge(datum/gas_effect/incoming)
	return effect == incoming

/obj/effect/gas_cloud/proc/merge(amount_to_add, temperature_to_blend = T20C)
	if(amount_to_add <= 0)
		return
	var/total = amount + amount_to_add
	temperature = ((temperature * amount) + (temperature_to_blend * amount_to_add)) / total
	amount = total

/// Try to spread one chunk into a neighbour. Returns the chunk transferred.
/obj/effect/gas_cloud/proc/spread_to_neighbour()
	if(amount < effect.spread_threshold)
		return 0
	var/turf/T = loc
	if(!isturf(T))
		return 0
	var/list/candidates = list()
	// 4-way horizontal candidates
	for(var/dir in GLOB.cardinals)
		var/turf/N = get_step(T, dir)
		if(!N)
			continue
		if(!cloud_can_pass(T, N))
			continue
		candidates += N
	// Vertical (Z) preference by density. Multi-Z is optional in this fork —
	// if there's no Z above/below, ignore silently.
	if(effect.density_type != GAS_DENSITY_NEUTRAL)
		var/dz = (effect.density_type == GAS_DENSITY_LIGHT) ? 1 : -1
		var/turf/V = locate(T.x, T.y, T.z + dz)
		if(V && cloud_can_pass(T, V))
			candidates += V
			candidates += V  // double weight on preferred direction
	if(!length(candidates))
		return 0
	var/turf/target = pick(candidates)
	var/chunk = amount * effect.spread_rate
	if(chunk <= 0)
		return 0
	amount -= chunk
	var/obj/effect/gas_cloud/existing = locate(/obj/effect/gas_cloud) in target
	if(existing && existing.can_merge(effect))
		existing.merge(chunk, temperature)
		return chunk
	// affects_underwater gate
	if(!effect.affects_underwater && is_water_turf(target))
		return chunk  // gas dissipates harmlessly into water
	spawn_gas_cloud(target, effect.type, chunk, temperature)
	return chunk

/// Whether a cloud can pass between two adjacent turfs.
/proc/cloud_can_pass(turf/source, turf/target)
	if(!target || target.density)
		return FALSE
	// Block on closed turfs (walls) and sealed doors.
	for(var/obj/O in target)
		if(O.density)
			if(istype(O, /obj/machinery/door))
				var/obj/machinery/door/D = O
				if(D.density)
					return FALSE
			else
				return FALSE
	return TRUE
