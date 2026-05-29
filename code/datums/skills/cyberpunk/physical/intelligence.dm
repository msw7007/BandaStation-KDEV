/datum/skill/physical/intelligence
	abstract_type = /datum/skill/physical/intelligence
	attribute_id = ATTRIBUTE_INTELLIGENCE
	giga_perk_name = "Ботаник"
	giga_perk_desc = "Демоны могут повторно активироваться, не тратить выносливость, снижать требования модификации или отражаться в применившего по шансам соответствующих навыков."

/datum/skill/physical/intelligence/enhanced_code
	name = "Улучшенный код"
	title = "Усилитель кода"
	desc = "Сила демонов и усиление следующего запуска."
	perk_types = list(
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_1,
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_2,
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_3,
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_4,
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_5,
		/datum/skill_perk/physical/intelligence/enhanced_code/perk_6,
	)

/datum/skill/physical/intelligence/fast_code
	name = "Быстрый код"
	title = "Ускоритель кода"
	desc = "Подготовка, активация и восстановление демонов."
	perk_types = list(
		/datum/skill_perk/physical/intelligence/fast_code/perk_1,
		/datum/skill_perk/physical/intelligence/fast_code/perk_2,
		/datum/skill_perk/physical/intelligence/fast_code/perk_3,
		/datum/skill_perk/physical/intelligence/fast_code/perk_4,
		/datum/skill_perk/physical/intelligence/fast_code/perk_5,
		/datum/skill_perk/physical/intelligence/fast_code/perk_6,
	)

/datum/skill/physical/intelligence/hacking
	name = "Взлом"
	title = "Хакер"
	desc = "Подключение, узлы, обнаружение и сетевые данные."
	perk_types = list(
		/datum/skill_perk/physical/intelligence/hacking/perk_1,
		/datum/skill_perk/physical/intelligence/hacking/perk_2,
		/datum/skill_perk/physical/intelligence/hacking/perk_3,
		/datum/skill_perk/physical/intelligence/hacking/perk_4,
		/datum/skill_perk/physical/intelligence/hacking/perk_5,
		/datum/skill_perk/physical/intelligence/hacking/perk_6,
	)

/datum/skill/physical/intelligence/neutralization
	name = "Нейрализация"
	title = "Нейтрализатор"
	desc = "Сопротивление враждебным негативным эффектам."
	perk_types = list(
		/datum/skill_perk/physical/intelligence/neutralization/perk_1,
		/datum/skill_perk/physical/intelligence/neutralization/perk_2,
		/datum/skill_perk/physical/intelligence/neutralization/perk_3,
		/datum/skill_perk/physical/intelligence/neutralization/perk_4,
		/datum/skill_perk/physical/intelligence/neutralization/perk_5,
		/datum/skill_perk/physical/intelligence/neutralization/perk_6,
	)
