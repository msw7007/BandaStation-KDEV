/datum/skill/weapon
	abstract_type = /datum/skill/weapon
	skill_kind = CHARACTER_SKILL_KIND_WEAPON
	point_pool = CHARACTER_SKILL_POOL_SKILL
	max_character_level = WEAPON_SKILL_MAX_LEVEL
	weapon_damage_bonus_per_level = 0.1
	weapon_cooldown_reduction_per_level = 0.05
	weapon_defense_break_bonus_per_level = 5
	desc = "Оружейный навык: каждый уровень дает +10% урона, -5% отката атаки и +5% к пробитию парирования или уворота."

/datum/skill/weapon/daggers
	name = "Кинжалы"
	title = "Кинжальщик"
	attribute_id = ATTRIBUTE_DEXTERITY

/datum/skill/weapon/light_slashing
	name = "Легкое режущее"
	title = "Фехтовальщик легкого клинка"
	attribute_id = ATTRIBUTE_DEXTERITY

/datum/skill/weapon/light_blunt
	name = "Легкое дробящее"
	title = "Боец легкого дробящего"
	attribute_id = ATTRIBUTE_DEXTERITY

/datum/skill/weapon/polearms
	name = "Древковое"
	title = "Боец древкового"
	attribute_id = ATTRIBUTE_DEXTERITY

/datum/skill/weapon/light_ranged
	name = "Легкое дальнобойное"
	title = "Стрелок легкого оружия"
	attribute_id = ATTRIBUTE_DEXTERITY

/datum/skill/weapon/heavy_slashing
	name = "Тяжелое режущее"
	title = "Боец тяжелого клинка"
	attribute_id = ATTRIBUTE_STRENGTH

/datum/skill/weapon/heavy_blunt
	name = "Тяжелое дробящее"
	title = "Боец тяжелого дробящего"
	attribute_id = ATTRIBUTE_STRENGTH

/datum/skill/weapon/chopping
	name = "Рубящее"
	title = "Рубящий боец"
	attribute_id = ATTRIBUTE_STRENGTH

/datum/skill/weapon/heavy_ranged
	name = "Тяжелое дальнобойное"
	title = "Стрелок тяжелого оружия"
	attribute_id = ATTRIBUTE_STRENGTH

/datum/skill/weapon/medium_ranged
	name = "Среднее дальнобойное"
	title = "Стрелок среднего оружия"
	attribute_id = ATTRIBUTE_STRENGTH

/datum/skill/weapon/light_piercing
	name = "Легкое колющее"
	title = "Боец легкого колющего"
	attribute_id = ATTRIBUTE_PERCEPTION

/datum/skill/weapon/heavy_piercing
	name = "Тяжелое колющее"
	title = "Боец тяжелого колющего"
	attribute_id = ATTRIBUTE_PERCEPTION

/datum/skill/weapon/precise_ranged
	name = "Точное дальнобойное"
	title = "Точный стрелок"
	attribute_id = ATTRIBUTE_PERCEPTION
