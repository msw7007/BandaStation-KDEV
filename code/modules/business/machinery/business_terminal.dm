/obj/machinery/computer/cy_business_terminal
	name = "business terminal"
	desc = "A civic terminal for registering and managing a persistent business."
	icon_screen = "id"
	var/obj/structure/cy_business_zone/linked_zone

/obj/machinery/computer/cy_business_terminal/Initialize(mapload)
	. = ..()
	if(!linked_zone)
		linked_zone = find_zone_in_area()
	if(linked_zone)
		linked_zone.linked_terminal = src

/obj/machinery/computer/cy_business_terminal/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!user)
		return
	ui_interact(user)

/obj/machinery/computer/cy_business_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkBusinessTerminal", name)
		ui.open()

/obj/machinery/computer/cy_business_terminal/ui_data(mob/user)
	var/list/data = list()
	var/area/current_area = get_area(src)
	data["zone"] = current_area?.cy_describe_zone()
	data["has_zone"] = !!linked_zone
	data["zone_size"] = linked_zone?.size_type
	var/datum/cy_business/business = linked_zone?.active_business
	data["business"] = business ? business.to_list() : null
	data["can_manage"] = business?.can_manage(user) || FALSE
	data["warehouses"] = SScy_business.get_warehouse_ui_data(business)
	data["user_businesses"] = list()
	for(var/datum/cy_business/user_business as anything in SScy_business.get_user_businesses(user))
		data["user_businesses"] += list(user_business.to_list())
	return data

/obj/machinery/computer/cy_business_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	var/datum/cy_business/business = linked_zone?.active_business
	switch(action)
		if("create")
			var/business_name = tgui_input_text(user, "Business name", "Create business", "New Business", MAX_NAME_LEN)
			if(!business_name)
				return TRUE
			var/business_type = tgui_input_text(user, "Business direction/type", "Create business", "general", MAX_NAME_LEN)
			var/legal_status = tgui_input_list(user, "Legal status", "Create business", list(CY_BUSINESS_LEGAL, CY_BUSINESS_FRONT, CY_BUSINESS_ILLEGAL))
			create_business_for(user, business_name, legal_status || CY_BUSINESS_LEGAL, business_type || "general")
			return TRUE
		if("save")
			save_business(user)
			return TRUE
		if("load")
			load_business(user)
			return TRUE
		if("pay_tax")
			var/amount = text2num(params["amount"]) || CY_BUSINESS_DEFAULT_TAX_DUE
			pay_tax(user, amount)
			return TRUE
		if("add_employee")
			if(!business || !business.can_manage(user))
				return TRUE
			var/ckey = ckey(tgui_input_text(user, "Employee ckey", "Add employee", "", MAX_NAME_LEN))
			if(!ckey)
				return TRUE
			var/wage = tgui_input_number(user, "Wage", "Add employee", 0, max_value = 100000, min_value = 0)
			var/permission = tgui_input_list(user, "Permission", "Add employee", list("worker", "manager"))
			business.add_employee(ckey, wage || 0, permission || "worker")
			return TRUE
		if("remove_employee")
			if(!business || !business.can_manage(user))
				return TRUE
			business.remove_employee(params["ckey"])
			return TRUE
		if("toggle_corp_item")
			if(!business || !business.can_manage(user))
				return TRUE
			var/corporation_id = params["corporation_id"]
			var/item_type = params["item_type"]
			var/allowed = params["allowed"]
			business.cy_set_corporate_storage_permission(corporation_id, item_type, !allowed)
			return TRUE
		if("add_corp_item")
			if(!business || !business.can_manage(user))
				return TRUE
			var/corporation_id = tgui_input_text(user, "Corporation id", "Storage permission", "", MAX_NAME_LEN)
			var/item_type = tgui_input_text(user, "Allowed item type path", "Storage permission", "/obj/item", MAX_MESSAGE_LEN)
			if(corporation_id && text2path(item_type))
				business.cy_set_corporate_storage_permission(corporation_id, item_type, TRUE)
			return TRUE

/obj/machinery/computer/cy_business_terminal/proc/find_zone_in_area()
	var/area/current_area = get_area(src)
	if(!current_area)
		return null
	for(var/turf/area_turf as anything in get_area_turfs(current_area))
		var/obj/structure/cy_business_zone/found_zone = locate(/obj/structure/cy_business_zone) in area_turf
		if(found_zone)
			return found_zone
	return null

/obj/machinery/computer/cy_business_terminal/proc/show_business_status(mob/user)
	var/area/current_area = get_area(src)
	var/list/zone = current_area?.cy_describe_zone()
	if(zone)
		to_chat(user, span_notice("Zone: [zone["name"]], security [zone["security_level"]], controller [zone["controller"] || "none"]."))
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business)
		to_chat(user, span_notice("Business zone is free. Use cy_create_business() in code/admin tooling or map verbs to register it."))
		return
	to_chat(user, span_notice("Business: [business.name] ([business.business_id])"))
	to_chat(user, span_notice("Status: [business.legal_status], risk [business.refresh_risk()]%, tax debt [business.tax_debt]."))
	to_chat(user, span_notice("Balance: [business.account?.account_balance || 0]. Employees: [length(business.employees)]."))

/obj/machinery/computer/cy_business_terminal/proc/create_business_for(mob/user, business_name, legal_status = CY_BUSINESS_LEGAL, business_type = "general")
	if(!linked_zone || linked_zone.active_business)
		return null
	return SScy_business.create_business(business_name, user?.ckey, linked_zone, legal_status, business_type)

/obj/machinery/computer/cy_business_terminal/proc/save_business(mob/user)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	return business.save_to_disk()

/obj/machinery/computer/cy_business_terminal/proc/load_business(mob/user)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	if(!business.load_from_disk())
		return FALSE
	return business.restore_snapshot()

/obj/machinery/computer/cy_business_terminal/proc/pay_tax(mob/user, amount = CY_BUSINESS_DEFAULT_TAX_DUE)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	return business.pay_tax(amount)
