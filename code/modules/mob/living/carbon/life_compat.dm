// Compatibility shims for upstream carbon/life.dm restored during modularization.

/obj/item/organ/heart/proc/get_blood_regeneration_multiplier()
	if(organ_flags & ORGAN_FAILING)
		return 0
	return get_efficiency()
