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
		fabricator.refresh_designs()

/datum/design/proc/get_cyberpunk_technology_search_text()
	var/search_text = lowertext("[id] [name] [desc] [build_path]")
	for(var/category_entry in category)
		search_text += " [lowertext("[category_entry]")]"
	return search_text

/datum/design/proc/cyberpunk_technology_text_has(list/needles)
	var/search_text = get_cyberpunk_technology_search_text()
	for(var/needle in needles)
		if(findtext(search_text, lowertext("[needle]")))
			return TRUE
	return FALSE

/datum/design/proc/get_cyberpunk_technology_corporation_id()
	if(cyberpunk_technology_corporation_id)
		return SScyberpunk_corporations.cyberpunk_normalize_corporation_id(cyberpunk_technology_corporation_id)
	if(cyberpunk_technology_text_has(list("robot", "robotic", "robotics", "cyborg", "borg", "mech", "mecha", "mechfab", "exosuit", "ai core", "ai upgrade")))
		return CYBERPUNK_CORP_RYAZNOV
	if(cyberpunk_technology_text_has(list("xeno", "xenobio", "xenobiology", "slime", "dna", "gene", "genetic", "mutation", "mutat", "limb", "organ", "medical", "surgery", "surgical", "chem", "pharma", "health", "cryo")))
		return CYBERPUNK_CORP_BENN
	if(cyberpunk_technology_text_has(list("cargo", "supply", "mining", "miner", "ore", "delivery", "market", "vendor", "vending", "service", "kitchen", "bar", "botany", "hydroponic", "janitor", "entertainment", "tourism")))
		return CYBERPUNK_CORP_STARLIGHT
	if(cyberpunk_technology_text_has(list("engineering", "engineer", "atmos", "power", "apc", "construction", "machine", "machinery", "stock part", "stock_parts", "capacitor", "matter bin", "servo", "scanning module", "telecomms", "tools")))
		return CYBERPUNK_CORP_RYAZNOV
	if(departmental_flags & DEPARTMENT_BITFLAG_MEDICAL)
		return CYBERPUNK_CORP_BENN
	if(departmental_flags & DEPARTMENT_BITFLAG_ENGINEERING)
		return CYBERPUNK_CORP_RYAZNOV
	if(departmental_flags & (DEPARTMENT_BITFLAG_CARGO | DEPARTMENT_BITFLAG_SERVICE))
		return CYBERPUNK_CORP_STARLIGHT
	return null

/datum/design/proc/get_cyberpunk_required_technology_id()
	if(cyberpunk_required_technology_id)
		return cyberpunk_required_technology_id
	var/source_id = get_cyberpunk_technology_corporation_id()
	switch(source_id)
		if(CYBERPUNK_CORP_BENN)
			if(cyberpunk_technology_text_has(list("dna", "gene", "genetic", "mutation", "mutat", "xeno", "xenobio", "xenobiology", "slime", "limb", "organ")))
				return "benn_genetics"
			if(cyberpunk_technology_text_has(list("chem", "pharma", "reagent", "toxin", "acid")))
				return "benn_chemistry"
			if(cyberpunk_technology_text_has(list("implant", "cybernetic", "augment", "stealth")))
				return "benn_stealthware"
			return "benn_medtech"
		if(CYBERPUNK_CORP_RYAZNOV)
			if(cyberpunk_technology_text_has(list("robot", "robotic", "robotics", "cyborg", "borg", "mech", "mecha", "mechfab", "exosuit", "ai core", "ai upgrade")))
				return "ryaznov_robotics"
			if(cyberpunk_technology_text_has(list("power", "apc", "cell", "battery", "charger", "shield", "energy")))
				return "ryaznov_power"
			if(cyberpunk_technology_text_has(list("armor", "plating", "reinforced", "barricade", "wall", "structure", "fort")))
				return "ryaznov_fortification"
			if(cyberpunk_technology_text_has(list("archive", "blueprint", "production", "fabricator", "optimizer", "overclock")))
				return "ryaznov_blueprints"
			return "ryaznov_tools"
		if(CYBERPUNK_CORP_STARLIGHT)
			if(cyberpunk_technology_text_has(list("vehicle", "shuttle", "transit", "transport", "bluespace", "teleport")))
				return "starlight_vehicle"
			if(cyberpunk_technology_text_has(list("phase", "blink", "relay", "cyberspace")))
				return "starlight_phase"
			if(cyberpunk_technology_text_has(list("delivery", "cargo", "supply", "mining", "miner", "ore", "route", "beacon")))
				return "starlight_delivery"
			if(cyberpunk_technology_text_has(list("archive", "statistics", "tracking", "camera", "network")))
				return "starlight_route_archive"
			return "starlight_market"
	return null

/datum/design/proc/get_cyberpunk_required_technology_name()
	var/technology_id = get_cyberpunk_required_technology_id()
	if(!technology_id)
		return null
	var/source_id = get_cyberpunk_technology_corporation_id()
	var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
	var/list/technology = source_corporation?.get_technology(technology_id)
	return technology?["name"] || technology_id

/datum/design/proc/can_build_cyberpunk_corporate_technology(obj/machinery/rnd/production/fabricator, mob/user = null, silent = FALSE)
	var/technology_id = get_cyberpunk_required_technology_id()
	if(!technology_id)
		return TRUE
	var/fabricator_corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(fabricator))
	if(!fabricator_corporation_id)
		return TRUE
	var/datum/cyberpunk_corporation/fabricator_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(fabricator_corporation_id)
	var/source_id = get_cyberpunk_technology_corporation_id()
	if(fabricator_corporation?.can_use_technology(source_id, technology_id))
		return TRUE
	if(!silent)
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
