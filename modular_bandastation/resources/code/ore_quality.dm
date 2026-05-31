/obj/item/stack/ore/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	set_resource_quality(resource_quality || pick_random_resource_quality())
	points = round(points * get_resource_quality_multiplier(resource_quality))
