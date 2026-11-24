/// Local injury state belongs to the tissue, so removing it also removes its processing.
/datum/component/medical_condition
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/pain = 0
	var/contamination = 0
	var/infection_seconds = 0
	var/antiseptic_seconds = 0
	var/organ_bleeding = FALSE
	var/list/minor_wounds
	var/minor_healing_seconds = 0
	var/pain_rolls = 0

/datum/component/medical_condition/Initialize()
	if(!isbodypart(parent) && !isorgan(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/medical_condition/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	REMOVE_TRAIT(parent, TRAIT_PARALYSIS, REF(src))
	return ..()

/datum/component/medical_condition/RegisterWithParent()
	RegisterSignal(parent, isbodypart(parent) ? COMSIG_BODYPART_CHANGED_OWNER : COMSIG_ORGAN_IMPLANTED, PROC_REF(ownership_changed))

/datum/component/medical_condition/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_BODYPART_CHANGED_OWNER, COMSIG_ORGAN_IMPLANTED))

/datum/component/medical_condition/proc/ownership_changed(datum/source, mob/living/carbon/new_owner)
	SIGNAL_HANDLER
	if(new_owner)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)

/datum/component/medical_condition/proc/patient()
	if(isbodypart(parent))
		var/obj/item/bodypart/limb = parent
		return limb.owner
	var/obj/item/organ/organ = parent
	return organ.owner

/datum/component/medical_condition/proc/zone()
	if(isbodypart(parent))
		var/obj/item/bodypart/limb = parent
		return limb.body_zone
	var/obj/item/organ/organ = parent
	return organ.zone

/datum/component/medical_condition/proc/injury_floor()
	if(isbodypart(parent))
		var/obj/item/bodypart/limb = parent
		return max(limb.get_damage() * 0.25, limb.medical_fracture() ? 25 : 0)
	var/obj/item/organ/organ = parent
	return organ.damage * 0.25

/// Only a positive impulse may roll consequences. Decay and restored sensation never call this.
/datum/component/medical_condition/proc/add_pain(amount)
	var/mob/living/carbon/owner = patient()
	if(amount <= 0 || !owner || HAS_TRAIT(owner, TRAIT_GODMODE))
		return
	var/analgesia = owner.medical_analgesia(zone())
	var/increase = amount * (1 - analgesia)
	if(increase <= 0)
		return
	var/old_pain = pain
	pain = min(300, pain + increase)
	if(pain <= old_pain)
		return
	START_PROCESSING(SSobj, src)
	if(owner.stat == DEAD)
		return
	var/threshold = 40 * (1 + analgesia)
	if(pain < threshold)
		return
	pain_rolls++
	if(prob(clamp((pain - threshold) * 0.6, 0, 60)))
		owner.apply_status_effect(/datum/status_effect/medical_pain)
	if(pain < threshold * 2 || !prob(clamp((pain - threshold * 2) * 0.5, 0, 50)))
		return
	if(!HAS_TRAIT(owner, TRAIT_PAIN_NUMB))
		to_chat(owner, span_warning("Резкий приступ боли мешает вам двигаться!"))
	var/affected = zone()
	if(isorgan(parent))
		var/obj/item/organ/organ = parent
		affected = organ.slot
	switch(affected)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			var/obj/item/bodypart/arm/arm = parent
			owner.dropItemToGround(owner.get_item_for_held_index(arm.held_index))
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			owner.Knockdown(1 SECONDS)
		if(BODY_ZONE_HEAD, ORGAN_SLOT_BRAIN, ORGAN_SLOT_EARS)
			owner.adjust_confusion(3 SECONDS)
			owner.adjust_eye_blur(5 SECONDS)
			var/obj/item/organ/ears/ears = owner.get_organ_slot(ORGAN_SLOT_EARS)
			ears?.adjust_temporary_deafness(3 SECONDS)
		if(ORGAN_SLOT_EYES)
			owner.adjust_eye_blur(10 SECONDS)
		if(ORGAN_SLOT_TONGUE)
			owner.adjust_slurring(5 SECONDS)
		if(ORGAN_SLOT_HEART)
			owner.apply_status_effect(/datum/status_effect/medical_arrhythmia)
		if(ORGAN_SLOT_LUNGS)
			owner.adjust_oxy_loss(3)
		else
			owner.apply_status_effect(/datum/status_effect/medical_pain)

/datum/component/medical_condition/proc/add_contamination(amount)
	if(!isbodypart(parent) || amount <= 0 || antiseptic_seconds > 0)
		return
	var/obj/item/bodypart/limb = parent
	if(!IS_ORGANIC_LIMB(limb) || !(limb.biological_state & BIO_FLESH))
		return
	contamination = min(100, contamination + amount)
	if(contamination >= 100 && !infection_seconds)
		infection_seconds = 1
		START_PROCESSING(SSobj, src)

/datum/component/medical_condition/proc/infection_stage()
	return infection_seconds > 0 ? min(4, 1 + floor(infection_seconds / 400)) : 0

/datum/component/medical_condition/proc/sterilize(power = 1)
	contamination = 0
	antiseptic_seconds = max(antiseptic_seconds, 30 * power)
	if(infection_stage() < 3)
		treat_infection(60 * power)
	START_PROCESSING(SSobj, src)

/datum/component/medical_condition/proc/treat_infection(amount, critical = FALSE)
	if(infection_stage() == 4 && !critical)
		return FALSE
	infection_seconds = max(0, infection_seconds - amount)
	if(!infection_seconds)
		contamination = 0
	if(infection_stage() < 4)
		REMOVE_TRAIT(parent, TRAIT_PARALYSIS, REF(src))
	return TRUE

/datum/component/medical_condition/proc/add_minor(kind)
	LAZYSET(minor_wounds, kind, min(20, LAZYACCESS(minor_wounds, kind) + 1))
	START_PROCESSING(SSobj, src)

/// Visible tissue signs are shared by examination, manual diagnosis and the wound scanner.
/datum/component/medical_condition/proc/visible_signs()
	var/list/signs = list()
	if(LAZYACCESS(minor_wounds, WOUND_SLASH))
		signs += "мелкие порезы ([minor_wounds[WOUND_SLASH]])"
	if(LAZYACCESS(minor_wounds, WOUND_PIERCE))
		signs += "мелкие проколы ([minor_wounds[WOUND_PIERCE]])"
	if(LAZYACCESS(minor_wounds, WOUND_BLUNT))
		signs += "гематомы ([minor_wounds[WOUND_BLUNT]])"
	if(LAZYACCESS(minor_wounds, WOUND_BURN))
		signs += "поверхностные ожоги ([minor_wounds[WOUND_BURN]])"
	switch(infection_stage())
		if(1)
			signs += "воспалённые края ран"
		if(2)
			signs += "отёк и нагноение"
		if(3)
			signs += "выраженная инфекция тканей"
		if(4)
			signs += "некротические ткани"
	return jointext(signs, ", ")

/datum/component/medical_condition/proc/treat_minor(brute, burn, bruises = TRUE)
	if(brute)
		LAZYREMOVE(minor_wounds, WOUND_SLASH)
		LAZYREMOVE(minor_wounds, WOUND_PIERCE)
		if(bruises)
			LAZYREMOVE(minor_wounds, WOUND_BLUNT)
	if(burn)
		LAZYREMOVE(minor_wounds, WOUND_BURN)

/datum/component/medical_condition/process(seconds_per_tick)
	var/mob/living/carbon/owner = patient()
	if(!owner)
		return PROCESS_KILL
	seconds_per_tick *= owner.medical_time_scale()
	antiseptic_seconds = max(0, antiseptic_seconds - seconds_per_tick)
	if(owner.stat != DEAD)
		var/analgesia = owner.medical_analgesia(zone())
		pain = max(min(pain, injury_floor() * (1 - analgesia)), pain - (0.5 + 2 * analgesia) * seconds_per_tick)
		process_infection(owner, seconds_per_tick)
		process_organ_bleeding(owner, seconds_per_tick)
		if(LAZYLEN(minor_wounds))
			minor_healing_seconds += seconds_per_tick
			if(LAZYACCESS(minor_wounds, WOUND_SLASH))
				owner.bleed(min(0.5, minor_wounds[WOUND_SLASH] * 0.05) * seconds_per_tick)
			if(LAZYACCESS(minor_wounds, WOUND_PIERCE))
				owner.bleed(min(0.2, minor_wounds[WOUND_PIERCE] * 0.02) * seconds_per_tick)
			if(minor_healing_seconds >= 180)
				minor_healing_seconds -= 180
				for(var/kind in minor_wounds.Copy())
					minor_wounds[kind]--
					if(minor_wounds[kind] <= 0)
						LAZYREMOVE(minor_wounds, kind)
	if(!pain && !infection_seconds && !antiseptic_seconds && !organ_bleeding && !LAZYLEN(minor_wounds))
		return PROCESS_KILL

/datum/component/medical_condition/proc/process_infection(mob/living/carbon/owner, seconds_per_tick)
	if(!infection_seconds || !isbodypart(parent))
		return
	var/obj/item/bodypart/limb = parent
	if(owner.bodytemperature > T0C + 10)
		var/growth = owner.bodytemperature > T0C + 40 ? 1.5 : 1
		for(var/datum/wound/burn/burn in limb.wounds)
			if(burn.severity >= WOUND_SEVERITY_SEVERE)
				growth += 0.5
		infection_seconds = min(1200, infection_seconds + growth * seconds_per_tick)
	var/stage = infection_stage()
	if(stage < 3)
		return
	if(stage == 4)
		ADD_TRAIT(limb, TRAIT_PARALYSIS, REF(src))
		owner.adjust_tox_loss(0.15 * seconds_per_tick)
		for(var/obj/item/organ/organ as anything in owner.organs)
			if(check_zone(organ.zone) == limb.body_zone && (organ.organ_flags & ORGAN_ORGANIC))
				organ.apply_organ_damage(0.1 * seconds_per_tick)
	if(!SPT_PROB(2, seconds_per_tick))
		return
	switch(limb.body_zone)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			var/obj/item/bodypart/arm/arm = limb
			owner.dropItemToGround(owner.get_item_for_held_index(arm.held_index))
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			owner.Knockdown(0.5 SECONDS)
		if(BODY_ZONE_CHEST)
			owner.adjust_tox_loss(1)
		if(BODY_ZONE_HEAD)
			add_pain(2)
			if(ishuman(owner))
				var/mob/living/carbon/human/human = owner
				human.set_hairstyle("Bald")

/datum/component/medical_condition/proc/process_organ_bleeding(mob/living/carbon/owner, seconds_per_tick)
	if(!organ_bleeding || !isorgan(parent))
		return
	owner.bleed(0.15 * seconds_per_tick)
	if(!SPT_PROB(2, seconds_per_tick))
		return
	var/obj/item/organ/organ = parent
	switch(organ.slot)
		if(ORGAN_SLOT_LUNGS)
			owner.emote("cough")
			organ.apply_organ_damage(2)
		if(ORGAN_SLOT_HEART)
			owner.apply_status_effect(/datum/status_effect/medical_arrhythmia)
		if(ORGAN_SLOT_STOMACH)
			owner.vomit()
		if(ORGAN_SLOT_LIVER)
			add_pain(8)

/obj/item/proc/get_medical_condition(create = TRUE) as /datum/component/medical_condition
	var/datum/component/medical_condition/condition = GetComponent(/datum/component/medical_condition)
	if(!condition && create)
		condition = AddComponent(/datum/component/medical_condition)
	return condition

/// Dislocations do not open the organ injury pathway; actual fractures do.
/obj/item/bodypart/proc/medical_fracture()
	for(var/datum/wound/blunt/bone/fracture in wounds)
		if(fracture.severity >= WOUND_SEVERITY_SEVERE)
			return TRUE
	return FALSE

/// Called after protection and limb-cap clamping, with fracture state captured before the hit.
/obj/item/bodypart/proc/medical_hit(brute, burn, sharpness, had_fracture, allow_wounds)
	if(!owner || !IS_ORGANIC_LIMB(src) || brute + burn <= 0)
		return
	var/datum/component/medical_condition/condition = get_medical_condition()
	var/minor_count = 0
	for(var/kind in condition.minor_wounds)
		minor_count += condition.minor_wounds[kind]
	var/sensitivity = 1 + min(0.5, minor_count * 0.1)
	condition.add_pain((brute + burn * 1.5) * sensitivity)
	condition.add_contamination((burn + (sharpness ? brute : 0)) * 0.1)
	owner.medical_activity = min(45, owner.medical_activity + min(10, (brute + burn) * 0.2))
	if(body_zone == BODY_ZONE_HEAD && brute >= 20 && allow_wounds)
		owner.adjust_confusion(2 SECONDS)
		owner.adjust_eye_blur(3 SECONDS)
	var/kind = burn > brute ? WOUND_BURN : (sharpness & SHARP_EDGED ? WOUND_SLASH : (sharpness & SHARP_POINTY ? WOUND_PIERCE : WOUND_BLUNT))
	if(allow_wounds && brute + burn >= 2 && brute + burn < 15)
		condition.add_minor(kind)
	if(allow_wounds && kind == WOUND_BLUNT && brute >= 10 && prob(min(brute, 35)))
		if(owner.has_status_effect(/datum/status_effect/staggered))
			owner.Knockdown(0.5 SECONDS)
		else
			owner.apply_status_effect(/datum/status_effect/staggered, 3 SECONDS)
	if(kind == WOUND_SLASH && length(wounds))
		owner.bleed(min(2, brute * 0.05))
	if(!had_fracture || !allow_wounds || brute <= 0)
		return
	var/list/candidates = list()
	for(var/obj/item/organ/organ as anything in owner.organs)
		if(check_zone(organ.zone) == body_zone && (organ.organ_flags & ORGAN_ORGANIC) && !(organ.organ_flags & ORGAN_HAZARDOUS))
			candidates += organ
	if(!length(candidates) || !prob(min(60, brute * 2)))
		return
	var/obj/item/organ/struck = pick(candidates)
	var/dealt = struck.apply_organ_damage(min(12, brute * 0.2), required_organ_flag = ORGAN_ORGANIC)
	if(dealt >= 0 || !(sharpness & SHARP_POINTY))
		return
	if(!(struck.slot in list(ORGAN_SLOT_LUNGS, ORGAN_SLOT_HEART, ORGAN_SLOT_STOMACH, ORGAN_SLOT_LIVER)))
		return
	var/datum/component/medical_condition/organ_condition = struck.get_medical_condition()
	organ_condition.organ_bleeding = TRUE
	START_PROCESSING(SSobj, organ_condition)

/datum/status_effect/medical_pain
	id = "medical_pain"
	duration = 5 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/medical_pain/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/medical_pain)
	owner.add_actionspeed_modifier(/datum/actionspeed_modifier/medical_pain)
	RegisterSignal(owner, COMSIG_MOB_FIRED_GUN, PROC_REF(aim_penalty))
	return TRUE

/datum/status_effect/medical_pain/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/medical_pain)
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/medical_pain)
	UnregisterSignal(owner, COMSIG_MOB_FIRED_GUN)

/datum/status_effect/medical_pain/proc/aim_penalty(datum/source, obj/item/gun/gun, atom/target, params, zone, list/bonus_spread_values)
	SIGNAL_HANDLER
	bonus_spread_values[MAX_BONUS_SPREAD_INDEX] += 10

/datum/movespeed_modifier/medical_pain
	multiplicative_slowdown = 0.5

/datum/actionspeed_modifier/medical_pain
	multiplicative_slowdown = 0.15

/// A brief functional arrest does not overwrite a heart's independent stopped/beating state.
/datum/status_effect/medical_arrhythmia
	id = "medical_arrhythmia"
	duration = 3 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/medical_arrhythmia/on_apply()
	ADD_TRAIT(owner, TRAIT_MEDICAL_ARRHYTHMIA, REF(src))
	return TRUE

/datum/status_effect/medical_arrhythmia/on_remove()
	REMOVE_TRAIT(owner, TRAIT_MEDICAL_ARRHYTHMIA, REF(src))
