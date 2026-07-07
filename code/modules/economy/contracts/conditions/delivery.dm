//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/delivery
	id = CYBERPUNK_CONTRACT_DELIVERY
	name = "Delivery"
	var/destination_kind = "creator"
	var/destination_text = ""
	var/target_kind = "item"


/datum/cyberpunk_contract_condition/delivery/configure_from_contract(datum/cyberpunk_contract/contract, list/params)
	. = ..()
	if(params)
		var/new_kind = reject_bad_text(params["destination_kind"], max_length = 32, ascii_only = TRUE)
		if(new_kind in list("creator", "recipient", "terminal", "coordinates"))
			destination_kind = new_kind
		var/new_destination = reject_bad_text(params["destination"], max_length = 64, ascii_only = FALSE)
		if(new_destination)
			destination_text = new_destination
		var/new_target_kind = reject_bad_text(params["delivery_target_kind"], max_length = 32, ascii_only = TRUE)
		if(new_target_kind in list("item", "object", "mob", "cargo"))
			target_kind = new_target_kind


/datum/cyberpunk_contract_condition/delivery/to_ui_data()
	. = ..()
	.["destinationKind"] = destination_kind
	.["destination"] = destination_text
	.["targetKind"] = target_kind


/datum/cyberpunk_contract_condition/delivery/to_failure_ui_data(datum/cyberpunk_contract/contract)
	return list(
		"id" = "delivery_failure",
		"name" = "Cargo lost or late",
		"description" = "Fails if the marked cargo is destroyed, deleted, or not delivered before the deadline.",
	)


/datum/cyberpunk_contract_condition/delivery/proc/item_at_destination(datum/cyberpunk_contract/contract, atom/movable/deliverable, mob/living/holder)
	if(!contract || !deliverable)
		return FALSE
	if(destination_kind == "coordinates")
		return matches_location(deliverable)
	if(destination_kind == "terminal")
		for(var/atom/nearby in view(1, deliverable))
			if(!destination_text || findtext(lowertext(nearby.name), lowertext(destination_text)) || findtext(lowertext("[nearby.type]"), lowertext(destination_text)))
				return TRUE
		return FALSE
	var/mob/living/recipient
	if(destination_kind == "recipient" && destination_text)
		recipient = SSeconomy.find_cyberpunk_contract_person(destination_text)
	if(!recipient)
		recipient = holder && contract.user_character_key(holder) == contract.creator_character_key ? holder : contract.find_creator_mob()
	return recipient && get_dist(get_turf(recipient), get_turf(deliverable)) <= 1


/datum/cyberpunk_contract_condition/delivery/proc/get_ai_destination(datum/cyberpunk_contract/contract, obj/machinery/vending/source_terminal)
	if(destination_kind == "coordinates")
		if(!target_x || !target_y || !target_z)
			return null
		return locate(target_x, target_y, target_z)
	if(destination_kind == "terminal")
		for(var/obj/machinery/vending/vendor as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
			if(!vendor.has_contract_terminal_module())
				continue
			if(source_terminal && vendor == source_terminal)
				continue
			if(terminal_matches(vendor))
				return vendor
		return null
	if(destination_kind == "recipient" && destination_text)
		return SSeconomy.find_cyberpunk_contract_person(destination_text)
	return contract?.find_creator_mob()


/datum/cyberpunk_contract_condition/delivery/record_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item)
	if(!contract || !item || item.cyberpunk_contract_id != contract.id)
		return FALSE
	if(!item_at_destination(contract, item, user))
		return FALSE
	delivered_amount = max(delivered_amount, required_amount)
	contract.delivered_amount = max(contract.delivered_amount, delivered_amount)
	contract.add_history("[item.name] delivered to [destination_text || destination_kind]")
	if(!contract.creator_confirm_required)
		contract.complete("cargo delivered")
	return TRUE


/datum/cyberpunk_contract_condition/delivery/check_nearby(datum/cyberpunk_contract/contract, mob/living/user)
	if(target_kind == "mob")
		var/mob/living/person = SSeconomy.find_cyberpunk_contract_person(target_text)
		if(person && item_at_destination(contract, person, user))
			delivered_amount = max(delivered_amount, required_amount)
			contract.delivered_amount = max(contract.delivered_amount, delivered_amount)
			contract.add_history("[person.real_name || person.name] delivered to [destination_text || destination_kind]")
			if(!contract.creator_confirm_required)
				contract.complete("person delivered")
			return TRUE
	for(var/atom/target in view(1, user))
		if(!matches_atom(target))
			continue
		if(isitem(target))
			var/obj/item/delivered_item = target
			return record_item(contract, user, delivered_item)
		if(target_kind in list("object", "cargo") && item_at_destination(contract, target, user))
			delivered_amount = max(delivered_amount, required_amount)
			contract.delivered_amount = max(contract.delivered_amount, delivered_amount)
			contract.add_history("[target] delivered to [destination_text || destination_kind]")
			if(!contract.creator_confirm_required)
				contract.complete("object delivered")
			return TRUE
	return FALSE


/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_item_in_hands(mob/living/holder, obj/item/item)
	if(!holder || !item?.cyberpunk_contract_id)
		return FALSE
	var/datum/cyberpunk_contract/contract = get_cyberpunk_contract(item.cyberpunk_contract_id)
	return contract?.record_delivery_contact(item, holder)


/datum/cyberpunk_contract/proc/submit_held_item(mob/living/user)
	if(!can_act_as_contractor(user) || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_MINING)))
		return FALSE
	var/obj/item/held = user.get_active_held_item()
	if(!held)
		return FALSE
	if(held.cyberpunk_contract_id != id && target_text && !findtext(lowertext(held.name), lowertext(target_text)) && !findtext(lowertext("[held.type]"), lowertext(target_text)))
		return FALSE
	if(contract_type == CYBERPUNK_CONTRACT_DELIVERY)
		if(try_record_item_condition(CYBERPUNK_CONTRACT_DELIVERY, user, held))
			return TRUE
		return record_delivery_contact(held, user)
	if(try_record_item_condition(CYBERPUNK_CONTRACT_MINING, user, held))
		return TRUE
	var/submitted_name = held.name
	var/amount = 1
	if(isstack(held))
		var/obj/item/stack/stack = held
		amount = min(stack.amount, required_amount - delivered_amount)
		stack.use(amount)
	else
		qdel(held)
	delivered_amount += amount
	add_history("[user.real_name || user.name] submitted [amount]x [submitted_name]")
	if(delivered_amount >= required_amount && !creator_confirm_required)
		return complete("submitted required cargo")
	return TRUE


/datum/cyberpunk_contract/proc/mark_held_item(mob/living/user)
	if(!can_act_as_contractor(user) || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_MINING, CYBERPUNK_CONTRACT_GUARD)))
		return FALSE
	var/obj/item/held = user.get_active_held_item()
	if(!held)
		return FALSE
	held.cyberpunk_contract_id = id
	add_history("[user.real_name || user.name] marked [held.name] as contract cargo")
	if(contract_type == CYBERPUNK_CONTRACT_GUARD)
		for(var/datum/cyberpunk_contract_condition/guard/condition as anything in completion_conditions)
			condition.protected_ref = REF(held)
			condition.guard_kind = "cargo"
		return TRUE
	track_delivery_item(held)
	try_record_item_condition(contract_type, user, held) || record_delivery_contact(held, user)
	return TRUE


/datum/cyberpunk_contract/proc/track_delivery_item(obj/item/item)
	if(!item || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY)))
		return
	if(!(item in delivery_items))
		delivery_items += item
		RegisterSignal(item, COMSIG_MOVABLE_MOVED, PROC_REF(on_delivery_item_moved))
		RegisterSignal(item, COMSIG_QDELETING, PROC_REF(on_delivery_item_deleted))
	var/mob/living/creator = find_creator_mob()
	if(creator && creator != tracked_creator)
		if(tracked_creator)
			UnregisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED)
		tracked_creator = creator
		RegisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED, PROC_REF(on_delivery_creator_moved))


/datum/cyberpunk_contract/proc/clear_delivery_tracking()
	for(var/obj/item/item as anything in delivery_items)
		UnregisterSignal(item, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
	delivery_items.Cut()
	if(tracked_creator)
		UnregisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED)
		tracked_creator = null


/datum/cyberpunk_contract/proc/record_delivery_contact(obj/item/item, mob/living/holder)
	if(status != CYBERPUNK_CONTRACT_ACCEPTED || contract_type != CYBERPUNK_CONTRACT_DELIVERY || !item || item.cyberpunk_contract_id != id)
		return FALSE
	if(try_record_item_condition(CYBERPUNK_CONTRACT_DELIVERY, holder, item))
		return TRUE
	var/mob/living/creator = holder && user_character_key(holder) == creator_character_key ? holder : find_creator_mob()
	if(!creator)
		return FALSE
	if(get_dist(get_turf(creator), get_turf(item)) > 1)
		return FALSE
	delivered_amount = max(delivered_amount, required_amount)
	add_history("[item.name] reached creator [creator.real_name || creator.name]")
	if(!creator_confirm_required)
		return complete("cargo delivered to creator")
	return TRUE


/datum/cyberpunk_contract/proc/on_delivery_item_moved(obj/item/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	record_delivery_contact(source)


/datum/cyberpunk_contract/proc/on_delivery_creator_moved(mob/living/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	for(var/obj/item/item as anything in delivery_items)
		record_delivery_contact(item, source)


/datum/cyberpunk_contract/proc/on_delivery_item_deleted(obj/item/source)
	SIGNAL_HANDLER
	delivery_items -= source
	if(status == CYBERPUNK_CONTRACT_ACCEPTED)
		fail("marked cargo was destroyed or lost")
