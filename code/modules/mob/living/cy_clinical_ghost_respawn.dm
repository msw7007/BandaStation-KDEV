/mob/living/proc/on_cy_enter_clinical_death()
	if(mind)
		mind.degrade_cy_memories_on_death(src)
	return TRUE

/mob/living/carbon/human/proc/process_cy_clinical_death(seconds_per_tick)
	if(!clinical_death_started_at || stat == DEAD)
		return FALSE
	var/organ_damage = CY_CLINICAL_ORGAN_DAMAGE_PER_SECOND * seconds_per_tick
	for(var/organ_slot in list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH, ORGAN_SLOT_BRAIN))
		adjust_organ_loss(organ_slot, organ_damage)
	return TRUE

/mob/living/proc/is_cy_critical()
	return health <= critical_health_threshold && stat != DEAD

/mob/living/proc/is_cy_clinically_dead()
	return health <= clinical_death_threshold && stat != DEAD

/mob/living/proc/is_cy_brain_dead()
	return brain_dead

/mob/living/carbon/human/proc/can_cy_revive()
	if(brain_dead)
		return FALSE
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	return heart && !(heart.organ_flags & ORGAN_FAILING)

/mob/living/carbon/human/proc/create_cy_ghost_shell()
	var/mob/dead/observer/ghost = ghostize(FALSE)
	if(!ghost)
		return null
	ghost.name = name
	ghost.real_name = real_name
	ghost.appearance = appearance
	ghost.cy_original_body = src
	return ghost

/mob/dead/observer/proc/cy_weak_interact(atom/target)
	if(!target || world.time < next_move)
		return FALSE
	visible_message(span_notice("[src] leaves a faint, cold disturbance near [target]."))
	changeNext_move(5 SECONDS)
	return TRUE

/mob/living/carbon/human/proc/get_cy_clone_respawn_delay()
	var/delay = 10 MINUTES
	if(mind?.assigned_role)
		delay = 5 MINUTES
	return delay

/mob/living/carbon/human/proc/is_cy_body_abandoned()
	if(stat != DEAD && !is_cy_clinically_dead())
		return FALSE
	for(var/mob/living/viewer in viewers(7, src))
		if(viewer.client)
			return FALSE
	if(!cy_body_abandoned_at)
		cy_body_abandoned_at = world.time
	return world.time - cy_body_abandoned_at >= get_cy_clone_respawn_delay() * 2

/mob/living/carbon/human/proc/on_cy_body_abandoned()
	if(!is_cy_body_abandoned())
		return FALSE
	if(cy_abandoned_body_rescue_attempted)
		return FALSE
	cy_abandoned_body_rescue_attempted = TRUE
	visible_message(span_warning("An emergency rescue contract pings for [src]."))
	cy_leave_forensic_trace(src, "abandoned body rescue", 60)
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_RESCUE, 5, src)
	if(can_cy_revive())
		heal_and_revive(max(25, round(maxHealth * 0.35)), "Emergency rescue contractors stabilize you.")
		clinical_death_started_at = null
		return TRUE
	return TRUE

/mob/dead/observer
	var/mob/living/cy_original_body
