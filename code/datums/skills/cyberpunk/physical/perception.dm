/datum/skill/physical/perception
	abstract_type = /datum/skill/physical/perception
	attribute_id = ATTRIBUTE_PERCEPTION
	giga_perk_name = "Орлиный глаз"
	giga_perk_desc = "Точные атаки могут ослепить цель с шансом навыка * 15%; анализ слабостей может удвоить критический удар после расчетов."

/datum/skill/physical/perception/precise_unarmed
	name = "Точечный рукопашный бой"
	title = "Точечный боец"
	desc = "Точные удары по зонам и болевым точкам."
	perk_types = list(
		/datum/skill_perk/physical/perception/precise_unarmed/perk_1,
		/datum/skill_perk/physical/perception/precise_unarmed/perk_2,
		/datum/skill_perk/physical/perception/precise_unarmed/perk_3,
		/datum/skill_perk/physical/perception/precise_unarmed/perk_4,
		/datum/skill_perk/physical/perception/precise_unarmed/perk_5,
		/datum/skill_perk/physical/perception/precise_unarmed/perk_6,
	)

/datum/skill/physical/perception/precise_weapon
	name = "Метательное оружие"
	title = "Точный оружейник"
	desc = "Точные броски, выстрелы и усиленные интенты."
	perk_types = list(
		/datum/skill_perk/physical/perception/precise_weapon/perk_1,
		/datum/skill_perk/physical/perception/precise_weapon/perk_2,
		/datum/skill_perk/physical/perception/precise_weapon/perk_3,
		/datum/skill_perk/physical/perception/precise_weapon/perk_4,
		/datum/skill_perk/physical/perception/precise_weapon/perk_5,
		/datum/skill_perk/physical/perception/precise_weapon/perk_6,
	)

/datum/skill/physical/perception/weakness_analysis
	name = "Анализ слабостей"
	title = "Аналитик слабостей"
	desc = "Критические удары и развитие травм."
	perk_types = list(
		/datum/skill_perk/physical/perception/weakness_analysis/perk_1,
		/datum/skill_perk/physical/perception/weakness_analysis/perk_2,
		/datum/skill_perk/physical/perception/weakness_analysis/perk_3,
		/datum/skill_perk/physical/perception/weakness_analysis/perk_4,
		/datum/skill_perk/physical/perception/weakness_analysis/perk_5,
		/datum/skill_perk/physical/perception/weakness_analysis/perk_6,
	)

/datum/skill/physical/perception/concentration
	name = "Концентрация"
	title = "Парирующий"
	desc = "Парирование и открытие защиты."
	perk_types = list(
		/datum/skill_perk/physical/perception/concentration/perk_1,
		/datum/skill_perk/physical/perception/concentration/perk_2,
		/datum/skill_perk/physical/perception/concentration/perk_3,
		/datum/skill_perk/physical/perception/concentration/perk_4,
		/datum/skill_perk/physical/perception/concentration/perk_5,
		/datum/skill_perk/physical/perception/concentration/perk_6,
	)
