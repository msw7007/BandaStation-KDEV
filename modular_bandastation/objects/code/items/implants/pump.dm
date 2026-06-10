///amount of reagent to inject per time
#define REAGENT_AMOUNT "reagent_amount"
///amount of reagent to inject before the implant stops injecting
#define REAGENT_THRESHOLD "reagent_threshold"
///cooldown for reagent synthesis
#define COOLDOWN_PUMP "pump"

/obj/item/organ/cyberimp/chest/pump
	name = "pump"
	desc = "Маленькая помпа, используемая для инъекции реагентов в кровоток."
	icon_state = "nutriment_implant"
	aug_overlay = "nutripump"
	slot = ORGAN_SLOT_BELLY_AUG
	var/cooldown_time = 5 SECONDS
	/**
	 * list of reagents with their injection and threshold amounts
	 * * REAGENT_AMOUNT - amount of reagent to inject per time
	 * * REAGENT_THRESHOLD - amount of reagent to inject before the implant stops injecting
	 */
	var/list/reagent_data = list()
	/// time between injections

/obj/item/organ/cyberimp/chest/pump/on_life(seconds_per_tick, times_fired)
	if(!is_implant_functional())
		return ..()
	if(!TIMER_COOLDOWN_FINISHED(src, COOLDOWN_PUMP))
		return ..()

	for(var/key,value in reagent_data)
		var/reagent_type = key
		var/list/reagent_data_value = value
		var/datum/reagent/reagent_inside_owner = owner.reagents.has_reagent(reagent_type)
		if(!reagent_inside_owner || reagent_inside_owner.volume < reagent_data_value[REAGENT_THRESHOLD])
			owner.reagents.add_reagent(reagent_type, reagent_data_value[REAGENT_AMOUNT])

	if(custom_check(seconds_per_tick, times_fired))
		custom_effect(seconds_per_tick, times_fired)

	TIMER_COOLDOWN_START(src, COOLDOWN_PUMP, cooldown_time)
	return ..()

/**
 * This is a stub, it should be overridden by the implant
 * to check if the implant can be used or not for the specific actions.
*/
/obj/item/organ/cyberimp/chest/pump/proc/custom_check(seconds_per_tick, times_fired)
	return FALSE

/**
 * This is a stub, it should be overridden by the implant
 * to apply the specific effect of the implant.
*/
/obj/item/organ/cyberimp/chest/pump/proc/custom_effect(seconds_per_tick, times_fired)
	return

/obj/item/organ/cyberimp/chest/pump/centcom
	name = "combat medicine pump"
	desc = "Маленькая помпа, используемая для инъекции крайне эффективных препаратов в кровоток."
	reagent_data = list(
		/datum/reagent/medicine/syndicate_nanites = list(
			REAGENT_AMOUNT = 5,
			REAGENT_THRESHOLD = 20
		),
		/datum/reagent/medicine/leporazine = list(
			REAGENT_AMOUNT = 2,
			REAGENT_THRESHOLD = 8
		),
		/datum/reagent/medicine/synaptizine = list(
			REAGENT_AMOUNT = 2,
			REAGENT_THRESHOLD = 4
		),
		/datum/reagent/medicine/coagulant = list(
			REAGENT_AMOUNT = 4,
			REAGENT_THRESHOLD = 16
		),
			/datum/reagent/medicine/salglu_solution = list(
			REAGENT_AMOUNT = 10,
			REAGENT_THRESHOLD = 50
		)
	)

/obj/item/organ/cyberimp/chest/pump/centcom/custom_check(seconds_per_tick, times_fired)
	return owner.nutrition <= NUTRITION_LEVEL_HUNGRY

/obj/item/organ/cyberimp/chest/pump/centcom/custom_effect(seconds_per_tick, times_fired)
	. = ..()
	to_chat(owner, span_notice("Вы чувствуете себя менее голодным..."))
	owner.adjust_nutrition(25 * seconds_per_tick)

/obj/item/organ/cyberimp/chest/pump/sansufentanyl
	name = "sansufentanyl pump"
	desc = "Помпа, используемая для инъекции синтетического опиоида в фент-реактор. Жизненно важный механизм для функционирования фент-дроидов"
	reagent_data = list(
		/datum/reagent/medicine/sansufentanyl = list(
			REAGENT_AMOUNT = 1,
			REAGENT_THRESHOLD = 4
		)
	)

/obj/item/organ/cyberimp/chest/pump/universal
	name = "universal reagent pump"
	desc = "A belly implant that stores any reagent poured into it and injects measured doses on command."
	reagent_data = list()
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/inject_amount = 5
	var/max_reagent_storage = 10
	COOLDOWN_DECLARE(universal_pump_cooldown)

/obj/item/organ/cyberimp/chest/pump/universal/Initialize(mapload)
	. = ..()
	inject_amount = tier_value(list(5, 10, 10))
	max_reagent_storage = tier_value(list(10, 20, 50))
	cooldown_time = tier_value(list(10 SECONDS, 8 SECONDS, 4 SECONDS))
	create_reagents(max_reagent_storage, OPENCONTAINER)

/obj/item/organ/cyberimp/chest/pump/universal/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!tool.reagents || !reagents)
		return NONE
	var/free_volume = max(0, reagents.maximum_volume - reagents.total_volume)
	if(free_volume <= 0)
		to_chat(user, span_warning("[capitalize(src)] is full."))
		return ITEM_INTERACT_BLOCKING
	var/transfer_amount = free_volume
	if(istype(tool, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/container = tool
		transfer_amount = container.amount_per_transfer_from_this
	var/transferred = tool.reagents.trans_to(src, min(free_volume, transfer_amount), transferred_by = user)
	if(transferred)
		to_chat(user, span_notice("You load [transferred] units into [src]."))
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/organ/cyberimp/chest/pump/universal/ui_action_click(mob/user, datum/action/source)
	if(!is_implant_functional())
		to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return
	if(!reagents?.total_volume)
		to_chat(owner, span_warning("[capitalize(src)] is empty."))
		return
	if(!COOLDOWN_FINISHED(src, universal_pump_cooldown))
		to_chat(owner, span_warning("[capitalize(src)] is still cycling."))
		return
	var/transferred = reagents.trans_to(owner, min(inject_amount, reagents.total_volume), transferred_by = owner, methods = INJECT)
	if(transferred)
		to_chat(owner, span_notice("[capitalize(src)] injects [transferred] units."))
		COOLDOWN_START(src, universal_pump_cooldown, cooldown_time)

/obj/item/organ/cyberimp/chest/pump/universal/t2
	name = "universal reagent pump T2"
	implant_tier = 2

/obj/item/organ/cyberimp/chest/pump/universal/t3
	name = "universal reagent pump T3"
	implant_tier = 3

/obj/item/organ/cyberimp/chest/kebab_generator
	name = "Животюрница 2.0"
	desc = "Абсурдный желудочный имплант, синтезирующий готовый кебаб по запросу."
	icon_state = "adv_nutriment_implant"
	aug_overlay = "nutripump_adv"
	slot = ORGAN_SLOT_BELLY_AUG
	chromity_overheat = 10
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/list/food_options = list(/obj/item/food/kebab)
	COOLDOWN_DECLARE(kebab_cooldown)

/obj/item/organ/cyberimp/chest/kebab_generator/ui_action_click(mob/user, datum/action/source)
	if(!is_implant_functional())
		to_chat(owner, span_warning("[capitalize(declent_ru(NOMINATIVE))] не отвечает."))
		return
	if(!COOLDOWN_FINISHED(src, kebab_cooldown))
		to_chat(owner, span_warning("[capitalize(declent_ru(NOMINATIVE))] ещё разогревается."))
		return

	COOLDOWN_START(src, kebab_cooldown, 5 SECONDS)
	add_chromity_overheat(30)

	var/food_type = pick_food_type()
	var/obj/item/food/generated_food = new food_type(owner.drop_location())
	if(owner.put_in_hands(generated_food))
		to_chat(owner, span_notice("[capitalize(declent_ru(NOMINATIVE))] выдаёт свежий кебаб."))
	else
		to_chat(owner, span_notice("[capitalize(declent_ru(NOMINATIVE))] выкладывает свежий кебаб рядом."))

/obj/item/organ/cyberimp/chest/kebab_generator/proc/pick_food_type()
	if(length(food_options) <= 1)
		return food_options[1]
	var/list/radial_options = list()
	for(var/obj/item/food/food_type as anything in food_options)
		radial_options[food_type] = image(icon = initial(food_type.icon), icon_state = initial(food_type.icon_state))
	var/choice = show_radial_menu(owner, owner, radial_options, radius = 38, tooltips = TRUE)
	return choice || food_options[1]

/obj/item/organ/cyberimp/chest/kebab_generator/t2
	name = "Soundfan T2"
	implant_tier = 2
	food_options = list(
		/obj/item/food/kebab,
		/obj/item/food/meat/steak,
		/obj/item/food/meatball,
	)

/obj/item/organ/cyberimp/chest/kebab_generator/t3
	name = "Soundfan T3"
	implant_tier = 3
	food_options = list(
		/obj/item/food/kebab,
		/obj/item/food/meat/steak,
		/obj/item/food/meatball,
		/obj/item/food/meatbun,
		/obj/item/food/pizza/meat,
	)

#undef REAGENT_AMOUNT
#undef REAGENT_THRESHOLD
#undef COOLDOWN_PUMP
