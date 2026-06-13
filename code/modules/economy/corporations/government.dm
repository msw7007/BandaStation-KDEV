//CYBERPUNK CORPORATIONS - government monitoring helpers.

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_government_tax_monitor_ui()
	var/list/businesses = list()
	for(var/business_id in SScyberpunk_property.cyberpunk_businesses)
		var/datum/cyberpunk_business/business = SScyberpunk_property.cyberpunk_businesses[business_id]
		if(!business)
			continue
		businesses += list(list(
			"id" = business.id,
			"name" = business.name,
			"owner" = business.owner_name,
			"legal" = business.legal,
			"registeredTo" = business.registered_to,
			"taxDebt" = business.tax_debt,
			"taxPaid" = business.tax_paid,
			"balance" = business.get_account()?.account_balance || 0,
			"debt" = business.get_account()?.account_debt || 0,
			"area" = business.get_business_area()?.name || "none",
		))
	var/list/corporations = list()
	for(var/corporation_id in cyberpunk_corporations)
		if(corporation_id == CYBERPUNK_CORP_GOVERNMENT)
			continue
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(!corporation)
			continue
		corporations += list(list(
			"id" = corporation.id,
			"name" = corporation.name,
			"taxDebt" = corporation.tax_debt,
			"taxPaid" = corporation.tax_paid,
			"balance" = corporation.get_account()?.account_balance || 0,
			"debt" = corporation.get_account()?.account_debt || 0,
		))
	return list(
		"businesses" = businesses,
		"corporations" = corporations,
	)

