/datum/cy_stat_holder
	/// Usually a /mob/living, later can be a phantom NPC profile datum.
	var/datum/owner

	/// Assoc list: stat typepath = raw/base value.
	var/list/base_stats = list()

	/// Assoc list: stat typepath = list(source = modifier amount).
	var/list/stat_modifiers = list()

	/// Assoc list: stat typepath = stored progression experience.
	var/list/stat_experience = list()

/datum/cy_stat_holder/New(datum/new_owner)
	. = ..()
	owner = new_owner
	initialize_stats()

/datum/cy_stat_holder/Destroy()
	owner = null
	base_stats = null
	stat_modifiers = null
	stat_experience = null
	return ..()

/datum/cy_stat_holder/proc/initialize_stats()
	for(var/stat_type in GLOB.cy_stat_types)
		base_stats[stat_type] = CY_STAT_DEFAULT

/datum/cy_stat_holder/proc/is_valid_stat(stat_type)
	return ispath(stat_type, /datum/cy_stat)

/datum/cy_stat_holder/proc/get_base_stat(stat_type)
	if(!is_valid_stat(stat_type))
		return CY_STAT_DEFAULT

	return base_stats[stat_type] || CY_STAT_DEFAULT

/datum/cy_stat_holder/proc/set_base_stat(stat_type, value)
	if(!is_valid_stat(stat_type))
		return FALSE

	base_stats[stat_type] = clamp(round(value), CY_STAT_MINIMUM, CY_STAT_MAXIMUM)
	return TRUE

/datum/cy_stat_holder/proc/adjust_base_stat(stat_type, amount)
	return set_base_stat(stat_type, get_base_stat(stat_type) + amount)

/datum/cy_stat_holder/proc/get_stat_modifier_total(stat_type)
	if(!is_valid_stat(stat_type))
		return 0

	var/list/modifiers = stat_modifiers[stat_type]
	if(!length(modifiers))
		return 0

	var/total = 0
	for(var/source in modifiers)
		total += modifiers[source]

	return total

/datum/cy_stat_holder/proc/set_stat_modifier(stat_type, source, amount)
	if(!is_valid_stat(stat_type) || isnull(source))
		return FALSE

	var/list/modifiers = stat_modifiers[stat_type]
	if(!modifiers)
		modifiers = list()
		stat_modifiers[stat_type] = modifiers

	if(!amount)
		modifiers -= source
	else
		modifiers[source] = amount

	return TRUE

/datum/cy_stat_holder/proc/clear_stat_modifier(stat_type, source)
	if(!is_valid_stat(stat_type) || isnull(source))
		return FALSE

	var/list/modifiers = stat_modifiers[stat_type]
	if(!modifiers)
		return FALSE

	modifiers -= source
	return TRUE

/datum/cy_stat_holder/proc/get_stat(stat_type, include_modifiers = TRUE)
	if(!is_valid_stat(stat_type))
		return CY_STAT_DEFAULT

	var/value = get_base_stat(stat_type)
	if(include_modifiers)
		value += get_stat_modifier_total(stat_type)

	return clamp(value, CY_STAT_MINIMUM, CY_STAT_MAXIMUM)


/datum/cy_stat_holder/proc/get_stat_experience(stat_type)
	if(!is_valid_stat(stat_type))
		return 0
	return stat_experience[stat_type] || 0

/datum/cy_stat_holder/proc/get_stat_experience_required_for_next_level(stat_type)
	if(!is_valid_stat(stat_type))
		return 0
	var/current_value = get_base_stat(stat_type)
	if(current_value >= CY_STAT_MAXIMUM)
		return 0
	return 100 + (50 * current_value)

/datum/cy_stat_holder/proc/adjust_stat_experience(stat_type, amount, apply_level = TRUE)
	if(!is_valid_stat(stat_type) || !amount)
		return 0

	var/new_experience = max(0, get_stat_experience(stat_type) + round(amount))
	stat_experience[stat_type] = new_experience
	return amount
