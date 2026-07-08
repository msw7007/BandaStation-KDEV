// Cyberpunk mob overrides kept outside core to reduce upstream merge conflicts.

/mob/Cell()
	set category = "Admin"
	set hidden = TRUE

	if(!loc)
		return

	var/datum/gas_mixture/environment = lightweight_atmos_scan_gasmix(src)

	var/t = "[span_notice("Coordinates: [x],[y] ")]\n"
	t += "[span_danger("Temperature: [environment.temperature] ")]\n"
	for(var/id in environment.gases)
		var/gas = environment.gases[id]
		if(gas[MOLES])
			t += "[span_notice("[gas[GAS_META][META_GAS_NAME]]: [gas[MOLES]] ")]\n"

	to_chat(usr, t)

/mob/run_examinate(atom/examinify, force_examinate_more = FALSE)
	if(QDELETED(examinify))
		return

	if(isturf(examinify) && !(sight & SEE_TURFS) && !(examinify in view(client ? client.view : world.view, src)))
		return

	var/turf/examine_turf = get_turf(examinify)
	if(is_blind())
		if(!blind_examine_check(examinify))
			return
	else if(examine_turf && !(examine_turf.luminosity || examine_turf.dynamic_lumcount) && \
		get_dist(src, examine_turf) > 1 && \
		!has_nightvision())
		return

	face_atom(examinify)
	var/result_combined
	var/removes_double_click = client?.prefs.read_preference(/datum/preference/toggle/remove_double_click)
	if(client)
		LAZYINITLIST(client.recent_examines)
		var/ref_to_atom = REF(examinify)
		var/examine_time = client.recent_examines[ref_to_atom]
		if(force_examinate_more || (examine_time && (world.time - examine_time < EXAMINE_MORE_WINDOW) && !removes_double_click))
			var/list/result = examinify.examine_more(src)
			if(!length(result))
				result += span_notice("<i>You examine [examinify] closer, but find nothing of interest...</i>")
			result_combined = boxed_message(jointext(result, "<br>"))

		else
			client.recent_examines[ref_to_atom] = world.time
			addtimer(CALLBACK(src, PROC_REF(clear_from_recent_examines), ref_to_atom), RECENT_EXAMINE_MAX_WINDOW)
			handle_eye_contact(examinify)

	if(!result_combined)
		var/list/result = examinify.examine(src)
		var/atom_title = examinify.examine_title(src, thats = TRUE)
		examining(examinify, result)
		var/alist/overrides = alist()
		SEND_SIGNAL(src, COMSIG_MOB_EXAMINING, examinify, result, overrides)
		if(length(overrides))
			result = overrides[max(overrides)]
		remember_examined_identity(examinify, result, atom_title)
		if(removes_double_click)
			result += span_notice("<i>You can <a href=byond://?src=[REF(src)];run_examinate=[REF(examinify)]>examine</a> [examinify] closer...</i>")
		result_combined = (atom_title ? fieldset_block("[atom_title].", jointext(result, "<br>"), "boxed_message") : boxed_message(jointext(result, "<br>")))

	to_chat(src, span_infoplain(result_combined))
	SEND_SIGNAL(src, COMSIG_MOB_EXAMINATE, examinify)

/mob/mode()
	DEFAULT_QUEUE_OR_CALL_VERB(VERB_CALLBACK(src, PROC_REF(execute_mode)))

/mob/proc/remember_data(title, information)
	if(!title)
		return FALSE
	LAZYINITLIST(memory_holder)
	memory_holder[title] = information
	return TRUE

/mob/proc/remember_examined_identity(atom/examined_atom, list/examine_lines, atom_title)
	if(!ismob(examined_atom) || examined_atom == src || !length(examine_lines))
		return FALSE
	var/mob/examined_mob = examined_atom
	var/stable_name = examined_mob.name
	if("real_name" in examined_mob.vars)
		stable_name = examined_mob.vars["real_name"] || stable_name
	if(!stable_name)
		stable_name = "[examined_mob]"
	var/area/current_area = get_area(examined_mob)
	var/plain_snapshot = strip_html_full(jointext(examine_lines, "\n"), 2048)
	return remember_data("identity:[stable_name]", list(
		"cyberpunk_kind" = "identity_snapshot",
		"name" = stable_name,
		"title" = atom_title || examined_mob.name,
		"area" = current_area?.name || "unknown",
		"last_seen" = round_timestamp("hh:mm"),
		"last_seen_time" = world.time,
		"snapshot" = plain_snapshot,
	))

/mob/proc/read_memory_data(title)
	if(!title || !memory_holder)
		return null
	return memory_holder[title]

/mob/proc/forget_memory_data(title)
	if(!title || !memory_holder)
		return FALSE
	if(isnull(memory_holder[title]))
		return FALSE
	memory_holder -= title
	return TRUE

/mob/perform_hand_swap(held_index)
	if(!HAS_TRAIT(src, TRAIT_CAN_HOLD_ITEMS))
		return FALSE

	if(!held_index)
		held_index = (active_hand_index % held_items.len) + 1

	if(!isnum(held_index))
		CRASH("You passed [held_index] into swap_hand instead of a number. WTF man")

	var/previous_index = active_hand_index
	active_hand_index = held_index
	if(hud_used)
		hud_used.update_inventory_slot(ITEM_SLOT_HANDS, previous_index)
		hud_used.update_inventory_slot(ITEM_SLOT_HANDS, held_index)
	return TRUE

/mob/verb/open_language_menu_verb()
	set name = "Open Language Menu"
	set category = null

	get_language_holder().open_language_menu(usr)

/mob/verb/memory()
	set name = "Memories"
	set category = "IC"
	set desc = "View your character's memories."
	if(!mind)
		var/fail_message = "You have no mind!"
		if(isobserver(src))
			fail_message += " You need to participate in the round to get one."
		to_chat(src, span_warning(fail_message))
		return
	if(!mind.memory_panel)
		mind.memory_panel = new(usr, mind)
	mind.memory_panel.ui_interact(usr)

/datum/memory_panel/ui_data(mob/user)
	var/list/data = list()
	var/list/memories = list()
	var/list/notes = list()
	var/list/cryptokeys = list()
	var/list/identity_memories = list()

	for(var/memory_key in user?.mind.memories)
		var/datum/memory/memory = user.mind.memories[memory_key]
		memories += list(list("name" = memory.name, "quality" = memory.story_value))

	var/mob/living/living_holder = isliving(mind_reference?.current) ? mind_reference.current : null
	if(length(living_holder?.cyberpunk_memory_notes))
		for(var/note in living_holder.cyberpunk_memory_notes)
			notes += list(list("text" = note))
	if(length(living_holder?.cyberpunk_crypto_memory))
		for(var/datum/cyberpunk_crypto_key/key_datum as anything in living_holder.cyberpunk_crypto_memory)
			cryptokeys += list(list(
				"name" = key_datum.name,
				"owner" = key_datum.owner,
				"code" = key_datum.code,
			))
	if(length(living_holder?.memory_holder))
		for(var/memory_key in living_holder.memory_holder)
			var/list/identity_memory = living_holder.memory_holder[memory_key]
			if(!islist(identity_memory) || identity_memory["cyberpunk_kind"] != "identity_snapshot")
				continue
			identity_memories += list(identity_memory.Copy())

	data["memories"] = memories
	data["notes"] = notes
	data["cryptokeys"] = cryptokeys
	data["identityMemories"] = identity_memories
	return data

/datum/memory_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .
	var/mob/living/living_holder = isliving(mind_reference?.current) ? mind_reference.current : null
	if(!living_holder)
		return FALSE
	switch(action)
		if("add_note")
			var/text = trim(params["text"], MAX_MESSAGE_LEN)
			if(!text)
				return TRUE
			LAZYINITLIST(living_holder.cyberpunk_memory_notes)
			living_holder.cyberpunk_memory_notes += text
			return TRUE
		if("add_key")
			var/key_name = trim(params["name"], MAX_NAME_LEN)
			var/key_owner = trim(params["owner"], MAX_NAME_LEN)
			var/key_code = trim(params["code"], 20)
			if(length_char(key_code) != 20)
				to_chat(living_holder, span_warning("Cryptokey code must be 20 characters long."))
				return TRUE
			living_holder.remember_cyberpunk_crypto_key(new /datum/cyberpunk_crypto_key(key_name || "manual key", key_owner || "manual", key_code))
			return TRUE
	return FALSE

/mob/verb/view_skills()
	set category = "IC"
	set name = "View Skills"

	open_cyberpunk_skill_interface()
