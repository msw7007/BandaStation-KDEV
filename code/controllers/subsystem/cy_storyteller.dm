SUBSYSTEM_DEF(cy_storyteller)
	name = "Cyberpunk Storyteller"
	wait = 30 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	ss_flags = SS_BACKGROUND

	var/list/pressure = list()
	var/list/story_log = list()
	var/list/last_snapshot = list()
	var/next_contract_seed = 0
	var/contract_seed_interval = 5 MINUTES

/datum/controller/subsystem/cy_storyteller/Initialize()
	reset_pressure()
	next_contract_seed = world.time + contract_seed_interval
	rebuild_snapshot()
	SSticker?.OnRoundend(CALLBACK(src, PROC_REF(announce_roundend_report)))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cy_storyteller/Recover()
	pressure = SScy_storyteller.pressure
	story_log = SScy_storyteller.story_log
	last_snapshot = SScy_storyteller.last_snapshot
	next_contract_seed = SScy_storyteller.next_contract_seed

/datum/controller/subsystem/cy_storyteller/fire(resumed = FALSE)
	rebuild_snapshot()
	if(world.time >= next_contract_seed)
		next_contract_seed = world.time + contract_seed_interval
		seed_pressure_contract()

/datum/controller/subsystem/cy_storyteller/stat_entry(msg)
	msg = "Pressure:[round(get_total_pressure())] Ending:[get_dominant_ending()]"
	return ..()

/datum/controller/subsystem/cy_storyteller/proc/reset_pressure()
	pressure = list(
		CY_STORY_PRESSURE_VIOLENCE = 0,
		CY_STORY_PRESSURE_ECONOMY = 0,
		CY_STORY_PRESSURE_CORPORATE = 0,
		CY_STORY_PRESSURE_BLACK_MARKET = 0,
		CY_STORY_PRESSURE_RESCUE = 0,
		CY_STORY_PRESSURE_LAW = 0,
	)

/datum/controller/subsystem/cy_storyteller/proc/add_pressure(category, amount = 1, source = null)
	if(!pressure)
		reset_pressure()
	category ||= CY_STORY_PRESSURE_ECONOMY
	pressure[category] = max(0, (pressure[category] || 0) + amount)
	log_story("pressure", category, amount, source)
	return pressure[category]

/datum/controller/subsystem/cy_storyteller/proc/log_story(event_type, category = null, amount = null, source = null)
	story_log += list(list(
		"time" = world.time,
		"event" = event_type,
		"category" = category,
		"amount" = amount,
		"source" = source ? "[source]" : null,
	))
	if(length(story_log) > 150)
		story_log.Cut(1, 2)

/datum/controller/subsystem/cy_storyteller/proc/get_total_pressure()
	var/total = 0
	for(var/category in pressure)
		total += pressure[category] || 0
	return total

/datum/controller/subsystem/cy_storyteller/proc/rebuild_snapshot()
	var/list/corporations = list()
	for(var/organization_type in list(/datum/cy_organization/corporation/ben, /datum/cy_organization/corporation/ryaznov, /datum/cy_organization/corporation/starlight))
		var/datum/cy_organization/organization = get_cy_organization_datum(organization_type)
		if(!organization)
			continue
		corporations[organization.id || "[organization.type]"] = list(
			"name" = organization.name,
			"level" = organization.round_level,
			"research" = organization.research_points,
			"profit" = organization.profit,
			"influence" = organization.influence,
		)
	var/open_contract_count = length(SScy_business?.open_contracts)
	var/crime_count = length(SSeconomy?.cy_city_crime_records)
	last_snapshot = list(
		"time" = world.time,
		"pressure" = pressure.Copy(),
		"total_pressure" = get_total_pressure(),
		"ending" = get_dominant_ending(),
		"corporations" = corporations,
		"open_contracts" = open_contract_count,
		"crime_records" = crime_count,
	)
	return last_snapshot

/datum/controller/subsystem/cy_storyteller/proc/get_dominant_ending()
	var/violence = pressure[CY_STORY_PRESSURE_VIOLENCE] || 0
	var/black_market = pressure[CY_STORY_PRESSURE_BLACK_MARKET] || 0
	var/law = pressure[CY_STORY_PRESSURE_LAW] || 0
	var/corporate = pressure[CY_STORY_PRESSURE_CORPORATE] || 0
	var/top_corp_level = 0
	for(var/organization_type in list(/datum/cy_organization/corporation/ben, /datum/cy_organization/corporation/ryaznov, /datum/cy_organization/corporation/starlight))
		var/datum/cy_organization/organization = get_cy_organization_datum(organization_type)
		top_corp_level = max(top_corp_level, organization?.round_level || 0)
	if(violence >= 100)
		return CY_STORY_ENDING_COLLAPSE
	if(black_market >= 80)
		return CY_STORY_ENDING_BLACK_MARKET
	if(top_corp_level >= 4 || corporate >= 120)
		return CY_STORY_ENDING_CORPORATE
	if(law >= 60 && violence < 50)
		return CY_STORY_ENDING_STABILITY
	return CY_STORY_ENDING_SURVIVAL

/datum/controller/subsystem/cy_storyteller/proc/get_story_state()
	return last_snapshot?.Copy() || rebuild_snapshot()

/datum/controller/subsystem/cy_storyteller/proc/roundend_report()
	var/list/state = get_story_state()
	var/list/report = list()
	report += "<b>Cyberpunk city ending:</b> [state["ending"]]<br>"
	report += "Total pressure: [round(state["total_pressure"])]<br>"
	var/list/state_pressure = state["pressure"]
	for(var/category in state_pressure)
		report += "[category]: [round(state_pressure[category])]<br>"
	var/list/corporations = state["corporations"]
	for(var/corp_id in corporations)
		var/list/corp = corporations[corp_id]
		report += "[corp["name"]]: level [corp["level"]], research [corp["research"]], profit [corp["profit"]], influence [corp["influence"]]<br>"
	return report.Join("")

/datum/controller/subsystem/cy_storyteller/proc/announce_roundend_report()
	to_chat(world, span_notice(roundend_report()))

/datum/controller/subsystem/cy_storyteller/proc/seed_pressure_contract()
	if(!SScy_business)
		return null
	var/ending = get_dominant_ending()
	var/list/data = list(
		"name" = "City pressure response",
		"description" = "A generated city contract responding to current round pressure.",
		"contract_type" = CY_CONTRACT_RECON,
		"visibility" = CY_CONTRACT_PUBLIC,
		"legality" = CY_CONTRACT_LEGAL,
		"payment_amount" = 300 + round(get_total_pressure() * 2),
		"due_time" = world.time + 20 MINUTES,
		"metadata" = list("story_ending" = ending, "recon_scanned" = FALSE, "allow_ai" = TRUE),
	)
	switch(ending)
		if(CY_STORY_ENDING_COLLAPSE)
			data["name"] = "Emergency stabilization patrol"
			data["contract_type"] = CY_CONTRACT_GUARD
			data["payment_amount"] += 500
		if(CY_STORY_ENDING_BLACK_MARKET)
			data["name"] = "Grey market audit"
			data["visibility"] = CY_CONTRACT_GREY
		if(CY_STORY_ENDING_CORPORATE)
			data["name"] = "Corporate asset survey"
			data["visibility"] = CY_CONTRACT_CORPORATE
	var/datum/cy_contract/contract = SScy_business.create_contract(data)
	if(contract)
		log_story("contract_seeded", ending, contract.payment_amount, contract)
	return contract
