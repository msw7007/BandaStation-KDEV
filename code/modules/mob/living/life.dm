/// This divisor controls how fast body temperature changes to match the environment
#define BODYTEMP_DIVISOR 16

/**
 * Handles the biological and general over-time processes of the mob.
 *
 *
 * Arguments:
 * - seconds_per_tick: The amount of time that has elapsed since this last fired.
 * - times_fired: The number of times SSmobs has fired
 */
/mob/living/proc/Life(seconds_per_tick = SSMOBS_DT)
	set waitfor = FALSE
	SHOULD_NOT_SLEEP(TRUE)

	var/signal_result = SEND_SIGNAL(src, COMSIG_LIVING_LIFE, seconds_per_tick)

	if(signal_result & COMPONENT_LIVING_CANCEL_LIFE_PROCESSING) // mmm less work
		return

	if (client)
		var/turf/T = get_turf(src)
		if(!T)
			move_to_error_room()
			var/msg = " was found to have no .loc with an attached client, if the cause is unknown it would be wise to ask how this was accomplished."
			message_admins(ADMIN_LOOKUPFLW(src) + msg)
			send2tgs_adminless_only("Mob", key_name_and_tag(src) + msg, R_ADMIN)
			src.log_message("was found to have no .loc with an attached client.", LOG_GAME)

		// This is a temporary error tracker to make sure we've caught everything
		else if (registered_z != T.z)
#ifdef TESTING
			message_admins("[ADMIN_LOOKUPFLW(src)] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z]. If you could ask them how that happened and notify coderbus, it would be appreciated.")
#endif
			log_game("Z-TRACKING: [src] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z].")
			update_z(T.z)
	else if (registered_z)
		log_game("Z-TRACKING: [src] of type [src.type] has a Z-registration despite not having a client.")
		update_z(null)

	if(isnull(loc) || HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(!HAS_TRAIT(src, TRAIT_STASIS))
		if(stat != DEAD)
			//Mutations and radiation
			handle_mutations(seconds_per_tick)
			//Breathing, if applicable
			handle_breathing(seconds_per_tick)
			handle_body_state(seconds_per_tick)
			handle_ssd(seconds_per_tick) // BANDASTATION ADD - SSD INDICATOR

		handle_diseases(seconds_per_tick) // DEAD check is in the proc itself; we want it to spread even if the mob is dead, but to handle its disease-y properties only if you're not.

		if (QDELETED(src)) // Diseases can qdel the mob via transformations
			return

		// Handle temperature/pressure differences between body and environment
		var/datum/gas_mixture/environment = loc.return_air()
		if(environment)
			handle_environment(environment, seconds_per_tick)

		handle_gravity(seconds_per_tick)

	if(living_flags & QUEUE_NUTRITION_UPDATE)
		update_nutrition()
		living_flags &= ~QUEUE_NUTRITION_UPDATE

	if (living_flags & BLOOD_UPDATE_QUEUED)
		update_blood_effects()

	if(stat != DEAD)
		return TRUE

/mob/living/proc/handle_breathing(seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_LIVING_HANDLE_BREATHING, seconds_per_tick)
	return

/mob/living/proc/handle_mutations(seconds_per_tick)
	return

/mob/living/proc/handle_diseases(seconds_per_tick)
	return

/mob/living/proc/handle_body_state(seconds_per_tick)
	drain_needs(seconds_per_tick)
	recover_stamina(seconds_per_tick)
	recover_energy_pool(seconds_per_tick)
	recover_tireness(seconds_per_tick)
	process_mood_state(seconds_per_tick)
	apply_body_state_effects()

/mob/living/get_status_tab_items()
	. = ..()
	. += ""
	. += "Body State"
	. += "Stamina: [round(stamina, 0.1)]/[round(max_stamina, 0.1)]"
	. += "Energy Pool: [round(energy_pool, 0.1)]/[round(max_energy_pool, 0.1)]"
	. += "Satiation: [round(satiety, 0.1)]/[MAX_SATIETY]"
	. += "Hydration: [round(hydration, 0.1)]/[MAX_SATIETY]"
	. += "Tireness: [round(tireness, 0.1)]/[MAX_SATIETY]"
	. += "Chrome Load: [round(chrome_load, 0.1)]/[round(chromity, 0.1)]"
	. += "Style: [round(style, 0.1)]/15"
	. += "Mood: [round(mood, 0.1)]/20"
	. += "Corp Align: [corp_align || "None"]"
	. += "Memory Holder: [length(memory_holder)] entries"

/mob/living/proc/drain_needs(seconds_per_tick)
	if(!HAS_TRAIT(src, TRAIT_NOHUNGER))
		satiation_drain_accumulator += seconds_per_tick
		while(satiation_drain_accumulator >= 20)
			satiation_drain_accumulator -= 20
			adjust_satiation(-1)
	else
		satiation_drain_accumulator = 0

	hydration_drain_accumulator += seconds_per_tick
	while(hydration_drain_accumulator >= 10)
		hydration_drain_accumulator -= 10
		adjust_hydration(-1)

	tireness_drain_accumulator += seconds_per_tick
	while(tireness_drain_accumulator >= 15)
		tireness_drain_accumulator -= 15
		adjust_tireness(-1)

	if(has_sleep_deprivation())
		sleep_deprivation_energy_drain_accumulator += seconds_per_tick
		while(sleep_deprivation_energy_drain_accumulator >= 60)
			sleep_deprivation_energy_drain_accumulator -= 60
			adjust_energy_pool(-2)
	else
		sleep_deprivation_energy_drain_accumulator = 0

	if(tireness <= 0 && !combat_mode && world.time >= tireness_sleep_grace_until && !IsSleeping() && !IsUnconscious())
		SetSleeping(30 SECONDS)

/mob/living/proc/recover_stamina(seconds_per_tick)
	if(stamina >= max_stamina || is_exhausted_by_needs())
		stamina_regen_accumulator = 0
		return
	if(world.time < last_stamina_spend + 10 SECONDS)
		stamina_regen_accumulator = 0
		return

	stamina_regen_accumulator += seconds_per_tick
	while(stamina_regen_accumulator >= 5)
		stamina_regen_accumulator -= 5
		var/recovery = 5
		if(buckled || resting)
			recovery += 5
		if(body_position == LYING_DOWN && (IsSleeping() || IsUnconscious()))
			recovery += 10
		if(stamina < max_stamina && energy_pool >= 2)
			adjust_energy_pool(-2)
			recovery += 15
		adjust_stamina(recovery, FALSE)

/mob/living/proc/recover_energy_pool(seconds_per_tick)
	if(energy_pool >= max_energy_pool || has_sleepiness() || has_strong_hunger() || has_strong_thirst())
		energy_regen_accumulator = 0
		return

	var/recovery = get_energy_pool_recovery()
	if(recovery <= 0)
		energy_regen_accumulator = 0
		return

	energy_regen_accumulator += seconds_per_tick
	while(energy_regen_accumulator >= 10)
		energy_regen_accumulator -= 10
		adjust_energy_pool(recovery)

/mob/living/proc/recover_tireness(seconds_per_tick)
	if(tireness >= MAX_SATIETY || body_position != LYING_DOWN || (!IsSleeping() && !IsUnconscious()))
		tireness_recovery_accumulator = 0
		return

	tireness_recovery_accumulator += seconds_per_tick
	while(tireness_recovery_accumulator >= 5)
		tireness_recovery_accumulator -= 5
		var/recovery = 10
		if(istype(buckled, /obj/structure/bed))
			recovery += 10
			if(locate(/obj/item/pillow) in loc)
				recovery += 20
			if(locate(/obj/item/bedsheet) in loc)
				recovery += 10
		if(!has_hunger() && !has_overeating())
			recovery += 20
		if(!has_thirst() && !has_overdrinking())
			recovery += 10
		adjust_tireness(recovery)

/mob/living/proc/process_mood_state(seconds_per_tick)
	sync_mood_from_moodlets()
	mood = clamp(mood, -30, 20)
	if(mood <= -30)
		time_at_min_mood += seconds_per_tick
		if(time_at_min_mood >= 10 MINUTES && world.time >= last_control_loss + 30 SECONDS)
			trigger_hysteria()

/mob/living/proc/sync_mood_from_moodlets()
	if(!QDELETED(mob_mood))
		mood = clamp(mob_mood.mood, -30, 20)
	return mood

/mob/living/proc/apply_body_state_effects()
	var/stamina_ratio = max_stamina ? stamina / max_stamina : 0
	var/move_slowdown = 0
	var/action_slowdown = 0

	if(stamina <= 0)
		move_slowdown = max(move_slowdown, 0.2)
		action_slowdown = max(action_slowdown, 0.2)
	else if(stamina_ratio <= 0.1)
		move_slowdown = max(move_slowdown, 0.2)
		action_slowdown = max(action_slowdown, 0.2)
	else if(stamina_ratio <= 0.5)
		move_slowdown = max(move_slowdown, 0.1)
		action_slowdown = max(action_slowdown, 0.1)

	if(has_dehydration())
		move_slowdown = max(move_slowdown, 0.2)
	if(tireness > 450)
		move_slowdown -= 0.1

	if(mood > 0)
		action_slowdown -= 0.1 * (mood / 20)
	else if(mood < 0)
		action_slowdown += 0.5 * (abs(mood) / 30)

	if(move_slowdown)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/body_state, multiplicative_slowdown = move_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/body_state)

	if(action_slowdown)
		add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/body_state, multiplicative_slowdown = action_slowdown)
	else
		remove_actionspeed_modifier(/datum/actionspeed_modifier/body_state)

	if(stamina <= 0 && energy_pool <= 0)
		Stun(10 SECONDS)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, BODY_STATE_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, BODY_STATE_TRAIT)

/mob/living/proc/spend_stamina(amount, source, allow_negative = FALSE)
	if(amount <= 0)
		return TRUE
	if(!allow_negative && stamina < amount)
		return FALSE
	adjust_stamina(-amount, TRUE)
	return TRUE

/mob/living/proc/adjust_stamina(amount, counts_as_spend = FALSE)
	var/old_value = stamina
	stamina = clamp(stamina + amount, 0, max_stamina)
	if(counts_as_spend && stamina < old_value)
		last_stamina_spend = world.time
		stamina_regen_accumulator = 0
	update_stamina_hud()
	apply_body_state_effects()
	return stamina - old_value

/mob/living/proc/adjust_energy_pool(amount)
	var/old_value = energy_pool
	energy_pool = clamp(energy_pool + amount, 0, max_energy_pool)
	return energy_pool - old_value

/mob/living/proc/adjust_satiation(amount)
	var/old_value = satiety
	satiety = clamp(satiety + amount, 0, MAX_SATIETY)
	return satiety - old_value

/mob/living/proc/adjust_hydration(amount)
	var/old_value = hydration
	hydration = clamp(hydration + amount, 0, MAX_SATIETY)
	return hydration - old_value

/mob/living/proc/adjust_tireness(amount)
	var/old_value = tireness
	tireness = clamp(tireness + amount, 0, MAX_SATIETY)
	return tireness - old_value

/mob/living/proc/adjust_mood(amount)
	var/old_value = mood
	mood = clamp(mood + amount, -30, 20)
	apply_body_state_effects()
	return mood - old_value

/mob/living/proc/get_energy_pool_recovery()
	if(body_position == LYING_DOWN)
		var/recovery = 2
		if(istype(buckled, /obj/structure/bed))
			recovery += 2
			if(locate(/obj/item/pillow) in loc)
				recovery += 2
			if(locate(/obj/item/bedsheet) in loc)
				recovery += 2
			if(!has_hunger())
				recovery += 2
		return recovery
	if(resting || buckled)
		return 2
	return 0

/mob/living/proc/get_check_penalty()
	if(stamina <= 0)
		return 0.2
	if(stamina <= max_stamina * 0.1)
		return 0.1
	if(stamina <= max_stamina * 0.5)
		return 0.05
	return 0

/mob/living/proc/get_experience_multiplier()
	return 1 + max(0, style) / 15 * 0.5 + max(0, mood) / 20 * 0.5

/mob/living/proc/can_dodge()
	return stamina > max_stamina * 0.1 && stamina >= STAMINA_COST_DODGE

/mob/living/proc/can_parry()
	return stamina > max_stamina * 0.1 && stamina >= STAMINA_COST_PARRY

/mob/living/proc/can_jump()
	return stamina > max_stamina * 0.1 && stamina >= STAMINA_COST_JUMP

/mob/living/proc/can_run()
	return stamina > max_stamina * 0.1 && stamina >= STAMINA_COST_RUN_TILE

/mob/living/proc/is_exhausted_by_needs()
	return has_starvation_exhaustion() || has_dehydration()

/mob/living/proc/has_hunger()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 200

/mob/living/proc/has_overeating()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety > 450

/mob/living/proc/has_strong_hunger()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 130

/mob/living/proc/has_starvation_exhaustion()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 80

/mob/living/proc/has_thirst()
	return hydration < 180

/mob/living/proc/has_overdrinking()
	return hydration > 450

/mob/living/proc/has_strong_thirst()
	return hydration < 100

/mob/living/proc/has_dehydration()
	return hydration < 20

/mob/living/proc/has_sleepiness()
	return tireness < 200

/mob/living/proc/has_sleep_deprivation()
	return tireness < 50

/mob/living/proc/trigger_hysteria()
	last_control_loss = world.time
	time_at_min_mood = 0
	visible_message(span_warning("[src] loses control!"), span_userdanger("You lose control of yourself."))
	Stun(30 SECONDS)

// Base mob environment handler for body temperature
/mob/living/proc/handle_environment(datum/gas_mixture/environment, seconds_per_tick)
	var/loc_temp = get_temperature(environment)
	var/temp_delta = loc_temp - bodytemperature

	if(ismovable(loc))
		var/atom/movable/occupied_space = loc
		temp_delta *= (1 - occupied_space.contents_thermal_insulation)

	if(temp_delta < 0) // it is cold here
		if(!on_fire) // do not reduce body temp when on fire
			adjust_bodytemperature(max(max(temp_delta / BODYTEMP_DIVISOR, BODYTEMP_COOLING_MAX) * seconds_per_tick, temp_delta))
	else // this is a hot place
		adjust_bodytemperature(min(min(temp_delta / BODYTEMP_DIVISOR, BODYTEMP_HEATING_MAX) * seconds_per_tick, temp_delta))

/**
 * Get the fullness of the mob
 *
 * Fullness is a representation of how much nutrition the mob has,
 * including the nutrition of stuff yet to be digested (reagents in blood / stomach)
 *
 * * only_consumable - if TRUE, only consumable reagents are counted.
 * Otherwise, all reagents contribute to fullness, despite not adding nutrition as they process.
 *
 * Returns a number representing fullness, scaled similarly to nutrition.
 */
/mob/living/proc/get_fullness(only_consumable)
	var/fullness = nutrition
	// we add the nutrition value of what we're currently digesting
	for(var/datum/reagent/consumable/bits in reagents.reagent_list)
		fullness += bits.get_nutriment_factor(src) * bits.volume / bits.metabolization_rate
	return fullness

/**
 * Check if the mob contains this reagent.
 *
 * This will validate the the reagent holder for the mob and any sub holders contain the requested reagent.
 * Vars:
 * * reagent (typepath) takes a PATH to a reagent.
 * * amount (int) checks for having a specific amount of that chemical.
 * * needs_metabolizing (bool) takes into consideration if the chemical is matabolizing when it's checked.
 */
/mob/living/proc/has_reagent(reagent, amount = -1, needs_metabolizing = FALSE)
	return reagents?.has_reagent(reagent, amount, needs_metabolizing)

/mob/living/proc/update_damage_hud()
	return

/mob/living/proc/handle_gravity(seconds_per_tick)
	if(gravity_state > STANDARD_GRAVITY)
		handle_high_gravity(gravity_state, seconds_per_tick)

/mob/living/proc/gravity_animate()
	if(!get_filter("gravity"))
		add_filter("gravity",1,list("type"="motion_blur", "x"=0, "y"=0))
	animate(get_filter("gravity"), y = 1, time = 10, loop = -1)
	animate(y = 0, time = 10)

/mob/living/proc/handle_high_gravity(gravity, seconds_per_tick)
	if(gravity < GRAVITY_DAMAGE_THRESHOLD) //Aka gravity values of 3 or more
		return

	var/grav_strength = gravity - GRAVITY_DAMAGE_THRESHOLD
	adjust_brute_loss(min(GRAVITY_DAMAGE_SCALING * grav_strength, GRAVITY_DAMAGE_MAXIMUM) * seconds_per_tick)

/// Proc used for custom metabolization of reagents, if any
/mob/living/proc/reagent_tick(datum/reagent/chem, seconds_per_tick)
	SHOULD_CALL_PARENT(TRUE)
	return SEND_SIGNAL(src, COMSIG_MOB_REAGENT_TICK, chem, seconds_per_tick)

/// Proc used for custom reagent exposure effects, if any
/mob/living/proc/reagent_expose(datum/reagent/chem, methods = TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	return

#undef BODYTEMP_DIVISOR
