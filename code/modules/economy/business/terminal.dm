//CYBERPUNK BUSINESS - business terminal program, machine and UI bridge.
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
/obj/machinery/computer/business_terminal
	name = "business terminal"
	desc = "A city business management terminal. It binds a deployed business to a neural interface owner."
	icon_screen = "supply"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = null
	var/business_id
	var/size_class = "small"
	cyberpunk_public_access = TRUE

/obj/machinery/computer/business_terminal/medium
	name = "medium business terminal"
	size_class = "medium"

/obj/machinery/computer/business_terminal/Destroy()
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
	if(business?.terminal == src)
		business.terminal = null
	return ..()

/obj/machinery/computer/business_terminal/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/business_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
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
	set desc = "Temporarily create a business terminal for testing."
	set category = "IC"

	new /obj/machinery/computer/business_terminal(get_turf(src))
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
	for(var/datum/cyberpunk_business/business as anything in SScyberpunk_property.get_cyberpunk_businesses_for_user(living_user))
		data["businesses"] += list(business.to_ui_data(living_user, FALSE))
	var/datum/cyberpunk_business/selected = SScyberpunk_property.get_cyberpunk_business(selected_business_id)
	if(!selected?.can_view(living_user))
		selected = null
	if(!selected && length(data["businesses"]))
		var/list/first_business = data["businesses"][1]
		selected = SScyberpunk_property.get_cyberpunk_business(first_business["id"])
	data["business"] = selected?.to_ui_data(living_user, TRUE)
	data["warehouseOptions"] = SScyberpunk_property.get_cyberpunk_business_warehouse_options(selected)
	return data

/proc/cyberpunk_business_terminal_ui_act(action, list/params, mob/user, obj/machinery/computer/business_terminal/terminal = null, selected_business_id = null)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/requested_business_id = params && params["id"] ? params["id"] : selected_business_id
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(requested_business_id)
	switch(action)
		if("create")
			var/datum/cyberpunk_business/new_business = SScyberpunk_property.create_cyberpunk_business(living_user, terminal, params)
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
		if("link_production")
			if(business?.link_nearby_production_machines(living_user))
				to_chat(living_user, span_notice("Business area production machines linked."))
			else
				to_chat(living_user, span_warning("No production machines inside the business area could be linked."))
			return TRUE
		if("restock_vendors")
			if(business?.restock_linked_vendors(living_user))
				to_chat(living_user, span_notice("Linked vendors restocked from warehouse."))
			else
				to_chat(living_user, span_warning("No linked vendors could be restocked."))
			return TRUE
	return FALSE

