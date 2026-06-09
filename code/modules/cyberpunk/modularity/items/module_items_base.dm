// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/obj/item/cyberpunk_item_module
	name = "item module"
	desc = "A modular Cyberpunk 13 item component. Use it on a weapon or protective item to install it."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "component"
	w_class = WEIGHT_CLASS_SMALL
	cyberpunk_manufacturer = "Starlight"
	var/module_datum_type = /datum/cyberpunk_item_module
	var/module_tier = 1
	var/module_variant = "standard"

/obj/item/cyberpunk_item_module/proc/get_module_variant_name()
	switch(module_variant)
		if("lightweight")
			return "Lightweight"
		if("reinforced")
			return "Reinforced"
		if("precision")
			return "Precision"
	return "Standard"

/obj/item/cyberpunk_item_module/proc/cycle_module_variant(mob/user)
	switch(module_variant)
		if("standard")
			module_variant = "lightweight"
		if("lightweight")
			module_variant = "reinforced"
		if("reinforced")
			module_variant = "precision"
		else
			module_variant = "standard"
	to_chat(user, span_notice("[src] variant set to [get_module_variant_name()]."))

/obj/item/cyberpunk_item_module/attack_self(mob/user, modifiers)
	cycle_module_variant(user)
	return TRUE

/obj/item/cyberpunk_item_module/proc/create_module_datum()
	var/datum/cyberpunk_item_module/module = new module_datum_type
	module.manufacturer = get_cyberpunk_manufacturer()
	module.module_tier = module_tier
	module.module_variant = module_variant
	module.apply_cyberpunk_module_variant()
	return module

/obj/item/cyberpunk_item_module/examine(mob/user)
	. = ..()
	var/datum/cyberpunk_item_module/module = new module_datum_type
	module.module_tier = module_tier
	module.module_variant = module_variant
	module.apply_cyberpunk_module_variant()
	. += span_notice("Manufacturer: [get_cyberpunk_manufacturer()].")
	. += span_notice("Tier: [module_tier]. Variant: [get_module_variant_name()]. Slot: [module.module_slot]. Effect scale: [round(module.get_effective_scale() * 100)]%.")
	. += span_notice("Use in hand before installation to cycle Standard, Lightweight, Reinforced and Precision variants.")
	if(module.has_active_ability())
		. += span_notice("Active ability: [module.active_ability_name]. [module.active_ability_description]")
	qdel(module)

/obj/item/cyberpunk_item_module/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/item/target_item = interacting_with
	if(!istype(target_item) || target_item == src)
		return NONE
	var/datum/cyberpunk_item_module/module = create_module_datum()
	var/install_delay = 2 SECONDS * (user ? user.get_cyberpunk_item_module_time_multiplier(target_item) : 1)
	if(!do_after(user, install_delay, target = target_item))
		qdel(module)
		return ITEM_INTERACT_BLOCKING
	if(!target_item.install_cyberpunk_module(module, user))
		if(target_item.is_cyberpunk_modular_weapon() && target_item.cyberpunk_weapon_assembled && !(module.module_slot in list("sight", "underbarrel")))
			to_chat(user, span_warning("Unlock [target_item]'s frame with a wrench on a table before changing its internal weapon modules."))
		else
			to_chat(user, span_warning("[name] does not fit into [target_item]."))
		qdel(module)
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You install [name] into [target_item]."))
	qdel(src)
	return ITEM_INTERACT_SUCCESS
