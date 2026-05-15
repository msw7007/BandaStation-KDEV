/area/netspace
	name = "Netspace"
	icon_state = "purple"
	requires_power = FALSE
	static_lighting = FALSE
	base_lighting_alpha = 255
	base_lighting_color = "#5aa8ff"
	default_gravity = STANDARD_GRAVITY
	ambient_buzz = null

/area/netspace/generated
	name = "Generated Netspace"

/turf/open/floor/netspace
	name = "netspace floor"
	desc = "A compressed neon reflection of the physical city."
	icon = 'icons/turf/floors.dmi'
	icon_state = "dark"
	color = "#6fb8ff"
	light_range = 3
	light_power = 1.4
	light_color = "#6fb8ff"
	baseturfs = /turf/open/floor/netspace

/turf/open/netspace
	parent_type = /turf/open/floor/netspace

/obj/effect/netspace
	name = "netspace effect"
	anchored = TRUE
	move_resist = INFINITY

/datum/net_access_key
	var/name = "net key"
	var/key_id
	var/access_flags = CY_NET_ACCESS_VIEW
	var/issuer
	var/expires_at = 0

/datum/net_access_key/New(new_id, new_name, new_flags, new_issuer, duration = 0)
	. = ..()
	key_id = new_id || "key_[REF(src)]"
	name = new_name || name
	access_flags = new_flags || access_flags
	issuer = new_issuer
	if(duration > 0)
		expires_at = world.time + duration

/datum/net_access_key/proc/is_valid()
	return !expires_at || world.time <= expires_at

/datum/net_access_key/proc/has_access(required_flags)
	if(!is_valid())
		return FALSE
	return (access_flags & required_flags) == required_flags

/datum/net_trace
	var/trace_level = 0
	var/last_source
	var/last_reason

/datum/net_trace/proc/add_trace(amount, source, reason)
	if(amount <= 0)
		return trace_level
	trace_level = clamp(trace_level + amount, 0, CY_NET_TRACE_BURN)
	last_source = source
	last_reason = reason
	return trace_level


/datum/netspace_cluster
	var/name = "network cluster"
	var/cluster_id
	var/area_type
	var/area_name = "Unknown Area"
	var/net_x = 1
	var/net_y = 1
	var/net_z
	var/list/nodes = list()
	var/obj/effect/netspace/proxy/proxy

/datum/netspace_cluster/New(new_area_type, new_area_name, new_x, new_y, new_z)
	. = ..()
	area_type = new_area_type
	area_name = new_area_name || area_name
	net_x = new_x
	net_y = new_y
	net_z = new_z
	cluster_id = "netcluster_[net_z]_[area_type]"
	name = SSnetspace.get_next_cluster_code(area_type, area_name)
	var/turf/T = locate(net_x, net_y, net_z)
	if(T)
		proxy = new(T, src)

/datum/netspace_cluster/Destroy()
	if(proxy)
		qdel(proxy)
		proxy = null
	for(var/datum/netspace_node/node as anything in nodes)
		if(node.cluster == src)
			node.cluster = null
	nodes = null
	return ..()

/datum/netspace_cluster/proc/add_node(datum/netspace_node/node)
	if(!node)
		return
	nodes |= node
	node.cluster = src
	update_proxy()

/datum/netspace_cluster/proc/remove_node(datum/netspace_node/node)
	if(!node)
		return
	nodes -= node
	if(node.cluster == src)
		node.cluster = null
	if(!length(nodes))
		SSnetspace.unregister_cluster(src)
		qdel(src)
		return
	update_proxy()

/datum/netspace_cluster/proc/update_proxy()
	if(!proxy)
		return
	proxy.name = "net node: [name]"
	proxy.desc = "A compact area node containing [length(nodes)] digital representation[length(nodes) == 1 ? "" : "s"]."
	proxy.color = get_cluster_color()
	proxy.update_appearance()

/datum/netspace_cluster/proc/get_cluster_color(mob/living/net_avatar/viewer)
	var/has_online = FALSE
	var/has_damaged = FALSE
	var/has_broken = FALSE
	for(var/datum/netspace_node/node as anything in nodes)
		if(!node)
			continue
		if(!node.is_online())
			has_broken = TRUE
			continue
		has_online = TRUE
		if(node.integrity < node.max_integrity)
			has_damaged = TRUE
	if(!has_online || has_broken && !has_online)
		return CY_NET_COLOR_NODE_BROKEN
	if(has_damaged || has_broken)
		return CY_NET_COLOR_NODE_DAMAGED
	// Personal Connect is avatar-local state. Do not tint the shared area node green/cyan for everyone.
	return CY_NET_COLOR_NODE_STABLE

/datum/netspace_cluster/proc/get_primary_node()
	for(var/datum/netspace_node/node as anything in nodes)
		if(node?.is_online())
			return node
	return length(nodes) ? nodes[1] : null

/datum/netspace_cluster/proc/get_node_choice_list()
	var/list/choices = list()
	for(var/datum/netspace_node/node as anything in nodes)
		if(!node)
			continue
		choices["[node.name] ([node.node_type]) [node.is_online() ? "online" : "offline"] #[REF(node)]"] = node
	return choices

/datum/netspace_cluster/proc/get_status_text(mob/living/net_avatar/avatar, include_links = TRUE)
	var/list/status = list()
	status += "[name] / [area_name]"
	status += "Representations: [length(nodes)]"
	for(var/datum/netspace_node/node as anything in nodes)
		if(!node)
			continue
		status += "- [node.name] ([node.node_type]) SEC [node.security]/[node.max_security] INT [node.integrity]/[node.max_integrity] TRACE [node.trace?.trace_level || 0] [node.is_online() ? "online" : "offline"]"
		if(include_links && length(node.linked_nodes))
			for(var/datum/netspace_node/linked_node as anything in node.linked_nodes)
				status += "  -> [linked_node.name] ([linked_node.node_type])"
	return status.Join("\n")

/datum/netspace_cluster/proc/apply_cluster_damage(amount, damage_type = PSYCHIC, mob/living/net_avatar/source)
	if(amount <= 0)
		return FALSE
	var/did_damage = FALSE
	for(var/datum/netspace_node/node as anything in nodes)
		if(node?.is_online())
			did_damage |= node.apply_net_damage(amount, damage_type, source)
	return did_damage

/datum/netspace_node
	var/name = "network node"
	var/node_id
	var/node_type = CY_NET_NODE_GENERIC
	var/atom/physical_ref
	var/datum/netspace_cluster/cluster
	var/security = CY_NET_SECURITY_BASIC
	var/max_security = CY_NET_SECURITY_BASIC
	var/integrity = 100
	var/max_integrity = 100
	var/list/access_keys = list()
	var/list/linked_nodes = list()
	var/list/available_actions = list()
	var/datum/net_trace/trace
	var/area_type
	var/area_name = "Unknown Area"
	var/net_x = 1
	var/net_y = 1
	var/net_z
	var/disabled = FALSE
	var/isolated = FALSE
	var/owner_organization
	var/last_net_attack_time = 0
	var/security_breached = FALSE
	var/integrity_restore_ready_time = 0

/datum/netspace_node/New(atom/source)
	. = ..()
	physical_ref = source
	trace = new
	if(source)
		name = source.name
		node_id = "node_[REF(source)]"
		var/area/A = get_area(source)
		if(A)
			area_type = A.type
			area_name = A.name
		refresh_position()
	SSnetspace.register_node(src)

/datum/netspace_node/Destroy()
	SSnetspace.unregister_node(src)
	if(cluster)
		var/datum/netspace_cluster/old_cluster = cluster
		cluster = null
		old_cluster.nodes -= src
		if(!length(old_cluster.nodes))
			SSnetspace.unregister_cluster(old_cluster)
			qdel(old_cluster)
		else
			old_cluster.update_proxy()
	physical_ref = null
	linked_nodes = null
	access_keys = null
	available_actions = null
	QDEL_NULL(trace)
	return ..()

/datum/netspace_node/proc/refresh_position()
	if(!physical_ref)
		return FALSE
	var/turf/net_turf = SSnetspace.get_net_turf_for_atom(physical_ref)
	if(!net_turf)
		return FALSE
	net_x = net_turf.x
	net_y = net_turf.y
	net_z = net_turf.z
	SSnetspace.assign_node_to_cluster(src)
	return TRUE

/datum/netspace_node/proc/is_online()
	if(disabled || isolated)
		return FALSE
	if(!physical_ref || QDELETED(physical_ref))
		return FALSE
	return physical_ref.cy_netspace_is_online()

/datum/netspace_node/proc/has_key_access(mob/living/net_avatar/avatar, required_flags)
	if(security <= CY_NET_SECURITY_OPEN)
		return TRUE
	if(!avatar)
		return FALSE
	var/required_key = physical_ref?.cy_get_net_key_id()
	for(var/datum/net_access_key/key as anything in avatar.net_keys)
		if(!key?.has_access(required_flags))
			continue
		if(!required_key || key.key_id == required_key || key.key_id == physical_ref?.cy_get_net_family_key_id())
			return TRUE
	for(var/datum/net_access_key/key as anything in access_keys)
		if(key?.has_access(required_flags))
			return TRUE
	return FALSE

/datum/netspace_node/proc/add_trace(amount, source, reason)
	return trace.add_trace(amount, source, reason)

/datum/netspace_node/proc/apply_net_damage(amount, damage_type = PSYCHIC, mob/living/net_avatar/source)
	if(amount <= 0 || !is_online())
		return FALSE
	last_net_attack_time = world.time
	add_trace(round(amount * 0.35), source, "net [damage_type] damage")
	if(security > CY_NET_SECURITY_OPEN)
		security = max(CY_NET_SECURITY_OPEN, security - amount)
		if(security <= CY_NET_SECURITY_OPEN)
			security = CY_NET_SECURITY_OPEN
			security_breached = TRUE
			grant_family_key(source)
		cluster?.update_proxy()
		return TRUE

	var/old_integrity_percent = get_integrity_percent()
	integrity = max(0, integrity - amount)
	var/new_integrity_percent = get_integrity_percent()
	if(old_integrity_percent > CY_NET_NODE_DAMAGE_EMI && new_integrity_percent <= CY_NET_NODE_DAMAGE_EMI)
		physical_ref?.cy_netspace_on_emi(source)
	if(old_integrity_percent > CY_NET_NODE_DAMAGE_GLITCH && new_integrity_percent <= CY_NET_NODE_DAMAGE_GLITCH)
		physical_ref?.cy_netspace_on_glitch(source)
	if(integrity <= 0)
		disabled = TRUE
		physical_ref?.cy_netspace_on_disabled(source)
	cluster?.update_proxy()
	return TRUE

/datum/netspace_node/proc/get_damage_percent()
	if(max_integrity <= 0)
		return 100
	return clamp(round(((max_integrity - integrity) / max_integrity) * 100), 0, 100)

/datum/netspace_node/proc/get_integrity_percent()
	if(max_integrity <= 0)
		return 0
	return clamp(round((integrity / max_integrity) * 100), 0, 100)

/datum/netspace_node/proc/grant_family_key(mob/living/net_avatar/avatar)
	if(!avatar || !physical_ref)
		return FALSE
	var/datum/net_access_key/key = physical_ref.cy_make_net_key(CY_NET_ACCESS_VIEW|CY_NET_ACCESS_USE|CY_NET_ACCESS_CONTROL)
	avatar.cy_remember_net_key(key)
	if(avatar.physical_body)
		avatar.physical_body.cy_remember_net_key(key)
	to_chat(avatar, span_notice("You capture a family key for [physical_ref.name]."))
	return TRUE

/datum/netspace_node/proc/process_recovery()
	if(last_net_attack_time && world.time >= last_net_attack_time + CY_NET_SECURITY_RECOVERY_DELAY)
		if(security < max_security)
			security = max_security
			security_breached = FALSE
			integrity_restore_ready_time = world.time + CY_NET_INTEGRITY_RECOVERY_DELAY
			cluster?.update_proxy()
		last_net_attack_time = 0
	if(integrity_restore_ready_time && world.time >= integrity_restore_ready_time && security >= max_security)
		if(integrity < max_integrity || disabled)
			integrity = max_integrity
			disabled = FALSE
			physical_ref?.cy_netspace_on_restored(src)
			cluster?.update_proxy()
		integrity_restore_ready_time = 0

/datum/netspace_node/proc/get_status_text(mob/living/net_avatar/avatar)
	var/list/status = list()
	status += "[name] ([node_type])"
	status += "Security: [security]/[max_security]"
	status += "Integrity: [integrity]/[max_integrity]"
	status += "Trace: [trace?.trace_level || 0]"
	status += "Online: [is_online() ? "yes" : "no"]"
	if(physical_ref)
		status += physical_ref.cy_netspace_status_text(avatar)
	return status.Join("\n")

/datum/netspace_node/proc/get_actions(mob/living/net_avatar/avatar)
	if(!physical_ref)
		return list()
	return physical_ref.cy_netspace_available_actions(avatar)

/datum/netspace_node/proc/execute_action(mob/living/net_avatar/avatar, action_id)
	if(!is_online())
		return FALSE
	if(!physical_ref)
		return FALSE
	return physical_ref.cy_netspace_execute_action(avatar, action_id)

/obj/effect/netspace/proxy
	name = "network node"
	desc = "A compact digital shell linked to nearby physical systems."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	color = "#55aaff"
	alpha = 180
	density = FALSE
	var/datum/netspace_cluster/cluster
	var/datum/netspace_node/selected_node

/obj/effect/netspace/proxy/Initialize(mapload, datum/netspace_cluster/new_cluster)
	. = ..()
	cluster = new_cluster
	if(cluster)
		name = "net node: [cluster.name]"
		selected_node = cluster.get_primary_node()

/obj/effect/netspace/proxy/Destroy()
	if(cluster?.proxy == src)
		cluster.proxy = null
	cluster = null
	selected_node = null
	return ..()

/obj/effect/netspace/proxy/examine(mob/user)
	. = ..()
	if(cluster)
		. += span_notice(cluster.get_status_text(istype(user, /mob/living/net_avatar) ? user : null, FALSE))

/obj/effect/netspace/proxy/proc/cy_handle_proxy_click(mob/living/net_avatar/avatar, list/modifiers)
	if(!avatar || !cluster)
		return TRUE
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		cy_middle_click_cluster(avatar)
		return TRUE
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(avatar.combat_mode)
			cy_attack_cluster(avatar)
		else
			cy_download_from_cluster(avatar)
		return TRUE
	if(avatar.combat_mode)
		cy_attack_selected_node(avatar)
		return TRUE
	cy_activate_cluster(avatar)
	return TRUE

/obj/effect/netspace/proxy/attack_hand(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		return cy_handle_proxy_click(user, modifiers)
	return TRUE

/obj/effect/netspace/proxy/attack_paw(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		return cy_handle_proxy_click(user, modifiers)
	return TRUE

/obj/effect/netspace/proxy/attack_hand_secondary(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		cy_handle_proxy_click(user, modifiers)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/netspace/proxy/attack_animal(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		return cy_handle_proxy_click(user, modifiers)
	return TRUE

/obj/effect/netspace/proxy/attack_basic_mob(mob/user, list/modifiers)
	. = ..()
	if(istype(user, /mob/living/net_avatar))
		return cy_handle_proxy_click(user, modifiers)
	return TRUE

/obj/effect/netspace/proxy/attack_animal_secondary(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		cy_handle_proxy_click(user, modifiers)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/effect/netspace/proxy/proc/cy_pick_node(mob/living/net_avatar/avatar, title = "Choose representation")
	if(!cluster || !length(cluster.nodes))
		return null
	var/list/choices = cluster.get_node_choice_list()
	if(!length(choices))
		return null
	var/choice = tgui_input_list(avatar, "Choose a digital representation inside [cluster.name].", title, choices)
	if(!choice)
		return null
	selected_node = choices[choice]
	return selected_node

/obj/effect/netspace/proxy/proc/cy_activate_cluster(mob/living/net_avatar/avatar)
	var/datum/netspace_node/node = cy_pick_node(avatar, "Netspace Representation")
	if(!node)
		to_chat(avatar, span_warning("The node is empty."))
		return
	var/list/actions = node.get_actions(avatar)
	if(!length(actions))
		to_chat(avatar, span_notice(node.get_status_text(avatar)))
		return
	var/action = tgui_input_list(avatar, node.get_status_text(avatar), "[node.name] actions", actions)
	if(!action)
		return
	if(!node.execute_action(avatar, action))
		to_chat(avatar, span_warning("The representation rejects the command. You need a matching key or open security."))

/obj/effect/netspace/proxy/proc/cy_attack_selected_node(mob/living/net_avatar/avatar)
	var/datum/netspace_node/node = cy_pick_node(avatar, "Attack Representation")
	if(!node)
		return
	node.apply_net_damage(avatar.net_power, PSYCHIC, avatar)
	avatar.personal_trace?.add_trace(4, node, "node attack")
	to_chat(avatar, span_warning("You strike [node.name]'s neural shell."))

/obj/effect/netspace/proxy/proc/cy_attack_cluster(mob/living/net_avatar/avatar)
	if(!cluster)
		return
	var/damage = max(1, round(avatar.net_power * CY_NET_CLUSTER_ATTACK_MULTIPLIER))
	cluster.apply_cluster_damage(damage, PSYCHIC, avatar)
	avatar.personal_trace?.add_trace(6, cluster, "area-node attack")
	to_chat(avatar, span_warning("You smear psychic disruption across [cluster.name]."))

/obj/effect/netspace/proxy/proc/cy_download_from_cluster(mob/living/net_avatar/avatar)
	if(!cluster)
		return
	var/downloaded = 0
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		if(!node?.is_online())
			continue
		if(node.security > CY_NET_SECURITY_OPEN)
			continue
		if(node.physical_ref?.cy_net_data <= 0)
			continue
		if(node.physical_ref.cy_download_net_data(avatar))
			downloaded++
	if(downloaded)
		to_chat(avatar, span_notice("You download [downloaded] net-data packet[downloaded == 1 ? "" : "s"] from unprotected systems in [cluster.name]."))
		cluster.update_proxy()
		return
	to_chat(avatar, span_warning("No unprotected systems with remaining data are available in this node."))

/obj/effect/netspace/proxy/proc/cy_middle_click_cluster(mob/living/net_avatar/avatar)
	if(!cluster)
		return
	if(!avatar.cy_has_connected_cluster(cluster))
		to_chat(avatar, span_warning("You need a personal Connect before routing demons through this node."))
		return
	// Neutral hook: demon spell/action layer may override/use this without netspace depending on demon classes.
	to_chat(avatar, span_notice("The node is connected and ready for demon routing."))

/obj/effect/netspace/proxy/proc/cy_show_cluster_overview(mob/living/net_avatar/avatar)
	to_chat(avatar, span_notice(cluster.get_status_text(avatar, TRUE)))
/proc/cy_netspace_get_or_create_node(atom/source, node_type = CY_NET_NODE_GENERIC, security = CY_NET_SECURITY_BASIC)
	if(!source)
		return null
	if(!source.cy_netspace_node)
		source.cy_netspace_node = new /datum/netspace_node(source)
	source.cy_netspace_node.node_type = node_type
	source.cy_netspace_node.security = security
	source.cy_netspace_node.max_security = max(source.cy_netspace_node.max_security, security)
	source.cy_netspace_node.available_actions = source.cy_netspace_available_actions(null)
	source.cy_netspace_node.refresh_position()
	return source.cy_netspace_node

/obj/effect/netspace/proxy/cy_is_netspace_target()
	return TRUE

/obj/effect/netspace/proxy/cy_get_netspace_security()
	var/datum/netspace_node/node = selected_node || cluster?.get_primary_node()
	return node ? node.security : CY_NET_SECURITY_OPEN

/obj/effect/netspace/proxy/cy_apply_netspace_damage(amount, damage_type = PSYCHIC, source)
	if(!cluster)
		return FALSE
	var/mob/living/net_avatar/avatar = source
	var/datum/netspace_node/node = selected_node || cluster.get_primary_node()
	if(node)
		return node.apply_net_damage(amount, damage_type, avatar)
	return FALSE

/obj/effect/netspace/proxy/cy_add_netspace_trace(amount, source, reason)
	if(!cluster)
		return FALSE
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		node?.add_trace(amount, source, reason)
	return TRUE

/obj/effect/netspace/proxy/cy_get_netspace_status(user)
	return cluster ? cluster.get_status_text(user, TRUE) : "Dead proxy."

/obj/effect/netspace/proxy/cy_get_netspace_actions(user)
	var/datum/netspace_node/node = selected_node || cluster?.get_primary_node()
	return node ? node.get_actions(user) : list()

/obj/effect/netspace/proxy/cy_execute_netspace_action(user, action_id)
	var/datum/netspace_node/node = selected_node || cluster?.get_primary_node()
	return node ? node.execute_action(user, action_id) : FALSE

/datum/netspace_cluster/proc/cy_raise_physical_alarm(mob/living/net_avatar/avatar)
	for(var/datum/netspace_node/node as anything in nodes)
		node?.physical_ref?.cy_netspace_raise_alarm(avatar, src)
	update_proxy()
