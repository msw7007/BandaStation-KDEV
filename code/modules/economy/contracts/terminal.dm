//CYBERPUNK BUILD - rebuild and delete before release

/obj/machinery/vending/proc/has_contract_terminal_module()
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		if(istype(module, /datum/cyberpunk_machine_module/vending_contract_terminal))
			return TRUE
	return FALSE


/obj/machinery/vending/proc/get_cyberpunk_contract_terminal_label()
	var/area/current_area = get_area(src)
	return "[name] ([current_area?.name || "unknown"], [x],[y],[z])"


/obj/machinery/vending/proc/matches_cyberpunk_contract_terminal(destination_text)
	if(!destination_text)
		return TRUE
	var/normalized = lowertext(destination_text)
	if(findtext(lowertext(name), normalized) || findtext(lowertext("[type]"), normalized))
		return TRUE
	var/area/current_area = get_area(src)
	if(current_area && findtext(lowertext(current_area.name), normalized))
		return TRUE
	return findtext(lowertext(get_cyberpunk_contract_terminal_label()), normalized)


/obj/machinery/vending/proc/open_cyberpunk_contract_terminal(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!has_contract_terminal_module())
		return FALSE
	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, span_warning("[src]'s contract terminal is offline."))
		return TRUE
	if(!cyberpunk_contract_terminal_ui)
		cyberpunk_contract_terminal_ui = new(src)
	cyberpunk_contract_terminal_ui.ui_interact(user)
	return TRUE


/obj/machinery/vending/var/datum/cyberpunk_contract_terminal_ui/cyberpunk_contract_terminal_ui


/datum/cyberpunk_contract_terminal_ui
	var/obj/machinery/vending/terminal


/datum/cyberpunk_contract_terminal_ui/New(obj/machinery/vending/new_terminal)
	terminal = new_terminal


/datum/cyberpunk_contract_terminal_ui/Destroy(force)
	terminal = null
	return ..()


/datum/cyberpunk_contract_terminal_ui/ui_state(mob/user)
	return GLOB.physical_state


/datum/cyberpunk_contract_terminal_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkContractTerminal", terminal?.name || "Contract terminal")
		ui.open()


/datum/cyberpunk_contract_terminal_ui/ui_data(mob/user)
	return SSeconomy.cyberpunk_contract_terminal_ui_data(user, terminal)


/datum/cyberpunk_contract_terminal_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !terminal)
		return
	return SSeconomy.cyberpunk_contract_terminal_ui_act(action, params, ui.user, terminal)


/datum/cyberpunk_contract_condition/delivery/proc/terminal_matches(obj/machinery/vending/terminal)
	if(destination_kind != "terminal" || !terminal)
		return FALSE
	return terminal.matches_cyberpunk_contract_terminal(destination_text)


/datum/cyberpunk_contract_condition/delivery/proc/can_record_terminal_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item, obj/machinery/vending/terminal)
	if(!contract || !user || !item || !terminal_matches(terminal))
		return FALSE
	if(item.cyberpunk_contract_id && item.cyberpunk_contract_id != contract.id)
		return FALSE
	if(item.cyberpunk_contract_id != contract.id && !matches_target_text(item))
		return FALSE
	return TRUE


/datum/cyberpunk_contract_condition/delivery/proc/record_terminal_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item, obj/machinery/vending/terminal)
	if(!can_record_terminal_item(contract, user, item, terminal))
		return FALSE
	delivered_amount = max(delivered_amount, required_amount)
	contract.delivered_amount = max(contract.delivered_amount, delivered_amount)
	contract.add_history("[user.real_name || user.name] submitted [item.name] through terminal [terminal.get_cyberpunk_contract_terminal_label()]")
	if(!contract.creator_confirm_required)
		contract.complete("cargo delivered through terminal")
	return TRUE


/datum/controller/subsystem/economy/proc/submit_cyberpunk_contract_terminal_item(mob/living/user, obj/machinery/vending/terminal, obj/item/item)
	if(!user || !terminal || !item)
		to_chat(user, span_warning("You need to hold the cargo you want to submit."))
		return TRUE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED)
			continue
		if(contract.contract_type == CYBERPUNK_CONTRACT_MINING)
			if(contract.try_record_item_condition(CYBERPUNK_CONTRACT_MINING, user, item))
				to_chat(user, span_notice("You submit [item] for contract #[contract.id]."))
				return TRUE
			continue
		if(contract.contract_type != CYBERPUNK_CONTRACT_DELIVERY)
			continue
		for(var/datum/cyberpunk_contract_condition/delivery/condition as anything in contract.completion_conditions)
			if(!istype(condition) || !condition.can_record_terminal_item(contract, user, item, terminal))
				continue
			if(!user.transferItemToLoc(item, terminal))
				to_chat(user, span_warning("[item] is stuck in your hand."))
				return TRUE
			if(condition.record_terminal_item(contract, user, item, terminal))
				create_cyberpunk_contract_mail(user, terminal, item, contract.creator_name, contract.id, TRUE)
				to_chat(user, span_notice("You submit [item] for contract #[contract.id]. It is now waiting for [contract.creator_name]."))
				return TRUE
	to_chat(user, span_warning("[terminal] finds no accepted contract that can take [item]."))
	return TRUE


/datum/controller/subsystem/economy/proc/open_cyberpunk_contract_mail_send(mob/living/user, obj/machinery/vending/terminal)
	var/obj/item/item = user?.get_active_held_item()
	if(!item)
		to_chat(user, span_warning("You need to hold the item you want to send."))
		return TRUE
	var/recipient = tgui_input_text(user, "Recipient character name.", "Send contract mail", max_length = 64)
	if(!recipient || QDELETED(item) || !user.Adjacent(terminal))
		return TRUE
	var/datum/cyberpunk_contract_mail/mail = create_cyberpunk_contract_mail(user, terminal, item, recipient)
	if(!mail)
		to_chat(user, span_warning("[terminal] fails to route [item]."))
		return TRUE
	to_chat(user, span_notice("You send [item] to [mail.recipient_name] as terminal mail #[mail.id]."))
	return TRUE


/datum/controller/subsystem/economy/proc/open_cyberpunk_contract_mail_claim(mob/living/user, obj/machinery/vending/terminal)
	var/list/mails = get_cyberpunk_contract_mail_for(user)
	if(!length(mails))
		to_chat(user, span_notice("[terminal] has no mail for you."))
		return TRUE
	var/list/labels = list()
	var/list/by_label = list()
	for(var/datum/cyberpunk_contract_mail/mail as anything in mails)
		var/label = mail.to_label()
		labels += label
		by_label[label] = mail
	var/choice = tgui_input_list(user, "Select mail to claim.", "Contract mail", labels)
	if(!choice || !user.Adjacent(terminal))
		return TRUE
	return claim_cyberpunk_contract_mail(user, by_label[choice])


/datum/controller/subsystem/economy/proc/show_cyberpunk_contract_terminal_contracts(mob/living/user, obj/machinery/vending/terminal)
	var/list/lines = list()
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_view(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED)
			continue
		if(contract.contract_type == CYBERPUNK_CONTRACT_MINING)
			lines += "#[contract.id] [contract.title]: resource turn-in [contract.delivered_amount]/[contract.required_amount]"
			continue
		if(contract.contract_type != CYBERPUNK_CONTRACT_DELIVERY)
			continue
		for(var/datum/cyberpunk_contract_condition/delivery/condition as anything in contract.completion_conditions)
			if(istype(condition) && condition.terminal_matches(terminal))
				lines += "#[contract.id] [contract.title]: delivery terminal target, cargo [contract.target_text]"
	if(!length(lines))
		to_chat(user, span_notice("[terminal] has no compatible visible contracts."))
		return TRUE
	to_chat(user, span_notice("Compatible contracts at [terminal.get_cyberpunk_contract_terminal_label()]:<br>[jointext(lines, "<br>")]"))
	return TRUE


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_terminal_options()
	var/list/terminals = list()
	for(var/obj/machinery/vending/vendor as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
		if(!vendor.has_contract_terminal_module())
			continue
		terminals += list(list(
			"label" = vendor.get_cyberpunk_contract_terminal_label(),
			"name" = vendor.name,
			"area" = get_area_name(vendor),
			"x" = vendor.x,
			"y" = vendor.y,
			"z" = vendor.z,
		))
	return terminals


/datum/controller/subsystem/economy/proc/cyberpunk_contract_terminal_ui_data(mob/user, obj/machinery/vending/terminal)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/obj/item/held = living_user?.get_active_held_item()
	data["terminal"] = terminal?.get_cyberpunk_contract_terminal_label()
	data["online"] = terminal && !(terminal.machine_stat & (BROKEN|NOPOWER))
	data["hasRelay"] = terminal?.has_cyberspace_relay_module() || FALSE
	data["heldItem"] = held ? held.name : null
	data["mail"] = list()
	for(var/datum/cyberpunk_contract_mail/mail as anything in get_cyberpunk_contract_mail_for(living_user))
		data["mail"] += list(list(
			"id" = mail.id,
			"label" = mail.to_label(),
			"sender" = mail.sender_name,
			"item" = mail.item?.name,
			"contractId" = mail.contract_id,
			"source" = mail.source_terminal,
		))
	data["contracts"] = list()
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_view(living_user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED)
			continue
		if(contract.contract_type == CYBERPUNK_CONTRACT_MINING)
			data["contracts"] += list(list(
				"id" = contract.id,
				"title" = contract.title,
				"type" = contract.contract_type,
				"target" = contract.target_text,
				"progress" = "[contract.delivered_amount]/[contract.required_amount]",
				"compatible" = TRUE,
			))
			continue
		if(contract.contract_type != CYBERPUNK_CONTRACT_DELIVERY)
			continue
		var/compatible = FALSE
		for(var/datum/cyberpunk_contract_condition/delivery/condition as anything in contract.completion_conditions)
			if(istype(condition) && condition.terminal_matches(terminal))
				compatible = TRUE
				break
		if(!compatible)
			continue
		data["contracts"] += list(list(
			"id" = contract.id,
			"title" = contract.title,
			"type" = contract.contract_type,
			"target" = contract.target_text,
			"progress" = "[contract.delivered_amount]/[contract.required_amount]",
			"compatible" = TRUE,
		))
	return data


/datum/controller/subsystem/economy/proc/cyberpunk_contract_terminal_ui_act(action, list/params, mob/user, obj/machinery/vending/terminal)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user || !terminal?.has_contract_terminal_module())
		return FALSE
	if(terminal.machine_stat & (BROKEN|NOPOWER))
		to_chat(living_user, span_warning("[terminal]'s contract terminal is offline."))
		return TRUE
	switch(action)
		if("submit_held")
			return submit_cyberpunk_contract_terminal_item(living_user, terminal, living_user.get_active_held_item())
		if("send_mail")
			var/obj/item/held = living_user.get_active_held_item()
			var/datum/cyberpunk_contract_mail/mail = create_cyberpunk_contract_mail(living_user, terminal, held, params["recipient"])
			if(mail)
				to_chat(living_user, span_notice("You send [held] to [mail.recipient_name] as terminal mail #[mail.id]."))
				return TRUE
			to_chat(living_user, span_warning("[terminal] fails to route your held item."))
			return TRUE
		if("claim_mail")
			var/datum/cyberpunk_contract_mail/mail = cyberpunk_contract_mail["[params["id"]]"]
			return claim_cyberpunk_contract_mail(living_user, mail)
		if("relay")
			return terminal.toggle_cyberspace_relay(living_user)
	return FALSE
