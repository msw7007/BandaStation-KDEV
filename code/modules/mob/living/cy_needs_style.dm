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
	var/hunger_and_thirst = round((get_cy_hunger_level() + get_cy_thirst_level()) * get_cy_survival_need_penalty_multiplier())
	var/sleep_deprivation = has_cy_skill_perk(/datum/cy_skill/spirit/survival, 3) ? 0 : get_cy_sleep_deprivation_level()
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
	if(best_skill_type && best_skill_level > CY_SKILL_LEVEL_UNTRAINED)
		var/datum/cy_skill/skill = get_cy_skill_datum(best_skill_type)
		var/skill_id = skill?.id || "unknown"
		result += "Most visible training: [skill_id] [best_skill_level]."
