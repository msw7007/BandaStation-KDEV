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

/obj/item/organ/genetic_tumor/on_mob_remove(mob/living/carbon/old_owner, special = FALSE, movement_flags)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/organ/genetic_tumor/feel_for_damage(self_aware)
	return self_aware ? "something inside your skull is growing in the wrong direction" : "a dense genetic tumor is tangled around the brain"

/obj/item/organ/genetic_tumor/process(seconds_per_tick)
	if(!owner)
		return
	if(!(src in owner.organs))
		Remove(owner)
		return
	if(owner.stat == DEAD)
		return
	if(istype(owner.loc, /mob/living/basic/visceroid))
		return
	if(world.time < dormant_until)
		return
	if(world.time >= next_severity_shift)
		severity_stage = min(severity_stage + 1, 3)
		next_severity_shift = world.time + GENETIC_TUMOR_SEVERITY_INTERVAL
		to_chat(owner, span_warning("The genetic tumor shifts inside your skull."))
	growth += (HUMANOIDITY_DEFAULT / (GENETIC_TUMOR_GROWTH_TIME / (1 SECONDS))) * seconds_per_tick
	if(growth < HUMANOIDITY_DEFAULT)
		return
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.cy_check_humanoidity_collapse(force = TRUE)
