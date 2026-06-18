/datum/preference_middleware/jobs
	action_delegations = list(
		"adjust_role_perk" = PROC_REF(adjust_role_perk),
		"adjust_role_skill_level" = PROC_REF(adjust_role_skill_level),
		"reset_role_preferences" = PROC_REF(reset_role_preferences),
		"set_job_preference" = PROC_REF(set_job_preference),
		"set_role_preview_job" = PROC_REF(set_role_preview_job),
		"set_role_custom_title" = PROC_REF(set_role_custom_title),
	)

/datum/preference_middleware/jobs/proc/set_role_preview_job(list/params, mob/user)
	var/atom/movable/screen/map_view/char_preview/preview = preferences.character_preview_view
	if(isnull(preview))
		return FALSE

	if(params["clear"])
		preview.preview_job_override = null
		preferences.loadout_preview_override = preferences.cyberpunk_build_assigned_loadout_preview_override()
		preview.update_body()
		return TRUE

	var/job_title = params["job"]
	var/datum/job/job = SSjob.get_job(job_title)
	if(isnull(job))
		return FALSE

	preview.preview_job_override = job
	preview.show_job_clothes = TRUE
	preferences.loadout_preview_override = preferences.cyberpunk_build_assigned_loadout_preview_override()
	preview.update_body()
	return TRUE

/datum/preference_middleware/jobs/proc/set_job_preference(list/params, mob/user)
	var/job_title = params["job"]
	var/level = params["level"]

	if (level != null && level != JP_LOW && level != JP_MEDIUM && level != JP_HIGH)
		return FALSE

	var/datum/job/job = SSjob.get_job(job_title)

	if (isnull(job))
		return FALSE

	if (job.faction != FACTION_STATION)
		return FALSE

	if (!preferences.set_job_preference_level(job, level))
		return FALSE

	preferences.character_preview_view?.update_body()

	return TRUE

/datum/preference_middleware/jobs/proc/reset_role_preferences(list/params, mob/user)
	preferences.job_preferences = list()
	preferences.character_preview_view?.update_body()
	return TRUE

/datum/preference_middleware/jobs/get_constant_data()
	var/list/data = list()

	var/list/departments = list()
	var/list/jobs = list()

	for (var/datum/job/job as anything in SSjob.joinable_occupations)
		if (job.job_flags & JOB_LATEJOIN_ONLY)
			continue
		var/datum/job_department/department_type = job.department_for_prefs || job.departments_list?[1]
		if (isnull(department_type))
			stack_trace("[job] does not have a department set, yet is a joinable occupation!")
			continue

		if (isnull(job.description))
			stack_trace("[job] does not have a description set, yet is a joinable occupation!")
			continue

		var/department_name = initial(department_type.department_name)
		if (isnull(departments[department_name]))
			var/datum/job/department_head_type = initial(department_type.department_head)

			departments[department_name] = list(
				"head" = department_head_type && initial(department_head_type.title),
			)

		jobs[job.title] = list(
			"description" = job.description,
			"department" = department_name,
			"supervisors" = job.supervisors,
			"paycheck" = job.paycheck,
			"paycheck_department" = job.paycheck_department,
			"total_positions" = job.total_positions,
			"spawn_positions" = job.spawn_positions,
			"cyberpunk_role" = job.cyberpunk_serialize_role_data(),
			"outfit_items" = serialize_outfit_preview(job),
		)

	data["departments"] = departments
	data["jobs"] = jobs

	return data

/datum/preference_middleware/jobs/proc/serialize_outfit_preview(datum/job/job)
	var/list/outfit_items = list()
	var/datum/outfit/outfit_type = job.outfit
	if(!ispath(outfit_type, /datum/outfit))
		return outfit_items

	add_outfit_preview_item(outfit_items, "ID", outfit_type::id, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Uniform", outfit_type::uniform, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Suit", outfit_type::suit, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Suit storage", outfit_type::suit_store, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Back", outfit_type::back, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Belt", outfit_type::belt, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Ears", outfit_type::ears, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Glasses", outfit_type::glasses, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Gloves", outfit_type::gloves, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Head", outfit_type::head, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Mask", outfit_type::mask, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Neck", outfit_type::neck, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Shoes", outfit_type::shoes, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Left pocket", outfit_type::l_pocket, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Right pocket", outfit_type::r_pocket, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Left hand", outfit_type::l_hand, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Right hand", outfit_type::r_hand, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Accessory", outfit_type::accessory, "job outfit", TRUE)
	add_outfit_preview_item(outfit_items, "Survival box", outfit_type::box, "job outfit", TRUE)

	for(var/item_type in outfit_type::backpack_contents)
		add_outfit_preview_item(outfit_items, "Backpack", item_type, "backpack contents", FALSE, outfit_type::backpack_contents[item_type])
	for(var/item_type in outfit_type::belt_contents)
		add_outfit_preview_item(outfit_items, "Belt", item_type, "belt contents", FALSE, outfit_type::belt_contents[item_type])
	for(var/item_type in outfit_type::implants)
		add_outfit_preview_item(outfit_items, "Implant", item_type, "job implant", TRUE)
	for(var/item_type in outfit_type::skillchips)
		add_outfit_preview_item(outfit_items, "Skillchip", item_type, "job skillchip", TRUE)

	return outfit_items

/datum/preference_middleware/jobs/proc/add_outfit_preview_item(list/outfit_items, slot, item_type, source, guaranteed = TRUE, amount = 1)
	if(!ispath(item_type, /obj/item))
		return
	var/obj/item/item_path = item_type
	if(!isnum(amount) || amount < 1)
		amount = 1
	for(var/index in 1 to amount)
		outfit_items += list(list(
			"slot" = slot,
			"item_name" = item_path::name,
			"item_type" = "[item_type]",
			"icon" = item_path::icon_preview || item_path::icon,
			"icon_state" = item_path::icon_state_preview || item_path::icon_state,
			"source" = source,
			"guaranteed" = guaranteed,
			"warning" = guaranteed ? null : "Stored item; final placement depends on outfit/loadout equip logic.",
		))

/datum/preference_middleware/jobs/get_ui_data(mob/user)
	var/list/data = list()

	data["is_admin"] = is_admin(user.client)
	data["job_preferences"] = preferences.job_preferences
	data["character_role_setups"] = serialize_character_role_setups(user)

	return data

/datum/preference_middleware/jobs/proc/get_role_setup(job_title)
	if(!preferences.character_role_setups[job_title])
		preferences.character_role_setups[job_title] = list()
	return preferences.character_role_setups[job_title]

/datum/preference_middleware/jobs/proc/prune_role_setup(job_title)
	var/list/setup = preferences.character_role_setups[job_title]
	if(!islist(setup))
		preferences.character_role_setups -= job_title
		return
	for(var/key in setup.Copy())
		if(islist(setup[key]) && !length(setup[key]))
			setup -= key
		else if(!setup[key])
			setup -= key
	if(!length(setup))
		preferences.character_role_setups -= job_title

/datum/preference_middleware/jobs/proc/adjust_role_perk(list/params, mob/user)
	var/job_title = params["job"]
	var/datum/job/job = SSjob.get_job(job_title)
	if(!job || job.faction != FACTION_STATION)
		return FALSE

	var/datum/mind/user_mind = user?.mind
	if(!user_mind)
		return FALSE

	var/skill_type = text2path(params["skill"])
	if(!ispath(skill_type, /datum/skill))
		return FALSE
	var/datum/skill/skill_datum = GetSkillRef(skill_type)
	if(!skill_datum || !skill_datum.uses_perks() || !(skill_datum.skill_kind in list(CHARACTER_SKILL_KIND_PHYSICAL, CHARACTER_SKILL_KIND_PROFESSIONAL)))
		return FALSE

	var/raw_perk_index = params["perk_index"]
	var/perk_index = round(text2num("[raw_perk_index]") || 0)
	var/raw_delta = params["delta"]
	var/delta = round(text2num("[raw_delta]") || 0)
	if(perk_index < 1 || perk_index > length(skill_datum.perks) || !delta)
		return FALSE

	var/list/setup = get_role_setup(job.title)
	var/list/perks = setup["perks"]
	if(!islist(perks))
		perks = list()
		setup["perks"] = perks
	var/skill_key = "[skill_type]"
	var/list/skill_perks = perks[skill_key]
	if(!islist(skill_perks))
		skill_perks = list()
		perks[skill_key] = skill_perks

	var/perk_key = "[perk_index]"
	var/base_rank = user_mind.get_character_perk_rank(skill_type, perk_index)
	var/bonus_rank = clamp(round(skill_perks[perk_key] || 0), 0, skill_datum.max_perk_rank)
	var/effective_rank = base_rank + bonus_rank
	if(delta > 0)
		switch(skill_datum.skill_kind)
			if(CHARACTER_SKILL_KIND_PHYSICAL)
				if(get_role_physical_points_spent(setup, skill_datum.attribute_id) >= get_role_attribute_bonus(job, skill_datum.attribute_id))
					return FALSE
			if(CHARACTER_SKILL_KIND_PROFESSIONAL)
				if(get_role_professional_points_spent(setup) >= job.cyberpunk_role_professional_skill_points)
					return FALSE
		if(!can_role_skill_use_attribute(user_mind, setup, job, skill_datum, skill_type, 1))
			return FALSE
		if(effective_rank >= skill_datum.max_perk_rank)
			return FALSE
		if(skill_datum.requires_sequential_perks && perk_index > 1 && get_effective_role_perk_rank(user_mind, setup, skill_type, perk_index - 1) <= 0)
			return FALSE
		skill_perks[perk_key] = bonus_rank + 1
	else
		if(bonus_rank <= 0)
			return FALSE
		if(skill_datum.requires_sequential_perks && effective_rank <= 1 && has_later_effective_role_perk(user_mind, setup, skill_type, perk_index, length(skill_datum.perks)))
			return FALSE
		if(bonus_rank <= 1)
			skill_perks -= perk_key
		else
			skill_perks[perk_key] = bonus_rank - 1

	prune_role_setup(job.title)
	preferences.save_character()
	return TRUE

/datum/preference_middleware/jobs/proc/adjust_role_skill_level(list/params, mob/user)
	var/job_title = params["job"]
	var/datum/job/job = SSjob.get_job(job_title)
	if(!job || job.faction != FACTION_STATION)
		return FALSE

	var/datum/mind/user_mind = user?.mind
	if(!user_mind)
		return FALSE

	var/skill_type = text2path(params["skill"])
	if(!ispath(skill_type, /datum/skill))
		return FALSE
	var/datum/skill/skill_datum = GetSkillRef(skill_type)
	if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
		return FALSE

	var/raw_delta = params["delta"]
	var/delta = round(text2num("[raw_delta]") || 0)
	if(!delta)
		return FALSE

	var/list/setup = get_role_setup(job.title)
	var/list/skill_levels = setup["skill_levels"]
	if(!islist(skill_levels))
		skill_levels = list()
		setup["skill_levels"] = skill_levels

	var/skill_key = "[skill_type]"
	var/base_level = user_mind.get_character_skill_level(skill_type)
	var/bonus_level = clamp(round(skill_levels[skill_key] || 0), 0, skill_datum.max_character_level)
	if(delta > 0)
		if(get_role_weapon_points_spent(setup) >= job.cyberpunk_role_weapon_skill_points)
			return FALSE
		if(!can_role_skill_use_attribute(user_mind, setup, job, skill_datum, skill_type, 1))
			return FALSE
		if(base_level + bonus_level >= skill_datum.max_character_level)
			return FALSE
		skill_levels[skill_key] = bonus_level + 1
	else
		if(bonus_level <= 0)
			return FALSE
		if(bonus_level <= 1)
			skill_levels -= skill_key
		else
			skill_levels[skill_key] = bonus_level - 1

	prune_role_setup(job.title)
	preferences.save_character()
	return TRUE

/datum/preference_middleware/jobs/proc/set_role_custom_title(list/params, mob/user)
	var/job_title = params["job"]
	var/datum/job/job = SSjob.get_job(job_title)
	if(!job || !job.cyberpunk_allow_custom_title)
		return FALSE

	var/list/setup = get_role_setup(job.title)
	var/custom_title = preferences.sanitize_role_custom_title(params["title"])
	if(custom_title)
		setup["custom_title"] = custom_title
	else
		setup -= "custom_title"

	prune_role_setup(job.title)
	preferences.save_character()
	return TRUE

/datum/preference_middleware/jobs/proc/serialize_character_role_setups(mob/user)
	var/list/role_setups = list()
	for(var/datum/job/job as anything in SSjob.joinable_occupations)
		if(job.job_flags & JOB_LATEJOIN_ONLY)
			continue
		var/list/setup = preferences.character_role_setups[job.title]
		if(!islist(setup))
			setup = list()
		role_setups[job.title] = serialize_character_role_setup(user, job, setup)
	return role_setups

/datum/preference_middleware/jobs/proc/serialize_character_role_setup(mob/user, datum/job/job, list/setup)
	var/datum/mind/user_mind = user?.mind
	var/list/attribute_bonuses = job.get_cyberpunk_role_attribute_point_limits()
	var/attribute_points_max = job.get_cyberpunk_role_attribute_points()
	var/list/attributes = list()
	for(var/attribute_id in ATTRIBUTE_ALL)
		var/base_value = user_mind?.get_attribute_value(attribute_id) || ATTRIBUTE_DEFAULT
		var/bonus_value = clamp(round(attribute_bonuses[attribute_id] || 0), 0, ATTRIBUTE_MAXIMUM - ATTRIBUTE_MINIMUM)
		attributes[attribute_id] = list(
			"base_value" = base_value,
			"bonus" = bonus_value,
			"value" = min(ATTRIBUTE_MAXIMUM, base_value + bonus_value),
			"can_increase" = FALSE,
			"can_decrease" = FALSE,
		)

	var/list/skills = list()
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || !skill_datum.is_character_skill())
			continue
		if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_PHYSICAL || skill_datum.skill_kind == CHARACTER_SKILL_KIND_PROFESSIONAL)
			var/list/perks = list()
			if(skill_datum.uses_perks())
				for(var/perk_index in 1 to length(skill_datum.perks))
					var/base_rank = user_mind?.get_character_perk_rank(skill_type, perk_index) || 0
					var/bonus_rank = get_role_perk_bonus(setup, skill_type, perk_index)
					var/effective_rank = min(skill_datum.max_perk_rank, base_rank + bonus_rank)
					perks["[perk_index]"] = list(
						"rank" = effective_rank,
						"base_rank" = base_rank,
						"bonus" = bonus_rank,
						"can_increase" = can_increase_role_perk(user_mind, setup, job, skill_datum, skill_type, perk_index),
						"can_decrease" = bonus_rank > 0 && can_decrease_role_perk(user_mind, setup, skill_datum, skill_type, perk_index),
					)
			skills["[skill_type]"] = list(
				"level" = min(skill_datum.max_character_level, get_effective_role_skill_level(user_mind, setup, skill_type)),
				"spent_points" = user_mind?.get_character_skill_spent_points(skill_type) || 0,
				"bonus_points" = get_role_skill_bonus_points(setup, skill_type),
				"perks" = perks,
				"can_increase" = FALSE,
				"can_decrease" = FALSE,
				"editable" = TRUE,
			)
		else if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_WEAPON)
			var/base_level = user_mind?.get_character_skill_level(skill_type) || CHARACTER_SKILL_LEVEL_NONE
			var/bonus_level = get_role_weapon_skill_bonus(setup, skill_type)
			skills["[skill_type]"] = list(
				"level" = min(skill_datum.max_character_level, base_level + bonus_level),
				"base_level" = base_level,
				"bonus_points" = bonus_level,
				"spent_points" = base_level,
				"perks" = list(),
				"can_increase" = get_role_weapon_points_spent(setup) < job.cyberpunk_role_weapon_skill_points && can_role_skill_use_attribute(user_mind, setup, job, skill_datum, skill_type, 1) && base_level + bonus_level < skill_datum.max_character_level,
				"can_decrease" = bonus_level > 0,
				"editable" = TRUE,
			)

	return list(
		"attributes" = attributes,
		"skills" = skills,
		"attribute_points" = max(0, attribute_points_max - get_role_physical_points_spent_total(setup, job)),
		"attribute_points_max" = attribute_points_max,
		"professional_skill_points" = max(0, job.cyberpunk_role_professional_skill_points - get_role_professional_points_spent(setup)),
		"professional_skill_points_max" = job.cyberpunk_role_professional_skill_points,
		"weapon_skill_points" = max(0, job.cyberpunk_role_weapon_skill_points - get_role_weapon_points_spent(setup)),
		"weapon_skill_points_max" = job.cyberpunk_role_weapon_skill_points,
		"custom_title" = setup["custom_title"],
		"can_rename" = job.cyberpunk_allow_custom_title,
	)

/datum/preference_middleware/jobs/proc/get_role_professional_points_spent(list/setup)
	var/total = 0
	var/list/perks = setup["perks"]
	if(!islist(perks))
		return 0
	for(var/skill_key in perks)
		var/skill_type = text2path(skill_key)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_PROFESSIONAL)
			continue
		var/list/skill_perks = perks[skill_key]
		if(!islist(skill_perks))
			continue
		for(var/perk_key in skill_perks)
			total += max(0, round(skill_perks[perk_key] || 0))
	return total

/datum/preference_middleware/jobs/proc/get_role_weapon_points_spent(list/setup)
	var/total = 0
	var/list/skill_levels = setup["skill_levels"]
	if(!islist(skill_levels))
		return 0
	for(var/skill_key in skill_levels)
		var/skill_type = text2path(skill_key)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
			continue
		total += max(0, round(skill_levels[skill_key] || 0))
	return total

/datum/preference_middleware/jobs/proc/get_role_physical_points_spent(list/setup, attribute_id)
	var/total = 0
	var/list/perks = setup["perks"]
	if(!islist(perks))
		return 0
	for(var/skill_key in perks)
		var/skill_type = text2path(skill_key)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_PHYSICAL || skill_datum.attribute_id != attribute_id)
			continue
		var/list/skill_perks = perks[skill_key]
		if(!islist(skill_perks))
			continue
		for(var/perk_key in skill_perks)
			total += max(0, round(skill_perks[perk_key] || 0))
	return total

/datum/preference_middleware/jobs/proc/get_role_physical_points_spent_total(list/setup, datum/job/job)
	var/total = 0
	var/list/attribute_bonuses = job.get_cyberpunk_role_attribute_point_limits()
	for(var/attribute_id in attribute_bonuses)
		total += get_role_physical_points_spent(setup, attribute_id)
	return total

/datum/preference_middleware/jobs/proc/get_role_attribute_bonus(datum/job/job, attribute_id)
	var/list/attribute_bonuses = job.get_cyberpunk_role_attribute_point_limits()
	return max(0, round(attribute_bonuses[attribute_id] || 0))

/datum/preference_middleware/jobs/proc/get_role_perk_bonus(list/setup, skill, perk_index)
	var/list/perks = setup["perks"]
	if(!islist(perks))
		return 0
	var/list/skill_perks = perks["[skill]"]
	if(!islist(skill_perks))
		return 0
	return max(0, round(skill_perks["[perk_index]"] || 0))

/datum/preference_middleware/jobs/proc/get_role_skill_bonus_points(list/setup, skill)
	var/list/perks = setup["perks"]
	if(!islist(perks))
		return 0
	var/list/skill_perks = perks["[skill]"]
	if(!islist(skill_perks))
		return 0
	var/total = 0
	for(var/perk_key in skill_perks)
		total += max(0, round(skill_perks[perk_key] || 0))
	return total

/datum/preference_middleware/jobs/proc/get_role_weapon_skill_bonus(list/setup, skill)
	var/list/skill_levels = setup["skill_levels"]
	if(!islist(skill_levels))
		return 0
	return max(0, round(skill_levels["[skill]"] || 0))

/datum/preference_middleware/jobs/proc/get_effective_role_perk_rank(datum/mind/user_mind, list/setup, skill, perk_index)
	return (user_mind?.get_character_perk_rank(skill, perk_index) || 0) + get_role_perk_bonus(setup, skill, perk_index)

/datum/preference_middleware/jobs/proc/get_effective_role_skill_level(datum/mind/user_mind, list/setup, skill)
	var/datum/skill/skill_datum = GetSkillRef(skill)
	if(!skill_datum)
		return 0
	if(skill_datum.skill_kind == CHARACTER_SKILL_KIND_WEAPON)
		return (user_mind?.get_character_skill_level(skill) || 0) + get_role_weapon_skill_bonus(setup, skill)
	var/level = 0
	for(var/perk_index in 1 to length(skill_datum.perks))
		if(get_effective_role_perk_rank(user_mind, setup, skill, perk_index) > 0)
			level++
	return level

/datum/preference_middleware/jobs/proc/get_effective_role_attribute_value(datum/mind/user_mind, datum/job/job, attribute_id)
	var/list/attribute_bonuses = job.get_cyberpunk_role_attribute_point_limits()
	var/base_value = user_mind?.get_attribute_value(attribute_id) || ATTRIBUTE_DEFAULT
	return min(ATTRIBUTE_MAXIMUM, base_value + max(0, round(attribute_bonuses[attribute_id] || 0)))

/datum/preference_middleware/jobs/proc/can_role_skill_use_attribute(datum/mind/user_mind, list/setup, datum/job/job, datum/skill/skill_datum, skill, point_delta)
	if(!skill_datum?.attribute_id)
		return TRUE
	var/effective_attribute_value = get_effective_role_attribute_value(user_mind, job, skill_datum.attribute_id)
	var/current_points = 0
	switch(skill_datum.skill_kind)
		if(CHARACTER_SKILL_KIND_PHYSICAL)
			current_points = (user_mind?.get_attribute_physical_perk_points(skill_datum.attribute_id) || 0) + get_role_physical_points_spent(setup, skill_datum.attribute_id)
		if(CHARACTER_SKILL_KIND_PROFESSIONAL)
			current_points = (user_mind?.get_character_skill_spent_points(skill) || 0) + get_role_skill_bonus_points(setup, skill)
		if(CHARACTER_SKILL_KIND_WEAPON)
			current_points = (user_mind?.get_character_skill_spent_points(skill) || 0) + get_role_weapon_skill_bonus(setup, skill)
		else
			return TRUE
	return current_points + max(0, point_delta) <= effective_attribute_value

/datum/preference_middleware/jobs/proc/has_later_effective_role_perk(datum/mind/user_mind, list/setup, skill, perk_index, max_perk_index)
	if(perk_index >= max_perk_index)
		return FALSE
	for(var/later_index in (perk_index + 1) to max_perk_index)
		if(get_effective_role_perk_rank(user_mind, setup, skill, later_index) > 0)
			return TRUE
	return FALSE

/datum/preference_middleware/jobs/proc/can_increase_role_perk(datum/mind/user_mind, list/setup, datum/job/job, datum/skill/skill_datum, skill, perk_index)
	if(!user_mind)
		return FALSE
	switch(skill_datum.skill_kind)
		if(CHARACTER_SKILL_KIND_PHYSICAL)
			if(get_role_physical_points_spent(setup, skill_datum.attribute_id) >= get_role_attribute_bonus(job, skill_datum.attribute_id))
				return FALSE
		if(CHARACTER_SKILL_KIND_PROFESSIONAL)
			if(get_role_professional_points_spent(setup) >= job.cyberpunk_role_professional_skill_points)
				return FALSE
		else
			return FALSE
	if(!can_role_skill_use_attribute(user_mind, setup, job, skill_datum, skill, 1))
		return FALSE
	var/effective_rank = get_effective_role_perk_rank(user_mind, setup, skill, perk_index)
	if(effective_rank >= skill_datum.max_perk_rank)
		return FALSE
	if(skill_datum.requires_sequential_perks && perk_index > 1 && get_effective_role_perk_rank(user_mind, setup, skill, perk_index - 1) <= 0)
		return FALSE
	return TRUE

/datum/preference_middleware/jobs/proc/can_decrease_role_perk(datum/mind/user_mind, list/setup, datum/skill/skill_datum, skill, perk_index)
	var/effective_rank = get_effective_role_perk_rank(user_mind, setup, skill, perk_index)
	if(skill_datum.requires_sequential_perks && effective_rank <= 1 && has_later_effective_role_perk(user_mind, setup, skill, perk_index, length(skill_datum.perks)))
		return FALSE
	return TRUE

/datum/preference_middleware/jobs/get_ui_static_data(mob/user)
	var/list/data = list()

	var/list/required_job_playtime = get_required_job_playtime(user)
	if (!isnull(required_job_playtime))
		data += required_job_playtime

	var/list/job_bans = get_job_bans(user)
	if (job_bans.len)
		data["job_bans"] = job_bans

	return data.len > 0 ? data : null

/datum/preference_middleware/jobs/proc/get_required_job_playtime(mob/user)
	var/list/data = list()

	var/list/job_days_left = list()
	var/list/job_required_experience = list()

	for (var/datum/job/job as anything in SSjob.all_occupations)
		if (job.job_flags & JOB_LATEJOIN_ONLY)
			continue
		var/required_playtime_remaining = job.required_playtime_remaining(user.client)
		if (required_playtime_remaining)
			job_required_experience[job.title] = list(
				"experience_type" = job.get_exp_req_type(),
				"required_playtime" = required_playtime_remaining,
			)

			continue

		if (!job.player_old_enough(user.client))
			job_days_left[job.title] = job.available_in_days(user.client)

	if (job_days_left.len)
		data["job_days_left"] = job_days_left

	if (job_required_experience)
		data["job_required_experience"] = job_required_experience

	return data

/datum/preference_middleware/jobs/proc/get_job_bans(mob/user)
	var/list/data = list()

	for (var/datum/job/job as anything in SSjob.all_occupations)
		if (is_banned_from(user.client?.ckey, job.title))
			data += job.title

	return data
