// Cyberpunk proc replacements. These intentionally shadow upstream core procs
// so the core files can stay close to upstream during merges.

/obj/machinery/deepfryer
	/// Last living user who placed the current item. Used by CP13 cooking skill hooks.
	var/tmp/mob/living/cyberpunk_fryer_user

/obj/machinery/deepfryer/process(seconds_per_tick)
	var/cyberpunk_time_multiplier = cyberpunk_fryer_user?.get_cyberpunk_cooking_machine_time_multiplier() || 1
	if(cyberpunk_time_multiplier == 1)
		return ..()

	var/old_fry_speed = fry_speed
	var/old_oil_use = oil_use
	fry_speed = old_fry_speed / cyberpunk_time_multiplier
	oil_use = old_oil_use * cyberpunk_time_multiplier
	. = ..()
	fry_speed = old_fry_speed
	oil_use = old_oil_use

/obj/machinery/deepfryer/reset_frying()
	. = ..()
	cyberpunk_fryer_user = null

/obj/machinery/deepfryer/start_fry(obj/item/frying_item, mob/user)
	. = ..()
	cyberpunk_fryer_user = isliving(user) ? user : null
	if(!frying || !cyberpunk_fryer_user)
		return
	var/quality_bonus = cyberpunk_fryer_user.get_cyberpunk_cooking_quality_bonus()
	if(quality_bonus > 0)
		frying.AddElement(/datum/element/quality_food_ingredient, quality_bonus)

/datum/song/playkey_legacy(note, acc as text, oct, atom/player)
	// handle accidental -> B<>C of E<>F
	if(acc == "b" && (note == 3 || note == 6)) // C or F
		if(note == 3)
			oct--
		note--
		acc = "n"
	else if(acc == "#" && (note == 2 || note == 5)) // B or E
		if(note == 2)
			oct++
		note++
		acc = "n"
	else if(acc == "#" && (note == 7)) //G#
		note = 1
		acc = "b"
	else if(acc == "#") // mass convert all sharps to flats, octave jump already handled
		acc = "b"
		note++

	// check octave, C is allowed to go to 9
	if(oct < 1 || (note == 3 ? oct > 9 : oct > 8))
		return

	// now generate name
	var/soundfile = "sound/runtime/instruments/[cached_legacy_dir]/[ascii2text(note+64)][acc][oct].[cached_legacy_ext]"
	soundfile = file(soundfile)
	// make sure the note exists
	if(!fexists(soundfile))
		return
	// and play
	var/turf/source = get_turf(parent)
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
		do_hearcheck()
	var/sound/music_played = sound(soundfile)
	pulse_cyberpunk_music_perks(player)
	for(var/i in hearing_mobs)
		var/mob/M = i
		var/listener_volume = get_listener_volume_multiplier(M)
		if(!listener_volume)
			continue
		M.playsound_local(source, null, get_output_volume(volume * using_instrument.volume_multiplier) * listener_volume, sound_to_use = music_played, pressure_affected = FALSE, max_distance = instrument_range, falloff_distance = get_sound_falloff_distance(), falloff_exponent = INSTRUMENT_FALLOFF_EXPONENT)
		// Could do environment and echo later but not for now

/datum/song/playkey_synth(key, atom/player)
	key = clamp(key + note_shift, key_min, key_max)
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
		do_hearcheck()
	pulse_cyberpunk_music_perks(player)
	var/datum/instrument_key/K = using_instrument.samples[num2text(key)] //See how easy it is to make a number text?
	var/channel = pop_channel()
	if(isnull(channel))
		return FALSE
	. = TRUE
	var/sound/copy = sound(K.sample)
	var/volume = get_output_volume(src.volume * using_instrument.volume_multiplier)
	copy.frequency = K.frequency
	copy.volume = volume
	var/channel_text = num2text(channel)
	channels_playing[channel_text] = 100
	last_channel_played = channel_text
	for(var/i in hearing_mobs)
		var/mob/M = i
		var/listener_volume = get_listener_volume_multiplier(M)
		if(!listener_volume)
			continue
		M.playsound_local(get_turf(parent), null, volume * listener_volume, FALSE, K.frequency, INSTRUMENT_FALLOFF_EXPONENT, channel, FALSE, copy, instrument_range, get_sound_falloff_distance())
		// Could do environment and echo later but not for now

/datum/song/process_decay(wait_ds)
	var/linear_dropoff = cached_linear_dropoff * wait_ds
	var/exponential_dropoff = cached_exponential_dropoff ** wait_ds
	for(var/channel in channels_playing)
		if(full_sustain_held_note && (channel == last_channel_played))
			continue
		var/current_volume = channels_playing[channel]
		switch(sustain_mode)
			if(SUSTAIN_LINEAR)
				current_volume -= linear_dropoff
			if(SUSTAIN_EXPONENTIAL)
				current_volume /= exponential_dropoff
		channels_playing[channel] = current_volume
		var/dead = current_volume <= sustain_dropoff_volume
		var/channelnumber = text2num(channel)
		if(dead)
			channels_playing -= channel
			channels_idle += channel
			for(var/i in hearing_mobs)
				var/mob/M = i
				M.stop_sound_channel(channelnumber)
		else
			for(var/i in hearing_mobs)
				var/mob/M = i
				M.set_sound_channel_volume(channelnumber, (current_volume * 0.01) * get_output_volume(volume * using_instrument.volume_multiplier) * get_listener_volume_multiplier(M))

/datum/tgui_say/handle_entry(type, payload)
	if(!islist(payload))
		if(type != "save")
			return FALSE
		payload = list(
			"entry" = "",
			"channel" = saved_channel || SAY_CHANNEL,
		)

	var/entry = payload["entry"]
	var/channel = payload["channel"]
	if(!channel)
		if(type != "save")
			return FALSE
		channel = saved_channel || SAY_CHANNEL
	if(!istext(entry))
		entry = ""

	payload["entry"] = entry
	payload["channel"] = channel

	if(type == "entry" && !entry)
		return TRUE
	if(length(entry) > max_length)
		CRASH("[usr] has entered more characters than allowed into a TGUI-Say")
	if(type == "entry")
		delegate_speech(entry, channel)
		return TRUE
	if(type == "force")
		var/target_channel = channel
		if(target_channel == ME_CHANNEL || target_channel == OOC_CHANNEL || target_channel == PRAY_CHANNEL)
			target_channel = SAY_CHANNEL // No ooc leaks
		delegate_speech(alter_entry(payload), target_channel)
		return TRUE
	if(type == "save")
		saved_text = "" // so we can differentiate null (nothing saved) and empty (nothing typed)
		var/target_channel = channel
		if(target_channel == SAY_CHANNEL || target_channel == RADIO_CHANNEL)
			saved_text = entry // only save IC text
			saved_channel = target_channel
		return TRUE
	return FALSE

/datum/storage_interface/add_items(
	screen_start_x,
	screen_pixel_x,
	screen_start_y,
	screen_pixel_y,
	columns,
	rows,
	mob/user_looking,
	atom/real_location,
	list/datum/numbered_display/numbered_contents,
)

	var/current_x = screen_start_x
	var/current_y = screen_start_y
	var/turf/our_turf = get_turf(real_location)

	var/list/obj/storage_contents = list()
	if(islist(numbered_contents))
		for(var/content_type in numbered_contents)
			var/datum/numbered_display/numberdisplay = numbered_contents[content_type]
			storage_contents[numberdisplay.sample_object] = MAPTEXT("<font color='white'>[(numberdisplay.number > 1)? "[numberdisplay.number]" : ""]</font>")
	else
		for(var/obj/item as anything in real_location)
			storage_contents[item] = ""

	for(var/obj/item/stored_item as anything in storage_contents)
		stored_item.mouse_opacity = MOUSE_OPACITY_OPAQUE
		if(parent_storage.cyberpunk_grid_width && parent_storage.cyberpunk_grid_height && stored_item.cyberpunk_grid_x && stored_item.cyberpunk_grid_y)
			var/list/footprint = stored_item.get_cyberpunk_grid_footprint()
			stored_item.screen_loc = spanning_screen_loc(
				(screen_start_x + stored_item.cyberpunk_grid_x - 1) * 32 + screen_pixel_x,
				(screen_start_y + stored_item.cyberpunk_grid_y - 1) * 32 + screen_pixel_y,
				(screen_start_x + stored_item.cyberpunk_grid_x + footprint[1] - 2) * 32 + screen_pixel_x,
				(screen_start_y + stored_item.cyberpunk_grid_y + footprint[2] - 2) * 32 + screen_pixel_y,
			)
		else
			stored_item.screen_loc = "[current_x]:[screen_pixel_x],[current_y]:[screen_pixel_y]"
		if(parent_storage.numerical_stacking)
			stored_item.maptext = storage_contents[stored_item]
		SET_PLANE(stored_item, ABOVE_HUD_PLANE, our_turf)
		current_x++
		if(current_x - screen_start_x < columns)
			continue
		current_x = screen_start_x

		current_y++
		if(current_y - screen_start_y >= rows)
			break

/datum/storage_interface/silicon/add_items(
	screen_start_x,
	screen_pixel_x,
	screen_start_y,
	screen_pixel_y,
	columns,
	rows,
	mob/user_looking,
	atom/real_location,
	list/datum/numbered_display/numbered_contents,
)
	var/list/usable_modules = robot_model.get_usable_modules()

	var/current_x = screen_start_x
	var/current_y = screen_start_y
	var/turf/our_turf = get_turf(real_location)

	for(var/i in 1 to length(usable_modules))
		var/atom/movable/item = usable_modules[i]
		if(item in robot_model.robot.held_items)
			current_x++
			if(current_x - screen_start_x < columns)
				continue
			current_x = screen_start_x

			current_y++
			if(current_y - screen_start_y >= rows)
				break
			//Module is currently active
			continue

		item.mouse_opacity = MOUSE_OPACITY_OPAQUE
		SET_PLANE(item, ABOVE_HUD_PLANE, our_turf)
		item.screen_loc = "[current_x]:[screen_pixel_x],[current_y]:[screen_pixel_y]"

		current_x++
		if(current_x - screen_start_x < columns)
			continue
		current_x = screen_start_x
		current_y++
		if(current_y - screen_start_y >= rows)
			break
