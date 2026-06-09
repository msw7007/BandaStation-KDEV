// Cyberpunk 13 cyberspace: cryptokeys and node access.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/datum/mind/proc/remember_cyber_cryptokey(datum/cyberspace_cryptokey/cryptokey)
	if(!cryptokey?.key)
		return FALSE
	if(!cyber_cryptokeys)
		cyber_cryptokeys = list()
	cyber_cryptokeys[cryptokey.key] = cryptokey
	if(ismob(current))
		var/mob/memory_owner = current
		memory_owner.remember_data("cryptokey:[cryptokey.key]", list(
			"key" = cryptokey.key,
			"manufacturer" = cryptokey.manufacturer,
			"object_type" = cryptokey.object_type,
			"area_type" = cryptokey.area_type,
			"rights" = cryptokey.rights?.Copy(),
		))
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
	/// Physical area type is kept separately so nearest-node lookup can prefer the local area even if the area datum changes.
	var/physical_area_type
	/// Representative source-world Z level. Aggregate nodes can merge same-area objects across main-map Z levels.
	var/source_z = 0
	/// Single-object trace nodes are rendered as TRACE and never merged into aggregate area nodes.
	var/trace_only = FALSE
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
	physical_area_type = physical_area?.type
	if(source)
		source_z = source.z
		cyber_x = source.x
		cyber_y = source.y

/datum/cyberspace_node/Destroy(force)
	anchor = null
	physical_area = null
	physical_area_type = null
	linked_object_refs = null
	cryptokeys = null
	QDEL_NULL(ice)
	return ..()

/datum/cyberspace_node/proc/prune_dead_object_refs()
	if(!linked_object_refs)
		linked_object_refs = list()
		return 0
	for(var/index in length(linked_object_refs) to 1 step -1)
		var/datum/weakref/object_ref = linked_object_refs[index]
		if(!object_ref || !object_ref.resolve())
			linked_object_refs.Cut(index, index + 1)
	return length(linked_object_refs)

/datum/cyberspace_node/proc/add_object(atom/movable/target, recenter = TRUE)
	prune_dead_object_refs()
	if(!target || length(linked_object_refs) >= CYBERSPACE_NODE_MAX_OBJECTS)
		return FALSE
	if(has_object(target))
		return FALSE
	var/old_count = length(linked_object_refs)
	linked_object_refs += WEAKREF(target)
	cryptokeys += new /datum/cyberspace_cryptokey(target)
	net_data += get_cyberspace_net_data_amount(target)
	if(recenter)
		var/new_count = old_count + 1
		cyber_x = round(((cyber_x * old_count) + target.x) / new_count)
		cyber_y = round(((cyber_y * old_count) + target.y) / new_count)
	QDEL_NULL(ice)
	return TRUE

/datum/cyberspace_node/proc/has_object(atom/movable/target)
	if(!target)
		return FALSE
	prune_dead_object_refs()
	for(var/datum/weakref/object_ref as anything in linked_object_refs)
		if(!object_ref)
			continue
		if(object_ref.resolve() == target)
			return TRUE
	return FALSE

/datum/cyberspace_node/proc/get_object_count()
	prune_dead_object_refs()
	return length(linked_object_refs)

/datum/cyberspace_node/proc/can_merge_with(datum/cyberspace_node/other_node)
	if(!other_node)
		return FALSE
	if(trace_only || other_node.trace_only)
		return FALSE
	if(get_object_count() + other_node.get_object_count() > CYBERSPACE_NODE_MAX_OBJECTS)
		return FALSE
	var/x_delta = cyber_x - other_node.cyber_x
	var/y_delta = cyber_y - other_node.cyber_y
	return sqrt((x_delta * x_delta) + (y_delta * y_delta)) <= CYBERSPACE_NODE_MERGE_RANGE

/datum/cyberspace_node/proc/merge_from(datum/cyberspace_node/other_node)
	if(!other_node || !can_merge_with(other_node))
		return FALSE
	var/original_count = max(1, get_object_count())
	var/other_count = max(1, other_node.get_object_count())
	if(!source_z)
		source_z = other_node.source_z
	cyber_x = round(((cyber_x * original_count) + (other_node.cyber_x * other_count)) / (original_count + other_count))
	cyber_y = round(((cyber_y * original_count) + (other_node.cyber_y * other_count)) / (original_count + other_count))
	var/list/refs_to_merge = other_node.linked_object_refs?.Copy() || list()
	for(var/datum/weakref/object_ref as anything in refs_to_merge)
		if(!object_ref)
			continue
		var/atom/movable/object = object_ref.resolve()
		if(object)
			add_object(object, FALSE)
	return TRUE

/datum/cyberspace_node/proc/get_ice() as /datum/cyber_ice
	if(!ice)
		ice = create_cyber_node_ice(max(1, get_object_count()), get_manufacturer_diversity_bonus())
	return ice

/datum/cyberspace_node/proc/get_manufacturer_diversity_count()
	var/list/seen_manufacturers = list()
	for(var/datum/cyberspace_cryptokey/cryptokey as anything in cryptokeys)
		var/manufacturer = cyberpunk_normalize_manufacturer_id(cryptokey.manufacturer)
		if(!manufacturer || manufacturer == "none")
			continue
		seen_manufacturers[manufacturer] = TRUE
	return length(seen_manufacturers)

/datum/cyberspace_node/proc/get_manufacturer_diversity_bonus()
	return max(0, get_manufacturer_diversity_count() - 1) * CYBERSPACE_NODE_MANUFACTURER_DIVERSITY_BONUS

/datum/cyberspace_node/proc/can_open_ice_hack()
	for(var/atom/movable/object as anything in get_live_objects())
		if(is_cyberspace_ice_hack_target(object))
			return TRUE
	return FALSE

/datum/cyberspace_node/proc/start_ice_hack(mob/living/hacker, datum/cyberspace_cryptokey/provided_key = null)
	if(!hacker)
		return null
	if(!can_open_ice_hack())
		to_chat(hacker, span_warning("This node has no neural interface or server-grade ICE endpoint. Use direct attack, connection, or node actions instead."))
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

/datum/cyberspace_node/proc/get_protection_integrity_percent()
	var/datum/cyber_ice/node_ice = get_ice()
	var/max_reserve = max(1, node_ice.get_max_reserve())
	return clamp(round((node_ice.current_reserve / max_reserve) * 100), 0, 100)

/datum/cyberspace_node/proc/can_use_control_function(mob/living/user, function_id)
	switch(function_id)
		if("control")
			return has_access(user)
		if("open_ui")
			return has_access(user)
		if("settings")
			return has_access(user)
		if("emag_activate")
			return get_protection_integrity_percent() <= CYBERSPACE_NODE_EMAG_INTEGRITY_THRESHOLD
		if("emp_activate")
			return get_protection_integrity_percent() <= CYBERSPACE_NODE_EMP_INTEGRITY_THRESHOLD
		if("shutdown")
			return get_protection_integrity_percent() <= CYBERSPACE_NODE_SHUTDOWN_INTEGRITY_THRESHOLD
	return FALSE

/datum/cyberspace_node/proc/extract_net_data(mob/living/user)
	if(!user || extracted || !has_access(user))
		return 0
	extracted = TRUE
	for(var/datum/cyberspace_cryptokey/cryptokey as anything in cryptokeys)
		user.mind?.remember_cyber_cryptokey(cryptokey)
	var/extracted_data = net_data + round(user.mind?.get_character_perk_effectiveness(SKILL_HACKING, 6) || 0)
	net_data = 0
	user.mind?.add_cyber_net_data(extracted_data)
	return extracted_data

/datum/cyberspace_node/proc/get_cyber_attack_damage(mob/living/user)
	var/damage = max(1, user?.get_cyber_hacking_skill() || 0)
	var/damage_bonus = user?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 2) || 0
	if(damage_bonus > 0)
		damage += round(damage * (damage_bonus / 100))
	return max(1, damage)

/datum/cyberspace_node/proc/get_cyber_attack_time(mob/living/user)
	return max(1 SECONDS, CYBERSPACE_BASE_ATTACK_TIME - ((user?.get_cyber_hacking_skill() || 0) SECONDS))

/datum/cyberspace_node/proc/get_cyber_connection_time(mob/living/user, stealth = TRUE)
	var/base_time = stealth ? CYBERSPACE_STEALTH_CONNECTION_BASE_TIME : CYBERSPACE_OPEN_CONNECTION_BASE_TIME
	var/connection_time = base_time - ((user?.get_cyber_hacking_skill() || 0) SECONDS)
	var/connection_bonus = user?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 3) || 0
	if(connection_bonus > 0)
		connection_time *= max(0, 1 - (connection_bonus / 100))
	return max(CYBERSPACE_CONNECTION_MIN_TIME, round(connection_time))

/datum/cyberspace_node/proc/get_stealth_alarm_chance(mob/living/user)
	var/alarm_chance = CYBERSPACE_STEALTH_ALARM_CHANCE - ((user?.get_cyber_hacking_skill() || 0) * CYBERSPACE_HACKING_ALARM_REDUCTION_PER_LEVEL)
	alarm_chance -= round(user?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 1) || 0)
	return clamp(alarm_chance, 0, 100)

/datum/cyberspace_node/proc/roll_connection_alarm(mob/living/user, atom/visual_anchor, stealth = TRUE)
	if(!stealth)
		if(!should_suppress_damage_alarm(user))
			get_ice().trigger_alarm(user, visual_anchor || anchor, "loud cyberspace connection")
		return TRUE
	var/alarm_chance = get_stealth_alarm_chance(user)
	if(alarm_chance > 0 && prob(alarm_chance))
		get_ice().trigger_alarm(user, visual_anchor || anchor, "stealth connection detected")
		return TRUE
	return FALSE

/datum/cyberspace_node/proc/perform_cyber_attack(mob/living/user, atom/visual_anchor)
	if(!user)
		return FALSE
	var/damage = get_cyber_attack_damage(user)
	get_ice().apply_reserve_damage(damage)
	roll_connection_alarm(user, visual_anchor, FALSE)
	if(get_ice().is_breached())
		to_chat(user, span_notice("[visual_anchor || anchor] digital protection breaks open."))
	else
		to_chat(user, span_notice("You damage [visual_anchor || anchor] digital protection by [damage]. Reserve left: [get_ice().current_reserve]."))
	return TRUE

/datum/cyberspace_node/proc/should_suppress_damage_alarm(mob/living/user)
	var/suppress_chance = user?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 5) || 0
	return suppress_chance > 0 && prob(suppress_chance)

/datum/cyberspace_node/proc/start_cyberspace_attack(mob/living/user, atom/visual_anchor)
	if(!user?.cyberspace_session || !visual_anchor)
		return FALSE
	if(!cyberspace_node_requires_adjacent(user, visual_anchor))
		return FALSE
	var/datum/cyberspace_session/session = user.cyberspace_session
	if(session.attack_token)
		return session.cancel_cyber_attack()
	if(has_access(user))
		to_chat(user, span_notice("[visual_anchor] is already open to you."))
		return FALSE
	if(!session.start_cyber_attack(visual_anchor))
		return FALSE
	var/current_token = session.attack_token
	to_chat(user, span_notice("You start a direct cyberspace attack against [visual_anchor]."))
	if(!do_after(user, get_cyber_attack_time(user), target = visual_anchor, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		if(session.is_current_cyber_attack(current_token))
			session.cancel_cyber_attack()
		return FALSE
	if(!session.finish_cyber_attack(current_token))
		return FALSE
	return perform_cyber_attack(user, visual_anchor)

/datum/cyberspace_node/proc/start_cyberspace_connection(mob/living/user, atom/visual_anchor)
	if(!user?.cyberspace_session || !visual_anchor)
		return FALSE
	if(!cyberspace_node_requires_adjacent(user, visual_anchor))
		return FALSE
	var/datum/cyberspace_session/session = user.cyberspace_session
	if(session.is_connected_to_node(src))
		to_chat(user, span_notice("Your avatar is already connected to [visual_anchor]."))
		return TRUE
	var/stealth = !user.combat_mode
	var/connection_time = get_cyber_connection_time(user, stealth)
	to_chat(user, span_notice("You start [stealth ? "a quiet" : "a loud"] connection to [visual_anchor]."))
	if(!do_after(user, connection_time, target = visual_anchor, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		to_chat(user, span_warning("Connection attempt interrupted."))
		return FALSE
	session.connect_to_node(src, visual_anchor)
	roll_connection_alarm(user, visual_anchor, stealth)
	return TRUE

/datum/cyberspace_node/proc/extract_connected_net_data(mob/living/user, atom/visual_anchor)
	if(!user?.cyberspace_session)
		return 0
	if(visual_anchor && !cyberspace_node_requires_adjacent(user, visual_anchor))
		return 0
	if(!user.cyberspace_session.is_connected_to_node(src))
		to_chat(user, span_warning("You need an active connection to [visual_anchor || anchor] before extracting net-data."))
		return 0
	var/extracted_data = extract_net_data(user)
	if(extracted_data > 0)
		to_chat(user, span_notice("You extract [extracted_data] net-data and cached cryptographic keys from [visual_anchor || anchor]. Total net-data: [user.mind?.cyber_net_data || 0]."))
	else if(!has_access(user))
		to_chat(user, span_warning("[visual_anchor || anchor] is still protected. Break protection before extracting data."))
	else
		to_chat(user, span_warning("[visual_anchor || anchor] has no accessible net-data."))
	return extracted_data

/datum/cyberspace_node/proc/run_control_mode(mob/living/user, atom/movable/target, mode = "control", atom/visual_anchor)
	if(!user || !target)
		return FALSE
	if(visual_anchor && !cyberspace_node_requires_adjacent(user, visual_anchor))
		return FALSE
	if(!can_use_control_function(user, mode))
		to_chat(user, span_warning("Cyberspace command failed: [target] refuses [mode]. Break more protection or use a valid cryptographic key."))
		return FALSE
	switch(mode)
		if("control")
			to_chat(user, span_notice("Node grants control access to [target]."))
		if("open_ui")
			return cyberspace_target_open_ui(user, target)
		if("emag_activate")
			return cyberspace_target_emag(user, target)
		if("emp_activate")
			return cyberspace_target_emp(user, target)
		if("shutdown")
			return cyberspace_target_shutdown(user, target)
		if("settings")
			return cyberspace_target_settings(user, target)
		else
			return FALSE
	return TRUE

/proc/cyberspace_target_can_open_ui(atom/movable/target)
	return !isnull(target) && hascall(target, "ui_interact")

/proc/cyberspace_target_can_settings(atom/movable/target)
	return cyberspace_target_can_open_ui(target)

/proc/cyberspace_target_can_emag(atom/movable/target)
	return !isnull(target) && hascall(target, "emag_act")

/proc/cyberspace_target_can_emp(atom/movable/target)
	return !isnull(target) && hascall(target, "emp_act")

/proc/cyberspace_target_can_shutdown(atom/movable/target)
	return istype(target, /obj/machinery)

/proc/cyberspace_target_open_ui(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_open_ui(target))
		to_chat(user, span_warning("[target] does not expose a remote interface."))
		return FALSE
	to_chat(user, span_notice("Cyberspace command accepted: opening remote interface for [target]."))
	call(target, "ui_interact")(user)
	return TRUE

/proc/cyberspace_target_settings(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_settings(target))
		to_chat(user, span_warning("[target] does not expose configurable remote settings."))
		return FALSE
	to_chat(user, span_notice("Cyberspace command accepted: opening remote settings for [target]."))
	call(target, "ui_interact")(user)
	return TRUE

/proc/cyberspace_target_emag(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_emag(target))
		to_chat(user, span_warning("[target] does not expose /proc/emag_activate(target)."))
		return FALSE
	to_chat(user, span_notice("Cyberspace command accepted: executing /proc/emag_activate(target) on [target]."))
	var/result = call(target, "emag_act")(user)
	to_chat(user, result ? span_notice("/proc/emag_activate(target) reports success.") : span_warning("/proc/emag_activate(target) reports no visible effect."))
	return TRUE

/proc/cyberspace_target_emp(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_emp(target))
		to_chat(user, span_warning("[target] does not expose /proc/emp_activate(target)."))
		return FALSE
	to_chat(user, span_notice("Cyberspace command accepted: executing /proc/emp_activate(target) on [target]."))
	var/result = call(target, "emp_act")(EMP_HEAVY)
	to_chat(user, result ? span_notice("/proc/emp_activate(target) reports success.") : span_warning("/proc/emp_activate(target) reports no visible confirmation."))
	return TRUE

/proc/cyberspace_target_shutdown(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_shutdown(target))
		to_chat(user, span_warning("[target] does not expose a shutdown channel."))
		return FALSE
	var/obj/machinery/target_machine = target
	to_chat(user, span_notice("Cyberspace command accepted: executing /proc/shutdown(target) on [target]."))
	target_machine.set_machine_stat(target_machine.machine_stat | NOPOWER)
	return TRUE

/datum/cyberspace_node/proc/get_live_objects()
	var/list/live_objects = list()
	prune_dead_object_refs()
	for(var/datum/weakref/object_ref as anything in linked_object_refs)
		if(!object_ref)
			continue
		var/atom/movable/object = object_ref.resolve()
		if(object)
			live_objects += object
	return live_objects
