/** Immutable hull/target pairing used by previews and revalidated after native yielding preflight. */
/datum/shuttle_impact
	/// References are scoped to one console operation and cleared on destruction.
	var/obj/docking_port/mobile/stationtrauma_space/precision/ship
	/// Private temporary berth, owned by the console or its landing site.
	var/obj/docking_port/stationary/target
	/// Only planetary targets may exceed the station collision budget.
	var/planetary = FALSE
	/// Owned source turf -> paired destination, respecting native rotation order.
	var/list/pairs = list()
	/// Destination footprint for complete multitile obstacle admission.
	var/list/target_tiles = list()
	/// Visible source types at quote time.
	var/list/source_types = list()
	/// Original obstacle -> type for terrain or location for objects.
	var/list/obstructions = list()
	/// Still-present quoted obstacles; moved objects are never destroyed remotely.
	var/list/current_obstructions = list()
	/// Unique collision destinations -> corresponding source cells.
	var/list/impact_tiles = list()
	/// Only incoming equipment receives direct hull-impact damage.
	var/list/incoming_machines = list()
	/// Percentage of real moving cells, not the hull's bounding rectangle.
	var/collision_percent = 0
	/// Failed-validation explanation for the operator.
	var/problem
	/// The final native interlock has accepted this plan exactly once.
	var/committed = FALSE

/datum/shuttle_impact/New(obj/docking_port/mobile/stationtrauma_space/precision/vessel, obj/docking_port/stationary/destination, surface = FALSE)
	ship = vessel
	target = destination
	planetary = surface
	return ..()

/datum/shuttle_impact/Destroy()
	ship = null
	target = null
	pairs = null
	target_tiles = null
	source_types = null
	obstructions = null
	current_obstructions = null
	impact_tiles = null
	incoming_machines = null
	return ..()

/** Count actual moving hull cells, including all cells occupied by a multitile obstacle. */
/datum/shuttle_impact/proc/build()
	if(QDELETED(ship) || QDELETED(target))
		return FALSE
	ship.initialize_docking_layers()
	var/list/source = ship.return_ordered_turfs(ship.x, ship.y, ship.z, ship.dir)
	var/list/destination = ship.return_ordered_turfs(target.x, target.y, target.z, target.dir)
	if(length(source) != length(destination))
		return FALSE
	for(var/index in 1 to length(source))
		var/turf/old_tile = source[index]
		if(!ship.has_docking_layer(old_tile) || !ship.shuttle_areas[get_area(old_tile)])
			continue
		pairs[old_tile] = destination[index]
		target_tiles[destination[index]] = TRUE
		source_types[old_tile] = old_tile.type
		for(var/obj/machinery/machine in old_tile)
			incoming_machines[machine] = TRUE
	return validate(TRUE)

/** True for fixed construction, not people, carried items or cosmetic effects. */
/datum/shuttle_impact/proc/is_obstacle(obj/thing)
	return !iseffect(thing) && !isitem(thing) && !istype(thing, /obj/docking_port) && (thing.anchored || thing.density)

/** Rebuild the quote without changing the world; newly introduced blockers always cancel a prepared move. */
/datum/shuttle_impact/proc/validate(initial = FALSE)
	problem = null
	if(QDELETED(ship) || QDELETED(target) || !length(pairs))
		return FALSE
	var/list/current = list()
	var/list/hits = list()
	var/list/landing_bounds = ship.return_coords(target.x, target.y, target.dir)
	for(var/obj/docking_port/mobile/other as anything in SSshuttle.mobile_docking_ports)
		if(other.z != target.z)
			continue
		var/list/bounds = other.return_coords()
		var/list/overlap = get_overlap(landing_bounds[1], landing_bounds[2], landing_bounds[3], landing_bounds[4], bounds[1], bounds[2], bounds[3], bounds[4])
		if(!length(overlap[1]) || !length(overlap[2]))
			continue
		for(var/turf/destination as anything in target_tiles)
			if(other.is_in_shuttle_bounds(destination))
				problem = "Another vessel occupies the destination."
				return FALSE
	for(var/turf/source as anything in pairs)
		var/turf/destination = pairs[source]
		if(source.type != source_types[source] || !ship.has_docking_layer(source))
			problem = "The hull changed during targeting."
			return FALSE
		if(!destination || destination.x <= SHUTTLE_TRANSIT_BORDER || destination.y <= SHUTTLE_TRANSIT_BORDER || destination.x >= world.maxx - SHUTTLE_TRANSIT_BORDER || destination.y >= world.maxy - SHUTTLE_TRANSIT_BORDER)
			problem = "Outside the safe map boundary."
			return FALSE
		if(isindestructiblefloor(destination) || istype(destination, /turf/closed/indestructible))
			problem = "An indestructible structure blocks the jump."
			return FALSE
		if(destination.density)
			if(!iswallturf(destination) && !ismineralturf(destination))
				problem = "This terrain cannot be breached."
				return FALSE
			hits[destination] = source
			current[destination] = destination.type
		for(var/obj/obstacle in destination)
			if(!is_obstacle(obstacle))
				continue
			if(obstacle.resistance_flags & (INDESTRUCTIBLE|SHUTTLE_CRUSH_PROOF))
				problem = "Protected equipment blocks the jump."
				return FALSE
			for(var/turf/occupied as anything in obstacle.locs)
				if(!target_tiles[occupied])
					problem = "A multitile obstacle extends outside the landing footprint."
					return FALSE
			hits[destination] = source
			current[obstacle] = get_turf(obstacle)
	collision_percent = 100 * length(hits) / length(pairs)
	if(!planetary && collision_percent > SHUTTLE_MANEUVER_COLLISION_LIMIT)
		problem = "Station collision limit exceeded."
		return FALSE
	if(!initial)
		for(var/atom/obstacle as anything in current)
			if(obstructions[obstacle] != current[obstacle])
				problem = "New obstruction detected. Retarget the jump."
				return FALSE
	else
		obstructions = current
	current_obstructions = current
	impact_tiles = hits
	return TRUE

/** Clear only the approved obstacles at the final non-sleeping movement boundary; refresh substrate snapshots. */
/datum/shuttle_impact/proc/commit()
	if(committed || !validate())
		return FALSE
	var/datum/stationtrauma_docking_layers/layers = ship.overmap?.docking_relocation
	if(!layers || !layers.validate())
		return FALSE
	committed = TRUE
	for(var/atom/obstacle as anything in current_obstructions)
		if(QDELETED(obstacle))
			continue
		if(iswallturf(obstacle))
			var/turf/closed/wall/wall = obstacle
			wall.dismantle_wall(TRUE)
		else if(ismineralturf(obstacle))
			var/turf/closed/mineral/mineral = obstacle
			mineral.gets_drilled()
		else if(isobj(obstacle))
			var/obj/object = obstacle
			object.deconstruct(FALSE)
	for(var/turf/source as anything in layers.cells)
		var/datum/stationtrauma_docking_layer_cell/cell = layers.cells[source]
		cell.target_type = cell.destination.type
		cell.target_prefix = list()
		cell.target_prefix += cell.destination.baseturfs
		cell.target_prefix += cell.destination.type
	return TRUE

/** Apply one finite damage wave to the arrived ship; secondary holes do not become new impact centres. */
/datum/shuttle_impact/proc/aftermath()
	if(!committed || !length(impact_tiles) || QDELETED(ship))
		return
	var/excess = max(0, collision_percent - SHUTTLE_MANEUVER_COLLISION_LIMIT)
	var/severe_chance = min(100, excess * 2)
	var/partial_chance = min(100 - severe_chance, excess)
	var/list/damage = list()
	var/list/shock_tiles = list()
	var/list/people = list()
	for(var/turf/impact as anything in impact_tiles)
		damage[impact] = 100
		for(var/turf/neighbor in orange(1, impact))
			if(ship.has_docking_layer(neighbor) && !damage[neighbor])
				damage[neighbor] = -1
		for(var/turf/nearby in range(SHUTTLE_MANEUVER_EMP_RADIUS, impact))
			shock_tiles[nearby] = TRUE
		for(var/mob/living/person in range(SHUTTLE_MANEUVER_SHOCK_RADIUS, impact))
			if(!people[person] || get_dist(person, impact) < get_dist(person, people[person]))
				people[person] = impact
	var/list/areas = list()
	for(var/turf/tile as anything in damage)
		var/amount = damage[tile]
		if(amount == -1)
			var/roll = rand(1, 100)
			amount = roll <= severe_chance ? 100 : roll <= severe_chance + partial_chance ? 50 : 0
		if(!amount || !ship.has_docking_layer(tile))
			continue
		var/area/shuttle/stationtrauma_space/precision/compartment = get_area(tile)
		var/obj/effect/abstract/shuttle_impact_guard/guard = locate() in tile
		for(var/obj/machinery/machine in tile)
			if(!incoming_machines[machine] || guard?.protect_machines)
				continue
			if(amount == 100)
				machine.atom_break(MELEE)
			else
				machine.take_damage(machine.max_integrity * 0.5, BRUTE, MELEE)
		if(guard?.protect_turf)
			continue
		if(istype(compartment))
			areas[compartment] = TRUE
		if(amount == 50)
			if(isfloorturf(tile))
				var/turf/open/floor/floor = tile
				floor.break_tile()
			else if(iswallturf(tile))
				tile.AddComponent(/datum/component/torn_wall, 0)
			continue
		for(var/obj/structure/cable/wire in tile)
			wire.deconstruct(FALSE)
		// Remove the ship's deck, not the saved planetary/station substrate below its ownership marker.
		var/index = ship.docking_layer_indices[tile]
		var/list/bases = tile.baseturfs.Copy(1, index + 1)
		tile.ChangeTurf(/turf/open/space, bases, CHANGETURF_INHERIT_AIR)
	for(var/area/shuttle/stationtrauma_space/precision/compartment as anything in areas)
		compartment.collision_visuals()
	var/list/area_severity = list()
	var/list/affected_machines = list()
	for(var/turf/tile as anything in shock_tiles)
		var/area/compartment = get_area(tile)
		if(!area_severity[compartment])
			area_severity[compartment] = prob(severe_chance) ? EMP_HEAVY : EMP_LIGHT
		for(var/obj/machinery/machine in tile)
			affected_machines[machine] = area_severity[compartment]
	for(var/obj/machinery/machine as anything in affected_machines)
		machine.emp_act(affected_machines[machine])
	var/list/bounds = ship.return_coords()
	var/turf/centre = locate(round((bounds[1] + bounds[3]) / 2), round((bounds[2] + bounds[4]) / 2), ship.z)
	for(var/mob/living/person as anything in people)
		if(person.buckled || person.incorporeal_move)
			continue
		var/turf/impact = people[person]
		var/direction = get_dir(centre, person) || get_dir(centre, impact) || REVERSE_DIR(target.dir)
		var/turf/away = get_ranged_target_turf(person, direction, SHUTTLE_MANEUVER_THROW_DISTANCE)
		person.safe_throw_at(away, SHUTTLE_MANEUVER_THROW_DISTANCE, 1)
