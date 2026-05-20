/mob/living/proc/get_cy_sleep_quality()
	var/sleep_quality = 0.2
	if(mob_mood)
		switch(mob_mood.sanity_level)
			if(SANITY_LEVEL_GREAT)
				sleep_quality = 0.2
			if(SANITY_LEVEL_NEUTRAL)
				sleep_quality = 0.1
			if(SANITY_LEVEL_DISTURBED)
				sleep_quality = 0
			if(SANITY_LEVEL_UNSTABLE)
				sleep_quality = 0
			if(SANITY_LEVEL_CRAZY)
				sleep_quality = -0.1
			if(SANITY_LEVEL_INSANE)
				sleep_quality = -0.2

	var/turf/rest_turf = get_turf(src)
	if(rest_turf && (is_blind_from(EYES_COVERED) || rest_turf.get_lumcount() <= LIGHTING_TILE_IS_DARK))
		sleep_quality += 0.1

	if(HAS_TRAIT(src, TRAIT_DEAF))
		sleep_quality += 0.1

	if(locate(/obj/structure/bed) in loc)
		sleep_quality += 0.2
	else if(locate(/obj/structure/table) in loc)
		sleep_quality += 0.1

	if(locate(/obj/item/bedsheet) in loc)
		sleep_quality += 0.1

	if(locate(/obj/item/pillow) in loc)
		sleep_quality += 0.1

	return sleep_quality

/mob/living/carbon/human/proc/is_cy_comfortably_sleeping()
	if(!IsSleeping())
		return FALSE
	if(get_cy_hunger_level() >= CY_NEED_STAGE_LOW || get_cy_thirst_level() >= CY_NEED_STAGE_LOW)
		return FALSE
	if(!(locate(/obj/structure/bed) in loc))
		return FALSE
	return get_cy_sleep_quality() >= 0.5

/mob/living/proc/set_cy_stealth_mode(enabled)
	var/new_mode = !!enabled
	if(new_mode == cy_stealth_mode)
		update_cy_chameleon()
		return cy_stealth_mode
	cy_stealth_mode = new_mode
	if(cy_stealth_mode)
		cy_stealth_original_alpha = alpha
		add_movespeed_modifier(/datum/movespeed_modifier/cy_stealth)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/cy_stealth)
		cy_chameleon_level = 0
		cy_wall_pressed = FALSE
		cy_wall_press_dir = NONE
		remove_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, animate = TRUE)
		animate(src, alpha = cy_stealth_original_alpha || 255, time = 0.3 SECONDS)
		return FALSE
	update_cy_chameleon()
	return cy_stealth_mode

/mob/living/proc/is_cy_stealthing()
	return cy_stealth_mode && cy_chameleon_level > 0

/mob/living/proc/get_cy_stealth_light_factor()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return 1
	return clamp(current_turf.get_lumcount(), 0, 1)

/mob/living/proc/get_cy_equipment_noise_weight()
	var/weight = 0
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		weight += equipped.w_class
	return weight

/mob/living/proc/get_cy_noise_level()
	var/noise = get_cy_equipment_noise_weight()
	if(is_cy_stealthing())
		noise *= max(0.1, 1 - cy_chameleon_level / 100)
	return noise

/mob/living/proc/update_cy_chameleon()
	if(!cy_stealth_mode || stat == DEAD)
		cy_chameleon_level = 0
		animate(src, alpha = cy_stealth_original_alpha || 255, time = 0.2 SECONDS)
		return 0
	var/stealth_level = get_cy_skill_level(/datum/cy_skill/charisma/stealth)
	var/light_factor = get_cy_stealth_light_factor()
	var/light_hide = round((1 - light_factor) * CY_STEALTH_CHAMELEON_MAX)
	var/skill_bonus = stealth_level * 10
	var/move_penalty = (world.time - cy_last_stealth_move_time) <= 1 SECONDS ? CY_STEALTH_MOVE_PENALTY : 0
	var/weight_penalty = round(get_cy_equipment_noise_weight() * CY_STEALTH_WEIGHT_PENALTY_PER_CLASS)
	var/wall_bonus = cy_wall_pressed ? CY_STEALTH_WALL_CHAMELEON_BONUS : 0
	var/hidden_bonus = cy_hidden_under ? CY_STEALTH_HIDDEN_CHAMELEON_BONUS : 0
	cy_chameleon_level = clamp(light_hide + skill_bonus + wall_bonus + hidden_bonus - move_penalty - weight_penalty, 0, CY_STEALTH_CHAMELEON_MAX)
	var/target_alpha = round((cy_stealth_original_alpha || 255) - ((cy_stealth_original_alpha || 255) - CY_STEALTH_MIN_ALPHA) * (cy_chameleon_level / CY_STEALTH_CHAMELEON_MAX))
	animate(src, alpha = target_alpha, time = 0.3 SECONDS)
	if(client && world.time >= cy_last_stealth_debug_time + CY_STEALTH_DEBUG_INTERVAL)
		cy_last_stealth_debug_time = world.time
		to_chat(src, span_notice("Скрытность: свет [round(light_factor * 100)]%, хамелеон [cy_chameleon_level]%."))
	return cy_chameleon_level

/mob/living/proc/reveal_cy_stealth(reason)
	if(!cy_stealth_mode)
		return FALSE
	set_cy_stealth_mode(FALSE)
	return TRUE

/mob/living/proc/set_cy_look_mode(enabled)
	cy_look_mode = !!enabled
	return cy_look_mode

/mob/living/proc/set_cy_listen_mode(enabled)
	cy_listen_mode = !!enabled
	return cy_listen_mode

/mob/living/proc/toggle_cy_listen_mode(show_message = TRUE)
	set_cy_listen_mode(!cy_listen_mode)
	if(show_message)
		if(cy_listen_mode)
			to_chat(src, span_notice("Вы прислушиваетесь."))
		else
			to_chat(src, span_notice("Вы перестаёте прислушиваться."))
	return cy_listen_mode

/mob/living/proc/get_cy_fov_angle()
	if(is_blind())
		return 0
	if(is_nearsighted_currently())
		return max(30, CY_DEFAULT_FOV_DEGREES * 0.5)
	return CY_DEFAULT_FOV_DEGREES

/mob/living/proc/get_cy_view_range()
	var/base_range = client?.view || world.view
	if(cy_look_mode)
		base_range += 3
	if(is_blind())
		return 0
	if(is_nearsighted_currently())
		return min(base_range, NEARSIGHTNESS_FOV_BLINDNESS)
	return base_range

/mob/living/proc/cy_is_in_fov(atom/target)
	if(!target || target == src)
		return TRUE
	if(is_blind())
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return FALSE
	var/rel_x = target_turf.x - my_turf.x
	var/rel_y = target_turf.y - my_turf.y
	if(abs(rel_x) <= 1 && abs(rel_y) <= 1)
		return TRUE
	if(get_dist(src, target) > get_cy_view_range())
		return FALSE
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
	if(!dir_x && !dir_y)
		return TRUE
	var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))
	return angle <= get_cy_fov_angle() * 0.5

/mob/living/proc/cy_can_hear_event(atom/source)
	if(!source)
		return FALSE
	if(get_dist(src, source) <= world.view)
		return TRUE
	if(!cy_listen_mode)
		return FALSE
	if(get_dist(src, source) > world.view + 3)
		return FALSE
	var/turf/start = get_turf(src)
	var/turf/end = get_turf(source)
	if(!start || !end)
		return FALSE
	var/dense_turfs = 0
	for(var/turf/checked_turf as anything in get_line(start, end))
		if(checked_turf.density)
			dense_turfs++
			if(dense_turfs > 1)
				return FALSE
