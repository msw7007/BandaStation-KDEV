/mob/living/proc/get_cy_skill_perk(skill_type, level)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_perk(skill_type, level)

/mob/living/proc/has_cy_skill_perk(skill_type, level)
	return !!get_cy_skill_perk(skill_type, level)

/mob/living/proc/get_cy_skill_perk_value(skill_type, level, effect_key, default = 0)
	var/datum/cy_skill_perk/perk = get_cy_skill_perk(skill_type, level)
	return perk ? perk.get_value(effect_key, default) : default

/mob/living/proc/get_cy_skill_speed_multiplier(skill_type)
	switch(skill_type)
		if(/datum/cy_skill/professional/cooking)
			if(!src.has_cy_skill_perk(/datum/cy_skill/professional/cooking, 1))
				return 1.3
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/cooking, 6))
				return get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 6, "value_1", 20) * 0.01
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/cooking, 2))
				return get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 2, "value_1", 75) * 0.01
			return 1
		if(/datum/cy_skill/professional/mining)
			if(!src.has_cy_skill_perk(/datum/cy_skill/professional/mining, 1))
				return 1.5
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/mining, 6))
				return get_cy_skill_perk_value(/datum/cy_skill/professional/mining, 6, "value_1", 25) * 0.01
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/mining, 2))
				return 1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/mining, 2, "value_1", 25) * 0.01)
			return 1
		if(/datum/cy_skill/professional/analysis)
			var/multiplier = 1
			if(!src.has_cy_skill_perk(/datum/cy_skill/professional/analysis, 1))
				multiplier *= 1.5
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/analysis, 2))
				multiplier *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/analysis, 2, "value_1", 25) * 0.01)
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/analysis, 4))
				multiplier *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/analysis, 4, "value_2", 25) * 0.01)
			return multiplier * get_cy_intelligence_action_delay_multiplier()
		if(/datum/cy_skill/professional/construction)
			if(!src.has_cy_skill_perk(/datum/cy_skill/professional/construction, 1))
				return 1.3
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/construction, 2))
				return 1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/construction, 2, "value_2", 20) * 0.01)
			return 1
		if(/datum/cy_skill/professional/invention)
			if(!src.has_cy_skill_perk(/datum/cy_skill/professional/invention, 1))
				return 1.3 * get_cy_intelligence_action_delay_multiplier()
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/invention, 5))
				return (1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/invention, 5, "value_1", 30) * 0.01)) * get_cy_intelligence_action_delay_multiplier()
			if(src.has_cy_skill_perk(/datum/cy_skill/professional/invention, 3))
				return (1 - (get_cy_skill_perk_value(/datum/cy_skill/professional/invention, 3, "value_2", 10) * 0.01)) * get_cy_intelligence_action_delay_multiplier()
			return get_cy_intelligence_action_delay_multiplier()
	return max(0.35, get_cy_skill_speed_multiplier_no_perks(skill_type))

/mob/living/proc/get_cy_skill_probability_bonus(skill_type)
	return get_cy_skill_probability_bonus_no_perks(skill_type)

/mob/living/proc/get_cy_skill_value_modifier(skill_type)
	return get_cy_skill_level(skill_type)

/mob/living/proc/get_cy_skill_speed_multiplier_no_perks(skill_type)
	var/multiplier = max(0.4, 1 - get_cy_skill_level(skill_type) * CY_PROFESSIONAL_SKILL_SPEED_PER_LEVEL)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(skill?.governing_stat == /datum/cy_stat/intelligence)
		multiplier *= get_cy_intelligence_action_delay_multiplier()
	return multiplier

/mob/living/proc/get_cy_skill_probability_bonus_no_perks(skill_type)
	return get_cy_skill_level(skill_type) * CY_SKILL_VALUE_PER_LEVEL

/mob/living/proc/get_cy_skill_quality_bonus_no_perks(skill_type)
	return get_cy_skill_level(skill_type) * CY_PROFESSIONAL_SKILL_QUALITY_PER_LEVEL

/mob/living/proc/has_cy_skill_perk_level(skill_type, required_level)
	return has_cy_skill_perk(skill_type, required_level)

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
	if(has_cy_skill_perk_level(/datum/cy_skill/strength/toughness, 6))
		toughness_multiplier = body_position == LYING_DOWN ? 0.9 : 0.8
	else if(!get_cy_skill_level(/datum/cy_skill/strength/toughness))
		toughness_multiplier = 1.1
	if(world.time < cy_surrender_until)
		toughness_multiplier *= 0.7
	return toughness_multiplier

/mob/living/proc/get_cy_stagger_duration_multiplier()
	var/multiplier = get_cy_spirit_effect_multiplier()
	if(has_cy_skill_perk_level(/datum/cy_skill/strength/toughness, 3))
		multiplier *= body_position == LYING_DOWN ? 0.75 : 1 - (get_cy_skill_perk_value(/datum/cy_skill/strength/toughness, 3, "value_1", 50) * 0.01)
	if(has_cy_skill_perk_level(/datum/cy_skill/spirit/endurance, 4))
		multiplier *= 1 - (get_cy_skill_perk_value(/datum/cy_skill/spirit/endurance, 4, "value_1", 50) * 0.01)
	return multiplier

/mob/living/proc/get_cy_negative_effect_duration_multiplier()
	var/spirit_multiplier = get_cy_spirit_effect_multiplier()
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/composure, 5))
		return spirit_multiplier * (1 - (get_cy_skill_perk_value(/datum/cy_skill/intelligence/composure, 5, "value_1", 25) * 0.01))
	if(has_cy_skill_perk_level(/datum/cy_skill/intelligence/composure, 2))
		return spirit_multiplier * (1 - (get_cy_skill_perk_value(/datum/cy_skill/intelligence/composure, 2, "value_1", 20) * 0.01))
	return spirit_multiplier

/mob/living/proc/get_cy_professional_quality_bonus(skill_type)
	return get_cy_skill_level(skill_type) * CY_PROFESSIONAL_SKILL_QUALITY_PER_LEVEL

/mob/living/proc/cy_apply_cooking_perks_to_food(obj/item/food/food)
	if(!food)
		return FALSE
	var/quality_bonus = 0
	var/effect_level = 0
	if(has_cy_skill_perk(/datum/cy_skill/professional/cooking, 2) && prob(get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 2, "value_2", 15)))
		var/level_2_effect = get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 2, "value_3", 1)
		quality_bonus += level_2_effect
		effect_level = max(effect_level, level_2_effect)
	if(has_cy_skill_perk(/datum/cy_skill/professional/cooking, 3))
		effect_level = max(effect_level, min(get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 3, "value_1", 3), max(0, food.cy_quality - CY_QUALITY_AVERAGE + 1)))
	if(has_cy_skill_perk(/datum/cy_skill/professional/cooking, 5))
		var/level_5_effect = get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 5, "value_2", 1)
		quality_bonus += level_5_effect
		effect_level = max(effect_level, min(FOOD_COMPLEXITY_5, food.crafting_complexity + level_5_effect))
	if(effect_level)
		food.crafting_complexity = max(food.crafting_complexity, min(FOOD_COMPLEXITY_5, effect_level))
	if(has_cy_skill_perk(/datum/cy_skill/professional/cooking, 6) && prob(get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 6, "value_2", 30)))
		cy_emit_cooking_effect_gas(food, get_cy_skill_perk_value(/datum/cy_skill/professional/cooking, 6, "value_3", 1))
	if(!quality_bonus && !effect_level)
		return FALSE
	food.cy_set_quality(food.cy_quality + quality_bonus)
	food.cy_quality_affects_stats = TRUE
	food.cy_initialize_quality_core()
	food.cy_rebuild_item_stats()
	return TRUE

/mob/living/proc/cy_emit_cooking_effect_gas(obj/item/food/food, effect_level = FOOD_COMPLEXITY_1)
	if(!food)
		return FALSE
	var/list/available_buffs = GLOB.food_buffs[min(max(effect_level, FOOD_COMPLEXITY_1), FOOD_COMPLEXITY_5)]
	var/datum/status_effect/food/buff = food.crafted_food_buff || pick_weight(available_buffs)
	if(!buff)
		return FALSE
	food.visible_message(span_notice("[food] releases an aromatic cloud."))
	for(var/mob/living/target in viewers(2, food))
		target.apply_status_effect(buff)
	return TRUE

/mob/living/proc/award_cy_professional_activity(skill_type, amount = CY_PROFESSIONAL_SKILL_EXPERIENCE_BASE)
	if(!ispath(skill_type, /datum/cy_skill/professional) || amount <= 0)
		return FALSE
	return perform_cy_skill_check(skill_type, amount)

/mob/living/proc/get_cy_cohort_limit()
	if(has_cy_skill_perk(/datum/cy_skill/charisma/inspiration, CY_SKILL_LEVEL_MASTER))
		return get_cy_skill_perk_value(/datum/cy_skill/charisma/inspiration, CY_SKILL_LEVEL_MASTER, "cohort_limit", 8)
	for(var/level in CY_SKILL_LEVEL_PROFESSIONAL to CY_SKILL_LEVEL_SKILLED step -1)
		var/cohort_limit = get_cy_skill_perk_value(/datum/cy_skill/charisma/inspiration, level, "cohort_limit", null)
		if(!isnull(cohort_limit))
			return cohort_limit
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
	var/effectiveness_bonus = get_cy_skill_perk_value(/datum/cy_skill/charisma/inspiration, CY_SKILL_LEVEL_TRAINED, "effectiveness_bonus", 0)
	if(effectiveness_bonus)
		multiplier *= 1 + (effectiveness_bonus * 0.01)
	var/cohort_mood_bonus = get_cy_skill_perk_value(/datum/cy_skill/charisma/inspiration, CY_SKILL_LEVEL_PROFESSIONAL, "cohort_mood_max_bonus", 0)
	if(cohort_mood_bonus)
		multiplier *= 1 + (cohort_mood_bonus * 0.01)
	return multiplier

/mob/living/proc/get_cy_theft_notice_chance(mob/living/victim)
	var/theft_level = get_cy_skill_level(/datum/cy_skill/charisma/theft)
	if(theft_level >= CY_SKILL_LEVEL_EXPERT)
		var/victim_perception = victim?.get_cy_stat(/datum/cy_stat/perception) || CY_STAT_DEFAULT
		if(victim_perception < theft_level * 3)
			return 0
	if(theft_level >= CY_SKILL_LEVEL_SKILLED)
		return is_cy_stealthing() ? 50 : 75
	if(theft_level >= CY_SKILL_LEVEL_BEGINNER)
		return 100
	return 100

/mob/living/proc/get_cy_theft_delay_multiplier()
	var/theft_level = get_cy_skill_level(/datum/cy_skill/charisma/theft)
	if(theft_level >= CY_SKILL_LEVEL_EXPERT)
		return 0
	return max(0.35, 1 - theft_level * 0.08)

/mob/living/proc/can_cy_steal_strippable_key(key)
	if(get_cy_skill_level(/datum/cy_skill/charisma/theft) >= CY_SKILL_LEVEL_MASTER)
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

/datum/cy_skill_holder/proc/get_granted_perk_list(skill_type)
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!perk_list)
		perk_list = list()
		granted_skill_perks[skill_type] = perk_list

	return perk_list

/datum/cy_skill_holder/proc/clear_skill_perks()
	if(!granted_skill_perks)
		return

	for(var/skill_type in granted_skill_perks)
		var/list/skill_perks = granted_skill_perks[skill_type]
		if(!islist(skill_perks))
			continue
		for(var/perk_type in skill_perks)
			var/datum/cy_skill_perk/perk = skill_perks[perk_type]
			if(!perk)
				continue
			if(isliving(owner))
				perk.on_loss(owner)
			qdel(perk)
		skill_perks.Cut()
	granted_skill_perks.Cut()

/datum/cy_skill_holder/proc/get_skill_perk(skill_type, level)
	var/list/perk_list = granted_skill_perks[skill_type]
	if(!length(perk_list))
		return null
	for(var/perk_type in perk_list)
		var/datum/cy_skill_perk/perk = perk_list[perk_type]
		if(perk?.level == level)
			return perk

	return null

/datum/cy_skill_holder/proc/grant_skill_perk(skill_type, perk_type)
	if(!is_valid_skill(skill_type) || !ispath(perk_type, /datum/cy_skill_perk))
		return FALSE

	var/list/perk_list = get_granted_perk_list(skill_type)
	if(perk_list[perk_type])
		return FALSE

	var/datum/cy_skill_perk/perk = new perk_type
	perk.skill_type = skill_type
	perk.apply_skill_context()
	perk_list[perk_type] = perk

	if(isliving(owner))
		perk.on_gain(owner)

	return TRUE

/datum/cy_skill_holder/proc/remove_skill_perk(skill_type, perk_type)
	if(!is_valid_skill(skill_type) || !ispath(perk_type, /datum/cy_skill_perk))
		return FALSE

	var/list/perk_list = granted_skill_perks[skill_type]
	if(!perk_list)
		return FALSE

	var/datum/cy_skill_perk/perk = perk_list[perk_type]
	if(!perk)
		return FALSE

	if(isliving(owner))
		perk.on_loss(owner)

	perk_list -= perk_type
	qdel(perk)
	return TRUE

/datum/cy_skill_holder/proc/refresh_skill_perks(skill_type, old_level, new_level)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return

	if(new_level > old_level)
		for(var/current_level in (old_level + 1) to new_level)
			for(var/perk_type in skill.get_perks_for_level(current_level))
				grant_skill_perk(skill_type, perk_type)
		return

	if(new_level < old_level)
		for(var/current_level in old_level to (new_level + 1) step -1)
			for(var/perk_type in skill.get_perks_for_level(current_level))
				remove_skill_perk(skill_type, perk_type)
