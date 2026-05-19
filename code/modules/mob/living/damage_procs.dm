
/mob/living/proc/normalize_cy_damage_type(damagetype, sharpness = NONE)
	switch(damagetype)
		if(BRUTE)
			if(sharpness & SHARP_POINTY)
				return PIERCE
			if(sharpness & SHARP_EDGED)
				return SLASH
			return BLUNT
		if(BURN)
			return FIRE
		if(BRAIN)
			return PSYCHIC
	return damagetype

/**
 * Applies damage to this mob.
 *
 * Sends [COMSIG_MOB_APPLY_DAMAGE]
 *
 * Arguuments:
 * * damage - Amount of damage
 * * damagetype - What type of damage to do. Prefer exact CP channels: [BLUNT], [PIERCE], [SLASH], [FIRE], [COLD], [ACID_DAMAGE], [TOX], [OXY], [PSYCHIC], [PAIN].
 * * def_zone - What body zone is being hit. Or a reference to what bodypart is being hit.
 * * blocked - Percent modifier to damage. 100 = 100% less damage dealt, 50% = 50% less damage dealt.
 * * forced - "Force" exactly the damage dealt. This means it skips damage modifier from blocked.
 * * spread_damage - For carbons, spreads the damage across all bodyparts rather than just the targeted zone.
 * * wound_bonus - Bonus modifier for wound chance.
 * * exposed_wound_bonus - Bonus modifier for wound chance on bare skin.
 * * sharpness - Sharpness of the weapon.
 * * attack_direction - Direction of the attack from the attacker to [src].
 * * attacking_item - Item that is attacking [src].
 * * wound_clothing - If this should cause damage to clothing.
 *
 * Returns the amount of damage dealt.
 */
/mob/living/proc/apply_damage(
	damage = 0,
	damagetype = BLUNT,
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
	SHOULD_CALL_PARENT(TRUE)
	var/damage_amount = damage
	if(damagetype == BRAIN)
		damagetype = PSYCHIC
	else if(damagetype != BRUTE && damagetype != BURN)
		damagetype = normalize_cy_damage_type(damagetype, sharpness)
	if(!forced)
		damage_amount *= ((100 - blocked) / 100)
		damage_amount *= get_incoming_damage_modifier(damage_amount, damagetype, def_zone, sharpness, attack_direction, attacking_item)
	if(damage_amount <= 0)
		return 0
	if(!forced)
		wound_bonus += get_cy_wound_bonus_modifier(damagetype)

	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, damage_amount, damagetype, def_zone, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)

	var/damage_dealt = 0
	switch(damagetype)
		if(BRUTE)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(brute = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_brute_loss(damage_amount, forced = forced)
		if(BLUNT)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(blunt = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = NONE, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_blunt_loss(damage_amount, forced = forced)
		if(PIERCE)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(pierce = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = SHARP_POINTY, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_pierce_loss(damage_amount, forced = forced)
		if(SLASH)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(slash = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = SHARP_EDGED, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_slash_loss(damage_amount, forced = forced)
		if(BURN)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(burn = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_fire_loss(damage_amount, forced = forced)
		if(FIRE)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(fire = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_heat_loss(damage_amount, forced = forced)
		if(COLD)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(cold = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_cold_loss(damage_amount, forced = forced)
		if(ACID_DAMAGE)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				if(actual_hit.receive_damage(acid = damage_amount, forced = forced, wound_bonus = wound_bonus, exposed_wound_bonus = exposed_wound_bonus, sharpness = sharpness, attack_direction = attack_direction, damage_source = attacking_item, wound_clothing = wound_clothing))
					update_damage_overlays()
				damage_dealt = actual_hit.get_damage() - delta
			else
				damage_dealt = -1 * adjust_acid_loss(damage_amount, forced = forced)
		if(PSYCHIC)
			damage_dealt = -1 * adjust_psychic_loss(damage_amount, forced = forced)
		if(PAIN)
			if(isbodypart(def_zone))
				var/obj/item/bodypart/actual_hit = def_zone
				damage_dealt = -1 * actual_hit.adjust_pain_damage(damage_amount)
			else
				damage_dealt = -1 * adjust_pain_loss(damage_amount, forced = forced)
		if(TOX)
			damage_dealt = -1 * adjust_tox_loss(damage_amount, forced = forced)
		if(OXY)
			damage_dealt = -1 * adjust_oxy_loss(damage_amount, forced = forced)
		if(STAMINA)
			damage_dealt = -1 * adjust_stamina_loss(damage_amount, forced = forced)
		if(BRAIN)
			damage_dealt = -1 * adjust_organ_loss(ORGAN_SLOT_BRAIN, damage_amount)

	SEND_SIGNAL(src, COMSIG_MOB_AFTER_APPLY_DAMAGE, damage_dealt, damagetype, def_zone, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)
	if(damage_dealt > 0)
		apply_cy_damage_pain(damage_dealt, damagetype, def_zone, forced)
		apply_cy_damage_organ_effects(damage_dealt, damagetype, def_zone, forced)
	return damage_dealt

/mob/living/proc/get_cy_wound_bonus_modifier(damagetype)
	var/modifier = 0
	if(damagetype in list(BRUTE, BLUNT, PIERCE, SLASH, BURN, FIRE, COLD, ACID_DAMAGE))
		if(!get_cy_skill_level(/datum/cy_skill/strength/toughness))
			modifier += 10
		if(has_cy_skill_perk_level(/datum/cy_skill/strength/toughness, 5))
			modifier -= body_position == LYING_DOWN ? 10 : 20
	return modifier

/mob/living/proc/get_cy_damage_pain_multiplier(damagetype)
	switch(damagetype)
		if(BLUNT)
			return 1.25
		if(PIERCE)
			return 1
		if(SLASH)
			return 0.8
		if(BURN)
			return 1.2
		if(FIRE)
			return 1.2
		if(COLD)
			return 0.7
		if(ACID_DAMAGE)
			return 1.4
	return 0

/mob/living/proc/apply_cy_damage_pain(damage_dealt, damagetype, def_zone = null, forced = FALSE)
	if(damage_dealt <= 0 || damagetype == PAIN || stat == DEAD)
		return 0
	var/pain_multiplier = get_cy_damage_pain_multiplier(damagetype)
	if(!pain_multiplier)
		return 0
	var/pain_amount = round(damage_dealt * pain_multiplier, DAMAGE_PRECISION)
	if(pain_amount <= 0)
		return 0
	if(isbodypart(def_zone))
		var/obj/item/bodypart/actual_hit = def_zone
		actual_hit.adjust_pain_damage(pain_amount)
		adjust_pain_loss(pain_amount * 0.1, updating_health = FALSE, forced = forced)
		return pain_amount
	adjust_pain_loss(pain_amount, updating_health = FALSE, forced = forced)
	return pain_amount

/mob/living/proc/apply_cy_damage_organ_effects(damage_dealt, damagetype, def_zone = null, forced = FALSE)
	if(damage_dealt <= 0 || forced || stat == DEAD || !iscarbon(src))
		return 0
	var/hit_zone = def_zone
	if(isbodypart(def_zone))
		var/obj/item/bodypart/actual_hit = def_zone
		hit_zone = actual_hit.body_zone

	var/organ_damage = 0
	switch(damagetype)
		if(BLUNT)
			organ_damage = damage_dealt * 0.1
			if(hit_zone == BODY_ZONE_HEAD)
				adjust_organ_loss(ORGAN_SLOT_BRAIN, organ_damage * 0.6, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
			if(hit_zone == BODY_ZONE_CHEST)
				adjust_organ_loss(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH), organ_damage, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
		if(PIERCE)
			if(hit_zone == BODY_ZONE_HEAD)
				organ_damage = damage_dealt * 0.12
				adjust_organ_loss(ORGAN_SLOT_BRAIN, organ_damage, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
			if(hit_zone == BODY_ZONE_CHEST && prob(min(60, damage_dealt * 2)))
				organ_damage = damage_dealt * 0.15
				adjust_organ_loss(pick(ORGAN_SLOT_LUNGS, ORGAN_SLOT_HEART, ORGAN_SLOT_LIVER), organ_damage, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
		if(SLASH)
			if(hit_zone == BODY_ZONE_CHEST && prob(min(35, damage_dealt)))
				organ_damage = damage_dealt * 0.08
				adjust_organ_loss(pick(ORGAN_SLOT_LUNGS, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH), organ_damage, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
		if(ACID_DAMAGE)
			if(hit_zone == BODY_ZONE_HEAD)
				organ_damage = damage_dealt * 0.05
				adjust_organ_loss(ORGAN_SLOT_EYES, organ_damage, required_organ_flag = ORGAN_ORGANIC)
				return organ_damage
	return 0

/**
 * Used in tandem with [/mob/living/proc/apply_damage] to calculate modifier applied into incoming damage
 */
/mob/living/proc/get_incoming_damage_modifier(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
)
	SHOULD_CALL_PARENT(TRUE)

	var/list/damage_mods = list()
	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, damage_mods, damage, damagetype, def_zone, sharpness, attack_direction, attacking_item)

	var/final_mod = 1
	for(var/new_mod in damage_mods)
		final_mod *= new_mod
	final_mod *= get_cy_incoming_damage_multiplier()
	return final_mod

/**
 * Simply a wrapper for calling mob adjustXLoss() procs to heal a certain damage type,
 * when you don't know what damage type you're healing exactly.
 */
/mob/living/proc/heal_damage_type(heal_amount = 0, damagetype = BRUTE, update_health = TRUE)
	heal_amount = abs(heal_amount) * -1

	switch(damagetype)
		if(BRUTE)
			return adjust_brute_loss(heal_amount, update_health)
		if(BLUNT)
			return adjust_blunt_loss(heal_amount, update_health)
		if(PIERCE)
			return adjust_pierce_loss(heal_amount, update_health)
		if(SLASH)
			return adjust_slash_loss(heal_amount, update_health)
		if(BURN)
			return adjust_fire_loss(heal_amount, update_health)
		if(FIRE)
			return adjust_heat_loss(heal_amount, update_health)
		if(COLD)
			return adjust_cold_loss(heal_amount, update_health)
		if(ACID_DAMAGE)
			return adjust_acid_loss(heal_amount, update_health)
		if(PSYCHIC)
			return adjust_psychic_loss(heal_amount, update_health)
		if(PAIN)
			return adjust_pain_loss(heal_amount, update_health)
		if(TOX)
			return adjust_tox_loss(heal_amount, update_health)
		if(OXY)
			return adjust_oxy_loss(heal_amount, update_health)
		if(STAMINA)
			return adjust_stamina_loss(heal_amount, update_health)

/// return the damage amount for the type given
/**
 * Simply a wrapper for calling mob getXLoss() procs to get a certain damage type,
 * when you don't know what damage type you're getting exactly.
 */
/mob/living/proc/get_current_damage_of_type(damagetype = BRUTE)
	switch(damagetype)
		if(BRUTE)
			return get_brute_loss()
		if(BLUNT)
			return get_blunt_loss()
		if(PIERCE)
			return get_pierce_loss()
		if(SLASH)
			return get_slash_loss()
		if(BURN)
			return get_fire_loss()
		if(FIRE)
			return get_heat_loss()
		if(COLD)
			return get_cold_loss()
		if(ACID_DAMAGE)
			return get_acid_loss()
		if(PSYCHIC)
			return get_psychic_loss()
		if(PAIN)
			return get_pain_loss()
		if(TOX)
			return get_tox_loss()
		if(OXY)
			return get_oxy_loss()
		if(STAMINA)
			return get_stamina_loss()

/// return the total damage of all types which update your health
/mob/living/proc/get_total_damage(precision = DAMAGE_PRECISION)
	return round(get_brute_loss() + get_fire_loss() + get_tox_loss() + get_oxy_loss() + max(get_pain_loss() - 200, 0), precision)

/// Applies multiple damages at once via [apply_damage][/mob/living/proc/apply_damage]
/mob/living/proc/apply_damages(
	blunt = 0,
	pierce = 0,
	slash = 0,
	heat = 0,
	cold = 0,
	caustic = 0,
	tox = 0,
	oxy = 0,
	psychic = 0,
	pain = 0,
	def_zone = null,
	blocked = 0,
	stamina = 0,
	brain = 0,
	brute = 0,
	burn = 0,
)
	var/total_damage = 0
	// Legacy aggregate inputs are split immediately; exact channels remain source of truth.
	if(brute)
		blunt += brute / 3
		pierce += brute / 3
		slash += brute / 3
	if(burn)
		heat += burn / 3
		cold += burn / 3
		caustic += burn / 3
	if(blunt)
		total_damage += apply_damage(blunt, BLUNT, def_zone, blocked)
	if(pierce)
		total_damage += apply_damage(pierce, PIERCE, def_zone, blocked)
	if(slash)
		total_damage += apply_damage(slash, SLASH, def_zone, blocked)
	if(heat)
		total_damage += apply_damage(heat, FIRE, def_zone, blocked)
	if(cold)
		total_damage += apply_damage(cold, COLD, def_zone, blocked)
	if(caustic)
		total_damage += apply_damage(caustic, ACID_DAMAGE, def_zone, blocked)
	if(tox)
		total_damage += apply_damage(tox, TOX, def_zone, blocked)
	if(oxy)
		total_damage += apply_damage(oxy, OXY, def_zone, blocked)
	if(psychic)
		total_damage += apply_damage(psychic, PSYCHIC, def_zone, blocked)
	if(pain)
		total_damage += apply_damage(pain, PAIN, def_zone, blocked)
	if(stamina)
		total_damage += apply_damage(stamina, STAMINA, def_zone, blocked)
	if(brain)
		total_damage += apply_damage(brain, BRAIN, def_zone, blocked)
	return total_damage

/// applies various common status effects or common hardcoded mob effects
/mob/living/proc/apply_effect(effect = 0,effecttype = EFFECT_STUN, blocked = 0)
	var/hit_percent = (100-blocked)/100
	if(!effect || (hit_percent <= 0))
		return FALSE
	switch(effecttype)
		if(EFFECT_STUN)
			Stun(effect * hit_percent)
		if(EFFECT_KNOCKDOWN)
			Knockdown(effect * hit_percent)
		if(EFFECT_PARALYZE)
			Paralyze(effect * hit_percent)
		if(EFFECT_IMMOBILIZE)
			Immobilize(effect * hit_percent)
		if(EFFECT_UNCONSCIOUS)
			Unconscious(effect * hit_percent)

	return TRUE

/**
 * Applies multiple effects at once via [/mob/living/proc/apply_effect]
 *
 * Pretty much only used for projectiles applying effects on hit,
 * don't use this for anything else please just cause the effects directly
 */
/mob/living/proc/apply_effects(
		stun = 0,
		knockdown = 0,
		unconscious = 0,
		slur = 0 SECONDS, // Speech impediment, not technically an effect
		stutter = 0 SECONDS, // Ditto
		eyeblur = 0 SECONDS,
		drowsy = 0 SECONDS,
		blocked = 0, // This one's not an effect, don't be confused - it's block chance
		stamina = 0, // This one's a damage type, and not an effect
		jitter = 0 SECONDS,
		paralyze = 0,
		immobilize = 0,
	)

	if(blocked >= 100)
		return FALSE

	if(stun)
		apply_effect(stun, EFFECT_STUN, blocked)
	if(knockdown)
		apply_effect(knockdown, EFFECT_KNOCKDOWN, blocked)
	if(unconscious)
		apply_effect(unconscious, EFFECT_UNCONSCIOUS, blocked)
	if(paralyze)
		apply_effect(paralyze, EFFECT_PARALYZE, blocked)
	if(immobilize)
		apply_effect(immobilize, EFFECT_IMMOBILIZE, blocked)

	if(stamina)
		apply_damage(stamina, STAMINA, null, blocked)

	if(drowsy)
		adjust_drowsiness(drowsy)
	if(eyeblur)
		adjust_eye_blur_up_to(eyeblur, eyeblur)
	if(jitter && !check_stun_immunity(CANSTUN))
		adjust_jitter(jitter)
	if(slur)
		adjust_slurring(slur)
	if(stutter)
		adjust_stutter(stutter)

	return TRUE

/// Returns a multiplier to apply to a specific kind of damage
/mob/living/proc/get_damage_mod(damage_type)
	switch(damage_type)
		if (OXY)
			return HAS_TRAIT(src, TRAIT_NOBREATH) ? 0 : 1
		if (TOX)
			if (HAS_TRAIT(src, TRAIT_TOXINLOVER))
				return -1
			return HAS_TRAIT(src, TRAIT_TOXIMMUNE) ? 0 : 1
	return 1

/mob/living/proc/get_brute_loss()
	return round(get_blunt_loss() + get_pierce_loss() + get_slash_loss(), DAMAGE_PRECISION)

/mob/living/proc/sync_physical_damage()
	return get_brute_loss()

/mob/living/proc/get_blunt_loss()
	return bluntloss

/mob/living/proc/get_pierce_loss()
	return pierceloss

/mob/living/proc/get_slash_loss()
	return slashloss

/mob/living/proc/can_adjust_brute_loss(amount, forced, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BRUTE_DAMAGE, BRUTE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjust_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if (!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	var/split_amount = amount / 3
	. = adjust_blunt_loss(split_amount, FALSE, TRUE, required_bodytype)
	. += adjust_pierce_loss(split_amount, FALSE, TRUE, required_bodytype)
	. += adjust_slash_loss(split_amount, FALSE, TRUE, required_bodytype)
	if(!.) // no change, no need to update
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_blunt_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if (!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	. = bluntloss
	bluntloss = clamp((bluntloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= bluntloss
	sync_physical_damage()
	if(!.)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_pierce_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if (!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	. = pierceloss
	pierceloss = clamp((pierceloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= pierceloss
	sync_physical_damage()
	if(!.)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_slash_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if (!can_adjust_brute_loss(amount, forced, required_bodytype))
		return 0
	. = slashloss
	slashloss = clamp((slashloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= slashloss
	sync_physical_damage()
	if(!.)
		return 0
	if(updating_health)
		updatehealth()


/mob/living/proc/set_brute_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	var/current = get_brute_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_brute_loss(diff, updating_health, forced, required_bodytype)

/mob/living/proc/get_oxy_loss()
	return oxygenloss

/mob/living/proc/can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type)
	if(!forced)
		if(HAS_TRAIT(src, TRAIT_GODMODE))
			return FALSE
		if (required_respiration_type)
			var/obj/item/organ/lungs/affected_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
			if(isnull(affected_lungs))
				if(!(mob_respiration_type & required_respiration_type))  // if the mob has no lungs, use mob_respiration_type
					return FALSE
			else
				if(!(affected_lungs.respiration_type & required_respiration_type)) // otherwise use the lungs' respiration_type
					return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_OXY_DAMAGE, OXY, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjust_oxy_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL, required_respiration_type = ALL)
	if(!can_adjust_oxy_loss(amount, forced, required_biotype, required_respiration_type))
		return 0
	. = oxygenloss
	oxygenloss = clamp((oxygenloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= oxygenloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/set_oxy_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL, required_respiration_type = ALL)
	if(!forced)
		if(HAS_TRAIT(src, TRAIT_GODMODE))
			return FALSE

		var/obj/item/organ/lungs/affected_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(isnull(affected_lungs))
			if(!(mob_respiration_type & required_respiration_type))
				return FALSE
		else
			if(!(affected_lungs.respiration_type & required_respiration_type))
				return FALSE
	. = oxygenloss
	oxygenloss = amount
	. -= oxygenloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/get_tox_loss()
	return toxinloss

/mob/living/proc/can_adjust_tox_loss(amount, forced, required_biotype = ALL)
	if(!forced && (HAS_TRAIT(src, TRAIT_GODMODE) || !(mob_biotypes & required_biotype)))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_TOX_DAMAGE, TOX, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjust_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!can_adjust_tox_loss(amount, forced, required_biotype))
		return 0

	if(!forced && HAS_TRAIT(src, TRAIT_TOXINLOVER)) //damage becomes healing and healing becomes damage
		amount = -amount
		if(HAS_TRAIT(src, TRAIT_TOXIMMUNE)) //Prevents toxin damage, but not healing
			amount = min(amount, 0)
		if(amount > 0)
			adjust_blood_volume(-5 * amount)
		else
			adjust_blood_volume(-amount)

	else if(!forced && HAS_TRAIT(src, TRAIT_TOXIMMUNE)) //Prevents toxin damage, but not healing
		amount = min(amount, 0)

	. = toxinloss
	toxinloss = clamp((toxinloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= toxinloss

	if(!.) // no change, no need to update
		return FALSE

	if(updating_health)
		updatehealth()


/mob/living/proc/set_tox_loss(amount, updating_health = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(!forced && !(mob_biotypes & required_biotype))
		return FALSE
	. = toxinloss
	toxinloss = amount
	. -= toxinloss
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/mob/living/proc/get_fire_loss()
	return round(get_heat_loss() + get_cold_loss() + get_acid_loss(), DAMAGE_PRECISION)

/mob/living/proc/sync_burn_damage()
	return get_fire_loss()

/mob/living/proc/get_heat_loss()
	return heatloss

/mob/living/proc/get_cold_loss()
	return coldloss

/mob/living/proc/get_acid_loss()
	return causticloss

/mob/living/proc/can_adjust_fire_loss(amount, forced, required_bodytype)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_BURN_DAMAGE, BURN, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjust_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	var/split_amount = amount / 3
	. = adjust_heat_loss(split_amount, FALSE, TRUE, required_bodytype)
	. += adjust_cold_loss(split_amount, FALSE, TRUE, required_bodytype)
	. += adjust_acid_loss(split_amount, FALSE, TRUE, required_bodytype)
	if(. == 0) // no change, no need to update
		return
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_heat_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	. = heatloss
	heatloss = clamp((heatloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= heatloss
	sync_burn_damage()
	if(. == 0)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_cold_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	. = coldloss
	coldloss = clamp((coldloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= coldloss
	sync_burn_damage()
	if(. == 0)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/adjust_acid_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!can_adjust_fire_loss(amount, forced, required_bodytype))
		return 0
	. = causticloss
	causticloss = clamp((causticloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, maxHealth * 2)
	. -= causticloss
	sync_burn_damage()
	if(. == 0)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/set_fire_loss(amount, updating_health = TRUE, forced = FALSE, required_bodytype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	var/current = get_fire_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_fire_loss(diff, updating_health, forced, required_bodytype)

/mob/living/proc/get_psychic_loss()
	return psychicloss

/mob/living/proc/get_psychic_status_duration_multiplier()
	var/current_psychic = get_psychic_loss()
	if(current_psychic < 50)
		return 1
	return 1 + min((current_psychic - 50) / 150, 1)

/mob/living/proc/get_psychic_recovery_rate()
	var/recovery_rate = 1.5
	if(cy_stat_holder)
		var/spirit = cy_stat_holder.get_stat(/datum/cy_stat/spirit)
		recovery_rate *= 1 + ((spirit - CY_STAT_DEFAULT) * 0.05)
	return max(0.5, recovery_rate)

/mob/living/proc/adjust_psychic_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	. = psychicloss
	psychicloss = clamp((psychicloss + amount), 0, maxHealth * 2)
	. -= psychicloss
	if(amount > 0 && .)
		last_psychic_damage = world.time
	if(. == 0)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/set_psychic_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	var/current = get_psychic_loss()
	var/diff = amount - current
	if(!diff)
		return FALSE
	return adjust_psychic_loss(diff, updating_health, forced)

/mob/living/proc/get_pain_loss()
	return painloss

/mob/living/proc/sync_pain_damage()
	return

/mob/living/proc/adjust_pain_loss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	. = painloss
	painloss = clamp((painloss + amount), 0, maxHealth * 2)
	. -= painloss
	if(. == 0)
		return 0
	if(updating_health)
		updatehealth()

/mob/living/proc/handle_psychic_damage(seconds_per_tick)
	if(!psychicloss)
		return
	if(last_psychic_damage && world.time >= last_psychic_damage + 10 SECONDS)
		adjust_psychic_loss(-get_psychic_recovery_rate() * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	switch(psychicloss)
		if(120 to INFINITY)
			if(SPT_PROB(12, seconds_per_tick))
				adjust_confusion(4 SECONDS)
			if(SPT_PROB(8, seconds_per_tick))
				adjust_eye_blur(4 SECONDS)
			if(SPT_PROB(6, seconds_per_tick))
				adjust_hallucinations_up_to(8 SECONDS, 45 SECONDS)
			if(SPT_PROB(6, seconds_per_tick))
				dropItemToGround(get_active_held_item())
			if(SPT_PROB(4, seconds_per_tick))
				step(src, pick(GLOB.cardinals))
			if(SPT_PROB(3, seconds_per_tick))
				addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, emote), pick("scream", "laugh", "cry")), 0)
			if(SPT_PROB(2, seconds_per_tick))
				Stun(1 SECONDS)
		if(80 to 120)
			if(SPT_PROB(8, seconds_per_tick))
				adjust_confusion(3 SECONDS)
			if(SPT_PROB(4, seconds_per_tick))
				adjust_eye_blur(3 SECONDS)
			if(SPT_PROB(3, seconds_per_tick))
				adjust_hallucinations_up_to(4 SECONDS, 25 SECONDS)
			if(SPT_PROB(3, seconds_per_tick))
				dropItemToGround(get_active_held_item())
		if(45 to 80)
			if(SPT_PROB(5, seconds_per_tick))
				adjust_jitter(2 SECONDS)
			if(SPT_PROB(3, seconds_per_tick))
				adjust_confusion(1 SECONDS)
		if(20 to 45)
			if(SPT_PROB(2, seconds_per_tick))
				adjust_dizzy(1 SECONDS)

/mob/living/proc/adjust_organ_loss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/set_organ_loss(slot, amount, maximum, required_organ_flag)
	return

/mob/living/proc/get_organ_loss(slot, required_organ_flag)
	return

/mob/living/proc/get_stamina_loss()
	return staminaloss

/mob/living/proc/can_adjust_stamina_loss(amount, forced, required_biotype = ALL)
	if(!forced && (!(mob_biotypes & required_biotype) || HAS_TRAIT(src, TRAIT_GODMODE)))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_STAMINA_DAMAGE, STAMINA, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjust_stamina_loss(amount, updating_stamina = TRUE, forced = FALSE, required_biotype = ALL)
	if(!can_adjust_stamina_loss(amount, forced, required_biotype))
		return 0
	var/old_amount = staminaloss
	staminaloss = clamp((staminaloss + (amount * CONFIG_GET(number/damage_multiplier))), 0, max_stamina)
	var/delta = old_amount - staminaloss
	if(delta <= 0)
		// need to check for stamcrit AFTER canadjust but BEFORE early return here
		received_stamina_damage(staminaloss, -1 * delta)
	if(delta == 0) // no change, no need to update
		return 0
	if(updating_stamina)
		updatehealth()
	return delta

/mob/living/proc/set_stamina_loss(amount, updating_stamina = TRUE, forced = FALSE, required_biotype = ALL)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return 0
	if(!forced && !(mob_biotypes & required_biotype))
		return 0
	var/old_amount = staminaloss
	staminaloss = amount
	var/delta = old_amount - staminaloss
	if(delta <= 0 && amount >= DAMAGE_PRECISION)
		received_stamina_damage(staminaloss, -1 * delta, amount)
	if(delta == 0) // no change, no need to update
		return 0
	if(updating_stamina)
		updatehealth()
	return delta

/// The mob has received stamina damage
///
/// - current_level: The mob's current stamina damage amount (to save unnecessary get_stamina_loss() calls)
/// - amount_actual: The amount of stamina damage received, in actuality
/// For example, if you are taking 50 stamina damage but are at 90, you would actually only receive 30 stamina damage (due to the cap)
/// - amount: The amount of stamina damage received, raw
/mob/living/proc/received_stamina_damage(current_level, amount_actual, amount)
	addtimer(CALLBACK(src, PROC_REF(set_stamina_loss), 0, TRUE, TRUE), stamina_regen_time, TIMER_UNIQUE|TIMER_OVERRIDE)

/**
 * heal ONE external organ, organ gets randomly selected from damaged ones.
 *
 * returns the net change in damage
 */
/mob/living/proc/heal_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype = NONE, target_zone = null)
	. = (adjust_brute_loss(-abs(brute), updating_health = FALSE) + adjust_fire_loss(-abs(burn), updating_health = FALSE))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// damage ONE external organ, organ gets randomly selected from damaged ones.
/mob/living/proc/take_bodypart_damage(brute = 0, burn = 0, updating_health = TRUE, required_bodytype, check_armor = FALSE, wound_bonus = 0, exposed_wound_bonus = 0, sharpness = NONE)
	. = (adjust_brute_loss(abs(brute), updating_health = FALSE) + adjust_fire_loss(abs(burn), updating_health = FALSE))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// heal MANY bodyparts, in random order. note: stamina arg nonfunctional for carbon mobs
/mob/living/proc/heal_overall_damage(brute = 0, burn = 0, stamina = 0, required_bodytype, updating_health = TRUE, forced = FALSE)
	. = (adjust_brute_loss(-abs(brute), updating_health = FALSE, forced = forced) + \
			adjust_fire_loss(-abs(burn), updating_health = FALSE, forced = forced) + \
			adjust_stamina_loss(-abs(stamina), updating_stamina = FALSE, forced = forced))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

/// damage MANY bodyparts, in random order. note: stamina arg nonfunctional for carbon mobs
/mob/living/proc/take_overall_damage(brute = 0, burn = 0, stamina = 0, updating_health = TRUE, forced = FALSE, required_bodytype)
	. = (adjust_brute_loss(abs(brute), updating_health = FALSE, forced = forced) + \
			adjust_fire_loss(abs(burn), updating_health = FALSE, forced = forced) + \
			adjust_stamina_loss(abs(stamina), updating_stamina = FALSE, forced = forced))
	if(!.) // no change, no need to update
		return FALSE
	if(updating_health)
		updatehealth()

///heal up to amount damage, in a given order
/mob/living/proc/heal_ordered_damage(amount, list/damage_types, update_health = TRUE)
	. = 0 //we'll return the amount of damage healed
	for(var/damagetype in damage_types)
		var/amount_to_heal = min(abs(amount), get_current_damage_of_type(damagetype)) //heal only up to the amount of damage we have
		if(amount_to_heal)
			. += heal_damage_type(amount_to_heal, damagetype, FALSE)
			amount -= amount_to_heal //remove what we healed from our current amount
		if(!amount)
			break
	if(. && update_health)
		updatehealth()
