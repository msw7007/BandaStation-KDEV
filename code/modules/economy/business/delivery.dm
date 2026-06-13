//CYBERPUNK BUSINESS - warehouse delivery records.
/datum/cyberpunk_business_delivery
	var/id = 0
	var/business_id = 0
	var/item_label = "goods"
	var/amount = 1
	var/source_label = "external supplier"
	var/source_business_id = 0
	var/destination_label = "business warehouse"
	var/cost = 0
	var/status = "enroute"
	var/created_at = 0
	var/arrival_time = 0

/datum/cyberpunk_business_delivery/proc/complete_delivery()
	if(status != "enroute")
		return FALSE
	var/datum/cyberpunk_business/business = SScyberpunk_property.get_cyberpunk_business(business_id)
	if(!business)
		return FALSE
	status = "completed"
	business.add_stock(item_label, amount)
	business.add_history("delivery #[id] arrived: [amount]x [item_label]; cost [cost][MONEY_SYMBOL]")
	if(business.terminal)
		business.terminal.say("Delivery #[id] arrived: [amount]x [item_label].")
	return TRUE

/datum/cyberpunk_business_delivery/proc/to_ui_data()
	return list(
		"id" = id,
		"item" = item_label,
		"amount" = amount,
		"source" = source_label,
		"destination" = destination_label,
		"cost" = cost,
		"status" = status,
		"eta" = status == "enroute" && arrival_time > world.time ? DisplayTimeText(arrival_time - world.time) : "arrived",
	)
//CYBERPUNK BUILD - rebuild and delete before release
