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

/datum/cyberspace_demon/proc/copy()
	var/datum/cyberspace_demon/new_demon = new type
	new_demon.demon_name = demon_name
	new_demon.description = description
	new_demon.effect = effect
	new_demon.effect_power = effect_power
	new_demon.cast_time = cast_time
	new_demon.duration = duration
	new_demon.special_effects = special_effects.Copy()
	new_demon.memory_cost = memory_cost
	new_demon.manufacturer = manufacturer
	new_demon.prebuilt = prebuilt
	new_demon.net_data_cost = net_data_cost
	new_demon.psychic_damage = psychic_damage
	new_demon.stamina_cost = stamina_cost
	new_demon.activation_delay = activation_delay
	new_demon.effect_frequency = effect_frequency
	new_demon.target_attribute = target_attribute
	new_demon.target_skill = target_skill
	new_demon.cooldown = cooldown
	return new_demon

/datum/cyberspace_demon/proc/get_effective_power(physical_world = FALSE)
	var/power = effect_power
	if(physical_world)
		power *= CYBER_DEMON_PHYSICAL_WORLD_MULTIPLIER
	return round(power)

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
	if(stamina_cost > 0 && !caster.spend_stamina(stamina_cost, "cyberdemon"))
		to_chat(caster, span_warning("You do not have enough stamina to run [demon_name]."))
		return FALSE
	var/physical_world = !caster.is_projected_into_cyberspace()
	var/current_power = get_effective_power(physical_world)
	if(CYBER_DEMON_SPECIAL_STEALTH in special_effects)
		to_chat(caster, span_notice("[demon_name] suppresses its network signature."))
	to_chat(caster, span_notice("You start preparing [demon_name]."))
	if(!do_after(caster, cast_time, target = target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		to_chat(caster, span_warning("[demon_name] fizzles before activation."))
		return FALSE
	if(activation_delay > 0)
		to_chat(caster, span_notice("[demon_name] is queued for activation."))
		if(!do_after(caster, activation_delay, target = target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
			to_chat(caster, span_warning("[demon_name] loses its activation window."))
			return FALSE
	apply_psychic_damage(caster)
	var/success = apply_effect(caster, target, current_power, physical_world)
	if(success && cooldown > 0)
		next_use = world.time + cooldown
	return success

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

/mob/living/proc/cyberdemon_block_demons(block_duration)
	cyberdemon_block_demons_until = max(cyberdemon_block_demons_until, world.time + block_duration)

/mob/living/proc/cyberdemon_demons_blocked()
	return world.time < cyberdemon_block_demons_until

/mob/living/proc/cyberdemon_block_implants(block_duration)
	cyberdemon_block_implants_until = max(cyberdemon_block_implants_until, world.time + block_duration)

/mob/living/proc/cyberdemon_implants_blocked()
	return world.time < cyberdemon_block_implants_until

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

/datum/cyberspace_demon/proc/apply_effect(mob/living/caster, atom/target, current_power, physical_world)
	var/success = apply_primary_effect(caster, target, current_power, physical_world)
	if(success)
		schedule_periodic_effects(caster, target, current_power, physical_world)
		apply_special_effects(caster, target, current_power, physical_world)
	return success

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
	if(!caster || !target)
		return FALSE
	return apply_primary_effect(caster, target, current_power, physical_world, FALSE)

/datum/cyberspace_demon/proc/apply_primary_effect(mob/living/caster, atom/target, current_power, physical_world, announce = TRUE)
	var/absolute_power = abs(current_power)
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
	if(target_node && (effect in list(CYBER_DEMON_EFFECT_DAMAGE, CYBER_DEMON_EFFECT_BURN, CYBER_DEMON_EFFECT_ACID, CYBER_DEMON_EFFECT_TOX, CYBER_DEMON_EFFECT_OVERHEAT)))
		var/datum/cyber_ice/ice = target_node.get_ice()
		if(!ice)
			return FALSE
		ice.apply_reserve_damage(max(1, absolute_power))
		if(announce)
			to_chat(caster, span_notice("[demon_name] converts into network damage and lowers [target_node_name] protection by [max(1, absolute_power)]."))
		return TRUE
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
				if(caster.is_projected_into_cyberspace())
					living_target.adjust_chromity_overheat(absolute_power)
				else
					living_target.apply_damage(absolute_power, BURN)
				if(announce)
					to_chat(caster, span_notice("[demon_name] applies HEAT/ACID pressure to [target] for [absolute_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_TOX)
			var/mob/living/living_target = target
			if(istype(living_target))
				if(caster.is_projected_into_cyberspace())
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
				to_chat(caster, span_warning("[demon_name] needs a cyberspace node target."))
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
			if(istype(living_target) && living_target.mind && duration > 0)
				living_target.mind.add_cyberdemon_attribute_modifier(target_attribute, current_power, duration, demon_name)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s [target_attribute] by [current_power] for [DisplayTimeText(duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_SKILL)
			var/mob/living/living_target = target
			if(istype(living_target) && living_target.mind && duration > 0)
				living_target.mind.add_cyberdemon_skill_modifier(target_skill, current_power, duration, demon_name)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s skill routing by [current_power] for [DisplayTimeText(duration)]."))
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
				living_target.set_temp_blindness_if_lower(max(1 SECONDS, duration || (absolute_power SECONDS)))
				if(announce)
					to_chat(caster, span_notice("[demon_name] blinds [target]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_DEAF)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/trait_source = "cyberdemon_deaf_[REF(src)]"
				ADD_TRAIT(living_target, TRAIT_DEAF, trait_source)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_trait), WEAKREF(living_target), TRAIT_DEAF, trait_source), max(1 SECONDS, duration || (absolute_power SECONDS)))
				if(announce)
					to_chat(caster, span_notice("[demon_name] suppresses [target]'s hearing."))
				return TRUE
		if(CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_DEMONS)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/block_duration = max(1 SECONDS, duration || (absolute_power SECONDS))
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
			var/turf/target_turf = get_turf(target)
			if(target_turf)
				caster.forceMove(target_turf)
				if(announce)
					to_chat(caster, span_notice("[demon_name] moves you through the network."))
				return TRUE
		if(CYBER_DEMON_EFFECT_MOVE_SPEED)
			var/mob/living/living_target = target
			if(istype(living_target) && duration > 0)
				living_target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberdemon, multiplicative_slowdown = -(current_power / 100))
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_movespeed_modifier), WEAKREF(living_target)), duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s movement speed by [current_power]% for [DisplayTimeText(duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_INTERACTION_SPEED)
			var/mob/living/living_target = target
			if(istype(living_target) && duration > 0)
				living_target.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/cyberdemon, multiplicative_slowdown = -(current_power / 100))
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberdemon_remove_actionspeed_modifier), WEAKREF(living_target)), duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] changes [target]'s interaction speed by [current_power]% for [DisplayTimeText(duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BLOCK_IMPLANTS)
			var/mob/living/living_target = target
			if(istype(living_target))
				var/block_duration = max(1 SECONDS, duration || (absolute_power SECONDS))
				living_target.cyberdemon_block_implants(block_duration)
				if(announce)
					to_chat(caster, span_notice("[demon_name] blocks [target]'s active implant channels for [DisplayTimeText(block_duration)]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF)
			if(announce)
				to_chat(caster, span_notice("[demon_name] applies a temporary [effect] with power [current_power] for [round(duration / 10)] seconds."))
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
	if(!caster || !origin)
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
		to_chat(caster, span_notice("[demon_name] jumps through [jumps] extra target[jumps == 1 ? "" : "s"]."))

/datum/cyberspace_demon/proc/apply_spread_effect(datum/weakref/caster_ref, datum/weakref/origin_ref, current_power, physical_world)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/origin = origin_ref?.resolve()
	if(!caster || !origin)
		return FALSE
	var/list/excluded = list(origin, caster)
	var/atom/next_target = find_secondary_effect_target(caster, origin, excluded)
	if(!next_target)
		return FALSE
	if(apply_primary_effect(caster, next_target, current_power, physical_world, FALSE))
		to_chat(caster, span_notice("[demon_name] spreads from [origin] to [next_target]."))
		return TRUE
	return FALSE

/datum/cyberspace_demon/proc/apply_repeat_effect(datum/weakref/caster_ref, datum/weakref/origin_ref, current_power, physical_world, repeats_left)
	var/mob/living/caster = caster_ref?.resolve()
	var/atom/origin = origin_ref?.resolve()
	if(!caster || !origin || repeats_left <= 0)
		return FALSE
	var/atom/repeat_target = origin
	if(CYBER_DEMON_SPECIAL_JUMP in special_effects)
		repeat_target = find_secondary_effect_target(caster, origin, list(caster))
	if(!repeat_target)
		return FALSE
	if(apply_primary_effect(caster, repeat_target, current_power, physical_world, FALSE))
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
	switch(effect)
		if(CYBER_DEMON_EFFECT_DAMAGE, CYBER_DEMON_EFFECT_BURN, CYBER_DEMON_EFFECT_ACID, CYBER_DEMON_EFFECT_TOX, CYBER_DEMON_EFFECT_OVERHEAT, CYBER_DEMON_EFFECT_OVERHEAT_DELTA, CYBER_DEMON_EFFECT_PROTECTION)
			return istype(candidate, /mob/living) || istype(candidate, /obj/effect/cyberspace_wall_shell) || istype(candidate, /obj/effect/cyberspace_node_shell) || istype(candidate, /obj/effect/cyberspace_object_trace)
		if(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF, CYBER_DEMON_EFFECT_ATTRIBUTE, CYBER_DEMON_EFFECT_SKILL, CYBER_DEMON_EFFECT_STAMINA, CYBER_DEMON_EFFECT_BLIND, CYBER_DEMON_EFFECT_DEAF, CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_IMPLANTS, CYBER_DEMON_EFFECT_BLOCK_DEMONS)
			return istype(candidate, /mob/living)
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
	effect = CYBER_DEMON_EFFECT_BUFF
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
	effect = CYBER_DEMON_EFFECT_BUFF
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
	effect = CYBER_DEMON_EFFECT_BLOCK_DEMONS
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
		"Нагрев электроники (HEAT)" = CYBER_DEMON_EFFECT_BURN,
		"Кислотный сбой (ACID)" = CYBER_DEMON_EFFECT_ACID,
		"Токсичный сбой имплантов" = CYBER_DEMON_EFFECT_TOX,
		"Перегрев имплантов" = CYBER_DEMON_EFFECT_OVERHEAT,
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
		"Стена" = CYBER_DEMON_EFFECT_WALL,
		"Скачок" = CYBER_DEMON_EFFECT_MOVEMENT,
	)

/proc/get_cyberdemon_special_choices()
	return list(
		"Массовость" = CYBER_DEMON_SPECIAL_MASS,
		"Распространяемость" = CYBER_DEMON_SPECIAL_SPREAD,
		"Прыжок" = CYBER_DEMON_SPECIAL_JUMP,
		"Повтор" = CYBER_DEMON_SPECIAL_REPEAT,
		"Стелс" = CYBER_DEMON_SPECIAL_STEALTH,
		"Слабый ЭМП по завершению" = CYBER_DEMON_SPECIAL_EMP_LIGHT,
		"Сильный ЭМП по завершению" = CYBER_DEMON_SPECIAL_EMP_HEAVY,
	)

/proc/get_cyberdemon_manufacturer_choices()
	return list(
		"Independent",
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
	if(effect_id in list(CYBER_DEMON_EFFECT_ATTRIBUTE, CYBER_DEMON_EFFECT_SKILL, CYBER_DEMON_EFFECT_MOVE_SPEED, CYBER_DEMON_EFFECT_INTERACTION_SPEED, CYBER_DEMON_EFFECT_BLIND, CYBER_DEMON_EFFECT_DEAF, CYBER_DEMON_EFFECT_SILENCE, CYBER_DEMON_EFFECT_BLOCK_IMPLANTS, CYBER_DEMON_EFFECT_BLOCK_DEMONS))
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

/proc/find_held_cyberdemon_disk(mob/user)
	if(!user)
		return null
	var/obj/item/cyberdemon_disk/disk = locate(/obj/item/cyberdemon_disk) in user.held_items
	if(!disk)
		disk = locate(/obj/item/cyberdemon_disk) in user.contents
	return disk

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
		var/disk_index = 1
		for(var/datum/cyberspace_demon/demon as anything in disk.demons)
			disk_demons += list(cyberdemon_to_ui_data(demon, disk_index++))

	return list(
		"net_data" = user?.mind?.cyber_net_data || 0,
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

/proc/delete_cyberdemon_from_list(list/demons, index, mob/user, source_name)
	index = text2num("[index]")
	if(index < 1 || index > length(demons))
		return FALSE
	var/datum/cyberspace_demon/demon = demons[index]
	if(!demon)
		return FALSE
	if(demon.prebuilt)
		to_chat(user, span_warning("Prebuilt demons cannot be deleted from [source_name]."))
		return FALSE
	demons.Cut(index, index + 1)
	to_chat(user, span_notice("You delete [demon.demon_name] from [source_name]."))
	qdel(demon)
	return TRUE

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
				delete_cyberdemon_from_list(deck.demons, params["index"], user, deck)
			return TRUE
		if("delete_disk")
			if(disk)
				delete_cyberdemon_from_list(disk.demons, params["index"], user, disk)
			return TRUE
		if("copy_to_disk")
			if(!deck || !disk)
				return TRUE
			var/index = text2num("[params["index"]]")
			if(index < 1 || index > length(deck.demons))
				return TRUE
			var/datum/cyberspace_demon/demon = deck.demons[index]
			if(demon?.prebuilt)
				to_chat(user, span_warning("Prebuilt demons cannot be copied to disk. Use the original demon disk."))
				return TRUE
			if(demon && disk.store_demon(demon.copy(), user))
				to_chat(user, span_notice("You copy [demon.demon_name] to [disk]."))
			return TRUE
		if("load_from_disk")
			if(!deck || !disk)
				return TRUE
			var/index = text2num("[params["index"]]")
			if(index < 1 || index > length(disk.demons))
				return TRUE
			var/datum/cyberspace_demon/demon = disk.demons[index]
			if(demon && deck.store_demon(demon.copy(), user))
				to_chat(user, span_notice("You load [demon.demon_name] from [disk] to [deck]."))
			return TRUE
	return FALSE

/obj/item/clothing/gloves/cyberdeck
	name = "cyberdeck gloves"
	desc = "A glove-mounted cyberdeck that stores and runs compiled demons."
	icon_state = "black"
	var/memory_capacity = CYBER_DECK_DEFAULT_MEMORY
	var/list/demons = list()
	var/compile_cooldown_until = 0
	var/obj/item/cyberdemon_disk/inserted_disk

/obj/item/clothing/gloves/cyberdeck/Destroy(force)
	QDEL_LIST(demons)
	QDEL_NULL(inserted_disk)
	return ..()

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
	return TRUE

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
	to_chat(user, span_notice("You delete [demon.demon_name] from [src]."))
	qdel(demon)
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
	return cyberdemon_storage_ui_data(src, inserted_disk || find_held_cyberdemon_disk(user), null, user)

/obj/item/clothing/gloves/cyberdeck/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, src, inserted_disk || find_held_cyberdemon_disk(ui.user), null)

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
	desc = "A stripped glove-mounted cyberdeck with minimal demon memory."
	memory_capacity = CYBER_DECK_MIN_MEMORY

/obj/item/clothing/gloves/cyberdeck/advanced
	name = "advanced cyberdeck gloves"
	desc = "A high-grade glove-mounted cyberdeck with expanded demon memory."
	memory_capacity = CYBER_DECK_MAX_MEMORY

/obj/item/cyberdemon_disk
	name = "demon disk"
	desc = "A removable storage disk for compiled demons."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_SMALL
	var/memory_capacity = CYBER_DEMON_DISK_MEMORY
	var/list/demons = list()

/obj/item/cyberdemon_disk/Destroy(force)
	QDEL_LIST(demons)
	return ..()

/obj/item/cyberdemon_disk/proc/get_used_memory()
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
	demons += demon
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
		demons += new demon_type

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
	QDEL_LIST(demons)
	var/list/catalog = get_cyberdemon_catalog()
	for(var/demon_name in catalog)
		var/demon_type = catalog[demon_name]
		demons += new demon_type

/obj/item/cyberdemon_disk/proc/choose_demon(mob/user)
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
	if(!.)
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
	return cyberdemon_storage_ui_data(find_held_cyberdeck(user), inserted_disk || find_held_cyberdemon_disk(user), src, user)

/obj/machinery/cyberdemon_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, find_held_cyberdeck(ui.user), inserted_disk || find_held_cyberdemon_disk(ui.user), src)

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
	return cyberdemon_storage_ui_data(find_held_cyberdeck(user), find_held_cyberdemon_disk(user), null, user, TRUE, "temporary IC compiler", 0)

/datum/cyberdemon_debug_compiler/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, find_held_cyberdeck(ui.user), find_held_cyberdemon_disk(ui.user), null)
