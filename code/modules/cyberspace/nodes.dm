// Cyberpunk 13 cyberspace: cryptokeys and node access.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/datum/mind/proc/remember_cyber_cryptokey(datum/cyberspace_cryptokey/cryptokey)
	if(!cryptokey?.key)
		return FALSE
	if(!cyber_cryptokeys)
		cyber_cryptokeys = list()
	cyber_cryptokeys[cryptokey.key] = cryptokey
	return TRUE

/datum/mind/proc/has_cyber_cryptokey(datum/cyberspace_cryptokey/cryptokey)
	if(!cryptokey?.key || !cyber_cryptokeys)
		return FALSE
	return !isnull(cyber_cryptokeys[cryptokey.key])

/datum/mind/proc/add_cyber_net_data(amount)
	if(amount <= 0)
		return cyber_net_data
	cyber_net_data += amount
	return cyber_net_data

/datum/cyberspace_node
	/// Physical area this node abstracts.
	var/area/physical_area
	/// Representative physical object for messages and fallback targeting.
	var/atom/movable/anchor
	var/cyber_x = 0
	var/cyber_y = 0
	var/list/linked_object_refs = list()
	var/list/datum/cyberspace_cryptokey/cryptokeys = list()
	var/datum/cyber_ice/ice
	var/net_data = 0
	var/extracted = FALSE

/datum/cyberspace_node/New(atom/movable/source)
	. = ..()
	anchor = source
	physical_area = get_area(source)
	if(source)
		cyber_x = round((world.maxx - source.x) / CYBERSPACE_SCALE_DIVISOR)
		cyber_y = round(source.y / CYBERSPACE_SCALE_DIVISOR)

/datum/cyberspace_node/Destroy(force)
	anchor = null
	physical_area = null
	linked_object_refs = null
	cryptokeys = null
	QDEL_NULL(ice)
	return ..()

/datum/cyberspace_node/proc/add_object(atom/movable/target)
	if(!target || length(linked_object_refs) >= CYBERSPACE_NODE_MAX_OBJECTS)
		return FALSE
	if(has_object(target))
		return FALSE
	linked_object_refs += WEAKREF(target)
	cryptokeys += new /datum/cyberspace_cryptokey(target)
	net_data += get_cyberspace_net_data_amount(target)
	QDEL_NULL(ice)
	return TRUE

/datum/cyberspace_node/proc/has_object(atom/movable/target)
	if(!target)
		return FALSE
	for(var/datum/weakref/object_ref as anything in linked_object_refs)
		if(object_ref.resolve() == target)
			return TRUE
	return FALSE

/datum/cyberspace_node/proc/get_object_count()
	return length(linked_object_refs)

/datum/cyberspace_node/proc/can_merge_with(datum/cyberspace_node/other_node)
	if(!other_node)
		return FALSE
	if(get_object_count() + other_node.get_object_count() > CYBERSPACE_NODE_MAX_OBJECTS)
		return FALSE
	return abs(cyber_x - other_node.cyber_x) <= CYBERSPACE_NODE_MERGE_RANGE && abs(cyber_y - other_node.cyber_y) <= CYBERSPACE_NODE_MERGE_RANGE

/datum/cyberspace_node/proc/merge_from(datum/cyberspace_node/other_node)
	if(!other_node || !can_merge_with(other_node))
		return FALSE
	var/original_count = max(1, get_object_count())
	var/other_count = max(1, other_node.get_object_count())
	cyber_x = round(((cyber_x * original_count) + (other_node.cyber_x * other_count)) / (original_count + other_count))
	cyber_y = round(((cyber_y * original_count) + (other_node.cyber_y * other_count)) / (original_count + other_count))
	for(var/datum/weakref/object_ref as anything in other_node.linked_object_refs)
		var/atom/movable/object = object_ref.resolve()
		if(object)
			add_object(object)
	return TRUE

/datum/cyberspace_node/proc/get_ice() as /datum/cyber_ice
	if(!ice)
		ice = create_cyber_node_ice(max(1, get_object_count()))
	return ice

/datum/cyberspace_node/proc/start_ice_hack(mob/living/hacker, datum/cyberspace_cryptokey/provided_key = null)
	if(!hacker)
		return null
	if(has_access(hacker, provided_key))
		to_chat(hacker, span_notice("Cryptographic key accepted. Node ICE bypassed."))
		return TRUE
	var/datum/cyber_ice_hack_session/session = new(hacker, get_ice(), anchor, hacker.get_cyber_hacking_skill(), TRUE, get_object_count())
	session.ui_interact(hacker)
	return session

/datum/cyberspace_node/proc/has_access(mob/living/user, datum/cyberspace_cryptokey/provided_key = null)
	if(get_ice().is_breached())
		return TRUE
	if(provided_key)
		for(var/datum/cyberspace_cryptokey/cryptokey as anything in cryptokeys)
			if(cryptokey.matches(provided_key))
				return TRUE
	if(user?.mind)
		for(var/datum/cyberspace_cryptokey/cryptokey as anything in cryptokeys)
			if(user.mind.has_cyber_cryptokey(cryptokey))
				return TRUE
	return FALSE

/datum/cyberspace_node/proc/extract_net_data(mob/living/user)
	if(!user || extracted || !has_access(user))
		return 0
	extracted = TRUE
	for(var/datum/cyberspace_cryptokey/cryptokey as anything in cryptokeys)
		user.mind?.remember_cyber_cryptokey(cryptokey)
	var/extracted_data = net_data
	net_data = 0
	user.mind?.add_cyber_net_data(extracted_data)
	return extracted_data

/datum/cyberspace_node/proc/run_control_mode(mob/living/user, atom/movable/target, mode = "control")
	if(!user || !target || !has_access(user))
		return FALSE
	switch(mode)
		if("control")
			to_chat(user, span_notice("Node grants control access to [target]."))
		if("glitch")
			target.emag_act(user)
		if("short")
			target.emp_act(EMP_HEAVY)
		if("settings")
			to_chat(user, span_notice("Node exposes settings for [target]."))
		else
			return FALSE
	return TRUE

/datum/cyberspace_node/proc/get_live_objects()
	var/list/live_objects = list()
	for(var/datum/weakref/object_ref as anything in linked_object_refs)
		var/atom/movable/object = object_ref.resolve()
		if(object)
			live_objects += object
	return live_objects
