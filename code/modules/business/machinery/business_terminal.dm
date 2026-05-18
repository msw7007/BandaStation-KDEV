/obj/machinery/computer/cy_business_terminal
	name = "business terminal"
	desc = "A civic terminal for registering and managing a persistent business."
	icon_screen = "id"
	var/obj/structure/cy_business_zone/linked_zone

/obj/machinery/computer/cy_business_terminal/Initialize(mapload)
	. = ..()
	if(!linked_zone)
		linked_zone = find_zone_in_area()
	if(linked_zone)
		linked_zone.linked_terminal = src

/obj/machinery/computer/cy_business_terminal/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(!user)
		return
	show_business_status(user)

/obj/machinery/computer/cy_business_terminal/proc/find_zone_in_area()
	var/area/current_area = get_area(src)
	if(!current_area)
		return null
	for(var/turf/area_turf as anything in get_area_turfs(current_area))
		var/obj/structure/cy_business_zone/found_zone = locate(/obj/structure/cy_business_zone) in area_turf
		if(found_zone)
			return found_zone
	return null

/obj/machinery/computer/cy_business_terminal/proc/show_business_status(mob/user)
	var/area/current_area = get_area(src)
	var/list/zone = current_area?.cy_describe_zone()
	if(zone)
		to_chat(user, span_notice("Zone: [zone["name"]], security [zone["security_level"]], controller [zone["controller"] || "none"]."))
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business)
		to_chat(user, span_notice("Business zone is free. Use cy_create_business() in code/admin tooling or map verbs to register it."))
		return
	to_chat(user, span_notice("Business: [business.name] ([business.business_id])"))
	to_chat(user, span_notice("Status: [business.legal_status], risk [business.refresh_risk()]%, tax debt [business.tax_debt]."))
	to_chat(user, span_notice("Balance: [business.account?.account_balance || 0]. Employees: [length(business.employees)]."))

/obj/machinery/computer/cy_business_terminal/proc/create_business_for(mob/user, business_name, legal_status = CY_BUSINESS_LEGAL, business_type = "general")
	if(!linked_zone || linked_zone.active_business)
		return null
	return SScy_business.create_business(business_name, user?.ckey, linked_zone, legal_status, business_type)

/obj/machinery/computer/cy_business_terminal/proc/save_business(mob/user)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	return business.save_to_disk()

/obj/machinery/computer/cy_business_terminal/proc/load_business(mob/user)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	if(!business.load_from_disk())
		return FALSE
	return business.restore_snapshot()

/obj/machinery/computer/cy_business_terminal/proc/pay_tax(mob/user, amount = CY_BUSINESS_DEFAULT_TAX_DUE)
	var/datum/cy_business/business = linked_zone?.active_business
	if(!business || !business.can_manage(user))
		return FALSE
	return business.pay_tax(amount)
