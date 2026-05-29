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

/mob/eye/cyberspace_avatar/proc/assign_body(mob/living/new_body, datum/cyberspace_session/new_session)
	if(!new_body)
		return FALSE
	body_ref = WEAKREF(new_body)
	session = new_session
	appearance = new_body.appearance
	alpha = get_mode_alpha(new_session?.mode)
	color = get_mode_color(new_session?.mode)
	name = "[new_body.real_name || new_body.name]'s [new_session?.mode || CYBERSPACE_MODE_AVATAR]"
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

/mob/eye/cyberspace_avatar/relaymove(mob/living/user, direction)
	if(world.time < last_moved)
		return
	var/turf/destination = get_step(src, direction)
	if(!destination)
		return
	forceMove(destination)
	setDir(direction)
	last_moved = world.time + move_delay

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
	var/datum/cyberspace_layer/layer
	var/mob/eye/cyberspace_avatar/avatar
	var/mode = CYBERSPACE_MODE_AVATAR
	var/list/datum/cyberspace_node/local_nodes = list()
	var/active = FALSE

/datum/cyberspace_session/New(mob/living/body, mode = CYBERSPACE_MODE_AVATAR)
	. = ..()
	src.body = body
	src.mode = mode

/datum/cyberspace_session/Destroy(force)
	if(body?.cyberspace_session == src)
		body.cyberspace_session = null
	QDEL_NULL(avatar)
	QDEL_NULL(layer)
	body = null
	body_origin = null
	avatar_origin = null
	local_nodes = null
	return ..()

/datum/cyberspace_session/proc/begin()
	if(!body || body.stat > CONSCIOUS)
		return FALSE
	if(!body.has_neural_implant())
		to_chat(body, span_warning("Your body has no functional neural interface."))
		return FALSE
	body_origin = get_turf(body)
	if(!body_origin)
		return FALSE
	layer = new()
	if(!layer.build(body))
		to_chat(body, span_warning("Your neural interface fails to resolve a stable cyberspace layer."))
		QDEL_NULL(layer)
		return FALSE
	body.cyberspace_session = src
	local_nodes = layer.nodes
	var/turf/entry_turf = layer.get_entry_turf()
	if(!entry_turf)
		return FALSE
	avatar = new(entry_turf)
	avatar_origin = entry_turf
	avatar.assign_body(body, src)
	active = TRUE
	to_chat(body, span_notice("Your neural interface projects an avatar into the local cyberspace layer. [length(local_nodes)] local node(s) resolve around you."))
	addtimer(CALLBACK(src, PROC_REF(check_avatar_link)), CYBERSPACE_AVATAR_CHECK_INTERVAL)
	return TRUE

/datum/cyberspace_session/proc/end_session(message = TRUE)
	if(message && body)
		to_chat(body, span_notice("Your cyberspace projection collapses back into your body."))
	active = FALSE
	QDEL_NULL(avatar)
	QDEL_NULL(layer)
	qdel(src)

/datum/cyberspace_session/proc/check_avatar_link()
	if(!active || QDELETED(src) || !body || !avatar)
		return
	if(body.stat == DEAD || !body.has_neural_implant())
		end_session(FALSE)
		return
	var/current_distance = get_dist(avatar, avatar_origin)
	if(current_distance > get_safe_distance())
		apply_distance_strain(current_distance)
	addtimer(CALLBACK(src, PROC_REF(check_avatar_link)), CYBERSPACE_AVATAR_CHECK_INTERVAL)

/datum/cyberspace_session/proc/get_safe_distance()
	return mode == CYBERSPACE_MODE_ENGRAM ? CYBERSPACE_ENGRAM_SAFE_DISTANCE : CYBERSPACE_AVATAR_SAFE_DISTANCE

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
