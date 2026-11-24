GLOBAL_LIST_EMPTY(cyberpunk_metro_stops)
GLOBAL_LIST_EMPTY(cyberpunk_metro_route_points)
GLOBAL_LIST_EMPTY(cyberpunk_metro_route_path_cache)
GLOBAL_LIST_EMPTY(cyberpunk_metro_interiors)
GLOBAL_LIST_EMPTY(cyberpunk_metro_trains)
GLOBAL_LIST_EMPTY(cyberpunk_metro_doors)

#define CYBERPUNK_METRO_TRAIN_TEMPLATE "_maps/templates/cyberpunk_metro_train_32x5.dmm"
#define CYBERPUNK_METRO_EXTERIOR_CARS 3
#define CYBERPUNK_METRO_MOVE_STEP_DELAY (0.1 SECONDS)

SUBSYSTEM_DEF(cyberpunk_metro)
	name = "Cyberpunk Metro"
	wait = CYBERPUNK_METRO_MOVE_STEP_DELAY
	priority = FIRE_PRIORITY_DEFAULT
	/// Interior reservations created for generated trains. Kept alive for the whole round.
	var/list/datum/turf_reservation/generated_reservations = list()
	/// Generated route/train keys, so re-initialization does not duplicate consists.
	var/list/generated_trains = list()
	/// Route generation is delayed until map landmarks finish initializing.
	var/routes_built = FALSE

/datum/controller/subsystem/cyberpunk_metro/Initialize(start_timeofday)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cyberpunk_metro/proc/try_build_route_trains()
	if(routes_built)
		return TRUE
	if(!length(GLOB.cyberpunk_metro_stops))
		return FALSE
	var/created_trains = build_route_trains()
	routes_built = TRUE
	return !!created_trains

/datum/controller/subsystem/cyberpunk_metro/proc/build_route_trains()
	var/created_trains = 0
	var/list/routes = list()
	for(var/obj/effect/landmark/cyberpunk_metro_stop/stop as anything in GLOB.cyberpunk_metro_stops)
		if(QDELETED(stop) || !stop.route_id)
			continue
		if(!routes[stop.route_id])
			routes[stop.route_id] = list(
				"train_count" = 1,
				"template_path" = CYBERPUNK_METRO_TRAIN_TEMPLATE,
			)
		var/list/route_data = routes[stop.route_id]
		route_data["train_count"] = max(route_data["train_count"], stop.train_count)
		if(stop.train_template_path)
			route_data["template_path"] = stop.train_template_path

	for(var/route_id as anything in routes)
		if(cyberpunk_metro_train_for_route(route_id))
			continue
		var/list/stops = cyberpunk_metro_route_stops(route_id)
		if(length(stops) < 2)
			stack_trace("Cyberpunk metro route '[route_id]' needs at least two stop landmarks.")
			continue
		if(!length(cyberpunk_metro_route_path(route_id)))
			continue
		var/list/route_data = routes[route_id]
		var/train_count = max(1, route_data["train_count"])
		var/start_offset = 0
		for(var/train_index in 1 to train_count)
			var/train_id = "[route_id]#[train_index]"
			if(generated_trains[train_id] || cyberpunk_metro_train_for_route(route_id, train_id))
				continue
			var/obj/effect/landmark/cyberpunk_metro_stop/start_stop = stops[((start_offset + train_index - 1) % length(stops)) + 1]
			if(!load_train_interior(route_id, train_id, route_data["template_path"]))
				continue
			var/obj/structure/cyberpunk_metro_train/controller = create_train_consist(route_id, train_id, start_stop)
			if(!controller)
				continue
			generated_trains[train_id] = TRUE
			created_trains++
	return created_trains

/datum/controller/subsystem/cyberpunk_metro/proc/load_train_interior(route_id, train_id, template_path)
	if(!fexists(template_path))
		stack_trace("Cyberpunk metro route '[route_id]' could not find train template '[template_path]'.")
		return FALSE
	var/datum/map_template/template = new(template_path, "Cyberpunk Metro Train [route_id] [train_id]")
	if(!template.width || !template.height)
		stack_trace("Cyberpunk metro route '[route_id]' train template '[template_path]' has invalid bounds.")
		qdel(template)
		return FALSE
	var/datum/turf_reservation/reservation = SSmapping.request_turf_block_reservation(template.width, template.height, 1)
	if(!reservation || !length(reservation.bottom_left_turfs))
		stack_trace("Cyberpunk metro route '[route_id]' failed to reserve [template.width]x[template.height] train interior.")
		qdel(template)
		return FALSE
	generated_reservations += reservation
	template.returns_created_atoms = TRUE
	var/turf/load_turf = reservation.bottom_left_turfs[1]
	if(!template.load(load_turf))
		stack_trace("Cyberpunk metro route '[route_id]' failed to load train interior template '[template_path]'.")
		generated_reservations -= reservation
		reservation.Release()
		qdel(reservation)
		qdel(template)
		return FALSE

	var/updated_landmarks = FALSE
	for(var/atom/created as anything in template.created_atoms)
		if(istype(created, /obj/effect/landmark/cyberpunk_metro_interior))
			var/obj/effect/landmark/cyberpunk_metro_interior/interior = created
			interior.route_id = route_id
			interior.train_id = train_id
			updated_landmarks = TRUE
			continue
		if(istype(created, /obj/structure/cyberpunk_metro_door))
			var/obj/structure/cyberpunk_metro_door/door = created
			door.route_id = route_id
			door.train_id = train_id

	if(!updated_landmarks)
		for(var/turf/reserved_turf as anything in reservation.reserved_turfs)
			for(var/obj/effect/landmark/cyberpunk_metro_interior/interior in reserved_turf)
				interior.route_id = route_id
				interior.train_id = train_id
				updated_landmarks = TRUE
			for(var/obj/structure/cyberpunk_metro_door/door in reserved_turf)
				door.route_id = route_id
				door.train_id = train_id

	template.created_atoms.Cut()
	qdel(template)
	if(!updated_landmarks)
		stack_trace("Cyberpunk metro route '[route_id]' train interior has no interior landmark.")
		return FALSE
	return TRUE

/datum/controller/subsystem/cyberpunk_metro/proc/create_train_consist(route_id, train_id, obj/effect/landmark/cyberpunk_metro_stop/start_stop)
	var/turf/origin = get_turf(start_stop)
	if(!origin)
		return null
	var/list/created_segments = list()
	var/list/segment_types = list(
		/obj/structure/cyberpunk_metro_train/locomotive,
		/obj/structure/cyberpunk_metro_train/car,
		/obj/structure/cyberpunk_metro_train/car/second,
	)
	for(var/index in 1 to min(CYBERPUNK_METRO_EXTERIOR_CARS, length(segment_types)))
		var/segment_type = segment_types[index]
		var/obj/structure/cyberpunk_metro_train/segment = new segment_type(origin)
		segment.route_id = route_id
		segment.train_id = train_id
		segment.name = "[segment.name] ([route_id] #[index])"
		created_segments += segment
	var/obj/structure/cyberpunk_metro_train/controller = created_segments[1]
	controller.arrive_at(start_stop)
	log_game("Cyberpunk metro generated train [train_id] for route [route_id] at [origin.x],[origin.y],[origin.z].")
	return controller

/datum/controller/subsystem/cyberpunk_metro/fire(resumed)
	if(!routes_built)
		try_build_route_trains()
	for(var/obj/structure/cyberpunk_metro_train/train as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(train))
			GLOB.cyberpunk_metro_trains -= train
			continue
		train.process_metro()

/proc/cyberpunk_metro_route_stops(route_id)
	var/list/stops = list()
	for(var/obj/effect/landmark/cyberpunk_metro_stop/stop as anything in GLOB.cyberpunk_metro_stops)
		if(QDELETED(stop) || stop.route_id != route_id)
			continue
		cyberpunk_metro_insert_route_landmark(stops, stop)
	return stops

/proc/cyberpunk_metro_route_path(route_id)
	var/list/cached_route_path = GLOB.cyberpunk_metro_route_path_cache[route_id]
	if(length(cached_route_path))
		return cached_route_path
	var/list/control_points = cyberpunk_metro_route_control_points(route_id)
	if(length(control_points) < 2)
		return control_points
	var/list/route_path = list()
	route_path += control_points[1]
	for(var/index in 1 to length(control_points))
		var/atom/start_point = control_points[index]
		var/atom/end_point = control_points[1]
		if(index < length(control_points))
			end_point = control_points[index + 1]
		var/list/segment = cyberpunk_metro_path_between(start_point, end_point, route_id)
		if(!length(segment))
			stack_trace("Cyberpunk metro route '[route_id]' has no connected rail path between [start_point] and [end_point].")
			return null
		if(length(segment) < 2)
			continue
		for(var/segment_index in 2 to length(segment))
			var/turf/segment_turf = segment[segment_index]
			if(segment_turf == get_turf(end_point))
				if(route_path[length(route_path)] != end_point)
					route_path += end_point
			else if(route_path[length(route_path)] != segment_turf)
				route_path += segment_turf
	GLOB.cyberpunk_metro_route_path_cache[route_id] = route_path
	return route_path

/proc/cyberpunk_metro_route_control_points(route_id)
	var/list/route_points = list()
	for(var/obj/effect/landmark/cyberpunk_metro_stop/stop as anything in GLOB.cyberpunk_metro_stops)
		if(QDELETED(stop) || stop.route_id != route_id)
			continue
		cyberpunk_metro_insert_route_landmark(route_points, stop)
	for(var/obj/effect/landmark/cyberpunk_metro_route_point/route_point as anything in GLOB.cyberpunk_metro_route_points)
		if(QDELETED(route_point) || route_point.route_id != route_id)
			continue
		cyberpunk_metro_insert_route_landmark(route_points, route_point)
	return route_points

/proc/cyberpunk_metro_path_between(atom/start_point, atom/end_point, route_id = "main")
	var/turf/start_turf = get_turf(start_point)
	var/turf/end_turf = get_turf(end_point)
	if(!cyberpunk_metro_rail_at(start_turf, route_id) || !cyberpunk_metro_rail_at(end_turf, route_id) || start_turf.z != end_turf.z)
		return null
	if(start_turf == end_turf)
		return list(start_turf)
	var/list/open_queue = list(start_turf)
	var/list/visited = list()
	var/list/came_from = list()
	visited[start_turf] = TRUE
	while(length(open_queue))
		var/turf/current_turf = open_queue[1]
		open_queue.Cut(1, 2)
		if(current_turf == end_turf)
			break
		for(var/direction in GLOB.cardinals)
			var/turf/next_turf = get_step(current_turf, direction)
			if(!cyberpunk_metro_can_step(current_turf, next_turf, route_id))
				continue
			if(visited[next_turf])
				continue
			visited[next_turf] = TRUE
			came_from[next_turf] = current_turf
			open_queue += next_turf
	if(!visited[end_turf])
		return null
	var/list/reversed_path = list()
	var/turf/walk_turf = end_turf
	while(walk_turf)
		reversed_path += walk_turf
		if(walk_turf == start_turf)
			break
		walk_turf = came_from[walk_turf]
	var/list/path = list()
	var/index = length(reversed_path)
	while(index >= 1)
		path += reversed_path[index]
		index--
	return path

/// Explicit rail edges are authoritative; a metro area alone is never a track.
/obj/structure/fluff/tram_rail/cyberpunk
	name = "metro rail"
	var/route_id = "main"
	/// Cardinal exits; corners need two perpendicular exits.
	var/rail_connections = NORTH | SOUTH

/obj/structure/fluff/tram_rail/cyberpunk/Initialize(mapload)
	. = ..()
	cyberpunk_metro_invalidate_route_path(route_id)

/obj/structure/fluff/tram_rail/cyberpunk/Destroy(force)
	cyberpunk_metro_invalidate_route_path(route_id)
	return ..()

/proc/cyberpunk_metro_rail_at(turf/track_turf, route_id)
	if(!isopenturf(track_turf))
		return null
	for(var/obj/structure/fluff/tram_rail/cyberpunk/rail in track_turf)
		if(!QDELETED(rail) && rail.route_id == route_id)
			return rail
	return null

/proc/cyberpunk_metro_can_step(turf/origin_turf, turf/destination_turf, route_id)
	if(!origin_turf || !destination_turf || origin_turf.z != destination_turf.z || get_dist(origin_turf, destination_turf) != 1)
		return FALSE
	var/direction = get_dir(origin_turf, destination_turf)
	if(!(direction in GLOB.cardinals))
		return FALSE
	var/obj/structure/fluff/tram_rail/cyberpunk/from_rail = cyberpunk_metro_rail_at(origin_turf, route_id)
	var/obj/structure/fluff/tram_rail/cyberpunk/to_rail = cyberpunk_metro_rail_at(destination_turf, route_id)
	return from_rail && to_rail && (from_rail.rail_connections & direction) && (to_rail.rail_connections & REVERSE_DIR(direction))

/proc/cyberpunk_metro_invalidate_route_path(route_id)
	if(!route_id)
		GLOB.cyberpunk_metro_route_path_cache.Cut()
		return
	GLOB.cyberpunk_metro_route_path_cache -= route_id

/proc/cyberpunk_metro_insert_route_landmark(list/route_landmarks, atom/route_landmark)
	var/inserted = FALSE
	var/route_order = cyberpunk_metro_route_landmark_order(route_landmark)
	for(var/index in 1 to length(route_landmarks))
		var/atom/other = route_landmarks[index]
		if(route_order < cyberpunk_metro_route_landmark_order(other))
			route_landmarks.Insert(index, route_landmark)
			inserted = TRUE
			break
	if(!inserted)
		route_landmarks += route_landmark

/proc/cyberpunk_metro_route_landmark_order(atom/route_landmark)
	if(istype(route_landmark, /obj/effect/landmark/cyberpunk_metro_stop))
		var/obj/effect/landmark/cyberpunk_metro_stop/stop = route_landmark
		return stop.route_order
	if(istype(route_landmark, /obj/effect/landmark/cyberpunk_metro_route_point))
		var/obj/effect/landmark/cyberpunk_metro_route_point/route_point = route_landmark
		return route_point.route_order
	return 0

/proc/cyberpunk_metro_train_segments(route_id, train_id)
	var/list/segments = list()
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(segment) || segment.route_id != route_id || segment.train_id != train_id)
			continue
		var/inserted = FALSE
		for(var/index in 1 to length(segments))
			var/obj/structure/cyberpunk_metro_train/other = segments[index]
			if(segment.segment_order < other.segment_order)
				segments.Insert(index, segment)
				inserted = TRUE
				break
		if(!inserted)
			segments += segment
	return segments

/proc/cyberpunk_metro_interior_landmark(route_id, train_id = null)
	var/list/interiors = list()
	for(var/obj/effect/landmark/cyberpunk_metro_interior/interior as anything in GLOB.cyberpunk_metro_interiors)
		if(QDELETED(interior) || interior.route_id != route_id)
			continue
		if(!isnull(train_id) && interior.train_id != train_id)
			continue
		interiors += interior
	if(!length(interiors))
		return null
	return pick(interiors)

/proc/cyberpunk_metro_train_for_route(route_id, train_id = null)
	for(var/obj/structure/cyberpunk_metro_train/train as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(train) || train.route_id != route_id || !train.is_controller)
			continue
		if(!isnull(train_id) && train.train_id != train_id)
			continue
		return train
	return null

/obj/effect/landmark/cyberpunk_metro_stop
	name = "CP13 metro stop"
	icon_state = "navigate"
	color = "#00d9ff"
	/// Stops with the same route id are connected into one cyclic route.
	var/route_id = "main"
	/// Lower values are visited earlier.
	var/route_order = 1
	/// Stable mapper-facing id.
	var/stop_id = "stop"
	/// Where passengers appear relative to the stop landmark.
	var/exit_x_offset = 0
	var/exit_y_offset = -1
	/// Number of generated trains for this route. The subsystem uses the highest value across route stops.
	var/train_count = 1
	/// Template used for generated train interiors on this route.
	var/train_template_path = CYBERPUNK_METRO_TRAIN_TEMPLATE

/obj/effect/landmark/cyberpunk_metro_stop/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_stops += src
	cyberpunk_metro_invalidate_route_path(route_id)

/obj/effect/landmark/cyberpunk_metro_stop/Destroy(force)
	GLOB.cyberpunk_metro_stops -= src
	cyberpunk_metro_invalidate_route_path(route_id)
	return ..()

/obj/effect/landmark/cyberpunk_metro_stop/proc/get_exit_turf()
	var/turf/origin = get_turf(src)
	if(!origin)
		return null
	var/turf/target = locate(origin.x + exit_x_offset, origin.y + exit_y_offset, origin.z)
	if(cyberpunk_turf_is_clear_for_city_spawn(target))
		return target
	for(var/direction in GLOB.cardinals)
		target = get_step(origin, direction)
		if(cyberpunk_turf_is_clear_for_city_spawn(target))
			return target
	return origin

/obj/effect/landmark/cyberpunk_metro_route_point
	name = "CP13 metro route point"
	icon_state = "x2"
	color = "#ff3b4f"
	/// Points with the same route id are inserted between metro stops by route_order.
	var/route_id = "main"
	/// Lower values are visited earlier. Use values between stops to draw turns.
	var/route_order = 1

/obj/effect/landmark/cyberpunk_metro_route_point/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_route_points += src
	cyberpunk_metro_invalidate_route_path(route_id)

/obj/effect/landmark/cyberpunk_metro_route_point/Destroy(force)
	GLOB.cyberpunk_metro_route_points -= src
	cyberpunk_metro_invalidate_route_path(route_id)
	return ..()

/obj/effect/landmark/cyberpunk_metro_interior
	name = "CP13 metro interior spawn"
	icon_state = "x2"
	/// Route whose passengers enter here.
	var/route_id = "main"
	/// Specific generated train on the route. Null keeps legacy/manual single-train behavior.
	var/train_id

/obj/effect/landmark/cyberpunk_metro_interior/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_interiors += src

/obj/effect/landmark/cyberpunk_metro_interior/Destroy(force)
	GLOB.cyberpunk_metro_interiors -= src
	return ..()

/obj/structure/cyberpunk_metro_train
	name = "metro train"
	desc = "A city metro train. Drag yourself onto it or click it while it is stopped to board."
	icon = 'icons/obj/tram/tram_structure.dmi'
	icon_state = "tram-part-0"
	base_icon_state = "tram-part"
	anchored = TRUE
	density = TRUE
	layer = TRAM_WALL_LAYER
	resistance_flags = INDESTRUCTIBLE
	/// Route id matching /obj/effect/landmark/cyberpunk_metro_stop and interior landmarks.
	var/route_id = "main"
	/// Specific generated train on a route. Null keeps legacy/manual single-train behavior.
	var/train_id
	var/state = "docked"
	var/dwell_time = 20 SECONDS
	var/travel_time = 30 SECONDS
	var/move_step_delay = CYBERPUNK_METRO_MOVE_STEP_DELAY
	var/next_departure_at = 0
	var/arrival_at = 0
	var/next_move_at = 0
	var/movement_dir = SOUTH
	var/obj/effect/landmark/cyberpunk_metro_stop/current_stop
	var/obj/effect/landmark/cyberpunk_metro_stop/target_stop
	/// Ordered stop + route point list currently used by the locomotive.
	var/list/route_path = list()
	var/route_path_index = 0
	var/target_route_index = 0
	/// Turf history of the locomotive. Following cars move through this trail instead of using a fixed offset.
	var/list/travel_history = list()
	/// Only one segment per train should control movement.
	var/is_controller = TRUE
	/// Position inside the consist. 1 is the locomotive, higher values follow its travel history.
	var/segment_order = 1
	/// Visual placement relative to the current stop. Cars use this when the controller arrives.
	var/segment_x_offset = 0
	var/segment_y_offset = 0

/obj/structure/cyberpunk_metro_train/Initialize(mapload)
	. = ..()
	set_glide_size(DELAY_TO_GLIDE_SIZE(move_step_delay))
	GLOB.cyberpunk_metro_trains += src

/obj/structure/cyberpunk_metro_train/Destroy(force)
	GLOB.cyberpunk_metro_trains -= src
	current_stop = null
	target_stop = null
	route_path = null
	travel_history = null
	return ..()

/obj/structure/cyberpunk_metro_train/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!istype(user))
		return
	board_passenger(user, src)

/obj/structure/cyberpunk_metro_train/mouse_drop_receive(atom/dropped, mob/user, params)
	. = ..()
	if(!isliving(dropped) || dropped != user)
		return
	var/mob/living/passenger = dropped
	board_passenger(passenger, src)

/obj/structure/cyberpunk_metro_train/proc/process_metro()
	if(!is_controller)
		return
	var/list/stops = cyberpunk_metro_route_stops(route_id)
	if(!length(stops))
		return
	if(!current_stop || QDELETED(current_stop))
		if(!length(travel_history))
			arrive_at(stops[1])
		return
	if(state == "docked")
		if(world.time < next_departure_at)
			return
		target_stop = next_stop(stops)
		if(!target_stop || target_stop == current_stop)
			next_departure_at = world.time + dwell_time
			return
		if(!prepare_route_to(target_stop, cyberpunk_metro_route_path(route_id)))
			next_departure_at = world.time + dwell_time
			return
		close_interior_doors()
		state = "moving"
		arrival_at = 0
		next_move_at = world.time
		sync_consist_state()
		visible_message(span_notice("[capitalize(src.name)] leaves [current_stop.stop_id]."))
		return
	if(state == "moving")
		process_train_movement()

/obj/structure/cyberpunk_metro_train/proc/next_stop(list/stops)
	if(!length(stops))
		return null
	var/current_index = stops.Find(current_stop)
	if(!current_index)
		return stops[1]
	current_index++
	if(current_index > length(stops))
		current_index = 1
	return stops[current_index]

/obj/structure/cyberpunk_metro_train/proc/prepare_route_to(obj/effect/landmark/cyberpunk_metro_stop/stop, list/new_route_path)
	if(!stop || QDELETED(stop))
		return FALSE
	if(!length(new_route_path))
		return FALSE
	if(length(new_route_path) < 2)
		return FALSE
	route_path = new_route_path.Copy()
	route_path_index = route_path.Find(current_stop)
	if(!route_path_index)
		route_path_index = route_path.Find(src)
	if(!route_path_index)
		route_path_index = 1
	target_route_index = next_route_path_index(route_path_index)
	return !!target_route_index

/obj/structure/cyberpunk_metro_train/proc/next_route_path_index(index)
	if(!length(route_path))
		return 0
	index++
	if(index > length(route_path))
		index = 1
	return index

/obj/structure/cyberpunk_metro_train/proc/advance_route_point()
	if(!target_route_index)
		return FALSE
	route_path_index = target_route_index
	target_route_index = next_route_path_index(route_path_index)
	return !!target_route_index

/obj/structure/cyberpunk_metro_train/proc/arrive_at(obj/effect/landmark/cyberpunk_metro_stop/stop)
	if(!stop || QDELETED(stop))
		return
	var/turf/origin = get_turf(stop)
	if(!origin || get_turf(src) != origin || !cyberpunk_metro_rail_at(origin, route_id))
		return
	current_stop = stop
	target_stop = null
	state = "docked"
	next_move_at = 0
	next_departure_at = world.time + dwell_time
	route_path = cyberpunk_metro_route_path(route_id)
	route_path_index = route_path.Find(stop)
	target_route_index = 0
	var/new_movement_dir = movement_dir
	if(route_path_index && length(route_path) > 1)
		var/next_index = next_route_path_index(route_path_index)
		var/atom/next_point = route_path[next_index]
		var/turf/next_turf = get_turf(next_point)
		new_movement_dir = get_cardinal_step_dir(origin, next_turf) || movement_dir
	movement_dir = new_movement_dir
	if(!length(travel_history))
		rebuild_travel_history(origin)
	var/list/segments = cyberpunk_metro_train_segments(route_id, train_id)
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in segments)
		segment.current_stop = stop
		segment.target_stop = null
		segment.state = state
		segment.next_departure_at = next_departure_at
		segment.next_move_at = next_move_at
		segment.route_path = route_path
		segment.route_path_index = route_path_index
		segment.target_route_index = target_route_index
		segment.travel_history = travel_history
		var/turf/segment_turf = origin
		if(segment.segment_order > 1 && length(travel_history) >= segment.segment_order - 1)
			segment_turf = travel_history[segment.segment_order - 1]
		segment.forceMove(segment_turf || origin)
	visible_message(span_notice("[capitalize(src.name)] arrives at [stop.stop_id]."))
	open_interior_doors()

/obj/structure/cyberpunk_metro_train/proc/rebuild_travel_history(turf/origin)
	travel_history = list()
	if(!origin || !route_path_index || !length(route_path))
		return
	var/history_index = route_path_index
	var/turf/history_turf = origin
	for(var/index in 2 to CYBERPUNK_METRO_EXTERIOR_CARS)
		history_index--
		if(history_index < 1)
			history_index = length(route_path)
		var/turf/previous_turf = get_turf(route_path[history_index])
		// The cyclic route may end with the first stop a second time.
		if(previous_turf == history_turf)
			history_index--
			if(history_index < 1)
				history_index = length(route_path)
			previous_turf = get_turf(route_path[history_index])
		if(!cyberpunk_metro_can_step(previous_turf, history_turf, route_id))
			return
		travel_history += previous_turf
		history_turf = previous_turf

/obj/structure/cyberpunk_metro_train/proc/process_train_movement()
	if(!target_stop || QDELETED(target_stop))
		return
	if(world.time < next_move_at)
		return
	if(!length(route_path) || !target_route_index)
		if(!prepare_route_to(target_stop, cyberpunk_metro_route_path(route_id)))
			next_move_at = world.time + 1 SECONDS
			return
	var/turf/current_turf = get_turf(src)
	var/atom/target_point = route_path[target_route_index]
	var/turf/target_turf = get_turf(target_point)
	if(!current_turf || !target_turf)
		return
	if(current_turf == target_turf)
		if(target_point == target_stop)
			arrive_at(target_stop)
		else
			advance_route_point()
		return
	var/step_dir = get_cardinal_step_dir(current_turf, target_turf)
	if(!step_dir)
		next_move_at = world.time + 1 SECONDS
		return
	var/turf/next_turf = get_step(current_turf, step_dir)
	if(next_turf != target_turf || !cyberpunk_metro_can_step(current_turf, next_turf, route_id))
		next_move_at = world.time + 1 SECONDS
		return
	movement_dir = step_dir
	if(!move_consist_to(next_turf, step_dir))
		next_move_at = world.time + 1 SECONDS
		return
	next_move_at = world.time + move_step_delay
	if(get_turf(src) == target_turf)
		if(target_point == target_stop)
			arrive_at(target_stop)
		else
			advance_route_point()

/obj/structure/cyberpunk_metro_train/proc/get_cardinal_step_dir(turf/current_turf, turf/target_turf)
	var/delta_x = target_turf.x - current_turf.x
	var/delta_y = target_turf.y - current_turf.y
	if(abs(delta_x) >= abs(delta_y) && delta_x)
		return delta_x > 0 ? EAST : WEST
	if(delta_y)
		return delta_y > 0 ? NORTH : SOUTH
	return NONE

/obj/structure/cyberpunk_metro_train/proc/move_consist_to(turf/origin, step_dir)
	var/turf/old_origin = get_turf(src)
	if(!cyberpunk_metro_can_step(old_origin, origin, route_id))
		return FALSE
	var/list/new_history = travel_history.Copy()
	new_history.Insert(1, old_origin)
	if(length(new_history) > CYBERPUNK_METRO_EXTERIOR_CARS + 2)
		new_history.Cut(CYBERPUNK_METRO_EXTERIOR_CARS + 3)
	var/list/segments_to_move = list()
	var/list/segment_dirs = list()
	var/list/segments = cyberpunk_metro_train_segments(route_id, train_id)
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in segments)
		var/turf/segment_turf = origin
		if(segment.segment_order > 1)
			var/history_index = segment.segment_order - 1
			if(length(new_history) >= history_index)
				segment_turf = new_history[history_index]
			else
				segment_turf = get_turf(segment)
		if(!segment_turf)
			continue
		var/turf/current_segment_turf = get_turf(segment)
		if(!cyberpunk_metro_can_step(current_segment_turf, segment_turf, route_id))
			return FALSE
		var/segment_dir = get_cardinal_step_dir(current_segment_turf, segment_turf) || step_dir
		segments_to_move[segment] = segment_turf
		segment_dirs[segment] = segment_dir
	travel_history = new_history
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in segments_to_move)
		var/turf/segment_turf = segments_to_move[segment]
		var/segment_dir = segment_dirs[segment]
		segment.clear_metro_path(segment_turf, segment_dir)
		segment.current_stop = current_stop
		segment.target_stop = target_stop
		segment.state = state
		segment.next_departure_at = next_departure_at
		segment.next_move_at = next_move_at
		segment.movement_dir = segment_dir
		segment.route_path = route_path
		segment.route_path_index = route_path_index
		segment.target_route_index = target_route_index
		segment.travel_history = travel_history
		segment.dir = segment_dir
		segment.set_glide_size(DELAY_TO_GLIDE_SIZE(segment.move_step_delay))
		segment.forceMove(segment_turf)
	return TRUE

/obj/structure/cyberpunk_metro_train/proc/clear_metro_path(turf/target_turf, step_dir)
	if(!target_turf)
		return
	if(iswallturf(target_turf))
		var/turf/closed/wall/hit_wall = target_turf
		visible_message(span_danger("[capitalize(src.name)] smashes through [hit_wall]!"))
		hit_wall.dismantle_wall(devastated = TRUE)
	else if(ismineralturf(target_turf))
		var/turf/closed/mineral/hit_mineral = target_turf
		visible_message(span_danger("[capitalize(src.name)] drills through [hit_mineral]!"))
		hit_mineral.gets_drilled()
	for(var/obj/structure/victim_structure in target_turf)
		if(QDELING(victim_structure) || istype(victim_structure, /obj/structure/cyberpunk_metro_train) || istype(victim_structure, /obj/structure/fluff/tram_rail))
			continue
		if(!victim_structure.density && victim_structure.layer <= LOW_OBJ_LAYER)
			continue
		if(victim_structure.anchored)
			visible_message(span_danger("[capitalize(src.name)] smashes through [victim_structure]!"))
			victim_structure.deconstruct(FALSE)
		else
			visible_message(span_danger("[capitalize(src.name)] rams [victim_structure] out of the way!"))
			victim_structure.take_damage(50, BRUTE, MELEE, FALSE)
			victim_structure.throw_at(get_edge_target_turf(victim_structure, step_dir), 8, 3)
	for(var/obj/machinery/victim_machine in target_turf)
		if(QDELING(victim_machine))
			continue
		if(victim_machine.layer < LOW_OBJ_LAYER)
			continue
		visible_message(span_danger("[capitalize(src.name)] smashes through [victim_machine]!"))
		qdel(victim_machine)
	for(var/mob/living/victim_living in target_turf)
		if(QDELING(victim_living))
			continue
		to_chat(victim_living, span_userdanger("[capitalize(src.name)] collides with you!"))
		visible_message(span_danger("[capitalize(src.name)] collides with [victim_living]!"))
		log_combat(src, victim_living, "collided with")
		victim_living.apply_damage(30, BRUTE, BODY_ZONE_CHEST, wound_bonus = 30)
		victim_living.apply_damage(20, BRUTE, BODY_ZONE_HEAD, wound_bonus = 25)
		victim_living.apply_damage(10, BRUTE, BODY_ZONE_L_LEG, wound_bonus = 15)
		victim_living.apply_damage(10, BRUTE, BODY_ZONE_R_LEG, wound_bonus = 15)
		victim_living.throw_at(get_edge_target_turf(victim_living, step_dir), 8, 3)

/obj/structure/cyberpunk_metro_train/proc/sync_consist_state()
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(segment) || segment.route_id != route_id || segment.train_id != train_id)
			continue
		segment.current_stop = current_stop
		segment.target_stop = target_stop
		segment.state = state
		segment.next_departure_at = next_departure_at
		segment.arrival_at = arrival_at
		segment.next_move_at = next_move_at
		segment.movement_dir = movement_dir
		segment.route_path = route_path
		segment.route_path_index = route_path_index
		segment.target_route_index = target_route_index
		segment.travel_history = travel_history

/obj/structure/cyberpunk_metro_train/proc/board_passenger(mob/living/passenger, atom/boarding_source)
	if(!is_controller)
		var/obj/structure/cyberpunk_metro_train/controller = cyberpunk_metro_train_for_route(route_id, train_id)
		return controller?.board_passenger(passenger, boarding_source || src)
	if(state != "docked" || !current_stop)
		passenger.balloon_alert(passenger, "train moving")
		return FALSE
	var/atom/source = boarding_source || src
	if(get_dist(passenger, source) > 1)
		return FALSE
	var/obj/effect/landmark/cyberpunk_metro_interior/interior = cyberpunk_metro_interior_landmark(route_id, train_id)
	if(!interior)
		passenger.balloon_alert(passenger, "no interior")
		return FALSE
	passenger.visible_message(span_notice("[passenger] starts boarding [source]."), span_notice("You start boarding [source]..."))
	if(!do_after(passenger, 1 SECONDS, target = source))
		return FALSE
	if(state != "docked" || !current_stop || QDELETED(interior))
		passenger.balloon_alert(passenger, "doors closed")
		return FALSE
	passenger.forceMove(get_turf(interior))
	to_chat(passenger, span_notice("You board the metro train."))
	return TRUE

/obj/structure/cyberpunk_metro_train/proc/exit_passenger(mob/living/passenger)
	if(!is_controller)
		var/obj/structure/cyberpunk_metro_train/controller = cyberpunk_metro_train_for_route(route_id, train_id)
		return controller?.exit_passenger(passenger)
	if(state != "docked" || !current_stop)
		passenger.balloon_alert(passenger, "train moving")
		return FALSE
	var/turf/exit_turf = current_stop.get_exit_turf()
	if(!exit_turf)
		passenger.balloon_alert(passenger, "no exit")
		return FALSE
	passenger.forceMove(exit_turf)
	to_chat(passenger, span_notice("You step out at [current_stop.stop_id]."))
	return TRUE

/obj/structure/cyberpunk_metro_train/proc/open_interior_doors()
	for(var/obj/structure/cyberpunk_metro_door/door as anything in GLOB.cyberpunk_metro_doors)
		if(door.route_id == route_id && door.train_id == train_id)
			door.set_open(TRUE)

/obj/structure/cyberpunk_metro_train/proc/close_interior_doors()
	for(var/obj/structure/cyberpunk_metro_door/door as anything in GLOB.cyberpunk_metro_doors)
		if(door.route_id == route_id && door.train_id == train_id)
			door.set_open(FALSE)

/obj/structure/cyberpunk_metro_train/locomotive
	name = "metro locomotive"
	is_controller = TRUE
	segment_order = 1

/obj/structure/cyberpunk_metro_train/car
	name = "metro car"
	is_controller = FALSE
	segment_order = 2
	segment_x_offset = 1

/obj/structure/cyberpunk_metro_train/car/second
	name = "metro second car"
	segment_order = 3
	segment_x_offset = 2

/obj/structure/cyberpunk_metro_door
	name = "metro door"
	desc = "A metro interior door that opens only while the train is stopped."
	icon = 'icons/obj/doors/airlocks/station/public.dmi'
	icon_state = "closed"
	anchored = TRUE
	density = TRUE
	/// Route id of the train this door belongs to.
	var/route_id = "main"
	/// Specific generated train on a route. Null keeps legacy/manual single-train behavior.
	var/train_id
	var/opened = FALSE

/obj/structure/cyberpunk_metro_door/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_doors += src
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/cyberpunk_metro_door/Destroy(force)
	GLOB.cyberpunk_metro_doors -= src
	return ..()

/obj/structure/cyberpunk_metro_door/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!istype(user))
		return
	try_exit(user)

/obj/structure/cyberpunk_metro_door/proc/on_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER
	if(isliving(entered))
		try_exit(entered)

/obj/structure/cyberpunk_metro_door/proc/try_exit(mob/living/user)
	if(!opened)
		user.balloon_alert(user, "doors closed")
		return
	var/obj/structure/cyberpunk_metro_train/train = cyberpunk_metro_train_for_route(route_id, train_id)
	if(!train)
		user.balloon_alert(user, "no train")
		return
	train.exit_passenger(user)

/obj/structure/cyberpunk_metro_door/proc/set_open(new_open)
	opened = new_open
	density = !opened
	icon_state = opened ? "open" : "closed"

/// The arrivals train uses the same moving-platform engine as the tram.
/// Its cabin is a converted copy of cyberpunk_metro_train_32x5.dmm.
/turf/open/floor/tram/cyberpunk_intercity
	name = "intercity railway guideway"

/obj/machinery/cryopod/cyberpunk_ticket_terminal
	name = "Терминал выезда из города"
	desc = "Оформляет бесплатный выезд из Брайт-Сити и завершает участие персонажа в текущем раунде."
	icon = 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/metro_ticket_terminal.dmi'
	icon_state = "terminal"
	base_icon_state = "terminal"
	open_icon_state = "terminal"
	interaction_flags_mouse_drop = NONE
	cyberpunk_public_access = TRUE

/obj/machinery/cryopod/cyberpunk_ticket_terminal/find_control_computer(force)
	return FALSE

/obj/machinery/cryopod/cyberpunk_ticket_terminal/mouse_drop_receive(atom/dropped, mob/user, params)
	return FALSE

/obj/machinery/cryopod/cyberpunk_ticket_terminal/can_be_put_inside(mob/target)
	return FALSE

/obj/machinery/cryopod/cyberpunk_ticket_terminal/proc/can_depart(mob/living/customer)
	if(QDELETED(src) || QDELETED(customer) || !customer.client || customer.mind?.current != customer)
		return FALSE
	if(customer.stat != CONSCIOUS || customer.incapacitated || customer.buckled || customer.has_buckled_mobs())
		return FALSE
	return Adjacent(customer) && is_operational && !occupant && SSticker.IsRoundInProgress()

/obj/machinery/cryopod/cyberpunk_ticket_terminal/attack_hand(mob/user, list/modifiers)
	var/mob/living/customer = user
	if(!istype(customer) || !can_depart(customer))
		return TRUE
	var/answer = tgui_alert(
		customer,
		"Персонаж покинет город до конца раунда. Вы перейдёте в наблюдатели, а вещи останутся у терминала.",
		"Желаете покинуть город?",
		list("Покинуть город", "Остаться"),
	)
	if(answer != "Покинуть город" || !can_depart(customer))
		return TRUE

	set_occupant(customer)
	despawn_occupant()
	return TRUE

/obj/machinery/cryopod/cyberpunk_ticket_terminal/despawn_occupant()
	var/mob/living/passenger = occupant
	if(!istype(passenger) || QDELETED(passenger))
		return
	var/role_title = passenger.mind?.assigned_role?.title
	GLOB.joined_player_list -= passenger.ckey || passenger.mind?.key
	handle_occupant_items()
	handle_objectives()
	erase_crew_manifest_record(passenger)
	SSjob.free_job_position(role_title)

	log_game("[key_name(passenger)] departed Bright City via the departure terminal at [AREACOORD(src)].")
	visible_message(span_notice("[passenger] покидает Брайт-Сити."))
	to_chat(passenger, span_notice("Вы покидаете Брайт-Сити."))
	passenger.ghostize(can_reenter_corpse = FALSE)
	set_occupant(null)
	qdel(passenger)

/obj/effect/landmark/cyberpunk_intercity_platform
	name = "intercity platform anchor (southwest corner)"
	var/platform_id = "city"

/obj/structure/transport/linear/tram/cyberpunk_intercity
	name = "intercity train chassis"
	transport_id = "cyberpunk_intercity"
	transport_controller_type = /datum/transport_controller/linear/cyberpunk_intercity
	/// The 32x5 chassis is baked once after its modules merge, before emissive overlays are added.
	var/chassis_icon_composed = FALSE

/obj/structure/transport/linear/tram/cyberpunk_intercity/update_overlays()
	// The parent merge leaves one subfloor overlay per additional tile. Flatten
	// those static sprites before ..() adds an emissive blocker: 159 + 1 exceeds
	// MAX_ATOM_OVERLAYS. Keep unrelated overlays and the physical platform intact.
	if(!chassis_icon_composed && (width > 1 || height > 1))
		var/icon/chassis_icon = icon(icon, icon_state, dir, 1)
		chassis_icon.Crop(1, 1, bound_width, bound_height)
		var/list/chassis_overlays = list()
		for(var/mutable_appearance/tile_appearance as anything in overlays)
			if(tile_appearance.icon != initial(icon) || tile_appearance.plane != plane || findtext(tile_appearance.icon_state, "subfloor") != 1)
				continue
			var/icon/tile_icon = icon(tile_appearance.icon, tile_appearance.icon_state, tile_appearance.dir || dir, 1)
			chassis_icon.Blend(tile_icon, ICON_OVERLAY, tile_appearance.pixel_x + 1, tile_appearance.pixel_y + 1)
			chassis_overlays += tile_appearance
		cut_overlay(chassis_overlays)
		icon = chassis_icon
		icon_state = ""
		chassis_icon_composed = TRUE
	return ..()

/obj/structure/transport/linear/tram/cyberpunk_intercity/register_collision(points = 1)
	SSblackbox.record_feedback("amount", "cyberpunk_intercity_collision", points)


/datum/transport_controller/linear/cyberpunk_intercity
	var/datum/weakref/arrival_ref
	var/turf/target_turf
	var/moving = FALSE
	// A six-tile final approach must remain visible on the compact map.
	var/move_delay = 0.3 SECONDS
	var/next_move_at = 0
	var/datum/looping_sound/tram/rail_sound
	var/datum/turf_reservation/depot_reservation

/datum/transport_controller/linear/cyberpunk_intercity/Destroy()
	STOP_PROCESSING(SStransport, src)
	QDEL_NULL(rail_sound)
	QDEL_NULL(depot_reservation)
	arrival_ref = null
	target_turf = null
	return ..()

/datum/transport_controller/linear/cyberpunk_intercity/proc/start_trip(turf/destination)
	if(moving || !length(transport_modules) || !z_sorted)
		return FALSE
	var/obj/structure/transport/linear/train = transport_modules[1]
	if(!destination || train.z != destination.z || train.y != destination.y || train.x == destination.x)
		return FALSE
	target_turf = destination
	moving = TRUE
	for(var/obj/structure/transport/linear/tram/module as anything in transport_modules)
		module.verify_transport_contents()
		module.internal_movement_delay = move_delay
		module.glide_size_override = DELAY_TO_GLIDE_SIZE(move_delay)
		module.set_travelling(TRUE)
	next_move_at = world.time + move_delay
	SStransport.can_fire = TRUE
	rail_sound?.start()
	START_PROCESSING(SStransport, src)
	return TRUE

/datum/transport_controller/linear/cyberpunk_intercity/process(seconds_per_tick)
	if(!moving || !length(transport_modules) || !target_turf)
		return PROCESS_KILL
	if(world.time < next_move_at)
		return
	var/obj/structure/transport/linear/train = transport_modules[1]
	if(get_turf(train) == target_turf)
		finish_trip()
		return PROCESS_KILL
	if(train.z != target_turf.z || train.y != target_turf.y)
		finish_trip(FALSE)
		return PROCESS_KILL
	var/direction = train.x < target_turf.x ? EAST : WEST
	// Check the entire entering edge before the tram engine can smash anything.
	for(var/obj/structure/transport/linear/module as anything in transport_modules)
		for(var/turf/occupied as anything in module.locs)
			var/turf/next_turf = get_step(occupied, direction)
			if(!istype(next_turf, /turf/open/floor/tram/cyberpunk_intercity))
				finish_trip(FALSE)
				return PROCESS_KILL
	var/old_x = train.x
	move_transport_horizontally(direction)
	if(train.x != old_x + (direction == EAST ? 1 : -1))
		finish_trip(FALSE)
		return PROCESS_KILL
	next_move_at = world.time + move_delay

/// Transfers one assembled cabin between the off-map departure bay and its final approach.
/// The city approach itself still uses tram movement, one rail tile at a time.
/datum/transport_controller/linear/cyberpunk_intercity/proc/transfer_train(turf/destination)
	if(moving || !z_sorted || length(transport_modules) != 1 || !destination)
		return FALSE
	var/obj/structure/transport/linear/module = transport_modules[1]
	module.verify_transport_contents()
	var/list/atom/movable/riders = module.transport_contents.Copy()
	var/list/target_positions = list()
	var/offset_x = destination.x - module.x
	var/offset_y = destination.y - module.y
	for(var/turf/occupied as anything in module.locs)
		var/turf/target = locate(occupied.x + offset_x, occupied.y + offset_y, destination.z)
		if(!istype(target, /turf/open/floor/tram/cyberpunk_intercity))
			return FALSE
		for(var/atom/movable/obstacle in target)
			if(obstacle != module && !(obstacle in riders) && (isliving(obstacle) || obstacle.density))
				return FALSE
	for(var/atom/movable/rider as anything in riders)
		target_positions[rider] = locate(rider.x + offset_x, rider.y + offset_y, destination.z)
	// Snapshot before moving chairs: they can move their buckled occupants too.
	module.unset_movement_registrations()
	module.forceMove(destination)
	if(get_turf(module) != destination)
		module.set_movement_registrations()
		return FALSE
	for(var/atom/movable/rider as anything in riders)
		if(!QDELETED(rider) && rider.loc != target_positions[rider])
			rider.forceMove(target_positions[rider])
	module.set_movement_registrations()
	module.verify_transport_contents()
	target_turf = null
	return TRUE

/datum/transport_controller/linear/cyberpunk_intercity/proc/finish_trip(success = TRUE)
	moving = FALSE
	rail_sound?.stop()
	for(var/obj/structure/transport/linear/tram/module as anything in transport_modules)
		module.set_travelling(FALSE)
	var/obj/docking_port/mobile/arrivals/cyberpunk_intercity/arrival = arrival_ref?.resolve()
	arrival?.train_stopped(success)

/// Adapter for latejoin and announcements. Physical movement belongs to SStransport.
/obj/docking_port/mobile/arrivals/cyberpunk_intercity
	name = "intercity arrivals train"
	invisibility = INVISIBILITY_MAXIMUM // Must travel with the tram's contents.
	dir = NORTH
	width = 32
	height = 5
	mode = SHUTTLE_CALL
	var/datum/transport_controller/linear/cyberpunk_intercity/train_controller
	var/turf/city_platform
	var/turf/approach_platform
	var/turf/depot_platform
	var/list/train_doors = list()
	var/departure_at = 0
	var/departing = FALSE
	var/old_require_undocked
	var/configured_latejoin = FALSE

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/LateInitialize()
	var/obj/structure/transport/linear/tram/cyberpunk_intercity/chassis = locate() in loc
	train_controller = chassis?.transport_controller_datum
	if(!istype(train_controller))
		stack_trace("Intercity arrival port has no matching tram chassis.")
		return
	train_controller.arrival_ref = WEAKREF(src)
	train_controller.rail_sound = new(src)
	for(var/obj/effect/landmark/cyberpunk_intercity_platform/platform in world)
		if(platform.z != z)
			continue
		if(platform.platform_id == "city")
			city_platform = get_turf(platform)
		else if(platform.platform_id == "approach")
			approach_platform = get_turf(platform)
	if(!city_platform || !approach_platform || city_platform.y != approach_platform.y || get_turf(chassis) != approach_platform)
		stack_trace("Intercity train needs aligned city/approach anchors and must be mapped at the approach.")
		return
	var/list/seats = list()
	for(var/obj/structure/transport/linear/module as anything in train_controller.transport_modules)
		for(var/atom/movable/rider as anything in module.transport_contents)
			if(istype(rider, /obj/structure/chair))
				seats |= rider
			else if(istype(rider, /obj/machinery/door/airlock/shuttle/cyberpunk_intercity))
				train_doors |= rider
			else if(istype(rider, /obj/machinery/requests_console))
				console = rider
	if(!length(seats) || !length(train_doors))
		stack_trace("Intercity train has no passenger seats or platform doors.")
		return
	SSjob.latejoin_trackers = seats
	old_require_undocked = CONFIG_GET(flag/arrivals_shuttle_require_undocked)
	CONFIG_SET(flag/arrivals_shuttle_require_undocked, TRUE)
	configured_latejoin = TRUE
	if(!registered)
		register()
	// Let the tram's LateInitialize merge all 160 chassis tiles first.
	addtimer(CALLBACK(src, PROC_REF(setup_remote_depot)), 1 TICKS)

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/proc/setup_remote_depot()
	if(QDELETED(train_controller) || depot_platform)
		return
	if(!train_controller.z_sorted)
		addtimer(CALLBACK(src, PROC_REF(setup_remote_depot)), 1 TICKS)
		return
	var/datum/map_template/template = new("_maps/templates/cyberpunk_intercity_depot_34x7.dmm", "Intercity departure bay")
	var/datum/turf_reservation/reservation = SSmapping.request_turf_block_reservation(template.width, template.height, 1)
	if(!reservation || !length(reservation.bottom_left_turfs))
		QDEL_NULL(reservation)
		qdel(template)
		stack_trace("Could not reserve the intercity departure bay.")
		return
	var/turf/load_turf = reservation.bottom_left_turfs[1]
	if(!template.load(load_turf))
		qdel(reservation)
		qdel(template)
		stack_trace("Could not load the intercity departure bay.")
		return
	var/turf/remote_platform = locate(load_turf.x + 1, load_turf.y + 1, load_turf.z)
	qdel(template)
	if(!train_controller.transfer_train(remote_platform))
		qdel(reservation)
		stack_trace("Could not transfer the intercity train to its departure bay.")
		return
	train_controller.depot_reservation = reservation
	depot_platform = remote_platform
	mode = SHUTTLE_CALL

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/Destroy(force)
	if(!force)
		return ..()
	if(configured_latejoin)
		CONFIG_SET(flag/arrivals_shuttle_require_undocked, old_require_undocked)
	if(!QDELETED(train_controller))
		train_controller.arrival_ref = null
	train_controller = null
	train_doors = null
	city_platform = null
	approach_platform = null
	depot_platform = null
	return ..()

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/proc/at_platform(turf/platform)
	if(!platform || QDELETED(train_controller) || train_controller.moving || !length(train_controller.transport_modules))
		return FALSE
	return get_turf(train_controller.transport_modules[1]) == platform

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/PersonCheck()
	if(QDELETED(train_controller))
		return FALSE
	for(var/obj/structure/transport/linear/module as anything in train_controller.transport_modules)
		for(var/turf/cabin_turf as anything in module.locs)
			for(var/mob/player in cabin_turf)
				if(player.client && player.stat != DEAD)
					return TRUE
	return FALSE

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/check()
	if(QDELETED(train_controller) || train_controller.moving || damaged || !depot_platform)
		return
	if(at_platform(approach_platform))
		if(mode == SHUTTLE_IGNITING)
			train_stopped(TRUE)
		else
			begin_train_trip(city_platform)
		return
	if(at_platform(depot_platform))
		mode = SHUTTLE_CALL
		if(PersonCheck())
			if(!departure_at)
				departure_at = world.time + 5 SECONDS
			if(world.time >= departure_at)
				begin_train_trip(city_platform)
	else if(at_platform(city_platform) && world.time >= departure_at)
		if(force_depart || !PersonCheck())
			begin_train_trip(depot_platform)

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/proc/begin_train_trip(turf/destination)
	// Doors can take time to close or be obstructed; never move until every door is shut.
	departing = TRUE
	var/doors_ready = TRUE
	for(var/obj/machinery/door/airlock/shuttle/cyberpunk_intercity/door as anything in train_doors)
		if(QDELETED(door))
			damaged = TRUE
			return FALSE
		if(door.operating || !door.density)
			doors_ready = FALSE
			if(!door.operating)
				INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, close))
	if(!doors_ready)
		return FALSE
	mode = destination == city_platform ? SHUTTLE_CALL : SHUTTLE_IGNITING
	var/turf/rail_destination = approach_platform
	if(destination == city_platform)
		if(at_platform(depot_platform) && !train_controller.transfer_train(approach_platform))
			return FALSE
		rail_destination = city_platform
	if(!train_controller.start_trip(rail_destination))
		return FALSE
	departure_at = 0
	console?.say("Двери закрываются. Поезд отправляется.")
	return TRUE

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/proc/train_stopped(success)
	if(!success)
		damaged = TRUE
		console?.say("Поезд остановлен: проверьте непрерывность путей.")
		return
	if(mode == SHUTTLE_IGNITING && at_platform(approach_platform))
		if(!train_controller.transfer_train(depot_platform))
			return
	force_depart = FALSE
	departing = FALSE
	departure_at = 0
	if(at_platform(city_platform))
		mode = SHUTTLE_IDLE
		departure_at = world.time + 15 SECONDS
		console?.say("Брайт Сити. Конечная. Выход на городской перрон.")
		for(var/obj/machinery/door/airlock/shuttle/cyberpunk_intercity/door as anything in train_doors)
			INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open))
		for(var/datum/callback/announcement as anything in queued_announces)
			announcement.Invoke()
		LAZYCLEARLIST(queued_announces)
	else
		mode = SHUTTLE_CALL

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/Launch(pickingup)
	if(pickingup)
		force_depart = TRUE
	if(at_platform(city_platform))
		departure_at = min(departure_at, world.time)

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/RequireUndocked(mob/user)
	if(at_platform(depot_platform))
		return
	Launch(TRUE)
	to_chat(user, span_notice("Ожидаем междугородний поезд на станции отправления..."))
	while(!QDELETED(src) && !at_platform(depot_platform))
		stoplag()

/obj/docking_port/mobile/arrivals/cyberpunk_intercity/check_effects()
	return // No hyperspace ripples on a physical railway.

/obj/machinery/door/airlock/shuttle/cyberpunk_intercity
	name = "intercity platform door"
	autoclose = FALSE

/obj/machinery/door/airlock/shuttle/cyberpunk_intercity/open(forced = DEFAULT_DOOR_CHECKS)
	var/obj/docking_port/mobile/arrivals/cyberpunk_intercity/train = SSshuttle.arrivals
	if(!istype(train) || train.departing || !train.at_platform(train.city_platform) || train.mode != SHUTTLE_IDLE)
		return FALSE
	return ..()

#undef CYBERPUNK_METRO_TRAIN_TEMPLATE
#undef CYBERPUNK_METRO_EXTERIOR_CARS
#undef CYBERPUNK_METRO_MOVE_STEP_DELAY

GLOBAL_LIST_EMPTY(cyberpunk_dungeon_instances)

#define CYBERPUNK_DUNGEON_CHUNK_SIZE 16
#define CYBERPUNK_DUNGEON_DEFAULT_WIDTH 5
#define CYBERPUNK_DUNGEON_DEFAULT_HEIGHT 5

#define CYBERPUNK_DUNGEON_EXIT_NORTH (1<<0)
#define CYBERPUNK_DUNGEON_EXIT_EAST (1<<1)
#define CYBERPUNK_DUNGEON_EXIT_SOUTH (1<<2)
#define CYBERPUNK_DUNGEON_EXIT_WEST (1<<3)
#define CYBERPUNK_DUNGEON_EXIT_ALL (CYBERPUNK_DUNGEON_EXIT_NORTH|CYBERPUNK_DUNGEON_EXIT_EAST|CYBERPUNK_DUNGEON_EXIT_SOUTH|CYBERPUNK_DUNGEON_EXIT_WEST)

/datum/cyberpunk_dungeon_chunk
	/// Stable id used by logs and future config files.
	var/id = "chunk"
	/// Human-readable label.
	var/name = "dungeon chunk"
	/// Visual/mechanical set. Current first pass ships with cave.
	var/theme = "cave"
	/// DMM template path. Chunk templates are expected to be 16x16 for now.
	var/template_path
	/// Bitfield of open edges this chunk can satisfy.
	var/exit_flags = CYBERPUNK_DUNGEON_EXIT_ALL
	/// Weighted selection inside matching candidates.
	var/weight = 1
	/// Roles this template can serve: normal/start/loot/boss/exit.
	var/list/roles = list("normal")
	/// Depth gates are intentionally loose; depth is path distance from entry.
	var/min_depth = 0
	var/max_depth = INFINITY

/datum/cyberpunk_dungeon_chunk/proc/can_place(required_theme, required_exits, role, depth)
	if(required_theme && theme != required_theme)
		return FALSE
	if(template_path && !fexists(template_path))
		return FALSE
	if((exit_flags & required_exits) != required_exits)
		return FALSE
	if(role && !(role in roles))
		return FALSE
	if(depth < min_depth || depth > max_depth)
		return FALSE
	return TRUE

/datum/cyberpunk_dungeon_chunk/cave/chamber
	id = "cave_chamber"
	name = "cave chamber"
	template_path = "_maps/templates/cyberpunk_dungeons/cave_chamber_16.dmm"
	weight = 6

/datum/cyberpunk_dungeon_chunk/cave/start
	id = "cave_start"
	name = "cave entry chamber"
	template_path = "_maps/templates/cyberpunk_dungeons/cave_start_16.dmm"
	roles = list("start")

/datum/cyberpunk_dungeon_chunk/cave/loot
	id = "cave_loot"
	name = "cave resource pocket"
	template_path = "_maps/templates/cyberpunk_dungeons/cave_loot_16.dmm"
	roles = list("loot")
	weight = 2

/datum/cyberpunk_dungeon_chunk/cave/boss
	id = "cave_boss"
	name = "cave boss chamber"
	template_path = "_maps/templates/cyberpunk_dungeons/cave_boss_16.dmm"
	roles = list("boss")
	min_depth = 3

/datum/cyberpunk_dungeon_chunk/cave/exit
	id = "cave_exit"
	name = "cave exit chamber"
	template_path = "_maps/templates/cyberpunk_dungeons/cave_exit_16.dmm"
	roles = list("exit")
	min_depth = 2

/proc/cyberpunk_dungeon_chunks()
	var/static/list/chunks
	if(chunks)
		return chunks
	chunks = list()
	for(var/chunk_type in subtypesof(/datum/cyberpunk_dungeon_chunk))
		chunks += new chunk_type
	return chunks

/proc/cyberpunk_dungeon_exit_flag(direction)
	switch(direction)
		if(NORTH)
			return CYBERPUNK_DUNGEON_EXIT_NORTH
		if(EAST)
			return CYBERPUNK_DUNGEON_EXIT_EAST
		if(SOUTH)
			return CYBERPUNK_DUNGEON_EXIT_SOUTH
		if(WEST)
			return CYBERPUNK_DUNGEON_EXIT_WEST
	return 0

/proc/cyberpunk_dungeon_opposite_exit_flag(direction)
	switch(direction)
		if(NORTH)
			return CYBERPUNK_DUNGEON_EXIT_SOUTH
		if(EAST)
			return CYBERPUNK_DUNGEON_EXIT_WEST
		if(SOUTH)
			return CYBERPUNK_DUNGEON_EXIT_NORTH
		if(WEST)
			return CYBERPUNK_DUNGEON_EXIT_EAST
	return 0

/proc/cyberpunk_dungeon_dir_between(from_x, from_y, to_x, to_y)
	if(to_x > from_x)
		return EAST
	if(to_x < from_x)
		return WEST
	if(to_y > from_y)
		return NORTH
	if(to_y < from_y)
		return SOUTH
	return NONE

/proc/cyberpunk_dungeon_cell_key(x_pos, y_pos)
	return "[x_pos],[y_pos]"

/proc/cyberpunk_dungeon_pick_chunk(theme, required_exits, role, depth)
	var/list/candidates = list()
	for(var/datum/cyberpunk_dungeon_chunk/chunk as anything in cyberpunk_dungeon_chunks())
		if(chunk.can_place(theme, required_exits, role, depth))
			candidates[chunk] = chunk.weight
	if(length(candidates))
		return pick_weight(candidates)

	if(role != "normal")
		for(var/datum/cyberpunk_dungeon_chunk/chunk as anything in cyberpunk_dungeon_chunks())
			if(chunk.can_place(theme, required_exits, "normal", depth))
				candidates[chunk] = chunk.weight
		if(length(candidates))
			return pick_weight(candidates)

	for(var/datum/cyberpunk_dungeon_chunk/chunk as anything in cyberpunk_dungeon_chunks())
		if(chunk.can_place(null, required_exits, null, depth))
			candidates[chunk] = chunk.weight
	if(length(candidates))
		return pick_weight(candidates)

	return null

/proc/cyberpunk_dungeon_theme_name(theme)
	switch(theme)
		if("metro")
			return "abandoned metro"
		if("corporate")
			return "corporate blacksite"
		if("wasteland")
			return "wasteland bunker"
	return "underground cave"

/proc/cyberpunk_dungeon_threat_name(theme, boss = FALSE)
	switch(theme)
		if("metro")
			return boss ? "metro alpha predator" : "metro tunnel threat"
		if("corporate")
			return boss ? "blacksite security chief" : "blacksite security remnant"
		if("wasteland")
			return boss ? "wasteland apex mutant" : "wasteland scavenger beast"
	return boss ? "dungeon boss" : "dungeon threat"

/proc/cyberpunk_dungeon_style_registry()
	var/static/list/styles
	if(styles)
		return styles
	styles = list(
		"cave" = list(
			"id" = "cave",
			"name" = "Underground Cave",
			"description" = "Natural underground routes and resource pockets.",
			"entrance_type" = /obj/structure/cyberpunk_dungeon_entrance,
			"theme" = "cave",
			"difficulty" = 1,
			"chunk_templates" = list(
				"_maps/templates/cyberpunk_dungeons/cave_start_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_chamber_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_loot_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_boss_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_exit_16.dmm",
			),
			"room_templates" = list(),
			"threat_types" = list(
				/mob/living/basic/mining/watcher,
				/mob/living/basic/mining/goliath,
				/mob/living/basic/mining/legion,
			),
			"loot_types" = list(
				/obj/item/stack/ore/iron,
				/obj/item/stack/ore/silver,
				/obj/item/stack/ore/titanium,
				/obj/item/stack/ore/gold,
			),
		),
		"metro" = list(
			"id" = "metro",
			"name" = "Abandoned Metro",
			"description" = "Old tunnels, cable salvage, broken city infrastructure.",
			"entrance_type" = /obj/structure/cyberpunk_dungeon_entrance/metro,
			"theme" = "metro",
			"difficulty" = 2,
			"chunk_templates" = list(
				"_maps/templates/cyberpunk_dungeons/cave_start_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_chamber_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_loot_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_boss_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_exit_16.dmm",
			),
			"room_templates" = list(),
			"threat_types" = list(
				/mob/living/basic/mining/watcher,
				/mob/living/basic/mining/legion,
				/mob/living/basic/mining/goliath,
			),
			"loot_types" = list(
				/obj/item/stack/sheet/iron,
				/obj/item/stack/cable_coil,
				/obj/item/stack/sheet/glass,
				/obj/item/stack/ore/silver,
			),
		),
		"corporate" = list(
			"id" = "corporate",
			"name" = "Corporate Blacksite",
			"description" = "Sealed installations, plasteel, glass, high-value ore.",
			"entrance_type" = /obj/structure/cyberpunk_dungeon_entrance/corporate,
			"theme" = "corporate",
			"difficulty" = 3,
			"chunk_templates" = list(
				"_maps/templates/cyberpunk_dungeons/cave_start_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_chamber_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_loot_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_boss_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_exit_16.dmm",
			),
			"room_templates" = list(),
			"threat_types" = list(
				/mob/living/basic/mining/watcher,
				/mob/living/basic/mining/goliath,
			),
			"loot_types" = list(
				/obj/item/stack/sheet/plasteel,
				/obj/item/stack/sheet/glass,
				/obj/item/stack/ore/gold,
				/obj/item/stack/ore/titanium,
			),
		),
		"wasteland" = list(
			"id" = "wasteland",
			"name" = "Wasteland Bunker",
			"description" = "Edge-city bunkers, heavy beasts, mixed salvage.",
			"entrance_type" = /obj/structure/cyberpunk_dungeon_entrance/wasteland,
			"theme" = "wasteland",
			"difficulty" = 2,
			"chunk_templates" = list(
				"_maps/templates/cyberpunk_dungeons/cave_start_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_chamber_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_loot_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_boss_16.dmm",
				"_maps/templates/cyberpunk_dungeons/cave_exit_16.dmm",
			),
			"room_templates" = list(),
			"threat_types" = list(
				/mob/living/basic/mining/goliath,
				/mob/living/basic/mining/legion,
				/mob/living/basic/mining/watcher,
			),
			"loot_types" = list(
				/obj/item/stack/ore/iron,
				/obj/item/stack/sheet/iron,
				/obj/item/stack/ore/titanium,
				/obj/item/stack/ore/gold,
			),
		),
	)
	return styles

/proc/cyberpunk_dungeon_style_record(style_id)
	var/list/styles = cyberpunk_dungeon_style_registry()
	return styles[style_id]

/proc/cyberpunk_dungeon_style_path_rows(list/paths)
	var/list/rows = list()
	for(var/path in paths)
		rows += "[path]"
	return rows

/datum/cyberpunk_dungeon_instance
	var/instance_id
	var/theme = "cave"
	var/difficulty = 1
	var/width_chunks = CYBERPUNK_DUNGEON_DEFAULT_WIDTH
	var/height_chunks = CYBERPUNK_DUNGEON_DEFAULT_HEIGHT
	var/chunk_size = CYBERPUNK_DUNGEON_CHUNK_SIZE
	var/generated = FALSE
	var/generating = FALSE
	var/datum/weakref/entry_ref
	var/turf/return_turf
	var/z_value
	var/turf/start_turf
	var/turf/exit_turf
	var/list/generated_atoms = list()
	var/list/dungeon_landmarks = list()
	var/datum/turf_reservation/reservation
	var/closing = FALSE
	var/completed = FALSE

/datum/cyberpunk_dungeon_instance/New(obj/structure/cyberpunk_dungeon_entrance/entry, new_theme, new_difficulty, new_width_chunks, new_height_chunks)
	. = ..()
	instance_id = "dungeon_[world.time]_[rand(1000, 9999)]"
	if(entry)
		entry_ref = WEAKREF(entry)
		return_turf = get_turf(entry)
	if(new_theme)
		theme = new_theme
	if(new_difficulty)
		difficulty = max(1, new_difficulty)
	if(new_width_chunks)
		width_chunks = max(3, new_width_chunks)
	if(new_height_chunks)
		height_chunks = max(3, new_height_chunks)
	GLOB.cyberpunk_dungeon_instances += src

/datum/cyberpunk_dungeon_instance/Destroy(force)
	GLOB.cyberpunk_dungeon_instances -= src
	var/obj/structure/cyberpunk_dungeon_entrance/entry = entry_ref?.resolve()
	if(entry?.instance == src)
		entry.instance = null
	QDEL_NULL(reservation)
	entry_ref = null
	return_turf = null
	start_turf = null
	exit_turf = null
	generated_atoms = null
	dungeon_landmarks = null
	return ..()

/datum/cyberpunk_dungeon_instance/proc/begin_collapse(reason = "entrance destroyed")
	if(closing)
		return
	closing = TRUE
	var/obj/structure/cyberpunk_dungeon_entrance/entry = entry_ref?.resolve()
	if(entry)
		entry.closed = TRUE
		SSpoints_of_interest?.remove_point_of_interest(entry)
	for(var/mob/living/person as anything in GLOB.mob_living_list)
		if(person.z == z_value)
			to_chat(person, span_warning("This route is collapsing. Return to the exit within two minutes."))
	SScyberpunk_round?.record_cyberpunk_round_event("dungeon_closed", "poi", "city", SScyberpunk_round.cyberpunk_round_chaos, "[instance_id]: [reason]", "completed")
	addtimer(CALLBACK(src, PROC_REF(finish_collapse)), 2 MINUTES)

/datum/cyberpunk_dungeon_instance/proc/finish_collapse()
	if(z_value)
		for(var/mob/living/person as anything in GLOB.mob_living_list)
			var/datum/ai_controller/controller = person.ai_controller
			var/turf/phantom_turf = controller?.blackboard[BB_CP_PHANTOM_APPROX_TURF]
			if(person.z == z_value || (isnull(person.loc) && phantom_turf?.z == z_value))
				if(!return_turf)
					return
				controller?.cyberpunk_materialize_phantom("dungeon closing")
				if(person.buckled)
					person.buckled.unbuckle_mob(person, force = TRUE)
				person.forceMove(return_turf)
	qdel(src)

/datum/cyberpunk_dungeon_instance/proc/ensure_generated()
	if(generated)
		return TRUE
	if(generating)
		return FALSE
	generating = TRUE
	var/result = generate()
	generating = FALSE
	generated = result
	if(!result)
		QDEL_NULL(reservation)
		z_value = null
		start_turf = null
		exit_turf = null
		generated_atoms.Cut()
		dungeon_landmarks.Cut()
	return result

/datum/cyberpunk_dungeon_instance/proc/enter(mob/living/user)
	if(!istype(user) || closing)
		return FALSE
	if(!ensure_generated())
		user.balloon_alert(user, "dungeon failed")
		return FALSE
	if(!start_turf)
		user.balloon_alert(user, "no entry")
		return FALSE
	user.forceMove(start_turf)
	to_chat(user, span_notice("You descend into [cyberpunk_dungeon_theme_name(theme)]."))
	return TRUE

/datum/cyberpunk_dungeon_instance/proc/leave(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!return_turf)
		var/obj/structure/cyberpunk_dungeon_entrance/entry = entry_ref?.resolve()
		return_turf = get_turf(entry)
	if(!return_turf)
		user.balloon_alert(user, "no return")
		return FALSE
	user.forceMove(return_turf)
	to_chat(user, span_notice("You return to the city."))
	return TRUE

/datum/cyberpunk_dungeon_instance/proc/generate()
	var/total_width = width_chunks * chunk_size
	var/total_height = height_chunks * chunk_size
	if(total_width + 4 > world.maxx || total_height + 4 > world.maxy)
		stack_trace("Cyberpunk dungeon [instance_id] is too large for world bounds: [total_width]x[total_height].")
		return FALSE

	// A whole-level reservation preserves isolated dungeons and lets mapping recycle their space.
	reservation = SSmapping.request_turf_block_reservation(world.maxx - 4, world.maxy - 4)
	if(!reservation)
		stack_trace("Cyberpunk dungeon [instance_id] failed to create a z-level.")
		return FALSE
	var/turf/origin = reservation.bottom_left_turfs[1]
	z_value = origin.z

	var/list/plan = build_plan()
	if(!length(plan))
		stack_trace("Cyberpunk dungeon [instance_id] generated an empty plan.")
		return FALSE

	var/origin_x = origin.x
	var/origin_y = origin.y
	for(var/key as anything in plan)
		var/list/cell = plan[key]
		var/datum/cyberpunk_dungeon_chunk/chunk = cyberpunk_dungeon_pick_chunk(theme, cell["exits"], cell["role"], cell["depth"])
		if(!chunk)
			stack_trace("Cyberpunk dungeon [instance_id] has no chunk for role [cell["role"]] exits [cell["exits"]].")
			return FALSE
		if(!load_chunk(chunk, origin_x + ((cell["x"] - 1) * chunk_size), origin_y + ((cell["y"] - 1) * chunk_size)))
			return FALSE

	spawn_content()
	if(!start_turf)
		start_turf = locate(origin_x + 7, origin_y + ((round((height_chunks + 1) / 2) - 1) * chunk_size) + 7, z_value)
	if(!exit_turf)
		exit_turf = locate(origin_x + ((width_chunks - 1) * chunk_size) + 7, origin_y + ((round((height_chunks + 1) / 2) - 1) * chunk_size) + 7, z_value)
	var/obj/structure/closet/crate/cyberpunk_dungeon_reward/reward = new(exit_turf)
	reward.instance_ref = WEAKREF(src)
	generated_atoms += reward
	log_game("Cyberpunk dungeon [instance_id] generated [length(plan)] [theme] chunks on z[z_value].")
	SScyberpunk_round?.record_cyberpunk_round_event("dungeon_generated", "poi", "city", SScyberpunk_round.cyberpunk_round_chaos, "Generated [theme] dungeon [instance_id] with [length(plan)] chunks.", "executed")
	return TRUE

/datum/cyberpunk_dungeon_instance/proc/build_plan()
	var/list/cells = list()
	var/start_y = round((height_chunks + 1) / 2)
	var/current_x = 1
	var/current_y = start_y
	var/list/main_path = list()

	var/list/start_cell = ensure_cell(cells, current_x, current_y)
	start_cell["role"] = "start"
	main_path += list(start_cell)

	var/guard = width_chunks * height_chunks * 4
	while(current_x < width_chunks && guard-- > 0)
		var/list/choices = list()
		choices[EAST] = 6
		if(current_y < height_chunks)
			choices[NORTH] = 2
		if(current_y > 1)
			choices[SOUTH] = 2
		var/chosen_dir = pick_weight(choices)
		var/next_x = current_x
		var/next_y = current_y
		switch(chosen_dir)
			if(EAST)
				next_x++
			if(NORTH)
				next_y++
			if(SOUTH)
				next_y--
		if(next_x < 1 || next_x > width_chunks || next_y < 1 || next_y > height_chunks)
			continue
		connect_cells(cells, current_x, current_y, next_x, next_y)
		current_x = next_x
		current_y = next_y
		var/list/current_cell = ensure_cell(cells, current_x, current_y)
		main_path += list(current_cell)

	var/list/end_cell = ensure_cell(cells, current_x, current_y)
	end_cell["role"] = "exit"
	if(length(main_path) >= 3)
		var/list/boss_cell = main_path[max(2, length(main_path) - 1)]
		if(boss_cell["role"] == "normal")
			boss_cell["role"] = "boss"

	for(var/list/path_cell as anything in main_path)
		if(prob(25))
			try_add_branch(cells, path_cell)

	for(var/key as anything in cells)
		var/list/cell = cells[key]
		cell["depth"] = abs(cell["x"] - 1) + abs(cell["y"] - start_y)

	return cells

/datum/cyberpunk_dungeon_instance/proc/ensure_cell(list/cells, x_pos, y_pos)
	var/key = cyberpunk_dungeon_cell_key(x_pos, y_pos)
	var/list/cell = cells[key]
	if(!cell)
		cell = list(
			"x" = x_pos,
			"y" = y_pos,
			"exits" = 0,
			"role" = "normal",
			"depth" = 0,
		)
		cells[key] = cell
	return cell

/datum/cyberpunk_dungeon_instance/proc/connect_cells(list/cells, from_x, from_y, to_x, to_y)
	var/direction = cyberpunk_dungeon_dir_between(from_x, from_y, to_x, to_y)
	if(!direction)
		return FALSE
	var/list/from_cell = ensure_cell(cells, from_x, from_y)
	var/list/to_cell = ensure_cell(cells, to_x, to_y)
	from_cell["exits"] |= cyberpunk_dungeon_exit_flag(direction)
	to_cell["exits"] |= cyberpunk_dungeon_opposite_exit_flag(direction)
	return TRUE

/datum/cyberpunk_dungeon_instance/proc/try_add_branch(list/cells, list/path_cell)
	var/list/options = list(NORTH, SOUTH, EAST, WEST)
	while(length(options))
		var/chosen_dir = pick(options)
		options -= chosen_dir
		var/branch_x = path_cell["x"]
		var/branch_y = path_cell["y"]
		switch(chosen_dir)
			if(NORTH)
				branch_y++
			if(SOUTH)
				branch_y--
			if(EAST)
				branch_x++
			if(WEST)
				branch_x--
		if(branch_x < 1 || branch_x > width_chunks || branch_y < 1 || branch_y > height_chunks)
			continue
		var/key = cyberpunk_dungeon_cell_key(branch_x, branch_y)
		if(cells[key])
			continue
		connect_cells(cells, path_cell["x"], path_cell["y"], branch_x, branch_y)
		var/list/branch_cell = cells[key]
		branch_cell["role"] = prob(45) ? "loot" : "normal"
		return TRUE
	return FALSE

/datum/cyberpunk_dungeon_instance/proc/load_chunk(datum/cyberpunk_dungeon_chunk/chunk, x_pos, y_pos)
	var/turf/load_turf = locate(x_pos, y_pos, z_value)
	if(!load_turf)
		stack_trace("Cyberpunk dungeon [instance_id] failed to locate chunk turf [x_pos],[y_pos],[z_value].")
		return FALSE
	var/datum/map_template/template = new(chunk.template_path, "Cyberpunk Dungeon [chunk.id]")
	if(template.width != chunk_size || template.height != chunk_size)
		stack_trace("Cyberpunk dungeon chunk [chunk.id] must be [chunk_size]x[chunk_size], got [template.width]x[template.height].")
		qdel(template)
		return FALSE
	template.returns_created_atoms = TRUE
	if(!template.load(load_turf))
		stack_trace("Cyberpunk dungeon [instance_id] failed to load chunk [chunk.id] at [x_pos],[y_pos],[z_value].")
		qdel(template)
		return FALSE
	for(var/atom/created as anything in template.created_atoms)
		generated_atoms += created
		if(istype(created, /obj/effect/landmark/cyberpunk_dungeon))
			var/obj/effect/landmark/cyberpunk_dungeon/landmark = created
			landmark.instance_id = instance_id
			dungeon_landmarks += landmark
	template.created_atoms.Cut()
	qdel(template)
	return TRUE

/datum/cyberpunk_dungeon_instance/proc/spawn_content()
	for(var/obj/effect/landmark/cyberpunk_dungeon/landmark as anything in dungeon_landmarks)
		if(QDELETED(landmark))
			continue
		var/turf/landmark_turf = get_turf(landmark)
		if(!landmark_turf)
			continue
		if(istype(landmark, /obj/effect/landmark/cyberpunk_dungeon/start))
			start_turf = landmark_turf
		else if(istype(landmark, /obj/effect/landmark/cyberpunk_dungeon/exit))
			exit_turf = landmark_turf
			var/obj/structure/cyberpunk_dungeon_exit/exit = new(landmark_turf)
			exit.instance = src
			generated_atoms += exit
		else if(istype(landmark, /obj/effect/landmark/cyberpunk_dungeon/enemy))
			spawn_enemy(landmark_turf)
		else if(istype(landmark, /obj/effect/landmark/cyberpunk_dungeon/boss))
			spawn_boss(landmark_turf)
		else if(istype(landmark, /obj/effect/landmark/cyberpunk_dungeon/loot))
			spawn_loot(landmark_turf)
		qdel(landmark)

/datum/cyberpunk_dungeon_instance/proc/spawn_enemy(turf/spawn_turf)
	var/list/enemies = list(
		/mob/living/basic/mining/watcher = 4,
		/mob/living/basic/mining/goliath = 2,
		/mob/living/basic/mining/legion = 1,
	)
	if(theme == "metro")
		enemies = list(
			/mob/living/basic/mining/watcher = 3,
			/mob/living/basic/mining/legion = 3,
			/mob/living/basic/mining/goliath = 1,
		)
	else if(theme == "corporate")
		enemies = list(
			/mob/living/basic/mining/watcher = 5,
			/mob/living/basic/mining/goliath = 1,
		)
	else if(theme == "wasteland")
		enemies = list(
			/mob/living/basic/mining/goliath = 4,
			/mob/living/basic/mining/legion = 2,
			/mob/living/basic/mining/watcher = 1,
		)
	var/enemy_type = pick_weight(enemies)
	var/mob/living/enemy = new enemy_type(spawn_turf)
	enemy.name = cyberpunk_dungeon_threat_name(theme)
	generated_atoms += enemy
	return enemy

/datum/cyberpunk_dungeon_instance/proc/spawn_boss(turf/spawn_turf)
	var/boss_type = difficulty >= 3 ? /mob/living/basic/mining/goliath/ancient : /mob/living/basic/mining/goliath
	var/mob/living/boss = new boss_type(spawn_turf)
	boss.name = cyberpunk_dungeon_threat_name(theme, TRUE)
	generated_atoms += boss
	return boss

/datum/cyberpunk_dungeon_instance/proc/spawn_loot(turf/spawn_turf)
	var/list/loot = list(
		/obj/item/stack/ore/iron = 5,
		/obj/item/stack/ore/silver = 2,
		/obj/item/stack/ore/titanium = 2,
		/obj/item/stack/ore/gold = 1,
	)
	if(theme == "metro")
		loot = list(
			/obj/item/stack/sheet/iron = 4,
			/obj/item/stack/cable_coil = 3,
			/obj/item/stack/sheet/glass = 2,
			/obj/item/stack/ore/silver = 1,
		)
	else if(theme == "corporate")
		loot = list(
			/obj/item/stack/sheet/plasteel = 3,
			/obj/item/stack/sheet/glass = 2,
			/obj/item/stack/ore/gold = 2,
			/obj/item/stack/ore/titanium = 2,
		)
	else if(theme == "wasteland")
		loot = list(
			/obj/item/stack/ore/iron = 4,
			/obj/item/stack/sheet/iron = 3,
			/obj/item/stack/ore/titanium = 2,
			/obj/item/stack/ore/gold = 1,
		)
	var/loot_type = pick_weight(loot)
	var/obj/item/spawned_loot = new loot_type(spawn_turf)
	spawned_loot.name = "[theme] salvage"
	generated_atoms += spawned_loot
	return spawned_loot

/obj/structure/cyberpunk_dungeon_entrance
	name = "unstable underground entrance"
	desc = "A route into generated underground space."
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "hole"
	anchored = TRUE
	density = FALSE
	var/theme = "cave"
	var/difficulty = 1
	var/width_chunks = CYBERPUNK_DUNGEON_DEFAULT_WIDTH
	var/height_chunks = CYBERPUNK_DUNGEON_DEFAULT_HEIGHT
	var/datum/cyberpunk_dungeon_instance/instance
	var/closed = FALSE

/obj/structure/cyberpunk_dungeon_entrance/metro
	name = "abandoned metro entrance"
	desc = "A route into old tunnels below the city."
	theme = "metro"
	difficulty = 2

/obj/structure/cyberpunk_dungeon_entrance/corporate
	name = "sealed blacksite entrance"
	desc = "A corporate service route into a sealed underground installation."
	theme = "corporate"
	difficulty = 3

/obj/structure/cyberpunk_dungeon_entrance/wasteland
	name = "wasteland bunker entrance"
	desc = "A half-buried route into the badlands infrastructure under the city edge."
	theme = "wasteland"
	difficulty = 2

/obj/structure/cyberpunk_dungeon_entrance/Initialize(mapload)
	. = ..()
	desc = "[desc] Ghosts may track it as a city point of interest."
	SSpoints_of_interest?.make_point_of_interest(src)

/obj/structure/cyberpunk_dungeon_entrance/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!istype(user))
		return
	enter_dungeon(user)

/obj/structure/cyberpunk_dungeon_entrance/proc/enter_dungeon(mob/living/user)
	if(closed)
		return FALSE
	if(!instance || QDELETED(instance))
		instance = new /datum/cyberpunk_dungeon_instance(src, theme, difficulty, width_chunks, height_chunks)
	return instance.enter(user)

/obj/structure/cyberpunk_dungeon_entrance/Destroy(force)
	SSpoints_of_interest?.remove_point_of_interest(src)
	instance?.begin_collapse()
	instance = null
	return ..()

/obj/structure/closet/crate/cyberpunk_dungeon_reward
	name = "sealed salvage cache"
	desc = "The final cache of this underground route. Opening it completes the expedition."
	var/datum/weakref/instance_ref
	var/rewards_generated = FALSE

/obj/structure/closet/crate/cyberpunk_dungeon_reward/before_open(mob/living/user, force)
	if(!..())
		return FALSE
	var/datum/cyberpunk_dungeon_instance/instance = instance_ref?.resolve()
	if(!rewards_generated && instance)
		rewards_generated = TRUE
		for(var/index in 1 to (2 + instance.difficulty))
			var/obj/item/reward = instance.spawn_loot(get_turf(src))
			reward.forceMove(src)
	return TRUE

/obj/structure/closet/crate/cyberpunk_dungeon_reward/after_open(mob/living/user, force)
	. = ..()
	var/datum/cyberpunk_dungeon_instance/instance = instance_ref?.resolve()
	if(instance && !instance.completed)
		instance.completed = TRUE
		instance.begin_collapse("final cache opened")

/obj/structure/cyberpunk_dungeon_exit
	name = "unstable return route"
	desc = "A route back to the place where this underground instance was entered."
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "hole"
	anchored = TRUE
	density = FALSE
	var/datum/cyberpunk_dungeon_instance/instance

/obj/structure/cyberpunk_dungeon_exit/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!istype(user) || !instance)
		return
	instance.leave(user)

/obj/structure/cyberpunk_dungeon_exit/Destroy(force)
	instance = null
	return ..()

/obj/effect/landmark/cyberpunk_dungeon
	name = "cyberpunk dungeon marker"
	icon_state = "x2"
	var/instance_id

/obj/effect/landmark/cyberpunk_dungeon/start
	name = "cyberpunk dungeon start"
	icon_state = "x"

/obj/effect/landmark/cyberpunk_dungeon/exit
	name = "cyberpunk dungeon exit"
	icon_state = "portal_exit"

/obj/effect/landmark/cyberpunk_dungeon/enemy
	name = "cyberpunk dungeon enemy"
	icon_state = "xeno_spawn"

/obj/effect/landmark/cyberpunk_dungeon/loot
	name = "cyberpunk dungeon loot"
	icon_state = "generic_event"

/obj/effect/landmark/cyberpunk_dungeon/boss
	name = "cyberpunk dungeon boss"
	icon_state = "xeno_spawn"

#undef CYBERPUNK_DUNGEON_CHUNK_SIZE
#undef CYBERPUNK_DUNGEON_DEFAULT_WIDTH
#undef CYBERPUNK_DUNGEON_DEFAULT_HEIGHT
#undef CYBERPUNK_DUNGEON_EXIT_NORTH
#undef CYBERPUNK_DUNGEON_EXIT_EAST
#undef CYBERPUNK_DUNGEON_EXIT_SOUTH
#undef CYBERPUNK_DUNGEON_EXIT_WEST
#undef CYBERPUNK_DUNGEON_EXIT_ALL
