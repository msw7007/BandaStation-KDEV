#define COLD_STORAGE (1<<16)

/proc/is_cold_zone(atom/checked_atom)
	if(!checked_atom)
		return FALSE
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
