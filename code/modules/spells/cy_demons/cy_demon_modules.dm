/datum/cy_demon/breach
	name = "Breach"
	desc = "A modular demon that tears down digital protection."
	id = "breach"
	power = 20
	prep_time = 1.5 SECONDS
	effect_values = list("damage" = 25)

/datum/cy_demon/breach/initialize_modules()
	modules += new /datum/cy_demon_module/effect/breach

/datum/cy_demon/ping
	name = "Ping"
	desc = "A stealthy query demon that reads a target shell or node."
	id = "ping"
	power = 5
	prep_time = 0.8 SECONDS
	trace_on_prepare = 1
	trace_on_fire = 2
	stealth = TRUE

/datum/cy_demon/ping/initialize_modules()
	modules += new /datum/cy_demon_module/effect/ping

/datum/cy_demon/wall
	name = "Compile Wall"
	desc = "A construction demon that compiles a defensive wall in netspace."
	id = "compile_wall"
	power = 10
	prep_time = 1.2 SECONDS
	net_range = 5
	effect_values = list("progress" = 35)

/datum/cy_demon/wall/initialize_modules()
	modules += new /datum/cy_demon_module/effect/net_wall

/datum/cy_demon/control
	name = "Control Spike"
	desc = "A control demon that forces a command through a node."
	id = "control_spike"
	power = 15
	prep_time = 2.5 SECONDS
	effect_values = list("security_damage" = 15)

/datum/cy_demon/control/initialize_modules()
	modules += new /datum/cy_demon_module/effect/control

/datum/cy_demon_module/effect
	module_type = CY_DEMON_MODULE_EFFECT

/datum/cy_demon_module/effect/breach
	name = "breach payload"
	desc = "Damages digital protection."

/datum/cy_demon_module/effect/breach/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	var/damage = round(demon.get_effect_value("damage", demon.power) * context.power_mult)
	return context.apply_digital_damage(damage, CY_DEMON_EFFECT_BREACH)

/datum/cy_demon_module/effect/ping
	name = "ping payload"
	desc = "Reads a digital target."

/datum/cy_demon_module/effect/ping/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	var/status = context.get_digital_status()
	if(status)
		to_chat(context.caster, span_notice(status))
		return TRUE
	to_chat(context.caster, span_notice("[context.target] has no readable digital shell."))
	return TRUE

/datum/cy_demon_module/effect/net_wall
	name = "wall compiler payload"
	desc = "Builds or strengthens a netspace wall."

/datum/cy_demon_module/effect/net_wall/can_apply(datum/cy_demon_context/context, datum/cy_demon/demon, feedback = TRUE)
	if(!context.is_netspace())
		if(feedback)
			to_chat(context.caster, span_warning("[demon.name] requires netspace."))
		return FALSE
	return TRUE

/datum/cy_demon_module/effect/net_wall/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	var/turf/T = get_turf(context.target)
	if(!T)
		return FALSE
	var/obj/structure/netspace/wall/existing
	for(var/obj/structure/netspace/wall/wall in T)
		existing = wall
		break
	var/progress = demon.get_effect_value("progress", 35)
	if(existing)
		existing.build_tick(progress)
	else
		new /obj/structure/netspace/wall(T, progress)
	return TRUE

/datum/cy_demon_module/effect/control
	name = "control payload"
	desc = "Forces one available command through a node."

/datum/cy_demon_module/effect/control/apply_effect(datum/cy_demon_context/context, datum/cy_demon/demon)
	var/security_damage = demon.get_effect_value("security_damage", 15)
	if(!context.apply_digital_damage(security_damage, CY_DEMON_EFFECT_CONTROL))
		return FALSE
	var/list/actions = context.get_digital_actions()
	if(length(actions))
		var/action = input(context.caster, "Force which node command?", demon.name) as null|anything in actions
		if(action)
			return context.execute_digital_action(action)
	return TRUE

/datum/cy_demon_module/modifier
	module_type = CY_DEMON_MODULE_MODIFIER

/datum/cy_demon_module/modifier/power_boost
	name = "power amplifier"
	power_mod = 5
	effect_value_mods = list("damage" = 5, "security_damage" = 5)

/datum/cy_demon_module/modifier/range_boost
	name = "range lens"
	physical_range_mod = 1
	net_range_mod = 2

/datum/cy_demon_module/modifier/speed_boost
	name = "fast compiler"
	prep_time_mod = -0.25 SECONDS
	cooldown_mod = 1 SECONDS

/datum/cy_demon_module/modifier/stealth_shell
	name = "stealth shell"
	trace_prepare_mod = -2
	trace_fire_mod = -3

/datum/cy_demon_module/modifier/stealth_shell/apply_passive(datum/cy_demon/demon)
	. = ..()
	demon.stealth = TRUE
