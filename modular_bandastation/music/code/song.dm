#define GROUP_PERFORMANCE_RADIUS 5
#define GROUP_PERFORMANCE_TIMEOUT (30 SECONDS)

#define GROUP_PERFORMANCE_PENDING "pending"
#define GROUP_PERFORMANCE_ACCEPTED "accepted"
#define GROUP_PERFORMANCE_READY "ready"
#define GROUP_PERFORMANCE_SKIPPED "skipped"

#define CYBERPUNK_MUSIC_PERK_PULSE_INTERVAL (1 SECONDS)
#define CYBERPUNK_MUSIC_EFFECT_DURATION (6 SECONDS)
#define CYBERPUNK_MUSIC_STYLE_ACTION "MUSIC"

/datum/song
	var/ignore_play_checks = FALSE
	var/datum/song/group_start_leader
	var/group_start_deadline = 0
	var/list/group_start_candidates
	var/atom/group_start_player
	var/last_cyberpunk_music_perk_pulse = 0
	var/group_generation = 0
	var/group_prepare_timer
	var/list/performance_members = list()
	var/list/performance_restore
	var/performance_cycle_length = 0
	var/mob/group_reserved_player
	var/datum/song/performance_leader

/datum/song/proc/start_without_prompt(atom/player)
	start_playing(player)

/datum/song/proc/find_group_player()
	var/atom/player = find_available_player()
	return ismob(player) ? player : null

/datum/song/handheld/find_group_player()
	if(!istype(parent, /obj/item/instrument))
		return null
	return find_available_player()

/datum/song/stationary/find_group_player()
	return find_available_player()

/datum/song/proc/get_nearby_group_candidates(atom/leader_player)
	var/list/candidates = list()
	var/turf/leader_turf = get_turf(leader_player || parent)
	if(!leader_turf)
		return candidates
	for(var/datum/song/S as anything in SSinstruments.songs)
		if(S == src || S.playing || S.group_start_leader || S.group_start_candidates || S.midi_start_timer)
			continue
		var/mob/candidate_player = S.find_group_player()
		if(!candidate_player || candidate_player.incapacitated || !candidate_player.client)
			continue
		var/turf/candidate_turf = get_turf(candidate_player)
		if(!candidate_turf || candidate_turf.z != leader_turf.z)
			continue
		if(get_dist(candidate_turf, leader_turf) > GROUP_PERFORMANCE_RADIUS)
			continue
		candidates[S] = candidate_player
		if(length(candidates) >= 15)
			break
	return candidates

/datum/song/proc/try_start_group_performance(mob/user)
	if(playing)
		stop_playing()
		return TRUE
	if(cancel_delayed_midi_start())
		return TRUE
	if(group_start_leader && group_start_leader != src)
		prepare_group_performance(user)
		return TRUE
	if(group_start_candidates)
		cancel_performance_prepare()
		return TRUE
	if(!istype(user))
		start_without_prompt(user)
		return TRUE
	var/list/candidates = get_nearby_group_candidates(user)
	if(!length(candidates))
		start_without_prompt(user)
		return TRUE
	group_start_candidates = list()
	group_start_deadline = world.time + GROUP_PERFORMANCE_TIMEOUT
	group_start_player = user
	group_reserved_player = user
	var/generation = ++group_generation
	for(var/datum/song/candidate as anything in candidates)
		group_start_candidates[candidate] = GROUP_PERFORMANCE_PENDING
		candidate.group_start_leader = src
		candidate.group_start_deadline = group_start_deadline
		candidate.group_reserved_player = candidates[candidate]
		INVOKE_ASYNC(src, PROC_REF(prompt_group_candidate), candidate, candidates[candidate], generation)
	to_chat(user, span_notice("You invite nearby musicians to join. Performance starts when they prepare or after [DisplayTimeText(GROUP_PERFORMANCE_TIMEOUT)]."))
	group_prepare_timer = addtimer(CALLBACK(src, PROC_REF(finalize_group_performance), generation), GROUP_PERFORMANCE_TIMEOUT, TIMER_STOPPABLE)
	return TRUE

/datum/song/proc/prompt_group_candidate(datum/song/candidate, mob/player, generation)
	if(!istype(candidate) || !istype(player))
		return
	var/mob/leader = group_start_player
	var/answer = tgui_alert(player, "[leader ? leader : parent] is starting a group performance. Join?", "Group Performance", list("Yes", "No"))
	if(QDELETED(candidate) || generation != group_generation || !group_start_candidates || world.time > group_start_deadline || !(candidate in group_start_candidates) || candidate.group_start_leader != src)
		return
	if(answer != "Yes")
		group_start_candidates[candidate] = GROUP_PERFORMANCE_SKIPPED
		candidate.clear_group_prepare()
		check_group_performance_ready()
		return
	group_start_candidates[candidate] = GROUP_PERFORMANCE_ACCEPTED
	candidate.group_start_leader = src
	candidate.group_start_deadline = group_start_deadline
	to_chat(player, span_notice("Choose your track and press Prepare within [DisplayTimeText(max(0, group_start_deadline - world.time))]."))
	candidate.ui_interact(player)
	candidate.update_static_data_for_all_viewers()
	check_group_performance_ready()

/datum/song/proc/prepare_group_performance(mob/user)
	if(!group_start_leader || world.time > group_start_deadline)
		clear_group_prepare()
		return FALSE
	var/datum/song/leader = group_start_leader
	if(find_group_player() != user || !valid_group_member(leader))
		return FALSE
	if(leader.playback_mode == "file" && playback_mode != "file")
		to_chat(user, span_warning("Select an OGG track before preparing this performance."))
		return FALSE
	if(!leader.group_start_candidates || !(src in leader.group_start_candidates))
		clear_group_prepare()
		return FALSE
	leader.group_start_candidates[src] = GROUP_PERFORMANCE_READY
	to_chat(user, span_notice("You are ready for the group performance."))
	leader.check_group_performance_ready()
	return TRUE

/datum/song/proc/check_group_performance_ready()
	if(!group_start_candidates)
		return FALSE
	for(var/datum/song/candidate as anything in group_start_candidates)
		var/status = group_start_candidates[candidate]
		if(status == GROUP_PERFORMANCE_PENDING || status == GROUP_PERFORMANCE_ACCEPTED)
			return FALSE
	finalize_group_performance()
	return TRUE

/datum/song/proc/finalize_group_performance(generation)
	if(!group_start_candidates || (!isnull(generation) && generation != group_generation))
		return
	if(group_prepare_timer)
		deltimer(group_prepare_timer)
		group_prepare_timer = null
	var/list/ready_songs = list(src)
	for(var/datum/song/candidate as anything in group_start_candidates)
		if(!QDELETED(candidate) && group_start_candidates[candidate] == GROUP_PERFORMANCE_READY && candidate.valid_group_member(src))
			ready_songs += candidate
		if(!QDELETED(candidate))
			candidate.clear_group_prepare(candidate in ready_songs)
	group_start_candidates = null
	group_start_deadline = 0
	group_start_player = null
	var/generation_token = ++group_generation
	for(var/datum/song/S as anything in ready_songs)
		S.group_start_leader = src
		S.group_start_deadline = world.time + 2 SECONDS
		if(S.playback_mode == "file" && S.file_track)
			for(var/mob/listener in get_hearers_in_view(S.instrument_range, get_turf(S.parent)))
				listener << browse_rsc(S.file_track)
	group_prepare_timer = addtimer(CALLBACK(src, PROC_REF(start_prepared_group), ready_songs, generation_token), 2 SECONDS, TIMER_STOPPABLE)
	group_start_candidates = list()
	for(var/datum/song/S as anything in ready_songs)
		if(S != src)
			group_start_candidates[S] = GROUP_PERFORMANCE_READY

/datum/song/proc/valid_group_member(datum/song/leader)
	var/mob/player = find_group_player()
	var/turf/here = get_turf(parent)
	var/turf/there = get_turf(leader?.parent)
	return player?.client && (!group_reserved_player || player == group_reserved_player) && !player.incapacitated && here && there && here.z == there.z && get_dist(here, there) <= GROUP_PERFORMANCE_RADIUS

/datum/song/proc/start_prepared_group(list/songs, generation)
	group_prepare_timer = null
	if(generation != group_generation || !valid_group_member(src))
		cancel_performance_prepare()
		return
	group_start_candidates = null
	clear_group_prepare()
	var/list/started = list()
	var/cycle_length = playback_mode == "file" ? file_track_length : sequence_length SECONDS
	for(var/datum/song/member as anything in songs)
		if(!QDELETED(member) && member.playback_mode == "file")
			cycle_length = max(cycle_length, member.file_track_length)
	for(var/datum/song/member as anything in songs)
		if(QDELETED(member) || !member.valid_group_member(src))
			continue
		if(member != src && member.group_start_leader != src)
			continue
		member.clear_group_prepare()
		if(member != src)
			member.performance_restore = list("mode" = member.playback_mode, "lines" = member.lines, "bpm" = member.bpm, "channels" = member.midi_channels.Copy(), "repeat" = member.repeat, "loop" = member.auto_repeat, "file" = member.file_track, "name" = member.file_track_name, "length" = member.file_track_length, "hash" = member.file_track_hash, "cues" = member.song_cues)
			member.repeat = repeat
			member.performance_restore["spacing"] = member.cue_spacing
			member.auto_repeat = auto_repeat
			if(group_mode == "unison" && playback_mode == "midi")
				member.set_playback_mode("midi")
				member.lines = lines.Copy()
				member.set_bpm(bpm)
			if(group_mode == "unison" && playback_mode == "file")
				member.set_playback_mode("file")
				member.file_track = file_track
				member.file_track_name = file_track_name
				member.file_track_length = file_track_length
				member.file_track_hash = file_track_hash
				member.song_cues = song_cues
				member.cue_spacing = cue_spacing
		member.performance_cycle_length = cycle_length
		if(playback_mode == "sequence" && member != src)
			member.set_playback_mode("sequence")
			member.sequence_master = src
			if(group_mode == "unison")
				member.midi_channels = midi_channels.Copy()
		member.ignore_midi_start_delay = TRUE
		member.start_without_prompt(member.find_group_player())
		if(member.playing)
			started += member
			member.update_static_data_for_all_viewers()
		else
			member.finish_performance()
	for(var/datum/song/member as anything in started)
		if(member != src)
			performance_members |= member
			member.performance_leader = src
		if(member != src && member.sequence_master == src)
			sequence_followers |= member

/datum/song/proc/finish_performance()
	sequence_master = null
	if(performance_leader && !QDELETED(performance_leader))
		performance_leader.performance_members -= src
		performance_leader.sequence_followers -= src
	performance_leader = null
	for(var/datum/song/member as anything in performance_members.Copy())
		if(!QDELETED(member))
			member.stop_playing()
	performance_members.Cut()
	performance_cycle_length = 0
	if(!performance_restore)
		return
	playback_mode = performance_restore["mode"]
	lines = performance_restore["lines"]
	set_bpm(performance_restore["bpm"])
	midi_channels = performance_restore["channels"]
	repeat = performance_restore["repeat"]
	auto_repeat = performance_restore["loop"]
	file_track = performance_restore["file"]
	file_track_name = performance_restore["name"]
	file_track_length = performance_restore["length"]
	file_track_hash = performance_restore["hash"]
	song_cues = performance_restore["cues"]
	cue_spacing = performance_restore["spacing"] || 5
	performance_restore = null
	update_static_data_for_all_viewers()

/datum/song/proc/cancel_performance_prepare()
	group_generation++
	if(group_prepare_timer)
		deltimer(group_prepare_timer)
		group_prepare_timer = null
	if(group_start_candidates)
		for(var/datum/song/member as anything in group_start_candidates)
			if(!QDELETED(member) && member.group_start_leader == src)
				member.clear_group_prepare()
		group_start_candidates = null
	if(group_start_leader && group_start_leader != src && !QDELETED(group_start_leader))
		if(group_start_leader.group_start_candidates)
			group_start_leader.group_start_candidates[src] = GROUP_PERFORMANCE_SKIPPED
	group_start_player = null
	clear_group_prepare()

/datum/song/proc/clear_group_prepare(preserve_player = FALSE)
	group_start_leader = null
	group_start_deadline = 0
	if(!preserve_player)
		group_reserved_player = null

/datum/song/proc/pulse_cyberpunk_music_perks(atom/player)
	if(world.time < last_cyberpunk_music_perk_pulse + CYBERPUNK_MUSIC_PERK_PULSE_INTERVAL)
		return FALSE
	last_cyberpunk_music_perk_pulse = world.time
	if(!isliving(player) || !length(hearing_mobs))
		return FALSE
	var/mob/living/performer = player
	var/mood_bonus = performer.get_cyberpunk_skill_perk_bonus(SKILL_MUSIC, 1)
	var/cohort_buff_level = performer.get_cyberpunk_skill_perk_bonus(SKILL_MUSIC, 2)
	var/outsider_debuff_level = performer.get_cyberpunk_skill_perk_bonus(SKILL_MUSIC, 4)
	var/style_bonus = performer.get_cyberpunk_skill_perk_bonus(SKILL_MUSIC, 5)
	var/has_music_effect = mood_bonus || cohort_buff_level || outsider_debuff_level || style_bonus || HAS_TRAIT(performer, TRAIT_MUSICIAN)
	if(!has_music_effect)
		return FALSE
	for(var/listener_ref in hearing_mobs)
		if(!isliving(listener_ref))
			continue
		var/mob/living/listener = listener_ref
		if(HAS_TRAIT(listener, TRAIT_DEAF))
			continue
		listener.apply_status_effect(/datum/status_effect/good_music)
		if(mood_bonus)
			listener.add_mood_event("cyberpunk_music", /datum/mood_event/cyberpunk_music, mood_bonus)
		var/same_cohort = performer.is_cyberpunk_music_cohort_listener(listener)
		if(cohort_buff_level && same_cohort)
			listener.apply_cyberpunk_status_effect(/datum/cyberpunk_status_effect/music_cohort, CYBERPUNK_MUSIC_EFFECT_DURATION, cohort_buff_level, performer, FALSE)
		if(outsider_debuff_level && !same_cohort)
			listener.apply_cyberpunk_status_effect(/datum/cyberpunk_status_effect/music_discord, CYBERPUNK_MUSIC_EFFECT_DURATION, outsider_debuff_level, performer, FALSE)
		if(style_bonus)
			listener.apply_cyberpunk_music_style(style_bonus)
	return TRUE

/mob/living/proc/is_cyberpunk_music_cohort_listener(mob/living/listener)
	return listener == src || (cyberpunk_cohort && listener?.cyberpunk_cohort == cyberpunk_cohort)

/mob/living/proc/apply_cyberpunk_music_style(style_bonus)
	var/datum/component/style/style_component = GetComponent(/datum/component/style)
	if(!style_component)
		return FALSE
	style_component.add_action(CYBERPUNK_MUSIC_STYLE_ACTION, max(1, style_bonus))
	return TRUE

/datum/song/handheld/should_stop_playing(atom/player)
	if(ignore_play_checks)
		return NONE

	. = ..()

	if(. == STOP_PLAYING || . == IGNORE_INSTRUMENT_CHECKS)
		return

	var/obj/item/instrument/I = parent
	return I.can_play(player) ? NONE : STOP_PLAYING

/datum/song/stationary/should_stop_playing(atom/player)
	if(ignore_play_checks)
		return NONE

	. = ..()

	if(. == STOP_PLAYING || . == IGNORE_INSTRUMENT_CHECKS)
		return TRUE

	var/obj/structure/musician/M = parent
	return M.can_play(player) ? NONE : STOP_PLAYING

/datum/song/ui_data(mob/user)
	var/list/data = ..()
	data["group_prepare_pending"] = !!group_start_leader && world.time <= group_start_deadline
	data["group_prepare_seconds"] = data["group_prepare_pending"] ? max(0, round((group_start_deadline - world.time) / (1 SECONDS))) : 0
	return music_ui_data(data)

/datum/song/ui_act(action, list/params)
	if(handle_music_action(action, params, usr))
		return TRUE
	if(action in list("play_music", "start_solo", "select_music_mode"))
		return TRUE

	return ..()

#undef GROUP_PERFORMANCE_RADIUS
#undef GROUP_PERFORMANCE_TIMEOUT
#undef GROUP_PERFORMANCE_PENDING
#undef GROUP_PERFORMANCE_ACCEPTED
#undef GROUP_PERFORMANCE_READY
#undef GROUP_PERFORMANCE_SKIPPED
#undef CYBERPUNK_MUSIC_PERK_PULSE_INTERVAL
#undef CYBERPUNK_MUSIC_EFFECT_DURATION
#undef CYBERPUNK_MUSIC_STYLE_ACTION

/datum/song/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "InstrumentEditor220", parent.name) // BANDASTATION EDIT - New Instrument Synchronisation
		ui.open()
