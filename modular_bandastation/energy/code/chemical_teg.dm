/obj/machinery/power/cyberpunk_generator/chemical_teg
	name = "chemical thermoelectric generator"
	desc = "A compact TEG that runs on hot and cold reagent cartridges instead of atmos pipe math."
	icon_state = "rtg"
	base_power_gen = 8 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_BENN
	cyberpunk_required_technology_id = "benn_chemical_teg"
	circuit = /obj/item/circuitboard/machine/cyberpunk_chemical_teg
	var/hot_reagent_units = 0
	var/cold_reagent_units = 0
	var/hot_temperature = T20C + 250
	var/cold_temperature = T20C - 80
	var/max_reagent_units = 200

/obj/machinery/power/cyberpunk_generator/chemical_teg/get_power_gen()
	var/delta = max(hot_temperature - cold_temperature, 0)
	var/feed = min(hot_reagent_units, cold_reagent_units) / max(max_reagent_units, 1)
	return base_power_gen * clamp(delta / 450, 0, 4) * clamp(feed, 0, 1) * get_condition_multiplier()

/obj/machinery/power/cyberpunk_generator/chemical_teg/process_generator(seconds_per_tick)
	if(hot_reagent_units <= 0 || cold_reagent_units <= 0)
		return FALSE
	var/used = max(0.25, seconds_per_tick)
	hot_reagent_units = max(0, hot_reagent_units - used)
	cold_reagent_units = max(0, cold_reagent_units - used)
	heat += clamp((hot_temperature - cold_temperature) / 200, 0, 12) * seconds_per_tick
	if(heat > critical_heat && prob(15))
		spawn_gas_cloud(get_turf(src), /datum/gas_effect/chemical, 35, heat)
	return TRUE

/obj/machinery/power/cyberpunk_generator/chemical_teg/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/reagent_containers/cup))
		var/obj/item/reagent_containers/cup/cup = item
		var/available = cup.reagents?.total_volume || 0
		var/is_hot_feed = cup.reagents?.chem_temp >= T20C
		var/available_space = max_reagent_units - (is_hot_feed ? hot_reagent_units : cold_reagent_units)
		var/added = min(available_space, available)
		if(added <= 0)
			return ..()
		if(is_hot_feed)
			hot_temperature = ((hot_temperature * hot_reagent_units) + (cup.reagents.chem_temp * added)) / max(hot_reagent_units + added, 1)
			hot_reagent_units += added
		else
			cold_temperature = ((cold_temperature * cold_reagent_units) + (cup.reagents.chem_temp * added)) / max(cold_reagent_units + added, 1)
			cold_reagent_units += added
		cup.reagents.remove_all(added)
		balloon_alert(user, is_hot_feed ? "hot feed loaded" : "cold feed loaded")
		return
	return ..()

/obj/machinery/power/cyberpunk_generator/chemical_teg/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Hot/cold feed: [round(hot_reagent_units)]/[round(cold_reagent_units)] units.")

/obj/machinery/power/cyberpunk_generator/chemical_teg/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "chemical_teg",
		"hot_units" = round(hot_reagent_units, 0.1),
		"cold_units" = round(cold_reagent_units, 0.1),
		"max_units" = max_reagent_units,
		"hot_ratio" = clamp(hot_reagent_units / max(max_reagent_units, 1), 0, 1),
		"cold_ratio" = clamp(cold_reagent_units / max(max_reagent_units, 1), 0, 1),
		"hot_temperature" = round(hot_temperature - T0C, 0.1),
		"cold_temperature" = round(cold_temperature - T0C, 0.1),
		"delta" = round(max(hot_temperature - cold_temperature, 0), 0.1),
	)

/obj/machinery/power/cyberpunk_generator/chemical_teg/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("purge_hot")
			hot_reagent_units = 0
			return TRUE
		if("purge_cold")
			cold_reagent_units = 0
			return TRUE
		if("purge_all")
			hot_reagent_units = 0
			cold_reagent_units = 0
			set_active(FALSE)
			return TRUE
	return FALSE

/obj/machinery/power/cyberpunk_generator/gasoline
	name = "gasoline generator"
	desc = "A compact fuel-fed generator. Feed it welding fuel or equivalent gasoline blend and connect it to a cable node."
	icon_state = "portgen0"
	base_icon_state = "portgen0"
	base_power_gen = 6 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_RYAZNOV
	circuit = /obj/item/circuitboard/machine/cyberpunk_chemical_teg
	var/fuel_units = 0
	var/max_fuel_units = 250
	var/fuel_burn_rate = 1

/obj/machinery/power/cyberpunk_generator/gasoline/get_power_gen()
	if(fuel_units <= 0)
		return 0
	return ..()

/obj/machinery/power/cyberpunk_generator/gasoline/process_generator(seconds_per_tick)
	if(fuel_units <= 0)
		return FALSE
	var/used = fuel_burn_rate * max(seconds_per_tick, 0.25) * power_output
	fuel_units = max(0, fuel_units - used)
	heat += clamp(power_output * 3, 1, 12) * seconds_per_tick
	wear = min(max_wear * 2, wear + (0.05 * seconds_per_tick * power_output))
	apply_cyberpunk_machine_wear(0.5 * seconds_per_tick * power_output, "use")
	if(heat > critical_heat && prob(10))
		spawn_gas_cloud(get_turf(src), /datum/gas_effect/smoke, 20, heat)
	return TRUE

/obj/machinery/power/cyberpunk_generator/gasoline/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/reagent_containers/cup))
		var/obj/item/reagent_containers/cup/cup = item
		var/available = cup.reagents?.get_reagent_amount(/datum/reagent/fuel) || 0
		var/available_space = max_fuel_units - fuel_units
		var/added = min(available_space, available)
		if(added <= 0)
			balloon_alert(user, "no fuel")
			return TRUE
		cup.reagents.remove_reagent(/datum/reagent/fuel, added)
		fuel_units += added
		balloon_alert(user, "fuel loaded")
		return TRUE
	return ..()

/obj/machinery/power/cyberpunk_generator/gasoline/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Fuel: [round(fuel_units)]/[max_fuel_units] units.")

/obj/machinery/power/cyberpunk_generator/gasoline/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "gasoline",
		"fuel" = round(fuel_units, 0.1),
		"max_fuel" = max_fuel_units,
		"fuel_ratio" = clamp(fuel_units / max(max_fuel_units, 1), 0, 1),
	)

/obj/machinery/power/cyberpunk_generator/gasoline/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("purge_fuel")
			fuel_units = 0
			set_active(FALSE)
			return TRUE
	return FALSE
