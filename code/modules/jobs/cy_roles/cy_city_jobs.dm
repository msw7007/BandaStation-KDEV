/// Cyberpunk city roles. These are ordinary jobs with city-role metadata attached;
/// no parallel role subsystem is created here.

/datum/job/cy_city_base
	faction = FACTION_STATION
	exp_granted_type = EXP_TYPE_CREW
	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_CIV
	outfit = /datum/outfit/job/cy_city_base
	job_flags = JOB_HIDE_WHEN_EMPTY
	total_positions = 0
	spawn_positions = 0
	allow_bureaucratic_error = FALSE
	random_spawns_possible = FALSE

/datum/outfit/job/cy_city_base
	name = "City Role"
	jobtype = /datum/job/cy_city_base
	id_trim = /datum/id_trim/job/assistant
	belt = /obj/item/modular_computer/pda/assistant

// ---------------------------------------------------------------------------
// Residents

/datum/job/cy_business_owner
	parent_type = /datum/job/cy_city_base
	title = JOB_CY_BUSINESS_OWNER
	description = "Откройте или загрузите бизнес, наймите работников, ведите склад, платите налоги и держите предприятие на плаву."
	supervisors = "городскими законами, налогами и собственными долгами"
	total_positions = 8
	spawn_positions = 8
	paycheck_department = ACCOUNT_CIV
	display_order = JOB_DISPLAY_ORDER_CY_BUSINESS_OWNER
	department_for_prefs = /datum/job_department/cy_residents
	departments_list = list(/datum/job_department/cy_residents)
	config_tag = "CY_BUSINESS_OWNER"
	outfit = /datum/outfit/job/cy_business_owner
	cy_role_group = CY_ROLE_GROUP_RESIDENT
	cy_role_id = "business_owner"
	cy_role_flags = CY_ROLE_FLAG_BUSINESS_OWNER
	cy_city_account_id = CY_ACCOUNT_CIV_MARKET
	cy_can_manage_budget = FALSE
	cy_role_stat_modifiers = list(/datum/cy_stat/charisma = 1)
	cy_role_expectations = list("Create, load and maintain a city business.", "Hire workers, manage stock and taxes, and protect your property.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_BEGINNER, /datum/cy_skill/charisma/style = CY_SKILL_LEVEL_BEGINNER)
	job_flags = STATION_JOB_FLAGS

/datum/outfit/job/cy_business_owner
	parent_type = /datum/outfit/job/cy_city_base
	name = JOB_CY_BUSINESS_OWNER
	jobtype = /datum/job/cy_business_owner

/datum/job/cy_official
	parent_type = /datum/job/cy_city_base
	title = JOB_CY_OFFICIAL
	description = "Ведите городские бумаги, балансы, налоги, сальдо, обращения жителей и экономические решения правительства."
	supervisors = "городским советом"
	total_positions = 4
	spawn_positions = 4
	paycheck_department = ACCOUNT_SEC
	paycheck = PAYCHECK_COMMAND
	display_order = JOB_DISPLAY_ORDER_CY_OFFICIAL
	department_for_prefs = /datum/job_department/cy_residents
	departments_list = list(/datum/job_department/cy_residents)
	config_tag = "CY_OFFICIAL"
	outfit = /datum/outfit/job/cy_official
	cy_role_group = CY_ROLE_GROUP_RESIDENT
	cy_role_id = "official"
	cy_role_flags = CY_ROLE_FLAG_GOVERNMENT_OFFICIAL
	cy_city_account_id = CY_ACCOUNT_GOVERNMENT
	cy_police_database_access = TRUE
	cy_can_issue_warrants = TRUE
	cy_can_manage_budget = TRUE
	cy_role_stat_modifiers = list(/datum/cy_stat/intelligence = 1, /datum/cy_stat/charisma = 1)
	cy_role_expectations = list("Maintain paperwork, taxes, budgets and city dispute records.", "Use the legal database to issue fines or warrants when city law requires it.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/charisma/inspiration = CY_SKILL_LEVEL_BEGINNER)
	job_flags = STATION_JOB_FLAGS

/datum/outfit/job/cy_official
	parent_type = /datum/outfit/job/lawyer
	name = JOB_CY_OFFICIAL
	jobtype = /datum/job/cy_official

/datum/job/cy_officer
	parent_type = /datum/job/security_officer
	title = JOB_CY_OFFICER
	description = "Патрулируйте город, работайте с камерами, базой нарушений, розыском, задержаниями и защитой чиновников."
	supervisors = "городским советом и старшими офицерами"
	total_positions = 8
	spawn_positions = 8
	paycheck_department = ACCOUNT_SEC
	display_order = JOB_DISPLAY_ORDER_CY_OFFICER
	department_for_prefs = /datum/job_department/cy_residents
	departments_list = list(/datum/job_department/cy_residents)
	config_tag = "CY_OFFICER"
	cy_role_group = CY_ROLE_GROUP_RESIDENT
	cy_role_id = "officer"
	cy_role_flags = CY_ROLE_FLAG_POLICE
	cy_city_account_id = CY_ACCOUNT_GOVERNMENT
	cy_police_database_access = TRUE
	cy_can_issue_warrants = TRUE
	cy_role_stat_modifiers = list(/datum/cy_stat/perception = 1)
	cy_role_expectations = list("Patrol the city, respond to incidents and protect officials.", "Use arrests, fines and force as legal tools, not as random violence.")
	cy_role_skill_levels = list(/datum/cy_skill/weapon/light_firearms = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/dexterity/light_weapons = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/perception/concentration = CY_SKILL_LEVEL_BEGINNER)
	job_flags = STATION_JOB_FLAGS

/datum/job/cy_council_member
	parent_type = /datum/job/cy_city_base
	title = JOB_CY_COUNCIL_MEMBER
	description = "Принимайте решения городского совета, управляйте бюджетом, налогами и чрезвычайными политическими решениями."
	supervisors = "городом и собственными голосами совета"
	total_positions = 4
	spawn_positions = 4
	paycheck_department = ACCOUNT_SEC
	paycheck = PAYCHECK_COMMAND
	display_order = JOB_DISPLAY_ORDER_CY_COUNCIL_MEMBER
	department_for_prefs = /datum/job_department/cy_residents
	departments_list = list(/datum/job_department/cy_residents)
	config_tag = "CY_COUNCIL_MEMBER"
	outfit = /datum/outfit/job/cy_council_member
	cy_role_group = CY_ROLE_GROUP_RESIDENT
	cy_role_id = "council_member"
	cy_role_flags = CY_ROLE_FLAG_COUNCIL | CY_ROLE_FLAG_GOVERNMENT_OFFICIAL
	cy_city_account_id = CY_ACCOUNT_GOVERNMENT
	cy_police_database_access = TRUE
	cy_can_issue_warrants = TRUE
	cy_can_manage_budget = TRUE
	cy_role_stat_modifiers = list(/datum/cy_stat/intelligence = 1, /datum/cy_stat/charisma = 1)
	cy_role_expectations = list("Represent the city council, manage emergency policy and negotiate with corporations.", "Your decisions create city-level consequences for residents and police.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/charisma/inspiration = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/charisma/style = CY_SKILL_LEVEL_BEGINNER)
	job_flags = STATION_JOB_FLAGS | HEAD_OF_STAFF_JOB_FLAGS | JOB_ANTAG_PROTECTED

/datum/outfit/job/cy_council_member
	parent_type = /datum/outfit/job/captain
	name = JOB_CY_COUNCIL_MEMBER
	jobtype = /datum/job/cy_council_member

// ---------------------------------------------------------------------------
// Corporates

/datum/job/cy_corporate_base
	parent_type = /datum/job/cy_city_base
	cy_role_group = CY_ROLE_GROUP_CORPORATE
	department_for_prefs = /datum/job_department/cy_corporate
	departments_list = list(/datum/job_department/cy_corporate)
	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_CAR
	cy_can_manage_budget = FALSE
	cy_role_stat_modifiers = list(/datum/cy_stat/intelligence = 1)
	job_flags = JOB_HIDE_WHEN_EMPTY
	total_positions = 0
	spawn_positions = 0

/datum/job/cy_corporate_trainee
	parent_type = /datum/job/cy_corporate_base
	title = JOB_CY_CORPORATE_TRAINEE
	description = "Учитесь работе корпорации. Доступы минимальны, серьёзные полномочия выдаются старшими сотрудниками."
	supervisors = "сотрудниками своей корпорации"
	total_positions = 9
	spawn_positions = 9
	display_order = JOB_DISPLAY_ORDER_CY_CORPORATE_TRAINEE
	config_tag = "CY_CORPORATE_TRAINEE"
	outfit = /datum/outfit/job/cy_corporate_trainee
	cy_role_id = "corporate_trainee"
	cy_role_flags = CY_ROLE_FLAG_CORPORATE_TRAINEE
	cy_city_account_id = CY_ACCOUNT_CIV_MARKET
	cy_role_expectations = list("Learn the corporation's work and request access from senior employees.", "You start with minimal authority and should be used for onboarding.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_BEGINNER)

/datum/outfit/job/cy_corporate_trainee
	parent_type = /datum/outfit/job/cy_city_base
	name = JOB_CY_CORPORATE_TRAINEE
	jobtype = /datum/job/cy_corporate_trainee

/datum/job/cy_corp_agent_base
	parent_type = /datum/job/cy_corporate_base
	description = "Защищайте свою корпорацию, внедряйтесь, саботируйте, охраняйте специалистов и перехватывайте чужие грузы."
	job_flags = JOB_HIDE_WHEN_EMPTY
	total_positions = 0
	spawn_positions = 0
	paycheck = PAYCHECK_COMMAND
	cy_role_flags = CY_ROLE_FLAG_CORPORATE_AGENT
	outfit = /datum/outfit/job/cy_corp_agent_base
	cy_role_stat_modifiers = list(/datum/cy_stat/dexterity = 1, /datum/cy_stat/perception = 1)
	cy_role_expectations = list("Protect your corporation, raid hostile assets, escort specialists and intercept hostile cargo.", "You are the corporation's combat and stealth arm.")
	cy_role_skill_levels = list(/datum/cy_skill/charisma/stealth = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/dexterity/light_weapons = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/light_firearms = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/knives = CY_SKILL_LEVEL_BEGINNER)

/datum/outfit/job/cy_corp_agent_base
	parent_type = /datum/outfit/job/security
	name = "Corporate Agent"
	jobtype = /datum/job/cy_corp_agent_base

/datum/job/cy_ben_agent
	parent_type = /datum/job/cy_corp_agent_base
	title = JOB_CY_BEN_AGENT
	supervisors = "представителем Бэнь"
	display_order = JOB_DISPLAY_ORDER_CY_BEN_AGENT
	config_tag = "CY_BEN_AGENT"
	cy_role_id = "ben_agent"
	total_positions = 3
	spawn_positions = 3
	outfit = /datum/outfit/job/cy_ben_agent
	cy_organization_type = /datum/cy_organization/corporation/ben
	cy_city_account_id = CY_ACCOUNT_BEN

/datum/job/cy_ryaznov_agent
	parent_type = /datum/job/cy_corp_agent_base
	title = JOB_CY_RYAZNOV_AGENT
	supervisors = "представителем Рязнова"
	display_order = JOB_DISPLAY_ORDER_CY_RYAZNOV_AGENT
	config_tag = "CY_RYAZNOV_AGENT"
	cy_role_id = "ryaznov_agent"
	total_positions = 3
	spawn_positions = 3
	outfit = /datum/outfit/job/cy_ryaznov_agent
	cy_organization_type = /datum/cy_organization/corporation/ryaznov
	cy_city_account_id = CY_ACCOUNT_RYAZNOV

/datum/job/cy_starlight_agent
	parent_type = /datum/job/cy_corp_agent_base
	title = JOB_CY_STARLIGHT_AGENT
	supervisors = "представителем Старлайт"
	display_order = JOB_DISPLAY_ORDER_CY_STARLIGHT_AGENT
	config_tag = "CY_STARLIGHT_AGENT"
	cy_role_id = "starlight_agent"
	total_positions = 3
	spawn_positions = 3
	outfit = /datum/outfit/job/cy_starlight_agent
	cy_organization_type = /datum/cy_organization/corporation/starlight
	cy_city_account_id = CY_ACCOUNT_STARLIGHT

/datum/job/cy_corp_specialist_base
	parent_type = /datum/job/cy_corporate_base
	total_positions = 0
	spawn_positions = 0
	job_flags = JOB_HIDE_WHEN_EMPTY
	paycheck = PAYCHECK_CREW
	cy_role_flags = CY_ROLE_FLAG_CORPORATE_SPECIALIST
	outfit = /datum/outfit/job/cy_corp_specialist_base
	cy_role_stat_modifiers = list(/datum/cy_stat/intelligence = 1)

/datum/outfit/job/cy_corp_specialist_base
	parent_type = /datum/outfit/job/cy_city_base
	name = "Corporate Specialist"
	jobtype = /datum/job/cy_corp_specialist_base

/datum/job/cy_ben_reaper
	parent_type = /datum/job/cy_corp_specialist_base
	title = JOB_CY_BEN_REAPER
	description = "Лечите, изучайте биотехнологии, импланты, химию, фауну и биоданные для исследований Бэнь."
	supervisors = "представителем Бэнь"
	paycheck_department = ACCOUNT_MED
	display_order = JOB_DISPLAY_ORDER_CY_BEN_REAPER
	config_tag = "CY_BEN_REAPER"
	cy_role_id = "ben_reaper"
	outfit = /datum/outfit/job/cy_ben_reaper
	cy_organization_type = /datum/cy_organization/corporation/ben
	cy_city_account_id = CY_ACCOUNT_BEN
	total_positions = 3
	spawn_positions = 3
	skills = list(/datum/cy_skill/professional/medicine = 150, /datum/cy_skill/professional/chemistry = 100, /datum/cy_skill/professional/analysis = 80)
	minimal_skills = list(/datum/cy_skill/professional/medicine = 80, /datum/cy_skill/professional/chemistry = 50)
	cy_role_stat_modifiers = list(/datum/cy_stat/spirit = 1, /datum/cy_stat/intelligence = 1)
	cy_role_expectations = list("Provide Ben medical, chemical and implant services.", "Collect biological and fauna data for corporate research.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/medicine = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/professional/chemistry = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_SKILLED)

/datum/job/cy_ryaznov_engineer
	parent_type = /datum/job/cy_corp_specialist_base
	title = JOB_CY_RYAZNOV_ENGINEER
	description = "Стройте, ремонтируйте, собирайте защиту, технику, мехи, энергоузлы и обрабатывайте рудные данные Рязнова."
	supervisors = "представителем Рязнова"
	paycheck_department = ACCOUNT_ENG
	display_order = JOB_DISPLAY_ORDER_CY_RYAZNOV_ENGINEER
	config_tag = "CY_RYAZNOV_ENGINEER"
	cy_role_id = "ryaznov_engineer"
	outfit = /datum/outfit/job/cy_ryaznov_engineer
	cy_organization_type = /datum/cy_organization/corporation/ryaznov
	cy_city_account_id = CY_ACCOUNT_RYAZNOV
	total_positions = 3
	spawn_positions = 3
	skills = list(/datum/cy_skill/professional/construction = 150, /datum/cy_skill/professional/invention = 100, /datum/cy_skill/professional/mining = 80)
	minimal_skills = list(/datum/cy_skill/professional/construction = 80, /datum/cy_skill/professional/invention = 50)
	cy_role_stat_modifiers = list(/datum/cy_stat/strength = 1, /datum/cy_stat/intelligence = 1)
	cy_role_expectations = list("Build, repair and produce Ryaznov armor, machinery and energy assets.", "Process ore and field data for corporate research.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/construction = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/professional/invention = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/professional/mining = CY_SKILL_LEVEL_SKILLED)

/datum/job/cy_starlight_logistician
	parent_type = /datum/job/cy_corp_specialist_base
	title = JOB_CY_STARLIGHT_LOGISTICIAN
	description = "Работайте с грузом, торговлей, логистикой, доставкой, техникой и маршрутными данными Старлайт."
	supervisors = "представителем Старлайт"
	paycheck_department = ACCOUNT_CAR
	display_order = JOB_DISPLAY_ORDER_CY_STARLIGHT_LOGISTICIAN
	config_tag = "CY_STARLIGHT_LOGISTICIAN"
	cy_role_id = "starlight_logistician"
	outfit = /datum/outfit/job/cy_starlight_logistician
	cy_organization_type = /datum/cy_organization/corporation/starlight
	cy_city_account_id = CY_ACCOUNT_STARLIGHT
	total_positions = 3
	spawn_positions = 3
	skills = list(/datum/cy_skill/professional/driving = 150, /datum/cy_skill/professional/analysis = 100, /datum/cy_skill/professional/invention = 60)
	minimal_skills = list(/datum/cy_skill/professional/driving = 80, /datum/cy_skill/professional/analysis = 50)
	cy_role_stat_modifiers = list(/datum/cy_stat/perception = 1, /datum/cy_stat/dexterity = 1)
	cy_role_expectations = list("Run Starlight cargo, trade, delivery and vehicle logistics.", "Use wreckage and route data to accelerate corporate research.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/driving = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/professional/invention = CY_SKILL_LEVEL_BEGINNER)

/datum/job/cy_corp_representative_base
	parent_type = /datum/job/cy_corporate_base
	description = "Управляйте местным подразделением корпорации, бюджетом, контрактами, исследованиями и развитием услуг."
	total_positions = 0
	spawn_positions = 0
	job_flags = JOB_HIDE_WHEN_EMPTY
	paycheck = PAYCHECK_COMMAND
	cy_role_flags = CY_ROLE_FLAG_CORPORATE_REPRESENTATIVE
	cy_can_manage_budget = TRUE
	outfit = /datum/outfit/job/cy_corp_representative_base
	cy_role_stat_modifiers = list(/datum/cy_stat/charisma = 1, /datum/cy_stat/intelligence = 1)
	cy_role_expectations = list("Lead the local corporate branch, budgets, contracts and research direction.", "Turn corporate services into profit and political leverage.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/analysis = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/charisma/inspiration = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/charisma/style = CY_SKILL_LEVEL_SKILLED)

/datum/outfit/job/cy_corp_representative_base
	parent_type = /datum/outfit/job/lawyer
	name = "Corporate Representative"
	jobtype = /datum/job/cy_corp_representative_base

/datum/job/cy_ben_representative
	parent_type = /datum/job/cy_corp_representative_base
	title = JOB_CY_BEN_REPRESENTATIVE
	supervisors = "советом директоров Бэнь"
	display_order = JOB_DISPLAY_ORDER_CY_BEN_REPRESENTATIVE
	config_tag = "CY_BEN_REPRESENTATIVE"
	cy_role_id = "ben_representative"
	total_positions = 1
	spawn_positions = 1
	job_flags = STATION_JOB_FLAGS | HEAD_OF_STAFF_JOB_FLAGS | JOB_ANTAG_PROTECTED
	outfit = /datum/outfit/job/cy_ben_representative
	cy_organization_type = /datum/cy_organization/corporation/ben
	cy_city_account_id = CY_ACCOUNT_BEN

/datum/job/cy_ryaznov_representative
	parent_type = /datum/job/cy_corp_representative_base
	title = JOB_CY_RYAZNOV_REPRESENTATIVE
	supervisors = "советом директоров Рязнова"
	display_order = JOB_DISPLAY_ORDER_CY_RYAZNOV_REPRESENTATIVE
	config_tag = "CY_RYAZNOV_REPRESENTATIVE"
	cy_role_id = "ryaznov_representative"
	total_positions = 1
	spawn_positions = 1
	job_flags = STATION_JOB_FLAGS | HEAD_OF_STAFF_JOB_FLAGS | JOB_ANTAG_PROTECTED
	outfit = /datum/outfit/job/cy_ryaznov_representative
	cy_organization_type = /datum/cy_organization/corporation/ryaznov
	cy_city_account_id = CY_ACCOUNT_RYAZNOV

/datum/job/cy_starlight_representative
	parent_type = /datum/job/cy_corp_representative_base
	title = JOB_CY_STARLIGHT_REPRESENTATIVE
	supervisors = "советом директоров Старлайт"
	display_order = JOB_DISPLAY_ORDER_CY_STARLIGHT_REPRESENTATIVE
	config_tag = "CY_STARLIGHT_REPRESENTATIVE"
	cy_role_id = "starlight_representative"
	total_positions = 1
	spawn_positions = 1
	job_flags = STATION_JOB_FLAGS | HEAD_OF_STAFF_JOB_FLAGS | JOB_ANTAG_PROTECTED
	outfit = /datum/outfit/job/cy_starlight_representative
	cy_organization_type = /datum/cy_organization/corporation/starlight
	cy_city_account_id = CY_ACCOUNT_STARLIGHT

// ---------------------------------------------------------------------------
// Outsourcers

/datum/job/cy_mercenary
	parent_type = /datum/job/cy_city_base
	title = JOB_CY_MERCENARY
	description = "Берите легальные и серые контракты, ходите в точки интереса, защищайте нанимателя и воюйте за оплату."
	supervisors = "условиями контракта и теми, кто платит"
	total_positions = 40
	spawn_positions = 40
	paycheck_department = ACCOUNT_CIV
	display_order = JOB_DISPLAY_ORDER_CY_MERCENARY
	department_for_prefs = /datum/job_department/cy_outsourcers
	departments_list = list(/datum/job_department/cy_outsourcers)
	config_tag = "CY_MERCENARY"
	outfit = /datum/outfit/job/cy_mercenary
	cy_role_group = CY_ROLE_GROUP_OUTSOURCER
	cy_role_id = "mercenary"
	cy_role_flags = CY_ROLE_FLAG_OUTSOURCER | CY_ROLE_FLAG_BOUNTY_HUNTER
	cy_city_account_id = CY_ACCOUNT_CIV_MARKET
	cy_bounty_hunter = TRUE
	skills = list(/datum/cy_skill/dexterity/light_weapons = 120, /datum/cy_skill/strength/heavy_weapons = 80, /datum/cy_skill/spirit/athletics = 80)
	minimal_skills = list(/datum/cy_skill/dexterity/light_weapons = 60, /datum/cy_skill/spirit/athletics = 40)
	cy_role_stat_modifiers = list(/datum/cy_stat/dexterity = 1, /datum/cy_stat/perception = 1)
	cy_role_expectations = list("Take legal or grey contracts, explore points of interest and sell field loot.", "You are a weapon-skilled contractor, not a netrunner specialist.")
	cy_role_skill_levels = list(/datum/cy_skill/dexterity/light_weapons = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/strength/heavy_weapons = CY_SKILL_LEVEL_BEGINNER, /datum/cy_skill/spirit/athletics = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/light_firearms = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/medium_firearms = CY_SKILL_LEVEL_BEGINNER)
	job_flags = STATION_JOB_FLAGS

/datum/outfit/job/cy_mercenary
	parent_type = /datum/outfit/job/security
	name = JOB_CY_MERCENARY
	jobtype = /datum/job/cy_mercenary

/datum/job/cy_laborer
	parent_type = /datum/job/cy_city_base
	title = JOB_CY_LABORER
	description = "Свободный работник без фиксированной привязки: нанимайтесь, меняйте работу, снимайте жильё и зарабатывайте как сможете."
	supervisors = "работодателем, если вы его выбрали"
	total_positions = 40
	spawn_positions = 40
	paycheck_department = ACCOUNT_CIV
	display_order = JOB_DISPLAY_ORDER_CY_LABORER
	department_for_prefs = /datum/job_department/cy_outsourcers
	departments_list = list(/datum/job_department/cy_outsourcers)
	config_tag = "CY_LABORER"
	outfit = /datum/outfit/job/cy_laborer
	cy_role_group = CY_ROLE_GROUP_OUTSOURCER
	cy_role_id = "laborer"
	cy_role_flags = CY_ROLE_FLAG_OUTSOURCER
	cy_city_account_id = CY_ACCOUNT_CIV_MARKET
	cy_role_stat_modifiers = list(/datum/cy_stat/strength = 1)
	cy_role_expectations = list("Work for whoever pays, change employers freely and learn city mechanics.", "This role has no special role bonus beyond broad access to city life.")
	job_flags = STATION_JOB_FLAGS

/datum/outfit/job/cy_laborer
	parent_type = /datum/outfit/job/assistant
	name = JOB_CY_LABORER
	jobtype = /datum/job/cy_laborer

// ---------------------------------------------------------------------------
// Antagonist role shells. They are hidden by default; storyteller/map config can open slots.

/datum/job/cy_antagonist_base
	parent_type = /datum/job/cy_city_base
	cy_role_group = CY_ROLE_GROUP_ANTAGONIST
	department_for_prefs = /datum/job_department/cy_antagonists
	departments_list = list(/datum/job_department/cy_antagonists)
	paycheck = PAYCHECK_LOWER
	paycheck_department = ACCOUNT_CIV
	cy_city_account_id = CY_ACCOUNT_BLACK_MARKET
	job_flags = JOB_EQUIP_RANK | JOB_ASSIGN_QUIRKS | JOB_HIDE_WHEN_EMPTY | JOB_CANNOT_OPEN_SLOTS
	total_positions = 0
	spawn_positions = 0
	outfit = /datum/outfit/job/cy_antagonist_base
	cy_role_stat_modifiers = list(/datum/cy_stat/spirit = 1)

/datum/outfit/job/cy_antagonist_base
	parent_type = /datum/outfit/job/assistant
	name = "City Antagonist"
	jobtype = /datum/job/cy_antagonist_base

/datum/job/cy_street_thug
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_STREET_THUG
	description = "Мелкий городской криминал: вымогательство, наркотики, подпольные услуги, драки и выживание под давлением полиции."
	display_order = JOB_DISPLAY_ORDER_CY_STREET_THUG
	config_tag = "CY_STREET_THUG"
	cy_role_id = "street_thug"
	cy_role_flags = CY_ROLE_FLAG_MINOR_CRIMINAL
	cy_role_expectations = list("Extort, sell contraband, run illegal services and survive police pressure.", "You are a small-scale antagonist for local city conflict.")
	cy_role_skill_levels = list(/datum/cy_skill/charisma/theft = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/dexterity/fast_melee = CY_SKILL_LEVEL_BEGINNER, /datum/cy_skill/weapon/knives = CY_SKILL_LEVEL_BEGINNER)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_THEFT, "details" = "Known petty extortion and black-market activity.", "issuer" = "City security database", "fine" = 250, "status" = CY_WARRANT_INVESTIGATION))

/datum/job/cy_gang_member
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_GANG_MEMBER
	description = "Член банды: богатейте преступлением, захватывайте влияние, давите полицию и чиновников."
	display_order = JOB_DISPLAY_ORDER_CY_GANG_MEMBER
	config_tag = "CY_GANG_MEMBER"
	cy_role_id = "gang_member"
	cy_role_flags = CY_ROLE_FLAG_MAJOR_CRIMINAL
	cy_role_expectations = list("Grow gang power through crime, territory pressure and violence.", "Police already know you have fines and unresolved criminal history.")
	cy_role_skill_levels = list(/datum/cy_skill/charisma/theft = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/strength/grappling = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/dexterity/light_weapons = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/light_firearms = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/knives = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_ASSAULT, "details" = "Known gang assault record and open street violence.", "issuer" = "Police gang desk", "fine" = 900, "sentence" = 5 MINUTES, "status" = CY_WARRANT_ARREST), list("law" = CY_LAW_CONTROLLED_ITEM, "details" = "Suspected illegal weapon and contraband possession.", "issuer" = "Police gang desk", "fine" = 700, "status" = CY_WARRANT_INVESTIGATION))

/datum/job/cy_anarchist
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_ANARCHIST
	description = "Анархист: бейте корпорации, государство, склады, станции, радары, сервера и лаборатории."
	display_order = JOB_DISPLAY_ORDER_CY_ANARCHIST
	config_tag = "CY_ANARCHIST"
	cy_role_id = "anarchist"
	cy_role_flags = CY_ROLE_FLAG_MAJOR_CRIMINAL
	cy_role_expectations = list("Strike corporate and state assets outside and inside the city.", "Your main targets are corporations, government control and their infrastructure.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/electricity = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/professional/construction = CY_SKILL_LEVEL_BEGINNER, /datum/cy_skill/dexterity/light_weapons = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/weapon/medium_firearms = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_SABOTAGE, "details" = "Known anti-corporate sabotage cell affiliation.", "issuer" = "Government intelligence", "fine" = 1200, "sentence" = 5 MINUTES, "status" = CY_WARRANT_ARREST))

/datum/job/cy_mutant
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_MUTANT
	description = "Биологическая угроза: размножайтесь, поглощайте, принимайте облики, избегайте огня и кислоты."
	display_order = JOB_DISPLAY_ORDER_CY_MUTANT
	config_tag = "CY_MUTANT"
	cy_role_id = "mutant"
	cy_role_flags = CY_ROLE_FLAG_MONSTER
	cy_role_expectations = list("Spread, consume biomass and use disguise or biomass forms to survive.", "Fire and acid are your primary vulnerabilities.")
	cy_role_skill_levels = list(/datum/cy_skill/spirit/survival = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/strength/toughness = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/strength/power_melee = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_MURDER, "details" = "Biological city-level threat. Kill authorization recommended if confirmed.", "issuer" = "Emergency response registry", "fine" = 0, "sentence" = 0, "status" = CY_WARRANT_KILL))

/datum/job/cy_construct
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_CONSTRUCT
	description = "Механический конструкт: уничтожайте биологическую жизнь, поглощайте металл, ремонтируйтесь и наращивайте потенциал."
	display_order = JOB_DISPLAY_ORDER_CY_CONSTRUCT
	config_tag = "CY_CONSTRUCT"
	cy_role_id = "construct"
	cy_role_flags = CY_ROLE_FLAG_MONSTER
	cy_role_expectations = list("Destroy biological life, consume scrap and grow shields, weapons and repairs.", "Your arc is mechanical escalation from scavenged equipment.")
	cy_role_skill_levels = list(/datum/cy_skill/professional/invention = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/strength/toughness = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/strength/heavy_weapons = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_MURDER, "details" = "Autonomous machine threat to biological life. Kill authorization recommended if confirmed.", "issuer" = "Emergency response registry", "fine" = 0, "sentence" = 0, "status" = CY_WARRANT_KILL))

/datum/job/cy_swarm
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_SWARM
	description = "Энергетический рой: ставьте пилоны, стабилизируйте производство плазмы и обращайте биомассу в боевые единицы."
	display_order = JOB_DISPLAY_ORDER_CY_SWARM
	config_tag = "CY_SWARM"
	cy_role_id = "swarm"
	cy_role_flags = CY_ROLE_FLAG_MONSTER
	cy_role_expectations = list("Place pylons, stabilize plasma production and convert biomass into combat units.", "You are an energy anomaly tied to Starlight failures.")
	cy_role_skill_levels = list(/datum/cy_skill/intelligence/improved_code = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/intelligence/fast_code = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/spirit/compatibility = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_SABOTAGE, "details" = "Energetic anomaly threat to city infrastructure. Termination authorization recommended if confirmed.", "issuer" = "Emergency response registry", "fine" = 0, "sentence" = 0, "status" = CY_WARRANT_KILL))

/datum/job/cy_salvation_army
	parent_type = /datum/job/cy_antagonist_base
	title = JOB_CY_SALVATION_ARMY
	description = "Армия Спасения: тяжёлая внешняя угроза с техникой и целью стереть город с лица земли."
	display_order = JOB_DISPLAY_ORDER_CY_SALVATION_ARMY
	config_tag = "CY_SALVATION_ARMY"
	cy_role_id = "salvation_army"
	cy_role_flags = CY_ROLE_FLAG_MAJOR_CRIMINAL
	cy_role_expectations = list("Use heavy gear and vehicles to wipe out the city and deploy the nuclear threat.", "You are a high-intensity combat antagonist, not a petty criminal.")
	cy_role_skill_levels = list(/datum/cy_skill/strength/heavy_weapons = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/weapon/heavy_firearms = CY_SKILL_LEVEL_TRAINED, /datum/cy_skill/weapon/medium_firearms = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/professional/driving = CY_SKILL_LEVEL_SKILLED, /datum/cy_skill/spirit/athletics = CY_SKILL_LEVEL_SKILLED)
	cy_role_roundstart_violations = list(list("law" = CY_LAW_MURDER, "details" = "External extermination force with city-destruction intent.", "issuer" = "Government intelligence", "fine" = 0, "sentence" = 0, "status" = CY_WARRANT_KILL), list("law" = CY_LAW_SABOTAGE, "details" = "Suspected nuclear or mass-destruction operation.", "issuer" = "Government intelligence", "fine" = 0, "sentence" = 0, "status" = CY_WARRANT_KILL))

// Concrete corporate outfits keep ID/jobtype previews tied to the selected role.
/datum/outfit/job/cy_ben_agent
	parent_type = /datum/outfit/job/cy_corp_agent_base
	name = JOB_CY_BEN_AGENT
	jobtype = /datum/job/cy_ben_agent

/datum/outfit/job/cy_ryaznov_agent
	parent_type = /datum/outfit/job/cy_corp_agent_base
	name = JOB_CY_RYAZNOV_AGENT
	jobtype = /datum/job/cy_ryaznov_agent

/datum/outfit/job/cy_starlight_agent
	parent_type = /datum/outfit/job/cy_corp_agent_base
	name = JOB_CY_STARLIGHT_AGENT
	jobtype = /datum/job/cy_starlight_agent

/datum/outfit/job/cy_ben_reaper
	parent_type = /datum/outfit/job/cy_corp_specialist_base
	name = JOB_CY_BEN_REAPER
	jobtype = /datum/job/cy_ben_reaper

/datum/outfit/job/cy_ryaznov_engineer
	parent_type = /datum/outfit/job/cy_corp_specialist_base
	name = JOB_CY_RYAZNOV_ENGINEER
	jobtype = /datum/job/cy_ryaznov_engineer

/datum/outfit/job/cy_starlight_logistician
	parent_type = /datum/outfit/job/cy_corp_specialist_base
	name = JOB_CY_STARLIGHT_LOGISTICIAN
	jobtype = /datum/job/cy_starlight_logistician

/datum/outfit/job/cy_ben_representative
	parent_type = /datum/outfit/job/cy_corp_representative_base
	name = JOB_CY_BEN_REPRESENTATIVE
	jobtype = /datum/job/cy_ben_representative

/datum/outfit/job/cy_ryaznov_representative
	parent_type = /datum/outfit/job/cy_corp_representative_base
	name = JOB_CY_RYAZNOV_REPRESENTATIVE
	jobtype = /datum/job/cy_ryaznov_representative

/datum/outfit/job/cy_starlight_representative
	parent_type = /datum/outfit/job/cy_corp_representative_base
	name = JOB_CY_STARLIGHT_REPRESENTATIVE
	jobtype = /datum/job/cy_starlight_representative
