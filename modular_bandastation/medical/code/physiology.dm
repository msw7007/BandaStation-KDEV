/mob/living/carbon
	var/medical_immunity = 100
	var/medical_pressure = 100
	var/medical_activity = 0
	var/medical_adaptation = 0
	var/medical_cold_exposure = 0
	var/medical_cpr_protection_until = 0
	var/medical_breath_elapsed = 0

/mob/living/carbon/proc/process_medical_life(seconds_per_tick)
	for(var/key in medical_analgesics)
		var/list/entry = medical_analgesics[key]
		entry["seconds"] -= seconds_per_tick
		if(entry["seconds"] <= 0 && !reagents.has_reagent(entry["chemical"]))
			LAZYREMOVE(medical_analgesics, key)
	if(stat == DEAD || !(mob_biotypes & MOB_ORGANIC))
		return
	var/normal_temperature = get_body_temp_normal()
	var/temperature_delta = bodytemperature - normal_temperature
	var/adaptation_speed = get_organ_slot(ORGAN_SLOT_APPENDIX) ? 0.004 : 0.002
	var/desired_adaptation = clamp(temperature_delta, -10, 10)
	medical_adaptation += clamp(desired_adaptation - medical_adaptation, -adaptation_speed * seconds_per_tick, adaptation_speed * seconds_per_tick)
	var/comfort_range = medical_comfort_range()
	var/infection_penalty = 0
	for(var/obj/item/bodypart/limb as anything in bodyparts)
		var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
		if(condition?.infection_stage() >= 2)
			infection_penalty += 10
	medical_immunity = clamp(100 - abs(temperature_delta - medical_adaptation) * 40 / comfort_range - infection_penalty, 0, 100)
	if(HAS_TRAIT(src, TRAIT_VIRUSIMMUNE))
		medical_immunity = 100
	else if(abs(temperature_delta - medical_adaptation) > comfort_range)
		medical_cold_exposure += seconds_per_tick
		if(medical_cold_exposure >= 180)
			medical_cold_exposure = 0
			var/datum/disease/cold/cold = new
			if(!ForceContractDisease(cold, make_copy = FALSE))
				qdel(cold)
	else
		medical_cold_exposure = max(0, medical_cold_exposure - seconds_per_tick)
	if(length(diseases) && !HAS_TRAIT(src, TRAIT_VIRUSIMMUNE))
		adjust_bodytemperature(0.05 * seconds_per_tick, normal_temperature, normal_temperature + 2)
		if(SPT_PROB((100 - medical_immunity) * 0.01, seconds_per_tick))
			INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, emote), "sneeze")
			if(prob(100 - medical_immunity))
				dropItemToGround(get_active_held_item())
	medical_activity = max(0, medical_activity - seconds_per_tick)
	var/blood_deficit = CAN_HAVE_BLOOD(src) ? max(0, 1 - get_blood_volume() / BLOOD_VOLUME_NORMAL) : 0
	medical_pressure = clamp(100 + medical_activity + (world.time < medical_adrenaline_until ? 20 : 0) - medical_analgesia(BODY_ZONE_CHEST) * 15 - blood_deficit * 70, 40, 180)
	if(medical_pressure > 135)
		adjust_eye_blur(2 SECONDS)
	if(medical_pressure < 70)
		apply_status_effect(/datum/status_effect/medical_hypotension)

/mob/living/carbon/proc/medical_comfort_range()
	return 10 + (reagents.has_reagent(/datum/reagent/medicine/granibitaluri) ? 3 : 0) + (reagents.has_reagent(/datum/reagent/medicine/leporazine) ? 5 : 0)

/datum/status_effect/medical_hypotension
	id = "medical_hypotension"
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/// Called only after the normal pressure/suit/species protection calculation.
/mob/living/carbon/human/proc/medical_pressure_injury(amount)
	if(amount <= 0 || HAS_TRAIT(src, TRAIT_GODMODE))
		return
	for(var/slot in list(ORGAN_SLOT_LUNGS, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS))
		var/covered_part = slot == ORGAN_SLOT_LUNGS ? CHEST : HEAD
		var/protected = FALSE
		for(var/obj/item/clothing/cover in get_equipped_items())
			if((cover.body_parts_covered & covered_part) && (cover.clothing_flags & STOPSPRESSUREDAMAGE))
				protected = TRUE
				break
		if(protected)
			continue
		var/obj/item/organ/organ = get_organ_slot(slot)
		if(organ && (organ.organ_flags & ORGAN_ORGANIC))
			organ.apply_organ_damage(min(2, amount * 0.1), required_organ_flag = ORGAN_ORGANIC)

/obj/item/organ/tongue/on_life(seconds_per_tick)
	. = ..()
	if(owner && damage > maxHealth * 0.3)
		owner.set_slurring_if_lower(3 SECONDS)

/datum/status_effect/medical_hypotension/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/medical_hypotension)
	owner.adjust_drowsiness(3 SECONDS)
	return TRUE

/datum/status_effect/medical_hypotension/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/medical_hypotension)

/datum/movespeed_modifier/medical_hypotension
	multiplicative_slowdown = 0.3
