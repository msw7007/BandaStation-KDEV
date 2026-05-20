// CYBERPUNK 13 STAGE 3 CORE OXYGENATION / DIAGNOSIS START
/mob/living/carbon/human/proc/get_cy_blood_percent()
	if(!blood_volume)
		return 0
	return clamp(blood_volume / BLOOD_VOLUME_NORMAL, 0, 1)

/mob/living/carbon/human/proc/get_cy_pressure_delta()
	var/obj/item/organ/heart/heart = get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart)
		return 0
	var/pressure = heart.get_cy_pressure_delta()
	if(reagents?.has_reagent(/datum/reagent/medicine/epinephrine))
		pressure += CY_PRESSURE_EPINEPHRINE_BONUS
	if(reagents?.has_reagent(/datum/reagent/medicine/atropine))
		pressure += CY_PRESSURE_ATROPINE_BONUS
	return clamp(pressure, 0, 1.5)

/mob/living/carbon/human/proc/get_cy_lung_efficiency()
	var/obj/item/organ/lungs/lungs = get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		return 0
	return lungs.get_cy_lung_efficiency()

/mob/living/carbon/human/proc/get_cy_blood_oxygenation()
	return clamp(get_cy_blood_percent() * get_cy_pressure_delta() * get_cy_lung_efficiency(), 0, 1)

/mob/living/carbon/human/proc/process_cy_oxygenation(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_NOBREATH) || stat == DEAD)
		return FALSE
	var/oxygenation = get_cy_blood_oxygenation()
	if(oxygenation >= CY_BLOOD_OXYGENATION_BRAIN_REQUIRED)
		adjust_oxy_loss(-0.35 * seconds_per_tick, updating_health = FALSE, forced = TRUE)
		if(oxygenation > 1)
			adjust_stamina_loss(-CY_HIGH_OXYGEN_STAMINA_RECOVERY * seconds_per_tick, updating_stamina = FALSE, forced = TRUE)
		return TRUE
	var/deficit = CY_BLOOD_OXYGENATION_BRAIN_REQUIRED - oxygenation
	adjust_oxy_loss(deficit * 4 * seconds_per_tick, updating_health = FALSE, forced = TRUE)
	if(oxygenation <= 0.25)
		adjust_organ_loss(ORGAN_SLOT_BRAIN, CY_CRITICAL_OXYGEN_BRAIN_DAMAGE_PER_SECOND * seconds_per_tick)
	else
		adjust_organ_loss(ORGAN_SLOT_BRAIN, CY_LOW_OXYGEN_BRAIN_DAMAGE_PER_SECOND * deficit * seconds_per_tick)
	return TRUE

/mob/living/carbon/human/proc/get_cy_diagnostic_lines(mob/living/user, advanced = FALSE)
	var/list/lines = list()
	var/medicine_level = user?.get_cy_medicine_skill_level() || CY_SKILL_LEVEL_UNTRAINED
	if(medicine_level <= CY_SKILL_LEVEL_UNTRAINED && !advanced)
		lines += "General state: [health < critical_health_threshold ? "critical" : health < maxHealth * 0.5 ? "poor" : "stable"]."
		return lines
	lines += "Health [round(health)]/[maxHealth]; pain [round(get_pain_loss())]; psychic [round(get_psychic_loss())]."
	if(medicine_level >= CY_SKILL_LEVEL_TRAINED || advanced)
		lines += "Blood [round(get_cy_blood_percent() * 100)]%; pressure [round(get_cy_pressure_delta() * 100)]%; lung efficiency [round(get_cy_lung_efficiency() * 100)]%; oxygenation [round(get_cy_blood_oxygenation() * 100)]%."
	if(is_cy_clinically_dead())
		lines += "Clinical death threshold reached. Revive requires working heart and non-dead brain."
	if(brain_dead)
		lines += "Brain death: revival blocked."
	if(has_dna())
		lines += "Humanoidity [round(get_cy_humanoidity())]%; stabilized buffer [round(get_cy_humanoidity_stabilized_bonus())]%; gene slots [length(dna.cy_gene_segments)]/[CY_GENETIC_MAX_SEGMENTS]."
	var/implant_heat = get_cy_total_implant_overheat()
	if(implant_heat || advanced)
		lines += "Implants: neural interface [has_cy_neurointerface() ? "online" : "missing"]; heat [round(implant_heat)]/[round(get_cy_brain_overheat_capacity())]."
	if(advanced)
		for(var/obj/item/organ/organ as anything in organs)
			lines += organ.get_cy_diagnostic_lines(TRUE)
		for(var/obj/item/organ/cyberimp/implant as anything in organs)
			var/datum/cy_organization/manufacturer = implant.get_manufacturer_organization()
			lines += "[capitalize(implant.name)]: manufacturer [manufacturer ? manufacturer.name : "unknown"], heat [round(implant.get_cy_implant_overheat())], state [implant.is_cy_functional_implant() ? "functional" : "offline"]."
	return lines

/mob/living/proc/get_cy_secondary_indicators()
	var/list/indicators = list()
	indicators["health"] = list(
		"current" = health,
		"maximum" = maxHealth,
		"critical" = is_cy_critical(),
		"clinical_death" = is_cy_clinically_dead(),
		"brain_dead" = is_cy_brain_dead(),
	)
	indicators["breath"] = list(
		"reserved_breath" = losebreath,
		"oxygen_damage" = get_oxy_loss(),
	)
	indicators["stamina"] = list(
		"loss" = staminaloss,
		"maximum" = max_stamina,
	)
	indicators["needs"] = list(
		"nutrition" = nutrition,
		"nutrition_stage" = get_cy_hunger_level(),
		"hydration" = hydration,
		"hydration_stage" = get_cy_thirst_level(),
		"rest" = rest,
		"rest_stage" = get_cy_sleep_deprivation_level(),
	)
	indicators["mental"] = list(
		"pain" = get_pain_loss(),
		"psychic_pressure" = get_psychic_loss(),
		"mood_level" = mob_mood?.mood_level,
		"sanity_level" = mob_mood?.sanity_level,
	)
	indicators["psyche"] = get_cy_psyche_state()
	indicators["style"] = list(
		"equipment_score" = get_cy_equipment_style_score(),
		"tags" = get_cy_equipment_style_tags(),
	)
	var/area/current_area = get_area(src)
	indicators["zone"] = current_area?.cy_describe_zone()
	indicators["legal_risk"] = list(
		"controlled_items_here" = length(get_cy_controlled_items_in_zone()),
	)
	indicators["equipment"] = get_cy_equipment_indicator()
	return indicators

/mob/living/proc/get_cy_equipment_indicator()
	var/list/equipment = list()
	for(var/obj/item/equipped as anything in get_equipped_items(INCLUDE_ABSTRACT))
		equipment += list(list(
			"name" = equipped.name,
			"type" = equipped.type,
			"weight_class" = equipped.w_class,
			"style" = equipped.get_cy_style_value(),
			"style_tags" = equipped.get_cy_style_tags(),
			"market_category" = equipped.get_cy_market_category(),
			"market_value" = equipped.get_cy_market_value(),
		))
	return equipment

/mob/living/proc/get_cy_secondary_indicator_summary()
	var/list/indicators = get_cy_secondary_indicators()
	var/list/health_data = indicators["health"]
	var/list/breath_data = indicators["breath"]
	var/list/stamina_data = indicators["stamina"]
	var/list/needs_data = indicators["needs"]
	var/list/mental_data = indicators["mental"]
	var/list/style_data = indicators["style"]
	return list(
		"Health [round(health_data["current"])]/[health_data["maximum"]]",
		"Breath reserve [round(breath_data["reserved_breath"])]; oxygen damage [round(breath_data["oxygen_damage"])]",
		"Stamina loss [round(stamina_data["loss"])]/[stamina_data["maximum"]]",
		"Nutrition [round(needs_data["nutrition"])]; hydration [round(needs_data["hydration"])]; rest [round(needs_data["rest"])]",
		"Pain [round(mental_data["pain"])]; psychic [round(mental_data["psychic_pressure"])]",
		"Style [round(style_data["equipment_score"])]",
	)

/mob/living/carbon/human/get_cy_secondary_indicators()
	. = ..()
	.["blood"] = list(
		"percent" = get_cy_blood_percent(),
		"pressure" = get_cy_pressure_delta(),
		"oxygenation" = get_cy_blood_oxygenation(),
	)
	.["implants"] = list(
		"overheat" = get_cy_total_implant_overheat(),
		"overheat_capacity" = get_cy_brain_overheat_capacity(),
		"has_neurointerface" = has_cy_neurointerface(),
	)
	.["organs"] = get_cy_organ_indicator()
	.["limbs"] = get_cy_limb_indicator()

/mob/living/carbon/human/proc/get_cy_organ_indicator()
	var/list/organ_data = list()
	for(var/obj/item/organ/organ as anything in organs)
		organ_data[organ.slot || "[organ.type]"] = list(
			"name" = organ.name,
			"type" = organ.type,
			"health_ratio" = organ.get_cy_health_ratio(),
			"function_efficiency" = organ.get_cy_function_efficiency(),
			"damage" = organ.damage,
			"maximum" = organ.maxHealth,
			"conditions" = organ.get_cy_condition_summary(),
		)
	return organ_data

/mob/living/carbon/human/proc/get_cy_limb_indicator()
	var/list/limb_data = list()
	for(var/obj/item/bodypart/limb as anything in get_bodyparts(include_stumps = TRUE))
		limb_data[limb.body_zone || "[limb.type]"] = list(
			"name" = limb.name,
			"type" = limb.type,
			"brute" = limb.get_brute_damage(),
			"burn" = limb.get_burn_damage(),
			"maximum" = limb.max_damage,
			"disabled" = limb.bodypart_disabled,
			"missing" = IS_STUMP(limb),
			"bleed_rate" = limb.cached_bleed_rate,
			"wounds" = length(limb.wounds),
		)
	return limb_data

/mob/living/carbon/human/get_cy_secondary_indicator_summary()
	. = ..()
	. += "Blood [round(get_cy_blood_percent() * 100)]%; oxygenation [round(get_cy_blood_oxygenation() * 100)]%"
	. += "Implants heat [round(get_cy_total_implant_overheat())]/[round(get_cy_brain_overheat_capacity())]"
// CYBERPUNK 13 STAGE 3 CORE OXYGENATION / DIAGNOSIS END

// CYBERPUNK 13 STAGE 3 CORE REAGENT ROUTE STATE START
/mob/living/carbon
	/// Last CP13 route used by reagents entering blood metabolism. Defaults to injection/blood.
	var/cy_current_reagent_route = CY_REAGENT_ROUTE_INJECT

/mob/living/carbon/proc/get_cy_current_reagent_route()
	return cy_current_reagent_route || CY_REAGENT_ROUTE_INJECT

/mob/living/carbon/proc/set_cy_current_reagent_route(route)
	cy_current_reagent_route = route || CY_REAGENT_ROUTE_INJECT
	return cy_current_reagent_route
// CYBERPUNK 13 STAGE 3 CORE REAGENT ROUTE STATE END


// CYBERPUNK 13 STAGE 3 CORE MEDICAL ROUTING FIX3 START
/mob/living/carbon/human/proc/route_cy_toxin_to_organs(amount, acidic = FALSE)
	if(amount <= 0)
		return FALSE
	var/obj/item/organ/liver/liver = get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && liver.get_cy_function_efficiency() > 0)
		adjust_organ_loss(ORGAN_SLOT_LIVER, amount * CY_TOXIN_LIVER_ROUTING_MULTIPLIER, required_organ_flag = ORGAN_ORGANIC)
		if(acidic)
			adjust_organ_loss(pick(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH), amount * 0.15, required_organ_flag = ORGAN_ORGANIC)
		return TRUE
	var/list/fallback_organs = list(ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_BRAIN)
	for(var/i in 1 to min(3, length(fallback_organs)))
		adjust_organ_loss(pick_n_take(fallback_organs), amount * CY_TOXIN_ORGAN_SPILLOVER_MULTIPLIER, required_organ_flag = ORGAN_ORGANIC)
	return TRUE

/mob/living/carbon/human/proc/apply_cy_rapid_bloodloss(amount)
	if(amount <= 0)
		return FALSE
	adjust_organ_loss(ORGAN_SLOT_HEART, amount * CY_FAST_BLOOD_LOSS_HEART_DAMAGE_PER_UNIT, required_organ_flag = ORGAN_ORGANIC)
	adjust_organ_loss(ORGAN_SLOT_BRAIN, amount * CY_FAST_BLOOD_LOSS_BRAIN_DAMAGE_PER_UNIT, required_organ_flag = ORGAN_ORGANIC)
	return TRUE
// CYBERPUNK 13 STAGE 3 CORE MEDICAL ROUTING FIX3 END
