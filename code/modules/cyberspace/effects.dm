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
	if(!cyberspace_node_requires_adjacent(user, src))
		return TRUE
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return TRUE
	if(body.combat_mode)
		node.start_cyberspace_attack(body, src)
		return TRUE
	ui_interact(body)
	return TRUE

/obj/effect/cyberspace_node_shell/attack_hand_secondary(mob/user, list/modifiers)
	if(!cyberspace_node_requires_adjacent(user, src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
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
	ui_interact(user)
	return TRUE

/obj/effect/cyberspace_node_shell/ui_state(mob/user)
	return GLOB.always_state

/obj/effect/cyberspace_node_shell/ui_interact(mob/user, datum/tgui/ui)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return
	ui = SStgui.try_update_ui(body, src, ui)
	if(!ui)
		ui = new(body, src, "CyberNode", name)
		ui.open()

/obj/effect/cyberspace_node_shell/ui_data(mob/user)
	return cyberspace_node_ui_data(user, node, name)

/obj/effect/cyberspace_node_shell/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	return cyberspace_node_ui_act(action, params, ui, ui.user || usr, node, src, name)

/obj/effect/cyberspace_node_shell/proc/get_ui_target(list/params)
	return cyberspace_node_ui_target(node, params)

/proc/cyberspace_node_interaction_actor(mob/user)
	if(istype(user, /mob/eye/cyberspace_avatar))
		return user
	var/mob/living/body = get_cyberspace_user_body(user)
	if(body?.cyberspace_session?.avatar)
		return body.cyberspace_session.avatar
	return user

/proc/cyberspace_node_is_adjacent(mob/user, atom/target)
	var/mob/actor = cyberspace_node_interaction_actor(user)
	if(!actor || !target)
		return FALSE
	var/turf/actor_turf = get_turf(actor)
	var/turf/target_turf = get_turf(target)
	if(!actor_turf || !target_turf || actor_turf.z != target_turf.z)
		return FALSE
	var/max_distance = 1
	var/mob/living/body = get_cyberspace_user_body(user)
	var/remote_range = body?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 4) || 0
	if(remote_range > 0)
		max_distance = max(max_distance, round(remote_range))
	return get_dist(actor_turf, target_turf) <= max_distance

/proc/cyberspace_node_requires_adjacent(mob/user, atom/target)
	if(cyberspace_node_is_adjacent(user, target))
		return TRUE
	var/mob/living/body = get_cyberspace_user_body(user)
	var/mob/message_target = body || user
	if(message_target)
		to_chat(message_target, span_warning("Подойдите вплотную к [target] в киберпространстве."))
	return FALSE

/proc/cyberspace_node_ui_data(mob/user, datum/cyberspace_node/node, node_name)
	var/list/data = list()
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return data
	var/datum/cyber_ice/ice = node.get_ice()
	var/has_access = node.has_access(body)
	var/connected = body.cyberspace_session?.is_connected_to_node(node)
	data["node_name"] = node_name
	data["area"] = node.physical_area?.name || "Unknown"
	data["objects_count"] = node.get_object_count()
	data["net_data"] = node.net_data
	data["extracted"] = node.extracted
	data["has_access"] = has_access
	data["connected"] = connected
	data["can_ice"] = node.can_open_ice_hack()
	data["combat_mode"] = body.combat_mode
	data["protection_integrity"] = node.get_protection_integrity_percent()
	data["permissions"] = list(
		"open_ui" = node.can_use_control_function(body, "open_ui"),
		"emag_activate" = node.can_use_control_function(body, "emag_activate"),
		"emp_activate" = node.can_use_control_function(body, "emp_activate"),
		"shutdown" = node.can_use_control_function(body, "shutdown"),
		"settings" = node.can_use_control_function(body, "settings"),
	)
	data["protection"] = list(
		"model" = ice.model,
		"model_name" = ice.model_name,
		"reserve" = ice.current_reserve,
		"max_reserve" = ice.get_max_reserve(),
		"breached" = ice.is_breached(),
		"alarm" = ice.alarm_triggered,
		"manufacturer_diversity" = node.get_manufacturer_diversity_count(),
		"manufacturer_diversity_bonus" = round(node.get_manufacturer_diversity_bonus() * 100),
	)

	var/list/live_objects = node.get_live_objects()
	var/list/objects = list()
	var/object_index = 1
	for(var/atom/movable/live_object as anything in live_objects)
		objects += list(cyberspace_node_object_ui_data(live_object, object_index))
		object_index++
	data["objects"] = objects
	return data

/proc/cyberspace_node_ui_act(action, list/params, datum/tgui/ui, mob/user, datum/cyberspace_node/node, atom/visual_anchor, node_name)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return FALSE
	if(action != "refresh" && !cyberspace_node_requires_adjacent(user, visual_anchor))
		return FALSE
	var/static/list/target_commands = list(
		"open_ui" = TRUE,
		"emag_activate" = TRUE,
		"emp_activate" = TRUE,
		"shutdown" = TRUE,
		"settings" = TRUE,
	)
	if(target_commands[action])
		to_chat(body, span_notice("Cyberspace node receives command: [action]."))
	switch(action)
		if("connect")
			return node.start_cyberspace_connection(body, visual_anchor)
		if("extract")
			return !!node.extract_connected_net_data(body, visual_anchor)
		if("attack")
			return node.start_cyberspace_attack(body, visual_anchor)
		if("ice")
			return !!node.start_ice_hack(body)
		if("refresh")
			return TRUE
	var/atom/movable/target = cyberspace_node_ui_target(node, params)
	if(!target)
		to_chat(body, span_warning("[node_name] has no matching linked object."))
		return FALSE
	switch(action)
		if("open_ui")
			return node.run_control_mode(body, target, "open_ui", visual_anchor)
		if("emag_activate")
			return node.run_control_mode(body, target, "emag_activate", visual_anchor)
		if("emp_activate")
			return node.run_control_mode(body, target, "emp_activate", visual_anchor)
		if("shutdown")
			return node.run_control_mode(body, target, "shutdown", visual_anchor)
		if("settings")
			return node.run_control_mode(body, target, "settings", visual_anchor)
		else
			return FALSE

/proc/cyberspace_node_ui_target(datum/cyberspace_node/node, list/params)
	if(!node || !params)
		return null
	var/target_index = text2num("[params["target_index"]]")
	if(target_index < 1)
		return null
	var/list/live_objects = node.get_live_objects()
	if(target_index > length(live_objects))
		return null
	return live_objects[target_index]

/proc/cyberspace_node_object_ui_data(atom/movable/target, object_index)
	var/list/functions = list()
	if(cyberspace_target_can_open_ui(target))
		functions += "interface"
	if(cyberspace_target_can_emag(target))
		functions += "emag_activate"
	if(cyberspace_target_can_emp(target))
		functions += "emp_activate"
	if(cyberspace_target_can_settings(target))
		functions += "settings"
	return list(
		"index" = object_index,
		"name" = target.name,
		"type" = "[target.type]",
		"category" = cyberspace_node_object_category(target),
		"status" = cyberspace_node_object_status(target),
		"has_ui" = cyberspace_target_can_open_ui(target),
		"critical_ice" = is_cyberspace_ice_hack_target(target),
		"functions" = functions,
	)

/proc/cyberspace_node_object_category(atom/movable/target)
	if(istype(target, /obj/machinery/door))
		return "door"
	if(istype(target, /obj/machinery/computer))
		return "computer"
	if(istype(target, /obj/machinery/camera))
		return "camera"
	if(istype(target, /obj/machinery/vending))
		return "vending"
	if(istype(target, /obj/machinery/power/apc))
		return "power"
	if(istype(target, /obj/machinery/airalarm) || istype(target, /obj/machinery/firealarm))
		return "alarm"
	if(istype(target, /obj/structure/server) || istype(target, /obj/machinery/telecomms/server) || istype(target, /obj/machinery/rnd/server))
		return "server"
	if(isliving(target))
		return "neural"
	if(istype(target, /obj/item/organ/cyberimp))
		return "implant"
	if(istype(target, /obj/machinery))
		return "machine"
	return "object"

/proc/cyberspace_node_object_status(atom/movable/target)
	if(!target)
		return "missing"
	if("machine_stat" in target.vars)
		var/machine_state = target.vars["machine_stat"]
		if(machine_state & BROKEN)
			return "broken"
		if(machine_state & NOPOWER)
			return "no power"
		if(machine_state & EMPED)
			return "emp"
		return "online"
	if(QDELETED(target))
		return "deleted"
	return "active"

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
		dir = linked_object.dir
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
	if(!cyberspace_node_requires_adjacent(user, src))
		return TRUE
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return TRUE
	if(body.combat_mode)
		node.start_cyberspace_attack(body, src)
		return TRUE
	ui_interact(body)
	return TRUE

/obj/effect/cyberspace_object_trace/attack_hand_secondary(mob/user, list/modifiers)
	if(!cyberspace_node_requires_adjacent(user, src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!body.cyberspace_session?.is_connected_to_node(node))
		node.start_cyberspace_connection(body, src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	node.extract_connected_net_data(body, src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/cyberspace_object_trace/ui_state(mob/user)
	return GLOB.always_state

/obj/effect/cyberspace_object_trace/ui_interact(mob/user, datum/tgui/ui)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body || !node)
		return
	ui = SStgui.try_update_ui(body, src, ui)
	if(!ui)
		ui = new(body, src, "CyberNode", name)
		ui.open()

/obj/effect/cyberspace_object_trace/ui_data(mob/user)
	return cyberspace_node_ui_data(user, node, name)

/obj/effect/cyberspace_object_trace/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	return cyberspace_node_ui_act(action, params, ui, ui.user || usr, node, src, name)

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
