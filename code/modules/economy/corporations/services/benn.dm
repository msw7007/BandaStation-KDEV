//CYBERPUNK CORPORATIONS - Benn service completion.
/proc/cyberpunk_complete_benn_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
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
			to_chat(user, span_notice("Benn body stabilization raises your genetic stability buffer."))
		if("stealth")
			user.adjust_stamina_loss(-45)
			to_chat(user, span_notice("Benn stealth conditioning clears fatigue and dampens your network profile."))
		if("chemistry")
			var/obj/item/storage/box/package = new(get_turf(user))
			package.name = "Benn chemistry kit"
			if(hascall(package, "set_cyberpunk_manufacturer"))
				call(package, "set_cyberpunk_manufacturer")("Benn")
			if(!user.put_in_hands(package))
				package.forceMove(get_turf(user))
			to_chat(user, span_notice("Benn chemical support delivers a compact chemistry kit."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "bio", 2, 0, "Benn service completed: [service_id]")
	return TRUE
