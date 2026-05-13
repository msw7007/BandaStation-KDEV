/datum/computer_file/program/skill_tracker
	filename = "skilltracker"
	filedesc = "ExperTrak Skill Tracker"
	downloader_category = PROGRAM_CATEGORY_DEVICE
	program_open_overlay = "generic"
	extended_desc = "Сканируйте и просматривайте свои текущие навыки работы на бирже труда."
	size = 2
	tgui_id = "NtosSkillTracker"
	program_icon = "medal"
	can_run_on_flags = PROGRAM_PDA // Must be a handheld device to read read your chakras or whatever

/datum/computer_file/program/skill_tracker/ui_data(mob/user)
	var/list/data = list()

	var/list/skills = list()
	data["skills"] = skills

	var/mob/living/target = user
	if(!istype(target))
		return data

	var/datum/cy_skill_holder/holder = target.ensure_cy_skill_holder()
	for(var/type in get_all_cy_skill_types())
		var/datum/cy_skill/skill = get_cy_skill_datum(type)
		if(!skill)
			continue
		var/lvl_num = target.get_cy_skill_level(type)
		var/exp = target.get_cy_skill_experience(type)
		var/max_exp = holder.get_total_experience_for_level(skill.max_level)
		var/list/skilldata = list(
			"name" = skill.name,
			"desc" = skill.desc,
			"title" = skill.category,
			"lvl_name" = uppertext(get_cy_skill_level_name(lvl_num)),
		)
		if(lvl_num < skill.max_level)
			var/xp_req_to_level = holder.get_experience_required_for_next_level(lvl_num)
			var/xp_prog = exp - holder.get_total_experience_for_level(lvl_num)
			if(xp_req_to_level)
				skilldata["progress_percent"] = clamp(xp_prog / xp_req_to_level, 0, 1)
		if(max_exp)
			skilldata["overall_percent"] = clamp(exp / max_exp, 0, 1)
		skills[++skills.len] = skilldata

	return data

/datum/computer_file/program/skill_tracker/proc/find_skilltype(name)
	for(var/type in get_all_cy_skill_types())
		var/datum/cy_skill/skill = get_cy_skill_datum(type)
		if(skill?.name == name || skill?.id == name)
			return type

	return null

/datum/computer_file/program/skill_tracker/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("PRG_reward")
			return TRUE
