//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/repair
	id = CYBERPUNK_CONTRACT_REPAIR
	name = "Repair"


/datum/cyberpunk_contract_condition/repair/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	if(!contract || !user || !target || target.max_integrity <= 0)
		return FALSE
	if(!matches_atom(target))
		return FALSE
	if(target.get_integrity_percentage() * 100 < required_percent)
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[user.real_name || user.name] repaired [target] to [required_percent]% threshold")
	if(!contract.creator_confirm_required)
		contract.complete("repair threshold reached")
	return TRUE


/datum/cyberpunk_contract_condition/repair/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	for(var/atom/target in view(1, user))
		if(record_atom(contract, user, target))
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_repair(mob/living/user, atom/target)
	if(!user || !target || target.max_integrity <= 0)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_REPAIR)
			continue
		if(contract.try_record_atom_condition(CYBERPUNK_CONTRACT_REPAIR, user, target))
			return TRUE
		if(!contract.matches_target(target))
			continue
		if(target.get_integrity_percentage() * 100 < contract.required_percent)
			continue
		contract.add_history("[user.real_name || user.name] repaired [target] to contract threshold")
		if(!contract.creator_confirm_required)
			contract.complete("repair threshold reached")
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/check_nearby_repair_target(mob/living/user)
	for(var/atom/target in view(1, user))
		if(!matches_target(target))
			continue
		if(target.max_integrity <= 0)
			continue
		if(target.get_integrity_percentage() * 100 < required_percent)
			continue
		add_history("[user.real_name || user.name] verified repair on [target]")
		if(!creator_confirm_required)
			return complete("repair threshold reached")
		return TRUE
	return FALSE


