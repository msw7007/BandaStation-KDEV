/mob/living/proc/get_cy_controlled_items_in_zone()
	var/list/result = list()
	var/area/current_area = get_area(src)
	if(!current_area)
		return result
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		if(current_area.cy_requires_controlled_item_permit(equipped))
			result += equipped
	return result

/mob/living/proc/report_cy_controlled_items_in_zone(issuer = "Zone audit")
	if(!SSeconomy)
		return 0
	var/count = 0
	for(var/obj/item/item as anything in get_cy_controlled_items_in_zone())
		SSeconomy.cy_issue_violation(src, CY_LAW_CONTROLLED_ITEM, "Controlled item in restricted zone: [item.name].", issuer, null, null, CY_WARRANT_INVESTIGATION)
		item.cy_leave_forensic_trace(src, "controlled item possession", 80)
		count++
	return count

/mob/living/proc/on_cy_enter_area_audit(datum/source, area/entered_area)
	SIGNAL_HANDLER
	if(world.time < cy_next_controlled_item_audit_at)
		return FALSE
	if(!entered_area)
		return FALSE
	var/controlled_count = length(get_cy_controlled_items_in_zone())
	if(!controlled_count)
		return FALSE
	cy_next_controlled_item_audit_at = world.time + 2 MINUTES
	report_cy_controlled_items_in_zone("Area security scan")
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_LAW, controlled_count, src)
	return TRUE

/mob/living/proc/report_cy_violent_action(mob/living/target, obj/item/weapon = null, issuer = "Zone violence monitor")
	if(!target || target == src || world.time < cy_next_violence_report_at)
		return FALSE
	var/area/current_area = get_area(src)
	if(!current_area || current_area.cy_allows_open_violence())
		return FALSE
	cy_next_violence_report_at = world.time + 30 SECONDS
	var/law_id = target.stat == DEAD ? CY_LAW_MURDER : CY_LAW_ASSAULT
	var/details = "[src] attacked [target][weapon ? " with [weapon]" : ""] in [current_area.name]."
	SSeconomy?.cy_issue_violation(src, law_id, details, issuer, null, null, CY_WARRANT_INVESTIGATION)
	cy_leave_forensic_trace(src, "violent action", 75)
	target.cy_leave_forensic_trace(src, "violence target", 65)
	SScy_storyteller?.add_pressure(CY_STORY_PRESSURE_VIOLENCE, law_id == CY_LAW_MURDER ? 10 : 4, src)
	return TRUE

/mob/living/proc/on_cy_story_item_attack(datum/source, mob/living/attacked_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER
	var/obj/item/weapon = user?.get_active_held_item()
	return report_cy_violent_action(attacked_mob, weapon)

/mob/living/proc/on_cy_story_unarmed_attack(datum/source, atom/attacked_atom, proximity)
	SIGNAL_HANDLER
	if(!proximity || !isliving(attacked_atom))
		return FALSE
