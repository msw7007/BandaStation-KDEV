/turf
	var/lightweight_pressure_override = null
	var/lightweight_pressure_hazard_until = 0

/turf/proc/set_lightweight_pressure_hazard(pressure, duration = LIGHTWEIGHT_ATMOS_PRESSURE_HAZARD_EXPIRE)
	lightweight_pressure_override = pressure
	lightweight_pressure_hazard_until = max(lightweight_pressure_hazard_until, world.time + duration)

/turf/proc/has_lightweight_pressure_hazard()
	if(lightweight_pressure_hazard_until <= world.time)
		lightweight_pressure_override = null
		return FALSE
	return TRUE

/turf/proc/get_lightweight_pressure_override()
	if(!has_lightweight_pressure_hazard())
		return null
	return lightweight_pressure_override

/proc/has_lightweight_pressure_hazard(atom/target)
	var/turf/T = get_turf(target)
	if(T?.has_lightweight_pressure_hazard())
		return TRUE
	var/area/A = get_area(target)
	return A?.pressure_hazard_enabled

/proc/get_lightweight_pressure_override(atom/target)
	var/turf/T = get_turf(target)
	return T?.get_lightweight_pressure_override()
