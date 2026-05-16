/datum/cy_demon_context
	var/mob/living/caster
	var/atom/source
	var/atom/target
	var/datum/cy_demon/demon
	var/context_type = CY_DEMON_CONTEXT_PHYSICAL
	var/target_context_type = CY_DEMON_CONTEXT_PHYSICAL
	var/distance = 0
	var/power_mult = 1
	var/prep_mult = 1
	var/range_mult = 1
	var/trace_mult = 1
	var/silent = FALSE

	/// Optional digital target interface. Filled by demon target resolver, not by netspace.
	var/has_digital_source = FALSE
	var/has_digital_target = FALSE

/datum/cy_demon_context/Destroy()
	caster = null
	source = null
	target = null
	demon = null
	return ..()

/datum/cy_demon_context/proc/is_netspace()
	return context_type == CY_DEMON_CONTEXT_NETSPACE || target_context_type == CY_DEMON_CONTEXT_NETSPACE

/datum/cy_demon_context/proc/get_cast_range()
	if(is_netspace())
		return round(demon.net_range * range_mult)
	return round(demon.physical_range * range_mult)

/datum/cy_demon_context/proc/resolve_base()
	if(!caster || !target)
		return FALSE
	source ||= caster
	distance = get_dist(get_turf(source), get_turf(target))
	return TRUE

/proc/cy_build_demon_context(mob/living/caster, atom/target, datum/cy_demon/demon, atom/source)
	var/datum/cy_demon_context/context = new
	context.caster = caster
	context.target = target
	context.demon = demon
	context.source = source || caster
	if(!context.resolve_base())
		qdel(context)
		return null
	context.resolve_target_interface()
	return context

/datum/cy_demon
	var/name = "Demon"
	var/desc = "A modular active program."
	var/id = "demon"
	var/power = CY_DEMON_DEFAULT_POWER
	var/physical_range = CY_DEMON_DEFAULT_PHYSICAL_RANGE
	var/net_range = CY_DEMON_DEFAULT_NET_RANGE
	var/prep_time = CY_DEMON_DEFAULT_PREP_TIME
	var/cooldown_time = CY_DEMON_DEFAULT_COOLDOWN
	var/duration = 0
	var/memory_cost = 1
	var/premade = FALSE
	var/list/special_effects = list()
	var/net_data_cost = 0
	var/stealth = FALSE
	var/trace_on_prepare = 5
	var/trace_on_fire = 10
	var/list/block_keys = list()
	var/list/effect_keys = list()
	var/list/effect_values = list()
	var/list/modules = list()
	var/base_power
	var/base_physical_range
	var/base_net_range
	var/base_prep_time
	var/base_cooldown_time
	var/base_memory_cost
	var/base_stealth
	var/base_trace_on_prepare
	var/base_trace_on_fire
	var/list/base_effect_values = list()

/datum/cy_demon/New()
	. = ..()
	cache_base_values()
	initialize_modules()
	rebuild_from_modules()

/datum/cy_demon/Destroy()
	QDEL_LIST(modules)
	block_keys = null
	effect_keys = null
	effect_values = null
	base_effect_values = null
	return ..()

/datum/cy_demon/proc/cache_base_values()
	base_power = power
	base_physical_range = physical_range
	base_net_range = net_range
	base_prep_time = prep_time
	base_cooldown_time = cooldown_time
	base_memory_cost = memory_cost
	base_stealth = stealth
	base_trace_on_prepare = trace_on_prepare
	base_trace_on_fire = trace_on_fire
	base_effect_values = effect_values ? effect_values.Copy() : list()

/datum/cy_demon/proc/initialize_modules()
	return

/datum/cy_demon/proc/add_module(datum/cy_demon_module/module)
	if(!module)
		return FALSE
	modules += module
	module.owner = src
	rebuild_from_modules()
	return TRUE

/datum/cy_demon/proc/remove_module(datum/cy_demon_module/module)
	if(!module || !(module in modules))
		return FALSE
	modules -= module
	module.owner = null
	rebuild_from_modules()
	return TRUE

/datum/cy_demon/proc/rebuild_from_modules()
	power = base_power
	physical_range = base_physical_range
	net_range = base_net_range
	prep_time = base_prep_time
	cooldown_time = base_cooldown_time
	memory_cost = base_memory_cost
	stealth = base_stealth
	trace_on_prepare = base_trace_on_prepare
	trace_on_fire = base_trace_on_fire
	effect_values = base_effect_values ? base_effect_values.Copy() : list()
	for(var/datum/cy_demon_module/module as anything in modules)
		module.owner = src
		module.apply_passive(src)

/datum/cy_demon/proc/get_effect_value(key, default_value = 0)
	if(!effect_values || isnull(effect_values[key]))
		return default_value
	return effect_values[key]

/datum/cy_demon/proc/can_cast(mob/living/caster, atom/target, atom/source)
	var/datum/cy_demon_context/context = cy_build_demon_context(caster, target, src, source)
	if(!context)
		return FALSE
	. = can_cast_context(context, TRUE)
	qdel(context)

/datum/cy_demon/proc/get_memory_cost()
	return max(1, memory_cost)

/datum/cy_demon/proc/can_compile(feedback_to = null)
	if(!premade && get_memory_cost() > CY_DEMON_MAX_COMPILED_MEMORY)
		if(feedback_to)
			to_chat(feedback_to, span_warning("[name] exceeds the 8 MU compiled demon limit."))
		return FALSE
	if(length(special_effects) > CY_DEMON_SPECIAL_MAX)
		if(feedback_to)
			to_chat(feedback_to, span_warning("[name] has too many special effects."))
		return FALSE
	return TRUE

/datum/cy_demon/proc/can_cast_context(datum/cy_demon_context/context, feedback = TRUE)
	if(!context?.caster || !context.target)
		return FALSE
	if(context.distance > context.get_cast_range())
		if(feedback)
			to_chat(context.caster, span_warning("[name] cannot reach that far."))
		return FALSE
	for(var/datum/cy_demon_module/module as anything in modules)
		if(!module.can_apply(context, src, feedback))
			return FALSE
	return TRUE

/datum/cy_demon/proc/start_cast(mob/living/caster, atom/target, atom/source)
	var/datum/cy_demon_context/context = cy_build_demon_context(caster, target, src, source)
	if(!context)
		return FALSE
	if(!can_cast_context(context, TRUE))
		qdel(context)
		return FALSE
	if(hascall(caster, "adjust_psychic_loss"))
		caster.adjust_psychic_loss(max(1, round(get_memory_cost() * 0.5)))
	var/datum/cy_demon_cast/cast = new(src, context)
	SScy_demons.start_cast(cast)
	if(!context.silent)
		to_chat(caster, span_notice("You begin compiling [name]."))
	return TRUE

/datum/cy_demon/proc/apply_effect(datum/cy_demon_context/context)
	var/success = FALSE
	var/list/targets = cy_collect_effect_targets(context)
	for(var/atom/effect_target as anything in targets)
		var/atom/original_target = context.target
		context.target = effect_target
		for(var/datum/cy_demon_module/module as anything in modules)
			if(module.apply_effect(context, src))
				success = TRUE
		context.target = original_target
	return success

/datum/cy_demon/proc/cy_collect_effect_targets(datum/cy_demon_context/context)
	var/list/targets = list(context.target)
	if((CY_DEMON_SPECIAL_MASS in special_effects) || (CY_DEMON_SPECIAL_SPREAD in special_effects))
		var/spread_radius = (CY_DEMON_SPECIAL_MASS in special_effects) ? CY_DEMON_MASS_RADIUS : 1
		for(var/atom/nearby as anything in view(spread_radius, context.target))
			if(nearby == context.target)
				continue
			if(cy_call_bool(nearby, "cy_is_netspace_target"))
				targets |= nearby
	if(CY_DEMON_SPECIAL_JUMP in special_effects)
		var/jumps_left = 2
		var/atom/current = context.target
		while(jumps_left-- > 0)
			var/atom/next_target
			for(var/atom/nearby as anything in view(CY_DEMON_JUMP_RANGE, current))
				if(nearby in targets)
					continue
				if(cy_call_bool(nearby, "cy_is_netspace_target"))
					next_target = nearby
					break
			if(!next_target)
				break
			targets |= next_target
			current = next_target
	return targets

/datum/cy_demon/proc/grant_as_spell(mob/living/user)
	if(!user)
		return null
	var/datum/action/cooldown/spell/pointed/cy_demon/action = new(user)
	action.set_demon(src)
	action.Grant(user)
	return action

/datum/cy_demon_module
	var/name = "module"
	var/desc = "A demon module."
	var/module_type = CY_DEMON_MODULE_EFFECT
	var/datum/cy_demon/owner
	var/power_mod = 0
	var/physical_range_mod = 0
	var/net_range_mod = 0
	var/prep_time_mod = 0
	var/cooldown_mod = 0
	var/memory_mod = 0
	var/trace_prepare_mod = 0
	var/trace_fire_mod = 0
	var/list/effect_value_mods = list()

/datum/cy_demon_module/Destroy()
	owner = null
	effect_value_mods = null
	return ..()

/datum/cy_demon_module/proc/apply_passive(datum/cy_demon/demon)
	if(power_mod)
		demon.power += power_mod
	if(physical_range_mod)
		demon.physical_range += physical_range_mod
	if(net_range_mod)
		demon.net_range += net_range_mod
	if(prep_time_mod)
		demon.prep_time = max(0.2 SECONDS, demon.prep_time + prep_time_mod)
	if(cooldown_mod)
		demon.cooldown_time = max(0.2 SECONDS, demon.cooldown_time + cooldown_mod)
	if(memory_mod)
		demon.memory_cost = max(1, demon.memory_cost + memory_mod)
	if(trace_prepare_mod)
		demon.trace_on_prepare = max(0, demon.trace_on_prepare + trace_prepare_mod)
	if(trace_fire_mod)
		demon.trace_on_fire = max(0, demon.trace_on_fire + trace_fire_mod)
	for(var/key in effect_value_mods)
		demon.effect_values[key] = demon.get_effect_value(key, 0) + effect_value_mods[key]

/datum/cy_demon_module/proc/can_apply(datum/cy_demon_context/context, datum/cy_demon/demon, feedback = TRUE)
	return TRUE

/datum/cy_demon_module/proc/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	return FALSE

/datum/cy_demon_cast
	var/datum/cy_demon/demon
	var/datum/cy_demon_context/context
	var/progress = 0
	var/started_at = 0

/datum/cy_demon_cast/New(datum/cy_demon/new_demon, datum/cy_demon_context/new_context)
	. = ..()
	demon = new_demon
	context = new_context
	started_at = world.time
	if(demon && context && !demon.stealth)
		context.on_prepare()

/datum/cy_demon_cast/Destroy()
	SScy_demons?.stop_cast(src)
	demon = null
	QDEL_NULL(context)
	return ..()

/datum/cy_demon_cast/proc/process_cast(seconds_per_tick)
	if(!demon || !context || !context.caster || !context.target || QDELETED(context.caster) || QDELETED(context.target))
		qdel(src)
		return CY_DEMON_CAST_CANCELLED
	if(!demon.can_cast_context(context, FALSE))
		to_chat(context.caster, span_warning("[demon.name] loses target lock."))
		context.on_fail()
		qdel(src)
		return CY_DEMON_CAST_CANCELLED
	progress += seconds_per_tick * 10
	var/effective_prep_time = max(0.1 SECONDS, demon.prep_time * context.prep_mult)
	if(progress < effective_prep_time)
		return CY_DEMON_CAST_RUNNING
	var/success = demon.apply_effect(context)
	if(success)
		context.on_fire()
		if(!context.silent)
			to_chat(context.caster, span_notice("[demon.name] executes."))
	else
		context.on_fail()
		if(!context.silent)
			to_chat(context.caster, span_warning("[demon.name] fails."))
	qdel(src)
	return CY_DEMON_CAST_FINISHED

/mob/living
	var/list/cy_known_demons
	var/datum/cy_demon/cy_selected_demon
	var/datum/cy_demon/cy_prepared_demon
	var/obj/item/clothing/gloves/cyberdeck/cy_prepared_demon_deck
	var/datum/action/cooldown/spell/pointed/cy_demon/cy_prepared_demon_action
	var/obj/item/clothing/gloves/cyberdeck/cy_active_cyberdeck
	var/cy_net_data_bank = 0


/mob/living/proc/cy_get_demon_skill_level(skill_type)
	if(hascall(src, "get_cy_skill_level"))
		return get_cy_skill_level(skill_type)
	return 0

/mob/living/proc/cy_get_demon_power_multiplier()
	var/level = cy_get_demon_skill_level(/datum/cy_skill/intelligence/improved_code)
	switch(level)
		if(0)
			return 0.8
		if(2)
			return 1.3
		if(3)
			return 1.55
		if(5)
			return 1.75
		if(6 to INFINITY)
			return 2
	return 1

/mob/living/proc/cy_get_demon_prep_multiplier()
	var/level = cy_get_demon_skill_level(/datum/cy_skill/intelligence/fast_code)
	switch(level)
		if(0)
			return 1.1
		if(2)
			return 0.8
		if(3)
			return 0.56
		if(4)
			return 0.5
		if(6 to INFINITY)
			return 0.25
	return 1

/mob/living/proc/cy_get_demon_trace_multiplier()
	var/level = cy_get_demon_skill_level(/datum/cy_skill/intelligence/hacking)
	switch(level)
		if(0)
			return 1.1
		if(2)
			return 0.75
		if(5)
			return 0.5
		if(6 to INFINITY)
			return 0.35
	return 1

/mob/living/proc/cy_ensure_demon_list()
	if(!cy_known_demons)
		cy_known_demons = list()
		cy_known_demons += new /datum/cy_demon/breach
		cy_known_demons += new /datum/cy_demon/ping
		cy_known_demons += new /datum/cy_demon/wall
		cy_known_demons += new /datum/cy_demon/control
		cy_known_demons += new /datum/cy_demon/blind
		cy_known_demons += new /datum/cy_demon/pacify
		cy_known_demons += new /datum/cy_demon/short_circuit
	return cy_known_demons

/mob/living/proc/cy_collect_demons()
	var/obj/item/clothing/gloves/cyberdeck/deck = cy_get_active_cyberdeck()
	if(deck)
		return deck.stored_demons || list()
	return cy_ensure_demon_list()

/mob/living/proc/cy_store_demon(datum/cy_demon/demon)
	if(!demon)
		return FALSE
	cy_ensure_demon_list()
	cy_known_demons += demon
	return TRUE


/mob/living/proc/cy_get_net_data()
	return cy_net_data_bank

/mob/living/proc/cy_set_net_data(amount)
	cy_net_data_bank = max(0, amount)
	return TRUE

/mob/living/proc/cy_add_net_data(amount)
	cy_set_net_data(cy_get_net_data() + amount)
	return cy_get_net_data()

/mob/living/proc/cy_choose_demon()
	var/list/demons = cy_collect_demons()
	if(!length(demons))
		to_chat(src, span_warning("No demons are loaded."))
		return null
	var/list/choices = list()
	for(var/datum/cy_demon/demon as anything in demons)
		if(!demon)
			continue
		choices["[demon.name] ([demon.id])"] = demon
	var/chosen = tgui_input_list(src, "Select demon", "Demons", choices)
	if(!chosen)
		return null
	return choices[chosen]

/mob/living/proc/cy_select_demon(datum/cy_demon/demon)
	if(!demon)
		demon = cy_choose_demon()
	if(!demon)
		return FALSE
	cy_selected_demon = demon
	to_chat(src, span_notice("Selected demon: [demon.name]."))
	return TRUE

/mob/living/verb/select_cy_demon()
	set name = "Select Demon"
	set category = "Netspace"
	cy_select_demon()

/mob/living/proc/cy_get_active_cyberdeck()
	if(cy_active_cyberdeck && !QDELETED(cy_active_cyberdeck))
		return cy_active_cyberdeck
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		var/obj/item/clothing/gloves/cyberdeck/deck = H.get_item_by_slot(ITEM_SLOT_GLOVES)
		if(istype(deck))
			cy_active_cyberdeck = deck
			return deck
	return null

/mob/living/proc/cy_prepare_demon(datum/cy_demon/demon, datum/action/cooldown/spell/pointed/cy_demon/action_source = null)
	if(!demon)
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = cy_get_active_cyberdeck()
	if(deck && deck.is_compile_locked())
		to_chat(src, span_warning("[deck] is cooling down and cannot run demons."))
		return FALSE
	if(!deck)
		to_chat(src, span_warning("You need an equipped cyberdeck to prepare demons."))
		return FALSE
	if(!(demon in deck.stored_demons))
		to_chat(src, span_warning("[demon.name] is not loaded into your cyberdeck."))
		return FALSE
	cy_prepared_demon = demon
	cy_prepared_demon_deck = deck
	cy_prepared_demon_action = action_source
	to_chat(src, span_notice("Prepared demon: [demon.name]. Middle-click a target to run it."))
	return TRUE

/mob/living/proc/cy_clear_prepared_demon()
	cy_prepared_demon = null
	cy_prepared_demon_deck = null
	cy_prepared_demon_action = null
	return TRUE

/mob/living/proc/cy_fire_prepared_demon(atom/target)
	if(!cy_prepared_demon)
		to_chat(src, span_warning("Prepare a demon ability first."))
		return FALSE
	var/obj/item/clothing/gloves/cyberdeck/deck = cy_get_active_cyberdeck()
	if(deck && deck.is_compile_locked())
		to_chat(src, span_warning("[deck] is cooling down and cannot run demons."))
		cy_clear_prepared_demon()
		return FALSE
	if(!deck || (cy_prepared_demon_deck && cy_prepared_demon_deck != deck))
		to_chat(src, span_warning("You need the same equipped cyberdeck to run the prepared demon."))
		cy_clear_prepared_demon()
		return FALSE
	if(!cy_can_use_demon_on(target, cy_prepared_demon))
		return FALSE
	var/datum/cy_demon/fired_demon = cy_prepared_demon
	var/datum/action/cooldown/spell/pointed/cy_demon/fired_action = cy_prepared_demon_action
	var/success = fired_demon.start_cast(src, target, deck)
	if(success && fired_action)
		fired_action.StartCooldown()
	cy_clear_prepared_demon()
	return success

/mob/living/proc/cy_can_use_demon_on(atom/target, datum/cy_demon/demon)
	if(!target || !demon)
		return FALSE
	return TRUE


/datum/cy_demon/reaper
	name = "Reaper"
	desc = "A rare demon that cuts an engram from its carrier."
	id = "reaper"
	memory_cost = 6
	power = 5
	prep_time = 4 SECONDS
	effect_values = list("duration" = 0)

/datum/cy_demon/reaper/initialize_modules()
	modules += new /datum/cy_demon_module/effect/reaper

/datum/cy_demon/collector
	name = "Collector"
	desc = "A rare demon that binds an engram to a prepared carrier."
	id = "collector"
	memory_cost = 6
	power = 5
	prep_time = 4 SECONDS

/datum/cy_demon/collector/initialize_modules()
	modules += new /datum/cy_demon_module/effect/collector

/datum/cy_demon_module/effect/reaper
	name = "reaper payload"

/datum/cy_demon_module/effect/reaper/can_apply(datum/cy_demon_context/context, datum/cy_demon/demon, feedback = TRUE)
	if(!istype(context.target, /mob/living/net_avatar))
		if(feedback)
			to_chat(context.caster, span_warning("Reaper requires an engram target."))
		return FALSE
	var/mob/living/net_avatar/avatar = context.target
	return avatar.avatar_mode == CY_NET_AVATAR_ENGRAM

/datum/cy_demon_module/effect/reaper/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	var/mob/living/net_avatar/avatar = context.target
	avatar.cy_unbind_engram("Your carrier link is severed.")
	return TRUE

/datum/cy_demon_module/effect/collector
	name = "collector payload"

/datum/cy_demon_module/effect/collector/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	if(!istype(context.target, /mob/living/net_avatar))
		return FALSE
	var/mob/living/net_avatar/avatar = context.target
	avatar.cy_bind_engram(context.source || context.caster, "Binding code hooks into your engram.")
	to_chat(context.caster, span_notice("Collector latches binding code onto [context.target]."))
	return TRUE
