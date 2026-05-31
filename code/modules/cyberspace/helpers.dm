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

	nodes = build_cyberspace_nodes_from_candidates(candidates)

	if(!length(nodes))
		var/datum/cyberspace_node/fallback_node = new(origin)
		fallback_node.add_object(origin)
		nodes += fallback_node
	return nodes

/proc/build_all_cyberspace_nodes()
	var/list/candidates = collect_all_cyberspace_network_objects()
	return build_cyberspace_nodes_from_candidates(candidates)

/proc/build_cyberspace_nodes_from_candidates(list/candidates)
	var/list/nodes = list()
	var/list/grouped_nodes = list()
	for(var/atom/movable/candidate as anything in candidates)
		if(!candidate)
			continue
		var/trace_only = is_cyberspace_trace_object(candidate)
		var/group_key = get_cyberspace_node_group_key(candidate)
		var/list/datum/cyberspace_node/group_nodes = grouped_nodes[group_key]
		if(!group_nodes)
			group_nodes = list()
			grouped_nodes[group_key] = group_nodes
		var/datum/cyberspace_node/target_node
		for(var/datum/cyberspace_node/existing_node as anything in group_nodes)
			if(existing_node?.trace_only != trace_only)
				continue
			if(existing_node?.get_object_count() < CYBERSPACE_NODE_MAX_OBJECTS)
				target_node = existing_node
				break
		if(!target_node)
			target_node = new(candidate)
			target_node.trace_only = trace_only
			group_nodes += target_node
			nodes += target_node
		target_node.add_object(candidate)
	return merge_nearby_cyberspace_nodes(nodes)

/proc/get_cyberspace_node_group_key(atom/movable/candidate)
	if(is_cyberspace_trace_object(candidate))
		return "trace|\ref[candidate]"
	var/area/candidate_area = get_area(candidate)
	var/area_key = candidate_area ? "[candidate_area.type]" : "[/area]"
	return "area|[area_key]"

/proc/collect_all_cyberspace_network_objects()
	var/list/candidates = list()
	for(var/obj/machinery/machine as anything in SSmachines.get_all_machines())
		if(is_cyberspace_network_object(machine) && is_cyberspace_source_z_level(machine.z))
			candidates |= machine
	for(var/mob/living/living_mob as anything in GLOB.mob_living_list)
		if(is_cyberspace_network_object(living_mob) && is_cyberspace_source_z_level(living_mob.z))
			candidates |= living_mob
	for(var/obj/item/organ/cyberimp/implant as anything in world)
		if(is_cyberspace_network_object(implant) && is_cyberspace_source_z_level(implant.z))
			candidates |= implant
	return candidates

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

/proc/is_cyberspace_source_z_level(z_level, origin_z = null)
	if(SScyberspace?.cyberspace_z == z_level)
		return FALSE
	if(!isnull(origin_z) && z_level == origin_z)
		return TRUE
	if(is_reserved_level(z_level) || is_centcom_level(z_level) || is_secret_level(z_level))
		return FALSE
	return TRUE

/proc/merge_nearby_cyberspace_nodes(list/datum/cyberspace_node/nodes)
	if(!length(nodes))
		return nodes
	var/list/merged_nodes = list()
	var/list/spatial_buckets = list()
	for(var/datum/cyberspace_node/current_node as anything in nodes)
		if(!current_node)
			continue
		var/datum/cyberspace_node/merge_candidate = find_cyberspace_node_merge_candidate(current_node, spatial_buckets)
		while(merge_candidate)
			remove_cyberspace_node_from_bucket(merge_candidate, spatial_buckets)
			merged_nodes -= merge_candidate
			current_node.merge_from(merge_candidate)
			qdel(merge_candidate)
			merge_candidate = find_cyberspace_node_merge_candidate(current_node, spatial_buckets)
		merged_nodes += current_node
		add_cyberspace_node_to_bucket(current_node, spatial_buckets)
	return merged_nodes

/proc/get_cyberspace_node_bucket_size()
	return max(1, CYBERSPACE_NODE_MERGE_RANGE + 1)

/proc/get_cyberspace_node_bucket_x(datum/cyberspace_node/node)
	return FLOOR(node.cyber_x / get_cyberspace_node_bucket_size(), 1)

/proc/get_cyberspace_node_bucket_y(datum/cyberspace_node/node)
	return FLOOR(node.cyber_y / get_cyberspace_node_bucket_size(), 1)

/proc/get_cyberspace_node_bucket_key(bucket_x, bucket_y)
	return "[bucket_x],[bucket_y]"

/proc/add_cyberspace_node_to_bucket(datum/cyberspace_node/node, list/spatial_buckets)
	if(!node || !spatial_buckets)
		return FALSE
	var/bucket_key = get_cyberspace_node_bucket_key(get_cyberspace_node_bucket_x(node), get_cyberspace_node_bucket_y(node))
	var/list/bucket = spatial_buckets[bucket_key]
	if(!bucket)
		bucket = list()
		spatial_buckets[bucket_key] = bucket
	bucket += node
	return TRUE

/proc/remove_cyberspace_node_from_bucket(datum/cyberspace_node/node, list/spatial_buckets)
	if(!node || !spatial_buckets)
		return FALSE
	var/bucket_key = get_cyberspace_node_bucket_key(get_cyberspace_node_bucket_x(node), get_cyberspace_node_bucket_y(node))
	var/list/bucket = spatial_buckets[bucket_key]
	if(!bucket)
		return FALSE
	bucket -= node
	return TRUE

/proc/find_cyberspace_node_merge_candidate(datum/cyberspace_node/node, list/spatial_buckets)
	if(!node || !spatial_buckets)
		return null
	var/base_bucket_x = get_cyberspace_node_bucket_x(node)
	var/base_bucket_y = get_cyberspace_node_bucket_y(node)
	for(var/bucket_x in (base_bucket_x - 1) to (base_bucket_x + 1))
		for(var/bucket_y in (base_bucket_y - 1) to (base_bucket_y + 1))
			var/list/bucket = spatial_buckets[get_cyberspace_node_bucket_key(bucket_x, bucket_y)]
			if(!length(bucket))
				continue
			for(var/datum/cyberspace_node/candidate as anything in bucket)
				if(candidate && node.can_merge_with(candidate))
					return candidate
	return null

/proc/is_cyberspace_network_object(atom/movable/candidate)
	if(!candidate)
		return FALSE
	if(isliving(candidate))
		var/mob/living/living_candidate = candidate
		return living_candidate.can_be_net_target() && !living_candidate.is_projected_into_cyberspace()
	return istype(candidate, /obj/machinery/door) \
		|| istype(candidate, /obj/machinery/camera) \
		|| istype(candidate, /obj/machinery/light) \
		|| istype(candidate, /obj/machinery/vending) \
		|| istype(candidate, /obj/machinery/computer) \
		|| istype(candidate, /obj/machinery/airalarm) \
		|| istype(candidate, /obj/machinery/firealarm) \
		|| istype(candidate, /obj/machinery/power/apc) \
		|| istype(candidate, /obj/machinery/requests_console) \
		|| istype(candidate, /obj/machinery/status_display) \
		|| istype(candidate, /obj/machinery/porta_turret) \
		|| istype(candidate, /mob/living/basic/bot) \
		|| istype(candidate, /mob/living/simple_animal/bot) \
		|| istype(candidate, /obj/item/organ/cyberimp)

/proc/is_cyberspace_trace_object(atom/movable/candidate)
	if(!candidate)
		return FALSE
	return istype(candidate, /obj/machinery/door) \
		|| istype(candidate, /obj/machinery/camera) \
		|| istype(candidate, /obj/machinery/light)

/proc/is_cyberspace_ice_hack_target(atom/movable/candidate)
	if(!candidate)
		return FALSE
	if(isliving(candidate))
		var/mob/living/living_candidate = candidate
		return living_candidate.can_be_net_target()
	return istype(candidate, /obj/structure/server) \
		|| istype(candidate, /obj/machinery/rnd/server) \
		|| istype(candidate, /obj/machinery/telecomms/server) \
		|| istype(candidate, /obj/machinery/telecomms/message_server) \
		|| istype(candidate, /obj/machinery/computer/telecomms/server) \
		|| istype(candidate, /obj/machinery/computer/rdservercontrol) \
		|| istype(candidate, /obj/machinery/quantum_server) \
		|| istype(candidate, /obj/machinery/cyberdemon_terminal)

/proc/get_cyberspace_manufacturer(atom/movable/target)
	if(!target)
		return "independent"
	if("corp_manufacturer" in target.vars)
		return target.vars["corp_manufacturer"] || "independent"
	if("manufacturer" in target.vars)
		return target.vars["manufacturer"] || "independent"
	return "independent"

/proc/get_cyberspace_net_data_amount(atom/movable/target)
	if(istype(target, /obj/machinery/door) || istype(target, /obj/machinery/camera) || istype(target, /obj/machinery/light))
		return CYBERSPACE_NET_DATA_DOOR_CAMERA
	if(istype(target, /obj/machinery/computer) || istype(target, /obj/structure/server))
		return CYBERSPACE_NET_DATA_TERMINAL_SERVER
	return rand(CYBERSPACE_NET_DATA_GENERIC_MIN, CYBERSPACE_NET_DATA_GENERIC_MAX)
