/datum/gas_effect/tox
	id = "tox"
	name = "toxic vapour"
	color = "#a06ec0"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 4
	spread_rate = 0.4
	decay_rate = 1.5
	filter_tags = list(GAS_FILTER_TOXIC)
	alarm_flags = CLOUD_ALARM_TOXIC
	visibility_modifier = 1

/datum/gas_effect/tox/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.04 * seconds_per_tick
	breather.adjust_tox_loss(dose)
	if(prob(15))
		breather.emote("cough")

/datum/gas_effect/co2
	id = "co2"
	name = "carbon dioxide cloud"
	color = "#8888aa"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 6
	spread_rate = 0.5
	decay_rate = 1.5
	filter_tags = list(GAS_FILTER_CO2)

/datum/gas_effect/co2/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.05 * seconds_per_tick
	breather.adjust_oxy_loss(dose)
	if(amount > 30 && prob(8 * seconds_per_tick))
		breather.adjust_drowsiness(2 SECONDS)

/datum/gas_effect/n2o
	id = "n2o"
	name = "nitrous oxide cloud"
	color = "#bba0d4"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 5
	spread_rate = 0.5
	decay_rate = 1.2
	filter_tags = list(GAS_FILTER_N2O)

/datum/gas_effect/n2o/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	breather.adjust_drowsiness(4 SECONDS * seconds_per_tick)
	if(amount > 20 && prob(20 * seconds_per_tick))
		breather.emote("giggle")
	if(amount > 60 && prob(8 * seconds_per_tick))
		breather.Sleeping(4 SECONDS)

/datum/gas_effect/smoke
	id = "smoke"
	name = "thick smoke"
	color = "#aaaaaa"
	density_type = GAS_DENSITY_NEUTRAL
	spread_threshold = 3
	spread_rate = 0.55
	decay_rate = 2
	filter_tags = list(GAS_FILTER_PARTICLE)
	alarm_flags = CLOUD_ALARM_SMOKE
	visibility_modifier = 2

/datum/gas_effect/smoke/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	if(prob(25 * seconds_per_tick))
		breather.emote("cough")
	if(amount > 25)
		breather.set_eye_blur_if_lower(4 SECONDS)

/datum/gas_effect/smoke/on_touch(atom/movable/AM, amount, seconds_per_tick)
	if(!iscarbon(AM))
		return
	var/mob/living/carbon/C = AM
	if(prob(10 * seconds_per_tick) && amount > 15)
		C.emote("cough")

/datum/gas_effect/sleeping_smoke
	id = "sleeping_smoke"
	name = "anaesthetic mist"
	color = "#cebde0"
	density_type = GAS_DENSITY_NEUTRAL
	spread_threshold = 4
	spread_rate = 0.5
	decay_rate = 2
	filter_tags = list(GAS_FILTER_PARTICLE, GAS_FILTER_CHEMICAL)

/datum/gas_effect/sleeping_smoke/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	breather.adjust_drowsiness(6 SECONDS * seconds_per_tick)
	if(amount > 20 && prob(15 * seconds_per_tick))
		breather.Sleeping(5 SECONDS)

/datum/gas_effect/fire
	id = "fire"
	name = "burning air"
	color = "#ff8030"
	icon_state = "fire"
	density_type = GAS_DENSITY_LIGHT
	spread_threshold = 8
	spread_rate = 0.35
	decay_rate = 3
	temperature_delta = 200
	filter_tags = list(GAS_FILTER_HEAT)
	affects_underwater = FALSE
	alarm_flags = CLOUD_ALARM_FIRE
	visibility_modifier = 1
	scrubbable = FALSE

/datum/gas_effect/fire/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.05 * seconds_per_tick
	breather.adjust_fire_loss(dose)
	breather.adjust_fire_stacks(0.2 * seconds_per_tick)
	if(prob(30 * seconds_per_tick))
		breather.ignite_mob()

/datum/gas_effect/fire/on_touch(atom/movable/AM, amount, seconds_per_tick)
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	L.adjust_fire_stacks(0.5 * seconds_per_tick)
	if(amount > 10 && prob(40))
		L.ignite_mob()

/datum/gas_effect/freeze
	id = "freeze"
	name = "freezing mist"
	color = "#7fb2ff"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 6
	spread_rate = 0.45
	decay_rate = 2
	temperature_delta = -120
	filter_tags = list(GAS_FILTER_COLD)
	affects_underwater = TRUE
	alarm_flags = CLOUD_ALARM_COLD

/datum/gas_effect/freeze/on_touch(atom/movable/AM, amount, seconds_per_tick)
	if(isliving(AM))
		var/mob/living/L = AM
		L.extinguish_mob()
		L.adjust_bodytemperature(-4 * seconds_per_tick, 200)

/datum/gas_effect/freeze/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	breather.adjust_bodytemperature(-2 * seconds_per_tick, 200)

/datum/gas_effect/plasma
	id = "plasma"
	name = "plasma fumes"
	color = "#ee32f0"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 4
	spread_rate = 0.4
	decay_rate = 1
	filter_tags = list(GAS_FILTER_TOXIC, GAS_FILTER_CHEMICAL)
	alarm_flags = CLOUD_ALARM_TOXIC | CLOUD_ALARM_CHEMICAL
	visibility_modifier = 1

/datum/gas_effect/plasma/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.06 * seconds_per_tick
	breather.adjust_tox_loss(dose)
	if(prob(20 * seconds_per_tick))
		breather.emote("cough")

/datum/gas_effect/oxygen
	id = "oxygen"
	name = "oxygen-rich pocket"
	color = "#c0ffe0"
	density_type = GAS_DENSITY_NEUTRAL
	spread_threshold = 8
	spread_rate = 0.3
	decay_rate = 2
	visible = FALSE
	affects_underwater = FALSE

/datum/gas_effect/oxygen/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	breather.adjust_oxy_loss(-2 * seconds_per_tick)

/datum/gas_effect/healing_smoke
	id = "healing_smoke"
	name = "medical mist"
	color = "#a8e0d0"
	density_type = GAS_DENSITY_NEUTRAL
	spread_threshold = 4
	spread_rate = 0.45
	decay_rate = 2
	filter_tags = list(GAS_FILTER_PARTICLE)
	affects_underwater = TRUE

/datum/gas_effect/healing_smoke/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	breather.adjust_brute_loss(-0.5 * seconds_per_tick)
	breather.adjust_fire_loss(-0.5 * seconds_per_tick)

/datum/gas_effect/acid
	id = "acid"
	name = "acid mist"
	color = "#9fff60"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 5
	spread_rate = 0.4
	decay_rate = 2
	filter_tags = list(GAS_FILTER_ACID, GAS_FILTER_CHEMICAL)
	alarm_flags = CLOUD_ALARM_ACID
	visibility_modifier = 1

/datum/gas_effect/acid/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.03 * seconds_per_tick
	breather.adjust_fire_loss(dose)
	if(prob(15 * seconds_per_tick))
		breather.emote("cough")

/datum/gas_effect/acid/on_touch(atom/movable/AM, amount, seconds_per_tick)
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(amount > 10)
		L.adjust_fire_loss(0.4 * seconds_per_tick)
		L.acid_act(min(amount * 0.3, 30), 5)

/datum/gas_effect/chemical
	id = "chemical"
	name = "chemical aerosol"
	color = "#d8c0ff"
	density_type = GAS_DENSITY_NEUTRAL
	spread_threshold = 4
	spread_rate = 0.5
	decay_rate = 1.5
	filter_tags = list(GAS_FILTER_CHEMICAL)
	alarm_flags = CLOUD_ALARM_CHEMICAL
	visibility_modifier = 1
	affects_underwater = TRUE

/datum/gas_effect/biohazard
	id = "biohazard"
	name = "biohazardous fog"
	color = "#7fc080"
	density_type = GAS_DENSITY_HEAVY
	spread_threshold = 5
	spread_rate = 0.35
	decay_rate = 1
	filter_tags = list(GAS_FILTER_PARTICLE, GAS_FILTER_CHEMICAL)
	alarm_flags = CLOUD_ALARM_BIOHAZARD | CLOUD_ALARM_TOXIC
	visibility_modifier = 1

/datum/gas_effect/biohazard/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	var/dose = min(amount, GAS_EFFECT_PER_TICK_MAX) * 0.02 * seconds_per_tick
	breather.adjust_tox_loss(dose)
	if(prob(8 * seconds_per_tick))
		breather.emote("cough")
