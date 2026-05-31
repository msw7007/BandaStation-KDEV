/datum/component/decomposition/Initialize(mapload, decomp_req_handle, decomp_flags = NONE, decomp_result, ant_attracting = FALSE, custom_time = 0, stink_particles = /particles/stink)
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	if(ismovable(parent))
		parent.AddComponent(/datum/component/perishable)

/obj/item/food/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ingredient_compatibility)
