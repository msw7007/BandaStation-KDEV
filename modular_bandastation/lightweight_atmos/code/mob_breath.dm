/mob/living/carbon/proc/get_breath_filter_tags()
	var/list/tags = list()

	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		tags |= GAS_FILTER_ANY
		return tags

	if(internal || external)
		tags |= GAS_FILTER_ANY
		return tags

	var/obj/item/clothing/mask/M = wear_mask
	if(istype(M))
		var/list/mask_tags = M.get_filter_tags()
		if(length(mask_tags))
			tags |= mask_tags

	return tags

/mob/living/carbon/proc/apply_active_gas_clouds(seconds_per_tick)
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/has_clouds = FALSE
	for(var/obj/effect/gas_cloud/cloud in T)
		has_clouds = TRUE
		break
	if(!has_clouds)
		return
	var/list/blocked = get_breath_filter_tags()
	for(var/obj/effect/gas_cloud/cloud in T)
		if(QDELETED(cloud) || !cloud.effect)
			continue
		if(cloud.effect.is_filtered_by(blocked))
			continue
		cloud.effect.on_breathe(src, cloud.amount, seconds_per_tick)

/mob/living/carbon/proc/breathe_from_area(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_NOBREATH) || HAS_TRAIT(src, TRAIT_GODMODE))
		return TRUE
	if(internal || external)
		return TRUE
	var/area/A = get_area(src)
	if(!A)
		return TRUE
	if(is_vacuum_turf(get_turf(src)))
		return FALSE
	if(A.is_outdoor_air())
		A.consume_oxygen(AREA_AIR_O2_PER_BREATH * seconds_per_tick)
		return TRUE
	var/needed = AREA_AIR_O2_PER_BREATH * seconds_per_tick
	A.consume_oxygen(needed)
	A.release_co2(AREA_AIR_CO2_PER_BREATH * seconds_per_tick)
	var/quality = A.get_air_quality()
	switch(quality)
		if(AREA_AIR_QUALITY_GOOD)
			clear_alert(ALERT_NOT_ENOUGH_OXYGEN)
			return TRUE
		if(AREA_AIR_QUALITY_TIGHT)
			if(prob(2 * seconds_per_tick))
				emote("cough")
			return TRUE
		if(AREA_AIR_QUALITY_SUFFOCATING)
			adjust_oxy_loss(1 * seconds_per_tick)
			throw_alert(ALERT_NOT_ENOUGH_OXYGEN, /atom/movable/screen/alert/not_enough_oxy)
			if(prob(20 * seconds_per_tick))
				emote("gasp")
			return FALSE
		if(AREA_AIR_QUALITY_LETHAL)
			adjust_oxy_loss(3 * seconds_per_tick)
			losebreath += 0.5 * seconds_per_tick
			throw_alert(ALERT_NOT_ENOUGH_OXYGEN, /atom/movable/screen/alert/not_enough_oxy)
			if(prob(40 * seconds_per_tick))
				emote("gasp")
			return FALSE
		if(AREA_AIR_QUALITY_TOXIC)
			adjust_tox_loss(0.5 * seconds_per_tick)
			adjust_oxy_loss(0.5 * seconds_per_tick)
			if(prob(20 * seconds_per_tick))
				emote("cough")
			return FALSE
	return TRUE
