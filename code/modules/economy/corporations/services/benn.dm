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
	return TRUE
