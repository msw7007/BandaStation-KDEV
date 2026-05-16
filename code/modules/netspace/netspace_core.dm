/area/netspace
	name = "Netspace"
	icon_state = "blue"
	requires_power = FALSE
	always_unpowered = FALSE
	default_gravity = STANDARD_GRAVITY
	ambient_buzz = null

/area/netspace/generated
	name = "Generated Netspace"

/turf/open/floor/netspace
	name = "netspace floor"
	desc = "A luminous compressed reflection of the city network."
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"
	color = "#2f74c0"
	light_range = 3
	light_power = 0.85
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

/datum/netspace_node
	var/name = "network representation"
	var/node_id
	var/node_type = CY_NET_NODE_GENERIC
	var/atom/physical_ref
	var/security = CY_NET_SECURITY_BASIC
	var/max_security = CY_NET_SECURITY_BASIC
	var/integrity = 100
	var/max_integrity = 100
	var/list/access_keys = list()
	var/list/available_actions = list()
	var/datum/net_trace/trace
	var/datum/netspace_cluster/cluster
	var/area_type
	var/area_name
	var/net_x = 1
	var/net_y = 1
	var/net_z
	var/disabled = FALSE
	var/isolated = FALSE
	var/owner_organization
	var/last_attack_time = 0
	var/security_restored_at = 0
	var/next_security_recovery_tick = 0
	var/damage_state = 0

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
		var/turf/net_turf = SSnetspace.get_net_turf_for_atom(source)
		if(net_turf)
			net_x = net_turf.x
			net_y = net_turf.y
			net_z = net_turf.z
	SSnetspace.register_node(src)

/datum/netspace_node/Destroy()
	SSnetspace.unregister_node(src)
	physical_ref = null
	access_keys = null
	available_actions = null
	cluster = null
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
	if(!cluster)
		SSnetspace.assign_node_to_cluster(src)
	else
		cluster.refresh_proxy_position()
	return TRUE

/datum/netspace_node/proc/is_online()
	if(disabled || isolated)
		return FALSE
	if(!physical_ref || QDELETED(physical_ref))
		return FALSE
	return physical_ref.cy_netspace_is_online()

/datum/netspace_node/proc/get_key_id()
	var/area_part = cluster ? cluster.cluster_id : "[area_type || "area"]"
	if(physical_ref)
		return physical_ref.cy_netspace_key_id(node_type, area_part)
	return "[area_part]_generic_[node_type]"

/datum/netspace_node/proc/has_key_access(mob/living/net_avatar/avatar, required_flags)
	if(security <= CY_NET_SECURITY_OPEN)
		return TRUE
	if(!avatar)
		return FALSE
	var/key_id = get_key_id()
	if(avatar.cy_has_net_key(key_id))
		return TRUE
	for(var/datum/net_access_key/key as anything in avatar.net_keys)
		if(key?.key_id == key_id && key.has_access(required_flags))
			return TRUE
	for(var/datum/net_access_key/key as anything in access_keys)
		if(key?.key_id == key_id && key.has_access(required_flags))
			return TRUE
	return FALSE

/datum/netspace_node/proc/can_interact(mob/living/net_avatar/avatar, required_flags = CY_NET_ACCESS_USE)
	if(!is_online())
		return FALSE
	return has_key_access(avatar, required_flags)

/datum/netspace_node/proc/can_download(mob/living/net_avatar/avatar)
	if(!is_online())
		return FALSE
	return security <= CY_NET_SECURITY_OPEN

/datum/netspace_node/proc/add_trace(amount, source, reason)
	return trace.add_trace(amount, source, reason)

/datum/netspace_node/proc/process_recovery()
	if(!physical_ref || QDELETED(physical_ref))
		return
	if(isolated)
		return
	if(security < max_security && world.time - last_attack_time >= CY_NET_SECURITY_REGEN_DELAY)
		if(!next_security_recovery_tick)
			next_security_recovery_tick = world.time
		if(world.time >= next_security_recovery_tick)
			security = min(max_security, security + CY_NET_SECURITY_REGEN_STEP_AMOUNT)
			next_security_recovery_tick = world.time + CY_NET_SECURITY_REGEN_STEP_TIME
			if(security >= max_security)
				security_restored_at = world.time
			update_cluster_color()
	if(security >= max_security && integrity < max_integrity && security_restored_at && world.time - security_restored_at >= CY_NET_DAMAGE_REPAIR_DELAY)
		integrity = max_integrity
		disabled = FALSE
		damage_state = 0
		physical_ref?.cy_netspace_on_damage_repaired()
		update_cluster_color()

/datum/netspace_node/proc/apply_net_damage(amount, mob/living/net_avatar/source)
	if(amount <= 0 || !is_online())
		return FALSE
	last_attack_time = world.time
	security_restored_at = 0
	next_security_recovery_tick = 0
	add_trace(max(1, round(amount * 0.35)), source, "net attack")
	if(security > CY_NET_SECURITY_OPEN)
		security = max(CY_NET_SECURITY_OPEN, security - amount)
		if(security <= CY_NET_SECURITY_OPEN)
			grant_key_to_attacker(source)
		update_cluster_color()
		return TRUE
	integrity = max(0, integrity - amount)
	if(physical_ref)
		physical_ref.cy_net_integrity = integrity
	apply_damage_stage(source)
	update_cluster_color()
	return TRUE

/datum/netspace_node/proc/apply_damage_stage(mob/living/net_avatar/source)
	var/percent = max_integrity ? (integrity / max_integrity) : 0
	if(percent <= 0)
		if(damage_state < 3)
			damage_state = 3
			disabled = TRUE
			physical_ref?.cy_netspace_on_disabled(source)
		return
	if(percent <= 0.33)
		if(damage_state < 2)
			damage_state = 2
			physical_ref?.cy_netspace_on_emi(source)
		return
	if(percent <= 0.66)
		if(damage_state < 1)
			damage_state = 1
			physical_ref?.cy_netspace_on_emagged(source)

/datum/netspace_node/proc/grant_key_to_attacker(mob/living/net_avatar/avatar)
	if(!avatar)
		return FALSE
	var/key_id = get_key_id()
	var/key_name = physical_ref ? physical_ref.cy_netspace_key_name(node_type) : "[node_type] key"
	return avatar.cy_grant_net_key(key_id, key_name)

/datum/netspace_node/proc/download_data(mob/living/net_avatar/avatar)
	if(!avatar || !physical_ref)
		return FALSE
	if(!can_download(avatar))
		to_chat(avatar, span_warning("The representation is still protected."))
		return FALSE
	if(!physical_ref.cy_netspace_download_data(avatar, src))
		to_chat(avatar, span_warning("No usable data remains in [name]."))
		return FALSE
	grant_key_to_attacker(avatar)
	add_trace(2, avatar, "data extraction")
	return TRUE

/datum/netspace_node/proc/update_cluster_color()
	if(cluster)
		cluster.update_color()

/datum/netspace_node/proc/get_status_text(mob/living/net_avatar/avatar)
	var/list/status = list()
	status += "[name] ([node_type])"
	status += "Protection: [security]/[max_security]"
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
	if(!can_interact(avatar, CY_NET_ACCESS_USE))
		add_trace(5, avatar, "denied action")
		return FALSE
	if(!physical_ref)
		return FALSE
	return physical_ref.cy_netspace_execute_action(avatar, action_id)

/datum/netspace_cluster
	var/name = "network area"
	var/cluster_id
	var/area_type
	var/area_name
	var/net_x = 1
	var/net_y = 1
	var/net_z
	var/list/nodes = list()
	var/obj/effect/netspace/proxy/proxy
	var/greek_code = "Α-Α-Α"

/datum/netspace_cluster/New(new_area_type, new_area_name, new_net_x = 1, new_net_y = 1, new_net_z)
	. = ..()
	area_type = new_area_type
	net_x = new_net_x
	net_y = new_net_y
	net_z = new_net_z
	greek_code = SSnetspace.next_greek_code()
	cluster_id = "[area_type]"
	name = "[greek_code] / [new_area_name || area_type || "AREA"]"

/datum/netspace_cluster/Destroy()
	for(var/datum/netspace_node/node as anything in nodes)
		node.cluster = null
	nodes = null
	if(proxy)
		qdel(proxy)
		proxy = null
	return ..()

/datum/netspace_cluster/proc/add_node(datum/netspace_node/node)
	if(!node)
		return
	nodes |= node
	node.cluster = src
	refresh_proxy_position()
	update_color()

/datum/netspace_cluster/proc/remove_node(datum/netspace_node/node, refresh_cluster = TRUE)
	nodes -= node
	if(node?.cluster == src)
		node.cluster = null
	if(!length(nodes))
		qdel(src)
		return
	if(refresh_cluster)
		refresh_proxy_position()
		update_color()

/datum/netspace_cluster/proc/refresh_proxy_position()
	var/datum/netspace_node/first_node = length(nodes) ? nodes[1] : null
	if(!first_node?.physical_ref)
		return FALSE
	var/turf/T = SSnetspace.get_net_turf_for_atom(first_node.physical_ref)
	if(!T)
		return FALSE
	if(!proxy)
		proxy = new(T, src)
	else if(proxy.loc != T)
		proxy.forceMove(T)
	proxy.name = name
	return TRUE

/datum/netspace_cluster/proc/is_personally_connected(mob/living/net_avatar/avatar)
	return avatar?.cy_is_connected_to_cluster(src)

/datum/netspace_cluster/proc/get_visible_color(mob/living/net_avatar/avatar)
	if(avatar && is_personally_connected(avatar))
		return CY_NET_CLUSTER_COLOR_CONNECTED
	if(all_broken())
		return CY_NET_CLUSTER_COLOR_BROKEN
	if(has_damaged_components())
		return CY_NET_CLUSTER_COLOR_DAMAGED
	return CY_NET_CLUSTER_COLOR_NORMAL

/datum/netspace_cluster/proc/update_color()
	if(proxy)
		proxy.color = get_visible_color(null)

/datum/netspace_cluster/proc/refresh_for_avatar(mob/living/net_avatar/avatar)
	if(proxy && avatar?.client)
		proxy.color = get_visible_color(avatar)

/datum/netspace_cluster/proc/has_damaged_components()
	for(var/datum/netspace_node/node as anything in nodes)
		if(node.integrity < node.max_integrity)
			return TRUE
	return FALSE

/datum/netspace_cluster/proc/all_broken()
	if(!length(nodes))
		return FALSE
	for(var/datum/netspace_node/node as anything in nodes)
		if(node.integrity > 0 && node.is_online())
			return FALSE
	return TRUE

/datum/netspace_cluster/proc/get_node_choices()
	var/list/choices = list()
	for(var/datum/netspace_node/node as anything in nodes)
		if(!node.physical_ref || QDELETED(node.physical_ref))
			continue
		choices["[node.name] ([node.node_type])"] = node
	return choices

/datum/netspace_cluster/proc/choose_node(mob/living/net_avatar/avatar, title = "Choose representation")
	var/list/choices = get_node_choices()
	if(!length(choices))
		return null
	var/chosen = tgui_input_list(avatar, title, name, choices)
	if(!chosen)
		return null
	return choices[chosen]

/datum/netspace_cluster/proc/left_click(mob/living/net_avatar/avatar)
	if(!avatar)
		return TRUE
	var/datum/netspace_node/node = choose_node(avatar, avatar.combat_mode ? "Attack representation" : "Use representation")
	if(!node)
		return TRUE
	if(avatar.combat_mode)
		node.apply_net_damage(CY_NET_ATTACK_FOCUSED, avatar)
		to_chat(avatar, span_warning("You focus a psychic strike into [node.name]."))
		return TRUE
	var/list/actions = node.get_actions(avatar)
	if(!length(actions))
		to_chat(avatar, span_notice(node.get_status_text(avatar)))
		return TRUE
	var/action = tgui_input_list(avatar, "Choose action", node.name, actions)
	if(!action)
		return TRUE
	if(!node.execute_action(avatar, action))
		to_chat(avatar, span_warning("The representation rejects the command. You need a valid key or lowered protection."))
	return TRUE

/datum/netspace_cluster/proc/right_click(mob/living/net_avatar/avatar)
	if(!avatar)
		return TRUE
	if(avatar.combat_mode)
		var/list/valid_nodes = list()
		for(var/datum/netspace_node/node as anything in nodes)
			if(node?.is_online())
				valid_nodes += node
		var/smear_damage = max(CY_NET_ATTACK_SMEAR_MIN, round(CY_NET_ATTACK_FOCUSED / max(1, length(valid_nodes))))
		var/hit_count = 0
		for(var/datum/netspace_node/node as anything in valid_nodes)
			if(node.apply_net_damage(smear_damage, avatar))
				hit_count++
		to_chat(avatar, span_warning("You smear [smear_damage] psychic damage across [hit_count] representations."))
		return TRUE
	var/downloaded = 0
	for(var/datum/netspace_node/node as anything in nodes)
		if(!node.can_download(avatar))
			continue
		if(node.download_data(avatar))
			downloaded++
	if(downloaded)
		to_chat(avatar, span_notice("You download [downloaded] net-data packet[downloaded == 1 ? "" : "s"] from exposed representations in [name]."))
	else
		to_chat(avatar, span_warning("No exposed data is available in [name]."))
	return TRUE

/datum/netspace_cluster/proc/middle_click(mob/living/net_avatar/avatar)
	if(!avatar)
		return TRUE
	if(!is_personally_connected(avatar))
		to_chat(avatar, span_warning("You need a personal Connect to use demons through this node."))
		return TRUE
	if(hascall(avatar, "cy_fire_prepared_demon"))
		call(avatar, "cy_fire_prepared_demon")(proxy)
	else
		SEND_SIGNAL(avatar, COMSIG_MOB_MIDDLECLICKON, proxy)
	return TRUE

/obj/effect/netspace/proxy
	name = "network area node"
	desc = "A compact digital node containing multiple representations in this area."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	color = CY_NET_CLUSTER_COLOR_NORMAL
	alpha = 190
	var/datum/netspace_cluster/cluster

/obj/effect/netspace/proxy/Initialize(mapload, datum/netspace_cluster/new_cluster)
	. = ..()
	cluster = new_cluster
	if(cluster)
		name = cluster.name
		color = cluster.get_visible_color(null)

/obj/effect/netspace/proxy/Destroy()
	if(cluster?.proxy == src)
		cluster.proxy = null
	cluster = null
	return ..()

/obj/effect/netspace/proxy/examine(mob/user)
	. = ..()
	if(cluster)
		. += span_notice("[cluster.name]: [length(cluster.nodes)] linked representations.")

/obj/effect/netspace/proxy/proc/cy_handle_net_left(mob/living/net_avatar/avatar)
	return cluster?.left_click(avatar)

/obj/effect/netspace/proxy/proc/cy_handle_net_right(mob/living/net_avatar/avatar)
	return cluster?.right_click(avatar)

/obj/effect/netspace/proxy/proc/cy_handle_net_middle(mob/living/net_avatar/avatar)
	return cluster?.middle_click(avatar)

/obj/effect/netspace/proxy/attack_hand(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		var/mob/living/net_avatar/avatar = user
		return cy_handle_net_left(avatar)
	return ..()

/obj/effect/netspace/proxy/attack_paw(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		var/mob/living/net_avatar/avatar = user
		return cy_handle_net_left(avatar)
	return ..()

/obj/effect/netspace/proxy/attack_animal(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		var/mob/living/net_avatar/avatar = user
		return cy_handle_net_left(avatar)
	return ..()

/obj/effect/netspace/proxy/attack_animal_secondary(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		var/mob/living/net_avatar/avatar = user
		cy_handle_net_right(avatar)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/effect/netspace/proxy/attack_hand_secondary(mob/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		var/mob/living/net_avatar/avatar = user
		cy_handle_net_right(avatar)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/effect/netspace/proxy/cy_is_netspace_target()
	return TRUE

/obj/effect/netspace/proxy/cy_get_netspace_status(user)
	return cluster ? "[cluster.name]: [length(cluster.nodes)] representations." : "Dead proxy."


/obj/effect/netspace/proxy/cy_apply_netspace_damage(amount, source)
	if(!cluster || amount <= 0)
		return FALSE
	var/hit_count = 0
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		if(node.apply_net_damage(amount, source))
			hit_count++
	return hit_count > 0

/obj/effect/netspace/proxy/cy_add_netspace_trace(amount, source, reason)
	if(!cluster || amount <= 0)
		return FALSE
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		node.add_trace(amount, source, reason)
	return TRUE

/obj/effect/netspace/proxy/cy_get_netspace_actions(user)
	var/list/actions = list()
	if(!cluster)
		return actions
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		var/list/node_actions = node.get_actions(user)
		for(var/action_id in node_actions)
			actions += "[node.node_id]|[action_id]"
	return actions

/obj/effect/netspace/proxy/cy_execute_netspace_action(user, action_id)
	if(!cluster || !action_id)
		return FALSE
	var/list/parts = splittext("[action_id]", "|")
	if(length(parts) < 2)
		return FALSE
	var/target_node_id = parts[1]
	var/target_action = parts[2]
	for(var/datum/netspace_node/node as anything in cluster.nodes)
		if(node.node_id == target_node_id)
			return node.execute_action(user, target_action)
	return FALSE

/datum/netspace_cluster/proc/cy_alert_all(mob/living/net_avatar/avatar, reason = "network intrusion")
	for(var/datum/netspace_node/node as anything in nodes)
		node.physical_ref?.cy_netspace_alert(avatar, reason)
	return TRUE

/proc/cy_netspace_get_or_create_node(atom/source, node_type = CY_NET_NODE_GENERIC, security = null)
	if(!source)
		return null
	if(!source.cy_netspace_node)
		source.cy_netspace_node = new /datum/netspace_node(source)
	source.cy_netspace_node.node_type = node_type
	if(!isnull(security))
		source.cy_netspace_node.security = security
		source.cy_netspace_node.max_security = max(source.cy_netspace_node.max_security, security)
	source.cy_netspace_node.available_actions = source.cy_netspace_available_actions(null)
	source.cy_netspace_node.refresh_position()
	return source.cy_netspace_node

