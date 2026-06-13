//CYBERPUNK CORPORATIONS - service request queue.

#define CYBERPUNK_CORP_SERVICE_CREATED "created"
#define CYBERPUNK_CORP_SERVICE_COMPLETED "completed"
#define CYBERPUNK_CORP_SERVICE_CANCELLED "cancelled"

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

#undef CYBERPUNK_CORP_SERVICE_CREATED
#undef CYBERPUNK_CORP_SERVICE_COMPLETED
#undef CYBERPUNK_CORP_SERVICE_CANCELLED

