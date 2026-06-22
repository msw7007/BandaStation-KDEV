/obj/item/organ/cyberimp/chest
	name = "cybernetic torso implant"
	desc = "Implants for the organs in your torso."
	abstract_type = /obj/item/organ/cyberimp/chest
	zone = BODY_ZONE_CHEST

/obj/item/organ/cyberimp/chest/nutriment
	name = "nutriment pump implant"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are starving."
	corp_manufacturer = "Starlight"
	icon_state = "nutriment_implant"
	aug_overlay = "nutripump"
	var/hunger_threshold = NUTRITION_LEVEL_STARVING
	var/synthesizing = 0
	var/poison_amount = 5
	slot = ORGAN_SLOT_BELLY_AUG

/obj/item/organ/cyberimp/chest/nutriment/on_life(seconds_per_tick)
	. = ..()

	if(!is_implant_functional())
		return

	if(synthesizing)
		return

	if(owner.nutrition <= hunger_threshold)
		synthesizing = TRUE
		to_chat(owner, span_notice("You feel less hungry..."))
		owner.adjust_nutrition(25 * seconds_per_tick)
		addtimer(CALLBACK(src, PROC_REF(synth_cool)), 5 SECONDS * get_cyberpunk_implant_passive_interval_multiplier())

/obj/item/organ/cyberimp/chest/nutriment/proc/synth_cool()
	synthesizing = FALSE

/obj/item/organ/cyberimp/chest/nutriment/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	owner.reagents.add_reagent(/datum/reagent/toxin/bad_food, poison_amount / severity)
	to_chat(owner, span_warning("You feel like your insides are burning."))


/obj/item/organ/cyberimp/chest/nutriment/plus
	name = "nutriment pump implant PLUS"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry."
	icon_state = "adv_nutriment_implant"
	aug_overlay = "nutripump_adv"
	hunger_threshold = NUTRITION_LEVEL_HUNGRY
	poison_amount = 10

/obj/item/organ/cyberimp/chest/reviver
	name = "reviver implant"
	desc = "This implant will attempt to revive and heal you if you lose consciousness. For the faint of heart!"
	corp_manufacturer = "Ryaznov"
	icon_state = "reviver_implant"
	aug_overlay = "reviver"
	emissive_overlay = TRUE
	slot = ORGAN_SLOT_CHEST_AUG
	var/revive_cost = 0
	var/reviving = FALSE
	COOLDOWN_DECLARE(reviver_cooldown)
	COOLDOWN_DECLARE(defib_cooldown)

/obj/item/organ/cyberimp/chest/reviver/on_death(seconds_per_tick)
	if(isnull(owner)) // owner can be null, on_death() gets called by /obj/item/organ/process() for decay
		return
	try_heal() // Allows implant to work even on dead people

/obj/item/organ/cyberimp/chest/reviver/on_life(seconds_per_tick)
	. = ..()

	try_heal()

/obj/item/organ/cyberimp/chest/reviver/proc/try_heal()
	if(!is_implant_functional())
		return

	if(reviving)
		if(owner.stat == CONSCIOUS)
			var/recharge_time = revive_cost * get_cyberpunk_implant_passive_interval_multiplier()
			COOLDOWN_START(src, reviver_cooldown, recharge_time)
			reviving = FALSE
			to_chat(owner, span_notice("Your reviver implant shuts down and starts recharging. It will be ready again in [DisplayTimeText(recharge_time)]."))
		else
			addtimer(CALLBACK(src, PROC_REF(heal)), 3 SECONDS * get_cyberpunk_implant_passive_interval_multiplier())
		return

	if(!COOLDOWN_FINISHED(src, reviver_cooldown) || HAS_TRAIT(owner, TRAIT_SUICIDED))
		return

	if(owner.stat != CONSCIOUS)
		revive_cost = 0
		reviving = TRUE
		to_chat(owner, span_notice("You feel a faint buzzing as your reviver implant starts patching your wounds..."))
		COOLDOWN_START(src, defib_cooldown, 8 SECONDS) // 5 seconds after heal proc delay


/obj/item/organ/cyberimp/chest/reviver/proc/heal()
	if(COOLDOWN_FINISHED(src, defib_cooldown))
		revive_dead()

	/// boolean that stands for if PHYSICAL damage being patched
	var/body_damage_patched = FALSE
	var/need_mob_update = FALSE
	if(owner.get_oxy_loss())
		need_mob_update += owner.adjust_oxy_loss(-5, updating_health = FALSE)
		revive_cost += 5
	if(owner.get_brute_loss())
		need_mob_update += owner.adjust_brute_loss(-2, updating_health = FALSE)
		revive_cost += 40
		body_damage_patched = TRUE
	if(owner.get_fire_loss())
		need_mob_update += owner.adjust_fire_loss(-2, updating_health = FALSE)
		revive_cost += 40
		body_damage_patched = TRUE
	if(owner.get_tox_loss())
		need_mob_update += owner.adjust_tox_loss(-1, updating_health = FALSE)
		revive_cost += 40
	if(need_mob_update)
		owner.updatehealth()

	if(body_damage_patched && prob(35)) // healing is called every few seconds, not every tick
		owner.visible_message(span_warning("[owner]'s body twitches a bit."), span_notice("You feel like something is patching your injured body."))


/obj/item/organ/cyberimp/chest/reviver/proc/revive_dead()
	if(!COOLDOWN_FINISHED(src, defib_cooldown) || owner.stat != DEAD || owner.can_defib() != DEFIB_POSSIBLE)
		return
	owner.notify_revival("You are being revived by [src]!")
	revive_cost += 10 MINUTES // Additional 10 minutes cooldown after revival.
	owner.grab_ghost()

	defib_cooldown += 16 SECONDS // delay so it doesn't spam

	owner.visible_message(span_warning("[owner]'s body convulses a bit."))
	playsound(owner, SFX_BODYFALL, 50, TRUE)
	playsound(owner, 'sound/machines/defib/defib_zap.ogg', 75, TRUE, -1)
	owner.set_heartattack(FALSE)
	owner.revive()
	owner.emote("gasp")
	owner.set_jitter_if_lower(200 SECONDS)
	SEND_SIGNAL(owner, COMSIG_LIVING_MINOR_SHOCK)
	log_game("[owner] been revived by [src]")


/obj/item/organ/cyberimp/chest/reviver/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return

	if(reviving)
		revive_cost += 200
	else
		reviver_cooldown += 20 SECONDS

	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(human_owner.stat != DEAD && prob(50 / severity) && human_owner.can_heartattack())
			human_owner.set_heartattack(TRUE)
			to_chat(human_owner, span_userdanger("You feel a horrible agony in your chest!"))
			addtimer(CALLBACK(src, PROC_REF(undo_heart_attack)), 600 / severity)

/obj/item/organ/cyberimp/chest/reviver/proc/undo_heart_attack()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return
	human_owner.set_heartattack(FALSE)
	if(human_owner.stat == CONSCIOUS)
		to_chat(human_owner, span_notice("You feel your heart beating again!"))


/obj/item/organ/cyberimp/chest/thrusters
	name = "implantable thrusters set"
	desc = "An implantable set of thruster ports for zero-gravity maneuvering. They do not use fuel, but generate chrome load while active."
	corp_manufacturer = "Benn"
	slot = ORGAN_SLOT_SPINE
	valid_zones = list(BODY_ZONE_CHEST = ORGAN_SLOT_SPINE)
	icon_state = "imp_jetpack"
	base_icon_state = "imp_jetpack"
	aug_overlay = "imp_jetpack"
	emissive_overlay = TRUE
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	w_class = WEIGHT_CLASS_NORMAL
	var/on = FALSE
	var/thrust_power = 1.5 NEWTONS
	var/active_overheat_floor = 10

/obj/item/organ/cyberimp/chest/thrusters/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/jetpack, \
		FALSE, \
		thrust_power, \
		COMSIG_THRUSTER_ACTIVATED, \
		COMSIG_THRUSTER_DEACTIVATED, \
		THRUSTER_ACTIVATION_FAILED, \
		CALLBACK(src, PROC_REF(allow_thrust), 0.01), \
		CALLBACK(src, PROC_REF(allow_thrust), 0.01), \
		/datum/effect_system/trail_follow/ion, \
	)

/obj/item/organ/cyberimp/chest/thrusters/Remove(mob/living/carbon/thruster_owner, special, movement_flags)
	if(on)
		deactivate(silent = TRUE)
	..()

/obj/item/organ/cyberimp/chest/thrusters/ui_action_click()
	toggle()

/obj/item/organ/cyberimp/chest/thrusters/proc/toggle(silent = FALSE)
	if(!is_implant_functional())
		if(!silent)
			to_chat(owner, span_warning("Your thrusters set doesn't respond."))
		return
	if(on)
		deactivate()
	else
		activate()

/obj/item/organ/cyberimp/chest/thrusters/proc/activate(silent = FALSE)
	if(on)
		return
	if(!is_implant_functional())
		if(!silent)
			to_chat(owner, span_warning("Your thrusters set doesn't respond."))
		return
	if(organ_flags & ORGAN_FAILING)
		if(!silent)
			to_chat(owner, span_warning("Your thrusters set seems to be broken!"))
		return
	if(SEND_SIGNAL(src, COMSIG_THRUSTER_ACTIVATED, owner) & THRUSTER_ACTIVATION_FAILED)
		return

	on = TRUE
	set_chromity_active_overheat_floor(round(active_overheat_floor / get_corporate_synergy_multiplier()))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
	if(!silent)
		to_chat(owner, span_notice("You turn your thrusters set on."))
	update_appearance()
	owner.update_body_parts()

/obj/item/organ/cyberimp/chest/thrusters/proc/deactivate(silent = FALSE)
	if(!on)
		return
	SEND_SIGNAL(src, COMSIG_THRUSTER_DEACTIVATED, owner)
	set_chromity_active_overheat_floor(0)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
	if(!silent)
		to_chat(owner, span_notice("You turn your thrusters set off."))
	on = FALSE
	update_appearance()
	owner.update_body_parts()

/obj/item/organ/cyberimp/chest/thrusters/update_icon_state()
	icon_state = "[base_icon_state][on ? "-on" : null]"
	return ..()

/obj/item/organ/cyberimp/chest/thrusters/proc/allow_thrust(num, use_fuel = TRUE)
	return !!owner && is_implant_functional()

/obj/item/organ/cyberimp/chest/thrusters/get_overlay_state(image_layer, obj/item/bodypart/limb)
	return "[aug_overlay][on ? "_on" : ""]"

/obj/item/organ/cyberimp/chest/thrusters/get_overlay(image_layer, obj/item/bodypart/limb)
	. = ..()
	for (var/image/overlay as anything in .)
		overlay.layer = -BODYPARTS_HIGH_LAYER // makes absolutely zero sense why it would layer ontop of jumpsuits but it looks cool

/obj/item/organ/cyberimp/chest/thrusters/t2
	name = "implantable thrusters set T2"
	implant_tier = 2
	thrust_power = 2 NEWTONS
	active_overheat_floor = 7

/obj/item/organ/cyberimp/chest/thrusters/t3
	name = "implantable thrusters set T3"
	implant_tier = 3
	thrust_power = 2.5 NEWTONS
	active_overheat_floor = 4

/obj/item/organ/cyberimp/chest/blackrock_reverse_cordial
	name = "\improper Blackrock reverse cordial system"
	desc = "A chest control implant that shortens debuffs, knockdowns and slow-control effects."
	corp_manufacturer = "Starlight"
	icon_state = "reviver_implant"
	slot = ORGAN_SLOT_CHEST_AUG
	chromity_overheat = 4
	var/control_duration_multiplier = 0.8

/obj/item/organ/cyberimp/chest/blackrock_reverse_cordial/Initialize(mapload)
	. = ..()
	control_duration_multiplier = tier_value(list(0.8, 0.5, 0.2))

/obj/item/organ/cyberimp/chest/blackrock_reverse_cordial/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	control_duration_multiplier = max(0.05, 1 - ((1 - tier_value(list(0.8, 0.5, 0.2))) * get_corporate_synergy_multiplier()))

/obj/item/organ/cyberimp/chest/blackrock_reverse_cordial/t2
	name = "\improper Blackrock reverse cordial system T2"
	implant_tier = 2

/obj/item/organ/cyberimp/chest/blackrock_reverse_cordial/t3
	name = "\improper Blackrock reverse cordial system T3"
	implant_tier = 3

/obj/item/organ/cyberimp/chest/adrenaline_booster
	name = "adrenaline booster"
	desc = "An active chest implant that floods the body with combat stimulants without increasing chrome load."
	corp_manufacturer = "Benn"
	icon_state = "reviver_implant"
	slot = ORGAN_SLOT_CHEST_AUG
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/boost_duration = 8 SECONDS
	var/boost_speed = -0.15
	COOLDOWN_DECLARE(adrenaline_cooldown)

/obj/item/organ/cyberimp/chest/adrenaline_booster/Initialize(mapload)
	. = ..()
	boost_duration = tier_value(list(8 SECONDS, 12 SECONDS, 18 SECONDS))
	boost_speed = tier_value(list(-0.15, -0.25, -0.35))

/obj/item/organ/cyberimp/chest/adrenaline_booster/ui_action_click(mob/user, datum/action/source)
	if(!is_implant_functional())
		to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return
	if(!cyberpsychosis_ignores_cooldown() && !COOLDOWN_FINISHED(src, adrenaline_cooldown))
		to_chat(owner, span_warning("[capitalize(src)] is still recharging."))
		return
	boost_duration = tier_value(list(8 SECONDS, 12 SECONDS, 18 SECONDS), TRUE)
	boost_speed = tier_value(list(-0.15, -0.25, -0.35), TRUE)
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberimp_adrenaline, multiplicative_slowdown = boost_speed)
	owner.adjust_stamina_loss(-25 * implant_tier * get_corporate_synergy_multiplier())
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/cyberimp_adrenaline), boost_duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	COOLDOWN_START(src, adrenaline_cooldown, 45 SECONDS * get_cyberpunk_implant_cooldown_multiplier())
	to_chat(owner, span_notice("[capitalize(src)] floods your body with adrenaline."))

/obj/item/organ/cyberimp/chest/adrenaline_booster/t2
	name = "adrenaline booster T2"
	implant_tier = 2

/obj/item/organ/cyberimp/chest/adrenaline_booster/t3
	name = "adrenaline booster T3"
	implant_tier = 3

/obj/item/organ/cyberimp/chest/biomonitor
	name = "biomonitor implant"
	desc = "A passive monitor that will feed detailed vitals into the neural interface once the full UI pass lands."
	corp_manufacturer = "Starlight"
	icon_state = "reviver_implant"
	slot = ORGAN_SLOT_CHEST_AUG
	chromity_overheat = 1

/obj/item/organ/cyberimp/chest/blood_pump
	name = "blood pump implant"
	desc = "A passive abdominal circulation pump that gradually stabilizes oxygenation and blood loss."
	corp_manufacturer = "Ryaznov"
	icon_state = "nutriment_implant"
	slot = ORGAN_SLOT_BELLY_AUG
	chromity_overheat = 2

/obj/item/organ/cyberimp/chest/blood_pump/on_life(seconds_per_tick)
	. = ..()
	if(!is_implant_functional())
		return
	var/synergy = get_corporate_synergy_multiplier()
	owner.adjust_oxy_loss(-0.4 * synergy * seconds_per_tick, updating_health = FALSE)
	owner.adjust_stamina_loss(-0.8 * synergy * seconds_per_tick, updating_stamina = FALSE)

/obj/item/organ/cyberimp/chest/metabolism_booster
	name = "metabolism regulator"
	desc = "A passive abdominal implant that slows reagent metabolism. Higher tiers keep drugs and medicine stable longer."
	corp_manufacturer = "Starlight"
	icon_state = "nutriment_implant"
	slot = ORGAN_SLOT_BELLY_AUG
	chromity_overheat = 2
	var/metabolism_multiplier = 0.98

/obj/item/organ/cyberimp/chest/metabolism_booster/Initialize(mapload)
	. = ..()
	metabolism_multiplier = tier_value(list(0.98, 0.95, 0.9))

/obj/item/organ/cyberimp/chest/metabolism_booster/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	metabolism_multiplier = max(0.05, 1 - ((1 - tier_value(list(0.98, 0.95, 0.9))) * get_corporate_synergy_multiplier()))

/obj/item/organ/cyberimp/chest/metabolism_booster/t2
	name = "metabolism regulator T2"
	implant_tier = 2

/obj/item/organ/cyberimp/chest/metabolism_booster/t3
	name = "metabolism regulator T3"
	implant_tier = 3

/obj/item/organ/cyberimp/chest/spine
	name = "\improper Herculean gravitronic spinal implant"
	desc = "This gravitronic spinal interface is able to improve the athletics of a user, allowing them greater physical ability. \
		Contains a slot which can be upgraded with a gravity anomaly core, improving its performance."
	corp_manufacturer = "Ryaznov"
	icon_state = "herculean_implant"
	slot = ORGAN_SLOT_SPINE
	valid_zones = list(BODY_ZONE_CHEST = ORGAN_SLOT_SPINE)
	/// How much faster does the spinal implant improve our lifting speed, workout ability, reducing falling damage and improving climbing and standing speed
	var/athletics_boost_multiplier = 0.8
	/// How much additional throwing speed does our spinal implant grant us.
	var/added_throw_speed = 1
	/// How much additional throwing range does our spinal implant grant us.
	var/added_throw_range = 4
	/// How much additional boxing damage and tackling power do we add?
	var/strength_bonus = 4
	/// Whether or not a gravity anomaly core has been installed, improving the effectiveness of the spinal implant.
	var/core_applied = FALSE
	/// The overlay for our implant to indicate that, yes, this person has an implant inserted.
	var/mutable_appearance/stone_overlay

/mob/proc/get_cyberpunk_spine_implant()
	var/obj/item/organ/cyberimp/chest/spine/spine_implant = get_organ_slot(ORGAN_SLOT_SPINE)
	if(istype(spine_implant))
		return spine_implant

/obj/item/organ/cyberimp/chest/spine/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	to_chat(owner, span_warning("You feel shearing pain as your body is crushed like a soda can!"))
	owner.apply_damage(20/severity, BRUTE, def_zone = BODY_ZONE_CHEST)

/obj/item/organ/cyberimp/chest/spine/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	stone_overlay = mutable_appearance(icon = 'icons/effects/effects.dmi', icon_state = "stone")
	organ_owner.add_overlay(stone_overlay)
	add_organ_trait(TRAIT_BOULDER_BREAKER)
	if(core_applied)
		organ_owner.AddElement(/datum/element/forced_gravity, 1)
		add_organ_trait(TRAIT_STURDY_FRAME)

/obj/item/organ/cyberimp/chest/spine/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	remove_organ_trait(TRAIT_BOULDER_BREAKER)
	if(stone_overlay)
		organ_owner.cut_overlay(stone_overlay)
		stone_overlay = null
	if(core_applied)
		organ_owner.RemoveElement(/datum/element/forced_gravity, 1)
		remove_organ_trait(TRAIT_STURDY_FRAME)

/obj/item/organ/cyberimp/chest/spine/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/assembly/signaler/anomaly/grav))
		return NONE

	if(core_applied)
		user.balloon_alert(user, "core already installed!")
		return ITEM_INTERACT_BLOCKING

	user.balloon_alert(user, "core installed")
	name = /obj/item/organ/cyberimp/chest/spine/atlas::name
	desc = /obj/item/organ/cyberimp/chest/spine/atlas::desc
	athletics_boost_multiplier = /obj/item/organ/cyberimp/chest/spine/atlas::athletics_boost_multiplier
	added_throw_range = /obj/item/organ/cyberimp/chest/spine/atlas::added_throw_range
	added_throw_speed = /obj/item/organ/cyberimp/chest/spine/atlas::added_throw_speed
	strength_bonus = /obj/item/organ/cyberimp/chest/spine/atlas::strength_bonus
	core_applied = TRUE
	icon_state = "herculean_implant_core"
	update_appearance()
	qdel(tool)
	return ITEM_INTERACT_SUCCESS

/obj/item/organ/cyberimp/chest/spine/atlas
	name = "\improper Atlas gravitonic spinal implant"
	desc = "This gravitronic spinal interface is able to improve the athletics of a user, allowing them greater physical ability. \
		This one has been improved through the installation of a gravity anomaly core, allowing for personal gravity manipulation. \
		Not only can you walk with your feet planted firmly on the ground even during a loss of environmental gravity, but you also \
		carry heavier loads with relative ease."
	icon_state = "herculean_implant_core"
	athletics_boost_multiplier = 0.25
	added_throw_speed = 6
	added_throw_range = 8
	strength_bonus = 8
	core_applied = TRUE
