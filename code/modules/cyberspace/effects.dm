// Cyberpunk 13 cyberspace: node, imprint and veil effects.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/obj/effect/cyberspace_node_shell
	name = "cyberspace node"
	desc = "A compressed digital shell of local equipment and access routes."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	anchored = TRUE
	density = FALSE
	alpha = 200
	color = "#18d8ff"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/cyberspace_node/node

/obj/effect/cyberspace_node_shell/Initialize(mapload, datum/cyberspace_node/new_node)
	. = ..()
	node = new_node
	if(node?.physical_area)
		name = "node: [node.physical_area.name]"
	desc = "Objects: [node?.get_object_count() || 0]. Net-data: [node?.net_data || 0]. Left click attacks ICE or enters with a key. Right click extracts available net-data."

/obj/effect/cyberspace_node_shell/Destroy(force)
	node = null
	return ..()

/obj/effect/cyberspace_node_shell/attack_hand(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return TRUE
	if(node.has_access(body))
		open_node_actions(body)
		return TRUE
	node.start_ice_hack(body)
	return TRUE

/obj/effect/cyberspace_node_shell/attack_hand_secondary(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/extracted_data = node.extract_net_data(body)
	if(extracted_data > 0)
		to_chat(body, span_notice("You extract [extracted_data] net-data and cached cryptographic keys from [name]."))
	else
		to_chat(body, span_warning("[name] has no accessible net-data."))
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/cyberspace_node_shell/proc/open_node_actions(mob/living/user)
	if(!user || !node)
		return FALSE
	var/action = tgui_input_list(user, "Node access granted. Choose a network action.", name, list(
		"Extract net-data",
		"Open control UI",
		"Glitch",
		"Short",
		"Settings",
		"Cancel",
	))
	if(!action || action == "Cancel")
		return FALSE
	if(action == "Extract net-data")
		var/extracted_data = node.extract_net_data(user)
		if(extracted_data > 0)
			to_chat(user, span_notice("You extract [extracted_data] net-data and cached cryptographic keys from [name]. Total net-data: [user.mind?.cyber_net_data || 0]."))
		else
			to_chat(user, span_warning("[name] has no accessible net-data."))
		return TRUE
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

/obj/effect/cyberspace_imprint_shell
	name = "neural imprint"
	desc = "A green neural-interface trace. It can be attacked as a personal ICE target."
	anchored = TRUE
	density = FALSE
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
		alpha = CYBERSPACE_IMPRINT_ALPHA
		color = "#4cff6b"
		name = "[target_body.real_name || target_body.name]'s neural imprint"

/obj/effect/cyberspace_imprint_shell/Destroy(force)
	body_ref = null
	node = null
	return ..()

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
	var/claimed = FALSE

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
