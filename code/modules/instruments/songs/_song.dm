/**
 * # Song datum
 *
 * These are the actual backend behind instruments.
 * They attach to an atom and provide the editor + playback functionality.
 */
/datum/song
	/// Name of the song
	var/name = "Untitled"

	/// The atom we're attached to/playing from
	var/atom/parent

	/// Our song lines
	var/list/lines

	/// delay between notes in deciseconds
	var/tempo = 5

	/// How far we can be heard
	var/instrument_range = 15

	/// Are we currently playing?
	var/playing = FALSE

	/// Repeats left
	var/repeat = 0
	/// Maximum times we can repeat
	var/max_repeats = 10
	/// Whether playback should loop until manually stopped.
	var/auto_repeat = FALSE

	/// Our volume
	var/volume = 75
	/// Max volume
	var/max_volume = 100
	/// Min volume - This is so someone doesn't decide it's funny to set it to 0 and play invisible songs.
	var/min_volume = 1
	/// Current playback mode: "midi" uses the text note editor, "file" plays a loaded OGG as one sound.
	var/playback_mode = "midi"
	/// Uploaded sound file for file playback mode.
	var/file_track
	/// Display name for the uploaded sound file.
	var/file_track_name
	/// Cached file track duration.
	var/file_track_length = 0
	/// World time when current file playback should finish.
	var/file_track_finish_time = 0
	/// Uploaded OGG tracks available in this editor session.
	var/list/loaded_file_tracks = list()

	/// What instruments our built in picker can use. The picker won't show unless this is longer than one.
	var/list/allowed_instrument_ids = list("r3grand")

	//////////// Cached instrument variables /////////////
	/// Instrument we are currently using
	var/datum/instrument/using_instrument
	/// Cached legacy ext for legacy instruments
	var/cached_legacy_ext
	/// Cached legacy dir for legacy instruments
	var/cached_legacy_dir
	/// Cached list of samples, referenced directly from the instrument for synthesized instruments
	var/list/cached_samples
	/// Are we operating in legacy mode (so if the instrument is a legacy instrument)
	var/legacy = FALSE
	//////////////////////////////////////////////////////

	/////////////////// Playing variables ////////////////
	/**
	  * Build by compile_chords()
	  * Must be rebuilt on instrument switch.
	  * Compilation happens when we start playing and is cleared after we finish playing.
	  * Format: list of chord lists, with chordlists having (key1, key2, key3, tempodiv)
	  */
	var/list/compiled_chords
	/// Current section of a long chord we're on, so we don't need to make a billion chords, one for every unit ticklag.
	var/elapsed_delay
	/// Amount of delay to wait before playing the next chord
	var/delay_by
	/// Current chord we're on.
	var/current_chord
	/// Channel as text = current volume percentage but it's 0 to 100 instead of 0 to 1.
	var/list/channels_playing = list()
	/// List of channels that aren't being used, as text. This is to prevent unnecessary freeing and reallocations from SSsounds/SSinstruments.
	var/list/channels_idle = list()
	/// Who or what's playing us
	var/atom/music_player
	//////////////////////////////////////////////////////

	/// Last world.time we checked for who can hear us
	var/last_hearcheck = 0
	/// The list of mobs that can hear us
	var/list/hearing_mobs
	/// If this is enabled, some things won't be strictly cleared when they usually are (liked compiled_chords on play stop)
	var/debug_mode = FALSE
	/// Max sound channels to occupy
	var/max_sound_channels = CHANNELS_PER_INSTRUMENT
	/// Current channels, so we can save a length() call.
	var/using_sound_channels = 0
	/// Last channel to play. text.
	var/last_channel_played
	/// Last world time process() ran; used to catch up small MIDI timing stalls.
	var/last_process_time = 0
	/// MIDI start delay in subsystem ticks, used for manual/group synchronization.
	var/midi_start_delay_ticks = 0
	/// Timer id for a delayed MIDI start.
	var/midi_start_timer
	/// If TRUE, the next direct start ignores midi_start_delay_ticks.
	var/ignore_midi_start_delay = FALSE
	/// Should we not decay our last played note?
	var/full_sustain_held_note = TRUE

	/////////////////////// DO NOT TOUCH THESE ///////////////////
	var/octave_min = INSTRUMENT_MIN_OCTAVE
	var/octave_max = INSTRUMENT_MAX_OCTAVE
	var/key_min = INSTRUMENT_MIN_KEY
	var/key_max = INSTRUMENT_MAX_KEY
	var/static/list/note_offset_lookup = list(9, 11, 0, 2, 4, 5, 7)
	var/static/list/accent_lookup = list("b" = -1, "s" = 1, "#" = 1, "n" = 0)
	//////////////////////////////////////////////////////////////

	///////////// !!FUN!! - Only works in synthesized mode! /////////////////
	/// Note numbers to shift.
	var/note_shift = 0
	var/note_shift_min = -100
	var/note_shift_max = 100
	/// The kind of sustain we're using
	var/sustain_mode = SUSTAIN_LINEAR
	/// When a note is considered dead if it is below this in volume
	var/sustain_dropoff_volume = 0
	/// Total duration of linear sustain for 100 volume note to get to SUSTAIN_DROPOFF
	var/sustain_linear_duration = 5
	/// Exponential sustain dropoff rate per decisecond
	var/sustain_exponential_dropoff = 1.4
	////////// DO NOT DIRECTLY SET THESE!
	/// Do not directly set, use update_sustain()
	var/cached_linear_dropoff = 10
	/// Do not directly set, use update_sustain()
	var/cached_exponential_dropoff = 1.045
	/////////////////////////////////////////////////////////////////////////
	// BANDASTATION ADDITION - START
	/// straight BPM (integer)
	var/bpm = 120
	/// minimal BPM
	var/min_bpm = 1
	/// summaraized delay
	var/delay_residual = 0.0
	// BANDASTATION ADDITION - END

/datum/song/New(atom/parent, list/instrument_ids, new_range)
	SSinstruments.on_song_new(src)
	lines = list()
	// tempo = sanitize_tempo(tempo, TRUE) // BANDASTATION REMOVAL - BPM unlock
	src.parent = parent
	if(instrument_ids)
		allowed_instrument_ids = islist(instrument_ids) ? instrument_ids : list(instrument_ids)
	if(length(allowed_instrument_ids))
		set_instrument(allowed_instrument_ids[1])
	hearing_mobs = list()
	volume = clamp(volume, min_volume, max_volume)
	update_sustain()
	if(new_range)
		instrument_range = new_range
	set_bpm(120) // BANDASTATION ADDITION - BPM unlock

/datum/song/Destroy()
	stop_playing()
	SSinstruments.on_song_del(src)
	lines = null
	if(using_instrument)
		using_instrument.songs_using -= src
		using_instrument = null
	allowed_instrument_ids = null
	loaded_file_tracks = null
	parent = null
	return ..()

/**
 * Checks and stores which mobs can hear us. Terminates sounds for mobs that leave our range.
 */
/datum/song/proc/do_hearcheck()
	last_hearcheck = world.time
	var/list/old = hearing_mobs.Copy()
	hearing_mobs.len = 0
	var/turf/source = get_turf(parent)
	for(var/mob/M in get_hearers_in_view(instrument_range, source))
		hearing_mobs[M] = get_dist(M, source)
	var/list/exited = old - hearing_mobs
	for(var/i in exited)
		terminate_sound_mob(i)

/**
 * Sets our instrument, caching anything necessary for faster accessing. Accepts an ID, typepath, or instantiated instrument datum.
 */
/datum/song/proc/set_instrument(datum/instrument/I)
	terminate_all_sounds()
	var/old_legacy
	if(using_instrument)
		using_instrument.songs_using -= src
		old_legacy = (using_instrument.instrument_flags & INSTRUMENT_LEGACY)
	using_instrument = null
	cached_samples = null
	cached_legacy_ext = null
	cached_legacy_dir = null
	legacy = null
	if(istext(I) || ispath(I))
		I = SSinstruments.instrument_data[I]
	if(istype(I))
		using_instrument = I
		I.songs_using += src
		var/instrument_legacy = (I.instrument_flags & INSTRUMENT_LEGACY)
		if(instrument_legacy)
			cached_legacy_ext = I.legacy_instrument_ext
			cached_legacy_dir = I.legacy_instrument_path
			legacy = TRUE
		else
			cached_samples = I.samples
			legacy = FALSE
		if(isnull(old_legacy) || (old_legacy != instrument_legacy))
			if(playing)
				compile_chords()

/**
 * Attempts to start playing our song.
 */
/datum/song/proc/start_playing(atom/user)
	if(playing)
		return
	if(midi_start_timer)
		return
	if(!using_instrument?.ready())
		to_chat(user, span_warning("An error has occured with [src]. Please reset the instrument."))
		ignore_midi_start_delay = FALSE
		return
	if(playback_mode == "file")
		start_file_playing(user)
		return
	if(midi_start_delay_ticks > 0 && !ignore_midi_start_delay)
		midi_start_timer = addtimer(CALLBACK(src, PROC_REF(delayed_midi_start), user), midi_start_delay_ticks * SSinstruments.wait, TIMER_STOPPABLE)
		return
	ignore_midi_start_delay = FALSE
	compile_chords()
	if(!length(compiled_chords))
		to_chat(user, span_warning("Song is empty."))
		ignore_midi_start_delay = FALSE
		return
	playing = TRUE
	//we can not afford to runtime, since we are going to be doing sound channel reservations and if we runtime it means we have a channel allocation leak.
	//wrap the rest of the stuff to ensure stop_playing() is called.
	do_hearcheck()
	SEND_SIGNAL(parent, COMSIG_INSTRUMENT_START, src, user)
	SEND_SIGNAL(user, COMSIG_ATOM_STARTING_INSTRUMENT, src)
	elapsed_delay = 0
	delay_by = 0
	delay_residual = 0.0 // BANDASTATION ADDITION - BPM unlock
	current_chord = 1
	music_player = user
	last_process_time = world.time
	START_PROCESSING(SSinstruments, src)

/datum/song/proc/delayed_midi_start(atom/user)
	midi_start_timer = null
	ignore_midi_start_delay = TRUE
	start_playing(user)

/datum/song/proc/cancel_delayed_midi_start()
	if(!midi_start_timer)
		return FALSE
	deltimer(midi_start_timer)
	midi_start_timer = null
	ignore_midi_start_delay = FALSE
	return TRUE

/**
 * Finds a player which would reasonably be able to play this song.
 */
/datum/song/proc/find_available_player()
	return null

/**
 * Stops playing, terminating all sounds if in synthesized mode. Clears hearing_mobs.
 *
 * Arguments:
 * * finished: boolean, whether the song ended via reaching the end.
 */
/datum/song/proc/stop_playing(finished = FALSE)
	ignore_play_checks = FALSE // BANDASTATION ADDITION - New Musical Sync

	cancel_delayed_midi_start()
	if(!playing)
		return
	playing = FALSE
	if(!debug_mode)
		compiled_chords = null
	STOP_PROCESSING(SSinstruments, src)
	SEND_SIGNAL(parent, COMSIG_INSTRUMENT_END, finished)
	terminate_all_sounds(TRUE)
	hearing_mobs.len = 0
	music_player = null
	file_track_finish_time = 0
	last_process_time = 0
	ignore_midi_start_delay = FALSE

	// BANDASTATION ADDITION START - New Musical Sync
	// BANDASTATION ADDITION END - New Musical Sync

/**
 * Processes our song.
 */
/datum/song/proc/process_song(wait)
	if(playback_mode == "file")
		if(playing)
			process_file_playing()
			return
		return PROCESS_KILL

	if(playing) // BANDASTATION ADDITION - New Musical Sync
		if(!length(compiled_chords))
			stop_playing(TRUE)
			return
		if(should_stop_playing(music_player) == STOP_PLAYING)
			stop_playing(FALSE)
			return
		var/list/chord = compiled_chords[current_chord]
		elapsed_delay++
		if(elapsed_delay < delay_by)
			return
		play_chord(chord)
		elapsed_delay = 0
		delay_by = tempodiv_to_delay(chord[length(chord)])
		current_chord++
		if(current_chord <= length(compiled_chords))
			return
		if(!repeat && !auto_repeat)
			stop_playing(TRUE)
			return
		if(!auto_repeat)
			repeat--
		current_chord = 1
		SEND_SIGNAL(parent, COMSIG_INSTRUMENT_REPEAT, TRUE)

	return PROCESS_KILL

	// BANDASTATION ADDITION END- New Musical Sync

/**
 * Converts a tempodiv to ticks to elapse before playing the next chord, taking into account our tempo.
 */
/datum/song/proc/tempodiv_to_delay(tempodiv)
	if(!tempodiv)
		tempodiv = 1 // no division by 0. some song converters tend to use 0 for when it wants to have no div, for whatever reason.
	// BANDASTATION EDIT START - BPM unlock
	var/ds_per_beat = (60 SECONDS) / bpm
	var/ds_per_div  = ds_per_beat / tempodiv
	var/exact_ticks = ds_per_div / world.tick_lag

	var/with_res = exact_ticks + delay_residual
	var/ticks = floor(with_res)
	if(ticks < 1)
		ticks = 1
	delay_residual = with_res - ticks

	return ticks
	// BANDASTATION EDIT END - BPM unlock

/**
 * Compiles chords.
 */
/datum/song/proc/compile_chords()
	legacy? compile_legacy() : compile_synthesized()

/**
 * Plays a chord.
 */
/datum/song/proc/play_chord(list/chord)
	// last value is timing information
	for(var/i in 1 to (length(chord) - 1))
		legacy? playkey_legacy(chord[i][1], chord[i][2], chord[i][3], music_player) : playkey_synth(chord[i], music_player)

/**
 * Checks if we should halt playback.
 */
/datum/song/proc/should_stop_playing(atom/player)
	if(QDELETED(player) || !using_instrument || !playing)
		return STOP_PLAYING
	return SEND_SIGNAL(parent, COMSIG_INSTRUMENT_SHOULD_STOP_PLAYING, player)

/// Sets and sanitizes the repeats variable.
/datum/song/proc/set_repeats(new_repeats_value)
	repeat = round(new_repeats_value)
	if(repeat < 0)
		repeat = 0
	if(repeat > max_repeats)
		repeat = max_repeats


/**
 * Sanitizes tempo to a value that makes sense and fits the current world.tick_lag.
 */
/datum/song/proc/sanitize_tempo(new_tempo, initializing = FALSE)
	new_tempo = abs(new_tempo)
	if(!initializing) // not only is it not helpful while initializing but it will runtime really hard since nothing is set up
		SEND_SIGNAL(parent, COMSIG_INSTRUMENT_TEMPO_CHANGE, src)
	return clamp(round(new_tempo, world.tick_lag), world.tick_lag, 5 SECONDS)

/**
 * Gets our beats per minute based on our tempo.
 */
/datum/song/proc/get_bpm()
	return 600 / tempo

/**
 * Sets our tempo from a beats-per-minute, sanitizing it to a valid number first.
 */
// BANDASTATION EDIT START - BPM unlock
/datum/song/proc/set_bpm(new_bpm)
	// tempo = sanitize_tempo(600 / bpm)
	new_bpm = clamp(round(new_bpm), min_bpm, get_max_bpm())
	if(new_bpm == bpm)
		return
	bpm = new_bpm

	// BANDASTATION ADD: legacy tempo = deciseconds per beat
	tempo = sanitize_tempo((60 SECONDS) / bpm, TRUE)

	SEND_SIGNAL(parent, COMSIG_INSTRUMENT_TEMPO_CHANGE, src)
	delay_residual = 0.0
	// BANDASTATION EDIT END - BPM unlock

/datum/song/proc/get_max_bpm()
	// сколько тиков в минуте: 60 сек / tick_lag
	return max(1, round((60 SECONDS) / world.tick_lag))

/datum/song/process(wait)
	if(!playing)
		return PROCESS_KILL
	if(playing && playback_mode != "file")
		var/elapsed = last_process_time ? max(world.tick_lag, world.time - last_process_time) : world.tick_lag
		last_process_time = world.time
		var/steps = clamp(round(elapsed / world.tick_lag), 1, 4)
		for(var/i in 1 to steps)
			if(!playing)
				break
			process_song(world.tick_lag)
			process_decay(world.tick_lag)
		return
	last_process_time = world.time
	process_song(world.tick_lag)

/**
 * Updates our cached linear/exponential falloff stuff, saving calculations down the line.
 */
/datum/song/proc/update_sustain()
	// Exponential is easy
	cached_exponential_dropoff = sustain_exponential_dropoff
	// Linear, not so much, since it's a target duration from 100 volume rather than an exponential rate.
	var/target_duration = sustain_linear_duration
	var/volume_diff = max(0, 100 - sustain_dropoff_volume)
	var/volume_decrease_per_decisecond = volume_diff / target_duration
	cached_linear_dropoff = volume_decrease_per_decisecond

/**
 * Setter for setting output volume.
 */
/datum/song/proc/set_volume(volume)
	src.volume = clamp(round(volume, 1), max(0, min_volume), max_volume)
	update_sustain()
	if(playing && playback_mode == "file")
		update_file_playback_volume()

/// Returns the actual sound volume sent to clients. UI stays 0-100, output has headroom for quiet tracks.
/datum/song/proc/get_output_volume(base_volume = volume)
	return base_volume * INSTRUMENT_OUTPUT_GAIN

/// File-backed OGG playback needs more headroom than MIDI notes.
/datum/song/proc/get_file_output_volume(base_volume = volume)
	return base_volume * INSTRUMENT_FILE_OUTPUT_GAIN

/// Keeps falloff valid for short-range instruments and circuits.
/datum/song/proc/get_sound_falloff_distance()
	if(instrument_range <= 1)
		return 0
	return min(INSTRUMENT_FALLOFF_DISTANCE, instrument_range - 1)

/datum/song/proc/set_playback_mode(new_mode)
	if(!(new_mode in list("midi", "file")))
		return
	if(playing)
		stop_playing()
	playback_mode = new_mode

/datum/song/proc/set_file_track(new_file, mob/user)
	if(!new_file || !IS_OGG_FILE(new_file))
		if(user)
			to_chat(user, span_warning("Only OGG files are supported for file playback."))
		return FALSE
	if(playing)
		stop_playing()
	file_track = new_file
	file_track_name = SANITIZE_FILENAME("[new_file]")
	file_track_length = SSsounds.get_sound_length(new_file)
	if(!file_track_length)
		file_track_length = 270 SECONDS
	store_loaded_file_track(file_track_name, file_track, file_track_length)
	playback_mode = "file"
	return TRUE

/datum/song/proc/store_loaded_file_track(track_name, track_file, track_length)
	for(var/list/track as anything in loaded_file_tracks)
		if(track["name"] == track_name)
			track["file"] = track_file
			track["length"] = track_length
			return
	loaded_file_tracks += list(list(
		"name" = track_name,
		"file" = track_file,
		"length" = track_length,
	))

/datum/song/proc/select_loaded_file_track(track_name)
	for(var/list/track as anything in loaded_file_tracks)
		if(track["name"] != track_name)
			continue
		if(playing)
			stop_playing()
		file_track = track["file"]
		file_track_name = track["name"]
		file_track_length = track["length"] || 270 SECONDS
		playback_mode = "file"
		return TRUE
	return FALSE

/datum/song/proc/set_file_track_length(new_length)
	new_length = round(text2num("[new_length]"))
	if(!isnum(new_length))
		return FALSE
	file_track_length = clamp(new_length, 1 SECONDS, 30 MINUTES)
	for(var/list/track as anything in loaded_file_tracks)
		if(track["name"] == file_track_name)
			track["length"] = file_track_length
			break
	if(playing && playback_mode == "file")
		file_track_finish_time = world.time + file_track_length
	return TRUE

/datum/song/proc/set_auto_repeat(new_auto_repeat)
	auto_repeat = !!new_auto_repeat

/datum/song/proc/update_file_playback_volume()
	for(var/channel in channels_playing)
		var/channel_number = text2num(channel)
		for(var/i in hearing_mobs)
			var/mob/listener = i
			listener.set_sound_channel_volume(channel_number, get_file_output_volume() * get_listener_volume_multiplier(listener))

/datum/song/proc/clear_file_track()
	if(playing && playback_mode == "file")
		stop_playing()
	file_track = null
	file_track_name = null
	file_track_length = 0
	if(playback_mode == "file")
		playback_mode = "midi"

/datum/song/proc/start_file_playing(atom/user)
	if(!file_track)
		to_chat(user, span_warning("No OGG file loaded."))
		return
	playing = TRUE
	do_hearcheck()
	SEND_SIGNAL(parent, COMSIG_INSTRUMENT_START, src, user)
	SEND_SIGNAL(user, COMSIG_ATOM_STARTING_INSTRUMENT, src)
	music_player = user
	last_process_time = world.time
	play_file_to_current_listeners(user)
	file_track_finish_time = world.time + file_track_length
	START_PROCESSING(SSinstruments, src)

/datum/song/proc/play_file_to_current_listeners(atom/player)
	var/channel = pop_channel()
	if(isnull(channel))
		return FALSE
	var/channel_text = num2text(channel)
	channels_playing[channel_text] = 100
	last_channel_played = channel_text
	var/turf/source = get_turf(parent)
	var/sound/music_played = sound(file_track)
	music_played.channel = channel
	music_played.volume = get_file_output_volume()
	for(var/i in hearing_mobs)
		var/mob/listener = i
		var/listener_volume = get_listener_volume_multiplier(listener)
		if(!listener_volume)
			continue
		listener.playsound_local(source, null, get_file_output_volume() * listener_volume, sound_to_use = music_played, channel = channel, pressure_affected = FALSE, max_distance = instrument_range, falloff_distance = get_sound_falloff_distance(), falloff_exponent = INSTRUMENT_FALLOFF_EXPONENT)
	return TRUE

/datum/song/proc/process_file_playing()
	if(should_stop_playing(music_player) == STOP_PLAYING)
		stop_playing(FALSE)
		return
	pulse_cyberpunk_music_perks(music_player)
	if(world.time < file_track_finish_time)
		return
	if(repeat > 0 || auto_repeat)
		repeat--
		if(auto_repeat)
			repeat = max(repeat, 0)
		terminate_all_sounds(TRUE)
		do_hearcheck()
		play_file_to_current_listeners(music_player)
		file_track_finish_time = world.time + file_track_length
		SEND_SIGNAL(parent, COMSIG_INSTRUMENT_REPEAT, TRUE)
		return
	stop_playing(TRUE)

/// Returns the listener-specific volume multiplier for instrument notes.
/datum/song/proc/get_listener_volume_multiplier(mob/listener)
	var/instrument_volume = listener?.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_instruments)
	if(!instrument_volume)
		return 0

	if(isliving(listener))
		var/mob/living/living_listener = listener
		if(living_listener.combat_mode)
			var/combat_volume = listener.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_combat_music)
			if(combat_volume > 0 && combat_volume <= instrument_volume)
				instrument_volume = min(instrument_volume, combat_volume * 0.5)

	if(length(GLOB.active_jukebox_music_listeners[listener]))
		instrument_volume *= 0.25

	return instrument_volume / 100

/**
 * Setter for setting how low the volume has to get before a note is considered "dead" and dropped
 */
/datum/song/proc/set_dropoff_volume(volume)
	sustain_dropoff_volume = clamp(round(volume, 0.01), INSTRUMENT_MIN_SUSTAIN_DROPOFF, 100)
	update_sustain()

/**
 * Setter for setting exponential falloff factor.
 */
/datum/song/proc/set_exponential_drop_rate(drop)
	sustain_exponential_dropoff = clamp(round(drop, 0.00001), INSTRUMENT_EXP_FALLOFF_MIN, INSTRUMENT_EXP_FALLOFF_MAX)
	update_sustain()

/**
 * Setter for setting linear falloff duration.
 */
/datum/song/proc/set_linear_falloff_duration(duration)
	sustain_linear_duration = clamp(round(duration * 10, world.tick_lag), world.tick_lag, INSTRUMENT_MAX_TOTAL_SUSTAIN)
	update_sustain()

/datum/song/vv_edit_var(var_name, var_value)
	. = ..()
	if(.)
		switch(var_name)
			if(NAMEOF(src, volume))
				set_volume(var_value)
			if(NAMEOF(src, sustain_dropoff_volume))
				set_dropoff_volume(var_value)
			if(NAMEOF(src, sustain_exponential_dropoff))
				set_exponential_drop_rate(var_value)
			if(NAMEOF(src, sustain_linear_duration))
				set_linear_falloff_duration(var_value)

// subtype for handheld instruments, like violin
/datum/song/handheld

/datum/song/handheld/should_stop_playing(atom/player)
	. = ..()
	if(. == STOP_PLAYING || . == IGNORE_INSTRUMENT_CHECKS)
		return
	var/obj/item/instrument/I = parent
	return I.can_play(player) ? NONE : STOP_PLAYING

/datum/song/handheld/find_available_player()
	var/obj/item/instrument/instrument = parent
	var/mob/living/player = get(parent, /mob/living)
	if(instrument.can_play(player))
		return player
	return null

// subtype for stationary structures, like pianos
/datum/song/stationary

/datum/song/stationary/should_stop_playing(atom/player)
	. = ..()
	if(. == STOP_PLAYING || . == IGNORE_INSTRUMENT_CHECKS)
		return
	var/obj/structure/musician/M = parent
	return M.can_play(player) ? NONE : STOP_PLAYING

/datum/song/stationary/find_available_player()
	var/obj/structure/musician/piano = parent
	for(var/mob/living/player in view(parent, 1))
		if(piano.can_play(player))
			return player

	return null
