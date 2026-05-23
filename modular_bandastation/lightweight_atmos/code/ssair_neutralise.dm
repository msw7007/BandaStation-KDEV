// ============================================================================
// Modular overrides for SSair active-turf registration.
//
// `add_to_active(turf)` and `remove_from_active(turf)` are declared as procs
// in code/controllers/subsystem/air.dm but aren't overridden anywhere. We
// turn them into no-ops so legacy callers (turf init, assume_air,
// remove_air, hotspot_expose path) don't accumulate work in active_turfs.
// ============================================================================

/datum/controller/subsystem/air/add_to_active(turf/open/activate, blockchanges = FALSE)
	return

/datum/controller/subsystem/air/remove_from_active(turf/open/T)
	return
