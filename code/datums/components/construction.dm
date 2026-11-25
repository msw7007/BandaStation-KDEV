/datum/component/construction
	var/list/steps
	var/result
	var/index = 1
	var/desc

/datum/component/construction/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(examine))
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(action))
	update_parent(index)

/datum/component/construction/proc/examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(desc)
		examine_list += desc

/datum/component/construction/proc/on_step()
	if(index > steps.len)
		spawn_result()
	else
		update_parent(index)

/datum/component/construction/proc/action(datum/source, obj/item/I, mob/living/user)
	SIGNAL_HANDLER
	if(QDELETED(I) || QDELETED(user) || !is_right_key(I))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(check_step), I, user)
	return COMPONENT_NO_AFTERATTACK

/datum/component/construction/proc/update_index(diff)
	index += diff
	on_step()

/datum/component/construction/proc/check_step(obj/item/I, mob/living/user)
	var/diff = is_right_key(I)
	if(diff && wait_for_construction_step(I, user, diff) && custom_action(I, user, diff))
		update_index(diff)
		return TRUE
	return FALSE

/datum/component/construction/proc/wait_for_construction_step(obj/item/work_item, mob/living/user, step_key)
	var/atom/work_target = parent
	var/initial_index = index
	var/duration = 4 SECONDS * user.get_cyberpunk_structure_time_multiplier(work_target, "build")
	if(!do_after(user, duration, target = work_target))
		return FALSE
	if(QDELETED(src) || QDELETED(work_target) || QDELETED(work_item) || QDELETED(user) || index != initial_index)
		return FALSE
	return user.is_holding(work_item) && user.can_perform_action(work_target) && step_key == is_right_key(work_item)

/datum/component/construction/proc/is_right_key(obj/item/I) // returns index step
	var/list/L = steps[index]
	if(check_used_item(I, L["key"]))
		return FORWARD //to the first step -> forward
	else if(check_used_item(I, L["back_key"]))
		return BACKWARD //to the last step -> backwards
	return FALSE

/datum/component/construction/proc/check_used_item(obj/item/I, key)
	if(!key)
		return FALSE

	if(ispath(key) && istype(I, key))
		return TRUE

	else if(I.tool_behaviour == key)
		return TRUE

	return FALSE

/datum/component/construction/proc/custom_action(obj/item/I, mob/living/user, diff)
	var/target_index = index + diff
	var/list/current_step = steps[index]
	var/list/target_step

	if(target_index > 0 && target_index <= steps.len)
		target_step = steps[target_index]

	. = TRUE

	if(I.tool_behaviour)
		. = I.use_tool(parent, user, 0, volume=50)

	else if(diff == FORWARD)
		switch(current_step["action"])
			if(ITEM_DELETE)
				. = user.transferItemToLoc(I, parent)
				if(.)
					qdel(I)

			if(ITEM_MOVE_INSIDE)
				. = user.transferItemToLoc(I, parent)

			// Using stacks
			else
				if(isstack(I))
					. = I.use_tool(parent, user, 0, volume=50, amount=current_step["amount"])


	// Going backwards? Undo the last action. Drop/respawn the items used in last action, if any.
	if(. && diff == BACKWARD && target_step && !target_step["no_refund"])
		var/target_step_key = target_step["key"]

		switch(target_step["action"])
			if(ITEM_DELETE)
				new target_step_key(drop_location())

			if(ITEM_MOVE_INSIDE)
				var/obj/item/located_item = locate(target_step_key) in parent
				if(located_item)
					located_item.forceMove(drop_location())

			else
				if(ispath(target_step_key, /obj/item/stack))
					new target_step_key(drop_location(), target_step["amount"])

/datum/component/construction/proc/spawn_result()
	// Some constructions result in new components being added.
	if(ispath(result, /datum/component))
		parent.AddComponent(result)
		qdel(src)

	else if(ispath(result, /atom))
		new result(drop_location())
		qdel(parent)

/datum/component/construction/proc/update_parent(step_index)
	var/list/step = steps[step_index]
	var/atom/parent_atom = parent

	if(step["desc"])
		desc = step["desc"]

	if(step["icon_state"])
		parent_atom.icon_state = step["icon_state"]

/datum/component/construction/proc/drop_location()
	var/atom/parent_atom = parent
	return parent_atom.drop_location()



// Unordered construction.
// Takes a list of part types, to be added in any order, as steps.
// Calls spawn_result() when every type has been added.
/datum/component/construction/unordered/check_step(obj/item/I, mob/living/user)
	var/typepath = is_right_key(I)
	if(typepath && wait_for_construction_step(I, user, typepath) && custom_action(I, user, typepath))
		steps -= typepath
		on_step()
		return TRUE
	return FALSE

/datum/component/construction/unordered/is_right_key(obj/item/I)
	for(var/typepath in steps)
		if(istype(I, typepath))
			return typepath
	return FALSE

/datum/component/construction/unordered/on_step()
	if(!steps.len)
		spawn_result()
	else
		update_parent(steps.len)

/datum/component/construction/unordered/update_parent(steps_left)
	return

/datum/component/construction/unordered/custom_action(obj/item/I, mob/living/user, typepath)
	return TRUE
