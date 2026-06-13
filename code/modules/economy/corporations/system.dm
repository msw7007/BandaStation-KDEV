//CYBERPUNK CORPORATIONS - subsystem-facing registry helpers.
/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporation(corporation_id)
	ensure_cyberpunk_corporations_seeded()
	return cyberpunk_corporations[cyberpunk_normalize_corporation_id(corporation_id)]

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_normalize_corporation_id(corporation_id)
	var/corp_id = lowertext(trim("[corporation_id]"))
	switch(corp_id)
		if("benn", "ben", "bСЌРЅ", "Р±СЌРЅСЊ")
			return CYBERPUNK_CORP_BENN
		if("ryaznov", "riaznov", "СЂСЏР·РЅРѕРІ")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight", "СЃС‚Р°СЂР»Р°Р№С‚")
			return CYBERPUNK_CORP_STARLIGHT
		if("government", "gov", "nanotrasen", "РїСЂР°РІРёС‚РµР»СЊСЃС‚РІРѕ")
			return CYBERPUNK_CORP_GOVERNMENT
	return corp_id

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_public_corporation_names(include_government = FALSE)
	ensure_cyberpunk_corporations_seeded()
	var/list/names = list()
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation.hidden && !include_government)
			continue
		names += corporation.name
	return names

/datum/controller/subsystem/cyberpunk_corporations/proc/ensure_cyberpunk_corporations_seeded()
	if(cyberpunk_corporations_seeded)
		return
	cyberpunk_corporations_seeded = TRUE
	create_cyberpunk_corporation(CYBERPUNK_CORP_BENN)
	create_cyberpunk_corporation(CYBERPUNK_CORP_RYAZNOV)
	create_cyberpunk_corporation(CYBERPUNK_CORP_STARLIGHT)
	create_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)

/datum/controller/subsystem/cyberpunk_corporations/proc/create_cyberpunk_corporation(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	if(cyberpunk_corporations[corporation_id])
		return cyberpunk_corporations[corporation_id]
	var/datum/cyberpunk_corporation/corporation = new(corporation_id)
	corporation.ensure_account()
	cyberpunk_corporations[corporation_id] = corporation
	return corporation

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_corporate_activity(corporation_id, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	if(data_amount)
		corporation.add_data(data_type, data_amount, source)
	if(credit_amount)
		corporation.add_funds(credit_amount, source)
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_id_from_manufacturer(manufacturer)
	var/manufacturer_id = cyberpunk_normalize_corporation_id(manufacturer)
	if(cyberpunk_corporations[manufacturer_id])
		return manufacturer_id
	var/manufacturer_group = cyberpunk_major_corp_for_manufacturer(manufacturer)
	switch(manufacturer_group)
		if("ben")
			return CYBERPUNK_CORP_BENN
		if("ryaznov")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight")
			return CYBERPUNK_CORP_STARLIGHT
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation?.get_subsidiary_by_manufacturer(manufacturer_text))
			return corporation_id
	if(findtext(manufacturer_text, "benn") || findtext(manufacturer_text, "ben"))
		return CYBERPUNK_CORP_BENN
	if(findtext(manufacturer_text, "ryaznov") || findtext(manufacturer_text, "riaznov"))
		return CYBERPUNK_CORP_RYAZNOV
	if(findtext(manufacturer_text, "starlight"))
		return CYBERPUNK_CORP_STARLIGHT
	if(findtext(manufacturer_text, "government") || findtext(manufacturer_text, "nanotrasen"))
		return CYBERPUNK_CORP_GOVERNMENT
	return null

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_has_edict(corporation_id, edict_id)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	return corporation?.has_edict(edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_manufacturer_has_edict(manufacturer, edict_id)
	return cyberpunk_corporation_has_edict(cyberpunk_corporation_id_from_manufacturer(manufacturer), edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_manufacturer_activity(manufacturer, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	return record_cyberpunk_corporate_activity(cyberpunk_corporation_id_from_manufacturer(manufacturer), data_type, data_amount, credit_amount, source)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporate_edict_multiplier(manufacturer, list/edict_ids, default_multiplier = 1, active_multiplier = 1.1)
	var/corporation_id = cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return default_multiplier
	for(var/edict_id in edict_ids)
		if(cyberpunk_corporation_has_edict(corporation_id, edict_id))
			return active_multiplier
	return default_multiplier
