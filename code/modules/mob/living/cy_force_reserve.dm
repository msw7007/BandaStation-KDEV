// CYBERPUNK 13 FORCE RESERVE START

/mob/living/proc/adjust_cy_force_reserve(amount)
	if(!cy_force_reserve_max)
		cy_force_reserve_max = CY_FORCE_RESERVE_MAX
	var/old_force_reserve = cy_force_reserve
	cy_force_reserve = clamp(cy_force_reserve + amount, 0, cy_force_reserve_max)
	return cy_force_reserve - old_force_reserve

/mob/living/proc/get_cy_force_reserve_recovery_amount(seconds_per_tick)
	if(stat == DEAD || cy_force_reserve >= cy_force_reserve_max)
		return 0

	var/recovery = 0
	if(cy_wall_pressed)
		recovery += CY_FORCE_RESERVE_WALL_RECOVERY
	if(resting || body_position == LYING_DOWN)
		recovery += CY_FORCE_RESERVE_LYING_RECOVERY
	if(is_cy_force_reserve_recovery_buckle())
		recovery += CY_FORCE_RESERVE_BUCKLED_RECOVERY
	if(IsSleeping())
		recovery += CY_FORCE_RESERVE_SLEEP_RECOVERY

	if(recovery <= 0)
		return 0
	return recovery * seconds_per_tick

/mob/living/proc/is_cy_force_reserve_recovery_buckle()
	if(!buckled)
		return FALSE
	return istype(buckled, /obj/structure/bed) || istype(buckled, /obj/structure/chair)

/mob/living/proc/process_cy_force_reserve(seconds_per_tick)
	var/recovery_amount = get_cy_force_reserve_recovery_amount(seconds_per_tick)
	if(recovery_amount <= 0)
		return FALSE
	adjust_cy_force_reserve(recovery_amount)
	return TRUE

/mob/living/proc/queue_cy_stamina_recovery(delay = CY_STAMINA_ACTIVE_REGEN_DELAY)
	if(cy_stamina_recovery_queued || QDELETED(src) || stat == DEAD)
		return FALSE
	cy_stamina_recovery_queued = TRUE
	addtimer(CALLBACK(src, PROC_REF(try_cy_active_stamina_recovery)), delay)
	return TRUE

/mob/living/proc/try_cy_active_stamina_recovery()
	cy_stamina_recovery_queued = FALSE
	if(QDELETED(src) || stat == DEAD)
		return FALSE
	if(staminaloss <= 0)
		return FALSE

	var/time_until_recovery = (cy_last_stamina_spent_time + CY_STAMINA_ACTIVE_REGEN_DELAY) - world.time
	if(time_until_recovery > 0)
		return queue_cy_stamina_recovery(time_until_recovery)

	var/recovery_amount
	if(cy_force_reserve > 0)
		recovery_amount = max_stamina * CY_STAMINA_FORCE_REGEN_FRACTION
		var/force_cost = cy_force_reserve_max * CY_STAMINA_FORCE_REGEN_COST_FRACTION
		adjust_cy_force_reserve(-force_cost)
	else
		recovery_amount = max_stamina * CY_STAMINA_EXHAUSTED_REGEN_FRACTION

	adjust_stamina_loss(-recovery_amount, updating_stamina = TRUE, forced = TRUE)
	if(staminaloss > 0)
		queue_cy_stamina_recovery(CY_STAMINA_ACTIVE_REGEN_INTERVAL)
	return TRUE

// CYBERPUNK 13 FORCE RESERVE END
