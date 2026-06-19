//CYBERPUNK CORPORATIONS - computer app, terminals and verb UI.
/datum/computer_file/program/corporations
	filename = "corporations"
	filedesc = "Корпорации"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Корпоративный реестр исследований, средств, технологий и решений."
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
	name = "корпоративный терминал"
	desc = "Закрытый корпоративный терминал исследований и решений."
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
	name = "корпоративный терминал Benn"
	corporation_id = "benn"
	corp_manufacturer = "Benn"
	light_color = COLOR_GREEN

/obj/machinery/computer/corporate_terminal/ryaznov
	name = "корпоративный терминал Ryaznov"
	corporation_id = "ryaznov"
	corp_manufacturer = "Ryaznov"
	light_color = COLOR_ORANGE

/obj/machinery/computer/corporate_terminal/starlight
	name = "корпоративный терминал Starlight"
	corporation_id = "starlight"
	corp_manufacturer = "Starlight"
	light_color = COLOR_CYAN

/mob/living/verb/create_cyberpunk_corporate_terminal()
	set name = "(НА УДАЛЕНИЕ) Создать корпоративный терминал"
	set desc = "Временно создать закрытый корпоративный терминал для тестирования."
	set category = "IC"

	var/list/choices = list(
		"Benn" = /obj/machinery/computer/corporate_terminal/benn,
		"Ryaznov" = /obj/machinery/computer/corporate_terminal/ryaznov,
		"Starlight" = /obj/machinery/computer/corporate_terminal/starlight,
	)
	var/choice = tgui_input_list(src, "Выберите корпоративный терминал.", "Корпоративный терминал", choices)
	if(!choice)
		return
	var/terminal_type = choices[choice]
	new terminal_type(get_turf(src))

/datum/cyberpunk_corporations_verb_ui
	var/selected_corporation_id

/datum/cyberpunk_corporations_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_corporations_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosCorporations", "Корпорации")
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
