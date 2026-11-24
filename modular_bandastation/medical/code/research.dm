/datum/design/medical_overhaul
	abstract_type = /datum/design/medical_overhaul
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT)
	category = list(RND_CATEGORY_TOOLS + RND_SUBCATEGORY_TOOLS_MEDICAL)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/medical_overhaul/compressor
	name = "Автокомпрессор"
	build_path = /obj/item/clothing/suit/autocompressor
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT)

/datum/design/medical_overhaul/medical_chip
	name = "Медицинский скилл-чип"
	build_path = /obj/item/skillchip/medical
	materials = list(/datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT)

/datum/design/medical_overhaul/wound_analyzer
	name = "Анализатор ранений"
	build_path = /obj/item/healthanalyzer/wound

/datum/design/medical_overhaul/hemo_analyzer
	name = "Гемоанализатор"
	build_path = /obj/item/healthanalyzer/hemo

/datum/design/medical_overhaul/paramedic_terminal
	name = "Терминал парамедика"
	build_path = /obj/item/medical_terminal

/datum/design/board/medical_station
	name = "СДУ"
	build_path = /obj/item/circuitboard/machine/medical_station
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_MEDICAL)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/design/board/medical_station/nerv
	name = "Нейрологический стол N.E.R.V."
	build_path = /obj/item/circuitboard/machine/medical_station/nerv
	materials = list(/datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/diamond = SHEET_MATERIAL_AMOUNT, /datum/material/bluespace = HALF_SHEET_MATERIAL_AMOUNT)

/datum/design/board/medical_station/cryostasis
	name = "Камера криостазиса"
	build_path = /obj/item/circuitboard/machine/medical_station/cryostasis

/datum/design/board/medical_station/self_analyzer
	name = "Медицинский самоанализатор"
	build_path = /obj/item/circuitboard/machine/medical_station/self_analyzer

/datum/design/board/medical_network
	name = "Врачебный терминал"
	build_path = /obj/item/circuitboard/computer/medical_network
	category = list(RND_CATEGORY_COMPUTER + RND_SUBCATEGORY_COMPUTER_MEDICAL)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL

/datum/preference/choiced/medical_blood_group
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "medical_blood_group"
	savefile_identifier = PREFERENCE_CHARACTER

/datum/preference/choiced/medical_blood_group/init_possible_values()
	return list("Случайная", "O", "A", "B", "AB")

/datum/preference/choiced/medical_blood_group/create_default_value()
	return "Случайная"

/datum/preference/choiced/medical_blood_group/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	if(value == "Случайная" || !istype(target.get_bloodtype(), /datum/blood_type/human))
		return
	var/list/groups = list(
		"O" = list(/datum/blood_type/human/o_plus, /datum/blood_type/human/o_minus),
		"A" = list(/datum/blood_type/human/a_plus, /datum/blood_type/human/a_minus),
		"B" = list(/datum/blood_type/human/b_plus, /datum/blood_type/human/b_minus),
		"AB" = list(/datum/blood_type/human/ab_plus, /datum/blood_type/human/ab_minus),
	)
	var/list/selected = groups[value]
	if(selected)
		target.set_blood_type(pick(selected))
