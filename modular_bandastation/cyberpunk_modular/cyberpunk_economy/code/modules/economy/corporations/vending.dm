//CYBERPUNK CORPORATIONS - corporate vending network integration.

/obj/machinery/vending
	var/cyberpunk_corporate_vendor_id
	var/cyberpunk_corporate_vendor_sales = 0
	var/cyberpunk_corporate_vendor_revenue = 0
	var/corp_manufacturer

/obj/machinery/vending/proc/has_corporate_vending_module()
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		if(istype(module, /datum/cyberpunk_machine_module/corporate_vending_bus))
			return TRUE
	return FALSE

/obj/machinery/vending/proc/set_cyberpunk_corporate_vendor(manufacturer, mob/living/user = null)
	var/corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return FALSE
	cyberpunk_corporate_vendor_id = corporation_id
	corp_manufacturer = manufacturer
	SScyberpunk_corporations.register_cyberpunk_corporate_vendor(src, corporation_id, user)
	return TRUE

/obj/machinery/vending/proc/cyberpunk_corporate_record_sale(amount, product_label)
	if(!cyberpunk_corporate_vendor_id)
		return FALSE
	amount = max(0, round(amount))
	cyberpunk_corporate_vendor_sales++
	cyberpunk_corporate_vendor_revenue += amount
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(cyberpunk_corporate_vendor_id)
	if(!corporation)
		return FALSE
	corporation.record_vendor_sale(src, amount, product_label)
	return TRUE

/obj/machinery/vending/proc/get_cyberpunk_corporate_vendor_ui()
	return list(
		"name" = name,
		"type" = "[type]",
		"area" = get_area_name(src, TRUE),
		"x" = x,
		"y" = y,
		"z" = z,
		"sales" = cyberpunk_corporate_vendor_sales,
		"revenue" = cyberpunk_corporate_vendor_revenue,
		"manufacturer" = corp_manufacturer,
	)

/obj/machinery/vending/cyberpunk_corporate
	name = "corporate vending machine"
	desc = "A vending machine preloaded with a corporate routing bus."
	var/preloaded_corporation_id = CYBERPUNK_CORP_STARLIGHT
	var/preloaded_corporate_manufacturer = "Starlight"
	var/preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/starlight

/obj/machinery/vending/cyberpunk_corporate/Initialize(mapload)
	. = ..()
	if(!has_corporate_vending_module())
		var/datum/cyberpunk_machine_module/module = new preloaded_module_type
		if(can_install_cyberpunk_module(module, null))
			LAZYADD(cyberpunk_machine_modules, module)
			module.on_install(src, null)
		else
			qdel(module)
	set_cyberpunk_corporate_vendor(preloaded_corporate_manufacturer)

/obj/machinery/vending/cyberpunk_corporate/benn
	name = "Benn corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_BENN
	preloaded_corporate_manufacturer = "Benn"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/benn

/obj/machinery/vending/cyberpunk_corporate/ryaznov
	name = "Ryaznov corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_RYAZNOV
	preloaded_corporate_manufacturer = "Ryaznov"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/ryaznov

/obj/machinery/vending/cyberpunk_corporate/starlight
	name = "Starlight corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_STARLIGHT
	preloaded_corporate_manufacturer = "Starlight"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/starlight

/datum/controller/subsystem/cyberpunk_corporations/proc/register_cyberpunk_corporate_vendor(obj/machinery/vending/vendor, corporation_id, mob/living/user = null)
	if(!vendor)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	corporation.register_vendor(vendor, user)
	return TRUE

/datum/cyberpunk_corporation/proc/register_vendor(obj/machinery/vending/vendor, mob/living/user = null)
	if(!vendor)
		return FALSE
	vendor_registry["\ref[vendor]"] = WEAKREF(vendor)
	add_history("[user ? (user.real_name || user.name) : "system"] registered corporate vendor [vendor.name] at [get_area_name(vendor, TRUE)]")
	return TRUE

/datum/cyberpunk_corporation/proc/record_vendor_sale(obj/machinery/vending/vendor, amount, product_label)
	amount = max(0, round(amount))
	var/vendor_key = "\ref[vendor]"
	var/list/sales = vendor_sales[vendor_key]
	if(!sales)
		sales = list("name" = vendor.name, "sales" = 0, "revenue" = 0, "lastProduct" = null)
		vendor_sales[vendor_key] = sales
	sales["sales"] = (sales["sales"] || 0) + 1
	sales["revenue"] = (sales["revenue"] || 0) + amount
	sales["lastProduct"] = product_label
	add_funds(round(amount * 0.05), "corporate vending fee")
	add_data(get_primary_data_type(), 1, "corporate vending sale")
	return TRUE

/datum/cyberpunk_corporation/proc/get_cyberpunk_corporate_vendors_ui()
	var/list/vendors = list()
	for(var/vendor_ref in vendor_registry)
		var/datum/weakref/vendor_weakref = vendor_registry[vendor_ref]
		var/obj/machinery/vending/vendor = vendor_weakref?.resolve()
		if(!vendor || QDELETED(vendor))
			vendor_registry -= vendor_ref
			continue
		var/list/vendor_data = vendor.get_cyberpunk_corporate_vendor_ui()
		var/list/sales = vendor_sales[vendor_ref]
		if(sales)
			vendor_data["sales"] = max(vendor_data["sales"] || 0, sales["sales"] || 0)
			vendor_data["revenue"] = max(vendor_data["revenue"] || 0, sales["revenue"] || 0)
			vendor_data["lastProduct"] = sales["lastProduct"]
		vendors += list(vendor_data)
	return vendors
