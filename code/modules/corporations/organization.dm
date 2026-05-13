GLOBAL_LIST_EMPTY(cy_organization_datums)

/proc/get_cy_organization_datum(organization_type) as /datum/cy_organization
	if(!ispath(organization_type, /datum/cy_organization))
		return null

	var/datum/cy_organization/organization = GLOB.cy_organization_datums[organization_type]
	if(!organization)
		organization = new organization_type
		GLOB.cy_organization_datums[organization_type] = organization

	return organization

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

	/// Tags used later by demons, implants, equipment, contracts and Storyteller.
	var/list/tech_tags = list()

	/// Soft relation placeholders. Full diplomacy/faction logic is a later corporation block.
	var/list/allied_organization_types = list()
	var/list/hostile_organization_types = list()

	/// If FALSE, players should not be able to select this as normal allegiance.
	var/can_have_player_allegiance = TRUE

/datum/cy_organization/proc/get_parent() as /datum/cy_organization
	if(!parent_organization)
		return null

	if(ispath(parent_organization, /datum/cy_organization))
		return get_cy_organization_datum(parent_organization)
	if(istype(parent_organization, /datum/cy_organization))
		return parent_organization

	return null

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
