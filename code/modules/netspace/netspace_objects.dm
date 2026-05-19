/atom
	var/datum/netspace_node/cy_netspace_node
	var/cy_net_enabled = FALSE
	var/cy_net_isolated = FALSE
	var/cy_net_security = CY_NET_SECURITY_BASIC
	var/cy_net_integrity = 100
	var/cy_net_max_integrity = 100
	var/list/cy_net_access_keys = list()
	var/list/cy_net_available_actions = list()
	var/cy_net_data = 15
	var/cy_net_key_id
	var/cy_net_key_name

/atom/proc/cy_netspace_register(node_type = CY_NET_NODE_GENERIC, security = null)
	cy_net_enabled = TRUE
	if(!isnull(security))
		cy_net_security = security
	cy_netspace_node = cy_netspace_get_or_create_node(src, node_type, cy_net_security)
	cy_netspace_node.integrity = cy_net_integrity
	cy_netspace_node.max_integrity = cy_net_max_integrity
	cy_netspace_node.access_keys = cy_net_access_keys
	cy_netspace_node.available_actions = cy_netspace_available_actions(null)
	if(node_type == CY_NET_NODE_DOOR || node_type == CY_NET_NODE_CAMERA)
		cy_net_data = min(cy_net_data, 1)
	else if(node_type == CY_NET_NODE_VENDING || node_type == CY_NET_NODE_TERMINAL)
		cy_net_data = max(cy_net_data, 10)
	else if(cy_net_data == CY_NET_NODE_DATA_DEFAULT)
		cy_net_data = rand(2, 9)
	return cy_netspace_node

/atom/proc/cy_netspace_register_deferred(node_type = CY_NET_NODE_GENERIC, security = null)
	cy_net_enabled = TRUE
	if(!isnull(security))
		cy_net_security = security
	addtimer(CALLBACK(src, PROC_REF(cy_netspace_register), node_type, cy_net_security), 1)

/atom/proc/cy_netspace_unregister()
	cy_net_enabled = FALSE
	if(cy_netspace_node)
		qdel(cy_netspace_node)
		cy_netspace_node = null

/atom/proc/cy_netspace_is_online()
	return cy_net_enabled && !cy_net_isolated

/atom/proc/cy_netspace_status_text(mob/living/net_avatar/avatar)
	return "Stored data: [cy_net_data]. Integrity: [cy_net_integrity]/[cy_net_max_integrity]."

/atom/proc/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return cy_net_available_actions || list()

/atom/proc/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	return FALSE

/atom/proc/cy_is_netspace_target()
	return cy_netspace_is_online()

/atom/proc/cy_get_netspace_security()
	if(!cy_netspace_is_online())
		return null
	return cy_netspace_node ? cy_netspace_node.security : cy_net_security

/atom/proc/cy_apply_netspace_damage(amount, source)
	if(!cy_netspace_is_online())
		return FALSE
	if(cy_netspace_node)
		return cy_netspace_node.apply_net_damage(amount, source)
	cy_net_integrity = max(0, cy_net_integrity - amount)
	return TRUE

/atom/proc/cy_add_netspace_trace(amount, source, reason)
	if(cy_netspace_node)
		cy_netspace_node.add_trace(amount, source, reason)
		return TRUE
	return FALSE

/atom/proc/cy_get_netspace_status(user)
	if(cy_netspace_node)
		return cy_netspace_node.get_status_text(user)
	return cy_netspace_status_text(user)

/atom/proc/cy_get_netspace_actions(user)
	if(cy_netspace_node)
		return cy_netspace_node.get_actions(user)
	return cy_netspace_available_actions(user)

/atom/proc/cy_execute_netspace_action(user, action_id)
	if(cy_netspace_node)
		return cy_netspace_node.execute_action(user, action_id)
	return cy_netspace_execute_action(user, action_id)

/atom/proc/cy_netspace_key_id(node_type = CY_NET_NODE_GENERIC, area_part = null)
	if(cy_net_key_id)
		return cy_net_key_id
	var/manufacturer = "generic"
	if(isobj(src))
		var/obj/object = src
		manufacturer = sanitize_css_class_name(lowertext(object.get_manufacturer_name() || "generic"))
	return "[area_part || "area"]_[manufacturer]"

/atom/proc/cy_netspace_key_name(node_type = CY_NET_NODE_GENERIC)
	if(cy_net_key_name)
		return cy_net_key_name
	var/manufacturer = "Generic"
	if(isobj(src))
		var/obj/object = src
		manufacturer = object.get_manufacturer_name() || "Generic"
	return "[manufacturer] [node_type] key"

/atom/proc/cy_netspace_download_data(mob/living/net_avatar/avatar, datum/netspace_node/node)
	if(cy_net_data <= 0)
		return FALSE
	var/downloaded = cy_net_data
	cy_net_data = 0
	if(avatar)
		avatar.cy_add_net_data(downloaded)
		node?.grant_key_to_attacker(avatar)
		to_chat(avatar, span_notice("You download [downloaded] net-data from [src]."))
	return TRUE

/atom/proc/cy_netspace_on_emi(mob/living/net_avatar/source)
	if(hascall(src, "emp_act"))
		call(src, "emp_act")(EMP_HEAVY)
	visible_message(span_warning("[src] crackles under remote electromagnetic interference."))

/atom/proc/cy_netspace_on_emagged(mob/living/net_avatar/source)
	if(hascall(src, "emag_act"))
		call(src, "emag_act")(source, null)
	visible_message(span_warning("[src]'s control logic glitches violently."))

/atom/proc/cy_netspace_on_disabled(mob/living/net_avatar/source)
	cy_net_isolated = TRUE
	visible_message(span_warning("[src] drops offline."))

/atom/proc/cy_netspace_on_damage_repaired()
	cy_net_isolated = FALSE

/atom/proc/cy_netspace_alert(mob/living/net_avatar/source, reason = "network intrusion")
	visible_message(span_warning("[src] screams an electronic alarm: [reason]!"))

/atom/proc/cy_netspace_on_feedback(mob/living/net_avatar/avatar, excess)
	return

/atom/proc/cy_netspace_on_brain_burn(mob/living/net_avatar/avatar, distance)
	return

/mob/living
	var/list/cy_known_net_keys
	var/obj/effect/netspace/projection/cy_netspace_projection
	var/list/cy_projection_implant_integrity


/mob/living/proc/cy_collect_net_keys()
	if(!cy_known_net_keys)
		cy_known_net_keys = list()
	return cy_known_net_keys.Copy()

/mob/living/proc/cy_remember_net_key(key_id, key_name = null)
	if(!key_id)
		return FALSE
	if(!cy_known_net_keys)
		cy_known_net_keys = list()
	cy_known_net_keys[key_id] = key_name || key_id
	return TRUE

/mob/living/proc/cy_knows_net_key(key_id)
	if(!key_id || !cy_known_net_keys)
		return FALSE
	return !!cy_known_net_keys[key_id]

/mob/living/proc/cy_has_neural_interface()
	if(istype(src, /mob/living/net_avatar))
		return TRUE
	if(vars.Find("cy_neural_interface") && vars["cy_neural_interface"])
		return TRUE
	if(vars.Find("implants") && length(vars["implants"]))
		return TRUE
	return FALSE

/mob/living/proc/cy_has_required_hackable_implants()
	if(cy_has_neural_interface())
		if(vars.Find("implants"))
			return length(vars["implants"]) >= 2
		return TRUE
	return FALSE

/mob/living/proc/cy_has_netspace_projection_prereqs()
	if(!cy_has_neural_interface())
		return FALSE
	if(vars.Find("implants"))
		return length(vars["implants"]) >= 1
	return TRUE

/mob/living/proc/cy_ensure_netspace_projection()
	if(cy_netspace_projection && !QDELETED(cy_netspace_projection))
		return cy_netspace_projection
	var/turf/net_turf = SSnetspace.get_net_turf_for_atom(src)
	if(!net_turf)
		return null
	cy_netspace_projection = new /obj/effect/netspace/projection(net_turf)
	cy_netspace_projection.setup_projection(src)
	return cy_netspace_projection

/mob/living/proc/cy_remove_netspace_projection()
	if(cy_netspace_projection && !QDELETED(cy_netspace_projection))
		qdel(cy_netspace_projection)
	cy_netspace_projection = null
	return TRUE

/mob/living/proc/cy_get_projection_implant_ids()
	var/list/ids = list()
	if(vars.Find("implants"))
		var/list/implants_list = vars["implants"]
		var/index = 1
		for(var/thing in implants_list)
			ids += "implant_[index++]"
	if(!length(ids) && cy_has_neural_interface())
		ids += "neural_interface"
	return ids

/mob/living/proc/cy_ensure_projection_implant_integrity()
	if(!cy_projection_implant_integrity)
		cy_projection_implant_integrity = list()
	for(var/id in cy_get_projection_implant_ids())
		if(isnull(cy_projection_implant_integrity[id]))
			cy_projection_implant_integrity[id] = CY_NET_PROJECTION_IMPLANT_INTEGRITY
	return cy_projection_implant_integrity

/mob/living/proc/cy_netspace_projection_status()
	var/list/status = list("Implants:")
	var/list/integrity = cy_ensure_projection_implant_integrity()
	for(var/id in integrity)
		status += "[id]: [integrity[id]]%"
	return status.Join("\n")

/mob/living/proc/cy_netspace_projection_implant_damage(amount, mob/living/net_avatar/source)
	var/list/integrity = cy_ensure_projection_implant_integrity()
	if(!length(integrity))
		return FALSE
	var/target_id = pick(integrity)
	integrity[target_id] = max(0, integrity[target_id] - amount)
	to_chat(src, span_userdanger("Implant [target_id] reports hostile netspace attack: [integrity[target_id]]% integrity."))
	if(integrity[target_id] <= CY_NET_DAMAGE_IMPLANT_EMI_THRESHOLD)
		cy_netspace_on_implant_emi(target_id, source)
	return TRUE

/mob/living/proc/cy_netspace_on_implant_emi(implant_id, mob/living/net_avatar/source)
	to_chat(src, span_userdanger("Implant [implant_id] is forced into an EMI fault state!"))
	adjust_psychic_loss(5, forced = TRUE)
	return TRUE

/mob/living/cy_netspace_on_feedback(mob/living/net_avatar/avatar, excess)
	if(prob(10 * excess))
		to_chat(src, span_warning("Your neural link crackles with distance noise."))

/mob/living/cy_netspace_on_brain_burn(mob/living/net_avatar/avatar, distance)
	adjust_psychic_loss(3 * distance)
	to_chat(src, span_userdanger("Your brain burns from a stretched netspace link!"))

/obj/machinery/net_terminal
	name = "netspace terminal"
	desc = "A terminal for entering the city network."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "computer"
	cy_net_enabled = TRUE
	cy_net_security = CY_NET_SECURITY_BASIC
	cy_net_data = 40
	var/cooldown_until = 0

/obj/machinery/net_terminal/Initialize(mapload)
	. = ..()
	cy_netspace_register_deferred(CY_NET_NODE_TERMINAL, cy_net_security)

/obj/machinery/net_terminal/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	if(!cy_netspace_node)
		cy_netspace_register(CY_NET_NODE_TERMINAL, cy_net_security)
	var/list/options = list("enter netspace", "compile demon", "upgrade loaded demon")
	var/choice = tgui_input_list(user, "Netspace terminal", name, options)
	switch(choice)
		if("enter netspace")
			cy_enter_netspace(user, src, CY_NET_AVATAR_ACTIVE)
		if("compile demon")
			cy_compile_demon_for_user(user)
		if("upgrade loaded demon")
			cy_upgrade_user_demon(user)
	return TRUE

/obj/machinery/net_terminal/proc/cy_compile_demon_for_user(mob/living/user)
	if(world.time < cooldown_until)
		to_chat(user, span_warning("[src] is cooling down."))
		return FALSE
	var/list/templates = list(
		"Ping" = /datum/cy_demon/ping,
		"Breach" = /datum/cy_demon/breach,
		"Compile Wall" = /datum/cy_demon/wall,
		"Control Spike" = /datum/cy_demon/control,
		"Blindspot" = /datum/cy_demon/blind,
		"Pax Lock" = /datum/cy_demon/pacify,
		"Short Circuit" = /datum/cy_demon/short_circuit,
		"Reaper" = /datum/cy_demon/reaper,
		"Collector" = /datum/cy_demon/collector,
	)
	var/list/costs = list(
		"Ping" = 10,
		"Breach" = 25,
		"Compile Wall" = 20,
		"Control Spike" = 35,
		"Blindspot" = 20,
		"Pax Lock" = 25,
		"Short Circuit" = 25,
		"Reaper" = 60,
		"Collector" = 60,
	)
	var/template = tgui_input_list(user, "Compile which demon?", name, templates)
	if(!template)
		return FALSE
	var/cost = costs[template] || 10
	if(user.cy_get_net_data() < cost)
		to_chat(user, span_warning("You need [cost] net-data."))
		return FALSE
	var/datum/cy_demon/new_demon = new templates[template]
	if(!new_demon.can_compile(user))
		qdel(new_demon)
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = user.cy_get_active_cyberdeck()
	if(deck)
		if(deck.is_compile_locked())
			to_chat(user, span_warning("[deck] is cooling down."))
			qdel(new_demon)
			return FALSE
		if(!deck.store_demon(new_demon, user))
			qdel(new_demon)
			return FALSE
		deck.grant_demon_actions(user)
	else
		user.cy_store_demon(new_demon)
	user.cy_add_net_data(-cost)
	cooldown_until = world.time + CY_NET_TERMINAL_COMPILE_COOLDOWN
	to_chat(user, span_notice("[src] compiles [new_demon.name]."))
	return TRUE

/obj/machinery/net_terminal/proc/cy_upgrade_user_demon(mob/living/user)
	if(world.time < cooldown_until)
		to_chat(user, span_warning("[src] is cooling down."))
		return FALSE
	var/list/demons = user.cy_collect_demons()
	if(!length(demons))
		to_chat(user, span_warning("No demons are loaded."))
		return FALSE
	var/list/choices = list()
	for(var/datum/cy_demon/demon as anything in demons)
		choices["[demon.name] ([demon.get_memory_cost()] MU)"] = demon
	var/picked = tgui_input_list(user, "Upgrade which demon?", name, choices)
	if(!picked)
		return FALSE
	var/list/options = list(CY_DEMON_UPGRADE_POWER, CY_DEMON_UPGRADE_RANGE, CY_DEMON_UPGRADE_SPEED, CY_DEMON_UPGRADE_STEALTH, CY_DEMON_UPGRADE_MASS, CY_DEMON_UPGRADE_SPREAD, CY_DEMON_UPGRADE_JUMP, CY_DEMON_UPGRADE_EMI)
	var/field = tgui_input_list(user, "Upgrade what?", name, options)
	if(!field)
		return FALSE
	var/cost = 15
	if(user.cy_get_net_data() < cost)
		to_chat(user, span_warning("You need [cost] net-data."))
		return FALSE
	var/datum/cy_demon_module/modifier/module
	switch(field)
		if(CY_DEMON_UPGRADE_POWER)
			module = new /datum/cy_demon_module/modifier/power_boost
		if(CY_DEMON_UPGRADE_RANGE)
			module = new /datum/cy_demon_module/modifier/range_boost
		if(CY_DEMON_UPGRADE_SPEED)
			module = new /datum/cy_demon_module/modifier/speed_boost
		if(CY_DEMON_UPGRADE_STEALTH)
			module = new /datum/cy_demon_module/modifier/stealth_shell
		if(CY_DEMON_UPGRADE_MASS)
			module = new /datum/cy_demon_module/modifier/mass_payload
		if(CY_DEMON_UPGRADE_SPREAD)
			module = new /datum/cy_demon_module/modifier/spread_payload
		if(CY_DEMON_UPGRADE_JUMP)
			module = new /datum/cy_demon_module/modifier/jump_payload
		if(CY_DEMON_UPGRADE_EMI)
			module = new /datum/cy_demon_module/modifier/emi_payload
	if(!module)
		return FALSE
	var/datum/cy_demon/demon = choices[picked]
	demon.add_module(module)
	if(!demon.can_compile(user))
		demon.remove_module(module)
		qdel(module)
		return FALSE
	user.cy_add_net_data(-cost)
	cooldown_until = world.time + CY_NET_TERMINAL_COMPILE_COOLDOWN
	user.cy_get_active_cyberdeck()?.grant_demon_actions(user)
	to_chat(user, span_notice("[src] rewrites [demon.name]."))
	return TRUE

// CYBERPUNK 13 ENGRAMMING CORE START
/obj/item/cy_engram_chip
	name = "engram chip"
	desc = "A neural carrier chip for holding a digitized mind."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_TINY
	var/datum/mind/stored_mind
	var/datum/weakref/engram_avatar_ref
	var/datum/weakref/bound_carrier_ref
	var/control_chance = 100
	var/used_first_control = FALSE

/obj/item/cy_engram_chip/examine(mob/user)
	. = ..()
	if(stored_mind)
		. += span_notice("Engram: [stored_mind.name]. Carrier chance: [control_chance]%.")
	var/atom/carrier = bound_carrier_ref?.resolve()
	if(carrier)
		. += span_notice("Carrier link: [carrier].")

/obj/item/cy_engram_chip/proc/store_engram(mob/living/net_avatar/avatar)
	if(!istype(avatar) || !avatar.mind)
		return FALSE
	stored_mind = avatar.mind
	engram_avatar_ref = WEAKREF(avatar)
	var/atom/carrier = avatar.anchor_ref || avatar.physical_body
	bound_carrier_ref = carrier ? WEAKREF(carrier) : null
	name = "[stored_mind.name] engram chip"
	return TRUE

/obj/item/cy_engram_chip/proc/clear_engram()
	stored_mind = null
	engram_avatar_ref = null
	bound_carrier_ref = null
	control_chance = 100
	used_first_control = FALSE
	name = initial(name)
	return TRUE

/obj/item/cy_engram_chip/proc/bind_carrier(atom/new_carrier)
	if(!stored_mind || !new_carrier)
		return FALSE
	bound_carrier_ref = WEAKREF(new_carrier)
	var/mob/living/net_avatar/avatar = engram_avatar_ref?.resolve()
	if(istype(avatar))
		avatar.cy_bind_engram(new_carrier, "Your carrier link is rebound.")
	return TRUE

/obj/item/cy_engram_chip/proc/deengram_into(mob/living/carbon/human/body, mob/living/user)
	if(!stored_mind || !istype(body))
		return FALSE
	if(body.mind && body.mind != stored_mind)
		var/obj/item/organ/brain/brain = body.get_organ_slot(ORGAN_SLOT_BRAIN)
		if(brain?.can_cy_bind_engram())
			brain.bind_cy_engram_stub(stored_mind, REF(src))
			bind_carrier(body)
			to_chat(user, span_notice("[stored_mind.name] is bound into [body] as a secondary engram."))
			to_chat(body, span_warning("A second neural pattern flickers at the edge of your thoughts."))
			return TRUE
		to_chat(user, span_warning("[body] already has an active mind and cannot host another engram."))
		return FALSE
	var/mob/old_current = stored_mind.current
	stored_mind.transfer_to(body, force_key_move = TRUE)
	if(istype(old_current, /mob/living/net_avatar) && old_current != body)
		qdel(old_current)
	body.SetUnconscious(0)
	to_chat(body, span_notice("Your engram resolves into physical nerves again."))
	clear_engram()
	return TRUE

/obj/item/cy_engram_chip/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) || !stored_mind)
		return NONE
	var/mob/living/carbon/human/body = interacting_with
	if(!used_first_control || prob(control_chance))
		used_first_control = TRUE
		control_chance = max(50, control_chance - 10)
		return deengram_into(body, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	to_chat(user, span_warning("The engram fails to seize the carrier."))
	control_chance = min(50, control_chance + 5)
	return ITEM_INTERACT_BLOCKING

/obj/machinery/cy_engram_transfer
	name = "neural transfer apparatus"
	desc = "A networked apparatus for engraving minds into engram chips and restoring them into prepared bodies."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "scanner_0"
	density = TRUE
	cy_net_enabled = TRUE
	cy_net_security = CY_NET_SECURITY_HARDENED
	cy_net_data = 80
	var/obj/item/cy_engram_chip/loaded_chip

/obj/machinery/cy_engram_transfer/Initialize(mapload)
	. = ..()
	cy_netspace_register_deferred(CY_NET_NODE_TERMINAL, cy_net_security)

/obj/machinery/cy_engram_transfer/examine(mob/user)
	. = ..()
	. += span_notice("Loaded chip: [loaded_chip ? loaded_chip : "none"].")

/obj/machinery/cy_engram_transfer/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cy_engram_chip))
		if(loaded_chip)
			to_chat(user, span_warning("[src] already has an engram chip loaded."))
			return TRUE
		if(!user.transferItemToLoc(attacking_item, src))
			return TRUE
		loaded_chip = attacking_item
		to_chat(user, span_notice("You load [attacking_item] into [src]."))
		return TRUE
	return ..()

/obj/machinery/cy_engram_transfer/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	var/list/actions = list()
	if(loaded_chip)
		actions += "Eject chip"
		if(!loaded_chip.stored_mind)
			actions += "Engram nearby body"
		else
			actions += "Bind chip to nearby carrier"
			actions += "De-engram into nearby body"
			actions += "Enter netspace as stored engram"
	else
		actions += "Load an engram chip first"
	var/choice = tgui_input_list(user, "Choose neural transfer action.", "Engramming", actions)
	switch(choice)
		if("Eject chip")
			loaded_chip.forceMove(drop_location())
			loaded_chip = null
			return TRUE
		if("Engram nearby body")
			return cy_engram_nearby_body(user)
		if("Bind chip to nearby carrier")
			return cy_bind_chip_to_nearby(user)
		if("De-engram into nearby body")
			return cy_deengram_nearby_body(user)
		if("Enter netspace as stored engram")
			return cy_enter_stored_engram(user)
	return TRUE

/obj/machinery/cy_engram_transfer/proc/cy_choose_nearby_human(mob/living/user, prompt)
	var/list/choices = list()
	for(var/mob/living/carbon/human/human in view(1, src))
		choices += human
	if(!length(choices))
		to_chat(user, span_warning("No compatible body is close enough."))
		return null
	return tgui_input_list(user, prompt, "Engramming", choices)

/obj/machinery/cy_engram_transfer/proc/cy_engram_nearby_body(mob/living/user)
	if(!loaded_chip || loaded_chip.stored_mind)
		return FALSE
	var/mob/living/carbon/human/body = cy_choose_nearby_human(user, "Engram which body?")
	if(!body || !body.mind)
		return FALSE
	if(!body.has_cy_neurointerface())
		to_chat(user, span_warning("[body] needs a working neural interface."))
		return FALSE
	if(!cy_netspace_node)
		cy_netspace_register(CY_NET_NODE_TERMINAL, cy_net_security)
	var/mob/living/net_avatar/avatar = cy_enter_netspace(body, src, CY_NET_AVATAR_ENGRAM)
	if(!avatar)
		return FALSE
	body.mind.transfer_to(avatar, force_key_move = TRUE)
	avatar.name = "[body.real_name]'s engram"
	avatar.setup_avatar(body, CY_NET_AVATAR_ENGRAM, loaded_chip)
	loaded_chip.store_engram(avatar)
	body.Unconscious(30 SECONDS)
	to_chat(user, span_notice("[body]'s engram is cut into [loaded_chip]."))
	return TRUE

/obj/machinery/cy_engram_transfer/proc/cy_bind_chip_to_nearby(mob/living/user)
	if(!loaded_chip?.stored_mind)
		return FALSE
	var/mob/living/carbon/human/body = cy_choose_nearby_human(user, "Bind to which carrier?")
	if(!body)
		return FALSE
	loaded_chip.bind_carrier(body)
	to_chat(user, span_notice("[loaded_chip] is bound to [body]."))
	return TRUE

/obj/machinery/cy_engram_transfer/proc/cy_deengram_nearby_body(mob/living/user)
	if(!loaded_chip?.stored_mind)
		return FALSE
	var/mob/living/carbon/human/body = cy_choose_nearby_human(user, "Restore into which body?")
	if(!body)
		return FALSE
	return loaded_chip.deengram_into(body, user)

/obj/machinery/cy_engram_transfer/proc/cy_enter_stored_engram(mob/living/user)
	if(!loaded_chip?.stored_mind)
		return FALSE
	var/mob/current = loaded_chip.stored_mind.current
	if(istype(current, /mob/living/net_avatar))
		if(loaded_chip.stored_mind.current?.client)
			loaded_chip.stored_mind.transfer_to(current, force_key_move = TRUE)
		return TRUE
	var/mob/living/carbon/human/body
	if(ishuman(current))
		body = current
	else
		body = cy_choose_nearby_human(user, "Use which physical anchor?")
	if(!body)
		return FALSE
	var/mob/living/net_avatar/avatar = cy_enter_netspace(body, loaded_chip.bound_carrier_ref?.resolve() || loaded_chip, CY_NET_AVATAR_ENGRAM)
	if(!avatar)
		return FALSE
	loaded_chip.stored_mind.transfer_to(avatar, force_key_move = TRUE)
	avatar.name = "[loaded_chip.stored_mind.name]'s engram"
	avatar.setup_avatar(body, CY_NET_AVATAR_ENGRAM, loaded_chip.bound_carrier_ref?.resolve() || loaded_chip)
	loaded_chip.engram_avatar_ref = WEAKREF(avatar)
	return TRUE
// CYBERPUNK 13 ENGRAMMING CORE END


/obj/structure/netspace/wall
	name = "net wall"
	desc = "A defensive wall of compiled access rules."
	icon = 'icons/effects/effects.dmi'
	icon_state = "wave2"
	color = "#44aaff"
	density = TRUE
	anchored = TRUE
	max_integrity = CY_NET_WALL_MAX_INTEGRITY
	var/build_progress = 100
	var/net_integrity = CY_NET_WALL_MAX_INTEGRITY

/obj/structure/netspace/wall/New(loc, progress = 100)
	. = ..()
	build_progress = clamp(progress, 1, 100)
	net_integrity = round(CY_NET_WALL_MAX_INTEGRITY * (build_progress / 100))
	alpha = 60 + round(build_progress * 1.8)

/obj/structure/netspace/wall/Initialize(mapload)
	. = ..()
	build_progress = clamp(build_progress, 1, 100)
	net_integrity = round(CY_NET_WALL_MAX_INTEGRITY * (build_progress / 100))
	alpha = 60 + round(build_progress * 1.8)

/obj/structure/netspace/wall/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(!istype(mover, /mob/living/net_avatar))
		return FALSE
	return build_progress < 100

/obj/structure/netspace/wall/Initialize(mapload)
	. = ..()
	RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(on_turf_entered))

/obj/structure/netspace/wall/Destroy()
	UnregisterSignal(loc, COMSIG_ATOM_ENTERED)
	return ..()

/obj/structure/netspace/wall/proc/on_turf_entered(datum/source, atom/movable/entered, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(build_progress >= 100)
		return

	if(entered.loc != loc)
		return

	var/mob/living/net_avatar/avatar = entered
	if(!istype(avatar))
		return

	avatar.adjust_stamina_loss(max(1, round(build_progress * 0.1)))

/obj/structure/netspace/wall/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user, /mob/living/net_avatar))
		return ..()
	take_net_damage(CY_NET_WALL_ATTACK_DAMAGE)
	return TRUE

/obj/structure/netspace/wall/proc/take_net_damage(amount)
	net_integrity -= amount
	if(net_integrity <= 0)
		qdel(src)
		return
	build_progress = clamp(round((net_integrity / CY_NET_WALL_MAX_INTEGRITY) * 100), 1, 100)
	alpha = 60 + round(build_progress * 1.8)

/obj/structure/netspace/wall/proc/build_tick(amount = CY_NET_WALL_BUILD_RATE)
	build_progress = clamp(build_progress + amount, 1, 100)
	net_integrity = max(net_integrity, round(CY_NET_WALL_MAX_INTEGRITY * (build_progress / 100)))
	alpha = 60 + round(build_progress * 1.8)

/obj/machinery/door/airlock/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "open", "close", "toggle_bolts")

/obj/machinery/door/airlock/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("open")
			open()
			return TRUE
		if("close")
			close()
			return TRUE
		if("toggle_bolts")
			set_bolt(!locked)
			return TRUE
	return FALSE

/obj/machinery/camera/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "disable", "enable")

/obj/machinery/camera/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable")
			if(camera_enabled)
				toggle_cam(null, FALSE)
			return TRUE
		if("enable")
			if(!camera_enabled)
				toggle_cam(null, FALSE)
			return TRUE
	return FALSE

/obj/machinery/vending/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "audit", "disable_network")

/obj/machinery/vending/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status", "audit")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable_network")
			cy_net_isolated = TRUE
			return TRUE
	return FALSE

/obj/machinery/power/apc/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "view_interface")

/obj/machinery/power/apc/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status", "view_interface")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			ui_interact(avatar)
			return TRUE
	return FALSE


/obj/item/clothing/gloves/cyberdeck
	name = "cyberdeck gloves"
	desc = "A wearable cyberdeck. Alt-right-click or use in hand to dive into netspace as an avatar."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "black"
	slot_flags = ITEM_SLOT_GLOVES
	w_class = WEIGHT_CLASS_SMALL
	var/memory_capacity = 8
	var/compile_cooldown_until = 0
	var/compile_cooldown_time = 2 MINUTES
	var/list/stored_demons = list()
	var/list/granted_demon_actions = list()

/obj/item/clothing/gloves/cyberdeck/Initialize(mapload)
	. = ..()
	if(!length(stored_demons))
		stored_demons += new /datum/cy_demon/ping
		stored_demons += new /datum/cy_demon/breach
		stored_demons += new /datum/cy_demon/wall

/obj/item/clothing/gloves/cyberdeck/proc/is_compile_locked()
	return world.time < compile_cooldown_until

/obj/item/clothing/gloves/cyberdeck/proc/begin_compile_cooldown()
	compile_cooldown_until = max(compile_cooldown_until, world.time + compile_cooldown_time)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/used_memory()
	var/used = 0
	for(var/datum/cy_demon/demon as anything in stored_demons)
		used += demon.get_memory_cost()
	return used

/obj/item/clothing/gloves/cyberdeck/proc/can_store_demon(datum/cy_demon/demon)
	if(!demon || !demon.can_compile())
		return FALSE
	return used_memory() + demon.get_memory_cost() <= memory_capacity

/obj/item/clothing/gloves/cyberdeck/proc/store_demon(datum/cy_demon/demon, mob/user)
	if(is_compile_locked())
		if(user)
			to_chat(user, span_warning("[src] is cooling down."))
		return FALSE
	if(!demon.can_compile(user))
		return FALSE
	if(!can_store_demon(demon))
		if(user)
			to_chat(user, span_warning("[src] lacks memory for [demon.name] ([demon.get_memory_cost()] MU)."))
		return FALSE
	stored_demons += demon
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/grant_demon_actions(mob/living/user)
	if(!user)
		return FALSE
	clear_demon_actions(user)
	for(var/datum/cy_demon/demon as anything in stored_demons)
		var/datum/action/action = demon.grant_as_spell(user)
		if(action)
			granted_demon_actions += action
	user.cy_active_cyberdeck = src
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/clear_demon_actions(mob/living/user)
	for(var/datum/action/action as anything in granted_demon_actions)
		if(action)
			action.Remove(user)
	granted_demon_actions.Cut()
	if(user && user.cy_active_cyberdeck == src)
		user.cy_active_cyberdeck = null
		user.cy_prepared_demon = null

/obj/item/clothing/gloves/cyberdeck/equipped(mob/living/user, slot, initial)
	. = ..()
	if(slot & ITEM_SLOT_GLOVES)
		grant_demon_actions(user)

/obj/item/clothing/gloves/cyberdeck/dropped(mob/living/user)
	clear_demon_actions(user)
	return ..()

/obj/item/clothing/gloves/cyberdeck/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	if(user.get_item_by_slot(ITEM_SLOT_GLOVES) != src)
		to_chat(user, span_warning("Wear [src] as gloves to use it."))
		return TRUE
	cy_enter_netspace(user, src, CY_NET_AVATAR_ACTIVE)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/attack_self_secondary(mob/living/user, modifiers)
	return attack_self(user, modifiers)

/obj/item/clothing/gloves/cyberdeck/click_alt_secondary(mob/living/user)
	if(!istype(user))
		return CLICK_ACTION_BLOCKING
	attack_self(user, list(RIGHT_CLICK = TRUE, ALT_CLICK = TRUE))
	return CLICK_ACTION_SUCCESS

/obj/item/clothing/gloves/cyberdeck/verb/configure_cyberdeck_demons()
	set name = "Configure Cyberdeck Demons"
	set category = "Object"
	set src in usr
	var/mob/living/user = usr
	if(!istype(user))
		return
	var/list/options = list("memory status", "load basic demon", "unload demon")
	var/choice = tgui_input_list(user, "[used_memory()]/[memory_capacity] MU used.", "Cyberdeck", options)
	if(!choice)
		return
	if(choice == "memory status")
		to_chat(user, span_notice("[src] memory: [used_memory()]/[memory_capacity] MU."))
		return
	if(choice == "load basic demon")
		if(is_compile_locked())
			to_chat(user, span_warning("[src] is cooling down."))
			return
		var/list/templates = list("Ping" = /datum/cy_demon/ping, "Breach" = /datum/cy_demon/breach, "Compile Wall" = /datum/cy_demon/wall, "Control Spike" = /datum/cy_demon/control, "Blindspot" = /datum/cy_demon/blind, "Pax Lock" = /datum/cy_demon/pacify, "Short Circuit" = /datum/cy_demon/short_circuit)
		var/template = tgui_input_list(user, "Compile which basic demon?", "Cyberdeck", templates)
		if(!template)
			return
		var/datum/cy_demon/new_demon = new templates[template]
		if(store_demon(new_demon, user))
			begin_compile_cooldown()
		else
			qdel(new_demon)
		if(user.get_item_by_slot(ITEM_SLOT_GLOVES) == src)
			grant_demon_actions(user)
		return
	if(choice == "unload demon")
		var/list/choices = list()
		for(var/datum/cy_demon/demon as anything in stored_demons)
			choices["[demon.name] ([demon.get_memory_cost()] MU)"] = demon
		var/remove_choice = tgui_input_list(user, "Unload which demon?", "Cyberdeck", choices)
		if(remove_choice)
			stored_demons -= choices[remove_choice]
			if(user.get_item_by_slot(ITEM_SLOT_GLOVES) == src)
				grant_demon_actions(user)

/obj/item/netdeck
	parent_type = /obj/item/clothing/gloves/cyberdeck
	name = "netdeck"
	desc = "A portable cyberdeck. Wear it as a glove to run demons and enter netspace."
	icon = 'icons/obj/devices/pda.dmi'
	icon_state = "pda-library"

/obj/item/cy_demon_disk
	name = "demon disk"
	desc = "A 12 MU storage disk for compiled demons."
	icon = 'icons/obj/devices/floppy_disks.dmi'
	icon_state = "datadisk8"
	w_class = WEIGHT_CLASS_SMALL
	var/memory_capacity = CY_DEMON_DISK_MEMORY
	var/list/stored_demons = list()

/obj/item/cy_demon_disk/proc/used_memory()
	var/used = 0
	for(var/datum/cy_demon/demon as anything in stored_demons)
		used += demon.get_memory_cost()
	return used

/obj/item/cy_demon_disk/proc/store_demon(datum/cy_demon/demon, mob/user)
	if(!demon)
		return FALSE
	if(used_memory() + demon.get_memory_cost() > memory_capacity)
		if(user)
			to_chat(user, span_warning("The disk lacks free memory."))
		return FALSE
	stored_demons += demon
	return TRUE

/obj/effect/netspace/projection
	name = "neural projection"
	desc = "A projected implant silhouette following a physical body."
	icon = 'icons/mob/simple/mob.dmi'
	icon_state = "reappear"
	color = "#7eeeff"
	alpha = 150
	anchored = TRUE
	var/mob/living/physical_body
	var/datum/net_trace/trace

/obj/effect/netspace/projection/Initialize(mapload)
	. = ..()
	trace = new
	SSnetspace.register_projection(src)

/obj/effect/netspace/projection/Destroy()
	SSnetspace.unregister_projection(src)
	if(physical_body?.cy_netspace_projection == src)
		physical_body.cy_netspace_projection = null
	physical_body = null
	QDEL_NULL(trace)
	return ..()

/obj/effect/netspace/projection/proc/setup_projection(mob/living/body)
	physical_body = body
	name = "[body.name]'s projection"
	return TRUE

/obj/effect/netspace/projection/proc/cy_process_projection(seconds_per_tick)
	if(!physical_body || QDELETED(physical_body) || !physical_body.cy_has_netspace_projection_prereqs())
		qdel(src)
		return
	var/turf/net_turf = SSnetspace.get_net_turf_for_atom(physical_body)
	if(net_turf && loc != net_turf)
		forceMove(net_turf)

/obj/effect/netspace/projection/cy_is_netspace_target()
	return TRUE

/obj/effect/netspace/projection/cy_add_netspace_trace(amount, source, reason)
	trace?.add_trace(amount, source, reason)
	return TRUE

/obj/effect/netspace/projection/cy_get_netspace_status(user)
	if(!physical_body)
		return "Dead projection."
	return physical_body.cy_netspace_projection_status()

/obj/effect/netspace/projection/cy_get_netspace_actions(user)
	return list("implant_scan")

/obj/effect/netspace/projection/cy_execute_netspace_action(user, action_id)
	if(action_id != "implant_scan" || !physical_body)
		return FALSE
	to_chat(user, span_notice(physical_body.cy_netspace_projection_status()))
	return TRUE

/obj/effect/netspace/projection/cy_apply_netspace_damage(amount, source)
	if(physical_body)
		physical_body.cy_netspace_projection_implant_damage(max(1, round(amount)), source)
		physical_body.adjust_psychic_loss(max(1, round(amount * 0.2)))
		trace?.add_trace(max(1, round(amount * 0.35)), source, "projection attack")
	return TRUE

/obj/effect/netspace/projection/attack_hand(mob/living/user, list/modifiers)
	if(istype(user, /mob/living/net_avatar))
		to_chat(user, span_notice(cy_get_netspace_status(user)))
		return TRUE
	return ..()

/mob/living/basic/netspace_analog
	name = "analog"
	desc = "A red hostile program roaming the net."
	icon = 'icons/mob/simple/lavaland/lavaland_monsters.dmi'
	icon_state = "watcher"
	color = CY_NET_COLOR_ALTERNATIVE
	faction = list("netspace_analog")
	maxHealth = 60
	health = 60
	melee_damage_lower = 6
	melee_damage_upper = 10
	obj_damage = 15
	environment_smash = ENVIRONMENT_SMASH_NONE

/mob/living/basic/netspace_analog/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	var/area/current_area = get_area(src)
	if(!istype(current_area, /area/netspace/veil))
		adjust_psychic_loss(CY_NET_ANALOG_OUTSIDE_VEIL_DAMAGE)

/obj/item/cy_demon_disk/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	var/obj/item/clothing/gloves/cyberdeck/deck = user.cy_get_active_cyberdeck()
	var/list/options = list("status")
	if(deck)
		options += "copy deck demon to disk"
		options += "copy disk demon to deck"
	var/choice = tgui_input_list(user, "Disk memory: [used_memory()]/[memory_capacity] MU", "Demon disk", options)
	if(!choice)
		return TRUE
	if(choice == "status")
		to_chat(user, span_notice("[src] memory: [used_memory()]/[memory_capacity] MU."))
		return TRUE
	if(!deck)
		return TRUE
	if(choice == "copy deck demon to disk")
		var/list/choices = list()
		for(var/datum/cy_demon/demon as anything in deck.stored_demons)
			choices["[demon.name] ([demon.get_memory_cost()] MU)"] = demon
		var/picked = tgui_input_list(user, "Copy which demon?", "Demon disk", choices)
		if(picked)
			store_demon(choices[picked], user)
		return TRUE
	if(choice == "copy disk demon to deck")
		var/list/choices = list()
		for(var/datum/cy_demon/demon as anything in stored_demons)
			choices["[demon.name] ([demon.get_memory_cost()] MU)"] = demon
		var/picked = tgui_input_list(user, "Load which demon?", "Demon disk", choices)
		if(picked && deck.store_demon(choices[picked], user))
			deck.grant_demon_actions(user)
		return TRUE

/obj/machinery/door/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "open", "close")

/obj/machinery/door/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("open")
			open()
			return TRUE
		if("close")
			close()
			return TRUE
	return FALSE

/obj/machinery/computer/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "open_interface", "disable_network")

/obj/machinery/computer/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("open_interface")
			ui_interact(avatar)
			return TRUE
		if("disable_network")
			cy_net_isolated = TRUE
			return TRUE
	return FALSE

/obj/machinery/porta_turret/cy_netspace_available_actions(mob/living/net_avatar/avatar)
	return list("status", "disable_network")

/obj/machinery/porta_turret/cy_netspace_execute_action(mob/living/net_avatar/avatar, action_id)
	switch(action_id)
		if("status")
			to_chat(avatar, span_notice(cy_netspace_status_text(avatar)))
			return TRUE
		if("disable_network")
			cy_net_isolated = TRUE
			return TRUE
	return FALSE
