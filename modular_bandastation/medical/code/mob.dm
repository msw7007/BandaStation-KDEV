/mob/living
	/// CPR: cooldown timestamp (when CPR can be performed without being "early")
	var/next_cpr_time = 0

	/// CPR: early-use stacks (only used when performer has NO doctor chip)
	var/cpr_early_counter = 0
	var/cpr_early_decay_at = 0

	/// CPR: auto-cycle state (only available with doctor chip)
	var/cpr_auto_running = FALSE
	var/datum/weakref/cpr_auto_target_ref

	/// CPR: organ preservation window on the patient
	var/cpr_preserve_until = 0
	var/datum/weakref/cpr_preserve_owner_ref

/// Checks if CPR is allowed on the given target under the new rules
/mob/living/proc/can_perform_cpr_on(mob/living/carbon/target)
	if(!target || target == src)
		return FALSE

	// Alive: allowed if OxyLoss > 0 OR health < 0
	if(target.stat != DEAD)
		if(target.get_oxy_loss() > 0)
			return TRUE
		if(target.health < 0)
			return TRUE
		return FALSE

	// Dead: allowed for organ preservation window
	return TRUE

/// Increments early-use stacks and resets decay timer (no-chip only)
/mob/living/proc/cpr_note_early_use()
	cpr_early_counter++
	cpr_reset_early_decay()

/// Schedules decay of early-use stacks (one stack per CPR_EARLY_DECAY_STEP)
/mob/living/proc/cpr_reset_early_decay()
	cpr_early_decay_at = world.time + CPR_EARLY_DECAY_STEP
	addtimer(CALLBACK(src, PROC_REF(cpr_try_decay_early_counter)), CPR_EARLY_DECAY_STEP, TIMER_UNIQUE)

/// Decays early-use stacks if the decay timer has elapsed
/mob/living/proc/cpr_try_decay_early_counter()
	if(world.time < cpr_early_decay_at)
		return
	if(cpr_early_counter > 0)
		cpr_early_counter--
	if(cpr_early_counter > 0)
		cpr_reset_early_decay()

/// Applies organ preservation window to the target using "first CPR wins" rule (does not extend an active window)
/mob/living/proc/cpr_apply_preserve_window(mob/living/target, has_chip)
	var/add_time = has_chip ? CPR_ORGAN_PRESERVE_CHIP : CPR_ORGAN_PRESERVE_BASE

	// First-rule: if active, do not extend or overwrite
	if(world.time < target.cpr_preserve_until)
		return

	target.cpr_preserve_until = world.time + add_time
	target.cpr_preserve_owner_ref = WEAKREF(src)

/// Toggles/retargets the auto-CPR cycle (doctor chip only)
/mob/living/proc/toggle_auto_cpr(mob/living/carbon/target)
	if(!HAS_DOCTOR_CHIP(src))
		return FALSE

	if(cpr_auto_running)
		var/mob/living/carbon/current = cpr_auto_target_ref?.resolve()
		if(current == target)
			cpr_auto_running = FALSE
			cpr_auto_target_ref = null
			return TRUE
		cpr_auto_target_ref = WEAKREF(target)
		return TRUE

	// Start
	cpr_auto_running = TRUE
	cpr_auto_target_ref = WEAKREF(target)
	addtimer(CALLBACK(src, PROC_REF(auto_cpr_tick)), 2 SECONDS, TIMER_UNIQUE)
	return TRUE

/// Auto-CPR loop tick: performs single CPR iteration and schedules next tick (doctor chip only)
/mob/living/proc/auto_cpr_tick()
	if(!cpr_auto_running)
		return

	var/mob/living/carbon/target = cpr_auto_target_ref?.resolve()
	if(!target || QDELETED(target))
		cpr_auto_running = FALSE
		cpr_auto_target_ref = null
		return

	if(!can_perform_cpr_on(target))
		cpr_auto_running = FALSE
		cpr_auto_target_ref = null
		return

	if(get_dist(src, target) > 1)
		cpr_auto_running = FALSE
		cpr_auto_target_ref = null
		return

	do_cpr_once(target)
	addtimer(CALLBACK(src, PROC_REF(auto_cpr_tick)), 2 SECONDS, TIMER_UNIQUE)

/// Applies a chest bone wound ("rib fracture") directly, without dealing damage
/mob/living/carbon/proc/try_apply_cpr_rib_fracture(mob/living/user, stacks)
	var/obj/item/bodypart/chest = get_bodypart(BODY_ZONE_CHEST)
	if(!chest || !chest.is_woundable())
		return FALSE

	var/datum/wound/blunt/bone/existing
	for(var/datum/wound/W as anything in chest.wounds)
		if(istype(W, /datum/wound/blunt/bone))
			existing = W
			break

	var/target_severity = (stacks >= 3) ? WOUND_SEVERITY_CRITICAL : WOUND_SEVERITY_SEVERE
	if(existing && existing.severity >= target_severity)
		return FALSE

	var/type_to_apply = (target_severity == WOUND_SEVERITY_CRITICAL) ? /datum/wound/blunt/bone/critical : /datum/wound/blunt/bone/severe
	var/datum/wound/blunt/bone/new_wound = new type_to_apply

	if(existing)
		existing.wound_source = "CPR compressions"
		existing.replace_wound(new_wound)
	else
		new_wound.apply_wound(chest, silent = FALSE, wound_source = "CPR compressions")

	if(!HAS_TRAIT(src, TRAIT_ANALGESIA))
		to_chat(src, span_userdanger("Компрессии прошли слишком резко — в груди хрустнуло от боли!"))
	if(user)
		to_chat(user, span_warning("Вы чувствуете, как грудная клетка [src.declent_ru(GENITIVE)] неприятно поддается под компрессиями."))

	return TRUE

/// Public CPR entrypoint: performs one CPR iteration, and starts auto-cycle if chip is present
/mob/living/carbon/human/do_cpr(mob/living/carbon/target)
	return do_cpr_internal(target, allow_auto_toggle = TRUE)

/// Internal single CPR iteration used by auto-cycle (does not toggle auto-cycle again)
/mob/living/proc/do_cpr_once(mob/living/carbon/target)
	return do_cpr_internal(target, allow_auto_toggle = FALSE)

/// Shared CPR implementation used by both manual and auto-cycle paths
/mob/living/proc/do_cpr_internal(mob/living/carbon/target, allow_auto_toggle = TRUE)
	if(!can_perform_cpr_on(target))
		return FALSE

	CHECK_DNA_AND_SPECIES(target)

	if(DOING_INTERACTION_WITH_TARGET(src, target))
		return FALSE

	if(is_mouth_covered())
		balloon_alert(src, "снимите свою маску!")
		return FALSE

	if(target.is_mouth_covered())
		balloon_alert(src, "снимите [target.p_their()] маску!")
		return FALSE

	if(HAS_TRAIT_FROM(src, TRAIT_NOBREATH, DISEASE_TRAIT))
		to_chat(src, span_warning("вы не дышите!"))
		return FALSE

	var/obj/item/organ/lungs/human_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(isnull(human_lungs))
		balloon_alert(src, "у вас нет легких!")
		return FALSE
	if(human_lungs.organ_flags & ORGAN_FAILING)
		balloon_alert(src, "ваши легкие слишком повреждены!")
		return FALSE

	var/has_chip = HAS_DOCTOR_CHIP(src)

	// Early CPR (before cooldown): stacks only apply without chip
	var/cooldown = has_chip ? CPR_COOLDOWN_CHIP : CPR_COOLDOWN_BASE
	var/early_use = (world.time < next_cpr_time)

	if(early_use && !has_chip)
		cpr_note_early_use()
	else if(!has_chip)
		cpr_reset_early_decay()

	next_cpr_time = world.time + cooldown

	visible_message(
		span_notice("[src] пытается сделать СЛР [target.declent_ru(DATIVE)]!"),
		span_notice("Вы пытаетесь сделать СЛР [target.declent_ru(DATIVE)]... не двигайтесь!")
	)

	var/action_time = has_chip ? CPR_ACTION_TIME_CHIP : CPR_ACTION_TIME_BASE
	if(!do_after(src, delay = action_time, target = target))
		balloon_alert(src, "не удалось сделать СЛР!")
		return FALSE

	if(!can_perform_cpr_on(target))
		return FALSE

	// Stamina cost
	var/stam_cost = has_chip ? CPR_STAMINA_COST_CHIP : CPR_STAMINA_COST_BASE
	adjust_stamina_loss(stam_cost)

	// Efficiency and rib fracture chance (only early stacks and only without chip)
	var/eff_mult = 1.0
	if(!has_chip && cpr_early_counter > 0)
		eff_mult = max(0, 1.0 - (0.10 * cpr_early_counter))

		if(target.stat != DEAD && prob(10 * cpr_early_counter))
			target.try_apply_cpr_rib_fracture(src, cpr_early_counter)

	visible_message(
		span_notice("[src] делает СЛР [target.declent_ru(DATIVE)]!"),
		span_notice("Вы делаете СЛР [target.declent_ru(DATIVE)].")
	)

	if(HAS_MIND_TRAIT(src, TRAIT_MORBID))
		add_mood_event("morbid_saved_life", /datum/mood_event/morbid_saved_life)
	else
		add_mood_event("saved_life", /datum/mood_event/saved_life)

	log_combat(src, target, "CPRed")

	if(HAS_TRAIT(target, TRAIT_NOBREATH))
		to_chat(target, span_unconscious("Вы чувствуете глоток свежего воздуха... ощущение странное..."))
	else if(!target.get_organ_slot(ORGAN_SLOT_LUNGS))
		to_chat(target, span_unconscious("Вы чувствуете глоток воздуха... но лучше вам не становится..."))
	else
		to_chat(target, span_unconscious("Вы чувствуете, как воздух наполняет ваши легкие..."))

	// Alive effect: reduce oxy; dead: no oxy effect
	if(target.stat != DEAD && !HAS_TRAIT(target, TRAIT_FAKEDEATH))
		var/oxy_amt = has_chip ? CPR_OXY_HEAL_CHIP : CPR_OXY_HEAL_BASE
		oxy_amt = round(oxy_amt * eff_mult)
		if(oxy_amt > 0)
			target.adjust_oxy_loss(-min(target.get_oxy_loss(), oxy_amt))

	// Preservation window (alive or dead)
	cpr_apply_preserve_window(target, has_chip)

	// Auto-cycle: single click starts cycle (chip only)
	if(has_chip && allow_auto_toggle)
		toggle_auto_cpr(target)

	return TRUE

/mob/living/carbon/handle_organs(seconds_per_tick, times_fired)
	if(stat == DEAD)
		if(reagents && (reagents.has_reagent(/datum/reagent/toxin/formaldehyde, 1) || reagents.has_reagent(/datum/reagent/cryostylane)))
			return

		if(world.time < cpr_preserve_until)
			return

		for(var/obj/item/organ/organ in organs)
			// On-death is where organ decay is handled
			if(organ?.owner)
				organ.on_death(seconds_per_tick, times_fired)
			// We need to re-check the stat every organ, as one of our others may have revived us
			if(stat != DEAD)
				break
		return

	// NOTE: organs_slot is sorted by GLOB.organ_process_order on insertion
	for(var/slot in organs_slot)
		var/obj/item/organ/organ = organs_slot[slot]
		if(organ?.owner)
			organ.on_life(seconds_per_tick, times_fired)
