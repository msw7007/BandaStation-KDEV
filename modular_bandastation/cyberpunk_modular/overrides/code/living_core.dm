// Cyberpunk living overrides kept outside core to reduce upstream merge conflicts.

/mob/living/Destroy()
	clear_partial_wall_occlusion()
	clear_cyberpunk_grab_hold_items()
	QDEL_NULL(cyberpunk_npc_profile)
	if(vertical_state_timer != TIMER_ID_NULL)
		deltimer(vertical_state_timer)
		vertical_state_timer = TIMER_ID_NULL
	if(vertical_stamina_timer != TIMER_ID_NULL)
		deltimer(vertical_stamina_timer)
		vertical_stamina_timer = TIMER_ID_NULL
	clear_vertical_anchor()
	return ..()

/mob/living/onZImpact(turf/impacted_turf, levels, impact_flags = NONE)
	if(!isgroundlessturf(impacted_turf))
		impact_flags |= ZImpactDamage(impacted_turf, levels)

	return ..()

/**
 * Called when this mob is receiving damage from falling
 *
 * * impacted_turf - the turf we are falling onto
 * * levels - the number of levels we are falling
 */
/mob/living/ZImpactDamage(turf/impacted_turf, levels)
	. = SEND_SIGNAL(src, COMSIG_LIVING_Z_IMPACT, levels, impacted_turf)
	if(. & ZIMPACT_CANCEL_DAMAGE)
		return .
	// multiplier for the damage taken from falling
	var/damage_softening_multiplier = 1

	var/obj/item/organ/cyberimp/chest/spine/potential_spine = get_cyberpunk_spine_implant()
	if(istype(potential_spine))
		damage_softening_multiplier *= potential_spine.athletics_boost_multiplier

	// If you are incapped, you probably can't brace yourself
	var/can_help_themselves = !INCAPACITATED_IGNORING(src, INCAPABLE_RESTRAINTS)
	if(levels <= 1 && can_help_themselves && get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 6) > 0)
		visible_message(
			span_notice("[capitalize(declent_ru(NOMINATIVE))] groups up and lands without taking damage."),
			span_notice("You group up and land without taking damage."),
		)
		return . | ZIMPACT_NO_MESSAGE
	if(levels <= 1 && can_help_themselves)
		var/obj/item/organ/wings/gliders = get_organ_by_type(/obj/item/organ/wings)
		if(HAS_TRAIT(src, TRAIT_FREERUNNING) || gliders?.can_soften_fall()) // the power of parkour or wings allows falling short distances unscathed
			var/graceful_landing = HAS_TRAIT(src, TRAIT_CATLIKE_GRACE)

			if(graceful_landing)
				add_movespeed_modifier(/datum/movespeed_modifier/landed_on_feet)
				addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/landed_on_feet), levels * 3 SECONDS)
			else
				Knockdown(levels * 4 SECONDS)
				emote("spin")

			visible_message(
				span_notice("[capitalize(declent_ru(NOMINATIVE))] жестко падает на [impacted_turf.declent_ru(ACCUSATIVE)] и не получает урона,[graceful_landing ? " оставаясь на своих ногах" : " группируясь и делая перекат"]."),
				span_notice("Вы готовитесь к падению. Вы жестко падаете на [impacted_turf.declent_ru(ACCUSATIVE)] и не получаете урона,[graceful_landing ? " оставаясь на своих ногах" : " группируясь и делая перекат"]."),
			)
			return . | ZIMPACT_NO_MESSAGE

	var/incoming_damage = (levels * 5) ** 1.5
	// Smaller mobs with catlike grace can ignore damage (EG: cats)
	var/small_surface_area = mob_size <= MOB_SIZE_SMALL
	var/skip_knockdown = FALSE
	if(HAS_TRAIT(src, TRAIT_CATLIKE_GRACE) && (small_surface_area || usable_legs >= 2) && body_position == STANDING_UP && can_help_themselves)
		. |= ZIMPACT_NO_MESSAGE|ZIMPACT_NO_SPIN
		skip_knockdown = TRUE
		if(small_surface_area)
			visible_message(
				span_notice("[capitalize(declent_ru(NOMINATIVE))] жестко падает на [impacted_turf.declent_ru(ACCUSATIVE)], но благополучно приземляется своими ногами!"),
				span_notice("Вы жестко падаете на [impacted_turf.declent_ru(ACCUSATIVE)], но благополучно приземляетесь своими ногами!"),
			)
			new /obj/effect/temp_visual/mook_dust/small(impacted_turf)
			return .

		incoming_damage *= 1.66
		add_movespeed_modifier(/datum/movespeed_modifier/landed_on_feet)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/landed_on_feet), levels * 2 SECONDS)
		visible_message(
			span_danger("[capitalize(declent_ru(NOMINATIVE))] жестко падает на [impacted_turf.declent_ru(ACCUSATIVE)] и болезненно приземляется на свои ноги!"),
			span_userdanger("Вы жестко падаете на [impacted_turf.declent_ru(ACCUSATIVE)] и инстиктивно приземляетесь на ноги - болезненно!"),
		)
		new /obj/effect/temp_visual/mook_dust(impacted_turf)

	if(body_position == STANDING_UP)
		var/damage_for_each_leg = round((incoming_damage / 2) * damage_softening_multiplier)
		apply_damage(damage_for_each_leg, BRUTE, BODY_ZONE_L_LEG, wound_bonus = -2.5 * levels)
		apply_damage(damage_for_each_leg, BRUTE, BODY_ZONE_R_LEG, wound_bonus = -2.5 * levels)
	else
		apply_damage(incoming_damage, BRUTE, spread_damage = TRUE)

	if(!skip_knockdown)
		Knockdown(levels * 5 SECONDS)
	return .

/// Modifier for mobs landing on their feet after a fall
/datum/movespeed_modifier/landed_on_feet
	movetypes = GROUND|UPSIDE_DOWN
	multiplicative_slowdown = CRAWLING_ADD_SLOWDOWN / 2

//Generic Bump(). Override MobBump() and ObjBump() instead of this.
/mob/living/Bump(atom/A)
	if(..()) //we are thrown onto something
		return
	if(buckled || now_pushing)
		return
	if(ismob(A))
		var/mob/M = A
		if(MobBump(M))
			return
	if(isobj(A))
		var/obj/O = A
		if(ObjBump(O))
			return
	if(ismovable(A))
		var/atom/movable/AM = A
		if(PushAM(AM, move_force))
			return

/mob/living/Bumped(atom/movable/AM)
	..()
	last_bumped = world.time

//Called when we bump onto a mob
/mob/living/MobBump(mob/M)
	//No bumping/swapping/pushing others if you are on walk intent
	if(move_intent == MOVE_INTENT_WALK)
		return TRUE

	if(SEND_SIGNAL(M, COMSIG_LIVING_PRE_MOB_BUMP, src) & COMPONENT_LIVING_BLOCK_PRE_MOB_BUMP)
		return TRUE

	SEND_SIGNAL(src, COMSIG_LIVING_MOB_BUMP, M)
	SEND_SIGNAL(M, COMSIG_LIVING_MOB_BUMPED, src)
	//Even if we don't push/swap places, we "touched" them, so spread fire
	spreadFire(M)

	if(now_pushing)
		return TRUE

	if(isliving(M))
		var/mob/living/L = M
		//Also spread diseases
		for(var/thing in diseases)
			var/datum/disease/D = thing
			if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
				L.ContactContractDisease(D)

		for(var/thing in L.diseases)
			var/datum/disease/D = thing
			if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
				ContactContractDisease(D)

		//Should stop you pushing a restrained person out of the way
		if(L.pulledby && L.pulledby != src && HAS_TRAIT(L, TRAIT_RESTRAINED))
			if(!(world.time % 5))
				to_chat(src, span_warning("[capitalize(L.declent_ru(NOMINATIVE))] сдерживается, вы не можете протолкнуться сквозь."))
			return TRUE

		if(L.pulling)
			if(ismob(L.pulling))
				var/mob/P = L.pulling
				if(HAS_TRAIT(P, TRAIT_RESTRAINED))
					if(!(world.time % 5))
						to_chat(src, span_warning("[capitalize(L.declent_ru(NOMINATIVE))] сдерживает [P.declent_ru(ACCUSATIVE)], вы не можете протолкнуться сквозь."))
					return TRUE

	if(moving_diagonally)//no mob swap during diagonal moves.
		return TRUE

	if(!M.buckled && !M.has_buckled_mobs())
		if(can_mobswap_with(M))
			//switch our position with M
			if(loc && !loc.Adjacent(M.loc))
				return TRUE
			now_pushing = TRUE
			var/oldloc = loc
			var/oldMloc = M.loc


			var/M_passmob = (M.pass_flags & PASSMOB) // we give PASSMOB to both mobs to avoid bumping other mobs during swap.
			var/src_passmob = (pass_flags & PASSMOB)
			M.pass_flags |= PASSMOB
			pass_flags |= PASSMOB

			var/move_failed = FALSE
			if(!M.Move(oldloc) || !Move(oldMloc))
				M.forceMove(oldMloc)
				forceMove(oldloc)
				move_failed = TRUE
			if(!src_passmob)
				pass_flags &= ~PASSMOB
			if(!M_passmob)
				M.pass_flags &= ~PASSMOB

			now_pushing = FALSE

			if(!move_failed)
				return TRUE

	//okay, so we didn't switch. but should we push?
	//not if he's not CANPUSH of course
	if(!(M.status_flags & CANPUSH))
		return TRUE
	if(isliving(M))
		var/mob/living/L = M
		if(HAS_TRAIT(L, TRAIT_PUSHIMMUNE))
			return TRUE
	//If they're a human, and they're not in help intent, block pushing
	if(ishuman(M))
		var/mob/living/carbon/human/human = M
		if(human.combat_mode)
			return TRUE
	//if they are a cyborg, and they're alive and in combat mode, block pushing
	if(iscyborg(M))
		var/mob/living/silicon/robot/borg = M
		if(borg.combat_mode && borg.stat != DEAD)
			return TRUE
	//anti-riot equipment is also anti-push
	for(var/obj/item/I in M.held_items)
		if(!isclothing(M))
			if(prob(I.block_chance*2))
				return

/mob/living/can_mobswap_with(mob/other)
	if (HAS_TRAIT(other, TRAIT_NOMOBSWAP) || HAS_TRAIT(src, TRAIT_NOMOBSWAP))
		return FALSE

	var/they_can_move = TRUE
	var/their_combat_mode = FALSE

	if(isliving(other))
		var/mob/living/other_living = other
		their_combat_mode = other_living.combat_mode
		they_can_move = other_living.mobility_flags & MOBILITY_MOVE

	var/too_strong = other.move_resist > move_force

	// They cannot move, see if we can push through them
	if (!they_can_move)
		return !too_strong

	// We are pulling them and can move through
	if (other.pulledby == src && !too_strong)
		return TRUE

	// If we're in combat mode and not restrained we don't try to pass through people
	if (combat_mode && !HAS_TRAIT(src, TRAIT_RESTRAINED))
		return FALSE

	// Nor can we pass through non-restrained people in combat mode (or if they're restrained but still too strong for us)
	if (their_combat_mode && (!HAS_TRAIT(other, TRAIT_RESTRAINED) || too_strong))
		return FALSE

	if (isnull(other.client) || isnull(client))
		return TRUE

	// If both of us are trying to move in the same direction, let the fastest one through first
	if (client.intended_direction == other.client.intended_direction)
		return cached_multiplicative_slowdown < other.cached_multiplicative_slowdown

	// Else, sure, let us pass
	return TRUE

/mob/living/get_photo_description(obj/item/camera/camera)
	var/list/holding = list()
	var/len = length(held_items)
	if(len)
		for(var/obj/item/held_item in held_items)
			if(!holding.len)
				holding += "[ru_p_they(TRUE)] держит [held_item.declent_ru(ACCUSATIVE)]"
			else if(held_items.Find(held_item) == len)
				holding += ", и [held_item.declent_ru(ACCUSATIVE)]"
			else
				holding += ", [held_item.declent_ru(ACCUSATIVE)]"
	return "На фотографии также имеется [declent_ru(NOMINATIVE)][health < (maxHealth * 0.75) ? " и выглядит немного ранено":""][holding.len ? ". [holding.Join("")].":"."]"

//Called when we bump onto an obj
/mob/living/ObjBump(obj/O)
	return

//Called when we want to push an atom/movable
/mob/living/PushAM(atom/movable/AM, force = move_force)
	if(now_pushing)
		return TRUE
	if(moving_diagonally)// no pushing during diagonal moves.
		return TRUE
	if(!client && (mob_size < MOB_SIZE_SMALL))
		return
	if(SEND_SIGNAL(AM, COMSIG_MOVABLE_BUMP_PUSHED, src, force) & COMPONENT_NO_PUSH)
		return
	now_pushing = TRUE
	SEND_SIGNAL(src, COMSIG_LIVING_PUSHING_MOVABLE, AM)
	var/dir_to_target = get_dir(src, AM)

	// If there's no dir_to_target then the player is on the same turf as the atom they're trying to push.
	// This can happen when a player is stood on the same turf as a directional window. All attempts to push
	// the window will fail as get_dir will return 0 and the player will be unable to move the window when
	// it should be pushable.
	// In this scenario, we will use the facing direction of the /mob/living attempting to push the atom as
	// a fallback.
	if(!dir_to_target)
		dir_to_target = dir

	var/push_anchored = FALSE
	if((AM.move_resist * MOVE_FORCE_CRUSH_RATIO) <= force)
		if(move_crush(AM, move_force, dir_to_target))
			push_anchored = TRUE
	if((AM.move_resist * MOVE_FORCE_FORCEPUSH_RATIO) <= force) //trigger move_crush and/or force_push regardless of if we can push it normally
		if(force_push(AM, move_force, dir_to_target, push_anchored))
			push_anchored = TRUE
	if(ismob(AM))
		var/mob/mob_to_push = AM
		var/atom/movable/mob_buckle = mob_to_push.buckled
		// If we can't pull them because of what they're buckled to, make sure we can push the thing they're buckled to instead.
		// If neither are true, we're not pushing anymore.
		if(mob_buckle && (mob_buckle.buckle_prevents_pull || (force < (mob_buckle.move_resist * MOVE_FORCE_PUSH_RATIO))))
			now_pushing = FALSE
			return
	if((AM.anchored && !push_anchored) || (force < (AM.move_resist * MOVE_FORCE_PUSH_RATIO)))
		now_pushing = FALSE
		return
	if(istype(AM, /obj/structure/window))
		var/obj/structure/window/W = AM
		if(W.fulltile)
			for(var/obj/structure/window/win in get_step(W, dir_to_target))
				now_pushing = FALSE
				return
	if(pulling == AM)
		stop_pulling()
	var/current_dir
	if(isliving(AM))
		current_dir = AM.dir
	if(AM.Move(get_step(AM.loc, dir_to_target), dir_to_target, glide_size))
		AM.add_fingerprint(src)
		Move(get_step(loc, dir_to_target), dir_to_target)
	if(current_dir)
		AM.setDir(current_dir)
	now_pushing = FALSE

/mob/living/proc/normalize_cyberpunk_grab_zone(zone)
	if(!zone)
		return BODY_ZONE_CHEST
	if(zone in GLOB.all_body_zones)
		return zone
	if(zone in GLOB.all_precise_body_zones)
		return zone
	return check_zone(zone) || zone

/mob/living/proc/set_cyberpunk_grab_zone(zone)
	cyberpunk_grab_zone = normalize_cyberpunk_grab_zone(zone)

/mob/living/proc/is_cyberpunk_grab_zone_arm(zone = cyberpunk_grab_zone)
	var/checked_zone = normalize_cyberpunk_grab_zone(zone)
	return (checked_zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND))

/mob/living/proc/is_cyberpunk_grab_zone_leg(zone = cyberpunk_grab_zone)
	var/checked_zone = normalize_cyberpunk_grab_zone(zone)
	return (checked_zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT))

/mob/living/proc/is_cyberpunk_grab_zone_head(zone = cyberpunk_grab_zone)
	var/checked_zone = normalize_cyberpunk_grab_zone(zone)
	return (checked_zone in list(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_NOSE, BODY_ZONE_PRECISE_EARS, BODY_ZONE_PRECISE_NECK))

/mob/living/proc/is_cyberpunk_grab_zone_torso(zone = cyberpunk_grab_zone)
	var/checked_zone = normalize_cyberpunk_grab_zone(zone)
	return (checked_zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_ABDOMEN))

/mob/living/proc/is_cyberpunk_grab_zone_mouth(zone = cyberpunk_grab_zone)
	return normalize_cyberpunk_grab_zone(zone) == BODY_ZONE_PRECISE_MOUTH

/mob/living/proc/is_cyberpunk_grab_zone_eyes(zone = cyberpunk_grab_zone)
	return normalize_cyberpunk_grab_zone(zone) == BODY_ZONE_PRECISE_EYES

/mob/living/proc/is_cyberpunk_grabbing_living()
	return isliving(pulling)

/mob/living/proc/is_cyberpunk_grabbed_by_arm()
	var/mob/living/grabber = pulledby
	return istype(grabber) && grabber.pulling == src && grabber.is_cyberpunk_grab_zone_arm()

/mob/living/proc/is_cyberpunk_grabbed_by_leg()
	var/mob/living/grabber = pulledby
	return istype(grabber) && grabber.pulling == src && grabber.is_cyberpunk_grab_zone_leg()

/mob/living/proc/is_active_hand_cyberpunk_grabbed()
	var/mob/living/grabber = pulledby
	if(!istype(grabber) || grabber.pulling != src || !grabber.is_cyberpunk_grab_zone_arm())
		return FALSE
	var/obj/item/bodypart/active_arm = get_active_hand()
	if(!active_arm)
		return TRUE
	var/grabbed_zone = normalize_cyberpunk_grab_zone(grabber.cyberpunk_grab_zone)
	return active_arm.body_zone == check_zone(grabbed_zone)

/mob/living/proc/is_cyberpunk_mouth_grabbed(grab_level = GRAB_PASSIVE)
	var/mob/living/grabber = pulledby
	return istype(grabber) && grabber.pulling == src && grabber.grab_state >= grab_level && grabber.is_cyberpunk_grab_zone_mouth()

/mob/living/proc/apply_cyberpunk_grab_zone_effects(mob/living/target)
	if(!istype(target) || pulling != target)
		return FALSE
	if(is_cyberpunk_grab_zone_eyes())
		if(grab_state >= GRAB_AGGRESSIVE)
			target.adjust_temp_blindness(2 SECONDS)
		else
			target.set_eye_blur_if_lower(4 SECONDS)
	return TRUE

/mob/living/proc/get_cyberpunk_grab_power(mob/living/target, upgrade = FALSE)
	var/grab_power = get_character_skill_level(SKILL_GRAPPLING)
	var/obj/item/organ/cyberimp/brain/anti_drop/grip_implant
	if(iscarbon(src))
		var/mob/living/carbon/carbon_owner = src
		grip_implant = locate(/obj/item/organ/cyberimp/brain/anti_drop) in carbon_owner.organs
	if(istype(grip_implant) && grip_implant.is_implant_functional())
		grab_power *= grip_implant.grip_strength_multiplier
	return round(grab_power)

/mob/living/proc/get_cyberpunk_grab_resistance(mob/living/grabber)
	return get_character_skill_level(SKILL_ATHLETICS)

/mob/living/proc/get_cyberpunk_grab_stamina_cost(base_cost = STAMINA_COST_ATTACK)
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 4)
	return base_cost * max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_grab_max_durability(grab_level = grab_state)
	switch(grab_level)
		if(GRAB_PASSIVE)
			return combat_mode ? 15 : 5
		if(GRAB_AGGRESSIVE)
			return 25
		if(GRAB_TWOHANDED, GRAB_KILL)
			var/strength_bonus = round(get_attribute_value(ATTRIBUTE_STRENGTH) * get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 3) * 0.01)
			return 50 + strength_bonus
	return 0

/mob/living/proc/reset_cyberpunk_grab_durability()
	cyberpunk_grab_max_durability = get_cyberpunk_grab_max_durability()
	var/mob/living/grabbed = pulling
	if(istype(grabbed))
		cyberpunk_grab_max_durability = round(cyberpunk_grab_max_durability * grabbed.get_cyberpunk_fortitude_incoming_grab_durability_multiplier())
	cyberpunk_grab_durability = cyberpunk_grab_max_durability

/mob/living/proc/get_cyberpunk_grab_durability_ratio()
	if(cyberpunk_grab_max_durability <= 0)
		return 0
	return cyberpunk_grab_durability / cyberpunk_grab_max_durability

/mob/living/proc/reinforce_cyberpunk_grab()
	reset_cyberpunk_grab_durability()
	var/mob/living/grabbed = pulling
	if(istype(grabbed))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] tightens the grip on [grabbed.declent_ru(ACCUSATIVE)]!"), span_warning("You tighten your grip on [grabbed.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/proc/reduce_cyberpunk_grab_durability(amount, mob/living/source = null)
	if(amount <= 0 || !isliving(pulling))
		return FALSE
	if(cyberpunk_grab_max_durability <= 0)
		reset_cyberpunk_grab_durability()
	cyberpunk_grab_durability = max(0, cyberpunk_grab_durability - amount)
	if(cyberpunk_grab_durability > 0)
		return TRUE
	var/mob/living/grabbed = pulling
	var/old_grab_state = grab_state
	if(grab_state > GRAB_PASSIVE)
		setGrabState(max(GRAB_PASSIVE, grab_state - 1))
	else
		reset_cyberpunk_grab_durability()
	reset_cyberpunk_grab_durability()
	if(istype(grabbed))
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))]'s grip on [grabbed.declent_ru(ACCUSATIVE)] weakens!"), span_warning("Your grip weakens."))
	log_combat(src, grabbed, "weakened grab", addition = "from [old_grab_state] to [grab_state]")
	return TRUE

/mob/living/proc/get_cyberpunk_grab_resist_amount()
	return 5 + get_attribute_value(ATTRIBUTE_STRENGTH)

/mob/living/proc/get_cyberpunk_grab_resist_cooldown()
	return max(0, 2 SECONDS - (get_attribute_value(ATTRIBUTE_DEXTERITY) * 0.2 SECONDS))

/mob/living/proc/can_cyberpunk_grab_succeed(mob/living/target, upgrade = FALSE)
	if(!istype(target))
		return TRUE
	var/grabber_power = get_cyberpunk_grab_power(target, upgrade)
	var/target_resistance = target.get_cyberpunk_grab_resistance(src)
	if(upgrade)
		if(grabber_power > target_resistance)
			return TRUE
		return prob(get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 1))
	return grabber_power >= target_resistance

/mob/living/proc/try_cyberpunk_grapple_stagger_on_grab(mob/living/target)
	if(!istype(target))
		return FALSE
	var/stagger_chance = get_cyberpunk_skill_perk_bonus(SKILL_GRAPPLING, 6, "value_1")
	if(stagger_chance <= 0 || !prob(stagger_chance))
		return FALSE
	target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
	visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))]'s grab makes [target.declent_ru(ACCUSATIVE)] stagger!"), span_warning("Your grab makes [target.declent_ru(ACCUSATIVE)] stagger."))
	return TRUE

/mob/living/proc/get_cyberpunk_failed_grab_cooldown()
	return max(0, 1 SECONDS - get_character_skill_level(SKILL_GRAPPLING))

/mob/living/proc/fail_cyberpunk_grab_attempt(mob/living/target, upgrade = FALSE)
	cyberpunk_grab_next_attempt = world.time + get_cyberpunk_failed_grab_cooldown()
	if(upgrade)
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to strengthen the grab on [target.declent_ru(ACCUSATIVE)]."), span_warning("You fail to strengthen the grab."))
	else
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] fails to grab [target.declent_ru(ACCUSATIVE)]."), span_warning("You fail to grab [target.declent_ru(ACCUSATIVE)]."))
	return FALSE

/mob/living/proc/cyberpunk_grab_action_delay(mob/living/target, upgrade = FALSE)
	if(!client || !istype(target))
		return TRUE
	if(world.time < cyberpunk_grab_next_attempt)
		balloon_alert(src, "recovering")
		return FALSE
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] reaches for [target.declent_ru(ACCUSATIVE)]."), span_notice("You reach for [target.declent_ru(ACCUSATIVE)]."))
	if(!do_after(src, 0.5 SECONDS, target))
		return FALSE
	if(!Adjacent(target) || QDELETED(target) || stat > SOFT_CRIT)
		return FALSE
	spend_stamina(get_cyberpunk_grab_stamina_cost(), "attack", TRUE)
	if(!can_cyberpunk_grab_succeed(target, upgrade))
		return fail_cyberpunk_grab_attempt(target, upgrade)
	return TRUE

/mob/living/proc/create_cyberpunk_grab_hold_item(mob/living/target, power_hold = FALSE)
	var/obj/item/cyberpunk_grab_hold/hold_item = new(src)
	hold_item.holder = src
	hold_item.grabbed = target
	hold_item.power_hold = power_hold
	hold_item.name = power_hold ? "two-handed grab" : "grab hold"
	hold_item.desc = power_hold ? "This hand reinforces a two-handed grab." : "This hand is occupied by an active grab."
	return hold_item

/mob/living/proc/equip_cyberpunk_grab_hold_item(mob/living/target, power_hold = FALSE)
	var/obj/item/cyberpunk_grab_hold/hold_item = create_cyberpunk_grab_hold_item(target, power_hold)
	var/equipped = FALSE
	if(power_hold)
		if(get_active_held_item())
			qdel(hold_item)
			return null
		equipped = put_in_active_hand(hold_item, forced = TRUE)
	else
		equipped = put_in_active_hand(hold_item, forced = TRUE)
	if(!equipped)
		qdel(hold_item)
		return null
	return hold_item

/mob/living/proc/update_cyberpunk_grab_hold_items()
	var/mob/living/grabbed = pulling
	if(!istype(grabbed))
		clear_cyberpunk_grab_hold_items()
		return FALSE
	if(!cyberpunk_grab_hold_item || QDELETED(cyberpunk_grab_hold_item))
		cyberpunk_grab_hold_item = equip_cyberpunk_grab_hold_item(grabbed)
	if(!cyberpunk_grab_hold_item)
		stop_pulling()
		return FALSE
	cyberpunk_grab_hold_item.grabbed = grabbed
	if(grab_state >= GRAB_TWOHANDED)
		if(!cyberpunk_grab_power_hold_item || QDELETED(cyberpunk_grab_power_hold_item))
			cyberpunk_grab_power_hold_item = equip_cyberpunk_grab_hold_item(grabbed, TRUE)
		if(!cyberpunk_grab_power_hold_item)
			to_chat(src, span_warning("You need a second hand for a two-handed grab."))
			setGrabState(GRAB_AGGRESSIVE)
			return FALSE
		cyberpunk_grab_power_hold_item.grabbed = grabbed
	else
		QDEL_NULL(cyberpunk_grab_power_hold_item)
	return TRUE

/mob/living/proc/clear_cyberpunk_grab_hold_items()
	QDEL_NULL(cyberpunk_grab_power_hold_item)
	QDEL_NULL(cyberpunk_grab_hold_item)

/mob/living/start_pulling(atom/movable/AM, state, force = pull_force, supress_message = FALSE)
	if(!AM || !src)
		return FALSE
	if(!(AM.can_be_pulled(src, force)))
		return FALSE
	if(throwing || !(mobility_flags & MOBILITY_PULL))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_TRY_PULL, AM, force) & COMSIG_LIVING_CANCEL_PULL)
		return FALSE
	if(SEND_SIGNAL(AM, COMSIG_LIVING_TRYING_TO_PULL, src, force) & COMSIG_LIVING_CANCEL_PULL)
		return FALSE
	if(isliving(AM))
		var/mob/living/living_target = AM
		if(!cyberpunk_grab_action_delay(living_target))
			return FALSE

	AM.add_fingerprint(src)

	// If we're pulling something then drop what we're currently pulling and pull this instead.
	if(pulling)
		// Are we trying to pull something we are already pulling? Then just stop here, no need to continue.
		if(AM == pulling)
			return FALSE
		stop_pulling()

	changeNext_move(CLICK_CD_GRABBING)

	if(AM.pulledby)
		if(!supress_message)
			AM.visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] оттаскивает [AM.declent_ru(ACCUSATIVE)] из захвата [AM.pulledby.declent_ru(GENITIVE)]."), \
							span_danger("[capitalize(declent_ru(NOMINATIVE))] оттаскивает вас из захвата [AM.pulledby.declent_ru(GENITIVE)]"), null, null, src)
			to_chat(src, span_notice("Вы оттаскиваете [AM.declent_ru(ACCUSATIVE)] из захвата [AM.pulledby.declent_ru(GENITIVE)]"))
		log_combat(AM, AM.pulledby, "pulled from", src)
		AM.pulledby.stop_pulling() //an object can't be pulled by two mobs at once.

	pulling = AM
	AM.set_pulledby(src)
	if(isliving(AM))
		set_cyberpunk_grab_zone(zone_selected)

	SEND_SIGNAL(src, COMSIG_LIVING_START_PULL, AM, state, force)

	if(!supress_message)
		var/sound_to_play = 'sound/items/weapons/thudswoosh.ogg'
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			if(H.dna.species.grab_sound)
				sound_to_play = H.dna.species.grab_sound
			if(HAS_TRAIT(H, TRAIT_STRONG_GRABBER))
				sound_to_play = null
		playsound(src.loc, sound_to_play, 50, TRUE, -1)
	update_pull_hud_icon()

	if(ismob(AM))
		var/mob/M = AM

		log_combat(src, M, "grabbed", addition="passive grab")
		if(!supress_message && !(iscarbon(AM) && HAS_TRAIT(src, TRAIT_STRONG_GRABBER)))
			if(ishuman(M))
				var/mob/living/carbon/human/grabbed_human = M
				var/grabbed_by_hands = (zone_selected == "l_arm" || zone_selected == "r_arm") && grabbed_human.usable_hands > 0
				M.visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))][grabbed_by_hands ? "":" пассивно"] хватает[grabbed_by_hands ? " за руки":""] [M.declent_ru(ACCUSATIVE)]!"), \
								span_warning("[capitalize(declent_ru(NOMINATIVE))][grabbed_by_hands ? "":" пассивно"] хватает вас[grabbed_by_hands ? " за руки":""]!"), null, null, src)
				to_chat(src, span_notice("Вы[grabbed_by_hands ? "":" пассивно"] хватаете [M.declent_ru(ACCUSATIVE)][grabbed_by_hands ? " за руки":""]!"))
				grabbed_human.share_blood_on_touch(src, grabbed_by_hands ? ITEM_SLOT_GLOVES : ITEM_SLOT_ICLOTHING|ITEM_SLOT_OCLOTHING)
			else
				M.visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] пассивно хватает [M.declent_ru(ACCUSATIVE)]!"), \
								span_warning("[capitalize(declent_ru(NOMINATIVE))] пассивно хватает вас!"), null, null, src)
				to_chat(src, span_notice("Вы пассивно хватаете [M.declent_ru(ACCUSATIVE)]!"))

		if(isliving(M))
			var/mob/living/L = M

			SEND_SIGNAL(M, COMSIG_LIVING_GET_PULLED, src)
			//Share diseases that are spread by touch
			for(var/thing in diseases)
				var/datum/disease/D = thing
				if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
					L.ContactContractDisease(D)

			for(var/thing in L.diseases)
				var/datum/disease/D = thing
				if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
					ContactContractDisease(D)

			if(iscarbon(L))
				var/mob/living/carbon/C = L
				if(HAS_TRAIT(src, TRAIT_STRONG_GRABBER))
					C.grabbedby(src)

			update_pull_movespeed()
			try_cyberpunk_grapple_stagger_on_grab(L)
			apply_cyberpunk_grab_zone_effects(L)

		set_pull_offsets(M, state)
		update_cyberpunk_grab_hold_items()
		reset_cyberpunk_grab_durability()
		return TRUE

/mob/living/stop_pulling()
	cyberpunk_grab_durability = 0
	cyberpunk_grab_max_durability = 0
	clear_cyberpunk_grab_hold_items()
	return ..()

/**
 * Updates the offsets of the passed mob according to the passed grab state and the direction between them and us
 *
 * * M - the mob to update the offsets of
 * * grab_state - the state of the grab
 * * animate - whether or not to animate the offsets
 */
/mob/living/set_pull_offsets(mob/living/mob_to_set, grab_state = GRAB_PASSIVE, animate = TRUE)
	if(mob_to_set.buckled)
		return //don't make them change direction or offset them if they're buckled into something.
	var/offset = 0
	switch(grab_state)
		if(GRAB_PASSIVE)
			offset = GRAB_PIXEL_SHIFT_PASSIVE
		if(GRAB_AGGRESSIVE)
			offset = GRAB_PIXEL_SHIFT_AGGRESSIVE
		if(GRAB_TWOHANDED)
			offset = GRAB_PIXEL_SHIFT_AGGRESSIVE
		if(GRAB_KILL)
			offset = GRAB_PIXEL_SHIFT_AGGRESSIVE
	mob_to_set.setDir(get_dir(mob_to_set, src))
	var/dir_filter = mob_to_set.dir
	if(ISDIAGONALDIR(dir_filter))
		dir_filter = EWCOMPONENT(dir_filter)
	switch(dir_filter)
		if(NORTH)
			mob_to_set.add_offsets(GRABBING_TRAIT, x_add = 0, y_add = offset, animate = animate)
		if(SOUTH)
			mob_to_set.add_offsets(GRABBING_TRAIT, x_add = 0, y_add = -offset, animate = animate)
		if(EAST)
			if(mob_to_set.lying_angle == LYING_ANGLE_WEST) //update the dragged dude's direction if we've turned
				mob_to_set.set_lying_angle(LYING_ANGLE_EAST)
			mob_to_set.add_offsets(GRABBING_TRAIT, x_add = offset, y_add = 0, animate = animate)
		if(WEST)
			if(mob_to_set.lying_angle == LYING_ANGLE_EAST)
				mob_to_set.set_lying_angle(LYING_ANGLE_WEST)
			mob_to_set.add_offsets(GRABBING_TRAIT, x_add = -offset, y_add = 0, animate = animate)

/**
 * Removes any offsets from the passed mob that are related to being grabbed
 *
 * * M - the mob to remove the offsets from
 * * override - if TRUE, the offsets will be removed regardless of the mob's buckled state
 * otherwise we won't remove the offsets if the mob is buckled
 */
/mob/living/reset_pull_offsets(mob/living/M, override)
	if(!override && M.buckled)
		return
	M.remove_offsets(GRABBING_TRAIT)

//mob verbs are a lot faster than object verbs
//for more info on why this is not atom/pull, see examinate() in mob.dm
/mob/living/pulled(atom/movable/AM as mob|obj in oview(1))
	set name = "Pull"
	set category = null // BANDASTATION REPLACEMENT: Original: "Object"

	if(istype(AM) && Adjacent(AM))
		start_pulling(AM)
	else if(!combat_mode) //Don;'t cancel pulls if misclicking in combat mode.
		stop_pulling()

/mob/living/stop_pulling()
	if(ismob(pulling))
		reset_pull_offsets(pulling)
	..()
	update_pull_movespeed()
	update_pull_hud_icon()

/mob/living/verb/stop_pulling1()
	set name = "Stop Pulling"
	set category = null // BANDASTATION REPLACEMENT: Original: "IC"
	stop_pulling()

//same as above
/mob/living/pointed(atom/A)
	if(INCAPACITATED_IGNORING(src, INCAPABLE_RESTRAINTS))
		return FALSE

	return ..()

/mob/living/_pointed(atom/pointing_at)
	if(!..())
		return FALSE
	log_message("points at [pointing_at]", LOG_EMOTE)
	visible_message(span_infoplain("[span_name("[capitalize(declent_ru(NOMINATIVE))]")] указывает на [pointing_at.declent_ru(ACCUSATIVE)]."), span_notice("Вы указываете на [pointing_at.declent_ru(ACCUSATIVE)]."))

/mob/living/succumb(whispered as num|null)
	set hidden = TRUE
	if (!CAN_SUCCUMB(src))
		if(HAS_TRAIT(src, TRAIT_SUCCUMB_OVERRIDE))
			if(whispered)
				to_chat(src, span_notice("Ваше бессмертное тело не даёт вам умереть! Пока вы не нажмёте кнопку на экране."), type=MESSAGE_TYPE_INFO)
				return
		else
			to_chat(src, span_warning("Вы не можете сдаться смерти! Эта жизнь продолжается."), type=MESSAGE_TYPE_INFO)
			return
	log_message("Has [whispered ? "whispered his final words" : "succumbed to death"] with [round(health, 0.1)] points of health!", LOG_ATTACK)
	adjust_oxy_loss(health - HEALTH_THRESHOLD_DEAD)
	updatehealth()
	if(!whispered)
		to_chat(src, span_notice("Вы сдались и отдались смерти."))
	investigate_log("has succumbed to death.", INVESTIGATE_DEATHS)
	death()

// Remember, anything that influences this needs to call update_incapacitated somehow when it changes
// Most often best done in [code/modules/mob/living/init_signals.dm]
/mob/living/build_incapacitated(flags)
	// Holds a set of flags that describe how we are currently incapacitated
	var/incap_status = NONE
	if(HAS_TRAIT(src, TRAIT_INCAPACITATED))
		incap_status |= TRADITIONAL_INCAPACITATED
	if(HAS_TRAIT(src, TRAIT_RESTRAINED))
		incap_status |= INCAPABLE_RESTRAINTS
	if(pulledby && pulledby.grab_state >= GRAB_AGGRESSIVE)
		incap_status |= INCAPABLE_GRAB
	if(HAS_TRAIT(src, TRAIT_STASIS))
		incap_status |= INCAPABLE_STASIS

	return incap_status

/mob/living/canUseStorage()
	if (usable_hands <= 0)
		return FALSE
	return TRUE


//This proc is used for mobs which are affected by pressure to calculate the amount of pressure that actually
//affects them once clothing is factored in. ~Errorage
/mob/living/calculate_affecting_pressure(pressure)
	return pressure

/mob/living/getMaxHealth()
	return maxHealth

/mob/living/setMaxHealth(newMaxHealth)
	maxHealth = newMaxHealth

/// Returns the health of the mob while ignoring damage of non-organic (prosthetic) limbs
/// Used by cryo cells to not permanently imprison those with damage from prosthetics,
/// as they cannot be healed through chemicals.
/mob/living/get_organic_health()
	return health

// MOB PROCS //END

/mob/living/mob_sleep()
	set name = "Sleep"
	set category = "IC"

	if(IsSleeping())
		to_chat(src, span_warning("You are already asleep!"))
		return
	if(cyberpunk_sleep_preparing)
		to_chat(src, span_warning("You are already preparing to sleep."))
		return
	if(tgui_alert(usr, "Are you sure you want to sleep for a while?", "Sleep", list("Yes", "No")) != "Yes")
		return
	var/sleep_prepare_time = get_cyberpunk_sleep_prepare_time()
	cyberpunk_sleep_preparing = TRUE
	to_chat(src, span_notice("You prepare to sleep."))
	if(!do_after(src, sleep_prepare_time, target = src))
		cyberpunk_sleep_preparing = FALSE
		to_chat(src, span_warning("You stop trying to fall asleep."))
		return
	cyberpunk_sleep_preparing = FALSE
	if(IsSleeping())
		return
	to_chat(src, span_notice("You fall asleep."))
	SetSleeping(400) //Short nap
	return



/mob/get_contents()


/**
 * Gets ID card from a mob.
 * Argument:
 * * hand_firsts - boolean that checks the hands of the mob first if TRUE.
 */
/mob/living/get_idcard(hand_first)
	if(!length(held_items)) //Early return for mobs without hands.
		return
	//Check hands
	var/obj/item/held_item = get_active_held_item()
	if(held_item) //Check active hand
		. = held_item.GetID()
	if(!.) //If there is no id, check the other hand
		held_item = get_inactive_held_item()
		if(held_item)
			. = held_item.GetID()

/**
 * Returns the access list for this mob
 */
/mob/living/get_access()
	var/list/access_list = list()
	SEND_SIGNAL(src, COMSIG_MOB_RETRIEVE_ACCESS, access_list)
	return access_list

/mob/living/get_id_in_hand()
	var/obj/item/held_item = get_active_held_item()
	if(!held_item)
		return
	return held_item.GetID()

//Returns the bank account of an ID the user may be holding.
/mob/living/get_bank_account()
	RETURN_TYPE(/datum/bank_account)
	var/datum/bank_account/account
	var/obj/item/card/id/I = get_idcard()

	if(I?.registered_account)
		account = I.registered_account
		remember_data("bank_account", account.account_id)
		return account

// CYBERPUNK BUILD - rebuild and delete before release
/// Assigns a reusable Cyberpunk NPC interaction profile to this mob.
/mob/living/proc/cyberpunk_setup_npc_profile(
	greeting = "Need something?",
	title = "street contact",
	faction = "independent",
	list/dialog_options,
	list/shop_items,
	list/services,
)
	QDEL_NULL(cyberpunk_npc_profile)
	cyberpunk_npc_profile = new(src, greeting, title, faction)
	if(dialog_options)
		for(var/datum/cyberpunk_npc_dialog_option/option as anything in dialog_options)
			cyberpunk_npc_profile.dialog_options += option
	if(shop_items)
		for(var/datum/cyberpunk_npc_shop_item/item as anything in shop_items)
			cyberpunk_npc_profile.shop_items += item
	if(services)
		for(var/datum/cyberpunk_npc_service/service as anything in services)
			cyberpunk_npc_profile.services += service
	return cyberpunk_npc_profile

/mob/living/proc/cyberpunk_vendor_is_open()
	return TRUE

/// Minimal test setup for temporary city NPCs until map roles bind real profiles.
/mob/living/proc/cyberpunk_setup_default_npc_vendor()
	var/list/dialog = list(
		new /datum/cyberpunk_npc_dialog_option("rumors", "Ask about the street", "Work moves through contracts, corps move through debt, and everyone else moves when credits do."),
		new /datum/cyberpunk_npc_dialog_option("services", "Ask about services", "I can trade, patch you up, repair your gear, or route you to a stylist/designer booth."),
	)
	var/list/shop = list(
		new /datum/cyberpunk_npc_shop_item("food_bread", "Ready food", "Cheap ready meal.", /obj/item/food/bread/plain, "food", 35, 10, 8),
		new /datum/cyberpunk_npc_shop_item("water", "Water", "Sealed drinking water.", /obj/item/reagent_containers/cup/soda_cans/sodawater, "water", 20, 5, 12),
		new /datum/cyberpunk_npc_shop_item("cigarettes", "Cigarettes", "A disposable pack of smokes.", /obj/item/storage/fancy/cigarettes, "cigarettes", 45, 8, 6),
		new /datum/cyberpunk_npc_shop_item("toy_ball", "Toy", "Cheap distraction.", /obj/item/toy/basketball, "toys", 70, 15, 2),
		new /datum/cyberpunk_npc_shop_item("jumpsuit", "Equipment", "Basic clothes.", /obj/item/clothing/under/color/grey, "equipment", 90, 20, 3),
		new /datum/cyberpunk_npc_shop_item("parts", "Machine parts", "Generic stock part.", /obj/item/stock_parts/scanning_module, "parts", 120, 25, 4),
	)
	var/list/services = list(
		new /datum/cyberpunk_npc_service/healing,
		new /datum/cyberpunk_npc_service/repair,
		new /datum/cyberpunk_npc_service/designer,
		new /datum/cyberpunk_npc_service/stylist,
	)
	return cyberpunk_setup_npc_profile("What are you buying?", "street vendor", "independent", dialog, shop, services)

/mob/living/proc/cyberpunk_can_talk_to_npc(mob/living/user)
	if(!cyberpunk_npc_profile || QDELETED(cyberpunk_npc_profile))
		return FALSE
	if(stat != CONSCIOUS)
		return FALSE
	if(!istype(user) || user.stat != CONSCIOUS)
		return FALSE
	if(!Adjacent(user))
		to_chat(user, span_warning("You need to be closer."))
		return FALSE
	return TRUE

/mob/living/proc/cyberpunk_open_npc_dialog(mob/living/user)
	if(!cyberpunk_can_talk_to_npc(user))
		return FALSE
	cyberpunk_npc_profile.open_dialog(user)
	return TRUE

/mob/living/proc/cyberpunk_open_npc_trade(mob/living/user)
	if(!cyberpunk_can_talk_to_npc(user))
		return FALSE
	cyberpunk_npc_profile.open_trade(user)
	return TRUE

/mob/living/verb/cyberpunk_talk_to_npc()
	set name = "Talk to NPC"
	set category = "IC"
	set src in oview(1)

	var/mob/living/user = usr
	cyberpunk_open_npc_dialog(user)

/mob/living/verb/cyberpunk_trade_with_npc()
	set name = "Trade with NPC"
	set category = "IC"
	set src in oview(1)

	var/mob/living/user = usr
	cyberpunk_open_npc_trade(user)

/mob/living/verb/cyberpunk_make_test_vendor()
	set name = "Make Test NPC Vendor"
	set category = "IC"

	var/turf/spawn_turf = get_step(src, dir) || get_turf(src)
	var/mob/living/carbon/human/cyberpunk_npc/vendor/npc = new(spawn_turf)
	to_chat(src, span_notice("Spawned [npc] with full temporary vendor, trade, treatment, repair, designer and stylist services."))
	npc.cyberpunk_open_npc_dialog(src)

/mob/living/verb/cyberpunk_apply_test_vendor_profile()
	set name = "Apply Test Vendor Profile"
	set category = "IC"
	set src in oview(1)

	cyberpunk_setup_default_npc_vendor()
	to_chat(usr, span_notice("[src] now has a temporary NPC vendor profile."))

/mob/living/verb/cyberpunk_spawn_test_npc()
	set name = "Spawn Test Cyberpunk NPC"
	set category = "IC"

	var/list/choices = list(
		"general vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor,
		"food vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/food,
		"water vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/water,
		"smokes vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/smokes,
		"gear vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/gear,
		"misc vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/misc,
		"toy vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/toys,
		"clothing vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/clothing,
		"stylist" = /mob/living/carbon/human/cyberpunk_npc/vendor/stylist,
		"designer" = /mob/living/carbon/human/cyberpunk_npc/vendor/designer,
		"implant vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/implants,
		"parts vendor" = /mob/living/carbon/human/cyberpunk_npc/vendor/parts,
		"bystander" = /mob/living/carbon/human/cyberpunk_npc/bystander,
		"runner" = /mob/living/carbon/human/cyberpunk_npc/runner,
		"worker" = /mob/living/carbon/human/cyberpunk_npc/worker,
		"security test heavy" = /mob/living/carbon/human/cyberpunk_npc/security,
	)
	var/picked = tgui_input_list(src, "Spawn which temporary NPC?", "Cyberpunk NPC", choices)
	if(!picked)
		return
	var/turf/spawn_turf = get_step(src, dir) || get_turf(src)
	var/npc_type = choices[picked]
	var/mob/living/carbon/human/cyberpunk_npc/npc = new npc_type(spawn_turf)
	to_chat(src, span_notice("Spawned [npc] ([picked])."))

/mob/living/verb/cyberpunk_create_test_wardrobe()
	set name = "Create Test Wardrobe"
	set category = "IC"

	var/turf/spawn_turf = get_step(src, dir) || get_turf(src)
	var/obj/machinery/cyberpunk_wardrobe/wardrobe = new(spawn_turf)
	to_chat(src, span_notice("Created [wardrobe]."))

/mob/living/carbon/human/cyberpunk_npc
	real_name = "city local"
	name = "city local"
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_city
	var/cyberpunk_stationary_npc = FALSE
	var/cyberpunk_vendor_profile = "local"
	var/list/cyberpunk_vendor_categories
	var/list/cyberpunk_vendor_services
	var/cyberpunk_vendor_active = TRUE
	var/cyberpunk_vendor_night_cycle = FALSE
	var/turf/cyberpunk_vendor_stall_turf
	var/turf/cyberpunk_vendor_home_turf
	var/cyberpunk_vendor_last_restock_day = 0
	var/cyberpunk_ambient_phrase_key = "bystander"
	var/cyberpunk_ambient_speech_interval = 10 SECONDS
	var/cyberpunk_next_ambient_speech = 0

/mob/living/carbon/human/cyberpunk_npc/Initialize(mapload)
	. = ..()
	set_species(/datum/species/human)
	equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(src), ITEM_SLOT_ICLOTHING, initial = TRUE)
	equip_to_slot_or_del(new /obj/item/clothing/shoes/sneakers/black(src), ITEM_SLOT_FEET, initial = TRUE)
	if(cyberpunk_stationary_npc)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, "cyberpunk_stationary_npc")
		QDEL_NULL(ai_controller)
	cyberpunk_setup_city_npc_profile()
	update_body()

/mob/living/carbon/human/cyberpunk_npc/attack_hand(mob/user, list/modifiers)
	var/mob/living/living_user = user
	if(!cyberpunk_stationary_npc && istype(living_user) && !living_user.combat_mode && !LAZYACCESS(modifiers, RIGHT_CLICK))
		cyberpunk_try_prompted_ambient_speech(living_user, modifiers)
		return TRUE
	return ..()

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_has_active_threat()
	return ai_controller?.blackboard_key_exists(BB_CP_THREAT_TARGET)

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_say_ambient_phrase()
	var/message = pick_list(CYBERPUNK_NPC_AMBIENT_FILE, cyberpunk_ambient_phrase_key)
	if(!message)
		return FALSE
	say(message, forced = "city ambient")
	cyberpunk_next_ambient_speech = world.time + cyberpunk_ambient_speech_interval
	return TRUE

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_try_prompted_ambient_speech(mob/user, list/modifiers)
	if(cyberpunk_stationary_npc || LAZYACCESS(modifiers, RIGHT_CLICK))
		return FALSE
	var/mob/living/living_user = user
	if(!istype(living_user) || living_user.stat != CONSCIOUS || living_user.combat_mode)
		return FALSE
	if(stat != CONSCIOUS || client || combat_mode || !ai_controller || cyberpunk_has_active_threat())
		return FALSE
	if(ai_controller.blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return FALSE
	if(!Adjacent(living_user))
		to_chat(living_user, span_warning("You need to be closer."))
		return TRUE
	return cyberpunk_say_ambient_phrase()

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_can_ambient_speak(list/active_players)
	if(cyberpunk_stationary_npc || stat != CONSCIOUS || client || !ai_controller)
		return FALSE
	if(cyberpunk_has_active_threat())
		return FALSE
	if(ai_controller.blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
		return FALSE
	if(!length(active_players))
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE
	for(var/mob/living/listener as anything in active_players)
		if(listener.z != current_turf.z || get_dist(listener, src) > 7)
			continue
		if(can_see(listener, src, 7))
			return TRUE
	return FALSE

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_try_ambient_speech(list/active_players)
	if(world.time < cyberpunk_next_ambient_speech)
		return FALSE
	if(!cyberpunk_next_ambient_speech)
		cyberpunk_next_ambient_speech = world.time + rand(0, cyberpunk_ambient_speech_interval)
		return FALSE
	cyberpunk_next_ambient_speech = world.time + cyberpunk_ambient_speech_interval
	if(!cyberpunk_can_ambient_speak(active_players))
		return FALSE
	return cyberpunk_say_ambient_phrase()

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_setup_city_npc_profile()
	var/list/dialog = list(
		new /datum/cyberpunk_npc_dialog_option("street", "Ask about the street", "The city never sleeps. It just changes who pays the electric bill."),
		new /datum/cyberpunk_npc_dialog_option("work", "Ask about work", "Contracts are cleaner than favors. Favors always come back with interest."),
	)
	var/list/services = list()
	if(cyberpunk_stationary_npc || istype(src, /mob/living/carbon/human/cyberpunk_npc/vendor))
		var/list/service_pool = list(
			"healing" = /datum/cyberpunk_npc_service/healing,
			"repair" = /datum/cyberpunk_npc_service/repair,
			"designer" = /datum/cyberpunk_npc_service/designer,
			"stylist" = /datum/cyberpunk_npc_service/stylist,
		)
		if(length(cyberpunk_vendor_services))
			for(var/service_id in cyberpunk_vendor_services)
				var/service_type = service_pool[service_id]
				if(service_type)
					services += new service_type
		else
			for(var/service_id in service_pool)
				var/service_type = service_pool[service_id]
				services += new service_type
	cyberpunk_setup_npc_profile("Need something?", cyberpunk_vendor_profile, "independent", dialog, cyberpunk_city_shop_items(cyberpunk_vendor_categories), services)

/mob/living/carbon/human/cyberpunk_npc/cyberpunk_vendor_is_open()
	return TRUE

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_vendor_restock(day = 0)
	if(day && cyberpunk_vendor_last_restock_day == day)
		return FALSE
	cyberpunk_vendor_last_restock_day = day
	cyberpunk_setup_city_npc_profile()
	return TRUE

/mob/living/carbon/human/cyberpunk_npc/proc/cyberpunk_set_vendor_open(open)
	cyberpunk_vendor_active = !!open
	return TRUE

/proc/cyberpunk_city_shop_items(list/categories)
	var/list/items = list(
		new /datum/cyberpunk_npc_shop_item("food_bread", "Ready food", "Cheap ready meal.", /obj/item/food/bread/plain, "food", 35, 10, 8),
		new /datum/cyberpunk_npc_shop_item("water", "Water", "Sealed drinking water.", /obj/item/reagent_containers/cup/soda_cans/sodawater, "water", 20, 5, 12),
		new /datum/cyberpunk_npc_shop_item("cigarettes", "Cigarettes", "A disposable pack of smokes.", /obj/item/storage/fancy/cigarettes, "cigarettes", 45, 8, 6),
		new /datum/cyberpunk_npc_shop_item("toy_ball", "Toy", "Cheap distraction.", /obj/item/toy/basketball, "toys", 70, 15, 2),
		new /datum/cyberpunk_npc_shop_item("plush", "Plush toy", "Soft shelf toy.", /obj/item/toy/plush, "toys", 80, 15, 3),
		new /datum/cyberpunk_npc_shop_item("jumpsuit", "Equipment", "Basic clothes.", /obj/item/clothing/under/color/grey, "equipment", 90, 20, 3),
		new /datum/cyberpunk_npc_shop_item("grey_clothes", "Basic clothes", "Clean streetwear basics.", /obj/item/clothing/under/color/grey, "clothing", 90, 20, 5),
		new /datum/cyberpunk_npc_shop_item("black_sneakers", "Black sneakers", "Cheap walking shoes.", /obj/item/clothing/shoes/sneakers/black, "clothing", 60, 15, 5),
		new /datum/cyberpunk_npc_shop_item("paper", "Paper", "Blank city paperwork.", /obj/item/paper, "misc", 5, 1, 20),
		new /datum/cyberpunk_npc_shop_item("pen", "Pen", "Disposable writing tool.", /obj/item/pen, "misc", 10, 2, 12),
		new /datum/cyberpunk_npc_shop_item("flashlight", "Flashlight", "Small utility light.", /obj/item/flashlight, "misc", 45, 10, 6),
		new /datum/cyberpunk_npc_shop_item("parts", "Machine parts", "Generic stock part.", /obj/item/stock_parts/scanning_module, "parts", 120, 25, 4),
		new /datum/cyberpunk_npc_shop_item("medkit", "First-aid kit", "Basic medical supplies.", /obj/item/storage/medkit/regular, "supplies", 240, 40, 2),
		new /datum/cyberpunk_npc_shop_item("toolbox", "Toolbox", "Common repair tools.", /obj/item/storage/toolbox/mechanical, "supplies", 180, 25, 3),
		new /datum/cyberpunk_npc_shop_item("cable_coil", "Cable coil", "Basic infrastructure supply.", /obj/item/stack/cable_coil, "supplies", 50, 8, 8),
	)
	if(!length(categories))
		return items
	var/list/filtered = list()
	for(var/datum/cyberpunk_npc_shop_item/item as anything in items)
		if(item.category in categories)
			filtered += item
		else
			qdel(item)
	return filtered

/mob/living/carbon/human/cyberpunk_npc/vendor
	real_name = "street vendor"
	name = "street vendor"
	cyberpunk_vendor_profile = "street vendor"
	cyberpunk_vendor_night_cycle = TRUE
	cyberpunk_ambient_phrase_key = "vendor"

/mob/living/carbon/human/cyberpunk_npc/vendor/cyberpunk_vendor_is_open()
	return cyberpunk_vendor_active && !stat && !QDELETED(src)

/mob/living/carbon/human/cyberpunk_npc/vendor/cyberpunk_set_vendor_open(open)
	cyberpunk_vendor_active = !!open
	return TRUE

/mob/living/carbon/human/cyberpunk_npc/vendor/attack_hand(mob/user, list/modifiers)
	if(!cyberpunk_vendor_is_open())
		to_chat(user, span_notice("[src] is closed right now."))
		return TRUE
	var/mob/living/living_user = user
	if(istype(living_user) && !living_user.combat_mode && !LAZYACCESS(modifiers, RIGHT_CLICK))
		return cyberpunk_open_npc_dialog(living_user)
	return ..()

/mob/living/carbon/human/cyberpunk_npc/vendor/food
	real_name = "food vendor"
	name = "food vendor"
	cyberpunk_vendor_profile = "food vendor"
	cyberpunk_vendor_categories = list("food")

/mob/living/carbon/human/cyberpunk_npc/vendor/water
	real_name = "water vendor"
	name = "water vendor"
	cyberpunk_vendor_profile = "water vendor"
	cyberpunk_vendor_categories = list("water")

/mob/living/carbon/human/cyberpunk_npc/vendor/smokes
	real_name = "smoke vendor"
	name = "smoke vendor"
	cyberpunk_vendor_profile = "smoke vendor"
	cyberpunk_vendor_categories = list("cigarettes")

/mob/living/carbon/human/cyberpunk_npc/vendor/gear
	real_name = "gear vendor"
	name = "gear vendor"
	cyberpunk_vendor_profile = "gear vendor"
	cyberpunk_vendor_categories = list("equipment", "toys", "supplies")

/mob/living/carbon/human/cyberpunk_npc/vendor/misc
	real_name = "city goods vendor"
	name = "city goods vendor"
	cyberpunk_vendor_profile = "city goods vendor"
	cyberpunk_vendor_categories = list("misc")

/mob/living/carbon/human/cyberpunk_npc/vendor/toys
	real_name = "toy vendor"
	name = "toy vendor"
	cyberpunk_vendor_profile = "toy vendor"
	cyberpunk_vendor_categories = list("toys")

/mob/living/carbon/human/cyberpunk_npc/vendor/clothing
	real_name = "clothing vendor"
	name = "clothing vendor"
	cyberpunk_vendor_profile = "clothing vendor"
	cyberpunk_vendor_categories = list("clothing")

/mob/living/carbon/human/cyberpunk_npc/vendor/stylist
	real_name = "stylist"
	name = "stylist"
	cyberpunk_vendor_profile = "stylist"
	cyberpunk_vendor_categories = list("clothing")
	cyberpunk_vendor_services = list("stylist")

/mob/living/carbon/human/cyberpunk_npc/vendor/designer
	real_name = "designer"
	name = "designer"
	cyberpunk_vendor_profile = "designer"
	cyberpunk_vendor_categories = list("clothing")
	cyberpunk_vendor_services = list("designer")

/mob/living/carbon/human/cyberpunk_npc/vendor/implants
	real_name = "implant vendor"
	name = "implant vendor"
	cyberpunk_vendor_profile = "implant vendor"
	cyberpunk_vendor_categories = list("implants")

/mob/living/carbon/human/cyberpunk_npc/vendor/parts
	real_name = "parts vendor"
	name = "parts vendor"
	cyberpunk_vendor_profile = "parts vendor"
	cyberpunk_vendor_categories = list("parts", "supplies")

/mob/living/carbon/human/cyberpunk_npc/vendor/supplies
	real_name = "supply vendor"
	name = "supply vendor"
	cyberpunk_vendor_profile = "supply vendor"
	cyberpunk_vendor_categories = list("supplies", "misc")

/mob/living/carbon/human/cyberpunk_npc/bystander
	real_name = "bystander"
	name = "bystander"
	cyberpunk_vendor_profile = "bystander"
	cyberpunk_vendor_categories = list()

/mob/living/carbon/human/cyberpunk_npc/runner
	real_name = "runner"
	name = "runner"
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_city/runner
	cyberpunk_vendor_profile = "runner"
	cyberpunk_vendor_categories = list()
	cyberpunk_ambient_phrase_key = "runner"

/mob/living/carbon/human/cyberpunk_npc/worker
	real_name = "worker"
	name = "worker"
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_city/worker
	cyberpunk_vendor_profile = "worker"
	cyberpunk_vendor_categories = list("parts", "water")
	cyberpunk_ambient_phrase_key = "worker"

/mob/living/carbon/human/cyberpunk_npc/security
	real_name = "security contractor"
	name = "security contractor"
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_city/security
	cyberpunk_vendor_profile = "security contractor"
	cyberpunk_vendor_categories = list("equipment")
	cyberpunk_ambient_phrase_key = "security"

/obj/effect/landmark/cyberpunk_npc_trader
	name = "cyberpunk npc trader"
	icon_state = "generic_event"
	color = "#00d9ff"
	var/trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor
	var/home_range = 18

/obj/effect/landmark/cyberpunk_npc_trader/Initialize(mapload)
	. = ..()
	if(!mapload)
		return
	var/turf/spawn_turf = get_turf(src)
	if(!cyberpunk_turf_is_clear_for_city_spawn(spawn_turf))
		stack_trace("Cyberpunk NPC trader landmark [src.type] has no valid ground turf at [AREACOORD(src)].")
		return INITIALIZE_HINT_QDEL
	var/mob/living/carbon/human/cyberpunk_npc/trader = new trader_type(spawn_turf)
	trader.setDir(dir)
	trader.cyberpunk_vendor_stall_turf = spawn_turf
	trader.cyberpunk_vendor_home_turf = SScyberpunk_city_ai?.nearest_vendor_home(src, home_range) || cyberpunk_random_turf_in_area_type(/area/cyberpunk/city/district, null, 0, INFINITY) || spawn_turf
	trader.cyberpunk_set_vendor_open(FALSE)
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/cyberpunk_npc_trader/food
	name = "cyberpunk food trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/food

/obj/effect/landmark/cyberpunk_npc_trader/stylist
	name = "cyberpunk stylist trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/stylist

/obj/effect/landmark/cyberpunk_npc_trader/designer
	name = "cyberpunk designer trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/designer

/obj/effect/landmark/cyberpunk_npc_trader/misc
	name = "cyberpunk misc trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/misc

/obj/effect/landmark/cyberpunk_npc_trader/toys
	name = "cyberpunk toy trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/toys

/obj/effect/landmark/cyberpunk_npc_trader/clothing
	name = "cyberpunk clothing trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/clothing

/obj/effect/landmark/cyberpunk_npc_trader/supplies
	name = "cyberpunk supply trader"
	trader_type = /mob/living/carbon/human/cyberpunk_npc/vendor/supplies

/obj/effect/landmark/cyberpunk_npc_trader_home
	name = "cyberpunk trader home"
	icon_state = "generic_event"
	color = "#8f8fff"
	invisibility = INVISIBILITY_ABSTRACT

/obj/effect/landmark/cyberpunk_npc_trader_home/Initialize(mapload)
	. = ..()
	SScyberpunk_city_ai?.vendor_home_points += src

/obj/effect/landmark/cyberpunk_npc_trader_home/Destroy()
	SScyberpunk_city_ai?.vendor_home_points -= src
	return ..()

/datum/cyberpunk_npc_profile
	var/mob/living/owner
	var/greeting = "Need something?"
	var/title = "contact"
	var/faction = "independent"
	var/list/dialog_options = list()
	var/list/shop_items = list()
	var/list/services = list()
	var/selected_dialog
	var/last_message

/datum/cyberpunk_npc_profile/New(mob/living/new_owner, new_greeting, new_title, new_faction)
	owner = new_owner
	if(!isnull(new_greeting))
		greeting = new_greeting
	if(!isnull(new_title))
		title = new_title
	if(!isnull(new_faction))
		faction = new_faction

/datum/cyberpunk_npc_profile/Destroy()
	owner = null
	QDEL_LIST(dialog_options)
	QDEL_LIST(shop_items)
	QDEL_LIST(services)
	return ..()

/datum/cyberpunk_npc_profile/proc/open_dialog(mob/living/user)
	var/datum/cyberpunk_npc_dialog_ui/ui_datum = new(src)
	ui_datum.ui_interact(user)

/datum/cyberpunk_npc_profile/proc/open_trade(mob/living/user)
	var/datum/cyberpunk_npc_trade_ui/ui_datum = new(src)
	ui_datum.ui_interact(user)

/datum/cyberpunk_npc_profile/proc/base_ui_data(mob/living/user)
	var/datum/bank_account/account = user?.get_bank_account()
	return list(
		"npcName" = owner?.name || "unknown",
		"title" = title,
		"faction" = faction,
		"greeting" = greeting,
		"lastMessage" = last_message,
		"balance" = account?.account_balance || 0,
	)

/datum/cyberpunk_npc_profile/proc/dialog_ui_data(mob/living/user)
	var/list/data = base_ui_data(user)
	var/list/options = list()
	for(var/datum/cyberpunk_npc_dialog_option/option as anything in dialog_options)
		options += list(option.to_ui_data())
	var/list/service_data = list()
	for(var/datum/cyberpunk_npc_service/service as anything in services)
		service_data += list(service.to_ui_data(user, owner))
	data["dialogOptions"] = options
	data["services"] = service_data
	data["canTrade"] = length(shop_items) > 0
	var/datum/cyberpunk_npc_dialog_option/selected = get_dialog_option(selected_dialog)
	data["selectedText"] = selected?.text || greeting
	return data

/datum/cyberpunk_npc_profile/proc/trade_ui_data(mob/living/user)
	var/list/data = base_ui_data(user)
	var/list/items = list()
	for(var/datum/cyberpunk_npc_shop_item/item as anything in shop_items)
		items += list(item.to_ui_data())
	data["items"] = items
	data["sellable"] = get_sellable_items(user)
	return data

/datum/cyberpunk_npc_profile/proc/get_dialog_option(option_id)
	for(var/datum/cyberpunk_npc_dialog_option/option as anything in dialog_options)
		if(option.id == option_id)
			return option

/datum/cyberpunk_npc_profile/proc/get_shop_item(item_id)
	for(var/datum/cyberpunk_npc_shop_item/item as anything in shop_items)
		if(item.id == item_id)
			return item

/datum/cyberpunk_npc_profile/proc/get_service(service_id)
	for(var/datum/cyberpunk_npc_service/service as anything in services)
		if(service.id == service_id)
			return service

/datum/cyberpunk_npc_profile/proc/get_sellable_items(mob/living/user)
	var/list/sellable = list()
	if(!istype(user))
		return sellable
	for(var/obj/item/held as anything in user.held_items)
		if(!held)
			continue
		var/price = get_sell_price(held)
		if(price <= 0)
			continue
		sellable += list(list(
			"ref" = REF(held),
			"name" = held.name,
			"price" = price,
		))
	return sellable

/datum/cyberpunk_npc_profile/proc/get_sell_price(obj/item/sold_item)
	for(var/datum/cyberpunk_npc_shop_item/item as anything in shop_items)
		if(istype(sold_item, item.item_path) && item.sell_price > 0)
			return item.sell_price
	return 0

/datum/cyberpunk_npc_profile/proc/buy_item(mob/living/user, item_id)
	if(owner && !owner.cyberpunk_vendor_is_open())
		last_message = "Closed right now."
		return FALSE
	var/datum/cyberpunk_npc_shop_item/item = get_shop_item(item_id)
	if(!item)
		return FALSE
	var/result = item.buy(user, owner)
	last_message = result
	return TRUE

/datum/cyberpunk_npc_profile/proc/sell_item(mob/living/user, item_ref)
	if(owner && !owner.cyberpunk_vendor_is_open())
		last_message = "Closed right now."
		return FALSE
	var/obj/item/sold_item = locate(item_ref)
	if(!sold_item || !(sold_item in user.held_items))
		last_message = "Hold the item you want to sell."
		return FALSE
	var/price = get_sell_price(sold_item)
	if(price <= 0)
		last_message = "This trader is not buying that."
		return FALSE
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		last_message = "No account found."
		return FALSE
	account.adjust_money(price, "NPC trade: [sold_item.name]")
	qdel(sold_item)
	last_message = "Sold for [price] credits."
	return TRUE

/datum/cyberpunk_npc_profile/proc/use_service(mob/living/user, service_id)
	if(owner && !owner.cyberpunk_vendor_is_open())
		last_message = "Closed right now."
		return FALSE
	var/datum/cyberpunk_npc_service/service = get_service(service_id)
	if(!service)
		return FALSE
	last_message = service.perform(user, owner)
	return TRUE

/datum/cyberpunk_npc_dialog_option
	var/id
	var/label
	var/text

/datum/cyberpunk_npc_dialog_option/New(new_id, new_label, new_text)
	id = new_id
	label = new_label
	text = new_text

/datum/cyberpunk_npc_dialog_option/proc/to_ui_data()
	return list(
		"id" = id,
		"label" = label,
		"text" = text,
	)

/datum/cyberpunk_npc_shop_item
	var/id
	var/name
	var/description
	var/item_path
	var/category = "misc"
	var/buy_price = 100
	var/sell_price = 10
	var/stock = -1

/datum/cyberpunk_npc_shop_item/New(new_id, new_name, new_description, new_item_path, new_category, new_buy_price, new_sell_price, new_stock = -1)
	id = new_id
	name = new_name
	description = new_description
	item_path = new_item_path
	category = new_category
	buy_price = new_buy_price
	sell_price = new_sell_price
	stock = new_stock

/datum/cyberpunk_npc_shop_item/proc/to_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"category" = category,
		"buyPrice" = buy_price,
		"sellPrice" = sell_price,
		"stock" = stock,
	)

/datum/cyberpunk_npc_shop_item/proc/buy(mob/living/user, mob/living/vendor)
	if(stock == 0)
		return "Out of stock."
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		return "No account found."
	if(!account.adjust_money(-buy_price, "NPC trade: [name]"))
		return "Not enough credits."
	var/obj/item/bought = new item_path(get_turf(user))
	if(!user.put_in_hands(bought))
		bought.forceMove(get_turf(user))
	if(stock > 0)
		stock--
	return "Bought [bought.name] for [buy_price] credits."

/datum/cyberpunk_npc_service
	var/id = "service"
	var/name = "Service"
	var/description = "A city service."
	var/base_price = 0

/datum/cyberpunk_npc_service/proc/to_ui_data(mob/living/user, mob/living/vendor)
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"price" = get_price(user, vendor),
		"available" = TRUE,
	)

/datum/cyberpunk_npc_service/proc/get_price(mob/living/user, mob/living/vendor)
	return base_price

/datum/cyberpunk_npc_service/proc/perform(mob/living/user, mob/living/vendor)
	var/datum/bank_account/account = user.get_bank_account()
	var/price = get_price(user, vendor)
	if(price > 0 && (!account || !account.adjust_money(-price, "NPC service: [name]")))
		return "Not enough credits."
	return "Service queued."

/datum/cyberpunk_npc_service/healing
	id = "healing"
	name = "Treatment"
	description = "Heal damage. Body damage costs 5 credits per unit; organ damage costs 10."

/datum/cyberpunk_npc_service/healing/get_price(mob/living/user, mob/living/vendor)
	return round(user.get_total_damage() * 5 + user.get_organ_loss(ORGAN_SLOT_BRAIN) * 10)

/datum/cyberpunk_npc_service/healing/perform(mob/living/user, mob/living/vendor)
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		return "No account found."
	var/credits = account.account_balance
	var/healed_body = 0
	var/list/damage_types = list(BRUTE, BURN, TOX, OXY)
	for(var/damage_type in damage_types)
		var/damage = round(user.get_current_damage_of_type(damage_type))
		var/can_heal = min(damage, FLOOR(credits / 5, 1))
		if(can_heal <= 0)
			continue
		if(!account.adjust_money(-(can_heal * 5), "NPC treatment: body damage"))
			break
		user.heal_damage_type(can_heal, damage_type)
		credits -= can_heal * 5
		healed_body += can_heal
	var/brain_damage = round(user.get_organ_loss(ORGAN_SLOT_BRAIN))
	var/healed_organs = min(brain_damage, FLOOR(credits / 10, 1))
	if(healed_organs > 0 && account.adjust_money(-(healed_organs * 10), "NPC treatment: organ damage"))
		user.adjust_organ_loss(ORGAN_SLOT_BRAIN, -healed_organs)
	user.updatehealth()
	if(!healed_body && !healed_organs)
		return "No treatable damage or not enough credits."
	return "Treated [healed_body] body damage and [healed_organs] organ damage."

/datum/cyberpunk_npc_service/repair
	id = "repair"
	name = "Gear repair"
	description = "Repair held and worn gear. Costs 4 credits per integrity unit."

/datum/cyberpunk_npc_service/repair/proc/get_repairable_items(mob/living/user)
	var/list/items = list()
	for(var/obj/item/item as anything in user.get_equipped_items(INCLUDE_HELD|INCLUDE_POCKETS|INCLUDE_PROSTHETICS))
		if(item.max_integrity > 0 && item.get_integrity() < item.max_integrity)
			items |= item
	return items

/datum/cyberpunk_npc_service/repair/get_price(mob/living/user, mob/living/vendor)
	var/total = 0
	for(var/obj/item/item as anything in get_repairable_items(user))
		total += max(0, item.max_integrity - item.get_integrity()) * 4
	return round(total)

/datum/cyberpunk_npc_service/repair/to_ui_data(mob/living/user, mob/living/vendor)
	var/list/data = ..()
	var/list/items = list()
	for(var/obj/item/item as anything in get_repairable_items(user))
		items += list(list(
			"name" = item.name,
			"integrity" = round(item.get_integrity()),
			"maxIntegrity" = item.max_integrity,
		))
	data["items"] = items
	return data

/datum/cyberpunk_npc_service/repair/perform(mob/living/user, mob/living/vendor)
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		return "No account found."
	var/credits = account.account_balance
	var/repaired = 0
	for(var/obj/item/item as anything in get_repairable_items(user))
		var/missing = max(0, item.max_integrity - item.get_integrity())
		var/can_repair = min(missing, FLOOR(credits / 4, 1))
		if(can_repair <= 0)
			continue
		if(!account.adjust_money(-(can_repair * 4), "NPC repair: [item.name]"))
			break
		item.repair_damage(can_repair)
		credits -= can_repair * 4
		repaired += can_repair
	if(!repaired)
		return "No damaged gear or not enough credits."
	return "Repaired [repaired] integrity."

/datum/cyberpunk_npc_service/designer
	id = "designer"
	name = "Designer"
	description = "Open clothing design routing for modular clothes."
	base_price = 700

/datum/cyberpunk_npc_service/designer/perform(mob/living/user, mob/living/vendor)
	. = ..()
	if(. != "Service queued.")
		return .
	var/datum/cyberpunk_style_designer_ui/designer = new("clothing")
	designer.ui_interact(user)
	return "Designer routing paid. Clothing design module opened."

/datum/cyberpunk_npc_service/stylist
	id = "stylist"
	name = "Stylist"
	description = "Open hairstyle styling and persistent custom hair cache."
	base_price = 500

/datum/cyberpunk_npc_service/stylist/perform(mob/living/user, mob/living/vendor)
	. = ..()
	if(. != "Service queued.")
		return .
	var/datum/cyberpunk_style_designer_ui/stylist = new("hair")
	stylist.ui_interact(user)
	return "Stylist routing paid. Style module opened."

#define CYBERPUNK_STYLE_DESIGNER_HAIR "hair"
#define CYBERPUNK_STYLE_DESIGNER_CLOTHING "clothing"
#define CYBERPUNK_STYLE_DESIGNER_WARDROBE "wardrobe"
#define CYBERPUNK_CUSTOM_HAIR_NAME "Custom Hair"
#define CYBERPUNK_CUSTOM_HAIR_ICON_STATE "custom_cyberpunk_hair"
#define CYBERPUNK_ACTIVE_HAIR_DESIGN_ID "active_custom_hair"
#define CYBERPUNK_STYLE_DESIGNER_MAX_PAYLOAD 65535
#define CYBERPUNK_CUSTOM_HAIR_RAW_SAVE_KEY "cyberpunk_custom_hair_designs_raw"

/mob/living/proc/cyberpunk_prefs()
	return client?.prefs

/datum/preferences/proc/cyberpunk_read_custom_hair_designs()
	var/list/designs = read_preference(/datum/preference/cyberpunk_custom_hair_designs)
	if(LAZYLEN(designs))
		return designs
	var/list/save_data = get_save_data_for_savefile_identifier(PREFERENCE_CHARACTER)
	var/raw_designs = save_data?[CYBERPUNK_CUSTOM_HAIR_RAW_SAVE_KEY]
	if(istext(raw_designs))
		raw_designs = safe_json_decode(raw_designs)
	var/list/sanitized_raw_designs = cyberpunk_sanitize_visual_design_records(raw_designs)
	if(LAZYLEN(sanitized_raw_designs))
		write_preference(GLOB.preference_entries[/datum/preference/cyberpunk_custom_hair_designs], sanitized_raw_designs)
	return sanitized_raw_designs

/mob/living/proc/cyberpunk_read_visual_designs(preference_type)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return list()
	if(preference_type == /datum/preference/cyberpunk_custom_hair_designs)
		return preferences.cyberpunk_read_custom_hair_designs()
	return preferences.read_preference(preference_type) || list()

/mob/living/proc/cyberpunk_write_visual_designs(preference_type, list/designs)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return FALSE
	if(!preferences.write_preference(GLOB.preference_entries[preference_type], designs))
		return FALSE
	preferences.recently_updated_keys |= preference_type
	preferences.save_character()
	preferences.save_preferences()
	return TRUE

/mob/living/proc/cyberpunk_write_hair_design_and_selection(list/design, custom_hair_name)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return FALSE
	design = cyberpunk_sanitize_visual_design_record(design)
	if(!design || !custom_hair_name)
		return FALSE
	var/list/designs = cyberpunk_read_visual_designs(/datum/preference/cyberpunk_custom_hair_designs)
	var/list/result = list()
	for(var/list/existing as anything in designs)
		if(existing["id"] == design["id"])
			continue
		result += list(existing)
	result = list(design) + result
	if(!preferences.write_preference(GLOB.preference_entries[/datum/preference/cyberpunk_custom_hair_designs], result))
		return FALSE
	var/list/save_data = preferences.get_save_data_for_savefile_identifier(PREFERENCE_CHARACTER)
	if(save_data)
		save_data[CYBERPUNK_CUSTOM_HAIR_RAW_SAVE_KEY] = json_encode(result)
	if(!preferences.write_preference(GLOB.preference_entries[/datum/preference/choiced/hairstyle], custom_hair_name))
		return FALSE
	if(!preferences.write_preference(GLOB.preference_entries[/datum/preference/color/hair_color], COLOR_WHITE))
		return FALSE
	preferences.recently_updated_keys |= /datum/preference/cyberpunk_custom_hair_designs
	preferences.recently_updated_keys |= /datum/preference/choiced/hairstyle
	preferences.recently_updated_keys |= /datum/preference/color/hair_color
	preferences.character_preview_view?.update_body()
	preferences.save_character()
	preferences.save_preferences()
	return TRUE

/mob/living/proc/cyberpunk_store_visual_design(preference_type, list/design)
	design = cyberpunk_sanitize_visual_design_record(design)
	if(!design)
		return FALSE
	var/list/designs = cyberpunk_read_visual_designs(preference_type)
	var/list/result = list()
	for(var/list/existing as anything in designs)
		if(existing["id"] == design["id"])
			continue
		result += list(existing)
	result = list(design) + result
	return cyberpunk_write_visual_designs(preference_type, result)

/mob/living/proc/cyberpunk_remove_visual_design(preference_type, design_id)
	if(!design_id)
		return FALSE
	var/list/designs = cyberpunk_read_visual_designs(preference_type)
	var/list/result = list()
	var/removed = FALSE
	for(var/list/existing as anything in designs)
		if(existing["id"] == design_id)
			removed = TRUE
			continue
		result += list(existing)
	if(!removed)
		return FALSE
	return cyberpunk_write_visual_designs(preference_type, result)

/mob/living/proc/cyberpunk_wardrobe_limit()
	var/donator_level = client?.get_donator_level() || BASIC_DONATOR_LEVEL
	return 1 + max(0, donator_level)

/datum/sprite_accessory/hair/cyberpunk_custom
	name = CYBERPUNK_CUSTOM_HAIR_NAME
	icon_state = CYBERPUNK_CUSTOM_HAIR_ICON_STATE
	color_src = null
	natural_spawn = FALSE
	locked = FALSE
	var/icon/runtime_icon

/proc/cyberpunk_blank_custom_hair_icon()
	RETURN_TYPE(/icon)
	var/icon/result_icon = icon('icons/effects/effects.dmi', "nothing")
	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
		result_icon.Insert(icon('icons/effects/effects.dmi', "nothing"), CYBERPUNK_CUSTOM_HAIR_ICON_STATE, direction, 1)
	return icon(result_icon, CYBERPUNK_CUSTOM_HAIR_ICON_STATE)

/datum/sprite_accessory/hair/cyberpunk_custom/getCachedIcon(list/hair_masks)
	var/icon/cached_icon = runtime_icon ? icon(runtime_icon) : cyberpunk_blank_custom_hair_icon()
	if(LAZYLEN(hair_masks))
		for(var/datum/hair_mask/mask as anything in hair_masks)
			var/icon/mask_icon = icon(mask.icon, mask.icon_state)
			mask_icon.Shift(SOUTH, y_offset)
			cached_icon.Blend(mask_icon, ICON_ADD)
	return cached_icon

/proc/cyberpunk_visual_design_has_pixel_payload(list/design)
	if(!islist(design))
		return FALSE
	var/list/directions = design["directions"]
	if(islist(directions))
		for(var/key in list("north", "south", "east", "west"))
			if(length("[directions[key] || ""]"))
				return TRUE
	return length("[design["item_icon"] || ""]")

/proc/cyberpunk_bake_sparse_pixel_layer(payload)
	RETURN_TYPE(/icon)
	if(!istext(payload) || !length(payload))
		return null
	var/icon/layer_icon = icon('icons/effects/effects.dmi', "nothing")
	var/drew_pixel = FALSE
	for(var/pixel_entry in splittext(payload, ";"))
		var/colon_position = findtext(pixel_entry, ":")
		if(!colon_position)
			continue
		var/pixel_index = text2num(copytext(pixel_entry, 1, colon_position))
		if(isnull(pixel_index) || pixel_index < 0 || pixel_index >= 1024)
			continue
		var/color = sanitize_hexcolor(copytext(pixel_entry, colon_position + 1), include_crunch = TRUE)
		if(!color)
			continue
		var/draw_x = (pixel_index % 32) + 1
		var/draw_y = 32 - round(pixel_index / 32)
		DrawPixel(layer_icon, color, draw_x, draw_y)
		drew_pixel = TRUE
	return drew_pixel ? layer_icon : null

/proc/cyberpunk_icon_to_sparse_pixel_payload(icon/source_icon)
	if(!source_icon)
		return ""
	var/list/pixels = list()
	var/width = min(source_icon.Width(), 32)
	var/height = min(source_icon.Height(), 32)
	for(var/y in 1 to height)
		for(var/x in 1 to width)
			var/color = source_icon.GetPixel(x, 33 - y)
			if(!color || color == "#00000000")
				continue
			var/alpha = length(color) >= 9 ? copytext(color, 8, 10) : "ff"
			if(alpha == "00")
				continue
			var/pixel_index = ((y - 1) * 32) + (x - 1)
			pixels += "[pixel_index]:[copytext(color, 1, 8)]"
	return pixels.Join(";")

/proc/cyberpunk_bake_directional_pixel_icon(list/directions, icon/base_icon, target_icon_state = CYBERPUNK_CUSTOM_HAIR_ICON_STATE)
	RETURN_TYPE(/icon)
	if(!islist(directions) && !base_icon)
		return null
	var/icon/result_icon = icon('icons/effects/effects.dmi', "nothing")
	var/has_content = FALSE
	var/static/list/direction_map = list(
		"north" = NORTH,
		"south" = SOUTH,
		"east" = EAST,
		"west" = WEST,
	)
	for(var/key in direction_map)
		var/icon/direction_icon = icon('icons/effects/effects.dmi', "nothing")
		if(base_icon)
			var/icon/base_direction_icon = icon(base_icon, target_icon_state, direction_map[key], 1)
			if(base_direction_icon)
				direction_icon.Blend(base_direction_icon, ICON_OVERLAY)
				has_content = TRUE
		var/icon/layer_icon = cyberpunk_bake_sparse_pixel_layer(islist(directions) ? directions[key] : null)
		if(layer_icon)
			direction_icon.Blend(layer_icon, ICON_OVERLAY)
			has_content = TRUE
		result_icon.Insert(direction_icon, target_icon_state, direction_map[key], 1)
	return has_content ? result_icon : null

/proc/cyberpunk_bake_item_pixel_icon(payload, icon/base_icon)
	RETURN_TYPE(/icon)
	var/icon/layer_icon = cyberpunk_bake_sparse_pixel_layer(payload)
	if(!base_icon)
		return layer_icon
	var/icon/result_icon = icon(base_icon)
	if(layer_icon)
		result_icon.Blend(layer_icon, ICON_OVERLAY)
	return result_icon

/proc/cyberpunk_base_hair_icon(base_hair_name)
	RETURN_TYPE(/icon)
	if(!(base_hair_name in SSaccessories.hairstyles_list))
		return null
	var/datum/sprite_accessory/hair/base_hair = SSaccessories.hairstyles_list[base_hair_name]
	if(!istype(base_hair))
		return null
	var/icon/base_icon = icon('icons/effects/effects.dmi', "nothing")
	var/icon/raw_hair_icon
	if(base_hair.icon_state != SPRITE_ACCESSORY_NONE)
		raw_hair_icon = icon(base_hair.getCachedIcon(null))
	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
		var/icon/base_direction_icon = icon('icons/effects/effects.dmi', "nothing")
		if(raw_hair_icon)
			base_direction_icon.Blend(icon(raw_hair_icon, "", direction, 1), ICON_OVERLAY)
		base_icon.Insert(base_direction_icon, CYBERPUNK_CUSTOM_HAIR_ICON_STATE, direction, 1)
	return base_icon

/proc/cyberpunk_resolve_hair_base(base_hair_name, list/designs)
	if(!(base_hair_name in SSaccessories.hairstyles_list) || !islist(designs))
		return base_hair_name
	for(var/list/design as anything in cyberpunk_sanitize_visual_design_records(designs))
		if(design["id"] != CYBERPUNK_ACTIVE_HAIR_DESIGN_ID)
			continue
		var/record_base = design["base"]
		if(record_base && record_base != base_hair_name)
			return cyberpunk_resolve_hair_base(record_base, designs)
	if(base_hair_name == CYBERPUNK_CUSTOM_HAIR_NAME)
		return /datum/sprite_accessory/hair/bald::name
	return base_hair_name

/proc/cyberpunk_ensure_custom_hair_accessory()
	RETURN_TYPE(/datum/sprite_accessory/hair/cyberpunk_custom)
	var/datum/sprite_accessory/hair/cyberpunk_custom/accessory = SSaccessories.hairstyles_list[CYBERPUNK_CUSTOM_HAIR_NAME]
	if(!istype(accessory))
		accessory = new
		accessory.name = CYBERPUNK_CUSTOM_HAIR_NAME
		SSaccessories.hairstyles_list[CYBERPUNK_CUSTOM_HAIR_NAME] = accessory
	accessory.locked = FALSE
	accessory.natural_spawn = FALSE
	if(!accessory.runtime_icon)
		accessory.runtime_icon = cyberpunk_blank_custom_hair_icon()
	return accessory

/proc/cyberpunk_register_custom_hair_design(list/design)
	design = cyberpunk_sanitize_visual_design_record(design)
	if(!design)
		return null
	if(design["id"] != CYBERPUNK_ACTIVE_HAIR_DESIGN_ID)
		return null
	var/icon/base_hair_icon = cyberpunk_base_hair_icon(design["base"])
	if(base_hair_icon && design["greyscale_colors"])
		var/base_hair_color = sanitize_hexcolor(design["greyscale_colors"])
		if(base_hair_color)
			base_hair_icon.Blend(base_hair_color, ICON_MULTIPLY)
	var/icon/hair_icon = cyberpunk_bake_directional_pixel_icon(design["directions"], base_hair_icon)
	if(!hair_icon)
		return null
	var/datum/sprite_accessory/hair/cyberpunk_custom/accessory = cyberpunk_ensure_custom_hair_accessory()
	accessory.runtime_icon = icon(hair_icon, CYBERPUNK_CUSTOM_HAIR_ICON_STATE)
	return CYBERPUNK_CUSTOM_HAIR_NAME

/datum/preference/choiced/hairstyle/proc/cyberpunk_add_runtime_hairstyle(hairstyle_name)
	if(!hairstyle_name)
		return
	var/list/choices = get_choices()
	if(!(hairstyle_name in choices))
		choices += hairstyle_name

/proc/cyberpunk_register_custom_hair_designs(list/designs)
	var/last_hair_name
	var/list/sanitized_designs = cyberpunk_sanitize_visual_design_records(designs)
	for(var/list/design as anything in sanitized_designs)
		design["base"] = cyberpunk_resolve_hair_base(design["base"], sanitized_designs)
		last_hair_name = cyberpunk_register_custom_hair_design(design) || last_hair_name
	return last_hair_name

/mob/living/proc/cyberpunk_apply_hair_design(list/design)
	var/mob/living/carbon/human/human = src
	if(!istype(human))
		return FALSE
	design = cyberpunk_sanitize_visual_design_record(design)
	if(!design)
		return FALSE
	var/custom_hair_name = cyberpunk_register_custom_hair_design(design)
	if(custom_hair_name)
		human.set_haircolor(COLOR_WHITE, update = FALSE)
		human.set_hairstyle(custom_hair_name, update = FALSE)
		human.update_hair()
		human.update_body()
		human.cyberpunk_write_hair_design_and_selection(design, custom_hair_name)
		return TRUE
	var/base = design["base"]
	if(base && (base in SSaccessories.hairstyles_list))
		human.set_hairstyle(base, update = FALSE)
	if(design["greyscale_colors"])
		human.set_haircolor(sanitize_hexcolor(design["greyscale_colors"]))
	human.update_hair()
	return TRUE

/mob/living/proc/cyberpunk_apply_clothing_design(list/design)
	var/obj/item/clothing/clothing = cyberpunk_find_designable_clothing(design?["target_ref"])
	if(!istype(clothing))
		return FALSE
	return clothing.cyberpunk_apply_design(design)

/mob/living/proc/cyberpunk_find_designable_clothing(item_ref)
	RETURN_TYPE(/obj/item/clothing)
	var/obj/item/clothing/fallback
	for(var/obj/item/item as anything in get_equipped_items(INCLUDE_HELD|INCLUDE_POCKETS))
		var/obj/item/clothing/clothing = item
		if(!istype(clothing))
			continue
		if(!fallback || clothing == get_active_held_item())
			fallback = clothing
		if(item_ref && REF(clothing) == item_ref)
			return clothing
	return fallback

/mob/living/proc/cyberpunk_get_designable_clothing_ui()
	var/list/items = list()
	for(var/obj/item/item as anything in get_equipped_items(INCLUDE_HELD|INCLUDE_POCKETS))
		var/obj/item/clothing/clothing = item
		if(!istype(clothing))
			continue
		var/icon/item_preview_icon = icon(clothing.icon, clothing.icon_state, frame = 1)
		var/list/worn_previews = list()
		var/list/worn_payloads = list()
		var/static/list/direction_map = list(
			"north" = NORTH,
			"south" = SOUTH,
			"east" = EAST,
			"west" = WEST,
		)
		for(var/key in direction_map)
			var/icon/worn_preview_icon
			if(clothing.worn_icon && clothing.worn_icon_state)
				worn_preview_icon = icon(clothing.worn_icon, clothing.worn_icon_state, direction_map[key], 1)
			else
				worn_preview_icon = icon(item_preview_icon, "", direction_map[key], 1)
			worn_previews[key] = icon2base64(worn_preview_icon)
			worn_payloads[key] = cyberpunk_icon_to_sparse_pixel_payload(worn_preview_icon)
		items += list(list(
			"ref" = REF(clothing),
			"name" = clothing.name,
			"typePath" = "[clothing.type]",
			"active" = clothing == get_active_held_item(),
			"modular" = clothing.cyberpunk_is_modular_clothing(),
			"greyscaleColors" = clothing.greyscale_colors || "",
			"iconState" = clothing.cyberpunk_base_icon_state || clothing.icon_state || "",
			"wornIconState" = clothing.cyberpunk_base_worn_icon_state || clothing.worn_icon_state || "",
			"itemPreview" = icon2base64(item_preview_icon),
			"wornPreviews" = worn_previews,
			"itemPayload" = cyberpunk_icon_to_sparse_pixel_payload(item_preview_icon),
			"wornPayloads" = worn_payloads,
		))
	return items

/mob/living/proc/cyberpunk_create_clothing_design_from_active(list/params)
	var/obj/item/clothing/clothing = cyberpunk_find_designable_clothing(params["targetRef"])
	if(!istype(clothing))
		return null
	var/list/design = clothing.cyberpunk_capture_wardrobe_design()
	design["target_ref"] = REF(clothing)
	design["id"] = params["id"] || design["id"]
	design["name"] = copytext_char(trim("[params["name"] || clothing.name]"), 1, MAX_NAME_LEN)
	design["kind"] = "clothing"
	design["icon_state"] = copytext_char(trim("[params["iconState"] || clothing.icon_state]"), 1, 96)
	design["worn_icon_state"] = copytext_char(trim("[params["wornIconState"] || clothing.worn_icon_state]"), 1, 96)
	design["greyscale_colors"] = copytext_char(trim("[params["greyscaleColors"] || clothing.greyscale_colors || ""]"), 1, 256)
	design["item_icon"] = copytext_char("[params["itemIcon"] || ""]", 1, CYBERPUNK_STYLE_DESIGNER_MAX_PAYLOAD)
	design["directions"] = cyberpunk_style_designer_directions_from_params(params)
	return cyberpunk_sanitize_visual_design_record(design)

/mob/living/proc/cyberpunk_store_active_clothing_in_wardrobe()
	var/obj/item/clothing/clothing = get_active_held_item()
	if(!istype(clothing))
		return "Hold modular clothing in your active hand."
	if(!clothing.cyberpunk_is_modular_clothing())
		return "This clothing is not modular enough for wardrobe storage."
	var/list/designs = cyberpunk_read_visual_designs(/datum/preference/cyberpunk_wardrobe_designs)
	var/limit = cyberpunk_wardrobe_limit()
	if(length(designs) >= limit)
		return "Wardrobe capacity reached ([length(designs)]/[limit]). Remove a saved item first."
	var/list/design = clothing.cyberpunk_capture_wardrobe_design()
	if(!cyberpunk_store_visual_design(/datum/preference/cyberpunk_wardrobe_designs, design))
		return "Unable to write wardrobe data."
	qdel(clothing)
	return "Wardrobe design stored ([length(designs) + 1]/[limit]). Hardware modules and inserts were not preserved."

/mob/living/proc/cyberpunk_extract_wardrobe_design(design_id)
	var/list/design = cyberpunk_find_design_by_id(cyberpunk_read_visual_designs(/datum/preference/cyberpunk_wardrobe_designs), design_id)
	if(!design)
		return "Wardrobe record not found."
	var/item_type = text2path(design["type_path"])
	if(!ispath(item_type, /obj/item/clothing))
		return "Wardrobe record has no valid clothing type."
	var/obj/item/clothing/clothing = new item_type(get_turf(src))
	clothing.cyberpunk_apply_design(design)
	if(!put_in_hands(clothing))
		clothing.forceMove(get_turf(src))
	return "Extracted [clothing.name]."

/mob/living/proc/cyberpunk_store_loadout_item_type_in_round_wardrobe(item_type, amount = 1)
	if(!ispath(item_type, /obj/item))
		return FALSE
	var/amount_number = text2num("[amount]")
	if(isnull(amount_number) || amount_number < 1)
		amount_number = 1
	amount_number = FLOOR(amount_number, 1)
	if(isnull(cyberpunk_round_wardrobe_items))
		cyberpunk_round_wardrobe_items = list()
	var/type_text = "[item_type]"
	for(var/list/existing as anything in cyberpunk_round_wardrobe_items)
		if(existing["type_path"] != type_text)
			continue
		existing["count"] = (text2num("[existing["count"]]") || 0) + amount_number
		return TRUE
	var/obj/item/preview_item = new item_type(null)
	var/item_name = preview_item?.name || type_text
	qdel(preview_item)
	cyberpunk_round_wardrobe_items += list(list(
		"id" = "loadout_[length(cyberpunk_round_wardrobe_items) + 1]_[world.time]_[rand(1000, 9999)]",
		"name" = item_name,
		"kind" = "loadout",
		"type_path" = type_text,
		"count" = amount_number,
	))
	return TRUE

/mob/living/proc/cyberpunk_extract_round_wardrobe_item(record_id)
	if(!record_id || !length(cyberpunk_round_wardrobe_items))
		return "Loadout wardrobe record not found."
	for(var/list/record as anything in cyberpunk_round_wardrobe_items)
		if(record["id"] != record_id)
			continue
		var/item_type = text2path(record["type_path"])
		if(!ispath(item_type, /obj/item))
			return "Loadout wardrobe record has no valid item type."
		var/obj/item/extracted = new item_type(get_turf(src))
		if(!put_in_hands(extracted))
			extracted.forceMove(get_turf(src))
		var/count = text2num("[record["count"]]")
		if(isnull(count) || count <= 1)
			cyberpunk_round_wardrobe_items -= record
		else
			record["count"] = count - 1
		return "Extracted [extracted.name]."
	return "Loadout wardrobe record not found."

/proc/cyberpunk_style_designer_directions_from_params(list/params)
	var/list/directions = list()
	for(var/key in list("north", "south", "east", "west"))
		directions[key] = copytext_char("[params[key] || ""]", 1, CYBERPUNK_STYLE_DESIGNER_MAX_PAYLOAD)
	return directions

/datum/cyberpunk_style_designer_ui
	var/mode = CYBERPUNK_STYLE_DESIGNER_HAIR
	var/last_message

/datum/cyberpunk_style_designer_ui/New(new_mode)
	mode = new_mode || CYBERPUNK_STYLE_DESIGNER_HAIR

/datum/cyberpunk_style_designer_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_style_designer_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkStyleDesigner")
		ui.open()

/datum/cyberpunk_style_designer_ui/ui_close(mob/user)
	qdel(src)

/datum/cyberpunk_style_designer_ui/ui_data(mob/user)
	var/mob/living/living_user = user
	var/list/hair_designs = istype(living_user) ? living_user.cyberpunk_read_visual_designs(/datum/preference/cyberpunk_custom_hair_designs) : list()
	var/list/wardrobe_designs = istype(living_user) ? living_user.cyberpunk_read_visual_designs(/datum/preference/cyberpunk_wardrobe_designs) : list()
	var/list/round_wardrobe_items = istype(living_user) ? (living_user.cyberpunk_round_wardrobe_items || list()) : list()
	var/mob/living/carbon/human/human = user
	var/list/current_hair_previews = list()
	var/list/current_hair_payloads = list()
	if(istype(human))
		var/datum/sprite_accessory/hair/hair_accessory = SSaccessories.hairstyles_list[human.hairstyle]
		if(istype(hair_accessory))
			if(istype(hair_accessory, /datum/sprite_accessory/hair/cyberpunk_custom))
				cyberpunk_register_custom_hair_designs(hair_designs)
			var/icon/full_hair_icon = icon(hair_accessory.getCachedIcon(null))
			var/static/list/direction_map = list(
				"north" = NORTH,
				"south" = SOUTH,
				"east" = EAST,
				"west" = WEST,
			)
			for(var/key in direction_map)
				var/icon/hair_icon = icon(full_hair_icon, "", direction_map[key], 1)
				if(human.hair_color)
					hair_icon.Blend(human.hair_color, ICON_MULTIPLY)
				current_hair_previews[key] = icon2base64(hair_icon)
				current_hair_payloads[key] = cyberpunk_icon_to_sparse_pixel_payload(hair_icon)
	return list(
		"mode" = mode,
		"lastMessage" = last_message,
		"hairDesigns" = hair_designs,
		"wardrobeDesigns" = wardrobe_designs,
		"roundWardrobeItems" = round_wardrobe_items,
		"wardrobeLimit" = istype(living_user) ? living_user.cyberpunk_wardrobe_limit() : 1,
		"wardrobeCount" = length(wardrobe_designs),
		"clothingItems" = istype(living_user) ? living_user.cyberpunk_get_designable_clothing_ui() : list(),
		"currentHair" = istype(human) ? human.hairstyle : "",
		"currentHairColor" = istype(human) ? human.hair_color : "",
		"currentHairPreviews" = current_hair_previews,
		"currentHairPayloads" = current_hair_payloads,
		"editableHairBase" = /datum/sprite_accessory/hair/bald::name,
	)

/datum/cyberpunk_style_designer_ui/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!istype(user))
		return TRUE
	switch(action)
		if("save_hair")
			var/list/existing_hair_designs = user.cyberpunk_read_visual_designs(/datum/preference/cyberpunk_custom_hair_designs)
			var/list/design = list(
				"id" = params["id"] || CYBERPUNK_ACTIVE_HAIR_DESIGN_ID,
				"name" = copytext_char(trim("[params["name"] || "custom hair"]"), 1, MAX_NAME_LEN),
				"kind" = "hair",
				"base" = copytext_char(trim("[cyberpunk_resolve_hair_base(params["base"], existing_hair_designs) || ""]"), 1, MAX_NAME_LEN),
				"greyscale_colors" = copytext_char(trim("[params["greyscaleColors"] || ""]"), 1, 256),
				"directions" = cyberpunk_style_designer_directions_from_params(params),
				"item_icon" = copytext_char("[params["itemIcon"] || ""]", 1, CYBERPUNK_STYLE_DESIGNER_MAX_PAYLOAD),
			)
			if(user.cyberpunk_store_visual_design(/datum/preference/cyberpunk_custom_hair_designs, design))
				user.cyberpunk_apply_hair_design(design)
				last_message = "Hair design saved and applied."
			else
				last_message = "Unable to save hair design."
		if("apply_hair")
			var/list/design = cyberpunk_find_design_by_id(user.cyberpunk_read_visual_designs(/datum/preference/cyberpunk_custom_hair_designs), params["id"])
			if(design && user.cyberpunk_apply_hair_design(design))
				last_message = "Hair design applied."
			else
				last_message = "Unable to apply hair design."
		if("save_clothing")
			var/list/design = user.cyberpunk_create_clothing_design_from_active(params)
			if(design && user.cyberpunk_apply_clothing_design(design))
				last_message = "Clothing design applied to active item. Use a wardrobe terminal to persist it."
			else
				last_message = "Hold a clothing item in your active hand."
		if("apply_clothing")
			var/list/design = cyberpunk_find_design_by_id(user.cyberpunk_read_visual_designs(/datum/preference/cyberpunk_wardrobe_designs), params["id"])
			if(design && user.cyberpunk_apply_clothing_design(design))
				last_message = "Clothing design applied to active item."
			else
				last_message = "Hold clothing in your active hand."
		if("store_wardrobe")
			last_message = user.cyberpunk_store_active_clothing_in_wardrobe()
		if("extract_wardrobe")
			last_message = user.cyberpunk_extract_wardrobe_design(params["id"])
		if("extract_round_wardrobe")
			last_message = user.cyberpunk_extract_round_wardrobe_item(params["id"])
		if("remove_wardrobe")
			if(user.cyberpunk_remove_visual_design(/datum/preference/cyberpunk_wardrobe_designs, params["id"]))
				last_message = "Wardrobe record removed."
			else
				last_message = "Wardrobe record not found."
	return TRUE

/proc/cyberpunk_find_design_by_id(list/designs, id)
	for(var/list/design as anything in designs)
		if(design["id"] == id)
			return design
	return null

#undef CYBERPUNK_STYLE_DESIGNER_HAIR
#undef CYBERPUNK_STYLE_DESIGNER_CLOTHING
#undef CYBERPUNK_STYLE_DESIGNER_WARDROBE
#undef CYBERPUNK_CUSTOM_HAIR_NAME
#undef CYBERPUNK_CUSTOM_HAIR_ICON_STATE
#undef CYBERPUNK_ACTIVE_HAIR_DESIGN_ID
#undef CYBERPUNK_STYLE_DESIGNER_MAX_PAYLOAD
#undef CYBERPUNK_CUSTOM_HAIR_RAW_SAVE_KEY

/datum/cyberpunk_npc_dialog_ui
	var/datum/cyberpunk_npc_profile/profile

/datum/cyberpunk_npc_dialog_ui/New(datum/cyberpunk_npc_profile/new_profile)
	profile = new_profile

/datum/cyberpunk_npc_dialog_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_npc_dialog_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkNpcDialog")
		ui.open()

/datum/cyberpunk_npc_dialog_ui/ui_close(mob/user)
	qdel(src)

/datum/cyberpunk_npc_dialog_ui/ui_data(mob/user)
	return profile?.dialog_ui_data(user) || list()

/datum/cyberpunk_npc_dialog_ui/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!profile?.owner?.cyberpunk_can_talk_to_npc(user))
		return TRUE
	switch(action)
		if("select_dialog")
			profile.selected_dialog = params["id"]
		if("service")
			profile.use_service(user, params["id"])
		if("trade")
			profile.open_trade(user)
	return TRUE

/datum/cyberpunk_npc_trade_ui
	var/datum/cyberpunk_npc_profile/profile

/datum/cyberpunk_npc_trade_ui/New(datum/cyberpunk_npc_profile/new_profile)
	profile = new_profile

/datum/cyberpunk_npc_trade_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_npc_trade_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkNpcTrade")
		ui.open()

/datum/cyberpunk_npc_trade_ui/ui_close(mob/user)
	qdel(src)

/datum/cyberpunk_npc_trade_ui/ui_data(mob/user)
	return profile?.trade_ui_data(user) || list()

/datum/cyberpunk_npc_trade_ui/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!profile?.owner?.cyberpunk_can_talk_to_npc(user))
		return TRUE
	switch(action)
		if("buy")
			profile.buy_item(user, params["id"])
		if("sell")
			profile.sell_item(user, params["ref"])
		if("dialog")
			profile.open_dialog(user)
	return TRUE
// CYBERPUNK BUILD - rebuild and delete before release

/mob/living/toggle_resting()
	set_resting(!resting, FALSE)


///Proc to hook behavior to the change of value in the resting variable.
/mob/living/set_resting(new_resting, silent = TRUE, instant = FALSE)
	if(!(mobility_flags & MOBILITY_REST))
		return
	if(new_resting == resting)
		return

	. = resting
	resting = new_resting
	if(new_resting)
		if(body_position == LYING_DOWN)
			if(!silent)
				to_chat(src, span_notice("Вы будете пытаться лежать на полу."))
		else if(HAS_TRAIT(src, TRAIT_FORCED_STANDING) || (buckled && buckled.buckle_lying != NO_BUCKLE_LYING))
			if(!silent)
				to_chat(src, span_notice("Вы ляжете на пол как только это станет возможным."))
		else
			if(!silent)
				to_chat(src, span_notice("Вы ложитесь."))
			set_lying_down()
	else
		if(body_position == STANDING_UP)
			if(!silent)
				to_chat(src, span_notice("Вы будете пытаться встать с пола."))
		else if(HAS_TRAIT(src, TRAIT_FLOORED) || (buckled && buckled.buckle_lying != NO_BUCKLE_LYING))
			if(!silent)
				to_chat(src, span_notice("Вы встанете с пола как только это станет возможным."))
		else
			if(!silent)
				to_chat(src, span_notice("Вы встаете."))
			get_up(instant)

	SEND_SIGNAL(src, COMSIG_LIVING_RESTING, new_resting, silent, instant)
	update_resting()


/// Proc to append and redefine behavior to the change of the [/mob/living/var/resting] variable.
/mob/living/update_resting()
	update_rest_hud_icon()


/mob/living/get_up(instant = FALSE)
	set waitfor = FALSE

	var/get_up_time = 1 SECONDS

	var/obj/item/organ/cyberimp/chest/spine/potential_spine = get_cyberpunk_spine_implant()
	if(istype(potential_spine))
		get_up_time *= potential_spine.athletics_boost_multiplier
	get_up_time = get_cyberpunk_acrobatics_get_up_duration(get_up_time)

	if(!instant && !do_after(src, get_up_time, src, timed_action_flags = (IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM), extra_checks = CALLBACK(src, TYPE_PROC_REF(/mob/living, rest_checks_callback)), interaction_key = DOAFTER_SOURCE_GETTING_UP, hidden = TRUE))
		return
	if(resting || body_position == STANDING_UP || HAS_TRAIT(src, TRAIT_FLOORED))
		return
	set_body_position(STANDING_UP)
	set_lying_angle(0)


/mob/living/rest_checks_callback()
	if(resting || body_position == STANDING_UP || HAS_TRAIT(src, TRAIT_FLOORED))
		return FALSE
	return TRUE


/// Change the [body_position] to [LYING_DOWN] and update associated behavior.
/mob/living/set_lying_down(new_lying_angle)
	set_body_position(LYING_DOWN)
	if(body_position != LYING_DOWN)
		return
	if(new_lying_angle)
		set_lying_angle(new_lying_angle)
	else if(!lying_angle && rotate_on_lying)
		if(buckled && buckled.buckle_lying != NO_BUCKLE_LYING)
			set_lying_angle(buckled.buckle_lying)
		else
			set_lying_angle(pick(LYING_ANGLE_EAST, LYING_ANGLE_WEST))

/// Proc to append behavior related to lying down.
/mob/living/on_lying_down(new_lying_angle)
	if(layer == initial(layer)) //to avoid things like hiding larvas.
		layer = LYING_MOB_LAYER //so mob lying always appear behind standing mobs
	add_traits(list(TRAIT_UI_BLOCKED, TRAIT_PULL_BLOCKED, TRAIT_UNDENSE), LYING_DOWN_TRAIT)
	if(HAS_TRAIT(src, TRAIT_FLOORED) && !(dir & (NORTH|SOUTH)))
		setDir(pick(NORTH, SOUTH)) // We are and look helpless.
	if(rotate_on_lying)
		add_offsets(LYING_DOWN_TRAIT, y_add = PIXEL_Y_OFFSET_LYING)

/// Proc to append behavior related to lying down.
/mob/living/on_standing_up()
	if(stealth_cover)
		stealth_cover = null
		chameleon_cap = STEALTH_CHAMELEON_MAX
		restore_stealth_cover_layer()
		update_stealth_chameleon()
	if(layer == LYING_MOB_LAYER)
		layer = initial(layer)
	remove_traits(list(TRAIT_UI_BLOCKED, TRAIT_PULL_BLOCKED, TRAIT_UNDENSE), LYING_DOWN_TRAIT)
	remove_offsets(LYING_DOWN_TRAIT)

/mob/living/update_density()
	if(HAS_TRAIT(src, TRAIT_UNDENSE))
		set_density(FALSE)
	else
		set_density(TRUE)

/mob/living/update_rest_hud_icon()
	. = ..()
	if(!. || !hud_used)
		return FALSE

	var/atom/movable/screen/sleep/sleep_icon = hud_used.screen_objects[HUD_MOB_SLEEP]
	if(!sleep_icon || HAS_TRAIT(src, TRAIT_SLEEPIMMUNE))
		return TRUE

	if(resting || HAS_TRAIT(src, TRAIT_FLOORED))
		sleep_icon.RemoveInvisibility(INVISIBILITY_SOURCE_SLEEP_HUD_BUTTON)
	else
		sleep_icon.SetInvisibility(INVISIBILITY_ABSTRACT, INVISIBILITY_SOURCE_SLEEP_HUD_BUTTON)
	return TRUE

//Recursive function to find everything a mob is holding. Really shitty proc tbh.
/mob/living/get_contents()
	var/list/ret = list()
	ret |= contents //add our contents
	for(var/atom/iter_atom as anything in ret) //iterate storage objects
		ret |= iter_atom.atom_storage?.return_inv()
	for(var/obj/item/folder/folder in ret) //very snowflakey-ly iterate folders
		ret |= folder.contents
	return ret

/**
 * Returns whether or not the mob can be injected. Should not perform any side effects.
 *
 * Arguments:
 * * user - The user trying to inject the mob.
 * * target_zone - The zone being targeted.
 * * injection_flags - A bitflag for extra properties to check.
 *   Check __DEFINES/injection.dm for more details, specifically the ones prefixed INJECT_CHECK_*.
 */
/mob/living/can_inject(mob/user, target_zone, injection_flags)
	return TRUE

/**
 * Like can_inject, but it can perform side effects.
 *
 * Arguments:
 * * user - The user trying to inject the mob.
 * * target_zone - The zone being targeted.
 * * injection_flags - A bitflag for extra properties to check. Check __DEFINES/injection.dm for more details.
 *   Check __DEFINES/injection.dm for more details. Unlike can_inject, the INJECT_TRY_* defines will behave differently.
 */
/mob/living/try_inject(mob/user, target_zone, injection_flags)
	return can_inject(user, target_zone, injection_flags)

/mob/living/is_injectable(mob/user, allowmobs = TRUE)
	return (allowmobs && reagents && can_inject(user))

/mob/living/is_drawable(mob/user, allowmobs = TRUE)
	return (allowmobs && reagents && can_inject(user))


///Sets the current mob's health value. Do not call directly if you don't know what you are doing, use the damage procs, instead.
/mob/living/set_health(new_value)
	. = health
	health = new_value


/mob/living/updatehealth()
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	set_health(maxHealth - get_oxy_loss() - get_tox_loss() - get_fire_loss() - get_brute_loss())
	update_stat()
	med_hud_set_health()
	med_hud_set_status()
	update_health_hud()
	update_stamina()
	SEND_SIGNAL(src, COMSIG_LIVING_HEALTH_UPDATE)

/mob/living/update_health_hud()
	var/severity = 0
	var/healthpercent = (health/maxHealth) * 100
	var/atom/movable/screen/healthdoll/living/livingdoll = hud_used?.screen_objects[HUD_MOB_HEALTHDOLL]
	if(istype(livingdoll)) //to really put you in the boots of a simplemob
		switch(healthpercent)
			if(100 to INFINITY)
				severity = 0
			if(80 to 100)
				severity = 1
			if(60 to 80)
				severity = 2
			if(40 to 60)
				severity = 3
			if(20 to 40)
				severity = 4
			if(1 to 20)
				severity = 5
			else
				severity = 6
		livingdoll.icon_state = "living[severity]"
		if(!livingdoll.filtered)
			livingdoll.filtered = TRUE
			var/icon/mob_mask = icon(icon, icon_state)
			if(get_cached_height() > ICON_SIZE_Y || get_cached_width() > ICON_SIZE_X)
				var/health_doll_icon_state = health_doll_icon ? health_doll_icon : "megasprite"
				mob_mask = icon('icons/hud/screen_gen.dmi', health_doll_icon_state) //swap to something generic if they have no special doll
			livingdoll.add_filter("mob_shape_mask", 1, alpha_mask_filter(icon = mob_mask))
			livingdoll.add_filter("inset_drop_shadow", 2, drop_shadow_filter(size = -1))
		livingdoll.health_overlay.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative'>[round(healthpercent, 1)]%</div>")

	if(severity > 0)
		overlay_fullscreen("brute", /atom/movable/screen/fullscreen/brute, severity)
	else
		clear_fullscreen("brute")

/**
 * Proc used to resuscitate a mob, bringing them back to life.
 *
 * Note that, even if a mob cannot be revived, the healing from this proc will still be applied.
 *
 * Arguments
 * * full_heal_flags - Optional. If supplied, [/mob/living/fully_heal] will be called with these flags before revival.
 * * excess_healing - Optional. If supplied, this number will be used to apply a bit of healing to the mob. Currently, 1 "excess healing" translates to -1 oxyloss, -1 toxloss, +2 blood, -5 to all organ damage.
 * * force_grab_ghost - We grab the ghost of the mob on revive. If TRUE, we force grab the ghost (includes suiciders). If FALSE, we do not. See [/mob/grab_ghost].
 *
 */
/mob/living/revive(full_heal_flags = NONE, excess_healing = 0, force_grab_ghost = FALSE)
	if(QDELETED(src))
		// Bro just like, don't ok
		return FALSE
	if(excess_healing)
		adjust_oxy_loss(-excess_healing, updating_health = FALSE)
		adjust_tox_loss(-excess_healing, updating_health = FALSE, forced = TRUE) //slime friendly
		updatehealth()

	grab_ghost(force_grab_ghost)
	if(full_heal_flags)
		fully_heal(full_heal_flags)

	if(stat == DEAD && can_be_revived()) //in some cases you can't revive (e.g. no brain)
		set_suicide(FALSE)
		set_stat(UNCONSCIOUS) //the mob starts unconscious,
		updatehealth() //then we check if the mob should wake up.
		if(full_heal_flags & HEAL_ADMIN)
			get_up(TRUE)
		update_sight()
		clear_alert(ALERT_NOT_ENOUGH_OXYGEN)
		reload_fullscreen()
		. = TRUE
		if(excess_healing)
			INVOKE_ASYNC(src, PROC_REF(emote), "gasp")
			log_combat(src, src, "revived")

	else if(full_heal_flags & HEAL_ADMIN)
		updatehealth()
		get_up(TRUE)

	// The signal is called after everything else so components can properly check the updated values
	SEND_SIGNAL(src, COMSIG_LIVING_REVIVE, full_heal_flags)

/**
 * Heals up the mob up to [heal_to] of the main damage types.
 * EX: If heal_to is 50, and they have 150 brute damage, they will heal 100 brute (up to 50 brute damage)
 *
 * If the target is dead, also revives them and heals their organs / restores blood.
 * If we have a [revive_message], play a visible message if the revive was successful.
 *
 * Arguments
 * * heal_to - the health threshold to heal the mob up to for each of the main damage types.
 * * revive_message - if provided, a visible message to show on a successful revive.
 *
 * Returns TRUE if the mob is alive afterwards, or FALSE if they're still dead (revive failed).
 */
/mob/living/heal_and_revive(heal_to = 50, revive_message)

	// Heal their brute and burn up to the threshold we're looking for
	var/brute_to_heal = heal_to - get_brute_loss()
	var/burn_to_heal = heal_to - get_fire_loss()
	var/oxy_to_heal = heal_to - get_oxy_loss()
	var/tox_to_heal = heal_to - get_tox_loss()
	if(brute_to_heal < 0)
		adjust_brute_loss(brute_to_heal, updating_health = FALSE)
	if(burn_to_heal < 0)
		adjust_fire_loss(burn_to_heal, updating_health = FALSE)
	if(oxy_to_heal < 0)
		adjust_oxy_loss(oxy_to_heal, updating_health = FALSE)
	if(tox_to_heal < 0)
		adjust_tox_loss(tox_to_heal, updating_health = FALSE, forced = TRUE)

	// Run updatehealth once to set health for the revival check
	updatehealth()

	// We've given them a decent heal.
	// If they happen to be dead too, try to revive them - if possible.
	if(stat == DEAD && can_be_revived())
		// If the revive is successful, show our revival message (if present).
		if(revive(excess_healing = 10) && revive_message)
			visible_message(revive_message)

	// Finally update health again after we're all done
	updatehealth()

	return stat != DEAD

/**
 * A grand proc used whenever this mob is, quote, "fully healed".
 * Fully healed could mean a number of things, such as "healing all the main damage types", "healing all the organs", etc
 * So, you can pass flags to specify
 *
 * See [mobs.dm] for more information on the flags
 *
 * If you ever think "hey I'm adding something and want it to be reverted on full heal",
 * consider handling it via signal instead of implementing it in this proc
 */
/mob/living/fully_heal(heal_flags = HEAL_ALL)

	if(heal_flags & HEAL_TOX)
		set_tox_loss(0, updating_health = FALSE, forced = TRUE)
	if(heal_flags & HEAL_OXY)
		set_oxy_loss(0, updating_health = FALSE, forced = TRUE)
	if(heal_flags & HEAL_BRUTE)
		set_brute_loss(0, updating_health = FALSE, forced = TRUE)
	if(heal_flags & HEAL_BURN)
		set_fire_loss(0, updating_health = FALSE, forced = TRUE)
	if(heal_flags & HEAL_STAM)
		set_stamina_loss(0, updating_stamina = FALSE, forced = TRUE)

	// I don't really care to keep this under a flag
	set_nutrition(NUTRITION_LEVEL_FED + 50)
	overeatduration = 0
	satiety = NEED_LEVEL_DEFAULT

	// These should be tracked by status effects
	losebreath = 0
	set_disgust(0)
	cure_husk()

	if(heal_flags & HEAL_TEMP)
		bodytemperature = get_body_temp_normal(apply_change = FALSE)
	if(heal_flags & HEAL_BLOOD)
		restore_blood()
	if(reagents && (heal_flags & HEAL_ALL_REAGENTS))
		reagents.clear_reagents()

	if(heal_flags & HEAL_ADMIN)
		REMOVE_TRAIT(src, TRAIT_SUICIDED, REF(src))

	updatehealth()
	stop_sound_channel(CHANNEL_HEARTBEAT)
	SEND_SIGNAL(src, COMSIG_LIVING_POST_FULLY_HEAL, heal_flags)

/**
 * Called by strange_reagent, with the amount of healing the strange reagent is doing
 * It uses the healing amount on brute/fire damage, and then uses the excess healing for revive
 */
/mob/living/do_strange_reagent_revival(healing_amount)
	var/brute_loss = get_brute_loss()
	if(brute_loss)
		var/brute_healing = min(healing_amount * 0.5, brute_loss) // 50% of the healing goes to brute
		set_brute_loss(round(brute_loss - brute_healing, DAMAGE_PRECISION), updating_health=FALSE, forced=TRUE)
		healing_amount = max(0, healing_amount - brute_healing)

	var/fire_loss = get_fire_loss()
	if(fire_loss && healing_amount)
		var/fire_healing = min(healing_amount, fire_loss) // rest of the healing goes to fire
		set_fire_loss(round(fire_loss - fire_healing, DAMAGE_PRECISION), updating_health=TRUE, forced=TRUE)
		healing_amount = max(0, healing_amount - fire_healing)

	revive(NONE, excess_healing=max(healing_amount, 0), force_grab_ghost=FALSE) // and any excess healing is passed along

/// Checks if we are actually able to ressuscitate this mob.
/// (We don't want to revive then to have them instantly die again)
/mob/living/can_be_revived()
	if(health <= HEALTH_THRESHOLD_DEAD)
		return FALSE
	return TRUE

/mob/living/update_damage_overlays()
	return

/mob/living/Move(atom/newloc, direct, glide_size_override)
	if(lying_angle != 0)
		lying_angle_on_movement(direct)
	if (buckled && buckled.loc != newloc) //not updating position
		if (!buckled.anchored)
			buckled.moving_from_pull = moving_from_pull
			. = buckled.Move(newloc, direct, glide_size)
			buckled.moving_from_pull = null
		return

	var/old_direction = dir
	var/turf/old_loc = loc
	var/old_wall_hug_dir = wall_hugging ? REVERSE_DIR(old_direction) : NONE

	if(pulling)
		update_pull_movespeed()

	if(wall_hugging && move_intent == MOVE_INTENT_RUN)
		stop_sprinting(silent = TRUE)

	if(move_intent == MOVE_INTENT_RUN && !(movement_type & FLOATING) && !can_run())
		stop_sprinting(silent = TRUE)

	if(move_intent == MOVE_INTENT_RUN && !(movement_type & FLOATING) && last_sprint_dir && direct == REVERSE_DIR(last_sprint_dir))
		stop_sprinting("momentum lost")

	. = ..()

	if(!.)
		if(wall_hugging)
			validate_wall_hug(direct, old_wall_hug_dir, TRUE)
		else if(move_intent == MOVE_INTENT_RUN && !(movement_type & FLOATING))
			handle_sprint_collision(newloc)
	else if(. && wall_hugging)
		validate_wall_hug(direct, old_wall_hug_dir)

	if(moving_diagonally != FIRST_DIAG_STEP && isliving(pulledby))
		var/mob/living/puller = pulledby
		puller.set_pull_offsets(src, puller.grab_state)

	if(active_storage)
		var/storage_is_important_recurisve = (active_storage.parent in important_recursive_contents?[RECURSIVE_CONTENTS_ACTIVE_STORAGE])
		var/can_reach_active_storage = active_storage.parent.IsReachableBy(src)
		if(!storage_is_important_recurisve && !can_reach_active_storage)
			active_storage.hide_contents(src)

	if(!buckled && !moving_diagonally && loc != old_loc)
		if(move_intent == MOVE_INTENT_RUN && !(movement_type & FLOATING))
			if(spend_stamina(STAMINA_COST_RUN_TILE, "run"))
				handle_sprint_step(direct)
			else
				stop_sprinting("too tired")
		if(has_starvation_exhaustion() && prob(2))
			Knockdown(2 SECONDS)
			visible_message(span_warning("[src] stumbles from hunger."), span_userdanger("Hunger makes your legs buckle."))
		var/blood_flow = get_bleed_rate()
		var/health_check = body_position == LYING_DOWN && prob(get_brute_loss() * 200 / maxHealth)
		var/bleeding_check = blood_flow > 3 && prob(blood_flow * 16)
		if(health_check || bleeding_check)
			make_blood_trail(newloc, old_loc, old_direction, direct)

///Called by mob Move() when the lying_angle is different than zero, to better visually simulate crawling.
/mob/living/lying_angle_on_movement(direct)
	if(buckled && buckled.buckle_lying != NO_BUCKLE_LYING)
		set_lying_angle(buckled.buckle_lying)
		return

	if(direct & EAST)
		set_lying_angle(LYING_ANGLE_EAST)
	else if(direct & WEST)
		set_lying_angle(LYING_ANGLE_WEST)

/mob/living/carbon/alien/adult/lying_angle_on_movement(direct)
	return

/// Print a message about an annoying sensation you are feeling. Returns TRUE if successful.
/mob/living/itch(obj/item/bodypart/target_part = null, damage = 0.5, can_scratch = TRUE, silent = FALSE)
	if ((mob_biotypes & (MOB_ROBOTIC | MOB_SPIRIT)))
		return FALSE
	var/will_scratch = can_scratch && !incapacitated
	var/applied_damage = 0
	if (will_scratch && damage)
		applied_damage = apply_damage(damage, damagetype = BRUTE, def_zone = target_part)
	if (silent)
		return applied_damage > 0
	var/visible_part = isnull(target_part) ? "бок" : (target_part.ru_plaintext_zone[ACCUSATIVE] || target_part.plaintext_zone)
	visible_message("[can_scratch ? span_warning("[capitalize(declent_ru(NOMINATIVE))] чешет у себя [visible_part].") : ""]", span_warning("Вы хотите почесать [visible_part]. [can_scratch ? "И успешно чешетесь." : ""]"))
	return TRUE

/mob/living/experience_pressure_difference(pressure_difference, direction, pressure_resistance_prob_delta = 0)
	playsound(src, 'sound/effects/space_wind.ogg', 50, TRUE)
	if(buckled || mob_negates_gravity())
		return

	if(client && client.move_delay >= world.time + world.tick_lag*2)
		pressure_resistance_prob_delta -= 30

	var/list/turfs_to_check = list()

	if(!has_limbs)
		var/turf/T = get_step(src, angle2dir(dir2angle(direction)+90))
		if (T)
			turfs_to_check += T

		T = get_step(src, angle2dir(dir2angle(direction)-90))
		if(T)
			turfs_to_check += T

		for(var/t in turfs_to_check)
			T = t
			if(T.density)
				pressure_resistance_prob_delta -= 20
				continue
			for (var/atom/movable/AM in T)
				if (AM.density && AM.anchored)
					pressure_resistance_prob_delta -= 20
					break
	..(pressure_difference, direction, pressure_resistance_prob_delta)

/mob/living/can_resist()
	if(next_move > world.time)
		return FALSE
	if(HAS_TRAIT(src, TRAIT_INCAPACITATED))
		return FALSE
	return TRUE

/mob/living/resist()
	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(execute_resist)))

///proc extender of [/mob/living/verb/resist] meant to make the process queable if the server is overloaded when the verb is called
/mob/living/execute_resist()
	if(!can_resist())
		return
	changeNext_move(CLICK_CD_RESIST)

	SEND_SIGNAL(src, COMSIG_LIVING_RESIST, src)
	//resisting grabs (as if it helps anyone...)
	if(!HAS_TRAIT(src, TRAIT_RESTRAINED) && pulledby)
		log_combat(src, pulledby, "resisted grab")
		resist_grab()
		return

	//unbuckling yourself
	if(buckled && last_special <= world.time)
		resist_buckle()

	//Breaking out of a container (Locker, sleeper, cryo...)
	else if(loc != get_turf(src))
		loc.container_resist_act(src)

	else if(mobility_flags & MOBILITY_MOVE)
		if(on_fire)
			resist_fire() //stop, drop, and roll
		else if(last_special <= world.time)
			resist_restraints() //trying to remove cuffs.

/mob/resist_grab(moving_resist)
	return 1 //returning 0 means we successfully broke free

/mob/living/resist_grab(moving_resist)
	. = TRUE
	if(isliving(pulledby))
		if(world.time < cyberpunk_next_grab_resist)
			return TRUE
		var/mob/living/grabber = pulledby
		cyberpunk_next_grab_resist = world.time + get_cyberpunk_grab_resist_cooldown()
		var/resist_amount = get_cyberpunk_grab_resist_amount()
		visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))] struggles against [grabber.declent_ru(GENITIVE)] grip!"), span_warning("You struggle against [grabber.declent_ru(GENITIVE)] grip."))
		grabber.reduce_cyberpunk_grab_durability(resist_amount, src)
		return TRUE

	//Our effective grab state. GRAB_PASSIVE is equal to 0, so if we have no other altering factors to our grab state, we can break free immediately on resist.
	var/effective_grab_state = pulledby.grab_state
	//The amount of damage inflicted on a failed resist attempt.
	var/damage_on_resist_fail = rand(7, 13)
	// Base chance to escape a grab. Divided by effective grab state
	var/escape_chance = BASE_GRAB_RESIST_CHANCE

	if(body_position == LYING_DOWN) //If prone, treat the grab state as one higher
		effective_grab_state++

	if(HAS_TRAIT(src, TRAIT_GRABWEAKNESS)) //If we have grab weakness from some source, treat the grab state as one higher
		effective_grab_state++

	if(get_timed_status_effect_duration(/datum/status_effect/staggered) && (get_fire_loss() + get_brute_loss()) >= 40) //If we are staggered, and we have at least 40 damage, treat the grab state as one higher.
		effective_grab_state++

	if(HAS_TRAIT(src, TRAIT_GRABRESISTANCE)) //If we have grab resistance from some source, treat the grab state as one lower.
		effective_grab_state--

	//If our puller is a human, and they have an active hand they're grabbing with (please don't ask how people grab without hands), then apply their unarmed values to the grab values
	if(pulledby && ishuman(pulledby))
		var/mob/living/carbon/human/human_puller = pulledby
		var/obj/item/bodypart/grabbing_bodypart = human_puller.get_active_hand()
		if(grabbing_bodypart)
			damage_on_resist_fail += (rand(grabbing_bodypart.unarmed_damage_low, grabbing_bodypart.unarmed_damage_high)) + grabbing_bodypart.unarmed_grab_damage_bonus
			effective_grab_state += grabbing_bodypart.unarmed_grab_state_bonus
			escape_chance += grabbing_bodypart.unarmed_grab_escape_chance_bonus
			//CYBERPUNK BUILD - rebuild and delete before release
			damage_on_resist_fail *= human_puller.get_cyberpunk_unarmed_damage_multiplier()
			escape_chance -= human_puller.get_cyberpunk_grapple_control_bonus()
			//CYBERPUNK BUILD - rebuild and delete before release

		//If our puller is a drunken brawler, they add more damage based on their own damage taken so long as they're drunk and treat the grab state as one higher
		var/puller_drunkenness = human_puller.get_drunk_amount()
		if(puller_drunkenness && HAS_TRAIT(human_puller, TRAIT_DRUNKEN_BRAWLER))
			damage_on_resist_fail += clamp((human_puller.get_fire_loss() + human_puller.get_brute_loss()) / 10, 3, 20)
			effective_grab_state++

		var/datum/martial_art/puller_art = GET_ACTIVE_MARTIAL_ART(human_puller)
		if(puller_art?.can_use(human_puller))
			damage_on_resist_fail += puller_art.grab_damage_modifier
			effective_grab_state += puller_art.grab_state_modifier
			escape_chance += puller_art.grab_escape_chance_modifier

	//We only resist our grab state if we are currently in a grab equal to or greater than GRAB_AGGRESSIVE (1). Otherwise, break out immediately!
	if(effective_grab_state >= GRAB_AGGRESSIVE)
		// see defines/combat.dm, this should be baseline 60%
		// Resist chance divided by the value imparted by your grab state. It isn't until you reach a two-handed grab that you gain a penalty to escaping a grab.
		var/resist_chance = clamp(escape_chance / effective_grab_state, 0, 100)
		if(prob(resist_chance))
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] вырывается из хватки [pulledby.declent_ru(GENITIVE)]!"), \
							span_danger("Вы вырываетесь из хватки [pulledby.declent_ru(GENITIVE)]!"), null, null, pulledby)
			to_chat(pulledby, span_warning("[capitalize(declent_ru(NOMINATIVE))] вырывается из вашей хватки!"))
			log_combat(pulledby, src, "broke grab")
			pulledby.stop_pulling()
			return FALSE
		else
			adjust_stamina_loss(damage_on_resist_fail) //Do some stamina damage if we fail to resist
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] неуспешно пытается вырваться из хватки [pulledby.declent_ru(GENITIVE)]!"), \
							span_warning("Вы неуспешно пытаетесь вырваться из хватки [pulledby.declent_ru(GENITIVE)]!"), null, null, pulledby)
			to_chat(pulledby, span_danger("[capitalize(declent_ru(NOMINATIVE))] неуспешно пытается вырваться из вашей хватки!"))
		if(moving_resist && client) //we resisted by trying to move
			client.move_delay = world.time + 4 SECONDS
	else
		pulledby.stop_pulling()
		return FALSE

/mob/living/resist_buckle()
	buckled.user_unbuckle_mob(src,src)

/mob/living/resist_fire()
	return FALSE

/mob/living/resist_restraints()
	return

/mob/living/update_gravity(gravity)
	// Handle movespeed stuff
	var/speed_change = max(0, gravity - STANDARD_GRAVITY)
	if(speed_change)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/gravity, multiplicative_slowdown=speed_change)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/gravity)

	// Time to add/remove gravity alerts. sorry for the mess it's gotta be fast
	var/atom/movable/screen/alert/gravity_alert = alerts[ALERT_GRAVITY]
	switch(gravity)
		if(-INFINITY to NEGATIVE_GRAVITY)
			if(!istype(gravity_alert, /atom/movable/screen/alert/negative))
				throw_alert(ALERT_GRAVITY, /atom/movable/screen/alert/negative)
				ADD_TRAIT(src, TRAIT_MOVE_UPSIDE_DOWN, NEGATIVE_GRAVITY_TRAIT)
				var/matrix/flipped_matrix = transform
				flipped_matrix.b = -flipped_matrix.b
				flipped_matrix.e = -flipped_matrix.e
				animate(src, transform = flipped_matrix, time = 0.5 SECONDS, easing = SINE_EASING|EASE_OUT, flags = ANIMATION_PARALLEL)
				add_offsets(NEGATIVE_GRAVITY_TRAIT, y_add = 4)
		if(NEGATIVE_GRAVITY + 0.01 to 0)
			if(!istype(gravity_alert, /atom/movable/screen/alert/weightless))
				throw_alert(ALERT_GRAVITY, /atom/movable/screen/alert/weightless)
				ADD_TRAIT(src, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT)
		if(0.01 to STANDARD_GRAVITY)
			if(gravity_alert)
				clear_alert(ALERT_GRAVITY)
		if(STANDARD_GRAVITY + 0.01 to GRAVITY_DAMAGE_THRESHOLD - 0.01)
			throw_alert(ALERT_GRAVITY, /atom/movable/screen/alert/highgravity)
		if(GRAVITY_DAMAGE_THRESHOLD to INFINITY)
			throw_alert(ALERT_GRAVITY, /atom/movable/screen/alert/veryhighgravity)

	// If we had no gravity alert, or the same alert as before, go home
	if(!gravity_alert || alerts[ALERT_GRAVITY] == gravity_alert)
		return
	// By this point we know that we do not have the same alert as we used to
	if(istype(gravity_alert, /atom/movable/screen/alert/weightless))
		REMOVE_TRAIT(src, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT)
	if(istype(gravity_alert, /atom/movable/screen/alert/negative))
		REMOVE_TRAIT(src, TRAIT_MOVE_UPSIDE_DOWN, NEGATIVE_GRAVITY_TRAIT)
		var/matrix/flipped_matrix = transform
		flipped_matrix.b = -flipped_matrix.b
		flipped_matrix.e = -flipped_matrix.e
		animate(src, transform = flipped_matrix, time = 0.5 SECONDS, easing = SINE_EASING|EASE_OUT, flags = ANIMATION_PARALLEL)
		remove_offsets(NEGATIVE_GRAVITY_TRAIT)

/mob/living/singularity_pull(atom/singularity, current_size)
	..()
	if(move_resist == INFINITY)
		return
	if(current_size >= STAGE_SIX) //your puny magboots/wings/whatever will not save you against supermatter singularity
		throw_at(singularity, 14, 3, src, TRUE)
	else if(!src.mob_negates_gravity())
		step_towards(src, singularity)

/mob/living/get_temperature(datum/gas_mixture/environment)
	var/loc_temp = environment ? environment.temperature : T0C
	if(isobj(loc))
		var/obj/oloc = loc
		var/obj_temp = oloc.return_temperature()
		if(obj_temp != null)
			loc_temp = obj_temp
	else if(isspaceturf(get_turf(src)))
		var/turf/heat_turf = get_turf(src)
		loc_temp = heat_turf.temperature
	if(ismovable(loc))
		var/atom/movable/occupied_space = loc
		loc_temp = ((1 - occupied_space.contents_thermal_insulation) * loc_temp) + (occupied_space.contents_thermal_insulation * bodytemperature)
	return loc_temp

/// Checks if this mob can be actively tracked by cameras / AI.
/// Can optionally be passed a user, which is the mob who is tracking src.
/mob/living/can_track(mob/living/user)
	//basic fast checks go first. When overriding this proc, I recommend calling ..() at the end.
	if(SEND_SIGNAL(src, COMSIG_LIVING_CAN_TRACK, user) & COMPONENT_CANT_TRACK)
		return FALSE
	if(!isnull(user) && src == user)
		return FALSE
	if(stealth_mode && chameleon >= STEALTH_SOUND_MUTE_THRESHOLD)
		create_stealth_camera_trace()
		return FALSE
	if(invisibility || alpha <= 50)//cloaked
		return FALSE
	if(!isturf(loc)) //The reason why we don't just use get_turf is because they could be in a closet, disposals, or a vehicle.
		return FALSE
	var/turf/T = loc
	if(is_centcom_level(T.z)) //dont detect mobs on centcom
		return FALSE
	if(is_away_level(T.z))
		return FALSE
	if(onSyndieBase() && !(ROLE_SYNDICATE in user?.faction))
		return FALSE
	// Now, are they viewable by a camera? (This is last because it's the most intensive check)
	if(!SScameras.is_visible_by_cameras(src))
		return FALSE
	return TRUE

/mob/living/proc/create_stealth_camera_trace()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return
	new /obj/effect/temp_visual/dir_setting/ninja/shadow(current_turf, dir)

/mob/living/harvest(mob/living/user) //used for extra objects etc. in butchering
	return

/mob/living/can_hold_items(obj/item/I)
	return ..() && HAS_TRAIT(src, TRAIT_CAN_HOLD_ITEMS) && usable_hands

/mob/living/can_perform_action(atom/target, action_bitflags)
	if(!istype(target))
		CRASH("Missing target arg for can_perform_action")

	if(stat != CONSCIOUS && stat != SOFT_CRIT)
		to_chat(src, span_warning("Вы должны быть в сознании!"))
		return FALSE

	if(!(interaction_flags_atom & INTERACT_ATOM_IGNORE_INCAPACITATED))
		var/ignore_flags = NONE
		if(interaction_flags_atom & INTERACT_ATOM_IGNORE_RESTRAINED)
			ignore_flags |= INCAPABLE_RESTRAINTS
		if(!(interaction_flags_atom & INTERACT_ATOM_CHECK_GRAB))
			ignore_flags |= INCAPABLE_GRAB

		if(INCAPACITATED_IGNORING(src, ignore_flags))
			to_chat(src, span_warning("Вы сейчас недееспособны!"))
			return FALSE

	// If the MOBILITY_UI bitflag is not set it indicates the mob's hands are cutoff, blocked, or handcuffed
	// Note - AI's and borgs have the MOBILITY_UI bitflag set even though they don't have hands
	// Also if it is not set, the mob could be incapcitated, knocked out, unconscious, asleep, EMP'd, etc.
	if(!(mobility_flags & MOBILITY_UI) && !(action_bitflags & ALLOW_RESTING))
		to_chat(src, span_warning("Вы сейчас недостаточно мобильны!"))
		return FALSE

	// NEED_HANDS is already checked by MOBILITY_UI for humans so this is for silicons
	if((action_bitflags & NEED_HANDS))
		if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
			to_chat(src, span_warning("Ваши руки сейчас недоступны!"))
			return FALSE
		if(is_active_hand_cyberpunk_grabbed())
			to_chat(src, span_warning("Your active hand is locked in a grab."))
			return FALSE
		if(!can_hold_items(isitem(target) ? target : null)) // almost redundant if it weren't for mobs
			to_chat(src, span_warning("У вас нет рук!"))
			return FALSE

	if(!(action_bitflags & BYPASS_ADJACENCY) && ((action_bitflags & NOT_INSIDE_TARGET) || !recursive_loc_check(src, target)) && !target.IsReachableBy(src))
		if(HAS_SILICON_ACCESS(src) && !ispAI(src))
			if(!(action_bitflags & ALLOW_SILICON_REACH)) // silicons can ignore range checks (except pAIs)
				if(!(action_bitflags & SILENT_ADJACENCY))
					to_chat(src, span_warning("Вы слишком далеко!"))
				return FALSE
		else // just a normal carbon mob
			if((action_bitflags & FORBID_TELEKINESIS_REACH))
				if(!(action_bitflags & SILENT_ADJACENCY))
					to_chat(src, span_warning("Вы слишком далеко!"))
				return FALSE

			var/datum/dna/mob_DNA = has_dna()
			if(!mob_DNA || !mob_DNA.check_mutation(/datum/mutation/telekinesis) || !tkMaxRangeCheck(src, target))
				if(!(action_bitflags & SILENT_ADJACENCY))
					to_chat(src, span_warning("Вы слишком далеко!"))
				return FALSE

	if((action_bitflags & NEED_VENTCRAWL) && !HAS_TRAIT(src, TRAIT_VENTCRAWLER_NUDE) && !HAS_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS))
		to_chat(src, span_warning("Вы не влезаете!"))
		return FALSE

	if((action_bitflags & NEED_DEXTERITY) && !ISADVANCEDTOOLUSER(src))
		to_chat(src, span_warning("Вам не хватает ловкости!"))
		return FALSE

	if((action_bitflags & NEED_LITERACY) && !is_literate())
		to_chat(src, span_warning("Вы ничего здесь не понимаете!"))
		return FALSE

	if((action_bitflags & NEED_LIGHT) && !has_light_nearby() && !has_nightvision())
		to_chat(src, span_warning("Вам нужно больше света!"))
		return FALSE

	if((action_bitflags & NEED_GRAVITY) && !has_gravity())
		to_chat(src, span_warning("Вам нужна гравитация!"))
		return FALSE

	return TRUE

/mob/living/can_use_guns(obj/item/G)//actually used for more than guns!
	if(G.trigger_guard == TRIGGER_GUARD_NONE)
		to_chat(src, span_warning("Вы не можете стрелять из этого!"))
		return FALSE
	if(G.trigger_guard != TRIGGER_GUARD_ALLOW_ALL && (!ISADVANCEDTOOLUSER(src) && !HAS_TRAIT(src, TRAIT_GUN_NATURAL)))
		to_chat(src, span_warning("Вы пытаетесь выстрелить из [G.declent_ru(GENITIVE)], но не можете нажать на курок!"))
		return FALSE
	return TRUE

/mob/living/update_stamina()
	SEND_SIGNAL(src, COMSIG_LIVING_STAMINA_UPDATE)
	update_stamina_hud()

/mob/living/update_stamina_hud(shown_stamina_loss)
	if(!client || !hud_used)
		return

	var/atom/movable/screen/stamina/stamina_hud = hud_used.screen_objects[HUD_MOB_STAMINA]
	if (!stamina_hud)
		return

	if(stat == DEAD)
		stamina_hud.icon_state = "stamina_dead"
		stamina_hud.maptext = null
		return

	var/shown_stamina = clamp(stamina, 0, max_stamina)
	if(!max_stamina)
		stamina_hud.icon_state = "stamina_crit"
		stamina_hud.maptext = null
		return

	var/stamina_ratio = shown_stamina / max_stamina
	if(shown_stamina <= 0)
		stamina_hud.icon_state = "stamina_crit"
	else if(stamina_ratio >= 1)
		stamina_hud.icon_state = "stamina_full"
	else
		stamina_hud.icon_state = "stamina_[clamp(ceil((1 - stamina_ratio) * 5), 1, 5)]"
	stamina_hud.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:7px; font-size:6px'>[round(shown_stamina)]/[round(max_stamina)]</div>")

/mob/living/carbon/alien/update_stamina()
	return

/mob/living/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	stop_pulling()
	. = ..()

// Used in polymorph code to shapeshift mobs into other creatures
/**
 * Polymorphs our mob into another mob.
 * If successful, our current mob is qdeleted!
 *
 * what_to_randomize - what are we randomizing the mob into? See the defines for valid options.
 * change_flags - only used for humanoid randomization (currently), what pool of changeflags should we draw from?
 *
 * Returns a mob (what our mob turned into) or null (if we failed).
 */
/mob/living/wabbajack(what_to_randomize, change_flags = WABBAJACK)
	if(stat == DEAD || HAS_TRAIT(src, TRAIT_GODMODE) || HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(SEND_SIGNAL(src, COMSIG_LIVING_PRE_WABBAJACKED, what_to_randomize) & STOP_WABBAJACK)
		return

	add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_NO_TRANSFORM), MAGIC_TRAIT)
	icon = null
	cut_overlays()
	SetInvisibility(INVISIBILITY_ABSTRACT)

	var/list/item_contents = list()

	if(iscyborg(src))
		var/mob/living/silicon/robot/Robot = src
		// Disconnect AI's in shells
		if(Robot.connected_ai)
			Robot.connected_ai.disconnect_shell()
		QDEL_NULL(Robot.mmi)
		Robot.notify_ai(AI_NOTIFICATION_NEW_BORG)
	else
		for(var/obj/item/item in src)
			if(!dropItemToGround(item))
				if(!(item.item_flags & ABSTRACT))
					qdel(item)
				continue
			item_contents += item

	var/mob/living/new_mob

	var/static/list/possible_results = list(
		WABBAJACK_MONKEY,
		WABBAJACK_CLOWN,
		WABBAJACK_ROBOT,
		WABBAJACK_SLIME,
		WABBAJACK_XENO,
		WABBAJACK_HUMAN,
		WABBAJACK_ANIMAL,
	)

	// If we weren't passed one, pick a default one
	what_to_randomize ||= pick(possible_results)

	switch(what_to_randomize)
		if(WABBAJACK_MONKEY)
			new_mob = new /mob/living/carbon/human/species/monkey(loc)

		if(WABBAJACK_CLOWN)
			var/picked_clown = pick(typesof(/mob/living/basic/clown))
			new_mob = new picked_clown(loc)

		if(WABBAJACK_ROBOT)
			var/static/list/robot_options = list(
				/mob/living/silicon/robot = 200,
				/mob/living/basic/drone/polymorphed = 200,
				/mob/living/silicon/robot/model/syndicate = 100,
				/mob/living/silicon/robot/model/syndicate/medical = 100,
				/mob/living/silicon/robot/model/syndicate/saboteur = 100,
				/mob/living/basic/hivebot/strong = 50,
				/mob/living/basic/hivebot/mechanic = 50,
				/mob/living/basic/bot/dedbot = 25,
				/mob/living/basic/bot/cleanbot = 25,
				/mob/living/basic/bot/firebot = 25,
				/mob/living/basic/bot/secbot/honkbot = 25,
				/mob/living/basic/bot/hygienebot = 25,
				/mob/living/basic/bot/vibebot = 25,
				/mob/living/basic/bot/medbot = 13,
				/mob/living/basic/bot/medbot/mysterious = 12,
				/mob/living/basic/netguardian = 1,
			)

			var/picked_robot = pick_weight(robot_options)
			new_mob = new picked_robot(loc)
			if(issilicon(new_mob))
				var/mob/living/silicon/robot/created_robot = new_mob
				new_mob.gender = gender
				new_mob.SetInvisibility(INVISIBILITY_NONE)
				new_mob.job = JOB_CYBORG
				created_robot.lawupdate = FALSE
				created_robot.connected_ai = null
				created_robot.mmi.transfer_identity(src) //Does not transfer key/client.
				created_robot.clear_inherent_laws(announce = FALSE)
				created_robot.clear_zeroth_law(announce = FALSE)

		if(WABBAJACK_SLIME)
			new_mob = new /mob/living/basic/slime/random(loc)

		if(WABBAJACK_XENO)
			var/picked_xeno_type

			if(ckey)
				picked_xeno_type = pick(
					/mob/living/carbon/alien/adult/hunter,
					/mob/living/carbon/alien/adult/sentinel,
					/mob/living/basic/alien/maid,
				)
			else
				picked_xeno_type = pick(
					/mob/living/carbon/alien/adult/hunter,
					/mob/living/basic/alien/sentinel,
					/mob/living/basic/alien/maid,
				)
			new_mob = new picked_xeno_type(loc)

		if(WABBAJACK_ANIMAL)
			var/picked_animal = pick(
				/mob/living/basic/ant,
				/mob/living/basic/axolotl,
				/mob/living/basic/bat,
				/mob/living/basic/bear,
				/mob/living/basic/bear/butter,
				/mob/living/basic/bear/snow,
				/mob/living/basic/bear/russian,
				/mob/living/basic/blob_minion/blobbernaut,
				/mob/living/basic/blob_minion/spore,
				/mob/living/basic/blood_worm/hatchling/polymorph,
				/mob/living/basic/butterfly,
				/mob/living/basic/carp,
				/mob/living/basic/carp/mega,
				/mob/living/basic/carp/magic,
				/mob/living/basic/carp/magic/chaos,
				/mob/living/basic/chick,
				/mob/living/basic/chick/permanent,
				/mob/living/basic/chicken,
				/mob/living/basic/cow,
				/mob/living/basic/cow/moonicorn,
				/mob/living/basic/crab,
				/mob/living/basic/crab/evil,
				/mob/living/basic/crab/kreb,
				/mob/living/basic/crab/evil/kreb,
				/mob/living/basic/flesh_spider,
				/mob/living/basic/frog, // finally we can turn people into the most iconic polymorph form.
				/mob/living/basic/deer,
				/mob/living/basic/eyeball,
				/mob/living/basic/goat,
				/mob/living/basic/gorilla,
				/mob/living/basic/gorilla/lesser,
				/mob/living/basic/headslug,
				/mob/living/basic/killer_tomato,
				/mob/living/basic/lizard,
				/mob/living/basic/lizard/space,
				/mob/living/basic/lightgeist,
				/mob/living/basic/migo,
				/mob/living/basic/migo/hatsune,
				/mob/living/basic/mining/basilisk,
				/mob/living/basic/mining/brimdemon,
				/mob/living/basic/mining/goldgrub,
				/mob/living/basic/mining/goldgrub/baby,
				/mob/living/basic/mining/goliath,
				/mob/living/basic/mining/goliath/ancient/immortal,
				/mob/living/basic/mining/gutlunch/warrior,
				/mob/living/basic/mining/mook,
				/mob/living/basic/mining/mook/worker,
				/mob/living/basic/mining/mook/worker/bard,
				/mob/living/basic/mining/mook/worker/tribal_chief,
				/mob/living/basic/mining/legion/monkey,
				/mob/living/basic/mining/legion/monkey/snow,
				/mob/living/basic/mining/lobstrosity,
				/mob/living/basic/mining/lobstrosity/lava,
				/mob/living/basic/mining/ice_demon,
				/mob/living/basic/mining/ice_whelp,
				/mob/living/basic/mining/watcher,
				/mob/living/basic/mining/watcher/icewing,
				/mob/living/basic/mining/watcher/magmawing,
				/mob/living/basic/mining/wolf,
				/mob/living/basic/morph,
				/mob/living/basic/mothroach,
				/mob/living/basic/mothroach/bar,
				/mob/living/basic/mouse,
				/mob/living/basic/mushroom,
				/mob/living/basic/parrot,
				/mob/living/basic/pet/cat,
				/mob/living/basic/pet/cat/cak,
				/mob/living/basic/pet/dog/breaddog,
				/mob/living/basic/pet/dog/bullterrier,
				/mob/living/basic/pet/dog/corgi,
				/mob/living/basic/pet/dog/corgi/exoticcorgi,
				/mob/living/basic/pet/dog/corgi/narsie,
				/mob/living/basic/pet/dog/pug,
				/mob/living/basic/pet/gondola,
				/mob/living/basic/pet/fox,
				/mob/living/basic/pet/penguin/baby,
				/mob/living/basic/pet/penguin/baby/permanent,
				/mob/living/basic/pet/penguin/emperor,
				/mob/living/basic/pet/penguin/emperor/shamebrero,
				/mob/living/basic/pony,
				/mob/living/basic/pony/syndicate,
				/mob/living/basic/rabbit,
				/mob/living/basic/rabbit/easter,
				/mob/living/basic/rabbit/easter/space,
				/mob/living/basic/regal_rat,
				/mob/living/basic/seedling,
				/mob/living/basic/seedling/meanie,
				/mob/living/basic/sheep,
				/mob/living/basic/snake,
				/mob/living/basic/snake/banded,
				/mob/living/basic/snake/banded/harmless,
				/mob/living/basic/spider/giant/tangle, // curated for the most 'interesting' ones
				/mob/living/basic/spider/giant/breacher,
				/mob/living/basic/spider/giant/tank,
				/mob/living/basic/spider/giant/ambush,
				/mob/living/basic/spider/maintenance,
				/mob/living/basic/statue,
				/mob/living/basic/statue/frosty,
				/mob/living/basic/statue/mannequin/suspicious,
				/mob/living/basic/stickman,
				/mob/living/basic/stickman/dog,
				/mob/living/basic/stickman/ranged,
				/mob/living/basic/living_limb_flesh,
				/mob/living/simple_animal/hostile/megafauna/dragon/lesser,
			)
			new_mob = new picked_animal(loc)
		if(WABBAJACK_HUMAN)
			var/mob/living/carbon/human/new_human = new(loc)

			// 50% chance that we'll also randomize race
			if(prob(50))
				var/list/chooseable_races = list()
				for(var/datum/species/species_type as anything in subtypesof(/datum/species))
					if(initial(species_type.changesource_flags) & change_flags)
						chooseable_races += species_type

				if(length(chooseable_races))
					new_human.set_species(pick(chooseable_races))

			// Randomize everything but the species, which was already handled above.
			new_human.randomize_human_appearance(~RANDOMIZE_SPECIES)
			new_human.update_body(is_creating = TRUE)
			new_human.dna.update_dna_identity()
			new_mob = new_human

		else
			stack_trace("wabbajack() was called without an invalid randomization choice. ([what_to_randomize])")

	if(!new_mob)
		return

	to_chat(src, span_hypnophrase(span_big("Ваше тело изменяется, принимая форму [what_to_randomize]!")))

	// And of course, make sure they get policy for being transformed
	var/poly_msg = get_policy(POLICY_POLYMORPH)
	if(poly_msg)
		to_chat(src, poly_msg)

	// Some forms can still wear some items
	for(var/obj/item/item as anything in item_contents)
		new_mob.equip_to_appropriate_slot(item)

	// I don't actually know why we do this
	new_mob.set_combat_mode(TRUE)

	// on_wabbajack is where we handle setting up the name,
	// transfering the mind and observerse, and other miscellaneous
	// actions that should be done before we delete the original mob.
	on_wabbajacked(new_mob)

	// Valid polymorph types unlock the Lepton.
	if((change_flags & (WABBAJACK|MIRROR_MAGIC|MIRROR_PRIDE|RACE_SWAP)) && (SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_WABBAJACK] != TRUE))
		to_chat(new_mob, span_revennotice("Вы ощущаете самое странное ощущение, но лишь на мгновение. Хрупкая, головокружительная память проносится по вашему разуму... всё, что вы можете понять, это-"))
		to_chat(new_mob, span_hypnophrase("Вы спите, чтобы оно пробудилось. Вы пробуждаетесь, чтобы оно уснуло. Оно пробудилось. Не усните."))
		SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_WABBAJACK] = TRUE

	qdel(src)
	return new_mob

// Called when we are hit by a bolt of polymorph and changed
// Generally the mob we are currently in is about to be deleted
/mob/living/on_wabbajacked(mob/living/new_mob)
	log_message("became [new_mob.name] ([new_mob.type])", LOG_ATTACK, color = "orange")
	SEND_SIGNAL(src, COMSIG_LIVING_ON_WABBAJACKED, new_mob)
	new_mob.name = real_name
	new_mob.real_name = real_name

	// Transfer mind to the new mob (also handles actions and observers and stuff)
	if(mind)
		mind.transfer_to(new_mob)

	// Well, no mmind, guess we should try to move a key over
	else if(key)
		new_mob.PossessByPlayer(key)

/mob/living/unfry_mob() //Callback proc to tone down spam from multiple sizzling frying oil dipping.
	REMOVE_TRAIT(src, TRAIT_OIL_FRIED, "cooking_oil_react")

//Mobs on Fire

/// Global list that containes cached fire overlays for mobs

/mob/living/ignite_mob(silent)
	if(fire_stacks <= 0)
		return FALSE

	var/datum/status_effect/fire_handler/fire_stacks/fire_status = has_status_effect(/datum/status_effect/fire_handler/fire_stacks)
	if(!fire_status || fire_status.on_fire)
		return FALSE

	return fire_status.ignite(silent)

/**
 * Extinguish all fire on the mob
 *
 * This removes all fire stacks, fire effects, alerts, and moods
 * Signals the extinguishing.
 */
/mob/living/extinguish_mob()
	if(HAS_TRAIT(src, TRAIT_NO_EXTINGUISH)) //The everlasting flames will not be extinguished
		return
	var/datum/status_effect/fire_handler/fire_stacks/fire_status = has_status_effect(/datum/status_effect/fire_handler/fire_stacks)
	if(!fire_status || !fire_status.on_fire)
		return
	remove_status_effect(/datum/status_effect/fire_handler/fire_stacks)

/**
 * Adjust the amount of fire stacks on a mob
 *
 * This modifies the fire stacks on a mob.
 *
 * Vars:
 * * stacks: int The amount to modify the fire stacks
 * * fire_type: type Type of fire status effect that we apply, should be subtype of /datum/status_effect/fire_handler/fire_stacks
 */

/mob/living/adjust_fire_stacks(stacks, fire_type = /datum/status_effect/fire_handler/fire_stacks)
	if(stacks < 0)
		if(HAS_TRAIT(src, TRAIT_NO_EXTINGUISH)) //You can't reduce fire stacks of the everlasting flames
			return
		stacks = max(-fire_stacks, stacks)
	apply_status_effect(fire_type, stacks)

/mob/living/adjust_wet_stacks(stacks, wet_type = /datum/status_effect/fire_handler/wet_stacks)
	if(HAS_TRAIT(src, TRAIT_NO_EXTINGUISH)) //The everlasting flames will not be extinguished
		return
	if(stacks < 0)
		stacks = max(fire_stacks, stacks)
	apply_status_effect(wet_type, stacks)

/**
 * Set the fire stacks on a mob
 *
 * This sets the fire stacks on a mob, stacks are clamped between -20 and 20.
 * If the fire stacks are reduced to 0 then we will extinguish the mob.
 *
 * Vars:
 * * stacks: int The amount to set fire_stacks to
 * * fire_type: type Type of fire status effect that we apply, should be subtype of /datum/status_effect/fire_handler/fire_stacks
 * * remove_wet_stacks: bool If we remove all wet stacks upon doing this
 */

/mob/living/set_fire_stacks(stacks, fire_type = /datum/status_effect/fire_handler/fire_stacks, remove_wet_stacks = TRUE)
	if(stacks < 0) //Shouldn't happen, ever
		CRASH("set_fire_stacks received negative [stacks] fire stacks")

	if(remove_wet_stacks)
		remove_status_effect(/datum/status_effect/fire_handler/wet_stacks)

	if(stacks == 0)
		remove_status_effect(fire_type)
		return

	apply_status_effect(fire_type, stacks, TRUE)

/mob/living/set_wet_stacks(stacks, wet_type = /datum/status_effect/fire_handler/wet_stacks, remove_fire_stacks = TRUE)
	if(stacks < 0)
		CRASH("set_wet_stacks received negative [stacks] wet stacks")

	if(remove_fire_stacks)
		remove_status_effect(/datum/status_effect/fire_handler/fire_stacks)

	if(stacks == 0)
		remove_status_effect(wet_type)
		return

	apply_status_effect(wet_type, stacks, TRUE)

//Share fire evenly between the two mobs
//Called in MobBump() and Crossed()
/mob/living/spreadFire(mob/living/spread_to)
	if(!istype(spread_to))
		return

	// can't spread fire to mobs that don't catch on fire
	if(HAS_TRAIT(spread_to, TRAIT_NOFIRE_SPREAD) || HAS_TRAIT(src, TRAIT_NOFIRE_SPREAD))
		return

	var/datum/status_effect/fire_handler/fire_stacks/fire_status = has_status_effect(/datum/status_effect/fire_handler/fire_stacks)
	var/datum/status_effect/fire_handler/fire_stacks/their_fire_status = spread_to.has_status_effect(/datum/status_effect/fire_handler/fire_stacks)
	if(fire_status && fire_status.on_fire)
		if(their_fire_status && their_fire_status.on_fire)
			var/firesplit = (fire_stacks + spread_to.fire_stacks) / 2
			var/fire_type = (spread_to.fire_stacks > fire_stacks) ? their_fire_status.type : fire_status.type
			set_fire_stacks(firesplit, fire_type)
			spread_to.set_fire_stacks(firesplit, fire_type)
			return

		adjust_fire_stacks(-fire_stacks / 2, fire_status.type)
		spread_to.adjust_fire_stacks(fire_stacks, fire_status.type)
		if(spread_to.ignite_mob())
			log_message("bumped into [key_name(spread_to)] and set them on fire.", LOG_ATTACK)
		return

	if(!their_fire_status || !their_fire_status.on_fire)
		return

	spread_to.adjust_fire_stacks(-spread_to.fire_stacks / 2, their_fire_status.type)
	adjust_fire_stacks(spread_to.fire_stacks, their_fire_status.type)
	ignite_mob()

/**
 * Gets the fire overlay to use for this mob
 *
 * Args:
 * * stacks: Current amount of fire_stacks
 * * on_fire: If we're lit on fire
 *
 * Return a mutable appearance, the overlay that will be applied.
 */

/mob/living/get_fire_overlay(stacks, on_fire)
	RETURN_TYPE(/mutable_appearance)
	return null

/// Create a fire overlay using the generic fire sprites
/mob/living/make_generic_fire_overlay()
	var/fire_key = "[base_pixel_x]_[base_pixel_y]_fire"
	if(!GLOB.fire_appearances[fire_key])
		var/mutable_appearance/fire = mutable_appearance(
			'icons/mob/effects/onfire.dmi',
			"generic_fire",
			ABOVE_ALL_MOB_LAYER,
			appearance_flags = RESET_COLOR|KEEP_APART,
		)
		fire.pixel_x = -1 * base_pixel_x
		fire.pixel_y = -1 * base_pixel_y
		GLOB.fire_appearances[fire_key] = fire

	return GLOB.fire_appearances[fire_key]

/// Takes a fire overlay and generates an emissive appearance for it
/mob/living/make_fire_emissive(mutable_appearance/fire_overlay)
	return emissive_appearance(fire_overlay.icon, fire_overlay.icon_state, src, fire_overlay.layer)

/**
 * Handles effects happening when mob is on normal fire
 *
 * Vars:
 * * seconds_per_tick
 * * times_fired
 * * fire_handler: Current fire status effect that called the proc
 */

/mob/living/on_fire_stack(seconds_per_tick, datum/status_effect/fire_handler/fire_stacks/fire_handler)
	return

//Mobs on Fire end

// used by secbot and monkeys Crossed
/mob/living/knockOver(mob/living/carbon/C)
	if(C.key) //save us from monkey hordes
		C.visible_message(span_warning(pick( \
						"[capitalize(C.declent_ru(NOMINATIVE))] выпрыгивает с пути [declent_ru(GENITIVE)]!", \
						"[capitalize(C.declent_ru(NOMINATIVE))] оступается об [declent_ru(ACCUSATIVE)]!", \
						"[capitalize(C.declent_ru(NOMINATIVE))] отпрыгивает с пути [declent_ru(GENITIVE)]!", \
						"[capitalize(C.declent_ru(NOMINATIVE))] спотыкается об [declent_ru(ACCUSATIVE)] и падает!", \
						"[capitalize(C.declent_ru(NOMINATIVE))] опрокидывается об [declent_ru(ACCUSATIVE)]!", \
						"[capitalize(C.declent_ru(NOMINATIVE))] выпрыгивает с пути [declent_ru(GENITIVE)]!")))
	C.Paralyze(40)

/mob/living/can_be_pulled(user, force)
	return ..() && !(buckled?.buckle_prevents_pull)


/// Called when mob changes from a standing position into a prone while lacking the ability to stand up at the moment.
/mob/living/on_fall()
	SEND_SIGNAL(src, COMSIG_LIVING_THUD)
	return

/mob/living/forceMove(atom/destination)
	if(!currently_z_moving)
		stop_pulling()
		if(buckled && !HAS_TRAIT(src, TRAIT_CANNOT_BE_UNBUCKLED))
			buckled.unbuckle_mob(src, force = TRUE)
		if(has_buckled_mobs())
			unbuckle_all_mobs(force = TRUE)
	refresh_gravity()
	. = ..()
	if(. && client)
		reset_perspective()


/mob/living/update_z(new_z) // 1+ to register, null to unregister
	if(registered_z == new_z)
		return
	if(registered_z)
		SSmobs.clients_by_zlevel[registered_z] -= src
	if(isnull(client))
		registered_z = null
		return

	//Check the amount of clients exists on the Z level we're leaving from,
	//this excludes us because at this point we are not registered to any z level.
	var/old_level_new_clients = (registered_z ? SSmobs.clients_by_zlevel[registered_z].len : null)
	//No one is left after we're gone, shut off inactive ones
	if(registered_z && old_level_new_clients == 0)
		for(var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_zlevel[registered_z])
			controller.set_ai_status(AI_STATUS_OFF)

	if(new_z)
		//Check the amount of clients exists on the Z level we're moving towards, excluding ourselves.
		var/new_level_old_clients = SSmobs.clients_by_zlevel[new_z].len

		//We'll add ourselves to the list now so get_expected_ai_status() will know we're on the z level.
		SSmobs.clients_by_zlevel[new_z] += src

		if(new_level_old_clients == 0) //No one was here before, wake up all the AIs.
			for (var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_zlevel[new_z])
				//We don't set them directly on, for instances like AIs acting while dead and other cases that may exist in the future.
				//This isn't a problem for AIs with a client since the client will prevent this from being called anyway.
				controller.set_ai_status(controller.get_expected_ai_status())

	registered_z = new_z

/mob/living/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	..()
	update_z(new_turf?.z)

/mob/living/mouse_drop_receive(atom/dropping, atom/user, params)
	var/mob/living/U = user
	if(isliving(dropping))
		var/mob/living/M = dropping
		var/list/modifiers = params2list(params)
		if(U == src && LAZYACCESS(modifiers, RIGHT_CLICK) && U.pulling == M && U.perform_cyberpunk_grapple_self_drag(M, TRUE))
			return
		if(M.can_be_held && U.pulling == M)
			M.mob_try_pickup(U)//blame kevinz
			return//dont open the mobs inventory if you are picking them up
	return ..()

/mob/living/mob_pickup(mob/living/user)
	var/obj/item/mob_holder/holder = new inhand_holder_type(get_turf(src), src, held_state, head_icon, held_lh, held_rh, worn_slot_flags)
	SEND_SIGNAL(src, COMSIG_LIVING_SCOOPED_UP, user, holder)
	user.visible_message(span_warning("[capitalize(user.declent_ru(NOMINATIVE))] подбирает [declent_ru(ACCUSATIVE)]!"))
	user.put_in_hands(holder)

/mob/living/set_name()
	if(identifier == 0)
		identifier = rand(1, 999)
	ru_names_rename(ru_names_toml(name, suffix = " ([identifier])", override_base = "[name] ([identifier])"))
	name = "[name] ([identifier])"
	real_name = declent_ru(NOMINATIVE)

/mob/living/mob_try_pickup(mob/living/user, instant=FALSE)
	if(!ishuman(user) && (user.mob_size <= mob_size || user.num_hands == 0))
		if (!user.num_hands)
			return
		if (user.mob_size <= mob_size)
			to_chat(user, span_warning("[src] is too big to pick up!"))
			return
	if(!user.get_empty_held_indexes())
		to_chat(user, span_warning("Ваши руки заняты!"))
		return FALSE
	if(buckled)
		to_chat(user, span_warning("Нужно отстегнуть [declent_ru(ACCUSATIVE)]!"))
		return FALSE
	if(!instant)
		user.visible_message(span_warning("[capitalize(user.declent_ru(NOMINATIVE))] начинает подбирать [declent_ru(ACCUSATIVE)]!"), \
						span_danger("Вы начинаете подбирать [declent_ru(ACCUSATIVE)]..."), null, null, src)
		to_chat(src, span_userdanger("[capitalize(user.declent_ru(NOMINATIVE))] начинает подбирать вас!"))
		if(!do_after(user, 2 SECONDS, target = src))
			return FALSE
	mob_pickup(user)
	return TRUE

/mob/living/get_static_viruses() //used when creating blood and other infective objects
	if(!LAZYLEN(diseases))
		return
	var/list/datum/disease/result = list()
	for(var/datum/disease/D in diseases)
		var/static_virus = D.Copy()
		result += static_virus
	return result

/mob/living/reset_perspective(atom/A)
	if(!..())
		return
	update_sight()
	update_fullscreen()
	update_pipe_vision()

/// Proc used to handle the fullscreen overlay updates, realistically meant for the reset_perspective() proc.
/mob/living/update_fullscreen()
	if(client.eye && client.eye != src)
		var/atom/client_eye = client.eye
		client_eye.get_remote_view_fullscreens(src)
	else
		clear_fullscreen("remote_view", 0)

/mob/living/vv_edit_var(var_name, var_value)
	switch(var_name)
		if (NAMEOF(src, maxHealth))
			if (!isnum(var_value) || var_value <= 0)
				return FALSE
		if(NAMEOF(src, health)) //this doesn't work. gotta use procs instead.
			return FALSE
		if(NAMEOF(src, resting))
			set_resting(var_value)
			. = TRUE
		if(NAMEOF(src, lying_angle))
			set_lying_angle(var_value)
			. = TRUE
		if(NAMEOF(src, buckled))
			set_buckled(var_value)
			. = TRUE
		if(NAMEOF(src, num_legs))
			set_num_legs(var_value)
			. = TRUE
		if(NAMEOF(src, usable_legs))
			set_usable_legs(var_value)
			. = TRUE
		if(NAMEOF(src, num_hands))
			set_num_hands(var_value)
			. = TRUE
		if(NAMEOF(src, usable_hands))
			set_usable_hands(var_value)
			. = TRUE
		if(NAMEOF(src, body_position))
			set_body_position(var_value)
			. = TRUE
		if(NAMEOF(src, current_size))
			if(var_value == 0) //prevents divisions of and by zero.
				return FALSE
			update_transform(var_value/current_size)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	. = ..()

	switch(var_name)
		if(NAMEOF(src, maxHealth))
			updatehealth()
		if(NAMEOF(src, lighting_cutoff))
			sync_lighting_plane_cutoff()


/mob/living/proc/get_vv_brute_damage_tooltip()
	return "Total brute damage: [get_brute_loss()]"

/mob/living/proc/get_vv_burn_damage_tooltip()
	return "Total fire damage: [get_fire_loss()]"

/mob/living/proc/get_vv_oxy_damage_tooltip()
	return "OXY loss: [get_oxy_loss()]"

/mob/living/carbon/get_vv_brute_damage_tooltip()
	var/blunt = 0
	var/pierce = 0
	var/slash = 0
	for(var/obj/item/bodypart/limb as anything in get_bodyparts())
		blunt += limb.blunt_dam
		pierce += limb.pierce_dam
		slash += limb.slash_dam
	return "Total brute: [get_brute_loss()]&#10;Blunt: [round(blunt, DAMAGE_PRECISION)]&#10;Pierce: [round(pierce, DAMAGE_PRECISION)]&#10;Slash: [round(slash, DAMAGE_PRECISION)]"

/mob/living/carbon/get_vv_burn_damage_tooltip()
	var/heat = 0
	var/cold = 0
	var/acid = 0
	for(var/obj/item/bodypart/limb as anything in get_bodyparts())
		heat += limb.heat_dam
		cold += limb.cold_dam
		acid += limb.acid_dam
	return "Total fire: [get_fire_loss()]&#10;Heat: [round(heat, DAMAGE_PRECISION)]&#10;Cold: [round(cold, DAMAGE_PRECISION)]&#10;Acid: [round(acid, DAMAGE_PRECISION)]"

/mob/living/carbon/get_vv_oxy_damage_tooltip()
	return "OXY loss: [get_oxy_loss()]&#10;Oxygenation: [round(oxygenation, DAMAGE_PRECISION)]"

/mob/living/vv_get_header()
	. = ..()
	var/refid = REF(src)
	var/brute_tooltip = get_vv_brute_damage_tooltip()
	var/fire_tooltip = get_vv_burn_damage_tooltip()
	var/oxy_tooltip = get_vv_oxy_damage_tooltip()
	. += {"
		<br><font size='1'>[VV_HREF_TARGETREF(refid, VV_HK_GIVE_DIRECT_CONTROL, "[ckey || "no ckey"]")] / [VV_HREF_TARGETREF_1V(refid, VV_HK_BASIC_EDIT, "[real_name || "no real name"]", NAMEOF(src, real_name))]</font>
		<br><font size='1'>
			BRUTE:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=brute' id='brute' title='[brute_tooltip]'>[get_brute_loss()]</a>
			FIRE:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=fire' id='fire' title='[fire_tooltip]'>[get_fire_loss()]</a>
			TOXIN:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=toxin' id='toxin'>[get_tox_loss()]</a>
			OXY:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=oxygen' id='oxygen' title='[oxy_tooltip]'>[get_oxy_loss()]</a>
			BRAIN:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=brain' id='brain'>[get_organ_loss(ORGAN_SLOT_BRAIN)]</a>
			STAMINA:<font size='1'><a href='byond://?_src_=vars;[HrefToken()];mobToDamage=[refid];adjustDamage=stamina' id='stamina'>[get_stamina_loss()]</a>
		</font>
	"}

/mob/living/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "--- /living ---")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_SPEECH_IMPEDIMENT, "Impede Speech (Slurring, stuttering, etc)")
	VV_DROPDOWN_OPTION(VV_HK_ADD_MOOD, "Add Mood Event")
	VV_DROPDOWN_OPTION(VV_HK_REMOVE_MOOD, "Remove Mood Event")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_HALLUCINATION, "Give Hallucination")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_DELUSION_HALLUCINATION, "Give Delusion Hallucination")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_GUARDIAN_SPIRIT, "Give Guardian Spirit")
	VV_DROPDOWN_OPTION(VV_HK_ADMIN_RENAME, "Force Change Name")

/mob/living/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_GIVE_SPEECH_IMPEDIMENT])
		admin_give_speech_impediment(usr)

	if(href_list[VV_HK_ADD_MOOD])
		admin_add_mood_event(usr)

	if(href_list[VV_HK_REMOVE_MOOD])
		admin_remove_mood_event(usr)

	if(href_list[VV_HK_GIVE_HALLUCINATION])
		admin_give_hallucination(usr)

	if(href_list[VV_HK_GIVE_DELUSION_HALLUCINATION])
		admin_give_delusion(usr)

	if(href_list[VV_HK_GIVE_GUARDIAN_SPIRIT])
		admin_give_guardian(usr)

	if(href_list[VV_HK_ADMIN_RENAME])
		if(!check_rights(R_ADMIN))
			return

		var/old_name = real_name
		var/new_name = sanitize_name(tgui_input_text(usr, "Enter the new name.", "Admin Rename", real_name))
		if(!new_name || new_name == real_name)
			return

		fully_replace_character_name(real_name, new_name)
		var/replace_preferences = !isnull(client) && (tgui_alert(usr, "Would you like to update the client's preference with the new name?", "Pref Overwrite", list("Yes", "No")) == "Yes")
		if(replace_preferences)
			client.prefs.write_preference(GLOB.preference_entries[/datum/preference/name/real_name], new_name)

		log_admin("forced rename", list(
			"admin" = key_name(usr),
			"player" = key_name(src),
			"old_name" = old_name,
			"new_name" = new_name,
			"updated_prefs" = replace_preferences,
		))
		message_admins("[key_name_admin(usr)] has forcibly changed the real name of [key_name(src)] from '[old_name]' to '[real_name]'[(replace_preferences ? " and their preferences" : "")]")

/mob/living/move_to_error_room()
	var/obj/effect/landmark/error/error_landmark = locate(/obj/effect/landmark/error) in GLOB.landmarks_list
	if(error_landmark)
		forceMove(error_landmark.loc)
	else
		forceMove(locate(4,4,1)) //Even if the landmark is missing, this should put them in the error room.
		//If you're here from seeing this error, I'm sorry. I'm so very sorry. The error landmark should be a sacred object that nobody has any business messing with, and someone did!
		//Consider seeing a therapist.
		var/ERROR_ERROR_LANDMARK_ERROR = "ERROR-ERROR: ERROR landmark missing!"
		log_mapping(ERROR_ERROR_LANDMARK_ERROR)
		CRASH(ERROR_ERROR_LANDMARK_ERROR)

/**
 * Changes the inclination angle of a mob, used by humans and others to differentiate between standing up and prone positions.
 *
 * In BYOND-angles 0 is NORTH, 90 is EAST, 180 is SOUTH and 270 is WEST.
 * This usually means that 0 is standing up, 90 and 270 are horizontal positions to right and left respectively, and 180 is upside-down.
 * Mobs that do now follow these conventions due to unusual sprites should require a special handling or redefinition of this proc, due to the density and layer changes.
 * The return of this proc is the previous value of the modified lying_angle if a change was successful (might include zero), or null if no change was made.
 */
/mob/living/set_lying_angle(new_lying)
	if(new_lying == lying_angle)
		return
	. = lying_angle
	lying_angle = new_lying
	if(lying_angle != lying_prev)
		update_transform()
		lying_prev = lying_angle


/**
 * add_body_temperature_change Adds modifications to the body temperature
 *
 * This collects all body temperature changes that the mob is experiencing to the list body_temp_changes
 * the aggrogate result is used to derive the new body temperature for the mob
 *
 * arguments:
 * * key_name (str) The unique key for this change, if it already exist it will be overridden
 * * amount (int) The amount of change from the base body temperature
 */
/mob/living/add_body_temperature_change(key_name, amount)
	body_temp_changes["[key_name]"] = amount

/**
 * remove_body_temperature_change Removes the modifications to the body temperature
 *
 * This removes the recorded change to body temperature from the body_temp_changes list
 *
 * arguments:
 * * key_name (str) The unique key for this change that will be removed
 */
/mob/living/remove_body_temperature_change(key_name)
	body_temp_changes -= key_name

/**
 * get_body_temp_normal_change Returns the aggregate change to body temperature
 *
 * This aggregates all the changes in the body_temp_changes list and returns the result
 */
/mob/living/get_body_temp_normal_change()
	var/total_change = 0
	if(body_temp_changes.len)
		for(var/change in body_temp_changes)
			total_change += body_temp_changes["[change]"]
	return total_change

/**
 * get_body_temp_normal Returns the mobs normal body temperature with any modifications applied
 *
 * This applies the result from proc/get_body_temp_normal_change() against the BODYTEMP_NORMAL and returns the result
 *
 * arguments:
 * * apply_change (optional) Default True This applies the changes to body temperature normal
 */
/mob/living/get_body_temp_normal(apply_change=TRUE)
	if(!apply_change)
		return BODYTEMP_NORMAL
	return BODYTEMP_NORMAL + get_body_temp_normal_change()

///Returns the body temperature at which this mob will start taking heat damage.
/mob/living/get_body_temp_heat_damage_limit()
	return BODYTEMP_HEAT_DAMAGE_LIMIT

///Returns the body temperature at which this mob will start taking cold damage.
/mob/living/get_body_temp_cold_damage_limit()
	return BODYTEMP_COLD_DAMAGE_LIMIT

///Checks if the user is incapacitated or on cooldown.
/mob/living/can_look_up()
	if(next_move > world.time)
		return FALSE
	if(INCAPACITATED_IGNORING(src, INCAPABLE_RESTRAINTS))
		return FALSE
	return TRUE

/mob/living/end_look()
	reset_perspective()
	looking_vertically = NONE
	if(!looking_holder)
		return
	on_looking_z_level_change(looking_holder.loc, get_turf(src))
	QDEL_NULL(looking_holder)

/mob/living/on_looking_z_level_change(turf/old_loc, turf/new_loc)
	SEND_SIGNAL(src, COMSIG_LIVING_LOOK_Z_CHANGE, old_loc, new_loc)

/**
 * look_up Changes the perspective of the mob to any openspace turf above the mob
 *
 * This also checks if an openspace turf is above the mob before looking up or resets the perspective if already looking up
 *
 */
/mob/living/look_up()
	if(looking_vertically == UP)
		return
	if(looking_vertically == DOWN)
		end_look()
		return
	if(!can_look_up())
		return
	changeNext_move(CLICK_CD_LOOK_UP)
	var/turf/above_turf = get_looking_turf(UP)
	if(!above_turf)
		return
	looking_vertically = UP
	looking_holder = new(above_turf, src, UP)
	reset_perspective(looking_holder)
	on_looking_z_level_change(get_turf(src), above_turf)

/mob/living/get_looking_turf(direction)
	//down needs to check this floor
	var/turf/check_turf = get_step_multiz(src, direction == DOWN ? NONE : direction)
	if(!get_step_multiz(src, direction)) //We are at the edge z-level.
		to_chat(src, span_warning("[direction == DOWN ? "Снизу" : "Сверху"] нет ничего интересного."))
		return
	else if(!istransparentturf(check_turf)) //There is no turf we can look through above us
		var/turf/front_hole = get_step(check_turf, dir)
		if(istransparentturf(front_hole))
			check_turf = front_hole
		else
			for(var/turf/checkhole in TURF_NEIGHBORS(check_turf))
				if(istransparentturf(checkhole))
					check_turf = checkhole
					break
		if(!istransparentturf(check_turf))
			to_chat(src, span_warning("Вы не можете смотреть через пол [direction == DOWN ? "под" : "над"] вами."))
			return
	return direction == DOWN ? get_step_multiz(check_turf, DOWN) : check_turf

/**
 * look_down Changes the perspective of the mob to any openspace turf below the mob
 *
 * This also checks if an openspace turf is below the mob before looking down or resets the perspective if already looking up
 *
 */
/mob/living/look_down()
	if(looking_vertically == UP)
		end_look()
		return
	if(looking_vertically == DOWN)
		return
	if(!can_look_up()) //if we cant look up, we cant look down.
		return
	changeNext_move(CLICK_CD_LOOK_UP)
	var/turf/below_turf = get_looking_turf(DOWN)
	if(!below_turf)
		return
	looking_vertically = DOWN
	looking_holder = new(get_looking_turf(DOWN), src, DOWN)
	reset_perspective(looking_holder)

/mob/living/set_stat(new_stat)
	. = ..()
	if(isnull(.))
		return
	if(stat in list(SOFT_CRIT, HARD_CRIT, UNCONSCIOUS, DEAD))
		//CYBERPUNK BUILD - rebuild and delete before release
		SSeconomy.record_cyberpunk_contract_elimination(src)
		//CYBERPUNK BUILD - rebuild and delete before release

	if(. <= UNCONSCIOUS || new_stat >= UNCONSCIOUS)
		update_eyes()

	switch(.) //Previous stat.
		if(CONSCIOUS)
			if(stat >= UNCONSCIOUS)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
				add_traits(list(TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED, TRAIT_FLOORED), STAT_TRAIT)
		if(SOFT_CRIT)
			if(stat >= UNCONSCIOUS)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT) //adding trait sources should come before removing to avoid unnecessary updates
				add_traits(list(TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED, TRAIT_FLOORED), STAT_TRAIT)
			if(pulledby)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)
		if(UNCONSCIOUS)
			if(stat != HARD_CRIT)
				cure_blind(UNCONSCIOUS_TRAIT)
		if(HARD_CRIT)
			if(stat != UNCONSCIOUS)
				cure_blind(UNCONSCIOUS_TRAIT)
			REMOVE_TRAIT(src, TRAIT_DEAF, STAT_TRAIT)
		if(DEAD)
			REMOVE_TRAIT(src, TRAIT_DEAF, STAT_TRAIT)
			remove_from_dead_mob_list()
			add_to_alive_mob_list()
	switch(stat) //Current stat.
		if(CONSCIOUS)
			if(. >= UNCONSCIOUS)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
			remove_traits(list(TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED, TRAIT_FLOORED, TRAIT_CRITICAL_CONDITION), STAT_TRAIT)
			log_combat(src, src, "regained consciousness")
		if(SOFT_CRIT)
			if(pulledby)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT) //adding trait sources should come before removing to avoid unnecessary updates
			if(. >= UNCONSCIOUS)
				REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, TRAIT_KNOCKEDOUT)
			ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			log_combat(src, src, "entered soft crit")
		if(UNCONSCIOUS)
			if(. != HARD_CRIT)
				become_blind(UNCONSCIOUS_TRAIT)
			if(health <= crit_threshold && !HAS_TRAIT(src, TRAIT_NOSOFTCRIT))
				ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			else
				REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			log_combat(src, src, "lost consciousness")
		if(HARD_CRIT)
			if(. != UNCONSCIOUS)
				become_blind(UNCONSCIOUS_TRAIT)
			ADD_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			ADD_TRAIT(src, TRAIT_DEAF, STAT_TRAIT)
			log_combat(src, src, "entered hard crit")
		if(DEAD)
			REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
			ADD_TRAIT(src, TRAIT_DEAF, STAT_TRAIT)
			remove_from_alive_mob_list()
			add_to_dead_mob_list()
			log_combat(src, src, "died")

///Reports the event of the change in value of the buckled variable.
/mob/living/set_buckled(new_buckled)
	if(new_buckled == buckled)
		return
	SEND_SIGNAL(src, COMSIG_LIVING_SET_BUCKLED, new_buckled)
	. = buckled
	buckled = new_buckled
	if(buckled)
		if(!HAS_TRAIT(buckled, TRAIT_NO_IMMOBILIZE))
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, BUCKLED_TRAIT)
		switch(buckled.buckle_lying)
			if(NO_BUCKLE_LYING) // The buckle doesn't force a lying angle.
				REMOVE_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
			if(0) // Forcing to a standing position.
				REMOVE_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
				set_body_position(STANDING_UP)
				set_lying_angle(0)
			else // Forcing to a lying position.
				ADD_TRAIT(src, TRAIT_FLOORED, BUCKLED_TRAIT)
				set_body_position(LYING_DOWN)
				set_lying_angle(buckled.buckle_lying)
	else
		remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_FLOORED), BUCKLED_TRAIT)
		if(.) // We unbuckled from something.
			var/atom/movable/old_buckled = .
			if(old_buckled.buckle_lying == 0 && (resting || HAS_TRAIT(src, TRAIT_FLOORED))) // The buckle forced us to stay up (like a chair)
				set_lying_down() // We want to rest or are otherwise floored, so let's drop on the ground.

/mob/living/set_pulledby(new_pulledby)
	. = ..()
	update_incapacitated()
	if(. == FALSE) //null is a valid value here, we only want to return if FALSE is explicitly passed.
		return
	if(pulledby)
		if(!. && stat == SOFT_CRIT)
			ADD_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)
	else if(. && stat == SOFT_CRIT)
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, PULLED_WHILE_SOFTCRIT_TRAIT)


/// Updates the grab state of the mob and updates movespeed
/mob/living/setGrabState(newstate)
	. = ..()
	switch(grab_state)
		if(GRAB_PASSIVE)
			remove_movespeed_modifier(MOVESPEED_ID_MOB_GRAB_STATE)
		if(GRAB_AGGRESSIVE)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/aggressive)
		if(GRAB_TWOHANDED)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/neck)
		if(GRAB_KILL)
			add_movespeed_modifier(/datum/movespeed_modifier/grab_slowdown/kill)
	if(grab_state == GRAB_PASSIVE)
		cyberpunk_grab_durability = 0
		cyberpunk_grab_max_durability = 0
		clear_cyberpunk_grab_hold_items()
	else if(update_cyberpunk_grab_hold_items())
		reset_cyberpunk_grab_durability()
		var/mob/living/grabbed = pulling
		if(istype(grabbed))
			apply_cyberpunk_grab_zone_effects(grabbed)

/// Sprite to show for photocopying mob butts
/mob/living/get_butt_sprite()
	return null

///Proc to modify the value of num_legs and hook behavior associated to this event.
/mob/living/set_num_legs(new_value)
	if(num_legs == new_value)
		return
	. = num_legs
	num_legs = new_value
	hud_used?.update_locked_slots()

///Proc to modify the value of usable_legs and hook behavior associated to this event.
/mob/living/set_usable_legs(new_value)
	if(usable_legs == new_value)
		return
	if(new_value < 0) // Sanity check
		stack_trace("[src] had set_usable_legs() called on them with a negative value!")
		new_value = 0

	. = usable_legs
	usable_legs = new_value
	update_usable_leg_status()

/**
 * Proc that updates the status of the mob's legs without setting its leg value to something else.
 */
/mob/living/update_usable_leg_status()

	if(usable_legs > 0) // Gained leg usage.
		REMOVE_TRAIT(src, TRAIT_FLOORED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
	else if(!(movement_type & (FLYING | FLOATING))) //Lost leg usage, not flying.
		if(!usable_legs)
			ADD_TRAIT(src, TRAIT_FLOORED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
			if(!usable_hands)
				ADD_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)

	if(usable_legs < default_num_legs)
		var/limbless_slowdown = (default_num_legs - usable_legs) * 3
		if(!usable_legs && usable_hands < default_num_hands)
			limbless_slowdown += (default_num_hands - usable_hands) * 3
		var/list/slowdown_mods = list()
		SEND_SIGNAL(src, COMSIG_LIVING_LIMBLESS_SLOWDOWN, limbless_slowdown, slowdown_mods)
		for(var/num in slowdown_mods)
			limbless_slowdown *= num
		if(limbless_slowdown == 0)
			remove_movespeed_modifier(/datum/movespeed_modifier/limbless)
			return
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/limbless, multiplicative_slowdown = limbless_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/limbless)


///Proc to modify the value of num_hands and hook behavior associated to this event.
/mob/living/set_num_hands(new_value)
	if(num_hands == new_value)
		return
	. = num_hands
	num_hands = new_value
	hud_used?.update_locked_slots()

///Proc to modify the value of usable_hands and hook behavior associated to this event.
/mob/living/set_usable_hands(new_value)
	if(usable_hands == new_value)
		return
	if(new_value < 0) // Sanity check
		stack_trace("[src] had set_usable_hands() called on them with a negative value!")
		new_value = 0
	. = usable_hands
	usable_hands = new_value

	if(new_value > .) // Gained hand usage.
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)
	else if(!(movement_type & (FLYING | FLOATING)) && !usable_hands && !usable_legs) //Lost a hand, not flying, no hands left, no legs.
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, LACKING_LOCOMOTION_APPENDAGES_TRAIT)


/// Whether or not this mob will escape from storages while being picked up/held.
/mob/living/will_escape_storage()
	return FALSE

//Used specifically for the clown box suicide act
/mob/living/carbon/human/will_escape_storage()
	return TRUE

/// Changes the value of the [living/body_position] variable. Call this before set_lying_angle()
/mob/living/set_body_position(new_value)
	if(body_position == new_value)
		return
	if((new_value == LYING_DOWN) && !(mobility_flags & MOBILITY_LIEDOWN))
		return
	. = body_position
	body_position = new_value
	SEND_SIGNAL(src, COMSIG_LIVING_SET_BODY_POSITION, new_value, .)
	if(new_value == LYING_DOWN) // From standing to lying down.
		on_lying_down()
	else // From lying down to standing up.
		on_standing_up()
	update_rest_hud_icon()


/// Proc to append behavior to the condition of being floored. Called when the condition starts.
/mob/living/on_floored_start()
	on_fall()
	if(body_position == STANDING_UP) //force them on the ground
		set_body_position(LYING_DOWN)
		set_lying_angle(pick(LYING_ANGLE_EAST, LYING_ANGLE_WEST))

/// Proc to append behavior to the condition of being floored. Called when the condition ends.
/mob/living/on_floored_end()
	if(!resting)
		get_up()


/// Proc to append behavior to the condition of being handsblocked. Called when the condition starts.
/mob/living/on_handsblocked_start()
	if(active_storage)
		active_storage.hide_contents(src)
	drop_all_held_items()
	add_traits(list(TRAIT_UI_BLOCKED, TRAIT_PULL_BLOCKED), TRAIT_HANDS_BLOCKED)


/// Proc to append behavior to the condition of being handsblocked. Called when the condition ends.
/mob/living/on_handsblocked_end()
	remove_traits(list(TRAIT_UI_BLOCKED, TRAIT_PULL_BLOCKED), TRAIT_HANDS_BLOCKED)


/// Returns the attack damage type of a living mob such as [BRUTE].
/mob/living/get_attack_type()
	return BRUTE

/**
 * Returns an assoc list of assignments and minutes for updating a client's exp time in the databse.
 *
 * Arguments:
 * * minutes - The number of minutes to allocate to each valid role.
 */
/mob/living/get_exp_list(minutes)
	var/list/exp_list = list()

	if(!(mind.datum_flags & DF_VAR_EDITED))
		for(var/datum/antagonist/antag as anything in mind?.antag_datums)
			var/flag_to_check = antag.jobban_flag || antag.pref_flag
			if(flag_to_check)
				exp_list[flag_to_check] = minutes

	if(mind.assigned_role.title in GLOB.exp_specialmap[EXP_TYPE_SPECIAL])
		exp_list[mind.assigned_role.title] = minutes

	return exp_list

/**
 * A proc triggered by callback when someone gets slammed by the tram and lands somewhere.
 *
 * This proc is used to force people to fall through things like lattice and unplated flooring at the expense of some
 * extra damage, so jokers can't use half a stack of iron rods to make getting hit by the tram immediately lethal.
 */
/mob/living/tram_slam_land()
	if(!istype(loc, /turf/open/openspace)) // BANDASTATION EDIT - Cyberiad: First day of fixes for "Ghetto rework" (Removes plating checks)
		return

	// // BANDASTATION REMOVAL START - Cyberiad: First day of fixes for "Ghetto rework"
	// if(isplatingturf(loc))
	// 	var/turf/open/floor/smashed_plating = loc
	// 	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] с силой отбрасывается в [smashed_plating.declent_ru(ACCUSATIVE)], пробиваясь насквозь!"),
	// 			span_userdanger("Вас с силой отбрасывает в [smashed_plating.declent_ru(ACCUSATIVE)], пробиваясь насквозь!"))
	// 	apply_damage(rand(5,20), BRUTE, BODY_ZONE_CHEST)
	// 	smashed_plating.ScrapeAway(1, CHANGETURF_INHERIT_AIR)
	// // BANDASTATION REMOVAL END - Cyberiad: First day of fixes for "Ghetto rework"

	for(var/obj/structure/lattice/lattice in loc)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] с силой отбрасывается в [lattice.declent_ru(ACCUSATIVE)], пробиваясь насквозь!"),
			span_userdanger("Вас с силой отбрасывает в [lattice.declent_ru(ACCUSATIVE)], пробиваясь насквозь!"))
		apply_damage(rand(5,10), BRUTE, BODY_ZONE_CHEST)
		lattice.deconstruct(FALSE)

/// Prints an ominous message if something bad is going to happen to you
/mob/living/ominous_nosebleed()
	to_chat(src, span_warning("Вы на мгновение чувствуете легкую тошноту."))

/**
 * Proc used by different station pets such as Ian and Poly so that some of their data can persist between rounds.
 * This base definition only contains a trait and comsig to stop memory from being (over)written.
 * Specific behavior is defined on subtypes that use it.
 */
/mob/living/Write_Memory(dead, gibbed)
	if(HAS_TRAIT(src, TRAIT_DONT_WRITE_MEMORY)) //always prevent data from being written.
		return FALSE
	// for selective behaviors that may or may not prevent data from being written.
	if(SEND_SIGNAL(src, COMSIG_LIVING_WRITE_MEMORY, dead, gibbed) & COMPONENT_DONT_WRITE_MEMORY)
		return FALSE
	return TRUE

/// Admin only proc for giving a certain speech impediment to this mob
/mob/living/admin_give_speech_impediment(mob/admin)
	if(!admin || !check_rights(NONE))
		return

	var/list/impediments = list()
	for(var/datum/status_effect/possible as anything in typesof(/datum/status_effect/speech))
		if(!initial(possible.id))
			continue

		impediments[initial(possible.id)] = possible

	var/chosen = tgui_input_list(admin, "What speech impediment?", "Impede Speech", impediments)
	if(!chosen || !ispath(impediments[chosen], /datum/status_effect/speech) || QDELETED(src) || !check_rights(NONE))
		return

	var/duration = tgui_input_number(admin, "How long should it last (in seconds)? Max is infinite duration.", "Duration", 0, INFINITY, 0 SECONDS)
	if(!isnum(duration) || duration <= 0 || QDELETED(src) || !check_rights(NONE))
		return

	adjust_timed_status_effect(duration * 1 SECONDS, impediments[chosen])

/mob/living/admin_add_mood_event(mob/admin)
	if (!admin || !check_rights(NONE))
		return

	var/list/mood_events = typesof(/datum/mood_event)

	var/chosen = tgui_input_list(admin, "What mood event?", "Add Mood Event", mood_events)
	if (!chosen || QDELETED(src) || !check_rights(NONE))
		return

	mob_mood.add_mood_event("[rand(1, 50)]", chosen)

/mob/living/admin_remove_mood_event(mob/admin)
	if (!admin || !check_rights(NONE))
		return

	var/list/mood_events = list()
	for (var/category in mob_mood.mood_events)
		var/datum/mood_event/event = mob_mood.mood_events[category]
		mood_events[event] = category


	var/datum/mood_event/chosen = tgui_input_list(admin, "What mood event?", "Remove Mood Event", mood_events)
	if (!chosen || QDELETED(src) || !check_rights(NONE))
		return

	mob_mood.clear_mood_event(mood_events[chosen])

/// Adds a mood event to the mob
/mob/living/add_mood_event(category, type, ...)
	if(QDELETED(mob_mood))
		return

	if(ispath(type, /datum/mood_event/conditional))
		mob_mood.add_conditional_mood_event(arglist(args))
	else
		mob_mood.add_mood_event(arglist(args))

/// Clears a mood event from the mob
/mob/living/clear_mood_event(category)
	if(QDELETED(mob_mood))
		return
	mob_mood.clear_mood_event(category)

/// This should be called by games when the gamer reaches a winning state, just sends a signal
/mob/living/won_game()
	SEND_SIGNAL(src, COMSIG_MOB_WON_VIDEOGAME)

/// This should be called by games when the gamer reaches a losing state, just sends a signal
/mob/living/lost_game()
	SEND_SIGNAL(src, COMSIG_MOB_LOST_VIDEOGAME)

/// This should be called by games whenever the gamer interacts with the device, sends a signal and grants us a moodlet
/mob/living/played_game()
	SEND_SIGNAL(src, COMSIG_MOB_PLAYED_VIDEOGAME)
	add_mood_event("gaming", /datum/mood_event/gaming)

/**
 * Helper proc for basic and simple animals to return true if the passed sentience type matches theirs
 * Living doesn't have a sentience type though so it always returns false if not a basic or simple mob
 */
/mob/living/compare_sentience_type(compare_type)
	return FALSE

/// Proc called when TARGETED by a lazarus injector
/mob/living/lazarus_revive(mob/living/reviver, malfunctioning)
	revive(HEAL_ALL)
	add_faction(FACTION_NEUTRAL)
	if (!malfunctioning)
		befriend(reviver)
	var/lazarus_policy = get_policy(ROLE_LAZARUS_GOOD) || "Вы вернулись к жизни благодаря инъектору лазаруса! Вы теперь дружественны ко всем."
	if (malfunctioning)
		reviver.log_message("has revived mob [key_name(src)] with a malfunctioning lazarus injector.", LOG_GAME)
		if(!isnull(src.mind))
			src.mind.enslave_mind_to_creator(reviver)
		to_chat(src, span_userdanger("[capitalize(reviver.real_name)] - ваш хозяин. Помогайте хозяину во всем любой ценой."))
		lazarus_policy = get_policy(ROLE_LAZARUS_BAD) || "Вы вернулись к жизни благодаря неисправному инъектору лазаруса! Вы теперь слуга того, кто вас вернул к жизни."
	to_chat(src, span_boldnotice(lazarus_policy))

/// Proc for giving a mob a new 'friend', generally used for AI control and targeting. Returns false if already friends or null if qdeleted.
/mob/living/befriend(mob/living/new_friend)
	SEND_SIGNAL(new_friend, COMSIG_LIVING_MADE_NEW_FRIEND, src)
	if(QDELETED(new_friend))
		return
	var/friend_ref = REF(new_friend)
	if (has_ally(friend_ref))
		return FALSE
	add_ally(friend_ref)
	ai_controller?.insert_blackboard_key_lazylist(BB_FRIENDS_LIST, new_friend)

	SEND_SIGNAL(src, COMSIG_LIVING_BEFRIENDED, new_friend)
	return TRUE

/// Proc for removing a friend you added with the proc 'befriend'. Returns true if you removed a friend.
/mob/living/unfriend(mob/living/old_friend)
	var/friend_ref = REF(old_friend)
	if (!has_ally(friend_ref))
		return FALSE
	remove_ally(friend_ref)
	ai_controller?.remove_thing_from_blackboard_key(BB_FRIENDS_LIST, old_friend)

	SEND_SIGNAL(src, COMSIG_LIVING_UNFRIENDED, old_friend)
	return TRUE

/**
 * Common proc used to deduct money from cargo, announce the kidnapping and add src to the black market.
 * Returns the black market item, for extra stuff like signals that need to be registered.
 */
/mob/living/process_capture(ransom_price, black_market_price)
	if(ransom_price > 0)
		var/datum/bank_account/cargo_account = SSeconomy.get_dep_account(ACCOUNT_CAR)

		if(cargo_account) //Just in case
			cargo_account.adjust_money(-min(ransom_price, cargo_account.account_balance)) //Not so much, especially for competent cargo. Plus this can't be mass-triggered like it has been done with contractors
		priority_announce("Один из членов экипажа был захвачен конкурирущей организацией - нам пришлось заплатить выкуп, чтобы вернуть его назад. В соответствии с политикой компании, часть средств станции была изъята для компенсации.", "Защита активов Нанотрейзен", has_important_message = TRUE)

	///The price should be high enough that the contractor can't just buy 'em back with their cut alone.
	var/datum/market_item/hostage/market_item = new(src, black_market_price || ransom_price)
	SSmarket.markets[/datum/market/blackmarket].add_item(market_item)

	if(mind)
		ADD_TRAIT(mind, TRAIT_HAS_BEEN_KIDNAPPED, TRAIT_GENERIC)
	return market_item

/// Admin only proc for making the mob hallucinate a certain thing
/mob/living/admin_give_hallucination(mob/admin)
	if(!admin || !check_rights(NONE))
		return

	var/chosen = select_hallucination_type(admin, "What hallucination do you want to give to [src]?", "Give Hallucination")
	if(!chosen || QDELETED(src) || !check_rights(NONE))
		return

	if(!cause_hallucination(chosen, "admin forced by [key_name_admin(admin)]"))
		to_chat(admin, "That hallucination ([chosen]) could not be run - it may be invalid with this type of mob or has no effects.")
		return

	message_admins("[key_name_admin(admin)] gave [ADMIN_LOOKUPFLW(src)] a hallucination. (Type: [chosen])")
	log_admin("[key_name(admin)] gave [src] a hallucination. (Type: [chosen])")

/// Admin only proc for giving the mob a delusion hallucination with specific arguments
/mob/living/admin_give_delusion(mob/admin)
	if(!admin || !check_rights(NONE))
		return

	var/list/delusion_args = create_delusion(admin)
	if(QDELETED(src) || !check_rights(NONE) || !length(delusion_args))
		return

	delusion_args[2] = "admin forced"
	message_admins("[key_name_admin(admin)] gave [ADMIN_LOOKUPFLW(src)] a delusion hallucination. (Type: [delusion_args[1]])")
	log_admin("[key_name(admin)] gave [src] a delusion hallucination. (Type: [delusion_args[1]])")
	// Not using the wrapper here because we already have a list / arglist
	_cause_hallucination(delusion_args)

/mob/living/admin_give_guardian(mob/admin)
	if(!admin || !check_rights(NONE))
		return
	var/del_mob = FALSE
	var/mob/old_mob
	var/list/possible_players = list("Poll Ghosts") + sort_list(GLOB.clients)
	var/client/guardian_client = tgui_input_list(admin, "Pick the player to put in control.", "Guardian Controller", possible_players)
	if(isnull(guardian_client))
		return
	else if(guardian_client == "Poll Ghosts")
		var/mob/chosen_one = SSpolling.poll_ghost_candidates("Do you want to play as an admin created [span_notice("Guardian Spirit")] of [span_danger(real_name)]?", check_jobban = ROLE_PAI, poll_time = 10 SECONDS, ignore_category = POLL_IGNORE_HOLOPARASITE, alert_pic = mutable_appearance('icons/mob/nonhuman-player/guardian.dmi', "magicexample"), jump_target = src, role_name_text = "guardian spirit", amount_to_pick = 1)
		if(chosen_one)
			guardian_client = chosen_one.client
		else
			tgui_alert(admin, "No ghost candidates.", "Guardian Controller")
			return
	else
		old_mob = guardian_client.mob
		if(isobserver(old_mob) || tgui_alert(admin, "Do you want to delete [guardian_client]'s old mob?", "Guardian Controller", list("Yes"," No")) == "Yes")
			del_mob = TRUE
	var/picked_type = tgui_input_list(admin, "Pick the guardian type.", "Guardian Controller", subtypesof(/mob/living/basic/guardian))
	var/picked_theme = tgui_input_list(admin, "Pick the guardian theme.", "Guardian Controller", list(GUARDIAN_THEME_TECH, GUARDIAN_THEME_MAGIC, GUARDIAN_THEME_CARP, GUARDIAN_THEME_MINER, "Random"))
	if(picked_theme == "Random")
		picked_theme = null //holopara code handles not having a theme by giving a random one
	var/picked_name = tgui_input_text(admin, "Name the guardian, leave empty to let player name it.", "Guardian Controller", max_length = MAX_NAME_LEN)
	var/picked_color = tgui_color_picker(admin, "Set the guardian's color, cancel to let player set it.", "Guardian Controller", COLOR_WHITE)
	if(tgui_alert(admin, "Confirm creation.", "Guardian Controller", list("Yes", "No")) != "Yes")
		return
	var/mob/living/basic/guardian/summoned_guardian = new picked_type(src, picked_theme)
	summoned_guardian.set_summoner(src, different_person = TRUE)
	if(picked_name)
		summoned_guardian.fully_replace_character_name(null, picked_name)
	if(picked_color)
		summoned_guardian.set_guardian_colour(picked_color)
	summoned_guardian.PossessByPlayer(guardian_client?.key)
	guardian_client?.init_verbs()
	if(del_mob)
		qdel(old_mob)
	message_admins(span_adminnotice("[key_name_admin(admin)] gave a guardian spirit controlled by [guardian_client || "AI"] to [src]."))
	log_admin("[key_name(admin)] gave a guardian spirit controlled by [guardian_client] to [src].")
	BLACKBOX_LOG_ADMIN_VERB("Give Guardian Spirit")

/mob/living/lookup()
	if(looking_vertically)
		to_chat(src, "Вы снова смотрите вперед.")
		end_look()
		return

	var/turf/current_turf = get_turf(src)
	var/turf/above_turf = GET_TURF_ABOVE(current_turf)

	//Check if turf above exists
	if(!above_turf)
		to_chat(src, span_warning("Сверху нет ничего интересного. Лучше смотрите вперед."))
		return

	to_chat(src, "Вы наклоняете голову вверх.")
	look_up()

/mob/living/lookdown()
	if(looking_vertically)
		to_chat(src, "Вы снова смотрите вперёд.")
		end_look()
		return

	var/turf/current_turf = get_turf(src)
	var/turf/below_turf = GET_TURF_BELOW(current_turf)

	//Check if turf below exists
	if(!below_turf)
		to_chat(src, span_warning("Снизу нет ничего интересного. Лучше смотрите вперед."))
		return

	to_chat(src, "Вы наклоняете голову вниз.")
	look_down()

/mob/living/verb/toggle_stealth()
	set name = "Toggle Stealth"
	set category = "IC"

	if(stat > SOFT_CRIT || INCAPACITATED_IGNORING(src, INCAPABLE_RESTRAINTS))
		return
	toggle_stealth_mode()

/mob/living/verb/toggle_listening()
	set name = "Listen Carefully"
	set category = "IC"

	if(stat > SOFT_CRIT || HAS_TRAIT(src, TRAIT_DEAF))
		return
	toggle_intent_listen()

/mob/living/verb/toggle_focused_look_verb()
	set name = "Focus Look"
	set category = "IC"

	if(stat > SOFT_CRIT || is_blind())
		return
	toggle_focused_look()

/**
 * Totals the physical cash on the mob and returns the total.
 */
/mob/living/tally_physical_credits()
	//Here is all the possible non-ID payment methods.
	var/list/counted_money = list()
	var/physical_cash_total = 0
	for(var/obj/item/credit as anything in typecache_filter_list(get_all_contents(), GLOB.allowed_money)) //Coins, cash, and credits.
		physical_cash_total += credit.get_item_credit_value()
		counted_money += credit

	if(is_type_in_typecache(pulling, GLOB.allowed_money)) //Coins(Pulled).
		var/obj/item/counted_credit = pulling
		physical_cash_total += counted_credit.get_item_credit_value()
		counted_money += counted_credit
	return round(physical_cash_total)

/// Returns an arbitrary number which very roughly correlates with how buff you look
/mob/living/calculate_fitness()
	var/athletics_level = mind?.get_skill_level(/datum/skill/athletics) || 1
	var/damage = (melee_damage_lower + melee_damage_upper) / 2

	return ceil(damage * (ceil(athletics_level / 2)) * maxHealth)

/// Create a report string about how strong this person looks, generated in a somewhat arbitrary fashion
/mob/living/compare_fitness(mob/living/scouter)
	if (HAS_TRAIT(src, TRAIT_UNKNOWN_APPEARANCE))
		return span_warning("Невозможно сказать, качается ли эта личность.")

	var/our_fitness_level = calculate_fitness()
	var/their_fitness_level = scouter.calculate_fitness()

	var/comparative_fitness = their_fitness_level ? our_fitness_level / their_fitness_level : 1

	if (comparative_fitness > 2)
		scouter.set_jitter_if_lower(comparative_fitness SECONDS)
		return "[span_notice("Вы оцениваете, что [ru_p_them()] примерный уровень фитнеса равен...")] [span_boldwarning("Что?!? [our_fitness_level]???")]"

	return span_notice("Вы оцениваете, что [ru_p_them()] примерный уровень фитнеса равен [our_fitness_level]. [comparative_fitness <= 0.33 ? "Жалость." : ""]")

///Performs the aftereffects of blocking a projectile.
/mob/living/block_projectile_effects()
	var/static/list/icon/blocking_overlay
	if(isnull(blocking_overlay))
		blocking_overlay = list(
			mutable_appearance('icons/mob/effects/blocking.dmi', "wow"),
			mutable_appearance('icons/mob/effects/blocking.dmi', "nice"),
			mutable_appearance('icons/mob/effects/blocking.dmi', "good"),
		)
	ADD_TRAIT(src, TRAIT_BLOCKING_PROJECTILES, BLOCKING_TRAIT)
	var/icon/selected_overlay = pick(blocking_overlay)
	add_overlay(selected_overlay)
	playsound(src, 'sound/items/weapons/fwoosh.ogg', 90, FALSE, frequency = 0.7)
	update_transform(1.25)
	addtimer(CALLBACK(src, PROC_REF(end_block_effects), selected_overlay), 0.6 SECONDS)

///Remoevs the effects of blocking a projectile and allows the user to block another.
/mob/living/end_block_effects(selected_overlay)
	REMOVE_TRAIT(src, TRAIT_BLOCKING_PROJECTILES, BLOCKING_TRAIT)
	cut_overlay(selected_overlay)
	update_transform(0.8)

/// Returns the string form of the def_zone we have hit.
/mob/living/check_hit_limb_zone_name(hit_zone)
	if(has_limbs)
		return hit_zone

/mob/living/painful_scream(force = FALSE)
	if(HAS_TRAIT(src, TRAIT_ANALGESIA) && !force)
		return
	INVOKE_ASYNC(src, PROC_REF(emote), "scream")
