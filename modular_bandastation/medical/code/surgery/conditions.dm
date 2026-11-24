/// Medical stacks retain tenths for surgery; normal applications still require a whole unit.
/obj/item/stack/medical/is_zero_amount(delete_if_zero = TRUE)
	if(is_cyborg)
		return source.energy < cost * 0.1
	amount = round(amount, 0.1)
	if(amount > 0)
		return FALSE
	if(delete_if_zero)
		qdel(src)
	return TRUE

/datum/surgery_operation/basic/tend_wounds/proc/medical_supplies(mob/living/surgeon, list/operation_args)
	for(var/obj/item/stack/medical/supply in surgeon.get_held_items())
		if(supply.get_amount() < 0.1)
			continue
		if(operation_args[OPERATION_BRUTE_HEAL] && !supply.heal_brute && !supply.stop_bleeding)
			continue
		if(operation_args[OPERATION_BURN_HEAL] && !supply.heal_burn && !supply.flesh_regeneration)
			continue
		return supply
	return null

/datum/surgery_operation/basic/tend_wounds/operate_check(mob/living/patient, atom/movable/operating_on, mob/living/surgeon, tool, list/operation_args)
	return ..() && medical_supplies(surgeon, operation_args)

/datum/surgery_operation/basic/tend_wounds/pre_preop(atom/movable/operating_on, mob/living/surgeon, tool, list/operation_args)
	if(!medical_supplies(surgeon, operation_args))
		to_chat(surgeon, span_warning("Для лечения держите подходящий перевязочный материал в свободной руке."))
		return FALSE
	return ..()

/datum/surgery_operation/basic/tend_wounds/proc/consume_medical_supplies(mob/living/surgeon, list/operation_args)
	var/obj/item/stack/medical/supply = medical_supplies(surgeon, operation_args)
	return supply?.use(0.1)

/// Surgical contamination is cumulative and sampled before this step soils the surgeon.
/datum/surgery_operation/proc/apply_medical_contamination(atom/movable/operating_on, mob/living/patient, mob/living/surgeon, obj/item/tool, list/operation_args)
	var/obj/item/bodypart/limb
	if(isbodypart(operating_on))
		limb = operating_on
	else if(iscarbon(patient))
		var/mob/living/carbon/carbon = patient
		limb = carbon.get_bodypart(operation_args[OPERATION_TARGET_ZONE])
	if(!limb || !IS_ORGANIC_LIMB(limb))
		return
	var/exposure = 0
	for(var/obj/item/stack/medical/supply in surgeon.get_held_items())
		if(supply.medical_floor_contaminated)
			exposure += 10
	if(isitem(tool) && GET_ATOM_BLOOD_DNA_LENGTH(tool))
		exposure += 20
	var/obj/item/gloves = surgeon.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(!gloves || GET_ATOM_BLOOD_DNA_LENGTH(gloves))
		exposure += 20
	for(var/obj/item/clothing/clothing in surgeon.get_equipped_items())
		if(GET_ATOM_BLOOD_DNA_LENGTH(clothing))
			exposure += 5
	var/turf/surface = get_turf(limb)
	if(GET_ATOM_BLOOD_DNA_LENGTH(surface) || locate(/obj/effect/decal/cleanable/blood) in surface)
		exposure += 10
	for(var/obj/structure/table/table in surface)
		if(GET_ATOM_BLOOD_DNA_LENGTH(table))
			exposure += 20
	exposure *= clamp(time / (5 SECONDS), 0.5, 3)
	if(HAS_TRAIT(surgeon, TRAIT_PROFESSIONAL_SURGEON))
		exposure *= 0.5
	var/datum/component/medical_condition/condition = limb.get_medical_condition()
	condition.add_contamination(exposure)
	condition.add_pain(clamp(time / (1 SECONDS) * 2, 2, 30))

/obj/item/stack/medical
	/// Dropped supplies remain contaminated after being picked up, until sterilized.
	var/medical_floor_contaminated = FALSE

/obj/item/stack/medical/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	if(isturf(loc) && !(locate(/obj/structure/table) in loc))
		medical_floor_contaminated = TRUE

/obj/item/stack/medical/merge_without_del(obj/item/stack/target_stack, limit)
	. = ..()
	if(. && medical_floor_contaminated && istype(target_stack, /obj/item/stack/medical))
		var/obj/item/stack/medical/medical_target = target_stack
		medical_target.medical_floor_contaminated = TRUE

/obj/item/stack/medical/split_stack(amount)
	var/was_contaminated = medical_floor_contaminated
	. = ..()
	if(.)
		var/obj/item/stack/medical/split = .
		split.medical_floor_contaminated = was_contaminated

/datum/reagent/space_cleaner/sterilizine/expose_obj(obj/exposed_obj, reac_volume)
	. = ..()
	if(reac_volume > 0 && istype(exposed_obj, /obj/item/stack/medical))
		var/obj/item/stack/medical/supply = exposed_obj
		supply.medical_floor_contaminated = FALSE

/datum/surgery_operation/limb/reduce_incision
	name = "Уменьшить разрез"
	desc = "Свести края расширенного разреза гемостатом."
	implements = list(TOOL_HEMOSTAT = 1)
	time = 2 SECONDS
	operation_flags = OPERATION_NO_PATIENT_REQUIRED
	all_surgery_states_required = SURGERY_SKIN_OPEN
	any_surgery_states_blocked = SURGERY_BONE_SAWED | SURGERY_ORGANS_CUT

/datum/surgery_operation/limb/reduce_incision/get_default_radial_image()
	return image(/obj/item/hemostat)

/datum/surgery_operation/limb/reduce_incision/on_success(obj/item/bodypart/limb)
	limb.remove_surgical_state(SURGERY_SKIN_OPEN)
	limb.add_surgical_state(SURGERY_SKIN_CUT)

/datum/surgery_operation/limb/treat_necrosis
	name = "Удалить некротические ткани"
	desc = "Удалить отмершую ткань и заместить её синтплотью из ёмкости в свободной руке."
	implements = list(TOOL_HEMOSTAT = 1, TOOL_SCALPEL = 1.2, TOOL_WIRECUTTER = 2.5)
	time = 10 SECONDS
	operation_flags = OPERATION_AFFECTS_MOOD | OPERATION_NO_PATIENT_REQUIRED
	any_surgery_states_required = ALL_SURGERY_SKIN_STATES

/datum/surgery_operation/limb/treat_necrosis/get_default_radial_image()
	return image(/obj/item/hemostat)

/datum/surgery_operation/limb/treat_necrosis/state_check(obj/item/bodypart/limb)
	var/datum/component/medical_condition/condition = limb.get_medical_condition(FALSE)
	return condition?.infection_stage() == 4

/datum/surgery_operation/limb/treat_necrosis/operate_check(mob/living/patient, obj/item/bodypart/limb, mob/living/surgeon, tool, list/operation_args)
	var/obj/item/supply = surgeon.get_inactive_held_item()
	return ..() && supply?.reagents?.has_reagent(/datum/reagent/medicine/c2/synthflesh, 10)

/datum/surgery_operation/limb/treat_necrosis/on_success(obj/item/bodypart/limb, mob/living/surgeon)
	var/obj/item/supply = surgeon.get_inactive_held_item()
	if(!supply?.reagents?.has_reagent(/datum/reagent/medicine/c2/synthflesh, 10))
		return
	supply.reagents.remove_reagent(/datum/reagent/medicine/c2/synthflesh, 10)
	limb.get_medical_condition().treat_infection(INFINITY, critical = TRUE)
	limb.receive_damage(5, wound_bonus = CANT_WOUND)

/datum/surgery_operation/limb/treat_necrosis/on_failure(obj/item/bodypart/limb)
	limb.receive_damage(10, wound_bonus = CANT_WOUND)
