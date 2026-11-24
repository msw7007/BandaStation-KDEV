/// Stationary equipment shares the existing medical bed's buckling and construction lifecycle.
/obj/machinery/stasis/medical_station
	name = "стационарная диагностическая установка"
	desc = "Полный медицинский анализ пациента. Запуск исследования вручную, длительность — 10 секунд."
	stasis_enabled = FALSE
	circuit = /obj/item/circuitboard/machine/medical_station
	req_access = list(ACCESS_MEDICAL)
	var/station_mode = "diagnostic"
	var/scanning = FALSE
	var/report_html
	var/report_name
	var/report_time
	var/report_author
	var/datum/weakref/report_patient
	var/malfunction_until = 0
	var/mob/living/supported_patient

/obj/machinery/stasis/medical_station/Initialize(mapload)
	. = ..()
	create_reagents(100, OPENCONTAINER)

/obj/machinery/stasis/medical_station/Destroy()
	clear_medical_support()
	return ..()

/obj/machinery/stasis/medical_station/chill_out(mob/living/target)
	return

/obj/machinery/stasis/medical_station/thaw_them(mob/living/target)
	clear_medical_support()

/obj/machinery/stasis/medical_station/process(seconds_per_tick)
	if(!is_operational || !stasis_enabled || !isliving(occupant))
		clear_medical_support()
		update_use_power(IDLE_POWER_USE)
		return
	if(supported_patient != occupant)
		clear_medical_support()
		supported_patient = occupant
	if(station_mode == "nerv")
		supported_patient.apply_status_effect(/datum/status_effect/grouped/medical_anesthesia, REF(src))
		update_use_power(ACTIVE_POWER_USE)
	else if(station_mode == "cryostasis")
		var/datum/reagent/cryostylane/fuel = reagents.has_reagent(/datum/reagent/cryostylane)
		if(!fuel || fuel.volume < 0.05 * seconds_per_tick / (SSmachines.wait / (1 SECONDS)))
			clear_medical_support()
			update_use_power(IDLE_POWER_USE)
			return
		var/factor = clamp(0.25 - 0.24 * fuel.purity, 0.01, 0.25)
		supported_patient.apply_status_effect(/datum/status_effect/grouped/medical_stasis/chamber, REF(src))
		var/datum/status_effect/grouped/medical_stasis/chamber/status = supported_patient.has_status_effect(/datum/status_effect/grouped/medical_stasis/chamber)
		status.time_factor = factor
		LAZYSET(supported_patient.medical_time_factors, REF(status), factor)
		reagents.remove_reagent(/datum/reagent/cryostylane, 0.05 * seconds_per_tick / (SSmachines.wait / (1 SECONDS)))
		update_use_power(ACTIVE_POWER_USE)

/obj/machinery/stasis/medical_station/proc/clear_medical_support()
	if(supported_patient)
		supported_patient.remove_status_effect(/datum/status_effect/grouped/medical_anesthesia, REF(src))
		supported_patient.remove_status_effect(/datum/status_effect/grouped/medical_stasis/chamber, REF(src))
	supported_patient = null

/obj/machinery/stasis/medical_station/on_set_is_operational(old_value)
	. = ..()
	if(!is_operational)
		clear_medical_support()

/obj/machinery/stasis/medical_station/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedicalStation", name)
		ui.open()

/obj/machinery/stasis/medical_station/ui_data(mob/user)
	return list(
		"mode" = station_mode,
		"enabled" = stasis_enabled,
		"patient" = occupant?.name,
		"scanning" = scanning,
		"report" = report_html ? html_decode(strip_html(replacetext(report_html, "<br>", "\n"), 30000)) : null,
		"reportName" = report_name,
		"reportTime" = report_time,
		"fuel" = reagents.get_reagent_amount(/datum/reagent/cryostylane),
	)

/obj/machinery/stasis/medical_station/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			stasis_enabled = !stasis_enabled
			if(!stasis_enabled)
				clear_medical_support()
			update_appearance()
			return TRUE
		if("eject")
			if(isliving(occupant))
				unbuckle_mob(occupant, force = TRUE)
			return TRUE
		if("scan")
			if(station_mode != "diagnostic" || scanning || !iscarbon(occupant))
				return FALSE
			INVOKE_ASYNC(src, PROC_REF(run_medical_scan), usr)
			return TRUE
		if("print")
			if(!report_html)
				return FALSE
			var/obj/item/paper/report = new(drop_location())
			report.name = "Медицинский отчёт — [report_name]"
			report.add_raw_text("<b>[html_encode(report_name)] — [report_time]</b><br>[report_html]", advanced_html = TRUE)
			return TRUE
		if("record")
			var/datum/record/crew/record = find_record(report_name)
			if(!report_html || !istype(record) || !allowed(usr))
				return FALSE
			record.medical_notes += new /datum/medical_note(report_author, "СДУ, [report_time]: [strip_html(report_html, 8000)]", round_timestamp())
			return TRUE
	return FALSE

/obj/machinery/stasis/medical_station/proc/valid_scan(mob/living/carbon/patient)
	return !QDELETED(patient) && occupant == patient && patient.buckled == src && is_operational

/obj/machinery/stasis/medical_station/proc/run_medical_scan(mob/living/user)
	if(scanning || !iscarbon(occupant) || !is_operational)
		return
	var/mob/living/carbon/patient = occupant
	scanning = TRUE
	if(!do_after(user, (obj_flags & EMAGGED) ? 15 SECONDS : 10 SECONDS, src, extra_checks = CALLBACK(src, PROC_REF(valid_scan), patient)))
		scanning = FALSE
		return
	scanning = FALSE
	if(!valid_scan(patient))
		return
	if(obj_flags & EMAGGED)
		var/obj/item/bodypart/head = patient.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			head.get_medical_condition().add_pain(80)
		patient.Unconscious(10 SECONDS)
		log_combat(user, patient, "used sabotaged diagnostic station", src)
	report_html = healthscan(user, patient, SCANNER_VERBOSE, SCANPOWER_SUPER, tochat = FALSE)
	report_html += "<hr>[medical_condition_report(patient)]"
	if(world.time < malfunction_until)
		report_html += "<br>Внимание: обнаружены признаки тяжёлой интоксикации и аритмии."
	report_name = patient.real_name
	report_time = round_timestamp()
	report_author = user.real_name
	report_patient = WEAKREF(patient)
	record_medical_event(patient, user, "Стационарная диагностика", src)
	SStgui.update_uis(src)

/obj/machinery/stasis/medical_station/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_SELF))
		malfunction_until = world.time + 1 MINUTES

/obj/machinery/stasis/medical_station/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	return TRUE

/proc/medical_condition_report(mob/living/carbon/patient)
	var/temperature_center = patient.get_body_temp_normal() + patient.medical_adaptation - T0C
	var/temperature_range = patient.medical_comfort_range()
	var/list/result = list("Давление: [round(patient.medical_pressure)]. Иммунитет: [round(patient.medical_immunity)]%. Температурная зона комфорта: [round(temperature_center - temperature_range, 0.1)] — [round(temperature_center + temperature_range, 0.1)] °C.")
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
		if(!condition)
			continue
		result += "[limb.plaintext_zone]: боль [round(condition.pain)], загрязнение [round(condition.contamination)]/100, инфекция [condition.infection_stage()]/4."
		if(condition.infection_stage() == 4)
			result += "Некроз: хирургическое удаление с синтплотью; для головы и груди также возможно криолечение."
	for(var/obj/item/organ/organ as anything in patient.organs)
		var/datum/component/medical_condition/condition = organ.get_medical_condition(FALSE)
		if(condition?.organ_bleeding)
			result += "[organ.name]: органное кровотечение, требуется хирургическое восстановление."
	return jointext(result, "<br>")

/obj/machinery/stasis/medical_station/nerv
	name = "нейрологический стол N.E.R.V."
	desc = "Нейронное подавление чувствительности для хирургической анестезии."
	station_mode = "nerv"
	circuit = /obj/item/circuitboard/machine/medical_station/nerv
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 10
	icon = 'modular_bandastation/medical/icons/operation_table_v3.dmi'
	icon_state = "table2-idle"
	base_icon_state = "table2-idle"
	mattress_state = null
	var/obj/machinery/computer/operating/computer

/obj/machinery/stasis/medical_station/nerv/Initialize(mapload)
	. = ..()
	for(var/direction in GLOB.alldirs)
		var/obj/machinery/computer/operating/candidate = locate() in get_step(src, direction)
		if(candidate && !candidate.table && !candidate.nerv_table)
			candidate.find_table()
			if(computer)
				break

/obj/machinery/stasis/medical_station/nerv/Destroy()
	if(computer?.nerv_table == src)
		computer.nerv_table = null
	computer = null
	return ..()

/obj/machinery/stasis/medical_station/nerv/post_buckle_mob(mob/living/patient)
	. = ..()
	if(occupant != patient)
		return
	RegisterSignal(patient, COMSIG_ATOM_BEING_OPERATED_ON, PROC_REF(get_surgeries))
	RegisterSignals(patient, list(COMSIG_ATOM_SURGERY_FINISHED, COMSIG_LIVING_UPDATING_SURGERY_STATE), PROC_REF(surgery_changed))
	computer?.update_static_data_for_all_viewers()

/obj/machinery/stasis/medical_station/nerv/post_unbuckle_mob(mob/living/patient)
	UnregisterSignal(patient, list(COMSIG_ATOM_BEING_OPERATED_ON, COMSIG_ATOM_SURGERY_FINISHED, COMSIG_LIVING_UPDATING_SURGERY_STATE))
	. = ..()
	computer?.update_static_data_for_all_viewers()

/obj/machinery/stasis/medical_station/nerv/proc/get_surgeries(datum/source, mob/living/surgeon, list/operations)
	SIGNAL_HANDLER
	if(computer?.is_operational)
		operations |= computer.advanced_surgeries

/obj/machinery/stasis/medical_station/nerv/proc/surgery_changed(datum/source)
	SIGNAL_HANDLER
	computer?.update_static_data_batched()

/obj/machinery/stasis/medical_station/nerv/update_icon_state()
	. = ..()
	icon_state = (is_operational && stasis_enabled && occupant) ? "table2-active" : "table2-idle"

/obj/machinery/stasis/medical_station/cryostasis
	name = "камера криостазиса"
	desc = "Замедляет биологические процессы до 99%. Требует криостилан; чистота определяет эффективность."
	station_mode = "cryostasis"
	circuit = /obj/item/circuitboard/machine/medical_station/cryostasis
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 15

/datum/status_effect/grouped/medical_stasis/chamber
	id = "medical_cryostasis_chamber"
	time_factor = 0.01

/datum/status_effect/grouped/medical_anesthesia
	id = "medical_anesthesia"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/grouped/medical_anesthesia/on_apply()
	owner.add_traits(list(TRAIT_MEDICAL_ANESTHESIA, TRAIT_ANALGESIA, TRAIT_KNOCKEDOUT), REF(src))
	return TRUE

/datum/status_effect/grouped/medical_anesthesia/on_remove()
	owner.remove_traits(list(TRAIT_MEDICAL_ANESTHESIA, TRAIT_ANALGESIA, TRAIT_KNOCKEDOUT), REF(src))
	owner.adjust_confusion(5 SECONDS)
	return ..()

/obj/item/circuitboard/machine/medical_station
	name = "СДУ (Machine Board)"
	build_path = /obj/machinery/stasis/medical_station
	req_components = list(/datum/stock_part/scanning_module = 2, /datum/stock_part/capacitor = 1, /obj/item/stack/sheet/glass = 2)

/obj/item/circuitboard/machine/medical_station/nerv
	name = "N.E.R.V. (Machine Board)"
	build_path = /obj/machinery/stasis/medical_station/nerv
	req_components = list(/datum/stock_part/scanning_module = 3, /datum/stock_part/capacitor = 3, /obj/item/stack/sheet/mineral/diamond = 2, /obj/item/stack/sheet/bluespace_crystal = 1)

/obj/item/circuitboard/machine/medical_station/cryostasis
	name = "Криостазис (Machine Board)"
	build_path = /obj/machinery/stasis/medical_station/cryostasis
	req_components = list(/datum/stock_part/micro_laser = 2, /datum/stock_part/capacitor = 2, /obj/item/stack/sheet/glass = 4)
