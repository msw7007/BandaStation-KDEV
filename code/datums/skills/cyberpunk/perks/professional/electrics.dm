// Concrete Cyberpunk professional perk datums for /datum/skill/professional/electrics.

/datum/skill_perk/professional/electrics/perk_1
	name = "Чтение проводов"
	desc = "{value}% шанс при наведении мышкой на провод или сигнал увидеть его назначение."
	effectiveness_values = list(2, 4, 6, 8)

/datum/skill_perk/professional/electrics/perk_2
	name = "Перенос шока"
	desc = "Удар током от подключенного провода парализует на {value} секунд и наносит урон огнем."
	effectiveness_values = list(8, 6, 4, 2)

/datum/skill_perk/professional/electrics/perk_3
	name = "Изоляция"
	desc = "Шанс поражения током без изоляции снижен до {value}%."
	effectiveness_values = list(85, 60, 35, 10)

/datum/skill_perk/professional/electrics/perk_4
	name = "Цепь людей"
	desc = "Шанс поражения, если держать пораженного током человека, снижен до {value}%."
	effectiveness_values = list(90, 60, 30, 0)

/datum/skill_perk/professional/electrics/perk_5
	name = "Сервис"
	desc = "Скорость ремонта и взаимодействия увеличена на {value}%."
	effectiveness_values = list(50, 100, 150, 200)
