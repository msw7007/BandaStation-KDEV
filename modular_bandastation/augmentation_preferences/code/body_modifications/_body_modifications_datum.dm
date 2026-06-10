GLOBAL_LIST_INIT(character_setup_organ_replacement_roots, list(
	/obj/item/organ/brain,
	/obj/item/organ/ears,
	/obj/item/organ/eyes,
	/obj/item/organ/heart,
	/obj/item/organ/liver,
	/obj/item/organ/lungs,
	/obj/item/organ/stomach,
	/obj/item/organ/tongue,
))
GLOBAL_LIST_INIT(character_setup_hidden_organ_replacements, list(
	/obj/item/organ/eyes/robotic,
	/obj/item/organ/eyes/robotic/basic,
	/obj/item/organ/eyes/robotic/basic/moth,
	/obj/item/organ/brain/cybernetic,
	/obj/item/organ/ears/cybernetic,
	/obj/item/organ/heart/cybernetic,
	/obj/item/organ/liver/cybernetic,
	/obj/item/organ/lungs/cybernetic,
	/obj/item/organ/stomach/cybernetic,
	/obj/item/organ/tongue/robot,
))
GLOBAL_LIST_INIT_TYPED(body_modifications, /datum/body_modification, init_body_modifications())

/proc/init_body_modifications()
	var/list/body_modifications = list()
	for(var/datum/body_modification/body_modification_type as anything in subtypesof(/datum/body_modification))
		if(body_modification_type == body_modification_type::abstract_type)
			continue

		body_modifications[body_modification_type::key] = new body_modification_type()

	for(var/obj/item/organ/cyberimp/implant_type as anything in subtypesof(/obj/item/organ/cyberimp))
		if(implant_type == implant_type::abstract_type)
			continue
		if(implant_type == /obj/item/organ/cyberimp/eyes)
			continue
		if(ispath(implant_type, /obj/item/organ/cyberimp/brain/neural_interface))
			continue

		var/obj/item/organ/cyberimp/implant_probe = new implant_type()
		var/implant_slot = implant_probe.slot
		var/implant_zone = implant_probe.zone
		var/list/valid_zones = implant_probe.valid_zones
		if(length(valid_zones))
			for(var/target_zone in valid_zones)
				var/list/zone_slots = get_character_setup_cyberimp_slots(implant_probe, target_zone, valid_zones[target_zone])
				if(!length(zone_slots))
					continue
				for(var/zone_slot in zone_slots)
					register_character_setup_cyberimp(body_modifications, implant_type, zone_slot, get_character_setup_cyberimp_zone(implant_probe, target_zone))
			qdel(implant_probe)
			continue

		if(!implant_slot)
			qdel(implant_probe)
			continue
		for(var/zone_slot in get_character_setup_cyberimp_slots(implant_probe, implant_zone, implant_slot))
			register_character_setup_cyberimp(body_modifications, implant_type, zone_slot, get_character_setup_cyberimp_zone(implant_probe, implant_zone))
		qdel(implant_probe)

	for(var/organ_root in GLOB.character_setup_organ_replacement_roots)
		for(var/obj/item/organ/organ_type as anything in subtypesof(organ_root))
			if(!is_character_setup_visible_organ_replacement(organ_type))
				continue

			var/obj/item/organ/organ_probe = new organ_type()
			if(!organ_probe.slot || !organ_probe.name)
				qdel(organ_probe)
				continue

			register_character_setup_organ_replacement(body_modifications, organ_type, organ_probe)
			qdel(organ_probe)

	return body_modifications

/proc/register_character_setup_cyberimp(list/body_modifications, implant_type, target_slot, target_zone)
	var/datum/body_modification/cybernetic_implant/modification = new(implant_type, target_slot, target_zone)
	body_modifications[modification.key] = modification

/proc/register_character_setup_organ_replacement(list/body_modifications, organ_type, obj/item/organ/organ_probe)
	var/datum/body_modification/dynamic_organ_replacement/modification = new(organ_type, organ_probe)
	if(!modification.key)
		qdel(modification)
		return
	body_modifications[modification.key] = modification

/proc/is_character_setup_visible_organ_replacement(organ_type)
	if(organ_type in GLOB.character_setup_hidden_organ_replacements)
		return FALSE

	var/organ_type_text = "[organ_type]"
	if(findtext(organ_type_text, "/cybernetic"))
		return TRUE
	if(findtext(organ_type_text, "/robotic"))
		return TRUE
	if(findtext(organ_type_text, "/evolved"))
		return TRUE
	if(findtext(organ_type_text, "/night_vision"))
		return TRUE

	return FALSE

/proc/get_character_setup_cyberimp_zone(obj/item/organ/cyberimp/implant, target_zone)
	return target_zone

/proc/get_character_setup_cyberimp_slots(obj/item/organ/cyberimp/implant, target_zone, target_slot)
	return target_slot ? list(target_slot) : list()

/proc/body_zone_to_character_setup_part(body_zone)
	switch(body_zone)
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_NECK)
			return "head"
		if(BODY_ZONE_L_ARM)
			return "left_arm"
		if(BODY_ZONE_R_ARM)
			return "right_arm"
		if(BODY_ZONE_L_LEG)
			return "left_leg"
		if(BODY_ZONE_R_LEG)
			return "right_leg"
		if(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN)
			return "torso"

	return "torso"

/datum/body_modification
	abstract_type = /datum/body_modification
	var/key = null
	var/name = null
	var/cost = 0
	var/list/incompatible_body_modifications = list()
	var/category = null
	/// Coarse setup zone used by the Biometrics UI.
	var/body_part = null
	/// Exact organ/body zone, when known.
	var/body_zone = null
	/// Internal slot this modification occupies/replaces, when known.
	var/slot_id = null
	/// UI grouping: organ, implant, prosthesis, amputation, feature.
	var/modification_kind = "feature"
	/// Optional icon preview for the modification picker.
	var/icon = null
	var/icon_state = null
	/// RnD/build grade shown in character setup.
	var/tier = null
	var/grade = null
	var/availability = "available"
	var/locked_reason = null
	/// Preference-time chrome load used by the biometrics setup preview.
	var/chromity_cost = 0

/datum/body_modification/New()
	..()
	if(isnull(key))
		stack_trace("body modification without key: [type]")

	if(abstract_type == type)
		stack_trace("abstract body modification attempted to be instantiated: [type]")
		qdel(src)

/datum/body_modification/proc/apply_to_human(mob/living/carbon/target, additional_params)
	SHOULD_CALL_PARENT(TRUE)

	return can_be_applied(target, additional_params)

/datum/body_modification/proc/can_be_applied(mob/living/carbon/target, additional_params)
	SHOULD_CALL_PARENT(TRUE)

	if(isnull(target))
		return FALSE

	var/list/applied_body_modifications = target.client?.prefs?.read_preference(/datum/preference/body_modifications)
	if(length(applied_body_modifications) == 0)
		return TRUE

	for(var/incompatible_body_modification in incompatible_body_modifications)
		if(incompatible_body_modification in applied_body_modifications)
			return FALSE

	return TRUE

/datum/body_modification/proc/get_conflicting_body_modifications(mob/living/carbon/target)
	return incompatible_body_modifications & target.client?.prefs?.read_preference(/datum/preference/body_modifications)

/datum/body_modification/proc/get_description()
	return "No description yet"

/// Checks if the preference value is valid
/datum/body_modification/proc/preference_value_valid(params)
	return TRUE

/// Return default value for preference
/datum/body_modification/proc/default_preference_value(params)
	return list()

/// Checks if passed params from UI are valid
/datum/body_modification/proc/ui_params_valid(params)
	return TRUE

/// Dangerously deserialize preference ui params,
/// as `/datum/body_modification/proc/is_valid_preference_params` is called before
/datum/body_modification/proc/handle_ui_params(params)
	return list()

/datum/body_modification/proc/get_manufacturers()
	return list()

/datum/body_modification/proc/get_default_manufacturer()
	var/list/manufacturers = get_manufacturers()
	return length(manufacturers) ? manufacturers[1] : null
