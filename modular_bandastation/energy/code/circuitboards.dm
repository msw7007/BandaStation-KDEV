/obj/item/circuitboard/machine/cyberpunk_government_import
	name = "Government Emergency Power Import"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/government_import
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 2,
		/obj/item/stack/sheet/iron = 5,
	)

/obj/item/circuitboard/machine/cyberpunk_corporate_energy_uplink
	name = "Corporate Energy Uplink"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_corporate_energy_uplink
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 2,
		/datum/stock_part/scanning_module = 1,
	)

/obj/item/circuitboard/machine/cyberpunk_corporate_collector
	name = "Corporate Energy Collector"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/corporate_collector
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 2,
		/datum/stock_part/scanning_module = 1,
	)

/obj/item/circuitboard/machine/cyberpunk_dynamo
	name = "Emergency Dynamo"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_dynamo
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/iron = 8,
	)

/obj/item/circuitboard/machine/cyberpunk_kinetic_reactor
	name = "Kinetic Reactor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/kinetic
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/obj/item/cyberpunk_power_part/kinetic_wheel = 1,
		/obj/item/cyberpunk_power_part/kinetic_shaft = 1,
		/obj/item/cyberpunk_power_part/kinetic_motor = 1,
	)

/obj/item/circuitboard/machine/cyberpunk_chemical_teg
	name = "Chemical Thermoelectric Generator"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/chemical_teg
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 2,
		/datum/stock_part/micro_laser = 1,
	)

/obj/item/circuitboard/machine/cyberpunk_nuclear_block
	name = "Nuclear Energy Block"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/nuclear_block
	req_components = list(
		/obj/item/stack/cable_coil = 15,
		/datum/stock_part/capacitor = 3,
		/obj/item/cyberpunk_power_part/coolant_rod = 4,
		/obj/item/stack/sheet/mineral/uranium = 5,
	)

/obj/item/circuitboard/machine/cyberpunk_cold_fusion
	name = "Cold Fusion Collider"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/cold_fusion
	req_components = list(
		/obj/item/stack/cable_coil = 20,
		/datum/stock_part/capacitor = 4,
		/datum/stock_part/micro_laser = 4,
	)

/obj/item/circuitboard/machine/cyberpunk_bioreactor
	name = "Bioreactor"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/bioreactor
	req_components = list(
		/obj/item/stack/cable_coil = 10,
		/datum/stock_part/capacitor = 2,
		/datum/stock_part/matter_bin = 2,
	)

/obj/item/circuitboard/machine/cyberpunk_energy_portal
	name = "Energy Portal"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/cyberpunk_generator/energy_portal
	req_components = list(
		/obj/item/stack/cable_coil = 20,
		/datum/stock_part/capacitor = 4,
		/datum/stock_part/scanning_module = 2,
	)
