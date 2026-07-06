/datum/component/decomposition/Initialize(mapload, decomp_req_handle, decomp_flags = NONE, decomp_result, ant_attracting = FALSE, custom_time = 0, stink_particles = /particles/stink)
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	if(istype(parent, /obj/item/food))
		parent.AddComponent(/datum/component/perishable, src) // pass ourselves; we aren't in the parent's component list yet

/obj/item/food/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cyberpunk_food_quality_model)
	AddComponent(/datum/component/ingredient_compatibility)
	AddComponent(/datum/component/cyberpunk_food_additions)
