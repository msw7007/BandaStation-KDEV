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
	switch(skill_type)
		if(/datum/cy_skill/professional/cooking)
			if(HAS_TRAIT(src, TRAIT_CY_COOKING_6))
				return 0.2
			if(HAS_TRAIT(src, TRAIT_CY_COOKING_2))
				return 0.75
			if(!HAS_TRAIT(src, TRAIT_CY_COOKING_1))
				return 1.3
			return 1
		if(/datum/cy_skill/professional/mining)
			if(HAS_TRAIT(src, TRAIT_CY_MINING_6))
				return 0.25
			if(HAS_TRAIT(src, TRAIT_CY_MINING_2))
				return 0.75
			if(!HAS_TRAIT(src, TRAIT_CY_MINING_1))
				return 1.5
			return 1
		if(/datum/cy_skill/professional/analysis)
			var/analysis_multiplier = 1
			if(!HAS_TRAIT(src, TRAIT_CY_ANALYSIS_1))
				analysis_multiplier *= 1.5
			if(HAS_TRAIT(src, TRAIT_CY_ANALYSIS_2))
				analysis_multiplier *= 0.75
			if(HAS_TRAIT(src, TRAIT_CY_ANALYSIS_4))
				analysis_multiplier *= 0.75
			return analysis_multiplier
		if(/datum/cy_skill/professional/construction)
			if(!HAS_TRAIT(src, TRAIT_CY_CONSTRUCTION_1))
				return 1.3
			if(HAS_TRAIT(src, TRAIT_CY_CONSTRUCTION_2))
				return 0.8
			return 1
		if(/datum/cy_skill/professional/invention)
			if(!HAS_TRAIT(src, TRAIT_CY_INVENTION_1))
				return 1.3
			if(HAS_TRAIT(src, TRAIT_CY_INVENTION_5))
				return 0.7
			if(HAS_TRAIT(src, TRAIT_CY_INVENTION_3))
				return 0.9
			return 1
	var/level_modifier = get_cy_skill_perk_level(skill_type) * 0.08
	var/perk_modifier = get_cy_skill_perk_work_speed_bonus(skill_type) * 0.01
	return max(0.35, 1 - level_modifier - perk_modifier)

/mob/living/proc/get_cy_skill_probability_bonus(skill_type)
	return (get_cy_skill_perk_level(skill_type) * CY_SKILL_VALUE_PER_LEVEL) + get_cy_skill_perk_check_bonus(skill_type)

/mob/living/proc/get_cy_skill_value_modifier(skill_type)
	return get_cy_skill_perk_level(skill_type) + get_cy_skill_perk_quality_bonus(skill_type)

/mob/living/proc/get_cy_skill_speed_multiplier_no_perks(skill_type)
	return max(0.4, 1 - get_cy_skill_level(skill_type) * CY_PROFESSIONAL_SKILL_SPEED_PER_LEVEL)

/mob/living/proc/get_cy_skill_probability_bonus_no_perks(skill_type)
	return get_cy_skill_level(skill_type) * CY_SKILL_VALUE_PER_LEVEL

/mob/living/proc/get_cy_skill_quality_bonus_no_perks(skill_type)
	return get_cy_skill_level(skill_type) * CY_PROFESSIONAL_SKILL_QUALITY_PER_LEVEL

/mob/living/proc/has_cy_skill_perk_level(skill_type, required_level)
	return HAS_TRAIT(src, cy_skill_perk_trait(skill_type, required_level))

/mob/living/proc/get_cy_skill_perk_level(skill_type)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return CY_SKILL_MINIMUM_LEVEL

	for(var/level in skill.max_level to CY_SKILL_LEVEL_BEGINNER step -1)
		if(HAS_TRAIT(src, cy_skill_perk_trait(skill_type, level)))
			return level

	return CY_SKILL_MINIMUM_LEVEL

/mob/living/proc/get_cy_skill_level_ratio(skill_type)
	return clamp(get_cy_skill_level(skill_type) / CY_SKILL_MAXIMUM_LEVEL, 0, 1)

/mob/living/proc/get_cy_incoming_damage_multiplier()
	var/toughness_multiplier = 1
	if(HAS_TRAIT(src, TRAIT_CY_TOUGHNESS_6))
		toughness_multiplier = body_position == LYING_DOWN ? 0.9 : 0.8
	else if(!HAS_TRAIT(src, TRAIT_CY_TOUGHNESS_1))
		toughness_multiplier = 1.1
	if(world.time < cy_surrender_until)
		toughness_multiplier *= 0.7
	if(world.time < cy_parry_resist_until)
		toughness_multiplier *= CY_PARRY_SUCCESS_DAMAGE_MULTIPLIER
	return toughness_multiplier

/mob/living/proc/get_cy_stagger_duration_multiplier()
	var/multiplier = 1
	if(HAS_TRAIT(src, TRAIT_CY_TOUGHNESS_3))
		multiplier *= body_position == LYING_DOWN ? 0.75 : 0.5
	if(HAS_TRAIT(src, TRAIT_CY_SPIRIT_ENDURANCE_4))
		multiplier *= 0.5
	return multiplier

/mob/living/proc/get_cy_negative_effect_duration_multiplier()
	if(HAS_TRAIT(src, TRAIT_CY_INTELLIGENCE_COMPOSURE_5))
		return 0.75
	if(HAS_TRAIT(src, TRAIT_CY_INTELLIGENCE_COMPOSURE_2))
		return 0.8
	return 1

/mob/living/proc/get_cy_professional_quality_bonus(skill_type)
	return (get_cy_skill_perk_level(skill_type) * CY_PROFESSIONAL_SKILL_QUALITY_PER_LEVEL) + (get_cy_skill_perk_quality_bonus(skill_type) * 0.05)

/mob/living/proc/award_cy_professional_activity(skill_type, amount = CY_PROFESSIONAL_SKILL_EXPERIENCE_BASE)
	if(!ispath(skill_type, /datum/cy_skill/professional) || amount <= 0)
		return FALSE
	return award_cy_raw_skill_experience(skill_type, amount, TRUE)

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
	if(required_level > CY_SKILL_MINIMUM_LEVEL && !HAS_TRAIT(src, cy_skill_perk_trait(skill_type, required_level)))
		return FALSE
	return roll_cy_skill_check(skill_type, difficulty, grant_experience, ignore_stat_limit)

/mob/living/proc/get_cy_cohort_limit()
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_6))
		return 8
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_5))
		return 6
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_4))
		return 4
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_3))
		return 3
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_2))
		return 2
	return CY_COHORT_BASE_LIMIT

/mob/living/proc/is_cy_cohort_member(mob/living/target)
	return target && (target in cy_cohort_members)

/mob/living/proc/cleanup_cy_cohort()
	if(!islist(cy_cohort_members))
		cy_cohort_members = list()
	for(var/mob/living/member as anything in cy_cohort_members.Copy())
		if(QDELETED(member) || member.stat == DEAD || get_dist(src, member) > 30)
			cy_cohort_members -= member
	while(length(cy_cohort_members) > get_cy_cohort_limit())
		cy_cohort_members.Cut(length(cy_cohort_members), length(cy_cohort_members) + 1)
	return cy_cohort_members

/mob/living/proc/add_cy_cohort_member(mob/living/target)
	if(!target || target == src)
		return FALSE
	cleanup_cy_cohort()
	if(target in cy_cohort_members)
		return TRUE
	if(length(cy_cohort_members) >= get_cy_cohort_limit())
		return FALSE
	cy_cohort_members += target
	return TRUE

/mob/living/proc/remove_cy_cohort_member(mob/living/target)
	if(!target || !(target in cy_cohort_members))
		return FALSE
	cy_cohort_members -= target
	return TRUE

/mob/living/proc/get_cy_cohort_effect_multiplier(mob/living/target)
	if(!is_cy_cohort_member(target))
		return 0
	var/multiplier = 1
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_3))
		multiplier *= 1.25
	if(HAS_TRAIT(src, TRAIT_CY_INSPIRATION_4))
		multiplier *= 1.2
	return multiplier

/mob/living/proc/get_cy_theft_notice_chance(mob/living/victim)
	var/theft_level = get_cy_skill_perk_level(/datum/cy_skill/charisma/theft)
	if(HAS_TRAIT(src, TRAIT_CY_THEFT_4))
		var/victim_perception = victim?.get_cy_stat(/datum/cy_stat/perception) || CY_STAT_DEFAULT
		if(victim_perception < theft_level * 3)
			return 0
	if(HAS_TRAIT(src, TRAIT_CY_THEFT_2))
		return is_cy_stealthing() ? 50 : 75
	if(HAS_TRAIT(src, TRAIT_CY_THEFT_1))
		return 100
	return 100

/mob/living/proc/get_cy_theft_delay_multiplier()
	var/theft_level = get_cy_skill_perk_level(/datum/cy_skill/charisma/theft)
	if(HAS_TRAIT(src, TRAIT_CY_THEFT_4))
		return 0
	return max(0.35, 1 - theft_level * 0.08)

/mob/living/proc/can_cy_steal_strippable_key(key)
	if(HAS_TRAIT(src, TRAIT_CY_THEFT_6))
		return TRUE
	return !(key in list(
		STRIPPABLE_ITEM_LHAND,
		STRIPPABLE_ITEM_RHAND,
		STRIPPABLE_ITEM_BACK,
		STRIPPABLE_ITEM_BELT,
		STRIPPABLE_ITEM_JUMPSUIT,
		STRIPPABLE_ITEM_SUIT,
		STRIPPABLE_ITEM_HEAD,
	))

/mob/living/proc/cy_can_be_stripped_freely()
	return cy_compliant_stripping || world.time < cy_surrender_until || stat >= UNCONSCIOUS || IsStun() || IsParalyzed() || IsImmobilized()

/mob/living/proc/cy_warn_theft_attempt(mob/living/victim, obj/item/item)
	if(!victim || !item)
		return FALSE
	var/notice_chance = get_cy_theft_notice_chance(victim)
	if(notice_chance && prob(notice_chance))
		to_chat(victim, span_userdanger("[capitalize(declent_ru(NOMINATIVE))] пытается украсть [item.ru_p_yours(ACCUSATIVE)] [item.declent_ru(ACCUSATIVE)]!"))
		for(var/mob/living/witness in viewers(1, victim))
			if(witness == victim || witness == src)
				continue
			to_chat(witness, span_warning("[capitalize(declent_ru(NOMINATIVE))] замечает попытку кражи у [victim.declent_ru(GENITIVE)]."))
	return TRUE
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


/proc/cy_has_click_modifier(list/modifiers, modifier)
	if(!islist(modifiers) || !modifier)
		return FALSE
	return !!modifiers[modifier]

/proc/cy_safe_params2list(params)
	if(!istext(params) || !length(params))
		return list()
	return params2list(params)

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

/mob/living/proc/get_cy_weapon_accuracy_bonus(obj/item/weapon)
	return get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_ACCURACY_PER_LEVEL

/mob/living/proc/get_cy_stat_weapon_damage_multiplier(obj/item/weapon)
	if(!weapon)
		return 1
	var/multiplier = 1
	if(weapon.w_class >= WEIGHT_CLASS_BULKY)
		if(!HAS_TRAIT(src, TRAIT_CY_HEAVY_WEAPONS_1))
			multiplier *= 0.9
		multiplier += get_cy_skill_perk_level(/datum/cy_skill/strength/heavy_weapons) * 0.03
		if(HAS_TRAIT(src, TRAIT_CY_HEAVY_WEAPONS_2))
			multiplier += get_cy_stat(/datum/cy_stat/strength) * 0.005
	else if(weapon.w_class <= WEIGHT_CLASS_SMALL)
		multiplier += get_cy_skill_perk_level(/datum/cy_skill/dexterity/light_weapons) * 0.02
	if(weapon.get_sharpness())
		multiplier += get_cy_skill_perk_level(/datum/cy_skill/perception/precise_melee) * 0.015
	if(HAS_TRAIT(src, TRAIT_CY_WEAKSPOT_ANALYSIS_3))
		multiplier += 0.05
	return multiplier

/mob/living/proc/get_cy_weapon_spread_multiplier(obj/item/weapon)
	var/multiplier = 1 - get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_SPREAD_REDUCTION_PER_LEVEL
	if(weapon?.w_class >= WEIGHT_CLASS_BULKY)
		if(HAS_TRAIT(src, TRAIT_CY_HEAVY_WEAPONS_6))
			multiplier = min(multiplier, 0.1)
		else if(HAS_TRAIT(src, TRAIT_CY_HEAVY_WEAPONS_4))
			multiplier *= 0.7
	return max(0.1, multiplier)

/mob/living/proc/apply_cy_stat_weapon_onhit_effects(mob/living/target, obj/item/weapon, target_zone, damage_done)
	if(!target || !weapon || target == src || damage_done <= 0)
		return FALSE
	if(HAS_TRAIT(src, TRAIT_CY_HEAVY_WEAPONS_6) && weapon.w_class >= WEIGHT_CLASS_BULKY && prob(10))
		target.Knockdown(1.5 SECONDS)
	if(HAS_TRAIT(src, TRAIT_CY_LIGHT_WEAPONS_3) && weapon.w_class <= WEIGHT_CLASS_NORMAL && prob(25))
		target.adjust_stamina_loss(6)
	if(HAS_TRAIT(src, TRAIT_CY_WEAKSPOT_ANALYSIS_2) && prob(10))
		target.apply_damage(max(1, round(damage_done * 0.2)), weapon.damtype, target_zone)
	if(HAS_TRAIT(src, TRAIT_CY_WEAKSPOT_ANALYSIS_4) && prob(15))
		target.Immobilize(2 SECONDS)
	if(HAS_TRAIT(src, TRAIT_CY_WEAKSPOT_ANALYSIS_6) && target_zone == BODY_ZONE_HEAD && prob(25))
		target.Paralyze(2 SECONDS)
	if(HAS_TRAIT(src, TRAIT_CY_PRECISE_MELEE_5) && target_zone == BODY_ZONE_HEAD && prob(30))
		target.adjust_confusion_up_to(4 SECONDS, 8 SECONDS)
	if(HAS_TRAIT(src, TRAIT_CY_STYLE_6) && prob(20))
		target.adjust_temp_blindness_up_to(2 SECONDS, 4 SECONDS)
	return TRUE

/mob/living/proc/award_cy_weapon_activity(obj/item/weapon, amount)
	if(!weapon || amount <= 0)
		return FALSE
	var/skill_type = weapon.get_cy_weapon_skill_type()
	if(!ispath(skill_type, /datum/cy_skill/weapon))
		return FALSE
	return award_cy_raw_skill_experience(skill_type, amount, TRUE)

/datum/crafting_recipe/proc/get_cy_professional_skill_type()
	if(ispath(result, /obj/item/food))
		return /datum/cy_skill/professional/cooking
	if(ispath(result, /obj/item/seeds))
		return /datum/cy_skill/professional/gardening
	if(ispath(result, /obj/item/reagent_containers) || ispath(result, /datum/reagent))
		return /datum/cy_skill/professional/chemistry
	if(ispath(result, /obj/item/circuitboard) || ispath(result, /obj/machinery))
		return /datum/cy_skill/professional/electricity
	if(ispath(result, /obj/structure) || ispath(result, /turf))
		return /datum/cy_skill/professional/construction
	if(ispath(result, /obj/item))
		return /datum/cy_skill/professional/invention
	return null

/atom/proc/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return current_recipe?.get_cy_professional_skill_type()

/obj/item/food/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/cooking

/obj/item/seeds/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/gardening

/obj/item/reagent_containers/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/chemistry

/obj/item/circuitboard/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/electricity

/obj/machinery/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/electricity

/obj/structure/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/construction

/mob/living/proc/get_cy_professional_crafting_speed_multiplier(datum/crafting_recipe/recipe)
	var/skill_type = recipe?.get_cy_professional_skill_type()
	if(!skill_type)
		return 1
	return get_cy_skill_speed_multiplier(skill_type)

/mob/living/proc/get_cy_professional_crafting_quality_bonus(datum/crafting_recipe/recipe)
	var/skill_type = recipe?.get_cy_professional_skill_type()
	if(!skill_type)
		return 0
	return get_cy_professional_quality_bonus(skill_type)

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

/mob/living/proc/get_cy_equipment_style_score()
	var/score = 0
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		score += equipped.get_cy_style_value()
	var/list/tags = get_cy_equipment_style_tags()
	var/conflicting_styles = 0
	for(var/style_tag in list(CY_ITEM_STYLE_TAG_CORPORATE, CY_ITEM_STYLE_TAG_STREET, CY_ITEM_STYLE_TAG_COMBAT, CY_ITEM_STYLE_TAG_LUXURY))
		if(tags[style_tag])
			conflicting_styles++
	if(conflicting_styles > 1)
		score -= (conflicting_styles - 1) * 2
	return clamp(score, -10, 10)

/mob/living/proc/get_cy_equipment_style_tags()
	var/list/tags = list()
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		for(var/style_tag in equipped.get_cy_style_tags())
			tags[style_tag] = (tags[style_tag] || 0) + 1
	return tags

/mob/living/proc/get_cy_psyche_state()
	return list(
		"pain" = get_pain_loss(),
		"psychic_pressure" = get_psychic_loss(),
		"mood" = mob_mood?.mood,
		"mood_level" = mob_mood?.mood_level,
		"sanity" = mob_mood?.sanity,
		"sanity_level" = mob_mood?.sanity_level,
		"equipment_style" = get_cy_equipment_style_score(),
		"equipment_style_tags" = get_cy_equipment_style_tags(),
	)

/mob/living/proc/update_cy_style_stat_modifiers()
	var/style_score = get_cy_equipment_style_score()
	var/charisma_modifier = clamp(round(style_score / 5), -2, 2)
	var/spirit_modifier = clamp(round(style_score / 10), -1, 1)
	var/pain_penalty = clamp(round(get_pain_loss() / 40), 0, 3)
	set_cy_stat_modifier(/datum/cy_stat/charisma, "cy_equipment_style", charisma_modifier)
	set_cy_stat_modifier(/datum/cy_stat/spirit, "cy_equipment_style", spirit_modifier - pain_penalty)
	return charisma_modifier + spirit_modifier - pain_penalty

/mob/living/proc/get_cy_experience_context_multiplier()
	var/multiplier = 1
	var/style_score = get_cy_equipment_style_score()
	if(style_score)
		multiplier += style_score * 0.01
	if(mob_mood)
		multiplier *= mob_mood.get_cy_training_experience_multiplier()
	return max(0.25, multiplier)

/mob/living/proc/get_cy_market_style_discount_multiplier()
	var/style_score = max(0, get_cy_equipment_style_score())
	return max(0.9, 1 - (style_score * 0.01))

/mob/living/proc/get_cy_style_examine_lines(mob/living/viewer)
	var/list/result = list()
	var/style_score = get_cy_equipment_style_score()
	if(style_score <= -5)
		result += "Their worn style makes their training and habits hard to read."
		if(style_score <= -8)
			result += "The outfit actively hides useful tells about their strengths."
		return result
	if(style_score < 5)
		return result

	result += "Their style is coherent enough to reveal a few personal tells."
	var/list/stat_names = list(
		/datum/cy_stat/strength = "strength",
		/datum/cy_stat/dexterity = "dexterity",
		/datum/cy_stat/perception = "perception",
		/datum/cy_stat/intelligence = "intelligence",
		/datum/cy_stat/spirit = "spirit",
		/datum/cy_stat/charisma = "charisma",
	)
	var/best_stat_type
	var/best_stat_value = -INFINITY
	for(var/stat_type in stat_names)
		var/stat_value = get_cy_stat(stat_type)
		if(stat_value > best_stat_value)
			best_stat_value = stat_value
			best_stat_type = stat_type
	if(best_stat_type)
		result += "Most readable strength: [stat_names[best_stat_type]] [best_stat_value]."

	if(style_score < 8)
		return result

	var/best_skill_type
	var/best_skill_level = 0
	for(var/skill_type in get_all_cy_skill_types())
		var/skill_level = get_cy_skill_level(skill_type)
		if(skill_level > best_skill_level)
			best_skill_level = skill_level
			best_skill_type = skill_type
	if(best_skill_type && HAS_TRAIT(src, cy_skill_perk_trait(best_skill_type, CY_SKILL_LEVEL_BEGINNER)))
		var/datum/cy_skill/skill = get_cy_skill_datum(best_skill_type)
		var/skill_id = skill?.id || "unknown"
		result += "Most visible training: [skill_id] [best_skill_level]."
	return result

/mob/living/proc/get_cy_controlled_items_in_zone()
	var/list/result = list()
	var/area/current_area = get_area(src)
	if(!current_area)
		return result
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		if(current_area.cy_requires_controlled_item_permit(equipped))
			result += equipped
	return result

/mob/living/proc/report_cy_controlled_items_in_zone(issuer = "Zone audit")
	if(!SSeconomy)
		return 0
	var/count = 0
	for(var/obj/item/item as anything in get_cy_controlled_items_in_zone())
		SSeconomy.cy_issue_violation(src, CY_LAW_CONTROLLED_ITEM, "Controlled item in restricted zone: [item.name].", issuer, null, null, CY_WARRANT_INVESTIGATION)
		item.cy_leave_forensic_trace(src, "controlled item possession", 80)
		count++
	return count

/mob/living/proc/on_cy_enter_area_audit(datum/source, area/entered_area)
	SIGNAL_HANDLER
	if(world.time < cy_next_controlled_item_audit_at)
		return FALSE
	if(!entered_area)
		return FALSE
	var/controlled_count = length(get_cy_controlled_items_in_zone())
	if(!controlled_count)
		return FALSE
	cy_next_controlled_item_audit_at = world.time + 2 MINUTES
	report_cy_controlled_items_in_zone("Area security scan")
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_LAW, controlled_count, src)
	return TRUE

/mob/living/proc/report_cy_violent_action(mob/living/target, obj/item/weapon = null, issuer = "Zone violence monitor")
	if(!target || target == src || world.time < cy_next_violence_report_at)
		return FALSE
	var/area/current_area = get_area(src)
	if(!current_area || current_area.cy_allows_open_violence())
		return FALSE
	cy_next_violence_report_at = world.time + 30 SECONDS
	var/law_id = target.stat == DEAD ? CY_LAW_MURDER : CY_LAW_ASSAULT
	var/details = "[src] attacked [target][weapon ? " with [weapon]" : ""] in [current_area.name]."
	SSeconomy?.cy_issue_violation(src, law_id, details, issuer, null, null, CY_WARRANT_INVESTIGATION)
	cy_leave_forensic_trace(src, "violent action", 75)
	target.cy_leave_forensic_trace(src, "violence target", 65)
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_VIOLENCE, law_id == CY_LAW_MURDER ? 10 : 4, src)
	return TRUE

/mob/living/proc/on_cy_story_item_attack(datum/source, mob/living/attacked_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER
	var/obj/item/weapon = user?.get_active_held_item()
	return report_cy_violent_action(attacked_mob, weapon)

/mob/living/proc/on_cy_story_unarmed_attack(datum/source, atom/attacked_atom, proximity)
	SIGNAL_HANDLER
	if(!proximity || !isliving(attacked_atom))
		return FALSE
	return report_cy_violent_action(attacked_atom)

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
	var/new_mode = !!enabled
	if(new_mode == cy_stealth_mode)
		update_cy_chameleon()
		return cy_stealth_mode
	cy_stealth_mode = new_mode
	if(cy_stealth_mode)
		cy_stealth_original_alpha = alpha
		add_movespeed_modifier(/datum/movespeed_modifier/cy_stealth)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/cy_stealth)
		cy_chameleon_level = 0
		cy_wall_pressed = FALSE
		cy_wall_press_dir = NONE
		remove_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, animate = TRUE)
		animate(src, alpha = cy_stealth_original_alpha || 255, time = 0.3 SECONDS)
		return FALSE
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
		animate(src, alpha = cy_stealth_original_alpha || 255, time = 0.2 SECONDS)
		return 0
	var/stealth_level = get_cy_skill_perk_level(/datum/cy_skill/charisma/stealth)
	var/light_factor = get_cy_stealth_light_factor()
	var/light_hide = round((1 - light_factor) * CY_STEALTH_CHAMELEON_MAX)
	var/skill_bonus = stealth_level * 10
	var/move_penalty = (world.time - cy_last_stealth_move_time) <= 1 SECONDS ? CY_STEALTH_MOVE_PENALTY : 0
	var/weight_penalty = round(get_cy_equipment_noise_weight() * CY_STEALTH_WEIGHT_PENALTY_PER_CLASS)
	var/wall_bonus = cy_wall_pressed ? CY_STEALTH_WALL_CHAMELEON_BONUS : 0
	var/hidden_bonus = cy_hidden_under ? CY_STEALTH_HIDDEN_CHAMELEON_BONUS : 0
	cy_chameleon_level = clamp(light_hide + skill_bonus + wall_bonus + hidden_bonus - move_penalty - weight_penalty, 0, CY_STEALTH_CHAMELEON_MAX)
	var/target_alpha = round((cy_stealth_original_alpha || 255) - ((cy_stealth_original_alpha || 255) - CY_STEALTH_MIN_ALPHA) * (cy_chameleon_level / CY_STEALTH_CHAMELEON_MAX))
	animate(src, alpha = target_alpha, time = 0.3 SECONDS)
	if(client && world.time >= cy_last_stealth_debug_time + CY_STEALTH_DEBUG_INTERVAL)
		cy_last_stealth_debug_time = world.time
		to_chat(src, span_notice("Скрытность: свет [round(light_factor * 100)]%, хамелеон [cy_chameleon_level]%."))
	return cy_chameleon_level

/mob/living/proc/reveal_cy_stealth(reason)
	if(!cy_stealth_mode)
		return FALSE
	set_cy_stealth_mode(FALSE)
	return TRUE

/mob/living/proc/set_cy_look_mode(enabled)
	cy_look_mode = !!enabled
	return cy_look_mode

/mob/living/proc/set_cy_listen_mode(enabled)
	cy_listen_mode = !!enabled
	return cy_listen_mode

/mob/living/proc/toggle_cy_listen_mode(show_message = TRUE)
	set_cy_listen_mode(!cy_listen_mode)
	if(show_message)
		if(cy_listen_mode)
			to_chat(src, span_notice("Вы прислушиваетесь."))
		else
			to_chat(src, span_notice("Вы перестаёте прислушиваться."))
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
	if(thing.vars.Find("manufacturer_organization"))
		var/datum/cy_organization/manufacturer = resolve_cy_organization_datum(thing.vars["manufacturer_organization"])
		if(manufacturer)
			return manufacturer.type
	if(thing.vars.Find("cy_organization_type"))
		return thing.vars["cy_organization_type"]
	if(thing.vars.Find("manufacturer_organization_type"))
		return thing.vars["manufacturer_organization_type"]
	return null

/mob/living/proc/get_cy_daemon_cast_time_multiplier(datum/daemon_source)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_DAEMON_CORP_MISMATCH_CAST_MULTIPLIER
	if(!HAS_TRAIT(src, TRAIT_CY_FAST_CODE_1))
		multiplier *= 1.1
	else if(HAS_TRAIT(src, TRAIT_CY_FAST_CODE_2))
		multiplier *= 0.8
	if(HAS_TRAIT(src, TRAIT_CY_FAST_CODE_4) && prob(25))
		multiplier *= 0.5
	if(HAS_TRAIT(src, TRAIT_CY_FAST_CODE_6) && prob(25))
		multiplier = 0
	return multiplier

/mob/living/proc/get_cy_daemon_effectiveness_multiplier(datum/daemon_source)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(daemon_source)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_DAEMON_CORP_MISMATCH_EFFECTIVENESS_MULTIPLIER
	if(!HAS_TRAIT(src, TRAIT_CY_IMPROVED_CODE_1))
		multiplier *= 0.8
	else if(HAS_TRAIT(src, TRAIT_CY_IMPROVED_CODE_2))
		multiplier *= 1.3
	if(HAS_TRAIT(src, TRAIT_CY_IMPROVED_CODE_3))
		multiplier *= 1.25
	if(HAS_TRAIT(src, TRAIT_CY_IMPROVED_CODE_6))
		multiplier *= 1.5
	return multiplier

/obj/item/organ/cyberimp
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski
	var/cy_organization_type
	var/cy_implant_is_neurointerface = FALSE
	var/cy_overheat = 0
	var/cy_active_implant = TRUE
	var/cy_requires_neurointerface = TRUE
	var/cy_last_functional_state

/obj/item/organ/cyberimp/brain
	manufacturer_organization = /datum/cy_organization/corporation/starlight/samanthas_care

/obj/item/organ/cyberimp/brain/connector
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_implant_is_neurointerface = TRUE
	cy_requires_neurointerface = FALSE

/obj/item/organ/cyberimp/bci
	manufacturer_organization = /datum/cy_organization/corporation/starlight/trans_travel
	cy_implant_is_neurointerface = TRUE
	cy_requires_neurointerface = FALSE

/obj/item/organ/cyberimp/eyes
	manufacturer_organization = /datum/cy_organization/corporation/ben/san_yon

/obj/item/organ/cyberimp/mouth
	manufacturer_organization = /datum/cy_organization/corporation/ben/ishikawa

/obj/item/organ/cyberimp/arm
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla

/obj/item/organ/cyberimp/chest
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/kowalski

/obj/item/organ/cyberimp/chest/thrusters
	manufacturer_organization = /datum/cy_organization/corporation/ben/ho_shi

/obj/item/organ/cyberimp/chest/spine
	manufacturer_organization = /datum/cy_organization/corporation/ryaznov/tesla

/obj/item/organ/cyberimp/proc/has_cy_working_neurointerface()
	if(!cy_requires_neurointerface)
		return TRUE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/human_owner = owner
	return human_owner.has_cy_neurointerface()

/obj/item/organ/cyberimp/proc/is_cy_active_implant()
	return cy_active_implant && has_cy_working_neurointerface()

/obj/item/organ/cyberimp/proc/is_cy_functional_implant()
	return !(organ_flags & ORGAN_FAILING) && has_cy_working_neurointerface()

/obj/item/organ/cyberimp/proc/can_cy_use_implant(mob/living/user, silent = FALSE)
	if(!owner)
		return FALSE
	if(organ_flags & ORGAN_FAILING)
		if(!silent)
			to_chat(user || owner, span_warning("[src] does not respond."))
		return FALSE
	if(!has_cy_working_neurointerface())
		if(!silent)
			to_chat(user || owner, span_warning("[src] needs a working neural interface."))
		return FALSE
	return TRUE

/obj/item/organ/cyberimp/proc/update_cy_functional_state()
	var/current_state = is_cy_functional_implant()
	if(isnull(cy_last_functional_state))
		cy_last_functional_state = current_state
		return current_state
	if(cy_last_functional_state == current_state)
		return current_state
	cy_last_functional_state = current_state
	cy_on_functional_state_changed(current_state)
	return current_state

/obj/item/organ/cyberimp/proc/cy_on_functional_state_changed(functional)
	return TRUE

/obj/item/organ/cyberimp/proc/get_cy_implant_overheat()
	return cy_overheat

/obj/item/organ/cyberimp/proc/adjust_cy_implant_overheat(amount)
	cy_overheat = max(0, cy_overheat + amount)
	return cy_overheat

/mob/living/carbon/human/proc/has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		if(implant.organ_flags & ORGAN_FAILING)
			continue
		if(implant.cy_implant_is_neurointerface || implant.type == /obj/item/organ/cyberimp/brain || findtext("[implant.type]", "neuro"))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/get_cy_implant_overheat_multiplier(obj/item/organ/cyberimp/implant)
	var/multiplier = 1
	var/org_type = get_cy_organization_type_for_thing(implant)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			multiplier *= CY_IMPLANT_CORP_MISMATCH_OVERHEAT_MULTIPLIER
	if(!HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_1))
		multiplier *= 1.2
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_3))
		multiplier *= 0.5
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_4))
		multiplier *= 0.7
	return multiplier

// CYBERPUNK 13 STAGE 3 CORE IMPLANT HEAT FIX3 START
/mob/living/carbon/human/proc/get_cy_implant_humanoidity_heat_multiplier()
	if(!has_dna())
		return 1
	return 1 + ((100 - get_cy_humanoidity()) * CY_IMPLANT_HUMANITY_HEAT_MULTIPLIER)
// CYBERPUNK 13 STAGE 3 CORE IMPLANT HEAT FIX3 END

/mob/living/carbon/human/proc/get_cy_implant_failure_chance_modifier(obj/item/organ/cyberimp/implant)
	var/modifier = 0
	var/org_type = get_cy_organization_type_for_thing(implant)
	if(org_type)
		var/compatibility = get_cy_organization_compatibility(org_type)
		if(compatibility <= CY_ORGANIZATION_COMPATIBILITY_NEUTRAL)
			modifier += CY_IMPLANT_CORP_MISMATCH_FAILURE_MODIFIER
	if(!HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_1))
		modifier += 1
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_6))
		modifier -= 100
	return modifier

/mob/living/carbon/human/proc/get_cy_total_implant_overheat()
	var/total = 0
	for(var/obj/item/organ/cyberimp/implant in organs)
		total += implant.get_cy_implant_overheat()
	return total

/mob/living/carbon/human/proc/get_cy_brain_overheat_capacity()
	var/capacity = max(10, get_cy_stat(/datum/cy_stat/spirit) * 10 + get_cy_stat(/datum/cy_stat/intelligence) * 5)
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_2))
		capacity *= 1.3
	return capacity

/mob/living/carbon/human/proc/process_cy_implant_overheat(seconds_per_tick)
	var/has_interface = has_cy_neurointerface()
	for(var/obj/item/organ/cyberimp/implant in organs)
		implant.update_cy_functional_state()
		if(implant.cy_requires_neurointerface && !has_interface)
			if(SPT_PROB(CY_IMPLANT_NO_INTERFACE_FAILURE_CHANCE, seconds_per_tick))
				implant.apply_organ_damage(0.25 * seconds_per_tick)
			continue
		var/heat_gain = implant.is_cy_active_implant() ? CY_IMPLANT_BASE_ACTIVE_HEAT_PER_SECOND : CY_IMPLANT_BASE_PASSIVE_HEAT_PER_SECOND
		implant.adjust_cy_implant_overheat((heat_gain * get_cy_implant_overheat_multiplier(implant) * get_cy_implant_humanoidity_heat_multiplier() - CY_IMPLANT_OVERHEAT_DECAY_PER_SECOND) * seconds_per_tick)
	var/overflow = get_cy_total_implant_overheat() - get_cy_brain_overheat_capacity()
	if(overflow <= 0)
		return FALSE
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_5))
		add_movespeed_modifier(/datum/movespeed_modifier/cy_implant_overload)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cy_implant_overload), 2 SECONDS)
		return TRUE
	if(HAS_TRAIT(src, TRAIT_CY_COMPATIBILITY_6))
		return TRUE
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
	if(cy_abandoned_body_rescue_attempted)
		return FALSE
	cy_abandoned_body_rescue_attempted = TRUE
	visible_message(span_warning("An emergency rescue contract pings for [src]."))
	cy_leave_forensic_trace(src, "abandoned body rescue", 60)
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_RESCUE, 5, src)
	if(can_cy_revive())
		heal_and_revive(max(25, round(maxHealth * 0.35)), "Emergency rescue contractors stabilize you.")
		clinical_death_started_at = null
		return TRUE
	return TRUE

/mob/dead/observer
	var/mob/living/cy_original_body

// Core control layer for CyberPunk-style input. Kept here so generated builds compile it with living stat helpers.
/datum/movespeed_modifier/cy_stealth
	movetypes = (~FLYING)
	multiplicative_slowdown = CY_STEALTH_MOVE_SLOWDOWN

/datum/movespeed_modifier/cy_sprint
	movetypes = (~FLYING)
	multiplicative_slowdown = CY_SPRINT_SPEED_MODIFIER

/datum/movespeed_modifier/cy_shoulder_carry
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.7

/datum/movespeed_modifier/cy_arms_carry
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.3

/datum/movespeed_modifier/cy_implant_overload
	movetypes = (~FLYING)
	multiplicative_slowdown = 0.35

/mob/living/proc/update_cy_sprint()
	if(!cy_sprint_enabled || move_intent == MOVE_INTENT_WALK || get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS || body_position != STANDING_UP || stat != CONSCIOUS)
		if(cy_sprinting)
			cy_sprinting = FALSE
			remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		return FALSE
	if(!cy_sprinting)
		cy_sprinting = TRUE
		add_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
	return TRUE

/mob/living/proc/set_cy_sprint_enabled(enabled)
	if(cy_sprint_enabled == enabled)
		if(!enabled && cy_sprinting)
			cy_sprinting = FALSE
			remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		return FALSE
	cy_sprint_enabled = enabled
	if(!cy_sprint_enabled)
		cy_sprinting = FALSE
		remove_movespeed_modifier(/datum/movespeed_modifier/cy_sprint)
		to_chat(src, span_notice("Вы замедляете бег."))
		return TRUE
	if(get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS || body_position != STANDING_UP || stat != CONSCIOUS)
		cy_sprint_enabled = FALSE
		to_chat(src, span_warning("У вас не хватает сил для спринта."))
		return FALSE
	to_chat(src, span_notice("Вы переходите на спринт."))
	update_cy_sprint()
	return TRUE

/mob/living/proc/toggle_cy_sprint()
	return set_cy_sprint_enabled(!cy_sprint_enabled)

/mob/living/proc/process_cy_sprint_step()
	if(!cy_sprint_enabled || !update_cy_sprint())
		return FALSE
	if(!cy_sprinting)
		return FALSE
	adjust_stamina_loss(CY_SPRINT_STAMINA_COST_PER_STEP, updating_stamina = FALSE, forced = TRUE)
	if(get_stamina_loss() >= CY_SPRINT_STAMINA_STOP_LOSS)
		set_cy_sprint_enabled(FALSE)
	return TRUE


/mob/living/proc/is_cy_sprint_collision_surface(atom/target)
	if(!target)
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/blocker in target_turf)
			if(blocker == src || !blocker.density)
				continue
			return TRUE
		return FALSE
	return target.density

/mob/living/proc/handle_cy_sprint_collision(direction)
	if(!cy_sprinting || !direction || body_position != STANDING_UP || stat != CONSCIOUS)
		return FALSE
	var/turf/collision_turf = get_step(src, direction)
	if(!is_cy_sprint_collision_surface(collision_turf))
		return FALSE
	set_cy_sprint_enabled(FALSE)
	adjust_stamina_loss(CY_SPRINT_STAMINA_COST_PER_STEP * 3, updating_stamina = FALSE, forced = TRUE)
	Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
	visible_message(span_warning("[src] на бегу врезается в препятствие и падает!"), span_userdanger("Вы на бегу врезаетесь в препятствие и падаете!"))
	return TRUE

/atom/movable/cy_look_holder
	invisibility = INVISIBILITY_MAXIMUM
	var/mob/living/owner

/atom/movable/cy_look_holder/Initialize(mapload, mob/living/owner)
	. = ..()
	src.owner = owner
	if(owner)
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(owner_moved))

/atom/movable/cy_look_holder/Destroy()
	if(owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	owner = null
	return ..()

/atom/movable/cy_look_holder/proc/owner_moved(mob/living/source, atom/oldloc, direction, Forced, old_locs)
	SIGNAL_HANDLER
	if(owner)
		owner.end_cy_look_mode(TRUE)

/mob/living/proc/get_cy_action_delay(base_delay = CY_BASE_ACTION_DELAY, skill_type = null)
	var/delay = base_delay
	if(skill_type)
		delay *= get_cy_skill_speed_multiplier(skill_type)
	var/dexterity = get_cy_stat(/datum/cy_stat/dexterity)
	delay *= max(0.45, 1 - max(0, dexterity - CY_STAT_DEFAULT) * 0.02)
	return max(1, round(delay))

/mob/living/proc/apply_cy_action_delay(base_delay = CY_BASE_ACTION_DELAY, skill_type = null)
	changeNext_move(get_cy_action_delay(base_delay, skill_type))
	return TRUE

/mob/living/proc/is_cy_click_held(list/modifiers)
	if(!client?.cy_mouse_down_time)
		return FALSE
	return world.time - client.cy_mouse_down_time >= CY_CLICK_HOLD_THRESHOLD


/mob/living/proc/set_cy_parkour_mode(enabled)
	if(enabled)
		if(stat != CONSCIOUS || body_position != STANDING_UP)
			to_chat(src, span_warning("Сейчас вы не можете заняться паркуром."))
			return FALSE
		cy_parkour_mode = TRUE
		cy_parkour_expires_at = world.time + CY_PARKOUR_MODE_TIMEOUT
		to_chat(src, span_notice("Вы готовитесь к паркурному движению."))
		return TRUE
	cy_parkour_mode = FALSE
	cy_parkour_expires_at = 0
	return TRUE

/mob/living/proc/toggle_cy_parkour_mode()
	return set_cy_parkour_mode(!cy_parkour_mode)

/mob/living/proc/has_cy_parkour_mode()
	if(!cy_parkour_mode)
		return FALSE
	if(world.time > cy_parkour_expires_at)
		set_cy_parkour_mode(FALSE)
		return FALSE
	return TRUE

/mob/living/proc/consume_cy_parkour_mode()
	if(cy_parkour_mode)
		set_cy_parkour_mode(FALSE)
	return TRUE

/mob/living/proc/is_cy_climb_surface(atom/target)
	if(!target || is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/movable_content as anything in target_turf)
			if(movable_content.density && (isstructure(movable_content) || isobj(movable_content)))
				return TRUE
		return FALSE
	return target.density || isstructure(target)

/mob/living/proc/get_cy_parkour_dir(atom/target)
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return NONE
	return get_dir(my_turf, target_turf)

/mob/living/proc/clear_cy_wall_hang(animate_offset = TRUE)
	if(!cy_wall_hanging)
		return FALSE
	cy_wall_hanging = FALSE
	cy_wall_hanging_dir = NONE
	cy_wall_hanging_surface = null
	remove_offsets(CY_PARKOUR_HANG_OFFSET_SOURCE, animate = animate_offset)
	return TRUE

/mob/living/proc/start_cy_wall_hang(atom/surface, jump_to_surface = FALSE)
	if(!surface || !is_cy_climb_surface(surface))
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/surface_turf = get_turf(surface)
	if(!my_turf || !surface_turf || get_dist(my_turf, surface_turf) > 1)
		return FALSE
	var/hang_dir = get_dir(my_turf, surface_turf)
	if(!hang_dir)
		return FALSE
	clear_cy_wall_press(FALSE)
	clear_cy_hide_under()
	clear_cy_wall_hang(FALSE)
	cy_wall_hanging = TRUE
	cy_wall_hanging_dir = hang_dir
	cy_wall_hanging_surface = surface
	var/x_offset = 0
	var/y_offset = 0
	if(hang_dir & EAST)
		x_offset += CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & WEST)
		x_offset -= CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & NORTH)
		y_offset += CY_PARKOUR_HANG_PIXEL_OFFSET
	if(hang_dir & SOUTH)
		y_offset -= CY_PARKOUR_HANG_PIXEL_OFFSET
	add_offsets(CY_PARKOUR_HANG_OFFSET_SOURCE, null, x_offset, y_offset, null, animate = FALSE)
	adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
	visible_message(span_notice("[src] цепляется за поверхность."), span_notice("Вы цепляетесь за поверхность."))
	if(jump_to_surface && looking_vertically == UP)
		addtimer(CALLBACK(src, PROC_REF(perform_cy_parkour_climb_up)), 2)
	return TRUE

/mob/living/proc/get_cy_parkour_landing_turf(atom/target, distance = 1)
	var/turf/my_turf = get_turf(src)
	if(!my_turf)
		return null
	var/jump_dir = target ? get_dir(my_turf, get_turf(target)) : dir
	if(!jump_dir)
		jump_dir = dir
	var/turf/landing = get_ranged_target_turf(my_turf, jump_dir, distance)
	if(!landing)
		return null
	if(landing.density)
		return null
	for(var/atom/movable/blocker as anything in landing)
		if(blocker == src)
			continue
		if(blocker.density)
			return null
	return landing

/mob/living/proc/perform_cy_parkour_jump(atom/target)
	if(stat != CONSCIOUS || body_position != STANDING_UP)
		return FALSE
	var/jump_distance = cy_sprinting ? 2 : 1
	if(HAS_TRAIT(src, TRAIT_CY_ACROBATICS_4))
		jump_distance++
	if(HAS_TRAIT(src, TRAIT_CY_ATHLETICS_6))
		jump_distance++
	var/turf/landing = get_cy_parkour_landing_turf(target, jump_distance)
	if(!landing)
		to_chat(src, span_warning("Вы не видите подходящего места для прыжка."))
		return TRUE
	var/stamina_cost = CY_PARKOUR_JUMP_STAMINA_COST * jump_distance
	if(HAS_TRAIT(src, TRAIT_CY_SPIRIT_ENDURANCE_2))
		stamina_cost *= 0.8
	adjust_stamina_loss(stamina_cost, updating_stamina = FALSE, forced = TRUE)
	visible_message(span_notice("[src] прыгает вперёд."), span_notice("Вы прыгаете вперёд."))
	forceMove(landing)
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_z_jump(atom/target, direction = UP)
	if(stat != CONSCIOUS)
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/success = zMove(direction, target_turf, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(success)
		adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
		return TRUE
	to_chat(src, span_warning("Вы не находите удобного пути."))
	return TRUE

/mob/living/proc/perform_cy_parkour_climb_up()
	if(!cy_wall_hanging)
		return FALSE
	var/result = zMove(UP, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(result)
		visible_message(span_notice("[src] подтягивается наверх."), span_notice("Вы подтягиваетесь наверх."))
		adjust_stamina_loss(CY_PARKOUR_CLIMB_STAMINA_COST, updating_stamina = FALSE, forced = TRUE)
		clear_cy_wall_hang(FALSE)
	else
		to_chat(src, span_warning("Вы не можете подняться выше."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_descend(safe = TRUE)
	if(!cy_wall_hanging && looking_vertically != DOWN)
		return FALSE
	var/result = zMove(DOWN, z_move_flags = ZMOVE_FLIGHT_FLAGS|ZMOVE_FEEDBACK)
	if(result)
		if(safe)
			visible_message(span_notice("[src] аккуратно спускается вниз."), span_notice("Вы аккуратно спускаетесь вниз."))
		else
			visible_message(span_notice("[src] скользит вниз по поверхности."), span_notice("Вы скользите вниз по поверхности."))
			if(prob(CY_PARKOUR_SLIDE_FALL_CHANCE))
				Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
		adjust_stamina_loss(max(1, round(CY_PARKOUR_CLIMB_STAMINA_COST * 0.5)), updating_stamina = FALSE, forced = TRUE)
		clear_cy_wall_hang(FALSE)
	else
		if(!safe && prob(CY_PARKOUR_SLIDE_FALL_CHANCE))
			Knockdown(2 SECONDS, daze_amount = 1 SECONDS)
		to_chat(src, span_warning("Спускаться здесь некуда."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/acrobatics)
	return TRUE

/mob/living/proc/perform_cy_parkour_transfer(atom/target)
	if(!cy_wall_hanging || !is_cy_climb_surface(target))
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf || get_dist(my_turf, target_turf) > 1)
		return FALSE
	return start_cy_wall_hang(target, FALSE)

/mob/living/proc/handle_cy_parkour_click(atom/target, list/modifiers)
	if(!target || !islist(modifiers))
		return FALSE
	var/parkour_ready = has_cy_parkour_mode()
	if(!parkour_ready && !cy_wall_hanging)
		return FALSE
	var/is_right = cy_has_click_modifier(modifiers, RIGHT_CLICK)
	var/is_middle = cy_has_click_modifier(modifiers, MIDDLE_CLICK)
	if(cy_wall_hanging)
		if(is_right)
			consume_cy_parkour_mode()
			return perform_cy_parkour_descend(TRUE)
		if(looking_vertically == DOWN && !is_middle)
			consume_cy_parkour_mode()
			return perform_cy_parkour_descend(FALSE)
		if(target == src && !is_middle)
			consume_cy_parkour_mode()
			return perform_cy_parkour_climb_up()
		if(!is_middle && perform_cy_parkour_transfer(target))
			consume_cy_parkour_mode()
			return TRUE
	if(!parkour_ready)
		return FALSE
	consume_cy_parkour_mode()
	if(looking_vertically == DOWN)
		if(is_right)
			return perform_cy_parkour_descend(TRUE)
		return perform_cy_parkour_descend(FALSE)
	if(is_middle)
		if(looking_vertically == UP)
			return perform_cy_parkour_z_jump(target, UP)
		return perform_cy_parkour_jump(target)
	if(!is_right && is_cy_climb_surface(target))
		if(looking_vertically == UP)
			if(start_cy_wall_hang(target, TRUE))
				return TRUE
			return perform_cy_parkour_z_jump(target, UP)
		return start_cy_wall_hang(target, FALSE)
	return FALSE

/mob/living/proc/prepare_cy_combat_intent(atom/target, list/modifiers)
	if(!combat_mode || !islist(modifiers))
		return FALSE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && pulling == target && grab_state < GRAB_NECK)
		return perform_cy_grab_zone_special(target)
	if(cy_has_click_modifier(modifiers, ALT_CLICK))
		modifiers -= ALT_CLICK
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			modifiers[CY_ATTACK_INTENT] = CY_ATTACK_INTENT_PREEMPTIVE
		else
			modifiers[CY_ATTACK_INTENT] = CY_ATTACK_INTENT_TRICKY
		cy_current_attack_intent = modifiers[CY_ATTACK_INTENT]
		return TRUE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
		modifiers[CY_ATTACK_INTENT] = is_cy_click_held(modifiers) ? CY_ATTACK_INTENT_PIERCE : CY_ATTACK_INTENT_STAB
	else
		modifiers[CY_ATTACK_INTENT] = is_cy_click_held(modifiers) ? CY_ATTACK_INTENT_CHOP : CY_ATTACK_INTENT_SLASH
	cy_current_attack_intent = modifiers[CY_ATTACK_INTENT]
	return TRUE


/mob/living/proc/apply_cy_attack_intent_modifiers(obj/item/weapon, list/modifiers, list/attack_modifiers)
	if(!islist(modifiers))
		return FALSE
	var/intent = LAZYACCESS(modifiers, CY_ATTACK_INTENT)
	if(!intent)
		return FALSE
	cy_current_attack_intent = intent
	if(!islist(attack_modifiers))
		return FALSE
	attack_modifiers[CY_ATTACK_INTENT] = intent
	switch(intent)
		if(CY_ATTACK_INTENT_TRICKY)
			attack_modifiers["cy_dodge_break"] = TRUE
		if(CY_ATTACK_INTENT_PREEMPTIVE)
			attack_modifiers["cy_parry_break"] = TRUE
	return TRUE

/mob/living/proc/handle_cy_control_click(atom/target, list/modifiers, params)
	if(!target || !islist(modifiers))
		return FALSE
	if(handle_cy_parkour_click(target, modifiers))
		return TRUE
	if(!combat_mode && cy_has_click_modifier(modifiers, RIGHT_CLICK) && !cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK) && !cy_has_click_modifier(modifiers, MIDDLE_CLICK) && is_cy_click_held(modifiers) && isliving(target) && get_active_held_item())
		give(target)
		return TRUE
	if(combat_mode && cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && !get_active_held_item())
		var/mob/living/running_target = target
		if(running_target.cy_wrestling_running)
			return perform_cy_wrestling_elbow(running_target)
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && pulling && ismob(pulling) && pulling != target && grab_state >= GRAB_AGGRESSIVE && is_cy_grabbing_arm_zone())
		return perform_cy_wrestling_launch(target)
	if(ismob(target) && pulling == target && grab_state >= GRAB_NECK)
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			return perform_cy_carry_knee_strike(target)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			return perform_cy_neck_back_throw(target)
		if(!cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK))
			return perform_cy_neck_choke(target)
	if(combat_mode && ismob(target) && can_perform_cy_carry_combat_action(target))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			return perform_cy_carry_knee_strike(target)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			return perform_cy_carry_back_slam(target)
		if(!cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK))
			return perform_cy_carry_floor_slam(target)
	if(cy_defense_hold)
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			perform_cy_defense_action(CY_DEFENSE_ACTION_DODGE, target)
			return TRUE
		if(!cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			perform_cy_defense_action(CY_DEFENSE_ACTION_PARRY, target)
			return TRUE
	if(cy_has_click_modifier(modifiers, CTRL_CLICK))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			pointed(target)
			return TRUE
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			if(combat_mode)
				if(perform_cy_uppercut(target))
					return TRUE
				perform_cy_kick(target)
			else
				perform_cy_shove(target)
			return TRUE
	if(cy_has_click_modifier(modifiers, SHIFT_CLICK))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			if(target == src)
				return TRUE // MouseUp decides between quick raise-head and held listening.
			if(ismob(target))
				toggle_cy_listen_mode(TRUE)
			else
				start_cy_look_at(target)
			return TRUE
	if(cy_has_click_modifier(modifiers, RIGHT_CLICK) && ismob(target) && pulling == target && grab_state < GRAB_NECK)
		return perform_cy_grab_zone_special(target)
	if(cy_has_click_modifier(modifiers, ALT_CLICK))
		if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
			try_open_loot_panel_on(target)
			return TRUE
		if(combat_mode)
			prepare_cy_combat_intent(target, modifiers)
			return FALSE
		if(cy_has_click_modifier(modifiers, RIGHT_CLICK))
			perform_cy_additional_secondary_action(target)
			return TRUE
		perform_cy_additional_primary_action(target)
		return TRUE
	if(cy_has_click_modifier(modifiers, MIDDLE_CLICK))
		activate_selected_cy_daemon(target)
		return TRUE
	if(!combat_mode && ismob(target) && pulling == target && !cy_has_click_modifier(modifiers, CTRL_CLICK) && !cy_has_click_modifier(modifiers, SHIFT_CLICK) && !cy_has_click_modifier(modifiers, ALT_CLICK) && !cy_has_click_modifier(modifiers, RIGHT_CLICK) && !cy_has_click_modifier(modifiers, MIDDLE_CLICK))
		return perform_cy_grab_palpation(target)
	prepare_cy_combat_intent(target, modifiers)
	return FALSE

/mob/living/proc/perform_cy_raise_head()
	if(next_move > world.time)
		return FALSE
	to_chat(src, span_notice("Вы поднимаете голову и осматриваетесь."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/perform_cy_look_down_hint(atom/target)
	if(next_move > world.time)
		return FALSE
	to_chat(src, span_notice("Вы пытаетесь посмотреть вниз."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/perform_cy_additional_primary_action(atom/target)
	if(!target)
		return FALSE
	to_chat(src, span_notice("Вы пробуете дополнительное действие с [target.declent_ru(INSTRUMENTAL)]."))
	apply_cy_action_delay(CLICK_CD_MELEE, null)
	return TRUE

/mob/living/proc/perform_cy_additional_secondary_action(atom/target)
	if(!target)
		return FALSE
	to_chat(src, span_notice("Вы пробуете вторичное дополнительное действие с [target.declent_ru(INSTRUMENTAL)]."))
	apply_cy_action_delay(CLICK_CD_MELEE, null)
	return TRUE

/mob/living/proc/perform_cy_grab_palpation(mob/living/target)
	if(!target || pulling != target || combat_mode || next_move > world.time)
		return FALSE
	if(!ishuman(target))
		to_chat(src, span_notice("You feel over [target], but learn nothing useful."))
		apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/professional/medicine)
		return TRUE
	var/mob/living/carbon/human/human_target = target
	visible_message(span_notice("[src] carefully checks [human_target] by touch."), span_notice("You palpate [human_target], checking for injuries."))
	var/list/diagnostic_lines = human_target.get_cy_diagnostic_lines(src, HAS_TRAIT(src, TRAIT_CY_MEDICINE_4))
	for(var/line in diagnostic_lines)
		to_chat(src, span_notice("[line]"))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/professional/medicine)
	return TRUE

/mob/living/proc/activate_selected_cy_daemon(atom/target)
	if(next_move > world.time)
		return FALSE
	if(!target)
		return FALSE
	var/datum/cy_demon/demon = cy_prepared_demon
	if(!demon)
		to_chat(src, span_warning("Prepare a demon ability first."))
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = cy_prepared_demon_deck || cy_get_active_cyberdeck()
	if(!deck || QDELETED(deck) || cy_get_active_cyberdeck() != deck)
		to_chat(src, span_warning("You need the cyberdeck that prepared [demon.name]."))
		cy_clear_prepared_demon()
		return FALSE
	if(!(demon in deck.stored_demons))
		to_chat(src, span_warning("[demon.name] is no longer loaded in [deck]."))
		cy_clear_prepared_demon()
		return FALSE
	if(!cy_can_use_demon_on(target, demon))
		return FALSE
	if(!demon.start_cast(src, target, src))
		return FALSE
	cy_prepared_demon_action?.StartCooldown(demon.cooldown_time)
	cy_clear_prepared_demon()
	apply_cy_action_delay(CLICK_CD_CLICK_ABILITY, /datum/cy_skill/intelligence/fast_code)
	return TRUE


/mob/living/proc/get_cy_shove_target_turf(atom/movable/target, distance = 1)
	if(!target)
		return null
	var/turf/current_turf = get_turf(target)
	if(!current_turf)
		return null
	var/shove_dir = get_dir(src, target)
	if(!shove_dir)
		shove_dir = dir || SOUTH
	var/turf/next_turf = current_turf
	for(var/i in 1 to max(1, distance))
		var/turf/candidate = get_step(next_turf, shove_dir)
		if(!candidate || candidate.density)
			break
		next_turf = candidate
	return next_turf

/mob/living/proc/try_cy_shove_movable(atom/movable/target, distance = 1, kick = FALSE)
	if(!target || target == src || !Adjacent(target) || target.anchored)
		return FALSE
	var/turf/target_turf = get_cy_shove_target_turf(target, distance)
	if(!target_turf || target_turf == get_turf(target))
		return FALSE
	face_atom(target)
	var/move_dir = get_dir(get_turf(target), target_turf)
	if(!target.Move(target_turf, move_dir))
		return FALSE
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] [kick ? "пинает" : "толкает"] [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы [kick ? "пинаете" : "толкаете"] [target.declent_ru(ACCUSATIVE)]."))
	return TRUE

/mob/living/proc/perform_cy_shove(atom/target)
	if(next_move > world.time)
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(!Adjacent(living_target))
			return FALSE
		disarm(living_target, null)
		if(HAS_TRAIT(src, TRAIT_CY_GRAPPLING_4))
			living_target.Knockdown(1 SECONDS + get_cy_skill_perk_level(/datum/cy_skill/strength/grappling) * 0.25 SECONDS, daze_amount = 0.5 SECONDS)
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/grappling)
		return TRUE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		if(try_cy_shove_movable(movable_target, 1, FALSE))
			apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/grappling)
			return TRUE
	return FALSE

/mob/living/proc/perform_cy_kick(atom/target)
	if(next_move > world.time)
		return FALSE
	if(!target || !Adjacent(target))
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		face_atom(living_target)
		do_attack_animation(living_target, ATTACK_EFFECT_KICK)
		living_target.adjust_stamina_loss(CY_KICK_STAMINA_DAMAGE)
		if(living_target.body_position == LYING_DOWN)
			living_target.apply_damage(CY_KICK_PRONE_BRUTE_DAMAGE, BRUTE)
		else
			living_target.throw_at(get_cy_shove_target_turf(living_target, CY_KICK_SHOVE_DISTANCE), CY_KICK_SHOVE_DISTANCE, 1, src, force = MOVE_FORCE_OVERPOWERING)
		var/kick_knockdown_chance = 25 + get_cy_skill_perk_level(/datum/cy_skill/dexterity/fast_melee) * 5
		if(prob(kick_knockdown_chance))
			living_target.Knockdown(CY_KICK_KNOCKDOWN_TIME)
		adjust_staggered_up_to(CY_KICK_SELF_STAGGER, 10 SECONDS)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пинает [living_target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы пинаете [living_target.declent_ru(ACCUSATIVE)]."))
		log_combat(src, living_target, "kicked")
		apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
		return TRUE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		if(try_cy_shove_movable(movable_target, CY_KICK_SHOVE_DISTANCE, TRUE))
			adjust_staggered_up_to(CY_KICK_SELF_STAGGER, 10 SECONDS)
			apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
			return TRUE
	return FALSE

/mob/living/proc/perform_cy_uppercut(atom/target)
	if(next_move > world.time || !isliving(target) || get_active_held_item())
		return FALSE
	var/mob/living/living_target = target
	if(!Adjacent(living_target) || !HAS_TRAIT(src, TRAIT_CY_POWER_MELEE_6))
		return FALSE
	face_atom(living_target)
	do_attack_animation(living_target, ATTACK_EFFECT_PUNCH)
	var/damage = 8 + get_cy_skill_perk_level(/datum/cy_skill/strength/power_melee) * 2
	living_target.apply_damage(damage, BRUTE, BODY_ZONE_HEAD)
	living_target.adjust_stamina_loss(20 + get_cy_skill_perk_level(/datum/cy_skill/strength/power_melee) * 5)
	living_target.Knockdown(3 SECONDS, daze_amount = 1.5 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] бьёт [living_target.declent_ru(ACCUSATIVE)] апперкотом!"), span_notice("Вы проводите апперкот по [living_target.declent_ru(DATIVE)]."))
	log_combat(src, living_target, "cyberpunk uppercut")
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/strength/power_melee)
	return TRUE

/mob/living/proc/apply_cy_open_defense(duration = CY_DEFENSE_OPEN_TIME)
	cy_open_defense_until = max(cy_open_defense_until, world.time + duration)
	return TRUE

/mob/living/proc/apply_cy_parry_resist(duration = CY_PARRY_SUCCESS_RESIST_TIME)
	cy_parry_resist_until = max(cy_parry_resist_until, world.time + duration)
	return TRUE

/mob/living/proc/get_cy_defense_success_chance(defense_action = null)
	var/chance = CY_DEFENSE_BASE_SUCCESS_CHANCE
	if(defense_action == CY_DEFENSE_ACTION_DODGE)
		chance += get_cy_skill_perk_level(/datum/cy_skill/dexterity/evasion) * CY_DODGE_PERK_SUCCESS_BONUS
		if(HAS_TRAIT(src, TRAIT_CY_EVASION_3))
			chance += 15
	else if(defense_action == CY_DEFENSE_ACTION_PARRY)
		chance += get_cy_skill_perk_level(/datum/cy_skill/perception/concentration) * CY_PARRY_PERK_SUCCESS_BONUS
		if(HAS_TRAIT(src, TRAIT_CY_CONCENTRATION_2))
			chance += 15
		if(!HAS_TRAIT(src, TRAIT_CY_CONCENTRATION_1))
			chance -= 10
	return clamp(chance, 1, 95)

/mob/living/proc/clear_cy_active_defense(trigger_cooldown = TRUE)
	cy_active_defense_action = null
	cy_active_defense_until = 0
	if(trigger_cooldown)
		cy_next_defense_time = max(cy_next_defense_time, world.time + CY_DEFENSE_TRIGGERED_COOLDOWN)
	return TRUE

/mob/living/proc/get_cy_current_attack_intent()
	return cy_current_attack_intent

/mob/living/proc/get_cy_dodge_turf(atom/attacker)
	var/list/candidates = list()
	var/away_dir = attacker ? get_dir(attacker, src) : dir
	if(away_dir)
		candidates += get_step(src, away_dir)
		candidates += get_step(src, turn(away_dir, 90))
		candidates += get_step(src, turn(away_dir, -90))
	for(var/turf/candidate as anything in candidates)
		if(!candidate || candidate.density)
			continue
		var/blocked = FALSE
		for(var/atom/movable/movable_content as anything in candidate)
			if(movable_content.density)
				blocked = TRUE
				break
		if(!blocked)
			return candidate
	return null

/mob/living/proc/resolve_cy_active_defense(atom/hit_by, attack_type = MELEE_ATTACK)
	if(!has_active_cy_defense())
		return FAILED_BLOCK
	if(body_position == LYING_DOWN && prob(50))
		clear_cy_active_defense(TRUE)
		return FAILED_BLOCK
	var/mob/living/attacker = isliving(hit_by) ? hit_by : null
	var/attacker_intent = attacker?.get_cy_current_attack_intent()
	var/bypass_chance = 0
	if(attacker)
		bypass_chance = attacker.get_cy_weapon_defense_bypass_bonus(attacker.get_active_held_item())
	if(bypass_chance && prob(bypass_chance))
		clear_cy_active_defense(TRUE)
		return FAILED_BLOCK
	if(cy_active_defense_action == CY_DEFENSE_ACTION_DODGE)
		if(attacker_intent == CY_ATTACK_INTENT_TRICKY)
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(!prob(get_cy_defense_success_chance(CY_DEFENSE_ACTION_DODGE)))
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		var/atom/dodge_source = attacker ? attacker : hit_by
		var/turf/dodge_turf = get_cy_dodge_turf(dodge_source)
		if(dodge_turf && !HAS_TRAIT(src, TRAIT_CY_EVASION_5))
			Move(dodge_turf, get_dir(src, dodge_turf))
		attacker?.apply_cy_open_defense()
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] уходит от атаки."), span_notice("Вы уходите от атаки."))
		clear_cy_active_defense(TRUE)
		if(attacker && HAS_TRAIT(src, TRAIT_CY_FAST_MELEE_4) && prob(25))
			perform_cy_kick(attacker)
		if(!HAS_TRAIT(src, TRAIT_CY_EVASION_1) && prob(10))
			Knockdown(1 SECONDS)
		return SUCCESSFUL_BLOCK
	if(cy_active_defense_action == CY_DEFENSE_ACTION_PARRY)
		if(attacker_intent == CY_ATTACK_INTENT_PREEMPTIVE)
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(attacker && HAS_TRAIT(attacker, TRAIT_CY_HEAVY_WEAPONS_3) && attacker.get_active_held_item() && prob(20))
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(!HAS_TRAIT(src, TRAIT_CY_CONCENTRATION_1) && prob(10))
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(!prob(get_cy_defense_success_chance(CY_DEFENSE_ACTION_PARRY)))
			clear_cy_active_defense(TRUE)
			return FAILED_BLOCK
		if(attacker && HAS_TRAIT(src, TRAIT_CY_CONCENTRATION_5) && prob(40))
			attacker.apply_cy_open_defense()
		visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] парирует атаку."), span_notice("Вы парируете атаку."))
		apply_cy_parry_resist()
		clear_cy_active_defense(TRUE)
		if(attacker && HAS_TRAIT(src, TRAIT_CY_FAST_MELEE_4) && prob(25))
			perform_cy_kick(attacker)
		return SUCCESSFUL_BLOCK
	return FAILED_BLOCK

/mob/living/proc/perform_cy_defense_action(defense_action = null, atom/target = null)
	if(cy_carrying_in_arms)
		to_chat(src, span_warning("Вы не можете защищаться, пока несёте кого-то на руках."))
		return FALSE
	if(next_move > world.time || world.time < cy_next_defense_time)
		return FALSE
	if(!defense_action)
		defense_action = cy_last_defense_action || CY_DEFENSE_ACTION_DODGE
	cy_last_defense_action = defense_action
	cy_active_defense_action = defense_action
	var/defense_skill = defense_action == CY_DEFENSE_ACTION_DODGE ? /datum/cy_skill/dexterity/evasion : /datum/cy_skill/perception/concentration
	var/skill_window_bonus = get_cy_skill_perk_level(defense_skill) * 0.05 SECONDS
	if(body_position == LYING_DOWN)
		skill_window_bonus *= 0.5
	cy_active_defense_until = world.time + CY_DEFENSE_WINDOW + skill_window_bonus
	cy_next_defense_time = world.time + get_cy_action_delay(CY_DEFENSE_BASE_COOLDOWN, defense_skill)
	if(target)
		face_atom(target)
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] готовится к [defense_action == CY_DEFENSE_ACTION_PARRY ? "парированию" : "уклонению"]."), span_notice("Вы готовитесь к [defense_action == CY_DEFENSE_ACTION_PARRY ? "парированию" : "уклонению"]."))
	return TRUE

/mob/living/proc/has_active_cy_defense(defense_action = null)
	if(world.time > cy_active_defense_until)
		cy_active_defense_action = null
		return FALSE
	if(defense_action && cy_active_defense_action != defense_action)
		return FALSE
	return !!cy_active_defense_action


/mob/living/proc/start_cy_look_at(atom/target)
	if(!target || !client)
		return FALSE
	var/turf/source_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!source_turf || !target_turf)
		return FALSE
	var/range = CY_LOOK_BASE_RANGE + round(max(0, get_cy_stat(/datum/cy_stat/perception) - CY_STAT_DEFAULT) * CY_LOOK_RANGE_PER_PERCEPTION)
	var/dx = clamp(target_turf.x - source_turf.x, -range, range)
	var/dy = clamp(target_turf.y - source_turf.y, -range, range)
	QDEL_NULL(cy_look_holder)
	cy_look_holder = new(source_turf, src)
	set_cy_look_mode(TRUE)
	animate(client, pixel_x = dx * CY_LOOK_TILE_PIXEL_OFFSET, pixel_y = dy * CY_LOOK_TILE_PIXEL_OFFSET, time = CY_LOOK_CAMERA_RETURN_TIME)
	apply_cy_action_delay(CLICK_CD_LOOK_UP, /datum/cy_skill/perception/concentration)
	return TRUE

/mob/living/proc/end_cy_look_mode(smooth = TRUE)
	set_cy_look_mode(FALSE)
	if(!client)
		QDEL_NULL(cy_look_holder)
		return FALSE
	if(smooth)
		animate(client, pixel_x = 0, pixel_y = 0, time = CY_LOOK_CAMERA_RETURN_TIME)
		addtimer(CALLBACK(src, PROC_REF(finish_cy_look_mode)), CY_LOOK_CAMERA_RETURN_TIME)
		return TRUE
	finish_cy_look_mode()
	return TRUE

/mob/living/proc/finish_cy_look_mode()
	if(client)
		client.pixel_x = initial(client.pixel_x)
		client.pixel_y = initial(client.pixel_y)
	QDEL_NULL(cy_look_holder)
	return TRUE

/mob/living/proc/do_cy_sit()
	set_resting(TRUE)
	return TRUE


/mob/living/proc/is_cy_wall_press_surface(atom/target)
	if(!target || is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_turf = target
		if(target_turf.density)
			return TRUE
		for(var/atom/movable/movable_content as anything in target_turf)
			if(movable_content.density && (isstructure(movable_content) || isobj(movable_content)))
				return TRUE
		return FALSE
	return target.density || isstructure(target)

/mob/living/proc/clear_cy_wall_press(animate_offset = TRUE)
	if(!cy_wall_pressed)
		return FALSE
	cy_wall_pressed = FALSE
	cy_wall_press_dir = NONE
	remove_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, animate = animate_offset)
	update_cy_chameleon()
	return TRUE

/mob/living/proc/refresh_cy_wall_press_after_move()
	if(!cy_wall_pressed)
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf || !cy_wall_press_dir)
		return clear_cy_wall_press(TRUE)
	var/turf/wall_turf = get_step(current_turf, cy_wall_press_dir)
	if(!wall_turf || !Adjacent(wall_turf) || !is_cy_wall_press_surface(wall_turf))
		return clear_cy_wall_press(TRUE)
	return TRUE

/mob/living/proc/cy_press_to_wall(atom/target)
	if(!target)
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf || !Adjacent(target_turf))
		return FALSE
	if(is_cy_furniture_surface(target))
		return FALSE
	if(isturf(target))
		var/turf/target_wall_turf = target
		if(!target_wall_turf.density)
			return FALSE
	else if(!target.density && !isstructure(target))
		return FALSE
	var/press_dir = get_dir(my_turf, target_turf)
	if(!press_dir)
		return FALSE
	clear_cy_hide_under()
	cy_wall_pressed = TRUE
	cy_wall_press_dir = press_dir
	var/x_offset = 0
	var/y_offset = 0
	if(press_dir & EAST)
		x_offset += CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & WEST)
		x_offset -= CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & NORTH)
		y_offset += CY_STEALTH_WALL_PIXEL_OFFSET
	if(press_dir & SOUTH)
		y_offset -= CY_STEALTH_WALL_PIXEL_OFFSET
	add_offsets(CY_STEALTH_WALL_OFFSET_SOURCE, null, x_offset, y_offset, null, animate = FALSE)
	update_cy_chameleon()
	to_chat(src, span_notice("Вы вжимаетесь в укрытие."))
	return TRUE


/mob/living/proc/handle_cy_mouse_drop(atom/dropped, atom/over, list/modifiers)
	if(!dropped || !over || !islist(modifiers))
		return FALSE
	var/is_right = cy_has_click_modifier(modifiers, RIGHT_CLICK)
	var/is_middle = cy_has_click_modifier(modifiers, MIDDLE_CLICK)
	if(dropped == src && over == src)
		if(is_middle)
			return perform_cy_erp_self()
		if(is_right)
			to_chat(src, span_notice("Вы просите понести вас."))
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] просит понести [ru_p_them()]."), ignored_mobs = list(src))
			return TRUE
		return do_cy_sit()
	if(dropped == src && ismob(over))
		var/mob/living/carbon/human/carrier = null
		if(ishuman(over))
			carrier = over
		if(is_right)
			to_chat(src, span_notice("Вы просите [over.declent_ru(ACCUSATIVE)] понести вас."))
			to_chat(over, span_notice("[capitalize(declent_ru(NOMINATIVE))] просит вас понести [ru_p_them()]."))
			return TRUE
		if(carrier && carrier.pulling == src && carrier.grab_state >= GRAB_AGGRESSIVE)
			carrier.piggyback(src)
			return TRUE
	if(dropped == src && !ismob(over) && !(istype(over, /obj/vehicle/sealed/car)))
		if(is_cy_furniture_surface(over))
			if(cy_stealth_mode && body_position == LYING_DOWN)
				return perform_cy_hide_under(over)
			return FALSE
		return cy_press_to_wall(over)
	if(over == src && ismovable(dropped))
		var/atom/movable/movable_dropped = dropped
		if(is_middle)
			return FALSE
		if(is_right)
			if(ismob(dropped))
				to_chat(dropped, span_notice("[capitalize(declent_ru(NOMINATIVE))] предлагает вам взобраться на спину."))
			visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] предлагает понести [dropped.declent_ru(ACCUSATIVE)]."), span_notice("Вы предлагаете понести [dropped.declent_ru(ACCUSATIVE)]."))
			return TRUE
		if(ishuman(src) && iscarbon(dropped))
			var/mob/living/carbon/human/human_user = src
			var/mob/living/carbon/carbon_target = dropped
			if(carbon_target.body_position == LYING_DOWN && human_user.pulling == carbon_target && human_user.grab_state)
				if(human_user.grab_state >= GRAB_AGGRESSIVE)
					return human_user.cy_carry_in_arms(carbon_target)
				var/shoulder_result = human_user.fireman_carry(carbon_target)
				if(shoulder_result)
					human_user.cy_carrying_on_shoulder = TRUE
					human_user.add_movespeed_modifier(/datum/movespeed_modifier/cy_shoulder_carry)
				return TRUE
			return FALSE
		if(isliving(dropped))
			return FALSE
		start_pulling(movable_dropped)
		return TRUE
	if((istype(over, /obj/structure/bed) || istype(over, /obj/structure/chair)) && ismob(dropped))
		return FALSE // Let the existing buckle mouse-drop machinery handle it.
	if(combat_mode && ismob(dropped) && (istype(over, /obj/structure/table) || istype(over, /obj/structure/chair) || istype(over, /obj/structure/bed)))
		var/mob/living/living_dropped = dropped
		living_dropped.Knockdown(2 SECONDS)
		living_dropped.forceMove(get_turf(over))
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] швыряет [living_dropped.declent_ru(ACCUSATIVE)] на [over.declent_ru(ACCUSATIVE)]!"), span_notice("Вы швыряете [living_dropped.declent_ru(ACCUSATIVE)] на [over.declent_ru(ACCUSATIVE)]."))
		log_combat(src, living_dropped, "threw into furniture", "[over]")
		apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
		return TRUE
	return FALSE


/mob/living/proc/cy_carry_in_arms(mob/living/carbon/target)
	return FALSE


/mob/living/carbon/human/cy_carry_in_arms(mob/living/carbon/target)
	if(!istype(target) || target.body_position != LYING_DOWN || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		return FALSE
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] начинает брать [target.declent_ru(ACCUSATIVE)] на руки..."), span_notice("Вы начинаете брать [target.declent_ru(ACCUSATIVE)] на руки..."))
	if(!do_after(src, 7 SECONDS, target))
		visible_message(span_warning("[capitalize(declent_ru(DATIVE))] не удается взять [target.declent_ru(ACCUSATIVE)] на руки!"))
		return FALSE
	if(target.body_position != LYING_DOWN || target.buckled || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		visible_message(span_warning("[capitalize(declent_ru(DATIVE))] не удается взять [target.declent_ru(ACCUSATIVE)] на руки!"))
		return FALSE
	if(!buckle_mob(target, TRUE, TRUE, CARRIER_NEEDS_ARM))
		return FALSE
	cy_carrying_in_arms = TRUE
	add_movespeed_modifier(/datum/movespeed_modifier/cy_arms_carry)
	return TRUE

/mob/living/proc/clear_cy_carry_state()
	cy_carrying_in_arms = FALSE
	cy_carrying_on_shoulder = FALSE
	remove_movespeed_modifier(/datum/movespeed_modifier/cy_arms_carry)
	remove_movespeed_modifier(/datum/movespeed_modifier/cy_shoulder_carry)
	return TRUE

/mob/living/proc/perform_cy_erp_self()
	to_chat(src, span_notice("Вы пытаетесь начать личное взаимодействие."))
	return TRUE

/mob/living/ShiftMiddleClickOn(atom/A)
	if(A == src)
		return TRUE // MouseUp handles quick raise-head versus held listening.
	if(ismob(A))
		toggle_cy_listen_mode(TRUE)
		return TRUE
	start_cy_look_at(A)
	return TRUE

/mob/living/proc/get_cy_controlled_mob(mob/living/target)
	if(!target)
		return null
	if(pulling == target && grab_state)
		return target
	if(target in buckled_mobs)
		return target
	return null

/mob/living/proc/can_perform_cy_carry_combat_action(mob/living/target)
	if(!target || INCAPACITATED_IGNORING(src, INCAPABLE_GRAB))
		return FALSE
	if(get_cy_controlled_mob(target) != target)
		return FALSE
	return cy_carrying_in_arms || cy_carrying_on_shoulder


/mob/living/proc/perform_cy_neck_choke(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_NECK)
		return FALSE
	target.apply_damage(14, OXY, BODY_ZONE_HEAD)
	target.apply_damage(8, BRUTE, BODY_ZONE_HEAD)
	target.adjust_confusion(2 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] душит [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы душите [target.declent_ru(ACCUSATIVE)]."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_floor_slam(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	target.Knockdown(3 SECONDS)
	target.apply_damage(18, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] бьёт [target.declent_ru(ACCUSATIVE)] об пол!"), span_notice("Вы бьёте [target.declent_ru(ACCUSATIVE)] об пол."))
	if(prob(35))
		stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_back_slam(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	var/turf/back_turf = get_step(src, turn(dir, 180))
	if(back_turf && !back_turf.density)
		target.forceMove(back_turf)
	target.Knockdown(4 SECONDS)
	target.apply_damage(22, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] обрушивает [target.declent_ru(ACCUSATIVE)] за собой!"), span_notice("Вы обрушиваете [target.declent_ru(ACCUSATIVE)] за собой."))
	stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_carry_knee_strike(mob/living/target)
	if(!can_perform_cy_carry_combat_action(target))
		return FALSE
	target.Knockdown(4 SECONDS)
	target.apply_damage(28, BRUTE, BODY_ZONE_CHEST)
	target.adjust_confusion(3 SECONDS)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пытается переломить [target.declent_ru(ACCUSATIVE)] через колено!"), span_notice("Вы бьёте [target.declent_ru(ACCUSATIVE)] позвоночником о колено."))
	if(prob(60))
		stop_pulling()
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/is_cy_furniture_surface(atom/target)
	return istype(target, /obj/structure/bed) || istype(target, /obj/structure/chair) || istype(target, /obj/structure/table)

/mob/living/proc/perform_cy_hide_under(atom/target)
	if(!target || !is_cy_furniture_surface(target))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || !Adjacent(target_turf))
		return FALSE
	cy_hidden_under = target
	if(!cy_hidden_old_layer)
		cy_hidden_old_layer = layer
	forceMove(target_turf)
	layer = min(layer, target.layer - 0.01)
	to_chat(src, span_notice("Вы забираетесь под [target.declent_ru(ACCUSATIVE)]."))
	update_cy_chameleon()
	return TRUE

/mob/living/proc/clear_cy_hide_under()
	if(!cy_hidden_under)
		return FALSE
	cy_hidden_under = null
	if(cy_hidden_old_layer)
		layer = cy_hidden_old_layer
	cy_hidden_old_layer = null
	update_cy_chameleon()
	return TRUE

/mob/living/proc/perform_cy_grab_zone_special(mob/living/target)
	if(!target || pulling != target || grab_state >= GRAB_NECK)
		return FALSE
	var/selected_zone = zone_selected
	switch(selected_zone)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			target.Knockdown(4 SECONDS)
			target.apply_damage(14, BRUTE, selected_zone)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] подсекает [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы подсекаете [target.declent_ru(ACCUSATIVE)]."))
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			if(iscarbon(target))
				var/mob/living/carbon/carbon_target = target
				carbon_target.drop_all_held_items()
			target.apply_damage(12, BRUTE, selected_zone)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] заламывает руку [target.declent_ru(GENITIVE)]!"), span_notice("Вы заламываете руку [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_HEAD)
			target.apply_damage(15, BRUTE, BODY_ZONE_HEAD)
			target.adjust_confusion(3 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] сжимает голову [target.declent_ru(GENITIVE)]!"), span_notice("Вы сжимаете голову [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_PRECISE_EYES)
			if(iscarbon(target))
				var/mob/living/carbon/eye_target = target
				eye_target.adjust_temp_blindness_up_to(5 SECONDS, 10 SECONDS)
			target.apply_damage(6, BRUTE, BODY_ZONE_HEAD)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] тычет в глаза [target.declent_ru(GENITIVE)]!"), span_notice("Вы тычете в глаза [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_PRECISE_MOUTH)
			if(iscarbon(target))
				var/mob/living/carbon/mouth_target = target
				mouth_target.adjust_stutter(10 SECONDS)
			target.apply_damage(6, BRUTE, BODY_ZONE_HEAD)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] грубо дёргает рот [target.declent_ru(GENITIVE)]!"), span_notice("Вы причиняете боль рту [target.declent_ru(GENITIVE)]."))
		if(BODY_ZONE_CHEST)
			if(target.body_position == LYING_DOWN)
				return cy_carry_in_arms(target)
			target.Knockdown(2 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] пытается поднять [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы пытаетесь поднять [target.declent_ru(ACCUSATIVE)]."))
		else
			target.apply_damage(8, BRUTE, selected_zone)
			target.adjust_confusion(2 SECONDS)
			visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] болезненно выкручивает [target.declent_ru(ACCUSATIVE)]!"), span_notice("Вы болезненно выкручиваете [target.declent_ru(ACCUSATIVE)]."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE


/mob/living/proc/is_cy_grabbing_arm_zone()
	return zone_selected in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)

/mob/living/proc/perform_cy_neck_back_throw(mob/living/target)
	if(!target || pulling != target || grab_state < GRAB_NECK)
		return FALSE
	var/turf/back_turf = get_step(src, turn(dir, 180))
	if(back_turf && !back_turf.density)
		target.forceMove(back_turf)
	target.Knockdown(4 SECONDS)
	target.apply_damage(20, BRUTE, BODY_ZONE_CHEST)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] перебрасывает [target.declent_ru(ACCUSATIVE)] себе за спину!"), span_notice("Вы перебрасываете [target.declent_ru(ACCUSATIVE)] себе за спину."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/perform_cy_wrestling_launch(atom/towards)
	var/mob/living/target = pulling
	if(!target || grab_state < GRAB_AGGRESSIVE || !is_cy_grabbing_arm_zone())
		return FALSE
	var/launch_dir = get_dir(src, towards)
	if(!launch_dir)
		launch_dir = dir
	if(!launch_dir)
		return FALSE
	stop_pulling()
	target.start_cy_wrestling_run(src, launch_dir)
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] рывком запускает [target.declent_ru(ACCUSATIVE)] вперёд!"), span_notice("Вы запускаете [target.declent_ru(ACCUSATIVE)] вперёд."))
	apply_cy_action_delay(CLICK_CD_GRABBING, /datum/cy_skill/strength/grappling)
	return TRUE

/mob/living/proc/start_cy_wrestling_run(mob/living/launcher, launch_dir)
	if(!launch_dir)
		return FALSE
	cy_wrestling_running = TRUE
	cy_wrestling_launcher = launcher
	cy_wrestling_run_dir = launch_dir
	cy_wrestling_run_steps_left = CY_WRESTLING_RUN_DISTANCE
	cy_wrestling_rebounded = FALSE
	cy_wrestling_start_health = health
	setDir(launch_dir)
	addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), 0)
	return TRUE

/mob/living/proc/clear_cy_wrestling_run(knock_down = FALSE)
	cy_wrestling_running = FALSE
	cy_wrestling_launcher = null
	cy_wrestling_run_dir = NONE
	cy_wrestling_run_steps_left = 0
	cy_wrestling_rebounded = FALSE
	cy_wrestling_start_health = 0
	if(knock_down)
		Knockdown(CY_WRESTLING_RUN_KNOCKDOWN_TIME)
	return TRUE

/mob/living/proc/process_cy_wrestling_run_step()
	if(!cy_wrestling_running || stat == DEAD || cy_wrestling_run_steps_left <= 0)
		clear_cy_wrestling_run(FALSE)
		return FALSE
	var/turf/next_turf = get_step(src, cy_wrestling_run_dir)
	var/damaged_during_launch = health < cy_wrestling_start_health
	if(!next_turf || next_turf.density || !Move(next_turf, cy_wrestling_run_dir))
		if(!cy_wrestling_rebounded && !damaged_during_launch)
			cy_wrestling_rebounded = TRUE
			cy_wrestling_run_dir = turn(cy_wrestling_run_dir, 180)
			setDir(cy_wrestling_run_dir)
			cy_wrestling_run_steps_left = CY_WRESTLING_RUN_DISTANCE
			addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), CY_WRESTLING_RUN_STEP_DELAY)
			return TRUE
		apply_damage(CY_WRESTLING_RUN_DAMAGE, BRUTE, BODY_ZONE_CHEST)
		visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] врезается в препятствие и падает!"), span_warning("Вы врезаетесь и падаете!"))
		clear_cy_wrestling_run(TRUE)
		return TRUE
	cy_wrestling_run_steps_left--
	addtimer(CALLBACK(src, PROC_REF(process_cy_wrestling_run_step)), CY_WRESTLING_RUN_STEP_DELAY)
	return TRUE

/mob/living/proc/perform_cy_wrestling_elbow(mob/living/target)
	if(!target?.cy_wrestling_running || get_active_held_item())
		return FALSE
	target.apply_damage(CY_WRESTLING_RUN_ELBOW_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	if(prob(CY_WRESTLING_RUN_ELBOW_KNOCKDOWN_CHANCE))
		target.clear_cy_wrestling_run(TRUE)
	else
		target.cy_wrestling_start_health = target.health + 1 // mark as damaged so collision will not rebound.
	visible_message(span_danger("[capitalize(declent_ru(NOMINATIVE))] встречает [target.declent_ru(ACCUSATIVE)] ударом локтя!"), span_notice("Вы встречаете [target.declent_ru(ACCUSATIVE)] ударом локтя."))
	apply_cy_action_delay(CLICK_CD_MELEE, /datum/cy_skill/dexterity/fast_melee)
	return TRUE

/mob/living/proc/get_cy_grab_offhand(mob/living/target = null) as /obj/item/riding_offhand
	for(var/obj/item/riding_offhand/offhand in contents)
		if(offhand.parent != src)
			continue
		if(!offhand.rider)
			continue
		if(offhand.rider in buckled_mobs) // Existing fireman/piggyback carry, not a normal grab.
			continue
		if(target && offhand.rider != target)
			continue
		return offhand
	return null

/mob/living/proc/ensure_cy_grab_hand_item(mob/living/target)
	if(!istype(target) || pulling != target)
		return FALSE
	var/mob/living/carbon/carbon_target = target
	if(!istype(carbon_target))
		return FALSE
	var/obj/item/riding_offhand/existing_offhand = get_cy_grab_offhand(target)
	if(existing_offhand)
		existing_offhand.name = "захват [target.declent_ru(GENITIVE)]"
		existing_offhand.desc = "Эта рука удерживает [target.declent_ru(ACCUSATIVE)]. Пока захват активен, рука занята."
		return TRUE
	var/obj/item/riding_offhand/grab_offhand = new(src)
	grab_offhand.parent = src
	grab_offhand.rider = carbon_target
	grab_offhand.name = "захват [target.declent_ru(GENITIVE)]"
	grab_offhand.desc = "Эта рука удерживает [target.declent_ru(ACCUSATIVE)]. Пока захват активен, рука занята."
	var/inserted_successfully = FALSE
	if(put_in_active_hand(grab_offhand))
		inserted_successfully = TRUE
	else
		var/hand = get_empty_held_index_for_side(LEFT_HANDS) || get_empty_held_index_for_side(RIGHT_HANDS)
		if(hand && put_in_hand(grab_offhand, hand))
			inserted_successfully = TRUE
	if(!inserted_successfully)
		qdel(grab_offhand)
		to_chat(src, span_warning("Вам нужна свободная рука, чтобы удерживать захват."))
		return FALSE
	return TRUE

/mob/living/proc/clear_cy_grab_hand_item()
	var/cleared = FALSE
	for(var/obj/item/riding_offhand/offhand in contents)
		if(offhand.parent != src)
			continue
		if(!offhand.rider)
			continue
		if(offhand.rider in buckled_mobs) // Do not remove real carry/piggyback offhands here.
			continue
		qdel(offhand)
		cleared = TRUE
	return cleared

// CYBERPUNK 13 STAGE 3 CORE OXYGENATION / DIAGNOSIS START
/mob/living/carbon/human/proc/get_cy_blood_percent()
	if(!blood_volume)
		return 0
	return clamp(blood_volume / BLOOD_VOLUME_NORMAL, 0, 1)

/mob/living/carbon/human/proc/get_cy_pressure_delta()
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart)
		return 0
	var/pressure = heart.get_cy_pressure_delta()
	if(reagents?.has_reagent(/datum/reagent/medicine/epinephrine))
		pressure += CY_PRESSURE_EPINEPHRINE_BONUS
	if(reagents?.has_reagent(/datum/reagent/medicine/atropine))
		pressure += CY_PRESSURE_ATROPINE_BONUS
	return clamp(pressure, 0, 1.5)

/mob/living/carbon/human/proc/get_cy_lung_efficiency()
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return 0
	return lungs.get_cy_lung_efficiency()

/mob/living/carbon/human/proc/get_cy_blood_oxygenation()
	return clamp(get_cy_blood_percent() * get_cy_pressure_delta() * get_cy_lung_efficiency(), 0, 1)

/mob/living/carbon/human/proc/process_cy_oxygenation(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_NOBREATH) || stat == DEAD)
		return FALSE
	var/oxygenation = get_cy_blood_oxygenation()
	if(oxygenation >= CY_BLOOD_OXYGENATION_BRAIN_REQUIRED)
		adjust_oxy_loss(-0.35 * seconds_per_tick, updating_health = FALSE, forced = TRUE)
		if(oxygenation > 1)
			adjust_stamina_loss(-CY_HIGH_OXYGEN_STAMINA_RECOVERY * seconds_per_tick, updating_stamina = FALSE, forced = TRUE)
		return TRUE
	var/deficit = CY_BLOOD_OXYGENATION_BRAIN_REQUIRED - oxygenation
	adjust_oxy_loss(deficit * 4 * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	if(oxygenation <= 0.25)
		adjust_organ_loss(ORGAN_SLOT_BRAIN, CY_CRITICAL_OXYGEN_BRAIN_DAMAGE_PER_SECOND * seconds_per_tick)
	else
		adjust_organ_loss(ORGAN_SLOT_BRAIN, CY_LOW_OXYGEN_BRAIN_DAMAGE_PER_SECOND * deficit * seconds_per_tick)
	return TRUE

/mob/living/carbon/human/proc/get_cy_diagnostic_lines(mob/living/user, advanced = FALSE)
	var/list/lines = list()
	if((!user || !HAS_TRAIT(user, TRAIT_CY_MEDICINE_1)) && !advanced)
		lines += "General state: [health < critical_health_threshold ? "critical" : health < maxHealth * 0.5 ? "poor" : "stable"]."
		return lines
	lines += "Health [round(health)]/[maxHealth]; pain [round(get_pain_loss())]; psychic [round(get_psychic_loss())]."
	if(HAS_TRAIT(user, TRAIT_CY_MEDICINE_3) || advanced)
		lines += "Blood [round(get_cy_blood_percent() * 100)]%; pressure [round(get_cy_pressure_delta() * 100)]%; lung efficiency [round(get_cy_lung_efficiency() * 100)]%; oxygenation [round(get_cy_blood_oxygenation() * 100)]%."
	if(is_cy_clinically_dead())
		lines += "Clinical death threshold reached. Revive requires working heart and non-dead brain."
	if(brain_dead)
		lines += "Brain death: revival blocked."
	if(has_dna())
		lines += "Humanoidity [round(get_cy_humanoidity())]%; stabilized buffer [round(get_cy_humanoidity_stabilized_bonus())]%; gene slots [length(dna.cy_gene_segments)]/[CY_GENETIC_MAX_SEGMENTS]."
	var/implant_heat = get_cy_total_implant_overheat()
	if(implant_heat || advanced)
		lines += "Implants: neural interface [has_cy_neurointerface() ? "online" : "missing"]; heat [round(implant_heat)]/[round(get_cy_brain_overheat_capacity())]."
	if(advanced)
		for(var/obj/item/organ/organ as anything in organs)
			lines += organ.get_cy_diagnostic_lines(TRUE)
		for(var/obj/item/organ/cyberimp/implant as anything in organs)
			var/datum/cy_organization/manufacturer = implant.get_manufacturer_organization()
			lines += "[capitalize(implant.name)]: manufacturer [manufacturer ? manufacturer.name : "unknown"], heat [round(implant.get_cy_implant_overheat())], state [implant.is_cy_functional_implant() ? "functional" : "offline"]."
	return lines

/mob/living/proc/get_cy_secondary_indicators()
	var/list/indicators = list()
	indicators["health"] = list(
		"current" = health,
		"maximum" = maxHealth,
		"critical" = is_cy_critical(),
		"clinical_death" = is_cy_clinically_dead(),
		"brain_dead" = is_cy_brain_dead(),
	)
	indicators["breath"] = list(
		"reserved_breath" = losebreath,
		"oxygen_damage" = get_oxy_loss(),
	)
	indicators["stamina"] = list(
		"loss" = staminaloss,
		"maximum" = max_stamina,
	)
	indicators["needs"] = list(
		"nutrition" = nutrition,
		"nutrition_stage" = get_cy_hunger_level(),
		"hydration" = hydration,
		"hydration_stage" = get_cy_thirst_level(),
		"rest" = rest,
		"rest_stage" = get_cy_sleep_deprivation_level(),
	)
	indicators["mental"] = list(
		"pain" = get_pain_loss(),
		"psychic_pressure" = get_psychic_loss(),
		"mood_level" = mob_mood?.mood_level,
		"sanity_level" = mob_mood?.sanity_level,
	)
	indicators["psyche"] = get_cy_psyche_state()
	indicators["style"] = list(
		"equipment_score" = get_cy_equipment_style_score(),
		"tags" = get_cy_equipment_style_tags(),
	)
	var/area/current_area = get_area(src)
	indicators["zone"] = current_area?.cy_describe_zone()
	indicators["legal_risk"] = list(
		"controlled_items_here" = length(get_cy_controlled_items_in_zone()),
	)
	indicators["equipment"] = get_cy_equipment_indicator()
	return indicators

/mob/living/proc/get_cy_equipment_indicator()
	var/list/equipment = list()
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		equipment += list(list(
			"name" = equipped.name,
			"type" = equipped.type,
			"weight_class" = equipped.w_class,
			"style" = equipped.get_cy_style_value(),
			"style_tags" = equipped.get_cy_style_tags(),
			"market_category" = equipped.get_cy_market_category(),
			"market_value" = equipped.get_cy_market_value(),
		))
	return equipment

/mob/living/proc/get_cy_secondary_indicator_summary()
	var/list/indicators = get_cy_secondary_indicators()
	var/list/health_data = indicators["health"]
	var/list/breath_data = indicators["breath"]
	var/list/stamina_data = indicators["stamina"]
	var/list/needs_data = indicators["needs"]
	var/list/mental_data = indicators["mental"]
	var/list/style_data = indicators["style"]
	return list(
		"Health [round(health_data["current"])]/[health_data["maximum"]]",
		"Breath reserve [round(breath_data["reserved_breath"])]; oxygen damage [round(breath_data["oxygen_damage"])]",
		"Stamina loss [round(stamina_data["loss"])]/[stamina_data["maximum"]]",
		"Nutrition [round(needs_data["nutrition"])]; hydration [round(needs_data["hydration"])]; rest [round(needs_data["rest"])]",
		"Pain [round(mental_data["pain"])]; psychic [round(mental_data["psychic_pressure"])]",
		"Style [round(style_data["equipment_score"])]",
	)

/mob/living/carbon/human/get_cy_secondary_indicators()
	. = ..()
	.["blood"] = list(
		"percent" = get_cy_blood_percent(),
		"pressure" = get_cy_pressure_delta(),
		"oxygenation" = get_cy_blood_oxygenation(),
	)
	.["implants"] = list(
		"overheat" = get_cy_total_implant_overheat(),
		"overheat_capacity" = get_cy_brain_overheat_capacity(),
		"has_neurointerface" = has_cy_neurointerface(),
	)
	.["organs"] = get_cy_organ_indicator()
	.["limbs"] = get_cy_limb_indicator()

/mob/living/carbon/human/proc/get_cy_organ_indicator()
	var/list/organ_data = list()
	for(var/obj/item/organ/organ as anything in organs)
		organ_data[organ.slot || "[organ.type]"] = list(
			"name" = organ.name,
			"type" = organ.type,
			"health_ratio" = organ.get_cy_health_ratio(),
			"function_efficiency" = organ.get_cy_function_efficiency(),
			"damage" = organ.damage,
			"maximum" = organ.maxHealth,
			"conditions" = organ.get_cy_condition_summary(),
		)
	return organ_data

/mob/living/carbon/human/proc/get_cy_limb_indicator()
	var/list/limb_data = list()
	for(var/obj/item/bodypart/limb as anything in get_bodyparts(include_stumps = TRUE))
		limb_data[limb.body_zone || "[limb.type]"] = list(
			"name" = limb.name,
			"type" = limb.type,
			"brute" = limb.get_brute_damage(),
			"burn" = limb.get_burn_damage(),
			"maximum" = limb.max_damage,
			"disabled" = limb.bodypart_disabled,
			"missing" = IS_STUMP(limb),
			"bleed_rate" = limb.cached_bleed_rate,
			"wounds" = length(limb.wounds),
		)
	return limb_data

/mob/living/carbon/human/get_cy_secondary_indicator_summary()
	. = ..()
	. += "Blood [round(get_cy_blood_percent() * 100)]%; oxygenation [round(get_cy_blood_oxygenation() * 100)]%"
	. += "Implants heat [round(get_cy_total_implant_overheat())]/[round(get_cy_brain_overheat_capacity())]"
// CYBERPUNK 13 STAGE 3 CORE OXYGENATION / DIAGNOSIS END

// CYBERPUNK 13 STAGE 3 CORE REAGENT ROUTE STATE START
/mob/living/carbon
	/// Last CP13 route used by reagents entering blood metabolism. Defaults to injection/blood.
	var/cy_current_reagent_route = CY_REAGENT_ROUTE_INJECT

/mob/living/carbon/proc/get_cy_current_reagent_route()
	return cy_current_reagent_route || CY_REAGENT_ROUTE_INJECT

/mob/living/carbon/proc/set_cy_current_reagent_route(route)
	cy_current_reagent_route = route || CY_REAGENT_ROUTE_INJECT
	return cy_current_reagent_route
// CYBERPUNK 13 STAGE 3 CORE REAGENT ROUTE STATE END


// CYBERPUNK 13 STAGE 3 CORE MEDICAL ROUTING FIX3 START
/mob/living/carbon/human/proc/route_cy_toxin_to_organs(amount, acidic = FALSE)
	if(amount <= 0)
		return FALSE
	var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && liver.get_cy_function_efficiency() > 0)
		adjust_organ_loss(ORGAN_SLOT_LIVER, amount * CY_TOXIN_LIVER_ROUTING_MULTIPLIER, required_organ_flag = ORGAN_ORGANIC)
		if(acidic)
			adjust_organ_loss(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH), amount * 0.15, required_organ_flag = ORGAN_ORGANIC)
		return TRUE
	var/list/fallback_organs = list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_BRAIN)
	for(var/i in 1 to min(3, length(fallback_organs)))
		adjust_organ_loss(pick_n_take(fallback_organs), amount * CY_TOXIN_ORGAN_SPILLOVER_MULTIPLIER, required_organ_flag = ORGAN_ORGANIC)
	return TRUE

/mob/living/carbon/human/proc/apply_cy_rapid_bloodloss(amount)
	if(amount <= 0)
		return FALSE
	adjust_organ_loss(ORGAN_SLOT_HEART, amount * CY_FAST_BLOOD_LOSS_HEART_DAMAGE_PER_UNIT, required_organ_flag = ORGAN_ORGANIC)
	adjust_organ_loss(ORGAN_SLOT_BRAIN, amount * CY_FAST_BLOOD_LOSS_BRAIN_DAMAGE_PER_UNIT, required_organ_flag = ORGAN_ORGANIC)
	return TRUE
// CYBERPUNK 13 STAGE 3 CORE MEDICAL ROUTING FIX3 END
