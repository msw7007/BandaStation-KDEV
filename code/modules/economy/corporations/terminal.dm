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
	circuit = /obj/item/circuitboard/computer/corporate_terminal
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
	circuit = /obj/item/circuitboard/computer/corporate_terminal/benn

/obj/machinery/computer/corporate_terminal/ryaznov
	name = "корпоративный терминал Ryaznov"
	corporation_id = "ryaznov"
	corp_manufacturer = "Ryaznov"
	light_color = COLOR_ORANGE
	circuit = /obj/item/circuitboard/computer/corporate_terminal/ryaznov

/obj/machinery/computer/corporate_terminal/starlight
	name = "корпоративный терминал Starlight"
	corporation_id = "starlight"
	corp_manufacturer = "Starlight"
	light_color = COLOR_CYAN
	circuit = /obj/item/circuitboard/computer/corporate_terminal/starlight

/mob/living/verb/create_cyberpunk_corporate_terminal()
	set name = "(TEMP) Create Corporate Terminal"
	set desc = "Temporarily create a restricted corporate terminal for test maps and pre-release setup."
	set category = "IC"

	var/list/choices = list(
		"Benn" = /obj/machinery/computer/corporate_terminal/benn,
		"Ryaznov" = /obj/machinery/computer/corporate_terminal/ryaznov,
		"Starlight" = /obj/machinery/computer/corporate_terminal/starlight,
		"Government" = /obj/machinery/computer/corporate_terminal/government,
	)
	var/choice = tgui_input_list(src, "Choose a corporate terminal.", "Corporate Terminal", choices)
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

/obj/machinery/computer/corporate_terminal/government
	name = "government corporate terminal"
	desc = "A restricted city government terminal for taxes, council votes and emergency directives."
	corporation_id = "government"
	corp_manufacturer = "Government"
	light_color = COLOR_RED
	circuit = /obj/item/circuitboard/computer/corporate_terminal/government

/obj/item/circuitboard/computer/corporate_terminal
	name = "Corporate Terminal"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/corporate_terminal

/obj/item/circuitboard/computer/corporate_terminal/benn
	name = "Benn Corporate Terminal"
	build_path = /obj/machinery/computer/corporate_terminal/benn

/obj/item/circuitboard/computer/corporate_terminal/ryaznov
	name = "Ryaznov Corporate Terminal"
	build_path = /obj/machinery/computer/corporate_terminal/ryaznov

/obj/item/circuitboard/computer/corporate_terminal/starlight
	name = "Starlight Corporate Terminal"
	build_path = /obj/machinery/computer/corporate_terminal/starlight

/obj/item/circuitboard/computer/corporate_terminal/government
	name = "Government Corporate Terminal"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/corporate_terminal/government

/datum/design/cyberpunk_corporate_terminal_board
	name = "Corporate Terminal Board"
	id = "cyberpunk_corporate_terminal_board"
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/circuitboard/computer/corporate_terminal
	category = list(
		RND_CATEGORY_INITIAL,
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_ELECTRONICS,
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/cyberpunk_corporate_terminal_board/benn
	name = "Benn Corporate Terminal Board"
	id = "cyberpunk_benn_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_terminal/benn

/datum/design/cyberpunk_corporate_terminal_board/ryaznov
	name = "Ryaznov Corporate Terminal Board"
	id = "cyberpunk_ryaznov_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_terminal/ryaznov

/datum/design/cyberpunk_corporate_terminal_board/starlight
	name = "Starlight Corporate Terminal Board"
	id = "cyberpunk_starlight_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_terminal/starlight

/datum/design/cyberpunk_corporate_terminal_board/government
	name = "Government Corporate Terminal Board"
	id = "cyberpunk_government_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_terminal/government
	departmental_flags = DEPARTMENT_BITFLAG_COMMAND | DEPARTMENT_BITFLAG_ENGINEERING
