/obj/vehicle/sealed/car
	layer = ABOVE_MOB_LAYER
	move_resist = MOVE_FORCE_VERY_STRONG

	///Bitflags for special behavior such as kidnapping
	var/car_traits = NONE
	///Sound file(s) to play when we drive around
	var/engine_sound = 'sound/vehicles/carrev.ogg'
	///Set this to the length of the engine sound.
	var/engine_sound_length = 2 SECONDS
	///Time it takes to break out of the car.
	var/escape_time = 6 SECONDS
	/// How long it takes to move, cars don't use the riding component similar to mechs so we handle it ourselves
	var/vehicle_move_delay = 1
	/// What sound to play if someone was forced in.
	var/forced_enter_sound
	/// How long it takes to rev (vrrm vrrm!)
	COOLDOWN_DECLARE(enginesound_cooldown)

/obj/vehicle/sealed/car/generate_actions()
	. = ..()
	if(!isnull(key_type))
		initialize_controller_action_type(/datum/action/vehicle/sealed/remove_key, VEHICLE_CONTROL_DRIVE)
	if(car_traits & CAN_KIDNAP)
		initialize_controller_action_type(/datum/action/vehicle/sealed/dump_kidnapped_mobs, VEHICLE_CONTROL_DRIVE)

/obj/vehicle/sealed/car/mouse_drop_receive(atom/dropping, mob/M, params)
	if(HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && !is_driver(M))
		return
	if((car_traits & CAN_KIDNAP) && isliving(dropping) && M != dropping)
		var/mob/living/kidnapped = dropping
		kidnapped.visible_message(span_warning("[M] starts forcing [kidnapped] into [src]!"))
		mob_try_forced_enter(M, kidnapped)
	return ..()

/obj/vehicle/sealed/car/mob_try_exit(mob/future_pedestrian, mob/user, silent = FALSE)
	if(future_pedestrian != user || !(LAZYACCESS(occupants, future_pedestrian) & VEHICLE_CONTROL_KIDNAPPED))
		mob_exit(future_pedestrian, silent)
		return TRUE
	if (escape_time > 0)
		to_chat(user, span_notice("You push against the back of \the [src]'s trunk to try and get out."))
		if(!do_after(user, escape_time, target = src))
			return FALSE
	to_chat(user,span_danger("[user] gets out of [src]."))
	mob_exit(future_pedestrian, silent)
	return TRUE

/obj/vehicle/sealed/car/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!(car_traits & CAN_KIDNAP))
		return
	to_chat(user, span_notice("You start opening [src]'s trunk."))
	if(!do_after(user, 30))
		return
	if(return_amount_of_controllers_with_flag(VEHICLE_CONTROL_KIDNAPPED))
		to_chat(user, span_notice("The people stuck in [src]'s trunk all come tumbling out."))
		dump_specific_mobs(VEHICLE_CONTROL_KIDNAPPED)
		return
	to_chat(user, span_notice("It seems [src]'s trunk was empty."))

///attempts to force a mob into the car
/obj/vehicle/sealed/car/proc/mob_try_forced_enter(mob/forcer, mob/kidnapped, silent = FALSE)
	if(occupant_amount() >= max_occupants)
		return FALSE
	var/atom/old_loc = loc
	var/enter_delay = get_enter_delay(kidnapped)
	if(enter_delay == 0 || do_after(forcer, enter_delay, kidnapped, extra_checks=CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/car, is_car_stationary), old_loc)))
		mob_forced_enter(kidnapped, silent)
		return TRUE
	return FALSE

///Callback proc to check for
/obj/vehicle/sealed/car/proc/is_car_stationary(atom/old_loc)
	return (old_loc == loc)

///Proc called when someone is forcefully stuffedd into a car
/obj/vehicle/sealed/car/proc/mob_forced_enter(mob/kidnapped, silent = FALSE)
	if(!silent)
		kidnapped.visible_message(span_warning("[kidnapped] is forced into \the [src]!"))
		if(forced_enter_sound)
			playsound(src, forced_enter_sound, 70, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	kidnapped.forceMove(src)
	add_occupant(kidnapped, VEHICLE_CONTROL_KIDNAPPED, TRUE)

/obj/vehicle/sealed/car/atom_destruction(damage_flag)
	explosion(src, heavy_impact_range = 1, light_impact_range = 2, flash_range = 3, adminlog = FALSE)
	log_message("[src] exploded due to destruction", LOG_ATTACK)
	return ..()

/obj/vehicle/sealed/car/relaymove(mob/living/user, direction)
	if(is_driver(user) && canmove && (!key_type || istype(inserted_key, key_type)))
		vehicle_move(direction)
	return TRUE

/obj/vehicle/sealed/car/vehicle_move(direction)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, modified_move_delay(vehicle_move_delay)) // BANDASTATION EDIT - Vehicle speed

	if(COOLDOWN_FINISHED(src, enginesound_cooldown))
		COOLDOWN_START(src, enginesound_cooldown, engine_sound_length)
		playsound(get_turf(src), engine_sound, 100, TRUE)

	if(trailer)
		var/dir_to_move = get_dir(trailer.loc, loc)
		var/did_move = try_step_multiz(direction)
		if(did_move)
			step(trailer, dir_to_move)
		return did_move
	after_move(direction)
	return try_step_multiz(direction)

/datum/cyberpunk_vehicle_part
	var/name = "vehicle part"
	var/category = "part"
	var/manufacturer = "Starlight"
	var/tier = 1
	var/max_health = 100
	var/health = 100
	var/effect_desc = "Provides baseline vehicle function."
	var/speed_multiplier = 1
	var/acceleration_multiplier = 1
	var/maneuver_multiplier = 1
	var/traction_multiplier = 1
	var/grip_switch_multiplier = 1
	var/brake_multiplier = 1
	var/fuel_multiplier = 1
	var/resource_type = "energy"
	var/max_fuel_multiplier = 1
	var/passenger_capacity = 0
	var/mechanism_capacity = 0
	var/running_gear_slots = 4
	var/floor_grip = 1
	var/rough_grip = 0.75
	var/bad_grip = 0.45
	var/space_grip = 0.1

/datum/cyberpunk_vehicle_part/New(part_name, part_category, part_health = 100, part_effect = null)
	. = ..()
	if(part_name)
		name = part_name
	if(part_category)
		category = part_category
	max_health = part_health
	health = max_health
	if(part_effect)
		effect_desc = part_effect

/datum/cyberpunk_vehicle_part/proc/health_fraction()
	return clamp(health / max(max_health, 1), 0, 1)

/datum/cyberpunk_vehicle_part/proc/take_damage(amount)
	health = clamp(health - amount, 0, max_health)

/datum/cyberpunk_vehicle_part/proc/repair(amount)
	var/old_health = health
	health = clamp(health + amount, 0, max_health)
	return health - old_health

/datum/cyberpunk_vehicle_part/proc/get_vehicle_part_ui_data()
	return list(
		"name" = name,
		"category" = category,
		"manufacturer" = manufacturer,
		"tier" = tier,
		"health" = round(health, 0.1),
		"maxHealth" = max_health,
		"integrity" = health_fraction(),
		"effect" = effect_desc,
		"speedMultiplier" = speed_multiplier,
		"accelerationMultiplier" = acceleration_multiplier,
		"maneuverMultiplier" = maneuver_multiplier,
		"tractionMultiplier" = traction_multiplier,
		"gripSwitchMultiplier" = grip_switch_multiplier,
		"brakeMultiplier" = brake_multiplier,
		"fuelMultiplier" = fuel_multiplier,
		"maxFuelMultiplier" = max_fuel_multiplier,
		"resourceType" = resource_type,
		"passengerCapacity" = passenger_capacity,
		"mechanismCapacity" = mechanism_capacity,
		"runningGearSlots" = running_gear_slots,
	)

/obj/item/cyberpunk_vehicle_part
	name = "Starlight vehicle part"
	desc = "A standardized Starlight vehicle component."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rtd"
	w_class = WEIGHT_CLASS_BULKY
	var/part_name = "Starlight vehicle part"
	var/part_category = "part"
	var/part_health = 100
	var/part_effect = "Provides baseline vehicle function."
	var/speed_multiplier = 1
	var/acceleration_multiplier = 1
	var/maneuver_multiplier = 1
	var/traction_multiplier = 1
	var/grip_switch_multiplier = 1
	var/brake_multiplier = 1
	var/fuel_multiplier = 1
	var/resource_type = "energy"
	var/max_fuel_multiplier = 1
	var/passenger_capacity = 0
	var/mechanism_capacity = 0
	var/running_gear_slots = 4
	var/floor_grip = 1
	var/rough_grip = 0.75
	var/bad_grip = 0.45
	var/space_grip = 0.1
	var/manufacturer = "Starlight"
	var/part_variant = "standard"
	var/part_tier = 1

/obj/item/cyberpunk_vehicle_part/proc/get_part_variant_name()
	switch(part_variant)
		if("performance")
			return "Performance"
		if("reinforced")
			return "Reinforced"
		if("economy")
			return "Economy"
	return "Standard"

/obj/item/cyberpunk_vehicle_part/proc/cycle_part_variant(mob/user)
	switch(part_variant)
		if("standard")
			part_variant = "performance"
		if("performance")
			part_variant = "reinforced"
		if("reinforced")
			part_variant = "economy"
		else
			part_variant = "standard"
	to_chat(user, span_notice("[src] variant set to [get_part_variant_name()]."))

/obj/item/cyberpunk_vehicle_part/attack_self(mob/user, modifiers)
	cycle_part_variant(user)
	return TRUE

/obj/item/cyberpunk_vehicle_part/examine(mob/user)
	. = ..()
	. += span_notice("Tier: T[part_tier].")
	. += span_notice("Variant: [get_part_variant_name()]. Use in hand before installation to cycle Standard, Performance, Reinforced and Economy variants.")

/obj/item/cyberpunk_vehicle_part/proc/build_part_datum()
	var/datum/cyberpunk_vehicle_part/part = new(part_name, part_category, part_health, part_effect)
	part.manufacturer = manufacturer
	part.tier = part_tier
	part.speed_multiplier = speed_multiplier
	part.acceleration_multiplier = acceleration_multiplier
	part.maneuver_multiplier = maneuver_multiplier
	part.traction_multiplier = traction_multiplier
	part.grip_switch_multiplier = grip_switch_multiplier
	part.brake_multiplier = brake_multiplier
	part.fuel_multiplier = fuel_multiplier
	part.max_fuel_multiplier = max_fuel_multiplier
	part.resource_type = resource_type
	part.passenger_capacity = passenger_capacity
	part.mechanism_capacity = mechanism_capacity
	part.running_gear_slots = running_gear_slots
	part.floor_grip = floor_grip
	part.rough_grip = rough_grip
	part.bad_grip = bad_grip
	part.space_grip = space_grip
	apply_part_tier_to(part)
	apply_part_variant_to(part)
	return part

/obj/item/cyberpunk_vehicle_part/proc/apply_part_tier_to(datum/cyberpunk_vehicle_part/part)
	if(!part || part_tier <= 1)
		return
	var/tier_power = clamp(part_tier, 1, 3)
	var/power_bonus = 1 + (0.15 * (tier_power - 1))
	var/durability_bonus = 1 + (0.2 * (tier_power - 1))
	var/fuel_bonus = max(0.65, 1 - (0.1 * (tier_power - 1)))
	part.name = "[part.name] T[tier_power]"
	part.effect_desc = "[part.effect_desc] Higher-tier construction improves output, durability and efficiency."
	part.max_health = max(1, round(part.max_health * durability_bonus))
	part.health = part.max_health
	part.speed_multiplier *= power_bonus
	part.acceleration_multiplier *= power_bonus
	part.maneuver_multiplier *= power_bonus
	part.traction_multiplier *= power_bonus
	part.grip_switch_multiplier *= power_bonus
	part.brake_multiplier *= power_bonus
	part.max_fuel_multiplier *= power_bonus
	part.fuel_multiplier *= fuel_bonus
	part.floor_grip *= power_bonus
	part.rough_grip *= power_bonus
	part.bad_grip *= power_bonus
	part.space_grip *= power_bonus

/obj/item/cyberpunk_vehicle_part/proc/apply_part_variant_to(datum/cyberpunk_vehicle_part/part)
	if(!part)
		return
	switch(part_variant)
		if("performance")
			part.name = "[part.name] (performance)"
			part.effect_desc = "[part.effect_desc] Tuned for speed and response at the cost of wear and fuel."
			part.max_health = max(1, round(part.max_health * 0.9))
			part.health = min(part.health, part.max_health)
			part.speed_multiplier *= 1.1
			part.acceleration_multiplier *= 1.12
			part.maneuver_multiplier *= 1.08
			part.fuel_multiplier *= 1.12
			part.floor_grip *= 1.03
			part.rough_grip *= 0.96
		if("reinforced")
			part.name = "[part.name] (reinforced)"
			part.effect_desc = "[part.effect_desc] Reinforced for impact tolerance at the cost of speed."
			part.max_health = max(1, round(part.max_health * 1.25))
			part.health = part.max_health
			part.speed_multiplier *= 0.92
			part.acceleration_multiplier *= 0.95
			part.brake_multiplier *= 1.05
			part.fuel_multiplier *= 1.08
			part.traction_multiplier *= 1.04
		if("economy")
			part.name = "[part.name] (economy)"
			part.effect_desc = "[part.effect_desc] Tuned for lower resource use and longer operating range."
			part.max_health = max(1, round(part.max_health * 0.95))
			part.health = min(part.health, part.max_health)
			part.speed_multiplier *= 0.96
			part.acceleration_multiplier *= 0.94
			part.fuel_multiplier *= 0.82
			part.max_fuel_multiplier *= 1.15
			part.grip_switch_multiplier *= 0.96
	apply_category_variant_to(part)

/obj/item/cyberpunk_vehicle_part/proc/apply_category_variant_to(datum/cyberpunk_vehicle_part/part)
	if(!part || part_variant == "standard")
		return
	switch(part.category)
		if("hull")
			apply_hull_variant_to(part)
		if("drivetrain")
			apply_drivetrain_variant_to(part)
		if("engine")
			apply_engine_variant_to(part)

/obj/item/cyberpunk_vehicle_part/proc/apply_hull_variant_to(datum/cyberpunk_vehicle_part/part)
	switch(part_variant)
		if("performance")
			part.effect_desc = "[part.effect_desc] Hull weight is stripped down for a quicker chassis."
			part.speed_multiplier *= 1.04
			part.acceleration_multiplier *= 1.08
			part.brake_multiplier *= 0.96
			part.passenger_capacity = max(1, part.passenger_capacity - 1)
		if("reinforced")
			part.effect_desc = "[part.effect_desc] Hull bracing improves crash tolerance and payload stability."
			part.max_health = max(part.max_health, round(part.max_health * 1.15))
			part.health = part.max_health
			part.speed_multiplier *= 0.96
			part.brake_multiplier *= 1.08
			part.mechanism_capacity += 1
		if("economy")
			part.effect_desc = "[part.effect_desc] Interior volume and service access are prioritized over response."
			part.max_fuel_multiplier *= 1.08
			part.fuel_multiplier *= 0.95
			part.maneuver_multiplier *= 0.96

/obj/item/cyberpunk_vehicle_part/proc/apply_drivetrain_variant_to(datum/cyberpunk_vehicle_part/part)
	var/is_street = findtext(lowertext(part.name), "street")
	var/is_offroad = findtext(lowertext(part.name), "off-road") || findtext(lowertext(part.name), "offroad")
	var/is_tracks = findtext(lowertext(part.name), "track")
	var/is_grav = findtext(lowertext(part.name), "gravitic") || findtext(lowertext(part.name), "grav")
	var/is_flight = findtext(lowertext(part.name), "flight") || findtext(lowertext(part.name), "nozzle")
	switch(part_variant)
		if("performance")
			part.effect_desc = "[part.effect_desc] Drive tuning sharpens the intended terrain profile."
			part.maneuver_multiplier *= 1.08
			if(is_street)
				part.floor_grip *= 1.12
				part.rough_grip *= 0.9
			else if(is_offroad)
				part.rough_grip *= 1.14
				part.floor_grip *= 0.98
			else if(is_tracks)
				part.rough_grip *= 1.08
				part.bad_grip *= 1.08
				part.speed_multiplier *= 0.96
			else if(is_grav)
				part.speed_multiplier *= 1.08
				part.maneuver_multiplier *= 1.08
				part.traction_multiplier *= 0.88
			else if(is_flight)
				part.space_grip *= 1.18
				part.acceleration_multiplier *= 1.08
		if("reinforced")
			part.effect_desc = "[part.effect_desc] Running gear is overbuilt for controlled recovery."
			part.traction_multiplier *= 1.1
			part.brake_multiplier *= 1.08
			part.grip_switch_multiplier *= 1.08
			if(is_grav)
				part.traction_multiplier *= 0.95
			if(is_flight)
				part.space_grip *= 1.1
		if("economy")
			part.effect_desc = "[part.effect_desc] Running gear uses low-loss bearings and conservative servos."
			part.fuel_multiplier *= 0.92
			part.brake_multiplier *= 0.96
			part.grip_switch_multiplier *= 0.94
			if(is_tracks)
				part.speed_multiplier *= 0.98

/obj/item/cyberpunk_vehicle_part/proc/apply_engine_variant_to(datum/cyberpunk_vehicle_part/part)
	switch(part_variant)
		if("performance")
			part.effect_desc = "[part.effect_desc] Engine output curve favors burst acceleration."
			part.acceleration_multiplier *= 1.16
			part.speed_multiplier *= 1.06
			part.fuel_multiplier *= 1.08
			part.max_fuel_multiplier *= 0.96
		if("reinforced")
			part.effect_desc = "[part.effect_desc] Engine block is overbuilt against dirty fuel and impact shock."
			part.max_health = max(part.max_health, round(part.max_health * 1.18))
			part.health = part.max_health
			part.acceleration_multiplier *= 0.96
			part.max_fuel_multiplier *= 1.08
		if("economy")
			part.effect_desc = "[part.effect_desc] Engine timing favors range and heat stability."
			part.fuel_multiplier *= 0.78
			part.max_fuel_multiplier *= 1.18
			part.speed_multiplier *= 0.97
			part.acceleration_multiplier *= 0.92

/obj/item/cyberpunk_vehicle_part/hull
	name = "Starlight compact chassis"
	part_name = "Starlight compact chassis"
	part_category = "hull"
	part_health = 140
	part_effect = "Four-seat body with one mechanism slot."
	passenger_capacity = 4
	mechanism_capacity = 1
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/microbike
	name = "Starlight microbike frame"
	part_name = "Starlight microbike frame"
	part_health = 80
	part_effect = "One-seat frame with one compact mechanism slot."
	speed_multiplier = 1.2
	maneuver_multiplier = 1.25
	passenger_capacity = 1
	mechanism_capacity = 1
	running_gear_slots = 2

/obj/item/cyberpunk_vehicle_part/hull/bike
	name = "Starlight bike frame"
	part_name = "Starlight bike frame"
	part_health = 95
	part_effect = "Two-seat bike frame without mechanism capacity."
	speed_multiplier = 1.15
	maneuver_multiplier = 1.15
	passenger_capacity = 2
	mechanism_capacity = 0
	running_gear_slots = 2

/obj/item/cyberpunk_vehicle_part/hull/large_car
	name = "Starlight large car chassis"
	part_name = "Starlight large car chassis"
	part_health = 180
	part_effect = "Four-seat body with two mechanism slots."
	speed_multiplier = 0.9
	maneuver_multiplier = 0.9
	passenger_capacity = 4
	mechanism_capacity = 2
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/minivan
	name = "Starlight minivan chassis"
	part_name = "Starlight minivan chassis"
	part_health = 200
	part_effect = "Six-seat body."
	speed_multiplier = 0.8
	maneuver_multiplier = 0.75
	passenger_capacity = 6
	mechanism_capacity = 0
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/cargo_minivan
	name = "Starlight cargo minivan chassis"
	part_name = "Starlight cargo minivan chassis"
	part_health = 210
	part_effect = "Two-seat cargo body with four mechanism slots."
	speed_multiplier = 0.75
	maneuver_multiplier = 0.7
	passenger_capacity = 2
	mechanism_capacity = 4
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/bus
	name = "Starlight bus chassis"
	part_name = "Starlight bus chassis"
	part_health = 260
	part_effect = "Eight-seat passenger body."
	speed_multiplier = 0.65
	maneuver_multiplier = 0.55
	passenger_capacity = 8
	mechanism_capacity = 0
	running_gear_slots = 6

/obj/item/cyberpunk_vehicle_part/hull/cargo_truck
	name = "Starlight cargo truck chassis"
	part_name = "Starlight cargo truck chassis"
	part_health = 280
	part_effect = "Two-seat heavy cargo body with six mechanism slots."
	speed_multiplier = 0.55
	maneuver_multiplier = 0.45
	passenger_capacity = 2
	mechanism_capacity = 6
	running_gear_slots = 8

/obj/item/cyberpunk_vehicle_part/hull/apc
	name = "Starlight APC hull"
	part_name = "Starlight APC hull"
	part_health = 360
	part_effect = "Twelve-seat armored carrier hull."
	speed_multiplier = 0.5
	maneuver_multiplier = 0.4
	passenger_capacity = 12
	mechanism_capacity = 0
	running_gear_slots = 8

/obj/item/cyberpunk_vehicle_part/hull/tank
	name = "Starlight tank hull"
	part_name = "Starlight tank hull"
	part_health = 420
	part_effect = "Four-seat armored hull with heavy protection."
	speed_multiplier = 0.45
	maneuver_multiplier = 0.35
	passenger_capacity = 4
	mechanism_capacity = 1
	running_gear_slots = 8

/obj/item/cyberpunk_vehicle_part/hull/sport_compact
	name = "Starlight sport compact chassis"
	part_name = "Starlight sport compact chassis"
	part_health = 120
	part_effect = "Two-seat compact body tuned for acceleration and corner entry."
	speed_multiplier = 1.12
	acceleration_multiplier = 1.18
	maneuver_multiplier = 1.14
	brake_multiplier = 0.95
	passenger_capacity = 2
	mechanism_capacity = 1
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/utility_compact
	name = "Starlight utility compact chassis"
	part_name = "Starlight utility compact chassis"
	part_health = 165
	part_effect = "Four-seat utility body with more mechanism space and modest response."
	speed_multiplier = 0.92
	acceleration_multiplier = 0.95
	maneuver_multiplier = 0.9
	brake_multiplier = 1.05
	passenger_capacity = 4
	mechanism_capacity = 3
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/armored_compact
	name = "Starlight armored compact chassis"
	part_name = "Starlight armored compact chassis"
	part_health = 230
	part_effect = "Four-seat compact body with reinforced cabin and slower handling."
	speed_multiplier = 0.82
	acceleration_multiplier = 0.88
	maneuver_multiplier = 0.78
	brake_multiplier = 1.12
	passenger_capacity = 4
	mechanism_capacity = 1
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/bike/pursuit
	name = "Starlight pursuit bike frame"
	part_name = "Starlight pursuit bike frame"
	part_health = 100
	part_effect = "Lean two-seat bike frame tuned for pursuit acceleration."
	speed_multiplier = 1.28
	acceleration_multiplier = 1.22
	maneuver_multiplier = 1.18
	passenger_capacity = 2
	mechanism_capacity = 0
	running_gear_slots = 2

/obj/item/cyberpunk_vehicle_part/hull/bike/courier
	name = "Starlight courier bike frame"
	part_name = "Starlight courier bike frame"
	part_health = 115
	part_effect = "Delivery bike frame with a compact mechanism bay."
	speed_multiplier = 1.12
	acceleration_multiplier = 1.08
	maneuver_multiplier = 1.08
	passenger_capacity = 1
	mechanism_capacity = 1
	running_gear_slots = 2

/obj/item/cyberpunk_vehicle_part/hull/large_car/executive
	name = "Starlight executive sedan chassis"
	part_name = "Starlight executive sedan chassis"
	part_health = 210
	part_effect = "Stable four-seat sedan body with reinforced passenger space."
	speed_multiplier = 0.86
	acceleration_multiplier = 0.92
	maneuver_multiplier = 0.88
	brake_multiplier = 1.15
	passenger_capacity = 4
	mechanism_capacity = 2
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor
	name = "Starlight interceptor chassis"
	part_name = "Starlight interceptor chassis"
	part_health = 170
	part_effect = "Four-seat patrol body with higher top speed and lower cargo tolerance."
	speed_multiplier = 1.08
	acceleration_multiplier = 1.08
	maneuver_multiplier = 0.96
	brake_multiplier = 1.08
	passenger_capacity = 4
	mechanism_capacity = 1
	running_gear_slots = 4

/obj/item/cyberpunk_vehicle_part/drivetrain
	name = "Starlight street suspension"
	part_name = "Starlight street suspension"
	part_category = "drivetrain"
	part_health = 100
	part_effect = "Fast street suspension. Strong on floors and roads, weak on natural terrain."
	speed_multiplier = 1.08
	floor_grip = 1.1
	rough_grip = 0.55
	bad_grip = 0.4
	space_grip = 0.05

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad
	name = "Starlight off-road suspension"
	part_name = "Starlight off-road suspension"
	part_effect = "Lower top speed, stronger grip on rough and natural terrain."
	speed_multiplier = 0.92
	traction_multiplier = 1.15
	floor_grip = 0.9
	rough_grip = 1.15
	bad_grip = 0.8
	space_grip = 0.1

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks
	name = "Starlight tracked running gear"
	part_name = "Starlight tracked running gear"
	part_health = 160
	part_effect = "Slow tracks with steady grip across most terrain."
	speed_multiplier = 0.7
	maneuver_multiplier = 0.65
	traction_multiplier = 1.35
	floor_grip = 0.95
	rough_grip = 0.95
	bad_grip = 0.95
	space_grip = 0.15

/obj/item/cyberpunk_vehicle_part/drivetrain/legs
	name = "Starlight walker legs"
	part_name = "Starlight walker legs"
	part_health = 130
	part_effect = "Mechanical legs with stable bad-terrain movement."
	speed_multiplier = 0.75
	maneuver_multiplier = 0.9
	traction_multiplier = 1.2
	bad_grip = 0.95

/obj/item/cyberpunk_vehicle_part/drivetrain/grav
	name = "Starlight gravitic drive"
	part_name = "Starlight gravitic drive"
	part_health = 120
	part_effect = "Terrain-agnostic grav drive with weak grip and heavy drift."
	speed_multiplier = 1.05
	maneuver_multiplier = 1.05
	traction_multiplier = 0.55
	floor_grip = 0.55
	rough_grip = 0.55
	bad_grip = 0.55
	space_grip = 0.55

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles
	name = "Starlight flight nozzles"
	part_name = "Starlight flight nozzles"
	part_health = 90
	part_effect = "Flight nozzles. Enables altitude changes and handles open space."
	speed_multiplier = 1.35
	maneuver_multiplier = 0.85
	traction_multiplier = 0.75
	floor_grip = 0.65
	rough_grip = 0.65
	bad_grip = 0.65
	space_grip = 0.9

/obj/item/cyberpunk_vehicle_part/drivetrain/race_street
	name = "Starlight race street suspension"
	part_name = "Starlight race street suspension"
	part_health = 85
	part_effect = "High-speed street suspension with weak rough-terrain stability."
	speed_multiplier = 1.18
	acceleration_multiplier = 1.1
	maneuver_multiplier = 1.08
	traction_multiplier = 0.96
	floor_grip = 1.22
	rough_grip = 0.42
	bad_grip = 0.32
	space_grip = 0.05

/obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street
	name = "Starlight comfort street suspension"
	part_name = "Starlight comfort street suspension"
	part_health = 115
	part_effect = "Stable city suspension with better braking and slower response."
	speed_multiplier = 0.98
	acceleration_multiplier = 0.95
	maneuver_multiplier = 0.96
	brake_multiplier = 1.18
	floor_grip = 1.18
	rough_grip = 0.62
	bad_grip = 0.48
	space_grip = 0.05

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally
	name = "Starlight rally suspension"
	part_name = "Starlight rally suspension"
	part_health = 105
	part_effect = "Fast rough-terrain suspension that keeps some street speed."
	speed_multiplier = 1
	acceleration_multiplier = 1.05
	maneuver_multiplier = 1.08
	traction_multiplier = 1.08
	floor_grip = 0.95
	rough_grip = 1.18
	bad_grip = 0.72
	space_grip = 0.1

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler
	name = "Starlight crawler suspension"
	part_name = "Starlight crawler suspension"
	part_health = 145
	part_effect = "Slow off-road suspension with strong grip on broken terrain."
	speed_multiplier = 0.78
	acceleration_multiplier = 0.9
	maneuver_multiplier = 0.92
	traction_multiplier = 1.35
	floor_grip = 0.85
	rough_grip = 1.25
	bad_grip = 1.05
	space_grip = 0.12

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light
	name = "Starlight light tracks"
	part_name = "Starlight light tracks"
	part_health = 140
	part_effect = "Lighter tracks with better turn-in and less armor tolerance."
	speed_multiplier = 0.82
	acceleration_multiplier = 0.95
	maneuver_multiplier = 0.82
	traction_multiplier = 1.22
	floor_grip = 0.98
	rough_grip = 0.98
	bad_grip = 0.9
	space_grip = 0.15

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial
	name = "Starlight industrial tracks"
	part_name = "Starlight industrial tracks"
	part_health = 210
	part_effect = "Heavy tracks that trade speed for consistent pull and braking."
	speed_multiplier = 0.58
	acceleration_multiplier = 0.82
	maneuver_multiplier = 0.55
	traction_multiplier = 1.55
	brake_multiplier = 1.25
	floor_grip = 0.9
	rough_grip = 1.02
	bad_grip = 1.08
	space_grip = 0.15

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport
	name = "Starlight sport gravitic drive"
	part_name = "Starlight sport gravitic drive"
	part_health = 95
	part_effect = "Fast gravitic drive with extreme drift."
	speed_multiplier = 1.24
	acceleration_multiplier = 1.12
	maneuver_multiplier = 1.12
	traction_multiplier = 0.42
	grip_switch_multiplier = 0.82
	floor_grip = 0.45
	rough_grip = 0.45
	bad_grip = 0.45
	space_grip = 0.62

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable
	name = "Starlight stabilized gravitic drive"
	part_name = "Starlight stabilized gravitic drive"
	part_health = 135
	part_effect = "Controlled gravitic drive with lower top speed and safer drift."
	speed_multiplier = 0.92
	acceleration_multiplier = 0.95
	maneuver_multiplier = 0.98
	traction_multiplier = 0.78
	grip_switch_multiplier = 1.18
	floor_grip = 0.7
	rough_grip = 0.7
	bad_grip = 0.7
	space_grip = 0.72

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift
	name = "Starlight lift nozzles"
	part_name = "Starlight lift nozzles"
	part_health = 120
	part_effect = "Stable lift nozzles with safer altitude changes and lower speed."
	speed_multiplier = 1.08
	acceleration_multiplier = 0.95
	maneuver_multiplier = 0.95
	traction_multiplier = 0.85
	grip_switch_multiplier = 1.12
	floor_grip = 0.75
	rough_grip = 0.75
	bad_grip = 0.75
	space_grip = 0.95

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector
	name = "Starlight vector nozzles"
	part_name = "Starlight vector nozzles"
	part_health = 80
	part_effect = "Aggressive flight nozzles with high speed and touchy control."
	speed_multiplier = 1.55
	acceleration_multiplier = 1.18
	maneuver_multiplier = 1.08
	traction_multiplier = 0.62
	grip_switch_multiplier = 0.9
	floor_grip = 0.55
	rough_grip = 0.55
	bad_grip = 0.55
	space_grip = 1.05

/obj/item/cyberpunk_vehicle_part/engine
	name = "Starlight electric engine"
	part_name = "Starlight electric engine"
	part_category = "engine"
	part_health = 100
	part_effect = "Internal rechargeable electric engine with a compact charge buffer."
	fuel_multiplier = 0.85
	max_fuel_multiplier = 0.75

/obj/item/cyberpunk_vehicle_part/engine/battery
	name = "Starlight removable-cell engine"
	part_name = "Starlight removable-cell engine"
	part_effect = "Electric engine powered by a removable power cell."
	resource_type = "battery"
	fuel_multiplier = 1.05
	max_fuel_multiplier = 0

/obj/item/cyberpunk_vehicle_part/engine/combustion
	name = "Starlight combustion engine"
	part_name = "Starlight combustion engine"
	part_effect = "High acceleration and higher fuel demand."
	acceleration_multiplier = 1.25
	fuel_multiplier = 1.25
	max_fuel_multiplier = 1.35
	resource_type = "fuel"

/obj/item/cyberpunk_vehicle_part/engine/performance
	name = "Starlight performance engine"
	part_name = "Starlight performance engine"
	part_health = 90
	part_effect = "High top speed, high consumption."
	speed_multiplier = 1.3
	acceleration_multiplier = 1.15
	fuel_multiplier = 1.35
	max_fuel_multiplier = 1.15
	resource_type = "fuel"

/obj/item/cyberpunk_vehicle_part/engine/heavy
	name = "Starlight heavy engine"
	part_name = "Starlight heavy engine"
	part_health = 150
	part_effect = "Heavy-duty engine for armored hulls."
	speed_multiplier = 0.9
	acceleration_multiplier = 0.85
	fuel_multiplier = 1.15
	max_fuel_multiplier = 1.8
	resource_type = "fuel"

/obj/item/cyberpunk_vehicle_part/engine/electric_efficiency
	name = "Starlight efficient electric engine"
	part_name = "Starlight efficient electric engine"
	part_health = 105
	part_effect = "Low-consumption internal electric engine with a small charge buffer."
	speed_multiplier = 0.92
	acceleration_multiplier = 0.9
	fuel_multiplier = 0.62
	max_fuel_multiplier = 0.8

/obj/item/cyberpunk_vehicle_part/engine/electric_torque
	name = "Starlight torque electric engine"
	part_name = "Starlight torque electric engine"
	part_health = 95
	part_effect = "Responsive internal electric engine with higher draw."
	speed_multiplier = 1.02
	acceleration_multiplier = 1.25
	fuel_multiplier = 1.08
	max_fuel_multiplier = 0.7

/obj/item/cyberpunk_vehicle_part/engine/battery/high_output
	name = "Starlight high-output cell engine"
	part_name = "Starlight high-output cell engine"
	part_health = 85
	part_effect = "Removable-cell engine with stronger acceleration and faster drain."
	resource_type = "battery"
	speed_multiplier = 1.08
	acceleration_multiplier = 1.18
	fuel_multiplier = 1.28
	max_fuel_multiplier = 0

/obj/item/cyberpunk_vehicle_part/engine/battery/long_range
	name = "Starlight long-range cell engine"
	part_name = "Starlight long-range cell engine"
	part_health = 115
	part_effect = "Removable-cell engine tuned for longer battery endurance."
	resource_type = "battery"
	speed_multiplier = 0.9
	acceleration_multiplier = 0.88
	fuel_multiplier = 0.72
	max_fuel_multiplier = 0

/obj/item/cyberpunk_vehicle_part/engine/combustion/diesel
	name = "Starlight diesel combustion engine"
	part_name = "Starlight diesel combustion engine"
	part_health = 140
	part_effect = "Fuel engine with strong pull and a larger tank profile."
	resource_type = "fuel"
	speed_multiplier = 0.94
	acceleration_multiplier = 1.08
	fuel_multiplier = 0.95
	max_fuel_multiplier = 1.65

/obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline
	name = "Starlight gasoline combustion engine"
	part_name = "Starlight gasoline combustion engine"
	part_health = 105
	part_effect = "Fuel engine with quick acceleration and higher consumption."
	resource_type = "fuel"
	speed_multiplier = 1.08
	acceleration_multiplier = 1.28
	fuel_multiplier = 1.22
	max_fuel_multiplier = 1.15

/obj/item/cyberpunk_vehicle_part/engine/performance/turbo
	name = "Starlight turbo performance engine"
	part_name = "Starlight turbo performance engine"
	part_health = 75
	part_effect = "Fragile performance engine with high speed and fuel demand."
	resource_type = "fuel"
	speed_multiplier = 1.45
	acceleration_multiplier = 1.25
	fuel_multiplier = 1.55
	max_fuel_multiplier = 1.05

/obj/item/cyberpunk_vehicle_part/engine/performance/overdrive
	name = "Starlight overdrive performance engine"
	part_name = "Starlight overdrive performance engine"
	part_health = 80
	part_effect = "Performance engine tuned for top speed over launch power."
	resource_type = "fuel"
	speed_multiplier = 1.58
	acceleration_multiplier = 1.05
	fuel_multiplier = 1.48
	max_fuel_multiplier = 1.1

/obj/item/cyberpunk_vehicle_part/engine/heavy/industrial
	name = "Starlight industrial heavy engine"
	part_name = "Starlight industrial heavy engine"
	part_health = 190
	part_effect = "Durable heavy engine for cargo and tracked vehicles."
	resource_type = "fuel"
	speed_multiplier = 0.82
	acceleration_multiplier = 0.78
	fuel_multiplier = 1.05
	max_fuel_multiplier = 2.05

/obj/item/cyberpunk_vehicle_part/engine/heavy/armored
	name = "Starlight armored heavy engine"
	part_name = "Starlight armored heavy engine"
	part_health = 240
	part_effect = "Protected heavy engine with low speed and excellent endurance."
	resource_type = "fuel"
	speed_multiplier = 0.72
	acceleration_multiplier = 0.72
	fuel_multiplier = 0.92
	max_fuel_multiplier = 2.25

/obj/item/cyberpunk_vehicle_part/hull/sport_compact/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/sport_compact/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/utility_compact/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/utility_compact/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/armored_compact/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/armored_compact/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/bike/pursuit/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/bike/pursuit/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/bike/courier/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/bike/courier/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/large_car/executive/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/large_car/executive/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/race_street/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/race_street/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/electric_efficiency/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/electric_efficiency/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/electric_torque/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/electric_torque/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/battery/high_output/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/battery/high_output/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/battery/long_range/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/battery/long_range/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/combustion/diesel/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/combustion/diesel/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/performance/turbo/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/performance/turbo/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/performance/overdrive/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/performance/overdrive/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/heavy/industrial/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/heavy/industrial/tier3
	part_tier = 3

/obj/item/cyberpunk_vehicle_part/engine/heavy/armored/tier2
	part_tier = 2

/obj/item/cyberpunk_vehicle_part/engine/heavy/armored/tier3
	part_tier = 3

/obj/vehicle/ridden/cyberpunk
	name = "Starlight tech bike"
	desc = "A modular Starlight rideable vehicle platform."
	icon_state = "atv"
	max_integrity = 160
	max_occupants = 1
	key_type = null
	var/panel_open = FALSE
	var/fuel = 160
	var/max_fuel = 160
	var/base_move_delay = 1.4
	var/base_step_cost = 1
	var/base_z_cost = 8
	var/base_collision_damage = 8
	var/base_crash_resistance = 0
	var/cyberpunk_vehicle_can_fly = FALSE
	var/obj/item/stock_parts/power_store/cyberpunk_power_cell
	var/cyberpunk_base_max_fuel = 160
	var/cyberpunk_last_slip = 0
	var/list/datum/cyberpunk_vehicle_part/vehicle_parts
	var/hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/microbike
	var/drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain
	var/engine_part_type = /obj/item/cyberpunk_vehicle_part/engine

/obj/vehicle/ridden/cyberpunk/Initialize(mapload)
	. = ..()
	vehicle_parts = list()
	install_default_cyberpunk_vehicle_part(hull_part_type)
	install_default_cyberpunk_vehicle_part(drivetrain_part_type)
	install_default_cyberpunk_vehicle_part(engine_part_type)
	recalculate_cyberpunk_vehicle()
	create_reagents(max(1, max_fuel), OPENCONTAINER)
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/cyberpunk)

/obj/vehicle/ridden/cyberpunk/Destroy(force)
	QDEL_NULL(cyberpunk_power_cell)
	QDEL_LIST(vehicle_parts)
	return ..()

/obj/vehicle/ridden/cyberpunk/examine(mob/user)
	. = ..()
	. += span_notice("Charge/fuel: [get_cyberpunk_power_text()]. Dirty fuel: [round(get_cyberpunk_dirty_fuel_amount(), 0.1)]. Surface grip: [round(get_current_turf_grip_multiplier(), 0.01)]. Panel: [panel_open ? "open" : "closed"].")
	if(cyberpunk_vehicle_can_fly)
		. += span_notice("Flight drive is online. It can move between Z-levels while ridden.")
	if(length(vehicle_parts))
		. += span_notice("Installed parts:")
		for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
			. += span_notice("- [part.name] ([part.category], [part.manufacturer], [round(part.health_fraction() * 100)]%).")

/obj/vehicle/ridden/cyberpunk/proc/install_default_cyberpunk_vehicle_part(part_type)
	var/obj/item/cyberpunk_vehicle_part/part_item = new part_type(src)
	vehicle_parts += part_item.build_part_datum()
	qdel(part_item)

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_part(category)
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(part.category == category)
			return part
	return null

/obj/vehicle/ridden/cyberpunk/proc/install_cyberpunk_vehicle_part(datum/cyberpunk_vehicle_part/new_part)
	if(!new_part)
		return FALSE
	for(var/i in 1 to length(vehicle_parts))
		var/datum/cyberpunk_vehicle_part/old_part = vehicle_parts[i]
		if(old_part.category != new_part.category)
			continue
		vehicle_parts[i] = new_part
		qdel(old_part)
		recalculate_cyberpunk_vehicle()
		return TRUE
	vehicle_parts += new_part
	recalculate_cyberpunk_vehicle()
	return TRUE

/obj/vehicle/ridden/cyberpunk/proc/remove_cyberpunk_vehicle_part(category)
	for(var/i in 1 to length(vehicle_parts))
		var/datum/cyberpunk_vehicle_part/part = vehicle_parts[i]
		if(part.category != category)
			continue
		vehicle_parts.Cut(i, i + 1)
		var/obj/item/cyberpunk_vehicle_part/removed = new /obj/item/cyberpunk_vehicle_part(drop_location())
		removed.part_name = part.name
		removed.name = part.name
		removed.part_category = part.category
		removed.part_health = part.max_health
		removed.part_effect = part.effect_desc
		removed.speed_multiplier = part.speed_multiplier
		removed.acceleration_multiplier = part.acceleration_multiplier
		removed.maneuver_multiplier = part.maneuver_multiplier
		removed.traction_multiplier = part.traction_multiplier
		removed.grip_switch_multiplier = part.grip_switch_multiplier
		removed.brake_multiplier = part.brake_multiplier
		removed.fuel_multiplier = part.fuel_multiplier
		removed.max_fuel_multiplier = part.max_fuel_multiplier
		removed.resource_type = part.resource_type
		removed.passenger_capacity = part.passenger_capacity
		removed.mechanism_capacity = part.mechanism_capacity
		removed.running_gear_slots = part.running_gear_slots
		removed.floor_grip = part.floor_grip
		removed.rough_grip = part.rough_grip
		removed.bad_grip = part.bad_grip
		removed.space_grip = part.space_grip
		removed.manufacturer = part.manufacturer
		qdel(part)
		recalculate_cyberpunk_vehicle()
		return removed
	return null

/obj/vehicle/ridden/cyberpunk/proc/recalculate_cyberpunk_vehicle()
	var/datum/cyberpunk_vehicle_part/hull = get_cyberpunk_part("hull")
	var/datum/cyberpunk_vehicle_part/drivetrain = get_cyberpunk_part("drivetrain")
	var/datum/cyberpunk_vehicle_part/engine = get_cyberpunk_part("engine")
	var/old_integrity = uses_integrity ? get_integrity() : 0
	var/old_max_integrity = max_integrity
	var/old_fuel_ratio = (max_fuel > 0) ? (fuel / max_fuel) : 1
	max_occupants = max(1, hull?.passenger_capacity || 1)
	max_integrity = max(60, (hull?.max_health || 80) + (drivetrain?.max_health || 0) * 0.35 + (engine?.max_health || 0) * 0.25)
	max_fuel = max(1, round(cyberpunk_base_max_fuel * (engine?.max_fuel_multiplier || 1)))
	if(get_engine_resource_type() == "battery")
		max_fuel = cyberpunk_power_cell?.maxcharge || 0
		fuel = cyberpunk_power_cell?.charge || 0
	else
		if(cyberpunk_power_cell)
			cyberpunk_power_cell.forceMove(drop_location())
			cyberpunk_power_cell = null
		fuel = clamp(round(max_fuel * old_fuel_ratio), 0, max_fuel)
	if(reagents)
		reagents.maximum_volume = max(1, max_fuel)
	if(uses_integrity)
		var/integrity_ratio = (old_integrity > 0 && old_max_integrity > 0) ? (old_integrity / old_max_integrity) : 1
		update_integrity(clamp(round(max_integrity * integrity_ratio), 1, max_integrity))
	cyberpunk_vehicle_can_fly = FALSE
	if(drivetrain)
		cyberpunk_vehicle_can_fly = (findtext(drivetrain.name, "flight") || findtext(drivetrain.name, "gravitic") || drivetrain.space_grip >= 0.5)
	if(cyberpunk_vehicle_can_fly)
		movement_type |= FLYING
	else
		movement_type &= ~FLYING

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_vehicle_stat(stat_key)
	var/result = 1
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		var/health_factor = 0.35 + part.health_fraction() * 0.65
		switch(stat_key)
			if("speed")
				result *= part.speed_multiplier * health_factor
			if("acceleration")
				result *= part.acceleration_multiplier * health_factor
			if("fuel")
				result *= part.fuel_multiplier
			if("brake")
				result *= part.brake_multiplier * health_factor
			if("maneuver")
				result *= part.maneuver_multiplier * health_factor
			if("traction")
				result *= part.traction_multiplier * health_factor
			if("grip_switch")
				result *= part.grip_switch_multiplier * health_factor
	return max(0.1, result)

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_vehicle_synergy(mob/living/driver)
	if(!driver)
		return 1
	var/total = 0
	var/count = 0
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(!part.manufacturer)
			continue
		total += driver.get_corporate_synergy_multiplier(part.manufacturer)
		count++
	return count ? total / count : 1

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_move_delay(mob/living/driver, direction)
	var/grip = max(0.2, get_current_turf_grip_multiplier())
	var/delay = base_move_delay / get_cyberpunk_vehicle_stat("speed")
	delay /= sqrt(max(0.1, get_cyberpunk_vehicle_stat("acceleration")))
	delay /= max(0.35, grip)
	if(driver)
		delay *= driver.get_cyberpunk_driving_speed_multiplier()
		delay /= get_cyberpunk_vehicle_synergy(driver)
	return max(world.tick_lag, round(delay, world.tick_lag))

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_step_cost(mob/living/driver, direction)
	var/cost = base_step_cost * get_cyberpunk_vehicle_stat("fuel")
	cost *= 1 + max(0, 1 - get_current_turf_grip_multiplier()) * 0.5
	if(driver)
		cost *= driver.get_cyberpunk_driving_fuel_multiplier()
	return max(0.05, cost)

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_z_cost(mob/living/driver)
	return max(1, base_z_cost * get_cyberpunk_step_cost(driver, UP))

/obj/vehicle/ridden/cyberpunk/proc/can_operate_cyberpunk_vehicle(mob/living/user, altitude_change = FALSE)
	if(!length(vehicle_parts) || !get_cyberpunk_part("hull") || !get_cyberpunk_part("drivetrain") || !get_cyberpunk_part("engine"))
		if(user)
			to_chat(user, span_warning("[src] is missing required vehicle parts."))
		return FALSE
	if(get_integrity() <= 0)
		if(user)
			to_chat(user, span_warning("[src] is wrecked."))
		return FALSE
	if(get_cyberpunk_power_available() <= 0)
		if(user)
			to_chat(user, span_warning("[src] has no charge or fuel."))
		return FALSE
	if(altitude_change && !cyberpunk_vehicle_can_fly)
		if(user)
			to_chat(user, span_warning("[src] is not fitted for flight."))
		return FALSE
	return TRUE

/obj/vehicle/ridden/cyberpunk/proc/consume_cyberpunk_vehicle_charge(mob/living/user, amount)
	if(amount <= 0)
		return TRUE
	var/resource_type = get_engine_resource_type()
	if(resource_type == "battery")
		if(!cyberpunk_power_cell)
			if(user)
				to_chat(user, span_warning("[src] has no power cell installed."))
			return FALSE
		var/power_amount = amount * 40
		var/power_used = cyberpunk_power_cell.use(power_amount, TRUE)
		fuel = cyberpunk_power_cell.charge
		if(power_used >= power_amount)
			return TRUE
		if(user)
			to_chat(user, span_warning("[src]'s power cell is empty."))
		return FALSE
	if(resource_type == "fuel")
		var/available_fuel = get_cyberpunk_clean_fuel_amount()
		if(available_fuel < amount)
			if(user)
				to_chat(user, span_warning("[src]'s fuel tank sputters."))
			damage_cyberpunk_engine_from_dirty_fuel(amount)
			return FALSE
		remove_cyberpunk_clean_fuel(amount)
		fuel = get_cyberpunk_clean_fuel_amount()
		damage_cyberpunk_engine_from_dirty_fuel(amount)
		return TRUE
	if(fuel < amount)
		if(user)
			to_chat(user, span_warning("[src]'s drive sputters; it needs more charge or fuel."))
		return FALSE
	fuel = max(0, fuel - amount)
	return TRUE

/obj/vehicle/ridden/cyberpunk/proc/refuel_cyberpunk_vehicle(amount)
	if(amount <= 0 || fuel >= max_fuel)
		return FALSE
	fuel = min(max_fuel, fuel + amount)
	return TRUE

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_power_available()
	if(get_engine_resource_type() == "battery")
		return cyberpunk_power_cell?.charge || 0
	if(get_engine_resource_type() == "fuel")
		return get_cyberpunk_clean_fuel_amount()
	return fuel

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_power_max()
	if(get_engine_resource_type() == "battery")
		return cyberpunk_power_cell?.maxcharge || 0
	return max_fuel

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_power_text()
	var/resource_type = get_engine_resource_type()
	if(resource_type == "battery")
		return cyberpunk_power_cell ? "[round(cyberpunk_power_cell.charge)]/[cyberpunk_power_cell.maxcharge] cell" : "no power cell"
	if(resource_type == "fuel")
		return "[round(get_cyberpunk_clean_fuel_amount(), 0.1)]/[max_fuel] fuel mix"
	return "[round(fuel, 0.1)]/[max_fuel] [resource_type]"

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_clean_fuel_amount()
	if(!reagents)
		return 0
	var/total = 0
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		if(is_cyberpunk_valid_fuel_reagent(reagent.type))
			total += reagent.volume
	return total

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_dirty_fuel_amount()
	if(!reagents)
		return 0
	return max(0, reagents.total_volume - get_cyberpunk_clean_fuel_amount())

/obj/vehicle/ridden/cyberpunk/proc/get_cyberpunk_valid_fuel_reagents()
	return list(
		/datum/reagent/fuel,
		/datum/reagent/fuel/gasoline,
		/datum/reagent/fuel/diesel,
		/datum/reagent/nitrogen,
		/datum/reagent/hydrogen,
		/datum/reagent/carbondioxide,
	)

/obj/vehicle/ridden/cyberpunk/proc/is_cyberpunk_valid_fuel_reagent(reagent_type)
	if(ispath(reagent_type, /datum/reagent/fuel))
		return TRUE
	return reagent_type in list(
		/datum/reagent/nitrogen,
		/datum/reagent/hydrogen,
		/datum/reagent/carbondioxide,
	)

/obj/vehicle/ridden/cyberpunk/proc/remove_cyberpunk_clean_fuel(amount)
	if(!reagents || amount <= 0)
		return 0
	var/removed = 0
	var/list/fuel_priority = list(
		/datum/reagent/fuel/gasoline,
		/datum/reagent/fuel/diesel,
		/datum/reagent/fuel,
		/datum/reagent/hydrogen,
		/datum/reagent/nitrogen,
		/datum/reagent/carbondioxide,
	)
	for(var/reagent_type in fuel_priority)
		var/to_remove = min(amount - removed, reagents.get_reagent_amount(reagent_type, REAGENT_PARENT_TYPE))
		if(to_remove <= 0)
			continue
		reagents.remove_reagent(reagent_type, to_remove, TRUE)
		removed += to_remove
		if(removed >= amount)
			break
	return removed

/obj/vehicle/ridden/cyberpunk/proc/damage_cyberpunk_engine_from_dirty_fuel(amount)
	var/dirty = get_cyberpunk_dirty_fuel_amount()
	if(dirty <= 0 || amount <= 0)
		return
	var/burned_dirty = min(dirty, max(0.1, amount * 0.5))
	var/list/dirty_reagents = reagents.reagent_list.Copy()
	for(var/datum/reagent/reagent as anything in dirty_reagents)
		if(is_cyberpunk_valid_fuel_reagent(reagent.type))
			continue
		var/to_remove = min(burned_dirty, reagent.volume)
		if(to_remove <= 0)
			continue
		reagents.remove_reagent(reagent.type, to_remove)
		burned_dirty -= to_remove
		if(burned_dirty <= 0)
			break
	var/damage = max(1, amount * 2)
	var/datum/cyberpunk_vehicle_part/engine = get_cyberpunk_part("engine")
	engine?.take_damage(damage)
	if(uses_integrity && get_integrity() > 0)
		take_damage(max(1, damage * 0.25), BRUTE, MELEE, FALSE)
	if(world.time > cyberpunk_last_slip + 1 SECONDS)
		cyberpunk_last_slip = world.time
		visible_message(span_warning("[src]'s engine coughs on dirty fuel!"))

/obj/vehicle/ridden/cyberpunk/proc/get_current_turf_grip_multiplier()
	var/turf/current_turf = get_turf(src)
	var/datum/cyberpunk_vehicle_part/drivetrain = get_cyberpunk_part("drivetrain")
	if(!current_turf || !drivetrain)
		return 1
	var/grip = drivetrain.bad_grip
	if(isspaceturf(current_turf) || is_space_or_openspace(current_turf))
		grip = drivetrain.space_grip
	else if(istype(current_turf, /turf/open/floor))
		grip = drivetrain.floor_grip
	else if(istype(current_turf, /turf/open/lava))
		grip = drivetrain.bad_grip
	else if(istype(current_turf, /turf/open/misc/snow) || istype(current_turf, /turf/open/misc/ice) || istype(current_turf, /turf/open/misc/asteroid))
		grip = drivetrain.rough_grip
	return max(0.05, grip * drivetrain.traction_multiplier * get_cyberpunk_vehicle_stat("traction"))

/obj/vehicle/ridden/cyberpunk/proc/resolve_cyberpunk_vehicle_direction(mob/living/driver, direction)
	var/grip = get_current_turf_grip_multiplier()
	if(grip >= 1 || !direction)
		return direction
	var/slip_chance = clamp((1 - grip) * 55, 0, 70)
	slip_chance /= max(0.25, get_cyberpunk_vehicle_stat("maneuver"))
	slip_chance /= max(0.25, get_cyberpunk_vehicle_stat("grip_switch"))
	if(driver)
		slip_chance *= driver.get_cyberpunk_driving_maneuver_multiplier()
	if(!prob(slip_chance))
		return direction
	var/slip_direction = pick(turn(direction, 45), turn(direction, -45), direction)
	if(world.time > cyberpunk_last_slip + 1 SECONDS)
		cyberpunk_last_slip = world.time
		visible_message(span_warning("[src] loses traction and drifts!"))
		new /obj/effect/temp_visual/cyberpunk_vehicle_skid(get_turf(src))
	return slip_direction

/obj/vehicle/ridden/cyberpunk/proc/get_engine_resource_type()
	var/datum/cyberpunk_vehicle_part/engine = get_cyberpunk_part("engine")
	return engine?.resource_type || "energy"

/obj/vehicle/ridden/cyberpunk/proc/get_primary_driver()
	var/list/drivers = return_drivers()
	if(!length(drivers))
		return null
	return drivers[1]

/obj/vehicle/ridden/cyberpunk/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/cyberpunk_vehicle_part))
		var/obj/item/cyberpunk_vehicle_part/part_item = tool
		if(!user.transferItemToLoc(part_item, src))
			return ITEM_INTERACT_BLOCKING
		var/replaced_category = part_item.part_category
		var/obj/item/removed_part = get_cyberpunk_part(replaced_category) ? remove_cyberpunk_vehicle_part(replaced_category) : null
		install_cyberpunk_vehicle_part(part_item.build_part_datum())
		qdel(part_item)
		if(removed_part)
			removed_part.forceMove(drop_location())
			balloon_alert(user, "part replaced")
		else
			balloon_alert(user, "part installed")
		return ITEM_INTERACT_SUCCESS
	if(get_engine_resource_type() == "fuel" && tool?.reagents?.total_volume)
		if(!tool.is_open_container())
			balloon_alert(user, "open container")
			return ITEM_INTERACT_BLOCKING
		if(!reagents)
			create_reagents(max_fuel, OPENCONTAINER)
		var/free_volume = max(0, reagents.maximum_volume - reagents.total_volume)
		if(free_volume <= 0)
			balloon_alert(user, "tank full")
			return ITEM_INTERACT_BLOCKING
		var/transferred = tool.reagents.trans_to(src, min(free_volume, tool.reagents.total_volume), transferred_by = user)
		if(transferred <= 0)
			return ITEM_INTERACT_BLOCKING
		fuel = get_cyberpunk_clean_fuel_amount()
		balloon_alert(user, "fuel transferred")
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/stack/sheet/mineral/plasma))
		if(get_engine_resource_type() != "fuel")
			balloon_alert(user, "wrong resource")
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "use liquid fuel")
		return ITEM_INTERACT_BLOCKING
	if(istype(tool, /obj/item/stock_parts/power_store))
		if(get_engine_resource_type() == "battery")
			if(!panel_open)
				balloon_alert(user, "open panel first")
				return ITEM_INTERACT_BLOCKING
			if(cyberpunk_power_cell)
				balloon_alert(user, "cell installed")
				return ITEM_INTERACT_BLOCKING
			if(!user.transferItemToLoc(tool, src))
				return ITEM_INTERACT_BLOCKING
			cyberpunk_power_cell = tool
			fuel = cyberpunk_power_cell.charge
			max_fuel = cyberpunk_power_cell.maxcharge
			balloon_alert(user, "cell installed")
			return ITEM_INTERACT_SUCCESS
		if(get_engine_resource_type() == "fuel")
			balloon_alert(user, "wrong resource")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/stock_parts/power_store/cell = tool
		var/power_used = cell.use(1000, TRUE)
		if(power_used <= 0)
			balloon_alert(user, "cell empty")
			return ITEM_INTERACT_BLOCKING
		refuel_cyberpunk_vehicle(power_used / 40)
		balloon_alert(user, "charged")
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/vehicle/ridden/cyberpunk/attack_hand(mob/living/user, list/modifiers)
	if(panel_open && get_engine_resource_type() == "battery" && cyberpunk_power_cell)
		var/obj/item/stock_parts/power_store/cell_to_remove = cyberpunk_power_cell
		cyberpunk_power_cell = null
		fuel = 0
		max_fuel = 0
		if(user.put_in_hands(cell_to_remove))
			balloon_alert(user, "cell removed")
			return TRUE
		cell_to_remove.forceMove(drop_location())
		balloon_alert(user, "cell removed")
		return TRUE
	return ..()

/obj/vehicle/ridden/cyberpunk/screwdriver_act(mob/living/user, obj/item/tool)
	panel_open = !panel_open
	balloon_alert(user, panel_open ? "panel open" : "panel closed")
	playsound(src, 'sound/items/tools/screwdriver.ogg', 50, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/cyberpunk/wrench_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "RMB: remove part")
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/cyberpunk/wrench_act_secondary(mob/living/user, obj/item/tool)
	var/list/options = list()
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(part.category == "drivetrain")
			options["drivetrain"] = image(icon = 'icons/obj/tools.dmi', icon_state = "rtd")
		if(part.category == "engine")
			options["engine"] = image(icon = 'icons/obj/tools.dmi', icon_state = "wrench")
	if(!length(options))
		return ITEM_INTERACT_BLOCKING
	var/category = show_radial_menu(user, src, options, require_near = TRUE, tooltips = TRUE)
	if(!category)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/removed = remove_cyberpunk_vehicle_part(category)
	if(removed)
		user.put_in_hands(removed)
		balloon_alert(user, "part removed")
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/vehicle/ridden/cyberpunk/welder_act(mob/living/user, obj/item/tool)
	if(get_integrity() >= max_integrity)
		balloon_alert(user, "intact")
		return ITEM_INTERACT_BLOCKING
	user.visible_message(span_notice("[user] starts repairing [src]."), span_notice("You start repairing [src]."))
	var/repair_time = 4 SECONDS * user.get_cyberpunk_vehicle_repair_time_multiplier(src)
	if(!do_after(user, repair_time, target = src))
		return ITEM_INTERACT_BLOCKING
	var/repaired = repair_damage(user.get_cyberpunk_vehicle_repair_amount(src, 25))
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		part.repair(repaired * 0.25)
	balloon_alert(user, "repaired")
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/ridden/cyberpunk/click_alt_secondary(mob/user)
	show_cyberpunk_vehicle_radial(user)
	return CLICK_ACTION_SUCCESS

/obj/vehicle/ridden/cyberpunk/proc/show_cyberpunk_vehicle_radial(mob/user)
	if(!user || !Adjacent(user))
		return
	var/list/options = list(
		"Inspect parts" = image(icon = 'icons/obj/tools.dmi', icon_state = "rtd"),
		"Status" = image(icon = 'icons/obj/tools.dmi', icon_state = "analyzer"),
		"Toggle panel" = image(icon = 'icons/obj/tools.dmi', icon_state = "screwdriver_map"),
	)
	var/choice = show_radial_menu(user, src, options, require_near = TRUE, tooltips = TRUE)
	switch(choice)
		if("Inspect parts")
			for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
				to_chat(user, span_notice("[part.name]: [part.effect_desc] Health [round(part.health_fraction() * 100)]%."))
		if("Status")
			to_chat(user, span_notice("[src]: [round(get_integrity())]/[max_integrity] integrity, [get_cyberpunk_power_text()], grip [round(get_current_turf_grip_multiplier(), 0.01)], move delay [get_cyberpunk_move_delay(user, NORTH)]."))
		if("Toggle panel")
			panel_open = !panel_open
			balloon_alert(user, panel_open ? "panel open" : "panel closed")

/obj/vehicle/ridden/cyberpunk/can_z_move(direction, turf/start, turf/destination, z_move_flags = ZMOVE_FLIGHT_FLAGS, mob/living/rider)
	. = ..()
	if(!.)
		return
	if(!can_operate_cyberpunk_vehicle(rider, TRUE))
		return FALSE
	if(!rider || fuel >= get_cyberpunk_z_cost(rider))
		return .
	if(z_move_flags & ZMOVE_FEEDBACK)
		to_chat(rider, span_warning("[src] lacks charge for altitude change."))
	return FALSE

/obj/vehicle/ridden/cyberpunk/zMove(dir, turf/target, z_move_flags)
	var/mob/living/driver = get_primary_driver()
	if(!consume_cyberpunk_vehicle_charge(driver, get_cyberpunk_z_cost(driver)))
		return FALSE
	return ..()

/obj/vehicle/ridden/cyberpunk/Bump(atom/bumped)
	. = ..()
	var/mob/living/driver = get_primary_driver()
	var/impact = max(2, base_collision_damage * get_cyberpunk_vehicle_stat("speed") - base_crash_resistance)
	impact /= max(0.25, get_cyberpunk_vehicle_stat("brake"))
	if(driver)
		impact *= driver.get_cyberpunk_driving_brake_multiplier()
	if(isliving(bumped))
		var/mob/living/victim = bumped
		victim.apply_damage(impact, BRUTE)
		victim.Knockdown(1 SECONDS)
	else if(bumped?.uses_integrity && impact > 0)
		bumped.take_damage(impact, BRUTE, MELEE, TRUE)
	if(impact > 0 && uses_integrity && get_integrity() > 0)
		take_damage(max(1, impact * 0.4), BRUTE, MELEE, TRUE)
	var/datum/cyberpunk_vehicle_part/part = length(vehicle_parts) ? pick(vehicle_parts) : null
	part?.take_damage(impact * 0.35)
	visible_message(span_warning("[src] slams into [bumped]!"))

/obj/vehicle/ridden/cyberpunk/hover
	name = "Starlight hover courier"
	desc = "A compact hover platform with a gravitic drive."
	icon_state = "hoverboard_red"
	max_fuel = 220
	fuel = 220
	base_move_delay = 1.1
	base_z_cost = 6
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/bike
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/grav
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine

/obj/vehicle/ridden/cyberpunk/avi
	name = "Starlight AVI courier"
	desc = "A light automated-flight vehicle platform. It can climb and descend between Z-levels."
	icon_state = "hoverboard_nt"
	max_fuel = 360
	fuel = 360
	base_move_delay = 0.9
	base_z_cost = 10
	base_collision_damage = 14
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/cargo_minivan
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/performance

/obj/vehicle/ridden/cyberpunk/cargo
	name = "Starlight cargo mule"
	desc = "A slow modular cargo rideable with stronger body parts."
	icon_state = "atv"
	max_fuel = 240
	fuel = 240
	base_move_delay = 1.8
	base_collision_damage = 12
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/cargo_truck
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/heavy

/obj/effect/temp_visual/cyberpunk_vehicle_skid
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	layer = BELOW_MOB_LAYER
	duration = 1.2 SECONDS
	randomdir = TRUE
	color = "#202020"
	alpha = 130

/obj/effect/temp_visual/cyberpunk_vehicle_dust
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	layer = BELOW_MOB_LAYER
	duration = 0.8 SECONDS
	randomdir = TRUE
	color = "#b7a47a"
	alpha = 90

/datum/design/cyberpunk_vehicle_part
	name = "Starlight Vehicle Part"
	id = "starlight_vehicle_part"
	build_type = AUTOLATHE | PROTOLATHE | MECHFAB | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part
	category = list(
		RND_CATEGORY_INITIAL,
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_MOUNTS,
		RND_CATEGORY_MECHFAB_EQUIPMENT + RND_SUBCATEGORY_MECHFAB_EQUIPMENT_MISC,
	)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/cyberpunk_vehicle_part/hull
	name = "Starlight Compact Chassis"
	id = "starlight_hull_compact"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull

/datum/design/cyberpunk_vehicle_part/hull/microbike
	name = "Starlight Microbike Frame"
	id = "starlight_hull_microbike"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/microbike

/datum/design/cyberpunk_vehicle_part/hull/bike
	name = "Starlight Bike Frame"
	id = "starlight_hull_bike"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike

/datum/design/cyberpunk_vehicle_part/hull/large_car
	name = "Starlight Large Car Chassis"
	id = "starlight_hull_large_car"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car

/datum/design/cyberpunk_vehicle_part/hull/minivan
	name = "Starlight Minivan Chassis"
	id = "starlight_hull_minivan"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/minivan

/datum/design/cyberpunk_vehicle_part/hull/cargo_minivan
	name = "Starlight Cargo Minivan Chassis"
	id = "starlight_hull_cargo_minivan"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 11, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/cargo_minivan

/datum/design/cyberpunk_vehicle_part/hull/bus
	name = "Starlight Bus Chassis"
	id = "starlight_hull_bus"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 14, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bus

/datum/design/cyberpunk_vehicle_part/hull/cargo_truck
	name = "Starlight Cargo Truck Chassis"
	id = "starlight_hull_cargo_truck"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 16, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/cargo_truck

/datum/design/cyberpunk_vehicle_part/hull/apc
	name = "Starlight APC Hull"
	id = "starlight_hull_apc"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 18, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/apc

/datum/design/cyberpunk_vehicle_part/hull/tank
	name = "Starlight Tank Hull"
	id = "starlight_hull_tank"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 20, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 6, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/tank

/datum/design/cyberpunk_vehicle_part/hull/sport_compact
	name = "Starlight Sport Compact Chassis"
	id = "starlight_hull_sport_compact"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/sport_compact

/datum/design/cyberpunk_vehicle_part/hull/utility_compact
	name = "Starlight Utility Compact Chassis"
	id = "starlight_hull_utility_compact"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/utility_compact

/datum/design/cyberpunk_vehicle_part/hull/armored_compact
	name = "Starlight Armored Compact Chassis"
	id = "starlight_hull_armored_compact"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/armored_compact

/datum/design/cyberpunk_vehicle_part/hull/pursuit_bike
	name = "Starlight Pursuit Bike Frame"
	id = "starlight_hull_pursuit_bike"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/pursuit

/datum/design/cyberpunk_vehicle_part/hull/courier_bike
	name = "Starlight Courier Bike Frame"
	id = "starlight_hull_courier_bike"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/courier

/datum/design/cyberpunk_vehicle_part/hull/executive
	name = "Starlight Executive Sedan Chassis"
	id = "starlight_hull_executive"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/executive

/datum/design/cyberpunk_vehicle_part/hull/interceptor
	name = "Starlight Interceptor Chassis"
	id = "starlight_hull_interceptor"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor

/datum/design/cyberpunk_vehicle_part/drivetrain
	name = "Starlight Street Suspension"
	id = "starlight_drivetrain_street"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain

/datum/design/cyberpunk_vehicle_part/drivetrain/offroad
	name = "Starlight Off-Road Suspension"
	id = "starlight_drivetrain_offroad"
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad

/datum/design/cyberpunk_vehicle_part/drivetrain/tracks
	name = "Starlight Tracked Running Gear"
	id = "starlight_drivetrain_tracks"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks

/datum/design/cyberpunk_vehicle_part/drivetrain/legs
	name = "Starlight Walker Legs"
	id = "starlight_drivetrain_legs"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/legs

/datum/design/cyberpunk_vehicle_part/drivetrain/grav
	name = "Starlight Gravitic Drive"
	id = "starlight_drivetrain_grav"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav

/datum/design/cyberpunk_vehicle_part/drivetrain/flight_nozzles
	name = "Starlight Flight Nozzles"
	id = "starlight_drivetrain_flight_nozzles"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles

/datum/design/cyberpunk_vehicle_part/drivetrain/race_street
	name = "Starlight Race Street Suspension"
	id = "starlight_drivetrain_race_street"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/race_street

/datum/design/cyberpunk_vehicle_part/drivetrain/comfort_street
	name = "Starlight Comfort Street Suspension"
	id = "starlight_drivetrain_comfort_street"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street

/datum/design/cyberpunk_vehicle_part/drivetrain/rally
	name = "Starlight Rally Suspension"
	id = "starlight_drivetrain_rally"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally

/datum/design/cyberpunk_vehicle_part/drivetrain/crawler
	name = "Starlight Crawler Suspension"
	id = "starlight_drivetrain_crawler"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler

/datum/design/cyberpunk_vehicle_part/drivetrain/light_tracks
	name = "Starlight Light Tracks"
	id = "starlight_drivetrain_light_tracks"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light

/datum/design/cyberpunk_vehicle_part/drivetrain/industrial_tracks
	name = "Starlight Industrial Tracks"
	id = "starlight_drivetrain_industrial_tracks"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial

/datum/design/cyberpunk_vehicle_part/drivetrain/sport_grav
	name = "Starlight Sport Gravitic Drive"
	id = "starlight_drivetrain_sport_grav"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport

/datum/design/cyberpunk_vehicle_part/drivetrain/stable_grav
	name = "Starlight Stabilized Gravitic Drive"
	id = "starlight_drivetrain_stable_grav"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable

/datum/design/cyberpunk_vehicle_part/drivetrain/lift_nozzles
	name = "Starlight Lift Nozzles"
	id = "starlight_drivetrain_lift_nozzles"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift

/datum/design/cyberpunk_vehicle_part/drivetrain/vector_nozzles
	name = "Starlight Vector Nozzles"
	id = "starlight_drivetrain_vector_nozzles"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector

/datum/design/cyberpunk_vehicle_part/engine
	name = "Starlight Electric Engine"
	id = "starlight_engine_electric"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine

/datum/design/cyberpunk_vehicle_part/engine/battery
	name = "Starlight Removable-Cell Engine"
	id = "starlight_engine_battery"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery

/datum/design/cyberpunk_vehicle_part/engine/combustion
	name = "Starlight Combustion Engine"
	id = "starlight_engine_combustion"
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion

/datum/design/cyberpunk_vehicle_part/engine/performance
	name = "Starlight Performance Engine"
	id = "starlight_engine_performance"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance

/datum/design/cyberpunk_vehicle_part/engine/heavy
	name = "Starlight Heavy Engine"
	id = "starlight_engine_heavy"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy

/datum/design/cyberpunk_vehicle_part/engine/electric_efficiency
	name = "Starlight Efficient Electric Engine"
	id = "starlight_engine_electric_efficiency"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_efficiency

/datum/design/cyberpunk_vehicle_part/engine/electric_torque
	name = "Starlight Torque Electric Engine"
	id = "starlight_engine_electric_torque"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_torque

/datum/design/cyberpunk_vehicle_part/engine/battery_high_output
	name = "Starlight High-Output Cell Engine"
	id = "starlight_engine_battery_high_output"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/high_output

/datum/design/cyberpunk_vehicle_part/engine/battery_long_range
	name = "Starlight Long-Range Cell Engine"
	id = "starlight_engine_battery_long_range"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/long_range

/datum/design/cyberpunk_vehicle_part/engine/combustion_diesel
	name = "Starlight Diesel Combustion Engine"
	id = "starlight_engine_combustion_diesel"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/diesel

/datum/design/cyberpunk_vehicle_part/engine/combustion_gasoline
	name = "Starlight Gasoline Combustion Engine"
	id = "starlight_engine_combustion_gasoline"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline

/datum/design/cyberpunk_vehicle_part/engine/turbo
	name = "Starlight Turbo Performance Engine"
	id = "starlight_engine_turbo"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/turbo

/datum/design/cyberpunk_vehicle_part/engine/overdrive
	name = "Starlight Overdrive Performance Engine"
	id = "starlight_engine_overdrive"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/overdrive

/datum/design/cyberpunk_vehicle_part/engine/industrial_heavy
	name = "Starlight Industrial Heavy Engine"
	id = "starlight_engine_industrial_heavy"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/industrial

/datum/design/cyberpunk_vehicle_part/engine/armored_heavy
	name = "Starlight Armored Heavy Engine"
	id = "starlight_engine_armored_heavy"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/armored

/datum/design/cyberpunk_vehicle_part/hull/sport_compact/tier2
	name = "Starlight Sport Compact Chassis T2"
	id = "starlight_hull_sport_compact_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/sport_compact/tier2

/datum/design/cyberpunk_vehicle_part/hull/sport_compact/tier3
	name = "Starlight Sport Compact Chassis T3"
	id = "starlight_hull_sport_compact_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/sport_compact/tier3

/datum/design/cyberpunk_vehicle_part/hull/utility_compact/tier2
	name = "Starlight Utility Compact Chassis T2"
	id = "starlight_hull_utility_compact_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/utility_compact/tier2

/datum/design/cyberpunk_vehicle_part/hull/utility_compact/tier3
	name = "Starlight Utility Compact Chassis T3"
	id = "starlight_hull_utility_compact_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 11, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/utility_compact/tier3

/datum/design/cyberpunk_vehicle_part/hull/armored_compact/tier2
	name = "Starlight Armored Compact Chassis T2"
	id = "starlight_hull_armored_compact_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 11, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/armored_compact/tier2

/datum/design/cyberpunk_vehicle_part/hull/armored_compact/tier3
	name = "Starlight Armored Compact Chassis T3"
	id = "starlight_hull_armored_compact_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 13, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/armored_compact/tier3

/datum/design/cyberpunk_vehicle_part/hull/pursuit_bike/tier2
	name = "Starlight Pursuit Bike Frame T2"
	id = "starlight_hull_pursuit_bike_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/pursuit/tier2

/datum/design/cyberpunk_vehicle_part/hull/pursuit_bike/tier3
	name = "Starlight Pursuit Bike Frame T3"
	id = "starlight_hull_pursuit_bike_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/pursuit/tier3

/datum/design/cyberpunk_vehicle_part/hull/courier_bike/tier2
	name = "Starlight Courier Bike Frame T2"
	id = "starlight_hull_courier_bike_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/courier/tier2

/datum/design/cyberpunk_vehicle_part/hull/courier_bike/tier3
	name = "Starlight Courier Bike Frame T3"
	id = "starlight_hull_courier_bike_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/bike/courier/tier3

/datum/design/cyberpunk_vehicle_part/hull/executive/tier2
	name = "Starlight Executive Sedan Chassis T2"
	id = "starlight_hull_executive_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 11, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/executive/tier2

/datum/design/cyberpunk_vehicle_part/hull/executive/tier3
	name = "Starlight Executive Sedan Chassis T3"
	id = "starlight_hull_executive_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 13, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/executive/tier3

/datum/design/cyberpunk_vehicle_part/hull/interceptor/tier2
	name = "Starlight Interceptor Chassis T2"
	id = "starlight_hull_interceptor_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor/tier2

/datum/design/cyberpunk_vehicle_part/hull/interceptor/tier3
	name = "Starlight Interceptor Chassis T3"
	id = "starlight_hull_interceptor_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 12, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.5)
	build_path = /obj/item/cyberpunk_vehicle_part/hull/large_car/interceptor/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/race_street/tier2
	name = "Starlight Race Street Suspension T2"
	id = "starlight_drivetrain_race_street_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/race_street/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/race_street/tier3
	name = "Starlight Race Street Suspension T3"
	id = "starlight_drivetrain_race_street_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/race_street/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/comfort_street/tier2
	name = "Starlight Comfort Street Suspension T2"
	id = "starlight_drivetrain_comfort_street_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/comfort_street/tier3
	name = "Starlight Comfort Street Suspension T3"
	id = "starlight_drivetrain_comfort_street_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/comfort_street/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/rally/tier2
	name = "Starlight Rally Suspension T2"
	id = "starlight_drivetrain_rally_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/rally/tier3
	name = "Starlight Rally Suspension T3"
	id = "starlight_drivetrain_rally_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/rally/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/crawler/tier2
	name = "Starlight Crawler Suspension T2"
	id = "starlight_drivetrain_crawler_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/crawler/tier3
	name = "Starlight Crawler Suspension T3"
	id = "starlight_drivetrain_crawler_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad/crawler/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/light_tracks/tier2
	name = "Starlight Light Tracks T2"
	id = "starlight_drivetrain_light_tracks_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/light_tracks/tier3
	name = "Starlight Light Tracks T3"
	id = "starlight_drivetrain_light_tracks_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/light/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/industrial_tracks/tier2
	name = "Starlight Industrial Tracks T2"
	id = "starlight_drivetrain_industrial_tracks_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/industrial_tracks/tier3
	name = "Starlight Industrial Tracks T3"
	id = "starlight_drivetrain_industrial_tracks_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 11, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks/industrial/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/sport_grav/tier2
	name = "Starlight Sport Gravitic Drive T2"
	id = "starlight_drivetrain_sport_grav_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/sport_grav/tier3
	name = "Starlight Sport Gravitic Drive T3"
	id = "starlight_drivetrain_sport_grav_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/sport/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/stable_grav/tier2
	name = "Starlight Stabilized Gravitic Drive T2"
	id = "starlight_drivetrain_stable_grav_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/stable_grav/tier3
	name = "Starlight Stabilized Gravitic Drive T3"
	id = "starlight_drivetrain_stable_grav_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/grav/stable/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/lift_nozzles/tier2
	name = "Starlight Lift Nozzles T2"
	id = "starlight_drivetrain_lift_nozzles_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/lift_nozzles/tier3
	name = "Starlight Lift Nozzles T3"
	id = "starlight_drivetrain_lift_nozzles_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 9, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 3, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/lift/tier3

/datum/design/cyberpunk_vehicle_part/drivetrain/vector_nozzles/tier2
	name = "Starlight Vector Nozzles T2"
	id = "starlight_drivetrain_vector_nozzles_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector/tier2

/datum/design/cyberpunk_vehicle_part/drivetrain/vector_nozzles/tier3
	name = "Starlight Vector Nozzles T3"
	id = "starlight_drivetrain_vector_nozzles_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 3, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/drivetrain/flight_nozzles/vector/tier3

/datum/design/cyberpunk_vehicle_part/engine/electric_efficiency/tier2
	name = "Starlight Efficient Electric Engine T2"
	id = "starlight_engine_electric_efficiency_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_efficiency/tier2

/datum/design/cyberpunk_vehicle_part/engine/electric_efficiency/tier3
	name = "Starlight Efficient Electric Engine T3"
	id = "starlight_engine_electric_efficiency_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_efficiency/tier3

/datum/design/cyberpunk_vehicle_part/engine/electric_torque/tier2
	name = "Starlight Torque Electric Engine T2"
	id = "starlight_engine_electric_torque_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_torque/tier2

/datum/design/cyberpunk_vehicle_part/engine/electric_torque/tier3
	name = "Starlight Torque Electric Engine T3"
	id = "starlight_engine_electric_torque_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/electric_torque/tier3

/datum/design/cyberpunk_vehicle_part/engine/battery_high_output/tier2
	name = "Starlight High-Output Cell Engine T2"
	id = "starlight_engine_battery_high_output_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/high_output/tier2

/datum/design/cyberpunk_vehicle_part/engine/battery_high_output/tier3
	name = "Starlight High-Output Cell Engine T3"
	id = "starlight_engine_battery_high_output_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/high_output/tier3

/datum/design/cyberpunk_vehicle_part/engine/battery_long_range/tier2
	name = "Starlight Long-Range Cell Engine T2"
	id = "starlight_engine_battery_long_range_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/long_range/tier2

/datum/design/cyberpunk_vehicle_part/engine/battery_long_range/tier3
	name = "Starlight Long-Range Cell Engine T3"
	id = "starlight_engine_battery_long_range_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/battery/long_range/tier3

/datum/design/cyberpunk_vehicle_part/engine/combustion_diesel/tier2
	name = "Starlight Diesel Combustion Engine T2"
	id = "starlight_engine_combustion_diesel_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/diesel/tier2

/datum/design/cyberpunk_vehicle_part/engine/combustion_diesel/tier3
	name = "Starlight Diesel Combustion Engine T3"
	id = "starlight_engine_combustion_diesel_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/diesel/tier3

/datum/design/cyberpunk_vehicle_part/engine/combustion_gasoline/tier2
	name = "Starlight Gasoline Combustion Engine T2"
	id = "starlight_engine_combustion_gasoline_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline/tier2

/datum/design/cyberpunk_vehicle_part/engine/combustion_gasoline/tier3
	name = "Starlight Gasoline Combustion Engine T3"
	id = "starlight_engine_combustion_gasoline_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 7, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/combustion/gasoline/tier3

/datum/design/cyberpunk_vehicle_part/engine/turbo/tier2
	name = "Starlight Turbo Performance Engine T2"
	id = "starlight_engine_turbo_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/turbo/tier2

/datum/design/cyberpunk_vehicle_part/engine/turbo/tier3
	name = "Starlight Turbo Performance Engine T3"
	id = "starlight_engine_turbo_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/gold = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/turbo/tier3

/datum/design/cyberpunk_vehicle_part/engine/overdrive/tier2
	name = "Starlight Overdrive Performance Engine T2"
	id = "starlight_engine_overdrive_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/overdrive/tier2

/datum/design/cyberpunk_vehicle_part/engine/overdrive/tier3
	name = "Starlight Overdrive Performance Engine T3"
	id = "starlight_engine_overdrive_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/gold = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/performance/overdrive/tier3

/datum/design/cyberpunk_vehicle_part/engine/industrial_heavy/tier2
	name = "Starlight Industrial Heavy Engine T2"
	id = "starlight_engine_industrial_heavy_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/industrial/tier2

/datum/design/cyberpunk_vehicle_part/engine/industrial_heavy/tier3
	name = "Starlight Industrial Heavy Engine T3"
	id = "starlight_engine_industrial_heavy_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/industrial/tier3

/datum/design/cyberpunk_vehicle_part/engine/armored_heavy/tier2
	name = "Starlight Armored Heavy Engine T2"
	id = "starlight_engine_armored_heavy_t2"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/armored/tier2

/datum/design/cyberpunk_vehicle_part/engine/armored_heavy/tier3
	name = "Starlight Armored Heavy Engine T3"
	id = "starlight_engine_armored_heavy_t3"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/silver = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_vehicle_part/engine/heavy/armored/tier3

/datum/design/cyberpunk_vehicle
	name = "Starlight Prototype Vehicle"
	id = "starlight_vehicle_prototype"
	build_type = MECHFAB | PROTOLATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 12, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/vehicle/sealed/car/cyberpunk_test
	construction_time = 30 SECONDS
	category = list(
		RND_CATEGORY_MECHFAB_EQUIPMENT + RND_SUBCATEGORY_MECHFAB_EQUIPMENT_MISC,
		RND_CATEGORY_CONSTRUCTION + RND_SUBCATEGORY_CONSTRUCTION_MOUNTS,
	)

/datum/design/cyberpunk_vehicle/ridden
	name = "Starlight Tech Bike"
	id = "starlight_vehicle_tech_bike"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 8, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/vehicle/ridden/cyberpunk

/datum/design/cyberpunk_vehicle/ridden/hover
	name = "Starlight Hover Courier"
	id = "starlight_vehicle_hover_courier"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/vehicle/ridden/cyberpunk/hover

/datum/design/cyberpunk_vehicle/ridden/avi
	name = "Starlight AVI Courier"
	id = "starlight_vehicle_avi_courier"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 14, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/titanium = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/vehicle/ridden/cyberpunk/avi

/datum/design/cyberpunk_vehicle/ridden/cargo
	name = "Starlight Cargo Mule"
	id = "starlight_vehicle_cargo_mule"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 16, /datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/vehicle/ridden/cyberpunk/cargo
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/cyberpunk_vehicle/microbike
	name = "Starlight Microbike"
	id = "starlight_vehicle_microbike"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/microbike

/datum/design/cyberpunk_vehicle/bike
	name = "Starlight Bike"
	id = "starlight_vehicle_bike"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/bike

/datum/design/cyberpunk_vehicle/large_car
	name = "Starlight Large Car"
	id = "starlight_vehicle_large_car"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/large_car

/datum/design/cyberpunk_vehicle/minivan
	name = "Starlight Minivan"
	id = "starlight_vehicle_minivan"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/minivan

/datum/design/cyberpunk_vehicle/cargo_minivan
	name = "Starlight Cargo Minivan"
	id = "starlight_vehicle_cargo_minivan"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/cargo_minivan

/datum/design/cyberpunk_vehicle/bus
	name = "Starlight Bus"
	id = "starlight_vehicle_bus"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/bus

/datum/design/cyberpunk_vehicle/cargo_truck
	name = "Starlight Cargo Truck"
	id = "starlight_vehicle_cargo_truck"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/cargo_truck

/datum/design/cyberpunk_vehicle/apc
	name = "Starlight APC"
	id = "starlight_vehicle_apc"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/apc

/datum/design/cyberpunk_vehicle/tank
	name = "Starlight Tank"
	id = "starlight_vehicle_tank"
	build_path = /obj/vehicle/sealed/car/cyberpunk_test/tank

/datum/techweb_node/cyberpunk_vehicle
	id = "starlight_vehicle"
	starting_node = TRUE
	display_name = "Starlight Vehicle Platforms"
	description = "Vehicle hulls, running gear and engines produced by Starlight."
	design_ids = list(
		"starlight_hull_compact",
		"starlight_hull_microbike",
		"starlight_hull_bike",
		"starlight_hull_large_car",
		"starlight_hull_minivan",
		"starlight_hull_cargo_minivan",
		"starlight_hull_bus",
		"starlight_hull_cargo_truck",
		"starlight_hull_apc",
		"starlight_hull_tank",
		"starlight_drivetrain_street",
		"starlight_drivetrain_offroad",
		"starlight_drivetrain_tracks",
		"starlight_drivetrain_legs",
		"starlight_drivetrain_grav",
		"starlight_drivetrain_flight_nozzles",
		"starlight_engine_electric",
		"starlight_engine_combustion",
		"starlight_engine_performance",
		"starlight_engine_heavy",
		"starlight_vehicle_prototype",
		"starlight_vehicle_microbike",
		"starlight_vehicle_bike",
		"starlight_vehicle_large_car",
		"starlight_vehicle_minivan",
		"starlight_vehicle_cargo_minivan",
		"starlight_vehicle_bus",
		"starlight_vehicle_cargo_truck",
		"starlight_vehicle_apc",
		"starlight_vehicle_tank",
	)

//CYBERPUNK BUILD - rebuild and delete before release
/obj/vehicle/sealed/car/cyberpunk_test
	name = "Starlight prototype vehicle"
	desc = "A temporary Starlight test platform using a clown car body shell."
	icon_state = "clowncar"
	max_integrity = 220
	max_occupants = 4
	max_drivers = 1
	enter_delay = 1 SECONDS
	escape_time = 0 SECONDS
	key_type = null
	car_traits = NONE
	vehicle_move_delay = 0
	engine_sound = 'sound/vehicles/carrev.ogg'
	engine_sound_length = 2 SECONDS
	var/panel_open = FALSE
	var/list/datum/cyberpunk_vehicle_part/vehicle_parts
	var/fuel = 2000
	var/max_fuel = 2000
	var/max_mechanism_slots = 1
	var/list/installed_mechanisms
	var/subpixel_x = 0
	var/subpixel_y = 0
	var/cy_world_px = 0
	var/cy_world_py = 0
	var/cy_velocity_x = 0
	var/cy_velocity_y = 0
	var/cy_accel_x = 0
	var/cy_accel_y = 1
	var/cy_grip_world_x = 0
	var/cy_grip_world_y = 1
	var/cy_forward_x = 0
	var/cy_forward_y = 1
	var/control_x = 0
	var/control_y = 0
	var/directed_x = 0
	var/directed_y = 0
	var/movement_x = 0
	var/movement_y = 0
	var/grip_x = 0
	var/grip_y = 0
	var/current_speed = 0
	var/last_input_time = 0
	var/base_maneuver = 7
	var/base_acceleration = 120
	var/base_traction = 4
	var/base_grip_switch = 2.5
	var/base_max_speed = 180
	var/base_brake = 70
	var/base_fuel_use = 0.05
	var/parking_speed_threshold = 45
	var/parking_acceleration_multiplier = 0.35
	var/parking_maneuver_multiplier = 0.45
	var/parking_brake_bonus = 0.45
	var/max_pixel_motion_per_tick = 8
	var/max_tile_steps_per_tick = 1
	var/pixel_animation_time = 0.2 SECONDS
	var/cy_smooth_camera_follow = TRUE
	var/cy_collision_center_offset_x = 16
	var/cy_collision_center_offset_y = 16
	var/cy_collision_half_width = 8
	var/cy_collision_half_height = 8
	var/cy_drift_amount = 0
	var/cy_reverse_drive = FALSE
	var/cy_reverse_speed_threshold = 35
	var/cy_reverse_max_speed_multiplier = 0.45
	var/cy_opposite_brake_multiplier = 1.75
	var/drift_active = FALSE
	var/last_drift_visual = FALSE
	var/last_skid_time = 0
	var/hull_part_type = /obj/item/cyberpunk_vehicle_part/hull
	var/drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain
	var/engine_part_type = /obj/item/cyberpunk_vehicle_part/engine

/obj/vehicle/sealed/car/cyberpunk_test/Initialize(mapload)
	. = ..()
	var/obj/item/cyberpunk_vehicle_part/default_hull = new hull_part_type(src)
	var/obj/item/cyberpunk_vehicle_part/default_drivetrain = new drivetrain_part_type(src)
	var/obj/item/cyberpunk_vehicle_part/default_engine = new engine_part_type(src)
	vehicle_parts = list(default_hull.build_part_datum(), default_drivetrain.build_part_datum(), default_engine.build_part_datum())
	qdel(default_hull)
	qdel(default_drivetrain)
	qdel(default_engine)
	installed_mechanisms = list()
	recalculate_vehicle_body()
	set_glide_size(MAX_GLIDE_SIZE)
	animate_movement = NO_STEPS
	cy_world_px = (x - 1) * ICON_SIZE_X + pixel_x
	cy_world_py = (y - 1) * ICON_SIZE_Y + pixel_y
	cy_set_forward_from_dir(dir || NORTH)
	cy_accel_x = cy_forward_x
	cy_accel_y = cy_forward_y
	cy_grip_world_x = cy_forward_x
	cy_grip_world_y = cy_forward_y
	START_PROCESSING(SSfastprocess, src)

/obj/vehicle/sealed/car/cyberpunk_test/microbike
	name = "Starlight microbike"
	desc = "A small Starlight one-seat vehicle with a compact mechanism slot."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/microbike

/obj/vehicle/sealed/car/cyberpunk_test/bike
	name = "Starlight bike"
	desc = "A two-seat Starlight bike frame."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/bike

/obj/vehicle/sealed/car/cyberpunk_test/large_car
	name = "Starlight large car"
	desc = "A larger Starlight car body with two mechanism slots."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/large_car

/obj/vehicle/sealed/car/cyberpunk_test/minivan
	name = "Starlight minivan"
	desc = "A six-seat Starlight minivan."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/minivan

/obj/vehicle/sealed/car/cyberpunk_test/cargo_minivan
	name = "Starlight cargo minivan"
	desc = "A compact cargo vehicle with four mechanism slots."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/cargo_minivan

/obj/vehicle/sealed/car/cyberpunk_test/bus
	name = "Starlight bus"
	desc = "A slow eight-seat Starlight bus."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/bus
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/offroad
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/heavy

/obj/vehicle/sealed/car/cyberpunk_test/cargo_truck
	name = "Starlight cargo truck"
	desc = "A heavy Starlight cargo carrier with six mechanism slots."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/cargo_truck
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/heavy

/obj/vehicle/sealed/car/cyberpunk_test/apc
	name = "Starlight APC"
	desc = "A heavy armored Starlight carrier."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/apc
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/heavy

/obj/vehicle/sealed/car/cyberpunk_test/tank
	name = "Starlight tank"
	desc = "A heavy armored Starlight combat hull."
	hull_part_type = /obj/item/cyberpunk_vehicle_part/hull/tank
	drivetrain_part_type = /obj/item/cyberpunk_vehicle_part/drivetrain/tracks
	engine_part_type = /obj/item/cyberpunk_vehicle_part/engine/heavy

/obj/vehicle/sealed/car/cyberpunk_test/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	for(var/mob/occupant as anything in occupants)
		cy_reset_occupant_camera(occupant)
	QDEL_LIST(vehicle_parts)
	installed_mechanisms = null
	return ..()

/obj/vehicle/sealed/car/cyberpunk_test/after_remove_occupant(mob/M)
	. = ..()
	cy_reset_occupant_camera(M)

/obj/vehicle/sealed/car/cyberpunk_test/relaymove(mob/living/user, direction)
	if(!is_driver(user) || !canmove)
		return TRUE
	if(fuel <= 0)
		if(COOLDOWN_FINISHED(src, enginesound_cooldown))
			COOLDOWN_START(src, enginesound_cooldown, 1 SECONDS)
			to_chat(user, span_warning("[src]'s engine has no charge."))
		clear_control_vector()
		return TRUE
	set_control_from_dir(direction)
	last_input_time = world.time
	return TRUE

/obj/vehicle/sealed/car/cyberpunk_test/proc/set_control_from_dir(direction)
	control_x = 0
	control_y = 0
	if(direction & EAST)
		control_x += 1
	if(direction & WEST)
		control_x -= 1
	if(direction & NORTH)
		control_y += 1
	if(direction & SOUTH)
		control_y -= 1
	normalize_pair("control")

/obj/vehicle/sealed/car/cyberpunk_test/proc/clear_control_vector()
	control_x = 0
	control_y = 0

/obj/vehicle/sealed/car/cyberpunk_test/process(seconds_per_tick)
	if(!seconds_per_tick)
		seconds_per_tick = world.tick_lag * 0.1
	seconds_per_tick = clamp(seconds_per_tick, 0, 0.2)
	update_pixel_movement(seconds_per_tick)

/obj/vehicle/sealed/car/cyberpunk_test/proc/update_pixel_movement(seconds_per_tick)
	if(world.time > last_input_time + 3)
		clear_control_vector()

	var/mob/living/driver = get_primary_driver()
	var/speed_multiplier = driver?.get_cyberpunk_driving_speed_multiplier() || 1
	var/reaction_multiplier = driver?.get_cyberpunk_driving_reaction_multiplier() || 1
	var/maneuver_multiplier = driver?.get_cyberpunk_driving_maneuver_multiplier() || 1
	var/brake_multiplier = driver?.get_cyberpunk_driving_brake_multiplier() || 1
	var/fuel_multiplier = driver?.get_cyberpunk_driving_fuel_multiplier() || 1
	var/corporate_vehicle_multiplier = get_vehicle_corporate_synergy_multiplier(driver)

	var/hull_health = get_part_health_fraction("hull")
	var/drivetrain_health = get_part_health_fraction("drivetrain")
	var/engine_health = get_part_health_fraction("engine")
	var/turf_grip = get_current_turf_grip_multiplier()
	var/max_speed = base_max_speed * speed_multiplier * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("speed") * turf_grip * (0.35 + engine_health * 0.65) * (0.55 + hull_health * 0.45)
	var/acceleration = base_acceleration * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("acceleration") * (0.25 + engine_health * 0.75)
	var/maneuver = base_maneuver * maneuver_multiplier * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("maneuver") * (0.35 + drivetrain_health * 0.65)
	var/traction = base_traction * reaction_multiplier * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("traction") * turf_grip * (0.3 + drivetrain_health * 0.7)
	var/grip_switch = base_grip_switch * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("grip_switch") * (0.35 + drivetrain_health * 0.65)
	var/brake = base_brake * brake_multiplier * corporate_vehicle_multiplier * get_vehicle_stat_multiplier("brake") * (0.3 + drivetrain_health * 0.7)
	var/pre_input_speed = cy_get_speed()
	var/parking_factor = clamp(pre_input_speed / max(parking_speed_threshold, 1), 0, 1)
	var/low_speed_acceleration_factor = parking_acceleration_multiplier + (1 - parking_acceleration_multiplier) * parking_factor
	var/low_speed_maneuver_factor = parking_maneuver_multiplier + (1 - parking_maneuver_multiplier) * parking_factor
	acceleration *= low_speed_acceleration_factor
	maneuver *= low_speed_maneuver_factor
	brake *= 1 + (1 - parking_factor) * parking_brake_bonus

	var/has_input = abs(control_x) + abs(control_y) > 0.01
	var/input_velocity_alignment = 1
	var/input_forward_alignment = 1
	if(has_input)
		input_forward_alignment = vector_dot(control_x, control_y, cy_forward_x, cy_forward_y)
		if(pre_input_speed > 0.05)
			input_velocity_alignment = vector_dot(control_x, control_y, cy_velocity_x / pre_input_speed, cy_velocity_y / pre_input_speed)
	var/reverse_request = has_input && input_forward_alignment < -0.35
	var/opposite_brake_request = has_input && input_velocity_alignment < -0.25 && pre_input_speed > 2
	if(reverse_request && pre_input_speed <= cy_reverse_speed_threshold)
		cy_reverse_drive = TRUE
	else if(!reverse_request)
		cy_reverse_drive = FALSE
	if(cy_reverse_drive)
		max_speed *= cy_reverse_max_speed_multiplier

	if(has_input && (!opposite_brake_request || cy_reverse_drive))
		cy_approach_accel_vector(control_x, control_y, clamp(maneuver * seconds_per_tick * 0.35, 0, 1))
	else
		var/accel_decay = clamp(maneuver * seconds_per_tick * 0.35, 0, 1)
		cy_accel_x *= (1 - accel_decay)
		cy_accel_y *= (1 - accel_decay)
		if(abs(cy_accel_x) < 0.01)
			cy_accel_x = 0
		if(abs(cy_accel_y) < 0.01)
			cy_accel_y = 0

	directed_x = cy_accel_x
	directed_y = cy_accel_y
	var/has_accel = abs(cy_accel_x) + abs(cy_accel_y) > 0.01
	if(has_accel && !cy_reverse_drive && !opposite_brake_request)
		cy_forward_x = cy_accel_x
		cy_forward_y = cy_accel_y
		cy_normalize_forward_vector()
		update_visual_dir()

	if(has_input)
		if(opposite_brake_request)
			var/opposite_brake_delta = min(pre_input_speed, brake * cy_opposite_brake_multiplier * seconds_per_tick)
			var/opposite_brake_scale = max(0, (pre_input_speed - opposite_brake_delta) / max(pre_input_speed, 0.01))
			cy_velocity_x *= opposite_brake_scale
			cy_velocity_y *= opposite_brake_scale
		if(!opposite_brake_request || cy_reverse_drive)
			cy_velocity_x += cy_accel_x * acceleration * seconds_per_tick
			cy_velocity_y += cy_accel_y * acceleration * seconds_per_tick
	else
		var/current_brake_speed = cy_get_speed()
		if(current_brake_speed > 0)
			var/brake_delta = min(current_brake_speed, brake * seconds_per_tick)
			var/brake_scale = max(0, (current_brake_speed - brake_delta) / current_brake_speed)
			cy_velocity_x *= brake_scale
			cy_velocity_y *= brake_scale

	current_speed = cy_get_speed()
	if(current_speed > max_speed)
		var/speed_scale = max_speed / current_speed
		cy_velocity_x *= speed_scale
		cy_velocity_y *= speed_scale
		current_speed = max_speed

	if(current_speed > 0.05)
		var/vel_x = cy_velocity_x / current_speed
		var/vel_y = cy_velocity_y / current_speed
		if(!cy_grip_world_x && !cy_grip_world_y)
			cy_grip_world_x = vel_x
			cy_grip_world_y = vel_y
		if(has_accel)
			cy_approach_grip_vector(cy_accel_x, cy_accel_y, clamp(grip_switch * turf_grip * seconds_per_tick * 0.25, 0, 1))
		else
			cy_approach_grip_vector(vel_x, vel_y, clamp(grip_switch * turf_grip * seconds_per_tick * 0.1, 0, 1))

		var/grip_alignment = clamp(vector_dot(vel_x, vel_y, cy_grip_world_x, cy_grip_world_y), -1, 1)
		var/grip_slip = 1 - grip_alignment
		var/stable_limit = clamp((0.28 + drivetrain_health * 0.18) * max(turf_grip, 0.25), 0.08, 0.55)
		drift_active = grip_slip > stable_limit && current_speed > 18
		cy_drift_amount = grip_slip * current_speed

		if(has_accel)
			var/accel_alignment = clamp(vector_dot(vel_x, vel_y, cy_accel_x, cy_accel_y), -1, 1)
			var/accel_slip = 1 - accel_alignment
			var/follow = traction * seconds_per_tick * (drift_active ? 0.08 : 0.25)
			cy_approach_velocity_direction(cy_accel_x, cy_accel_y, follow)
			var/speed_loss = clamp(accel_slip * (drift_active ? 0.08 : 0.32) * seconds_per_tick, 0, 0.55)
			cy_velocity_x *= (1 - speed_loss)
			cy_velocity_y *= (1 - speed_loss)
	else
		drift_active = FALSE
		cy_drift_amount = 0

	current_speed = cy_get_speed()
	if(current_speed > max_speed)
		var/final_speed_scale = max_speed / current_speed
		cy_velocity_x *= final_speed_scale
		cy_velocity_y *= final_speed_scale
		current_speed = max_speed

	if(abs(cy_velocity_x) < 0.05)
		cy_velocity_x = 0
	if(abs(cy_velocity_y) < 0.05)
		cy_velocity_y = 0

	current_speed = cy_get_speed()
	if(current_speed > 0)
		movement_x = cy_velocity_x / current_speed
		movement_y = cy_velocity_y / current_speed
	else
		movement_x = 0
		movement_y = 0
	grip_x = cy_grip_world_x
	grip_y = cy_grip_world_y

	var/grip_speed_limit = max_speed * (0.45 + drivetrain_health * 0.45)
	if(current_speed > grip_speed_limit)
		drift_active = TRUE
	if(last_drift_visual != drift_active)
		last_drift_visual = drift_active
		update_appearance(UPDATE_OVERLAYS)

	if(current_speed <= 0.01 || !isturf(loc))
		current_speed = 0
		return

	var/next_px = cy_world_px + cy_velocity_x * seconds_per_tick
	var/next_py = cy_world_py + cy_velocity_y * seconds_per_tick
	var/move_x = next_px - cy_world_px
	var/move_y = next_py - cy_world_py
	if(cy_can_occupy_pixel_position(next_px, next_py))
		cy_world_px = next_px
		cy_world_py = next_py
	else
		cy_on_pixel_collision(cy_velocity_to_dir())
		cy_velocity_x = 0
		cy_velocity_y = 0
		current_speed = 0
		drift_active = FALSE
		cy_drift_amount = 0
		return

	consume_vehicle_fuel((abs(move_x) + abs(move_y)) * base_fuel_use * fuel_multiplier * get_vehicle_stat_multiplier("fuel"))
	handle_vehicle_movement_visuals()
	cy_apply_world_pixel_position()

/obj/vehicle/sealed/car/cyberpunk_test/proc/handle_vehicle_movement_visuals()
	if(current_speed < 16 || world.time < last_skid_time + 4)
		return
	last_skid_time = world.time
	var/turf/skid_turf = get_turf(src)
	if(!skid_turf)
		return
	if(drift_active)
		new /obj/effect/temp_visual/cyberpunk_vehicle_skid(skid_turf)
	else if(prob(15))
		new /obj/effect/temp_visual/cyberpunk_vehicle_dust(skid_turf)

/obj/vehicle/sealed/car/cyberpunk_test/proc/approach_value(current, target, amount)
	if(current < target)
		return min(target, current + amount)
	if(current > target)
		return max(target, current - amount)
	return current

/obj/vehicle/sealed/car/cyberpunk_test/proc/normalize_pair(kind)
	var/x_value
	var/y_value
	switch(kind)
		if("control")
			x_value = control_x
			y_value = control_y
		if("directed")
			x_value = directed_x
			y_value = directed_y
		if("movement")
			x_value = movement_x
			y_value = movement_y
		if("grip")
			x_value = grip_x
			y_value = grip_y
	var/magnitude = sqrt(x_value * x_value + y_value * y_value)
	if(magnitude <= 1)
		return
	x_value /= magnitude
	y_value /= magnitude
	switch(kind)
		if("control")
			control_x = x_value
			control_y = y_value
		if("directed")
			directed_x = x_value
			directed_y = y_value
		if("movement")
			movement_x = x_value
			movement_y = y_value
		if("grip")
			grip_x = x_value
			grip_y = y_value

/obj/vehicle/sealed/car/cyberpunk_test/proc/vector_dot(ax, ay, bx, by)
	return ax * bx + ay * by

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_get_speed()
	return sqrt(cy_velocity_x * cy_velocity_x + cy_velocity_y * cy_velocity_y)

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_approach_accel_vector(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	cy_accel_x += (target_x - cy_accel_x) * amount
	cy_accel_y += (target_y - cy_accel_y) * amount
	var/length = sqrt(cy_accel_x * cy_accel_x + cy_accel_y * cy_accel_y)
	if(length <= 0)
		cy_accel_x = 0
		cy_accel_y = 0
		return
	cy_accel_x /= length
	cy_accel_y /= length

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_approach_grip_vector(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	cy_grip_world_x += (target_x - cy_grip_world_x) * amount
	cy_grip_world_y += (target_y - cy_grip_world_y) * amount
	var/length = sqrt(cy_grip_world_x * cy_grip_world_x + cy_grip_world_y * cy_grip_world_y)
	if(length <= 0)
		return
	cy_grip_world_x /= length
	cy_grip_world_y /= length

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_approach_velocity_direction(target_x, target_y, amount)
	amount = clamp(amount, 0, 1)
	var/speed = cy_get_speed()
	if(speed <= 0)
		return
	var/current_x = cy_velocity_x / speed
	var/current_y = cy_velocity_y / speed
	current_x += (target_x - current_x) * amount
	current_y += (target_y - current_y) * amount
	var/length = sqrt(current_x * current_x + current_y * current_y)
	if(length <= 0)
		return
	current_x /= length
	current_y /= length
	cy_velocity_x = current_x * speed
	cy_velocity_y = current_y * speed

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_apply_world_pixel_position()
	var/tile = ICON_SIZE_X
	var/new_x = FLOOR(cy_world_px / tile, 1) + 1
	var/new_y = FLOOR(cy_world_py / tile, 1) + 1
	var/new_pixel_x = round(cy_world_px - ((new_x - 1) * tile))
	var/new_pixel_y = round(cy_world_py - ((new_y - 1) * tile))

	if(new_pixel_x > tile * 0.5)
		new_pixel_x -= tile
		new_x++
	else if(new_pixel_x < -tile * 0.5)
		new_pixel_x += tile
		new_x--

	if(new_pixel_y > tile * 0.5)
		new_pixel_y -= tile
		new_y++
	else if(new_pixel_y < -tile * 0.5)
		new_pixel_y += tile
		new_y--

	var/turf/new_turf = locate(new_x, new_y, z)
	var/animation_time = max(1, round(pixel_animation_time))
	var/did_register_to_new_turf = FALSE

	if(new_turf && loc != new_turf)
		var/turf/old_turf = loc
		var/old_x = x
		var/old_y = y
		var/old_pixel_x = pixel_x
		var/old_pixel_y = pixel_y
		var/move_dir = get_dir(src, new_turf)
		forceMove(new_turf)
		did_register_to_new_turf = TRUE

		var/tile_shift_x = (x - old_x) * tile
		var/tile_shift_y = (y - old_y) * tile
		pixel_x = old_pixel_x - tile_shift_x
		pixel_y = old_pixel_y - tile_shift_y
		cy_sync_occupant_cameras(pixel_x, pixel_y, 0)

		if(trailer && old_turf)
			var/dir_to_move = get_dir(trailer.loc, old_turf)
			step(trailer, dir_to_move)
		if(move_dir)
			after_move(move_dir)

	animate(src, pixel_x = new_pixel_x, pixel_y = new_pixel_y, time = animation_time, flags = ANIMATION_END_NOW)
	cy_sync_occupant_cameras(new_pixel_x, new_pixel_y, animation_time)
	if(!did_register_to_new_turf)
		return

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_sync_occupant_cameras(target_pixel_x = pixel_x, target_pixel_y = pixel_y, animation_time = 0)
	if(!cy_smooth_camera_follow)
		return
	for(var/mob/occupant as anything in occupants)
		cy_sync_occupant_camera(occupant, target_pixel_x, target_pixel_y, animation_time)

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_sync_occupant_camera(mob/occupant, target_pixel_x = pixel_x, target_pixel_y = pixel_y, animation_time = 0)
	if(!cy_smooth_camera_follow || !occupant?.client)
		return
	var/client/occupant_client = occupant.client
	if(animation_time > 0)
		animate(occupant_client, pixel_x = target_pixel_x, pixel_y = target_pixel_y, time = animation_time, flags = ANIMATION_END_NOW)
	else
		occupant_client.pixel_x = target_pixel_x
		occupant_client.pixel_y = target_pixel_y

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_reset_occupant_camera(mob/occupant)
	if(!occupant?.client)
		return
	animate(occupant.client, pixel_x = 0, pixel_y = 0, time = 1, flags = ANIMATION_END_NOW)

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_can_occupy_pixel_position(test_px, test_py)
	var/collision_center_x = test_px + cy_collision_center_offset_x
	var/collision_center_y = test_py + cy_collision_center_offset_y
	if(cy_pixel_point_blocked(collision_center_x, collision_center_y))
		return FALSE
	if(cy_pixel_point_blocked(collision_center_x + cy_collision_half_width, collision_center_y + cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(collision_center_x + cy_collision_half_width, collision_center_y - cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(collision_center_x - cy_collision_half_width, collision_center_y + cy_collision_half_height))
		return FALSE
	if(cy_pixel_point_blocked(collision_center_x - cy_collision_half_width, collision_center_y - cy_collision_half_height))
		return FALSE
	return TRUE

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_pixel_point_blocked(test_px, test_py)
	var/tile = ICON_SIZE_X
	var/check_x = FLOOR(test_px / tile, 1) + 1
	var/check_y = FLOOR(test_py / tile, 1) + 1
	var/turf/check_turf = locate(check_x, check_y, z)
	if(!check_turf || check_turf.density)
		return TRUE

	for(var/atom/movable/movable_content as anything in check_turf)
		if(movable_content == src)
			continue
		if(movable_content.loc == src)
			continue
		if(istype(movable_content, /obj/machinery/camera))
			continue
		if(movable_content.density)
			return TRUE
	return FALSE

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_on_pixel_collision(direction)
	var/speed = cy_get_speed()
	if(speed < 1)
		return
	current_speed = speed
	handle_vehicle_collision(get_step(src, direction) || get_turf(src))

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_set_forward_from_dir(direction)
	switch(direction)
		if(EAST)
			cy_forward_x = 1
			cy_forward_y = 0
		if(WEST)
			cy_forward_x = -1
			cy_forward_y = 0
		if(SOUTH)
			cy_forward_x = 0
			cy_forward_y = -1
		else
			cy_forward_x = 0
			cy_forward_y = 1
	cy_normalize_forward_vector()

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_normalize_forward_vector()
	var/length = sqrt(cy_forward_x * cy_forward_x + cy_forward_y * cy_forward_y)
	if(length <= 0)
		cy_forward_x = 0
		cy_forward_y = 1
		return
	cy_forward_x /= length
	cy_forward_y /= length

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_forward_to_dir()
	var/x_value = cy_forward_x
	var/y_value = cy_forward_y
	if(y_value >= 0.45)
		if(x_value >= 0.45)
			return NORTHEAST
		if(x_value <= -0.45)
			return NORTHWEST
		return NORTH
	if(y_value <= -0.45)
		if(x_value >= 0.45)
			return SOUTHEAST
		if(x_value <= -0.45)
			return SOUTHWEST
		return SOUTH
	if(x_value >= 0)
		return EAST
	return WEST

/obj/vehicle/sealed/car/cyberpunk_test/proc/cy_velocity_to_dir()
	if(abs(cy_velocity_x) < 0.01 && abs(cy_velocity_y) < 0.01)
		return dir
	if(abs(cy_velocity_x) > abs(cy_velocity_y))
		return cy_velocity_x > 0 ? EAST : WEST
	return cy_velocity_y > 0 ? NORTH : SOUTH

/obj/vehicle/sealed/car/cyberpunk_test/proc/apply_pixel_motion(move_x, move_y)
	subpixel_x += move_x
	subpixel_y += move_y
	var/half_tile_x = ICON_SIZE_X * 0.5
	var/half_tile_y = ICON_SIZE_Y * 0.5
	var/tile_steps = 0
	var/stepped_tile = FALSE
	while(subpixel_x > half_tile_x && tile_steps < max_tile_steps_per_tick)
		if(!try_vehicle_pixel_step(EAST))
			subpixel_x = half_tile_x
			update_vehicle_pixel_visuals(FALSE)
			update_visual_dir()
			return
		subpixel_x -= ICON_SIZE_X
		tile_steps++
		stepped_tile = TRUE
	while(subpixel_x < -half_tile_x && tile_steps < max_tile_steps_per_tick)
		if(!try_vehicle_pixel_step(WEST))
			subpixel_x = -half_tile_x
			update_vehicle_pixel_visuals(FALSE)
			update_visual_dir()
			return
		subpixel_x += ICON_SIZE_X
		tile_steps++
		stepped_tile = TRUE
	while(subpixel_y > half_tile_y && tile_steps < max_tile_steps_per_tick)
		if(!try_vehicle_pixel_step(NORTH))
			subpixel_y = half_tile_y
			update_vehicle_pixel_visuals(FALSE)
			update_visual_dir()
			return
		subpixel_y -= ICON_SIZE_Y
		tile_steps++
		stepped_tile = TRUE
	while(subpixel_y < -half_tile_y && tile_steps < max_tile_steps_per_tick)
		if(!try_vehicle_pixel_step(SOUTH))
			subpixel_y = -half_tile_y
			update_vehicle_pixel_visuals(FALSE)
			update_visual_dir()
			return
		subpixel_y += ICON_SIZE_Y
		tile_steps++
		stepped_tile = TRUE
	subpixel_x = clamp(subpixel_x, -half_tile_x, half_tile_x)
	subpixel_y = clamp(subpixel_y, -half_tile_y, half_tile_y)
	update_vehicle_pixel_visuals(!stepped_tile)
	update_visual_dir()

/obj/vehicle/sealed/car/cyberpunk_test/proc/update_vehicle_pixel_visuals(animate_shift = TRUE)
	var/target_pixel_x = round(subpixel_x)
	var/target_pixel_y = round(subpixel_y)
	if(!animate_shift || pixel_animation_time <= 0)
		animate(src)
		pixel_x = target_pixel_x
		pixel_y = target_pixel_y
		return
	if(pixel_x == target_pixel_x && pixel_y == target_pixel_y)
		return
	animate(src, pixel_x = target_pixel_x, pixel_y = target_pixel_y, time = pixel_animation_time, flags = ANIMATION_PARALLEL)

/obj/vehicle/sealed/car/cyberpunk_test/proc/try_vehicle_pixel_step(step_dir)
	var/turf/next = get_step(src, step_dir)
	if(!istype(next))
		current_speed = 0
		return FALSE
	var/did_move = Move(next, step_dir)
	if(!did_move)
		handle_vehicle_collision(next)
		return FALSE
	return TRUE

/obj/vehicle/sealed/car/cyberpunk_test/proc/update_visual_dir()
	setDir(cy_forward_to_dir())

/obj/vehicle/sealed/car/cyberpunk_test/proc/consume_vehicle_fuel(amount)
	if(amount <= 0)
		return
	fuel = max(0, fuel - amount)
	if(fuel <= 0)
		current_speed = min(current_speed, base_brake * 0.2)

/obj/vehicle/sealed/car/cyberpunk_test/proc/handle_vehicle_collision(atom/collided)
	var/impact = max(5, current_speed * 0.18)
	current_speed *= 0.25
	damage_random_vehicle_part(impact)
	take_damage(impact, BRUTE, MELEE, TRUE)
	playsound(src, 'sound/vehicles/car_crash.ogg', 65, TRUE)
	visible_message(span_warning("[src] slams into [collided]!"))

/obj/vehicle/sealed/car/cyberpunk_test/Bump(atom/bumped)
	. = ..()
	if(current_speed > 12)
		handle_vehicle_collision(bumped)

/obj/vehicle/sealed/car/cyberpunk_test/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	damage_random_vehicle_part(damage_amount * 0.35)

/obj/vehicle/sealed/car/cyberpunk_test/proc/damage_random_vehicle_part(amount)
	if(!length(vehicle_parts) || amount <= 0)
		return
	var/datum/cyberpunk_vehicle_part/part = pick(vehicle_parts)
	part.take_damage(amount)
	if(part.category == "engine" && part.health_fraction() <= 0.05 && prob(amount * 2))
		visible_message(span_danger("[src]'s engine coughs and dies!"))
		fuel = min(fuel, 5)
		current_speed = 0

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_part_health_fraction(category)
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(part.category == category)
			return part.health_fraction()
	return 1

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_vehicle_part(category)
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(part.category == category)
			return part

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_vehicle_stat_multiplier(stat_key)
	var/result = 1
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		var/health_factor = 0.35 + part.health_fraction() * 0.65
		switch(stat_key)
			if("speed")
				result *= part.speed_multiplier * health_factor
			if("acceleration")
				result *= part.acceleration_multiplier * health_factor
			if("maneuver")
				result *= part.maneuver_multiplier * health_factor
			if("traction")
				result *= part.traction_multiplier * health_factor
			if("grip_switch")
				result *= part.grip_switch_multiplier * health_factor
			if("brake")
				result *= part.brake_multiplier * health_factor
			if("fuel")
				result *= part.fuel_multiplier
	return max(0.05, result)

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_vehicle_corporate_synergy_multiplier(mob/living/driver)
	if(!driver)
		return 1
	var/base_manufacturer = "Starlight"
	var/total_multiplier = driver.get_corporate_synergy_multiplier(base_manufacturer) * SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(base_manufacturer, list("starlight_route_registry", "starlight_phase_tuning"), 1, 1.05)
	var/counted_parts = 1
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(!part?.manufacturer)
			continue
		var/part_multiplier = driver.get_corporate_synergy_multiplier(part.manufacturer)
		part_multiplier *= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(part.manufacturer, list("starlight_route_registry", "starlight_phase_tuning", "ryaznov_power_tuning", "benn_self_analysis"), 1, 1.05)
		total_multiplier += part_multiplier
		counted_parts++
	return total_multiplier / max(1, counted_parts)

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_current_turf_grip_multiplier()
	var/turf/current_turf = get_turf(src)
	var/datum/cyberpunk_vehicle_part/drivetrain = get_vehicle_part("drivetrain")
	if(!current_turf || !drivetrain)
		return 1
	if(isspaceturf(current_turf) || is_space_or_openspace(current_turf))
		return drivetrain.space_grip
	if(istype(current_turf, /turf/open/floor))
		return drivetrain.floor_grip
	if(istype(current_turf, /turf/open/lava))
		return drivetrain.bad_grip
	if(istype(current_turf, /turf/open/misc/snow) || istype(current_turf, /turf/open/misc/ice) || istype(current_turf, /turf/open/misc/asteroid))
		return drivetrain.rough_grip
	return drivetrain.bad_grip

/obj/vehicle/sealed/car/cyberpunk_test/proc/install_vehicle_part(datum/cyberpunk_vehicle_part/new_part)
	if(!new_part)
		return FALSE
	for(var/i in 1 to length(vehicle_parts))
		var/datum/cyberpunk_vehicle_part/old_part = vehicle_parts[i]
		if(old_part.category != new_part.category)
			continue
		vehicle_parts[i] = new_part
		qdel(old_part)
		recalculate_vehicle_body()
		return TRUE
	vehicle_parts += new_part
	recalculate_vehicle_body()
	return TRUE

/obj/vehicle/sealed/car/cyberpunk_test/proc/recalculate_vehicle_body()
	var/datum/cyberpunk_vehicle_part/hull = get_vehicle_part("hull")
	if(!hull)
		return
	max_occupants = max(1, hull.passenger_capacity)
	max_mechanism_slots = max(0, hull.mechanism_capacity)
	max_integrity = max(50, hull.max_health + 80)
	if(atom_integrity <= 0)
		atom_integrity = max_integrity
	else
		atom_integrity = min(atom_integrity, max_integrity)
	color = get_vehicle_body_color(hull.category, hull.name)
	update_appearance(UPDATE_OVERLAYS)

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_vehicle_body_color(category, hull_name)
	if(findtext(hull_name, "bike"))
		return "#d0ecff"
	if(findtext(hull_name, "minivan"))
		return "#d8ffd6"
	if(findtext(hull_name, "bus"))
		return "#ffe8a3"
	if(findtext(hull_name, "truck"))
		return "#d7d7d7"
	if(findtext(hull_name, "APC") || findtext(hull_name, "tank"))
		return "#b8c2b0"
	return "#ffffff"

/obj/vehicle/sealed/car/cyberpunk_test/update_overlays()
	. = ..()
	if(panel_open)
		var/mutable_appearance/panel_overlay = mutable_appearance(icon, icon_state, ABOVE_MOB_LAYER)
		panel_overlay.color = "#66ccff"
		panel_overlay.alpha = 70
		. += panel_overlay
	if(drift_active)
		var/mutable_appearance/drift_overlay = mutable_appearance(icon, icon_state, ABOVE_MOB_LAYER)
		drift_overlay.color = "#ffcc66"
		drift_overlay.alpha = 80
		. += drift_overlay
	if(atom_integrity < max_integrity * 0.35)
		var/mutable_appearance/damage_overlay = mutable_appearance(icon, icon_state, ABOVE_MOB_LAYER)
		damage_overlay.color = "#ff3333"
		damage_overlay.alpha = 65
		. += damage_overlay

/obj/vehicle/sealed/car/cyberpunk_test/proc/refuel_vehicle(amount)
	if(amount <= 0 || fuel >= max_fuel)
		return FALSE
	fuel = min(max_fuel, fuel + amount)
	return TRUE

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_engine_resource_type()
	var/datum/cyberpunk_vehicle_part/engine = get_vehicle_part("engine")
	return engine?.resource_type || "energy"

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_primary_driver()
	var/list/drivers = return_drivers()
	if(!length(drivers))
		return null
	return drivers[1]

/obj/vehicle/sealed/car/cyberpunk_test/attack_hand(mob/living/user, list/modifiers)
	if(panel_open)
		ui_interact(user)
		return
	return ..()

/obj/vehicle/sealed/car/cyberpunk_test/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(panel_open && istype(tool, /obj/item/cyberpunk_vehicle_part))
		var/obj/item/cyberpunk_vehicle_part/part_item = tool
		if(!user.transferItemToLoc(part_item, src))
			return ITEM_INTERACT_BLOCKING
		var/datum/cyberpunk_vehicle_part/new_part = part_item.build_part_datum()
		install_vehicle_part(new_part)
		qdel(part_item)
		balloon_alert(user, "part installed")
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/stack/sheet/mineral/plasma))
		if(get_engine_resource_type() != "fuel")
			balloon_alert(user, "wrong resource")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/stack/plasma_stack = tool
		if(fuel >= max_fuel)
			balloon_alert(user, "tank full")
			return ITEM_INTERACT_BLOCKING
		if(!plasma_stack.use(1))
			return ITEM_INTERACT_BLOCKING
		refuel_vehicle(35)
		balloon_alert(user, "refueled")
		return ITEM_INTERACT_SUCCESS

	if(istype(tool, /obj/item/stock_parts/power_store))
		if(get_engine_resource_type() == "fuel")
			balloon_alert(user, "wrong resource")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/stock_parts/power_store/cell = tool
		if(fuel >= max_fuel)
			balloon_alert(user, "battery full")
			return ITEM_INTERACT_BLOCKING
		var/power_used = cell.use(1000, TRUE)
		if(power_used <= 0)
			balloon_alert(user, "cell empty")
			return ITEM_INTERACT_BLOCKING
		refuel_vehicle(power_used / 40)
		balloon_alert(user, "charged")
		return ITEM_INTERACT_SUCCESS

	return ..()

/obj/vehicle/sealed/car/cyberpunk_test/mouse_drop_receive(atom/dropping, mob/M, params)
	if(panel_open && istype(dropping, /obj/machinery) && istype(M))
		var/obj/machinery/machine = dropping
		if(length(installed_mechanisms) >= max_mechanism_slots)
			balloon_alert(M, "no slots")
			return
		if(machine.anchored)
			balloon_alert(M, "unanchor first")
			return
		if(!Adjacent(machine) || !Adjacent(M))
			return
		M.visible_message(span_notice("[M] starts mounting [machine] into [src]."), span_notice("You start mounting [machine]."))
		if(!do_after(M, 5 SECONDS, target = src))
			return
		installed_mechanisms += machine
		machine.forceMove(src)
		balloon_alert(M, "mechanism installed")
		return
	return ..()

/obj/vehicle/sealed/car/cyberpunk_test/screwdriver_act(mob/living/user, obj/item/tool)
	panel_open = !panel_open
	balloon_alert(user, panel_open ? "panel open" : "panel closed")
	playsound(src, 'sound/items/tools/screwdriver.ogg', 50, TRUE)
	update_appearance(UPDATE_OVERLAYS)
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/sealed/car/cyberpunk_test/wrench_act(mob/living/user, obj/item/tool)
	if(!panel_open)
		balloon_alert(user, "open panel first")
		return ITEM_INTERACT_BLOCKING
	var/datum/cyberpunk_vehicle_part/part = get_most_damaged_part()
	if(!part || part.health >= part.max_health)
		balloon_alert(user, "parts intact")
		return ITEM_INTERACT_BLOCKING
	var/repair_time = 4 SECONDS * user.get_cyberpunk_vehicle_repair_time_multiplier(src)
	user.visible_message(span_notice("[user] starts tuning [src]'s [part.name]."), span_notice("You start repairing [part.name]."))
	if(!do_after(user, repair_time, target = src))
		return ITEM_INTERACT_BLOCKING
	var/repaired = part.repair(user.get_cyberpunk_vehicle_repair_amount(src, 18))
	repair_damage(repaired * 0.5)
	balloon_alert(user, "part repaired")
	return ITEM_INTERACT_SUCCESS

/obj/vehicle/sealed/car/cyberpunk_test/proc/get_most_damaged_part()
	var/datum/cyberpunk_vehicle_part/worst_part
	var/worst_fraction = 2
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		if(part.health_fraction() < worst_fraction)
			worst_fraction = part.health_fraction()
			worst_part = part
	return worst_part

/obj/vehicle/sealed/car/cyberpunk_test/ui_state(mob/user)
	return GLOB.physical_state

/obj/vehicle/sealed/car/cyberpunk_test/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkVehicle", name)
		ui.open()

/obj/vehicle/sealed/car/cyberpunk_test/ui_data(mob/user)
	var/list/data = list()
	var/list/part_data = list()
	for(var/datum/cyberpunk_vehicle_part/part as anything in vehicle_parts)
		part_data += list(part.get_vehicle_part_ui_data())
	var/list/mechanism_data = list()
	for(var/i in 1 to length(installed_mechanisms))
		var/obj/machinery/machine = installed_mechanisms[i]
		if(QDELETED(machine))
			continue
		mechanism_data += list(list(
			"name" = machine.name,
			"index" = i,
			"integrity" = machine.get_integrity(),
			"maxIntegrity" = machine.max_integrity,
		))
	data["name"] = name
	data["panelOpen"] = panel_open
	data["integrity"] = atom_integrity
	data["maxIntegrity"] = max_integrity
	data["fuel"] = round(fuel, 0.1)
	data["maxFuel"] = max_fuel
	data["resourceType"] = get_engine_resource_type()
	data["speed"] = round(current_speed, 0.1)
	data["maxSpeed"] = round(base_max_speed, 0.1)
	data["surfaceGrip"] = round(get_current_turf_grip_multiplier(), 0.01)
	data["drift"] = drift_active
	data["occupants"] = occupant_amount()
	data["maxOccupants"] = max_occupants
	data["mechanisms"] = length(installed_mechanisms)
	data["mechanismSlots"] = max_mechanism_slots
	data["parts"] = part_data
	data["mechanismData"] = mechanism_data
	data["vectors"] = list(
		"control" = list("x" = round(control_x, 0.01), "y" = round(control_y, 0.01)),
		"directed" = list("x" = round(directed_x, 0.01), "y" = round(directed_y, 0.01)),
		"movement" = list("x" = round(movement_x, 0.01), "y" = round(movement_y, 0.01)),
		"grip" = list("x" = round(grip_x, 0.01), "y" = round(grip_y, 0.01)),
	)
	return data

/obj/vehicle/sealed/car/cyberpunk_test/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "ejectMechanism")
		var/index = text2num(params["index"])
		if(index < 1 || index > length(installed_mechanisms))
			return
		var/obj/machinery/machine = installed_mechanisms[index]
		installed_mechanisms.Cut(index, index + 1)
		if(!QDELETED(machine))
			machine.forceMove(drop_location())
		return TRUE
//CYBERPUNK BUILD - rebuild and delete before release

//CYBERPUNK BUILD - rebuild and delete before release
/client/proc/spawn_cyberpunk_test_vehicle()
	set name = "Create Cyberpunk Test Vehicle"
	set category = "Debug"
	if(!check_rights(R_SPAWN))
		return
	var/turf/spawn_turf = get_turf(mob)
	if(!spawn_turf)
		return
	var/list/options = list(
		"prototype car" = /obj/vehicle/sealed/car/cyberpunk_test,
		"microbike" = /obj/vehicle/sealed/car/cyberpunk_test/microbike,
		"bike" = /obj/vehicle/sealed/car/cyberpunk_test/bike,
		"large car" = /obj/vehicle/sealed/car/cyberpunk_test/large_car,
		"minivan" = /obj/vehicle/sealed/car/cyberpunk_test/minivan,
		"cargo minivan" = /obj/vehicle/sealed/car/cyberpunk_test/cargo_minivan,
		"bus" = /obj/vehicle/sealed/car/cyberpunk_test/bus,
		"cargo truck" = /obj/vehicle/sealed/car/cyberpunk_test/cargo_truck,
		"APC" = /obj/vehicle/sealed/car/cyberpunk_test/apc,
		"tank" = /obj/vehicle/sealed/car/cyberpunk_test/tank,
	)
	var/choice = tgui_input_list(mob, "Choose temporary vehicle type.", "Starlight vehicle", options)
	var/vehicle_type = options[choice] || /obj/vehicle/sealed/car/cyberpunk_test
	new vehicle_type(spawn_turf)
//CYBERPUNK BUILD - rebuild and delete before release
