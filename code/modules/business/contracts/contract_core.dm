/datum/cy_contract
	var/contract_id
	var/name = "Unnamed Contract"
	var/description = ""
	var/contract_type = CY_CONTRACT_DELIVERY
	var/status = CY_CONTRACT_STATUS_CREATED
	var/legality = CY_CONTRACT_LEGAL
	var/visibility = CY_CONTRACT_PUBLIC
	var/customer_ckey
	var/performer_ckey
	var/customer_business_id
	var/performer_business_id
	var/target_ref
	var/target_type
	var/target_amount = 1
	var/target_area_ref
	var/target_x
	var/target_y
	var/target_z
	var/payment_amount = 0
	var/service_fee = CY_CONTRACT_DEFAULT_SERVICE_FEE
	var/tax_percent = CY_CONTRACT_DEFAULT_TAX_PERCENT
	var/deposit_amount = 0
	var/reserved_payment = 0
	var/reserved_tax = 0
	var/fail_penalty = 0
	var/start_time = 0
	var/due_time = 0
	var/completed_time = 0
	var/created_time = 0
	var/accepted_time = 0
	var/list/participants = list()
	var/list/event_log = list()
	var/list/metadata = list()

/datum/cy_contract/New()
	. = ..()
	created_time = world.time
	if(!participants)
		participants = list()
	if(!event_log)
		event_log = list()
	if(!metadata)
		metadata = list()

/datum/cy_contract/proc/load_from_list(list/data)
	if(!data)
		return FALSE
	name = data["name"] || name
	description = data["description"] || description
	contract_type = data["contract_type"] || data["type"] || contract_type
	legality = data["legality"] || legality
	visibility = data["visibility"] || visibility
	customer_ckey = data["customer_ckey"] || customer_ckey
	performer_ckey = data["performer_ckey"] || performer_ckey
	customer_business_id = data["customer_business_id"] || customer_business_id
	performer_business_id = data["performer_business_id"] || performer_business_id
	target_ref = data["target_ref"] || target_ref
	target_type = data["target_type"] || target_type
	target_amount = data["target_amount"] || target_amount
	target_area_ref = data["target_area_ref"] || target_area_ref
	target_x = data["target_x"] || target_x
	target_y = data["target_y"] || target_y
	target_z = data["target_z"] || target_z
	payment_amount = max(0, round(data["payment_amount"] || payment_amount))
	service_fee = max(0, round(data["service_fee"] || service_fee))
	deposit_amount = max(0, round(data["deposit_amount"] || deposit_amount))
	fail_penalty = max(0, round(data["fail_penalty"] || fail_penalty))
	due_time = data["due_time"] || due_time
	metadata = data["metadata"] || metadata || list()
	participants = data["participants"] || participants || list()
	return TRUE

/datum/cy_contract/proc/to_list()
	var/list/data = list()
	data["contract_id"] = contract_id
	data["name"] = name
	data["description"] = description
	data["contract_type"] = contract_type
	data["status"] = status
	data["legality"] = legality
	data["visibility"] = visibility
	data["customer_ckey"] = customer_ckey
	data["performer_ckey"] = performer_ckey
	data["customer_business_id"] = customer_business_id
	data["performer_business_id"] = performer_business_id
	data["target_ref"] = target_ref
	data["target_type"] = target_type
	data["target_amount"] = target_amount
	data["target_area_ref"] = target_area_ref
	data["target_x"] = target_x
	data["target_y"] = target_y
	data["target_z"] = target_z
	data["payment_amount"] = payment_amount
	data["service_fee"] = service_fee
	data["tax_percent"] = tax_percent
	data["deposit_amount"] = deposit_amount
	data["reserved_payment"] = reserved_payment
	data["reserved_tax"] = reserved_tax
	data["fail_penalty"] = fail_penalty
	data["start_time"] = start_time
	data["due_time"] = due_time
	data["completed_time"] = completed_time
	data["created_time"] = created_time
	data["accepted_time"] = accepted_time
	data["participants"] = participants.Copy()
	data["event_log"] = event_log.Copy()
	data["metadata"] = metadata.Copy()
	return data

/datum/cy_contract/proc/open_contract()
	if(status != CY_CONTRACT_STATUS_CREATED)
		return FALSE
	if(!reserve_customer_payment())
		return FALSE
	status = CY_CONTRACT_STATUS_OPEN
	log_event("Contract opened")
	SScy_business?.open_contracts[contract_id] = src
	return TRUE

/datum/cy_contract/proc/reserve_customer_payment()
	var/total = payment_amount + service_fee
	reserved_tax = 0
	if(legality == CY_CONTRACT_LEGAL)
		reserved_tax = round(payment_amount * tax_percent * 0.01)
		total += reserved_tax
	var/datum/cy_business/customer_business = SScy_business?.get_business(customer_business_id)
	if(customer_business)
		if(!customer_business.reserve_payment(total, "Contract [name] reserve"))
			return FALSE
	reserved_payment = payment_amount
	return TRUE

/datum/cy_contract/proc/accept_contract(mob/user, datum/cy_business/performer_business)
	if(status != CY_CONTRACT_STATUS_OPEN)
		return FALSE
	if(!user?.ckey)
		return FALSE
	if(deposit_amount > 0 && performer_business)
		if(!performer_business.reserve_payment(deposit_amount, "Contract [name] deposit"))
			return FALSE
	performer_ckey = user.ckey
	performer_business_id = performer_business?.business_id
	participants |= performer_ckey
	accepted_time = world.time
	start_time = world.time
	status = CY_CONTRACT_STATUS_ACTIVE
	SScy_business?.open_contracts -= contract_id
	log_event("Accepted by [performer_ckey]")
	return TRUE

/datum/cy_contract/proc/process_contract()
	if(status != CY_CONTRACT_STATUS_ACTIVE)
		return FALSE
	if(due_time && world.time >= due_time)
		return fail_contract("Contract deadline expired")
	if(check_completion())
		return complete_contract("Automatic completion")
	return TRUE

/datum/cy_contract/proc/check_completion()
	switch(contract_type)
		if(CY_CONTRACT_DELIVERY, CY_CONTRACT_ESCORT, CY_CONTRACT_EVACUATION)
			return check_target_at_destination()
		if(CY_CONTRACT_PROCUREMENT, CY_CONTRACT_MINING)
			return check_terminal_progress()
		if(CY_CONTRACT_REPAIR)
			return check_repair_progress()
		if(CY_CONTRACT_CONSTRUCTION)
			return check_construction_progress()
		if(CY_CONTRACT_GUARD)
			return check_guard_progress()
		if(CY_CONTRACT_SABOTAGE)
			return check_sabotage_progress()
		if(CY_CONTRACT_ELIMINATION)
			return check_elimination_progress()
		if(CY_CONTRACT_RECON)
			return check_recon_progress()
	return FALSE

/datum/cy_contract/proc/complete_contract(reason = "Completed")
	if(status == CY_CONTRACT_STATUS_COMPLETED || status == CY_CONTRACT_STATUS_CLOSED)
		return FALSE
	status = CY_CONTRACT_STATUS_COMPLETED
	completed_time = world.time
	pay_performer()
	log_event(reason)
	close_contract()
	return TRUE

/datum/cy_contract/proc/fail_contract(reason = "Failed")
	if(status == CY_CONTRACT_STATUS_FAILED || status == CY_CONTRACT_STATUS_CLOSED)
		return FALSE
	status = CY_CONTRACT_STATUS_FAILED
	log_event(reason)
	apply_failure_penalty()
	close_contract()
	return TRUE

/datum/cy_contract/proc/cancel_contract(reason = "Cancelled")
	status = CY_CONTRACT_STATUS_CANCELLED
	log_event(reason)
	close_contract()
	return TRUE

/datum/cy_contract/proc/dispute_contract(reason = "Disputed")
	status = CY_CONTRACT_STATUS_DISPUTED
	log_event(reason)
	return TRUE

/datum/cy_contract/proc/close_contract()
	if(status != CY_CONTRACT_STATUS_CLOSED)
		log_event("Closed")
	SScy_business?.move_contract_to_ledger(src)
	status = CY_CONTRACT_STATUS_CLOSED
	return TRUE

/datum/cy_contract/proc/pay_performer()
	var/datum/cy_business/performer_business = SScy_business?.get_business(performer_business_id)
	if(performer_business && reserved_payment > 0)
		performer_business.adjust_balance(reserved_payment, "Contract [name] payment")
	return TRUE

/datum/cy_contract/proc/apply_failure_penalty()
	var/datum/cy_business/customer_business = SScy_business?.get_business(customer_business_id)
	var/datum/cy_business/performer_business = SScy_business?.get_business(performer_business_id)
	if(customer_business && deposit_amount > 0)
		customer_business.adjust_balance(deposit_amount, "Contract [name] failed deposit")
	if(performer_business && fail_penalty > 0)
		performer_business.reserve_payment(fail_penalty, "Contract [name] failure penalty")
	return TRUE

/datum/cy_contract/proc/log_event(text)
	event_log += "[world.time]: [text]"
	return TRUE

/datum/cy_contract/proc/get_target_atom()
	if(!target_ref)
		return null
	return locate(target_ref)

/datum/cy_contract/proc/get_destination_turf()
	if(target_x && target_y && target_z)
		return locate(target_x, target_y, target_z)
	return null

/datum/cy_contract/proc/check_target_at_destination()
	var/atom/movable/target = get_target_atom()
	var/turf/destination = get_destination_turf()
	if(!target || !destination)
		return FALSE
	return get_dist(target, destination) <= (metadata["destination_range"] || 1)

/datum/cy_contract/proc/check_terminal_progress()
	return (metadata["delivered_amount"] || 0) >= target_amount

/datum/cy_contract/proc/check_repair_progress()
	var/atom/target = get_target_atom()
	if(!target)
		return FALSE
	return target.cy_contract_repair_percent() >= (metadata["repair_percent"] || 90)

/datum/cy_contract/proc/check_construction_progress()
	var/area/target_area = target_area_ref ? locate(target_area_ref) : null
	if(!target_area || !target_type)
		return FALSE
	var/path = text2path(target_type)
	if(!path)
		return FALSE
	for(var/turf/area_turf as anything in get_area_turfs(target_area))
		for(var/atom/movable/candidate in area_turf)
			if(istype(candidate, path))
				return TRUE
	return FALSE

/datum/cy_contract/proc/check_guard_progress()
	var/mob/living/target = get_target_atom()
	if(!target)
		return FALSE
	if(target.stat == DEAD)
		return fail_contract("Guarded target died")
	return due_time && world.time >= due_time

/datum/cy_contract/proc/check_sabotage_progress()
	var/atom/target = get_target_atom()
	if(!target || QDELETED(target))
		return TRUE
	return target.cy_contract_sabotaged(metadata)

/datum/cy_contract/proc/check_elimination_progress()
	var/mob/living/target = get_target_atom()
	if(!target || QDELETED(target))
		return TRUE
	return target.stat == DEAD || target.health <= (metadata["elimination_health"] || 0)

/datum/cy_contract/proc/check_recon_progress()
	return !!metadata["recon_scanned"]

/atom/proc/cy_contract_repair_percent()
	return 100

/atom/proc/cy_contract_sabotaged(list/metadata)
	return QDELETED(src)

/obj/cy_contract_sabotaged(list/metadata)
	if(QDELETED(src))
		return TRUE
	if(get_integrity() <= (metadata?["sabotage_integrity"] || 0))
		return TRUE
	return FALSE
