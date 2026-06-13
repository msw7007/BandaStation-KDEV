//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/guard
	id = CYBERPUNK_CONTRACT_GUARD
	name = "Guard"
	var/protected_ref
	var/protected_start_area
	var/guard_started_at = 0
	var/last_verified_at = 0
	var/partial_payment_enabled = FALSE


/datum/cyberpunk_contract_condition/guard/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_ref = reject_bad_text(params["target_ref"], max_length = 96, ascii_only = TRUE)
		if(new_ref)
			protected_ref = new_ref
		partial_payment_enabled = text2num(params["partial_guard_payment"]) ? TRUE : FALSE


/datum/cyberpunk_contract_condition/guard/to_ui_data()
	. = ..()
	.["protectedRef"] = protected_ref
	.["guardStartedAt"] = guard_started_at
	.["lastVerifiedAt"] = last_verified_at
	.["partialPayment"] = partial_payment_enabled


/datum/cyberpunk_contract_condition/guard/on_accept(datum/cyberpunk_contract/contract, mob/living/user)
	guard_started_at = world.time
	var/atom/target = find_protected_target()
	if(target)
		var/area/target_area = get_area(target)
		protected_start_area = target_area?.name
		contract.add_history("guard target registered: [target] in [protected_start_area || "unknown area"]")


/datum/cyberpunk_contract_condition/guard/proc/find_protected_target()
	if(protected_ref)
		var/atom/by_ref = locate(protected_ref)
		if(by_ref)
			return by_ref
	for(var/mob/living/person as anything in GLOB.player_list)
		if(target_text && findtext(lowertext(person.real_name || person.name), lowertext(target_text)))
			return person
	for(var/obj/machinery/thing as anything in SSmachines.get_all_machines())
		if(matches_target_text(thing))
			return thing
	return null


/datum/cyberpunk_contract_condition/guard/proc/target_safe()
	var/atom/target = find_protected_target()
	if(!target || QDELETED(target))
		return FALSE
	if(!matches_location(target))
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		return living_target.stat != DEAD && living_target.health > HEALTH_THRESHOLD_CRIT
	if(target.max_integrity > 0 && target.get_integrity_percentage() <= 0)
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
