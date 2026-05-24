/proc/vent_pump_refill_area(area/A, seconds_per_tick)
	if(!isarea(A) || !A.air_vents?.len)
		return
	var/total_refill = 0
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/pump as anything in A.air_vents)
		if(QDELETED(pump))
			continue
		if(!pump.on || !pump.is_operational)
			continue
		if(pump.pump_direction != ATMOS_DIRECTION_RELEASING)
			continue
		total_refill += AREA_AIR_VENT_REFILL
	if(total_refill > 0)
		A.refill_oxygen(total_refill * seconds_per_tick)

/proc/vent_scrubber_clean_area(area/A, seconds_per_tick)
	if(!isarea(A) || !A.air_scrubbers?.len)
		return
	var/total_scrub = 0
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrub as anything in A.air_scrubbers)
		if(QDELETED(scrub))
			continue
		if(!scrub.on || !scrub.is_operational)
			continue
		if(scrub.scrubbing != ATMOS_DIRECTION_SCRUBBING)
			continue
		total_scrub += AREA_AIR_VENT_SCRUB_CO2
	if(total_scrub > 0)
		A.scrub_co2(total_scrub * seconds_per_tick)
