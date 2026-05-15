SUBSYSTEM_DEF(cy_demons)
	name = "Cyberpunk Demons"
	wait = 0.5 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	ss_flags = SS_BACKGROUND

	var/list/active_casts = list()

/datum/controller/subsystem/cy_demons/fire(resumed = FALSE)
	for(var/datum/cy_demon_cast/cast as anything in active_casts.Copy())
		if(QDELETED(cast))
			active_casts -= cast
			continue
		var/result = cast.process_cast(wait / 10)
		if(result != CY_DEMON_CAST_RUNNING)
			active_casts -= cast

/datum/controller/subsystem/cy_demons/stat_entry(msg)
	msg = "Casts:[length(active_casts)]"
	return ..()

/datum/controller/subsystem/cy_demons/proc/start_cast(datum/cy_demon_cast/cast)
	if(!cast)
		return FALSE
	active_casts |= cast
	return TRUE

/datum/controller/subsystem/cy_demons/proc/stop_cast(datum/cy_demon_cast/cast)
	if(!cast)
		return FALSE
	active_casts -= cast
	return TRUE
