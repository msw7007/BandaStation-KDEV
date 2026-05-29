// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/spirit/survival/perk_1
	name = "Начинающий"
	desc = "Голод, жажда и сон наступают на {value}% медленнее."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/spirit/survival/perk_2
	name = "Умелый"
	desc = "Пища, вода и сон эффективнее на {value_1}%; пороги переедания увеличены на {value_2}%."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(40, 60, 80),
	)

/datum/skill_perk/physical/spirit/survival/perk_3
	name = "Обученный"
	desc = "Критические жажда, голод и сонливость вызывают только {value}% замедления."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/spirit/survival/perk_4
	name = "Эксперт"
	desc = "Получает {value}% силы бонусов комфортного сна, засыпая в кресле или на земле."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/spirit/survival/perk_5
	name = "Профессионал"
	desc = "Время подготовки ко сну сокращается на {value}%."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/spirit/survival/perk_6
	name = "Мастер"
	desc = "Сила снижения характеристик от голода, сонливости и жажды снижена на {value}%."
	effectiveness_values = list(33, 49.5, 66)

/datum/skill_perk/physical/spirit/endurance/perk_1
	name = "Начинающий"
	desc = "На {value}% повышает показатель, при котором конечность теряет эффективность."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/spirit/endurance/perk_2
	name = "Умелый"
	desc = "На {value}% повышает показатель, при котором персонаж падает от боли."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/spirit/endurance/perk_3
	name = "Обученный"
	desc = "Замедление от негативного настроя снижено на {value}%."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/spirit/endurance/perk_4
	name = "Эксперт"
	desc = "При получении урона есть {value}% шанс, что боль после удара не будет применена."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/spirit/endurance/perk_5
	name = "Профессионал"
	desc = "Вместо падения от боли персонаж иммобилизуется на {value} секунды."
	effectiveness_values = list(3, 2, 1)

/datum/skill_perk/physical/spirit/endurance/perk_6
	name = "Мастер"
	desc = "Эффекты негативных мудлетов и боли снижены на {value}%."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/spirit/athletics/perk_1
	name = "Начинающий"
	desc = "{value}% расход сил при беге или боевых действиях."
	effectiveness_values = list(-10, -15, -20)

/datum/skill_perk/physical/spirit/athletics/perk_2
	name = "Умелый"
	desc = "+{value_1}% к запасу выносливости и +{value_2}% к запасу сил."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(20, 30, 40),
	)

/datum/skill_perk/physical/spirit/athletics/perk_3
	name = "Обученный"
	desc = "Перенос тяжелых вещей снижает скорость до {value}%."
	effectiveness_values = list(50, 70, 90)

/datum/skill_perk/physical/spirit/athletics/perk_4
	name = "Эксперт"
	desc = "+{value}% к скорости спринта, пока запас сил выше 80%."
	effectiveness_values = list(20, 20, 20)
	effectiveness_by_key = list(
		"value_1" = list(20, 20, 20),
		"value_2" = list(80, 60, 40),
	)

/datum/skill_perk/physical/spirit/athletics/perk_5
	name = "Профессионал"
	desc = "Дополнительно +{value} выносливости при конвертации запаса сил в выносливость."
	effectiveness_values = list(1, 2, 3)

/datum/skill_perk/physical/spirit/athletics/perk_6
	name = "Мастер"
	desc = "Таймер начала регенерации выносливости снижается на {value}%."
	effectiveness_values = list(45, 67.5, 90)

/datum/skill_perk/physical/spirit/compatibility/perk_1
	name = "Начинающий"
	desc = "{value}% к перегреву от имплантов."
	effectiveness_values = list(-10, -15, -20)

/datum/skill_perk/physical/spirit/compatibility/perk_2
	name = "Умелый"
	desc = "Хромированность повышается на {value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/spirit/compatibility/perk_3
	name = "Обученный"
	desc = "При превышении перегрева импланты не могут наносить больше {value} урона мозгу за тик."
	effectiveness_values = list(2, 1, 0.5)

/datum/skill_perk/physical/spirit/compatibility/perk_4
	name = "Эксперт"
	desc = "Эффективность и сила имплантов увеличиваются на {value}%."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/spirit/compatibility/perk_5
	name = "Профессионал"
	desc = "При перегрузе боль заменяется замедлением по превышению в соотношении {value}:{value}."
	effectiveness_values = list(1, 1, 1)
	effectiveness_by_key = list(
		"value_1" = list(1, 1, 1),
		"value_2" = list(1, 2, 3),
	)

/datum/skill_perk/physical/spirit/compatibility/perk_6
	name = "Мастер"
	desc = "Перегруз имплантов увеличивает эффективность на {value_1}% и снижает урон мозгу на {value_2}%."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(50, 75, 100),
	)

