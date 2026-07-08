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
	/// Cached ownership for global R&D techweb nodes. Keyed by techweb node id.
	var/list/cyberpunk_techweb_node_corporation_cache = list()
	/// Round-local corporate transaction tax rates. Keyed by corporation id, stored as 0..1.
	var/list/cyberpunk_corporation_tax_rates = list()
	/// Round-local default business transaction tax rate, stored as 0..1.
	var/cyberpunk_business_default_tax_rate
	/// Round-local business transaction tax rates. Keyed by business id, stored as 0..1.
	var/list/cyberpunk_business_tax_rates = list()
	/// Round-local apartment rent fees. Keyed by apartment area type text, stored as flat credits.
	var/list/cyberpunk_housing_rent_by_area = list()
	/// Round-local city council emergency votes. Keyed by voter identity.
	var/list/cyberpunk_government_emergency_votes = list()
	/// Whether government emergency mode is currently active.
	var/cyberpunk_government_emergency_active = FALSE
	/// Round-local emergency directive text.
	var/cyberpunk_government_directive = ""
	//CYBERPUNK BUILD - rebuild and delete before release

/datum/controller/subsystem/cyberpunk_corporations/Initialize()
	ensure_cyberpunk_corporations_seeded()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cyberpunk_corporations/Recover()
	cyberpunk_corporations = SScyberpunk_corporations.cyberpunk_corporations
	cyberpunk_corporations_seeded = SScyberpunk_corporations.cyberpunk_corporations_seeded
	cyberpunk_corporate_service_requests = SScyberpunk_corporations.cyberpunk_corporate_service_requests
	next_cyberpunk_corporate_service_request_id = SScyberpunk_corporations.next_cyberpunk_corporate_service_request_id
	cyberpunk_techweb_node_corporation_cache = SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache
	cyberpunk_corporation_tax_rates = SScyberpunk_corporations.cyberpunk_corporation_tax_rates
	cyberpunk_business_default_tax_rate = SScyberpunk_corporations.cyberpunk_business_default_tax_rate
	cyberpunk_business_tax_rates = SScyberpunk_corporations.cyberpunk_business_tax_rates
	cyberpunk_housing_rent_by_area = SScyberpunk_corporations.cyberpunk_housing_rent_by_area
	cyberpunk_government_emergency_votes = SScyberpunk_corporations.cyberpunk_government_emergency_votes
	cyberpunk_government_emergency_active = SScyberpunk_corporations.cyberpunk_government_emergency_active
	cyberpunk_government_directive = SScyberpunk_corporations.cyberpunk_government_directive

/datum/controller/subsystem/cyberpunk_corporations/fire(resumed = 0)
	ensure_cyberpunk_corporations_seeded()
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		corporation?.process_payroll()
