/// A mutable fragment of what a character remembers hearing or experiencing this shift.
/// Unlike /datum/memory story memories, these are intentionally degradable.
/datum/cy_memory_fragment
	var/raw_text = ""
	var/recalled_text = ""
	var/speaker_name = ""
	var/recalled_speaker_name = ""
	var/location_name = ""
	var/channel_name = ""
	var/memory_kind = "speech"
	var/created_at = 0
	var/importance = CY_MEMORY_IMPORTANCE_NORMAL
	var/degradation = 0

/datum/cy_memory_fragment/New(
	text,
	speaker,
	where,
	channel,
	kind = "speech",
	new_importance = CY_MEMORY_IMPORTANCE_NORMAL,
	when = world.time,
)
	raw_text = copytext_char(strip_html("[text]", MAX_MESSAGE_LEN), 1, MAX_MESSAGE_LEN)
	recalled_text = raw_text
	speaker_name = copytext_char(strip_html("[speaker]", MAX_NAME_LEN), 1, MAX_NAME_LEN)
	recalled_speaker_name = speaker_name
	location_name = copytext_char(strip_html("[where]", MAX_NAME_LEN), 1, MAX_NAME_LEN)
	channel_name = copytext_char(strip_html("[channel]", MAX_NAME_LEN), 1, MAX_NAME_LEN)
	memory_kind = kind
	importance = clamp(new_importance, CY_MEMORY_IMPORTANCE_LOW, CY_MEMORY_IMPORTANCE_HIGH)
	created_at = when

/datum/cy_memory_fragment/proc/apply_degradation(amount = 1)
	if(amount <= 0)
		return FALSE
	degradation = clamp(degradation + amount, 0, 4)
	switch(degradation)
		if(1)
			recalled_speaker_name = blur_name(recalled_speaker_name)
			recalled_text = blur_text(recalled_text, 30)
		if(2)
			recalled_speaker_name = pick("someone", "a familiar voice", "an unclear voice")
			recalled_text = blur_text(recalled_text, 55)
		if(3)
			recalled_speaker_name = pick("someone", "a distant voice", "a face without a name")
			recalled_text = blur_text(recalled_text, 80)
		if(4)
			recalled_speaker_name = "unknown"
			recalled_text = "The memory breaks apart before it can be recalled."
	return degradation >= 4

/datum/cy_memory_fragment/proc/copy_fragment(additional_degradation = 0)
	var/datum/cy_memory_fragment/copy = new(raw_text, speaker_name, location_name, channel_name, memory_kind, importance, created_at)
	copy.recalled_text = recalled_text
	copy.recalled_speaker_name = recalled_speaker_name
	copy.degradation = degradation
	copy.apply_degradation(additional_degradation)
	return copy

/datum/cy_memory_fragment/proc/blur_name(name_to_blur)
	if(!name_to_blur)
		return "someone"
	var/list/name_parts = splittext(name_to_blur, " ")
	if(length(name_parts) <= 1)
		return "someone like [copytext_char(name_to_blur, 1, 2)]."
	return "[name_parts[1]]..."

/datum/cy_memory_fragment/proc/blur_text(text_to_blur, percent)
	if(!text_to_blur)
		return "..."
	var/list/words = splittext(text_to_blur, " ")
	var/list/result = list()
	for(var/word in words)
		if(!length(word))
			continue
		if(prob(percent))
			result += "..."
		else
			result += word
	if(!length(result))
		return "..."
	return jointext(result, " ")

/datum/cy_memory_fragment/proc/fragment_ui_data()
	return list(
		"text" = recalled_text,
		"speaker" = recalled_speaker_name,
		"where" = location_name,
		"channel" = channel_name,
		"kind" = memory_kind,
		"time" = round_timestamp(wtime = created_at),
		"importance" = importance,
		"degradation" = degradation,
	)

/datum/cy_memory_fragment/proc/chat_replay_message_data()
	var/message_type = MESSAGE_TYPE_INFO
	var/html

	switch(memory_kind)
		if("speech")
			message_type = findtext(channel_name, "radio") ? MESSAGE_TYPE_RADIO : MESSAGE_TYPE_LOCALCHAT
			var/channel_suffix = ""
			if(channel_name && channel_name != "local")
				channel_suffix = " <span class='smallnotice'>[channel_name]</span>"
			html = "<span class='game say'><span class='name'>[recalled_speaker_name]</span>[channel_suffix]: <span class='message'>\"[recalled_text]\"</span></span>"
		if("death")
			message_type = MESSAGE_TYPE_WARNING
			html = span_warning("<i>[recalled_text]</i>")
		else
			html = span_notice("<i>[recalled_text]</i>")

	return list(
		"type" = message_type,
		"html" = html,
		"avoidHighlighting" = TRUE,
	)
