//CYBERPUNK CORPORATIONS - government monitoring helpers.

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_tax_monitor_ui()
	var/list/businesses = list()
	for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
		var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses[business_id]
		if(!business)
			continue
		businesses += list(list(
			"id" = business.id,
			"name" = business.name,
			"owner" = business.owner_name,
			"legal" = business.legal,
			"registeredTo" = business.registered_to,
			"taxDebt" = business.tax_debt,
			"taxPaid" = business.tax_paid,
			"balance" = business.get_account()?.account_balance || 0,
			"debt" = business.get_account()?.account_debt || 0,
			"area" = business.get_business_area()?.name || "none",
			"taxRate" = round(get_cyberpunk_business_tax_rate(business.id) * 100),
			"overdue" = business.tax_debt > 0,
		))
	var/list/corporations = list()
	for(var/corporation_id in cyberpunk_corporations)
		if(corporation_id == CYBERPUNK_CORP_GOVERNMENT)
			continue
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(!corporation)
			continue
		corporations += list(list(
			"id" = corporation.id,
			"name" = corporation.name,
			"taxDebt" = corporation.tax_debt,
			"taxPaid" = corporation.tax_paid,
			"balance" = corporation.get_account()?.account_balance || 0,
			"debt" = corporation.get_account()?.account_debt || 0,
			"taxRate" = round(get_cyberpunk_corporation_tax_rate(corporation.id) * 100),
			"overdue" = corporation.tax_debt > 0,
		))
	var/list/accounts = list()
	for(var/account_id in SSeconomy.bank_accounts_by_id)
		var/datum/bank_account/account = SSeconomy.bank_accounts_by_id[account_id]
		if(!account)
			continue
		accounts += list(list(
			"id" = account.account_id,
			"name" = account.account_holder,
			"balance" = account.account_balance,
			"debt" = account.account_debt,
		))
	var/list/housing = get_cyberpunk_government_housing_tax_ui()
	return list(
		"businesses" = businesses,
		"corporations" = corporations,
		"accounts" = accounts,
		"housing" = housing,
		"businessDefaultTaxRate" = round(get_cyberpunk_business_tax_rate() * 100),
	)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporation_tax_rate(corporation_id)
	if(corporation_id && isnum(cyberpunk_corporation_tax_rates["[corporation_id]"]))
		return clamp(cyberpunk_corporation_tax_rates["[corporation_id]"], 0, 1)
	return CYBERPUNK_CORP_TAX_RATE

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_business_tax_rate(business_id = null)
	if(isnum(cyberpunk_business_default_tax_rate))
		return clamp(cyberpunk_business_default_tax_rate, 0, 1)
	var/default_rate = 0.05
	return default_rate

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_housing_rent(area_key)
	if(area_key && isnum(cyberpunk_housing_rent_by_area["[area_key]"]))
		return max(0, round(cyberpunk_housing_rent_by_area["[area_key]"]))
	return 0

/datum/controller/subsystem/cyberpunk_corporations/proc/set_cyberpunk_tax_setting(kind, target, value)
	kind = lowertext(trim("[kind]"))
	target = trim("[target]")
	switch(kind)
		if("corporation")
			var/corporation_id = cyberpunk_normalize_corporation_id(target)
			if(!corporation_id || corporation_id == CYBERPUNK_CORP_GOVERNMENT)
				return FALSE
			cyberpunk_corporation_tax_rates[corporation_id] = clamp(round(value, 0.01), 0, 100) / 100
			return TRUE
		if("business")
			cyberpunk_business_default_tax_rate = clamp(round(value, 0.01), 0, 100) / 100
			return TRUE
		if("business_default")
			cyberpunk_business_default_tax_rate = clamp(round(value, 0.01), 0, 100) / 100
			return TRUE
		if("housing")
			if(!target)
				return FALSE
			cyberpunk_housing_rent_by_area[target] = clamp(round(value), 0, 1000000)
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_housing_area_label(area_key)
	var/area/area_type = text2path(area_key)
	if(ispath(area_type, /area))
		return initial(area_type.cyberpunk_district_name) || initial(area_type.name) || area_key
	return area_key

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_apartment_housing_area_key(datum/cyberpunk_apartment/apartment)
	var/area/apartment_area = apartment?.get_apartment_area()
	if(apartment_area?.cyberpunk_district_id)
		return "[apartment_area.type]"
	return "[apartment?.apartment_area_type]"

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_housing_tax_ui()
	var/list/housing_by_area = list()
	for(var/area/area_type in typesof(/area/cyberpunk_city/district))
		if(area_type == /area/cyberpunk_city/district)
			continue
		var/area_key = "[area_type]"
		housing_by_area[area_key] = list(
			"areaKey" = area_key,
			"area" = get_cyberpunk_housing_area_label(area_key),
			"rent" = get_cyberpunk_housing_rent(area_key),
			"apartments" = 0,
		)
	for(var/apartment_id in SScyberpunk_property.cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.cyberpunk_apartments[apartment_id]
		if(!apartment)
			continue
		var/area_key = get_cyberpunk_apartment_housing_area_key(apartment)
		var/list/entry = housing_by_area[area_key]
		if(!entry)
			entry = list(
				"areaKey" = area_key,
				"area" = get_cyberpunk_housing_area_label(area_key),
				"rent" = get_cyberpunk_housing_rent(area_key),
				"apartments" = 0,
			)
			housing_by_area[area_key] = entry
		entry["apartments"] = (entry["apartments"] || 0) + 1
	for(var/area_key in cyberpunk_housing_rent_by_area)
		if(housing_by_area[area_key])
			continue
		housing_by_area[area_key] = list(
			"areaKey" = area_key,
			"area" = get_cyberpunk_housing_area_label(area_key),
			"rent" = get_cyberpunk_housing_rent(area_key),
			"apartments" = 0,
		)
	var/list/housing = list()
	for(var/area_key in housing_by_area)
		housing += list(housing_by_area[area_key])
	return housing

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_apartment_owner_account(datum/cyberpunk_apartment/apartment)
	if(!apartment?.owner_character_key)
		return null
	for(var/mob/living/person as anything in GLOB.player_list)
		var/datum/bank_account/account = person.get_bank_account()
		if(SScyberpunk_property.get_cyberpunk_business_key(person, account) == apartment.owner_character_key)
			return account
	return null

/datum/controller/subsystem/cyberpunk_corporations/proc/charge_cyberpunk_housing_rent(area_key, actor = "government terminal")
	area_key = trim("[area_key]")
	var/charged = 0
	var/total = 0
	for(var/apartment_id in SScyberpunk_property.cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.cyberpunk_apartments[apartment_id]
		if(!apartment)
			continue
		var/current_area_key = get_cyberpunk_apartment_housing_area_key(apartment)
		if(area_key && current_area_key != area_key)
			continue
		var/rent = get_cyberpunk_housing_rent(current_area_key)
		if(rent <= 0)
			continue
		var/datum/bank_account/account = get_cyberpunk_apartment_owner_account(apartment)
		if(!account || !account.adjust_money(-rent, "Government apartment rent: [apartment.name]"))
			continue
		SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(rent, "Apartment rent: [apartment.name]")
		apartment.add_history("government rent charged by [actor]: [rent][MONEY_SYMBOL]")
		charged++
		total += rent
	if(total)
		log_econ("Government charged apartment rent [total][MONEY_NAME] from [charged] apartment owner(s) by [actor].")
	return list("charged" = charged, "total" = total)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_transfer_account(kind, account_key)
	kind = lowertext(trim("[kind]"))
	switch(kind)
		if("account", "person", "player")
			return SSeconomy.bank_accounts_by_id["[account_key]"]
		if("corporation", "corp")
			var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(account_key)
			return corporation?.get_account()
		if("business")
			var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses["[account_key]"]
			return business?.get_account()
		if("civil", "government")
			return SSeconomy.get_dep_account(ACCOUNT_CIV)
	return null

/datum/controller/subsystem/cyberpunk_corporations/proc/force_cyberpunk_government_transfer(source_kind, source_key, target_kind, target_key, amount, actor = "government terminal")
	amount = max(0, round(amount))
	if(amount <= 0)
		return FALSE
	var/datum/bank_account/source_account = get_cyberpunk_government_transfer_account(source_kind, source_key)
	var/datum/bank_account/target_account = get_cyberpunk_government_transfer_account(target_kind, target_key)
	if(!source_account || !target_account || source_account == target_account)
		return FALSE
	var/transfer_amount = min(amount, max(0, source_account.account_balance))
	if(transfer_amount <= 0)
		return FALSE
	if(!source_account.adjust_money(-transfer_amount, "Government seizure: [actor]"))
		return FALSE
	if(!target_account.adjust_money(transfer_amount, "Government transfer: [actor]"))
		source_account.adjust_money(transfer_amount, "Government transfer rollback")
		return FALSE
	log_econ("Government forced [transfer_amount][MONEY_NAME] from [source_account.account_holder] to [target_account.account_holder] by [actor].")
	return TRUE
