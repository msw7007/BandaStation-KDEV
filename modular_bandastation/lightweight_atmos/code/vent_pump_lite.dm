/obj/machinery/atmospherics/components/unary/vent_pump
	var/lightweight_filter_clog = 0

/obj/machinery/atmospherics/components/unary/vent_scrubber
	var/lightweight_filter_clog = 0

/obj/machinery/atmospherics/components/unary/vent_pump/proc/get_lightweight_vent_efficiency()
	if(QDELETED(src) || !on || !is_operational || welded)
		return 0
	return clamp(get_integrity_percentage() * (1 - lightweight_filter_clog * 0.01), 0, 1)

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/get_lightweight_scrubber_efficiency()
	if(QDELETED(src) || !on || !is_operational || welded)
		return 0
	return clamp((1 - lightweight_filter_clog * 0.01), 0, 1)

/obj/machinery/atmospherics/components/unary/vent_pump/proc/add_lightweight_filter_clog(amount)
	if(amount <= 0)
		return
	lightweight_filter_clog = clamp(lightweight_filter_clog + amount, 0, 100)

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/add_lightweight_filter_clog(amount)
	if(amount <= 0)
		return
	lightweight_filter_clog = clamp(lightweight_filter_clog + amount, 0, 100)

/obj/machinery/atmospherics/components/unary/vent_pump/proc/service_lightweight_filter(mob/living/user, obj/item/tool)
	if(lightweight_filter_clog <= 0)
		return FALSE
	var/service_delay = 4 SECONDS * (user?.get_cyberpunk_structure_time_multiplier(src, "repair") || 1) * tool.toolspeed
	balloon_alert(user, "servicing filter...")
	if(!do_after(user, service_delay, src))
		balloon_alert(user, "interrupted!")
		return TRUE
	lightweight_filter_clog = 0
	user?.reward_character_check_experience(SKILL_CONSTRUCTION, 2, FALSE, 1)
	user?.reward_character_check_experience(SKILL_ELECTRICS, 1, FALSE, 1)
	balloon_alert(user, "filter serviced")
	return TRUE

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/service_lightweight_filter(mob/living/user, obj/item/tool)
	if(lightweight_filter_clog <= 0)
		return FALSE
	var/service_delay = 4 SECONDS * (user?.get_cyberpunk_structure_time_multiplier(src, "repair") || 1) * tool.toolspeed
	balloon_alert(user, "servicing filter...")
	if(!do_after(user, service_delay, src))
		balloon_alert(user, "interrupted!")
		return TRUE
	lightweight_filter_clog = 0
	user?.reward_character_check_experience(SKILL_CONSTRUCTION, 2, FALSE, 1)
	user?.reward_character_check_experience(SKILL_ELECTRICS, 1, FALSE, 1)
	balloon_alert(user, "filter serviced")
	return TRUE

/obj/machinery/atmospherics/components/unary/vent_pump/examine(mob/user)
	. = ..()
	if(lightweight_filter_clog >= 75)
		. += span_warning("Its intake filter is heavily clogged.")
	else if(lightweight_filter_clog >= 25)
		. += span_notice("Its intake filter has visible dust buildup.")

/obj/machinery/atmospherics/components/unary/vent_scrubber/examine(mob/user)
	. = ..()
	if(lightweight_filter_clog >= 75)
		. += span_warning("Its scrubber filter is heavily clogged.")
	else if(lightweight_filter_clog >= 25)
		. += span_notice("Its scrubber filter has visible residue buildup.")

/obj/machinery/atmospherics/components/unary/vent_pump/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if(.)
		return
	return service_lightweight_filter(user, tool) ? ITEM_INTERACT_SUCCESS : .

/obj/machinery/atmospherics/components/unary/vent_scrubber/screwdriver_act(mob/living/user, obj/item/tool)
	return service_lightweight_filter(user, tool) ? ITEM_INTERACT_SUCCESS : ..()

/obj/machinery/atmospherics/components/unary
	/// Optional map offsets for the outdoor end of this vent's duct.
	var/air_outside_dx
	var/air_outside_dy
	var/air_outside_dz = 0
	var/tmp/turf/air_outside_endpoint
	var/tmp/turf/air_endpoint_origin

/obj/machinery/atmospherics/components/unary/proc/get_lightweight_air_endpoint()
	RETURN_TYPE(/turf)
	var/turf/origin = get_turf(src)
	if(!origin || origin == air_endpoint_origin)
		return air_outside_endpoint
	air_endpoint_origin = origin
	air_outside_endpoint = null
	if(isnum(air_outside_dx) && isnum(air_outside_dy))
		var/turf/mapped_endpoint = locate(origin.x + air_outside_dx, origin.y + air_outside_dy, origin.z + air_outside_dz)
		if(is_lightweight_air_endpoint(mapped_endpoint))
			air_outside_endpoint = mapped_endpoint
		return air_outside_endpoint
	var/best_distance = 11
	for(var/turf/open/candidate in range(10, origin))
		var/distance = get_dist(origin, candidate)
		if(distance >= best_distance || !is_lightweight_air_endpoint(candidate))
			continue
		air_outside_endpoint = candidate
		best_distance = distance
	return air_outside_endpoint

/proc/is_lightweight_air_endpoint(turf/candidate)
	var/area/outside = get_area(candidate)
	return isopenturf(candidate) && !is_vacuum_turf(candidate) && !is_water_turf(candidate) && outside?.is_outdoor_air()

/proc/transfer_lightweight_vent_cloud(obj/effect/gas_cloud/cloud, turf/destination, requested_amount)
	var/transferred = min(requested_amount, cloud.amount)
	if(transferred <= LIGHTWEIGHT_ATMOS_CLOUD_FLOOR || !destination || destination == cloud.loc)
		return 0
	var/list/chemicals = cloud.chemicals?.Copy()
	for(var/chemical in chemicals)
		chemicals[chemical] *= transferred / cloud.amount
	if(!spawn_gas_cloud(destination, cloud.effect.type, transferred, cloud.temperature, chemicals))
		return 0
	var/old_amount = cloud.amount
	cloud.amount -= transferred
	cloud.shrink_chemicals(cloud.amount, old_amount)
	return transferred

/proc/vent_pump_refill_area(area/A, seconds_per_tick)
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/pump as anything in A.air_vents)
		var/efficiency = pump.get_lightweight_vent_efficiency()
		if(efficiency <= 0)
			continue
		var/turf/outside = pump.get_lightweight_air_endpoint()
		if(!outside && istype(A, /area/cyberpunk))
			continue
		var/rate = AREA_AIR_VENT_REFILL * efficiency * seconds_per_tick
		if(pump.pump_direction == ATMOS_DIRECTION_RELEASING)
			var/contamination = 0
			var/supply_temperature = AREA_AIR_TEMP_DEFAULT
			for(var/obj/effect/gas_cloud/cloud in outside)
				var/airflow = GAS_EFFECT_PER_TICK_MAX * rate
				var/incoming = min(cloud.amount, airflow * (1 - contamination))
				var/fraction = incoming / airflow
				contamination += fraction
				supply_temperature += (cloud.temperature - AREA_AIR_TEMP_DEFAULT) * fraction
				transfer_lightweight_vent_cloud(cloud, get_turf(pump), incoming)
				if(contamination >= 1)
					break
			A.refill_oxygen(rate * (1 - contamination))
			A.scrub_co2(A.co2_level * min(rate, 1) * (1 - contamination))
			A.exchange_environment_temperature(supply_temperature, AREA_AIR_VENT_TEMP_EXCHANGE * rate, 1)
		else if(outside)
			exhaust_lightweight_area_air(A, outside, rate)
		pump.add_lightweight_filter_clog(0.002 * seconds_per_tick)

/proc/vent_scrubber_clean_area(area/A, seconds_per_tick)
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrub as anything in A.air_scrubbers)
		var/efficiency = scrub.get_lightweight_scrubber_efficiency()
		if(efficiency <= 0)
			continue
		var/rate = AREA_AIR_VENT_SCRUB_CO2 * efficiency * seconds_per_tick
		var/turf/outside = scrub.get_lightweight_air_endpoint()
		if(scrub.scrubbing == ATMOS_DIRECTION_SIPHONING)
			if(outside)
				exhaust_lightweight_area_air(A, outside, rate)
		else
			A.scrub_co2(rate)
		scrub.add_lightweight_filter_clog(0.003 * seconds_per_tick)

/proc/exhaust_lightweight_area_air(area/source, turf/outside, rate)
	var/fraction = clamp(rate, 0, 1)
	source.consume_oxygen(source.oxygen_level * fraction)
	var/exhaust_co2 = source.co2_level * fraction
	source.scrub_co2(exhaust_co2)
	if(exhaust_co2 > 0)
		spawn_gas_cloud(outside, /datum/gas_effect/co2, exhaust_co2 * GAS_EFFECT_PER_TICK_MAX, source.environment_temperature)
