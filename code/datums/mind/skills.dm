/datum/mind/var/list/cyberdemon_skill_modifiers = list()

/datum/mind/proc/get_cyberdemon_skill_modifier(skill)
	var/total_modifier = 0
	for(var/modifier_key in cyberdemon_skill_modifiers)
		var/list/modifier_data = cyberdemon_skill_modifiers[modifier_key]
		if(!modifier_data || modifier_data["skill"] != skill)
			continue
		total_modifier += modifier_data["amount"] || 0
	return total_modifier

/datum/mind/proc/add_cyberdemon_skill_modifier(skill, amount, duration, source_name = "demon")
	if(!skill || !amount || duration <= 0)
		return null
	var/modifier_key = "[source_name]-[skill]-[world.time]-[rand(1, 99999)]"
	cyberdemon_skill_modifiers[modifier_key] = list(
		"skill" = skill,
		"amount" = amount,
	)
	addtimer(CALLBACK(src, PROC_REF(remove_cyberdemon_skill_modifier), modifier_key), duration)
	return modifier_key

/datum/mind/proc/remove_cyberdemon_skill_modifier(modifier_key)
	cyberdemon_skill_modifiers -= modifier_key

/datum/mind/proc/init_known_skills()
	for (var/type in GLOB.skill_types)
		known_skills[type] = list(SKILL_LEVEL_NONE, 0)
		var/datum/skill/skill_path = type
		if(initial(skill_path.skill_kind) == CHARACTER_SKILL_KIND_WEAPON)
			character_skill_levels[type] = CHARACTER_SKILL_LEVEL_NONE
		else if(initial(skill_path.max_perk_rank))
			character_skill_perks[type] = list()

/datum/mind/proc/get_character_skill_datum(skill)
	return GetSkillRef(skill)

/datum/mind/proc/is_character_skill(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	return skill_datum && skill_datum.is_character_skill()

/datum/mind/proc/get_character_perk_list(skill)
	if(!character_skill_perks[skill])
		character_skill_perks[skill] = list()
	return character_skill_perks[skill]

/datum/mind/proc/normalize_character_skill_number(value)
	if(!isnum(value))
		value = text2num("[value]")
	return round(value || 0)

/datum/mind/proc/get_character_perk_key(perk_index)
	return "[normalize_character_skill_number(perk_index)]"

/datum/mind/proc/get_character_perk_rank(skill, perk_index)
	var/list/perk_ranks = get_character_perk_list(skill)
	var/datum/skill/skill_datum = GetSkillRef(skill)
	perk_index = normalize_character_skill_number(perk_index)
	var/rank = perk_ranks[get_character_perk_key(perk_index)]
	if(isnull(rank) && perk_index >= 1 && perk_index <= length(perk_ranks))
		var/has_keyed_perks = FALSE
		for(var/stored_perk_key in perk_ranks)
			if(istext(stored_perk_key))
				has_keyed_perks = TRUE
				break
		if(!has_keyed_perks)
			rank = perk_ranks[perk_index]
	rank = normalize_character_skill_number(rank)
	return clamp(rank || 0, 0, skill_datum ? skill_datum.max_perk_rank : 0)

/datum/mind/proc/get_character_skill_spent_points(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return 0
	if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_WEAPON)
		return normalize_character_skill_number(character_skill_levels[skill])
	var/total_points = 0
	var/list/perk_ranks = get_character_perk_list(skill)
	for(var/perk_index in perk_ranks)
		var/rank = normalize_character_skill_number(perk_ranks[perk_index])
		total_points += rank || 0
	return total_points

/datum/mind/proc/get_character_skill_spent_points_by_kind(skill_kind)
	var/total_points = 0
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || skill_datum.skill_kind != skill_kind)
			continue
		total_points += get_character_skill_spent_points(skill_type)
	return total_points

/datum/mind/proc/recalculate_character_skill_point_pools()
	professional_skill_points = max(0, PROFESSIONAL_SKILL_POINTS_DEFAULT - get_character_skill_spent_points_by_kind(CHARACTER_SKILL_KIND_PROFESSIONAL))
	weapon_skill_points = max(0, WEAPON_SKILL_POINTS_DEFAULT - get_character_skill_spent_points_by_kind(CHARACTER_SKILL_KIND_WEAPON))

/datum/mind/proc/get_attribute_physical_perk_points(attribute_id)
	var/total_points = 0
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_PHYSICAL || skill_datum.attribute_id != attribute_id)
			continue
		total_points += get_character_skill_spent_points(skill_type)
	return total_points

/datum/mind/proc/get_character_skill_level(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return known_skills[skill]?[SKILL_LVL] || SKILL_LEVEL_NONE
	if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_WEAPON)
		var/weapon_level = normalize_character_skill_number(character_skill_levels[skill])
		return clamp(weapon_level || CHARACTER_SKILL_LEVEL_NONE, CHARACTER_SKILL_LEVEL_NONE, skill_datum.max_character_level)

	var/skill_level = 0
	for(var/perk_index in 1 to length(skill_datum.perks))
		if(get_character_perk_rank(skill, perk_index) > 0)
			skill_level++
	return min(skill_level, skill_datum.max_character_level)

/datum/mind/proc/can_pay_character_skill_points(skill, point_delta, free = FALSE)
	point_delta = normalize_character_skill_number(point_delta)
	if(point_delta <= 0 || free)
		return TRUE
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return FALSE
	switch(skill_datum.point_pool)
		if(CHARACTER_SKILL_POOL_ATTRIBUTE)
			return get_attribute_physical_perk_points(skill_datum.attribute_id) + point_delta <= get_attribute_perk_point_limit(skill_datum.attribute_id)
		if(CHARACTER_SKILL_POOL_SKILL)
			switch(skill_datum.skill_kind)
				if(CHARACTER_SKILL_KIND_PROFESSIONAL)
					return professional_skill_points + skill_points >= point_delta
				if(CHARACTER_SKILL_KIND_WEAPON)
					return weapon_skill_points + skill_points >= point_delta
			return skill_points >= point_delta
	return TRUE

/datum/mind/proc/can_pay_character_skill_experience(skill, point_delta, free = FALSE)
	point_delta = normalize_character_skill_number(point_delta)
	if(point_delta <= 0 || free)
		return TRUE
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return FALSE
	var/current_points = get_character_skill_spent_points(skill)
	var/target_points = current_points + point_delta
	var/unlocked_points = FLOOR((converted_skill_experience[skill] || 0) / ATTRIBUTE_LEVEL_POINT_EXPERIENCE, 1)
	return target_points <= unlocked_points

/datum/mind/proc/pay_character_skill_points(skill, point_delta, free = FALSE)
	point_delta = normalize_character_skill_number(point_delta)
	if(point_delta == 0 || free)
		return
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return
	if(skill_datum.point_pool == CHARACTER_SKILL_POOL_SKILL)
		switch(skill_datum.skill_kind)
			if(CHARACTER_SKILL_KIND_PROFESSIONAL)
				var/professional_payment = min(point_delta, professional_skill_points)
				professional_skill_points -= professional_payment
				skill_points -= point_delta - professional_payment
			if(CHARACTER_SKILL_KIND_WEAPON)
				var/weapon_payment = min(point_delta, weapon_skill_points)
				weapon_skill_points -= weapon_payment
				skill_points -= point_delta - weapon_payment
			else
				skill_points -= point_delta

/datum/mind/proc/can_set_character_perk_rank(skill, perk_index, new_rank, free = FALSE, allow_sequence_break = FALSE, require_experience = FALSE)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE
	perk_index = normalize_character_skill_number(perk_index)
	if(perk_index < 1 || perk_index > length(skill_datum.perks))
		return FALSE
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.can_set_rank(src, new_rank, free, allow_sequence_break, require_experience)

/datum/mind/proc/set_character_perk_rank(skill, perk_index, new_rank, free = FALSE, allow_sequence_break = FALSE, require_experience = FALSE)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE
	perk_index = normalize_character_skill_number(perk_index)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.set_rank(src, new_rank, free, allow_sequence_break, require_experience)

/datum/mind/proc/adjust_character_perk_rank(skill, perk_index, amount = 1, free = FALSE, allow_sequence_break = FALSE, require_experience = FALSE)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE
	perk_index = normalize_character_skill_number(perk_index)
	amount = normalize_character_skill_number(amount)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.adjust_rank(src, amount, free, allow_sequence_break, require_experience)

/datum/mind/proc/has_character_perk(skill, perk_index, required_rank = 1)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE
	perk_index = normalize_character_skill_number(perk_index)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.has_rank(src, required_rank)

/datum/mind/proc/get_character_perk_effectiveness(skill, perk_index, effect_key = null)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return 0
	perk_index = normalize_character_skill_number(perk_index)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.get_effectiveness(src, effect_key) || 0

/datum/mind/proc/get_character_perk_effectiveness_by_type(perk_type, effect_key = null)
	if(!ispath(perk_type, /datum/skill_perk))
		return 0
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_datum = get_character_skill_datum(skill_type)
		if(!skill_datum || !skill_datum.uses_perks())
			continue
		for(var/perk_index in 1 to length(skill_datum.perks))
			var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
			if(perk?.type != perk_type)
				continue
			return perk.get_effectiveness(src, effect_key) || 0
	return 0

/datum/mind/proc/passes_character_perk_check(skill, perk_index, required_rank = 1, probability = 100)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE
	perk_index = normalize_character_skill_number(perk_index)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.passes_check(src, required_rank, probability)

/datum/mind/proc/get_character_perk_check_result(skill, perk_index, required_rank = 1, probability = 100)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.uses_perks())
		return list(
			"has_perk" = FALSE,
			"rank" = 0,
			"required_rank" = normalize_character_skill_number(required_rank),
			"effectiveness" = 0,
			"passed" = FALSE,
		)
	perk_index = normalize_character_skill_number(perk_index)
	var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
	return perk?.get_check_result(src, required_rank, probability)

/datum/mind/proc/set_character_skill_level(skill, new_level, free = FALSE, require_experience = FALSE)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return FALSE
	new_level = clamp(normalize_character_skill_number(new_level), CHARACTER_SKILL_LEVEL_NONE, skill_datum.max_character_level)
	if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_WEAPON)
		var/old_level = normalize_character_skill_number(character_skill_levels[skill])
		var/point_delta = new_level - old_level
		if(!can_pay_character_skill_points(skill, point_delta, free))
			return FALSE
		if(require_experience && !can_pay_character_skill_experience(skill, point_delta, free))
			return FALSE
		character_skill_levels[skill] = new_level
		pay_character_skill_points(skill, point_delta, free)
		return TRUE

	var/old_points = get_character_skill_spent_points(skill)
	var/point_delta = new_level - old_points
	if(!can_pay_character_skill_points(skill, point_delta, free))
		return FALSE
	if(require_experience && !can_pay_character_skill_experience(skill, point_delta, free))
		return FALSE
	var/list/perk_ranks = get_character_perk_list(skill)
	for(var/perk_index in 1 to length(skill_datum.perks))
		var/target_rank = perk_index <= new_level ? 1 : 0
		var/perk_key = get_character_perk_key(perk_index)
		if(target_rank)
			perk_ranks[perk_key] = target_rank
		else
			perk_ranks -= perk_key
	pay_character_skill_points(skill, point_delta, free)
	return TRUE

/datum/mind/proc/adjust_character_skill_level(skill, amount = 1, free = FALSE, require_experience = FALSE)
	amount = normalize_character_skill_number(amount)
	return set_character_skill_level(skill, get_character_skill_level(skill) + amount, free, require_experience)

/datum/mind/proc/get_character_skill_check_value(skill, modifier = 0, apply_body_penalty = TRUE)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || !skill_datum.is_character_skill())
		return clamp((get_skill_level(skill) * 10) + modifier, CHARACTER_SKILL_CHECK_MINIMUM, CHARACTER_SKILL_CHECK_MAXIMUM)
	var/mob/living/living_current
	if(isliving(current))
		living_current = current
	var/effective_skill_level = max(CHARACTER_SKILL_LEVEL_NONE, get_character_skill_level(skill) + get_cyberdemon_skill_modifier(skill))
	if(living_current)
		effective_skill_level += living_current.get_cyberpunk_status_skill_modifier(skill)
	var/attribute_value = get_attribute_value(skill_datum.attribute_id)
	if(living_current)
		attribute_value += living_current.get_cyberpunk_status_attribute_modifier(skill_datum.attribute_id)
	var/check_value = (effective_skill_level * 10) + (attribute_value * 5) + modifier + (living_current?.get_cyberpunk_status_check_modifier() || 0)
	if(apply_body_penalty && living_current)
		check_value *= (1 - living_current.get_check_penalty())
	return clamp(round(check_value), CHARACTER_SKILL_CHECK_MINIMUM, CHARACTER_SKILL_CHECK_MAXIMUM)

/datum/mind/proc/roll_character_skill_check(skill, difficulty = 0, modifier = 0, apply_body_penalty = TRUE)
	return prob(clamp(get_character_skill_check_value(skill, modifier, apply_body_penalty) - difficulty, CHARACTER_SKILL_CHECK_MINIMUM, CHARACTER_SKILL_CHECK_MAXIMUM))

/datum/mind/proc/get_character_perk_power_multiplier(skill, perk_index)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	return skill_datum ? skill_datum.get_perk_power_multiplier(get_character_perk_rank(skill, perk_index)) : 0

/datum/mind/proc/has_character_giga_perk(attribute_id)
	if(has_super_attribute(attribute_id) || !!character_giga_perks[attribute_id])
		return TRUE
	var/mob/living/living_current = isliving(current) ? current : null
	var/status_id = living_current?.get_character_giga_perk_status_id(attribute_id)
	return status_id && living_current.has_cyberpunk_status_effect(status_id)

/datum/mind/proc/grant_character_giga_perk(attribute_id)
	if(!(attribute_id in ATTRIBUTE_ALL))
		return FALSE
	character_giga_perks[attribute_id] = TRUE
	var/mob/living/living_current = isliving(current) ? current : null
	living_current?.sync_character_giga_perk_status_effects()
	return TRUE

/datum/mind/proc/revoke_character_giga_perk(attribute_id)
	character_giga_perks -= attribute_id
	var/mob/living/living_current = isliving(current) ? current : null
	living_current?.sync_character_giga_perk_status_effects()
	return TRUE

/datum/mind/proc/get_weapon_skill_damage_multiplier(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
		return 1
	return 1 + (get_character_skill_level(skill) * skill_datum.weapon_damage_bonus_per_level)

/datum/mind/proc/get_weapon_skill_cooldown_multiplier(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
		return 1
	return max(0, 1 - (get_character_skill_level(skill) * skill_datum.weapon_cooldown_reduction_per_level))

/datum/mind/proc/get_weapon_skill_defense_break_bonus(skill)
	var/datum/skill/skill_datum = get_character_skill_datum(skill)
	if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
		return 0
	return get_character_skill_level(skill) * skill_datum.weapon_defense_break_bonus_per_level

/datum/mind/proc/teach_character_skill(mob/living/student, skill, difficulty = 1, action_multiplier = 1)
	if(!student || !student.mind)
		return FALSE
	if(get_character_skill_level(skill) <= student.mind.get_character_skill_level(skill))
		return FALSE
	student.mind.reward_character_check_experience(skill, max(difficulty, 1), FALSE, action_multiplier)
	return TRUE

///Return the amount of EXP needed to go to the next level. Returns 0 if max level
/datum/mind/proc/exp_needed_to_level_up(skill)
	if(is_character_skill(skill))
		return 0
	var/lvl = update_skill_level(skill)
	if (lvl >= length(SKILL_EXP_LIST)) //If we're already past the last exp threshold
		return 0
	return SKILL_EXP_LIST[lvl+1] - known_skills[skill][SKILL_EXP]

///Adjust experience of a specific skill
/datum/mind/proc/adjust_experience(skill, amt, silent = FALSE, force_old_level = 0)
	var/datum/skill/S = GetSkillRef(skill)
	if(S && S.is_character_skill())
		experience_multiplier = initial(experience_multiplier)
		for(var/key in experience_multiplier_reasons)
			experience_multiplier += experience_multiplier_reasons[key]
		pending_skill_experience[skill] = max(0, (pending_skill_experience[skill] || 0) + (amt * experience_multiplier))
		return
	var/old_level = force_old_level ? force_old_level : known_skills[skill][SKILL_LVL] //Get current level of the S skill
	experience_multiplier = initial(experience_multiplier)
	for(var/key in experience_multiplier_reasons)
		experience_multiplier += experience_multiplier_reasons[key]
	known_skills[skill][SKILL_EXP] = max(0, known_skills[skill][SKILL_EXP] + amt*experience_multiplier) //Update exp. Prevent going below 0
	known_skills[skill][SKILL_LVL] = update_skill_level(skill)//Check what the current skill level is based on that skill's exp
	if(known_skills[skill][SKILL_LVL] > old_level)
		S.level_gained(src, known_skills[skill][SKILL_LVL], old_level, silent)
	else if(known_skills[skill][SKILL_LVL] < old_level)
		S.level_lost(src, known_skills[skill][SKILL_LVL], old_level, silent)

///Set experience of a specific skill to a number
/datum/mind/proc/set_experience(skill, amt, silent = FALSE)
	if(is_character_skill(skill))
		converted_skill_experience[skill] = max(0, amt)
		return
	var/old_level = known_skills[skill][SKILL_EXP]
	known_skills[skill][SKILL_EXP] = amt
	adjust_experience(skill, 0, silent, old_level) //Make a call to adjust_experience to handle updating level

///Set level of a specific skill
/datum/mind/proc/set_level(skill, newlevel, silent = FALSE)
	if(is_character_skill(skill))
		set_character_skill_level(skill, newlevel, TRUE)
		return
	var/oldlevel = get_skill_level(skill)
	var/difference = SKILL_EXP_LIST[newlevel] - SKILL_EXP_LIST[oldlevel]
	adjust_experience(skill, difference, silent)

///Check what the current skill level is based on that skill's exp
/datum/mind/proc/update_skill_level(skill)
	if(is_character_skill(skill))
		return get_character_skill_level(skill)
	var/i = 0
	for (var/exp in SKILL_EXP_LIST)
		i ++
		if (known_skills[skill][SKILL_EXP] >= SKILL_EXP_LIST[i])
			continue
		return i - 1 //Return level based on the last exp requirement that we were greater than
	return i //If we had greater EXP than even the last exp threshold, we return the last level

///Gets the skill's singleton and returns the result of its get_skill_modifier
/datum/mind/proc/get_skill_modifier(skill, modifier)
	var/datum/skill/S = GetSkillRef(skill)
	var/list/modifier_values = S.modifiers[modifier]
	if(!length(modifier_values))
		return 1
	var/level = get_skill_level(skill)
	if(S.is_character_skill())
		level++
	return S.get_skill_modifier(modifier, clamp(level, 1, length(modifier_values)))

///Gets the player's current level number from the relevant skill
/datum/mind/proc/get_skill_level(skill)
	if(is_character_skill(skill))
		return get_character_skill_level(skill)
	return known_skills[skill][SKILL_LVL]

///Gets the player's current exp from the relevant skill
/datum/mind/proc/get_skill_exp(skill)
	if(is_character_skill(skill))
		return converted_skill_experience[skill] || 0
	return known_skills[skill][SKILL_EXP]

/datum/mind/proc/get_skill_level_name(skill)
	var/level = get_skill_level(skill)
	if(is_character_skill(skill))
		return SSskills.character_level_names[level + 1]
	return SSskills.level_names[level]

/datum/mind/proc/print_levels(user)
	var/list/shown_skills = list()
	for(var/i in known_skills)
		if(is_character_skill(i) && get_character_skill_level(i) > CHARACTER_SKILL_LEVEL_NONE)
			shown_skills += i
		else if(!is_character_skill(i) && known_skills[i][SKILL_LVL] > SKILL_LEVEL_NONE) //Do we actually have a level in this?
			shown_skills += i
	if(!length(shown_skills))
		to_chat(user, span_notice("You don't seem to have any particularly outstanding skills."))
		return
	var/msg = "[span_info("<EM>Your skills</EM>")]\n<span class='notice'>"
	for(var/i in shown_skills)
		var/datum/skill/the_skill = i
		msg += "[initial(the_skill.name)] - [get_skill_level_name(the_skill)]\n"
	msg += "</span>"
	to_chat(user, boxed_message(msg))
