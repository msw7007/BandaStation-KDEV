// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/charisma/stealth/perk_1
	name = "Начинающий"
	desc = "Максимальный хамелеон в тени повышен на {value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/charisma/stealth/perk_2
	name = "Умелый"
	desc = "При передвижении в скрытности хамелеон снижается до {value}%."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/charisma/stealth/perk_3
	name = "Обученный"
	desc = "Количество люменов для активации хамелеона снижается на {value} за уровень."
	effectiveness_values = list(0.25, 0.38, 0.5)

/datum/skill_perk/physical/charisma/stealth/perk_4
	name = "Эксперт"
	desc = "+{value}% скорости в режиме скрытности."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/charisma/stealth/perk_5
	name = "Профессионал"
	desc = "Атака из скрытности повышает множитель до x1.{value}."
	effectiveness_values = list(5, 7.5, 10)

/datum/skill_perk/physical/charisma/stealth/perk_6
	name = "Мастер"
	desc = "Хамелеон может составлять до {value}%."
	effectiveness_values = list(70, 85, 100)

/datum/skill_perk/physical/charisma/theft/perk_1
	name = "Начинающий"
	desc = "Можно видеть и воровать из карманов, сумки, куртки, пояса, шеи, уха и бейджа."

/datum/skill_perk/physical/charisma/theft/perk_2
	name = "Умелый"
	desc = "{value}% шанс не вывести сообщение о воровстве цели."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/charisma/theft/perk_3
	name = "Обученный"
	desc = "Скрытность увеличивает шанс скрыть сообщение на {value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/charisma/theft/perk_4
	name = "Эксперт"
	desc = "Скорость снятия вещи увеличена на {value}%."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/charisma/theft/perk_5
	name = "Профессионал"
	desc = "При краже в движении есть {value}% шанс успеха."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/charisma/theft/perk_6
	name = "Мастер"
	desc = "Можно воровать все слоты экипировки, включая рюкзаки, перчатки, сапоги, очки, маску и шлем."

/datum/skill_perk/physical/charisma/inspiration/perk_1
	name = "Начинающий"
	desc = "{value}% опыта члена когорты передается остальным."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/charisma/inspiration/perk_2
	name = "Умелый"
	desc = "Размер когорты повышается на +{value} человека за уровень."
	effectiveness_values = list(2, 3, 4)

/datum/skill_perk/physical/charisma/inspiration/perk_3
	name = "Обученный"
	desc = "Положительные эффекты на одного члена когорты дают остальным {value}% эффекта."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/charisma/inspiration/perk_4
	name = "Эксперт"
	desc = "Полученное одним членом когорты настроение передается остальным с {value}% силой."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/charisma/inspiration/perk_5
	name = "Профессионал"
	desc = "При получении настроения время защиты членов когорты возрастает на {value}%."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/charisma/inspiration/perk_6
	name = "Мастер"
	desc = "При получении эффектов персонажи не теряют сознание. Смерть все еще возможна."

/datum/skill_perk/physical/charisma/style/perk_1
	name = "Начинающий"
	desc = "{value_1}% шанс, что осмотревший вас в течение {value_2} минут получит небольшой бонус настроения."
	effectiveness_values = list(10, 15, 20)
	effectiveness_by_key = list(
		"value_1" = list(10, 15, 20),
		"value_2" = list(5, 7.5, 10),
	)

/datum/skill_perk/physical/charisma/style/perk_2
	name = "Умелый"
	desc = "Можно видеть настроение, сонливость, голод и жажду человека."

/datum/skill_perk/physical/charisma/style/perk_3
	name = "Обученный"
	desc = "После действия предмет получает ваш статус на {value_1} секунд; повторивший действие получает +{value_2}% опыта."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(20, 30, 40),
	)

/datum/skill_perk/physical/charisma/style/perk_4
	name = "Эксперт"
	desc = "Если вы наносите урон или стреляете, повторяющие такую же атаку получают +{value}% опыта."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/charisma/style/perk_5
	name = "Профессионал"
	desc = "Получаемый опыт от показателя стиля увеличен на +{value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/charisma/style/perk_6
	name = "Мастер"
	desc = "Если вас успешно атакуют, есть {value}% шанс дезориентировать противника."
	effectiveness_values = list(20, 30, 40)

