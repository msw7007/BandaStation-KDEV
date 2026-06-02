/datum/computer_file/program/restock_tracker
	filename = "restockapp"
	filedesc = "NT Restock Tracker"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "restock"
	extended_desc = "Сеть Nanotrasen IoT, в которой перечислены все торговые автоматы, находящиеся на станции, и насколько хорошо укомплектован каждый из них. Прибыльно!"
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = "cash-register"
	tgui_id = "NtosRestock"

/datum/computer_file/program/restock_tracker/ui_data()
	var/list/data = list()
	var/list/vending_list = list()
	var/id_increment = 1
	for(var/obj/machinery/vending/vendor as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
		if(vendor.all_products_free)
			continue
		var/list/total_legal_stock = vendor.total_stock(contrabrand = FALSE)
		if((!total_legal_stock[2] || (total_legal_stock[1] >= total_legal_stock[2])) && !vendor.credits_contained)
			continue
		vending_list += list(list(
			"name" = vendor.name,
			"location" = get_area_name(vendor),
			"credits" = vendor.credits_contained,
			"percentage" = (total_legal_stock[1] / total_legal_stock[2]) * 100,
			"id" = id_increment,
		))
		id_increment++
	data["vending_list"] = vending_list
	return data

/datum/computer_file/program/contracts
	filename = "contracts"
	filedesc = "Contracts"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "A public and private contract board for paid work, deposits, deadlines, and completion tracking."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 6
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContracts"
	/// Direct contract id loaded by the user. Used for private/illegal contracts that are not listed publicly.
	var/direct_contract_id

/datum/computer_file/program/contracts/ui_data(mob/user)
	return cyberpunk_contracts_ui_data(user, direct_contract_id)

/datum/computer_file/program/contracts/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "direct_lookup")
		direct_contract_id = params["id"]
		return TRUE
	return cyberpunk_contracts_ui_act(action, params, ui.user)

/datum/computer_file/program/contract_registry
	filename = "contractregistry"
	filedesc = "Contract Registry"
	downloader_category = PROGRAM_CATEGORY_SECURITY
	program_open_overlay = "generic"
	extended_desc = "A legal contract registry. Criminal and off-ledger contracts are not indexed."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContractRegistry"

/datum/computer_file/program/contract_registry/ui_data(mob/user)
	return cyberpunk_contract_registry_ui_data(user)

/datum/cyberpunk_contracts_verb_ui
	var/direct_contract_id

/datum/cyberpunk_contracts_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContracts", "Contracts")
		ui.open()

/datum/cyberpunk_contracts_verb_ui/ui_data(mob/user)
	return cyberpunk_contracts_ui_data(user, direct_contract_id)

/datum/cyberpunk_contracts_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "direct_lookup")
		direct_contract_id = params["id"]
		return TRUE
	return cyberpunk_contracts_ui_act(action, params, ui.user)

/datum/cyberpunk_contract_registry_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractRegistry", "Contract Registry")
		ui.open()

/datum/cyberpunk_contract_registry_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_registry_ui_data(user)

/mob/living/verb/open_cyberpunk_contracts()
	set name = "Контракты"
	set desc = "Временно открыть приложение контрактов без КПК."
	set category = "IC"

	var/datum/cyberpunk_contracts_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_contract_registry()
	set name = "Реестр контрактов"
	set desc = "Временно открыть легальный реестр контрактов без КПК."
	set category = "IC"

	var/datum/cyberpunk_contract_registry_verb_ui/interface = new
	interface.ui_interact(src)

/proc/cyberpunk_contracts_ui_data(mob/user, direct_contract_id = null)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	var/user_character_key = SSeconomy.get_cyberpunk_contract_character_key(living_user, account)
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["userStats"] = SSeconomy.get_cyberpunk_contract_stats(user_character_key)
	data["contracts"] = list()
	data["ownedContracts"] = list()
	data["acceptedContracts"] = list()
	data["directContract"] = null
	for(var/contract_id in SSeconomy.cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = SSeconomy.cyberpunk_contracts[contract_id]
		if(!contract || !contract.can_view(living_user))
			continue
		var/list/contract_data = contract.to_ui_data(living_user, TRUE)
		if(contract.creator_character_key == user_character_key)
			data["ownedContracts"] += list(contract_data)
		if(contract.contractor_character_key == user_character_key)
			data["acceptedContracts"] += list(contract_data)
		if(contract.public_contract && contract.legal && contract.status == "created")
			data["contracts"] += list(contract_data)
	var/datum/cyberpunk_contract/direct_contract = SSeconomy.get_cyberpunk_contract(direct_contract_id)
	if(direct_contract)
		data["directContract"] = direct_contract.to_ui_data(living_user, TRUE)
	return data

/proc/cyberpunk_contract_registry_ui_data(mob/user)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	data["contracts"] = list()
	data["activeCount"] = 0
	data["completedCount"] = 0
	data["failedCount"] = 0
	data["taxRate"] = 5
	for(var/contract_id in SSeconomy.cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = SSeconomy.cyberpunk_contracts[contract_id]
		if(!contract || !contract.legal)
			continue
		if(contract.status in list("created", "accepted"))
			data["activeCount"]++
		else if(contract.status == "completed")
			data["completedCount"]++
		else if(contract.status == "failed")
			data["failedCount"]++
		data["contracts"] += list(contract.to_ui_data(living_user, TRUE))
	return data

/proc/cyberpunk_contracts_ui_act(action, list/params, mob/user)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract
	if(params && params["id"])
		contract = SSeconomy.get_cyberpunk_contract(params["id"])

	switch(action)
		if("create")
			var/datum/cyberpunk_contract/new_contract = SSeconomy.create_cyberpunk_contract(living_user, params)
			if(!new_contract)
				to_chat(living_user, span_warning("Contract creation failed. Check your ID account and reserved payment."))
				return TRUE
			to_chat(living_user, span_notice("Contract #[new_contract.id] created."))
			return TRUE
		if("accept")
			if(contract?.accept(living_user))
				to_chat(living_user, span_notice("Contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this contract."))
			return TRUE
		if("cancel")
			if(contract?.cancel(living_user))
				to_chat(living_user, span_notice("Contract cancelled."))
			else
				to_chat(living_user, span_warning("Unable to cancel this contract."))
			return TRUE
		if("abandon")
			if(contract?.can_act_as_contractor(living_user) && contract.fail("contractor abandoned contract"))
				to_chat(living_user, span_notice("Contract abandoned."))
			else
				to_chat(living_user, span_warning("Unable to abandon this contract."))
			return TRUE
		if("creator_complete")
			if(contract?.can_manage(living_user) && contract.complete("creator confirmed completion"))
				to_chat(living_user, span_notice("Contract completed."))
			else
				to_chat(living_user, span_warning("Unable to complete this contract."))
			return TRUE
		if("submit_held")
			if(contract?.submit_held_item(living_user))
				to_chat(living_user, span_notice("Submission recorded."))
			else
				to_chat(living_user, span_warning("Held item does not satisfy this contract."))
			return TRUE
		if("mark_held")
			if(contract?.mark_held_item(living_user))
				to_chat(living_user, span_notice("Held item marked as contract cargo."))
			else
				to_chat(living_user, span_warning("Unable to mark held item for this contract."))
			return TRUE
		if("check_target")
			if(contract?.check_nearby_target(living_user))
				to_chat(living_user, span_notice("Contract target check recorded."))
			else
				to_chat(living_user, span_warning("No nearby target satisfies this contract."))
			return TRUE
	return FALSE
