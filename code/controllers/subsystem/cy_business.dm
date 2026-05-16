SUBSYSTEM_DEF(cy_business)
	name = "Cyberpunk Business"
	wait = 10 SECONDS
	priority = FIRE_PRIORITY_DEFAULT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	ss_flags = SS_BACKGROUND

	var/next_business_id = 1
	var/next_contract_id = 1
	var/list/businesses_by_id = list()
	var/list/contracts_by_id = list()
	var/list/open_contracts = list()
	var/list/business_zones = list()
	var/list/contract_ledger = list()

/datum/controller/subsystem/cy_business/Initialize()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cy_business/Recover()
	businesses_by_id = SScy_business.businesses_by_id
	contracts_by_id = SScy_business.contracts_by_id
	open_contracts = SScy_business.open_contracts
	business_zones = SScy_business.business_zones
	contract_ledger = SScy_business.contract_ledger
	next_business_id = SScy_business.next_business_id
	next_contract_id = SScy_business.next_contract_id

/datum/controller/subsystem/cy_business/fire(resumed = FALSE)
	for(var/contract_id in contracts_by_id)
		var/datum/cy_contract/contract = contracts_by_id[contract_id]
		if(!contract)
			continue
		contract.process_contract()

/datum/controller/subsystem/cy_business/stat_entry(msg)
	msg = "Businesses:[length(businesses_by_id)] Contracts:[length(contracts_by_id)] Open:[length(open_contracts)]"
	return ..()

/datum/controller/subsystem/cy_business/proc/register_zone(obj/structure/cy_business_zone/zone)
	if(!zone)
		return FALSE
	business_zones |= zone
	return TRUE

/datum/controller/subsystem/cy_business/proc/unregister_zone(obj/structure/cy_business_zone/zone)
	if(!zone)
		return FALSE
	business_zones -= zone
	return TRUE

/datum/controller/subsystem/cy_business/proc/register_business(datum/cy_business/business)
	if(!business)
		return FALSE
	if(!business.business_id)
		business.business_id = "BIZ-[next_business_id++]"
	businesses_by_id[business.business_id] = business
	return TRUE

/datum/controller/subsystem/cy_business/proc/unregister_business(datum/cy_business/business)
	if(!business?.business_id)
		return FALSE
	businesses_by_id -= business.business_id
	return TRUE

/datum/controller/subsystem/cy_business/proc/get_business(business_id)
	if(istype(business_id, /datum/cy_business))
		return business_id
	return businesses_by_id["[business_id]"]

/datum/controller/subsystem/cy_business/proc/create_business(name, owner_ckey, obj/structure/cy_business_zone/zone, legal_status = CY_BUSINESS_LEGAL, business_type = "general")
	if(!zone || zone.active_business)
		return null
	var/datum/cy_business/business = new
	business.name = name || "Unnamed Business"
	business.owner_ckey = owner_ckey
	business.legal_status = legal_status
	business.business_type = business_type
	business.size_type = zone.size_type
	business.zone_ref = REF(zone)
	business.zone_name = zone.name
	business.locate_zone = zone
	business.setup_account()
	register_business(business)
	zone.active_business = business
	return business

/datum/controller/subsystem/cy_business/proc/register_contract(datum/cy_contract/contract)
	if(!contract)
		return FALSE
	if(!contract.contract_id)
		contract.contract_id = "CON-[next_contract_id++]"
	contracts_by_id[contract.contract_id] = contract
	if(contract.status == CY_CONTRACT_STATUS_OPEN)
		open_contracts[contract.contract_id] = contract
	return TRUE

/datum/controller/subsystem/cy_business/proc/unregister_contract(datum/cy_contract/contract)
	if(!contract?.contract_id)
		return FALSE
	contracts_by_id -= contract.contract_id
	open_contracts -= contract.contract_id
	return TRUE

/datum/controller/subsystem/cy_business/proc/get_contract(contract_id)
	if(istype(contract_id, /datum/cy_contract))
		return contract_id
	return contracts_by_id["[contract_id]"]

/datum/controller/subsystem/cy_business/proc/create_contract(list/contract_data)
	var/datum/cy_contract/contract = new
	contract.load_from_list(contract_data)
	register_contract(contract)
	contract.open_contract()
	return contract

/datum/controller/subsystem/cy_business/proc/move_contract_to_ledger(datum/cy_contract/contract)
	if(!contract)
		return FALSE
	open_contracts -= contract.contract_id
	contract_ledger += list(contract.to_list())
	return TRUE
