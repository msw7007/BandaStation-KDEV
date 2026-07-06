/obj/structure/chair/stool/bar/dark
	icon = 'modular_bandastation/objects/icons/obj/structures/chairs.dmi'
	icon_state = "bar_dark"
	item_chair = /obj/item/chair/stool/bar/dark

/obj/item/chair/stool/bar/dark
	icon = 'modular_bandastation/objects/icons/obj/structures/chairs.dmi'
	icon_state = "bar_toppled_dark"
	inhand_icon_state = "stool_bar_dark"
	origin_type = /obj/structure/chair/stool/bar/dark
	lefthand_file = 'modular_bandastation/objects/icons/mob/inhands/chairs_lefthand.dmi'
	righthand_file = 'modular_bandastation/objects/icons/mob/inhands/chairs_righthand.dmi'

MAPPING_DIRECTIONAL_HELPERS(/obj/item/chair/stool/bar/dark, 0)

// Comfy (also recoloring)
/obj/structure/chair/comfy/shuttle/tactical
	icon = 'modular_bandastation/objects/icons/obj/structures/chairs.dmi'
	icon_state = "shuttle_chair_dark"

/obj/structure/chair/comfy/corp
	icon = 'modular_bandastation/objects/icons/obj/structures/chairs.dmi'
	icon_state = "comfychair_corp"
	color = null

/obj/structure/chair/comfy/beige
	color = rgb(240, 240, 200)

/obj/structure/chair/comfy/black
	color = rgb(60, 60, 55)

/obj/structure/chair/comfy/red
	color = rgb(165, 65, 65)

/obj/structure/chair/comfy/brown
	color = rgb(141, 70, 0)

/obj/structure/chair/comfy/green
	color = rgb(80, 170, 85)

/obj/structure/chair/comfy/lime
	color = rgb(185, 210, 115)

/obj/structure/chair/comfy/yellow
	color = rgb(225, 215, 125)

/obj/structure/chair/comfy/blue
	color = rgb(80, 125, 220)

/obj/structure/chair/comfy/teal
	color = rgb(115, 215, 215)

/obj/structure/chair/comfy/purp
	color = rgb(100, 65, 120)

/proc/cyberpunk_pack_foldable_structure(atom/movable/source, mob/living/user, obj/item/tool, folded_type, pack_time = 3 SECONDS)
	if(!source || !user || !tool || !ispath(folded_type, /obj/item))
		return ITEM_INTERACT_BLOCKING
	if(source.has_buckled_mobs())
		source.balloon_alert(user, "occupied")
		return ITEM_INTERACT_BLOCKING
	if(locate(/mob/living) in source.contents)
		source.balloon_alert(user, "occupied")
		return ITEM_INTERACT_BLOCKING
	source.balloon_alert(user, "folding...")
	pack_time *= user.get_cyberpunk_structure_time_multiplier(source, "fold")
	if(!tool.use_tool(source, user, pack_time, volume = 50))
		return ITEM_INTERACT_BLOCKING
	var/turf/target_turf = get_turf(source)
	if(!target_turf)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/packed = new folded_type(target_turf)
	packed.add_fingerprint(user)
	if(!user.put_in_hands(packed))
		packed.forceMove(target_turf)
	user.reward_cyberpunk_structure_anchor_experience(source)
	qdel(source)
	return ITEM_INTERACT_SUCCESS

/obj/item/folded_cp13_structure_kit
	name = "folded structure kit"
	desc = "A compact deployable structure kit."
	icon = 'icons/obj/storage/toolbox.dmi'
	icon_state = "red"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	var/atom/movable/deployed_type
	var/deploy_time = 3 SECONDS

/obj/item/folded_cp13_structure_kit/is_cyberpunk_structure_target()
	return TRUE

/obj/item/folded_cp13_structure_kit/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/folded_cp13_structure_kit/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand or on an open turf to deploy it. Use a wrench in alternate mode on the deployed structure to fold it back.")

/obj/item/folded_cp13_structure_kit/attack_self(mob/user, modifiers)
	var/turf/deploy_turf = get_step(user, user.dir)
	deploy_structure(user, deploy_turf)

/obj/item/folded_cp13_structure_kit/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isopenturf(interacting_with))
		return NONE
	deploy_structure(user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/folded_cp13_structure_kit/proc/deploy_structure(mob/user, turf/deploy_turf)
	if(!user || !deploy_turf || !ispath(deployed_type, /atom/movable))
		return
	if(deploy_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
		balloon_alert(user, "not enough space")
		return
	balloon_alert(user, "deploying...")
	playsound(src, 'sound/items/tools/ratchet.ogg', 50, TRUE)
	var/effective_deploy_time = deploy_time
	var/mob/living/living_user = user
	if(istype(living_user))
		effective_deploy_time *= living_user.get_cyberpunk_structure_time_multiplier(src, "unfold")
	if(!do_after(user, effective_deploy_time, target = deploy_turf))
		return
	if(QDELETED(src) || deploy_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
		return
	var/atom/movable/deployed = new deployed_type(deploy_turf)
	deployed.setDir(user.dir)
	deployed.add_fingerprint(user)
	if(istype(living_user))
		living_user.reward_cyberpunk_structure_anchor_experience(deployed)
	qdel(src)

/obj/item/folded_cp13_structure_kit/table
	name = "folding table kit"
	desc = "A compact folding table."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	deployed_type = /obj/structure/table/foldable

/obj/structure/table/foldable
	name = "folding table"

/obj/structure/table/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/table/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/table)

/obj/item/folded_cp13_structure_kit/stove
	name = "folding stove kit"
	desc = "A packed compact stove."
	icon = 'icons/obj/machines/kitchen_stove.dmi'
	icon_state = "stove"
	deployed_type = /obj/machinery/stove/foldable

/obj/machinery/stove/foldable
	name = "folding stove"

/obj/machinery/stove/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/stove/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/stove)

/obj/item/folded_cp13_structure_kit/microwave
	name = "folding microwave kit"
	desc = "A packed microwave oven."
	icon = 'icons/obj/machines/microwave.dmi'
	icon_state = "mw_complete"
	deployed_type = /obj/machinery/microwave/foldable

/obj/machinery/microwave/foldable
	name = "folding microwave oven"

/obj/machinery/microwave/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/microwave/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(length(ingredients))
		balloon_alert(user, "empty it first")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/microwave)

/obj/item/folded_cp13_structure_kit/concert_speaker
	name = "packed JBL concert speaker"
	desc = "A packed high-power concert speaker shell."
	icon = 'icons/obj/machines/music.dmi'
	icon_state = "jukebox"
	deployed_type = /obj/structure/concertspeaker/foldable

/obj/structure/concertspeaker/foldable
	name = "JBL concert speaker"

/obj/structure/concertspeaker/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/concertspeaker/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/concert_speaker)

/obj/item/folded_cp13_structure_kit/mech_station
	name = "folding mech station kit"
	desc = "A packed mech recharge station."
	icon = 'icons/obj/machines/mech_bay.dmi'
	icon_state = "recharge_port"
	deployed_type = /obj/machinery/mech_bay_recharge_port/foldable

/obj/machinery/mech_bay_recharge_port/foldable
	name = "folding mech station"

/obj/machinery/mech_bay_recharge_port/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/mech_bay_recharge_port/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/mech_station)

/obj/item/folded_cp13_structure_kit/security_barrier
	name = "folding barrier kit"
	desc = "A packed security barrier."
	icon = 'icons/obj/structures.dmi'
	icon_state = "barrier1"
	deployed_type = /obj/structure/barricade/security/foldable

/obj/structure/barricade/security/foldable
	name = "folding security barrier"

/obj/structure/barricade/security/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/barricade/security/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/security_barrier)

/obj/item/folded_cp13_structure_kit/bioscanner
	name = "folding bioscanner kit"
	desc = "A packed bioscanner sleeper."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_open"
	deployed_type = /obj/machinery/sleeper/bioscanner/foldable

/obj/machinery/sleeper/bioscanner/foldable
	name = "folding bioscanner"

/obj/machinery/sleeper/bioscanner/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/sleeper/bioscanner/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(occupant)
		balloon_alert(user, "occupied")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/bioscanner)

/obj/item/folded_cp13_structure_kit/operating_table
	name = "folding operating table kit"
	desc = "A packed operating table."
	icon = 'icons/obj/medical/surgery_table.dmi'
	icon_state = "surgery_table"
	deployed_type = /obj/structure/table/optable/foldable

/obj/structure/table/optable/foldable
	name = "folding operating table"

/obj/structure/table/optable/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/table/optable/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/operating_table)

/obj/item/folded_cp13_structure_kit/floodlight
	name = "folding floodlight kit"
	desc = "A packed portable floodlight."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "floodlight"
	deployed_type = /obj/machinery/power/floodlight/foldable

/obj/machinery/power/floodlight/foldable
	name = "folding floodlight"

/obj/machinery/power/floodlight/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/power/floodlight/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/floodlight)

/obj/item/folded_cp13_structure_kit/chem_dispenser
	name = "folding chemical dispenser kit"
	desc = "A packed chemical dispenser."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "dispenser"
	deployed_type = /obj/machinery/chem_dispenser/foldable

/obj/machinery/chem_dispenser/foldable
	name = "folding chemical dispenser"

/obj/machinery/chem_dispenser/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/chem_dispenser/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(beaker)
		balloon_alert(user, "remove beaker first")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/chem_dispenser)

/obj/item/folded_cp13_structure_kit/fuel_generator
	name = "folding fuel generator kit"
	desc = "A packed gasoline generator. Feed it fuel, anchor it, and connect it to a cable node."
	icon = 'icons/obj/machines/engine/other.dmi'
	icon_state = "portgen0"
	deployed_type = /obj/machinery/power/cyberpunk_generator/gasoline/foldable

/obj/machinery/power/cyberpunk_generator/gasoline/foldable
	name = "folding fuel generator"
	desc = "A compact fuel-fed generator packed into a folding frame."
	anchored = FALSE

/obj/machinery/power/cyberpunk_generator/gasoline/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/power/cyberpunk_generator/gasoline/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(fuel_units)
		balloon_alert(user, "purge fuel first")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/fuel_generator)

/obj/item/folded_cp13_structure_kit/fridge
	name = "folding refrigerator kit"
	desc = "A packed smartfridge."
	icon = 'icons/obj/machines/smartfridge.dmi'
	icon_state = "smartfridge"
	deployed_type = /obj/machinery/smartfridge/foldable

/obj/machinery/smartfridge/foldable
	name = "folding refrigerator"

/obj/machinery/smartfridge/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/smartfridge/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(length(contents))
		balloon_alert(user, "empty it first")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/fridge)

/obj/item/folded_cp13_structure_kit/stasis_bed
	name = "folding stasis bed kit"
	desc = "A packed lifeform stasis bed."
	icon = 'icons/obj/machines/stasis.dmi'
	icon_state = "stasis"
	deployed_type = /obj/machinery/stasis/foldable

/obj/machinery/stasis/foldable
	name = "folding stasis bed"

/obj/machinery/stasis/foldable/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/stasis/foldable/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(occupant)
		balloon_alert(user, "occupied")
		return ITEM_INTERACT_BLOCKING
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/folded_cp13_structure_kit/stasis_bed)

/obj/structure/chair/plastic/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/chair/plastic/is_cyberpunk_structure_target()
	return TRUE

/obj/item/chair/plastic/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/bed/medical/emergency/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/emergency_bed/is_cyberpunk_structure_target()
	return TRUE

/obj/item/emergency_bed/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/vehicle/ridden/wheelchair/is_cyberpunk_structure_target()
	return TRUE

/obj/vehicle/ridden/wheelchair/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/wheelchair/is_cyberpunk_structure_target()
	return TRUE

/obj/item/wheelchair/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/packed_concertspeaker/is_cyberpunk_structure_target()
	return TRUE

/obj/item/packed_concertspeaker/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/concertspeaker/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/concertspeaker/wrench_act_secondary(mob/living/user, obj/item/tool)
	if(active || length(contents))
		balloon_alert(user, "disconnect it first")
		return ITEM_INTERACT_BLOCKING
	if(anchored)
		set_anchored(FALSE)
		density = FALSE
		force_stop_all_listeners()
	return cyberpunk_pack_foldable_structure(src, user, tool, /obj/item/packed_concertspeaker)

/obj/item/deployable_turret_folded/is_cyberpunk_structure_target()
	return TRUE

/obj/item/deployable_turret_folded/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/deployable_turret/hmg/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/folded_navigation_gigabeacon/is_cyberpunk_structure_target()
	return TRUE

/obj/item/folded_navigation_gigabeacon/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/machinery/spaceship_navigation_beacon/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/item/bodybag/is_cyberpunk_structure_target()
	return TRUE

/obj/item/bodybag/get_cyberpunk_structure_category()
	return "foldable_structure"

/obj/structure/closet/body_bag/get_cyberpunk_structure_category()
	return "foldable_structure"
