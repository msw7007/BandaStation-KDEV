/area
	var/oxygen_level = AREA_AIR_O2_DEFAULT
	var/co2_level = AREA_AIR_CO2_DEFAULT
	var/cached_outdoor_state = null
	var/pressure_hazard_enabled = FALSE

/area/proc/is_outdoor_air()
	if(cached_outdoor_state != null)
		return cached_outdoor_state
	cached_outdoor_state = area_is_outdoor(src)
	return cached_outdoor_state

/area/proc/consume_oxygen(amount)
	if(amount <= 0)
		return 0
	if(is_outdoor_air())
		return amount
	var/before = oxygen_level
	oxygen_level = max(0, oxygen_level - amount)
	return before - oxygen_level

/area/proc/release_co2(amount)
	if(amount <= 0)
		return
	if(is_outdoor_air())
		return
	co2_level = min(2, co2_level + amount)

/area/proc/refill_oxygen(amount)
	if(amount <= 0)
		return
	if(is_outdoor_air())
		return
	oxygen_level = min(AREA_AIR_O2_DEFAULT, oxygen_level + amount)

/area/proc/scrub_co2(amount)
	if(amount <= 0)
		return
	co2_level = max(0, co2_level - amount)

/area/proc/get_air_quality()
	if(is_outdoor_air())
		return AREA_AIR_QUALITY_GOOD
	if(co2_level >= AREA_AIR_CO2_TOXIC)
		return AREA_AIR_QUALITY_TOXIC
	if(oxygen_level <= AREA_AIR_O2_LETHAL)
		return AREA_AIR_QUALITY_LETHAL
	if(oxygen_level <= AREA_AIR_O2_SUFFOCATING)
		return AREA_AIR_QUALITY_SUFFOCATING
	if(oxygen_level <= AREA_AIR_O2_TIGHT || co2_level >= AREA_AIR_CO2_TIGHT)
		return AREA_AIR_QUALITY_TIGHT
	return AREA_AIR_QUALITY_GOOD

/area/proc/process_air_tick(seconds_per_tick)
	if(is_outdoor_air())
		oxygen_level = AREA_AIR_O2_DEFAULT
		co2_level = AREA_AIR_CO2_DEFAULT
		return
	vent_pump_refill_area(src, seconds_per_tick)
	vent_scrubber_clean_area(src, seconds_per_tick)
	if(oxygen_level > AREA_AIR_O2_DEFAULT * 0.2 && !LAZYLEN(air_vents))
		oxygen_level = max(AREA_AIR_O2_DEFAULT * 0.2, oxygen_level - AREA_AIR_INDOOR_DRIFT * seconds_per_tick)
