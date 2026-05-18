/// Cyberpunk city economy, law, loan and forensic core.
/// This layer deliberately extends SSeconomy instead of creating a parallel subsystem.

/datum/cy_city_transaction
	var/id
	var/timestamp
	var/from_account_id
	var/from_name
	var/to_account_id
	var/to_name
	var/amount = 0
	var/tax_amount = 0
	var/service_fee = 0
	var/reason = ""
	var/visibility = CY_ECON_VISIBILITY_BANK
	var/channel = CY_ECON_CHANNEL_BANK
	var/operator_name
	var/source_name
	var/flagged = FALSE
	var/erased = FALSE
	var/shadow_bank_id

/datum/cy_city_transaction/New(datum/bank_account/from_account, datum/bank_account/to_account, amount, reason, visibility, channel, operator_name, atom/source, tax_amount = 0, service_fee = 0)
	id = "TX-[world.time]-[rand(1000,9999)]"
	timestamp = round_timestamp("hh:mm:ss")
	if(from_account)
		from_account_id = "[from_account.account_id]"
		from_name = from_account.account_holder
	if(to_account)
		to_account_id = "[to_account.account_id]"
		to_name = to_account.account_holder
	src.amount = amount
	src.tax_amount = tax_amount
	src.service_fee = service_fee
	src.reason = reason || "Городская транзакция"
	src.visibility = visibility || CY_ECON_VISIBILITY_BANK
	src.channel = channel || CY_ECON_CHANNEL_BANK
	src.operator_name = operator_name
	source_name = source ? "[source]" : null

/datum/cy_city_loan
	var/id
	var/datum/bank_account/lender
	var/datum/bank_account/borrower
	var/principal = 0
	var/outstanding = 0
	var/interest_percent = 0
	var/late_fee = 0
	var/due_time = 0
	var/collateral
	var/status = CY_LOAN_ACTIVE
	var/visibility = CY_ECON_VISIBILITY_BANK
	var/created_time
	var/last_payment_time
	var/list/log = list()

/datum/cy_city_loan/New(datum/bank_account/lender, datum/bank_account/borrower, amount, interest_percent = 0, due_time = 0, collateral = null, visibility = CY_ECON_VISIBILITY_BANK)
	id = "LN-[world.time]-[rand(1000,9999)]"
	src.lender = lender
	src.borrower = borrower
	principal = max(0, round(amount))
	outstanding = principal + round(principal * max(0, interest_percent) / 100)
	src.interest_percent = interest_percent
	src.due_time = due_time
	src.collateral = collateral
	src.visibility = visibility
	created_time = world.time
	log += "[round_timestamp("hh:mm")]: loan opened for [principal][MONEY_SYMBOL], outstanding [outstanding][MONEY_SYMBOL]."

/datum/cy_city_loan/proc/make_payment(amount)
	if(status != CY_LOAN_ACTIVE)
		return FALSE
	amount = min(max(0, round(amount)), outstanding)
	if(amount <= 0)
		return FALSE
	if(!SSeconomy.cy_transfer_money(borrower, lender, amount, "Погашение ссуды [id]", CY_TAX_NONE, CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_BANK))
		return FALSE
	outstanding -= amount
	last_payment_time = world.time
	log += "[round_timestamp("hh:mm")]: paid [amount][MONEY_SYMBOL], remains [outstanding][MONEY_SYMBOL]."
	if(outstanding <= 0)
		status = CY_LOAN_PAID
		log += "[round_timestamp("hh:mm")]: loan closed."
	return TRUE

/datum/cy_city_law
	var/id
	var/title
	var/description
	var/default_fine = 0
	var/default_sentence = 0
	var/severity = CY_CRIME_SEVERITY_MINOR
	var/active = TRUE
	var/issuer = "Городской совет"
	var/created_time

/datum/cy_city_law/New(id, title, description, default_fine = 0, default_sentence = 0, severity = CY_CRIME_SEVERITY_MINOR, issuer = "Городской совет")
	src.id = id
	src.title = title
	src.description = description
	src.default_fine = default_fine
	src.default_sentence = default_sentence
	src.severity = severity
	src.issuer = issuer
	created_time = round_timestamp("hh:mm")

/datum/cy_city_crime_record
	var/character_key
	var/character_name
	var/list/violations = list()
	var/list/forensic_traces = list()
	var/security_note = ""
	var/last_seen_status = CY_WARRANT_NONE

/datum/cy_city_crime_record/New(character_key, character_name)
	src.character_key = character_key
	src.character_name = character_name

/datum/cy_city_crime_record/proc/current_status()
	var/highest = CY_WARRANT_NONE
	for(var/datum/cy_city_violation/violation as anything in violations)
		if(!violation.active)
			continue
		highest = max(highest, violation.status)
	last_seen_status = highest
	return highest

/datum/cy_city_crime_record/proc/total_fines()
	var/total = 0
	for(var/datum/cy_city_violation/violation as anything in violations)
		if(violation.active)
			total += max(0, violation.fine_remaining)
	return total

/datum/cy_city_violation
	var/id
	var/law_id
	var/law_title
	var/details
	var/issuer
	var/issued_time
	var/fine_total = 0
	var/fine_remaining = 0
	var/sentence_time = 0
	var/status = CY_WARRANT_FINE
	var/active = TRUE
	var/served = FALSE
	var/served_at_roundend = FALSE
	var/list/log = list()

/datum/cy_city_violation/New(law_id, law_title, details, issuer, fine_total = 0, sentence_time = 0, status = CY_WARRANT_FINE)
	id = "CR-[world.time]-[rand(1000,9999)]"
	src.law_id = law_id
	src.law_title = law_title
	src.details = details
	src.issuer = issuer
	issued_time = round_timestamp("hh:mm")
	src.fine_total = max(0, round(fine_total))
	fine_remaining = src.fine_total
	src.sentence_time = max(0, sentence_time)
	src.status = status
	log += "[issued_time]: issued by [issuer || "system"]."

/datum/cy_city_violation/proc/pay(amount)
	amount = min(max(0, round(amount)), fine_remaining)
	if(amount <= 0)
		return FALSE
	fine_remaining -= amount
	log += "[round_timestamp("hh:mm")]: paid [amount][MONEY_SYMBOL], remains [fine_remaining][MONEY_SYMBOL]."
	if(fine_remaining <= 0 && !sentence_time)
		active = FALSE
		status = CY_WARRANT_CLEARED
		log += "[round_timestamp("hh:mm")]: fine cleared."
	return TRUE

/datum/cy_city_forensic_trace
	var/id
	var/character_key
	var/character_name
	var/action
	var/atom_name
	var/area_name
	var/turf_x
	var/turf_y
	var/turf_z
	var/quality = 100
	var/time_created
	var/collected_by
	var/collected_time

/datum/cy_city_forensic_trace/New(mob/user, atom/source, action, quality = 100)
	id = "FT-[world.time]-[rand(1000,9999)]"
	character_key = SSeconomy.cy_character_key(user)
	character_name = user ? user.real_name || user.name : "Unknown"
	src.action = action || "interaction"
	atom_name = source ? source.name : "Unknown object"
	var/turf/T = get_turf(source)
	if(T)
		var/area/A = get_area(T)
		area_name = A ? A.name : null
		turf_x = T.x
		turf_y = T.y
		turf_z = T.z
	src.quality = clamp(quality, 1, 100)
	time_created = round_timestamp("hh:mm")

/datum/controller/subsystem/economy/proc/cy_init_city_economy()
	if(cy_city_economy_ready)
		return
	cy_city_economy_ready = TRUE
	cy_city_accounts = list()
	cy_city_ledger = list()
	cy_city_loans = list()
	cy_city_laws = list()
	cy_city_crime_records = list()
	cy_city_forensic_traces = list()
	cy_supply_pressure = list()
	cy_round_access_keys = list()
	cy_create_city_account(CY_ACCOUNT_GOVERNMENT, "Казна правительства", CY_CITY_GOVERNMENT_STARTING_BALANCE, CY_CITY_GOVERNMENT_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_BEN, "Конгломерат Бэнь", CY_CITY_CORP_STARTING_BALANCE, CY_CITY_CORP_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_RYAZNOV, "Союз Рязнов", CY_CITY_CORP_STARTING_BALANCE, CY_CITY_CORP_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_STARLIGHT, "Объединение Старлайт", CY_CITY_CORP_STARTING_BALANCE, CY_CITY_CORP_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_CIV_MARKET, "Городской рынок", CY_CITY_MARKET_STARTING_BALANCE, CY_CITY_MARKET_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_EXPORT_POOL, "Внешний экспорт", CY_CITY_EXPORT_POOL_STARTING_BALANCE, CY_CITY_EXPORT_POOL_STARTING_BUDGET)
	cy_create_city_account(CY_ACCOUNT_BLACK_MARKET, "Теневой рынок", CY_CITY_BLACK_MARKET_STARTING_BALANCE, CY_CITY_BLACK_MARKET_STARTING_BUDGET, TRUE)
	cy_seed_default_laws()
	cy_generate_round_access_keys()

/datum/controller/subsystem/economy/proc/cy_create_city_account(account_id, holder, balance, budget = 0, shadow = FALSE)
	var/datum/bank_account/city_system/account = new(holder, account_id, balance, budget, shadow)
	cy_city_accounts[account_id] = account
	return account

/datum/controller/subsystem/economy/proc/cy_get_city_account(account_id)
	if(!cy_city_economy_ready)
		cy_init_city_economy()
	return cy_city_accounts[account_id]

/datum/controller/subsystem/economy/proc/cy_get_government_account()
	return cy_get_city_account(CY_ACCOUNT_GOVERNMENT)

/datum/controller/subsystem/economy/proc/cy_account_for_department(dep_id)
	switch(dep_id)
		if(ACCOUNT_MED, ACCOUNT_SCI)
			return cy_get_city_account(CY_ACCOUNT_BEN)
		if(ACCOUNT_ENG, ACCOUNT_SEC)
			return cy_get_city_account(CY_ACCOUNT_RYAZNOV)
		if(ACCOUNT_SRV, ACCOUNT_CAR)
			return cy_get_city_account(CY_ACCOUNT_STARLIGHT)
	return cy_get_city_account(CY_ACCOUNT_CIV_MARKET)

/datum/controller/subsystem/economy/proc/cy_account_for_vendor(obj/machinery/vending/vendor)
	if(!vendor)
		return cy_get_city_account(CY_ACCOUNT_CIV_MARKET)
	return cy_account_for_department(vendor.payment_department)

/datum/controller/subsystem/economy/proc/cy_tax_rate_for_profile(tax_profile)
	switch(tax_profile)
		if(CY_TAX_NONE)
			return 0
		if(CY_TAX_VENDOR)
			return CY_CITY_VENDOR_TAX_RATE
		if(CY_TAX_SERVICE)
			return CY_CITY_SERVICE_TAX_RATE
		if(CY_TAX_CONTRACT)
			return CY_CITY_CONTRACT_TAX_RATE
		if(CY_TAX_TRANSFER)
			return CY_CITY_TRANSFER_TAX_RATE
		if(CY_TAX_LOAN)
			return CY_CITY_LOAN_FEE_RATE
	return CY_CITY_TRANSFER_TAX_RATE

/datum/controller/subsystem/economy/proc/cy_transfer_money(datum/bank_account/from_account, datum/bank_account/to_account, amount, reason = "Городская транзакция", tax_profile = CY_TAX_TRANSFER, visibility = CY_ECON_VISIBILITY_BANK, channel = CY_ECON_CHANNEL_BANK, mob/operator = null, atom/source = null)
	if(!cy_city_economy_ready)
		cy_init_city_economy()
	amount = max(0, round(amount))
	if(amount <= 0 || !to_account)
		return FALSE
	if(from_account && !from_account.has_money(amount))
		return FALSE
	var/tax_rate = cy_tax_rate_for_profile(tax_profile)
	var/tax_amount = round(amount * tax_rate)
	var/service_fee = 0
	var/net_amount = max(0, amount - tax_amount - service_fee)
	if(from_account && !from_account.adjust_money(-amount, reason))
		return FALSE
	if(net_amount)
		to_account.adjust_money(net_amount, reason)
	var/datum/bank_account/government = cy_get_government_account()
	if(tax_amount && government && government != to_account)
		government.adjust_money(tax_amount, "Налог: [reason]")
	var/operator_name = operator ? operator.name : null
	cy_record_transaction(from_account, to_account, amount, reason, visibility, channel, operator_name, source, tax_amount, service_fee)
	SSblackbox.record_feedback("amount", "cy_city_credits_transferred", amount)
	return TRUE

/datum/controller/subsystem/economy/proc/cy_record_transaction(datum/bank_account/from_account, datum/bank_account/to_account, amount, reason, visibility, channel, operator_name, atom/source, tax_amount = 0, service_fee = 0)
	var/datum/cy_city_transaction/transaction = new(from_account, to_account, amount, reason, visibility, channel, operator_name, source, tax_amount, service_fee)
	if(to_account?.cy_shadow_bank || from_account?.cy_shadow_bank || visibility == CY_ECON_VISIBILITY_SHADOW)
		transaction.shadow_bank_id = CY_ACCOUNT_BLACK_MARKET
	if(LAZYLEN(cy_city_ledger) >= CY_CITY_LEDGER_MAX_ENTRIES)
		cy_city_ledger.Cut(1, 2)
	cy_city_ledger += transaction
	return transaction

/datum/controller/subsystem/economy/proc/cy_route_vendor_sale(datum/bank_account/customer, obj/machinery/vending/vendor, amount, product_name)
	var/datum/bank_account/corp_account = cy_account_for_vendor(vendor)
	if(!corp_account)
		return FALSE
	var/datum/bank_account/department_account = get_dep_account(vendor.payment_department)
	if(department_account && department_account != corp_account && department_account.account_balance >= amount)
		cy_transfer_money(department_account, corp_account, amount, "Выручка автомата: [product_name || vendor.name]", CY_TAX_VENDOR, CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_VENDOR, null, vendor)
	else
		cy_record_transaction(customer, corp_account, amount, "Выручка автомата: [product_name || vendor.name]", CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_VENDOR, null, vendor, round(amount * CY_CITY_VENDOR_TAX_RATE), 0)
	cy_register_supply_signal(vendor.payment_department, amount, 1)
	return TRUE

/datum/controller/subsystem/economy/proc/cy_register_supply_signal(category, value = 1, quality = 1)
	var/key = "[category || CY_SUPPLY_GENERAL]"
	var/current = cy_supply_pressure[key] || 0
	cy_supply_pressure[key] = max(0, current + max(1, value) * max(1, quality))
	return cy_supply_pressure[key]

/datum/controller/subsystem/economy/proc/cy_export_value(category, datum/bank_account/payee, amount, reason = "Экспорт")
	if(!payee)
		return FALSE
	amount = max(0, round(amount))
	if(amount <= 0)
		return FALSE
	var/datum/bank_account/export_pool = cy_get_city_account(CY_ACCOUNT_EXPORT_POOL)
	if(!export_pool)
		return FALSE
	// Export is the one intended external faucet. Keep the source visible and ledgered.
	if(export_pool.account_balance < amount)
		export_pool.adjust_money(amount, "Внешнее экспортное пополнение")
	cy_register_supply_signal(category, amount, 1)
	return cy_transfer_money(export_pool, payee, amount, reason, CY_TAX_NONE, CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_EXPORT)

/datum/controller/subsystem/economy/proc/cy_get_price_pressure(category)
	var/supply = cy_supply_pressure["[category || CY_SUPPLY_GENERAL]"] || 0
	if(supply <= 0)
		return CY_CITY_DEFAULT_PRICE_MULTIPLIER
	return clamp(CY_CITY_DEFAULT_PRICE_MULTIPLIER - (supply / CY_CITY_SUPPLY_PRICE_DIVISOR), CY_CITY_MIN_PRICE_MULTIPLIER, CY_CITY_DEFAULT_PRICE_MULTIPLIER)

/datum/controller/subsystem/economy/proc/cy_get_vending_price_multiplier(obj/machinery/vending/vendor)
	if(!cy_city_economy_ready)
		cy_init_city_economy()
	return cy_get_price_pressure(vendor ? vendor.payment_department : CY_SUPPLY_GENERAL)

/datum/controller/subsystem/economy/proc/cy_open_loan(datum/bank_account/lender, datum/bank_account/borrower, amount, interest_percent = 0, due_time = 0, collateral = null, visibility = CY_ECON_VISIBILITY_BANK)
	if(!lender || !borrower || amount <= 0)
		return null
	if(!cy_transfer_money(lender, borrower, amount, "Выдача ссуды", CY_TAX_LOAN, visibility, CY_ECON_CHANNEL_LOAN))
		return null
	var/datum/cy_city_loan/loan = new(lender, borrower, amount, interest_percent, due_time, collateral, visibility)
	cy_city_loans[loan.id] = loan
	borrower.account_debt += loan.outstanding
	return loan

/datum/controller/subsystem/economy/proc/cy_seed_default_laws()
	if(length(cy_city_laws))
		return
	cy_city_laws[CY_LAW_ASSAULT] = new /datum/cy_city_law(CY_LAW_ASSAULT, "Нападение", "Насильственное воздействие на гражданина, сотрудника корпорации или государственный персонал.", 500, 0, CY_CRIME_SEVERITY_MEDIUM)
	cy_city_laws[CY_LAW_THEFT] = new /datum/cy_city_law(CY_LAW_THEFT, "Кража", "Незаконное присвоение имущества, груза, корпоративной собственности или личных вещей.", 400, 0, CY_CRIME_SEVERITY_MEDIUM)
	cy_city_laws[CY_LAW_SABOTAGE] = new /datum/cy_city_law(CY_LAW_SABOTAGE, "Саботаж", "Повреждение инфраструктуры, механизмов, сетевых узлов, бизнеса или корпоративной собственности.", 1000, 5 MINUTES, CY_CRIME_SEVERITY_MAJOR)
	cy_city_laws[CY_LAW_MURDER] = new /datum/cy_city_law(CY_LAW_MURDER, "Убийство", "Ликвидация или выведение из раунда гражданина или охраняемой цели.", 2500, 15 MINUTES, CY_CRIME_SEVERITY_MAJOR)
	cy_city_laws[CY_LAW_NETCRIME] = new /datum/cy_city_law(CY_LAW_NETCRIME, "Сетевое преступление", "Незаконный демон, взлом, кража данных или цифровой саботаж.", 1200, 5 MINUTES, CY_CRIME_SEVERITY_MAJOR)
	cy_city_laws[CY_LAW_TRESPASS] = new /datum/cy_city_law(CY_LAW_TRESPASS, "Нарушение доступа", "Проникновение в зону без прав или криптографического ключа.", 300, 0, CY_CRIME_SEVERITY_MINOR)

	cy_city_laws[CY_LAW_CONTROLLED_ITEM] = new /datum/cy_city_law(CY_LAW_CONTROLLED_ITEM, "Controlled item", "Illegal carrying, sale or transfer of controlled combat, armor or black-market equipment.", 700, 0, CY_CRIME_SEVERITY_MEDIUM)

/datum/controller/subsystem/economy/proc/cy_generate_round_access_keys()
	cy_round_access_keys = list()
	cy_round_access_keys[CY_POLICE_DB_ACCESS] = "POL-[rand(100000,999999)]"
	cy_round_access_keys[CY_BOUNTY_HUNTER_ACCESS] = "BNT-[rand(100000,999999)]"
	cy_round_access_keys[CY_GOVERNMENT_LEDGER_ACCESS] = "GOV-[rand(100000,999999)]"
	return cy_round_access_keys

/datum/controller/subsystem/economy/proc/cy_character_key(mob/user, fallback_name = null)
	if(user?.ckey)
		return "ckey:[user.ckey]"
	var/name = fallback_name || user?.real_name || user?.name || "unknown"
	return "name:[lowertext(name)]"

/datum/controller/subsystem/economy/proc/cy_get_crime_record(target, create = TRUE)
	var/key
	var/name
	if(ismob(target))
		var/mob/M = target
		key = cy_character_key(M)
		name = M.real_name || M.name
	else
		name = "[target]"
		key = cy_character_key(null, name)
	var/datum/cy_city_crime_record/record = cy_city_crime_records[key]
	if(!record && create)
		record = new(key, name)
		cy_city_crime_records[key] = record
	return record

/datum/controller/subsystem/economy/proc/cy_issue_violation(target, law_id, details = "", issuer = "Система", fine = null, sentence_time = null, status = null)
	if(!cy_city_economy_ready)
		cy_init_city_economy()
	var/datum/cy_city_law/law = cy_city_laws[law_id]
	if(!law)
		law = cy_city_laws[CY_LAW_TRESPASS]
	var/actual_fine = isnull(fine) ? law.default_fine : fine
	var/actual_sentence = isnull(sentence_time) ? law.default_sentence : sentence_time
	var/actual_status = isnull(status) ? (actual_sentence ? CY_WARRANT_ARREST : CY_WARRANT_FINE) : status
	var/datum/cy_city_crime_record/record = cy_get_crime_record(target, TRUE)
	var/datum/cy_city_violation/violation = new(law.id, law.title, details || law.description, issuer, actual_fine, actual_sentence, actual_status)
	record.violations += violation
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_LAW, max(1, law.severity * 2), violation)
	if(law_id in list(CY_LAW_ASSAULT, CY_LAW_MURDER, CY_LAW_SABOTAGE))
		SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_VIOLENCE, max(2, law.severity * 3), violation)
	return violation

/datum/controller/subsystem/economy/proc/cy_pay_violation(target, violation_id, datum/bank_account/payer, amount)
	var/datum/cy_city_crime_record/record = cy_get_crime_record(target, FALSE)
	if(!record || !payer)
		return FALSE
	for(var/datum/cy_city_violation/violation as anything in record.violations)
		if(violation.id != violation_id)
			continue
		amount = min(amount, violation.fine_remaining)
		if(!cy_transfer_money(payer, cy_get_government_account(), amount, "Оплата штрафа: [violation.law_title]", CY_TAX_NONE, CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_FINE))
			return FALSE
		return violation.pay(amount)
	return FALSE

/datum/controller/subsystem/economy/proc/cy_mark_sentence_served(target, violation_id = null, roundend = FALSE)
	var/datum/cy_city_crime_record/record = cy_get_crime_record(target, FALSE)
	if(!record)
		return FALSE
	var/changed = FALSE
	for(var/datum/cy_city_violation/violation as anything in record.violations)
		if(violation_id && violation.id != violation_id)
			continue
		if(violation.sentence_time <= 0)
			continue
		violation.served = TRUE
		violation.served_at_roundend = roundend
		if(violation.fine_remaining <= 0)
			violation.active = FALSE
			violation.status = CY_WARRANT_CLEARED
		violation.log += "[round_timestamp("hh:mm")]: sentence served[roundend ? " at round end" : ""]."
		changed = TRUE
	return changed

/datum/controller/subsystem/economy/proc/cy_add_forensic_trace(mob/user, atom/source, action = "interaction", quality = 100)
	if(!user || !source)
		return null
	var/datum/cy_city_forensic_trace/trace = new(user, source, action, quality)
	if(LAZYLEN(cy_city_forensic_traces) >= CY_CITY_FORENSIC_MAX_TRACES)
		cy_city_forensic_traces.Cut(1, 2)
	cy_city_forensic_traces += trace
	var/datum/cy_city_crime_record/record = cy_get_crime_record(user, TRUE)
	record.forensic_traces += trace
	return trace

/datum/controller/subsystem/economy/proc/cy_account_for_item(obj/item/item)
	if(!item)
		return cy_get_city_account(CY_ACCOUNT_CIV_MARKET)
	switch(item.get_cy_market_category())
		if(CY_ITEM_MARKET_BLACK)
			return cy_get_city_account(CY_ACCOUNT_BLACK_MARKET)
		if(CY_ITEM_MARKET_CONTROLLED)
			return cy_get_city_account(CY_ACCOUNT_RYAZNOV)
	return cy_get_city_account(CY_ACCOUNT_CIV_MARKET)

/datum/controller/subsystem/economy/proc/cy_get_item_market_price(obj/item/item, market_category = null)
	if(!item)
		return 0
	var/category = market_category || item.get_cy_market_category()
	var/multiplier = cy_get_price_pressure(category)
	switch(category)
		if(CY_ITEM_MARKET_CONTROLLED)
			multiplier *= 1.25
		if(CY_ITEM_MARKET_BLACK)
			multiplier *= 1.75
	return max(1, round(item.get_cy_market_value() * multiplier))

/datum/controller/subsystem/economy/proc/cy_record_item_transfer(mob/seller, mob/buyer, obj/item/item, datum/bank_account/buyer_account = null, datum/bank_account/seller_account = null, legal = TRUE)
	if(!item)
		return FALSE
	if(!cy_city_economy_ready)
		cy_init_city_economy()
	var/category = item.get_cy_market_category()
	var/price = cy_get_item_market_price(item, category)
	var/datum/bank_account/market_account = cy_account_for_item(item)
	var/visibility = legal && category != CY_ITEM_MARKET_BLACK ? CY_ECON_VISIBILITY_BANK : CY_ECON_VISIBILITY_SHADOW
	if(buyer_account && seller_account)
		if(!cy_transfer_money(buyer_account, seller_account, price, "Item transfer: [item.name]", CY_TAX_TRANSFER, visibility, CY_ECON_CHANNEL_BANK, buyer, item))
			return FALSE
	else
		cy_record_transaction(buyer_account, seller_account || market_account, price, "Item transfer: [item.name]", visibility, CY_ECON_CHANNEL_BANK, buyer?.name, item)
	cy_register_supply_signal(category, price, item.cy_quality)
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_ECONOMY, max(1, round(price / 100)), item)
	if(category == CY_ITEM_MARKET_CONTROLLED)
		SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_CORPORATE, max(1, round(price / 150)), item)
	else if(category == CY_ITEM_MARKET_BLACK)
		SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_BLACK_MARKET, max(2, round(price / 100)), item)
	if(!legal || category == CY_ITEM_MARKET_BLACK)
		if(seller)
			cy_issue_violation(seller, CY_LAW_CONTROLLED_ITEM, "Illegal transfer of [item.name].", "Market audit", null, null, CY_WARRANT_INVESTIGATION)
		if(buyer)
			cy_issue_violation(buyer, CY_LAW_CONTROLLED_ITEM, "Illegal acquisition of [item.name].", "Market audit", null, null, CY_WARRANT_INVESTIGATION)
	return TRUE

/datum/controller/subsystem/economy/proc/cy_log_demon_use(mob/user, datum/cy_demon/demon, atom/target, origin = null, civic = FALSE, corporation_id = null)
	var/details = "Демон [demon || "unknown"] used on [target || "unknown target"]."
	var/issuer = civic ? "Правительственный сетевой журнал" : "Корпоративный сетевой журнал"
	var/datum/cy_city_violation/violation = cy_issue_violation(user, CY_LAW_NETCRIME, details, issuer, null, null, CY_WARRANT_INVESTIGATION)
	if(corporation_id)
		cy_record_transaction(null, cy_get_city_account(corporation_id), 0, "Сетевой лог: [details]", CY_ECON_VISIBILITY_RESTRICTED, CY_ECON_CHANNEL_NETLOG, user?.name, target)
	return violation

/atom/proc/cy_leave_forensic_trace(mob/user, action = "interaction", quality = 100)
	if(!SSeconomy)
		return null
	return SSeconomy.cy_add_forensic_trace(user, src, action, quality)

/datum/cy_demon/proc/cy_log_economic_legal_use(mob/user, atom/target, civic = FALSE, corporation_id = null)
	if(!SSeconomy)
		return null
	return SSeconomy.cy_log_demon_use(user, src, target, null, civic, corporation_id)
