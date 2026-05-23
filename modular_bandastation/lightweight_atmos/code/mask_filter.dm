// ============================================================================
// Mask filter resolution.
//
// Old system: mask.consume_filter(breath) destructively edited a gas_mixture.
// New system: mask exposes a list of filter tags (GAS_FILTER_*); the cloud
// processor checks whether the wearer's full tag-set covers the gas effect.
// ============================================================================

/// Default: no filtering. Subtypes override.
/obj/item/clothing/mask/proc/get_filter_tags()
	return null

// Replace the default body of mask.consume_filter() with a no-op that returns
// the breath unchanged. The new gas-cloud system handles filtering instead.
/obj/item/clothing/mask/consume_filter(datum/gas_mixture/breath)
	return breath

/// Gas masks with filters installed protect against the tags listed in
/// `filter_tags_when_loaded`. Empty filter slot → no protection.
/obj/item/clothing/mask/gas
	var/list/filter_tags_when_loaded = list(
		GAS_FILTER_PARTICLE,
		GAS_FILTER_TOXIC,
		GAS_FILTER_CHEMICAL,
	)

/obj/item/clothing/mask/gas/get_filter_tags()
	if(has_filter && length(gas_filters))
		return filter_tags_when_loaded
	return null

// Sealed military / EOD variants ship with full filters by default and protect
// against everything except heat/cold.
/obj/item/clothing/mask/gas/sechailer
	filter_tags_when_loaded = list(
		GAS_FILTER_PARTICLE,
		GAS_FILTER_TOXIC,
		GAS_FILTER_CHEMICAL,
		GAS_FILTER_CO2,
		GAS_FILTER_N2O,
	)

// Plasmaman breath mask doesn't filter ambient gas — it just supplies plasma.
// Handled implicitly via internals.

