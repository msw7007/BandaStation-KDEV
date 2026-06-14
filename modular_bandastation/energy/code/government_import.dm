/obj/machinery/power/cyberpunk_generator/government_import
	name = "government emergency power import"
	desc = "A city reserve power meter. It imports fixed power into the local grid and bills the government account."
	icon_state = "portgen1_0"
	base_icon_state = "portgen1"
	base_power_gen = 75 KILO WATTS
	corp_manufacturer = CYBERPUNK_CORP_GOVERNMENT
	circuit = /obj/item/circuitboard/machine/cyberpunk_government_import
	var/credits_per_tick = 35
	var/authorized = FALSE
	var/authorized_by = null

/obj/machinery/power/cyberpunk_generator/government_import/process_generator(seconds_per_tick)
	if(!authorized)
		return FALSE
	var/datum/cyberpunk_corporation/government = SScyberpunk_corporations.get_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)
	if(!government?.charge_funds(credits_per_tick, "emergency power import"))
		return FALSE
	return TRUE

/obj/machinery/power/cyberpunk_generator/government_import/attackby(obj/item/item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(item, /obj/item/card/id))
		var/obj/item/card/id/card = item
		authorized = TRUE
		authorized_by = card.registered_name || user.real_name || user.name
		balloon_alert(user, "reserve authorized")
		return
	return ..()

/obj/machinery/power/cyberpunk_generator/government_import/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Reserve billing: [credits_per_tick][MONEY_SYMBOL] per machine tick.")
		. += span_notice("Authorization: [authorized ? authorized_by : "no ID swiped"].")

/obj/machinery/power/cyberpunk_generator/government_import/get_cyberpunk_power_ui_data(mob/user)
	return list(
		"kind" = "government_import",
		"authorized" = authorized,
		"authorized_by" = authorized_by,
		"credits_per_tick" = credits_per_tick,
	)

/obj/machinery/power/cyberpunk_generator/government_import/handle_cyberpunk_power_ui_act(action, list/params, mob/user)
	switch(action)
		if("clear_auth")
			authorized = FALSE
			authorized_by = null
			set_active(FALSE)
			return TRUE
	return FALSE
