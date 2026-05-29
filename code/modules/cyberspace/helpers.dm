// Cyberpunk 13 cyberspace: source-world object discovery helpers.

/proc/build_cyberspace_nodes_for_area(atom/movable/origin)
	var/list/nodes = list()
	if(!origin)
		return nodes
	var/area/origin_area = get_area(origin)
	if(!origin_area)
		return nodes

	var/list/candidates = collect_cyberspace_network_objects(origin_area, origin.z)
	if(!length(candidates) && is_cyberspace_network_object(origin))
		candidates += origin

	for(var/atom/movable/candidate as anything in candidates)
		var/datum/cyberspace_node/new_node = new(candidate)
		new_node.add_object(candidate)
		nodes += new_node

	nodes = merge_nearby_cyberspace_nodes(nodes)
	if(!length(nodes))
		var/datum/cyberspace_node/fallback_node = new(origin)
		fallback_node.add_object(origin)
		nodes += fallback_node
	return nodes

/proc/collect_cyberspace_network_objects(area/origin_area, origin_z)
	var/list/candidates = list()
	if(!origin_area)
		return candidates
	for(var/z_level in 1 to world.maxz)
		if(!is_cyberspace_source_z_level(z_level, origin_z))
			continue
		var/list/area_turfs = get_area_turfs(origin_area.type, z_level)
		for(var/turf/area_turf as anything in area_turfs)
			for(var/atom/movable/candidate as anything in area_turf)
				if(is_cyberspace_network_object(candidate))
					candidates += candidate
	return candidates

/proc/is_cyberspace_source_z_level(z_level, origin_z)
	if(z_level == origin_z)
		return TRUE
	if(is_reserved_level(z_level) || is_centcom_level(z_level) || is_secret_level(z_level))
		return FALSE
	return TRUE

/proc/merge_nearby_cyberspace_nodes(list/datum/cyberspace_node/nodes)
	if(!length(nodes))
		return nodes
	var/merged = TRUE
	while(merged)
		merged = FALSE
		for(var/i in 1 to length(nodes))
			var/datum/cyberspace_node/left_node = nodes[i]
			if(!left_node)
				continue
			if(i >= length(nodes))
				continue
			for(var/j in (i + 1) to length(nodes))
				var/datum/cyberspace_node/right_node = nodes[j]
				if(!right_node || !left_node.can_merge_with(right_node))
					continue
				left_node.merge_from(right_node)
				nodes.Cut(j, j + 1)
				qdel(right_node)
				merged = TRUE
				break
			if(merged)
				break
	return nodes

/proc/is_cyberspace_network_object(atom/movable/candidate)
	if(!candidate)
		return FALSE
	if(isliving(candidate))
		var/mob/living/living_candidate = candidate
		return living_candidate.can_be_net_target() && !living_candidate.is_projected_into_cyberspace()
	return istype(candidate, /obj/machinery/door) \
		|| istype(candidate, /obj/machinery/camera) \
		|| istype(candidate, /obj/machinery/vending) \
		|| istype(candidate, /obj/machinery/computer) \
		|| istype(candidate, /obj/machinery/porta_turret) \
		|| istype(candidate, /mob/living/basic/bot) \
		|| istype(candidate, /mob/living/simple_animal/bot) \
		|| istype(candidate, /obj/item/organ/cyberimp)

/proc/get_cyberspace_manufacturer(atom/movable/target)
	if(!target)
		return "independent"
	if("corp_manufacturer" in target.vars)
		return target.vars["corp_manufacturer"] || "independent"
	if("manufacturer" in target.vars)
		return target.vars["manufacturer"] || "independent"
	return "independent"

/proc/get_cyberspace_net_data_amount(atom/movable/target)
	if(istype(target, /obj/machinery/door) || istype(target, /obj/machinery/camera))
		return CYBERSPACE_NET_DATA_DOOR_CAMERA
	if(istype(target, /obj/machinery/computer) || istype(target, /obj/structure/server))
		return CYBERSPACE_NET_DATA_TERMINAL_SERVER
	return rand(CYBERSPACE_NET_DATA_GENERIC_MIN, CYBERSPACE_NET_DATA_GENERIC_MAX)
