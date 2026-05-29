/datum/skill/physical/spirit
	abstract_type = /datum/skill/physical/spirit
	attribute_id = ATTRIBUTE_SPIRIT
	giga_perk_name = "Несокрушимость"
	giga_perk_desc = "Голод, жажда и сон могут не снижаться; переедание и перепитие не дебаффают; настроение, остаточная боль и траты выносливости смягчаются."

/datum/skill/physical/spirit/survival
	name = "Выживание"
	title = "Выживальщик"
	desc = "Голод, жажда, сон и комфорт."
	perk_types = list(
		/datum/skill_perk/physical/spirit/survival/perk_1,
		/datum/skill_perk/physical/spirit/survival/perk_2,
		/datum/skill_perk/physical/spirit/survival/perk_3,
		/datum/skill_perk/physical/spirit/survival/perk_4,
		/datum/skill_perk/physical/spirit/survival/perk_5,
		/datum/skill_perk/physical/spirit/survival/perk_6,
	)

/datum/skill/physical/spirit/endurance
	name = "Выдержка"
	title = "Стойкий"
	desc = "Боль, настроение и сопротивление срывам."
	perk_types = list(
		/datum/skill_perk/physical/spirit/endurance/perk_1,
		/datum/skill_perk/physical/spirit/endurance/perk_2,
		/datum/skill_perk/physical/spirit/endurance/perk_3,
		/datum/skill_perk/physical/spirit/endurance/perk_4,
		/datum/skill_perk/physical/spirit/endurance/perk_5,
		/datum/skill_perk/physical/spirit/endurance/perk_6,
	)

/datum/skill/physical/spirit/athletics
	name = "Атлетика"
	title = "Атлет"
	desc = "Выносливость, запас сил, бег и перенос тяжестей."
	perk_types = list(
		/datum/skill_perk/physical/spirit/athletics/perk_1,
		/datum/skill_perk/physical/spirit/athletics/perk_2,
		/datum/skill_perk/physical/spirit/athletics/perk_3,
		/datum/skill_perk/physical/spirit/athletics/perk_4,
		/datum/skill_perk/physical/spirit/athletics/perk_5,
		/datum/skill_perk/physical/spirit/athletics/perk_6,
	)

/datum/skill/physical/spirit/compatibility
	name = "Совместимость"
	title = "Совместимый"
	desc = "Хромированность, импланты и перегрев."
	perk_types = list(
		/datum/skill_perk/physical/spirit/compatibility/perk_1,
		/datum/skill_perk/physical/spirit/compatibility/perk_2,
		/datum/skill_perk/physical/spirit/compatibility/perk_3,
		/datum/skill_perk/physical/spirit/compatibility/perk_4,
		/datum/skill_perk/physical/spirit/compatibility/perk_5,
		/datum/skill_perk/physical/spirit/compatibility/perk_6,
	)
