/// Shared by hanging drips and bags: changing UI mode cannot override actual activity.
/mob/living/carbon/proc/medical_infusion_unsafe()
	return body_position != LYING_DOWN || combat_mode || world.time < medical_combat_until

/mob/living/carbon
	var/medical_combat_until = 0

/datum/component/medical_activity
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/medical_activity/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/medical_activity/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_FIRED_GUN, PROC_REF(fired))
	RegisterSignal(parent, COMSIG_LIVING_ATTACK_ATOM, PROC_REF(attacked))
	RegisterSignal(parent, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(unarmed))

/datum/component/medical_activity/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_FIRED_GUN, COMSIG_LIVING_ATTACK_ATOM, COMSIG_LIVING_UNARMED_ATTACK))

/datum/component/medical_activity/proc/fired()
	SIGNAL_HANDLER
	mark_activity()

/datum/component/medical_activity/proc/attacked(datum/source, atom/target)
	SIGNAL_HANDLER
	if(isliving(target) && target != parent)
		mark_activity()

/datum/component/medical_activity/proc/unarmed(mob/living/carbon/source, atom/target)
	SIGNAL_HANDLER
	if(source.combat_mode && isliving(target))
		mark_activity()

/datum/component/medical_activity/proc/mark_activity()
	var/mob/living/carbon/patient = parent
	patient.medical_combat_until = world.time + 10 SECONDS
	patient.medical_adrenaline_until = world.time + 10 SECONDS
	patient.medical_activity = min(45, patient.medical_activity + 5)

/obj/item/reagent_containers/blood
	var/datum/weakref/medical_patient
	var/medical_draw = FALSE
	var/medical_flow = 1
	var/medical_sealed = TRUE
	var/medical_needle_zone = BODY_ZONE_L_ARM
	var/datum/beam/medical_tube

/obj/item/reagent_containers/blood/Destroy()
	medical_disconnect()
	return ..()

/obj/item/reagent_containers/blood/examine(mob/user)
	. = ..()
	. += span_notice("[medical_sealed ? "Пакет герметичен" : "Пакет открыт"]. Расход: [medical_flow] ед./с. Режим: [medical_draw ? "забор крови" : "введение"]. Используйте в руке для настройки; примените к пациенту для подключения.")
	if(medical_patient?.resolve())
		. += span_notice("Игла подключена. Пакет должен оставаться рядом на поверхности.")

/obj/item/reagent_containers/blood/attack_self(mob/user)
	var/action = tgui_input_list(user, "Настройка пакета", name, list("Подключение / снять иглу", "Введение / забор", "Расход", "Герметизация"))
	if(QDELETED(src) || !user.can_perform_action(src, NEED_DEXTERITY))
		return
	switch(action)
		if("Подключение / снять иглу")
			medical_disconnect()
		if("Введение / забор")
			medical_draw = !medical_draw
		if("Расход")
			var/flow = tgui_input_number(user, "Единиц в секунду (0–5)", name, medical_flow, 5, 0)
			if(!isnull(flow) && !QDELETED(src) && user.can_perform_action(src, NEED_DEXTERITY))
				medical_flow = clamp(flow, 0, 5)
		if("Герметизация")
			medical_sealed = !medical_sealed
	update_appearance()

/obj/item/reagent_containers/blood/attack(mob/living/target, mob/living/user)
	if(!iscarbon(target) || user.combat_mode)
		return ..()
	if(medical_patient?.resolve())
		medical_disconnect()
		return
	var/mob/living/carbon/patient = target
	var/zone = check_zone(user.zone_selected)
	var/obj/item/bodypart/limb = patient.get_bodypart(zone)
	if(!limb || !IS_ORGANIC_LIMB(limb) || !patient.can_inject(user, TRUE, zone))
		return
	if(!do_after(user, 2 SECONDS, patient) || QDELETED(src) || QDELETED(limb) || limb.owner != patient || !user.Adjacent(patient) || medical_patient?.resolve())
		return
	if(loc == user && !user.dropItemToGround(src))
		return
	if(!isturf(loc) || get_dist(src, patient) > 1)
		return
	medical_sealed = FALSE
	medical_patient = WEAKREF(patient)
	medical_needle_zone = zone
	limb.receive_damage(1, sharpness = SHARP_POINTY, wound_bonus = CANT_WOUND)
	limb.get_medical_condition().add_minor(WOUND_PIERCE)
	medical_tube = Beam(patient, icon_state = "1-full", beam_color = COLOR_SILVER)
	START_PROCESSING(SSobj, src)
	log_combat(user, patient, "connected infusion bag", src, reagents.get_reagent_log_string())
	update_appearance()

/obj/item/reagent_containers/blood/proc/medical_disconnect(ripped = FALSE)
	var/mob/living/carbon/patient = medical_patient?.resolve()
	if(ripped && patient)
		var/obj/item/bodypart/limb = patient.get_bodypart(medical_needle_zone)
		limb?.receive_damage(3, sharpness = SHARP_POINTY, wound_bonus = CANT_WOUND)
		if(limb)
			limb.get_medical_condition().add_minor(WOUND_PIERCE)
	STOP_PROCESSING(SSobj, src)
	medical_patient = null
	QDEL_NULL(medical_tube)
	update_appearance()

/obj/item/reagent_containers/blood/process(seconds_per_tick)
	var/mob/living/carbon/patient = medical_patient?.resolve()
	if(!patient || get_dist(src, patient) > 1 || !isturf(loc) || !isturf(patient.loc))
		medical_disconnect(ripped = TRUE)
		return PROCESS_KILL
	if(patient.medical_infusion_unsafe())
		medical_draw = TRUE
	if(medical_sealed || medical_flow <= 0)
		return
	var/amount = medical_flow * seconds_per_tick * patient.medical_time_scale()
	if(medical_draw)
		amount = min(amount, reagents.maximum_volume - reagents.total_volume)
		if(amount > 0)
			patient.transfer_blood_to(src, amount)
	else if(reagents.total_volume)
		reagents.trans_to(patient, amount, methods = INJECT, show_message = FALSE)
	update_appearance()

/obj/item/reagent_containers/blood/update_overlays()
	. = ..()
	if(medical_patient?.resolve())
		var/mutable_appearance/needle = mutable_appearance('icons/obj/medical/syringe.dmi', "syringe_0")
		needle.pixel_x = 6
		. += needle
