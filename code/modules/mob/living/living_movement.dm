/mob/living/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	clear_focused_look()
	if(listening_intently)
		toggle_intent_listen()
	if(iscarbon(src))
		var/mob/living/carbon/carbon_mover = src
		carbon_mover.handle_bodypart_movement_trauma()
	update_turf_movespeed(loc)
	update_stealth_chameleon()
	if(HAS_TRAIT(src, TRAIT_NEGATES_GRAVITY))
		if(!isgroundlessturf(loc))
			ADD_TRAIT(src, TRAIT_IGNORING_GRAVITY, IGNORING_GRAVITY_NEGATION)
		else
			REMOVE_TRAIT(src, TRAIT_IGNORING_GRAVITY, IGNORING_GRAVITY_NEGATION)

	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(src)
	// If we're moving to/from nullspace, refresh
	// Easier then adding nullchecks to all this shit, and technically right since a null turf means nograv
	if(isnull(old_turf) || isnull(new_turf))
		if(!QDELING(src))
			refresh_gravity()
		return
	// If the turf gravity has changed, then it's possible that our state has changed, so update
	if(HAS_TRAIT(old_turf, TRAIT_FORCED_GRAVITY) != HAS_TRAIT(new_turf, TRAIT_FORCED_GRAVITY) || new_turf.force_no_gravity != old_turf.force_no_gravity)
		refresh_gravity()

	// Going to do area gravity checking here
	var/area/old_area = old_turf.loc
	var/area/new_area = new_turf.loc
	// If the area gravity has changed, then it's possible that our state has changed, so update
	if(old_area.default_gravity != new_area.default_gravity)
		refresh_gravity()

/mob/living/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	. = ..()

	if(!old_turf || !new_turf || SSmapping.gravity_by_z_level[old_turf.z] != SSmapping.gravity_by_z_level[new_turf.z])
		refresh_gravity()

/// Living Mob use event based gravity
/// We check here to ensure we haven't dropped any gravity changes
/mob/living/proc/gravity_setup()
	on_negate_gravity(src)
	refresh_gravity()

/// Handles gravity effects. Call if something about our gravity has potentially changed!
/mob/living/proc/refresh_gravity()
	var/old_grav_state = gravity_state
	gravity_state = has_gravity()
	if(gravity_state == old_grav_state)
		return

	update_gravity(gravity_state)
	SEND_SIGNAL(src, COMSIG_LIVING_GRAVITY_CHANGED, gravity_state, old_grav_state)
	if(gravity_state > STANDARD_GRAVITY)
		gravity_animate()
	else if(old_grav_state > STANDARD_GRAVITY)
		remove_filter("gravity")

/mob/living/mob_negates_gravity()
	return HAS_TRAIT_FROM(src, TRAIT_IGNORING_GRAVITY, IGNORING_GRAVITY_NEGATION)

/mob/living/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	if(wall_hugging && ismob(mover))
		return TRUE
	if(mover.throwing)
		var/mob/thrower = mover.throwing.get_thrower()
		return (!density || (body_position == LYING_DOWN) || (thrower == src && !ismob(mover)))
	if(buckled == mover)
		return TRUE
	if(ismob(mover) && (mover in buckled_mobs))
		return TRUE
	return !mover.density || body_position == LYING_DOWN

/mob/living/update_config_movespeed()
	update_move_intent_slowdown()
	return ..()

/mob/living/proc/update_move_intent_slowdown()
	add_movespeed_modifier(get_move_intent_slowdown())

/mob/living/proc/get_move_intent_slowdown()
	if(move_intent == MOVE_INTENT_WALK)
		return /datum/movespeed_modifier/config_walk_run/walk
	return /datum/movespeed_modifier/config_walk_run/run

/mob/living/verb/jump_forward()
	set name = "Jump Forward"
	set category = "IC"
	try_jump_forward()

/mob/living/verb/toggle_wall_hug()
	set name = "Wall Hug"
	set category = "IC"
	toggle_wall_hug_state()

/mob/living/proc/stop_sprinting(message, silent = FALSE)
	if(move_intent != MOVE_INTENT_RUN && !has_movespeed_modifier(/datum/movespeed_modifier/sprint_low_stamina))
		last_sprint_dir = NONE
		return
	move_intent = MOVE_INTENT_WALK
	last_sprint_dir = NONE
	remove_movespeed_modifier(/datum/movespeed_modifier/sprint_low_stamina)
	hud_used?.screen_objects[HUD_MOB_MOVE_INTENT]?.update_appearance()
	update_move_intent_slowdown()
	SEND_SIGNAL(src, COMSIG_MOVE_INTENT_TOGGLED)
	if(message && !silent)
		balloon_alert(src, message)

/mob/living/proc/update_sprint_stamina_slowdown()
	if(move_intent == MOVE_INTENT_RUN && stamina <= max_stamina * STAMINA_LOW_RUN_THRESHOLD && stamina > 0)
		add_movespeed_modifier(/datum/movespeed_modifier/sprint_low_stamina)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/sprint_low_stamina)

/mob/living/proc/handle_sprint_step(direct)
	last_sprint_dir = direct
	update_sprint_stamina_slowdown()
	if(stamina > 0)
		return
	stop_sprinting("breathless")
	if(energy_pool <= 0 || is_exhausted_by_needs())
		Knockdown(STAMINA_SPRINT_RESERVE_KNOCKDOWN, ignore_canstun = TRUE)
		return
	Immobilize(STAMINA_SPRINT_BREATHLESS_TIME, ignore_canstun = TRUE)

/mob/living/proc/handle_sprint_collision(atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf || !target_turf.is_blocked_turf(source_atom = src))
		return
	stop_sprinting("crashed")
	Knockdown(STAMINA_SPRINT_COLLISION_KNOCKDOWN, ignore_canstun = TRUE)
	visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] crashes and falls!"), span_userdanger("You crash and fall!"))

/mob/living/proc/try_jump_forward()
	if(currently_jumping)
		return FALSE
	if(!(mobility_flags & MOBILITY_MOVE) || body_position != STANDING_UP || buckled || incapacitated)
		balloon_alert(src, "can't jump")
		return FALSE
	if(!can_jump() || !spend_stamina(STAMINA_COST_JUMP, "jump"))
		balloon_alert(src, "too tired")
		return FALSE

	var/long_jump = move_intent == MOVE_INTENT_RUN && !(movement_type & FLOATING)
	INVOKE_ASYNC(src, PROC_REF(perform_jump_sequence), dir, long_jump)
	return TRUE

/mob/living/proc/perform_jump_sequence(jump_dir, long_jump = FALSE)
	currently_jumping = TRUE
	var/original_pixel_z = pixel_z
	setDir(jump_dir)
	var/air_steps = long_jump ? 2 : 1
	var/success = FALSE
	for(var/i in 1 to air_steps)
		var/turf/current_turf = get_turf(src)
		var/turf/next_turf = get_step(current_turf, jump_dir)
		if(!next_turf)
			pixel_z = original_pixel_z
			handle_jump_collision(jump_dir)
			currently_jumping = FALSE
			return FALSE

		var/atom/jumpable_obstacle
		if(next_turf.is_blocked_turf(source_atom = src))
			jumpable_obstacle = get_jumpable_obstacle(next_turf)
			if(!jumpable_obstacle)
				pixel_z = original_pixel_z
				handle_jump_collision(jump_dir)
				currently_jumping = FALSE
				return FALSE
			var/turf/landing_turf = get_step(next_turf, jump_dir)
			if(!landing_turf || landing_turf.is_blocked_turf(source_atom = src))
				pixel_z = original_pixel_z
				handle_jump_collision(jump_dir)
				currently_jumping = FALSE
				return FALSE
			next_turf = landing_turf
			i = air_steps

		animate_jump_arc(i, air_steps, original_pixel_z)
		sleep(world.tick_lag)
		forceMove(next_turf)
		setDir(jump_dir)
		if(jumpable_obstacle)
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] vaults over [jumpable_obstacle.declent_ru(ACCUSATIVE)]."), span_notice("You vault over [jumpable_obstacle.declent_ru(ACCUSATIVE)]."))
		else
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] jumps forward."), span_notice("You jump forward."))
		success = TRUE
		animate(src, pixel_z = original_pixel_z, time = world.tick_lag, easing = SINE_EASING|EASE_IN)
		sleep(world.tick_lag)

	if(success && long_jump)
		continue_long_jump(jump_dir)
	pixel_z = original_pixel_z
	currently_jumping = FALSE
	return TRUE

/mob/living/proc/animate_jump_arc(step_index, total_steps, original_pixel_z)
	var/arc_peak = total_steps > 1 ? 14 : 10
	if(step_index == total_steps)
		arc_peak = max(8, arc_peak - 4)
	animate(src, pixel_z = original_pixel_z + arc_peak, time = world.tick_lag, easing = SINE_EASING|EASE_OUT)

/mob/living/proc/continue_long_jump(jump_dir)
	var/turf/next_turf = get_step(src, jump_dir)
	if(!next_turf)
		return FALSE
	if(next_turf.is_blocked_turf(source_atom = src))
		handle_jump_collision(jump_dir)
		return FALSE
	Move(next_turf, jump_dir)
	return TRUE

/mob/living/proc/get_jumpable_obstacle(turf/target_turf)
	if(!target_turf)
		return null
	if(HAS_TRAIT(target_turf, TRAIT_CLIMBABLE))
		return target_turf
	for(var/atom/movable/content as anything in target_turf.contents)
		if(HAS_TRAIT(content, TRAIT_CLIMBABLE))
			return content
	return null

/mob/living/proc/handle_jump_collision(jump_dir = NONE)
	if(!jump_dir)
		jump_dir = dir
	var/turf/rebound_turf = get_step(src, REVERSE_DIR(jump_dir))
	if(rebound_turf && !rebound_turf.is_blocked_turf(source_atom = src))
		step(src, REVERSE_DIR(jump_dir))
	Knockdown(STAMINA_JUMP_COLLISION_KNOCKDOWN, ignore_canstun = TRUE)
	visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] clips the obstacle and falls!"), span_userdanger("You clip the obstacle and fall!"))

/mob/living/proc/near_wall_hug_cover()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE
	for(var/check_dir in GLOB.cardinals)
		var/turf/check_turf = get_step(current_turf, check_dir)
		if(check_turf?.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
			return TRUE
	return FALSE

/mob/living/proc/start_wall_hug()
	if(wall_hugging)
		return TRUE
	if(body_position != STANDING_UP || buckled || incapacitated)
		balloon_alert(src, "can't hug cover")
		return FALSE
	if(!near_wall_hug_cover())
		balloon_alert(src, "no cover")
		return FALSE
	wall_hugging = TRUE
	if(!stealth_mode)
		start_stealth()
		wall_hug_started_stealth = TRUE
	chameleon_bonus += WALL_HUG_CHAMELEON_BONUS
	add_movespeed_modifier(/datum/movespeed_modifier/wall_hug)
	if(move_intent == MOVE_INTENT_RUN)
		stop_sprinting(silent = TRUE)
	update_stealth_chameleon()
	balloon_alert(src, "hugging cover")
	return TRUE

/mob/living/proc/stop_wall_hug(silent = FALSE)
	if(!wall_hugging)
		return
	wall_hugging = FALSE
	chameleon_bonus = max(0, chameleon_bonus - WALL_HUG_CHAMELEON_BONUS)
	remove_movespeed_modifier(/datum/movespeed_modifier/wall_hug)
	if(wall_hug_started_stealth)
		wall_hug_started_stealth = FALSE
		end_stealth()
	else
		update_stealth_chameleon()
	if(!silent)
		balloon_alert(src, "left cover")

/mob/living/proc/toggle_wall_hug_state()
	if(wall_hugging)
		stop_wall_hug()
		return FALSE
	return start_wall_hug()

/mob/living/proc/validate_wall_hug()
	if(!wall_hugging)
		return
	if(body_position != STANDING_UP || buckled || incapacitated || !near_wall_hug_cover())
		stop_wall_hug()

/mob/living/proc/update_turf_movespeed(turf/open/turf)
	if(isopenturf(turf) && !HAS_TRAIT(turf, TRAIT_TURF_IGNORE_SLOWDOWN))
		if(turf.slowdown != current_turf_slowdown)
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown, multiplicative_slowdown = turf.slowdown)
			current_turf_slowdown = turf.slowdown
	else if(current_turf_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/turf_slowdown)
		current_turf_slowdown = 0

/mob/living/proc/toggle_stealth_mode()
	if(stealth_mode)
		end_stealth()
		return FALSE
	start_stealth()
	return TRUE

/mob/living/proc/start_stealth()
	if(stealth_mode)
		return
	stealth_mode = TRUE
	ADD_TRAIT(src, TRAIT_SNEAK, TRAIT_GENERIC)
	update_stealth_chameleon()
	balloon_alert(src, "stealth on")

/mob/living/proc/end_stealth(revealed = FALSE)
	if(!stealth_mode && !chameleon && !stealth_cover)
		return
	stealth_mode = FALSE
	chameleon = 0
	chameleon_cap = STEALTH_CHAMELEON_MAX
	stealth_cover = null
	alpha = initial(alpha)
	REMOVE_TRAIT(src, TRAIT_SNEAK, TRAIT_GENERIC)
	if(revealed)
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] emerges from concealment."))
	else
		balloon_alert(src, "stealth off")

/mob/living/proc/get_stealth_light_level()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return 1
	return current_turf.get_lumcount()

/mob/living/proc/get_stealth_skill_bonus()
	return 0

/mob/living/proc/get_stealth_equipment_weight()
	var/total_weight = 0
	for(var/obj/item/item as anything in get_equipped_items(INCLUDE_POCKETS|INCLUDE_HELD|INCLUDE_PROSTHETICS|INCLUDE_ABSTRACT))
		total_weight += item.w_class
	return total_weight

/mob/living/proc/get_stealth_equipment_weight_limit()
	return STEALTH_BASE_EQUIPMENT_WEIGHT_LIMIT + get_stealth_skill_bonus()

/mob/living/proc/stealth_muffles_sound()
	return stealth_mode && chameleon >= STEALTH_SOUND_MUTE_THRESHOLD && get_stealth_equipment_weight() <= get_stealth_equipment_weight_limit()

/mob/living/proc/update_stealth_chameleon()
	if(!stealth_mode)
		return
	var/light_level = get_stealth_light_level()
	var/target_chameleon = clamp(round((1 - light_level) * STEALTH_CHAMELEON_MAX) + get_stealth_skill_bonus() + chameleon_bonus, 0, chameleon_cap)
	var/change_rate = (target_chameleon > chameleon ? STEALTH_CHAMELEON_FADE_RATE : STEALTH_CHAMELEON_LIGHT_RATE) + chameleon_speed_bonus
	if(chameleon < target_chameleon)
		chameleon = min(chameleon + change_rate, target_chameleon)
	else if(chameleon > target_chameleon)
		chameleon = max(chameleon - change_rate, target_chameleon)
	apply_chameleon_alpha()

/mob/living/proc/apply_chameleon_alpha()
	if(!stealth_mode)
		alpha = initial(alpha)
		return
	alpha = round(STEALTH_ALPHA_MAXIMUM - ((STEALTH_ALPHA_MAXIMUM - STEALTH_ALPHA_MINIMUM) * (chameleon / STEALTH_CHAMELEON_MAX)))

/mob/living/proc/get_stealth_damage_multiplier()
	if(!stealth_mode)
		return 1
	return clamp(STEALTH_DAMAGE_MULTIPLIER_MIN + ((STEALTH_DAMAGE_MULTIPLIER_MAX - STEALTH_DAMAGE_MULTIPLIER_MIN) * (chameleon / STEALTH_CHAMELEON_MAX)), STEALTH_DAMAGE_MULTIPLIER_MIN, STEALTH_DAMAGE_MULTIPLIER_MAX)

/mob/living/proc/reveal_from_stealth_attack()
	if(!stealth_mode)
		return
	end_stealth(revealed = TRUE)

/mob/living/proc/hide_under_stealth_cover(atom/movable/cover)
	if(!cover)
		return FALSE
	if(!stealth_mode)
		start_stealth()
	stealth_cover = cover
	chameleon_cap = STEALTH_CHAMELEON_HIDDEN_CAP
	chameleon = STEALTH_CHAMELEON_HIDDEN_CAP
	apply_chameleon_alpha()
	balloon_alert(src, "hidden")
	return TRUE

/mob/living/proc/update_pull_movespeed()
	SEND_SIGNAL(src, COMSIG_LIVING_UPDATING_PULL_MOVESPEED)

	if(pulling)
		if(isliving(pulling))
			var/mob/living/L = pulling
			if(!slowed_by_drag || L.body_position == STANDING_UP || L.buckled || grab_state >= GRAB_AGGRESSIVE)
				remove_movespeed_modifier(/datum/movespeed_modifier/bulky_drag)
				return
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bulky_drag, multiplicative_slowdown = PULL_PRONE_SLOWDOWN)
			return
		if(isobj(pulling))
			var/obj/structure/S = pulling
			if(!slowed_by_drag || !S.drag_slowdown)
				remove_movespeed_modifier(/datum/movespeed_modifier/bulky_drag)
				return
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bulky_drag, multiplicative_slowdown = S.drag_slowdown)
			return
	remove_movespeed_modifier(/datum/movespeed_modifier/bulky_drag)

/**
 * We want to relay the zmovement to the buckled atom when possible
 * and only run what we can't have on buckled.zMove() or buckled.can_z_move() here.
 * This way we can avoid esoteric bugs, copypasta and inconsistencies.
 */
/mob/living/zMove(dir, turf/target, z_move_flags = ZMOVE_FLIGHT_FLAGS)
	if(buckled)
		if(buckled.currently_z_moving)
			return FALSE
		if(!(z_move_flags & ZMOVE_ALLOW_BUCKLED))
			buckled.unbuckle_mob(src, force = TRUE, can_fall = FALSE)
		else
			if(!target)
				target = can_z_move(dir, get_turf(src), null, z_move_flags, src)
				if(!target)
					return FALSE
			return buckled.zMove(dir, target, z_move_flags) // Return value is a loc.
	return ..()

/mob/living/can_z_move(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	if(z_move_flags & ZMOVE_INCAPACITATED_CHECKS && incapacitated)
		if(z_move_flags & ZMOVE_FEEDBACK)
			to_chat(rider || src, span_warning("[rider ? "[declent_ru(NOMINATIVE)] не может" : "Вы не можете"] сейчас это сделать!"))
		return FALSE
	if(!buckled || !(z_move_flags & ZMOVE_ALLOW_BUCKLED))
		if(!(z_move_flags & ZMOVE_FALL_CHECKS) && incorporeal_move && (!rider || rider.incorporeal_move))
			//An incorporeal mob will ignore obstacles unless it's a potential fall (it'd suck hard) or is carrying corporeal mobs.
			//Coupled with flying/floating, this allows the mob to move up and down freely.
			//By itself, it only allows the mob to move down.
			z_move_flags |= ZMOVE_IGNORE_OBSTACLES
		return ..()
	switch(SEND_SIGNAL(buckled, COMSIG_BUCKLED_CAN_Z_MOVE, direction, start, destination, z_move_flags, src))
		if(COMPONENT_RIDDEN_ALLOW_Z_MOVE) // Can be ridden.
			return buckled.can_z_move(direction, start, destination, z_move_flags, src)
		if(COMPONENT_RIDDEN_STOP_Z_MOVE) // Is a ridable but can't be ridden right now. Feedback messages already done.
			return FALSE
		else
			if(!(z_move_flags & ZMOVE_CAN_FLY_CHECKS) && !buckled.anchored)
				return buckled.can_z_move(direction, start, destination, z_move_flags, src)
			if(z_move_flags & ZMOVE_FEEDBACK)
				to_chat(src, span_warning("Для начала отстегнитесь от [buckled.declent_ru(GENITIVE)]."))
			return FALSE

/mob/set_currently_z_moving(value)
	if(buckled)
		return buckled.set_currently_z_moving(value)
	return ..()

/mob/living/keybind_face_direction(direction)
	if(stat > SOFT_CRIT)
		return
	return ..()
// BANDASTATION ADDITION: Limp Quirk
/mob/living/toggle_move_intent(new_intent)

	if(HAS_TRAIT(src, TRAIT_LIMP))

		var/target_intent = new_intent

		if(!target_intent)
			if(move_intent == MOVE_INTENT_RUN)
				target_intent = MOVE_INTENT_WALK
			else
				target_intent = MOVE_INTENT_RUN

		if(SEND_SIGNAL(src, COMSIG_MOB_PRE_TOGGLE_MOVE_INTENT, target_intent) & COMPONENT_PREVENT_TOGGLE_MOVE_INTENT)
			return

	return ..()
// BANDASTATION ADDITION: END
