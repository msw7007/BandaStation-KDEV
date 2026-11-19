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
		return base_price
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	if(!business)
		return base_price
	var/configured_price = business.warehouse_prices[lowertext("[item_label]")]
	if(isnum(configured_price))
		return configured_price
	var/markup = clamp(round(cyberpunk_business_markup_percent), -100, 500)
	return max(0, round(base_price * (100 + markup) / 100))

/obj/machinery/vending/proc/cyberpunk_business_restock_from_warehouse()
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	if(!business || !business.warehouse_enabled || !business.warehouse_valid)
		return 0
	var/restocked = 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records + hidden_records)
		var/stock_multiplier = get_cyberpunk_machine_vending_stock_multiplier()
		stock_multiplier *= get_cyberpunk_corporate_stock_multiplier()
		var/target_maximum = max(1, CEILING(record.max_amount * stock_multiplier, 1))
		var/target_amount = cyberpunk_business_minimum_stock > 0 ? min(cyberpunk_business_minimum_stock, target_maximum) : target_maximum
		var/needed = target_amount - record.amount
		if(needed <= 0)
			continue
		var/taken = 0
		// The display name may be translated, changed by the user, or shared by different item types.
		for(var/stock_key in business.warehouse_stock.Copy())
			if(!length(business.warehouse_items[stock_key]))
				continue
			var/list/packet = business.take_stock(stock_key, needed - taken, record.product_path, allow_abstract = FALSE)
			if(!packet)
				continue
			var/list/lots = packet["items"]
			record.cyberpunk_warehouse_items = (record.cyberpunk_warehouse_items || list()) + lots
			taken += packet["amount"]
			if(taken >= needed)
				break
		if(taken < needed)
			taken += business.consume_fungible_stock(record.name, needed - taken, record.product_path)
		if(taken < needed && record.name != "[record.product_path]")
			taken += business.consume_fungible_stock("[record.product_path]", needed - taken, record.product_path)
		if(taken < needed)
			taken += business.consume_fungible_stock("goods", needed - taken, record.product_path)
		record.amount += taken
		restocked += taken
	if(restocked)
		business.add_history("[name] restocked [restocked] item(s) from warehouse")
	return restocked

/obj/machinery/vending/proc/dispense_cyberpunk_warehouse_item(datum/data/vending_product/record, atom/location)
	var/list/lots = record.cyberpunk_warehouse_items
	if(!length(lots))
		return null
	var/list/lot = lots[1]
	var/units = lot["stack_amount"] || 1
	var/list/entry = lot.Copy()
	if(lot["stack_amount"])
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
				record.amount -= lot["stack_amount"] || 1
		record.cyberpunk_warehouse_items = null
