/obj/item
	/// Resource quality tier (RESOURCE_QUALITY_NONE = untracked). Drives examine + tool/armor scaling.
	var/resource_quality = RESOURCE_QUALITY_NONE

/// Single entry point: stores the tier, shows it on examine, and (re)applies its stat effects.
/// Idempotent — effects are always recomputed from base values, so repeated calls don't compound.
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
	var/multiplier = get_resource_quality_multiplier(resource_quality)
	if(tool_behaviour)
		toolspeed = initial(toolspeed) / multiplier
	if(armor_type && get_armor().has_any_armor())
		set_armor(get_armor_by_type(armor_type).generate_new_with_multipliers(list(ARMOR_ALL = multiplier)))

/// Crafted items inherit the average quality of their quality-bearing components.
/obj/item/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	var/total = 0
	var/count = 0
	for(var/obj/item/part in components)
		if(part.resource_quality == RESOURCE_QUALITY_NONE)
			continue
		total += part.resource_quality
		count++
	if(count)
		set_resource_quality(clamp(round(total / count + 0.5), RESOURCE_QUALITY_DISGUSTING, RESOURCE_QUALITY_EXCELLENT))
