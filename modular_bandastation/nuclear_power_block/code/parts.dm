/// Reusable pressure seal that becomes a normal damaging thrown item when released.
/obj/item/nuclear_power_block_lid
	name = "reactor pressure lid"
	desc = "A reinforced pressure lid. Repair a damaged lid with one titanium sheet, then weld it onto an open reactor."
	icon = 'modular_bandastation/nuclear_power_block/icons/lid.dmi'
	icon_state = "lid"
	w_class = WEIGHT_CLASS_HUGE
	throwforce = NUCLEAR_POWER_BLOCK_LID_DAMAGE
	throw_range = NUCLEAR_POWER_BLOCK_LID_RANGE
	throw_speed = NUCLEAR_POWER_BLOCK_LID_SPEED
	/// A released lid must be repaired before it can be staged for welding.
	var/broken = FALSE
	/// Prevents concurrent repair actions consuming multiple titanium sheets.
	var/repairing = FALSE
	/// Temporary collision exemption for the launching reactor, cleared after flight.
	var/datum/weakref/released_from

/obj/item/nuclear_power_block_lid/Destroy()
	released_from = null
	return ..()

/// Invoked when the standard thrown-item flight ends, whether it hits somebody or not.
/obj/item/nuclear_power_block_lid/proc/break_lid()
	released_from = null
	broken = TRUE
	icon_state = "lid_broken"
	name = "broken reactor pressure lid"

/obj/item/nuclear_power_block_lid/item_interaction(mob/living/user, obj/item/item, list/modifiers)
	if(!istype(item, /obj/item/stack/sheet/mineral/titanium))
		return NONE
	if(!broken || repairing || released_from)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/stack/sheet/mineral/titanium/sheet = item
	repairing = TRUE
	var/finished = do_after(user, NUCLEAR_POWER_BLOCK_LID_REPAIR_TIME, src)
	if(QDELETED(src))
		return ITEM_INTERACT_BLOCKING
	repairing = FALSE
	if(!finished || !broken || QDELETED(user) || QDELETED(sheet) || !user.is_holding(sheet) || !Adjacent(user) || user.incapacitated || released_from || !sheet.use(1))
		return ITEM_INTERACT_BLOCKING
	broken = FALSE
	icon_state = "lid"
	name = initial(name)
	return ITEM_INTERACT_SUCCESS

/// Standard machine-frame board with independently replaceable turbine parts and two vessel slots.
/obj/item/circuitboard/machine/nuclear_power_block
	name = "Uranium power block"
	greyscale_colors = CIRCUIT_COLOR_ENGINEERING
	build_path = /obj/machinery/power/nuclear_power_block
	req_components = list(
		/datum/stock_part/capacitor = 1,
		/datum/stock_part/servo = 1,
		/obj/item/reagent_containers/cup/beaker = 2,
		/obj/item/stack/cable_coil = 10,
		/obj/item/stack/sheet/plasteel = 10,
	)

/// Native machine-frame construction must reserve the entire 3x3 footprint.
/obj/item/circuitboard/machine/nuclear_power_block/completion_requirements(obj/structure/frame/install_frame, mob/living/user)
	. = ..()
	if(!.)
		return
	var/turf/origin = get_turf(install_frame)
	for(var/x in 0 to 2)
		for(var/y in 0 to 2)
			var/turf/tile = locate(origin.x + x, origin.y + y, origin.z)
			if(!isopenturf(tile))
				balloon_alert(user, "needs a clear 3x3 floor!")
				return FALSE
			for(var/atom/movable/obstacle in tile)
				if(obstacle != install_frame && obstacle.density)
					balloon_alert(user, "needs a clear 3x3 floor!")
					return FALSE
	return TRUE

/// Engineering circuit imprinter recipe; no deployment-specific acquisition mechanism is needed.
/datum/design/board/nuclear_power_block
	name = "Uranium power block"
	desc = "Integrated uranium reactor with two internal turbines."
	build_path = /obj/item/circuitboard/machine/nuclear_power_block
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING

/// A standalone research unlock avoids replacing upstream engineering-node design lists.
/datum/techweb_node/nuclear_power_block
	display_name = "Integrated uranium power"
	description = "A compact fission power block with internal cooling and turbine generation."
	prerequisite_nodes = list(/datum/techweb_node/energy_manipulation)
	unlocked_designs = list(/datum/design/board/nuclear_power_block)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)
	announce_channels = list(RADIO_CHANNEL_ENGINEERING)
