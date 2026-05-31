// Cyberpunk 13 cyberspace: global cyberspace layer generation.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

SUBSYSTEM_DEF(cyberspace)
	name = "Cyberspace"
	dependencies = list(
		/datum/controller/subsystem/mapping,
	)
	dependents = list(
		/datum/controller/subsystem/atoms,
	)
	ss_flags = SS_NO_FIRE
	runlevels = ALL
	wait = CYBERSPACE_LAYER_REFRESH_INTERVAL
	var/datum/cyberspace_layer/global_layer
	var/cyberspace_z
	var/nodes_initialized = FALSE

/datum/controller/subsystem/cyberspace/Initialize()
	global_layer = new()
	if(!global_layer.build_global())
		return SS_INIT_FAILURE
	global_layer.reset_network_turfs()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cyberspace/Recover()
	global_layer = SScyberspace.global_layer
	cyberspace_z = SScyberspace.cyberspace_z
	nodes_initialized = SScyberspace.nodes_initialized

/datum/controller/subsystem/cyberspace/Destroy()
	QDEL_NULL(global_layer)
	return ..()

/datum/controller/subsystem/cyberspace/fire(resumed = FALSE)
	return

/datum/controller/subsystem/cyberspace/proc/finalize_initial_layer()
	if(!global_layer || !global_layer.origin_turf)
		return FALSE
	if(!global_layer.refresh_global())
		return FALSE
	nodes_initialized = TRUE
	return TRUE

/datum/controller/subsystem/cyberspace/proc/get_layer()
	return ensure_ready()

/datum/controller/subsystem/cyberspace/proc/ensure_ready()
	if(!global_layer?.origin_turf || !nodes_initialized)
		return null
	return global_layer

SUBSYSTEM_DEF(cyberspace_nodes)
	name = "Cyberspace Nodes"
	dependencies = list(
		/datum/controller/subsystem/cyberspace,
		/datum/controller/subsystem/machines,
	)
	ss_flags = SS_NO_FIRE

/datum/controller/subsystem/cyberspace_nodes/Initialize()
	if(!SScyberspace?.finalize_initial_layer())
		return SS_INIT_FAILURE
	return SS_INIT_SUCCESS

/datum/cyberspace_layer
	var/list/datum/cyberspace_node/nodes = list()
	var/list/atom/movable/rendered_entities = list()
	var/list/turf/network_turfs = list()
	var/list/network_turf_lookup = list()
	var/turfs_initialized = FALSE
	var/turf/origin_turf
	var/width = CYBERSPACE_LAYER_MIN_SIZE
	var/height = CYBERSPACE_LAYER_MIN_SIZE
	var/min_cyber_x = 0
	var/max_cyber_x = 0
	var/min_cyber_y = 0
	var/max_cyber_y = 0
	var/physical_origin_x = 1
	var/physical_origin_y = 1
/datum/cyberspace_layer/Destroy(force)
	clear_rendered_entities()
	rendered_entities = null
	network_turfs = null
	network_turf_lookup = null
	for(var/datum/cyberspace_node/node as anything in nodes)
		qdel(node)
	nodes = null
	origin_turf = null
	return ..()

/datum/cyberspace_layer/proc/build_global()
	if(origin_turf)
		return TRUE
	var/datum/space_level/cyberspace_level = SSmapping.add_new_zlevel("Cyberspace", list(ZTRAIT_CYBERSPACE = TRUE))
	if(!cyberspace_level)
		return FALSE
	ensure_spatial_grid_for_z(cyberspace_level)
	SScyberspace.cyberspace_z = cyberspace_level.z_value
	width = world.maxx
	height = world.maxy
	physical_origin_x = 1
	physical_origin_y = 1
	min_cyber_x = 1
	min_cyber_y = 1
	max_cyber_x = world.maxx
	max_cyber_y = world.maxy
	origin_turf = locate(1, 1, cyberspace_level.z_value)
	if(!origin_turf)
		return FALSE
	return TRUE

/datum/cyberspace_layer/proc/ensure_spatial_grid_for_z(datum/space_level/cyberspace_level)
	if(!cyberspace_level || !SSspatial_grid?.initialized)
		return
	if(length(SSspatial_grid.grids_by_z_level) >= cyberspace_level.z_value && SSspatial_grid.grids_by_z_level[cyberspace_level.z_value])
		return
	SSspatial_grid.propogate_spatial_grid_to_new_z(null, cyberspace_level)

/datum/cyberspace_layer/proc/build(mob/living/source)
	if(!source)
		return FALSE
	if(!origin_turf && !build_global())
		return FALSE
	nodes = build_cyberspace_nodes_for_area(source)
	calculate_node_bounds()
	calculate_layer_dimensions()
	reset_network_turfs()
	render_network_floor()
	render_nodes()
	render_veil_entities()
	return TRUE

/datum/cyberspace_layer/proc/refresh_global()
	if(!origin_turf)
		return FALSE
	clear_rendered_entities()
	for(var/datum/cyberspace_node/node as anything in nodes)
		qdel(node)
	nodes = build_all_cyberspace_nodes()
	reset_network_turfs()
	render_network_floor()
	render_nodes()
	render_veil_entities()
	return TRUE

/datum/cyberspace_layer/proc/refresh(mob/living/source)
	if(!source || !origin_turf)
		return FALSE
	clear_rendered_entities()
	for(var/datum/cyberspace_node/node as anything in nodes)
		qdel(node)
	nodes = build_cyberspace_nodes_for_area(source)
	calculate_node_bounds()
	reset_network_turfs()
	render_network_floor()
	render_nodes()
	render_veil_entities()
	return TRUE

/datum/cyberspace_layer/proc/clear_rendered_entities()
	for(var/atom/movable/rendered as anything in rendered_entities)
		qdel(rendered)
	rendered_entities = list()

/datum/cyberspace_layer/proc/calculate_node_bounds()
	min_cyber_x = INFINITY
	max_cyber_x = -INFINITY
	min_cyber_y = INFINITY
	max_cyber_y = -INFINITY
	for(var/datum/cyberspace_node/node as anything in nodes)
		if(!node)
			continue
		min_cyber_x = min(min_cyber_x, node.cyber_x)
		max_cyber_x = max(max_cyber_x, node.cyber_x)
		min_cyber_y = min(min_cyber_y, node.cyber_y)
		max_cyber_y = max(max_cyber_y, node.cyber_y)
	if(min_cyber_x == INFINITY)
		min_cyber_x = 0
		max_cyber_x = 0
		min_cyber_y = 0
		max_cyber_y = 0

/datum/cyberspace_layer/proc/calculate_layer_dimensions()
	var/x_span = max(1, max_cyber_x - min_cyber_x + 1)
	var/y_span = max(1, max_cyber_y - min_cyber_y + 1)
	width = clamp(x_span + (CYBERSPACE_NODE_CLEAR_RADIUS * 2) + (CYBERSPACE_LAYER_PADDING * 2), CYBERSPACE_LAYER_MIN_SIZE, world.maxx)
	height = clamp(y_span + (CYBERSPACE_NODE_CLEAR_RADIUS * 2) + (CYBERSPACE_LAYER_PADDING * 2), CYBERSPACE_LAYER_MIN_SIZE, world.maxy)
	physical_origin_x = min_cyber_x - CYBERSPACE_NODE_CLEAR_RADIUS - CYBERSPACE_LAYER_PADDING
	physical_origin_y = min_cyber_y - CYBERSPACE_NODE_CLEAR_RADIUS - CYBERSPACE_LAYER_PADDING

/datum/cyberspace_layer/proc/reset_network_turfs()
	if(!origin_turf)
		return
	if(!turfs_initialized)
		initialize_veil_turfs()
		return
	var/list/old_network_turfs = network_turfs?.Copy() || list()
	network_turfs = list()
	network_turf_lookup = list()
	for(var/turf/current_turf as anything in old_network_turfs)
		if(!current_turf || QDELETED(current_turf))
			continue
		if(istype(current_turf, /turf/open/indestructible/cyberspace/veil))
			continue
		var/turf/new_turf = current_turf.ChangeTurf(/turf/open/indestructible/cyberspace/veil, null, CHANGETURF_IGNORE_AIR)
		if(current_turf == origin_turf)
			origin_turf = new_turf
		CHECK_TICK

/datum/cyberspace_layer/proc/initialize_veil_turfs()
	network_turfs = list()
	network_turf_lookup = list()
	for(var/x_offset in 0 to (width - 1))
		for(var/y_offset in 0 to (height - 1))
			var/turf/current_turf = locate(origin_turf.x + x_offset, origin_turf.y + y_offset, origin_turf.z)
			if(!current_turf)
				continue
			var/turf/new_turf = current_turf.ChangeTurf(/turf/open/indestructible/cyberspace/veil, null, CHANGETURF_IGNORE_AIR)
			if(current_turf == origin_turf)
				origin_turf = new_turf
			CHECK_TICK
	turfs_initialized = TRUE

/datum/cyberspace_layer/proc/render_network_floor()
	network_turfs = list()
	network_turf_lookup = list()
	if(!origin_turf)
		return
	for(var/datum/cyberspace_node/node as anything in nodes)
		render_node_network_floor(node)

/datum/cyberspace_layer/proc/render_node_network_floor(datum/cyberspace_node/node)
	if(!origin_turf || !node)
		return 0
	var/rendered = 0
	for(var/x_position in (node.cyber_x - CYBERSPACE_NODE_CLEAR_RADIUS) to (node.cyber_x + CYBERSPACE_NODE_CLEAR_RADIUS))
		for(var/y_position in (node.cyber_y - CYBERSPACE_NODE_CLEAR_RADIUS) to (node.cyber_y + CYBERSPACE_NODE_CLEAR_RADIUS))
			var/x_delta = x_position - node.cyber_x
			var/y_delta = y_position - node.cyber_y
			if(sqrt((x_delta * x_delta) + (y_delta * y_delta)) > CYBERSPACE_NODE_CLEAR_RADIUS)
				continue
			var/turf/network_turf = resolve_physical_turf(x_position, y_position)
			if(!network_turf || network_turf_lookup[network_turf])
				continue
			var/turf/new_network_turf = network_turf
			if(!istype(network_turf, /turf/open/indestructible/cyberspace) || istype(network_turf, /turf/open/indestructible/cyberspace/veil))
				new_network_turf = network_turf.ChangeTurf(/turf/open/indestructible/cyberspace, null, CHANGETURF_IGNORE_AIR)
			if(network_turf == origin_turf)
				origin_turf = new_network_turf
			network_turfs += new_network_turf
			network_turf_lookup[new_network_turf] = TRUE
			rendered++
	return rendered

/datum/cyberspace_layer/proc/render_nodes()
	if(!origin_turf)
		return
	for(var/datum/cyberspace_node/node as anything in nodes)
		var/turf/node_turf = resolve_node_turf(node)
		if(!node_turf)
			continue
		if(node.trace_only)
			var/list/live_objects = node.get_live_objects()
			var/atom/movable/linked_object = length(live_objects) ? live_objects[1] : node.anchor
			var/obj/effect/cyberspace_object_trace/trace = new(node_turf, linked_object, node)
			rendered_entities += trace
			continue
		var/obj/effect/cyberspace_node_shell/shell = new(node_turf, node)
		rendered_entities += shell
		render_imprints(node, node_turf)

/datum/cyberspace_layer/proc/render_object_traces(datum/cyberspace_node/node, turf/node_turf)
	if(!node || !node_turf)
		return
	node.prune_dead_object_refs()
	var/rendered_count = 0
	for(var/datum/weakref/object_ref as anything in node.linked_object_refs)
		if(rendered_count >= CYBERSPACE_NODE_OBJECT_TRACE_LIMIT)
			break
		if(!object_ref)
			continue
		var/atom/movable/linked_object = object_ref.resolve()
		if(!linked_object || ismob(linked_object))
			continue
		rendered_count++
		var/turf/trace_turf = get_object_trace_turf(node_turf, rendered_count)
		if(!trace_turf)
			trace_turf = node_turf
		var/obj/effect/cyberspace_object_trace/trace = new(trace_turf, linked_object, node)
		rendered_entities += trace

/datum/cyberspace_layer/proc/get_object_trace_turf(turf/node_turf, trace_index)
	if(!node_turf || trace_index <= 0)
		return node_turf
	var/list/directions = list(NORTH, EAST, SOUTH, WEST, NORTHEAST, SOUTHEAST, SOUTHWEST, NORTHWEST)
	var/direction = directions[((trace_index - 1) % length(directions)) + 1]
	var/distance = 2 + FLOOR((trace_index - 1) / length(directions), 1)
	var/turf/current_turf = node_turf
	for(var/step_index in 1 to distance)
		current_turf = get_step(current_turf, direction)
		if(!current_turf)
			return node_turf
	if(!network_turf_lookup[current_turf])
		return node_turf
	return current_turf
/datum/cyberspace_layer/proc/render_veil_entities()
	if(!origin_turf)
		return
	for(var/i in 1 to CYBERSPACE_VEIL_STORAGE_COUNT)
		var/turf/storage_turf = pick_veil_turf()
		if(!storage_turf)
			continue
		var/obj/effect/cyberspace_storage_node/storage_node = new(storage_turf)
		rendered_entities += storage_node
	for(var/i in 1 to CYBERSPACE_VEIL_ALTERNATIVE_COUNT)
		var/turf/alternative_turf = pick_veil_turf()
		if(!alternative_turf)
			continue
		var/mob/living/basic/cyberspace_alternative/alternative = new(alternative_turf)
		rendered_entities += alternative

/datum/cyberspace_layer/proc/pick_veil_turf()
	if(!origin_turf)
		return null
	for(var/attempt in 1 to 100)
		var/turf/candidate = locate(origin_turf.x + rand(0, width - 1), origin_turf.y + rand(0, height - 1), origin_turf.z)
		if(candidate && !network_turf_lookup[candidate])
			return candidate
	return origin_turf
/datum/cyberspace_layer/proc/render_imprints(datum/cyberspace_node/node, turf/node_turf)
	if(!node || !node_turf)
		return
	node.prune_dead_object_refs()
	for(var/datum/weakref/object_ref as anything in node.linked_object_refs)
		if(!object_ref)
			continue
		var/mob/living/net_target = object_ref.resolve()
		if(!istype(net_target) || net_target.is_projected_into_cyberspace() || !net_target.can_be_net_target())
			continue
		var/turf/imprint_turf = get_step(node_turf, pick(GLOB.alldirs))
		if(!imprint_turf)
			imprint_turf = node_turf
		var/obj/effect/cyberspace_imprint_shell/imprint = new(imprint_turf, net_target, node)
		rendered_entities += imprint
/datum/cyberspace_layer/proc/resolve_node_turf(datum/cyberspace_node/node)
	if(!node || !origin_turf)
		return null
	return resolve_physical_turf(node.cyber_x, node.cyber_y)

/datum/cyberspace_layer/proc/resolve_physical_turf(x_position, y_position)
	if(!origin_turf)
		return null
	var/x_offset = x_position - physical_origin_x
	var/y_offset = y_position - physical_origin_y
	if(x_offset < 0 || y_offset < 0 || x_offset >= width || y_offset >= height)
		return null
	return locate(origin_turf.x + x_offset, origin_turf.y + y_offset, origin_turf.z)

/datum/cyberspace_layer/proc/get_nearest_node(atom/movable/source)
	var/datum/cyberspace_node/local_area_node = get_nearest_node_matching(source, TRUE, TRUE)
	if(local_area_node)
		return local_area_node
	var/datum/cyberspace_node/local_z_node = get_nearest_node_matching(source, TRUE, FALSE)
	if(local_z_node)
		return local_z_node
	return get_nearest_node_matching(source, FALSE, FALSE)

/datum/cyberspace_layer/proc/get_nearest_node_matching(atom/movable/source, require_same_z = FALSE, require_same_area = FALSE)
	if(!source || !length(nodes))
		return null
	var/area/source_area = get_area(source)
	var/source_area_type = source_area?.type
	var/datum/cyberspace_node/nearest_node
	var/nearest_distance = INFINITY
	for(var/datum/cyberspace_node/node as anything in nodes)
		if(!node)
			continue
		if(require_same_z && node.source_z && node.source_z != source.z)
			continue
		if(require_same_area && source_area && node.physical_area != source_area && node.physical_area_type != source_area_type)
			continue
		var/x_delta = source.x - node.cyber_x
		var/y_delta = source.y - node.cyber_y
		var/current_distance = sqrt((x_delta * x_delta) + (y_delta * y_delta))
		if(current_distance >= nearest_distance)
			continue
		nearest_distance = current_distance
		nearest_node = node
	return nearest_node

/datum/cyberspace_layer/proc/get_entry_turf()
	if(!origin_turf)
		return null
	if(length(network_turfs))
		return pick(network_turfs)
	return locate(origin_turf.x + round(width * 0.5), origin_turf.y + round(height * 0.5), origin_turf.z)

/datum/cyberspace_layer/proc/get_entry_turf_for(atom/movable/source)
	if(source)
		var/turf/source_coordinate_turf = resolve_physical_turf(source.x, source.y)
		if(source_coordinate_turf && !source_coordinate_turf.density)
			return source_coordinate_turf
	return get_entry_turf()
