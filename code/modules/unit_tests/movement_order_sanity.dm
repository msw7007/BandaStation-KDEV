/datum/unit_test/movement_order_sanity/Run()
	var/obj/movement_tester/test_obj = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/list/movement_cache = test_obj.movement_order

	var/obj/movement_interceptor/interceptor = allocate(__IMPLIED_TYPE__)
	interceptor.forceMove(locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))

	var/did_move = step(test_obj, EAST)

	TEST_ASSERT(did_move, "Object did not move at all.")
	TEST_ASSERT(QDELETED(test_obj), "Object was not qdeleted.")
	TEST_ASSERT(length(movement_cache) == 4, "Movement order length was not the expected value of 4, got: [length(movement_cache)].\nMovement Log\n[jointext(movement_cache, "\n")]")

	// Due to when the logging takes place, it will always be Move Move > Moved Moved instead of the reality of
	// Move > Moved > Move > Moved
	TEST_ASSERT(findtext(movement_cache[1], "Moving from"),"Movement step 1 was not a Move attempt.\nMovement Log\n[jointext(movement_cache, "\n")]")
	TEST_ASSERT(findtext(movement_cache[2], "Moving from"),"Movement step 2 was not a Move attempt.\nMovement Log\n[jointext(movement_cache, "\n")]")
	TEST_ASSERT(findtext(movement_cache[3], "Moved from"),"Movement step 3 was not a Moved() call.\nMovement Log\n[jointext(movement_cache, "\n")]")
	TEST_ASSERT(findtext(movement_cache[4], "Moved from"),"Movement step 4 was not a Moved() call.\nMovement Log\n[jointext(movement_cache, "\n")]")

/obj/movement_tester
	name = "movement debugger"
	var/list/movement_order = list()

/obj/movement_tester/Move(atom/newloc, direct, glide_size_override, z_movement_flags)
	movement_order += "Moving from ([loc.x], [loc.y]) to [newloc ? "([newloc.x], [newloc.y])" : "NULL"]"
	return ..()

/obj/movement_tester/doMove(atom/destination)
	movement_order += "Abstractly Moving from ([loc.x], [loc.y]) to [destination ? "([destination.x], [destination.y])" : "NULL"]"
	return ..()

/obj/movement_tester/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	movement_order += "Moved from ([old_loc.x], [old_loc.y]) to [loc ? "([loc.x], [loc.y])" : "NULL"]"
	return ..()

/obj/movement_interceptor
	name = "movement interceptor"

/obj/movement_interceptor/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/connect_loc, list(COMSIG_ATOM_ENTERED = PROC_REF(on_crossed)))

/obj/movement_interceptor/proc/on_crossed(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(src == arrived)
		return

	qdel(arrived)

/datum/unit_test/cyberpunk_service_z_links/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/other_level
	for(var/check_z in 1 to world.maxz)
		if(check_z != start.z && !(check_z in SSmapping.get_connected_levels(start.z)))
			other_level = locate(start.x, start.y, check_z)
			break
	if(!other_level)
		TEST_NOTICE(src, "No independent Z level exists; cross-stack graph assertions require a multi-stack test map.")
		return
	TEST_ASSERT(!cyberpunk_service_z_connected(start.z, other_level.z, list()), "Disconnected stacks must not be serviceable without a physical link.")
	var/list/edge = list("entry" = start, "exit" = other_level)
	var/list/edges = list(edge)
	TEST_ASSERT(cyberpunk_service_z_connected(start.z, other_level.z, edges), "A physical link must permit cross-Z service dispatch.")
	var/list/rejected = list()
	rejected[cyberpunk_service_z_edge_key(edge)] = TRUE
	TEST_ASSERT(!cyberpunk_service_z_connected(start.z, other_level.z, edges, rejected), "Failed links must be excluded from route planning.")
	edges += list(list("entry" = run_loc_floor_top_right, "exit" = other_level))
	TEST_ASSERT(cyberpunk_service_z_connected(start.z, other_level.z, edges, rejected), "Rejecting one link must not reject another entry on the same floor.")

/datum/unit_test/cyberpunk_service_z_progress/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/list/levels = list()
	for(var/check_z in 1 to world.maxz)
		if(check_z != start.z)
			levels += check_z
	if(length(levels) < 2)
		TEST_NOTICE(src, "Three Z levels are needed to test forward progress.")
		return
	var/turf/middle = locate(start.x, start.y, levels[1])
	var/turf/destination = locate(start.x, start.y, levels[2])
	var/turf/far_entry = locate(min(start.x + 4, world.maxx), start.y, middle.z)
	var/list/backward = list("entry" = middle, "exit" = start)
	var/list/forward = list("entry" = far_entry, "exit" = destination)
	var/list/edges = list(list("entry" = start, "exit" = middle), backward, forward)
	TEST_ASSERT(!cyberpunk_service_z_connected(start.z, middle.z, list()), "Stack membership alone must not authorize travel.")
	TEST_ASSERT_EQUAL(cyberpunk_service_z_next_edge(middle, destination, edges), forward, "A nearby reverse ladder must not win over a route toward the destination.")

/datum/unit_test/cyberpunk_avi_cargo_location/Run()
	var/obj/vehicle/ridden/cyberpunk/avi/courier = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/obj/item/loaded = allocate(__IMPLIED_TYPE__, courier)
	var/obj/item/not_loaded = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	courier.avi_dropoff_turf = run_loc_floor_top_right
	courier.avi_cargo = list(loaded, not_loaded)
	TEST_ASSERT(!courier.cyberpunk_avi_unload_cargo(), "Cargo cannot unload before the courier arrives.")
	TEST_ASSERT_EQUAL(loaded.loc, courier, "Cargo must remain aboard before arrival.")
	courier.forceMove(run_loc_floor_top_right)
	courier.cyberpunk_avi_unload_cargo()
	TEST_ASSERT_EQUAL(loaded.loc, run_loc_floor_top_right, "Loaded cargo must arrive at the destination.")
	TEST_ASSERT_EQUAL(not_loaded.loc, run_loc_floor_bottom_left, "Unloaded cargo must not teleport to the destination.")

/datum/unit_test/cyberpunk_avi_path_generation/Run()
	var/obj/vehicle/ridden/cyberpunk/avi/courier = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	courier.avi_route_generation = 2
	courier.avi_route_pending = TRUE
	courier.cyberpunk_avi_path_ready(1, list(run_loc_floor_top_right))
	TEST_ASSERT(courier.avi_route_pending, "An old callback must not complete the new route request.")
	TEST_ASSERT_NULL(courier.avi_route_path, "An old route must not replace the current path.")
	var/list/current_path = list(run_loc_floor_top_right)
	courier.cyberpunk_avi_path_ready(2, current_path)
	TEST_ASSERT_EQUAL(courier.avi_route_path, current_path, "The current callback must install the new route.")
	courier.cyberpunk_avi_path_ready(2, null)
	TEST_ASSERT_EQUAL(courier.avi_route_path, current_path, "A duplicate callback must not clear a finished request.")

/datum/unit_test/cyberpunk_city_cargo_custody/Run()
	var/mob/living/carbon/human/consistent/carrier = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller, carrier)
	controller.set_blackboard_key(BB_CP_AI_CAPABILITIES, CP_AI_CAP_CARGO_SLOT)
	var/obj/item/cargo = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	controller.set_blackboard_key(BB_CP_CARGO, cargo)
	controller.set_blackboard_key(BB_CP_CARGO_RECEIVER, run_loc_floor_top_right)
	TEST_ASSERT(controller.cyberpunk_pickup_city_cargo(), "A cargo-slot carrier must load its item.")
	TEST_ASSERT_EQUAL(cargo.loc, carrier, "A cargo slot must contain the actual item.")
	TEST_ASSERT(controller.cyberpunk_has_city_cargo(), "Loaded cargo must be recognized.")
	cargo.forceMove(run_loc_floor_top_right)
	controller.set_blackboard_key(BB_CP_CARGO_STATUS, CP_AI_CARGO_CARRIED)
	TEST_ASSERT(!controller.cyberpunk_has_city_cargo(), "The carried flag must not substitute for possession.")
	TEST_ASSERT(!controller.cyberpunk_deliver_city_cargo(), "Missing cargo must not be teleported to a recipient.")
	TEST_ASSERT_EQUAL(cargo.loc, run_loc_floor_top_right, "A failed delivery must leave lost cargo untouched.")

/datum/unit_test/cyberpunk_city_work_completion/Run()
	var/mob/living/carbon/human/consistent/worker = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller, worker)
	controller.cyberpunk_assign_city_task(CP_AI_TASK_WORK, null, null, null, null, 10 SECONDS)
	controller.cyberpunk_work_city_task(1)
	controller.set_blackboard_key(BB_CP_CITY_TASK_FINISH_AT, world.time)
	var/datum/cyberpunk_goap_planner/planner = allocate(__IMPLIED_TYPE__)
	var/list/state = planner.build_world_state(controller)
	TEST_ASSERT(!state["timed_out"], "Finished work must be completed, not failed as an overdue delivery.")
	controller.cyberpunk_work_city_task(1)
	TEST_ASSERT_NULL(controller.blackboard[BB_CP_CITY_TASK], "Finished work must clear the task.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_CP_CITY_TASK_RESULT], "work finished", "Work must report successful completion.")

/datum/unit_test/cyberpunk_phantom_repair/Run()
	var/mob/living/carbon/human/consistent/worker = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller, worker)
	var/obj/structure/table/target = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	target.take_damage(80, BRUTE, MELEE)
	var/before = target.get_integrity()
	controller.cyberpunk_assign_city_task(CP_AI_TASK_REPAIR, null, target, null, null, 1 MINUTES)
	controller.phantom_body = allocate(/obj/effect/cyberpunk_phantom_body, run_loc_floor_bottom_left)
	controller.set_blackboard_key(BB_CP_PHANTOM_APPROX_TURF, run_loc_floor_bottom_left)
	controller.set_blackboard_key(BB_CP_PHANTOM_STATE, CP_AI_PHANTOM_WAITING)
	worker.forceMove(controller.phantom_body)
	controller.cyberpunk_work_city_task(1)
	controller.cyberpunk_work_city_task(2)
	TEST_ASSERT(target.get_integrity() > before, "Phantom repair must repair the actual object without requiring cargo.")
	controller.cyberpunk_work_city_task(30)
	TEST_ASSERT_EQUAL(target.get_integrity(), target.max_integrity, "Repair may complete only after restoring integrity.")
	TEST_ASSERT_NULL(controller.blackboard[BB_CP_CITY_TASK], "Completed phantom repair must clear the task.")

/datum/unit_test/cyberpunk_starlight_queue_custody/Run()
	var/mob/living/carbon/human/consistent/customer = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/consistent/thief = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/cyberpunk_corporation/corporation = allocate(__IMPLIED_TYPE__, CYBERPUNK_CORP_STARLIGHT)
	corporation.update_agent_pool()
	corporation.agents_available = 0
	var/obj/machinery/vending/source = allocate(/obj/machinery/vending/medical, run_loc_floor_bottom_left)
	var/obj/item/cargo = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/datum/cyberpunk_starlight_shipment/shipment = corporation.register_starlight_tracking(customer, cargo)
	TEST_ASSERT(shipment, "A purchase must create a buyer-owned shipment.")
	var/obj/item/cyberpunk_delivery_beacon/beacon = allocate(__IMPLIED_TYPE__, run_loc_floor_top_right)
	beacon.owner_key = shipment.owner_key
	beacon.active = TRUE
	shipment.source_ref = WEAKREF(source)
	shipment.beacon_ref = WEAKREF(beacon)
	shipment.status = "queued"
	shipment.process(1)
	TEST_ASSERT_EQUAL(shipment.status, "queued", "A busy agent pool must retain the queue.")
	TEST_ASSERT_EQUAL(cargo.loc, run_loc_floor_bottom_left, "Queued cargo must remain at the pickup point.")
	cargo.forceMove(thief)
	shipment.next_dispatch_at = 0
	shipment.process(1)
	TEST_ASSERT_EQUAL(shipment.status, "failed", "Stolen queued cargo must invalidate dispatch.")
	TEST_ASSERT_EQUAL(cargo.loc, thief, "A queue must never reclaim stolen cargo by teleportation.")
