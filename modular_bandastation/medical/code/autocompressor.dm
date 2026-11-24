/obj/item/clothing/suit/autocompressor
	name = "автокомпрессор"
	desc = "Автоматические компрессии, сердечная поддержка и дыхание из сменного баллона."
	icon = 'modular_bandastation/medical/icons/medical_suits.dmi'
	worn_icon = 'modular_bandastation/medical/icons/medical_suits.dmi'
	icon_state = "pumper"
	inhand_icon_state = "pumper"
	var/obj/item/stock_parts/power_store/cell/cell
	var/obj/item/tank/internals/tank
	var/mob/living/carbon/patient
	var/enabled = FALSE
	var/compression_seconds = 0

/obj/item/clothing/suit/autocompressor/Initialize(mapload)
	. = ..()
	cell = new(src)

/obj/item/clothing/suit/autocompressor/Destroy()
	stop_support()
	QDEL_NULL(cell)
	QDEL_NULL(tank)
	return ..()

/obj/item/clothing/suit/autocompressor/equipped(mob/living/user, slot)
	. = ..()
	stop_support()
	if(slot == ITEM_SLOT_OCLOTHING && iscarbon(user))
		patient = user
		if(enabled)
			start_support()

/obj/item/clothing/suit/autocompressor/dropped(mob/user)
	stop_support()
	patient = null
	return ..()

/obj/item/clothing/suit/autocompressor/attack_self(mob/user)
	enabled = !enabled
	if(enabled)
		start_support()
	else
		stop_support()
	balloon_alert(user, enabled ? "включён" : "выключен")

/obj/item/clothing/suit/autocompressor/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/tank/internals) || istype(tool, /obj/item/stock_parts/power_store/cell))
		if(enabled)
			balloon_alert(user, "сначала выключите")
			return ITEM_INTERACT_BLOCKING
		if(!user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_BLOCKING
		if(istype(tool, /obj/item/tank/internals))
			tank?.forceMove(drop_location())
			tank = tool
		else
			cell?.forceMove(drop_location())
			cell = tool
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/clothing/suit/autocompressor/examine(mob/user)
	. = ..()
	. += span_notice("[enabled ? "Включён" : "Выключен"]. Заряд: [cell ? round(cell.percent()) : 0]%. Баллон: [tank || "не установлен"].")

/obj/item/clothing/suit/autocompressor/proc/start_support()
	if(!patient || patient.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src || !enabled || !cell?.charge)
		return
	ADD_TRAIT(patient, TRAIT_CARDIAC_SUPPORT, REF(src))
	RegisterSignal(patient, COMSIG_CARBON_ATTEMPT_BREATHE, PROC_REF(supply_breath), override = TRUE)
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/autocompressor/proc/stop_support()
	STOP_PROCESSING(SSobj, src)
	compression_seconds = 0
	if(patient)
		REMOVE_TRAIT(patient, TRAIT_CARDIAC_SUPPORT, REF(src))
		UnregisterSignal(patient, COMSIG_CARBON_ATTEMPT_BREATHE)

/obj/item/clothing/suit/autocompressor/process(seconds_per_tick)
	if(!enabled || !patient || patient.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src || !cell?.use(5 * seconds_per_tick))
		stop_support()
		return PROCESS_KILL
	compression_seconds += seconds_per_tick
	if(compression_seconds >= 7)
		compression_seconds %= 7
		patient.apply_medical_cpr(trained = TRUE)

/obj/item/clothing/suit/autocompressor/proc/supply_breath(mob/living/carbon/source, seconds_per_tick)
	SIGNAL_HANDLER
	if(!enabled || !cell?.charge || !tank || source.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src || HAS_TRAIT(source, TRAIT_NOBREATH))
		return
	INVOKE_ASYNC(src, PROC_REF(deliver_breath), source)
	return COMSIG_CARBON_BLOCK_BREATH

/obj/item/clothing/suit/autocompressor/proc/deliver_breath(mob/living/carbon/source)
	if(!enabled || !cell?.charge || !tank || patient != source || source.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src)
		return
	var/datum/gas_mixture/breath = tank.remove_air_volume(BREATH_VOLUME)
	source.check_breath(breath)
	if(breath)
		var/turf/location = get_turf(source)
		location?.assume_air(breath)
	return COMSIG_CARBON_BLOCK_BREATH
