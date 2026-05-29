/datum/skill/professional
	abstract_type = /datum/skill/professional
	skill_kind = CHARACTER_SKILL_KIND_PROFESSIONAL
	point_pool = CHARACTER_SKILL_POOL_SKILL
	max_character_level = PROFESSIONAL_SKILL_MAX_LEVEL
	max_perk_rank = PROFESSIONAL_PERK_MAX_RANK
	requires_sequential_perks = FALSE

/datum/skill/professional/surgery
	name = "Хирургия"
	title = "Хирург"
	attribute_id = ATTRIBUTE_DEXTERITY
	desc = "Сканирование и операции."
	perk_types = list(
		/datum/skill_perk/professional/surgery/perk_1,
		/datum/skill_perk/professional/surgery/perk_2,
		/datum/skill_perk/professional/surgery/perk_3,
		/datum/skill_perk/professional/surgery/perk_4,
		/datum/skill_perk/professional/surgery/perk_5,
	)

/datum/skill/professional/chemistry
	name = "Химия"
	title = "Химик"
	attribute_id = ATTRIBUTE_INTELLIGENCE
	desc = "pH, перегрев, скорость и чистота реакций."
	perk_types = list(
		/datum/skill_perk/professional/chemistry/perk_1,
		/datum/skill_perk/professional/chemistry/perk_2,
		/datum/skill_perk/professional/chemistry/perk_3,
		/datum/skill_perk/professional/chemistry/perk_4,
		/datum/skill_perk/professional/chemistry/perk_5,
	)

/datum/skill/professional/electrics
	name = "Электрика"
	title = "Электрик"
	attribute_id = ATTRIBUTE_DEXTERITY
	desc = "Провода, шоки и ремонт электрики."
	perk_types = list(
		/datum/skill_perk/professional/electrics/perk_1,
		/datum/skill_perk/professional/electrics/perk_2,
		/datum/skill_perk/professional/electrics/perk_3,
		/datum/skill_perk/professional/electrics/perk_4,
		/datum/skill_perk/professional/electrics/perk_5,
	)

/datum/skill/professional/construction
	name = "Строительство"
	title = "Строитель"
	attribute_id = ATTRIBUTE_STRENGTH
	desc = "Постройки, ремонт и демонтаж."
	perk_types = list(
		/datum/skill_perk/professional/construction/perk_1,
		/datum/skill_perk/professional/construction/perk_2,
		/datum/skill_perk/professional/construction/perk_3,
		/datum/skill_perk/professional/construction/perk_4,
		/datum/skill_perk/professional/construction/perk_5,
	)

/datum/skill/professional/invention
	name = "Изобретательство"
	title = "Изобретатель"
	attribute_id = ATTRIBUTE_INTELLIGENCE
	desc = "Сборка, разборка, ремонт и качество предметов."
	perk_types = list(
		/datum/skill_perk/professional/invention/perk_1,
		/datum/skill_perk/professional/invention/perk_2,
		/datum/skill_perk/professional/invention/perk_3,
		/datum/skill_perk/professional/invention/perk_4,
		/datum/skill_perk/professional/invention/perk_5,
	)

/datum/skill/professional/analysis
	name = "Анализ"
	title = "Аналитик"
	attribute_id = ATTRIBUTE_PERCEPTION
	desc = "Исследование объектов, людей и технологий."
	perk_types = list(
		/datum/skill_perk/professional/analysis/perk_1,
		/datum/skill_perk/professional/analysis/perk_2,
		/datum/skill_perk/professional/analysis/perk_3,
		/datum/skill_perk/professional/analysis/perk_4,
		/datum/skill_perk/professional/analysis/perk_5,
	)

/datum/skill/professional/mining
	name = "Добыча"
	title = "Добытчик"
	attribute_id = ATTRIBUTE_STRENGTH
	desc = "Добыча породы, бур и руда."
	perk_types = list(
		/datum/skill_perk/professional/mining/perk_1,
		/datum/skill_perk/professional/mining/perk_2,
		/datum/skill_perk/professional/mining/perk_3,
		/datum/skill_perk/professional/mining/perk_4,
		/datum/skill_perk/professional/mining/perk_5,
	)

/datum/skill/professional/driving
	name = "Управление"
	title = "Водитель"
	attribute_id = ATTRIBUTE_PERCEPTION
	desc = "Транспорт, топливо, скорость и маневренность."
	perk_types = list(
		/datum/skill_perk/professional/driving/perk_1,
		/datum/skill_perk/professional/driving/perk_2,
		/datum/skill_perk/professional/driving/perk_3,
		/datum/skill_perk/professional/driving/perk_4,
		/datum/skill_perk/professional/driving/perk_5,
	)

/datum/skill/professional/cooking
	name = "Готовка"
	title = "Повар"
	attribute_id = ATTRIBUTE_DEXTERITY
	desc = "Ручная и машинная готовка, совместимость и запахи."
	perk_types = list(
		/datum/skill_perk/professional/cooking/perk_1,
		/datum/skill_perk/professional/cooking/perk_2,
		/datum/skill_perk/professional/cooking/perk_3,
		/datum/skill_perk/professional/cooking/perk_4,
		/datum/skill_perk/professional/cooking/perk_5,
	)

/datum/skill/professional/gardening
	name = "Садоводство"
	title = "Садовод"
	attribute_id = ATTRIBUTE_SPIRIT
	desc = "Посадка, рост, полив, сбор и мутации растений."
	perk_types = list(
		/datum/skill_perk/professional/gardening/perk_1,
		/datum/skill_perk/professional/gardening/perk_2,
		/datum/skill_perk/professional/gardening/perk_3,
		/datum/skill_perk/professional/gardening/perk_4,
		/datum/skill_perk/professional/gardening/perk_5,
	)

/datum/skill/professional/music
	name = "Музыка"
	title = "Музыкант"
	attribute_id = ATTRIBUTE_CHARISMA
	desc = "Мудлеты, когорта, баффы, дебаффы и стиль."
	perk_types = list(
		/datum/skill_perk/professional/music/perk_1,
		/datum/skill_perk/professional/music/perk_2,
		/datum/skill_perk/professional/music/perk_3,
		/datum/skill_perk/professional/music/perk_4,
		/datum/skill_perk/professional/music/perk_5,
	)
