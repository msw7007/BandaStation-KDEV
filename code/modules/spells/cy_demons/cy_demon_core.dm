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
	var/net_data_cost = 0
	var/stealth = FALSE
	var/trace_on_prepare = 5
	var/trace_on_fire = 10
	var/list/block_keys = list()
	var/list/effect_keys = list()
	var/list/effect_values = list()
	var/list/modules = list()

/datum/cy_demon/New()
	. = ..()
	initialize_modules()
	rebuild_from_modules()

/datum/cy_demon/Destroy()
	QDEL_LIST(modules)
	block_keys = null
	effect_keys = null
	effect_values = null
	return ..()

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
	for(var/datum/cy_demon_module/module as anything in modules)
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
	var/datum/cy_demon_cast/cast = new(src, context)
	SScy_demons.start_cast(cast)
	if(!context.silent)
		to_chat(caster, span_notice("You begin compiling [name]."))
	return TRUE

/datum/cy_demon/proc/apply_effect(datum/cy_demon_context/context)
	var/success = FALSE
	for(var/datum/cy_demon_module/module as anything in modules)
		if(module.apply_effect(context, src))
			success = TRUE
	return success

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

/mob/living/proc/cy_ensure_demon_list()
	if(!cy_known_demons)
		cy_known_demons = list()
		cy_known_demons += new /datum/cy_demon/breach
		cy_known_demons += new /datum/cy_demon/ping
		cy_known_demons += new /datum/cy_demon/wall
	return cy_known_demons

/mob/living/proc/cy_collect_demons()
	return cy_ensure_demon_list()

/mob/living/proc/cy_store_demon(datum/cy_demon/demon)
	if(!demon)
		return FALSE
	cy_ensure_demon_list()
	cy_known_demons += demon
	return TRUE
