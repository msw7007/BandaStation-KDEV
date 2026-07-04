/datum/mutation/biotechcompat
	name = "Biological Compatibility"
	desc = "Субъект становится более совместимым с грубыми биологическими изменениями. Часть потери гуманоидности временно маскируется при расчетах совместимости с хромом."
	quality = POSITIVE
	instability = HUMANOIDITY_LOAD_MINI
	var/humanoidity_bonus = 10

/datum/mutation/biotechcompat/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(!.)
		return
	owner.dna?.update_humanoidity(FALSE)

/datum/mutation/biotechcompat/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(.)
		return
	owner.dna?.update_humanoidity(FALSE)

/datum/mutation/clever
	name = "Clever"
	desc = "Заставляет субъекта чувствовать себя немного умнее. Наиболее эффективен с особями, обладающими низким уровнем интеллекта."
	quality = POSITIVE
	instability = HUMANOIDITY_LOAD_MODERATE // literally makes you on par with station equipment
	text_gain_indication = span_danger("Ты чувствуешь себя немного умнее.")
	text_lose_indication = span_danger("Твоё сознание немного затуманивается.")

/datum/mutation/clever/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_LITERATE), GENETIC_MUTATION)

/datum/mutation/clever/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.remove_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_LITERATE), GENETIC_MUTATION)
