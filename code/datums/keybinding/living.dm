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

/datum/keybinding/living/toggle_move_intent
	hotkey_keys = list("Unbound") // BANDASTATION EDIT
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
	living_user.cy_defense_hold = TRUE
	living_user.cy_defense_hold_used = FALSE
	return TRUE

/datum/keybinding/living/hold_throw_mode/up(client/user, turf/target)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	if(living_user.cy_defense_hold && !living_user.cy_defense_hold_used)
		living_user.perform_cy_defense_action()
	living_user.cy_defense_hold = FALSE
	living_user.cy_defense_hold_used = FALSE
	return TRUE


/datum/keybinding/living/toggle_cy_sprint
	hotkey_keys = list("V")
	name = "toggle_cy_sprint"
	full_name = "Спринт"
	description = "Переключает спринт. Спринт ускоряет движение, но расходует запас сил."
	keybind_signal = COMSIG_KB_LIVING_TOGGLE_SPRINT_DOWN

/datum/keybinding/living/toggle_cy_sprint/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.toggle_cy_sprint()
	return TRUE

/datum/keybinding/living/toggle_cy_parkour
	hotkey_keys = list("G")
	name = "toggle_cy_parkour"
	full_name = "Паркур"
	description = "Включает режим паркура на одно действие: прыжок, зацеп, подъём или спуск."
	keybind_signal = COMSIG_KB_LIVING_PARKOUR_DOWN

/datum/keybinding/living/toggle_cy_parkour/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.toggle_cy_parkour_mode()
	return TRUE

/datum/keybinding/living/give
	hotkey_keys = list(UNBOUND_KEY) // BANDASTATION EDIT - V is CP sprint
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


/datum/keybinding/living/defensive_hold
	hotkey_keys = list("Space")
	name = "defensive_hold"
	full_name = "Защитное действие (зажать)"
	description = "Удерживайте для защитных кликов: Space+ЛКМ — парирование, Space+ПКМ — уклонение. Нажатие повторяет последнее защитное действие."
	keybind_signal = COMSIG_KB_LIVING_DEFENSIVE_HOLD_DOWN

/datum/keybinding/living/defensive_hold/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.cy_defense_hold = TRUE
	living_user.perform_cy_defense_action(living_user.cy_last_defense_action, target)
	return TRUE

/datum/keybinding/living/defensive_hold/up(client/user, turf/target)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.cy_defense_hold = FALSE
	return TRUE

/datum/keybinding/living/toggle_cy_stealth
	hotkey_keys = list("ShiftC")
	name = "toggle_cy_stealth"
	full_name = "Скрытый режим"
	description = "Переключает скрытый режим."
	keybind_signal = COMSIG_KB_LIVING_TOGGLE_STEALTH_DOWN

/datum/keybinding/living/toggle_cy_stealth/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	if(!istype(living_user))
		return FALSE
	var/enabled = living_user.cy_stealth_mode ? FALSE : TRUE
	living_user.set_cy_stealth_mode(enabled)
	var/message = living_user.cy_stealth_mode ? "Вы переходите в скрытый режим." : "Вы выходите из скрытого режима."
	to_chat(living_user, span_notice(message))
	return TRUE

/datum/keybinding/living/surrender
	hotkey_keys = list("ShiftH")
	name = "surrender"
	full_name = "Сдаться"
	description = "Сдаться."
	keybind_signal = COMSIG_KB_LIVING_SURRENDER_DOWN

/datum/keybinding/living/surrender/down(client/user, turf/target, mousepos_x, mousepos_y)
	. = ..()
	if(.)
		return
	var/mob/living/living_user = user.mob
	living_user.visible_message(span_notice("[capitalize(living_user.declent_ru(NOMINATIVE))] сдаётся."), span_notice("Вы сдаётесь."))
	living_user.emote("surrender")
	return TRUE
