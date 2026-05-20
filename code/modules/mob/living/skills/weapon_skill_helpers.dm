/mob/living/proc/get_cy_weapon_skill_level(obj/item/weapon)
	if(!weapon)
		return CY_SKILL_LEVEL_UNTRAINED
	var/skill_type = weapon.get_cy_weapon_skill_type()
	if(!skill_type)
		return CY_SKILL_LEVEL_UNTRAINED
	return get_cy_skill_level(skill_type)

/mob/living/proc/get_cy_weapon_damage_multiplier(obj/item/weapon)
	return 1 + get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_DAMAGE_PER_LEVEL

/mob/living/proc/get_cy_weapon_cooldown_multiplier(obj/item/weapon)
	return max(0.1, 1 - get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_COOLDOWN_PER_LEVEL)

/mob/living/proc/get_cy_weapon_defense_bypass_bonus(obj/item/weapon)
	return get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_DEFENSE_BYPASS_PER_LEVEL

/mob/living/proc/get_cy_weapon_accuracy_bonus(obj/item/weapon)
	return get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_ACCURACY_PER_LEVEL

/mob/living/proc/get_cy_stat_weapon_damage_multiplier(obj/item/weapon)
	if(!weapon)
		return 1
	var/multiplier = 1
	if(weapon.w_class >= WEIGHT_CLASS_BULKY)
		if(!get_cy_skill_level(/datum/cy_skill/strength/heavy_weapons))
			multiplier *= 0.9
		multiplier += get_cy_skill_level(/datum/cy_skill/strength/heavy_weapons) * 0.03
		if(has_cy_skill_perk_level(/datum/cy_skill/strength/heavy_weapons, 2))
			multiplier += get_cy_stat(/datum/cy_stat/strength) * 0.005
	else if(weapon.w_class <= WEIGHT_CLASS_SMALL)
		multiplier += get_cy_skill_level(/datum/cy_skill/dexterity/light_weapons) * 0.02
	if(weapon.get_sharpness())
		multiplier += get_cy_skill_level(/datum/cy_skill/perception/precise_melee) * 0.015
	if(has_cy_skill_perk_level(/datum/cy_skill/perception/weakspot_analysis, 3))
		multiplier += 0.05
	return multiplier

/mob/living/proc/get_cy_weapon_spread_multiplier(obj/item/weapon)
	var/multiplier = 1 - get_cy_weapon_skill_level(weapon) * CY_WEAPON_SKILL_SPREAD_REDUCTION_PER_LEVEL
	if(weapon?.w_class >= WEIGHT_CLASS_BULKY)
		var/heavy_level = get_cy_skill_level(/datum/cy_skill/strength/heavy_weapons)
		if(heavy_level >= 6)
			multiplier = min(multiplier, 0.1)
		else if(heavy_level >= 4)
			multiplier *= 0.7
	return max(0.1, multiplier)

/mob/living/proc/apply_cy_stat_weapon_onhit_effects(mob/living/target, obj/item/weapon, target_zone, damage_done)
	if(!target || !weapon || target == src || damage_done <= 0)
		return FALSE
	if(has_cy_skill_perk_level(/datum/cy_skill/strength/heavy_weapons, 6) && weapon.w_class >= WEIGHT_CLASS_BULKY && prob(10))
		target.Knockdown(1.5 SECONDS)
	if(has_cy_skill_perk_level(/datum/cy_skill/dexterity/light_weapons, 3) && weapon.w_class <= WEIGHT_CLASS_NORMAL && prob(25))
		target.adjust_stamina_loss(6)
	if(has_cy_skill_perk_level(/datum/cy_skill/perception/weakspot_analysis, 2) && prob(10))
		target.apply_damage(max(1, round(damage_done * 0.2)), weapon.damtype, target_zone)
	if(has_cy_skill_perk_level(/datum/cy_skill/perception/weakspot_analysis, 4) && prob(15))
		target.Immobilize(2 SECONDS)
	if(has_cy_skill_perk_level(/datum/cy_skill/perception/weakspot_analysis, 6) && target_zone == BODY_ZONE_HEAD && prob(25))
		target.Paralyze(2 SECONDS)
	if(has_cy_skill_perk_level(/datum/cy_skill/perception/precise_melee, 5) && target_zone == BODY_ZONE_HEAD && prob(30))
		target.adjust_confusion_up_to(4 SECONDS, 8 SECONDS)
	if(has_cy_skill_perk_level(/datum/cy_skill/charisma/style, 6) && prob(20))
		target.adjust_temp_blindness_up_to(2 SECONDS, 4 SECONDS)
	return TRUE

/mob/living/proc/award_cy_weapon_activity(obj/item/weapon, amount)
	if(!weapon || amount <= 0)
		return FALSE
	var/skill_type = weapon.get_cy_weapon_skill_type()
	if(!ispath(skill_type, /datum/cy_skill/weapon))
		return FALSE
	return award_cy_raw_skill_experience(skill_type, amount)

/datum/crafting_recipe/proc/get_cy_professional_skill_type()
	if(ispath(result, /obj/item/food))
		return /datum/cy_skill/professional/cooking
	if(ispath(result, /obj/item/seeds))
		return /datum/cy_skill/professional/gardening
	if(ispath(result, /obj/item/reagent_containers) || ispath(result, /datum/reagent))
		return /datum/cy_skill/professional/chemistry
	if(ispath(result, /obj/item/circuitboard) || ispath(result, /obj/machinery))
		return /datum/cy_skill/professional/electricity
	if(ispath(result, /obj/structure) || ispath(result, /turf))
		return /datum/cy_skill/professional/construction
	if(ispath(result, /obj/item))
		return /datum/cy_skill/professional/invention
	return null

/atom/proc/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return current_recipe?.get_cy_professional_skill_type()

/obj/item/food/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/cooking

/obj/item/seeds/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/gardening

/obj/item/reagent_containers/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/chemistry

/obj/item/circuitboard/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/electricity

/obj/machinery/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/electricity

/obj/structure/get_cy_crafting_skill_type(datum/crafting_recipe/current_recipe)
	return /datum/cy_skill/professional/construction

/mob/living/proc/get_cy_professional_crafting_speed_multiplier(datum/crafting_recipe/recipe)
	var/skill_type = recipe?.get_cy_professional_skill_type()
	if(!skill_type)
		return 1
	return get_cy_skill_speed_multiplier(skill_type)

/mob/living/proc/get_cy_professional_crafting_quality_bonus(datum/crafting_recipe/recipe)
	var/skill_type = recipe?.get_cy_professional_skill_type()
	if(!skill_type)
		return 0
	return get_cy_professional_quality_bonus(skill_type)
