//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/sabotage
	id = CYBERPUNK_CONTRACT_SABOTAGE
	name = "Sabotage"
	var/sabotage_mode = "damage"


/datum/cyberpunk_contract_condition/sabotage/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_mode = reject_bad_text(params["sabotage_mode"], max_length = 32, ascii_only = TRUE)
		if(new_mode in list("damage", "disabled", "hacked", "destroyed", "unpowered", "broken", "emagged"))
			sabotage_mode = new_mode


/datum/cyberpunk_contract_condition/sabotage/to_ui_data()
	. = ..()
	.["sabotageMode"] = sabotage_mode


/datum/cyberpunk_contract_condition/sabotage/proc/target_sabotaged(atom/target)
	if(!target)
		return FALSE
	if(sabotage_mode in list("damage", "destroyed"))
		if(target.max_integrity <= 0)
			return FALSE
		var/integrity_percent = target.get_integrity_percentage() * 100
		if(sabotage_mode == "destroyed")
			return integrity_percent <= 0
		return integrity_percent <= required_percent
	if(sabotage_mode == "disabled")
		if(ismachinery(target))
			var/obj/machinery/machine = target
			return !!(machine.machine_stat & (BROKEN|NOPOWER|EMPED|MAINT))
		if("disabled" in target.vars)
			return !!target.vars["disabled"]
		return FALSE
	if(sabotage_mode == "unpowered")
		if(ismachinery(target))
			var/obj/machinery/machine = target
			return !!(machine.machine_stat & NOPOWER)
		return FALSE
	if(sabotage_mode == "broken")
		if(ismachinery(target))
			var/obj/machinery/machine = target
			return !!(machine.machine_stat & BROKEN)
		if(target.max_integrity > 0)
			return target.get_integrity_percentage() <= 0
		return FALSE
	if(sabotage_mode == "hacked")
		if(isobj(target))
			var/obj/target_obj = target
			if(target_obj.obj_flags & EMAGGED)
				return TRUE
		return ("hacked" in target.vars) && !!target.vars["hacked"]
	if(sabotage_mode == "emagged")
		if(isobj(target))
			var/obj/target_obj = target
			return !!(target_obj.obj_flags & EMAGGED)
		return FALSE
	return FALSE


/datum/cyberpunk_contract_condition/sabotage/record_atom(datum/cyberpunk_contract/contract, mob/living/user, atom/target)
	if(!contract || !user || !target)
		return FALSE
	if(!matches_atom(target))
		return FALSE
	if(!target_sabotaged(target))
		return FALSE
	delivered_amount = required_amount
	contract.add_history("[user.real_name || user.name] sabotaged [target] ([sabotage_mode])")
	if(!contract.creator_confirm_required)
		contract.complete("sabotage condition reached")
	return TRUE


/datum/cyberpunk_contract_condition/sabotage/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	for(var/atom/target in view(1, user))
		if(record_atom(contract, user, target))
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_sabotage(mob/living/user, atom/target)
	if(!user || !target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_SABOTAGE)
			continue
		if(contract.try_record_atom_condition(CYBERPUNK_CONTRACT_SABOTAGE, user, target))
			return TRUE
		if(target.max_integrity <= 0)
			continue
		if(!contract.matches_target(target))
			continue
		if(target.get_integrity_percentage() * 100 > contract.required_percent)
			continue
		contract.add_history("[user.real_name || user.name] sabotaged [target] to contract threshold")
		if(!contract.creator_confirm_required)
			contract.complete("sabotage threshold reached")
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/check_nearby_sabotage_target(mob/living/user)
	for(var/atom/target in view(1, user))
		if(!matches_target(target))
			continue
		if(target.max_integrity <= 0)
			continue
		if(target.get_integrity_percentage() * 100 > required_percent)
			continue
		add_history("[user.real_name || user.name] verified sabotage on [target]")
		if(!creator_confirm_required)
			return complete("sabotage threshold reached")
		return TRUE
	return FALSE


