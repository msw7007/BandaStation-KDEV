#define TEST_ORGAN_INSERT_MESSAGE(test_organ, message) "`[test_organ.type]/Insert()` [message]"
#define TEST_ORGAN_REMOVE_MESSAGE(test_organ, message) "`[test_organ.type]/Remove()` [message]"

/// Check organ insertion and removal, for all organ subtypes usable in-game.
/// Ensures algorithmic correctness of the "Insert()" and "Remove()" procs.
/// This test is especially useful because developers frequently  override those.
/datum/unit_test/organ_sanity
	// List of organ typepaths which cause species change.
	// Species change swaps out all the organs, making test_organ un-usable after insertion.
	var/static/list/species_changing_organs = typecacheof(list(
		/obj/item/organ/brain/shadow/nightmare,
	))

/datum/unit_test/organ_sanity/Run()
	for(var/obj/item/organ/organ_type as anything in subtypesof(/obj/item/organ) - GLOB.prototype_organs)
		organ_test_insert(organ_type)

/datum/unit_test/organ_sanity/proc/organ_test_insert(obj/item/organ/organ_type)
	// Appropriate mob (Human) which will receive organ.
	var/mob/living/carbon/human/lab_rat = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/organ/test_organ = new organ_type()

	// Inappropriate mob (Dog) which will hopefully reject organ.
	var/mob/living/basic/pet/dog/lab_dog = allocate(/mob/living/basic/pet/dog/corgi)
	var/obj/item/organ/reject_organ = new organ_type()

	TEST_ASSERT(test_organ.Insert(lab_rat, special = TRUE, movement_flags = DELETE_IF_REPLACED), TEST_ORGAN_INSERT_MESSAGE(test_organ, "should return TRUE to indicate success."))
	TEST_ASSERT(!reject_organ.Insert(lab_dog, special = TRUE, movement_flags = DELETE_IF_REPLACED), TEST_ORGAN_INSERT_MESSAGE(test_organ, "shouldn't return TRUE when inserting into a basic mob (Corgi)."))

	// Species change swaps out all the organs, making test_organ un-usable by this point.
	if(species_changing_organs[test_organ.type])
		return

	TEST_ASSERT(test_organ.owner == lab_rat, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should assign the human to the organ's `owner` var."))
	TEST_ASSERT(test_organ in lab_rat.organs, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should insert the organ into the human's `internal_organs` list."))
	if(test_organ.slot)
		TEST_ASSERT(lab_rat.organs_slot[test_organ.slot] == test_organ, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add the organ to the human's `internal_organs_slot` list."))
		TEST_ASSERT(lab_rat.get_organ_slot(test_organ.slot) == test_organ, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should make the organ available via human's `get_organ_slot()` proc."))

	if(LAZYLEN(test_organ.organ_traits))
		TEST_ASSERT(LAZYLEN(lab_rat._status_traits), TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Traits to lazylist `human._status_traits`."))
		for(var/test_trait in test_organ.organ_traits)
			TEST_ASSERT(HAS_TRAIT(lab_rat, test_trait), TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Trait `[test_trait]` to lazylist `human._status_traits`"))

	if(LAZYLEN(test_organ.actions))
		TEST_ASSERT(LAZYLEN(lab_rat.actions), TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Actions to lazylist `human.actions`."))
		for(var/datum/action/test_action as anything in test_organ.actions)
			TEST_ASSERT(test_action in lab_rat.actions, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Action `[test_action]` to lazylist `human.actions`."))

	if(LAZYLEN(test_organ.organ_effects))
		TEST_ASSERT(LAZYLEN(lab_rat.status_effects), TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Status Effects to lazylist `human.status_effects`."))
		for(var/datum/status_effect/test_status as anything in test_organ.organ_effects)
			TEST_ASSERT(test_status in lab_rat.status_effects, TEST_ORGAN_INSERT_MESSAGE(test_organ, "should add Status Effect `[test_status]` to lazylist `human.status_effects`."))

	test_organ.Remove(lab_rat, special = TRUE)

	TEST_ASSERT(test_organ.owner == null, TEST_ORGAN_REMOVE_MESSAGE(test_organ, "should assign the organ's `owner` var to null."))
	TEST_ASSERT(!(test_organ in lab_rat.organs), TEST_ORGAN_REMOVE_MESSAGE(test_organ, "should remove the organ from the human's `internal_organs` list."))
	if(test_organ.slot)
		TEST_ASSERT(lab_rat.organs_slot[test_organ.slot] != test_organ, TEST_ORGAN_REMOVE_MESSAGE(test_organ, "should remove the organ from the human's `internal_organs_slot` list."))
		TEST_ASSERT(lab_rat.get_organ_slot(test_organ.slot) != test_organ, TEST_ORGAN_REMOVE_MESSAGE(test_organ, "should remove the organ from the human's `get_organ_slot()` proc."))

	return

#undef TEST_ORGAN_INSERT_MESSAGE
#undef TEST_ORGAN_REMOVE_MESSAGE

/datum/unit_test/cyberpunk_implant_emp_reboot/Run()
	TEST_ASSERT_EQUAL(IMPLANT_EMP_REBOOT_INTERVAL, 1 MINUTES, "EMP reboot attempts must be one minute apart.")
	TEST_ASSERT_EQUAL(IMPLANT_EMP_REBOOT_CHANCE, 1, "Each EMP reboot attempt must have a one percent chance.")
	var/obj/item/organ/cyberimp/brain/neural_interface/organ = allocate(__IMPLIED_TYPE__)
	var/obj/item/implant/implant = allocate(__IMPLIED_TYPE__)
	organ.disable_implant(reason = "EMP")
	implant.disable_implant(reason = "EMP")
	var/organ_timer = organ.implant_emp_reboot_timer
	var/implant_timer = implant.implant_emp_reboot_timer
	TEST_ASSERT_EQUAL(organ.implant_emp_reboot_at, world.time + 1 MINUTES, "The first organ reboot must wait a full minute.")
	TEST_ASSERT_EQUAL(implant.implant_emp_reboot_at, world.time + 1 MINUTES, "The first legacy implant reboot must wait a full minute.")
	TEST_ASSERT(!organ.attempt_implant_emp_reboot(), "An early organ check must not roll for a reboot.")
	TEST_ASSERT(!implant.attempt_implant_emp_reboot(), "An early legacy implant check must not roll for a reboot.")
	TEST_ASSERT_EQUAL(organ.implant_emp_reboot_timer, organ_timer, "Early polling must not replace the organ timer.")
	TEST_ASSERT_EQUAL(implant.implant_emp_reboot_timer, implant_timer, "Early polling must not replace the legacy implant timer.")
	organ.implant_disabled_until = world.time - 1
	implant.implant_disabled_until = world.time - 1
	TEST_ASSERT(organ.is_implant_disabled(), "An elapsed temporary timer must not clear organ EMP shutdown.")
	TEST_ASSERT(implant.is_implant_disabled(), "An elapsed temporary timer must not clear legacy EMP shutdown.")
	organ.apply_organ_damage(10)
	organ.disable_implant(10 MINUTES, "overheat")
	var/temporary_deadline = organ.implant_disabled_until
	organ.implant_emp_reboot_at = world.time - 1
	var/restarted = organ.attempt_implant_emp_reboot()
	if(restarted)
		TEST_ASSERT_EQUAL(organ.implant_emp_reboot_at, 0, "A successful roll must clear EMP shutdown.")
		TEST_ASSERT_NULL(organ.implant_emp_reboot_timer, "A successful roll must stop future attempts.")
	else
		TEST_ASSERT_EQUAL(organ.implant_emp_reboot_at, world.time + 1 MINUTES, "A failed roll must schedule another minute, not restore the organ.")
		TEST_ASSERT(organ.implant_emp_reboot_timer, "A failed roll must keep a pending reboot timer.")
	TEST_ASSERT_EQUAL(organ.damage, 10, "A reboot must not repair physical damage.")
	TEST_ASSERT_EQUAL(organ.implant_disabled_until, temporary_deadline, "A reboot must not clear unrelated temporary shutdown.")
	var/datum/surgery_operation/organ/repair/implant/retune/unit_test/operation = allocate(__IMPLIED_TYPE__)
	TEST_ASSERT(operation.test_retune(organ), "A disabled implant must offer surgical retuning.")
	TEST_ASSERT(!organ.is_implant_disabled(), "Successful surgery must immediately retune the organ.")
	TEST_ASSERT_NULL(organ.implant_emp_reboot_timer, "Surgery must cancel the pending reboot.")
	TEST_ASSERT_EQUAL(organ.damage, 10, "Retuning must not repair physical damage.")
	implant.retune_implant()
	TEST_ASSERT(!implant.is_implant_disabled(), "Manual retuning must immediately restart a legacy implant.")
	TEST_ASSERT_NULL(implant.implant_emp_reboot_timer, "Retuning must cancel the legacy implant timer.")
	TEST_ASSERT(!organ.attempt_implant_emp_reboot() && !implant.attempt_implant_emp_reboot(), "Stale callbacks must not schedule attempts after retuning.")

/datum/surgery_operation/organ/repair/implant/retune/unit_test
	abstract_type = /datum/surgery_operation/organ/repair/implant/retune/unit_test

/datum/surgery_operation/organ/repair/implant/retune/unit_test/proc/test_retune(obj/item/organ/organ)
	if(!state_check(organ))
		return FALSE
	on_success(organ)
	return TRUE

/datum/unit_test/cyberpunk_implant_electric_retune/Run()
	var/mob/living/carbon/human/consistent/patient = allocate(__IMPLIED_TYPE__, run_loc_floor_bottom_left)
	var/obj/item/organ/cyberimp/brain/neural_interface/organ = allocate(__IMPLIED_TYPE__)
	TEST_ASSERT(organ.Insert(patient), "A neural implant must be insertable for the electric restart test.")
	var/obj/item/implant/implant = allocate(__IMPLIED_TYPE__)
	implant.requires_neural_interface = TRUE
	TEST_ASSERT(implant.implant(patient, silent = TRUE), "A legacy implant must be insertable for the electric restart test.")
	organ.disable_implant(reason = "EMP")
	implant.disable_implant(reason = "EMP")
	TEST_ASSERT(!patient.retune_implants_from_electricity(0), "An absent electrical pulse must not restart implants.")
	TEST_ASSERT(patient.retune_implants_from_electricity(30), "A real electrical pulse must retune EMP-disabled implants.")
	TEST_ASSERT(!organ.is_implant_disabled() && !implant.is_implant_disabled(), "Electricity must immediately clear both kinds of EMP shutdown.")
	TEST_ASSERT_NULL(organ.implant_emp_reboot_timer, "Electricity must cancel the organ reboot timer.")
	TEST_ASSERT_NULL(implant.implant_emp_reboot_timer, "Electricity must cancel the legacy reboot timer.")

/// Tests organ damage cap.
/// Organ damage should never bypass the cap.
/// Every internal organ is tested.
/datum/unit_test/organ_damage

/datum/unit_test/organ_damage/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human/consistent)
	for(var/obj/item/organ/organ_to_test in dummy.organs)
		test_organ(dummy, organ_to_test)

/datum/unit_test/organ_damage/proc/test_organ(mob/living/carbon/human/dummy, obj/item/organ/test_organ)
	var/slot_to_use = test_organ.slot

	// Tests [mob/living/proc/adjust_organ_loss]
	TEST_ASSERT_EQUAL(dummy.adjust_organ_loss(slot_to_use, test_organ.maxHealth * 10), -test_organ.maxHealth, \
		"Mob level \"apply organ damage\" returned the wrong value for [slot_to_use] organ with default arguments.")
	TEST_ASSERT_EQUAL(dummy.get_organ_loss(slot_to_use), test_organ.maxHealth, \
		"Mob level \"apply organ damage\" can exceed the [slot_to_use] organ's damage cap with default arguments.")
	TEST_ASSERT_EQUAL(dummy.get_organ_loss(slot_to_use, required_organ_flag = test_organ.organ_flags), test_organ.maxHealth, \
		"(Testing get_organ_loss() with required_organ_flag = [test_organ.organ_flags]) \
			Mob level \"apply organ damage\" can exceed the [slot_to_use] organ's damage cap with default arguments.")
	dummy.fully_heal(HEAL_ORGANS)

	// Tests [mob/living/proc/set_organ_damage]
	TEST_ASSERT_EQUAL(dummy.set_organ_loss(slot_to_use, test_organ.maxHealth * 10), -test_organ.maxHealth, \
		"Mob level \"set organ damage\" returned the wrong value for [slot_to_use] organ with default arguments.")
	TEST_ASSERT_EQUAL(dummy.get_organ_loss(slot_to_use), test_organ.maxHealth, \
		"Mob level \"set organ damage\" can exceed the [slot_to_use] organ's damage cap with default arguments.")
	dummy.fully_heal(HEAL_ORGANS)

	// Tests [mob/living/proc/adjust_organ_loss] with a large max supplied
	TEST_ASSERT_EQUAL(dummy.adjust_organ_loss(slot_to_use, test_organ.maxHealth * 10, INFINITY), -test_organ.maxHealth, \
		"Mob level \"apply organ damage\" returned the wrong value for [slot_to_use] organ with a large maximum supplied.")
	TEST_ASSERT_EQUAL(dummy.get_organ_loss(slot_to_use), test_organ.maxHealth, \
		"Mob level \"apply organ damage\" can exceed the [slot_to_use] organ's damage cap with a large maximum supplied.")
	TEST_ASSERT_EQUAL(dummy.get_organ_loss(slot_to_use, required_organ_flag = test_organ.organ_flags), test_organ.maxHealth, \
		"(Testing get_organ_loss() with required_organ_flag = [test_organ.organ_flags]) \
			Mob level \"apply organ damage\" can exceed the [slot_to_use] organ's damage cap with a large maximum supplied.")
	dummy.fully_heal(HEAL_ORGANS)

///Allocate a human mob, give 'em a skillchip and a generic trauma, then see if it throws any error when the brain is removed.
/datum/unit_test/chipped_traumatized_brain_removal

/datum/unit_test/chipped_traumatized_brain_removal/Run()
	var/mob/living/carbon/human/dummy/dummy = allocate(__IMPLIED_TYPE__)

	//add the chip and activate it
	var/obj/item/skillchip/basketweaving/chip = new(dummy.loc)
	dummy.implant_skillchip(chip, force = TRUE)
	TEST_ASSERT(chip.holding_brain, "Skillchip couldn't be implanted successfully, 'holding_brain' is null")
	chip.try_activate_skillchip(force = TRUE)
	TEST_ASSERT(chip.active, "Skillchip couldn't be activated")

	//add a trauma
	dummy.gain_trauma_type(BRAIN_TRAUMA_MILD)

	var/obj/item/organ/brain = locate() in dummy.organs
	brain.forceMove(dummy.loc)
	allocated += brain

/datum/unit_test/felinid_ears

/datum/unit_test/felinid_ears/Run()
	var/mob/living/carbon/human/normal_dummy = allocate(/mob/living/carbon/human/consistent)
	normal_dummy.dna.features[FEATURE_EARS] = SPRITE_ACCESSORY_NONE
	normal_dummy.set_species(/datum/species/human/felinid, pref_load = TRUE)
	TEST_ASSERT(!istype(normal_dummy.get_organ_slot(ORGAN_SLOT_EARS), /obj/item/organ/ears/cat), "Felinid with NONE ears set had cat ears on species gain.")
	TEST_ASSERT_NOTNULL(normal_dummy.get_organ_slot(ORGAN_SLOT_EARS), "Felinid with NONE ears set had NO ears on species gain.")

	var/mob/living/carbon/human/anime_dummy = allocate(/mob/living/carbon/human/consistent)
	anime_dummy.set_species(/datum/species/human/felinid, pref_load = TRUE)
	TEST_ASSERT(istype(anime_dummy.get_organ_slot(ORGAN_SLOT_EARS), /obj/item/organ/ears/cat), "Felinid with default ears set did not have cat ears on species gain.")
