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

//CYBERPUNK BUILD - rebuild and delete before release
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

/datum/computer_file/program/contract_pool
	filename = "contractpool"
	filedesc = "Contract Pool"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Corporate pool contracts. These jobs are public offers and can be taken by any contractor."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContractPool"

/datum/computer_file/program/contract_pool/ui_data(mob/user)
	return cyberpunk_contract_pool_ui_data(user)

/datum/computer_file/program/contract_pool/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_pool_ui_act(action, params, ui.user)

/datum/computer_file/program/business_terminal
	filename = "business"
	filedesc = "Business Terminal"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Business management terminal for registration, storage, staff, finance, and logistics."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 6
	program_icon = "building"
	tgui_id = "NtosBusinessTerminal"
	var/business_id

/datum/computer_file/program/business_terminal/ui_data(mob/user)
	return cyberpunk_business_terminal_ui_data(user, business_id)

/datum/computer_file/program/business_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		business_id = params["id"]
		return TRUE
	return cyberpunk_business_terminal_ui_act(action, params, ui.user, null, business_id)

//CYBERPUNK BUILD - rebuild and delete before release
/datum/cyberpunk_contracts_verb_ui
	var/direct_contract_id

/datum/cyberpunk_contracts_verb_ui/ui_state(mob/user)
	return GLOB.always_state

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

/datum/cyberpunk_contract_registry_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_registry_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractRegistry", "Contract Registry")
		ui.open()

/datum/cyberpunk_contract_registry_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_registry_ui_data(user)

/datum/cyberpunk_contract_pool_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_pool_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractPool", "Contract Pool")
		ui.open()

/datum/cyberpunk_contract_pool_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_pool_ui_data(user)

/datum/cyberpunk_contract_pool_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_pool_ui_act(action, params, ui.user)

/datum/cyberpunk_contract_offer_verb_ui
	var/contract_id

/datum/cyberpunk_contract_offer_verb_ui/New(new_contract_id)
	. = ..()
	contract_id = new_contract_id

/datum/cyberpunk_contract_offer_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_offer_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractOffer", "Contract Offer")
		ui.open()

/datum/cyberpunk_contract_offer_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_offer_ui_data(user, contract_id)

/datum/cyberpunk_contract_offer_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_offer_ui_act(action, params, ui.user, contract_id)

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

/mob/living/verb/open_cyberpunk_contract_pool()
	set name = "Contract Pool"
	set desc = "Temporarily open corporate pool contracts without a PDA."
	set category = "IC"

	var/datum/cyberpunk_contract_pool_verb_ui/interface = new
	interface.ui_interact(src)

/obj/machinery/computer/business_terminal
	name = "business terminal"
	desc = "A city business management terminal. It binds a deployed business to a neural interface owner."
	icon_screen = "supply"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = null
	var/business_id
	var/size_class = "small"

/obj/machinery/computer/business_terminal/medium
	name = "medium business terminal"
	size_class = "medium"

/obj/machinery/computer/business_terminal/Destroy()
	var/datum/cyberpunk_business/business = SSeconomy.get_cyberpunk_business(business_id)
	if(business?.terminal == src)
		business.terminal = null
	return ..()

/obj/machinery/computer/business_terminal/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/business_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosBusinessTerminal", name)
		ui.open()

/obj/machinery/computer/business_terminal/ui_data(mob/user)
	return cyberpunk_business_terminal_ui_data(user, business_id, src)

/obj/machinery/computer/business_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		business_id = params["id"]
		return TRUE
	return cyberpunk_business_terminal_ui_act(action, params, ui.user, src, business_id)

/mob/living/verb/create_cyberpunk_business_terminal()
	set name = "Create Business Terminal"
	set desc = "Temporarily create a small business terminal for testing."
	set category = "IC"

	new /obj/machinery/computer/business_terminal(get_turf(src))

/obj/machinery/vending
	var/cyberpunk_business_id
	var/cyberpunk_business_auto_restock = FALSE
	var/cyberpunk_business_markup_percent = 0
	var/cyberpunk_business_minimum_stock = 0

/obj/machinery/vending/proc/cyberpunk_business_record_sale(amount, product_label)
	var/datum/cyberpunk_business/business = SSeconomy.get_cyberpunk_business(cyberpunk_business_id)
	if(!business)
		return FALSE
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	var/business_share = max(0, amount - round(amount * VENDING_CREDITS_COLLECTION_AMOUNT))
	if(!business_share)
		return FALSE
	return business.record_income(business_share, "Business vendor sale at [name]: [product_label]")

/obj/machinery/vending/proc/cyberpunk_business_restock_from_warehouse()
	var/datum/cyberpunk_business/business = SSeconomy.get_cyberpunk_business(cyberpunk_business_id)
	if(!business || !business.warehouse_enabled || !business.warehouse_valid)
		return 0
	var/restocked = 0
	for(var/datum/data/vending_product/record as anything in product_records + coin_records + hidden_records)
		var/target_amount = cyberpunk_business_minimum_stock > 0 ? min(cyberpunk_business_minimum_stock, record.max_amount) : record.max_amount
		var/needed = target_amount - record.amount
		if(needed <= 0)
			continue
		var/taken = business.consume_stock(record.name, needed)
		if(taken < needed)
			taken += business.consume_stock("[record.product_path]", needed - taken)
		if(taken < needed)
			taken += business.consume_stock("goods", needed - taken)
		if(!taken)
			continue
		record.amount += taken
		restocked += taken
	if(restocked)
		business.add_history("[name] restocked [restocked] item(s) from warehouse")
	return restocked
//CYBERPUNK BUILD - rebuild and delete before release

/proc/cyberpunk_contracts_ui_data(mob/user, direct_contract_id = null)
	SSeconomy.ensure_cyberpunk_contract_pool_seeded()
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	var/user_character_key = SSeconomy.get_cyberpunk_contract_character_key(living_user, account)
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["userStats"] = SSeconomy.get_cyberpunk_contract_stats(user_character_key)
	data["contracts"] = list()
	data["offeredContracts"] = list()
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
		if(contract.assigned_contractor_key == user_character_key && contract.status == "offered")
			data["offeredContracts"] += list(contract_data)
		if(contract.public_contract && contract.legal && contract.status == "created")
			data["contracts"] += list(contract_data)
	var/datum/cyberpunk_contract/direct_contract = SSeconomy.get_cyberpunk_contract(direct_contract_id)
	if(direct_contract)
		data["directContract"] = direct_contract.to_ui_data(living_user, TRUE)
	return data

/proc/cyberpunk_contract_pool_ui_data(mob/user)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["contracts"] = list()
	for(var/datum/cyberpunk_contract/contract as anything in SSeconomy.get_cyberpunk_contract_pool())
		if(!contract || !contract.can_view(living_user))
			continue
		data["contracts"] += list(contract.to_ui_data(living_user, TRUE))
	return data

/proc/cyberpunk_contract_offer_ui_data(mob/user, contract_id)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/cyberpunk_contract/contract = SSeconomy.get_cyberpunk_contract(contract_id)
	data["contract"] = contract?.can_view(living_user) ? contract.to_ui_data(living_user, TRUE) : null
	return data

/proc/cyberpunk_business_terminal_ui_data(mob/user, selected_business_id = null, obj/machinery/computer/business_terminal/terminal = null)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["hasNeural"] = living_user?.has_neural_implant() || FALSE
	data["terminalSize"] = terminal?.size_class || "program"
	data["terminalAnchored"] = terminal?.anchored || FALSE
	data["businesses"] = list()
	for(var/datum/cyberpunk_business/business as anything in SSeconomy.get_cyberpunk_businesses_for_user(living_user))
		data["businesses"] += list(business.to_ui_data(living_user, FALSE))
	var/datum/cyberpunk_business/selected = SSeconomy.get_cyberpunk_business(selected_business_id)
	if(!selected?.can_view(living_user))
		selected = null
	if(!selected && length(data["businesses"]))
		var/list/first_business = data["businesses"][1]
		selected = SSeconomy.get_cyberpunk_business(first_business["id"])
	data["business"] = selected?.to_ui_data(living_user, TRUE)
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
		if("refuse_offer")
			if(contract?.refuse_offer(living_user))
				to_chat(living_user, span_notice("Contract offer refused."))
			else
				to_chat(living_user, span_warning("Unable to refuse this contract offer."))
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

/proc/cyberpunk_contract_pool_ui_act(action, list/params, mob/user)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract = params && params["id"] ? SSeconomy.get_cyberpunk_contract(params["id"]) : null
	switch(action)
		if("accept")
			if(contract?.pool_contract && contract.accept(living_user))
				to_chat(living_user, span_notice("Pool contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this pool contract."))
			return TRUE
	return FALSE

/proc/cyberpunk_contract_offer_ui_act(action, list/params, mob/user, contract_id)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract = SSeconomy.get_cyberpunk_contract(contract_id)
	switch(action)
		if("accept")
			if(contract?.accept(living_user))
				to_chat(living_user, span_notice("Contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this contract offer."))
			return TRUE
		if("refuse_offer")
			if(contract?.refuse_offer(living_user))
				to_chat(living_user, span_notice("Contract offer refused."))
			else
				to_chat(living_user, span_warning("Unable to refuse this contract offer."))
			return TRUE
	return FALSE

/proc/cyberpunk_business_terminal_ui_act(action, list/params, mob/user, obj/machinery/computer/business_terminal/terminal = null, selected_business_id = null)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/requested_business_id = params && params["id"] ? params["id"] : selected_business_id
	var/datum/cyberpunk_business/business = SSeconomy.get_cyberpunk_business(requested_business_id)
	switch(action)
		if("create")
			var/datum/cyberpunk_business/new_business = SSeconomy.create_cyberpunk_business(living_user, terminal, params)
			if(!new_business)
				to_chat(living_user, span_warning("Business creation failed. A functional neural interface and a terminal inside a business area are required."))
			else
				to_chat(living_user, span_notice("Business #[new_business.id] created and linked to your neural interface."))
			return TRUE
		if("set_settings")
			if(business?.set_settings(living_user, params))
				to_chat(living_user, span_notice("Business settings updated."))
			else
				to_chat(living_user, span_warning("Unable to update business settings."))
			return TRUE
		if("deposit")
			if(business?.deposit(living_user, text2num(params["amount"])))
				to_chat(living_user, span_notice("Business deposit completed."))
			else
				to_chat(living_user, span_warning("Unable to deposit credits."))
			return TRUE
		if("withdraw")
			if(business?.withdraw(living_user, text2num(params["amount"])))
				to_chat(living_user, span_notice("Business withdrawal completed."))
			else
				to_chat(living_user, span_warning("Unable to withdraw credits."))
			return TRUE
		if("pay_taxes")
			if(business?.pay_taxes(living_user, text2num(params["amount"])))
				to_chat(living_user, span_notice("Business tax payment completed."))
			else
				to_chat(living_user, span_warning("Unable to pay business taxes."))
			return TRUE
		if("set_warehouse")
			if(business?.set_warehouse(living_user, params))
				to_chat(living_user, span_notice("Warehouse settings updated."))
			else
				to_chat(living_user, span_warning("Unable to update warehouse settings."))
			return TRUE
		if("validate_premises")
			if(business?.validate_premises(living_user))
				to_chat(living_user, span_notice("Business premises validated."))
			else
				to_chat(living_user, span_warning("Business premises validation failed."))
			return TRUE
		if("validate_warehouse")
			if(business?.validate_warehouse(living_user))
				to_chat(living_user, span_notice("Warehouse validation passed."))
			else
				to_chat(living_user, span_warning("Warehouse validation failed."))
			return TRUE
		if("request_delivery")
			if(business?.request_delivery(living_user, params["item"], text2num(params["amount"]), params["source"]))
				to_chat(living_user, span_notice("Delivery requested. ETA two minutes."))
			else
				to_chat(living_user, span_warning("Unable to request delivery. Enable and validate warehouse access first."))
			return TRUE
		if("add_employee")
			if(business?.add_employee(living_user, params["name"], text2num(params["wage"])))
				to_chat(living_user, span_notice("Employee added."))
			else
				to_chat(living_user, span_warning("Unable to add employee."))
			return TRUE
		if("remove_employee")
			if(business?.remove_employee(living_user, params["employee"]))
				to_chat(living_user, span_notice("Employee removed."))
			else
				to_chat(living_user, span_warning("Unable to remove employee."))
			return TRUE
		if("set_employee_wage")
			if(business?.set_employee_wage(living_user, params["employee"], text2num(params["wage"])))
				to_chat(living_user, span_notice("Employee wage updated."))
			else
				to_chat(living_user, span_warning("Unable to update employee wage."))
			return TRUE
		if("toggle_employee_access")
			if(business?.toggle_employee_access(living_user, params["employee"], params["access"]))
				to_chat(living_user, span_notice("Employee access updated."))
			else
				to_chat(living_user, span_warning("Unable to update employee access."))
			return TRUE
		if("save")
			if(business?.save_business(living_user))
				to_chat(living_user, span_notice("Business snapshot saved."))
			else
				to_chat(living_user, span_warning("Unable to save business. Only the neural owner can save."))
			return TRUE
		if("load")
			if(business?.load_business(living_user))
				to_chat(living_user, span_notice("Business snapshot loaded."))
			else
				to_chat(living_user, span_warning("Unable to load business. Only one owner load is allowed per round."))
			return TRUE
		if("link_vendors")
			if(business?.link_nearby_vendors(living_user))
				to_chat(living_user, span_notice("Business area vendors linked."))
			else
				to_chat(living_user, span_warning("No vendors inside the business area could be linked."))
			return TRUE
		if("restock_vendors")
			if(business?.restock_linked_vendors(living_user))
				to_chat(living_user, span_notice("Linked vendors restocked from warehouse."))
			else
				to_chat(living_user, span_warning("No linked vendors could be restocked."))
			return TRUE
	return FALSE
//CYBERPUNK BUILD - rebuild and delete before release
