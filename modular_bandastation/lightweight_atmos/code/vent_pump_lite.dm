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

/proc/vent_pump_refill_area(area/A, seconds_per_tick)
	if(!isarea(A) || !A.air_vents?.len)
		return
	var/total_refill = 0
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/pump as anything in A.air_vents)
		var/efficiency = pump.get_lightweight_vent_efficiency()
		if(efficiency <= 0)
			continue
		if(pump.pump_direction != ATMOS_DIRECTION_RELEASING)
			continue
		total_refill += AREA_AIR_VENT_REFILL * efficiency
		pump.add_lightweight_filter_clog(0.002 * seconds_per_tick)
	if(total_refill > 0)
		A.refill_oxygen(total_refill * seconds_per_tick)
		A.exchange_environment_temperature(AREA_AIR_TEMP_DEFAULT, AREA_AIR_VENT_TEMP_EXCHANGE * total_refill, seconds_per_tick)

/proc/vent_scrubber_clean_area(area/A, seconds_per_tick)
	if(!isarea(A) || !A.air_scrubbers?.len)
		return
	var/total_scrub = 0
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrub as anything in A.air_scrubbers)
		var/efficiency = scrub.get_lightweight_scrubber_efficiency()
		if(efficiency <= 0)
			continue
		if(scrub.scrubbing != ATMOS_DIRECTION_SCRUBBING)
			continue
		total_scrub += AREA_AIR_VENT_SCRUB_CO2 * efficiency
		scrub.add_lightweight_filter_clog(0.003 * seconds_per_tick)
	if(total_scrub > 0)
		A.scrub_co2(total_scrub * seconds_per_tick)
