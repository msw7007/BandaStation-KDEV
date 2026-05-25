/datum/ai_controller/basic_controller/fleshblob
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_AGGRO_RANGE = 7,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/mob/living/basic/fleshblob
	name = "mass of flesh"
	desc = "A moving slithering mass of flesh, seems to be very much in pain. Better avoid. It has no mouth and it must scream."
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "fleshblob"
	icon_living = "fleshblob"
	mob_biotypes = MOB_ORGANIC|MOB_MINING
	mob_size = MOB_SIZE_LARGE
	gender = NEUTER
	basic_mob_flags = DEL_ON_DEATH
	faction = list(FACTION_HOSTILE, FACTION_MINING)
	melee_damage_lower = 3
	melee_damage_upper = 3
	health = 160
	maxHealth = 160
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_SMASH
	attack_verb_continuous = "attempts to assimilate"
	attack_verb_simple = "attempt to assimilate"
	mob_biotypes = MOB_ORGANIC
	speed = 8
	combat_mode = TRUE
	ai_controller = /datum/ai_controller/basic_controller/fleshblob

/mob/living/basic/fleshblob/Initialize(mapload, obj/item/bodypart/limb)
	. = ..()
	grant_actions_by_list(list(/datum/action/consume/fleshblob))
	ADD_TRAIT(src, TRAIT_STRONG_GRABBER, INNATE_TRAIT)
	AddElement(/datum/element/death_drops, /obj/effect/gibspawner/generic)
	AddComponent(\
		/datum/component/blood_walk, \
		blood_type = /obj/effect/decal/cleanable/blood/trail_holder, \
		target_dir_change = TRUE,\
	)

/mob/living/basic/fleshblob/container_resist_act(mob/living/user)
	. = ..()
	if(!do_after(user, 4 SECONDS, target = src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE|IGNORE_USER_LOC_CHANGE|IGNORE_INCAPACITATED))
		return FALSE
	var/datum/action/consume/fleshblob/consume = locate() in actions
	if(isnull(consume))
		return
	consume.stop_consuming()

/mob/living/basic/fleshblob/melee_attack(mob/living/target, list/modifiers, ignore_cooldown = FALSE)
	if(target.loc == src || pulling == target)
		return FALSE
	. = ..()
	if(!istype(target) || isnull(.)) // we deal 0 damage
		return
	start_pulling(target, state = GRAB_AGGRESSIVE)
	var/datum/action/consume/fleshblob/consume = locate() in actions
	if(isnull(consume))
		return
	consume.Trigger() // subtrees wouldve spammed this shit repeatedly anyway

/datum/action/consume/fleshblob
	devour_verb = "assimilate"
	devour_time = 3 SECONDS

/mob/living/basic/visceroid
	name = "visceroid"
	desc = "A hostile genetic collapse wearing the outline of a human body."
	icon = 'icons/mob/simple/animal.dmi'
	icon_state = "fleshblob"
	icon_living = "fleshblob"
	mob_biotypes = MOB_ORGANIC
	mob_size = MOB_SIZE_LARGE
	gender = NEUTER
	basic_mob_flags = DEL_ON_DEATH
	faction = list(FACTION_HOSTILE)
	melee_damage_lower = 18
	melee_damage_upper = 24
	health = 260
	maxHealth = 260
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_SMASH
	attack_verb_continuous = "assimilates"
	attack_verb_simple = "assimilate"
	speed = 4
	combat_mode = TRUE
	ai_controller = /datum/ai_controller/basic_controller/fleshblob
	var/list/swallowed_victims = list()
	var/mob/living/carbon/human/origin_body
	var/releasing_victims = FALSE

/mob/living/basic/visceroid/Initialize(mapload, mob/living/carbon/human/source_body)
	. = ..()
	ADD_TRAIT(src, TRAIT_STRONG_GRABBER, INNATE_TRAIT)
	AddComponent(\
		/datum/component/blood_walk, \
		blood_type = /obj/effect/decal/cleanable/blood/trail_holder, \
		target_dir_change = TRUE, \
	)
	if(source_body)
		origin_body = source_body

/mob/living/basic/visceroid/proc/absorb_source_body(mob/living/carbon/human/source_body)
	if(!source_body || QDELETED(source_body))
		return FALSE
	origin_body = source_body
	swallow_victim(source_body, kill = FALSE)
	source_body.Unconscious(GENETIC_TUMOR_DORMANT_TIME)
	return TRUE

/mob/living/basic/visceroid/melee_attack(mob/living/target, list/modifiers, ignore_cooldown = FALSE)
	. = ..()
	if(can_swallow_victim(target))
		swallow_victim(target)

/mob/living/basic/visceroid/proc/can_swallow_victim(mob/living/target)
	if(!istype(target) || target == src || target.loc == src)
		return FALSE
	if(!(target.mob_biotypes & MOB_ORGANIC))
		return FALSE
	return target.stat >= SOFT_CRIT || target.IsSleeping() || target.IsUnconscious()

/mob/living/basic/visceroid/proc/swallow_victim(mob/living/victim, kill = TRUE)
	if(!victim || QDELETED(victim) || victim.loc == src)
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] folds [victim] into itself!"))
	if(kill && victim.stat != DEAD)
		victim.death()
	victim.forceMove(src)
	swallowed_victims[victim] = world.time
	maxHealth += 25
	health = min(maxHealth, health + 50)
	return TRUE

/mob/living/basic/visceroid/death(gibbed)
	release_swallowed_victims()
	return ..()

/mob/living/basic/visceroid/Destroy()
	release_swallowed_victims()
	return ..()

/mob/living/basic/visceroid/proc/release_swallowed_victims()
	if(releasing_victims || !length(swallowed_victims))
		return
	releasing_victims = TRUE
	var/turf/drop_turf = get_turf(src)
	for(var/mob/living/victim as anything in swallowed_victims)
		var/swallowed_at = swallowed_victims[victim]
		if(QDELETED(victim))
			continue
		victim.forceMove(drop_turf)
		if(ishuman(victim) && (victim == origin_body || (world.time - swallowed_at) >= VISCEROID_CONTAINMENT_TUMOR_TIME))
			var/mob/living/carbon/human/human_victim = victim
			human_victim.apply_genetic_tumor()
			if(victim == origin_body)
				human_victim.Unconscious(GENETIC_TUMOR_DORMANT_TIME)
	swallowed_victims.Cut()
	releasing_victims = FALSE
