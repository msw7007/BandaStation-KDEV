/datum/cy_npc_profile
	var/name = "NPC"
	var/role = CY_NPC_ROLE_CIVILIAN
	var/faction_id = "neutral"
	var/level = CY_NPC_LEVEL_BASIC
	var/capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_MELEE | CY_NPC_CAP_ITEM_USE
	var/reaction_delay = 1 SECONDS
	var/error_chance = 20
	var/accuracy_modifier = 0
	var/retreat_health_percent = 20
	var/group_radius = 7
	var/threat_scan_range = 7
	var/phantom_allowed = TRUE
	var/interesting_distance = AI_DEFAULT_INTERESTING_DIST
	var/list/default_patrol_points
	var/default_work_target
	var/list/default_schedule

/datum/cy_npc_profile/New()
	. = ..()
	apply_level_quality()

/datum/cy_npc_profile/proc/apply_level_quality()
	switch(level)
		if(CY_NPC_LEVEL_PRIMITIVE)
			reaction_delay = 2 SECONDS
			error_chance = 40
			accuracy_modifier = -25
			threat_scan_range = 4
			capabilities &= ~(CY_NPC_CAP_RANGED | CY_NPC_CAP_COVER | CY_NPC_CAP_AIM | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_DEMONS | CY_NPC_CAP_IMPLANTS | CY_NPC_CAP_GROUP | CY_NPC_CAP_LAW | CY_NPC_CAP_EQUIPMENT)
		if(CY_NPC_LEVEL_BASIC)
			reaction_delay = 1.5 SECONDS
			error_chance = 25
			accuracy_modifier = -10
			threat_scan_range = 6
		if(CY_NPC_LEVEL_TRAINED)
			reaction_delay = 1 SECONDS
			error_chance = 15
			accuracy_modifier = 0
			threat_scan_range = 7
		if(CY_NPC_LEVEL_PROFESSIONAL)
			reaction_delay = 0.7 SECONDS
			error_chance = 8
			accuracy_modifier = 10
			threat_scan_range = 9
			capabilities |= CY_NPC_CAP_GROUP | CY_NPC_CAP_COVER | CY_NPC_CAP_AIM
		if(CY_NPC_LEVEL_ELITE)
			reaction_delay = 0.4 SECONDS
			error_chance = 3
			accuracy_modifier = 20
			threat_scan_range = 11
			capabilities |= CY_NPC_CAP_GROUP | CY_NPC_CAP_COVER | CY_NPC_CAP_AIM | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_EQUIPMENT
		if(CY_NPC_LEVEL_SPECIAL)
			reaction_delay = 0.25 SECONDS
			error_chance = 0
			accuracy_modifier = 30
			threat_scan_range = 13
			capabilities |= CY_NPC_CAP_GROUP | CY_NPC_CAP_COVER | CY_NPC_CAP_AIM | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_DEMONS | CY_NPC_CAP_IMPLANTS | CY_NPC_CAP_EQUIPMENT

/datum/cy_npc_profile/proc/apply_to_controller(datum/ai_controller/controller)
	if(!controller)
		return FALSE
	controller.cy_npc_profile = src
	controller.cy_npc_role = role
	controller.cy_npc_level = level
	controller.cy_npc_faction_id = faction_id
	controller.cy_npc_capabilities = capabilities
	controller.cy_npc_state = CY_NPC_STATE_CALM
	controller.interesting_dist = interesting_distance
	controller.movement_delay = max(0.05 SECONDS, reaction_delay * 0.35)
	controller.max_target_distance = max(controller.max_target_distance, threat_scan_range * 2)
	controller.blackboard[BB_CY_NPC_PROFILE] = src
	controller.blackboard[BB_CY_NPC_ROLE] = role
	controller.blackboard[BB_CY_NPC_LEVEL] = level
	controller.blackboard[BB_CY_NPC_FACTION] = faction_id
	controller.blackboard[BB_CY_NPC_STATE] = controller.cy_npc_state
	if(default_patrol_points)
		controller.blackboard[BB_CY_NPC_PATROL] = default_patrol_points.Copy()
	if(default_work_target)
		controller.blackboard[BB_CY_NPC_WORK_TARGET] = default_work_target
	if(default_schedule)
		controller.blackboard[BB_CY_NPC_SCHEDULE] = default_schedule.Copy()
	return TRUE

/datum/cy_npc_profile/civilian
	name = "Civilian"
	role = CY_NPC_ROLE_CIVILIAN
	faction_id = "city"
	level = CY_NPC_LEVEL_BASIC
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_ITEM_USE | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_SCHEDULE | CY_NPC_CAP_SOCIAL

/datum/cy_npc_profile/government_worker
	name = "Government Worker"
	role = CY_NPC_ROLE_GOVERNMENT_WORKER
	faction_id = "government"
	level = CY_NPC_LEVEL_BASIC
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_ITEM_USE | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_SCHEDULE | CY_NPC_CAP_SOCIAL

/datum/cy_npc_profile/corporate_worker
	name = "Corporate Worker"
	role = CY_NPC_ROLE_CORPORATE_WORKER
	faction_id = "corporate"
	level = CY_NPC_LEVEL_BASIC
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_ITEM_USE | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_SCHEDULE | CY_NPC_CAP_SOCIAL

/datum/cy_npc_profile/drone
	name = "Drone"
	role = CY_NPC_ROLE_DRONE
	faction_id = "city"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_DRONE | CY_NPC_CAP_DELIVERY | CY_NPC_CAP_REPAIR | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM

/datum/cy_npc_profile/repair_drone
	name = "Repair Drone"
	role = CY_NPC_ROLE_REPAIR_DRONE
	faction_id = "corporate"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_DRONE | CY_NPC_CAP_REPAIR | CY_NPC_CAP_DELIVERY | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM

/datum/cy_npc_profile/medical_drone
	name = "Medical Drone"
	role = CY_NPC_ROLE_MEDICAL_DRONE
	faction_id = "city"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_DRONE | CY_NPC_CAP_MEDICAL | CY_NPC_CAP_DELIVERY | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM

/datum/cy_npc_profile/courier
	name = "Courier"
	role = CY_NPC_ROLE_COURIER
	faction_id = "city"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_DELIVERY | CY_NPC_CAP_CARRY | CY_NPC_CAP_ITEM_USE | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_SCHEDULE

/datum/cy_npc_profile/corporate_guard
	name = "Corporate Guard"
	role = CY_NPC_ROLE_CORPORATE
	faction_id = "corporate"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED | CY_NPC_CAP_GRAB | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_CARRY | CY_NPC_CAP_COVER | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_GROUP | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_EQUIPMENT

/datum/cy_npc_profile/police
	name = "Police"
	role = CY_NPC_ROLE_POLICE
	faction_id = "government"
	level = CY_NPC_LEVEL_PROFESSIONAL
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED | CY_NPC_CAP_GRAB | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_CARRY | CY_NPC_CAP_COVER | CY_NPC_CAP_AIM | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_GROUP | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_LAW | CY_NPC_CAP_EQUIPMENT

/datum/cy_npc_profile/bandit
	name = "Bandit"
	role = CY_NPC_ROLE_BANDIT
	faction_id = "bandit"
	level = CY_NPC_LEVEL_TRAINED
	capabilities = CY_NPC_CAP_HANDS | CY_NPC_CAP_INVENTORY | CY_NPC_CAP_MELEE | CY_NPC_CAP_RANGED | CY_NPC_CAP_GRAB | CY_NPC_CAP_RESTRAIN | CY_NPC_CAP_CARRY | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_GROUP | CY_NPC_CAP_PHANTOM | CY_NPC_CAP_EQUIPMENT

/datum/cy_npc_profile/hostile_animal
	name = "Hostile Animal"
	role = CY_NPC_ROLE_HOSTILE_ANIMAL
	faction_id = "wildlife"
	level = CY_NPC_LEVEL_PRIMITIVE
	capabilities = CY_NPC_CAP_MELEE | CY_NPC_CAP_SIGNAL | CY_NPC_CAP_PHANTOM

/datum/cy_npc_profile/animal
	name = "Animal"
	role = CY_NPC_ROLE_ANIMAL
	faction_id = "wildlife"
	level = CY_NPC_LEVEL_PRIMITIVE
	capabilities = CY_NPC_CAP_MELEE | CY_NPC_CAP_PHANTOM
