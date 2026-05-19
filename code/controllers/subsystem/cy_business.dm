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
	var/list/warehouses = list()

/datum/controller/subsystem/cy_business/Initialize()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cy_business/Recover()
	businesses_by_id = SScy_business.businesses_by_id
	contracts_by_id = SScy_business.contracts_by_id
	open_contracts = SScy_business.open_contracts
	business_zones = SScy_business.business_zones
	contract_ledger = SScy_business.contract_ledger
	warehouses = SScy_business.warehouses
	next_business_id = SScy_business.next_business_id
	next_contract_id = SScy_business.next_contract_id

/datum/controller/subsystem/cy_business/fire(resumed = FALSE)
	for(var/contract_id in contracts_by_id)
		var/datum/cy_contract/contract = contracts_by_id[contract_id]
		if(!contract)
			continue
		contract.process_contract()
	for(var/contract_id in open_contracts.Copy())
		var/datum/cy_contract/open_contract = open_contracts[contract_id]
		if(!open_contract?.metadata?["allow_ai"])
			continue
		cy_offer_contract_to_ai(open_contract, open_contract.metadata?["ai_faction"])

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

/datum/controller/subsystem/cy_business/proc/register_warehouse(obj/structure/cy_business_warehouse/warehouse)
	if(!warehouse)
		return FALSE
	warehouses |= warehouse
	return TRUE

/datum/controller/subsystem/cy_business/proc/unregister_warehouse(obj/structure/cy_business_warehouse/warehouse)
	if(!warehouse)
		return FALSE
	warehouses -= warehouse
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

/datum/controller/subsystem/cy_business/proc/get_user_businesses(mob/user)
	var/list/result = list()
	if(!user?.ckey)
		return result
	for(var/business_id in businesses_by_id)
		var/datum/cy_business/business = businesses_by_id[business_id]
		if(business?.can_manage(user) || business?.has_employee(user))
			result += business
	return result

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

/datum/controller/subsystem/cy_business/proc/cy_contract_order_type(contract_type)
	switch(contract_type)
		if(CY_CONTRACT_DELIVERY, CY_CONTRACT_PROCUREMENT, CY_CONTRACT_MINING)
			return CY_NPC_ORDER_DELIVER
		if(CY_CONTRACT_REPAIR)
			return CY_NPC_ORDER_REPAIR
		if(CY_CONTRACT_CONSTRUCTION)
			return CY_NPC_ORDER_WORK
		if(CY_CONTRACT_GUARD, CY_CONTRACT_ESCORT)
			return CY_NPC_ORDER_GUARD
		if(CY_CONTRACT_EVACUATION)
			return CY_NPC_ORDER_CARRY
		if(CY_CONTRACT_SABOTAGE)
			return CY_NPC_ORDER_USE_OBJECT
		if(CY_CONTRACT_ELIMINATION)
			return CY_NPC_ORDER_ATTACK
		if(CY_CONTRACT_RECON)
			return CY_NPC_ORDER_SEARCH
	return CY_NPC_ORDER_WORK

/datum/controller/subsystem/cy_business/proc/cy_offer_contract_to_ai(datum/cy_contract/contract, faction_id = null)
	if(!contract || contract.status != CY_CONTRACT_STATUS_OPEN)
		return FALSE
	var/order_type = cy_contract_order_type(contract.contract_type)
	var/atom/target = contract.get_target_atom()
	var/turf/destination = contract.get_destination_turf()
	var/needed_caps = CY_NPC_CAP_HANDS | CY_NPC_CAP_ITEM_USE
	switch(contract.contract_type)
		if(CY_CONTRACT_DELIVERY, CY_CONTRACT_PROCUREMENT, CY_CONTRACT_MINING)
			needed_caps = CY_NPC_CAP_DELIVERY
		if(CY_CONTRACT_REPAIR, CY_CONTRACT_CONSTRUCTION)
			needed_caps = CY_NPC_CAP_REPAIR
		if(CY_CONTRACT_GUARD, CY_CONTRACT_ESCORT)
			needed_caps = CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED | CY_NPC_CAP_SIGNAL
		if(CY_CONTRACT_EVACUATION)
			needed_caps = CY_NPC_CAP_CARRY | CY_NPC_CAP_MEDICAL
		if(CY_CONTRACT_SABOTAGE)
			needed_caps = CY_NPC_CAP_ITEM_USE | CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED
		if(CY_CONTRACT_ELIMINATION)
			needed_caps = CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED
		if(CY_CONTRACT_RECON)
			needed_caps = CY_NPC_CAP_SIGNAL | CY_NPC_CAP_DELIVERY
	var/list/data = list(
		"priority" = 20,
		"timeout" = contract.due_time ? max(1, contract.due_time - world.time) : 10 MINUTES,
		"destination" = destination,
		"contract_id" = contract.contract_id,
	)
	for(var/status in GLOB.ai_controllers_by_status)
		for(var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_status[status])
			if(!controller.cy_npc_profile || !controller.cy_npc_active)
				continue
			if(faction_id && controller.cy_npc_faction_id != faction_id)
				continue
			if(!(controller.cy_npc_capabilities & needed_caps))
				continue
			controller.blackboard[BB_CY_NPC_CONTRACT] = contract
			controller.cy_npc_make_order(order_type, target || destination, data)
			contract.performer_ckey = "AI:[REF(controller.pawn)]"
			contract.accepted_time = world.time
			contract.start_time = world.time
			contract.status = CY_CONTRACT_STATUS_ACTIVE
			open_contracts -= contract.contract_id
			contract.log_event("Accepted by AI [controller.pawn]")
			return TRUE
	return FALSE

/datum/controller/subsystem/cy_business/proc/move_contract_to_ledger(datum/cy_contract/contract)
	if(!contract)
		return FALSE
	open_contracts -= contract.contract_id
	contract_ledger += list(contract.to_list())
	return TRUE

/datum/controller/subsystem/cy_business/proc/route_warehouse_item(business_id, corporation_id, obj/item/item)
	if(!item)
		return FALSE
	var/datum/cy_business/business = get_business(business_id)
	if(!business)
		return FALSE
	for(var/obj/structure/cy_business_warehouse/warehouse as anything in warehouses)
		if(!warehouse || warehouse.business_id != business.business_id || !warehouse.corporation_id)
			continue
		if(warehouse.can_accept_item(item, corporation_id))
			return warehouse.store_item(item)
	if(!business.cy_can_accept_corporate_storage(corporation_id, item))
		return FALSE
	for(var/obj/structure/cy_business_warehouse/warehouse as anything in warehouses)
		if(!warehouse || warehouse.business_id != business.business_id || warehouse.corporation_id || !warehouse.allow_business_fallback)
			continue
		if(warehouse.can_accept_item(item, corporation_id))
			return warehouse.store_item(item)
	return FALSE

/datum/controller/subsystem/cy_business/proc/get_warehouse_ui_data(datum/cy_business/business)
	var/list/result = list()
	if(!business)
		return result
	for(var/obj/structure/cy_business_warehouse/warehouse as anything in warehouses)
		if(warehouse?.business_id == business.business_id)
			result += list(warehouse.to_ui_data())
	return result
