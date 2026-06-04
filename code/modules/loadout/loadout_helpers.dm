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

	var/list/item_details = preference_source.read_preference(/datum/preference/loadout)
	var/list/loadout_datums = loadout_list_to_datums(item_details)
	// Slap our things into the outfit given
	for(var/datum/loadout_item/item as anything in loadout_datums)
		var/list/current_item_details = item_details?[item.item_path] || list()
		if(!item.is_equippable(src, current_item_details))
			loadout_datums -= item
			continue

		item.insert_path_into_outfit(equipped_outfit, src, visuals_only)
		var/amount = loadout_item_amount(current_item_details)
		if(amount > 1)
			for(var/index in 2 to amount)
				LAZYADD(equipped_outfit.backpack_contents, item.item_path)
	// Equip the outfit loadout items included
	if(!equipped_outfit.equip(src, visuals_only))
		return FALSE
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
