/obj/machinery/atmospherics/components/unary/passive_vent
	icon_state = "passive_vent_map-3"

	name = "passive vent"
	desc = "It is an open vent."

	can_unwrench = TRUE
	hide = TRUE
	layer = GAS_SCRUBBER_LAYER
	shift_underlay_only = FALSE

	pipe_state = "pvent"
	has_cap_visuals = TRUE
	vent_movement = VENTCRAWL_ALLOWED | VENTCRAWL_CAN_SEE | VENTCRAWL_ENTRANCE_ALLOWED
	interaction_flags_click = NEED_VENTCRAWL


/obj/machinery/atmospherics/components/unary/passive_vent/update_icon_nopipes()
	cut_overlays()
	if(underfloor_state)
		var/image/cap = get_pipe_image(icon, "vent_cap", initialize_directions, pipe_color)
		cap.appearance_flags |= RESET_COLOR|KEEP_APART
		add_overlay(cap)
	else
		PIPING_LAYER_SHIFT(src, PIPING_LAYER_DEFAULT)
	icon_state = "passive_vent"

/obj/machinery/atmospherics/components/unary/passive_vent/process_atmos()
	var/turf/location = get_turf(loc)
	if(isclosedturf(location))
		return

	var/datum/gas_mixture/external = lightweight_atmos_scan_gasmix(location)
	var/datum/gas_mixture/internal = airs[1]

	if(!internal.volume || !external.volume)
		return

	var/internal_pressure = internal.return_pressure()
	var/external_pressure = external.return_pressure()
	if(internal_pressure > external_pressure)
		if(release_gas_mixture_to_lightweight_atmos(location, internal, external_pressure, 0.5))
			update_parents()
	else if(external_pressure > internal_pressure)
		if(collect_lightweight_atmos_to_gas_mixture(location, internal, 10))
			update_parents()
		update_parents()

/obj/machinery/atmospherics/components/unary/passive_vent/layer2
	piping_layer = 2
	icon_state = "passive_vent_map-2"

/obj/machinery/atmospherics/components/unary/passive_vent/layer4
	piping_layer = 4
	icon_state = "passive_vent_map-4"
