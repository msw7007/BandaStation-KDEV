// CYBERPUNK MACHINERY MODULARITY - moved out of code/game/machinery/_machinery.dm for architecture clarity.

/datum/cyberpunk_machine_module
	var/name = "generic machinery module"
	var/id = "generic"
	var/description = "A generic machinery module."
	var/manufacturer = "Р В РЎРЏР В·Р Р…Р С•Р Р†"
	var/corp_manufacturer = "Р В РЎРЏР В·Р Р…Р С•Р Р†"
	var/obj/item/module_item_type = /obj/item/cyberpunk_machine_module
	var/power_usage_multiplier = 1
	var/wear_multiplier = 1
	var/tool_time_multiplier = 1
	var/repair_multiplier = 1
	var/salvage_multiplier = 1
	var/integrity_bonus = 0
	var/chem_speed_multiplier = 1
	var/chem_cost_multiplier = 1
	var/vending_stock_multiplier = 1
	var/apc_efficiency_multiplier = 1
	var/production_time_multiplier = 1
	var/production_material_multiplier = 1
	var/failure_shock_multiplier = 1

/datum/cyberpunk_machine_module/proc/can_install(obj/machinery/machine, mob/living/user)
	return TRUE

/datum/cyberpunk_machine_module/proc/on_install(obj/machinery/machine, mob/living/user)
	if(integrity_bonus > 0 && machine.uses_integrity)
		machine.max_integrity += integrity_bonus
		machine.update_integrity(min(machine.max_integrity, machine.get_integrity() + integrity_bonus))
	machine.RefreshParts()
	return

/datum/cyberpunk_machine_module/proc/on_remove(obj/machinery/machine, mob/living/user)
	if(integrity_bonus > 0 && machine.uses_integrity)
		machine.max_integrity = max(1, machine.max_integrity - integrity_bonus)
		machine.update_integrity(min(machine.get_integrity(), machine.max_integrity))
	machine.RefreshParts()
	return

/datum/cyberpunk_machine_module/proc/get_diagnostic_line(obj/machinery/machine)
	return "[name] ([manufacturer]): [description]"

/datum/cyberpunk_machine_module/power_governor
	name = "reserve power governor"
	id = "power_governor"
	description = "Lowers passive and active machine power draw."
	module_item_type = /obj/item/cyberpunk_machine_module/power_governor
	power_usage_multiplier = 0.8

/datum/cyberpunk_machine_module/wear_buffer
	name = "wear buffer"
	id = "wear_buffer"
	description = "Reduces component wear from machine use."
	module_item_type = /obj/item/cyberpunk_machine_module/wear_buffer
	wear_multiplier = 0.75

/datum/cyberpunk_machine_module/reinforced_frame
	name = "reinforced machine frame"
	id = "reinforced_frame"
	description = "Adds structural integrity to the machine housing."
	module_item_type = /obj/item/cyberpunk_machine_module/reinforced_frame
	integrity_bonus = 25

/datum/cyberpunk_machine_module/service_bus
	name = "service bus"
	id = "service_bus"
	description = "Improves maintenance and repair efficiency."
	module_item_type = /obj/item/cyberpunk_machine_module/service_bus
	tool_time_multiplier = 0.9
	repair_multiplier = 1.25

/datum/cyberpunk_machine_module/salvage_router
	name = "salvage routing matrix"
	id = "salvage_router"
	description = "Improves recoverable component stack drops during clean deconstruction."
	module_item_type = /obj/item/cyberpunk_machine_module/salvage_router
	salvage_multiplier = 1.25

/datum/cyberpunk_machine_module/chem_reaction_accelerator
	name = "chem reaction accelerator"
	id = "chem_reaction_accelerator"
	description = "A general chemistry module that slightly improves reaction and handling speed."
	module_item_type = /obj/item/cyberpunk_machine_module/chem_reaction_accelerator
	tool_time_multiplier = 0.85
	chem_speed_multiplier = 0.85

/datum/cyberpunk_machine_module/chem_yield_regulator
	name = "chem yield regulator"
	id = "chem_yield_regulator"
	description = "A general chemistry module that trims reagent and energy waste."
	module_item_type = /obj/item/cyberpunk_machine_module/chem_yield_regulator
	power_usage_multiplier = 0.9
	wear_multiplier = 0.9
	chem_cost_multiplier = 0.9

/datum/cyberpunk_machine_module/corporate_vending_bus
	name = "corporate vending bus"
	id = "corporate_vending_bus"
	description = "A vending module for corporate stock routing and slightly cleaner service cycles."
	module_item_type = /obj/item/cyberpunk_machine_module/corporate_vending_bus
	power_usage_multiplier = 0.95
	wear_multiplier = 0.9
	vending_stock_multiplier = 1.1

/datum/cyberpunk_machine_module/business_vending_bus
	name = "business vending bus"
	id = "business_vending_bus"
	description = "Lets a player business link this vending machine to its warehouse stock, pricing and sale account."
	module_item_type = /obj/item/cyberpunk_machine_module/business_vending_bus
	power_usage_multiplier = 0.97
	wear_multiplier = 0.92
	vending_stock_multiplier = 1.05

/datum/cyberpunk_machine_module/apc_efficiency_core
	name = "APC efficiency core"
	id = "apc_efficiency_core"
	description = "An APC-focused module that reduces local control losses and passive draw."
	module_item_type = /obj/item/cyberpunk_machine_module/apc_efficiency_core
	power_usage_multiplier = 0.75
	wear_multiplier = 0.9
	apc_efficiency_multiplier = 0.85

/datum/cyberpunk_machine_module/emergency_battery
	name = "emergency buffer battery"
	id = "emergency_battery"
	description = "Stabilizes power draw and lets the machine tolerate short local power dips."
	module_item_type = /obj/item/cyberpunk_machine_module/emergency_battery
	power_usage_multiplier = 0.88
	wear_multiplier = 0.95
	failure_shock_multiplier = 0.85

/datum/cyberpunk_machine_module/arc_suppressor
	name = "arc suppressor"
	id = "arc_suppressor"
	description = "Reduces dangerous electrical shorts when worn machinery starts failing."
	module_item_type = /obj/item/cyberpunk_machine_module/arc_suppressor
	power_usage_multiplier = 0.95
	failure_shock_multiplier = 0.45

/datum/cyberpunk_machine_module/production_overclocker
	name = "production overclocker"
	id = "production_overclocker"
	description = "Speeds fabricators at the cost of higher power draw and component wear."
	module_item_type = /obj/item/cyberpunk_machine_module/production_overclocker
	power_usage_multiplier = 1.12
	wear_multiplier = 1.15
	production_time_multiplier = 0.82

/datum/cyberpunk_machine_module/material_optimizer
	name = "material optimizer"
	id = "material_optimizer"
	description = "Reduces fabricator material waste with slower machine staging."
	module_item_type = /obj/item/cyberpunk_machine_module/material_optimizer
	power_usage_multiplier = 0.95
	wear_multiplier = 0.95
	production_time_multiplier = 1.08
	production_material_multiplier = 0.88

/datum/cyberpunk_machine_module/vendor_stock_router
	name = "vendor stock router"
	id = "vendor_stock_router"
	description = "Improves vending restock routing and service throughput."
	module_item_type = /obj/item/cyberpunk_machine_module/vendor_stock_router
	power_usage_multiplier = 0.95
	wear_multiplier = 0.9
	tool_time_multiplier = 0.9
	vending_stock_multiplier = 1.25

/datum/cyberpunk_machine_module/vendor_security_cage
	name = "vendor security cage"
	id = "vendor_security_cage"
	description = "Reinforces vending internals against tilts, shocks and rough servicing."
	module_item_type = /obj/item/cyberpunk_machine_module/vendor_security_cage
	wear_multiplier = 0.85
	integrity_bonus = 35
	failure_shock_multiplier = 0.75

/datum/cyberpunk_machine_module/medical_sterile_bus
	name = "medical sterile bus"
	id = "medical_sterile_bus"
	description = "Improves medical machine servicing, repair response and safe power flow."
	module_item_type = /obj/item/cyberpunk_machine_module/medical_sterile_bus
	power_usage_multiplier = 0.92
	wear_multiplier = 0.88
	tool_time_multiplier = 0.88
	repair_multiplier = 1.15
	failure_shock_multiplier = 0.8

/datum/cyberpunk_machine_module/security_response_core
	name = "security response core"
	id = "security_response_core"
	description = "Reinforces camera, turret and alarm equipment for longer operation under stress."
	module_item_type = /obj/item/cyberpunk_machine_module/security_response_core
	power_usage_multiplier = 0.95
	wear_multiplier = 0.82
	integrity_bonus = 20

/datum/cyberpunk_machine_module/network_filter
	name = "network filter"
	id = "network_filter"
	description = "Reduces wear and power instability in computers, servers and telecom equipment."
	module_item_type = /obj/item/cyberpunk_machine_module/network_filter
	power_usage_multiplier = 0.86
	wear_multiplier = 0.88
	tool_time_multiplier = 0.92

/datum/cyberpunk_machine_module/vending_cyberspace_relay
	name = "vending cyberspace relay"
	id = "vending_cyberspace_relay"
	description = "Adds a hardline cyberspace access relay to a vending machine. Right-click the vendor to enter or leave the network."
	module_item_type = /obj/item/cyberpunk_machine_module/vending_cyberspace_relay
	power_usage_multiplier = 1.08
	wear_multiplier = 1.05

/datum/cyberpunk_machine_module/vending_contract_terminal
	name = "vending contract terminal"
	id = "vending_contract_terminal"
	description = "Adds contract cargo turn-in and private mail routing to a vending machine. Right-click the vendor to access the terminal."
	module_item_type = /obj/item/cyberpunk_machine_module/vending_contract_terminal
	power_usage_multiplier = 1.04
	wear_multiplier = 1.03

/datum/cyberpunk_machine_module/chem_reaction_accelerator/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/chem_master) || istype(machine, /obj/machinery/chem_dispenser)

/datum/cyberpunk_machine_module/chem_yield_regulator/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/chem_master) || istype(machine, /obj/machinery/chem_dispenser)

/datum/cyberpunk_machine_module/corporate_vending_bus/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/datum/cyberpunk_machine_module/business_vending_bus/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/datum/cyberpunk_machine_module/apc_efficiency_core/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/power/apc)

/datum/cyberpunk_machine_module/production_overclocker/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/rnd/production) || istype(machine, /obj/machinery/autolathe) || istype(machine, /obj/machinery/mecha_part_fabricator) || istype(machine, /obj/machinery/component_printer)

/datum/cyberpunk_machine_module/material_optimizer/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/rnd/production) || istype(machine, /obj/machinery/autolathe) || istype(machine, /obj/machinery/mecha_part_fabricator) || istype(machine, /obj/machinery/component_printer)

/datum/cyberpunk_machine_module/vendor_stock_router/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending) || istype(machine, /obj/machinery/smartfridge)

/datum/cyberpunk_machine_module/vendor_security_cage/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/datum/cyberpunk_machine_module/medical_sterile_bus/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/sleeper) || istype(machine, /obj/machinery/cryo_cell) || istype(machine, /obj/machinery/stasis) || istype(machine, /obj/machinery/dna_scannernew) || istype(machine, /obj/machinery/chem_master) || istype(machine, /obj/machinery/chem_dispenser)

/datum/cyberpunk_machine_module/security_response_core/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/camera) || istype(machine, /obj/machinery/porta_turret) || istype(machine, /obj/machinery/deployable_turret) || istype(machine, /obj/machinery/flasher) || istype(machine, /obj/machinery/firealarm) || istype(machine, /obj/machinery/turretid)

/datum/cyberpunk_machine_module/network_filter/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/computer) || istype(machine, /obj/machinery/modular_computer) || istype(machine, /obj/machinery/telecomms) || istype(machine, /obj/machinery/ntnet_relay) || istype(machine, /obj/machinery/quantum_server)

/datum/cyberpunk_machine_module/vending_cyberspace_relay/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/datum/cyberpunk_machine_module/vending_contract_terminal/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/proc/cyberpunk_machine_module_catalog()
	return list(
		/datum/cyberpunk_machine_module/power_governor,
		/datum/cyberpunk_machine_module/wear_buffer,
		/datum/cyberpunk_machine_module/reinforced_frame,
		/datum/cyberpunk_machine_module/service_bus,
		/datum/cyberpunk_machine_module/salvage_router,
		/datum/cyberpunk_machine_module/emergency_battery,
		/datum/cyberpunk_machine_module/arc_suppressor,
		/datum/cyberpunk_machine_module/production_overclocker,
		/datum/cyberpunk_machine_module/material_optimizer,
		/datum/cyberpunk_machine_module/chem_reaction_accelerator,
		/datum/cyberpunk_machine_module/chem_yield_regulator,
		/datum/cyberpunk_machine_module/corporate_vending_bus,
		/datum/cyberpunk_machine_module/business_vending_bus,
		/datum/cyberpunk_machine_module/vendor_stock_router,
		/datum/cyberpunk_machine_module/vendor_security_cage,
		/datum/cyberpunk_machine_module/apc_efficiency_core,
		/datum/cyberpunk_machine_module/medical_sterile_bus,
		/datum/cyberpunk_machine_module/security_response_core,
		/datum/cyberpunk_machine_module/network_filter,
		/datum/cyberpunk_machine_module/vending_cyberspace_relay,
		/datum/cyberpunk_machine_module/vending_contract_terminal,
	)

/obj/item/cyberpunk_machine_module
	name = "machine module"
	desc = "A Р В РЎРЏР В·Р Р…Р С•Р Р†-produced Cyberpunk 13 machinery module shell."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "integrated_circuit"
	w_class = WEIGHT_CLASS_SMALL
	var/manufacturer = "Р В РЎРЏР В·Р Р…Р С•Р Р†"
	var/corp_manufacturer = "Р В РЎРЏР В·Р Р…Р С•Р Р†"
	var/module_datum_type = /datum/cyberpunk_machine_module

/obj/item/cyberpunk_machine_module/proc/create_module_datum()
	return new module_datum_type

/obj/item/cyberpunk_machine_module/examine(mob/user)
	. = ..()
	. += span_notice("Manufacturer: [manufacturer].")

/obj/item/cyberpunk_machine_module/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/machinery/machine = interacting_with
	if(!istype(machine))
		return NONE
	if(!machine.panel_open)
		to_chat(user, span_warning("Open the maintenance panel before installing a machine module."))
		return ITEM_INTERACT_BLOCKING
	var/datum/cyberpunk_machine_module/module = create_module_datum()
	if(machine.install_cyberpunk_module(module, user, TRUE))
		to_chat(user, span_notice("You install [module.name] into [machine]."))
		qdel(src)
		return ITEM_INTERACT_SUCCESS
	qdel(module)
	to_chat(user, span_warning("This machine cannot accept that module."))
	return ITEM_INTERACT_BLOCKING

/obj/item/cyberpunk_machine_module/power_governor
	name = "reserve power governor"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/power_governor

/obj/item/cyberpunk_machine_module/wear_buffer
	name = "wear buffer"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/wear_buffer

/obj/item/cyberpunk_machine_module/reinforced_frame
	name = "reinforced machine frame"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_machine_module/reinforced_frame

/obj/item/cyberpunk_machine_module/service_bus
	name = "service bus"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/service_bus

/obj/item/cyberpunk_machine_module/salvage_router
	name = "salvage routing matrix"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/salvage_router

/obj/item/cyberpunk_machine_module/chem_reaction_accelerator
	name = "chem reaction accelerator"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/chem_reaction_accelerator

/obj/item/cyberpunk_machine_module/chem_yield_regulator
	name = "chem yield regulator"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/chem_yield_regulator

/obj/item/cyberpunk_machine_module/corporate_vending_bus
	name = "corporate vending bus"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/corporate_vending_bus

/obj/item/cyberpunk_machine_module/business_vending_bus
	name = "business vending bus"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/business_vending_bus

/obj/item/cyberpunk_machine_module/apc_efficiency_core
	name = "APC efficiency core"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/apc_efficiency_core

/obj/item/cyberpunk_machine_module/emergency_battery
	name = "emergency buffer battery"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_machine_module/emergency_battery

/obj/item/cyberpunk_machine_module/arc_suppressor
	name = "arc suppressor"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/arc_suppressor

/obj/item/cyberpunk_machine_module/production_overclocker
	name = "production overclocker"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/production_overclocker

/obj/item/cyberpunk_machine_module/material_optimizer
	name = "material optimizer"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/material_optimizer

/obj/item/cyberpunk_machine_module/vendor_stock_router
	name = "vendor stock router"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/vendor_stock_router

/obj/item/cyberpunk_machine_module/vendor_security_cage
	name = "vendor security cage"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_machine_module/vendor_security_cage

/obj/item/cyberpunk_machine_module/medical_sterile_bus
	name = "medical sterile bus"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/medical_sterile_bus

/obj/item/cyberpunk_machine_module/security_response_core
	name = "security response core"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/security_response_core

/obj/item/cyberpunk_machine_module/network_filter
	name = "network filter"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/network_filter

/obj/item/cyberpunk_machine_module/vending_cyberspace_relay
	name = "vending cyberspace relay"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/vending_cyberspace_relay

/obj/item/cyberpunk_machine_module/vending_contract_terminal
	name = "vending contract terminal"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/vending_contract_terminal
