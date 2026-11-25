/obj/machinery/power/nuclear_power_block/screwdriver_act(mob/living/user, obj/item/tool)
	if(service_busy)
		return ITEM_INTERACT_BLOCKING
	tool.play_tool_sound(src)
	panel_open = !panel_open
	balloon_alert(user, panel_open ? "panel open" : "panel closed")
	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/nuclear_power_block/wrench_act(mob/living/user, obj/item/tool)
	if(service_busy || !can_wrench_service(user, tool))
		return ITEM_INTERACT_BLOCKING
	var/static/list/options
	if(!options)
		var/icon/main_turbine = icon('modular_bandastation/nuclear_power_block/icons/reactor.dmi', "reactor")
		main_turbine.Crop(1, 29, 32, 60)
		var/icon/reserve_turbine = icon('modular_bandastation/nuclear_power_block/icons/reactor.dmi', "reactor")
		reserve_turbine.Crop(65, 29, 96, 60)
		options = list(
			"Raise rods" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_up"),
			"Lower rods" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_down"),
			"Repair main turbine" = main_turbine,
			"Repair reserve turbine" = reserve_turbine,
		)
	var/choice = show_radial_menu(user, src, options, custom_check = CALLBACK(src, PROC_REF(can_wrench_service), user, tool), tooltips = TRUE, radial_menu_offset = list(32, 32))
	if(!choice || service_busy || !can_wrench_service(user, tool))
		return ITEM_INTERACT_BLOCKING
	switch(choice)
		if("Raise rods")
			rod_insertion = max(0, rod_insertion - NUCLEAR_POWER_BLOCK_ROD_STEP)
		if("Lower rods")
			rod_insertion = min(100, rod_insertion + NUCLEAR_POWER_BLOCK_ROD_STEP)
		if("Repair main turbine")
			return repair_turbine(user, tool, 1)
		if("Repair reserve turbine")
			return repair_turbine(user, tool, 2)
	tool.play_tool_sound(src)
	return ITEM_INTERACT_SUCCESS

/// Shared eligibility for the wrench menu and every tick of its timed repair.
/obj/machinery/power/nuclear_power_block/proc/can_wrench_service(mob/living/user, obj/item/tool)
	return !QDELETED(src) && !QDELETED(user) && !QDELETED(tool) && panel_open && Adjacent(user) && !user.incapacitated && !HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) && user.get_active_held_item() == tool && tool.tool_behaviour == TOOL_WRENCH

/// One risk roll uses actual rotor speed after the full tool action, not its requested speed.
/obj/machinery/power/nuclear_power_block/proc/repair_turbine(mob/living/user, obj/item/tool, index)
	if(service_busy || !can_wrench_service(user, tool) || !ISINTEGER(index) || index < 1 || index > length(turbines))
		return ITEM_INTERACT_BLOCKING
	var/datum/nuclear_power_turbine/turbine = turbines[index]
	if(turbine.condition >= 100 || turbine.tier <= 0)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/bodypart/working_arm = user.get_active_hand()
	service_busy = TRUE
	var/finished = tool.use_tool(src, user, NUCLEAR_POWER_BLOCK_TURBINE_REPAIR_TIME, volume = 50, extra_checks = CALLBACK(src, PROC_REF(can_wrench_service), user, tool))
	if(QDELETED(src))
		return ITEM_INTERACT_BLOCKING
	service_busy = FALSE
	if(!finished || !can_wrench_service(user, tool) || turbines[index] != turbine || turbine.tier <= 0 || user.get_active_hand() != working_arm)
		return ITEM_INTERACT_BLOCKING
	if(prob(clamp(turbine.rpm, 0, 100)))
		turbine.condition = max(0, turbine.condition - NUCLEAR_POWER_BLOCK_REPAIR_DAMAGE)
		update_indicator_appearance()
		user.apply_damage(NUCLEAR_POWER_BLOCK_REPAIR_DAMAGE, BRUTE, working_arm, wound_bonus = CANT_WOUND)
		if(iscarbon(user) && working_arm)
			var/mob/living/carbon/technician = user
			technician.cause_wound_of_type_and_severity(WOUND_SLASH, working_arm, WOUND_SEVERITY_MODERATE, wound_source = "reactor turbine")
		user.visible_message(span_danger("[user]'s hand is caught by the spinning [turbine.name] turbine!"), span_userdanger("The spinning rotor catches your hand and the repair fails!"))
		return ITEM_INTERACT_BLOCKING
	turbine.condition = min(100, turbine.condition + NUCLEAR_POWER_BLOCK_REPAIR_AMOUNT)
	update_indicator_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/machinery/power/nuclear_power_block/crowbar_act(mob/living/user, obj/item/tool)
	if(service_busy)
		return ITEM_INTERACT_BLOCKING
	if(lid)
		tool.play_tool_sound(src)
		release_lid(user)
		return ITEM_INTERACT_SUCCESS
	if(reaction_rate > 0 || target_reaction_rate > 0 || chamber_temperature > NUCLEAR_POWER_BLOCK_SAFE_SERVICE_TEMPERATURE)
		balloon_alert(user, "core is not safe to dismantle!")
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/power/nuclear_power_block/welder_act(mob/living/user, obj/item/tool)
	if(!panel_open || lid || !replacement_lid || service_busy || !tool.tool_start_check(user, amount = 1))
		return ITEM_INTERACT_BLOCKING
	var/obj/item/nuclear_power_block_lid/replacement = replacement_lid
	service_busy = TRUE
	welding_lid = TRUE
	var/finished = tool.use_tool(src, user, NUCLEAR_POWER_BLOCK_LID_WELD_TIME, amount = 1, volume = 50)
	if(QDELETED(src))
		return ITEM_INTERACT_BLOCKING
	welding_lid = FALSE
	service_busy = FALSE
	if(!finished || QDELETED(user) || QDELETED(tool) || !user.is_holding(tool) || !Adjacent(user) || user.incapacitated || !panel_open || lid || replacement_lid != replacement || QDELETED(replacement) || replacement.loc != src || replacement.broken)
		return ITEM_INTERACT_BLOCKING
	replacement_lid = null
	lid = replacement
	update_appearance()
	return ITEM_INTERACT_SUCCESS

/// Select one of the two owned turbines without accepting arbitrary references from a client.
/obj/machinery/power/nuclear_power_block/proc/choose_turbine(mob/user)
	var/list/options = list("Main", "Reserve")
	var/choice = input(user, "Select turbine", name) as null|anything in options
	if(QDELETED(src) || QDELETED(user) || !(choice in options) || !Adjacent(user) || user.incapacitated || !panel_open)
		return null
	return turbines[choice == "Main" ? 1 : 2]

/obj/machinery/power/nuclear_power_block/attack_hand_secondary(mob/living/user, list/modifiers)
	if(!panel_open || user.get_active_held_item() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return ..()
	var/datum/nuclear_power_turbine/turbine = choose_turbine(user)
	if(!turbine || turbine.manual_user?.resolve() || user.get_active_held_item() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	turbine.manual_user = WEAKREF(user)
	while(!QDELETED(src) && !QDELETED(user) && user.client && panel_open && Adjacent(user) && !user.incapacitated && !HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) && !user.get_active_held_item())
		if(!do_after(user, 2 SECONDS, src))
			break
	if(!QDELETED(turbine))
		turbine.manual_user = null
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/power/nuclear_power_block/item_interaction(mob/living/user, obj/item/item, list/modifiers)
	if(!panel_open || service_busy)
		return NONE
	if(istype(item, /obj/item/stack/sheet/mineral/uranium))
		if(fuel > 0)
			balloon_alert(user, "fuel chamber occupied!")
			return ITEM_INTERACT_BLOCKING
		var/obj/item/stack/sheet/mineral/uranium/sheet = item
		if(sheet.use(1))
			fuel = 1
		return ITEM_INTERACT_SUCCESS
	if(istype(item, /obj/item/nuclear_power_block_lid))
		var/obj/item/nuclear_power_block_lid/new_lid = item
		if(lid || replacement_lid || new_lid.broken || new_lid.released_from)
			return ITEM_INTERACT_BLOCKING
		if(user.transferItemToLoc(new_lid, src))
			replacement_lid = new_lid
		return ITEM_INTERACT_SUCCESS
	if(istype(item, /obj/item/reagent_containers/cup/beaker))
		if(!Adjacent(user) || user.incapacitated || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || !user.is_holding(item))
			return ITEM_INTERACT_BLOCKING
		var/slot = coolant_beakers.Find(null) || 1
		var/obj/item/reagent_containers/cup/beaker/old_beaker = coolant_beakers[slot]
		if(!user.transferItemToLoc(item, src))
			return ITEM_INTERACT_BLOCKING
		component_parts += item
		coolant_beakers[slot] = item
		if(old_beaker)
			component_parts -= old_beaker
			old_beaker.forceMove(drop_location())
			user.put_in_hands(old_beaker)
		RefreshParts()
		return ITEM_INTERACT_SUCCESS
	if(istype(item, /obj/item/stock_parts/capacitor) || istype(item, /obj/item/stock_parts/servo))
		var/datum/stock_part/upgrade = GLOB.stock_part_datums_per_object[item.type]
		if(!upgrade)
			return ITEM_INTERACT_BLOCKING
		for(var/datum/stock_part/installed in component_parts)
			if(installed.physical_object_base_type != upgrade.physical_object_base_type)
				continue
			if(installed.tier >= upgrade.tier || !user.transferItemToLoc(item, src))
				return ITEM_INTERACT_BLOCKING
			component_parts -= installed
			component_parts += upgrade
			var/obj/item/old_part = new installed.physical_object_type(drop_location())
			user.put_in_hands(old_part)
			qdel(item)
			RefreshParts()
			return ITEM_INTERACT_SUCCESS
	return NONE

/// Do not allow remote RPED operations to bypass the open physical service hatch.
/obj/machinery/power/nuclear_power_block/exchange_parts(mob/user, obj/item/storage/part_replacer/replacer_tool)
	if(!panel_open || service_busy || !Adjacent(user))
		return FALSE
	return ..()

/// Remove one actual vessel without redistributing or discarding its liquid.
/obj/machinery/power/nuclear_power_block/proc/eject_beaker(mob/living/user, index)
	if(!panel_open || service_busy || !Adjacent(user) || user.incapacitated || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return FALSE
	if(!ISINTEGER(index) || index < 1 || index > length(coolant_beakers))
		return FALSE
	var/obj/item/reagent_containers/cup/beaker/removed = coolant_beakers[index]
	if(!removed)
		return FALSE
	coolant_beakers[index] = null
	component_parts -= removed
	removed.forceMove(drop_location())
	user.put_in_hands(removed)
	RefreshParts()
	return TRUE
