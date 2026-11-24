/mob/living/carbon
	/// Route records: chemical, affected zone (null means systemic), strength, remaining effective seconds.
	var/list/medical_analgesics
	/// Set synchronously by targeted applicators; unrelated exposure defaults to the chest.
	var/medical_exposure_zone = BODY_ZONE_CHEST
	var/medical_exposure_is_spray = FALSE
	var/medical_adrenaline_until = 0

/datum/reagent
	/// Null uses the ordinary 50% category for existing analgesic medicines.
	var/medical_pain_strength

/datum/reagent/proc/pain_strength()
	if(!isnull(medical_pain_strength))
		return medical_pain_strength
	return (TRAIT_ANALGESIA in metabolized_traits) ? 0.5 : 0

/datum/reagent/drug/pumpup
	medical_pain_strength = 1
/datum/reagent/drug/bath_salts
	medical_pain_strength = 1
/datum/reagent/drug/maint/sludge
	medical_pain_strength = 1
/datum/reagent/medicine/adminordrazine
	medical_pain_strength = 1

/mob/living/carbon/proc/medical_analgesia(body_zone)
	body_zone = check_zone(body_zone)
	if(HAS_TRAIT(src, TRAIT_MEDICAL_ANESTHESIA))
		return 1
	var/strength = world.time < medical_adrenaline_until ? 0.5 : 0
	// Gas anesthesia and nonchemical abilities retain their true analgesia. Numb only hides perception.
	for(var/source in GET_TRAIT_SOURCES(src, TRAIT_ANALGESIA))
		if(source == QUIRK_TRAIT && HAS_TRAIT(src, TRAIT_PAIN_NUMB))
			continue
		if(findtext("[source]", "metabolize:") == 1)
			continue
		return 1
	var/list/routed = list()
	for(var/key in medical_analgesics)
		var/list/entry = medical_analgesics[key]
		routed |= entry["chemical"]
		if(!entry["zone"])
			if(!reagents.has_reagent(entry["chemical"]))
				continue
		else if(entry["zone"] != body_zone || entry["seconds"] <= 0)
			continue
		strength = max(strength, entry["strength"])
	for(var/datum/reagent/chem as anything in reagents.reagent_list)
		if(!(chem.type in routed))
			strength = max(strength, chem.pain_strength())
	return strength

/mob/living/carbon/proc/medical_exposure(datum/reagent/chem, methods, amount, touch_protection)
	if(amount <= 0)
		return
	var/local = (methods & (TOUCH | PATCH)) || medical_exposure_is_spray
	var/strength = chem.pain_strength()
	if(strength)
		strength *= local ? 0.9 * (1 - touch_protection) : (methods & INGEST ? 0.5 : 1)
		var/zone = local ? medical_exposure_zone : null
		var/key = "[chem.type]-[zone]-[methods]"
		var/list/entry = LAZYACCESS(medical_analgesics, key)
		var/seconds = max(5, amount / max(0.01, chem.metabolization_rate))
		LAZYSET(medical_analgesics, key, list("chemical" = chem.type, "zone" = zone, "strength" = strength, "seconds" = max(seconds, entry?["seconds"])))
	if(!local)
		return
	var/obj/item/bodypart/limb = get_bodypart(medical_exposure_zone)
	if(!limb || !IS_ORGANIC_LIMB(limb))
		return
	var/datum/component/medical_condition/condition = limb.get_medical_condition()
	if(istype(chem, /datum/reagent/space_cleaner/sterilizine))
		condition.sterilize(amount)
	else if(istype(chem, /datum/reagent/medicine/mine_salve) && condition.infection_stage() <= 1)
		condition.treat_infection(60 * amount)
	else if(istype(chem, /datum/reagent/medicine/potass_iodide))
		condition.treat_infection(30 * amount)
	else if(istype(chem, /datum/reagent/medicine/c2/synthflesh))
		condition.treat_minor(TRUE, TRUE)

/mob/living/carbon/proc/process_medical_chemistry(datum/reagent/chem, seconds_per_tick)
	if(!istype(chem, /datum/reagent/medicine/spaceacillin) && !istype(chem, /datum/reagent/medicine/necroinversite) && !istype(chem, /datum/reagent/medicine/cryoxadone))
		return
	for(var/obj/item/bodypart/limb as anything in bodyparts)
		var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
		if(!condition)
			continue
		if(istype(chem, /datum/reagent/medicine/spaceacillin))
			condition.treat_infection(4 * seconds_per_tick)
		else if(istype(chem, /datum/reagent/medicine/necroinversite))
			condition.treat_infection(8 * seconds_per_tick)
		else if(bodytemperature < T0C && istype(loc, /obj/machinery/cryo_cell))
			var/obj/machinery/cryo_cell/cell = loc
			if(cell.on && cell.occupant == src)
				condition.treat_minor(TRUE, TRUE)
				if(limb.body_zone == BODY_ZONE_HEAD || limb.body_zone == BODY_ZONE_CHEST)
					condition.treat_infection(5 * seconds_per_tick, critical = TRUE)

/datum/reagent/medicine/necroinversite
	name = "Necroinversite"
	description = "Reverses developing tissue infection. Fully necrotic tissue requires surgery."
	color = "#9d517b"
	overdose_threshold = 30
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/necroinversite/overdose_process(mob/living/affected_mob, seconds_per_tick, metabolization_ratio)
	. = ..()
	affected_mob.adjust_brute_loss(seconds_per_tick * metabolization_ratio)

/datum/chemical_reaction/medicine/necroinversite
	results = list(/datum/reagent/medicine/necroinversite = 3)
	required_reagents = list(/datum/reagent/medicine/spaceacillin = 1, /datum/reagent/medicine/c2/synthflesh = 1, /datum/reagent/medicine/potass_iodide = 1)
	reaction_tags = REACTION_TAG_HEALING

/obj/machinery/cryo_cell/proc/has_medical_wound_treatment()
	if(!on || !iscarbon(occupant))
		return FALSE
	var/mob/living/carbon/patient = occupant
	if(!patient.reagents.has_reagent(/datum/reagent/medicine/cryoxadone) && !beaker?.reagents.has_reagent(/datum/reagent/medicine/cryoxadone))
		return FALSE
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
		if(!condition)
			continue
		if(LAZYLEN(condition.minor_wounds))
			return TRUE
		if(condition.infection_stage() && (limb.body_zone == BODY_ZONE_HEAD || limb.body_zone == BODY_ZONE_CHEST))
			return TRUE
	return FALSE

