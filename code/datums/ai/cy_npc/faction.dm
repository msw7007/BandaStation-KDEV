/datum/cy_npc_faction
	var/id = "neutral"
	var/name = "Neutral"
	var/list/relations = list()

/datum/cy_npc_faction/proc/get_relation(other_faction_id)
	if(!other_faction_id || other_faction_id == id)
		return CY_NPC_REL_ALLY
	if(isnum(relations[other_faction_id]))
		return relations[other_faction_id]
	return CY_NPC_REL_NEUTRAL

/datum/cy_npc_faction/proc/set_relation(other_faction_id, relation)
	if(!other_faction_id)
		return FALSE
	relations[other_faction_id] = relation
	return TRUE

/datum/cy_npc_faction/city
	id = "city"
	name = "City"

/datum/cy_npc_faction/government
	id = "government"
	name = "Government"

/datum/cy_npc_faction/corporate
	id = "corporate"
	name = "Corporate"

/datum/cy_npc_faction/bandit
	id = "bandit"
	name = "Bandit"

/datum/cy_npc_faction/wildlife
	id = "wildlife"
	name = "Wildlife"
