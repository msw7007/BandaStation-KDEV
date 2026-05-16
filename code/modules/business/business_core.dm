/datum/cy_business
	var/business_id
	var/name = "Unnamed Business"
	var/business_type = "general"
	var/legal_status = CY_BUSINESS_LEGAL
	var/size_type = CY_BUSINESS_SIZE_SMALL
	var/owner_ckey
	var/list/employees = list()
	var/list/employee_wages = list()
	var/list/permissions = list()
	var/datum/bank_account/account
	var/account_id
	var/tax_debt = 0
	var/tax_due_per_cycle = CY_BUSINESS_DEFAULT_TAX_DUE
	var/tax_missed_cycles = 0
	var/risk_score = CY_BUSINESS_RISK_LOW
	var/corporate_partner
	var/last_saved_time = 0
	var/list/saved_snapshot = list()
	var/zone_ref
	var/zone_name
	var/tmp/obj/structure/cy_business_zone/locate_zone

/datum/cy_business/New()
	. = ..()
	if(!employees)
		employees = list()
	if(!employee_wages)
		employee_wages = list()
	if(!permissions)
		permissions = list()
	if(!saved_snapshot)
		saved_snapshot = list()

/datum/cy_business/Destroy()
	locate_zone?.active_business = null
	locate_zone = null
	return ..()

/datum/cy_business/proc/setup_account()
	if(account)
		return account
	account = new /datum/bank_account(name, null, 1, FALSE)
	account_id = account.account_id
	return account

/datum/cy_business/proc/is_owner(mob/user)
	return !!user?.ckey && user.ckey == owner_ckey

/datum/cy_business/proc/has_employee(mob/user)
	return !!user?.ckey && (user.ckey in employees)

/datum/cy_business/proc/can_manage(mob/user)
	if(is_owner(user))
		return TRUE
	if(!user?.ckey)
		return FALSE
	return permissions[user.ckey] == "manager"

/datum/cy_business/proc/add_employee(ckey, wage = 0, permission = "worker")
	if(!ckey)
		return FALSE
	employees |= ckey
	employee_wages[ckey] = max(0, round(wage))
	permissions[ckey] = permission
	return TRUE

/datum/cy_business/proc/remove_employee(ckey)
	if(!ckey)
		return FALSE
	employees -= ckey
	employee_wages -= ckey
	permissions -= ckey
	return TRUE

/datum/cy_business/proc/adjust_balance(amount, reason = "Business transaction")
	setup_account()
	return account.adjust_money(amount, reason)

/datum/cy_business/proc/reserve_payment(amount, reason = "Business reserve")
	setup_account()
	if(amount <= 0)
		return TRUE
	return account.adjust_money(-amount, reason)

/datum/cy_business/proc/pay_tax(amount = tax_due_per_cycle)
	setup_account()
	if(!account.adjust_money(-amount, "Business tax"))
		tax_debt += amount
		tax_missed_cycles++
		refresh_risk()
		return FALSE
	tax_debt = max(0, tax_debt - amount)
	tax_missed_cycles = 0
	refresh_risk()
	return TRUE

/datum/cy_business/proc/refresh_risk()
	var/new_risk = CY_BUSINESS_RISK_LOW
	if(legal_status == CY_BUSINESS_ILLEGAL)
		new_risk += 40
	else if(legal_status == CY_BUSINESS_FRONT)
		new_risk += 20
	new_risk += tax_missed_cycles * 15
	if(tax_debt > 0)
		new_risk += clamp(round(tax_debt / 100), 1, 30)
	if(corporate_partner)
		new_risk = max(0, new_risk - 10)
	risk_score = clamp(new_risk, 0, 100)
	return risk_score

/datum/cy_business/proc/capture_snapshot()
	saved_snapshot = list()
	var/area/business_area = get_business_area()
	if(!business_area)
		return saved_snapshot
	for(var/turf/turf_to_scan as anything in get_area_turfs(business_area))
		for(var/obj/object_to_save in turf_to_scan)
			if(!object_to_save.cy_business_should_persist(src))
				continue
			var/list/entry = object_to_save.cy_business_serialize(src)
			if(entry)
				saved_snapshot += list(entry)
	last_saved_time = world.time
	return saved_snapshot

/datum/cy_business/proc/restore_snapshot()
	if(!length(saved_snapshot))
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	for(var/turf/turf_to_clean as anything in get_area_turfs(business_area))
		for(var/obj/object_to_remove in turf_to_clean)
			if(object_to_remove.cy_business_should_persist(src))
				qdel(object_to_remove)
	for(var/list/entry as anything in saved_snapshot)
		cy_business_restore_object(entry)
	return TRUE

/datum/cy_business/proc/save_to_disk()
	capture_snapshot()
	var/path = get_save_path()
	var/list/data = to_list(include_snapshot = TRUE)
	fdel(path)
	text2file(json_encode(data, JSON_PRETTY_PRINT), path)
	return TRUE

/datum/cy_business/proc/load_from_disk()
	var/path = get_save_path()
	if(!fexists(path))
		return FALSE
	var/list/data = json_decode(file2text(path))
	load_from_list(data)
	return TRUE

/datum/cy_business/proc/get_save_path()
	return "[CY_BUSINESS_SAVE_ROOT]/[business_id].json"

/datum/cy_business/proc/get_business_area()
	if(locate_zone)
		return get_area(locate_zone)
	return null

/datum/cy_business/proc/to_list(include_snapshot = FALSE)
	var/list/data = list()
	data["business_id"] = business_id
	data["name"] = name
	data["business_type"] = business_type
	data["legal_status"] = legal_status
	data["size_type"] = size_type
	data["owner_ckey"] = owner_ckey
	data["employees"] = employees.Copy()
	data["employee_wages"] = employee_wages.Copy()
	data["permissions"] = permissions.Copy()
	data["tax_debt"] = tax_debt
	data["tax_missed_cycles"] = tax_missed_cycles
	data["risk_score"] = risk_score
	data["corporate_partner"] = corporate_partner
	data["last_saved_time"] = last_saved_time
	data["zone_ref"] = zone_ref
	data["zone_name"] = zone_name
	data["account_balance"] = account?.account_balance || 0
	if(include_snapshot)
		data["saved_snapshot"] = saved_snapshot.Copy()
	return data

/datum/cy_business/proc/load_from_list(list/data)
	if(!data)
		return FALSE
	business_id = data["business_id"] || business_id
	name = data["name"] || name
	business_type = data["business_type"] || business_type
	legal_status = data["legal_status"] || legal_status
	size_type = data["size_type"] || size_type
	owner_ckey = data["owner_ckey"] || owner_ckey
	employees = data["employees"] || list()
	employee_wages = data["employee_wages"] || list()
	permissions = data["permissions"] || list()
	tax_debt = data["tax_debt"] || 0
	tax_missed_cycles = data["tax_missed_cycles"] || 0
	risk_score = data["risk_score"] || risk_score
	corporate_partner = data["corporate_partner"]
	last_saved_time = data["last_saved_time"] || 0
	zone_ref = data["zone_ref"] || zone_ref
	zone_name = data["zone_name"] || zone_name
	saved_snapshot = data["saved_snapshot"] || saved_snapshot || list()
	setup_account()
	account.account_balance = data["account_balance"] || account.account_balance
	return TRUE

/atom/proc/cy_business_should_persist(datum/cy_business/business)
	return FALSE

/obj/cy_business_should_persist(datum/cy_business/business)
	if(anchored || density)
		return TRUE
	return FALSE

/obj/proc/cy_business_serialize(datum/cy_business/business)
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return null
	return list(
		"type" = "[type]",
		"x" = current_turf.x,
		"y" = current_turf.y,
		"z" = current_turf.z,
		"dir" = dir,
		"name" = name,
		"desc" = desc,
		"pixel_x" = pixel_x,
		"pixel_y" = pixel_y,
	)

/proc/cy_business_restore_object(list/entry)
	if(!entry)
		return null
	var/path_text = entry["type"]
	var/object_type = text2path(path_text)
	if(!ispath(object_type, /obj))
		return null
	var/turf/target_turf = locate(entry["x"], entry["y"], entry["z"])
	if(!target_turf)
		return null
	var/obj/new_object = new object_type(target_turf)
	new_object.dir = entry["dir"] || SOUTH
	new_object.name = entry["name"] || initial(new_object.name)
	new_object.desc = entry["desc"] || initial(new_object.desc)
	new_object.pixel_x = entry["pixel_x"] || 0
	new_object.pixel_y = entry["pixel_y"] || 0
	return new_object
