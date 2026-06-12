/// This divisor controls how fast body temperature changes to match the environment
#define BODYTEMP_DIVISOR 16

/**
 * Handles the biological and general over-time processes of the mob.
 *
 *
 * Arguments:
 * - seconds_per_tick: The amount of time that has elapsed since this last fired.
 * - times_fired: The number of times SSmobs has fired
 */
/mob/living/proc/Life(seconds_per_tick = SSMOBS_DT)
	set waitfor = FALSE
	SHOULD_NOT_SLEEP(TRUE)

	var/signal_result = SEND_SIGNAL(src, COMSIG_LIVING_LIFE, seconds_per_tick)

	if(signal_result & COMPONENT_LIVING_CANCEL_LIFE_PROCESSING) // mmm less work
		return

	if (client)
		var/turf/T = get_turf(src)
		if(!T)
			move_to_error_room()
			var/msg = " was found to have no .loc with an attached client, if the cause is unknown it would be wise to ask how this was accomplished."
			message_admins(ADMIN_LOOKUPFLW(src) + msg)
			send2tgs_adminless_only("Mob", key_name_and_tag(src) + msg, R_ADMIN)
			src.log_message("was found to have no .loc with an attached client.", LOG_GAME)

		// This is a temporary error tracker to make sure we've caught everything
		else if (registered_z != T.z)
#ifdef TESTING
			message_admins("[ADMIN_LOOKUPFLW(src)] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z]. If you could ask them how that happened and notify coderbus, it would be appreciated.")
#endif
			log_game("Z-TRACKING: [src] has somehow ended up in Z-level [T.z] despite being registered in Z-level [registered_z].")
			update_z(T.z)
	else if (registered_z)
		log_game("Z-TRACKING: [src] of type [src.type] has a Z-registration despite not having a client.")
		update_z(null)

	if(isnull(loc) || HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return

	if(!HAS_TRAIT(src, TRAIT_STASIS))
		if(stat != DEAD)
			//Mutations and radiation
			handle_mutations(seconds_per_tick)
			//Breathing, if applicable
			handle_breathing(seconds_per_tick)
			handle_body_state(seconds_per_tick)
			handle_ssd(seconds_per_tick) // BANDASTATION ADD - SSD INDICATOR

		handle_diseases(seconds_per_tick) // DEAD check is in the proc itself; we want it to spread even if the mob is dead, but to handle its disease-y properties only if you're not.

		if (QDELETED(src)) // Diseases can qdel the mob via transformations
			return

		// Handle temperature/pressure differences between body and environment
		var/datum/gas_mixture/environment = lightweight_atmos_scan_gasmix(src)
		if(environment)
			handle_environment(environment, seconds_per_tick)

		handle_gravity(seconds_per_tick)

	if(living_flags & QUEUE_NUTRITION_UPDATE)
		update_nutrition()
		living_flags &= ~QUEUE_NUTRITION_UPDATE

	if (living_flags & BLOOD_UPDATE_QUEUED)
		update_blood_effects()

	if(stat != DEAD)
		return TRUE

/mob/living/proc/handle_breathing(seconds_per_tick)
	SEND_SIGNAL(src, COMSIG_LIVING_HANDLE_BREATHING, seconds_per_tick)
	return

/mob/living/proc/handle_mutations(seconds_per_tick)
	return

/mob/living/proc/handle_diseases(seconds_per_tick)
	return

/mob/living/proc/handle_body_state(seconds_per_tick)
	drain_needs(seconds_per_tick)
	recover_stamina(seconds_per_tick)
	recover_energy_pool(seconds_per_tick)
	recover_tireness(seconds_per_tick)
	process_equipment_style(seconds_per_tick)
	process_chromity_overheat(seconds_per_tick)
	process_mood_state(seconds_per_tick)
	process_cyberpunk_status_effects(seconds_per_tick)
	apply_body_state_effects()

/mob/living/get_status_tab_items()
	. = ..()
	. += ""
	. += "Body State"
	. += "Stamina: [round(stamina, 0.1)]/[round(max_stamina, 0.1)]"
	. += "Energy Pool: [round(energy_pool, 0.1)]/[round(max_energy_pool, 0.1)]"
	. += "Satiation: [round(satiety, 0.1)]/[MAX_SATIETY]"
	. += "Hydration: [round(hydration, 0.1)]/[MAX_SATIETY]"
	. += "Tireness: [round(tireness, 0.1)]/[MAX_SATIETY]"
	. += "Chromity Overheat: [round(chromity_overheat, 0.1)]/[round(get_effective_chromity(), 0.1)]"
	. += "Chromity Floor: [round(get_chromity_overheat_floor(), 0.1)]"
	if(iscarbon(src))
		var/mob/living/carbon/carbon_source = src
		if(carbon_source.dna)
			. += "Genetic Stability: [round(carbon_source.dna.get_effective_genetic_stability(), 0.1)]/[HUMANOIDITY_DEFAULT]"
	. += "Style: [round(style, 0.1)]/15"
	. += "Mood: [round(mood, 0.1)]/20"
	if(length(cyberpunk_status_effects))
		. += "Cyberpunk Status"
		for(var/effect_id in cyberpunk_status_effects)
			var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
			if(!effect)
				continue
			var/time_left = effect.expires_at ? max(0, round((effect.expires_at - world.time) / 10, 0.1)) : 0
			. += "[effect.name]: [effect.effect_kind][time_left ? " ([time_left]s)" : ""]"
	. += "Corp Align: [corp_align || "None"]"
	. += "Memory Holder: [length(memory_holder)] entries"
	if(mind)
		. += ""
		. += "Character Attributes"
		for(var/attribute_id in ATTRIBUTE_ALL)
			var/datum/attribute/attribute = mind.get_attribute(attribute_id)
			if(attribute)
				. += "[attribute.name]: [attribute.value]/[ATTRIBUTE_MAXIMUM][attribute.super_mode ? " (Super)" : ""]"
		. += "Unconverted General XP: [round(mind.unconverted_general_experience, 0.1)]/[ATTRIBUTE_LEVEL_POINT_EXPERIENCE]"
		. += "Level Points: [mind.level_points]"
		. += "Skill Points: [mind.skill_points]"

/mob/living/proc/drain_needs(seconds_per_tick)
	var/survival_drain_multiplier = get_cyberpunk_survival_need_drain_multiplier()
	if(!HAS_TRAIT(src, TRAIT_NOHUNGER))
		satiation_drain_accumulator += seconds_per_tick * survival_drain_multiplier
		while(satiation_drain_accumulator >= 20)
			satiation_drain_accumulator -= 20
			adjust_satiation(-1)
	else
		satiation_drain_accumulator = 0

	hydration_drain_accumulator += seconds_per_tick * survival_drain_multiplier
	while(hydration_drain_accumulator >= 10)
		hydration_drain_accumulator -= 10
		adjust_hydration(-1)

	tireness_drain_accumulator += seconds_per_tick * survival_drain_multiplier
	while(tireness_drain_accumulator >= 15)
		tireness_drain_accumulator -= 15
		adjust_tireness(-1)

	if(has_sleep_deprivation())
		sleep_deprivation_energy_drain_accumulator += seconds_per_tick
		while(sleep_deprivation_energy_drain_accumulator >= 60)
			sleep_deprivation_energy_drain_accumulator -= 60
			adjust_energy_pool(-2)
	else
		sleep_deprivation_energy_drain_accumulator = 0

	if(tireness <= 0 && !combat_mode && world.time >= tireness_sleep_grace_until && !IsSleeping() && !IsUnconscious())
		SetSleeping(30 SECONDS)

/mob/living/proc/recover_stamina(seconds_per_tick)
	if(stamina >= max_stamina || is_exhausted_by_needs())
		stamina_regen_accumulator = 0
		return
	if(world.time < last_stamina_spend + get_cyberpunk_stamina_regen_delay())
		stamina_regen_accumulator = 0
		return

	stamina_regen_accumulator += seconds_per_tick
	while(stamina_regen_accumulator >= STAMINA_REGEN_INTERVAL)
		stamina_regen_accumulator -= STAMINA_REGEN_INTERVAL
		var/recovery = STAMINA_REGEN_AMOUNT
		recovery *= get_cyberpunk_endurance_stamina_recovery_multiplier()
		recovery *= get_cyberpunk_medical_stamina_recovery_multiplier()
		if(buckled || resting)
			recovery += 5
		if(body_position == LYING_DOWN && (IsSleeping() || IsUnconscious()))
			recovery += 10
		if(stamina < max_stamina && energy_pool >= STAMINA_ENERGY_RESERVE_COST)
			adjust_energy_pool(-STAMINA_ENERGY_RESERVE_COST)
			recovery += get_cyberpunk_stamina_energy_reserve_recovery()
		adjust_stamina(recovery, FALSE)

/mob/living/proc/recover_energy_pool(seconds_per_tick)
	if(energy_pool >= max_energy_pool || has_sleepiness() || has_strong_hunger() || has_strong_thirst())
		energy_regen_accumulator = 0
		return

	var/recovery = get_energy_pool_recovery()
	if(recovery <= 0)
		energy_regen_accumulator = 0
		return

	var/recovery_interval = wall_hugging ? ENERGY_POOL_WALL_HUG_INTERVAL : ENERGY_POOL_RECOVERY_INTERVAL
	energy_regen_accumulator += seconds_per_tick
	while(energy_regen_accumulator >= recovery_interval)
		energy_regen_accumulator -= recovery_interval
		adjust_energy_pool(recovery)

/mob/living/proc/recover_tireness(seconds_per_tick)
	if(tireness >= MAX_SATIETY || (!IsSleeping() && !IsUnconscious()))
		tireness_recovery_accumulator = 0
		return
	if(body_position != LYING_DOWN && !(istype(buckled, /obj/structure/chair) && get_cyberpunk_sleep_survival_comfort_multiplier() > 0))
		tireness_recovery_accumulator = 0
		return

	tireness_recovery_accumulator += seconds_per_tick
	while(tireness_recovery_accumulator >= 5)
		tireness_recovery_accumulator -= 5
		var/recovery = 10
		recovery += get_cyberpunk_sleep_comfort_recovery_bonus()
		if(!has_hunger() && !has_overeating())
			recovery += 20
		if(!has_thirst() && !has_overdrinking())
			recovery += 10
		recovery *= get_cyberpunk_survival_recovery_multiplier()
		adjust_tireness(recovery)

/mob/living/proc/process_mood_state(seconds_per_tick)
	sync_mood_from_moodlets()
	mood = clamp(mood, -30, 20)
	if(mood <= -30)
		time_at_min_mood += seconds_per_tick
		if(time_at_min_mood >= 10 MINUTES && world.time >= last_control_loss + 30 SECONDS)
			trigger_hysteria()

	if(is_comfortably_sleeping_for_experience())
		mind?.convert_rest_experience()

	if(mood <= CYBERPSYCHOSIS_MIN_MOOD && chromity_overheat > get_effective_chromity() * CYBERPSYCHOSIS_OVERHEAT_RATIO)
		trigger_cyberpsychosis()

/mob/living/proc/process_chromity_overheat(seconds_per_tick)
	if(iscarbon(src))
		var/mob/living/carbon/carbon_owner = src
		carbon_owner.dna?.process_humanoidity_stabilization(seconds_per_tick)

	var/overheat_floor = get_chromity_overheat_floor()
	if(chromity_overheat > overheat_floor)
		chromity_overheat = max(overheat_floor, chromity_overheat - CHROMITY_OVERHEAT_DECAY * seconds_per_tick)
	else if(chromity_overheat < overheat_floor)
		chromity_overheat = overheat_floor

	if(bodytemperature < T0C)
		adjust_chromity_overheat(-seconds_per_tick, respect_floor = TRUE)

	var/effective_chromity = get_effective_chromity()
	if(chromity_overheat > effective_chromity)
		apply_chromity_overheat_damage(chromity_overheat - effective_chromity)

/mob/living/proc/get_chromity_overheat_floor()
	var/floor_value = 0
	if(!iscarbon(src))
		return floor_value
	var/mob/living/carbon/carbon_owner = src
	for(var/obj/item/organ/organ as anything in carbon_owner.organs)
		floor_value += organ.get_chromity_overheat_floor()
	floor_value *= max(0, 1 + get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 1) * 0.01)
	return floor_value

/mob/living/proc/get_effective_chromity()
	var/effective_chromity = chromity
	effective_chromity *= 1 + get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 2) * 0.01
	effective_chromity += max(0, get_attribute_value(ATTRIBUTE_SPIRIT) - ATTRIBUTE_DEFAULT) * 2
	if(iscarbon(src))
		var/mob/living/carbon/carbon_owner = src
		if(carbon_owner.dna)
			effective_chromity *= carbon_owner.dna.get_humanoidity_chromity_multiplier()
	effective_chromity -= get_neural_ice_chromity_penalty()
	return max(0, effective_chromity)

/mob/living/proc/adjust_chromity_overheat(amount, respect_floor = TRUE)
	var/old_value = chromity_overheat
	var/minimum = respect_floor ? get_chromity_overheat_floor() : 0
	chromity_overheat = max(minimum, chromity_overheat + amount)
	return chromity_overheat - old_value

/mob/living/proc/set_chromity_overheat(amount, respect_floor = TRUE)
	var/old_value = chromity_overheat
	var/minimum = respect_floor ? get_chromity_overheat_floor() : 0
	chromity_overheat = max(minimum, amount)
	return chromity_overheat - old_value

/mob/living/proc/apply_chromity_overheat_damage(amount)
	if(amount <= 0)
		return
	if(!has_neural_implant())
		return
	switch(rand(1, 100))
		if(1 to 40)
			var/overload_pain = get_cyberpunk_chromity_overload_pain(amount)
			if(overload_pain > 0)
				var/obj/item/organ/brain_for_pain = get_organ_slot(ORGAN_SLOT_BRAIN)
				brain_for_pain?.add_organ_pain(overload_pain)
		if(41 to 55)
			var/obj/item/organ/implant = pick_working_chrome_implant()
			implant?.disable_implant(IMPLANT_OVERHEAT_SHUTDOWN_TIME, "overheat")
		if(56 to 60)
			var/obj/item/organ/implant = pick_working_chrome_implant()
			implant?.on_implant_erroneous_activation()
		if(61 to 100)
			var/damage_cap = get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 3)
			if(damage_cap > 0)
				amount = min(amount, damage_cap)
			var/master_reduction = get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 6, "value_2")
			if(master_reduction > 0)
				amount *= max(0, 1 - master_reduction * 0.01)
			if(amount > 0)
				adjust_organ_loss(ORGAN_SLOT_BRAIN, amount)

/mob/living/proc/trigger_cyberpsychosis()
	if(world.time < last_cyberpsychosis_time + CYBERPSYCHOSIS_COOLDOWN)
		return FALSE
	last_cyberpsychosis_time = world.time
	visible_message(span_warning("[src] spasms under chrome overload!"), span_userdanger("Your neural interface burns with static. You lose your grip on reality."))
	apply_status_effect(/datum/status_effect/hallucination, 2 MINUTES)
	adjust_jitter(30 SECONDS)
	adjust_confusion_up_to(20 SECONDS, 40 SECONDS)
	Stun(5 SECONDS)
	return TRUE

/mob/living/proc/process_equipment_style(seconds_per_tick)
	style_update_accumulator += seconds_per_tick
	if(style_update_accumulator < BODY_STYLE_UPDATE_INTERVAL)
		return
	style_update_accumulator = 0
	recalculate_equipment_style()

/mob/living/proc/recalculate_equipment_style()
	var/style_score = 0
	for(var/obj/item/item as anything in get_equipped_items(INCLUDE_ACCESSORIES|INCLUDE_ABSTRACT))
		if(isnull(item))
			continue
		if(!(item.slot_flags & (ITEM_SLOT_ICLOTHING|ITEM_SLOT_OCLOTHING|ITEM_SLOT_HEAD|ITEM_SLOT_MASK|ITEM_SLOT_NECK|ITEM_SLOT_FEET|ITEM_SLOT_GLOVES|ITEM_SLOT_EYES|ITEM_SLOT_SHOULDERS|ITEM_SLOT_FINGER|ITEM_SLOT_BRACERS|ITEM_SLOT_PANTS|ITEM_SLOT_CHEST|ITEM_SLOT_UNDERSHIRT|ITEM_SLOT_UNDERWEAR|ITEM_SLOT_TIGHTS)))
			continue
		var/item_score = 0
		var/lower_name = lowertext(item.name)
		var/lower_desc = lowertext(item.desc)
		if(findtext(lower_name, "style") || findtext(lower_name, "fashion") || findtext(lower_desc, "stylish") || findtext(lower_desc, "fashion"))
			item_score += 2
		if(findtext(lower_name, "costume") || findtext(lower_name, "dress") || findtext(lower_name, "suit") || findtext(lower_name, "jacket"))
			item_score += 1
		if(findtext(lower_name, "clown") || findtext(lower_name, "mime") || findtext(lower_name, "fedora") || findtext(lower_name, "hat"))
			item_score += 1
		item_score += clamp(round((item.custom_price || 0) / max(PAYCHECK_CREW, 1)), 0, 3)
		item_score -= max(0, item.w_class - WEIGHT_CLASS_NORMAL)
		if(istype(item, /obj/item/clothing/suit/armor) || istype(item, /obj/item/clothing/head/helmet))
			item_score -= 1
		style_score += item_score
	style = clamp(style_score, -15, 15)
	return style

/mob/living/proc/get_working_chrome_implants()
	. = list()
	if(!iscarbon(src))
		return
	var/mob/living/carbon/carbon_owner = src
	for(var/obj/item/organ/organ as anything in carbon_owner.organs)
		if(!organ.is_implant_functional())
			continue
		if(!organ.chromity_overheat && !organ.chromity_active_overheat_floor && !length(organ.actions))
			continue
		. += organ

/mob/living/proc/pick_working_chrome_implant()
	var/list/implants = get_working_chrome_implants()
	if(!length(implants))
		return null
	return pick(implants)

/mob/living/proc/retune_implants_from_electricity(power = 0)
	var/retuned = FALSE
	if(!iscarbon(src))
		return retuned
	var/mob/living/carbon/carbon_owner = src
	for(var/obj/item/organ/organ as anything in carbon_owner.organs)
		if(!organ.is_implant())
			continue
		if(!organ.is_implant_disabled())
			continue
		retuned |= organ.retune_implant()
	return retuned

/mob/living/proc/sync_mood_from_moodlets()
	if(!QDELETED(mob_mood))
		mood = clamp(mob_mood.mood, -30, 20)
	return mood

/mob/living/proc/is_comfortably_sleeping_for_experience()
	if(!IsSleeping() && !IsUnconscious())
		return FALSE
	if(istype(buckled, /obj/structure/bed))
		return (locate(/obj/item/pillow) in loc) && (locate(/obj/item/bedsheet) in loc)
	if(istype(buckled, /obj/structure/chair))
		return get_cyberpunk_sleep_survival_comfort_multiplier() > 0
	if(body_position != LYING_DOWN)
		return FALSE
	return get_cyberpunk_sleep_survival_comfort_multiplier() > 0

/mob/living/proc/get_cyberpunk_sleep_comfort_recovery_bonus()
	if(istype(buckled, /obj/structure/bed))
		var/recovery = 10
		if(locate(/obj/item/pillow) in loc)
			recovery += 20
		if(locate(/obj/item/bedsheet) in loc)
			recovery += 10
		return recovery
	return round(40 * get_cyberpunk_sleep_survival_comfort_multiplier())

/mob/living/proc/get_cyberpunk_sleep_survival_comfort_multiplier()
	var/perk_bonus = get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 4)
	if(perk_bonus <= 0)
		return 0
	if(istype(buckled, /obj/structure/chair))
		return perk_bonus * 0.01
	if(!buckled && body_position == LYING_DOWN)
		return perk_bonus * 0.01
	return 0

/mob/living/proc/get_cyberpunk_sleep_prepare_time()
	var/prepare_time = 1 MINUTES
	if(istype(buckled, /obj/structure/bed))
		prepare_time *= 0.8
	if(locate(/obj/item/bedsheet) in loc)
		prepare_time *= 0.8
	if(locate(/obj/item/pillow) in loc)
		prepare_time *= 0.8
	var/survival_bonus = get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 5)
	if(survival_bonus > 0)
		prepare_time *= max(0.1, 1 - (survival_bonus * 0.01))
	return max(1 SECONDS, round(prepare_time))

/datum/cyberpunk_status_effect
	var/id = "status"
	var/name = "Status"
	var/desc = ""
	var/effect_kind = "neutral"
	var/duration = 0
	var/expires_at = 0
	var/power = 1
	var/source
	var/mob/living/owner
	var/list/attribute_modifiers
	var/list/skill_modifiers
	var/check_modifier = 0
	var/action_speed_modifier = 0
	var/move_speed_modifier = 0
	var/experience_multiplier = 1
	var/shareable = TRUE
	var/unique_effect = null

/datum/cyberpunk_status_effect/New()
	attribute_modifiers = list()
	skill_modifiers = list()

/datum/cyberpunk_status_effect/Destroy(force)
	owner = null
	attribute_modifiers = null
	skill_modifiers = null
	return ..()

/datum/cyberpunk_status_effect/proc/on_apply(mob/living/new_owner)
	owner = new_owner
	if(duration > 0)
		expires_at = world.time + duration

/datum/cyberpunk_status_effect/proc/on_remove()
	return

/datum/cyberpunk_status_effect/proc/refresh(new_duration, new_power = 1, new_source = null)
	if(new_duration > 0)
		duration = max(duration, new_duration)
		expires_at = max(expires_at, world.time + new_duration)
	power = max(power, new_power)
	if(new_source)
		source = new_source

/datum/cyberpunk_status_effect/proc/tick(seconds_per_tick)
	return

/datum/cyberpunk_status_effect/proc/get_remaining_duration()
	if(!expires_at)
		return duration
	return max(0, expires_at - world.time)

/datum/cyberpunk_status_effect/proc/get_attribute_modifier(attribute_id)
	return (attribute_modifiers?[attribute_id] || 0) * power

/datum/cyberpunk_status_effect/proc/get_skill_modifier(skill)
	return (skill_modifiers?[skill] || 0) * power

/datum/cyberpunk_status_effect/need
	effect_kind = "debuff"
	shareable = FALSE
	unique_effect = "need"

/datum/cyberpunk_status_effect/need/hunger
	id = "hunger"
	name = "Hunger"
	desc = "Low satiation is pulling down the body state."

/datum/cyberpunk_status_effect/need/thirst
	id = "thirst"
	name = "Thirst"
	desc = "Low hydration is pulling down the body state."

/datum/cyberpunk_status_effect/need/tiredness
	id = "tiredness"
	name = "Tiredness"
	desc = "Fatigue is pulling down the body state."

/datum/cyberpunk_status_effect/radiation
	id = "radiation"
	name = "Radiation"
	desc = "Ionizing contamination disrupts focus and body response."
	effect_kind = "debuff"
	check_modifier = -5
	action_speed_modifier = 0.05
	move_speed_modifier = 0.03
	shareable = FALSE
	unique_effect = "radiation"

/datum/cyberpunk_status_effect/inspiration
	id = "inspiration"
	name = "Inspiration"
	desc = "A positive cohort effect."
	effect_kind = "buff"

/datum/cyberpunk_status_effect/analysis_insight
	id = "analysis_insight"
	name = "Analysis Insight"
	desc = "Recent diagnostics sharpen technical checks."
	effect_kind = "buff"
	check_modifier = 5
	experience_multiplier = 1.05

/datum/cyberpunk_status_effect/music_cohort
	id = "music_cohort"
	name = "Cohort Rhythm"
	desc = "A live performance keeps the cohort in sync."
	effect_kind = "buff"
	check_modifier = 1
	action_speed_modifier = -0.01
	move_speed_modifier = -0.005
	experience_multiplier = 1.01
	shareable = FALSE

/datum/cyberpunk_status_effect/music_discord
	id = "music_discord"
	name = "Discordant Rhythm"
	desc = "A hostile performance breaks your rhythm."
	effect_kind = "debuff"
	check_modifier = -1
	action_speed_modifier = 0.01
	move_speed_modifier = 0.005
	shareable = FALSE

/mob/living/proc/apply_cyberpunk_status_effect(effect_type, duration = 0, power = 1, source = null, share_cohort = TRUE)
	if(!ispath(effect_type, /datum/cyberpunk_status_effect))
		return null
	var/datum/cyberpunk_status_effect/new_effect = new effect_type()
	new_effect.duration = duration
	new_effect.power = max(0.1, power)
	new_effect.source = source
	LAZYINITLIST(cyberpunk_status_effects)
	var/datum/cyberpunk_status_effect/existing_effect = cyberpunk_status_effects[new_effect.id]
	if(existing_effect)
		existing_effect.refresh(duration, power, source)
		qdel(new_effect)
		return existing_effect
	cyberpunk_status_effects[new_effect.id] = new_effect
	new_effect.on_apply(src)
	apply_body_state_effects()
	if(share_cohort && new_effect.shareable && new_effect.effect_kind == "buff")
		cyberpunk_cohort?.share_status_effect(src, new_effect)
	return new_effect

/mob/living/proc/remove_cyberpunk_status_effect(effect_id)
	if(!length(cyberpunk_status_effects))
		return FALSE
	var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
	if(!effect)
		return FALSE
	cyberpunk_status_effects -= effect_id
	effect.on_remove()
	qdel(effect)
	apply_body_state_effects()
	return TRUE

/mob/living/proc/has_cyberpunk_status_effect(effect_id)
	return !!cyberpunk_status_effects?[effect_id]

/mob/living/proc/process_cyberpunk_status_effects(seconds_per_tick)
	sync_cyberpunk_need_status_effects()
	if(!length(cyberpunk_status_effects))
		return
	for(var/effect_id in cyberpunk_status_effects.Copy())
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		if(!effect)
			cyberpunk_status_effects -= effect_id
			continue
		if(effect.expires_at && world.time >= effect.expires_at)
			remove_cyberpunk_status_effect(effect_id)
			continue
		effect.tick(seconds_per_tick)

/mob/living/proc/sync_cyberpunk_need_status_effects()
	if(has_hunger())
		apply_cyberpunk_status_effect(/datum/cyberpunk_status_effect/need/hunger, 5 SECONDS, has_starvation_exhaustion() ? 3 : (has_strong_hunger() ? 2 : 1), src, FALSE)
	else
		remove_cyberpunk_status_effect("hunger")

	if(has_thirst())
		apply_cyberpunk_status_effect(/datum/cyberpunk_status_effect/need/thirst, 5 SECONDS, has_dehydration() ? 3 : (has_strong_thirst() ? 2 : 1), src, FALSE)
	else
		remove_cyberpunk_status_effect("thirst")

	if(has_sleepiness())
		apply_cyberpunk_status_effect(/datum/cyberpunk_status_effect/need/tiredness, 5 SECONDS, has_sleep_deprivation() ? 3 : 1, src, FALSE)
	else
		remove_cyberpunk_status_effect("tiredness")

/mob/living/proc/get_cyberpunk_status_attribute_modifier(attribute_id)
	if(!length(cyberpunk_status_effects))
		return 0
	var/total = 0
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		total += effect?.get_attribute_modifier(attribute_id) || 0
	return total

/mob/living/proc/get_cyberpunk_status_skill_modifier(skill)
	if(!length(cyberpunk_status_effects))
		return 0
	var/total = 0
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		total += effect?.get_skill_modifier(skill) || 0
	return total

/mob/living/proc/get_cyberpunk_status_check_modifier()
	if(!length(cyberpunk_status_effects))
		return 0
	var/total = 0
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		total += (effect?.check_modifier || 0) * (effect?.power || 1)
	return total

/mob/living/proc/get_cyberpunk_status_action_slowdown()
	if(!length(cyberpunk_status_effects))
		return 0
	var/total = 0
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		total += (effect?.action_speed_modifier || 0) * (effect?.power || 1)
	return total

/mob/living/proc/get_cyberpunk_status_move_slowdown()
	if(!length(cyberpunk_status_effects))
		return 0
	var/total = 0
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		total += (effect?.move_speed_modifier || 0) * (effect?.power || 1)
	return total

/mob/living/proc/get_cyberpunk_medical_action_slowdown()
	var/slowdown = 0
	if(stat == SOFT_CRIT)
		slowdown = max(slowdown, 0.7)
	var/mob/living/carbon/carbon_mob = iscarbon(src) ? src : null
	if(!carbon_mob)
		return slowdown
	for(var/obj/item/bodypart/limb as anything in carbon_mob.get_bodyparts())
		if(limb.cold_trauma >= TRAUMA_MINOR)
			slowdown = max(slowdown, 1)
	return slowdown

/mob/living/proc/get_cyberpunk_medical_stamina_cost_multiplier(source)
	var/mob/living/carbon/carbon_mob = iscarbon(src) ? src : null
	if(!carbon_mob)
		return 1
	for(var/obj/item/bodypart/limb as anything in carbon_mob.get_bodyparts())
		if(limb.cold_trauma >= TRAUMA_MINOR)
			return 2
	return 1

/mob/living/proc/get_cyberpunk_medical_stamina_recovery_multiplier()
	var/mob/living/carbon/carbon_mob = iscarbon(src) ? src : null
	if(!carbon_mob)
		return 1
	var/obj/item/bodypart/chest = carbon_mob.get_bodypart(BODY_ZONE_CHEST)
	if(!chest || chest.blunt_trauma < TRAUMA_MINOR)
		return 1
	return chest.blunt_trauma == TRAUMA_CRITICAL ? 0.5 : 0.75

/mob/living/proc/is_cyberpunk_sprint_blocked_by_cold_trauma()
	var/mob/living/carbon/carbon_mob = iscarbon(src) ? src : null
	if(!carbon_mob)
		return FALSE
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/obj/item/bodypart/leg = carbon_mob.get_bodypart(zone)
		if(leg?.cold_trauma == TRAUMA_CRITICAL)
			return TRUE
	return FALSE

/mob/living/proc/is_cyberpunk_jump_blocked_by_cold_trauma()
	return is_cyberpunk_sprint_blocked_by_cold_trauma()

/mob/living/proc/get_cyberpunk_status_experience_multiplier()
	if(!length(cyberpunk_status_effects))
		return 1
	var/multiplier = 1
	for(var/effect_id in cyberpunk_status_effects)
		var/datum/cyberpunk_status_effect/effect = cyberpunk_status_effects[effect_id]
		if(!effect || effect.experience_multiplier == 1)
			continue
		multiplier *= 1 + ((effect.experience_multiplier - 1) * effect.power)
	return multiplier

/mob/living/proc/apply_body_state_effects()
	var/stamina_ratio = max_stamina ? stamina / max_stamina : 0
	var/move_slowdown = 0
	var/action_slowdown = 0

	if(stamina <= 0)
		move_slowdown = max(move_slowdown, 0.2)
		action_slowdown = max(action_slowdown, 0.2)
	else if(stamina_ratio <= 0.1)
		move_slowdown = max(move_slowdown, 0.2)
		action_slowdown = max(action_slowdown, 0.2)
	else if(stamina_ratio <= 0.5)
		move_slowdown = max(move_slowdown, 0.1)
		action_slowdown = max(action_slowdown, 0.1)

	move_slowdown = max(move_slowdown, get_cyberpunk_needs_move_slowdown())
	action_slowdown = max(action_slowdown, get_cyberpunk_needs_action_slowdown())
	action_slowdown = max(action_slowdown, get_cyberpunk_medical_action_slowdown())
	move_slowdown += get_cyberpunk_status_move_slowdown()
	action_slowdown += get_cyberpunk_status_action_slowdown()
	if(tireness > 450)
		move_slowdown -= 0.1
	move_slowdown -= get_cyberpunk_acrobatics_move_bonus()
	move_slowdown -= get_cyberpunk_heavy_weapon_move_bonus()
	if(stealth_mode)
		move_slowdown -= get_cyberpunk_skill_perk_bonus(SKILL_STEALTH, 4) * 0.01
	var/athletics_sprint_threshold = get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 4, "value_2")
	if(move_intent == MOVE_INTENT_RUN && athletics_sprint_threshold > 0 && stamina_ratio >= athletics_sprint_threshold * 0.01)
		move_slowdown -= get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 4, "value_1") * 0.01

	if(mood > 0)
		action_slowdown -= 0.1 * (mood / 20)
	else if(mood < 0)
		action_slowdown += (0.5 * (abs(mood) / 30)) * get_cyberpunk_endurance_negative_mood_multiplier()

	if(move_slowdown)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/body_state, multiplicative_slowdown = move_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/body_state)

	if(action_slowdown)
		add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/body_state, multiplicative_slowdown = action_slowdown)
	else
		remove_actionspeed_modifier(/datum/actionspeed_modifier/body_state)

	if(stamina <= 0 && energy_pool <= 0)
		Stun(10 SECONDS)
		ADD_TRAIT(src, TRAIT_IMMOBILIZED, BODY_STATE_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, BODY_STATE_TRAIT)

/mob/living/proc/spend_stamina(amount, source, allow_negative = FALSE)
	if(amount <= 0)
		return TRUE
	amount *= get_cyberpunk_stamina_cost_multiplier(source)
	amount *= get_cyberpunk_medical_stamina_cost_multiplier(source)
	amount *= get_cyberpunk_needs_stamina_cost_multiplier(source)
	amount *= get_cyberpunk_skill_stamina_cost_multiplier(source)
	if(!allow_negative && stamina < amount)
		return FALSE
	var/spent = -adjust_stamina(-amount, TRUE)
	if(spent > 0)
		reward_stamina_spend_experience(spent, source)
	return TRUE

/mob/living/proc/adjust_stamina(amount, counts_as_spend = FALSE)
	var/old_value = stamina
	stamina = clamp(stamina + amount, 0, max_stamina)
	if(counts_as_spend && stamina < old_value)
		last_stamina_spend = world.time
		stamina_regen_accumulator = 0
	update_stamina_hud()
	apply_body_state_effects()
	return stamina - old_value

/mob/living/proc/adjust_energy_pool(amount)
	var/old_value = energy_pool
	energy_pool = clamp(energy_pool + amount, 0, max_energy_pool)
	return energy_pool - old_value

/mob/living/proc/adjust_satiation(amount)
	var/old_value = satiety
	satiety = clamp(satiety + amount, 0, MAX_SATIETY)
	return satiety - old_value

/mob/living/proc/adjust_hydration(amount)
	var/old_value = hydration
	hydration = clamp(hydration + amount, 0, MAX_SATIETY)
	return hydration - old_value

/mob/living/proc/adjust_tireness(amount)
	var/old_value = tireness
	tireness = clamp(tireness + amount, 0, MAX_SATIETY)
	return tireness - old_value

/mob/living/proc/adjust_mood(amount, share_cohort = TRUE)
	var/old_value = mood
	mood = clamp(mood + amount, -30, 20)
	apply_body_state_effects()
	if(share_cohort && amount > 0 && cyberpunk_cohort)
		cyberpunk_cohort.try_grant_inspiration_guard(src, amount)
		cyberpunk_cohort.share_mood(src, amount)
	return mood - old_value

/mob/living/proc/get_energy_pool_recovery()
	if(wall_hugging)
		return WALL_HUG_ENERGY_RECOVERY
	if(body_position == LYING_DOWN)
		var/recovery = 1
		if(istype(buckled, /obj/structure/bed))
			recovery += 1
			if(locate(/obj/item/pillow) in loc)
				recovery += 1
			if(locate(/obj/item/bedsheet) in loc)
				recovery += 1
			if(!has_hunger())
				recovery += 1
		return recovery
	if(resting || buckled)
		return 1
	return 0

/mob/living/proc/reward_stamina_spend_experience(amount, source)
	if(!mind || amount <= 0)
		return 0
	return mind.reward_character_check_experience(SKILL_ATHLETICS, amount * STAMINA_SPEND_XP_MULTIPLIER, FALSE, 1)

/datum/cyberpunk_cohort
	var/datum/weakref/leader_ref
	var/list/member_refs = list()

/datum/cyberpunk_cohort/New(mob/living/leader)
	leader_ref = WEAKREF(leader)
	add_member(leader)

/datum/cyberpunk_cohort/proc/get_leader()
	return leader_ref?.resolve()

/datum/cyberpunk_cohort/proc/get_members()
	var/list/members = list()
	for(var/datum/weakref/member_ref as anything in member_refs.Copy())
		var/mob/living/member = member_ref?.resolve()
		if(!member || QDELETED(member) || member.cyberpunk_cohort != src)
			member_refs -= member_ref
			continue
		members += member
	return members

/datum/cyberpunk_cohort/proc/get_capacity()
	var/mob/living/leader = get_leader()
	var/base_capacity = 2
	var/extra_capacity = leader?.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 2) || 0
	return base_capacity + extra_capacity

/datum/cyberpunk_cohort/proc/add_member(mob/living/member)
	if(!member)
		return FALSE
	if(length(get_members()) >= get_capacity() && member != get_leader())
		return FALSE
	if(member.cyberpunk_cohort && member.cyberpunk_cohort != src)
		member.cyberpunk_cohort.remove_member(member)
	member.cyberpunk_cohort = src
	member_refs |= WEAKREF(member)
	return TRUE

/datum/cyberpunk_cohort/proc/remove_member(mob/living/member)
	if(!member)
		return FALSE
	for(var/datum/weakref/member_ref as anything in member_refs.Copy())
		if(member_ref?.resolve() == member)
			member_refs -= member_ref
	if(member.cyberpunk_cohort == src)
		member.cyberpunk_cohort = null
	if(!length(get_members()))
		qdel(src)
	return TRUE

/datum/cyberpunk_cohort/proc/share_experience(mob/living/source, skill_key, final_experience, attribute_limited = FALSE)
	if(!source || final_experience <= 0 || source.cyberpunk_cohort != src)
		return
	var/share_percent = source.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 1)
	if(share_percent <= 0)
		return
	var/shared_experience = final_experience * share_percent * 0.01
	for(var/mob/living/member as anything in get_members())
		if(member == source || !member.mind)
			continue
		member.mind.add_raw_character_experience(skill_key, shared_experience, attribute_limited)

/datum/cyberpunk_cohort/proc/share_mood(mob/living/source, amount)
	if(!source || amount <= 0 || source.cyberpunk_cohort != src)
		return
	var/share_percent = source.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 4)
	if(share_percent <= 0)
		return
	var/shared_amount = amount * share_percent * 0.01
	for(var/mob/living/member as anything in get_members())
		if(member == source)
			continue
		member.adjust_mood(shared_amount, FALSE)

/datum/cyberpunk_cohort/proc/get_inspiration_guard_bonus(mob/living/source)
	var/bonus = source?.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 5) || 0
	var/mob/living/leader = get_leader()
	if(leader && leader != source)
		bonus = max(bonus, leader.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 5))
	return bonus

/datum/cyberpunk_cohort/proc/try_grant_inspiration_guard(mob/living/source, amount)
	if(!source || amount < 5 || source.cyberpunk_cohort != src)
		return FALSE
	var/bonus = get_inspiration_guard_bonus(source)
	if(bonus <= 0)
		return FALSE
	for(var/mob/living/member as anything in get_members())
		member.apply_cyberpunk_inspiration_guard(bonus)
	return TRUE

/datum/cyberpunk_cohort/proc/share_status_effect(mob/living/source, datum/cyberpunk_status_effect/effect)
	if(!source || !effect || source.cyberpunk_cohort != src || !effect.shareable || effect.effect_kind != "buff")
		return
	var/share_percent = source.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 3)
	if(share_percent <= 0)
		return
	var/shared_duration = max(1, round(effect.get_remaining_duration() * share_percent * 0.01))
	var/shared_power = max(0.1, effect.power * share_percent * 0.01)
	for(var/mob/living/member as anything in get_members())
		if(member == source)
			continue
		member.apply_cyberpunk_status_effect(effect.type, shared_duration, shared_power, source, FALSE)

/mob/living/proc/has_cyberpunk_cohort_unconscious_protection()
	if(!cyberpunk_cohort)
		return FALSE
	var/mob/living/leader = cyberpunk_cohort.get_leader()
	return leader?.get_cyberpunk_skill_perk_bonus(SKILL_INSPIRATION, 6) > 0

/mob/living/proc/apply_cyberpunk_inspiration_guard(bonus)
	if(bonus <= 0)
		return FALSE
	cyberpunk_inspiration_guard_bonus = max(cyberpunk_inspiration_guard_bonus, bonus)
	to_chat(src, span_notice("Inspiration sharpens your next defensive moment."))
	return TRUE

/mob/living/proc/get_cyberpunk_inspiration_guard_multiplier()
	if(cyberpunk_inspiration_guard_bonus <= 0)
		return 1
	return 1 + cyberpunk_inspiration_guard_bonus * 0.01

/mob/living/proc/consume_cyberpunk_inspiration_guard(context = "defense")
	if(cyberpunk_inspiration_guard_bonus <= 0)
		return 0
	var/bonus = cyberpunk_inspiration_guard_bonus
	cyberpunk_inspiration_guard_bonus = 0
	to_chat(src, span_notice("Your cohort inspiration reinforces your [context]."))
	return bonus

/mob/living/verb/manage_cyberpunk_cohort()
	set name = "Cohort"
	set category = "IC"
	var/list/options = list("Invite nearby", "Show members")
	if(cyberpunk_cohort)
		options += "Leave cohort"
	var/choice = tgui_input_list(src, "Choose cohort action.", "Cohort", options)
	switch(choice)
		if("Invite nearby")
			invite_cyberpunk_cohort_member()
		if("Show members")
			show_cyberpunk_cohort()
		if("Leave cohort")
			leave_cyberpunk_cohort()

/mob/living/proc/ensure_cyberpunk_cohort()
	if(!cyberpunk_cohort)
		cyberpunk_cohort = new /datum/cyberpunk_cohort(src)
	return cyberpunk_cohort

/mob/living/proc/invite_cyberpunk_cohort_member()
	var/datum/cyberpunk_cohort/cohort = ensure_cyberpunk_cohort()
	var/list/candidates = list()
	for(var/mob/living/candidate in view(8, src))
		if(candidate == src || !candidate.client || candidate.stat == DEAD || candidate.cyberpunk_cohort == cohort)
			continue
		candidates[candidate.name] = candidate
	if(!length(candidates))
		to_chat(src, span_notice("No nearby candidates for your cohort."))
		return FALSE
	var/choice = tgui_input_list(src, "Invite who?", "Cohort Invite", candidates)
	var/mob/living/target = candidates[choice]
	if(!target || get_dist(src, target) > 8)
		return FALSE
	if(tgui_alert(target, "[src] invites you to join their cohort.", "Cohort Invite", list("Join", "Decline")) != "Join")
		return FALSE
	if(get_dist(src, target) > 8 || QDELETED(target))
		return FALSE
	if(!cohort.add_member(target))
		to_chat(src, span_warning("The cohort is full."))
		return FALSE
	to_chat(src, span_notice("[target] joins your cohort."))
	to_chat(target, span_notice("You join [src]'s cohort."))
	return TRUE

/mob/living/proc/show_cyberpunk_cohort()
	if(!cyberpunk_cohort)
		to_chat(src, span_notice("You are not in a cohort."))
		return FALSE
	var/list/names = list()
	for(var/mob/living/member as anything in cyberpunk_cohort.get_members())
		names += member.name
	to_chat(src, span_notice("Cohort: [english_list(names)]."))
	return TRUE

/mob/living/proc/leave_cyberpunk_cohort()
	if(!cyberpunk_cohort)
		return FALSE
	var/datum/cyberpunk_cohort/old_cohort = cyberpunk_cohort
	old_cohort.remove_member(src)
	to_chat(src, span_notice("You leave the cohort."))
	return TRUE

/mob/living/proc/get_check_penalty()
	var/penalty = get_cyberpunk_needs_check_penalty()
	if(stamina <= 0)
		penalty += 0.2 * get_cyberpunk_endurance_stamina_penalty_multiplier()
	else if(stamina <= max_stamina * 0.1)
		penalty += 0.1 * get_cyberpunk_endurance_stamina_penalty_multiplier()
	else if(stamina <= max_stamina * 0.5)
		penalty += 0.05 * get_cyberpunk_endurance_stamina_penalty_multiplier()
	return min(penalty * get_cyberpunk_survival_penalty_multiplier(), 0.45)

/mob/living/proc/get_experience_multiplier()
	var/style_bonus = max(0, style) / 15 * 0.5
	var/style_xp_bonus = get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 5)
	if(style_xp_bonus > 0)
		style_bonus *= 1 + style_xp_bonus * 0.01
	return (1 + style_bonus + max(0, mood) / 20 * 0.5) * get_cyberpunk_status_experience_multiplier()

/mob/living/proc/can_dodge()
	if(is_cyberpunk_grabbing_living() || is_cyberpunk_grabbed_by_leg())
		return FALSE
	var/threshold_multiplier = max(0.2, 1 - get_cyberpunk_skill_perk_bonus(SKILL_EVASION, 1) * 0.01)
	return stamina > max_stamina * 0.1 * threshold_multiplier && stamina >= STAMINA_COST_DODGE * threshold_multiplier && !is_exhausted_by_needs()

/mob/living/proc/can_parry()
	if(is_active_hand_cyberpunk_grabbed())
		return FALSE
	if(is_cyberpunk_grabbing_living() && grab_state >= GRAB_TWOHANDED)
		return FALSE
	var/threshold_multiplier = max(0.2, 1 - get_cyberpunk_skill_perk_bonus(SKILL_CONCENTRATION, 1) * 0.01)
	return stamina > max_stamina * 0.1 * threshold_multiplier && stamina >= STAMINA_COST_PARRY * threshold_multiplier && !is_exhausted_by_needs()

/mob/living/proc/perform_cyberpunk_defensive_action(action = null)
	if(stat > SOFT_CRIT || INCAPACITATED_IGNORING(src, INCAPABLE_RESTRAINTS))
		return FALSE
	var/selected_action = action || cyberpunk_last_defensive_action || "parry"
	switch(selected_action)
		if("dodge")
			if(!can_dodge() || !spend_stamina(STAMINA_COST_DODGE, "dodge"))
				balloon_alert(src, "too tired")
				return FALSE
			cyberpunk_last_defensive_action = "dodge"
			cyberpunk_dodge_until = world.time + 2.4 SECONDS
			visible_message(span_notice("[src] prepares to dodge."), span_notice("You prepare to dodge."))
			reward_character_check_experience(SKILL_EVASION, 1, FALSE, 1)
			return TRUE
		if("parry")
			if(!can_parry() || !spend_stamina(STAMINA_COST_PARRY, "parry"))
				balloon_alert(src, "too tired")
				return FALSE
			cyberpunk_last_defensive_action = "parry"
			cyberpunk_parry_until = world.time + 3 SECONDS
			visible_message(span_notice("[src] raises a guard."), span_notice("You prepare to parry."))
			reward_character_check_experience(SKILL_CONCENTRATION, 1, FALSE, 1)
			return TRUE
	return FALSE

/mob/living/proc/has_active_cyberpunk_parry()
	return world.time <= cyberpunk_parry_until

/mob/living/proc/has_active_cyberpunk_dodge()
	return world.time <= cyberpunk_dodge_until

/mob/living/proc/set_cyberpunk_combat_intent(intent)
	if(intent != "slash" && intent != "stab")
		return FALSE
	cyberpunk_combat_intent = intent
	if(!combat_mode)
		set_combat_mode(TRUE, silent = FALSE)
	balloon_alert(src, intent)
	return TRUE

/mob/living/proc/cycle_cyberpunk_combat_intent()
	return set_cyberpunk_combat_intent(cyberpunk_combat_intent == "slash" ? "stab" : "slash")

/mob/living/proc/can_jump()
	var/threshold_multiplier = max(0.2, 1 - get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 3) * 0.01)
	return stamina > max_stamina * 0.1 * threshold_multiplier && stamina >= STAMINA_COST_JUMP * threshold_multiplier && !is_exhausted_by_needs()

/mob/living/proc/can_run()
	return stamina > 0 && stamina >= STAMINA_COST_RUN_TILE && !is_exhausted_by_needs() && !has_sleep_deprivation()

/mob/living/proc/is_exhausted_by_needs()
	return has_starvation_exhaustion() || has_dehydration() || has_sleep_deprivation()

/mob/living/proc/get_cyberpunk_needs_move_slowdown()
	var/slowdown = 0
	if(has_starvation_exhaustion())
		slowdown = max(slowdown, 0.25)
	else if(has_strong_hunger())
		slowdown = max(slowdown, 0.1)

	if(has_dehydration())
		slowdown = max(slowdown, 0.25)
	else if(has_strong_thirst())
		slowdown = max(slowdown, 0.15)
	else if(has_thirst())
		slowdown = max(slowdown, 0.05)

	if(has_sleep_deprivation())
		slowdown = max(slowdown, 0.2)
	return slowdown * get_cyberpunk_survival_penalty_multiplier()

/mob/living/proc/get_cyberpunk_needs_action_slowdown()
	var/slowdown = 0
	if(has_starvation_exhaustion())
		slowdown = max(slowdown, 0.25)
	else if(has_strong_hunger())
		slowdown = max(slowdown, 0.15)
	else if(has_hunger())
		slowdown = max(slowdown, 0.05)

	if(has_dehydration())
		slowdown = max(slowdown, 0.2)
	else if(has_strong_thirst())
		slowdown = max(slowdown, 0.15)
	else if(has_thirst())
		slowdown = max(slowdown, 0.05)

	if(has_sleep_deprivation())
		slowdown = max(slowdown, 0.25)
	else if(has_sleepiness())
		slowdown = max(slowdown, 0.08)
	return slowdown * get_cyberpunk_survival_penalty_multiplier()

/mob/living/proc/get_cyberpunk_needs_check_penalty()
	var/penalty = 0
	if(has_starvation_exhaustion())
		penalty += 0.15
	else if(has_strong_hunger())
		penalty += 0.08
	else if(has_hunger())
		penalty += 0.03

	if(has_dehydration())
		penalty += 0.15
	else if(has_strong_thirst())
		penalty += 0.08
	else if(has_thirst())
		penalty += 0.03

	if(has_sleep_deprivation())
		penalty += 0.12
	else if(has_sleepiness())
		penalty += 0.05
	return penalty

/mob/living/proc/get_cyberpunk_needs_stamina_cost_multiplier(source)
	if(!(source in list("progress", "run", "jump", "vertical_movement", "attack", "parry", "dodge", "defense")))
		return 1
	var/multiplier = 1
	if(has_starvation_exhaustion())
		multiplier += 0.25
	else if(has_strong_hunger())
		multiplier += 0.15
	else if(has_hunger())
		multiplier += 0.05

	if(has_dehydration())
		multiplier += 0.25
	else if(has_strong_thirst())
		multiplier += 0.15
	else if(has_thirst())
		multiplier += 0.05

	if(has_sleep_deprivation())
		multiplier += 0.2
	else if(has_sleepiness())
		multiplier += 0.08
	return multiplier

/mob/living/proc/get_cyberpunk_skill_stamina_cost_multiplier(source)
	var/multiplier = 1
	switch(source)
		if("jump", "vertical_movement")
			multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 3) * 0.01)
		if("dodge")
			multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_EVASION, 2, "value_1") * 0.01)
		if("parry", "defense")
			multiplier *= max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_CONCENTRATION, 2, "value_1") * 0.01)
	return multiplier

/mob/living/proc/get_cyberpunk_survival_need_drain_multiplier()
	return max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 1) * 0.01)

/mob/living/proc/get_cyberpunk_survival_recovery_multiplier()
	return 1 + get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 2, "value_1") * 0.01

/mob/living/proc/get_cyberpunk_survival_penalty_multiplier()
	var/reduction = max(get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 3), get_cyberpunk_skill_perk_bonus(SKILL_SURVIVAL, 6))
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_endurance_negative_mood_multiplier()
	var/reduction = max(get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 3), get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 6))
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_endurance_stamina_penalty_multiplier()
	var/reduction = max(get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 1), get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 2))
	return max(0.1, 1 - reduction * 0.01)

/mob/living/proc/get_cyberpunk_endurance_stamina_recovery_multiplier()
	return 1 + (get_character_skill_level(SKILL_ENDURANCE) * 0.05)

/mob/living/proc/get_cyberpunk_stamina_energy_reserve_recovery()
	return STAMINA_ENERGY_RESERVE_RECOVERY + get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 5)

/mob/living/proc/get_cyberpunk_stamina_regen_delay()
	return STAMINA_REGEN_DELAY * max(0.1, 1 - get_cyberpunk_skill_perk_bonus(SKILL_ATHLETICS, 6) * 0.01)

/mob/living/proc/roll_cyberpunk_endurance_ignore_damage_pain()
	var/ignore_chance = get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 4)
	return ignore_chance > 0 && prob(ignore_chance)

/mob/living/proc/apply_cyberpunk_pain_collapse()
	var/immobilize_duration = get_cyberpunk_skill_perk_bonus(SKILL_ENDURANCE, 5)
	if(immobilize_duration > 0)
		Immobilize(immobilize_duration SECONDS)
		to_chat(src, span_warning("Pain locks your muscles in place."))
		return TRUE
	Knockdown(5 SECONDS)
	return FALSE

/mob/living/proc/get_cyberpunk_implant_cooldown_multiplier()
	var/reduction = get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 4, "value_1")
	return max(0.1, 1 - (reduction * 0.01))

/mob/living/proc/get_cyberpunk_implant_passive_interval_multiplier()
	var/frequency_bonus = get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 4, "value_2")
	return 1 / max(0.1, 1 + (frequency_bonus * 0.01))

/mob/living/proc/get_cyberpunk_theft_search_level()
	return round(get_cyberpunk_skill_perk_bonus(SKILL_THEFT, 1))

/mob/living/proc/get_cyberpunk_theft_protected_level()
	return round(get_cyberpunk_skill_perk_bonus(SKILL_THEFT, 6))

/mob/living/proc/roll_cyberpunk_theft_moving_success()
	var/move_chance = get_cyberpunk_skill_perk_bonus(SKILL_THEFT, 5)
	return move_chance > 0 && prob(move_chance)

/mob/living/proc/get_cyberpunk_chromity_overload_pain(amount)
	var/overload_ratio = get_cyberpunk_skill_perk_bonus(SKILL_COMPATIBILITY, 5, "value_2")
	if(overload_ratio > 0)
		return amount / overload_ratio
	return amount * 2

/mob/living/proc/get_cyberpunk_acrobatics_move_bonus()
	var/bonus = get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 5) * 0.01
	if(world.time <= cyberpunk_acrobatics_speed_until)
		bonus += get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 4, "value_2") * 0.01
	return bonus

/mob/living/proc/get_cyberpunk_acrobatics_climb_duration(base_duration = 2 SECONDS)
	var/perk_reduction = get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 2)
	var/adjusted_duration = base_duration * max(0.1, 1 - perk_reduction * 0.01)
	adjusted_duration -= get_character_skill_level(SKILL_ACROBATICS) * (0.15 SECONDS)
	return max((0.2 SECONDS), adjusted_duration)

/mob/living/proc/get_cyberpunk_acrobatics_get_up_duration(base_duration = 1 SECONDS)
	var/perk_reduction = get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 2)
	if(perk_reduction <= 0)
		return base_duration
	return max((0.2 SECONDS), base_duration * max(0.1, 1 - perk_reduction * 0.01))

/mob/living/proc/apply_cyberpunk_acrobatics_speed_bonus()
	var/duration = get_cyberpunk_skill_perk_bonus(SKILL_ACROBATICS, 4, "value_1")
	if(duration <= 0)
		return FALSE
	cyberpunk_acrobatics_speed_until = world.time + duration SECONDS
	apply_body_state_effects()
	return TRUE

/mob/living/proc/roll_cyberpunk_weakness_critical(mob/living/target)
	if(!target)
		return FALSE
	var/crit_chance = get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 1, "value_1")
	if(crit_chance <= 0)
		return FALSE
	var/cooldown_seconds = get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 1, "value_2")
	if(cooldown_seconds > 0 && get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 5) <= 0 && world.time < cyberpunk_last_weakness_crit + cooldown_seconds SECONDS)
		return FALSE
	if(!prob(crit_chance))
		return FALSE
	cyberpunk_last_weakness_crit = world.time
	return TRUE

/mob/living/proc/get_cyberpunk_weakness_critical_damage_multiplier()
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 2)))
		return 3
	return 2

/mob/living/proc/get_cyberpunk_weakness_armor_ignore_chance()
	return get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 6)

/mob/living/proc/apply_cyberpunk_weakness_critical_effects(mob/living/target)
	if(!target)
		return FALSE
	if(prob(get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 3)))
		target.adjust_staggered_up_to(4 SECONDS, 10 SECONDS)
	var/stun_time = get_cyberpunk_skill_perk_bonus(SKILL_WEAKNESS_ANALYSIS, 4)
	if(stun_time > 0)
		target.Stun(stun_time SECONDS)
	reward_character_check_experience(SKILL_WEAKNESS_ANALYSIS, 10, FALSE, 1)
	return TRUE

/mob/living/examining(atom/target, list/result)
	. = ..()
	if(!istype(target, /mob/living) || target == src || !length(result))
		return
	var/mob/living/living_target = target
	if(can_cyberpunk_style_read_body_state())
		result += living_target.get_cyberpunk_style_body_readout()
	living_target.apply_cyberpunk_style_examine_bonus(src)

/mob/living/proc/can_cyberpunk_style_read_body_state()
	return get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 2) > 0

/mob/living/proc/get_cyberpunk_style_body_readout()
	return span_notice("Style read: mood [round(mood, 0.1)], satiation [get_cyberpunk_hunger_state()], hydration [get_cyberpunk_thirst_state()], tiredness [get_cyberpunk_tiredness_state()].")

/mob/living/proc/apply_cyberpunk_style_examine_bonus(mob/living/viewer)
	if(!viewer || viewer == src || style <= 0)
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 1, "value_1")
	if(chance <= 0 || !prob(chance))
		return FALSE
	viewer.adjust_mood(1)
	var/experience_minutes = get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 1, "value_2")
	if(experience_minutes > 0)
		reward_character_check_experience(SKILL_STYLE, max(1, experience_minutes), FALSE, 1)
	to_chat(viewer, span_notice("[src]'s style leaves an impression."))
	return TRUE

/mob/living/proc/apply_cyberpunk_style_counterattack_disorient(mob/living/attacker)
	if(!attacker || attacker == src)
		return FALSE
	var/chance = get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 6)
	if(chance <= 0 || !prob(chance))
		return FALSE
	attacker.adjust_confusion_up_to(3 SECONDS, 8 SECONDS)
	attacker.changeNext_move(CLICK_CD_MELEE)
	to_chat(attacker, span_warning("[src]'s style throws off your rhythm."))
	return TRUE

/obj/item/proc/apply_cyberpunk_style_action_status(mob/living/user)
	if(!user)
		return FALSE
	var/style_bonus = user.get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 3, "value_2")
	if(style_bonus <= 0)
		return FALSE
	cyberpunk_style_xp_bonus = style_bonus
	cyberpunk_style_xp_bonus_until = world.time + 30 SECONDS
	cyberpunk_style_status_owner = user.real_name || user.name
	return TRUE

/obj/item/proc/get_cyberpunk_style_xp_multiplier()
	if(world.time > cyberpunk_style_xp_bonus_until || cyberpunk_style_xp_bonus <= 0)
		return 1
	return 1 + cyberpunk_style_xp_bonus * 0.01

/mob/living/proc/get_cyberpunk_active_item_style_xp_multiplier()
	var/obj/item/active_item = get_active_held_item()
	return active_item?.get_cyberpunk_style_xp_multiplier() || 1

/mob/living/proc/get_cyberpunk_style_xp_bonus_receivers()
	var/list/bonus_receivers = list()
	for(var/mob/living/bonus_receiver in view(6, src))
		if(bonus_receiver == src || !bonus_receiver.mind || bonus_receiver.stat == DEAD || !bonus_receiver.client)
			continue
		if(has_recent_cyberpunk_style_attacker(bonus_receiver))
			continue
		bonus_receivers += bonus_receiver
	return bonus_receivers

/mob/living/proc/share_cyberpunk_style_experience_bonus(skill_key, final_experience, attribute_limited = FALSE)
	if(final_experience <= 0 || get_cyberpunk_skill_perk_bonus(SKILL_STYLE, 4) <= 0)
		return
	var/shared_experience = final_experience * 0.2
	for(var/mob/living/bonus_receiver as anything in get_cyberpunk_style_xp_bonus_receivers())
		bonus_receiver.mind?.add_raw_character_experience(skill_key, shared_experience, attribute_limited)

/mob/living/proc/remember_cyberpunk_style_attacker(mob/living/attacker)
	if(!attacker)
		return FALSE
	LAZYINITLIST(cyberpunk_recent_style_attackers)
	var/attacker_key = attacker.ckey || attacker.real_name || attacker.name
	if(!attacker_key)
		return FALSE
	cyberpunk_recent_style_attackers[attacker_key] = world.time + 30 SECONDS
	return TRUE

/mob/living/proc/has_recent_cyberpunk_style_attacker(mob/living/check_mob)
	if(!check_mob || !length(cyberpunk_recent_style_attackers))
		return FALSE
	var/check_key = check_mob.ckey || check_mob.real_name || check_mob.name
	if(!check_key)
		return FALSE
	var/blocked_until = cyberpunk_recent_style_attackers[check_key]
	if(!blocked_until)
		return FALSE
	if(world.time > blocked_until)
		cyberpunk_recent_style_attackers -= check_key
		return FALSE
	return TRUE

/mob/living/proc/get_cyberpunk_hunger_state()
	if(has_starvation_exhaustion())
		return "starving"
	if(has_strong_hunger())
		return "hungry"
	if(has_hunger())
		return "peckish"
	if(has_overeating())
		return "overfed"
	return "steady"

/mob/living/proc/get_cyberpunk_thirst_state()
	if(has_dehydration())
		return "dehydrated"
	if(has_strong_thirst())
		return "thirsty"
	if(has_thirst())
		return "dry"
	if(has_overdrinking())
		return "overhydrated"
	return "steady"

/mob/living/proc/get_cyberpunk_tiredness_state()
	if(has_sleep_deprivation())
		return "sleep-deprived"
	if(has_sleepiness())
		return "tired"
	if(tireness > 450)
		return "rested"
	return "steady"

/mob/living/proc/has_hunger()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 200

/mob/living/proc/has_overeating()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety > 450

/mob/living/proc/has_strong_hunger()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 130

/mob/living/proc/has_starvation_exhaustion()
	if(HAS_TRAIT(src, TRAIT_NOHUNGER))
		return FALSE
	return satiety < 80

/mob/living/proc/has_thirst()
	return hydration < 180

/mob/living/proc/has_overdrinking()
	return hydration > 450

/mob/living/proc/has_strong_thirst()
	return hydration < 100

/mob/living/proc/has_dehydration()
	return hydration < 20

/mob/living/proc/has_sleepiness()
	return tireness < 200

/mob/living/proc/has_sleep_deprivation()
	return tireness < 50

/mob/living/proc/trigger_hysteria()
	last_control_loss = world.time
	time_at_min_mood = 0
	visible_message(span_warning("[src] loses control!"), span_userdanger("You lose control of yourself."))
	Stun(30 SECONDS)

// Base mob environment handler for body temperature
/mob/living/proc/handle_environment(datum/gas_mixture/environment, seconds_per_tick)
	var/loc_temp = get_temperature(environment)
	var/temp_delta = loc_temp - bodytemperature

	if(ismovable(loc))
		var/atom/movable/occupied_space = loc
		temp_delta *= (1 - occupied_space.contents_thermal_insulation)

	if(temp_delta < 0) // it is cold here
		if(!on_fire) // do not reduce body temp when on fire
			adjust_bodytemperature(max(max(temp_delta / BODYTEMP_DIVISOR, BODYTEMP_COOLING_MAX) * seconds_per_tick, temp_delta))
	else // this is a hot place
		adjust_bodytemperature(min(min(temp_delta / BODYTEMP_DIVISOR, BODYTEMP_HEATING_MAX) * seconds_per_tick, temp_delta))

/**
 * Get the fullness of the mob
 *
 * Fullness is a representation of how much nutrition the mob has,
 * including the nutrition of stuff yet to be digested (reagents in blood / stomach)
 *
 * * only_consumable - if TRUE, only consumable reagents are counted.
 * Otherwise, all reagents contribute to fullness, despite not adding nutrition as they process.
 *
 * Returns a number representing fullness, scaled similarly to nutrition.
 */
/mob/living/proc/get_fullness(only_consumable)
	var/fullness = nutrition
	// we add the nutrition value of what we're currently digesting
	for(var/datum/reagent/consumable/bits in reagents.reagent_list)
		fullness += bits.get_nutriment_factor(src) * bits.volume / bits.metabolization_rate
	return fullness

/**
 * Check if the mob contains this reagent.
 *
 * This will validate the the reagent holder for the mob and any sub holders contain the requested reagent.
 * Vars:
 * * reagent (typepath) takes a PATH to a reagent.
 * * amount (int) checks for having a specific amount of that chemical.
 * * needs_metabolizing (bool) takes into consideration if the chemical is matabolizing when it's checked.
 */
/mob/living/proc/has_reagent(reagent, amount = -1, needs_metabolizing = FALSE)
	return reagents?.has_reagent(reagent, amount, needs_metabolizing)

/mob/living/proc/update_damage_hud()
	return

/mob/living/proc/handle_gravity(seconds_per_tick)
	if(gravity_state > STANDARD_GRAVITY)
		handle_high_gravity(gravity_state, seconds_per_tick)

/mob/living/proc/gravity_animate()
	if(!get_filter("gravity"))
		add_filter("gravity",1,list("type"="motion_blur", "x"=0, "y"=0))
	animate(get_filter("gravity"), y = 1, time = 10, loop = -1)
	animate(y = 0, time = 10)

/mob/living/proc/handle_high_gravity(gravity, seconds_per_tick)
	if(gravity < GRAVITY_DAMAGE_THRESHOLD) //Aka gravity values of 3 or more
		return

	var/grav_strength = gravity - GRAVITY_DAMAGE_THRESHOLD
	adjust_brute_loss(min(GRAVITY_DAMAGE_SCALING * grav_strength, GRAVITY_DAMAGE_MAXIMUM) * seconds_per_tick)

/// Proc used for custom metabolization of reagents, if any
/mob/living/proc/reagent_tick(datum/reagent/chem, seconds_per_tick)
	SHOULD_CALL_PARENT(TRUE)
	return SEND_SIGNAL(src, COMSIG_MOB_REAGENT_TICK, chem, seconds_per_tick)

/// Proc used for custom reagent exposure effects, if any
/mob/living/proc/reagent_expose(datum/reagent/chem, methods = TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	return

#undef BODYTEMP_DIVISOR
