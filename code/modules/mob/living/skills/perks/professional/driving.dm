/datum/cy_skill_perk/professional/driving
	skill_type = /datum/cy_skill/professional/driving

/datum/cy_skill_perk/professional/driving/level_1
	id = "driving_1"
	level = 1
	name = "Driving 1"
	desc_template = "Movement speed penalty is removed."
	effects = list(
		"level" = 1,
		"movement_speed_penalty_removed" = TRUE
	)

/datum/cy_skill_perk/professional/driving/level_2
	id = "driving_2"
	level = 2
	name = "Driving 2"
	desc_template = "Vehicle reaction penalty is reduced to {value_1}%; fuel penalty is reduced by {value_2}%."
	effects = list(
		"level" = 2,
		"value_1" = 25,
		"value_2" = 10,
		"reaction_penalty_percent" = 25,
		"fuel_penalty_percent" = 10
	)

/datum/cy_skill_perk/professional/driving/level_3
	id = "driving_3"
	level = 3
	name = "Driving 3"
	desc_template = "Vehicles can install extra equipment; max {value_1} item per component or mechanism slot."
	effects = list(
		"level" = 3,
		"value_1" = 1,
		"slot_upgrade_limit" = 1
	)

/datum/cy_skill_perk/professional/driving/level_4
	id = "driving_4"
	level = 4
	name = "Driving 4"
	desc_template = "Fuel penalty is removed; maximum movement speed is increased by {value_1}%."
	effects = list(
		"level" = 4,
		"value_1" = 25,
		"fuel_penalty_removed" = TRUE,
		"max_speed_bonus_percent" = 25
	)

/datum/cy_skill_perk/professional/driving/level_5
	id = "driving_5"
	level = 5
	name = "Driving 5"
	desc_template = "Reaction penalty is removed; component or mechanism slot upgrade limit is {value_1}."
	effects = list(
		"level" = 5,
		"value_1" = 2,
		"reaction_penalty_removed" = TRUE,
		"slot_upgrade_limit" = 2
	)

/datum/cy_skill_perk/professional/driving/level_6
	id = "driving_6"
	level = 6
	name = "Driving 6"
	desc_template = "Vehicle speed, maneuver and brakes are increased by {value_1}%; fuel use is reduced by {value_2}%."
	effects = list(
		"level" = 6,
		"value_1" = 20,
		"value_2" = 10,
		"vehicle_stat_bonus_percent" = 20,
		"fuel_use_reduction_percent" = 10
	)
