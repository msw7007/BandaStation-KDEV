// ============================================================================
// atmos_sensitive shim.
//
// Old flow:
//   /turf/open processed in SSair -> COMSIG_TURF_EXPOSE -> check_atmos_process
//   queues atom into SSair.atom_process -> later SSair fires atom.process_exposure
//   -> atmos_expose(air, temp).
//
// New flow:
//   SSgas_effects fires COMSIG_TURF_EXPOSE on the cloud's turf each tick
//   (for clouds with temperature_delta). Our override of check_atmos_process
//   runs atmos_expose synchronously — no SSair.atom_process queue.
//
// Net result: bonfires, thermite, combustible items and other
// atmos_sensitive consumers still react to heat/cold, just driven by the
// lightweight cloud system rather than per-turf gas physics.
// ============================================================================

/atom/check_atmos_process(datum/source, datum/gas_mixture/air, exposed_temperature)
	SIGNAL_HANDLER
	if(!should_atmos_process(air, exposed_temperature))
		return
	atmos_expose(air, exposed_temperature)
