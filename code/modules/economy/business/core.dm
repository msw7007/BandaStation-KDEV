//CYBERPUNK BUSINESS - business datum and warehouse logic.
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
	var/list/warehouse_stock = list()
	var/warehouse_enabled = FALSE
	var/warehouse_auto_restock = FALSE
	var/warehouse_surplus_percent = 0
	var/warehouse_markup_percent = 0
	var/warehouse_unload_zone = "unset"
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
	var/list/history = list()

/datum/cyberpunk_business/proc/get_account()
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/datum/cyberpunk_business/proc/user_key(mob/living/user)
	return SScyberpunk_property.get_cyberpunk_business_key(user, user?.get_bank_account())

/datum/cyberpunk_business/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_business/proc/get_business_area()
	RETURN_TYPE(/area)
	var/area/current_area = terminal ? get_area(terminal) : null
	if(istype(current_area, /area/station/service/business))
		return current_area
	if(business_area_type)
		var/area/stored_area = GLOB.areas_by_type[business_area_type]
		if(stored_area)
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
			"warehouse_enabled" = warehouse_enabled,
			"warehouse_auto_restock" = warehouse_auto_restock,
			"warehouse_surplus_percent" = warehouse_surplus_percent,
			"warehouse_markup_percent" = warehouse_markup_percent,
			"warehouse_unload_zone" = warehouse_unload_zone,
			"warehouse_buy_links" = warehouse_buy_links.Copy(),
			"warehouse_sell_links" = warehouse_sell_links.Copy(),
			"employees" = employees.Copy(),
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
		warehouse_enabled = !!meta["warehouse_enabled"]
		warehouse_auto_restock = !!meta["warehouse_auto_restock"]
		warehouse_surplus_percent = clamp(round(meta["warehouse_surplus_percent"] || 0), 0, 100)
		warehouse_markup_percent = clamp(round(meta["warehouse_markup_percent"] || 0), -100, 500)
		warehouse_unload_zone = meta["warehouse_unload_zone"] || warehouse_unload_zone
		var/list/persistent_buy_links = meta["warehouse_buy_links"]
		if(islist(persistent_buy_links))
			warehouse_buy_links = persistent_buy_links.Copy()
		var/list/persistent_sell_links = meta["warehouse_sell_links"]
		if(islist(persistent_sell_links))
			warehouse_sell_links = persistent_sell_links.Copy()
		var/list/persistent_employees = meta["employees"]
		if(islist(persistent_employees))
			employees = persistent_employees.Copy()
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
	return key == owner_character_key || !!employees[key] || has_terminal_key(user)

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
	account.adjust_money(amount, reason)
	if(legal && taxable)
		var/tax = round(amount * CYBERPUNK_BUSINESS_TAX_RATE)
		if(tax > 0)
			tax_debt += tax
			add_history("tax debt increased by [tax][MONEY_SYMBOL]: [reason]")
	log_econ("Business #[id] [legal ? "legal" : "off-ledger"] income [amount][MONEY_NAME]: [reason]; tax debt [tax_debt][MONEY_NAME].")
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

/datum/cyberpunk_business/proc/validate_premises(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL) || !terminal)
		return FALSE
	var/area/business_area = get_business_area()
	if(!istype(business_area, /area/station/service/business))
		premises_valid = FALSE
		premises_validation = "failed: terminal is outside a business area"
	else
		var/turf_count = length(get_business_turfs())
		premises_valid = turf_count <= 17 * 17
		premises_validation = premises_valid ? "ok: [business_area.name], [turf_count]/289 tiles" : "failed: [business_area.name] is larger than 17x17 ([turf_count]/289 tiles)"
	add_history("[user.real_name || user.name] validated premises: [premises_validation]")
	return premises_valid

/datum/cyberpunk_business/proc/validate_unload_zone()
	if(!terminal)
		return FALSE
	var/turf/center = get_turf(terminal)
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
		warehouse_validation = "ok: [business_area.name] and terminal-centered 3x3 unload area"
	else if(!premises_valid || !business_area)
		warehouse_validation = "failed: business area is not valid"
	else
		warehouse_validation = "failed: terminal-centered 3x3 unload area is blocked or outside business area"
	add_history("[user.real_name || user.name] validated warehouse: [warehouse_validation]")
	return warehouse_valid

/datum/cyberpunk_business/proc/set_settings(mob/living/user, list/params)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL))
		return FALSE
	name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE) || name
	direction = reject_bad_text(params["direction"], max_length = 64, ascii_only = FALSE) || direction
	if(is_owner(user))
		legal = text2num(params["legal"]) ? TRUE : FALSE
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
	var/list/stock_records = list()
	for(var/stock_name in warehouse_stock)
		stock_records += list(list("name" = stock_name, "amount" = warehouse_stock[stock_name]))
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
		"taxRate" = round(CYBERPUNK_BUSINESS_TAX_RATE * 100),
		"employees" = employee_records,
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
