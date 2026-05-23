// ============================================================================
// Turf-level environment classification.
//
// Replaces "read the gas mixture" with three constant categories: vacuum,
// water, or normal breathable air. Cheap calls, no per-tile state.
// ============================================================================

// Trait defines (used with ADD_TRAIT/REMOVE_TRAIT/HAS_TRAIT on turfs).
/// Marks a turf as having no breathable air regardless of `isspaceturf`.
#define TRAIT_VACUUM_TURF "vacuum_turf"
/// Marks a turf as a water environment for the breath-hold timer.
#define TRAIT_WATER_TURF "water_turf"

/// Returns TRUE if the turf has no breathable atmosphere.
/proc/is_vacuum_turf(turf/T)
	if(!T)
		return TRUE
	if(isspaceturf(T))
		return TRUE
	if(HAS_TRAIT(T, TRAIT_VACUUM_TURF))
		return TRUE
	return FALSE

/// Returns TRUE if the turf is a water environment (lake, pool, ocean).
/proc/is_water_turf(turf/T)
	if(!T)
		return FALSE
	if(HAS_TRAIT(T, TRAIT_WATER_TURF))
		return TRUE
	return FALSE

/// Pull the active gas clouds on a turf without forcing list allocation.
/proc/turf_gas_clouds(turf/T)
	if(!T)
		return null
	var/list/clouds
	for(var/obj/effect/gas_cloud/C in T)
		LAZYADD(clouds, C)
	return clouds
