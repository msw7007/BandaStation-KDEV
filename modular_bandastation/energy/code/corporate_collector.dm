/obj/machinery/power/cyberpunk_corporate_energy_uplink
	name = "corporate energy uplink"
	desc = "Stores surplus local grid power in a corporation's remote energy reserve."
	icon = 'icons/obj/machines/engine/other.dmi'
	icon_state = "rtg"
	base_icon_state = "rtg"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/cyberpunk_corporate_energy_uplink
	var/active = TRUE
	var/corporation_id = CYBERPUNK_CORP_RYAZNOV
	var/input_level = 50 KILO WATTS

/obj/machinery/power/cyberpunk_corporate_energy_uplink/Initialize(mapload)
	. = ..()
	connect_to_network()
	START_PROCESSING(SSmachines, src)

/obj/machinery/power/cyberpunk_corporate_energy_uplink/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/power/cyberpunk_corporate_energy_uplink/process()
	if(!active || !anchored || !powernet)
		return
	var/energy = min(surplus(), power_to_energy(input_level))
	if(energy <= 0)
		return
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return
	var/accepted = corporation.add_cyberpunk_energy(energy, "corporate energy uplink")
	if(accepted)
		add_load(accepted)

/obj/machinery/power/cyberpunk_corporate_energy_uplink/examine(mob/user)
	. = ..()
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Linked corporation: [corporation?.name || corporation_id].")
		. += span_notice("Reserve: [round((corporation?.cyberpunk_energy_reserve || 0) / (1 KILO JOULES))] kJ.")

/obj/machinery/power/cyberpunk_corporate_energy_uplink/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/machinery/power/cyberpunk_corporate_energy_uplink/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkPowerSource", name)
		ui.open()

/obj/machinery/power/cyberpunk_corporate_energy_uplink/ui_data(mob/user)
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	return list(
		"name" = name,
		"kind" = "corporate_uplink",
		"active" = active,
		"anchored" = anchored,
		"connected" = !isnull(powernet),
		"can_generate" = anchored && !isnull(powernet),
		"output" = display_power(input_level, convert = FALSE),
		"base_output" = display_power(input_level, convert = FALSE),
		"power_output" = 1,
		"heat" = 20,
		"heat_ratio" = 0,
		"safe_heat" = 0,
		"critical_heat" = 0,
		"wear" = 0,
		"wear_ratio" = 0,
		"max_wear" = 0,
		"integrity" = round(atom_integrity || 0, 0.1),
		"max_integrity" = max_integrity,
		"integrity_ratio" = clamp((atom_integrity || 0) / max(max_integrity, 1), 0, 1),
		"corp" = corporation_id,
		"technology" = null,
		"special" = list(
			"kind" = "corporate_uplink",
			"corporation" = corporation?.name || corporation_id,
			"corporation_id" = corporation_id,
			"reserve_kj" = round((corporation?.cyberpunk_energy_reserve || 0) / (1 KILO JOULES)),
			"reserve_limit_kj" = round((corporation?.cyberpunk_energy_reserve_limit || 0) / (1 KILO JOULES)),
			"input_level" = display_power(input_level, convert = FALSE),
		),
	)

/obj/machinery/power/cyberpunk_corporate_energy_uplink/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			active = !active
			. = TRUE
		if("set_corporation")
			var/new_corp = params["corporation"]
			if(new_corp in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT, CYBERPUNK_CORP_GOVERNMENT))
				corporation_id = new_corp
				. = TRUE
		if("adjust_input")
			var/delta = text2num(params["delta"])
			if(isnum(delta))
				input_level = clamp(input_level + delta, 5 KILO WATTS, 500 KILO WATTS)
				. = TRUE

/obj/machinery/power/cyberpunk_generator/corporate_collector
	name = "corporate energy collector"
	desc = "Buys remote corporate energy and injects it into the local powernet."
	icon_state = "portgen1_0"
	base_icon_state = "portgen1"
	base_power_gen = 50 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_RYAZNOV
	circuit = /obj/item/circuitboard/machine/cyberpunk_corporate_collector
	var/provider_corporation_id = CYBERPUNK_CORP_RYAZNOV
	var/customer_account_id = null

/obj/machinery/power/cyberpunk_generator/corporate_collector/process_generator(seconds_per_tick)
	if(!customer_account_id)
		return FALSE
	var/energy = power_to_energy(get_power_gen())
	var/datum/cyberpunk_corporation/provider = SScyberpunk_corporations.get_cyberpunk_corporation(provider_corporation_id)
	if(!provider || provider.cyberpunk_energy_reserve < energy)
		return FALSE
	if(customer_account_id && !provider.charge_cyberpunk_energy_customer(customer_account_id, energy, "energy collector sale"))
		return FALSE
	provider.use_cyberpunk_energy(energy, "energy collector")
	return TRUE

/obj/machinery/power/cyberpunk_generator/corporate_collector/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/card/id))
		var/obj/item/card/id/card = item
		if(card.registered_account)
			customer_account_id = card.registered_account.account_id
			balloon_alert(user, "account linked")
			return
	return ..()

/obj/machinery/power/cyberpunk_generator/corporate_collector/examine(mob/user)
	. = ..()
	var/datum/cyberpunk_corporation/provider = SScyberpunk_corporations.get_cyberpunk_corporation(provider_corporation_id)
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Provider: [provider?.name || provider_corporation_id]. Reserve: [round((provider?.cyberpunk_energy_reserve || 0) / (1 KILO JOULES))] kJ.")
		. += span_notice("Customer account: [customer_account_id || "not linked"].")

/obj/machinery/power/cyberpunk_generator/corporate_collector/get_cyberpunk_power_ui_data(mob/user)
	var/datum/cyberpunk_corporation/provider = SScyberpunk_corporations.get_cyberpunk_corporation(provider_corporation_id)
	return list(
		"kind" = "corporate_collector",
		"provider" = provider?.name || provider_corporation_id,
		"provider_id" = provider_corporation_id,
		"reserve_kj" = round((provider?.cyberpunk_energy_reserve || 0) / (1 KILO JOULES)),
		"reserve_limit_kj" = round((provider?.cyberpunk_energy_reserve_limit || 0) / (1 KILO JOULES)),
		"customer_account_id" = customer_account_id,
		"estimated_price" = provider ? round(provider.get_cyberpunk_energy_price(power_to_energy(get_power_gen())), 0.01) : 0,
	)

/obj/machinery/power/cyberpunk_generator/corporate_collector/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("set_provider")
			var/new_provider = params["provider"]
			if(new_provider in list(CYBERPUNK_CORP_BENN, CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT, CYBERPUNK_CORP_GOVERNMENT))
				provider_corporation_id = new_provider
				return TRUE
		if("clear_account")
			customer_account_id = null
			set_active(FALSE)
			return TRUE
	return FALSE
