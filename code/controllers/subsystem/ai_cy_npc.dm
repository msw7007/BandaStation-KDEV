/datum/controller/subsystem/ai_controllers
	var/list/cy_npc_factions = list()

/datum/controller/subsystem/ai_controllers/proc/setup_cy_npc_factions()
	if(length(cy_npc_factions))
		return
	for(var/faction_type in subtypesof(/datum/cy_npc_faction))
		var/datum/cy_npc_faction/faction = new faction_type
		cy_npc_factions[faction.id] = faction
	cy_npc_link_default_factions()

/datum/controller/subsystem/ai_controllers/proc/cy_npc_link_default_factions()
	var/datum/cy_npc_faction/city = cy_npc_factions["city"]
	var/datum/cy_npc_faction/government = cy_npc_factions["government"]
	var/datum/cy_npc_faction/corporate = cy_npc_factions["corporate"]
	var/datum/cy_npc_faction/bandit = cy_npc_factions["bandit"]
	var/datum/cy_npc_faction/wildlife = cy_npc_factions["wildlife"]
	city?.set_relation("government", CY_NPC_REL_ALLY)
	city?.set_relation("corporate", CY_NPC_REL_NEUTRAL)
	city?.set_relation("bandit", CY_NPC_REL_ENEMY)
	city?.set_relation("wildlife", CY_NPC_REL_NEUTRAL)
	government?.set_relation("city", CY_NPC_REL_ALLY)
	government?.set_relation("corporate", CY_NPC_REL_NEUTRAL)
	government?.set_relation("bandit", CY_NPC_REL_ENEMY)
	government?.set_relation("wildlife", CY_NPC_REL_NEUTRAL)
	corporate?.set_relation("city", CY_NPC_REL_NEUTRAL)
	corporate?.set_relation("government", CY_NPC_REL_NEUTRAL)
	corporate?.set_relation("bandit", CY_NPC_REL_ENEMY)
	corporate?.set_relation("wildlife", CY_NPC_REL_NEUTRAL)
	bandit?.set_relation("city", CY_NPC_REL_ENEMY)
	bandit?.set_relation("government", CY_NPC_REL_ENEMY)
	bandit?.set_relation("corporate", CY_NPC_REL_ENEMY)
	bandit?.set_relation("wildlife", CY_NPC_REL_NEUTRAL)
	wildlife?.set_relation("city", CY_NPC_REL_NEUTRAL)
	wildlife?.set_relation("government", CY_NPC_REL_NEUTRAL)
	wildlife?.set_relation("corporate", CY_NPC_REL_NEUTRAL)
	wildlife?.set_relation("bandit", CY_NPC_REL_NEUTRAL)

/datum/controller/subsystem/ai_controllers/proc/cy_npc_current_day_phase()
	var/phase_time = world.time % (30 MINUTES)
	if(phase_time < 7.5 MINUTES)
		return "night"
	if(phase_time < 15 MINUTES)
		return "morning"
	if(phase_time < 22.5 MINUTES)
		return "day"
	return "evening"

/datum/controller/subsystem/ai_controllers/proc/cy_npc_get_faction(faction_id)
	setup_cy_npc_factions()
	return cy_npc_factions[faction_id]

/datum/controller/subsystem/ai_controllers/proc/cy_npc_relation(first_faction_id, second_faction_id)
	var/datum/cy_npc_faction/faction = cy_npc_get_faction(first_faction_id)
	if(!faction)
		return CY_NPC_REL_NEUTRAL
	return faction.get_relation(second_faction_id)

/datum/controller/subsystem/ai_controllers/proc/cy_npc_dispatch_order(mob/living/target_mob, order_type, atom/target, list/data)
	if(!target_mob?.ai_controller)
		return null
	var/datum/ai_controller/controller = target_mob.ai_controller
	return controller.cy_npc_make_order(order_type, target, data)

/datum/controller/subsystem/ai_controllers/proc/cy_npc_broadcast_order(faction_id, order_type, atom/target, list/data, turf/center, radius = 0)
	var/list/orders = list()
	for(var/status in GLOB.ai_controllers_by_status)
		for(var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_status[status])
			if(!controller.cy_npc_profile)
				continue
			if(faction_id && controller.cy_npc_faction_id != faction_id)
				continue
			if(center && radius && get_dist(controller.pawn, center) > radius)
				continue
			orders += controller.cy_npc_make_order(order_type, target, data)
	return orders

/datum/controller/subsystem/ai_controllers/proc/cy_npc_storyteller_snapshot()
	var/list/snapshot = list()
	for(var/status in GLOB.ai_controllers_by_status)
		for(var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_status[status])
			if(controller.cy_npc_profile)
				snapshot += list(controller.cy_npc_snapshot())
	return snapshot
