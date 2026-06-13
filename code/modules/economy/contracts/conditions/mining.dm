//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_condition/mining
	id = CYBERPUNK_CONTRACT_MINING
	name = "Resource turn-in"


/datum/cyberpunk_contract_condition/mining/record_item(datum/cyberpunk_contract/contract, mob/living/user, obj/item/item)
	if(!contract || !user || !item)
		return FALSE
	if(!matches_target_text(item) && item.cyberpunk_contract_id != contract.id)
		return FALSE
	if(!item_meets_quality(item))
		return FALSE
	var/submitted_name = item.name
	var/submitted_quality = get_item_quality(item)
	var/submitted_rarity = get_item_rarity(item)
	var/amount = min(get_item_amount(item), required_amount - delivered_amount)
	if(amount <= 0)
		return FALSE
	if(isstack(item))
		var/obj/item/stack/stack = item
		stack.use(amount)
	else
		qdel(item)
	delivered_amount += amount
	contract.delivered_amount = delivered_amount
	contract.add_history("[user.real_name || user.name] submitted [amount]x [submitted_name] (quality [submitted_quality], rarity [submitted_rarity])")
	if(delivered_amount >= required_amount && !contract.creator_confirm_required)
		contract.complete("submitted required resources")
	return TRUE
