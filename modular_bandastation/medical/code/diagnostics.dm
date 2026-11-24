/mob/living/proc/has_medical_competence()
	return HAS_TRAIT(src, TRAIT_MEDICAL_TRAINING) || HAS_TRAIT(src, TRAIT_PROFESSIONAL_DOCTOR)

/mob/living/carbon/proc/medical_auscultation(selected_zone, mob/living/examiner)
	var/list/result = list()
	examiner.add_mood_event("medical_diagnosis", /datum/mood_event/medical_diagnosis)
	if(selected_zone == BODY_ZONE_PRECISE_GROIN)
		var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
		if(liver && liver.damage > liver.maxHealth * 0.3)
			result += liver.damage > liver.maxHealth * 0.6 ? "Свистящие звуки и выраженное газообразование." : "Необычные булькающие звуки."
		return result
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(lungs && !HAS_TRAIT(src, TRAIT_NOBREATH))
		if(stat == DEAD || failed_last_breath || (lungs.organ_flags & ORGAN_FAILING))
			result += "Дыхание не прослушивается."
		else if(lungs.damage > lungs.maxHealth * 0.6)
			result += "Выраженные хрипы."
		else if(lungs.damage > lungs.maxHealth * 0.3 || get_oxy_loss() > 10)
			result += "Тяжёлое дыхание."
		else
			result += lungs.hear_breath_noise(examiner)
		var/datum/component/medical_condition/condition = lungs.get_medical_condition(FALSE)
		if(condition?.organ_bleeding)
			result += "Влажные хрипы с признаками повреждения лёгкого."
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	if(heart?.is_beating())
		if(heart.damage > heart.maxHealth * 0.6)
			result += "Слабое сердцебиение."
		else if(heart.damage > heart.maxHealth * 0.3)
			result += "Неровный ритм."
	else if(needs_heart())
		result += "Сердцебиение отсутствует."
	return result

/mob/living/carbon/proc/medical_eye_exam()
	var/list/result = list()
	var/obj/item/organ/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(!eyes || is_blind())
		return result
	if(eyes.damage > eyes.maxHealth * 0.5)
		result += "Движения глаз замедлены."
	if(has_status_effect(/datum/status_effect/eye_blur))
		result += "Медленная фокусировка."
	var/obj/item/organ/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
	if(brain && length(brain.traumas))
		result += "Нарушена фокусировка и координация движений глаз."
	if(medical_pressure > 135)
		result += "Признаки повышенного давления."
	else if(medical_pressure < 70)
		result += "Вялая реакция, признаки пониженного давления."
	if(medical_analgesia(BODY_ZONE_HEAD) || IsSleeping())
		result += "Глаза закрываются замедленно."
	return result

/mob/living/carbon/proc/medical_mouth_exam()
	var/list/result = list()
	if(!get_organ_slot(ORGAN_SLOT_TONGUE))
		return result
	if(get_tox_loss() > 10)
		result += "Зеленоватый налёт на языке."
	if(length(diseases))
		result += "Слизь во рту."
	for(var/slot in list(ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH))
		var/obj/item/organ/organ = get_organ_slot(slot)
		if(!organ)
			continue
		if(organ.organ_flags & ORGAN_FAILING)
			result |= "Серый налёт на языке."
		else if(organ.damage > organ.maxHealth * 0.5)
			result |= "Желтоватый налёт на языке."
	return result

/// An explicit action avoids replacing help-clicks, CPR or martial arts.
/mob/living/carbon/human/verb/medical_palpate(mob/living/carbon/patient as mob in oview(1))
	set name = "Медицинский осмотр"
	set category = "IC"
	if(!has_medical_competence() || incapacitated || combat_mode)
		return
	var/selected_zone = check_zone(zone_selected)
	var/obj/item/bodypart/limb = patient.get_bodypart(selected_zone)
	var/turf/exam_turf = get_turf(patient)
	if(!limb || exam_turf.get_lumcount() < 0.3 || !patient.is_location_accessible(selected_zone, IGNORED_OPERATION_CLOTHING_SLOTS))
		to_chat(src, span_warning("Для осмотра нужен свет и доступ к выбранной части тела."))
		return
	if(!do_after(src, 3 SECONDS, patient) || QDELETED(limb) || limb.owner != patient || !Adjacent(patient))
		return
	exam_turf = get_turf(patient)
	if(incapacitated || !has_medical_competence() || exam_turf.get_lumcount() < 0.3 || !patient.is_location_accessible(selected_zone, IGNORED_OPERATION_CLOTHING_SLOTS))
		return
	var/list/result = list("Повреждение [limb.plaintext_zone]: [round(limb.get_damage(), 1)].")
	var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
	var/signs = condition?.visible_signs()
	if(signs)
		result += signs
	if(limb.medical_fracture())
		result += "Признаки перелома."
	if(selected_zone == BODY_ZONE_HEAD)
		var/obj/item/organ/ears/ears = patient.get_organ_slot(ORGAN_SLOT_EARS)
		if(ears && ears.damage > ears.maxHealth * 0.3)
			result += "Болезненность в области ушей."
	if(selected_zone == BODY_ZONE_CHEST)
		var/obj/item/organ/stomach/stomach = patient.get_organ_slot(ORGAN_SLOT_STOMACH)
		var/obj/item/organ/appendix/appendix = patient.get_organ_slot(ORGAN_SLOT_APPENDIX)
		if(stomach && stomach.damage > stomach.maxHealth * 0.6)
			result += "Выраженное уплотнение живота."
		else if((stomach && stomach.damage > stomach.maxHealth * 0.3) || (appendix && appendix.organ_flags & ORGAN_FAILING))
			result += "Живот вздут."
		else if(!stomach && !HAS_TRAIT(patient, TRAIT_NOHUNGER))
			result += "Желудок не прощупывается."
	to_chat(src, boxed_message(jointext(result, "<br>")))
	add_mood_event("medical_diagnosis", /datum/mood_event/medical_diagnosis)

/datum/mood_event/medical_diagnosis
	description = "Я провёл медицинский осмотр и помог разобраться в состоянии пациента.\n"
	mood_change = 2
	timeout = 2 MINUTES
