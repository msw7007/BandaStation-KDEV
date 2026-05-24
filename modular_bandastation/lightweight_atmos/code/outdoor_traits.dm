/proc/area_is_outdoor(area/A)
	if(!isarea(A))
		return FALSE
	if(HAS_TRAIT(A, TRAIT_OUTDOOR_AIR))
		return TRUE
	if(A.outdoors)
		return TRUE
	if(istype(A, /area/space))
		return FALSE
	if(!A.requires_power && !A.always_unpowered)
		return TRUE
	return FALSE

/proc/mark_area_outdoor(area/A)
	if(!isarea(A))
		return
	ADD_TRAIT(A, TRAIT_OUTDOOR_AIR, INNATE_TRAIT)
	A.oxygen_level = AREA_AIR_O2_DEFAULT
	A.co2_level = AREA_AIR_CO2_DEFAULT
