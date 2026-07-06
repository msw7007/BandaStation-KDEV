// Shared base for CP13 replacement power sources. These are normal TG power
// machines: if they are connected to a cable/terminal, they add power to the net.

/obj/machinery/power/cyberpunk_generator
	name = "city power generator"
	desc = "A modular city-grade power generator."
	icon = 'icons/obj/machines/engine/other.dmi'
	icon_state = "rtg"
	base_icon_state = "rtg"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	max_integrity = 350
	var/active = FALSE
	var/base_power_gen = 10 KILO WATTS
	var/power_output = 1
	var/heat = T20C
	var/max_safe_heat = T20C + 250
	var/critical_heat = T20C + 500
	var/wear = 0
	var/max_wear = 100
	var/corp_manufacturer = CYBERPUNK_CORP_RYAZNOV
	var/cyberpunk_required_technology_id = null

/obj/machinery/power/cyberpunk_generator/Initialize(mapload)
	. = ..()
	connect_to_network()
	if(active)
		START_PROCESSING(SSmachines, src)

/obj/machinery/power/cyberpunk_generator/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/power/cyberpunk_generator/should_have_node()
	return anchored

/obj/machinery/power/cyberpunk_generator/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return
	if(anchorvalue)
		connect_to_network()
	else
		disconnect_from_network()

/obj/machinery/power/cyberpunk_generator/proc/can_generate()
	return anchored && !machine_stat && powernet && atom_integrity > 0

/obj/machinery/power/cyberpunk_generator/proc/get_power_gen()
	return max(0, base_power_gen * power_output * get_condition_multiplier() * get_cyberpunk_machine_generator_output_multiplier())

/obj/machinery/power/cyberpunk_generator/proc/get_condition_multiplier()
	var/heat_factor = heat > max_safe_heat ? clamp(1 - ((heat - max_safe_heat) / max(max_safe_heat, 1)), 0.25, 1) : 1
	var/wear_factor = clamp(1 - (wear / max(max_wear * 1.5, 1)), 0.25, 1)
	return heat_factor * wear_factor

/obj/machinery/power/cyberpunk_generator/proc/process_generator(seconds_per_tick)
	return TRUE

/obj/machinery/power/cyberpunk_generator/proc/idle_cooling(seconds_per_tick)
	heat = max(T20C, heat - 3 * seconds_per_tick)

/obj/machinery/power/cyberpunk_generator/process(seconds_per_tick)
	seconds_per_tick ||= 1
	if(!active)
		idle_cooling(seconds_per_tick)
		if(heat <= T20C)
			STOP_PROCESSING(SSmachines, src)
		return
	if(!can_generate() || !process_generator(seconds_per_tick))
		set_active(FALSE)
		return
	var/generated = get_power_gen()
	if(generated > 0)
		add_avail(power_to_energy(generated))
	if(heat > critical_heat)
		take_damage(10 * seconds_per_tick, BURN, FIRE)
	if(atom_integrity <= 0)
		set_active(FALSE)

/obj/machinery/power/cyberpunk_generator/proc/set_active(new_active)
	if(active == new_active)
		return
	active = new_active
	update_appearance()
	if(active)
		START_PROCESSING(SSmachines, src)
	else if(heat <= T20C)
		STOP_PROCESSING(SSmachines, src)

/obj/machinery/power/cyberpunk_generator/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/machinery/power/cyberpunk_generator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkPowerSource", name)
		ui.open()

/obj/machinery/power/cyberpunk_generator/ui_data(mob/user)
	var/list/data = list()
	data["name"] = name
	data["kind"] = "generator"
	data["active"] = active
	data["anchored"] = anchored
	data["connected"] = !isnull(powernet)
	data["can_generate"] = can_generate()
	data["output"] = display_power(get_power_gen(), convert = FALSE)
	data["base_output"] = display_power(base_power_gen, convert = FALSE)
	data["power_output"] = round(power_output, 0.01)
	data["heat"] = round(heat - T0C, 0.1)
	data["heat_ratio"] = clamp((heat - T20C) / max(critical_heat - T20C, 1), 0, 1)
	data["safe_heat"] = round(max_safe_heat - T0C, 0.1)
	data["critical_heat"] = round(critical_heat - T0C, 0.1)
	data["wear"] = round(wear, 0.1)
	data["wear_ratio"] = clamp(wear / max(max_wear, 1), 0, 1)
	data["max_wear"] = max_wear
	data["integrity"] = round(atom_integrity || 0, 0.1)
	data["max_integrity"] = max_integrity
	data["integrity_ratio"] = clamp((atom_integrity || 0) / max(max_integrity, 1), 0, 1)
	data["corp"] = corp_manufacturer
	data["technology"] = cyberpunk_required_technology_id
	data["special"] = get_cyberpunk_power_ui_data(user)
	return data

/obj/machinery/power/cyberpunk_generator/proc/get_cyberpunk_power_ui_data(mob/user)
	return list()

/obj/machinery/power/cyberpunk_generator/proc/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	return FALSE

/obj/machinery/power/cyberpunk_generator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			set_active(!active)
			. = TRUE
		if("set_output")
			var/new_output = text2num(params["value"])
			if(isnum(new_output))
				power_output = clamp(new_output, 0.25, 4)
				. = TRUE
		if("adjust_output")
			var/delta = text2num(params["delta"])
			if(isnum(delta))
				power_output = clamp(power_output + delta, 0.25, 4)
				. = TRUE
	if(.)
		return
	. = handle_cyberpunk_power_ui_act(action, params, ui.user)

/obj/machinery/power/cyberpunk_generator/wrench_act(mob/living/user, obj/item/tool)
	var/wrench_time = 2 SECONDS * user.get_cyberpunk_structure_time_multiplier(src, anchored ? "unanchor" : "anchor")
	if(!tool.use_tool(src, user, wrench_time))
		return ITEM_INTERACT_BLOCKING
	set_anchored(!anchored)
	tool.play_tool_sound(src)
	balloon_alert(user, anchored ? "anchored" : "unanchored")
	user.reward_cyberpunk_structure_anchor_experience(src)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/cyberpunk_generator/cyberpunk_handle_wrong_function(mob/living/user)
	balloon_alert(user, "fuel misfire")
	heat += 50
	wear = min(max_wear * 2, wear + 3)
	do_sparks(3, TRUE, src)
	apply_cyberpunk_machine_wear(3, "use", user)
	if(prob(50))
		set_active(FALSE)
	return TRUE

/obj/machinery/power/cyberpunk_generator/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Output: <b>[display_power(get_power_gen(), convert = FALSE)]</b>.")
		. += span_notice("Heat: [round(heat - T0C)]C. Wear: [round(wear)]/[max_wear].")
		. += span_notice("It is [active ? "running" : "idle"].")
