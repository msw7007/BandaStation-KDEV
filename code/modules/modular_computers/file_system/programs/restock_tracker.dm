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

/datum/computer_file/program/corporations
	filename = "corporations"
	filedesc = "Corporations"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Corporate registry for research, funds, technologies, and corporate decisions."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 6
	program_icon = "building-columns"
	tgui_id = "NtosCorporations"
	var/selected_corporation_id

/datum/computer_file/program/corporations/ui_data(mob/user)
	return cyberpunk_corporations_ui_data(user, selected_corporation_id)

/datum/computer_file/program/corporations/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		selected_corporation_id = params["corporation_id"]
		return TRUE
	return cyberpunk_corporations_ui_act(action, params, ui.user)

/obj/machinery/computer/corporate_terminal
	name = "corporate terminal"
	desc = "A locked corporate research and decision terminal."
	icon_screen = "rdcomp"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = null
	var/corporation_id = "benn"
	var/corp_manufacturer = "Benn"

/obj/machinery/computer/corporate_terminal/Initialize(mapload)
	. = ..()
	var/access_id = cyberpunk_corporation_access_id(corporation_id)
	if(access_id)
		add_cyberpunk_crypto_key(create_cyberpunk_crypto_access_key(access_id))

/obj/machinery/computer/corporate_terminal/attack_hand(mob/user, list/modifiers)
	var/mob/living/living_user = user
	if(!istype(living_user) || !has_cyberpunk_crypto_access(living_user))
		to_chat(user, span_warning("[src] rejects your cryptokey handshake."))
		return TRUE
	ui_interact(user)
	return TRUE

/obj/machinery/computer/corporate_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosCorporations", name)
		ui.open()

/obj/machinery/computer/corporate_terminal/ui_data(mob/user)
	return cyberpunk_corporations_ui_data(user, corporation_id, corporation_id)

/obj/machinery/computer/corporate_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	params["corporation_id"] = corporation_id
	if(action == "select")
		return TRUE
	return cyberpunk_corporations_ui_act(action, params, ui.user)

/obj/machinery/computer/corporate_terminal/benn
	name = "Benn corporate terminal"
	corporation_id = "benn"
	corp_manufacturer = "Benn"
	light_color = COLOR_GREEN

/obj/machinery/computer/corporate_terminal/ryaznov
	name = "Ryaznov corporate terminal"
	corporation_id = "ryaznov"
	corp_manufacturer = "Ryaznov"
	light_color = COLOR_ORANGE

/obj/machinery/computer/corporate_terminal/starlight
	name = "Starlight corporate terminal"
	corporation_id = "starlight"
	corp_manufacturer = "Starlight"
	light_color = COLOR_CYAN

/mob/living/verb/create_cyberpunk_corporate_terminal()
	set name = "Create Corporate Terminal"
	set desc = "Temporarily create a locked corporate terminal for testing."
	set category = "IC"

	var/list/choices = list(
		"Benn" = /obj/machinery/computer/corporate_terminal/benn,
		"Ryaznov" = /obj/machinery/computer/corporate_terminal/ryaznov,
		"Starlight" = /obj/machinery/computer/corporate_terminal/starlight,
	)
	var/choice = tgui_input_list(src, "Select corporate terminal.", "Corporate terminal", choices)
	if(!choice)
		return
	var/terminal_type = choices[choice]
	new terminal_type(get_turf(src))

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

/datum/cyberpunk_corporations_verb_ui
	var/selected_corporation_id

/datum/cyberpunk_corporations_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_corporations_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosCorporations", "Corporations")
		ui.open()

/datum/cyberpunk_corporations_verb_ui/ui_data(mob/user)
	return cyberpunk_corporations_ui_data(user, selected_corporation_id)

/datum/cyberpunk_corporations_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		selected_corporation_id = params["corporation_id"]
		return TRUE
	return cyberpunk_corporations_ui_act(action, params, ui.user)

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

/datum/cyberpunk_temporary_interface_verb_ui
	var/interface_mode = "generic"
	var/interface_title = "Temporary Interface"

/datum/cyberpunk_temporary_interface_verb_ui/New(new_mode, new_title)
	. = ..()
	interface_mode = new_mode || interface_mode
	interface_title = new_title || interface_title

/datum/cyberpunk_temporary_interface_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_temporary_interface_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkTemporaryInterface", interface_title)
		ui.open()

/datum/cyberpunk_temporary_interface_verb_ui/ui_data(mob/user)
	var/mob/living/living_user = istype(user, /mob/living) ? user : null
	var/obj/item/card/id/access_card
	if(living_user)
		access_card = living_user.get_cyberpunk_access_card()
	return list(
		"mode" = interface_mode,
		"title" = interface_title,
		"userName" = user?.name || "unknown",
		"status" = "temporary development entrypoint",
		"hasNeuralInterface" = istype(living_user) && living_user.has_neural_implant(),
		"accessCard" = access_card?.name,
		"memoryKeys" = length(living_user?.cyberpunk_crypto_memory),
	)

/datum/cyberpunk_temporary_interface_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(interface_mode != "neurolink")
		return FALSE
	var/mob/living/living_user = istype(ui.user, /mob/living) ? ui.user : null
	if(!living_user)
		return FALSE
	switch(action)
		if("sync_card")
			var/result = living_user.sync_cyberpunk_access_card_to_neural_interface()
			to_chat(living_user, span_notice(result))
			return TRUE
	return FALSE

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

/mob/living/verb/open_cyberpunk_corporations()
	set name = "Corporate Interface"
	set desc = "Temporarily open the corporate research and decisions interface."
	set category = "IC"

	var/datum/cyberpunk_corporations_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_neurolink_interface()
	set name = "Neurolink Interface"
	set desc = "Temporarily open the neurolink interface shell."
	set category = "IC"

	var/datum/cyberpunk_temporary_interface_verb_ui/interface = new("neurolink", "Neurolink Interface")
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_pc_interface()
	set name = "PC Interface"
	set desc = "Temporarily open the personal computer interface shell."
	set category = "IC"

	var/datum/cyberpunk_temporary_interface_verb_ui/interface = new("pc", "PC Interface")
	interface.ui_interact(src)

/obj/machinery/computer/apartment_terminal
	name = "apartment terminal"
	desc = "A residential persistence terminal. It binds an apartment area to a neural interface owner."
	icon_screen = "supply"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = null
	var/apartment_id
	cyberpunk_public_access = TRUE

/obj/machinery/computer/apartment_terminal/Destroy()
	var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.get_cyberpunk_apartment(apartment_id)
	if(apartment?.terminal == src)
		apartment.terminal = null
	return ..()

/obj/machinery/computer/apartment_terminal/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/apartment_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosApartmentTerminal", name)
		ui.open()

/obj/machinery/computer/apartment_terminal/ui_data(mob/user)
	return cyberpunk_apartment_terminal_ui_data(user, apartment_id, src)

/obj/machinery/computer/apartment_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		apartment_id = params["id"]
		return TRUE
	return cyberpunk_apartment_terminal_ui_act(action, params, ui.user, src, apartment_id)

/mob/living/verb/create_cyberpunk_apartment_terminal()
	set name = "Create Apartment Terminal"
	set desc = "Temporarily create an apartment persistence terminal for testing."
	set category = "IC"

	new /obj/machinery/computer/apartment_terminal(get_turf(src))

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
	data["terminalOptions"] = SSeconomy.get_cyberpunk_contract_terminal_options()
	data["fundingOptions"] = list(list(
		"id" = 0,
		"name" = "Personal account",
		"balance" = account?.account_balance || 0,
	))
	for(var/datum/cyberpunk_business/business as anything in SScyberpunk_property.get_cyberpunk_businesses_for_user(living_user))
		if(!business?.has_access(living_user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS))
			continue
		var/datum/bank_account/business_account = business.get_account()
		data["fundingOptions"] += list(list(
			"id" = business.id,
			"name" = business.name,
			"balance" = business_account?.account_balance || 0,
		))
	for(var/contract_id in SSeconomy.cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = SSeconomy.cyberpunk_contracts[contract_id]
		if(!contract || !contract.can_view(living_user))
			continue
		var/list/contract_data = contract.to_ui_data(living_user, TRUE)
		if(contract.creator_character_key == user_character_key || contract.can_manage(living_user))
			data["ownedContracts"] += list(contract_data)
		if(contract.contractor_character_key == user_character_key)
			data["acceptedContracts"] += list(contract_data)
		if(contract.assigned_contractor_key == user_character_key && contract.status == "offered")
			data["offeredContracts"] += list(contract_data)
		if(contract.public_contract && contract.legal && contract.status == "created")
			data["contracts"] += list(contract_data)
	var/datum/cyberpunk_contract/direct_contract = SSeconomy.get_cyberpunk_contract(direct_contract_id)
	if(direct_contract?.can_direct_lookup(living_user, direct_contract_id))
		data["directContract"] = direct_contract.to_ui_data(living_user, TRUE)
	else
		for(var/contract_key in SSeconomy.cyberpunk_contracts)
			var/datum/cyberpunk_contract/private_contract = SSeconomy.cyberpunk_contracts[contract_key]
			if(private_contract?.can_direct_lookup(living_user, direct_contract_id))
				data["directContract"] = private_contract.to_ui_data(living_user, TRUE)
				break
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

/proc/cyberpunk_apartment_terminal_ui_data(mob/user, selected_apartment_id = null, obj/machinery/computer/apartment_terminal/terminal = null)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["hasNeural"] = living_user?.has_neural_implant() || FALSE
	data["terminalAnchored"] = terminal?.anchored || FALSE
	data["apartments"] = list()
	for(var/datum/cyberpunk_apartment/apartment as anything in SScyberpunk_property.get_cyberpunk_apartments_for_user(living_user))
		data["apartments"] += list(apartment.to_ui_data(living_user, FALSE))
	var/datum/cyberpunk_apartment/selected = SScyberpunk_property.get_cyberpunk_apartment(selected_apartment_id)
	if(!selected?.can_view(living_user))
		selected = null
	if(!selected && length(data["apartments"]))
		var/list/first_apartment = data["apartments"][1]
		selected = SScyberpunk_property.get_cyberpunk_apartment(first_apartment["id"])
	data["apartment"] = selected?.to_ui_data(living_user, TRUE)
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

/proc/cyberpunk_apartment_terminal_ui_act(action, list/params, mob/user, obj/machinery/computer/apartment_terminal/terminal = null, selected_apartment_id = null)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/requested_apartment_id = params && params["id"] ? params["id"] : selected_apartment_id
	var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.get_cyberpunk_apartment(requested_apartment_id)
	switch(action)
		if("create")
			var/datum/cyberpunk_apartment/new_apartment = SScyberpunk_property.create_cyberpunk_apartment(living_user, terminal, params)
			if(!new_apartment)
				to_chat(living_user, span_warning("Apartment binding failed. A functional neural interface and a terminal inside dormitory apartment area are required."))
			else
				to_chat(living_user, span_notice("Apartment #[new_apartment.id] linked to your neural interface."))
			return TRUE
		if("save")
			if(apartment?.save_apartment(living_user))
				to_chat(living_user, span_notice("Apartment snapshot saved."))
			else
				to_chat(living_user, span_warning("Unable to save apartment. Only the neural owner can save."))
			return TRUE
		if("load")
			if(apartment?.load_apartment(living_user))
				to_chat(living_user, span_notice("Apartment snapshot loaded."))
			else
				to_chat(living_user, span_warning("Unable to load apartment. Only one owner load is allowed per round."))
			return TRUE
	return FALSE
//CYBERPUNK BUILD - rebuild and delete before release
