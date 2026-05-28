// Cyberpunk 13 cyberspace: local cyberspace layer generation.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/datum/cyberspace_layer
	/// Reserved map block that represents this local cyberspace projection.
	var/datum/turf_reservation/reservation
	var/list/datum/cyberspace_node/nodes = list()
	var/list/atom/movable/rendered_entities = list()
	var/list/turf/veil_turfs = list()
	var/turf/origin_turf
	var/width = CYBERSPACE_LAYER_MIN_SIZE
	var/height = CYBERSPACE_LAYER_MIN_SIZE
	var/min_cyber_x = 0
	var/max_cyber_x = 0
	var/min_cyber_y = 0
	var/max_cyber_y = 0
/datum/cyberspace_layer/Destroy(force)
	for(var/atom/movable/rendered as anything in rendered_entities)
		qdel(rendered)
	rendered_entities = null
	veil_turfs = null
	for(var/datum/cyberspace_node/node as anything in nodes)
		qdel(node)
	nodes = null
	QDEL_NULL(reservation)
	origin_turf = null
	return ..()
/datum/cyberspace_layer/proc/build(mob/living/source)
	if(!source)
		return FALSE
	nodes = build_cyberspace_nodes_for_area(source)
	calculate_node_bounds()
	width = clamp(CEILING(sqrt(max(1, length(nodes))) * 8, 1), CYBERSPACE_LAYER_MIN_SIZE, CYBERSPACE_LAYER_MAX_SIZE)
	height = width
	reservation = SSmapping.request_turf_block_reservation(width, height, turf_type_override = /turf/open/indestructible/cyberspace)
	if(!reservation || !length(reservation.bottom_left_turfs))
		return FALSE
	origin_turf = reservation.bottom_left_turfs[1]
	render_nodes()
	render_veil()
	return TRUE
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
/datum/cyberspace_layer/proc/render_nodes()
	if(!origin_turf)
		return
	for(var/datum/cyberspace_node/node as anything in nodes)
		var/turf/node_turf = resolve_node_turf(node)
		if(!node_turf)
			continue
		var/obj/effect/cyberspace_node_shell/shell = new(node_turf, node)
		rendered_entities += shell
		render_imprints(node, node_turf)
/datum/cyberspace_layer/proc/render_veil()
	if(!origin_turf)
		return
	var/start_x = max(1, width - CYBERSPACE_VEIL_SIZE - 1)
	var/start_y = 1
	for(var/x_offset in start_x to min(width - 2, start_x + CYBERSPACE_VEIL_SIZE - 1))
		for(var/y_offset in start_y to min(height - 2, start_y + CYBERSPACE_VEIL_SIZE - 1))
			var/turf/veil_turf = locate(origin_turf.x + x_offset, origin_turf.y + y_offset, origin_turf.z)
			if(!veil_turf)
				continue
			veil_turf = veil_turf.ChangeTurf(/turf/open/indestructible/cyberspace/veil, null, CHANGETURF_IGNORE_AIR)
			veil_turfs += veil_turf
	if(!length(veil_turfs))
		return
	for(var/i in 1 to CYBERSPACE_VEIL_STORAGE_COUNT)
		var/obj/effect/cyberspace_storage_node/storage_node = new(pick(veil_turfs))
		rendered_entities += storage_node
	for(var/i in 1 to CYBERSPACE_VEIL_ALTERNATIVE_COUNT)
		var/mob/living/basic/cyberspace_alternative/alternative = new(pick(veil_turfs))
		rendered_entities += alternative
/datum/cyberspace_layer/proc/render_imprints(datum/cyberspace_node/node, turf/node_turf)
	if(!node || !node_turf)
		return
	for(var/datum/weakref/object_ref as anything in node.linked_object_refs)
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
	var/x_span = max(1, max_cyber_x - min_cyber_x)
	var/y_span = max(1, max_cyber_y - min_cyber_y)
	var/x_offset = (max_cyber_x == min_cyber_x) ? round(width * 0.5) : round(1 + ((node.cyber_x - min_cyber_x) / x_span) * max(1, width - 3))
	var/y_offset = (max_cyber_y == min_cyber_y) ? round(height * 0.5) : round(1 + ((node.cyber_y - min_cyber_y) / y_span) * max(1, height - 3))
	x_offset = clamp(x_offset, 1, width - 2)
	y_offset = clamp(y_offset, 1, height - 2)
	return locate(origin_turf.x + x_offset, origin_turf.y + y_offset, origin_turf.z)
/datum/cyberspace_layer/proc/get_entry_turf()
	if(!origin_turf)
		return null
	return locate(origin_turf.x + round(width * 0.5), origin_turf.y + round(height * 0.5), origin_turf.z)
