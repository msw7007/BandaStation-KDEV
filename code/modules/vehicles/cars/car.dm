/obj/vehicle/sealed/car
	layer = ABOVE_MOB_LAYER
	move_resist = MOVE_FORCE_VERY_STRONG

	///Bitflags for special behavior such as kidnapping
	var/car_traits = NONE
	///Sound file(s) to play when we drive around
	var/engine_sound = 'sound/vehicles/carrev.ogg'
	///Set this to the length of the engine sound.
	var/engine_sound_length = 2 SECONDS
	///Time it takes to break out of the car.
	var/escape_time = 6 SECONDS
	/// How long it takes to move, cars don't use the riding component similar to mechs so we handle it ourselves
	var/vehicle_move_delay = 1
	/// What sound to play if someone was forced in.
	var/forced_enter_sound
	/// How long it takes to rev (vrrm vrrm!)
	COOLDOWN_DECLARE(enginesound_cooldown)

/obj/vehicle/sealed/car/generate_actions()
	. = ..()
	if(!isnull(key_type))
		initialize_controller_action_type(/datum/action/vehicle/sealed/remove_key, VEHICLE_CONTROL_DRIVE)
	if(car_traits & CAN_KIDNAP)
		initialize_controller_action_type(/datum/action/vehicle/sealed/dump_kidnapped_mobs, VEHICLE_CONTROL_DRIVE)

/obj/vehicle/sealed/car/mouse_drop_receive(atom/dropping, mob/M, params)
	if(HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && !is_driver(M))
		return
	if((car_traits & CAN_KIDNAP) && isliving(dropping) && M != dropping)
		var/mob/living/kidnapped = dropping
		kidnapped.visible_message(span_warning("[M] starts forcing [kidnapped] into [src]!"))
		mob_try_forced_enter(M, kidnapped)
	return ..()

/obj/vehicle/sealed/car/mob_try_exit(mob/future_pedestrian, mob/user, silent = FALSE)
	if(future_pedestrian != user || !(LAZYACCESS(occupants, future_pedestrian) & VEHICLE_CONTROL_KIDNAPPED))
		mob_exit(future_pedestrian, silent)
		return TRUE
	if (escape_time > 0)
		to_chat(user, span_notice("You push against the back of \the [src]'s trunk to try and get out."))
		if(!do_after(user, escape_time, target = src))
			return FALSE
	to_chat(user,span_danger("[user] gets out of [src]."))
	mob_exit(future_pedestrian, silent)
	return TRUE

/obj/vehicle/sealed/car/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!(car_traits & CAN_KIDNAP))
		return
	to_chat(user, span_notice("You start opening [src]'s trunk."))
	if(!do_after(user, 30))
		return
	if(return_amount_of_controllers_with_flag(VEHICLE_CONTROL_KIDNAPPED))
		to_chat(user, span_notice("The people stuck in [src]'s trunk all come tumbling out."))
		dump_specific_mobs(VEHICLE_CONTROL_KIDNAPPED)
		return
	to_chat(user, span_notice("It seems [src]'s trunk was empty."))

///attempts to force a mob into the car
/obj/vehicle/sealed/car/proc/mob_try_forced_enter(mob/forcer, mob/kidnapped, silent = FALSE)
	if(occupant_amount() >= max_occupants)
		return FALSE
	var/atom/old_loc = loc
	var/enter_delay = get_enter_delay(kidnapped)
	if(enter_delay == 0 || do_after(forcer, enter_delay, kidnapped, extra_checks=CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/car, is_car_stationary), old_loc)))
		mob_forced_enter(kidnapped, silent)
		return TRUE
	return FALSE

///Callback proc to check for
/obj/vehicle/sealed/car/proc/is_car_stationary(atom/old_loc)
	return (old_loc == loc)

///Proc called when someone is forcefully stuffedd into a car
/obj/vehicle/sealed/car/proc/mob_forced_enter(mob/kidnapped, silent = FALSE)
	if(!silent)
		kidnapped.visible_message(span_warning("[kidnapped] is forced into \the [src]!"))
		if(forced_enter_sound)
			playsound(src, forced_enter_sound, 70, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	kidnapped.forceMove(src)
	add_occupant(kidnapped, VEHICLE_CONTROL_KIDNAPPED, TRUE)

/obj/vehicle/sealed/car/after_add_occupant(mob/M)
	. = ..()
	if(cy_pixel_physics)
		cy_sync_occupant_camera(M)

/obj/vehicle/sealed/car/after_remove_occupant(mob/M)
	if(cy_pixel_physics)
		cy_reset_occupant_camera(M)
	. = ..()

/obj/vehicle/sealed/car/atom_destruction(damage_flag)
	explosion(src, heavy_impact_range = 1, light_impact_range = 2, flash_range = 3, adminlog = FALSE)
	log_message("[src] exploded due to destruction", LOG_ATTACK)
	return ..()

/obj/vehicle/sealed/car/relaymove(mob/living/user, direction)
	if(is_driver(user) && canmove && (!key_type || istype(inserted_key, key_type)))
		vehicle_move(direction)
	return TRUE

/obj/vehicle/sealed/car/vehicle_move(direction)
	if(cy_pixel_physics)
		return cy_receive_drive_input(direction)

	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, modified_move_delay(vehicle_move_delay * get_cy_driver_skill_multiplier())) // BANDASTATION EDIT - Vehicle speed

	if(COOLDOWN_FINISHED(src, enginesound_cooldown))
		COOLDOWN_START(src, enginesound_cooldown, engine_sound_length)
		playsound(get_turf(src), engine_sound, 100, TRUE)

	if(trailer)
		var/dir_to_move = get_dir(trailer.loc, loc)
		var/did_move = try_step_multiz(direction)
		if(did_move)
			step(trailer, dir_to_move)
			award_cy_driver_experience()
		return did_move
	after_move(direction)
	var/main_did_move = try_step_multiz(direction)
	if(main_did_move)
		award_cy_driver_experience()
	return main_did_move

// -----------------------------------------------------------------------------
// Cyberpunk vehicle core: modular parts + lightweight pixel physics.
// This intentionally lives on the existing car type so old sealed cars keep their
// behavior unless cy_pixel_physics is enabled.
// -----------------------------------------------------------------------------

/obj/vehicle/sealed/car
	/// Enables sub-tile movement, acceleration, braking, steering and drift.
	var/cy_pixel_physics = FALSE
	/// internal/external/platform. External/platform are data flags here; movement is still object-based.
	var/cy_vehicle_body_type = CY_VEHICLE_BODY_INTERNAL
	/// civilian/modified/combat.
	var/cy_vehicle_class = CY_VEHICLE_CLASS_CIVILIAN
	/// Set when a civilian vehicle receives non-civilian/armored/combat modifications.
	var/cy_illegal_modification = FALSE
	/// Civilian electric vehicles can self-charge until modification blocks it.
	var/cy_can_autocharge = TRUE

	/// Installed drive parts. Must be 2-6 for normal ground vehicles.
	var/list/cy_drive_parts
	var/obj/item/cy_vehicle_part/suspension/cy_suspension
	var/obj/item/cy_vehicle_part/hull/cy_hull
	var/obj/item/cy_vehicle_part/engine/cy_engine
	/// Structures/machines attached to a platform vehicle. They are payloads, not moving turfs.
	var/list/cy_installed_payloads

	/// Default parts installed on Initialize(). Subtypes override these.
	var/list/cy_default_drive_part_types
	var/cy_default_suspension_type
	var/cy_default_hull_type
	var/cy_default_engine_type

	/// Continuous world-pixel position. This is the real movement state. loc is only a technical registration turf.
	var/cy_world_px = 0
	var/cy_world_py = 0
	/// Velocity in pixels per second.
	var/cy_velocity_x = 0
	var/cy_velocity_y = 0
	/// Body heading in degrees. Kept for examine/debug only. Movement uses vectors directly.
	var/cy_heading = 90
	/// Desired vector from WASD. Instant player intent.
	var/cy_desired_x = 0
	var/cy_desired_y = 0
	/// Acceleration/thrust vector. It follows desired with engine/control response.
	var/cy_accel_x = 0
	var/cy_accel_y = 1
	/// Grip vector. It is the direction where the drive parts currently have stable traction.
	var/cy_grip_x = 0
	var/cy_grip_y = 1
	/// Facing vector used for dir/examine. For BYOND visuals, NORTH is positive Y/pixel_y.
	var/cy_forward_x = 0
	var/cy_forward_y = 1
	var/cy_last_input_time = 0

	/// Render smoothing state. Actual movement is world-pixel based; no tile glide is used.
	var/cy_smooth_pixel_motion = TRUE
	/// Smooths the camera of contained occupants by mirroring vehicle pixel offsets on their clients.
	var/cy_smooth_camera_follow = TRUE

	/// Effective physics values rebuilt from installed parts.
	var/cy_mass = 1000
	var/cy_max_speed = 5
	var/cy_acceleration = 0.35
	var/cy_brake_force = 0.6
	var/cy_turn_rate = 8
	var/cy_drag = 0.03
	var/cy_lateral_grip = 0.24
	/// How quickly acceleration vector follows desired vector. Mostly engine/control response.
	var/cy_engine_response = 1.1
	/// How quickly velocity direction is pulled toward acceleration while stable.
	var/cy_maneuverability = 0.85
	/// How quickly grip vector follows acceleration. Mostly tires/tracks/gravity drives.
	var/cy_grip_follow_speed = 0.75
	/// Allowed 1-dot(normalized velocity, grip) before drift starts. Higher means more stable.
	var/cy_stable_slip_limit = 0.28
	/// How much steering authority remains while drifting.
	var/cy_drift_control_mult = 0.35
	/// How much speed is kept when drifting through a turn. Higher = longer, faster drift.
	var/cy_drift_retention = 0.82
	var/cy_turn_loss_mult = 0.45
	var/cy_min_drift_speed = 18
	var/cy_is_drifting = FALSE
	var/cy_drift_amount = 0
	var/cy_road_grip = 1
	var/cy_offroad_grip = 0.7
	var/cy_collision_damage_mult = 4
	var/cy_engine_explosion_chance = 0
	/// Collision box half-size, in pixels from vehicle center.
	var/cy_collision_half_width = 12
	var/cy_collision_half_height = 12

/obj/vehicle/sealed/car/Initialize(mapload)
	. = ..()
	cy_drive_parts = list()
	cy_installed_payloads = list()
	cy_heading = cy_dir_to_angle(dir || NORTH)
	cy_set_forward_from_dir(dir || NORTH)
	cy_accel_x = cy_forward_x
	cy_accel_y = cy_forward_y
	cy_grip_x = cy_forward_x
	cy_grip_y = cy_forward_y
	if(cy_pixel_physics)
		glide_size = 0
		animate_movement = NO_STEPS
		cy_world_px = (x - 1) * CY_VEHICLE_TILE_PIXELS + pixel_x
		cy_world_py = (y - 1) * CY_VEHICLE_TILE_PIXELS + pixel_y
	cy_install_default_parts()
	cy_rebuild_vehicle_stats()
	if(cy_pixel_physics)
		START_PROCESSING(SSfastprocess, src)

/obj/vehicle/sealed/car/Destroy(force)
	if(cy_pixel_physics)
		STOP_PROCESSING(SSfastprocess, src)
	cy_drive_parts = null
	cy_suspension = null
	cy_hull = null
	cy_engine = null
	cy_installed_payloads = null
	return ..()

/obj/vehicle/sealed/car/process(seconds_per_tick)
	if(!cy_pixel_physics)
		return PROCESS_KILL

	cy_process_pixel_physics(seconds_per_tick)
	return

/obj/vehicle/sealed/car/examine(mob/user)
	. = ..()
	if(!cy_pixel_physics)
		return
	. += span_notice("It uses pixel vehicle physics. Speed: [round(cy_get_speed(), 0.1)] px/s, cap: [round(cy_get_effective_max_speed(), 0.1)] px/s, drift: [round(cy_get_drift_amount(), 0.1)] ([cy_is_drifting ? "sliding" : "stable"]).")
	. += span_notice("Chassis: [cy_vehicle_class], body: [cy_vehicle_body_type].")
	if(cy_illegal_modification)
		. += span_warning("It has illegal civilian modifications.")
	if(cy_suspension)
		. += "Suspension: [cy_suspension.name] ([cy_suspension.cy_part_integrity]/[cy_suspension.cy_part_max_integrity])."
	if(cy_hull)
		. += "Hull: [cy_hull.name] ([cy_hull.cy_part_integrity]/[cy_hull.cy_part_max_integrity])."
	if(cy_engine)
		. += "Engine: [cy_engine.name] ([cy_engine.cy_part_integrity]/[cy_engine.cy_part_max_integrity])."
	if(length(cy_drive_parts))
		. += "Drive parts: [length(cy_drive_parts)] installed."

/obj/vehicle/sealed/car/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/cy_vehicle_part))
		var/obj/item/cy_vehicle_part/part = tool
		if(!cy_can_install_part(part, user))
			return ITEM_INTERACT_BLOCKING
		if(!user.transferItemToLoc(part, src))
			to_chat(user, span_warning("[part] seems to be stuck to your hand!"))
			return ITEM_INTERACT_BLOCKING
		cy_install_part(part, user)
		to_chat(user, span_notice("You install [part] into [src]."))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/vehicle/sealed/car/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(cy_pixel_physics && damage_amount > 0)
		cy_apply_part_damage(damage_amount * 0.5, CY_VEHICLE_PART_HULL)

/obj/vehicle/sealed/car/proc/cy_install_default_parts()
	if(length(cy_default_drive_part_types))
		for(var/part_type in cy_default_drive_part_types)
			var/obj/item/cy_vehicle_part/part = new part_type(src)
			cy_install_part(part)
	if(cy_default_suspension_type)
		cy_install_part(new cy_default_suspension_type(src))
	if(cy_default_hull_type)
		cy_install_part(new cy_default_hull_type(src))
	if(cy_default_engine_type)
		cy_install_part(new cy_default_engine_type(src))

/obj/vehicle/sealed/car/proc/cy_can_install_part(obj/item/cy_vehicle_part/part, mob/user)
	if(!istype(part))
		return FALSE
	switch(part.cy_part_slot)
		if(CY_VEHICLE_PART_DRIVE)
			if(length(cy_drive_parts) >= CY_VEHICLE_MAX_DRIVE_PARTS)
				if(user)
					to_chat(user, span_warning("[src] cannot accept more than [CY_VEHICLE_MAX_DRIVE_PARTS] drive parts."))
				return FALSE
		if(CY_VEHICLE_PART_SUSPENSION)
			if(cy_suspension)
				if(user)
					to_chat(user, span_warning("[src] already has suspension installed."))
				return FALSE
		if(CY_VEHICLE_PART_HULL)
			if(cy_hull)
				if(user)
					to_chat(user, span_warning("[src] already has a hull installed."))
				return FALSE
		if(CY_VEHICLE_PART_ENGINE)
			if(cy_engine)
				if(user)
					to_chat(user, span_warning("[src] already has an engine installed."))
				return FALSE
		else
			return FALSE
	return TRUE

/obj/vehicle/sealed/car/proc/cy_install_part(obj/item/cy_vehicle_part/part, mob/user)
	if(!istype(part))
		return FALSE
	part.forceMove(src)
	part.cy_installed_vehicle = src
	switch(part.cy_part_slot)
		if(CY_VEHICLE_PART_DRIVE)
			cy_drive_parts += part
		if(CY_VEHICLE_PART_SUSPENSION)
			cy_suspension = part
		if(CY_VEHICLE_PART_HULL)
			cy_hull = part
		if(CY_VEHICLE_PART_ENGINE)
			cy_engine = part
	if(part.cy_marks_civilian_modified && cy_vehicle_class == CY_VEHICLE_CLASS_CIVILIAN)
		cy_vehicle_class = CY_VEHICLE_CLASS_MODIFIED
		cy_illegal_modification = TRUE
	if(part.cy_blocks_autocharge)
		cy_can_autocharge = FALSE
	cy_rebuild_vehicle_stats()
	update_appearance(UPDATE_OVERLAYS)
	return TRUE

/obj/vehicle/sealed/car/update_overlays()
	. = ..()
	if(length(cy_drive_parts))
		for(var/obj/item/cy_vehicle_part/part as anything in cy_drive_parts)
			var/mutable_appearance/part_overlay = part.cy_get_overlay_appearance(layer)
			if(part_overlay)
				. += part_overlay
	if(cy_suspension)
		var/mutable_appearance/suspension_overlay = cy_suspension.cy_get_overlay_appearance(layer)
		if(suspension_overlay)
			. += suspension_overlay
	if(cy_hull)
		var/mutable_appearance/hull_overlay = cy_hull.cy_get_overlay_appearance(layer)
		if(hull_overlay)
			. += hull_overlay
	if(cy_engine)
		var/mutable_appearance/engine_overlay = cy_engine.cy_get_overlay_appearance(layer)
		if(engine_overlay)
			. += engine_overlay

/obj/vehicle/sealed/car/proc/cy_rebuild_vehicle_stats()
	var/total_mass = 0
	var/drive_count = max(length(cy_drive_parts), 1)
	var/drive_max_speed = 0
	var/drive_acceleration = 0
	var/drive_turn = 0
	var/drive_road_grip = 0
	var/drive_offroad_grip = 0
	var/drive_lateral_grip = 0
	var/drive_efficiency = 0

	for(var/obj/item/cy_vehicle_part/drive/drive_part as anything in cy_drive_parts)
		var/efficiency = drive_part.cy_get_efficiency()
		drive_efficiency += efficiency
		drive_max_speed += drive_part.cy_max_speed * efficiency
		drive_acceleration += drive_part.cy_acceleration * efficiency
		drive_turn += drive_part.cy_turn_rate * efficiency
		drive_road_grip += drive_part.cy_road_grip * efficiency
		drive_offroad_grip += drive_part.cy_offroad_grip * efficiency
		drive_lateral_grip += drive_part.cy_lateral_grip * efficiency
		total_mass += drive_part.cy_mass

	var/suspension_efficiency = cy_suspension ? cy_suspension.cy_get_efficiency() : 0.6
	var/hull_efficiency = cy_hull ? cy_hull.cy_get_efficiency() : 0.5
	var/engine_efficiency = cy_engine ? cy_engine.cy_get_efficiency() : 0
	if(cy_suspension)
		total_mass += cy_suspension.cy_mass
	if(cy_hull)
		total_mass += cy_hull.cy_mass
	if(cy_engine)
		total_mass += cy_engine.cy_mass

	cy_mass = max(total_mass, 100)
	cy_max_speed = ((drive_max_speed / drive_count) + (cy_engine ? cy_engine.cy_max_speed : 0)) * suspension_efficiency * hull_efficiency * max(engine_efficiency, 0.1)
	cy_acceleration = ((drive_acceleration / drive_count) + (cy_engine ? cy_engine.cy_acceleration : 0)) * suspension_efficiency * max(engine_efficiency, 0.1)
	cy_turn_rate = (drive_turn / drive_count) * suspension_efficiency
	cy_road_grip = max(drive_road_grip / drive_count, 0.05) * suspension_efficiency
	cy_offroad_grip = max(drive_offroad_grip / drive_count, 0.05) * suspension_efficiency
	cy_lateral_grip = max(drive_lateral_grip / drive_count, 0.02) * suspension_efficiency
	// These are response rates per second, not direct multipliers. Keep them low enough that
	// a vehicle visibly transitions NORTH -> EAST instead of snapping into the new vector.
	cy_engine_response = clamp(((cy_engine ? cy_engine.cy_engine_response : 3) + (cy_suspension ? cy_suspension.cy_engine_response : 0)) * max(engine_efficiency, 0.1) * 0.22, 0.25, 1.6)
	cy_maneuverability = clamp(((drive_turn / drive_count) * 0.09 + (cy_suspension ? cy_suspension.cy_maneuverability : 2) * 0.12) * suspension_efficiency / max(cy_mass / 900, 0.75), 0.18, 1.35)
	cy_grip_follow_speed = clamp((drive_lateral_grip / drive_count) * 2.5 * suspension_efficiency, 0.18, 1.05)
	cy_stable_slip_limit = clamp((cy_suspension ? cy_suspension.cy_stable_slip_limit : 0.25) + (drive_lateral_grip / drive_count) * 0.08, 0.08, 0.42)
	cy_drift_retention = clamp((cy_suspension ? cy_suspension.cy_drift_retention : 0.78) + (drive_lateral_grip / drive_count) * 0.08, 0.25, 0.94)
	cy_drift_control_mult = clamp(cy_lateral_grip * 0.8, 0.08, 0.38)
	cy_turn_loss_mult = max((cy_hull ? cy_hull.cy_turn_loss_mult : 0.45) / max(suspension_efficiency, 0.1), 0.05)
	cy_brake_force = (cy_suspension ? cy_suspension.cy_brake_force : 0.5) * suspension_efficiency
	cy_drag = cy_hull ? cy_hull.cy_drag : 0.04
	cy_engine_explosion_chance = cy_engine ? cy_engine.cy_explosion_chance : 0

/obj/vehicle/sealed/car/proc/cy_receive_drive_input(direction)
	if(!cy_pixel_physics)
		return FALSE
	if(!canmove || !cy_engine || cy_engine.cy_broken)
		return FALSE
	if(length(cy_drive_parts) < CY_VEHICLE_MIN_DRIVE_PARTS)
		return FALSE

	if(COOLDOWN_FINISHED(src, enginesound_cooldown))
		COOLDOWN_START(src, enginesound_cooldown, engine_sound_length)
		playsound(get_turf(src), engine_sound, 100, TRUE)

	var/new_x = 0
	var/new_y = 0

	if(direction & NORTH)
		new_y += 1
	if(direction & SOUTH)
		new_y -= 1
	if(direction & EAST)
		new_x += 1
	if(direction & WEST)
		new_x -= 1

	if(new_x || new_y)
		var/magnitude = sqrt(new_x * new_x + new_y * new_y)
		cy_desired_x = new_x / magnitude
		cy_desired_y = new_y / magnitude
	else
		cy_desired_x = 0
		cy_desired_y = 0

	cy_last_input_time = world.time
	award_cy_driver_experience()
	return TRUE

/obj/vehicle/sealed/car/proc/cy_process_pixel_physics(seconds_per_tick)
	cy_process_pixel_movement(seconds_per_tick)

/obj/vehicle/sealed/car/proc/cy_process_pixel_movement(seconds_per_tick)
	if(isnull(seconds_per_tick) || seconds_per_tick <= 0)
		seconds_per_tick = SSfastprocess.wait * 0.1

	if(!cy_engine || cy_engine.cy_broken || world.time - cy_last_input_time > CY_VEHICLE_INPUT_LINGER)
		cy_desired_x = 0
		cy_desired_y = 0

	var/terrain_grip = cy_get_terrain_grip()
	var/effective_max_speed = cy_get_effective_max_speed() / get_cy_driver_skill_multiplier()
	var/driver_transport_stat_multiplier = get_cy_driver_transport_stat_multiplier()
	var/has_desired = !!(cy_desired_x || cy_desired_y)
	var/has_accel = !!(cy_accel_x || cy_accel_y)

	// 1. Desired vector is raw WASD. Acceleration vector is where the vehicle has managed
	// to point its power. It follows desired with engine/control response, not instantly.
	if(has_desired)
		cy_approach_accel_vector(cy_desired_x, cy_desired_y, cy_engine_response * seconds_per_tick)
	else
		var/accel_decay = clamp(cy_engine_response * seconds_per_tick, 0, 1)
		cy_accel_x *= (1 - accel_decay)
		cy_accel_y *= (1 - accel_decay)
		if(abs(cy_accel_x) < 0.01)
			cy_accel_x = 0
		if(abs(cy_accel_y) < 0.01)
			cy_accel_y = 0

	has_accel = !!(cy_accel_x || cy_accel_y)
	if(has_accel)
		cy_forward_x = cy_accel_x
		cy_forward_y = cy_accel_y
		cy_normalize_forward_vector()
		cy_heading = cy_vector_to_debug_angle()
		setDir(cy_forward_to_dir())

	// 2. Engine pushes along the acceleration vector. Velocity is where the car is actually moving.
	if(has_accel)
		var/effective_acceleration = cy_acceleration * CY_VEHICLE_ACCEL_SCALE * terrain_grip
		cy_velocity_x += cy_accel_x * effective_acceleration * seconds_per_tick
		cy_velocity_y += cy_accel_y * effective_acceleration * seconds_per_tick

	var/current_speed = cy_get_speed()
	if(current_speed > effective_max_speed)
		var/speed_scale = effective_max_speed / current_speed
		cy_velocity_x *= speed_scale
		cy_velocity_y *= speed_scale
		current_speed = effective_max_speed

	// 3. Grip is a separate vector. It lags behind the acceleration vector according to drive parts.
	// Drift starts when real velocity pulls away from the grip direction farther than the chassis can stabilize.
	if(current_speed > 0.05)
		var/vel_x = cy_velocity_x / current_speed
		var/vel_y = cy_velocity_y / current_speed
		if(!cy_grip_x && !cy_grip_y)
			cy_grip_x = vel_x
			cy_grip_y = vel_y

		if(has_accel)
			cy_approach_grip_vector(cy_accel_x, cy_accel_y, cy_grip_follow_speed * terrain_grip * seconds_per_tick)
		else
			cy_approach_grip_vector(vel_x, vel_y, cy_grip_follow_speed * 0.45 * terrain_grip * seconds_per_tick)

		var/grip_length = sqrt(cy_grip_x * cy_grip_x + cy_grip_y * cy_grip_y)
		if(grip_length <= 0)
			cy_grip_x = vel_x
			cy_grip_y = vel_y
		else
			cy_grip_x /= grip_length
			cy_grip_y /= grip_length

		var/grip_dot = clamp(vel_x * cy_grip_x + vel_y * cy_grip_y, -1, 1)
		var/grip_slip = 1 - grip_dot
		var/stable_limit = cy_stable_slip_limit * max(terrain_grip, 0.25)
		cy_is_drifting = (grip_slip > stable_limit && current_speed > cy_min_drift_speed)
		cy_drift_amount = grip_slip * current_speed

		// 4. Maneuverability pulls velocity direction toward acceleration.
		// Stable vehicles follow strongly and lose speed in sharp turns. Drifting vehicles follow weakly but keep speed.
		if(has_accel)
			var/accel_dot = clamp(vel_x * cy_accel_x + vel_y * cy_accel_y, -1, 1)
			var/accel_slip = 1 - accel_dot
			var/follow = cy_maneuverability * driver_transport_stat_multiplier * terrain_grip * seconds_per_tick
			if(cy_is_drifting)
				follow *= cy_drift_control_mult
			cy_approach_velocity_direction(cy_accel_x, cy_accel_y, follow)

			current_speed = cy_get_speed()
			var/speed_loss = accel_slip * cy_turn_loss_mult * seconds_per_tick
			if(cy_is_drifting)
				speed_loss *= (1 - cy_drift_retention)
			speed_loss = clamp(speed_loss, 0, 0.55)
			cy_velocity_x *= (1 - speed_loss)
			cy_velocity_y *= (1 - speed_loss)
	else
		cy_is_drifting = FALSE
		cy_drift_amount = 0

	// 5. World drag. With no desired input it is stronger; in drift, retention keeps speed from vanishing instantly.
	var/drag = cy_drag * CY_VEHICLE_DRAG_SCALE * seconds_per_tick
	if(!has_desired)
		drag *= 2.2
	else if(cy_is_drifting)
		drag *= (1 - cy_drift_retention)
	drag = clamp(drag, 0, 0.8)
	cy_velocity_x *= (1 - drag)
	cy_velocity_y *= (1 - drag)

	current_speed = cy_get_speed()
	if(current_speed > effective_max_speed)
		var/final_speed_scale = effective_max_speed / current_speed
		cy_velocity_x *= final_speed_scale
		cy_velocity_y *= final_speed_scale

	if(abs(cy_velocity_x) < 0.05)
		cy_velocity_x = 0
	if(abs(cy_velocity_y) < 0.05)
		cy_velocity_y = 0

	var/next_px = cy_world_px + cy_velocity_x * seconds_per_tick
	var/next_py = cy_world_py + cy_velocity_y * seconds_per_tick

	if(cy_can_occupy_pixel_position(next_px, next_py))
		cy_world_px = next_px
		cy_world_py = next_py
	else
		cy_on_pixel_collision(cy_velocity_to_dir())
		cy_velocity_x = 0
		cy_velocity_y = 0
		cy_is_drifting = FALSE
		cy_drift_amount = 0

	cy_apply_world_pixel_position()


/obj/vehicle/sealed/car/proc/cy_approach_accel_vector(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	cy_accel_x += (target_x - cy_accel_x) * amount
	cy_accel_y += (target_y - cy_accel_y) * amount
	var/length = sqrt(cy_accel_x * cy_accel_x + cy_accel_y * cy_accel_y)
	if(length <= 0)
		cy_accel_x = 0
		cy_accel_y = 0
		return
	cy_accel_x /= length
	cy_accel_y /= length

/obj/vehicle/sealed/car/proc/cy_approach_grip_vector(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	cy_grip_x += (target_x - cy_grip_x) * amount
	cy_grip_y += (target_y - cy_grip_y) * amount
	var/length = sqrt(cy_grip_x * cy_grip_x + cy_grip_y * cy_grip_y)
	if(length <= 0)
		return
	cy_grip_x /= length
	cy_grip_y /= length

/obj/vehicle/sealed/car/proc/cy_approach_velocity_direction(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	var/speed = cy_get_speed()
	if(speed <= 0)
		return
	var/current_x = cy_velocity_x / speed
	var/current_y = cy_velocity_y / speed
	current_x += (target_x - current_x) * amount
	current_y += (target_y - current_y) * amount
	var/length = sqrt(current_x * current_x + current_y * current_y)
	if(length <= 0)
		return
	current_x /= length
	current_y /= length
	cy_velocity_x = current_x * speed
	cy_velocity_y = current_y * speed


/obj/vehicle/sealed/car/proc/cy_apply_world_pixel_position()
	var/tile = CY_VEHICLE_TILE_PIXELS
	var/new_x = FLOOR(cy_world_px / tile, 1) + 1
	var/new_y = FLOOR(cy_world_py / tile, 1) + 1
	var/new_pixel_x = round(cy_world_px - ((new_x - 1) * tile))
	var/new_pixel_y = round(cy_world_py - ((new_y - 1) * tile))

	if(new_pixel_x > tile * 0.5)
		new_pixel_x -= tile
		new_x++
	else if(new_pixel_x < -tile * 0.5)
		new_pixel_x += tile
		new_x--

	if(new_pixel_y > tile * 0.5)
		new_pixel_y -= tile
		new_y++
	else if(new_pixel_y < -tile * 0.5)
		new_pixel_y += tile
		new_y--

	var/turf/new_turf = locate(new_x, new_y, z)
	var/animation_time = max(1, round(SSfastprocess.wait))
	var/did_register_to_new_turf = FALSE

	if(new_turf && loc != new_turf)
		var/turf/old_turf = loc
		var/old_x = x
		var/old_y = y
		var/old_pixel_x = pixel_x
		var/old_pixel_y = pixel_y
		var/move_dir = get_dir(src, new_turf)
		forceMove(new_turf)
		did_register_to_new_turf = TRUE

		// Keep the rendered position continuous across technical turf registration changes.
		// Without this, the camera sees: turf jumps by 32px, then pixel_x/y animates back.
		// That creates the visible squash/jolt during tile boundary crossings.
		var/tile_shift_x = (x - old_x) * tile
		var/tile_shift_y = (y - old_y) * tile
		pixel_x = old_pixel_x - tile_shift_x
		pixel_y = old_pixel_y - tile_shift_y
		cy_sync_occupant_cameras(pixel_x, pixel_y, 0)

		if(trailer && old_turf)
			var/dir_to_move = get_dir(trailer.loc, old_turf)
			step(trailer, dir_to_move)
		if(move_dir)
			after_move(move_dir)

	if(!cy_smooth_pixel_motion)
		pixel_x = new_pixel_x
		pixel_y = new_pixel_y
		cy_sync_occupant_cameras(new_pixel_x, new_pixel_y)
		return

	if(did_register_to_new_turf)
		animate(src, pixel_x = new_pixel_x, pixel_y = new_pixel_y, time = animation_time, flags = ANIMATION_END_NOW)
		cy_sync_occupant_cameras(new_pixel_x, new_pixel_y, animation_time)
		return

	animate(src, pixel_x = new_pixel_x, pixel_y = new_pixel_y, time = animation_time, flags = ANIMATION_END_NOW)
	cy_sync_occupant_cameras(new_pixel_x, new_pixel_y, animation_time)

/obj/vehicle/sealed/car/proc/cy_sync_occupant_cameras(target_pixel_x = pixel_x, target_pixel_y = pixel_y, animation_time = 0)
	if(!cy_smooth_camera_follow || !cy_pixel_physics)
		return
	for(var/mob/occupant as anything in occupants)
		cy_sync_occupant_camera(occupant, target_pixel_x, target_pixel_y, animation_time)

/obj/vehicle/sealed/car/proc/cy_sync_occupant_camera(mob/occupant, target_pixel_x = pixel_x, target_pixel_y = pixel_y, animation_time = 0)
	if(!cy_smooth_camera_follow || !cy_pixel_physics || !occupant?.client)
		return
	var/client/occupant_client = occupant.client
	if(animation_time > 0)
		animate(occupant_client, pixel_x = target_pixel_x, pixel_y = target_pixel_y, time = animation_time, flags = ANIMATION_END_NOW)
	else
		occupant_client.pixel_x = target_pixel_x
		occupant_client.pixel_y = target_pixel_y

/obj/vehicle/sealed/car/proc/cy_reset_occupant_camera(mob/occupant)
	if(!occupant?.client)
		return
	animate(occupant.client, pixel_x = 0, pixel_y = 0, time = 1, flags = ANIMATION_END_NOW)

/obj/vehicle/sealed/car/proc/cy_can_occupy_pixel_position(test_px, test_py)
	if(cy_pixel_point_blocked(test_px, test_py))
		return FALSE
	if(cy_pixel_point_blocked(test_px + cy_collision_half_width, test_py + cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(test_px + cy_collision_half_width, test_py - cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(test_px - cy_collision_half_width, test_py + cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(test_px - cy_collision_half_width, test_py - cy_collision_half_height))
		return FALSE
	return TRUE

/obj/vehicle/sealed/car/proc/cy_pixel_point_blocked(test_px, test_py)
	var/tile = CY_VEHICLE_TILE_PIXELS
	var/check_x = FLOOR(test_px / tile, 1) + 1
	var/check_y = FLOOR(test_py / tile, 1) + 1
	var/turf/check_turf = locate(check_x, check_y, z)
	if(!check_turf || check_turf.density)
		return TRUE

	for(var/atom/movable/movable_content as anything in check_turf)
		if(movable_content == src)
			continue
		if(movable_content.density)
			return TRUE

	return FALSE

/obj/vehicle/sealed/car/proc/cy_on_pixel_collision(direction)
	var/speed = cy_get_speed()
	if(speed < 1)
		return
	var/collision_damage = round(speed * cy_collision_damage_mult)
	if(collision_damage <= 0)
		return
	visible_message(span_warning("[src] skids into an obstacle!"))
	playsound(src, 'sound/vehicles/car_crash.ogg', 70, TRUE)
	cy_apply_part_damage(collision_damage, CY_VEHICLE_PART_SUSPENSION)
	take_damage(collision_damage * 0.5, BRUTE, 0, TRUE, direction)

/obj/vehicle/sealed/car/proc/cy_apply_part_damage(amount, preferred_slot)
	if(amount <= 0)
		return
	var/remaining = amount
	if(preferred_slot == CY_VEHICLE_PART_SUSPENSION && cy_suspension)
		remaining = cy_suspension.cy_receive_damage(remaining)
	if(remaining > 0 && cy_hull)
		remaining = cy_hull.cy_receive_damage(remaining)
	if(remaining > 0 && cy_engine)
		remaining = cy_engine.cy_receive_damage(remaining)
		if(cy_engine.cy_broken && cy_engine_explosion_chance && prob(cy_engine_explosion_chance))
			visible_message(span_danger("[src]'s engine ruptures!"))
			explosion(src, light_impact_range = 1, adminlog = FALSE)
	cy_rebuild_vehicle_stats()

/obj/vehicle/sealed/car/proc/cy_get_speed()
	return sqrt(cy_velocity_x * cy_velocity_x + cy_velocity_y * cy_velocity_y)

/obj/vehicle/sealed/car/proc/cy_get_effective_max_speed()
	return max(cy_max_speed * CY_VEHICLE_SPEED_SCALE, 1)

/obj/vehicle/sealed/car/proc/cy_get_forward_speed()
	return cy_velocity_x * cy_forward_x + cy_velocity_y * cy_forward_y

/obj/vehicle/sealed/car/proc/cy_get_drift_amount()
	return cy_drift_amount

/obj/vehicle/sealed/car/proc/cy_set_forward_from_dir(direction)
	switch(direction)
		if(EAST)
			cy_forward_x = 1
			cy_forward_y = 0
		if(WEST)
			cy_forward_x = -1
			cy_forward_y = 0
		if(SOUTH)
			cy_forward_x = 0
			cy_forward_y = -1
		if(NORTHEAST)
			cy_forward_x = 0.707
			cy_forward_y = 0.707
		if(NORTHWEST)
			cy_forward_x = -0.707
			cy_forward_y = 0.707
		if(SOUTHEAST)
			cy_forward_x = 0.707
			cy_forward_y = -0.707
		if(SOUTHWEST)
			cy_forward_x = -0.707
			cy_forward_y = -0.707
		else
			cy_forward_x = 0
			cy_forward_y = 1
	cy_normalize_forward_vector()

/obj/vehicle/sealed/car/proc/cy_normalize_forward_vector()
	var/length = sqrt(cy_forward_x * cy_forward_x + cy_forward_y * cy_forward_y)
	if(length <= 0)
		cy_forward_x = 0
		cy_forward_y = 1
		return
	cy_forward_x /= length
	cy_forward_y /= length

/obj/vehicle/sealed/car/proc/cy_forward_to_dir()
	var/x = cy_forward_x
	var/y = cy_forward_y
	if(y >= 0.45)
		if(x >= 0.45)
			return NORTHEAST
		if(x <= -0.45)
			return NORTHWEST
		return NORTH
	if(y <= -0.45)
		if(x >= 0.45)
			return SOUTHEAST
		if(x <= -0.45)
			return SOUTHWEST
		return SOUTH
	if(x >= 0)
		return EAST
	return WEST

/obj/vehicle/sealed/car/proc/cy_velocity_to_dir()
	var/x = cy_velocity_x
	var/y = cy_velocity_y
	if(abs(x) < 0.01 && abs(y) < 0.01)
		return dir
	if(abs(x) > abs(y))
		return x > 0 ? EAST : WEST
	return y > 0 ? NORTH : SOUTH

/obj/vehicle/sealed/car/proc/cy_vector_to_debug_angle()
	// Only approximate. Used for examine/debug, not physics.
	var/direction = cy_forward_to_dir()
	return cy_dir_to_angle(direction)

/obj/vehicle/sealed/car/proc/cy_get_terrain_grip()
	var/turf/current_turf = get_turf(src)
	if(isnull(current_turf))
		return 1
	// Road detection can be made stricter when the map turf set is finalized.
	if(istype(current_turf, /turf/open/floor))
		return cy_road_grip
	return cy_offroad_grip

/obj/vehicle/sealed/car/proc/cy_dir_to_angle(direction)
	switch(direction)
		if(EAST)
			return 0
		if(NORTHEAST)
			return 45
		if(NORTH)
			return 90
		if(NORTHWEST)
			return 135
		if(WEST)
			return 180
		if(SOUTHWEST)
			return 225
		if(SOUTH)
			return 270
		if(SOUTHEAST)
			return 315
	return 90

/obj/vehicle/sealed/car/proc/cy_angle_to_dir(angle)
	angle = cy_normalize_angle(angle)
	if(angle >= 337.5 || angle < 22.5)
		return EAST
	if(angle < 67.5)
		return NORTHEAST
	if(angle < 112.5)
		return NORTH
	if(angle < 157.5)
		return NORTHWEST
	if(angle < 202.5)
		return WEST
	if(angle < 247.5)
		return SOUTHWEST
	if(angle < 292.5)
		return SOUTH
	return SOUTHEAST

/obj/vehicle/sealed/car/proc/cy_normalize_angle(angle)
	while(angle < 0)
		angle += 360
	while(angle >= 360)
		angle -= 360
	return angle

// Vehicle part datums are items, so they can be moved, installed, sold and damaged.
/obj/item/cy_vehicle_part
	name = "vehicle part"
	desc = "A modular vehicle component."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_NORMAL
	var/cy_part_slot
	var/cy_drive_kind
	var/cy_part_max_integrity = 100
	var/cy_part_integrity = 100
	var/cy_mass = 10
	var/cy_max_speed = 0
	var/cy_acceleration = 0
	var/cy_turn_rate = 0
	var/cy_road_grip = 1
	var/cy_offroad_grip = 1
	var/cy_lateral_grip = 0.2
	var/cy_engine_response = 0
	var/cy_maneuverability = 0
	var/cy_stable_slip_limit = 0.25
	var/cy_drift_retention = 0.78
	var/cy_turn_loss_mult = 0.45
	var/cy_brake_force = 0.5
	var/cy_drag = 0.04
	var/cy_engine_type
	var/cy_explosion_chance = 0
	var/cy_marks_civilian_modified = FALSE
	var/cy_blocks_autocharge = FALSE
	var/obj/vehicle/sealed/car/cy_installed_vehicle
	var/icon/cy_overlay_icon = 'icons/mob/rideables/vehicles.dmi'
	var/cy_overlay_state = "clowncar"
	var/cy_overlay_layer_offset = 0.01
	var/cy_overlay_pixel_x = 0
	var/cy_overlay_pixel_y = 0
	var/cy_overlay_color

/obj/item/cy_vehicle_part/proc/cy_get_overlay_appearance(base_layer = ABOVE_MOB_LAYER)
	if(!cy_overlay_icon || !cy_overlay_state)
		return null
	var/mutable_appearance/overlay = mutable_appearance(cy_overlay_icon, cy_overlay_state, base_layer + cy_overlay_layer_offset)
	overlay.pixel_x = cy_overlay_pixel_x
	overlay.pixel_y = cy_overlay_pixel_y
	if(cy_overlay_color)
		overlay.color = cy_overlay_color
	return overlay

/obj/item/cy_vehicle_part/proc/cy_get_efficiency()
	if(cy_broken || cy_part_max_integrity <= 0)
		return 0
	return clamp(cy_part_integrity / cy_part_max_integrity, 0, 1)

/obj/item/cy_vehicle_part/proc/cy_receive_damage(amount)
	if(amount <= 0 || cy_broken)
		return amount
	var/new_integrity = cy_part_integrity - amount
	cy_part_integrity = max(new_integrity, 0)
	if(cy_part_integrity <= 0)
		cy_broken = TRUE
		if(cy_installed_vehicle)
			cy_installed_vehicle.visible_message(span_warning("[src] breaks inside [cy_installed_vehicle]!"))
	return max(-new_integrity, 0)

/obj/item/cy_vehicle_part/drive
	name = "vehicle drive part"
	cy_part_slot = CY_VEHICLE_PART_DRIVE
	cy_part_max_integrity = 80
	cy_part_integrity = 80

/obj/item/cy_vehicle_part/drive/wheel
	name = "basic wheel assembly"
	cy_drive_kind = CY_VEHICLE_DRIVE_WHEEL
	cy_mass = 35
	cy_max_speed = 3
	cy_acceleration = 0.12
	cy_turn_rate = 6
	cy_road_grip = 1.15
	cy_offroad_grip = 0.55
	cy_lateral_grip = 0.24
	cy_stable_slip_limit = 0.25
	cy_drift_retention = 0.78

/obj/item/cy_vehicle_part/drive/wheel/road
	name = "road wheel assembly"
	cy_max_speed = 3.8
	cy_acceleration = 0.15
	cy_turn_rate = 7
	cy_road_grip = 1.35
	cy_offroad_grip = 0.45
	cy_lateral_grip = 0.28
	cy_stable_slip_limit = 0.24
	cy_drift_retention = 0.82

/obj/item/cy_vehicle_part/drive/wheel/offroad
	name = "offroad wheel assembly"
	cy_max_speed = 3.2
	cy_acceleration = 0.14
	cy_turn_rate = 6
	cy_road_grip = 1
	cy_offroad_grip = 0.95
	cy_lateral_grip = 0.25
	cy_stable_slip_limit = 0.32
	cy_drift_retention = 0.76

/obj/item/cy_vehicle_part/drive/track
	name = "track assembly"
	cy_drive_kind = CY_VEHICLE_DRIVE_TRACK
	cy_mass = 70
	cy_max_speed = 2.5
	cy_acceleration = 0.1
	cy_turn_rate = 4.5
	cy_road_grip = 0.9
	cy_offroad_grip = 0.9
	cy_lateral_grip = 0.35
	cy_stable_slip_limit = 0.46
	cy_drift_retention = 0.68
	cy_marks_civilian_modified = TRUE
	cy_blocks_autocharge = TRUE

/obj/item/cy_vehicle_part/drive/flight
	name = "gravitic lift engine"
	cy_drive_kind = CY_VEHICLE_DRIVE_FLIGHT
	cy_mass = 55
	cy_max_speed = 3.4
	cy_acceleration = 0.13
	cy_turn_rate = 5.5
	cy_road_grip = 1
	cy_offroad_grip = 1
	cy_lateral_grip = 0.18
	cy_stable_slip_limit = 0.35
	cy_drift_retention = 0.9
	cy_marks_civilian_modified = TRUE
	cy_blocks_autocharge = TRUE

/obj/item/cy_vehicle_part/suspension
	name = "basic suspension"
	cy_part_slot = CY_VEHICLE_PART_SUSPENSION
	cy_part_max_integrity = 120
	cy_part_integrity = 120
	cy_mass = 90
	cy_brake_force = 0.65
	cy_lateral_grip = 0.25
	cy_engine_response = 1
	cy_maneuverability = 2.4
	cy_stable_slip_limit = 0.26
	cy_drift_retention = 0.78

/obj/item/cy_vehicle_part/suspension/sport
	name = "sport suspension"
	cy_brake_force = 0.75
	cy_lateral_grip = 0.32
	cy_engine_response = 1.5
	cy_maneuverability = 3.2
	cy_stable_slip_limit = 0.28
	cy_drift_retention = 0.84
	cy_mass = 75

/obj/item/cy_vehicle_part/suspension/heavy
	name = "heavy suspension"
	cy_part_max_integrity = 180
	cy_part_integrity = 180
	cy_brake_force = 0.55
	cy_lateral_grip = 0.22
	cy_engine_response = 0.5
	cy_maneuverability = 1.5
	cy_stable_slip_limit = 0.42
	cy_drift_retention = 0.7
	cy_mass = 150
	cy_marks_civilian_modified = TRUE

/obj/item/cy_vehicle_part/hull
	name = "civilian hull"
	cy_part_slot = CY_VEHICLE_PART_HULL
	cy_part_max_integrity = 180
	cy_part_integrity = 180
	cy_mass = 350
	cy_drag = 0.035
	cy_turn_loss_mult = 0.45

/obj/item/cy_vehicle_part/hull/clown
	name = "clown car hull"
	desc = "A tiny, suspiciously roomy hull painted in deeply unserious colors."
	cy_part_max_integrity = 150
	cy_part_integrity = 150
	cy_mass = 260
	cy_drag = 0.03
	cy_turn_loss_mult = 0.38

/obj/item/cy_vehicle_part/hull/armored
	name = "armored vehicle hull"
	cy_part_max_integrity = 350
	cy_part_integrity = 350
	cy_mass = 700
	cy_drag = 0.055
	cy_turn_loss_mult = 0.65
	cy_marks_civilian_modified = TRUE
	cy_blocks_autocharge = TRUE

/obj/item/cy_vehicle_part/engine
	name = "vehicle engine"
	cy_part_slot = CY_VEHICLE_PART_ENGINE
	cy_part_max_integrity = 120
	cy_part_integrity = 120
	cy_mass = 160
	cy_engine_type = CY_VEHICLE_ENGINE_ENERGY
	cy_explosion_chance = 5

/obj/item/cy_vehicle_part/engine/electric
	name = "electric engine"
	cy_engine_type = CY_VEHICLE_ENGINE_ENERGY
	cy_max_speed = 2.6
	cy_acceleration = 0.28
	cy_engine_response = 4.5
	cy_explosion_chance = 2

/obj/item/cy_vehicle_part/engine/electric/basic
	name = "basic electric engine"

/obj/item/cy_vehicle_part/engine/fuel
	name = "fuel engine"
	cy_engine_type = CY_VEHICLE_ENGINE_FUEL
	cy_max_speed = 3.2
	cy_acceleration = 0.38
	cy_engine_response = 5.5
	cy_explosion_chance = 12
	cy_blocks_autocharge = TRUE

/obj/item/cy_vehicle_part/engine/battery
	name = "battery engine"
	cy_engine_type = CY_VEHICLE_ENGINE_BATTERY
	cy_max_speed = 2.9
	cy_acceleration = 0.32
	cy_engine_response = 4.8
	cy_explosion_chance = 6
	cy_blocks_autocharge = TRUE
