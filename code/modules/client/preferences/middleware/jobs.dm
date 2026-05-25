/datum/preference_middleware/jobs
	action_delegations = list(
		"reset_role_preferences" = PROC_REF(reset_role_preferences),
		"set_job_preference" = PROC_REF(set_job_preference),
	)

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

	data["job_preferences"] = preferences.job_preferences

	return data

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
