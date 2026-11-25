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

/datum/computer_file/program/business_registry
	filename = "businessregistry"
	filedesc = "City Business Registry"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Public city registry of legal businesses, their directions, locations, and tax standing."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = "building"
	tgui_id = "NtosBusinessRegistry"

/datum/computer_file/program/business_registry/ui_data(mob/user)
	return cyberpunk_business_registry_ui_data(user)
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

/obj/machinery/computer/business_terminal/cyberpunk_test
	var/test_bench_prepared = FALSE

/obj/machinery/computer/business_terminal/cyberpunk_test/ui_data(mob/user)
	var/list/data = ..()
	data["testBench"] = SSmapping.current_map?.map_name == "Cyberpunk Test"
	if(data["testBench"])
		var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
		var/mob/living/customer = user
		data["business"] = istype(customer) && business?.terminal == src && business.can_view(customer) ? business.to_ui_data(customer, TRUE) : null
	return data

/obj/machinery/computer/business_terminal/cyberpunk_test/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(SSmapping.current_map?.map_name == "Cyberpunk Test" && (action in list("create", "select")))
		return FALSE
	. = ..()
	if(. || action != "prepare_test_bench")
		return
	var/mob/living/carbon/user = ui.user
	if(!istype(user) || !Adjacent(user) || !is_operational || SSmapping.current_map?.map_name != "Cyberpunk Test")
		return FALSE
	return prepare_test_bench(user)

/obj/machinery/computer/business_terminal/cyberpunk_test/proc/prepare_test_bench(mob/living/carbon/user)
	var/area/premises = get_area(src)
	if(!istype(premises, /area/cyberpunk/city/business/lot_10/test_shop) && !istype(premises, /area/cyberpunk/city/business/lot_09/test_warehouse))
		return FALSE
	var/datum/bank_account/personal_account = user.get_bank_account()
	if(!personal_account || !user.has_living_brain())
		to_chat(user, span_warning("Для стенда нужен живой персонаж с банковским счётом на ID."))
		return TRUE
	var/datum/cyberpunk_business/business
	for(var/key in SScyberpunk_property.cyberpunk_businesses)
		var/datum/cyberpunk_business/candidate = SScyberpunk_property.cyberpunk_businesses[key]
		if(candidate?.get_business_area() == premises)
			business = candidate
			break
	if(business && !business.is_owner(user))
		to_chat(user, span_warning("У этого стенда уже есть владелец."))
		return TRUE
	if(!user.has_neural_implant() && !user.get_organ_slot(ORGAN_SLOT_NEURAL_IMPLANT))
		var/obj/item/organ/cyberimp/brain/neural_interface/implant = new(get_turf(src))
		if(!implant.Insert(user, special = TRUE))
			qdel(implant)
	if(!user.has_neural_implant())
		to_chat(user, span_warning("Тестовый бизнес требует исправного нейроинтерфейса."))
		return TRUE
	if(!business)
		business = SScyberpunk_property.create_cyberpunk_business(user, src, list("name" = premises.name, "legal" = "1", "registered_to" = "city"))
	if(!business)
		to_chat(user, span_warning("Не удалось зарегистрировать тестовый бизнес."))
		return TRUE
	business_id = business.id
	business.warehouse_enabled = TRUE
	business.validate_premises(user)
	var/obj/structure/cyberpunk_business_unload_zone/zone = business.get_unload_zone()
	if(!zone)
		for(var/turf/loading_tile as anything in business.get_business_turfs())
			var/obj/structure/cyberpunk_business_unload_zone/marker = locate() in loading_tile
			if(marker && !marker.business_id)
				marker.bind_business(business)
				business.warehouse_unload_zone_ref = REF(marker)
				business.warehouse_unload_zone = "[loading_tile.x],[loading_tile.y],[loading_tile.z]"
				break
	if(!business.validate_warehouse(user))
		to_chat(user, span_warning("Площадка 3×3 не прошла проверку."))
		return TRUE
	if(!business.link_nearby_vendors(user))
		to_chat(user, span_warning("В помещении не найден складской автомат."))
		return TRUE
	if(!test_bench_prepared)
		test_bench_prepared = TRUE
		if(personal_account.account_balance < 500)
			personal_account.adjust_money(500 - personal_account.account_balance, "Cyberpunk Test starting credits")
		var/datum/bank_account/business_account = business.get_account()
		if(business_account && business_account.account_balance < 500)
			business_account.adjust_money(500 - business_account.account_balance, "Cyberpunk Test working capital")
	to_chat(user, span_notice("Стенд готов: площадка разгрузки и автомат привязаны. Образцы рядом с терминалом."))
	return TRUE

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
	data["terminalArea"] = terminal ? get_area_name(terminal) : "program"
	data["terminalBusinessArea"] = terminal ? cyberpunk_is_business_area(get_area(terminal)) : FALSE
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
			if(!terminal)
				to_chat(living_user, span_warning("Для регистрации открой стационарный бизнес-терминал в помещении."))
				return TRUE
			var/datum/cyberpunk_business/new_business = SScyberpunk_property.create_cyberpunk_business(living_user, terminal, params)
			if(!new_business)
				to_chat(living_user, span_warning("Регистрация не удалась. Проверь нейроинтерфейс и назначение помещения. В одном помещении может быть только один легальный бизнес."))
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
		if("set_trade_price")
			return business?.set_trade_price(living_user, params["item"], text2num(params["price"]))
		if("set_buyer_adjustment")
			if(business?.set_buyer_adjustment(living_user, params["buyer"], text2num(params["adjustment"])))
				to_chat(living_user, span_notice("Buyer adjustment saved."))
			else
				to_chat(living_user, span_warning("Select a corporation, civilian, or a valid business ID."))
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
		if("deploy_unload_zone")
			if(business?.deploy_unload_zone(living_user))
				to_chat(living_user, span_notice("Warehouse unload zone linked at your position."))
			else
				to_chat(living_user, span_warning("Unable to deploy an unload zone here. Stand inside valid premises and keep this tile free."))
			return TRUE
		if("request_delivery")
			if(business?.request_delivery(living_user, params["item"], text2num(params["amount"]), params["source"]))
				to_chat(living_user, span_notice("Заказ принят. Состояние поставки доступно в списке заказов."))
			else
				to_chat(living_user, span_warning("Заказ не принят. Проверь настройку склада, наличие товара у поставщика и баланс."))
			return TRUE
		if("export_stock")
			if(business?.export_stock(living_user, params["item"], text2num(params["amount"])))
				to_chat(living_user, span_notice("Товар продан за город. Деньги зачислены на счёт бизнеса."))
			else
				to_chat(living_user, span_warning("Продажа не прошла. Проверь количество подходящих товаров и доступ к финансам."))
			return TRUE
		if("deposit_warehouse_item")
			if(business?.deposit_warehouse_item(living_user, living_user.get_active_held_item()))
				to_chat(living_user, span_notice("Held item deposited into the business warehouse."))
			else
				to_chat(living_user, span_warning("Unable to deposit your held item. Stand next to a valid unload zone."))
			return TRUE
		if("absorb_warehouse_items")
			if(business?.absorb_unload_zone_items(living_user))
				to_chat(living_user, span_notice("Предметы с пола площадки приняты на склад."))
			else
				to_chat(living_user, span_warning("На полу площадки 3×3 нет подходящих предметов или склад ещё не настроен."))
			return TRUE
		if("withdraw_warehouse_item")
			if(business?.withdraw_warehouse_item(living_user, params["item"], text2num(params["amount"])))
				to_chat(living_user, span_notice("Предмет выдан на белый квадрат."))
			else
				to_chat(living_user, span_warning("Подойди к белому квадрату и проверь остаток на складе."))
			return TRUE
		if("add_employee")
			if(business?.add_employee(living_user, params["name"], text2num(params["wage"])))
				to_chat(living_user, span_notice("Employee invite sent."))
			else
				to_chat(living_user, span_warning("Unable to invite employee."))
			return TRUE
		if("accept_employee_invite")
			if(business?.accept_employee_invite(living_user))
				to_chat(living_user, span_notice("Employment accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this employment invite."))
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
				to_chat(living_user, span_notice("Дрон отправлен со склада. Автомат примет товар, когда груз прибудет."))
			else
				to_chat(living_user, span_warning("Дрон не отправлен. Проверь товары на складе, остаток в автомате и открытый проход к нему."))
			return TRUE
	return FALSE

/proc/cyberpunk_business_registry_ui_data(mob/user)
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	return list(
		"accountName" = account?.account_holder,
		"businesses" = SScyberpunk_property.get_cyberpunk_public_business_registry(),
	)
