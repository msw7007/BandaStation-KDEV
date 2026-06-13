//CYBERPUNK CORPORATIONS - Ryaznov service completion.
/proc/cyberpunk_complete_ryaznov_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/repair_amount = corporation?.is_subscribed(user) ? 80 : 45
	if(service_id == "fortify")
		repair_amount *= 0.5
	var/atom/repair_target
	for(var/atom/candidate as anything in range(1, user))
		if(candidate == user || candidate.max_integrity <= 0 || candidate.get_integrity() >= candidate.max_integrity)
			continue
		repair_target = candidate
		break
	if(service_id == "salvage")
		var/obj/item/storage/box/package = new(get_turf(user))
		package.name = "Ryaznov salvage pack"
		if(hascall(package, "set_cyberpunk_manufacturer"))
			call(package, "set_cyberpunk_manufacturer")("Ryaznov")
		if(!user.put_in_hands(package))
			package.forceMove(get_turf(user))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov salvage service completed")
		to_chat(user, span_notice("Ryaznov salvage service delivers an industrial pack."))
		return TRUE
	if(service_id == "power")
		for(var/obj/machinery/nearby_machine in range(1, user))
			nearby_machine.repair_cyberpunk_machine_wear(repair_amount, user)
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov power service completed")
		to_chat(user, span_notice("Ryaznov power tuning refreshes nearby machinery components."))
		return TRUE
	if(!repair_target)
		to_chat(user, span_warning("Ryaznov field service finds no damaged nearby object."))
		return FALSE
	var/applied_repair = repair_target.repair_damage(repair_amount)
	var/obj/machinery/repaired_machine = repair_target
	if(istype(repaired_machine))
		repaired_machine.repair_cyberpunk_machine_wear(repair_amount, user)
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", max(1, round(applied_repair / 10)), 0, "Ryaznov service completed: [service_id]")
	to_chat(user, span_notice("Ryaznov field service repairs [repair_target] by [applied_repair] integrity."))
	return TRUE
