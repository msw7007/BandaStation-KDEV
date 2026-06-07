/datum/keybinding/client/communication/whisper
	hotkey_keys = list("ShiftT")
	name = WHIS_CHANNEL
	full_name = "IC Whisper"
	keybind_signal = COMSIG_KB_CLIENT_WHISPER_DOWN

/datum/keybinding/client/communication/whisper/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	if(!user.prefs.read_preference(/datum/preference/toggle/tgui_input))
		winset(user, null, "command=[VERB_WHISPER]")
		return TRUE
	winset(user, null, "command=[user.tgui_say_create_open_command(WHIS_CHANNEL)]")
	winset(user, SKIN_TGUISAY_BROWSER, "focus=true")
	return TRUE

/datum/tgui_say/alter_entry(payload)
	/// No OOC leaks
	if(payload["channel"] == WHIS_CHANNEL)
		return pick(hurt_phrases)
	. = ..()

/datum/tgui_say/delegate_speech(entry, channel)
	switch(channel)
		if(WHIS_CHANNEL)
			client.mob.whisper_verb(entry)
			return TRUE
	. = ..()
