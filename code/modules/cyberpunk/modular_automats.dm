// Modular automated machine shell. UI and concrete catalogues are intentionally deferred.

/obj/machinery/cy_modular_automat
	name = "modular automat"
	desc = "A modular automated machine shell. Its behavior is determined by installed machinery modules."
	icon = 'icons/mob/rideables/vehicles.dmi'
	icon_state = "clowncar"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	var/cy_market_value = 500
	var/list/cy_default_machine_module_types
	var/cy_automat_can_sell = FALSE
	var/cy_automat_can_network = FALSE
	var/cy_automat_can_store = FALSE
	var/cy_automat_can_take_payment = FALSE
	var/cy_automat_speed_mult = 1
	var/cy_automat_power_mult = 1
	var/cy_automat_quality_bonus = 0
	var/cy_automat_reliability_bonus = 0
	var/cy_automat_output_bonus = 0
	var/cy_automat_heat_bonus = 0
	var/cy_automat_illegal = FALSE

/obj/machinery/cy_modular_automat/Initialize(mapload)
	. = ..()
	cy_machine_modules = list()
	if(length(cy_default_machine_module_types))
		for(var/module_type in cy_default_machine_module_types)
			var/obj/item/cy_machinery_module/module = new module_type(src)
			cy_install_machine_module(module, null, FALSE)
	cy_rebuild_machine_modules()

/obj/machinery/cy_modular_automat/Destroy()
	QDEL_LIST(cy_machine_modules)
	cy_machine_modules = null
	return ..()

/obj/machinery/cy_modular_automat/examine(mob/user)
	. = ..()
	. += span_notice("Modules: [length(cy_machine_modules)]. Sales: [cy_automat_can_sell ? "yes" : "no"], payment: [cy_automat_can_take_payment ? "yes" : "no"], network: [cy_automat_can_network ? "yes" : "no"], storage: [cy_automat_can_store ? "yes" : "no"].")
	. += span_notice("Profile: speed x[cy_automat_speed_mult], power x[cy_automat_power_mult], quality +[cy_automat_quality_bonus], output +[cy_automat_output_bonus], reliability +[cy_automat_reliability_bonus].")
	if(cy_automat_illegal)
		. += span_warning("At least one installed module is illegal or black-market only.")

/obj/machinery/cy_modular_automat/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/cy_machinery_module))
		var/obj/item/cy_machinery_module/module = tool
		if(cy_install_machine_module(module, user))
			return ITEM_INTERACT_SUCCESS
	return ..()

/obj/machinery/cy_modular_automat/cy_install_machine_module(obj/item/cy_machinery_module/module, mob/user, messages = TRUE)
	if(!istype(module))
		return FALSE
	if(!..(module, user, messages))
		return FALSE
	cy_rebuild_machine_modules()
	update_appearance(UPDATE_OVERLAYS)
	if(messages && user)
		user.balloon_alert(user, "module installed")
	return TRUE

/obj/machinery/cy_modular_automat/proc/cy_rebuild_machine_modules()
	cy_automat_can_sell = FALSE
	cy_automat_can_network = FALSE
	cy_automat_can_store = FALSE
	cy_automat_can_take_payment = FALSE
	cy_automat_speed_mult = 1
	cy_automat_power_mult = 1
	cy_automat_quality_bonus = 0
	cy_automat_reliability_bonus = 0
	cy_automat_output_bonus = 0
	cy_automat_heat_bonus = 0
	cy_automat_illegal = FALSE
	for(var/obj/item/cy_machinery_module/module as anything in cy_machine_modules)
		cy_automat_can_sell ||= module.cy_machine_enables_sales
		cy_automat_can_network ||= module.cy_machine_enables_network
		cy_automat_can_store ||= module.cy_machine_enables_storage
		cy_automat_can_take_payment ||= module.cy_machine_enables_payment
		cy_automat_speed_mult *= module.cy_machine_speed_mult
		cy_automat_power_mult *= module.cy_machine_power_mult
		cy_automat_quality_bonus += module.cy_machine_quality_bonus
		cy_automat_reliability_bonus += module.cy_machine_reliability_bonus
		cy_automat_output_bonus += module.cy_machine_output_bonus
		cy_automat_heat_bonus += module.cy_machine_heat_bonus
		cy_automat_illegal ||= module.cy_machine_illegal || module.cy_black_market_only
	update_mode_power_usage(IDLE_POWER_USE, initial(idle_power_usage) * cy_automat_power_mult)
	update_mode_power_usage(ACTIVE_POWER_USE, initial(active_power_usage) * cy_automat_power_mult)
	if(cy_automat_can_network)
		cy_net_enabled = TRUE
		cy_net_data = max(cy_net_data, 10)
		cy_netspace_register_deferred(CY_NET_NODE_VENDING, CY_NET_SECURITY_BASIC)
	else if(cy_netspace_node)
		cy_netspace_unregister()

/obj/machinery/cy_modular_automat/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	var/list/options = list("inspect modules")
	if(cy_automat_can_network)
		options += "connect to netspace"
		options += "network audit"
	if(cy_automat_can_sell)
		options += "sales mode"
	var/choice = tgui_input_list(user, "Automat", name, options)
	switch(choice)
		if("connect to netspace")
			if(!cy_netspace_node)
				cy_netspace_register(CY_NET_NODE_VENDING, CY_NET_SECURITY_BASIC)
			cy_enter_netspace(user, src, CY_NET_AVATAR_ACTIVE)
		if("network audit")
			to_chat(user, span_notice(cy_get_netspace_status(user)))
		if("sales mode")
			to_chat(user, span_notice("Sales UI is provided by installed sale/storage/payment modules."))
		else
			examine(user)
	return TRUE

/obj/machinery/cy_modular_automat/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	var/list/actions = list("status")
	if(cy_automat_can_network)
		actions += "disable_network"
	if(cy_automat_can_sell)
		actions += "sales_audit"
	if(cy_automat_can_store)
		actions += "storage_audit"
	return actions

/obj/machinery/cy_modular_automat/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status", "sales_audit", "storage_audit")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable_network")
			cy_net_isolated = TRUE
			return TRUE
	return FALSE

/obj/machinery/cy_modular_automat/update_overlays()
	. = ..()
	if(!length(cy_machine_modules))
		return
	var/offset = 0
	for(var/obj/item/cy_machinery_module/module as anything in cy_machine_modules)
		var/mutable_appearance/module_overlay = module.cy_get_overlay_appearance(layer + offset)
		if(module_overlay)
			. += module_overlay
		offset += 0.01

/obj/machinery/cy_modular_automat/vendor
	name = "modular vendor automat"
	desc = "A prepared vending shell with sale, storage and payment modules. Final UI comes later."
	cy_default_machine_module_types = list(
		/obj/item/cy_machinery_module/sales,
		/obj/item/cy_machinery_module/storage,
		/obj/item/cy_machinery_module/payment,
	)

/obj/machinery/cy_modular_automat/network_vendor
	name = "networked modular vendor automat"
	desc = "A prepared vending shell with payment, storage, sale and network modules."
	cy_default_machine_module_types = list(
		/obj/item/cy_machinery_module/sales,
		/obj/item/cy_machinery_module/storage,
		/obj/item/cy_machinery_module/payment,
		/obj/item/cy_machinery_module/network,
	)

/obj/machinery/cy_modular_automat/industrial
	name = "industrial modular automat"
	desc = "A prepared industrial shell using high-output machinery modules."
	cy_default_machine_module_types = list(
		/obj/item/cy_machinery_module/storage,
		/obj/item/cy_machinery_module/tyazhmarsh_industrial,
		/obj/item/cy_machinery_module/kowalski_redundancy,
	)
