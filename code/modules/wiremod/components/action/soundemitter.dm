/**
 * # Sound Emitter Component
 *
 * A component that emits a sound when it receives an input.
 */
/obj/item/circuit_component/soundemitter
	display_name = "Sound Emitter"
	desc = "A component that emits a sound when it receives an input. The frequency is a multiplier which determines the speed at which the sound is played"
	category = "Action"
	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL|CIRCUIT_FLAG_OUTPUT_SIGNAL

	/// Sound to play
	var/datum/port/input/option/sound_file

	/// Volume of the sound when played
	var/datum/port/input/volume

	/// Whether to play the sound backwards
	var/datum/port/input/backwards

	/// Frequency of the sound when played
	var/datum/port/input/frequency

	/// The cooldown for this component of how often it can play sounds.
	var/sound_cooldown = 2 SECONDS

	/// The maximum pitch this component can play sounds at.
	var/max_pitch = 50
	/// The minimum pitch this component can play sounds at.
	var/min_pitch = -50
	/// The maximum volume this component can play sounds at.
	var/max_volume = 30

	var/list/options_map

/obj/item/circuit_component/soundemitter/Initialize(mapload)
	if(CONFIG_GET(flag/disallow_circuit_sounds))
		update_ui_alerts(new_flag=CIRCUIT_FLAG_DISABLED)
	. = ..()

/obj/item/circuit_component/soundemitter/get_ui_notices()
	. = ..()
	. += create_ui_notice("Sound Cooldown: [DisplayTimeText(sound_cooldown)]", "orange", "stopwatch")
	if(CONFIG_GET(flag/disallow_circuit_sounds))
		. += create_ui_notice("Non-functional", "red", "exclamation")
		update_ui_alerts(new_flag=CIRCUIT_FLAG_DISABLED)
	else
		update_ui_alerts(remove_flag=CIRCUIT_FLAG_DISABLED)


/obj/item/circuit_component/soundemitter/populate_ports()
	volume = add_input_port("Volume", PORT_TYPE_NUMBER, default = 35)
	frequency = add_input_port("Frequency", PORT_TYPE_NUMBER, default = 0)
	backwards = add_input_port("Play Backwards", PORT_TYPE_BOOLEAN, default = FALSE)

/obj/item/circuit_component/soundemitter/populate_options()
	var/static/component_options = list(
		"Buzz" = 'sound/machines/buzz/buzz-sigh.ogg',
		"Buzz Twice" = 'sound/machines/buzz/buzz-two.ogg',
		"Chime" = 'sound/machines/chime.ogg',
		"Honk" = 'sound/items/bikehorn.ogg',
		"Ping" = 'sound/machines/ping.ogg',
		"Sad Trombone" = 'sound/misc/sadtrombone.ogg',
		"Warn" = 'sound/machines/warning-buzzer.ogg',
		"Slow Clap" = 'sound/machines/slowclap.ogg',
		"Moth Buzz" = 'sound/mobs/humanoids/moth/scream_moth.ogg',
		"Squeak" = 'sound/items/toy_squeak/toysqueak1.ogg',
		"Rip" = 'sound/items/poster/poster_ripped.ogg',
		"Coinflip" = 'sound/items/coinflip.ogg',
		"Megaphone" = 'sound/items/megaphone.ogg',
		"Warpwhistle" = 'sound/effects/magic/warpwhistle.ogg',
		"Hiss" = 'sound/mobs/non-humanoids/hiss/hiss1.ogg',
		"Lizard" = 'sound/mobs/humanoids/lizard/lizard_scream_1.ogg',
		"Flashbang" = 'sound/items/weapons/flashbang.ogg',
		"Flash" = 'sound/items/weapons/flash.ogg',
		"Whip" = 'sound/items/weapons/whip.ogg',
		"Laugh Track" = 'sound/items/sitcom_laugh/sitcomLaugh1.ogg',
		"Gavel" = 'sound/items/gavel.ogg',
	)
	sound_file = add_option_port("Sound Option", component_options)
	options_map = component_options

/obj/item/circuit_component/soundemitter/pre_input_received(datum/port/input/port)
	volume.set_value(clamp(volume.value, 0, 100))
	frequency.set_value(clamp(frequency.value, min_pitch, max_pitch))
	backwards.set_value(clamp(backwards.value, 0, 1))

/obj/item/circuit_component/soundemitter/input_received(datum/port/input/port)
	if(CONFIG_GET(flag/disallow_circuit_sounds))
		// Without constantly checking the config 24/7 or sending a signal to every circuit, best we can do to update existing emitters is this.
		update_ui_alerts(new_flag=CIRCUIT_FLAG_DISABLED)
		return
	else
		update_ui_alerts(remove_flag=CIRCUIT_FLAG_DISABLED)

	if(!parent.shell)
		return

	if(TIMER_COOLDOWN_RUNNING(parent.shell, COOLDOWN_CIRCUIT_SOUNDEMITTER))
		return

	var/sound_to_play = options_map[sound_file.value]
	if(!sound_to_play)
		return

	var/actual_frequency = 1 + (frequency.value/100)
	var/actual_volume = max_volume * (volume.value/100)

	if(backwards.value)
		actual_frequency = -actual_frequency

	playsound(src, sound_to_play, actual_volume, TRUE, frequency = actual_frequency)

	TIMER_COOLDOWN_START(parent.shell, COOLDOWN_CIRCUIT_SOUNDEMITTER, sound_cooldown)

/**
 * # Concert Speaker Receiver Component
 *
 * Turns the current integrated-circuit shell into a positional jukebox emitter.
 */
/obj/item/circuit_component/concert_listener
	display_name = "Concert Speaker Receiver"
	desc = "Links the circuit shell as an additional music source for a jukebox."
	category = "Action"
	required_shells = list(/obj/structure/concertspeaker)
	circuit_size = 2

	/// Jukebox to relay.
	var/datum/port/input/jukebox_target
	/// Connect this shell to the jukebox in Target Jukebox.
	var/datum/port/input/link_input
	/// Disconnect this shell from its current jukebox.
	var/datum/port/input/unlink_input
	/// Whether the linked jukebox is currently playing.
	var/datum/port/output/is_playing
	/// Fired when the linked jukebox starts.
	var/datum/port/output/started_playing
	/// Fired when the linked jukebox stops.
	var/datum/port/output/stopped_playing

	/// Currently linked jukebox.
	var/obj/machinery/jukebox/linked_jukebox
	/// Whether this receiver currently exposes its shell as an active speaker.
	var/playing = FALSE

/obj/item/circuit_component/concert_listener/populate_ports()
	jukebox_target = add_input_port("Target Jukebox", PORT_TYPE_ATOM, order = 1)
	link_input = add_input_port("Link", PORT_TYPE_SIGNAL, order = 2, trigger = PROC_REF(link_to_target))
	unlink_input = add_input_port("Unlink", PORT_TYPE_SIGNAL, order = 3, trigger = PROC_REF(unlink))
	is_playing = add_output_port("Is Playing", PORT_TYPE_BOOLEAN)
	started_playing = add_output_port("Started Playing", PORT_TYPE_SIGNAL)
	stopped_playing = add_output_port("Stopped Playing", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/concert_listener/get_ui_notices()
	. = ..()
	if(linked_jukebox)
		. += create_ui_notice("Linked to: [linked_jukebox.name]", "green", "music")
	else
		. += create_ui_notice("No jukebox linked.", "orange", "music")

/obj/item/circuit_component/concert_listener/register_shell(atom/movable/shell)
	. = ..()
	if(!linked_jukebox)
		return
	linked_jukebox.music_player?.register_music_source(shell)
	if(linked_jukebox.music_player?.active_song_sound)
		play_track()

/obj/item/circuit_component/concert_listener/unregister_shell(atom/movable/shell)
	if(linked_jukebox)
		linked_jukebox.music_player?.unregister_music_source(shell)
	stop_playback()
	return ..()

/obj/item/circuit_component/concert_listener/Destroy()
	unlink()
	return ..()

/obj/item/circuit_component/concert_listener/proc/link_to_target()
	var/obj/machinery/jukebox/target_jukebox = jukebox_target.value
	if(!istype(target_jukebox) || QDELETED(target_jukebox) || !target_jukebox.music_player)
		return
	link_jukebox(target_jukebox)

/obj/item/circuit_component/concert_listener/proc/link_jukebox(obj/machinery/jukebox/new_jukebox)
	if(linked_jukebox == new_jukebox)
		return
	unlink()
	linked_jukebox = new_jukebox
	RegisterSignal(linked_jukebox, COMSIG_INSTRUMENT_START, PROC_REF(on_song_start))
	RegisterSignal(linked_jukebox, COMSIG_INSTRUMENT_END, PROC_REF(on_song_end))
	RegisterSignal(linked_jukebox, COMSIG_QDELETING, PROC_REF(on_jukebox_deleted))
	if(parent?.shell)
		linked_jukebox.music_player?.register_music_source(parent.shell)
	update_parent()
	if(linked_jukebox.music_player?.active_song_sound)
		play_track()
	if(parent)
		SStgui.update_uis(parent)

/obj/item/circuit_component/concert_listener/proc/unlink()
	if(!linked_jukebox)
		return
	if(parent?.shell)
		linked_jukebox.music_player?.unregister_music_source(parent.shell)
	UnregisterSignal(linked_jukebox, list(COMSIG_INSTRUMENT_START, COMSIG_INSTRUMENT_END, COMSIG_QDELETING))
	linked_jukebox = null
	stop_playback()
	update_parent(TRUE)
	if(parent)
		SStgui.update_uis(parent)

/obj/item/circuit_component/concert_listener/proc/play_track()
	if(playing)
		return
	playing = TRUE
	is_playing.set_output(TRUE)
	started_playing.set_output(COMPONENT_SIGNAL)
	update_parent()

/obj/item/circuit_component/concert_listener/proc/stop_playback()
	if(!playing)
		return
	playing = FALSE
	is_playing.set_output(FALSE)
	stopped_playing.set_output(COMPONENT_SIGNAL)
	update_parent()

/obj/item/circuit_component/concert_listener/proc/update_parent(unreg = FALSE)
	var/atom/movable/shell = parent?.shell
	var/obj/structure/concertspeaker/speaker = shell
	if(!istype(speaker))
		return
	speaker.set_concert_state(playing && speaker.anchored, !unreg && !isnull(linked_jukebox))

/obj/item/circuit_component/concert_listener/proc/on_song_start(datum/source, datum/track/starting_song)
	SIGNAL_HANDLER
	play_track()

/obj/item/circuit_component/concert_listener/proc/on_song_end()
	SIGNAL_HANDLER
	stop_playback()

/obj/item/circuit_component/concert_listener/proc/on_jukebox_deleted()
	SIGNAL_HANDLER
	unlink()

/obj/item/circuit_component/concert_master
	display_name = "Concert Master"
	desc = "Controls a concert DJ deck and relays track state to linked speaker receivers."
	category = "Action"
	required_shells = list(/obj/machinery/jukebox/concertspeaker)
	circuit_size = 2

	var/datum/port/output/track_name_out
	var/datum/port/output/is_playing
	var/datum/port/output/started_playing
	var/datum/port/output/stopped_playing

	/// Concert deck hosting this component.
	var/obj/machinery/jukebox/concertspeaker/linked_jukebox
	/// Remote used to link listener components into speaker circuits.
	var/obj/item/concert_remote/remote

/obj/item/circuit_component/concert_master/Initialize(mapload)
	. = ..()
	if(!remote)
		remote = new(src)

/obj/item/circuit_component/concert_master/populate_ports()
	track_name_out = add_output_port("Track Name", PORT_TYPE_STRING)
	is_playing = add_output_port("Is Playing", PORT_TYPE_BOOLEAN)
	started_playing = add_output_port("Started Playing", PORT_TYPE_SIGNAL)
	stopped_playing = add_output_port("Stopped Playing", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/concert_master/Destroy()
	QDEL_NULL(remote)
	return ..()

/obj/item/circuit_component/concert_master/attack_self(mob/user, modifiers)
	if(!remote || remote.loc != src)
		to_chat(user, span_warning("The link remote is already removed."))
		return
	if(!user.put_in_active_hand(remote))
		remote.forceMove(drop_location())
	to_chat(user, span_notice("You remove the concert link remote."))

/obj/item/circuit_component/concert_master/attackby(obj/item/tool, mob/user, params)
	if(istype(tool, /obj/item/concert_remote))
		if(tool != remote)
			to_chat(user, span_warning("This remote is paired with another concert master."))
			return TRUE
		tool.forceMove(src)
		to_chat(user, span_notice("You insert the concert link remote."))
		return TRUE
	return ..()

/obj/item/circuit_component/concert_master/register_shell(atom/movable/shell)
	. = ..()
	var/obj/machinery/jukebox/concertspeaker/concert_deck = shell
	if(!istype(concert_deck))
		return
	linked_jukebox = concert_deck
	linked_jukebox.master_component = src
	linked_jukebox.remote_installed = TRUE
	RegisterSignal(linked_jukebox, COMSIG_INSTRUMENT_START, PROC_REF(on_song_start))
	RegisterSignal(linked_jukebox, COMSIG_INSTRUMENT_END, PROC_REF(on_song_end))
	if(linked_jukebox.music_player?.active_song_sound)
		on_song_start(linked_jukebox, linked_jukebox.music_player.selection)

/obj/item/circuit_component/concert_master/unregister_shell(atom/movable/shell)
	if(linked_jukebox)
		UnregisterSignal(linked_jukebox, list(COMSIG_INSTRUMENT_START, COMSIG_INSTRUMENT_END))
		linked_jukebox.master_component = null
		linked_jukebox.remote_installed = FALSE
		on_song_end()
	linked_jukebox = null
	return ..()

/obj/item/circuit_component/concert_master/proc/on_song_start(datum/source, datum/track/starting_song)
	SIGNAL_HANDLER
	if(!starting_song || !remote)
		return
	track_name_out.set_output(starting_song.song_name)
	is_playing.set_output(TRUE)
	started_playing.set_output(COMPONENT_SIGNAL)
	for(var/obj/item/circuit_component/concert_listener/listener as anything in remote.takers)
		if(QDELETED(listener))
			continue
		listener.link_jukebox(linked_jukebox)
		listener.play_track()

/obj/item/circuit_component/concert_master/proc/on_song_end()
	SIGNAL_HANDLER
	track_name_out.set_output("")
	is_playing.set_output(FALSE)
	stopped_playing.set_output(COMPONENT_SIGNAL)
	if(!remote)
		return
	for(var/obj/item/circuit_component/concert_listener/listener as anything in remote.takers)
		if(QDELETED(listener))
			continue
		listener.stop_playback()

/obj/item/concert_remote
	name = "concert link remote"
	desc = "A paired remote that installs or removes speaker receiver components in integrated circuits."
	icon = 'icons/obj/devices/remote.dmi'
	icon_state = "shuttleremote"
	w_class = WEIGHT_CLASS_SMALL
	/// Linked speaker receiver components.
	var/list/obj/item/circuit_component/concert_listener/takers

/obj/item/concert_remote/Initialize(mapload)
	. = ..()
	takers = list()

/obj/item/concert_remote/Destroy()
	for(var/obj/item/circuit_component/concert_listener/listener as anything in takers)
		remove_taker(listener)
	takers = null
	return ..()

/obj/item/concert_remote/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!target)
		return
	try_toggle_on(target, user)

/obj/item/concert_remote/proc/add_taker(obj/item/circuit_component/concert_listener/listener)
	if(!listener || takers[listener])
		return
	takers[listener] = TRUE
	RegisterSignal(listener, COMSIG_CIRCUIT_COMPONENT_REMOVED, PROC_REF(on_component_removed))
	RegisterSignal(listener, COMSIG_QDELETING, PROC_REF(on_component_deleted))

/obj/item/concert_remote/proc/remove_taker(obj/item/circuit_component/concert_listener/listener)
	if(!listener || !takers[listener])
		return
	takers -= listener
	UnregisterSignal(listener, list(COMSIG_CIRCUIT_COMPONENT_REMOVED, COMSIG_QDELETING))
	listener.unlink()

/obj/item/concert_remote/proc/on_component_removed(datum/source, obj/item/integrated_circuit/old_circuit)
	SIGNAL_HANDLER
	remove_taker(source)

/obj/item/concert_remote/proc/on_component_deleted(datum/source)
	SIGNAL_HANDLER
	remove_taker(source)

/obj/item/concert_remote/proc/find_linked_listener_in_circuit(obj/item/integrated_circuit/circuit)
	if(!circuit)
		return null
	for(var/obj/item/circuit_component/concert_listener/listener in circuit.attached_components)
		return listener
	return null

/obj/item/concert_remote/proc/try_toggle_on(atom/target, mob/user)
	var/obj/item/integrated_circuit/circuit = find_circuit(target)
	if(!circuit)
		to_chat(user, span_warning("There is no integrated circuit here."))
		return
	var/obj/item/circuit_component/concert_listener/existing = find_linked_listener_in_circuit(circuit)
	if(existing)
		circuit.remove_component(existing)
		remove_taker(existing)
		qdel(existing)
		to_chat(user, span_notice("Speaker unlinked. Total linked: [length(takers)]."))
		return
	if(length(takers) >= 16)
		to_chat(user, span_warning("The remote cannot link more speakers."))
		return
	var/obj/item/circuit_component/concert_listener/listener = new()
	if(!circuit.add_component(listener))
		qdel(listener)
		to_chat(user, span_warning("The receiver does not fit into this circuit."))
		return
	add_taker(listener)
	to_chat(user, span_notice("Speaker linked. Total linked: [length(takers)]."))

/obj/item/concert_remote/proc/find_circuit(atom/target)
	var/obj/item/integrated_circuit/circuit = target
	if(istype(circuit))
		return circuit
	var/datum/component/shell/shell = target.GetComponent(/datum/component/shell)
	if(shell?.attached_circuit)
		return shell.attached_circuit
	for(var/obj/item/integrated_circuit/contained_circuit in target.contents)
		return contained_circuit
	return null
