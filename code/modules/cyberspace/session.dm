// Cyberpunk 13 cyberspace: avatar projection and session runtime.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/mob/eye/cyberspace_avatar
	name = "cyberspace avatar"
	desc = "A projected digital body."
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_ICON
	alpha = CYBERSPACE_AVATAR_ALPHA
	color = "#18d8ff"
	var/datum/weakref/body_ref
	var/datum/cyberspace_session/session
	var/last_moved = 0
	var/move_delay = 1

/mob/eye/cyberspace_avatar/Destroy()
	release_body()
	session = null
	body_ref = null
	return ..()

/mob/eye/cyberspace_avatar/update_remote_sight(mob/living/user)
	user.set_invis_see(SEE_INVISIBLE_LIVING)
	user.set_sight(SEE_TURFS|SEE_MOBS|SEE_OBJS)
	user.lighting_cutoff = LIGHTING_CUTOFF_FULLBRIGHT
	return TRUE

/mob/eye/cyberspace_avatar/proc/assign_body(mob/living/new_body, datum/cyberspace_session/new_session)
	if(!new_body)
		return FALSE
	body_ref = WEAKREF(new_body)
	session = new_session
	appearance = new_body.appearance
	alpha = get_mode_alpha(new_session?.mode)
	color = get_mode_color(new_session?.mode)
	name = new_body.get_cyberspace_avatar_name(new_session?.mode || CYBERSPACE_MODE_AVATAR)
	new_body.remote_control = src
	new_body.reset_perspective(src)
	new_body.update_sight()
	return TRUE

/mob/eye/cyberspace_avatar/proc/release_body()
	var/mob/living/body = body_ref?.resolve()
	if(body?.remote_control == src)
		body.remote_control = null
		body.reset_perspective(null)
		body.update_sight()

/mob/eye/cyberspace_avatar/proc/get_mode_color(mode)
	switch(mode)
		if(CYBERSPACE_MODE_ENGRAM)
			return "#ff334a"
		if(CYBERSPACE_MODE_IMPRINT)
			return "#4cff6b"
	return "#18d8ff"

/mob/eye/cyberspace_avatar/proc/get_mode_alpha(mode)
	switch(mode)
		if(CYBERSPACE_MODE_ENGRAM)
			return CYBERSPACE_ENGRAM_ALPHA
		if(CYBERSPACE_MODE_IMPRINT)
			return CYBERSPACE_IMPRINT_ALPHA
	return CYBERSPACE_AVATAR_ALPHA

/mob/eye/cyberspace_avatar/proc/setLoc(turf/destination)
	if(!destination)
		return FALSE
	forceMove(destination)
	return TRUE

/mob/eye/cyberspace_avatar/relaymove(mob/living/user, direction)
	if(world.time < last_moved)
		return TRUE
	var/turf/destination = get_step(src, direction)
	if(!destination)
		return TRUE
	setLoc(destination)
	setDir(direction)
	last_moved = world.time + move_delay
	return TRUE

/proc/get_cyberspace_user_body(mob/user)
	if(isliving(user))
		return user
	if(istype(user, /mob/eye/cyberspace_avatar))
		var/mob/eye/cyberspace_avatar/avatar = user
		return avatar.body_ref?.resolve()
	return null

/datum/cyberspace_session
	var/mob/living/body
	var/turf/body_origin
	var/turf/avatar_origin
	var/turf/connection_origin
	var/datum/cyberspace_layer/layer
	var/mob/eye/cyberspace_avatar/avatar
	var/mode = CYBERSPACE_MODE_AVATAR
	var/list/datum/cyberspace_node/local_nodes = list()
	var/active = FALSE
	var/next_layer_refresh = 0
	var/datum/weakref/connected_node_ref
	var/datum/weakref/engram_anchor_ref
	var/attack_token

/datum/cyberspace_session/New(mob/living/body, mode = CYBERSPACE_MODE_AVATAR, atom/movable/engram_anchor = null)
	. = ..()
	src.body = body
	src.mode = mode
	if(engram_anchor)
		engram_anchor_ref = WEAKREF(engram_anchor)

/datum/cyberspace_session/Destroy(force)
	if(body?.cyberspace_session == src)
		body.cyberspace_session = null
	QDEL_NULL(avatar)
	layer = null
	body = null
	body_origin = null
	avatar_origin = null
	connection_origin = null
	local_nodes = null
	connected_node_ref = null
	engram_anchor_ref = null
	attack_token = null
	return ..()

/datum/cyberspace_session/proc/begin()
	if(!body || body.stat > CONSCIOUS)
		return FALSE
	if(mode != CYBERSPACE_MODE_ENGRAM && !body.has_neural_implant())
		to_chat(body, span_warning("Your body has no functional neural interface."))
		return FALSE
	var/atom/movable/entry_source = get_engram_anchor() || body
	body_origin = get_turf(entry_source)
	if(!body_origin)
		return FALSE
	layer = SScyberspace?.ensure_ready()
	if(!layer?.origin_turf)
		to_chat(body, span_warning("Your neural interface fails to resolve a stable cyberspace layer."))
		return FALSE
	body.cyberspace_session = src
	local_nodes = layer.nodes
	var/datum/cyberspace_node/entry_node = layer.get_nearest_node(entry_source)
	var/turf/entry_turf = layer.get_entry_turf_for(entry_source)
	if(!entry_turf)
		return FALSE
	avatar = new(entry_turf)
	avatar_origin = entry_turf
	avatar.assign_body(body, src)
	active = TRUE
	if(mode == CYBERSPACE_MODE_ENGRAM)
		to_chat(body, span_notice("Your engram unfolds into the cyberspace layer from [entry_source]."))
	else if(entry_node)
		to_chat(body, span_notice("Your neural interface projects an avatar into the cyberspace layer near [entry_node.physical_area?.name || "unknown area"] ([entry_node.get_object_count()] linked object(s), [length(local_nodes)] total node(s))."))
	else
		to_chat(body, span_notice("Your neural interface projects an avatar into the cyberspace layer. [length(local_nodes)] total node(s) resolve."))
	addtimer(CALLBACK(src, PROC_REF(check_avatar_link)), CYBERSPACE_AVATAR_CHECK_INTERVAL)
	return TRUE

/datum/cyberspace_session/proc/end_session(message = TRUE)
	if(message && body)
		to_chat(body, span_notice("Your cyberspace projection collapses back into your body."))
	active = FALSE
	QDEL_NULL(avatar)
	layer = null
	qdel(src)

/datum/cyberspace_session/proc/can_return_to_body()
	if(!body || !avatar || !body_origin)
		return FALSE
	var/atom/movable/anchor = get_engram_anchor()
	if(mode == CYBERSPACE_MODE_ENGRAM && anchor)
		var/turf/anchor_turf = get_cyberspace_reference_turf(anchor)
		return anchor_turf && get_dist(avatar, anchor_turf) <= CYBERSPACE_ENGRAM_PHYSICAL_RANGE
	var/turf/body_turf = get_cyberspace_reference_turf(body)
	return body_turf && get_dist(avatar, body_turf) <= CYBERSPACE_RETURN_TO_BODY_RANGE

/datum/cyberspace_session/proc/check_avatar_link()
	if(!active || QDELETED(src) || !body || !avatar)
		return
	if(body.stat == DEAD || !body.has_neural_implant())
		if(mode != CYBERSPACE_MODE_ENGRAM)
			end_session(FALSE)
			return
	var/atom/movable/anchor = get_engram_anchor()
	if(mode == CYBERSPACE_MODE_ENGRAM && !anchor)
		end_session(FALSE)
		return
	var/turf/anchor_turf = anchor ? get_cyberspace_reference_turf(anchor) : null
	var/turf/safe_origin = connection_origin || anchor_turf || get_cyberspace_reference_turf(body) || avatar_origin
	var/current_distance = get_dist(avatar, safe_origin)
	if(current_distance > get_safe_distance())
		apply_distance_strain(current_distance)
	if(world.time >= next_layer_refresh && layer)
		next_layer_refresh = world.time + CYBERSPACE_LAYER_REFRESH_INTERVAL
		local_nodes = layer.nodes
	addtimer(CALLBACK(src, PROC_REF(check_avatar_link)), CYBERSPACE_AVATAR_CHECK_INTERVAL)

/datum/cyberspace_session/proc/get_safe_distance()
	return mode == CYBERSPACE_MODE_ENGRAM ? CYBERSPACE_ENGRAM_SAFE_DISTANCE : CYBERSPACE_AVATAR_SAFE_DISTANCE

/datum/cyberspace_session/proc/get_engram_anchor()
	return engram_anchor_ref?.resolve()

/datum/cyberspace_session/proc/set_engram_anchor(atom/movable/new_anchor)
	if(!new_anchor)
		return FALSE
	engram_anchor_ref = WEAKREF(new_anchor)
	body_origin = get_turf(new_anchor)
	var/turf/anchor_turf = get_cyberspace_reference_turf(new_anchor)
	connection_origin = anchor_turf || avatar_origin
	avatar_origin = anchor_turf || avatar_origin
	return TRUE

/datum/cyberspace_session/proc/get_cyberspace_reference_turf(atom/movable/source)
	if(!source)
		return null
	return layer?.get_entry_turf_for(source)

/datum/cyberspace_session/proc/apply_distance_strain(current_distance)
	var/overflow = max(0, current_distance - get_safe_distance())
	if(overflow <= 0 || !body)
		return
	var/overheat = overflow * CYBERSPACE_AVATAR_OVERHEAT_PER_TILE
	body.adjust_chromity_overheat(overheat)
	to_chat(body, span_warning("Your avatar strains the neural link and adds [overheat] overheat."))
	if(prob(overflow * CYBERSPACE_AVATAR_BRAIN_DAMAGE_CHANCE))
		var/obj/item/organ/brain = body.get_organ_slot(ORGAN_SLOT_BRAIN)
		brain?.apply_organ_damage(1)

/datum/cyberspace_session/proc/apply_avatar_damage(amount)
	if(amount <= 0 || !body)
		return 0
	return body.adjust_chromity_overheat(amount)

/datum/cyberspace_session/proc/get_connected_node()
	return connected_node_ref?.resolve()

/datum/cyberspace_session/proc/is_connected_to_node(datum/cyberspace_node/node)
	return !isnull(node) && get_connected_node() == node

/datum/cyberspace_session/proc/connect_to_node(datum/cyberspace_node/node, atom/visual_anchor)
	if(!node || !avatar || !body)
		return FALSE
	connected_node_ref = WEAKREF(node)
	connection_origin = get_turf(visual_anchor || avatar)
	avatar_origin = connection_origin
	to_chat(body, span_notice("Your avatar anchors to [visual_anchor || "the node"]."))
	return TRUE

/datum/cyberspace_session/proc/cancel_cyber_attack()
	if(!attack_token)
		return FALSE
	attack_token = null
	if(body)
		to_chat(body, span_warning("You break off the cyberspace attack."))
	return TRUE

/datum/cyberspace_session/proc/start_cyber_attack(atom/target)
	if(!target || !body)
		return FALSE
	if(attack_token)
		return cancel_cyber_attack()
	attack_token = "\ref[target]-[world.time]"
	return TRUE

/datum/cyberspace_session/proc/is_current_cyber_attack(expected_token)
	return attack_token && attack_token == expected_token

/datum/cyberspace_session/proc/finish_cyber_attack(expected_token)
	if(!is_current_cyber_attack(expected_token))
		return FALSE
	attack_token = null
	return TRUE
