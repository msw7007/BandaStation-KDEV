/** Independently powered concert compartments; only explicitly mapped guards protect collision damage. */
/area/shuttle/stationtrauma_space/precision
	name = "Expedition vessel"
	requires_power = TRUE
	/// Bounded visual aftermath; repeated impacts extend one existing timer rather than stacking loops.
	var/damage_until = 0
	var/damage_timer

/area/shuttle/stationtrauma_space/precision/bridge
	name = "Vessel: bridge"

/area/shuttle/stationtrauma_space/precision/stage
	name = "Vessel: stage"

/area/shuttle/stationtrauma_space/precision/lounge
	name = "Vessel: lounge"

/area/shuttle/stationtrauma_space/precision/engineering
	name = "Vessel: engineering"

/area/shuttle/stationtrauma_space/precision/medical
	name = "Vessel: medical"

/area/shuttle/stationtrauma_space/precision/exterior
	name = "Vessel: exterior equipment"
	monitored_compartment = FALSE
	vacuum_by_design = TRUE

/area/shuttle/stationtrauma_space/precision/Destroy()
	deltimer(damage_timer)
	return ..()

/** Show cosmetic sparks and smoke, never hot sparks or reagent smoke. Equipment does not exclude a tile. */
/area/shuttle/stationtrauma_space/precision/proc/collision_visuals()
	damage_until = world.time + 30 SECONDS
	if(!damage_timer)
		damage_burst()

/area/shuttle/stationtrauma_space/precision/proc/damage_burst()
	damage_timer = null
	if(world.time >= damage_until)
		return
	var/list/tiles = list()
	for(var/list/deck as anything in get_zlevel_turf_lists())
		for(var/turf/tile as anything in deck)
			if(isopenturf(tile) && !isspaceturf(tile))
				tiles += tile
	if(length(tiles))
		for(var/index in 1 to min(3, length(tiles)))
			var/turf/tile = pick_n_take(tiles)
			new /obj/effect/temp_visual/small_smoke(tile)
			new /obj/effect/temp_visual/shuttle_impact_spark(tile)
	damage_timer = addtimer(CALLBACK(src, PROC_REF(damage_burst)), 5 SECONDS, TIMER_STOPPABLE)

/** A non-igniting visual using the existing spark sprite. */
/obj/effect/temp_visual/shuttle_impact_spark
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	duration = 8

/** Mapping-only collision armour; it travels with its tile without granting general invulnerability. */
/obj/effect/abstract/shuttle_impact_guard
	name = "shuttle collision armour"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	/// Bow and stage walls protect the turf; stage blastdoors protect only machinery on their tile.
	var/protect_turf = TRUE
	var/protect_machines = TRUE

/obj/effect/abstract/shuttle_impact_guard/blastdoor
	protect_turf = FALSE

/** Native overmap vessel; the addon does not modify other ships' landing or helm code. */
/obj/docking_port/mobile/stationtrauma_space/precision
	name = "Expedition vessel"
	shuttle_id = "precision_vessel"
	area_type = /area/shuttle/stationtrauma_space/precision
	width = 19
	height = 25
	dwidth = 9
	dheight = 0
	dir = NORTH
	preferred_direction = NORTH
	port_direction = SOUTH
	ship_class = ST_SHIP_MEDIUM
	movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)
	/// Only the current precision move can relax occupancy checks, never ordinary docking.
	var/datum/shuttle_impact/precision_move
	/// Private landing site retained until normal departure has released its native berth.
	var/datum/stationtrauma_overmap_site/space/precision/precision_site

/obj/docking_port/mobile/stationtrauma_space/precision/Destroy(force)
	if(!force)
		return ..()
	precision_move = null
	if(precision_site)
		if(overmap?.sites[precision_site.id] == precision_site)
			overmap.sites -= precision_site.id
		if(overmap?.docked == precision_site)
			overmap.docked = null
		QDEL_NULL(precision_site)
	return ..()

/obj/docking_port/mobile/stationtrauma_space/precision/check_dock(obj/docking_port/stationary/target, silent = FALSE)
	if(precision_move?.target == target && !precision_move.committed)
		return !orbital_only && canDock(target) == SHUTTLE_CAN_DOCK && precision_move.validate()
	return ..()

/** Privately registered physical landing, not an extra public station berth. */
/datum/stationtrauma_overmap_site/space/precision
	physical_docking = TRUE

/datum/stationtrauma_overmap_site/space/precision/Destroy()
	if(berth)
		qdel(berth, force = TRUE)
		berth = null
	return ..()

/obj/item/circuitboard/computer/stationtrauma_transponder/nt/precision
	callsign = "Expedition vessel"

/obj/machinery/computer/stationtrauma_transponder/precision
	circuit = /obj/item/circuitboard/computer/stationtrauma_transponder/nt/precision

/obj/machinery/computer/stationtrauma_space_navigation/precision
	name = "overmap helm"
	req_access = list(ACCESS_CENT_GENERAL)

/obj/machinery/computer/stationtrauma_space_navigation/precision/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(!allowed(ui.user))
		return FALSE
	return ..()

/** Mapped plasma circuit remains separate from supply and scrubber pipes. */
/obj/machinery/atmospherics/components/tank/plasma/layer1
	piping_layer = 1

/** Matching receiver preset for the hull's first-layer fuel pipe. */
/obj/machinery/atmospherics/components/unary/ship_engine_heater/plasma/layer1
	piping_layer = 1
