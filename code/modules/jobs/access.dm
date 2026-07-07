/**
 * Returns TRUE if this mob has sufficient access to use this object
 *
 * * accessor - mob trying to access this object, !!CAN BE NULL!! because of telekiesis because we're in hell
 */
/atom/movable/var/cyberpunk_public_access = FALSE

/atom/movable/proc/allowed(mob/accessor)
	//check if it doesn't require any access at all, or the user is an Adminghost
	if(cyberpunk_public_access || check_access(null) || isAdminGhostAI(accessor))
		return TRUE
	if(isnull(accessor)) //likely a TK user, and we checked for free access above.
		return FALSE

	//If the mob has the simple_access component with the requried access, we let them in.
	var/attempted_access = SEND_SIGNAL(accessor, COMSIG_MOB_TRIED_ACCESS, src)
	if(attempted_access & ACCESS_ALLOWED)
		return TRUE
	if(attempted_access & ACCESS_DISALLOWED)
		return FALSE

	var/list/player_access = accessor.get_access()

	//now let's check access we got from the signal.
	if(check_cyberpunk_crypto_access(accessor))
		return TRUE
	if(!isliving(accessor) && check_access_list(player_access))
		return TRUE

	if(HAS_SILICON_ACCESS(accessor))
		if(!(accessor.has_faction(ROLE_SYNDICATE)))
			if((ACCESS_SYNDICATE in req_access) || (ACCESS_SYNDICATE_LEADER in req_access) || (ACCESS_SYNDICATE in req_one_access) || (ACCESS_SYNDICATE_LEADER in req_one_access))
				return FALSE
			if(onSyndieBase() && loc != accessor)
				return FALSE
		return TRUE //AI can do whatever it wants
	return FALSE

// Check if an item has access to this object
/atom/movable/proc/check_access(obj/item/I)
	if(cyberpunk_public_access)
		return TRUE
	if(has_cyberpunk_direct_crypto_requirements() && !I)
		return FALSE
	if(check_cyberpunk_crypto_item_access(I))
		return TRUE
	return check_access_list(I ? I.GetAccess() : null)

//CYBERPUNK BUILD - rebuild and delete before release
/atom/movable/proc/check_access_list(list/access_list)
	if(has_cyberpunk_direct_crypto_requirements())
		return FALSE
	if(!length(req_access) && !length(req_one_access))
		return TRUE

	if(!length(access_list) || !islist(access_list))
		return FALSE

	for(var/req in req_access)
		if(!(req in access_list)) //doesn't have this access
			return FALSE

	if(length(req_one_access))
		for(var/req in req_one_access)
			if(req in access_list) //has an access from the single access list
				return TRUE
		return FALSE
	return TRUE
//CYBERPUNK BUILD - rebuild and delete before release

/proc/get_cyberpunk_crypto_access_code(access_id)
	if(!access_id)
		return null
	return uppertext(copytext(md5("cyberpunk-access|[access_id]"), 1, 21))

/proc/create_cyberpunk_crypto_access_key(access_id)
	if(!access_id)
		return null
	if(SSid_access)
		var/datum/cyberpunk_crypto_key/bank_key = SSid_access.get_cyberpunk_crypto_access_key(access_id)
		if(bank_key)
			return bank_key
	return new /datum/cyberpunk_crypto_key("access: [access_id]", "station access", get_cyberpunk_crypto_access_code(access_id))

/proc/cyberpunk_corporation_access_id(corporation_id)
	switch(lowertext("[corporation_id]"))
		if("benn")
			return "corp:benn"
		if("ryaznov")
			return "corp:ryaznov"
		if("starlight")
			return "corp:starlight"
		if("government", "gov")
			return "city:council"
	return null

/proc/cyberpunk_is_corporate_access(access_id)
	return access_id in list("corp:benn", "corp:ryaznov", "corp:starlight")

/proc/cyberpunk_named_accesses()
	return list(
		"corp:benn" = list("Benn corporate access", "Benn"),
		"corp:ryaznov" = list("Ryaznov corporate access", "Ryaznov"),
		"corp:starlight" = list("Starlight corporate access", "Starlight"),
		"city:council" = list("City Council access", "Council"),
		"city:police" = list("Police access", "Police"),
		"corp:heads" = list("Corporate heads access", "Corporate Heads"),
		"government:all" = list("Government master access", "Government"),
	)

/atom/movable/proc/has_cyberpunk_direct_crypto_requirements()
	if(!("cyberpunk_crypto_keys" in vars))
		return FALSE
	var/list/datum/cyberpunk_crypto_key/direct_keys = vars["cyberpunk_crypto_keys"]
	return length(direct_keys) > 0

/atom/movable/proc/check_cyberpunk_crypto_access(mob/accessor)
	var/mob/living/living_accessor = accessor
	if(!istype(living_accessor))
		return FALSE
	if(has_cyberpunk_direct_crypto_requirements())
		return has_cyberpunk_direct_crypto_key(living_accessor)
	if(!length(req_access) && !length(req_one_access))
		return TRUE
	if(has_cyberpunk_direct_crypto_key(living_accessor))
		return TRUE

	for(var/req in req_access)
		if(!living_accessor.has_cyberpunk_crypto_access(req))
			return FALSE

	if(length(req_one_access))
		for(var/req in req_one_access)
			if(living_accessor.has_cyberpunk_crypto_access(req))
				return TRUE
		return FALSE
	return TRUE

/atom/movable/proc/check_cyberpunk_crypto_item_access(obj/item/item)
	if(!item)
		return FALSE
	if(has_cyberpunk_direct_crypto_requirements())
		return item_has_cyberpunk_direct_crypto_key(item)
	if(!length(req_access) && !length(req_one_access))
		return TRUE
	if(item_has_cyberpunk_direct_crypto_key(item))
		return TRUE

	for(var/req in req_access)
		if(!item.has_cyberpunk_crypto_access(req))
			return FALSE

	if(length(req_one_access))
		for(var/req in req_one_access)
			if(item.has_cyberpunk_crypto_access(req))
				return TRUE
		return FALSE
	return TRUE

/atom/movable/proc/has_cyberpunk_direct_crypto_key(mob/living/accessor)
	if(!("cyberpunk_crypto_keys" in vars))
		return FALSE
	var/list/datum/cyberpunk_crypto_key/direct_keys = vars["cyberpunk_crypto_keys"]
	if(!length(direct_keys))
		return FALSE
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in direct_keys)
		if(!accessor)
			return FALSE
		if(accessor.has_cyberpunk_crypto_key(key_datum) || accessor.held_or_neck_card_has_cyberpunk_crypto_key(key_datum))
			return TRUE
	return FALSE

/atom/movable/proc/item_has_cyberpunk_direct_crypto_key(obj/item/item)
	if(!("cyberpunk_crypto_keys" in vars))
		return FALSE
	var/list/datum/cyberpunk_crypto_key/direct_keys = vars["cyberpunk_crypto_keys"]
	if(!length(direct_keys))
		return FALSE
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in direct_keys)
		if(!item)
			return FALSE
		if(item.has_cyberpunk_crypto_key(key_datum))
			return TRUE
	return FALSE

/mob/living/proc/has_cyberpunk_crypto_access(access_id)
	if(!access_id)
		return TRUE
	if(access_id != "government:all" && has_cyberpunk_crypto_exact_access("government:all"))
		return TRUE
	if(access_id != "corp:heads" && cyberpunk_is_corporate_access(access_id) && has_cyberpunk_crypto_exact_access("corp:heads"))
		return TRUE
	return has_cyberpunk_crypto_exact_access(access_id)

/mob/living/proc/has_cyberpunk_crypto_exact_access(access_id)
	if(!access_id)
		return TRUE
	var/datum/cyberpunk_crypto_key/access_key = create_cyberpunk_crypto_access_key(access_id)
	if(has_cyberpunk_crypto_key(access_key))
		return TRUE
	for(var/obj/item/item as anything in held_items)
		if(!istype(item, /obj/item/card/id))
			continue
		if(item.has_cyberpunk_crypto_exact_access(access_id))
			return TRUE
	var/obj/item/neck_item = get_item_by_slot(ITEM_SLOT_NECK)
	if(istype(neck_item, /obj/item/card/id) && neck_item.has_cyberpunk_crypto_exact_access(access_id))
		return TRUE
	return FALSE

/obj/item/proc/has_cyberpunk_crypto_access(access_id)
	if(!access_id)
		return TRUE
	if(access_id != "government:all" && has_cyberpunk_crypto_exact_access("government:all"))
		return TRUE
	if(access_id != "corp:heads" && cyberpunk_is_corporate_access(access_id) && has_cyberpunk_crypto_exact_access("corp:heads"))
		return TRUE
	return has_cyberpunk_crypto_exact_access(access_id)

/obj/item/proc/has_cyberpunk_crypto_exact_access(access_id)
	if(!access_id)
		return TRUE
	var/datum/cyberpunk_crypto_key/access_key = create_cyberpunk_crypto_access_key(access_id)
	if(has_cyberpunk_crypto_key(access_key))
		return TRUE
	return access_id in GetAccess()

/obj/item/proc/store_cyberpunk_crypto_access(access_id)
	var/datum/cyberpunk_crypto_key/access_key = create_cyberpunk_crypto_access_key(access_id)
	if(!access_key)
		return FALSE
	return store_cyberpunk_crypto_key(access_key)

/obj/item/proc/remove_cyberpunk_crypto_access(access_id)
	var/datum/cyberpunk_crypto_key/access_key = create_cyberpunk_crypto_access_key(access_id)
	if(!access_key)
		return FALSE
	. = remove_cyberpunk_crypto_key(access_key)

/obj/item/proc/clear_cyberpunk_crypto_access_keys()
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in cyberpunk_crypto_keys)
		if(key_datum.owner == "station access" && findtext(key_datum.name, "access: ") == 1)
			cyberpunk_crypto_keys -= key_datum

/obj/item/proc/has_any_cyberpunk_crypto_access(list/accesses)
	if(!length(accesses))
		return TRUE
	for(var/access_id in accesses)
		if(has_cyberpunk_crypto_access(access_id))
			return TRUE
	return FALSE

/mob/living/proc/has_any_cyberpunk_crypto_access(list/accesses)
	if(!length(accesses))
		return TRUE
	for(var/access_id in accesses)
		if(has_cyberpunk_crypto_access(access_id))
			return TRUE
	return FALSE

//CYBERPUNK BUILD - rebuild and delete before release
/obj/item/proc/GetAccess()
	return list()

/obj/item/proc/GetID()
	return null

/obj/item/proc/remove_id()
	return null

/obj/item/proc/insert_id()
	return FALSE
//CYBERPUNK BUILD - rebuild and delete before release
