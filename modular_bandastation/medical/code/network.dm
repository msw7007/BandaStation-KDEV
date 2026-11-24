GLOBAL_LIST_EMPTY(medical_events)

/// Text-only, bounded treatment journal shared by medical terminals.
/proc/record_medical_event(mob/living/patient, mob/living/author, action, atom/device)
	if(!patient)
		return
	var/turf/location = get_turf(patient)
	GLOB.medical_events += list(list("patient" = patient.real_name, "author" = author?.real_name || "автоматика", "action" = action, "device" = device?.name || "ручное вмешательство", "time" = round_timestamp(), "z" = location?.z))
	if(length(GLOB.medical_events) > 200)
		GLOB.medical_events.Cut(1, 2)
	var/datum/record/crew/record = find_record(patient.real_name)
	if(istype(record))
		if(length(record.medical_notes) >= 100)
			var/datum/medical_note/old_note = record.medical_notes[1]
			record.medical_notes.Cut(1, 2)
			qdel(old_note)
		record.medical_notes += new /datum/medical_note(author?.real_name || "автоматика", strip_html(action), round_timestamp())

/proc/medical_network_data(z_level)
	var/list/endpoints = list()
	for(var/obj/machinery/stasis/medical_station/station as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/stasis/medical_station))
		if(station.z == z_level && station.is_operational)
			endpoints += list(list("name" = station.name, "patient" = station.occupant?.name || "нет пациента", "status" = station.scanning ? "исследование" : (station.stasis_enabled ? "включена" : "ожидание")))
	for(var/obj/machinery/computer/operating/computer as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/operating))
		if(computer.z == z_level && computer.is_operational)
			endpoints += list(list("name" = computer.name, "patient" = computer.table?.patient?.name || computer.nerv_table?.occupant?.name || "нет пациента", "status" = (computer.table || computer.nerv_table) ? "стол подключён" : "нет стола"))
	var/list/events = list()
	for(var/list/event as anything in GLOB.medical_events)
		if(event["z"] == z_level)
			events += list(event)
	var/list/sensors = list()
	for(var/list/sensor as anything in GLOB.crewmonitor.update_data(z_level))
		if(!sensor["position"])
			continue
		var/status = sensor["life_status"] == DEAD ? "Мёртв" : (sensor["health"] < 0 ? "Критическое состояние" : (sensor["health"] < 80 ? "Ранен" : "Стабилен"))
		sensors += list(list("name" = sensor["name"], "status" = status))
	return list("endpoints" = endpoints, "events" = events, "sensors" = sensors)

/obj/machinery/computer/medical_network
	name = "врачебный терминал"
	desc = "Связывает операционные столы, диагностические установки, полевые сообщения и датчики экипажа."
	icon_screen = "crew"
	icon_keyboard = "med_key"
	req_access = list(ACCESS_MEDICAL)
	circuit = /obj/item/circuitboard/computer/medical_network
	var/next_sensor_update = 0

/obj/machinery/computer/medical_network/process()
	if(!is_operational || world.time < next_sensor_update)
		return
	next_sensor_update = world.time + 10 SECONDS
	update_medical_sensor_records()

/obj/machinery/computer/medical_network/proc/update_medical_sensor_records()
	for(var/list/sensor as anything in GLOB.crewmonitor.update_data(z))
		if(!sensor["position"])
			continue
		var/datum/record/crew/record = find_record(sensor["name"])
		if(istype(record))
			record.physical_status = sensor["life_status"] == DEAD ? PHYSICAL_DECEASED : (sensor["health"] < 0 ? PHYSICAL_UNCONSCIOUS : (sensor["health"] < 80 ? PHYSICAL_DEBILITATED : PHYSICAL_ACTIVE))

/obj/machinery/computer/medical_network/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(!allowed(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedicalNetwork", name)
		ui.open()

/obj/machinery/computer/medical_network/ui_data(mob/user)
	return allowed(user) ? medical_network_data(z) : list()

/obj/machinery/computer/medical_network/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "records" && allowed(usr))
		update_medical_sensor_records()
		return TRUE
	return FALSE

/obj/item/circuitboard/computer/medical_network
	name = "Врачебный терминал (Computer Board)"
	build_path = /obj/machinery/computer/medical_network

/obj/item/medical_terminal
	name = "терминал парамедика"
	desc = "Полевые сообщения о состоянии пациентов в медицинскую сеть. Примените к пациенту для записи осмотра."
	icon = 'icons/obj/devices/scanner.dmi'
	icon_state = "health_adv"
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NOBLUDGEON

/obj/item/medical_terminal/attack_self(mob/user)
	ui_interact(user)

/obj/item/medical_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MedicalNetwork", name)
		ui.open()

/obj/item/medical_terminal/ui_data(mob/user)
	var/turf/location = get_turf(src)
	return medical_network_data(location?.z)

/obj/item/medical_terminal/attack(mob/living/patient, mob/living/user)
	if(user.combat_mode || !user.has_medical_competence())
		return
	if(!do_after(user, 3 SECONDS, patient) || QDELETED(patient) || !user.Adjacent(patient))
		return
	record_medical_event(patient, user, "Полевой осмотр: [patient.stat == DEAD ? "нет признаков жизни" : "жив"], жизнеспособность [round(patient.health)].", src)
	balloon_alert(user, "осмотр записан")

/obj/machinery/stasis/medical_station/self_analyzer
	name = "медицинский самоанализатор"
	desc = "Исследование пациента с передачей выявленных отклонений в медицинский радиоканал."
	circuit = /obj/item/circuitboard/machine/medical_station/self_analyzer
	var/obj/item/radio/medical_radio

/obj/machinery/stasis/medical_station/self_analyzer/Initialize(mapload)
	. = ..()
	medical_radio = new(src)
	medical_radio.keyslot = new /obj/item/encryptionkey/headset_med
	medical_radio.recalculateChannels()
	medical_radio.set_listening(FALSE)

/obj/machinery/stasis/medical_station/self_analyzer/Destroy()
	QDEL_NULL(medical_radio)
	return ..()

/obj/machinery/stasis/medical_station/self_analyzer/run_medical_scan(mob/living/user)
	var/previous_time = report_time
	. = ..()
	var/mob/living/carbon/patient = report_patient?.resolve()
	if(previous_time == report_time || !patient)
		return
	var/abnormal = patient.health < patient.maxHealth || patient.medical_pressure < 70 || patient.medical_pressure > 135 || LAZYLEN(patient.diseases)
	for(var/obj/item/organ/organ as anything in patient.organs)
		if(organ.damage > 0 || organ.maxHealth < initial(organ.maxHealth))
			abnormal = TRUE
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
		if(LAZYLEN(limb.wounds) || condition?.infection_seconds || LAZYLEN(condition?.minor_wounds))
			abnormal = TRUE
	if(abnormal)
		medical_radio.talk_into(src, "Самоанализатор: [report_name], выявлены отклонения. Жизнеспособность [round(patient.health)], давление [round(patient.medical_pressure)]. Требуется осмотр врача.", RADIO_CHANNEL_MEDICAL)

/obj/item/circuitboard/machine/medical_station/self_analyzer
	name = "Самоанализатор (Machine Board)"
	build_path = /obj/machinery/stasis/medical_station/self_analyzer
