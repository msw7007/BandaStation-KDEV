/// Cold neurotherapy reduces treatable trauma resilience one tier at a time.
/datum/reagent/medicine/cryoneurine
	name = "Cryoneurine"
	description = "Cold neurotherapy which gradually makes severe brain traumas treatable, then cures them. Cannot restore lost brain capacity."
	color = "#a0c8e8"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	/// Effective seconds of cold treatment towards the next step.
	var/treatment_seconds = 0

/datum/reagent/medicine/cryoneurine/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, metabolization_ratio)
	. = ..()
	if(!iscarbon(affected_mob) || affected_mob.bodytemperature >= T0C)
		return
	var/obj/item/organ/brain/brain = affected_mob.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain || !(brain.organ_flags & affected_organ_flags))
		return
	treatment_seconds += seconds_per_tick * metabolization_ratio
	if(treatment_seconds < 20)
		return
	treatment_seconds -= 20
	for(var/datum/brain_trauma/trauma as anything in brain.traumas)
		if(trauma.resilience == TRAUMA_RESILIENCE_BASIC)
			qdel(trauma)
			return
		if(trauma.resilience == TRAUMA_RESILIENCE_SURGERY)
			trauma.resilience = TRAUMA_RESILIENCE_BASIC
			return

/datum/chemical_reaction/medicine/cryoneurine
	results = list(/datum/reagent/medicine/cryoneurine = 2)
	required_reagents = list(/datum/reagent/medicine/cryoxadone = 1, /datum/reagent/medicine/neurine = 1)
	required_temp = 280
	optimal_temp = 300
	overheat_temp = 400
	optimal_ph_min = 6
	optimal_ph_max = 8
	reaction_tags = REACTION_TAG_HEALING | REACTION_TAG_ORGAN

/// Cryoneurine treatment must not stop merely because the patient's body damage is already healed.
/obj/machinery/cryo_cell/proc/has_cryoneurine_treatment()
	if(!iscarbon(occupant))
		return FALSE
	var/mob/living/carbon/patient = occupant
	var/obj/item/organ/brain/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain || !(brain.organ_flags & ORGAN_ORGANIC))
		return FALSE
	if(!patient.reagents.has_reagent(/datum/reagent/medicine/cryoneurine) && !beaker?.reagents.has_reagent(/datum/reagent/medicine/cryoneurine))
		return FALSE
	for(var/datum/brain_trauma/trauma as anything in brain.traumas)
		if(trauma.resilience == TRAUMA_RESILIENCE_BASIC || trauma.resilience == TRAUMA_RESILIENCE_SURGERY)
			return TRUE
	return FALSE
