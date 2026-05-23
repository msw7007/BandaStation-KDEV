// ============================================================================
// SSgas_effects — processes active gas_cloud objects.
//
// Only iterates the active_clouds list. Empty world → near-zero CPU.
// ============================================================================

SUBSYSTEM_DEF(gas_effects)
	name = "Gas Effects"
	wait = 1 SECONDS
	priority = FIRE_PRIORITY_AIR - 1
	ss_flags = SS_NO_INIT | SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	/// All cloud objects currently being processed.
	var/list/obj/effect/gas_cloud/active_clouds = list()
	/// Working currentrun copy.
	var/list/currentrun = list()
	/// Cached singleton effect instances keyed by typepath.
	var/list/effect_singletons = list()

/datum/controller/subsystem/gas_effects/stat_entry(msg)
	msg += "Clouds:[length(active_clouds)]"
	return ..()

/datum/controller/subsystem/gas_effects/proc/get_effect_singleton(effect_path)
	if(!ispath(effect_path, /datum/gas_effect))
		return null
	var/datum/gas_effect/cached = effect_singletons[effect_path]
	if(cached)
		return cached
	cached = new effect_path
	effect_singletons[effect_path] = cached
	return cached

/datum/controller/subsystem/gas_effects/proc/register_cloud(obj/effect/gas_cloud/C)
	if(C in active_clouds)
		return
	active_clouds += C
	if(length(active_clouds) > LIGHTWEIGHT_ATMOS_MAX_CLOUDS)
		// Hard cap: drop the oldest cloud to keep CPU bounded.
		var/obj/effect/gas_cloud/oldest = active_clouds[1]
		qdel(oldest)

/datum/controller/subsystem/gas_effects/proc/unregister_cloud(obj/effect/gas_cloud/C)
	active_clouds -= C
	currentrun -= C

/datum/controller/subsystem/gas_effects/fire(resumed = FALSE)
	if(!resumed)
		currentrun = active_clouds.Copy()

	var/seconds_per_tick = wait / (1 SECONDS)

	while(length(currentrun))
		var/obj/effect/gas_cloud/cloud = currentrun[length(currentrun)]
		currentrun.len--
		if(QDELETED(cloud) || !cloud.effect)
			continue
		process_cloud(cloud, seconds_per_tick)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/gas_effects/proc/process_cloud(obj/effect/gas_cloud/cloud, seconds_per_tick)
	var/turf/T = cloud.loc
	if(!isturf(T))
		qdel(cloud)
		return

	// 1) Decay
	cloud.amount -= cloud.effect.decay_rate * seconds_per_tick

	// 2) Apply to any carbons standing on this turf
	for(var/mob/living/carbon/C in T)
		if(HAS_TRAIT(C, TRAIT_NOBREATH))
			continue
		var/list/blocked = C.get_breath_filter_tags()
		if(cloud.effect.is_filtered_by(blocked))
			continue
		cloud.effect.on_breathe(C, cloud.amount, seconds_per_tick)

	// 3) Spread (rate-limited)
	if(cloud.amount >= cloud.effect.spread_threshold && world.time >= cloud.next_spread_at)
		cloud.spread_to_neighbour()
		cloud.next_spread_at = world.time + (1 SECONDS) // at most once per second per cloud

	// 4) Expose atoms on this turf to a synthesised temperature event so the
	// atmos_sensitive shim (bonfires, thermite, combustible items, etc.) still
	// reacts to fire/freeze clouds.
	if(cloud.effect.temperature_delta != 0)
		var/synth_temp = cloud.temperature + cloud.effect.temperature_delta
		var/datum/gas_mixture/synth_air = null
		if(istype(T, /turf/open))
			var/turf/open/OT = T
			synth_air = OT.air
		SEND_SIGNAL(T, COMSIG_TURF_EXPOSE, synth_air, synth_temp)

	// 5) Decay-hook + cleanup
	cloud.effect.on_decay(T, cloud.amount)
	if(cloud.amount <= LIGHTWEIGHT_ATMOS_CLOUD_FLOOR)
		qdel(cloud)
