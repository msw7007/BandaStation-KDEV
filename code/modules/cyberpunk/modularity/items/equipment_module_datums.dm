// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/datum/cyberpunk_item_module/armor_plate
	name = "armor plate"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 25
	armor_delta = list(MELEE = 8, BULLET = 8)

/datum/cyberpunk_item_module/armor_plate/t2
	name = "armor plate T2"
	module_tier = 2

/datum/cyberpunk_item_module/armor_plate/t3
	name = "armor plate T3"
	module_tier = 3

/datum/cyberpunk_item_module/armor_lining
	name = "protective lining"
	module_slot = "lining"
	integrity_delta = 10
	armor_delta = list(FIRE = 8, ACID = 5, WOUND = 3)

/datum/cyberpunk_item_module/armor_lining/t2
	name = "protective lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/armor_lining/t3
	name = "protective lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/weight_reducer
	name = "lightweight frame"
	module_slot = "utility"
	weight_delta = -1
	integrity_delta = -5
	armor_delta = list(MELEE = -2, BULLET = -2)

/datum/cyberpunk_item_module/weight_reducer/t2
	name = "lightweight frame T2"
	module_tier = 2

/datum/cyberpunk_item_module/weight_reducer/t3
	name = "lightweight frame T3"
	module_tier = 3

/datum/cyberpunk_item_module/mobility_servo
	name = "mobility servo"
	module_slot = "mobility"
	weight_delta = 0
	slowdown_delta = -0.15
	integrity_delta = 5
	armor_delta = list(ENERGY = 4)
	active_ability_name = "servo burst"
	active_ability_description = "The mobility frame dumps reserve torque into your limbs."
	active_cooldown = 24 SECONDS
	active_duration = 6 SECONDS
	active_slowdown_delta = -0.2
	active_stamina_restore = 12

/datum/cyberpunk_item_module/mobility_servo/t2
	name = "mobility servo T2"
	module_tier = 2

/datum/cyberpunk_item_module/mobility_servo/t3
	name = "mobility servo T3"
	module_tier = 3

/datum/cyberpunk_item_module/reactive_hardener
	name = "reactive hardener"
	module_slot = "active"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(MELEE = 6, BULLET = 6, LASER = 6, ENERGY = 6, WOUND = 4)
	active_ability_name = "reactive hardening"
	active_ability_description = "The plating locks into a short defensive state."
	active_cooldown = 45 SECONDS
	active_duration = 10 SECONDS
	active_armor_delta = list(MELEE = 14, BULLET = 14, LASER = 14, ENERGY = 14, BOMB = 8, WOUND = 8)

/datum/cyberpunk_item_module/reactive_hardener/t2
	name = "reactive hardener T2"
	module_tier = 2

/datum/cyberpunk_item_module/reactive_hardener/t3
	name = "reactive hardener T3"
	module_tier = 3

/datum/cyberpunk_item_module/impact_gel
	name = "impact gel"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 20
	armor_delta = list(MELEE = 12, BOMB = 8, WOUND = 8)

/datum/cyberpunk_item_module/impact_gel/t2
	name = "impact gel T2"
	module_tier = 2

/datum/cyberpunk_item_module/impact_gel/t3
	name = "impact gel T3"
	module_tier = 3

/datum/cyberpunk_item_module/ballistic_weave
	name = "ballistic weave"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(BULLET = 14, MELEE = 4, WOUND = 5)

/datum/cyberpunk_item_module/ballistic_weave/t2
	name = "ballistic weave T2"
	module_tier = 2

/datum/cyberpunk_item_module/ballistic_weave/t3
	name = "ballistic weave T3"
	module_tier = 3

/datum/cyberpunk_item_module/ablative_mesh
	name = "ablative mesh"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(LASER = 14, ENERGY = 8, FIRE = 4)

/datum/cyberpunk_item_module/ablative_mesh/t2
	name = "ablative mesh T2"
	module_tier = 2

/datum/cyberpunk_item_module/ablative_mesh/t3
	name = "ablative mesh T3"
	module_tier = 3

/datum/cyberpunk_item_module/insulation_lining
	name = "insulation lining"
	module_slot = "lining"
	integrity_delta = 8
	armor_delta = list(ENERGY = 10, FIRE = 8)
	active_ability_name = "thermal dump"
	active_ability_description = "The lining vents heat and stabilizes energy insulation."
	active_cooldown = 35 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(ENERGY = 12, FIRE = 16, LASER = 6)
	active_extinguish = TRUE

/datum/cyberpunk_item_module/insulation_lining/t2
	name = "insulation lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/insulation_lining/t3
	name = "insulation lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/chemseal_lining
	name = "chemseal lining"
	module_slot = "lining"
	integrity_delta = 8
	armor_delta = list(ACID = 14, BIO = 12)
	active_ability_name = "seal purge"
	active_ability_description = "The lining purges contaminants and seals vulnerable seams."
	active_cooldown = 40 SECONDS
	active_duration = 10 SECONDS
	active_armor_delta = list(ACID = 18, BIO = 18, FIRE = 6)

/datum/cyberpunk_item_module/chemseal_lining/t2
	name = "chemseal lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/chemseal_lining/t3
	name = "chemseal lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/sensor_bus
	name = "sensor bus"
	module_slot = "utility"
	weight_delta = 0
	integrity_delta = 5
	armor_delta = list(ENERGY = 2)
	active_ability_name = "threat scan"
	active_ability_description = "The bus predicts incoming angles and tightens defensive timing."
	active_cooldown = 30 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(MELEE = 5, BULLET = 5, LASER = 5, ENERGY = 5, WOUND = 5)

/datum/cyberpunk_item_module/blast_padding
	name = "blast padding"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 18
	armor_delta = list(BOMB = 16, MELEE = 5, FIRE = 5, WOUND = 4)

/datum/cyberpunk_item_module/blast_padding/t2
	name = "blast padding T2"
	module_tier = 2

/datum/cyberpunk_item_module/blast_padding/t3
	name = "blast padding T3"
	module_tier = 3

/datum/cyberpunk_item_module/trauma_mesh
	name = "trauma mesh"
	module_slot = "lining"
	integrity_delta = 12
	armor_delta = list(WOUND = 14, MELEE = 5, BULLET = 5)

/datum/cyberpunk_item_module/trauma_mesh/t2
	name = "trauma mesh T2"
	module_tier = 2

/datum/cyberpunk_item_module/trauma_mesh/t3
	name = "trauma mesh T3"
	module_tier = 3

/datum/cyberpunk_item_module/deflection_laminate
	name = "deflection laminate"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 18
	armor_delta = list(LASER = 10, BULLET = 8, ENERGY = 6)

/datum/cyberpunk_item_module/deflection_laminate/t2
	name = "deflection laminate T2"
	module_tier = 2

/datum/cyberpunk_item_module/deflection_laminate/t3
	name = "deflection laminate T3"
	module_tier = 3

/datum/cyberpunk_item_module/grounding_bus
	name = "grounding bus"
	module_slot = "utility"
	integrity_delta = 6
	armor_delta = list(ENERGY = 10, LASER = 4)
	active_ability_name = "grounding pulse"
	active_ability_description = "The bus shunts hostile charge through a short grounding loop."
	active_cooldown = 32 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(ENERGY = 18, LASER = 8)
	active_stamina_restore = 6

/datum/cyberpunk_item_module/grounding_bus/t2
	name = "grounding bus T2"
	module_tier = 2

/datum/cyberpunk_item_module/grounding_bus/t3
	name = "grounding bus T3"
	module_tier = 3

/datum/cyberpunk_item_module/medfoam_injector
	name = "medfoam injector"
	module_slot = "active"
	weight_delta = 1
	integrity_delta = 8
	armor_delta = list(WOUND = 4, BIO = 4)
	active_ability_name = "medfoam release"
	active_ability_description = "The injector floods inner pads with emergency foam."
	active_cooldown = 60 SECONDS
	active_duration = 6 SECONDS
	active_armor_delta = list(WOUND = 10, MELEE = 5, BULLET = 5)
	active_brute_heal = 6
	active_burn_heal = 4

/datum/cyberpunk_item_module/medfoam_injector/t2
	name = "medfoam injector T2"
	module_tier = 2

/datum/cyberpunk_item_module/medfoam_injector/t3
	name = "medfoam injector T3"
	module_tier = 3

/datum/cyberpunk_item_module/sensor_bus/t2
	name = "sensor bus T2"
	module_tier = 2

/datum/cyberpunk_item_module/sensor_bus/t3
	name = "sensor bus T3"
	module_tier = 3
