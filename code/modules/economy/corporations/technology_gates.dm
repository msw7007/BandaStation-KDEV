//CYBERPUNK CORPORATIONS - technology access gates for production and services.

/datum/cyberpunk_corporation/proc/can_use_technology(source_corporation_id, technology_id)
	if(!technology_id)
		return TRUE
	source_corporation_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(source_corporation_id || id)
	if(source_corporation_id == id)
		return has_technology(technology_id)
	return stolen_technologies[technology_id] == source_corporation_id

/datum/controller/subsystem/cyberpunk_corporations/proc/refresh_cyberpunk_corporate_fabricators(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	if(!corporation_id)
		return
	for(var/obj/machinery/rnd/production/fabricator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/rnd/production))
		if(cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(fabricator)) != corporation_id)
			continue
		fabricator.update_designs()

/datum/design/proc/get_cyberpunk_required_technology_name()
	if(!cyberpunk_required_technology_id)
		return null
	var/source_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(cyberpunk_technology_corporation_id)
	var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
	var/list/technology = source_corporation?.get_technology(cyberpunk_required_technology_id)
	return technology?["name"] || cyberpunk_required_technology_id

/datum/design/proc/can_build_cyberpunk_corporate_technology(obj/machinery/rnd/production/fabricator, mob/user = null, silent = FALSE)
	if(!cyberpunk_required_technology_id)
		return TRUE
	var/fabricator_corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(fabricator))
	if(!fabricator_corporation_id)
		return TRUE
	var/datum/cyberpunk_corporation/fabricator_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(fabricator_corporation_id)
	if(fabricator_corporation?.can_use_technology(cyberpunk_technology_corporation_id, cyberpunk_required_technology_id))
		return TRUE
	if(!silent)
		var/source_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(cyberpunk_technology_corporation_id)
		var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
		var/technology_name = get_cyberpunk_required_technology_name()
		to_chat(user, span_warning("[fabricator] lacks [source_corporation?.name || source_id] technology: [technology_name]."))
	return FALSE

/datum/cyberpunk_corporation/proc/get_service_required_technology(service_id)
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			switch(service_id)
				if("medical")
					return "benn_medtech"
				if("body")
					return "benn_genetics"
				if("stealth")
					return "benn_stealthware"
				if("chemistry")
					return "benn_chemistry"
		if(CYBERPUNK_CORP_RYAZNOV)
			switch(service_id)
				if("technical")
					return "ryaznov_tools"
				if("salvage")
					return "ryaznov_blueprints"
				if("fortify")
					return "ryaznov_fortification"
				if("power")
					return "ryaznov_power"
		if(CYBERPUNK_CORP_STARLIGHT)
			switch(service_id)
				if("delivery")
					return "starlight_delivery"
				if("return")
					return "starlight_market"
				if("transport")
					return "starlight_vehicle"
				if("influence")
					return "starlight_route_archive"
	return null
