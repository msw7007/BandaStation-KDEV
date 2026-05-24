#define TRAIT_VACUUM_TURF "vacuum_turf"
#define TRAIT_WATER_TURF "water_turf"

/proc/is_vacuum_turf(turf/T)
	if(!T)
		return TRUE
	if(isspaceturf(T))
		return TRUE
	if(HAS_TRAIT(T, TRAIT_VACUUM_TURF))
		return TRUE
	return FALSE

/proc/is_water_turf(turf/T)
	if(!T)
		return FALSE
	if(HAS_TRAIT(T, TRAIT_WATER_TURF))
		return TRUE
	return FALSE

/proc/turf_gas_clouds(turf/T)
	if(!T)
		return null
	var/list/clouds
	for(var/obj/effect/gas_cloud/C in T)
		LAZYADD(clouds, C)
	return clouds
