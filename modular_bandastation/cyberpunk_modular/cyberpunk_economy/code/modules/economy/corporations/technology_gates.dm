//CYBERPUNK CORPORATIONS - technology access gates for production and services.

/proc/resolve_cyberpunk_corporate_technology_id(technology_id)
	switch("[technology_id]")
		if("benn_medtech")
			return "medbay_equip"
		if("benn_genetics")
			return "gene_engineering"
		if("benn_chemistry")
			return "chem_synthesis"
		if("benn_chemical_teg")
			return "chem_synthesis"
		if("benn_stealthware")
			return "cyber_implants"
		if("benn_bioarchive")
			return "bio_scan"
		if("ryaznov_tools")
			return "construction"
		if("ryaznov_fortification")
			return "construction"
		if("ryaznov_power")
			return "energy_manipulation"
		if("ryaznov_nuclear_block")
			return "plasma_control"
		if("ryaznov_robotics")
			return "robotics"
		if("ryaznov_blueprints")
			return "parts_adv"
		if("starlight_market")
			return "office_equip"
		if("starlight_delivery")
			return "material_proc"
		if("starlight_vehicle")
			return "shuttle_eng"
		if("starlight_phase")
			return "applied_bluespace"
		if("starlight_route_archive")
			return "telecoms"
		if("gov_tax")
			return "consoles"
		if("gov_cameras")
			return "hud"
		if("gov_council")
			return "consoles"
		if("gov_armory")
			return "sec_equip"
		if("gov_city_directive")
			return "ai"
	return technology_id

/proc/get_cyberpunk_techweb_node_cost(datum/techweb_node/node)
	if(!node)
		return 0
	var/total_cost = 0
	for(var/cost_type in node.research_costs)
		total_cost += node.research_costs[cost_type]
	return total_cost

/proc/get_cyberpunk_techweb_node_corporation_id(datum/techweb_node/node)
	if(!istype(node))
		node = SSresearch.techweb_node_by_id(node)
	if(!node)
		return null
	if(node.id in SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache)
		var/cached_corporation_id = SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id]
		return cached_corporation_id == CYBERPUNK_CORP_GOVERNMENT ? CYBERPUNK_CORP_STARLIGHT : cached_corporation_id
	var/list/corporation_scores = list()
	for(var/design_id in node.design_ids)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		var/corporation_id = design?.get_cyberpunk_technology_corporation_id()
		if(!corporation_id)
			continue
		corporation_scores[corporation_id] = (corporation_scores[corporation_id] || 0) + 1
	var/best_corporation
	var/best_score = 0
	for(var/corporation_id in corporation_scores)
		var/score = corporation_scores[corporation_id]
		if(score > best_score)
			best_score = score
			best_corporation = corporation_id
	if(best_corporation)
		if(best_corporation == CYBERPUNK_CORP_GOVERNMENT)
			best_corporation = CYBERPUNK_CORP_STARLIGHT
		SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = best_corporation
		return best_corporation
	var/search_text = lowertext("[node.id] [node.display_name] [node.description] [node.category]")
	if(findtext(search_text, "medical") || findtext(search_text, "chem") || findtext(search_text, "bio") || findtext(search_text, "gene") || findtext(search_text, "surgery") || findtext(search_text, "cyber"))
		SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = CYBERPUNK_CORP_BENN
		return CYBERPUNK_CORP_BENN
	if(findtext(search_text, "engineering") || findtext(search_text, "atmos") || findtext(search_text, "power") || findtext(search_text, "robot") || findtext(search_text, "mech") || findtext(search_text, "parts"))
		SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = CYBERPUNK_CORP_RYAZNOV
		return CYBERPUNK_CORP_RYAZNOV
	if(findtext(search_text, "service") || findtext(search_text, "cargo") || findtext(search_text, "mining") || findtext(search_text, "office") || findtext(search_text, "food") || findtext(search_text, "shuttle") || findtext(search_text, "bluespace"))
		SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = CYBERPUNK_CORP_STARLIGHT
		return CYBERPUNK_CORP_STARLIGHT
	if(findtext(search_text, "security") || findtext(search_text, "weapon") || findtext(search_text, "hud"))
		SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = CYBERPUNK_CORP_STARLIGHT
		return CYBERPUNK_CORP_STARLIGHT
	SScyberpunk_corporations.cyberpunk_techweb_node_corporation_cache[node.id] = null
	return null

/datum/cyberpunk_corporation/proc/can_use_technology(source_corporation_id, technology_id)
	if(!technology_id)
		return TRUE
	technology_id = resolve_cyberpunk_corporate_technology_id(technology_id)
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
		return resolve_cyberpunk_corporate_technology_id(cyberpunk_required_technology_id)
	var/source_id = get_cyberpunk_technology_corporation_id()
	for(var/node_entry as anything in unlocked_by)
		var/datum/techweb_node/node
		if(istype(node_entry, /datum/techweb_node))
			node = node_entry
		else
			node = SSresearch.techweb_node_by_id(node_entry)
		if(get_cyberpunk_techweb_node_corporation_id(node) == source_id)
			return node.id
	switch(source_id)
		if(CYBERPUNK_CORP_BENN)
			if(cyberpunk_technology_text_has(list("dna", "gene", "genetic", "mutation", "mutat", "xeno", "xenobio", "xenobiology", "slime", "limb", "organ")))
				return "gene_engineering"
			if(cyberpunk_technology_text_has(list("chem", "pharma", "reagent", "toxin", "acid")))
				return "chem_synthesis"
			if(cyberpunk_technology_text_has(list("implant", "cybernetic", "augment", "stealth")))
				return "cyber_implants"
			return "medbay_equip"
		if(CYBERPUNK_CORP_RYAZNOV)
			if(cyberpunk_technology_text_has(list("robot", "robotic", "robotics", "cyborg", "borg", "mech", "mecha", "mechfab", "exosuit", "ai core", "ai upgrade")))
				return "robotics"
			if(cyberpunk_technology_text_has(list("power", "apc", "cell", "battery", "charger", "shield", "energy")))
				return "energy_manipulation"
			if(cyberpunk_technology_text_has(list("armor", "plating", "reinforced", "barricade", "wall", "structure", "fort")))
				return "construction"
			if(cyberpunk_technology_text_has(list("archive", "blueprint", "production", "fabricator", "optimizer", "overclock")))
				return "parts_adv"
			return "construction"
		if(CYBERPUNK_CORP_STARLIGHT)
			if(cyberpunk_technology_text_has(list("vehicle", "shuttle", "transit", "transport", "bluespace", "teleport")))
				return "shuttle_eng"
			if(cyberpunk_technology_text_has(list("phase", "blink", "relay", "cyberspace")))
				return "applied_bluespace"
			if(cyberpunk_technology_text_has(list("delivery", "cargo", "supply", "mining", "miner", "ore", "route", "beacon")))
				return "material_proc"
			if(cyberpunk_technology_text_has(list("archive", "statistics", "tracking", "camera", "network")))
				return "telecoms"
			return "office_equip"
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
					return "medbay_equip"
				if("body")
					return "gene_engineering"
				if("stealth")
					return "cyber_implants"
				if("chemistry")
					return "chem_synthesis"
		if(CYBERPUNK_CORP_RYAZNOV)
			switch(service_id)
				if("technical")
					return "construction"
				if("salvage")
					return "parts_adv"
				if("fortify")
					return "construction"
				if("power")
					return "energy_manipulation"
		if(CYBERPUNK_CORP_STARLIGHT)
			switch(service_id)
				if("delivery")
					return "material_proc"
				if("return")
					return "office_equip"
				if("transport")
					return "shuttle_eng"
				if("influence")
					return "telecoms"
	return null
