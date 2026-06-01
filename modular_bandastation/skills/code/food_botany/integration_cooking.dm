/obj/machinery/microwave/loop_finish(mob/cooker)
	apply_cooking_skill_bonus(cooker)
	return ..()

/obj/machinery/microwave/proc/apply_cooking_skill_bonus(mob/cooker)
	if(!cooker?.mind)
		return
	var/level = cooker.mind.get_skill_level(/datum/skill/cooking)
	var/bonus = level >= SKILL_LEVEL_APPRENTICE ? round((level - SKILL_LEVEL_NOVICE) / 2) : 0
	var/mob/living/living_cooker = isliving(cooker) ? cooker : null
	if(living_cooker)
		bonus = max(bonus, living_cooker.get_cyberpunk_cooking_quality_bonus())
	for(var/obj/item/ingredient in ingredients)
		var/obj/item/food/food_ingredient = ingredient
		if(living_cooker && istype(food_ingredient))
			var/compatibility_bonus = living_cooker.get_cyberpunk_cooking_compatibility_bonus(food_ingredient)
			if(compatibility_bonus)
				ingredient.AddElement(/datum/element/quality_food_ingredient, compatibility_bonus)
		if(bonus > 0)
			ingredient.AddElement(/datum/element/quality_food_ingredient, bonus)
		cooker.mind.adjust_experience(/datum/skill/cooking, SKILL_XP_COOKING_PER_ITEM)
