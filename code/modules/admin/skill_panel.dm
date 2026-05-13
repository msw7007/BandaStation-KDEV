/datum/skill_panel
	var/datum/mind/targetmind
	var/client/holder //client of whoever is using this datum

/datum/skill_panel/New(user, datum/mind/mind)//H can either be a client or a mob due to byondcode(tm)
	targetmind = mind
	if (istype(user,/client))
		var/client/userClient = user
		holder = userClient //if its a client, assign it to holder
	else
		var/mob/userMob = user
		holder = userMob.client //if its a mob, assign the mob's client to holder

/datum/skill_panel/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/skill_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SkillPanel")
		ui.open()

/datum/skill_panel/ui_data(mob/user) //Sends info about the skills to UI
	. = list()
	.["skills"] = list()
	var/mob/living/target = targetmind?.current
	if(!istype(target))
		return

	var/datum/cy_skill_holder/holder = target.ensure_cy_skill_holder()
	for(var/type in get_all_cy_skill_types())
		var/datum/cy_skill/skill = get_cy_skill_datum(type)
		if(!skill)
			continue
		var/lvl_num = target.get_cy_skill_level(type)
		var/lvl_name = uppertext(get_cy_skill_level_name(lvl_num))
		var/exp = target.get_cy_skill_experience(type)
		var/xp_req_to_level = 0
		var/exp_prog = 0
		if(lvl_num < skill.max_level)
			xp_req_to_level = holder.get_experience_required_for_next_level(lvl_num)
			exp_prog = exp - holder.get_total_experience_for_level(lvl_num)
		var/max_exp = holder.get_total_experience_for_level(skill.max_level)
		var/exp_percent = max_exp ? clamp(exp / max_exp, 0, 1) : 1
		.["skills"] += list(list(
			"playername" = target,
			"path" = type,
			"name" = skill.name,
			"desc" = skill.desc,
			"lvlnum" = lvl_num,
			"lvl" = lvl_name,
			"exp" = exp,
			"exp_prog" = exp_prog,
			"exp_req" = xp_req_to_level,
			"exp_percent" = exp_percent,
			"max_exp" = max_exp,
		))

/datum/skill_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch (action)
		if ("adj_exp")
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the amount of experience you'd like to add/subtract:") as num|null
			var/mob/living/target = targetmind?.current
			if (number && istype(target))
				target.adjust_cy_skill_experience(skill, number, TRUE, TRUE, null)
		if ("set_exp")
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the number you want to set the player's exp to:") as num|null
			var/mob/living/target = targetmind?.current
			if (!isnull(number) && istype(target))
				target.set_cy_skill_experience(skill, number, TRUE, TRUE, null)
		if ("set_lvl")
			var/skill = text2path(params["skill"])
			var/mob/living/target = targetmind?.current
			var/datum/cy_skill/skill_datum = get_cy_skill_datum(skill)
			if(!istype(target) || !skill_datum)
				return
			var/number = input("Please insert a whole number between 0 (UNTRAINED) and [skill_datum.max_level] (MASTER) corresponding to the level you'd like to set the player to.") as num|null
			if (!isnull(number) && number >= CY_SKILL_MINIMUM_LEVEL && number <= skill_datum.max_level)
				target.set_cy_skill_level(skill, number, TRUE)
