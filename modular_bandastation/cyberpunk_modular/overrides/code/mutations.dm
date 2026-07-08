// Cyberpunk modular overrides for selected mutation files.
// Core mutation files stay upstream-clean; this file loads late.

// From code/datums/mutations/adaptation.dm

/datum/mutation/adaptation
	name = "Adaptation"
	desc = "Странная мутация, которая адаптирует иммунную систему организма к экстремальным температурам. Не защищает от вакуума."
	quality = POSITIVE
	difficulty = 16
	text_gain_indication = span_notice("Твоё тело окутывает тепло!")
	instability = HUMANOIDITY_RECOVERY_MAJOR
	locked = TRUE // fake parent
	conflicts = list(/datum/mutation/adaptation)
	mutation_traits = list(TRAIT_WADDLING)
	/// Icon used for the adaptation overlay
	var/adapt_icon = "meow"

/datum/mutation/adaptation/New(datum/mutation/copymut)
	..()
	conflicts = typesof(/datum/mutation/adaptation)
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/mob/effects/genetics.dmi', adapt_icon, -MUTATIONS_LAYER))

/datum/mutation/adaptation/get_visual_indicator()
	return visual_indicators[type][1]

/datum/mutation/adaptation/cold
	name = "Cold Adaptation"
	desc = "Странная мутация, которая адаптирует иммунную систему организма к низким температурам. Она также предотвращает подсклазьзование на льду."
	text_gain_indication = span_notice("Твое тело наполняет освежающий холод.")
	instability = HUMANOIDITY_LOAD_MODERATE
	mutation_traits = list(TRAIT_RESISTCOLD, TRAIT_NO_SLIP_ICE)
	adapt_icon = "cold"
	locked = FALSE

/datum/mutation/adaptation/heat
	name = "Heat Adaptation"
	desc = "Странная мутация, которая адаптирует иммунную систему организма к высоким температурам, а также предотвращает возгорание её обладателя, хотя пламя всё ещё сжигает одежду. Также делает носителя невосприимчивым к пепельным штормам."
	text_gain_indication = span_notice("Твоё тело наполняет лёгкое тепло.")
	instability = HUMANOIDITY_LOAD_MODERATE
	mutation_traits = list(TRAIT_RESISTHEAT, TRAIT_ASHSTORM_IMMUNE)
	adapt_icon = "fire"
	locked = FALSE

/datum/mutation/adaptation/thermal
	name = "Thermal Adaptation"
	desc = "Странная мутация, которая даёт невосприимчивость к урону от высокой и низкой температур. Не защищает от высокого и низкого давления."
	difficulty = 32
	text_gain_indication = span_notice("Твоё тело ощущает комфорто-комнатную температуру.")
	instability = HUMANOIDITY_LOAD_MAJOR
	mutation_traits = list(TRAIT_RESISTHEAT, TRAIT_RESISTCOLD)
	adapt_icon = "thermal"
	locked = TRUE // recipe

/datum/mutation/adaptation/pressure
	name = "Pressure Adaptation"
	desc = "Странная мутация, которая адаптирует иммунную систему организма к низкому и высокому давлению. Не защищает от температуры и холодного космоса в том числе."
	text_gain_indication = span_notice("Ваше тело испытывает сильное давление.")
	instability = HUMANOIDITY_LOAD_MODERATE
	adapt_icon = "pressure"
	mutation_traits = list(TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)
	locked = TRUE

// From code/datums/mutations/antenna.dm

/datum/mutation/antenna
	name = "Antenna"
	desc = "У лица, подверженного данной мутации, вырастает антенна. Известно, что она позволяет получать доступ к общим радиоканалам."
	quality = POSITIVE
	text_gain_indication = span_notice("Ты чувствуешь, что на твоём лбу вырастает антенна.")
	text_lose_indication = span_notice("Твоя антенна убавляется и пропадает окончательно.")
	instability = HUMANOIDITY_LOAD_MINOR
	difficulty = 8
	locked = TRUE

/obj/item/implant/radio/antenna
	name = "internal antenna organ"
	desc = "The internal organ part of the antenna. Science has not yet given it a good name."
	icon = 'icons/obj/devices/voice.dmi'//maybe make a unique sprite later. not important
	icon_state = "walkietalkie"

/obj/item/implant/radio/antenna/Initialize(mapload)
	. = ..()
	radio.name = "internal antenna"

/datum/mutation/antenna/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(!.)
		return
	var/obj/item/implant/radio/antenna/linked_radio = new(owner)
	linked_radio.implant(owner, null, TRUE, TRUE)
	radio_weakref = WEAKREF(linked_radio)

/datum/mutation/antenna/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	var/obj/item/implant/radio/antenna/linked_radio = radio_weakref.resolve()
	if(linked_radio)
		QDEL_NULL(linked_radio)

/datum/mutation/antenna/New(datum/mutation/copymut)
	..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/mob/effects/genetics.dmi', "antenna", -FRONT_MUTATIONS_LAYER+1))//-MUTATIONS_LAYER+1

/datum/mutation/antenna/get_visual_indicator()
	return visual_indicators[type][1]

/datum/mutation/mindreader
	name = "Mind Reader"
	desc = "Лицо, подверженное данной мутации, может заглянуть в недавние воспоминания других."
	quality = POSITIVE
	text_gain_indication = span_notice("Ты слышишь голоса вдали в закромах своего разума.")
	text_lose_indication = span_notice("Голоса вдали затихают.")
	power_path = /datum/action/cooldown/spell/pointed/mindread
	instability = HUMANOIDITY_LOAD_MINOR
	difficulty = 8
	locked = TRUE

/datum/action/cooldown/spell/pointed/mindread
	name = "Mindread"
	desc = "Read the target's mind."
	button_icon_state = "mindread"
	school = SCHOOL_PSYCHIC
	cooldown_time = 5 SECONDS
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	antimagic_flags = MAGIC_RESISTANCE_MIND

	ranged_mousepointer = 'icons/effects/mouse_pointers/mindswap_target.dmi'

/datum/action/cooldown/spell/pointed/mindread/Grant(mob/grant_to)
	. = ..()
	if (!owner)
		return
	ADD_TRAIT(grant_to, TRAIT_MIND_READER, GENETIC_MUTATION)
	RegisterSignal(grant_to, COMSIG_MOB_EXAMINATE, PROC_REF(on_examining))

/datum/action/cooldown/spell/pointed/mindread/Remove(mob/remove_from)
	. = ..()
	REMOVE_TRAIT(remove_from, TRAIT_MIND_READER, GENETIC_MUTATION)
	UnregisterSignal(remove_from, COMSIG_MOB_EXAMINATE)

/datum/action/cooldown/spell/pointed/mindread/is_valid_target(atom/cast_on)
	if(!isliving(cast_on))
		return FALSE
	var/mob/living/living_cast_on = cast_on
	if(!living_cast_on.mind)
		to_chat(owner, span_warning("[cast_on] has no mind to read!"))
		return FALSE
	if(living_cast_on.stat == DEAD)
		to_chat(owner, span_warning("[cast_on] is dead!"))
		return FALSE
	if(living_cast_on.mob_biotypes & MOB_ROBOTIC)
		to_chat(owner, span_warning("[cast_on] is robotic, you can't read [cast_on.p_their()] mind!"))
		return FALSE

	return TRUE

/datum/action/cooldown/spell/pointed/mindread/cast(mob/living/cast_on)
	. = ..()
	if(cast_on.can_block_magic(antimagic_flags, charge_cost = 0))
		to_chat(owner, span_warning("As you reach into [cast_on]'s mind, \
			you are stopped by a mental blockage. It seems you've been foiled."))
		return

	if(cast_on == owner)
		to_chat(owner, span_warning("You plunge into your mind... Yep, it's your mind."))
		return

	if(cast_on.has_status_effect(/datum/status_effect/heretic_passive/moon))
		to_chat(owner, span_hypnophrase(span_bolddanger("YOU SEEK THE TRUTH? I WILL SHOW YOU EVERYTHING.")))
		if(isliving(owner))
			var/mob/living/reader = owner
			reader.apply_status_effect(/datum/status_effect/moon_converted)
		return

	if(HAS_TRAIT(cast_on, TRAIT_EVIL))
		to_chat(owner, span_warning("As you reach into [cast_on]'s mind, \
			you feel the overwhelming emptiness within. A truly evil being. \
			[HAS_TRAIT(owner, TRAIT_EVIL) ? "It's nice to find someone who is like-minded." : "What is wrong with this person?"]"))

	var/list/log_info = list()
	var/list/discovered_info = list("<i>You plunge into [cast_on]'s mind and discover...</i>")
	if(prob(20))
		// chance to alert the read-ee
		to_chat(cast_on, span_danger("You feel something foreign enter your mind."))
		log_info += "Target alerted!"

	var/list/recent_speech = cast_on.copy_recent_speech(copy_amount = 3, line_chance = 50)
	if(length(recent_speech))
		discovered_info += "...Drifting memories of past conversations:"
		var/list/speech_block = list()
		for(var/spoken_memory in recent_speech)
			speech_block += "&emsp;\"[spoken_memory]\"..."
			log_info += "Recent speech: \"[spoken_memory]\""
		discovered_info += jointext(speech_block, "<br>")

	if(iscarbon(cast_on))
		var/mob/living/carbon/carbon_cast_on = cast_on
		discovered_info += "...Intent to <b>[carbon_cast_on.combat_mode ? "harm" : "help"]</b>."
		discovered_info += "...True identity of <b>[carbon_cast_on.mind.name]</b>."
		log_info += "Intent: \"[carbon_cast_on.combat_mode ? "harm" : "help"]\""
		log_info += "Identity: \"[carbon_cast_on.mind.name]\""

	to_chat(owner, boxed_message(span_notice(jointext(discovered_info, "<br>"))))
	log_combat(owner, cast_on, "mind read (cast intentionally)", null, "info: [english_list(log_info, and_text = ", ")]")

/datum/action/cooldown/spell/pointed/mindread/on_examining(mob/examiner, atom/examining)
	if(!isliving(examining) || examiner == examining)
		return

	INVOKE_ASYNC(src, PROC_REF(read_mind), examiner, examining)

/datum/action/cooldown/spell/pointed/mindread/read_mind(mob/living/examiner, mob/living/examined)
	if(examined.stat >= UNCONSCIOUS || isnull(examined.mind) || (examined.mob_biotypes & MOB_ROBOTIC))
		return

	var/antimagic = examined.can_block_magic(antimagic_flags, charge_cost = 0)
	var/read_text = ""
	if(!antimagic)
		read_text = examined.get_typing_text()
		if(!read_text)
			return

	sleep(0.5 SECONDS) // small pause so it comes after all examine text and effects
	if(QDELETED(examiner))
		return
	if(antimagic)
		to_chat(examiner, boxed_message(span_warning("You attempt to analyze [examined]'s current thoughts, but fail to penetrate [examined.p_their()] mind - It seems you've been foiled.")))
		return

	var/list/log_info = list()
	if(prob(10))
		to_chat(examined, span_danger("You feel something foreign enter your mind."))
		log_info += "Target alerted!"

	to_chat(examiner, boxed_message(span_notice("<i>You analyze [examined]'s current thoughts...</i><br>&emsp;\"[read_text]\"...")))
	log_info += "Current thought: \"[read_text]\""

	log_combat(examiner, examined, "mind read (triggered on examine)", null, "info: [english_list(log_info, and_text = ", ")]")

/datum/mutation/mindreader/New(datum/mutation/copymut)
	..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/mob/effects/genetics.dmi', "antenna", -FRONT_MUTATIONS_LAYER+1))

/datum/mutation/mindreader/get_visual_indicator()
	return visual_indicators[type][1]

// From code/datums/mutations/reach.dm

///Telekinesis lets you interact with objects from range, and gives you a light blue halo around your head.
/datum/mutation/telekinesis
	name = "Telekinesis"
	desc = "Странная мутация, которая позволяет её обладателю взаимодействовать с объектами при помощи силы мыслей."
	quality = POSITIVE
	difficulty = 18
	text_gain_indication = span_notice("You feel smarter!")
	limb_req = BODY_ZONE_HEAD
	instability = HUMANOIDITY_LOAD_MAJOR

/datum/mutation/telekinesis/New(datum/mutation/copymut)
	..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/mob/effects/genetics.dmi', "telekinesishead", -MUTATIONS_LAYER))

/datum/mutation/telekinesis/on_acquiring(mob/living/carbon/human/homan)
	. = ..()
	if(!.)
		return
	RegisterSignal(homan, COMSIG_MOB_ATTACK_RANGED, PROC_REF(on_ranged_attack))

/datum/mutation/telekinesis/on_losing(mob/living/carbon/human/homan)
	. = ..()
	if(.)
		return
	UnregisterSignal(homan, COMSIG_MOB_ATTACK_RANGED)

/datum/mutation/telekinesis/get_visual_indicator()
	return visual_indicators[type][1]

///Triggers on COMSIG_MOB_ATTACK_RANGED. Usually handles stuff like picking up items at range.
/datum/mutation/telekinesis/on_ranged_attack(mob/source, atom/target)
	if(!HAS_TRAIT(source, TRAIT_PSI_EYES))
		to_chat(source, span_warning("Your psionic sense cannot resolve the target without psi eyes."))
		return
	if(is_type_in_typecache(target, blacklisted_atoms))
		return
	if(!tkMaxRangeCheck(source, target) || source.z != target.z)
		return
	return target.attack_tk(source)

/datum/mutation/elastic_arms
	name = "Elastic Arms"
	desc = "Руки субъекта становятся эластичными, позволяя им растягиваться до метра. Однако, такая эластичность затрудняет ношение перчаток, выполнение сложных задач и взятие больших объектов."
	quality = POSITIVE
	instability = HUMANOIDITY_LOAD_MAJOR
	text_gain_indication = span_warning("Твои руки становятся похожими на... на... НА СПАГЕТТИ!")
	text_lose_indication = span_warning("Твои руки перестают быть такими отвисшими всё время.")
	difficulty = 32
	mutation_traits = list(TRAIT_CHUNKYFINGERS, TRAIT_NO_TWOHANDING)

/datum/mutation/elastic_arms/on_acquiring(mob/living/carbon/human/homan)
	. = ..()
	if(!.)
		return
	RegisterSignal(homan, COMSIG_LIVING_TRY_PUT_IN_HAND, PROC_REF(on_owner_equipping_item))
	RegisterSignal(homan, COMSIG_LIVING_TRY_PULL, PROC_REF(on_owner_try_pull))
	homan.reach_length++

/datum/mutation/elastic_arms/on_losing(mob/living/carbon/human/homan)
	. = ..()
	if(.)
		return
	UnregisterSignal(homan, list(COMSIG_LIVING_TRY_PUT_IN_HAND, COMSIG_LIVING_TRY_PULL))
	homan.reach_length = min(1, homan.reach_length - 1)

/// signal sent when prompting if an item can be equipped
/datum/mutation/elastic_arms/on_owner_equipping_item(mob/living/carbon/human/owner, obj/item/pick_item)
	if((pick_item.w_class > WEIGHT_CLASS_BULKY) && !(pick_item.item_flags & (ABSTRACT|HAND_ITEM))) // cant decide if i should limit to huge or bulky.
		pick_item.balloon_alert(owner, "arms too floppy to wield!")
		return COMPONENT_LIVING_CANT_PUT_IN_HAND

/// signal sent when owner tries to pull
/datum/mutation/elastic_arms/on_owner_try_pull(mob/living/carbon/owner, atom/movable/target, force)
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.mob_size > MOB_SIZE_HUMAN)
			living_target.balloon_alert(owner, "arms too floppy to pull this!")
			return COMSIG_LIVING_CANCEL_PULL
	if(isitem(target))
		var/obj/item/item_target = target
		if(item_target.w_class > WEIGHT_CLASS_BULKY)
			item_target.balloon_alert(owner, "arms too floppy to pull this!")
			return COMSIG_LIVING_CANCEL_PULL

