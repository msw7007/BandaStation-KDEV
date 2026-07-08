// Compatibility shims for upstream living_say.dm restored during modularization.

/mob/proc/get_tts_voice(list/filter, list/special_filter)
	return null

/mob/living
	var/blip_base = ""
	var/blip_number = 0

/mob/living/proc/do_tts_message(tts_message, datum/language/message_language, list/message_mods, list/tts_filter, list/listened)
	if(!SStts.tts_enabled || !voice || message_mods[MODE_CUSTOM_SAY_ERASE_INPUT] || HAS_TRAIT(src, TRAIT_SIGN_LANG) || HAS_TRAIT(src, TRAIT_UNKNOWN_VOICE))
		return
	if(CONFIG_GET(flag/tts_no_whisper) && message_mods[WHISPER_MODE])
		return

	var/list/filter = list()
	var/list/special_filter = list()
	if(length(voice_filter) > 0)
		filter += voice_filter
	if(length(tts_filter) > 0)
		filter += tts_filter.Join(",")

	var/voice_to_use = get_tts_voice(filter, special_filter)
	INVOKE_ASYNC(SStts, TYPE_PROC_REF(/datum/controller/subsystem/tts, queue_tts_message), src, html_decode(tts_message), message_language, voice_to_use, filter.Join(","), listened, message_range = MESSAGE_RANGE, pitch = pitch, special_filters = special_filter.Join("|"))
