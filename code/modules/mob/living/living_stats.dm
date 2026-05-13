/mob/living/proc/ensure_cy_stat_holder() as /datum/cy_stat_holder
	if(!cy_stat_holder)
		cy_stat_holder = new(src)

	return cy_stat_holder

/mob/living/proc/ensure_cy_skill_holder() as /datum/cy_skill_holder
	if(!cy_skill_holder)
		var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
		cy_skill_holder = new(src, stats)

	return cy_skill_holder

/mob/living/proc/get_cy_stat(stat_type, include_modifiers = TRUE)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_stat(stat_type, include_modifiers)

/mob/living/proc/get_cy_base_stat(stat_type)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_base_stat(stat_type)

/mob/living/proc/set_cy_base_stat(stat_type, value)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_base_stat(stat_type, value)

/mob/living/proc/adjust_cy_base_stat(stat_type, amount)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.adjust_base_stat(stat_type, amount)

/mob/living/proc/get_cy_stat_experience(stat_type)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.get_stat_experience(stat_type)

/mob/living/proc/adjust_cy_stat_experience(stat_type, amount, apply_level = TRUE)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.adjust_stat_experience(stat_type, amount, apply_level)

/mob/living/proc/set_cy_stat_modifier(stat_type, source, amount)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.set_stat_modifier(stat_type, source, amount)

/mob/living/proc/clear_cy_stat_modifier(stat_type, source)
	var/datum/cy_stat_holder/stats = ensure_cy_stat_holder()
	return stats.clear_stat_modifier(stat_type, source)

/mob/living/proc/get_cy_skill_level(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_level(skill_type)

/mob/living/proc/set_cy_skill_level(skill_type, level, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_level(skill_type, level, ignore_stat_limit)

/mob/living/proc/adjust_cy_skill_level(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_skill_level(skill_type, amount, ignore_stat_limit)

/mob/living/proc/get_cy_skill_experience(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_experience(skill_type)

/mob/living/proc/set_cy_skill_experience(skill_type, experience, apply_level = TRUE, ignore_stat_limit = FALSE, auto_level_limit = CY_SKILL_AUTO_LEVEL_LIMIT)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_experience(skill_type, experience, apply_level, ignore_stat_limit, auto_level_limit)

/mob/living/proc/adjust_cy_skill_experience(skill_type, amount, apply_level = TRUE, ignore_stat_limit = FALSE, auto_level_limit = CY_SKILL_AUTO_LEVEL_LIMIT)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_skill_experience(skill_type, amount, apply_level, ignore_stat_limit, auto_level_limit)

/mob/living/proc/award_cy_raw_skill_experience(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.award_raw_skill_experience(skill_type, amount, ignore_stat_limit)

/mob/living/proc/adjust_cy_distributable_experience(amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.adjust_distributable_experience(amount)

/mob/living/proc/spend_cy_distributable_experience_on_skill(skill_type, amount, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.spend_distributable_experience_on_skill(skill_type, amount, ignore_stat_limit)

/mob/living/proc/process_cy_awake_training_experience(seconds_per_tick, mood_modifier = 1)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.process_awake_training_experience(seconds_per_tick, mood_modifier)

/mob/living/proc/set_cy_experience_multiplier(source, amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_experience_multiplier(source, amount)

/mob/living/proc/copy_cy_skill_progress_from(mob/living/source)
	if(!source)
		return FALSE
	var/datum/cy_skill_holder/source_skills = source.ensure_cy_skill_holder()
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.copy_progress_from(source_skills)

/mob/living/proc/get_cy_skill_perk_check_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_check_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_experience_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_experience_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_work_speed_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_work_speed_bonus(skill_type)

/mob/living/proc/get_cy_skill_perk_quality_bonus(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk_quality_bonus(skill_type)

/mob/living/proc/get_cy_skill_speed_multiplier(skill_type)
	var/level_modifier = get_cy_skill_level(skill_type) * 0.08
	var/perk_modifier = get_cy_skill_perk_work_speed_bonus(skill_type) * 0.01
	return max(0.35, 1 - level_modifier - perk_modifier)

/mob/living/proc/get_cy_skill_probability_bonus(skill_type)
	return (get_cy_skill_level(skill_type) * CY_SKILL_VALUE_PER_LEVEL) + get_cy_skill_perk_check_bonus(skill_type)

/mob/living/proc/get_cy_skill_value_modifier(skill_type)
	return get_cy_skill_level(skill_type) + get_cy_skill_perk_quality_bonus(skill_type)

/mob/living/proc/get_cy_check_chance(stat_type, skill_type = null, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_check_chance(stat_type, skill_type, difficulty)

/mob/living/proc/get_cy_skill_check_chance(skill_type, difficulty = 0)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_check_chance(skill_type, difficulty)

/mob/living/proc/get_cy_skill_check_experience(skill_type, difficulty = 0, success = TRUE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_check_experience(skill_type, difficulty, success)

/mob/living/proc/award_cy_skill_check_experience(skill_type, difficulty = 0, success = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.award_skill_check_experience(skill_type, difficulty, success, ignore_stat_limit)

/mob/living/proc/perform_cy_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.perform_check(stat_type, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/perform_cy_skill_check(skill_type, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || !skill.governing_stat)
		return null
	return skills.perform_check(skill.governing_stat, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/roll_cy_check(stat_type, skill_type = null, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.roll_check(stat_type, skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/roll_cy_skill_check(skill_type, difficulty = 0, grant_experience = TRUE, ignore_stat_limit = FALSE)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.roll_skill_check(skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/roll_cy_passive_skill_check(skill_type, required_level = CY_SKILL_MINIMUM_LEVEL, difficulty = 35, grant_experience = TRUE, ignore_stat_limit = FALSE)
	if(get_cy_skill_level(skill_type) < required_level)
		return FALSE
	return roll_cy_skill_check(skill_type, difficulty, grant_experience, ignore_stat_limit)
// CyberPunk character completion layer.
// Covers character-TZ behaviour not provided by the base Banda/TG systems.

/obj/item/proc/get_cy_weapon_skill_type()
	if(w_class <= WEIGHT_CLASS_SMALL && (get_sharpness() & SHARP_POINTY))
		return /datum/cy_skill/weapon/knives

	var/two_handed = w_class >= WEIGHT_CLASS_BULKY
	switch(get_sharpness())
		if(SHARP_POINTY)
			return two_handed ? /datum/cy_skill/weapon/two_handed_piercing : /datum/cy_skill/weapon/one_handed_piercing
		if(SHARP_EDGED)
			return two_handed ? /datum/cy_skill/weapon/two_handed_slashing : /datum/cy_skill/weapon/one_handed_slashing
		if(SHARP_EDGED | SHARP_POINTY)
			return two_handed ? /datum/cy_skill/weapon/two_handed_chopping : /datum/cy_skill/weapon/one_handed_chopping

	return two_handed ? /datum/cy_skill/weapon/two_handed_blunt : /datum/cy_skill/weapon/one_handed_blunt

/obj/item/gun/get_cy_weapon_skill_type()
	switch(weapon_weight)
		if(WEAPON_LIGHT)
			return /datum/cy_skill/weapon/light_firearms
		if(WEAPON_MEDIUM)
			return /datum/cy_skill/weapon/medium_firearms
		if(WEAPON_HEAVY)
			return /datum/cy_skill/weapon/heavy_firearms
	return /datum/cy_skill/weapon/medium_firearms

/mob/living/proc/get_cy_weapon_skill_level(obj/item/weapon)
	if(!weapon)
		return CY_SKILL_LEVEL_UNTRAINED
	var/skill_type = weapon.get_cy_weapon_skill_type()
	if(!skill_type)
		return CY_SKILL_LEVEL_UNTRAINED
	return get_cy_skill_level(skill_type)

/mob/living/proc/get_cy_weapon_damage_multiplier(obj/item/weapon)
	return 1 + get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_DAMAGE_PER_LEVEL

/mob/living/proc/get_cy_weapon_cooldown_multiplier(obj/item/weapon)
	return max(0.1, 1 - get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_COOLDOWN_PER_LEVEL)

/mob/living/proc/get_cy_weapon_defense_bypass_bonus(obj/item/weapon)
	return get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_DEFENSE_BYPASS_PER_LEVEL

/mob/living/proc/get_cy_hunger_level()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return 0
	if(nutrition <= 0)
		return CY_NEED_STAGE_EMPTY
	if(nutrition <= NUTRITION_LEVEL_STARVING)
		return CY_NEED_STAGE_CRITICAL
	if(nutrition <= NUTRITION_LEVEL_HUNGRY)
		return CY_NEED_STAGE_LOW
	return 0

/mob/living/proc/get_cy_thirst_level()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return 0
	if(hydration <= 0)
		return CY_NEED_STAGE_EMPTY
	if(hydration <= NEED_LEVEL_CRITICAL)
		return CY_NEED_STAGE_CRITICAL
	if(hydration <= NEED_LEVEL_LOW)
		return CY_NEED_STAGE_LOW
	return 0

/mob/living/proc/get_cy_sleep_deprivation_level()
	if(rest <= 0)
		return CY_NEED_STAGE_EMPTY
	if(rest <= NEED_LEVEL_CRITICAL)
		return CY_NEED_STAGE_CRITICAL
	if(rest <= NEED_LEVEL_LOW)
		return CY_NEED_STAGE_LOW
	return 0

/mob/living/proc/update_cy_need_stat_modifiers()
	var/hunger_and_thirst = get_cy_hunger_level() + get_cy_thirst_level()
	var/sleep_deprivation = get_cy_sleep_deprivation_level()
	set_cy_stat_modifier(/datum/cy_stat/spirit, "cy_needs_hunger_thirst", -hunger_and_thirst)
	set_cy_stat_modifier(/datum/cy_stat/dexterity, "cy_needs_hunger_thirst", -hunger_and_thirst)
	set_cy_stat_modifier(/datum/cy_stat/perception, "cy_needs_sleep", -sleep_deprivation)
	set_cy_stat_modifier(/datum/cy_stat/charisma, "cy_needs_sleep", -sleep_deprivation)
	return TRUE

/mob/living/carbon/human/proc/is_cy_comfortably_sleeping()
	if(!IsSleeping())
		return FALSE
	if(get_cy_hunger_level() >= CY_NEED_STAGE_CRITICAL || get_cy_thirst_level() >= CY_NEED_STAGE_CRITICAL)
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE
	for(var/obj/structure/bed/bed in current_turf)
		return TRUE
	for(var/obj/structure/chair/chair in current_turf)
		return TRUE
	return rest >= NEED_LEVEL_LOW

/mob/living/proc/set_cy_stealth_mode(enabled)
	cy_stealth_mode = !!enabled
	update_cy_chameleon()
	return cy_stealth_mode

/mob/living/proc/is_cy_stealthing()
	return cy_stealth_mode && cy_chameleon_level > 0

/mob/living/proc/get_cy_stealth_light_factor()
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return 1
	return clamp(current_turf.get_lumcount(), 0, 1)

/mob/living/proc/get_cy_equipment_noise_weight()
	var/weight = 0
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		weight += equipped.w_class
	return weight

/mob/living/proc/get_cy_noise_level()
	var/noise = get_cy_equipment_noise_weight()
	if(is_cy_stealthing())
		noise *= max(0.1, 1 - cy_chameleon_level / 100)
	return noise

/mob/living/proc/update_cy_chameleon()
	if(!cy_stealth_mode || stat == DEAD)
		cy_chameleon_level = 0
		return 0
	var/stealth_level = get_cy_skill_level(/datum/cy_skill/charisma/stealth)
	var/light_penalty = round(get_cy_stealth_light_factor() * CY_STEALTH_LIGHT_PENALTY_MAX)
	var/move_penalty = (world.time - cy_last_stealth_move_time) <= 1 SECONDS ? CY_STEALTH_MOVE_PENALTY : 0
	var/weight_penalty = round(get_cy_equipment_noise_weight() * CY_STEALTH_WEIGHT_PENALTY_PER_CLASS)
	cy_chameleon_level = clamp(15 + stealth_level * 15 - light_penalty - move_penalty - weight_penalty, 0, CY_STEALTH_CHAMELEON_MAX)
	return cy_chameleon_level

/mob/living/proc/reveal_cy_stealth(reason)
	if(!cy_stealth_mode)
		return FALSE
	cy_stealth_mode = FALSE
	cy_chameleon_level = 0
	return TRUE

/mob/living/proc/set_cy_look_mode(enabled)
	cy_look_mode = !!enabled
	return cy_look_mode

/mob/living/proc/set_cy_listen_mode(enabled)
	cy_listen_mode = !!enabled
	return cy_listen_mode

/mob/living/proc/get_cy_fov_angle()
	if(is_blind())
		return 0
	if(is_nearsighted_currently())
		return max(30, CY_DEFAULT_FOV_DEGREES * 0.5)
	return CY_DEFAULT_FOV_DEGREES

/mob/living/proc/get_cy_view_range()
	var/base_range = client?.view || world.view
	if(cy_look_mode)
		base_range += 3
	if(is_blind())
		return 0
	if(is_nearsighted_currently())
		return min(base_range, NEARSIGHTNESS_FOV_BLINDNESS)
	return base_range

/mob/living/proc/cy_is_in_fov(atom/target)
	if(!target || target == src)
		return TRUE
	if(is_blind())
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return FALSE
	var/rel_x = target_turf.x - my_turf.x
	var/rel_y = target_turf.y - my_turf.y
	if(abs(rel_x) <= 1 && abs(rel_y) <= 1)
		return TRUE
	if(get_dist(src, target) > get_cy_view_range())
		return FALSE
	var/vector_len = sqrt(abs(rel_x) ** 2 + abs(rel_y) ** 2)
	var/dir_x = 0
	var/dir_y = 0
	if(dir & NORTH)
		dir_y += vector_len
	else if(dir & SOUTH)
		dir_y -= vector_len
	if(dir & EAST)
		dir_x += vector_len
	else if(dir & WEST)
		dir_x -= vector_len
	if(!dir_x && !dir_y)
		return TRUE
	var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))
	return angle <= get_cy_fov_angle() * 0.5

/mob/living/proc/cy_can_hear_event(atom/source)
	if(!source)
		return FALSE
	if(get_dist(src, source) <= world.view)
		return TRUE
	if(!cy_listen_mode)
		return FALSE
	if(get_dist(src, source) > world.view + 3)
		return FALSE
	var/turf/start = get_turf(src)
	var/turf/end = get_turf(source)
	if(!start || !end)
		return FALSE
	var/dense_turfs = 0
	for(var/turf/checked_turf as anything in get_line(start, end))
		if(checked_turf.density)
			dense_turfs++
			if(dense_turfs > 1)
				return FALSE
	return TRUE

/mob/living/proc/get_cy_organization_type_for_thing(datum/thing)
	if(!thing)
		return null
	if(thing.vars.Find("cy_organization_type"))
		return thing.vars["cy_organization_type"]
	if(thing.vars.Find("manufacturer_organization_type"))
		return thing.vars["manufacturer_organization_type"]
	return null

/mob/living/proc/get_cy_daemon_cast_time_multiplier(datum/daemon_source)
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(!org_type)
		return 1
	var/compatibility = get_cy_organization_compatibility(org_type)
	return compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL ? CY_DAEMON_CORP_MISMATCH_CAST_MULTIPLIER : 1

/mob/living/proc/get_cy_daemon_effectiveness_multiplier(datum/daemon_source)
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(!org_type)
		return 1
	var/compatibility = get_cy_organization_compatibility(org_type)
	return compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL ? CY_DAEMON_CORP_MISMATCH_EFFECTIVENESS_MULTIPLIER : 1

/obj/item/organ/cyberimp
	var/cy_organization_type
	var/cy_overheat = 0
	var/cy_active_implant = TRUE
	var/cy_requires_neurointerface = TRUE

/obj/item/organ/cyberimp/proc/is_cy_active_implant()
	return cy_active_implant

/obj/item/organ/cyberimp/proc/get_cy_implant_overheat()
	return cy_overheat

/obj/item/organ/cyberimp/proc/adjust_cy_implant_overheat(amount)
	cy_overheat = max(0, cy_overheat + amount)
	return cy_overheat

/mob/living/carbon/human/proc/has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		if(implant.type == /obj/item/organ/cyberimp/brain || findtext("[implant.type]", "neuro"))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/get_cy_implant_overheat_multiplier(obj/item/organ/cyberimp/implant)
	if(!implant?.cy_organization_type)
		return 1
	var/compatibility = get_cy_organization_compatibility(implant.cy_organization_type)
	return compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL ? CY_IMPLANT_CORP_MISMATCH_OVERHEAT_MULTIPLIER : 1

/mob/living/carbon/human/proc/get_cy_implant_failure_chance_modifier(obj/item/organ/cyberimp/implant)
	if(!implant?.cy_organization_type)
		return 0
	var/compatibility = get_cy_organization_compatibility(implant.cy_organization_type)
	return compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL ? CY_IMPLANT_CORP_MISMATCH_FAILURE_MODIFIER : 0

/mob/living/carbon/human/proc/get_cy_total_implant_overheat()
	var/total = 0
	for(var/obj/item/organ/cyberimp/implant in organs)
		total += implant.get_cy_implant_overheat()
	return total

/mob/living/carbon/human/proc/get_cy_brain_overheat_capacity()
	return max(10, get_cy_stat(/datum/cy_stat/spirit) * 10 + get_cy_stat(/datum/cy_stat/intelligence) * 5)

/mob/living/carbon/human/proc/process_cy_implant_overheat(seconds_per_tick)
	var/has_interface = has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		if(implant.cy_requires_neurointerface && !has_interface)
			continue
		implant.adjust_cy_implant_overheat(-CY_IMPLANT_OVERHEAT_DECAY_PER_SECOND * seconds_per_tick)
	var/overflow = get_cy_total_implant_overheat() - get_cy_brain_overheat_capacity()
	if(overflow <= 0)
		return FALSE
	adjust_psychic_loss(overflow * CY_IMPLANT_OVERHEAT_PSYCHIC_PER_SECOND * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	adjust_pain_loss(overflow * CY_IMPLANT_OVERHEAT_PAIN_PER_SECOND * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	if(overflow >= get_cy_brain_overheat_capacity() && SPT_PROB(1, seconds_per_tick))
		adjust_organ_loss(ORGAN_SLOT_BRAIN, 1)
	return TRUE

/mob/living/proc/on_cy_enter_clinical_death()
	if(mind)
		mind.degrade_cy_memories_on_death(src)
	return TRUE

/mob/living/carbon/human/proc/process_cy_clinical_death(seconds_per_tick)
	if(!clinical_death_started_at || stat == DEAD)
		return FALSE
	var/organ_damage = CY_CLINICAL_ORGAN_DAMAGE_PER_SECOND * seconds_per_tick
	for(var/organ_slot in list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH, ORGAN_SLOT_BRAIN))
		adjust_organ_loss(organ_slot, organ_damage)
	return TRUE

/mob/living/proc/is_cy_critical()
	return health <= critical_health_threshold && stat != DEAD

/mob/living/proc/is_cy_clinically_dead()
	return health <= clinical_death_threshold && stat != DEAD

/mob/living/proc/is_cy_brain_dead()
	return brain_dead

/mob/living/carbon/human/proc/can_cy_revive()
	if(brain_dead)
		return FALSE
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	return heart && !(heart.organ_flags & ORGAN_FAILING)

/mob/living/carbon/human/proc/create_cy_ghost_shell()
	var/mob/dead/observer/ghost = ghostize(FALSE)
	if(!ghost)
		return null
	ghost.name = name
	ghost.real_name = real_name
	ghost.appearance = appearance
	ghost.cy_original_body = src
	return ghost

/mob/dead/observer/proc/cy_weak_interact(atom/target)
	if(!target || world.time < next_move)
		return FALSE
	visible_message(span_notice("[src] leaves a faint, cold disturbance near [target]."))
	changeNext_move(5 SECONDS)
	return TRUE

/mob/living/carbon/human/proc/get_cy_clone_respawn_delay()
	var/delay = 10 MINUTES
	if(mind?.assigned_role)
		delay = 5 MINUTES
	return delay

/mob/living/carbon/human/proc/is_cy_body_abandoned()
	if(stat != DEAD && !is_cy_clinically_dead())
		return FALSE
	for(var/mob/living/viewer in viewers(7, src))
		if(viewer.client)
			return FALSE
	if(!cy_body_abandoned_at)
		cy_body_abandoned_at = world.time
	return world.time - cy_body_abandoned_at >= get_cy_clone_respawn_delay() * 2

/mob/living/carbon/human/proc/on_cy_body_abandoned()
	if(!is_cy_body_abandoned())
		return FALSE
	return TRUE

/mob/dead/observer
	var/mob/living/cy_original_body
