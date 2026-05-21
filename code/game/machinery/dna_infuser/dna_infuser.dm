/// how long it takes to infuse
#define INFUSING_TIME 4 SECONDS
/// we throw in a scream along the way.
#define SCREAM_TIME 3 SECONDS

/obj/machinery/dna_infuser
	name = "\improper DNA infuser"
	desc = "A defunct genetics machine for merging foreign DNA with a subject's own."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "infuser"
	base_icon_state = "infuser"
	density = TRUE
	obj_flags = BLOCKS_CONSTRUCTION // Becomes undense when the door is open
	interaction_flags_mouse_drop = NEED_HANDS | NEED_DEXTERITY
	circuit = /obj/item/circuitboard/machine/dna_infuser

	/// maximum tier this will infuse
	var/max_tier_allowed = DNA_MUTANT_TIER_ONE
	///currently infusing a vict- subject
	var/infusing = FALSE
	///what we're infusing with
	var/atom/movable/infusing_from
	///what we're turning into
	var/datum/infuser_entry/infusing_into
	///a message for relaying that the machine is locked if someone tries to leave while it's active
	COOLDOWN_DECLARE(message_cooldown)

/obj/machinery/dna_infuser/Initialize(mapload)
	. = ..()
	occupant_typecache = typecacheof(/mob/living/carbon/human)

/obj/machinery/dna_infuser/Destroy()
	. = ..()
	//dump_inventory_contents called by parent, emptying infusing_from
	infusing_into = null

/obj/machinery/dna_infuser/examine(mob/user)
	. = ..()
	if(!occupant)
		. += span_notice("Requires [span_bold("a subject")].")
	else
		. += span_notice("\"[span_bold(occupant.name)]\" is inside the infusion chamber.")
	if(!infusing_from)
		. += span_notice("Missing [span_bold("an infusion source")].")
	else
		. += span_notice("[span_bold(infusing_from.name)] is in the infusion slot.")
	if(cy_loaded_sequence)
		. += span_notice("Loaded CP gene sequence: [span_bold(cy_loaded_sequence.name)]. Alt-click with an empty infusion slot to print serum.")
	. += span_notice("To operate: Obtain dead creature. Depending on size, drag or drop into the infuser slot.")
	. += span_notice("Subject enters the chamber, someone activates the machine. Voila! One of your organs has... changed!")
	. += span_notice("Alt-click to eject the infusion source, if one is inside.")
	if(max_tier_allowed < DNA_INFUSER_MAX_TIER)
		. += span_boldnotice("Right now, the DNA Infuser can only infuse Tier [max_tier_allowed] entries.")
	else
		. += span_boldnotice("Maximum tier unlocked. All DNA entries are possible.")
	. += span_notice("Examine further for more information.")

/obj/machinery/dna_infuser/examine_more(mob/user)
	. = ..()
	. += span_notice("If you infuse a Tier [DNA_MUTANT_TIER_ONE] entry until it unlocks the bonus, it will upgrade the maximum tier and allow more complicated infusions.")
	. += span_notice("The maximum level it can reach is Tier [DNA_INFUSER_MAX_TIER].")

/obj/machinery/dna_infuser/interact(mob/user)
	if(user == occupant)
		toggle_open(user)
		return
	if(infusing)
		balloon_alert(user, "not while it's on!")
		return
	if(occupant && infusing_from)
		if(!occupant.can_infuse(user))
			playsound(src, 'sound/machines/scanner/scanbuzz.ogg', 35, vary = TRUE)
			return
		balloon_alert(user, "starting DNA infusion...")
		start_infuse()
		return
	toggle_open(user)

/obj/machinery/dna_infuser/proc/start_infuse()
	var/mob/living/carbon/human/human_occupant = occupant
	infusing = TRUE
	visible_message(span_notice("[src] hums to life, beginning the infusion process!"))

	infusing_into = infusing_from.get_infusion_entry()
	var/fail_title = ""
	var/fail_explanation = ""
	if(istype(infusing_into, /datum/infuser_entry/fly))
		fail_title = "Unknown DNA"
		fail_explanation = "Unknown DNA. Consult the \"DNA infusion book\"."
	if(infusing_into.tier > max_tier_allowed)
		infusing_into = GLOB.infuser_entries[/datum/infuser_entry/fly]
		fail_title = "Overcomplexity"
		fail_explanation = "DNA too complicated to infuse. The machine needs to infuse simpler DNA first."
	playsound(src, 'sound/machines/blender.ogg', 50, vary = TRUE)
	to_chat(human_occupant, span_danger("Little needles repeatedly prick you!"))
	human_occupant.take_overall_damage(10)
	human_occupant.add_mob_memory(/datum/memory/dna_infusion, protagonist = human_occupant, deuteragonist = infusing_from, mutantlike = infusing_into.infusion_desc)
	Shake(duration = INFUSING_TIME)
	addtimer(CALLBACK(human_occupant, TYPE_PROC_REF(/mob, emote), "scream"), INFUSING_TIME - 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(end_infuse), fail_explanation, fail_title), INFUSING_TIME)
	update_appearance()

/obj/machinery/dna_infuser/proc/end_infuse(fail_explanation, fail_title)
	var/mob/living/carbon/human/human_occupant = occupant
	if(human_occupant.infuse_organ(infusing_into, infusing_from))
		check_tier_progression(human_occupant)
		to_chat(occupant, span_danger("You feel yourself becoming more... [infusing_into.infusion_desc]?"))
	infusing = FALSE
	infusing_into = null
	QDEL_NULL(infusing_from)
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, vary = FALSE)
	if(fail_explanation)
		playsound(src, 'sound/machines/printer.ogg', 100, TRUE)
		visible_message(span_notice("[src] prints an error report."))
		var/obj/item/paper/printed_paper = new /obj/item/paper(loc)
		printed_paper.name = "error report - '[fail_title]'"
		printed_paper.add_raw_text(fail_explanation)
		printed_paper.update_appearance()
	toggle_open()
	update_appearance()

/// checks to see if the machine should progress a new tier.
/obj/machinery/dna_infuser/proc/check_tier_progression(mob/living/carbon/human/target)
	if(
		max_tier_allowed != DNA_INFUSER_MAX_TIER \
		&& infusing_into.tier == max_tier_allowed \
		&& target.has_status_effect(infusing_into.status_effect_type) \
	)
		max_tier_allowed++
		playsound(src, 'sound/machines/ding.ogg', 50, TRUE)
		visible_message(span_notice("[src] dings as it records the results of the full infusion."))

/obj/machinery/dna_infuser/update_icon_state()
	//out of order
	if(machine_stat & (NOPOWER | BROKEN))
		icon_state = base_icon_state
		return ..()
	//maintenance
	if((machine_stat & MAINT) || panel_open)
		icon_state = "[base_icon_state]_panel"
		return ..()
	//actively running
	if(infusing)
		icon_state = "[base_icon_state]_on"
		return ..()
	//open or not
	icon_state = "[base_icon_state][state_open ? "_open" : null]"
	return ..()

/obj/machinery/dna_infuser/proc/toggle_open(mob/user)
	if(panel_open)
		if(user)
			balloon_alert(user, "close panel first!")
		return
	if(state_open)
		close_machine()
		return
	else if(infusing)
		if(user)
			balloon_alert(user, "not while it's on!")
		return
	open_machine(drop = FALSE)
	//we set drop to false to manually call it with an allowlist
	dump_inventory_contents(list(occupant))

/obj/machinery/dna_infuser/screwdriver_act(mob/living/user, obj/item/tool)
	return infusing ? NONE : default_deconstruction_screwdriver(user, tool)

/obj/machinery/dna_infuser/crowbar_act(mob/living/user, obj/item/tool)
	return infusing ? NONE : default_pry_open(user, tool, deconstruct_on_fail = TRUE)

/obj/machinery/dna_infuser/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.combat_mode)
		return NONE
	if(istype(tool, /obj/item/disk/cy_gene_sequence))
		var/obj/item/disk/cy_gene_sequence/disk = tool
		if(infusing_from)
			if(cy_build_sequence_from_sample(infusing_from, "[infusing_from.name] gene sequence") && cy_write_sequence_disk(disk))
				balloon_alert(user, "sample sequence written")
				return ITEM_INTERACT_SUCCESS
		else if(occupant)
			var/mob/living/carbon/human/human_occupant = occupant
			if(cy_build_sequence_from_subject(human_occupant, "[human_occupant.real_name] gene sequence") && cy_write_sequence_disk(disk))
				balloon_alert(user, "sequence written")
				return ITEM_INTERACT_SUCCESS
		if(cy_write_sequence_disk(disk))
			balloon_alert(user, "sequence copied")
			return ITEM_INTERACT_SUCCESS
		balloon_alert(user, "no sequence")
		return ITEM_INTERACT_BLOCKING
	// if the machine already has a infusion target, or the target is not valid then no adding.
	if(!is_valid_infusion(tool, user))
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("[tool] is stuck to your hand!"))
		return ITEM_INTERACT_BLOCKING
	infusing_from = tool
	return ITEM_INTERACT_SUCCESS

/obj/machinery/dna_infuser/relaymove(mob/living/user, direction)
	if(user.stat)
		if(COOLDOWN_FINISHED(src, message_cooldown))
			COOLDOWN_START(src, message_cooldown, 4 SECONDS)
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	if(infusing)
		if(COOLDOWN_FINISHED(src, message_cooldown))
			COOLDOWN_START(src, message_cooldown, 4 SECONDS)
			to_chat(user, span_danger("[src]'s door won't budge while all the needles are infusing you!"))
		return
	open_machine(drop = FALSE)
	//we set drop to false to manually call it with an allowlist
	dump_inventory_contents(list(occupant))

// mostly good for dead mobs like corpses (drag to add).
/obj/machinery/dna_infuser/mouse_drop_receive(atom/target, mob/user, params)
	// if the machine is closed, already has a infusion target, or the target is not valid then no mouse drop.
	if(!is_valid_infusion(target, user))
		return
	infusing_from = target
	infusing_from.forceMove(src)

/// Verify that the given infusion source/mob is a dead creature.
/obj/machinery/dna_infuser/proc/is_valid_infusion(atom/movable/target, mob/user)
	if(infusing_from)
		balloon_alert(user, "empty the machine first!")
		return FALSE
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat != DEAD)
			balloon_alert(user, "only dead creatures!")
			return FALSE
	else if(!HAS_TRAIT(target, TRAIT_VALID_DNA_INFUSION))
		balloon_alert(user, "only creatures!")
		return FALSE
	return TRUE

/obj/machinery/dna_infuser/click_alt(mob/user)
	if(infusing)
		balloon_alert(user, "not while it's on!")
		return CLICK_ACTION_BLOCKING
	if(!infusing_from)
		if(cy_loaded_sequence)
			if(cy_print_gene_serum())
				balloon_alert(user, "serum printed")
				return CLICK_ACTION_SUCCESS
		balloon_alert(user, "no sample to eject!")
		return CLICK_ACTION_BLOCKING
	balloon_alert(user, "ejected sample")
	infusing_from.forceMove(get_turf(src))
	infusing_from = null
	return CLICK_ACTION_SUCCESS

#undef INFUSING_TIME
#undef SCREAM_TIME

// CYBERPUNK 13 STAGE 3 CORE GENETICS START
/mob/living/carbon
	/// CP13 humanoid compatibility for neurointerfaces and mutation pressure.
	var/cy_humanoidity = 100
	var/cy_humanoidity_stabilized_bonus = 0
	/// CP13 active genetic sequence slots. Hard-capped by TЗ to 10.
	var/list/cy_gene_segments

/mob/living/carbon/proc/get_cy_humanoidity()
	if(has_dna())
		return clamp(dna.cy_humanoidity + dna.cy_humanoidity_stabilized_bonus, 0, 100)
	return clamp(cy_humanoidity + cy_humanoidity_stabilized_bonus, 0, 100)

/mob/living/carbon/proc/get_cy_humanoidity_stabilized_bonus()
	if(has_dna())
		return max(0, dna.cy_humanoidity_stabilized_bonus)
	return max(0, cy_humanoidity_stabilized_bonus)

/mob/living/carbon/proc/adjust_cy_humanoidity_stabilized_bonus(amount)
	if(has_dna())
		dna.cy_humanoidity_stabilized_bonus = clamp(dna.cy_humanoidity_stabilized_bonus + amount, 0, 100)
		return dna.cy_humanoidity_stabilized_bonus
	cy_humanoidity_stabilized_bonus = clamp(cy_humanoidity_stabilized_bonus + amount, 0, 100)
	return cy_humanoidity_stabilized_bonus

/mob/living/carbon/proc/cy_check_humanoidity_collapse()
	if(get_cy_humanoidity() > CY_HUMANITY_MONSTER_THRESHOLD)
		return FALSE
	if(ishuman(src))
		var/mob/living/carbon/human/human_src = src
		if(prob(CY_GENETIC_MUTATION_MONSTER_RISK))
			return human_src.apply_cy_genetic_monster_failure()
		return FALSE
	return try_cy_monster_mutation()

/mob/living/carbon/proc/adjust_cy_humanoidity(amount)
	if(has_dna())
		dna.cy_humanoidity = clamp(dna.cy_humanoidity + amount, 0, 100)
		if(dna.cy_humanoidity <= CY_HUMANITY_MONSTER_THRESHOLD)
			cy_check_humanoidity_collapse()
		return dna.cy_humanoidity
	cy_humanoidity = clamp(cy_humanoidity + amount, 0, 100)
	if(cy_humanoidity <= CY_HUMANITY_MONSTER_THRESHOLD)
		cy_check_humanoidity_collapse()
	return cy_humanoidity

/mob/living/carbon/proc/add_cy_gene_segment(segment_id, instability = 0)
	var/list/segments = has_dna() ? dna.cy_gene_segments : cy_gene_segments
	LAZYINITLIST(segments)
	if(length(segments) >= CY_GENETIC_MAX_SEGMENTS && !segments[segment_id])
		return FALSE
	segments[segment_id] = instability
	if(has_dna())
		dna.cy_gene_segments = segments
	else
		cy_gene_segments = segments
	adjust_cy_humanoidity(-instability)
	return TRUE

/mob/living/carbon/proc/try_cy_monster_mutation()
	// Full monster form belongs to antagonist/fauna content. Core hook intentionally only marks the body unstable.
	adjust_psychic_loss(10, updating_health = FALSE, forced = TRUE)
	adjust_organ_loss(ORGAN_SLOT_BRAIN, 5)
	return TRUE
// CYBERPUNK 13 STAGE 3 CORE GENETICS END

// CYBERPUNK 13 STAGE 3 CORE GENETICS FIX2 START
/datum/cy_gene_sequence
	var/id
	var/name = "unstable gene sequence"
	var/humanoidity_delta = -5
	var/list/segments = list()
	var/list/mutations_to_add = list()
	var/amino_chain

/datum/cy_gene_sequence/New(sequence_name, list/new_segments, new_humanoidity_delta = -5)
	. = ..()
	id = md5("[GLOB.round_id]-[world.time]-[rand(1000,9999)]")
	if(sequence_name)
		name = sequence_name
	if(new_segments)
		segments = new_segments.Copy()
	humanoidity_delta = new_humanoidity_delta
	amino_chain = cy_generate_amino_chain()

/datum/cy_gene_sequence/proc/cy_generate_amino_chain()
	var/list/chunks = list()
	var/seed = md5("[GLOB.round_id]-[name]-[json_encode(segments)]")
	for(var/i in 1 to 10)
		chunks += uppertext(copytext(seed, i * 2 - 1, i * 2 + 1))
	return chunks.Join("-")

/obj/item/disk/cy_gene_sequence
	name = "gene sequence disk"
	desc = "Stores one CP13 gene sequence for later printing or replication."
	var/datum/cy_gene_sequence/stored_sequence

/obj/item/disk/cy_gene_sequence/examine(mob/user)
	. = ..()
	if(stored_sequence)
		. += span_notice("Sequence: [stored_sequence.name].")
		. += span_notice("Amino chain: [stored_sequence.amino_chain].")

/obj/item/disk/cy_gene_sequence/attack_self(mob/user, modifiers)
	if(!stored_sequence)
		to_chat(user, span_warning("[src] is blank."))
		return
	to_chat(user, span_notice("Sequence: [stored_sequence.name]."))
	to_chat(user, span_notice("Amino chain: [stored_sequence.amino_chain]. Humanoidity delta: [stored_sequence.humanoidity_delta]. Segments: [length(stored_sequence.segments)]/[CY_GENETIC_MAX_SEGMENTS]."))

/obj/item/reagent_containers/syringe/cy_gene_serum
	name = "gene serum syringe"
	desc = "A prepared genetic serum. Its sequence applies immediately on injection."
	var/datum/cy_gene_sequence/stored_sequence

/obj/item/reagent_containers/syringe/cy_gene_serum/examine(mob/user)
	. = ..()
	if(stored_sequence)
		. += span_notice("Prepared sequence: [stored_sequence.name].")
		. += span_notice("Amino chain: [stored_sequence.amino_chain].")

/obj/item/reagent_containers/syringe/cy_gene_serum/proc/apply_cy_gene_serum(mob/living/carbon/human/target)
	if(!istype(target) || !target.has_dna() || !stored_sequence)
		return FALSE
	for(var/segment in stored_sequence.segments)
		var/instability = stored_sequence.segments[segment]
		if(!isnum(instability))
			instability = 1
		target.add_cy_gene_segment(segment, instability)
	for(var/mutation in stored_sequence.mutations_to_add)
		target.dna.add_mutation(mutation, MUTATION_SOURCE_MUTATOR)
	target.adjust_cy_humanoidity(stored_sequence.humanoidity_delta)
	return TRUE

/mob/living/carbon/human/proc/apply_cy_genetic_monster_failure()
	if(stat == DEAD && istype(loc, /mob/living/basic/mining/legion/cy_genetic_abomination))
		return FALSE
	var/turf/body_turf = get_turf(src)
	if(!body_turf)
		return FALSE
	var/mob/living/basic/mining/legion/cy_genetic_abomination/monster = new(body_turf)
	monster.consume_cy_original_body(src)
	visible_message(span_danger("[src] violently mutates as humanoid genetic stability collapses!"), span_userdanger("Your body stops answering as your genes collapse into something inhuman!"))
	adjust_psychic_loss(40, forced = TRUE)
	adjust_organ_loss(ORGAN_SLOT_BRAIN, 20)
	return TRUE

/mob/living/basic/mining/legion/cy_genetic_abomination
	name = "genetic abomination"
	desc = "A failed humanoid genome wearing itself inside out."
	icon = 'icons/mob/nonhuman-player/blob.dmi'
	icon_state = "blobbernaut_independent"
	icon_living = "blobbernaut_independent"
	icon_dead = "blobbernaut_independent_dead"
	base_icon_state = "blobbernaut_independent"
	maxHealth = 200
	health = 200
	melee_damage_lower = 18
	melee_damage_upper = 22
	speed = 2
	corpse_type = /obj/effect/gibspawner/generic
	has_emissive = FALSE

/mob/living/basic/mining/legion/cy_genetic_abomination/proc/consume_cy_original_body(mob/living/carbon/human/original_body)
	if(!istype(original_body))
		return FALSE
	stored_mob = original_body
	gender = original_body.gender
	name = "mutated [original_body.real_name]"
	var/datum/mind/original_mind = original_body.mind
	if(original_mind)
		original_mind.transfer_to(src, force_key_move = TRUE)
	original_body.death()
	original_body.extinguish_mob()
	original_body.apply_status_effect(/datum/status_effect/grouped/stasis, STASIS_LEGION_EATEN)
	RegisterSignal(original_body, COMSIG_LIVING_REVIVE, PROC_REF(on_consumed_revive))
	original_body.forceMove(src)
	ai_controller?.set_blackboard_key(BB_LEGION_CORPSE, original_body)
	return TRUE

/mob/living/basic/mining/legion/cy_genetic_abomination/death(gibbed)
	var/mob/living/stored = stored_mob
	if(stored)
		stored.forceMove(loc)
		if(stored.stat != DEAD)
			stored.death()
		stored.remove_status_effect(/datum/status_effect/grouped/stasis, STASIS_LEGION_EATEN)
		stored_mob = null
	return ..()
// CYBERPUNK 13 STAGE 3 CORE GENETICS FIX2 END


// CYBERPUNK 13 STAGE 3 CORE GENETICS FIX3 START
/obj/machinery/dna_infuser
	var/datum/cy_gene_sequence/cy_loaded_sequence

/obj/machinery/dna_infuser/proc/cy_build_sequence_from_subject(mob/living/carbon/human/subject, sequence_name = "sampled sequence")
	if(!istype(subject) || !subject.has_dna())
		return null
	var/list/segments = list()
	subject.dna.cy_sync_reserved_gene_segments()
	for(var/segment in subject.dna.cy_gene_segments)
		segments[segment] = subject.dna.cy_gene_segments[segment]
	var/list/mutation_payload = list()
	for(var/datum/mutation/mutation as anything in subject.dna.mutations)
		if(mutation.type == /datum/mutation/race)
			continue
		mutation_payload |= mutation.type
		if(length(segments) < CY_GENETIC_MAX_SEGMENTS)
			segments["mutation:[mutation.type]"] = 1
	if(subject.dna.species && length(segments) < CY_GENETIC_MAX_SEGMENTS)
		segments["species:[subject.dna.species.type]"] = 1
	if(!length(segments))
		segments["[CY_GENE_SEQUENCE_ROUND_SEED]-[rand(100,999)]"] = 1
	cy_loaded_sequence = new /datum/cy_gene_sequence(sequence_name, segments, CY_GENE_SERUM_UNSTABLE_HUMANITY_DELTA)
	cy_loaded_sequence.mutations_to_add = mutation_payload
	return cy_loaded_sequence

/obj/machinery/dna_infuser/proc/cy_build_sequence_from_sample(atom/movable/sample, sequence_name = "sampled sequence")
	if(!sample)
		return null
	if(ishuman(sample))
		return cy_build_sequence_from_subject(sample, sequence_name)
	var/list/segments = list()
	var/datum/infuser_entry/entry = sample.get_infusion_entry()
	if(entry)
		segments["infusion:[entry.type]"] = max(1, entry.tier)
		segments["sample:[sample.type]"] = 1
	else
		segments["sample:[sample.type]"] = 1
	cy_loaded_sequence = new /datum/cy_gene_sequence(sequence_name, segments, CY_GENE_SERUM_UNSTABLE_HUMANITY_DELTA)
	return cy_loaded_sequence

/obj/machinery/dna_infuser/proc/cy_write_sequence_disk(obj/item/disk/cy_gene_sequence/disk)
	if(!istype(disk) || !cy_loaded_sequence)
		return FALSE
	disk.stored_sequence = cy_loaded_sequence
	return TRUE

/obj/machinery/dna_infuser/proc/cy_print_gene_serum()
	if(!cy_loaded_sequence)
		return null
	var/obj/item/reagent_containers/syringe/cy_gene_serum/serum = new(get_turf(src))
	serum.stored_sequence = cy_loaded_sequence
	return serum

/obj/item/reagent_containers/syringe/cy_gene_serum/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && ishuman(target) && stored_sequence)
		var/mob/living/carbon/human/human_target = target
		if(apply_cy_gene_serum(human_target))
			to_chat(user, span_notice("You inject [human_target] with [stored_sequence.name]."))
			qdel(src)
			return TRUE
	return ..()

/obj/item/cy_gene_analyzer
	name = "gene analyzer"
	desc = "A compact scanner for reading CP13 humanoidity, gene slots and sequence carriers."
	icon = 'icons/obj/devices/scanner.dmi'
	icon_state = "health"
	w_class = WEIGHT_CLASS_TINY

/obj/item/cy_gene_analyzer/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(ishuman(interacting_with))
		var/mob/living/carbon/human/target = interacting_with
		if(!target.has_dna())
			to_chat(user, span_warning("[target] has no readable humanoid DNA."))
			return ITEM_INTERACT_BLOCKING
		target.dna.cy_sync_reserved_gene_segments()
		to_chat(user, span_notice("[target]: humanoidity [round(target.get_cy_humanoidity())]%, stabilized [round(target.get_cy_humanoidity_stabilized_bonus())]%, slots [length(target.dna.cy_gene_segments)]/[CY_GENETIC_MAX_SEGMENTS]."))
		if(length(target.dna.cy_gene_segments))
			for(var/segment in target.dna.cy_gene_segments)
				to_chat(user, span_notice("Segment [segment]: instability [target.dna.cy_gene_segments[segment]]."))
		return ITEM_INTERACT_SUCCESS
	if(istype(interacting_with, /obj/item/disk/cy_gene_sequence))
		var/obj/item/disk/cy_gene_sequence/disk = interacting_with
		if(!disk.stored_sequence)
			to_chat(user, span_warning("[disk] is blank."))
			return ITEM_INTERACT_BLOCKING
		to_chat(user, span_notice("[disk.stored_sequence.name]: [disk.stored_sequence.amino_chain], humanoidity delta [disk.stored_sequence.humanoidity_delta]."))
		return ITEM_INTERACT_SUCCESS
	if(istype(interacting_with, /obj/item/reagent_containers/syringe/cy_gene_serum))
		var/obj/item/reagent_containers/syringe/cy_gene_serum/serum = interacting_with
		if(!serum.stored_sequence)
			to_chat(user, span_warning("[serum] has no readable sequence."))
			return ITEM_INTERACT_BLOCKING
		to_chat(user, span_notice("[serum.stored_sequence.name]: [serum.stored_sequence.amino_chain], humanoidity delta [serum.stored_sequence.humanoidity_delta]."))
		return ITEM_INTERACT_SUCCESS
	return NONE
// CYBERPUNK 13 STAGE 3 CORE GENETICS FIX3 END
