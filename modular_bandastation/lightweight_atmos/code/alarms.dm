/proc/cloud_alarm_to_alarm_type(alarm_flags)
	. = list()
	if(alarm_flags & CLOUD_ALARM_FIRE)
		. += ALARM_FIRE
	if(alarm_flags & (CLOUD_ALARM_TOXIC | CLOUD_ALARM_COLD | CLOUD_ALARM_ACID | CLOUD_ALARM_CHEMICAL | CLOUD_ALARM_SMOKE | CLOUD_ALARM_OXYGEN_DANGER | CLOUD_ALARM_BIOHAZARD))
		. += ALARM_ATMOS

/proc/trigger_cloud_alarms(area/source, alarm_flags, obj/effect/gas_cloud/cloud)
	if(!isarea(source) || !alarm_flags)
		return
	var/list/alarm_types = cloud_alarm_to_alarm_type(alarm_flags)
	if(!length(alarm_types))
		return

	for(var/obj/machinery/airalarm/AA as anything in GLOB.air_alarms)
		if(QDELETED(AA) || get_area(AA) != source)
			continue
		if(AA.machine_stat & (NOPOWER|BROKEN))
			continue
		if(AA.shorted || !AA.alarm_manager)
			continue
		for(var/alarm_type in alarm_types)
			AA.alarm_manager.send_alarm(alarm_type, source)

	if(alarm_flags & CLOUD_ALARM_FIRE)
		for(var/obj/machinery/firealarm/FA as anything in source.firealarms)
			if(QDELETED(FA) || (FA.machine_stat & (NOPOWER|BROKEN)))
				continue
			if(source.fire)
				continue
			FA.alarm()
