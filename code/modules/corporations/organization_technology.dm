GLOBAL_LIST_EMPTY(cy_organization_technology_datums)

/proc/get_cy_organization_technology(technology_type) as /datum/cy_organization_technology
	if(!ispath(technology_type, /datum/cy_organization_technology))
		return null

	var/datum/cy_organization_technology/technology = GLOB.cy_organization_technology_datums[technology_type]
	if(!technology)
		technology = new technology_type
		GLOB.cy_organization_technology_datums[technology_type] = technology

	return technology

/datum/cy_organization_technology
	var/name = "Unknown technology"
	var/id = "unknown"
	var/desc = ""
	var/cost = 0
	var/datum/cy_organization/required_organization_type
	var/list/required_technology_types = list()

/datum/cy_organization_technology/proc/can_unlock(datum/cy_organization/organization, free = FALSE)
	if(!organization)
		return FALSE

	var/datum/cy_organization/owner = organization.get_progress_owner()
	if(type in owner.unlocked_technology_types)
		return FALSE

	if(required_organization_type && !owner.is_same_or_child_of(required_organization_type))
		return FALSE

	for(var/required_technology_type in required_technology_types)
		if(!(required_technology_type in owner.unlocked_technology_types))
			return FALSE

	if(!free && owner.research_points < cost)
		return FALSE

	return TRUE

/datum/cy_organization_technology/ben_medical_baseline
	name = "Базовая мед-сеть Бэнь"
	id = "ben_medical_baseline"
	desc = "Автоматы, анализаторы и базовые медицинские сервисы Бэнь."
	cost = 50
	required_organization_type = /datum/cy_organization/corporation/ben

/datum/cy_organization_technology/ben_gene_registry
	name = "Генная регистрация"
	id = "ben_gene_registry"
	desc = "Сбор генетических данных через сервисы и автоматы Бэнь."
	cost = 120
	required_organization_type = /datum/cy_organization/corporation/ben
	required_technology_types = list(/datum/cy_organization_technology/ben_medical_baseline)

/datum/cy_organization_technology/ryaznov_engineering_baseline
	name = "Базовая инженерная сеть Рязнова"
	id = "ryaznov_engineering_baseline"
	desc = "Инструменты, ремонтные терминалы и базовое инженерное обслуживание."
	cost = 50
	required_organization_type = /datum/cy_organization/corporation/ryaznov

/datum/cy_organization_technology/ryaznov_modular_assembly
	name = "Модульная сборка"
	id = "ryaznov_modular_assembly"
	desc = "Сокращение времени и стоимости сборки оружия, брони, ригов, турелей и техники."
	cost = 120
	required_organization_type = /datum/cy_organization/corporation/ryaznov
	required_technology_types = list(/datum/cy_organization_technology/ryaznov_engineering_baseline)

/datum/cy_organization_technology/starlight_logistics_baseline
	name = "Базовая логистическая сеть Старлайт"
	id = "starlight_logistics_baseline"
	desc = "Автоматы, поставки, терминалы заказов и базовая доставка."
	cost = 50
	required_organization_type = /datum/cy_organization/corporation/starlight

/datum/cy_organization_technology/starlight_route_archive
	name = "Архив маршрутов"
	id = "starlight_route_archive"
	desc = "Сбор маршрутных данных, ускорение транспорта и сканирование чужих технологий."
	cost = 120
	required_organization_type = /datum/cy_organization/corporation/starlight
	required_technology_types = list(/datum/cy_organization_technology/starlight_logistics_baseline)
