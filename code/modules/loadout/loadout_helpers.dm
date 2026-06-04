/**
 * Equips this mob with a given outfit and loadout items as per the passed preferences.
 *
 * Loadout items override the pre-existing item in the corresponding slot of the job outfit.
 * Some job items are preserved after being overridden - belt items, ear items, and glasses.
 * The rest of the slots, the items are overridden completely and deleted.
 *
 * Species with special outfits are snowflaked to have loadout items placed in their bags instead of overriding the outfit.
 *
 * * outfit - the job outfit we're equipping
 * * preference_source - the preferences to draw loadout items from.
 * * visuals_only - whether we call special equipped procs, or if we just look like we equipped it
 */
/mob/living/carbon/human/proc/equip_outfit_and_loadout(
	datum/outfit/outfit = /datum/outfit,
	datum/preferences/preference_source,
	visuals_only = FALSE,
)
	if(isnull(preference_source))
		return equipOutfit(outfit, visuals_only)

	var/datum/outfit/equipped_outfit
	if(ispath(outfit, /datum/outfit))
		equipped_outfit = new outfit()
	else if(istype(outfit, /datum/outfit))
		equipped_outfit = outfit
	else
		CRASH("Invalid outfit passed to equip_outfit_and_loadout ([outfit])")

	var/list/item_details = visuals_only && !isnull(preference_source.loadout_preview_override) ? preference_source.loadout_preview_override : preference_source.read_preference(/datum/preference/loadout)
	var/list/loadout_datums = loadout_list_to_datums(item_details)
	var/list/cyberpunk_assigned_loadout_items = list()
	// Slap our things into the outfit given
	for(var/datum/loadout_item/item as anything in loadout_datums)
		var/list/current_item_details = item_details?[item.item_path] || list()
		var/equip_slot = current_item_details[INFO_EQUIP_SLOT]
		if(!equip_slot && !visuals_only)
			cyberpunk_store_loadout_item_type_in_round_wardrobe(item.item_path, loadout_item_amount(current_item_details))
			loadout_datums -= item
			continue
		if(!item.is_equippable(src, current_item_details))
			loadout_datums -= item
			continue

		var/amount = loadout_item_amount(current_item_details)
		if(equip_slot == "bag")
			for(var/index in 1 to amount)
				LAZYADD(equipped_outfit.backpack_contents, item.item_path)
		else if(!visuals_only)
			cyberpunk_assigned_loadout_items += list(list(
				"item" = item,
				"details" = current_item_details,
				"slot" = equip_slot,
				"amount" = amount,
			))
		else
			item.insert_path_into_outfit(equipped_outfit, src, visuals_only)
			if(amount > 1)
				for(var/index in 2 to amount)
					LAZYADD(equipped_outfit.backpack_contents, item.item_path)
	// Equip the outfit loadout items included
	if(!equipped_outfit.equip(src, visuals_only))
		return FALSE
	if(!visuals_only)
		for(var/list/assignment as anything in cyberpunk_assigned_loadout_items)
			var/datum/loadout_item/item = assignment["item"]
			var/amount = assignment["amount"]
			var/slot_name = assignment["slot"]
			for(var/index in 1 to amount)
				cyberpunk_equip_loadout_item_to_named_slot(item.item_path, slot_name)
	// Handle any snowflake on_equips
	var/list/new_contents = get_all_gear(INCLUDE_PROSTHETICS|INCLUDE_ABSTRACT|INCLUDE_ACCESSORIES)
	var/list/processed_loadout_items = list()
	var/update = NONE
	for(var/datum/loadout_item/item as anything in loadout_datums)
		var/list/current_item_details = item_details?[item.item_path] || list()
		var/amount = loadout_item_amount(current_item_details)
		var/applied = 0
		for(var/obj/item/equipped_item as anything in new_contents)
			if(applied >= amount)
				break
			if(equipped_item in processed_loadout_items)
				continue
			if(!istype(equipped_item, item.item_path))
				continue

			processed_loadout_items += equipped_item
			applied++
			update |= item.on_equip_item(
				equipped_item = equipped_item,
				item_details = current_item_details,
				equipper = src,
				outfit = equipped_outfit,
				visuals_only = visuals_only,
			)
	if(update)
		update_clothing(update)

	return TRUE

/mob/living/carbon/human/proc/cyberpunk_equip_loadout_item_to_named_slot(item_path, equip_slot)
	if(!ispath(item_path, /obj/item))
		return FALSE
	var/obj/item/new_item = new item_path(get_turf(src))
	var/slot_id = cyberpunk_loadout_named_slot_to_item_slot(equip_slot)
	if(slot_id)
		var/obj/item/existing_item = get_item_by_slot(slot_id)
		if(existing_item)
			doUnEquip(existing_item, TRUE, get_turf(src), FALSE, invdrop = FALSE, silent = TRUE)
			qdel(existing_item)
		if(equip_to_slot_if_possible(new_item, slot_id, qdel_on_fail = FALSE, disable_warning = TRUE, initial = TRUE))
			return TRUE
	switch(equip_slot)
		if("hand_l")
			if(put_in_l_hand(new_item))
				return TRUE
		if("hand_r")
			if(put_in_r_hand(new_item))
				return TRUE
	if(put_in_hands(new_item))
		return TRUE
	new_item.forceMove(get_turf(src))
	return FALSE

/proc/cyberpunk_loadout_named_slot_to_item_slot(equip_slot)
	switch("[equip_slot]")
		if("head")
			return ITEM_SLOT_HEAD
		if("mask")
			return ITEM_SLOT_MASK
		if("glasses")
			return ITEM_SLOT_EYES
		if("ears")
			return ITEM_SLOT_EARS
		if("neck")
			return ITEM_SLOT_NECK
		if("uniform")
			return ITEM_SLOT_ICLOTHING
		if("suit")
			return ITEM_SLOT_OCLOTHING
		if("shoes")
			return ITEM_SLOT_FEET
		if("gloves")
			return ITEM_SLOT_GLOVES
		if("pocket_l")
			return ITEM_SLOT_LPOCKET
		if("pocket_r")
			return ITEM_SLOT_RPOCKET
		if("shoulder_l")
			return ITEM_SLOT_SHOULDER_LEFT
		if("shoulder_r")
			return ITEM_SLOT_SHOULDER_RIGHT
		if("finger")
			return ITEM_SLOT_FINGER
		if("bracers")
			return ITEM_SLOT_BRACERS
		if("pants")
			return ITEM_SLOT_PANTS
		if("chest")
			return ITEM_SLOT_CHEST
		if("undershirt")
			return ITEM_SLOT_UNDERSHIRT
		if("underwear")
			return ITEM_SLOT_UNDERWEAR
		if("tights")
			return ITEM_SLOT_TIGHTS
	return NONE

/// Returns the selected amount for a loadout entry.
/proc/loadout_item_amount(list/item_details)
	if(!islist(item_details))
		return 1
	var/raw_amount = item_details[INFO_AMOUNT]
	if(isnull(raw_amount))
		return 1
	var/amount = text2num("[raw_amount]")
	return max(1, FLOOR(amount, 1))

/**
 * Takes a list of paths (such as a loadout list)
 * and returns a list of their singleton loadout item datums
 *
 * loadout_list - the list being checked
 *
 * Returns a list of singleton datums
 */
/proc/loadout_list_to_datums(list/loadout_list) as /list
	var/list/datums = list()

	if(!length(GLOB.all_loadout_datums))
		CRASH("No loadout datums in the global loadout list!")

	for(var/path in loadout_list)
		var/actual_datum = GLOB.all_loadout_datums[path]
		if(!istype(actual_datum, /datum/loadout_item))
			stack_trace("Could not find ([path]) loadout item in the global list of loadout datums!")
			continue

		datums += actual_datum

	return datums
