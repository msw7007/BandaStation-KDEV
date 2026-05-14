SUBSYSTEM_DEF(cy_organizations)
	name = "Cyberpunk Organizations"
	ss_flags = SS_NO_FIRE

/datum/controller/subsystem/cy_organizations/Initialize()
	for(var/datum/cy_organization/organization_type as anything in subtypesof(/datum/cy_organization))
		get_cy_organization_datum(organization_type)
	return SS_INIT_SUCCESS

/datum/controller/subsystem/cy_organizations/proc/get_organization(organization) as /datum/cy_organization
	if(ispath(organization, /datum/cy_organization))
		return get_cy_organization_datum(organization)
	if(istype(organization, /datum/cy_organization))
		return organization
	if(istext(organization))
		return get_cy_organization_by_id(organization)
	return null

/datum/controller/subsystem/cy_organizations/proc/add_research(organization, amount, source = null)
	var/datum/cy_organization/resolved_organization = get_organization(organization)
	return resolved_organization?.add_research_points(amount, source)

/datum/controller/subsystem/cy_organizations/proc/add_data(organization, data_key, amount = 1, source = null)
	var/datum/cy_organization/resolved_organization = get_organization(organization)
	return resolved_organization?.add_data(data_key, amount, source)

/datum/controller/subsystem/cy_organizations/proc/unlock_technology(organization, technology_type, free = FALSE)
	var/datum/cy_organization/resolved_organization = get_organization(organization)
	return resolved_organization?.unlock_technology(technology_type, free)

/datum/controller/subsystem/cy_organizations/proc/choose_edict(organization, edict_type)
	var/datum/cy_organization/resolved_organization = get_organization(organization)
	return resolved_organization?.choose_edict(edict_type)
