// ============================================================================
// Water environment — breath-hold timer.
//
// When a carbon mob enters a water turf without underwater breathing gear,
// they hold their breath. After the status effect's duration elapses, oxy
// loss begins to accumulate.
// ============================================================================

/datum/status_effect/holding_breath
	id = "holding_breath"
	duration = HOLDING_BREATH_DEFAULT_SECONDS SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/holding_breath

/datum/status_effect/holding_breath/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_HOLDING_BREATH, "water_environment")
	return TRUE

/datum/status_effect/holding_breath/on_remove()
	REMOVE_TRAIT(owner, TRAIT_HOLDING_BREATH, "water_environment")
	return ..()

/atom/movable/screen/alert/status_effect/holding_breath
	name = "Holding Breath"
	desc = "You are holding your breath underwater. Surface or use a rebreather before it runs out."
	icon_state = "asleep"

/// Called from the patched breathe() proc when the mob is in water.
/mob/living/carbon/proc/handle_water_breath(seconds_per_tick)
	if(has_underwater_breathing())
		end_water_breath()
		return
	if(HAS_TRAIT(src, TRAIT_HOLDING_BREATH))
		// Status effect is active — still holding breath, no damage yet.
		return
	if(!has_status_effect(/datum/status_effect/holding_breath))
		// Either: just hit the water, or the previous timer expired.
		// First entry → apply. Expired → status effect was removed; start drowning.
		if(!HAS_TRAIT(src, "water_environment_drowning"))
			apply_status_effect(/datum/status_effect/holding_breath)
			ADD_TRAIT(src, "water_environment_drowning", "water_environment")
		else
			losebreath += seconds_per_tick

/mob/living/carbon/proc/has_underwater_breathing()
	if(internal || external)
		return TRUE
	var/obj/item/clothing/mask/M = wear_mask
	if(istype(M) && (M.clothing_flags & BREATHES_UNDERWATER))
		return TRUE
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		var/obj/item/clothing/head/HD = H.head
		if(istype(HD) && (HD.clothing_flags & BREATHES_UNDERWATER))
			return TRUE
		var/obj/item/clothing/suit/S = H.wear_suit
		if(istype(S) && (S.clothing_flags & BREATHES_UNDERWATER))
			return TRUE
	return FALSE

/// Surface — clear the timer.
/mob/living/carbon/proc/end_water_breath()
	if(has_status_effect(/datum/status_effect/holding_breath))
		remove_status_effect(/datum/status_effect/holding_breath)
	REMOVE_TRAIT(src, "water_environment_drowning", "water_environment")
