/datum/mind/proc/init_character_attributes()
	for(var/attribute_type in GLOB.attribute_types)
		var/datum/attribute/attribute = new attribute_type(ATTRIBUTE_DEFAULT)
		character_attributes[attribute.id] = attribute

/datum/mind/proc/get_attribute(attribute_id)
	return character_attributes[attribute_id]

/datum/mind/proc/get_attribute_value(attribute_id)
	var/datum/attribute/attribute = get_attribute(attribute_id)
	return attribute?.value || ATTRIBUTE_DEFAULT

/datum/mind/proc/set_attribute_value(attribute_id, new_value)
	var/datum/attribute/attribute = get_attribute(attribute_id)
	if(!attribute)
		return 0
	return attribute.set_value(new_value)

/datum/mind/proc/adjust_attribute_value(attribute_id, amount)
	var/datum/attribute/attribute = get_attribute(attribute_id)
	if(!attribute)
		return 0
	return attribute.adjust_value(amount)

/datum/mind/proc/has_super_attribute(attribute_id)
	var/datum/attribute/attribute = get_attribute(attribute_id)
	return !!attribute?.super_mode

/datum/mind/proc/get_attribute_check_value(skill_level, attribute_id)
	return (skill_level * 10) + (get_attribute_value(attribute_id) * 5)

/datum/mind/proc/get_attribute_perk_point_limit(attribute_id)
	return get_attribute_value(attribute_id)

/datum/mind/proc/reward_character_check_experience(skill_key, difficulty, attribute_limited = FALSE, action_multiplier = 1)
	if(difficulty <= 0)
		return 0

	var/final_experience = difficulty * action_multiplier
	if(isliving(current))
		var/mob/living/living_current = current
		final_experience *= living_current.get_experience_multiplier()

	if(attribute_limited)
		unconverted_general_experience += final_experience * 0.6
		return final_experience

	if(skill_key)
		pending_skill_experience[skill_key] = (pending_skill_experience[skill_key] || 0) + (final_experience * 0.75)
	unconverted_general_experience += final_experience * 0.25
	return final_experience

/datum/mind/proc/convert_rest_experience()
	if(unconverted_general_experience >= ATTRIBUTE_LEVEL_POINT_EXPERIENCE)
		var/new_points = FLOOR(unconverted_general_experience / ATTRIBUTE_LEVEL_POINT_EXPERIENCE, 1)
		level_points += new_points
		character_level += new_points
		unconverted_general_experience -= new_points * ATTRIBUTE_LEVEL_POINT_EXPERIENCE

	for(var/skill_key in pending_skill_experience)
		converted_skill_experience[skill_key] = (converted_skill_experience[skill_key] || 0) + pending_skill_experience[skill_key]
	pending_skill_experience.Cut()

/datum/mind/proc/spend_level_point_on_attribute(attribute_id)
	if(level_points <= 0)
		return FALSE
	var/datum/attribute/attribute = get_attribute(attribute_id)
	if(!attribute || attribute.value >= ATTRIBUTE_MAXIMUM)
		return FALSE
	level_points--
	attribute.adjust_value(1)
	return TRUE

/datum/mind/proc/convert_level_points_to_skill_points(amount = 1)
	if(level_points <= 0)
		return FALSE
	amount = clamp(round(amount), 1, level_points)
	if(amount <= 0)
		return FALSE
	level_points -= amount
	skill_points += amount * 2
	return TRUE

/mob/living/proc/get_attribute_value(attribute_id)
	return mind?.get_attribute_value(attribute_id) || ATTRIBUTE_DEFAULT

/mob/living/proc/get_attribute_check_value(skill_level, attribute_id)
	return mind?.get_attribute_check_value(skill_level, attribute_id) || ((skill_level * 10) + (ATTRIBUTE_DEFAULT * 5))

/mob/living/proc/get_character_check_value(skill_level, attribute_id, apply_body_penalty = TRUE)
	var/check_value = get_attribute_check_value(skill_level, attribute_id)
	if(apply_body_penalty)
		check_value *= (1 - get_check_penalty())
	return check_value

/mob/living/proc/get_attribute_perk_point_limit(attribute_id)
	return mind?.get_attribute_perk_point_limit(attribute_id) || ATTRIBUTE_DEFAULT

/mob/living/proc/reward_character_check_experience(skill_key, difficulty, attribute_limited = FALSE, action_multiplier = 1)
	return mind?.reward_character_check_experience(skill_key, difficulty, attribute_limited, action_multiplier) || 0

/mob/living/proc/get_character_skill_level(skill)
	return mind?.get_character_skill_level(skill) || CHARACTER_SKILL_LEVEL_NONE

/mob/living/proc/set_character_skill_level(skill, new_level, free = FALSE)
	return mind?.set_character_skill_level(skill, new_level, free) || FALSE

/mob/living/proc/adjust_character_skill_level(skill, amount = 1, free = FALSE)
	return mind?.adjust_character_skill_level(skill, amount, free) || FALSE

/mob/living/proc/get_character_skill_check(skill, modifier = 0, apply_body_penalty = TRUE)
	return mind?.get_character_skill_check_value(skill, modifier, apply_body_penalty) || clamp((ATTRIBUTE_DEFAULT * 5) + modifier, CHARACTER_SKILL_CHECK_MINIMUM, CHARACTER_SKILL_CHECK_MAXIMUM)

/mob/living/proc/roll_character_skill_check(skill, difficulty = 0, modifier = 0, apply_body_penalty = TRUE)
	return mind?.roll_character_skill_check(skill, difficulty, modifier, apply_body_penalty) || prob(clamp((ATTRIBUTE_DEFAULT * 5) + modifier - difficulty, CHARACTER_SKILL_CHECK_MINIMUM, CHARACTER_SKILL_CHECK_MAXIMUM))

/mob/living/proc/get_character_perk_rank(skill, perk_index)
	return mind?.get_character_perk_rank(skill, perk_index) || 0

/mob/living/proc/set_character_perk_rank(skill, perk_index, new_rank, free = FALSE, allow_sequence_break = FALSE)
	return mind?.set_character_perk_rank(skill, perk_index, new_rank, free, allow_sequence_break) || FALSE

/mob/living/proc/adjust_character_perk_rank(skill, perk_index, amount = 1, free = FALSE, allow_sequence_break = FALSE)
	return mind?.adjust_character_perk_rank(skill, perk_index, amount, free, allow_sequence_break) || FALSE

/mob/living/proc/get_character_perk_power_multiplier(skill, perk_index)
	return mind?.get_character_perk_power_multiplier(skill, perk_index) || 0

/mob/living/proc/has_character_giga_perk(attribute_id)
	return mind?.has_character_giga_perk(attribute_id) || FALSE

/mob/living/proc/get_weapon_skill_damage_multiplier(skill)
	return mind?.get_weapon_skill_damage_multiplier(skill) || 1

/mob/living/proc/get_weapon_skill_cooldown_multiplier(skill)
	return mind?.get_weapon_skill_cooldown_multiplier(skill) || 1

/mob/living/proc/get_weapon_skill_defense_break_bonus(skill)
	return mind?.get_weapon_skill_defense_break_bonus(skill) || 0

/mob/living/proc/teach_character_skill_to(mob/living/student, skill, difficulty = 1, action_multiplier = 1)
	return mind?.teach_character_skill(student, skill, difficulty, action_multiplier) || FALSE
