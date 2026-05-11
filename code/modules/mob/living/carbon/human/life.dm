

//NOTE: Breathing happens once per FOUR TICKS, unless the last breath fails. In which case it happens once per ONE TICK! So oxygenloss healing is done once per 4 ticks while oxygenloss damage is applied once per tick!

// bitflags for the percentual amount of protection a piece of clothing which covers the body part offers.
// Used with human/proc/get_heat_protection() and human/proc/get_cold_protection()
// The values here should add up to 1.
// Hands and feet have 2.5%, arms and legs 7.5%, each of the torso parts has 15% and the head has 30%
#define THERMAL_PROTECTION_HEAD 0.3
#define THERMAL_PROTECTION_CHEST 0.15
#define THERMAL_PROTECTION_GROIN 0.15
#define THERMAL_PROTECTION_LEG_LEFT 0.075
#define THERMAL_PROTECTION_LEG_RIGHT 0.075
#define THERMAL_PROTECTION_FOOT_LEFT 0.025
#define THERMAL_PROTECTION_FOOT_RIGHT 0.025
#define THERMAL_PROTECTION_ARM_LEFT 0.075
#define THERMAL_PROTECTION_ARM_RIGHT 0.075
#define THERMAL_PROTECTION_HAND_LEFT 0.025
#define THERMAL_PROTECTION_HAND_RIGHT 0.025

/mob/living/carbon/human/Life(seconds_per_tick = SSMOBS_DT)
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	. = ..()

	if(QDELETED(src))
		return FALSE

	// Body temperature stability and damage
	dna.species.handle_body_temperature(src, seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_STASIS))
		for(var/datum/wound/iter_wound as anything in all_wounds)
			iter_wound.on_stasis(seconds_per_tick)
		return stat != DEAD

	if(stat == DEAD)
		return FALSE

	// Handle active mutations
	for(var/datum/mutation/mutation as anything in dna.mutations)
		mutation.on_life(seconds_per_tick)

	// Heart attack stuff
	handle_heart(seconds_per_tick)
	// Handles liver failure effects, if we lack a liver
	handle_liver(seconds_per_tick)
	handle_stomach(seconds_per_tick)
	handle_toxin_organ_damage(seconds_per_tick)
	// For special species interactions
	dna.species.spec_life(src, seconds_per_tick)
	return stat != DEAD

/mob/living/carbon/human/proc/handle_stomach(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_NOHUNGER) || isnull(dna?.species?.mutantstomach))
		return

	var/obj/item/organ/stomach/stomach = get_organ_slot(ORGAN_SLOT_STOMACH)
	if(stomach && !(stomach.organ_flags & ORGAN_FAILING))
		return

	var/digestion_penalty = stomach ? 0.2 : 0.35
	adjust_tox_loss(digestion_penalty * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	if(nutrition > NUTRITION_LEVEL_STARVING)
		adjust_nutrition(-HUNGER_FACTOR * seconds_per_tick)
	if(SPT_PROB(stomach ? 1 : 2, seconds_per_tick))
		vomit(vomit_flags = MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM, lost_nutrition = 3, purge_ratio = 0.03)

/mob/living/carbon/human/proc/handle_toxin_organ_damage(seconds_per_tick)
	var/toxin_load = get_tox_loss()
	if(toxin_load < 10 || HAS_TRAIT(src, TRAIT_TOXIMMUNE) || HAS_TRAIT(src, TRAIT_TOXINLOVER))
		return

	var/toxin_pressure = clamp((toxin_load - 10) / 90, 0.05, 1)
	var/organ_damage = 0.25 * toxin_pressure * seconds_per_tick
	var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && !(liver.organ_flags & ORGAN_FAILING))
		liver.apply_organ_damage(organ_damage * 1.5)
		return

	var/list/fallback_organs = list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS)
	if(toxin_load >= 60)
		fallback_organs += ORGAN_SLOT_BRAIN
	adjust_organ_loss(pick(fallback_organs), organ_damage)

/mob/living/carbon/proc/apply_targeted_toxin_organ_damage(datum/reagent/toxin/source_toxin, seconds_per_tick, metabolization_ratio)
	return

/mob/living/carbon/human/apply_targeted_toxin_organ_damage(datum/reagent/toxin/source_toxin, seconds_per_tick, metabolization_ratio)
	if(!source_toxin || HAS_TRAIT(src, TRAIT_TOXIMMUNE) || HAS_TRAIT(src, TRAIT_TOXINLOVER))
		return

	var/list/target_organs = source_toxin.toxin_target_organs
	if(!length(target_organs))
		target_organs = list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH)

	var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	var/liver_working = liver && !(liver.organ_flags & ORGAN_FAILING)
	var/metabolism_scale = (0.2 * REAGENTS_METABOLISM) / source_toxin.metabolization_rate
	var/organ_damage = metabolism_scale * max(source_toxin.toxpwr, 1) * source_toxin.normalise_creation_purity() * metabolization_ratio * seconds_per_tick
	if(liver_working)
		liver.apply_organ_damage(organ_damage * 0.5 * source_toxin.liver_damage_multiplier, required_organ_flag = source_toxin.affected_organ_flags)
		if(liver.damage < liver.high_threshold)
			return
	else
		organ_damage *= 1.5

	var/damage_per_organ = organ_damage / length(target_organs)
	for(var/organ_slot as anything in target_organs)
		adjust_organ_loss(organ_slot, damage_per_organ, required_organ_flag = source_toxin.affected_organ_flags)
	if(ORGAN_SLOT_BRAIN in target_organs)
		adjust_psychic_loss(organ_damage * 0.25, updating_health = FALSE, forced = TRUE)

/mob/living/carbon/human/calculate_affecting_pressure(pressure)
	var/chest_covered = !get_bodypart(BODY_ZONE_CHEST)
	var/head_covered = !get_bodypart(BODY_ZONE_HEAD)
	var/hands_covered = !get_bodypart(BODY_ZONE_L_ARM) && !get_bodypart(BODY_ZONE_R_ARM)
	var/feet_covered = !get_bodypart(BODY_ZONE_L_LEG) && !get_bodypart(BODY_ZONE_R_LEG)
	for(var/obj/item/clothing/equipped in get_equipped_items(INCLUDE_ABSTRACT))
		if(!chest_covered && (equipped.body_parts_covered & CHEST) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE))
			chest_covered = TRUE
		if(!head_covered && (equipped.body_parts_covered & HEAD) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE))
			head_covered = TRUE
		if(!hands_covered && (equipped.body_parts_covered & HANDS|ARMS) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE))
			hands_covered = TRUE
		if(!feet_covered && (equipped.body_parts_covered & FEET|LEGS) && (equipped.clothing_flags & STOPSPRESSUREDAMAGE))
			feet_covered = TRUE

	if(chest_covered && head_covered && hands_covered && feet_covered)
		return ONE_ATMOSPHERE
	if(ismovable(loc))
		/// If we're in a space with 0.5 content pressure protection, it averages the values, for example.
		var/atom/movable/occupied_space = loc
		return (occupied_space.contents_pressure_protection * ONE_ATMOSPHERE + (1 - occupied_space.contents_pressure_protection) * pressure)
	return pressure

/mob/living/carbon/human/breathe()
	if(!HAS_TRAIT(src, TRAIT_NOBREATH))
		return ..()

/mob/living/carbon/human/check_breath(datum/gas_mixture/breath)
	var/obj/item/organ/lungs/human_lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(human_lungs)
		return human_lungs.check_breath(breath, src)

	set_lung_air_quality(0)
	failed_last_breath = TRUE

	var/datum/species/human_species = dna.species

	switch(human_species.breathid)
		if(GAS_O2)
			throw_alert(ALERT_NOT_ENOUGH_OXYGEN, /atom/movable/screen/alert/not_enough_oxy)
		if(GAS_PLASMA)
			throw_alert(ALERT_NOT_ENOUGH_PLASMA, /atom/movable/screen/alert/not_enough_plas)
		if(GAS_CO2)
			throw_alert(ALERT_NOT_ENOUGH_CO2, /atom/movable/screen/alert/not_enough_co2)
		if(GAS_N2)
			throw_alert(ALERT_NOT_ENOUGH_NITRO, /atom/movable/screen/alert/not_enough_nitro)
	return FALSE

/// Environment handlers for species
/mob/living/carbon/human/handle_environment(datum/gas_mixture/environment, seconds_per_tick)
	// If we are in a cryo bed do not process life functions
	if(istype(loc, /obj/machinery/cryo_cell))
		return

	dna.species.handle_environment(src, environment, seconds_per_tick)

/**
 * Adjust the core temperature of a mob
 *
 * vars:
 * * amount The amount of degrees to change body temperature by
 * * min_temp (optional) The minimum body temperature after adjustment
 * * max_temp (optional) The maximum body temperature after adjustment
 */
/mob/living/carbon/human/proc/adjust_coretemperature(amount, min_temp=0, max_temp=INFINITY)
	set_coretemperature(clamp(coretemperature + amount, min_temp, max_temp))

/mob/living/carbon/human/proc/set_coretemperature(value)
	SEND_SIGNAL(src, COMSIG_HUMAN_CORETEMP_CHANGE, coretemperature, value)
	coretemperature = value

/**
 * get_body_temperature Returns the body temperature with any modifications applied
 *
 * This applies the result from proc/get_body_temp_normal_change() against the bodytemp_normal
 * for the species and returns the result
 *
 * arguments:
 * * apply_change (optional) Default True This applies the changes to body temperature normal
 */
/mob/living/carbon/human/get_body_temp_normal(apply_change=TRUE)
	if(!apply_change)
		return dna.species.bodytemp_normal
	return dna.species.bodytemp_normal + get_body_temp_normal_change()

/mob/living/carbon/human/get_body_temp_heat_damage_limit()
	return dna.species.bodytemp_heat_damage_limit

/mob/living/carbon/human/get_body_temp_cold_damage_limit()
	return dna.species.bodytemp_cold_damage_limit

/mob/living/carbon/human/proc/get_thermal_protection()
	var/thermal_protection = 0 //Simple check to estimate how protected we are against multiple temperatures
	if(wear_suit)
		if((wear_suit.heat_protection & CHEST) && (wear_suit.max_heat_protection_temperature >= FIRE_SUIT_MAX_TEMP_PROTECT))
			thermal_protection += (wear_suit.max_heat_protection_temperature * 0.7)
	if(head)
		if((head.heat_protection & HEAD) && (head.max_heat_protection_temperature >= FIRE_HELM_MAX_TEMP_PROTECT))
			thermal_protection += (head.max_heat_protection_temperature * THERMAL_PROTECTION_HEAD)
	thermal_protection = round(thermal_protection)
	return thermal_protection

//END FIRE CODE

//This proc returns a number made up of the flags for body parts which you are protected on. (such as HEAD, CHEST, GROIN, etc. See setup.dm for the full list)
/mob/living/carbon/human/proc/get_heat_protection_flags(temperature) //Temperature is the temperature you're being exposed to.
	var/thermal_protection_flags = 0
	//Handle normal clothing
	if(head)
		if(head.max_heat_protection_temperature && head.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= head.heat_protection
	if(wear_suit)
		if(wear_suit.max_heat_protection_temperature && wear_suit.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= wear_suit.heat_protection
	if(w_uniform)
		if(w_uniform.max_heat_protection_temperature && w_uniform.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= w_uniform.heat_protection
	if(shoes)
		if(shoes.max_heat_protection_temperature && shoes.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= shoes.heat_protection
	if(gloves)
		if(gloves.max_heat_protection_temperature && gloves.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= gloves.heat_protection
	if(wear_mask)
		if(wear_mask.max_heat_protection_temperature && wear_mask.max_heat_protection_temperature >= temperature)
			thermal_protection_flags |= wear_mask.heat_protection

	return thermal_protection_flags

/mob/living/carbon/human/get_heat_protection(temperature)
	var/thermal_protection_flags = get_heat_protection_flags(temperature)
	var/thermal_protection = heat_protection

	// Apply clothing items protection
	if(thermal_protection_flags)
		if(thermal_protection_flags & HEAD)
			thermal_protection += THERMAL_PROTECTION_HEAD
		if(thermal_protection_flags & CHEST)
			thermal_protection += THERMAL_PROTECTION_CHEST
		if(thermal_protection_flags & GROIN)
			thermal_protection += THERMAL_PROTECTION_GROIN
		if(thermal_protection_flags & LEG_LEFT)
			thermal_protection += THERMAL_PROTECTION_LEG_LEFT
		if(thermal_protection_flags & LEG_RIGHT)
			thermal_protection += THERMAL_PROTECTION_LEG_RIGHT
		if(thermal_protection_flags & FOOT_LEFT)
			thermal_protection += THERMAL_PROTECTION_FOOT_LEFT
		if(thermal_protection_flags & FOOT_RIGHT)
			thermal_protection += THERMAL_PROTECTION_FOOT_RIGHT
		if(thermal_protection_flags & ARM_LEFT)
			thermal_protection += THERMAL_PROTECTION_ARM_LEFT
		if(thermal_protection_flags & ARM_RIGHT)
			thermal_protection += THERMAL_PROTECTION_ARM_RIGHT
		if(thermal_protection_flags & HAND_LEFT)
			thermal_protection += THERMAL_PROTECTION_HAND_LEFT
		if(thermal_protection_flags & HAND_RIGHT)
			thermal_protection += THERMAL_PROTECTION_HAND_RIGHT

	return min(1, round(thermal_protection, 0.001))

//See proc/get_heat_protection_flags(temperature) for the description of this proc.
/mob/living/carbon/human/proc/get_cold_protection_flags(temperature)
	var/thermal_protection_flags = 0
	//Handle normal clothing

	if(head)
		if(head.min_cold_protection_temperature && head.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= head.cold_protection
	if(wear_suit)
		if(wear_suit.min_cold_protection_temperature && wear_suit.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= wear_suit.cold_protection
	if(w_uniform)
		if(w_uniform.min_cold_protection_temperature && w_uniform.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= w_uniform.cold_protection
	if(shoes)
		if(shoes.min_cold_protection_temperature && shoes.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= shoes.cold_protection
	if(gloves)
		if(gloves.min_cold_protection_temperature && gloves.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= gloves.cold_protection
	if(wear_mask)
		if(wear_mask.min_cold_protection_temperature && wear_mask.min_cold_protection_temperature <= temperature)
			thermal_protection_flags |= wear_mask.cold_protection

	return thermal_protection_flags

/mob/living/carbon/human/get_cold_protection(temperature)
	// There is an occasional bug where the temperature is miscalculated in areas with small amounts of gas.
	// This is necessary to ensure that does not affect this calculation.
	// Space's temperature is 2.7K and most suits that are intended to protect against any cold, protect down to 2.0K.
	temperature = max(temperature, 2.7)
	var/thermal_protection_flags = get_cold_protection_flags(temperature)
	var/thermal_protection = cold_protection

	// Apply clothing items protection
	if(thermal_protection_flags)
		if(thermal_protection_flags & HEAD)
			thermal_protection += THERMAL_PROTECTION_HEAD
		if(thermal_protection_flags & CHEST)
			thermal_protection += THERMAL_PROTECTION_CHEST
		if(thermal_protection_flags & GROIN)
			thermal_protection += THERMAL_PROTECTION_GROIN
		if(thermal_protection_flags & LEG_LEFT)
			thermal_protection += THERMAL_PROTECTION_LEG_LEFT
		if(thermal_protection_flags & LEG_RIGHT)
			thermal_protection += THERMAL_PROTECTION_LEG_RIGHT
		if(thermal_protection_flags & FOOT_LEFT)
			thermal_protection += THERMAL_PROTECTION_FOOT_LEFT
		if(thermal_protection_flags & FOOT_RIGHT)
			thermal_protection += THERMAL_PROTECTION_FOOT_RIGHT
		if(thermal_protection_flags & ARM_LEFT)
			thermal_protection += THERMAL_PROTECTION_ARM_LEFT
		if(thermal_protection_flags & ARM_RIGHT)
			thermal_protection += THERMAL_PROTECTION_ARM_RIGHT
		if(thermal_protection_flags & HAND_LEFT)
			thermal_protection += THERMAL_PROTECTION_HAND_LEFT
		if(thermal_protection_flags & HAND_RIGHT)
			thermal_protection += THERMAL_PROTECTION_HAND_RIGHT

	return min(1, round(thermal_protection, 0.001))

/mob/living/carbon/human/has_smoke_protection()
	if(isclothing(wear_mask))
		if(wear_mask.clothing_flags & BLOCK_GAS_SMOKE_EFFECT)
			return TRUE
	if(isclothing(glasses))
		if(glasses.clothing_flags & BLOCK_GAS_SMOKE_EFFECT)
			return TRUE
	if(isclothing(head))
		var/obj/item/clothing/CH = head
		if(CH.clothing_flags & BLOCK_GAS_SMOKE_EFFECT)
			return TRUE
	return ..()

/mob/living/carbon/human/proc/handle_heart(seconds_per_tick)
	var/we_breath = !HAS_TRAIT_FROM(src, TRAIT_NOBREATH, SPECIES_TRAIT)

	if(!undergoing_cardiac_arrest())
		return

	if(we_breath)
		set_lung_air_quality(min(lung_air_quality, 0.35))
		Unconscious(80)
	// Tissues die without blood circulation
	adjust_brute_loss(1 * seconds_per_tick)

#undef THERMAL_PROTECTION_HEAD
#undef THERMAL_PROTECTION_CHEST
#undef THERMAL_PROTECTION_GROIN
#undef THERMAL_PROTECTION_LEG_LEFT
#undef THERMAL_PROTECTION_LEG_RIGHT
#undef THERMAL_PROTECTION_FOOT_LEFT
#undef THERMAL_PROTECTION_FOOT_RIGHT
#undef THERMAL_PROTECTION_ARM_LEFT
#undef THERMAL_PROTECTION_ARM_RIGHT
#undef THERMAL_PROTECTION_HAND_LEFT
#undef THERMAL_PROTECTION_HAND_RIGHT
