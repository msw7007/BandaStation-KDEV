// Cyberpunk 13 cyberspace: node, imprint and veil effects.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/obj/effect/cyberspace_node_shell
	name = "cyberspace node"
	desc = "A compressed digital shell of local equipment and access routes."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE
	alpha = 200
	color = "#18d8ff"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/cyberspace_node/node

/obj/effect/cyberspace_node_shell/Initialize(mapload, datum/cyberspace_node/new_node)
	. = ..()
	node = new_node
	if(node?.physical_area)
		name = "node: [node.physical_area.name]"
	desc = "Objects: [node?.get_object_count() || 0]. Net-data: [node?.net_data || 0]. LMB activates access, combat LMB attacks protection. RMB connects first, then extracts data."
	maptext = "<span class='maptext' style='color:#18d8ff;text-shadow:0 0 4px #18d8ff;font-size:8px'>NODE</span>"
	maptext_width = 64
	maptext_x = -16
	maptext_y = 20

/obj/effect/cyberspace_node_shell/Destroy(force)
	node = null
	return ..()

/obj/effect/cyberspace_node_shell/Click(location, control, params)
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		attack_hand_secondary(usr, modifiers)
	else
		attack_hand(usr, modifiers)
	return TRUE

/obj/effect/cyberspace_node_shell/attack_hand(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return TRUE
	if(body.combat_mode)
		node.start_cyberspace_attack(body, src)
		return TRUE
	open_node_actions(body)
	return TRUE

/obj/effect/cyberspace_node_shell/attack_hand_secondary(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!body.cyberspace_session?.is_connected_to_node(node))
		node.start_cyberspace_connection(body, src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	node.extract_connected_net_data(body, src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/cyberspace_node_shell/proc/open_node_actions(mob/living/user)
	if(!user || !node)
		return FALSE
	var/has_access = node.has_access(user)
	var/list/actions = list(
		"View linked objects",
		"Start ICE hack",
		"Connect",
		"Extract net-data",
	)
	if(has_access)
		actions += list(
			"Open control UI",
			"Glitch",
			"Short",
			"Settings",
		)
	actions += "Cancel"
	var/action = tgui_input_list(user, "[has_access ? "Node access granted" : "Node protection active"]. Choose a network action.", name, actions)
	if(!action || action == "Cancel")
		return FALSE
	if(action == "View linked objects")
		var/list/live_objects = node.get_live_objects()
		if(!length(live_objects))
			to_chat(user, span_warning("[name] has no linked objects left."))
			return FALSE
		var/list/object_names = list()
		for(var/atom/movable/live_object as anything in live_objects)
			object_names += "[live_object] ([live_object.type])"
		tgui_alert(user, jointext(object_names, "\n"), "Linked objects")
		return TRUE
	if(action == "Start ICE hack")
		node.start_ice_hack(user)
		return TRUE
	if(action == "Connect")
		node.start_cyberspace_connection(user, src)
		return TRUE
	if(action == "Extract net-data")
		node.extract_connected_net_data(user, src)
		return TRUE
	if(!has_access)
		to_chat(user, span_warning("[name] is still protected. Break ICE or obtain a cryptokey before using control actions."))
		return FALSE
	var/list/live_objects = node.get_live_objects()
	if(!length(live_objects))
		to_chat(user, span_warning("[name] has no linked objects left."))
		return FALSE
	var/atom/movable/target = tgui_input_list(user, "Choose a linked object.", name, live_objects)
	if(!target)
		return FALSE
	switch(action)
		if("Open control UI")
			if(hascall(target, "ui_interact"))
				call(target, "ui_interact")(user)
			else
				node.run_control_mode(user, target, "control")
		if("Glitch")
			node.run_control_mode(user, target, "glitch")
		if("Short")
			node.run_control_mode(user, target, "short")
		if("Settings")
			node.run_control_mode(user, target, "settings")
	return TRUE

/obj/effect/cyberspace_object_trace
	name = "network trace"
	desc = "A local object's digital trace inside this cyberspace node."
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE
	alpha = 170
	color = "#18d8ff"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/weakref/linked_object_ref
	var/datum/cyberspace_node/node

/obj/effect/cyberspace_object_trace/Initialize(mapload, atom/movable/linked_object, datum/cyberspace_node/source_node)
	. = ..()
	node = source_node
	if(linked_object)
		linked_object_ref = WEAKREF(linked_object)
		appearance = linked_object.appearance
		layer = ABOVE_MOB_LAYER
		plane = GAME_PLANE
		alpha = 170
		color = "#18d8ff"
		name = "trace: [linked_object.name]"
		desc = "Digital trace of [linked_object] ([linked_object.type]). LMB opens node actions, combat LMB attacks protection. RMB connects first, then extracts data."
		maptext = "<span class='maptext' style='color:#18d8ff;text-shadow:0 0 4px #18d8ff;font-size:7px'>TRACE</span>"
		maptext_width = 64
		maptext_x = -16
		maptext_y = 18

/obj/effect/cyberspace_object_trace/Destroy(force)
	linked_object_ref = null
	node = null
	return ..()

/obj/effect/cyberspace_object_trace/Click(location, control, params)
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		attack_hand_secondary(usr, modifiers)
	else
		attack_hand(usr, modifiers)
	return TRUE

/obj/effect/cyberspace_object_trace/attack_hand(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return TRUE
	if(body.combat_mode)
		node.start_cyberspace_attack(body, src)
		return TRUE
	var/obj/effect/cyberspace_node_shell/proxy = new(get_turf(src), node)
	proxy.open_node_actions(body)
	qdel(proxy)
	return TRUE

/obj/effect/cyberspace_object_trace/attack_hand_secondary(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!body.cyberspace_session?.is_connected_to_node(node))
		node.start_cyberspace_connection(body, src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	node.extract_connected_net_data(body, src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/cyberspace_imprint_shell
	name = "neural imprint"
	desc = "A green neural-interface trace. It can be attacked as a personal ICE target."
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE
	alpha = CYBERSPACE_IMPRINT_ALPHA
	color = "#4cff6b"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/weakref/body_ref
	var/datum/cyberspace_node/node

/obj/effect/cyberspace_imprint_shell/Initialize(mapload, mob/living/target_body, datum/cyberspace_node/source_node)
	. = ..()
	node = source_node
	if(target_body)
		body_ref = WEAKREF(target_body)
		appearance = target_body.appearance
		layer = ABOVE_MOB_LAYER
		plane = GAME_PLANE
		alpha = CYBERSPACE_IMPRINT_ALPHA
		color = "#4cff6b"
		name = "[target_body.real_name || target_body.name]'s neural imprint"

/obj/effect/cyberspace_imprint_shell/Destroy(force)
	body_ref = null
	node = null
	return ..()

/obj/effect/cyberspace_imprint_shell/Click(location, control, params)
	attack_hand(usr, params2list(params))
	return TRUE

/obj/effect/cyberspace_imprint_shell/attack_hand(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	var/mob/living/target_body = body_ref?.resolve()
	if(!body || !target_body)
		return TRUE
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = target_body.get_neural_interface()
	if(!interface)
		to_chat(body, span_warning("The imprint collapses: no neural interface answers."))
		return TRUE
	interface.start_ice_hack(body)
	return TRUE

/obj/effect/cyberspace_storage_node
	name = "network storage node"
	desc = "A Veil storage node. It can be pulled into the physical world and opened by a dedigitizer."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	color = "#ffd447"
	alpha = 210
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE
	var/claimed = FALSE

/obj/effect/cyberspace_storage_node/Click(location, control, params)
	attack_hand(usr, params2list(params))
	return TRUE

/obj/effect/cyberspace_storage_node/attack_hand(mob/user, list/modifiers)
	if(claimed)
		to_chat(user, span_warning("The storage node has already been extracted."))
		return TRUE
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!istype(body))
		to_chat(user, span_warning("You need a physical body link to pull the storage out."))
		return TRUE
	claimed = TRUE
	color = "#7a6b28"
	alpha = 90
	var/obj/item/cyberspace_storage/storage = new(body.drop_location())
	if(body.put_in_hands(storage))
		to_chat(body, span_notice("You pull [storage] through your neural interface."))
	else
		to_chat(body, span_notice("[storage] materializes near your body."))
	return TRUE
