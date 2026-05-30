/obj/item/plant_analyzer/analyze(mob/user, atom/target)
	. = ..()
	if(!user?.mind)
		return
	user.mind.adjust_experience(/datum/skill/analysis, SKILL_XP_ANALYSIS_PER_SCAN)
	var/level = user.mind.get_skill_level(/datum/skill/analysis)
	if(level < SKILL_LEVEL_APPRENTICE)
		return
	var/obj/item/seeds/checked_seed
	if(istype(target, /obj/item/seeds))
		checked_seed = target
	else if(istype(target, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/tray = target
		checked_seed = tray.myseed
	if(!checked_seed)
		return
	to_chat(user, span_notice("Скрытый анализ: нестабильность [checked_seed.instability], [checked_seed.is_negative_plant() ? "негативное растение" : "стабильное"]."))
