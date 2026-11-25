//CYBERPUNK BUSINESS - subsystem-facing business registry and delivery factory.
/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_business(business_id)
	return cyberpunk_businesses["[business_id]"]
/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_business_key(mob/living/person, datum/bank_account/account)
	return SSeconomy.get_cyberpunk_contract_character_key(person, account)

/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_businesses_for_user(mob/living/user)
	var/list/businesses = list()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(business?.can_view(user))
			businesses += business
	return businesses

/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_business_warehouse_options(datum/cyberpunk_business/requester)
	var/list/options = list()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(!business || business == requester || !business.warehouse_enabled)
			continue
		options += list(list(
			"id" = business.id,
			"name" = business.name,
			"label" = "#[business.id] [business.name]",
			"stock" = length(business.warehouse_stock),
			"canBuy" = requester ? requester.allows_warehouse_partner(business, TRUE) : TRUE,
			"canSell" = requester ? business.allows_warehouse_partner(requester, FALSE) : TRUE,
		))
	return options

/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_public_business_registry()
	var/list/entries = list()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(!business || !business.legal)
			continue
		entries += list(list(
			"id" = business.id,
			"name" = business.name,
			"direction" = business.direction,
			"registeredTo" = business.registered_to,
			"owner" = business.owner_name,
			"area" = business.get_business_area()?.name || "unlisted",
			"taxDebt" = business.tax_debt,
			"taxPaid" = business.tax_paid,
			"taxRate" = round(SScyberpunk_corporations.get_cyberpunk_business_tax_rate(business.id) * 100),
			"status" = business.tax_debt > 0 ? "tax overdue" : "registered",
		))
	return entries

/datum/controller/subsystem/cyberpunk_property/proc/find_cyberpunk_business_supplier(datum/cyberpunk_business/requester, item_label, amount, source_label, required_type)
	item_label = reject_bad_text(item_label, max_length = 64, ascii_only = FALSE)
	if(!requester || !item_label)
		return null
	amount = max(1, round(amount))
	var/source_key = lowertext("[source_label]")
	if(source_key == "external supplier")
		return null
	var/datum/cyberpunk_business/best_supplier
	var/best_price = INFINITY
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/supplier = cyberpunk_businesses[business_id]
		if(!supplier || supplier == requester || !supplier.warehouse_enabled || !supplier.warehouse_valid || !supplier.validate_unload_zone() || !supplier.get_account())
			continue
		if(length(requester.warehouse_buy_links) && !requester.allows_warehouse_partner(supplier, TRUE))
			continue
		if(length(supplier.warehouse_sell_links) && !supplier.allows_warehouse_partner(requester, FALSE))
			continue
		if(source_key && source_key != "auto")
			if(source_key != lowertext("[supplier.id]") && source_key != lowertext(supplier.name))
				continue
		if(supplier.get_sellable_stock_amount(item_label, required_type) < amount)
			continue
		var/unit_price = supplier.get_stock_price(item_label, requester)
		if(unit_price < best_price)
			best_price = unit_price
			best_supplier = supplier
	return best_supplier

/datum/controller/subsystem/cyberpunk_property/proc/create_cyberpunk_business(mob/living/owner, obj/machinery/computer/business_terminal/terminal, list/params)
	if(!owner || !terminal)
		return null
	if(!owner.has_neural_implant())
		return null
	var/area/business_area = get_area(terminal)
	var/is_legal = text2num(params["legal"]) ? TRUE : FALSE
	if(is_legal && !cyberpunk_is_business_area(business_area))
		return null
	if(!business_area)
		return null
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/existing_business = cyberpunk_businesses[business_id]
		if(existing_business?.legal && is_legal && existing_business.get_business_area() == business_area)
			return null
	var/datum/bank_account/owner_account = owner.get_bank_account()
	var/name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE)
	if(!name)
		name = "[owner.real_name || owner.name]'s business"
	var/datum/bank_account/business_account = new /datum/bank_account("[name] account", null, 1, TRUE)
	var/datum/cyberpunk_business/business = new
	business.id = next_cyberpunk_business_id++
	business.name = name
	business.direction = reject_bad_text(params["direction"], max_length = 64, ascii_only = FALSE) || "general trade"
	business.legal = is_legal
	business.registered_to = reject_bad_text(params["registered_to"], max_length = 48, ascii_only = FALSE) || (is_legal ? "city" : "off-ledger")
	business.size_class = is_legal ? "17x17" : "off-ledger"
	business.owner_ckey = owner.ckey
	business.owner_name = owner.real_name || owner.name
	business.owner_character_key = get_cyberpunk_business_key(owner, owner_account)
	business.account_id = business_account.account_id
	business.terminal = terminal
	business.business_area_type = business_area.type
	business.hydrate_from_persistent(owner)
	business.add_history("created by [business.owner_name] at [business_area.name]")
	cyberpunk_businesses["[business.id]"] = business
	terminal.business_id = business.id
	business.apply_generated_access(owner)
	business.validate_premises(owner)
	return business
/// Public off-map suppliers trade standard civilian hardware and consumables.
/proc/cyberpunk_external_trade_catalog()
	var/static/list/catalog
	if(!catalog)
		catalog = list()
		for(var/obj/item/product as anything in list(
			/obj/item/stack/sheet/iron,
			/obj/item/stack/sheet/glass,
			/obj/item/stack/sheet/plastic,
			/obj/item/stack/cable_coil,
			/obj/item/stack/medical/bruise_pack,
			/obj/item/stack/medical/wrap/gauze,
			/obj/item/screwdriver,
			/obj/item/wrench,
			/obj/item/crowbar,
			/obj/item/wirecutters,
			/obj/item/multitool,
		))
			catalog[lowertext(initial(product.name))] = product
	return catalog

/proc/cyberpunk_external_trade_price(item_type)
	return get_cyberpunk_sale_price_for_type(item_type, "vendor", default_price = CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST)

/datum/controller/subsystem/cyberpunk_property/proc/create_cyberpunk_business_delivery(datum/cyberpunk_business/business, item_label, amount, source_label = "external supplier", destination_label = "business warehouse", required_type)
	if(!business)
		return null
	item_label = reject_bad_text(item_label, max_length = 64, ascii_only = FALSE)
	if(!item_label)
		return null
	if(!isnum(amount) || amount < 1 || amount > 1000 || amount != round(amount))
		return null
	var/datum/cyberpunk_business/supplier = find_cyberpunk_business_supplier(business, item_label, amount, source_label, required_type)
	var/source_key = lowertext(source_label || "auto")
	var/obj/item/external_type
	if(!supplier)
		if(!business.legal || !(source_key in list("auto", "external supplier")) || (source_key == "auto" && length(business.warehouse_buy_links)))
			return null
		var/list/catalog = cyberpunk_external_trade_catalog()
		external_type = catalog[lowertext(item_label)]
		if(!external_type || (required_type && required_type != external_type))
			return null
		item_label = initial(external_type.name)
		var/stock_key = business.get_stock_key(item_label)
		var/existing_type = business.warehouse_item_types[stock_key]
		if(existing_type && existing_type != "[external_type]")
			return null
	var/atom/delivery_destination = business.get_unload_zone()
	var/atom/delivery_source = supplier?.get_unload_zone()
	if(!business.validate_unload_zone() || !get_turf(delivery_destination) || (supplier && !get_turf(delivery_source)))
		return null

	var/unit_cost = supplier ? supplier.get_stock_price(item_label, business) : cyberpunk_external_trade_price(external_type)
	var/total_cost = max(0, round(unit_cost * amount))
	var/list/stock_packet
	if(supplier)
		var/stock_key = supplier.get_stock_key(item_label)
		var/legacy_type = text2path(supplier.warehouse_item_types[stock_key])
		stock_packet = supplier.take_stock(item_label, amount, required_type, allow_abstract = ispath(legacy_type, /obj/item))
		if(stock_packet?["amount"] != amount)
			if(stock_packet)
				supplier.receive_stock(item_label, stock_packet)
			return null
	else
		stock_packet = list("amount" = amount, "legacy_type" = "[external_type]")
	if(total_cost && !business.charge(total_cost, "Business delivery #[next_cyberpunk_business_delivery_id]: [amount]x [item_label]"))
		if(supplier)
			supplier.receive_stock(item_label, stock_packet)
		return null
	if(supplier)
		supplier.record_income(total_cost, "Business supply sale to [business.name]: [amount]x [item_label]")
	var/datum/cyberpunk_business_delivery/delivery = new
	delivery.id = next_cyberpunk_business_delivery_id++
	delivery.business_id = business.id
	delivery.source_business_id = supplier?.id || 0
	delivery.item_label = item_label
	delivery.amount = amount
	delivery.required_type = required_type || external_type
	delivery.stock_packet = stock_packet
	delivery.source_label = supplier ? supplier.name : "Внешний рынок"
	delivery.destination_label = reject_bad_text(destination_label, max_length = 48, ascii_only = FALSE) || "business warehouse"
	delivery.cost = total_cost
	delivery.created_at = world.time
	delivery.arrival_time = world.time + 2 MINUTES
	cyberpunk_business_deliveries["[delivery.id]"] = delivery
	business.deliveries += delivery
	business.add_history("delivery #[delivery.id] requested: [amount]x [item_label] from [delivery.source_label]; cost [total_cost][MONEY_SYMBOL]")
	if(supplier)
		delivery.begin_warehouse_delivery(delivery_source, delivery_destination)
		supplier.add_history("Поставка #[delivery.id] подготовлена для [business.name].")
	else
		delivery.ai_courier_status = "АВИ внешнего поставщика в пути"
		addtimer(CALLBACK(delivery, TYPE_PROC_REF(/datum/cyberpunk_business_delivery, complete_delivery)), 2 MINUTES)
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "market", max(1, round(amount / 2)), max(0, round(total_cost * 0.03)), "business delivery #[delivery.id]")
	if(SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_cargo_tracking"))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", 1, 0, "cargo tracking: delivery #[delivery.id]")
	if(SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_log_observation"))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", max(1, round(amount / 4)), 0, "log observation: delivery #[delivery.id]")
	return delivery
