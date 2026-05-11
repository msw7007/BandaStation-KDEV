/mob/living/carbon/apply_damage(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	blocked = 0,
	forced = FALSE,
	spread_damage = FALSE,
	wound_bonus = 0,
	exposed_wound_bonus = 0,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
	wound_clothing = TRUE,
)
	// Spread damage should always have def zone be null
	if(spread_damage)
		def_zone = null

	// Otherwise if def zone is null, we'll get a random bodypart / zone to hit.
	// ALso we'll automatically covnert string def zones into bodyparts to pass into parent call.
	else if(!isbodypart(def_zone))
		var/random_zone = check_zone(def_zone || get_random_valid_zone(def_zone))
		def_zone = get_bodypart(random_zone) || get_bodypart()

	. = ..()
	// Taking brute or burn to bodyparts gives a damage flash
	if(def_zone && (damagetype == BRUTE || damagetype == BURN))
		damageoverlaytemp += .

	return .

/mob/living/carbon/human/get_damage_mod(damage_type)
	if (!dna?.species?.damage_modifier)
		return ..()
	var/species_mod = (100 - dna.species.damage_modifier) / 100
	return ..() * species_mod

/mob/living/carbon/human/apply_damage(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	blocked = 0,
	forced = FALSE,
	spread_damage = FALSE,
	wound_bonus = 0,
	exposed_wound_bonus = 0,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
	wound_clothing = TRUE,
)

	// Add relevant DR modifiers into blocked value to pass to parent
	blocked += physiology?.damage_resistance
	blocked += dna?.species?.damage_modifier
	return ..()

/mob/living/carbon/human/get_incoming_damage_modifier(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
)
	var/final_mod = ..()

	switch(damagetype)
		if(BRUTE)
			final_mod *= physiology.brute_mod
		if(BLUNT)
			final_mod *= physiology.blunt_mod
		if(PIERCE)
			final_mod *= physiology.pierce_mod
		if(SLASH)
			final_mod *= physiology.slash_mod
		if(BURN)
			final_mod *= physiology.burn_mod
		if(FIRE)
			final_mod *= physiology.fire_mod
		if(COLD)
			final_mod *= physiology.cold_damage_mod
		if(ACID_DAMAGE)
			final_mod *= physiology.acid_mod
		if(PSYCHIC)
			final_mod *= physiology.psychic_mod
		if(PAIN)
			final_mod *= physiology.pain_mod
		if(TOX)
			final_mod *= physiology.tox_mod
		if(OXY)
			final_mod *= physiology.oxy_mod
		if(STAMINA)
			final_mod *= physiology.stamina_mod
		if(BRAIN)
			final_mod *= physiology.brain_mod

	return final_mod

//These procs fetch a cumulative total damage from all bodyparts
/mob/living/carbon/get_brute_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.get_brute_damage()
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_fire_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.get_burn_damage()
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_blunt_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.blunt_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_pierce_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.pierce_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_slash_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.slash_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_heat_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.heat_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_cold_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.cold_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_acid_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.acid_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_pain_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.get_pain_damage()
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/sync_pain_damage()
	painloss = get_pain_loss()
	if(painloss > 100)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/pain_slowdown, TRUE, multiplicative_slowdown = min(painloss / 150, 3))
		add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/pain_slowdown, TRUE, multiplicative_slowdown = min(painloss / 200, 2))
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/pain_slowdown)
		remove_actionspeed_modifier(/datum/actionspeed_modifier/pain_slowdown)

/**
 * Returns the amount of bruteloss across all bodyparts meeting the matching bodytype.
 * Useful for if you would like to check the bruteloss for only organic bodyparts, for example.
 *
 * Arguments:
 * *  required_bodytype - The bodytype(s) to match against.
 */
/mob/living/carbon/proc/get_brute_loss_for_type(required_bodytype = ALL)
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		if(!(bodypart.bodytype & required_bodytype))
			continue
		amount += bodypart.get_brute_damage()
	return round(amount, DAMAGE_PRECISION)

/**
 * Returns the amount of fireloss across all bodyparts meeting the matching bodytype.
 * Useful for if you would like to check the fireloss for only organic bodyparts, for example.
 *
 * Arguments:
 * *  required_bodytype - The bodytype(s) to match against.
 */
/mob/living/carbon/proc/get_fire_loss_for_type(required_bodytype = ALL)
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		if(!(bodypart.bodytype & required_bodytype))
			continue
		amount += bodypart.get_burn_damage()
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/adjust_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(brute = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(brute = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_blunt_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(blunt = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(blunt = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_pierce_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(pierce = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(pierce = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_slash_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(slash = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(slash = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/set_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	var/current = get_brute_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_brute_loss(diff, updating_health, forced, required_bodytype)

/mob/living/carbon/adjust_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(burn = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(burn = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_heat_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(fire = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(fire = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_cold_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(cold = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(cold = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_acid_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(acid = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype)
	else
		. = heal_overall_damage(acid = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/adjust_pain_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	if(amount > 0)
		var/list/obj/item/bodypart/parts = get_bodyparts()
		while(parts.len && amount > 0)
			var/obj/item/bodypart/picked = pick(parts)
			var/pain_per_part = round(amount / parts.len, DAMAGE_PRECISION)
			var/old_pain = picked.get_pain_damage()
			. += picked.adjust_pain_damage(pain_per_part)
			amount = round(amount - (picked.get_pain_damage() - old_pain), DAMAGE_PRECISION)
			parts -= picked
	else
		var/healing = abs(amount)
		var/list/obj/item/bodypart/parts = get_bodyparts()
		while(parts.len && healing > 0)
			var/obj/item/bodypart/picked = pick(parts)
			var/old_pain = picked.get_pain_damage()
			. += picked.adjust_pain_damage(-healing)
			healing = round(healing - (old_pain - picked.get_pain_damage()), DAMAGE_PRECISION)
			parts -= picked
	sync_pain_damage()
	if(. && updating_health)
		updatehealth()

/mob/living/carbon/can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type)
	if(!resolving_blood_oxygenation)
		return FALSE
	return ..()

/mob/living/carbon/set_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	var/current = get_fire_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_fire_loss(diff, updating_health, forced, required_bodytype)

/mob/living/carbon/human/proc/route_toxin_damage_through_organs(amount)
	if(amount <= 0 || HAS_TRAIT(src, TRAIT_TOXINLOVER) || HAS_TRAIT(src, TRAIT_TOXIMMUNE))
		return amount
	if(HAS_TRAIT(src, TRAIT_LIVERLESS_METABOLISM))
		return amount

	var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	if(!liver)
		return amount * 1.25

	return liver.filter_toxin_damage(amount)

/mob/living/carbon/human/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(amount > 0 && !forced && !HAS_TRAIT(src, TRAIT_GODMODE) && (mob_biotypes & required_biotype))
		amount = route_toxin_damage_through_organs(amount)
	. = ..()
	if(. >= 0) // 0 = no damage, + values = healed damage
		return .

	if(AT_TOXIN_VOMIT_THRESHOLD(src))
		apply_status_effect(/datum/status_effect/tox_vomit)

/mob/living/carbon/human/set_tox_loss(amount, updating_health, forced, required_biotype)
	. = ..()
	if(. >= 0)
		return .

	if(AT_TOXIN_VOMIT_THRESHOLD(src))
		apply_status_effect(/datum/status_effect/tox_vomit)

/mob/living/carbon/received_stamina_damage(current_level, amount_actual, amount)
	. = ..()
	if((maxHealth - current_level) <= critical_health_threshold && stat != DEAD)
		apply_status_effect(/datum/status_effect/incapacitating/stamcrit)

/**
 * If an organ exists in the slot requested, and we are capable of taking damage (we don't have TRAIT_GODMODE), call the damage proc on that organ.
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 * * amount - damage to be done
 * * maximum - currently an arbitrarily large number, can be set so as to limit damage
 * * required_organ_flag - targets only a specific organ type if set to ORGAN_ORGANIC or ORGAN_ROBOTIC
 *
 * Returns: The net change in damage from apply_organ_damage()
 */
/mob/living/carbon/adjust_organ_loss(slot, amount, maximum, required_organ_flag = NONE)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(!affected_organ || HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(required_organ_flag && !(affected_organ.organ_flags & required_organ_flag))
		return FALSE
	return affected_organ.apply_organ_damage(amount, maximum)

/**
 * If an organ exists in the slot requested, and we are capable of taking damage (we don't have TRAIT_GODMODE), call the set damage proc on that organ, which can
 * set or clear the failing variable on that organ, making it either cease or start functions again, unlike adjust_organ_loss.
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 * * amount - damage to be set to
 * * required_organ_flag - targets only a specific organ type if set to ORGAN_ORGANIC or ORGAN_ROBOTIC
 *
 * Returns: The net change in damage from set_organ_damage()
 */
/mob/living/carbon/set_organ_loss(slot, amount, required_organ_flag = NONE)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(!affected_organ || HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(required_organ_flag && !(affected_organ.organ_flags & required_organ_flag))
		return FALSE
	if(affected_organ.damage == amount)
		return FALSE
	return affected_organ.set_organ_damage(amount)

/**
 * If an organ exists in the slot requested, return the amount of damage that organ has
 *
 * Arguments:
 * * slot - organ slot, like [ORGAN_SLOT_HEART]
 * * required_organ_flag - if you only want to check the damage of organs with the specified organ_flag(s) then you can use this.
 */
/mob/living/carbon/get_organ_loss(slot, required_organ_flag = NONE)
	var/obj/item/organ/affected_organ = get_organ_slot(slot)
	if(affected_organ)
		if(required_organ_flag && !(affected_organ.organ_flags & required_organ_flag))
			return
		return affected_organ.damage

////////////////////////////////////////////

///Returns a list of damaged bodyparts
/mob/living/carbon/proc/get_damaged_bodyparts(brute = FALSE, burn = FALSE, required_bodytype = NONE, target_zone = null)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/BP as anything in get_bodyparts())
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(!isnull(target_zone) && BP.body_zone != target_zone)
			continue
		if((brute && BP.get_brute_damage()) || (burn && BP.get_burn_damage()))
			parts += BP
	return parts

///Returns a list of damageable bodyparts
/mob/living/carbon/proc/get_damageable_bodyparts(required_bodytype)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/BP as anything in get_bodyparts())
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(BP.get_damage() < BP.max_damage)
			parts += BP
	return parts


///Returns a list of bodyparts with wounds (in case someone has a wound on an otherwise fully healed limb)
/mob/living/carbon/proc/get_wounded_bodyparts(required_bodytype)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/BP as anything in get_bodyparts())
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(LAZYLEN(BP.wounds))
			parts += BP
	return parts

/**
 * Heals ONE bodypart randomly selected from damaged ones.

 * It automatically updates damage overlays if necessary
 *
 * It automatically updates health status
 */
/mob/living/carbon/heal_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype = NONE, target_zone = null)
	. = FALSE
	var/list/obj/item/bodypart/parts = get_damaged_bodyparts(brute, burn, required_bodytype, target_zone)
	if(!parts.len)
		return

	var/obj/item/bodypart/picked = pick(parts)
	var/damage_calculator = picked.get_damage() //heal_damage returns update status T/F instead of amount healed so we dance gracefully around this
	if(picked.heal_damage(abs(brute), abs(burn), required_bodytype = required_bodytype))
		update_damage_overlays()
	return (damage_calculator - picked.get_damage())


/**
 * Damages ONE bodypart randomly selected from damagable ones.
 *
 * It automatically updates damage overlays if necessary
 *
 * It automatically updates health status
 */
/mob/living/carbon/take_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype, check_armor = FALSE, wound_bonus = 0, exposed_wound_bonus = 0, sharpness = NONE)
	. = FALSE
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	var/list/obj/item/bodypart/parts = get_damageable_bodyparts(required_bodytype)
	if(!parts.len)
		return

	var/obj/item/bodypart/picked = pick(parts)
	var/damage_calculator = picked.get_damage()
	if(picked.receive_damage(abs(brute), abs(burn), check_armor ? run_armor_check(picked, (brute ? MELEE : burn ? FIRE : null)) : FALSE, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness))
		update_damage_overlays()
	return (damage_calculator - picked.get_damage())

/mob/living/carbon/heal_overall_damage(brute = 0, burn = 0, stamina = 0, required_bodytype, updating_health = TRUE, forced = FALSE, blunt = 0, pierce = 0, slash = 0, fire = 0, cold = 0, acid = 0)
	. = FALSE
	// treat negative args as positive
	brute = abs(brute)
	burn = abs(burn)
	if(brute)
		blunt += brute / 3
		pierce += brute / 3
		slash += brute / 3
	if(burn)
		fire += burn / 3
		cold += burn / 3
		acid += burn / 3

	var/list/obj/item/bodypart/parts = get_damaged_bodyparts(brute || blunt || pierce || slash, burn || fire || cold || acid, required_bodytype)

	var/update = NONE
	while(parts.len && (blunt > 0 || pierce > 0 || slash > 0 || fire > 0 || cold > 0 || acid > 0))
		var/obj/item/bodypart/picked = pick(parts)

		var/blunt_was = picked.blunt_dam
		var/pierce_was = picked.pierce_dam
		var/slash_was = picked.slash_dam
		var/fire_was = picked.heat_dam
		var/cold_was = picked.cold_dam
		var/acid_was = picked.acid_dam
		. += picked.get_damage()

		update |= picked.heal_damage(updating_health = FALSE, forced = forced, required_bodytype = required_bodytype, blunt = blunt, pierce = pierce, slash = slash, fire = fire, cold = cold, acid = acid)

		. -= picked.get_damage() // return the net amount of damage healed

		blunt = round(blunt - (blunt_was - picked.blunt_dam), DAMAGE_PRECISION)
		pierce = round(pierce - (pierce_was - picked.pierce_dam), DAMAGE_PRECISION)
		slash = round(slash - (slash_was - picked.slash_dam), DAMAGE_PRECISION)
		fire = round(fire - (fire_was - picked.heat_dam), DAMAGE_PRECISION)
		cold = round(cold - (cold_was - picked.cold_dam), DAMAGE_PRECISION)
		acid = round(acid - (acid_was - picked.acid_dam), DAMAGE_PRECISION)

		parts -= picked

	if(!.) // no change? no need to update anything
		return

	if(updating_health)
		updatehealth()
	if(update)
		update_damage_overlays()

/mob/living/carbon/take_overall_damage(brute = 0, burn = 0, stamina = 0, updating_health = TRUE, forced = FALSE, required_bodytype, blunt = 0, pierce = 0, slash = 0, fire = 0, cold = 0, acid = 0)
	. = FALSE
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return
	// treat negative args as positive
	brute = abs(brute)
	burn = abs(burn)
	if(brute)
		blunt += brute / 3
		pierce += brute / 3
		slash += brute / 3
	if(burn)
		fire += burn / 3
		cold += burn / 3
		acid += burn / 3

	var/list/obj/item/bodypart/parts = get_damageable_bodyparts(required_bodytype)
	var/update = NONE
	while(parts.len && (blunt > 0 || pierce > 0 || slash > 0 || fire > 0 || cold > 0 || acid > 0))
		var/obj/item/bodypart/picked = pick(parts)
		var/blunt_per_part = round(blunt/parts.len, DAMAGE_PRECISION)
		var/pierce_per_part = round(pierce/parts.len, DAMAGE_PRECISION)
		var/slash_per_part = round(slash/parts.len, DAMAGE_PRECISION)
		var/fire_per_part = round(fire/parts.len, DAMAGE_PRECISION)
		var/cold_per_part = round(cold/parts.len, DAMAGE_PRECISION)
		var/acid_per_part = round(acid/parts.len, DAMAGE_PRECISION)

		var/blunt_was = picked.blunt_dam
		var/pierce_was = picked.pierce_dam
		var/slash_was = picked.slash_dam
		var/fire_was = picked.heat_dam
		var/cold_was = picked.cold_dam
		var/acid_was = picked.acid_dam
		. += picked.get_damage()

		// disabling wounds from these for now cuz your entire body snapping cause your heart stopped would suck
		update |= picked.receive_damage(blocked = FALSE, updating_health = FALSE, forced = forced, required_bodytype = required_bodytype, wound_bonus = CANT_WOUND, blunt = blunt_per_part, pierce = pierce_per_part, slash = slash_per_part, fire = fire_per_part, cold = cold_per_part, acid = acid_per_part)

		. -= picked.get_damage() // return the net amount of damage healed

		blunt = round(blunt - (picked.blunt_dam - blunt_was), DAMAGE_PRECISION)
		pierce = round(pierce - (picked.pierce_dam - pierce_was), DAMAGE_PRECISION)
		slash = round(slash - (picked.slash_dam - slash_was), DAMAGE_PRECISION)
		fire = round(fire - (picked.heat_dam - fire_was), DAMAGE_PRECISION)
		cold = round(cold - (picked.cold_dam - cold_was), DAMAGE_PRECISION)
		acid = round(acid - (picked.acid_dam - acid_was), DAMAGE_PRECISION)

		parts -= picked

	if(!.) // no change? no need to update anything
		return

	if(updating_health)
		updatehealth()
	if(update)
		update_damage_overlays()
