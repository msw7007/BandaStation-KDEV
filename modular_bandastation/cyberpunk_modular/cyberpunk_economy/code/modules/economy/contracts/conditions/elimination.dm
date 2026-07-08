//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/elimination
	id = CYBERPUNK_CONTRACT_ELIMINATION
	name = "Elimination"
	var/elimination_mode = "critical"


/datum/cyberpunk_contract_condition/elimination/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_mode = reject_bad_text(params["elimination_mode"], max_length = 32, ascii_only = TRUE)
		if(new_mode in list("critical", "dead", "incapacitated", "removed"))
			elimination_mode = new_mode


/datum/cyberpunk_contract_condition/elimination/to_ui_data()
	. = ..()
	.["eliminationMode"] = elimination_mode


/datum/cyberpunk_contract_condition/elimination/to_failure_ui_data(datum/cyberpunk_contract/contract)
	return list(
		"id" = "elimination_failure",
		"name" = "Target not eliminated",
		"description" = "Fails if the target is not killed, critically wounded, incapacitated, or removed from the round as required before the deadline.",
	)


/datum/cyberpunk_contract_condition/elimination/proc/matches_living_target(mob/living/target)
	if(!target)
		return FALSE
	if(!target_text)
		return TRUE
	return findtext(lowertext(target.real_name || target.name), lowertext(target_text))


/datum/cyberpunk_contract_condition/elimination/proc/target_eliminated(mob/living/target)
	if(!target)
		return FALSE
	if(elimination_mode == "dead")
		return target.stat == DEAD
	if(elimination_mode == "removed")
		return target.stat == DEAD || !target.mind || target.mind.current != target
	if(elimination_mode == "incapacitated")
		return target.stat == DEAD || target.health <= HEALTH_THRESHOLD_CRIT
	return target.stat == DEAD || target.health <= HEALTH_THRESHOLD_CRIT


/datum/cyberpunk_contract_condition/elimination/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	var/mob/living/living_target = target
	if(!istype(living_target) || !contract || !user)
		return FALSE
	if(!matches_living_target(living_target))
		return FALSE
	if(!target_eliminated(living_target))
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[living_target.real_name || living_target.name] was eliminated by [user.real_name || user.name]")
	if(!contract.creator_confirm_required)
		contract.complete("target [elimination_mode]")
	return TRUE


/datum/cyberpunk_contract_condition/elimination/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	for(var/mob/living/target in GLOB.player_list)
		if(record_atom(contract, user, target))
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_elimination(mob/living/target)
	if(!target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_ELIMINATION)
			continue
		if(contract.contractor_ckey != target.lastattackerckey)
			continue
		var/mob/living/contractor = SSeconomy.find_cyberpunk_contract_person(contract.contractor_name)
		if(contractor && contract.try_record_atom_condition(CYBERPUNK_CONTRACT_ELIMINATION, contractor, target))
			return TRUE
		if(contract.target_text && !findtext(lowertext(target.real_name || target.name), lowertext(contract.target_text)))
			continue
		var/datum/cyberpunk_contract_condition/elimination/condition
		for(var/datum/cyberpunk_contract_condition/elimination/potential as anything in contract.completion_conditions)
			condition = potential
			break
		if(condition && !condition.target_eliminated(target))
			continue
		if(!condition && target.stat != DEAD && target.health > HEALTH_THRESHOLD_CRIT)
			continue
		contract.add_history("[target.real_name || target.name] was eliminated by [contract.contractor_name]")
		if(!contract.creator_confirm_required)
			contract.complete("target eliminated")
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/check_nearby_elimination_target(mob/living/user)
	for(var/mob/living/target in GLOB.player_list)
		if(target_text && !findtext(lowertext(target.real_name || target.name), lowertext(target_text)))
			continue
		for(var/datum/cyberpunk_contract_condition/elimination/condition as anything in completion_conditions)
			if(condition.record_atom(src, user, target))
				return TRUE
	return FALSE

