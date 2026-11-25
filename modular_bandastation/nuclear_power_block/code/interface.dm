/obj/machinery/power/nuclear_power_block/ui_state(mob/user)
	return GLOB.physical_state

/// Physical TGUI distance uses the southwest anchor; extend touch access to the actual footprint.
/obj/machinery/power/nuclear_power_block/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(state == GLOB.physical_state && isliving(user) && Adjacent(user) && can_interact(user))
		. = min(user.shared_ui_interaction(src), ui_status_user_has_free_hands(user, src), ui_status_user_is_advanced_tool_user(user))

/obj/machinery/power/nuclear_power_block/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NuclearPowerBlock", name)
		ui.open()

/// Recheck actual supply at the action boundary rather than trusting the previous process tick.
/obj/machinery/power/nuclear_power_block/proc/controls_available()
	if(machine_stat & (BROKEN | EMPED))
		return FALSE
	var/supply = energy_to_power(surplus())
	for(var/datum/nuclear_power_turbine/turbine as anything in turbines)
		supply += turbine.generate_power(chamber_temperature, minimum_generation_temperature())
	return supply >= NUCLEAR_POWER_BLOCK_CONTROL_POWER

/obj/machinery/power/nuclear_power_block/ui_data(mob/user)
	update_coolant()
	var/list/turbine_data = list()
	for(var/datum/nuclear_power_turbine/turbine as anything in turbines)
		turbine_data += list(list(
			"name" = turbine.name,
			"tier" = turbine.tier,
			"rpm" = turbine.rpm,
			"target" = turbine.target_rpm,
			"condition" = turbine.condition,
			"capacity" = turbine.capacity(),
			"generation" = turbine.generation,
			"consumption" = turbine.consumption,
			"powered" = turbine.driven,
			"manual" = !!turbine.manual_user?.resolve(),
		))
	var/list/beaker_data = list()
	for(var/index in 1 to length(coolant_beakers))
		var/obj/item/reagent_containers/cup/beaker/beaker = coolant_beakers[index]
		var/list/chemicals = list()
		if(beaker)
			for(var/datum/reagent/chemical as anything in beaker.reagents.reagent_list)
				chemicals += chemical.name
		beaker_data += list(list(
			"index" = index,
			"installed" = !!beaker,
			"name" = beaker?.name,
			"capacity" = beaker?.reagents.maximum_volume || 0,
			"volume" = beaker?.reagents.total_volume || 0,
			"temperature" = beaker?.reagents.chem_temp,
			"contents" = jointext(chemicals, ", "),
		))
	return list(
		"nominalRate" = NUCLEAR_POWER_BLOCK_NOMINAL_RATE,
		"maxRpm" = NUCLEAR_POWER_BLOCK_MAX_RPM,
		"ventTemperature" = NUCLEAR_POWER_BLOCK_VALVE_TEMPERATURE,
		"baseFlow" = NUCLEAR_POWER_BLOCK_WATER_PER_SECOND * 60,
		"powered" = controls_available(),
		"panel" = panel_open,
		"rate" = reaction_rate,
		"targetRate" = target_reaction_rate,
		"chain" = reaction_rate >= NUCLEAR_POWER_BLOCK_CHAIN_RATE,
		"rods" = rod_insertion,
		"fuel" = fuel,
		"emitters" = emitter_count,
		"temperature" = chamber_temperature,
		"targetTemperature" = target_temperature,
		"gross" = gross_generation,
		"consumption" = internal_consumption,
		"net" = net_generation,
		"heat" = heat_input,
		"cooling" = cooling_output,
		"coolant" = coolant_volume,
		"capacity" = coolant_capacity,
		"efficiency" = coolant_efficiency,
		"flow" = coolant_flow * 60,
		"fuelMultiplier" = fuel_multiplier,
		"wearMultiplier" = wear_multiplier,
		"ambientTemperature" = ambient_temperature,
		"pressure" = ambient_pressure,
		"circulation" = circulation,
		"turbines" = turbine_data,
		"beakers" = beaker_data,
	)

/obj/machinery/power/nuclear_power_block/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!Adjacent(ui.user) || ui.user.incapacitated || HAS_TRAIT(ui.user, TRAIT_HANDS_BLOCKED))
		return FALSE
	if(action == "ejectBeaker")
		var/index = text2num(params["index"])
		if(!isnum(index))
			return FALSE
		return eject_beaker(ui.user, index)
	if(!controls_available())
		return FALSE
	var/value = text2num(params["value"])
	if(!isnum(value))
		return FALSE
	switch(action)
		if("rods")
			rod_insertion = clamp(value, 0, 100)
			return TRUE
		if("rpm")
			var/index = text2num(params["index"])
			if(!isnum(index) || !ISINTEGER(index) || index < 1 || index > length(turbines))
				return FALSE
			var/datum/nuclear_power_turbine/turbine = turbines[index]
			if(turbine.condition <= 0 || turbine.tier <= 0)
				return FALSE
			turbine.target_rpm = clamp(value, 0, NUCLEAR_POWER_BLOCK_MAX_RPM)
			return TRUE
	return FALSE
