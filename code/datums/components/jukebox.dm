// Reasons for appling STATUS_MUTE to a mob's sound status
/// The mob is deaf
#define MUTE_DEAF (1<<0)
/// The mob has disabled jukeboxes in their preferences
#define MUTE_PREF (1<<1)
/// The mob is out of range of the jukebox
#define MUTE_RANGE (1<<2)
/// Internal jukebox gain. UI volume remains 0-100, output gets headroom for quiet OGGs.
#define JUKEBOX_OUTPUT_GAIN 3

/**
 * ## Jukebox datum
 *
 * Plays music to nearby mobs when hosted in a movable or a turf.
 */
/datum/jukebox
	/// Atom that hosts the jukebox. Can be a turf or a movable.
	VAR_FINAL/atom/parent
	/// List of /datum/tracks we can play. Set via get_songs().
	VAR_FINAL/list/songs = list()
	/// Current song track selected
	VAR_FINAL/datum/track/selection
	/// Current song datum playing
	VAR_FINAL/sound/active_song_sound
	/// Whether the jukebox requires a connect_range component to check for new listeners
	VAR_PROTECTED/requires_range_check = TRUE

	/// Assoc list of all mobs listening to the jukebox to their sound status.
	VAR_PRIVATE/list/mob/listeners = list()
	/// Additional atoms that emit this jukebox's music, such as linked speakers.
	VAR_PRIVATE/list/atom/extra_sources = list()
	/// connect_range components attached to extra emitters.
	VAR_PRIVATE/list/source_range_components = list()

	/// Volume of the songs played. Also serves as the max volume.
	/// Do not set directly, use set_new_volume() instead.
	VAR_PROTECTED/volume = 100

	/// Range at which the sound plays to players, can also be a view "XxY" string
	VAR_PROTECTED/sound_range
	/// How far away horizontally from the jukebox can you be before you stop hearing it
	VAR_PRIVATE/x_cutoff
	/// How far away vertically from the jukebox can you be before you stop hearing it
	VAR_PRIVATE/z_cutoff
	/// Whether the music loops when done.
	/// If FALSE, you must handle ending music yourself.
	var/sound_loops = FALSE

/datum/jukebox/New(atom/new_parent)
	if(!ismovable(new_parent) && !isturf(new_parent))
		stack_trace("[type] created on non-turf or non-movable: [new_parent ? "[new_parent] ([new_parent.type])" : "null"])")
		qdel(src)
		return

	parent = new_parent

	if(isnull(sound_range))
		sound_range = world.view
		var/list/worldviewsize = getviewsize(sound_range)
		x_cutoff = ceil(worldviewsize[1] * 1.25 / 2) // * 1.25 gives us some extra range to fade out with
		z_cutoff = ceil(worldviewsize[2] * 1.25 / 2) // and / 2 is because world view is the whole screen, and we want the centre

	if(requires_range_check)
		var/static/list/connections = list(COMSIG_ATOM_ENTERED = PROC_REF(check_new_listener))
		AddComponent(/datum/component/connect_range, parent, connections, max(x_cutoff, z_cutoff))

	songs = init_songs()
	if(length(songs))
		selection = songs[pick(songs)]

	RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(on_enter_area))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_QDELETING, PROC_REF(parent_delete))

/datum/jukebox/Destroy()
	unlisten_all()
	for(var/atom/source as anything in extra_sources)
		unregister_music_source(source)
	parent = null
	selection = null
	songs.Cut()
	extra_sources.Cut()
	source_range_components.Cut()
	active_song_sound = null
	return ..()

/// When our parent is deleted, we should go too.
/datum/jukebox/proc/parent_delete(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/**
 * Initializes the track list.
 *
 * By default, this loads all tracks from the config datum.
 *
 * Returns
 * * An assoc list of track names to /datum/track. Track names must be unique.
 */
/datum/jukebox/proc/init_songs()
	return load_songs_from_config()

/// Loads the config sounds once, and returns a copy of them.
/datum/jukebox/proc/load_songs_from_config()
	var/static/list/config_songs
	if(isnull(config_songs))
		config_songs = list()
		var/list/tracks = flist(CONFIG_JUKEBOX_SOUNDS)
		for(var/track_file in tracks)
			var/datum/track/new_track = new()
			new_track.song_path = file("[CONFIG_JUKEBOX_SOUNDS][track_file]")
			var/list/track_data = splittext(track_file, "+")
			if(!length(track_data) || !IS_SOUND_FILE_SAFE(new_track.song_path))
				continue
			var/track_name = track_data[JUKEBOX_NAME]
			track_name = strip_filepath_extension(track_name, SSsounds.safe_formats)
			new_track.song_name = track_name
			new_track.song_length = SSsounds.get_sound_length(new_track.song_path)
			if(track_data.len >= 3) // Bandaid for legacy tracks to not use the length for the bpm rather then the actual beats.
				var/static/logged_to_admins = FALSE
				log_game("[new_track.song_path] track data seems to be using the legacy format; we will attempt to make it work.")
				if(!logged_to_admins)
					message_admins("The jukebox has tracks uploaded in a legacy format. Length is now fetched programmatically, with title and beats being the only required fields.")
					logged_to_admins = TRUE
				new_track.song_beat_deciseconds = text2num(track_data[3])
			else if(track_data.len >= 2)
				new_track.song_beat_deciseconds = text2num(track_data[JUKEBOX_BEATS])
			config_songs[new_track.song_name] = new_track

		if(!length(config_songs))
			var/datum/track/default/default_track = new()
			config_songs[default_track.song_name] = default_track

	// returns a copy so it can mutate if desired.
	return config_songs.Copy()

/**
 * Returns a set of general data relating to the jukebox for use in TGUI.
 *
 * Returns
 * * A list of UI data
 */
/datum/jukebox/proc/get_ui_data()
	var/list/data = list()
	var/list/songs_data = list()
	for(var/song_name in songs)
		var/datum/track/one_song = songs[song_name]
		UNTYPED_LIST_ADD(songs_data, list( \
			"name" = song_name, \
			"length" = one_song.song_length  /* BANDASTATION EDIT - ORIGINAL: DisplayTimeText(one_song.song_length) */, \
			"beat" = one_song.song_beat_deciseconds || "Unknown", \
		))

	data["active"] = !!active_song_sound
	data["songs"] = songs_data
	data["track_selected"] = selection?.song_name
	data["looping"] = sound_loops
	data["volume"] = volume
	return data

/**
 * Sets the sound's range to a new value. This can be a number or a view size string "XxY".
 * Then updates any mobs listening to it.
 */
/datum/jukebox/proc/set_sound_range(new_range)
	if(sound_range == new_range)
		return
	sound_range = new_range
	var/list/worldviewsize = getviewsize(sound_range)
	x_cutoff = ceil(worldviewsize[1] / 2)
	z_cutoff = ceil(worldviewsize[2] / 2)
	update_all()

/**
 * Sets the sound's volume to a new value.
 * Then updates any mobs listening to it.
 */
/datum/jukebox/proc/set_new_volume(new_vol)
	new_vol = clamp(new_vol, 0, initial(volume))
	if(volume == new_vol)
		return
	volume = new_vol
	if(!active_song_sound)
		return
	active_song_sound.volume = get_output_volume()
	update_all()

/// Sets volume to the maximum possible value, the initial volume value.
/datum/jukebox/proc/set_volume_to_max()
	set_new_volume(initial(volume))

/**
 * Sets the sound's environment to a new value.
 * Then updates any mobs listening to it.
 */
/datum/jukebox/proc/set_new_environment(new_env)
	if(!active_song_sound || active_song_sound.environment == new_env)
		return
	active_song_sound.environment = new_env
	update_all()

/// Helper to stop the music for all mobs listening to the music.
/datum/jukebox/proc/unlisten_all()
	for(var/mob/listening as anything in listeners)
		deregister_listener(listening)
	active_song_sound = null

/// Returns all atoms that currently emit this jukebox.
/datum/jukebox/proc/get_music_sources()
	var/list/sources = list(parent)
	for(var/atom/source as anything in extra_sources)
		if(!QDELETED(source))
			sources += source
	return sources

/// Returns the actual sound volume sent to clients. UI stays 0-100.
/datum/jukebox/proc/get_output_volume(base_volume = volume)
	return base_volume * JUKEBOX_OUTPUT_GAIN

/// BYOND sound falloff should cover the whole jukebox range, otherwise music drops too hard near speakers.
/datum/jukebox/proc/get_sound_falloff()
	return max(1, x_cutoff, z_cutoff)

/// Adds an external music emitter to this jukebox.
/datum/jukebox/proc/register_music_source(atom/source)
	if(!source || QDELETED(source) || (source == parent) || (source in extra_sources))
		return FALSE
	extra_sources += source
	RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(source, COMSIG_QDELETING, PROC_REF(music_source_deleted))
	if(requires_range_check)
		var/static/list/connections = list(COMSIG_ATOM_ENTERED = PROC_REF(check_new_listener))
		source_range_components[source] = AddComponent(/datum/component/connect_range, source, connections, max(x_cutoff, z_cutoff))
	if(active_song_sound)
		for(var/mob/nearby in hearers(sound_range, source))
			if(!(nearby in listeners))
				register_listener(nearby)
		update_all()
	return TRUE

/// Removes an external music emitter from this jukebox.
/datum/jukebox/proc/unregister_music_source(atom/source)
	if(!(source in extra_sources))
		return FALSE
	extra_sources -= source
	UnregisterSignal(source, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
	var/datum/component/range_component = source_range_components[source]
	qdel(range_component)
	source_range_components -= source
	update_all()
	return TRUE

/// Removes deleted external music emitters.
/datum/jukebox/proc/music_source_deleted(atom/source)
	SIGNAL_HANDLER
	unregister_music_source(source)

/// Helper to update all mobs currently listening to the music.
/datum/jukebox/proc/update_all()
	for(var/mob/listening as anything in listeners)
		update_listener(listening)

/// Helper to kickstart the music for all mobs in hearing range of the jukebox.
/datum/jukebox/proc/start_music()
	for(var/atom/source as anything in get_music_sources())
		for(var/mob/nearby in hearers(sound_range, source))
			if(nearby in listeners)
				continue
			register_listener(nearby)

/// Helper to get all mobs currently, ACTIVELY listening to the jukebox.
/datum/jukebox/proc/get_active_listeners()
	var/list/all_listeners = list()
	for(var/mob/listener as anything in listeners)
		if(listeners[listener] & SOUND_MUTE)
			continue
		all_listeners += listener
	return all_listeners

/// Registers the passed mob as a new listener to the jukebox.
/datum/jukebox/proc/register_listener(mob/new_listener)
	PROTECTED_PROC(TRUE)

	listeners[new_listener] = NONE
	RegisterSignal(new_listener, COMSIG_QDELETING, PROC_REF(listener_deleted))

	if(isnull(new_listener.client))
		RegisterSignal(new_listener, COMSIG_MOB_LOGIN, PROC_REF(listener_login))
		return

	RegisterSignals(new_listener, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_JUKEBOX_PREFERENCE_APPLIED), PROC_REF(listener_moved))
	RegisterSignals(new_listener, list(SIGNAL_ADDTRAIT(TRAIT_DEAF), SIGNAL_REMOVETRAIT(TRAIT_DEAF)), PROC_REF(listener_deaf))
	var/pref_volume = new_listener.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_jukebox)
	if(HAS_TRAIT(new_listener, TRAIT_DEAF) || !pref_volume)
		listeners[new_listener] |= SOUND_MUTE

	if(isnull(active_song_sound))
		var/area/juke_area = get_area(parent)
		active_song_sound = sound(selection.song_path)
		active_song_sound.channel = CHANNEL_JUKEBOX
		active_song_sound.priority = 255
		active_song_sound.falloff = get_sound_falloff()
		active_song_sound.volume = get_output_volume() * (pref_volume/100)
		active_song_sound.y = 1
		active_song_sound.environment = juke_area.sound_environment || SOUND_ENVIRONMENT_NONE
		active_song_sound.repeat = sound_loops

	update_listener(new_listener)
	// if you have a sound with status SOUND_UPDATE,
	// and try to play it to a client who is not listening to the sound already,
	// it will not work.
	// so we only add this status AFTER the first update, which plays the first sound.
	// and after that it's fine to keep it on the sound so it updates as the x/z does.
	listeners[new_listener] |= SOUND_UPDATE

/// Tracks whether this jukebox currently has audible priority over a listener.
/datum/jukebox/proc/set_listener_music_priority(mob/listener, active)
	if(!listener)
		return
	var/list/active_jukeboxes = GLOB.active_jukebox_music_listeners[listener]
	var/had_priority = length(active_jukeboxes)
	if(active)
		if(isnull(active_jukeboxes))
			active_jukeboxes = list()
			GLOB.active_jukebox_music_listeners[listener] = active_jukeboxes
		active_jukeboxes[src] = TRUE
		if(!had_priority)
			listener.refresh_looping_ambience()
		return
	if(!isnull(active_jukeboxes))
		active_jukeboxes -= src
		if(!length(active_jukeboxes))
			GLOB.active_jukebox_music_listeners -= listener
			if(had_priority)
				listener.refresh_looping_ambience()

/// Deregisters mobs on deletion.
/datum/jukebox/proc/listener_deleted(mob/source)
	SIGNAL_HANDLER
	deregister_listener(source)

/// Updates the sound's position on mob movement.
/datum/jukebox/proc/listener_moved(mob/source)
	SIGNAL_HANDLER
	update_listener(source)

/// Allows mobs who are clientless when the music starts to hear it when they log in.
/datum/jukebox/proc/listener_login(mob/source)
	SIGNAL_HANDLER
	deregister_listener(source)
	register_listener(source)

/// Updates the sound's mute status when the mob's deafness updates.
/datum/jukebox/proc/listener_deaf(mob/source)
	SIGNAL_HANDLER

	if(HAS_TRAIT(source, TRAIT_DEAF))
		listeners[source] |= SOUND_MUTE
	else if(!unmute_listener(source, MUTE_DEAF))
		return
	update_listener(source)

/**
 * Unmutes the passed mob's sound from the passed reason.
 *
 * Arguments
 * * mob/listener - The mob to unmute.
 * * reason - The reason to unmute them for. Can be a combination of MUTE_DEAF, MUTE_PREF, MUTE_RANGE.
 */
/datum/jukebox/proc/unmute_listener(mob/listener, reason)
	// We need to check everything BUT the reason we're unmuting for
	// Because if we're muted for a different reason we don't wanna touch it
	reason = ~reason

	if((reason & MUTE_DEAF) && HAS_TRAIT(listener, TRAIT_DEAF))
		return FALSE
	var/pref_volume = listener.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_jukebox)
	if((reason & MUTE_PREF) && !pref_volume)
		return FALSE

	if(reason & MUTE_RANGE)
		var/turf/listener_turf = get_turf(listener)
		if(isnull(listener_turf))
			return FALSE
		var/source_in_range = FALSE
		for(var/atom/source as anything in get_music_sources())
			var/turf/sound_turf = get_turf(source)
			if(isnull(sound_turf) || sound_turf.z != listener_turf.z)
				continue
			if(abs(sound_turf.x - listener_turf.x) > x_cutoff)
				continue
			if(abs(sound_turf.y - listener_turf.y) > z_cutoff)
				continue
			source_in_range = TRUE
			break
		if(!source_in_range)
			return FALSE

	listeners[listener] &= ~SOUND_MUTE
	return TRUE

/// Deregisters the passed mob as a listener to the jukebox, stopping the music.
/datum/jukebox/proc/deregister_listener(mob/no_longer_listening)
	PROTECTED_PROC(TRUE)

	set_listener_music_priority(no_longer_listening, FALSE)
	listeners -= no_longer_listening
	no_longer_listening.stop_sound_channel(CHANNEL_JUKEBOX)
	UnregisterSignal(no_longer_listening, list(
		COMSIG_MOB_LOGIN,
		COMSIG_QDELETING,
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOB_JUKEBOX_PREFERENCE_APPLIED,
		SIGNAL_ADDTRAIT(TRAIT_DEAF),
		SIGNAL_REMOVETRAIT(TRAIT_DEAF),
	))

/// Updates the passed mob's sound in according to their position and status.
/datum/jukebox/proc/update_listener(mob/listener)
	PROTECTED_PROC(TRUE)

	active_song_sound.status = listeners[listener] || NONE

	var/turf/sound_turf
	var/turf/listener_turf = get_turf(listener)
	var/best_distance = INFINITY
	for(var/atom/source as anything in get_music_sources())
		var/turf/source_turf = get_turf(source)
		if(isnull(source_turf) || isnull(listener_turf))
			continue
		if(source_turf.z != listener_turf.z)
			continue
		var/source_x = source_turf.x - listener_turf.x
		var/source_z = source_turf.y - listener_turf.y
		if(abs(source_x) > x_cutoff || abs(source_z) > z_cutoff)
			continue
		var/source_distance = abs(source_x) + abs(source_z)
		if(source_distance >= best_distance)
			continue
		best_distance = source_distance
		sound_turf = source_turf

	if(isnull(sound_turf) || isnull(listener_turf)) // ??
		active_song_sound.x = 0
		active_song_sound.z = 0
		listeners[listener] |= SOUND_MUTE

	else if(sound_turf.z != listener_turf.z) // Could MAYBE model multi-z jukeboxes but that's too complex for now
		listeners[listener] |= SOUND_MUTE

	else
		// keep in mind sound XYZ is different to world XYZ. sound +-z = world +-y
		var/new_x = sound_turf.x - listener_turf.x
		var/new_z = sound_turf.y - listener_turf.y

		if((abs(new_x) > x_cutoff || abs(new_z) > z_cutoff))
			listeners[listener] |= SOUND_MUTE

		else if(listeners[listener] & SOUND_MUTE)
			unmute_listener(listener, MUTE_RANGE)

		active_song_sound.x = new_x
		active_song_sound.z = new_z

		var/pref_volume = listener.client?.prefs.read_preference(/datum/preference/numeric/volume/sound_jukebox)
		if(!pref_volume)
			listeners[listener] |= SOUND_MUTE
		else
			unmute_listener(listener, MUTE_PREF)
			active_song_sound.falloff = get_sound_falloff()
			active_song_sound.volume = get_output_volume() * (pref_volume/100)

	active_song_sound.status = listeners[listener] || NONE
	set_listener_music_priority(listener, !(listeners[listener] & SOUND_MUTE))
	SEND_SOUND(listener, active_song_sound)

/// When the jukebox moves, we need to update all listeners.
/datum/jukebox/proc/on_moved(datum/source, ...)
	SIGNAL_HANDLER
	update_all()

/// When the jukebox enters a new area entirely, we need to update the environment to the new area's.
/datum/jukebox/proc/on_enter_area(datum/source, area/area_to_register)
	SIGNAL_HANDLER
	set_new_environment(area_to_register.sound_environment || SOUND_ENVIRONMENT_NONE)

/// Check for new mobs entering the jukebox's range.
/datum/jukebox/proc/check_new_listener(datum/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(isnull(active_song_sound))
		return
	if(!ismob(entered))
		return
	if(entered in listeners)
		return
	register_listener(entered)

/**
 * Subtype which only plays the music to the mob you pass in via start_music().
 *
 * Multiple mobs can still listen at once, but you must register them all manually via start_music().
 */
/datum/jukebox/single_mob
	requires_range_check = FALSE

/datum/jukebox/single_mob/start_music(mob/solo_listener)
	register_listener(solo_listener)

/datum/jukebox/concertspeaker

/datum/jukebox/concertspeaker/init_songs()
	return list()

/datum/jukebox/concertspeaker/proc/load_concert_disk(obj/item/disk/concert/disk)
	unlisten_all()
	songs.Cut()
	if(!disk)
		selection = null
		return
	var/datum/track/disk_track = new()
	disk_track.song_name = disk.track_name
	disk_track.song_path = disk.track_path
	disk_track.song_length = disk.track_length
	disk_track.song_beat_deciseconds = disk.track_beat_deciseconds
	songs[disk_track.song_name] = disk_track
	selection = disk_track

/datum/jukebox/concertspeaker/proc/clear_concert_disk()
	unlisten_all()
	songs.Cut()
	selection = null

#undef MUTE_DEAF
#undef MUTE_PREF
#undef MUTE_RANGE
#undef JUKEBOX_OUTPUT_GAIN

/// Track datums, used in jukeboxes
/datum/track
	/// Readable name, used in the jukebox menu
	var/song_name = "generic"
	/// Filepath of the song
	var/song_path = null
	/// How long is the song in deciseconds
	var/song_length = 0
	/// How long is a beat of the song in decisconds
	/// Used to determine time between effects when played
	/// Do note this is NOT BPM.
	var/song_beat_deciseconds = 0

// Default track supplied for testing and also because it's a banger
/datum/track/default
	song_path = 'sound/music/lobby_music/title3.ogg'
	song_name = "Tintin on the Moon"
	song_length = 3 MINUTES + 52 SECONDS
	song_beat_deciseconds = 1 SECONDS
