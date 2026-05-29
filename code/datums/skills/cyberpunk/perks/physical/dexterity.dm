// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_1
	name = "Начинающий"
	desc = "+{value}% к скорости удара."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_2
	name = "Умелый"
	desc = "+{value}% значения ловкости при расчете времени отката удара руками или имплантами."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_3
	name = "Обученный"
	desc = "+{value}% шанс, что после удара ногой не будет отката для следующего удара."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_4
	name = "Эксперт"
	desc = "После успешного удара ногой откат удара рукой с {value}% шансом не тратит выносливость."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_5
	name = "Профессионал"
	desc = "Удар ногой с {value}% шансом вызывает пошатывание."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/dexterity/fast_unarmed/perk_6
	name = "Мастер"
	desc = "Удар ногой по пошатывающемуся противнику с {value_1}% шансом оглушает на {value_2} секунды."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(2, 3, 4),
	)

/datum/skill_perk/physical/dexterity/light_weapon/perk_1
	name = "Начинающий"
	desc = "+{value}% скорости перезарядки оружия в руках."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/dexterity/light_weapon/perk_2
	name = "Умелый"
	desc = "При ударе оружием ближнего боя или прикладом время отката сокращается на {value}%."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/dexterity/light_weapon/perk_3
	name = "Обученный"
	desc = "При стрельбе и атаке оружием есть {value}% шанс повторного бесплатного выстрела или удара."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/dexterity/light_weapon/perk_4
	name = "Эксперт"
	desc = "Неприцельная стрельба снижает откат следующего выстрела на {value_1}%; усиленные интенты требуют на {value_2}% меньше времени."
	effectiveness_values = list(40, 60, 80)
	effectiveness_by_key = list(
		"value_1" = list(40, 60, 80),
		"value_2" = list(40, 60, 80),
	)

/datum/skill_perk/physical/dexterity/light_weapon/perk_5
	name = "Профессионал"
	desc = "Скорость доставания оружия сокращается на {value_1}%; восстановление интентов оружия сокращается на {value_2}%."
	effectiveness_values = list(50, 75, 100)
	effectiveness_by_key = list(
		"value_1" = list(50, 75, 100),
		"value_2" = list(40, 60, 80),
	)

/datum/skill_perk/physical/dexterity/light_weapon/perk_6
	name = "Мастер"
	desc = "Можно атаковать во время долгих действий с эффективностью {value}% по времени отката."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/dexterity/acrobatics/perk_1
	name = "Начинающий"
	desc = "С {value}% шансом после прыжка вы не сделаете движение на дополнительный тайл."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/dexterity/acrobatics/perk_2
	name = "Умелый"
	desc = "На {value}% сокращаются долгие действия лазанья и перебирания."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/dexterity/acrobatics/perk_3
	name = "Обученный"
	desc = "Прыжок позволяет ослабить захват; прыжки и лазанье тратят на {value}% меньше выносливости."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/dexterity/acrobatics/perk_4
	name = "Эксперт"
	desc = "После действия акробатики кукла на {value_1} секунд получает +{value_2}% скорости перемещения."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/dexterity/acrobatics/perk_5
	name = "Профессионал"
	desc = "Персонаж всегда получает +{value}% к скорости перемещения."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/dexterity/acrobatics/perk_6
	name = "Мастер"
	desc = "Подъемы и спуски мгновенны; можно прыгать между Z; падение на уровень без прыжка не наносит урон."

/datum/skill_perk/physical/dexterity/evasion/perk_1
	name = "Начинающий"
	desc = "+{value}% к шансу успешного уворота."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/dexterity/evasion/perk_2
	name = "Умелый"
	desc = "Успешный уворот тратит на {value_1}% меньше выносливости, неуспешный на {value_2}% меньше."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/dexterity/evasion/perk_3
	name = "Обученный"
	desc = "+{value}% шанс вызвать пошатывание противника после уворота."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/dexterity/evasion/perk_4
	name = "Эксперт"
	desc = "При попытке захвата на вас есть {value}% шанс, что при успешном увороте атакующий схватит сам себя."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/dexterity/evasion/perk_5
	name = "Профессионал"
	desc = "Можно уклоняться без видимости цели; успешный уворот не перемещает куклу; можно уклоняться от предметов и выстрелов."

/datum/skill_perk/physical/dexterity/evasion/perk_6
	name = "Мастер"
	desc = "При успешном увороте есть {value_1}% шанс стать невидимым для противника на {value_2} секунды."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(2, 3, 4),
	)

