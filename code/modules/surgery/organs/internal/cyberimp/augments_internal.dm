
/obj/item/organ/cyberimp
	name = "cybernetic implant"
	desc = "A state-of-the-art implant that improves a baseline's functionality."
	abstract_type = /obj/item/organ/cyberimp
	organ_flags = ORGAN_ROBOTIC
	implant_flags = IMPLANT_REQUIRES_NEURAL
	failing_desc = "seems to be broken."
	chromity_overheat = 10
	/// Cyberpunk content tier. Most old implants stay tier 1 unless a subtype overrides this.
	var/implant_tier = 1
	/// Cyberpunk implant manufacturer used for neural-interface corporate synergy.
	var/corp_manufacturer = "independent"
	/// icon of the bodypart overlay we're going to be applying to our owner
	var/aug_icon = 'icons/mob/human/species/misc/bodypart_overlay_augmentations.dmi'
	/// icon_state of the bodypart overlay we're going to be applying to our owner
	var/aug_overlay = null
	/// Does the implant have an emissive overlay too?
	var/emissive_overlay = FALSE
	/// Bodypart overlay we're going to apply to whoever we're implanted into
	var/datum/bodypart_overlay/augment/bodypart_aug = null

/obj/item/organ/cyberimp/Initialize(mapload)
	. = ..()
	if (aug_overlay)
		bodypart_aug = new(src)

/obj/item/organ/cyberimp/Destroy()
	QDEL_NULL(bodypart_aug)
	return ..()

/obj/item/organ/cyberimp/proc/get_overlay_state()
	return aug_overlay

/obj/item/organ/cyberimp/proc/get_overlay(image_layer, obj/item/bodypart/limb)
	. = list()
	. += image(icon = aug_icon, icon_state = get_overlay_state(), layer = image_layer)
	if (emissive_overlay)
		. += emissive_appearance(aug_icon, "[get_overlay_state()]_e", limb.owner || limb, image_layer)

/obj/item/organ/cyberimp/on_bodypart_insert(obj/item/bodypart/limb)
	. = ..()
	if (bodypart_aug)
		limb.add_bodypart_overlay(bodypart_aug)

/obj/item/organ/cyberimp/on_bodypart_remove(obj/item/bodypart/limb)
	. = ..()
	if (bodypart_aug)
		limb.remove_bodypart_overlay(bodypart_aug)

/datum/bodypart_overlay/augment
	layers = EXTERNAL_ADJACENT
	draw_on_husks = HUSK_OVERLAY_NORMAL
	/// Implant that owns this overlay
	var/obj/item/organ/cyberimp/implant

/datum/bodypart_overlay/augment/New(obj/item/organ/cyberimp/implant)
	. = ..()
	src.implant = implant

/datum/bodypart_overlay/augment/Destroy(force)
	implant = null
	return ..()

/datum/bodypart_overlay/augment/generate_icon_cache(obj/item/bodypart/limb)
	. = ..()
	. += implant.get_overlay_state()

/datum/bodypart_overlay/augment/get_overlay(layer, obj/item/bodypart/limb)
	layer = bitflag_to_layer(layer)
	var/list/imageset = implant.get_overlay(layer, limb)
	if(blocks_emissive == EMISSIVE_BLOCK_NONE || !limb)
		return imageset

	var/list/all_images = list()
	for(var/image/overlay as anything in imageset)
		all_images += overlay
		all_images += emissive_blocker(overlay.icon, overlay.icon_state, limb, layer = overlay.layer, alpha = overlay.alpha)

	return all_images

/obj/item/organ/cyberimp/feel_for_damage(self_aware)
	// No feeling in implants (yet?)
	return ""

/obj/item/organ/cyberimp/proc/tier_value(list/values, use_synergy = FALSE)
	if(!length(values))
		return null
	var/value = values[clamp(implant_tier, 1, length(values))]
	if(use_synergy && isnum(value))
		return value * get_corporate_synergy_multiplier()
	return value

/datum/movespeed_modifier/cyberimp_sandevistan
	variable = TRUE

/datum/movespeed_modifier/cyberimp_adrenaline
	variable = TRUE

/datum/movespeed_modifier/cyberimp_subdermal_armor
	variable = TRUE

/datum/movespeed_modifier/cyberimp_leg_speed
	variable = TRUE

//[[[[BRAIN]]]]

/obj/item/organ/cyberimp/brain
	name = "cybernetic brain implant"
	desc = "Injectors of extra sub-routines for the brain."
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY
	/// Duration of stun when hit with worst-case emp
	var/emp_stun_duration = 20 SECONDS
	/// Duration of immobilization when hit with worst-case emp
	var/emp_immobilize_duration = 0 SECONDS

/obj/item/organ/cyberimp/brain/emp_act(severity)
	. = ..()
	if(isnull(owner) || (. & EMP_PROTECT_SELF))
		return
	if(emp_immobilize_duration > 0)
		owner.Immobilize(emp_immobilize_duration / severity)
	if(emp_stun_duration > 0)
		owner.Stun(emp_stun_duration / severity)
		to_chat(owner, span_warning("Your body seizes up!"))

/obj/item/organ/cyberimp/brain/neural_interface
	name = "neural interface implant"
	desc = "The central neural bridge between the brain, chrome, memories and the Net."
	icon_state = "brain_implant"
	slot = ORGAN_SLOT_NEURAL_IMPLANT
	implant_flags = IMPLANT_NEURAL_INTERFACE
	emp_stun_duration = 0
	chromity_overheat = 0
	actions_types = list(/datum/action/item_action/organ_action/use)
	/// Legal key used by direct interfaces to bypass this neural implant's ice.
	var/cryptographic_key
	/// Configurable digital ice bound to this neural interface.
	var/datum/cyber_ice/neural_ice
	/// One-use Veil reward keys remembered by this neural interface.
	var/list/veil_reward_keys = list()

/obj/item/organ/cyberimp/brain/neural_interface/Initialize(mapload)
	. = ..()
	if(!cryptographic_key)
		cryptographic_key = generate_neural_cryptokey()
	neural_ice = new()
	refresh_ice_model()

/obj/item/organ/cyberimp/brain/neural_interface/Destroy()
	QDEL_NULL(neural_ice)
	veil_reward_keys = null
	return ..()

/obj/item/organ/cyberimp/brain/neural_interface/requires_neural_implant()
	return FALSE

/obj/item/organ/cyberimp/brain/neural_interface/is_implant_functional()
	if(!..())
		return FALSE
	return has_living_brain()

/obj/item/organ/cyberimp/brain/neural_interface/on_life(seconds_per_tick)
	. = ..()
	if(!owner || owner.stat == DEAD || damage <= 0)
		return
	var/repaired_amount = min(damage, NEURAL_INTERFACE_SELF_REPAIR_PER_SECOND * seconds_per_tick)
	if(repaired_amount <= 0)
		return
	apply_organ_damage(-repaired_amount)
	add_organ_pain(repaired_amount * NEURAL_INTERFACE_SELF_REPAIR_PAIN_MULTIPLIER)

/obj/item/organ/cyberimp/brain/neural_interface/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	if(!cryptographic_key)
		cryptographic_key = generate_neural_cryptokey()
	receiver.corp_align = corp_manufacturer == "independent" ? null : corp_manufacturer
	refresh_ice_model()

/obj/item/organ/cyberimp/brain/neural_interface/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	if(organ_owner?.corp_align == corp_manufacturer)
		organ_owner.corp_align = null

/obj/item/organ/cyberimp/brain/neural_interface/proc/has_living_brain()
	var/obj/item/organ/brain = owner?.get_organ_slot(ORGAN_SLOT_BRAIN)
	return !isnull(brain) && !(brain.organ_flags & ORGAN_FAILING) && brain.damage < brain.maxHealth

/obj/item/organ/cyberimp/brain/neural_interface/proc/generate_neural_cryptokey()
	return uppertext(copytext(md5("[REF(src)]-[world.realtime]-[rand(1, 999999)]"), 1, 17))

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice() as /datum/cyber_ice
	if(!neural_ice)
		neural_ice = new()
	return neural_ice

/obj/item/organ/cyberimp/brain/neural_interface/proc/refresh_ice_model()
	var/datum/cyber_ice/ice = get_ice()
	if(corp_manufacturer && corp_manufacturer != "independent")
		return ice.configure_model(CYBER_ICE_MODEL_CORPORATE)
	return ice.configure_model(CYBER_ICE_MODEL_BASIC)

/obj/item/organ/cyberimp/brain/neural_interface/proc/set_ice_model(model)
	return get_ice().configure_model(model)

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_chromity_penalty()
	var/penalty = get_ice().get_chromity_penalty()
	penalty /= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(corp_manufacturer, list("benn_dna_storage", "ryaznov_power_tuning", "starlight_phase_tuning"), 1, 1.1)
	return round(penalty)

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_timer_duration(hacking_skill = 0)
	var/timer_duration = get_ice().get_timer_duration(hacking_skill)
	timer_duration /= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(corp_manufacturer, list("benn_dna_storage", "ryaznov_power_tuning", "starlight_phase_tuning"), 1, 1.05)
	return max(1, round(timer_duration))

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_grid_size(hacking_skill = 0)
	return get_ice().get_grid_size(hacking_skill)

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_sequence_length(hacking_skill = 0)
	return get_ice().get_sequence_length(hacking_skill, get_ice_grid_size(hacking_skill))

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_reserve()
	return get_ice().current_reserve

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_ice_max_reserve()
	return get_ice().get_max_reserve()

/obj/item/organ/cyberimp/brain/neural_interface/proc/set_ice_distribution(timer, size, sequence, reserve)
	return get_ice().set_distribution(timer, size, sequence, reserve)

/obj/item/organ/cyberimp/brain/neural_interface/proc/open_ice_configuration(mob/living/user)
	if(!user)
		return FALSE
	var/datum/cyber_ice_configurator/configurator = new(src, owner)
	configurator.ui_interact(user)
	return TRUE

/obj/item/organ/cyberimp/brain/neural_interface/proc/has_cryptographic_key(key)
	return !isnull(key) && key == cryptographic_key

/obj/item/organ/cyberimp/brain/neural_interface/proc/get_cryptographic_key()
	if(!cryptographic_key)
		cryptographic_key = generate_neural_cryptokey()
	return cryptographic_key

/obj/item/organ/cyberimp/brain/neural_interface/proc/remember_veil_reward_key(key, level = 1)
	if(!key || is_veil_reward_key_redeemed(key))
		return FALSE
	if(!veil_reward_keys)
		veil_reward_keys = list()
	veil_reward_keys[key] = max(1, round(level))
	return TRUE

/obj/item/organ/cyberimp/brain/neural_interface/proc/remove_veil_reward_key(key)
	if(!veil_reward_keys || !key)
		return FALSE
	if(!(key in veil_reward_keys))
		return FALSE
	veil_reward_keys -= key
	return TRUE

/obj/item/organ/cyberimp/brain/neural_interface/proc/choose_veil_reward_key(mob/user)
	if(!length(veil_reward_keys))
		to_chat(user, span_warning("[src] has no remembered Veil reward keys."))
		return null
	var/list/options = list()
	for(var/key in veil_reward_keys)
		if(is_veil_reward_key_redeemed(key))
			veil_reward_keys -= key
			continue
		options["[key] (L[veil_reward_keys[key]])"] = key
	if(!length(options))
		to_chat(user, span_warning("[src] has no usable Veil reward keys."))
		return null
	var/choice = tgui_input_list(user, "Choose a Veil reward key.", "Veil reward memory", options)
	return choice ? options[choice] : null

/obj/item/organ/cyberimp/brain/neural_interface/proc/start_ice_hack(mob/living/hacker, provided_key = null)
	if(!hacker || !is_implant_functional())
		return null
	if(has_cryptographic_key(provided_key))
		to_chat(hacker, span_notice("Cryptographic key accepted. ICE bypassed."))
		return TRUE
	var/datum/cyber_ice_hack_session/session = new(hacker, get_ice(), owner, hacker.get_cyber_hacking_skill())
	session.ui_interact(hacker)
	return session

/obj/item/organ/cyberimp/brain/neural_interface/ui_action_click()
	if(!is_implant_functional())
		if(owner)
			to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return

	to_chat(owner, span_notice("You access your neural skillchip bridge."))
	playsound(owner, 'sound/items/taperecorder/tape_flip.ogg', 20, vary = TRUE)

	if(!do_after(owner, 1.5 SECONDS, owner))
		to_chat(owner, span_warning("You were interrupted!"))
		return

	var/obj/item/skillchip/skillchip = owner.get_active_held_item()
	if(skillchip)
		if(!istype(skillchip))
			to_chat(owner, span_warning("You try to insert [owner.get_active_held_item()] into [src], but it won't fit."))
			return
		insert_skillchip(skillchip)
		return

	var/obj/item/organ/brain/chippy_brain = owner.get_organ_by_type(/obj/item/organ/brain)
	if(!chippy_brain)
		to_chat(owner, span_warning("Your neural interface cannot find a living brain to access."))
		return
	remove_skillchip(chippy_brain)

/obj/item/organ/cyberimp/brain/neural_interface/proc/insert_skillchip(obj/item/skillchip/skillchip)
	var/fail_string = owner.implant_skillchip(skillchip, force = FALSE)
	if(fail_string)
		to_chat(owner, span_warning(fail_string))
		playsound(owner, 'sound/machines/buzz/buzz-sigh.ogg', 10, vary = TRUE)
		return

	var/refail_string = skillchip.try_activate_skillchip(silent = FALSE, force = FALSE)
	if(refail_string)
		to_chat(owner, span_warning(refail_string))
		playsound(owner, 'sound/machines/buzz/buzz-two.ogg', 10, vary = TRUE)
		return

	playsound(owner, 'sound/machines/chime.ogg', 10, vary = TRUE)

/obj/item/organ/cyberimp/brain/neural_interface/proc/remove_skillchip(obj/item/organ/brain/chippy_brain)
	if(!length(chippy_brain.skillchips))
		to_chat(owner, span_warning("Your brain has no removable skillchips."))
		return
	var/obj/item/skillchip/skillchip = show_radial_menu(owner, owner, chippy_brain.skillchips)
	if(!skillchip)
		return
	owner.remove_skillchip(skillchip, silent = FALSE)
	skillchip.forceMove(owner.drop_location())
	owner.put_in_hands(skillchip, del_on_fail = FALSE)
	playsound(owner, 'sound/machines/click.ogg', 10, vary = TRUE)
	to_chat(owner, span_notice("You take [skillchip] out through [src]."))

/obj/item/organ/cyberimp/brain/operating_system
	name = "neural operating system"
	desc = "A brain-grade combat operating system. Only one such system should be installed into the active CNS hardpoint."
	icon_state = "brain_implant"
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY
	emp_stun_duration = 0
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	var/active = FALSE
	var/active_duration = 8 SECONDS
	var/active_overheat_floor = 0
	COOLDOWN_DECLARE(os_cooldown)

/obj/item/organ/cyberimp/brain/operating_system/ui_action_click()
	if(active)
		deactivate_os()
		return
	activate_os()

/obj/item/organ/cyberimp/brain/operating_system/proc/activate_os()
	if(!is_implant_functional())
		if(owner)
			to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return FALSE
	if(!COOLDOWN_FINISHED(src, os_cooldown))
		to_chat(owner, span_warning("[capitalize(src)] is still cooling down."))
		return FALSE
	active = TRUE
	COOLDOWN_START(src, os_cooldown, 45 SECONDS * get_cyberpunk_implant_cooldown_multiplier())
	add_chromity_overheat(active_overheat_floor)
	set_chromity_active_overheat_floor(active_overheat_floor)
	addtimer(CALLBACK(src, PROC_REF(deactivate_os)), active_duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	to_chat(owner, span_notice("[capitalize(src)] comes online."))
	return TRUE

/obj/item/organ/cyberimp/brain/operating_system/proc/deactivate_os()
	if(!active)
		return
	active = FALSE
	set_chromity_active_overheat_floor(0)
	if(owner)
		to_chat(owner, span_notice("[capitalize(src)] disengages."))

/obj/item/organ/cyberimp/brain/operating_system/Remove(mob/living/carbon/implant_owner, special, movement_flags)
	deactivate_os()
	return ..()

/obj/item/organ/cyberimp/brain/operating_system/sandevistan
	name = "\improper Sandevistan reflex OS"
	desc = "An active neural OS that accelerates the user and leaves visual afterimages. High-tier models are brutally hot."
	corp_manufacturer = "Benn"
	active_duration = 6 SECONDS
	active_overheat_floor = 35
	var/active_speed_mod = -0.25

/obj/item/organ/cyberimp/brain/operating_system/sandevistan/activate_os()
	active_speed_mod = tier_value(list(-0.25, -0.6, -1), TRUE)
	active_overheat_floor = tier_value(list(35, 55, 80))
	. = ..()
	if(.)
		owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberimp_sandevistan, multiplicative_slowdown = active_speed_mod)
		owner.do_jitter_animation(20)

/obj/item/organ/cyberimp/brain/operating_system/sandevistan/deactivate_os()
	if(owner)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/cyberimp_sandevistan)
	return ..()

/obj/item/organ/cyberimp/brain/operating_system/sandevistan/t2
	name = "\improper Sandevistan reflex OS T2"
	implant_tier = 2

/obj/item/organ/cyberimp/brain/operating_system/sandevistan/t3
	name = "\improper Sandevistan reflex OS T3"
	implant_tier = 3

/obj/item/organ/cyberimp/brain/operating_system/berserk
	name = "\improper Berserk motor OS"
	desc = "An active neural OS that overdrives unarmed and strength-based combat formulas. It runs cooler than reflex acceleration."
	corp_manufacturer = "Ryaznov"
	active_duration = 10 SECONDS
	active_overheat_floor = 12
	var/unarmed_damage_multiplier = 1.5

/obj/item/organ/cyberimp/brain/operating_system/berserk/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	RegisterSignal(organ_owner, COMSIG_LIVING_EARLY_UNARMED_ATTACK, PROC_REF(on_berserk_unarmed))

/obj/item/organ/cyberimp/brain/operating_system/berserk/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_LIVING_EARLY_UNARMED_ATTACK)

/obj/item/organ/cyberimp/brain/operating_system/berserk/activate_os()
	unarmed_damage_multiplier = tier_value(list(1.5, 2, 2.5), TRUE)
	active_overheat_floor = tier_value(list(12, 18, 24))
	return ..()

/obj/item/organ/cyberimp/brain/operating_system/berserk/proc/on_berserk_unarmed(mob/living/carbon/human/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(!active || !proximity || !isliving(target) || LAZYACCESS(modifiers, RIGHT_CLICK))
		return NONE
	var/mob/living/living_target = target
	var/bonus_damage = max(1, round(source.get_attribute_value(ATTRIBUTE_STRENGTH) * (unarmed_damage_multiplier - 1)))
	living_target.apply_damage(bonus_damage, BRUTE, living_target.get_random_valid_zone(source.zone_selected))
	to_chat(source, span_danger("Berserk overdrive adds [bonus_damage] force to your hit."))
	return NONE

/obj/item/organ/cyberimp/brain/operating_system/berserk/t2
	name = "\improper Berserk motor OS T2"
	implant_tier = 2

/obj/item/organ/cyberimp/brain/operating_system/berserk/t3
	name = "\improper Berserk motor OS T3"
	implant_tier = 3

/obj/item/organ/cyberimp/brain/operating_system/eagle
	name = "\improper Kowalski Eagle targeting OS"
	desc = "An active targeting OS that stabilizes ranged fire. Weapon hooks read its spread reduction from the user's brain implant."
	corp_manufacturer = "Ryaznov"
	active_duration = 12 SECONDS
	active_overheat_floor = 30
	var/spread_reduction = 0.33

/obj/item/organ/cyberimp/brain/operating_system/eagle/activate_os()
	spread_reduction = min(1, tier_value(list(0.33, 0.66, 1), TRUE))
	active_overheat_floor = tier_value(list(30, 45, 60))
	. = ..()
	if(.)
		to_chat(owner, span_notice("Targeting solution stabilized by [round(spread_reduction * 100)]%."))

/obj/item/organ/cyberimp/brain/operating_system/eagle/t2
	name = "\improper Kowalski Eagle targeting OS T2"
	implant_tier = 2

/obj/item/organ/cyberimp/brain/operating_system/eagle/t3
	name = "\improper Kowalski Eagle targeting OS T3"
	implant_tier = 3

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck
	name = "implanted cyberdeck OS"
	desc = "An OS-slot cyberdeck implant that stores and runs compiled demons without occupying the hands."
	corp_manufacturer = "Benn"
	icon_state = "brain_implant"
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/obj/item/clothing/gloves/cyberdeck/implant_proxy/internal_deck

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/Initialize(mapload)
	. = ..()
	ensure_internal_deck()

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/Destroy()
	QDEL_NULL(internal_deck)
	return ..()

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	ensure_internal_deck()
	internal_deck.forceMove(receiver)
	internal_deck.register_middleclick_owner(receiver)
	internal_deck.sync_demon_actions(receiver)

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	if(internal_deck)
		internal_deck.unregister_middleclick_owner(organ_owner)
		internal_deck.clear_demon_actions(organ_owner)
		internal_deck.forceMove(src)

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/ui_action_click()
	if(!is_implant_functional())
		if(owner)
			to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return
	ensure_internal_deck()
	internal_deck.ui_interact(owner)

/obj/item/organ/cyberimp/brain/operating_system/cyberdeck/proc/ensure_internal_deck()
	if(internal_deck)
		return internal_deck
	internal_deck = new(src)
	return internal_deck

/obj/item/organ/cyberimp/utility
	name = "utility implant"
	desc = "A simple chrome frame reserved for a future specialized implant."
	abstract_type = /obj/item/organ/cyberimp/utility
	icon_state = "implant-toolkit"
	chromity_overheat = 2

/obj/item/organ/cyberimp/utility/jaw
	name = "iron jaw"
	desc = "A reinforced jaw assembly. Its current model is mostly structural chrome with limited active function."
	slot = ORGAN_SLOT_NECK_AUG
	zone = BODY_ZONE_PRECISE_NECK

/obj/item/organ/cyberimp/utility/skull
	name = "reinforced skull"
	desc = "A cranial reinforcement shell. It provides a first-pass slot occupant for skull-grade chrome."
	slot = ORGAN_SLOT_NECK_AUG
	zone = BODY_ZONE_PRECISE_NECK

/obj/item/organ/cyberimp/utility/eyelids
	name = "eyelid HUD mount"
	desc = "A low-power eyelid mount for future optics and HUD modules."
	slot = ORGAN_SLOT_EYELID_AUG
	zone = BODY_ZONE_HEAD

/obj/item/organ/cyberimp/utility/neck
	name = "neck relay"
	desc = "A compact neck relay for future breathing, voice and signal chrome."
	slot = ORGAN_SLOT_NECK_AUG
	zone = BODY_ZONE_PRECISE_NECK

/obj/item/organ/cyberimp/utility/chest
	name = "chest hardpoint"
	desc = "A reinforced chest hardpoint for future torso modules."
	slot = ORGAN_SLOT_CHEST_AUG
	zone = BODY_ZONE_CHEST

/obj/item/organ/cyberimp/utility/belly
	name = "abdominal hardpoint"
	desc = "A reinforced abdominal hardpoint for future metabolism and storage modules."
	slot = ORGAN_SLOT_BELLY_AUG
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/cyberimp/brain/neural_interface/retune_implant()
	. = ..()
	if(. && !cryptographic_key)
		cryptographic_key = generate_neural_cryptokey()

/obj/item/organ/cyberimp/brain/anti_drop
	name = "anti-drop implant"
	desc = "This cybernetic motor implant reinforces grip strength. Twitch ear to lock held items."
	corp_manufacturer = "Ryaznov"
	icon_state = "brain_implant_antidrop"
	var/active = FALSE
	var/list/stored_items = list()
	var/grip_strength_multiplier = 1.25
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/cyberimp/brain/anti_drop/Initialize(mapload)
	. = ..()
	grip_strength_multiplier = tier_value(list(1.25, 1.6, 2))

/obj/item/organ/cyberimp/brain/anti_drop/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	grip_strength_multiplier = tier_value(list(1.25, 1.6, 2), TRUE)

/obj/item/organ/cyberimp/brain/anti_drop/ui_action_click()
	if(!is_implant_functional())
		if(owner)
			to_chat(owner, span_warning("[capitalize(src)] doesn't respond."))
		return
	active = !active
	if(active)
		var/list/hold_list = owner.get_empty_held_indexes()
		if(LAZYLEN(hold_list) == owner.held_items.len)
			to_chat(owner, span_notice("You are not holding any items, your hands relax..."))
			active = FALSE
			return
		for(var/obj/item/held_item as anything in owner.held_items)
			if(!held_item)
				continue
			stored_items += held_item
			to_chat(owner, span_notice("Your [owner.get_held_index_name(owner.get_held_index_of_item(held_item))]'s grip tightens."))
			ADD_TRAIT(held_item, TRAIT_NODROP, IMPLANT_TRAIT)
			RegisterSignal(held_item, COMSIG_ITEM_DROPPED, PROC_REF(on_held_item_dropped))
	else
		release_items()
		to_chat(owner, span_notice("Your hands relax..."))


/obj/item/organ/cyberimp/brain/anti_drop/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/range = severity ? 10 : 5
	var/atom/throw_target
	if(active)
		release_items()
	for(var/obj/item/stored_item as anything in stored_items)
		throw_target = pick(oview(range))
		stored_item.throw_at(throw_target, range, 2)
		to_chat(owner, span_warning("Your [owner.get_held_index_name(owner.get_held_index_of_item(stored_item))] spasms and throws \the [stored_item]!"))
	stored_items = list()


/obj/item/organ/cyberimp/brain/anti_drop/proc/release_items()
	for(var/obj/item/stored_item as anything in stored_items)
		REMOVE_TRAIT(stored_item, TRAIT_NODROP, IMPLANT_TRAIT)
		UnregisterSignal(stored_item, COMSIG_ITEM_DROPPED)
	stored_items = list()


/obj/item/organ/cyberimp/brain/anti_drop/Remove(mob/living/carbon/implant_owner, special, movement_flags)
	if(active)
		ui_action_click()
	..()

/obj/item/organ/cyberimp/brain/anti_drop/proc/on_held_item_dropped(obj/item/source, mob/user)
	SIGNAL_HANDLER
	REMOVE_TRAIT(source, TRAIT_NODROP, IMPLANT_TRAIT)
	UnregisterSignal(source, COMSIG_ITEM_DROPPED)
	stored_items -= source

/obj/item/organ/cyberimp/brain/anti_drop/t2
	name = "anti-drop implant T2"
	implant_tier = 2

/obj/item/organ/cyberimp/brain/anti_drop/t3
	name = "anti-drop implant T3"
	implant_tier = 3

/obj/item/organ/cyberimp/brain/anti_stun
	name = "CNS rebooter implant"
	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
	corp_manufacturer = "Ryaznov"
	icon_state = "brain_implant_rebooter"
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY

	var/static/list/signalCache = list(
		COMSIG_LIVING_STATUS_STUN,
		COMSIG_LIVING_STATUS_IMMOBILIZE,
		COMSIG_LIVING_STATUS_PARALYZE,
	)

	///timer before the implant activates
	var/stun_cap_amount = 1 SECONDS
	///amount of time you are resistant to stuns and knockdowns
	var/stun_resistance_time = 6 SECONDS
	COOLDOWN_DECLARE(implant_cooldown)

/obj/item/organ/cyberimp/brain/anti_stun/on_mob_remove(mob/living/carbon/implant_owner)
	. = ..()
	UnregisterSignal(implant_owner, signalCache)
	UnregisterSignal(implant_owner, COMSIG_LIVING_ENTER_STAMCRIT)
	remove_stun_buffs(implant_owner)

/obj/item/organ/cyberimp/brain/anti_stun/on_mob_insert(mob/living/carbon/receiver)
	. = ..()
	RegisterSignals(receiver, signalCache, PROC_REF(on_signal))
	RegisterSignal(receiver, COMSIG_LIVING_ENTER_STAMCRIT, PROC_REF(on_stamcrit))

/obj/item/organ/cyberimp/brain/anti_stun/proc/on_signal(datum/source, amount)
	SIGNAL_HANDLER
	if(is_implant_functional() && amount > 0)
		addtimer(CALLBACK(src, PROC_REF(clear_stuns)), stun_cap_amount, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/cyberimp/brain/anti_stun/proc/on_stamcrit(datum/source)
	SIGNAL_HANDLER
	if(is_implant_functional())
		addtimer(CALLBACK(src, PROC_REF(clear_stuns)), stun_cap_amount, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/cyberimp/brain/anti_stun/proc/clear_stuns()
	if(!is_implant_functional() || !COOLDOWN_FINISHED(src, implant_cooldown))
		return

	owner.SetStun(0)
	owner.SetKnockdown(0)
	owner.SetImmobilized(0)
	owner.SetParalyzed(0)
	owner.set_stamina_loss(0)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living, set_stamina_loss), 0), stun_resistance_time)

	do_sparks(5, TRUE, src)

	give_stun_buffs(owner)
	addtimer(CALLBACK(src, PROC_REF(remove_stun_buffs), owner), stun_resistance_time)

	var/reboot_interval = 60 SECONDS * get_cyberpunk_implant_passive_interval_multiplier()
	COOLDOWN_START(src, implant_cooldown, reboot_interval)
	addtimer(CALLBACK(src, PROC_REF(implant_ready)), reboot_interval)

/obj/item/organ/cyberimp/brain/anti_stun/proc/implant_ready()
	if(owner)
		to_chat(owner, span_purple("Your rebooter implant is ready."))

/obj/item/organ/cyberimp/brain/anti_stun/proc/give_stun_buffs(mob/living/give_to = owner)
	give_to.add_traits(list(TRAIT_STUNIMMUNE, TRAIT_BATON_RESISTANCE), REF(src))
	give_to.add_movespeed_mod_immunities(REF(src), /datum/movespeed_modifier/damage_slowdown)

/obj/item/organ/cyberimp/brain/anti_stun/proc/remove_stun_buffs(mob/living/remove_from = owner)
	remove_from.remove_traits(list(TRAIT_STUNIMMUNE, TRAIT_BATON_RESISTANCE), REF(src))
	remove_from.remove_movespeed_mod_immunities(REF(src), /datum/movespeed_modifier/damage_slowdown)

/obj/item/organ/cyberimp/brain/anti_stun/emp_act(severity)
	. = ..()
	if((organ_flags & ORGAN_FAILING) || . & EMP_PROTECT_SELF)
		return
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, PROC_REF(reboot)), 90 / severity)

/obj/item/organ/cyberimp/brain/anti_stun/proc/reboot()
	organ_flags &= ~ORGAN_FAILING
	implant_ready()

/obj/item/organ/cyberimp/brain/surgical_processor
	name = "surgical processor implant"
	desc = "A cybernetic brain implant that allows you to perform advanced operations anywhere, anytime."
	corp_manufacturer = "Ryaznov"
	icon_state = "brain_implant_antidrop"
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY
	emp_stun_duration = 0 SECONDS
	emp_immobilize_duration = 4 SECONDS
	/// Lazylist of surgeries this implant provides
	var/list/loaded_surgeries
	var/surgery_speed_multiplier = 1.15

/obj/item/organ/cyberimp/brain/surgical_processor/examine(mob/user)
	. = ..()
	if(length(loaded_surgeries))
		. += span_info("Load surgeries from an operating compuer or a disk containing surgery data. Loaded surgeries:")
		for(var/datum/surgery_operation/downloaded_surgery as anything in GLOB.operations.get_instances_from(loaded_surgeries))
			if(!(downloaded_surgery.operation_flags & OPERATION_LOCKED))
				continue
			// for simplicitly, filters out mechanical subtypes of normal surgeries
			if((downloaded_surgery.operation_flags & OPERATION_MECHANIC) && (downloaded_surgery.parent_type in loaded_surgeries))
				continue
			. += span_info("&bull; [capitalize(downloaded_surgery.rnd_name || downloaded_surgery.name)]")

	else
		. += span_info("Load surgeries from an operating compuer or a disk containing surgery data.")
		. += span_info("No surgeries loaded. Surgeries must be loaded <i>before</i> installation.")

/obj/item/organ/cyberimp/brain/surgical_processor/proc/load_surgeries(mob/living/user, obj/design_holder)
	balloon_alert(user, "copying designs...")
	playsound(src, 'sound/machines/terminal/terminal_processing.ogg', 25, TRUE)
	if(do_after(user, 1 SECONDS, target = design_holder))
		if(istype(design_holder, /obj/item/disk/surgery))
			var/obj/item/disk/surgery/surgery_disk = design_holder
			LAZYOR(loaded_surgeries, surgery_disk.surgeries)
		else
			var/obj/machinery/computer/operating/surgery_computer = design_holder
			LAZYOR(loaded_surgeries, surgery_computer.advanced_surgeries)
		playsound(src, 'sound/machines/terminal/terminal_success.ogg', 25, TRUE)
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/organ/cyberimp/brain/surgical_processor/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(istype(interacting_with, /obj/item/disk/surgery) || istype(interacting_with, /obj/machinery/computer/operating))
		return load_surgeries(user, interacting_with)
	return NONE

/obj/item/organ/cyberimp/brain/surgical_processor/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/disk/surgery))
		return load_surgeries(user, tool)
	return NONE

/obj/item/organ/cyberimp/brain/surgical_processor/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	RegisterSignal(organ_owner, COMSIG_LIVING_OPERATING_ON, PROC_REF(check_surgery))
	organ_owner.add_surgery_speed_mod(REF(src), surgery_speed_multiplier * get_corporate_synergy_multiplier(), INFINITY)

/obj/item/organ/cyberimp/brain/surgical_processor/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	UnregisterSignal(organ_owner, COMSIG_LIVING_OPERATING_ON)
	organ_owner.remove_surgery_speed_mod(REF(src))

/obj/item/organ/cyberimp/brain/surgical_processor/proc/check_surgery(datum/source, atom/movable/operating_on, list/operations)
	SIGNAL_HANDLER

	if(organ_flags & (ORGAN_FAILING|ORGAN_EMP))
		return

	operations |= loaded_surgeries

/obj/item/organ/cyberimp/brain/surgical_processor/emp_act(severity)
	. = ..()
	if(isnull(owner) || (. & EMP_PROTECT_SELF))
		return

	var/obj/item/organ/surgeon_brain = owner.get_organ_by_type(/obj/item/organ/brain)
	surgeon_brain.apply_organ_damage(20 / severity, maximum = 120)


	var/duration = (30 SECONDS) / severity
	if(owner.mob_mood?.mood_modifier > 0)
		// forced insanity - reset to "only a little crazy" after
		owner.mob_mood.set_sanity(SANITY_INSANE)
		addtimer(CALLBACK(owner.mob_mood, TYPE_PROC_REF(/datum/mood, reset_sanity), SANITY_UNSTABLE + 10), duration, TIMER_DELETE_ME)
		// and some moodlets to sell the sanity loss
		owner.add_mood_event("surgery_emp", /datum/mood_event/surgery_emp_active)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living, add_mood_event), "surgery_emp", /datum/mood_event/surgery_emp_expired), duration, TIMER_DELETE_ME)

	// causes the surgeon to go crazy and start stabbing people
	owner.apply_status_effect(/datum/status_effect/forced_combat, duration, (rand(8, 16) / severity))
	to_chat(owner, span_boldwarning("Your surgical processor malfunctions, giving you an overwhelming urge to incise, saw, and stitch!"))

/datum/mood_event/surgery_emp_active
	description = "THE PATIENT WILL NOT SURVIVE UNLESS THE OPERATION IS COMPLETE!"
	mood_change = -90
	timeout = 1 MINUTES
	special_screen_obj = "mood_despair"

/datum/mood_event/surgery_emp_expired
	description = "I lost control - Thankfully it's over now."
	timeout = 5 MINUTES

/obj/item/organ/cyberimp/brain/surgical_processor/pre_loaded
	loaded_surgeries = list(
		/datum/surgery_operation/basic/tend_wounds/combo/upgraded/master,
		/datum/surgery_operation/limb/bioware/cortex_folding,
		/datum/surgery_operation/limb/bioware/cortex_folding/mechanic,
		/datum/surgery_operation/limb/bioware/cortex_imprint,
		/datum/surgery_operation/limb/bioware/cortex_imprint/mechanic,
		/datum/surgery_operation/limb/bioware/ligament_hook,
		/datum/surgery_operation/limb/bioware/ligament_hook/mechanic,
		/datum/surgery_operation/limb/bioware/ligament_reinforcement,
		/datum/surgery_operation/limb/bioware/ligament_reinforcement/mechanic,
		/datum/surgery_operation/limb/bioware/muscled_veins,
		/datum/surgery_operation/limb/bioware/muscled_veins/mechanic,
		/datum/surgery_operation/limb/bioware/nerve_grounding,
		/datum/surgery_operation/limb/bioware/nerve_grounding/mechanic,
		/datum/surgery_operation/limb/bioware/nerve_splicing,
		/datum/surgery_operation/limb/bioware/nerve_splicing/mechanic,
		/datum/surgery_operation/limb/bioware/vein_threading,
		/datum/surgery_operation/limb/bioware/vein_threading/mechanic,
		/datum/surgery_operation/organ/brainwash,
		/datum/surgery_operation/organ/brainwash/mechanic,
		/datum/surgery_operation/organ/pacify,
		/datum/surgery_operation/organ/pacify/mechanic,
	)

/obj/item/organ/cyberimp/brain/surgical_processor/t2
	name = "surgical processor implant T2"
	implant_tier = 2
	surgery_speed_multiplier = 1.3

/obj/item/organ/cyberimp/brain/surgical_processor/t3
	name = "surgical processor implant T3"
	implant_tier = 3
	surgery_speed_multiplier = 1.5

/obj/item/organ/cyberimp/brain/neurostabilizer
	name = "\improper Samantas neurostabilizer"
	desc = "A psychosomatic regulator that reduces the practical force of negative mood effects."
	corp_manufacturer = "Starlight"
	icon_state = "brain_implant"
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY
	chromity_overheat = 2
	var/negative_mood_multiplier = 0.85

/obj/item/organ/cyberimp/brain/neurostabilizer/Initialize(mapload)
	. = ..()
	negative_mood_multiplier = tier_value(list(0.85, 0.7, 0.5))

/obj/item/organ/cyberimp/brain/neurostabilizer/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	negative_mood_multiplier = max(0.1, 1 - ((1 - tier_value(list(0.85, 0.7, 0.5))) * get_corporate_synergy_multiplier()))

/obj/item/organ/cyberimp/brain/neurostabilizer/t2
	name = "\improper Samantas neurostabilizer T2"
	implant_tier = 2

/obj/item/organ/cyberimp/brain/neurostabilizer/t3
	name = "\improper Samantas neurostabilizer T3"
	implant_tier = 3

/obj/item/organ/cyberimp/brain/pain_editor
	name = "pain editor"
	desc = "A cranial pain gate for future pain-processing hooks."
	icon_state = "brain_implant"
	slot = ORGAN_SLOT_OS
	slot_capacity = CYBERPUNK_OS_SLOT_CAPACITY
	chromity_overheat = 3

/obj/item/organ/cyberimp/utility/skull/subdermal_armor
	name = "subdermal armor lattice"
	desc = "An external armor weave installed under the skin. Higher tiers protect more and slow more."
	corp_manufacturer = "Ryaznov"
	implant_flags = IMPLANT_REQUIRES_NEURAL | IMPLANT_PASSIVE | IMPLANT_EXTERNAL
	chromity_overheat = 2
	var/armor_value = 8
	var/speed_penalty = 0.05

/obj/item/organ/cyberimp/utility/skull/subdermal_armor/Initialize(mapload)
	. = ..()
	armor_value = tier_value(list(8, 14, 22))
	speed_penalty = tier_value(list(0.05, 0.1, 0.18))

/obj/item/organ/cyberimp/utility/skull/subdermal_armor/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	armor_value = tier_value(list(8, 14, 22), TRUE)
	organ_owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberimp_subdermal_armor, multiplicative_slowdown = speed_penalty)

/obj/item/organ/cyberimp/utility/skull/subdermal_armor/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	organ_owner.remove_movespeed_modifier(/datum/movespeed_modifier/cyberimp_subdermal_armor)

/obj/item/organ/cyberimp/utility/skull/subdermal_armor/t2
	name = "subdermal armor lattice T2"
	implant_tier = 2

/obj/item/organ/cyberimp/utility/skull/subdermal_armor/t3
	name = "subdermal armor lattice T3"
	implant_tier = 3

/obj/item/organ/cyberimp/utility/skull/opticamo_surface
	name = "opticamo surface"
	desc = "A skin-grade optic camouflage surface. Tiers improve invisibility strength for future stealth hooks."
	corp_manufacturer = "Benn"
	chromity_overheat = 6
	var/invisibility_strength = 0.35

/obj/item/organ/cyberimp/utility/skull/opticamo_surface/Initialize(mapload)
	. = ..()
	invisibility_strength = min(1, tier_value(list(0.35, 0.6, 0.85)))

/obj/item/organ/cyberimp/utility/skull/opticamo_surface/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	invisibility_strength = min(1, tier_value(list(0.35, 0.6, 0.85), TRUE))

/obj/item/organ/cyberimp/utility/skull/opticamo_surface/t2
	name = "opticamo surface T2"
	implant_tier = 2

/obj/item/organ/cyberimp/utility/skull/opticamo_surface/t3
	name = "opticamo surface T3"
	implant_tier = 3

/obj/item/organ/cyberimp/leg
	name = "leg-mounted implant"
	desc = "A cybernetic implant installed into a leg hardpoint."
	abstract_type = /obj/item/organ/cyberimp/leg
	zone = BODY_ZONE_R_LEG
	slot = ORGAN_SLOT_RIGHT_LEG_AUG
	w_class = WEIGHT_CLASS_SMALL
	valid_zones = list(
		BODY_ZONE_R_LEG = ORGAN_SLOT_RIGHT_LEG_AUG,
		BODY_ZONE_L_LEG = ORGAN_SLOT_LEFT_LEG_AUG,
	)

/obj/item/organ/cyberimp/leg/speed
	name = "leg speed actuator"
	desc = "A leg actuator package that improves sprint and running response."
	corp_manufacturer = "Benn"
	icon_state = "implant-toolkit"
	chromity_overheat = 3
	var/speed_bonus = -0.08

/obj/item/organ/cyberimp/leg/speed/Initialize(mapload)
	. = ..()
	speed_bonus = tier_value(list(-0.08, -0.14, -0.22))

/obj/item/organ/cyberimp/leg/speed/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	speed_bonus = tier_value(list(-0.08, -0.14, -0.22), TRUE)
	organ_owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberimp_leg_speed, multiplicative_slowdown = speed_bonus)

/obj/item/organ/cyberimp/leg/speed/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	organ_owner.remove_movespeed_modifier(/datum/movespeed_modifier/cyberimp_leg_speed)

/obj/item/organ/cyberimp/leg/speed/t2
	name = "leg speed actuator T2"
	implant_tier = 2

/obj/item/organ/cyberimp/leg/speed/t3
	name = "leg speed actuator T3"
	implant_tier = 3

/obj/item/organ/cyberimp/leg/silent_step
	name = "silent step implant"
	desc = "A passive gait suppressor that silences all footsteps made by the body."
	corp_manufacturer = "Benn"
	icon_state = "implant-toolkit"
	chromity_overheat = 1

/obj/item/organ/cyberimp/leg/silent_step/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	ADD_TRAIT(organ_owner, TRAIT_SILENT_FOOTSTEPS, REF(src))

/obj/item/organ/cyberimp/leg/silent_step/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	REMOVE_TRAIT(organ_owner, TRAIT_SILENT_FOOTSTEPS, REF(src))

//[[[[MOUTH]]]]
/obj/item/organ/cyberimp/mouth
	zone = BODY_ZONE_PRECISE_MOUTH

/obj/item/organ/cyberimp/mouth/breathing_tube
	name = "breathing tube implant"
	desc = "This simple implant adds an internals connector to your back, allowing you to use internals without a mask and protecting you from being choked."
	icon_state = "implant_mask"
	slot = ORGAN_SLOT_NECK_AUG
	zone = BODY_ZONE_PRECISE_NECK
	w_class = WEIGHT_CLASS_TINY
	aug_overlay = "breathing_tube"

/obj/item/organ/cyberimp/mouth/breathing_tube/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(60/severity))
		to_chat(owner, span_warning("Your breathing tube suddenly closes!"))
		owner.losebreath += 2
