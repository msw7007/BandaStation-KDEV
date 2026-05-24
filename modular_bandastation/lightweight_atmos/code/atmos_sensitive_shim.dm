/atom/check_atmos_process(datum/source, datum/gas_mixture/air, exposed_temperature)
	if(!should_atmos_process(air, exposed_temperature))
		return
	atmos_expose(air, exposed_temperature)
