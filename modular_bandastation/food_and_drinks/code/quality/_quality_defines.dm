#define COLD_STORAGE (1<<16)

/proc/is_cold_zone(atom/checked_atom)
	if(!checked_atom)
		return FALSE
	for(var/atom/location = checked_atom; location; location = location.loc)
		if(istype(location, /obj/machinery/smartfridge))
			return TRUE
		if(istype(location, /obj/structure/closet/crate/freezer))
			return TRUE
		if(istype(location, /obj/structure/closet/crate/secure/freezer))
			return TRUE
		if(istype(location, /obj/structure/closet/secure_closet/freezer))
			return TRUE
		if(istype(location, /obj/structure/closet/mini_fridge))
			return TRUE
	var/area/our_area = get_area(checked_atom)
	if(!our_area)
		return FALSE
	return !!(our_area.area_flags & COLD_STORAGE)

#define PERISH_PROGRESS_FRESH 0.75
#define PERISH_PROGRESS_STALE 0.50
#define PERISH_PROGRESS_GROSS 0.25

#define PERISH_PENALTY_STALE -1
#define PERISH_PENALTY_GROSS -2
#define PERISH_PENALTY_ROTTEN -3

#define COMPAT_SYNERGY_BONUS 1
#define COMPAT_ANTAGONISM_PENALTY -1
#define COMPAT_BONUS_CAP 2
#define COMPAT_PENALTY_CAP -2

#define CY_FOOD_INHERITED_QUALITY_CAP 4
#define CY_FOOD_QUALITY_EFFECT_PER_POINT 0.08
#define CY_FOOD_QUALITY_EFFECT_MIN 0.5
#define CY_FOOD_QUALITY_EFFECT_MAX 1.6
