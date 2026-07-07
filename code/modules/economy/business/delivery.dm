//CYBERPUNK BUSINESS - warehouse delivery records.
/datum/cyberpunk_business_delivery
	var/id = 0
	var/business_id = 0
	var/item_label = "goods"
	var/amount = 1
	var/source_label = "external supplier"
	var/source_business_id = 0
	var/destination_label = "business warehouse"
	var/cost = 0
	var/status = "enroute"
	var/created_at = 0
	var/arrival_time = 0
	var/ai_dispatched = FALSE
	var/ai_courier_status = "not requested"
	var/list/flight_markers = list()

/obj/effect/cyberpunk_business_delivery_marker
	name = "business delivery flight marker"
	desc = "A temporary logistics beacon marking an active business delivery flight."
	icon = 'icons/obj/structures.dmi'
	icon_state = "rack"
	anchored = TRUE
	density = FALSE
	alpha = 160
	var/delivery_id = 0

/obj/effect/cyberpunk_business_delivery_marker/Initialize(mapload, new_delivery_id = 0, marker_label = null)
	. = ..()
	delivery_id = new_delivery_id
	if(marker_label)
		name = marker_label
	addtimer(CALLBACK(src, PROC_REF(fade_out)), 2 MINUTES, TIMER_STOPPABLE)

/obj/effect/cyberpunk_business_delivery_marker/proc/fade_out()
	qdel(src)

/datum/cyberpunk_business_delivery/proc/complete_delivery()
	if(status != "enroute")
		return FALSE
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
	if(!business)
		return FALSE
	status = "completed"
	business.add_stock(item_label, amount)
	business.add_history("delivery #[id] arrived: [amount]x [item_label]; cost [cost][MONEY_SYMBOL]")
	var/atom/arrival_point = business.get_unload_zone() || business.terminal
	var/atom/movable/arrival_speaker = arrival_point
	if(istype(arrival_speaker))
		arrival_speaker.say("Delivery #[id] arrived: [amount]x [item_label].")
	QDEL_LIST(flight_markers)
	return TRUE

/datum/cyberpunk_business_delivery/proc/create_flight_visual(atom/source, atom/target)
	var/turf/source_turf = get_turf(source)
	var/turf/target_turf = get_turf(target)
	if(source_turf)
		flight_markers += new /obj/effect/cyberpunk_business_delivery_marker(source_turf, id, "AVI departure marker #[id]")
	if(target_turf && target_turf != source_turf)
		flight_markers += new /obj/effect/cyberpunk_business_delivery_marker(target_turf, id, "AVI arrival marker #[id]")
	return length(flight_markers)

/datum/cyberpunk_business_delivery/proc/dispatch_ai_courier(atom/source, atom/target)
	if(ai_dispatched || status != "enroute" || !source || !target)
		return FALSE
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return FALSE
	create_flight_visual(source, target)
	var/obj/item/cyberpunk_business_delivery_crate/crate = new(source_turf)
	crate.delivery_id = id
	crate.name = "[item_label] delivery crate"
	crate.desc = "A sealed business delivery crate containing [amount]x [item_label]."
	if(!cyberpunk_request_ai_delivery(source, target, crate, null, source, CP_AI_CAP_HANDS))
		qdel(crate)
		ai_courier_status = "no courier available"
		return FALSE
	ai_dispatched = TRUE
	ai_courier_status = "courier dispatched"
	return TRUE

/datum/cyberpunk_business_delivery/proc/to_ui_data()
	return list(
		"id" = id,
		"item" = item_label,
		"amount" = amount,
		"source" = source_label,
		"destination" = destination_label,
		"cost" = cost,
		"status" = status,
		"aiCourierStatus" = ai_courier_status,
		"eta" = status == "enroute" && arrival_time > world.time ? DisplayTimeText(arrival_time - world.time) : "arrived",
	)
//CYBERPUNK BUILD - rebuild and delete before release

/obj/item/cyberpunk_business_delivery_crate
	name = "business delivery crate"
	desc = "A sealed crate routed through city business logistics."
	icon = 'icons/obj/storage/crates.dmi'
	icon_state = "crate"
	w_class = WEIGHT_CLASS_BULKY
	var/delivery_id = 0

/obj/item/cyberpunk_business_delivery_crate/proc/on_cyberpunk_ai_delivered(mob/living/courier)
	var/datum/cyberpunk_business_delivery/delivery = SScyberpunk_property.cyberpunk_business_deliveries["[delivery_id]"]
	if(!delivery)
		return FALSE
	if(delivery.complete_delivery())
		delivery.ai_courier_status = "delivered by [courier?.real_name || courier?.name || "city courier"]"
		qdel(src)
		return TRUE
	return FALSE
