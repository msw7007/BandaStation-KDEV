//CYBERPUNK CORPORATIONS - corporations UI bridge.
/proc/cyberpunk_corporations_ui_data(mob/user, selected_corporation_id = null, locked_corporation_id = null)
	SScyberpunk_corporations.ensure_cyberpunk_corporations_seeded()
	var/mob/living/living_user = isliving(user) ? user : null
	var/list/corporations = list()
	var/locked_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(locked_corporation_id)
	var/selected_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(selected_corporation_id)
	if(locked_id && selected_id != locked_id)
		selected_id = locked_id
	var/datum/cyberpunk_corporation/selected_corporation
	for(var/corporation_id in SScyberpunk_corporations.cyberpunk_corporations)
		if(locked_id && corporation_id != locked_id)
			continue
		var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.cyberpunk_corporations[corporation_id]
		var/list/corporation_data = corporation.to_ui_data(TRUE)
		if(!corporation_data)
			continue
		corporations += list(corporation_data)
		if(corporation.id == selected_id)
			selected_corporation = corporation
	if(!selected_corporation && length(corporations))
		var/list/first_corporation = corporations[1]
		selected_corporation = SScyberpunk_corporations.cyberpunk_corporations[first_corporation["id"]]
	var/datum/bank_account/user_account = living_user?.get_bank_account()
	return list(
		"accountName" = user_account?.account_holder,
		"accountBalance" = user_account?.account_balance || 0,
		"corporations" = corporations,
		"selected" = selected_corporation?.to_ui_data(TRUE),
	)

/proc/cyberpunk_corporations_ui_act(action, list/params, mob/user)
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(params && params["corporation_id"])
	if(!corporation)
		return FALSE
	switch(action)
		if("select")
			return TRUE
		if("unlock_technology")
			if(corporation.unlock_technology(params["technology_id"]))
				to_chat(user, span_notice("[corporation.name] unlocked a technology."))
			else
				to_chat(user, span_warning("Unable to unlock this technology."))
			return TRUE
		if("choose_edict")
			if(corporation.choose_edict(params["edict_id"]))
				to_chat(user, span_notice("[corporation.name] activated a corporate decision."))
			else
				to_chat(user, span_warning("Unable to activate this corporate decision."))
			return TRUE
		if("convert_data")
			if(corporation.exchange_data_to_research(params["data_type"], text2num(params["amount"])))
				to_chat(user, span_notice("[corporation.name] converted data to research."))
			else
				to_chat(user, span_warning("Unable to convert this data."))
			return TRUE
		if("exchange_research")
			if(corporation.exchange_research_to_funds(text2num(params["amount"])))
				to_chat(user, span_notice("[corporation.name] exchanged research for funds."))
			else
				to_chat(user, span_warning("Unable to exchange research."))
			return TRUE
		if("toggle_service_auto")
			corporation.service_auto_enabled = !corporation.service_auto_enabled
			corporation.add_history("[user?.name || "system"] toggled automatic services [corporation.service_auto_enabled ? "on" : "off"]")
			return TRUE
		if("complete_service_request")
			var/datum/cyberpunk_corporate_service_request/request = SScyberpunk_corporations.get_cyberpunk_corporate_service_request(text2num(params["request_id"]))
			if(request?.corporation_id == corporation.id && request.complete())
				to_chat(user, span_notice("Service request completed."))
			else
				to_chat(user, span_warning("Unable to complete this service request."))
			return TRUE
		if("cancel_service_request")
			var/datum/cyberpunk_corporate_service_request/request = SScyberpunk_corporations.get_cyberpunk_corporate_service_request(text2num(params["request_id"]))
			if(request?.corporation_id == corporation.id && request.cancel("cancelled from corporate terminal"))
				to_chat(user, span_notice("Service request cancelled."))
			else
				to_chat(user, span_warning("Unable to cancel this service request."))
			return TRUE
		if("create_corporate_contract")
			var/datum/cyberpunk_contract/contract = corporation.create_corporate_contract(params["contract_type"])
			if(contract)
				to_chat(user, span_notice("Corporate contract #[contract.id] created."))
			else
				to_chat(user, span_warning("Unable to fund a corporate contract."))
			return TRUE
		if("pay_corporate_taxes")
			if(corporation.pay_taxes(text2num(params["amount"]), user?.name || "corporate terminal"))
				to_chat(user, span_notice("[corporation.name] paid corporate taxes."))
			else
				to_chat(user, span_warning("Unable to pay corporate taxes."))
			return TRUE
		if("government_transfer")
			if(corporation.id != CYBERPUNK_CORP_GOVERNMENT)
				return FALSE
			var/amount = clamp(round(text2num(params["amount"]) || 0), 1, 1000000)
			if(SScyberpunk_corporations.force_cyberpunk_government_transfer(params["source_kind"], params["source_id"], params["target_kind"], params["target_id"], amount, user?.name || "government terminal"))
				to_chat(user, span_notice("Government transfer completed."))
			else
				to_chat(user, span_warning("Unable to complete government transfer."))
			return TRUE
		if("set_tax_setting")
			if(corporation.id != CYBERPUNK_CORP_GOVERNMENT)
				return FALSE
			if(SScyberpunk_corporations.set_cyberpunk_tax_setting(params["kind"], params["target"], text2num(params["value"])))
				to_chat(user, span_notice("Government tax setting updated."))
			else
				to_chat(user, span_warning("Unable to update this tax setting."))
			return TRUE
		if("charge_housing_rent")
			if(corporation.id != CYBERPUNK_CORP_GOVERNMENT)
				return FALSE
			var/list/result = SScyberpunk_corporations.charge_cyberpunk_housing_rent(params["area_key"], user?.name || "government terminal")
			if(result && result["charged"])
				to_chat(user, span_notice("Housing rent charged: [result["charged"]] account(s), [result["total"]][MONEY_SYMBOL]."))
			else
				to_chat(user, span_warning("No housing rent was charged."))
			return TRUE
		if("invest_foreign_tech")
			var/points = max(CYBERPUNK_CORP_RESEARCH_TO_FOREIGN_PROGRESS_COST, round(text2num(params["points"]) || CYBERPUNK_CORP_RESEARCH_TO_FOREIGN_PROGRESS_COST))
			if(corporation.invest_research_into_foreign_technology(params["source"], params["technology_id"], points))
				to_chat(user, span_notice("[corporation.name] assimilated foreign technology data."))
			else
				to_chat(user, span_warning("Unable to assimilate this foreign technology."))
			return TRUE
		if("test_activity")
			var/data_type = reject_bad_text(params["data_type"], max_length = 32, ascii_only = TRUE) || "general"
			var/amount = clamp(round(text2num(params["amount"]) || 10), 1, 1000)
			var/test_source_name = user?.name || "system"
			corporation.add_data(data_type, amount, "[test_source_name] test activity")
			return TRUE
	return FALSE
