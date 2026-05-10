/mob/living/proc/ensure_cy_organization() as /datum/cy_organization
	if(!cy_organization)
		cy_organization = get_cy_organization_datum(cy_organization_type)

	return cy_organization

/mob/living/proc/get_cy_organization() as /datum/cy_organization
	return ensure_cy_organization()

/mob/living/proc/get_cy_organization_type()
	ensure_cy_organization()
	return cy_organization_type

/mob/living/proc/set_cy_organization(organization_type)
	if(!ispath(organization_type, /datum/cy_organization))
		return FALSE

	var/datum/cy_organization/organization = get_cy_organization_datum(organization_type)
	if(!organization)
		return FALSE

	cy_organization_type = organization_type
	cy_organization = organization
	return TRUE

/mob/living/proc/clear_cy_organization()
	return set_cy_organization(/datum/cy_organization/neutral)

/mob/living/proc/has_cy_organization(organization_type, include_parent = TRUE)
	if(!ispath(organization_type, /datum/cy_organization))
		return FALSE

	var/datum/cy_organization/organization = ensure_cy_organization()
	if(!organization)
		return FALSE

	if(organization.type == organization_type)
		return TRUE

	return include_parent && organization.is_same_or_child_of(organization_type)

/mob/living/proc/get_cy_organization_compatibility(organization_type)
	var/datum/cy_organization/organization = ensure_cy_organization()
	if(!organization)
		return CY_ORGANIZATION_COMPATIBILITY_NEUTRAL

	return organization.get_compatibility_with(organization_type)
