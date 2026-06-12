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

/datum/song/proc/start_without_prompt(atom/player)
	start_playing(player)

/datum/song/proc/find_group_player()
	var/atom/player = find_available_player()
	return ismob(player) ? player : null

/datum/song/handheld/find_group_player()
	if(!istype(parent, /obj/item/instrument))
		return null
	var/obj/item/instrument/instrument = parent
	var/mob/living/player = instrument.loc
	if(!istype(player) || !(instrument in player.held_items))
		return null
	return instrument.can_play(player) ? player : null

/datum/song/stationary/find_group_player()
	return find_available_player()

/datum/song/proc/get_nearby_group_candidates(atom/leader_player)
	var/list/candidates = list()
	var/turf/leader_turf = get_turf(leader_player || parent)
	if(!leader_turf)
		return candidates
	for(var/datum/song/S as anything in SSinstruments.songs)
		if(S == src || S.playing || S.group_start_leader)
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
	return candidates

/datum/song/proc/try_start_group_performance(mob/user)
	if(playing)
		stop_playing()
		return TRUE
	if(cancel_delayed_midi_start())
		return TRUE
	if(group_start_leader)
		prepare_group_performance(user)
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
	for(var/datum/song/candidate as anything in candidates)
		group_start_candidates[candidate] = GROUP_PERFORMANCE_PENDING
		INVOKE_ASYNC(src, PROC_REF(prompt_group_candidate), candidate, candidates[candidate])
	to_chat(user, span_notice("You invite nearby musicians to join. Performance starts when they prepare or after [DisplayTimeText(GROUP_PERFORMANCE_TIMEOUT)]."))
	addtimer(CALLBACK(src, PROC_REF(finalize_group_performance)), GROUP_PERFORMANCE_TIMEOUT, TIMER_UNIQUE)
	return TRUE

/datum/song/proc/prompt_group_candidate(datum/song/candidate, mob/player)
	if(!istype(candidate) || !istype(player))
		return
	var/mob/leader = group_start_player
	var/answer = tgui_alert(player, "[leader ? leader : parent] is starting a group performance. Join?", "Group Performance", list("Yes", "No"))
	if(!group_start_candidates || world.time > group_start_deadline || !(candidate in group_start_candidates))
		return
	if(answer != "Yes")
		group_start_candidates[candidate] = GROUP_PERFORMANCE_SKIPPED
		check_group_performance_ready()
		return
	group_start_candidates[candidate] = GROUP_PERFORMANCE_ACCEPTED
	candidate.group_start_leader = src
	candidate.group_start_deadline = group_start_deadline
	to_chat(player, span_notice("Choose your track and press Prepare within [DisplayTimeText(max(0, group_start_deadline - world.time))]."))
	candidate.ui_interact(player)
	check_group_performance_ready()

/datum/song/proc/prepare_group_performance(mob/user)
	if(!group_start_leader || world.time > group_start_deadline)
		clear_group_prepare()
		return FALSE
	var/datum/song/leader = group_start_leader
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

/datum/song/proc/finalize_group_performance()
	if(!group_start_candidates)
		return
	var/list/ready_songs = list(src)
	for(var/datum/song/candidate as anything in group_start_candidates)
		if(group_start_candidates[candidate] == GROUP_PERFORMANCE_READY)
			ready_songs += candidate
		candidate.clear_group_prepare()
	group_start_candidates = null
	group_start_deadline = 0
	var/atom/player = group_start_player
	group_start_player = null
	for(var/datum/song/S as anything in ready_songs)
		var/atom/start_player = (S == src) ? player : S.find_group_player()
		S.start_without_prompt(start_player || S.parent)

/datum/song/proc/clear_group_prepare()
	group_start_leader = null
	group_start_deadline = 0

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
	return data

/datum/song/ui_act(action, list/params)
	switch(action)
		if("play_music")
			var/mob/user = usr
			if(!istype(user))
				return FALSE
			return try_start_group_performance(user)

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
