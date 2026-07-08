// Cyberpunk 13 cyberspace: cyberspace hostile programs.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/mob/living/basic/cyberspace_alternative
	name = "alternative"
	desc = "An aggressive Veil program, shaped like a yellow animal imprint."
	icon = 'icons/mob/nonhuman-player/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	color = "#ffd447"
	alpha = 190
	health = 45
	maxHealth = 45
	melee_damage_lower = 6
	melee_damage_upper = 12
	obj_damage = 10
	mob_biotypes = MOB_ROBOTIC
	basic_mob_flags = DEL_ON_DEATH
	faction = list(FACTION_HOSTILE)
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile
	var/datum/weakref/veil_target_ref

/mob/living/basic/cyberspace_alternative/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(veil_hunt_loop)), CYBERSPACE_VEIL_HUNT_INTERVAL)

/mob/living/basic/cyberspace_alternative/proc/set_veil_target(mob/eye/cyberspace_avatar/new_target)
	veil_target_ref = new_target ? WEAKREF(new_target) : null
	return TRUE

/mob/living/basic/cyberspace_alternative/proc/get_veil_target()
	var/mob/eye/cyberspace_avatar/target = veil_target_ref?.resolve()
	if(!target || QDELETED(target) || !target.session?.is_veil_target())
		return null
	return target

/mob/living/basic/cyberspace_alternative/proc/find_veil_target()
	var/mob/eye/cyberspace_avatar/best_target
	var/best_distance = INFINITY
	for(var/mob/eye/cyberspace_avatar/candidate in view(CYBERSPACE_VEIL_HUNT_RANGE, src))
		if(!candidate.session?.is_veil_target())
			continue
		var/current_distance = get_dist(src, candidate)
		if(current_distance >= best_distance)
			continue
		best_target = candidate
		best_distance = current_distance
	if(best_target)
		set_veil_target(best_target)
	return best_target

/mob/living/basic/cyberspace_alternative/proc/veil_hunt_loop()
	if(QDELETED(src) || stat == DEAD)
		return
	var/mob/eye/cyberspace_avatar/target = get_veil_target() || find_veil_target()
	if(target)
		setDir(get_dir(src, target))
		if(get_dist(src, target) <= 1)
			strike_veil_target(target)
		else
			step_towards(src, target)
	addtimer(CALLBACK(src, PROC_REF(veil_hunt_loop)), CYBERSPACE_VEIL_HUNT_INTERVAL)

/mob/living/basic/cyberspace_alternative/proc/strike_veil_target(mob/eye/cyberspace_avatar/target)
	if(!target?.session?.is_veil_target())
		return FALSE
	visible_message(span_danger("[src] tears at [target]'s cyberspace form!"))
	target.session.apply_veil_avatar_attack(rand(melee_damage_lower, melee_damage_upper), src)
	return TRUE

/mob/living/basic/cyberspace_alternative/death(gibbed)
	for(var/obj/effect/cyberspace_old_data_vault/vault in range(CYBERSPACE_VEIL_DATA_VAULT_GUARD_RANGE, src))
		vault.absorb_alternative(src)
	if(!gibbed && prob(35))
		new /obj/item/cyberspace_storage/reward(drop_location())
	return ..()
