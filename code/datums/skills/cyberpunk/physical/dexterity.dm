/datum/skill/physical/dexterity
	abstract_type = /datum/skill/physical/dexterity
	attribute_id = ATTRIBUTE_DEXTERITY
	giga_perk_name = "Змеевидность"
	giga_perk_desc = "Удары могут не запускать откат с шансом навыка * 15%; прыжок может сбить цель; уворот может заставить противника атаковать себя."

/datum/skill/physical/dexterity/fast_unarmed
	name = "Быстрый рукопашный бой"
	title = "Боец быстрого стиля"
	desc = "Скорость ударов руками, ногами и имплантами."
	perk_types = list(
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_1,
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_2,
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_3,
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_4,
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_5,
		/datum/skill_perk/physical/dexterity/fast_unarmed/perk_6,
	)

/datum/skill/physical/dexterity/light_weapon
	name = "Легкое оружие"
	title = "Скоростной оружейник"
	desc = "Быстрые атаки, перезарядка и смена оружия."
	perk_types = list(
		/datum/skill_perk/physical/dexterity/light_weapon/perk_1,
		/datum/skill_perk/physical/dexterity/light_weapon/perk_2,
		/datum/skill_perk/physical/dexterity/light_weapon/perk_3,
		/datum/skill_perk/physical/dexterity/light_weapon/perk_4,
		/datum/skill_perk/physical/dexterity/light_weapon/perk_5,
		/datum/skill_perk/physical/dexterity/light_weapon/perk_6,
	)

/datum/skill/physical/dexterity/acrobatics
	name = "Акробатика"
	title = "Акробат"
	desc = "Прыжки, лазанье, перемещение между уровнями."
	perk_types = list(
		/datum/skill_perk/physical/dexterity/acrobatics/perk_1,
		/datum/skill_perk/physical/dexterity/acrobatics/perk_2,
		/datum/skill_perk/physical/dexterity/acrobatics/perk_3,
		/datum/skill_perk/physical/dexterity/acrobatics/perk_4,
		/datum/skill_perk/physical/dexterity/acrobatics/perk_5,
		/datum/skill_perk/physical/dexterity/acrobatics/perk_6,
	)

/datum/skill/physical/dexterity/evasion
	name = "Изворотливость"
	title = "Уклоняющийся"
	desc = "Увороты, реакция и защита движением."
	perk_types = list(
		/datum/skill_perk/physical/dexterity/evasion/perk_1,
		/datum/skill_perk/physical/dexterity/evasion/perk_2,
		/datum/skill_perk/physical/dexterity/evasion/perk_3,
		/datum/skill_perk/physical/dexterity/evasion/perk_4,
		/datum/skill_perk/physical/dexterity/evasion/perk_5,
		/datum/skill_perk/physical/dexterity/evasion/perk_6,
	)
