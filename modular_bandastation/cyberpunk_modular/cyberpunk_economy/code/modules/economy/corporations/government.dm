//CYBERPUNK CORPORATIONS - government monitoring helpers.

/obj/item/circuitboard/machine/cyberpunk_bank_server
	name = "правительственный банковский сервер"
	build_path = /obj/machinery/cyberpunk_bank_server
	req_components = list(
		/datum/stock_part/capacitor = 2,
		/datum/stock_part/micro_laser = 1,
	)

/obj/machinery/cyberpunk_bank_server
	name = "правительственный банковский сервер"
	desc = "Серверный узел, хранящий реестры личных, корпоративных и коммерческих счетов города."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "RD-server-on"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/machine/cyberpunk_bank_server
	req_access = list("government:all")
	var/list/account_registry = list()
	var/list/department_registry = list()

/obj/machinery/cyberpunk_bank_server/LateInitialize()
	. = ..()
	if(!SSeconomy.cyberpunk_bank_server)
		account_registry = SSeconomy.bank_accounts_by_id
		department_registry = SSeconomy.departmental_accounts
		SSeconomy.bank_accounts_by_id = null
		SSeconomy.departmental_accounts = null
		SSeconomy.cyberpunk_bank_server = src
		SSeconomy.cyberpunk_bank_server_configured = TRUE
		if(length(SSeconomy.cyberpunk_pending_credits))
			START_PROCESSING(SSobj, src)

/obj/machinery/cyberpunk_bank_server/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/cyberpunk_bank_server/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/cyberpunk_bank_server/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/cyberpunk_bank_server/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(SSeconomy.cyberpunk_bank_server == src)
		SSeconomy.bank_accounts_by_id = account_registry
		SSeconomy.departmental_accounts = department_registry
		SSeconomy.cyberpunk_bank_server = null
	account_registry = null
	department_registry = null
	return ..()

/obj/machinery/cyberpunk_bank_server/process(seconds_per_tick)
	if(!length(SSeconomy.cyberpunk_pending_credits))
		return PROCESS_KILL
	if(!is_operational)
		return
	var/list/pending = SSeconomy.cyberpunk_pending_credits
	SSeconomy.cyberpunk_pending_credits = list()
	for(var/list/entry as anything in pending)
		var/datum/weakref/account_ref = entry["account"]
		var/datum/bank_account/account = account_ref?.resolve()
		account?.adjust_money(entry["amount"], entry["reason"])
	return PROCESS_KILL

/datum/controller/subsystem/economy/proc/is_cyberpunk_bank_online()
	return !cyberpunk_bank_server_configured || cyberpunk_bank_server?.is_operational

/datum/controller/subsystem/economy/proc/get_bank_accounts()
	return cyberpunk_bank_server ? cyberpunk_bank_server.account_registry : bank_accounts_by_id

/datum/controller/subsystem/economy/proc/get_bank_departments()
	return cyberpunk_bank_server ? cyberpunk_bank_server.department_registry : departmental_accounts

/datum/controller/subsystem/economy/proc/queue_cyberpunk_bank_credit(datum/bank_account/account, amount, reason)
	cyberpunk_pending_credits += list(list("account" = WEAKREF(account), "amount" = amount, "reason" = reason))
	if(cyberpunk_bank_server)
		START_PROCESSING(SSobj, cyberpunk_bank_server)
	return TRUE

/datum/controller/subsystem/economy/proc/get_cyberpunk_bank_registry()
	return is_cyberpunk_bank_online() ? get_bank_accounts() : null

/obj/item/cyberpunk_council_emergency_chip
	name = "council emergency chip"
	desc = "Персональный чип для голосования о режиме ЧС и подписания директив совета."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "skillchip"
	w_class = WEIGHT_CLASS_TINY
	var/registered_council_key
	var/registered_council_name

/obj/structure/closet/secure_closet/cyberpunk_emergency_armory
	name = "оружейный шкаф ЧС"
	desc = "Шкаф с полицейским снаряжением. Доступен полиции при действующем режиме ЧС."
	anchored = TRUE
	req_one_access = list("city:police", "government:all")

/obj/structure/closet/secure_closet/cyberpunk_emergency_armory/PopulateContents()
	. = ..()
	new /obj/item/clothing/suit/armor/riot(src)
	new /obj/item/clothing/head/helmet/cyberpunk/plasteel(src)
	new /obj/item/shield/riot(src)
	new /obj/item/gun/energy/disabler(src)

/obj/structure/closet/secure_closet/cyberpunk_emergency_armory/togglelock(mob/living/user, silent)
	if(!SScyberpunk_corporations.cyberpunk_government_emergency_active)
		if(!silent)
			balloon_alert(user, "режим ЧС выключен")
		return TRUE
	return ..()

/obj/structure/closet/secure_closet/cyberpunk_emergency_armory/can_open(mob/living/user, force = FALSE)
	return (force || SScyberpunk_corporations.cyberpunk_government_emergency_active) && ..()

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_tax_monitor_ui()
	var/list/businesses = list()
	for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
		var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses[business_id]
		if(!business || !business.legal)
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
	var/list/bank_registry = SSeconomy.get_cyberpunk_bank_registry()
	for(var/account_id in bank_registry)
		var/datum/bank_account/account = bank_registry[account_id]
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
		"council" = get_cyberpunk_government_council_ui(),
	)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_council_ui()
	var/list/votes = list()
	var/yes_votes = 0
	for(var/voter_key in cyberpunk_government_emergency_chips)
		var/list/vote_record = cyberpunk_government_emergency_chips[voter_key]
		if(!islist(vote_record))
			continue
		votes += list(vote_record.Copy())
		if(vote_record["vote"])
			yes_votes++
	return list(
		"emergencyActive" = cyberpunk_government_emergency_active,
		"directive" = cyberpunk_government_directive,
		"pendingDirective" = cyberpunk_pending_government_directive,
		"directiveVotes" = length(cyberpunk_directive_votes),
		"yesVotes" = yes_votes,
		"noVotes" = length(votes) - yes_votes,
		"requiredVotes" = get_cyberpunk_government_emergency_required_chips(),
		"votes" = votes,
	)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_council_seats()
	return 7

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_emergency_required_chips()
	var/total_seats = get_cyberpunk_government_council_seats()
	var/required = 1
	while((required / total_seats) <= 0.75)
		required++
	return min(total_seats, required)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_voter_key(mob/user)
	var/mob/living/living_user = user
	if(!istype(living_user))
		return null
	var/datum/bank_account/account = living_user.get_bank_account()
	var/key = SSeconomy.get_cyberpunk_contract_character_key(living_user, account)
	return key || ckey(living_user.ckey || living_user.name)

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_voter_label(mob/user)
	var/mob/living/living_user = user
	if(!istype(living_user))
		return "unknown"
	if(living_user.has_cyberpunk_crypto_access("government:all"))
		return "[living_user.real_name || living_user.name] / government"
	if(living_user.has_cyberpunk_crypto_access("city:council"))
		return "[living_user.real_name || living_user.name] / council"
	for(var/corporation_id in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT))
		if(living_user.has_cyberpunk_crypto_access(cyberpunk_corporation_access_id(corporation_id, "head")))
			var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
			return "[living_user.real_name || living_user.name] / [corporation?.name || corporation_id]"
	return living_user.real_name || living_user.name

/datum/controller/subsystem/cyberpunk_corporations/proc/cast_cyberpunk_government_emergency_vote(mob/living/user, vote, obj/machinery/source_terminal, directive_ballot = FALSE)
	var/obj/item/cyberpunk_council_emergency_chip/chip = user?.get_active_held_item()
	return insert_cyberpunk_government_emergency_chip(user, chip, source_terminal, vote, directive_ballot)

/datum/controller/subsystem/cyberpunk_corporations/proc/insert_cyberpunk_government_emergency_chip(mob/living/user, obj/item/cyberpunk_council_emergency_chip/chip, obj/machinery/source_terminal, vote = TRUE, directive_ballot = FALSE)
	if(!istype(user) || !istype(chip) || !source_terminal?.is_operational || !user.is_holding(chip) || !user.can_perform_action(source_terminal, FORBID_TELEKINESIS_REACH))
		return FALSE
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	if(!government?.can_vote_council(user))
		return FALSE
	if(directive_ballot ? isnull(cyberpunk_pending_government_directive) : cyberpunk_government_emergency_active)
		return FALSE
	var/voter_key = get_cyberpunk_government_voter_key(user)
	if(!voter_key || chip.registered_council_key != voter_key)
		return FALSE
	var/datum/job/job = user.mind?.assigned_role
	var/seat = job?.get_cyberpunk_role_class() == "representative" ? job.get_cyberpunk_corporation_id() : null
	var/ballot_key = seat ? "corp:[seat]" : voter_key
	var/list/ballot = directive_ballot ? cyberpunk_directive_votes : cyberpunk_government_emergency_chips
	ballot[ballot_key] = list(
		"name" = get_cyberpunk_government_voter_label(user),
		"vote" = !!vote,
		"at" = round_timestamp(),
		"terminal" = get_area_name(source_terminal, TRUE),
	)
	var/approved = 0
	for(var/key in ballot)
		var/list/entry = ballot[key]
		if(entry["vote"])
			approved++
	var/required_chips = get_cyberpunk_government_emergency_required_chips()
	to_chat(user, span_notice("Чип принят. Голосов за [approved] из [required_chips]."))
	if(approved >= required_chips)
		if(directive_ballot)
			cyberpunk_government_directive = cyberpunk_pending_government_directive
			cyberpunk_pending_government_directive = null
			cyberpunk_directive_votes.Cut()
			government.add_history("Совет утвердил директиву: [cyberpunk_government_directive || "снята"]")
		else
			start_cyberpunk_government_emergency(user.real_name)
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/start_cyberpunk_government_emergency(actor = "council")
	if(cyberpunk_government_emergency_active)
		return FALSE
	cyberpunk_government_emergency_active = TRUE
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	government?.add_history("emergency mode activated by [actor]")
	var/datum/bank_account/civil = SSeconomy.get_dep_account(ACCOUNT_CIV)
	civil?.adjust_money(2500, "Government emergency policing budget")
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/end_cyberpunk_government_emergency(actor = "government")
	if(!cyberpunk_government_emergency_active)
		return FALSE
	cyberpunk_government_emergency_active = FALSE
	cyberpunk_government_emergency_votes.Cut()
	cyberpunk_government_emergency_chips.Cut()
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	government?.add_history("emergency mode ended by [actor]")
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/dispatch_cyberpunk_government_police(atom/target, mob/living/user, label_override)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE
	var/area/target_area = get_area(target_turf)
	var/dispatch_label = label_override || "[target_area?.name || "Unknown area"] ([target_turf.x], [target_turf.y], [target_turf.z])"
	var/player_count = 0
	for(var/mob/living/officer as anything in GLOB.player_list)
		if(!officer?.has_cyberpunk_crypto_access("city:police"))
			continue
		officer.cyberpunk_show_police_dispatch("DISPATCH: [dispatch_label]")
		player_count++
	var/npc_count = 0
	for(var/mob/living/carbon/human/cyberpunk_npc/security/security_npc as anything in GLOB.mob_living_list)
		if(!security_npc.ai_controller)
			continue
		if(cyberpunk_order_city_ai(security_npc, CP_AI_TASK_EMERGENCY_RESPONSE, user || target, target_turf, null))
			npc_count++
	cyberpunk_government_dispatch_history += list(list(
		"at" = round_timestamp(),
		"actor" = user?.name || "council terminal",
		"target" = dispatch_label,
		"players" = player_count,
		"npcs" = npc_count,
	))
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	government?.add_history("[user?.name || "council terminal"] dispatched police to [dispatch_label] ([player_count] players, [npc_count] NPCs)")
	to_chat(user, span_notice("Police dispatched to [dispatch_label]: [player_count] officers notified, [npc_count] NPC police routed."))
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/set_cyberpunk_government_directive(text, actor = "government")
	text = trim("[text]")
	if(length(text) > 240)
		text = copytext_char(text, 1, 241)
	if(!isnull(cyberpunk_pending_government_directive))
		return FALSE
	cyberpunk_pending_government_directive = text
	cyberpunk_directive_votes.Cut()
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	government?.add_history("[actor] submitted directive for approval: [text || "clear active directive"]")
	return TRUE

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
	for(var/area/area_type in typesof(/area/cyberpunk/city/district))
		var/area_path = "[area_type]"
		if(area_type == /area/cyberpunk/city/district)
			continue
		var/area_key = area_path
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

/datum/controller/subsystem/cyberpunk_corporations/proc/collect_cyberpunk_tax_debts(kind = "all", target = null, actor = "government terminal")
	kind = lowertext(trim("[kind]")) || "all"
	target = trim("[target]")
	var/collected_total = 0
	var/collected_count = 0
	if(kind in list("all", "corporation", "corp"))
		for(var/corporation_id in cyberpunk_corporations)
			if(corporation_id == CYBERPUNK_CORP_GOVERNMENT)
				continue
			if(target && cyberpunk_normalize_corporation_id(target) != corporation_id)
				continue
			var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
			var/datum/bank_account/account = corporation?.get_account()
			var/amount = min(corporation?.tax_debt || 0, max(0, round(account?.account_balance || 0)))
			if(amount <= 0 || !account.adjust_money(-amount, "Government tax collection: [actor]"))
				continue
			SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(amount, "Collected corporate tax: [corporation.name]")
			corporation.tax_debt -= amount
			corporation.tax_paid += amount
			corporation.add_history("[actor] collected tax debt [amount][MONEY_SYMBOL]")
			collected_total += amount
			collected_count++
	if(kind in list("all", "business"))
		for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
			if(target && "[business_id]" != target)
				continue
			var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses[business_id]
			if(!business || !business.legal)
				continue
			var/datum/bank_account/account = business.get_account()
			var/amount = min(business.tax_debt, max(0, round(account?.account_balance || 0)))
			if(!business.settle_tax_debt(amount, actor))
				continue
			collected_total += amount
			collected_count++
	if(collected_total)
		log_econ("Government collected [collected_total][MONEY_NAME] tax debt from [collected_count] debtor(s) by [actor].")
	return list("total" = collected_total, "count" = collected_count)

/datum/controller/subsystem/cyberpunk_corporations/proc/apply_cyberpunk_government_sanction(kind, target, sanction = "fine", actor = "government terminal")
	kind = lowertext(trim("[kind]"))
	target = trim("[target]")
	sanction = lowertext(trim("[sanction]")) || "fine"
	var/datum/cyberpunk_corporation/government = get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	switch(kind)
		if("corporation", "corp")
			var/corporation_id = cyberpunk_normalize_corporation_id(target)
			if(!corporation_id || corporation_id == CYBERPUNK_CORP_GOVERNMENT)
				return FALSE
			var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
			if(!corporation)
				return FALSE
			var/datum/bank_account/account = corporation.get_account()
			switch(sanction)
				if("audit")
					var/audit_debt = max(250, round(max(account?.account_balance || 0, corporation.tax_debt) * 0.05))
					corporation.tax_debt += audit_debt
					corporation.influence = max(0, corporation.influence - 5)
					corporation.add_history("[actor] issued government audit: +[audit_debt][MONEY_SYMBOL] tax debt")
				if("suspend")
					corporation.service_auto_enabled = FALSE
					corporation.influence = max(0, corporation.influence - 10)
					corporation.add_history("[actor] suspended automatic public services")
				else
					var/fine = max(500, round(max(corporation.tax_debt, account?.account_balance || 0) * 0.1))
					var/paid = min(fine, max(0, round(account?.account_balance || 0)))
					if(paid > 0 && account.adjust_money(-paid, "Government corporate sanction: [actor]"))
						SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(paid, "Corporate sanction: [corporation.name]")
						corporation.tax_paid += paid
					if(fine > paid)
						corporation.tax_debt += fine - paid
					corporation.influence = max(0, corporation.influence - 7)
					corporation.add_history("[actor] issued government fine: [paid][MONEY_SYMBOL] paid, [fine - paid][MONEY_SYMBOL] added to debt")
			government?.add_history("[actor] sanctioned [corporation.name]: [sanction]")
			log_econ("Government sanction '[sanction]' applied to corporation [corporation.name] by [actor].")
			return TRUE
		if("business")
			var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses["[target]"]
			if(!business)
				return FALSE
			var/datum/bank_account/account = business.get_account()
			switch(sanction)
				if("audit")
					var/audit_debt = max(150, round(max(account?.account_balance || 0, business.tax_debt) * 0.05))
					business.tax_debt += audit_debt
					business.add_history("[actor] issued government audit: +[audit_debt][MONEY_SYMBOL] tax debt")
				if("revoke")
					business.legal = FALSE
					business.registered_to = "registration revoked"
					business.add_history("[actor] revoked legal registration")
				else
					var/fine = max(250, round(max(business.tax_debt, account?.account_balance || 0) * 0.1))
					var/paid = min(fine, max(0, round(account?.account_balance || 0)))
					if(paid > 0 && account.adjust_money(-paid, "Government business sanction: [actor]"))
						SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(paid, "Business sanction: [business.name]")
						business.tax_paid += paid
					if(fine > paid)
						business.tax_debt += fine - paid
					business.add_history("[actor] issued government fine: [paid][MONEY_SYMBOL] paid, [fine - paid][MONEY_SYMBOL] added to debt")
			government?.add_history("[actor] sanctioned business [business.name]: [sanction]")
			log_econ("Government sanction '[sanction]' applied to business [business.name] by [actor].")
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_transfer_account(kind, account_key)
	var/list/bank_registry = SSeconomy.get_cyberpunk_bank_registry()
	if(!bank_registry)
		return null
	kind = lowertext(trim("[kind]"))
	switch(kind)
		if("account", "person", "player")
			return bank_registry?["[account_key]"]
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
