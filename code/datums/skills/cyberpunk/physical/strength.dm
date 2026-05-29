/datum/skill/physical/strength
	abstract_type = /datum/skill/physical/strength
	attribute_id = ATTRIBUTE_STRENGTH
	giga_perk_name = "Дробление"
	giga_perk_desc = "Кулаки, оружие и выстрелы могут ломать атакованную конечность с шансом навыка * 15%; захваты могут сразу перейти в третий уровень; крепость может отменить падение."

/datum/skill/physical/strength/power_unarmed
	name = "Силовой рукопашный бой"
	title = "Боец силового стиля"
	desc = "Силовые удары руками, ногами и имплантами."
	perk_types = list(
		/datum/skill_perk/physical/strength/power_unarmed/perk_1,
		/datum/skill_perk/physical/strength/power_unarmed/perk_2,
		/datum/skill_perk/physical/strength/power_unarmed/perk_3,
		/datum/skill_perk/physical/strength/power_unarmed/perk_4,
		/datum/skill_perk/physical/strength/power_unarmed/perk_5,
		/datum/skill_perk/physical/strength/power_unarmed/perk_6,
	)

/datum/skill/physical/strength/heavy_weapon
	name = "Тяжелое оружие"
	title = "Силовой оружейник"
	desc = "Силовое владение тяжелым оружием, прикладами и бросками."
	perk_types = list(
		/datum/skill_perk/physical/strength/heavy_weapon/perk_1,
		/datum/skill_perk/physical/strength/heavy_weapon/perk_2,
		/datum/skill_perk/physical/strength/heavy_weapon/perk_3,
		/datum/skill_perk/physical/strength/heavy_weapon/perk_4,
		/datum/skill_perk/physical/strength/heavy_weapon/perk_5,
		/datum/skill_perk/physical/strength/heavy_weapon/perk_6,
	)

/datum/skill/physical/strength/grappling
	name = "Захваты"
	title = "Борец"
	desc = "Силовые хваты, удержания и броски."
	perk_types = list(
		/datum/skill_perk/physical/strength/grappling/perk_1,
		/datum/skill_perk/physical/strength/grappling/perk_2,
		/datum/skill_perk/physical/strength/grappling/perk_3,
		/datum/skill_perk/physical/strength/grappling/perk_4,
		/datum/skill_perk/physical/strength/grappling/perk_5,
		/datum/skill_perk/physical/strength/grappling/perk_6,
	)

/datum/skill/physical/strength/fortitude
	name = "Крепость"
	title = "Крепкий боец"
	desc = "Сопротивление урону, падению и травмам."
	perk_types = list(
		/datum/skill_perk/physical/strength/fortitude/perk_1,
		/datum/skill_perk/physical/strength/fortitude/perk_2,
		/datum/skill_perk/physical/strength/fortitude/perk_3,
		/datum/skill_perk/physical/strength/fortitude/perk_4,
		/datum/skill_perk/physical/strength/fortitude/perk_5,
		/datum/skill_perk/physical/strength/fortitude/perk_6,
	)
