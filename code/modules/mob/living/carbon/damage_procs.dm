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
	brute_type = null,
	burn_type = null,
	precise_zone = null,
)
	// Spread damage should always have def zone be null
	if(spread_damage)
		def_zone = null

	// Otherwise if def zone is null, we'll get a random bodypart / zone to hit.
	// ALso we'll automatically covnert string def zones into bodyparts to pass into parent call.
	else if(!isbodypart(def_zone))
		precise_zone ||= def_zone
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
	brute_type = null,
	burn_type = null,
	precise_zone = null,
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
		if(BURN)
			final_mod *= physiology.burn_mod
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
		amount += bodypart.brute_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/get_fire_loss()
	var/amount = 0
	for(var/obj/item/bodypart/bodypart as anything in get_bodyparts())
		amount += bodypart.burn_dam
	return round(amount, DAMAGE_PRECISION)


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
		amount += bodypart.brute_dam
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
		amount += bodypart.burn_dam
	return round(amount, DAMAGE_PRECISION)

/mob/living/carbon/adjust_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype, brute_type = BODYPART_DAMAGE_BLUNT)
	if(!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(brute = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype, brute_type = brute_type)
	else
		. = heal_overall_damage(brute = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/set_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	var/current = get_brute_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_brute_loss(diff, updating_health, forced, required_bodytype)

/mob/living/carbon/adjust_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype, burn_type = BODYPART_DAMAGE_HEAT)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	if(amount > 0)
		. = take_overall_damage(burn = amount, updating_health = updating_health, forced = forced, required_bodytype = required_bodytype, burn_type = burn_type)
	else
		. = heal_overall_damage(burn = abs(amount), required_bodytype = required_bodytype, updating_health = updating_health, forced = forced)

/mob/living/carbon/set_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	var/current = get_fire_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_fire_loss(diff, updating_health, forced, required_bodytype)

/mob/living/carbon/get_oxy_loss()
	return round(max(0, 100 - oxygenation), DAMAGE_PRECISION)

/mob/living/carbon/proc/get_chemical_loss()
	return round(chemical_loss, DAMAGE_PRECISION)

/mob/living/carbon/proc/adjust_chemical_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	. = chemical_loss
	chemical_loss = clamp(chemical_loss + amount * CONFIG_GET(number/damage_multiplier), 0, maxHealth * 2)
	. -= chemical_loss
	if(!.)
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/carbon/proc/set_chemical_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	. = chemical_loss
	chemical_loss = clamp(amount, 0, maxHealth * 2)
	. -= chemical_loss
	if(!.)
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/carbon/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!can_adjust_tox_loss(amount, forced, required_biotype))
		return 0
	if(!forced && HAS_TRAIT(src, TRAIT_TOXINLOVER))
		amount = -amount
		if(HAS_TRAIT(src, TRAIT_TOXIMMUNE))
			amount = min(amount, 0)
		if(amount > 0)
			adjust_blood_volume(-5 * amount)
		else
			adjust_blood_volume(-amount)
	else if(!forced && HAS_TRAIT(src, TRAIT_TOXIMMUNE))
		amount = min(amount, 0)
	. = toxloss
	toxloss = clamp(toxloss + amount * CONFIG_GET(number/damage_multiplier), 0, maxHealth * 2)
	if(toxloss > .)
		apply_toxin_effects_to_organs(toxloss - .)
	. -= toxloss
	if(!.)
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/carbon/set_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(!forced && !(mob_biotypes & required_biotype))
		return FALSE
	. = toxloss
	toxloss = clamp(amount, 0, maxHealth * 2)
	if(toxloss > .)
		apply_toxin_effects_to_organs(toxloss - .)
	. -= toxloss
	if(!.)
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/carbon/proc/apply_toxin_effects_to_organs(amount)
	if(amount <= 0)
		return
	var/obj/item/organ/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && !(liver.organ_flags & ORGAN_FAILING) && liver.damage < liver.maxHealth)
		liver.apply_organ_damage(amount / 5, required_organ_flag = ORGAN_ORGANIC)
		return
	var/list/targets = list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_BRAIN, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_TONGUE)
	var/split_amount = amount / max(length(targets), 1)
	for(var/slot in targets)
		adjust_organ_loss(slot, split_amount, required_organ_flag = ORGAN_ORGANIC)

/mob/living/carbon/proc/get_total_pain()
	. = 0
	for(var/obj/item/bodypart/part as anything in get_bodyparts(include_stumps = TRUE))
		. += part.pain
	for(var/obj/item/organ/organ as anything in organs)
		. += organ.pain
	return round(., DAMAGE_PRECISION)

/mob/living/carbon/proc/get_medical_painkiller_strength()
	if(stat >= UNCONSCIOUS || IsSleeping())
		return PAINKILLER_INSTANT
	if(!reagents)
		return HAS_TRAIT(src, TRAIT_ANALGESIA) ? PAINKILLER_STRONG : PAINKILLER_NONE
	if(reagents.has_reagent(/datum/reagent/medicine/adminordrazine, needs_metabolizing = TRUE))
		return PAINKILLER_INSTANT
	if(reagents.has_reagent(/datum/reagent/medicine/morphine, needs_metabolizing = TRUE) \
		|| reagents.has_reagent(/datum/reagent/medicine/muscle_stimulant, needs_metabolizing = TRUE) \
		|| reagents.has_reagent(/datum/reagent/medicine/mine_salve, needs_metabolizing = TRUE) \
		|| reagents.has_reagent(/datum/reagent/determination, needs_metabolizing = TRUE))
		return PAINKILLER_STRONG
	if(reagents.has_reagent(/datum/reagent/medicine/granibitaluri, needs_metabolizing = TRUE))
		return PAINKILLER_WEAK
	return HAS_TRAIT(src, TRAIT_ANALGESIA) ? PAINKILLER_STRONG : PAINKILLER_NONE

/mob/living/carbon/proc/reduce_bodypart_infections(amount, maximum_reduction = 50, maximum_treatable = 50)
	var/remaining = amount
	for(var/obj/item/bodypart/part as anything in get_bodyparts(include_stumps = TRUE))
		if(remaining <= 0)
			break
		remaining -= part.reduce_infection(remaining, maximum_reduction, maximum_treatable)
	return amount - remaining

/mob/living/carbon/human/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
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
	if((maxHealth - current_level) <= crit_threshold && stat != DEAD)
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
		if((brute && BP.brute_dam) || (burn && BP.burn_dam))
			parts += BP
	return parts

///Returns a list of damageable bodyparts
/mob/living/carbon/proc/get_damageable_bodyparts(required_bodytype)
	var/list/obj/item/bodypart/parts = list()
	for(var/obj/item/bodypart/BP as anything in get_bodyparts())
		if(required_bodytype && !(BP.bodytype & required_bodytype))
			continue
		if(BP.brute_dam + BP.burn_dam < BP.max_damage)
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
/mob/living/carbon/take_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype, check_armor = FALSE, wound_bonus = 0, exposed_wound_bonus = 0, sharpness = NONE, brute_type = null, burn_type = null, precise_zone = null)
	. = FALSE
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	var/list/obj/item/bodypart/parts = get_damageable_bodyparts(required_bodytype)
	if(!parts.len)
		return

	var/obj/item/bodypart/picked = pick(parts)
	var/damage_calculator = picked.get_damage()
	var/resolved_brute_type = brute_type
	if(isnull(resolved_brute_type) && !sharpness)
		resolved_brute_type = BODYPART_DAMAGE_BLUNT
	var/resolved_burn_type = burn_type || BODYPART_DAMAGE_HEAT
	if(picked.receive_damage(abs(brute), abs(burn), check_armor ? run_armor_check(picked, (brute ? MELEE : burn ? FIRE : null)) : FALSE, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, brute_type = resolved_brute_type, burn_type = resolved_burn_type, precise_zone = precise_zone))
		update_damage_overlays()
	return (damage_calculator - picked.get_damage())

/mob/living/carbon/heal_overall_damage(brute = 0, burn = 0, stamina = 0, required_bodytype, updating_health = TRUE, forced = FALSE)
	. = FALSE
	// treat negative args as positive
	brute = abs(brute)
	burn = abs(burn)

	var/list/obj/item/bodypart/parts = get_damaged_bodyparts(brute, burn, required_bodytype)

	var/update = NONE
	while(parts.len && (brute > 0 || burn > 0))
		var/obj/item/bodypart/picked = pick(parts)

		var/brute_was = picked.brute_dam
		var/burn_was = picked.burn_dam
		. += picked.get_damage()

		update |= picked.heal_damage(brute, burn, updating_health = FALSE, forced = forced, required_bodytype = required_bodytype)

		. -= picked.get_damage() // return the net amount of damage healed

		brute = round(brute - (brute_was - picked.brute_dam), DAMAGE_PRECISION)
		burn = round(burn - (burn_was - picked.burn_dam), DAMAGE_PRECISION)

		parts -= picked

	if(!.) // no change? no need to update anything
		return

	if(updating_health)
		updatehealth()
	if(update)
		update_damage_overlays()

/mob/living/carbon/take_overall_damage(brute = 0, burn = 0, stamina = 0, updating_health = TRUE, forced = FALSE, required_bodytype, brute_type = null, burn_type = null)
	. = FALSE
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return
	// treat negative args as positive
	brute = abs(brute)
	burn = abs(burn)
	brute_type ||= BODYPART_DAMAGE_BLUNT
	burn_type ||= BODYPART_DAMAGE_HEAT

	var/list/obj/item/bodypart/parts = get_damageable_bodyparts(required_bodytype)
	var/update = NONE
	while(parts.len && (brute > 0 || burn > 0))
		var/obj/item/bodypart/picked = pick(parts)
		var/brute_per_part = round(brute/parts.len, DAMAGE_PRECISION)
		var/burn_per_part = round(burn/parts.len, DAMAGE_PRECISION)

		var/brute_was = picked.brute_dam
		var/burn_was = picked.burn_dam
		. += picked.get_damage()

		// disabling wounds from these for now cuz your entire body snapping cause your heart stopped would suck
		update |= picked.receive_damage(brute_per_part, burn_per_part, blocked = FALSE, updating_health = FALSE, forced = forced, required_bodytype = required_bodytype, wound_bonus = CANT_WOUND, brute_type = brute_type, burn_type = burn_type)

		. -= picked.get_damage() // return the net amount of damage healed

		brute = round(brute - (picked.brute_dam - brute_was), DAMAGE_PRECISION)
		burn = round(burn - (picked.burn_dam - burn_was), DAMAGE_PRECISION)

		parts -= picked

	if(!.) // no change? no need to update anything
		return

	if(updating_health)
		updatehealth()
	if(update)
		update_damage_overlays()
