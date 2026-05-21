/obj/item/retractor
	name = "retractor"
	desc = "Retracts stuff."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "retractor"
	inhand_icon_state = "retractor"
	icon_angle = 45
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*3, /datum/material/glass =SHEET_MATERIAL_AMOUNT * 1.5)
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	w_class = WEIGHT_CLASS_TINY
	tool_behaviour = TOOL_RETRACTOR
	toolspeed = 1
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "retractor_normal"

/obj/item/retractor/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/retractor/augment
	desc = "Micro-mechanical manipulator for retracting stuff."
	toolspeed = 0.5

/obj/item/retractor/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_retractor"
	icon_angle = 45

/obj/item/hemostat
	name = "hemostat"
	desc = "You think you have seen this before."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "hemostat"
	inhand_icon_state = "hemostat"
	icon_angle = 135
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5, /datum/material/glass = SHEET_MATERIAL_AMOUNT*1.25)
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	w_class = WEIGHT_CLASS_TINY
	attack_verb_continuous = list("attacks", "pinches")
	attack_verb_simple = list("attack", "pinch")
	tool_behaviour = TOOL_HEMOSTAT
	toolspeed = 1
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "hemostat_normal"

/obj/item/hemostat/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/hemostat/augment
	desc = "Tiny servos power a pair of pincers to stop bleeding."
	toolspeed = 0.5

/obj/item/hemostat/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_hemostat"
	icon_angle = 45

/obj/item/cautery
	name = "cautery"
	desc = "This stops bleeding."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "cautery"
	inhand_icon_state = "cautery"
	icon_angle = 135
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*1.25, /datum/material/glass = SMALL_MATERIAL_AMOUNT*7.5)
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	w_class = WEIGHT_CLASS_TINY
	attack_verb_continuous = list("burns")
	attack_verb_simple = list("burn")
	tool_behaviour = TOOL_CAUTERY
	toolspeed = 1
	heat = 500
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "cautery_normal"

/obj/item/cautery/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/cautery/ignition_effect(atom/ignitable_atom, mob/user)
	return span_rose("[user] touches the end of [src] to \the [ignitable_atom], igniting it with a puff of smoke.")

/obj/item/cautery/augment
	desc = "A heated element that cauterizes wounds."
	toolspeed = 0.5

/obj/item/cautery/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_cautery"
	icon_angle = 45

/obj/item/cautery/advanced
	name = "searing tool"
	desc = "It projects a high power laser used for medical applications."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "e_cautery"
	inhand_icon_state = "e_cautery"
	surgical_tray_overlay = "cautery_advanced"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*2, /datum/material/glass =SHEET_MATERIAL_AMOUNT, /datum/material/plasma =SHEET_MATERIAL_AMOUNT, /datum/material/uranium = SHEET_MATERIAL_AMOUNT*1.5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT*1.5)
	hitsound = 'sound/items/tools/welder.ogg'
	w_class = WEIGHT_CLASS_NORMAL
	toolspeed = 0.7
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 0.4
	light_color = COLOR_SOFT_RED

/obj/item/cautery/advanced/get_all_tool_behaviours()
	return list(TOOL_CAUTERY, TOOL_DRILL)

/obj/item/cautery/advanced/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		force_on = force, \
		throwforce_on = throwforce, \
		hitsound_on = hitsound, \
		w_class_on = w_class, \
		clumsy_check = FALSE, \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Toggles between drill and cautery and gives feedback to the user.
 */
/obj/item/cautery/advanced/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	if(active)
		tool_behaviour = TOOL_DRILL
		set_light_color(LIGHT_COLOR_BLUE)
	else
		tool_behaviour = TOOL_CAUTERY
		set_light_color(LIGHT_COLOR_ORANGE)

	balloon_alert(user, "lenses set to [active ? "drill" : "mend"]")
	playsound(user ? user : src, 'sound/items/weapons/tap.ogg', 50, TRUE)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/cautery/advanced/examine()
	. = ..()
	. += span_notice("It's set to [tool_behaviour == TOOL_CAUTERY ? "mending" : "drilling"] mode.")

/obj/item/surgicaldrill
	name = "surgical drill"
	desc = "You can drill using this item. You dig?"
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "drill"
	inhand_icon_state = "drill"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	hitsound = 'sound/items/weapons/circsawhit.ogg'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*5, /datum/material/glass = SHEET_MATERIAL_AMOUNT*3)
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	force = 15
	demolition_mod = 0.5
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("drills")
	attack_verb_simple = list("drill")
	tool_behaviour = TOOL_DRILL
	toolspeed = 1
	sharpness = SHARP_POINTY
	wound_bonus = 10
	exposed_wound_bonus = 10
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "drill_normal"

/obj/item/surgicaldrill/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/eyestab)

/obj/item/surgicaldrill/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/surgicaldrill/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] rams [src] into [user.p_their()] chest! Кажется, [user.ru_p_they()] пытается совершить самоубийство!"))
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living/carbon, gib), DROP_ALL_REMAINS), 2.5 SECONDS)
	user.SpinAnimation(3, 10)
	playsound(user, 'sound/machines/juicer.ogg', 20, TRUE)
	return MANUAL_SUICIDE

/obj/item/surgicaldrill/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_drill"

/obj/item/surgicaldrill/augment
	desc = "Effectively a small power drill contained within your arm. May or may not pierce the heavens."
	hitsound = 'sound/items/weapons/circsawhit.ogg'
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 0.5

/obj/item/scalpel
	name = "scalpel"
	desc = "Cut, cut, and once more cut."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "scalpel"
	inhand_icon_state = "scalpel"
	icon_angle = 180
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	force = 10
	demolition_mod = 0.25
	w_class = WEIGHT_CLASS_TINY
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*2, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT)
	attack_verb_continuous = list("attacks", "slashes", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "slice", "tear", "lacerate", "rip", "dice", "cut")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	sharpness = SHARP_EDGED
	tool_behaviour = TOOL_SCALPEL
	toolspeed = 1
	wound_bonus = 10
	exposed_wound_bonus = 15
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "scalpel_normal"
	var/list/alt_continuous = list("stabs", "pierces", "impales")
	var/list/alt_simple = list("stab", "pierce", "impale")

/obj/item/scalpel/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
	speed = 8 SECONDS * toolspeed, \
	effectiveness = 100, \
	bonus_modifier = 0, \
	)
	AddElement(/datum/element/eyestab)
	alt_continuous = string_list(alt_continuous)
	alt_simple = string_list(alt_simple)
	AddComponent(/datum/component/alternative_sharpness, SHARP_POINTY, alt_continuous, alt_simple)

/obj/item/scalpel/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/scalpel/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is slitting [user.p_their()] [pick("wrists", "throat", "stomach")] with [src]! Кажется, [user.ru_p_they()] пытается совершить самоубийство!"))
	return BRUTELOSS

/obj/item/scalpel/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_scalpel"
	icon_angle = 0

/obj/item/scalpel/augment
	desc = "Ultra-sharp blade attached directly to your bone for extra-accuracy."
	toolspeed = 0.5

/obj/item/circular_saw
	name = "circular saw"
	desc = "For heavy duty cutting."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "saw"
	inhand_icon_state = "saw"
	icon_angle = 180
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	hitsound = 'sound/items/weapons/circsawhit.ogg'
	mob_throw_hit_sound = 'sound/items/weapons/pierce.ogg'
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	force = 15
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 9
	throw_speed = 2
	throw_range = 5
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*5, /datum/material/glass = SHEET_MATERIAL_AMOUNT*3)
	attack_verb_continuous = list("attacks", "slashes", "saws", "cuts")
	attack_verb_simple = list("attack", "slash", "saw", "cut")
	sharpness = SHARP_EDGED
	tool_behaviour = TOOL_SAW
	toolspeed = 1
	wound_bonus = 15
	exposed_wound_bonus = 10
	/// How this looks when placed in a surgical tray
	var/surgical_tray_overlay = "saw_normal"

/obj/item/circular_saw/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
	speed = 4 SECONDS * toolspeed, \
	effectiveness = 100, \
	bonus_modifier = 5, \
	butcher_sound = 'sound/items/weapons/circsawhit.ogg', \
	)
	//saws are very accurate and fast at butchering
	var/static/list/slapcraft_recipe_list = list(/datum/crafting_recipe/chainsaw)

	AddElement(
		/datum/element/slapcrafting,\
		slapcraft_recipes = slapcraft_recipe_list,\
	)

/obj/item/circular_saw/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/circular_saw/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_saw"
	icon_angle = 0

/obj/item/circular_saw/augment
	desc = "A small but very fast spinning saw. It rips and tears until it is done."
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 0.5


/obj/item/surgical_drapes
	name = "surgical drapes"
	desc = "Nanotrasen brand surgical drapes provide optimal safety and infection control."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "surgical_drapes"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	inhand_icon_state = "drapes"
	w_class = WEIGHT_CLASS_TINY
	attack_verb_continuous = list("slaps")
	attack_verb_simple = list("slap")
	drop_sound = SFX_CLOTH_DROP
	pickup_sound = SFX_CLOTH_PICKUP
	gender = PLURAL

/obj/item/surgical_drapes/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/surgery_aid, name)

/obj/item/surgical_drapes/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_surgicaldrapes"

/obj/item/surgical_processor //allows medical cyborgs to scan and initiate advanced surgeries
	name = "surgical processor"
	desc = "A device for scanning and initiating surgeries from a disk or operating computer."
	icon = 'icons/obj/devices/scanner.dmi'
	icon_state = "surgical_processor"
	item_flags = NOBLUDGEON
	// List of surgeries downloaded into the device.
	var/list/loaded_surgeries = list()
	// If a surgery has been downloaded in. Will cause the display to have a noticeable effect - helps to realize you forgot to load anything in.
	var/downloaded = TRUE

/obj/item/surgical_processor/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/surgery_aid, /obj/item/surgical_drapes::name) // i guess it's a drape dispenser

/obj/item/surgical_processor/examine(mob/user)
	. = ..()
	. += span_notice("Equip the processor in one of your active modules to access downloaded advanced surgeries.")
	. += span_boldnotice("Advanced surgeries available:")
	//list of downloaded surgeries' names
	var/list/surgeries_names = list()
	for(var/datum/surgery_operation/downloaded_surgery as anything in GLOB.operations.get_instances_from(loaded_surgeries))
		surgeries_names += "[capitalize(downloaded_surgery.name)]"
	. += span_notice("[english_list(surgeries_names)]")

/obj/item/surgical_processor/equipped(mob/user, slot, initial)
	. = ..()
	if(!(slot & ITEM_SLOT_HANDS))
		UnregisterSignal(user, COMSIG_LIVING_OPERATING_ON)
		return
	RegisterSignal(user, COMSIG_LIVING_OPERATING_ON, PROC_REF(check_surgery), override = TRUE)

/obj/item/surgical_processor/dropped(mob/user, silent)
	. = ..()
	UnregisterSignal(user, COMSIG_LIVING_OPERATING_ON)

/obj/item/surgical_processor/interact_with_atom(atom/design_holder, mob/living/user, list/modifiers)
	if(!istype(design_holder, /obj/item/disk/surgery) && !istype(design_holder, /obj/machinery/computer/operating))
		return NONE
	balloon_alert(user, "copying designs...")
	playsound(src, 'sound/machines/terminal/terminal_processing.ogg', 25, TRUE)
	if(do_after(user, 1 SECONDS, target = design_holder))
		if(istype(design_holder, /obj/item/disk/surgery))
			var/obj/item/disk/surgery/surgery_disk = design_holder
			loaded_surgeries |= surgery_disk.surgeries
		else
			var/obj/machinery/computer/operating/surgery_computer = design_holder
			loaded_surgeries |= surgery_computer.advanced_surgeries
		playsound(src, 'sound/machines/terminal/terminal_success.ogg', 25, TRUE)
		downloaded = TRUE
		update_appearance(UPDATE_OVERLAYS)
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/surgical_processor/update_overlays()
	. = ..()
	if(downloaded)
		. += mutable_appearance(src.icon, "+downloaded")

/obj/item/surgical_processor/proc/check_surgery(datum/source, atom/movable/operating_on, list/operations)
	SIGNAL_HANDLER

	operations |= loaded_surgeries

/obj/item/scalpel/advanced
	name = "laser scalpel"
	desc = "An advanced scalpel which uses laser technology to cut."
	icon_state = "e_scalpel"
	inhand_icon_state = "e_scalpel"
	surgical_tray_overlay = "scalpel_advanced"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*3, /datum/material/glass =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/silver =SHEET_MATERIAL_AMOUNT, /datum/material/gold =HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/diamond =SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SHEET_MATERIAL_AMOUNT*2)
	hitsound = 'sound/items/weapons/blade1.ogg'
	force = 16
	w_class = WEIGHT_CLASS_NORMAL
	toolspeed = 0.7
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 0.4
	light_color = LIGHT_COLOR_BLUE
	sharpness = SHARP_EDGED
	item_flags = parent_type::item_flags | NO_BLOOD_ON_ITEM

/obj/item/scalpel/advanced/get_all_tool_behaviours()
	return list(TOOL_SAW, TOOL_SCALPEL)

/obj/item/scalpel/advanced/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		force_on = force + 1, \
		throwforce_on = throwforce, \
		throw_speed_on = throw_speed, \
		sharpness_on = sharpness, \
		hitsound_on = hitsound, \
		w_class_on = w_class, \
		clumsy_check = FALSE, \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Toggles between saw and scalpel and updates the light / gives feedback to the user.
 */
/obj/item/scalpel/advanced/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	if(active)
		tool_behaviour = TOOL_SAW
		set_light_color(LIGHT_COLOR_ORANGE)
	else
		tool_behaviour = TOOL_SCALPEL
		set_light_color(LIGHT_COLOR_BLUE)

	balloon_alert(user, "[active ? "enabled" : "disabled"] bone-cutting mode")
	playsound(user ? user : src, 'sound/machines/click.ogg', 50, TRUE)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/scalpel/advanced/examine()
	. = ..()
	. += span_notice("It's set to [tool_behaviour == TOOL_SCALPEL ? "scalpel" : "saw"] mode.")

/obj/item/retractor/advanced
	name = "mechanical pinches"
	desc = "An agglomerate of rods and gears."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "adv_retractor"
	inhand_icon_state = "adv_retractor"
	surgical_tray_overlay = "retractor_advanced"
	icon_angle = 0
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT*6, /datum/material/glass = SHEET_MATERIAL_AMOUNT*2, /datum/material/silver = SHEET_MATERIAL_AMOUNT*2, /datum/material/titanium =SHEET_MATERIAL_AMOUNT * 2.5)
	w_class = WEIGHT_CLASS_NORMAL
	toolspeed = 0.7

/obj/item/retractor/advanced/get_all_tool_behaviours()
	return list(TOOL_HEMOSTAT, TOOL_RETRACTOR)

/obj/item/retractor/advanced/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/transforming, \
		force_on = force, \
		throwforce_on = throwforce, \
		hitsound_on = hitsound, \
		w_class_on = w_class, \
		clumsy_check = FALSE, \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/*
 * Signal proc for [COMSIG_TRANSFORMING_ON_TRANSFORM].
 *
 * Toggles between retractor and hemostat and gives feedback to the user.
 */
/obj/item/retractor/advanced/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	tool_behaviour = (active ? TOOL_HEMOSTAT : TOOL_RETRACTOR)
	balloon_alert(user, "gears set to [active ? "clamp" : "retract"]")
	playsound(user ? user : src, 'sound/items/tools/change_drill.ogg', 50, TRUE)
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/retractor/advanced/examine()
	. = ..()
	. += span_notice("It resembles a [tool_behaviour == TOOL_RETRACTOR ? "retractor" : "hemostat"].")

/obj/item/shears
	name = "amputation shears"
	desc = "A type of heavy duty surgical shears used for achieving a clean separation between limb and patient. Keeping the patient still is imperative to be able to secure and align the shears."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "shears"
	icon_angle = 90
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	toolspeed = 1
	force = 12
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 6
	throw_speed = 2
	throw_range = 5
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*4, /datum/material/titanium=SHEET_MATERIAL_AMOUNT*3)
	attack_verb_continuous = list("shears", "snips")
	attack_verb_simple = list("shear", "snip")
	sharpness = SHARP_EDGED
	custom_premium_price = PAYCHECK_CREW * 14

/obj/item/shears/attack(mob/living/amputee, mob/living/user)
	if(!iscarbon(amputee) || user.combat_mode)
		return ..()

	if(user.zone_selected == BODY_ZONE_CHEST)
		return ..()

	var/mob/living/carbon/patient = amputee

	if(HAS_TRAIT(patient, TRAIT_NODISMEMBER))
		to_chat(user, span_warning("The patient's limbs look too sturdy to amputate."))
		return

	var/candidate_name
	var/obj/item/organ/tail_snip_candidate
	var/obj/item/bodypart/limb_snip_candidate

	if(user.zone_selected == BODY_ZONE_PRECISE_GROIN)
		tail_snip_candidate = patient.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
		if(!tail_snip_candidate)
			to_chat(user, span_warning("[patient] does not have a tail."))
			return
		candidate_name = tail_snip_candidate.name

	else
		limb_snip_candidate = patient.get_bodypart(check_zone(user.zone_selected))
		if(!limb_snip_candidate)
			to_chat(user, span_warning("[patient] is already missing that limb, what more do you want?"))
			return
		candidate_name = limb_snip_candidate.name

	var/amputation_speed_mod = 1

	patient.visible_message(span_danger("[user] begins to secure [src] around [patient]'s [candidate_name]."), span_userdanger("[user] begins to secure [src] around your [candidate_name]!"))
	playsound(get_turf(patient), 'sound/items/tools/ratchet.ogg', 20, TRUE)
	if(patient.stat >= UNCONSCIOUS || HAS_TRAIT(patient, TRAIT_INCAPACITATED)) //if you're incapacitated (due to paralysis, a stun, being in staminacrit, etc.), critted, unconscious, or dead, it's much easier to properly line up a snip
		amputation_speed_mod *= 0.5
	if(patient.stat != DEAD && patient.has_status_effect(/datum/status_effect/jitter)) //jittering will make it harder to secure the shears, even if you can't otherwise move
		amputation_speed_mod *= 1.5 //15*0.5*1.5=11.25, so staminacritting someone who's jittering (from, say, a stun baton) won't give you enough time to snip their head off, but staminacritting someone who isn't jittering will
	if(HAS_MIND_TRAIT(user, TRAIT_MORBID))
		amputation_speed_mod *= 0.7 //its morbin time

	if(do_after(user,  toolspeed * 15 SECONDS * amputation_speed_mod, target = patient))
		playsound(get_turf(patient), 'sound/items/weapons/bladeslice.ogg', 250, TRUE)
		if(user.zone_selected == BODY_ZONE_PRECISE_GROIN) //OwO
			tail_snip_candidate.Remove(patient)
			tail_snip_candidate.forceMove(get_turf(patient))
		else
			limb_snip_candidate.dismember()
		user.visible_message(span_danger("[src] violently slams shut, amputating [patient]'s [candidate_name]."), span_notice("You amputate [patient]'s [candidate_name] with [src]."))
		user.log_message("[user] has amputated [patient]'s [candidate_name] with [src]", LOG_GAME)
		patient.log_message("[patient]'s [candidate_name] has been amputated by [user] with [src]", LOG_GAME)

	if(HAS_MIND_TRAIT(user, TRAIT_MORBID)) //Freak
		user.add_mood_event("morbid_dismemberment", /datum/mood_event/morbid_dismemberment)

/obj/item/shears/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is pinching [user.p_them()]self with \the [src]! Кажется, [user.ru_p_they()] пытается совершить самоубийство!"))
	var/timer = 1 SECONDS
	for(var/obj/item/bodypart/thing in user.get_bodyparts())
		if(thing.body_part == CHEST)
			continue
		addtimer(CALLBACK(thing, TYPE_PROC_REF(/obj/item/bodypart/, dismember)), timer)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), user, 'sound/items/weapons/bladeslice.ogg', 70), timer)
		timer += 1 SECONDS
	sleep(timer)
	return BRUTELOSS

/obj/item/bonesetter
	name = "bonesetter"
	desc = "For setting things right."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "bonesetter"
	icon_angle = 135
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron =SHEET_MATERIAL_AMOUNT * 2.5,  /datum/material/glass = SHEET_MATERIAL_AMOUNT*1.25, /datum/material/silver = SHEET_MATERIAL_AMOUNT*1.25)
	obj_flags = CONDUCTS_ELECTRICITY
	item_flags = SURGICAL_TOOL
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("corrects", "properly sets")
	attack_verb_simple = list("correct", "properly set")
	tool_behaviour = TOOL_BONESET
	toolspeed = 1
	var/surgical_tray_overlay = "bonesetter"

/obj/item/bonesetter/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay + (tray_extended ? "" : "_out")

/obj/item/bonesetter/cyborg
	icon = 'icons/mob/silicon/robot_items.dmi'
	icon_state = "toolkit_medborg_bonesetter"
	icon_angle = 45

/obj/item/blood_filter
	name = "blood filter"
	desc = "For filtering the blood."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "bloodfilter"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT, /datum/material/glass=HALF_SHEET_MATERIAL_AMOUNT * 1.5, /datum/material/silver=SMALL_MATERIAL_AMOUNT*5)
	item_flags = SURGICAL_TOOL
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("pumps", "siphons")
	attack_verb_simple = list("pump", "siphon")
	tool_behaviour = TOOL_BLOODFILTER
	toolspeed = 1
	sound_vary = TRUE
	pickup_sound = SFX_GENERIC_DEVICE_PICKUP
	drop_sound = SFX_GENERIC_DEVICE_DROP
	/// Assoc list of chem ids to names, used for deciding which chems to filter when used for surgery
	var/list/whitelist = list()
	var/surgical_tray_overlay = "filter"

/obj/item/blood_filter/get_surgery_tool_overlay(tray_extended)
	return surgical_tray_overlay

/obj/item/blood_filter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BloodFilter", name)
		ui.open()

/obj/item/blood_filter/ui_data(mob/user)
	. = list()

	.["whitelist"] = list()
	for(var/key in whitelist)
		.["whitelist"] += whitelist[key]

/obj/item/blood_filter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	. = TRUE
	switch(action)
		if("add")
			var/selected_reagent = tgui_input_list(usr, "Select reagent to filter", "Whitelist reagent", GLOB.name2reagent)
			if(!selected_reagent)
				return FALSE

			var/datum/reagent/chem_id = GLOB.name2reagent[selected_reagent]
			if(!chem_id)
				return FALSE

			if(!(chem_id in whitelist))
				whitelist[chem_id] = selected_reagent

		if("remove")
			var/chem_name = params["reagent"]
			var/chem_id = get_chem_id(chem_name)
			whitelist -= chem_id

/*
 * Cruel Surgery Tools
 *
 * This variety of tool has the CRUEL_IMPLEMENT flag.
 *
 * Bonuses if the surgery is being done by a morbid user and it is of their interest.
 *
 * Morbid users are interested in; autospies, revival surgery, plastic surgery, organ/feature manipulations, amputations
 *
 * Otherwise, normal tool.
 */

/obj/item/retractor/cruel
	name = "twisted retractor"
	desc = "Helps reveal secrets that would rather stay buried."
	icon_state = "cruelretractor"
	surgical_tray_overlay = "retractor_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/hemostat/cruel
	name = "cruel hemostat"
	desc = "Clamping bleeders, but not so good at fixing breathers."
	icon_state = "cruelhemostat"
	surgical_tray_overlay = "hemostat_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/cautery/cruel
	name = "savage cautery"
	desc = "Chalk this one up as another successful vivisection."
	icon_state = "cruelcautery"
	surgical_tray_overlay = "cautery_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/scalpel/cruel
	name = "hungry scalpel"
	desc = "I remember every time I hold you. My born companion..."
	icon_state = "cruelscalpel"
	surgical_tray_overlay = "scalpel_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/scalpel/cruel/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/bane, mob_biotypes = MOB_UNDEAD, damage_multiplier = 1) //Just in case one of the tennants get uppity

/obj/item/surgicaldrill/cruel
	name = "tearing drill"
	desc = "What secrets do they keep buried within those pearls..."
	icon_state = "crueldrill"
	inhand_icon_state = "crueldrill"
	surgical_tray_overlay = "drill_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/circular_saw/cruel
	name = "jagged bonesaw"
	desc = "A twisted blade for twisted purpose. Rip sinew and bone until your work is done."
	icon_state = "cruelsaw"
	inhand_icon_state = "cruelsaw"
	icon_angle = 0
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	surgical_tray_overlay = "saw_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/bonesetter/cruel
	name = "harsh bonesetter"
	desc = "We shall make you whole once more..."
	icon_state = "cruelbonesetter"
	inhand_icon_state = "cruelbonesetter"
	surgical_tray_overlay = "bonesetter_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/blood_filter/cruel
	name = "malignant blood filter"
	desc = "You must be made pure..."
	icon_state = "cruelbloodfilter"
	inhand_icon_state = "cruelbloodfilter"
	surgical_tray_overlay = "filter_cruel"
	item_flags = SURGICAL_TOOL | CRUEL_IMPLEMENT

/obj/item/retractor/cruel/augment
	desc = "A twisted micro-mechanical manipulator for retracting flesh and sinew."
	toolspeed = 0.5

/obj/item/hemostat/cruel/augment
	desc = "Tiny, warped servos power a pair of pincers to stop bleeding."
	toolspeed = 0.5

/obj/item/cautery/cruel/augment
	desc = "All mistakes can be burned away with a little flame..."
	toolspeed = 0.5

/obj/item/scalpel/cruel/augment
	desc = "Ultra-sharp blade attached directly to your bone for enhanced vivisection."
	toolspeed = 0.5

/obj/item/surgicaldrill/cruel/augment
	desc = "You cannot hide your secrets from me..."
	hitsound = 'sound/items/weapons/circsawhit.ogg'
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 0.5

/obj/item/circular_saw/cruel/augment
	desc = "A jagged sawblade built for grisly work."
	w_class = WEIGHT_CLASS_SMALL
	toolspeed = 0.5

// CYBERPUNK 13 FREE MEDICAL CORE START
/obj/item/proc/cy_try_free_medical_treatment(atom/interacting_with, mob/living/user)
	if(!ishuman(interacting_with) || !isliving(user) || user.combat_mode)
		return FALSE
	var/mob/living/carbon/human/patient = interacting_with
	var/medicine_level = user.get_cy_medicine_skill_level()
	var/action_time = max(0.5 SECONDS, (3 SECONDS - (medicine_level * 0.25 SECONDS)) * toolspeed)
	var/obj/item/bodypart/selected_limb = patient.get_bodypart(user.zone_selected)
	switch(tool_behaviour)
		if(TOOL_SCALPEL)
			if(!selected_limb || LIMB_HAS_ANY_SURGERY_STATE(selected_limb, ALL_SURGERY_SKIN_STATES))
				return FALSE
			user.visible_message(span_notice("[user] makes a careful incision on [patient]'s [selected_limb.plaintext_zone]."), span_notice("You make a careful incision on [patient]'s [selected_limb.plaintext_zone]."))
			if(!do_after(user, action_time, target = patient))
				return TRUE
			selected_limb.add_surgical_state(SURGERY_SKIN_CUT|SURGERY_VESSELS_UNCLAMPED)
			if(selected_limb.can_bleed())
				selected_limb.refresh_bleed_rate()
			return TRUE
		if(TOOL_RETRACTOR)
			if(!selected_limb)
				return FALSE
			if(LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_SKIN_CUT))
				user.visible_message(span_notice("[user] retracts the incision on [patient]'s [selected_limb.plaintext_zone]."), span_notice("You retract the incision on [patient]'s [selected_limb.plaintext_zone]."))
				if(!do_after(user, action_time, target = patient))
					return TRUE
				selected_limb.add_surgical_state(SURGERY_SKIN_OPEN | (LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_VESSELS_CLAMPED) ? NONE : SURGERY_VESSELS_UNCLAMPED))
				selected_limb.remove_surgical_state(SURGERY_SKIN_CUT)
				return TRUE
			if(LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_SKIN_OPEN) && !LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_ORGANS_CUT))
				user.visible_message(span_notice("[user] opens access to deeper tissue on [patient]'s [selected_limb.plaintext_zone]."), span_notice("You open access to deeper tissue on [patient]'s [selected_limb.plaintext_zone]."))
				if(!do_after(user, action_time, target = patient))
					return TRUE
				selected_limb.add_surgical_state(SURGERY_ORGANS_CUT)
				return TRUE
			return FALSE
		if(TOOL_HEMOSTAT)
			if(selected_limb && LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_VESSELS_UNCLAMPED))
				user.visible_message(span_notice("[user] clamps open vessels on [patient]'s [selected_limb.plaintext_zone]."), span_notice("You clamp open vessels on [patient]'s [selected_limb.plaintext_zone]."))
				if(!do_after(user, action_time, target = patient))
					return TRUE
				selected_limb.add_surgical_state(SURGERY_VESSELS_CLAMPED)
				selected_limb.remove_surgical_state(SURGERY_VESSELS_UNCLAMPED)
				selected_limb.refresh_bleed_rate()
				return TRUE
			if(selected_limb?.body_zone == BODY_ZONE_CHEST && LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_ORGANS_CUT))
				var/obj/item/organ/lungs/lungs = patient.get_organ_slot(ORGAN_SLOT_LUNGS)
				if(lungs?.get_cy_condition_stacks(CY_ORGAN_CONDITION_LUNG_PUNCTURE))
					user.visible_message(span_notice("[user] seals a puncture in [patient]'s lungs."), span_notice("You seal a puncture in [patient]'s lungs."))
					if(!do_after(user, action_time, target = patient))
						return TRUE
					lungs.clear_cy_puncture(1)
					return TRUE
			if(selected_limb?.has_cy_limb_bleeding_trauma())
				var/internal_access = LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_ORGANS_CUT)
				if(selected_limb.has_cy_limb_trauma(CY_LIMB_TRAUMA_AORTA) && !internal_access)
					return FALSE
				user.visible_message(span_notice("[user] seals damaged vessels in [patient]'s [selected_limb.plaintext_zone]."), span_notice("You seal damaged vessels in [patient]'s [selected_limb.plaintext_zone]."))
				if(!do_after(user, action_time, target = patient))
					return TRUE
				selected_limb.close_cy_limb_bleeding_traumas(include_internal = internal_access)
				return TRUE
			if(selected_limb?.cy_internal_blood_pool > 0 && LIMB_HAS_SURGERY_STATE(selected_limb, SURGERY_ORGANS_CUT))
				user.visible_message(span_notice("[user] drains pooled blood from [patient]'s [selected_limb.plaintext_zone]."), span_notice("You drain pooled blood from [patient]'s [selected_limb.plaintext_zone]."))
				if(!do_after(user, action_time, target = patient))
					return TRUE
				selected_limb.drain_cy_internal_blood(20)
				return TRUE
			if(patient.get_bleed_rate() <= 0)
				return FALSE
			user.visible_message(span_notice("[user] clamps bleeding vessels on [patient]."), span_notice("You clamp bleeding vessels on [patient]."))
			if(!do_after(user, action_time, target = patient))
				return TRUE
			for(var/obj/item/bodypart/limb as anything in patient.get_bodyparts())
				for(var/datum/wound/wound as anything in limb.wounds)
					if(hascall(wound, "adjust_blood_flow"))
						call(wound, "adjust_blood_flow")(-0.75)
				limb.refresh_bleed_rate()
			return TRUE
		if(TOOL_CAUTERY)
			if(!selected_limb || (selected_limb.get_burn_damage() <= 0 && selected_limb.get_brute_damage() <= 0 && !length(selected_limb.cy_limb_traumas)))
				return FALSE
			user.visible_message(span_notice("[user] seals damaged tissue on [patient]."), span_notice("You seal damaged tissue on [patient]."))
			if(!do_after(user, action_time, target = patient))
				return TRUE
			selected_limb.close_cy_limb_bleeding_traumas(include_internal = FALSE)
			selected_limb.treat_cy_limb_surface_traumas()
			selected_limb.heal_damage(2, 6, forced = TRUE)
			selected_limb.refresh_bleed_rate()
			return TRUE
		if(TOOL_BONESET)
			if(!selected_limb || (selected_limb.get_brute_damage() <= 0 && !selected_limb.has_cy_limb_trauma(CY_LIMB_TRAUMA_DISLOCATION) && !selected_limb.has_cy_limb_trauma(CY_LIMB_TRAUMA_FRACTURE)))
				return FALSE
			user.visible_message(span_notice("[user] sets damaged bones on [patient]."), span_notice("You set damaged bones on [patient]."))
			if(!do_after(user, action_time, target = patient))
				return TRUE
			selected_limb.set_cy_limb_bone_traumas()
			selected_limb.heal_damage(8, 0, forced = TRUE, blunt = 8)
			return TRUE
		if(TOOL_BLOODFILTER)
			if(patient.get_tox_loss() <= 0 && !patient.get_organ_loss(ORGAN_SLOT_LIVER))
				return FALSE
			user.visible_message(span_notice("[user] filters toxins from [patient]'s blood."), span_notice("You filter toxins from [patient]'s blood."))
			if(!do_after(user, action_time, target = patient))
				return TRUE
			patient.adjust_tox_loss(-8, forced = TRUE)
			patient.adjust_organ_loss(ORGAN_SLOT_LIVER, -4, required_organ_flag = ORGAN_ORGANIC)
			return TRUE
	return FALSE

/obj/item/hemostat/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/retractor/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/cautery/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/scalpel/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/bonesetter/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/blood_filter/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(cy_try_free_medical_treatment(interacting_with, user))
		return ITEM_INTERACT_SUCCESS
	return ..()
// CYBERPUNK 13 FREE MEDICAL CORE END
