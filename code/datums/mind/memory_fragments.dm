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

	while(length(cy_memory_fragments) > CY_MEMORY_FRAGMENT_LIMIT)
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

/// Death damages recent memories first: the closer a fragment is to death, the less reliable it becomes.
/datum/mind/proc/degrade_cy_memories_on_death(mob/living/dead_body, gibbed = FALSE)
	if(!dead_body || HAS_TRAIT(dead_body, TRAIT_DONT_WRITE_MEMORY))
		return

	var/death_time = world.time
	var/where = get_area_name(dead_body)
	add_cy_memory_fragment("I died in [where].", dead_body, where, "body", "death", CY_MEMORY_IMPORTANCE_HIGH, death_time)

	if(!length(cy_memory_fragments))
		return

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

	cy_memory_fragments = kept_fragments
	sync_cy_memory_fragments_to_chat()

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

/datum/mind/proc/sync_cy_memory_fragments_to_chat(show_notice = TRUE)
	var/client/target = current?.client
	if(!target?.tgui_panel?.window)
		return FALSE

	LAZYREMOVE(SSchat.client_to_payloads, target.ckey)
	LAZYREMOVE(SSchat.client_to_reliability_history, target.ckey)

	var/list/messages = list()
	if(show_notice)
		messages += list(list(
			"type" = MESSAGE_TYPE_WARNING,
			"html" = span_warning("<b>Memory damaged. Chat was rebuilt from what the character can still recall.</b>"),
			"avoidHighlighting" = TRUE,
		))

	for(var/datum/cy_memory_fragment/fragment as anything in cy_memory_fragments)
		messages += list(fragment.chat_replay_message_data())

	target.tgui_panel.window.send_message("chat/memoryRewrite", list(
		"messages" = messages,
	))
	return TRUE
