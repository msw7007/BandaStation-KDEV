// Cyberpunk 13 cyberspace: living mob session helpers.
// Split from cyberimp internals; keep cyberspace session state out of organ item definitions.

/mob/living
	var/datum/cyberspace_session/cyberspace_session
	var/tmp/cyberspace_transition_blocked_until = 0
	var/tmp/datum/action/cyberspace_return/cyberspace_return_action

/mob/living/proc/start_cyberspace_session(mode = CYBERSPACE_MODE_AVATAR, atom/movable/engram_anchor = null)
	if(cyberspace_session)
		cyberspace_session.end_session()
		return TRUE
	if(world.time < cyberspace_transition_blocked_until)
		to_chat(src, span_warning("Your neural pattern is transition-locked for [DisplayTimeText(cyberspace_transition_blocked_until - world.time)]."))
		return FALSE
	var/datum/cyberspace_session/session = new(src, mode, engram_anchor)
	if(!session.begin())
		qdel(session)
		return FALSE
	return TRUE

/mob/living/proc/stop_cyberspace_session()
	if(!cyberspace_session)
		return FALSE
	if(!cyberspace_session.can_return_to_body())
		to_chat(src, span_warning("Your avatar is too far from your body to safely collapse the projection. Return within [CYBERSPACE_RETURN_TO_BODY_RANGE] tiles."))
		return FALSE
	cyberspace_session.end_session()
	return TRUE

/mob/living/proc/grant_cyberspace_return_action()
	if(cyberspace_return_action)
		return cyberspace_return_action
	cyberspace_return_action = new(src)
	cyberspace_return_action.Grant(src)
	update_action_buttons(TRUE)
	return cyberspace_return_action

/mob/living/proc/remove_cyberspace_return_action()
	if(!cyberspace_return_action)
		return
	cyberspace_return_action.Remove(src)
	QDEL_NULL(cyberspace_return_action)
	update_action_buttons(TRUE)

/mob/living/proc/is_projected_into_cyberspace()
	return !isnull(cyberspace_session) && cyberspace_session.active

/mob/living/proc/get_cyberspace_speech_source()
	return cyberspace_session?.avatar || src

/mob/living/proc/get_cyber_hacking_skill()
	return mind?.get_character_skill_level(SKILL_HACKING) || 0

/mob/living/proc/get_cyberspace_avatar_name(mode = CYBERSPACE_MODE_AVATAR)
	var/avatar_name = real_name || name
	if(client?.prefs)
		avatar_name = client.prefs.read_preference(/datum/preference/name/hacker_alias) || avatar_name
	return "[avatar_name]'s [mode]"

/datum/action/cyberspace_return
	name = "Return From Net"
	desc = "Collapse the active cyberspace avatar back into the body."
	button_icon = 'icons/obj/devices/circuitry_n_data.dmi'
	button_icon_state = "datadisk1"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cyberspace_return/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/mob/living/living_owner = owner
	if(!istype(living_owner))
		return FALSE
	return living_owner.stop_cyberspace_session()
