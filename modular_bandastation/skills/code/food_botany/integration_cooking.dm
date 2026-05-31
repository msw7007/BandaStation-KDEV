/obj/machinery/microwave/loop_finish(mob/cooker)
	apply_cooking_skill_bonus(cooker)
	return ..()

/obj/machinery/microwave/proc/apply_cooking_skill_bonus(mob/cooker)
	if(!cooker?.mind)
		return
	var/level = cooker.mind.get_skill_level(/datum/skill/cooking)
	var/bonus = level >= SKILL_LEVEL_APPRENTICE ? round((level - SKILL_LEVEL_NOVICE) / 2) : 0
	for(var/obj/item/ingredient in ingredients)
		if(bonus > 0)
			ingredient.AddElement(/datum/element/quality_food_ingredient, bonus)
		cooker.mind.adjust_experience(/datum/skill/cooking, SKILL_XP_COOKING_PER_ITEM)
