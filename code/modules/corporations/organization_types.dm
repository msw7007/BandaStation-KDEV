/datum/cy_organization/neutral
	name = "Нейтральные"
	id = "neutral"
	desc = "Нет выраженной корпоративной или идеологической приверженности."
	organization_kind = CY_ORGANIZATION_KIND_NEUTRAL
	tech_tags = list()

/datum/cy_organization/corporation
	organization_kind = CY_ORGANIZATION_KIND_CORPORATION

/datum/cy_organization/corporation/ben
	name = "Конгломерат Бэнь"
	id = "ben"
	desc = "Азиатская группа: медицина, генетика, химия, скрытность, точность и скорость."
	tech_tags = list(CY_TECH_TAG_MEDICAL, CY_TECH_TAG_GENETIC, CY_TECH_TAG_CHEMICAL, CY_TECH_TAG_STEALTH, CY_TECH_TAG_PRECISION, CY_TECH_TAG_SPEED)
	uses_round_progression = TRUE
	available_technology_types = list(
		/datum/cy_organization_technology/ben_medical_baseline,
		/datum/cy_organization_technology/ben_gene_registry,
	)
	available_edict_types = list(
		/datum/cy_organization_edict/ben_med_insurance,
		/datum/cy_organization_edict/ben_self_analysis,
	)

/datum/cy_organization/corporation/ben/san_yon
	name = "Сан Йон Корпорейшн"
	id = "san_yon"
	desc = "Дочерняя корпорация Бэнь: точность, дальнее оружие, одиночные демоны и стабилизация."
	parent_organization = /datum/cy_organization/corporation/ben
	tech_tags = list(CY_TECH_TAG_PRECISION, CY_TECH_TAG_MEDICAL)

/datum/cy_organization/corporation/ben/ishikawa
	name = "Ишикава Индастриз"
	id = "ishikawa"
	desc = "Дочерняя корпорация Бэнь: скрытность, маскировка, подавление сигнатур."
	parent_organization = /datum/cy_organization/corporation/ben
	tech_tags = list(CY_TECH_TAG_STEALTH, CY_TECH_TAG_SPEED)

/datum/cy_organization/corporation/ben/ho_shi
	name = "Хо Ши Текнолоджис"
	id = "ho_shi"
	desc = "Дочерняя корпорация Бэнь: скорость, ускорение, мобильность, быстрые демоны."
	parent_organization = /datum/cy_organization/corporation/ben
	tech_tags = list(CY_TECH_TAG_SPEED, CY_TECH_TAG_STEALTH)

/datum/cy_organization/corporation/ryaznov
	name = "Союз Рязнов"
	id = "ryaznov"
	desc = "Европейская группа: инженерия, броня, сила, надежность, тяжелая техника и разрушение."
	tech_tags = list(CY_TECH_TAG_ENGINEERING, CY_TECH_TAG_ARMOR, CY_TECH_TAG_FORCE, CY_TECH_TAG_RELIABILITY, CY_TECH_TAG_AOE, CY_TECH_TAG_SHIELDS)
	uses_round_progression = TRUE
	available_technology_types = list(
		/datum/cy_organization_technology/ryaznov_engineering_baseline,
		/datum/cy_organization_technology/ryaznov_modular_assembly,
	)
	available_edict_types = list(
		/datum/cy_organization_edict/ryaznov_tech_contract,
		/datum/cy_organization_edict/ryaznov_self_diagnostics,
	)

/datum/cy_organization/corporation/ryaznov/kowalski
	name = "Ковальски и Ко"
	id = "kowalski"
	desc = "Дочерняя корпорация Рязнова: надежность, износостойкость, стабильность и перегрузка."
	parent_organization = /datum/cy_organization/corporation/ryaznov
	tech_tags = list(CY_TECH_TAG_RELIABILITY, CY_TECH_TAG_ENGINEERING, CY_TECH_TAG_ARMOR)

/datum/cy_organization/corporation/ryaznov/tyazhmarsh
	name = "ТяжМарш Продакшен"
	id = "tyazhmarsh"
	desc = "Дочерняя корпорация Рязнова: поражение по площади, тяжелое оружие, клив и конусные атаки."
	parent_organization = /datum/cy_organization/corporation/ryaznov
	tech_tags = list(CY_TECH_TAG_AOE, CY_TECH_TAG_FORCE, CY_TECH_TAG_ARMOR)

/datum/cy_organization/corporation/ryaznov/tesla
	name = "Тесла Саенс"
	id = "tesla_science"
	desc = "Дочерняя корпорация Рязнова: силовые эффекты, щиты, рывки, броски и энергетическая защита."
	parent_organization = /datum/cy_organization/corporation/ryaznov
	tech_tags = list(CY_TECH_TAG_FORCE, CY_TECH_TAG_SHIELDS, CY_TECH_TAG_ENGINEERING)

/datum/cy_organization/corporation/starlight
	name = "Объединение Старлайт"
	id = "starlight"
	desc = "Северо-американская группа: логистика, транспорт, массовость, контроль, влияние и телепортация."
	tech_tags = list(CY_TECH_TAG_LOGISTICS, CY_TECH_TAG_TRANSPORT, CY_TECH_TAG_CONTROL, CY_TECH_TAG_TELEPORT, CY_TECH_TAG_INFLUENCE, CY_TECH_TAG_MASS_PRODUCTION)
	uses_round_progression = TRUE
	available_technology_types = list(
		/datum/cy_organization_technology/starlight_logistics_baseline,
		/datum/cy_organization_technology/starlight_route_archive,
	)
	available_edict_types = list(
		/datum/cy_organization_edict/starlight_trade_subscription,
		/datum/cy_organization_edict/starlight_self_statistics,
	)

/datum/cy_organization/corporation/starlight/blackrock
	name = "Блэкрок Инвестигейт"
	id = "blackrock"
	desc = "Дочерняя корпорация Старлайт: контроль, замедление, дебаффы и сопротивление контролю."
	parent_organization = /datum/cy_organization/corporation/starlight
	tech_tags = list(CY_TECH_TAG_CONTROL, CY_TECH_TAG_INFLUENCE)

/datum/cy_organization/corporation/starlight/trans_travel
	name = "Транс Трэвел"
	id = "trans_travel"
	desc = "Дочерняя корпорация Старлайт: массовость, транспорт, телепортация, реколл и распространение эффектов."
	parent_organization = /datum/cy_organization/corporation/starlight
	tech_tags = list(CY_TECH_TAG_TRANSPORT, CY_TECH_TAG_TELEPORT, CY_TECH_TAG_MASS_PRODUCTION)

/datum/cy_organization/corporation/starlight/samanthas_care
	name = "Самантас Кеир"
	id = "samanthas_care"
	desc = "Дочерняя корпорация Старлайт: влияние, психика, эмоции, социальные баффы и дебаффы."
	parent_organization = /datum/cy_organization/corporation/starlight
	tech_tags = list(CY_TECH_TAG_INFLUENCE, CY_TECH_TAG_CONTROL)

/datum/cy_organization/government
	name = "Правительство"
	id = "government"
	desc = "Скрытая четвертая сила города: контроль, налоги, полиция, ЧС и корабль правительства."
	organization_kind = CY_ORGANIZATION_KIND_GOVERNMENT
	tech_tags = list(CY_TECH_TAG_CONTROL, CY_TECH_TAG_LOGISTICS, CY_TECH_TAG_SHIELDS)

/datum/cy_organization/anarchy
	name = "Анархия"
	id = "anarchy"
	desc = "Антикорпоративные и антиправительственные группы."
	organization_kind = CY_ORGANIZATION_KIND_CRIMINAL
	tech_tags = list()

/datum/cy_organization/wild
	name = "Дикие"
	id = "wild"
	desc = "Пустошные, природные и некорпоративные существа."
	organization_kind = CY_ORGANIZATION_KIND_WILD
	tech_tags = list()
	can_have_player_allegiance = FALSE

/datum/cy_organization/mutant
	name = "Мутанты"
	id = "mutant"
	desc = "Биологические угрозы и порождения мутаций."
	organization_kind = CY_ORGANIZATION_KIND_THREAT
	tech_tags = list(CY_TECH_TAG_GENETIC, CY_TECH_TAG_CHEMICAL)
	can_have_player_allegiance = FALSE

/datum/cy_organization/construct
	name = "Конструкты"
	id = "construct"
	desc = "Механические самосборные сущности, связанные с техногенными угрозами."
	organization_kind = CY_ORGANIZATION_KIND_THREAT
	tech_tags = list(CY_TECH_TAG_ENGINEERING, CY_TECH_TAG_ARMOR)
	can_have_player_allegiance = FALSE

/datum/cy_organization/swarm
	name = "Рой"
	id = "swarm"
	desc = "Энергетические и иномирные сущности, связанные с плазмой и стабилизацией пилонов."
	organization_kind = CY_ORGANIZATION_KIND_THREAT
	tech_tags = list(CY_TECH_TAG_TELEPORT, CY_TECH_TAG_CONTROL)
	can_have_player_allegiance = FALSE
