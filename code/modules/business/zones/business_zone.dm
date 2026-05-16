/obj/structure/cy_business_zone
	name = "business zone anchor"
	desc = "An invisible city anchor that marks a persistent business cell."
	icon = 'icons/effects/effects.dmi'
	icon_state = "x2"
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/size_type = CY_BUSINESS_SIZE_SMALL
	var/datum/cy_business/active_business
	var/obj/machinery/computer/cy_business_terminal/linked_terminal

/obj/structure/cy_business_zone/Initialize(mapload)
	. = ..()
	SScy_business?.register_zone(src)

/obj/structure/cy_business_zone/Destroy()
	SScy_business?.unregister_zone(src)
	if(active_business)
		active_business.locate_zone = null
		active_business = null
	linked_terminal = null
	return ..()

/obj/structure/cy_business_zone/medium
	size_type = CY_BUSINESS_SIZE_MEDIUM
