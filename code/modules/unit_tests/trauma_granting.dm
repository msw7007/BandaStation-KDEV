/// Tests that brain traumas can be granted and removed properly.
/datum/unit_test/trauma_granting

/datum/unit_test/trauma_granting/Run()

	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human/consistent)
	// It's not stricly necessary a mob must have a mind, but some traumas do extra stuff if you have mind.
	dummy.mind_initialize()

	// Following includes some traumas that would require special handling to test.
	var/list/trauma_blacklist = list()
	// Requires a phase be set in New
	trauma_blacklist += typesof(/datum/brain_trauma/hypnosis)
	// Requires another player, sleeps in gain()
	trauma_blacklist += typesof(/datum/brain_trauma/severe/split_personality)
	// Requires another player, sleeps in gain()
	trauma_blacklist += typesof(/datum/brain_trauma/special/imaginary_friend)
	// Requires a obsession target
	trauma_blacklist += typesof(/datum/brain_trauma/special/obsessed)

	for(var/datum/brain_trauma/trauma as anything in valid_subtypesof(/datum/brain_trauma) - trauma_blacklist)
		test_trauma(dummy, trauma)

/datum/unit_test/trauma_granting/proc/test_trauma(mob/living/carbon/human/dummy, trauma)
	dummy.gain_trauma(trauma)
	TEST_ASSERT(dummy.has_trauma_type(trauma), "Brain trauma [trauma] failed to grant to dummy")
	dummy.cure_trauma_type(trauma, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(!dummy.has_trauma_type(trauma), "Brain trauma [trauma] failed to cure from dummy")

/datum/unit_test/cyberpunk_genetic_tumor_clock/Run()
	var/mob/living/carbon/human/consistent/patient = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/obj/item/organ/brain/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
	var/obj/item/organ/old_zombie_slot = patient.get_organ_slot(ORGAN_SLOT_ZOMBIE)
	TEST_ASSERT(patient.apply_genetic_tumor(), "Genetic collapse must grant a brain trauma.")
	var/datum/brain_trauma/special/genetic_tumor/tumor = locate() in brain.traumas
	TEST_ASSERT(tumor, "The tumor must belong to the brain, not a separate organ slot.")
	TEST_ASSERT_EQUAL(patient.get_organ_slot(ORGAN_SLOT_ZOMBIE), old_zombie_slot, "The zombie slot must not be changed.")
	tumor.on_life(GENETIC_TUMOR_SEVERITY_INTERVAL / (1 SECONDS))
	TEST_ASSERT_EQUAL(tumor.severity_stage, 2, "Tumor severity must change during dormancy.")
	TEST_ASSERT_EQUAL(tumor.growth, 0, "Dormant tumors must not grow.")
	var/remaining = tumor.dormant_remaining
	var/mob/living/basic/visceroid/host = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	patient.forceMove(host)
	tumor.on_life(100)
	TEST_ASSERT_EQUAL(tumor.dormant_remaining, remaining, "Visceroid containment must pause the remaining dormancy.")
	TEST_ASSERT_EQUAL(tumor.severity_stage, 2, "Visceroid containment must pause severity changes.")
	patient.forceMove(run_loc_floor_bottom_left)
	tumor.reset_dormancy(0)
	tumor.on_life(1)
	TEST_ASSERT(tumor.growth > 0, "Tumor growth must resume outside the visceroid.")
	brain.Remove(patient)
	TEST_ASSERT(tumor in brain.traumas, "Removing the brain must retain its tumor.")
	var/growth = tumor.growth
	tumor.on_life(10)
	TEST_ASSERT_EQUAL(tumor.growth, growth, "An extracted brain must not advance the tumor clock.")
	var/mob/living/carbon/human/consistent/recipient = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/obj/item/organ/brain/replaced_brain = recipient.get_organ_slot(ORGAN_SLOT_BRAIN)
	replaced_brain.Remove(recipient)
	qdel(replaced_brain)
	brain.Insert(recipient)
	TEST_ASSERT_EQUAL(tumor.owner, recipient, "The tumor must follow a transplanted brain.")
	TEST_ASSERT_EQUAL(tumor.growth, growth, "Transplantation must preserve tumor progress.")
