// Cyberpunk 13 cyberspace: cyberspace wall shell.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/datum/cyberspace_wall
	var/build_progress = 0
	var/integrity = 100

/datum/cyberspace_wall/proc/get_slowdown()
	return clamp(build_progress, 0, 99)

/datum/cyberspace_wall/proc/build(amount)
	build_progress = clamp(build_progress + amount, 0, 100)
	return build_progress

/datum/cyberspace_wall/proc/take_damage(amount)
	if(amount <= 0)
		return FALSE
	integrity = max(0, integrity - amount)
	return integrity <= 0

/obj/effect/cyberspace_wall_shell
	name = "cyberspace wall"
	desc = "A digital barrier. Incomplete walls slow avatars; completed walls block passage."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	anchored = TRUE
	density = TRUE
	alpha = 180
	color = "#18d8ff"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/cyberspace_wall/wall_data

/obj/effect/cyberspace_wall_shell/Initialize(mapload, datum/cyberspace_wall/new_wall)
	. = ..()
	wall_data = new_wall || new()
	update_wall_visuals()

/obj/effect/cyberspace_wall_shell/Destroy(force)
	QDEL_NULL(wall_data)
	return ..()

/obj/effect/cyberspace_wall_shell/Click(location, control, params)
	attack_hand(usr, params2list(params))
	return TRUE

/obj/effect/cyberspace_wall_shell/attack_hand(mob/user, list/modifiers)
	var/mob/living/body = get_cyberspace_user_body(user)
	if(!body)
		return TRUE
	if(get_dist(user, src) > 1)
		to_chat(body, span_warning("You need to be adjacent to the cyberspace wall."))
		return TRUE
	var/hacking_skill = body.get_cyber_hacking_skill()
	var/hack_time = max(1 SECONDS, CYBERSPACE_BASE_ATTACK_TIME - (hacking_skill SECONDS))
	to_chat(body, span_notice("You begin forcing a breach through [src]."))
	if(!do_after(user, hack_time, target = src))
		return TRUE
	var/damage = max(5, 10 + (hacking_skill * 5))
	if(take_wall_damage(damage))
		to_chat(body, span_notice("You break [src] apart."))
	else
		to_chat(body, span_notice("You weaken [src]. [wall_data?.integrity || 0]% integrity remains."))
	return TRUE

/obj/effect/cyberspace_wall_shell/CanAllowThrough(atom/movable/mover, border_dir)
	..()
	var/mob/eye/cyberspace_avatar/avatar = mover
	if(istype(avatar) && wall_data)
		avatar.last_moved = max(avatar.last_moved, world.time + round(wall_data.get_slowdown() / 10))
	return !wall_data || wall_data.build_progress < 100

/obj/effect/cyberspace_wall_shell/proc/update_wall_visuals()
	if(!wall_data)
		return
	alpha = clamp(60 + wall_data.build_progress, 60, 220)
	density = TRUE
	desc = "Progress: [wall_data.build_progress]%. Integrity: [wall_data.integrity]%. Incomplete walls slow avatars; completed walls block passage."

/obj/effect/cyberspace_wall_shell/proc/build_wall(amount)
	if(!wall_data)
		wall_data = new()
	. = wall_data.build(amount)
	update_wall_visuals()

/obj/effect/cyberspace_wall_shell/proc/take_wall_damage(amount)
	if(!wall_data)
		return FALSE
	if(wall_data.take_damage(amount))
		qdel(src)
		return TRUE
	update_wall_visuals()
	return FALSE
