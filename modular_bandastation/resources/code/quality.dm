/obj/item
	/// Resource quality tier (RESOURCE_QUALITY_NONE = untracked). Drives examine + tool/armor scaling.
	var/resource_quality = RESOURCE_QUALITY_NONE

/proc/get_weighted_resource_quality(first_quality, first_amount, second_quality, second_amount)
	if(first_quality == RESOURCE_QUALITY_NONE && second_quality == RESOURCE_QUALITY_NONE)
		return RESOURCE_QUALITY_NONE
	first_quality ||= RESOURCE_QUALITY_AVERAGE
	second_quality ||= RESOURCE_QUALITY_AVERAGE
	var/total_amount = max(1, first_amount + second_amount)
	var/weighted_quality = ((first_quality * first_amount) + (second_quality * second_amount)) / total_amount
	return clamp(round(weighted_quality), RESOURCE_QUALITY_DISGUSTING, RESOURCE_QUALITY_EXCELLENT)

/// Single entry point: stores the tier, shows it on examine, and (re)applies its stat effects.
/// Idempotent: effects are always recomputed from base values, so repeated calls don't compound.
/obj/item/proc/set_resource_quality(quality)
	if(quality == RESOURCE_QUALITY_NONE)
		return
	if(resource_quality == RESOURCE_QUALITY_NONE)
		RegisterSignal(src, COMSIG_ATOM_EXAMINE, PROC_REF(on_resource_quality_examine))
	resource_quality = quality
	apply_resource_quality_effects()

/obj/item/proc/on_resource_quality_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Качество материала: [get_resource_quality_label(resource_quality)].")

/// Better quality = faster tools and tougher armor; worse = the reverse. Recomputed from base each call.
/obj/item/proc/apply_resource_quality_effects()
	if(cyberpunk_weapon_form)
		recalculate_cyberpunk_weapon_stats()
		return
	if(cyberpunk_equipment_form)
		recalculate_cyberpunk_equipment_stats()
		return
	var/multiplier = get_resource_quality_multiplier(resource_quality)
	if(tool_behaviour)
		toolspeed = initial(toolspeed) / multiplier
	if(armor_type && get_armor().has_any_armor())
		set_armor(get_armor_by_type(armor_type).generate_new_with_multipliers(list(ARMOR_ALL = multiplier)))

/obj/item/proc/get_resource_quality_component_weight()
	return 1

/obj/item/stack/get_resource_quality_component_weight()
	return max(1, get_amount())

/// Crafted items inherit the weighted average quality of their quality-bearing components.
/obj/item/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	var/total = 0
	var/total_weight = 0
	for(var/obj/item/part in components)
		if(part.resource_quality == RESOURCE_QUALITY_NONE)
			continue
		var/weight = part.get_resource_quality_component_weight()
		total += part.resource_quality * weight
		total_weight += weight
	if(total_weight)
		set_resource_quality(clamp(round(total / total_weight), RESOURCE_QUALITY_DISGUSTING, RESOURCE_QUALITY_EXCELLENT))

/obj/item/stack/on_stack_merged(obj/item/stack/source_stack, transfer_amount, previous_amount)
	. = ..()
	if(!source_stack || transfer_amount <= 0)
		return
	var/merged_quality = get_weighted_resource_quality(resource_quality, previous_amount, source_stack.resource_quality, transfer_amount)
	if(merged_quality != RESOURCE_QUALITY_NONE)
		set_resource_quality(merged_quality)

/obj/item/stack/on_stack_split(obj/item/stack/new_stack, split_amount)
	. = ..()
	if(!new_stack || resource_quality == RESOURCE_QUALITY_NONE)
		return
	new_stack.set_resource_quality(resource_quality)
