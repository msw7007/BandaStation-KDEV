/datum/movespeed_modifier/cy_stealth
	movetypes = (~FLYING)
	multiplicative_slowdown = CY_STEALTH_MOVE_SLOWDOWN

/datum/movespeed_modifier/cy_sprint
	movetypes = (~FLYING)
	multiplicative_slowdown = CY_SPRINT_SPEED_MODIFIER

/datum/movespeed_modifier/cy_shoulder_carry
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.7

/datum/movespeed_modifier/cy_arms_carry
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.3

/datum/movespeed_modifier/cy_implant_overload
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.35

/mob/living/proc/update_cy_sprint()
	if(!cy_sprint_enabled || move_intent == MOVE_INTENT_WALK || get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS || body_position != STANDING_UP || stat != CONSCIOUS)
		if(cy_sprinting)
			cy_sprinting = FALSE
			remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		return FALSE
	if(!cy_sprinting)
		cy_sprinting = TRUE
		add_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
	return TRUE

/mob/living/proc/set_cy_sprint_enabled(enabled)
	if(cy_sprint_enabled == enabled)
		if(!enabled && cy_sprinting)
			cy_sprinting = FALSE
			remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		return FALSE
	cy_sprint_enabled = enabled
	if(!cy_sprint_enabled)
		cy_sprinting = FALSE
		remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		to_chat(src, span_notice("Вы замедляете бег."))
		return TRUE
	if(get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS || body_position != STANDING_UP || stat != CONSCIOUS)
		cy_sprint_enabled = FALSE
		to_chat(src, span_warning("У вас не хватает сил для спринта."))
		return FALSE
	to_chat(src, span_notice("Вы переходите на спринт."))
	update_cy_sprint()
	return TRUE

/mob/living/proc/toggle_cy_sprint()
	return set_cy_sprint_enabled(!cy_sprint_enabled)

/mob/living/proc/process_cy_sprint_step()
	if(!cy_sprint_enabled || !update_cy_sprint())
		return FALSE
	if(!cy_sprinting)
		return FALSE
	adjust_stamina_loss(CY_SPRINT_STAMINA_COST_PER_STEP, updating_stamina = FALSE, forced = TRUE)
	if(get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS)
		set_cy_sprint_enabled(FALSE)
	return TRUE


/mob/living/proc/is_cy_sprint_collision_surface(atom/target)
	if(!target)
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/blocker in target_turf)
			if(blocker == src || !blocker.density)
				continue
			return TRUE
		return FALSE
	return target.density

/mob/living/proc/handle_cy_sprint_collision(direction)
	if(!cy_sprinting || !direction || body_position != STANDING_UP || stat != CONSCIOUS)
		return FALSE
	var/turf/collision_turf = get_step(src, direction)
	if(!is_cy_sprint_collision_surface(collision_turf))
		return FALSE
	set_cy_sprint_enabled(FALSE)
	adjust_stamina_loss(CY_SPRINT_STAMINA_COST_PER_STEP * 3, updating_stamina = FALSE, forced = TRUE)
	Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
	visible_message(span_warning("[src] на бегу врезается в препятствие и падает!"), span_userdanger("Вы на бегу врезаетесь в препятствие и падаете!"))
	return TRUE

/atom/movable/cy_look_holder
	invisibility = INVISIBILITY_MAXIMUM
	var/mob/living/owner

/atom/movable/cy_look_holder/Initialize(mapload, mob/living/owner)
	. = ..()
	src.owner = owner
	if(owner)
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(owner_moved))

/atom/movable/cy_look_holder/Destroy()
	if(owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	owner = null
	return ..()

/atom/movable/cy_look_holder/proc/owner_moved(mob/living/source, atom/oldloc, direction, Forced, old_locs)
	SIGNAL_HANDLER
	if(owner)
		owner.end_cy_look_mode(TRUE)

/mob/living/proc/get_cy_action_delay(base_delay = CY_BASE_ACTION_DELAY, skill_type = null)
	var/delay = base_delay
	if(skill_type)
		delay *= get_cy_skill_speed_multiplier(skill_type)
	delay *= get_cy_dexterity_action_delay_multiplier()
	return max(1, round(delay))

/mob/living/proc/apply_cy_action_delay(base_delay = CY_BASE_ACTION_DELAY, skill_type = null)
	changeNext_move(get_cy_action_delay(base_delay, skill_type))
	return TRUE

/mob/living/proc/is_cy_click_held(list/modifiers)
	if(!client?.cy_mouse_down_time)
		return FALSE
	return world.time - client.cy_mouse_down_time >= CY_CLICK_HOLD_THRESHOLD


/mob/living/proc/set_cy_parkour_mode(enabled)
	if(enabled)
		if(stat != CONSCIOUS || body_position != STANDING_UP)
			to_chat(src, span_warning("Сейчас вы не можете заняться паркуром."))
			return FALSE
		cy_parkour_mode = TRUE
		cy_parkour_expires_at = world.time + CY_PARKOUR_MODE_TIMEOUT
		to_chat(src, span_notice("Вы готовитесь к паркурному движению."))
		return TRUE
	cy_parkour_mode = FALSE
	cy_parkour_expires_at = 0
	return TRUE

/mob/living/proc/toggle_cy_parkour_mode()
	return set_cy_parkour_mode(!cy_parkour_mode)

/mob/living/proc/has_cy_parkour_mode()
	if(!cy_parkour_mode)
		return FALSE
	if(world.time > cy_parkour_expires_at)
		set_cy_parkour_mode(FALSE)
		return FALSE
	return TRUE

/mob/living/proc/consume_cy_parkour_mode()
	if(cy_parkour_mode)
		set_cy_parkour_mode(FALSE)
	return TRUE

/mob/living/proc/is_cy_climb_surface(atom/target)
	if(!target || is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/movable_content as anything in target_turf)
			if(movable_content.density && (isstructure(movable_content) || isobj(movable_content)))
				return TRUE
		return FALSE
	return target.density || isstructure(target)

/mob/living/proc/get_cy_parkour_dir(atom/target)
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return NONE
	return get_dir(my_turf, target_turf)

/mob/living/proc/clear_cy_wall_hang(animate_offset = TRUE)
	if(!cy_wall_hanging)
		return FALSE
	cy_wall_hanging = FALSE
	cy_wall_hanging_dir = NONE
	cy_wall_hanging_surface = null
	remove_offsets(CY_PARKOUR_HANG_OFFSET_SOURCE, animate = animate_offset)
	return TRUE

/mob/living/proc/start_cy_wall_hang(atom/surface, jump_to_surface = FALSE)
	if(!surface || !is_cy_climb_surface(surface))
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/surface_turf = get_turf(surface)
	if(!my_turf || !surface_turf || get_dist(my_turf, surface_turf) > 1)
		return FALSE
	var/hang_dir = get_dir(my_turf, surface_turf)
	if(!hang_dir)
		return FALSE
	clear_cy_wall_press(FALSE)
	clear_cy_hide_under()
	clear_cy_wall_hang(FALSE)
	cy_wall_hanging = TRUE
	cy_wall_hanging_dir = hang_dir
	cy_wall_hanging_surface = surface
	var/x_offset = 0
	var/y_offset = 0
	if(hang_dir & EAST)
		x_offset += CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & WEST)
		x_offset -= CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & NORTH)
		y_offset += CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & SOUTH)
		y_offset -= CY_PARKOUR_HANG_PIXEL_OFFSET
	add_offsets(CY_PARKOUR_HANG_OFFSET_SOURCE, null, x_offset, y_offset, null, animate = FALSE)
	adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
	visible_message(span_notice("[src] цепляется за поверхность."), span_notice("Вы цепляетесь за поверхность."))
	if(jump_to_surface && looking_vertically == UP)
		addtimer(CALLBACK(src, PROC_REF(perform_cy_parkour_climb_up)), 2)
	return TRUE

/mob/living/proc/get_cy_parkour_landing_turf(atom/target, distance = 1)
	var/turf/my_turf = get_turf(src)
	if(!my_turf)
		return null
	var/jump_dir = target ? get_dir(my_turf, get_turf(target)) : dir
	if(!jump_dir)
		jump_dir = dir
	var/turf/landing = get_ranged_target_turf(my_turf, jump_dir, distance)
	if(!landing)
		return null
	if(landing.density)
		return null
	for(var/atom/movable/blocker as anything in landing)
		if(blocker == src)
			continue
		if(blocker.density)
			return null
	return landing

/mob/living/proc/perform_cy_parkour_jump(atom/target)
	if(stat != CONSCIOUS || body_position != STANDING_UP)
		return FALSE
	var/jump_distance = cy_sprinting ? 2 : 1
	if(has_cy_skill_perk_level(/datum/cy_skill/dexterity/acrobatics, 4))
		jump_distance++
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/athletics, 6))
		jump_distance++
	var/turf/landing = get_cy_parkour_landing_turf(target, jump_distance)
	if(!landing)
		to_chat(src, span_warning("Вы не видите подходящего места для прыжка."))
		return TRUE
	var/stamina_cost = CY_PARKOUR_JUMP_STAMINA_COST * jump_distance
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/endurance, 2))
		stamina_cost *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/spirit/endurance, 2, "value_1", 20) * 0.01)
	adjust_stamina_loss(stamina_cost, updating_stamina = FALSE, forced = TRUE)
	visible_message(span_notice("[src] прыгает вперёд."), span_notice("Вы прыгаете вперёд."))
	forceMove(landing)
	perform_cy_skill_check(/datum/cy_skill/dexterity/acrobatics, max(1, jump_distance * 10))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_z_jump(atom/target, direction = UP)
	if(stat != CONSCIOUS)
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/success = zMove(direction, target_turf, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(success)
		adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
		perform_cy_skill_check(/datum/cy_skill/dexterity/acrobatics, 20)
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
		return TRUE
	to_chat(src, span_warning("Вы не находите удобного пути."))
	return TRUE

/mob/living/proc/perform_cy_parkour_climb_up()
	if(!cy_wall_hanging)
		return FALSE
	var/result = zMove(UP, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(result)
		visible_message(span_notice("[src] подтягивается наверх."), span_notice("Вы подтягиваетесь наверх."))
		adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
		perform_cy_skill_check(/datum/cy_skill/dexterity/acrobatics, 25)
		clear_cy_wall_hang(FALSE)
	else
		to_chat(src, span_warning("Вы не можете подняться выше."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_descend(safe = TRUE)
	if(!cy_wall_hanging && looking_vertically != DOWN)
		return FALSE
	var/result = zMove(DOWN, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(result)
		if(safe)
			visible_message(span_notice("[src] аккуратно спускается вниз."), span_notice("Вы аккуратно спускаетесь вниз."))
		else
			visible_message(span_notice("[src] скользит вниз по поверхности."), span_notice("Вы скользите вниз по поверхности."))
			if(prob(CY_PARKOUR_SLIDE_FALL_CHANCE))
				Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
		adjust_stamina_loss(max(1, round(CY_PARKOUR_CLIMB_STAMINA_COST * 0.5)), updating_stamina = FALSE, forced = TRUE)
		perform_cy_skill_check(/datum/cy_skill/dexterity/acrobatics, safe ? 15 : 25)
		clear_cy_wall_hang(FALSE)
	else
		if(!safe && prob(CY_PARKOUR_SLIDE_FALL_CHANCE))
			Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
		to_chat(src, span_warning("Спускаться здесь некуда."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_transfer(atom/target)
	if(!cy_wall_hanging || !is_cy_climb_surface(target))
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf || get_dist(my_turf, target_turf) > 1)
		return FALSE
	return start_cy_wall_hang(target, FALSE)

/mob/living/proc/handle_cy_parkour_click(atom/target, list/modifiers)
	if(!target || !islist(modifiers))
		return FALSE
	var/parkour_ready = has_cy_parkour_mode()
	if(!parkour_ready && !cy_wall_hanging)
		return FALSE
	var/is_right = cy_has_click_modifier(modifiers, RIGHT_CLICK)
	var/is_middle = cy_has_click_modifier(modifiers, MIDDLE_CLICK)
	if(cy_wall_hanging)
		if(is_right)
			consume_cy_parkour_mode()
			return perform_cy_parkour_descend(TRUE)
		if(looking_vertically == DOWN && !is_middle)
			consume_cy_parkour_mode()
			return perform_cy_parkour_descend(FALSE)
		if(target == src && !is_middle)
			consume_cy_parkour_mode()
			return perform_cy_parkour_climb_up()
		if(!is_middle && perform_cy_parkour_transfer(target))
			consume_cy_parkour_mode()
			return TRUE
	if(!parkour_ready)
		return FALSE
	consume_cy_parkour_mode()
	if(looking_vertically == DOWN)
		if(is_right)
			return perform_cy_parkour_descend(TRUE)
		return perform_cy_parkour_descend(FALSE)
	if(is_middle)
		if(looking_vertically == UP)
			return perform_cy_parkour_z_jump(target, UP)
		return perform_cy_parkour_jump(target)
	if(!is_right && is_cy_climb_surface(target))
		if(looking_vertically == UP)
			if(start_cy_wall_hang(target, TRUE))
				return TRUE
			return perform_cy_parkour_z_jump(target, UP)
		return start_cy_wall_hang(target, FALSE)
	return FALSE

/mob/living/proc/prepare_cy_combat_intent(atom/target, list/modifiers)
	if(!combat_mode || !islist(modifiers))
		return FALSE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && pulling == target && grab_state < GRAB_NECK)
		return perform_cy_grab_zone_special(target)
	if(cy_has_click_modifier(modifiers, ALT_CLICK))
		modifiers -= ALT_CLICK
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			modifiers[CY_ATTACK_INTENT] = CY_ATTACK_INTENT_PREEMPTIVE
		else
			modifiers[CY_ATTACK_INTENT] = CY_ATTACK_INTENT_TRICKY
		cy_current_attack_intent = modifiers[CY_ATTACK_INTENT]
		return TRUE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
		modifiers[CY_ATTACK_INTENT] = is_cy_click_held(modifiers) ? CY_ATTACK_INTENT_PIERCE : CY_ATTACK_INTENT_STAB
	else
		modifiers[CY_ATTACK_INTENT] = is_cy_click_held(modifiers) ? CY_ATTACK_INTENT_CHOP : CY_ATTACK_INTENT_SLASH
	cy_current_attack_intent = modifiers[CY_ATTACK_INTENT]
	return TRUE


/mob/living/proc/apply_cy_attack_intent_modifiers(obj/item/weapon, list/modifiers, list/attack_modifiers)
	if(!islist(modifiers))
		return FALSE
	var/intent = LAZYACCESS(modifiers, CY_ATTACK_INTENT)
	if(!intent)
		return FALSE
	cy_current_attack_intent = intent
	if(!islist(attack_modifiers))
		return FALSE
	attack_modifiers[CY_ATTACK_INTENT] = intent
	switch(intent)
		if(CY_ATTACK_INTENT_TRICKY)
			attack_modifiers["cy_dodge_break"] = TRUE
		if(CY_ATTACK_INTENT_PREEMPTIVE)
			attack_modifiers["cy_parry_break"] = TRUE
	return TRUE

/mob/living/proc/handle_cy_control_click(atom/target, list/modifiers, params)
	if(!target || !islist(modifiers))
		return FALSE
	if(handle_cy_parkour_click(target, modifiers))
		return TRUE
	if(!combat_mode && cy_has_click_modifier(modifiers, RIGHT_CLICK) && !cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK) && !cy_has_click_modifier(modifiers, MIDDLE_CLICK) && is_cy_click_held(modifiers) && isliving(target) && get_active_held_item())
		give(target)
		return TRUE
	if(combat_mode && cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && !get_active_held_item())
		var/mob/living/running_target = target
		if(running_target.cy_wrestling_running)
			return perform_cy_wrestling_elbow(running_target)
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && pulling && ismob(pulling) && pulling != target && grab_state >= GRAB_AGGRESSIVE && grab_state < GRAB_NECK && !ismob(target))
		return perform_cy_wrestling_launch(target)
	if(ismob(target) && pulling == target && grab_state >= GRAB_NECK)
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			return perform_cy_neck_knee_strike(target)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			return perform_cy_neck_back_throw(target)
		if(!cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK))
			return perform_cy_neck_choke(target)
	if(combat_mode && ismob(target) && can_perform_cy_carry_combat_action(target))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			return perform_cy_carry_knee_strike(target)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			return perform_cy_carry_back_slam(target)
		if(!cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK))
			return perform_cy_carry_floor_slam(target)
	if(cy_defense_hold)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			perform_cy_defense_action(CY_DEFENSE_ACTION_DODGE, target)
			return TRUE
		if(!cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			perform_cy_defense_action(CY_DEFENSE_ACTION_PARRY, target)
			return TRUE
	if(cy_has_click_modifier(modifiers, CTRL_CLICK))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			pointed(target)
			return TRUE
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			if(combat_mode)
				if(perform_cy_uppercut(target))
					return TRUE
				perform_cy_kick(target)
			else
				perform_cy_shove(target)
			return TRUE
	if(cy_has_click_modifier(modifiers, SHIFT_CLICK))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			if(target == src)
				return TRUE // MouseUp decides between quick raise-head and held listening.
			if(ismob(target))
				toggle_cy_listen_mode(TRUE)
			else
				start_cy_look_at(target)
			return TRUE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && pulling == target && grab_state < GRAB_NECK)
		return perform_cy_grab_zone_special(target)
	if(cy_has_click_modifier(modifiers, ALT_CLICK))
		if(combat_mode)
			if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
				activate_selected_cy_daemon(target)
				return TRUE
			prepare_cy_combat_intent(target, modifiers)
			return FALSE
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			try_open_loot_panel_on(target)
			return TRUE
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			if(try_click_alt_secondary(target))
				return TRUE
			perform_cy_additional_secondary_action(target)
			return TRUE
		if(try_click_alt(target))
			return TRUE
		perform_cy_additional_primary_action(target)
		return TRUE
	if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
		activate_selected_cy_daemon(target)
		return TRUE
	if(!combat_mode && ismob(target) && pulling == target && !cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK) && !cy_has_click_modifier(modifiers, RIGHT_CLICK) && !cy_has_click_modifier(modifiers, MIDDLE_CLICK))
		return perform_cy_grab_palpation(target)
	prepare_cy_combat_intent(target, modifiers)
	return FALSE

/mob/living/proc/perform_cy_raise_head()
	if(next_move > world.time)
		return FALSE
	to_chat(src, span_notice("Вы поднимаете голову и осматриваетесь."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/perform_cy_look_down_hint(atom/target)
	if(next_move > world.time)
		return FALSE
	to_chat(src, span_notice("Вы пытаетесь посмотреть вниз."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/perform_cy_additional_primary_action(atom/target)
	if(!target)
		return FALSE
	to_chat(src, span_notice("Вы пробуете дополнительное действие с [target.declent_ru(INSTRUMENTAL)]."))
	apply_cy_action_delay(CLICK_CD_MELEE, null)
	return TRUE

/mob/living/proc/perform_cy_additional_secondary_action(atom/target)
	if(!target)
		return FALSE
	to_chat(src, span_notice("Вы пробуете вторичное дополнительное действие с [target.declent_ru(INSTRUMENTAL)]."))
	apply_cy_action_delay(CLICK_CD_MELEE, null)
	return TRUE

/mob/living/proc/perform_cy_grab_palpation(mob/living/target)
	if(!target || pulling != target || combat_mode || next_move > world.time)
		return FALSE
	if(!ishuman(target))
		to_chat(src, span_notice("You feel over [target], but learn nothing useful."))
		apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/professional/medicine)
		return TRUE
	var/mob/living/carbon/human/human_target = target
	visible_message(span_notice("[src] carefully checks [human_target] by touch."), span_notice("You palpate [human_target], checking for injuries."))
	var/medicine_level = get_cy_medicine_skill_level()
	var/list/diagnostic_lines = human_target.get_cy_diagnostic_lines(src, medicine_level >= CY_SKILL_LEVEL_EXPERT)
	for(var/line in diagnostic_lines)
		to_chat(src, span_notice("[line]"))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/professional/medicine)
	return TRUE

/mob/living/proc/activate_selected_cy_daemon(atom/target)
	if(next_move > world.time)
		return FALSE
	if(!target)
		return FALSE
	var/datum/cy_demon/demon = cy_prepared_demon
	if(!demon)
		to_chat(src, span_warning("Prepare a demon ability first."))
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = cy_prepared_demon_deck || cy_get_active_cyberdeck()
	if(!deck || QDELETED(deck) || cy_get_active_cyberdeck() != deck)
		to_chat(src, span_warning("You need the cyberdeck that prepared [demon.name]."))
		cy_clear_prepared_demon()
		return FALSE
	if(!(demon in deck.stored_demons))
		to_chat(src, span_warning("[demon.name] is no longer loaded in [deck]."))
		cy_clear_prepared_demon()
		return FALSE
	if(!cy_can_use_demon_on(target, demon))
		return FALSE
	if(!demon.start_cast(src, target, src))
		return FALSE
	cy_prepared_demon_action?.StartCooldown(demon.cooldown_time)
	cy_clear_prepared_demon()
	apply_cy_action_delay(CLICK_CD_CLICK_ABILITY, /datum/cy_skill/intelligence/fast_code)
	return TRUE


/mob/living/proc/get_cy_shove_target_turf(atom/movable/target, distance = 1)
	if(!target)
		return null
	var/turf/current_turf = get_turf(target)
	if(!current_turf)
		return null
	var/shove_dir = get_dir(src, target)
	if(!shove_dir)
		shove_dir = dir || SOUTH
	var/turf/next_turf = current_turf
	for(var/i in 1 to max(1, distance))
		var/turf/candidate = get_step(next_turf, shove_dir)
		if(!candidate || candidate.density)
			break
		next_turf = candidate
	return next_turf

/mob/living/proc/try_cy_shove_movable(atom/movable/target, distance = 1, kick = FALSE)
	if(!target || target == src || !Adjacent(target) || target.anchored)
		return FALSE
	var/turf/target_turf = get_cy_shove_target_turf(target, distance)
	if(!target_turf || target_turf == get_turf(target))
		return FALSE
	face_atom(target)
	var/move_dir = get_dir(get_turf(target), target_turf)
	if(!target.Move(target_turf, move_dir))
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] [kick ? "пинает" : "толкает"] [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы [kick ? "пинаете" : "толкаете"] [target.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/proc/perform_cy_shove(atom/target)
	if(next_move > world.time)
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(!Adjacent(living_target))
			return FALSE
		disarm(living_target, null)
		perform_cy_skill_check(/datum/cy_skill/strength/grappling, 25)
		if(has_cy_skill_perk_level(/datum/cy_skill/strength/grappling, 4))
			living_target.Knockdown(1 SECONDS + get_cy_skill_level(/datum/cy_skill/strength/grappling) * 0.25 SECONDS, daze_amount = 0.5 SECONDS)
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/grappling)
		return TRUE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		if(try_cy_shove_movable(movable_target, 1, FALSE))
			apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/grappling)
			return TRUE
	return FALSE

/mob/living/proc/perform_cy_kick(atom/target)
	if(next_move > world.time)
		return FALSE
	if(!target || !Adjacent(target))
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		face_atom(living_target)
		do_attack_animation(living_target, ATTACK_EFFECT_KICK)
		living_target.adjust_stamina_loss(CY_KICK_STAMINA_DAMAGE)
		if(living_target.body_position == LYING_DOWN)
			living_target.apply_damage(CY_KICK_PRONE_BRUTE_DAMAGE, BRUTE)
		else
			living_target.throw_at(get_cy_shove_target_turf(living_target, CY_KICK_SHOVE_DISTANCE), CY_KICK_SHOVE_DISTANCE, 1, src, force = MOVE_FORCE_OVERPOWERING)
		var/kick_knockdown_chance = 25 + get_cy_skill_level(/datum/cy_skill/dexterity/fast_melee) * 5
		if(has_cy_skill_perk_level(/datum/cy_skill/strength/power_melee, 3))
			kick_knockdown_chance += get_cy_skill_perk_value(/datum/cy_skill/strength/power_melee, 3, "value_1", 25) * 0.4
		if(prob(kick_knockdown_chance))
			living_target.Knockdown(CY_KICK_KNOCKDOWN_TIME)
		perform_cy_random_skill_check(list(
			/datum/cy_skill/strength/power_melee,
			/datum/cy_skill/dexterity/fast_melee,
			/datum/cy_skill/perception/precise_melee,
		), max(1, round(kick_knockdown_chance)))
		adjust_staggered_up_to(CY_KICK_SELF_STAGGER, 10 SECONDS)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пинает [living_target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы пинаете [living_target.declent_ru(ACCUSATIVE)]."))
		log_combat(src, living_target, "kicked")
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
		return TRUE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		if(try_cy_shove_movable(movable_target, CY_KICK_SHOVE_DISTANCE, TRUE))
			adjust_staggered_up_to(CY_KICK_SELF_STAGGER, 10 SECONDS)
			apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
			return TRUE
	return FALSE

/mob/living/proc/perform_cy_uppercut(atom/target)
	if(next_move > world.time || !isliving(target) || get_active_held_item())
		return FALSE
	var/mob/living/living_target = target
	if(!Adjacent(living_target) || !has_cy_skill_perk_level(/datum/cy_skill/strength/power_melee, 6))
		return FALSE
	face_atom(living_target)
	do_attack_animation(living_target, ATTACK_EFFECT_PUNCH)
	var/damage = 8 + get_cy_skill_level(/datum/cy_skill/strength/power_melee) * 2
	perform_cy_skill_check(/datum/cy_skill/strength/power_melee, max(1, damage))
	living_target.apply_damage(damage, BRUTE, BODY_ZONE_HEAD)
	living_target.adjust_stamina_loss(20 + get_cy_skill_level(/datum/cy_skill/strength/power_melee) * 5)
	living_target.Knockdown(3 SECONDS, daze_amount = 1.5 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] бьёт [living_target.declent_ru(ACCUSATIVE)] апперкотом!"), span_notice("Вы проводите апперкот по [living_target.declent_ru(DATIVE)]."))
	log_combat(src, living_target, "cyberpunk uppercut")
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/power_melee)
	return TRUE

/mob/living/proc/apply_cy_open_defense(duration = CY_DEFENSE_OPEN_TIME)
	cy_open_defense_until = max(cy_open_defense_until, world.time + duration)
	return TRUE

/mob/living/proc/clear_cy_active_defense(trigger_cooldown = TRUE)
	cy_active_defense_action = null
	cy_active_defense_until = 0
	if(trigger_cooldown)
		cy_next_defense_time = max(cy_next_defense_time, world.time + CY_DEFENSE_TRIGGERED_COOLDOWN)
	return TRUE

/mob/living/proc/get_cy_current_attack_intent()
	return cy_current_attack_intent

/mob/living/proc/get_cy_dodge_turf(atom/attacker)
	var/list/candidates = list()
	var/away_dir = attacker ? get_dir(attacker, src) : dir
	if(away_dir)
		candidates += get_step(src, away_dir)
		candidates += get_step(src, turn(away_dir, 90))
		candidates += get_step(src, turn(away_dir, -90))
	for(var/turf/candidate as anything in candidates)
		if(!candidate || candidate.density)
			continue
		var/blocked = FALSE
		for(var/atom/movable/movable_content as anything in candidate)
			if(movable_content.density)
				blocked = TRUE
				break
		if(!blocked)
			return candidate
	return null

/mob/living/proc/resolve_cy_active_defense(atom/hit_by, attack_type = MELEE_ATTACK)
	if(!has_active_cy_defense())
		return FAILED_BLOCK
	if(body_position == LYING_DOWN && prob(50))
		clear_cy_active_defense(TRUE)
		return FAILED_BLOCK
	var/mob/living/attacker = isliving(hit_by) ? hit_by : null
	var/attacker_intent = attacker?.get_cy_current_attack_intent()
	var/bypass_chance = 0
	if(attacker)
		bypass_chance = attacker.get_cy_weapon_defense_bypass_bonus(attacker.get_active_held_item())
	if(bypass_chance && prob(bypass_chance))
		clear_cy_active_defense(TRUE)
		return FAILED_BLOCK
	if(cy_active_defense_action == CY_DEFENSE_ACTION_DODGE)
		if(attacker_intent == CY_ATTACK_INTENT_TRICKY)
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		var/dodge_difficulty = attack_type == MELEE_ATTACK ? 45 : 70
		if(has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 3))
			dodge_difficulty -= get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 3, "value_1", 15)
		if(!perform_cy_skill_check(/datum/cy_skill/dexterity/evasion, max(1, dodge_difficulty)))
			var/failed_cost = 10
			if(has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 2))
				failed_cost *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 2, "value_2", 10) * 0.01)
			adjust_stamina_loss(failed_cost)
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		var/atom/dodge_source = attacker ? attacker : hit_by
		var/turf/dodge_turf = get_cy_dodge_turf(dodge_source)
		if(dodge_turf && !has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 5))
			Move(dodge_turf, get_dir(src, dodge_turf))
		var/success_cost = 10
		if(has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 2))
			success_cost *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 2, "value_1", 20) * 0.01)
		adjust_stamina_loss(success_cost)
		if(!has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 1) && prob(get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 1, "value_1", 10)))
			Knockdown(1 SECONDS)
		if(attacker && has_cy_skill_perk(/datum/cy_skill/dexterity/evasion, 6) && prob(get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 6, "value_1", 20)))
			attacker.apply_cy_open_defense(get_cy_skill_perk_value(/datum/cy_skill/dexterity/evasion, 6, "value_2", 1) SECONDS)
		attacker?.apply_cy_open_defense()
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] уходит от атаки."), span_notice("Вы уходите от атаки."))
		clear_cy_active_defense(TRUE)
		return SUCCESSFUL_BLOCK
	if(cy_active_defense_action == CY_DEFENSE_ACTION_PARRY)
		if(attacker_intent == CY_ATTACK_INTENT_PREEMPTIVE)
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		var/parry_difficulty = 45
		if(has_cy_skill_perk(/datum/cy_skill/perception/concentration, 2))
			parry_difficulty -= get_cy_skill_perk_value(/datum/cy_skill/perception/concentration, 2, "value_1", 15)
		if(!has_cy_skill_perk(/datum/cy_skill/perception/concentration, 1))
			parry_difficulty += get_cy_skill_perk_value(/datum/cy_skill/perception/concentration, 1, "value_1", 10)
		if(!perform_cy_skill_check(/datum/cy_skill/perception/concentration, max(1, parry_difficulty)))
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(has_cy_skill_perk(/datum/cy_skill/perception/concentration, 5))
			attacker?.apply_cy_open_defense(CY_DEFENSE_OPEN_TIME * 2)
		attacker?.apply_cy_open_defense()
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] парирует атаку."), span_notice("Вы парируете атаку."))
		clear_cy_active_defense(TRUE)
		return SUCCESSFUL_BLOCK
	return FAILED_BLOCK

/mob/living/proc/perform_cy_defense_action(defense_action = null, atom/target = null)
	if(cy_carrying_in_arms)
		to_chat(src, span_warning("Вы не можете защищаться, пока несёте кого-то на руках."))
		return FALSE
	if(next_move > world.time || world.time < cy_next_defense_time)
		return FALSE
	if(!defense_action)
		defense_action = cy_last_defense_action || CY_DEFENSE_ACTION_DODGE
	cy_last_defense_action = defense_action
	cy_active_defense_action = defense_action
	var/defense_skill = defense_action == CY_DEFENSE_ACTION_DODGE ? /datum/cy_skill/dexterity/evasion : /datum/cy_skill/perception/concentration
	perform_cy_skill_check(defense_skill, 25)
	var/skill_window_bonus = get_cy_skill_level(defense_skill) * 0.05 SECONDS
	if(body_position == LYING_DOWN)
		skill_window_bonus *= 0.5
	cy_active_defense_until = world.time + CY_DEFENSE_WINDOW + skill_window_bonus
	cy_next_defense_time = world.time + get_cy_action_delay(CY_DEFENSE_BASE_COOLDOWN, defense_skill)
	if(target)
		face_atom(target)
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] готовится к [defense_action == CY_DEFENSE_ACTION_PARRY ? "парированию" : "уклонению"]."), span_notice("Вы готовитесь к [defense_action == CY_DEFENSE_ACTION_PARRY ? "парированию" : "уклонению"]."))
	return TRUE

/mob/living/proc/has_active_cy_defense(defense_action = null)
	if(world.time > cy_active_defense_until)
		cy_active_defense_action = null
		return FALSE
	if(defense_action && cy_active_defense_action != defense_action)
		return FALSE
	return !!cy_active_defense_action


/mob/living/proc/start_cy_look_at(atom/target)
	if(!target || !client)
		return FALSE
	var/turf/source_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!source_turf || !target_turf)
		return FALSE
	var/range = CY_LOOK_BASE_RANGE + round(max(0, get_cy_stat(/datum/cy_stat/perception) - CY_STAT_DEFAULT) * CY_LOOK_RANGE_PER_PERCEPTION)
	var/dx = clamp(target_turf.x - source_turf.x, -range, range)
	var/dy = clamp(target_turf.y - source_turf.y, -range, range)
	QDEL_NULL(cy_look_holder)
	cy_look_holder = new(source_turf, src)
	set_cy_look_mode(TRUE)
	animate(client, pixel_x = dx * CY_LOOK_TILE_PIXEL_OFFSET, pixel_y = dy * CY_LOOK_TILE_PIXEL_OFFSET, time = CY_LOOK_CAMERA_RETURN_TIME)
	apply_cy_action_delay(CLICK_CD_LOOK_UP, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/end_cy_look_mode(smooth = TRUE)
	set_cy_look_mode(FALSE)
	if(!client)
		QDEL_NULL(cy_look_holder)
		return FALSE
	if(smooth)
		animate(client, pixel_x = 0, pixel_y = 0, time = CY_LOOK_CAMERA_RETURN_TIME)
		addtimer(CALLBACK(src, PROC_REF(finish_cy_look_mode)), CY_LOOK_CAMERA_RETURN_TIME)
		return TRUE
	finish_cy_look_mode()
	return TRUE

/mob/living/proc/finish_cy_look_mode()
	if(client)
		client.pixel_x = initial(client.pixel_x)
		client.pixel_y = initial(client.pixel_y)
	QDEL_NULL(cy_look_holder)
	return TRUE

/mob/living/proc/do_cy_sit()
	set_resting(TRUE)
	return TRUE


/mob/living/proc/is_cy_wall_press_surface(atom/target)
	if(!target || is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/movable_content as anything in target_turf)
			if(movable_content.density && (isstructure(movable_content) || isobj(movable_content)))
				return TRUE
		return FALSE
	return target.density || isstructure(target)

/mob/living/proc/clear_cy_wall_press(animate_offset = TRUE)
	if(!cy_wall_pressed)
		return FALSE
	cy_wall_pressed = FALSE
	cy_wall_press_dir = NONE
	remove_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, animate = animate_offset)
	update_cy_chameleon()
	return TRUE

/mob/living/proc/refresh_cy_wall_press_after_move()
	if(!cy_wall_pressed)
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf || !cy_wall_press_dir)
		return clear_cy_wall_press(TRUE)
	var/turf/wall_turf = get_step(current_turf, cy_wall_press_dir)
	if(!wall_turf || !Adjacent(wall_turf) || !is_cy_wall_press_surface(wall_turf))
		return clear_cy_wall_press(TRUE)
	return TRUE

/mob/living/proc/cy_press_to_wall(atom/target)
	if(!target)
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf || !Adjacent(target_turf))
		return FALSE
	if(is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_wall_turf = target
		if(!target_wall_turf.density)
			return FALSE
	else if(!target.density && !isstructure(target))
		return FALSE
	var/press_dir = get_dir(my_turf, target_turf)
	if(!press_dir)
		return FALSE
	clear_cy_hide_under()
	cy_wall_pressed = TRUE
	cy_wall_press_dir = press_dir
	var/x_offset = 0
	var/y_offset = 0
	if(press_dir & EAST)
		x_offset += CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & WEST)
		x_offset -= CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & NORTH)
		y_offset += CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & SOUTH)
		y_offset -= CY_STEALTH_WALL_PIXEL_OFFSET
	add_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, null, x_offset, y_offset, null, animate = FALSE)
	update_cy_chameleon()
	to_chat(src, span_notice("Вы вжимаетесь в укрытие."))
	return TRUE


/mob/living/proc/handle_cy_mouse_drop(atom/dropped, atom/over, list/modifiers)
	if(!dropped || !over || !islist(modifiers))
		return FALSE
	var/is_right = cy_has_click_modifier(modifiers, RIGHT_CLICK)
	var/is_middle = cy_has_click_modifier(modifiers, MIDDLE_CLICK)
	if(dropped == src && over == src)
		if(is_middle)
			return perform_cy_erp_self()
		if(is_right)
			to_chat(src, span_notice("Вы просите понести вас."))
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] просит понести [ru_p_them()]."), ignored_mobs = list(src))
			return TRUE
		return do_cy_sit()
	if(dropped == src && ismob(over))
		var/mob/living/carbon/human/carrier = null
		if(ishuman(over))
			carrier = over
		if(is_right)
			to_chat(src, span_notice("Вы просите [over.declent_ru(ACCUSATIVE)] понести вас."))
			to_chat(over, span_notice("[capitalize(declent_ru(NOMINATIVE))] просит вас понести [ru_p_them()]."))
			return TRUE
		if(carrier && carrier.pulling == src && carrier.grab_state >= GRAB_AGGRESSIVE)
			carrier.piggyback(src)
			return TRUE
	if(dropped == src && !ismob(over) && !(istype(over, /obj/vehicle/sealed/car)))
		if(is_cy_furniture_surface(over))
			if(cy_stealth_mode && body_position == LYING_DOWN)
				return perform_cy_hide_under(over)
			return FALSE
		return cy_press_to_wall(over)
	if(over == src && ismovable(dropped))
		var/atom/movable/movable_dropped = dropped
		if(is_middle)
			return FALSE
		if(is_right)
			if(ismob(dropped))
				to_chat(dropped, span_notice("[capitalize(declent_ru(NOMINATIVE))] предлагает вам взобраться на спину."))
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] предлагает понести [dropped.declent_ru(ACCUSATIVE)]."), span_notice("Вы предлагаете понести [dropped.declent_ru(ACCUSATIVE)]."))
			return TRUE
		if(ishuman(src) && iscarbon(dropped))
			var/mob/living/carbon/human/human_user = src
			var/mob/living/carbon/carbon_target = dropped
			if(carbon_target.body_position == LYING_DOWN && human_user.pulling == carbon_target && human_user.grab_state)
				if(human_user.grab_state >= GRAB_AGGRESSIVE)
					return human_user.cy_carry_in_arms(carbon_target)
				var/shoulder_result = human_user.fireman_carry(carbon_target)
				if(shoulder_result)
					human_user.cy_carrying_on_shoulder = TRUE
					human_user.add_movespeed_modifier(/datum/movespeed_modifier/cy_shoulder_carry)
				return TRUE
			return FALSE
		if(isliving(dropped))
			return FALSE
		start_pulling(movable_dropped)
		return TRUE
	if((istype(over, /obj/structure/bed) || istype(over, /obj/structure/chair)) && ismob(dropped))
		return FALSE // Let the existing buckle mouse-drop machinery handle it.
	if(combat_mode && ismob(dropped) && (istype(over, /obj/structure/table) || istype(over, /obj/structure/chair) || istype(over, /obj/structure/bed)))
		var/mob/living/living_dropped = dropped
		living_dropped.Knockdown(2 SECONDS)
		living_dropped.forceMove(get_turf(over))
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] швыряет [living_dropped.declent_ru(ACCUSATIVE)] на [over.declent_ru(ACCUSATIVE)]!"), span_notice("Вы швыряете [living_dropped.declent_ru(ACCUSATIVE)] на [over.declent_ru(ACCUSATIVE)]."))
		log_combat(src, living_dropped, "threw into furniture", "[over]")
		apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
		return TRUE
	return FALSE


/mob/living/proc/cy_carry_in_arms(mob/living/carbon/target)
	return FALSE


/mob/living/carbon/human/cy_carry_in_arms(mob/living/carbon/target)
	if(!istype(target) || target.body_position != LYING_DOWN || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		return FALSE
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] начинает брать [target.declent_ru(ACCUSATIVE)] на руки..."), span_notice("Вы начинаете брать [target.declent_ru(ACCUSATIVE)] на руки..."))
	if(!do_after(src, 7 SECONDS, target))
		visible_message(span_warning("[capitalize(declent_ru(DATIVE))] не удается взять [target.declent_ru(ACCUSATIVE)] на руки!"))
		return FALSE
	if(target.body_position != LYING_DOWN || target.buckled || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		visible_message(span_warning("[capitalize(declent_ru(DATIVE))] не удается взять [target.declent_ru(ACCUSATIVE)] на руки!"))
		return FALSE
	if(!buckle_mob(target, TRUE, TRUE, CARRIER_NEEDS_ARM))
		return FALSE
	cy_carrying_in_arms = TRUE
	add_movespeed_modifier(/datum/movespeed_modifier/cy_arms_carry)
	return TRUE

/mob/living/proc/clear_cy_carry_state()
	cy_carrying_in_arms = FALSE
	cy_carrying_on_shoulder = FALSE
	remove_movespeed_modifier(/datum/movespeed_modifier/cy_arms_carry)
	remove_movespeed_modifier(/datum/movespeed_modifier/cy_shoulder_carry)
	return TRUE

/mob/living/proc/perform_cy_erp_self()
	to_chat(src, span_notice("Вы пытаетесь начать личное взаимодействие."))
	return TRUE

/mob/living/ShiftMiddleClickOn(atom/A)
	if(A == src)
		return TRUE // MouseUp handles quick raise-head versus held listening.
	if(ismob(A))
		toggle_cy_listen_mode(TRUE)
		return TRUE
	start_cy_look_at(A)
	return TRUE

/mob/living/proc/get_cy_controlled_mob(mob/living/target)
	if(!target)
		return null
	if(pulling == target && grab_state)
		return target
	if(target in buckled_mobs)
		return target
	return null

/mob/living/proc/can_perform_cy_carry_combat_action(mob/living/target)
	if(!target || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		return FALSE
	if(get_cy_controlled_mob(target) != target)
		return FALSE
	return cy_carrying_in_arms || cy_carrying_on_shoulder


/mob/living/proc/perform_cy_neck_choke(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_NECK)
		return FALSE
	target.apply_damage(14, OXY, BODY_ZONE_HEAD)
	target.apply_damage(8, BRUTE, BODY_ZONE_HEAD)
	target.adjust_confusion(2 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] душит [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы душите [target.declent_ru(ACCUSATIVE)]."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_floor_slam(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	target.Knockdown(3 SECONDS)
	target.apply_damage(18, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] бьёт [target.declent_ru(ACCUSATIVE)] об пол!"), span_notice("Вы бьёте [target.declent_ru(ACCUSATIVE)] об пол."))
	if(prob(35))
		stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_back_slam(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	var/turf/back_turf = get_step(src, turn(dir, 180))
	if(back_turf && !back_turf.density)
		target.forceMove(back_turf)
	target.Knockdown(4 SECONDS)
	target.apply_damage(22, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] обрушивает [target.declent_ru(ACCUSATIVE)] за собой!"), span_notice("Вы обрушиваете [target.declent_ru(ACCUSATIVE)] за собой."))
	stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_knee_strike(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	target.Knockdown(4 SECONDS)
	target.apply_damage(28, BRUTE, BODY_ZONE_CHEST)
	target.adjust_confusion(3 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пытается переломить [target.declent_ru(ACCUSATIVE)] через колено!"), span_notice("Вы бьёте [target.declent_ru(ACCUSATIVE)] позвоночником о колено."))
	if(prob(60))
		stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_neck_knee_strike(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_NECK)
		return FALSE
	target.apply_damage(24, BRUTE, BODY_ZONE_CHEST)
	target.adjust_stamina_loss(35)
	target.adjust_confusion(3 SECONDS)
	target.Knockdown(3 SECONDS)
	adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] бьёт [target.declent_ru(ACCUSATIVE)] позвоночником о колено!"), span_notice("Вы бьёте [target.declent_ru(ACCUSATIVE)] позвоночником о колено."))
	if(prob(70))
		stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/is_cy_furniture_surface(atom/target)
	return istype(target, /obj/structure/bed) || istype(target, /obj/structure/chair) || istype(target, /obj/structure/table)

/mob/living/proc/perform_cy_hide_under(atom/target)
	if(!target || !is_cy_furniture_surface(target))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || !Adjacent(target_turf))
		return FALSE
	cy_hidden_under = target
	if(!cy_hidden_old_layer)
		cy_hidden_old_layer = layer
	forceMove(target_turf)
	layer = min(layer, target.layer - 0.01)
	to_chat(src, span_notice("Вы забираетесь под [target.declent_ru(ACCUSATIVE)]."))
	update_cy_chameleon()
	return TRUE

/mob/living/proc/clear_cy_hide_under()
	if(!cy_hidden_under)
		return FALSE
	cy_hidden_under = null
	if(cy_hidden_old_layer)
		layer = cy_hidden_old_layer
	cy_hidden_old_layer = null
	update_cy_chameleon()
	return TRUE

/mob/living/proc/perform_cy_grab_zone_special(mob/living/target)
	if(!target || pulling != target || grab_state >= GRAB_NECK)
		return FALSE
	var/selected_zone = zone_selected
	switch(selected_zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			target.Knockdown(4 SECONDS)
			target.apply_damage(14, BRUTE, selected_zone)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] подсекает [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы подсекаете [target.declent_ru(ACCUSATIVE)]."))
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			if(iscarbon(target))
				var/mob/living/carbon/carbon_target = target
				carbon_target.drop_all_held_items()
			target.apply_damage(12, BRUTE, selected_zone)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] заламывает руку [target.declent_ru(GENITIVE)]!"), span_notice("Вы заламываете руку [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_HEAD)
			target.apply_damage(15, BRUTE, BODY_ZONE_HEAD)
			target.adjust_confusion(3 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] сжимает голову [target.declent_ru(GENITIVE)]!"), span_notice("Вы сжимаете голову [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_PRECISE_EYES)
			if(iscarbon(target))
				var/mob/living/carbon/eye_target = target
				eye_target.adjust_temp_blindness_up_to(5 SECONDS, 10 SECONDS)
			target.apply_damage(6, BRUTE, BODY_ZONE_HEAD)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] тычет в глаза [target.declent_ru(GENITIVE)]!"), span_notice("Вы тычете в глаза [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_PRECISE_MOUTH)
			if(iscarbon(target))
				var/mob/living/carbon/mouth_target = target
				mouth_target.adjust_stutter(10 SECONDS)
			target.apply_damage(6, BRUTE, BODY_ZONE_HEAD)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] грубо дёргает рот [target.declent_ru(GENITIVE)]!"), span_notice("Вы причиняете боль рту [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_CHEST)
			if(target.body_position == LYING_DOWN)
				return cy_carry_in_arms(target)
			target.Knockdown(2 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пытается поднять [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы пытаетесь поднять [target.declent_ru(ACCUSATIVE)]."))
		else
			target.apply_damage(8, BRUTE, selected_zone)
			target.adjust_confusion(2 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] болезненно выкручивает [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы болезненно выкручиваете [target.declent_ru(ACCUSATIVE)]."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE


/mob/living/proc/is_cy_grabbing_arm_zone()
	return zone_selected in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)

/mob/living/proc/perform_cy_neck_back_throw(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_NECK)
		return FALSE
	var/turf/back_turf = get_step(src, turn(dir, 180))
	if(back_turf && !back_turf.density)
		target.forceMove(back_turf)
	target.Knockdown(4 SECONDS)
	Knockdown(2 SECONDS)
	target.apply_damage(20, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] перебрасывает [target.declent_ru(ACCUSATIVE)] себе за спину!"), span_notice("Вы перебрасываете [target.declent_ru(ACCUSATIVE)] себе за спину."))
	stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_wrestling_launch(atom/towards)
	var/mob/living/target = pulling
	if(!target || grab_state < GRAB_AGGRESSIVE || grab_state >= GRAB_NECK)
		return FALSE
	var/launch_dir = get_dir(src, towards)
	if(!launch_dir)
		launch_dir = dir
	if(!launch_dir)
		return FALSE
	stop_pulling()
	target.start_cy_wrestling_run(src, launch_dir)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] рывком запускает [target.declent_ru(ACCUSATIVE)] вперёд!"), span_notice("Вы запускаете [target.declent_ru(ACCUSATIVE)] вперёд."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/start_cy_wrestling_run(mob/living/launcher, launch_dir)
	if(!launch_dir)
		return FALSE
	cy_wrestling_running = TRUE
	cy_wrestling_launcher = launcher
	cy_wrestling_run_dir = launch_dir
	cy_wrestling_run_steps_left = CY_WRESTLING_RUN_DISTANCE
	cy_wrestling_rebounded = FALSE
	cy_wrestling_start_health = health
	setDir(launch_dir)
	addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), 0)
	return TRUE

/mob/living/proc/clear_cy_wrestling_run(knock_down = FALSE)
	cy_wrestling_running = FALSE
	cy_wrestling_launcher = null
	cy_wrestling_run_dir = NONE
	cy_wrestling_run_steps_left = 0
	cy_wrestling_rebounded = FALSE
	cy_wrestling_start_health = 0
	if(knock_down)
		Knockdown(CY_WRESTLING_RUN_KNOCKDOWN_TIME)
	return TRUE

/mob/living/proc/get_cy_wrestling_hard_obstacle(turf/target_turf)
	if(!target_turf)
		return null
	for(var/atom/movable/blocker as anything in target_turf)
		if(blocker == src || !blocker.density)
			continue
		if(istype(blocker, /obj/structure/table) || istype(blocker, /obj/machinery/vending))
			return blocker
	return null

/mob/living/proc/resolve_cy_wrestling_hard_obstacle(atom/movable/obstacle)
	if(!obstacle)
		return FALSE
	apply_damage(CY_WRESTLING_RUN_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] врезается в [obstacle.declent_ru(ACCUSATIVE)] и падает!"), span_warning("Вы врезаетесь в [obstacle.declent_ru(ACCUSATIVE)] и падаете!"))
	if(istype(obstacle, /obj/machinery/vending))
		var/obj/machinery/vending/vendor = obstacle
		if(!vendor.tilted && vendor.tiltable)
			vendor.tilt(src)
	clear_cy_wrestling_run(TRUE)
	return TRUE

/mob/living/proc/process_cy_wrestling_run_step()
	if(!cy_wrestling_running || stat == DEAD || cy_wrestling_run_steps_left <= 0)
		clear_cy_wrestling_run(FALSE)
		return FALSE
	var/turf/next_turf = get_step(src, cy_wrestling_run_dir)
	var/damaged_during_launch = health < cy_wrestling_start_health
	var/atom/movable/hard_obstacle = get_cy_wrestling_hard_obstacle(next_turf)
	if(hard_obstacle)
		return resolve_cy_wrestling_hard_obstacle(hard_obstacle)
	if(!next_turf || next_turf.density || !Move(next_turf, cy_wrestling_run_dir))
		if(!cy_wrestling_rebounded && !damaged_during_launch)
			cy_wrestling_rebounded = TRUE
			cy_wrestling_run_dir = turn(cy_wrestling_run_dir, 180)
			setDir(cy_wrestling_run_dir)
			cy_wrestling_run_steps_left = CY_WRESTLING_RUN_DISTANCE
			addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), CY_WRESTLING_RUN_STEP_DELAY)
			return TRUE
		apply_damage(CY_WRESTLING_RUN_DAMAGE, BRUTE, BODY_ZONE_CHEST)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] врезается в препятствие и падает!"), span_warning("Вы врезаетесь и падаете!"))
		clear_cy_wrestling_run(TRUE)
		return TRUE
	cy_wrestling_run_steps_left--
	addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), CY_WRESTLING_RUN_STEP_DELAY)
	return TRUE

/mob/living/proc/perform_cy_wrestling_elbow(mob/living/target)
	if(!target?.cy_wrestling_running || get_active_held_item())
		return FALSE
	target.apply_damage(CY_WRESTLING_RUN_ELBOW_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	if(prob(CY_WRESTLING_RUN_ELBOW_KNOCKDOWN_CHANCE))
		target.clear_cy_wrestling_run(TRUE)
	else
		target.cy_wrestling_start_health = target.health + 1 // mark as damaged so collision will not rebound.
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] встречает [target.declent_ru(ACCUSATIVE)] ударом локтя!"), span_notice("Вы встречаете [target.declent_ru(ACCUSATIVE)] ударом локтя."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
	return TRUE

/mob/living/proc/get_cy_grab_offhand(mob/living/target = null) as /obj/item/riding_offhand
	for(var/obj/item/riding_offhand/offhand in contents)
		if(offhand.parent != src)
			continue
		if(!offhand.rider)
			continue
		if(offhand.rider in buckled_mobs) // Existing fireman/piggyback carry, not a normal grab.
			continue
		if(target && offhand.rider != target)
			continue
		return offhand
	return null

/mob/living/proc/ensure_cy_grab_hand_item(mob/living/target)
	if(!istype(target) || pulling != target)
		return FALSE
	var/mob/living/carbon/carbon_target = target
	if(!istype(carbon_target))
		return FALSE
	var/obj/item/riding_offhand/existing_offhand = get_cy_grab_offhand(target)
	if(existing_offhand)
		existing_offhand.name = "захват [target.declent_ru(GENITIVE)]"
		existing_offhand.desc = "Эта рука удерживает [target.declent_ru(ACCUSATIVE)]. Пока захват активен, рука занята."
		return TRUE
	var/obj/item/riding_offhand/grab_offhand = new(src)
	grab_offhand.parent = src
	grab_offhand.rider = carbon_target
	grab_offhand.name = "захват [target.declent_ru(GENITIVE)]"
	grab_offhand.desc = "Эта рука удерживает [target.declent_ru(ACCUSATIVE)]. Пока захват активен, рука занята."
	var/inserted_successfully = FALSE
	if(put_in_active_hand(grab_offhand))
		inserted_successfully = TRUE
	else
		var/hand = get_empty_held_index_for_side(LEFT_HANDS) || get_empty_held_index_for_side(RIGHT_HANDS)
		if(hand && put_in_hand(grab_offhand, hand))
			inserted_successfully = TRUE
	if(!inserted_successfully)
		qdel(grab_offhand)
		to_chat(src, span_warning("Вам нужна свободная рука, чтобы удерживать захват."))
		return FALSE
	return TRUE

/mob/living/proc/clear_cy_grab_hand_item()
	var/cleared = FALSE
	for(var/obj/item/riding_offhand/offhand in contents)
		if(offhand.parent != src)
			continue
		if(!offhand.rider)
			continue
		if(offhand.rider in buckled_mobs) // Do not remove real carry/piggyback offhands here.
			continue
		qdel(offhand)
		cleared = TRUE
	return cleared
