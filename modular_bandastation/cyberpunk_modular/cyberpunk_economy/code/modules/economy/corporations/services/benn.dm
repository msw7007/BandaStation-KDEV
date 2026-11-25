//CYBERPUNK CORPORATIONS - Benn service completion.
/obj/item/healthanalyzer/benn_lifeline
	name = "Benn Lifeline analyzer"
	desc = "A Benn-branded medical analyzer tuned for fast field triage."
	cyberpunk_manufacturer = "Benn"
	cyberpunk_quality = 118
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 180

/obj/item/reagent_containers/hypospray/medipen/salbutamol/benn
	name = "Benn ClearBreath medipen"
	desc = "A Benn-branded emergency respiratory medipen."
	cyberpunk_manufacturer = "Benn"
	cyberpunk_quality = 115
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 140

/obj/item/reagent_containers/cup/beaker/large/epinephrine/benn
	name = "Benn PulseGuard vial"
	desc = "A sealed Benn emergency vial for premium medical support kits."
	cyberpunk_manufacturer = "Benn"
	cyberpunk_quality = 120
	cyberpunk_rarity = "rare"
	cyberpunk_base_price = 240

/obj/item/reagent_containers/applicator/pill/epinephrine/benn
	name = "Benn PulseTab"
	desc = "A Benn emergency stabilizer pill sealed for field responders."
	cyberpunk_manufacturer = "Benn"
	cyberpunk_quality = 112
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 95

/obj/item/reagent_containers/applicator/pill/salbutamol/benn
	name = "Benn ClearTab"
	desc = "A Benn respiratory support pill for compact response kits."
	cyberpunk_manufacturer = "Benn"
	cyberpunk_quality = 112
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 90

/proc/cyberpunk_prepare_benn_package(obj/item/storage/box/package, subscribed = FALSE)
	if(!package)
		return FALSE
	new /obj/item/stack/medical/wrap/gauze(package)
	new /obj/item/stack/medical/bruise_pack(package)
	new /obj/item/healthanalyzer/benn_lifeline(package)
	new /obj/item/reagent_containers/hypospray/medipen/salbutamol/benn(package)
	new /obj/item/reagent_containers/applicator/pill/salbutamol/benn(package)
	if(subscribed)
		new /obj/item/reagent_containers/hypospray/medipen/atropine(package)
		new /obj/item/reagent_containers/cup/beaker/large/epinephrine/benn(package)
		new /obj/item/reagent_containers/applicator/pill/epinephrine/benn(package)
	return TRUE

/// Records in-game medical or genetic research produced at Benn equipment or on Benn territory.
/proc/cyberpunk_record_benn_biodata(atom/source, edict_id, activity, amount = 1, credits = 0, branded_service = FALSE)
	if(!source || !SScyberpunk_corporations?.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_BENN, edict_id))
		return FALSE
	if(!branded_service && cyberpunk_property_edict_multiplier(source, CYBERPUNK_CORP_BENN, edict_id, 2) == 1)
		var/manufacturer = get_cyberspace_manufacturer(source)
		if(SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(manufacturer) != CYBERPUNK_CORP_BENN)
			return FALSE
	return SScyberpunk_corporations.record_cyberpunk_corporate_activity(CYBERPUNK_CORP_BENN, "bio", amount, credits, activity)

/mob/living/carbon/var/cyberpunk_benn_scan_available_at = 0

/datum/cyberpunk_corporation/var/list/benn_dna_sample_after = list()

/// Benn services collect game research data and recognizable foreign implant or equipment signatures.
/proc/cyberpunk_collect_benn_dna_sample(mob/living/carbon/human/patient, activity, revived = FALSE)
	if(!istype(patient) || !patient.dna || patient.stat == DEAD)
		return FALSE
	var/datum/cyberpunk_corporation/benn = SScyberpunk_corporations?.cyberpunk_corporations[CYBERPUNK_CORP_BENN]
	if(!benn?.has_edict("benn_dna_storage"))
		return FALSE
	var/area/patient_area = get_area(patient)
	if(!patient_area || is_area_virtual(patient_area))
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(patient, patient.get_bank_account())
	if(!character_key)
		return FALSE
	if(revived && benn.is_service_employee(patient, character_key))
		return FALSE
	var/sample_key = revived ? "revival:[character_key]" : character_key
	if(benn.benn_dna_sample_after[sample_key] > world.time)
		return FALSE
	benn.benn_dna_sample_after[sample_key] = world.time + (revived ? (5 MINUTES) : (1 MINUTES))

	benn.add_data("bio", revived ? 6 : 2, activity)
	var/list/foreign_ids = list()
	var/job_corporation = patient.mind?.assigned_role?.get_cyberpunk_corporation_id()
	if(job_corporation in list(CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT))
		foreign_ids += job_corporation
	var/list/equipment = patient.get_equipped_items(INCLUDE_HELD) + patient.organs
	for(var/obj/item/item as anything in equipment)
		var/id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(item))
		if(id in list(CYBERPUNK_CORP_RYAZNOV, CYBERPUNK_CORP_STARLIGHT))
			foreign_ids |= id
	for(var/id in foreign_ids)
		var/datum/cyberpunk_corporation/foreign = SScyberpunk_corporations.get_cyberpunk_corporation(id)
		benn.steal_technology_from(foreign, revived ? 8 : 2, activity)
	return TRUE

/mob/living/basic/cyberpunk_corporate_agent/service_drone/dna_sampler
	agent_title = "clinical sampling drone"

/mob/living/basic/cyberpunk_corporate_agent/service_drone/dna_sampler/complete_treatment()
	var/mob/living/carbon/human/patient = target_ref?.resolve()
	if(!istype(patient) || !patient.IsReachableBy(src))
		return FALSE
	if(cyberpunk_collect_benn_dna_sample(patient, "Benn sampling drone: DNA storage"))
		visible_message(span_notice("[src] confirms the clinical scan of [patient]."))
	QDEL_IN(src, 1 SECONDS)
	return TRUE

/proc/cyberpunk_complete_benn_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	cyberpunk_spawn_service_agent(corporation_id, service_id, user, corporation?.get_service_label(service_id))
	switch(service_id)
		if("medical")
			var/heal_amount = corporation?.is_subscribed(user) ? 60 : 35
			user.heal_ordered_damage(heal_amount, list(BRUTE, BURN, TOX, OXY))
			to_chat(user, span_notice("Benn remote medical service completes treatment protocol."))
		if("body")
			var/mob/living/carbon/carbon_user = user
			if(istype(carbon_user) && carbon_user.dna)
				carbon_user.dna.adjust_humanoidity_stabilized_bonus(corporation?.is_subscribed(user) ? 12 : 7)
			user.adjust_stamina_loss(-25)
			to_chat(user, span_notice("Benn body stabilization raises your humanoidity buffer."))
		if("stealth")
			user.adjust_stamina_loss(-45)
			to_chat(user, span_notice("Benn stealth conditioning clears fatigue and dampens your network profile."))
		if("chemistry")
			var/obj/item/storage/box/package = new(get_turf(user))
			package.name = "Benn chemistry kit"
			cyberpunk_prepare_benn_package(package, corporation?.is_subscribed(user))
			if(hascall(package, "set_cyberpunk_manufacturer"))
				call(package, "set_cyberpunk_manufacturer")("Benn")
			if(!user.put_in_hands(package))
				package.forceMove(get_turf(user))
			to_chat(user, span_notice("Benn chemical support delivers a compact chemistry kit."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "bio", 2, 0, "Benn service completed: [service_id]")
	if(ishuman(user) && corporation?.has_edict("benn_dna_storage") && (service_id in list("medical", "body")))
		var/atom/source = corporation.get_nearby_service_source(user)
		if(source && user.stat != DEAD)
			var/mob/living/basic/cyberpunk_corporate_agent/service_drone/dna_sampler/drone = new(get_turf(source), corporation_id, "dna storage", user.real_name)
			drone.target_ref = WEAKREF(user)
			drone.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, user)
			to_chat(user, span_notice("Бэнь направила клинический дрон для анализа. Оставайся рядом."))
	if(iscarbon(user))
		cyberpunk_record_benn_biodata(user, "benn_gene_registry", "Benn service: genetic registry", 2, 1, branded_service = TRUE)
		if(service_id == "medical")
			cyberpunk_record_benn_biodata(user, "benn_self_analysis", "Benn remote treatment", branded_service = TRUE)
	return TRUE
