/// Portable readout deliberately omits surgical detail; stationary and autopsy scans use healthscan().
/obj/item/healthanalyzer/proc/medical_scan(mob/living/user, mob/living/target, tochat = TRUE)
	if(scanpower >= SCANPOWER_SUPER)
		return healthscan(user, target, mode, scanpower, tochat)
	var/oxygen_loss = target.get_oxy_loss()
	if(HAS_TRAIT(target, TRAIT_FAKEDEATH) && target.stat != DEAD)
		oxygen_loss = max(oxygen_loss, 200 - target.get_brute_loss() - target.get_fire_loss() - target.get_tox_loss())
	var/status = IS_DEAD_OR_FAKING(target) ? "смерть" : "[round(100 * target.health / target.maxHealth)]% жизнеспособности"
	var/list/result = list("Пациент: [target.name]", "Состояние: [status]", "Механические повреждения: [target.get_brute_loss()]; ожоги: [target.get_fire_loss()]; токсины: [target.get_tox_loss()]; кислородная недостаточность: [oxygen_loss].")
	SEND_SIGNAL(target, COMSIG_LIVING_HEALTHSCAN, result, scanpower, user, mode, tochat)
	if(iscarbon(target))
		var/mob/living/carbon/patient = target
		result += "Температура: [round(patient.bodytemperature - T0C, 0.1)] °C. Давление: [round(patient.medical_pressure)]."
		result += "Объём крови: [round(patient.get_blood_volume())]. Группа: [patient.get_bloodtype()?.name || "не определена"]."
		if(scanpower >= SCANPOWER_ADVANCED)
			if(HAS_TRAIT(patient, TRAIT_IRRADIATED))
				result += "Обнаружено радиоактивное заражение."
			for(var/datum/disease/disease as anything in patient.diseases)
				if(!(disease.visibility_flags & HIDDEN_SCANNER))
					result += "Инфекция: [disease.name], стадия [disease.stage]/[disease.max_stages]."
			for(var/obj/item/organ/organ as anything in patient.organs)
				if(organ.organ_flags & ORGAN_HIDDEN)
					continue
				if(organ.organ_flags & ORGAN_FAILING)
					result += "[organ.name]: признаки отказа."
				else if(organ.damage >= organ.high_threshold)
					result += "[organ.name]: признаки серьёзного повреждения."
	record_medical_event(target, user, "Портативное обследование", src)
	var/text = jointext(result, "<br>")
	if(tochat)
		to_chat(user, boxed_message(text))
	return text

/obj/item/healthanalyzer/wound
	name = "анализатор ранений"
	desc = "Специализированная диагностика ранений и подбор их лечения."
	icon_state = "health_adv"
	give_wound_treatment_bonus = TRUE

/obj/item/healthanalyzer/wound/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(user.can_read(src) && !user.is_blind())
		woundscan(user, interacting_with, src)
		if(iscarbon(interacting_with))
			var/mob/living/carbon/patient = interacting_with
			for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
				var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
				if(!condition)
					continue
				if(LAZYLEN(condition.minor_wounds))
					to_chat(user, span_notice("[limb.plaintext_zone]: мелкие ранения. Используйте обычные перевязочные материалы."))
				if(condition.infection_stage())
					to_chat(user, span_warning("[limb.plaintext_zone]: инфекция стадии [condition.infection_stage()]. [condition.infection_stage() == 4 ? "Нужна хирургическая обработка с синтплотью." : "Требуется антимикробное лечение."]"))
	return ITEM_INTERACT_SUCCESS

/obj/item/healthanalyzer/hemo
	name = "гемоанализатор"
	desc = "Анализ химических веществ в крови и содержимого желудка."
	icon_state = "health_adv"

/obj/item/healthanalyzer/hemo/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(user.can_read(src) && !user.is_blind())
		chemscan(user, interacting_with)
	return ITEM_INTERACT_SUCCESS
