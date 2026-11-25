/// Cosmetic worn variant; the power block retains its standard operating characteristics.
/obj/machinery/power/nuclear_power_block/worn
	name = "weathered uranium power block"
	desc = "An old uranium reactor with two internal turbines and a battered casing. Its power cable connects at the southwest tile."

/// Integrated 3x3 fission plant with a separate removable pressure hatch.
/obj/machinery/power/nuclear_power_block
	name = "uranium power block"
	desc = "An integrated uranium reactor with two internal turbines. Its power cable connects at the southwest tile."
	icon = 'modular_bandastation/nuclear_power_block/icons/reactor.dmi'
	icon_state = "reactor"
	bound_width = 96
	bound_height = 96
	density = TRUE
	opacity = FALSE
	max_integrity = 1000
	resistance_flags = FIRE_PROOF
	circuit = /obj/item/circuitboard/machine/nuclear_power_block
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN
	can_change_cable_layer = TRUE
	/// Main uses a capacitor, reserve a servo, keeping their upgrades independent.
	var/list/datum/nuclear_power_turbine/turbines
	/// Sealed lid owned by this machine; cleared before launching it into the world.
	var/obj/item/nuclear_power_block_lid/lid
	/// Loose, intact replacement awaiting welding; it does not seal radiation.
	var/obj/item/nuclear_power_block_lid/replacement_lid
	/// Actual fission intensity, bounded to 0..150.
	var/reaction_rate = 0
	/// Emitter and rod inputs accumulate here before reaction inertia is applied.
	var/target_reaction_rate = 0
	/// Percentage insertion; mechanical operation remains available without power.
	var/rod_insertion = 100
	/// Remaining fraction of one uranium sheet, not a physical radioactive item.
	var/fuel = 0
	/// Actual chamber temperature in kelvin; powers turbines and triggers accidents.
	var/chamber_temperature = T20C
	/// Integrated kelvin target, changed by heat production and cooling.
	var/target_temperature = T20C
	/// Mean temperature of the occupied turfs in kelvin.
	var/ambient_temperature = T20C
	/// Mean pressure of the occupied turfs in kPa.
	var/ambient_pressure = ONE_ATMOSPHERE
	/// Atmospheric circulation multiplier, 0.1 in vacuum and 1 at normal pressure.
	var/circulation = 1
	/// Chemical and temperature multiplier of the active coolant flow, excluding idle reserves.
	var/coolant_efficiency = 1
	/// Stable vessel slots; component_parts owns these items and handles their destruction.
	var/list/obj/item/reagent_containers/cup/beaker/coolant_beakers = list(null, null)
	/// Combined actual liquid remaining in the installed vessels.
	var/coolant_volume = 0
	/// Combined capacity of installed vessels, excluding empty slots.
	var/coolant_capacity = 0
	/// Additional fuel consumption caused by acidic coolant.
	var/fuel_multiplier = 1
	/// Additional turbine wear caused by alkaline coolant.
	var/wear_multiplier = 1
	/// Last calculated liquid consumption in units per second.
	var/coolant_flow = 0
	/// Last fission heat input in kelvin per second, including live welding.
	var/heat_input = 0
	/// Last active heat removal in kelvin per second.
	var/cooling_output = 0
	/// Combined turbine electrical output in watts, before internal loads.
	var/gross_generation = 0
	/// Control and motor consumption in watts.
	var/internal_consumption = 0
	/// Signed grid exchange in watts; negative values draw external power.
	var/net_generation = 0
	/// Whether the last processing step funded the control electronics.
	var/control_power = FALSE
	/// Serializes welding and mechanical repairs across do_after yields.
	var/service_busy = FALSE
	/// Doubles fission heating only while the lid welding action is running.
	var/welding_lid = FALSE
	/// Prevents recursive terminal failure effects during explosion processing.
	var/destroying_core = FALSE
	/// Only recently impacting emitters; weak keys prevent retaining deleted machinery.
	var/list/emitter_hits = list()
	/// Pending direct heating from beam impacts into an empty fuel chamber, in kelvin.
	var/emitter_heat = 0
	/// Number of recently impacting sources, for the operator display only.
	var/emitter_count = 0
	/// Rebuild lamp overlays only when one of their discrete states changes.
	var/last_indicator_state

/obj/machinery/power/nuclear_power_block/Initialize(mapload)
	turbines = list(new /datum/nuclear_power_turbine("Main", 1), new /datum/nuclear_power_turbine("Reserve", 0.25))
	var/default_coolant = ispath(circuit)
	. = ..()
	lid = new(src)
	if(default_coolant)
		for(var/obj/item/reagent_containers/cup/beaker/beaker in coolant_beakers)
			beaker.reagents.add_reagent(/datum/reagent/water, beaker.reagents.maximum_volume, reagtemp = T20C)
	update_coolant()
	connect_to_network()
	update_environment()
	chamber_temperature = ambient_temperature
	target_temperature = ambient_temperature
	update_appearance()

/obj/machinery/power/nuclear_power_block/Destroy()
	QDEL_NULL(lid)
	QDEL_NULL(replacement_lid)
	QDEL_LIST(turbines)
	coolant_beakers = null
	emitter_hits = null
	return ..()

/obj/machinery/power/nuclear_power_block/Exited(atom/movable/gone, direction)
	if(gone == lid)
		lid = null
	if(gone == replacement_lid)
		replacement_lid = null
	if(coolant_beakers)
		for(var/slot in 1 to length(coolant_beakers))
			if(coolant_beakers[slot] == gone)
				coolant_beakers[slot] = null
	return ..()

/obj/machinery/power/nuclear_power_block/RefreshParts()
	. = ..()
	if(!length(turbines))
		return
	var/datum/nuclear_power_turbine/main = turbines[1]
	var/datum/nuclear_power_turbine/reserve = turbines[2]
	main.tier = 0
	reserve.tier = 0
	for(var/datum/stock_part/capacitor/part in component_parts)
		main.tier = max(main.tier, part.tier)
	for(var/datum/stock_part/servo/part in component_parts)
		reserve.tier = max(reserve.tier, part.tier)
	for(var/slot in 1 to length(coolant_beakers))
		var/obj/item/reagent_containers/cup/beaker/beaker = coolant_beakers[slot]
		if(QDELETED(beaker) || beaker.loc != src || !(beaker in component_parts))
			coolant_beakers[slot] = null
	for(var/obj/item/reagent_containers/cup/beaker/beaker in component_parts)
		if(beaker in coolant_beakers)
			continue
		var/slot = coolant_beakers.Find(null)
		if(slot)
			coolant_beakers[slot] = beaker
	update_coolant()
	update_indicator_appearance()

/// Reach any occupied tile using the same border/window checks as other multi-tile machines.
/obj/machinery/power/nuclear_power_block/Adjacent(atom/neighbor, atom/target, atom/movable/mover)
	if(QDELETED(src) || QDELETED(neighbor) || !isturf(loc) || (!isturf(neighbor) && !isturf(neighbor.loc)))
		return FALSE
	target ||= src
	if(!mover && ismovable(neighbor))
		mover = neighbor
	for(var/turf/footprint as anything in locs)
		if(footprint.Adjacent(neighbor, target = target, mover = mover))
			return TRUE
	return FALSE

/obj/machinery/power/nuclear_power_block/CheckReachableAdjacency(atom/movable/reacher, reacher_range)
	return Adjacent(reacher) || ..()

/// Keep all shared machine checks, replacing only their single-anchor distance gate.
/obj/machinery/power/nuclear_power_block/can_interact(mob/user, require_adjacent_turf = TRUE)
	return ..(user, require_adjacent_turf && !Adjacent(user))

/obj/machinery/power/nuclear_power_block/update_icon_state()
	. = ..()
	icon_state = panel_open ? "reactor_open" : "reactor"

/obj/machinery/power/nuclear_power_block/update_overlays()
	. = ..()
	if(lid)
		var/mutable_appearance/hatch = mutable_appearance(lid.icon, lid.icon_state)
		hatch.pixel_x = 32
		hatch.pixel_y = 28
		. += hatch
	for(var/state in list(reaction_indicator(), temperature_indicator(), turbine_indicator(1), turbine_indicator(2), coolant_indicator()))
		if(state)
			. += mutable_appearance('modular_bandastation/nuclear_power_block/icons/indicators.dmi', state)
			. += emissive_appearance('modular_bandastation/nuclear_power_block/icons/indicators.dmi', state, src, effect_type = EMISSIVE_NO_BLOOM)

/// Lamp animations live in DMI frames, not per-client timers or repeated flicks.
/obj/machinery/power/nuclear_power_block/proc/update_indicator_appearance()
	var/state = "[reaction_indicator()]|[temperature_indicator()]|[turbine_indicator(1)]|[turbine_indicator(2)]|[coolant_indicator()]"
	if(state == last_indicator_state)
		return
	last_indicator_state = state
	update_appearance(UPDATE_OVERLAYS)

/// Fission status is independent of the chamber's actual temperature.
/obj/machinery/power/nuclear_power_block/proc/reaction_indicator()
	if(reaction_rate <= 0)
		return null
	if(reaction_rate > NUCLEAR_POWER_BLOCK_NOMINAL_RATE)
		return "reaction_yellow"
	return reaction_rate >= NUCLEAR_POWER_BLOCK_CHAIN_RATE ? "reaction_blue" : "reaction_green"

/// Use actual temperature; the thermal target can be far ahead during warm-up.
/obj/machinery/power/nuclear_power_block/proc/temperature_indicator()
	if(reaction_rate <= 0)
		return null
	if(chamber_temperature >= NUCLEAR_POWER_BLOCK_CRITICAL_TEMPERATURE - 2000)
		return "temperature_red_blink"
	return chamber_temperature >= NUCLEAR_POWER_BLOCK_VALVE_TEMPERATURE - 1000 ? "temperature_red" : "temperature_green"

/// Stopped lamps stay dark, including a stopped rotor awaiting repairs.
/obj/machinery/power/nuclear_power_block/proc/turbine_indicator(index)
	if(reaction_rate <= 0 || !length(turbines))
		return null
	var/datum/nuclear_power_turbine/turbine = turbines[index]
	if(turbine.rpm <= 0)
		return null
	var/prefix = index == 1 ? "main" : "reserve"
	if(turbine.condition < 15)
		return "[prefix]_red"
	return "[prefix]_[turbine.rpm > 100 ? "yellow" : "green"]"

/// Aggregate volume must not hide an empty individual coolant vessel.
/obj/machinery/power/nuclear_power_block/proc/coolant_indicator()
	if(reaction_rate <= 0)
		return null
	for(var/index in 1 to length(coolant_beakers))
		var/obj/item/reagent_containers/cup/beaker/beaker = coolant_beakers[index]
		if(!beaker || beaker.reagents.total_volume <= 0)
			return "coolant_red"
	return coolant_efficiency >= 1 ? "coolant_cyan" : "coolant_yellow"

/obj/machinery/power/nuclear_power_block/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(istype(mover, /obj/item/nuclear_power_block_lid))
		var/obj/item/nuclear_power_block_lid/moving_lid = mover
		if(IS_WEAKREF_OF(src, moving_lid.released_from))
			return TRUE

/// Absorb actual emitter impacts without applying their normal hull damage.
/obj/machinery/power/nuclear_power_block/bullet_act(obj/projectile/projectile)
	if(!istype(projectile, /obj/projectile/beam/emitter))
		return ..()
	if(fuel > 0)
		target_reaction_rate = min(NUCLEAR_POWER_BLOCK_MAX_RATE, target_reaction_rate + (reaction_rate >= NUCLEAR_POWER_BLOCK_CHAIN_RATE ? 3 : 1))
	else
		emitter_heat += NUCLEAR_POWER_BLOCK_DRY_HIT_HEAT
	if(projectile.fired_from)
		emitter_hits[WEAKREF(projectile.fired_from)] = world.time
	return BULLET_ACT_HIT

/// Geometric center used by lid physics and radiation rather than the southwest cable anchor.
/obj/machinery/power/nuclear_power_block/proc/center_turf()
	var/turf/origin = get_turf(src)
	return origin ? locate(origin.x + 1, origin.y + 1, origin.z) : null

/// Useful generation requires a positive thermal gradient relative to the room.
/obj/machinery/power/nuclear_power_block/proc/minimum_generation_temperature()
	return ambient_temperature + NUCLEAR_POWER_BLOCK_GENERATION_DELTA

/obj/machinery/power/nuclear_power_block/examine(mob/user)
	. = ..()
	. += span_notice("Reaction: [round(reaction_rate, 0.1)] / 150. Chamber: [round(chamber_temperature)] K. Fuel: [round(fuel * 100, 0.1)]%.")
	. += span_notice("[lid ? "The pressure lid is installed." : "The pressure lid is missing!"] Open the service panel with a screwdriver; pry off the lid with a crowbar.")
	if(panel_open)
		. += span_notice("Use a wrench to adjust the rods or repair either turbine; right-click with an empty hand to crank. Capacitors upgrade the main turbine; servos upgrade the reserve. Insert coolant beakers to fill empty slots or replace the first vessel. Spinning rotors can injure your hand during repairs.")
