/obj/item/organ/genetic_tumor
	name = "genetic tumor"
	desc = "A self-developing genetic lesion left by a visceroid collapse."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_ZOMBIE
	icon_state = "blacktumor"
	organ_flags = ORGAN_ORGANIC
	var/growth = 0
	var/dormant_until = 0
	var/next_severity_shift = 0
	var/severity_stage = 1

/obj/item/organ/genetic_tumor/Initialize(mapload, dormant_time = GENETIC_TUMOR_DORMANT_TIME)
	. = ..()
	reset_dormancy(dormant_time)
	if(iscarbon(loc))
		Insert(loc)

/obj/item/organ/genetic_tumor/proc/reset_dormancy(dormant_time = GENETIC_TUMOR_DORMANT_TIME)
	growth = 0
	dormant_until = world.time + dormant_time
	next_severity_shift = world.time + GENETIC_TUMOR_SEVERITY_INTERVAL

/obj/item/organ/genetic_tumor/on_mob_insert(mob/living/carbon/new_owner, special = FALSE, movement_flags)
	. = ..()
	START_PROCESSING(SSobj, src)
	addtimer(CALLBACK(src, PROC_REF(migrate_to_brain)), 0)

/obj/item/organ/genetic_tumor/on_mob_remove(mob/living/carbon/old_owner, special = FALSE, movement_flags)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/organ/genetic_tumor/feel_for_damage(self_aware)
	return self_aware ? "something inside your skull is growing in the wrong direction" : "a dense genetic tumor is tangled around the brain"

/obj/item/organ/genetic_tumor/process(seconds_per_tick)
	migrate_to_brain()

/// Compatibility for old mapped/admin-spawned organs; new infections live on the brain.
/obj/item/organ/genetic_tumor/proc/migrate_to_brain()
	if(!owner || !ishuman(owner))
		return FALSE
	var/obj/item/organ/brain/brain = owner.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(!brain)
		return FALSE
	var/datum/brain_trauma/special/genetic_tumor/trauma = locate() in brain.traumas
	if(!trauma)
		trauma = owner.gain_trauma(/datum/brain_trauma/special/genetic_tumor, TRAUMA_RESILIENCE_BASIC, max(0, dormant_until - world.time))
		if(!trauma)
			return FALSE
		trauma.growth = growth
		trauma.severity_stage = clamp(severity_stage, 1, 3)
		trauma.update_severity_resilience()
	Remove(owner)
	qdel(src)
	return TRUE
