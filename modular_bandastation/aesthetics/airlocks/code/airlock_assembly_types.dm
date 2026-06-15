// Station airlocks assembly
/obj/structure/door_assembly

/obj/structure/door_assembly/door_assembly_public

/obj/structure/door_assembly/door_assembly_com

/obj/structure/door_assembly/door_assembly_cap
	base_name = "captain airlock"
	airlock_type = /obj/machinery/door/airlock/command/cap
	glass_type = /obj/machinery/door/airlock/command/cap/glass

/obj/structure/door_assembly/door_assembly_hop
	base_name = "head of personnel airlock"
	airlock_type = /obj/machinery/door/airlock/command/hop
	glass_type = /obj/machinery/door/airlock/command/hop/glass

/obj/structure/door_assembly/door_assembly_cmo
	base_name = "chief medical officer airlock"
	airlock_type = /obj/machinery/door/airlock/command/cmo
	glass_type = /obj/machinery/door/airlock/command/cmo/glass

/obj/structure/door_assembly/door_assembly_rd
	base_name = "research director airlock"
	airlock_type = /obj/machinery/door/airlock/command/rd
	glass_type = /obj/machinery/door/airlock/command/rd/glass

/obj/structure/door_assembly/door_assembly_hos
	base_name = "head of security airlock"
	airlock_type = /obj/machinery/door/airlock/command/hos
	glass_type = /obj/machinery/door/airlock/command/hos/glass

/obj/structure/door_assembly/door_assembly_qm
	base_name = "quartermaster airlock"
	airlock_type = /obj/machinery/door/airlock/command/qm
	glass_type = /obj/machinery/door/airlock/command/qm/glass

/obj/structure/door_assembly/door_assembly_ce
	base_name = "chief engineer airlock"
	airlock_type = /obj/machinery/door/airlock/command/ce
	glass_type = /obj/machinery/door/airlock/command/ce/glass

/obj/structure/door_assembly/door_assembly_sec

/obj/structure/door_assembly/door_assembly_eng

/obj/structure/door_assembly/door_assembly_min

/obj/structure/door_assembly/door_assembly_atmo

/obj/structure/door_assembly/door_assembly_research

/obj/structure/door_assembly/door_assembly_science

/obj/structure/door_assembly/door_assembly_med

/obj/structure/door_assembly/door_assembly_viro

/obj/structure/door_assembly/door_assembly_hydro
	base_name = "hydroponics airlock"
	airlock_type = /obj/machinery/door/airlock/hydroponics
	glass_type = /obj/machinery/door/airlock/hydroponics/glass

/obj/structure/door_assembly/door_assembly_corporate
	name = "corporate airlock assembly"
	base_name = "corporate airlock"
	glass_type = /obj/machinery/door/airlock/corporate/glass
	airlock_type = /obj/machinery/door/airlock/corporate

/obj/structure/door_assembly/door_assembly_lawyer
	name = "lawyer airlock assembly"
	base_name = "lawyer airlock"
	glass_type = /obj/machinery/door/airlock/lawyer/glass
	airlock_type = /obj/machinery/door/airlock/lawyer

/obj/structure/door_assembly/door_assembly_psych
	name = "psych airlock assembly"
	base_name = "psych airlock"
	glass_type = /obj/machinery/door/airlock/psych/glass
	airlock_type = /obj/machinery/door/airlock/psych

/obj/structure/door_assembly/door_assembly_eva
	name = "eva airlock assembly"
	base_name = "eva airlock"
	glass_type = /obj/machinery/door/airlock/eva/glass
	airlock_type = /obj/machinery/door/airlock/eva

/obj/structure/door_assembly/door_assembly_service
	base_name = "service airlock"
	airlock_type = /obj/machinery/door/airlock/service
	glass_type = /obj/machinery/door/airlock/service/glass

/obj/structure/door_assembly/door_assembly_bathroom
	base_name = "bathroom airlock"
	airlock_type = /obj/machinery/door/airlock/bathroom
	noglass = TRUE

/obj/structure/door_assembly/door_assembly_mai

/obj/structure/door_assembly/door_assembly_extmai

/obj/structure/door_assembly/door_assembly_ext

/obj/structure/door_assembly/door_assembly_fre

/obj/structure/door_assembly/door_assembly_hatch

/obj/structure/door_assembly/door_assembly_mhatch

/obj/structure/door_assembly/door_assembly_highsecurity

/obj/structure/door_assembly/door_assembly_centcom

/obj/structure/door_assembly/door_assembly_grunge

// Mineral airlocks
/obj/structure/door_assembly/door_assembly_gold

/obj/structure/door_assembly/door_assembly_silver

/obj/structure/door_assembly/door_assembly_diamond

/obj/structure/door_assembly/door_assembly_uranium

/obj/structure/door_assembly/door_assembly_plasma

/obj/structure/door_assembly/door_assembly_bananium

/obj/structure/door_assembly/door_assembly_tranquillite

/obj/structure/door_assembly/door_assembly_sandstone

/obj/structure/door_assembly/door_assembly_wood

// Multi-tile airlocks
/obj/structure/door_assembly/multi_tile
	airlock_type = /obj/machinery/door/airlock/multi_tile/public
	opacity = TRUE
	glass = FALSE

/obj/structure/door_assembly/multi_tile/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/structure/door_assembly/multi_tile/door_assembly_public
	airlock_type = /obj/machinery/door/airlock/multi_tile/public
	glass_type = /obj/machinery/door/airlock/multi_tile/public/glass

/obj/structure/door_assembly/multi_tile/command
	base_name = "large command airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/command
	glass_type = /obj/machinery/door/airlock/multi_tile/command/glass

/obj/structure/door_assembly/multi_tile/security
	base_name = "large security airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/security
	glass_type = /obj/machinery/door/airlock/multi_tile/security/glass

/obj/structure/door_assembly/multi_tile/atmospheric
	base_name = "large atmospheric airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/atmospheric
	glass_type = /obj/machinery/door/airlock/multi_tile/atmospheric/glass

/obj/structure/door_assembly/multi_tile/engineering
	base_name = "large engineering airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/engineering
	glass_type = /obj/machinery/door/airlock/multi_tile/engineering/glass

/obj/structure/door_assembly/multi_tile/supply
	base_name = "large supply airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/supply
	glass_type = /obj/machinery/door/airlock/multi_tile/supply/glass

/obj/structure/door_assembly/multi_tile/medical
	base_name = "large medical airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/medical
	glass_type = /obj/machinery/door/airlock/multi_tile/medical/glass

/obj/structure/door_assembly/multi_tile/research
	base_name = "large research airlock"
	airlock_type = /obj/machinery/door/airlock/multi_tile/research
	glass_type = /obj/machinery/door/airlock/multi_tile/research/glass
