/obj/machinery/door
	/// Mapper flag: keep the mapped dir on roundstart instead of letting CP13 visual auto-orientation adjust it.
	var/prebuilt_direction = FALSE

/obj/machinery/door/airlock
	doorOpen = 'modular_bandastation/aesthetics/airlocks/sound/open.ogg'
	doorClose = 'modular_bandastation/aesthetics/airlocks/sound/close.ogg'
	boltUp = 'modular_bandastation/aesthetics/airlocks/sound/bolts_up.ogg'
	boltDown = 'modular_bandastation/aesthetics/airlocks/sound/bolts_down.ogg'
	var/has_open_lights = FALSE
	var/mapload_dir_follows_passage = FALSE

/obj/machinery/door/airlock/Initialize(mapload)
	if(mapload && !prebuilt_direction)
		normalize_mapload_dir()
	return ..()

/obj/machinery/door/airlock/proc/normalize_mapload_dir()
	var/north_south_passable = is_adjacent_turf_passable(NORTH) && is_adjacent_turf_passable(SOUTH)
	var/east_west_passable = is_adjacent_turf_passable(EAST) && is_adjacent_turf_passable(WEST)
	if(north_south_passable == east_west_passable)
		return
	if(mapload_dir_follows_passage)
		setDir(north_south_passable ? SOUTH : EAST)
	else
		setDir(north_south_passable ? EAST : SOUTH)

/obj/machinery/door/airlock/proc/is_adjacent_turf_passable(direction)
	var/turf/adjacent_turf = get_step(src, direction)
	return adjacent_turf && !adjacent_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = src, ignore_atoms = list(src))

/obj/machinery/door/airlock/external
	mapload_dir_follows_passage = TRUE

/obj/machinery/door/airlock/shuttle
	mapload_dir_follows_passage = TRUE

/obj/machinery/door/airlock/update_overlays()
	. = ..()
	if(!has_open_lights || !feedback || !hasPower())
		return
	var/light_state
	switch(airlock_state)
		if(AIRLOCK_CLOSED)
			if(!locked && !emergency && !has_active_reta_access())
				light_state = "poweron"
		if(AIRLOCK_OPEN)
			if(locked)
				light_state = "bolts_open"
			else if(emergency)
				light_state = "emergency_open"
			else if(has_active_reta_access())
				light_state = "reta_open"
			else
				light_state = "poweron_open"
	if(!light_state)
		return
	. += get_airlock_overlay("lights_[light_state]", overlays_file, src, em_block = FALSE)

/obj/machinery/door/airlock/highsecurity
	has_open_lights = FALSE
