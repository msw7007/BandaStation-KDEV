//CYBERPUNK CORPORATIONS - subsidiary metadata.
/datum/cyberpunk_corporate_subsidiary
	var/id = ""
	var/name = ""
	var/parent_id = ""
	var/manufacturer = ""
	var/focus = ""
	var/data_type = "general"

/datum/cyberpunk_corporate_subsidiary/New(parent_id, subsidiary_id, subsidiary_name, subsidiary_manufacturer, subsidiary_focus, subsidiary_data_type)
	. = ..()
	src.parent_id = parent_id
	id = subsidiary_id
	name = subsidiary_name
	manufacturer = subsidiary_manufacturer || subsidiary_name
	focus = subsidiary_focus
	data_type = subsidiary_data_type || "general"

/datum/cyberpunk_corporate_subsidiary/proc/matches_manufacturer(manufacturer_text)
	manufacturer_text = lowertext(trim("[manufacturer_text]"))
	if(!manufacturer_text)
		return FALSE
	return findtext(manufacturer_text, lowertext(name)) || findtext(manufacturer_text, lowertext(manufacturer)) || findtext(manufacturer_text, lowertext(id))

/datum/cyberpunk_corporate_subsidiary/proc/to_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"manufacturer" = manufacturer,
		"focus" = focus,
		"dataType" = data_type,
	)
