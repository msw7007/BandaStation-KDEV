// Concrete Cyberpunk professional perk datums for /datum/skill/professional/mining.

/datum/skill_perk/professional/mining/perk_1
	name = "Скорость добычи"
	desc = "Время добычи сокращено на {value}%."
	effectiveness_values = list(20, 40, 60, 80)

/datum/skill_perk/professional/mining/perk_2
	name = "Бур"
	desc = "Запущенный вами бур приносит на {value}% больше ресурсов."
	effectiveness_values = list(25, 50, 75, 100)

/datum/skill_perk/professional/mining/perk_3
	name = "Жила"
	desc = "{value}% шанс, что при разборе породы там будет ресурс."
	effectiveness_values = list(15, 30, 45, 60)

/datum/skill_perk/professional/mining/perk_4
	name = "Качество блока"
	desc = "+{value_1}%, +{value_2}%, +{value_3}% шанс, что ресурс блока будет 1, 2, 3 уровня."
	effectiveness_values = list(20, 40, 60, 80)
	effectiveness_by_key = list(
		"value_1" = list(20, 40, 60, 80),
		"value_2" = list(15, 30, 45, 60),
		"value_3" = list(10, 20, 30, 40),
	)

/datum/skill_perk/professional/mining/perk_5
	name = "Копия руды"
	desc = "{value}% шанс, что при получении руды выпадет копия руды."
	effectiveness_values = list(25, 50, 75, 100)
