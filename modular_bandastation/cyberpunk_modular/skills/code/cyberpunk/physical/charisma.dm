/datum/skill/physical/charisma
	abstract_type = /datum/skill/physical/charisma
	attribute_id = ATTRIBUTE_CHARISMA
	giga_perk_name = "Холщенность"
	giga_perk_desc = "Скрытность может не сбрасываться на свету; воровство может дать невидимость; вдохновение и стиль усиливаются от соответствующих навыков."

/datum/skill/physical/charisma/stealth
	name = "Скрытность"
	title = "Скрытный"
	desc = "Хамелеон, движение в тени и атаки из скрытности."
	perk_types = list(
		/datum/skill_perk/physical/charisma/stealth/perk_1,
		/datum/skill_perk/physical/charisma/stealth/perk_2,
		/datum/skill_perk/physical/charisma/stealth/perk_3,
		/datum/skill_perk/physical/charisma/stealth/perk_4,
		/datum/skill_perk/physical/charisma/stealth/perk_5,
		/datum/skill_perk/physical/charisma/stealth/perk_6,
	)

/datum/skill/physical/charisma/theft
	name = "Воровство"
	title = "Вор"
	desc = "Кража из слотов и сокрытие сообщения о краже."
	perk_types = list(
		/datum/skill_perk/physical/charisma/theft/perk_1,
		/datum/skill_perk/physical/charisma/theft/perk_2,
		/datum/skill_perk/physical/charisma/theft/perk_3,
		/datum/skill_perk/physical/charisma/theft/perk_4,
		/datum/skill_perk/physical/charisma/theft/perk_5,
		/datum/skill_perk/physical/charisma/theft/perk_6,
	)

/datum/skill/physical/charisma/inspiration
	name = "Воодушевление"
	title = "Лидер когорты"
	desc = "Когорта, общий опыт, настроение и защита союзников."
	perk_types = list(
		/datum/skill_perk/physical/charisma/inspiration/perk_1,
		/datum/skill_perk/physical/charisma/inspiration/perk_2,
		/datum/skill_perk/physical/charisma/inspiration/perk_3,
		/datum/skill_perk/physical/charisma/inspiration/perk_4,
		/datum/skill_perk/physical/charisma/inspiration/perk_5,
		/datum/skill_perk/physical/charisma/inspiration/perk_6,
	)

/datum/skill/physical/charisma/style
	name = "Стиль"
	title = "Икона стиля"
	desc = "Стиль, осмотр, опыт и реакция окружающих."
	perk_types = list(
		/datum/skill_perk/physical/charisma/style/perk_1,
		/datum/skill_perk/physical/charisma/style/perk_2,
		/datum/skill_perk/physical/charisma/style/perk_3,
		/datum/skill_perk/physical/charisma/style/perk_4,
		/datum/skill_perk/physical/charisma/style/perk_5,
		/datum/skill_perk/physical/charisma/style/perk_6,
	)
