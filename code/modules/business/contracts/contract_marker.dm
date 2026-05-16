/obj/item/cy_contract_marker
	name = "contract marker"
	desc = "A contract tracking tag used by city terminals."
	icon = 'icons/obj/devices/tracker.dmi'
	icon_state = "pinpointer"
	var/contract_id
	var/marker_role = "target"

/obj/item/cy_contract_marker/proc/bind_to_contract(datum/cy_contract/contract, role = "target")
	if(!contract)
		return FALSE
	contract_id = contract.contract_id
	marker_role = role
	name = "contract marker ([contract_id])"
	return TRUE

/obj/item/cy_contract_marker/proc/get_contract()
	return SScy_business?.get_contract(contract_id)
