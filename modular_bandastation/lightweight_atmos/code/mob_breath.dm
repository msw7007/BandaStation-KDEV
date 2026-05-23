// ============================================================================
// Mob-side breath helpers.
//
// New flow:
//   /mob/living/carbon/breathe(spt) — replaced in stubs/breathing_stub.dm
//     1. Decide environment (vacuum / water / normal / internals)
//     2. On normal/internals: call apply_active_gas_clouds(spt)
//     3. On vacuum: increment losebreath
//     4. On water: handle holding_breath status effect
// ============================================================================

/// Compute the set of filter tags this mob currently carries (mask, internals,
/// species traits, hardsuit). The set is consulted by gas_effect.is_filtered_by.
/mob/living/carbon/proc/get_breath_filter_tags()
	var/list/tags = list()

	// Universal trait (godmode-style).
	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		tags |= GAS_FILTER_ANY
		return tags

	// Internals tank — supplies clean air, blocks everything.
	if(internal || external)
		tags |= GAS_FILTER_ANY
		return tags

	// Mask filter
	var/obj/item/clothing/mask/M = wear_mask
	if(istype(M))
		var/list/mask_tags = M.get_filter_tags()
		if(length(mask_tags))
			tags |= mask_tags

	// Sealed suit (hazmat / RIG) — extend later
	return tags

/// Look at every gas cloud on the current turf and apply on_breathe.
/mob/living/carbon/proc/apply_active_gas_clouds(seconds_per_tick)
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/has_clouds = FALSE
	for(var/obj/effect/gas_cloud/cloud in T)
		has_clouds = TRUE
		break
	if(!has_clouds)
		return
	var/list/blocked = get_breath_filter_tags()
	for(var/obj/effect/gas_cloud/cloud in T)
		if(QDELETED(cloud) || !cloud.effect)
			continue
		if(cloud.effect.is_filtered_by(blocked))
			continue
		cloud.effect.on_breathe(src, cloud.amount, seconds_per_tick)
