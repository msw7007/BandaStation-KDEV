/obj/machinery/demon_forge
	name = "demon forge"
	desc = "A workstation for creating and modifying modular demons. It uses net-data, but demons are spell abilities, not netspace datums."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "rdconsole"
	cy_net_enabled = TRUE
	cy_net_security = CY_NET_SECURITY_CORPORATE
	var/cooldown_until = 0
	var/base_cooldown = 1 MINUTES

/obj/machinery/demon_forge/Initialize(mapload)
	. = ..()
	cy_netspace_register_deferred(CY_NET_NODE_TERMINAL, cy_net_security)

/obj/machinery/demon_forge/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(world.time < cooldown_until)
		to_chat(user, span_warning("The forge is cooling down."))
		return
	var/list/options = list("create breach", "create ping", "create control", "create wall", "create blindspot", "create pax lock", "create short circuit", "upgrade loaded demon", "grant deck demons as spells")
	var/choice = input(user, "Demon forge", name) as null|anything in options
	if(!choice)
		return
	switch(choice)
		if("create breach")
			cy_create_demon_for_mob(user, /datum/cy_demon/breach, 25)
		if("create ping")
			cy_create_demon_for_mob(user, /datum/cy_demon/ping, 10)
		if("create control")
			cy_create_demon_for_mob(user, /datum/cy_demon/control, 35)
		if("create wall")
			cy_create_demon_for_mob(user, /datum/cy_demon/wall, 20)
		if("upgrade loaded demon")
			cy_upgrade_mob_demon(user)
		if("create blindspot")
			cy_create_demon_for_mob(user, /datum/cy_demon/blind, 20)
		if("create pax lock")
			cy_create_demon_for_mob(user, /datum/cy_demon/pacify, 25)
		if("create short circuit")
			cy_create_demon_for_mob(user, /datum/cy_demon/short_circuit, 25)
		if("grant deck demons as spells")
			var/obj/item/clothing/gloves/cyberdeck/deck = user.cy_get_active_cyberdeck()
			if(deck)
				deck.grant_demon_actions(user)

/obj/machinery/demon_forge/proc/cy_get_user_net_data(mob/living/user)
	if(!user)
		return 0
	if(hascall(user, "cy_get_net_data"))
		return call(user, "cy_get_net_data")()
	return user.vars.Find("net_data") ? user.vars["net_data"] : 0

/obj/machinery/demon_forge/proc/cy_set_user_net_data(mob/living/user, amount)
	if(!user)
		return
	if(hascall(user, "cy_set_net_data"))
		call(user, "cy_set_net_data")(amount)
		return
	if(user.vars.Find("net_data"))
		user.vars["net_data"] = amount

/obj/machinery/demon_forge/proc/cy_create_demon_for_mob(mob/living/user, demon_type, cost)
	var/net_data = cy_get_user_net_data(user)
	if(net_data < cost)
		to_chat(user, span_warning("You need [cost] net-data."))
		return FALSE
	var/datum/cy_demon/demon = new demon_type
	if(!demon.can_compile(user))
		qdel(demon)
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = user.cy_get_active_cyberdeck()
	if(deck && deck.is_compile_locked())
		to_chat(user, span_warning("[deck] is cooling down."))
		qdel(demon)
		return FALSE
	cy_set_user_net_data(user, net_data - cost)
	if(deck)
		if(!deck.store_demon(demon, user))
			cy_set_user_net_data(user, net_data)
			qdel(demon)
			return FALSE
		deck.begin_compile_cooldown()
		deck.grant_demon_actions(user)
	else
		user.cy_store_demon(demon)
	cooldown_until = world.time + base_cooldown
	to_chat(user, span_notice("The forge compiles [demon.name]."))
	return TRUE

/obj/machinery/demon_forge/proc/cy_upgrade_mob_demon(mob/living/user)
	var/list/demons = user.cy_collect_demons()
	if(!length(demons))
		to_chat(user, span_warning("You have no loaded demons."))
		return FALSE
	var/datum/cy_demon/demon = input(user, "Upgrade which demon?", name) as null|anything in demons
	if(!demon)
		return FALSE
	var/list/options = list(CY_DEMON_UPGRADE_POWER, CY_DEMON_UPGRADE_RANGE, CY_DEMON_UPGRADE_SPEED, CY_DEMON_UPGRADE_STEALTH, CY_DEMON_UPGRADE_MASS, CY_DEMON_UPGRADE_SPREAD, CY_DEMON_UPGRADE_JUMP, CY_DEMON_UPGRADE_EMI)
	var/field = input(user, "Upgrade what?", demon.name) as null|anything in options
	if(!field)
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = user.cy_get_active_cyberdeck()
	if(deck && deck.is_compile_locked())
		to_chat(user, span_warning("[deck] is cooling down."))
		return FALSE
	var/cost = 15
	var/net_data = cy_get_user_net_data(user)
	if(net_data < cost)
		to_chat(user, span_warning("You need [cost] net-data."))
		return FALSE
	var/datum/cy_demon_module/modifier/module
	switch(field)
		if(CY_DEMON_UPGRADE_POWER)
			module = new /datum/cy_demon_module/modifier/power_boost
		if(CY_DEMON_UPGRADE_RANGE)
			module = new /datum/cy_demon_module/modifier/range_boost
		if(CY_DEMON_UPGRADE_SPEED)
			module = new /datum/cy_demon_module/modifier/speed_boost
		if(CY_DEMON_UPGRADE_STEALTH)
			module = new /datum/cy_demon_module/modifier/stealth_shell
		if(CY_DEMON_UPGRADE_MASS)
			module = new /datum/cy_demon_module/modifier/mass_payload
		if(CY_DEMON_UPGRADE_SPREAD)
			module = new /datum/cy_demon_module/modifier/spread_payload
		if(CY_DEMON_UPGRADE_JUMP)
			module = new /datum/cy_demon_module/modifier/jump_payload
		if(CY_DEMON_UPGRADE_EMI)
			module = new /datum/cy_demon_module/modifier/emi_payload
	if(!module)
		return FALSE
	demon.add_module(module)
	if(!demon.can_compile(user))
		demon.remove_module(module)
		qdel(module)
		return FALSE
	cy_set_user_net_data(user, net_data - cost)
	if(deck)
		deck.begin_compile_cooldown()
		deck.grant_demon_actions(user)
	cooldown_until = world.time + base_cooldown
	to_chat(user, span_notice("The forge rewrites [demon.name]."))
	return TRUE
