/datum/loadout_item/head
	abstract_type = /datum/loadout_item/head

/datum/loadout_item/head/insert_path_into_outfit(datum/outfit/outfit, mob/living/carbon/human/equipper, visuals_only = FALSE)
	if(equipper?.dna?.species?.outfit_important_for_life)
		if(!visuals_only)
			to_chat(equipper, "Your loadout helmet was not equipped directly due to your species outfit.")
			LAZYADD(outfit.backpack_contents, item_path)
		return

	if(outfit.head)
		LAZYADD(outfit.backpack_contents, outfit.head)
	outfit.head = item_path

// MARK: Tier 0
/datum/loadout_item/head/kippah
	name = "Киппа"
	item_path = /obj/item/clothing/head/chaplain/kippah

/datum/loadout_item/head/cowboy_grey
	name = "Шляпа бродяги"
	item_path = /obj/item/clothing/head/cowboy/grey

/datum/loadout_item/head/mothcap
	name = "Молиная шапка"
	item_path = /obj/item/clothing/head/mothcap

/datum/loadout_item/head/hairpin
	name = "Заколка"
	item_path = /obj/item/clothing/head/costume/hairpin

/datum/loadout_item/head/cowboy_white
	name = "Ковбойская шляпа"
	item_path = /obj/item/clothing/head/cowboy/white

/datum/loadout_item/head/irs
	name = "Cap(Налоговая)"
	item_path = /obj/item/clothing/head/costume/irs

/datum/loadout_item/head/yuri
	name = "Шлем посвященного юри"
	item_path = /obj/item/clothing/head/costume/yuri

// MARK: Tier 1
/datum/loadout_item/head/ratge_helmet
	name = "Крысоголов"
	item_path = /obj/item/clothing/head/ratge
	donator_level = DONATOR_TIER_1

// MARK: Tier 2
/datum/loadout_item/head/biker_helmet
	name = "Байкерский шлем"
	item_path = /obj/item/clothing/head/helmet/biker_helmet/replica
	donator_level = DONATOR_TIER_2
