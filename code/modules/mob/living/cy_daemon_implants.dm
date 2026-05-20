/mob/living/proc/get_cy_organization_type_for_thing(datum/thing)
	if(!thing)
		return null
	if(thing.vars.Find("manufacturer_organization"))
		var/datum/cy_organization/manufacturer = resolve_cy_organization_datum(thing.vars["manufacturer_organization"])
		if(manufacturer)
			return manufacturer.type
	if(thing.vars.Find("cy_organization_type"))
		return thing.vars["cy_organization_type"]
	if(thing.vars.Find("manufacturer_organization_type"))
		return thing.vars["manufacturer_organization_type"]
	return null

/mob/living/proc/get_cy_daemon_cast_time_multiplier(datum/daemon_source)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_DAEMON_CORP_MISMATCH_CAST_MULTIPLIER
	var/fast_code_level = get_cy_skill_level(/datum/cy_skill/intelligence/fast_code)
	if(!fast_code_level)
		multiplier *= 1.1
	else if(fast_code_level >= 2)
		multiplier *= 0.8
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/fast_code, 4) && prob(25))
		multiplier *= 0.5
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/fast_code, 6) && prob(25))
		multiplier = 0
	return multiplier

/mob/living/proc/get_cy_daemon_effectiveness_multiplier(datum/daemon_source)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_DAEMON_CORP_MISMATCH_EFFECTIVENESS_MULTIPLIER
	var/improved_code_level = get_cy_skill_level(/datum/cy_skill/intelligence/improved_code)
	if(!improved_code_level)
		multiplier *= 0.8
	else if(improved_code_level >= 2)
		multiplier *= 1.3
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/improved_code, 3))
		multiplier *= 1.25
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/improved_code, 6))
		multiplier *= 1.5
	return multiplier

/obj/item/organ/cyberimp
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	var/cy_organization_type
	var/cy_implant_is_neurointerface = FALSE
	var/cy_overheat = 0
	var/cy_active_implant = TRUE
	var/cy_requires_neurointerface = TRUE
	var/cy_last_functional_state

/obj/item/organ/cyberimp/brain
	manufacturer_organization = /datum/cy_organization/corporation/starlight/samanthas_care

/obj/item/organ/cyberimp/brain/connector
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_implant_is_neurointerface = TRUE
	cy_requires_neurointerface = FALSE

/obj/item/organ/cyberimp/bci
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_implant_is_neurointerface = TRUE
	cy_requires_neurointerface = FALSE

/obj/item/organ/cyberimp/eyes
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon

/obj/item/organ/cyberimp/mouth
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa

/obj/item/organ/cyberimp/arm
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla

/obj/item/organ/cyberimp/chest
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski

/obj/item/organ/cyberimp/chest/thrusters
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi

/obj/item/organ/cyberimp/chest/spine
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla

/obj/item/organ/cyberimp/proc/has_cy_working_neurointerface()
	if(!cy_requires_neurointerface)
		return TRUE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/human_owner = owner
	return human_owner.has_cy_neurointerface()

/obj/item/organ/cyberimp/proc/is_cy_active_implant()
	return cy_active_implant && has_cy_working_neurointerface()

/obj/item/organ/cyberimp/proc/is_cy_functional_implant()
	return !(organ_flags & ORGAN_FAILING) && has_cy_working_neurointerface()

/obj/item/organ/cyberimp/proc/can_cy_use_implant(mob/living/user, silent = FALSE)
	if(!owner)
		return FALSE
	if(organ_flags & ORGAN_FAILING)
		if(!silent)
			to_chat(user || owner, span_warning("[src] does not respond."))
		return FALSE
	if(!has_cy_working_neurointerface())
		if(!silent)
			to_chat(user || owner, span_warning("[src] needs a working neural interface."))
		return FALSE
	return TRUE

/obj/item/organ/cyberimp/proc/update_cy_functional_state()
	var/current_state = is_cy_functional_implant()
	if(isnull(cy_last_functional_state))
		cy_last_functional_state = current_state
		return current_state
	if(cy_last_functional_state == current_state)
		return current_state
	cy_last_functional_state = current_state
	cy_on_functional_state_changed(current_state)
	return current_state

/obj/item/organ/cyberimp/proc/cy_on_functional_state_changed(functional)
	return TRUE

/obj/item/organ/cyberimp/proc/get_cy_implant_overheat()
	return cy_overheat

/obj/item/organ/cyberimp/proc/adjust_cy_implant_overheat(amount)
	cy_overheat = max(0, cy_overheat + amount)
	return cy_overheat

/mob/living/carbon/human/proc/has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		if(implant.organ_flags & ORGAN_FAILING)
			continue
		if(implant.cy_implant_is_neurointerface || implant.type == /obj/item/organ/cyberimp/brain || findtext("[implant.type]", "neuro"))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/get_cy_implant_overheat_multiplier(obj/item/organ/cyberimp/implant)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(implant)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_IMPLANT_CORP_MISMATCH_OVERHEAT_MULTIPLIER
	if(!get_cy_skill_level(/datum/cy_skill/spirit/compatibility))
		multiplier *= 1.2
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 3))
		multiplier *= 0.5
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 4))
		multiplier *= 0.7
	return multiplier

// CYBERPUNK 13 STAGE 3 CORE IMPLANT HEAT FIX3 START
/mob/living/carbon/human/proc/get_cy_implant_humanoidity_heat_multiplier()
	if(!has_dna())
		return 1
	return 1 + ((100 - get_cy_humanoidity()) * CY_IMPLANT_HUMANITY_HEAT_MULTIPLIER)
// CYBERPUNK 13 STAGE 3 CORE IMPLANT HEAT FIX3 END

/mob/living/carbon/human/proc/get_cy_implant_failure_chance_modifier(obj/item/organ/cyberimp/implant)
	var/modifier = 0
	var/org_type = get_cy_organization_type_for_thing(implant)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			modifier += CY_IMPLANT_CORP_MISMATCH_FAILURE_MODIFIER
	if(!get_cy_skill_level(/datum/cy_skill/spirit/compatibility))
		modifier += 1
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 6))
		modifier -= 100
	return modifier

/mob/living/carbon/human/proc/get_cy_total_implant_overheat()
	var/total = 0
	for(var/obj/item/organ/cyberimp/implant in organs)
		total += implant.get_cy_implant_overheat()
	return total

/mob/living/carbon/human/proc/get_cy_brain_overheat_capacity()
	var/capacity = max(10, get_cy_stat(/datum/cy_stat/spirit) * 10 + get_cy_stat(/datum/cy_stat/intelligence) * 5)
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 2))
		capacity *= 1.3
	return capacity

/mob/living/carbon/human/proc/process_cy_implant_overheat(seconds_per_tick)
	var/has_interface = has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		implant.update_cy_functional_state()
		if(implant.cy_requires_neurointerface && !has_interface)
			if(SPT_PROB(CY_IMPLANT_NO_INTERFACE_FAILURE_CHANCE, seconds_per_tick))
				implant.apply_organ_damage(0.25 * seconds_per_tick)
			continue
		var/heat_gain = implant.is_cy_active_implant() ? CY_IMPLANT_BASE_ACTIVE_HEAT_PER_SECOND : CY_IMPLANT_BASE_PASSIVE_HEAT_PER_SECOND
		implant.adjust_cy_implant_overheat((heat_gain * get_cy_implant_overheat_multiplier(implant) * get_cy_implant_humanoidity_heat_multiplier() - CY_IMPLANT_OVERHEAT_DECAY_PER_SECOND) * seconds_per_tick)
	var/overflow = get_cy_total_implant_overheat() - get_cy_brain_overheat_capacity()
	if(overflow <= 0)
		return FALSE
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 5))
		add_movespeed_modifier(/datum/movespeed_modifier/cy_implant_overload)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cy_implant_overload), 2 SECONDS)
		return TRUE
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/compatibility, 6))
		return TRUE
	adjust_psychic_loss(overflow * CY_IMPLANT_OVERHEAT_PSYCHIC_PER_SECOND * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	adjust_pain_loss(overflow * CY_IMPLANT_OVERHEAT_PAIN_PER_SECOND * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	if(overflow >= get_cy_brain_overheat_capacity() && SPT_PROB(1, seconds_per_tick))
		adjust_organ_loss(ORGAN_SLOT_BRAIN, 1)
