/datum/cy_character_progression_panel
	var/mob/living/owner

/datum/cy_character_progression_panel/New(mob/living/new_owner)
	. = ..()
	owner = new_owner

/datum/cy_character_progression_panel/Destroy()
	owner = null
	return ..()

/datum/cy_character_progression_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/cy_character_progression_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyCharacterProgression", "Character")
		ui.open()

/datum/cy_character_progression_panel/ui_data(mob/user)
	var/list/data = list()
	if(!istype(owner))
		return data

	var/datum/cy_skill_holder/skills = owner.ensure_cy_skill_holder()
	var/datum/cy_stat_holder/stats = owner.ensure_cy_stat_holder()
	data["stat_points"] = skills.stat_points
	data["skill_points"] = skills.distributable_experience
	data["general_experience"] = skills.general_experience
	data["can_show_character_level"] = !!user?.client && check_rights_for(user.client, R_ADMIN)
	if(data["can_show_character_level"])
		data["character_level"] = skills.character_level

	var/list/stat_data = list()
	for(var/stat_type in GLOB.cy_stat_types)
		var/datum/cy_stat/stat = get_cy_stat_datum(stat_type)
		if(!stat)
			continue
		var/base_value = stats.get_base_stat(stat_type)
		stat_data += list(list(
			"path" = "[stat_type]",
			"name" = stat.name,
			"id" = stat.id,
			"value" = base_value,
			"effective_value" = stats.get_stat(stat_type),
			"max_value" = CY_STAT_MAXIMUM,
			"can_raise" = skills.stat_points > 0 && base_value < CY_STAT_MAXIMUM,
		))
	data["stats"] = stat_data

	var/list/skill_data = list()
	for(var/skill_type in get_all_cy_skill_types())
		var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
		if(!skill)
			continue
		var/current_level = skills.get_skill_level(skill_type)
		var/next_level = current_level + 1
		var/unlocked_level = skills.get_unlocked_skill_level(skill_type)
		var/cost = skills.get_distributable_experience_cost_for_skill_level(next_level)
		var/can_raise = next_level <= skill.max_level && next_level <= unlocked_level && skills.distributable_experience >= cost && skills.can_set_skill_level(skill_type, next_level)
		skill_data += list(list(
			"path" = "[skill_type]",
			"name" = skill.name,
			"desc" = skill.desc,
			"category" = skill.category,
			"level" = current_level,
			"level_name" = get_cy_skill_level_name(current_level),
			"next_level" = next_level,
			"next_level_name" = next_level <= skill.max_level ? get_cy_skill_level_name(next_level) : null,
			"unlocked_level" = unlocked_level,
			"max_level" = skill.max_level,
			"cost" = cost,
			"can_raise" = can_raise,
		))
	data["skills"] = skill_data
	return data

/datum/cy_character_progression_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !istype(owner) || ui.user != owner)
		return

	var/datum/cy_skill_holder/skills = owner.ensure_cy_skill_holder()
	switch(action)
		if("raise_stat")
			var/stat_type = text2path(params["stat"])
			return skills.spend_stat_point_on_stat(stat_type)
		if("raise_skill")
			var/skill_type = text2path(params["skill"])
			var/next_level = skills.get_skill_level(skill_type) + 1
			var/cost = skills.get_distributable_experience_cost_for_skill_level(next_level)
			return skills.spend_distributable_experience_on_skill(skill_type, cost)
		if("stat_to_skill")
			return skills.convert_stat_point_to_skill_points()
		if("skill_to_stat")
			return skills.convert_skill_points_to_stat_point()

/mob/living/verb/open_cy_character_progression()
	set category = "IC"
	set name = "Character"
	set desc = "Distribute digested character progression points."

	var/datum/cy_character_progression_panel/panel = new(src)
	panel.ui_interact(src)
