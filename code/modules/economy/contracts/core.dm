//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract
	var/id = 0
	var/title = "Contract"
	var/description = ""
	var/contract_type = CYBERPUNK_CONTRACT_DELIVERY
	var/target_text = ""
	var/status = CYBERPUNK_CONTRACT_CREATED
	var/creator_ckey
	var/creator_name
	var/creator_character_key
	var/creator_account_id
	var/creator_business_id = 0
	var/contractor_ckey
	var/contractor_name
	var/contractor_character_key
	var/contractor_account_id
	var/assigned_contractor_name
	var/assigned_contractor_key
	var/payment = 0
	var/deposit = 0
	var/penalty = 0
	var/escrow_payment = 0
	var/escrow_deposit = 0
	var/legal = TRUE
	var/public_contract = TRUE
	var/source_corporation
	var/creator_confirm_required = FALSE
	var/created_at = 0
	var/accepted_at = 0
	var/due_time = 0
	var/required_amount = 1
	var/delivered_amount = 0
	var/required_percent = 75
	var/tax_paid = 0
	var/direct_access_code
	var/evidence_disclosed = FALSE
	var/evidence_summary = ""
	var/list/history = list()
	var/list/datum/cyberpunk_contract_condition/completion_conditions = list()
	var/list/obj/item/delivery_items = list()
	var/mob/living/tracked_creator


/datum/cyberpunk_contract/proc/get_creator_account()
	return SSeconomy.bank_accounts_by_id["[creator_account_id]"]


/datum/cyberpunk_contract/proc/get_contractor_account()
	return SSeconomy.bank_accounts_by_id["[contractor_account_id]"]


/datum/cyberpunk_contract/proc/find_security_record(character_name)
	if(!character_name)
		return null
	var/normalized_name = ckey(character_name)
	for(var/datum/record/crew/record as anything in GLOB.manifest.general)
		if(ckey(record.name) == normalized_name)
			return record
	return null


/datum/cyberpunk_contract/proc/add_security_incident(character_name, incident_name, details, fine = 0)
	var/datum/record/crew/record = find_security_record(character_name)
	if(!record)
		add_history("security incident could not be filed for [character_name]: no crew record")
		return FALSE
	if(fine > 0)
		var/datum/crime/citation/new_citation = new(name = incident_name, details = details, author = "Contract Registry", fine = fine)
		record.citations += new_citation
		SSblackbox.ReportCitation(REF(new_citation), "contract_registry", "Contract Registry", record.name, incident_name, details, fine)
	else
		var/datum/crime/new_crime = new(name = incident_name, details = details, author = "Contract Registry")
		record.crimes += new_crime
		record.wanted_status = WANTED_SUSPECT
		update_matching_security_huds(record.name)
		SSblackbox.ReportCitation(REF(new_crime), "contract_registry", "Contract Registry", record.name, incident_name, details)
	add_history("security incident filed for [record.name]: [incident_name]")
	return TRUE


/datum/cyberpunk_contract/proc/apply_legal_breach(actor_name, incident_name, details, fine = 0)
	if(!legal || !actor_name)
		return FALSE
	return add_security_incident(actor_name, incident_name, details, fine)


/datum/cyberpunk_contract/proc/disclose_evidence(mob/living/user)
	if(!can_view(user))
		return FALSE
	if(evidence_disclosed)
		return TRUE
	evidence_disclosed = TRUE
	evidence_summary = legal ? "Legal contract #[id] disclosed as civil evidence." : "Illegal contract #[id] disclosed as criminal evidence."
	add_history("[user.real_name || user.name] disclosed contract evidence")
	if(!legal)
		var/details = "Illegal contract #[id]: [title]. Type: [contract_type]. Target: [target_text]. Payment: [payment][MONEY_SYMBOL]."
		add_security_incident(creator_name, "Illegal contract", details)
		if(contractor_name)
			add_security_incident(contractor_name, "Illegal contract", details)
		else if(assigned_contractor_name)
			add_security_incident(assigned_contractor_name, "Illegal contract offer", details)
	return TRUE


/datum/cyberpunk_contract/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")


/datum/cyberpunk_contract/proc/user_character_key(mob/living/user)
	return SSeconomy.get_cyberpunk_contract_character_key(user, user?.get_bank_account())


/datum/cyberpunk_contract/proc/can_view(mob/living/user)
	if(public_contract && legal)
		return TRUE
	if(creator_business_id)
		var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(creator_business_id)
		if(business?.can_view(user))
			return TRUE
	var/character_key = user_character_key(user)
	if(character_key == creator_character_key || character_key == contractor_character_key || character_key == assigned_contractor_key)
		return TRUE
	return FALSE


/datum/cyberpunk_contract/proc/can_direct_lookup(mob/living/user, lookup_token)
	if(can_view(user))
		return TRUE
	if(!lookup_token || !direct_access_code)
		return FALSE
	return lowertext("[lookup_token]") == lowertext(direct_access_code)


/mob/living/proc/remember_cyberpunk_contract(datum/cyberpunk_contract/contract)
	if(!contract)
		return FALSE
	return remember_data("contract:[contract.id]", list(
		"cyberpunk_kind" = "contract",
		"id" = contract.id,
		"title" = contract.title,
		"type" = contract.contract_type,
		"target" = contract.target_text,
		"creator" = contract.creator_name,
		"contractor" = contract.contractor_name,
		"payment" = contract.payment,
		"deposit" = contract.deposit,
		"penalty" = contract.penalty,
		"legal" = contract.legal,
		"public" = contract.public_contract,
		"direct_access_code" = contract.direct_access_code,
		"accepted_at" = round_timestamp(),
	))


/datum/cyberpunk_contract/proc/can_manage(mob/living/user)
	if(creator_business_id)
		var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(creator_business_id)
		return business?.has_access(user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS)
	return user_character_key(user) == creator_character_key


/datum/cyberpunk_contract/proc/can_act_as_contractor(mob/living/user)
	return user_character_key(user) == contractor_character_key


/datum/cyberpunk_contract/proc/can_accept(mob/living/user)
	if(!(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED)) || !user || can_manage(user))
		return FALSE
	if(!assigned_contractor_key)
		return TRUE
	return user_character_key(user) == assigned_contractor_key


/datum/cyberpunk_contract/proc/can_refuse(mob/living/user)
	return status == CYBERPUNK_CONTRACT_OFFERED && user_character_key(user) == assigned_contractor_key


/datum/cyberpunk_contract/proc/refuse_offer(mob/living/user)
	if(!can_refuse(user))
		return FALSE
	add_history("[user.real_name || user.name] refused assigned offer")
	assigned_contractor_name = null
	assigned_contractor_key = null
	status = CYBERPUNK_CONTRACT_CREATED
	return TRUE


/datum/cyberpunk_contract/proc/notify_assigned_contractor()
	var/mob/living/target = SSeconomy.find_cyberpunk_contract_person(assigned_contractor_name)
	if(!target)
		return FALSE
	to_chat(target, span_notice("You received contract offer #[id]: [title]."))
	var/datum/cyberpunk_contract_offer_verb_ui/interface = new(id)
	interface.ui_interact(target)
	return TRUE


/datum/cyberpunk_contract/proc/matches_target(atom/target)
	if(!target)
		return FALSE
	if(!target_text)
		return TRUE
	var/normalized_target = lowertext(target_text)
	return findtext(lowertext(target.name), normalized_target) || findtext(lowertext("[target.type]"), normalized_target)


/datum/cyberpunk_contract/proc/setup_default_condition(list/params)
	if(LAZYLEN(completion_conditions))
		return
	var/datum/cyberpunk_contract_condition/condition
	switch(contract_type)
		if(CYBERPUNK_CONTRACT_DELIVERY)
			condition = new /datum/cyberpunk_contract_condition/delivery
		if(CYBERPUNK_CONTRACT_MINING)
			condition = new /datum/cyberpunk_contract_condition/mining
		if(CYBERPUNK_CONTRACT_REPAIR)
			condition = new /datum/cyberpunk_contract_condition/repair
		if(CYBERPUNK_CONTRACT_BUILD)
			condition = new /datum/cyberpunk_contract_condition/build
		if(CYBERPUNK_CONTRACT_SABOTAGE)
			condition = new /datum/cyberpunk_contract_condition/sabotage
		if(CYBERPUNK_CONTRACT_ELIMINATION)
			condition = new /datum/cyberpunk_contract_condition/elimination
		if(CYBERPUNK_CONTRACT_GUARD)
			condition = new /datum/cyberpunk_contract_condition/guard
	if(!condition)
		return
	condition.configure_from_contract(src, params)
	completion_conditions += condition


/datum/cyberpunk_contract/proc/get_conditions_ui_data()
	var/list/conditions = list()
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		conditions += list(condition.to_ui_data())
	return conditions


/datum/cyberpunk_contract/proc/get_failure_conditions_ui_data()
	var/list/conditions = list()
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		conditions += list(condition.to_failure_ui_data(src))
	return conditions


/datum/cyberpunk_contract/proc/try_record_atom_condition(condition_id, mob/living/user, atom/target)
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		if(condition.id != condition_id)
			continue
		if(condition.record_atom(src, user, target))
			delivered_amount = max(delivered_amount, condition.delivered_amount)
			return TRUE
	return FALSE


/datum/cyberpunk_contract/proc/try_record_item_condition(condition_id, mob/living/user, obj/item/item)
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		if(condition.id != condition_id)
			continue
		if(condition.record_item(src, user, item))
			delivered_amount = max(delivered_amount, condition.delivered_amount)
			return TRUE
	return FALSE


/datum/cyberpunk_contract/proc/accept(mob/living/user)
	if(!can_accept(user))
		return FALSE
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		return FALSE
	if(deposit > 0 && !account.adjust_money(-deposit, "Contract deposit: [title]"))
		return FALSE
	contractor_ckey = user.ckey
	contractor_name = user.real_name || user.name
	contractor_character_key = SSeconomy.get_cyberpunk_contract_character_key(user, account)
	contractor_account_id = account.account_id
	escrow_deposit = deposit
	status = CYBERPUNK_CONTRACT_ACCEPTED
	accepted_at = world.time
	add_history("accepted by [contractor_name]; deposit [deposit][MONEY_SYMBOL]")
	user.remember_cyberpunk_contract(src)
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		condition.on_accept(src, user)
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "accepted")
	return TRUE


/datum/cyberpunk_contract/proc/cancel(mob/living/user)
	if(!can_manage(user) || !(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED)))
		return FALSE
	var/datum/bank_account/creator_account = get_creator_account()
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(escrow_payment > 0)
		creator_account?.adjust_money(escrow_payment, "Contract cancelled: [title]")
		escrow_payment = 0
	if(escrow_deposit > 0)
		contractor_account?.adjust_money(escrow_deposit, "Contract deposit returned: [title]")
		escrow_deposit = 0
	if(status == CYBERPUNK_CONTRACT_ACCEPTED && penalty > 0 && creator_account?.adjust_money(-penalty, "Contract cancellation penalty: [title]"))
		contractor_account?.adjust_money(penalty, "Contract cancellation penalty: [title]")
		apply_legal_breach(creator_name, "Contract cancellation breach", "Cancelled accepted legal contract #[id]: [title].", penalty)
	status = CYBERPUNK_CONTRACT_CANCELLED
	add_history("cancelled by [user.real_name || user.name]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(creator_character_key, "cancelled")
	return TRUE


/datum/cyberpunk_contract/proc/fail(reason = "failure", partial_payout_multiplier = 0)
	if(!(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED)))
		return FALSE
	var/datum/bank_account/creator_account = get_creator_account()
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(partial_payout_multiplier > 0 && escrow_payment > 0 && contractor_account)
		var/partial_payout = clamp(round(escrow_payment * partial_payout_multiplier), 0, escrow_payment)
		if(partial_payout > 0)
			contractor_account.adjust_money(partial_payout, "Partial contract payout #[id]: [title]")
			escrow_payment -= partial_payout
			add_history("partial payout [partial_payout][MONEY_SYMBOL] issued before failure")
	if(escrow_payment > 0)
		creator_account?.adjust_money(escrow_payment, "Contract failed: [title]")
		escrow_payment = 0
	if(escrow_deposit > 0)
		creator_account?.adjust_money(escrow_deposit, "Contract failed deposit: [title]")
		escrow_deposit = 0
	if(penalty > 0 && contractor_account?.adjust_money(-penalty, "Contract failure penalty: [title]"))
		creator_account?.adjust_money(penalty, "Contract failure penalty: [title]")
		apply_legal_breach(contractor_name, "Contract failure breach", "Failed legal contract #[id]: [title]. Reason: [reason].", penalty)
	status = CYBERPUNK_CONTRACT_FAILED
	add_history("failed: [reason]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "failed")
	return TRUE


/datum/cyberpunk_contract/proc/complete(reason = "completion")
	if(status != CYBERPUNK_CONTRACT_ACCEPTED)
		return FALSE
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(!contractor_account)
		return FALSE
	var/payout = escrow_payment
	if(legal)
		var/tax = round(payout * CYBERPUNK_CONTRACT_TAX_RATE)
		if(tax > 0)
			SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(tax, "Contract tax: [title]")
			tax_paid += tax
			payout -= tax
	var/payout_reason = legal ? "Legal contract payout #[id]: [title]; tax [tax_paid][MONEY_SYMBOL]" : "Off-ledger contract payout #[id]: [title]; no tax"
	contractor_account.adjust_money(payout, payout_reason)
	log_econ("Contract #[id] [legal ? "legal" : "off-ledger"] payout [payout][MONEY_NAME] to [contractor_account.account_holder]; tax [tax_paid][MONEY_NAME].")
	escrow_payment = 0
	if(escrow_deposit > 0)
		contractor_account.adjust_money(escrow_deposit, "Contract deposit returned: [title]")
		escrow_deposit = 0
	status = CYBERPUNK_CONTRACT_COMPLETED
	add_history("completed: [reason]")
	if(source_corporation)
		var/data_type = contract_type == CYBERPUNK_CONTRACT_DELIVERY ? "market" : contract_type
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(source_corporation, data_type, max(1, round(payment / 100)), max(1, round(payment * 0.02)), "contract completed #[id]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "completed")
	return TRUE


/datum/cyberpunk_contract/proc/timeout_check()
	if(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED))
		for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
			if(condition.on_timeout(src))
				return
		fail("deadline expired")


/datum/cyberpunk_contract/proc/find_creator_mob()
	for(var/mob/living/person as anything in GLOB.player_list)
		if(user_character_key(person) == creator_character_key)
			return person
	return null


/datum/cyberpunk_contract/proc/check_nearby_target(mob/living/user)
	if(!can_act_as_contractor(user))
		return FALSE
	for(var/datum/cyberpunk_contract_condition/condition as anything in completion_conditions)
		if(condition.check_nearby(src, user))
			delivered_amount = max(delivered_amount, condition.delivered_amount)
			return TRUE
	if(LAZYLEN(completion_conditions))
		return FALSE
	switch(contract_type)
		if(CYBERPUNK_CONTRACT_REPAIR)
			return check_nearby_repair_target(user)
		if(CYBERPUNK_CONTRACT_SABOTAGE)
			return check_nearby_sabotage_target(user)
		if(CYBERPUNK_CONTRACT_BUILD)
			return check_nearby_build_target(user)
		if(CYBERPUNK_CONTRACT_ELIMINATION)
			return check_nearby_elimination_target(user)
		if(CYBERPUNK_CONTRACT_GUARD)
			return check_guard_status(user)
	return FALSE


/datum/cyberpunk_contract/proc/to_ui_data(mob/living/user, include_history = FALSE)
	var/list/stats = contractor_character_key ? SSeconomy.get_cyberpunk_contract_stats(contractor_character_key) : null
	return list(
		"id" = id,
		"title" = title,
		"description" = description,
		"type" = contract_type,
		"target" = target_text,
		"status" = status,
		"creator" = creator_name,
		"creatorBusinessId" = creator_business_id,
		"contractor" = contractor_name,
		"assignedContractor" = assigned_contractor_name,
		"corporation" = source_corporation,
		"payment" = payment,
		"deposit" = deposit,
		"penalty" = penalty,
		"legal" = legal,
		"public" = public_contract,
		"taxPaid" = tax_paid,
		"creatorConfirmRequired" = creator_confirm_required,
		"directAccessCode" = can_manage(user) ? direct_access_code : null,
		"requiredAmount" = required_amount,
		"deliveredAmount" = delivered_amount,
		"requiredPercent" = required_percent,
		"conditions" = get_conditions_ui_data(),
		"failureConditions" = get_failure_conditions_ui_data(),
		"evidenceDisclosed" = evidence_disclosed,
		"evidenceSummary" = evidence_summary,
		"deadline" = due_time > world.time ? DisplayTimeText(due_time - world.time) : "expired",
		"canAccept" = can_accept(user),
		"canRefuse" = can_refuse(user),
		"canManage" = can_manage(user),
		"canAct" = can_act_as_contractor(user),
		"contractorStats" = stats,
		"history" = include_history ? history : null,
	)
//CYBERPUNK BUILD - rebuild and delete before release
