//CYBERPUNK CORPORATIONS - Ryaznov service completion.
/obj/item/weldingtool/ryaznov_rivet
	name = "Ryaznov Rivet welder"
	desc = "A reinforced Ryaznov field welder built for rough salvage work."
	cyberpunk_manufacturer = "Ryaznov"
	cyberpunk_quality = 118
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 170

/obj/item/wrench/ryaznov_torque
	name = "Ryaznov Torque wrench"
	desc = "A heavy Ryaznov wrench with a stamped load rating."
	cyberpunk_manufacturer = "Ryaznov"
	cyberpunk_quality = 115
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 130

/obj/item/multitool/ryaznov_gridkey
	name = "Ryaznov Gridkey multitool"
	desc = "A Ryaznov diagnostic multitool intended for power grid tuning."
	cyberpunk_manufacturer = "Ryaznov"
	cyberpunk_quality = 122
	cyberpunk_rarity = "rare"
	cyberpunk_base_price = 260

/obj/item/crowbar/ryaznov_prybar
	name = "Ryaznov Prybar"
	desc = "A rugged Ryaznov crowbar with a reinforced industrial grip."
	cyberpunk_manufacturer = "Ryaznov"
	cyberpunk_quality = 116
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 125

/proc/cyberpunk_prepare_ryaznov_package(obj/item/storage/box/package, subscribed = FALSE)
	if(!package)
		return FALSE
	new /obj/item/weldingtool/ryaznov_rivet(package)
	new /obj/item/wrench/ryaznov_torque(package)
	new /obj/item/screwdriver(package)
	new /obj/item/stack/sheet/iron/five(package)
	if(subscribed)
		new /obj/item/crowbar/ryaznov_prybar(package)
		new /obj/item/multitool/ryaznov_gridkey(package)
		new /obj/item/stack/sheet/plasteel(package)
	return TRUE

/proc/cyberpunk_complete_ryaznov_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	cyberpunk_spawn_service_agent(corporation_id, service_id, user, corporation?.get_service_label(service_id))
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
		cyberpunk_prepare_ryaznov_package(package, corporation?.is_subscribed(user))
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
