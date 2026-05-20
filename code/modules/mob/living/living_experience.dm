/mob/living/proc/get_cy_skill_experience(skill_type)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.get_skill_experience(skill_type)

/mob/living/proc/set_cy_skill_experience(skill_type, experience)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_experience(skill_type, experience)

/mob/living/proc/adjust_cy_skill_experience(skill_type, amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_skill_experience(skill_type, skills.get_skill_experience(skill_type) + amount)

/mob/living/proc/award_cy_raw_skill_experience(skill_type, amount, experience_modifier = 1)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.award_raw_skill_experience(skill_type, amount, experience_modifier)

/mob/living/proc/process_cy_awake_training_experience(seconds_per_tick, mood_modifier = 1)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.process_awake_training_experience(seconds_per_tick, mood_modifier)

/mob/living/proc/digest_cy_experience()
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.digest_experience()

/mob/living/proc/set_cy_experience_multiplier(source, amount)
	var/datum/cy_skill_holder/skills = ensure_cy_skill_holder()
	return skills.set_experience_multiplier(source, amount)

/datum/cy_skill_holder/proc/get_experience_required_for_next_level(current_level)
	return CY_EXPERIENCE_THRESHOLD_BASE + (CY_EXPERIENCE_THRESHOLD_PER_LEVEL * max(current_level, 0))

/datum/cy_skill_holder/proc/get_total_experience_for_level(level)
	if(level <= CY_SKILL_MINIMUM_LEVEL)
		return 0

	var/total = 0
	for(var/current_level in CY_SKILL_MINIMUM_LEVEL to (level - 1))
		total += get_experience_required_for_next_level(current_level)
	return total

/datum/cy_skill_holder/proc/get_skill_experience(skill_type)
	if(!is_valid_skill(skill_type))
		return 0

	return skill_experience[skill_type] || 0

/datum/cy_skill_holder/proc/get_skill_level_from_experience(skill_type, experience)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return CY_SKILL_MINIMUM_LEVEL

	var/level = CY_SKILL_MINIMUM_LEVEL
	var/remaining_experience = max(0, round(experience))
	while(level < skill.max_level)
		var/needed_experience = get_experience_required_for_next_level(level)
		if(remaining_experience < needed_experience)
			break
		remaining_experience -= needed_experience
		level++

	return clamp(level, CY_SKILL_MINIMUM_LEVEL, skill.max_level)

/datum/cy_skill_holder/proc/get_unlocked_skill_level(skill_type)
	if(!is_valid_skill(skill_type))
		return CY_SKILL_MINIMUM_LEVEL
	return max(get_skill_level(skill_type), skill_level_gates[skill_type] || CY_SKILL_MINIMUM_LEVEL)

/datum/cy_skill_holder/proc/get_distributable_experience_cost_for_skill_level(level)
	return 1

/datum/cy_skill_holder/proc/set_skill_experience(skill_type, experience)
	if(!is_valid_skill(skill_type))
		return FALSE

	experience = max(0, round(experience))
	if(!experience)
		skill_experience -= skill_type
	else
		skill_experience[skill_type] = experience

	return TRUE

/datum/cy_skill_holder/proc/set_experience_multiplier(source, amount)
	if(isnull(source))
		return FALSE
	if(!amount)
		experience_multiplier_reasons -= source
	else
		experience_multiplier_reasons[source] = amount
	return TRUE

/datum/cy_skill_holder/proc/award_raw_skill_experience(skill_type, amount, experience_modifier = 1)
	if(!is_valid_skill(skill_type) || !amount)
		return 0

	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill || (amount > 0 && get_skill_level(skill_type) >= skill.max_level))
		return 0

	if(isliving(owner))
		var/mob/living/living_owner = owner
		amount *= living_owner.get_cy_experience_context_multiplier()
	amount *= experience_modifier
	var/multiplier = 1
	for(var/source in experience_multiplier_reasons)
		multiplier += experience_multiplier_reasons[source]
	amount = round(amount * max(0, multiplier))
	if(!amount)
		return 0

	amount = modify_experience_gain_by_perks(skill_type, amount)
	if(skill.limited_by_stat)
		var/level_experience_amount = round(amount * 0.5)
		if(amount > 0)
			level_experience_amount = max(1, level_experience_amount)
		if(level_experience_amount)
			general_experience = max(0, round(general_experience + level_experience_amount))
		return amount

	var/skill_experience_amount = round(amount * CY_SKILL_EXPERIENCE_SHARE)
	var/general_experience_amount = round(amount * CY_STAT_EXPERIENCE_SHARE)
	if(amount > 0)
		skill_experience_amount = max(1, skill_experience_amount)
		general_experience_amount = max(0, general_experience_amount)

	if(!set_skill_experience(skill_type, get_skill_experience(skill_type) + skill_experience_amount))
		return 0

	if(general_experience_amount)
		general_experience = max(0, round(general_experience + general_experience_amount))

	return amount

/datum/cy_skill_holder/proc/digest_experience()
	var/new_level = 1
	var/remaining_experience = max(0, round(general_experience))
	while(remaining_experience >= get_experience_required_for_next_level(new_level))
		remaining_experience -= get_experience_required_for_next_level(new_level)
		new_level++

	var/digested = 0
	if(new_level > character_level)
		digested += new_level - character_level
		stat_points += new_level - character_level
		character_level = new_level

	for(var/skill_type in get_all_cy_skill_types())
		var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
		if(!skill)
			continue
		var/current_gate = get_unlocked_skill_level(skill_type)
		var/potential_level = get_skill_level_from_experience(skill_type, get_skill_experience(skill_type))
		if(potential_level <= current_gate)
			continue
		var/unlocked_levels = potential_level - current_gate
		skill_level_gates[skill_type] = potential_level
		distributable_experience = max(0, round(distributable_experience + unlocked_levels))
		digested += unlocked_levels
	return digested

/datum/cy_skill_holder/proc/spend_distributable_experience_on_skill(skill_type, amount, ignore_stat_limit = FALSE)
	if(!is_valid_skill(skill_type))
		return 0

	amount = min(max(0, round(amount)), distributable_experience)
	if(!amount)
		return 0

	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return 0

	var/spent = 0
	while(amount > 0)
		var/target_level = get_skill_level(skill_type) + 1
		target_level = clamp(round(target_level), CY_SKILL_MINIMUM_LEVEL, skill.max_level)
		var/cost = get_distributable_experience_cost_for_skill_level(target_level)
		if(cost > amount)
			break
		if(get_unlocked_skill_level(skill_type) < target_level)
			break
		if(!ignore_stat_limit && !can_set_skill_level(skill_type, target_level))
			break
		if(!set_skill_level(skill_type, target_level, ignore_stat_limit))
			break
		distributable_experience -= cost
		amount -= cost
		spent += cost

	return spent

/datum/cy_skill_holder/proc/process_awake_training_experience(seconds_per_tick, mood_modifier = 1)
	if(seconds_per_tick <= 0)
		return 0

	awake_training_experience_timer += seconds_per_tick * 10
	if(awake_training_experience_timer < CY_AWAKE_TRAINING_EXPERIENCE_INTERVAL)
		return 0

	var/ticks = FLOOR(awake_training_experience_timer / CY_AWAKE_TRAINING_EXPERIENCE_INTERVAL, 1)
	awake_training_experience_timer -= ticks * CY_AWAKE_TRAINING_EXPERIENCE_INTERVAL
	var/experience = max(1, round(ticks * CY_AWAKE_TRAINING_EXPERIENCE_AMOUNT * max(mood_modifier, 0)))
	general_experience = max(0, round(general_experience + experience))
	return experience

/datum/cy_skill_holder/proc/spend_stat_point_on_stat(stat_type)
	if(!stat_holder?.is_valid_stat(stat_type))
		return FALSE
	if(stat_points <= 0)
		return FALSE
	if(stat_holder.get_base_stat(stat_type) >= CY_STAT_MAXIMUM)
		return FALSE

	stat_points--
	return stat_holder.adjust_base_stat(stat_type, 1)

/datum/cy_skill_holder/proc/convert_stat_point_to_skill_points()
	if(stat_points <= 0)
		return FALSE

	stat_points--
	distributable_experience += 2
	return TRUE

/datum/cy_skill_holder/proc/convert_skill_points_to_stat_point()
	if(distributable_experience < 2)
		return FALSE

	distributable_experience -= 2
	stat_points++
	return TRUE
