//CYBERPUNK BUSINESS - business datum and warehouse logic.
/obj/structure/cyberpunk_business_unload_zone
	name = "business unload zone"
	desc = "A compact logistics beacon marking the center of a 3x3 business warehouse loading area."
	icon = 'icons/obj/structures.dmi'
	icon_state = "rack"
	anchored = TRUE
	density = FALSE
	var/business_id = 0
	var/business_name = "unlinked"

/obj/structure/cyberpunk_business_unload_zone/proc/bind_business(datum/cyberpunk_business/business)
	if(!business)
		return FALSE
	business_id = business.id
	business_name = business.name
	name = "[business.name] unload zone"
	return TRUE

/obj/structure/cyberpunk_business_unload_zone/examine(mob/user)
	. = ..()
	. += span_notice("This beacon marks a 3x3 unload area for [business_name]. Keep all nine tiles open and inside the business premises.")

/datum/cyberpunk_business
	var/id = 0
	var/name = "Business"
	var/direction = "general trade"
	var/legal = TRUE
	var/registered_to = "city"
	var/size_class = "small"
	var/owner_ckey
	var/owner_name
	var/owner_character_key
	var/account_id
	var/access_id
	var/obj/machinery/computer/business_terminal/terminal
	var/business_area_type
	var/list/employees = list()
	var/list/pending_employees = list()
	var/list/warehouse_stock = list()
	var/list/warehouse_item_types = list()
	var/warehouse_enabled = FALSE
	var/warehouse_auto_restock = FALSE
	var/warehouse_surplus_percent = 0
	var/warehouse_markup_percent = 0
	var/warehouse_unload_zone = "unset"
	var/warehouse_unload_zone_ref
	var/list/warehouse_buy_links = list()
	var/list/warehouse_sell_links = list()
	var/last_auto_restock_at = 0
	var/premises_valid = FALSE
	var/premises_validation = "not checked"
	var/warehouse_valid = FALSE
	var/warehouse_validation = "not checked"
	var/unload_zone_valid = FALSE
	var/tax_debt = 0
	var/tax_paid = 0
	var/list/datum/cyberpunk_business_delivery/deliveries = list()
	var/list/saved_snapshot = list()
	var/saved_at = 0
	var/loaded_this_round = FALSE
	var/last_payroll_at = 0
	var/list/history = list()

/datum/cyberpunk_business/proc/get_account()
	RETURN_TYPE(/datum/bank_account)
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/datum/cyberpunk_business/proc/find_employee_account(employee_key)
	RETURN_TYPE(/datum/bank_account)
	employee_key = ckey(employee_key)
	if(!employee_key)
		return null
	for(var/account_id in SSeconomy.bank_accounts_by_id)
		var/datum/bank_account/account = SSeconomy.bank_accounts_by_id[account_id]
		if(account && ckey(account.account_holder) == employee_key)
			return account
	return null

/datum/cyberpunk_business/proc/user_key(mob/living/user)
	return SScyberpunk_property.get_cyberpunk_business_key(user, user?.get_bank_account())

/datum/cyberpunk_business/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_business/proc/get_business_area()
	RETURN_TYPE(/area)
	var/area/current_area = terminal ? get_area(terminal) : null
	if(cyberpunk_is_business_area(current_area))
		return current_area
	if(!legal && current_area)
		return current_area
	if(business_area_type)
		var/area/stored_area = GLOB.areas_by_type[business_area_type]
		if(stored_area && (!legal || cyberpunk_is_business_area(stored_area)))
			return stored_area
	return null

/datum/cyberpunk_business/proc/get_business_turfs()
	var/area/business_area = get_business_area()
	if(!business_area)
		return list()
	return cyberpunk_area_turfs(business_area)

/datum/cyberpunk_business/proc/persistent_record_id()
	return "[owner_character_key]:[business_area_type]"

/datum/cyberpunk_business/proc/get_access_id()
	if(!access_id)
		access_id = cyberpunk_persistent_access_id("business", owner_character_key, business_area_type)
	return access_id

/datum/cyberpunk_business/proc/get_access_key()
	if(!SSid_access)
		return null
	return SSid_access.register_cyberpunk_crypto_access_key(get_access_id(), "[name] business access", name)

/datum/cyberpunk_business/proc/apply_generated_access(mob/living/owner)
	var/datum/cyberpunk_crypto_key/access_key = get_access_key()
	if(!access_key)
		return FALSE
	terminal?.add_cyberpunk_crypto_key(access_key)
	cyberpunk_grant_persistent_access(owner, access_key)
	add_history("business cryptokey access refreshed")
	return TRUE

/datum/cyberpunk_business/proc/to_persistent_record()
	var/datum/bank_account/account = get_account()
	return list(
		"id" = persistent_record_id(),
		"name" = name,
		"owner_key" = owner_character_key,
		"area_type" = "[business_area_type]",
		"saved_at" = world.realtime,
		"snapshot" = saved_snapshot,
		"meta" = list(
			"direction" = direction,
			"legal" = legal,
			"registered_to" = registered_to,
			"account_balance" = account?.account_balance || 0,
			"tax_debt" = tax_debt,
			"tax_paid" = tax_paid,
			"access_id" = get_access_id(),
			"warehouse_stock" = warehouse_stock.Copy(),
			"warehouse_item_types" = warehouse_item_types.Copy(),
			"warehouse_enabled" = warehouse_enabled,
			"warehouse_auto_restock" = warehouse_auto_restock,
			"warehouse_surplus_percent" = warehouse_surplus_percent,
			"warehouse_markup_percent" = warehouse_markup_percent,
			"warehouse_unload_zone" = warehouse_unload_zone,
			"warehouse_unload_zone_ref" = warehouse_unload_zone_ref,
			"warehouse_buy_links" = warehouse_buy_links.Copy(),
			"warehouse_sell_links" = warehouse_sell_links.Copy(),
			"employees" = employees.Copy(),
			"pending_employees" = pending_employees.Copy(),
		),
	)

/datum/cyberpunk_business/proc/hydrate_from_persistent(mob/living/user)
	var/list/record = user?.cyberpunk_find_persistent_area_record(/datum/preference/cyberpunk_business_records, persistent_record_id())
	if(!islist(record))
		return FALSE
	var/list/meta = record["meta"]
	name = record["name"] || name
	if(islist(meta))
		direction = meta["direction"] || direction
		legal = !!meta["legal"]
		registered_to = meta["registered_to"] || registered_to
		access_id = meta["access_id"] || access_id
		tax_debt = max(0, round(meta["tax_debt"] || tax_debt))
		tax_paid = max(0, round(meta["tax_paid"] || tax_paid))
		var/list/persistent_stock = meta["warehouse_stock"]
		if(islist(persistent_stock))
			warehouse_stock = persistent_stock.Copy()
		var/list/persistent_item_types = meta["warehouse_item_types"]
		if(islist(persistent_item_types))
			warehouse_item_types = persistent_item_types.Copy()
		warehouse_enabled = !!meta["warehouse_enabled"]
		warehouse_auto_restock = !!meta["warehouse_auto_restock"]
		warehouse_surplus_percent = clamp(round(meta["warehouse_surplus_percent"] || 0), 0, 100)
		warehouse_markup_percent = clamp(round(meta["warehouse_markup_percent"] || 0), -100, 500)
		warehouse_unload_zone = meta["warehouse_unload_zone"] || warehouse_unload_zone
		warehouse_unload_zone_ref = meta["warehouse_unload_zone_ref"] || warehouse_unload_zone_ref
		var/list/persistent_buy_links = meta["warehouse_buy_links"]
		if(islist(persistent_buy_links))
			warehouse_buy_links = persistent_buy_links.Copy()
		var/list/persistent_sell_links = meta["warehouse_sell_links"]
		if(islist(persistent_sell_links))
			warehouse_sell_links = persistent_sell_links.Copy()
		var/list/persistent_employees = meta["employees"]
		if(islist(persistent_employees))
			employees = persistent_employees.Copy()
		var/list/persistent_pending_employees = meta["pending_employees"]
		if(islist(persistent_pending_employees))
			pending_employees = persistent_pending_employees.Copy()
		var/datum/bank_account/account = get_account()
		if(account && isnum(meta["account_balance"]))
			account.account_balance = max(0, round(meta["account_balance"]))
	if(islist(record["snapshot"]))
		saved_snapshot = record["snapshot"]
		saved_at = world.time
	add_history("persistent business record loaded")
	return TRUE

/datum/cyberpunk_business/proc/contains_atom(atom/checked)
	var/area/business_area = get_business_area()
	return !!(business_area && checked && get_area(checked) == business_area)

/datum/cyberpunk_business/proc/can_view(mob/living/user)
	var/key = user_key(user)
	return key == owner_character_key || !!employees[key] || !!pending_employees[key] || has_terminal_key(user)

/datum/cyberpunk_business/proc/is_owner(mob/living/user)
	return user_key(user) == owner_character_key

/datum/cyberpunk_business/proc/has_terminal_key(mob/living/user)
	return !!(user && terminal && length(terminal.cyberpunk_crypto_keys) && terminal.has_cyberpunk_crypto_access(user))

/datum/cyberpunk_business/proc/has_access(mob/living/user, access_key)
	if(is_owner(user))
		return TRUE
	if(has_terminal_key(user))
		return TRUE
	var/key = user_key(user)
	var/list/employee = employees[key]
	if(!employee)
		return FALSE
	var/list/access = employee["access"]
	return !!(access && access[access_key])

/datum/cyberpunk_business/proc/can_save_load(mob/living/user)
	return is_owner(user) && user.has_neural_implant()

/datum/cyberpunk_business/proc/get_stock_key(item_label)
	var/needle = lowertext("[item_label]")
	for(var/stock_name in warehouse_stock)
		if(lowertext("[stock_name]") == needle)
			return stock_name
	return null

/datum/cyberpunk_business/proc/get_stock_amount(item_label)
	var/stock_key = get_stock_key(item_label)
	return stock_key ? (warehouse_stock[stock_key] || 0) : 0

/datum/cyberpunk_business/proc/get_sellable_stock_amount(item_label)
	var/amount = get_stock_amount(item_label)
	if(amount <= 0)
		return 0
	if(warehouse_surplus_percent <= 0)
		return amount
	return max(0, round(amount * warehouse_surplus_percent / 100))

/datum/cyberpunk_business/proc/add_stock(item_label, amount)
	item_label = reject_bad_text(item_label, max_length = 64, ascii_only = FALSE)
	if(!item_label)
		return 0
	amount = max(0, round(amount))
	if(!amount)
		return 0
	var/stock_key = get_stock_key(item_label) || item_label
	warehouse_stock[stock_key] = (warehouse_stock[stock_key] || 0) + amount
	return amount

/datum/cyberpunk_business/proc/set_stock_item_type(item_label, item_type)
	var/stock_key = get_stock_key(item_label) || item_label
	if(!stock_key || !ispath(item_type, /obj/item))
		return FALSE
	warehouse_item_types[stock_key] = "[item_type]"
	return TRUE

/datum/cyberpunk_business/proc/consume_stock(item_label, amount)
	amount = max(0, round(amount))
	var/stock_key = get_stock_key(item_label)
	if(!stock_key || !amount)
		return 0
	var/taken = min(warehouse_stock[stock_key] || 0, amount)
	warehouse_stock[stock_key] -= taken
	if(warehouse_stock[stock_key] <= 0)
		warehouse_stock -= stock_key
	return taken

/datum/cyberpunk_business/proc/deposit_warehouse_item(mob/living/user, obj/item/item)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !warehouse_enabled || !warehouse_valid || !item)
		return FALSE
	var/obj/structure/cyberpunk_business_unload_zone/zone = get_unload_zone()
	if(!zone || get_dist(user, zone) > 1)
		return FALSE
	if(item.item_flags & ABSTRACT)
		return FALSE
	var/amount = 1
	var/obj/item/stack/stack_item = item
	if(istype(stack_item))
		amount = max(1, stack_item.get_amount())
	var/item_label = item.name
	if(!user.transferItemToLoc(item, zone))
		return FALSE
	add_stock(item_label, amount)
	set_stock_item_type(item_label, item.type)
	qdel(item)
	add_history("[user.real_name || user.name] deposited [amount]x [item_label] into warehouse")
	return TRUE

/datum/cyberpunk_business/proc/absorb_unload_zone_items(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !warehouse_enabled || !warehouse_valid)
		return FALSE
	var/obj/structure/cyberpunk_business_unload_zone/zone = get_unload_zone()
	if(!zone)
		return FALSE
	var/absorbed = 0
	for(var/turf/nearby_turf as anything in range(1, zone))
		if(get_area(nearby_turf) != get_business_area())
			continue
		for(var/obj/item/item in nearby_turf.contents)
			if(item == zone || (item.item_flags & ABSTRACT))
				continue
			var/amount = 1
			var/obj/item/stack/stack_item = item
			if(istype(stack_item))
				amount = max(1, stack_item.get_amount())
			var/item_label = item.name
			add_stock(item_label, amount)
			set_stock_item_type(item_label, item.type)
			qdel(item)
			absorbed += amount
	if(absorbed)
		add_history("[user.real_name || user.name] absorbed [absorbed] physical item(s) from unload zone")
	return absorbed > 0

/datum/cyberpunk_business/proc/withdraw_warehouse_item(mob/living/user, item_label, amount = 1)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !warehouse_enabled || !warehouse_valid)
		return FALSE
	var/obj/structure/cyberpunk_business_unload_zone/zone = get_unload_zone()
	if(!zone || get_dist(user, zone) > 1)
		return FALSE
	amount = clamp(round(amount), 1, 100)
	var/stock_key = get_stock_key(item_label)
	if(!stock_key)
		return FALSE
	var/item_type = text2path("[warehouse_item_types[stock_key]]")
	if(!ispath(item_type, /obj/item))
		return FALSE
	var/taken = consume_stock(stock_key, amount)
	if(!taken)
		return FALSE
	var/turf/drop_turf = get_turf(zone)
	if(ispath(item_type, /obj/item/stack))
		new item_type(drop_turf, taken)
	else
		for(var/i in 1 to taken)
			new item_type(drop_turf)
	add_history("[user.real_name || user.name] withdrew [taken]x [stock_key] from warehouse")
	return TRUE

/datum/cyberpunk_business/proc/get_stock_price(item_label)
	var/base_price = CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST
	return max(1, round(base_price * (100 + warehouse_markup_percent) / 100))

/datum/cyberpunk_business/proc/allows_warehouse_partner(datum/cyberpunk_business/partner, buy_side = TRUE)
	if(!partner)
		return FALSE
	var/list/links = buy_side ? warehouse_buy_links : warehouse_sell_links
	if(!length(links))
		return TRUE
	for(var/link in links)
		var/link_key = lowertext("[link]")
		if(link_key == lowertext("[partner.id]") || link_key == lowertext(partner.name))
			return TRUE
	return FALSE

/datum/cyberpunk_business/proc/charge(amount, reason, allow_debt = TRUE)
	amount = max(0, round(amount))
	if(!amount)
		return TRUE
	var/datum/bank_account/account = get_account()
	if(!account)
		return FALSE
	if(account.adjust_money(-amount, reason))
		return TRUE
	if(!allow_debt)
		return FALSE
	var/available = max(0, account.account_balance)
	if(available)
		account.adjust_money(-available, reason)
	var/debt = amount - available
	account.account_debt += debt
	account.add_log_to_history(-debt, "[reason]; debt")
	add_history("debt increased by [debt][MONEY_SYMBOL]: [reason]")
	log_econ("Business #[id] [name] debt increased by [debt][MONEY_NAME]: [reason]")
	return TRUE

/datum/cyberpunk_business/proc/record_income(amount, reason, taxable = TRUE)
	amount = max(0, round(amount))
	var/datum/bank_account/account = get_account()
	if(!account || !amount)
		return FALSE
	var/tax = 0
	if(legal && taxable)
		tax = round(amount * SScyberpunk_corporations.get_cyberpunk_business_tax_rate(id))
	if(!account.adjust_money(amount, reason))
		return FALSE
	if(tax > 0)
		tax_debt += tax
		add_history("tax accrued [tax][MONEY_SYMBOL]: [reason]")
		auto_pay_taxes()
	log_econ("Business #[id] [legal ? "legal" : "off-ledger"] income [amount][MONEY_NAME]: [reason]; tax accrued [tax][MONEY_NAME].")
	return TRUE

/datum/cyberpunk_business/proc/pay_taxes(mob/living/user, amount = 0)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = round(amount || tax_debt)
	amount = clamp(amount, 0, tax_debt)
	if(amount <= 0)
		return FALSE
	var/datum/bank_account/account = get_account()
	if(!account || !account.adjust_money(-amount, "Business tax payment: [name]"))
		return FALSE
	SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(amount, "Business tax: [name]")
	tax_debt -= amount
	tax_paid += amount
	add_history("[user.real_name || user.name] paid [amount][MONEY_SYMBOL] tax")
	log_econ("Business #[id] [name] paid [amount][MONEY_NAME] tax.")
	return TRUE

/datum/cyberpunk_business/proc/auto_pay_taxes()
	if(!legal || tax_debt <= 0)
		return FALSE
	var/datum/bank_account/account = get_account()
	if(!account)
		return FALSE
	var/amount = min(tax_debt, max(0, round(account.account_balance)))
	if(amount <= 0 || !account.adjust_money(-amount, "Automatic business tax payment: [name]"))
		return FALSE
	SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(amount, "Automatic business tax: [name]")
	tax_debt -= amount
	tax_paid += amount
	add_history("automatic tax payment: [amount][MONEY_SYMBOL]")
	log_econ("Business #[id] [name] automatically paid [amount][MONEY_NAME] tax.")
	return TRUE

/datum/cyberpunk_business/proc/process_payroll()
	if(world.time < last_payroll_at + CYBERPUNK_BUSINESS_PAYROLL_INTERVAL)
		return FALSE
	last_payroll_at = world.time
	if(!length(employees))
		return FALSE
	var/datum/bank_account/business_account = get_account()
	if(!business_account)
		return FALSE
	var/paid_count = 0
	var/paid_total = 0
	for(var/employee_key in employees)
		var/list/employee = employees[employee_key]
		var/wage = max(0, round(employee["wage"] || 0))
		if(wage <= 0)
			continue
		var/datum/bank_account/employee_account = find_employee_account(employee_key)
		if(!employee_account)
			add_history("payroll skipped [employee["name"]]: no bank account")
			continue
		if(!employee_account.transfer_money(business_account, wage, "Business payroll: [name]"))
			add_history("payroll failed [employee["name"]]: insufficient business funds")
			continue
		paid_count++
		paid_total += wage
		employee_account.bank_card_talk("Payroll received from [name]: [wage][MONEY_SYMBOL].")
	if(paid_total)
		add_history("payroll paid [paid_total][MONEY_SYMBOL] to [paid_count] employee(s)")
		log_econ("Business #[id] [name] paid payroll [paid_total][MONEY_NAME] to [paid_count] employee(s).")
	return paid_total > 0

/datum/cyberpunk_business/proc/get_unload_zone()
	RETURN_TYPE(/obj/structure/cyberpunk_business_unload_zone)
	if(warehouse_unload_zone_ref)
		var/obj/structure/cyberpunk_business_unload_zone/stored_zone = locate(warehouse_unload_zone_ref)
		if(istype(stored_zone) && stored_zone.business_id == id && contains_atom(stored_zone))
			return stored_zone
	var/area/business_area = get_business_area()
	if(!business_area)
		return null
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/structure/cyberpunk_business_unload_zone/zone in business_turf.contents)
			if(zone.business_id == id)
				warehouse_unload_zone_ref = REF(zone)
				return zone
	return null

/datum/cyberpunk_business/proc/validate_premises(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL) || !terminal)
		return FALSE
	var/area/business_area = get_business_area()
	if(legal && !cyberpunk_is_business_area(business_area))
		premises_valid = FALSE
		premises_validation = "failed: legal business terminal is outside a registered business area"
	else if(!business_area)
		premises_valid = FALSE
		premises_validation = "failed: no business premises area"
	else
		var/turf_count = length(get_business_turfs())
		premises_valid = turf_count <= 17 * 17
		var/legal_label = legal ? "registered" : "off-ledger"
		premises_validation = premises_valid ? "ok: [legal_label] premises [business_area.name], [turf_count]/289 tiles" : "failed: [business_area.name] is larger than 17x17 ([turf_count]/289 tiles)"
	add_history("[user.real_name || user.name] validated premises: [premises_validation]")
	return premises_valid

/datum/cyberpunk_business/proc/validate_unload_zone()
	var/obj/structure/cyberpunk_business_unload_zone/zone = get_unload_zone()
	if(!zone)
		return FALSE
	var/turf/center = get_turf(zone)
	if(!center)
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	for(var/dx in -1 to 1)
		for(var/dy in -1 to 1)
			var/turf/check = locate(center.x + dx, center.y + dy, center.z)
			if(!check || get_area(check) != business_area || isclosedturf(check) || isspaceturf(check))
				return FALSE
	return TRUE

/datum/cyberpunk_business/proc/validate_warehouse(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	if(!warehouse_enabled)
		warehouse_valid = FALSE
		unload_zone_valid = FALSE
		warehouse_validation = "failed: warehouse disabled"
		add_history("[user.real_name || user.name] validated warehouse: [warehouse_validation]")
		return FALSE
	var/area/business_area = get_business_area()
	unload_zone_valid = validate_unload_zone()
	warehouse_valid = premises_valid && !!business_area && unload_zone_valid
	if(warehouse_valid)
		warehouse_validation = "ok: [business_area.name] and linked 3x3 unload zone"
	else if(!premises_valid || !business_area)
		warehouse_validation = "failed: business area is not valid"
	else
		warehouse_validation = "failed: linked 3x3 unload zone is missing, blocked, or outside premises"
	add_history("[user.real_name || user.name] validated warehouse: [warehouse_validation]")
	return warehouse_valid

/datum/cyberpunk_business/proc/deploy_unload_zone(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	if(!premises_valid)
		validate_premises(user)
	if(!premises_valid)
		return FALSE
	var/turf/target_turf = get_turf(user)
	if(!target_turf || get_area(target_turf) != get_business_area())
		return FALSE
	for(var/obj/structure/cyberpunk_business_unload_zone/existing in target_turf.contents)
		if(existing.business_id && existing.business_id != id)
			return FALSE
		existing.bind_business(src)
		warehouse_unload_zone = "[target_turf.x],[target_turf.y],[target_turf.z]"
		warehouse_unload_zone_ref = REF(existing)
		add_history("[user.real_name || user.name] linked unload zone at [warehouse_unload_zone]")
		return TRUE
	var/obj/structure/cyberpunk_business_unload_zone/zone = new(target_turf)
	zone.bind_business(src)
	warehouse_unload_zone = "[target_turf.x],[target_turf.y],[target_turf.z]"
	warehouse_unload_zone_ref = REF(zone)
	add_history("[user.real_name || user.name] deployed unload zone at [warehouse_unload_zone]")
	return TRUE

/datum/cyberpunk_business/proc/set_settings(mob/living/user, list/params)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL))
		return FALSE
	name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE) || name
	direction = reject_bad_text(params["direction"], max_length = 64, ascii_only = FALSE) || direction
	if(is_owner(user))
		var/wants_legal = text2num(params["legal"]) ? TRUE : FALSE
		if(wants_legal && !cyberpunk_is_business_area(get_area(terminal)))
			return FALSE
		if(wants_legal && !legal)
			for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
				var/datum/cyberpunk_business/existing_business = SScyberpunk_property.cyberpunk_businesses[business_id]
				if(existing_business && existing_business != src && existing_business.legal && existing_business.get_business_area() == get_area(terminal))
					return FALSE
		legal = wants_legal
		size_class = legal ? "17x17" : "off-ledger"
	registered_to = reject_bad_text(params["registered_to"], max_length = 48, ascii_only = FALSE) || registered_to
	add_history("[user.real_name || user.name] updated business settings")
	return TRUE

/datum/cyberpunk_business/proc/set_warehouse(mob/living/user, list/params)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK))
		return FALSE
	warehouse_enabled = text2num(params["enabled"]) ? TRUE : FALSE
	warehouse_auto_restock = text2num(params["auto_restock"]) ? TRUE : FALSE
	warehouse_surplus_percent = clamp(round(text2num(params["surplus_percent"]) || 0), 0, 100)
	warehouse_markup_percent = clamp(round(text2num(params["markup_percent"]) || 0), -100, 500)
	warehouse_unload_zone = reject_bad_text(params["unload_zone"], max_length = 64, ascii_only = FALSE) || warehouse_unload_zone
	warehouse_buy_links = cyberpunk_business_link_list_from_text(params["buy_links"])
	warehouse_sell_links = cyberpunk_business_link_list_from_text(params["sell_links"])
	add_history("[user.real_name || user.name] updated warehouse settings")
	return TRUE

/datum/cyberpunk_business/proc/add_employee(mob/living/user, employee_name, wage = 0)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_name = reject_bad_text(employee_name, max_length = 64, ascii_only = FALSE)
	var/key = ckey(employee_name)
	if(!key || key == owner_character_key)
		return FALSE
	if(employees[key])
		return FALSE
	pending_employees[key] = list(
		"name" = employee_name,
		"wage" = max(0, round(wage)),
		"access" = list(
			CYBERPUNK_BUSINESS_ACCESS_TERMINAL = TRUE,
			CYBERPUNK_BUSINESS_ACCESS_FINANCE = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STOCK = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STAFF = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_CONTRACTS = TRUE,
		),
	)
	add_history("[user.real_name || user.name] invited [employee_name]")
	return TRUE

/datum/cyberpunk_business/proc/accept_employee_invite(mob/living/user)
	var/key = user_key(user)
	var/list/pending_employee = pending_employees[key]
	if(!pending_employee)
		return FALSE
	employees[key] = pending_employee.Copy()
	pending_employees -= key
	add_history("[user.real_name || user.name] accepted employment")
	return TRUE

/datum/cyberpunk_business/proc/force_add_employee(mob/living/user, employee_name, wage = 0)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_name = reject_bad_text(employee_name, max_length = 64, ascii_only = FALSE)
	var/key = ckey(employee_name)
	if(!key || key == owner_character_key)
		return FALSE
	employees[key] = list(
		"name" = employee_name,
		"wage" = max(0, round(wage)),
		"access" = list(
			CYBERPUNK_BUSINESS_ACCESS_TERMINAL = TRUE,
			CYBERPUNK_BUSINESS_ACCESS_FINANCE = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STOCK = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STAFF = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_CONTRACTS = TRUE,
		),
	)
	add_history("[user.real_name || user.name] hired [employee_name]")
	return TRUE

/datum/cyberpunk_business/proc/remove_employee(mob/living/user, employee_key)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	if(pending_employees[employee_key])
		var/list/pending_employee = pending_employees[employee_key]
		add_history("[user.real_name || user.name] cancelled invite for [pending_employee["name"]]")
		pending_employees -= employee_key
		return TRUE
	if(!employees[employee_key])
		return FALSE
	var/list/employee = employees[employee_key]
	add_history("[user.real_name || user.name] removed [employee["name"]]")
	employees -= employee_key
	return TRUE

/datum/cyberpunk_business/proc/set_employee_wage(mob/living/user, employee_key, wage)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	var/list/employee = employees[employee_key]
	if(!employee)
		return FALSE
	employee["wage"] = max(0, round(wage))
	add_history("[user.real_name || user.name] set [employee["name"]]'s wage to [employee["wage"]][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/toggle_employee_access(mob/living/user, employee_key, access_key)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	var/list/employee = employees[employee_key]
	if(!employee)
		return FALSE
	if(!(access_key in list(CYBERPUNK_BUSINESS_ACCESS_TERMINAL, CYBERPUNK_BUSINESS_ACCESS_FINANCE, CYBERPUNK_BUSINESS_ACCESS_STOCK, CYBERPUNK_BUSINESS_ACCESS_STAFF, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS)))
		return FALSE
	var/list/access = employee["access"]
	access[access_key] = !access[access_key]
	add_history("[user.real_name || user.name] toggled [access_key] for [employee["name"]]")
	return TRUE

/datum/cyberpunk_business/proc/deposit(mob/living/user, amount)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = max(0, round(amount))
	var/datum/bank_account/user_account = user.get_bank_account()
	var/datum/bank_account/business_account = get_account()
	if(!user_account || !business_account || amount <= 0)
		return FALSE
	if(!business_account.transfer_money(user_account, amount, "Business deposit: [name]"))
		return FALSE
	add_history("[user.real_name || user.name] deposited [amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/withdraw(mob/living/user, amount)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = max(0, round(amount))
	var/datum/bank_account/user_account = user.get_bank_account()
	var/datum/bank_account/business_account = get_account()
	if(!user_account || !business_account || amount <= 0)
		return FALSE
	if(!user_account.transfer_money(business_account, amount, "Business withdrawal: [name]"))
		return FALSE
	add_history("[user.real_name || user.name] withdrew [amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/save_business(mob/living/user)
	if(!can_save_load(user) || !terminal)
		return FALSE
	if(!premises_valid && !validate_premises(user))
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	saved_snapshot = cyberpunk_persistent_area_capture(business_area, terminal)
	saved_at = world.time
	user.cyberpunk_store_persistent_area_record(/datum/preference/cyberpunk_business_records, to_persistent_record())
	add_history("[user.real_name || user.name] saved [length(saved_snapshot["movables"])] object(s) and [length(saved_snapshot["turfs"])] turf(s)")
	return TRUE

/datum/cyberpunk_business/proc/load_business(mob/living/user)
	if(!can_save_load(user) || !terminal || loaded_this_round || !length(saved_snapshot))
		return FALSE
	if(!premises_valid && !validate_premises(user))
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	var/restored = cyberpunk_persistent_area_restore(business_area, terminal, saved_snapshot)
	loaded_this_round = TRUE
	apply_generated_access(user)
	add_history("[user.real_name || user.name] loaded [restored] object(s); area overwritten")
	return TRUE

/datum/cyberpunk_business/proc/request_delivery(mob/living/user, item_label, amount, source_label)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !warehouse_enabled || !warehouse_valid)
		return FALSE
	return !!SScyberpunk_property.create_cyberpunk_business_delivery(src, item_label, amount, source_label)

/datum/cyberpunk_business/proc/link_nearby_vendors(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	var/linked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/vending/vendor in business_turf.contents)
			if(!vendor.has_business_vending_module())
				continue
			vendor.cyberpunk_business_id = id
			vendor.cyberpunk_business_auto_restock = warehouse_auto_restock
			vendor.cyberpunk_business_markup_percent = warehouse_markup_percent
			linked++
	if(linked)
		add_history("[user.real_name || user.name] linked [linked] vendor(s) inside business area")
	return linked > 0

/datum/cyberpunk_business/proc/link_nearby_production_machines(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	var/linked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/machine in business_turf.contents)
			if(!(istype(machine, /obj/machinery/autolathe) || istype(machine, /obj/machinery/rnd/production)))
				continue
			machine.cyberpunk_business_id = id
			machine.cyberpunk_business_warehouse_linked = TRUE
			linked++
	if(linked)
		add_history("[user.real_name || user.name] linked [linked] production machine(s) to warehouse")
	return linked > 0

/datum/cyberpunk_business/proc/restock_linked_vendors(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal || !warehouse_enabled || !warehouse_valid)
		return FALSE
	var/restocked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/vending/vendor in business_turf.contents)
			if(vendor.cyberpunk_business_id != id)
				continue
			restocked += vendor.cyberpunk_business_restock_from_warehouse()
	if(restocked)
		add_history("[user.real_name || user.name] restocked linked vendors with [restocked] item(s)")
	return restocked > 0

/datum/cyberpunk_business/proc/auto_restock_linked_vendors()
	if(!warehouse_auto_restock || !warehouse_enabled || !warehouse_valid || world.time < last_auto_restock_at + CYBERPUNK_BUSINESS_AUTO_RESTOCK_INTERVAL)
		return FALSE
	last_auto_restock_at = world.time
	var/restocked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/vending/vendor in business_turf.contents)
			if(vendor.cyberpunk_business_id != id || !vendor.cyberpunk_business_auto_restock)
				continue
			restocked += vendor.cyberpunk_business_restock_from_warehouse()
	if(restocked)
		add_history("automatic vendor restock: [restocked] item(s)")
	return restocked > 0

/datum/cyberpunk_business/proc/to_ui_data(mob/living/user, include_history = FALSE)
	var/datum/bank_account/account = get_account()
	var/list/employee_records = list()
	for(var/employee_key in employees)
		var/list/employee = employees[employee_key]
		var/list/access = employee["access"]
		employee_records += list(list(
			"key" = employee_key,
			"name" = employee["name"],
			"wage" = employee["wage"],
			"access" = access,
		))
	var/list/pending_employee_records = list()
	for(var/pending_key in pending_employees)
		var/list/pending_employee = pending_employees[pending_key]
		pending_employee_records += list(list(
			"key" = pending_key,
			"name" = pending_employee["name"],
			"wage" = pending_employee["wage"],
			"access" = pending_employee["access"],
		))
	var/list/stock_records = list()
	for(var/stock_name in warehouse_stock)
		stock_records += list(list(
			"name" = stock_name,
			"amount" = warehouse_stock[stock_name],
			"itemType" = warehouse_item_types[stock_name],
			"canWithdraw" = !!warehouse_item_types[stock_name],
		))
	var/list/delivery_records = list()
	for(var/datum/cyberpunk_business_delivery/delivery as anything in deliveries)
		delivery_records += list(delivery.to_ui_data())
	return list(
		"id" = id,
		"name" = name,
		"direction" = direction,
		"legal" = legal,
		"registeredTo" = registered_to,
		"sizeClass" = size_class,
		"owner" = owner_name,
		"accountId" = account_id,
		"balance" = account?.account_balance || 0,
		"businessArea" = get_business_area()?.name || "none",
		"warehouse" = list(
			"enabled" = warehouse_enabled,
			"autoRestock" = warehouse_auto_restock,
			"surplusPercent" = warehouse_surplus_percent,
			"markupPercent" = warehouse_markup_percent,
			"unloadZone" = warehouse_unload_zone,
			"hasUnloadZone" = !!get_unload_zone(),
			"buyLinks" = cyberpunk_business_link_list_to_text(warehouse_buy_links),
			"sellLinks" = cyberpunk_business_link_list_to_text(warehouse_sell_links),
			"valid" = warehouse_valid,
			"unloadValid" = unload_zone_valid,
			"validation" = warehouse_validation,
		),
		"premises" = list(
			"valid" = premises_valid,
			"validation" = premises_validation,
		),
		"debt" = account?.account_debt || 0,
		"taxDebt" = tax_debt,
		"taxPaid" = tax_paid,
		"taxRate" = round(SScyberpunk_corporations.get_cyberpunk_business_tax_rate(id) * 100),
		"employees" = employee_records,
		"pendingEmployees" = pending_employee_records,
		"canAcceptEmployment" = !!pending_employees[user_key(user)],
		"stock" = stock_records,
		"deliveries" = delivery_records,
		"savedObjects" = islist(saved_snapshot) && islist(saved_snapshot["movables"]) ? length(saved_snapshot["movables"]) : 0,
		"savedAt" = saved_at ? DisplayTimeText(world.time - saved_at) : null,
		"loadedThisRound" = loaded_this_round,
		"canSaveLoad" = can_save_load(user),
		"canFinance" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE),
		"canStock" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK),
		"canStaff" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF),
		"canContracts" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS),
		"history" = include_history ? history : null,
	)
