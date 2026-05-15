/// Generic digital-target adapter for modular demons.
/// This file belongs to the demon/spell layer. Netspace does not call or own demons;
/// it only exposes neutral cy_* target procs on digital atoms.

/proc/cy_has_proc(datum/thing, proc_name)
	return thing && hascall(thing, proc_name)

/proc/cy_call_bool(datum/thing, proc_name, list/args = list())
	if(!cy_has_proc(thing, proc_name))
		return FALSE
	return call(thing, proc_name)(arglist(args))

/proc/cy_call_value(datum/thing, proc_name, list/args = list(), default_value = null)
	if(!cy_has_proc(thing, proc_name))
		return default_value
	return call(thing, proc_name)(arglist(args))

/datum/cy_demon_context/proc/resolve_target_interface()
	has_digital_source = cy_call_bool(source, "cy_is_netspace_actor") || cy_call_bool(caster, "cy_is_netspace_actor")
	has_digital_target = cy_call_bool(target, "cy_is_netspace_target")
	if(has_digital_source)
		context_type = CY_DEMON_CONTEXT_NETSPACE
		power_mult *= 1.15
		prep_mult *= 0.75
		trace_mult *= 1.25
	if(has_digital_target)
		target_context_type = CY_DEMON_CONTEXT_NETSPACE
	return TRUE

/datum/cy_demon_context/proc/on_prepare()
	if(demon?.stealth)
		return
	add_digital_trace(round(demon.trace_on_prepare * trace_mult), CY_DEMON_CAST_TRACE_PREPARE)

/datum/cy_demon_context/proc/on_fire()
	add_digital_trace(round(demon.trace_on_fire * trace_mult), CY_DEMON_CAST_TRACE_FIRE)

/datum/cy_demon_context/proc/on_fail()
	add_digital_trace(max(1, round((demon.trace_on_prepare * 0.5) * trace_mult)), CY_DEMON_CAST_TRACE_FAIL)

/datum/cy_demon_context/proc/add_digital_trace(amount, reason)
	if(amount <= 0)
		return FALSE
	var/success = FALSE
	if(cy_has_proc(source, "cy_add_netspace_trace"))
		cy_call_bool(source, "cy_add_netspace_trace", list(amount, caster, reason))
		success = TRUE
	if(cy_has_proc(caster, "cy_add_netspace_trace"))
		cy_call_bool(caster, "cy_add_netspace_trace", list(amount, target, reason))
		success = TRUE
	if(cy_has_proc(target, "cy_add_netspace_trace"))
		cy_call_bool(target, "cy_add_netspace_trace", list(amount, caster, reason))
		success = TRUE
	return success

/datum/cy_demon_context/proc/apply_digital_damage(amount, damage_type = CY_DEMON_EFFECT_BREACH)
	if(!target)
		return FALSE
	return cy_call_bool(target, "cy_apply_netspace_damage", list(amount, damage_type, caster))

/datum/cy_demon_context/proc/get_digital_status()
	if(!target)
		return null
	return cy_call_value(target, "cy_get_netspace_status", list(caster), null)

/datum/cy_demon_context/proc/get_digital_actions()
	if(!target)
		return list()
	var/list/actions = cy_call_value(target, "cy_get_netspace_actions", list(caster), list())
	return actions || list()

/datum/cy_demon_context/proc/execute_digital_action(action_id)
	if(!target || !action_id)
		return FALSE
	return cy_call_bool(target, "cy_execute_netspace_action", list(caster, action_id))
