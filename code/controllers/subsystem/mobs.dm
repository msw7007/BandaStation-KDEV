SUBSYSTEM_DEF(mobs)
	name = "Mobs"
	priority = FIRE_PRIORITY_MOBS
	ss_flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 2 SECONDS

	var/list/currentrun = list()
	///only contains living players for some reason
	var/static/list/clients_by_zlevel[][]
	var/static/list/dead_players_by_zlevel[][] = list(list()) // Needs to support zlevel 1 here, MaxZChanged only happens when z2 is created and new_players can login before that.
	var/static/list/cubemonkeys = list()
	var/static/list/cheeserats = list()

/datum/controller/subsystem/mobs/stat_entry(msg)
	msg = "P:[length(GLOB.mob_living_list)]"
	return ..()

/datum/controller/subsystem/mobs/proc/MaxZChanged()
	if (!islist(clients_by_zlevel))
		clients_by_zlevel = new /list(world.maxz,0)
		dead_players_by_zlevel = new /list(world.maxz,0)
	while (clients_by_zlevel.len < world.maxz)
		clients_by_zlevel.len++
		clients_by_zlevel[clients_by_zlevel.len] = list()
		dead_players_by_zlevel.len++
		dead_players_by_zlevel[dead_players_by_zlevel.len] = list()

/datum/controller/subsystem/mobs/fire(resumed = FALSE)
	if (!resumed)
		src.currentrun = GLOB.mob_living_list.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun
	var/seconds_per_tick = wait / (1 SECONDS)
	while(currentrun.len)
		var/mob/living/processing_mob = currentrun[currentrun.len]
		currentrun.len--
		if(processing_mob)
			var/datum/ai_controller/controller = processing_mob.ai_controller
			if(controller?.blackboard[BB_CP_PHANTOM_ENABLED] && controller.blackboard[BB_CP_PHANTOM_STATE] != CP_AI_PHANTOM_INACTIVE)
				controller.cyberpunk_process_phantom_health()
				if(QDELETED(processing_mob))
					if(MC_TICK_CHECK)
						return
					continue
				if(controller.cyberpunk_can_suspend_body())
					if(MC_TICK_CHECK)
						return
					continue
				controller.cyberpunk_materialize_phantom("body needs processing")
			processing_mob.Life(seconds_per_tick)
		else
			GLOB.mob_living_list.Remove(processing_mob)
		if (MC_TICK_CHECK)
			return
