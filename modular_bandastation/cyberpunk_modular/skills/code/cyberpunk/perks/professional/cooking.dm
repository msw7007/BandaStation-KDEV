// Concrete Cyberpunk professional perk datums for /datum/skill/professional/cooking.

/datum/skill_perk/professional/cooking/perk_1
	name = "Скорость готовки"
	desc = "Ручная готовка быстрее на {value_1}%, машинная на {value_2}%, если еду загружали вы."
	effectiveness_values = list(15, 30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(15, 30, 45, 60),
		"value_2" = list(20, 40, 60, 80),
	)

/datum/skill_perk/professional/cooking/perk_2
	name = "Совместимость"
	desc = "Можно добавлять ингредиенты по совместимости для усиления эффекта до {value_1} уровня или испортить еду с шансом {value_2}%."
	effectiveness_values = list(4, 8, 12, 16)
	effectiveness_by_key = list(
		"value_1" = list(4, 8, 12, 16),
		"value_2" = list(20, 40, 60, 80),
	)

/datum/skill_perk/professional/cooking/perk_3
	name = "Контроль блюда"
	desc = "Шанс испортить блюдо снижен на {value}%."
	effectiveness_values = list(20, 40, 60, 80)

/datum/skill_perk/professional/cooking/perk_4
	name = "Экономия кухни"
	desc = "При подготовке блюда {value_1}% шанс не поглотить ресурс; положительный эффект еды усиливается минимум на {value_2} уровень."
	effectiveness_values = list(10, 20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(10, 20, 30, 40),
		"value_2" = list(1, 2, 3, 4),
	)

/datum/skill_perk/professional/cooking/perk_5
	name = "Запах"
	desc = "Во время готовки есть {value_1}% шанс распространить запах с мудлетом +{value_2} настроения."
	effectiveness_values = list(20, 20, 20, 20)
	effectiveness_by_key = list(
		"value_1" = list(20, 20, 20, 20),
		"value_2" = list(2, 6, 10, 15),
	)
