/mob/living/net_avatar
	name = "net avatar"
	desc = "A digital body in the city network."
	incorporeal_move = INCORPOREAL_MOVE_BASIC
	move_resist = INFINITY
	density = FALSE
	color = CY_NET_COLOR_ACTIVE
	/// Net avatars still pass through some generic object-attack code.
	/// Declare these vars locally instead of relying on basic-mob fields.
	/// In netspace, default direct attacks are psychic disruption, not brute hits.
	var/obj_damage = 8
	melee_damage_lower = 1
	melee_damage_upper = 3
	var/melee_damage_type = PSYCHIC
	var/environment_smash = ENVIRONMENT_SMASH_NONE
	var/armour_penetration = 0

	var/avatar_mode = CY_NET_AVATAR_ACTIVE
	var/mob/living/physical_body
	var/atom/anchor_ref
	var/last_synced_physical_x = 0
	var/last_synced_physical_y = 0
	var/last_synced_physical_z = 0
	var/list/net_keys = list()
	var/net_data = 0
	var/net_power = 10
	var/net_stealth = 0
	var/datum/net_trace/personal_trace
	var/list/connected_clusters = list()
	var/list/connected_cluster_images = list()
	var/datum/netspace_cluster/connecting_cluster
	var/connect_action_until = 0
	var/returning = FALSE

/mob/living/net_avatar/Initialize(mapload)
	. = ..()
	personal_trace = new
	SSnetspace.register_avatar(src)
	update_net_color()

/mob/living/net_avatar/Destroy()
	SSnetspace.unregister_avatar(src)
	if(client && physical_body && !QDELETED(physical_body))
		client.mob = physical_body
	physical_body = null
	anchor_ref = null
	net_keys = null
	connected_clusters = null
	connecting_cluster = null
	QDEL_NULL(personal_trace)
	return ..()

/mob/living/net_avatar/proc/setup_avatar(mob/living/body, mode = CY_NET_AVATAR_ACTIVE, atom/anchor)
	physical_body = body
	avatar_mode = mode
	anchor_ref = anchor || body
	if(body)
		last_synced_physical_x = body.x
		last_synced_physical_y = body.y
		last_synced_physical_z = body.z
	update_net_color()

/mob/living/net_avatar/proc/update_net_color()
	switch(avatar_mode)
		if(CY_NET_AVATAR_ENGRAM)
			color = CY_NET_COLOR_ENGRAM
		if(CY_NET_AVATAR_ALTERNATIVE)
			color = CY_NET_COLOR_ALTERNATIVE
		if(CY_NET_AVATAR_MIRROR)
			color = CY_NET_COLOR_MIRROR
		else
			color = CY_NET_COLOR_ACTIVE

/mob/living/net_avatar/cy_remember_net_key(datum/net_access_key/key)
	if(!key)
		return FALSE
	if(!net_keys)
		net_keys = list()
	for(var/datum/net_access_key/existing as anything in net_keys)
		if(existing.key_id == key.key_id)
			return TRUE
	net_keys += key
	return TRUE

/mob/living/net_avatar/proc/cy_clear_connected_cluster_images()
	if(client && connected_cluster_images)
		for(var/image/I as anything in connected_cluster_images)
			client.images -= I
	connected_cluster_images = list()

/mob/living/net_avatar/proc/cy_refresh_connected_cluster_images()
	cy_clear_connected_cluster_images()
	if(!client)
		return
	cy_prune_connected_clusters(FALSE)
	for(var/datum/netspace_cluster/cluster as anything in connected_clusters)
		if(!cluster?.proxy)
			continue
		var/image/I = image(cluster.proxy.icon, cluster.proxy, cluster.proxy.icon_state)
		I.color = CY_NET_COLOR_NODE_CONNECTED
		I.alpha = 220
		I.layer = cluster.proxy.layer + 0.1
		connected_cluster_images += I
		client.images += I

/mob/living/net_avatar/proc/cy_is_netspace_actor()
	return TRUE

/mob/living/net_avatar/cy_is_netspace_target()
	return TRUE

/mob/living/net_avatar/cy_get_netspace_security()
	return CY_NET_SECURITY_BASIC

/mob/living/net_avatar/cy_apply_netspace_damage(amount, damage_type = CY_NET_DAMAGE_ATTACK, source)
	adjust_psychic_loss(max(0, round(amount * 0.25)))
	if(personal_trace)
		personal_trace.add_trace(max(1, round(amount * 0.25)), source, "avatar hit")
	return TRUE

/mob/living/net_avatar/cy_add_netspace_trace(amount, source, reason)
	if(personal_trace)
		personal_trace.add_trace(amount, source, reason)
	return TRUE

/mob/living/net_avatar/cy_get_netspace_status(user)
	return "Avatar mode: [avatar_mode]. Data: [net_data]. Trace: [personal_trace ? personal_trace.trace_level : 0]."

/mob/living/net_avatar/proc/cy_get_net_data()
	return net_data

/mob/living/net_avatar/proc/cy_set_net_data(amount)
	net_data = max(0, amount)
	return TRUE

/mob/living/net_avatar/proc/netspace_process(seconds_per_tick)
	if(avatar_mode == CY_NET_AVATAR_MIRROR)
		process_mirror_sync()
	else
		process_distance_feedback()

/mob/living/net_avatar/proc/process_mirror_sync()
	if(!physical_body || QDELETED(physical_body))
		qdel(src)
		return
	if(get_dist(locate(last_synced_physical_x, last_synced_physical_y, last_synced_physical_z), physical_body) < CY_NETSPACE_SCALE)
		return
	var/turf/net_turf = SSnetspace.get_net_turf_for_atom(physical_body)
	if(net_turf)
		forceMove(net_turf)
		last_synced_physical_x = physical_body.x
		last_synced_physical_y = physical_body.y
		last_synced_physical_z = physical_body.z

/mob/living/net_avatar/proc/process_distance_feedback()
	if(avatar_mode == CY_NET_AVATAR_ENGRAM)
		process_engram_distance()
		return
	if(!physical_body || QDELETED(physical_body))
		qdel(src)
		return
	var/distance = cy_get_best_link_distance()
	if(isnull(distance) || distance <= CY_NET_DISTANCE_SAFE)
		return
	var/excess = distance - CY_NET_DISTANCE_SAFE
	if(prob(excess * 10))
		cy_netspace_feedback(excess)
	if(distance > CY_NET_DISTANCE_BRAIN_BURN)
		cy_netspace_brain_burn(distance)

/mob/living/net_avatar/proc/cy_get_best_link_distance()
	var/best_distance
	var/turf/body_net_turf = SSnetspace.get_net_turf_for_atom(physical_body)
	if(body_net_turf && z == body_net_turf.z)
		best_distance = get_dist(src, body_net_turf)
	cy_prune_connected_clusters()
	for(var/datum/netspace_cluster/cluster as anything in connected_clusters)
		if(!cluster?.proxy || cluster.proxy.z != z)
			continue
		var/cluster_distance = get_dist(src, cluster.proxy)
		if(isnull(best_distance) || cluster_distance < best_distance)
			best_distance = cluster_distance
	return best_distance

/mob/living/net_avatar/proc/cy_prune_connected_clusters(refresh_images = TRUE)
	if(!connected_clusters)
		connected_clusters = list()
	var/changed = FALSE
	for(var/datum/netspace_cluster/cluster as anything in connected_clusters.Copy())
		var/expires_at = connected_clusters[cluster]
		if(world.time > expires_at || QDELETED(cluster))
			connected_clusters.Remove(cluster)
			changed = TRUE
	if(changed && refresh_images)
		cy_refresh_connected_cluster_images()

/mob/living/net_avatar/proc/cy_has_connected_cluster(datum/netspace_cluster/cluster)
	if(!cluster)
		return FALSE
	cy_prune_connected_clusters()
	return connected_clusters[cluster] && world.time <= connected_clusters[cluster]

/mob/living/net_avatar/proc/cy_is_connecting_to_cluster(datum/netspace_cluster/cluster)
	return connecting_cluster == cluster && world.time <= connect_action_until

/mob/living/net_avatar/proc/cy_connect_to_cluster(datum/netspace_cluster/cluster)
	if(!cluster)
		to_chat(src, span_warning("No node is close enough."))
		return FALSE
	if(cy_has_connected_cluster(cluster))
		to_chat(src, span_notice("You are already connected to [cluster.name]."))
		return TRUE
	var/connect_time = combat_mode ? CY_NET_CONNECT_COMBAT_TIME : CY_NET_CONNECT_TIME
	connecting_cluster = cluster
	connect_action_until = world.time + connect_time
	if(combat_mode)
		cluster.cy_raise_physical_alarm(src)
	to_chat(src, span_notice("Connecting to [cluster.name]..."))
	if(!do_after(src, connect_time, target = cluster.proxy))
		if(connecting_cluster == cluster)
			connecting_cluster = null
			connect_action_until = 0
		to_chat(src, span_warning("Connection interrupted."))
		return FALSE
	if(!connected_clusters)
		connected_clusters = list()
	connected_clusters[cluster] = world.time + CY_NET_CONNECT_DURATION
	if(connecting_cluster == cluster)
		connecting_cluster = null
		connect_action_until = 0
	cy_refresh_connected_cluster_images()
	to_chat(src, span_notice("Connected to [cluster.name] for five minutes."))
	return TRUE

/mob/living/net_avatar/proc/process_engram_distance()
	if(!anchor_ref || QDELETED(anchor_ref))
		return
	var/turf/anchor_net_turf = SSnetspace.get_net_turf_for_atom(anchor_ref)
	if(!anchor_net_turf || z != anchor_net_turf.z)
		return
	var/distance = get_dist(src, anchor_net_turf)
	if(distance > CY_NET_ENGRAM_SAFE_DISTANCE)
		adjust_psychic_loss(2)
		to_chat(src, span_warning("Your engram frays outside its anchor range."))

/mob/living/net_avatar/proc/cy_netspace_feedback(excess)
	to_chat(src, span_warning("Distance noise claws at your deck and implants."))
	if(physical_body)
		physical_body.cy_netspace_on_feedback(src, excess)

/mob/living/net_avatar/proc/cy_netspace_brain_burn(distance)
	to_chat(src, span_userdanger("The link burns too far from your body!"))
	if(physical_body)
		physical_body.cy_netspace_on_brain_burn(src, distance)

/mob/living/net_avatar/proc/return_to_body()
	if(returning)
		return
	returning = TRUE
	if(client && physical_body && !QDELETED(physical_body))
		client.mob = physical_body
	qdel(src)


/mob/living/net_avatar/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	if(istype(attack_target, /obj/effect/netspace/proxy))
		var/obj/effect/netspace/proxy/proxy = attack_target
		proxy.cy_handle_proxy_click(src, modifiers)
		return TRUE
	return ..()

/mob/living/net_avatar/resolve_right_click_attack(atom/target, list/modifiers)
	if(istype(target, /obj/effect/netspace/proxy))
		var/obj/effect/netspace/proxy/proxy = target
		proxy.cy_handle_proxy_click(src, modifiers)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/mob/living/net_avatar/verb/leave_netspace()
	set name = "Leave Netspace"
	set category = "Netspace"
	return_to_body()

/mob/living/net_avatar/verb/connect_net_node()
	set name = "Connect"
	set category = "Netspace"
	var/list/targets = list()
	for(var/obj/effect/netspace/proxy/proxy in view(1, src))
		if(proxy.cluster && length(proxy.cluster.nodes))
			targets[proxy.cluster.name] = proxy.cluster
	if(!length(targets))
		to_chat(src, span_warning("No node is close enough."))
		return
	var/choice = tgui_input_list(src, "Connect to which area node?", "Connect", targets)
	if(!choice)
		return
	cy_connect_to_cluster(targets[choice])

/proc/cy_enter_netspace(mob/living/user, atom/anchor, mode = CY_NET_AVATAR_ACTIVE)
	if(!user?.client)
		return null
	var/turf/net_turf = SSnetspace.get_net_turf_for_atom(anchor || user)
	if(!net_turf)
		to_chat(user, span_warning("The local network has no mapped netspace."))
		return null
	var/mob/living/net_avatar/avatar = new(net_turf)
	avatar.setup_avatar(user, mode, anchor || user)
	avatar.name = "[user.name]'s avatar"
	avatar.net_keys = user.cy_collect_net_keys()
	user.client.mob = avatar
	return avatar
