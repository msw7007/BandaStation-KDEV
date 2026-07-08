//CYBERPUNK CORPORATIONS - service request queue.

/mob/living/basic/cyberpunk_corporate_agent
	name = "corporate field agent"
	desc = "A short-term corporate representative dispatched to close a paid service request."
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = "nanotrasen"
	health = 60
	maxHealth = 60
	speed = 0
	density = FALSE
	basic_mob_flags = DEL_ON_DEATH
	habitable_atmos = null
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	ai_controller = null
	var/corporation_id
	var/service_id
	var/agent_title = "field agent"

/mob/living/basic/cyberpunk_corporate_agent/Initialize(mapload, new_corporation_id, new_service_id, customer_name)
	. = ..()
	corporation_id = new_corporation_id
	service_id = new_service_id
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(corporation)
		name = "[corporation.name] [agent_title]"
		desc = "A temporary [corporation.name] representative assigned to service '[service_id]' for [customer_name || "a client"]."
		add_atom_colour(cyberpunk_corporate_agent_color(corporation_id), FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, 35 SECONDS)

/mob/living/basic/cyberpunk_corporate_agent/proc/announce_service(mob/living/customer, service_label)
	if(!customer || QDELETED(customer))
		return FALSE
	visible_message(span_notice("[src] confirms [service_label || service_id] service for [customer]."))
	return TRUE

/mob/living/basic/cyberpunk_corporate_agent/benn
	agent_title = "clinical agent"
	icon_state = "medical"

/mob/living/basic/cyberpunk_corporate_agent/ryaznov
	agent_title = "industrial agent"
	icon_state = "engineer"

/mob/living/basic/cyberpunk_corporate_agent/starlight
	agent_title = "courier agent"
	icon_state = "assistant"

/mob/living/basic/cyberpunk_corporate_agent/government
	agent_title = "civic agent"
	icon_state = "officer"

/datum/cyberpunk_corporate_service_request
	var/id = 0
	var/corporation_id
	var/corporation_name
	var/service_id
	var/service_label
	var/customer_name
	var/customer_key
	var/cost = 0
	var/status = CYBERPUNK_CORP_SERVICE_CREATED
	var/created_at = 0
	var/completed_at = 0
	var/datum/weakref/customer_ref
	var/list/history = list()

/datum/cyberpunk_corporate_service_request/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_corporate_service_request/proc/complete()
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation?.dispatch_agent("manual service: [service_id]", 3 MINUTES))
		add_history("completion failed: no free corporate agents")
		return FALSE
	var/mob/living/customer = customer_ref?.resolve()
	if(!customer || QDELETED(customer))
		add_history("completion failed: customer unavailable")
		return FALSE
	var/success = FALSE
	switch(corporation_id)
		if(CYBERPUNK_CORP_BENN)
			success = cyberpunk_complete_benn_service(WEAKREF(customer), corporation_id, service_id)
		if(CYBERPUNK_CORP_RYAZNOV)
			success = cyberpunk_complete_ryaznov_service(WEAKREF(customer), corporation_id, service_id)
		if(CYBERPUNK_CORP_STARLIGHT)
			success = cyberpunk_complete_starlight_service(WEAKREF(customer), corporation_id, service_id)
	if(!success)
		add_history("completion failed during service execution")
		return FALSE
	status = CYBERPUNK_CORP_SERVICE_COMPLETED
	completed_at = world.time
	add_history("completed")
	return TRUE

/datum/cyberpunk_corporate_service_request/proc/cancel(reason = "cancelled")
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	status = CYBERPUNK_CORP_SERVICE_CANCELLED
	add_history(reason)
	return TRUE

/datum/cyberpunk_corporate_service_request/proc/outsource()
	if(status != CYBERPUNK_CORP_SERVICE_CREATED)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/datum/cyberpunk_contract/contract = corporation?.create_service_outsource_contract(src)
	return !!contract

/datum/cyberpunk_corporate_service_request/proc/to_ui_data()
	return list(
		"id" = id,
		"corporationId" = corporation_id,
		"corporation" = corporation_name,
		"serviceId" = service_id,
		"service" = service_label || service_id,
		"customer" = customer_name,
		"cost" = cost,
		"status" = status,
		"age" = created_at ? DisplayTimeText(world.time - created_at) : "unknown",
		"history" = history,
	)

/datum/controller/subsystem/cyberpunk_corporations/proc/create_cyberpunk_corporate_service_request(datum/cyberpunk_corporation/corporation, mob/living/customer, service_id, cost = 0)
	if(!corporation || !customer)
		return null
	var/datum/cyberpunk_corporate_service_request/request = new
	request.id = next_cyberpunk_corporate_service_request_id++
	request.corporation_id = corporation.id
	request.corporation_name = corporation.name
	request.service_id = service_id
	request.service_label = corporation.get_service_label(service_id)
	request.customer_name = customer.real_name || customer.name
	request.customer_key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	request.cost = max(0, round(cost))
	request.created_at = world.time
	request.customer_ref = WEAKREF(customer)
	request.add_history("created by [request.customer_name]")
	cyberpunk_corporate_service_requests["[request.id]"] = request
	corporation.add_history("service request #[request.id] queued: [service_id] for [request.customer_name]")
	return request

/datum/controller/subsystem/cyberpunk_corporations/proc/spawn_cyberpunk_corporate_agent(corporation_id, service_id, mob/living/customer)
	if(!customer || QDELETED(customer))
		return null
	var/turf/spawn_turf = get_step(get_turf(customer), customer.dir || SOUTH)
	if(!spawn_turf || spawn_turf.is_blocked_turf(source_atom = customer))
		spawn_turf = get_turf(customer)
	if(!spawn_turf)
		return null
	var/agent_type = cyberpunk_corporate_agent_type(corporation_id)
	var/mob/living/basic/cyberpunk_corporate_agent/agent = new agent_type(spawn_turf, corporation_id, service_id, customer.real_name || customer.name)
	return agent

/proc/cyberpunk_spawn_service_agent(corporation_id, service_id, mob/living/customer, service_label = null)
	var/mob/living/basic/cyberpunk_corporate_agent/agent = SScyberpunk_corporations.spawn_cyberpunk_corporate_agent(corporation_id, service_id, customer)
	agent?.announce_service(customer, service_label || service_id)
	return agent

/proc/cyberpunk_corporate_agent_color(corporation_id)
	switch(lowertext(trim("[corporation_id]")))
		if(CYBERPUNK_CORP_BENN)
			return COLOR_GREEN
		if(CYBERPUNK_CORP_RYAZNOV)
			return COLOR_ORANGE
		if(CYBERPUNK_CORP_STARLIGHT)
			return COLOR_CYAN
		if(CYBERPUNK_CORP_GOVERNMENT)
			return COLOR_RED
	return COLOR_WHITE

/proc/cyberpunk_corporate_agent_type(corporation_id)
	switch(lowertext(trim("[corporation_id]")))
		if(CYBERPUNK_CORP_BENN)
			return /mob/living/basic/cyberpunk_corporate_agent/benn
		if(CYBERPUNK_CORP_RYAZNOV)
			return /mob/living/basic/cyberpunk_corporate_agent/ryaznov
		if(CYBERPUNK_CORP_STARLIGHT)
			return /mob/living/basic/cyberpunk_corporate_agent/starlight
		if(CYBERPUNK_CORP_GOVERNMENT)
			return /mob/living/basic/cyberpunk_corporate_agent/government
	return /mob/living/basic/cyberpunk_corporate_agent

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporate_service_request(request_id)
	return cyberpunk_corporate_service_requests["[request_id]"]

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporate_service_requests_ui(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	var/list/requests = list()
	for(var/request_id in cyberpunk_corporate_service_requests)
		var/datum/cyberpunk_corporate_service_request/request = cyberpunk_corporate_service_requests[request_id]
		if(request?.corporation_id != corporation_id)
			continue
		requests += list(request.to_ui_data())
	return requests

/datum/cyberpunk_corporation/proc/get_service_label(service_id)
	for(var/list/service as anything in get_available_services_ui())
		if(service["id"] == service_id)
			return service["label"]
	return service_id
