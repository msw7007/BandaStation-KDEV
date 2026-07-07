SUBSYSTEM_DEF(gas_effects)
	name = "Gas Effects"
	wait = 1 SECONDS
	priority = FIRE_PRIORITY_AIR - 1
	ss_flags = SS_NO_INIT | SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/obj/effect/gas_cloud/active_clouds = list()
	var/list/currentrun = list()
	var/list/effect_singletons = list()
	var/area_air_tick_counter = 0

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
		var/obj/effect/gas_cloud/oldest = active_clouds[1]
		qdel(oldest)

/datum/controller/subsystem/gas_effects/proc/unregister_cloud(obj/effect/gas_cloud/C)
	active_clouds -= C
	currentrun -= C

/datum/controller/subsystem/gas_effects/fire(resumed = FALSE)
	if(!resumed)
		currentrun = active_clouds.Copy()
		area_air_tick_counter++
		if(area_air_tick_counter >= AREA_AIR_TICK_INTERVAL)
			area_air_tick_counter = 0
			sweep_area_air(AREA_AIR_TICK_INTERVAL * (wait / (1 SECONDS)))

	var/seconds_per_tick = wait / (1 SECONDS)

	while(length(currentrun))
		var/obj/effect/gas_cloud/cloud = currentrun[length(currentrun)]
		currentrun.len--
		if(QDELETED(cloud) || !cloud.effect)
			continue
		process_cloud(cloud, seconds_per_tick)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/gas_effects/proc/sweep_area_air(seconds_per_tick)
	for(var/area/A as anything in GLOB.areas)
		if(QDELETED(A))
			continue
		A.process_air_tick(seconds_per_tick)

/datum/controller/subsystem/gas_effects/proc/process_cloud(obj/effect/gas_cloud/cloud, seconds_per_tick)
	var/turf/T = cloud.loc
	if(!isturf(T))
		qdel(cloud)
		return

	var/datum/gas_effect/effect = cloud.effect
	var/area/A = T.loc
	if(!isarea(A))
		A = null
	var/old_amount = cloud.amount

	effect.on_process_cloud(cloud, T, A, seconds_per_tick)
	if(QDELETED(cloud))
		return
	effect.try_ignite_cloud(cloud)
	effect = cloud.effect

	var/decay = effect.decay_rate
	if(A?.is_outdoor_air())
		decay *= effect.outdoor_decay_multiplier
	if(effect.scrubbable && A?.air_scrubbers?.len)
		var/scrub_total = 0
		for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrub as anything in A.air_scrubbers)
			var/scrub_efficiency = scrub.get_lightweight_scrubber_efficiency()
			if(scrub_efficiency <= 0)
				continue
			if(scrub.scrubbing != ATMOS_DIRECTION_SCRUBBING)
				continue
			scrub_total += LIGHTWEIGHT_ATMOS_VENT_SCRUB_RATE * scrub_efficiency
			scrub.add_lightweight_filter_clog(0.01 * seconds_per_tick)
		decay += scrub_total
	cloud.amount -= decay * seconds_per_tick

	var/list/chem_pool = cloud.chemicals || effect.default_chemicals
	for(var/mob/living/carbon/C in T)
		if(HAS_TRAIT(C, TRAIT_NOBREATH))
			continue
		var/list/blocked = C.get_breath_filter_tags()
		if(effect.is_filtered_by(blocked))
			continue
		var/effective_amount = effect.beneficial ? cloud.amount : cloud.amount * C.get_cyberpunk_environment_hazard_multiplier()
		effect.on_breathe(C, effective_amount, seconds_per_tick)
		if(length(chem_pool))
			effect.apply_chemicals_on_breathe(C, chem_pool, effective_amount, seconds_per_tick)
		if(effect.visibility_modifier > 0)
			C.set_eye_blur_if_lower((effect.visibility_modifier * min(effective_amount, GAS_EFFECT_PER_TICK_MAX) * 0.4 * seconds_per_tick) SECONDS)
			if(effective_amount > 50 && effect.visibility_modifier >= 2)
				C.adjust_temp_blindness((1 SECONDS) * seconds_per_tick)

	if(cloud.amount >= effect.spread_threshold && cloud.get_pressure() >= effect.pressure_spread_threshold && world.time >= cloud.next_spread_at)
		cloud.spread_to_neighbour()
		cloud.next_spread_at = world.time + (1 SECONDS)

	if(effect.temperature_delta != 0)
		var/synth_temp = cloud.temperature + effect.temperature_delta
		A?.exchange_environment_temperature(synth_temp, LIGHTWEIGHT_ATMOS_CLOUD_TEMP_EXCHANGE * min(cloud.amount / GAS_EFFECT_PER_TICK_MAX, 1), seconds_per_tick)
		var/datum/gas_mixture/synth_air = null
		if(istype(T, /turf/open))
			var/turf/open/OT = T
			synth_air = OT.air
		SEND_SIGNAL(T, COMSIG_TURF_EXPOSE, synth_air, synth_temp)

	if(A && effect.alarm_flags && cloud.amount >= effect.alarm_threshold)
		trigger_cloud_alarms(A, effect.alarm_flags, cloud)
		SEND_SIGNAL(A, COMSIG_AREA_CLOUD_ALARM, effect.alarm_flags, cloud)

	if(cloud.amount < old_amount)
		cloud.shrink_chemicals(cloud.amount, old_amount)

	effect.on_decay(T, cloud.amount)
	if(cloud.amount <= LIGHTWEIGHT_ATMOS_CLOUD_FLOOR)
		qdel(cloud)
