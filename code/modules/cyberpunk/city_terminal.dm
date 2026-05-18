/obj/machinery/computer/cy_city_terminal
	name = "city operations terminal"
	desc = "A civic access terminal for health, zone, legal, market and story-state diagnostics."
	icon_screen = "request"

/obj/machinery/computer/cy_city_terminal/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!user)
		return
	show_city_status(user)

/obj/machinery/computer/cy_city_terminal/proc/show_city_status(mob/user)
	var/mob/living/living_user = user
	if(istype(living_user))
		var/list/temp_data = living_user.get_cy_secondary_indicator_summary()
		to_chat(user, span_notice("Vitals: [temp_data.Join("; ")]"))
		var/area/current_area = get_area(user)
		var/list/zone = current_area?.cy_describe_zone()
		if(zone)
			to_chat(user, span_notice("Zone: [zone["name"]], security [zone["security_level"]], controller [zone["controller"] || "none"]."))
		var/list/temp_info = living_user.get_cy_controlled_items_in_zone()
		var/controlled_count = length(temp_info)
		if(controlled_count)
			to_chat(user, span_warning("Legal risk: [controlled_count] controlled items conflict with this zone."))
	var/obj/item/held = user.get_active_held_item()
	if(held)
		var/price = SSeconomy?.cy_get_item_market_price(held) || held.get_cy_market_value()
		to_chat(user, span_notice("Held item: [held.name], [held.get_cy_market_category()], [price] credits, style [held.get_cy_style_value()]."))
	var/datum/cy_city_crime_record/record = SSeconomy?.cy_get_crime_record(user, FALSE)
	if(record)
		to_chat(user, span_notice("Legal record: status [record.current_status()], fines [record.total_fines()], traces [length(record.forensic_traces)]."))
	var/list/story_state = SScy_storyteller?.get_story_state()
	if(story_state)
		to_chat(user, span_notice("Story state: [story_state["ending"]], pressure [round(story_state["total_pressure"])], open contracts [story_state["open_contracts"]]."))

/obj/machinery/computer/cy_city_terminal/proc/audit_user(mob/living/user)
	if(!user)
		return 0
	return user.report_cy_controlled_items_in_zone("City terminal audit")

/obj/machinery/computer/cy_city_terminal/proc/estimate_item(obj/item/item)
	if(!item)
		return null
	return list(
		"name" = item.name,
		"market_category" = item.get_cy_market_category(),
		"base_value" = item.get_cy_market_value(),
		"market_price" = SSeconomy?.cy_get_item_market_price(item) || item.get_cy_market_value(),
		"style" = item.get_cy_style_value(),
		"style_tags" = item.get_cy_style_tags(),
	)
