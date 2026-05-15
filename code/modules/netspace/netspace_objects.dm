/atom
	var/datum/netspace_node/cy_netspace_node
	var/cy_net_enabled = FALSE
	var/cy_net_isolated = FALSE
	var/cy_net_security = CY_NET_SECURITY_BASIC
	var/cy_net_integrity = 100
	var/cy_net_max_integrity = 100
	var/list/cy_net_access_keys = list()
	var/list/cy_net_available_actions = list()
	var/cy_net_data = CY_NET_NODE_DATA_DEFAULT
	var/cy_net_key_id
	var/cy_net_family_key_id
	var/cy_net_key_name
	var/cy_net_glitched = FALSE
	var/cy_net_emi_fault = FALSE

/atom/proc/cy_netspace_register(node_type = CY_NET_NODE_GENERIC, security = null)
	cy_net_enabled = TRUE
	if(!isnull(security))
		cy_net_security = security
	cy_netspace_node = cy_netspace_get_or_create_node(src, node_type, cy_net_security)
	cy_netspace_node.integrity = cy_net_integrity
	cy_netspace_node.max_integrity = cy_net_max_integrity
	cy_netspace_node.access_keys = cy_net_access_keys
	cy_netspace_node.available_actions = cy_netspace_available_actions(null)
	return cy_netspace_node

/atom/proc/cy_netspace_register_deferred(node_type = CY_NET_NODE_GENERIC, security = null)
	cy_net_enabled = TRUE
	if(!isnull(security))
		cy_net_security = security
	if(SSnetspace)
		SSnetspace.queue_network_object(src)
		return
	addtimer(CALLBACK(src, PROC_REF(cy_netspace_register), node_type, cy_net_security), 1)

/atom/proc/cy_netspace_unregister()
	cy_net_enabled = FALSE
	if(cy_netspace_node)
		qdel(cy_netspace_node)
		cy_netspace_node = null

/atom/proc/cy_netspace_is_online()
	return cy_net_enabled && !cy_net_isolated

/atom/proc/cy_netspace_status_text(mob/living/net_avatar/avatar)
	return "Object integrity: [cy_net_integrity]/[cy_net_max_integrity]. Net-data: [cy_net_data]."

/atom/proc/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return cy_net_available_actions || list()

/atom/proc/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	return FALSE

/atom/proc/cy_is_netspace_target()
	return cy_netspace_is_online()

/atom/proc/cy_get_netspace_security()
	if(!cy_netspace_is_online())
		return null
	return cy_netspace_node ? cy_netspace_node.security : cy_net_security

/atom/proc/cy_apply_netspace_damage(amount, damage_type = CY_NET_DAMAGE_ATTACK, source)
	if(!cy_netspace_is_online())
		return FALSE
	if(cy_netspace_node)
		return cy_netspace_node.apply_net_damage(amount, damage_type, source)
	cy_net_integrity = max(0, cy_net_integrity - amount)
	return TRUE

/atom/proc/cy_add_netspace_trace(amount, source, reason)
	if(cy_netspace_node)
		cy_netspace_node.add_trace(amount, source, reason)
		return TRUE
	return FALSE

/atom/proc/cy_get_netspace_status(user)
	if(cy_netspace_node)
		return cy_netspace_node.get_status_text(user)
	return cy_netspace_status_text(user)

/atom/proc/cy_get_netspace_actions(user)
	if(cy_netspace_node)
		return cy_netspace_node.get_actions(user)
	return cy_netspace_available_actions(user)

/atom/proc/cy_execute_netspace_action(user, action_id)
	if(cy_netspace_node)
		return cy_netspace_node.execute_action(user, action_id)
	return cy_netspace_execute_action(user, action_id)

/atom/proc/cy_netspace_on_disabled(mob/living/net_avatar/source)
	cy_net_enabled = FALSE

/atom/proc/cy_netspace_on_restored(datum/netspace_node/node)
	cy_net_enabled = TRUE
	cy_net_glitched = FALSE
	cy_net_emi_fault = FALSE

/atom/proc/cy_netspace_on_feedback(mob/living/net_avatar/avatar, excess)
	return

/atom/proc/cy_netspace_on_brain_burn(mob/living/net_avatar/avatar, distance)
	return

/mob/living
	var/list/cy_net_memory_keys = list()

/mob/living/proc/cy_collect_net_keys()
	return cy_net_memory_keys?.Copy() || list()

/mob/living/proc/cy_remember_net_key(datum/net_access_key/key)
	if(!key)
		return FALSE
	if(!cy_net_memory_keys)
		cy_net_memory_keys = list()
	for(var/datum/net_access_key/existing as anything in cy_net_memory_keys)
		if(existing.key_id == key.key_id)
			return TRUE
	cy_net_memory_keys += key
	return TRUE


/mob/living/proc/cy_has_neural_interface()
	return FALSE

/mob/living/proc/cy_has_required_hackable_implants()
	return FALSE

/mob/living/cy_netspace_on_feedback(mob/living/net_avatar/avatar, excess)
	if(prob(10 * excess))
		to_chat(src, span_warning("Your neural link crackles with distance noise."))

/mob/living/cy_netspace_on_brain_burn(mob/living/net_avatar/avatar, distance)
	adjust_psychic_loss(3 * distance)
	to_chat(src, span_userdanger("Your brain burns from a stretched netspace link!"))


/atom/proc/cy_get_net_key_id()
	if(!cy_net_key_id)
		cy_net_key_id = "[type]#[cy_get_manufacturer_key_part()]"
	return cy_net_key_id

/atom/proc/cy_get_net_family_key_id()
	if(!cy_net_family_key_id)
		cy_net_family_key_id = "[cy_get_net_node_family_name()]#[cy_get_manufacturer_key_part()]"
	return cy_net_family_key_id

/atom/proc/cy_get_manufacturer_key_part()
	if(isobj(src))
		var/obj/object_source = src
		var/manufacturer_name = object_source.get_manufacturer_name()
		if(manufacturer_name)
			return manufacturer_name
	return "generic"

/atom/proc/cy_get_net_node_family_name()
	if(istype(src, /obj/machinery/door/airlock))
		return CY_NET_NODE_DOOR
	if(istype(src, /obj/machinery/camera))
		return CY_NET_NODE_CAMERA
	if(istype(src, /obj/machinery/vending))
		return CY_NET_NODE_VENDING
	if(istype(src, /obj/machinery/power/apc))
		return CY_NET_NODE_AREA
	if(istype(src, /obj/machinery/net_terminal))
		return CY_NET_NODE_TERMINAL
	return "[type]"

/atom/proc/cy_make_net_key(access_flags = CY_NET_ACCESS_ADMIN)
	return new /datum/net_access_key(cy_get_net_family_key_id(), cy_net_key_name || "[cy_get_manufacturer_key_part()] [cy_get_net_node_family_name()] key", access_flags, src)

/atom/proc/cy_download_net_data(mob/living/net_avatar/avatar)
	if(!avatar || cy_net_data <= 0)
		return FALSE
	cy_net_data--
	avatar.net_data++
	var/datum/net_access_key/key = cy_make_net_key(CY_NET_ACCESS_VIEW|CY_NET_ACCESS_USE)
	avatar.cy_remember_net_key(key)
	if(avatar.physical_body)
		avatar.physical_body.cy_remember_net_key(key)
	to_chat(avatar, span_notice("You download 1 net-data from [name]. Remaining: [cy_net_data]."))
	return TRUE

/atom/proc/cy_netspace_raise_alarm(mob/living/net_avatar/avatar, datum/netspace_cluster/cluster)
	visible_message(span_warning("[src] emits a sharp network alarm!"))
	cy_add_netspace_trace(15, avatar, "combat connect alarm")

/atom/proc/cy_netspace_on_glitch(mob/living/net_avatar/source)
	cy_net_glitched = TRUE
	if(hascall(src, PROC_REF(emag_act)))
		call(src, PROC_REF(emag_act))(source, null)

/atom/proc/cy_netspace_on_emi(mob/living/net_avatar/source)
	cy_net_emi_fault = TRUE
	emp_act(EMP_LIGHT)

/atom/proc/cy_netspace_can_execute(mob/living/net_avatar/avatar, required_flags = CY_NET_ACCESS_USE)
	if(!cy_netspace_node)
		return cy_net_security <= CY_NET_SECURITY_OPEN
	return cy_netspace_node.has_key_access(avatar, required_flags)

/obj/machinery/net_terminal
	name = "netspace terminal"
	desc = "A terminal for entering the city network."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "computer"
	cy_net_enabled = TRUE
	cy_net_security = CY_NET_SECURITY_BASIC

/obj/machinery/net_terminal/Initialize(mapload)
	. = ..()
	cy_netspace_register_deferred(CY_NET_NODE_TERMINAL, cy_net_security)

/obj/machinery/net_terminal/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	if(!cy_netspace_node)
		cy_netspace_register(CY_NET_NODE_TERMINAL, cy_net_security)
	cy_enter_netspace(user, src, CY_NET_AVATAR_ACTIVE)
	return TRUE

/obj/item/netdeck
	name = "netdeck"
	desc = "A portable cyberdeck for diving into local netspace."
	icon = 'icons/obj/devices/pda.dmi'
	icon_state = "pda-library"
	w_class = WEIGHT_CLASS_SMALL
	var/list/stored_keys = list()

/obj/item/netdeck/attack_self(mob/living/user, modifiers)
	. = ..()
	if(!istype(user))
		return
	var/mob/living/net_avatar/avatar = cy_enter_netspace(user, src, CY_NET_AVATAR_ACTIVE)
	if(avatar)
		avatar.net_keys += stored_keys

/obj/structure/netspace/wall
	name = "net wall"
	desc = "A defensive wall of compiled access rules."
	icon = 'icons/effects/effects.dmi'
	icon_state = "wave2"
	color = "#44aaff"
	density = TRUE
	anchored = TRUE
	max_integrity = CY_NET_WALL_MAX_INTEGRITY
	var/build_progress = 100
	var/net_integrity = CY_NET_WALL_MAX_INTEGRITY

/obj/structure/netspace/wall/Initialize(mapload, progress = 100)
	. = ..()
	build_progress = clamp(progress, 1, 100)
	net_integrity = round(CY_NET_WALL_MAX_INTEGRITY * (build_progress / 100))
	alpha = 60 + round(build_progress * 1.8)

/obj/structure/netspace/wall/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(!istype(mover, /mob/living/net_avatar))
		return FALSE
	if(build_progress >= 100)
		return FALSE
	return prob(100 - build_progress)

/obj/structure/netspace/wall/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user, /mob/living/net_avatar))
		return
	take_net_damage(CY_NET_WALL_ATTACK_DAMAGE, PSYCHIC)

/obj/structure/netspace/wall/attack_animal(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		take_net_damage(CY_NET_WALL_ATTACK_DAMAGE, PSYCHIC)
		return TRUE
	return ..()

/obj/structure/netspace/wall/proc/take_net_damage(amount, damage_type = PSYCHIC)
	net_integrity -= amount
	if(net_integrity <= 0)
		qdel(src)
		return
	build_progress = clamp(round((net_integrity / CY_NET_WALL_MAX_INTEGRITY) * 100), 1, 100)
	alpha = 60 + round(build_progress * 1.8)

/obj/structure/netspace/wall/proc/build_tick(amount = CY_NET_WALL_BUILD_RATE)
	build_progress = clamp(build_progress + amount, 1, 100)
	net_integrity = max(net_integrity, round(CY_NET_WALL_MAX_INTEGRITY * (build_progress / 100)))
	alpha = 60 + round(build_progress * 1.8)

/obj/machinery/door/airlock/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "open", "close", "toggle_bolts")

/obj/machinery/door/airlock/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	if(!cy_netspace_can_execute(avatar, CY_NET_ACCESS_USE))
		cy_netspace_node?.add_trace(10, avatar, "denied door command")
		return FALSE
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("open")
			open()
			return TRUE
		if("close")
			close()
			return TRUE
		if("toggle_bolts")
			if(cy_netspace_can_execute(avatar, CY_NET_ACCESS_CONTROL))
				set_bolt(!locked)
				return TRUE
	return FALSE

/obj/machinery/camera/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "disable", "enable")

/obj/machinery/camera/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	if(!cy_netspace_can_execute(avatar, CY_NET_ACCESS_CONTROL))
		cy_netspace_node?.add_trace(8, avatar, "denied camera command")
		return FALSE
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable")
			if(camera_enabled)
				toggle_cam(null, FALSE)
			return TRUE
		if("enable")
			if(!camera_enabled)
				toggle_cam(null, FALSE)
			return TRUE
	return FALSE

/obj/machinery/vending/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "audit", "disable_network")

/obj/machinery/vending/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	if(!cy_netspace_can_execute(avatar, CY_NET_ACCESS_USE))
		cy_netspace_node?.add_trace(8, avatar, "denied vending command")
		return FALSE
	switch(action_id)
		if("status", "audit")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable_network")
			if(cy_netspace_can_execute(avatar, CY_NET_ACCESS_CONTROL))
				cy_net_isolated = TRUE
				return TRUE
	return FALSE


/obj/machinery/door/airlock
	cy_net_data = 10

/obj/machinery/camera
	cy_net_data = 12

/obj/machinery/vending
	cy_net_data = 20

/obj/machinery/power/apc
	cy_net_data = 25

/obj/machinery/net_terminal
	cy_net_data = 40

/obj/machinery/power/apc/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "open_interface")

/obj/machinery/power/apc/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	if(!cy_netspace_can_execute(avatar, CY_NET_ACCESS_USE))
		cy_netspace_node?.add_trace(8, avatar, "denied APC command")
		return FALSE
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("open_interface")
			ui_interact(avatar)
			return TRUE
	return FALSE
