//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/guard
	id = CYBERPUNK_CONTRACT_GUARD
	name = "Guard"
	var/protected_ref
	var/protected_start_area
	var/guard_started_at = 0
	var/last_verified_at = 0
	var/partial_payment_enabled = FALSE
	var/guard_kind = "target"
	var/datum/weakref/contract_ref
	var/datum/weakref/guarded_area_ref
	var/list/guarded_objects = list()


/datum/cyberpunk_contract_condition/guard/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_ref = reject_bad_text(params["target_ref"], max_length = 96, ascii_only = TRUE)
		if(new_ref)
			protected_ref = new_ref
		var/new_guard_kind = reject_bad_text(params["guard_kind"], max_length = 32, ascii_only = TRUE)
		if(new_guard_kind in list("target", "area", "cargo"))
			guard_kind = new_guard_kind
		partial_payment_enabled = text2num(params["partial_guard_payment"]) ? TRUE : FALSE


/datum/cyberpunk_contract_condition/guard/to_ui_data()
	. = ..()
	.["protectedRef"] = protected_ref
	.["guardKind"] = guard_kind
	.["guardStartedAt"] = guard_started_at
	.["lastVerifiedAt"] = last_verified_at
	.["partialPayment"] = partial_payment_enabled


/datum/cyberpunk_contract_condition/guard/to_failure_ui_data(datum/cyberpunk_contract/contract)
	return list(
		"id" = "guard_failure",
		"name" = "Protected target lost",
		"description" = "Fails if the protected target, area, or marked cargo is lost before the deadline.",
	)


/datum/cyberpunk_contract_condition/guard/on_accept(datum/cyberpunk_contract/contract, mob/living/user)
	guard_started_at = world.time
	contract_ref = WEAKREF(contract)
	if(guard_kind == "area")
		for(var/area/candidate as anything in GLOB.areas)
			if(target_area_text && lowertext(candidate.name) == lowertext(target_area_text))
				guarded_area_ref = WEAKREF(candidate)
				for(var/turf/tile as anything in candidate.get_turfs_from_all_zlevels())
					for(var/obj/structure/structure in tile)
						guarded_objects += WEAKREF(structure)
					for(var/obj/machinery/machine in tile)
						guarded_objects += WEAKREF(machine)
				break
	var/atom/target = find_protected_target()
	if(target)
		protected_ref = REF(target)
		var/area/target_area = get_area(target)
		protected_start_area = target_area?.name
		contract.add_history("guard target registered: [target] in [protected_start_area || "unknown area"]")
	monitor_guard()

/datum/cyberpunk_contract_condition/guard/proc/monitor_guard()
	var/datum/cyberpunk_contract/contract = contract_ref?.resolve()
	if(contract?.status != CYBERPUNK_CONTRACT_ACCEPTED)
		return
	if(!target_safe())
		var/elapsed = max(0, world.time - guard_started_at)
		var/total = max(1, contract.due_time - guard_started_at)
		contract.fail("guard target lost", partial_payment_enabled ? clamp(elapsed / total, 0, 1) : 0)
		return
	last_verified_at = world.time
	addtimer(CALLBACK(src, PROC_REF(monitor_guard)), 2 SECONDS)


/datum/cyberpunk_contract_condition/guard/proc/find_protected_target()
	if(protected_ref)
		var/atom/by_ref = locate(protected_ref)
		return by_ref
	for(var/mob/living/person as anything in GLOB.mob_living_list)
		if(target_text && findtext(lowertext(person.real_name || person.name), lowertext(target_text)))
			return person
	if(guard_kind == "cargo")
		for(var/obj/item/item as anything in world)
			if(matches_target_text(item))
				return item
	for(var/obj/machinery/thing as anything in SSmachines.get_all_machines())
		if(matches_target_text(thing))
			return thing
	return null


/datum/cyberpunk_contract_condition/guard/proc/target_safe()
	if(guard_kind == "area")
		var/area/guarded_area = guarded_area_ref?.resolve()
		if(!guarded_area || !length(guarded_area.get_turfs_from_all_zlevels()))
			return FALSE
		var/intact = 0
		for(var/datum/weakref/object_ref as anything in guarded_objects)
			var/atom/object = object_ref.resolve()
			if(object && get_area(object) == guarded_area && (!object.uses_integrity || object.get_integrity_percentage() > 0))
				intact++
		return !length(guarded_objects) || intact * 100 >= length(guarded_objects) * required_percent
	var/atom/target = find_protected_target()
	if(!target || QDELETED(target))
		return FALSE
	if(!matches_location(target))
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		return living_target.stat != DEAD && living_target.health > HEALTH_THRESHOLD_CRIT
	if(target.uses_integrity && target.get_integrity_percentage() <= 0)
		return FALSE
	return TRUE


/datum/cyberpunk_contract_condition/guard/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	if(!target_safe())
		return FALSE
	last_verified_at = world.time
	contract.add_history("[user.real_name || user.name] verified guard target status")
	return TRUE


/datum/cyberpunk_contract_condition/guard/on_timeout(datum/cyberpunk_contract/contract)
	if(contract.status != CYBERPUNK_CONTRACT_ACCEPTED)
		return FALSE
	if(target_safe())
		delivered_amount = required_amount
		contract.delivered_amount = required_amount
		return contract.complete("guard duty completed")
	var/elapsed = max(world.time - guard_started_at, 0)
	var/total = max(contract.due_time - guard_started_at, 1)
	var/partial = partial_payment_enabled ? clamp(elapsed / total, 0, 0.75) : 0
	return contract.fail("guard target lost before deadline", partial)


/datum/cyberpunk_contract/proc/check_guard_status(mob/living/user)
	for(var/datum/cyberpunk_contract_condition/guard/condition as anything in completion_conditions)
		if(condition.check_nearby(src, user))
			return TRUE
	return FALSE
