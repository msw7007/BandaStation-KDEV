/datum/component/pain_tracker
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/pain_damage = 0

/datum/component/pain_tracker/Initialize(starting_pain = 0)
	if(!istype(parent, /obj/item/bodypart))
		return COMPONENT_INCOMPATIBLE
	pain_damage = round(max(starting_pain, 0), DAMAGE_PRECISION)

/datum/component/pain_tracker/proc/get_pain()
	return pain_damage

/datum/component/pain_tracker/proc/set_pain(amount, maximum = INFINITY)
	var/old_pain = pain_damage
	pain_damage = round(clamp(amount, 0, maximum), DAMAGE_PRECISION)
	return old_pain - pain_damage

/datum/component/pain_tracker/proc/adjust_pain(amount, maximum = INFINITY)
	return set_pain(pain_damage + amount, maximum)

/datum/component/pain_tracker/proc/get_residual_pain()
	var/obj/item/bodypart/limb = parent
	return round((limb.blunt_dam * 1.25 + limb.pierce_dam + limb.slash_dam * 0.8 + limb.heat_dam * 1.2 + limb.cold_dam * 0.7 + limb.acid_dam * 1.4) * 0.1, DAMAGE_PRECISION)

/datum/component/pain_tracker/proc/process_pain(seconds_per_tick)
	var/old_pain = pain_damage
	var/pain_floor = get_residual_pain()
	if(pain_damage > pain_floor)
		adjust_pain(-min(pain_damage - pain_floor, 5 * seconds_per_tick))
	else if(pain_damage < pain_floor)
		set_pain(pain_floor)
	return old_pain != pain_damage
