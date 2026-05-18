#define CHARACTERISTIC_POINT_BUDGET 5
#define CHARACTERISTIC_COUNT 7
#define CHARACTERISTIC_TOTAL_POINT_BUDGET ((CY_STAT_DEFAULT * CHARACTERISTIC_COUNT) + CHARACTERISTIC_POINT_BUDGET)
#define WEAPON_SKILL_POINT_BUDGET 8
#define PROFESSIONAL_SKILL_POINT_BUDGET 8

/datum/preference/numeric/character_setup_stat
	abstract_type = /datum/preference/numeric/character_setup_stat
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	priority = PREFERENCE_PRIORITY_BODY_TYPE
	minimum = 0
	maximum = 4
	step = 1
	can_randomize = FALSE
	var/point_budget = 0
	var/stat_group
	var/stat_key
	var/stat_peer_root
	var/stat_type
	var/skill_type
	var/limiting_characteristic_key

/datum/preference/numeric/character_setup_stat/create_default_value()
	return 0

/datum/preference/numeric/character_setup_stat/is_valid(value, datum/preferences/preferences)
	if(!..(value, preferences))
		return FALSE

	var/used_points = value
	var/list/save_data = preferences.get_save_data_for_savefile_identifier(savefile_identifier)
	for(var/preference_type in subtypesof(stat_peer_root))
		if(preference_type == type)
			continue
		var/datum/preference/numeric/character_setup_stat/stat_preference = GLOB.preference_entries[preference_type]
		if(!istype(stat_preference) || stat_preference.point_budget != point_budget)
			continue
		if(limiting_characteristic_key && stat_preference.limiting_characteristic_key != limiting_characteristic_key)
			continue
		if(preference_type in preferences.value_cache)
			used_points += preferences.value_cache[preference_type]
			continue

		var/peer_value = stat_preference.read(save_data, preferences)
		used_points += isnull(peer_value) ? stat_preference.create_default_value() : peer_value

	if(limiting_characteristic_key)
		return used_points <= get_characteristic_limit(limiting_characteristic_key, save_data, preferences)

	return used_points <= point_budget

/datum/preference/numeric/character_setup_stat/proc/get_characteristic_limit(characteristic_key, list/save_data, datum/preferences/preferences)
	for(var/preference_type in subtypesof(/datum/preference/numeric/character_setup_stat/characteristic))
		var/datum/preference/numeric/character_setup_stat/characteristic/stat_preference = GLOB.preference_entries[preference_type]
		if(!istype(stat_preference) || stat_preference.stat_key != characteristic_key)
			continue
		if(preference_type in preferences.value_cache)
			return preferences.value_cache[preference_type]

		var/stat_value = stat_preference.read(save_data, preferences)
		return isnull(stat_value) ? stat_preference.create_default_value() : stat_value

	return CY_STAT_DEFAULT

/datum/preference/numeric/character_setup_stat/apply_to_human(mob/living/carbon/human/target, value)
	switch(stat_group)
		if("characteristics")
			if(stat_type)
				target.set_cy_base_stat(stat_type, value)
		if("combat_skills")
			if(skill_type)
				target.set_cy_skill_level(skill_type, value, TRUE)
		if("weapon_skills")
			if(skill_type)
				target.set_cy_skill_level(skill_type, value, TRUE)
		if("professional_skills")
			if(skill_type)
				target.set_cy_skill_level(skill_type, value, TRUE)

	var/list/dna_stats = target.dna.features[stat_group]
	if(!islist(dna_stats))
		dna_stats = list()
		target.dna.features[stat_group] = dna_stats
	dna_stats[stat_key] = value

/datum/preference/numeric/character_setup_stat/characteristic
	abstract_type = /datum/preference/numeric/character_setup_stat/characteristic
	minimum = CY_STAT_MINIMUM
	maximum = CY_STAT_MAXIMUM
	point_budget = CHARACTERISTIC_TOTAL_POINT_BUDGET
	stat_group = "characteristics"
	stat_peer_root = /datum/preference/numeric/character_setup_stat/characteristic

/datum/preference/numeric/character_setup_stat/characteristic/create_default_value()
	return CY_STAT_DEFAULT

/datum/preference/numeric/character_setup_stat/characteristic/strength
	savefile_key = "characteristic_strength"
	stat_key = "strength"
	stat_type = /datum/cy_stat/strength

/datum/preference/numeric/character_setup_stat/characteristic/dexterity
	savefile_key = "characteristic_dexterity"
	stat_key = "dexterity"
	stat_type = /datum/cy_stat/dexterity

/datum/preference/numeric/character_setup_stat/characteristic/perception
	savefile_key = "characteristic_perception"
	stat_key = "perception"
	stat_type = /datum/cy_stat/perception

/datum/preference/numeric/character_setup_stat/characteristic/intelligence
	savefile_key = "characteristic_intelligence"
	stat_key = "intelligence"
	stat_type = /datum/cy_stat/intelligence

/datum/preference/numeric/character_setup_stat/characteristic/spirit
	savefile_key = "characteristic_spirit"
	stat_key = "spirit"
	stat_type = /datum/cy_stat/spirit

/datum/preference/numeric/character_setup_stat/characteristic/charisma
	savefile_key = "characteristic_charisma"
	stat_key = "charisma"
	stat_type = /datum/cy_stat/charisma

/datum/preference/numeric/character_setup_stat/characteristic/luck
	savefile_key = "characteristic_luck"
	stat_key = "luck"
	stat_type = /datum/cy_stat/luck

/datum/preference/numeric/character_setup_stat/combat
	abstract_type = /datum/preference/numeric/character_setup_stat/combat
	maximum = CY_SKILL_MAXIMUM_LEVEL
	stat_group = "combat_skills"
	stat_peer_root = /datum/preference/numeric/character_setup_stat/combat

/datum/preference/numeric/character_setup_stat/combat/power_melee
	savefile_key = "combat_power_melee"
	stat_key = "power_melee"
	skill_type = /datum/cy_skill/strength/power_melee
	limiting_characteristic_key = "strength"

/datum/preference/numeric/character_setup_stat/combat/heavy_weapons
	savefile_key = "combat_heavy_weapons"
	stat_key = "heavy_weapons"
	skill_type = /datum/cy_skill/strength/heavy_weapons
	limiting_characteristic_key = "strength"

/datum/preference/numeric/character_setup_stat/combat/grappling
	savefile_key = "combat_grappling"
	stat_key = "grappling"
	skill_type = /datum/cy_skill/strength/grappling
	limiting_characteristic_key = "strength"

/datum/preference/numeric/character_setup_stat/combat/toughness
	savefile_key = "combat_toughness"
	stat_key = "toughness"
	skill_type = /datum/cy_skill/strength/toughness
	limiting_characteristic_key = "strength"

/datum/preference/numeric/character_setup_stat/combat/fast_melee
	savefile_key = "combat_fast_melee"
	stat_key = "fast_melee"
	skill_type = /datum/cy_skill/dexterity/fast_melee
	limiting_characteristic_key = "dexterity"

/datum/preference/numeric/character_setup_stat/combat/light_weapons
	savefile_key = "combat_light_weapons"
	stat_key = "light_weapons"
	skill_type = /datum/cy_skill/dexterity/light_weapons
	limiting_characteristic_key = "dexterity"

/datum/preference/numeric/character_setup_stat/combat/acrobatics
	savefile_key = "combat_acrobatics"
	stat_key = "acrobatics"
	skill_type = /datum/cy_skill/dexterity/acrobatics
	limiting_characteristic_key = "dexterity"

/datum/preference/numeric/character_setup_stat/combat/evasion
	savefile_key = "combat_evasion"
	stat_key = "evasion"
	skill_type = /datum/cy_skill/dexterity/evasion
	limiting_characteristic_key = "dexterity"

/datum/preference/numeric/character_setup_stat/combat/precise_melee
	savefile_key = "combat_precise_melee"
	stat_key = "precise_melee"
	skill_type = /datum/cy_skill/perception/precise_melee
	limiting_characteristic_key = "perception"

/datum/preference/numeric/character_setup_stat/combat/throwing
	savefile_key = "combat_throwing"
	stat_key = "throwing"
	skill_type = /datum/cy_skill/perception/throwing
	limiting_characteristic_key = "perception"

/datum/preference/numeric/character_setup_stat/combat/weakspot_analysis
	savefile_key = "combat_weakspot_analysis"
	stat_key = "weakspot_analysis"
	skill_type = /datum/cy_skill/perception/weakspot_analysis
	limiting_characteristic_key = "perception"

/datum/preference/numeric/character_setup_stat/combat/concentration
	savefile_key = "combat_concentration"
	stat_key = "concentration"
	skill_type = /datum/cy_skill/perception/concentration
	limiting_characteristic_key = "perception"

/datum/preference/numeric/character_setup_stat/combat/improved_code
	savefile_key = "combat_improved_code"
	stat_key = "improved_code"
	skill_type = /datum/cy_skill/intelligence/improved_code
	limiting_characteristic_key = "intelligence"

/datum/preference/numeric/character_setup_stat/combat/fast_code
	savefile_key = "combat_fast_code"
	stat_key = "fast_code"
	skill_type = /datum/cy_skill/intelligence/fast_code
	limiting_characteristic_key = "intelligence"

/datum/preference/numeric/character_setup_stat/combat/hacking
	savefile_key = "combat_hacking"
	stat_key = "hacking"
	skill_type = /datum/cy_skill/intelligence/hacking
	limiting_characteristic_key = "intelligence"

/datum/preference/numeric/character_setup_stat/combat/intelligence_composure
	savefile_key = "combat_intelligence_composure"
	stat_key = "intelligence_composure"
	skill_type = /datum/cy_skill/intelligence/composure
	limiting_characteristic_key = "intelligence"

/datum/preference/numeric/character_setup_stat/combat/survival
	savefile_key = "combat_survival"
	stat_key = "survival"
	skill_type = /datum/cy_skill/spirit/survival
	limiting_characteristic_key = "spirit"

/datum/preference/numeric/character_setup_stat/combat/endurance
	savefile_key = "combat_endurance"
	stat_key = "spirit_endurance"
	skill_type = /datum/cy_skill/spirit/endurance
	limiting_characteristic_key = "spirit"

/datum/preference/numeric/character_setup_stat/combat/athletics
	savefile_key = "combat_athletics"
	stat_key = "athletics"
	skill_type = /datum/cy_skill/spirit/athletics
	limiting_characteristic_key = "spirit"

/datum/preference/numeric/character_setup_stat/combat/compatibility
	savefile_key = "combat_compatibility"
	stat_key = "compatibility"
	skill_type = /datum/cy_skill/spirit/compatibility
	limiting_characteristic_key = "spirit"

/datum/preference/numeric/character_setup_stat/combat/stealth
	savefile_key = "combat_stealth"
	stat_key = "stealth"
	skill_type = /datum/cy_skill/charisma/stealth
	limiting_characteristic_key = "charisma"

/datum/preference/numeric/character_setup_stat/combat/theft
	savefile_key = "combat_theft"
	stat_key = "theft"
	skill_type = /datum/cy_skill/charisma/theft
	limiting_characteristic_key = "charisma"

/datum/preference/numeric/character_setup_stat/combat/inspiration
	savefile_key = "combat_inspiration"
	stat_key = "inspiration"
	skill_type = /datum/cy_skill/charisma/inspiration
	limiting_characteristic_key = "charisma"

/datum/preference/numeric/character_setup_stat/combat/style
	savefile_key = "combat_style"
	stat_key = "style"
	skill_type = /datum/cy_skill/charisma/style
	limiting_characteristic_key = "charisma"

/datum/preference/numeric/character_setup_stat/weapon
	abstract_type = /datum/preference/numeric/character_setup_stat/weapon
	maximum = CY_SKILL_MAXIMUM_LEVEL
	point_budget = WEAPON_SKILL_POINT_BUDGET
	stat_group = "weapon_skills"
	stat_peer_root = /datum/preference/numeric/character_setup_stat/weapon

/datum/preference/numeric/character_setup_stat/weapon/knives
	savefile_key = "weapon_knives"
	stat_key = "knives"
	skill_type = /datum/cy_skill/weapon/knives

/datum/preference/numeric/character_setup_stat/weapon/one_handed_chopping
	savefile_key = "weapon_one_handed_chopping"
	stat_key = "one_handed_chopping"
	skill_type = /datum/cy_skill/weapon/one_handed_chopping

/datum/preference/numeric/character_setup_stat/weapon/two_handed_chopping
	savefile_key = "weapon_two_handed_chopping"
	stat_key = "two_handed_chopping"
	skill_type = /datum/cy_skill/weapon/two_handed_chopping

/datum/preference/numeric/character_setup_stat/weapon/one_handed_piercing
	savefile_key = "weapon_one_handed_piercing"
	stat_key = "one_handed_piercing"
	skill_type = /datum/cy_skill/weapon/one_handed_piercing

/datum/preference/numeric/character_setup_stat/weapon/two_handed_piercing
	savefile_key = "weapon_two_handed_piercing"
	stat_key = "two_handed_piercing"
	skill_type = /datum/cy_skill/weapon/two_handed_piercing

/datum/preference/numeric/character_setup_stat/weapon/one_handed_slashing
	savefile_key = "weapon_one_handed_slashing"
	stat_key = "one_handed_slashing"
	skill_type = /datum/cy_skill/weapon/one_handed_slashing

/datum/preference/numeric/character_setup_stat/weapon/two_handed_slashing
	savefile_key = "weapon_two_handed_slashing"
	stat_key = "two_handed_slashing"
	skill_type = /datum/cy_skill/weapon/two_handed_slashing

/datum/preference/numeric/character_setup_stat/weapon/one_handed_blunt
	savefile_key = "weapon_one_handed_blunt"
	stat_key = "one_handed_blunt"
	skill_type = /datum/cy_skill/weapon/one_handed_blunt

/datum/preference/numeric/character_setup_stat/weapon/two_handed_blunt
	savefile_key = "weapon_two_handed_blunt"
	stat_key = "two_handed_blunt"
	skill_type = /datum/cy_skill/weapon/two_handed_blunt

/datum/preference/numeric/character_setup_stat/weapon/light_firearms
	savefile_key = "weapon_light_firearms"
	stat_key = "light_firearms"
	skill_type = /datum/cy_skill/weapon/light_firearms

/datum/preference/numeric/character_setup_stat/weapon/medium_firearms
	savefile_key = "weapon_medium_firearms"
	stat_key = "medium_firearms"
	skill_type = /datum/cy_skill/weapon/medium_firearms

/datum/preference/numeric/character_setup_stat/weapon/heavy_firearms
	savefile_key = "weapon_heavy_firearms"
	stat_key = "heavy_firearms"
	skill_type = /datum/cy_skill/weapon/heavy_firearms

/datum/preference/numeric/character_setup_stat/professional
	abstract_type = /datum/preference/numeric/character_setup_stat/professional
	maximum = CY_SKILL_MAXIMUM_LEVEL
	point_budget = PROFESSIONAL_SKILL_POINT_BUDGET
	stat_group = "professional_skills"
	stat_peer_root = /datum/preference/numeric/character_setup_stat/professional

/datum/preference/numeric/character_setup_stat/professional/electricity
	savefile_key = "professional_electricity"
	stat_key = "electricity"
	skill_type = /datum/cy_skill/professional/electricity

/datum/preference/numeric/character_setup_stat/professional/medicine
	savefile_key = "professional_medicine"
	stat_key = "medicine"
	skill_type = /datum/cy_skill/professional/medicine

/datum/preference/numeric/character_setup_stat/professional/chemistry
	savefile_key = "professional_chemistry"
	stat_key = "chemistry"
	skill_type = /datum/cy_skill/professional/chemistry

/datum/preference/numeric/character_setup_stat/professional/construction
	savefile_key = "professional_construction"
	stat_key = "construction"
	skill_type = /datum/cy_skill/professional/construction

/datum/preference/numeric/character_setup_stat/professional/invention
	savefile_key = "professional_invention"
	stat_key = "invention"
	skill_type = /datum/cy_skill/professional/invention

/datum/preference/numeric/character_setup_stat/professional/analysis
	savefile_key = "professional_analysis"
	stat_key = "analysis"
	skill_type = /datum/cy_skill/professional/analysis

/datum/preference/numeric/character_setup_stat/professional/mining
	savefile_key = "professional_mining"
	stat_key = "mining"
	skill_type = /datum/cy_skill/professional/mining

/datum/preference/numeric/character_setup_stat/professional/driving
	savefile_key = "professional_driving"
	stat_key = "driving"
	skill_type = /datum/cy_skill/professional/driving

/datum/preference/numeric/character_setup_stat/professional/cooking
	savefile_key = "professional_cooking"
	stat_key = "cooking"
	skill_type = /datum/cy_skill/professional/cooking

/datum/preference/numeric/character_setup_stat/professional/gardening
	savefile_key = "professional_gardening"
	stat_key = "gardening"
	skill_type = /datum/cy_skill/professional/gardening

/datum/preference/numeric/character_setup_stat/professional/music
	savefile_key = "professional_music"
	stat_key = "music"
	skill_type = /datum/cy_skill/professional/music

#undef CHARACTERISTIC_POINT_BUDGET
#undef CHARACTERISTIC_COUNT
#undef CHARACTERISTIC_TOTAL_POINT_BUDGET
#undef WEAPON_SKILL_POINT_BUDGET
#undef PROFESSIONAL_SKILL_POINT_BUDGET
