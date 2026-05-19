/obj/structure/cy_business_warehouse
	name = "business warehouse anchor"
	desc = "A business supply anchor. Items routed here are owned by the linked business."
	icon = 'icons/obj/storage/crates.dmi'
	icon_state = "crate"
	anchored = TRUE
	density = TRUE
	var/business_id
	var/corporation_id
	var/allow_business_fallback = TRUE
	var/list/allowed_item_types = list()

/obj/structure/cy_business_warehouse/Initialize(mapload)
	. = ..()
	if(!allowed_item_types)
		allowed_item_types = list()
	SScy_business?.register_warehouse(src)

/obj/structure/cy_business_warehouse/Destroy()
	SScy_business?.unregister_warehouse(src)
	return ..()

/obj/structure/cy_business_warehouse/examine(mob/user)
	. = ..()
	. += span_notice("Business: [business_id || "none"]. Corporation: [corporation_id || "independent"].")
	. += span_notice("Fallback: [allow_business_fallback ? "allowed" : "blocked"]. Accepted types: [length(allowed_item_types)].")

/obj/structure/cy_business_warehouse/proc/can_accept_item(obj/item/item, corporation)
	if(!item)
		return FALSE
	if(corporation_id && corporation_id != corporation)
		return FALSE
	if(!length(allowed_item_types))
		return TRUE
	for(var/type_text in allowed_item_types)
		var/path = text2path(type_text)
		if(path && istype(item, path))
			return TRUE
	return FALSE

/obj/structure/cy_business_warehouse/proc/store_item(obj/item/item)
	if(!item)
		return FALSE
	item.forceMove(src)
	return TRUE

/obj/structure/cy_business_warehouse/proc/to_ui_data()
	var/list/items = list()
	for(var/obj/item/item in contents)
		items += list(list(
			"name" = item.name,
			"type" = "[item.type]",
			"quality" = item.cy_get_quality_text(),
		))
	return list(
		"ref" = REF(src),
		"name" = name,
		"business_id" = business_id,
		"corporation_id" = corporation_id,
		"allow_business_fallback" = allow_business_fallback,
		"allowed_item_types" = allowed_item_types.Copy(),
		"items" = items,
	)

/obj/structure/cy_business_warehouse/cy_business_should_persist(datum/cy_business/business)
	return business && business.business_id == business_id

/obj/structure/cy_business_warehouse/cy_business_serialize(datum/cy_business/business)
	var/list/data = ..()
	data["business_id"] = business_id
	data["corporation_id"] = corporation_id
	data["allow_business_fallback"] = allow_business_fallback
	data["allowed_item_types"] = allowed_item_types.Copy()
	return data

/obj/structure/cy_business_warehouse/proc/cy_business_apply_serialized(list/entry)
	business_id = entry["business_id"]
	corporation_id = entry["corporation_id"]
	allow_business_fallback = isnull(entry["allow_business_fallback"]) ? TRUE : entry["allow_business_fallback"]
	allowed_item_types = entry["allowed_item_types"] || list()

/proc/cy_business_apply_restored_object_data(obj/object, list/entry)
	if(istype(object, /obj/structure/cy_business_warehouse))
		var/obj/structure/cy_business_warehouse/warehouse = object
		warehouse.cy_business_apply_serialized(entry)
