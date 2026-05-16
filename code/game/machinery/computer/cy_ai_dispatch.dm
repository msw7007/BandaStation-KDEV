/obj/machinery/computer/cy_ai_dispatch
	name = "AI dispatch console"
	desc = "A command console for assigning strategic orders to local NPC controllers."
	icon_screen = "ai-fixer"
	icon_keyboard = "tech_key"
	var/dispatch_range = 14

/obj/machinery/computer/cy_ai_dispatch/proc/get_local_npcs()
	var/list/result = list()
	for(var/mob/living/living_mob in oview(dispatch_range, src))
		if(living_mob.ai_controller?.cy_npc_profile)
			result += living_mob
	return result

/obj/machinery/computer/cy_ai_dispatch/proc/dispatch_order(order_type, atom/target, list/data)
	var/count = 0
	for(var/mob/living/living_mob as anything in get_local_npcs())
		if(SSai_controllers.cy_npc_dispatch_order(living_mob, order_type, target, data))
			count++
	return count
