// Concrete Cyberpunk professional perk datums for /datum/skill/professional/surgery.

/datum/skill_perk/professional/surgery/perk_1
	name = "Диагностика"
	desc = "Полный анализ сканером здоровья или биомонитором проходит на {value}% быстрее."
	effectiveness_values = list(25, 50, 75, 100)

/datum/skill_perk/professional/surgery/perk_2
	name = "База операций"
	desc = "Ускоряет простые, сложные и редкие этапы операции на {value_1}%, {value_2}% и {value_3}% соответственно. Также увеличивает объём лечения мозга за этап."
	effectiveness_values = list(1, 2, 3, 4)
	effectiveness_by_key = list(
		"value_1" = list(15, 30, 45, 60),
		"value_2" = list(10, 20, 30, 40),
		"value_3" = list(5, 10, 15, 20),
	)

/datum/skill_perk/professional/surgery/perk_3
	name = "Скорость лечения"
	desc = "+{value}% к скорости хирургических этапов, перевязок, инъекций и других лечебных действий."
	effectiveness_values = list(25, 50, 75, 100)

/datum/skill_perk/professional/surgery/perk_4
	name = "Стерильность"
	desc = "+{value}% шанс, что операция не вызовет заражение."
	effectiveness_values = list(25, 50, 75, 100)

/datum/skill_perk/professional/surgery/perk_5
	name = "Самооперация"
	desc = "Можно проводить операции на себе с шансом успеха {value_1}%, {value_2}%, {value_3}% соответственно для всех уровня."
	effectiveness_values = list(20, 40, 60, 80)
	effectiveness_by_key = list(
		"value_1" = list(20, 40, 60, 80),
		"value_2" = list(15, 30, 45, 60),
		"value_3" = list(10, 20, 30, 40),
	)
