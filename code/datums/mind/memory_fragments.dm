/// Adds a mutable IC memory fragment and keeps the rolling memory log bounded.
/datum/mind/proc/add_cy_memory_fragment(
	text,
	speaker,
	where,
	channel,
	kind = "speech",
	importance = CY_MEMORY_IMPORTANCE_NORMAL,
	when = world.time,
)
	if(!text || !current || HAS_TRAIT(current, TRAIT_DONT_WRITE_MEMORY))
		return

	var/datum/cy_memory_fragment/fragment = new(text, speaker, where, channel, kind, importance, when)
	cy_memory_fragments += fragment

	while(length(cy_memory_fragments) > get_cy_temporary_memory_limit())
		var/datum/cy_memory_fragment/oldest = cy_memory_fragments[1]
		cy_memory_fragments.Cut(1, 2)
		qdel(oldest)

	return fragment

/// Records a line after the hearer actually received it.
/datum/mind/proc/add_cy_speech_memory(atom/movable/speaker, raw_message, radio_freq_name, list/message_mods)
	if(!speaker || !raw_message)
		return

	var/speaker_name = LAZYACCESS(message_mods, MODE_SPEAKER_NAME_OVERRIDE) || "[speaker]"
	var/channel = "local"
	if(radio_freq_name)
		channel = "[radio_freq_name] radio"
	else if(LAZYACCESS(message_mods, WHISPER_MODE))
		channel = "whisper"

	var/where = current ? get_area_name(current) : get_area_name(speaker)
	return add_cy_memory_fragment(raw_message, speaker_name, where, channel, "speech", CY_MEMORY_IMPORTANCE_LOW)

/// Records a non-chat event into the mutable memory stream.
/datum/mind/proc/add_cy_event_memory(text, importance = CY_MEMORY_IMPORTANCE_NORMAL, mob/living/source)
	var/where = source ? get_area_name(source) : current ? get_area_name(current) : ""
	var/speaker = source || current || name || "self"
	return add_cy_memory_fragment(text, speaker, where, "memory", "event", importance)

/// Records a delivered chat payload into temporary character memory.
/datum/mind/proc/add_cy_chat_payload_memory(list/message_data)
	if(!message_data || !current || HAS_TRAIT(current, TRAIT_DONT_WRITE_MEMORY))
		return
	if(message_data["skipMemory"] || cy_memory_rebuild_in_progress)
		return
	if(world.time <= cy_memory_suppress_until)
		return
	if(current.stat == DEAD)
		return

	var/message_type = message_data["type"]
	if(message_type in list(
		MESSAGE_TYPE_SYSTEM,
		MESSAGE_TYPE_DEADCHAT,
		MESSAGE_TYPE_OOC,
		MESSAGE_TYPE_ADMINPM,
		MESSAGE_TYPE_ADMINCHAT,
		MESSAGE_TYPE_MENTORCHAT,
		MESSAGE_TYPE_PRAYER,
		MESSAGE_TYPE_MODCHAT,
		MESSAGE_TYPE_EVENTCHAT,
		MESSAGE_TYPE_ADMINLOG,
		MESSAGE_TYPE_ATTACKLOG,
		MESSAGE_TYPE_DEBUG,
	))
		return

	var/message_text = message_data["html"] || message_data["text"]
	if(!message_text)
		return

	var/where = get_area_name(current)
	return add_cy_memory_fragment(message_text, "", where, message_type || "chat", "chat", CY_MEMORY_IMPORTANCE_LOW)

/// Death damages recent memories first: the closer a fragment is to death, the less reliable it becomes.
/datum/mind/proc/degrade_cy_memories_on_death(mob/living/dead_body, gibbed = FALSE)
	if(!dead_body || HAS_TRAIT(dead_body, TRAIT_DONT_WRITE_MEMORY))
		return

	var/death_time = world.time
	var/where = get_area_name(dead_body)
	cy_memory_suppress_until = max(cy_memory_suppress_until, death_time + 10 SECONDS)

	var/list/kept_fragments = list()
	for(var/datum/cy_memory_fragment/fragment as anything in cy_memory_fragments)
		var/age = max(0, death_time - fragment.created_at)
		var/severity = 0
		if(age <= CY_MEMORY_DEATH_ERASE_WINDOW)
			severity = 4
		else if(age <= CY_MEMORY_DEATH_SHATTER_WINDOW)
			severity = 3
		else if(age <= CY_MEMORY_DEATH_HAZE_WINDOW)
			severity = 2

		severity += gibbed ? 1 : 0
		severity -= max(0, fragment.importance - CY_MEMORY_IMPORTANCE_LOW)
		severity = clamp(severity, 0, 4)

		if(severity && fragment.apply_degradation(severity))
			qdel(fragment)
			continue

		kept_fragments += fragment

	var/datum/cy_memory_fragment/death_fragment = new("I died in [where].", dead_body, where, "body", "death", CY_MEMORY_IMPORTANCE_HIGH, death_time)
	death_fragment.apply_degradation(gibbed ? 3 : 2)
	kept_fragments += death_fragment

	cy_memory_fragments = kept_fragments
	replace_cy_memory_chat_from_memory()

/// When the mind is moved from a dead body later, dead time adds another pass of memory loss.
/datum/mind/proc/degrade_cy_memories_for_dead_time(dead_time)
	if(dead_time < CY_MEMORY_DEAD_TIME_DEGRADATION_STEP || !length(cy_memory_fragments))
		return FALSE

	var/severity = clamp(floor(dead_time / CY_MEMORY_DEAD_TIME_DEGRADATION_STEP), 1, 3)
	var/list/kept_fragments = list()
	for(var/datum/cy_memory_fragment/fragment as anything in cy_memory_fragments)
		var/extra_severity = severity
		if(last_death && fragment.created_at < (last_death - CY_MEMORY_DEATH_HAZE_WINDOW))
			extra_severity = max(0, severity - 1)
			if(extra_severity <= 0 && !prob(10 * severity))
				kept_fragments += fragment
				continue

		extra_severity -= max(0, fragment.importance - CY_MEMORY_IMPORTANCE_LOW)
		extra_severity = clamp(extra_severity, 0, 4)
		if(extra_severity && fragment.apply_degradation(extra_severity))
			qdel(fragment)
			continue

		kept_fragments += fragment

	cy_memory_fragments = kept_fragments
	return TRUE

/datum/mind/proc/copy_cy_memory_fragments_to(datum/mind/new_memorizer, additional_degradation = 0)
	if(!new_memorizer)
		return

	QDEL_LIST(new_memorizer.cy_memory_fragments)
	new_memorizer.cy_memory_fragments = list()
	for(var/datum/cy_memory_fragment/fragment as anything in cy_memory_fragments)
		new_memorizer.cy_memory_fragments += fragment.copy_fragment(additional_degradation)

/datum/mind/proc/replace_cy_memory_chat_from_memory(show_notice = TRUE)
	var/client/target = current?.client
	if(!target)
		return FALSE

	var/list/messages = list()
	if(show_notice)
		messages += list(list(
			"type" = MESSAGE_TYPE_WARNING,
			"text" = "Memory damaged. Recent IC chat was rebuilt from what the character can still recall.",
			"avoidHighlighting" = TRUE,
			"skipMemory" = TRUE,
			"cyMemoryTracked" = TRUE,
		))

	for(var/datum/cy_memory_fragment/fragment as anything in cy_memory_fragments)
		messages += list(fragment.chat_replay_message_data())

	cy_memory_rebuild_in_progress = TRUE
	target.tgui_panel.window.send_message("chat/memoryRewrite", list("messages" = messages), TRUE)
	addtimer(CALLBACK(src, PROC_REF(finish_cy_memory_chat_replace)), 1 SECONDS)
	return TRUE

/datum/mind/proc/sync_cy_memory_fragments_to_chat(show_notice = TRUE)
	return replace_cy_memory_chat_from_memory(show_notice)

/datum/mind/proc/finish_cy_memory_chat_replace()
	cy_memory_rebuild_in_progress = FALSE
	return TRUE

/datum/mind/proc/get_cy_temporary_memory_limit()
	var/mob/living/living_current = current
	var/intelligence = istype(living_current) ? living_current.get_cy_stat(/datum/cy_stat/intelligence) : CY_STAT_DEFAULT
	return max(30, CY_MEMORY_FRAGMENT_LIMIT + (intelligence - CY_STAT_DEFAULT) * 12)

/datum/mind/proc/get_cy_quick_memory_limit()
	var/mob/living/living_current = current
	var/intelligence = istype(living_current) ? living_current.get_cy_stat(/datum/cy_stat/intelligence) : CY_STAT_DEFAULT
	return max(1, round(intelligence / 2))

/datum/mind/proc/add_cy_quick_memory(datum/cy_memory_fragment/fragment)
	if(!fragment)
		return FALSE
	cy_quick_memories += fragment.copy_fragment()
	while(length(cy_quick_memories) > get_cy_quick_memory_limit())
		var/datum/cy_memory_fragment/oldest = cy_quick_memories[1]
		cy_quick_memories.Cut(1, 2)
		qdel(oldest)
	return TRUE

/datum/mind/proc/add_cy_deep_memory(key, value)
	if(!key)
		return FALSE
	LAZYSET(cy_deep_memories, key, value)
	return TRUE

/datum/mind/proc/get_cy_deep_memory(key)
	return LAZYACCESS(cy_deep_memories, key)
