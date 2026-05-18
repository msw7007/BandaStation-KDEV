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
	show_contract_status(user)

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
