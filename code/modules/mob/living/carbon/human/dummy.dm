
/mob/living/carbon/human/dummy
	real_name = "Test Dummy"
	mouse_drag_pointer = MOUSE_INACTIVE_POINTER
	visual_only_organs = TRUE
	var/in_use = FALSE

INITIALIZE_IMMEDIATE(/mob/living/carbon/human/dummy)

/mob/living/carbon/human/dummy/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_GODMODE, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_PREVENT_BLINKING, INNATE_TRAIT)

/mob/living/carbon/human/dummy/Destroy()
	in_use = FALSE
	return ..()

/mob/living/carbon/human/dummy/Life(seconds_per_tick = SSMOBS_DT)
	return

/mob/living/carbon/human/dummy/attach_rot(mapload)
	return

/mob/living/carbon/human/dummy/set_species(datum/species/mrace, icon_update = TRUE, pref_load = FALSE, replace_missing = TRUE)
	harvest_organs()
	return ..()

///Let's extract our dummies organs and limbs for storage, to reduce the cache missed that spamming a dummy cause
/mob/living/carbon/human/dummy/proc/harvest_organs()
	for(var/slot in list(ORGAN_SLOT_BRAIN, ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_APPENDIX, \
		ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_TONGUE, ORGAN_SLOT_LIVER, ORGAN_SLOT_STOMACH))
		var/obj/item/organ/current_organ = get_organ_slot(slot) //Time to cache it lads
		if(current_organ)
			current_organ.Remove(src, special = TRUE) //Please don't somehow kill our dummy
			SSwardrobe.recycle_object(current_organ)

	var/datum/species/current_species = dna.species
	for(var/organ_path in current_species.mutant_organs)
		var/obj/item/organ/current_organ = get_organ_by_type(organ_path)
		if(current_organ)
			current_organ.Remove(src, special = TRUE) //Please don't somehow kill our dummy
			SSwardrobe.recycle_object(current_organ)

//Instead of just deleting our equipment, we save what we can and reinsert it into SSwardrobe's store
//Hopefully this makes preference reloading not the worst thing ever
/mob/living/carbon/human/dummy/delete_equipment()
	var/list/items_to_check = get_equipped_items(INCLUDE_POCKETS|INCLUDE_HELD|INCLUDE_PROSTHETICS|INCLUDE_ABSTRACT)
	var/list/to_nuke = list() //List of items queued for deletion, can't qdel them before iterating their contents in case they hold something
	///Travel to the bottom of the contents chain, expanding it out
	for(var/i = 1; i <= length(items_to_check); i++) //Needs to be a c style loop since it can expand
		var/obj/item/checking = items_to_check[i]
		if(QDELETED(checking)) //Nulls in the list, depressing
			continue
		if(!isitem(checking)) //What the fuck are you on
			to_nuke += checking
			continue

		var/list/contents = checking.contents
		if(length(contents))
			items_to_check |= contents //Please don't make an infinite loop somehow thx
			to_nuke += checking //Goodbye
			continue

		//I'm making the bet that if you're empty of other items you're not going to OOM if reapplied. I assume you're here because I was wrong
		if(ismob(checking.loc))
			var/mob/checkings_owner = checking.loc
			checkings_owner.temporarilyRemoveItemFromInventory(checking, TRUE) //Clear out of there yeah?
		SSwardrobe.recycle_object(checking)

	for(var/obj/item/delete as anything in to_nuke)
		qdel(delete)

/mob/living/carbon/human/dummy/has_equipped(obj/item/item, slot, initial = FALSE)
	SHOULD_CALL_PARENT(FALSE) // assuming direct control
	item.item_flags |= IN_INVENTORY
	if(!item.visual_equipped(src, slot, initial))
		return FALSE
	if(!(slot & item.slot_flags)) // Things below only update if slotted in (ie: not held)
		return TRUE
	add_item_coverage(item)
	if(item.hair_mask)
		LAZYADD(hair_masks, item.hair_mask)
		update_hair()
	return TRUE

/mob/living/carbon/human/dummy/proc/wipe_state()
	dna.species.create_fresh_body(src) // BANDASTATION ADDITION - Add body modifications
	delete_equipment()
	update_lips(null, null, null, update = FALSE)
	cut_overlays(TRUE)
	clear_filters()

/mob/living/carbon/human/dummy/setup_human_dna()
	randomize_human_normie(src, randomize_mutations = FALSE)

/mob/living/carbon/human/dummy/log_mob_tag(text)
	return

// To speed up the preference menu, we apply one height filter to the entire mob,
// rather than independently applying offsets and filters to each individual overlay
// This looks good enough to pass the sniff test and saves a lot of time
/mob/living/carbon/human/dummy/apply_height(image/appearance, body_area)
	if(appearance == src)
		return ..()

/// Takes in an accessory list and returns the first entry from that list, ensuring that we dont return SPRITE_ACCESSORY_NONE in the process.
/proc/get_consistent_feature_entry(list/accessory_feature_list)
	var/consistent_entry = (accessory_feature_list- SPRITE_ACCESSORY_NONE)[1]
	ASSERT(!isnull(consistent_entry))
	return consistent_entry

/proc/create_consistent_human_dna(mob/living/carbon/human/target)
	target.dna.features[FEATURE_MUTANT_COLOR] = COLOR_VIBRANT_LIME
	target.dna.features[FEATURE_ETHEREAL_COLOR] = COLOR_WHITE
	for(var/feature_key in SSaccessories.feature_list)
		target.dna.features[feature_key] = get_consistent_feature_entry(SSaccessories.feature_list[feature_key])
	target.dna.initialize_dna(newblood_type = get_blood_type(BLOOD_TYPE_O_MINUS), create_mutation_blocks = FALSE, randomize_features = FALSE)

	// UF and UI are nondeterministic, even though the features are the same some blocks will randomize slightly
	// In practice this doesn't matter, but this is for the sake of 100%(ish) consistency
	var/static/consistent_UF
	var/static/consistent_UI
	if(isnull(consistent_UF) || isnull(consistent_UI))
		consistent_UF = target.dna.unique_features
		consistent_UI = target.dna.unique_identity
	else
		target.dna.unique_features = consistent_UF
		target.dna.unique_identity = consistent_UI

/// Provides a dummy that is consistently bald, white, naked, etc.
/mob/living/carbon/human/dummy/consistent

/mob/living/carbon/human/dummy/consistent/setup_human_dna()
	create_consistent_human_dna(src)

/// Provides a dummy for unit_tests that functions like a normal human, but with a standardized appearance
/// Copies the stock dna setup from the dummy/consistent type
/mob/living/carbon/human/consistent

/mob/living/carbon/human/consistent/setup_human_dna()
	create_consistent_human_dna(src)
	fully_replace_character_name(real_name, "John Doe")

/mob/living/carbon/human/consistent/domutcheck()
	return // We skipped adding any mutations so this runtimes

/mob/living/carbon/human/consistent/slow

#ifdef UNIT_TESTS
//unit test dummies should be very fast with actions
/mob/living/carbon/human/dummy/consistent/initialize_actionspeed()
	add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/base, multiplicative_slowdown = -1)

/mob/living/carbon/human/consistent/initialize_actionspeed()
	add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/base, multiplicative_slowdown = -1)

//this one gives us a small window of time for checks on asynced actions.
/mob/living/carbon/human/consistent/slow/initialize_actionspeed()
	add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/base, multiplicative_slowdown = 0.1)
#endif

/client/var/tmp/mob/living/carbon/human/consistent/combat_doll/combat_doll

/client/verb/spawn_combat_doll()
	set name = "Боевая кукла"
	set category = "IC"
	set desc = "Создать боевую куклу для проверки атак"

	if(!isliving(mob))
		to_chat(src, span_warning("Боевая кукла требует живого персонажа."))
		return
	var/mob/living/living_owner = mob
	QDEL_NULL(combat_doll)

	var/turf/spawn_turf = get_step(living_owner, living_owner.dir)
	if(!spawn_turf || spawn_turf.is_blocked_turf())
		spawn_turf = living_owner.drop_location()

	combat_doll = new(spawn_turf)
	combat_doll.set_owner(living_owner)
	to_chat(src, span_notice("Боевая кукла создана. Укажите на нее, чтобы начать или остановить атаку. Обнимите ее без боевого режима, чтобы сменить режим."))

/mob/living/carbon/human/consistent/combat_doll
	real_name = "Боевая кукла"
	var/datum/weakref/owner_ref
	var/active = FALSE
	var/mode_index = 1
	var/static/list/mode_names = list(
		"простые удары: stab",
		"charged pierce",
		"простые удары: slash",
		"charged chop",
		"хитрый удар против парирования",
		"быстрый удар против уклонения",
		"уклонение",
		"парирование",
	)

/mob/living/carbon/human/consistent/combat_doll/Initialize(mapload)
	. = ..()
	fully_replace_character_name(real_name, initial(real_name))
	set_combat_mode(TRUE)

/mob/living/carbon/human/consistent/combat_doll/Destroy()
	var/mob/living/owner = owner_ref?.resolve()
	if(owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_POINTED)
	return ..()

/mob/living/carbon/human/consistent/combat_doll/proc/set_owner(mob/living/new_owner)
	owner_ref = WEAKREF(new_owner)
	RegisterSignal(new_owner, COMSIG_MOVABLE_POINTED, PROC_REF(on_owner_pointed))
	face_atom(new_owner)
	report_status("Цель: [new_owner]. Режим: [get_mode_name()].")

/mob/living/carbon/human/consistent/combat_doll/proc/on_owner_pointed(mob/living/source, atom/pointed, obj/effect/temp_visual/point/point, intentional)
	SIGNAL_HANDLER

	if(pointed != src)
		return
	addtimer(CALLBACK(src, PROC_REF(toggle_active)), 0, TIMER_DELETE_ME)

/mob/living/carbon/human/consistent/combat_doll/proc/toggle_active()
	active = !active
	report_status(active ? "Атака запущена. Режим: [get_mode_name()]." : "Атака остановлена.")
	if(active)
		addtimer(CALLBACK(src, PROC_REF(combat_loop)), 0, TIMER_DELETE_ME)

/mob/living/carbon/human/consistent/combat_doll/attack_hand(mob/user, list/modifiers)
	var/mob/living/owner = owner_ref?.resolve()
	if(user == owner && isliving(user))
		var/mob/living/living_user = user
		if(!living_user.combat_mode && !LAZYACCESS(modifiers, RIGHT_CLICK) && !LAZYACCESS(modifiers, MIDDLE_CLICK) && !LAZYACCESS(modifiers, CTRL_CLICK) && !LAZYACCESS(modifiers, ALT_CLICK))
			cycle_mode(living_user)
			return TRUE
	return ..()

/mob/living/carbon/human/consistent/combat_doll/proc/cycle_mode(mob/living/user)
	mode_index++
	if(mode_index > length(mode_names))
		mode_index = 1
	var/mode_name = get_mode_name()
	report_status("Режим: [mode_name].")
	to_chat(user, span_notice("Режим боевой куклы: [mode_name]."))

/mob/living/carbon/human/consistent/combat_doll/proc/get_mode_name()
	return mode_names[mode_index]

/mob/living/carbon/human/consistent/combat_doll/proc/report_status(message)
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] сообщает: \"[message]\""))

/mob/living/carbon/human/consistent/combat_doll/proc/combat_loop()
	if(!active || QDELETED(src))
		return
	var/mob/living/owner = owner_ref?.resolve()
	if(!owner || QDELETED(owner) || owner.stat == DEAD)
		qdel(src)
		return

	face_atom(owner)
	if(!Adjacent(owner))
		step_to(src, owner, 1)
	else if(world.time >= next_move)
		perform_mode(owner)

	addtimer(CALLBACK(src, PROC_REF(combat_loop)), 0.8 SECONDS, TIMER_DELETE_ME)

/mob/living/carbon/human/consistent/combat_doll/proc/perform_mode(mob/living/target)
	switch(mode_index)
		if(1)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "stab"))
		if(2)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "stab", "cyberpunk_charged_intent" = "pierce"))
		if(3)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "slash"))
		if(4)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "slash", "cyberpunk_charged_intent" = "chop"))
		if(5)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "stab", "cyberpunk_defense_break" = "parry"))
		if(6)
			UnarmedAttack(target, TRUE, list(LEFT_CLICK = TRUE, BUTTON = LEFT_CLICK, "cyberpunk_combat_intent" = "slash", "cyberpunk_defense_break" = "dodge"))
		if(7)
			perform_cyberpunk_defensive_action("dodge")
		if(8)
			perform_cyberpunk_defensive_action("parry")

//Inefficient pooling/caching way.
GLOBAL_LIST_EMPTY(human_dummy_list)
GLOBAL_LIST_EMPTY(dummy_mob_list)

/proc/generate_or_wait_for_human_dummy(slotkey)
	if(!slotkey)
		return new /mob/living/carbon/human/dummy
	var/mob/living/carbon/human/dummy/D = GLOB.human_dummy_list[slotkey]
	if(istype(D))
		UNTIL(!D.in_use)
	if(QDELETED(D))
		D = new
		GLOB.human_dummy_list[slotkey] = D
		GLOB.dummy_mob_list += D
	else
		D.regenerate_icons() //they were cut in wipe_state()
		D.update_body_parts(update_limb_data = TRUE)
	D.in_use = TRUE
	return D

/proc/generate_dummy_lookalike(slotkey, mob/target)
	if(!istype(target))
		return generate_or_wait_for_human_dummy(slotkey)

	var/mob/living/carbon/human/dummy/copycat = generate_or_wait_for_human_dummy(slotkey)

	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		carbon_target.dna.copy_dna(copycat.dna, COPY_DNA_SE|COPY_DNA_SPECIES)

		if(ishuman(target))
			var/mob/living/carbon/human/human_target = target
			human_target.copy_clothing_prefs(copycat)

		copycat.updateappearance(icon_update=TRUE, mutcolor_update=TRUE, mutations_overlay_update=TRUE)
	else
		//even if target isn't a carbon, if they have a client we can make the
		//dummy look like what their human would look like based on their prefs
		target?.client?.prefs?.apply_prefs_to(copycat, TRUE)

	return copycat

/proc/unset_busy_human_dummy(slotkey)
	if(!slotkey)
		return
	var/mob/living/carbon/human/dummy/D = GLOB.human_dummy_list[slotkey]
	if(istype(D))
		D.wipe_state()
		D.in_use = FALSE

/proc/clear_human_dummy(slotkey)
	if(!slotkey)
		return

	var/mob/living/carbon/human/dummy/dummy = GLOB.human_dummy_list[slotkey]

	GLOB.human_dummy_list -= slotkey
	if(istype(dummy))
		GLOB.dummy_mob_list -= dummy
		qdel(dummy)
