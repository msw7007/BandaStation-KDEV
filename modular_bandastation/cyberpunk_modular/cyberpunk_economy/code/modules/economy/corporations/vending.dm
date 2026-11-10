//CYBERPUNK CORPORATIONS - corporate vending network integration.

/obj/machinery/vending
	var/cyberpunk_corporate_vendor_id
	var/cyberpunk_corporate_vendor_sales = 0
	var/cyberpunk_corporate_vendor_revenue = 0
	var/corp_manufacturer
	var/cyberpunk_energy_stock_added = FALSE

/obj/machinery/vending/proc/get_cyberpunk_supply_corporation()
	if(!has_corporate_vending_module())
		return null
	return SScyberpunk_corporations.get_cyberpunk_corporation(cyberpunk_corporate_vendor_id)

/obj/machinery/vending/proc/has_cyberpunk_supply_certification()
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_supply_corporation()
	return corporation?.has_edict("[corporation.id]_supply_cert")

/obj/machinery/vending/proc/get_cyberpunk_corporate_stock_multiplier()
	return has_cyberpunk_supply_certification() ? 1.15 : 1

/obj/machinery/vending/proc/get_cyberpunk_corporate_supply_interval()
	if(!get_cyberpunk_supply_corporation())
		return cyberpunk_sale_rotation_interval
	var/day_duration = SScyberpunk_round?.cyberpunk_round_real_day || cyberpunk_sale_rotation_interval
	if(!has_cyberpunk_supply_certification())
		return day_duration
	return day_duration / (cyberpunk_corporate_vendor_id == CYBERPUNK_CORP_STARLIGHT ? 3 : 2)

/obj/machinery/vending/proc/apply_cyberpunk_corporate_supply_quality(obj/item/product)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_supply_corporation()
	if(!product || corporation?.id != CYBERPUNK_CORP_BENN)
		return
	// Returned goods retain their condition; only newly supplied goods use this profile.
	product.cyberpunk_quality = has_cyberpunk_supply_certification() ? 95 : 75
	product.recalculate_cyberpunk_weapon_stats()
	product.recalculate_cyberpunk_equipment_stats()

/obj/machinery/vending/proc/sync_cyberpunk_energy_stock()
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_supply_corporation()
	if(cyberpunk_energy_stock_added || !corporation)
		return
	var/list/energy_products
	if(corporation.has_edict("ryaznov_energy_supply"))
		energy_products = list(/obj/item/stock_parts/power_store/cell = 4, /obj/item/stock_parts/power_store/battery = 4, /obj/item/stack/cable_coil = 5)
	else if(corporation.id == CYBERPUNK_CORP_STARLIGHT && (corporation.has_edict("starlight_trade_analysis") || corporation.has_edict("starlight_cargo_tracking") || corporation.has_edict("starlight_log_help")))
		energy_products = list(/obj/item/cyberpunk_delivery_beacon = 4)
	else
		return
	cyberpunk_energy_stock_added = TRUE
	for(var/product_type in energy_products)
		var/already_stocked = FALSE
		for(var/datum/data/vending_product/existing as anything in product_records)
			if(existing.product_path == product_type)
				already_stocked = TRUE
				break
		if(already_stocked)
			continue
		var/obj/item/product = product_type
		var/datum/data/vending_product/record = new
		record.product_path = product_type
		record.name = initial(product.name)
		record.cyberpunk_base_amount = energy_products[product_type]
		record.max_amount = record.cyberpunk_base_amount
		record.amount = record.max_amount
		record.cyberpunk_sale_source = cyberpunk_sale_source
		record.cyberpunk_sale_entry = get_cyberpunk_sale_entry_for_type(product_type, cyberpunk_sale_source)
		record.price = record.cyberpunk_sale_entry.get_price(default_price, extra_price)
		product_records += record

/obj/machinery/vending/proc/route_cyberpunk_starlight_purchase(mob/living/customer, obj/item/product)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_supply_corporation()
	if(product && corporation?.id == CYBERPUNK_CORP_STARLIGHT && corporation.has_edict("starlight_log_observation"))
		corporation.register_starlight_tracking(customer, product)
	if(!product || corporation?.id != CYBERPUNK_CORP_STARLIGHT || !corporation.service_auto_enabled || !corporation.has_edict("starlight_cargo_tracking") || !corporation.is_subscribed(customer))
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(customer, customer.get_bank_account())
	for(var/obj/item/cyberpunk_delivery_beacon/beacon as anything in GLOB.cyberpunk_starlight_beacons)
		var/turf/destination = get_turf(beacon)
		if(beacon.owner_key != character_key || !beacon.active || !isturf(beacon.loc) || !destination || !is_station_level(destination.z) || destination.density || isspaceturf(destination))
			continue
		var/datum/cyberpunk_starlight_shipment/shipment = corporation.register_starlight_tracking(customer, product)
		if(!shipment)
			return FALSE
		shipment.source_ref = WEAKREF(src)
		shipment.beacon_ref = WEAKREF(beacon)
		shipment.destination = destination
		shipment.status = "queued"
		START_PROCESSING(SSobj, shipment)
		to_chat(customer, span_notice("Starlight queued [product] for your beacon. The parcel waits at this vendor until a courier is available."))
		return TRUE
	return FALSE

/obj/machinery/vending/proc/has_corporate_vending_module()
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		if(istype(module, /datum/cyberpunk_machine_module/corporate_vending_bus))
			return TRUE
	return FALSE

/obj/machinery/proc/get_cyberpunk_corporate_charging_multiplier()
	var/area/territory = get_area(src)
	var/owner_id = cyberpunk_corporate_area_id(src) || territory?.cyberpunk_world_owner
	if(SScyberpunk_corporations.cyberpunk_normalize_corporation_id(owner_id) != CYBERPUNK_CORP_RYAZNOV)
		return 1
	var/multiplier = SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_RYAZNOV, "ryaznov_energy_supply") ? 1.25 : 1
	return multiplier * cyberpunk_property_edict_multiplier(src, CYBERPUNK_CORP_RYAZNOV, "ryaznov_power_tuning")

/obj/machinery
	var/list/cyberpunk_energy_sales
	var/cyberpunk_energy_restock_at = 0

/obj/machinery/proc/has_cyberpunk_energy_shop()
	var/area/territory = get_area(src)
	var/owner = get_cyberspace_manufacturer(src)
	if(owner == "independent")
		owner = cyberpunk_corporate_area_id(src) || territory?.cyberpunk_world_owner
	return SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(owner) == CYBERPUNK_CORP_RYAZNOV && SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_RYAZNOV, "ryaznov_energy_supply")

/obj/machinery/proc/buy_cyberpunk_energy_supply(mob/living/customer)
	if(!has_cyberpunk_energy_shop())
		return FALSE
	if(!istype(customer) || !is_operational || !Adjacent(customer) || customer.incapacitated || customer.stat != CONSCIOUS)
		return TRUE
	var/list/catalogue = list("Power cell" = /obj/item/stock_parts/power_store/cell, "Battery" = /obj/item/stock_parts/power_store/battery, "Cable coil" = /obj/item/stack/cable_coil)
	var/list/offers = list()
	var/list/prices = list()
	for(var/product_type in catalogue)
		var/datum/cyberpunk_sale_entry/entry = get_cyberpunk_sale_entry_for_type(catalogue[product_type], "vendor")
		var/price = entry.get_price()
		qdel(entry)
		offers["[product_type] ([price] cr)"] = catalogue[product_type]
		prices[catalogue[product_type]] = price
	var/choice = tgui_input_list(customer, "Energy supplies", name, offers)
	var/product_type = offers[choice]
	if(!product_type || QDELETED(src) || !has_cyberpunk_energy_shop() || !is_operational || !Adjacent(customer) || customer.incapacitated || customer.stat != CONSCIOUS)
		return TRUE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(CYBERPUNK_CORP_RYAZNOV)
	LAZYINITLIST(cyberpunk_energy_sales)
	if(world.time >= cyberpunk_energy_restock_at)
		cyberpunk_energy_sales.Cut()
		cyberpunk_energy_restock_at = world.time + (SScyberpunk_round?.cyberpunk_round_real_day || 30 MINUTES) / (corporation.has_edict("ryaznov_supply_cert") ? 2 : 1)
	if(cyberpunk_energy_sales[product_type] >= 4)
		to_chat(customer, span_warning("This supply is sold out until the next delivery."))
		return TRUE
	var/datum/bank_account/account = customer.get_bank_account()
	if(!account?.adjust_money(-prices[product_type], "Ryaznov energy supplies"))
		return TRUE
	cyberpunk_energy_sales[product_type] = (cyberpunk_energy_sales[product_type] || 0) + 1
	var/obj/item/product = new product_type(drop_location())
	if(!customer.put_in_hands(product))
		product.forceMove(drop_location())
	corporation.add_funds(prices[product_type], "energy supplies")
	return TRUE

/obj/machinery/cell_charger/attack_hand_secondary(mob/user, list/modifiers)
	if(buy_cyberpunk_energy_supply(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/machinery/recharger/attack_hand_secondary(mob/user, list/modifiers)
	if(buy_cyberpunk_energy_supply(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/datum/cyberpunk_corporation/proc/service_tracking_edict()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return "benn_med_tracking"
		if(CYBERPUNK_CORP_RYAZNOV)
			return "ryaznov_tech_tracking"
		if(CYBERPUNK_CORP_STARLIGHT)
			return "starlight_cargo_tracking"

/datum/cyberpunk_corporation/proc/service_guardian_edict()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return "benn_chem_guardians"
		if(CYBERPUNK_CORP_RYAZNOV)
			return "ryaznov_shield_guardians"
		if(CYBERPUNK_CORP_STARLIGHT)
			return "starlight_phase_guardians"

/obj/machinery/vending/proc/get_cyberpunk_service_chip_offer()
	if(!has_corporate_vending_module())
		return null
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(cyberpunk_corporate_vendor_id)
	if(!corporation || (!corporation.has_edict(corporation.service_tracking_edict()) && !corporation.has_edict(corporation.service_guardian_edict())))
		return null
	return list("name" = "[corporation.name] service chip (autoimplant)", "price" = 100)

/obj/machinery/vending/proc/buy_cyberpunk_service_chip(mob/living/user)
	var/list/offer = get_cyberpunk_service_chip_offer()
	if(!istype(user) || !offer || !is_operational || !Adjacent(user) || user.incapacitated || user.stat != CONSCIOUS)
		return FALSE
	for(var/obj/item/implant/cyberpunk_service/chip as anything in user.implants)
		if(chip.corporation_id == cyberpunk_corporate_vendor_id)
			return FALSE
	var/obj/item/implant/cyberpunk_service/chip = new
	chip.corporation_id = cyberpunk_corporate_vendor_id
	var/datum/bank_account/account = user.get_bank_account()
	if(!chip.can_be_implanted_in(user) || !user.has_neural_implant() || !account?.adjust_money(-offer["price"], "Corporate service chip"))
		qdel(chip)
		return FALSE
	if(!chip.implant(user, user))
		account.adjust_money(offer["price"], "Corporate service chip refund")
		qdel(chip)
		return FALSE
	SScyberpunk_corporations.get_cyberpunk_corporation(cyberpunk_corporate_vendor_id).add_funds(offer["price"], "service chip sale")
	to_chat(user, span_notice("The service chip is implanted and linked to your neural interface."))
	return TRUE

/obj/item/implant/cyberpunk_service
	name = "corporate service chip"
	requires_neural_interface = TRUE
	allow_multiple = TRUE
	var/corporation_id
	var/next_alarm_at = 0
	var/shield_until = 0
	var/datum/weakref/last_attacker_ref
	var/last_attack_at = 0
	var/datum/weakref/equipment_ref
	var/emergency_until = 0

/obj/item/implant/cyberpunk_service/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(!.)
		return
	RegisterSignal(target, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(target, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_health_update))
	RegisterSignal(target, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(on_damage_modifiers))

/obj/item/implant/cyberpunk_service/removed(mob/living/source, silent = FALSE, special = FALSE)
	UnregisterSignal(source, list(COMSIG_MOB_AFTER_APPLY_DAMAGE, COMSIG_LIVING_HEALTH_UPDATE, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS))
	release_stasis()
	clear_equipment()
	last_attacker_ref = null
	return ..()

/obj/item/implant/cyberpunk_service/proc/on_health_update()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(check_alarm)), 0, TIMER_UNIQUE)

/obj/item/implant/cyberpunk_service/proc/on_damage(mob/living/source, damage, damagetype, def_zone, blocked, wound_bonus, exposed_wound_bonus, sharpness, attack_direction, atom/attacking_item)
	SIGNAL_HANDLER
	var/mob/living/attacker = isliving(attacking_item) ? attacking_item : null
	if(isitem(attacking_item) && isliving(attacking_item.loc))
		attacker = attacking_item.loc
	var/obj/projectile/projectile = attacking_item
	if(istype(projectile) && isliving(projectile.firer))
		attacker = projectile.firer
	if(attacker && attacker != source)
		last_attacker_ref = WEAKREF(attacker)
		last_attack_at = world.time
	on_health_update()

/obj/item/implant/cyberpunk_service/proc/on_damage_modifiers(datum/source, list/modifiers)
	SIGNAL_HANDLER
	if(world.time < shield_until && !is_implant_disabled() && imp_in?.has_neural_implant())
		modifiers += 0.5

/obj/item/implant/cyberpunk_service/proc/release_stasis()
	imp_in?.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))

/obj/item/implant/cyberpunk_service/proc/check_alarm()
	if(!imp_in || imp_in.stat == DEAD || imp_in.health > imp_in.maxHealth * 0.5 || world.time < next_alarm_at || !can_activate_implant())
		return
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return
	var/tracking = corporation.has_edict(corporation.service_tracking_edict())
	var/member_key = SSeconomy.get_cyberpunk_contract_character_key(imp_in, imp_in.get_bank_account())
	var/guardians = (corporation.employees[member_key] || corporation.is_subscribed(imp_in)) && corporation.has_edict(corporation.service_guardian_edict()) && corporation.has_service_infrastructure(imp_in)
	if(!tracking && !guardians)
		return
	next_alarm_at = world.time + 3 MINUTES
	corporation.broadcast_service_alarm(imp_in, "critical body condition")
	if(tracking && corporation_id == CYBERPUNK_CORP_BENN && corporation.is_subscribed(imp_in))
		imp_in.apply_status_effect(/datum/status_effect/grouped/stasis, REF(src))
		addtimer(CALLBACK(src, PROC_REF(release_stasis)), 3 MINUTES)
	if(guardians)
		var/mob/living/attacker = world.time <= last_attack_at + 10 SECONDS ? last_attacker_ref?.resolve() : null
		var/mob/living/basic/cyberpunk_corporate_agent/guardian/drone = new(get_turf(imp_in), corporation_id, "guardian", imp_in.real_name)
		drone.faction = list("corporate_guardian_[corporation_id]")
		if(attacker && attacker != imp_in && attacker.z == imp_in.z && get_dist(attacker, imp_in) <= 7)
			drone.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, attacker)
		if(corporation_id == CYBERPUNK_CORP_RYAZNOV)
			shield_until = world.time + 20 SECONDS
		else if(corporation_id == CYBERPUNK_CORP_STARLIGHT && attacker)
			var/turf/escape = get_step(attacker, REVERSE_DIR(attacker.dir))
			if(escape && escape.z == imp_in.z && get_dist(escape, imp_in) <= 7 && !escape.is_blocked_turf(source_atom = imp_in))
				imp_in.forceMove(escape)
				attacker.adjust_staggered_up_to(2 SECONDS, 2 SECONDS)

/datum/cyberpunk_corporation/proc/has_service_infrastructure(atom/target)
	for(var/vendor_key in vendor_registry)
		var/datum/weakref/vendor_ref = vendor_registry[vendor_key]
		var/obj/machinery/vending/vendor = vendor_ref?.resolve()
		if(vendor?.is_operational && vendor.has_corporate_vending_module() && vendor.z == target.z && get_dist(vendor, target) <= 7)
			return TRUE
	for(var/obj/machinery/machine in range(7, target))
		if(machine.is_operational && SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(machine)) == id)
			return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/broadcast_service_alarm(atom/target, reason)
	add_history("Service beacon: [reason] at [AREACOORD(target)]")
	for(var/mob/living/person in GLOB.player_list)
		if(employees[SSeconomy.get_cyberpunk_contract_character_key(person, person.get_bank_account())])
			to_chat(person, span_warning("[name] service beacon: [reason], [get_area_name(target, TRUE)] ([target.x], [target.y], [target.z])."))

/obj/item/implant/cyberpunk_service/activate()
	if(!..())
		return FALSE
	if(corporation_id != CYBERPUNK_CORP_RYAZNOV)
		check_alarm()
		return TRUE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation.has_edict("ryaznov_tech_tracking"))
		return FALSE
	var/atom/movable/equipment = imp_in.get_active_held_item()
	if(!equipment)
		var/list/candidates = list()
		for(var/obj/candidate in view(1, imp_in))
			if(candidate.uses_integrity)
				candidates += candidate
		equipment = tgui_input_list(imp_in, "Choose equipment for the service beacon", "Technical tracking", candidates)
	if(!equipment || !imp_in || !can_activate_implant() || !imp_in.Adjacent(equipment))
		return FALSE
	if(!equipment.uses_integrity)
		return FALSE
	clear_equipment()
	equipment_ref = WEAKREF(equipment)
	RegisterSignal(equipment, COMSIG_ATOM_INTEGRITY_CHANGED, PROC_REF(on_equipment_damage))
	RegisterSignals(equipment, list(COMSIG_ATOM_FIRE_ACT, COMSIG_ATOM_EMAG_ACT, COMSIG_ATOM_EMP_ACT), PROC_REF(on_equipment_alarm))
	to_chat(imp_in, span_notice("Technical service beacon linked to [equipment]."))
	return TRUE

/mob/living/proc/get_cyberpunk_service_chip(corporation_id)
	RETURN_TYPE(/obj/item/implant/cyberpunk_service)
	for(var/obj/item/implant/cyberpunk_service/chip as anything in implants)
		if(chip.corporation_id == corporation_id)
			return chip
	return null

/obj/item/implant/cyberpunk_service/proc/clear_equipment()
	var/atom/movable/equipment = equipment_ref?.resolve()
	if(equipment)
		UnregisterSignal(equipment, list(COMSIG_ATOM_INTEGRITY_CHANGED, COMSIG_ATOM_FIRE_ACT, COMSIG_ATOM_EMAG_ACT, COMSIG_ATOM_EMP_ACT))
	equipment_ref = null
	emergency_until = 0

/obj/item/implant/cyberpunk_service/proc/on_equipment_damage(atom/source, old_integrity, new_integrity)
	SIGNAL_HANDLER
	if(world.time < emergency_until && new_integrity <= source.integrity_failure * source.max_integrity)
		source.update_integrity(max(1, source.integrity_failure * source.max_integrity + 1))
	if(new_integrity <= source.max_integrity * 0.25)
		on_equipment_alarm(source)

/obj/item/implant/cyberpunk_service/proc/on_equipment_alarm(atom/source)
	SIGNAL_HANDLER
	if(!imp_in || world.time < next_alarm_at || is_implant_disabled() || !imp_in.has_neural_implant())
		return
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	if(!corporation?.has_edict("ryaznov_tech_tracking"))
		return
	next_alarm_at = world.time + 3 MINUTES
	corporation.broadcast_service_alarm(source, "technical emergency")
	if(corporation.is_subscribed(imp_in))
		emergency_until = world.time + 30 SECONDS
		if(source.get_integrity() <= source.integrity_failure * source.max_integrity)
			source.update_integrity(max(1, source.integrity_failure * source.max_integrity + 1))
	addtimer(CALLBACK(src, PROC_REF(dispatch_repair_alarm)), 0)

/obj/item/implant/cyberpunk_service/proc/dispatch_repair_alarm()
	var/atom/equipment = equipment_ref?.resolve()
	if(!equipment || !imp_in)
		return
	var/datum/cyberpunk_ai_task_request/request = new(CP_AI_TASK_REPAIR, equipment, equipment, null, null, 2 MINUTES, get_turf(imp_in), CP_AI_CAP_REPAIR)
	request.dispatch()
	qdel(request)

/datum/ai_controller/basic_controller/simple/cyberpunk_service_guardian
	planning_subtrees = list(/datum/ai_planning_subtree/basic_melee_attack_subtree)
	can_idle = FALSE

/mob/living/basic/cyberpunk_corporate_agent/guardian
	name = "corporate guardian drone"
	agent_title = "guardian drone"
	ai_controller = /datum/ai_controller/basic_controller/simple/cyberpunk_service_guardian
	melee_damage_lower = 5
	melee_damage_upper = 5

/mob/living/basic/cyberpunk_corporate_agent/guardian/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	. = ..()
	if(. && isliving(target))
		var/mob/living/victim = target
		if(corporation_id == CYBERPUNK_CORP_BENN)
			victim.apply_damage(3, BURN, burn_type = BODYPART_DAMAGE_ACID)
		else
			victim.adjust_staggered_up_to(2 SECONDS, 2 SECONDS)

/obj/machinery/vending/proc/set_cyberpunk_corporate_vendor(manufacturer, mob/living/user = null)
	var/corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return FALSE
	cyberpunk_corporate_vendor_id = corporation_id
	corp_manufacturer = manufacturer
	SScyberpunk_corporations.register_cyberpunk_corporate_vendor(src, corporation_id, user)
	return TRUE

/obj/machinery/vending/proc/cyberpunk_corporate_record_sale(amount, product_label)
	if(!cyberpunk_corporate_vendor_id)
		return FALSE
	amount = max(0, round(amount))
	cyberpunk_corporate_vendor_sales++
	cyberpunk_corporate_vendor_revenue += amount
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(cyberpunk_corporate_vendor_id)
	if(!corporation)
		return FALSE
	corporation.record_vendor_sale(src, amount, product_label)
	return TRUE

/obj/machinery/vending/proc/get_cyberpunk_corporate_vendor_ui()
	return list(
		"name" = name,
		"type" = "[type]",
		"area" = get_area_name(src, TRUE),
		"x" = x,
		"y" = y,
		"z" = z,
		"sales" = cyberpunk_corporate_vendor_sales,
		"revenue" = cyberpunk_corporate_vendor_revenue,
		"manufacturer" = corp_manufacturer,
	)

/obj/machinery/vending/cyberpunk_corporate
	name = "corporate vending machine"
	desc = "A vending machine preloaded with a corporate routing bus."
	var/preloaded_corporation_id = CYBERPUNK_CORP_STARLIGHT
	var/preloaded_corporate_manufacturer = "Starlight"
	var/preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/starlight

/obj/machinery/vending/cyberpunk_corporate/Initialize(mapload)
	. = ..()
	if(!has_corporate_vending_module())
		var/datum/cyberpunk_machine_module/module = new preloaded_module_type
		if(can_install_cyberpunk_module(module, null))
			LAZYADD(cyberpunk_machine_modules, module)
			module.on_install(src, null)
		else
			qdel(module)
	set_cyberpunk_corporate_vendor(preloaded_corporate_manufacturer)

/obj/machinery/vending/cyberpunk_corporate/benn
	name = "Benn corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_BENN
	preloaded_corporate_manufacturer = "Benn"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/benn

/obj/machinery/vending/cyberpunk_corporate/ryaznov
	name = "Ryaznov corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_RYAZNOV
	preloaded_corporate_manufacturer = "Ryaznov"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/ryaznov

/obj/machinery/vending/cyberpunk_corporate/starlight
	name = "Starlight corporate vending machine"
	preloaded_corporation_id = CYBERPUNK_CORP_STARLIGHT
	preloaded_corporate_manufacturer = "Starlight"
	preloaded_module_type = /datum/cyberpunk_machine_module/corporate_vending_bus/starlight

/datum/controller/subsystem/cyberpunk_corporations/proc/register_cyberpunk_corporate_vendor(obj/machinery/vending/vendor, corporation_id, mob/living/user = null)
	if(!vendor)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	corporation.register_vendor(vendor, user)
	return TRUE

/datum/cyberpunk_corporation/proc/register_vendor(obj/machinery/vending/vendor, mob/living/user = null)
	if(!vendor)
		return FALSE
	vendor_registry["\ref[vendor]"] = WEAKREF(vendor)
	service_sources[REF(vendor)] = WEAKREF(vendor)
	vendor.sync_cyberpunk_energy_stock()
	add_history("[user ? (user.real_name || user.name) : "system"] registered corporate vendor [vendor.name] at [get_area_name(vendor, TRUE)]")
	return TRUE

/datum/cyberpunk_corporation/proc/record_vendor_sale(obj/machinery/vending/vendor, amount, product_label)
	amount = max(0, round(amount))
	var/vendor_key = "\ref[vendor]"
	var/list/sales = vendor_sales[vendor_key]
	if(!sales)
		sales = list("name" = vendor.name, "sales" = 0, "revenue" = 0, "lastProduct" = null)
		vendor_sales[vendor_key] = sales
	sales["sales"] = (sales["sales"] || 0) + 1
	sales["revenue"] = (sales["revenue"] || 0) + amount
	sales["lastProduct"] = product_label
	add_funds(round(amount * 0.05), "corporate vending fee")
	add_data(get_primary_data_type(), 1, "corporate vending sale")
	return TRUE

/datum/cyberpunk_corporation/proc/get_cyberpunk_corporate_vendors_ui()
	var/list/vendors = list()
	for(var/vendor_ref in vendor_registry)
		var/datum/weakref/vendor_weakref = vendor_registry[vendor_ref]
		var/obj/machinery/vending/vendor = vendor_weakref?.resolve()
		if(!vendor || QDELETED(vendor))
			vendor_registry -= vendor_ref
			continue
		var/list/vendor_data = vendor.get_cyberpunk_corporate_vendor_ui()
		var/list/sales = vendor_sales[vendor_ref]
		if(sales)
			vendor_data["sales"] = max(vendor_data["sales"] || 0, sales["sales"] || 0)
			vendor_data["revenue"] = max(vendor_data["revenue"] || 0, sales["revenue"] || 0)
			vendor_data["lastProduct"] = sales["lastProduct"]
		vendors += list(vendor_data)
	return vendors
