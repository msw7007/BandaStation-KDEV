/// Preference middleware is code that helps to decentralize complicated preference features.
/datum/preference_middleware
	/// The preferences datum
	var/datum/preferences/preferences

	/// The key that will be used for get_constant_data().
	/// If null, will use the typepath minus /datum/preference_middleware.
	var/key = null

	/// Map of ui_act actions -> proc paths to call.
	/// Signature is `(list/params, mob/user) -> TRUE/FALSE.
	/// Return output is the same as ui_act--TRUE if it should update, FALSE if it should not
	var/list/action_delegations = list()

/datum/preference_middleware/New(datum/preferences)
	src.preferences = preferences

	if (isnull(key))
		// + 2 coming from the off-by-one of copytext, and then another from the slash
		key = copytext("[type]", length("[parent_type]") + 2)

/datum/preference_middleware/Destroy()
	preferences = null
	return ..()

/// Append all of these into ui_data
/datum/preference_middleware/proc/get_ui_data(mob/user)
	return list()

/// Append all of these into ui_static_data
/datum/preference_middleware/proc/get_ui_static_data(mob/user)
	return list()

/// Append all of these into ui_assets
/datum/preference_middleware/proc/get_ui_assets()
	return list()

/// Append all of these into /datum/asset/json/preferences.
/datum/preference_middleware/proc/get_constant_data()
	return null

/// Merge this into the result of compile_character_preferences.
/datum/preference_middleware/proc/get_character_preferences(mob/user)
	return null

/// Called every set_preference, returns TRUE if this handled it.
/datum/preference_middleware/proc/pre_set_preference(mob/user, preference, value)
	return FALSE

/// Called when a character is changed.
/datum/preference_middleware/proc/on_new_character(mob/user)
	return

/// Called after every update_preference
/datum/preference_middleware/proc/post_set_preference(mob/user, preference, value)
	return

/// Read-only adapter data for the CyberPunk 13 character setup shell.
/datum/preference_middleware/character_setup
	key = "character_setup"
	action_delegations = list(
		"adjust_character_attribute" = PROC_REF(adjust_character_attribute),
		"adjust_character_perk" = PROC_REF(adjust_character_perk),
		"adjust_character_skill_level" = PROC_REF(adjust_character_skill_level),
	)

/datum/preference_middleware/character_setup/get_constant_data()
	return list(
		"attributes" = get_attribute_definitions(),
		"physical_skills" = get_skill_definitions(CHARACTER_SKILL_KIND_PHYSICAL),
		"professional_skills" = get_skill_definitions(CHARACTER_SKILL_KIND_PROFESSIONAL),
		"weapon_skills" = get_skill_definitions(CHARACTER_SKILL_KIND_WEAPON),
		"implant_slots" = get_implant_slot_definitions(),
	)

/datum/preference_middleware/character_setup/get_ui_data(mob/user)
	var/list/data = list()
	var/datum/mind/user_mind = user?.mind
	user_mind?.recalculate_character_skill_point_pools()

	var/list/attributes = list()
	for(var/attribute_id in ATTRIBUTE_ALL)
		var/attribute_editable = !!user_mind
		attributes[attribute_id] = list(
			"value" = user_mind?.get_attribute_value(attribute_id) || ATTRIBUTE_DEFAULT,
			"min" = ATTRIBUTE_MINIMUM,
			"max" = ATTRIBUTE_MAXIMUM,
			"super_threshold" = ATTRIBUTE_SUPER_THRESHOLD,
			"editable" = attribute_editable,
			"disabled_reason" = attribute_editable ? null : "Character mind is not available.",
		)

	var/list/skills = list()
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_path = skill_type
		if(initial(skill_path.abstract_type) == skill_type)
			continue
		var/datum/skill/skill_datum = SSskills.all_skills[skill_type]
		var/temporary_skill = FALSE
		if(isnull(skill_datum))
			skill_datum = new skill_type
			temporary_skill = TRUE
		if(skill_datum.is_character_skill())
			var/list/perks = list()
			if(skill_datum.uses_perks())
				for(var/perk_index in 1 to length(skill_datum.perks))
					var/perk_rank = user_mind?.get_character_perk_rank(skill_type, perk_index) || 0
					var/independent_perk = !skill_datum.requires_sequential_perks
					var/can_increase = user_mind?.can_set_character_perk_rank(skill_type, perk_index, perk_rank + 1, FALSE, independent_perk) || FALSE
					var/can_decrease = user_mind?.can_set_character_perk_rank(skill_type, perk_index, perk_rank - 1, FALSE, independent_perk) || FALSE
					perks["[perk_index]"] = list(
						"rank" = perk_rank,
						"can_increase" = can_increase,
						"can_decrease" = can_decrease,
					)
			var/skill_level = user_mind?.get_character_skill_level(skill_type) || CHARACTER_SKILL_LEVEL_NONE
			skills["[skill_type]"] = list(
				"level" = skill_level,
				"spent_points" = user_mind?.get_character_skill_spent_points(skill_type) || 0,
				"perks" = perks,
				"can_increase" = user_mind?.can_pay_character_skill_points(skill_type, 1) && skill_level < skill_datum.max_character_level,
				"can_decrease" = skill_level > CHARACTER_SKILL_LEVEL_NONE,
				"editable" = !!user_mind,
				"disabled_reason" = user_mind ? null : "Character mind is not available.",
			)
		if(temporary_skill)
			qdel(skill_datum)

	var/list/implant_metrics = list(
		"chromity" = CHROMITY_DEFAULT,
		"chromity_max" = CHROMITY_DEFAULT,
		"overheat" = CHROMITY_OVERHEAT_DEFAULT,
		"overheat_floor" = CHROMITY_OVERHEAT_DEFAULT,
		"has_neural_implant" = TRUE,
		"editable" = FALSE,
		"disabled_reason" = "TODO: preference-time implant loadout is not wired yet.",
	)
	if(isliving(user))
		var/mob/living/living_user = user
		implant_metrics["chromity"] = living_user.get_effective_chromity()
		implant_metrics["chromity_max"] = living_user.chromity
		implant_metrics["overheat"] = living_user.chromity_overheat
		implant_metrics["overheat_floor"] = living_user.get_chromity_overheat_floor()
		implant_metrics["has_neural_implant"] = living_user.has_neural_implant()

	data["character_setup"] = list(
		"attributes" = attributes,
		"skills" = skills,
		"level_points" = user_mind?.level_points || 0,
		"skill_points" = (user_mind?.professional_skill_points || 0) + (user_mind?.weapon_skill_points || 0),
		"professional_skill_points" = user_mind?.professional_skill_points || 0,
		"weapon_skill_points" = user_mind?.weapon_skill_points || 0,
		"implant_metrics" = implant_metrics,
	)

	return data

/datum/preference_middleware/character_setup/proc/adjust_character_attribute(list/params, mob/user)
	var/attribute_id = params["attribute_id"]
	if(!(attribute_id in ATTRIBUTE_ALL))
		return FALSE

	var/datum/mind/user_mind = user?.mind
	if(!user_mind)
		return FALSE

	var/raw_delta = params["delta"]
	var/delta = round(text2num("[raw_delta]") || 0)
	if(!delta)
		return FALSE

	var/current_value = user_mind.get_attribute_value(attribute_id)
	if(delta > 0)
		if(user_mind.level_points <= 0 || current_value >= ATTRIBUTE_MAXIMUM)
			return FALSE
		user_mind.level_points--
		user_mind.adjust_attribute_value(attribute_id, 1)
		preferences.save_character()
		return TRUE

	if(current_value <= ATTRIBUTE_MINIMUM)
		return FALSE
	if(user_mind.get_attribute_physical_perk_points(attribute_id) > current_value - 1)
		return FALSE
	user_mind.adjust_attribute_value(attribute_id, -1)
	user_mind.level_points++
	preferences.save_character()
	return TRUE

/datum/preference_middleware/character_setup/proc/adjust_character_perk(list/params, mob/user)
	var/datum/mind/user_mind = user?.mind
	if(!user_mind)
		return FALSE

	var/skill_type = text2path(params["skill"])
	if(!ispath(skill_type, /datum/skill))
		return FALSE

	var/raw_perk_index = params["perk_index"]
	var/perk_index = round(text2num("[raw_perk_index]") || 0)
	var/raw_delta = params["delta"]
	var/delta = round(text2num("[raw_delta]") || 0)
	if(!perk_index || !delta)
		return FALSE

	var/datum/skill/skill_datum = GetSkillRef(skill_type)
	if(!skill_datum || !skill_datum.uses_perks())
		return FALSE

	var/independent_perk = !skill_datum.requires_sequential_perks
	if(!user_mind.adjust_character_perk_rank(skill_type, perk_index, delta, FALSE, independent_perk))
		return FALSE
	preferences.save_character()
	return TRUE

/datum/preference_middleware/character_setup/proc/adjust_character_skill_level(list/params, mob/user)
	var/datum/mind/user_mind = user?.mind
	if(!user_mind)
		return FALSE

	var/skill_type = text2path(params["skill"])
	if(!ispath(skill_type, /datum/skill))
		return FALSE

	var/raw_delta = params["delta"]
	var/delta = round(text2num("[raw_delta]") || 0)
	if(!delta)
		return FALSE

	var/datum/skill/skill_datum = GetSkillRef(skill_type)
	if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
		return FALSE

	if(!user_mind.adjust_character_skill_level(skill_type, delta))
		return FALSE
	preferences.save_character()
	return TRUE

/datum/preference_middleware/character_setup/proc/get_attribute_definitions()
	return list(
		ATTRIBUTE_STRENGTH = list(
			"id" = ATTRIBUTE_STRENGTH,
			"name" = "Сила",
			"description" = "Физическая мощь, тяжелое оружие, захваты и крепость.",
		),
		ATTRIBUTE_DEXTERITY = list(
			"id" = ATTRIBUTE_DEXTERITY,
			"name" = "Ловкость",
			"description" = "Скорость, легкое оружие, акробатика и изворотливость.",
		),
		ATTRIBUTE_PERCEPTION = list(
			"id" = ATTRIBUTE_PERCEPTION,
			"name" = "Восприятие",
			"description" = "Точность, метание, анализ слабостей и концентрация.",
		),
		ATTRIBUTE_INTELLIGENCE = list(
			"id" = ATTRIBUTE_INTELLIGENCE,
			"name" = "Интеллект",
			"description" = "Код, демоны, взлом и нейрализация.",
		),
		ATTRIBUTE_SPIRIT = list(
			"id" = ATTRIBUTE_SPIRIT,
			"name" = "Дух",
			"description" = "Выживание, выдержка, атлетика и совместимость.",
		),
		ATTRIBUTE_CHARISMA = list(
			"id" = ATTRIBUTE_CHARISMA,
			"name" = "Харизма",
			"description" = "Скрытность, воровство, воодушевление и стиль.",
		),
	)

/datum/preference_middleware/character_setup/proc/get_skill_definitions(skill_kind)
	var/list/skills = list()
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_path = skill_type
		if(initial(skill_path.abstract_type) == skill_type)
			continue
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		var/temporary_skill = FALSE
		if(isnull(skill_datum))
			skill_datum = new skill_type
			temporary_skill = TRUE
		if(skill_datum.skill_kind != skill_kind)
			if(temporary_skill)
				qdel(skill_datum)
			continue

		skills += list(list(
			"id" = "[skill_type]",
			"name" = skill_datum.name,
			"title" = skill_datum.title,
			"description" = skill_datum.desc,
			"attribute_id" = skill_datum.attribute_id,
			"kind" = skill_datum.skill_kind,
			"point_pool" = skill_datum.point_pool,
			"max_character_level" = skill_datum.max_character_level,
			"max_perk_rank" = skill_datum.max_perk_rank,
			"requires_sequential_perks" = skill_datum.requires_sequential_perks,
			"giga_perk_name" = skill_datum.giga_perk_name,
			"giga_perk_desc" = skill_datum.giga_perk_desc,
			"weapon_damage_bonus_per_level" = skill_datum.weapon_damage_bonus_per_level,
			"weapon_cooldown_reduction_per_level" = skill_datum.weapon_cooldown_reduction_per_level,
			"weapon_defense_break_bonus_per_level" = skill_datum.weapon_defense_break_bonus_per_level,
			"perks" = get_perk_definitions(skill_datum),
		))
		if(temporary_skill)
			qdel(skill_datum)

	return skills

/datum/preference_middleware/character_setup/proc/get_perk_definitions(datum/skill/skill_datum)
	var/list/perks = list()
	for(var/perk_index in 1 to length(skill_datum.perks))
		var/datum/skill_perk/perk = skill_datum.perks[perk_index]
		perks += list(list(
			"index" = perk.index,
			"name" = perk.name,
			"description" = perk.desc,
			"rank_descriptions" = perk.get_rank_descriptions(),
			"max_rank" = perk.max_rank,
		))
	return perks

/datum/preference_middleware/character_setup/proc/get_implant_slot_definitions()
	return list(
		list("id" = "left_arm_1", "name" = "Левая рука I", "zone" = BODY_ZONE_L_ARM, "default_state" = "empty"),
		list("id" = "left_arm_2", "name" = "Левая рука II", "zone" = BODY_ZONE_L_ARM, "default_state" = "empty"),
		list("id" = "right_arm_1", "name" = "Правая рука I", "zone" = BODY_ZONE_R_ARM, "default_state" = "empty"),
		list("id" = "right_arm_2", "name" = "Правая рука II", "zone" = BODY_ZONE_R_ARM, "default_state" = "empty"),
		list("id" = "left_leg", "name" = "Левая нога", "zone" = BODY_ZONE_L_LEG, "default_state" = "empty"),
		list("id" = "right_leg", "name" = "Правая нога", "zone" = BODY_ZONE_R_LEG, "default_state" = "empty"),
		list("id" = "spine_1", "name" = "Позвоночник I", "zone" = BODY_ZONE_CHEST, "default_state" = "empty"),
		list("id" = "spine_2", "name" = "Позвоночник II", "zone" = BODY_ZONE_CHEST, "default_state" = "empty"),
		list("id" = ORGAN_SLOT_HEART, "name" = "Сердце", "zone" = BODY_ZONE_CHEST, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_LUNGS, "name" = "Лёгкие", "zone" = BODY_ZONE_CHEST, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_STOMACH, "name" = "Желудок", "zone" = BODY_ZONE_PRECISE_GROIN, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_LIVER, "name" = "Печень", "zone" = BODY_ZONE_PRECISE_GROIN, "default_state" = "organ"),
		list("id" = "belly", "name" = "Брюхо", "zone" = BODY_ZONE_PRECISE_GROIN, "default_state" = "empty"),
		list("id" = "chest", "name" = "Грудь", "zone" = BODY_ZONE_CHEST, "default_state" = "empty"),
		list("id" = "neck", "name" = "Шея", "zone" = BODY_ZONE_PRECISE_NECK, "default_state" = "empty"),
		list("id" = "skull", "name" = "Череп", "zone" = BODY_ZONE_HEAD, "default_state" = "empty"),
		list("id" = ORGAN_SLOT_BRAIN, "name" = "Мозг", "zone" = BODY_ZONE_HEAD, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_EYES, "name" = "Глаза", "zone" = BODY_ZONE_HEAD, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_EARS, "name" = "Уши", "zone" = BODY_ZONE_HEAD, "default_state" = "organ"),
		list("id" = ORGAN_SLOT_TONGUE, "name" = "Язык / рот", "zone" = BODY_ZONE_PRECISE_MOUTH, "default_state" = "organ"),
		list("id" = "jaw", "name" = "Челюсть", "zone" = BODY_ZONE_PRECISE_MOUTH, "default_state" = "empty"),
		list("id" = "eyelids", "name" = "Веки", "zone" = BODY_ZONE_HEAD, "default_state" = "empty"),
		list("id" = ORGAN_SLOT_NEURAL_IMPLANT, "name" = "Нейросетевой имплант", "zone" = BODY_ZONE_HEAD, "default_state" = "neural_implant"),
	)
