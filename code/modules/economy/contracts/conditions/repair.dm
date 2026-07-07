//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/repair
	id = CYBERPUNK_CONTRACT_REPAIR
	name = "Repair"
	var/repair_mode = "integrity"


/datum/cyberpunk_contract_condition/repair/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_mode = reject_bad_text(params["repair_mode"], max_length = 32, ascii_only = TRUE)
		if(new_mode in list("integrity", "functional"))
			repair_mode = new_mode


/datum/cyberpunk_contract_condition/repair/to_ui_data()
	. = ..()
	.["repairMode"] = repair_mode


/datum/cyberpunk_contract_condition/repair/to_failure_ui_data(datum/cyberpunk_contract/contract)
	return list(
		"id" = "repair_failure",
		"name" = "Repair not restored",
		"description" = "Fails if the target is not restored above the required integrity or functionality threshold before the deadline.",
	)


/datum/cyberpunk_contract_condition/repair/proc/target_repaired(atom/target)
	if(!target)
		return FALSE
	if(repair_mode == "functional")
		if(ismachinery(target))
			var/obj/machinery/machine = target
			return !(machine.machine_stat & (BROKEN|NOPOWER|MAINT))
		if("functional" in target.vars)
			return !!target.vars["functional"]
	if(target.max_integrity <= 0)
		return FALSE
	return target.get_integrity_percentage() * 100 >= required_percent


/datum/cyberpunk_contract_condition/repair/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	if(!contract || !user || !target)
		return FALSE
	if(!matches_atom(target))
		return FALSE
	if(!target_repaired(target))
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[user.real_name || user.name] repaired [target] to [repair_mode] threshold")
	if(!contract.creator_confirm_required)
		contract.complete("repair threshold reached")
	return TRUE


/datum/cyberpunk_contract_condition/repair/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	for(var/atom/target in view(1, user))
		if(record_atom(contract, user, target))
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_repair(mob/living/user, atom/target)
	if(!user || !target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_REPAIR)
			continue
		if(contract.try_record_atom_condition(CYBERPUNK_CONTRACT_REPAIR, user, target))
			return TRUE
		if(LAZYLEN(contract.completion_conditions))
			continue
		if(!contract.matches_target(target))
			continue
		if(target.max_integrity <= 0 || target.get_integrity_percentage() * 100 < contract.required_percent)
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
