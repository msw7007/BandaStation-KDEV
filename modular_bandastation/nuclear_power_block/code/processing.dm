/// Nine local turf samples, independent of the number of players or emitters on the map.
/obj/machinery/power/nuclear_power_block/proc/update_environment()
	var/temperature_sum = 0
	var/pressure_sum = 0
	var/samples = 0
	for(var/turf/footprint as anything in locs)
		var/datum/gas_mixture/air = footprint.return_air()
		if(!air)
			continue
		temperature_sum += air.temperature
		pressure_sum += air.return_pressure()
		samples++
	ambient_temperature = samples ? temperature_sum / samples : TCMB
	ambient_pressure = samples ? pressure_sum / samples : 0
	circulation = 0.1 + 0.9 * clamp(ambient_pressure / ONE_ATMOSPHERE, 0, 1)

/// Use the first nonempty vessel, or weight only the portions consumed during a processing step.
/obj/machinery/power/nuclear_power_block/proc/update_coolant(consumption = 0)
	coolant_efficiency = 0
	fuel_multiplier = 1
	wear_multiplier = 1
	coolant_volume = 0
	coolant_capacity = 0
	var/active_volume = 0
	for(var/obj/item/reagent_containers/cup/beaker/beaker in coolant_beakers)
		coolant_volume += beaker.reagents.total_volume
		coolant_capacity += beaker.reagents.maximum_volume
		if(!active_volume && beaker.reagents.total_volume > 0)
			active_volume = beaker.reagents.total_volume
	if(coolant_volume <= 0)
		return
	var/effect_volume = consumption > 0 ? min(consumption, coolant_volume) : active_volume
	var/remaining = effect_volume
	var/chemical_bonus = 0
	var/chemical_penalty = 0
	var/temperature_bonus = 0
	for(var/obj/item/reagent_containers/cup/beaker/beaker in coolant_beakers)
		var/datum/reagents/liquid = beaker.reagents
		if(liquid.total_volume <= 0)
			continue
		if(remaining <= 0)
			break
		var/used = min(remaining, liquid.total_volume)
		remaining -= used
		var/vessel_fraction = used / effect_volume
		temperature_bonus += clamp((273 - liquid.chem_temp) / 546, -0.5, 0.5) * vessel_fraction
		for(var/datum/reagent/chemical as anything in liquid.reagent_list)
			var/fraction = chemical.volume / liquid.total_volume * vessel_fraction
			if(istype(chemical, /datum/reagent/nitrogen))
				chemical_bonus += 0.25 * fraction
			else if(istype(chemical, /datum/reagent/medicine/c2/hercuri))
				chemical_bonus += 0.3 * fraction
			else if(istype(chemical, /datum/reagent/cryostylane))
				chemical_bonus += 0.4 * fraction
			else if(istype(chemical, /datum/reagent/medicine/cryoxadone))
				chemical_bonus += 0.5 * fraction
			else
				chemical_penalty += fraction * abs(chemical.ph - 7) / 7
				fuel_multiplier += 6 * fraction * clamp((7 - chemical.ph) / 7, 0, 1)
				wear_multiplier += 6 * fraction * clamp((chemical.ph - 7) / 7, 0, 1)
	coolant_efficiency = clamp(1 + temperature_bonus + chemical_bonus - chemical_penalty, 0, 2)

/obj/machinery/power/nuclear_power_block/process(seconds_per_tick)
	if(seconds_per_tick <= 0)
		return
	update_environment()
	// Bound catch-up work while preserving elapsed-time accounting after a slow subsystem tick.
	var/steps = clamp(CEILING(seconds_per_tick / NUCLEAR_POWER_BLOCK_INTERVAL, 1), 1, 10)
	for(var/step in 1 to steps)
		process_core(seconds_per_tick / steps)
		if(QDELETED(src))
			return PROCESS_KILL
	if(fuel > 0 && reaction_rate >= 1 && (!lid || panel_open))
		var/radius = lid ? 1 : 5
		radiation_pulse(center_turf(), radius + 1, 0.1, 100 * (1 - 0.7 ** (seconds_per_tick / NUCLEAR_POWER_BLOCK_INTERVAL)))
	emitter_count = 0
	for(var/datum/weakref/emitter_ref as anything in emitter_hits)
		if(!emitter_ref.resolve() || world.time > emitter_hits[emitter_ref] + NUCLEAR_POWER_BLOCK_EMITTER_MEMORY)
			emitter_hits -= emitter_ref
		else
			emitter_count++
	update_coolant()
	update_indicator_appearance()

/// Integrate a single bounded thermal/power step; no sleeping operations or map-wide searches.
/obj/machinery/power/nuclear_power_block/proc/process_core(seconds)
	var/minimum_temperature = minimum_generation_temperature()
	var/flow_multiplier = 1 + clamp((chamber_temperature - NUCLEAR_POWER_BLOCK_EXTRA_FLOW_TEMPERATURE) / NUCLEAR_POWER_BLOCK_FLOW_TEMPERATURE_STEP, 0, NUCLEAR_POWER_BLOCK_MAX_FLOW_MULTIPLIER - 1)
	var/coolant_demand = chamber_temperature > minimum_temperature ? NUCLEAR_POWER_BLOCK_WATER_PER_SECOND * seconds * flow_multiplier : 0
	update_coolant(coolant_demand)
	if(fuel <= 0)
		target_reaction_rate = 0
		reaction_rate = 0
	else
		if(reaction_rate > NUCLEAR_POWER_BLOCK_NOMINAL_RATE)
			target_reaction_rate += seconds / NUCLEAR_POWER_BLOCK_INTERVAL
		target_reaction_rate -= NUCLEAR_POWER_BLOCK_ROD_INFLUENCE * rod_insertion / 100 * reaction_rate / NUCLEAR_POWER_BLOCK_NOMINAL_RATE * seconds / NUCLEAR_POWER_BLOCK_INTERVAL
		if(reaction_rate < NUCLEAR_POWER_BLOCK_CHAIN_RATE)
			target_reaction_rate -= seconds / NUCLEAR_POWER_BLOCK_DECAY_TIME
		target_reaction_rate = clamp(target_reaction_rate, 0, NUCLEAR_POWER_BLOCK_MAX_RATE)
		reaction_rate += (target_reaction_rate - reaction_rate) * (1 - 0.5 ** (seconds / NUCLEAR_POWER_BLOCK_RATE_INERTIA))
		// An asymptotic tail must eventually permit a complete shutdown and disassembly.
		if(target_reaction_rate == 0 && reaction_rate < 0.01)
			reaction_rate = 0
		fuel = max(0, fuel - seconds / NUCLEAR_POWER_BLOCK_FUEL_SECONDS * reaction_rate / NUCLEAR_POWER_BLOCK_NOMINAL_RATE * fuel_multiplier)
		if(fuel <= 0)
			reaction_rate = 0
			target_reaction_rate = 0

	var/heat_fraction = clamp((chamber_temperature - minimum_temperature) / NUCLEAR_POWER_BLOCK_COOLING_DELTA, 0, 1)
	var/external_power = energy_to_power(surplus())
	gross_generation = 0
	for(var/datum/nuclear_power_turbine/turbine as anything in turbines)
		turbine.generation = (machine_stat & (BROKEN | EMPED)) ? 0 : turbine.generate_power(chamber_temperature, minimum_temperature)
		gross_generation += turbine.generation
	var/available_power = gross_generation + external_power
	control_power = available_power >= NUCLEAR_POWER_BLOCK_CONTROL_POWER && !(machine_stat & (BROKEN | EMPED))
	internal_consumption = control_power ? NUCLEAR_POWER_BLOCK_CONTROL_POWER : 0
	available_power -= internal_consumption
	cooling_output = 0
	for(var/datum/nuclear_power_turbine/turbine as anything in turbines)
		var/demand = turbine.power_demand()
		turbine.driven = control_power && demand > 0 && available_power >= demand
		turbine.consumption = turbine.driven ? demand : 0
		available_power -= turbine.consumption
		internal_consumption += turbine.consumption
		if(!turbine.driven)
			turbine.target_rpm = 0
		var/mob/living/cranker = turbine.manual_user?.resolve()
		var/manual = cranker?.client && panel_open && Adjacent(cranker) && !cranker.incapacitated && !HAS_TRAIT(cranker, TRAIT_HANDS_BLOCKED) && !cranker.get_active_held_item()
		var/target = turbine.driven ? turbine.target_rpm : 0
		if(manual && turbine.condition > 0 && turbine.tier > 0)
			target = max(target, NUCLEAR_POWER_BLOCK_MANUAL_RPM)
		turbine.rpm += clamp(target - turbine.rpm, -NUCLEAR_POWER_BLOCK_RPM_INERTIA * seconds, NUCLEAR_POWER_BLOCK_RPM_INERTIA * seconds)
		if(turbine.condition <= 0 || turbine.tier <= 0)
			turbine.rpm = 0
		var/liquid_factor = coolant_volume > 0 ? coolant_efficiency : 0.1
		cooling_output += NUCLEAR_POWER_BLOCK_MAIN_COOLING * turbine.multiplier * turbine.rpm / 100 * (0.5 + turbine.condition / 200) * heat_fraction * circulation * liquid_factor
		var/overclock = max(1, turbine.rpm / 100)
		var/overload_wear = 1 + max(0, turbine.rpm - 100) ** 2 / max(1, 100 * turbine.tier)
		if(turbine.rpm > 0)
			turbine.condition = max(0, turbine.condition - NUCLEAR_POWER_BLOCK_WEAR_PER_SECOND * seconds * min(1, turbine.rpm / 100) * overload_wear * wear_multiplier)
			if(turbine.rpm > 100 && prob((overclock - 1) * seconds / max(1, turbine.tier)))
				turbine.condition = max(0, turbine.condition - 5)
		if(turbine.condition <= 0)
			turbine.target_rpm = 0

	// Network accounting uses the same pre-step generation that funded this step's motors.
	net_generation = gross_generation - internal_consumption
	if(net_generation >= 0)
		add_avail(net_generation * seconds)
	else
		add_load(-net_generation * seconds)
	coolant_flow = 0
	if(chamber_temperature > minimum_temperature && coolant_volume > 0)
		var/remaining = min(coolant_volume, coolant_demand)
		var/consumed = 0
		for(var/obj/item/reagent_containers/cup/beaker/beaker in coolant_beakers)
			if(remaining <= 0)
				break
			var/removed = beaker.reagents.remove_all(remaining)
			consumed += removed
			remaining = max(0, remaining - removed)
		coolant_flow = consumed / seconds
		cooling_output += NUCLEAR_POWER_BLOCK_LIQUID_COOLING * consumed / (NUCLEAR_POWER_BLOCK_WATER_PER_SECOND * seconds) * coolant_efficiency * circulation * heat_fraction
		coolant_volume = max(0, coolant_volume - consumed)
	var/heat_per_interval = reaction_rate <= 100 ? 5 * reaction_rate : 500 + 10 * (reaction_rate - 100)
	heat_input = heat_per_interval / NUCLEAR_POWER_BLOCK_INTERVAL
	if(welding_lid && reaction_rate >= 1)
		heat_input *= 2
	var/environmental_heat = ambient_temperature > (T0C + 30) ? (ambient_temperature - (T0C + 30)) / 100 : 0
	var/passive_cooling = ambient_temperature < T20C ? (T20C - ambient_temperature) / 100 : 0
	target_temperature = max(ambient_temperature, TCMB, target_temperature + (heat_input + environmental_heat - cooling_output - passive_cooling) * seconds + emitter_heat)
	emitter_heat = 0
	chamber_temperature += (target_temperature - chamber_temperature) * (1 - 0.5 ** (seconds / NUCLEAR_POWER_BLOCK_THERMAL_INERTIA))
	if(chamber_temperature >= NUCLEAR_POWER_BLOCK_CRITICAL_TEMPERATURE)
		meltdown()
	else if(lid && chamber_temperature >= NUCLEAR_POWER_BLOCK_VALVE_TEMPERATURE)
		release_lid()

/// Shared, one-shot release for crowbar and overheating. There is no pressure explosion.
/obj/machinery/power/nuclear_power_block/proc/release_lid(mob/user)
	if(!lid)
		return FALSE
	var/obj/item/nuclear_power_block_lid/launched = lid
	lid = null
	chamber_temperature = max(TCMB, chamber_temperature - NUCLEAR_POWER_BLOCK_VENT_DROP)
	target_temperature = max(TCMB, target_temperature - NUCLEAR_POWER_BLOCK_VENT_DROP)
	var/turf/center = center_turf()
	var/direction = pick(GLOB.alldirs)
	launched.released_from = WEAKREF(src)
	launched.forceMove(center)
	if(!launched.throw_at(get_edge_target_turf(launched, direction), NUCLEAR_POWER_BLOCK_LID_RANGE, NUCLEAR_POWER_BLOCK_LID_SPEED, user, callback = CALLBACK(launched, TYPE_PROC_REF(/obj/item/nuclear_power_block_lid, break_lid))))
		launched.break_lid()
	visible_message(span_danger("The pressure lid tears free of [src]!"))
	playsound(src, 'sound/machines/airlock/airlock.ogg', 70, TRUE)
	log_game("[src] pressure lid released by [user ? key_name(user) : "overheating"] at [AREACOORD(src)].")
	update_appearance()
	return TRUE

/// Only the terminal core failure explodes; ordinary lid events never enter this path.
/obj/machinery/power/nuclear_power_block/proc/meltdown()
	if(destroying_core)
		return
	destroying_core = TRUE
	var/nuclear = fuel > 0 && reaction_rate >= 1
	var/turf/center = center_turf()
	message_admins("[src] suffered a [nuclear ? "nuclear" : "dry"] failure at [ADMIN_VERBOSEJMP(src)].")
	log_game("[src] suffered a [nuclear ? "nuclear" : "dry"] failure at [AREACOORD(src)].")
	explosion(center, devastation_range = nuclear ? NUCLEAR_POWER_BLOCK_NUCLEAR_DEVASTATION : 1, heavy_impact_range = nuclear ? NUCLEAR_POWER_BLOCK_NUCLEAR_HEAVY : 3, light_impact_range = nuclear ? NUCLEAR_POWER_BLOCK_NUCLEAR_LIGHT : 5, flash_range = nuclear ? NUCLEAR_POWER_BLOCK_NUCLEAR_LIGHT : 5, adminlog = TRUE)
	qdel(src)
