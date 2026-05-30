#define CULTIVATOR_TILL_TIME (3 SECONDS)
#define CULTIVATOR_WEED_TIME (2 SECONDS)

/obj/item/cultivator/interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(istype(target, /obj/machinery/hydroponics))
		return remove_weeds(target, user)
	if(istype(target, /turf/open/misc/dirt) || istype(target, /turf/open/misc/grass))
		return till_soil(target, user)
	return NONE

/obj/item/cultivator/proc/till_soil(turf/target, mob/living/user)
	if(locate(/obj/machinery/hydroponics) in target)
		balloon_alert(user, "грядка уже есть")
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "рыхлим землю...")
	if(!do_after(user, CULTIVATOR_TILL_TIME, target))
		return ITEM_INTERACT_BLOCKING
	new /obj/machinery/hydroponics/soil(target)
	playsound(target, 'sound/effects/soil_plop.ogg', 50, TRUE)
	balloon_alert(user, "грядка готова")
	if(user.mind)
		user.mind.adjust_experience(/datum/skill/gardening, SKILL_XP_GARDENING_PER_WATERING)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivator/proc/remove_weeds(obj/machinery/hydroponics/tray, mob/living/user)
	if(tray.weedlevel <= 0)
		return NONE
	balloon_alert(user, "выкорчёвываем сорняки...")
	if(!do_after(user, CULTIVATOR_WEED_TIME, tray))
		return ITEM_INTERACT_BLOCKING
	tray.set_weedlevel(0)
	balloon_alert(user, "сорняки убраны")
	return ITEM_INTERACT_SUCCESS

#undef CULTIVATOR_TILL_TIME
#undef CULTIVATOR_WEED_TIME
