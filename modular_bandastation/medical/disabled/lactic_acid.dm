// Deliberately excluded from _medical.dme. No production metabolism or movement hooks.
// This optional module is reserved for a later, separately balanced exercise system.
/datum/component/medical_lactic_acid
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/load = 0

/datum/component/medical_lactic_acid/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/medical_lactic_acid/proc/exert(amount)
	load = clamp(load + amount, 0, 100)

/datum/component/medical_lactic_acid/proc/recover(seconds)
	load = max(0, load - seconds)
