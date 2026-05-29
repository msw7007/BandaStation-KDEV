// Concrete Cyberpunk perk datums. Skills reference these types through perk_types.

/datum/skill_perk/physical/strength/power_unarmed/perk_1
	name = "Начинающий"
	desc = "+{value}% к силе удара."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/strength/power_unarmed/perk_2
	name = "Умелый"
	desc = "+{value}% значения силы при расчете силы удара руками."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/strength/power_unarmed/perk_3
	name = "Обученный"
	desc = "При парировании вашего удара наносится дополнительно {value}% значения силы по экипировке."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/power_unarmed/perk_4
	name = "Эксперт"
	desc = "При нанесении удара есть {value}% шанс вызвать пошатывание противника."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/power_unarmed/perk_5
	name = "Профессионал"
	desc = "При ударе по пошатывающемуся противнику есть {value}% шанс вызвать оглушение."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/strength/power_unarmed/perk_6
	name = "Мастер"
	desc = "При ударе по оглушенному противнику есть {value}% шанс провести апперкот и уронить цель."
	effectiveness_values = list(40, 60, 80)

/datum/skill_perk/physical/strength/heavy_weapon/perk_1
	name = "Начинающий"
	desc = "+{value}% скорости передвижения с оружием в руках."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/strength/heavy_weapon/perk_2
	name = "Умелый"
	desc = "При ударе оружием ближнего боя или прикладом учитывается +{value}% силы."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/strength/heavy_weapon/perk_3
	name = "Обученный"
	desc = "Урон по экипировке противника увеличивается на {value}% от показателя силы."
	effectiveness_values = list(100, 150, 200)

/datum/skill_perk/physical/strength/heavy_weapon/perk_4
	name = "Эксперт"
	desc = "При выстреле вероятность отклонения снижается на {value_1}%; при ударе оружием затраты выносливости снижаются на {value_2}%."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(20, 30, 40),
	)

/datum/skill_perk/physical/strength/heavy_weapon/perk_5
	name = "Профессионал"
	desc = "Попадание оружием, выстрелом или броском дает +{value}% к шансу критической раны первого уровня."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/heavy_weapon/perk_6
	name = "Мастер"
	desc = "При движении и стрельбе из тяжелого оружия отклонение снижается на {value_1}%; оружие ближнего боя имеет {value_2}% шанс уронить цель."
	effectiveness_values = list(30, 45, 60)
	effectiveness_by_key = list(
		"value_1" = list(30, 45, 60),
		"value_2" = list(10, 15, 20),
	)

/datum/skill_perk/physical/strength/grappling/perk_1
	name = "Начинающий"
	desc = "+{value}% к шансу усилить захват."
	effectiveness_values = list(10, 15, 20)

/datum/skill_perk/physical/strength/grappling/perk_2
	name = "Умелый"
	desc = "Силовые приемы наносят на {value_1}% больше урона при хвате одной рукой и на {value_2}% при хвате двумя."
	effectiveness_values = list(10, 15, 20)
	effectiveness_by_key = list(
		"value_1" = list(10, 15, 20),
		"value_2" = list(30, 45, 60),
	)

/datum/skill_perk/physical/strength/grappling/perk_3
	name = "Обученный"
	desc = "При захвате двумя руками прочность захвата получает бонус {value}% значения силы."
	effectiveness_values = list(50, 75, 100)

/datum/skill_perk/physical/strength/grappling/perk_4
	name = "Эксперт"
	desc = "Применение или усиление хвата тратит на {value}% меньше выносливости."
	effectiveness_values = list(30, 45, 60)

/datum/skill_perk/physical/strength/grappling/perk_5
	name = "Профессионал"
	desc = "Действия в хвате второго уровня получают +{value}% шанс успеха."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/strength/grappling/perk_6
	name = "Мастер"
	desc = "При хвате противника есть {value_1}% шанс вызвать пошатывание; суплекс с {value_2}% шансом не роняет вас."
	effectiveness_values = list(50, 75, 100)
	effectiveness_by_key = list(
		"value_1" = list(50, 75, 100),
		"value_2" = list(50, 75, 100),
	)

/datum/skill_perk/physical/strength/fortitude/perk_1
	name = "Начинающий"
	desc = "{value}% получаемого урона."
	effectiveness_values = list(-10, -15, -20)

/datum/skill_perk/physical/strength/fortitude/perk_2
	name = "Умелый"
	desc = "Внутренние органы получают +{value}% к здоровью."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/fortitude/perk_3
	name = "Обученный"
	desc = "Пошатывание длится на {value}% меньше."
	effectiveness_values = list(25, 37.5, 50)

/datum/skill_perk/physical/strength/fortitude/perk_4
	name = "Эксперт"
	desc = "Конечности получают +{value}% к прочности до порога критической раны всех уровней."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/fortitude/perk_5
	name = "Профессионал"
	desc = "Направленный против вас захват автоматически теряет {value}% прочности."
	effectiveness_values = list(20, 30, 40)

/datum/skill_perk/physical/strength/fortitude/perk_6
	name = "Мастер"
	desc = "Вы получаете на {value_1}% меньше урона; при попытке опрокинуть вас есть {value_2}% шанс не упасть."
	effectiveness_values = list(20, 30, 40)
	effectiveness_by_key = list(
		"value_1" = list(20, 30, 40),
		"value_2" = list(40, 60, 80),
	)

