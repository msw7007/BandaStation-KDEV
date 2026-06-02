/obj/machinery/rnd/production/protolathe
	name = "protolathe"
	desc = "Converts raw materials into useful objects."
	icon_state = "protolathe"
	base_icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/protolathe
	production_animation = "protolathe_n"
	allowed_buildtypes = PROTOLATHE

/obj/machinery/rnd/production/protolathe/on_deconstruction(disassembled)
	log_game("Protolathe of type [type] [disassembled ? "disassembled" : "deconstructed"] by [key_name(usr)] at [get_area_name(src, TRUE)]")

	return ..()

/obj/machinery/rnd/production/protolathe/Initialize(mapload)
	if(!mapload)
		log_game("Protolathe of type [type] constructed by [key_name(usr)] at [get_area_name(src, TRUE)]")

	return ..()

/// Special subtype protolathe for offstation use. Has a more limited available design selection.
/obj/machinery/rnd/production/protolathe/offstation
	name = "ancient protolathe"
	desc = "Converts raw materials into useful objects. Its ancient construction may limit its ability to print all known technology."
	circuit = /obj/item/circuitboard/machine/protolathe/offstation
	allowed_buildtypes = AWAY_LATHE

/obj/machinery/rnd/production/protolathe/benn
	name = "Benn protolathe"
	corp_manufacturer = "Benn"
	stripe_color = "#52B4E9"

/obj/machinery/rnd/production/protolathe/ryaznov
	name = "Ryaznov protolathe"
	corp_manufacturer = "Ryaznov"
	stripe_color = "#EFB341"

/obj/machinery/rnd/production/protolathe/starlight
	name = "Starlight protolathe"
	corp_manufacturer = "Starlight"
	stripe_color = "#83ca41"
