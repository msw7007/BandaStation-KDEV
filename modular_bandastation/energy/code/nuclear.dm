/obj/machinery/power/cyberpunk_generator/nuclear_block
	name = "nuclear energy block"
	desc = "A compact uranium energy block with four coolant rods. Cold cores do not pay out; overheated broken cores fail violently."
	icon_state = "rtg"
	base_power_gen = 120 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_nuclear_block"
	circuit = /obj/item/circuitboard/machine/cyberpunk_nuclear_block
	max_integrity = 700
	max_safe_heat = T20C + 600
	critical_heat = T20C + 950
	var/fuel_units = 0
	var/max_fuel_units = 100
	var/reaction_rate = 1
	var/list/coolant_rods = list(100, 100, 100, 100)
	var/list/coolant_ratings = list(1, 1, 1, 1)
	var/list/coolant_depths = list(1, 1, 1, 1)
	var/meltdown_started = FALSE

/obj/machinery/power/cyberpunk_generator/nuclear_block/get_power_gen()
	if(heat < T20C + 180)
		return 0
	return base_power_gen * reaction_rate * get_condition_multiplier()

/obj/machinery/power/cyberpunk_generator/nuclear_block/process_generator(seconds_per_tick)
	if(fuel_units <= 0 || meltdown_started)
		return FALSE
	var/cooling = 0
	for(var/i in 1 to length(coolant_rods))
		var/rod_integrity = coolant_rods[i]
		var/rating = coolant_ratings[i] || 1
		var/depth = coolant_depths[i]
		if(rod_integrity <= 0 || depth <= 0)
			continue
		cooling += 24 * depth * rating
		coolant_rods[i] = max(0, rod_integrity - (0.035 * depth * seconds_per_tick / max(rating, 1)))
	heat += ((65 * reaction_rate) - cooling) * seconds_per_tick
	heat = max(T20C, heat)
	fuel_units = max(0, fuel_units - 0.02 * reaction_rate * seconds_per_tick)
	if(heat > critical_heat)
		take_damage(20 * seconds_per_tick, BURN, FIRE)
	if(atom_integrity <= max_integrity * 0.2 && heat > max_safe_heat)
		start_meltdown()
	return TRUE

/obj/machinery/power/cyberpunk_generator/nuclear_block/proc/start_meltdown()
	if(meltdown_started)
		return
	meltdown_started = TRUE
	active = FALSE
	visible_message(span_danger("[src] breaches containment!"))
	spawn_gas_cloud_radial(get_turf(src), /datum/gas_effect/radiation, 250, 5, heat)
	explosion(src, devastation_range = 2, heavy_impact_range = 4, light_impact_range = 7, flash_range = 8)
	qdel(src)

/obj/machinery/power/cyberpunk_generator/nuclear_block/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/stack/sheet/mineral/uranium))
		var/obj/item/stack/stack = item
		var/add_amount = min(max_fuel_units - fuel_units, stack.amount)
		if(add_amount <= 0)
			balloon_alert(user, "fuel full")
			return
		fuel_units += add_amount
		stack.use(add_amount)
		balloon_alert(user, "fuel loaded")
		return
	if(istype(item, /obj/item/cyberpunk_power_part/coolant_rod))
		var/obj/item/cyberpunk_power_part/coolant_rod/rod = item
		var/slot = get_coolant_replacement_slot()
		if(!slot)
			balloon_alert(user, "coolant full")
			return
		coolant_rods[slot] = rod.rod_integrity
		coolant_ratings[slot] = max(1, rod.part_rating)
		coolant_depths[slot] = 1
		qdel(rod)
		balloon_alert(user, "rod installed")
		return
	return ..()

/obj/machinery/power/cyberpunk_generator/nuclear_block/proc/get_coolant_replacement_slot()
	var/lowest_slot = 0
	var/lowest_integrity = INFINITY
	for(var/i in 1 to length(coolant_rods))
		var/integrity = coolant_rods[i]
		if(integrity <= 0)
			return i
		if(integrity < lowest_integrity)
			lowest_integrity = integrity
			lowest_slot = i
	if(lowest_integrity < 25)
		return lowest_slot
	return 0

/obj/machinery/power/cyberpunk_generator/nuclear_block/attack_hand_secondary(mob/user, list/modifiers)
	var/slot = tgui_input_number(user, "Coolant rod slot (1-[length(coolant_rods)]).", "Coolant Control", 1, length(coolant_rods), 1)
	if(isnull(slot) || QDELETED(src) || !user.Adjacent(src))
		return TRUE
	slot = clamp(round(slot), 1, length(coolant_rods))
	var/current_depth = coolant_depths[slot]
	var/new_depth = tgui_input_number(user, "Coolant rod #[slot] depth. 0 stops cooling and wear, 3 is maximum cooling and wear.", "Coolant Control", current_depth, 3, 0)
	if(isnull(new_depth) || QDELETED(src) || !user.Adjacent(src))
		return TRUE
	coolant_depths[slot] = clamp(round(new_depth), 0, 3)
	balloon_alert(user, "rod depth set")
	return TRUE

/obj/machinery/power/cyberpunk_generator/nuclear_block/crowbar_act(mob/living/user, obj/item/tool)
	var/slot = tgui_input_number(user, "Remove coolant rod slot (1-[length(coolant_rods)]).", "Coolant Removal", 1, length(coolant_rods), 1)
	if(isnull(slot) || QDELETED(src) || !user.Adjacent(src))
		return ITEM_INTERACT_SUCCESS
	slot = clamp(round(slot), 1, length(coolant_rods))
	if(coolant_rods[slot] <= 0)
		balloon_alert(user, "slot empty")
		return ITEM_INTERACT_SUCCESS
	var/obj/item/cyberpunk_power_part/coolant_rod/rod = new /obj/item/cyberpunk_power_part/coolant_rod(drop_location())
	rod.rod_integrity = coolant_rods[slot]
	rod.part_rating = max(1, coolant_ratings[slot])
	coolant_rods[slot] = 0
	coolant_ratings[slot] = 1
	coolant_depths[slot] = 0
	tool.play_tool_sound(src)
	balloon_alert(user, "rod removed")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/cyberpunk_generator/nuclear_block/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		var/list/rod_report = list()
		for(var/i in 1 to length(coolant_rods))
			rod_report += "#[i]: [round(coolant_rods[i])]% x[coolant_ratings[i] || 1] depth [coolant_depths[i]]"
		. += span_notice("Fuel: [round(fuel_units)]/[max_fuel_units]. Coolant rods: [rod_report.Join("; ")].")

/obj/machinery/power/cyberpunk_generator/nuclear_block/get_cyberpunk_power_ui_data(mob/user)
	var/list/rods = list()
	for(var/i in 1 to length(coolant_rods))
		rods += list(list(
			"index" = i,
			"integrity" = round(coolant_rods[i], 0.1),
			"integrity_ratio" = clamp(coolant_rods[i] / 100, 0, 1),
			"rating" = coolant_ratings[i] || 1,
			"depth" = coolant_depths[i],
		))
	return list(
		"kind" = "nuclear",
		"fuel" = round(fuel_units, 0.1),
		"max_fuel" = max_fuel_units,
		"fuel_ratio" = clamp(fuel_units / max(max_fuel_units, 1), 0, 1),
		"reaction_rate" = round(reaction_rate, 0.01),
		"meltdown_started" = meltdown_started,
		"rods" = rods,
	)

/obj/machinery/power/cyberpunk_generator/nuclear_block/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("set_reaction_rate")
			var/new_rate = text2num(params["value"])
			if(isnum(new_rate))
				reaction_rate = clamp(new_rate, 0.25, 3)
				return TRUE
		if("adjust_reaction_rate")
			var/delta = text2num(params["delta"])
			if(isnum(delta))
				reaction_rate = clamp(reaction_rate + delta, 0.25, 3)
				return TRUE
		if("set_rod_depth")
			var/slot = text2num(params["slot"])
			var/depth = text2num(params["depth"])
			if(isnum(slot) && isnum(depth))
				slot = clamp(round(slot), 1, length(coolant_rods))
				coolant_depths[slot] = clamp(round(depth), 0, 3)
				return TRUE
		if("scram")
			reaction_rate = 0.25
			for(var/i in 1 to length(coolant_depths))
				coolant_depths[i] = 3
			set_active(FALSE)
			return TRUE
	return FALSE
