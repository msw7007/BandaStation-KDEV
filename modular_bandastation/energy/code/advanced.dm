/obj/machinery/power/cyberpunk_generator/cold_fusion
	name = "cold fusion collider"
	desc = "An advanced Ryaznov reactor. It produces large power, but unstable operation can seed anomalies."
	icon_state = "rtg"
	base_power_gen = 180 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_cold_fusion"
	circuit = /obj/item/circuitboard/machine/cyberpunk_cold_fusion
	var/instability = 0

/obj/machinery/power/cyberpunk_generator/cold_fusion/process_generator(seconds_per_tick)
	instability = max(0, instability + rand(-1, 3) * seconds_per_tick)
	heat += instability * 0.3
	if(instability > 100 && prob(5))
		spawn_gas_cloud(get_turf(src), /datum/gas_effect/pressure, 50, T20C)
		instability *= 0.5
	return TRUE

/obj/machinery/power/cyberpunk_generator/cold_fusion/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "cold_fusion",
		"instability" = round(instability, 0.1),
		"instability_ratio" = clamp(instability / 150, 0, 1),
	)

/obj/machinery/power/cyberpunk_generator/cold_fusion/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("stabilize")
			instability = max(0, instability - 20)
			heat += 10
			return TRUE
	return FALSE

/obj/machinery/power/cyberpunk_generator/bioreactor
	name = "bioreactor"
	desc = "A Benn reactor that disassembles organic mass into energy."
	icon_state = "rtg"
	base_power_gen = 60 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_BENN
	cyberpunk_required_technology_id = "benn_bioreactor"
	circuit = /obj/item/circuitboard/machine/cyberpunk_bioreactor
	var/biomass = 0
	var/max_biomass = 500

/obj/machinery/power/cyberpunk_generator/bioreactor/get_power_gen()
	return base_power_gen * clamp(biomass / max_biomass, 0, 2) * get_condition_multiplier()

/obj/machinery/power/cyberpunk_generator/bioreactor/process_generator(seconds_per_tick)
	if(biomass <= 0)
		return FALSE
	biomass = max(0, biomass - 1.5 * seconds_per_tick)
	if(prob(2))
		spawn_gas_cloud(get_turf(src), /datum/gas_effect/biohazard, 20, T20C + 40)
	return TRUE

/obj/machinery/power/cyberpunk_generator/bioreactor/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/food))
		biomass = min(max_biomass, biomass + 25)
		qdel(item)
		balloon_alert(user, "biomass loaded")
		return
	if(istype(item, /obj/item/organ))
		biomass = min(max_biomass, biomass + 40)
		qdel(item)
		balloon_alert(user, "organ loaded")
		return
	if(istype(item, /obj/item/bodypart))
		biomass = min(max_biomass, biomass + 70)
		qdel(item)
		balloon_alert(user, "biomass loaded")
		return
	return ..()

/obj/machinery/power/cyberpunk_generator/bioreactor/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "bioreactor",
		"biomass" = round(biomass, 0.1),
		"max_biomass" = max_biomass,
		"biomass_ratio" = clamp(biomass / max(max_biomass, 1), 0, 1),
	)

/obj/machinery/power/cyberpunk_generator/bioreactor/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("purge_biomass")
			biomass = 0
			set_active(FALSE)
			return TRUE
	return FALSE

/obj/machinery/power/cyberpunk_generator/energy_portal
	name = "energy portal"
	desc = "A Starlight crystal portal. Emitters keep it productive and contained; instability draws hostile attention."
	icon_state = "rtg"
	base_power_gen = 220 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_energy_portal"
	circuit = /obj/item/circuitboard/machine/cyberpunk_energy_portal
	var/portal_size = 1
	var/containment = 100

/obj/machinery/power/cyberpunk_generator/energy_portal/process_generator(seconds_per_tick)
	portal_size += 0.01 * seconds_per_tick
	containment = max(0, containment - portal_size * 0.03 * seconds_per_tick)
	heat += portal_size * seconds_per_tick
	if(containment <= 0 && prob(4))
		spawn_gas_cloud_radial(get_turf(src), /datum/gas_effect/pressure, 120, 3, T20C)
		containment = 50
	return TRUE

/obj/machinery/power/cyberpunk_generator/energy_portal/get_power_gen()
	return base_power_gen * clamp(portal_size, 1, 4) * get_condition_multiplier()

/obj/machinery/power/cyberpunk_generator/energy_portal/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "energy_portal",
		"portal_size" = round(portal_size, 0.01),
		"portal_ratio" = clamp(portal_size / 4, 0, 1),
		"containment" = round(containment, 0.1),
		"containment_ratio" = clamp(containment / 100, 0, 1),
	)

/obj/machinery/power/cyberpunk_generator/energy_portal/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("tighten_containment")
			containment = min(100, containment + 20)
			heat += 15
			return TRUE
	return FALSE
