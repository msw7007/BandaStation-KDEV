// Physical warehouse shipments are credited only when the original crate reaches its unload point.
/datum/cyberpunk_business_delivery
	var/id = 0
	var/business_id = 0
	var/item_label = "goods"
	var/required_type
	var/amount = 1
	var/list/stock_packet
	var/source_label = "external supplier"
	var/source_business_id = 0
	var/destination_label = "business warehouse"
	var/cost = 0
	var/status = "enroute"
	var/created_at = 0
	var/arrival_time = 0
	var/ai_courier_status = "not requested"
	var/datum/weakref/crate_ref
	var/datum/weakref/destination_ref
	var/datum/weakref/vending_product_ref

/obj/effect/cyberpunk_business_delivery_marker
	name = "АВИ грузовой службы"
	desc = "Грузовой АВИ выполняет манёвр на площадке."
	icon = 'icons/obj/exploration.dmi'
	icon_state = "drone"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/obj/effect/cyberpunk_business_delivery_marker/Initialize(mapload, arriving = FALSE)
	. = ..()
	if(arriving)
		pixel_y = 64
		alpha = 30
	animate(src, pixel_y = arriving ? 0 : 64, alpha = arriving ? 255 : 0, time = 1.5 SECONDS)
	QDEL_IN(src, 2 SECONDS)

/datum/cyberpunk_business_delivery/proc/begin_warehouse_delivery(atom/source, atom/destination, turf/vending_landing)
	var/turf/loading_turf = get_turf(source)
	var/obj/item/cyberpunk_business_delivery_crate/crate = new(loading_turf)
	crate.delivery_id = id
	crate.name = "грузовой ящик #[id]"
	crate.desc = "Опломбированный груз. Содержимое: [amount] × [item_label]. Получатель: [destination_label]."
	crate_ref = WEAKREF(crate)
	destination_ref = WEAKREF(destination)
	arrival_time = world.time + 5 MINUTES
	addtimer(CALLBACK(src, PROC_REF(expire_warehouse_delivery)), 5 MINUTES)
	var/obj/vehicle/ridden/cyberpunk/avi/warehouse/courier
	if(vending_landing)
		courier = new /obj/vehicle/ridden/cyberpunk/avi/warehouse/vending(loading_turf)
	else
		courier = new(get_turf(destination))
	courier.business_delivery_ref = WEAKREF(src)
	if(!courier.start_cyberpunk_avi_delivery(source, vending_landing || destination, list(crate)))
		qdel(courier)
		return
	ai_courier_status = vending_landing ? "дрон везёт запас" : "АВИ вылетел за грузом"

/obj/vehicle/ridden/cyberpunk/avi/warehouse
	name = "грузовой АВИ"
	var/datum/weakref/business_delivery_ref

/obj/vehicle/ridden/cyberpunk/avi/warehouse/vending
	name = "дрон пополнения автоматов"
	icon = 'icons/obj/exploration.dmi'
	icon_state = "drone"

/obj/vehicle/ridden/cyberpunk/avi/warehouse/vending/cyberpunk_avi_find_exit_turf(turf/origin)
	return null

/obj/vehicle/ridden/cyberpunk/avi/warehouse/attack_hand(mob/living/user, list/modifiers)
	balloon_alert(user, "грузовой автопилот")
	return TRUE

/obj/vehicle/ridden/cyberpunk/avi/warehouse/wrench_act_secondary(mob/living/user, obj/item/tool)
	balloon_alert(user, "сервисная панель заперта")
	return ITEM_INTERACT_BLOCKING

/obj/vehicle/ridden/cyberpunk/avi/warehouse/screwdriver_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "сервисная панель заперта")
	return ITEM_INTERACT_BLOCKING

/obj/vehicle/ridden/cyberpunk/avi/warehouse/cyberpunk_avi_load_cargo()
	. = ..()
	if(length(avi_cargo))
		animate(src, pixel_z = 12, time = 0.6 SECONDS)

/obj/vehicle/ridden/cyberpunk/avi/warehouse/cyberpunk_avi_unload_cargo()
	var/datum/cyberpunk_business_delivery/delivery = business_delivery_ref?.resolve()
	var/obj/item/cyberpunk_business_delivery_crate/crate = delivery?.crate_ref?.resolve()
	var/arrived_with_crate = crate?.loc == src
	. = ..()
	if(.)
		animate(src, pixel_z = 0, time = 0.6 SECONDS)
		if(arrived_with_crate)
			delivery.complete_delivery(crate)

/obj/vehicle/ridden/cyberpunk/avi/warehouse/Destroy(force)
	var/datum/cyberpunk_business_delivery/delivery = business_delivery_ref?.resolve()
	delivery?.fail_delivery("АВИ потерян или прервал маршрут")
	business_delivery_ref = null
	return ..()

/datum/cyberpunk_business_delivery/proc/expire_warehouse_delivery()
	fail_delivery("груз не прибыл на склад вовремя")

/datum/cyberpunk_business_delivery/proc/fail_delivery(reason)
	if(status != "enroute")
		return
	status = "failed"
	ai_courier_status = reason
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
	business?.add_history("Поставка #[id] сорвана: [reason]. Оплата не возвращена.")

/datum/cyberpunk_business_delivery/proc/complete_delivery(obj/item/cyberpunk_business_delivery_crate/crate)
	if(status != "enroute")
		return FALSE
	if(source_business_id && world.time >= arrival_time)
		expire_warehouse_delivery()
		return FALSE
	if(!source_business_id && world.time < arrival_time)
		return FALSE
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
	if(!business)
		return FALSE
	var/atom/arrival_point = business.get_unload_zone()
	if(vending_product_ref)
		arrival_point = destination_ref?.resolve()
	if(!arrival_point || !business.warehouse_enabled || !business.validate_unload_zone())
		if(!source_business_id)
			fail_delivery("склад не может принять груз")
		return FALSE
	if(source_business_id)
		if(QDELETED(crate) || crate != crate_ref?.resolve() || !stock_packet)
			return FALSE
		if(arrival_point != destination_ref?.resolve() || !get_turf(arrival_point) || !in_range(arrival_point, crate))
			return FALSE
		if(get_area(crate) != business.get_business_area() || get_area(arrival_point) != business.get_business_area())
			return FALSE
	if(vending_product_ref)
		var/obj/machinery/vending/vendor = arrival_point
		var/datum/data/vending_product/product = vending_product_ref.resolve()
		if(!vendor?.receive_cyberpunk_business_refill(business, product, stock_packet))
			return FALSE
	else if(!business.receive_stock(item_label, stock_packet))
		return FALSE
	stock_packet = null
	if(crate)
		crate.delivery_id = 0
	status = "completed"
	business.add_history("Поставка #[id] принята: [amount] × [item_label].")
	var/atom/movable/arrival_speaker = arrival_point
	if(istype(arrival_speaker))
		arrival_speaker.say("Поставка #[id] прибыла. [amount] × [item_label].")
	var/turf/landing_turf = get_turf(arrival_point)
	if(landing_turf && !source_business_id)
		new /obj/effect/cyberpunk_business_delivery_marker(landing_turf, arriving = TRUE)
	if(crate)
		qdel(crate)
	ai_courier_status = "доставлено"
	return TRUE

/datum/cyberpunk_business_delivery/proc/spill_cargo(turf/location)
	if(!location || !stock_packet)
		return
	var/list/packet = stock_packet
	stock_packet = null
	var/legacy_units = packet["amount"]
	for(var/list/entry as anything in packet["items"])
		legacy_units -= entry["stack_amount"] || 1
		cyberpunk_persistent_restore_movable(entry, location, null, location, null)
	var/item_type = text2path(packet["legacy_type"])
	if(legacy_units > 0 && ispath(item_type, /obj/item))
		if(ispath(item_type, /obj/item/stack))
			new item_type(location, legacy_units, FALSE)
		else
			for(var/i in 1 to legacy_units)
				new item_type(location)

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
		"eta" = status == "enroute" && arrival_time > world.time ? DisplayTimeText(arrival_time - world.time) : "—",
	)

/obj/item/cyberpunk_business_delivery_crate
	name = "грузовой ящик"
	desc = "Опломбированный складской груз."
	icon = 'icons/obj/storage/crates.dmi'
	icon_state = "crate"
	w_class = WEIGHT_CLASS_BULKY
	uses_integrity = TRUE
	max_integrity = 80
	var/delivery_id = 0

/obj/item/cyberpunk_business_delivery_crate/proc/get_delivery()
	return delivery_id ? SScyberpunk_property?.cyberpunk_business_deliveries?["[delivery_id]"] : null

/obj/item/cyberpunk_business_delivery_crate/attack_self(mob/user, modifiers)
	var/datum/cyberpunk_business_delivery/delivery = get_delivery()
	if(!delivery)
		return
	balloon_alert(user, "вскрываю пломбу…")
	if(!do_after(user, 3 SECONDS, target = src) || QDELETED(src) || !user.is_holding(src))
		return
	delivery.fail_delivery("пломба вскрыта")
	delivery.spill_cargo(get_turf(src))
	delivery_id = 0
	qdel(src)
	return TRUE

/obj/item/cyberpunk_business_delivery_crate/Destroy()
	var/datum/cyberpunk_business_delivery/delivery = get_delivery()
	if(delivery)
		delivery.fail_delivery("ящик повреждён или уничтожен")
		delivery.spill_cargo(get_turf(src))
	return ..()

/obj/item/cyberpunk_business_delivery_crate/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/datum/cyberpunk_business_delivery/delivery = get_delivery()
	if(!delivery || delivery.destination_ref?.resolve() != interacting_with)
		return NONE
	if(!delivery.complete_delivery(src))
		balloon_alert(user, "поставка не принята")
		return ITEM_INTERACT_BLOCKING
	return ITEM_INTERACT_SUCCESS
