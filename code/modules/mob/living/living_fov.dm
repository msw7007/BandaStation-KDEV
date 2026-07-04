/// Is `observed_atom` in a mob's field of view? This takes blindness, nearsightness and FOV into consideration
/mob/living/proc/in_fov(atom/observed_atom, ignore_self = FALSE)
	if(ignore_self && observed_atom == src)
		return TRUE

	if(is_blind())
		return FALSE

	var/turf/my_turf = get_turf(src) //Because being inside contents of something will cause our x,y to not be updated
	// If turf doesn't exist, then we wouldn't get a fov check called by `play_fov_effect` or presumably other new stuff that might check this.
	//  ^ If that case has changed and you need that check, add it.
	var/rel_x = observed_atom.x - my_turf.x
	var/rel_y = observed_atom.y - my_turf.y

	// Handling nearsightnedness
	if(is_nearsighted_currently())
		if(abs(rel_x) >= NEARSIGHTNESS_FOV_BLINDNESS || abs(rel_y) >= NEARSIGHTNESS_FOV_BLINDNESS)
			return FALSE

	if(!fov_view)
		return TRUE

	if(rel_x >= -1 && rel_x <= 1 && rel_y >= -1 && rel_y <= 1) //Cheap way to check inside that 3x3 box around you
		return TRUE //Also checks if both are 0 to stop division by zero

	// Get the vector length so we can create a good directional vector
	var/vector_len = sqrt(abs(rel_x) ** 2 + abs(rel_y) ** 2)

	/// Getting a direction vector
	var/dir_x = 0 // based on east/west
	var/dir_y = 0 // based on north/south

	if(dir & NORTH)
		dir_y += vector_len
	else if(dir & SOUTH)
		dir_y -= vector_len

	if(dir & EAST)
		dir_x += vector_len
	else if(dir & WEST)
		dir_x -= vector_len

	///Calculate angle
	var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))

	/// Calculate vision angle and compare
	var/vision_angle = (360 - abs(fov_view)) / 2
	if(fov_view > 0)
		return angle < vision_angle
	return angle > vision_angle

/// Code-only field of view used by mechanics that care where the mob is facing, not by the client's rendered view.
/mob/living/proc/in_code_fov(atom/observed_atom, ignore_self = FALSE)
	if(ignore_self && observed_atom == src)
		return TRUE
	if(is_blind())
		return FALSE
	if(code_fov_angle >= 360)
		return TRUE
	var/turf/my_turf = get_turf(src)
	var/turf/observed_turf = get_turf(observed_atom)
	if(!my_turf || !observed_turf)
		return FALSE
	var/rel_x = observed_turf.x - my_turf.x
	var/rel_y = observed_turf.y - my_turf.y
	if(rel_x >= -1 && rel_x <= 1 && rel_y >= -1 && rel_y <= 1)
		return TRUE
	var/vector_len = sqrt(abs(rel_x) ** 2 + abs(rel_y) ** 2)
	var/dir_x = 0
	var/dir_y = 0
	if(dir & NORTH)
		dir_y += vector_len
	else if(dir & SOUTH)
		dir_y -= vector_len
	if(dir & EAST)
		dir_x += vector_len
	else if(dir & WEST)
		dir_x -= vector_len
	var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))
	return angle <= (code_fov_angle / 2)

/// Multiplier for attacks against this mob from outside its code FOV.
/mob/living/proc/get_rear_attack_multiplier(atom/movable/attacker)
	if(in_code_fov(attacker, ignore_self = TRUE))
		return 1
	return 1.25

/// Updates code-only FOV from current eye damage. Visual TG FOV remains separate.
/mob/living/proc/update_code_fov()
	var/eye_damage = get_eye_damage_percent()
	if(eye_damage >= 75)
		code_fov_angle = 90
	else if(eye_damage >= 50)
		code_fov_angle = 180
	else if(eye_damage >= 25)
		code_fov_angle = 270
	else
		code_fov_angle = 360

/// Override on carbon/human if a different eye damage source becomes canonical.
/mob/living/proc/get_eye_damage_percent()
	return 0

/mob/living/carbon/get_eye_damage_percent()
	var/obj/item/organ/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(!eyes?.maxHealth)
		return 100
	return (eyes.damage / eyes.maxHealth) * 100

/// Toggle distant inspection by extending the client's view without changing code FOV.
/mob/living/proc/toggle_focused_look()
	if(!client)
		return FALSE
	if(focused_look)
		clear_focused_look()
		return TRUE
	focused_look = TRUE
	balloon_alert(src, "choose focus")
	return TRUE

/mob/living/proc/focus_look_at(atom/target)
	if(!client || !target)
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return FALSE
	var/x_offset = clamp(target_turf.x - my_turf.x, -FOCUS_LOOK_MAX_TILES, FOCUS_LOOK_MAX_TILES)
	var/y_offset = clamp(target_turf.y - my_turf.y, -FOCUS_LOOK_MAX_TILES, FOCUS_LOOK_MAX_TILES)
	animate(client, pixel_x = x_offset * FOCUS_LOOK_PIXEL_MULTIPLIER, pixel_y = y_offset * FOCUS_LOOK_PIXEL_MULTIPLIER, time = 0.25 SECONDS, easing = SINE_EASING|EASE_OUT)
	return TRUE

/mob/living/proc/clear_focused_look()
	if(!focused_look && !client?.pixel_x && !client?.pixel_y)
		return
	focused_look = FALSE
	if(client)
		animate(client, pixel_x = 0, pixel_y = 0, time = 0.15 SECONDS, easing = SINE_EASING|EASE_OUT)
	balloon_alert(src, "focused look off")

/// Toggle active listening through one wall block.
/mob/living/proc/toggle_intent_listen()
	listening_intently = !listening_intently
	balloon_alert(src, listening_intently ? "listening" : "stopped listening")
	return listening_intently

/mob/living/proc/start_held_intent_listen()
	if(listening_intently && cyberpunk_shift_middle_listening)
		return TRUE
	clear_focused_look()
	cyberpunk_shift_middle_listening = TRUE
	cyberpunk_shift_middle_listen_started = 0
	cyberpunk_shift_middle_listen_ref = null
	if(!listening_intently)
		listening_intently = TRUE
		balloon_alert(src, "listening")
	return TRUE

/mob/living/proc/stop_held_intent_listen()
	if(!cyberpunk_shift_middle_listening)
		return FALSE
	cyberpunk_shift_middle_listening = FALSE
	cyberpunk_shift_middle_listen_started = 0
	cyberpunk_shift_middle_listen_ref = null
	if(listening_intently)
		listening_intently = FALSE
		balloon_alert(src, "stopped listening")
	return TRUE

/mob/living/proc/prepare_held_intent_listen(atom/target)
	if(target != src)
		return FALSE
	cyberpunk_shift_middle_listen_started = world.time
	cyberpunk_shift_middle_listen_ref = WEAKREF(target)
	return TRUE

/mob/living/proc/complete_held_intent_listen()
	if(!cyberpunk_shift_middle_listen_started)
		return FALSE
	var/atom/target = cyberpunk_shift_middle_listen_ref?.resolve()
	if(target != src)
		clear_held_intent_listen_pending()
		return FALSE
	if(world.time < cyberpunk_shift_middle_listen_started + 0.35 SECONDS)
		clear_held_intent_listen_pending()
		return FALSE
	return start_held_intent_listen()

/mob/living/proc/clear_held_intent_listen_pending()
	cyberpunk_shift_middle_listen_started = 0
	cyberpunk_shift_middle_listen_ref = null

/// Updates the applied FOV value and applies the handler to client if able
/mob/living/proc/update_fov()
	var/highest_fov
	for(var/trait_type in fov_traits)
		var/fov_type = fov_traits[trait_type]
		if(!highest_fov || fov_type > highest_fov) // Forward-facing FOV always takes priority over reversed FOV
			highest_fov = fov_type
	fov_view = highest_fov
	if(HAS_TRAIT(src, TRAIT_EXPANDED_FOV))
		fov_view += 30
	update_fov_client()

/// Updates the FOV for the client.
/mob/living/proc/update_fov_client()
	if(!client)
		return
	var/datum/component/fov_handler/fov_component = GetComponent(/datum/component/fov_handler)
	if(fov_view)
		if(!fov_component)
			AddComponent(/datum/component/fov_handler, fov_view)
		else
			fov_component.set_fov_angle(fov_view)
	else if(fov_component)
		qdel(fov_component)

/// Adds a trait which limits a user's FOV
/mob/living/proc/add_fov_trait(source, type)
	LAZYSET(fov_traits, source, type)
	update_fov()

/// Removes a trait which limits a user's FOV
/mob/living/proc/remove_fov_trait(source, type)
	if(!fov_traits) //Clothing equip/unequip is bad code and invokes this several times
		return
	LAZYREMOVE(fov_traits, source)
	update_fov()

//did you know you can subtype /image and /mutable_appearance? // Stop telling them that they might actually do it
/image/fov_image
	icon = 'icons/effects/fov/fov_effects.dmi'
	layer = EFFECTS_LAYER + FOV_EFFECT_LAYER
	appearance_flags = RESET_COLOR | RESET_TRANSFORM
	plane = FULLSCREEN_PLANE

/mob/living/var/tmp/list/partial_wall_occlusion_images
/mob/living/var/tmp/partial_wall_occlusion_update_timer = TIMER_ID_NULL

/proc/is_partial_wall_occlusion_enabled()
	return !isnull(global.config) && CONFIG_GET(flag/partial_wall_occlusion)

/proc/update_nearby_partial_wall_occlusion(atom/center)
	if(!is_partial_wall_occlusion_enabled() || !length(GLOB.player_list))
		return
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return
	for(var/mob/player_mob as anything in GLOB.player_list)
		var/mob/living/viewer = player_mob
		if(!istype(viewer) || !viewer.client)
			continue
		var/turf/viewer_turf = get_turf(viewer.client.eye || viewer)
		if(!viewer_turf || viewer_turf.z != center_turf.z || get_dist(viewer_turf, center_turf) > 16)
			continue
		viewer.request_partial_wall_occlusion_update()

/proc/get_partial_wall_occlusion_scan_view(view_size)
	var/static/list/scan_views_by_key = list()
	var/view_key = "[view_size]"
	if(!isnull(scan_views_by_key[view_key]))
		return scan_views_by_key[view_key]

	if(isnum(view_size))
		scan_views_by_key[view_key] = view_size + 1
		return scan_views_by_key[view_key]

	var/text_view = view_key
	var/list/view_parts = splittext(text_view, "x")
	if(length(view_parts) >= 2)
		var/view_width = text2num(view_parts[1])
		var/view_height = text2num(view_parts[2])
		if(view_width && view_height)
			scan_views_by_key[view_key] = "[view_width + 2]x[view_height + 2]"
			return scan_views_by_key[view_key]
	var/view_range = text2num(text_view)
	if(!isnull(view_range))
		scan_views_by_key[view_key] = view_range + 1
		return scan_views_by_key[view_key]

	scan_views_by_key[view_key] = view_size
	return scan_views_by_key[view_key]

/proc/get_partial_wall_occlusion_view_bounds(view_size)
	var/static/list/view_bounds_by_key = list()
	var/view_key = "[view_size]"
	if(view_bounds_by_key[view_key])
		return view_bounds_by_key[view_key]

	var/list/view_bounds
	if(isnum(view_size))
		view_bounds = list("x" = view_size, "y" = view_size)
	else
		var/text_view = view_key
		var/list/view_parts = splittext(text_view, "x")
		if(length(view_parts) >= 2)
			var/view_width = text2num(view_parts[1])
			var/view_height = text2num(view_parts[2])
			if(view_width && view_height)
				view_bounds = list("x" = round((view_width - 1) * 0.5), "y" = round((view_height - 1) * 0.5))
		if(!view_bounds)
			var/view_range = text2num(text_view)
			view_bounds = list("x" = view_range || 7, "y" = view_range || 7)

	view_bounds_by_key[view_key] = view_bounds
	return view_bounds_by_key[view_key]

/proc/build_partial_wall_occlusion_icon(x1, y1, x2, y2)
	if(x1 > x2 || y1 > y2)
		return null
	var/icon/cut_icon = icon('icons/blanks/32x32.dmi', "nothing")
	cut_icon.DrawBox(COLOR_BLACK, x1, y1, x2, y2)
	return cut_icon

/proc/get_partial_wall_occlusion_icon(cut_dir)
	var/static/list/partial_wall_occlusion_icons
	var/static/cached_x_pixels
	var/static/cached_y_pixels

	var/x_pixels = CONFIG_GET(number/partial_wall_occlusion_x_pixels)
	var/y_pixels = CONFIG_GET(number/partial_wall_occlusion_y_pixels)
	if(!partial_wall_occlusion_icons || cached_x_pixels != x_pixels || cached_y_pixels != y_pixels)
		partial_wall_occlusion_icons = list()
		cached_x_pixels = x_pixels
		cached_y_pixels = y_pixels

		partial_wall_occlusion_icons["[EAST]"] = build_partial_wall_occlusion_icon(ICON_SIZE_X - x_pixels + 1, 1, ICON_SIZE_X, ICON_SIZE_Y)
		partial_wall_occlusion_icons["[WEST]"] = build_partial_wall_occlusion_icon(1, 1, x_pixels, ICON_SIZE_Y)
		partial_wall_occlusion_icons["[NORTH]"] = build_partial_wall_occlusion_icon(1, ICON_SIZE_Y - y_pixels + 1, ICON_SIZE_X, ICON_SIZE_Y)
		partial_wall_occlusion_icons["[SOUTH]"] = build_partial_wall_occlusion_icon(1, 1, ICON_SIZE_X, ICON_SIZE_Y - y_pixels)

	return partial_wall_occlusion_icons["[cut_dir]"]

/mob/living/proc/clear_partial_wall_occlusion()
	if(partial_wall_occlusion_update_timer != TIMER_ID_NULL)
		deltimer(partial_wall_occlusion_update_timer)
		partial_wall_occlusion_update_timer = TIMER_ID_NULL
	if(!length(partial_wall_occlusion_images))
		LAZYCLEARLIST(partial_wall_occlusion_images)
		return
	if(client)
		for(var/mask_key in partial_wall_occlusion_images)
			var/image/cut_mask = partial_wall_occlusion_images[mask_key]
			client.images -= cut_mask
	LAZYCLEARLIST(partial_wall_occlusion_images)

/mob/living/proc/request_partial_wall_occlusion_update(immediate = FALSE)
	if(!is_partial_wall_occlusion_enabled())
		clear_partial_wall_occlusion()
		return
	if(!client)
		LAZYCLEARLIST(partial_wall_occlusion_images)
		return
	if(immediate)
		if(partial_wall_occlusion_update_timer != TIMER_ID_NULL)
			deltimer(partial_wall_occlusion_update_timer)
			partial_wall_occlusion_update_timer = TIMER_ID_NULL
		update_partial_wall_occlusion()
		return
	if(partial_wall_occlusion_update_timer != TIMER_ID_NULL)
		return
	partial_wall_occlusion_update_timer = addtimer(CALLBACK(src, PROC_REF(run_partial_wall_occlusion_update)), world.tick_lag, TIMER_STOPPABLE)

/mob/living/proc/run_partial_wall_occlusion_update()
	partial_wall_occlusion_update_timer = TIMER_ID_NULL
	update_partial_wall_occlusion()

/mob/living/proc/add_partial_wall_occlusion_mask(atom/occluder, cut_dir, list/desired_masks)
	var/icon/mask_icon = get_partial_wall_occlusion_icon(cut_dir)
	if(!mask_icon)
		return
	var/mask_key = "[REF(occluder)]-[cut_dir]"
	desired_masks[mask_key] = list(
		"occluder" = occluder,
		"dir" = cut_dir,
	)

/mob/living/proc/queue_partial_wall_occlusion(atom/occluder, turf/occluder_turf, list/scanned_turfs, list/desired_masks, require_segment_neighbor = TRUE)
	if(!occluder?.opacity || !occluder_turf)
		return

	var/list/cut_dirs = list()
	for(var/check_dir in GLOB.cardinals)
		var/turf/hidden_side = get_step(occluder_turf, check_dir)
		if(hidden_side && scanned_turfs[hidden_side])
			continue

		var/turf/near_side = get_step(occluder_turf, REVERSE_DIR(check_dir))
		if(!near_side || !scanned_turfs[near_side])
			continue

		cut_dirs += check_dir

	var/cut_dir_count = length(cut_dirs)
	if(cut_dir_count == 1)
		var/cut_dir = cut_dirs[1]
		if(require_segment_neighbor)
			var/has_straight_segment_neighbor = FALSE
			if(cut_dir & (EAST|WEST))
				for(var/parallel_dir in list(NORTH, SOUTH))
					var/turf/closed/segment_neighbor = get_step(occluder_turf, parallel_dir)
					if(istype(segment_neighbor) && segment_neighbor.opacity && scanned_turfs[segment_neighbor])
						has_straight_segment_neighbor = TRUE
						break
			else
				for(var/parallel_dir in list(EAST, WEST))
					var/turf/closed/segment_neighbor = get_step(occluder_turf, parallel_dir)
					if(istype(segment_neighbor) && segment_neighbor.opacity && scanned_turfs[segment_neighbor])
						has_straight_segment_neighbor = TRUE
						break
			if(!has_straight_segment_neighbor)
				return
	else if(cut_dir_count == 2)
		if(cut_dirs[1] == REVERSE_DIR(cut_dirs[2]))
			return
	else
		return

	for(var/cut_dir in cut_dirs)
		add_partial_wall_occlusion_mask(occluder, cut_dir, desired_masks)

/mob/living/proc/apply_partial_wall_occlusion_masks(list/desired_masks)
	LAZYINITLIST(partial_wall_occlusion_images)

	var/list/remove_masks
	for(var/mask_key in partial_wall_occlusion_images)
		if(desired_masks[mask_key])
			continue
		LAZYADD(remove_masks, mask_key)

	for(var/mask_key in remove_masks)
		var/image/old_mask = partial_wall_occlusion_images[mask_key]
		client.images -= old_mask
		partial_wall_occlusion_images -= mask_key

	for(var/mask_key in desired_masks)
		if(partial_wall_occlusion_images[mask_key])
			continue
		var/list/mask_data = desired_masks[mask_key]
		var/atom/occluder = mask_data["occluder"]
		var/cut_dir = mask_data["dir"]
		var/image/cut_mask = image(icon = get_partial_wall_occlusion_icon(cut_dir), loc = occluder, layer = ABOVE_ALL_MOB_LAYER)
		cut_mask.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		SET_PLANE_EXPLICIT(cut_mask, ABOVE_LIGHTING_PLANE, occluder)
		partial_wall_occlusion_images[mask_key] = cut_mask
		client.images += cut_mask

/mob/living/proc/update_partial_wall_occlusion()
	if(!client || !is_partial_wall_occlusion_enabled())
		clear_partial_wall_occlusion()
		return

	var/turf/viewer_turf = get_turf(client.eye || src)
	if(!viewer_turf)
		return

	var/list/rendered_turfs = list()
	var/list/scanned_turfs = list()
	var/list/view_bounds = get_partial_wall_occlusion_view_bounds(client.view)
	var/view_x = view_bounds["x"]
	var/view_y = view_bounds["y"]
	for(var/turf/scanned_turf as anything in view(get_partial_wall_occlusion_scan_view(client.view), viewer_turf))
		scanned_turfs[scanned_turf] = TRUE
		if(abs(scanned_turf.x - viewer_turf.x) <= view_x && abs(scanned_turf.y - viewer_turf.y) <= view_y)
			rendered_turfs[scanned_turf] = TRUE

	var/list/desired_masks = list()

	for(var/turf/closed/visible_wall as anything in rendered_turfs)
		queue_partial_wall_occlusion(visible_wall, visible_wall, scanned_turfs, desired_masks)

	for(var/turf/rendered_turf as anything in rendered_turfs)
		for(var/obj/machinery/door/visible_door in rendered_turf)
			queue_partial_wall_occlusion(visible_door, rendered_turf, scanned_turfs, desired_masks, require_segment_neighbor = FALSE)

	apply_partial_wall_occlusion_masks(desired_masks)

/// Plays a visual effect representing a sound cue for people with vision obstructed by FOV or blindness
/proc/play_fov_effect(atom/center, range, icon_state, dir = SOUTH, ignore_self = FALSE, angle = 0, time = 1.5 SECONDS, list/override_list)
	var/turf/anchor_point = get_turf(center)
	var/image/fov_image/fov_image
	var/list/clients_shown

	for(var/mob/living/living_mob in override_list || get_hearers_in_view(range, center))
		var/client/mob_client = living_mob.client
		if(!mob_client)
			continue
		if(HAS_TRAIT(living_mob, TRAIT_DEAF)) //Deaf people can't hear sounds so no sound indicators
			continue
		if(living_mob.in_fov(center, ignore_self))
			continue
		if(!fov_image) //Make the image once we found one recipient to receive it
			fov_image = new()
			fov_image.loc = anchor_point
			fov_image.icon_state = icon_state
			fov_image.dir = dir
			if(angle)
				var/matrix/matrix = new
				matrix.Turn(angle)
				fov_image.transform = matrix
			fov_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		LAZYADD(clients_shown, mob_client)

		mob_client.images += fov_image
		//when added as an image mutable_appearances act identically. we just make it an MA becuase theyre faster to change appearance

	if(clients_shown)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_image_from_clients), fov_image, clients_shown), time)

/atom/movable/screen/fov_blocker
	icon = 'icons/effects/fov/field_of_view.dmi'
	icon_state = "90"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	screen_loc = "BOTTOM,LEFT"
	// Manages itself through the fov_handler component
	clear_with_screen = FALSE
