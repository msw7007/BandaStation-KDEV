SUBSYSTEM_DEF(cyberpunk_property)
	name = "Cyberpunk Property"
	wait = 1 MINUTES
	runlevels = RUNLEVEL_GAME
	ss_flags = SS_NO_INIT
	//CYBERPUNK BUILD - rebuild and delete before release
	/// Round-local business registry. Keyed by business id.
	var/list/cyberpunk_businesses = list()
	/// Next id for round-local businesses.
	var/next_cyberpunk_business_id = 1
	/// Round-local apartment registry. Keyed by apartment id.
	var/list/cyberpunk_apartments = list()
	/// Next id for round-local apartments.
	var/next_cyberpunk_apartment_id = 1
	/// Round-local business delivery jobs.
	var/list/cyberpunk_business_deliveries = list()
	/// Next id for round-local business delivery jobs.
	var/next_cyberpunk_business_delivery_id = 1
	//CYBERPUNK BUILD - rebuild and delete before release

/datum/controller/subsystem/cyberpunk_property/Recover()
	cyberpunk_businesses = SScyberpunk_property.cyberpunk_businesses
	next_cyberpunk_business_id = SScyberpunk_property.next_cyberpunk_business_id
	cyberpunk_apartments = SScyberpunk_property.cyberpunk_apartments
	next_cyberpunk_apartment_id = SScyberpunk_property.next_cyberpunk_apartment_id
	cyberpunk_business_deliveries = SScyberpunk_property.cyberpunk_business_deliveries
	next_cyberpunk_business_delivery_id = SScyberpunk_property.next_cyberpunk_business_delivery_id

/datum/controller/subsystem/cyberpunk_property/fire(resumed = 0)
	for(var/delivery_id in cyberpunk_business_deliveries)
		var/datum/cyberpunk_business_delivery/delivery = cyberpunk_business_deliveries[delivery_id]
		if(delivery?.status == "enroute" && delivery.arrival_time <= world.time)
			delivery.complete_delivery()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(business?.legal && business.tax_debt > 0)
			business.auto_pay_taxes()
		if(business?.warehouse_auto_restock)
			business.auto_restock_linked_vendors()
