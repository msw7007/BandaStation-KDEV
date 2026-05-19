GLOBAL_LIST_INIT(cy_weapon_skill_types, list(
	/datum/cy_skill/weapon/knives,
	/datum/cy_skill/weapon/one_handed_chopping,
	/datum/cy_skill/weapon/two_handed_chopping,
	/datum/cy_skill/weapon/one_handed_piercing,
	/datum/cy_skill/weapon/two_handed_piercing,
	/datum/cy_skill/weapon/one_handed_slashing,
	/datum/cy_skill/weapon/two_handed_slashing,
	/datum/cy_skill/weapon/one_handed_blunt,
	/datum/cy_skill/weapon/two_handed_blunt,
	/datum/cy_skill/weapon/light_firearms,
	/datum/cy_skill/weapon/medium_firearms,
	/datum/cy_skill/weapon/heavy_firearms,
))

/datum/cy_skill/weapon
	category = "weapon"
	limited_by_stat = FALSE
	max_level = CY_SKILL_MAXIMUM_LEVEL
	perks_by_level = list(
		"1" = list(),
		"2" = list(),
		"3" = list(),
		"4" = list(),
		"5" = list(),
		"6" = list(),
	)

/datum/cy_skill/weapon/knives
	name = "Ножи"
	id = "knives"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/weapon/one_handed_chopping
	name = "Рубящее одноручное"
	id = "one_handed_chopping"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/weapon/two_handed_chopping
	name = "Рубящее двуручное"
	id = "two_handed_chopping"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/weapon/one_handed_piercing
	name = "Колющее одноручное"
	id = "one_handed_piercing"
	governing_stat = /datum/cy_stat/perception

/datum/cy_skill/weapon/two_handed_piercing
	name = "Колющее двуручное"
	id = "two_handed_piercing"
	governing_stat = /datum/cy_stat/perception

/datum/cy_skill/weapon/one_handed_slashing
	name = "Режущее одноручное"
	id = "one_handed_slashing"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/weapon/two_handed_slashing
	name = "Режущее двуручное"
	id = "two_handed_slashing"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/weapon/one_handed_blunt
	name = "Молотящее одноручное"
	id = "one_handed_blunt"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/weapon/two_handed_blunt
	name = "Молотящее двуручное"
	id = "two_handed_blunt"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/weapon/light_firearms
	name = "Лёгкое огнестрельное"
	id = "light_firearms"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/weapon/medium_firearms
	name = "Среднее огнестрельное"
	id = "medium_firearms"
	governing_stat = /datum/cy_stat/perception

/datum/cy_skill/weapon/heavy_firearms
	name = "Тяжёлое огнестрельное"
	id = "heavy_firearms"
	governing_stat = /datum/cy_stat/strength
