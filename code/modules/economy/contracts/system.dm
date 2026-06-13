//CYBERPUNK BUILD - rebuild and delete before release

#define CYBERPUNK_CONTRACT_STATS_FILE "data/cyberpunk_contract_stats.json"

/datum/controller/subsystem/economy/proc/load_cyberpunk_contract_stats()
	if(!cyberpunk_contract_stats_database)
		cyberpunk_contract_stats_database = new(CYBERPUNK_CONTRACT_STATS_FILE)
	var/list/stored_stats = cyberpunk_contract_stats_database.get()
	if(islist(stored_stats))
		cyberpunk_contract_stats = stored_stats


/datum/controller/subsystem/economy/proc/save_cyberpunk_contract_stats(ckey)
	if(!cyberpunk_contract_stats_database)
		cyberpunk_contract_stats_database = new(CYBERPUNK_CONTRACT_STATS_FILE)
	ckey = ckey(ckey)
	if(!ckey)
		return
	cyberpunk_contract_stats_database.set_key(ckey, cyberpunk_contract_stats[ckey] || get_cyberpunk_contract_stats(ckey))


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract(contract_id)
	return cyberpunk_contracts["[contract_id]"]


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_character_key(mob/living/person, datum/bank_account/account)
	var/name = account?.account_holder || person?.real_name || person?.name
	return ckey(name)


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_stats(ckey)
	ckey = ckey(ckey)
	if(!ckey)
		return list("created" = 0, "accepted" = 0, "completed" = 0, "failed" = 0, "cancelled" = 0, "open" = 0, "success_percent" = 0)
	if(!cyberpunk_contract_stats[ckey])
		cyberpunk_contract_stats[ckey] = list("created" = 0, "accepted" = 0, "completed" = 0, "failed" = 0, "cancelled" = 0)
	var/list/stats = cyberpunk_contract_stats[ckey]
	for(var/stat_key in list("created", "accepted", "completed", "failed", "cancelled"))
		if(isnull(stats[stat_key]))
			stats[stat_key] = 0
	stats["open"] = max(0, (stats["accepted"] || 0) - (stats["completed"] || 0) - (stats["failed"] || 0) - (stats["cancelled"] || 0))
	var/closed = (stats["completed"] || 0) + (stats["failed"] || 0)
	stats["success_percent"] = closed > 0 ? round((stats["completed"] || 0) / closed * 100) : 0
	return stats


/datum/controller/subsystem/economy/proc/adjust_cyberpunk_contract_stat(ckey, stat_key, amount = 1)
	var/list/stats = get_cyberpunk_contract_stats(ckey)
	stats[stat_key] = (stats[stat_key] || 0) + amount
	save_cyberpunk_contract_stats(ckey)


/datum/controller/subsystem/economy/proc/find_cyberpunk_contract_person(character_name)
	var/character_key = ckey(character_name)
	if(!character_key)
		return null
	for(var/mob/living/person as anything in GLOB.player_list)
		if(get_cyberpunk_contract_character_key(person, person.get_bank_account()) == character_key)
			return person
	return null


/datum/controller/subsystem/economy/proc/ensure_cyberpunk_contract_pool_seeded()
	if(cyberpunk_contract_pool_seeded)
		return
	cyberpunk_contract_pool_seeded = TRUE
	var/list/corporations = SScyberpunk_corporations.get_cyberpunk_public_corporation_names()
	for(var/corporation in corporations)
		var/contract_count = rand(3, 4)
		for(var/i in 1 to contract_count)
			create_cyberpunk_generated_pool_contract(corporation)


/datum/controller/subsystem/economy/proc/create_cyberpunk_generated_pool_contract(corporation)
	var/contract_type = pick(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_REPAIR, CYBERPUNK_CONTRACT_BUILD, CYBERPUNK_CONTRACT_MINING, CYBERPUNK_CONTRACT_SABOTAGE)
	var/target = "work order"
	var/description = "Corporate pool work order. Details are intentionally brief for the first production pass."
	var/required_amount = 1
	var/required_percent = 75
	switch(contract_type)
		if(CYBERPUNK_CONTRACT_DELIVERY)
			target = pick("sealed packet", "data disk", "medical crate", "machine component")
			description = "Deliver the marked cargo to the corporate representative."
		if(CYBERPUNK_CONTRACT_REPAIR)
			target = pick("door", "machine", "terminal", "generator")
			description = "Restore the target above the required integrity threshold."
			required_percent = rand(65, 90)
		if(CYBERPUNK_CONTRACT_BUILD)
			target = pick("barricade", "table", "window", "structure")
			description = "Build the requested structure in the assigned area."
		if(CYBERPUNK_CONTRACT_MINING)
			target = pick("ore", "glass", "metal", "plasma")
			description = "Submit the requested resource stack."
			required_amount = rand(3, 8)
		if(CYBERPUNK_CONTRACT_SABOTAGE)
			target = pick("door", "camera", "terminal", "machine")
			description = "Damage or disable the target to the required threshold."
			required_percent = rand(0, 40)

	var/datum/cyberpunk_contract/contract = new
	contract.id = next_cyberpunk_contract_id++
	contract.title = "[corporation] pool job #[contract.id]"
	contract.description = description
	contract.contract_type = contract_type
	contract.target_text = target
	contract.creator_name = corporation
	contract.creator_character_key = ckey("corp-[corporation]")
	contract.payment = rand(150, 650)
	contract.deposit = rand(0, 2) ? 0 : rand(25, 100)
	contract.penalty = rand(0, 2) ? 0 : rand(25, 100)
	contract.escrow_payment = contract.payment
	contract.legal = TRUE
	contract.public_contract = TRUE
	contract.pool_contract = TRUE
	contract.pool_corporation = corporation
	contract.generated_pool_contract = TRUE
	contract.required_amount = required_amount
	contract.required_percent = required_percent
	contract.direct_access_code = uppertext(random_string(8, GLOB.hex_characters))
	contract.due_time = world.time + rand(35, 90) MINUTES
	contract.created_at = world.time
	contract.setup_default_condition()
	contract.add_history("generated by [corporation] corporate pool; [contract.payment][MONEY_SYMBOL] reserved")
	cyberpunk_contracts["[contract.id]"] = contract
	addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/cyberpunk_contract, timeout_check)), contract.due_time - world.time, TIMER_STOPPABLE)
	return contract


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_pool()
	ensure_cyberpunk_contract_pool_seeded()
	var/list/contracts = list()
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(contract?.pool_contract && contract.status == CYBERPUNK_CONTRACT_CREATED)
			contracts += contract
	return contracts


/datum/controller/subsystem/economy/proc/create_cyberpunk_contract(mob/living/creator, list/params)
	var/datum/bank_account/creator_account = creator?.get_bank_account()
	if(!creator_account)
		return null
	var/datum/cyberpunk_business/funding_business
	var/funding_business_id = text2num(params["funding_business_id"])
	if(funding_business_id)
		funding_business = SScyberpunk_property.get_cyberpunk_business(funding_business_id)
		if(!funding_business?.has_access(creator, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS))
			return null
		creator_account = funding_business.get_account()
		if(!creator_account)
			return null

	var/payment = max(0, round(text2num(params["payment"])))
	var/deposit = max(0, round(text2num(params["deposit"])))
	var/penalty = max(0, round(text2num(params["penalty"])))
	var/is_legal = text2num(params["legal"]) ? TRUE : FALSE
	if(payment <= 0 || !creator_account.has_money(payment))
		return null

	var/contract_type = params["contract_type"] || CYBERPUNK_CONTRACT_DELIVERY
	var/static/list/valid_contract_types = list(
		CYBERPUNK_CONTRACT_DELIVERY,
		CYBERPUNK_CONTRACT_REPAIR,
		CYBERPUNK_CONTRACT_BUILD,
		CYBERPUNK_CONTRACT_GUARD,
		CYBERPUNK_CONTRACT_MINING,
		CYBERPUNK_CONTRACT_SABOTAGE,
		CYBERPUNK_CONTRACT_ELIMINATION,
	)
	if(!(contract_type in valid_contract_types))
		contract_type = CYBERPUNK_CONTRACT_DELIVERY

	var/title = reject_bad_text(params["title"], max_length = 48, ascii_only = FALSE)
	var/target = reject_bad_text(params["target"], max_length = 64, ascii_only = FALSE)
	var/description = reject_bad_text(params["description"], max_length = 240, ascii_only = FALSE)
	var/assigned_contractor = reject_bad_text(params["assigned_contractor"], max_length = 64, ascii_only = FALSE)
	var/pool_contract = text2num(params["pool_contract"]) ? TRUE : FALSE
	var/pool_corporation = reject_bad_text(params["pool_corporation"], max_length = 64, ascii_only = FALSE)
	var/reserve_held = text2num(params["reserve_held"]) ? TRUE : FALSE
	var/obj/item/reserved_item
	if(reserve_held)
		if(contract_type != CYBERPUNK_CONTRACT_DELIVERY)
			return null
		reserved_item = creator.get_active_held_item()
		if(!reserved_item)
			return null
		if(!target)
			target = reserved_item.name
	if(!title)
		title = "Contract #[next_cyberpunk_contract_id]"
	if(!target)
		target = "unspecified target"

	var/escrow_reason = is_legal ? "Legal contract escrow: [title]" : "Off-ledger contract escrow: [title]"
	if(!creator_account.adjust_money(-payment, escrow_reason))
		return null

	var/datum/cyberpunk_contract/contract = new
	contract.id = next_cyberpunk_contract_id++
	contract.title = title
	contract.description = description
	contract.contract_type = contract_type
	contract.target_text = target
	contract.creator_ckey = creator.ckey
	contract.creator_name = funding_business ? funding_business.name : (creator.real_name || creator.name)
	contract.creator_account_id = creator_account.account_id
	contract.creator_character_key = funding_business ? "business:[funding_business.id]" : get_cyberpunk_contract_character_key(creator, creator_account)
	contract.creator_business_id = funding_business?.id || 0
	contract.assigned_contractor_name = assigned_contractor
	contract.assigned_contractor_key = ckey(assigned_contractor)
	contract.payment = payment
	contract.deposit = deposit
	contract.penalty = penalty
	contract.escrow_payment = payment
	contract.legal = is_legal
	contract.public_contract = text2num(params["public_contract"]) ? TRUE : FALSE
	contract.pool_contract = pool_contract
	contract.pool_corporation = pool_corporation
	contract.creator_confirm_required = text2num(params["creator_confirm_required"]) ? TRUE : FALSE
	contract.required_amount = max(1, round(text2num(params["required_amount"]) || 1))
	contract.required_percent = clamp(round(text2num(params["required_percent"]) || 75), 0, 100)
	contract.direct_access_code = uppertext(random_string(8, GLOB.hex_characters))
	contract.due_time = world.time + clamp(round(text2num(params["duration_minutes"]) || 30), 1, 180) MINUTES
	contract.created_at = world.time
	contract.setup_default_condition(params)
	contract.add_history("created by [contract.creator_name]; [payment][MONEY_SYMBOL] reserved from [funding_business ? "business" : "personal"] budget")
	if(assigned_contractor)
		contract.add_history("assigned contractor: [assigned_contractor]")
		contract.status = CYBERPUNK_CONTRACT_OFFERED
	if(pool_contract)
		contract.public_contract = TRUE
		contract.add_history("published into contract pool[pool_corporation ? " for [pool_corporation]" : ""]")
	if(reserved_item)
		reserved_item.cyberpunk_contract_id = contract.id
		contract.track_delivery_item(reserved_item)
		contract.add_history("[reserved_item.name] reserved as creator cargo")
	cyberpunk_contracts["[contract.id]"] = contract
	adjust_cyberpunk_contract_stat(contract.creator_character_key, "created")
	addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/cyberpunk_contract, timeout_check)), contract.due_time - world.time, TIMER_STOPPABLE)
	if(assigned_contractor)
		contract.notify_assigned_contractor()
	return contract

#undef CYBERPUNK_CONTRACT_STATS_FILE


