// Cyberpunk 13 cyberspace: network storage and dedigitizer.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/obj/item/cyberspace_storage
	name = "network storage"
	desc = "A compressed piece of network storage. It needs a dedigitizer to become physical loot."
	icon = 'icons/obj/economy.dmi'
	icon_state = "holochip"
	w_class = WEIGHT_CLASS_SMALL
	var/list/reward_types = list(
		/obj/item/holochip = 500,
		/obj/item/stack/ore/iron = 2,
		/obj/item/stack/ore/glass = 2,
	)

/obj/item/cyberspace_storage/proc/dedigitize(atom/output_location, mob/user)
	if(!output_location)
		output_location = drop_location()
	if(!output_location)
		return FALSE

	for(var/reward_type in reward_types)
		var/reward_amount = reward_types[reward_type]
		new reward_type(output_location, reward_amount)

	if(user)
		to_chat(user, span_notice("[src] unfolds into physical resources."))
	qdel(src)
	return TRUE

/obj/item/cyberspace_storage/reward
	name = "dense network storage"
	desc = "A denser piece of network storage taken from an aggressive Veil program."
	reward_types = list(
		/obj/item/holochip = 750,
		/obj/item/stack/ore/iron = 3,
		/obj/item/stack/ore/titanium = 1,
	)

/obj/machinery/dedigitizer
	name = "dedigitizer"
	desc = "A machine that unfolds network storage into physical items."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "byteforge"
	base_icon_state = "byteforge"
	density = TRUE
	anchored = TRUE
	circuit = null

/obj/machinery/dedigitizer/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberspace_storage))
		var/obj/item/cyberspace_storage/storage = attacking_item
		flash()
		storage.dedigitize(drop_location(), user)
		return TRUE
	return ..()

/obj/machinery/dedigitizer/proc/flash()
	flick("byteforge_prespawn", src)
	playsound(src, 'sound/effects/magic/blink.ogg', 50, TRUE)
	do_sparks(3, TRUE, loc, spark_type = /datum/effect_system/basic/spark_spread/quantum)

/proc/get_redeemed_veil_reward_keys()
	var/static/list/redeemed_keys = list()
	return redeemed_keys

/proc/is_veil_reward_key_redeemed(key)
	if(!key)
		return TRUE
	return !!get_redeemed_veil_reward_keys()[key]

/proc/redeem_veil_reward_key(key)
	if(!key || is_veil_reward_key_redeemed(key))
		return FALSE
	get_redeemed_veil_reward_keys()[key] = TRUE
	for(var/mob/living/living_mob as anything in GLOB.mob_living_list)
		var/obj/item/organ/cyberimp/brain/neural_interface/interface = living_mob.get_neural_interface()
		interface?.remove_veil_reward_key(key)
	return TRUE

/proc/generate_veil_reward_key()
	return uppertext(copytext(md5("[world.time]-[world.realtime]-[rand(1, 999999)]-[rand(1, 999999)]"), 1, CYBERSPACE_VEIL_REWARD_KEY_LENGTH + 1))

/proc/get_veil_reward_key_seed(key)
	var/seed = 0
	for(var/i in 1 to length(key))
		seed += text2ascii(key, i)
	return seed

/proc/create_veil_reward_from_key(key, level, atom/output_location, mob/user)
	if(!output_location)
		return null
	level = clamp(round(level), 1, CYBERSPACE_VEIL_DATA_VAULT_MAX_LEVEL)
	var/seed = get_veil_reward_key_seed(key)
	if(level >= 3 || (seed % 2))
		var/obj/item/cyberdemon_disk/veil/disk = new(output_location)
		disk.build_from_veil_key(key, level)
		if(user)
			to_chat(user, span_notice("[disk] materializes from the decoded Veil key."))
		return disk

	var/list/reward_types = list(
		/obj/item/holochip,
		/obj/item/stack/ore/gold,
		/obj/item/stack/ore/titanium,
		/obj/item/stock_parts/power_store/cell/high,
	)
	var/reward_type = reward_types[(seed % length(reward_types)) + 1]
	var/reward_amount = max(1, level * 2)
	if(ispath(reward_type, /obj/item/holochip))
		reward_amount = 500 * level
	var/obj/item/reward = new reward_type(output_location, reward_amount)
	if(user)
		to_chat(user, span_notice("[reward] materializes from the decoded Veil key."))
	return reward

/obj/item/cyberspace_old_data_chip
	name = "old data chip"
	desc = "A brittle chip torn out of an ancient Veil data vault. Use it to burn its reward key into your neural interface."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk1"
	w_class = WEIGHT_CLASS_SMALL
	var/reward_key
	var/reward_level = 1

/obj/item/cyberspace_old_data_chip/Initialize(mapload)
	. = ..()
	if(!reward_key)
		reward_key = generate_veil_reward_key()
	reward_level = clamp(round(reward_level), 1, CYBERSPACE_VEIL_DATA_VAULT_MAX_LEVEL)

/obj/item/cyberspace_old_data_chip/proc/record_key(mob/living/user)
	if(!istype(user))
		return FALSE
	if(is_veil_reward_key_redeemed(reward_key))
		to_chat(user, span_warning("[src]'s key has already been spent."))
		return FALSE
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = user.get_neural_interface()
	if(!interface || !interface.is_implant_functional())
		to_chat(user, span_warning("You need a functional neural interface to remember [src]'s key."))
		return FALSE
	if(!interface.remember_veil_reward_key(reward_key, reward_level))
		to_chat(user, span_warning("[src]'s key cannot be recorded."))
		return FALSE
	to_chat(user, span_notice("You burn Veil reward key <b>[reward_key]</b> into your neural memory."))
	return TRUE

/obj/item/cyberspace_old_data_chip/pickup(mob/user)
	. = ..()
	if(record_key(user))
		qdel(src)

/obj/item/cyberspace_old_data_chip/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	if(record_key(user))
		qdel(src)
	return TRUE

/obj/machinery/veil_decipherizer
	name = "Veil decipherizer"
	desc = "A hardline decoder that consumes one remembered Veil reward key and prints a physical reward."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "byteforge"
	base_icon_state = "byteforge"
	density = TRUE
	anchored = TRUE
	circuit = null

/obj/machinery/veil_decipherizer/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, span_warning("[src] is offline."))
		return TRUE
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = user.get_neural_interface()
	if(!interface || !interface.is_implant_functional())
		to_chat(user, span_warning("You need a functional neural interface to feed [src] a remembered Veil key."))
		return TRUE
	var/key = interface.choose_veil_reward_key(user)
	if(!key)
		return TRUE
	var/level = interface.veil_reward_keys?[key] || 1
	if(!redeem_veil_reward_key(key))
		to_chat(user, span_warning("The key is already spent."))
		return TRUE
	flash()
	create_veil_reward_from_key(key, level, drop_location(), user)
	return TRUE

/obj/machinery/veil_decipherizer/proc/flash()
	flick("byteforge_prespawn", src)
	playsound(src, 'sound/effects/magic/blink.ogg', 50, TRUE)
	do_sparks(5, TRUE, loc, spark_type = /datum/effect_system/basic/spark_spread/quantum)

/obj/machinery/cyberspace_terminal
	name = "cyberspace access terminal"
	desc = "A hardline terminal that lets a neural-interface user project into the local network layer."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "comm_server"
	base_icon_state = "comm_server"
	density = TRUE
	anchored = TRUE
	circuit = null

/obj/machinery/cyberspace_terminal/proc/toggle_cyberspace_access(mob/living/user)
	if(!istype(user))
		return FALSE
	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, span_warning("[src] is offline."))
		return TRUE
	if(user.cyberspace_session)
		return user.stop_cyberspace_session()
	return user.start_cyberspace_session(CYBERSPACE_MODE_AVATAR, src)

/obj/machinery/cyberspace_terminal/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	toggle_cyberspace_access(user)
	return TRUE

/obj/machinery/cyberspace_terminal/attack_hand_secondary(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	toggle_cyberspace_access(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/cyberspace_engram_chip
	name = "engram chip"
	desc = "A portable anchor for a digitized engram."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk1"
	w_class = WEIGHT_CLASS_SMALL
	var/datum/weakref/bound_body_ref
	var/transition_blocked_until = 0

/obj/item/cyberspace_engram_chip/proc/get_bound_body()
	return bound_body_ref?.resolve()

/obj/item/cyberspace_engram_chip/proc/bind_body(mob/living/target, mob/user)
	if(!istype(target))
		return FALSE
	bound_body_ref = WEAKREF(target)
	to_chat(user || target, span_notice("[src] binds to [target]'s engram signature."))
	return TRUE

/obj/item/cyberspace_engram_chip/proc/eject_bound_engram(mob/living/user)
	var/mob/living/bound_body = get_bound_body()
	if(!bound_body)
		to_chat(user, span_warning("[src] has no bound engram."))
		return FALSE
	if(world.time < transition_blocked_until || world.time < bound_body.cyberspace_transition_blocked_until)
		to_chat(user, span_warning("[src]'s engram transfer channel is locked."))
		return FALSE
	if(bound_body.is_projected_into_cyberspace())
		to_chat(user, span_warning("[bound_body] is already active in cyberspace."))
		return FALSE
	if(!bound_body.start_cyberspace_session(CYBERSPACE_MODE_ENGRAM, src))
		return FALSE
	to_chat(user || bound_body, span_notice("[src] ejects [bound_body]'s engram into cyberspace."))
	return TRUE

/obj/item/cyberspace_engram_chip/proc/receive_engram(mob/living/user)
	var/mob/living/bound_body = get_bound_body()
	if(!bound_body || !bound_body.cyberspace_session || bound_body.cyberspace_session.mode != CYBERSPACE_MODE_ENGRAM)
		to_chat(user, span_warning("[src] has no active engram to receive."))
		return FALSE
	if(bound_body.cyberspace_session.get_engram_anchor() != src)
		to_chat(user, span_warning("[src] is not the active anchor for that engram."))
		return FALSE
	if(!bound_body.cyberspace_session.can_return_to_body())
		to_chat(user, span_warning("The engram must be within [CYBERSPACE_ENGRAM_PHYSICAL_RANGE] tiles of [src]."))
		return FALSE
	bound_body.cyberspace_session.end_session()
	transition_blocked_until = world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK
	bound_body.cyberspace_transition_blocked_until = max(bound_body.cyberspace_transition_blocked_until, transition_blocked_until)
	to_chat(user || bound_body, span_notice("[src] receives [bound_body]'s engram and locks transfer for [DisplayTimeText(CYBERSPACE_ENGRAM_TRANSFER_BLOCK)]."))
	return TRUE

/obj/item/cyberspace_engram_chip/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	var/mob/living/bound_body = get_bound_body()
	if(bound_body && bound_body.cyberspace_session && bound_body.cyberspace_session.mode == CYBERSPACE_MODE_ENGRAM)
		receive_engram(user)
	else
		eject_bound_engram(user)
	return TRUE

/obj/machinery/engrammator
	name = "engrammator"
	desc = "A server-grade terminal that digitizes, anchors, receives and transfers engrams."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "comm_server"
	base_icon_state = "comm_server"
	density = TRUE
	anchored = TRUE
	var/datum/weakref/bound_body_ref
	var/obj/item/cyberspace_engram_chip/inserted_chip

/obj/machinery/engrammator/Destroy(force)
	bound_body_ref = null
	QDEL_NULL(inserted_chip)
	return ..()

/obj/machinery/engrammator/proc/get_bound_body()
	return bound_body_ref?.resolve()

/obj/machinery/engrammator/proc/bind_body(mob/living/target, mob/user)
	if(!istype(target))
		return FALSE
	bound_body_ref = WEAKREF(target)
	to_chat(user || target, span_notice("[src] binds to [target]'s engram signature."))
	return TRUE

/obj/machinery/engrammator/proc/insert_engram_chip(obj/item/cyberspace_engram_chip/chip, mob/user)
	if(!chip || inserted_chip == chip)
		return FALSE
	if(inserted_chip)
		eject_engram_chip(user)
	if(user && !user.transferItemToLoc(chip, src))
		return FALSE
	inserted_chip = chip
	to_chat(user, span_notice("You insert [chip] into [src]."))
	return TRUE

/obj/machinery/engrammator/proc/eject_engram_chip(mob/user)
	if(!inserted_chip)
		to_chat(user, span_warning("[src] has no engram chip inserted."))
		return FALSE
	var/obj/item/cyberspace_engram_chip/chip = inserted_chip
	inserted_chip = null
	chip.forceMove(drop_location())
	if(user)
		user.put_in_hands(chip)
		to_chat(user, span_notice("You eject [chip] from [src]."))
	return TRUE

/obj/machinery/engrammator/proc/receive_stored_engram(mob/living/user)
	var/mob/living/bound_body = get_bound_body()
	if(!bound_body || !bound_body.cyberspace_session || bound_body.cyberspace_session.mode != CYBERSPACE_MODE_ENGRAM)
		to_chat(user, span_warning("[src] has no active engram to receive."))
		return FALSE
	if(bound_body.cyberspace_session.get_engram_anchor() != src)
		to_chat(user, span_warning("[src] is not the active anchor for that engram."))
		return FALSE
	if(!bound_body.cyberspace_session.can_return_to_body())
		to_chat(user, span_warning("The engram must be within [CYBERSPACE_ENGRAM_PHYSICAL_RANGE] tiles of [src]."))
		return FALSE
	bound_body.cyberspace_session.end_session()
	bound_body.cyberspace_transition_blocked_until = max(bound_body.cyberspace_transition_blocked_until, world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK)
	to_chat(user || bound_body, span_notice("[src] receives [bound_body]'s engram and locks transfer for [DisplayTimeText(CYBERSPACE_ENGRAM_TRANSFER_BLOCK)]."))
	return TRUE

/obj/machinery/engrammator/proc/eject_stored_engram(mob/living/user)
	var/mob/living/bound_body = get_bound_body()
	if(!bound_body)
		if(!bind_body(user, user))
			return FALSE
		bound_body = user
	if(world.time < bound_body.cyberspace_transition_blocked_until)
		to_chat(user, span_warning("[src]'s engram transfer channel is locked."))
		return FALSE
	if(bound_body.is_projected_into_cyberspace())
		to_chat(user, span_warning("[bound_body] is already active in cyberspace."))
		return FALSE
	if(!bound_body.start_cyberspace_session(CYBERSPACE_MODE_ENGRAM, src))
		return FALSE
	to_chat(user || bound_body, span_notice("[src] unfolds [bound_body]'s engram into cyberspace."))
	return TRUE

/obj/machinery/engrammator/proc/write_active_engram_to_chip(mob/living/user)
	if(!inserted_chip)
		return FALSE
	var/mob/living/bound_body = get_bound_body()
	if(!bound_body || !bound_body.cyberspace_session || bound_body.cyberspace_session.mode != CYBERSPACE_MODE_ENGRAM)
		return FALSE
	if(bound_body.cyberspace_session.get_engram_anchor() != src)
		return FALSE
	if(!inserted_chip.bind_body(bound_body, user))
		return FALSE
	bound_body.cyberspace_session.set_engram_anchor(inserted_chip)
	bound_body.cyberspace_transition_blocked_until = max(bound_body.cyberspace_transition_blocked_until, world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK)
	inserted_chip.transition_blocked_until = max(inserted_chip.transition_blocked_until, world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK)
	bound_body_ref = null
	to_chat(user, span_notice("You write [bound_body]'s active engram from [src] to [inserted_chip]."))
	return TRUE

/obj/machinery/engrammator/proc/operate(mob/living/user)
	if(!istype(user))
		return FALSE
	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, span_warning("[src] is offline."))
		return FALSE
	if(inserted_chip)
		if(write_active_engram_to_chip(user))
			return TRUE
		var/mob/living/chip_body = inserted_chip.get_bound_body()
		if(chip_body && chip_body.cyberspace_session && chip_body.cyberspace_session.mode == CYBERSPACE_MODE_ENGRAM)
			return inserted_chip.receive_engram(user)
		return inserted_chip.eject_bound_engram(user)
	var/mob/living/bound_body = get_bound_body()
	if(bound_body && bound_body.cyberspace_session && bound_body.cyberspace_session.mode == CYBERSPACE_MODE_ENGRAM)
		return receive_stored_engram(user)
	return eject_stored_engram(user)

/obj/machinery/engrammator/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	operate(user)
	return TRUE

/obj/machinery/engrammator/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberspace_engram_chip))
		return insert_engram_chip(attacking_item, user)
	return ..()

/obj/machinery/engrammator/click_alt(mob/user)
	if(eject_engram_chip(user))
		return CLICK_ACTION_SUCCESS
	return ..()

/datum/cyberspace_demon
	var/demon_name = "blank demon"
	var/description = "An unfinished network ability."
	var/effect = CYBER_DEMON_EFFECT_BURN
	var/effect_power = 1
	var/cast_time = 2 SECONDS
	var/duration = 0
	var/list/special_effects = list()
	var/memory_cost = 1
	var/manufacturer = "Independent"
	var/prebuilt = FALSE
	var/net_data_cost = 0
	var/psychic_damage = CYBER_DEMON_DEFAULT_PSYCHIC_DAMAGE
	var/stamina_cost = CYBER_DEMON_BASE_STAMINA_COST
	var/activation_delay = CYBER_DEMON_DEFAULT_ACTIVATION_DELAY
	var/effect_frequency = CYBER_DEMON_DEFAULT_FREQUENCY
	var/target_attribute = ATTRIBUTE_STRENGTH
	var/target_skill = SKILL_HACKING
	var/cooldown = 0
	var/tmp/next_use = 0

/datum/cyberspace_demon/New()
	. = ..()
	if(!islist(special_effects))
		special_effects = list()

/datum/cyberspace_demon/proc/copy(development_copy = FALSE)
	var/datum/cyberspace_demon/new_demon = new type
	new_demon.demon_name = development_copy ? "[demon_name] copy" : demon_name
	new_demon.description = development_copy ? "Editable development copy of [demon_name]." : description
	new_demon.effect = effect
	new_demon.effect_power = effect_power
	new_demon.cast_time = cast_time
	new_demon.duration = duration
	new_demon.special_effects = special_effects.Copy()
	new_demon.memory_cost = memory_cost
	new_demon.manufacturer = manufacturer
	new_demon.prebuilt = development_copy ? FALSE : prebuilt
	new_demon.net_data_cost = net_data_cost
	new_demon.psychic_damage = psychic_damage
	new_demon.stamina_cost = stamina_cost
	new_demon.activation_delay = activation_delay
	new_demon.effect_frequency = effect_frequency
	new_demon.target_attribute = target_attribute
	new_demon.target_skill = target_skill
	new_demon.cooldown = cooldown
	return new_demon

/datum/cyberspace_demon/proc/get_effective_power(mob/living/caster, physical_world = FALSE)
	var/power = effect_power
	var/power_bonus = caster?.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 1) || 0
	if(power_bonus > 0)
		power *= 1 + (power_bonus / 100)
	power *= caster?.cyberdemon_consume_next_power_multiplier() || 1
	var/synergy = caster?.get_corporate_synergy_multiplier(manufacturer) || 1
	power *= synergy
	power *= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(manufacturer, list("benn_chem_recycling", "ryaznov_overload_loop", "starlight_suppression_loop"), 1, 1.1)
	if(physical_world)
		power *= CYBER_DEMON_PHYSICAL_WORLD_MULTIPLIER
	var/master_chance = caster?.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 6, "value_1") || 0
	var/master_multiplier = caster?.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 6, "value_2") || 0
	if(master_chance > 0 && master_multiplier > 0 && prob(master_chance))
		power *= master_multiplier
	return round(power)

/datum/cyberspace_demon/proc/get_effective_cast_time(mob/living/caster)
	var/effective_cast_time = cast_time
	var/prepare_bonus = caster?.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 1) || 0
	if(prepare_bonus > 0)
		effective_cast_time *= max(0, 1 - (prepare_bonus / 100))
	effective_cast_time *= caster?.cyberdemon_consume_next_prepare_multiplier() || 1
	effective_cast_time /= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(manufacturer, list("benn_chem_tuning", "ryaznov_power_tuning", "starlight_phase_tuning"), 1, 1.1)
	var/instant_chance = caster?.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 5) || 0
	if(instant_chance > 0 && prob(instant_chance))
		return 0
	return max(0, round(effective_cast_time))

/datum/cyberspace_demon/proc/get_effective_cooldown(mob/living/caster)
	var/effective_cooldown = cooldown
	if(effective_cooldown <= 0)
		return 0
	var/synergy = caster?.get_corporate_synergy_multiplier(manufacturer) || 1
	effective_cooldown /= synergy
	effective_cooldown /= SScyberpunk_corporations.cyberpunk_corporate_edict_multiplier(manufacturer, list("benn_chem_tuning", "ryaznov_power_tuning", "starlight_phase_tuning"), 1, 1.05)
	return max(0, round(effective_cooldown))

/datum/cyberspace_demon/proc/get_effective_activation_delay(mob/living/caster)
	var/effective_delay = activation_delay
	if(caster?.cyberdemon_consume_next_instant_activation())
		return 0
	var/activation_bonus = caster?.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 2) || 0
	if(activation_bonus > 0)
		effective_delay *= max(0, 1 - (activation_bonus / 100))
	var/instant_next_chance = caster?.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 6) || 0
	if(instant_next_chance > 0 && prob(instant_next_chance))
		return 0
	return max(0, round(effective_delay))

/datum/cyberspace_demon/proc/get_effective_stamina_cost(mob/living/caster)
	var/effective_cost = stamina_cost
	var/stamina_modifier = caster?.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 2) || 0
	if(stamina_modifier)
		effective_cost *= 1 + (stamina_modifier / 100)
	return max(0, round(effective_cost))

/datum/cyberspace_demon/proc/get_compile_requirement_multiplier(mob/living/user)
	return cyberdemon_compile_requirement_multiplier(user)

/proc/cyberdemon_compile_requirement_multiplier(mob/living/user)
	if(!user?.cyberdemon_has_botanist())
		return 1
	var/hacking_level = user.mind?.get_character_skill_level(SKILL_HACKING) || 0
	return max(0, 1 - (hacking_level * 0.1))

/datum/cyberspace_demon/proc/get_net_data_cost()
	if(net_data_cost)
		return net_data_cost
	return max(0, round(memory_cost + (effect_power / 5) + length(special_effects)))

/datum/cyberspace_demon/proc/get_target_node(atom/target)
	var/obj/effect/cyberspace_node_shell/node_shell = target
	if(istype(node_shell))
		return node_shell.node
	var/obj/effect/cyberspace_object_trace/trace = target
	if(istype(trace))
		return trace.node
	return null

/datum/cyberspace_demon/proc/can_compile(mob/living/user, obj/item/clothing/gloves/cyberdeck/deck, obj/machinery/cyberdemon_terminal/terminal)
	if(length(special_effects) > CYBER_DEMON_MAX_SPECIAL_EFFECTS)
		to_chat(user, span_warning("[demon_name] has too many special effects."))
		return FALSE
	if(deck && !deck.can_store_demon(src, user))
		return FALSE
	if(terminal && !terminal.can_compile(user))
		return FALSE
	var/cost = get_net_data_cost()
	cost = round(cost * get_compile_requirement_multiplier(user))
	if(cost > (user?.mind?.cyber_net_data || 0))
		to_chat(user, span_warning("[demon_name] requires [cost] net-data."))
		return FALSE
	return TRUE

/datum/cyberspace_demon/proc/compile_to_deck(mob/living/user, obj/item/clothing/gloves/cyberdeck/deck, obj/machinery/cyberdemon_terminal/terminal)
	if(!user?.mind || !deck)
		return FALSE
	if(!prebuilt && memory_cost > CYBER_DEMON_MAX_COMPILED_MEMORY)
		to_chat(user, span_warning("[demon_name] requires [memory_cost] memory and cannot be saved to a cyberdeck for use."))
		return FALSE
	if(!can_compile(user, deck, terminal))
		return FALSE
	var/cost = get_net_data_cost()
	cost = round(cost * get_compile_requirement_multiplier(user))
	user.mind.cyber_net_data -= cost
	deck.store_demon(copy(), user)
	deck.start_compile_cooldown()
	terminal?.start_compile_cooldown()
	to_chat(user, span_notice("You compile [demon_name] into [deck]. Net-data left: [user.mind.cyber_net_data]."))
	return TRUE

/datum/cyberspace_demon/proc/compile_to_disk(mob/living/user, obj/item/cyberdemon_disk/disk, obj/machinery/cyberdemon_terminal/terminal)
	if(!user?.mind || !disk)
		return FALSE
	if(length(special_effects) > CYBER_DEMON_MAX_SPECIAL_EFFECTS)
		to_chat(user, span_warning("[demon_name] has too many special effects."))
		return FALSE
	if(terminal && !terminal.can_compile(user))
		return FALSE
	if(!disk.can_store_demon(src, user))
		return FALSE
	var/cost = get_net_data_cost()
	cost = round(cost * get_compile_requirement_multiplier(user))
	if(cost > user.mind.cyber_net_data)
		to_chat(user, span_warning("[demon_name] requires [cost] net-data."))
		return FALSE
	user.mind.cyber_net_data -= cost
	disk.store_demon(copy(), user)
	terminal?.start_compile_cooldown()
	to_chat(user, span_notice("You compile [demon_name] into [disk]. Net-data left: [user.mind.cyber_net_data]."))
	return TRUE

/datum/cyberspace_demon/proc/apply(mob/living/caster, atom/target, obj/item/clothing/gloves/cyberdeck/deck)
	if(!caster || !target || !deck)
		return FALSE
	if(!deck.can_run_demons(caster))
		return FALSE
	if(cooldown > 0 && world.time < next_use)
		to_chat(caster, span_warning("[demon_name] is cooling down for [DisplayTimeText(next_use - world.time)]."))
		return FALSE
	var/physical_world = !caster.is_projected_into_cyberspace()
	var/current_power = get_effective_power(caster, physical_world)
	var/effective_cast_time = get_effective_cast_time(caster)
	if(CYBER_DEMON_SPECIAL_STEALTH in special_effects)
		to_chat(caster, span_notice("[demon_name] suppresses its network signature."))
	to_chat(caster, span_notice("You start preparing [demon_name]."))
	if(effective_cast_time > 0 && !do_after(caster, effective_cast_time, target = target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		to_chat(caster, span_warning("[demon_name] fizzles before activation."))
		return FALSE
	return release_prepared(caster, target, deck, current_power, physical_world)

/datum/cyberspace_demon/proc/release_prepared(mob/living/caster, atom/target, obj/item/clothing/gloves/cyberdeck/deck, current_power, physical_world, activation_delay_multiplier = 1)
	if(!caster || !target || !deck)
		return FALSE
	if(!deck.can_run_demons(caster))
		return FALSE
	var/mob/living/original_target = istype(target, /mob/living) ? target : null
	if(original_target?.cyberdemon_should_reflect_directed_demon(caster, src))
		to_chat(original_target, span_notice("You reflect [demon_name] back through the connection."))
		to_chat(caster, span_warning("[demon_name] reflects back through [original_target]'s neural defense."))
		target = caster
	var/effective_activation_delay = round(get_effective_activation_delay(caster) * max(0, activation_delay_multiplier))
	var/effective_stamina_cost = get_effective_stamina_cost(caster)
	if(caster.cyberdemon_has_botanist())
		var/free_chance = (caster.mind?.get_character_skill_level(SKILL_FAST_CODE) || 0) * 15
		if(free_chance > 0 && prob(free_chance))
			effective_stamina_cost = 0
	if(effective_stamina_cost > 0)
		caster.adjust_stamina_loss(effective_stamina_cost)
	apply_psychic_damage(caster)
	var/effective_cooldown = get_effective_cooldown(caster)
	if(effective_cooldown > 0)
		if((caster?.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 5) || 0) > 0 && prob(caster.mind.get_character_perk_effectiveness(SKILL_FAST_CODE, 5)))
			next_use = 0
		else
			next_use = world.time + effective_cooldown
	if(effective_activation_delay > 0)
		to_chat(caster, span_notice("[demon_name] is unpacking and will activate in [DisplayTimeText(effective_activation_delay)]."))
		addtimer(CALLBACK(src, PROC_REF(activate_deployment), WEAKREF(caster), WEAKREF(target), current_power, physical_world), effective_activation_delay)
		return TRUE
	return activate_deployment(WEAKREF(caster), WEAKREF(target), current_power, physical_world)

/datum/cyberspace_demon/proc/activate_deployment(datum/weakref/caster_ref, datum/weakref/target_ref, current_power, physical_world)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/target = target_ref?.resolve()
	if(!target || QDELETED(target))
		if(caster)
			to_chat(caster, span_warning("[demon_name] loses its target before activation."))
		return FALSE
	if(caster)
		to_chat(caster, span_notice("[demon_name] activates."))
	var/success = apply_effect(caster, target, current_power, physical_world)
	if(success)
		apply_botanist_followups(caster, target, current_power, physical_world)
	return success

/datum/cyberspace_demon/proc/apply_botanist_followups(mob/living/caster, atom/target, current_power, physical_world)
	if(!caster)
		return
	var/power_roll = caster.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 3, "value_1") || 0
	var/power_bonus = caster.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 3, "value_2") || 0
	if(power_roll > 0 && power_bonus > 0 && prob(power_roll))
		caster.cyberdemon_next_power_multiplier = max(caster.cyberdemon_next_power_multiplier, 1 + (power_bonus / 100))
	var/prepare_roll = caster.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 3, "value_1") || 0
	var/prepare_bonus = caster.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 3, "value_2") || 0
	if(prepare_roll > 0 && prepare_bonus > 0 && prob(prepare_roll))
		caster.cyberdemon_next_prepare_multiplier = min(caster.cyberdemon_next_prepare_multiplier, max(0, 1 - (prepare_bonus / 100)))
	var/next_instant_chance = caster.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 6) || 0
	if(next_instant_chance > 0 && prob(next_instant_chance))
		caster.cyberdemon_next_instant_activation = TRUE
	if(!caster.cyberdemon_has_botanist())
		return
	var/repeat_chance = (caster.mind?.get_character_skill_level(SKILL_ENHANCED_CODE) || 0) * 15
	if(repeat_chance > 0 && prob(repeat_chance))
		to_chat(caster, span_notice("[demon_name] self-activates again on the same target."))
		apply_effect(caster, target, current_power, physical_world)

/datum/cyberspace_demon/proc/apply_psychic_damage(mob/living/caster)
	var/damage = psychic_damage
	if(CYBER_DEMON_SPECIAL_STEALTH in special_effects)
		damage = max(0, damage - 1)
	if(damage <= 0 || !caster)
		return
	caster.adjust_organ_loss(ORGAN_SLOT_BRAIN, damage)

/proc/cyberdemon_remove_trait(datum/weakref/living_ref, trait, source)
	var/mob/living/living_target = living_ref?.resolve()
	if(!living_target)
		return
	REMOVE_TRAIT(living_target, trait, source)

/datum/movespeed_modifier/cyberdemon
	variable = TRUE
	id = "cyberdemon"

/datum/actionspeed_modifier/cyberdemon
	variable = TRUE
	id = "cyberdemon"

/mob/living/var/tmp/cyberdemon_block_demons_until = 0
/mob/living/var/tmp/cyberdemon_block_implants_until = 0
/mob/living/var/tmp/cyberdemon_neutralization_block_until = 0
/mob/living/var/tmp/cyberdemon_next_power_multiplier = 1
/mob/living/var/tmp/cyberdemon_next_prepare_multiplier = 1
/mob/living/var/tmp/cyberdemon_next_instant_activation = FALSE

/mob/living/proc/cyberdemon_block_demons(block_duration)
	cyberdemon_block_demons_until = max(cyberdemon_block_demons_until, world.time + block_duration)

/mob/living/proc/cyberdemon_demons_blocked()
	return world.time < cyberdemon_block_demons_until

/mob/living/proc/cyberdemon_block_implants(block_duration)
	cyberdemon_block_implants_until = max(cyberdemon_block_implants_until, world.time + block_duration)

/mob/living/proc/cyberdemon_implants_blocked()
	return world.time < cyberdemon_block_implants_until

/mob/living/proc/cyberdemon_is_hostile_target(mob/living/caster)
	return caster && caster != src

/mob/living/proc/cyberdemon_has_botanist()
	return has_character_giga_perk(ATTRIBUTE_INTELLIGENCE)

/mob/living/proc/cyberdemon_should_reflect_directed_demon(mob/living/caster, datum/cyberspace_demon/demon)
	if(!cyberdemon_is_hostile_target(caster) || !cyberdemon_has_botanist())
		return FALSE
	var/reflect_chance = (mind?.get_character_skill_level(SKILL_ENDURANCE) || 0) * 15
	return reflect_chance > 0 && prob(reflect_chance)

/mob/living/proc/cyberdemon_consume_next_power_multiplier()
	var/multiplier = max(0, cyberdemon_next_power_multiplier || 1)
	cyberdemon_next_power_multiplier = 1
	return multiplier

/mob/living/proc/cyberdemon_consume_next_prepare_multiplier()
	var/multiplier = max(0, cyberdemon_next_prepare_multiplier || 1)
	cyberdemon_next_prepare_multiplier = 1
	return multiplier

/mob/living/proc/cyberdemon_consume_next_instant_activation()
	var/instant = cyberdemon_next_instant_activation
	cyberdemon_next_instant_activation = FALSE
	return instant

/proc/cyberdemon_remove_movespeed_modifier(datum/weakref/living_ref)
	var/mob/living/living_target = living_ref?.resolve()
	if(!living_target)
		return
	living_target.remove_movespeed_modifier(/datum/movespeed_modifier/cyberdemon)

/proc/cyberdemon_remove_actionspeed_modifier(datum/weakref/living_ref)
	var/mob/living/living_target = living_ref?.resolve()
	if(!living_target)
		return
	living_target.remove_actionspeed_modifier(/datum/actionspeed_modifier/cyberdemon)

/proc/cyberdemon_restore_alpha(datum/weakref/target_ref, old_alpha, applied_alpha)
	var/atom/movable/target = target_ref?.resolve()
	if(!target)
		return
	if(target.alpha == applied_alpha)
		target.alpha = old_alpha

/datum/cyberspace_demon/proc/get_cyberspace_avatar_target(atom/target)
	var/mob/eye/cyberspace_avatar/avatar_target = target
	if(istype(avatar_target))
		return avatar_target
	var/mob/living/living_target = target
	if(istype(living_target))
		return living_target.cyberspace_session?.avatar
	return null

/datum/cyberspace_demon/proc/get_cyberspace_body_target(atom/target)
	var/mob/living/living_target = target
	if(istype(living_target))
		return living_target
	var/mob/eye/cyberspace_avatar/avatar_target = target
	if(istype(avatar_target))
		return avatar_target.body_ref?.resolve()
	return null

/datum/cyberspace_demon/proc/apply_visibility_alpha(atom/movable/target, new_alpha, visibility_duration)
	if(!target || visibility_duration <= 0)
		return FALSE
	var/old_alpha = target.alpha
	target.alpha = min(target.alpha, new_alpha)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_restore_alpha), WEAKREF(target), old_alpha, target.alpha), visibility_duration)
	return TRUE

/datum/cyberspace_demon/proc/glitch_nearby_cameras(atom/center)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return
	for(var/obj/machinery/camera/camera in range(CYBER_DEMON_CAMERA_GLITCH_RANGE, center_turf))
		camera.emp_act(EMP_LIGHT, CYBER_DEMON_CAMERA_GLITCH_DURATION)

/datum/cyberspace_demon/proc/move_caster_projection(mob/living/caster, atom/target, announce = TRUE)
	var/turf/target_turf = get_turf(target)
	if(!target_turf || !caster)
		return FALSE
	if(caster.cyberspace_session?.avatar)
		if(!caster.cyberspace_session.can_avatar_move_to(target_turf))
			if(announce)
				to_chat(caster, span_warning("[demon_name] cannot stretch your avatar that far without a node connector."))
			return FALSE
		caster.cyberspace_session.avatar.setLoc(target_turf)
		if(announce)
			to_chat(caster, span_notice("[demon_name] moves your avatar through the network."))
		return TRUE
	caster.forceMove(target_turf)
	if(announce)
		to_chat(caster, span_notice("[demon_name] moves you."))
	return TRUE

/datum/cyberspace_demon/proc/is_hostile_negative_effect(current_power)
	if(current_power < 0)
		return TRUE
	return effect in list(
		CYBER_DEMON_EFFECT_ATTRIBUTE,
		CYBER_DEMON_EFFECT_SKILL,
		CYBER_DEMON_EFFECT_MOVE_SPEED,
		CYBER_DEMON_EFFECT_INTERACTION_SPEED,
		CYBER_DEMON_EFFECT_BLIND,
		CYBER_DEMON_EFFECT_DEAF,
		CYBER_DEMON_EFFECT_SILENCE,
		CYBER_DEMON_EFFECT_BLOCK_IMPLANTS,
		CYBER_DEMON_EFFECT_BLOCK_DEMONS,
		CYBER_DEMON_EFFECT_DEBUFF,
	)

/datum/cyberspace_demon/proc/requires_neural_living_target()
	return !(effect in list(
		CYBER_DEMON_EFFECT_PROTECTION,
		CYBER_DEMON_EFFECT_WALL,
		CYBER_DEMON_EFFECT_CRYPTOKEY,
		CYBER_DEMON_EFFECT_MOVEMENT,
		CYBER_DEMON_EFFECT_CLOAK,
		CYBER_DEMON_EFFECT_VANISH,
		CYBER_DEMON_EFFECT_ENGRAM_STUN,
	))

/datum/cyberspace_demon/proc/apply_neutralization(mob/living/caster, mob/living/target, current_power, effect_duration)
	var/list/result = list(
		"blocked" = FALSE,
		"power" = current_power,
		"duration" = effect_duration,
	)
	if(!target?.cyberdemon_is_hostile_target(caster) || !is_hostile_negative_effect(current_power))
		return result
	var/block_cooldown_minutes = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 6) || 0
	if(block_cooldown_minutes > 0 && world.time >= target.cyberdemon_neutralization_block_until)
		target.cyberdemon_neutralization_block_until = world.time + (block_cooldown_minutes MINUTES)
		result["blocked"] = TRUE
		to_chat(target, span_notice("Your neuralization fully blocks [demon_name]."))
		return result
	var/pre_reduction = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 5) || 0
	if(pre_reduction > 0)
		current_power = round(current_power * max(0, 1 - (pre_reduction / 100)))
	var/half_chance = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 1) || 0
	if(half_chance > 0 && prob(half_chance))
		current_power = round(current_power * 0.5)
	var/duration_modifier = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 2) || 0
	if(duration_modifier)
		effect_duration = round(effect_duration * max(0, 1 + (duration_modifier / 100)))
	var/post_power_reduction = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 3, "value_1") || 0
	var/power_slow = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 3, "value_2") || 0
	if(post_power_reduction > 0)
		current_power = round(current_power * max(0, 1 - (post_power_reduction / 100)))
		if(power_slow > 0 && effect_duration > 0)
			target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberdemon, multiplicative_slowdown = power_slow / 100)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_movespeed_modifier), WEAKREF(target)), effect_duration)
	var/post_duration_reduction = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 4, "value_1") || 0
	var/duration_slow = target.mind?.get_character_perk_effectiveness(SKILL_NEUTRALIZATION, 4, "value_2") || 0
	if(post_duration_reduction > 0)
		effect_duration = round(effect_duration * max(0, 1 - (post_duration_reduction / 100)))
		if(duration_slow > 0 && effect_duration > 0)
			target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberdemon, multiplicative_slowdown = duration_slow / 100)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_movespeed_modifier), WEAKREF(target)), effect_duration)
	result["power"] = current_power
	result["duration"] = effect_duration
	return result

/datum/cyberspace_demon/proc/apply_effect(mob/living/caster, atom/target, current_power, physical_world)
	var/success = apply_primary_effect(caster, target, current_power, physical_world)
	if(success)
		apply_corporate_edict_effects(caster, target, current_power, physical_world)
		schedule_periodic_effects(caster, target, current_power, physical_world)
		apply_special_effects(caster, target, current_power, physical_world)
	return success

/datum/cyberspace_demon/proc/apply_corporate_edict_effects(mob/living/caster, atom/target, current_power, physical_world)
	if(!target || !SSeconomy)
		return FALSE
	var/corporation_id = SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return FALSE
	var/bonus_power = max(1, round(abs(current_power) * 0.25))
	var/datum/cyberspace_node/target_node = get_target_node(target)
	if(corporation_id == "benn" && SScyberpunk_corporations.cyberpunk_corporation_has_edict(corporation_id, "benn_chem_recycling"))
		if(target_node)
			var/datum/cyber_ice/benn_ice = target_node.get_ice()
			if(benn_ice)
				benn_ice.apply_reserve_damage(bonus_power)
				SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "bio", 1, 0, "chemical demon pressure")
				return TRUE
		var/mob/living/benn_living_target = target
		if(istype(benn_living_target) && physical_world && !benn_living_target.is_projected_into_cyberspace())
			benn_living_target.apply_damage(bonus_power, TOX)
			SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "bio", 1, 0, "chemical demon pressure")
			return TRUE
	if(corporation_id == "ryaznov" && SScyberpunk_corporations.cyberpunk_corporation_has_edict(corporation_id, "ryaznov_overload_loop"))
		if(target_node)
			var/datum/cyber_ice/ryaznov_ice = target_node.get_ice()
			if(ryaznov_ice)
				ryaznov_ice.apply_reserve_damage(bonus_power)
				SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 1, 0, "overload demon loop")
				return TRUE
		var/mob/living/ryaznov_living_target = target
		if(istype(ryaznov_living_target) && physical_world && !ryaznov_living_target.is_projected_into_cyberspace())
			ryaznov_living_target.apply_damage(bonus_power, BURN)
			SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 1, 0, "overload demon loop")
			return TRUE
	if(corporation_id == "starlight" && SScyberpunk_corporations.cyberpunk_corporation_has_edict(corporation_id, "starlight_suppression_loop"))
		if(target_node)
			var/datum/cyber_ice/starlight_ice = target_node.get_ice()
			if(starlight_ice)
				starlight_ice.apply_reserve_damage(bonus_power)
				SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "market", 1, 0, "suppression demon loop")
				return TRUE
		var/mob/living/starlight_living_target = target
		if(istype(starlight_living_target))
			starlight_living_target.adjust_stamina_loss(bonus_power * 2)
			SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "market", 1, 0, "suppression demon loop")
			return TRUE
	return FALSE

/datum/cyberspace_demon/proc/is_periodic_effect()
	return effect in list(
		CYBER_DEMON_EFFECT_BURN,
		CYBER_DEMON_EFFECT_ACID,
		CYBER_DEMON_EFFECT_TOX,
		CYBER_DEMON_EFFECT_OVERHEAT,
		CYBER_DEMON_EFFECT_OVERHEAT_DELTA,
		CYBER_DEMON_EFFECT_STAMINA,
		CYBER_DEMON_EFFECT_PROTECTION,
	)

/datum/cyberspace_demon/proc/schedule_periodic_effects(mob/living/caster, atom/target, current_power, physical_world)
	if(duration <= 0 || effect_frequency <= CYBER_DEMON_DEFAULT_FREQUENCY || !is_periodic_effect())
		return
	var/total_ticks = min(CYBER_DEMON_MAX_PERIODIC_TICKS, max(1, round((duration / 10) * effect_frequency)))
	if(total_ticks <= 1)
		return
	var/tick_delay = max(1, round(10 / effect_frequency))
	for(var/tick_number in 2 to total_ticks)
		addtimer(CALLBACK(src, PROC_REF(apply_periodic_effect_tick), WEAKREF(caster), WEAKREF(target), current_power, physical_world), tick_delay * (tick_number - 1))

/datum/cyberspace_demon/proc/apply_periodic_effect_tick(datum/weakref/caster_ref, datum/weakref/target_ref, current_power, physical_world)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/target = target_ref?.resolve()
	if(!target)
		return FALSE
	return apply_primary_effect(caster, target, current_power, physical_world, FALSE)

/datum/cyberspace_demon/proc/apply_primary_effect(mob/living/caster, atom/target, current_power, physical_world, announce = TRUE)
	var/absolute_power = abs(current_power)
	var/effect_duration = duration
	var/datum/cyberspace_node/target_node = get_target_node(target)
	var/target_node_name = target_node?.physical_area?.name || "node"
	if(target_node && effect == CYBER_DEMON_EFFECT_PROTECTION)
		var/datum/cyber_ice/protection_ice = target_node.get_ice()
		if(!protection_ice)
			return FALSE
		var/old_reserve = protection_ice.current_reserve
		protection_ice.current_reserve = clamp(protection_ice.current_reserve + current_power, 0, protection_ice.get_max_reserve())
		if(announce)
			to_chat(caster, span_notice("[demon_name] changes [target_node_name] protection by [protection_ice.current_reserve - old_reserve]. Reserve: [protection_ice.current_reserve]/[protection_ice.get_max_reserve()]."))
		return TRUE
	if(target_node && (effect in list(CYBER_DEMON_EFFECT_DAMAGE, CYBER_DEMON_EFFECT_BURN, CYBER_DEMON_EFFECT_ACID, CYBER_DEMON_EFFECT_TOX)))
		var/datum/cyber_ice/ice = target_node.get_ice()
		if(!ice)
			return FALSE
		ice.apply_reserve_damage(max(1, absolute_power))
		if(announce)
			to_chat(caster, span_notice("[demon_name] converts into network damage and lowers [target_node_name] protection by [max(1, absolute_power)]."))
		return TRUE
	if(target_node && (effect in list(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF)))
		var/datum/cyber_ice/network_ice = target_node.get_ice()
		if(!network_ice)
			return FALSE
		var/network_delta = max(1, absolute_power * 2)
		if(effect == CYBER_DEMON_EFFECT_DEBUFF || current_power < 0)
			network_ice.apply_reserve_damage(network_delta)
			if(announce)
				to_chat(caster, span_notice("[demon_name] converts a debuff into [network_delta] network damage against [target_node_name]."))
			return TRUE
		var/restored = network_ice.restore_reserve(network_delta)
		if(announce)
			to_chat(caster, span_notice("[demon_name] converts a buff into [restored] restored network protection on [target_node_name]."))
		return TRUE
	var/mob/living/neutralized_target = istype(target, /mob/living) ? target : null
	if(neutralized_target)
		if(requires_neural_living_target() && !neutralized_target.has_neural_implant())
			if(announce && caster)
				to_chat(caster, span_warning("[target] has no neural interface for [demon_name] to bind to."))
			return FALSE
		var/list/neutralized = apply_neutralization(caster, neutralized_target, current_power, effect_duration)
		if(neutralized["blocked"])
			if(announce && caster)
				to_chat(caster, span_warning("[target] neutralizes [demon_name]."))
			return TRUE
		current_power = neutralized["power"]
		effect_duration = neutralized["duration"]
		absolute_power = abs(current_power)
	switch(effect)
		if(CYBER_DEMON_EFFECT_DAMAGE)
			var/mob/living/living_target = target
			if(istype(living_target))
				if(!physical_world || living_target.is_projected_into_cyberspace())
					living_target.adjust_chromity_overheat(absolute_power)
				else
					living_target.adjust_organ_loss(ORGAN_SLOT_BRAIN, absolute_power)
				if(announce)
					to_chat(caster, span_notice("[demon_name] damages [target]'s neural pattern for [absolute_power]."))
				return TRUE
			var/obj/effect/cyberspace_wall_shell/wall = target
			if(istype(wall))
				return wall.take_wall_damage(absolute_power)
		if(CYBER_DEMON_EFFECT_BURN, CYBER_DEMON_EFFECT_ACID)
			var/mob/living/living_target = target
			if(istype(living_target))
				if(!physical_world || living_target.is_projected_into_cyberspace())
					living_target.adjust_chromity_overheat(absolute_power)
				else
					living_target.apply_damage(absolute_power, BURN)
				if(announce)
					to_chat(caster, span_notice("[demon_name] applies HEAT/ACID pressure to [target] for [absolute_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_TOX)
			var/mob/living/living_target = target
			if(istype(living_target))
				if(!physical_world || living_target.is_projected_into_cyberspace())
					living_target.adjust_chromity_overheat(absolute_power)
				else
					living_target.apply_damage(absolute_power, TOX)
				if(announce)
					to_chat(caster, span_notice("[demon_name] disrupts [target]'s implant chemistry for [absolute_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_OVERHEAT, CYBER_DEMON_EFFECT_OVERHEAT_DELTA)
			var/mob/living/living_target = target
			if(istype(living_target))
				living_target.adjust_chromity_overheat(current_power)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s implant overheat by [current_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_PROTECTION)
			if(announce)
				to_chat(caster, span_warning("[demon_name] needs a cyberspace node or trace to change protection."))
			return FALSE
		if(CYBER_DEMON_EFFECT_WALL)
			var/turf/target_turf = get_turf(target)
			if(!target_turf)
				return FALSE
			var/obj/effect/cyberspace_wall_shell/wall = locate(/obj/effect/cyberspace_wall_shell) in target_turf
			if(!wall)
				wall = new(target_turf, new /datum/cyberspace_wall())
			wall.build_wall(current_power)
			if(announce)
				to_chat(caster, span_notice("[demon_name] raises a cyberspace wall to [wall.wall_data?.build_progress || 0]%."))
			return TRUE
		if(CYBER_DEMON_EFFECT_CRYPTOKEY)
			var/datum/cyberspace_node/key_node
			var/obj/effect/cyberspace_node_shell/node_shell = target
			if(istype(node_shell))
				key_node = node_shell.node
			else
				var/obj/effect/cyberspace_object_trace/trace = target
				if(istype(trace))
					key_node = trace.node
			if(!key_node)
				if(announce && caster)
					to_chat(caster, span_warning("[demon_name] needs a cyberspace node target."))
				return FALSE
			if(!caster?.mind)
				return FALSE
			for(var/datum/cyberspace_cryptokey/cryptokey as anything in key_node.cryptokeys)
				caster.mind?.remember_cyber_cryptokey(cryptokey)
			if(announce)
				to_chat(caster, span_notice("[demon_name] copies node cryptokeys into memory."))
			return TRUE
		if(CYBER_DEMON_EFFECT_EMP)
			if(!hascall(target, "emp_act"))
				to_chat(caster, span_warning("[demon_name] cannot find an EMP channel on [target]."))
				return FALSE
			call(target, "emp_act")(EMP_HEAVY)
			if(announce)
				to_chat(caster, span_notice("[demon_name] shorts [target]."))
			return TRUE
		if(CYBER_DEMON_EFFECT_ATTRIBUTE)
			var/mob/living/living_target = target
			if(istype(living_target) && living_target.mind && effect_duration > 0)
				living_target.mind.add_cyberdemon_attribute_modifier(target_attribute, current_power, effect_duration, demon_name)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s [target_attribute] by [current_power] for [DisplayTimeText(effect_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_SKILL)
			var/mob/living/living_target = target
			if(istype(living_target) && living_target.mind && effect_duration > 0)
				living_target.mind.add_cyberdemon_skill_modifier(target_skill, current_power, effect_duration, demon_name)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s skill routing by [current_power] for [DisplayTimeText(effect_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_STAMINA)
			var/mob/living/living_target = target
			if(istype(living_target))
				living_target.adjust_stamina_loss(current_power)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s stamina load by [current_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BLIND)
			var/mob/living/living_target = target
			if(istype(living_target))
				living_target.set_temp_blindness_if_lower(max(1 SECONDS, effect_duration || (absolute_power SECONDS)))
				if(announce)
					to_chat(caster, span_notice("[demon_name] blinds [target]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_DEAF)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/trait_source = "cyberdemon_deaf_[REF(src)]"
				ADD_TRAIT(living_target, TRAIT_DEAF, trait_source)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_trait), WEAKREF(living_target), TRAIT_DEAF, trait_source), max(1 SECONDS, effect_duration || (absolute_power SECONDS)))
				if(announce)
					to_chat(caster, span_notice("[demon_name] suppresses [target]'s hearing."))
				return TRUE
		if(CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_DEMONS)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/block_duration = max(1 SECONDS, effect_duration || (absolute_power SECONDS))
				if(effect == CYBER_DEMON_EFFECT_SILENCE)
					var/trait_source = "cyberdemon_mute_[REF(src)]"
					ADD_TRAIT(living_target, TRAIT_MUTE, trait_source)
					addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_trait), WEAKREF(living_target), TRAIT_MUTE, trait_source), block_duration)
					if(announce)
						to_chat(caster, span_notice("[demon_name] blocks [target]'s output channel."))
				else
					living_target.cyberdemon_block_demons(block_duration)
					if(announce)
						to_chat(caster, span_notice("[demon_name] blocks [target]'s demon runtime for [DisplayTimeText(block_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_MOVEMENT)
			return move_caster_projection(caster, target, announce)
		if(CYBER_DEMON_EFFECT_CLOAK)
			var/applied = FALSE
			var/mob/eye/cyberspace_avatar/avatar_target = get_cyberspace_avatar_target(target)
			if(avatar_target)
				applied |= apply_visibility_alpha(avatar_target, CYBER_DEMON_CLOAK_ALPHA, effect_duration)
			var/mob/living/body_target = get_cyberspace_body_target(target)
			if(!avatar_target && body_target)
				applied |= apply_visibility_alpha(body_target, CYBER_DEMON_CLOAK_ALPHA, effect_duration)
			var/atom/glitch_center = body_target ? body_target : target
			glitch_nearby_cameras(glitch_center)
			if(applied && announce)
				to_chat(caster, span_notice("[demon_name] cloaks [target] and throws nearby camera feeds into static."))
			return applied
		if(CYBER_DEMON_EFFECT_VANISH)
			var/applied = FALSE
			var/mob/eye/cyberspace_avatar/avatar_target = get_cyberspace_avatar_target(target)
			if(avatar_target)
				applied |= apply_visibility_alpha(avatar_target, CYBER_DEMON_VANISH_ALPHA, effect_duration)
			var/mob/living/body_target = get_cyberspace_body_target(target)
			if(body_target)
				applied |= apply_visibility_alpha(body_target, CYBER_DEMON_VANISH_ALPHA, effect_duration)
			var/atom/glitch_center = body_target ? body_target : target
			glitch_nearby_cameras(glitch_center)
			if(applied && announce)
				to_chat(caster, span_notice("[demon_name] vanishes [target] from sight and camera feeds."))
			return applied
		if(CYBER_DEMON_EFFECT_ENGRAM_STUN)
			var/mob/eye/cyberspace_avatar/engram_target = get_cyberspace_avatar_target(target)
			if(!engram_target || engram_target.session?.mode != CYBERSPACE_MODE_ENGRAM)
				if(announce && caster)
					to_chat(caster, span_warning("[demon_name] needs an active engram target."))
				return FALSE
			var/stun_duration = max(1 SECONDS, effect_duration || (absolute_power SECONDS))
			engram_target.stun_from_cyberdemon(stun_duration)
			if(announce)
				to_chat(caster, span_notice("[demon_name] stuns [engram_target] for [DisplayTimeText(stun_duration)]."))
			return TRUE
		if(CYBER_DEMON_EFFECT_MOVE_SPEED)
			var/mob/living/living_target = target
			if(istype(living_target) && effect_duration > 0)
				living_target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberdemon, multiplicative_slowdown = -(current_power / 100))
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_movespeed_modifier), WEAKREF(living_target)), effect_duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s movement speed by [current_power]% for [DisplayTimeText(effect_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_INTERACTION_SPEED)
			var/mob/living/living_target = target
			if(istype(living_target) && effect_duration > 0)
				living_target.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/cyberdemon, multiplicative_slowdown = -(current_power / 100))
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_actionspeed_modifier), WEAKREF(living_target)), effect_duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s interaction speed by [current_power]% for [DisplayTimeText(effect_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BLOCK_IMPLANTS)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/block_duration = max(1 SECONDS, effect_duration || (absolute_power SECONDS))
				living_target.cyberdemon_block_implants(block_duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] blocks [target]'s active implant channels for [DisplayTimeText(block_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/network_delta = max(1, absolute_power * 2)
				if(effect == CYBER_DEMON_EFFECT_DEBUFF || current_power < 0)
					living_target.adjust_chromity_overheat(network_delta)
				else
					living_target.adjust_chromity_overheat(-network_delta)
				if(living_target.mind && effect_duration > 0)
					var/skill_delta = max(1, round(absolute_power / 10))
					living_target.mind.add_cyberdemon_skill_modifier(target_skill || SKILL_HACKING, effect == CYBER_DEMON_EFFECT_DEBUFF ? -skill_delta : skill_delta, effect_duration, demon_name)
				if(announce)
					to_chat(caster, span_notice("[demon_name] applies a [effect] as [network_delta] neural protection pressure on [target]."))
				return TRUE
			if(announce)
				to_chat(caster, span_notice("[demon_name] applies a temporary [effect] with power [current_power] for [round(effect_duration / 10)] seconds."))
			return TRUE
	return FALSE

/datum/cyberspace_demon/proc/apply_special_effects(mob/living/caster, atom/target, current_power, physical_world)
	if(!length(special_effects))
		return
	var/secondary_power = max(1, round(current_power * CYBER_DEMON_SPECIAL_SECONDARY_MULTIPLIER))
	var/end_delay = max(1 SECONDS, duration || CYBER_DEMON_SPECIAL_SPREAD_DELAY)
	if((CYBER_DEMON_SPECIAL_EMP in special_effects) || (CYBER_DEMON_SPECIAL_EMP_LIGHT in special_effects))
		addtimer(CALLBACK(src, PROC_REF(apply_emp_aftershock), WEAKREF(caster), WEAKREF(target), EMP_LIGHT), end_delay)
	if(CYBER_DEMON_SPECIAL_EMP_HEAVY in special_effects)
		addtimer(CALLBACK(src, PROC_REF(apply_emp_aftershock), WEAKREF(caster), WEAKREF(target), EMP_HEAVY), end_delay)
	if(CYBER_DEMON_SPECIAL_MASS in special_effects)
		apply_mass_effect(caster, target, secondary_power, physical_world)
	if(CYBER_DEMON_SPECIAL_JUMP in special_effects)
		addtimer(CALLBACK(src, PROC_REF(apply_jump_effect_delayed), WEAKREF(caster), WEAKREF(target), secondary_power, physical_world), end_delay)
	if(CYBER_DEMON_SPECIAL_SPREAD in special_effects)
		var/spread_delay = duration || CYBER_DEMON_SPECIAL_SPREAD_DELAY
		addtimer(CALLBACK(src, PROC_REF(apply_spread_effect), WEAKREF(caster), WEAKREF(target), secondary_power, physical_world), spread_delay)
	if(CYBER_DEMON_SPECIAL_REPEAT in special_effects)
		addtimer(CALLBACK(src, PROC_REF(apply_repeat_effect), WEAKREF(caster), WEAKREF(target), secondary_power, physical_world, CYBER_DEMON_SPECIAL_REPEAT_LIMIT), end_delay)

/datum/cyberspace_demon/proc/apply_emp_aftershock(datum/weakref/caster_ref, datum/weakref/target_ref, emp_severity)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/target = target_ref?.resolve()
	if(!target)
		return FALSE
	if(!hascall(target, "emp_act"))
		return FALSE
	call(target, "emp_act")(emp_severity)
	if(caster)
		to_chat(caster, span_notice("[demon_name] releases [emp_severity == EMP_HEAVY ? "a heavy" : "a weak"] EMP aftershock on [target]."))
	return TRUE

/datum/cyberspace_demon/proc/apply_jump_effect_delayed(datum/weakref/caster_ref, datum/weakref/origin_ref, current_power, physical_world)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/origin = origin_ref?.resolve()
	if(!origin)
		return FALSE
	apply_jump_effect(caster, origin, current_power, physical_world)
	return TRUE

/datum/cyberspace_demon/proc/apply_mass_effect(mob/living/caster, atom/origin, current_power, physical_world)
	var/applied = 0
	var/list/excluded = list(origin, caster)
	for(var/atom/candidate as anything in range(CYBER_DEMON_SPECIAL_MASS_RANGE, origin))
		if(applied >= CYBER_DEMON_SPECIAL_MASS_LIMIT)
			break
		if(!(candidate in excluded) && can_apply_secondary_effect(caster, origin, candidate))
			if(apply_primary_effect(caster, candidate, current_power, physical_world, FALSE))
				excluded += candidate
				applied++
	if(applied)
		if(caster)
			to_chat(caster, span_notice("[demon_name] hits [applied] nearby network target[applied == 1 ? "" : "s"]."))

/datum/cyberspace_demon/proc/apply_jump_effect(mob/living/caster, atom/origin, current_power, physical_world)
	var/atom/current_origin = origin
	var/list/excluded = list(origin, caster)
	var/jumps = 0
	while(jumps < CYBER_DEMON_SPECIAL_JUMP_LIMIT)
		var/atom/next_target = find_secondary_effect_target(caster, current_origin, excluded)
		if(!next_target)
			break
		if(!apply_primary_effect(caster, next_target, current_power, physical_world, FALSE))
			break
		excluded += next_target
		current_origin = next_target
		jumps++
	if(jumps)
		if(caster)
			to_chat(caster, span_notice("[demon_name] jumps through [jumps] extra target[jumps == 1 ? "" : "s"]."))

/datum/cyberspace_demon/proc/apply_spread_effect(datum/weakref/caster_ref, datum/weakref/origin_ref, current_power, physical_world)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/origin = origin_ref?.resolve()
	if(!origin)
		return FALSE
	var/list/excluded = list(origin, caster)
	var/atom/next_target = find_secondary_effect_target(caster, origin, excluded)
	if(!next_target)
		return FALSE
	if(apply_primary_effect(caster, next_target, current_power, physical_world, FALSE))
		if(caster)
			to_chat(caster, span_notice("[demon_name] spreads from [origin] to [next_target]."))
		return TRUE
	return FALSE

/datum/cyberspace_demon/proc/apply_repeat_effect(datum/weakref/caster_ref, datum/weakref/origin_ref, current_power, physical_world, repeats_left)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/origin = origin_ref?.resolve()
	if(!origin || repeats_left <= 0)
		return FALSE
	var/atom/repeat_target = origin
	if(CYBER_DEMON_SPECIAL_JUMP in special_effects)
		repeat_target = find_secondary_effect_target(caster, origin, list(caster))
	if(!repeat_target)
		return FALSE
	if(apply_primary_effect(caster, repeat_target, current_power, physical_world, FALSE))
		if(caster)
			to_chat(caster, span_notice("[demon_name] repeats on [repeat_target]."))
		addtimer(CALLBACK(src, PROC_REF(apply_repeat_effect), caster_ref, WEAKREF(repeat_target), current_power, physical_world, repeats_left - 1), max(1 SECONDS, duration || CYBER_DEMON_SPECIAL_SPREAD_DELAY))
		return TRUE
	return FALSE

/datum/cyberspace_demon/proc/find_secondary_effect_target(mob/living/caster, atom/origin, list/excluded)
	var/list/candidates = list()
	for(var/atom/candidate as anything in range(CYBER_DEMON_SPECIAL_JUMP_RANGE, origin))
		if((candidate in excluded) || !can_apply_secondary_effect(caster, origin, candidate))
			continue
		candidates += candidate
	if(!length(candidates))
		return null
	return pick(candidates)

/datum/cyberspace_demon/proc/can_apply_secondary_effect(mob/living/caster, atom/origin, atom/candidate)
	if(!candidate || QDELETED(candidate) || candidate == origin || candidate == caster)
		return FALSE
	var/mob/living/living_candidate = candidate
	if(istype(living_candidate) && requires_neural_living_target() && !living_candidate.has_neural_implant())
		return FALSE
	switch(effect)
		if(CYBER_DEMON_EFFECT_DAMAGE, CYBER_DEMON_EFFECT_BURN, CYBER_DEMON_EFFECT_ACID, CYBER_DEMON_EFFECT_TOX, CYBER_DEMON_EFFECT_OVERHEAT_DELTA, CYBER_DEMON_EFFECT_PROTECTION)
			return istype(candidate, /mob/living) || istype(candidate, /obj/effect/cyberspace_wall_shell) || istype(candidate, /obj/effect/cyberspace_node_shell) || istype(candidate, /obj/effect/cyberspace_object_trace)
		if(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF, CYBER_DEMON_EFFECT_ATTRIBUTE, CYBER_DEMON_EFFECT_SKILL, CYBER_DEMON_EFFECT_STAMINA, CYBER_DEMON_EFFECT_BLIND, CYBER_DEMON_EFFECT_DEAF, CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_IMPLANTS, CYBER_DEMON_EFFECT_BLOCK_DEMONS)
			return istype(candidate, /mob/living)
		if(CYBER_DEMON_EFFECT_CLOAK, CYBER_DEMON_EFFECT_VANISH, CYBER_DEMON_EFFECT_ENGRAM_STUN)
			return istype(candidate, /mob/living) || istype(candidate, /mob/eye/cyberspace_avatar)
		if(CYBER_DEMON_EFFECT_WALL, CYBER_DEMON_EFFECT_MOVEMENT)
			return isturf(candidate) || istype(candidate, /obj/effect/cyberspace_wall_shell) || istype(candidate, /obj/effect/cyberspace_node_shell) || istype(candidate, /obj/effect/cyberspace_object_trace)
		if(CYBER_DEMON_EFFECT_EMP)
			return hascall(candidate, "emp_act")
		if(CYBER_DEMON_EFFECT_CRYPTOKEY)
			return istype(candidate, /obj/effect/cyberspace_node_shell) || istype(candidate, /obj/effect/cyberspace_object_trace)
	return FALSE

/datum/cyberspace_demon/proc/get_summary()
	return "[demon_name] ([memory_cost] memory, [get_net_data_cost()] net-data): [description]"

/datum/cyberspace_demon/custom
	demon_name = "Custom demon"
	description = "A custom compiled demon."

/datum/cyberspace_demon/wall
	demon_name = "Стена"
	description = "Создает стену в киберпространстве за 30 секунд."
	effect = CYBER_DEMON_EFFECT_WALL
	effect_power = 100
	cast_time = 1 SECONDS
	activation_delay = CYBER_DEMON_WALL_BUILD_TIME
	cooldown = CYBER_DEMON_WALL_COOLDOWN
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 2
	prebuilt = TRUE

/datum/cyberspace_demon/cloak
	demon_name = "Сокрытие"
	description = "Скрывает аватара или энграмму на 120 секунд. Камеры ловят помехи."
	effect = CYBER_DEMON_EFFECT_CLOAK
	effect_power = 90
	cast_time = 2 SECONDS
	duration = CYBER_DEMON_CLOAK_DURATION
	cooldown = CYBER_DEMON_CLOAK_COOLDOWN
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 3
	special_effects = list(CYBER_DEMON_SPECIAL_STEALTH)
	prebuilt = TRUE

/datum/cyberspace_demon/vanish
	demon_name = "Исчезновение"
	description = "Полностью скрывает аватара, энграмму и физическое тело на 30 секунд."
	effect = CYBER_DEMON_EFFECT_VANISH
	effect_power = 100
	cast_time = 3 SECONDS
	duration = CYBER_DEMON_VANISH_DURATION
	cooldown = CYBER_DEMON_VANISH_COOLDOWN
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 4
	special_effects = list(CYBER_DEMON_SPECIAL_STEALTH)
	prebuilt = TRUE

/datum/cyberspace_demon/soulcatcher
	demon_name = "Душелов"
	description = "Оглушает энграмму на 120 секунд."
	effect = CYBER_DEMON_EFFECT_ENGRAM_STUN
	effect_power = 1
	cast_time = 3 SECONDS
	duration = CYBER_DEMON_SOULCATCHER_DURATION
	cooldown = CYBER_DEMON_SOULCATCHER_COOLDOWN
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 4
	prebuilt = TRUE

/datum/cyberspace_demon/soulconduit
	demon_name = "Душепроводчик"
	description = "Переносит энграмму в носитель или выбрасывает ее с чипа в сетевой мир."
	effect = CYBER_DEMON_EFFECT_PREBUILT
	effect_power = 1
	cast_time = 10 SECONDS
	duration = CYBER_DEMON_SOULCONDUIT_DURATION
	cooldown = CYBER_DEMON_SOULCONDUIT_COOLDOWN
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 5
	prebuilt = TRUE

/datum/cyberspace_demon/soulconduit/apply_primary_effect(mob/living/caster, atom/target, current_power, physical_world, announce = TRUE)
	var/obj/item/cyberspace_engram_chip/chip = target
	if(istype(chip))
		var/mob/living/chip_body = chip.get_bound_body()
		if(chip_body && chip_body.cyberspace_session && chip_body.cyberspace_session.mode == CYBERSPACE_MODE_ENGRAM)
			return chip.receive_engram(caster)
		return chip.eject_bound_engram(caster)

	var/mob/eye/cyberspace_avatar/engram_avatar = target
	if(istype(engram_avatar) && engram_avatar.session?.mode == CYBERSPACE_MODE_ENGRAM)
		return bind_engram_avatar_to_chip(caster, engram_avatar)

	var/mob/living/living_target = target
	if(istype(living_target))
		if(!living_target.has_neural_implant())
			to_chat(caster, span_warning("[living_target] has no neural interface for [demon_name] to bind to."))
			return FALSE
		var/obj/item/cyberspace_engram_chip/held_chip = find_held_engram_chip(caster)
		if(!held_chip)
			to_chat(caster, span_warning("[demon_name] needs an engram chip in hand to bind a physical target."))
			return FALSE
		return held_chip.bind_body(living_target, caster)

	to_chat(caster, span_warning("[demon_name] needs an engram chip, physical body, or active engram target."))
	return FALSE

/datum/cyberspace_demon/soulconduit/proc/bind_engram_avatar_to_chip(mob/living/caster, mob/eye/cyberspace_avatar/engram_avatar)
	var/obj/item/cyberspace_engram_chip/chip = find_held_engram_chip(caster)
	if(!chip)
		to_chat(caster, span_warning("[demon_name] needs an engram chip in hand."))
		return FALSE
	var/turf/original_turf = get_turf(engram_avatar)
	to_chat(caster, span_notice("[demon_name] starts synchronizing [engram_avatar] with [chip]."))
	if(!do_after(caster, duration, target = engram_avatar, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		to_chat(caster, span_warning("[demon_name] loses the engram synchronization window."))
		return FALSE
	if(get_turf(engram_avatar) != original_turf)
		to_chat(caster, span_warning("[engram_avatar] moved before synchronization completed."))
		return FALSE
	if(!engram_avatar.session || engram_avatar.session.mode != CYBERSPACE_MODE_ENGRAM)
		to_chat(caster, span_warning("[engram_avatar] is no longer an active engram."))
		return FALSE
	if(find_held_engram_chip(caster) != chip)
		to_chat(caster, span_warning("[demon_name] needs the same engram chip in hand when synchronization completes."))
		return FALSE
	var/mob/living/bound_body = engram_avatar.body_ref?.resolve()
	if(!bound_body)
		return FALSE
	if(!chip.bind_body(bound_body, caster))
		return FALSE
	if(engram_avatar.session)
		engram_avatar.session.set_engram_anchor(chip)
	bound_body.cyberspace_transition_blocked_until = max(bound_body.cyberspace_transition_blocked_until, world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK)
	chip.transition_blocked_until = max(chip.transition_blocked_until, world.time + CYBERSPACE_ENGRAM_TRANSFER_BLOCK)
	to_chat(caster, span_notice("[demon_name] binds [bound_body]'s active engram to [chip]."))
	return TRUE

/datum/cyberspace_demon/blink
	demon_name = "Скачок"
	description = "Перемещает пользователя к точке применения."
	effect = CYBER_DEMON_EFFECT_MOVEMENT
	effect_power = 1
	cast_time = 1.5 SECONDS
	memory_cost = CYBER_DEMON_PREBUILT_MEMORY
	net_data_cost = 2
	prebuilt = TRUE

/proc/get_cyberdemon_catalog()
	return list(
		"Стена" = /datum/cyberspace_demon/wall,
		"Сокрытие" = /datum/cyberspace_demon/cloak,
		"Исчезновение" = /datum/cyberspace_demon/vanish,
		"Душелов" = /datum/cyberspace_demon/soulcatcher,
		"Душепроводчик" = /datum/cyberspace_demon/soulconduit,
		"Скачок" = /datum/cyberspace_demon/blink,
	)

/proc/get_cyberdemon_effect_choices()
	return list(
		"Network strike" = CYBER_DEMON_EFFECT_DAMAGE,
		"Нагрев электроники (HEAT)" = CYBER_DEMON_EFFECT_BURN,
		"Кислотный сбой (ACID)" = CYBER_DEMON_EFFECT_ACID,
		"Токсичный сбой имплантов" = CYBER_DEMON_EFFECT_TOX,
		"Изменить перегрев имплантов" = CYBER_DEMON_EFFECT_OVERHEAT_DELTA,
		"Изменить характеристику" = CYBER_DEMON_EFFECT_ATTRIBUTE,
		"Изменить навык" = CYBER_DEMON_EFFECT_SKILL,
		"Изменить скорость движения" = CYBER_DEMON_EFFECT_MOVE_SPEED,
		"Изменить скорость взаимодействия" = CYBER_DEMON_EFFECT_INTERACTION_SPEED,
		"Ослепление" = CYBER_DEMON_EFFECT_BLIND,
		"Глухота" = CYBER_DEMON_EFFECT_DEAF,
		"Блок речи" = CYBER_DEMON_EFFECT_SILENCE,
		"Блок имплантов" = CYBER_DEMON_EFFECT_BLOCK_IMPLANTS,
		"Блок демонов" = CYBER_DEMON_EFFECT_BLOCK_DEMONS,
		"Изменить выносливость" = CYBER_DEMON_EFFECT_STAMINA,
		"Изменить защиту" = CYBER_DEMON_EFFECT_PROTECTION,
		"Buff" = CYBER_DEMON_EFFECT_BUFF,
		"Debuff" = CYBER_DEMON_EFFECT_DEBUFF,
		"Copy cryptokey" = CYBER_DEMON_EFFECT_CRYPTOKEY,
		"EMP" = CYBER_DEMON_EFFECT_EMP,
		"Стена" = CYBER_DEMON_EFFECT_WALL,
		"Скачок" = CYBER_DEMON_EFFECT_MOVEMENT,
		"Сокрытие" = CYBER_DEMON_EFFECT_CLOAK,
		"Исчезновение" = CYBER_DEMON_EFFECT_VANISH,
		"Душелов" = CYBER_DEMON_EFFECT_ENGRAM_STUN,
	)

/proc/get_cyberdemon_special_choices()
	return list(
		"Массовость" = CYBER_DEMON_SPECIAL_MASS,
		"Распространяемость" = CYBER_DEMON_SPECIAL_SPREAD,
		"Прыжок" = CYBER_DEMON_SPECIAL_JUMP,
		"Повтор" = CYBER_DEMON_SPECIAL_REPEAT,
		"Стелс" = CYBER_DEMON_SPECIAL_STEALTH,
		"Слабый ЭМИ" = CYBER_DEMON_SPECIAL_EMP_LIGHT,
		"Сильный ЭМИ" = CYBER_DEMON_SPECIAL_EMP_HEAVY,
	)

/proc/get_cyberdemon_manufacturer_choices()
	return list(
		"Independent",
		"Benn",
		"Benn Bio",
		"Benn Clinic",
		"Benn Shadow",
		"Ryaznov",
		"Ryaznov Works",
		"Ryaznov Energy",
		"Ryaznov Defense",
		"Starlight",
		"Starlight Logistics",
		"Starlight Transit",
		"Starlight Market",
		"Сан Йон Корпорейшн",
		"Ишикава Индастриз",
		"Хо Ши Текнолоджис",
		"Ковальски и Ко",
		"ТяжМарш Продакшен",
		"Тесла Саенс",
		"Блэкрок Инвестигейт",
		"Транс Трэвел",
		"Самантас Кеир",
	)

/proc/is_valid_cyberdemon_effect(effect_id)
	var/list/effects = get_cyberdemon_effect_choices()
	for(var/name in effects)
		if(effects[name] == effect_id)
			return TRUE
	return FALSE

/proc/is_valid_cyberdemon_special(special_id)
	var/list/specials = get_cyberdemon_special_choices()
	for(var/name in specials)
		if(specials[name] == special_id)
			return TRUE
	return FALSE

/proc/is_valid_cyberdemon_manufacturer(manufacturer)
	return manufacturer in get_cyberdemon_manufacturer_choices()

/proc/get_cyberdemon_skill_from_id(skill_id)
	for(var/skill_type in GLOB.skill_types)
		if("[skill_type]" == "[skill_id]")
			return skill_type
	return SKILL_HACKING

/proc/cyberdemon_attributes_ui_data()
	var/list/attributes_data = list()
	for(var/attribute_type in GLOB.attribute_types)
		var/datum/attribute/attribute = new attribute_type()
		attributes_data += list(list(
			"id" = attribute.id,
			"name" = attribute.name,
		))
		qdel(attribute)
	return attributes_data

/proc/cyberdemon_skills_ui_data()
	var/list/skills_data = list()
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || !skill_datum.is_character_skill())
			continue
		skills_data += list(list(
			"id" = "[skill_type]",
			"name" = skill_datum.name,
		))
	return skills_data

/proc/create_custom_cyberdemon_from_params(list/params)
	var/effect_id = params["effect"]
	if(!is_valid_cyberdemon_effect(effect_id))
		return null

	var/raw_name = params["name"]
	var/demon_name = trim("[raw_name]")
	if(!length(demon_name))
		demon_name = "Custom demon"
	demon_name = copytext_char(demon_name, 1, 33)

	var/raw_power = params["power"]
	var/raw_cast_time = params["cast_time"]
	var/raw_duration = params["duration"]
	var/raw_activation_delay = params["activation_delay"]
	var/raw_frequency = params["frequency"]
	var/raw_stamina_cost = params["stamina_cost"]
	var/raw_manufacturer = params["manufacturer"]
	var/power = clamp(text2num("[raw_power]") || 1, -100, 100)
	var/cast_seconds = clamp(text2num("[raw_cast_time]") || 1, 0, 60)
	var/duration_seconds = clamp(text2num("[raw_duration]") || 0, 0, 300)
	var/activation_seconds = clamp(text2num("[raw_activation_delay]") || 0, 0, 120)
	var/frequency = clamp(round(text2num("[raw_frequency]") || CYBER_DEMON_DEFAULT_FREQUENCY), 1, CYBER_DEMON_MAX_FREQUENCY)
	var/stamina_cost = clamp(round(text2num("[raw_stamina_cost]") || CYBER_DEMON_BASE_STAMINA_COST), 0, 100)
	var/manufacturer = copytext_char(trim("[raw_manufacturer]"), 1, 33)
	if(!length(manufacturer) || !is_valid_cyberdemon_manufacturer(manufacturer))
		manufacturer = "Independent"
	var/target_attribute = params["target_attribute"]
	if(!(target_attribute in ATTRIBUTE_ALL))
		target_attribute = ATTRIBUTE_STRENGTH
	var/target_skill = get_cyberdemon_skill_from_id(params["target_skill"])

	var/list/specials = list()
	var/list/raw_specials = params["specials"]
	if(!islist(raw_specials))
		raw_specials = list()
	for(var/special in raw_specials)
		if(length(specials) >= CYBER_DEMON_MAX_SPECIAL_EFFECTS)
			break
		if(is_valid_cyberdemon_special(special) && !(special in specials))
			specials += special

	var/datum/cyberspace_demon/custom/new_demon = new()
	new_demon.demon_name = demon_name
	new_demon.description = "Custom [effect_id] demon."
	new_demon.effect = effect_id
	new_demon.effect_power = round(power)
	new_demon.cast_time = round(cast_seconds) SECONDS
	new_demon.duration = round(duration_seconds) SECONDS
	new_demon.activation_delay = round(activation_seconds) SECONDS
	new_demon.effect_frequency = frequency
	new_demon.stamina_cost = stamina_cost
	new_demon.target_attribute = target_attribute
	new_demon.target_skill = target_skill
	new_demon.special_effects = specials
	new_demon.memory_cost = calculate_custom_cyberdemon_memory(power, cast_seconds, duration_seconds, activation_seconds, frequency, specials, effect_id)
	new_demon.net_data_cost = calculate_custom_cyberdemon_net_data_cost(new_demon.memory_cost, specials)
	new_demon.psychic_damage = CYBER_DEMON_DEFAULT_PSYCHIC_DAMAGE + round(new_demon.memory_cost / 3)
	new_demon.manufacturer = manufacturer
	return new_demon

/proc/calculate_custom_cyberdemon_memory(power, cast_seconds, duration_seconds, activation_seconds, frequency, list/specials, effect_id)
	var/memory_cost = 1 + round(abs(power) / 10)
	memory_cost += round(duration_seconds)
	memory_cost += round(max(0, frequency - CYBER_DEMON_DEFAULT_FREQUENCY) * 0.2)
	memory_cost -= round(activation_seconds)
	memory_cost -= round(cast_seconds)
	if(effect_id in list(CYBER_DEMON_EFFECT_ATTRIBUTE, CYBER_DEMON_EFFECT_SKILL, CYBER_DEMON_EFFECT_MOVE_SPEED, CYBER_DEMON_EFFECT_INTERACTION_SPEED, CYBER_DEMON_EFFECT_BLIND, CYBER_DEMON_EFFECT_DEAF, CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_IMPLANTS, CYBER_DEMON_EFFECT_BLOCK_DEMONS, CYBER_DEMON_EFFECT_CLOAK, CYBER_DEMON_EFFECT_VANISH, CYBER_DEMON_EFFECT_ENGRAM_STUN))
		memory_cost += 1
	for(var/special in specials)
		switch(special)
			if(CYBER_DEMON_SPECIAL_MASS, CYBER_DEMON_SPECIAL_SPREAD, CYBER_DEMON_SPECIAL_JUMP, CYBER_DEMON_SPECIAL_REPEAT, CYBER_DEMON_SPECIAL_EMP_LIGHT)
				memory_cost += 2
			if(CYBER_DEMON_SPECIAL_STEALTH)
				memory_cost += 1
			if(CYBER_DEMON_SPECIAL_EMP_HEAVY)
				memory_cost += 3
	return clamp(memory_cost, 1, 99)

/proc/calculate_custom_cyberdemon_net_data_cost(memory_cost, list/specials)
	return max(1, memory_cost + length(specials))

/proc/get_cyberdemon_type_from_id(demon_id)
	var/list/catalog = get_cyberdemon_catalog()
	for(var/name in catalog)
		var/demon_type = catalog[name]
		if("[demon_type]" == "[demon_id]")
			return demon_type
	return null

/proc/cyberdemon_to_ui_data(datum/cyberspace_demon/demon, index = 0)
	return list(
		"index" = index,
		"name" = demon.demon_name,
		"description" = demon.description,
		"effect" = demon.effect,
		"power" = demon.effect_power,
		"cast_time" = round(demon.cast_time / 10),
		"duration" = round(demon.duration / 10),
		"specials" = demon.special_effects.Copy(),
		"memory" = demon.memory_cost,
		"manufacturer" = demon.manufacturer,
		"net_data_cost" = demon.get_net_data_cost(),
		"psychic_damage" = demon.psychic_damage,
		"stamina_cost" = demon.stamina_cost,
		"activation_delay" = round(demon.activation_delay / 10),
		"frequency" = demon.effect_frequency,
		"target_attribute" = demon.target_attribute,
		"target_skill" = "[demon.target_skill]",
		"cooldown" = round(demon.cooldown / 10),
		"prebuilt" = demon.prebuilt,
	)

/proc/cyberdemon_catalog_ui_data()
	var/list/catalog_data = list()
	var/list/catalog = get_cyberdemon_catalog()
	for(var/name in catalog)
		var/demon_type = catalog[name]
		var/datum/cyberspace_demon/demon = new demon_type
		var/list/demon_data = cyberdemon_to_ui_data(demon)
		demon_data["id"] = "[demon_type]"
		catalog_data += list(demon_data)
		qdel(demon)
	return catalog_data

/proc/cyberdemon_effects_ui_data()
	var/list/effects_data = list()
	var/list/effects = get_cyberdemon_effect_choices()
	for(var/name in effects)
		if(effects[name] == CYBER_DEMON_EFFECT_OVERHEAT)
			continue
		effects_data += list(list(
			"name" = name,
			"id" = effects[name],
		))
	return effects_data

/proc/cyberdemon_specials_ui_data()
	var/list/specials_data = list()
	var/list/specials = get_cyberdemon_special_choices()
	for(var/name in specials)
		specials_data += list(list(
			"name" = name,
			"id" = specials[name],
		))
	return specials_data

/proc/find_held_cyberdeck(mob/user)
	if(!user)
		return null
	var/obj/item/clothing/gloves/cyberdeck/deck = locate(/obj/item/clothing/gloves/cyberdeck) in user.held_items
	if(!deck)
		deck = locate(/obj/item/clothing/gloves/cyberdeck) in user.contents
	return deck

#define CYBERPUNK_DATA_PAYLOAD_DEMON "demon"
#define CYBERPUNK_DATA_PAYLOAD_CRYPTOKEY "cryptokey"
#define CYBERPUNK_DATA_PAYLOAD_MUTATION "mutation"
#define CYBERPUNK_DATA_PAYLOAD_GENE_SEQUENCE "gene_sequence"
#define CYBERPUNK_DATA_PAYLOAD_REWARD_KEY "reward_key"

/proc/find_held_cyberdemon_disk(mob/user)
	if(!user)
		return null
	var/obj/item/cyberdemon_disk/disk = locate(/obj/item/cyberdemon_disk) in user.held_items
	if(!disk)
		disk = locate(/obj/item/cyberdemon_disk) in user.contents
	return disk

/proc/find_accessible_cyberdemon_disk(mob/user, obj/item/clothing/gloves/cyberdeck/deck, obj/machinery/cyberdemon_terminal/terminal)
	if(terminal?.inserted_disk)
		return terminal.inserted_disk
	if(deck?.inserted_disk)
		return deck.inserted_disk
	return find_held_cyberdemon_disk(user)

/proc/find_held_engram_chip(mob/user)
	if(!user)
		return null
	var/obj/item/cyberspace_engram_chip/chip = locate(/obj/item/cyberspace_engram_chip) in user.held_items
	if(!chip)
		chip = locate(/obj/item/cyberspace_engram_chip) in user.contents
	return chip

/proc/cyberdemon_storage_ui_data(obj/item/clothing/gloves/cyberdeck/deck, obj/item/cyberdemon_disk/disk, obj/machinery/cyberdemon_terminal/terminal, mob/user, virtual_terminal_present = FALSE, virtual_terminal_name = "temporary demon compiler", virtual_terminal_cooldown = 0)
	var/list/deck_demons = list()
	if(deck)
		var/deck_index = 1
		for(var/datum/cyberspace_demon/demon as anything in deck.demons)
			deck_demons += list(cyberdemon_to_ui_data(demon, deck_index++))

	var/list/disk_demons = list()
	if(disk)
		disk.rebuild_demon_index()
		var/disk_index = 1
		for(var/datum/cyberspace_demon/demon as anything in disk.demons)
			disk_demons += list(cyberdemon_to_ui_data(demon, disk_index++))

	return list(
		"net_data" = user?.mind?.cyber_net_data || 0,
		"compile_requirement_multiplier" = cyberdemon_compile_requirement_multiplier(user),
		"deck" = list(
			"present" = !!deck,
			"name" = deck?.name,
			"used_memory" = deck?.get_used_memory() || 0,
			"memory_capacity" = deck?.memory_capacity || 0,
			"free_memory" = deck?.get_free_memory() || 0,
			"cooldown" = deck ? max(0, round((deck.compile_cooldown_until - world.time) / 10)) : 0,
			"demons" = deck_demons,
		),
		"disk" = list(
			"present" = !!disk,
			"name" = disk?.name,
			"used_memory" = disk?.get_used_memory() || 0,
			"memory_capacity" = disk?.memory_capacity || 0,
			"free_memory" = disk?.get_free_memory() || 0,
			"net_data" = disk?.stored_net_data || 0,
			"cryptokeys" = disk?.get_stored_cryptokey_count() || 0,
			"demons" = disk_demons,
		),
		"terminal" = list(
			"present" = !!terminal || virtual_terminal_present,
			"name" = terminal?.name || virtual_terminal_name,
			"cooldown" = terminal ? max(0, round((terminal.compile_cooldown_until - world.time) / 10)) : virtual_terminal_cooldown,
		),
		"limits" = list(
			"max_specials" = CYBER_DEMON_MAX_SPECIAL_EFFECTS,
			"max_custom_memory" = CYBER_DEMON_MAX_COMPILED_MEMORY,
			"disk_memory" = CYBER_DEMON_DISK_MEMORY,
		),
	)

/proc/cyberdemon_compiler_static_data()
	return list(
		"effects" = cyberdemon_effects_ui_data(),
		"specials" = cyberdemon_specials_ui_data(),
		"manufacturers" = get_cyberdemon_manufacturer_choices(),
		"attributes" = cyberdemon_attributes_ui_data(),
		"skills" = cyberdemon_skills_ui_data(),
	)

/proc/cyberdemon_parse_ui_index(value)
	if(isnum(value))
		return round(value)
	return round(text2num("[value]"))

/proc/delete_cyberdemon_from_list(list/demons, index, mob/user, source_name)
	index = cyberdemon_parse_ui_index(index)
	if(index < 1 || index > length(demons))
		to_chat(user, span_warning("Invalid demon index for [source_name]."))
		return FALSE
	var/datum/cyberspace_demon/demon = demons[index]
	if(!demon)
		to_chat(user, span_warning("No demon exists in that [source_name] slot."))
		return FALSE
	if(demon.prebuilt)
		to_chat(user, span_warning("Prebuilt demons cannot be deleted from [source_name]."))
		return FALSE
	demons.Cut(index, index + 1)
	to_chat(user, span_notice("You delete [demon.demon_name] from [source_name]."))
	qdel(demon)
	return TRUE

/obj/item/cyberdemon_disk/proc/delete_demon_by_index(index, mob/user)
	rebuild_demon_index()
	index = cyberdemon_parse_ui_index(index)
	if(index < 1 || index > length(demons))
		to_chat(user, span_warning("Invalid demon index for [src]."))
		return FALSE
	var/datum/cyberspace_demon/demon = demons[index]
	if(!demon)
		to_chat(user, span_warning("No demon exists in that [src] slot."))
		return FALSE
	if(demon.prebuilt)
		to_chat(user, span_warning("Prebuilt demons cannot be deleted from [src]."))
		return FALSE
	for(var/datum/cyberpunk_data_payload/demon/payload as anything in get_data_payloads(CYBERPUNK_DATA_PAYLOAD_DEMON))
		if(payload.contained_datum != demon)
			continue
		data_payloads -= payload
		qdel(payload)
		rebuild_demon_index()
		to_chat(user, span_notice("You delete [demon.demon_name] from [src]."))
		return TRUE
	to_chat(user, span_warning("[demon.demon_name] has no matching data payload on [src]."))
	return FALSE

/proc/handle_cyberdemon_compiler_action(action, list/params, mob/living/user, obj/item/clothing/gloves/cyberdeck/deck, obj/item/cyberdemon_disk/disk, obj/machinery/cyberdemon_terminal/terminal)
	if(!istype(user))
		return FALSE
	if(!params)
		params = list()

	switch(action)
		if("compile_stock")
			to_chat(user, span_warning("Prebuilt demons are loaded from demon disks. Copy one into a custom demon before development."))
			return TRUE
		if("compile_custom")
			var/datum/cyberspace_demon/demon = create_custom_cyberdemon_from_params(params)
			if(!demon)
				return TRUE
			var/target = params["target"]
			if(target == "disk")
				if(deck && !terminal && !deck.can_compile(user))
					qdel(demon)
					return TRUE
				if(demon.compile_to_disk(user, disk, terminal) && deck && !terminal)
					deck.start_compile_cooldown()
			else
				demon.compile_to_deck(user, deck, terminal)
			qdel(demon)
			return TRUE
		if("delete_deck")
			if(deck)
				var/delete_index = cyberdemon_parse_ui_index(params["index"])
				var/datum/cyberspace_demon/deleted_demon = (delete_index >= 1 && delete_index <= length(deck.demons)) ? deck.demons[delete_index] : null
				if(delete_cyberdemon_from_list(deck.demons, delete_index, user, deck))
					deck.forget_demon(deleted_demon)
					deck.sync_demon_actions(user)
			return TRUE
		if("delete_disk")
			if(disk)
				disk.delete_demon_by_index(params["index"], user)
			return TRUE
		if("copy_to_disk")
			if(!deck)
				to_chat(user, span_warning("No cyberdeck is available."))
				return TRUE
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			var/index = cyberdemon_parse_ui_index(params["index"])
			if(index < 1 || index > length(deck.demons))
				to_chat(user, span_warning("Invalid cyberdeck demon slot."))
				return TRUE
			var/datum/cyberspace_demon/demon = deck.demons[index]
			if(demon && disk.store_demon(demon.copy(demon.prebuilt), user))
				to_chat(user, span_notice("You copy [demon.demon_name] to [disk][demon.prebuilt ? " as an editable development copy" : ""]."))
			return TRUE
		if("load_from_disk")
			if(!deck)
				to_chat(user, span_warning("No cyberdeck is available."))
				return TRUE
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			disk.rebuild_demon_index()
			var/index = cyberdemon_parse_ui_index(params["index"])
			if(index < 1 || index > length(disk.demons))
				to_chat(user, span_warning("Invalid demon disk slot."))
				return TRUE
			var/datum/cyberspace_demon/demon = disk.demons[index]
			if(!demon)
				to_chat(user, span_warning("No demon exists in that disk slot."))
				return TRUE
			var/datum/cyberspace_demon/demon_copy = demon.copy()
			if(deck.store_demon(demon_copy, user))
				to_chat(user, span_notice("You load [demon.demon_name] from [disk] to [deck]."))
				SStgui.update_uis(deck)
				SStgui.update_uis(disk)
			else
				qdel(demon_copy)
			return TRUE
		if("download_net_data")
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			var/amount = cyberdemon_parse_ui_index(params["amount"])
			if(amount <= 0)
				amount = user.mind?.cyber_net_data || 0
			disk.download_net_data(user, amount)
			return TRUE
		if("upload_net_data")
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			disk.upload_net_data(user)
			return TRUE
		if("download_cryptokeys")
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			disk.download_cryptokeys(user)
			return TRUE
		if("upload_cryptokeys")
			if(!disk)
				to_chat(user, span_warning("No demon disk is available."))
				return TRUE
			disk.upload_cryptokeys(user)
			return TRUE
	return FALSE

/datum/action/cooldown/cyberdemon
	name = "Cyberdemon"
	desc = "Runs a compiled demon from a cyberdeck."
	background_icon_state = "bg_spell"
	button_icon = 'icons/obj/devices/circuitry_n_data.dmi'
	button_icon_state = "skillchip"
	overlay_icon_state = "bg_spell_border"
	click_to_activate = FALSE
	unset_after_click = TRUE
	check_flags = AB_CHECK_CONSCIOUS
	var/obj/item/clothing/gloves/cyberdeck/deck
	var/datum/cyberspace_demon/demon

/datum/action/cooldown/cyberdemon/New(datum/cyberspace_demon/new_demon, obj/item/clothing/gloves/cyberdeck/new_deck)
	. = ..(new_demon)
	demon = new_demon
	deck = new_deck
	if(demon)
		name = demon.demon_name
		desc = demon.description
		cooldown_time = demon.cooldown

/datum/action/cooldown/cyberdemon/Destroy()
	deck = null
	demon = null
	return ..()

/datum/action/cooldown/cyberdemon/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	if(QDELETED(deck) || QDELETED(demon))
		return FALSE
	var/mob/living/living_owner = owner
	if(!istype(living_owner) || !(deck in living_owner.contents))
		if(feedback && owner)
			owner.balloon_alert(owner, "no cyberdeck")
		return FALSE
	if(world.time < deck.compile_cooldown_until)
		if(feedback)
			living_owner.balloon_alert(living_owner, "deck cooling")
		return FALSE
	if(living_owner.cyberdemon_demons_blocked())
		if(feedback)
			living_owner.balloon_alert(living_owner, "demons blocked")
		return FALSE
	if(demon.cooldown > 0 && world.time < demon.next_use)
		if(feedback)
			living_owner.balloon_alert(living_owner, "cooling")
		return FALSE
	return TRUE

/datum/action/cooldown/cyberdemon/Activate(atom/target)
	var/mob/living/user = owner
	if(!istype(user) || QDELETED(deck) || QDELETED(demon))
		return FALSE
	if(target && target != user && target != deck)
		return deck.release_or_prepare_demon(user, target, demon)
	return deck.select_demon(demon, user)

/datum/action/cooldown/cyberspace_deck_entry
	name = "Enter/Exit Net"
	desc = "Project into or collapse out of the local cyberspace layer through this cyberdeck."
	background_icon_state = "bg_spell"
	button_icon = 'icons/obj/devices/circuitry_n_data.dmi'
	button_icon_state = "datadisk1"
	overlay_icon_state = "bg_spell_border"
	click_to_activate = FALSE
	unset_after_click = FALSE
	check_flags = AB_CHECK_CONSCIOUS
	var/obj/item/clothing/gloves/cyberdeck/deck

/datum/action/cooldown/cyberspace_deck_entry/New(obj/item/clothing/gloves/cyberdeck/new_deck)
	. = ..(new_deck)
	deck = new_deck

/datum/action/cooldown/cyberspace_deck_entry/Destroy()
	deck = null
	return ..()

/datum/action/cooldown/cyberspace_deck_entry/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/living_owner = owner
	if(!istype(living_owner) || QDELETED(deck) || !(deck in living_owner.contents))
		if(feedback && owner)
			owner.balloon_alert(owner, "no cyberdeck")
		return FALSE
	return TRUE

/datum/action/cooldown/cyberspace_deck_entry/Activate(atom/target)
	var/mob/living/user = owner
	if(!istype(user) || QDELETED(deck))
		return FALSE
	return deck.toggle_cyberspace_access(user)

/obj/item/clothing/gloves/cyberdeck
	name = "cyberdeck gloves"
	desc = "A glove-mounted cyberdeck that stores and runs compiled demons without a neural interface."
	icon_state = "black"
	var/memory_capacity = CYBER_DECK_DEFAULT_MEMORY
	var/list/demons = list()
	var/compile_cooldown_until = 0
	var/obj/item/cyberdemon_disk/inserted_disk
	var/list/demon_actions = list()
	var/datum/cyberspace_demon/selected_demon
	var/datum/cyberspace_demon/preparing_demon
	var/datum/cyberspace_demon/ready_demon
	var/prepared_power = 0
	var/prepared_physical_world = FALSE
	var/prepared_ready_time = 0
	var/prepare_token = 0
	var/datum/weakref/middleclick_owner_ref
	var/datum/action/cooldown/cyberspace_deck_entry/cyberspace_entry_action

/obj/item/clothing/gloves/cyberdeck/Destroy(force)
	clear_demon_actions()
	unregister_middleclick_owner()
	QDEL_LIST(demons)
	QDEL_NULL(inserted_disk)
	return ..()

/obj/item/clothing/gloves/cyberdeck/equipped(mob/living/user, slot)
	. = ..()
	if(istype(user))
		register_middleclick_owner(user)
		sync_demon_actions(user)

/obj/item/clothing/gloves/cyberdeck/dropped(mob/living/user)
	. = ..()
	unregister_middleclick_owner(user)
	clear_demon_actions(user)

/obj/item/clothing/gloves/cyberdeck/proc/register_middleclick_owner(mob/living/user)
	if(!istype(user))
		return
	unregister_middleclick_owner()
	middleclick_owner_ref = WEAKREF(user)
	RegisterSignal(user, COMSIG_MOB_MIDDLECLICKON, PROC_REF(on_owner_middleclick))
	RegisterSignal(user, COMSIG_MOB_MIDDLEMOUSEDOWNON, PROC_REF(on_owner_middle_mouse_down))
	RegisterSignal(user, COMSIG_MOB_MIDDLEMOUSEUPON, PROC_REF(on_owner_middle_mouse_up))

/obj/item/clothing/gloves/cyberdeck/proc/unregister_middleclick_owner(mob/living/user)
	var/mob/living/old_owner = user || middleclick_owner_ref?.resolve()
	if(old_owner)
		UnregisterSignal(old_owner, list(COMSIG_MOB_MIDDLECLICKON, COMSIG_MOB_MIDDLEMOUSEDOWNON, COMSIG_MOB_MIDDLEMOUSEUPON))
	middleclick_owner_ref = null

/obj/item/clothing/gloves/cyberdeck/proc/on_owner_middleclick(mob/living/user, atom/target, params)
	SIGNAL_HANDLER
	if(!istype(user) || !(src in user.contents))
		return
	if(!selected_demon && !ready_demon && !preparing_demon)
		return
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/clothing/gloves/cyberdeck/proc/on_owner_middle_mouse_down(mob/living/user, atom/target, params)
	SIGNAL_HANDLER
	if(!istype(user) || !(src in user.contents) || !selected_demon || ready_demon || preparing_demon)
		return
	prepare_selected_demon(user, selected_demon)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/clothing/gloves/cyberdeck/proc/on_owner_middle_mouse_up(mob/living/user, atom/target, params)
	SIGNAL_HANDLER
	if(!istype(user) || !(src in user.contents))
		return
	if(ready_demon)
		release_ready_demon(user, target)
		return COMSIG_MOB_CANCEL_CLICKON
	if(preparing_demon)
		to_chat(user, span_warning("[preparing_demon.demon_name] preparation is released before completion."))
		clear_prepared_demon()
		return COMSIG_MOB_CANCEL_CLICKON

/obj/item/clothing/gloves/cyberdeck/proc/select_demon(datum/cyberspace_demon/demon, mob/living/user)
	if(!demon || !(demon in demons))
		return FALSE
	selected_demon = demon
	to_chat(user, span_notice("[demon.demon_name] selected. Middle-click to prepare; middle-click a target when ready to release it."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/release_or_prepare_demon(mob/living/user, atom/target, datum/cyberspace_demon/demon)
	if(ready_demon)
		return release_ready_demon(user, target)
	if(preparing_demon)
		to_chat(user, span_warning("[preparing_demon.demon_name] is still preparing."))
		return TRUE
	return prepare_selected_demon(user, demon || selected_demon)

/obj/item/clothing/gloves/cyberdeck/proc/prepare_selected_demon(mob/living/user, datum/cyberspace_demon/demon)
	if(!istype(user) || !demon || !(demon in demons))
		return FALSE
	if(!can_run_demons(user))
		return FALSE
	if(demon.cooldown > 0 && world.time < demon.next_use)
		to_chat(user, span_warning("[demon.demon_name] is cooling down for [DisplayTimeText(demon.next_use - world.time)]."))
		return TRUE
	preparing_demon = demon
	ready_demon = null
	prepare_token++
	var/current_token = prepare_token
	prepared_physical_world = !user.is_projected_into_cyberspace()
	prepared_power = demon.get_effective_power(user, prepared_physical_world)
	prepared_ready_time = 0
	var/prepare_time = demon.get_effective_cast_time(user)
	to_chat(user, span_notice("You start preparing [demon.demon_name]."))
	INVOKE_ASYNC(src, PROC_REF(finish_demon_preparation), WEAKREF(user), WEAKREF(demon), current_token, prepare_time)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/finish_demon_preparation(datum/weakref/user_ref, datum/weakref/demon_ref, current_token, prepare_time)
	var/mob/living/user = user_ref?.resolve()
	var/datum/cyberspace_demon/demon = demon_ref?.resolve()
	if(prepare_time > 0 && (!user || !do_after(user, prepare_time, target = src, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE)))
		if(prepare_token == current_token)
			clear_prepared_demon()
		if(user && demon)
			to_chat(user, span_warning("[demon.demon_name] preparation collapses."))
		return TRUE
	if(prepare_token != current_token || preparing_demon != demon)
		return TRUE
	preparing_demon = null
	ready_demon = demon
	prepared_ready_time = world.time
	to_chat(user, span_notice("[demon.demon_name] is ready. Middle-click a target to release it."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/release_ready_demon(mob/living/user, atom/target)
	if(!istype(user) || !target || !ready_demon)
		clear_prepared_demon()
		return FALSE
	var/datum/cyberspace_demon/demon = ready_demon
	var/current_power = prepared_power
	var/physical_world = prepared_physical_world
	var/list/overcharge = get_prepared_demon_overcharge(user)
	var/power_bonus = overcharge["power"]
	var/activation_bonus = overcharge["activation"]
	if(power_bonus > 0)
		current_power = round(current_power * (1 + (power_bonus / 100)))
	var/activation_delay_multiplier = max(0, 1 - (activation_bonus / 100))
	if(power_bonus > 0 || activation_bonus > 0)
		to_chat(user, span_notice("[demon.demon_name] releases overcharged: power +[round(power_bonus, 0.1)]%, activation delay -[round(activation_bonus, 0.1)]%."))
	clear_prepared_demon()
	return demon.release_prepared(user, target, src, current_power, physical_world, activation_delay_multiplier)

/obj/item/clothing/gloves/cyberdeck/proc/get_prepared_demon_overcharge(mob/living/user)
	var/list/overcharge = list(
		"power" = 0,
		"activation" = 0,
	)
	if(!istype(user) || !prepared_ready_time || world.time <= prepared_ready_time)
		return overcharge
	var/held_seconds = FLOOR((world.time - prepared_ready_time) / (1 SECONDS), 1)
	if(held_seconds <= 0)
		return overcharge
	var/power_cap = user.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 4, "value_1") || 0
	var/power_step = user.mind?.get_character_perk_effectiveness(SKILL_ENHANCED_CODE, 4, "value_2") || 0
	if(power_cap > 0 && power_step > 0)
		overcharge["power"] = min(power_cap, held_seconds * power_step)
	var/activation_cap = user.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 4, "value_1") || 0
	var/activation_step = user.mind?.get_character_perk_effectiveness(SKILL_FAST_CODE, 4, "value_2") || 0
	if(activation_cap > 0 && activation_step > 0)
		overcharge["activation"] = min(activation_cap, held_seconds * activation_step)
	return overcharge

/obj/item/clothing/gloves/cyberdeck/proc/clear_prepared_demon()
	preparing_demon = null
	ready_demon = null
	prepared_power = 0
	prepared_physical_world = FALSE
	prepared_ready_time = 0
	prepare_token++

/obj/item/clothing/gloves/cyberdeck/proc/clear_demon_actions(mob/living/user)
	var/mob/action_owner = user
	if(cyberspace_entry_action)
		if(!action_owner)
			action_owner = cyberspace_entry_action.owner
		cyberspace_entry_action.Remove(cyberspace_entry_action.owner)
		QDEL_NULL(cyberspace_entry_action)
	for(var/datum/action/action as anything in demon_actions)
		if(!action_owner)
			action_owner = action.owner
		action.Remove(action.owner)
		qdel(action)
	demon_actions = list()
	action_owner?.update_action_buttons(TRUE)

/obj/item/clothing/gloves/cyberdeck/proc/sync_demon_actions(mob/living/user)
	clear_demon_actions(user)
	if(!istype(user) || !(src in user.contents))
		return
	cyberspace_entry_action = new(src)
	cyberspace_entry_action.Grant(user)
	for(var/datum/cyberspace_demon/demon as anything in demons)
		if(QDELETED(demon))
			continue
		var/datum/action/cooldown/cyberdemon/demon_action = new(demon, src)
		demon_actions += demon_action
		demon_action.Grant(user)
	user.update_action_buttons(TRUE)

/obj/item/clothing/gloves/cyberdeck/proc/toggle_cyberspace_access(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.cyberspace_session)
		return user.stop_cyberspace_session()
	return user.start_cyberspace_session(CYBERSPACE_MODE_AVATAR, src)

/obj/item/clothing/gloves/cyberdeck/proc/get_used_memory()
	var/used_memory = 0
	for(var/datum/cyberspace_demon/demon as anything in demons)
		used_memory += demon.memory_cost
	return used_memory

/obj/item/clothing/gloves/cyberdeck/proc/get_free_memory()
	return max(0, memory_capacity - get_used_memory())

/obj/item/clothing/gloves/cyberdeck/proc/can_store_demon(datum/cyberspace_demon/demon, mob/user)
	if(!demon)
		return FALSE
	if(demon.memory_cost > memory_capacity)
		to_chat(user, span_warning("[demon.demon_name] is too large for [src]."))
		return FALSE
	if(demon.memory_cost > get_free_memory())
		to_chat(user, span_warning("[src] has only [get_free_memory()] free memory."))
		return FALSE
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/store_demon(datum/cyberspace_demon/demon, mob/user)
	if(!can_store_demon(demon, user))
		return FALSE
	demons += demon
	var/mob/living/living_user = user
	if(istype(living_user))
		sync_demon_actions(living_user)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/forget_demon(datum/cyberspace_demon/demon)
	if(selected_demon == demon)
		selected_demon = null
	if(preparing_demon == demon || ready_demon == demon)
		clear_prepared_demon()

/obj/item/clothing/gloves/cyberdeck/proc/can_compile(mob/user)
	if(world.time < compile_cooldown_until)
		to_chat(user, span_warning("[src] is cooling down for [DisplayTimeText(compile_cooldown_until - world.time)]."))
		return FALSE
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/start_compile_cooldown()
	compile_cooldown_until = world.time + CYBER_DECK_COMPILE_COOLDOWN

/obj/item/clothing/gloves/cyberdeck/proc/can_run_demons(mob/user)
	if(world.time < compile_cooldown_until)
		to_chat(user, span_warning("[src] is locked by its compilation cooldown."))
		return FALSE
	var/mob/living/living_user = user
	if(istype(living_user) && living_user.cyberdemon_demons_blocked())
		to_chat(user, span_warning("Your demon runtime is blocked by hostile code."))
		return FALSE
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/choose_demon(mob/user)
	if(!length(demons))
		to_chat(user, span_warning("[src] has no compiled demons."))
		return null
	var/list/options = list()
	for(var/datum/cyberspace_demon/demon as anything in demons)
		options["[demon.demon_name] ([demon.memory_cost])"] = demon
	var/choice = tgui_input_list(user, "Choose a compiled demon.", name, options)
	if(!choice)
		return null
	return options[choice]

/obj/item/clothing/gloves/cyberdeck/proc/compile_stock_demon(mob/living/user, obj/machinery/cyberdemon_terminal/terminal)
	to_chat(user, span_warning("Prebuilt demons are loaded from demon disks, not compiled from the catalog."))
	return FALSE

/obj/item/clothing/gloves/cyberdeck/proc/delete_demon(mob/user)
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
		return FALSE
	if(demon.prebuilt)
		to_chat(user, span_warning("Prebuilt demons cannot be deleted from [src]."))
		return FALSE
	demons -= demon
	forget_demon(demon)
	to_chat(user, span_notice("You delete [demon.demon_name] from [src]."))
	qdel(demon)
	var/mob/living/living_user = user
	if(istype(living_user))
		sync_demon_actions(living_user)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/find_held_demon_disk(mob/user)
	if(inserted_disk)
		return inserted_disk
	var/obj/item/cyberdemon_disk/disk = locate(/obj/item/cyberdemon_disk) in user.held_items
	if(!disk)
		disk = locate(/obj/item/cyberdemon_disk) in user.contents
	return disk

/obj/item/clothing/gloves/cyberdeck/proc/insert_demon_disk(obj/item/cyberdemon_disk/disk, mob/user)
	if(!disk || inserted_disk == disk)
		return FALSE
	if(inserted_disk)
		eject_demon_disk(user)
	if(user && !user.transferItemToLoc(disk, src))
		return FALSE
	inserted_disk = disk
	to_chat(user, span_notice("You insert [disk] into [src]."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/eject_demon_disk(mob/user)
	if(!inserted_disk)
		to_chat(user, span_warning("[src] has no demon disk inserted."))
		return FALSE
	var/obj/item/cyberdemon_disk/disk = inserted_disk
	inserted_disk = null
	disk.forceMove(drop_location())
	if(user)
		user.put_in_hands(disk)
		to_chat(user, span_notice("You eject [disk] from [src]."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/copy_demon_to_disk(mob/user)
	var/obj/item/cyberdemon_disk/disk = find_held_demon_disk(user)
	if(!disk)
		to_chat(user, span_warning("You need a demon disk."))
		return FALSE
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
		return FALSE
	if(demon.prebuilt)
		to_chat(user, span_warning("Prebuilt demons cannot be copied from [src]."))
		return FALSE
	if(!disk.store_demon(demon.copy(), user))
		return FALSE
	to_chat(user, span_notice("You copy [demon.demon_name] to [disk]."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/load_demon_from_disk(mob/user)
	var/obj/item/cyberdemon_disk/disk = find_held_demon_disk(user)
	if(!disk)
		to_chat(user, span_warning("You need a demon disk."))
		return FALSE
	var/datum/cyberspace_demon/demon = disk.choose_demon(user)
	if(!demon)
		return FALSE
	if(!store_demon(demon.copy(), user))
		return FALSE
	to_chat(user, span_notice("You load [demon.demon_name] from [disk] to [src]."))
	return TRUE

/obj/item/clothing/gloves/cyberdeck/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/clothing/gloves/cyberdeck/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberDemonCompiler", name)
		ui.open()

/obj/item/clothing/gloves/cyberdeck/ui_static_data(mob/user)
	return cyberdemon_compiler_static_data()

/obj/item/clothing/gloves/cyberdeck/ui_data(mob/user)
	return cyberdemon_storage_ui_data(src, find_accessible_cyberdemon_disk(user, src, null), null, user)

/obj/item/clothing/gloves/cyberdeck/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, src, find_accessible_cyberdemon_disk(ui.user, src, null), null)

/obj/item/clothing/gloves/cyberdeck/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberdemon_disk))
		return insert_demon_disk(attacking_item, user)
	return ..()

/obj/item/clothing/gloves/cyberdeck/click_alt(mob/user)
	if(eject_demon_disk(user))
		return CLICK_ACTION_SUCCESS
	return ..()

/obj/item/clothing/gloves/cyberdeck/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(user) || !target || target == src)
		return
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
		return
	demon.apply(user, target, src)

/obj/item/clothing/gloves/cyberdeck/cheap
	name = "sulfur cyberdeck gloves"
	desc = "A stripped glove-mounted cyberdeck with minimal demon memory. It works from the hands, without a neural interface."
	memory_capacity = CYBER_DECK_MIN_MEMORY

/obj/item/clothing/gloves/cyberdeck/advanced
	name = "advanced cyberdeck gloves"
	desc = "A high-grade glove-mounted cyberdeck with expanded demon memory. It works from the hands, without a neural interface."
	memory_capacity = CYBER_DECK_MAX_MEMORY

/obj/item/clothing/gloves/cyberdeck/implant_proxy
	name = "implanted cyberdeck runtime"
	desc = "A hidden runtime for an implanted cyberdeck OS."
	item_flags = ABSTRACT
	invisibility = INVISIBILITY_ABSTRACT
	memory_capacity = CYBER_DECK_DEFAULT_MEMORY

/obj/item/clothing/gloves/cyberdeck/implant_proxy/equipped(mob/living/user, slot)
	. = ..()
	return

/obj/item/clothing/gloves/cyberdeck/implant_proxy/dropped(mob/living/user)
	. = ..()
	return

/datum/cyberpunk_data_payload
	/// Generic payload type. Demons use CYBERPUNK_DATA_PAYLOAD_DEMON now; genetics will reuse this datum later.
	var/payload_type = "generic"
	var/payload_id
	var/payload_name = "data payload"
	var/list/payload_data = list()
	var/integrity = 100
	var/encrypted = FALSE
	var/datum/contained_datum

/datum/cyberpunk_data_payload/Destroy(force)
	QDEL_NULL(contained_datum)
	payload_data = null
	return ..()

/datum/cyberpunk_data_payload/proc/copy()
	var/datum/cyberpunk_data_payload/new_payload = new type
	new_payload.payload_type = payload_type
	new_payload.payload_id = payload_id
	new_payload.payload_name = payload_name
	new_payload.payload_data = payload_data?.Copy() || list()
	new_payload.integrity = integrity
	new_payload.encrypted = encrypted
	if(contained_datum)
		var/datum/cyberspace_demon/demon = contained_datum
		if(istype(demon))
			new_payload.contained_datum = demon.copy()
	return new_payload

/datum/cyberpunk_data_payload/demon
	payload_type = CYBERPUNK_DATA_PAYLOAD_DEMON

/datum/cyberpunk_data_payload/demon/New(datum/cyberspace_demon/demon)
	. = ..()
	if(!demon)
		return
	contained_datum = demon
	payload_id = replacetext("[demon.type]", "/", "_")
	payload_name = demon.demon_name
	payload_data = list(
		"description" = demon.description,
		"manufacturer" = demon.manufacturer,
		"memory_cost" = demon.memory_cost,
		"effect" = demon.effect,
		"effect_power" = demon.effect_power,
		"prebuilt" = demon.prebuilt,
	)

/datum/cyberpunk_data_payload/cryptokey
	payload_type = CYBERPUNK_DATA_PAYLOAD_CRYPTOKEY

/datum/cyberpunk_data_payload/cryptokey/New(datum/cyberspace_cryptokey/cryptokey)
	. = ..()
	if(!cryptokey)
		return
	payload_id = cryptokey.key
	payload_name = "cryptokey [cryptokey.key]"
	payload_data = list(
		"key" = cryptokey.key,
		"manufacturer" = cryptokey.manufacturer,
		"object_type" = cryptokey.object_type,
		"area_type" = cryptokey.area_type,
		"rights" = cryptokey.rights?.Copy(),
	)

/obj/item/cyberdemon_disk
	name = "demon disk"
	desc = "A removable data disk for compiled demons and other net payloads."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "skillchip"
	inhand_icon_state = "electronic"
	w_class = WEIGHT_CLASS_SMALL
	var/memory_capacity = CYBER_DEMON_DISK_MEMORY
	var/list/datum/cyberpunk_data_payload/data_payloads = list()
	/// Runtime index for old demon UI/deck code. The authoritative storage is data_payloads.
	var/list/demons = list()
	var/stored_net_data = 0
	var/list/stored_cryptokeys = list()

/obj/item/cyberdemon_disk/Destroy(force)
	QDEL_LIST(data_payloads)
	demons = null
	stored_cryptokeys = null
	return ..()

/obj/item/cyberdemon_disk/proc/add_data_payload(datum/cyberpunk_data_payload/payload)
	if(!payload)
		return FALSE
	if(!data_payloads)
		data_payloads = list()
	data_payloads += payload
	var/datum/cyberpunk_data_payload/demon/demon_payload = payload
	if(istype(demon_payload))
		var/datum/cyberspace_demon/demon = demon_payload.contained_datum
		if(istype(demon))
			if(!demons)
				demons = list()
			demons += demon
	return TRUE

/obj/item/cyberdemon_disk/proc/get_data_payloads(payload_type)
	var/list/found_payloads = list()
	for(var/datum/cyberpunk_data_payload/payload as anything in data_payloads)
		if(payload.payload_type == payload_type)
			found_payloads += payload
	return found_payloads

/obj/item/cyberdemon_disk/proc/rebuild_demon_index()
	if(!demons)
		demons = list()
	demons.Cut()
	for(var/datum/cyberpunk_data_payload/demon/payload as anything in get_data_payloads(CYBERPUNK_DATA_PAYLOAD_DEMON))
		var/datum/cyberspace_demon/demon = payload.contained_datum
		if(istype(demon))
			demons += demon

/obj/item/cyberdemon_disk/proc/get_used_memory()
	rebuild_demon_index()
	var/used_memory = 0
	for(var/datum/cyberspace_demon/demon as anything in demons)
		used_memory += demon.memory_cost
	return used_memory

/obj/item/cyberdemon_disk/proc/get_free_memory()
	return max(0, memory_capacity - get_used_memory())

/obj/item/cyberdemon_disk/proc/can_store_demon(datum/cyberspace_demon/demon, mob/user)
	if(!demon)
		return FALSE
	if(get_used_memory() + demon.memory_cost > memory_capacity)
		to_chat(user, span_warning("[src] lacks enough free disk memory."))
		return FALSE
	return TRUE

/obj/item/cyberdemon_disk/proc/store_demon(datum/cyberspace_demon/demon, mob/user)
	if(!can_store_demon(demon, user))
		return FALSE
	return add_data_payload(new /datum/cyberpunk_data_payload/demon(demon))

/obj/item/cyberdemon_disk/proc/get_stored_cryptokey_count()
	return length(stored_cryptokeys)

/obj/item/cyberdemon_disk/proc/cryptokey_from_memory(memory_entry)
	if(istype(memory_entry, /datum/cyberspace_cryptokey))
		return memory_entry
	if(!islist(memory_entry))
		return null
	var/key = memory_entry["key"]
	if(!key)
		return null
	var/datum/cyberspace_cryptokey/cryptokey = new()
	cryptokey.key = key
	cryptokey.object_type = memory_entry["object_type"]
	cryptokey.area_type = memory_entry["area_type"]
	cryptokey.manufacturer = memory_entry["manufacturer"] || "independent"
	var/list/rights = memory_entry["rights"]
	cryptokey.rights = islist(rights) ? rights.Copy() : list("view", "use", "control", "settings")
	return cryptokey

/obj/item/cyberdemon_disk/proc/download_net_data(mob/living/user, amount)
	if(!user?.mind)
		return FALSE
	amount = min(max(0, round(amount)), user.mind.cyber_net_data)
	if(amount <= 0)
		to_chat(user, span_warning("No net-data is available to write."))
		return FALSE
	user.mind.cyber_net_data -= amount
	stored_net_data += amount
	to_chat(user, span_notice("You write [amount] net-data to [src]. Disk net-data: [stored_net_data]."))
	return TRUE

/obj/item/cyberdemon_disk/proc/upload_net_data(mob/living/user)
	if(!user?.mind)
		return FALSE
	if(stored_net_data <= 0)
		to_chat(user, span_warning("[src] has no stored net-data."))
		return FALSE
	var/amount = stored_net_data
	stored_net_data = 0
	user.mind.add_cyber_net_data(amount)
	to_chat(user, span_notice("You load [amount] net-data from [src]. Total net-data: [user.mind.cyber_net_data]."))
	return TRUE

/obj/item/cyberdemon_disk/proc/download_cryptokeys(mob/living/user)
	if(!user)
		return FALSE
	if(!length(user?.mind?.cyber_cryptokeys) && !length(user.memory_holder))
		to_chat(user, span_warning("No cached or remembered cryptographic keys are available to write."))
		return FALSE
	if(!stored_cryptokeys)
		stored_cryptokeys = list()
	var/copied = 0
	if(length(user?.mind?.cyber_cryptokeys))
		for(var/key in user.mind.cyber_cryptokeys)
			if(stored_cryptokeys[key])
				continue
			stored_cryptokeys[key] = user.mind.cyber_cryptokeys[key]
			add_data_payload(new /datum/cyberpunk_data_payload/cryptokey(stored_cryptokeys[key]))
			copied++
	if(length(user.memory_holder))
		for(var/memory_title in user.memory_holder)
			if(!findtext(memory_title, "cryptokey:"))
				continue
			var/datum/cyberspace_cryptokey/cryptokey = cryptokey_from_memory(user.memory_holder[memory_title])
			if(!cryptokey || stored_cryptokeys[cryptokey.key])
				continue
			stored_cryptokeys[cryptokey.key] = cryptokey
			add_data_payload(new /datum/cyberpunk_data_payload/cryptokey(cryptokey))
			copied++
	to_chat(user, span_notice("You write [copied] cryptographic key[copied == 1 ? "" : "s"] to [src]."))
	return TRUE

/obj/item/cyberdemon_disk/proc/upload_cryptokeys(mob/living/user)
	if(!user?.mind)
		return FALSE
	if(!length(stored_cryptokeys))
		to_chat(user, span_warning("[src] has no stored cryptographic keys."))
		return FALSE
	var/loaded = 0
	for(var/key in stored_cryptokeys)
		var/datum/cyberspace_cryptokey/cryptokey = stored_cryptokeys[key]
		if(user.mind.has_cyber_cryptokey(cryptokey))
			continue
		if(user.mind.remember_cyber_cryptokey(cryptokey))
			loaded++
	to_chat(user, span_notice("You load [loaded] cryptographic key[loaded == 1 ? "" : "s"] from [src]."))
	return TRUE

/obj/item/cyberdemon_disk/prebuilt
	name = "prebuilt demon disk"
	desc = "A library disk with locked prebuilt demons. The demons can be loaded or copied into a custom design, but not deleted."
	var/list/prebuilt_demon_types = list(
		/datum/cyberspace_demon/wall,
		/datum/cyberspace_demon/blink,
		/datum/cyberspace_demon/cloak,
		/datum/cyberspace_demon/vanish,
	)

/obj/item/cyberdemon_disk/prebuilt/Initialize(mapload)
	. = ..()
	for(var/demon_type in prebuilt_demon_types)
		store_demon(new demon_type)

/obj/item/cyberdemon_disk/primary
	name = "primary demon data disk"
	desc = "A general-purpose CP13 data disk carrying the primary demon payloads. Later the same storage format can carry genetic data."
	var/list/primary_demon_types = list(
		/datum/cyberspace_demon/wall,
		/datum/cyberspace_demon/blink,
		/datum/cyberspace_demon/cloak,
		/datum/cyberspace_demon/vanish,
	)

/obj/item/cyberdemon_disk/primary/Initialize(mapload)
	. = ..()
	for(var/demon_type in primary_demon_types)
		store_demon(new demon_type)

/obj/item/cyberdemon_disk/prebuilt/soul
	name = "prebuilt soul demon disk"
	prebuilt_demon_types = list(
		/datum/cyberspace_demon/soulcatcher,
		/datum/cyberspace_demon/soulconduit,
		/datum/cyberspace_demon/wall,
		/datum/cyberspace_demon/blink,
	)

/obj/item/cyberdemon_disk/prebuilt/debug_all
	name = "debug prebuilt demon disk"
	desc = "A temporary debug disk with every currently defined prebuilt demon."
	memory_capacity = 24

/obj/item/cyberdemon_disk/prebuilt/debug_all/Initialize(mapload)
	. = ..()
	QDEL_LIST(data_payloads)
	demons.Cut()
	var/list/catalog = get_cyberdemon_catalog()
	for(var/demon_name in catalog)
		var/demon_type = catalog[demon_name]
		store_demon(new demon_type)

/obj/item/cyberdemon_disk/veil
	name = "old Veil demon disk"
	desc = "A decoded fragment of ancient Veil combat logic. Its contents are fixed by the spent reward key."
	memory_capacity = CYBER_DEMON_DISK_MEMORY

/obj/item/cyberdemon_disk/veil/proc/build_from_veil_key(key, level)
	QDEL_LIST(data_payloads)
	demons.Cut()
	level = clamp(round(level), 1, CYBERSPACE_VEIL_DATA_VAULT_MAX_LEVEL)
	memory_capacity = CYBER_DEMON_DISK_MEMORY + max(0, level - 2) * 2
	name = "old Veil demon disk L[level]"
	var/seed = get_veil_reward_key_seed(key)
	var/list/demon_types = list(
		/datum/cyberspace_demon/wall,
		/datum/cyberspace_demon/blink,
		/datum/cyberspace_demon/cloak,
		/datum/cyberspace_demon/vanish,
		/datum/cyberspace_demon/soulcatcher,
		/datum/cyberspace_demon/soulconduit,
	)
	var/list/added_types = list()
	var/demon_count = clamp(level + 1, 2, length(demon_types))
	for(var/i in 1 to demon_count)
		var/demon_type = demon_types[((seed + i - 1) % length(demon_types)) + 1]
		if(added_types[demon_type])
			continue
		added_types[demon_type] = TRUE
		store_demon(new demon_type)
	if(!length(demons))
		store_demon(new /datum/cyberspace_demon/wall)

/obj/item/cyberdemon_disk/proc/choose_demon(mob/user)
	rebuild_demon_index()
	if(!length(demons))
		to_chat(user, span_warning("[src] has no stored demons."))
		return null
	var/list/options = list()
	for(var/datum/cyberspace_demon/demon as anything in demons)
		options["[demon.demon_name] ([demon.memory_cost])"] = demon
	var/choice = tgui_input_list(user, "Choose a stored demon.", name, options)
	if(!choice)
		return null
	return options[choice]

/obj/item/cyberdemon_disk/attack_self(mob/user, modifiers)
	ui_interact(user)
	return TRUE

/obj/item/cyberdemon_disk/ui_state(mob/user)
	return GLOB.inventory_state

/obj/item/cyberdemon_disk/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberDemonCompiler", name)
		ui.open()

/obj/item/cyberdemon_disk/ui_static_data(mob/user)
	return cyberdemon_compiler_static_data()

/obj/item/cyberdemon_disk/ui_data(mob/user)
	return cyberdemon_storage_ui_data(find_held_cyberdeck(user), src, null, user)

/obj/item/cyberdemon_disk/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, find_held_cyberdeck(ui.user), src, null)

/obj/machinery/cyberdemon_terminal
	name = "demon compiler terminal"
	desc = "A network terminal that compiles demons into cyberdecks."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "comm_server"
	base_icon_state = "comm_server"
	density = TRUE
	anchored = TRUE
	var/compile_cooldown_until = 0
	var/obj/item/cyberdemon_disk/inserted_disk

/obj/machinery/cyberdemon_terminal/Destroy(force)
	QDEL_NULL(inserted_disk)
	return ..()

/obj/machinery/cyberdemon_terminal/proc/can_compile(mob/user)
	if(world.time < compile_cooldown_until)
		to_chat(user, span_warning("[src] is cooling down for [DisplayTimeText(compile_cooldown_until - world.time)]."))
		return FALSE
	return TRUE

/obj/machinery/cyberdemon_terminal/proc/start_compile_cooldown()
	compile_cooldown_until = world.time + CYBER_TERMINAL_COMPILE_COOLDOWN

/obj/machinery/cyberdemon_terminal/proc/insert_demon_disk(obj/item/cyberdemon_disk/disk, mob/user)
	if(!disk || inserted_disk == disk)
		return FALSE
	if(inserted_disk)
		eject_demon_disk(user)
	if(user && !user.transferItemToLoc(disk, src))
		return FALSE
	inserted_disk = disk
	to_chat(user, span_notice("You insert [disk] into [src]."))
	return TRUE

/obj/machinery/cyberdemon_terminal/proc/eject_demon_disk(mob/user)
	if(!inserted_disk)
		to_chat(user, span_warning("[src] has no demon disk inserted."))
		return FALSE
	var/obj/item/cyberdemon_disk/disk = inserted_disk
	inserted_disk = null
	disk.forceMove(drop_location())
	if(user)
		user.put_in_hands(disk)
		to_chat(user, span_notice("You eject [disk] from [src]."))
	return TRUE

/obj/machinery/cyberdemon_terminal/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/machinery/cyberdemon_terminal/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberdemon_disk))
		return insert_demon_disk(attacking_item, user)
	return ..()

/obj/machinery/cyberdemon_terminal/click_alt(mob/user)
	if(eject_demon_disk(user))
		return CLICK_ACTION_SUCCESS
	return ..()

/obj/machinery/cyberdemon_terminal/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/cyberdemon_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberDemonCompiler", name)
		ui.open()

/obj/machinery/cyberdemon_terminal/ui_static_data(mob/user)
	return cyberdemon_compiler_static_data()

/obj/machinery/cyberdemon_terminal/ui_data(mob/user)
	var/obj/item/clothing/gloves/cyberdeck/deck = find_held_cyberdeck(user)
	return cyberdemon_storage_ui_data(deck, find_accessible_cyberdemon_disk(user, deck, src), src, user)

/obj/machinery/cyberdemon_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	var/obj/item/clothing/gloves/cyberdeck/deck = find_held_cyberdeck(ui.user)
	return handle_cyberdemon_compiler_action(action, params, ui.user, deck, find_accessible_cyberdemon_disk(ui.user, deck, src), src)

/datum/cyberdemon_debug_compiler
	var/mob/living/owner

/datum/cyberdemon_debug_compiler/New(mob/living/new_owner)
	. = ..()
	owner = new_owner

/datum/cyberdemon_debug_compiler/Destroy(force)
	owner = null
	return ..()

/datum/cyberdemon_debug_compiler/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberdemon_debug_compiler/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberDemonCompiler", "Temporary Demon Compiler")
		ui.open()

/datum/cyberdemon_debug_compiler/ui_static_data(mob/user)
	return cyberdemon_compiler_static_data()

/datum/cyberdemon_debug_compiler/ui_data(mob/user)
	var/obj/item/clothing/gloves/cyberdeck/deck = find_held_cyberdeck(user)
	return cyberdemon_storage_ui_data(deck, find_accessible_cyberdemon_disk(user, deck, null), null, user, TRUE, "temporary IC compiler", 0)

/datum/cyberdemon_debug_compiler/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(action == "change_ui_state")
		return
	var/obj/item/clothing/gloves/cyberdeck/deck = find_held_cyberdeck(ui.user)
	return handle_cyberdemon_compiler_action(action, params, ui.user, deck, find_accessible_cyberdemon_disk(ui.user, deck, null), null)
