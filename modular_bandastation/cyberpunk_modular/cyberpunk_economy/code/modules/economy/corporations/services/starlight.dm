//CYBERPUNK CORPORATIONS - Starlight service completion.
/obj/item/flashlight/starlight_beacon
	name = "Starlight Beacon lamp"
	desc = "A compact Starlight courier lamp with route-marker firmware."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 116
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 125

/obj/item/radio/starlight_burst
	name = "Starlight Burst radio"
	desc = "A Starlight-branded radio for short logistics confirmations."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 115
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 150

/obj/item/multitool/starlight_pathfinder
	name = "Starlight Pathfinder multitool"
	desc = "A Starlight routing multitool used by premium courier crews."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 122
	cyberpunk_rarity = "rare"
	cyberpunk_base_price = 260

/obj/item/crowbar/starlight_quickjack
	name = "Starlight Quickjack"
	desc = "A lightweight courier crowbar sold as a route recovery tool."
	cyberpunk_manufacturer = "Starlight"
	cyberpunk_quality = 114
	cyberpunk_rarity = "uncommon"
	cyberpunk_base_price = 120

/proc/cyberpunk_prepare_starlight_package(obj/item/storage/box/package, subscribed = FALSE)
	if(!package)
		return FALSE
	new /obj/item/flashlight/starlight_beacon(package)
	new /obj/item/radio/starlight_burst(package)
	new /obj/item/crowbar/starlight_quickjack(package)
	new /obj/item/stack/sheet/glass(package)
	if(subscribed)
		new /obj/item/multitool/starlight_pathfinder(package)
		new /obj/item/stack/sheet/iron/five(package)
	return TRUE

/proc/cyberpunk_complete_starlight_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	cyberpunk_spawn_service_agent(corporation_id, service_id, user, corporation?.get_service_label(service_id))
	switch(service_id)
		if("delivery")
			var/obj/item/storage/box/package = new(get_turf(user))
			package.name = "Starlight delivery pack"
			cyberpunk_prepare_starlight_package(package, corporation?.is_subscribed(user))
			if(hascall(package, "set_cyberpunk_manufacturer"))
				call(package, "set_cyberpunk_manufacturer")("Starlight")
			if(!user.put_in_hands(package))
				package.forceMove(get_turf(user))
			to_chat(user, span_notice("Starlight drone delivery arrives."))
		if("return")
			var/obj/item/held_item = user.get_active_held_item()
			if(!held_item)
				to_chat(user, span_warning("Starlight return program needs an active held item."))
				return FALSE
			var/return_value = max(1, round(held_item.get_cyberpunk_price(user) * (corporation?.is_subscribed(user) ? 0.6 : 0.4)))
			var/datum/bank_account/user_account = user.get_bank_account()
			user_account?.adjust_money(return_value, "Starlight return program")
			qdel(held_item)
			to_chat(user, span_notice("Starlight return program credits [return_value][MONEY_SYMBOL]."))
		if("transport")
			var/turf/destination = get_step(get_turf(user), user.dir || SOUTH)
			if(destination && !destination.is_blocked_turf(source_atom = user))
				user.forceMove(destination)
			user.adjust_stamina_loss(-20)
			to_chat(user, span_notice("Starlight transport ping shifts your position."))
		if("influence")
			user.adjust_stamina_loss(-35)
			user.add_mood_event("starlight_influence", /datum/mood_event/starlight_influence)
			to_chat(user, span_notice("Starlight influence pulse stabilizes your tempo."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "market", 2, 0, "Starlight service completed: [service_id]")
	return TRUE

/datum/mood_event/starlight_influence
	description = "Starlight's feed is keeping my pace tuned."
	mood_change = 2
	timeout = 3 MINUTES
