// Cyberpunk 13 cyberspace: network storage and dedigitizer.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/obj/item/cyberspace_storage
	name = "network storage"
	desc = "A compressed piece of network storage. It needs a dedigitizer to become physical loot."
	icon = 'icons/obj/economy.dmi'
	icon_state = "holochip"
	w_class = WEIGHT_CLASS_SMALL
	var/list/reward_types = list(
		/obj/item/holochip = 500,
		/obj/item/stack/ore/iron = 2,
		/obj/item/stack/ore/glass = 2,
	)

/obj/item/cyberspace_storage/proc/dedigitize(atom/output_location, mob/user)
	if(!output_location)
		output_location = drop_location()
	if(!output_location)
		return FALSE

	for(var/reward_type in reward_types)
		var/reward_amount = reward_types[reward_type]
		new reward_type(output_location, reward_amount)

	if(user)
		to_chat(user, span_notice("[src] unfolds into physical resources."))
	qdel(src)
	return TRUE

/obj/item/cyberspace_storage/reward
	name = "dense network storage"
	desc = "A denser piece of network storage taken from an aggressive Veil program."
	reward_types = list(
		/obj/item/holochip = 750,
		/obj/item/stack/ore/iron = 3,
		/obj/item/stack/ore/titanium = 1,
	)

/obj/machinery/dedigitizer
	name = "dedigitizer"
	desc = "A machine that unfolds network storage into physical items."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "byteforge"
	base_icon_state = "byteforge"
	density = TRUE
	anchored = TRUE
	circuit = null

/obj/machinery/dedigitizer/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberspace_storage))
		var/obj/item/cyberspace_storage/storage = attacking_item
		flash()
		storage.dedigitize(drop_location(), user)
		return TRUE
	return ..()

/obj/machinery/dedigitizer/proc/flash()
	flick("byteforge_prespawn", src)
	playsound(src, 'sound/effects/magic/blink.ogg', 50, TRUE)
	do_sparks(3, TRUE, loc, spark_type = /datum/effect_system/basic/spark_spread/quantum)
