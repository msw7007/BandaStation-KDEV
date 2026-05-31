/obj/item/seeds/proc/is_negative_plant()
	return instability >= NEGATIVE_PLANT_INSTABILITY_THRESHOLD

/obj/item/food/grown/Initialize(mapload, obj/item/seeds/new_seed)
	. = ..()
	if(. != INITIALIZE_HINT_QDEL)
		AddComponent(/datum/component/negative_plant_payload)

/datum/component/negative_plant_payload
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/negative_plant_payload/Initialize()
	if(!istype(parent, /obj/item/food/grown))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/food/grown/grown_food = parent
	if(!grown_food.seed?.is_negative_plant() || !grown_food.reagents)
		return
	var/excess = grown_food.seed.instability - NEGATIVE_PLANT_INSTABILITY_THRESHOLD
	grown_food.reagents.add_reagent(/datum/reagent/toxin, NEGATIVE_PLANT_TOXIN_PER_BITE * (1 + excess * 0.05))
