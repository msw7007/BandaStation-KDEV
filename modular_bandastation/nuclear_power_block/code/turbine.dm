/// State owned by one power block; never independently processed or stored in stock-part singletons.
/datum/nuclear_power_turbine
	/// Stable display and service-selection label.
	var/name
	/// Nominal size, 1 for main and 0.25 for reserve.
	var/multiplier = 1
	/// Installed stock-part grade; zero disables a turbine with a missing part.
	var/tier = 1
	/// Actual rotation as a percentage of nominal, not absolute mechanical RPM.
	var/rpm = 0
	/// Operator-requested percentage; lost when electrical drive fails.
	var/target_rpm = 0
	/// Internal mechanical health, 0..100; not stock-part item integrity.
	var/condition = 100
	/// Most recent electrical output in watts.
	var/generation = 0
	/// Most recent funded motor consumption in watts.
	var/consumption = 0
	/// Whether the last energy budget funded this motor.
	var/driven = FALSE
	/// Weak ownership of an ongoing hand-crank action; never keeps a mob alive.
	var/datum/weakref/manual_user

/datum/nuclear_power_turbine/New(turbine_name, capacity_multiplier)
	. = ..()
	name = turbine_name
	multiplier = capacity_multiplier

/datum/nuclear_power_turbine/Destroy()
	manual_user = null
	return ..()

/// Rated output at nominal RPM; wear reduces capacity without changing the part's grade.
/datum/nuclear_power_turbine/proc/capacity()
	if(condition <= 0 || tier <= 0)
		return 0
	var/static/list/main_output = list(150, 250, 350, 500)
	var/static/list/reserve_output = list(25, 50, 75, 100)
	var/list/rated_output = multiplier == 1 ? main_output : reserve_output
	return rated_output[min(tier, length(rated_output))] * (1 KILO WATTS) * (0.5 + condition / 200)

/// Cranking cannot generate electricity without a temperature gradient or useful rotation.
/datum/nuclear_power_turbine/proc/generate_power(temperature, minimum_temperature)
	if(rpm < NUCLEAR_POWER_BLOCK_MIN_RPM)
		return 0
	return capacity() * rpm / 100 * clamp((temperature - minimum_temperature) / NUCLEAR_POWER_BLOCK_FULL_POWER_DELTA, 0, 1)

/// Motor load in watts; an unpowered rotor still coasts but receives no artificial drive.
/datum/nuclear_power_turbine/proc/power_demand()
	if(condition <= 0 || tier <= 0 || max(rpm, target_rpm) <= 0)
		return 0
	return NUCLEAR_POWER_BLOCK_MOTOR_MIN_POWER + (NUCLEAR_POWER_BLOCK_MOTOR_NOMINAL_POWER - NUCLEAR_POWER_BLOCK_MOTOR_MIN_POWER) * (max(rpm, target_rpm) / 100) ** 2
