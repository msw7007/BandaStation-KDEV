// CYBERPUNK MACHINERY MODULARITY DESIGNS - moved out of code/game/machinery/_machinery.dm for architecture clarity.

/datum/design/cyberpunk_machine_module
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Machine Module"
	desc = "A Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ -certified maintenance module for Cyberpunk 13 machinery."
	id = "ryaznov_machine_module"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/cyberpunk_machine_module/power_governor
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Reserve Power Governor"
	id = "ryaznov_power_governor"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/power_governor

/datum/design/cyberpunk_machine_module/wear_buffer
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Wear Buffer"
	id = "ryaznov_wear_buffer"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/wear_buffer

/datum/design/cyberpunk_machine_module/reinforced_frame
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Reinforced Machine Frame"
	id = "ryaznov_reinforced_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module/reinforced_frame

/datum/design/cyberpunk_machine_module/service_bus
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Service Bus"
	id = "ryaznov_service_bus"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/service_bus

/datum/design/cyberpunk_machine_module/salvage_router
	name = "Р В Р’В Р РЋР РЏР В Р’В·Р В Р вЂ¦Р В РЎвЂўР В Р вЂ  Salvage Routing Matrix"
	id = "ryaznov_salvage_router"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/salvage_router

/datum/design/cyberpunk_machine_module/chem_reaction_accelerator
	name = "Р В Р’В Р вЂ™Р’В Р В Р Р‹Р В Р РЏР В Р’В Р вЂ™Р’В·Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  Chem Reaction Accelerator"
	id = "ryaznov_chem_reaction_accelerator"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/chem_reaction_accelerator

/datum/design/cyberpunk_machine_module/chem_yield_regulator
	name = "Р В Р’В Р вЂ™Р’В Р В Р Р‹Р В Р РЏР В Р’В Р вЂ™Р’В·Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  Chem Yield Regulator"
	id = "ryaznov_chem_yield_regulator"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/chem_yield_regulator

/datum/design/cyberpunk_machine_module/corporate_vending_bus
	name = "Р В Р’В Р вЂ™Р’В Р В Р Р‹Р В Р РЏР В Р’В Р вЂ™Р’В·Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  Corporate Vending Bus"
	id = "ryaznov_corporate_vending_bus"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/corporate_vending_bus

/datum/design/cyberpunk_machine_module/apc_efficiency_core
	name = "Р В Р’В Р вЂ™Р’В Р В Р Р‹Р В Р РЏР В Р’В Р вЂ™Р’В·Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р В РІР‚В  APC Efficiency Core"
	id = "ryaznov_apc_efficiency_core"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/apc_efficiency_core

/datum/design/cyberpunk_machine_module/emergency_battery
	name = "Ryaznov Emergency Buffer Battery"
	id = "ryaznov_emergency_battery"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/emergency_battery

/datum/design/cyberpunk_machine_module/arc_suppressor
	name = "Ryaznov Arc Suppressor"
	id = "ryaznov_arc_suppressor"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/arc_suppressor

/datum/design/cyberpunk_machine_module/production_overclocker
	name = "Ryaznov Production Overclocker"
	id = "ryaznov_production_overclocker"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module/production_overclocker

/datum/design/cyberpunk_machine_module/material_optimizer
	name = "Ryaznov Material Optimizer"
	id = "ryaznov_material_optimizer"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/material_optimizer

/datum/design/cyberpunk_machine_module/vendor_stock_router
	name = "Ryaznov Vendor Stock Router"
	id = "ryaznov_vendor_stock_router"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module/vendor_stock_router

/datum/design/cyberpunk_machine_module/vendor_security_cage
	name = "Ryaznov Vendor Security Cage"
	id = "ryaznov_vendor_security_cage"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/vendor_security_cage

/datum/design/cyberpunk_machine_module/medical_sterile_bus
	name = "Ryaznov Medical Sterile Bus"
	id = "ryaznov_medical_sterile_bus"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/medical_sterile_bus

/datum/design/cyberpunk_machine_module/security_response_core
	name = "Ryaznov Security Response Core"
	id = "ryaznov_security_response_core"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/security_response_core

/datum/design/cyberpunk_machine_module/network_filter
	name = "Ryaznov Network Filter"
	id = "ryaznov_network_filter"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/network_filter
