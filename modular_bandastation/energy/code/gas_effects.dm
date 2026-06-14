/datum/gas_effect/radiation
	id = "radiation"
	name = "radioactive fallout"
	color = "#85ff57"
	icon_state = "smoke"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 5
	spread_rate = 0.35
	decay_rate = 0.7
	filter_tags = list(GAS_FILTER_PARTICLE)
	alarm_flags = CLOUD_ALARM_TOXIC
	visibility_modifier = 1
	scrubbable = TRUE

/datum/gas_effect/radiation/on_process_cloud(obj/effect/gas_cloud/cloud, turf/T, area/A, seconds_per_tick)
	if(prob(clamp(cloud.amount * 0.25 * seconds_per_tick, 1, 20)))
		radiation_pulse(T, max_range = 1, threshold = RAD_LIGHT_INSULATION, chance = 12)

/datum/gas_effect/radiation/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	if(prob(clamp(amount * 0.2 * seconds_per_tick, 1, 25)))
		radiation_pulse(breather, max_range = 0, threshold = RAD_VERY_LIGHT_INSULATION, chance = 20)
