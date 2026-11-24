/mob/living
	/// Source-owned biological speed factors. The strongest slowing effect wins.
	var/list/medical_time_factors
	var/medical_death_adjusted_at = 0

/mob/living/proc/medical_time_scale()
	var/factor = 1
	for(var/source in medical_time_factors)
		factor = min(factor, medical_time_factors[source])
	return factor

/datum/status_effect/grouped/medical_stasis
	id = "medical_stasis"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = /atom/movable/screen/alert/status_effect/medical_stasis
	var/time_factor = 0.5

/datum/status_effect/grouped/medical_stasis/on_apply()
	if(!LAZYLEN(owner.medical_time_factors))
		owner.medical_death_adjusted_at = world.time
	LAZYSET(owner.medical_time_factors, REF(src), time_factor)
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	return TRUE

/datum/status_effect/grouped/medical_stasis/tick(seconds_between_ticks)
	if(owner.stat == DEAD)
		owner.timeofdeath += (world.time - owner.medical_death_adjusted_at) * (1 - owner.medical_time_scale())
		owner.station_timestamp_timeofdeath = round_timestamp(wtime = owner.timeofdeath)
	owner.medical_death_adjusted_at = world.time

/datum/status_effect/grouped/medical_stasis/on_remove()
	LAZYREMOVE(owner.medical_time_factors, REF(src))
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	return ..()

/datum/status_effect/grouped/medical_stasis/cryostasis
	id = "medical_cryostasis"
	time_factor = 0.25

/atom/movable/screen/alert/status_effect/medical_stasis
	name = "Стазис"
	desc = "Биологические процессы замедлены. Повреждения и лечение продолжаются."
	icon_state = "stasis"

