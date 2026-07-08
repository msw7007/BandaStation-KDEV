// Cyberpunk speech overrides kept outside core to reduce upstream merge conflicts.

/mob/living/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	if(sanitize)
		message = trim(copytext_char(sanitize(message, apply_ic_filter = TRUE), 1, MAX_MESSAGE_LEN)) // BANDASTATION EDIT - Sanitize emotes
	if(!message || message == "")
		return

	var/original_message = message
	message = get_message_mods(message, message_mods)
	saymode = SSradio.get_available_say_mode(src, message_mods[RADIO_KEY])
	if(!forced && (isnull(saymode) || saymode.allows_custom_say_emotes))
		message = check_for_custom_say_emote(message, message_mods)

	if(!message)
		return

	if(message_mods[RADIO_EXTENSION] == MODE_ADMIN)
		SSadmin_verbs.dynamic_invoke_verb(client, /datum/admin_verb/cmd_admin_say, message)
		return

	if(message_mods[RADIO_EXTENSION] == MODE_DEADMIN)
		SSadmin_verbs.dynamic_invoke_verb(client, /datum/admin_verb/dsay, message)
		return

	// dead is the only state you can never emote
	if(stat != DEAD && check_emote(original_message, forced))
		return

	// Checks if the saymode or channel extension can be used even if not totally conscious.
	var/say_radio_or_mode = saymode || message_mods[RADIO_EXTENSION]
	if(say_radio_or_mode)
		var/mob_stat_limit = GLOB.message_modes_stat_limits[say_radio_or_mode]
		if(stat > (isnull(mob_stat_limit) ? CONSCIOUS : mob_stat_limit))
			saymode = null
			message_mods -= RADIO_EXTENSION

	switch(stat)
		if(SOFT_CRIT)
			message_mods[WHISPER_MODE] = MODE_WHISPER
		if(UNCONSCIOUS)
			return
		if(HARD_CRIT)
			if(!message_mods[WHISPER_MODE])
				return
		if(DEAD)
			say_dead(original_message, message_mods[MANNEQUIN_CONTROLLED])
			return

	if(HAS_TRAIT(src, TRAIT_SOFTSPOKEN) && !HAS_TRAIT(src, TRAIT_SIGN_LANG)) // softspoken trait only applies to spoken languages
		message_mods[WHISPER_MODE] = MODE_WHISPER
	if(is_cyberpunk_mouth_grabbed(GRAB_AGGRESSIVE) && !forced)
		to_chat(src, span_warning("You cannot speak with your mouth held shut."))
		return
	if(is_cyberpunk_mouth_grabbed() && !forced)
		message_mods[WHISPER_MODE] = MODE_WHISPER
		adjust_stutter(2 SECONDS)

	if(client && SSlag_switch.measures[SLOWMODE_SAY] && !HAS_TRAIT(src, TRAIT_BYPASS_MEASURES) && !forced && src == usr)
		if(!COOLDOWN_FINISHED(client, say_slowmode))
			to_chat(src, span_warning("Message not sent due to slowmode. Please wait [SSlag_switch.slowmode_cooldown/10] seconds between messages.\n\"[message]\""))
			return
		COOLDOWN_START(client, say_slowmode, SSlag_switch.slowmode_cooldown)

	if(!try_speak(original_message, ignore_spam, forced, filterproof))
		return

	language ||= message_mods[LANGUAGE_EXTENSION] || get_selected_language()

	var/succumbed = FALSE

	// If it's not erasing the input portion, then something is being said and this isn't a pure custom say emote.
	if(!message_mods[MODE_CUSTOM_SAY_ERASE_INPUT])
		if(message_mods[WHISPER_MODE] == MODE_WHISPER)
			message_range = 1
			if(stat == HARD_CRIT)
				var/health_diff = round(-HEALTH_THRESHOLD_DEAD + health)
				// If we cut our message short, abruptly end it with a-..
				var/message_len = length_char(message)
				message = copytext_char(message, 1, health_diff) + "[message_len > health_diff ? "-.." : "..."]"
				message = Ellipsis(message, 10, 1)
				last_words = message
				message_mods[WHISPER_MODE] = MODE_WHISPER_CRIT
				succumbed = TRUE

	log_sayverb_talk(message, message_mods, forced_by = forced)

#ifdef UNIT_TESTS
	// Saves a ref() to our arglist specifically.
	// We do this because we need to check that COMSIG_MOB_SAY is getting EXACTLY this list.
	last_say_args_ref = REF(args)
#endif

	// Make sure the arglist is passed exactly - don't pass a copy of it. Say signal handlers will modify some of the parameters.
	var/sigreturn = SEND_SIGNAL(src, COMSIG_MOB_SAY, args)
	if(sigreturn & COMPONENT_UPPERCASE_SPEECH)
		message = uppertext(message)

	var/list/message_data = treat_message(message) // unfortunately we still need this
	message = message_data["message"]
	var/tts_message = message_data["tts_message"]
	var/list/tts_filter = message_data["tts_filter"]

	spans |= speech_span

	var/datum/language/spoken_lang = GLOB.language_datum_instances[language]
	if(LAZYLEN(spoken_lang?.spans))
		spans |= spoken_lang.spans

	if(message_mods[MODE_SING])
		var/randomnote = pick("\u2669", "\u266A", "\u266B")
		message = "[randomnote] [message] [randomnote]"
		spans |= SPAN_SINGING

	if(message_mods[WHISPER_MODE]) // whisper away
		spans |= SPAN_ITALICS

	if(!message)
		if(succumbed)
			succumb()
		return

	//Get which verb is prefixed to the message before radio but after most modifications
	message_mods[SAY_MOD_VERB] = say_mod(message, message_mods)

	//This is before anything that sends say a radio message, and after all important message type modifications, so you can scumb in alien chat or something
	if(saymode && (saymode.handle_message(src, message, spans, language, message_mods) & SAYMODE_MESSAGE_HANDLED))
		return

	var/radio_return = radio(message, message_mods, spans, language)//roughly 27% of living/say()'s total cost
	if(radio_return & NOPASS)
		return TRUE

	if(radio_return & ITALICS)
		spans |= SPAN_ITALICS
	if(radio_return & REDUCE_RANGE)
		message_range = 1
		if(!message_mods[WHISPER_MODE])
			message_mods[WHISPER_MODE] = MODE_WHISPER
			message_mods[SAY_MOD_VERB] = say_mod(message, message_mods)

	//No screams in space, unless you're next to someone.
	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = lightweight_atmos_scan_gasmix(T)
	var/pressure = (environment)? environment.return_pressure() : 0
	if(pressure < SOUND_MINIMUM_PRESSURE && !HAS_TRAIT(src, TRAIT_SIGN_LANG))
		message_range = 1

	if(pressure < ONE_ATMOSPHERE * (HAS_TRAIT(src, TRAIT_SPEECH_BOOSTER) ? 0.1 : 0.4)) //Thin air, let's italicise the message unless we have a loud low pressure speech trait and not in vacuum
		spans |= SPAN_ITALICS

	send_speech(message, message_range, src, bubble_type, spans, language, message_mods, forced = forced, tts_message = tts_message, tts_filter = tts_filter)//roughly 58% of living/say()'s total cost
	if(succumbed)
		succumb(TRUE)
		to_chat(src, compose_message(src, language, message, null, null, null, spans, message_mods))

	return TRUE


/mob/living/Hear(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, list/spans, list/message_mods = list(), message_range=0)
	if((SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_HEAR, args) & COMSIG_MOVABLE_CANCEL_HEARING) || !GET_CLIENT(src))
		return FALSE

	var/deaf_message
	var/deaf_type

	if(speaker != src)
		deaf_type = !radio_freq ? MSG_VISUAL : null
	else
		deaf_type = MSG_AUDIBLE

	var/atom/movable/virtualspeaker/holopad_speaker = speaker
	var/avoid_highlight = src == (istype(holopad_speaker) ? holopad_speaker.source : speaker)

	var/is_custom_emote = message_mods[MODE_CUSTOM_SAY_ERASE_INPUT]
	var/understood = TRUE
	if(!is_custom_emote) // we do not translate emotes
		var/untranslated_raw_message = raw_message
		raw_message = translate_language(speaker, message_language, raw_message, spans, message_mods) // translate
		if(raw_message != untranslated_raw_message)
			understood = FALSE

	var/speaker_is_signing = HAS_TRAIT(speaker, TRAIT_SIGN_LANG)
	var/use_runechat = client?.prefs.read_preference(/datum/preference/toggle/enable_runechat)
	if (stat == UNCONSCIOUS || stat == HARD_CRIT)
		use_runechat = FALSE
	else if (!ismob(speaker) && !client?.prefs.read_preference(/datum/preference/toggle/enable_runechat_non_mobs))
		use_runechat = FALSE

	var/message = ""
	var/speech_hearing_state = get_speech_hearing_state(speaker, message_range, !!message_mods[WHISPER_MODE], radio_freq)
	if(!speech_hearing_state)
		return FALSE
	if(speech_hearing_state == SPEECH_HEARING_MUFFLED)
		raw_message = stars(raw_message)
	// if someone is whispering we make an extra type of message that is obfuscated for people out of range
	// Less than or equal to 0 means normal hearing. More than 0 and less than or equal to eavesdrop_range means
	// partial hearing. More than eavesdrop_range means no hearing. Exception for GOOD_HEARING trait
	var/dist = get_dist(speaker, src) - message_range
	if(!speech_hearing_state && dist > 0 && dist <= eavesdrop_range && !HAS_TRAIT(src, TRAIT_GOOD_HEARING))
		raw_message = stars(raw_message)
	var/speaker_name = span_name("[message_mods[MODE_SPEAKER_NAME_OVERRIDE] || speaker]")
	if(!speech_hearing_state && message_range != INFINITY && dist > eavesdrop_range && !HAS_TRAIT(src, TRAIT_GOOD_HEARING))
		// Too far away and don't have good hearing, you can't hear anything
		if(is_blind() || HAS_TRAIT(speaker, TRAIT_INVISIBLE_MAN)) // Can't see them speak either
			return FALSE
		if(!isturf(speaker.loc)) // If they're inside of something, probably can't see them speak
			return FALSE

		// But we can still see them speak
		if(speaker_is_signing)
			deaf_message = "[speaker_name] [speaker.get_default_say_verb()] что-то, но движения едва заметны, чтобы разобрать их."
		else if(!HAS_TRAIT(src, TRAIT_DEAF)) // If we can't hear we want to continue to the default deaf message
			if(isliving(speaker))
				var/mob/living/living_speaker = speaker
				var/mouth_hidden = living_speaker.is_mouth_covered() || HAS_TRAIT(living_speaker, TRAIT_FACE_COVERED)
				if(mouth_hidden && !HAS_TRAIT(src, TRAIT_SEE_MASK_WHISPER)) // Can't see them speak if their mouth is covered or hidden, unless we're an empath
					return FALSE

			deaf_message = "[speaker_name] [ru_say_verb(speaker.verb_whisper)] что-то, но вы слишком далеко, чтобы услышать [speaker.ru_p_them()]."

		if(deaf_message)
			deaf_type = MSG_VISUAL
			message = deaf_message
			show_message(message, MSG_VISUAL, deaf_message, deaf_type, avoid_highlight)
			return FALSE


	// we need to send this signal before compose_message() is used since other signals need to modify
	// the raw_message first. After the raw_message is passed through the various signals, it's ready to be formatted
	// by compose_message() to be displayed in chat boxes for to_chat or runechat
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)

	if(speaker_is_signing) //Checks if speaker is using sign language
		deaf_message = compose_message(speaker, message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, spans, message_mods, TRUE)

		if(speaker != src)
			if(!radio_freq) //I'm about 90% sure there's a way to make this less cluttered
				deaf_type = MSG_VISUAL
		else
			deaf_type = MSG_AUDIBLE

		// Create map text prior to modifying message for goonchat, sign lang edition
		if (use_runechat && !is_blind())
			if (is_custom_emote)
				create_chat_message(speaker, null, message_mods[MODE_CUSTOM_SAY_EMOTE], spans, EMOTE_MESSAGE)
			else
				create_chat_message(speaker, message_language, raw_message, spans)

		if(is_blind())
			return FALSE

		message = deaf_message

		var/show_message_success = show_message(message, MSG_VISUAL, deaf_message, deaf_type, avoid_highlight)
		return understood && show_message_success

	if(speaker != src)
		if(!radio_freq) //These checks have to be separate, else people talking on the radio will make "You can't hear yourself!" appear when hearing people over the radio while deaf.
			deaf_message = "[speaker_name] [speaker.get_default_say_verb()] что-то, но вы не слышите [speaker.ru_p_them()]."
			deaf_type = MSG_VISUAL
	else
		deaf_message = span_notice("Вы не слышите себя!")
		deaf_type = MSG_AUDIBLE // Since you should be able to hear yourself without looking

	// Create map text prior to modifying message for goonchat
	if (use_runechat && !HAS_TRAIT(src, TRAIT_DEAF))
		if (is_custom_emote)
			create_chat_message(speaker, null, message_mods[MODE_CUSTOM_SAY_EMOTE], spans, EMOTE_MESSAGE)
		else
			create_chat_message(speaker, message_language, raw_message, spans)

	// Recompose message for AI hrefs, language incomprehension.
	var/can_identify_speaker = can_identify_speech_source(speaker, message_range, radio_freq)
	message = compose_message(speaker, message_language, raw_message, radio_freq, radio_freq_name, radio_freq_color, spans, message_mods, can_identify_speaker)
	if(!can_identify_speaker)
		message = "[get_speech_direction_marker(speaker)] [message]"
	var/show_message_success = show_message(message, MSG_AUDIBLE, deaf_message, deaf_type, avoid_highlight)

	// BANDASTATION ADDITION START - TTS
	if(show_message_success && radio_freq != FREQ_ENTERTAINMENT)
		var/message_to_tts = LAZYACCESS(message_mods, MODE_TTS_MESSAGE_OVERRIDE) || raw_message
		speaker.cast_tts(
			src,
			message_to_tts,
			is_local = (message_range != INFINITY),
			is_radio = !!radio_freq,
			effects = LAZYACCESS(message_mods, MODE_TTS_FILTERS),
			tts_seed_override = LAZYACCESS(message_mods, MODE_TTS_SEED_OVERRIDE),
			channel_override = radio_freq ? CHANNEL_TTS_RADIO : null
		)
	// BANDASTATION ADDITION END - TTS

	return understood && show_message_success

/mob/living/proc/get_speech_hearing_state(atom/movable/speaker, message_range, is_whisper, radio_freq)
	if(radio_freq || speaker == src || message_range == INFINITY)
		return SPEECH_HEARING_CLEAR
	if(stealth_blocks_speech_wall_hearing(speaker))
		return SPEECH_HEARING_NONE
	var/hearing_distance = get_planar_hearing_distance(speaker)
	if(speaker.z != z)
		if(hearing_distance > HEARING_OTHER_Z_RANGE)
			return SPEECH_HEARING_NONE
		return (HAS_TRAIT(src, TRAIT_GOOD_HEARING) || listening_intently) ? SPEECH_HEARING_CLEAR : SPEECH_HEARING_MUFFLED
	var/can_see_source = can_see_speech_source(speaker, message_range)
	if(can_see_source && !is_whisper && hearing_distance <= message_range)
		return SPEECH_HEARING_CLEAR
	if(is_whisper)
		if(listening_intently)
			if(can_see_source && hearing_distance <= get_open_whisper_listen_range())
				return SPEECH_HEARING_CLEAR
			if(!can_see_source && hearing_distance <= get_intent_listen_range(TRUE))
				return SPEECH_HEARING_CLEAR
		var/muffled_range = HEARING_WALL_WHISPER_RANGE + (HAS_TRAIT(src, TRAIT_GOOD_HEARING) ? LISTEN_HEARING_QUIRK_BONUS : 0)
		if(hearing_distance <= muffled_range)
			return SPEECH_HEARING_MUFFLED
		return SPEECH_HEARING_NONE
	if(listening_intently && hearing_distance <= get_intent_listen_range(FALSE))
		return SPEECH_HEARING_CLEAR
	if(hearing_distance <= HEARING_WALL_SPEECH_RANGE)
		return SPEECH_HEARING_MUFFLED
	return SPEECH_HEARING_NONE

/mob/living/proc/get_intent_listen_range(is_whisper = FALSE)
	var/range = is_whisper ? LISTEN_WHISPER_WALL_RANGE : LISTEN_NORMAL_WALL_RANGE
	if(HAS_TRAIT(src, TRAIT_GOOD_HEARING))
		range += is_whisper ? LISTEN_HEARING_QUIRK_BONUS : LISTEN_HEARING_QUIRK_INTENT_BONUS
	return range

/mob/living/proc/get_open_whisper_listen_range()
	return LISTEN_WHISPER_OPEN_RANGE + (HAS_TRAIT(src, TRAIT_GOOD_HEARING) ? LISTEN_HEARING_QUIRK_BONUS : 0)

/mob/living/proc/can_hear_speech_through_wall(atom/movable/speaker, message_range, is_whisper = FALSE)
	return get_speech_hearing_state(speaker, message_range, is_whisper, null) != SPEECH_HEARING_NONE

/mob/living/proc/can_see_speech_source(atom/movable/speaker, message_range)
	var/view_range = client ? client.view : world.view
	return (speaker in view(view_range, src)) && in_code_fov(speaker, ignore_self = TRUE)

/mob/living/proc/can_identify_speech_source(atom/movable/speaker, message_range, radio_freq)
	if(radio_freq || speaker == src)
		return TRUE
	return can_see_speech_source(speaker, message_range)

/mob/living/proc/get_planar_hearing_distance(atom/movable/speaker)
	var/turf/my_turf = get_turf(src)
	var/turf/speaker_turf = get_turf(speaker)
	if(!my_turf || !speaker_turf)
		return INFINITY
	return max(abs(speaker_turf.x - my_turf.x), abs(speaker_turf.y - my_turf.y))

/mob/living/proc/get_speech_direction_marker(atom/movable/speaker)
	var/turf/my_turf = get_turf(src)
	var/turf/speaker_turf = get_turf(speaker)
	if(!my_turf || !speaker_turf)
		return ""
	var/dir_to_source = get_dir(my_turf, speaker_turf)
	var/marker = get_planar_direction_marker(dir_to_source)
	if(speaker_turf.z > my_turf.z)
		marker = "[marker]↑"
	else if(speaker_turf.z < my_turf.z)
		marker = "[marker]↓"
	return marker

/mob/living/proc/get_planar_direction_marker(direction)
	switch(direction)
		if(NORTH)
			return "↑"
		if(NORTHEAST)
			return "↗"
		if(EAST)
			return "→"
		if(SOUTHEAST)
			return "↘"
		if(SOUTH)
			return "↓"
		if(SOUTHWEST)
			return "↙"
		if(WEST)
			return "←"
		if(NORTHWEST)
			return "↖"
	return "?"

/mob/living/proc/stealth_blocks_speech_wall_hearing(atom/movable/speaker)
	var/mob/living/living_speaker = speaker
	return istype(living_speaker) && living_speaker.stealth_muffles_sound()

/mob/living/send_speech(message_raw, message_range = 6, obj/source = src, bubble_type = bubble_icon, list/spans, datum/language/message_language = null, list/message_mods = list(), forced = null, tts_message, list/tts_filter)
	var/atom/movable/speech_source = get_cyberspace_speech_source()
	if(source == src && speech_source)
		source = speech_source
	var/whisper_range = 0
	var/is_speaker_whispering = FALSE
	if(message_mods[WHISPER_MODE]) //If we're whispering
		// Needed for good hearing trait. The actual filtering for whispers happens at the /mob/living/Hear proc
		whisper_range = MESSAGE_RANGE - WHISPER_RANGE
		is_speaker_whispering = TRUE
	if(stealth_muffles_sound())
		message_range = min(message_range, 1)
		whisper_range = 0

	var/hearing_candidate_range = max(message_range + whisper_range, HEARING_WALL_SPEECH_RANGE + LISTEN_HEARING_QUIRK_INTENT_BONUS)
	var/list/in_view = get_hearers_in_view(hearing_candidate_range, source)
	var/list/listening = get_hearers_in_range(hearing_candidate_range, source)

	// Pre-process listeners to account for line-of-sight
	for(var/atom/movable/listening_movable as anything in listening)
		if((listening_movable in in_view) || HAS_TRAIT(listening_movable, TRAIT_XRAY_HEARING))
			continue
		var/mob/living/listening_living = listening_movable
		if(istype(listening_living) && listening_living.can_hear_speech_through_wall(source, message_range, is_speaker_whispering))
			continue
		else
			listening.Remove(listening_movable)

	for(var/mob/living/other_z_listener as anything in GLOB.alive_mob_list)
		if(other_z_listener.z == source.z || !other_z_listener.client)
			continue
		if(other_z_listener.get_speech_hearing_state(source, message_range, is_speaker_whispering, null) != SPEECH_HEARING_NONE)
			listening |= other_z_listener

	SEND_SIGNAL(src, COMSIG_LIVING_SEND_SPEECH, listening)

	if(imaginary_group)
		listening |= imaginary_group

	if(client) //client is so that ghosts don't have to listen to mice
		for(var/mob/player_mob as anything in GLOB.player_list)
			if(QDELETED(player_mob)) //Some times nulls and deleteds stay in this list. This is a workaround to prevent ic chat breaking for everyone when they do.
				continue //Remove if underlying cause (likely byond issue) is fixed. See TG PR #49004.
			if(player_mob.stat != DEAD) //not dead, not important
				continue
			if(player_mob.z != source.z || get_dist(player_mob, source) > 7) //they're out of range of normal hearing
				if(is_speaker_whispering)
					if(!(get_chat_toggles(player_mob.client) & CHAT_GHOSTWHISPER)) //they're whispering and we have hearing whispers at any range off
						continue
				else if(!(get_chat_toggles(player_mob.client) & CHAT_GHOSTEARS)) //they're talking normally and we have hearing at any range off
					continue
			listening |= player_mob

	// this signal ignores whispers or language translations (only used by beetlejuice component)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_LIVING_SAY_SPECIAL, src, message_raw)

	var/list/listened = list()
	for(var/atom/movable/listening_movable as anything in listening)
		if(!listening_movable)
			stack_trace("somehow theres a null returned from get_hearers_in_view() in send_speech!")
			continue

		if(listening_movable.Hear(speech_source, message_language, message_raw, null, null, null, spans, message_mods, message_range))
			listened += listening_movable

	//speech bubble
	var/list/speech_bubble_recipients = list()
	var/found_client = FALSE
	var/talk_icon_state = say_test(message_raw)
	for(var/mob/M in listening)
		if(M.client)
			if(!M.client.prefs.read_preference(/datum/preference/toggle/enable_runechat) || (SSlag_switch.measures[DISABLE_RUNECHAT] && !HAS_TRAIT(src, TRAIT_BYPASS_MEASURES)))
				speech_bubble_recipients.Add(M.client)
			found_client = TRUE
	if(SStts.tts_enabled && voice && found_client && !message_mods[MODE_CUSTOM_SAY_ERASE_INPUT] && !HAS_TRAIT(src, TRAIT_SIGN_LANG) && !HAS_TRAIT(src, TRAIT_UNKNOWN_VOICE))
		var/tts_message_to_use = tts_message
		if(!tts_message_to_use)
			tts_message_to_use = message_raw

		var/list/filter = list()
		var/list/special_filter = list()
		if(length(voice_filter) > 0)
			filter += voice_filter

		if(length(tts_filter) > 0)
			filter += tts_filter.Join(",")

		var/voice_to_use = get_tts_voice(filter, special_filter)
		if (!CONFIG_GET(flag/tts_no_whisper) || (CONFIG_GET(flag/tts_no_whisper) && !message_mods[WHISPER_MODE]))
			INVOKE_ASYNC(SStts, TYPE_PROC_REF(/datum/controller/subsystem/tts, queue_tts_message), src, html_decode(tts_message_to_use), message_language, voice_to_use, filter.Join(","), listened, message_range = message_range, pitch = pitch, special_filters = special_filter.Join("|"))

	var/image/say_popup = image('icons/mob/effects/talk.dmi', speech_source, "[bubble_type][talk_icon_state]", FLY_LAYER)
	SET_PLANE_EXPLICIT(say_popup, ABOVE_GAME_PLANE, speech_source)
	say_popup.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay_global), say_popup, speech_bubble_recipients, 3 SECONDS)
	LAZYADD(update_on_z, say_popup)
	addtimer(CALLBACK(src, PROC_REF(clear_saypopup), say_popup), 3.5 SECONDS)

/mob/living/get_tts_voice(list/filter, list/special_filter)
	. = voice
	var/obj/item/clothing/mask/mask = get_item_by_slot(ITEM_SLOT_MASK)
	if(!istype(mask) || mask.up)
		return
	if(mask.voice_override)
		. = mask.voice_override
	if(mask.voice_filter)
		filter += mask.voice_filter
	if(mask.use_radio_beeps_tts)
		special_filter |= TTS_FILTER_RADIO

/mob/living/silicon/get_tts_voice(list/filter, list/special_filter)
	. = ..()
	special_filter |= TTS_FILTER_SILICON

/mob/living/clear_saypopup(image/say_popup)
	LAZYREMOVE(update_on_z, say_popup)

/**
 * Treats the passed message with things that may modify speech (stuttering, slurring etc).
 *
 * message - The message to treat.
 * capitalize_message - Whether we run capitalize() on the message after we're done.
 *
 * Returns a list, which is a packet of information corresponding to the message that has been treated, which
 * contains the new message, as well as text-to-speech information.
 */
/mob/living/treat_message(message, tts_message, tts_filter, capitalize_message = TRUE)
	RETURN_TYPE(/list)

	if(HAS_TRAIT(src, TRAIT_UNINTELLIGIBLE_SPEECH))
		message = unintelligize(message)

	tts_filter = list()
	var/list/data = list(message, tts_message, tts_filter, capitalize_message)
	SEND_SIGNAL(src, COMSIG_LIVING_TREAT_MESSAGE, data)
	message = data[TREAT_MESSAGE_ARG]
	tts_message = data[TREAT_TTS_MESSAGE_ARG]
	tts_filter = data[TREAT_TTS_FILTER_ARG]
	capitalize_message = data[TREAT_CAPITALIZE_MESSAGE]

	if(!tts_message)
		tts_message = message

	if(capitalize_message)
		message = capitalize(message)
		tts_message = capitalize(tts_message)

	///caps the length of individual letters to 3: ex: heeeeeeyy -> heeeyy
	/// prevents TTS from choking on unrealistic text while keeping emphasis
	var/static/regex/length_regex = regex(@"(.+)\1\1\1", "gi")
	while(length_regex.Find(tts_message))
		var/replacement = tts_message[length_regex.index]+tts_message[length_regex.index]+tts_message[length_regex.index]
		tts_message = replacetext(tts_message, length_regex.match, replacement, length_regex.index)

	// removes repeated consonants at the start of a word: ex: sss
	var/static/regex/word_start_regex = regex(@"\b([^aeiou\L])\1", "gi")
	while(word_start_regex.Find(tts_message))
		var/replacement = tts_message[word_start_regex.index]
		tts_message = replacetext(tts_message, word_start_regex.match, replacement, word_start_regex.index)

	return list("message" = message, "tts_message" = tts_message, "tts_filter" = tts_filter)

