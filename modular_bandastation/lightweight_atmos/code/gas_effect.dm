// ============================================================================
// /datum/gas_effect — singleton "type of dangerous gas".
//
// One instance per effect type, cached in SSgas_effects.effect_singletons by
// path. Concrete subtypes live in gas_effect_types.dm.
// ============================================================================

/datum/gas_effect
	/// Stable identifier (e.g. "tox", "fire", "smoke").
	var/id = "abstract"
	/// Display name shown by scanners and admin tools.
	var/name = "gas"
	/// RGB hex for the cloud overlay.
	var/color = "#888888"
	/// Cloud icon state; defaults to "cloud".
	var/icon_state = "cloud"

	/// Density behaviour for Z-spread (see GAS_DENSITY_*).
	var/density_type = GAS_DENSITY_NEUTRAL

	/// Amount below which the cloud cannot spread to a neighbour.
	var/spread_threshold = 5
	/// Fraction of cloud amount that flows into a chosen neighbour per spread tick.
	var/spread_rate = 0.4
	/// Per-second decay applied by the subsystem.
	var/decay_rate = 1
	/// Per-second on-turf temperature delta (informational; not a physical sim).
	var/temperature_delta = 0

	/// Filter tags this effect carries. Masks/internals matching ALL listed
	/// tags (or GAS_FILTER_ANY) fully block on_breathe.
	var/list/filter_tags

	/// Whether the cloud renders an overlay on the turf.
	var/visible = TRUE
	/// Whether this gas can persist in a water-environment turf.
	var/affects_underwater = FALSE
	/// Whether moving through the cloud (Crossed) triggers on_touch immediately.
	var/touch_on_cross = TRUE

/datum/gas_effect/New()
	. = ..()
	if(!filter_tags)
		filter_tags = list()

/// Effect applied per processing tick to a mob breathing this cloud.
/// `amount` is the cloud's current strength (already capped via the cloud).
/datum/gas_effect/proc/on_breathe(mob/living/carbon/breather, amount, seconds_per_tick)
	return

/// Effect applied when a movable enters or stands on the cloud.
/datum/gas_effect/proc/on_touch(atom/movable/AM, amount, seconds_per_tick)
	return

/// Optional hook called when the cloud's amount decays.
/datum/gas_effect/proc/on_decay(turf/T, amount)
	return

/// Whether a wearer with the given filter-tag list is fully protected.
/datum/gas_effect/proc/is_filtered_by(list/tags)
	if(!length(tags) || !length(filter_tags))
		return FALSE
	if(GAS_FILTER_ANY in tags)
		return TRUE
	for(var/tag in filter_tags)
		if(!(tag in tags))
			return FALSE
	return TRUE
