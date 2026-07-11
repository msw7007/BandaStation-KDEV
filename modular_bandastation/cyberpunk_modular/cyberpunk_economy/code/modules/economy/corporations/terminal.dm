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

/datum/computer_file/program/corporate_research
	filename = "corp_research"
	filedesc = "Corporate Research"
	extended_desc = "Restricted corporate research application."
	program_flags = NONE
	can_run_on_flags = PROGRAM_CONSOLE
	program_open_overlay = "generic"
	program_icon = "flask"
	tgui_id = "CyberpunkCorporateMinigame"
	always_update_ui = TRUE
	var/corporation_id = CYBERPUNK_CORP_BENN
	var/data_type
	var/game_id = "research"
	var/collection_cooldown = 5 MINUTES
	var/next_collection_at = 0
	var/minigame_reward = 50
	var/datum/cyberpunk_corporate_minigame/session

/datum/computer_file/program/corporate_research/New()
	. = ..()
	var/access_id = cyberpunk_corporation_access_id(corporation_id, "specialist")
	if(access_id)
		run_access = list(access_id)

/datum/computer_file/program/corporate_research/can_run(mob/user, loud = FALSE, access_to_check, downloading = FALSE, list/access)
	var/mob/living/living_user = user
	var/access_id = cyberpunk_corporation_access_id(corporation_id, "specialist")
	if(istype(living_user) && living_user.has_cyberpunk_crypto_access(access_id))
		return TRUE
	return ..()

/datum/computer_file/program/corporate_research/on_start(mob/living/user)
	. = ..()
	if(!.)
		return FALSE
	QDEL_NULL(session)
	session = new(src, user, game_id)
	return TRUE

/datum/computer_file/program/corporate_research/kill_program(mob/user)
	QDEL_NULL(session)
	return ..()

/datum/computer_file/program/corporate_research/proc/can_use_minigame(mob/living/user)
	if(!istype(user) || !computer || !computer.Adjacent(user))
		return FALSE
	var/access_id = cyberpunk_corporation_access_id(corporation_id, "specialist")
	if(user.has_cyberpunk_crypto_access(access_id))
		return TRUE
	return can_run(user, FALSE)

/datum/computer_file/program/corporate_research/proc/complete_corporate_minigame(mob/living/user, completed_game_id)
	if(completed_game_id != "research" && world.time < next_collection_at)
		return FALSE
	if(!can_use_minigame(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	var/collected_data_type = data_type || corporation.get_primary_data_type()
	var/reward = get_cyberpunk_corporate_minigame_reward(completed_game_id, minigame_reward)
	if(!SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation.id, collected_data_type, reward, 0, "[completed_game_id] completed by [user.real_name || user.name]"))
		return FALSE
	next_collection_at = world.time + collection_cooldown
	to_chat(user, span_notice("[filedesc] uploads [reward] [collected_data_type] data to [corporation.name]."))
	return TRUE

/datum/computer_file/program/corporate_research/proc/record_corporate_research_correction(mob/living/user)
	if(!can_use_minigame(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	var/collected_data_type = data_type || corporation.get_primary_data_type()
	return SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation.id, collected_data_type, 1, 0, "Research correction by [user.real_name || user.name]")

/datum/computer_file/program/corporate_research/ui_data(mob/user)
	if(!session || session.owner != user)
		session = new(src, user, game_id)
	return session.ui_data(user)

/datum/computer_file/program/corporate_research/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!session || session.owner != ui.user)
		session = new(src, ui.user, game_id)
	return session.ui_act(action, params, ui, state)

/datum/computer_file/program/corporate_research/benn_dr_mario
	filename = "benn_dr_mario"
	filedesc = "Benn: Dr. Mario"
	corporation_id = CYBERPUNK_CORP_BENN
	data_type = "bio"
	game_id = "dr_mario"

/datum/computer_file/program/corporate_research/benn_triple_town
	filename = "benn_triple_town"
	filedesc = "Benn: Triple Town"
	corporation_id = CYBERPUNK_CORP_BENN
	data_type = "bio"
	game_id = "triple_town"

/datum/computer_file/program/corporate_research/benn_research
	filename = "benn_research"
	filedesc = "Benn: Research"
	corporation_id = CYBERPUNK_CORP_BENN
	data_type = "bio"
	game_id = "research"

/datum/computer_file/program/corporate_research/ryaznov_pipe_mania
	filename = "ryaznov_pipe_mania"
	filedesc = "Ryaznov: Pipe Mania"
	corporation_id = CYBERPUNK_CORP_RYAZNOV
	data_type = "engineering"
	game_id = "pipe_mania"

/datum/computer_file/program/corporate_research/ryaznov_robozzle
	filename = "ryaznov_robozzle"
	filedesc = "Ryaznov: RoboZZle"
	corporation_id = CYBERPUNK_CORP_RYAZNOV
	data_type = "engineering"
	game_id = "robozzle"

/datum/computer_file/program/corporate_research/ryaznov_research
	filename = "ryaznov_research"
	filedesc = "Ryaznov: Research"
	corporation_id = CYBERPUNK_CORP_RYAZNOV
	data_type = "engineering"
	game_id = "research"

/datum/computer_file/program/corporate_research/starlight_minesweeper
	filename = "starlight_minesweeper"
	filedesc = "Starlight: Minesweeper"
	corporation_id = CYBERPUNK_CORP_STARLIGHT
	data_type = "market"
	game_id = "minesweeper"

/datum/computer_file/program/corporate_research/starlight_papers
	filename = "starlight_papers"
	filedesc = "Starlight: Papers"
	corporation_id = CYBERPUNK_CORP_STARLIGHT
	data_type = "market"
	game_id = "papers_please"

/datum/computer_file/program/corporate_research/starlight_research
	filename = "starlight_research"
	filedesc = "Starlight: Research"
	corporation_id = CYBERPUNK_CORP_STARLIGHT
	data_type = "market"
	game_id = "research"

/obj/machinery/modular_computer/preset/corporate_terminal
	name = "corporate research terminal"
	desc = "A restricted corporate computer with preloaded management and research software."
	starting_programs = list(/datum/computer_file/program/corporations)

/obj/machinery/modular_computer/preset/corporate_terminal/benn
	name = "Benn research terminal"
	starting_programs = list(
		/datum/computer_file/program/corporations,
		/datum/computer_file/program/corporate_research/benn_dr_mario,
		/datum/computer_file/program/corporate_research/benn_triple_town,
		/datum/computer_file/program/corporate_research/benn_research,
	)

/obj/machinery/modular_computer/preset/corporate_terminal/ryaznov
	name = "Ryaznov research terminal"
	starting_programs = list(
		/datum/computer_file/program/corporations,
		/datum/computer_file/program/corporate_research/ryaznov_pipe_mania,
		/datum/computer_file/program/corporate_research/ryaznov_robozzle,
		/datum/computer_file/program/corporate_research/ryaznov_research,
	)

/obj/machinery/modular_computer/preset/corporate_terminal/starlight
	name = "Starlight research terminal"
	starting_programs = list(
		/datum/computer_file/program/corporations,
		/datum/computer_file/program/corporate_research/starlight_minesweeper,
		/datum/computer_file/program/corporate_research/starlight_papers,
		/datum/computer_file/program/corporate_research/starlight_research,
	)

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
	var/access_id = corporation_id == "government" ? cyberpunk_corporation_access_id(corporation_id) : cyberpunk_corporation_access_id(corporation_id, "head")
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

/obj/machinery/computer/corporate_data_terminal
	name = "corporate data terminal"
	desc = "A restricted corporate workstation for collecting field research data."
	icon_screen = "rdcomp"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = /obj/item/circuitboard/computer/corporate_data_terminal
	var/corporation_id = "benn"
	var/data_type
	var/data_amount = 5
	var/collection_cooldown = 5 MINUTES
	var/next_collection_at = 0
	var/minigame_reward = 50
	var/next_ai_theory_at = 0

/obj/machinery/computer/corporate_data_terminal/Initialize(mapload)
	. = ..()
	var/access_id = cyberpunk_corporation_access_id(corporation_id, "specialist")
	if(access_id)
		req_access = list(access_id)

/obj/machinery/computer/corporate_data_terminal/attack_hand(mob/user, list/modifiers)
	var/mob/living/living_user = user
	var/access_id = cyberpunk_corporation_access_id(corporation_id, "specialist")
	if(!istype(living_user) || !living_user.has_cyberpunk_crypto_access(access_id))
		to_chat(user, span_warning("[src] rejects your specialist cryptokey handshake."))
		return TRUE
	var/list/games = get_corporate_minigames()
	var/choice = tgui_input_list(user, "Choose a research task.", name, games)
	if(!choice || !living_user.Adjacent(src))
		return TRUE
	var/game_id = games[choice]
	if(game_id != "research" && world.time < next_collection_at)
		to_chat(user, span_warning("[src] is still compiling data."))
		return TRUE
	var/datum/cyberpunk_corporate_minigame/session = new(src, living_user, game_id)
	session.ui_interact(living_user)
	return TRUE

/obj/machinery/computer/corporate_data_terminal/proc/get_corporate_minigames()
	switch(corporation_id)
		if(CYBERPUNK_CORP_BENN)
			return list("Dr. Mario" = "dr_mario", "Triple Town" = "triple_town", "Research" = "research")
		if(CYBERPUNK_CORP_RYAZNOV)
			return list("Pipe Mania" = "pipe_mania", "RoboZZle" = "robozzle", "Research" = "research")
		if(CYBERPUNK_CORP_STARLIGHT)
			return list("Minesweeper" = "minesweeper", "Papers, Please" = "papers_please", "Research" = "research")
	return list()

/obj/machinery/computer/corporate_data_terminal/proc/complete_corporate_minigame(mob/living/user, game_id)
	if(!user?.Adjacent(src) || world.time < next_collection_at)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	var/collected_data_type = data_type || corporation.get_primary_data_type()
	var/reward = get_cyberpunk_corporate_minigame_reward(game_id, minigame_reward)
	if(!SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation.id, collected_data_type, reward, 0, "[game_id] completed by [user.real_name || user.name]"))
		return FALSE
	next_collection_at = world.time + collection_cooldown
	to_chat(user, span_notice("[src] uploads [reward] [collected_data_type] data to [corporation.name]."))
	return TRUE

/proc/get_cyberpunk_corporate_minigame_reward(game_id, default_reward = 50)
	switch(game_id)
		if("triple_town")
			return 10
		if("pipe_mania")
			return 5
		if("minesweeper")
			return 10
		if("papers_please")
			return 5
	return default_reward

/obj/machinery/computer/corporate_data_terminal/proc/record_corporate_research_correction(mob/living/user)
	if(!user?.Adjacent(src))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	var/collected_data_type = data_type || corporation.get_primary_data_type()
	return SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation.id, collected_data_type, 1, 0, "Research correction by [user.real_name || user.name]")

/obj/machinery/computer/corporate_data_terminal/proc/record_ai_theory_tick(mob/living/worker)
	if(!worker?.Adjacent(src) || world.time < next_ai_theory_at)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	var/collected_data_type = data_type || corporation.get_primary_data_type()
	if(!SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation.id, collected_data_type, 1, 0, "AI theory work by [worker.real_name || worker.name]"))
		return FALSE
	next_ai_theory_at = world.time + 1 SECONDS
	return TRUE

// Per-player game sessions keep board state out of terminals and the shared economy subsystem.
/datum/cyberpunk_corporate_minigame
	var/terminal
	var/mob/living/owner
	var/game_id
	var/completed = FALSE
	var/result = ""
	var/progress = 0
	var/errors = 0
	var/list/dr_board
	var/list/dr_current_pill
	var/list/dr_next_pill
	var/list/triple_board
	var/triple_next_level = 1
	var/triple_merges = 0
	var/list/pipe_board
	var/pipe_flow_started = FALSE
	var/list/robo_program = list()
	var/robo_x = 0
	var/robo_y = 4
	var/robo_direction = "north"
	var/list/robo_stars
	var/list/robo_tiles
	var/list/robo_animation_steps = list()
	var/robo_animation_index = 0
	var/robo_animation_next_at = 0
	var/robo_animation_success = FALSE
	var/list/mine_bombs
	var/list/mine_open = list()
	var/list/mine_flags = list()
	var/list/papers_cases
	var/papers_index = 1
	var/research_active_cell = -1
	var/research_active_until = 0
	var/research_next_at = 0

/datum/cyberpunk_corporate_minigame/New(new_terminal, mob/living/new_owner, new_game_id)
	. = ..()
	terminal = new_terminal
	owner = new_owner
	game_id = new_game_id
	initialize_game()

/datum/cyberpunk_corporate_minigame/proc/terminal_available(mob/living/user)
	if(istype(terminal, /datum/computer_file/program/corporate_research))
		var/datum/computer_file/program/corporate_research/research_program = terminal
		return research_program.can_use_minigame(user)
	var/atom/terminal_atom = terminal
	return terminal_atom && !QDELETED(terminal_atom) && user.Adjacent(terminal_atom)

/datum/cyberpunk_corporate_minigame/proc/can_view(mob/living/user)
	return user == owner && terminal_available(user)

/datum/cyberpunk_corporate_minigame/proc/can_use(mob/living/user)
	return !completed && can_view(user)

/datum/cyberpunk_corporate_minigame/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_corporate_minigame/ui_status(mob/user, datum/ui_state/state)
	if(!can_view(user))
		return UI_CLOSE
	return completed ? UI_UPDATE : UI_INTERACTIVE

/datum/cyberpunk_corporate_minigame/ui_interact(mob/user, datum/tgui/ui)
	if(!can_use(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkCorporateMinigame", get_game_name())
		ui.open()

/datum/cyberpunk_corporate_minigame/proc/get_game_name()
	switch(game_id)
		if("dr_mario") return "Benn: Dr. Mario"
		if("triple_town") return "Benn: Triple Town"
		if("pipe_mania") return "Ryaznov: Pipe Mania"
		if("robozzle") return "Ryaznov: RoboZZle"
		if("minesweeper") return "Starlight: Minesweeper"
		if("papers_please") return "Starlight: Papers, Please"
		if("research") return "Corporate research cleanup"
	return "Corporate research task"

/datum/cyberpunk_corporate_minigame/proc/initialize_game()
	switch(game_id)
		if("dr_mario")
			initialize_dr_mario()
		if("triple_town")
			triple_board = list(
				list(1, 1, 0, 0, 0, 0),
				list(1, 0, 0, -1, 0, 0),
				list(0, 0, 2, 0, 0, 0),
				list(0, 0, 2, 0, -2, 0),
				list(0, 0, 0, 0, 0, 0),
				list(-1, 0, 0, 0, 0, 0),
			)
			triple_next_level = 1
		if("pipe_mania")
			initialize_pipe_board()
		if("robozzle")
			initialize_robozzle()
		if("minesweeper")
			initialize_minesweeper()
		if("papers_please")
			initialize_papers()
		if("research")
			research_next_at = world.time

/datum/cyberpunk_corporate_minigame/proc/initialize_pipe_board()
	var/list/patterns = list(
		list(list(0, 0), list(1, 0), list(2, 0), list(3, 0), list(3, 1), list(2, 1), list(1, 1), list(0, 1), list(0, 2), list(0, 3)),
		list(list(0, 0), list(0, 1), list(1, 1), list(2, 1), list(2, 2), list(1, 2), list(1, 3), list(0, 3)),
		list(list(0, 0), list(1, 0), list(1, 1), list(2, 1), list(3, 1), list(3, 2), list(2, 2), list(2, 3), list(1, 3), list(0, 3)),
		list(list(0, 0), list(0, 1), list(0, 2), list(1, 2), list(2, 2), list(3, 2), list(3, 3), list(2, 3), list(1, 3), list(0, 3)),
	)
	var/list/path = pick(patterns)
	var/list/solution = list()
	for(var/i in 1 to length(path))
		var/list/point = path[i]
		var/list/directions = list()
		if(i > 1)
			directions += pipe_direction_to(point, path[i - 1])
		if(i < length(path))
			directions += pipe_direction_to(point, path[i + 1])
		solution["[point[1]],[point[2]]"] = pipe_part_for_directions(directions)
	pipe_board = list()
	for(var/y in 0 to 3)
		var/list/row = list()
		for(var/x in 0 to 3)
			var/list/part = solution["[x],[y]"]
			if(!part)
				part = list(pick("straight", "corner"), rand(0, 3))
			row += list(list("type" = part[1], "rotation" = rand(0, 3), "solution" = part[2]))
		pipe_board += list(row)

/datum/cyberpunk_corporate_minigame/proc/finish_game(success)
	if(completed)
		return
	completed = TRUE
	if(success && call(terminal, "complete_corporate_minigame")(owner, game_id))
		result = "Research task complete. Data uploaded."
	else if(success)
		result = "The terminal was unavailable before the data upload."
	else
		result = "Research task failed. No data was uploaded."

/datum/cyberpunk_corporate_minigame/ui_data(mob/user)
	var/list/data = list(
		"game" = game_id,
		"title" = get_game_name(),
		"progress" = progress,
		"errors" = errors,
		"completed" = completed,
		"result" = result,
	)
	switch(game_id)
		if("dr_mario")
			data["drBoard"] = get_dr_mario_board()
			data["currentPill"] = dr_current_pill
			data["nextPill"] = dr_next_pill
			data["goal"] = 20
		if("triple_town")
			data["tripleBoard"] = triple_board
			data["nextLevel"] = triple_next_level
			data["goal"] = 5
		if("pipe_mania")
			data["pipeBoard"] = get_pipe_board()
			data["flowStarted"] = pipe_flow_started
			data["goal"] = 1
		if("robozzle")
			advance_robo_animation()
			data["program"] = robo_program
			data["robot"] = list("x" = robo_x, "y" = robo_y, "direction" = robo_direction)
			data["stars"] = robo_stars
			data["tiles"] = robo_tiles
			data["goal"] = 6
		if("minesweeper")
			data["mineBoard"] = get_mine_board()
			data["bombs"] = length(mine_bombs)
			data["goal"] = 20
		if("papers_please")
			var/list/current = papers_index <= length(papers_cases) ? papers_cases[papers_index] : null
			if(current)
				data["paper"] = list("product" = current["product"], "price" = current["price"], "budget" = current["budget"], "demand" = current["demand"], "profile" = current["profile"])
			data["goal"] = length(papers_cases)
		if("research")
			update_research_target()
			data["activeCell"] = research_active_cell
			data["activeUntil"] = max(0, research_active_until - world.time)
			data["goal"] = "-"
	return data

/datum/cyberpunk_corporate_minigame/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(action == "restart_game")
		if(!can_view(user))
			return FALSE
		restart_game()
		return TRUE
	if(!can_use(user))
		return FALSE
	switch(action)
		if("dr_move")
			return dr_move(params["direction"])
		if("dr_rotate")
			return dr_rotate()
		if("dr_soft_drop")
			return dr_soft_drop()
		if("dr_hard_drop")
			return dr_hard_drop()
		if("triple_place")
			return triple_place(text2num(params["x"]), text2num(params["y"]))
		if("pipe_rotate")
			return pipe_rotate(text2num(params["x"]), text2num(params["y"]))
		if("pipe_flow")
			return pipe_start_flow()
		if("robo_add")
			return robo_add(params["command"], params["condition"])
		if("robo_clear")
			if(length(robo_animation_steps))
				return FALSE
			robo_program.Cut()
			return TRUE
		if("robo_run")
			return robo_run()
		if("mine_open")
			return mine_open_cell(text2num(params["x"]), text2num(params["y"]))
		if("mine_flag")
			return mine_flag_cell(text2num(params["x"]), text2num(params["y"]))
		if("paper_decide")
			return papers_decide(params["decision"])
		if("research_click")
			return research_click(text2num(params["cell"]))
	return FALSE

/datum/cyberpunk_corporate_minigame/proc/restart_game()
	completed = FALSE
	result = ""
	progress = 0
	errors = 0
	dr_board = null
	dr_current_pill = null
	dr_next_pill = null
	triple_board = null
	triple_next_level = 1
	triple_merges = 0
	pipe_board = null
	pipe_flow_started = FALSE
	robo_program = list()
	robo_x = 0
	robo_y = 4
	robo_direction = "north"
	robo_stars = null
	robo_tiles = null
	robo_animation_steps = list()
	robo_animation_index = 0
	robo_animation_next_at = 0
	robo_animation_success = FALSE
	mine_bombs = null
	mine_open = list()
	mine_flags = list()
	papers_cases = null
	papers_index = 1
	research_active_cell = -1
	research_active_until = 0
	research_next_at = 0
	initialize_game()

/datum/cyberpunk_corporate_minigame/proc/initialize_dr_mario()
	dr_board = list()
	for(var/y in 1 to 12)
		var/list/row = list()
		for(var/x in 1 to 8)
			row += list(null)
		dr_board += list(row)
	for(var/i in 1 to 12)
		var/x = rand(1, 8)
		var/y = rand(6, 12)
		while(dr_board[y][x])
			x = rand(1, 8)
			y = rand(6, 12)
		dr_board[y][x] = dr_cell(pick("red", "blue", "yellow"), "virus")
	dr_next_pill = make_dr_pill()
	spawn_dr_pill()

/datum/cyberpunk_corporate_minigame/proc/dr_cell(color, kind)
	return list("color" = color, "kind" = kind)

/datum/cyberpunk_corporate_minigame/proc/make_dr_pill()
	return list("colors" = list(pick("red", "blue", "yellow"), pick("red", "blue", "yellow")))

/datum/cyberpunk_corporate_minigame/proc/spawn_dr_pill()
	dr_current_pill = dr_next_pill || make_dr_pill()
	dr_current_pill["x"] = 4
	dr_current_pill["y"] = 1
	dr_current_pill["rotation"] = 0
	dr_next_pill = make_dr_pill()
	if(!dr_pill_can_fit(dr_current_pill))
		finish_game(FALSE)

/datum/cyberpunk_corporate_minigame/proc/get_dr_pill_cells(list/pill)
	if(!pill)
		return list()
	var/x = pill["x"]
	var/y = pill["y"]
	var/rotation = pill["rotation"] % 4
	var/list/colors = pill["colors"]
	switch(rotation)
		if(0)
			return list(list("x" = x, "y" = y, "color" = colors[1]), list("x" = x + 1, "y" = y, "color" = colors[2]))
		if(1)
			return list(list("x" = x, "y" = y, "color" = colors[1]), list("x" = x, "y" = y + 1, "color" = colors[2]))
		if(2)
			return list(list("x" = x, "y" = y, "color" = colors[1]), list("x" = x - 1, "y" = y, "color" = colors[2]))
	return list(list("x" = x, "y" = y, "color" = colors[1]), list("x" = x, "y" = y - 1, "color" = colors[2]))

/datum/cyberpunk_corporate_minigame/proc/dr_pill_can_fit(list/pill)
	for(var/list/cell as anything in get_dr_pill_cells(pill))
		var/x = cell["x"]
		var/y = cell["y"]
		if(x < 1 || x > 8 || y < 1 || y > 12)
			return FALSE
		if(dr_board[y][x])
			return FALSE
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/dr_move(direction)
	if(game_id != "dr_mario" || completed || !dr_current_pill || !(direction in list("left", "right")))
		return FALSE
	var/list/moved = dr_current_pill.Copy()
	moved["x"] += direction == "left" ? -1 : 1
	if(dr_pill_can_fit(moved))
		dr_current_pill = moved
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/dr_rotate()
	if(game_id != "dr_mario" || completed || !dr_current_pill)
		return FALSE
	var/list/rotated = dr_current_pill.Copy()
	rotated["rotation"] = (rotated["rotation"] + 1) % 4
	if(dr_pill_can_fit(rotated))
		dr_current_pill = rotated
		return TRUE
	for(var/offset in list(-1, 1))
		var/list/kicked = rotated.Copy()
		kicked["x"] += offset
		if(dr_pill_can_fit(kicked))
			dr_current_pill = kicked
			return TRUE
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/dr_soft_drop()
	if(game_id != "dr_mario" || completed || !dr_current_pill)
		return FALSE
	var/list/moved = dr_current_pill.Copy()
	moved["y"] += 1
	if(dr_pill_can_fit(moved))
		dr_current_pill = moved
	else
		lock_dr_pill()
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/dr_hard_drop()
	if(game_id != "dr_mario" || completed || !dr_current_pill)
		return FALSE
	var/list/moved = dr_current_pill.Copy()
	moved["y"] += 1
	while(dr_pill_can_fit(moved))
		dr_current_pill = moved
		moved = dr_current_pill.Copy()
		moved["y"] += 1
	lock_dr_pill()
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/lock_dr_pill()
	for(var/list/cell as anything in get_dr_pill_cells(dr_current_pill))
		dr_board[cell["y"]][cell["x"]] = dr_cell(cell["color"], "pill")
	dr_current_pill = null
	resolve_dr_mario_board()
	if(progress >= 20)
		finish_game(TRUE)
		return
	spawn_dr_pill()

/datum/cyberpunk_corporate_minigame/proc/resolve_dr_mario_board()
	var/resolved_any = TRUE
	while(resolved_any)
		resolved_any = FALSE
		var/list/remove = list()
		for(var/y in 1 to 12)
			var/run_color
			var/list/run = list()
			for(var/x in 1 to 9)
				var/list/cell = x <= 8 ? dr_board[y][x] : null
				if(cell && cell["color"] == run_color)
					run += "[x],[y]"
				else
					if(length(run) >= 4)
						for(var/key in run)
							remove[key] = TRUE
					run_color = cell ? cell["color"] : null
					run = cell ? list("[x],[y]") : list()
		for(var/x in 1 to 8)
			var/run_color
			var/list/run = list()
			for(var/y in 1 to 13)
				var/list/cell = y <= 12 ? dr_board[y][x] : null
				if(cell && cell["color"] == run_color)
					run += "[x],[y]"
				else
					if(length(run) >= 4)
						for(var/key in run)
							remove[key] = TRUE
					run_color = cell ? cell["color"] : null
					run = cell ? list("[x],[y]") : list()
		if(length(remove))
			resolved_any = TRUE
			progress += 1
			for(var/key in remove)
				var/list/point = splittext(key, ",")
				dr_board[text2num(point[2])][text2num(point[1])] = null
			apply_dr_gravity()

/datum/cyberpunk_corporate_minigame/proc/apply_dr_gravity()
	var/moved = TRUE
	while(moved)
		moved = FALSE
		for(var/y in 11 to 1 step -1)
			for(var/x in 1 to 8)
				var/list/cell = dr_board[y][x]
				if(!cell || cell["kind"] == "virus" || dr_board[y + 1][x])
					continue
				dr_board[y + 1][x] = cell
				dr_board[y][x] = null
				moved = TRUE

/datum/cyberpunk_corporate_minigame/proc/get_dr_mario_board()
	var/list/board = list()
	for(var/y in 1 to 12)
		var/list/row = list()
		for(var/x in 1 to 8)
			var/list/cell = dr_board[y][x]
			row += list(cell ? cell.Copy() : null)
		board += list(row)
	for(var/list/active as anything in get_dr_pill_cells(dr_current_pill))
		var/x = active["x"]
		var/y = active["y"]
		if(x >= 1 && x <= 8 && y >= 1 && y <= 12)
			board[y][x] = dr_cell(active["color"], "active")
	return board

/datum/cyberpunk_corporate_minigame/proc/triple_place(x, y)
	if(game_id != "triple_town" || x < 0 || x > 5 || y < 0 || y > 5 || triple_board[y + 1][x + 1])
		return FALSE
	var/level = triple_next_level
	triple_board[y + 1][x + 1] = level
	if(level > 0)
		var/list/group = triple_connected_group(x, y, level)
		if(length(group) >= 3)
			for(var/key in group)
				var/list/point = splittext(key, ",")
				triple_board[text2num(point[2]) + 1][text2num(point[1]) + 1] = 0
			triple_board[y + 1][x + 1] = level + 1
			triple_merges++
			progress = triple_merges
			if(triple_merges >= 5)
				finish_game(TRUE)
	if(!triple_has_empty_cells())
		finish_game(FALSE)
	triple_next_level = pick(1, 1, 1, 2, -1, -2)
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/triple_has_empty_cells()
	for(var/list/row as anything in triple_board)
		for(var/value in row)
			if(!value)
				return TRUE
	return FALSE

/datum/cyberpunk_corporate_minigame/proc/triple_connected_group(start_x, start_y, level)
	var/list/found = list()
	var/list/queue = list("[start_x],[start_y]")
	while(length(queue))
		var/key = queue[1]
		queue.Cut(1, 2)
		if(found[key])
			continue
		var/list/point = splittext(key, ",")
		var/x = text2num(point[1])
		var/y = text2num(point[2])
		if(x < 0 || x > 5 || y < 0 || y > 5 || triple_board[y + 1][x + 1] != level)
			continue
		found[key] = TRUE
		for(var/list/delta in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			queue += "[x + delta[1]],[y + delta[2]]"
	return found

/datum/cyberpunk_corporate_minigame/proc/pipe_rotate(x, y)
	if(game_id != "pipe_mania" || pipe_flow_started || x < 0 || x > 3 || y < 0 || y > 3)
		return FALSE
	var/list/part = pipe_board[y + 1][x + 1]
	part["rotation"] = (part["rotation"] + 1) % 4
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/pipe_start_flow()
	if(game_id != "pipe_mania" || pipe_flow_started)
		return FALSE
	pipe_flow_started = TRUE
	if(pipe_connected())
		progress = 1
		finish_game(TRUE)
	else
		finish_game(FALSE)
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/pipe_connections(type, rotation)
	if(type == "straight")
		return rotation % 2 ? list("east", "west") : list("north", "south")
	switch(rotation % 4)
		if(0) return list("north", "east")
		if(1) return list("east", "south")
		if(2) return list("south", "west")
	return list("west", "north")

/datum/cyberpunk_corporate_minigame/proc/pipe_connected()
	var/list/seen = list()
	var/list/queue = list("0,0")
	while(length(queue))
		var/key = queue[1]
		queue.Cut(1, 2)
		if(seen[key])
			continue
		seen[key] = TRUE
		var/list/point = splittext(key, ",")
		var/x = text2num(point[1])
		var/y = text2num(point[2])
		var/list/part = pipe_board[y + 1][x + 1]
		for(var/direction in pipe_connections(part["type"], part["rotation"]))
			var/list/delta = pipe_delta(direction)
			var/next_x = x + delta[1]
			var/next_y = y + delta[2]
			if(next_x < 0 || next_x > 3 || next_y < 0 || next_y > 3)
				continue
			var/list/next_part = pipe_board[next_y + 1][next_x + 1]
			if(pipe_opposite(direction) in pipe_connections(next_part["type"], next_part["rotation"]))
				queue += "[next_x],[next_y]"
	return !!seen["0,3"]

/datum/cyberpunk_corporate_minigame/proc/get_pipe_board()
	var/list/board = list()
	for(var/list/row as anything in pipe_board)
		var/list/data_row = list()
		for(var/list/part as anything in row)
			data_row += list(list("type" = part["type"], "rotation" = part["rotation"]))
		board += list(data_row)
	return board

/datum/cyberpunk_corporate_minigame/proc/pipe_delta(direction)
	switch(direction)
		if("north") return list(0, -1)
		if("south") return list(0, 1)
		if("east") return list(1, 0)
	return list(-1, 0)

/datum/cyberpunk_corporate_minigame/proc/pipe_opposite(direction)
	switch(direction)
		if("north") return "south"
		if("south") return "north"
		if("east") return "west"
	return "east"

/datum/cyberpunk_corporate_minigame/proc/pipe_direction_to(list/from_point, list/to_point)
	if(to_point[1] > from_point[1])
		return "east"
	if(to_point[1] < from_point[1])
		return "west"
	if(to_point[2] > from_point[2])
		return "south"
	return "north"

/datum/cyberpunk_corporate_minigame/proc/pipe_part_for_directions(list/directions)
	if(("north" in directions) && ("south" in directions))
		return list("straight", 0)
	if(("east" in directions) && ("west" in directions))
		return list("straight", 1)
	if(("north" in directions) && ("east" in directions))
		return list("corner", 0)
	if(("east" in directions) && ("south" in directions))
		return list("corner", 1)
	if(("south" in directions) && ("west" in directions))
		return list("corner", 2)
	if(("west" in directions) && ("north" in directions))
		return list("corner", 3)
	if(("east" in directions) || ("west" in directions))
		return list("straight", 1)
	return list("straight", 0)

/datum/cyberpunk_corporate_minigame/proc/initialize_robozzle()
	var/list/star_patterns = list(
		list("0,3", "0,2", "1,2", "2,2", "2,1", "2,0"),
		list("1,4", "1,3", "2,3", "3,3", "3,2", "4,2"),
		list("0,3", "1,3", "1,2", "2,2", "3,2", "3,1"),
		list("2,4", "2,3", "2,2", "1,2", "1,1", "0,1"),
	)
	robo_stars = list()
	for(var/key in pick(star_patterns))
		robo_stars[key] = TRUE
	var/list/colors = list("red", "blue", "green")
	robo_tiles = list()
	for(var/y in 0 to 4)
		var/list/row = list()
		for(var/x in 0 to 4)
			row += pick(colors)
		robo_tiles += list(row)
	robo_x = 0
	robo_y = 4
	robo_direction = "north"

/datum/cyberpunk_corporate_minigame/proc/robo_add(command, condition)
	if(game_id != "robozzle" || length(robo_animation_steps) || !(command in list("forward", "left", "right")) || !(condition in list("red", "green", "blue")) || length(robo_program) >= 10)
		return FALSE
	robo_program += "[condition]:[command]"
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/robo_run()
	if(game_id != "robozzle" || !length(robo_program) || length(robo_animation_steps))
		return FALSE
	var/sim_x = 0
	var/sim_y = 4
	var/sim_direction = "north"
	var/list/sim_stars = robo_stars.Copy()
	robo_animation_steps = list()
	robo_animation_index = 0
	robo_animation_success = FALSE
	for(var/entry in robo_program)
		var/list/parts = splittext(entry, ":")
		var/condition = parts[1]
		var/command = parts[2]
		var/tile_color = robo_tiles[sim_y + 1][sim_x + 1]
		if(condition != tile_color)
			continue
		if(command == "left")
			sim_direction = robo_turn_from(sim_direction, -1)
		else if(command == "right")
			sim_direction = robo_turn_from(sim_direction, 1)
		else
			var/list/delta = pipe_delta(sim_direction)
			sim_x += delta[1]
			sim_y += delta[2]
			if(sim_x < 0 || sim_x > 4 || sim_y < 0 || sim_y > 4)
				return TRUE
		var/key = "[sim_x],[sim_y]"
		var/collected_key = null
		if(sim_stars[key])
			sim_stars -= key
			collected_key = key
		robo_animation_steps += list(list("x" = sim_x, "y" = sim_y, "direction" = sim_direction, "collected" = collected_key))
	robo_animation_success = !length(sim_stars)
	robo_x = 0
	robo_y = 4
	robo_direction = "north"
	robo_animation_next_at = world.time
	if(!length(robo_animation_steps) && robo_animation_success)
		finish_game(TRUE)
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/robo_turn_from(direction, amount)
	var/list/directions = list("north", "east", "south", "west")
	var/index = directions.Find(direction)
	return directions[((index - 1 + amount + 4) % 4) + 1]

/datum/cyberpunk_corporate_minigame/proc/advance_robo_animation()
	if(game_id != "robozzle" || !length(robo_animation_steps) || world.time < robo_animation_next_at)
		return
	robo_animation_index++
	var/list/step = robo_animation_steps[robo_animation_index]
	robo_x = step["x"]
	robo_y = step["y"]
	robo_direction = step["direction"]
	var/collected_key = step["collected"]
	if(collected_key && robo_stars[collected_key])
		robo_stars -= collected_key
		progress++
	if(robo_animation_index >= length(robo_animation_steps))
		robo_animation_steps = list()
		robo_animation_index = 0
		if(robo_animation_success)
			finish_game(TRUE)
		return
	robo_animation_next_at = world.time + 3

/datum/cyberpunk_corporate_minigame/proc/initialize_minesweeper()
	mine_bombs = list()
	while(length(mine_bombs) < 5)
		mine_bombs["[rand(0, 4)],[rand(0, 4)]"] = TRUE

/datum/cyberpunk_corporate_minigame/proc/initialize_papers()
	var/list/pool = list(
		list("product" = "med-kit batch", "price" = 40, "budget" = 60, "demand" = 80, "profile" = "stable", "expected" = "approve"),
		list("product" = "neural stimulant", "price" = 75, "budget" = 60, "demand" = 85, "profile" = "stable", "expected" = "adjust"),
		list("product" = "unknown alloy", "price" = 35, "budget" = 70, "demand" = 20, "profile" = "unstable", "expected" = "reject"),
		list("product" = "organ transport", "price" = 55, "budget" = 55, "demand" = 75, "profile" = "stable", "expected" = "approve"),
		list("product" = "blank contract", "price" = 15, "budget" = 80, "demand" = 5, "profile" = "unstable", "expected" = "reject"),
		list("product" = "drone chassis", "price" = 90, "budget" = 70, "demand" = 90, "profile" = "stable", "expected" = "adjust"),
	)
	papers_cases = list()
	for(var/i in 1 to 4)
		var/list/picked = pick(pool)
		papers_cases += list(picked)
		pool -= picked

/datum/cyberpunk_corporate_minigame/proc/robo_turn(amount)
	var/list/directions = list("north", "east", "south", "west")
	var/index = directions.Find(robo_direction)
	return directions[((index - 1 + amount + 4) % 4) + 1]

/datum/cyberpunk_corporate_minigame/proc/mine_open_cell(x, y)
	if(game_id != "minesweeper" || x < 0 || x > 4 || y < 0 || y > 4)
		return FALSE
	var/key = "[x],[y]"
	if(mine_flags[key] || mine_open[key])
		return FALSE
	if(mine_bombs[key])
		mine_open[key] = TRUE
		finish_game(FALSE)
		return TRUE
	mine_reveal_safe(x, y)
	progress = length(mine_open)
	if(progress >= 20)
		finish_game(TRUE)
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/mine_flag_cell(x, y)
	if(game_id != "minesweeper" || x < 0 || x > 4 || y < 0 || y > 4)
		return FALSE
	var/key = "[x],[y]"
	if(mine_open[key])
		return FALSE
	if(mine_flags[key])
		mine_flags -= key
	else
		mine_flags[key] = TRUE
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/mine_reveal_safe(start_x, start_y)
	var/list/queue = list("[start_x],[start_y]")
	while(length(queue))
		var/key = queue[1]
		queue.Cut(1, 2)
		if(mine_open[key] || mine_bombs[key])
			continue
		mine_open[key] = TRUE
		var/list/point = splittext(key, ",")
		var/x = text2num(point[1])
		var/y = text2num(point[2])
		if(mine_count_neighbors(x, y))
			continue
		for(var/offset_x in -1 to 1)
			for(var/offset_y in -1 to 1)
				if(offset_x || offset_y)
					var/next_x = x + offset_x
					var/next_y = y + offset_y
					if(next_x >= 0 && next_x <= 4 && next_y >= 0 && next_y <= 4)
						queue += "[next_x],[next_y]"

/datum/cyberpunk_corporate_minigame/proc/mine_count_neighbors(x, y)
	var/count = 0
	for(var/offset_x in -1 to 1)
		for(var/offset_y in -1 to 1)
			if(offset_x || offset_y)
				count += !!mine_bombs["[x + offset_x],[y + offset_y]"]
	return count

/datum/cyberpunk_corporate_minigame/proc/get_mine_board()
	var/list/board = list()
	for(var/y in 0 to 4)
		var/list/row = list()
		for(var/x in 0 to 4)
			var/key = "[x],[y]"
			row += list(list("open" = !!mine_open[key], "flag" = !!mine_flags[key], "bomb" = !!mine_bombs[key] && (mine_open[key] || completed), "around" = mine_count_neighbors(x, y)))
		board += list(row)
	return board

/datum/cyberpunk_corporate_minigame/proc/papers_decide(decision)
	if(game_id != "papers_please" || !(decision in list("approve", "reject", "adjust")))
		return FALSE
	var/list/current = papers_index <= length(papers_cases) ? papers_cases[papers_index] : null
	if(!current || decision != current["expected"])
		finish_game(FALSE)
		return TRUE
	progress++
	papers_index++
	if(papers_index > length(papers_cases))
		finish_game(TRUE)
	return TRUE

/datum/cyberpunk_corporate_minigame/proc/update_research_target()
	if(game_id != "research")
		return
	if(research_active_cell > 0 && world.time <= research_active_until)
		return
	if(research_active_cell > 0)
		research_active_cell = -1
		research_next_at = world.time + rand(6, 14)
	if(world.time < research_next_at)
		return
	research_active_cell = rand(1, 9)
	research_active_until = world.time + rand(12, 20)

/datum/cyberpunk_corporate_minigame/proc/research_click(cell)
	if(game_id != "research" || cell < 1 || cell > 9)
		return FALSE
	update_research_target()
	if(cell != research_active_cell)
		return TRUE
	if(call(terminal, "record_corporate_research_correction")(owner))
		progress++
	research_active_cell = -1
	research_active_until = 0
	research_next_at = world.time + rand(4, 10)
	return TRUE

/obj/machinery/computer/corporate_data_terminal/benn
	name = "Benn data terminal"
	corporation_id = "benn"
	data_type = "bio"
	light_color = COLOR_GREEN
	circuit = /obj/item/circuitboard/computer/corporate_data_terminal/benn

/obj/machinery/computer/corporate_data_terminal/ryaznov
	name = "Ryaznov data terminal"
	corporation_id = "ryaznov"
	data_type = "engineering"
	light_color = COLOR_ORANGE
	circuit = /obj/item/circuitboard/computer/corporate_data_terminal/ryaznov

/obj/machinery/computer/corporate_data_terminal/starlight
	name = "Starlight data terminal"
	corporation_id = "starlight"
	data_type = "market"
	light_color = COLOR_CYAN
	circuit = /obj/item/circuitboard/computer/corporate_data_terminal/starlight

// Hand-held field analyzers feed the same corporate data store as data terminals.
/obj/item/cyberpunk_corporate_analyzer
	parent_type = /obj/item/analyzer
	name = "corporate field analyzer"
	desc = "A corporate field analyzer for turning approved scans into research data."
	var/corporation_id
	var/data_type = "general"
	var/scan_time = 15 SECONDS
	var/data_amount = 1

/obj/item/cyberpunk_corporate_analyzer/proc/can_scan_target(atom/target)
	return FALSE

/obj/item/cyberpunk_corporate_analyzer/proc/get_scan_time(mob/living/user)
	return round(scan_time * user.get_cyberpunk_analysis_time_multiplier())

/obj/item/cyberpunk_corporate_analyzer/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!can_scan_target(interacting_with))
		to_chat(user, span_warning("[src] cannot process [interacting_with]."))
		return ITEM_INTERACT_BLOCKING
	var/actual_scan_time = get_scan_time(user)
	user.visible_message(span_notice("[user] starts scanning [interacting_with] with [src]."), span_notice("You start scanning [interacting_with]."))
	if(!do_after(user, actual_scan_time, target = interacting_with))
		return ITEM_INTERACT_BLOCKING
	if(!can_scan_target(interacting_with))
		to_chat(user, span_warning("[interacting_with] is no longer a valid scan target."))
		return ITEM_INTERACT_BLOCKING
	if(!SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, data_type, data_amount, 0, "[src] scan of [interacting_with] by [user.real_name || user.name]"))
		to_chat(user, span_warning("[src] cannot upload its scan result."))
		return ITEM_INTERACT_BLOCKING
	user.visible_message(span_notice("[user] completes a scan with [src]."), span_notice("The scan uploads [data_amount] [data_type] data to the corporate network."))
	return ITEM_INTERACT_SUCCESS

/obj/item/cyberpunk_corporate_analyzer/benn
	name = "Benn biomedical scanner"
	desc = "A Benn biomedical scanner for analyzing living organisms."
	corporation_id = CYBERPUNK_CORP_BENN
	data_type = "bio"
	icon_state = "health_adv"
	inhand_icon_state = "analyzer"

/obj/item/cyberpunk_corporate_analyzer/benn/can_scan_target(atom/target)
	return isliving(target)

/obj/item/cyberpunk_corporate_analyzer/ryaznov
	name = "Ryaznov machine reader"
	desc = "A Ryaznov reader for robotics, mechs, rigs and cybernetic implants."
	corporation_id = CYBERPUNK_CORP_RYAZNOV
	data_type = "engineering"
	icon_state = "analyzer"
	inhand_icon_state = "analyzer"

/obj/item/cyberpunk_corporate_analyzer/ryaznov/can_scan_target(atom/target)
	return issilicon(target) || isdrone(target) || istype(target, /obj/vehicle/sealed/mecha) || istype(target, /obj/item/mod/control) || istype(target, /obj/item/organ/cyberimp)

/obj/item/cyberpunk_corporate_analyzer/starlight
	name = "Starlight spectral analyzer"
	desc = "A Starlight spectral analyzer for ores, alloys, machinery and transport."
	corporation_id = CYBERPUNK_CORP_STARLIGHT
	data_type = "market"
	icon_state = "analyzer"
	inhand_icon_state = "analyzer"

/obj/item/cyberpunk_corporate_analyzer/starlight/can_scan_target(atom/target)
	return istype(target, /obj/item/stack/ore) || istype(target, /obj/item/stack/sheet) || istype(target, /obj/machinery) || istype(target, /obj/vehicle)

/datum/outfit/job/doctor/cyberpunk_benn_ripper
	name = "Benn Ripper Specialist"
	jobtype = /datum/job/cyberpunk/corporate/benn_ripper
	backpack_contents = list(/obj/item/cyberpunk_corporate_analyzer/benn = 1)

/datum/outfit/job/engineer/cyberpunk_ryaznov_engineer
	name = "Ryaznov Engineering Specialist"
	jobtype = /datum/job/cyberpunk/corporate/ryaznov_engineer
	backpack_contents = list(
		/obj/item/construction/rcd/loaded = 1,
		/obj/item/cyberpunk_corporate_analyzer/ryaznov = 1,
	)

/datum/outfit/job/cargo_tech/cyberpunk_starlight_logist
	name = "Starlight Logistics Specialist"
	jobtype = /datum/job/cyberpunk/corporate/starlight_logist
	backpack_contents = list(
		/obj/item/boxcutter = 1,
		/obj/item/cyberpunk_corporate_analyzer/starlight = 1,
	)

/mob/living/verb/create_cyberpunk_corporate_terminal()
	set name = "(TEMP) Create Corporate Terminal"
	set desc = "Temporarily create a restricted corporate terminal for test maps and pre-release setup."
	set category = "IC"

	var/list/choices = list(
		"Benn" = /obj/machinery/computer/corporate_terminal/benn,
		"Ryaznov" = /obj/machinery/computer/corporate_terminal/ryaznov,
		"Starlight" = /obj/machinery/computer/corporate_terminal/starlight,
		"Government" = /obj/machinery/computer/corporate_terminal/government,
		"Council Emergency" = /obj/machinery/computer/security/cyberpunk_council_emergency,
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

/obj/machinery/computer/security/cyberpunk_council_emergency
	name = "council emergency monitor"
	desc = "A council emergency camera monitor. Insert council emergency chips to activate city emergency mode."
	icon_screen = "security"
	icon_keyboard = "security_key"
	light_color = COLOR_RED
	circuit = /obj/item/circuitboard/computer/cyberpunk_council_emergency
	network = list(CAMERANET_NETWORK_SS13)
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/authorized(mob/user)
	var/mob/living/living_user = user
	return istype(living_user) && (living_user.has_cyberpunk_crypto_access("city:council") || living_user.has_cyberpunk_crypto_access("government:all"))

/obj/machinery/computer/security/cyberpunk_council_emergency/ui_interact(mob/user, datum/tgui/ui)
	if(!authorized(user))
		to_chat(user, span_warning("Council emergency access denied."))
		return
	return ..()

/obj/machinery/computer/security/cyberpunk_council_emergency/ui_data()
	. = ..()
	var/list/council = SScyberpunk_corporations.get_cyberpunk_government_council_ui()
	var/list/last_dispatch = length(SScyberpunk_corporations.cyberpunk_government_dispatch_history) ? SScyberpunk_corporations.cyberpunk_government_dispatch_history[length(SScyberpunk_corporations.cyberpunk_government_dispatch_history)] : null
	.["councilEmergency"] = list(
		"active" = council["emergencyActive"],
		"inserted" = council["yesVotes"],
		"required" = council["requiredVotes"],
		"lastDispatch" = islist(last_dispatch) ? last_dispatch["target"] : null,
	)

/obj/machinery/computer/security/cyberpunk_council_emergency/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(action in list("council_insert_chip", "council_dispatch_camera", "council_dispatch_area", "council_dispatch_visible"))
		var/mob/living/user = ui.user
		if(!istype(user))
			return TRUE
		switch(action)
			if("council_insert_chip")
				var/obj/item/cyberpunk_council_emergency_chip/chip = user.get_active_held_item()
				if(!istype(chip))
					to_chat(user, span_warning("Hold a council emergency chip in your active hand."))
					return TRUE
				insert_council_emergency_chip(user, chip)
			if("council_dispatch_camera")
				dispatch_council_emergency_to_camera(user)
			if("council_dispatch_area")
				dispatch_council_emergency_to_area(user)
			if("council_dispatch_visible")
				dispatch_council_emergency_to_visible_target(user)
		SStgui.update_uis(src)
		return TRUE
	return ..()

/obj/machinery/computer/security/cyberpunk_council_emergency/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	var/obj/item/cyberpunk_council_emergency_chip/chip = attacking_item
	if(!istype(chip))
		return ..()
	var/mob/living/living_user = user
	if(!istype(living_user))
		return
	insert_council_emergency_chip(living_user, chip)

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/insert_council_emergency_chip(mob/living/living_user, obj/item/cyberpunk_council_emergency_chip/chip)
	if(!SScyberpunk_corporations.insert_cyberpunk_government_emergency_chip(living_user, chip, src))
		return
	if(!living_user.transferItemToLoc(chip, src))
		chip.forceMove(src)
	playsound(src, 'sound/machines/terminal/terminal_insert_disc.ogg', 25, FALSE)
	visible_message(span_notice("[living_user] inserts [chip] into [src]."))
	SStgui.update_uis(src)

/obj/machinery/computer/security/cyberpunk_council_emergency/examine(mob/user)
	. = ..()
	var/list/council = SScyberpunk_corporations.get_cyberpunk_government_council_ui()
	. += span_notice("Emergency chips: [council["yesVotes"]]/[council["requiredVotes"]].")
	if(council["emergencyActive"])
		. += span_warning("Emergency dispatch mode is active.")

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/can_dispatch(mob/user)
	if(!authorized(user))
		to_chat(user, span_warning("Council emergency access denied."))
		return FALSE
	if(!SScyberpunk_corporations.cyberpunk_government_emergency_active)
		to_chat(user, span_warning("Emergency mode is not active. Insert enough council chips first."))
		return FALSE
	return TRUE

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/dispatch_council_emergency_to_camera(mob/living/user)
	if(!can_dispatch(user))
		return
	if(!active_camera?.can_use())
		to_chat(user, span_warning("No active camera selected."))
		return
	SScyberpunk_corporations.dispatch_cyberpunk_government_police(active_camera, user, "camera: [active_camera.c_tag || active_camera.name]")

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/dispatch_council_emergency_to_area(mob/living/user)
	if(!can_dispatch(user))
		return
	var/list/area_choices = list()
	for(var/area/area_instance as anything in GLOB.areas)
		if(!istype(area_instance, /area/cyberpunk/city))
			continue
		var/turf/target_turf = cyberpunk_council_emergency_area_turf(area_instance)
		if(!target_turf)
			continue
		area_choices["[area_instance.name] ([area_instance.type])"] = target_turf
	var/choice = tgui_input_list(user, "Choose a city area.", name, area_choices)
	if(!choice)
		return
	var/turf/target_turf = area_choices[choice]
	SScyberpunk_corporations.dispatch_cyberpunk_government_police(target_turf, user, "[choice]")

/obj/machinery/computer/security/cyberpunk_council_emergency/proc/dispatch_council_emergency_to_visible_target(mob/living/user)
	if(!can_dispatch(user))
		return
	var/list/target_choices = list()
	for(var/atom/movable/target in view(12, user))
		if(target == user || target == src)
			continue
		target_choices["[target.name] ([get_area_name(target, TRUE)])"] = target
	var/choice = tgui_input_list(user, "Choose a visible target.", name, target_choices)
	if(!choice)
		return
	var/atom/target = target_choices[choice]
	SScyberpunk_corporations.dispatch_cyberpunk_government_police(target, user, "[choice]")

/obj/machinery/computer/security/cyberpunk_council_emergency/verb/dispatch_police_to_camera()
	set name = "Dispatch police to active camera"
	set category = "Object"
	set src in oview(1)

	dispatch_council_emergency_to_camera(usr)

/obj/machinery/computer/security/cyberpunk_council_emergency/verb/dispatch_police_to_area()
	set name = "Dispatch police to city area"
	set category = "Object"
	set src in oview(1)

	dispatch_council_emergency_to_area(usr)

/obj/machinery/computer/security/cyberpunk_council_emergency/verb/dispatch_police_to_visible_target()
	set name = "Dispatch police to visible target"
	set category = "Object"
	set src in oview(1)

	dispatch_council_emergency_to_visible_target(usr)

/proc/cyberpunk_council_emergency_area_turf(area/area_instance)
	if(!area_instance)
		return null
	var/list/turfs = area_instance.get_turfs_from_all_zlevels()
	for(var/turf/checked_turf as anything in shuffle(turfs))
		if(isclosedturf(checked_turf) || isspaceturf(checked_turf))
			continue
		return checked_turf
	return null

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

/obj/item/circuitboard/computer/cyberpunk_council_emergency
	name = "Council Emergency Monitor"
	greyscale_colors = CIRCUIT_COLOR_COMMAND
	build_path = /obj/machinery/computer/security/cyberpunk_council_emergency

/obj/item/circuitboard/computer/corporate_data_terminal
	name = "Corporate Data Terminal"
	greyscale_colors = CIRCUIT_COLOR_SCIENCE
	build_path = /obj/machinery/computer/corporate_data_terminal

/obj/item/circuitboard/computer/corporate_data_terminal/benn
	name = "Benn Data Terminal"
	build_path = /obj/machinery/computer/corporate_data_terminal/benn

/obj/item/circuitboard/computer/corporate_data_terminal/ryaznov
	name = "Ryaznov Data Terminal"
	build_path = /obj/machinery/computer/corporate_data_terminal/ryaznov

/obj/item/circuitboard/computer/corporate_data_terminal/starlight
	name = "Starlight Data Terminal"
	build_path = /obj/machinery/computer/corporate_data_terminal/starlight

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

/datum/design/cyberpunk_corporate_terminal_board/council_emergency
	name = "Council Emergency Monitor Board"
	id = "cyberpunk_council_emergency_monitor_board"
	build_path = /obj/item/circuitboard/computer/cyberpunk_council_emergency
	departmental_flags = DEPARTMENT_BITFLAG_COMMAND | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/cyberpunk_corporate_data_terminal_board
	name = "Corporate Data Terminal Board"
	id = "cyberpunk_corporate_data_terminal_board"
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/circuitboard/computer/corporate_data_terminal
	category = list(
		RND_CATEGORY_INITIAL,
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_ELECTRONICS,
	)
	departmental_flags = DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/cyberpunk_corporate_data_terminal_board/benn
	name = "Benn Data Terminal Board"
	id = "cyberpunk_benn_data_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_data_terminal/benn

/datum/design/cyberpunk_corporate_data_terminal_board/ryaznov
	name = "Ryaznov Data Terminal Board"
	id = "cyberpunk_ryaznov_data_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_data_terminal/ryaznov

/datum/design/cyberpunk_corporate_data_terminal_board/starlight
	name = "Starlight Data Terminal Board"
	id = "cyberpunk_starlight_data_terminal_board"
	build_path = /obj/item/circuitboard/computer/corporate_data_terminal/starlight
