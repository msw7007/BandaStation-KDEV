//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/elimination
	id = CYBERPUNK_CONTRACT_ELIMINATION
	name = "Elimination"


/datum/cyberpunk_contract_condition/elimination/proc/matches_living_target(mob/living/target)
	if(!target)
		return FALSE
	if(!target_text)
		return TRUE
	return findtext(lowertext(target.real_name || target.name), lowertext(target_text))


/datum/cyberpunk_contract_condition/elimination/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	var/mob/living/living_target = target
	if(!istype(living_target) || !contract || !user)
		return FALSE
	if(!matches_living_target(living_target))
		return FALSE
	if(living_target.stat != DEAD && living_target.health > HEALTH_THRESHOLD_CRIT)
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[living_target.real_name || living_target.name] was eliminated by [user.real_name || user.name]")
	if(!contract.creator_confirm_required)
		contract.complete("target incapacitated")
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
		if(target.stat != DEAD && target.health > HEALTH_THRESHOLD_CRIT)
			continue
		contract.add_history("[target.real_name || target.name] was eliminated by [contract.contractor_name]")
		if(!contract.creator_confirm_required)
			contract.complete("target incapacitated")
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/check_nearby_elimination_target(mob/living/user)
	for(var/mob/living/target in GLOB.player_list)
		if(target_text && !findtext(lowertext(target.real_name || target.name), lowertext(target_text)))
			continue
		if(target.stat != DEAD && target.health > HEALTH_THRESHOLD_CRIT)
			continue
		add_history("[user.real_name || user.name] verified elimination of [target.real_name || target.name]")
		if(!creator_confirm_required)
			return complete("target incapacitated")
		return TRUE
	return FALSE


