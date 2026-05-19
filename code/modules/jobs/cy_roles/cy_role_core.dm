/// Runtime city-role state. Roles are still normal /datum/job entries; this stores the city-layer metadata on the mob.
/mob/living
	var/cy_role_group
	var/cy_role_id
	var/cy_role_flags = CY_ROLE_FLAG_NONE
	var/cy_role_city_account_id
	var/datum/cy_organization/cy_role_organization_type
	var/cy_police_database_access = FALSE
	var/cy_can_issue_warrants = FALSE
	var/cy_can_manage_budget = FALSE
	var/cy_bounty_hunter = FALSE
	var/list/cy_role_expectations = list()

/mob/living/proc/cy_has_role_flag(flag)
	return !!(cy_role_flags & flag)

/mob/living/proc/cy_get_role_organization()
	if(!cy_role_organization_type)
		return null
	if(ispath(cy_role_organization_type, /datum/cy_organization))
		return get_cy_organization_datum(cy_role_organization_type)
	return cy_role_organization_type

/mob/living/proc/cy_can_access_police_database()
	return cy_police_database_access || cy_bounty_hunter || cy_has_role_flag(CY_ROLE_FLAG_POLICE) || cy_has_role_flag(CY_ROLE_FLAG_COUNCIL)

/mob/living/proc/cy_can_manage_city_budget(account_id)
	if(!cy_can_manage_budget)
		return FALSE
	if(cy_has_role_flag(CY_ROLE_FLAG_COUNCIL))
		return TRUE
	return account_id && account_id == cy_role_city_account_id

/datum/job/proc/apply_cy_city_role(mob/living/spawned, client/player_client)
	if(!spawned || !cy_role_id)
		return

	spawned.cy_role_group = cy_role_group
	spawned.cy_role_id = cy_role_id
	spawned.cy_role_flags = cy_role_flags
	spawned.cy_role_city_account_id = cy_city_account_id
	spawned.cy_role_organization_type = cy_organization_type
	spawned.cy_police_database_access = cy_police_database_access
	spawned.cy_can_issue_warrants = cy_can_issue_warrants
	spawned.cy_can_manage_budget = cy_can_manage_budget
	spawned.cy_bounty_hunter = cy_bounty_hunter
	if(length(cy_role_stat_modifiers))
		for(var/stat_type in cy_role_stat_modifiers)
			spawned.set_cy_stat_modifier(stat_type, "cy_city_role", cy_role_stat_modifiers[stat_type])
	if(length(cy_role_expectations))
		spawned.cy_role_expectations = cy_role_expectations.Copy()
	else
		spawned.cy_role_expectations = list()
	apply_cy_role_skill_levels(spawned)
	apply_cy_role_roundstart_violations(spawned)

	if(SSeconomy && cy_city_account_id)
		SSeconomy.cy_init_city_economy()
		var/datum/bank_account/source_account = SSeconomy.cy_get_city_account(cy_city_account_id)
		var/datum/bank_account/target_account = spawned.get_bank_account()
		if(source_account && target_account)
			// Turn the role spawn into a ledgered city event. This does not create new money; it links the role to the city account flow.
			SSeconomy.cy_record_transaction(source_account, target_account, 0, "Назначение роли: [title]", CY_ECON_VISIBILITY_BANK, CY_ECON_CHANNEL_BANK, spawned.name, spawned)

	to_chat(spawned, span_notice("Городская роль: [job_title_ru(title)]. [get_cy_city_role_summary()]"))

	if(length(spawned.cy_role_expectations))
		to_chat(spawned, span_notice("Role expectations: [jointext(spawned.cy_role_expectations, " ")]"))

/datum/job/proc/apply_cy_role_skill_levels(mob/living/spawned)
	if(!spawned || !length(cy_role_skill_levels))
		return
	for(var/skill_type in cy_role_skill_levels)
		var/granted_level = clamp(round(cy_role_skill_levels[skill_type]), CY_SKILL_MINIMUM_LEVEL, CY_SKILL_MAXIMUM_LEVEL)
		if(granted_level <= CY_SKILL_MINIMUM_LEVEL || HAS_TRAIT(spawned, cy_skill_perk_trait(skill_type, granted_level)))
			continue
		spawned.set_cy_skill_level(skill_type, granted_level, TRUE)

/datum/job/proc/apply_cy_role_roundstart_violations(mob/living/spawned)
	if(!spawned || !SSeconomy || !length(cy_role_roundstart_violations))
		return
	SSeconomy.cy_init_city_economy()
	for(var/list/entry as anything in cy_role_roundstart_violations)
		if(!islist(entry))
			continue
		var/law_id = entry["law"] || CY_LAW_TRESPASS
		var/details = entry["details"] || "Roundstart city role flag."
		var/issuer = entry["issuer"] || "City security database"
		var/fine = entry["fine"]
		var/sentence_time = entry["sentence"]
		var/status = entry["status"]
		SSeconomy.cy_issue_violation(spawned, law_id, details, issuer, fine, sentence_time, status)

/datum/job/proc/get_cy_city_role_summary()
	if(!cy_role_id)
		return ""
	var/list/parts = list()
	switch(cy_role_group)
		if(CY_ROLE_GROUP_RESIDENT)
			parts += "Вы относитесь к жителям города."
		if(CY_ROLE_GROUP_CORPORATE)
			parts += "Вы служите корпоративной структуре."
		if(CY_ROLE_GROUP_OUTSOURCER)
			parts += "Вы работаете как внешний исполнитель."
		if(CY_ROLE_GROUP_ANTAGONIST)
			parts += "Вы антагонистическая роль городского конфликта."
	if(cy_can_manage_budget)
		parts += "У вас есть доступ к управлению закрепленным бюджетом."
	if(cy_police_database_access)
		parts += "У вас есть доступ к юридической базе."
	if(cy_bounty_hunter)
		parts += "Вы можете работать с розыском как охотник за головами при наличии ключей доступа."
	return jointext(parts, " ")
