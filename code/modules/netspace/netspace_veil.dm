/area/netspace
	name = "Netspace"
	static_lighting = FALSE
	requires_power = FALSE

/area/netspace/veil
	name = "The Veil"

/turf/open/netspace/veil
	name = "veil netspace"
	color = "#42101a"

/mob/living/net_avatar/alternative
	name = "alternative"
	desc = "A red hostile program from beyond the city net."
	avatar_mode = CY_NET_AVATAR_ALTERNATIVE
	color = CY_NET_COLOR_ALTERNATIVE
	var/attack_power = 8
	var/aggro_range = 7

/mob/living/net_avatar/alternative/Initialize(mapload)
	. = ..()
	avatar_mode = CY_NET_AVATAR_ALTERNATIVE
	update_net_color()

/mob/living/net_avatar/alternative/netspace_process(seconds_per_tick)
	var/mob/living/net_avatar/target
	for(var/mob/living/net_avatar/avatar in view(aggro_range, src))
		if(avatar == src || avatar.avatar_mode == CY_NET_AVATAR_MIRROR || avatar.avatar_mode == CY_NET_AVATAR_ALTERNATIVE)
			continue
		target = avatar
		break
	if(!target)
		return
	if(get_dist(src, target) > 1)
		step_towards(src, target)
		return
	target.adjust_psychic_loss(attack_power)
	to_chat(target, span_userdanger("[src] tears at your avatar."))

/obj/effect/netspace/lost_code
	name = "lost code"
	desc = "A condensed fragment of dead netspace code. It can be de-digitized into rare technology."
	icon = 'icons/effects/effects.dmi'
	icon_state = "static"
	color = "#ff3333"
	var/net_data_value = 50
	var/obj/item/dedigitized_result

/obj/effect/netspace/lost_code/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user, /mob/living/net_avatar))
		return
	var/mob/living/net_avatar/avatar = user
	avatar.net_data += net_data_value
	to_chat(avatar, span_notice("You absorb [net_data_value] net-data from [src]."))
	qdel(src)

/obj/machinery/net_dedigitizer
	name = "de-digitizer"
	desc = "A machine that can print physical objects from lost code."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "protolathe"
	cy_net_enabled = TRUE
	cy_net_security = CY_NET_SECURITY_CORPORATE

/obj/machinery/net_dedigitizer/Initialize(mapload)
	. = ..()
	cy_netspace_register_deferred(CY_NET_NODE_TERMINAL, cy_net_security)

/obj/machinery/net_dedigitizer/proc/dedigitize_code(mob/living/user, obj/effect/netspace/lost_code/code)
	if(!code)
		return FALSE
	new /obj/item/stack/sheet/iron(get_turf(src), 5)
	qdel(code)
	to_chat(user, span_notice("The de-digitizer condenses the code into salvage."))
	return TRUE
