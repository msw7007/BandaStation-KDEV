GLOBAL_LIST_EMPTY(cy_organization_datums)
GLOBAL_LIST_EMPTY(cy_organizations_by_id)

/proc/get_cy_organization_datum(organization_type) as /datum/cy_organization
	if(!ispath(organization_type, /datum/cy_organization))
		return null

	var/datum/cy_organization/organization = GLOB.cy_organization_datums[organization_type]
	if(!organization)
		organization = new organization_type
		GLOB.cy_organization_datums[organization_type] = organization
		if(organization.id)
			GLOB.cy_organizations_by_id[organization.id] = organization

	return organization

/proc/get_cy_organization_by_id(organization_id) as /datum/cy_organization
	if(!organization_id)
		return null

	var/datum/cy_organization/cached_organization = GLOB.cy_organizations_by_id[organization_id]
	if(cached_organization)
		return cached_organization

	for(var/datum/cy_organization/organization_type as anything in subtypesof(/datum/cy_organization))
		var/datum/cy_organization/organization = get_cy_organization_datum(organization_type)
		if(organization?.id == organization_id)
			return organization

	return null

/datum/cy_organization
	/// Player-facing name.
	var/name = "Unknown organization"

	/// Stable id for saves, logs, future UI and external systems.
	var/id = "unknown"

	/// Description for future UI.
	var/desc = ""

	/// Broad organization kind. This is not the same as combat faction.
	var/organization_kind = CY_ORGANIZATION_KIND_NEUTRAL

	/// Parent organization type. Example: San Yon -> Ben conglomerate.
	var/datum/cy_organization/parent_organization

	/// Tags used by demons, implants, equipment, contracts and Storyteller.
	var/list/tech_tags = list()

	/// Soft relation placeholders. Full diplomacy/faction logic is a later block.
	var/list/allied_organization_types = list()
	var/list/hostile_organization_types = list()

	/// If FALSE, players should not be able to select this as normal allegiance.
	var/can_have_player_allegiance = TRUE

	/// TRUE for organizations that own round progression directly: Ben, Ryaznov, Starlight.
	var/uses_round_progression = FALSE

	/// Current round level of this organization.
	var/round_level = 0

	/// Main research currency spent on technology unlocks.
	var/research_points = 0

	/// Abstract city/corporate pressure value for Storyteller, services and future city control.
	var/influence = 0

	/// Abstract profit counter. Economy can later replace this with real account integration.
	var/profit = 0

	/// Assoc data buckets. Examples: "bio", "engineering", "market", "route", "combat".
	var/list/collected_data = list()

	/// Technology type paths unlocked by this organization.
	var/list/unlocked_technology_types = list()

	/// Edict type paths chosen by this organization.
	var/list/chosen_edict_types = list()

	/// Technology type paths available to this organization.
	var/list/available_technology_types = list()

	/// Edict type paths available to this organization.
	var/list/available_edict_types = list()

	/// Lightweight round log for UI, admin panels and Storyteller payloads.
	var/list/round_log = list()

/datum/cy_organization/proc/get_parent() as /datum/cy_organization
	if(!parent_organization)
		return null

	if(ispath(parent_organization, /datum/cy_organization))
		return get_cy_organization_datum(parent_organization)
	if(istype(parent_organization, /datum/cy_organization))
		return parent_organization

	return null

/datum/cy_organization/proc/get_progress_owner() as /datum/cy_organization
	if(uses_round_progression)
		return src

	var/datum/cy_organization/current = get_parent()
	while(current)
		if(current.uses_round_progression)
			return current
		current = current.get_parent()

	return src

/datum/cy_organization/proc/is_same_or_child_of(organization_type)
	if(!ispath(organization_type, /datum/cy_organization))
		return FALSE

	if(type == organization_type)
		return TRUE

	var/datum/cy_organization/current = src
	while(current)
		current = current.get_parent()
		if(current?.type == organization_type)
			return TRUE

	return FALSE

/datum/cy_organization/proc/has_tech_tag(tech_tag)
	return tech_tag in tech_tags

/datum/cy_organization/proc/get_compatibility_with(organization_type)
	if(!ispath(organization_type, /datum/cy_organization))
		return CY_ORGANIZATION_COMPATIBILITY_NEUTRAL

	if(type == organization_type)
		return CY_ORGANIZATION_COMPATIBILITY_SAME

	if(is_same_or_child_of(organization_type))
		return CY_ORGANIZATION_COMPATIBILITY_PARENT

	var/datum/cy_organization/other = get_cy_organization_datum(organization_type)
	if(other?.is_same_or_child_of(type))
		return CY_ORGANIZATION_COMPATIBILITY_PARENT

	if(organization_type in allied_organization_types)
		return CY_ORGANIZATION_COMPATIBILITY_ALLIED

	if(organization_type in hostile_organization_types)
		return CY_ORGANIZATION_COMPATIBILITY_HOSTILE

	return CY_ORGANIZATION_COMPATIBILITY_NEUTRAL

/datum/cy_organization/proc/add_research_points(amount, source = null)
	var/datum/cy_organization/owner = get_progress_owner()
	if(amount <= 0)
		return owner.research_points

	owner.research_points += amount
	owner.write_round_log("research", source, amount)
	owner.update_round_level()
	return owner.research_points

/datum/cy_organization/proc/add_profit(amount, source = null)
	var/datum/cy_organization/owner = get_progress_owner()
	if(!amount)
		return owner.profit

	owner.profit += amount
	owner.write_round_log("profit", source, amount)
	owner.update_round_level()
	return owner.profit

/datum/cy_organization/proc/add_influence(amount, source = null)
	var/datum/cy_organization/owner = get_progress_owner()
	if(!amount)
		return owner.influence

	owner.influence += amount
	owner.write_round_log("influence", source, amount)
	owner.update_round_level()
	return owner.influence

/datum/cy_organization/proc/add_data(data_key, amount = 1, source = null)
	var/datum/cy_organization/owner = get_progress_owner()
	if(!data_key || amount <= 0)
		return 0

	owner.collected_data[data_key] = (owner.collected_data[data_key] || 0) + amount
	owner.write_round_log("data", source || data_key, amount)
	owner.update_round_level()
	return owner.collected_data[data_key]

/datum/cy_organization/proc/update_round_level()
	if(!uses_round_progression)
		return get_progress_owner().update_round_level()

	var/score = research_points + influence + round(profit / 100)
	for(var/data_key in collected_data)
		score += round(collected_data[data_key] / 2)

	var/new_level = 0
	if(score >= 1000)
		new_level = 5
	else if(score >= 600)
		new_level = 4
	else if(score >= 350)
		new_level = 3
	else if(score >= 150)
		new_level = 2
	else if(score >= 50)
		new_level = 1

	if(new_level > round_level)
		round_level = new_level
		write_round_log("level", null, round_level)

	return round_level

/datum/cy_organization/proc/can_unlock_technology(technology_type)
	var/datum/cy_organization/owner = get_progress_owner()
	var/datum/cy_organization_technology/technology = get_cy_organization_technology(technology_type)
	return technology?.can_unlock(owner)

/datum/cy_organization/proc/unlock_technology(technology_type, free = FALSE)
	var/datum/cy_organization/owner = get_progress_owner()
	var/datum/cy_organization_technology/technology = get_cy_organization_technology(technology_type)
	if(!technology?.can_unlock(owner, free))
		return FALSE

	if(!free)
		owner.research_points -= technology.cost
	owner.unlocked_technology_types |= technology.type
	owner.write_round_log("technology", technology.name, technology.cost)
	return TRUE

/datum/cy_organization/proc/has_unlocked_technology(technology_type)
	return technology_type in get_progress_owner().unlocked_technology_types

/datum/cy_organization/proc/can_choose_edict(edict_type)
	var/datum/cy_organization/owner = get_progress_owner()
	var/datum/cy_organization_edict/edict = get_cy_organization_edict(edict_type)
	return edict?.can_choose(owner)

/datum/cy_organization/proc/choose_edict(edict_type)
	var/datum/cy_organization/owner = get_progress_owner()
	var/datum/cy_organization_edict/edict = get_cy_organization_edict(edict_type)
	if(!edict?.can_choose(owner))
		return FALSE

	owner.chosen_edict_types |= edict.type
	owner.write_round_log("edict", edict.name, edict.level)
	return TRUE

/datum/cy_organization/proc/has_chosen_edict_level(level)
	var/datum/cy_organization/owner = get_progress_owner()
	for(var/edict_type in owner.chosen_edict_types)
		var/datum/cy_organization_edict/edict = get_cy_organization_edict(edict_type)
		if(edict?.level == level)
			return TRUE

	return FALSE

/datum/cy_organization/proc/write_round_log(event_type, source = null, amount = null)
	round_log += list(list(
		"time" = world.time,
		"event" = event_type,
		"source" = source,
		"amount" = amount,
	))

	if(length(round_log) > 100)
		round_log.Cut(1, 2)

/// Resolve an organization from a datum, typepath or stable id string.
/proc/resolve_cy_organization_datum(organization) as /datum/cy_organization
	if(istype(organization, /datum/cy_organization))
		return organization

	if(ispath(organization, /datum/cy_organization))
		return get_cy_organization_datum(organization)

	if(istext(organization))
		return get_cy_organization_by_id(organization)

	return null

/datum/cy_organization/proc/get_root() as /datum/cy_organization
	var/datum/cy_organization/current = src
	var/datum/cy_organization/parent = current.get_parent()
	while(parent)
		current = parent
		parent = current.get_parent()
	return current

/datum/cy_organization/proc/matches(organization, include_parent = TRUE)
	var/datum/cy_organization/other = resolve_cy_organization_datum(organization)
	if(!other)
		return FALSE
	if(type == other.type)
		return TRUE
	return include_parent && is_same_or_child_of(other.type)

/datum/controller/subsystem/cy_organizations/proc/get_cy_organization_by_id(organization_id) as /datum/cy_organization
	return get_cy_organization_by_id(organization_id)
