/obj/item/seeds/proc/is_negative_plant()
	return instability >= NEGATIVE_PLANT_INSTABILITY_THRESHOLD

/// Fruit from an unstable (negative) plant carries a toxin dose scaled by how far past the threshold it is.
/obj/item/food/grown/Initialize(mapload, obj/item/seeds/new_seed)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	if(!seed?.is_negative_plant() || !reagents)
		return
	var/excess = seed.instability - NEGATIVE_PLANT_INSTABILITY_THRESHOLD
	reagents.add_reagent(/datum/reagent/toxin, NEGATIVE_PLANT_TOXIN_PER_BITE * (1 + excess * 0.05))
