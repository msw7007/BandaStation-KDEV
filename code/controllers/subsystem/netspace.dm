SUBSYSTEM_DEF(netspace)
	name = "Cyberpunk Netspace"
	wait = 1 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	runlevels = RUNLEVEL_LOBBY | RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	ss_flags = SS_BACKGROUND

	var/list/active_avatars = list()
	var/list/active_projections = list()
	var/next_projection_scan = 0
	var/list/registered_nodes = list()
	var/list/area_nodes = list()
	var/list/net_clusters = list()
	var/list/cluster_codes_by_area = list()
	var/next_cluster_code = 1
	var/list/net_z_by_physical_z = list()
	var/datum/turf_reservation/net_reservation
	var/city_net_z
	var/default_objects_registered = FALSE
	var/default_object_registration_queue_built = FALSE
	var/list/default_object_registration_queue = list()
	var/netspace_prewarm_queue_built = FALSE
	var/netspace_prewarm_finished = FALSE
	var/list/netspace_prewarm_queue = list()
	var/lobby_full_floor_finished = FALSE
	var/list/lobby_full_floor_z_queue = list()
	var/list/lobby_full_floor_progress = list()

/datum/controller/subsystem/netspace/Initialize()
	ensure_city_net_z()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/netspace/fire(resumed = FALSE)
	for(var/mob/living/net_avatar/avatar as anything in active_avatars.Copy())
		if(QDELETED(avatar))
			active_avatars -= avatar
			continue
		avatar.netspace_process(wait / 10)

	for(var/obj/effect/netspace/projection/projection as anything in active_projections.Copy())
		if(QDELETED(projection))
			active_projections -= projection
			continue
		projection.cy_process_projection(wait / 10)

	if(world.time >= next_projection_scan)
		process_netspace_projections()
		next_projection_scan = world.time + CY_NET_PROJECTION_SCAN_INTERVAL

	for(var/datum/netspace_node/node as anything in registered_nodes.Copy())
		if(QDELETED(node))
			registered_nodes -= node
			continue
		node.process_recovery()

	if(SSticker && SSticker.current_state <= GAME_STATE_PREGAME)
		process_lobby_netspace_build()

/datum/controller/subsystem/netspace/stat_entry(msg)
	var/ready_text = cy_lobby_netspace_ready() ? "Y" : "N"
	msg = "Avatars:[length(active_avatars)] Proj:[length(active_projections)] Nodes:[length(registered_nodes)] Clusters:[length(net_clusters)] Ready:[ready_text]"
	return ..()


/datum/controller/subsystem/netspace/proc/register_projection(obj/effect/netspace/projection/projection)
	if(!projection)
		return
	active_projections |= projection

/datum/controller/subsystem/netspace/proc/unregister_projection(obj/effect/netspace/projection/projection)
	if(!projection)
		return
	active_projections -= projection

/datum/controller/subsystem/netspace/proc/process_netspace_projections()
	for(var/mob/living/living_mob in GLOB.alive_mob_list)
		if(QDELETED(living_mob) || istype(living_mob, /mob/living/net_avatar))
			continue
		if(living_mob.cy_has_netspace_projection_prereqs())
			living_mob.cy_ensure_netspace_projection()
		else
			living_mob.cy_remove_netspace_projection()

/datum/controller/subsystem/netspace/proc/register_avatar(mob/living/net_avatar/avatar)
	if(!avatar)
		return
	active_avatars |= avatar

/datum/controller/subsystem/netspace/proc/unregister_avatar(mob/living/net_avatar/avatar)
	if(!avatar)
		return
	active_avatars -= avatar

/datum/controller/subsystem/netspace/proc/register_node(datum/netspace_node/node)
	if(!node)
		return
	registered_nodes |= node
	if(node.area_type)
		var/list/nodes = area_nodes[node.area_type]
		if(!nodes)
			nodes = list()
			area_nodes[node.area_type] = nodes
		nodes |= node

/datum/controller/subsystem/netspace/proc/unregister_node(datum/netspace_node/node)
	if(!node)
		return
	registered_nodes -= node
	if(node.area_type && area_nodes[node.area_type])
		var/list/nodes = area_nodes[node.area_type]
		nodes -= node

/datum/controller/subsystem/netspace/proc/get_cluster_key(area_type, net_x, net_y, net_z)
	// Netspace is a single compressed Z-layer. Area nodes merge by physical area type across all physical Z-levels.
	return "[area_type]"

/datum/controller/subsystem/netspace/proc/register_cluster(datum/netspace_cluster/cluster)
	if(!cluster)
		return
	net_clusters[get_cluster_key(cluster.area_type, cluster.net_x, cluster.net_y, cluster.net_z)] = cluster

/datum/controller/subsystem/netspace/proc/unregister_cluster(datum/netspace_cluster/cluster)
	if(!cluster)
		return
	var/key = get_cluster_key(cluster.area_type, cluster.net_x, cluster.net_y, cluster.net_z)
	if(net_clusters[key] == cluster)
		net_clusters.Remove(key)

/datum/controller/subsystem/netspace/proc/assign_node_to_cluster(datum/netspace_node/node)
	if(!node || !node.net_z)
		return null
	if(node.cluster)
		node.cluster.remove_node(node)
	var/key = get_cluster_key(node.area_type, node.net_x, node.net_y, node.net_z)
	var/datum/netspace_cluster/cluster = net_clusters[key]
	if(!cluster)
		cluster = new /datum/netspace_cluster(node.area_type, node.area_name, node.net_x, node.net_y, node.net_z)
		register_cluster(cluster)
	cluster.add_node(node)
	return cluster


/datum/controller/subsystem/netspace/proc/next_greek_code()
	return cy_greek_triplet(next_cluster_code++)

/datum/controller/subsystem/netspace/proc/get_next_cluster_code(area_type, area_name)
	var/code = cluster_codes_by_area[area_type]
	if(!code)
		code = cy_greek_triplet(next_cluster_code++)
		cluster_codes_by_area[area_type] = code
	return "[code] / [area_name || "AREA"]"

/datum/controller/subsystem/netspace/proc/cy_greek_triplet(index)
	var/static/list/letters = list("Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ", "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω")
	var/base = length(letters)
	var/number = max(1, index) - 1
	var/a = round(number / (base * base)) % base
	var/b = round(number / base) % base
	var/c = number % base
	return "[letters[a + 1]]-[letters[b + 1]]-[letters[c + 1]]"

/datum/controller/subsystem/netspace/proc/ensure_city_net_z()
	if(city_net_z)
		return city_net_z
	net_reservation = SSmapping.request_turf_block_reservation(CY_NETSPACE_DEFAULT_WIDTH, CY_NETSPACE_DEFAULT_HEIGHT, 1)
	if(!net_reservation)
		return null
	for(var/turf/T as anything in net_reservation.reserved_turfs)
		city_net_z = T.z
		break
	return city_net_z

/datum/controller/subsystem/netspace/proc/get_net_z_for_physical_z(physical_z)
	if(!physical_z)
		return null
	var/key = "[physical_z]"
	if(net_z_by_physical_z[key])
		return net_z_by_physical_z[key]
	var/net_z = ensure_city_net_z()
	if(!net_z)
		return null
	net_z_by_physical_z[key] = net_z
	return net_z

/datum/controller/subsystem/netspace/proc/physical_to_net_x(physical_x)
	return max(1, round(physical_x / CY_NETSPACE_SCALE))

/datum/controller/subsystem/netspace/proc/physical_to_net_y(physical_y)
	return max(1, round(physical_y / CY_NETSPACE_SCALE))

/datum/controller/subsystem/netspace/proc/get_net_turf_for_atom(atom/source)
	if(!source || !source.z)
		return null
	var/net_z = get_net_z_for_physical_z(source.z)
	if(!net_z)
		return null
	var/net_x = physical_to_net_x(source.x)
	var/net_y = physical_to_net_y(source.y)
	return locate(net_x, net_y, net_z)

/datum/controller/subsystem/netspace/proc/ensure_netspace_floor_around(center_x, center_y, target_z, radius = 0)
	if(!target_z)
		return
	var/area/netspace/generated/net_area = GLOB.areas_by_type[/area/netspace/generated]
	if(!net_area)
		net_area = new /area/netspace/generated
	var/start_x = max(1, center_x - radius)
	var/end_x = min(world.maxx, center_x + radius)
	var/start_y = max(1, center_y - radius)
	var/end_y = min(world.maxy, center_y + radius)
	for(var/current_x in start_x to end_x)
		for(var/current_y in start_y to end_y)
			var/turf/T = locate(current_x, current_y, target_z)
			if(!T)
				continue
			if(!istype(T, /turf/open/floor/netspace))
				T.ChangeTurf(/turf/open/floor/netspace)
			if(get_area(T) != net_area)
				set_turf_to_area(T, net_area)



/datum/controller/subsystem/netspace/proc/notify_trace(atom/source, mob/living/net_avatar/avatar, amount, reason)
	if(!source || amount <= 0)
		return FALSE
	var/sent = FALSE
	for(var/datum/netspace_node/node as anything in registered_nodes)
		if(!node?.physical_ref || !node.is_online())
			continue
		if(get_dist(get_turf(source), get_turf(node.physical_ref)) > CY_NET_DETECTION_SENSOR_RANGE)
			continue
		if(node.node_type in list(CY_NET_NODE_CAMERA, CY_NET_NODE_TERMINAL, CY_NET_NODE_TURRET, CY_NET_NODE_AREA))
			node.add_trace(amount, avatar, reason)
			if(node.trace?.trace_level >= CY_NET_TRACE_REVEAL)
				node.physical_ref.cy_netspace_alert(avatar, reason)
			sent = TRUE
	return sent

/datum/controller/subsystem/netspace/proc/build_netspace_prewarm_queue()
	if(netspace_prewarm_queue_built)
		return
	netspace_prewarm_queue_built = TRUE
	netspace_prewarm_queue = list()
	var/list/seen_keys = list()

	var/list/sources = list()
	for(var/obj/machinery/net_terminal/terminal in world)
		sources += terminal
	for(var/obj/machinery/door/airlock/airlock in world)
		sources += airlock
	for(var/obj/machinery/camera/camera in world)
		sources += camera
	for(var/obj/machinery/vending/vending in world)
		sources += vending
	for(var/obj/machinery/power/apc/apc in world)
		sources += apc

	for(var/atom/source as anything in sources)
		if(!source?.z)
			continue
		var/net_x = physical_to_net_x(source.x)
		var/net_y = physical_to_net_y(source.y)
		var/key = "[net_x]:[net_y]"
		if(seen_keys[key])
			continue
		seen_keys[key] = TRUE
		netspace_prewarm_queue += list(list("z" = source.z, "x" = net_x, "y" = net_y))

	if(!length(netspace_prewarm_queue))
		for(var/turf/T in world)
			if(!T.z)
				continue
			netspace_prewarm_queue += list(list("z" = T.z, "x" = physical_to_net_x(T.x), "y" = physical_to_net_y(T.y)))
			break

/datum/controller/subsystem/netspace/proc/process_netspace_prewarm()
	build_netspace_prewarm_queue()
	var/processed = 0
	while(length(netspace_prewarm_queue) && processed < CY_NETSPACE_PREWARM_BUDGET)
		var/list/entry = netspace_prewarm_queue[1]
		netspace_prewarm_queue.Cut(1, 2)
		processed++
		var/physical_z = entry["z"]
		var/net_z = get_net_z_for_physical_z(physical_z)
		if(!net_z)
			continue
		ensure_netspace_floor_around(entry["x"], entry["y"], net_z, CY_NETSPACE_PREWARM_RADIUS)
	if(!length(netspace_prewarm_queue))
		netspace_prewarm_finished = TRUE

/datum/controller/subsystem/netspace/proc/cy_lobby_netspace_ready()
	return default_objects_registered && lobby_full_floor_finished

/datum/controller/subsystem/netspace/proc/process_lobby_netspace_build()
	if(!lobby_full_floor_finished)
		process_lobby_full_floor_generation(CY_NETSPACE_LOBBY_FLOOR_BUDGET)
	if(!default_objects_registered)
		process_default_network_object_registration(CY_NETSPACE_LOBBY_NODE_REGISTER_BUDGET)

/datum/controller/subsystem/netspace/proc/build_lobby_full_floor_queue()
	if(length(lobby_full_floor_z_queue) || lobby_full_floor_finished)
		return
	var/net_z = ensure_city_net_z()
	if(!net_z)
		lobby_full_floor_finished = TRUE
		return
	lobby_full_floor_z_queue += net_z
	lobby_full_floor_progress["[net_z]"] = 1

/datum/controller/subsystem/netspace/proc/process_lobby_full_floor_generation(tile_budget = CY_NETSPACE_LOBBY_FLOOR_BUDGET)
	build_lobby_full_floor_queue()
	if(lobby_full_floor_finished)
		return
	var/area/netspace/generated/net_area = GLOB.areas_by_type[/area/netspace/generated]
	if(!net_area)
		net_area = new /area/netspace/generated
	var/processed = 0
	while(length(lobby_full_floor_z_queue) && processed < tile_budget)
		var/net_z = lobby_full_floor_z_queue[1]
		var/progress_key = "[net_z]"
		var/index = lobby_full_floor_progress[progress_key] || 1
		var/max_tiles = CY_NETSPACE_DEFAULT_WIDTH * CY_NETSPACE_DEFAULT_HEIGHT
		while(index <= max_tiles && processed < tile_budget)
			var/current_x = ((index - 1) % CY_NETSPACE_DEFAULT_WIDTH) + 1
			var/current_y = FLOOR((index - 1) / CY_NETSPACE_DEFAULT_WIDTH, 1) + 1
			var/turf/T = locate(current_x, current_y, net_z)
			if(T)
				if(!istype(T, /turf/open/floor/netspace))
					T.ChangeTurf(/turf/open/floor/netspace)
				if(get_area(T) != net_area)
					set_turf_to_area(T, net_area)
			index++
			processed++
		lobby_full_floor_progress[progress_key] = index
		if(index > max_tiles)
			lobby_full_floor_z_queue.Cut(1, 2)
			lobby_full_floor_progress.Remove(progress_key)
	if(!length(lobby_full_floor_z_queue))
		lobby_full_floor_finished = TRUE

/datum/controller/subsystem/netspace/proc/queue_network_object(atom/network_object)
	if(!network_object)
		return
	if(default_objects_registered)
		default_objects_registered = FALSE
	default_object_registration_queue |= network_object

/datum/controller/subsystem/netspace/proc/build_default_network_object_queue()
	if(default_object_registration_queue_built)
		return
	default_object_registration_queue_built = TRUE
	default_object_registration_queue = list()
	for(var/obj/machinery/door/airlock/airlock in world)
		default_object_registration_queue += airlock
	for(var/obj/machinery/camera/camera in world)
		default_object_registration_queue += camera
	for(var/obj/machinery/vending/vending in world)
		default_object_registration_queue += vending
	for(var/obj/machinery/power/apc/apc in world)
		default_object_registration_queue += apc
	for(var/obj/machinery/net_terminal/terminal in world)
		default_object_registration_queue += terminal
	for(var/obj/machinery/computer/computer in world)
		default_object_registration_queue += computer
	for(var/obj/machinery/porta_turret/turret in world)
		default_object_registration_queue += turret

/datum/controller/subsystem/netspace/proc/process_default_network_object_registration(register_budget = CY_NETSPACE_NODE_REGISTER_BUDGET)
	build_default_network_object_queue()
	var/processed = 0
	while(length(default_object_registration_queue) && processed < register_budget)
		var/atom/network_object = default_object_registration_queue[1]
		default_object_registration_queue.Cut(1, 2)
		processed++
		if(QDELETED(network_object))
			continue
		if(istype(network_object, /obj/machinery/door/airlock))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_DOOR, CY_NET_SECURITY_BASIC)
		else if(istype(network_object, /obj/machinery/camera))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_CAMERA, CY_NET_SECURITY_BASIC)
		else if(istype(network_object, /obj/machinery/vending))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_VENDING, CY_NET_SECURITY_BASIC)
		else if(istype(network_object, /obj/machinery/power/apc))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_AREA, CY_NET_SECURITY_BASIC)
		else if(istype(network_object, /obj/machinery/net_terminal))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_TERMINAL, network_object.cy_net_security)
		else if(istype(network_object, /obj/machinery/computer))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_TERMINAL, CY_NET_SECURITY_BASIC)
		else if(istype(network_object, /obj/machinery/porta_turret))
			network_object.cy_net_enabled = TRUE
			network_object.cy_netspace_register(CY_NET_NODE_TURRET, CY_NET_SECURITY_CORPORATE)
	if(!length(default_object_registration_queue))
		default_objects_registered = TRUE

/datum/controller/subsystem/netspace/proc/register_default_network_objects()
	build_default_network_object_queue()
	while(length(default_object_registration_queue))
		process_default_network_object_registration()
