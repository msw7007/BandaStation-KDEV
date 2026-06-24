GLOBAL_LIST_EMPTY(cyberpunk_metro_stops)
GLOBAL_LIST_EMPTY(cyberpunk_metro_route_points)
GLOBAL_LIST_EMPTY(cyberpunk_metro_route_path_cache)
GLOBAL_LIST_EMPTY(cyberpunk_metro_interiors)
GLOBAL_LIST_EMPTY(cyberpunk_metro_trains)
GLOBAL_LIST_EMPTY(cyberpunk_metro_doors)

#define CYBERPUNK_METRO_TRAIN_TEMPLATE "_maps/templates/cyberpunk_metro_train_32x5.dmm"
#define CYBERPUNK_METRO_EXTERIOR_CARS 3
#define CYBERPUNK_METRO_MOVE_STEP_DELAY (0.2 SECONDS)

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
		var/list/segment = cyberpunk_metro_path_between(start_point, end_point)
		if(!length(segment))
			stack_trace("Cyberpunk metro route '[route_id]' has no connected metro-area path between [start_point] and [end_point].")
			if(route_path[length(route_path)] != end_point)
				route_path += end_point
			continue
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

/proc/cyberpunk_metro_path_between(atom/start_point, atom/end_point)
	var/turf/start_turf = get_turf(start_point)
	var/turf/end_turf = get_turf(end_point)
	if(!start_turf || !end_turf || start_turf.z != end_turf.z)
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
			if(!cyberpunk_metro_can_route_through(next_turf, start_turf, end_turf))
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

/proc/cyberpunk_metro_can_route_through(turf/check_turf, turf/start_turf, turf/end_turf)
	if(!check_turf)
		return FALSE
	if(check_turf == start_turf || check_turf == end_turf)
		return TRUE
	if(!isopenturf(check_turf))
		return FALSE
	return istype(get_area(check_turf), /area/cyberpunk/city/metro)

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
		new_route_path = cyberpunk_metro_route_stops(route_id)
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
	if(!origin)
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
	rebuild_travel_history(origin, movement_dir)
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

/obj/structure/cyberpunk_metro_train/proc/rebuild_travel_history(turf/origin, head_dir)
	travel_history = list()
	if(!origin)
		return
	var/turf/history_turf = origin
	var/tail_dir = head_dir ? REVERSE_DIR(head_dir) : SOUTH
	for(var/index in 2 to CYBERPUNK_METRO_EXTERIOR_CARS)
		var/turf/next_history_turf = get_step(history_turf || origin, tail_dir)
		history_turf = next_history_turf || origin
		travel_history += history_turf

/obj/structure/cyberpunk_metro_train/proc/process_train_movement()
	if(!target_stop || QDELETED(target_stop))
		return
	if(world.time < next_move_at)
		return
	if(!length(route_path) || !target_route_index)
		if(!prepare_route_to(target_stop, cyberpunk_metro_route_path(route_id)))
			arrive_at(target_stop)
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
		if(target_point == target_stop)
			arrive_at(target_stop)
		else
			advance_route_point()
		return
	var/turf/next_turf = get_step(current_turf, step_dir)
	if(!next_turf)
		arrive_at(target_stop)
		return
	movement_dir = step_dir
	move_consist_to(next_turf, step_dir)
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
	if(!origin)
		return
	var/turf/old_origin = get_turf(src)
	if(old_origin)
		travel_history.Insert(1, old_origin)
		if(length(travel_history) > CYBERPUNK_METRO_EXTERIOR_CARS + 2)
			travel_history.Cut(CYBERPUNK_METRO_EXTERIOR_CARS + 3)
	var/list/segments_to_move = list()
	var/list/segment_dirs = list()
	var/list/segments = cyberpunk_metro_train_segments(route_id, train_id)
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in segments)
		var/turf/segment_turf = origin
		if(segment.segment_order > 1)
			var/history_index = segment.segment_order - 1
			if(length(travel_history) >= history_index)
				segment_turf = travel_history[history_index]
			else
				segment_turf = get_turf(segment)
		if(!segment_turf)
			continue
		var/turf/current_segment_turf = get_turf(segment)
		var/segment_dir = get_cardinal_step_dir(current_segment_turf, segment_turf) || step_dir
		segments_to_move[segment] = segment_turf
		segment_dirs[segment] = segment_dir
		segment.clear_metro_path(segment_turf, segment_dir)
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in segments_to_move)
		var/turf/segment_turf = segments_to_move[segment]
		var/segment_dir = segment_dirs[segment]
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
		if(QDELING(victim_structure) || istype(victim_structure, /obj/structure/cyberpunk_metro_train))
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

#undef CYBERPUNK_METRO_TRAIN_TEMPLATE
#undef CYBERPUNK_METRO_EXTERIOR_CARS
#undef CYBERPUNK_METRO_MOVE_STEP_DELAY
