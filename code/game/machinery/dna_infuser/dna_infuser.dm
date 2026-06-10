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

/obj/machinery/dna_infuser/proc/get_analysis_level(mob/user)
	return user?.mind?.get_character_skill_level(SKILL_ANALYSIS) || CHARACTER_SKILL_LEVEL_NONE

/obj/machinery/dna_infuser/proc/get_analysis_speed_multiplier(mob/user)
	var/level = get_analysis_level(user)
	var/speed_bonus = max(0, level * 5)
	if(isliving(user))
		var/mob/living/living_user = user
		speed_bonus = max(speed_bonus, living_user.get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 1))
	return 1 / max(0.1, 1 + speed_bonus * 0.01)

/obj/machinery/dna_infuser/proc/get_analysis_info_bonus(mob/user)
	var/bonus = max(0, get_analysis_level(user) * 5)
	if(isliving(user))
		var/mob/living/living_user = user
		bonus = max(bonus, living_user.get_cyberpunk_skill_perk_bonus(SKILL_ANALYSIS, 2))
	return bonus

/obj/machinery/dna_infuser/examine(mob/user)
	. = ..()
	var/analysis_info = get_analysis_info_bonus(user)
	if(!occupant)
		. += span_notice("Requires [span_bold("a subject")].")
	else
		. += span_notice("\"[span_bold(occupant.name)]\" is inside the infusion chamber.")
		if(ishuman(occupant))
			var/mob/living/carbon/human/human_occupant = occupant
			if(human_occupant.dna)
				. += span_notice("Humanoidity: [round(human_occupant.dna.get_effective_genetic_stability(), 0.1)]/[HUMANOIDITY_DEFAULT] (raw [round(human_occupant.dna.humanoidity, 0.1)], TG stability [round(human_occupant.dna.stability, 0.1)], stabilized +[round(human_occupant.dna.humanoidity_stabilized_bonus, 0.1)]).")
	if(!infusing_from)
		. += span_notice("Missing [span_bold("an infusion source")].")
	else
		. += span_notice("[span_bold(infusing_from.name)] is in the infusion slot.")
		var/datum/infuser_entry/source_entry = infusing_from.get_infusion_entry()
		. += span_notice("Infusion humanoidity cost: [source_entry.get_humanoidity_cost()].")
	. += span_notice("To operate: Obtain dead creature. Depending on size, drag or drop into the infuser slot.")
	. += span_notice("Subject enters the chamber, someone activates the machine. Voila! One of your organs has... changed!")
	. += span_notice("Alt-click to eject the infusion source, if one is inside.")
	if(infusing_from && (analysis_info >= 20 || get_analysis_level(user) >= CHARACTER_SKILL_LEVEL_SKILLED))
		var/datum/infuser_entry/analyzed_entry = infusing_from.get_infusion_entry()
		. += span_notice("Analysis: [analyzed_entry.infuse_mob_name], tier [analyzed_entry.tier], genetic stability cost [analyzed_entry.get_humanoidity_cost()].")
		if(analysis_info >= 40)
			. += span_notice("Likely adaptation: [analyzed_entry.infusion_desc].")
		if(analysis_info >= 60 && length(analyzed_entry.output_organs))
			var/list/organ_names = list()
			for(var/organ_type in analyzed_entry.output_organs)
				var/obj/item/organ/preview_organ = new organ_type()
				organ_names += preview_organ.name
				qdel(preview_organ)
			. += span_notice("Possible organ changes: [english_list(organ_names)].")
		if(analysis_info >= 80 && analyzed_entry.threshold_desc)
			. += span_notice("Threshold warning: [analyzed_entry.threshold_desc]")
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
		start_infuse(user)
		return
	toggle_open(user)

/obj/machinery/dna_infuser/proc/start_infuse(mob/user)
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
	var/infusing_time = INFUSING_TIME * get_analysis_speed_multiplier(user)
	Shake(duration = infusing_time)
	addtimer(CALLBACK(human_occupant, TYPE_PROC_REF(/mob, emote), "scream"), max(1 SECONDS, infusing_time - 1 SECONDS))
	addtimer(CALLBACK(src, PROC_REF(end_infuse), fail_explanation, fail_title, WEAKREF(user)), infusing_time)
	update_appearance()

/obj/machinery/dna_infuser/proc/end_infuse(fail_explanation, fail_title, datum/weakref/user_ref)
	var/mob/living/carbon/human/human_occupant = occupant
	if(human_occupant.infuse_organ(infusing_into, infusing_from))
		check_tier_progression(human_occupant)
		to_chat(occupant, span_danger("You feel yourself becoming more... [infusing_into.infusion_desc]?"))
		var/mob/user = user_ref?.resolve()
		user?.mind?.adjust_experience(SKILL_ANALYSIS, 3, TRUE)
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
		balloon_alert(user, "no sample to eject!")
		return CLICK_ACTION_BLOCKING
	balloon_alert(user, "ejected sample")
	infusing_from.forceMove(get_turf(src))
	infusing_from = null
	return CLICK_ACTION_SUCCESS

#undef INFUSING_TIME
#undef SCREAM_TIME
