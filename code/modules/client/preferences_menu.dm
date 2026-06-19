/client/verb/open_character_preferences()
	set category = "OOC"
	set name = "Open Character Preferences"
	set desc = "Open Character Preferences"

	if(!prefs)
		return
	prefs.current_window = PREFERENCE_TAB_CHARACTER_PREFERENCES
	prefs.update_static_data(usr)
	prefs.ui_interact(usr)

/client/verb/open_game_preferences()
	set category = "OOC"
	set name = "Open Game Preferences"
	set desc = "Open Game Preferences"

	if(!prefs)
		return
	prefs.current_window = PREFERENCE_TAB_GAME_PREFERENCES
	prefs.update_static_data(usr)
	prefs.ui_interact(usr)

// CYBERPUNK BUILD - rebuild and delete before release
/proc/cyberpunk_tgui_debug_interface_choices()
	var/static/list/interface_choices
	if(interface_choices)
		return interface_choices

	interface_choices = list()
	for(var/file_name in sort_list(flist("tgui/packages/tgui/interfaces/")))
		if(!endswith(file_name, ".tsx") && !endswith(file_name, ".jsx"))
			continue
		var/extension_start = findlasttext(file_name, ".")
		if(!extension_start)
			continue
		var/interface_name = copytext(file_name, 1, extension_start)
		interface_choices[interface_name] = interface_name

	return interface_choices

// CYBERPUNK BUILD - rebuild and delete before release
/datum/cyberpunk_tgui_debug_preview
	var/interface_name
	var/last_action = "none"

/datum/cyberpunk_tgui_debug_preview/New(new_interface_name)
	. = ..()
	interface_name = new_interface_name

/datum/cyberpunk_tgui_debug_preview/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_tgui_debug_preview/ui_interact(mob/user, datum/tgui/ui)
	if(!interface_name)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, interface_name, "TGUI Preview: [interface_name]")
		ui.open()

/datum/cyberpunk_tgui_debug_preview/ui_data(mob/user)
	return list(
		"user_name" = user?.real_name || user?.name || "Lobby user",
		"build_label" = "Generic TGUI preview",
		"last_action" = last_action,
		"progress_value" = 62,
		"danger_value" = 24,
		"options" = list("Primary", "Secondary", "Disabled", "Warning"),
		"metrics" = list(
			list("label" = "Preview metric", "value" = 42, "max" = 100, "color" = "average"),
			list("label" = "Danger sample", "value" = 24, "max" = 100, "color" = "bad"),
			list("label" = "Success sample", "value" = 81, "max" = 100, "color" = "good"),
		),
		"rows" = list(
			list("name" = "Preview row", "type" = "Dummy", "state" = "empty", "owner" = "none"),
			list("name" = "Second row", "type" = "Dummy", "state" = "idle", "owner" = "none"),
		),
		"tabs" = list("Status", "Actions", "Records", "Style"),
	)

/datum/cyberpunk_tgui_debug_preview/ui_static_data(mob/user)
	return ui_data(user)

/datum/cyberpunk_tgui_debug_preview/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	last_action = action
	return TRUE

/datum/cyberpunk_tgui_debug_preview/ui_close(mob/user)
	qdel(src)

// CYBERPUNK BUILD - rebuild and delete before release
/client/verb/open_cyberpunk_tgui_debug_interface()
	set category = "IC"
	set name = "Open TGUI Interface"
	set desc = "Open any top-level TGUI interface without its normal in-game object."

	if(!mob)
		return
	var/list/choices = cyberpunk_tgui_debug_interface_choices()
	var/interface_name = tgui_input_list(mob, "Choose a TGUI interface to open. Object-backed UIs may need their real data and can render partially.", "TGUI Interface", choices)
	if(!interface_name)
		return
	var/datum/cyberpunk_tgui_debug_preview/preview = new(interface_name)
	preview.ui_interact(mob)

// CYBERPUNK BUILD - rebuild and delete before release
/client/verb/open_cyberpunk_tgui_style_guide_from_lobby()
	set category = "IC"
	set name = "TGUI Style Guide"
	set desc = "Open the cyberpunk TGUI reference window from anywhere, including the lobby."

	if(!mob)
		return
	var/datum/cyberpunk_tgui_style_guide_ui/interface = new
	interface.ui_interact(mob)
