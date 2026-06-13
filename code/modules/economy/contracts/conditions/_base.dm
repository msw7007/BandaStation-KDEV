//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition
	var/id = "generic"
	var/name = "Condition"
	var/description = ""
	var/target_text = ""
	var/target_area_text = ""
	var/target_x = 0
	var/target_y = 0
	var/target_z = 0
	var/coordinate_radius = 0
	var/required_amount = 1
	var/delivered_amount = 0
	var/required_percent = 75
	var/minimum_quality = 0
	var/minimum_rarity = 0


/datum/cyberpunk_contract_condition/proc/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	if(!contract)
		return
	target_text = contract.target_text
	required_amount = contract.required_amount
	delivered_amount = contract.delivered_amount
	required_percent = contract.required_percent
	if(params)
		var/new_area = reject_bad_text(params["target_area"], max_length = 64, ascii_only = FALSE)
		if(new_area)
			target_area_text = new_area
		target_x = round(text2num(params["target_x"]))
		target_y = round(text2num(params["target_y"]))
		target_z = round(text2num(params["target_z"]))
		coordinate_radius = max(0, round(text2num(params["target_radius"])))
		minimum_quality = max(0, round(text2num(params["minimum_quality"])))
		minimum_rarity = max(0, round(text2num(params["minimum_rarity"])))


/datum/cyberpunk_contract_condition/proc/to_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"target" = target_text,
		"targetArea" = target_area_text,
		"targetX" = target_x,
		"targetY" = target_y,
		"targetZ" = target_z,
		"targetRadius" = coordinate_radius,
		"requiredAmount" = required_amount,
		"deliveredAmount" = delivered_amount,
		"requiredPercent" = required_percent,
		"minimumQuality" = minimum_quality,
		"minimumRarity" = minimum_rarity,
	)


/datum/cyberpunk_contract_condition/proc/matches_target_text(atom/target)
	if(!target)
		return FALSE
	if(!target_text)
		return TRUE
	var/normalized_target = lowertext(target_text)
	return findtext(lowertext(target.name), normalized_target) || findtext(lowertext("[target.type]"), normalized_target)


/datum/cyberpunk_contract_condition/proc/matches_area(atom/target)
	if(!target_area_text)
		return TRUE
	var/area/target_area = get_area(target)
	return target_area && findtext(lowertext(target_area.name), lowertext(target_area_text))


/datum/cyberpunk_contract_condition/proc/matches_coordinates(atom/target)
	if(!target_x && !target_y && !target_z)
		return TRUE
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE
	if(target_z && target_turf.z != target_z)
		return FALSE
	if(target_x && abs(target_turf.x - target_x) > coordinate_radius)
		return FALSE
	if(target_y && abs(target_turf.y - target_y) > coordinate_radius)
		return FALSE
	return TRUE


/datum/cyberpunk_contract_condition/proc/matches_location(atom/target)
	return matches_area(target) && matches_coordinates(target)


/datum/cyberpunk_contract_condition/proc/matches_atom(atom/target)
	return matches_target_text(target) && matches_location(target)


/datum/cyberpunk_contract_condition/proc/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	return FALSE


/datum/cyberpunk_contract_condition/proc/record_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item)
	return FALSE


/datum/cyberpunk_contract_condition/proc/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	return FALSE


/datum/cyberpunk_contract_condition/proc/on_accept(datum/cyberpunk_contract/contract, mob/living/user)
	return


/datum/cyberpunk_contract_condition/proc/on_timeout(datum/cyberpunk_contract/contract)
	return FALSE


/datum/cyberpunk_contract_condition/proc/get_item_amount(obj/item/item)
	if(isstack(item))
		var/obj/item/stack/stack = item
		return stack.amount
	return 1


/datum/cyberpunk_contract_condition/proc/get_item_quality(obj/item/item)
	if(!item)
		return 0
	if("quality" in item.vars)
		return item.vars["quality"] || 0
	if("resource_quality" in item.vars)
		return item.vars["resource_quality"] || 0
	if("cyberpunk_quality" in item.vars)
		return item.vars["cyberpunk_quality"] || 0
	return 0


/datum/cyberpunk_contract_condition/proc/get_item_rarity(obj/item/item)
	if(!item)
		return 0
	if("rarity" in item.vars)
		return item.vars["rarity"] || 0
	if("resource_rarity" in item.vars)
		return item.vars["resource_rarity"] || 0
	if("cyberpunk_rarity" in item.vars)
		return item.vars["cyberpunk_rarity"] || 0
	return 0


/datum/cyberpunk_contract_condition/proc/item_meets_quality(obj/item/item)
	return get_item_quality(item) >= minimum_quality && get_item_rarity(item) >= minimum_rarity
