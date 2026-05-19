GLOBAL_LIST_INIT(cy_professional_skill_types, list(
	/datum/cy_skill/professional/medicine,
	/datum/cy_skill/professional/chemistry,
	/datum/cy_skill/professional/electricity,
	/datum/cy_skill/professional/construction,
	/datum/cy_skill/professional/invention,
	/datum/cy_skill/professional/analysis,
	/datum/cy_skill/professional/mining,
	/datum/cy_skill/professional/driving,
	/datum/cy_skill/professional/cooking,
	/datum/cy_skill/professional/gardening,
	/datum/cy_skill/professional/music,
))

/datum/cy_skill/professional
	category = "professional"
	limited_by_stat = FALSE
	max_level = CY_SKILL_MAXIMUM_LEVEL
	perks_by_level = list(
		"1" = list(/datum/cy_skill_perk/professional/apprentice),
		"2" = list(/datum/cy_skill_perk/professional/journeyman),
		"3" = list(/datum/cy_skill_perk/professional/reliable),
		"4" = list(/datum/cy_skill_perk/professional/specialist),
		"5" = list(/datum/cy_skill_perk/professional/expert),
		"6" = list(/datum/cy_skill_perk/professional/master),
	)

/datum/cy_skill/professional/medicine
	name = "Медицина"
	id = "medicine"
	governing_stat = /datum/cy_stat/spirit

/datum/cy_skill/professional/chemistry
	name = "Химия"
	id = "chemistry"
	governing_stat = /datum/cy_stat/intelligence

/datum/cy_skill/professional/electricity
	name = "Электрика"
	id = "electricity"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/professional/construction
	name = "Строительство"
	id = "construction"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/professional/invention
	name = "Изобретательство"
	id = "invention"
	governing_stat = /datum/cy_stat/intelligence

/datum/cy_skill/professional/analysis
	name = "Анализ"
	id = "analysis"
	governing_stat = /datum/cy_stat/perception

/datum/cy_skill/professional/mining
	name = "Добыча"
	id = "mining"
	governing_stat = /datum/cy_stat/strength

/datum/cy_skill/professional/driving
	name = "Управление"
	id = "driving"
	governing_stat = /datum/cy_stat/perception

/datum/cy_skill/professional/cooking
	name = "Готовка"
	id = "cooking"
	governing_stat = /datum/cy_stat/dexterity

/datum/cy_skill/professional/gardening
	name = "Садоводство"
	id = "gardening"
	governing_stat = /datum/cy_stat/spirit

/datum/cy_skill/professional/music
	name = "Музыка"
	id = "music"
	governing_stat = /datum/cy_stat/charisma
