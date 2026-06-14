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

/datum/controller/subsystem/cyberpunk_property/proc/find_cyberpunk_business_supplier(datum/cyberpunk_business/requester, item_label, amount, source_label)
	item_label = reject_bad_text(item_label, max_length = 48, ascii_only = FALSE)
	if(!requester || !item_label)
		return null
	amount = max(1, round(amount))
	var/source_key = lowertext("[source_label]")
	var/datum/cyberpunk_business/best_supplier
	var/best_price = INFINITY
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/supplier = cyberpunk_businesses[business_id]
		if(!supplier || supplier == requester || !supplier.warehouse_enabled)
			continue
		if(length(requester.warehouse_buy_links) && !requester.allows_warehouse_partner(supplier, TRUE))
			continue
		if(length(supplier.warehouse_sell_links) && !supplier.allows_warehouse_partner(requester, FALSE))
			continue
		if(source_key && source_key != "external supplier" && source_key != "auto")
			if(source_key != lowertext("[supplier.id]") && source_key != lowertext(supplier.name))
				continue
		if(supplier.get_stock_amount(item_label) < amount)
			continue
		var/unit_price = supplier.get_stock_price(item_label)
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
	if(!istype(business_area, /area/station/service/business))
		return null
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/existing_business = cyberpunk_businesses[business_id]
		if(existing_business?.get_business_area() == business_area)
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
	business.legal = text2num(params["legal"]) ? TRUE : FALSE
	business.size_class = "17x17"
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
	return business
/datum/controller/subsystem/cyberpunk_property/proc/create_cyberpunk_business_delivery(datum/cyberpunk_business/business, item_label, amount, source_label = "external supplier", destination_label = "business warehouse")
	if(!business)
		return null
	item_label = reject_bad_text(item_label, max_length = 48, ascii_only = FALSE)
	if(!item_label)
		return null
	amount = clamp(round(amount), 1, 1000)
	var/datum/cyberpunk_business/supplier = find_cyberpunk_business_supplier(business, item_label, amount, source_label)
	var/unit_cost = supplier ? supplier.get_stock_price(item_label) : CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST
	var/total_cost = max(0, round(unit_cost * amount))
	if(total_cost && !business.charge(total_cost, "Business delivery #[next_cyberpunk_business_delivery_id]: [amount]x [item_label]"))
		return null
	if(supplier)
		var/supplied = supplier.consume_stock(item_label, amount)
		if(supplied < amount)
			return null
		supplier.record_income(total_cost, "Business supply sale to [business.name]: [amount]x [item_label]")
	var/datum/cyberpunk_business_delivery/delivery = new
	delivery.id = next_cyberpunk_business_delivery_id++
	delivery.business_id = business.id
	delivery.source_business_id = supplier?.id || 0
	delivery.item_label = item_label
	delivery.amount = amount
	delivery.source_label = supplier ? supplier.name : (reject_bad_text(source_label, max_length = 48, ascii_only = FALSE) || "external supplier")
	delivery.destination_label = reject_bad_text(destination_label, max_length = 48, ascii_only = FALSE) || "business warehouse"
	delivery.cost = total_cost
	delivery.created_at = world.time
	delivery.arrival_time = world.time + 2 MINUTES
	cyberpunk_business_deliveries["[delivery.id]"] = delivery
	business.deliveries += delivery
	business.add_history("delivery #[delivery.id] requested: [amount]x [item_label] from [delivery.source_label]; cost [total_cost][MONEY_SYMBOL]")
	if(supplier?.terminal && business.terminal)
		if(delivery.dispatch_ai_courier(supplier.terminal, business.terminal))
			business.add_history("delivery #[delivery.id] assigned to city courier from [supplier.name]")
			supplier.add_history("delivery #[delivery.id] courier pickup requested for [business.name]")
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "market", max(1, round(amount / 2)), max(0, round(total_cost * 0.03)), "business delivery #[delivery.id]")
	if(SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_cargo_tracking"))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", 1, 0, "cargo tracking: delivery #[delivery.id]")
	if(SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_log_observation"))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", max(1, round(amount / 4)), 0, "log observation: delivery #[delivery.id]")
	addtimer(CALLBACK(delivery, TYPE_PROC_REF(/datum/cyberpunk_business_delivery, complete_delivery)), 2 MINUTES, TIMER_STOPPABLE)
	return delivery
