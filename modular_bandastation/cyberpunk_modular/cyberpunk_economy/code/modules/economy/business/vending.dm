//CYBERPUNK BUSINESS - vending integration.
/obj/machinery/vending/tool/cyberpunk_business
	name = "business supplies vendor"
	desc = "A paid supplies vendor ready to link to the local business warehouse."
	payment_department = NO_FREEBIES
	default_price = 100
	all_products_free = FALSE
	refill_canister = null
	cyberpunk_sale_rotation_enabled = FALSE
	products = list(
		/obj/item/wrench = 4,
		/obj/item/crowbar = 4,
		/obj/item/stack/cable_coil = 4,
	)
	contraband = null
	premium = null

/obj/machinery/vending/tool/cyberpunk_business/Initialize(mapload)
	. = ..()
	var/datum/cyberpunk_machine_module/business_vending_bus/bus = new
	if(!install_cyberpunk_module(bus, null))
		qdel(bus)
	for(var/datum/data/vending_product/product as anything in product_records)
		product.amount = 0

/obj/machinery/vending
	var/cyberpunk_business_auto_restock = FALSE
	var/cyberpunk_business_markup_percent = 0
	var/cyberpunk_business_minimum_stock = 0
	var/datum/weakref/cyberpunk_refill_in_progress
	cyberpunk_public_access = TRUE

/obj/machinery/vending/proc/has_business_vending_module()
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		if(istype(module, /datum/cyberpunk_machine_module/business_vending_bus))
			return TRUE
	return FALSE

/obj/machinery/vending/proc/cyberpunk_business_record_sale(amount, product_label)
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	if(!business)
		return FALSE
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	var/business_share = max(0, amount - round(amount * VENDING_CREDITS_COLLECTION_AMOUNT))
	if(!business_share)
		return FALSE
	return business.record_income(business_share, "Business vendor sale at [name]: [product_label]")

/obj/machinery/vending/proc/get_cyberpunk_business_vending_price(base_price, item_label)
	base_price = max(0, round(base_price))
	if(!cyberpunk_business_id)
		if(!cyberpunk_corporate_markup_percent || !has_corporate_vending_module())
			return base_price
		return max(0, round(base_price * (100 + cyberpunk_corporate_markup_percent) / 100))
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	if(!business)
		return base_price
	var/configured_price = business.warehouse_prices[lowertext("[item_label]")]
	if(isnum(configured_price))
		return configured_price
	var/markup = clamp(round(cyberpunk_business_markup_percent), -100, 500)
	return max(0, round(base_price * (100 + markup) / 100))

/obj/machinery/vending/proc/cyberpunk_business_restock_from_warehouse(list/shortages)
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	var/datum/cyberpunk_business_delivery/active_refill = cyberpunk_refill_in_progress?.resolve()
	if(active_refill?.status == "enroute" || !business || !business.warehouse_enabled || !business.warehouse_valid)
		return 0
	var/obj/structure/cyberpunk_business_unload_zone/source = business.get_unload_zone()
	if(!source || !business.validate_unload_zone())
		return 0
	var/area/business_area = business.get_business_area()
	var/turf/landing
	for(var/direction in GLOB.cardinals)
		var/turf/candidate = get_step(src, direction)
		if(!candidate || get_area(candidate) != business_area || isspaceturf(candidate) || candidate.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(!landing || get_dist(source, candidate) < get_dist(source, landing))
			landing = candidate
	if(!landing)
		return 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records + hidden_records)
		var/stock_multiplier = get_cyberpunk_machine_vending_stock_multiplier()
		stock_multiplier *= get_cyberpunk_corporate_stock_multiplier()
		var/target_maximum = max(1, CEILING(record.max_amount * stock_multiplier, 1))
		var/target_amount = cyberpunk_business_minimum_stock > 0 ? min(cyberpunk_business_minimum_stock, target_maximum) : target_maximum
		var/needed = target_amount - record.amount
		if(needed <= 0)
			continue
		var/taken = 0
		var/list/physical_lots = list()
		// Match by type so renamed items retain their individual properties.
		for(var/stock_key in business.warehouse_stock.Copy())
			if(!length(business.warehouse_items[stock_key]))
				continue
			var/list/packet = business.take_stock(stock_key, needed - taken, record.product_path, allow_abstract = FALSE)
			if(!packet)
				continue
			physical_lots += packet["items"]
			taken += packet["amount"]
			if(taken >= needed)
				break
		if(taken < needed)
			taken += business.consume_fungible_stock(record.name, needed - taken, record.product_path)
		if(taken < needed && record.name != "[record.product_path]")
			taken += business.consume_fungible_stock("[record.product_path]", needed - taken, record.product_path)
		if(taken < needed)
			taken += business.consume_fungible_stock("goods", needed - taken, record.product_path)
		if(shortages && taken < needed && record.product_path)
			shortages[record.product_path] = (shortages[record.product_path] || 0) + needed - taken
		if(!taken)
			continue

		var/datum/cyberpunk_business_delivery/refill = new
		refill.id = SScyberpunk_property.next_cyberpunk_business_delivery_id++
		refill.business_id = business.id
		refill.source_business_id = business.id
		refill.item_label = record.name
		refill.required_type = record.product_path
		refill.amount = taken
		refill.source_label = business.name
		refill.destination_label = name
		refill.created_at = world.time
		refill.stock_packet = list("amount" = taken, "items" = physical_lots, "legacy_type" = "[record.product_path]")
		refill.vending_product_ref = WEAKREF(record)
		SScyberpunk_property.cyberpunk_business_deliveries["[refill.id]"] = refill
		business.deliveries += refill
		cyberpunk_refill_in_progress = WEAKREF(refill)
		refill.begin_warehouse_delivery(source, src, landing)
		return taken
	return 0

/obj/machinery/vending/proc/receive_cyberpunk_business_refill(datum/cyberpunk_business/business, datum/data/vending_product/product, list/packet)
	if(QDELETED(product) || !packet || business.id != cyberpunk_business_id || !has_business_vending_module())
		return FALSE
	if(!(product in product_records) && !(product in coin_records) && !(product in hidden_records))
		return FALSE
	if(LAZYLEN(packet["items"]))
		product.cyberpunk_warehouse_items = (product.cyberpunk_warehouse_items || list()) + packet["items"]
	product.amount += packet["amount"]
	update_appearance()
	return TRUE

/obj/machinery/vending/proc/dispense_cyberpunk_warehouse_item(datum/data/vending_product/record, atom/location)
	var/list/lots = record.cyberpunk_warehouse_items
	if(!length(lots))
		return null
	var/list/lot = lots[1]
	var/units = lot["vending_bundle"] ? 1 : (lot["stack_amount"] || 1)
	var/list/entry = lot.Copy()
	if(lot["stack_amount"] && !lot["vending_bundle"])
		entry["stack_amount"] = 1
	var/turf/drop_turf = get_turf(location)
	var/obj/item/restored = cyberpunk_persistent_restore_movable(entry, location, null, drop_turf, null)
	if(!restored)
		return null
	var/list/remaining = lots.Copy(2)
	if(units > 1)
		var/list/remainder = lot.Copy()
		remainder["stack_amount"] = units - 1
		remaining.Insert(1, remainder)
	record.cyberpunk_warehouse_items = remaining
	return restored

/obj/machinery/vending/proc/eject_cyberpunk_warehouse_stock()
	var/turf/drop_turf = get_turf(src)
	for(var/datum/data/vending_product/record as anything in product_records + coin_records + hidden_records)
		for(var/list/lot as anything in record.cyberpunk_warehouse_items)
			if(cyberpunk_persistent_restore_movable(lot, drop_turf, null, drop_turf, null))
				record.amount -= lot["vending_bundle"] ? 1 : (lot["stack_amount"] || 1)
		record.cyberpunk_warehouse_items = null
