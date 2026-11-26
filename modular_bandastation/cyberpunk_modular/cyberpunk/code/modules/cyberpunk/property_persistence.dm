//CYBERPUNK BUILD - rebuild and delete before release
/proc/cyberpunk_area_turfs(area/target_area)
	var/list/turfs = list()
	if(!target_area)
		return turfs
	for(var/list/zlevel_turfs as anything in target_area.get_zlevel_turf_lists())
		turfs += zlevel_turfs
	return turfs

/proc/cyberpunk_is_apartment_area(area/target_area)
	if(istype(target_area, /area/station/commons/dorms/persistent_apartment) || istype(target_area, /area/station/commons/dorms/apartment1) || istype(target_area, /area/station/commons/dorms/apartment2))
		return TRUE
	if(istype(target_area, /area/cyberpunk/city/housing/apartment))
		return TRUE
	return islist(target_area?.cyberpunk_world_tags) && ("apartment" in target_area.cyberpunk_world_tags)

/proc/cyberpunk_is_business_area(area/target_area)
	if(istype(target_area, /area/station/service/business))
		return TRUE
	if(istype(target_area, /area/cyberpunk/city/business))
		return TRUE
	return islist(target_area?.cyberpunk_world_tags) && ("business" in target_area.cyberpunk_world_tags)

/obj/structure/cyberpunk_vehicle_parking
	name = "vehicle parking anchor"
	desc = "A parking anchor for persistent vehicles."
	icon = 'icons/obj/structures.dmi'
	icon_state = "rack"
	anchored = TRUE
	density = FALSE

/obj/structure/cyberpunk_vehicle_parking/examine(mob/user)
	. = ..()
	. += span_notice("Vehicles parked on or next to this anchor are included when the linked persistent property is saved.")

/proc/cyberpunk_persistent_read_var(datum/source, var_name, fallback = null)
	if(!source || !(var_name in source.vars))
		return fallback
	return source.vars[var_name]

/proc/cyberpunk_persistent_write_var(datum/target, var_name, value)
	if(!target || !(var_name in target.vars))
		return FALSE
	target.vars[var_name] = value
	return TRUE

/proc/cyberpunk_persistent_capture_reagents(atom/movable/thing)
	var/list/reagent_records = list()
	if(!thing?.reagents)
		return reagent_records
	for(var/datum/reagent/reagent as anything in thing.reagents.reagent_list)
		reagent_records += list(list(
			"type" = "[reagent.type]",
			"volume" = reagent.volume,
		))
	return reagent_records

/proc/cyberpunk_persistent_capture_movable(atom/movable/thing, turf/base_turf, turf/center, obj/machinery/active_terminal, depth = 0, allow_vehicle = FALSE)
	if(!thing || thing == active_terminal || ismob(thing) || istype(thing, /obj/item/cyberpunk_business_delivery_crate) || istype(thing, /obj/vehicle/ridden/cyberpunk/avi/warehouse))
		return null
	var/is_persistent_vehicle = allow_vehicle && istype(thing, /obj/vehicle/sealed/car/cyberpunk)
	if(!(isitem(thing) || istype(thing, /obj/machinery) || istype(thing, /obj/structure) || is_persistent_vehicle))
		return null
	var/list/req_access = cyberpunk_persistent_read_var(thing, "req_access")
	var/list/req_one_access = cyberpunk_persistent_read_var(thing, "req_one_access")
	var/list/machine_module_types = list()
	var/obj/machinery/machine = thing
	if(istype(machine) && length(machine.cyberpunk_machine_modules))
		for(var/datum/cyberpunk_machine_module/module as anything in machine.cyberpunk_machine_modules)
			machine_module_types += "[module.type]"
	var/list/vending_stock = list()
	var/obj/machinery/vending/vendor = thing
	if(istype(vendor))
		for(var/datum/data/vending_product/record as anything in vendor.product_records + vendor.coin_records + vendor.hidden_records)
			vending_stock += list(list(
				"path" = "[record.product_path]",
				"name" = record.name,
				"amount" = record.amount,
				"max_amount" = record.max_amount,
				"warehouse_items" = record.cyberpunk_warehouse_items?.Copy(),
			))
	var/list/entry = list(
		"type" = "[thing.type]",
		"name" = thing.name,
		"desc" = thing.desc,
		"x" = base_turf.x - center.x,
		"y" = base_turf.y - center.y,
		"z" = base_turf.z - center.z,
		"dir" = thing.dir,
		"pixel_x" = thing.pixel_x,
		"pixel_y" = thing.pixel_y,
		"pixel_z" = thing.pixel_z,
		"anchored" = thing.anchored,
		"density" = thing.density,
		"opacity" = thing.opacity,
		"alpha" = thing.alpha,
		"color" = thing.color,
		"icon_state" = thing.icon_state,
		"base_icon_state" = cyberpunk_persistent_read_var(thing, "base_icon_state"),
		"integrity" = cyberpunk_persistent_read_var(thing, "atom_integrity"),
		"max_integrity" = cyberpunk_persistent_read_var(thing, "max_integrity"),
		"machine_stat" = cyberpunk_persistent_read_var(thing, "machine_stat"),
		"manufacturer" = cyberpunk_persistent_read_var(thing, "manufacturer"),
		"corp_manufacturer" = cyberpunk_persistent_read_var(thing, "corp_manufacturer"),
		"cyberpunk_business_id" = cyberpunk_persistent_read_var(thing, "cyberpunk_business_id"),
		"cyberpunk_business_warehouse_linked" = cyberpunk_persistent_read_var(thing, "cyberpunk_business_warehouse_linked"),
		"cyberpunk_business_auto_restock" = cyberpunk_persistent_read_var(thing, "cyberpunk_business_auto_restock"),
		"cyberpunk_business_markup_percent" = cyberpunk_persistent_read_var(thing, "cyberpunk_business_markup_percent"),
		"cyberpunk_business_minimum_stock" = cyberpunk_persistent_read_var(thing, "cyberpunk_business_minimum_stock"),
		"cyberpunk_unload_business_id" = cyberpunk_persistent_read_var(thing, "business_id"),
		"cyberpunk_unload_business_name" = cyberpunk_persistent_read_var(thing, "business_name"),
		"cyberpunk_machine_modules" = machine_module_types,
		"cyberpunk_vending_stock" = vending_stock,
		"cyberpunk_corporate_markup" = vendor?.cyberpunk_corporate_markup_percent,
		"req_access" = islist(req_access) ? req_access.Copy() : null,
		"req_one_access" = islist(req_one_access) ? req_one_access.Copy() : null,
	)
	var/list/reagent_records = cyberpunk_persistent_capture_reagents(thing)
	if(length(reagent_records))
		entry["reagents"] = reagent_records
	var/obj/item/item = thing
	if(istype(item))
		entry["item_quality"] = item.cyberpunk_quality
		entry["item_manufacturer"] = item.get_cyberpunk_manufacturer()
		entry["resource_quality"] = item.resource_quality
		if(item.cyberpunk_recovered_scrap)
			entry["recovered_scrap"] = TRUE
			entry["scrap_analyzed"] = item.cyberpunk_scrap_analyzed
		entry["weapon_assembled"] = item.cyberpunk_weapon_assembled
		var/obj/item/stack/stack = item
		var/units = istype(stack) ? stack.get_amount() : 1
		if(istype(stack))
			entry["stack_amount"] = units
		var/list/materials = list()
		for(var/datum/material/material as anything in item.custom_materials)
			materials["[material.type]"] = item.custom_materials[material] / max(units, 1)
		entry["item_materials"] = materials
		var/list/modules = list()
		for(var/datum/cyberpunk_item_module/module as anything in item.cyberpunk_modules)
			modules += list(list("type" = "[module.type]", "quality" = module.quality, "manufacturer" = module.manufacturer, "tier" = module.module_tier, "variant" = module.module_variant))
		entry["item_modules"] = modules
		var/obj/item/cyberpunk_item_module/module_item = item
		if(istype(module_item))
			entry["module_tier"] = module_item.module_tier
			entry["module_variant"] = module_item.module_variant
		var/obj/item/seeds/seed = item
		if(istype(seed))
			entry["plant_genetics"] = seed.cyberpunk_capture_genetics()
	var/obj/item/clothing/clothing = thing
	if(istype(clothing) && islist(clothing.cyberpunk_custom_design_data))
		entry["clothing_design"] = clothing.cyberpunk_custom_design_data.Copy()
	if(istype(machine) && islist(machine.component_parts) && depth < 3)
		var/list/parts = list()
		for(var/datum/component as anything in machine.component_parts)
			var/list/part_record
			if(istype(component, /datum/stock_part))
				part_record = list("stock_part" = "[component.type]")
			else if(isitem(component))
				part_record = cyberpunk_persistent_capture_movable(component, base_turf, center, active_terminal, depth + 1)
			if(part_record)
				part_record["wear"] = machine.get_cyberpunk_component_wear(component)
				parts += list(part_record)
		if(length(parts) == length(machine.component_parts))
			entry["machine_parts"] = parts
		entry["machine_failure"] = machine.cyberpunk_machine_failure_state
	if(is_persistent_vehicle)
		var/obj/vehicle/sealed/car/cyberpunk/vehicle = thing
		entry["cyberpunk_vehicle"] = vehicle.cyberpunk_to_persistent_record()
	if(depth < 3 && length(thing.contents))
		var/list/content_records = list()
		var/obj/machinery/reagentgrinder/grinder = thing
		if(istype(grinder))
			entry["has_machine_slots"] = TRUE
		for(var/atom/movable/content as anything in thing.contents)
			if(islist(entry["machine_parts"]) && (content in machine.component_parts))
				continue
			var/list/content_entry = cyberpunk_persistent_capture_movable(content, base_turf, center, active_terminal, depth + 1)
			if(content_entry)
				if(istype(grinder) && content == grinder.beaker)
					content_entry["machine_slot"] = "beaker"
				content_records += list(content_entry)
		if(length(content_records))
			entry["contents"] = content_records
	return entry

/proc/cyberpunk_persistent_capture_parked_vehicles(obj/structure/cyberpunk_vehicle_parking/parking, area/target_area, turf/center, obj/machinery/active_terminal, list/captured_vehicles)
	var/list/entries = list()
	if(!parking || !target_area || !center)
		return entries
	for(var/turf/nearby_turf as anything in range(1, parking))
		if(!nearby_turf || get_area(nearby_turf) != target_area)
			continue
		for(var/obj/vehicle/sealed/car/cyberpunk/vehicle as anything in nearby_turf.contents)
			if(captured_vehicles[vehicle])
				continue
			var/list/entry = cyberpunk_persistent_capture_movable(vehicle, nearby_turf, center, active_terminal, allow_vehicle = TRUE)
			if(!entry)
				continue
			captured_vehicles[vehicle] = TRUE
			entries += list(entry)
	return entries

/proc/cyberpunk_persistent_restore_movable(list/entry, atom/location, area/target_area, turf/center, obj/machinery/active_terminal)
	if(!islist(entry) || !location)
		return null
	var/movable_path = text2path("[entry["type"]]")
	if(!ispath(movable_path, /atom/movable))
		return null
	var/turf/target_turf = isturf(location) ? location : get_turf(location)
	if(!target_turf || (target_area && get_area(target_turf) != target_area))
		return null
	var/atom/movable/restored_atom
	if(ispath(movable_path, /obj/item/stack) && isnum(entry["stack_amount"]))
		restored_atom = new movable_path(location, max(1, round(entry["stack_amount"])), FALSE)
	else
		restored_atom = new movable_path(location)
	if(QDELETED(restored_atom) || restored_atom == active_terminal)
		return null
	var/obj/item/restored_item = restored_atom
	if(istype(restored_item) && isnum(entry["item_quality"]))
		cyberpunk_persistent_restore_item(restored_item, entry)
	restored_atom.name = entry["name"] || restored_atom.name
	restored_atom.desc = entry["desc"] || restored_atom.desc
	restored_atom.dir = entry["dir"] || SOUTH
	restored_atom.pixel_x = entry["pixel_x"] || 0
	restored_atom.pixel_y = entry["pixel_y"] || 0
	restored_atom.pixel_z = entry["pixel_z"] || 0
	restored_atom.anchored = !!entry["anchored"]
	restored_atom.density = !!entry["density"]
	restored_atom.opacity = !!entry["opacity"]
	restored_atom.alpha = isnum(entry["alpha"]) ? entry["alpha"] : restored_atom.alpha
	restored_atom.color = entry["color"] || restored_atom.color
	if(entry["icon_state"])
		restored_atom.icon_state = entry["icon_state"]
	cyberpunk_persistent_write_var(restored_atom, "base_icon_state", entry["base_icon_state"])
	cyberpunk_persistent_write_var(restored_atom, "atom_integrity", entry["integrity"])
	cyberpunk_persistent_write_var(restored_atom, "max_integrity", entry["max_integrity"])
	cyberpunk_persistent_write_var(restored_atom, "machine_stat", entry["machine_stat"])
	cyberpunk_persistent_write_var(restored_atom, "manufacturer", entry["manufacturer"])
	cyberpunk_persistent_write_var(restored_atom, "corp_manufacturer", entry["corp_manufacturer"])
	cyberpunk_persistent_write_var(restored_atom, "cyberpunk_business_id", entry["cyberpunk_business_id"])
	cyberpunk_persistent_write_var(restored_atom, "cyberpunk_business_warehouse_linked", entry["cyberpunk_business_warehouse_linked"])
	cyberpunk_persistent_write_var(restored_atom, "cyberpunk_business_auto_restock", entry["cyberpunk_business_auto_restock"])
	cyberpunk_persistent_write_var(restored_atom, "cyberpunk_business_markup_percent", entry["cyberpunk_business_markup_percent"])
	cyberpunk_persistent_write_var(restored_atom, "cyberpunk_business_minimum_stock", entry["cyberpunk_business_minimum_stock"])
	cyberpunk_persistent_write_var(restored_atom, "business_id", entry["cyberpunk_unload_business_id"])
	cyberpunk_persistent_write_var(restored_atom, "business_name", entry["cyberpunk_unload_business_name"])
	var/list/req_access = entry["req_access"]
	if(islist(req_access))
		cyberpunk_persistent_write_var(restored_atom, "req_access", req_access.Copy())
	var/list/req_one_access = entry["req_one_access"]
	if(islist(req_one_access))
		cyberpunk_persistent_write_var(restored_atom, "req_one_access", req_one_access.Copy())
	if(restored_atom.reagents && islist(entry["reagents"]))
		restored_atom.reagents.clear_reagents()
		for(var/list/reagent_entry as anything in entry["reagents"])
			var/reagent_path = text2path("[reagent_entry["type"]]")
			var/volume = max(0, reagent_entry["volume"] || 0)
			if(ispath(reagent_path, /datum/reagent) && volume)
				restored_atom.reagents.add_reagent(reagent_path, volume)
	var/obj/item/clothing/clothing = restored_atom
	if(istype(clothing) && islist(entry["clothing_design"]))
		clothing.cyberpunk_apply_design(entry["clothing_design"])
	var/obj/vehicle/sealed/car/cyberpunk/vehicle = restored_atom
	var/list/vehicle_record = entry["cyberpunk_vehicle"]
	if(istype(vehicle) && islist(vehicle_record))
		vehicle.cyberpunk_apply_persistent_record(vehicle_record)
	var/obj/machinery/restored_machine = restored_atom
	if(istype(restored_machine) && islist(entry["cyberpunk_machine_modules"]))
		QDEL_LIST(restored_machine.cyberpunk_machine_modules)
		for(var/module_type_text in entry["cyberpunk_machine_modules"])
			var/module_type = text2path("[module_type_text]")
			if(!ispath(module_type, /datum/cyberpunk_machine_module))
				continue
			var/datum/cyberpunk_machine_module/module = new module_type
			if(restored_machine.can_install_cyberpunk_module(module, null))
				LAZYADD(restored_machine.cyberpunk_machine_modules, module)
				module.on_install(restored_machine, null)
			else
				qdel(module)
	if(istype(restored_machine) && islist(entry["machine_parts"]))
		cyberpunk_persistent_restore_machine_parts(restored_machine, entry["machine_parts"], target_area, center, active_terminal)
		var/failure = entry["machine_failure"]
		if(failure in list("offline", "short", "jammed", "network", "unsafe", "wrong_function"))
			restored_machine.set_cyberpunk_failure_state(failure)
	var/obj/machinery/vending/restored_vendor = restored_atom
	if(istype(restored_vendor) && islist(entry["cyberpunk_vending_stock"]))
		restored_vendor.cyberpunk_corporate_markup_percent = clamp(entry["cyberpunk_corporate_markup"] || 0, -100, 500)
		for(var/list/stock_entry as anything in entry["cyberpunk_vending_stock"])
			for(var/datum/data/vending_product/record as anything in restored_vendor.product_records + restored_vendor.coin_records + restored_vendor.hidden_records)
				if(stock_entry["path"] ? "[record.product_path]" != stock_entry["path"] : record.name != stock_entry["name"])
					continue
				if(isnum(stock_entry["amount"]))
					record.amount = max(0, round(stock_entry["amount"]))
				var/list/saved_warehouse_items = stock_entry["warehouse_items"]
				if(islist(saved_warehouse_items))
					record.cyberpunk_warehouse_items = saved_warehouse_items.Copy()
				break
	if(islist(entry["contents"]))
		var/obj/machinery/reagentgrinder/grinder = restored_atom
		var/obj/item/reagent_containers/legacy_beaker
		var/beaker_candidates = 0
		for(var/list/content_entry as anything in entry["contents"])
			var/atom/movable/restored_content = cyberpunk_persistent_restore_movable(content_entry, restored_atom, target_area, center, active_terminal)
			if(!istype(grinder) || !istype(restored_content, /obj/item/reagent_containers))
				continue
			if(content_entry["machine_slot"] == "beaker")
				grinder.beaker = restored_content
			else if(!entry["has_machine_slots"] && restored_content.is_open_container())
				legacy_beaker = restored_content
				beaker_candidates++
		if(istype(grinder))
			if(!grinder.beaker && beaker_candidates == 1)
				grinder.beaker = legacy_beaker
			grinder.update_appearance(UPDATE_OVERLAYS)
	if(istype(vehicle) && islist(vehicle_record))
		vehicle.cyberpunk_after_persistent_restore(vehicle_record)
	return restored_atom

/proc/cyberpunk_persistent_restore_machine_parts(obj/machinery/machine, list/records, area/target_area, turf/center, obj/machinery/active_terminal)
	var/list/restored_parts = list()
	var/list/restored_wear = list()
	for(var/list/record as anything in records)
		var/datum/part
		if(record["stock_part"])
			var/stock_part_type = text2path(record["stock_part"])
			part = GLOB.stock_part_datums[stock_part_type]
		else if(ispath(text2path(record["type"]), /obj/item))
			part = cyberpunk_persistent_restore_movable(record, machine, target_area, center, active_terminal)
		if(!part)
			for(var/obj/item/temporary_part in restored_parts)
				qdel(temporary_part)
			return FALSE
		restored_parts += part
		if(isnum(record["wear"]) && record["wear"] > 0)
			restored_wear[part] = min(record["wear"], machine.cyberpunk_machine_wear_limit)

	var/list/initial_parts = machine.component_parts
	machine.component_parts = restored_parts
	var/obj/item/circuitboard/restored_board = locate() in restored_parts
	if(restored_board || (machine.circuit in initial_parts))
		machine.circuit = restored_board
	for(var/obj/item/initial_part in initial_parts)
		qdel(initial_part)
	machine.RefreshParts()
	machine.cyberpunk_component_wear = length(restored_wear) ? restored_wear : null
	machine.recalculate_cyberpunk_machine_wear()
	return TRUE

/proc/cyberpunk_persistent_restore_item(obj/item/item, list/entry)
	item.cyberpunk_quality = clamp(round(entry["item_quality"]), 1, 200)
	item.set_cyberpunk_manufacturer(entry["item_manufacturer"])
	item.set_resource_quality(entry["resource_quality"])
	item.cyberpunk_recovered_scrap = !!entry["recovered_scrap"]
	item.cyberpunk_scrap_analyzed = !!entry["scrap_analyzed"]
	var/list/materials = list()
	for(var/material_text in entry["item_materials"])
		var/material_path = text2path(material_text)
		var/quantity = entry["item_materials"][material_text]
		if(ispath(material_path, /datum/material) && isnum(quantity) && quantity > 0)
			materials[material_path] = quantity
	var/obj/item/stack/stack = item
	item.set_custom_materials(materials, istype(stack) ? stack.get_amount() : 1)
	var/obj/item/cyberpunk_item_module/module_item = item
	if(istype(module_item))
		module_item.module_tier = entry["module_tier"] || module_item.module_tier
		module_item.module_variant = entry["module_variant"] || module_item.module_variant
	var/obj/item/seeds/seed = item
	if(istype(seed) && islist(entry["plant_genetics"]))
		seed.cyberpunk_restore_genetics(entry["plant_genetics"])
	if(!islist(entry["item_modules"]))
		return
	for(var/datum/cyberpunk_item_module/installed as anything in item.cyberpunk_modules?.Copy())
		item.remove_cyberpunk_module(installed)
	item.cyberpunk_weapon_assembled = FALSE
	for(var/list/module_entry as anything in entry["item_modules"])
		var/module_path = text2path(module_entry["type"])
		if(!ispath(module_path, /datum/cyberpunk_item_module))
			continue
		var/datum/cyberpunk_item_module/module = new module_path
		module.quality = module_entry["quality"]
		module.manufacturer = module_entry["manufacturer"]
		module.module_tier = module_entry["tier"]
		module.module_variant = module_entry["variant"]
		module.apply_cyberpunk_module_variant()
		if(!item.install_cyberpunk_module(module, null))
			qdel(module)
	item.cyberpunk_weapon_assembled = !!entry["weapon_assembled"]
	if(item.cyberpunk_weapon_form)
		item.recalculate_cyberpunk_weapon_stats()
	else if(item.cyberpunk_equipment_form)
		item.recalculate_cyberpunk_equipment_stats()

/proc/cyberpunk_persistent_area_capture(area/target_area, obj/machinery/active_terminal)
	var/list/snapshot = list(
		"turfs" = list(),
		"movables" = list(),
	)
	var/turf/center = get_turf(active_terminal)
	if(!target_area || !center)
		return snapshot
	var/list/captured_vehicles = list()
	for(var/turf/area_turf as anything in cyberpunk_area_turfs(target_area))
		snapshot["turfs"] += list(list(
			"type" = "[area_turf.type]",
			"x" = area_turf.x - center.x,
			"y" = area_turf.y - center.y,
			"z" = area_turf.z - center.z,
		))
		for(var/atom/movable/thing as anything in area_turf.contents)
			var/list/entry = cyberpunk_persistent_capture_movable(thing, area_turf, center, active_terminal)
			if(entry)
				snapshot["movables"] += list(entry)
			var/obj/structure/cyberpunk_vehicle_parking/parking = thing
			if(istype(parking))
				for(var/list/parked_entry as anything in cyberpunk_persistent_capture_parked_vehicles(parking, target_area, center, active_terminal, captured_vehicles))
					snapshot["movables"] += list(parked_entry)
	return snapshot

/proc/cyberpunk_persistent_area_restore(area/target_area, obj/machinery/active_terminal, list/snapshot)
	if(!target_area || !active_terminal || !islist(snapshot))
		return 0
	var/turf/center = get_turf(active_terminal)
	if(!center)
		return 0
	for(var/turf/area_turf as anything in cyberpunk_area_turfs(target_area))
		for(var/atom/movable/thing as anything in area_turf.contents)
			if(thing == active_terminal || ismob(thing))
				continue
			qdel(thing)
	var/list/turf_entries = snapshot["turfs"]
	if(islist(turf_entries))
		for(var/list/entry as anything in turf_entries)
			var/turf_path = text2path("[entry["type"]]")
			if(!ispath(turf_path, /turf))
				continue
			var/turf/target = locate(clamp(center.x + (entry["x"] || 0), 1, world.maxx), clamp(center.y + (entry["y"] || 0), 1, world.maxy), clamp(center.z + (entry["z"] || 0), 1, world.maxz))
			if(!target || get_area(target) != target_area)
				continue
			target.ChangeTurf(turf_path, null, CHANGETURF_INHERIT_AIR)
	var/restored = 0
	var/list/movable_entries = snapshot["movables"]
	if(islist(movable_entries))
		for(var/list/entry as anything in movable_entries)
			var/movable_path = text2path("[entry["type"]]")
			if(!ispath(movable_path, /atom/movable))
				continue
			var/turf/target = locate(clamp(center.x + (entry["x"] || 0), 1, world.maxx), clamp(center.y + (entry["y"] || 0), 1, world.maxy), clamp(center.z + (entry["z"] || 0), 1, world.maxz))
			if(!target || get_area(target) != target_area)
				continue
			if(cyberpunk_persistent_restore_movable(entry, target, target_area, center, active_terminal))
				restored++
	return restored

/datum/preferences/proc/cyberpunk_write_persistent_area_records(preference_type, list/records)
	if(!write_preference(GLOB.preference_entries[preference_type], records))
		return FALSE
	recently_updated_keys |= preference_type
	save_character()
	save_preferences()
	return TRUE

/datum/preferences/proc/cyberpunk_store_persistent_area_record(preference_type, list/record)
	if(!islist(record) || !record["id"])
		return FALSE
	var/list/result = list()
	for(var/list/existing as anything in read_preference(preference_type) || list())
		if(existing["id"] == record["id"])
			continue
		result += list(existing)
	result = list(record) + result
	return cyberpunk_write_persistent_area_records(preference_type, result)

/mob/living/proc/cyberpunk_read_persistent_area_records(preference_type)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return list()
	return preferences.read_preference(preference_type) || list()

/mob/living/proc/cyberpunk_write_persistent_area_records(preference_type, list/records)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return FALSE
	return preferences.cyberpunk_write_persistent_area_records(preference_type, records)

/mob/living/proc/cyberpunk_store_persistent_area_record(preference_type, list/record)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return FALSE
	return preferences.cyberpunk_store_persistent_area_record(preference_type, record)

/mob/living/proc/cyberpunk_find_persistent_area_record(preference_type, record_id)
	if(!record_id)
		return null
	for(var/list/record as anything in cyberpunk_read_persistent_area_records(preference_type))
		if(record["id"] == record_id)
			return record
	return null

/proc/cyberpunk_persistent_access_id(kind, owner_character_key, area_type)
	return "persistent:[kind]:[owner_character_key]:[area_type]"

/datum/controller/subsystem/cyberpunk_property/proc/get_online_owner_preferences(owner_ckey)
	if(!owner_ckey)
		return null
	for(var/client/player_client as anything in GLOB.clients)
		if(player_client.ckey == owner_ckey)
			return player_client.prefs
	return null

/datum/controller/subsystem/cyberpunk_property/proc/autosave_persistent_properties()
	for(var/delivery_id in cyberpunk_business_deliveries)
		var/datum/cyberpunk_business_delivery/delivery = cyberpunk_business_deliveries[delivery_id]
		if(delivery?.status == "enroute" && delivery.arrival_time <= world.time)
			if(delivery.source_business_id)
				delivery.expire_warehouse_delivery()
			else
				delivery.complete_delivery()
	var/saved = 0
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(!business?.terminal)
			continue
		var/area/business_area = business.get_business_area()
		if(!business_area)
			continue
		var/datum/preferences/business_preferences = get_online_owner_preferences(business.owner_ckey)
		if(!business_preferences)
			continue
		business.saved_snapshot = cyberpunk_persistent_area_capture(business_area, business.terminal)
		business.saved_at = world.time
		if(business_preferences.cyberpunk_store_persistent_area_record(/datum/preference/cyberpunk_business_records, business.to_persistent_record()))
			business.add_history("round-end autosave captured [length(business.saved_snapshot["movables"])] object(s) and [length(business.saved_snapshot["turfs"])] turf(s)")
			saved++

	for(var/apartment_id in cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = cyberpunk_apartments[apartment_id]
		if(!apartment?.terminal)
			continue
		var/area/apartment_area = apartment.get_apartment_area()
		if(!apartment_area)
			continue
		var/datum/preferences/apartment_preferences = get_online_owner_preferences(apartment.owner_ckey)
		if(!apartment_preferences)
			continue
		apartment.saved_snapshot = cyberpunk_persistent_area_capture(apartment_area, apartment.terminal)
		apartment.saved_at = world.time
		if(apartment_preferences.cyberpunk_store_persistent_area_record(/datum/preference/cyberpunk_apartment_records, apartment.to_persistent_record()))
			apartment.add_history("round-end autosave captured [length(apartment.saved_snapshot["movables"])] object(s) and [length(apartment.saved_snapshot["turfs"])] turf(s)")
			saved++
	return saved
