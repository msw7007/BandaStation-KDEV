// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/intelligence/enhanced_code/perk_1
	name = "Начинающий"
	desc = "+{value}% к силе применяемого демона."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/intelligence/enhanced_code/perk_2
	name = "Умелый"
	desc = "+{value}% к скорости активации демона."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/intelligence/enhanced_code/perk_3
	name = "Обученный"
	desc = "Активация демона с {value_1}% шансом усилит эффекты следующего демона на {value_2}%."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(20, 30, 40),
	)

/datum/skill_perk/physical/intelligence/enhanced_code/perk_4
	name = "Эксперт"
	desc = "Можно усиливать силу демона задержкой подготовки до {value_1}%, по {value_2}% за секунду."
	effectiveness_values = list(25, 37.5, 50)
	effectiveness_by_key = list(
		"value_1" = list(25, 37.5, 50),
		"value_2" = list(5, 7.5, 10),
	)

/datum/skill_perk/physical/intelligence/enhanced_code/perk_5
	name = "Профессионал"
	desc = "При активации демона есть {value}% шанс мгновенной активации."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/intelligence/enhanced_code/perk_6
	name = "Мастер"
	desc = "При активации демона есть {value_1}% шанс усилить все эффекты в {value_2} раза."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(2, 3, 4),
	)

/datum/skill_perk/physical/intelligence/fast_code/perk_1
	name = "Начинающий"
	desc = "+{value}% к скорости подготовки демона."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/intelligence/fast_code/perk_2
	name = "Умелый"
	desc = "{value}% к затратам выносливости при активации демона."
	effectiveness_values = list(-10, -15, -20)

/datum/skill_perk/physical/intelligence/fast_code/perk_3
	name = "Обученный"
	desc = "Активация демона с {value_1}% шансом ускорит подготовку следующего демона на {value_2}%."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(20, 30, 40),
	)

/datum/skill_perk/physical/intelligence/fast_code/perk_4
	name = "Эксперт"
	desc = "Можно ускорять активацию демона задержкой подготовки до {value_1}%, по {value_2}% за секунду."
	effectiveness_values = list(50, 75, 100)
	effectiveness_by_key = list(
		"value_1" = list(50, 75, 100),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/intelligence/fast_code/perk_5
	name = "Профессионал"
	desc = "При активации демона есть {value}% шанс сбросить восстановление демона."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/intelligence/fast_code/perk_6
	name = "Мастер"
	desc = "При активации демона есть {value}% шанс, что следующий демон применится мгновенно."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/intelligence/hacking/perk_1
	name = "Начинающий"
	desc = "+{value}% шанс снижения обнаружения при начале взлома."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/intelligence/hacking/perk_2
	name = "Умелый"
	desc = "+{value}% увеличенный урон по узлам в Сети."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/intelligence/hacking/perk_3
	name = "Обученный"
	desc = "Время подключения повышено на {value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/intelligence/hacking/perk_4
	name = "Эксперт"
	desc = "Взлом можно вести с расстояния {value} тайла."
	effectiveness_values = list(2, 4, 6)

/datum/skill_perk/physical/intelligence/hacking/perk_5
	name = "Профессионал"
	desc = "{value}% шанс, что при получении урона оборудование не сообщит об этом."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/intelligence/hacking/perk_6
	name = "Мастер"
	desc = "Количество сетевых данных с каждого открытого объекта узла увеличивается на {value}."
	effectiveness_values = list(1, 1.5, 2)

/datum/skill_perk/physical/intelligence/neutralization/perk_1
	name = "Начинающий"
	desc = "{value}% шанс, что враждебный негативный эффект работает в полсилы."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/intelligence/neutralization/perk_2
	name = "Умелый"
	desc = "{value}% к длительности враждебного негативного эффекта."
	effectiveness_values = list(-20, -30, -40)

/datum/skill_perk/physical/intelligence/neutralization/perk_3
	name = "Обученный"
	desc = "Враждебный эффект после расчетов теряет {value_1}% мощности, преобразуясь в {value_2}% замедления."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(5, 7.5, 10),
	)

/datum/skill_perk/physical/intelligence/neutralization/perk_4
	name = "Эксперт"
	desc = "Враждебный эффект после расчетов теряет {value_1}% длительности, преобразуясь в {value_2}% замедления."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(5, 7.5, 10),
	)

/datum/skill_perk/physical/intelligence/neutralization/perk_5
	name = "Профессионал"
	desc = "Эффективность негативных эффектов снижена на {value}% до расчетов преобразования."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/intelligence/neutralization/perk_6
	name = "Мастер"
	desc = "Полная блокировка враждебного негативного эффекта с кулдауном {value} минуты."
	effectiveness_values = list(2, 1.5, 1)

