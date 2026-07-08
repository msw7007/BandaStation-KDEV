//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/build
	id = CYBERPUNK_CONTRACT_BUILD
	name = "Construction"


/datum/cyberpunk_contract_condition/build/to_failure_ui_data(datum/cyberpunk_contract/contract)
	return list(
		"id" = "build_failure",
		"name" = "Construction missing",
		"description" = "Fails if the required object type is not present in the target area or coordinates before the deadline.",
	)


/datum/cyberpunk_contract_condition/build/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	if(!contract || !user || !target)
		return FALSE
	if(!matches_atom(target))
		return FALSE
	if(target.max_integrity > 0 && target.get_integrity_percentage() * 100 < required_percent)
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[user.real_name || user.name] constructed [target][target_area_text ? " in [target_area_text]" : ""]")
	if(!contract.creator_confirm_required)
		contract.complete("construction target built")
	return TRUE


/datum/cyberpunk_contract_condition/build/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	for(var/atom/target in view(1, user))
		if(record_atom(contract, user, target))
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_construction(mob/living/user, atom/target)
	if(!user || !target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_BUILD)
			continue
		if(contract.try_record_atom_condition(CYBERPUNK_CONTRACT_BUILD, user, target))
			return TRUE
		if(LAZYLEN(contract.completion_conditions))
			continue
		if(!contract.matches_target(target))
			continue
		contract.add_history("[user.real_name || user.name] constructed [target]")
		if(!contract.creator_confirm_required)
			contract.complete("construction target built")
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/check_nearby_build_target(mob/living/user)
	for(var/atom/target in view(1, user))
		if(!matches_target(target))
			continue
		add_history("[user.real_name || user.name] verified construction of [target]")
		if(!creator_confirm_required)
			return complete("construction target present")
		return TRUE
	return FALSE

