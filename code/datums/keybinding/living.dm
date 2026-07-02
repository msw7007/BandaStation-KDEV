/datum/keybinding/living
	category = CATEGORY_HUMAN
	weight = WEIGHT_MOB

/datum/keybinding/living/can_use(client/user)
	return isliving(user.mob)

/datum/keybinding/living/resist
	hotkey_keys = list("B")
	name = "resist"
	full_name = "Сопротивляться"
	description = "Освободиться от текущего состояния. В наручниках? Вы горите? Сопротивляйтесь!"
	keybind_signal = COMSIG_KB_LIVING_RESIST_DOWN

/datum/keybinding/living/resist/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/owner = user.mob
	owner.resist()
	if (owner.hud_used?.screen_objects[HUD_MOB_RESIST])
		owner.hud_used.screen_objects[HUD_MOB_RESIST].icon_state = "[owner.hud_used.screen_objects[HUD_MOB_RESIST].base_icon_state]_on"
	return TRUE

/datum/keybinding/living/resist/up(client/user, turf/target)
	. = ..()
	if(.)
		return
	var/mob/living/owner = user.mob
	if (owner.hud_used?.screen_objects[HUD_MOB_RESIST])
		owner.hud_used.screen_objects[HUD_MOB_RESIST].icon_state = owner.hud_used.screen_objects[HUD_MOB_RESIST].base_icon_state

/datum/keybinding/living/look_up
	hotkey_keys = list("P") // BANDASTATION EDIT
	name = "look up"
	full_name = "Посмотреть вверх"
	description = "Посмотреть на нижний Z-уровень. Возможно только если над вами свободное пространство."
	keybind_signal = COMSIG_KB_LIVING_LOOKUP_DOWN

/datum/keybinding/living/look_up/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/L = user.mob
	L.look_up()
	return TRUE

/datum/keybinding/living/look_up/up(client/user, turf/target)
	. = ..()
	var/mob/living/L = user.mob
	L.end_look()
	return TRUE

/datum/keybinding/living/look_down
	hotkey_keys = list(";")
	name = "look down"
	full_name = "Посмотреть вниз"
	description = "Посмотреть на нижний Z-уровень. Возможно только если под вами его видно."
	keybind_signal = COMSIG_KB_LIVING_LOOKDOWN_DOWN

/datum/keybinding/living/look_down/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/L = user.mob
	L.look_down()
	return TRUE

/datum/keybinding/living/look_down/up(client/user, turf/target)
	. = ..()
	var/mob/living/L = user.mob
	L.end_look()
	return TRUE

/datum/keybinding/living/rest
	hotkey_keys = list("ShiftB") // BANDASTATION EDIT
	name = "rest"
	full_name = "Лечь/встать"
	description = "Нажмите, чтобы лечь или встать"
	keybind_signal = COMSIG_KB_LIVING_REST_DOWN

/datum/keybinding/living/rest/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_mob = user.mob
	living_mob.toggle_resting()
	return TRUE

/datum/keybinding/living/toggle_combat_mode
	hotkey_keys = list("F")
	name = "toggle_combat_mode"
	full_name = "Переключить Combat Mode"
	description = "Переключает боевой режим. Это как Помощь/Вред, но круче"
	keybind_signal = COMSIG_KB_LIVING_TOGGLE_COMBAT_DOWN


/datum/keybinding/living/toggle_combat_mode/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.set_combat_mode(!user_mob.combat_mode, FALSE)

/datum/keybinding/living/enable_combat_mode
	hotkey_keys = list("4")
	name = "enable_combat_mode"
	full_name = "Включить Combat Mode"
	description = "Включает боевой режим"
	keybind_signal = COMSIG_KB_LIVING_ENABLE_COMBAT_DOWN

/datum/keybinding/living/enable_combat_mode/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.set_combat_mode(TRUE, silent = FALSE)

/datum/keybinding/living/disable_combat_mode
	hotkey_keys = list("1")
	name = "disable_combat_mode"
	full_name = "Отключить Combat Mode"
	description = "Отключает боевой режим"
	keybind_signal = COMSIG_KB_LIVING_DISABLE_COMBAT_DOWN

/datum/keybinding/living/disable_combat_mode/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.set_combat_mode(FALSE, silent = FALSE)

/datum/keybinding/living/cyberpunk_slash_intent
	hotkey_keys = list("2")
	name = "cyberpunk_slash_intent"
	full_name = "Slash Intent"
	description = "Switches to slash intent."
	keybind_signal = "keybinding_living_cyberpunk_slash_intent_down"

/datum/keybinding/living/cyberpunk_slash_intent/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.set_cyberpunk_combat_intent("slash")
	return TRUE

/datum/keybinding/living/cyberpunk_stab_intent
	hotkey_keys = list("3")
	name = "cyberpunk_stab_intent"
	full_name = "Stab Intent"
	description = "Switches to stab intent."
	keybind_signal = "keybinding_living_cyberpunk_stab_intent_down"

/datum/keybinding/living/cyberpunk_stab_intent/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.set_cyberpunk_combat_intent("stab")
	return TRUE

/datum/keybinding/living/cyberpunk_toggle_stealth
	hotkey_keys = list("ShiftC")
	name = "cyberpunk_toggle_stealth"
	full_name = "Toggle Stealth"
	description = "Toggle stealth mode."
	keybind_signal = "keybinding_living_cyberpunk_toggle_stealth_down"

/datum/keybinding/living/cyberpunk_toggle_stealth/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.toggle_stealth_mode()
	return TRUE

/datum/keybinding/living/cyberpunk_jump
	hotkey_keys = list("ShiftJ")
	name = "cyberpunk_jump"
	full_name = "Jump"
	description = "Jump forward."
	keybind_signal = "keybinding_living_cyberpunk_jump_down"

/datum/keybinding/living/cyberpunk_jump/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/user_mob = user.mob
	user_mob.try_jump_forward()
	return TRUE

/datum/keybinding/living/toggle_move_intent
	hotkey_keys = list("Shift") // BANDASTATION EDIT
	name = "toggle_move_intent"
	full_name = "Смена режима ходьбы (зажать)"
	description = "Удерживайте, чтобы временно поменять режим передвижения."
	keybind_signal = COMSIG_KB_LIVING_TOGGLEMOVEINTENT_DOWN

/datum/keybinding/living/toggle_move_intent/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/M = user.mob
	M.toggle_move_intent()
	return TRUE

/datum/keybinding/living/toggle_move_intent/up(client/user, turf/target)
	. = ..()
	var/mob/living/M = user.mob
	M.toggle_move_intent()
	return TRUE

/datum/keybinding/living/toggle_move_intent_alternative
	hotkey_keys = list(UNBOUND_KEY)
	name = "toggle_move_intent_alt"
	full_name = "Смена режима ходьбы (переключить)"
	description = "Нажмите, чтобы поменять режим передвижения."
	keybind_signal = COMSIG_KB_LIVING_TOGGLEMOVEINTENTALT_DOWN

/datum/keybinding/living/toggle_move_intent_alternative/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/M = user.mob
	M.toggle_move_intent()
	return TRUE

/datum/keybinding/living/toggle_throw_mode
	hotkey_keys = list("R", "Southwest") // END
	name = "toggle_throw_mode"
	full_name = "Режим броска (переключить)"
	description = "Переключает будете ли вы бросать текущий предмет"
	keybind_signal = COMSIG_KB_LIVING_TOGGLETHROWMODE_DOWN

/datum/keybinding/living/toggle_throw_mode/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.toggle_throw_mode()
	return TRUE

/datum/keybinding/living/hold_throw_mode
	hotkey_keys = list(UNBOUND_KEY)
	name = "hold_throw_mode"
	full_name = "Режим броска (зажать)"
	description = "Удерживайте, чтобы включить режим броска, и отпустите, чтобы выключить его"
	keybind_signal = COMSIG_KB_LIVING_HOLDTHROWMODE_DOWN

/datum/keybinding/living/hold_throw_mode/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.throw_mode_on(THROW_MODE_HOLD)

/datum/keybinding/living/hold_throw_mode/up(client/user, turf/target)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.throw_mode_off(THROW_MODE_HOLD)

/datum/keybinding/living/cyberpunk_defensive_action
	hotkey_keys = list("Space")
	name = "cyberpunk_defensive_action"
	full_name = "Defensive Action"
	description = "Repeats the last defensive action. Hold and click to choose parry or dodge."
	keybind_signal = "keybinding_living_cyberpunk_defensive_down"

/datum/keybinding/living/cyberpunk_defensive_action/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	if(living_user.cyberpunk_defensive_action_held)
		return TRUE
	living_user.cyberpunk_defensive_action_held = TRUE
	living_user.cyberpunk_defensive_action_clicked = FALSE
	return TRUE

/datum/keybinding/living/cyberpunk_defensive_action/up(client/user, turf/target)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	var/repeat_last_action = living_user.cyberpunk_defensive_action_held && !living_user.cyberpunk_defensive_action_clicked
	living_user.cyberpunk_defensive_action_held = FALSE
	living_user.cyberpunk_defensive_action_clicked = FALSE
	if(repeat_last_action)
		living_user.perform_cyberpunk_defensive_action()
	return TRUE

/datum/keybinding/living/cyberpunk_surrender
	hotkey_keys = list("AltShiftH", "ShiftAltH")
	name = "cyberpunk_surrender"
	full_name = "Surrender"
	description = "Surrender."
	keybind_signal = "keybinding_living_cyberpunk_surrender_down"

/datum/keybinding/living/cyberpunk_surrender/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.emote("surrender")
	return TRUE

/datum/keybinding/living/give
	hotkey_keys = list(UNBOUND_KEY) // BANDASTATION EDIT
	name = "Give_Item"
	full_name = "Передать вещь"
	description = "Передать предмет в активной руке"
	keybind_signal = COMSIG_KB_LIVING_GIVEITEM_DOWN

/datum/keybinding/living/give/can_use(client/user)
	. = ..()
	if (!.)
		return FALSE
	if(!user.mob)
		return FALSE
	if(!HAS_TRAIT(user.mob, TRAIT_CAN_HOLD_ITEMS))
		return FALSE
	return TRUE

/datum/keybinding/living/give/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	if(!HAS_TRAIT(living_user, TRAIT_CAN_HOLD_ITEMS))
		return
	living_user.give()
