#define SURGERY_TOOL_MOD_GHETTO 10
#define SURGERY_TOOL_MOD_ADVANCED 0
#define SURGERY_TOOL_MOD_ALIEN 1
#define SURGERY_TOOL_MOD_AUGMENT 0
#define SURGERY_TOOL_MOD_BASIC 5
#define SURGERY_RING_FAIL_MOD 10

/datum/surgery_operation/proc/get_modified_failure_chance(operation_time, mob/living/patient, mob/living/surgeon, tool, list/operation_args)
	var/fail_chance = clamp(GET_FAILURE_CHANCE(operation_time, operation_args[OPERATION_SPEED]), 0, 99)

	// Боль
	if(patient && patient.stat < HARD_CRIT && !HAS_TRAIT(patient, TRAIT_PAIN_NUMB))
		if(iscarbon(patient))
			var/mob/living/carbon/carbon = patient
			fail_chance += 40 * (1 - carbon.medical_analgesia(operation_args[OPERATION_TARGET_ZONE]))
		else if(!HAS_TRAIT(patient, TRAIT_ANALGESIA))
			fail_chance += 40
	if(HAS_TRAIT(surgeon, TRAIT_MEDICAL_TRAINING))
		fail_chance -= 10
	if(HAS_TRAIT(surgeon, TRAIT_PROFESSIONAL_SURGEON))
		fail_chance -= 15
	if(patient)
		var/turf/operation_turf = get_turf(patient)
		if(!(locate(/obj/structure/table/optable) in operation_turf) && !(locate(/obj/machinery/stasis) in operation_turf))
			fail_chance += time >= 5 SECONDS ? 20 : 10

	// Свет или абдуктор
	if(!(surgeon.has_nightvision() || isabductor(surgeon)))
		var/turf/patient_turf = get_turf(patient || surgeon)
		var/light_amount = patient_turf.get_lumcount() // минимальное кол-во света для успеха - 0.6
		if(light_amount < 0.6)
			fail_chance += (1.0 - (light_amount / 0.6))**1.5 * 60.0

	// Инструменты
	var/tool_mod = 0
	if(isitem(tool) || tool_check(tool))
		var/obj/item/realtool = tool
		var/tool_type = realtool.type
		if(get_tool_quality(realtool) > 1.15) // чек на гетто инструмент
			tool_mod = SURGERY_TOOL_MOD_GHETTO
		else
			if(findtext("[tool_type]", "/advanced"))
				tool_mod = SURGERY_TOOL_MOD_ADVANCED
			else if(findtext("[tool_type]", "/alien"))
				tool_mod = SURGERY_TOOL_MOD_ALIEN
			else if(findtext("[tool_type]", "/augment"))
				tool_mod = SURGERY_TOOL_MOD_AUGMENT
			else
				tool_mod = SURGERY_TOOL_MOD_BASIC

	fail_chance += tool_mod

	// Кольцо на перчатках ухудшает точность работы
	var/obj/item/clothing/gloves/worn_gloves = surgeon.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(istype(worn_gloves) && locate(/obj/item/clothing/accessory/gloves_accessory/ring) in worn_gloves.attached_accessories)
		fail_chance += SURGERY_RING_FAIL_MOD - 5

	return clamp(fail_chance, 0, 100)

#undef SURGERY_TOOL_MOD_GHETTO
#undef SURGERY_TOOL_MOD_ADVANCED
#undef SURGERY_TOOL_MOD_ALIEN
#undef SURGERY_TOOL_MOD_AUGMENT
#undef SURGERY_TOOL_MOD_BASIC
#undef SURGERY_RING_FAIL_MOD
