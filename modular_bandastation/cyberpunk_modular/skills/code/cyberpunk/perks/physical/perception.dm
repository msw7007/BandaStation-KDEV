// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/perception/precise_unarmed/perk_1
	name = "Начинающий"
	desc = "+{value}% к точности удара."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/perception/precise_unarmed/perk_2
	name = "Умелый"
	desc = "+{value}% значения восприятия при расчете точности удара руками или имплантами."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/perception/precise_unarmed/perk_3
	name = "Обученный"
	desc = "Удар рукой имеет {value}% шанс нанести дополнительно двойное значение боли."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/perception/precise_unarmed/perk_4
	name = "Эксперт"
	desc = "Удар в ноги может замедлить на {value_1}% на {value_2} секунд; удар по руке может отключить ее на {value_3} секунд; удар по голове может дезориентировать на {value_4} секунды."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(10, 15, 20),
		"value_3" = list(5, 7.5, 10),
		"value_4" = list(2, 3, 4),
	)

/datum/skill_perk/physical/perception/precise_unarmed/perk_5
	name = "Профессионал"
	desc = "{value_1}% шанс усилить шансы зональных атак до {value_2}%."
	effectiveness_values = list(50, 75, 100)
	effectiveness_by_key = list(
		"value_1" = list(50, 75, 100),
		"value_2" = list(50, 75, 100),
	)

/datum/skill_perk/physical/perception/precise_unarmed/perk_6
	name = "Мастер"
	desc = "Все шансы по конечностям получают +{value_1}%; удар в торс имеет {value_2}% шанс уронить противника."
	effectiveness_values = list(10, 15, 20)
	effectiveness_by_key = list(
		"value_1" = list(10, 15, 20),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/perception/precise_weapon/perk_1
	name = "Начинающий"
	desc = "+{value} тайл к максимальной дальности броска."
	effectiveness_values = list(1, 1.5, 2)

/datum/skill_perk/physical/perception/precise_weapon/perk_2
	name = "Умелый"
	desc = "+{value}% к урону броском, прицельным выстрелом или усиленным интентом."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/perception/precise_weapon/perk_3
	name = "Обученный"
	desc = "Бонус точного выстрела работает на +{value_1} тайлов; при ударе оружием откат интента снижается на {value_2}%."
	effectiveness_values = list(5, 7.5, 10)
	effectiveness_by_key = list(
		"value_1" = list(5, 7.5, 10),
		"value_2" = list(30, 45, 60),
	)

/datum/skill_perk/physical/perception/precise_weapon/perk_4
	name = "Эксперт"
	desc = "Урон точного выстрела и заряженных интентов увеличивается на {value}%."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/perception/precise_weapon/perk_5
	name = "Профессионал"
	desc = "Попадание выстрелом или заряженным интентом дает следующему обычному выстрелу или интенту +{value}% на попадание."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/perception/precise_weapon/perk_6
	name = "Мастер"
	desc = "Точный выстрел можно активировать в движении; оружие ближнего боя усиленными интентами выбивает предметы из рук цели."

/datum/skill_perk/physical/perception/weakness_analysis/perk_1
	name = "Начинающий"
	desc = "Удары могут стать критическими с шансом {value_1}%; крит не чаще одного раза в {value_2} секунд."
	effectiveness_values = list(10, 15, 20)
	effectiveness_by_key = list(
		"value_1" = list(10, 15, 20),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/perception/weakness_analysis/perk_2
	name = "Умелый"
	desc = "{value}% шанс, что критический удар станет тройным по урону."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/perception/weakness_analysis/perk_3
	name = "Обученный"
	desc = "Критический удар имеет {value}% шанс поставить или усилить травму конечности."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/perception/weakness_analysis/perk_4
	name = "Эксперт"
	desc = "Критическая рана любого уровня оглушает противника на {value} секунды."
	effectiveness_values = list(2, 3, 4)

/datum/skill_perk/physical/perception/weakness_analysis/perk_5
	name = "Профессионал"
	desc = "Критический удар больше не имеет временного ограничения и может идти цепью."

/datum/skill_perk/physical/perception/weakness_analysis/perk_6
	name = "Мастер"
	desc = "{value}% шанс, что критический удар проигнорирует броню и нанесет прямой урон телу."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/perception/concentration/perk_1
	name = "Начинающий"
	desc = "+{value}% к вероятности успешного парирования."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/perception/concentration/perk_2
	name = "Умелый"
	desc = "Успешное парирование тратит на {value_1}% меньше выносливости, неуспешное на {value_2}% меньше."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(15, 22.5, 30),
	)

/datum/skill_perk/physical/perception/concentration/perk_3
	name = "Обученный"
	desc = "При успешном парировании есть {value}% шанс, что оружие не будет повреждено."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/perception/concentration/perk_4
	name = "Эксперт"
	desc = "Парирование двумя оружиями больше не имеет штрафа {value}%."
	effectiveness_values = list(15, 22.5, 30)

/datum/skill_perk/physical/perception/concentration/perk_5
	name = "Профессионал"
	desc = "Парируя атаку, вы с {value}% шансом открываете брешь, и следующий удар пройдет гарантированно."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/perception/concentration/perk_6
	name = "Мастер"
	desc = "Успешное парирование с {value}% шансом выбьет оружие противника в сторону."
	effectiveness_values = list(50, 75, 100)

