SUBSYSTEM_DEF(cyberpunk_corporations)
	name = "Cyberpunk Corporations"
	runlevels = RUNLEVEL_GAME
	//CYBERPUNK BUILD - rebuild and delete before release
	/// Round-local corporate registry. Keyed by corporation id.
	var/list/cyberpunk_corporations = list()
	/// Whether round-local corporate datums and accounts were created.
	var/cyberpunk_corporations_seeded = FALSE
	//CYBERPUNK BUILD - rebuild and delete before release

/datum/controller/subsystem/cyberpunk_corporations/Initialize()
	ensure_cyberpunk_corporations_seeded()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cyberpunk_corporations/Recover()
	cyberpunk_corporations = SScyberpunk_corporations.cyberpunk_corporations
	cyberpunk_corporations_seeded = SScyberpunk_corporations.cyberpunk_corporations_seeded
