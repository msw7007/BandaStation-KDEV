//CYBERPUNK CORPORATIONS - subsystem-facing registry helpers.
/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporation(corporation_id)
	ensure_cyberpunk_corporations_seeded()
	return cyberpunk_corporations[cyberpunk_normalize_corporation_id(corporation_id)]

/datum/cyberpunk_corporation/proc/get_cyberpunk_share_buy_price()
	var/datum/bank_account/corporate_account = get_account()
	var/treasury_modifier = clamp(round(((corporate_account?.account_balance || 0) - tax_debt) / 1000), -20, 35)
	return max(10, 25 + 8 * (level - 1) + length(unlocked_technologies) * 2 + round(influence / 10) + treasury_modifier)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_share_market(datum/bank_account/account)
	var/list/rows = list()
	for(var/id in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT))
		var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(id)
		var/buy_price = corporation.get_cyberpunk_share_buy_price()
		rows += list(list(
			"id" = id,
			"name" = corporation.name,
			"buyPrice" = buy_price,
			"sellPrice" = max(1, round(buy_price * 0.9)),
			"available" = corporation.shares_available,
			"owned" = account.cyberpunk_share_holdings?[id] || 0,
			"level" = corporation.level,
		))
	return rows

/datum/controller/subsystem/cyberpunk_corporations/proc/trade_cyberpunk_shares(mob/living/user, datum/bank_account/account, issuer_id, amount, buying, shown_price)
	if(!istype(user) || QDELETED(account) || IS_DEPARTMENTAL_ACCOUNT(account) || istype(account, /datum/bank_account/cyberpunk_corporation))
		return FALSE
	var/area/current_area = get_area(user)
	if(current_area && is_area_virtual(current_area))
		return FALSE
	if(!isnum(amount) || amount != round(amount) || amount < 1 || amount > 300)
		return FALSE
	if(!(issuer_id in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT)))
		return FALSE

	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(issuer_id)
	var/buy_price = corporation.get_cyberpunk_share_buy_price()
	var/price = buying ? buy_price : max(1, round(buy_price * 0.9))
	if(shown_price != price)
		to_chat(user, span_warning("Котировка изменилась. Проверьте цену и подтвердите сделку снова."))
		return TRUE
	var/holding = account.cyberpunk_share_holdings?[issuer_id] || 0
	if((buying && amount > corporation.shares_available) || (!buying && amount > holding))
		to_chat(user, span_warning("Недостаточно акций для сделки."))
		return TRUE

	var/total = amount * price
	var/direction = buying ? 1 : -1
	if(!account.adjust_money(-direction * total, "Биржа: [buying ? "покупка" : "продажа"] [amount] × [corporation.name]"))
		to_chat(user, span_warning("На счёте недостаточно средств для покупки."))
		return TRUE
	LAZYINITLIST(account.cyberpunk_share_holdings)
	account.cyberpunk_share_holdings[issuer_id] = holding + direction * amount
	corporation.shares_available -= direction * amount
	to_chat(user, span_notice("Биржа: [buying ? "куплено" : "продано"] [amount] × [corporation.name] за [total] кр."))
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_normalize_corporation_id(corporation_id)
	var/corp_id = lowertext(trim("[corporation_id]"))
	switch(corp_id)
		if("benn", "ben", "bэн", "бэнь")
			return CYBERPUNK_CORP_BENN
		if("ryaznov", "riaznov", "рязнов")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight", "старлайт")
			return CYBERPUNK_CORP_STARLIGHT
		if("government", "gov", "nanotrasen", "правительство")
			return CYBERPUNK_CORP_GOVERNMENT
	return corp_id

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_public_corporation_names(include_government = FALSE)
	ensure_cyberpunk_corporations_seeded()
	var/list/names = list()
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation.hidden && !include_government)
			continue
		names += corporation.name
	return names

/datum/controller/subsystem/cyberpunk_corporations/proc/ensure_cyberpunk_corporations_seeded()
	if(cyberpunk_corporations_seeded)
		return
	cyberpunk_corporations_seeded = TRUE
	create_cyberpunk_corporation(CYBERPUNK_CORP_BENN)
	create_cyberpunk_corporation(CYBERPUNK_CORP_RYAZNOV)
	create_cyberpunk_corporation(CYBERPUNK_CORP_STARLIGHT)
	create_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)

/datum/controller/subsystem/cyberpunk_corporations/proc/create_cyberpunk_corporation(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	if(cyberpunk_corporations[corporation_id])
		return cyberpunk_corporations[corporation_id]
	var/datum/cyberpunk_corporation/corporation = new(corporation_id)
	corporation.ensure_account()
	cyberpunk_corporations[corporation_id] = corporation
	return corporation

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_corporate_activity(corporation_id, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	if(data_amount)
		corporation.add_data(data_type, data_amount, source)
	if(credit_amount)
		corporation.add_funds(credit_amount, source)
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_id_from_manufacturer(manufacturer)
	var/manufacturer_id = cyberpunk_normalize_corporation_id(manufacturer)
	if(cyberpunk_corporations[manufacturer_id])
		return manufacturer_id
	var/manufacturer_group = cyberpunk_major_corp_for_manufacturer(manufacturer)
	switch(manufacturer_group)
		if("ben")
			return CYBERPUNK_CORP_BENN
		if("ryaznov")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight")
			return CYBERPUNK_CORP_STARLIGHT
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation?.get_subsidiary_by_manufacturer(manufacturer_text))
			return corporation_id
	if(findtext(manufacturer_text, "benn") || findtext(manufacturer_text, "ben"))
		return CYBERPUNK_CORP_BENN
	if(findtext(manufacturer_text, "ryaznov") || findtext(manufacturer_text, "riaznov"))
		return CYBERPUNK_CORP_RYAZNOV
	if(findtext(manufacturer_text, "starlight"))
		return CYBERPUNK_CORP_STARLIGHT
	if(findtext(manufacturer_text, "government") || findtext(manufacturer_text, "nanotrasen"))
		return CYBERPUNK_CORP_GOVERNMENT
	return null

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_has_edict(corporation_id, edict_id)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	return corporation?.has_edict(edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_manufacturer_has_edict(manufacturer, edict_id)
	return cyberpunk_corporation_has_edict(cyberpunk_corporation_id_from_manufacturer(manufacturer), edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_manufacturer_activity(manufacturer, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	return record_cyberpunk_corporate_activity(cyberpunk_corporation_id_from_manufacturer(manufacturer), data_type, data_amount, credit_amount, source)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporate_edict_multiplier(manufacturer, list/edict_ids, default_multiplier = 1, active_multiplier = 1.1)
	var/corporation_id = cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return default_multiplier
	for(var/edict_id in edict_ids)
		if(cyberpunk_corporation_has_edict(corporation_id, edict_id))
			return active_multiplier
	return default_multiplier

/proc/cyberpunk_property_edict_multiplier(atom/location, corporation_id, edict_id, active_multiplier = 1.1)
	if(!location || !SScyberpunk_corporations.cyberpunk_corporation_has_edict(corporation_id, edict_id))
		return 1
	if(corporation_id == CYBERPUNK_CORP_STARLIGHT && ismovable(location))
		if(recursive_loc_check(location, /obj/vehicle/sealed/car/cyberpunk) || recursive_loc_check(location, /obj/vehicle/ridden/cyberpunk/avi))
			return active_multiplier
	var/area/territory = get_area(location)
	var/owner_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(cyberpunk_corporate_area_id(location) || territory?.cyberpunk_world_owner)
	return owner_id == corporation_id ? active_multiplier : 1
