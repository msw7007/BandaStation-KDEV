/datum/greyscale_config/material_airlock
	icon_file = 'icons/obj/doors/airlocks/material/material.dmi'

// MARK: Station airlocks
/obj/machinery/door/airlock/command

/obj/machinery/door/airlock/command/cap
	assemblytype = /obj/structure/door_assembly/door_assembly_cap

/obj/machinery/door/airlock/command/ce
	assemblytype = /obj/structure/door_assembly/door_assembly_ce

/obj/machinery/door/airlock/command/cmo
	assemblytype = /obj/structure/door_assembly/door_assembly_cmo

/obj/machinery/door/airlock/command/hop
	assemblytype = /obj/structure/door_assembly/door_assembly_hop

/obj/machinery/door/airlock/command/hos
	assemblytype = /obj/structure/door_assembly/door_assembly_hos

/obj/machinery/door/airlock/command/qm
	assemblytype = /obj/structure/door_assembly/door_assembly_qm

/obj/machinery/door/airlock/command/rd
	assemblytype = /obj/structure/door_assembly/door_assembly_rd

/obj/machinery/door/airlock/security

/obj/machinery/door/airlock/engineering

/obj/machinery/door/airlock/medical

/obj/machinery/door/airlock/maintenance

/obj/machinery/door/airlock/maintenance/external

/obj/machinery/door/airlock/mining

/obj/machinery/door/airlock/atmos

/obj/machinery/door/airlock/research

/obj/machinery/door/airlock/freezer

/obj/machinery/door/airlock/science

/obj/machinery/door/airlock/virology

/obj/machinery/door/airlock/hydroponics
	assemblytype = /obj/structure/door_assembly/door_assembly_hydro

/obj/machinery/door/airlock/eva
	assemblytype = /obj/structure/door_assembly/door_assembly_eva

/obj/machinery/door/airlock/psych
	assemblytype = /obj/structure/door_assembly/door_assembly_psych

/obj/machinery/door/airlock/corporate
	assemblytype = /obj/structure/door_assembly/door_assembly_corporate

/obj/machinery/door/airlock/lawyer
	assemblytype = /obj/structure/door_assembly/door_assembly_lawyer

/obj/machinery/door/airlock/service
	assemblytype = /obj/structure/door_assembly/door_assembly_service

/obj/machinery/door/airlock/bathroom
	assemblytype = /obj/structure/door_assembly/door_assembly_bathroom

/obj/machinery/door/airlock/grunge
	assemblytype = /obj/structure/door_assembly/door_assembly_grunge

// MARK: Glass station airlocks
/obj/machinery/door/airlock/command/cap/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/hop/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/cmo/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/rd/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/hos/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/qm/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/command/ce/glass
	opacity = 0
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/hydroponics/glass
	opacity = 0
	glass = TRUE

/obj/machinery/door/airlock/eva/glass
	opacity = 0
	glass = TRUE

/obj/machinery/door/airlock/service/glass
	opacity = 0
	glass = TRUE

/obj/machinery/door/airlock/psych/glass
	opacity = 0
	glass = TRUE

/obj/machinery/door/airlock/corporate/glass
	opacity = 0
	glass = TRUE

/obj/machinery/door/airlock/lawyer/glass
	opacity = 0
	glass = TRUE

// MARK: Other airlocks
/obj/machinery/door/airlock/gold

/obj/machinery/door/airlock/silver

/obj/machinery/door/airlock/diamond

/obj/machinery/door/airlock/uranium

/obj/machinery/door/airlock/plasma

/obj/machinery/door/airlock/bananium

/obj/machinery/door/airlock/tranquillite

/obj/machinery/door/airlock/sandstone

/obj/machinery/door/airlock/wood

// Station2 airlocks
/obj/machinery/door/airlock/public

// External airlocks
/obj/machinery/door/airlock/external

// Centcom airlocks
/obj/machinery/door/airlock/centcom

// Hatch airlocks
/obj/machinery/door/airlock/hatch

/obj/machinery/door/airlock/maintenance_hatch

// High security airlocks
/obj/machinery/door/airlock/highsecurity

// Multi-tile airlocks
/obj/machinery/door/airlock/multi_tile
	opacity = TRUE
	glass = FALSE

/obj/machinery/door/airlock/multi_tile/public
	opacity = TRUE
	glass = FALSE

/obj/machinery/door/airlock/multi_tile/public/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/command

/obj/machinery/door/airlock/multi_tile/command/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/security

/obj/machinery/door/airlock/multi_tile/security/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/atmospheric

/obj/machinery/door/airlock/multi_tile/atmospheric/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/engineering

/obj/machinery/door/airlock/multi_tile/engineering/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/supply

/obj/machinery/door/airlock/multi_tile/supply/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/medical

/obj/machinery/door/airlock/multi_tile/medical/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/multi_tile/research

/obj/machinery/door/airlock/multi_tile/research/glass
	opacity = FALSE
	glass = TRUE

// MARK: Cyberpunk city doors
/obj/machinery/door/cyberpunk
	name = "city door"
	desc = "A city door."
	icon = 'modular_bandastation/aesthetics/doors/icons/cyberpunk/32x48doors.dmi'
	icon_state = "basic_door"
	base_icon_state = "basic_door"
	autoclose = TRUE
	can_be_glass = FALSE
	has_access_panel = FALSE

/obj/machinery/door/cyberpunk/update_icon_state()
	. = ..()
	icon_state = base_icon_state

/obj/machinery/door/cyberpunk/update_overlays()
	. = ..()
	return list()

/obj/machinery/door/cyberpunk/animation_length(animation)
	return 0.3 SECONDS

/obj/machinery/door/cyberpunk/animation_segment_delay(animation)
	switch(animation)
		if(DOOR_OPENING_PASSABLE)
			return 0.2 SECONDS
		if(DOOR_OPENING_FINISHED)
			return 0.3 SECONDS
		if(DOOR_CLOSING_UNPASSABLE)
			return 0.1 SECONDS
		if(DOOR_CLOSING_FINISHED)
			return 0.3 SECONDS
	return 0.1 SECONDS

/obj/machinery/door/cyberpunk/internal
	name = "internal city door"
	icon_state = "inner_door"
	base_icon_state = "inner_door"

/obj/machinery/door/cyberpunk/glass
	name = "windowed city door"
	icon_state = "basic_door"
	base_icon_state = "basic_door"
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/cyberpunk/restricted
	name = "restricted city door"
	icon_state = "sector_door"
	base_icon_state = "sector_door"

/obj/machinery/door/cyberpunk/heavy
	name = "heavy city door"
	icon_state = "heavy_door"
	base_icon_state = "heavy_door"
	max_integrity = 450
	damage_deflection = 20

// Fake doors
/turf/closed/indestructible/fakedoor

/turf/closed/indestructible/fakedoor/maintenance

/turf/closed/indestructible/fakedoor/glass_airlock

/turf/closed/indestructible/fakedoor/engineering
