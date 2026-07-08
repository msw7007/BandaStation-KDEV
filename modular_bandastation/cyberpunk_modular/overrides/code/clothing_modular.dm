/obj/item/clothing
	/// Cyberpunk build: modular clothing can persist visual/material identity through wardrobe storage.
	var/list/cyberpunk_custom_design_data
	/// Explicit opt-in for modular clothing. Greyscale clothing is treated as modular by proc fallback.
	var/cyberpunk_modular_clothing = FALSE
	/// Original item icon state used as the design base when runtime custom icons replace icon_state.
	var/cyberpunk_base_icon_state
	/// Original worn icon state used as the design base when runtime custom icons replace worn_icon_state.
	var/cyberpunk_base_worn_icon_state

/obj/item/clothing/proc/cyberpunk_is_modular_clothing()
	return cyberpunk_modular_clothing || greyscale_config || greyscale_config_worn || greyscale_colors

/obj/item/clothing/cyberpunk_underwear
	name = "underwear"
	desc = "A lightweight wearable underlayer."
	icon = 'icons/mob/clothing/underwear.dmi'
	w_class = WEIGHT_CLASS_TINY
	body_parts_covered = NONE
	can_be_bloody = FALSE
	cyberpunk_modular_clothing = TRUE
	var/accessory_name = "Nude"
	var/accessory_color

/obj/item/clothing/cyberpunk_underwear/proc/get_accessory()
	return null

/obj/item/clothing/cyberpunk_underwear/proc/set_accessory(accessory_value, color_value)
	accessory_name = accessory_value || "Nude"
	accessory_color = color_value
	var/datum/sprite_accessory/clothing/accessory = get_accessory()
	if(accessory)
		name = accessory.name
		icon_state = accessory.icon_state
		worn_icon_state = accessory.icon_state
		color = accessory.use_static ? null : accessory_color
	else
		name = initial(name)
		icon_state = null
		worn_icon_state = null
		color = null
	update_appearance()

/obj/item/clothing/cyberpunk_underwear/proc/make_underwear_appearance(mob/living/carbon/human/wearer)
	var/datum/sprite_accessory/clothing/accessory = get_accessory()
	if(!accessory)
		return null
	return accessory.make_appearance(accessory_color, wearer.physique, wearer.get_active_bodyshapes())

/obj/item/clothing/cyberpunk_underwear/undershirt
	name = "undershirt"
	slot_flags = ITEM_SLOT_UNDERSHIRT

/obj/item/clothing/cyberpunk_underwear/undershirt/get_accessory()
	return SSaccessories.undershirt_list[accessory_name]

/obj/item/clothing/cyberpunk_underwear/underwear
	name = "underwear"
	slot_flags = ITEM_SLOT_UNDERWEAR

/obj/item/clothing/cyberpunk_underwear/underwear/get_accessory()
	return SSaccessories.underwear_list[accessory_name]

/obj/item/clothing/cyberpunk_underwear/tights
	name = "tights"
	slot_flags = ITEM_SLOT_TIGHTS

/obj/item/clothing/cyberpunk_underwear/tights/get_accessory()
	return SSaccessories.socks_list[accessory_name]

/obj/item/clothing/proc/cyberpunk_capture_wardrobe_design()
	var/list/design = list(
		"id" = "[world.realtime]-[rand(1000, 9999)]",
		"name" = name,
		"kind" = "clothing",
		"type_path" = "[type]",
		"icon_state" = cyberpunk_base_icon_state || icon_state,
		"worn_icon_state" = cyberpunk_base_worn_icon_state || worn_icon_state,
		"greyscale_colors" = greyscale_colors,
		"material_signature" = cyberpunk_material_signature(),
		"directions" = list(
			"north" = "",
			"south" = "",
			"east" = "",
			"west" = "",
		),
		"item_icon" = "",
	)
	if(islist(cyberpunk_custom_design_data))
		for(var/key in cyberpunk_custom_design_data)
			design[key] = cyberpunk_custom_design_data[key]
		design["type_path"] ||= "[type]"
		design["name"] ||= name
		design["kind"] = "clothing"
	return cyberpunk_sanitize_visual_design_record(design)

/obj/item/clothing/proc/cyberpunk_apply_design(list/design)
	design = cyberpunk_sanitize_visual_design_record(design)
	if(!design)
		return FALSE

	var/has_pixel_design = cyberpunk_visual_design_has_pixel_payload(design)
	var/base_icon_state = design["icon_state"] || cyberpunk_base_icon_state || icon_state
	var/base_worn_state = design["worn_icon_state"] || cyberpunk_base_worn_icon_state || worn_icon_state
	name = design["name"] || name
	cyberpunk_base_icon_state = base_icon_state
	cyberpunk_base_worn_icon_state = base_worn_state
	icon = initial(icon)
	worn_icon = initial(worn_icon)
	icon_state = base_icon_state
	worn_icon_state = base_worn_state
	if(design["greyscale_colors"])
		greyscale_colors = design["greyscale_colors"]
	cyberpunk_custom_design_data = design.Copy()
	if(has_pixel_design)
		var/list/directions = design["directions"]
		var/has_worn_pixel_design = FALSE
		if(islist(directions))
			for(var/key in list("north", "south", "east", "west"))
				if(length("[directions[key] || ""]"))
					has_worn_pixel_design = TRUE
					break
		if(has_worn_pixel_design)
			var/icon/base_worn_icon
			if(initial(worn_icon) && base_worn_state)
				base_worn_icon = icon(initial(worn_icon), base_worn_state)
			else if(worn_icon && base_worn_state)
				base_worn_icon = icon(worn_icon, base_worn_state)
			var/icon/custom_worn_icon = cyberpunk_bake_directional_pixel_icon(directions, base_worn_icon, "cyberpunk_custom_worn")
			if(custom_worn_icon)
				worn_icon = custom_worn_icon
				worn_icon_state = "cyberpunk_custom_worn"
		if(length("[design["item_icon"] || ""]"))
			var/icon/base_item_icon
			if(initial(icon) && base_icon_state)
				base_item_icon = icon(initial(icon), base_icon_state, frame = 1)
			else if(icon && base_icon_state)
				base_item_icon = icon(icon, base_icon_state, frame = 1)
			var/icon/custom_item_icon = cyberpunk_bake_item_pixel_icon(design["item_icon"], base_item_icon)
			if(custom_item_icon)
				icon = custom_item_icon
				icon_state = ""
	update_appearance()
	if(has_pixel_design)
		var/mob/living/carbon/wearer
		if(iscarbon(loc))
			wearer = loc
		if(wearer)
			if(src in wearer.held_items)
				wearer.update_held_items()
			if(src in wearer.get_equipped_items())
				wearer.update_clothing(slot_flags)
	return TRUE

/obj/item/clothing/proc/cyberpunk_material_signature()
	if(!length(custom_materials))
		return ""
	var/list/materials = list()
	for(var/datum/material/material as anything in custom_materials)
		materials += "[material.type]:[custom_materials[material]]"
	return jointext(materials, ";")
