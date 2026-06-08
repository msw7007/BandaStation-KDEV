/mob/living/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	clear_focused_look()
	if(cyberpunk_shift_middle_listening)
		stop_held_intent_listen()
	else if(listening_intently)
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

/mob/living/proc/try_jump_forward(long_jump = FALSE)
	if(currently_jumping)
		return FALSE
	if(!(mobility_flags & MOBILITY_MOVE) || body_position != STANDING_UP || buckled || incapacitated)
		balloon_alert(src, "can't jump")
		return FALSE
	if(!can_jump() || !spend_stamina(STAMINA_COST_JUMP, "jump"))
		balloon_alert(src, "too tired")
		return FALSE

	long_jump = (long_jump || move_intent == MOVE_INTENT_RUN) && !(movement_type & FLOATING)
	INVOKE_ASYNC(src, PROC_REF(perform_jump_sequence), dir, long_jump)
	return TRUE

/mob/living/proc/perform_jump_sequence(jump_dir, long_jump = FALSE)
	currently_jumping = TRUE
	var/original_pixel_z = pixel_z
	setDir(jump_dir)
	var/air_distance = long_jump ? 3 : 2
	var/turf/current_turf = get_turf(src)
	var/turf/landing_turf = current_turf
	var/atom/jumpable_obstacle
	for(var/i in 1 to air_distance)
		landing_turf = get_step(landing_turf, jump_dir)
		if(!landing_turf)
			pixel_z = original_pixel_z
			handle_jump_collision(jump_dir)
			currently_jumping = FALSE
			return FALSE
		if(landing_turf.is_blocked_turf(source_atom = src))
			if(i < air_distance)
				if(!jumpable_obstacle)
					jumpable_obstacle = get_jumpable_obstacle(landing_turf)
				if(jumpable_obstacle)
					continue
			pixel_z = original_pixel_z
			handle_jump_collision(jump_dir)
			currently_jumping = FALSE
			return FALSE

	animate_jump_arc(1, air_distance, original_pixel_z)
	sleep(world.tick_lag)
	forceMove(landing_turf)
	setDir(jump_dir)
	if(jumpable_obstacle)
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] vaults over [jumpable_obstacle.declent_ru(ACCUSATIVE)]."), span_notice("You vault over [jumpable_obstacle.declent_ru(ACCUSATIVE)]."))
	else
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] jumps forward."), span_notice("You jump forward."))
	animate(src, pixel_z = original_pixel_z, time = world.tick_lag, easing = SINE_EASING|EASE_IN)
	sleep(world.tick_lag)

	apply_cyberpunk_acrobatics_speed_bonus()
	if(long_jump)
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

/mob/living/proc/perform_cyberpunk_self_drag(atom/over)
	if(!over)
		return FALSE
	if(ismovable(over))
		var/atom/movable/movable_cover = over
		if(stealth_mode && movable_cover.can_hide_under_stealth_cover(src))
			return hide_under_stealth_cover(movable_cover)
	if(isturf(over))
		return start_wall_hug(over)
	return FALSE

/mob/living/proc/handle_cyberpunk_shift_secondary_click(atom/target, params)
	if(!target)
		return FALSE
	if(cyberpunk_shift_middle_listening)
		stop_held_intent_listen()
		return TRUE
	if(target == src)
		look_up()
		return TRUE
	if(isturf(target))
		var/turf/target_turf = target
		if(!target_turf.density && get_dist(src, target_turf) <= 1)
			var/look_dir = get_dir(src, target_turf)
			if(look_dir)
				setDir(look_dir)
			look_down()
			return TRUE
	if(focused_look)
		clear_focused_look()
		return TRUE
	if(!toggle_focused_look())
		return FALSE
	focus_look_at(target)
	return TRUE

/mob/living/proc/get_wall_hug_cover(atom/preferred_cover = null)
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return null
	if(preferred_cover)
		var/turf/preferred_turf = get_turf(preferred_cover)
		if(preferred_turf && get_dist(current_turf, preferred_turf) <= 1 && preferred_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
			return preferred_turf
	for(var/check_dir in GLOB.cardinals)
		var/turf/check_turf = get_step(current_turf, check_dir)
		if(check_turf?.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
			return check_turf
	return null

/mob/living/proc/near_wall_hug_cover()
	return !!get_wall_hug_cover()

/mob/living/proc/start_wall_hug(atom/preferred_cover = null)
	if(wall_hugging)
		return TRUE
	if(body_position != STANDING_UP || buckled || incapacitated)
		balloon_alert(src, "can't hug cover")
		return FALSE
	var/turf/cover = get_wall_hug_cover(preferred_cover)
	if(!cover)
		balloon_alert(src, "no cover")
		return FALSE
	wall_hugging = TRUE
	var/wall_dir = get_dir(src, cover)
	if(wall_dir && !ISDIAGONALDIR(wall_dir))
		setDir(REVERSE_DIR(wall_dir))
		start_leaning(cover, 11)
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
	stop_leaning()
	chameleon_bonus = max(0, chameleon_bonus - WALL_HUG_CHAMELEON_BONUS)
	remove_movespeed_modifier(/datum/movespeed_modifier/wall_hug)
	if(wall_hug_started_stealth)
		wall_hug_started_stealth = FALSE
	if(stealth_mode)
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
	return max(0, current_turf.get_lumcount() - get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 3) * 0.01)

/mob/living/proc/get_stealth_skill_bonus()
	return get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 1)

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
	var/perk_cap = get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 6)
	var/effective_chameleon_cap = perk_cap > 0 ? max(chameleon_cap, perk_cap) : chameleon_cap
	var/target_chameleon = clamp(round((1 - light_level) * STEALTH_CHAMELEON_MAX) + get_stealth_skill_bonus() + chameleon_bonus, 0, effective_chameleon_cap)
	var/change_rate = (target_chameleon > chameleon ? STEALTH_CHAMELEON_FADE_RATE : STEALTH_CHAMELEON_LIGHT_RATE) + chameleon_speed_bonus + round(get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 2) * 0.1)
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
	var/maximum_multiplier = max(STEALTH_DAMAGE_MULTIPLIER_MAX, 1 + get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 5) * 0.1)
	return clamp(STEALTH_DAMAGE_MULTIPLIER_MIN + ((maximum_multiplier - STEALTH_DAMAGE_MULTIPLIER_MIN) * (chameleon / STEALTH_CHAMELEON_MAX)), STEALTH_DAMAGE_MULTIPLIER_MIN, maximum_multiplier)

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

/mob/living/proc/set_vertical_state(new_state, duration = 0, turf/anchor_turf = null)
	if(vertical_state_timer != TIMER_ID_NULL)
		deltimer(vertical_state_timer)
		vertical_state_timer = TIMER_ID_NULL
	if(vertical_stamina_timer != TIMER_ID_NULL)
		deltimer(vertical_stamina_timer)
		vertical_stamina_timer = TIMER_ID_NULL

	vertical_state = new_state
	vertical_state_until = duration > 0 ? world.time + duration : 0

	if(vertical_state == VERTICAL_STATE_NONE)
		clear_vertical_anchor()
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, VERTICAL_STATE_TRAIT)
		return TRUE

	if(vertical_state == VERTICAL_STATE_HANGING || vertical_state == VERTICAL_STATE_CLIMBING)
		if(!set_vertical_anchor(anchor_turf || find_vertical_anchor()))
			vertical_state = VERTICAL_STATE_NONE
			REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, VERTICAL_STATE_TRAIT)
			return FALSE
	else
		clear_vertical_anchor()

	if(vertical_state == VERTICAL_STATE_HANGING || vertical_state == VERTICAL_STATE_CLIMBING || vertical_state == VERTICAL_STATE_AIRBORNE)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, VERTICAL_STATE_TRAIT)

	if(duration > 0)
		vertical_state_timer = addtimer(CALLBACK(src, PROC_REF(end_vertical_state), new_state), duration, TIMER_STOPPABLE)

	if(vertical_state == VERTICAL_STATE_HANGING || vertical_state == VERTICAL_STATE_CLIMBING)
		vertical_stamina_timer = addtimer(CALLBACK(src, PROC_REF(vertical_stamina_tick), new_state), VERTICAL_STAMINA_TICK, TIMER_STOPPABLE)
	return TRUE

/mob/living/proc/end_vertical_state(ending_state)
	if(vertical_state != ending_state)
		return
	set_vertical_state(VERTICAL_STATE_NONE)
	if(ending_state == VERTICAL_STATE_AIRBORNE)
		var/turf/current_turf = get_turf(src)
		current_turf?.zFall(src)

/mob/living/proc/vertical_stamina_tick(ticking_state)
	if(vertical_state != ticking_state)
		return
	var/stamina_cost = vertical_state == VERTICAL_STATE_CLIMBING ? VERTICAL_CLIMB_STAMINA_COST : VERTICAL_HANG_STAMINA_COST
	if(!spend_stamina(stamina_cost, "vertical_movement"))
		set_vertical_state(VERTICAL_STATE_NONE)
		var/turf/current_turf = get_turf(src)
		current_turf?.zFall(src)
		return
	vertical_stamina_timer = addtimer(CALLBACK(src, PROC_REF(vertical_stamina_tick), ticking_state), VERTICAL_STAMINA_TICK, TIMER_STOPPABLE)

/mob/living/proc/reset_vertical_fall_chain()
	vertical_fall_chain = 0
	vertical_last_fall_time = 0
	vertical_ignore_next_fall_delay = FALSE

/mob/living/proc/clear_vertical_anchor()
	if(vertical_anchor_pixel_x || vertical_anchor_pixel_y)
		pixel_x -= vertical_anchor_pixel_x
		pixel_y -= vertical_anchor_pixel_y
		vertical_anchor_pixel_x = 0
		vertical_anchor_pixel_y = 0
	vertical_anchor_turf = null
	vertical_anchor_dir = NONE

/mob/living/proc/find_vertical_anchor(preferred_dir = NONE)
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return null
	if(preferred_dir)
		var/turf/preferred_turf = get_step(current_turf, preferred_dir)
		if(is_valid_vertical_anchor(preferred_turf, current_turf))
			return preferred_turf
	for(var/check_dir in GLOB.cardinals)
		var/turf/check_turf = get_step(current_turf, check_dir)
		if(is_valid_vertical_anchor(check_turf, current_turf))
			return check_turf
	return null

/mob/living/proc/is_valid_vertical_anchor(turf/anchor_turf, turf/from_turf = null)
	if(!anchor_turf)
		return FALSE
	from_turf ||= get_turf(src)
	if(!from_turf || get_dist(from_turf, anchor_turf) > 1)
		return FALSE
	var/anchor_dir = get_dir(from_turf, anchor_turf)
	if(!anchor_dir || ISDIAGONALDIR(anchor_dir))
		return FALSE
	if(anchor_turf.density)
		return TRUE
	for(var/atom/movable/thing as anything in anchor_turf)
		if(thing == src)
			continue
		if(thing.density && !(thing.flags_1 & ON_BORDER_1))
			return TRUE
	return FALSE

/mob/living/proc/set_vertical_anchor(turf/anchor_turf)
	var/turf/current_turf = get_turf(src)
	if(!is_valid_vertical_anchor(anchor_turf, current_turf))
		return FALSE
	clear_vertical_anchor()
	vertical_anchor_turf = anchor_turf
	vertical_anchor_dir = get_dir(current_turf, anchor_turf)
	apply_vertical_anchor_visual()
	return TRUE

/mob/living/proc/apply_vertical_anchor_visual()
	if(!vertical_anchor_dir)
		return
	var/new_pixel_x = 0
	var/new_pixel_y = 0
	if(vertical_anchor_dir & EAST)
		new_pixel_x = 8
	else if(vertical_anchor_dir & WEST)
		new_pixel_x = -8
	if(vertical_anchor_dir & NORTH)
		new_pixel_y = 8
	else if(vertical_anchor_dir & SOUTH)
		new_pixel_y = -8
	vertical_anchor_pixel_x = new_pixel_x
	vertical_anchor_pixel_y = new_pixel_y
	pixel_x += vertical_anchor_pixel_x
	pixel_y += vertical_anchor_pixel_y

/mob/living/proc/can_vertical_anchor_move(direction)
	if(vertical_state != VERTICAL_STATE_HANGING && vertical_state != VERTICAL_STATE_CLIMBING)
		return FALSE
	if(!vertical_anchor_turf || !vertical_anchor_dir)
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf || !is_valid_vertical_anchor(vertical_anchor_turf, current_turf))
		return FALSE
	if(!(direction in GLOB.cardinals) && direction != UP && direction != DOWN)
		return FALSE
	return TRUE

/mob/living/proc/try_vertical_anchor_move(direction)
	if(!can_vertical_anchor_move(direction))
		return FALSE
	var/turf/current_turf = get_turf(src)
	var/turf/target_turf
	var/turf/target_anchor
	if(direction == UP || direction == DOWN)
		target_turf = get_step_multiz(current_turf, direction)
		target_anchor = get_step_multiz(vertical_anchor_turf, direction)
	else
		target_turf = get_step(current_turf, direction)
		target_anchor = get_step(target_turf, vertical_anchor_dir)
	if(!target_turf || !target_anchor)
		return FALSE
	if(target_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
		return FALSE
	if(!is_valid_vertical_anchor(target_anchor, target_turf))
		return FALSE
	var/old_anchor_dir = vertical_anchor_dir
	clear_vertical_anchor()
	forceMove(target_turf)
	if(!set_vertical_anchor(target_anchor))
		set_vertical_state(VERTICAL_STATE_NONE)
		return FALSE
	if(vertical_anchor_dir != old_anchor_dir)
		setDir(REVERSE_DIR(vertical_anchor_dir))
	return TRUE

/mob/living/proc/try_delay_vertical_fall(turf/fall_from, levels = 1, force = FALSE, falling_from_move = FALSE)
	if(vertical_state == VERTICAL_STATE_HANGING || vertical_state == VERTICAL_STATE_CLIMBING)
		set_currently_z_moving(FALSE, TRUE)
		return TRUE
	if(vertical_state == VERTICAL_STATE_AIRBORNE && world.time < vertical_state_until)
		set_currently_z_moving(FALSE, TRUE)
		return TRUE
	if(vertical_ignore_next_fall_delay)
		vertical_ignore_next_fall_delay = FALSE
		vertical_last_fall_time = world.time
		return FALSE
	if(vertical_state == VERTICAL_STATE_FALLING_RECOVER)
		return TRUE
	if(world.time > vertical_last_fall_time + VERTICAL_FALL_CHAIN_RESET_TIME)
		vertical_fall_chain = 0
	if(vertical_fall_chain <= 0)
		vertical_fall_chain = 1
		vertical_last_fall_time = world.time
		return FALSE
	set_vertical_state(VERTICAL_STATE_FALLING_RECOVER, VERTICAL_FALL_RECOVERY_TIME)
	set_currently_z_moving(FALSE, TRUE)
	addtimer(CALLBACK(src, PROC_REF(continue_delayed_vertical_fall), fall_from, levels, force, falling_from_move), VERTICAL_FALL_RECOVERY_TIME, TIMER_STOPPABLE)
	return TRUE

/mob/living/proc/continue_delayed_vertical_fall(turf/fall_from, levels = 1, force = FALSE, falling_from_move = FALSE)
	if(QDELETED(src) || vertical_state != VERTICAL_STATE_FALLING_RECOVER || get_turf(src) != fall_from)
		return
	set_vertical_state(VERTICAL_STATE_NONE)
	vertical_fall_chain++
	vertical_ignore_next_fall_delay = TRUE
	fall_from.zFall(src, levels, force, falling_from_move)

/mob/living/proc/start_vertical_hanging(duration = VERTICAL_HANG_TIME, turf/anchor_turf = null)
	if(!set_vertical_state(VERTICAL_STATE_HANGING, duration, anchor_turf))
		return FALSE
	balloon_alert(src, "hanging")
	return TRUE

/mob/living/proc/start_vertical_climbing(duration = VERTICAL_HANG_TIME, turf/anchor_turf = null)
	if(!set_vertical_state(VERTICAL_STATE_CLIMBING, duration, anchor_turf))
		return FALSE
	balloon_alert(src, "climbing")
	return TRUE

/mob/living/proc/start_vertical_airborne(duration = VERTICAL_AIRBORNE_TIME)
	set_vertical_state(VERTICAL_STATE_AIRBORNE, duration)
	balloon_alert(src, "airborne")

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
