//CYBERPUNK CORPORATIONS - Starlight service completion.
/datum/cyberpunk_corporation
	var/list/starlight_shipments = list()

/datum/cyberpunk_corporation/Destroy()
	for(var/key in starlight_shipments)
		var/list/records = starlight_shipments[key]
		QDEL_LIST(records)
	starlight_shipments = null
	return ..()

/// Only queued orders process; live tracking reads weak references when the buyer opens the UI.
/datum/cyberpunk_starlight_shipment
	var/datum/weakref/cargo_ref
	var/datum/weakref/customer_ref
	var/datum/weakref/source_ref
	var/datum/weakref/beacon_ref
	var/datum/weakref/corporation_ref
	var/owner_key
	var/cargo_name
	var/status = "tracking"
	var/turf/destination
	var/turf/pickup_turf
	var/priority_delivery = FALSE
	var/created_at
	var/next_dispatch_at = 0
	var/persistent_tracking = FALSE
	var/datum/weakref/ordered_product_ref
	var/datum/weakref/payer_ref
	var/reserved_payment = 0

/datum/cyberpunk_starlight_shipment/Destroy()
	STOP_PROCESSING(SSobj, src)
	refund_reservation()
	cargo_ref = null
	customer_ref = null
	source_ref = null
	beacon_ref = null
	corporation_ref = null
	destination = null
	pickup_turf = null
	return ..()

/datum/cyberpunk_starlight_shipment/proc/refund_reservation()
	var/datum/bank_account/payer = payer_ref?.resolve()
	if(reserved_payment)
		payer?.adjust_money(reserved_payment, "Возврат за заказ Старлайта")
	reserved_payment = 0
	payer_ref = null

/datum/cyberpunk_starlight_shipment/proc/finish(success)
	if(status == "received" || status == "failed" || status == "delivered")
		return
	status = success ? "delivered" : "failed"
	refund_reservation()
	STOP_PROCESSING(SSobj, src)
	var/mob/customer = customer_ref?.resolve()
	if(customer)
		to_chat(customer, span_notice("Starlight: [cargo_name] - [status]."))

/datum/cyberpunk_starlight_shipment/process(seconds_per_tick)
	if(!(status in list("queued", "awaiting stock")))
		return PROCESS_KILL
	if(world.time < next_dispatch_at)
		return
	next_dispatch_at = world.time + (priority_delivery ? 5 SECONDS : 10 SECONDS)
	var/obj/machinery/source = source_ref?.resolve()
	var/mob/living/customer = customer_ref?.resolve()
	var/obj/item/cyberpunk_delivery_beacon/beacon = beacon_ref?.resolve()
	var/datum/cyberpunk_corporation/corporation = corporation_ref?.resolve()
	var/turf/pickup = pickup_turf || get_turf(source)
	if(!source || !corporation || world.time > created_at + 10 MINUTES)
		finish(FALSE)
		return
	if(!source.is_operational)
		return
	var/turf/dropoff = get_turf(customer)
	if(beacon?.active && beacon.owner_key == owner_key && isturf(beacon.loc))
		dropoff = get_turf(beacon)
	if(!dropoff || !is_station_level(dropoff.z) || isspaceturf(dropoff) || is_area_virtual(get_area(dropoff)))
		return
	if(dropoff.is_blocked_turf(exclude_mobs = TRUE))
		for(var/direction in GLOB.cardinals)
			var/turf/nearby = get_step(dropoff, direction)
			if(isopenturf(nearby) && !isspaceturf(nearby) && !nearby.is_blocked_turf(exclude_mobs = TRUE))
				dropoff = nearby
				break
		if(dropoff.is_blocked_turf(exclude_mobs = TRUE))
			return
	corporation.update_agent_pool()
	if(!corporation.service_auto_enabled || corporation.agents_available <= 0)
		return
	if(status == "awaiting stock")
		var/obj/machinery/vending/vendor = source
		var/datum/data/vending_product/product = ordered_product_ref?.resolve()
		if(!istype(vendor) || !(product in vendor.product_records) || vendor.get_cyberpunk_supply_corporation() != corporation)
			finish(FALSE)
			return
		if(product.amount <= LAZYLEN(product.returned_products))
			vendor.schedule_cyberpunk_preorder_supply(product)
			return
		var/obj/item/ordered_item = vendor.dispense(product, pickup, silent = TRUE)
		if(!ordered_item)
			return
		cargo_ref = WEAKREF(ordered_item)
		ordered_product_ref = null
		corporation.add_funds(reserved_payment, "Заказ с доставкой: [product.name]")
		reserved_payment = 0
		payer_ref = null
		status = "queued"
	var/atom/movable/cargo = cargo_ref?.resolve()
	// A stolen or moved parcel is not available to the queue, even if its reference survives.
	if(!cargo || cargo.loc != pickup || cargo.anchored)
		finish(FALSE)
		return
	destination = dropoff
	var/obj/vehicle/ridden/cyberpunk/avi/courier = new(pickup)
	courier.cyberpunk_route_corporation_id = CYBERPUNK_CORP_STARLIGHT
	courier.cyberpunk_priority_delivery = priority_delivery
	if(!courier.start_cyberpunk_avi_delivery(pickup, destination, list(cargo)))
		qdel(courier)
		finish(FALSE)
		return
	if(!corporation.dispatch_agent("queued beacon delivery", 5 MINUTES))
		qdel(courier)
		return
	courier.track_starlight_shipment(src, dropoff)
	STOP_PROCESSING(SSobj, src)

/obj/vehicle/ridden/cyberpunk
	var/list/cargo_tracking_refs

/obj/vehicle/ridden/cyberpunk/proc/track_starlight_shipment(datum/cyberpunk_starlight_shipment/shipment, turf/dropoff)
	LAZYADD(cargo_tracking_refs, WEAKREF(shipment))
	shipment.status = "in transit"
	shipment.destination = dropoff

/obj/vehicle/ridden/cyberpunk/proc/track_starlight_delivery(mob/living/customer, list/cargo_atoms, turf/dropoff)
	if(!customer)
		return
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(CYBERPUNK_CORP_STARLIGHT)
	if(!corporation?.has_edict("starlight_log_observation"))
		return
	for(var/atom/movable/cargo as anything in cargo_atoms)
		if(QDELETED(cargo))
			continue
		var/datum/cyberpunk_starlight_shipment/shipment = corporation.register_starlight_tracking(customer, cargo)
		if(shipment)
			track_starlight_shipment(shipment, dropoff)

/obj/vehicle/ridden/cyberpunk/proc/finish_starlight_delivery(list/delivered_cargo)
	for(var/datum/weakref/shipment_ref as anything in cargo_tracking_refs)
		var/datum/cyberpunk_starlight_shipment/shipment = shipment_ref.resolve()
		if(shipment?.status == "in transit")
			var/atom/movable/cargo = shipment.cargo_ref?.resolve()
			shipment.finish(cargo && (cargo in delivered_cargo))
	cargo_tracking_refs = null

/datum/cyberpunk_corporation/proc/register_starlight_tracking(mob/living/customer, atom/movable/cargo, order_name)
	if(id != CYBERPUNK_CORP_STARLIGHT || !customer || (!cargo && !order_name))
		return null
	var/key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	if(!key)
		return null
	var/list/records = starlight_shipments[key]
	if(!records)
		records = list()
		starlight_shipments[key] = records
	for(var/datum/cyberpunk_starlight_shipment/existing as anything in records.Copy())
		if(cargo && existing.cargo_ref?.resolve() == cargo && !(existing.status in list("received", "failed")))
			return existing
		if(existing.status in list("received", "failed"))
			records -= existing
			qdel(existing)
	if(length(records) >= 32)
		return null
	var/datum/cyberpunk_starlight_shipment/shipment = new
	if(cargo)
		shipment.cargo_ref = WEAKREF(cargo)
	shipment.customer_ref = WEAKREF(customer)
	shipment.corporation_ref = WEAKREF(src)
	shipment.owner_key = key
	shipment.cargo_name = cargo?.name || order_name
	shipment.created_at = world.time
	records += shipment
	return shipment

/datum/cyberpunk_corporation/proc/get_starlight_tracking_ui(mob/living/customer)
	var/list/result = list()
	if(id != CYBERPUNK_CORP_STARLIGHT || !istype(customer))
		return result
	var/key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	for(var/datum/cyberpunk_starlight_shipment/shipment as anything in starlight_shipments[key])
		var/atom/movable/cargo = shipment.cargo_ref?.resolve()
		if(!cargo && shipment.status != "awaiting stock")
			shipment.finish(FALSE)
		else if(cargo && !shipment.persistent_tracking && customer.contains(cargo))
			shipment.status = "received"
		var/turf/position = shipment.status != "received" && has_edict("starlight_log_observation") ? get_turf(cargo) : null
		result += list(list("ref" = REF(shipment), "name" = shipment.cargo_name, "status" = shipment.status, "position" = position ? "[position.x], [position.y], [position.z]" : "-", "canClear" = !(shipment.status in list("awaiting stock", "queued", "in transit"))))
	return result

/datum/cyberpunk_corporation/proc/clear_starlight_tracking(mob/living/customer, shipment_ref)
	if(id != CYBERPUNK_CORP_STARLIGHT || !istype(customer))
		return FALSE
	var/key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	var/list/records = starlight_shipments[key]
	for(var/datum/cyberpunk_starlight_shipment/shipment as anything in records)
		if(REF(shipment) != shipment_ref || (shipment.status in list("awaiting stock", "queued", "in transit")))
			continue
		records -= shipment
		qdel(shipment)
		return TRUE
	return FALSE

/obj/machinery/vending/proc/attach_starlight_tracking(mob/living/customer)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_supply_corporation()
	if(corporation?.id != CYBERPUNK_CORP_STARLIGHT || !corporation.has_edict("starlight_log_observation") || !corporation.is_subscribed(customer) || !is_operational || !Adjacent(customer) || customer.incapacitated)
		return FALSE
	var/list/choices = list()
	for(var/obj/target in range(1, customer))
		if(target != src && !(target.flags_1 & HOLOGRAM_1))
			choices["[target.name] ([REF(target)])"] = target
	var/obj/item/held = customer.get_active_held_item()
	if(held)
		choices["Held: [held.name]"] = held
	var/selection = tgui_input_list(customer, "Attach a cargo tracker.", name, choices)
	var/obj/target = choices[selection]
	if(QDELETED(target) || QDELETED(customer) || !Adjacent(customer) || !is_operational || customer.incapacitated || !corporation.has_edict("starlight_log_observation") || !corporation.is_subscribed(customer))
		return FALSE
	if(target != customer.get_active_held_item() && (!isturf(target.loc) || target.z != customer.z || get_dist(target, customer) > 1 || !target.IsReachableBy(customer)))
		return FALSE
	var/datum/cyberpunk_starlight_shipment/tracker = corporation.register_starlight_tracking(customer, target)
	if(!tracker)
		return FALSE
	tracker.persistent_tracking = TRUE
	to_chat(customer, span_notice("Starlight tracking attached to [target]."))
	return TRUE

/obj/item/flashlight/starlight_beacon
	name = "Starlight Beacon lamp"
	desc = "A compact Starlight courier lamp with route-marker firmware."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 116
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 125

/obj/item/radio/starlight_burst
	name = "Starlight Burst radio"
	desc = "A Starlight-branded radio for short logistics confirmations."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 115
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 150

/obj/item/multitool/starlight_pathfinder
	name = "Starlight Pathfinder multitool"
	desc = "A Starlight routing multitool used by premium courier crews."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 122
	cyberpunk_rarity = "rare"
	cyberpunk_base_price = 260

/obj/item/crowbar/starlight_quickjack
	name = "Starlight Quickjack"
	desc = "A lightweight courier crowbar sold as a route recovery tool."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 114
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 120

/proc/cyberpunk_prepare_starlight_package(obj/item/storage/box/package, subscribed = FALSE)
	if(!package)
		return FALSE
	new /obj/item/flashlight/starlight_beacon(package)
	new /obj/item/radio/starlight_burst(package)
	new /obj/item/crowbar/starlight_quickjack(package)
	new /obj/item/stack/sheet/glass(package)
	if(subscribed)
		new /obj/item/multitool/starlight_pathfinder(package)
		new /obj/item/stack/sheet/iron/five(package)
	return TRUE

/proc/cyberpunk_complete_starlight_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	cyberpunk_spawn_service_agent(corporation_id, service_id, user, corporation?.get_service_label(service_id))
	switch(service_id)
		if("delivery")
			return corporation?.request_starlight_route_service(user, service_id)
		if("return")
			var/obj/item/held_item = user.get_active_held_item()
			if(!cyberpunk_starlight_return_eligible(held_item))
				to_chat(user, span_warning("Starlight return program needs an active held item."))
				return FALSE
			var/return_value = max(1, round(held_item.get_cyberpunk_price(user) * (corporation?.is_subscribed(user) ? 0.6 : 0.4)))
			var/datum/bank_account/user_account = user.get_bank_account()
			if(!user_account || !user.temporarilyRemoveItemFromInventory(held_item))
				return FALSE
			user_account.adjust_money(return_value, "Starlight return program")
			qdel(held_item)
			to_chat(user, span_notice("Starlight return program credits [return_value][MONEY_SYMBOL]."))
		if("transport")
			return corporation?.request_starlight_route_service(user, service_id)
		if("influence")
			user.adjust_stamina_loss(-35)
			user.add_mood_event("starlight_influence", /datum/mood_event/starlight_influence)
			to_chat(user, span_notice("Starlight influence pulse stabilizes your tempo."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "market", 2, 0, "Starlight service completed: [service_id]")
	return TRUE

/proc/cyberpunk_starlight_return_eligible(obj/item/item)
	return item && !(item.item_flags & ABSTRACT) && !item.cyberpunk_contract_id && SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(item)) != CYBERPUNK_CORP_STARLIGHT

/datum/cyberpunk_corporation/proc/request_starlight_route_service(mob/living/user, service_id)
	if(id != CYBERPUNK_CORP_STARLIGHT || !can_request_service(service_id) || !user || !service_auto_enabled)
		return FALSE
	if(service_id == "transport" && !has_edict("starlight_log_help") && !is_subscribed(user))
		return FALSE
	var/turf/pickup = get_turf(user)
	var/atom/movable/cargo = service_id == "transport" ? user : user.get_active_held_item()
	if(!pickup || !is_station_level(pickup.z) || !cargo || cargo.anchored || user.buckled)
		return FALSE
	var/list/modes = list("Coordinates")
	if(is_subscribed(user) || has_edict("starlight_trade_analysis"))
		modes += "My beacon"
	var/mode = tgui_input_list(user, "Delivery destination.", name, modes)
	var/turf/destination
	if(mode == "My beacon")
		var/list/beacons = list()
		var/character_key = SSeconomy.get_cyberpunk_contract_character_key(user, user.get_bank_account())
		for(var/obj/item/cyberpunk_delivery_beacon/beacon as anything in GLOB.cyberpunk_starlight_beacons)
			if(beacon.owner_key == character_key && beacon.active && isturf(beacon.loc))
				beacons["[beacon.name] ([beacon.x],[beacon.y],[beacon.z])"] = beacon
		var/choice = tgui_input_list(user, "Active destination beacon.", name, beacons)
		var/obj/item/cyberpunk_delivery_beacon/beacon = beacons[choice]
		destination = get_turf(beacon)
	else if(mode == "Coordinates")
		var/target_x = tgui_input_number(user, "Destination X.", name, pickup.x, world.maxx, 1)
		var/target_y = tgui_input_number(user, "Destination Y.", name, pickup.y, world.maxy, 1)
		var/target_z = tgui_input_number(user, "Destination Z.", name, pickup.z, world.maxz, 1)
		if(!target_x || !target_y || !target_z)
			return FALSE
		destination = locate(round(target_x), round(target_y), round(target_z))
	if(!destination || !is_station_level(destination.z) || isspaceturf(destination) || destination.is_blocked_turf(source_atom = user))
		return FALSE
	var/cost = cyberpunk_starlight_delivery_cost("avi", list(cargo))
	if(tgui_alert(user, "Request transport to [destination.x],[destination.y],[destination.z] for [cost][MONEY_SYMBOL]?", name, list("Yes", "No")) != "Yes")
		return FALSE
	if(QDELETED(user) || QDELETED(cargo) || get_turf(user) != pickup || !can_request_service(service_id) || !service_auto_enabled || user.buckled)
		return FALSE
	if(service_id == "delivery")
		if(user.get_active_held_item() != cargo || !user.transferItemToLoc(cargo, pickup))
			return FALSE
	if(!cyberpunk_request_starlight_delivery(user, pickup, destination, list(cargo)))
		if(isitem(cargo))
			user.put_in_hands(cargo)
		return FALSE
	add_history("[user.real_name] requested [service_id] to [destination.x],[destination.y],[destination.z]")
	return TRUE

/datum/mood_event/starlight_influence
	description = "Starlight's feed is keeping my pace tuned."
	mood_change = 2
	timeout = 3 MINUTES
