SUBSYSTEM_DEF(cyberpunk_corporations)
	name = "Cyberpunk Corporations"
	wait = 1 MINUTES
	runlevels = RUNLEVEL_GAME
	//CYBERPUNK BUILD - rebuild and delete before release
	/// Round-local corporate registry. Keyed by corporation id.
	var/list/cyberpunk_corporations = list()
	/// Whether round-local corporate datums and accounts were created.
	var/cyberpunk_corporations_seeded = FALSE
	/// Round-local corporate service requests.
	var/list/cyberpunk_corporate_service_requests = list()
	/// Next round-local corporate service request id.
	var/next_cyberpunk_corporate_service_request_id = 1
	//CYBERPUNK BUILD - rebuild and delete before release

/datum/controller/subsystem/cyberpunk_corporations/Initialize()
	ensure_cyberpunk_corporations_seeded()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cyberpunk_corporations/Recover()
	cyberpunk_corporations = SScyberpunk_corporations.cyberpunk_corporations
	cyberpunk_corporations_seeded = SScyberpunk_corporations.cyberpunk_corporations_seeded
	cyberpunk_corporate_service_requests = SScyberpunk_corporations.cyberpunk_corporate_service_requests
	next_cyberpunk_corporate_service_request_id = SScyberpunk_corporations.next_cyberpunk_corporate_service_request_id

/datum/controller/subsystem/cyberpunk_corporations/fire(resumed = 0)
	ensure_cyberpunk_corporations_seeded()
