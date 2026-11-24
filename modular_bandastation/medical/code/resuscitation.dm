/mob/living/carbon
	var/medical_cpr_last = -INFINITY
	var/medical_cpr_errors = 0
	var/medical_cpr_error_time = 0
	var/medical_defib_last = -INFINITY
	var/medical_defib_attempts = 0

/mob/living/carbon/proc/can_receive_medical_cpr()
	return body_position == LYING_DOWN && (stat == DEAD || health < 0 || get_oxy_loss() > 0) && needs_heart() && get_organ_slot(ORGAN_SLOT_HEART)

/// The first active circulation window wins, even with several rescuers or machines.
/mob/living/carbon/proc/apply_medical_cpr(trained = FALSE)
	if(!can_receive_medical_cpr())
		return FALSE
	var/recovery_interval = trained ? 4 SECONDS : 10 SECONDS
	medical_cpr_errors = max(0, medical_cpr_errors - floor((world.time - medical_cpr_error_time) / recovery_interval))
	if(!trained && world.time < medical_cpr_last + 5 SECONDS)
		medical_cpr_errors = min(10, medical_cpr_errors + 1)
	medical_cpr_last = world.time
	medical_cpr_error_time = world.time
	if(world.time >= medical_cpr_protection_until)
		medical_cpr_protection_until = world.time + (trained ? 3 SECONDS : 2 SECONDS)
	if(get_organ_slot(ORGAN_SLOT_LUNGS) && !HAS_TRAIT(src, TRAIT_NOBREATH))
		adjust_oxy_loss(-(trained ? 5 : 3) * max(0, 1 - medical_cpr_errors * 0.1))
	if(prob(clamp(medical_cpr_errors * 10, 0, 100)))
		var/obj/item/bodypart/chest = get_bodypart(BODY_ZONE_CHEST)
		chest?.force_wound_upwards(/datum/wound/blunt/bone/severe)
	return TRUE

/mob/living/carbon/human/proc/perform_medical_cpr(mob/living/carbon/target)
	if(target == src || QDELETED(target) || DOING_INTERACTION_WITH_TARGET(src, target))
		return FALSE
	var/trained = HAS_TRAIT(src, TRAIT_MEDICAL_TRAINING)
	do
		if(!target.can_receive_medical_cpr() || incapacitated || !Adjacent(target) || is_mouth_covered() || target.is_mouth_covered())
			return FALSE
		var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(!lungs || (lungs.organ_flags & ORGAN_FAILING))
			return FALSE
		if(!do_after(src, trained ? 1 SECONDS : 2 SECONDS, target))
			return FALSE
		if(QDELETED(target) || !Adjacent(target) || incapacitated || is_mouth_covered() || target.is_mouth_covered())
			return FALSE
		lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(!lungs || (lungs.organ_flags & ORGAN_FAILING) || HAS_TRAIT_FROM(src, TRAIT_NOBREATH, DISEASE_TRAIT))
			return FALSE
		trained = HAS_TRAIT(src, TRAIT_MEDICAL_TRAINING)
		if(!target.apply_medical_cpr(trained))
			return FALSE
		adjust_stamina_loss(trained ? 2 : 5)
		visible_message(span_notice("[src] проводит СЛР [target.declent_ru(DATIVE)]."))
		add_mood_event("saved_life", /datum/mood_event/saved_life)
		log_combat(src, target, "CPRed")
		if(!trained || !do_after(src, 2 SECONDS, target))
			break
	while(!QDELETED(target))
	return TRUE

/// Called only after the existing defibrillation eligibility checks.
/mob/living/carbon/proc/medical_defib_roll(mob/living/user, improvised = FALSE)
	if(world.time > medical_defib_last + 30 SECONDS)
		medical_defib_attempts = 0
	var/base_chance = improvised ? 50 : 60
	if(user && HAS_TRAIT(user, TRAIT_MEDICAL_TRAINING))
		base_chance = 70
	var/chance = min(100, base_chance + medical_defib_attempts * (improvised ? 10 : 15))
	medical_defib_last = world.time
	medical_defib_attempts++
	return prob(chance)

/obj/item/skillchip/medical
	name = "MED-1C skillchip"
	desc = "Навыки медицинской диагностики, реанимации и хирургии."
	auto_traits = list(TRAIT_MEDICAL_TRAINING)
	skill_name = "Медицинская подготовка"
	skill_description = "Диагностика, автоматические циклы СЛР, улучшенная дефибрилляция и хирургия."
	skill_icon = FA_ICON_USER_DOCTOR
	activate_message = span_notice("Вы вспоминаете протоколы медицинской помощи.")
	deactivate_message = span_notice("Детали медицинских протоколов ускользают из памяти.")

/datum/quirk/professional_doctor
	name = "Профессиональный врач"
	desc = "Вы умеете проводить подробный ручной медицинский осмотр."
	value = 2
	icon = FA_ICON_USER_DOCTOR
	mob_trait = TRAIT_PROFESSIONAL_DOCTOR
	gain_text = span_notice("Вы уверенно распознаёте медицинские симптомы.")
	lose_text = span_notice("Подробности диагностики ускользают из памяти.")
	medical_record_text = "Имеет медицинскую подготовку."

/datum/quirk/professional_surgeon
	name = "Профессиональный хирург"
	desc = "Опыт позволяет реже ошибаться и меньше загрязнять ткани во время операции."
	value = 4
	icon = FA_ICON_USER_DOCTOR
	mob_trait = TRAIT_PROFESSIONAL_SURGEON
	gain_text = span_notice("Ваши руки уверенно держат хирургические инструменты.")
	lose_text = span_notice("Вы больше не уверены в своей хирургической подготовке.")
	medical_record_text = "Имеет хирургическую подготовку."
