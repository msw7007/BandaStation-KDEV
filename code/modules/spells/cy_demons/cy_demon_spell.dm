/datum/action/cooldown/spell/pointed/cy_demon
	name = "Demon"
	desc = "Compile and run a modular demon."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"
	background_icon_state = "bg_spell"
	spell_requirements = SPELL_REQUIRES_MIND
	invocation_type = INVOCATION_NONE
	cast_range = CY_DEMON_DEFAULT_PHYSICAL_RANGE
	cooldown_time = CY_DEMON_DEFAULT_COOLDOWN
	active_msg = "You ready a demon."
	deactive_msg = "You dismiss the demon."

	var/datum/cy_demon/loaded_demon

/datum/action/cooldown/spell/pointed/cy_demon/Destroy()
	loaded_demon = null
	return ..()

/datum/action/cooldown/spell/pointed/cy_demon/proc/set_demon(datum/cy_demon/new_demon)
	loaded_demon = new_demon
	if(!loaded_demon)
		return FALSE
	name = loaded_demon.name
	desc = loaded_demon.desc
	cast_range = max(loaded_demon.physical_range, loaded_demon.net_range)
	cooldown_time = loaded_demon.cooldown_time
	active_msg = "You ready [loaded_demon.name]."
	deactive_msg = "You dismiss [loaded_demon.name]."
	build_all_button_icons()
	return TRUE

/datum/action/cooldown/spell/pointed/cy_demon/is_valid_target(atom/cast_on)
	if(!loaded_demon)
		return FALSE
	if(cast_on == owner)
		return TRUE
	return TRUE

/datum/action/cooldown/spell/pointed/cy_demon/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(!loaded_demon)
		return . | SPELL_CANCEL_CAST
	if(!loaded_demon.can_cast(owner, cast_on, owner))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cy_demon/cast(atom/cast_on)
	. = ..()
	if(!loaded_demon)
		return FALSE
	loaded_demon.start_cast(owner, cast_on, owner)
	unset_click_ability(owner, refund_cooldown = FALSE)
	return TRUE

/mob/living/proc/cy_grant_demon_spell(datum/cy_demon/demon)
	if(!demon)
		return null
	return demon.grant_as_spell(src)

/mob/living/proc/cy_grant_default_demon_spells()
	for(var/datum/cy_demon/demon as anything in cy_collect_demons())
		cy_grant_demon_spell(demon)
