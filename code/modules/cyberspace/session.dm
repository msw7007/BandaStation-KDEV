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
	var/cyberdemon_stunned_until = 0

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

/mob/eye/cyberspace_avatar/proc/stun_from_cyberdemon(stun_duration)
	cyberdemon_stunned_until = max(cyberdemon_stunned_until, world.time + stun_duration)
	return TRUE

/mob/eye/cyberspace_avatar/relaymove(mob/living/user, direction)
	if(world.time < cyberdemon_stunned_until)
		to_chat(user, span_warning("Your engram is stunned and cannot move."))
		return TRUE
	if(world.time < last_moved)
		return TRUE
	var/turf/destination = get_step(src, direction)
	if(!destination)
		return TRUE
	if(session && !session.can_avatar_move_to(destination))
		to_chat(user, span_warning("The neural link refuses to stretch any further without a node connector."))
		last_moved = world.time + move_delay
		return TRUE
	setLoc(destination)
	setDir(direction)
	last_moved = world.time + (session ? session.get_avatar_move_delay() : move_delay)
	return TRUE

/mob/eye/cyberspace_avatar/attack_hand(mob/user, list/modifiers)
	var/mob/living/hacker_body = get_cyberspace_user_body(user)
	var/mob/living/target_body = body_ref?.resolve()
	if(!hacker_body || !target_body || hacker_body == target_body)
		return TRUE
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = target_body.get_neural_interface()
	if(!interface)
		to_chat(hacker_body, span_warning("[src]'s avatar has no answering neural interface."))
		return TRUE
	interface.start_ice_hack(hacker_body)
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
	var/next_veil_response = 0
	var/avatar_veil_integrity = CYBERSPACE_VEIL_AVATAR_INTEGRITY
	var/list/datum/weakref/veil_alternative_refs = list()

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
	veil_alternative_refs = null
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
	if(mode == CYBERSPACE_MODE_AVATAR)
		relax_physical_body()
	body.grant_cyberspace_return_action()
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
	body?.remove_cyberspace_return_action()
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
			force_return_body_to_origin()
			end_session(FALSE)
			return
	var/atom/movable/anchor = get_engram_anchor()
	if(mode == CYBERSPACE_MODE_ENGRAM && !anchor)
		end_session(FALSE)
		return
	if(mode == CYBERSPACE_MODE_AVATAR)
		relax_physical_body(FALSE)
	var/turf/anchor_turf = anchor ? get_cyberspace_reference_turf(anchor) : null
	var/turf/safe_origin = connection_origin || anchor_turf || get_cyberspace_reference_turf(body) || avatar_origin
	var/current_distance = get_dist(avatar, safe_origin)
	if(current_distance > get_safe_distance())
		apply_distance_strain(current_distance)
	handle_veil_presence()
	if(world.time >= next_layer_refresh && layer)
		next_layer_refresh = world.time + CYBERSPACE_LAYER_REFRESH_INTERVAL
		local_nodes = layer.nodes
	addtimer(CALLBACK(src, PROC_REF(check_avatar_link)), CYBERSPACE_AVATAR_CHECK_INTERVAL)

/datum/cyberspace_session/proc/force_return_body_to_origin()
	if(!body || !body_origin)
		return FALSE
	var/turf/target_turf = get_turf(body_origin)
	if(!target_turf)
		return FALSE
	body.forceMove(target_turf)
	return TRUE

/datum/cyberspace_session/proc/relax_physical_body(announce = TRUE)
	if(!body || body.stat != CONSCIOUS)
		return FALSE
	if(announce)
		body.visible_message(
			span_notice("[body]'s body relaxes and falls as their consciousness slips into the network."),
			span_notice("Your body relaxes and falls as your consciousness slips into the network."),
		)
	body.Knockdown(CYBERSPACE_BODY_RELAX_KNOCKDOWN, ignore_canstun = TRUE)
	return TRUE

/datum/cyberspace_session/proc/get_safe_distance()
	return mode == CYBERSPACE_MODE_ENGRAM ? CYBERSPACE_ENGRAM_SAFE_DISTANCE : CYBERSPACE_AVATAR_SAFE_DISTANCE

/datum/cyberspace_session/proc/get_safe_origin_turf()
	var/atom/movable/anchor = get_engram_anchor()
	var/turf/anchor_turf = anchor ? get_cyberspace_reference_turf(anchor) : null
	return connection_origin || anchor_turf || get_cyberspace_reference_turf(body) || avatar_origin

/datum/cyberspace_session/proc/get_avatar_move_delay()
	if(mode != CYBERSPACE_MODE_AVATAR || !avatar)
		return avatar?.move_delay || 1
	var/turf/safe_origin = get_safe_origin_turf()
	if(safe_origin && get_dist(avatar, safe_origin) > get_safe_distance())
		return max(1, (avatar.move_delay || 1) * CYBERSPACE_AVATAR_STRAIN_MOVE_DELAY_MULTIPLIER)
	return avatar?.move_delay || 1

/datum/cyberspace_session/proc/can_avatar_move_to(turf/destination)
	if(mode != CYBERSPACE_MODE_AVATAR || !avatar || !destination)
		return TRUE
	if(get_connected_node())
		return TRUE
	var/turf/safe_origin = get_safe_origin_turf()
	if(!safe_origin)
		return TRUE
	var/current_distance = get_dist(avatar, safe_origin)
	var/next_distance = get_dist(destination, safe_origin)
	var/hard_distance = get_safe_distance() + CYBERSPACE_AVATAR_HARD_DISTANCE_EXTRA
	if(current_distance >= hard_distance && next_distance > current_distance)
		return FALSE
	return TRUE

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

/datum/cyberspace_session/proc/is_veil_target()
	if(!active || !body || body.stat == DEAD || !avatar)
		return FALSE
	if(!istype(get_turf(avatar), /turf/open/indestructible/cyberspace/veil))
		return FALSE
	if(mode == CYBERSPACE_MODE_AVATAR)
		return TRUE
	return mode == CYBERSPACE_MODE_ENGRAM && !isnull(get_engram_anchor())

/datum/cyberspace_session/proc/handle_veil_presence()
	if(!is_veil_target() || !layer)
		return FALSE
	if(world.time < next_veil_response)
		return FALSE
	next_veil_response = world.time + CYBERSPACE_VEIL_RESPONSE_COOLDOWN
	var/live_alternatives = prune_veil_alternatives()
	if(live_alternatives >= CYBERSPACE_VEIL_MAX_ALTERNATIVES_PER_TARGET)
		return FALSE
	var/distance_to_network = layer.get_nearest_network_turf_distance(avatar)
	var/spawn_chance = clamp((distance_to_network / CYBERSPACE_VEIL_FULL_RESPONSE_DISTANCE) * 100, 0, 100)
	if(!prob(spawn_chance))
		return FALSE
	var/spawn_amount = min(CYBERSPACE_VEIL_RESPONSE_COUNT, CYBERSPACE_VEIL_MAX_ALTERNATIVES_PER_TARGET - live_alternatives)
	var/list/mob/living/basic/cyberspace_alternative/spawned_alternatives = layer.spawn_veil_response(avatar, spawn_amount)
	if(!length(spawned_alternatives))
		return FALSE
	for(var/mob/living/basic/cyberspace_alternative/alternative as anything in spawned_alternatives)
		veil_alternative_refs += WEAKREF(alternative)
	if(body)
		to_chat(body, span_danger("The Veil answers your projection. Alternatives begin hunting your avatar."))
	return TRUE

/datum/cyberspace_session/proc/prune_veil_alternatives()
	if(!veil_alternative_refs)
		veil_alternative_refs = list()
	var/live_count = 0
	for(var/i = length(veil_alternative_refs), i >= 1, i--)
		var/datum/weakref/alternative_ref = veil_alternative_refs[i]
		var/mob/living/basic/cyberspace_alternative/alternative = alternative_ref?.resolve()
		if(!alternative || QDELETED(alternative) || alternative.stat == DEAD)
			veil_alternative_refs.Cut(i, i + 1)
			continue
		live_count++
	return live_count

/datum/cyberspace_session/proc/apply_veil_avatar_attack(amount, mob/living/basic/cyberspace_alternative/attacker)
	if(amount <= 0 || !is_veil_target())
		return FALSE
	avatar_veil_integrity = max(0, avatar_veil_integrity - amount)
	if(body)
		to_chat(body, span_userdanger("An alternative tears into your cyberspace avatar. Integrity: [avatar_veil_integrity]/[CYBERSPACE_VEIL_AVATAR_INTEGRITY]."))
	if(avatar_veil_integrity > 0)
		return TRUE
	veil_avatar_destroyed(attacker)
	return TRUE

/datum/cyberspace_session/proc/veil_avatar_destroyed(mob/living/basic/cyberspace_alternative/killer)
	if(!active || !body)
		return FALSE
	to_chat(body, span_userdanger("Your avatar is destroyed in the Veil. Feedback crushes through your brain."))
	body.adjust_organ_loss(ORGAN_SLOT_BRAIN, CYBERSPACE_VEIL_AVATAR_BRAIN_DAMAGE, BRAIN_DAMAGE_DEATH)
	if(mode != CYBERSPACE_MODE_ENGRAM)
		force_return_body_to_origin()
	end_session(FALSE)
	return TRUE

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
