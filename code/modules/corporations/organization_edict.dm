GLOBAL_LIST_EMPTY(cy_organization_edict_datums)

/proc/get_cy_organization_edict(edict_type) as /datum/cy_organization_edict
	if(!ispath(edict_type, /datum/cy_organization_edict))
		return null

	var/datum/cy_organization_edict/edict = GLOB.cy_organization_edict_datums[edict_type]
	if(!edict)
		edict = new edict_type
		GLOB.cy_organization_edict_datums[edict_type] = edict

	return edict

/datum/cy_organization_edict
	var/name = "Unknown edict"
	var/id = "unknown"
	var/desc = ""
	var/level = 1
	var/datum/cy_organization/required_organization_type

/datum/cy_organization_edict/proc/can_choose(datum/cy_organization/organization)
	if(!organization)
		return FALSE

	var/datum/cy_organization/owner = organization.get_progress_owner()
	if(type in owner.chosen_edict_types)
		return FALSE

	if(owner.has_chosen_edict_level(level))
		return FALSE

	if(owner.round_level < level)
		return FALSE

	if(required_organization_type && !owner.is_same_or_child_of(required_organization_type))
		return FALSE

	return TRUE

/datum/cy_organization_edict/ben_med_insurance
	name = "Мед-Страховка"
	id = "ben_med_insurance"
	desc = "Жители могут покупать страховку Бэнь и получать расширенный ассортимент лекарств."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/ben

/datum/cy_organization_edict/ben_self_analysis
	name = "Само-анализ"
	id = "ben_self_analysis"
	desc = "Анализы, операции и покупки медтоваров дают Бэнь биоданные."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/ben

/datum/cy_organization_edict/ryaznov_tech_contract
	name = "Тех-Договор"
	id = "ryaznov_tech_contract"
	desc = "Жители и бизнесы получают доступ к расширенному инженерному обслуживанию Рязнова."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/ryaznov

/datum/cy_organization_edict/ryaznov_self_diagnostics
	name = "Самодиагностика"
	id = "ryaznov_self_diagnostics"
	desc = "Ремонты, диагностика и покупки инструментов дают Рязнову инженерные данные."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/ryaznov

/datum/cy_organization_edict/starlight_trade_subscription
	name = "Торговая подписка"
	id = "starlight_trade_subscription"
	desc = "Подписчики Старлайт получают ускоренную доставку и сдачу контрактов через автоматы."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/starlight

/datum/cy_organization_edict/starlight_self_statistics
	name = "Само-статистика"
	id = "starlight_self_statistics"
	desc = "Покупки, доставки и контракты дают Старлайт рыночные данные."
	level = 1
	required_organization_type = /datum/cy_organization/corporation/starlight
