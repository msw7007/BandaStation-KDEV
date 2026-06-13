//CYBERPUNK BUSINESS - vending integration.
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

/obj/machinery/vending/proc/cyberpunk_business_restock_from_warehouse()
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(cyberpunk_business_id)
	if(!business || !business.warehouse_enabled || !business.warehouse_valid)
		return 0
	var/restocked = 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records + hidden_records)
		var/stock_multiplier = get_cyberpunk_machine_vending_stock_multiplier()
		stock_multiplier *= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(get_cyberspace_manufacturer(src), list("benn_supply_cert", "ryaznov_supply_cert", "starlight_supply_cert"), 1, 1.15)
		var/target_maximum = max(1, round(record.max_amount * stock_multiplier))
		var/target_amount = cyberpunk_business_minimum_stock > 0 ? min(cyberpunk_business_minimum_stock, target_maximum) : target_maximum
		var/needed = target_amount - record.amount
		if(needed <= 0)
			continue
		var/taken = business.consume_stock(record.name, needed)
		if(taken < needed)
			taken += business.consume_stock("[record.product_path]", needed - taken)
		if(taken < needed)
			taken += business.consume_stock("goods", needed - taken)
		if(!taken)
			continue
		record.amount += taken
		restocked += taken
	if(restocked)
		business.add_history("[name] restocked [restocked] item(s) from warehouse")
