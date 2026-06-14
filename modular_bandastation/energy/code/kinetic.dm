/obj/machinery/power/cyberpunk_generator/kinetic
	name = "kinetic reactor"
	desc = "A wheel-shaft-generator assembly. It needs a spin-up, then produces power from inertia while wearing its shaft and heating the motor."
	icon_state = "rtg"
	base_power_gen = 18 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_kinetic_reactor"
	circuit = /obj/item/circuitboard/machine/cyberpunk_kinetic_reactor
	var/wheels = 1
	var/max_wheels = 4
	var/shaft_rating = 1
	var/motor_rating = 1
	var/rotation = 0
	var/max_rotation = 100

/obj/machinery/power/cyberpunk_generator/kinetic/get_power_gen()
	return base_power_gen * wheels * motor_rating * clamp(rotation / max_rotation, 0, 1) * get_condition_multiplier()

/obj/machinery/power/cyberpunk_generator/kinetic/process_generator(seconds_per_tick)
	if(rotation <= 0)
		return FALSE
	var/load = max(wheels / max(shaft_rating, 1), 0.1)
	rotation = max(0, rotation - (0.35 * seconds_per_tick * load))
	wear = min(max_wear * 2, wear + 0.03 * seconds_per_tick * load)
	heat += (1.8 * seconds_per_tick * wheels * motor_rating)
	apply_cloud_cooling(seconds_per_tick)
	return rotation > 0

/obj/machinery/power/cyberpunk_generator/kinetic/proc/spin_up(amount = 25)
	rotation = clamp(rotation + amount, 0, max_rotation)
	set_active(TRUE)

/obj/machinery/power/cyberpunk_generator/kinetic/proc/apply_cloud_cooling(seconds_per_tick)
	for(var/obj/effect/gas_cloud/cloud in get_turf(src))
		if(!cloud.effect || cloud.amount <= 0)
			continue
		if(istype(cloud.effect, /datum/gas_effect/freeze))
			heat = max(T20C, heat - cloud.amount * seconds_per_tick)

/obj/machinery/power/cyberpunk_generator/kinetic/attack_hand(mob/user, list/modifiers)
	return ..()

/obj/machinery/power/cyberpunk_generator/kinetic/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/cyberpunk_power_part/kinetic_wheel))
		if(wheels >= max_wheels)
			balloon_alert(user, "wheel train full")
			return
		wheels++
		qdel(item)
		balloon_alert(user, "wheel installed")
		return
	if(istype(item, /obj/item/cyberpunk_power_part/kinetic_shaft))
		var/obj/item/cyberpunk_power_part/part = item
		shaft_rating = max(1, part.part_rating)
		qdel(item)
		balloon_alert(user, "shaft replaced")
		return
	if(istype(item, /obj/item/cyberpunk_power_part/kinetic_motor))
		var/obj/item/cyberpunk_power_part/part = item
		motor_rating = max(1, part.part_rating)
		qdel(item)
		balloon_alert(user, "motor replaced")
		return
	return ..()

/obj/machinery/power/cyberpunk_generator/kinetic/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Kinetic train: [wheels] wheel(s), shaft rating [shaft_rating], motor rating [motor_rating], rotation [round(rotation)]/[max_rotation].")

/obj/machinery/power/cyberpunk_generator/kinetic/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "kinetic",
		"wheels" = wheels,
		"max_wheels" = max_wheels,
		"shaft_rating" = shaft_rating,
		"motor_rating" = motor_rating,
		"rotation" = round(rotation, 0.1),
		"rotation_ratio" = clamp(rotation / max(max_rotation, 1), 0, 1),
		"max_rotation" = max_rotation,
	)

/obj/machinery/power/cyberpunk_generator/kinetic/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("spin_up")
			spin_up(15)
			balloon_alert(user, "spun up")
			return TRUE
	return FALSE

/obj/machinery/power/cyberpunk_dynamo
	name = "emergency dynamo"
	desc = "A manual emergency generator. Cranking it gives a small grid pulse and can spin up adjacent kinetic reactors."
	icon = 'icons/obj/machines/engine/other.dmi'
	icon_state = "portgen0_0"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cyberpunk_dynamo
	var/pulse_power = 4 KILO WATTS

/obj/machinery/power/cyberpunk_dynamo/Initialize(mapload)
	. = ..()
	connect_to_network()

/obj/machinery/power/cyberpunk_dynamo/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(powernet)
		add_avail(power_to_energy(pulse_power))
	for(var/obj/machinery/power/cyberpunk_generator/kinetic/reactor in orange(1, src))
		reactor.spin_up(20)
	balloon_alert(user, "cranked")
	return TRUE
