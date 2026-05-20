/datum/cy_skill_perk/professional/electricity
	skill_type = /datum/cy_skill/professional/electricity

/datum/cy_skill_perk/professional/electricity/level_1
	id = "electricity_1"
	level = 1
	name = "Electricity 1"
	desc_template = "No rubber-glove shock penalty."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/electricity/level_2
	id = "electricity_2"
	level = 2
	name = "Electricity 2"
	desc_template = "Electric shock paralysis is {value_1} seconds shorter."
	effects = list(
		"level" = 2,
		"value_1" = 2
	)

/datum/cy_skill_perk/professional/electricity/level_3
	id = "electricity_3"
	level = 3
	name = "Electricity 3"
	desc_template = "Live wire shock chance is reduced to {value_1}%."
	effects = list(
		"level" = 3,
		"value_1" = 50
	)

/datum/cy_skill_perk/professional/electricity/level_4
	id = "electricity_4"
	level = 4
	name = "Electricity 4"
	desc_template = "{value_1}% chance to avoid shock when grabbing or holding an electrocuted person."
	effects = list(
		"level" = 4,
		"value_1" = 50
	)

/datum/cy_skill_perk/professional/electricity/level_5
	id = "electricity_5"
	level = 5
	name = "Electricity 5"
	desc_template = "Signal types are highlighted when dismantling protected panels."
	effects = list(
		"level" = 5,
	)

/datum/cy_skill_perk/professional/electricity/level_6
	id = "electricity_6"
	level = 6
	name = "Electricity 6"
	desc_template = "Shock chance is reduced by {value_1}% even without insulation."
	effects = list(
		"level" = 6,
		"value_1" = 50
	)
