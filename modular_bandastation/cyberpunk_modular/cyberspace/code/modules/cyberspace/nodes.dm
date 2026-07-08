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
	var/list/datum/cyber_ice/object_ice_by_ref = list()
	var/list/object_net_data_by_ref = list()
	var/list/extracted_object_refs = list()
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
	object_ice_by_ref = null
	object_net_data_by_ref = null
	extracted_object_refs = null
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
	var/ref_key = get_object_ref_key(target)
	var/object_net_data = get_cyberspace_net_data_amount(target)
	object_ice_by_ref[ref_key] = create_cyber_object_ice(target)
	object_net_data_by_ref[ref_key] = object_net_data
	net_data += object_net_data
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

/datum/cyberspace_node/proc/get_object_ref_key(atom/movable/target)
	return target ? REF(target) : null

/datum/cyberspace_node/proc/get_object_ice(atom/movable/target) as /datum/cyber_ice
	var/ref_key = get_object_ref_key(target)
	if(!ref_key)
		return null
	var/datum/cyber_ice/object_ice = object_ice_by_ref[ref_key]
	if(!object_ice)
		object_ice = create_cyber_object_ice(target)
		object_ice_by_ref[ref_key] = object_ice
	return object_ice

/datum/cyberspace_node/proc/get_object_protection_integrity_percent(atom/movable/target)
	var/datum/cyber_ice/object_ice = get_object_ice(target)
	if(!object_ice)
		return 0
	var/max_reserve = max(1, object_ice.get_max_reserve())
	return clamp(round((object_ice.current_reserve / max_reserve) * 100), 0, 100)

/datum/cyberspace_node/proc/object_key_matches_user(mob/living/user, atom/movable/target)
	if(!user?.mind || !target)
		return FALSE
	var/datum/cyberspace_cryptokey/target_key = new(target)
	var/result = user.mind.has_cyber_cryptokey(target_key)
	qdel(target_key)
	return result

/datum/cyberspace_node/proc/has_object_access(mob/living/user, atom/movable/target)
	if(!target)
		return has_access(user)
	var/datum/cyber_ice/object_ice = get_object_ice(target)
	return has_access(user) || object_key_matches_user(user, target) || object_ice?.is_breached()

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

/datum/cyberspace_node/proc/can_use_control_function(mob/living/user, function_id, atom/movable/target = null)
	var/has_target_access = has_object_access(user, target)
	var/protection_integrity = target ? get_object_protection_integrity_percent(target) : get_protection_integrity_percent()
	switch(function_id)
		if("control")
			return has_target_access
		if("open_ui")
			return has_target_access
		if("settings")
			return has_target_access
		if("door_toggle")
			return has_target_access
		if("camera_inspect")
			return has_target_access
		if("camera_rotate")
			return has_target_access
		if("panel_toggle")
			return has_target_access
		if("power_toggle")
			return has_target_access
		if("contraband_toggle")
			return has_target_access
		if("apc_breaker_toggle")
			return has_target_access
		if("apc_nightshift_toggle")
			return has_target_access
		if("turret_power_toggle")
			return has_target_access
		if("turret_lethal_toggle")
			return has_target_access
		if("turret_silicon_toggle")
			return has_target_access
		if("light_toggle")
			return has_target_access
		if("device_toggle")
			return has_target_access
		if("bolt_toggle")
			return protection_integrity <= CYBERSPACE_NODE_EMP_INTEGRITY_THRESHOLD || has_target_access
		if("electrify_toggle")
			return protection_integrity <= CYBERSPACE_NODE_EMP_INTEGRITY_THRESHOLD || has_target_access
		if("emag_activate")
			return protection_integrity <= CYBERSPACE_NODE_EMAG_INTEGRITY_THRESHOLD
		if("emp_activate")
			return protection_integrity <= CYBERSPACE_NODE_EMP_INTEGRITY_THRESHOLD
		if("shutdown")
			return protection_integrity <= CYBERSPACE_NODE_SHUTDOWN_INTEGRITY_THRESHOLD
	return FALSE

/datum/cyberspace_node/proc/extract_net_data(mob/living/user)
	if(!user || extracted)
		return 0
	var/extracted_data = 0
	var/extracted_count = 0
	for(var/atom/movable/object as anything in get_live_objects())
		var/ref_key = get_object_ref_key(object)
		if(!ref_key || extracted_object_refs[ref_key] || !has_object_access(user, object))
			continue
		extracted_count++
		extracted_object_refs[ref_key] = TRUE
		var/object_data = object_net_data_by_ref[ref_key] || 0
		extracted_data += object_data
		net_data = max(0, net_data - object_data)
		var/datum/cyberspace_cryptokey/object_key = new(object)
		user.mind?.remember_cyber_cryptokey(object_key)
	if(extracted_count > 0)
		extracted_data += round(user.mind?.get_character_perk_effectiveness(SKILL_HACKING, 6) || 0)
	if(net_data <= 0)
		extracted = TRUE
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
	var/atom/movable/target_object = get_visual_anchor_object(visual_anchor)
	var/datum/cyber_ice/target_ice = target_object ? get_object_ice(target_object) : get_ice()
	target_ice.apply_reserve_damage(damage)
	roll_connection_alarm(user, visual_anchor, FALSE)
	if(target_ice.is_breached())
		to_chat(user, span_notice("[visual_anchor || anchor] digital protection breaks open."))
	else
		to_chat(user, span_notice("You damage [visual_anchor || anchor] digital protection by [damage]. Reserve left: [target_ice.current_reserve]."))
	return TRUE

/datum/cyberspace_node/proc/should_suppress_damage_alarm(mob/living/user)
	var/suppress_chance = user?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 5) || 0
	return suppress_chance > 0 && prob(suppress_chance)

/datum/cyberspace_node/proc/get_visual_anchor_object(atom/visual_anchor)
	var/obj/effect/cyberspace_object_trace/trace = visual_anchor
	if(istype(trace))
		return trace.linked_object_ref?.resolve()
	return null

/datum/cyberspace_node/proc/start_cyberspace_attack(mob/living/user, atom/visual_anchor)
	if(!user?.cyberspace_session || !visual_anchor)
		return FALSE
	if(!cyberspace_node_requires_adjacent(user, visual_anchor))
		return FALSE
	var/datum/cyberspace_session/session = user.cyberspace_session
	if(session.attack_token)
		return session.cancel_cyber_attack()
	var/atom/movable/target_object = get_visual_anchor_object(visual_anchor)
	if(target_object ? has_object_access(user, target_object) : has_access(user))
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
	if(!can_use_control_function(user, mode, target))
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
		if("door_toggle")
			return cyberspace_target_toggle_door(user, target)
		if("bolt_toggle")
			return cyberspace_target_toggle_bolts(user, target)
		if("electrify_toggle")
			return cyberspace_target_toggle_electrified(user, target)
		if("camera_inspect")
			return cyberspace_target_inspect_camera(user, target)
		if("camera_rotate")
			return cyberspace_target_rotate_camera(user, target)
		if("panel_toggle")
			return cyberspace_target_toggle_panel(user, target)
		if("power_toggle")
			return cyberspace_target_toggle_power(user, target)
		if("contraband_toggle")
			return cyberspace_target_toggle_contraband(user, target)
		if("apc_breaker_toggle")
			return cyberspace_target_toggle_apc_breaker(user, target)
		if("apc_nightshift_toggle")
			return cyberspace_target_toggle_apc_nightshift(user, target)
		if("turret_power_toggle")
			return cyberspace_target_toggle_turret_power(user, target)
		if("turret_lethal_toggle")
			return cyberspace_target_toggle_turret_lethal(user, target)
		if("turret_silicon_toggle")
			return cyberspace_target_toggle_turret_silicons(user, target)
		if("light_toggle")
			return cyberspace_target_toggle_light(user, target)
		if("device_toggle")
			return cyberspace_target_toggle_device(user, target)
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

/proc/cyberspace_target_can_toggle_door(atom/movable/target)
	return istype(target, /obj/machinery/door)

/proc/cyberspace_target_can_toggle_bolts(atom/movable/target)
	return !isnull(target) && hascall(target, "toggle_bolt")

/proc/cyberspace_target_can_toggle_electrified(atom/movable/target)
	if(isnull(target))
		return FALSE
	return hascall(target, "set_electrified") || ("seconds_electrified" in target.vars)

/proc/cyberspace_target_can_inspect_camera(atom/movable/target)
	return istype(target, /obj/machinery/camera)

/proc/cyberspace_target_can_rotate_camera(atom/movable/target)
	return istype(target, /obj/machinery/camera)

/proc/cyberspace_target_can_toggle_panel(atom/movable/target)
	return istype(target, /obj/machinery)

/proc/cyberspace_target_can_toggle_power(atom/movable/target)
	return istype(target, /obj/machinery)

/proc/cyberspace_target_can_toggle_contraband(atom/movable/target)
	return istype(target, /obj/machinery/vending)

/proc/cyberspace_target_can_toggle_apc_breaker(atom/movable/target)
	return istype(target, /obj/machinery/power/apc)

/proc/cyberspace_target_can_toggle_apc_nightshift(atom/movable/target)
	return istype(target, /obj/machinery/power/apc)

/proc/cyberspace_target_can_toggle_turret_power(atom/movable/target)
	return istype(target, /obj/machinery/turretid)

/proc/cyberspace_target_can_toggle_turret_lethal(atom/movable/target)
	return istype(target, /obj/machinery/turretid)

/proc/cyberspace_target_can_toggle_turret_silicons(atom/movable/target)
	return istype(target, /obj/machinery/turretid)

/proc/cyberspace_target_can_toggle_light(atom/movable/target)
	return istype(target, /obj/machinery/light)

/proc/cyberspace_target_toggle_device_proc(atom/movable/target)
	if(isnull(target))
		return null
	var/static/list/toggle_procs = list(
		"toggle",
		"toggle_power",
		"toggle_open",
		"toggle_restock",
		"toggle_disable",
		"toggle_broadcast",
		"toggle_feed",
	)
	for(var/proc_name as anything in toggle_procs)
		if(hascall(target, proc_name))
			return proc_name
	return null

/proc/cyberspace_target_can_toggle_device(atom/movable/target)
	return !isnull(cyberspace_target_toggle_device_proc(target))

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

/proc/cyberspace_target_toggle_door(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_door(target))
		to_chat(user, span_warning("[target] does not expose a door motor channel."))
		return FALSE
	var/obj/machinery/door/target_door = target
	if(target_door.density)
		target_door.open()
	else
		target_door.close()
	to_chat(user, span_notice("Cyberspace command accepted: toggling [target]'s door motor."))
	return TRUE

/proc/cyberspace_target_toggle_bolts(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_bolts(target))
		to_chat(user, span_warning("[target] does not expose a bolt channel."))
		return FALSE
	call(target, "toggle_bolt")(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling [target]'s bolt channel."))
	return TRUE

/proc/cyberspace_target_toggle_electrified(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_electrified(target))
		to_chat(user, span_warning("[target] does not expose an electrification channel."))
		return FALSE
	var/electrified = FALSE
	if(hascall(target, "isElectrified"))
		electrified = call(target, "isElectrified")()
	else if("seconds_electrified" in target.vars)
		electrified = target.vars["seconds_electrified"] != MACHINE_NOT_ELECTRIFIED
	if(hascall(target, "set_electrified"))
		call(target, "set_electrified")(electrified ? MACHINE_NOT_ELECTRIFIED : MACHINE_ELECTRIFIED_PERMANENT, user)
	else
		target.vars["seconds_electrified"] = electrified ? MACHINE_NOT_ELECTRIFIED : MACHINE_DEFAULT_ELECTRIFY_TIME
	to_chat(user, span_notice("Cyberspace command accepted: [electrified ? "clearing" : "arming"] [target]'s electrification channel."))
	return TRUE

/proc/cyberspace_target_inspect_camera(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_inspect_camera(target))
		to_chat(user, span_warning("[target] does not expose a camera diagnostics channel."))
		return FALSE
	var/obj/machinery/camera/target_camera = target
	var/list/report = list(
		"tag: [target_camera.c_tag || "untagged"]",
		"network: [length(target_camera.network) ? english_list(target_camera.network) : "none"]",
		"range: [target_camera.view_range]",
		"direction: [dir2text(target_camera.dir)]",
		"state: [target_camera.can_use() ? "online" : "offline"]",
		"alarm: [target_camera.alarm_on ? "active" : "clear"]",
		"xray: [target_camera.isXRay(TRUE) ? "yes" : "no"]",
		"motion: [target_camera.isMotion() ? "yes" : "no"]",
		"emp-shield: [target_camera.isEmpProof(TRUE) ? "yes" : "no"]",
	)
	to_chat(user, span_notice("Camera diagnostics for [target_camera]: [jointext(report, "; ")]."))
	return TRUE

/proc/cyberspace_target_rotate_camera(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_rotate_camera(target))
		to_chat(user, span_warning("[target] does not expose a camera pan channel."))
		return FALSE
	target.setDir(turn(target.dir, 90))
	to_chat(user, span_notice("Cyberspace command accepted: rotating [target]'s camera head to [dir2text(target.dir)]."))
	return TRUE

/proc/cyberspace_target_toggle_panel(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_panel(target))
		to_chat(user, span_warning("[target] does not expose a service panel channel."))
		return FALSE
	var/obj/machinery/target_machine = target
	target_machine.toggle_panel_open()
	to_chat(user, span_notice("Cyberspace command accepted: [target_machine.panel_open ? "opening" : "closing"] [target]'s service panel."))
	return TRUE

/proc/cyberspace_target_toggle_power(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_power(target))
		to_chat(user, span_warning("[target] does not expose a local power channel."))
		return FALSE
	var/obj/machinery/target_machine = target
	var/was_offline = target_machine.machine_stat & NOPOWER
	if(was_offline)
		target_machine.set_machine_stat(target_machine.machine_stat & ~NOPOWER)
	else
		target_machine.set_machine_stat(target_machine.machine_stat | NOPOWER)
	to_chat(user, span_notice("Cyberspace command accepted: [was_offline ? "restoring" : "cutting"] [target]'s local power channel."))
	return TRUE

/proc/cyberspace_target_toggle_contraband(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_contraband(target))
		to_chat(user, span_warning("[target] does not expose a contraband inventory channel."))
		return FALSE
	var/obj/machinery/vending/vendor = target
	vendor.extended_inventory = !vendor.extended_inventory
	SStgui.update_uis(vendor)
	to_chat(user, span_notice("Cyberspace command accepted: [vendor.extended_inventory ? "opening" : "hiding"] [target]'s contraband inventory."))
	return TRUE

/proc/cyberspace_target_toggle_apc_breaker(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_apc_breaker(target))
		to_chat(user, span_warning("[target] does not expose an APC breaker channel."))
		return FALSE
	var/obj/machinery/power/apc/apc = target
	apc.toggle_breaker(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling [target]'s area breaker."))
	return TRUE

/proc/cyberspace_target_toggle_apc_nightshift(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_apc_nightshift(target))
		to_chat(user, span_warning("[target] does not expose an APC lighting profile channel."))
		return FALSE
	var/obj/machinery/power/apc/apc = target
	apc.toggle_nightshift_lights(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling [target]'s night lighting profile."))
	return TRUE

/proc/cyberspace_target_toggle_turret_power(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_turret_power(target))
		to_chat(user, span_warning("[target] does not expose a turret power channel."))
		return FALSE
	var/obj/machinery/turretid/turret_control = target
	turret_control.toggle_on(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling linked turret power."))
	return TRUE

/proc/cyberspace_target_toggle_turret_lethal(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_turret_lethal(target))
		to_chat(user, span_warning("[target] does not expose a turret lethality channel."))
		return FALSE
	var/obj/machinery/turretid/turret_control = target
	turret_control.toggle_lethal(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling linked turret lethality."))
	return TRUE

/proc/cyberspace_target_toggle_turret_silicons(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_turret_silicons(target))
		to_chat(user, span_warning("[target] does not expose a turret silicon targeting channel."))
		return FALSE
	var/obj/machinery/turretid/turret_control = target
	turret_control.shoot_silicons(user)
	to_chat(user, span_notice("Cyberspace command accepted: toggling linked turret silicon targeting."))
	return TRUE

/proc/cyberspace_target_toggle_light(mob/living/user, atom/movable/target)
	if(!cyberspace_target_can_toggle_light(target))
		to_chat(user, span_warning("[target] does not expose a lighting channel."))
		return FALSE
	var/obj/machinery/light/light = target
	light.set_on(!light.on)
	to_chat(user, span_notice("Cyberspace command accepted: toggling [target]'s light emitter."))
	return TRUE

/proc/cyberspace_target_toggle_device(mob/living/user, atom/movable/target)
	var/proc_name = cyberspace_target_toggle_device_proc(target)
	if(!proc_name)
		to_chat(user, span_warning("[target] does not expose a safe generic toggle channel."))
		return FALSE
	call(target, proc_name)(user)
	to_chat(user, span_notice("Cyberspace command accepted: executing /proc/[proc_name](target) on [target]."))
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
