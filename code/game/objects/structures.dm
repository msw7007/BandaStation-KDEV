/// Inert structures, such as girders, machine frames, and crates/lockers.
/obj/structure
	icon = 'icons/obj/structures.dmi'
	abstract_type = /obj/structure
	pressure_resistance = 8
	max_integrity = 300
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	layer = BELOW_OBJ_LAYER
	flags_ricochet = RICOCHET_HARD
	receive_ricochet_chance_mod = 0.6
	pass_flags_self = PASSSTRUCTURE
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	armor_type = /datum/armor/obj_structure
	burning_particles = /particles/smoke/burning
	var/broken = FALSE

/datum/armor/obj_structure
	fire = 50
	acid = 50

/obj/structure/Initialize(mapload)
	. = ..()
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)

/obj/structure/Destroy(force)
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH_NEIGHBORS(src)
	return ..()

/obj/structure/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	add_fingerprint(usr)
	return ..()

/obj/structure/examine(mob/user)
	. = ..()
	if(!(resistance_flags & INDESTRUCTIBLE))
		if(resistance_flags & ON_FIRE)
			. += span_warning("В огне!")
		if(broken)
			. += span_notice("Кажется, сломано.")
		var/examine_status = examine_status(user)
		if(examine_status)
			. += examine_status

/obj/structure/proc/examine_status(mob/user) //An overridable proc, mostly for falsewalls.
	var/healthpercent = (atom_integrity/max_integrity) * 100
	switch(healthpercent)
		if(50 to 99)
			return  "Имеет незначительные повреждения."
		if(25 to 50)
			return  "Имеет значительные повреждения."
		if(0 to 25)
			if(!broken)
				return  span_warning("Разваливается на части!")

/obj/structure/examine_descriptor(mob/user)
	return "структура"

/obj/structure/rust_heretic_act()
	take_damage(500, BRUTE, "melee", 1)

/obj/structure/zap_act(power, zap_flags)
	if(zap_flags & ZAP_OBJ_DAMAGE)
		take_damage(power * 2.5e-4, BURN, "energy")
	power -= power * 5e-4 //walls take a lot out of ya
	. = ..()

/obj/structure/animate_atom_living(mob/living/owner)
	return new /mob/living/basic/mimic/copy(drop_location(), src, owner)

/// For when a mob comes flying through the window, smash it and damage the mob
/obj/structure/proc/smash_and_injure(mob/living/flying_mob, atom/oldloc, direction)
	flying_mob.balloon_alert_to_viewers("пробивает собой!")
	flying_mob.apply_damage(damage = rand(5, 15), damagetype = BRUTE, wound_bonus = 15, exposed_wound_bonus = 25, sharpness = SHARP_EDGED, attack_direction = get_dir(src, oldloc))
	new /obj/effect/decal/cleanable/glass(get_step(flying_mob, flying_mob.dir))
	deconstruct(disassembled = FALSE)

/obj/structure/used_in_craft(atom/result, datum/crafting_recipe/current_recipe)
	. = ..()
	// If we consumed in crafting, we should dump contents out before qdeling them.
	if(!is_type_in_list(src, current_recipe.parts))
		dump_contents()

// CyberPunk structure core.
/obj/structure
	/// Mobile/foldable/fixed as required by the item TЗ.
	var/cy_structure_mobility = CY_STRUCTURE_MOBILITY_FIXED
	/// Item returned by a foldable structure.
	var/cy_folded_item_type
	/// Generic construction stage for frame-based construction.
	var/cy_construction_stage = CY_CONSTRUCTION_STAGE_COMPLETE
	/// Accepted component/item types for staged construction.
	var/list/cy_required_components
	var/list/cy_loaded_components
	var/cy_requires_board = FALSE
	var/obj/item/circuitboard/cy_loaded_board
	var/list/cy_required_resources
	var/list/cy_loaded_resources

/obj/structure/proc/cy_can_move_structure()
	return cy_structure_mobility == CY_STRUCTURE_MOBILITY_MOBILE && !anchored

/obj/structure/proc/cy_can_fold_structure()
	return cy_structure_mobility == CY_STRUCTURE_MOBILITY_FOLDABLE && ispath(cy_folded_item_type, /obj/item)

/obj/structure/proc/cy_fold_structure(mob/user)
	if(!cy_can_fold_structure())
		return FALSE
	var/obj/item/folded = new cy_folded_item_type(get_turf(src))
	folded.manufacturer_organization = manufacturer_organization
	folded.manufacturer_tech_tags = manufacturer_tech_tags
	if(user)
		user.put_in_hands(folded)
	qdel(src)
	return TRUE

/obj/structure/proc/cy_handle_structure_tool(obj/item/tool, mob/user)
	if(!tool)
		return FALSE
	switch(tool.tool_behaviour)
		if(TOOL_WRENCH)
			if(cy_structure_mobility == CY_STRUCTURE_MOBILITY_MOBILE || cy_structure_mobility == CY_STRUCTURE_MOBILITY_FOLDABLE)
				anchored = !anchored
				if(user)
					user.balloon_alert(user, anchored ? "зафиксировано" : "снято")
				return TRUE
			if(cy_construction_stage == CY_CONSTRUCTION_STAGE_NONE)
				cy_construction_stage = CY_CONSTRUCTION_STAGE_FRAME_WRENCHED
				if(user)
					user.balloon_alert(user, "каркас собран")
				return TRUE
		if(TOOL_WELDER)
			if(get_integrity() < max_integrity)
				repair_damage(max_integrity * 0.25)
				if(user)
					user.balloon_alert(user, "корпус заварен")
				return TRUE
			if(cy_construction_stage == CY_CONSTRUCTION_STAGE_FRAME_WRENCHED)
				cy_construction_stage = CY_CONSTRUCTION_STAGE_FRAME_WELDED
				if(user)
					user.balloon_alert(user, "каркас сварен")
				return TRUE
		if(TOOL_SCREWDRIVER)
			if(cy_can_fold_structure() && !anchored)
				return cy_fold_structure(user)
			if(cy_construction_stage == CY_CONSTRUCTION_STAGE_COMPONENTS_LOADED)
				cy_construction_stage = CY_CONSTRUCTION_STAGE_COMPLETE
				if(user)
					user.balloon_alert(user, "установлено")
				return TRUE
		if(TOOL_MULTITOOL)
			if(broken)
				broken = FALSE
				if(user)
					user.balloon_alert(user, "перезапущено")
				return TRUE
	return FALSE

/obj/structure/attackby(obj/item/tool, mob/user, list/modifiers, list/attack_modifiers)
	if(cy_handle_structure_tool(tool, user))
		var/mob/living/living_user = user
		if(istype(living_user))
			var/skill_type = tool?.tool_behaviour == TOOL_MULTITOOL ? /datum/cy_skill/professional/electricity : /datum/cy_skill/professional/construction
			living_user.award_cy_professional_activity(skill_type)
		return TRUE
	return ..()
