//CYBERPUNK CORPORATIONS - corporation datum and core economy/research logic.
/datum/cyberpunk_corporation
	var/id = ""
	var/name = "Corporation"
	var/group = ""
	var/direction = ""
	var/combat_doctrine = ""
	var/hidden = FALSE
	var/account_id
	var/level = 1
	var/experience = 0
	var/research_points = 0
	var/influence = 0
	var/tax_debt = 0
	var/tax_paid = 0
	var/service_auto_enabled = TRUE
	var/list/subsidiaries = list()
	var/list/research_data = list()
	var/list/unlocked_technologies = list()
	var/list/active_edicts = list()
	var/list/subscribers = list()
	var/list/vendor_sales = list()
	var/list/vendor_registry = list()
	var/list/stolen_technology_progress = list()
	var/list/stolen_technologies = list()
	var/list/technology_discount_points = list()
	var/list/technologies = list()
	var/list/edicts = list()
	var/list/history = list()

/datum/cyberpunk_corporation/New(corporation_id)
	. = ..()
	id = corporation_id
	setup_profile()
	add_history("corporation initialized")

/datum/cyberpunk_corporation/proc/setup_profile()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			name = "Benn Conglomerate"
			group = "Asian medical and genetic group"
			direction = "Medicine, genetics, chemistry, stealth, precision, speed."
			combat_doctrine = "Hidden and precise strikes, blade damage, poison, acceleration, stealth."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "sun_yon", "Sun Yon Corporation", "Sun Yon", "Precision systems and ranged weapon modules.", "precision"),
				new /datum/cyberpunk_corporate_subsidiary(id, "ishikawa", "Ishikawa Industries", "Ishikawa", "Stealth systems and covert equipment.", "stealth"),
				new /datum/cyberpunk_corporate_subsidiary(id, "ho_shi", "Ho Shi Technologies", "Ho Shi", "Speed, reflex and acceleration modules.", "speed"),
			)
			technologies = list(
				list("id" = "benn_medtech", "name" = "Medical service lattice", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Medical kiosks, analyzers, insurance goods, and treatment automation."),
				list("id" = "benn_genetics", "name" = "Genetic stabilization", "tier" = 2, "cost" = 45, "prereq" = "benn_medtech", "description" = "Genetic consoles, infusers, stabilizers, and mutation rollback support."),
				list("id" = "benn_chemistry", "name" = "Combat chemistry", "tier" = 3, "cost" = 65, "prereq" = "benn_genetics", "description" = "Composite reagents, toxins, acid mixtures, and chemical demon payloads."),
				list("id" = "benn_chemical_teg", "name" = "Chemical thermoelectric generation", "tier" = 3, "cost" = 70, "prereq" = "benn_chemistry", "description" = "Reagent-driven TEG blocks, hot/cold cartridges, and chemistry-controlled grid support."),
				list("id" = "benn_stealthware", "name" = "Stealthware implants", "tier" = 4, "cost" = 85, "prereq" = "benn_chemistry", "description" = "Stealth, speed, precision and surgical implant branches."),
				list("id" = "benn_bioreactor", "name" = "Biomass reactor", "tier" = 5, "cost" = 120, "prereq" = "benn_chemical_teg", "description" = "Organic matter disassembly, biohazard containment, and high-yield biological generation."),
				list("id" = "benn_bioarchive", "name" = "DNA archive", "tier" = 5, "cost" = 110, "prereq" = "benn_stealthware", "description" = "Bio-data storage, foreign technology scanning, and recovery research.")
			)
			edicts = cyberpunk_benn_edicts()
		if(CYBERPUNK_CORP_RYAZNOV)
			name = "Ryaznov Union"
			group = "European infrastructure and industry group"
			direction = "Construction, repair, robotics, energy, heavy machinery, industrial production."
			combat_doctrine = "Open force, reliability, armor, area damage, impact and thermal weapons."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "kowalski", "Kowalski & Co", "Kowalski", "Industrial tooling and heavy classic weapons.", "engineering"),
				new /datum/cyberpunk_corporate_subsidiary(id, "tyazhmarsh", "Tyazhmarsh Production", "Tyazhmarsh", "Armor, heavy machinery and reinforced frames.", "defense"),
				new /datum/cyberpunk_corporate_subsidiary(id, "tesla_science", "Tesla Science", "Tesla Science", "Energy, power and shield modules.", "power"),
			)
			technologies = list(
				list("id" = "ryaznov_tools", "name" = "Industrial toolchain", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Engineering tools, analyzers, repair stations, and construction gear."),
				list("id" = "ryaznov_fortification", "name" = "Fortification grid", "tier" = 2, "cost" = 45, "prereq" = "ryaznov_tools", "description" = "Barriers, shields, barricades, plating, and reinforced structures."),
				list("id" = "ryaznov_power", "name" = "Power and shield systems", "tier" = 3, "cost" = 65, "prereq" = "ryaznov_fortification", "description" = "Generators, shield emitters, chargers, and emergency energy modules."),
				list("id" = "ryaznov_nuclear_block", "name" = "Nuclear energy block", "tier" = 3, "cost" = 75, "prereq" = "ryaznov_power", "description" = "Uranium energy blocks, coolant rods, reactor consoles, and city-grade industrial generation."),
				list("id" = "ryaznov_robotics", "name" = "Robotic industry", "tier" = 4, "cost" = 85, "prereq" = "ryaznov_power", "description" = "Drones, turrets, mech docks, exoskeletons, and mobile workshops."),
				list("id" = "ryaznov_cold_fusion", "name" = "Cold fusion collider", "tier" = 5, "cost" = 130, "prereq" = "ryaznov_nuclear_block", "description" = "High-density fusion generation and anomaly-prone collider infrastructure."),
				list("id" = "ryaznov_blueprints", "name" = "Blueprint archive", "tier" = 5, "cost" = 110, "prereq" = "ryaznov_robotics", "description" = "Engineering data archive and foreign technology reverse engineering.")
			)
			edicts = cyberpunk_ryaznov_edicts()
		if(CYBERPUNK_CORP_STARLIGHT)
			name = "Starlight Combine"
			group = "North American logistics and mass production group"
			direction = "Goods, transport, delivery, contracts, vending, teleport nodes, social influence."
			combat_doctrine = "Control, mass pressure, speed, buffs, debuffs, teleportation, positional manipulation."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "blackrock_investigate", "Blackrock Investigate", "Blackrock", "Data collection, investigation and suppression modules.", "intel"),
				new /datum/cyberpunk_corporate_subsidiary(id, "trans_travel", "Trans Travel", "Trans Travel", "Routing, movement and delivery systems.", "route"),
				new /datum/cyberpunk_corporate_subsidiary(id, "samanthas_keir", "Samantha's Keir", "Samantha's Keir", "Social influence, advertising and market pressure.", "social"),
			)
			technologies = list(
				list("id" = "starlight_market", "name" = "Market routing", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Contracts, vending, subscriptions, and stock telemetry."),
				list("id" = "starlight_delivery", "name" = "Delivery network", "tier" = 2, "cost" = 45, "prereq" = "starlight_market", "description" = "Cargo drones, delivery beacons, route data, and business logistics."),
				list("id" = "starlight_kinetic_reactor", "name" = "Kinetic reactor train", "tier" = 3, "cost" = 65, "prereq" = "starlight_delivery", "description" = "Wheel-shaft-motor reactor assemblies, inertia storage, and cold-room maintenance loops."),
				list("id" = "starlight_vehicle", "name" = "Transport platforms", "tier" = 3, "cost" = 65, "prereq" = "starlight_delivery", "description" = "Ground and air vehicles, route registration, and cargo movement."),
				list("id" = "starlight_phase", "name" = "Phase logistics", "tier" = 4, "cost" = 85, "prereq" = "starlight_vehicle", "description" = "Teleportation, recall, phase suits, and blink delivery."),
				list("id" = "starlight_energy_portal", "name" = "Energy portal lattice", "tier" = 5, "cost" = 135, "prereq" = "starlight_phase", "description" = "Crystal portals, emitter containment, and high-risk extradimensional power import."),
				list("id" = "starlight_route_archive", "name" = "Route archive", "tier" = 5, "cost" = 110, "prereq" = "starlight_phase", "description" = "Market intelligence, foreign tech scanning, and route optimization.")
			)
			edicts = cyberpunk_starlight_edicts()
		if(CYBERPUNK_CORP_GOVERNMENT)
			name = "City Government"
			group = "Hidden council corporation"
			direction = "Taxes, city stability, laws, emergency modes, police support."
			combat_doctrine = "Police operations, cameras, emergency armories, council voting keys."
			hidden = TRUE
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_council", "Council", "City Council", "Votes, laws, emergency decrees.", "civic", 1, 1, 1),
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_police", "Police", "City Police", "Public order and emergency enforcement.", "security", 1, 1, 1),
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_treasury", "City Treasury", "City Treasury", "Taxes, debt, registered finance.", "finance", 1, 1, 1),
			)
			technologies = list(
				list("id" = "gov_tax", "name" = "Tax registry", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Legal transaction tracking, tax records, and debt oversight."),
				list("id" = "gov_cameras", "name" = "City surveillance", "tier" = 2, "cost" = 45, "prereq" = "gov_tax", "description" = "Camera monitoring, evidence routing, and public order data."),
				list("id" = "gov_council", "name" = "Council voting keys", "tier" = 3, "cost" = 65, "prereq" = "gov_cameras", "description" = "Council votes, emergency state confirmation, and formal decrees."),
				list("id" = "gov_armory", "name" = "Emergency armory", "tier" = 4, "cost" = 85, "prereq" = "gov_council", "description" = "Special police warehouse and emergency combat kit authorization."),
				list("id" = "gov_city_directive", "name" = "City directive", "tier" = 5, "cost" = 110, "prereq" = "gov_armory", "description" = "City-wide corporate action approval and suppression hooks.")
			)
			edicts = list()

/datum/cyberpunk_corporation/proc/ensure_account()
	if(account_id && SSeconomy.bank_accounts_by_id["[account_id]"])
		return SSeconomy.bank_accounts_by_id["[account_id]"]
	var/datum/bank_account/account = new /datum/bank_account/cyberpunk_corporation("[name] corporate account")
	account.adjust_money(CYBERPUNK_CORP_STARTING_BUDGET, "Corporate starting budget")
	account_id = account.account_id
	return account

/datum/cyberpunk_corporation/proc/get_account()
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/datum/cyberpunk_corporation/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_corporation/proc/get_subsidiary_by_manufacturer(manufacturer)
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	if(!manufacturer_text)
		return null
	for(var/datum/cyberpunk_corporate_subsidiary/subsidiary as anything in subsidiaries)
		if(subsidiary.matches_manufacturer(manufacturer_text))
			return subsidiary
	return null

/datum/cyberpunk_corporation/proc/technology_matches_data_type(list/technology, data_type)
	if(!islist(technology) || !data_type)
		return FALSE
	var/technology_id = technology["id"]
	var/technology_name = technology["name"]
	var/technology_description = technology["description"]
	var/search_text = lowertext("[technology_id] [technology_name] [technology_description]")
	switch(data_type)
		if("bio", "medical", "genetic", "chemistry", "stealth")
			return findtext(search_text, "benn") || findtext(search_text, "med") || findtext(search_text, "gene") || findtext(search_text, "chem") || findtext(search_text, "bio") || findtext(search_text, "stealth")
		if("engineering", "power", "defense", "repair", "salvage")
			return findtext(search_text, "ryaznov") || findtext(search_text, "tool") || findtext(search_text, "fort") || findtext(search_text, "power") || findtext(search_text, "robot") || findtext(search_text, "blueprint")
		if("market", "route", "social", "delivery", "supply")
			return findtext(search_text, "starlight") || findtext(search_text, "market") || findtext(search_text, "delivery") || findtext(search_text, "vehicle") || findtext(search_text, "phase") || findtext(search_text, "route")
	return findtext(search_text, data_type)

/datum/cyberpunk_corporation/proc/apply_technology_discounts(data_type, amount, source = "activity")
	if(!amount)
		return FALSE
	var/applied = FALSE
	for(var/list/technology as anything in technologies)
		var/technology_id = technology["id"]
		if(unlocked_technologies[technology_id] || !technology_matches_data_type(technology, data_type))
			continue
		var/max_discount = round((technology["cost"] || 0) * 0.35)
		if(max_discount <= 0)
			continue
		var/current_discount = technology_discount_points[technology_id] || 0
		var/add_discount = min(max_discount - current_discount, max(1, round(amount / 3)))
		if(add_discount <= 0)
			continue
		technology_discount_points[technology_id] = current_discount + add_discount
		applied = TRUE
	if(applied)
		add_history("[source]: [data_type] activity reduced matching technology costs")
	return applied

/datum/cyberpunk_corporation/proc/add_data(data_type, amount, source = "activity")
	data_type = lowertext(trim("[data_type]")) || "general"
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	if(has_edict("[id]_self_analysis") || has_edict("[id]_self_diagnostics") || has_edict("[id]_self_statistics"))
		amount = max(1, round(amount * 1.25))
	research_data[data_type] = (research_data[data_type] || 0) + amount
	research_points += amount
	experience += amount
	apply_technology_discounts(data_type, amount, source)
	update_level()
	add_history("[source]: +[amount] [data_type] data, +[amount] RP")
	return TRUE

/datum/cyberpunk_corporation/proc/add_funds(amount, source = "activity")
	amount = round(amount)
	if(!amount)
		return FALSE
	var/datum/bank_account/account = ensure_account()
	account.adjust_money(amount, "Corporate funds: [source]")
	if(amount > 0 && id != CYBERPUNK_CORP_GOVERNMENT)
		var/tax = round(amount * CYBERPUNK_CORP_TAX_RATE)
		if(tax > 0)
			tax_debt += tax
			add_history("[source]: tax debt +[tax][MONEY_SYMBOL]")
	var/amount_prefix = amount >= 0 ? "+" : ""
	add_history("[source]: [amount_prefix][amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/charge_funds(amount, source = "expense")
	amount = max(0, round(amount))
	if(!amount)
		return TRUE
	var/datum/bank_account/account = ensure_account()
	if(!account || !account.adjust_money(-amount, "Corporate expense: [source]"))
		return FALSE
	add_history("[source]: -[amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/add_tax_debt(amount, source = "tax")
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	tax_debt += amount
	add_history("[source]: tax debt +[amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/pay_taxes(amount = 0, source = "tax payment")
	amount = round(amount || tax_debt)
	amount = clamp(amount, 0, tax_debt)
	if(amount <= 0)
		return FALSE
	var/datum/bank_account/account = ensure_account()
	if(!account || !account.adjust_money(-amount, "Corporate tax payment: [name]"))
		return FALSE
	SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(amount, "Corporate tax: [name]")
	tax_debt -= amount
	tax_paid += amount
	add_history("[source]: paid [amount][MONEY_SYMBOL] tax")
	return TRUE

/datum/cyberpunk_corporation/proc/update_level()
	level = clamp(1 + FLOOR(experience / CYBERPUNK_CORP_LEVEL_STEP, 1), 1, 5)

/datum/cyberpunk_corporation/proc/exchange_data_to_research(data_type, amount)
	data_type = lowertext(trim("[data_type]")) || "general"
	amount = clamp(round(amount), 0, research_data[data_type] || 0)
	if(!amount)
		return FALSE
	research_data[data_type] -= amount
	if(research_data[data_type] <= 0)
		research_data -= data_type
	research_points += amount
	experience += amount
	update_level()
	add_history("converted [amount] [data_type] data to research")
	return TRUE

/datum/cyberpunk_corporation/proc/exchange_research_to_funds(points)
	points = clamp(round(points), 0, research_points)
	if(!points)
		return FALSE
	research_points -= points
	add_funds(points * CYBERPUNK_CORP_RESEARCH_TO_CREDITS, "research exchange")
	add_history("converted [points] RP to [points * CYBERPUNK_CORP_RESEARCH_TO_CREDITS][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/get_technology(technology_id)
	for(var/list/technology as anything in technologies)
		if(technology["id"] == technology_id)
			return technology
	return null

/datum/cyberpunk_corporation/proc/get_foreign_technology_bonus()
	return min(0.25, length(stolen_technologies) * 0.05)

/datum/cyberpunk_corporation/proc/get_technology_cost(list/technology)
	if(!islist(technology))
		return 0
	var/technology_id = technology["id"]
	var/base_cost = technology["cost"] || 0
	var/activity_discount = min(technology_discount_points[technology_id] || 0, round(base_cost * 0.35))
	return max(0, round((base_cost - activity_discount) * (1 - get_foreign_technology_bonus())))

/datum/cyberpunk_corporation/proc/unlock_technology(technology_id)
	var/list/technology = get_technology(technology_id)
	if(!technology || unlocked_technologies[technology_id])
		return FALSE
	var/prereq = technology["prereq"]
	if(prereq && !unlocked_technologies[prereq])
		return FALSE
	var/cost = get_technology_cost(technology)
	if(research_points < cost)
		return FALSE
	research_points -= cost
	unlocked_technologies[technology_id] = TRUE
	technology_discount_points -= technology_id
	var/technology_name = technology["name"]
	add_history("unlocked technology: [technology_name]")
	SScyberpunk_corporations.refresh_cyberpunk_corporate_fabricators(id)
	return TRUE

/datum/cyberpunk_corporation/proc/choose_edict(edict_id)
	for(var/list/edict as anything in edicts)
		if(edict["id"] != edict_id)
			continue
		var/edict_level = edict["level"] || 1
		if(level < edict_level || active_edicts["[edict_level]"])
			return FALSE
		active_edicts["[edict_level]"] = edict_id
		var/edict_name = edict["name"]
		add_history("activated level [edict_level] edict: [edict_name]")
		return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/has_edict(edict_id)
	for(var/level_key in active_edicts)
		if(active_edicts[level_key] == edict_id)
			return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/has_technology(technology_id)
	return !!unlocked_technologies[technology_id]

/datum/cyberpunk_corporation/proc/subscribe(mob/living/user)
	if(!user)
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(user, user.get_bank_account())
	if(!character_key)
		return FALSE
	if(subscribers[character_key])
		return TRUE
	var/cost = get_subscription_cost()
	var/datum/bank_account/user_account = user.get_bank_account()
	if(cost && (!user_account || !user_account.adjust_money(-cost, "[name] subscription")))
		return FALSE
	subscribers[character_key] = user.real_name || user.name
	add_funds(cost, "subscription: [user.real_name || user.name]")
	add_data(get_primary_data_type(), 2, "subscription")
	add_history("[user.real_name || user.name] subscribed")
	return TRUE

/datum/cyberpunk_corporation/proc/is_subscribed(mob/living/user)
	if(!user)
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(user, user.get_bank_account())
	return !!subscribers[character_key]

/datum/cyberpunk_corporation/proc/get_subscription_cost()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return 150
		if(CYBERPUNK_CORP_RYAZNOV)
			return 125
		if(CYBERPUNK_CORP_STARLIGHT)
			return 100
	return 0

/datum/cyberpunk_corporation/proc/get_primary_data_type()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return "bio"
		if(CYBERPUNK_CORP_RYAZNOV)
			return "engineering"
		if(CYBERPUNK_CORP_STARLIGHT)
			return "market"
		if(CYBERPUNK_CORP_GOVERNMENT)
			return "civic"
	return "general"

/datum/cyberpunk_corporation/proc/get_service_cost(service_id, mob/living/user)
	var/subscribed = is_subscribed(user)
	switch(service_id)
		if("medical")
			return subscribed ? 75 : 150
		if("body")
			return subscribed ? 90 : 180
		if("stealth")
			return subscribed ? 60 : 130
		if("chemistry")
			return subscribed ? 70 : 140
		if("technical")
			return subscribed ? 60 : 125
		if("salvage")
			return subscribed ? 45 : 95
		if("fortify")
			return subscribed ? 80 : 160
		if("power")
			return subscribed ? 70 : 145
		if("delivery")
			return subscribed ? 40 : 100
		if("return")
			return 0
		if("transport")
			return subscribed ? 85 : 170
		if("influence")
			return subscribed ? 50 : 110
	return 0

/datum/cyberpunk_corporation/proc/can_request_service(service_id)
	var/required_technology = get_service_required_technology(service_id)
	if(required_technology && !can_use_technology(id, required_technology))
		return FALSE
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			if(service_id == "medical")
				return has_edict("benn_med_help") || has_edict("benn_med_observation") || has_edict("benn_med_insurance")
			if(service_id == "body")
				return has_edict("benn_gene_combo") || has_edict("benn_dna_storage")
			if(service_id == "stealth")
				return has_edict("benn_chem_recycling")
			if(service_id == "chemistry")
				return has_edict("benn_chem_synthesis") || has_edict("benn_chem_tuning")
		if(CYBERPUNK_CORP_RYAZNOV)
			if(service_id == "technical")
				return has_edict("ryaznov_field_support") || has_edict("ryaznov_tech_observation") || has_edict("ryaznov_tech_contract")
			if(service_id == "salvage")
				return has_edict("ryaznov_salvage_program") || has_edict("ryaznov_blueprint_archive")
			if(service_id == "fortify")
				return has_edict("ryaznov_mass_repair") || has_edict("ryaznov_blueprint_tuning")
			if(service_id == "power")
				return has_edict("ryaznov_power_tuning") || has_edict("ryaznov_field_support")
		if(CYBERPUNK_CORP_STARLIGHT)
			if(service_id == "delivery")
				return has_edict("starlight_log_help") || has_edict("starlight_cargo_tracking") || has_edict("starlight_trade_subscription")
			if(service_id == "return")
				return has_edict("starlight_return_program")
			if(service_id == "transport")
				return has_edict("starlight_trade_analysis") || has_edict("starlight_log_help")
			if(service_id == "influence")
				return has_edict("starlight_aggressive_ads")
	return FALSE

/datum/cyberpunk_corporation/proc/get_available_services_ui()
	var/list/services = list()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			services += cyberpunk_service_ui_entry("medical", "Medical aid", "Remote treatment and medical telemetry.", "truck-medical", can_request_service("medical"))
			services += cyberpunk_service_ui_entry("body", "Body stabilization", "Genetic stability and body retuning support.", "dna", can_request_service("body"))
			services += cyberpunk_service_ui_entry("stealth", "Stealth conditioning", "Short tactical stamina and signature support.", "user-ninja", can_request_service("stealth"))
			services += cyberpunk_service_ui_entry("chemistry", "Chemistry kit", "Combat chemistry starter delivery.", "flask", can_request_service("chemistry"))
		if(CYBERPUNK_CORP_RYAZNOV)
			services += cyberpunk_service_ui_entry("technical", "Technical support", "Nearby machine and structure repair.", "screwdriver-wrench", can_request_service("technical"))
			services += cyberpunk_service_ui_entry("salvage", "Salvage pack", "Industrial material and salvage delivery.", "recycle", can_request_service("salvage"))
			services += cyberpunk_service_ui_entry("fortify", "Field fortify", "Broad nearby integrity patch.", "shield", can_request_service("fortify"))
			services += cyberpunk_service_ui_entry("power", "Power tune", "Nearby machinery wear and power tuning.", "bolt", can_request_service("power"))
		if(CYBERPUNK_CORP_STARLIGHT)
			services += cyberpunk_service_ui_entry("delivery", "Delivery pack", "Courier pack to hands or turf.", "box", can_request_service("delivery"))
			services += cyberpunk_service_ui_entry("return", "Return program", "Sell a held non-Starlight item back into logistics.", "rotate-left", can_request_service("return"))
			services += cyberpunk_service_ui_entry("transport", "Transport ping", "Short tactical relocation request.", "location-arrow", can_request_service("transport"))
			services += cyberpunk_service_ui_entry("influence", "Influence pulse", "Mood and market telemetry pulse.", "bullhorn", can_request_service("influence"))
	return services

/proc/cyberpunk_service_ui_entry(service_id, label, description, icon, enabled = FALSE)
	return list(list(
		"id" = service_id,
		"label" = label,
		"description" = description,
		"icon" = icon,
		"enabled" = enabled,
	))

/datum/cyberpunk_corporation/proc/request_service(mob/living/user, service_id)
	if(!can_request_service(service_id) || !user)
		return FALSE
	var/cost = get_service_cost(service_id, user)
	var/datum/bank_account/user_account = user.get_bank_account()
	if(cost && (!user_account || !user_account.adjust_money(-cost, "[name] service: [service_id]")))
		return FALSE
	add_funds(cost, "service: [service_id]")
	add_data(get_primary_data_type(), is_subscribed(user) ? 4 : 2, "service request")
	add_history("[user.real_name || user.name] requested [service_id] service")
	if(!service_auto_enabled)
		var/datum/cyberpunk_corporate_service_request/request = SScyberpunk_corporations.create_cyberpunk_corporate_service_request(src, user, service_id, cost)
		if(request)
			to_chat(user, span_notice("[name] accepted service request #[request.id]. It is queued for corporate handling."))
			return TRUE
		return FALSE
	switch(service_id)
		if("medical")
			to_chat(user, span_notice("Benn medical support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("body")
			to_chat(user, span_notice("Benn body stabilization has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("stealth")
			to_chat(user, span_notice("Benn stealth conditioning has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("chemistry")
			to_chat(user, span_notice("Benn chemistry kit has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("technical")
			to_chat(user, span_notice("Ryaznov technical support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("salvage")
			to_chat(user, span_notice("Ryaznov salvage support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("fortify")
			to_chat(user, span_notice("Ryaznov fortification support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("power")
			to_chat(user, span_notice("Ryaznov power tuning has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("delivery")
			to_chat(user, span_notice("Starlight delivery has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("return")
			to_chat(user, span_notice("Starlight return program has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("transport")
			to_chat(user, span_notice("Starlight transport ping has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("influence")
			to_chat(user, span_notice("Starlight influence pulse has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
	return TRUE

/datum/cyberpunk_corporation/proc/to_ui_data(include_hidden = FALSE)
	if(hidden && !include_hidden)
		return null
	var/datum/bank_account/account = ensure_account()
	var/list/data_records = list()
	for(var/data_type in research_data)
		data_records += list(list("type" = data_type, "amount" = research_data[data_type]))
	var/list/technology_records = list()
	for(var/list/technology as anything in technologies)
		var/technology_id = technology["id"]
		var/prereq = technology["prereq"]
		var/base_cost = technology["cost"] || 0
		var/current_cost = get_technology_cost(technology)
		technology_records += list(list(
			"id" = technology_id,
			"name" = technology["name"],
			"tier" = technology["tier"],
			"cost" = current_cost,
			"baseCost" = base_cost,
			"discount" = max(0, base_cost - current_cost),
			"prereq" = prereq,
			"description" = technology["description"],
			"unlocked" = !!unlocked_technologies[technology_id],
			"canUnlock" = !unlocked_technologies[technology_id] && (!prereq || unlocked_technologies[prereq]) && research_points >= current_cost,
		))
	var/list/edict_records = list()
	for(var/list/edict as anything in edicts)
		var/edict_level = edict["level"] || 1
		var/edict_id = edict["id"]
		edict_records += list(list(
			"id" = edict_id,
			"name" = edict["name"],
			"level" = edict_level,
			"description" = edict["description"],
			"active" = active_edicts["[edict_level]"] == edict_id,
			"locked" = level < edict_level || (active_edicts["[edict_level]"] && active_edicts["[edict_level]"] != edict_id),
		))
	var/list/subsidiary_records = list()
	for(var/datum/cyberpunk_corporate_subsidiary/subsidiary as anything in subsidiaries)
		subsidiary_records += list(subsidiary.to_ui_data())
	return list(
		"id" = id,
		"name" = name,
		"group" = group,
		"direction" = direction,
		"combatDoctrine" = combat_doctrine,
		"hidden" = hidden,
		"subsidiaries" = subsidiary_records,
		"level" = level,
		"experience" = experience,
		"nextLevelAt" = level < 5 ? level * CYBERPUNK_CORP_LEVEL_STEP : null,
		"researchPoints" = research_points,
		"influence" = influence,
		"accountId" = account.account_id,
		"balance" = account.account_balance,
		"debt" = account.account_debt,
		"taxDebt" = tax_debt,
		"taxPaid" = tax_paid,
		"serviceAutoEnabled" = service_auto_enabled,
		"researchData" = data_records,
		"technologies" = technology_records,
		"edicts" = edict_records,
		"activeEdicts" = active_edicts,
		"subscribers" = length(subscribers),
		"subscriptionCost" = get_subscription_cost(),
		"serviceMedical" = can_request_service("medical"),
		"serviceTechnical" = can_request_service("technical"),
		"serviceDelivery" = can_request_service("delivery"),
		"services" = get_available_services_ui(),
		"serviceRequests" = SScyberpunk_corporations.get_cyberpunk_corporate_service_requests_ui(id),
		"contracts" = SScyberpunk_corporations.get_cyberpunk_corporate_contracts_ui(id),
		"vendors" = get_cyberpunk_corporate_vendors_ui(),
		"taxMonitor" = id == CYBERPUNK_CORP_GOVERNMENT ? SScyberpunk_corporations.get_cyberpunk_government_tax_monitor_ui() : null,
		"foreignTechBonus" = round(get_foreign_technology_bonus() * 100),
		"stolenTechnologies" = get_stolen_technologies_ui(),
		"stolenProgress" = get_stolen_progress_ui(),
		"history" = history,
	)
