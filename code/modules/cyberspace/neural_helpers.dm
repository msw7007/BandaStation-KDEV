// Cyberpunk 13 cyberspace: neural interface helpers and IC debug verbs.

/mob/living/proc/has_living_brain()
	var/obj/item/organ/brain = get_organ_slot(ORGAN_SLOT_BRAIN)
	return !isnull(brain) && !(brain.organ_flags & ORGAN_FAILING) && brain.damage < brain.maxHealth

/mob/living/proc/get_neural_interface()
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = get_organ_slot(ORGAN_SLOT_NEURAL_IMPLANT)
	return istype(neural_interface) ? neural_interface : null

/mob/living/proc/has_neural_implant()
	if(!has_living_brain())
		return FALSE
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = get_neural_interface()
	return !isnull(neural_interface) && neural_interface.is_implant_functional()

/mob/living/proc/can_be_net_target()
	return has_neural_implant()

/mob/living/proc/get_neural_ice_chromity_penalty()
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = get_neural_interface()
	if(!neural_interface)
		return 0
	return neural_interface.get_ice_chromity_penalty()

/mob/living/proc/get_neural_manufacturer()
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = get_neural_interface()
	if(!neural_interface)
		return null
	return neural_interface.corp_manufacturer

/mob/living/proc/get_corporate_synergy_multiplier(equipment_manufacturer)
	if(!has_neural_implant())
		return 1
	return cyberpunk_corporate_synergy_multiplier(get_neural_manufacturer(), equipment_manufacturer)

/mob/living/verb/enter_cyberspace()
	set name = "Enter Cyberspace"
	set category = "IC"
	set desc = "Enter or leave the local digital layer through your neural interface."

	if(stat > CONSCIOUS)
		return
	if(!has_neural_implant())
		to_chat(src, span_warning("Your body has no functional neural interface."))
		return
	start_cyberspace_session()

/mob/living/verb/exit_cyberspace()
	set name = "Exit Cyberspace"
	set category = "IC"
	set desc = "Collapse your current cyberspace projection."

	if(!stop_cyberspace_session())
		to_chat(src, span_warning("You are not projected into cyberspace."))

/mob/living/verb/test_random_ice_hack()
	set name = "Test Random ICE Hack"
	set category = "IC"
	set desc = "Open a random test ICE breach against your neural interface."

	if(stat > CONSCIOUS)
		return
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = get_neural_interface()
	if(!neural_interface)
		to_chat(src, span_warning("Your body has no neural interface to attack."))
		return
	if(!neural_interface.is_implant_functional())
		to_chat(src, span_warning("Your neural interface is not functional."))
		return
	neural_interface.start_ice_hack(src)

/mob/living/verb/test_local_cybernode_hack()
	set name = "Test Local Cybernode Hack"
	set category = "IC"
	set desc = "Build a local cyberspace node from this area and attack its ICE."

	if(stat > CONSCIOUS)
		return
	if(!has_neural_implant())
		to_chat(src, span_warning("Your body has no functional neural interface."))
		return
	var/datum/cyberspace_layer/layer = SScyberspace?.get_layer()
	var/list/nodes = layer?.nodes || build_cyberspace_nodes_for_area(src)
	if(!length(nodes))
		to_chat(src, span_warning("No cyberspace nodes resolve in this area."))
		return
	var/datum/cyberspace_node/node = layer?.get_nearest_node(src) || nodes[1]
	to_chat(src, span_notice("Resolved local node at [node.cyber_x], [node.cyber_y], source Z [node.source_z], area [node.physical_area?.name || "unknown"], with [node.get_object_count()] object(s) and [node.net_data] net-data."))
	node.start_ice_hack(src)
