// Cyberpunk 13 cyberspace: living mob session helpers.
// Split from cyberimp internals; keep cyberspace session state out of organ item definitions.

/mob/living
	var/datum/cyberspace_session/cyberspace_session

/mob/living/proc/start_cyberspace_session(mode = CYBERSPACE_MODE_AVATAR)
	if(cyberspace_session)
		cyberspace_session.end_session()
		return TRUE
	var/datum/cyberspace_session/session = new(src, mode)
	if(!session.begin())
		qdel(session)
		return FALSE
	return TRUE

/mob/living/proc/stop_cyberspace_session()
	if(!cyberspace_session)
		return FALSE
	cyberspace_session.end_session()
	return TRUE

/mob/living/proc/is_projected_into_cyberspace()
	return !isnull(cyberspace_session) && cyberspace_session.active

/mob/living/proc/get_cyber_hacking_skill()
	return mind?.get_character_skill_level(SKILL_HACKING) || 0
