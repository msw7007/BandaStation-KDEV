/datum/design/board/cyberpunk_government_import
	name = "Government Emergency Power Import Board"
	desc = "The circuit board for a city emergency paid power import."
	id = "cyberpunk_government_import_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_government_import
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/datum/design/board/cyberpunk_corporate_energy_uplink
	name = "Corporate Energy Uplink Board"
	desc = "The circuit board for storing grid surplus in a corporation's remote energy reserve."
	id = "cyberpunk_corporate_energy_uplink_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_corporate_energy_uplink
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_power"

/datum/design/board/cyberpunk_corporate_collector
	name = "Corporate Energy Collector Board"
	desc = "The circuit board for buying remote corporate energy into a local powernet."
	id = "cyberpunk_corporate_collector_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_corporate_collector
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_power"

/datum/design/board/cyberpunk_dynamo
	name = "Emergency Dynamo Board"
	desc = "The circuit board for a manual emergency dynamo."
	id = "cyberpunk_dynamo_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_dynamo
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_nuclear_block"

/datum/design/board/cyberpunk_kinetic_reactor
	name = "Kinetic Reactor Board"
	desc = "The circuit board for a wheel-shaft-motor kinetic reactor."
	id = "cyberpunk_kinetic_reactor_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_kinetic_reactor
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_kinetic_reactor"

/datum/design/board/cyberpunk_chemical_teg
	name = "Chemical Thermoelectric Generator Board"
	desc = "The circuit board for a reagent-fed thermoelectric generator."
	id = "cyberpunk_chemical_teg_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_chemical_teg
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_SCIENCE
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_BENN
	cyberpunk_required_technology_id = "benn_chemical_teg"

/datum/design/board/cyberpunk_nuclear_block
	name = "Nuclear Energy Block Board"
	desc = "The circuit board for a coolant-managed uranium energy block."
	id = "cyberpunk_nuclear_block_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_nuclear_block
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_nuclear_block"

/datum/design/board/cyberpunk_cold_fusion
	name = "Cold Fusion Collider Board"
	desc = "The circuit board for an anomaly-prone cold fusion collider."
	id = "cyberpunk_cold_fusion_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_cold_fusion
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_cold_fusion"

/datum/design/board/cyberpunk_bioreactor
	name = "Bioreactor Board"
	desc = "The circuit board for a biomass reactor."
	id = "cyberpunk_bioreactor_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_bioreactor
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_SCIENCE
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_BENN
	cyberpunk_required_technology_id = "benn_bioreactor"

/datum/design/board/cyberpunk_energy_portal
	name = "Energy Portal Board"
	desc = "The circuit board for a contained Starlight energy portal."
	id = "cyberpunk_energy_portal_board"
	build_path = /obj/item/circuitboard/machine/cyberpunk_energy_portal
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_energy_portal"

/datum/design/cyberpunk_kinetic_wheel
	name = "Kinetic Reactor Wheel"
	desc = "A flywheel for a kinetic reactor."
	id = "cyberpunk_kinetic_wheel"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_power_part/kinetic_wheel
	category = list(RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_MISC)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_kinetic_reactor"

/datum/design/cyberpunk_kinetic_shaft
	name = "Kinetic Reactor Shaft"
	desc = "A shaft for a kinetic reactor."
	id = "cyberpunk_kinetic_shaft"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_power_part/kinetic_shaft
	category = list(RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_MISC)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_kinetic_reactor"

/datum/design/cyberpunk_kinetic_motor
	name = "Kinetic Reactor Motor"
	desc = "A motor-generator for a kinetic reactor."
	id = "cyberpunk_kinetic_motor"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_power_part/kinetic_motor
	category = list(RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_MISC)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_STARLIGHT
	cyberpunk_required_technology_id = "starlight_kinetic_reactor"

/datum/design/cyberpunk_coolant_rod
	name = "Reactor Coolant Rod"
	desc = "A replaceable coolant rod for nuclear energy blocks."
	id = "cyberpunk_coolant_rod"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_power_part/coolant_rod
	category = list(RND_CATEGORY_STOCK_PARTS + RND_SUBCATEGORY_STOCK_PARTS_MISC)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING
	cyberpunk_technology_corporation_id = CYBERPUNK_CORP_RYAZNOV
	cyberpunk_required_technology_id = "ryaznov_nuclear_block"
