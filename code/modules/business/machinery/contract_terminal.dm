/obj/machinery/computer/cy_contract_terminal
	name = "contract terminal"
	desc = "A city terminal for registering public, corporate and grey contracts."
	icon_screen = "request"
	var/grey_unlocked = FALSE
	var/linked_business_id

/obj/machinery/computer/cy_contract_terminal/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!user)
		return
	ui_interact(user)

/obj/machinery/computer/cy_contract_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkContractTerminal", name)
		ui.open()

/obj/machinery/computer/cy_contract_terminal/ui_data(mob/user)
	var/list/data = list()
	data["grey_unlocked"] = grey_unlocked
	data["contracts"] = list()
	for(var/contract_id in SScy_business.contracts_by_id)
		var/datum/cy_contract/contract = SScy_business.contracts_by_id[contract_id]
		if(!contract)
			continue
		if(contract.visibility == CY_CONTRACT_GREY && !grey_unlocked)
			continue
		data["contracts"] += list(contract.to_list())
	data["businesses"] = list()
	for(var/datum/cy_business/business as anything in SScy_business.get_user_businesses(user))
		data["businesses"] += list(business.to_list())
	data["ledger"] = SScy_business.contract_ledger.Copy()
	return data

/obj/machinery/computer/cy_contract_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	switch(action)
		if("create")
			var/list/businesses = SScy_business.get_user_businesses(user)
			if(!length(businesses) && !linked_business_id)
				to_chat(user, span_warning("No managed business found for contract reserve."))
				return TRUE
			var/datum/cy_business/customer_business = linked_business_id ? SScy_business.get_business(linked_business_id) : businesses[1]
			var/name = tgui_input_text(user, "Contract name", "Create contract", "New contract", MAX_NAME_LEN)
			if(!name)
				return TRUE
			var/type = tgui_input_list(user, "Contract type", "Create contract", list(CY_CONTRACT_DELIVERY, CY_CONTRACT_PROCUREMENT, CY_CONTRACT_REPAIR, CY_CONTRACT_CONSTRUCTION, CY_CONTRACT_GUARD, CY_CONTRACT_ESCORT, CY_CONTRACT_EVACUATION, CY_CONTRACT_MINING, CY_CONTRACT_SABOTAGE, CY_CONTRACT_ELIMINATION, CY_CONTRACT_RECON))
			var/payment = tgui_input_number(user, "Payment", "Create contract", 100, max_value = 1000000, min_value = 0)
			var/deposit = tgui_input_number(user, "Performer deposit", "Create contract", 0, max_value = 1000000, min_value = 0)
			var/minutes = tgui_input_number(user, "Deadline in minutes (0 for none)", "Create contract", 0, max_value = 600, min_value = 0)
			var/legality = tgui_input_list(user, "Legality", "Create contract", list(CY_CONTRACT_LEGAL, CY_CONTRACT_ILLEGAL))
			var/visibility = tgui_input_list(user, "Visibility", "Create contract", list(CY_CONTRACT_PUBLIC, CY_CONTRACT_CORPORATE, CY_CONTRACT_PRIVATE, CY_CONTRACT_GREY))
			var/list/contract_data = list(
				"name" = name,
				"contract_type" = type || CY_CONTRACT_DELIVERY,
				"payment_amount" = payment || 0,
				"deposit_amount" = deposit || 0,
				"legality" = legality || CY_CONTRACT_LEGAL,
				"visibility" = visibility || CY_CONTRACT_PUBLIC,
				"customer_ckey" = user?.ckey,
				"customer_business_id" = customer_business?.business_id,
				"due_time" = minutes ? world.time + (minutes * 1 MINUTES) : 0,
			)
			var/target_ref = tgui_input_text(user, "Optional target REF", "Create contract", "", MAX_MESSAGE_LEN)
			if(target_ref)
				contract_data["target_ref"] = target_ref
			var/target_type = tgui_input_text(user, "Optional target type path", "Create contract", "", MAX_MESSAGE_LEN)
			if(target_type)
				contract_data["target_type"] = target_type
			create_contract(contract_data)
			return TRUE
		if("accept")
			var/list/businesses = SScy_business.get_user_businesses(user)
			var/datum/cy_business/performer_business = length(businesses) ? businesses[1] : null
			accept_contract(user, params["contract_id"], performer_business)
			return TRUE
		if("process")
			var/datum/cy_contract/contract = SScy_business.get_contract(params["contract_id"])
			contract?.process_contract()
			return TRUE
		if("cancel")
			var/datum/cy_contract/contract = SScy_business.get_contract(params["contract_id"])
			contract?.cancel_contract("Cancelled from terminal")
			return TRUE
		if("dispute")
			var/datum/cy_contract/contract = SScy_business.get_contract(params["contract_id"])
			contract?.dispute_contract("Disputed from terminal")
			return TRUE
		if("unlock_grey")
			unlock_grey_pool()
			return TRUE

/obj/machinery/computer/cy_contract_terminal/proc/show_contract_status(mob/user)
	to_chat(user, span_notice("Open contracts: [length(SScy_business.open_contracts)]. Grey pool: [grey_unlocked ? "unlocked" : "locked"]."))
	var/list/story_state = SScy_storyteller?.get_story_state()
	if(story_state)
		to_chat(user, span_notice("City pressure: [round(story_state["total_pressure"])] / [story_state["ending"]]."))
	for(var/contract_id in SScy_business.open_contracts)
		var/datum/cy_contract/contract = SScy_business.open_contracts[contract_id]
		if(!contract)
			continue
		if(contract.visibility == CY_CONTRACT_GREY && !grey_unlocked)
			continue
		to_chat(user, span_notice("[contract.contract_id]: [contract.name] ([contract.contract_type]) - [contract.payment_amount] credits."))

/obj/machinery/computer/cy_contract_terminal/proc/create_contract(list/contract_data)
	if(!contract_data)
		return null
	if(!contract_data["visibility"])
		contract_data["visibility"] = grey_unlocked ? CY_CONTRACT_GREY : CY_CONTRACT_PUBLIC
	if(!contract_data["customer_business_id"])
		contract_data["customer_business_id"] = linked_business_id
	return SScy_business.create_contract(contract_data)

/obj/machinery/computer/cy_contract_terminal/proc/accept_contract(mob/user, contract_id, datum/cy_business/performer_business)
	var/datum/cy_contract/contract = SScy_business.get_contract(contract_id)
	if(!contract)
		return FALSE
	if(contract.visibility == CY_CONTRACT_GREY && !grey_unlocked)
		return FALSE
	return contract.accept_contract(user, performer_business)

/obj/machinery/computer/cy_contract_terminal/proc/submit_contract_item(obj/item/submitted_item, datum/cy_contract/contract, amount = 1)
	if(!submitted_item || !contract)
		return FALSE
	if(contract.target_type)
		var/path = text2path(contract.target_type)
		if(path && !istype(submitted_item, path))
			return FALSE
	contract.metadata["delivered_amount"] = (contract.metadata["delivered_amount"] || 0) + amount
	qdel(submitted_item)
	contract.process_contract()
	return TRUE

/obj/machinery/computer/cy_contract_terminal/proc/unlock_grey_pool(key = null)
	grey_unlocked = TRUE
	return TRUE
