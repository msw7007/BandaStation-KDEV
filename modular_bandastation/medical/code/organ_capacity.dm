/// The recipient retains surgical wear even while an organ slot is empty.
/mob/living/carbon
	var/list/organ_capacity_by_slot

/obj/item/organ
	/// Remaining fraction of the organ's capacity after restorative surgery.
	var/medical_capacity = 1
	/// Existing medicine which enables capacity restoration alongside cryoxadone in a cryo cell.
	var/cryo_capacity_reagent

/obj/item/organ/liver
	cryo_capacity_reagent = /datum/reagent/medicine/higadrite

/obj/item/organ/lungs
	cryo_capacity_reagent = /datum/reagent/medicine/polypyr

/obj/item/organ/heart
	cryo_capacity_reagent = /datum/reagent/nitroglycerin

/obj/item/organ/stomach
	cryo_capacity_reagent = /datum/reagent/medicine/ondansetron

/obj/item/organ/eyes
	cryo_capacity_reagent = /datum/reagent/medicine/oculine

/obj/item/organ/ears
	cryo_capacity_reagent = /datum/reagent/medicine/inacusiate

/obj/item/organ/appendix
	cryo_capacity_reagent = /datum/reagent/medicine/spaceacillin

/obj/item/organ/tongue
	cryo_capacity_reagent = /datum/reagent/medicine/c2/synthflesh

/// Shared capacity report for living-patient and autopsy scanners; phantom damage remains indistinguishable.
/obj/item/organ/proc/get_capacity_status(scanpower)
	if(slot == ORGAN_SLOT_BRAIN)
		var/obj/item/organ/brain/brain = src
		if(brain.maxHealth <= 0)
			return "Запас восстановления мозга исчерпан."
		if(brain.requires_reconstruction)
			return "Требуется восстановление разрушенного мозга. Остаточный максимум: [round(maxHealth, 0.1)]."
		if(maxHealth >= initial(maxHealth))
			return
	else if(medical_capacity >= 1)
		return
	if(scanpower < SCANPOWER_ADVANCED)
		return "Снижен запас прочности органа."
	return "Максимальный запас прочности: [round(maxHealth, 0.1)]."

/// Sets surgical capacity without changing damage or undoing unrelated maximum-health adjustments.
/obj/item/organ/proc/set_medical_capacity(new_capacity)
	if(slot == ORGAN_SLOT_BRAIN || new_capacity <= 0 || new_capacity > 1)
		return FALSE
	var/multiplier = new_capacity / medical_capacity
	var/old_low_threshold = low_threshold
	var/old_high_threshold = high_threshold
	maxHealth *= multiplier
	low_threshold *= multiplier
	high_threshold *= multiplier
	medical_capacity = new_capacity
	if(owner && slot)
		LAZYSET(owner.organ_capacity_by_slot, slot, medical_capacity)
	if(damage > low_threshold && damage <= old_low_threshold)
		on_low_damage_received()
	else if(damage <= low_threshold && damage > old_low_threshold)
		on_low_damage_healed()
	if(damage > high_threshold && damage <= old_high_threshold)
		on_high_damage_received()
	else if(damage <= high_threshold && damage > old_high_threshold)
		on_high_damage_healed()
	if(damage >= maxHealth && !(organ_flags & ORGAN_FAILING))
		organ_flags |= ORGAN_FAILING
		on_begin_failure()
	else if(damage < maxHealth && (organ_flags & ORGAN_FAILING) && !(organ_flags & ORGAN_EMP))
		organ_flags &= ~ORGAN_FAILING
		on_failure_recovery()
	return TRUE

/// Transplants inherit the worse of the donor organ's wear and the recipient slot's wear.
/obj/item/organ/proc/inherit_medical_capacity()
	if(slot == ORGAN_SLOT_BRAIN || !slot || !owner)
		return
	var/recipient_capacity = LAZYACCESS(owner.organ_capacity_by_slot, slot)
	if(isnull(recipient_capacity))
		recipient_capacity = 1
	set_medical_capacity(min(medical_capacity, recipient_capacity))

/// Restores only organic non-brain organs with their matching medicine, inside an active therapeutic cell.
/mob/living/carbon/proc/restore_cryo_organ_capacity(seconds_per_tick)
	if(!istype(loc, /obj/machinery/cryo_cell))
		return
	var/obj/machinery/cryo_cell/cell = loc
	if(!cell.on || cell.occupant != src)
		return
	for(var/obj/item/organ/organ as anything in organs)
		if(organ.medical_capacity >= 1 || !(organ.organ_flags & ORGAN_ORGANIC) || !organ.cryo_capacity_reagent)
			continue
		if(!reagents.has_reagent(organ.cryo_capacity_reagent))
			continue
		organ.set_medical_capacity(min(1, organ.medical_capacity + 0.0025 * seconds_per_tick))

/// Keeps an otherwise healed patient in cryo when the supplied combination can still restore an organ.
/obj/machinery/cryo_cell/proc/has_organ_capacity_treatment()
	if(!iscarbon(occupant))
		return FALSE
	var/mob/living/carbon/patient = occupant
	if(!patient.reagents.has_reagent(/datum/reagent/medicine/cryoxadone) && !beaker?.reagents.has_reagent(/datum/reagent/medicine/cryoxadone))
		return FALSE
	for(var/obj/item/organ/organ as anything in patient.organs)
		if(organ.medical_capacity >= 1 || !(organ.organ_flags & ORGAN_ORGANIC) || !organ.cryo_capacity_reagent)
			continue
		if(patient.reagents.has_reagent(organ.cryo_capacity_reagent) || beaker?.reagents.has_reagent(organ.cryo_capacity_reagent))
			return TRUE
	return FALSE
