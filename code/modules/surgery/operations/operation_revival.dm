/datum/surgery_operation/basic/revival
	name = "Дефибрилляция мозга"
	rnd_name = "Дефибриляция мозга (Оживление)"
	desc = "Использование дефибриллятора, чтобы вернуть мозг пациента к жизни."
	implements = list(
		/obj/item/shockpaddles = 1,
		/obj/item/melee/touch_attack/shock = 1,
		/obj/item/melee/baton/security = 1.33,
		/obj/item/gun/energy = 1.67,
	)
	operation_flags = OPERATION_MORBID | OPERATION_NOTABLE
	time = 5 SECONDS
	preop_sound = list(
		/obj/item/shockpaddles = 'sound/machines/defib/defib_charge.ogg',
		/obj/item = null,
	)
	success_sound = 'sound/machines/defib/defib_zap.ogg'
	required_biotype = NONE
	target_zone = BODY_ZONE_HEAD
	all_surgery_states_required = SURGERY_SKIN_OPEN|SURGERY_BONE_SAWED

/datum/surgery_operation/basic/revival/get_default_radial_image()
	return image(/obj/item/shockpaddles)

/datum/surgery_operation/basic/revival/all_required_strings()
	return ..() + list("пациент должен быть мёртв", "пациент должен быть в состоянии, пригодном для реанимации")

/datum/surgery_operation/basic/revival/state_check(mob/living/patient)
	if(patient.stat != DEAD)
		return FALSE
	if(HAS_TRAIT(patient, TRAIT_SUICIDED) || HAS_TRAIT(patient, TRAIT_HUSK) || HAS_TRAIT(patient, TRAIT_DEFIB_BLACKLISTED))
		return FALSE
	if(patient.has_limbs)
		var/obj/item/organ/brain/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
		return !isnull(brain) && brain_check(brain)
	return mob_check(patient)

/datum/surgery_operation/basic/revival/proc/brain_check(obj/item/organ/brain/brain)
	return !IS_ROBOTIC_ORGAN(brain)

/datum/surgery_operation/basic/revival/proc/mob_check(mob/living/patient)
	return !(patient.mob_biotypes & MOB_ROBOTIC)

/datum/surgery_operation/basic/revival/tool_check(obj/item/tool)
	if(istype(tool, /obj/item/shockpaddles))
		var/obj/item/shockpaddles/paddles = tool
		if((paddles.req_defib && !paddles.defib.powered) || !HAS_TRAIT(paddles, TRAIT_WIELDED) || paddles.cooldown || paddles.busy)
			return FALSE

	if(istype(tool, /obj/item/melee/baton/security))
		var/obj/item/melee/baton/security/baton = tool
		return baton.active

	if(istype(tool, /obj/item/gun/energy))
		var/obj/item/gun/energy/egun = tool
		return istype(egun.chambered, /obj/item/ammo_casing/energy/electrode)

	return TRUE

/datum/surgery_operation/basic/revival/on_preop(mob/living/patient, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		patient,
		span_notice("Вы готовитесь дать мозгу [patient] искру жизни с помощью [tool.declent_ru(ACCUSATIVE)]."),
		span_notice("[surgeon] готовится дать мозгу [patient] искру жизни с помощью [tool.declent_ru(ACCUSATIVE)]."),
		span_notice("[surgeon] готовится дать мозгу [patient] искру жизни."),
	)
	patient.notify_revival("Кто‑то пытается дать разряд вашему мозгу.", source = patient)

/datum/surgery_operation/basic/revival/on_success(mob/living/patient, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		patient,
		span_notice("Вам удаётся успешно ударить мозг [patient] разрядом с помощью [tool.declent_ru(ACCUSATIVE)]..."),
		span_notice("[surgeon] посылает мощный разряд в мозг [patient] с помощью [tool.declent_ru(ACCUSATIVE)]..."),
		span_notice("[surgeon] посылает мощный разряд в мозг [patient]..."),
	)
	patient.grab_ghost()
	patient.adjust_oxy_loss(-50)
	if(iscarbon(patient))
		var/mob/living/carbon/carbon_patient = patient
		carbon_patient.set_heartattack(FALSE)
	if(!patient.revive())
		on_no_revive(surgeon, patient)
		return

	on_revived(surgeon, patient)

/// Called when you have been successfully raised from the dead
/datum/surgery_operation/basic/revival/proc/on_revived(mob/living/surgeon, mob/living/patient)
	patient.visible_message(span_notice("...[patient] приходит в себя - живой и в сознании!"))
	patient.emote("gasp")
	if(HAS_MIND_TRAIT(surgeon, TRAIT_MORBID)) // Contrary to their typical hatred of resurrection, it wouldn't be very thematic if morbid people didn't love playing god
		surgeon.add_mood_event("morbid_revival_success", /datum/mood_event/morbid_revival_success)
	patient.adjust_organ_loss(ORGAN_SLOT_BRAIN, 15, 180)

/// Called when revival fails
/datum/surgery_operation/basic/revival/proc/on_no_revive(mob/living/surgeon, mob/living/patient)
	patient.visible_message(span_warning("...[patient.p_they()] дёргает [patient.p_s()] в конвульсиях и замирает [patient.p_s()]."))
	patient.adjust_organ_loss(ORGAN_SLOT_BRAIN, 50, 199) // MAD SCIENCE

/datum/surgery_operation/basic/revival/on_failure(mob/living/patient, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		patient,
		span_warning("Вы бьёте мозг [patient] разрядом с помощью [tool.declent_ru(ACCUSATIVE)], но [patient.p_they()] никак не реагирует[patient.p_s()]."),
		span_warning("[surgeon] бьёт мозг [patient] разрядом с помощью [tool.declent_ru(ACCUSATIVE)], но [patient.p_they()] никак не реагирует[patient.p_s()]."),
		span_warning("[surgeon] бьёт мозг [patient] разрядом с помощью [tool.declent_ru(ACCUSATIVE)], но [patient.p_they()] никак не реагирует[patient.p_s()]."),
	)

/datum/surgery_operation/basic/revival/mechanic
	name = "Полная перезагрузка системы"
	required_biotype = MOB_ROBOTIC

/datum/surgery_operation/basic/revival/mechanic/brain_check(obj/item/organ/brain/brain)
	return !..()

/datum/surgery_operation/basic/revival/mechanic/mob_check(mob/living/patient)
	return !..()

/datum/surgery_operation/cyberpunk_cpr
	name = "Сердечно-лёгочная реанимация"
	desc = "Циклы компрессий и искусственного дыхания для пациента без сознания."
	time = 5 SECONDS
	implements = list(IMPLEMENT_HAND = 1)
	operation_flags = OPERATION_LOOPING | OPERATION_ALWAYS_FAILABLE | OPERATION_IGNORE_CLOTHES
	cyberpunk_step_severity = SURGERY_STEP_SEVERITY_ADVANCED
	stamina_cost_on_completion = 5 * STAMINA_COST_PROGRESS_TICK

/datum/surgery_operation/cyberpunk_cpr/state_check(mob/living/carbon/patient)
	return iscarbon(patient) && patient.stat >= UNCONSCIOUS && patient.stat < DEAD && !HAS_TRAIT(patient, TRAIT_FAKEDEATH) && patient.body_position == LYING_DOWN && !patient.buckled && patient.oxygenation < 90

/datum/surgery_operation/cyberpunk_cpr/snowflake_check_availability(atom/movable/operating_on, mob/living/surgeon, tool, operated_zone)
	return operated_zone == BODY_ZONE_CHEST && !get_block_reason(operating_on, surgeon)

/datum/surgery_operation/cyberpunk_cpr/proc/get_block_reason(mob/living/carbon/patient, mob/living/carbon/surgeon)
	if(!iscarbon(surgeon) || QDELETED(patient) || patient == surgeon)
		return "СЛР недоступна"
	if(patient.stat == DEAD || HAS_TRAIT(patient, TRAIT_FAKEDEATH))
		return "пациент мёртв"
	if(patient.buckled)
		return "сначала отстегните пациента"
	if(patient.stat < UNCONSCIOUS || patient.body_position != LYING_DOWN)
		return "пациент должен лежать без сознания"
	if(patient.oxygenation >= 90)
		return "оксигенация пациента достаточна"
	if(surgeon.is_mouth_covered() || patient.is_mouth_covered())
		return "освободите рот пациента и свой"
	var/obj/item/organ/lungs/lungs = surgeon.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs || (lungs.organ_flags & ORGAN_FAILING) || HAS_TRAIT_FROM(surgeon, TRAIT_NOBREATH, DISEASE_TRAIT))
		return "вы не можете дышать"
	if(surgeon.stamina <= 0)
		return "не хватает сил"
	return null

/datum/surgery_operation/cyberpunk_cpr/get_location_modifier(turf/operation_turf, mob/living/patient, mob/living/surgeon, tool)
	return 1

/datum/surgery_operation/cyberpunk_cpr/on_preop(mob/living/carbon/patient, mob/living/surgeon, tool, list/operation_args)
	surgeon.visible_message(span_notice("[surgeon] начинает СЛР."), span_notice("Вы начинаете СЛР [patient.declent_ru(GENITIVE)]. Оставайтесь рядом."))

/datum/surgery_operation/cyberpunk_cpr/on_success(mob/living/carbon/patient, mob/living/surgeon, tool, list/operation_args)
	var/obj/item/organ/heart/heart = patient.get_organ_slot(ORGAN_SLOT_HEART)
	if(istype(heart) && !(heart.organ_flags & (ORGAN_FAILING | ORGAN_EMP)) && patient.set_heartattack(FALSE))
		to_chat(surgeon, span_notice("Сердце пациента снова бьётся."))
	support_breathing(patient, 7)
	to_chat(surgeon, span_notice("Вы завершаете цикл СЛР."))
	if(HAS_MIND_TRAIT(surgeon, TRAIT_MORBID))
		surgeon.add_mood_event("morbid_saved_life", /datum/mood_event/morbid_saved_life)
	else
		surgeon.add_mood_event("saved_life", /datum/mood_event/saved_life)
	log_combat(surgeon, patient, "performed CPR on")

/datum/surgery_operation/cyberpunk_cpr/apply_surgery_failure_damage(atom/movable/operating_on, mob/living/surgeon, tool, list/operation_args)
	var/mob/living/carbon/patient = operating_on
	patient.apply_damage(5, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND, brute_type = BODYPART_DAMAGE_BLUNT)

/datum/surgery_operation/cyberpunk_cpr/on_failure(mob/living/carbon/patient, mob/living/surgeon, tool, list/operation_args)
	to_chat(surgeon, span_warning("Неудачная компрессия повредила грудную клетку пациента."))
	support_breathing(patient, 3)

/datum/surgery_operation/cyberpunk_cpr/proc/support_breathing(mob/living/carbon/patient, amount)
	if(patient.stat != DEAD && !HAS_TRAIT(patient, TRAIT_NOBREATH) && patient.get_organ_slot(ORGAN_SLOT_LUNGS))
		patient.adjust_oxy_loss(-amount)
