//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/delivery
	id = CYBERPUNK_CONTRACT_DELIVERY
	name = "Delivery"
	var/destination_kind = "creator"
	var/destination_text = ""
	var/target_kind = "item"
	var/datum/weakref/person_contract_ref
	var/datum/weakref/person_deliverable_ref
	var/datum/weakref/person_contractor_ref
	var/datum/weakref/person_recipient_ref
	var/next_person_search = 0


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


/datum/cyberpunk_contract_condition/delivery/proc/item_at_destination(datum/cyberpunk_contract/contract, atom/movable/deliverable, mob/living/holder, mob/living/known_recipient)
	if(!contract || !deliverable)
		return FALSE
	if(destination_kind == "coordinates")
		return matches_location(deliverable)
	if(destination_kind == "terminal")
		for(var/obj/machinery/vending/nearby in view(1, deliverable))
			if(nearby.has_contract_terminal_module() && terminal_matches(nearby))
				return TRUE
		return FALSE
	var/mob/living/recipient = known_recipient
	if(!recipient && destination_kind == "recipient")
		recipient = SSeconomy.find_cyberpunk_contract_person(destination_text)
	else if(!recipient)
		recipient = holder && contract.user_character_key(holder) == contract.creator_character_key ? holder : contract.find_creator_mob()
	var/turf/recipient_turf = get_turf(recipient)
	var/turf/cargo_turf = get_turf(deliverable)
	return recipient_turf && cargo_turf && recipient_turf.z == cargo_turf.z && get_dist(recipient_turf, cargo_turf) <= 1


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
	if(destination_kind == "recipient")
		return SSeconomy.find_cyberpunk_contract_person(destination_text)
	return contract?.find_creator_mob()


/datum/cyberpunk_contract_condition/delivery/record_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item)
	if(!contract || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || !item || item.cyberpunk_contract_id != contract.id || !(item in contract.delivery_items))
		return FALSE
	if(!matches_type(item) || !item_meets_quality(item) || get_item_amount(item) < required_amount)
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
		var/mob/living/person = person_deliverable_ref?.resolve() || SSeconomy.find_cyberpunk_contract_person(target_text)
		return record_person_delivery(contract, person, user, person_recipient_ref?.resolve())
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


/datum/cyberpunk_contract_condition/delivery/on_accept(datum/cyberpunk_contract/contract, mob/living/user)
	if(target_kind != "mob")
		return
	person_contract_ref = WEAKREF(contract)
	person_contractor_ref = WEAKREF(user)
	START_PROCESSING(SSobj, src)

/datum/cyberpunk_contract_condition/delivery/Destroy()
	stop_person_delivery()
	return ..()

/datum/cyberpunk_contract_condition/delivery/proc/stop_person_delivery()
	STOP_PROCESSING(SSobj, src)
	person_contract_ref = null
	person_deliverable_ref = null
	person_contractor_ref = null
	person_recipient_ref = null

/datum/cyberpunk_contract_condition/delivery/process(seconds_per_tick)
	var/datum/cyberpunk_contract/contract = person_contract_ref?.resolve()
	if(!contract || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || delivered_amount >= required_amount)
		stop_person_delivery()
		return PROCESS_KILL
	var/mob/living/person = person_deliverable_ref?.resolve()
	var/mob/living/contractor = person_contractor_ref?.resolve()
	var/mob/living/recipient = person_recipient_ref?.resolve()
	var/needs_recipient = destination_kind in list("creator", "recipient")
	if(world.time >= next_person_search && (!person || !contractor || (needs_recipient && !recipient)))
		next_person_search = world.time + 5 SECONDS
		if(!person)
			person = SSeconomy.find_cyberpunk_contract_person(target_text)
			if(person)
				person_deliverable_ref = WEAKREF(person)
		if(!contractor)
			contractor = SSeconomy.find_cyberpunk_contract_person(contract.contractor_character_key)
			if(contractor)
				person_contractor_ref = WEAKREF(contractor)
		if(needs_recipient && !recipient)
			recipient = destination_kind == "recipient" ? SSeconomy.find_cyberpunk_contract_person(destination_text) : contract.find_creator_mob()
			if(recipient)
				person_recipient_ref = WEAKREF(recipient)
	if(!needs_recipient || recipient)
		record_person_delivery(contract, person, contractor, recipient)

/datum/cyberpunk_contract_condition/delivery/proc/record_person_delivery(datum/cyberpunk_contract/contract, mob/living/person, mob/living/contractor, mob/living/recipient)
	if(!person || !contractor || contract.status != CYBERPUNK_CONTRACT_ACCEPTED)
		return FALSE
	if(delivered_amount >= required_amount)
		return TRUE
	var/turf/person_turf = get_turf(person)
	var/turf/contractor_turf = get_turf(contractor)
	if(!person_turf || !contractor_turf || person_turf.z != contractor_turf.z || get_dist(person_turf, contractor_turf) > 1)
		return FALSE
	if(!item_at_destination(contract, person, contractor, recipient))
		return FALSE
	delivered_amount = max(delivered_amount, required_amount)
	contract.delivered_amount = max(contract.delivered_amount, delivered_amount)
	contract.add_history("[person.real_name || person.name] delivered to [destination_text || destination_kind]")
	stop_person_delivery()
	if(!contract.creator_confirm_required)
		contract.complete("person delivered")
	return TRUE


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
	if(contract_type == CYBERPUNK_CONTRACT_DELIVERY)
		if(try_record_item_condition(CYBERPUNK_CONTRACT_DELIVERY, user, held))
			return TRUE
		return record_delivery_contact(held, user)
	if(try_record_item_condition(CYBERPUNK_CONTRACT_MINING, user, held))
		return TRUE
	if(length(completion_conditions) || (target_text && !findtext(lowertext(held.name), lowertext(target_text)) && !findtext(lowertext("[held.type]"), lowertext(target_text))))
		return FALSE
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
	if(!held || (held.cyberpunk_contract_id && held.cyberpunk_contract_id != id))
		return FALSE
	if(contract_type == CYBERPUNK_CONTRACT_GUARD)
		for(var/datum/cyberpunk_contract_condition/guard/condition as anything in completion_conditions)
			if(condition.guard_kind == "cargo" && condition.protected_ref == REF(held))
				held.cyberpunk_contract_id = id
				return TRUE
		return FALSE
	if(contract_type == CYBERPUNK_CONTRACT_DELIVERY && !(held in delivery_items))
		return FALSE
	if(contract_type == CYBERPUNK_CONTRACT_MINING)
		var/valid_resource = FALSE
		for(var/datum/cyberpunk_contract_condition/mining/condition as anything in completion_conditions)
			if(condition.matches_target_text(held) && condition.matches_type(held) && condition.item_meets_quality(held))
				valid_resource = TRUE
		if(!valid_resource)
			return FALSE
		return TRUE
	held.cyberpunk_contract_id = id
	add_history("[user.real_name || user.name] marked [held.name] as contract cargo")
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
		if(item.cyberpunk_contract_id == id)
			item.cyberpunk_contract_id = 0
	delivery_items.Cut()
	for(var/datum/cyberpunk_contract_condition/delivery/delivery in completion_conditions)
		delivery.stop_person_delivery()
	for(var/datum/cyberpunk_contract_condition/guard/condition as anything in completion_conditions)
		var/obj/item/guarded_item = locate(condition.protected_ref)
		if(istype(guarded_item) && guarded_item.cyberpunk_contract_id == id)
			guarded_item.cyberpunk_contract_id = 0
	if(tracked_creator)
		UnregisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED)
		tracked_creator = null


/datum/cyberpunk_contract/proc/record_delivery_contact(obj/item/item, mob/living/holder)
	if(status != CYBERPUNK_CONTRACT_ACCEPTED || contract_type != CYBERPUNK_CONTRACT_DELIVERY || !item || item.cyberpunk_contract_id != id)
		return FALSE
	if(try_record_item_condition(CYBERPUNK_CONTRACT_DELIVERY, holder, item))
		return TRUE
	if(length(completion_conditions))
		return FALSE
	var/mob/living/creator = holder && user_character_key(holder) == creator_character_key ? holder : find_creator_mob()
	if(!creator)
		return FALSE
	var/turf/item_turf = get_turf(item)
	if(!(item in delivery_items) || creator.z != item_turf?.z || get_dist(get_turf(creator), item_turf) > 1)
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
		addtimer(CALLBACK(src, PROC_REF(fail), "marked cargo was destroyed or lost"), 0)
