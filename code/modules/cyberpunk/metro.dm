GLOBAL_LIST_EMPTY(cyberpunk_metro_stops)
GLOBAL_LIST_EMPTY(cyberpunk_metro_interiors)
GLOBAL_LIST_EMPTY(cyberpunk_metro_trains)
GLOBAL_LIST_EMPTY(cyberpunk_metro_doors)

SUBSYSTEM_DEF(cyberpunk_metro)
	name = "Cyberpunk Metro"
	wait = 5 SECONDS
	priority = FIRE_PRIORITY_DEFAULT

/datum/controller/subsystem/cyberpunk_metro/fire(resumed)
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
		var/inserted = FALSE
		for(var/index in 1 to length(stops))
			var/obj/effect/landmark/cyberpunk_metro_stop/other = stops[index]
			if(stop.route_order < other.route_order)
				stops.Insert(index, stop)
				inserted = TRUE
				break
		if(!inserted)
			stops += stop
	return stops

/proc/cyberpunk_metro_interior_landmark(route_id)
	var/list/interiors = list()
	for(var/obj/effect/landmark/cyberpunk_metro_interior/interior as anything in GLOB.cyberpunk_metro_interiors)
		if(QDELETED(interior) || interior.route_id != route_id)
			continue
		interiors += interior
	if(!length(interiors))
		return null
	return pick(interiors)

/proc/cyberpunk_metro_train_for_route(route_id)
	for(var/obj/structure/cyberpunk_metro_train/train as anything in GLOB.cyberpunk_metro_trains)
		if(!QDELETED(train) && train.route_id == route_id && train.is_controller)
			return train
	return null

/obj/effect/landmark/cyberpunk_metro_stop
	name = "CP13 metro stop"
	icon_state = "x"
	/// Stops with the same route id are connected into one cyclic route.
	var/route_id = "main"
	/// Lower values are visited earlier.
	var/route_order = 1
	/// Stable mapper-facing id.
	var/stop_id = "stop"
	/// Where passengers appear relative to the stop landmark.
	var/exit_x_offset = 0
	var/exit_y_offset = -1

/obj/effect/landmark/cyberpunk_metro_stop/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_stops += src

/obj/effect/landmark/cyberpunk_metro_stop/Destroy(force)
	GLOB.cyberpunk_metro_stops -= src
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

/obj/effect/landmark/cyberpunk_metro_interior
	name = "CP13 metro interior spawn"
	icon_state = "x2"
	/// Route whose passengers enter here.
	var/route_id = "main"

/obj/effect/landmark/cyberpunk_metro_interior/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_interiors += src

/obj/effect/landmark/cyberpunk_metro_interior/Destroy(force)
	GLOB.cyberpunk_metro_interiors -= src
	return ..()

/obj/structure/cyberpunk_metro_train
	name = "metro train"
	desc = "A city metro train. Drag yourself onto it or click it while it is stopped to board."
	icon = 'icons/obj/machines/beacon.dmi'
	icon_state = "beacon"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Route id matching /obj/effect/landmark/cyberpunk_metro_stop and interior landmarks.
	var/route_id = "main"
	var/state = "docked"
	var/dwell_time = 20 SECONDS
	var/travel_time = 30 SECONDS
	var/next_departure_at = 0
	var/arrival_at = 0
	var/obj/effect/landmark/cyberpunk_metro_stop/current_stop
	var/obj/effect/landmark/cyberpunk_metro_stop/target_stop
	/// Only one segment per route should control movement.
	var/is_controller = TRUE
	/// Visual placement relative to the current stop. Cars use this when the controller arrives.
	var/segment_x_offset = 0
	var/segment_y_offset = 0

/obj/structure/cyberpunk_metro_train/Initialize(mapload)
	. = ..()
	GLOB.cyberpunk_metro_trains += src

/obj/structure/cyberpunk_metro_train/Destroy(force)
	GLOB.cyberpunk_metro_trains -= src
	current_stop = null
	target_stop = null
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
		close_interior_doors()
		state = "moving"
		arrival_at = world.time + travel_time
		sync_consist_state()
		visible_message(span_notice("[capitalize(src.name)] leaves [current_stop.stop_id]."))
		return
	if(state == "moving" && world.time >= arrival_at)
		arrive_at(target_stop)

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

/obj/structure/cyberpunk_metro_train/proc/arrive_at(obj/effect/landmark/cyberpunk_metro_stop/stop)
	if(!stop || QDELETED(stop))
		return
	var/turf/origin = get_turf(stop)
	if(!origin)
		return
	current_stop = stop
	target_stop = null
	state = "docked"
	next_departure_at = world.time + dwell_time
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(segment) || segment.route_id != route_id)
			continue
		segment.current_stop = stop
		segment.target_stop = null
		segment.state = state
		segment.next_departure_at = next_departure_at
		var/turf/segment_turf = locate(origin.x + segment.segment_x_offset, origin.y + segment.segment_y_offset, origin.z)
		segment.forceMove(segment_turf || origin)
	visible_message(span_notice("[capitalize(src.name)] arrives at [stop.stop_id]."))
	open_interior_doors()

/obj/structure/cyberpunk_metro_train/proc/sync_consist_state()
	for(var/obj/structure/cyberpunk_metro_train/segment as anything in GLOB.cyberpunk_metro_trains)
		if(QDELETED(segment) || segment.route_id != route_id)
			continue
		segment.current_stop = current_stop
		segment.target_stop = target_stop
		segment.state = state
		segment.next_departure_at = next_departure_at
		segment.arrival_at = arrival_at

/obj/structure/cyberpunk_metro_train/proc/board_passenger(mob/living/passenger, atom/boarding_source)
	if(!is_controller)
		var/obj/structure/cyberpunk_metro_train/controller = cyberpunk_metro_train_for_route(route_id)
		return controller?.board_passenger(passenger, boarding_source || src)
	if(state != "docked" || !current_stop)
		passenger.balloon_alert(passenger, "train moving")
		return FALSE
	var/atom/source = boarding_source || src
	if(get_dist(passenger, source) > 1)
		return FALSE
	var/obj/effect/landmark/cyberpunk_metro_interior/interior = cyberpunk_metro_interior_landmark(route_id)
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
		var/obj/structure/cyberpunk_metro_train/controller = cyberpunk_metro_train_for_route(route_id)
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
		if(door.route_id == route_id)
			door.set_open(TRUE)

/obj/structure/cyberpunk_metro_train/proc/close_interior_doors()
	for(var/obj/structure/cyberpunk_metro_door/door as anything in GLOB.cyberpunk_metro_doors)
		if(door.route_id == route_id)
			door.set_open(FALSE)

/obj/structure/cyberpunk_metro_train/locomotive
	name = "metro locomotive"
	is_controller = TRUE

/obj/structure/cyberpunk_metro_train/car
	name = "metro car"
	is_controller = FALSE
	segment_x_offset = 1

/obj/structure/cyberpunk_metro_train/car/second
	name = "metro second car"
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
	var/obj/structure/cyberpunk_metro_train/train = cyberpunk_metro_train_for_route(route_id)
	if(!train)
		user.balloon_alert(user, "no train")
		return
	train.exit_passenger(user)

/obj/structure/cyberpunk_metro_door/proc/set_open(new_open)
	opened = new_open
	density = !opened
	icon_state = opened ? "open" : "closed"
