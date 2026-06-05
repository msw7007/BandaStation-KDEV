/**
 * Machines in the world, such as computers, pipes, and airlocks.
 *
 *Overview:
 *  Used to create objects that need a per step proc call.  Default definition of 'Initialize()'
 *  stores a reference to src machine in global 'machines list'.  Default definition
 *  of 'Destroy' removes reference to src machine in global 'machines list'.
 *
 *Class Variables:
 *  use_power (num)
 *     current state of auto power use.
 *     Possible Values:
 *        NO_POWER_USE -- no auto power use
 *        IDLE_POWER_USE -- machine is using power at its idle power level
 *        ACTIVE_POWER_USE -- machine is using power at its active power level
 *
 *  active_power_usage (num)
 *     Value for the amount of power to use when in active power mode
 *
 *  idle_power_usage (num)
 *     Value for the amount of power to use when in idle power mode
 *
 *  power_channel (num)
 *     What channel to draw from when drawing power for power mode
 *     Possible Values:
 *        AREA_USAGE_EQUIP:1 -- Equipment Channel
 *        AREA_USAGE_LIGHT:2 -- Lighting Channel
 *        AREA_USAGE_ENVIRON:3 -- Environment Channel
 *
 *  component_parts (list)
 *     A list of component parts of machine used by frame based machines.
 *
 *  stat (bitflag)
 *     Machine status bit flags.
 *     Possible bit flags:
 *        BROKEN -- Machine is broken
 *        NOPOWER -- No power is being supplied to machine.
 *        MAINT -- machine is currently under going maintenance.
 *        EMPED -- temporary broken by EMP pulse
 *
 *Class Procs:
 *  Initialize()
 *
 *  Destroy()
 *
 *	update_mode_power_usage()
 *		updates the static_power_usage var of this machine and makes its static power usage from its area accurate.
 *		called after the idle or active power usage has been changed.
 *
 *	update_power_channel()
 *		updates the static_power_usage var of this machine and makes its static power usage from its area accurate.
 *		called after the power_channel var has been changed or called to change the var itself.
 *
 *	unset_static_power()
 *		completely removes the current static power usage of this machine from its area.
 *		used in the other power updating procs to then readd the correct power usage.
 *
 *
 *     Default definition uses 'use_power', 'power_channel', 'active_power_usage',
 *     'idle_power_usage', 'powered()', and 'use_energy()' implement behavior.
 *
 *  powered(chan = -1)         'modules/power/power.dm'
 *     Checks to see if area that contains the object has power available for power
 *     channel given in 'chan'. -1 defaults to power_channel
 *
 *  use_energy(amount, chan=-1)   'modules/power/power.dm'
 *     Deducts 'amount' from the power channel 'chan' of the area that contains the object.
 *
 *  power_change()               'modules/power/power.dm'
 *     Called by the area that contains the object when ever that area under goes a
 *     power state change (area runs out of power, or area channel is turned off).
 *
 *  RefreshParts()               'game/machinery/machine.dm'
 *     Called to refresh the variables in the machine that are contributed to by parts
 *     contained in the component_parts list. (example: glass and material amounts for
 *     the autolathe)
 *
 *     Default definition does nothing.
 *
 *  process()                  'game/machinery/machine.dm'
 *     Called by the 'machinery subsystem' once per machinery tick for each machine that is listed in its 'machines' list.
 *
 *  process_atmos()
 *     Called by the 'air subsystem' once per atmos tick for each machine that is listed in its 'atmos_machines' list.
 * Compiled by Aygar
 */
//CYBERPUNK BUILD - rebuild and delete before release
#define CYBERPUNK_CRYPTO_KEY_LENGTH 20
#define CYBERPUNK_CRYPTO_COLUMNS 5
#define CYBERPUNK_CRYPTO_SEGMENT_LENGTH 4
#define CYBERPUNK_CRYPTO_OPTIONS 9
#define CYBERPUNK_CRYPTO_REVEAL_DELAY (10 SECONDS)
#define CYBERPUNK_CRYPTO_MIN_REVEAL_DELAY (3 SECONDS)
#define CYBERPUNK_CRYPTO_BYPASS_DURATION (30 SECONDS)
#define CYBERPUNK_CRYPTO_CHARSET "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"

/datum/cyberpunk_crypto_key
	var/name = "access key"
	var/owner = "independent"
	var/code

/datum/cyberpunk_crypto_key/New(key_name = null, key_owner = null, key_code = null)
	. = ..()
	if(key_name)
		name = key_name
	if(key_owner)
		owner = key_owner
	code = key_code || generate_cyberpunk_crypto_code()

/datum/cyberpunk_crypto_key/proc/matches(datum/cyberpunk_crypto_key/other_key)
	return !isnull(other_key) && code == other_key.code

/proc/generate_cyberpunk_crypto_code(length = CYBERPUNK_CRYPTO_KEY_LENGTH)
	. = ""
	for(var/index in 1 to length)
		var/char_index = rand(1, length(CYBERPUNK_CRYPTO_CHARSET))
		. += copytext_char(CYBERPUNK_CRYPTO_CHARSET, char_index, char_index + 1)

/proc/get_cyberpunk_crypto_segment(code, segment_index)
	var/start_index = ((segment_index - 1) * CYBERPUNK_CRYPTO_SEGMENT_LENGTH) + 1
	return copytext_char(code, start_index, start_index + CYBERPUNK_CRYPTO_SEGMENT_LENGTH)

/mob/living
	var/list/datum/cyberpunk_crypto_key/cyberpunk_crypto_memory
	var/list/cyberpunk_memory_notes

/mob/living/proc/get_cyberpunk_crypto_identity()
	return ckey("[mind?.name || real_name || key || name]")

/mob/living/proc/remember_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return FALSE
	LAZYINITLIST(cyberpunk_crypto_memory)
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_memory)
		if(stored_key.matches(key_datum))
			return TRUE
	cyberpunk_crypto_memory += key_datum
	return TRUE

/mob/living/proc/has_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return TRUE
	if(!has_neural_implant())
		return FALSE
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_memory)
		if(stored_key.matches(key_datum))
			return TRUE
	return FALSE

/mob/living/proc/get_cyberpunk_access_card()
	var/obj/item/held_item = get_active_held_item()
	if(istype(held_item, /obj/item/card/id))
		return held_item
	for(var/obj/item/item as anything in held_items)
		if(istype(item, /obj/item/card/id))
			return item
	var/obj/item/neck_item = get_item_by_slot(ITEM_SLOT_NECK)
	if(istype(neck_item, /obj/item/card/id))
		return neck_item
	return null

/mob/living/proc/held_or_neck_card_has_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return TRUE
	for(var/obj/item/item as anything in held_items)
		if(!istype(item, /obj/item/card/id))
			continue
		if(item.has_cyberpunk_crypto_key(key_datum))
			return TRUE
	var/obj/item/neck_item = get_item_by_slot(ITEM_SLOT_NECK)
	if(istype(neck_item, /obj/item/card/id) && neck_item.has_cyberpunk_crypto_key(key_datum))
		return TRUE
	return FALSE

/mob/living/proc/sync_cyberpunk_access_card_to_neural_interface(obj/item/card/id/card)
	if(!has_neural_implant())
		return "Your body has no functional neural interface."
	if(!card)
		card = get_cyberpunk_access_card()
	if(!card)
		return "Hold an ID card or wear it on your neck to synchronize access keys."
	card.sync_cyberpunk_crypto_access_keys()
	var/synced_keys = 0
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in card.cyberpunk_crypto_keys)
		if(remember_cyberpunk_crypto_key(key_datum))
			synced_keys++
	return "Synchronized [synced_keys] cryptokey[synced_keys == 1 ? "" : "s"] from [card]."

//CYBERPUNK BUILD - rebuild and delete before release
/mob/living/verb/test_cyberpunk_crypto_hack()
	set name = "Test cryptokey"
	set category = "IC"

	var/datum/cyberpunk_crypto_key/test_key = new("test service key", "independent")
	var/datum/cyberpunk_crypto_hack_session/session = new(src, null, test_key)
	session.ui_interact(src)

/mob/living/verb/create_cyberpunk_access_backup_cards()
	set name = "Create Test Access Cards"
	set category = "IC"

	var/turf/drop_turf = get_turf(src)
	if(!drop_turf)
		return
	new /obj/item/card/id/cyberpunk_access/benn(drop_turf)
	new /obj/item/card/id/cyberpunk_access/ryaznov(drop_turf)
	new /obj/item/card/id/cyberpunk_access/starlight(drop_turf)
	new /obj/item/card/id/cyberpunk_access/council(drop_turf)
	new /obj/item/card/id/cyberpunk_access/police(drop_turf)
	new /obj/item/card/id/cyberpunk_access/corporate_heads(drop_turf)
	new /obj/item/card/id/cyberpunk_access/government(drop_turf)

/mob/living/proc/show_cyberpunk_crypto_memory()
	if(!length(cyberpunk_crypto_memory))
		to_chat(src, span_notice("No cryptokeys stored in memory."))
		return
	to_chat(src, span_notice("Stored cryptokeys:"))
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in cyberpunk_crypto_memory)
		to_chat(src, span_notice("- [key_datum.name] / [key_datum.owner]: [key_datum.code]"))

/mob/living/verb/write_cyberpunk_crypto_key_to_held_item()
	set name = "Р—Р°РїРёСЃР°С‚СЊ РєСЂРёРїС‚РѕРєР»СЋС‡ РЅР° РїСЂРµРґРјРµС‚"
	set category = "IC"

	var/obj/item/held_item = get_active_held_item()
	if(!held_item)
		to_chat(src, span_warning("Hold a card, disk or device to write a cryptokey onto it."))
		return
	if(!length(cyberpunk_crypto_memory))
		to_chat(src, span_warning("No cryptokeys stored in memory."))
		return
	var/list/key_choices = list()
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in cyberpunk_crypto_memory)
		key_choices["[key_datum.name] / [key_datum.owner]"] = key_datum
	var/choice = tgui_input_list(src, "Select a cryptokey to write to [held_item].", "Cryptokey memory", key_choices)
	if(!choice)
		return
	var/datum/cyberpunk_crypto_key/selected_key = key_choices[choice]
	if(held_item.store_cyberpunk_crypto_key(selected_key))
		to_chat(src, span_notice("You write [selected_key.name] to [held_item]."))
//CYBERPUNK BUILD - rebuild and delete before release

/obj/item/proc/store_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return FALSE
	LAZYINITLIST(cyberpunk_crypto_keys)
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_keys)
		if(stored_key.matches(key_datum))
			return TRUE
	cyberpunk_crypto_keys += key_datum
	return TRUE

/obj/item/proc/has_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return TRUE
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_keys)
		if(stored_key.matches(key_datum))
			return TRUE
	return FALSE

/atom/movable/proc/add_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum)
		return FALSE
	LAZYINITLIST(cyberpunk_crypto_keys)
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_keys)
		if(stored_key.matches(key_datum))
			return TRUE
	cyberpunk_crypto_keys += key_datum
	return TRUE

/atom/movable/proc/remove_cyberpunk_crypto_key(datum/cyberpunk_crypto_key/key_datum)
	if(!key_datum || !length(cyberpunk_crypto_keys))
		return FALSE
	for(var/datum/cyberpunk_crypto_key/stored_key as anything in cyberpunk_crypto_keys)
		if(stored_key.matches(key_datum))
			cyberpunk_crypto_keys -= stored_key
			return TRUE
	return FALSE

/atom/movable/proc/create_and_add_cyberpunk_crypto_key(key_name = null, key_owner = null)
	var/datum/cyberpunk_crypto_key/key_datum = new(key_name || "[name] service key", key_owner || get_cyberspace_manufacturer(src))
	add_cyberpunk_crypto_key(key_datum)
	return key_datum

/obj/machinery
	var/list/cyberpunk_crypto_bypass_until

/obj/machinery/proc/get_or_create_cyberpunk_crypto_key()
	LAZYINITLIST(cyberpunk_crypto_keys)
	if(!length(cyberpunk_crypto_keys))
		var/manufacturer = get_cyberspace_manufacturer(src)
		create_and_add_cyberpunk_crypto_key("[name] service key", manufacturer)
	return cyberpunk_crypto_keys[1]

/obj/machinery/proc/has_cyberpunk_crypto_access(mob/living/user)
	if(!length(cyberpunk_crypto_keys))
		return TRUE
	if(!user)
		return FALSE
	if(has_cyberpunk_crypto_bypass(user))
		return TRUE
	for(var/datum/cyberpunk_crypto_key/key_datum as anything in cyberpunk_crypto_keys)
		if(user.has_cyberpunk_crypto_key(key_datum) || user.held_or_neck_card_has_cyberpunk_crypto_key(key_datum))
			return TRUE
	return FALSE

/obj/machinery/proc/has_cyberpunk_crypto_bypass(mob/living/user)
	if(!user || !cyberpunk_crypto_bypass_until)
		return FALSE
	var/identity = user.get_cyberpunk_crypto_identity()
	return (cyberpunk_crypto_bypass_until[identity] || 0) > world.time

/obj/machinery/proc/grant_cyberpunk_crypto_bypass(mob/living/user, duration = CYBERPUNK_CRYPTO_BYPASS_DURATION)
	if(!user)
		return FALSE
	LAZYINITLIST(cyberpunk_crypto_bypass_until)
	cyberpunk_crypto_bypass_until[user.get_cyberpunk_crypto_identity()] = world.time + duration
	return TRUE

/obj/machinery/proc/consume_cyberpunk_crypto_bypass(mob/living/user)
	if(!has_cyberpunk_crypto_bypass(user))
		return FALSE
	cyberpunk_crypto_bypass_until -= user.get_cyberpunk_crypto_identity()
	return TRUE

/obj/machinery/proc/open_cyberpunk_crypto_hack(mob/living/user)
	if(!user)
		return FALSE
	var/datum/cyberpunk_crypto_hack_session/session = new(user, src, get_or_create_cyberpunk_crypto_key())
	session.ui_interact(user)
	return TRUE

/obj/machinery/multitool_act(mob/living/user, obj/item/tool)
	if(panel_open)
		tool?.play_tool_sound(src)
		open_cyberpunk_crypto_hack(user)
		return TRUE
	return ..()

/datum/cyberpunk_crypto_hack_session
	var/mob/living/user
	var/obj/machinery/target
	var/datum/cyberpunk_crypto_key/key_datum
	var/list/columns = list()
	var/list/selections = list()
	var/list/revealed_positions = list()
	var/list/column_results = list()
	var/next_reveal = 0
	var/reveal_delay = CYBERPUNK_CRYPTO_REVEAL_DELAY
	var/last_error_count = 0
	var/closed = FALSE

/datum/cyberpunk_crypto_hack_session/New(mob/living/new_user, obj/machinery/new_target, datum/cyberpunk_crypto_key/new_key)
	. = ..()
	user = new_user
	target = new_target
	key_datum = new_key || new /datum/cyberpunk_crypto_key()
	reveal_delay = get_reveal_delay()
	for(var/column_index in 1 to CYBERPUNK_CRYPTO_COLUMNS)
		var/correct_segment = get_cyberpunk_crypto_segment(key_datum.code, column_index)
		columns += list(generate_column_options(correct_segment))
		selections += 0
		column_results["[column_index]"] = null
	initialize_revealed_positions()
	next_reveal = world.time + reveal_delay

/datum/cyberpunk_crypto_hack_session/Destroy(force)
	user = null
	target = null
	key_datum = null
	columns = null
	selections = null
	revealed_positions = null
	column_results = null
	return ..()

/datum/cyberpunk_crypto_hack_session/proc/generate_column_options(correct_segment)
	var/list/options = list(correct_segment)
	while(length(options) < CYBERPUNK_CRYPTO_OPTIONS)
		var/candidate = generate_cyberpunk_crypto_code(CYBERPUNK_CRYPTO_SEGMENT_LENGTH)
		if(candidate in options)
			continue
		options += candidate
	return shuffle(options)

/datum/cyberpunk_crypto_hack_session/proc/get_reveal_delay()
	var/hacking_skill = user?.get_character_skill_level(SKILL_HACKING) || 0
	return max(CYBERPUNK_CRYPTO_MIN_REVEAL_DELAY, CYBERPUNK_CRYPTO_REVEAL_DELAY - (hacking_skill * 1 SECONDS))

/datum/cyberpunk_crypto_hack_session/proc/initialize_revealed_positions()
	revealed_positions = list()
	var/reveal_count = clamp(round(user?.get_attribute_value(ATTRIBUTE_INTELLIGENCE) || 0), 0, CYBERPUNK_CRYPTO_KEY_LENGTH)
	for(var/reveal_index in 1 to reveal_count)
		var/position = clamp(round((CYBERPUNK_CRYPTO_KEY_LENGTH / (reveal_count + 1)) * reveal_index), 1, CYBERPUNK_CRYPTO_KEY_LENGTH)
		revealed_positions["[position]"] = TRUE

/datum/cyberpunk_crypto_hack_session/proc/reveal_random_position()
	var/list/hidden_positions = list()
	for(var/char_index in 1 to CYBERPUNK_CRYPTO_KEY_LENGTH)
		if(!revealed_positions["[char_index]"])
			hidden_positions += char_index
	if(!length(hidden_positions))
		return FALSE
	revealed_positions["[pick(hidden_positions)]"] = TRUE
	return TRUE

/datum/cyberpunk_crypto_hack_session/proc/update_timed_reveals()
	if(closed || world.time < next_reveal)
		return
	while(world.time >= next_reveal)
		if(!reveal_random_position())
			next_reveal = world.time
			return
		next_reveal += reveal_delay

/datum/cyberpunk_crypto_hack_session/proc/selected_segment(column_index)
	var/list/options = columns[column_index]
	if(selections[column_index] < 1)
		return "****"
	return options[selections[column_index]]

/datum/cyberpunk_crypto_hack_session/proc/is_aligned()
	for(var/column_index in 1 to CYBERPUNK_CRYPTO_COLUMNS)
		if(selected_segment(column_index) != get_cyberpunk_crypto_segment(key_datum.code, column_index))
			return FALSE
	return TRUE

/datum/cyberpunk_crypto_hack_session/proc/get_masked_key()
	update_timed_reveals()
	. = ""
	for(var/char_index in 1 to CYBERPUNK_CRYPTO_KEY_LENGTH)
		if(revealed_positions["[char_index]"])
			. += copytext_char(key_datum.code, char_index, char_index + 1)
		else
			. += "*"

/datum/cyberpunk_crypto_hack_session/proc/get_selected_code()
	. = ""
	for(var/column_index in 1 to CYBERPUNK_CRYPTO_COLUMNS)
		. += selected_segment(column_index)

/datum/cyberpunk_crypto_hack_session/proc/get_column_ui_data(column_index)
	var/list/options = columns[column_index]
	var/correct_segment = get_cyberpunk_crypto_segment(key_datum.code, column_index)
	var/selected_index = selections[column_index]
	var/check_result = column_results["[column_index]"]
	var/hacking_skill = user?.get_character_skill_level(SKILL_HACKING) || 0
	var/wrong_hint_budget = clamp(hacking_skill, 0, CYBERPUNK_CRYPTO_OPTIONS - 1)
	var/wrong_hints_used = 0
	var/list/option_data = list()
	for(var/option_index in 1 to length(options))
		var/option = options[option_index]
		var/is_wrong = option != correct_segment
		var/hinted_wrong = FALSE
		if(is_wrong && wrong_hints_used < wrong_hint_budget)
			hinted_wrong = TRUE
			wrong_hints_used++
		option_data += list(list(
			"index" = option_index,
			"text" = option,
			"selected" = option_index == selected_index,
			"wrongHint" = hinted_wrong,
			"result" = (option_index == selected_index) ? check_result : null,
		))
	return list(
		"index" = column_index,
		"selectedIndex" = selected_index,
		"options" = option_data,
	)

/datum/cyberpunk_crypto_hack_session/proc/complete_alignment()
	var/error_count = 0
	for(var/column_index in 1 to CYBERPUNK_CRYPTO_COLUMNS)
		if(selected_segment(column_index) == get_cyberpunk_crypto_segment(key_datum.code, column_index))
			column_results["[column_index]"] = "correct"
		else
			column_results["[column_index]"] = "wrong"
			error_count++
	last_error_count = error_count
	if(error_count)
		var/alarm_chance = min(90, error_count * 15)
		to_chat(user, span_warning("[error_count] cryptokey segment[error_count == 1 ? "" : "s"] rejected. Correct picks stay marked; wrong picks are flagged for brute-force correction."))
		if(prob(alarm_chance))
			to_chat(user, span_danger("The target access controller raises an alarm."))
			target?.visible_message(span_warning("[target] emits a sharp access alarm."))
		return TRUE
	user?.remember_cyberpunk_crypto_key(key_datum)
	target?.grant_cyberpunk_crypto_bypass(user)
	to_chat(user, span_notice("Cryptokey reconstructed and stored in memory."))
	closed = TRUE
	SStgui.close_uis(src)
	qdel(src)
	return TRUE

/datum/cyberpunk_crypto_hack_session/proc/submit_code(code)
	if(code != key_datum.code)
		to_chat(user, span_danger("Incorrect cryptokey. The target access controller raises an alarm."))
		target?.visible_message(span_warning("[target] emits a sharp access alarm."))
		return TRUE
	target?.grant_cyberpunk_crypto_bypass(user)
	to_chat(user, span_notice("Cryptokey accepted for one activation. It is not stored in memory."))
	closed = TRUE
	SStgui.close_uis(src)
	qdel(src)
	return TRUE

/datum/cyberpunk_crypto_hack_session/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_crypto_hack_session/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkCryptoHack", "Cryptokey breach")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/cyberpunk_crypto_hack_session/ui_close(mob/user)
	closed = TRUE
	qdel(src)

/datum/cyberpunk_crypto_hack_session/ui_data(mob/user)
	update_timed_reveals()
	var/list/column_data = list()
	for(var/column_index in 1 to CYBERPUNK_CRYPTO_COLUMNS)
		column_data += list(get_column_ui_data(column_index))
	var/hidden_count = CYBERPUNK_CRYPTO_KEY_LENGTH - length(revealed_positions)
	return list(
		"targetName" = target?.name || "test harness",
		"keyName" = key_datum.name,
		"owner" = key_datum.owner,
		//CYBERPUNK BUILD - rebuild and delete before release
		"testKey" = key_datum.code,
		//CYBERPUNK BUILD - rebuild and delete before release
		"maskedKey" = get_masked_key(),
		"selectedCode" = get_selected_code(),
		"hackingSkill" = src.user?.get_character_skill_level(SKILL_HACKING) || 0,
		"intelligence" = src.user?.get_attribute_value(ATTRIBUTE_INTELLIGENCE) || 0,
		"columns" = column_data,
		"aligned" = is_aligned(),
		"revealTimer" = hidden_count > 0 ? max(0, round((next_reveal - world.time) / 10, 0.1)) : 0,
		"revealDelay" = round(reveal_delay / 10, 0.1),
		"revealedCount" = length(revealed_positions),
		"lastErrorCount" = last_error_count,
	)

/datum/cyberpunk_crypto_hack_session/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .
	switch(action)
		if("select_segment")
			var/column_index = clamp(text2num(params["column"]), 1, CYBERPUNK_CRYPTO_COLUMNS)
			var/option_index = clamp(text2num(params["option"]), 1, CYBERPUNK_CRYPTO_OPTIONS)
			selections[column_index] = option_index
			column_results["[column_index]"] = null
			return TRUE
		if("attempt_alignment")
			return complete_alignment()
		if("submit_code")
			return submit_code(params["code"])
	return FALSE

#undef CYBERPUNK_CRYPTO_KEY_LENGTH
#undef CYBERPUNK_CRYPTO_COLUMNS
#undef CYBERPUNK_CRYPTO_SEGMENT_LENGTH
#undef CYBERPUNK_CRYPTO_OPTIONS
#undef CYBERPUNK_CRYPTO_REVEAL_DELAY
#undef CYBERPUNK_CRYPTO_MIN_REVEAL_DELAY
#undef CYBERPUNK_CRYPTO_BYPASS_DURATION
#undef CYBERPUNK_CRYPTO_CHARSET
//CYBERPUNK BUILD - rebuild and delete before release

//CYBERPUNK BUILD - rebuild and delete before release
/datum/cyberpunk_machine_module
	var/name = "generic machinery module"
	var/id = "generic"
	var/description = "A generic machinery module."
	var/manufacturer = "Р СЏР·РЅРѕРІ"
	var/corp_manufacturer = "Р СЏР·РЅРѕРІ"
	var/obj/item/module_item_type = /obj/item/cyberpunk_machine_module
	var/power_usage_multiplier = 1
	var/wear_multiplier = 1
	var/tool_time_multiplier = 1
	var/repair_multiplier = 1
	var/salvage_multiplier = 1
	var/integrity_bonus = 0
	var/chem_speed_multiplier = 1
	var/chem_cost_multiplier = 1
	var/vending_stock_multiplier = 1
	var/apc_efficiency_multiplier = 1

/datum/cyberpunk_machine_module/proc/can_install(obj/machinery/machine, mob/living/user)
	return TRUE

/datum/cyberpunk_machine_module/proc/on_install(obj/machinery/machine, mob/living/user)
	if(integrity_bonus > 0 && machine.uses_integrity)
		machine.max_integrity += integrity_bonus
		machine.update_integrity(min(machine.max_integrity, machine.get_integrity() + integrity_bonus))
	machine.RefreshParts()
	return

/datum/cyberpunk_machine_module/proc/on_remove(obj/machinery/machine, mob/living/user)
	if(integrity_bonus > 0 && machine.uses_integrity)
		machine.max_integrity = max(1, machine.max_integrity - integrity_bonus)
		machine.update_integrity(min(machine.get_integrity(), machine.max_integrity))
	machine.RefreshParts()
	return

/datum/cyberpunk_machine_module/proc/get_diagnostic_line(obj/machinery/machine)
	return "[name] ([manufacturer]): [description]"

/datum/cyberpunk_machine_module/power_governor
	name = "reserve power governor"
	id = "power_governor"
	description = "Lowers passive and active machine power draw."
	module_item_type = /obj/item/cyberpunk_machine_module/power_governor
	power_usage_multiplier = 0.8

/datum/cyberpunk_machine_module/wear_buffer
	name = "wear buffer"
	id = "wear_buffer"
	description = "Reduces component wear from machine use."
	module_item_type = /obj/item/cyberpunk_machine_module/wear_buffer
	wear_multiplier = 0.75

/datum/cyberpunk_machine_module/reinforced_frame
	name = "reinforced machine frame"
	id = "reinforced_frame"
	description = "Adds structural integrity to the machine housing."
	module_item_type = /obj/item/cyberpunk_machine_module/reinforced_frame
	integrity_bonus = 25

/datum/cyberpunk_machine_module/service_bus
	name = "service bus"
	id = "service_bus"
	description = "Improves maintenance and repair efficiency."
	module_item_type = /obj/item/cyberpunk_machine_module/service_bus
	tool_time_multiplier = 0.9
	repair_multiplier = 1.25

/datum/cyberpunk_machine_module/salvage_router
	name = "salvage routing matrix"
	id = "salvage_router"
	description = "Improves recoverable component stack drops during clean deconstruction."
	module_item_type = /obj/item/cyberpunk_machine_module/salvage_router
	salvage_multiplier = 1.25

/datum/cyberpunk_machine_module/chem_reaction_accelerator
	name = "chem reaction accelerator"
	id = "chem_reaction_accelerator"
	description = "A general chemistry module that slightly improves reaction and handling speed."
	module_item_type = /obj/item/cyberpunk_machine_module/chem_reaction_accelerator
	tool_time_multiplier = 0.85
	chem_speed_multiplier = 0.85

/datum/cyberpunk_machine_module/chem_yield_regulator
	name = "chem yield regulator"
	id = "chem_yield_regulator"
	description = "A general chemistry module that trims reagent and energy waste."
	module_item_type = /obj/item/cyberpunk_machine_module/chem_yield_regulator
	power_usage_multiplier = 0.9
	wear_multiplier = 0.9
	chem_cost_multiplier = 0.9

/datum/cyberpunk_machine_module/corporate_vending_bus
	name = "corporate vending bus"
	id = "corporate_vending_bus"
	description = "A vending module for corporate stock routing and slightly cleaner service cycles."
	module_item_type = /obj/item/cyberpunk_machine_module/corporate_vending_bus
	power_usage_multiplier = 0.95
	wear_multiplier = 0.9
	vending_stock_multiplier = 1.1

/datum/cyberpunk_machine_module/apc_efficiency_core
	name = "APC efficiency core"
	id = "apc_efficiency_core"
	description = "An APC-focused module that reduces local control losses and passive draw."
	module_item_type = /obj/item/cyberpunk_machine_module/apc_efficiency_core
	power_usage_multiplier = 0.75
	wear_multiplier = 0.9
	apc_efficiency_multiplier = 0.85

/datum/cyberpunk_machine_module/chem_reaction_accelerator/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/chem_master) || istype(machine, /obj/machinery/chem_dispenser)

/datum/cyberpunk_machine_module/chem_yield_regulator/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/chem_master) || istype(machine, /obj/machinery/chem_dispenser)

/datum/cyberpunk_machine_module/corporate_vending_bus/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/vending)

/datum/cyberpunk_machine_module/apc_efficiency_core/can_install(obj/machinery/machine, mob/living/user)
	return istype(machine, /obj/machinery/power/apc)

/proc/cyberpunk_machine_module_catalog()
	return list(
		/datum/cyberpunk_machine_module/power_governor,
		/datum/cyberpunk_machine_module/wear_buffer,
		/datum/cyberpunk_machine_module/reinforced_frame,
		/datum/cyberpunk_machine_module/service_bus,
		/datum/cyberpunk_machine_module/salvage_router,
		/datum/cyberpunk_machine_module/chem_reaction_accelerator,
		/datum/cyberpunk_machine_module/chem_yield_regulator,
		/datum/cyberpunk_machine_module/corporate_vending_bus,
		/datum/cyberpunk_machine_module/apc_efficiency_core,
	)

/obj/item/cyberpunk_machine_module
	name = "machine module"
	desc = "A Р СЏР·РЅРѕРІ-produced Cyberpunk 13 machinery module shell."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "integrated_circuit"
	w_class = WEIGHT_CLASS_SMALL
	var/manufacturer = "Р СЏР·РЅРѕРІ"
	var/corp_manufacturer = "Р СЏР·РЅРѕРІ"
	var/module_datum_type = /datum/cyberpunk_machine_module

/obj/item/cyberpunk_machine_module/proc/create_module_datum()
	return new module_datum_type

/obj/item/cyberpunk_machine_module/examine(mob/user)
	. = ..()
	. += span_notice("Manufacturer: [manufacturer].")

/obj/item/cyberpunk_machine_module/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/machinery/machine = interacting_with
	if(!istype(machine))
		return NONE
	if(!machine.panel_open)
		to_chat(user, span_warning("Open the maintenance panel before installing a machine module."))
		return ITEM_INTERACT_BLOCKING
	var/datum/cyberpunk_machine_module/module = create_module_datum()
	if(machine.install_cyberpunk_module(module, user, TRUE))
		to_chat(user, span_notice("You install [module.name] into [machine]."))
		qdel(src)
		return ITEM_INTERACT_SUCCESS
	qdel(module)
	to_chat(user, span_warning("This machine cannot accept that module."))
	return ITEM_INTERACT_BLOCKING

/obj/item/cyberpunk_machine_module/power_governor
	name = "reserve power governor"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/power_governor

/obj/item/cyberpunk_machine_module/wear_buffer
	name = "wear buffer"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/wear_buffer

/obj/item/cyberpunk_machine_module/reinforced_frame
	name = "reinforced machine frame"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_machine_module/reinforced_frame

/obj/item/cyberpunk_machine_module/service_bus
	name = "service bus"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/service_bus

/obj/item/cyberpunk_machine_module/salvage_router
	name = "salvage routing matrix"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/salvage_router

/obj/item/cyberpunk_machine_module/chem_reaction_accelerator
	name = "chem reaction accelerator"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_machine_module/chem_reaction_accelerator

/obj/item/cyberpunk_machine_module/chem_yield_regulator
	name = "chem yield regulator"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_machine_module/chem_yield_regulator

/obj/item/cyberpunk_machine_module/corporate_vending_bus
	name = "corporate vending bus"
	icon_state = "harddisk"
	module_datum_type = /datum/cyberpunk_machine_module/corporate_vending_bus

/obj/item/cyberpunk_machine_module/apc_efficiency_core
	name = "APC efficiency core"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_machine_module/apc_efficiency_core

/datum/design/cyberpunk_machine_module
	name = "Р СЏР·РЅРѕРІ Machine Module"
	desc = "A Р СЏР·РЅРѕРІ-certified maintenance module for Cyberpunk 13 machinery."
	id = "ryaznov_machine_module"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/cyberpunk_machine_module/power_governor
	name = "Р СЏР·РЅРѕРІ Reserve Power Governor"
	id = "ryaznov_power_governor"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/power_governor

/datum/design/cyberpunk_machine_module/wear_buffer
	name = "Р СЏР·РЅРѕРІ Wear Buffer"
	id = "ryaznov_wear_buffer"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/wear_buffer

/datum/design/cyberpunk_machine_module/reinforced_frame
	name = "Р СЏР·РЅРѕРІ Reinforced Machine Frame"
	id = "ryaznov_reinforced_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_machine_module/reinforced_frame

/datum/design/cyberpunk_machine_module/service_bus
	name = "Р СЏР·РЅРѕРІ Service Bus"
	id = "ryaznov_service_bus"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/service_bus

/datum/design/cyberpunk_machine_module/salvage_router
	name = "Р СЏР·РЅРѕРІ Salvage Routing Matrix"
	id = "ryaznov_salvage_router"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/salvage_router

/datum/design/cyberpunk_machine_module/chem_reaction_accelerator
	name = "Р В РЎРЏР В·Р Р…Р С•Р Р† Chem Reaction Accelerator"
	id = "ryaznov_chem_reaction_accelerator"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/chem_reaction_accelerator

/datum/design/cyberpunk_machine_module/chem_yield_regulator
	name = "Р В РЎРЏР В·Р Р…Р С•Р Р† Chem Yield Regulator"
	id = "ryaznov_chem_yield_regulator"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/chem_yield_regulator

/datum/design/cyberpunk_machine_module/corporate_vending_bus
	name = "Р В РЎРЏР В·Р Р…Р С•Р Р† Corporate Vending Bus"
	id = "ryaznov_corporate_vending_bus"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/corporate_vending_bus

/datum/design/cyberpunk_machine_module/apc_efficiency_core
	name = "Р В РЎРЏР В·Р Р…Р С•Р Р† APC Efficiency Core"
	id = "ryaznov_apc_efficiency_core"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_machine_module/apc_efficiency_core

//CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery
	name = "machinery"
	icon = 'icons/obj/machines/fax.dmi'
	desc = "Some kind of machine."
	abstract_type = /obj/machinery
	verb_say = "beeps"
	verb_yell = "blares"
	pressure_resistance = 15
	pass_flags_self = PASSMACHINE | LETPASSCLICKS
	max_integrity = 200
	layer = BELOW_OBJ_LAYER //keeps shit coming out of the machine from ending up underneath it.
	flags_ricochet = RICOCHET_HARD
	receive_ricochet_chance_mod = 0.3
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	initial_language_holder = /datum/language_holder/speaking_machine
	armor_type = /datum/armor/obj_machinery

	///see code/__DEFINES/stat.dm
	var/machine_stat = NONE
	///see code/__DEFINES/machines.dm
	var/use_power = IDLE_POWER_USE
	///the amount of static power load this machine adds to its area's power_usage list when use_power = IDLE_POWER_USE
	var/idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	///the amount of static power load this machine adds to its area's power_usage list when use_power = ACTIVE_POWER_USE
	var/active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	///the current amount of static power usage this machine is taking from its area
	var/static_power_usage = 0
	//AREA_USAGE_EQUIP,AREA_USAGE_ENVIRON or AREA_USAGE_LIGHT
	var/power_channel = AREA_USAGE_EQUIP
	///A combination of factors such as having power, not being broken and so on. Boolean.
	var/is_operational = TRUE
	///list of all the parts used to build it, if made from certain kinds of frames.
	var/list/component_parts = null
	///Cyberpunk 13 machinery wear accumulated through active use.
	var/cyberpunk_machine_wear = 0
	///Wear value at which the machine is considered broken.
	var/cyberpunk_machine_wear_limit = 100
	///Wear value at which the machine starts taking integrity damage.
	var/cyberpunk_machine_wear_damage_threshold = 50
	//CYBERPUNK BUILD - rebuild and delete before release
	///Default wear added by one active interaction.
	var/cyberpunk_machine_wear_per_use = 1
	///Global per-machine tuning knob for Cyberpunk 13 wear accumulation.
	var/cyberpunk_machine_wear_rate_multiplier = 0.05
	///Throttle for passive Cyberpunk 13 wear produced by powered work.
	var/cyberpunk_last_power_wear_time = 0
	///Current Cyberpunk 13 failure mode. Null means no wear-induced failure.
	var/cyberpunk_machine_failure_state = null
	///Chance that a shorted failure shocks a user on interaction before skill mitigation.
	var/cyberpunk_machine_failure_shock_chance = 35
	///Last mob that caused wear failure. Used for hack/alarm mitigation checks.
	var/mob/living/cyberpunk_last_failure_actor = null
	///Per-component Cyberpunk 13 wear. Keys are entries from component_parts.
	var/list/cyberpunk_component_wear
	///Installed Cyberpunk 13 machine modules.
	var/list/datum/cyberpunk_machine_module/cyberpunk_machine_modules
	///Generic module slots. Specific machines can override this later.
	var/cyberpunk_machine_module_slots = 2
	///Temporary CP13 module installation UI holder.
	var/datum/cyberpunk_machine_module_interface/cyberpunk_module_ui
	//CYBERPUNK BUILD - rebuild and delete before release
	///Is the machines maintenance panel open.
	var/panel_open = FALSE
	///Is the machine open or closed
	var/state_open = FALSE
	///If this machine is critical to station operation and should have the area be excempted from power failures.
	var/critical_machine = FALSE
	///if set, turned into typecache in Initialize, other wise, defaults to mob/living typecache
	var/list/occupant_typecache
	///The mob that is sealed inside the machine
	var/atom/movable/occupant = null
	///Viable flags to go here are START_PROCESSING_ON_INIT, or START_PROCESSING_MANUALLY. See code\__DEFINES\machines.dm for more information on these flags.
	var/processing_flags = START_PROCESSING_ON_INIT
	///What subsystem this machine will use, which is generally SSmachines or SSfastprocess. By default all machinery use SSmachines. This fires a machine's process() roughly every 2 seconds.
	var/subsystem_type = /datum/controller/subsystem/machines
	///Circuit to be created and inserted when the machinery is created
	var/obj/item/circuitboard/circuit
	///See code/DEFINES/interaction_flags.dm
	var/interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON
	///The department we are paying to use this machine
	var/payment_department = ACCOUNT_ENG
	///Used in NAP violation, pay fine
	var/fair_market_price = 5
	///Is this machine currently in the atmos machinery queue?
	var/atmos_processing = FALSE
	///world.time of last use by [/mob/living]
	var/last_used_time = 0
	///Mobtype of last user. Typecast to [/mob/living] for initial() usage
	var/mob/living/last_user_mobtype
	///Do we want to hook into on_enter_area and on_exit_area?
	///Disables some optimizations
	var/always_area_sensitive = FALSE
	///What was our power state the last time we updated its appearance?
	///TRUE for on, FALSE for off, -1 for never checked
	var/appearance_power_state = -1

/datum/armor/obj_machinery
	melee = 25
	bullet = 10
	laser = 10
	fire = 50
	acid = 70

///Needed by machine frame & flatpacker i.e the named arg board
/obj/machinery/New(location, obj/item/circuitboard/board, ...)
	if(istype(board))
		circuit = board
		//we don't want machines that override Initialize() have the board passed as a param e.g. atmos
		return ..(location)

	return ..()

/obj/machinery/Initialize(mapload)
	. = ..()
	SSmachines.register_machine(src)

	if(ispath(circuit, /obj/item/circuitboard))
		circuit = new circuit(src)
	if(istype(circuit))
		circuit.apply_default_parts(src)

	if(processing_flags & START_PROCESSING_ON_INIT)
		begin_processing()

	if(occupant_typecache)
		occupant_typecache = typecacheof(occupant_typecache)

	if((resistance_flags & INDESTRUCTIBLE) && component_parts){ // This is needed to prevent indestructible machinery still blowing up. If an explosion occurs on the same tile as the indestructible machinery without the PREVENT_CONTENTS_EXPLOSION_1 flag, /datum/controller/subsystem/explosions/proc/propagate_blastwave will call ex_act on all movable atoms inside the machine, including the circuit board and component parts. However, if those parts get deleted, the entire machine gets deleted, allowing for INDESTRUCTIBLE machines to be destroyed. (See #62164 for more info)
		flags_1 |= PREVENT_CONTENTS_EXPLOSION_1
	}

	if(HAS_TRAIT(SSstation, STATION_TRAIT_MACHINES_GLITCHED) && mapload)
		randomize_language_if_on_station()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_MACHINE, src)

	return INITIALIZE_HINT_LATELOAD

//CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery/get_cyberpunk_diagnostic_data(mob/living/user)
	. = ..()
	. += "Wear: [round(cyberpunk_machine_wear)]/[cyberpunk_machine_wear_limit]."
	. += "Wear rate: x[round(cyberpunk_machine_wear_rate_multiplier, 0.01)]."
	. += "Failure: [cyberpunk_machine_failure_state || "none"]."
	. += "Modules: [length(cyberpunk_machine_modules)]/[cyberpunk_machine_module_slots]."
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		. += module.get_diagnostic_line(src)
	. += "РџРёС‚Р°РЅРёРµ: [powered() ? "РµСЃС‚СЊ" : "РЅРµС‚"]."
	. += "РЎРѕСЃС‚РѕСЏРЅРёРµ: [machine_stat ? "[machine_stat]" : "С€С‚Р°С‚РЅРѕРµ"]."
	. += "РџР°РЅРµР»СЊ: [panel_open ? "РѕС‚РєСЂС‹С‚Р°" : "Р·Р°РєСЂС‹С‚Р°"]."
	. += "РљРѕРјРїРѕРЅРµРЅС‚С‹: [length(component_parts)]."
	if(user?.get_cyberpunk_machine_diagnostic_depth(src) > 0)
		. += "РџРѕСЂРѕРі РїРѕРІСЂРµР¶РґРµРЅРёСЏ РёР·РЅРѕСЃРѕРј: [cyberpunk_machine_wear_damage_threshold]."
		. += "РЁР°РЅСЃ РєРѕСЂРѕС‚РєРѕРіРѕ Р·Р°РјС‹РєР°РЅРёСЏ: [cyberpunk_machine_failure_shock_chance]%."

//CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery/LateInitialize()
	SHOULD_NOT_OVERRIDE(TRUE)
	post_machine_initialize()

/**
 * Called in LateInitialize meant to be the machine replacement to it
 * This sets up power for the machine and requires parent be called,
 * ensuring power works on all machines unless exempted with NO_POWER_USE.
 * This is the proc to override if you want to do anything in LateInitialize.
 */
/obj/machinery/proc/post_machine_initialize()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	find_and_mount_on_atom(late_init = TRUE)

	power_change()
	if(use_power == NO_POWER_USE)
		return
	update_current_power_usage()
	setup_area_power_relationship()


/obj/machinery/Destroy(force)
	SSmachines.unregister_machine(src)
	end_processing()

	QDEL_LIST(cyberpunk_machine_modules)
	QDEL_NULL(cyberpunk_module_ui)
	cyberpunk_component_wear = null
	cyberpunk_last_deconstructor = null
	cyberpunk_last_failure_actor = null
	clear_components()
	unset_static_power()

	return ..()

/**
 * proc to call when the machine starts to require power after a duration of not requiring power
 * sets up power related connections to its area if it exists and becomes area sensitive
 * does not affect power usage itself
 *
 * Returns TRUE if it triggered a full registration, FALSE otherwise
 * We do this so machinery that want to sidestep the area sensitiveity optimization can
 */
/obj/machinery/proc/setup_area_power_relationship()
	var/area/our_area = get_area(src)
	if(our_area)
		RegisterSignal(our_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(power_change))

	if(HAS_TRAIT_FROM(src, TRAIT_AREA_SENSITIVE, INNATE_TRAIT)) // If we for some reason have not lost our area sensitivity, there's no reason to set it back up
		return FALSE

	become_area_sensitive(INNATE_TRAIT)
	RegisterSignal(src, COMSIG_ENTER_AREA, PROC_REF(on_enter_area))
	RegisterSignal(src, COMSIG_EXIT_AREA, PROC_REF(on_exit_area))
	return TRUE

/**
 * proc to call when the machine stops requiring power after a duration of requiring power
 * saves memory by removing the power relationship with its area if it exists and loses area sensitivity
 * does not affect power usage itself
 */
/obj/machinery/proc/remove_area_power_relationship()
	var/area/our_area = get_area(src)
	if(our_area)
		UnregisterSignal(our_area, COMSIG_AREA_POWER_CHANGE)

	if(always_area_sensitive)
		return

	lose_area_sensitivity(INNATE_TRAIT)
	UnregisterSignal(src, COMSIG_ENTER_AREA)
	UnregisterSignal(src, COMSIG_EXIT_AREA)

/obj/machinery/proc/on_enter_area(datum/source, area/area_to_register)
	SIGNAL_HANDLER
	// If we're always area sensitive, and this is called while we have no power usage, do nothing and return
	if(always_area_sensitive && use_power == NO_POWER_USE)
		return
	update_current_power_usage()
	power_change()
	RegisterSignal(area_to_register, COMSIG_AREA_POWER_CHANGE, PROC_REF(power_change))

/obj/machinery/proc/on_exit_area(datum/source, area/area_to_unregister)
	SIGNAL_HANDLER
	// If we're always area sensitive, and this is called while we have no power usage, do nothing and return
	if(always_area_sensitive && use_power == NO_POWER_USE)
		return
	unset_static_power()
	UnregisterSignal(area_to_unregister, COMSIG_AREA_POWER_CHANGE)

/obj/machinery/proc/set_occupant(atom/movable/new_occupant)
	SHOULD_CALL_PARENT(TRUE)

	SEND_SIGNAL(src, COMSIG_MACHINERY_SET_OCCUPANT, new_occupant)
	occupant = new_occupant

/// Helper proc for telling a machine to start processing
/obj/machinery/proc/begin_processing()
	var/datum/controller/subsystem/processing/subsystem = locate(subsystem_type) in Master.subsystems
	START_PROCESSING(subsystem, src)

/// Helper proc for telling a machine to stop processing
/obj/machinery/proc/end_processing()
	var/datum/controller/subsystem/processing/subsystem = locate(subsystem_type) in Master.subsystems
	STOP_PROCESSING(subsystem, src)

///Early process for machines added to SSmachines.processing_early to prioritize power draw
/obj/machinery/proc/process_early()
	set waitfor = FALSE
	return PROCESS_KILL

/obj/machinery/process()//If you dont use process or power why are you here
	return PROCESS_KILL

///Late process for machines added to SSmachines.processing_late to gather accurate recordings
/obj/machinery/proc/process_late()
	set waitfor = FALSE
	return PROCESS_KILL

/**
 * Process but for machines interacting with atmospherics.
 * Like process, anything sensitive to changes in the wait time between process ticks should account for seconds_per_tick.
**/
/obj/machinery/proc/process_atmos(seconds_per_tick)//If you dont touch atmos why are you here
	set waitfor = FALSE
	return PROCESS_KILL

///Called when we want to change the value of the machine_stat variable. Holds bitflags.
/obj/machinery/proc/set_machine_stat(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(new_value == machine_stat)
		return
	. = machine_stat
	machine_stat = new_value
	on_set_machine_stat(.)


///Called when the value of `machine_stat` changes, so we can react to it.
/obj/machinery/proc/on_set_machine_stat(old_value)
	PROTECTED_PROC(TRUE)

	//From off to on.
	if((old_value & (NOPOWER|BROKEN|MAINT)) && !(machine_stat & (NOPOWER|BROKEN|MAINT)))
		set_is_operational(TRUE)
		return
	//From on to off.
	if(machine_stat & (NOPOWER|BROKEN|MAINT))
		set_is_operational(FALSE)


/obj/machinery/emp_act(severity)
	. = ..()
	if(!use_power || machine_stat || (. & EMP_PROTECT_SELF))
		return
	use_energy(7.5 KILO JOULES / severity)
	new /obj/effect/temp_visual/emp(loc)

	if(!prob(70/severity))
		return
	if (!length(GLOB.uncommon_roundstart_languages))
		return
	remove_all_languages(source = LANGUAGE_EMP)
	grant_random_uncommon_language(source = LANGUAGE_EMP)

/**
 * Opens the machine.
 *
 * Will update the machine icon and any user interfaces currently open.
 * Arguments:
 * * drop - Boolean. Whether to drop any stored items in the machine. Does not include components.
 * * density - Boolean. Whether to make the object dense when it's open.
 */
/obj/machinery/proc/open_machine(drop = TRUE, density_to_set = FALSE)
	state_open = TRUE
	set_density(density_to_set)
	if(drop)
		dump_inventory_contents()
	update_appearance()

/**
 * Drop every movable atom in the machine's contents list, including any components and circuit.
 */
/obj/machinery/dump_contents()
	// Start by calling the dump_inventory_contents proc. Will allow machines with special contents
	// to handle their dropping.
	dump_inventory_contents()

	// Then we can clean up and drop everything else.
	var/turf/this_turf = get_turf(src)
	for(var/atom/movable/movable_atom in contents)
		movable_atom.forceMove(this_turf)

	// We'll have dropped the occupant, circuit and component parts as part of this.
	set_occupant(null)
	circuit = null
	LAZYCLEARLIST(component_parts)

/**
 * Drop every movable atom in the machine's contents list that is not a component_part.
 *
 * Proc does not drop components and will skip over anything in the component_parts list.
 * Call dump_contents() to drop all contents including components.
 * Arguments:
 * * subset - If this is not null, only atoms that are also contained within the subset list will be dropped.
 */
/obj/machinery/proc/dump_inventory_contents(list/subset = null)
	var/turf/this_turf = get_turf(src)
	for(var/atom/movable/movable_atom in contents)
		//so machines like microwaves dont dump out signalers after cooking
		if(wires && (movable_atom in assoc_to_values(wires.assemblies)))
			continue

		if(subset && !(movable_atom in subset))
			continue

		if(movable_atom in component_parts)
			continue

		movable_atom.forceMove(this_turf)

		if(occupant == movable_atom)
			set_occupant(null)

/**
 * Puts passed object in to user's hand
 *
 * Puts the passed object in to the users hand if they are adjacent.
 * If the user is not adjacent then place the object on top of the machine.
 *
 * Vars:
 * * object (obj) The object to be moved in to the users hand.
 * * user (mob/living) The user to recive the object
 */
/obj/machinery/proc/try_put_in_hand(obj/item/object, mob/living/user)
	if(!issilicon(user) && in_range(src, user))
		object.do_pickup_animation(user, src)
		user.put_in_hands(object)
	else
		object.forceMove(drop_location())

/obj/machinery/proc/can_be_occupant(atom/movable/occupant_atom)
	return occupant_typecache ? is_type_in_typecache(occupant_atom, occupant_typecache) : isliving(occupant_atom)

/obj/machinery/proc/close_machine(atom/movable/target, density_to_set = TRUE)
	state_open = FALSE
	set_density(density_to_set)
	if (!density)
		update_appearance()
		return

	if(!target)
		for(var/atom in loc)
			if (!(can_be_occupant(atom)))
				continue
			var/atom/movable/current_atom = atom
			if(current_atom.has_buckled_mobs())
				continue
			if(isliving(current_atom))
				var/mob/living/current_mob = atom
				if(current_mob.buckled || current_mob.mob_size >= MOB_SIZE_LARGE)
					continue
			target = atom

	var/mob/living/mobtarget = target
	if(target && !target.has_buckled_mobs() && (!isliving(target) || !mobtarget.buckled))
		set_occupant(target)
		target.forceMove(src)
	update_appearance()

///updates the use_power var for this machine and updates its static power usage from its area to reflect the new value
/obj/machinery/proc/update_use_power(new_use_power)
	SHOULD_CALL_PARENT(TRUE)
	if(new_use_power == use_power)
		return FALSE

	unset_static_power()

	var/new_usage = 0
	switch(new_use_power)
		if(IDLE_POWER_USE)
			new_usage = idle_power_usage
		if(ACTIVE_POWER_USE)
			new_usage = active_power_usage

	if(use_power == NO_POWER_USE)
		setup_area_power_relationship()
	else if(new_use_power == NO_POWER_USE)
		remove_area_power_relationship()

	static_power_usage = new_usage

	if(new_usage)
		var/area/our_area = get_area(src)
		our_area?.addStaticPower(new_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	use_power = new_use_power

	if(use_power)
		power_change()

	return TRUE

///updates the power channel this machine uses. removes the static power usage from the old channel and readds it to the new channel
/obj/machinery/proc/update_power_channel(new_power_channel)
	SHOULD_CALL_PARENT(TRUE)
	if(new_power_channel == power_channel)
		return FALSE

	var/usage = unset_static_power()

	var/area/our_area = get_area(src)

	if(our_area && usage)
		our_area.addStaticPower(usage, DYNAMIC_TO_STATIC_CHANNEL(new_power_channel))

	power_channel = new_power_channel

	return TRUE

///internal proc that removes all static power usage from the current area
/obj/machinery/proc/unset_static_power()
	SHOULD_NOT_OVERRIDE(TRUE)

	var/old_usage = static_power_usage

	var/area/our_area = get_area(src)

	if(our_area && old_usage)
		our_area.removeStaticPower(old_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))
		static_power_usage = 0

	return old_usage

/**
 * sets the power_usage linked to the specified use_power_mode to new_usage
 * e.g. update_mode_power_usage(ACTIVE_POWER_USE, 10) sets active_power_use = 10 and updates its power draw from the machines area if use_power == ACTIVE_POWER_USE
 *
 * Arguments:
 * * use_power_mode - the use_power power mode to change. if IDLE_POWER_USE changes idle_power_usage, ACTIVE_POWER_USE changes active_power_usage
 * * new_usage - the new value to set the specified power mode var to
 */
/obj/machinery/proc/update_mode_power_usage(use_power_mode, new_usage)
	SHOULD_CALL_PARENT(TRUE)
	if(use_power_mode == NO_POWER_USE)
		stack_trace("trying to set the power usage associated with NO_POWER_USE in update_mode_power_usage()!")
		return FALSE

	unset_static_power() //completely remove our static_power_usage from our area, then readd new_usage

	switch(use_power_mode)
		if(IDLE_POWER_USE)
			idle_power_usage = new_usage
		if(ACTIVE_POWER_USE)
			active_power_usage = new_usage

	if(use_power_mode == use_power)
		static_power_usage = new_usage

	var/area/our_area = get_area(src)

	if(our_area)
		our_area.addStaticPower(static_power_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	return TRUE

///Get a valid powered area to reference for power use, mainly for wall-mounted machinery that isn't always mapped directly in a powered location.
/obj/machinery/proc/get_room_area()
	var/area/machine_area = get_area(src)
	if(isnull(machine_area))
		return null // ??

	// check our own loc first to see if its a powered area
	if(!machine_area.always_unpowered)
		return machine_area

	// loc area wasn't good, checking adjacent wall for a good area to use
	var/turf/mounted_wall = get_step(src, dir)
	if(isclosedturf(mounted_wall))
		var/area/wall_area = get_area(mounted_wall)
		if(!wall_area.always_unpowered)
			return wall_area

	// couldn't find a proper powered area on loc or adjacent wall, defaulting back to loc and blaming mappers
	return machine_area

///makes this machine draw power from its area according to which use_power mode it is set to
/obj/machinery/proc/update_current_power_usage()
	if(static_power_usage)
		unset_static_power()

	var/area/our_area = get_area(src)
	if(!our_area)
		return FALSE

	switch(use_power)
		if(IDLE_POWER_USE)
			static_power_usage = idle_power_usage
		if(ACTIVE_POWER_USE)
			static_power_usage = active_power_usage
		if(NO_POWER_USE)
			return

	if(static_power_usage)
		our_area.addStaticPower(static_power_usage, DYNAMIC_TO_STATIC_CHANNEL(power_channel))

	return TRUE

///Called when we want to change the value of the `is_operational` variable. Boolean.
/obj/machinery/proc/set_is_operational(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(new_value == is_operational)
		return
	. = is_operational
	is_operational = new_value
	on_set_is_operational(.)


///Called when the value of `is_operational` changes, so we can react to it.
/obj/machinery/proc/on_set_is_operational(old_value)
	PROTECTED_PROC(TRUE)

	return

///Called when we want to change the value of the `panel_open` variable. Boolean.
/obj/machinery/proc/set_panel_open(new_value)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(panel_open == new_value)
		return
	var/old_value = panel_open
	panel_open = new_value
	on_set_panel_open(old_value)
	update_appearance()
	// if this is a machine that cares about whether the panel is open for UIs, force an update
	if(interaction_flags_machine & (INTERACT_MACHINE_OPEN_SILICON|INTERACT_MACHINE_OPEN))
		SStgui.update_uis(src)

///Called when the value of `panel_open` changes, so we can react to it.
/obj/machinery/proc/on_set_panel_open(old_value)
	PROTECTED_PROC(TRUE)

	return

/// Toggles the panel_open var. Defined for convienience
/obj/machinery/proc/toggle_panel_open()
	SHOULD_NOT_OVERRIDE(TRUE)

	set_panel_open(!panel_open)

/obj/machinery/can_interact(mob/user)
	if(QDELETED(user))
		return FALSE

	if((machine_stat & (NOPOWER|BROKEN)) && !(interaction_flags_machine & INTERACT_MACHINE_OFFLINE)) // Check if the machine is broken, and if we can still interact with it if so
		return FALSE

	var/try_use_signal = SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) | SEND_SIGNAL(src, COMSIG_TRY_USE_MACHINE, user)
	if(try_use_signal & COMPONENT_CANT_USE_MACHINE_INTERACT)
		return FALSE

	if(isAdminGhostAI(user))
		return TRUE //the Gods have unlimited power and do not care for things such as range or blindness

	if(!isliving(user))
		return FALSE //no ghosts allowed, sorry

	if(!HAS_SILICON_ACCESS(user) && !user.can_hold_items())
		return FALSE //spiders gtfo

	if(HAS_SILICON_ACCESS(user)) // If we are a silicon, make sure the machine allows silicons to interact with it
		if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON))
			return FALSE

		if(panel_open && !(interaction_flags_machine & INTERACT_MACHINE_OPEN) && !(interaction_flags_machine & INTERACT_MACHINE_OPEN_SILICON))
			return FALSE

		return user.can_interact_with(src) //AIs don't care about petty mortal concerns like needing to be next to a machine to use it, but borgs do care somewhat

	. = ..()
	if(!.)
		return FALSE

	if((interaction_flags_machine & INTERACT_MACHINE_REQUIRES_SIGHT) && user.is_blind())
		to_chat(user, span_warning("Р§С‚РѕР±С‹ РІРѕСЃРїРѕР»СЊР·РѕРІР°С‚СЊСЃСЏ СЌС‚РѕР№ РјР°С€РёРЅРѕР№, РЅСѓР¶РЅРѕ РёРјРµС‚СЊ Р·СЂРµРЅРёРµ."))
		return FALSE

	// machines have their own lit up display screens and LED buttons so we don't need to check for light
	if((interaction_flags_machine & INTERACT_MACHINE_REQUIRES_LITERACY) && !user.can_read(src, READING_CHECK_LITERACY))
		return FALSE

	if(panel_open && !(interaction_flags_machine & INTERACT_MACHINE_OPEN))
		return FALSE

	if(interaction_flags_machine & INTERACT_MACHINE_REQUIRES_SILICON) //if the user was a silicon, we'd have returned out earlier, so the user must not be a silicon
		return FALSE

	if(interaction_flags_machine & INTERACT_MACHINE_REQUIRES_STANDING)
		var/mob/living/living_user = user
		if(!(living_user.mobility_flags & MOBILITY_MOVE))
			return FALSE

	return TRUE // If we passed all of those checks, woohoo! We can interact with this machine.

////////////////////////////////////////////////////////////////////////////////////////////

//Return a non FALSE value to interrupt attack_hand propagation to subtypes.
/obj/machinery/interact(mob/user)
	if(isliving(user) && handle_cyberpunk_machine_failure_interaction(user))
		return TRUE
	if(panel_open && istype(user, /mob/living))
		var/mob/living/living_user = user
		var/obj/item/held_item = living_user.get_active_held_item()
		if(held_item?.tool_behaviour != TOOL_ANALYZER)
			open_cyberpunk_module_interface(living_user)
			return TRUE
	update_last_used(user)
	return ..()

/obj/machinery/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = ui.user
	add_fingerprint(user)
	update_last_used(user)
	if(isAI(user) && !SScameras.is_visible_by_cameras(get_turf(src))) //We check if they're an AI specifically here, so borgs/adminghosts/human wand can still access off-camera stuff.
		to_chat(user, span_warning("Р’С‹ Р±РѕР»СЊС€Рµ РЅРµ РјРѕР¶РµС‚Рµ РІР·Р°РёРјРѕРґРµР№СЃС‚РІРѕРІР°С‚СЊ СЃ СЌС‚РёРј СѓСЃС‚СЂРѕР№СЃС‚РІРѕРј!"))
		return FALSE
	return ..()

/obj/machinery/Topic(href, href_list)
	..()
	if(!can_interact(usr))
		return TRUE
	if(!usr.can_perform_action(src, ALLOW_SILICON_REACH))
		return TRUE
	add_fingerprint(usr)
	update_last_used(usr)
	return FALSE

////////////////////////////////////////////////////////////////////////////////////////////

/obj/machinery/attack_paw(mob/living/user, list/modifiers)
	if(!user.combat_mode)
		return attack_hand(user)

	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	var/damage = take_damage(damage_amount = 4, damage_type = BRUTE, damage_flag = MELEE, sound_effect = TRUE, attack_dir = get_dir(user, src))

	var/hit_with_what_noun = "paws"
	var/obj/item/bodypart/arm/arm = user.get_active_hand()
	if(!isnull(arm))
		hit_with_what_noun = arm.appendage_noun // hit with "their hand"
		if(user.usable_hands > 1)
			hit_with_what_noun += plural_s(hit_with_what_noun) // hit with "their hands"

	user.visible_message(
		span_danger("[user] smashes [src] with [user.p_their()] [hit_with_what_noun][damage ? "." : ", [no_damage_feedback]!"]"),
		span_danger("You smash [src] with your [hit_with_what_noun][damage ? "." : ", [no_damage_feedback]!"]"),
		span_hear("You hear a [damage ? "smash" : "thud"]."),
		COMBAT_MESSAGE_RANGE,
	)
	return TRUE

/obj/machinery/attack_hulk(mob/living/carbon/user)
	. = ..()
	var/obj/item/bodypart/arm = user.get_active_hand()
	if(!arm || arm.bodypart_disabled)
		return
	user.apply_damage(damage_deflection * 0.1, BRUTE, arm, wound_bonus = CANT_WOUND)

/obj/machinery/attack_robot(mob/user)
	if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON) && !isAdminGhostAI(user))
		return FALSE

	if(!Adjacent(user) || !can_buckle || !has_buckled_mobs()) //so that borgs (but not AIs, sadly (perhaps in a future PR?)) can unbuckle people from machines
		return _try_interact(user)

	if(length(buckled_mobs) <= 1)
		if(user_unbuckle_mob(buckled_mobs[1],user))
			return TRUE

	var/unbuckled = tgui_input_list(user, "РљРѕРіРѕ РІС‹ С…РѕС‚РёС‚Рµ РѕС‚СЃС‚РµРіРЅСѓС‚СЊ?", "РћС‚СЃС‚РµРіРёРІР°РЅРёРµ", sort_names(buckled_mobs))
	if(isnull(unbuckled))
		return FALSE
	if(user_unbuckle_mob(unbuckled,user))
		return TRUE

	return _try_interact(user)

/obj/machinery/attack_ai(mob/user)
	if(!(interaction_flags_machine & INTERACT_MACHINE_ALLOW_SILICON) && !isAdminGhostAI(user))
		return FALSE
	if(!user.has_faction(ROLE_SYNDICATE))
		if((ACCESS_SYNDICATE in req_access) || (ACCESS_SYNDICATE_LEADER in req_access) || (ACCESS_SYNDICATE in req_one_access) || (ACCESS_SYNDICATE_LEADER in req_one_access))
			return FALSE
		if((onSyndieBase() && loc != user))
			return FALSE
	if(iscyborg(user))// For some reason attack_robot doesn't work
		return attack_robot(user)
	return _try_interact(user)

/obj/machinery/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return
	update_last_used(user)

/obj/machinery/attackby_secondary(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return
	update_last_used(user)

/obj/machinery/base_item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) & COMPONENT_CANT_USE_MACHINE_TOOLS)
		return ITEM_INTERACT_BLOCKING

	//takes priority in case material container or other atoms that hook onto item interaction signals won't give it a chance
	if(istype(tool, /obj/item/storage/part_replacer))
		update_last_used(user)
		return tool.interact_with_atom(src, user, modifiers)

	. = ..()
	if(.)
		update_last_used(user)

/obj/machinery/_try_interact(mob/user)
	if((interaction_flags_machine & INTERACT_MACHINE_WIRES_IF_OPEN) && panel_open && (attempt_wire_interaction(user) == WIRE_INTERACTION_BLOCK))
		return TRUE
	if(SEND_SIGNAL(user, COMSIG_TRY_USE_MACHINE, src) & COMPONENT_CANT_USE_MACHINE_INTERACT)
		return TRUE
	return ..()

/obj/machinery/on_craft_completion(list/components, datum/crafting_recipe/current_recipe, atom/crafter)
	. = ..()
	RefreshParts()

/obj/machinery/proc/RefreshParts()
	SHOULD_CALL_PARENT(TRUE)
	//reset to baseline
	idle_power_usage = initial(idle_power_usage)
	active_power_usage = initial(active_power_usage)
	if(!component_parts || !component_parts.len)
		return
	var/parts_energy_rating = 0

	for(var/datum/stock_part/part in component_parts)
		parts_energy_rating += part.energy_rating()

	for(var/obj/item/stock_parts/part in component_parts)
		parts_energy_rating += part.energy_rating

	idle_power_usage = initial(idle_power_usage) * (1 + parts_energy_rating)
	active_power_usage = initial(active_power_usage) * (1 + parts_energy_rating)
	var/power_multiplier = get_cyberpunk_machine_power_multiplier()
	idle_power_usage *= power_multiplier
	active_power_usage *= power_multiplier
	update_current_power_usage()
	SEND_SIGNAL(src, COMSIG_MACHINERY_REFRESH_PARTS)

/**
 * Checks if the machine is in a state where it can be pried open with a crowbar,
 * which is used by the default crowbar pry open method.
 */
/obj/machinery/proc/can_crowbar_pry_open()
	PROTECTED_PROC(TRUE)
	return !state_open && !panel_open && !is_operational

/**
 * Default method for prying a machine open, setting it to open state
 *
 * * crowbar - The crowbar being used to pry the machine open.
 * You do not have to assert the crowbar is a crowbar, it is checked for you.
 * * close_after_pry - If TRUE, the machine will immediately close after being pried open. Defaults to FALSE.
 * Best used for machines that don't have a real open state, effectively making this proc a "dump contents on crowbar" action.
 * * open_density - If TRUE, the machine will be set to dense when pried open. Defaults to FALSE.
 * * closed_density - If TRUE, the machine will be set to dense when closed after being pried open. Defaults to TRUE.
 * Only applies if close_after_pry is TRUE.
 * * deconstruct_on_fail - If TRUE, runs default_deconstruction_crowbar if the machine cannot be pried open. Defaults to FALSE.
 *
 * Returns NONE on failure
 * Returns ITEM_INTERACT_SUCCESS on success
 */
/obj/machinery/proc/default_pry_open(
	mob/living/user,
	obj/item/crowbar,
	close_after_pry = FALSE,
	open_density = FALSE,
	closed_density = TRUE,
	deconstruct_on_fail = FALSE,
)
	PROTECTED_PROC(TRUE)

	if(crowbar.tool_behaviour != TOOL_CROWBAR)
		return NONE
	if(!can_crowbar_pry_open())
		return deconstruct_on_fail ? default_deconstruction_crowbar(user, crowbar) : ITEM_INTERACT_BLOCKING

	crowbar.play_tool_sound(src, 50)
	user.visible_message(span_notice("[capitalize(user.declent_ru(NOMINATIVE))] РІСЃРєСЂС‹РІР°РµС‚ [declent_ru(ACCUSATIVE)]."), span_notice("Р’С‹ РІСЃРєСЂС‹РІР°РµС‚Рµ [declent_ru(ACCUSATIVE)]."))
	open_machine(density_to_set = open_density)
	if (close_after_pry) //Should it immediately close after prying? (If not, it must be closed elsewhere)
		close_machine(density_to_set = closed_density)
	return ITEM_INTERACT_SUCCESS

/**
 * Checks if the machine is in a state where it can be deconstructed with a crowbar,
 * which is used by the default crowbar deconstruction method.
 */
/obj/machinery/proc/can_crowbar_deconstruct()
	PROTECTED_PROC(TRUE)
	return panel_open

/**
 * Default method of deconstructing a machine with a crowbar
 * Requires panel be open to work, unless ignore_panel is set to TRUE.
 *
 * * crowbar - The crowbar being used to deconstruct the machine.
 * You do not have to assert the crowbar is a crowbar, it is checked for you.
 *
 * Returns NONE on failure, or if custom_deconstruct is set to TRUE.
 * Returns ITEM_INTERACT_SUCCESS on success.
 */
/obj/machinery/proc/default_deconstruction_crowbar(mob/living/user, obj/item/crowbar)
	PROTECTED_PROC(TRUE)

	if(crowbar.tool_behaviour != TOOL_CROWBAR)
		return NONE
	if(!can_crowbar_deconstruct())
		return ITEM_INTERACT_BLOCKING

	if(!crowbar.use_tool(src, user, 2 SECONDS, volume = 50))
		return ITEM_INTERACT_BLOCKING
	// user.visible_message(span_notice("[user] deconstructs [src]."), span_notice("You deconstruct [src]."))
	deconstruct(TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/handle_deconstruct(disassembled = TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(obj_flags & NO_DEBRIS_AFTER_DECONSTRUCTION)
		dump_inventory_contents() //drop stuff we consider important
		return //Just delete us, no need to call anything else.

	on_deconstruction(disassembled)

	if(circuit)
		spawn_frame(disassembled)

	if(!LAZYLEN(component_parts))
		dump_contents() //drop everything inside us
		return //we don't have any parts.

	for(var/part in component_parts)
		if(istype(part, /datum/stock_part))
			var/datum/stock_part/datum_part = part
			new datum_part.physical_object_type(loc)
		else
			var/obj/item/obj_part = part
			component_parts -= part
			obj_part.forceMove(loc)
			if(istype(obj_part, /obj/item/circuitboard/machine))
				var/obj/item/circuitboard/machine/board = obj_part
				for(var/component in board.req_components) //loop through all stack components and spawn them
					if(!ispath(component, /obj/item/stack))
						continue
					var/obj/item/stack/stack_path = component
					var/stack_amount = board.req_components[component]
					if(disassembled && cyberpunk_last_deconstructor)
						stack_amount = cyberpunk_last_deconstructor.get_cyberpunk_structure_salvage_amount(src, stack_amount)
					if(disassembled)
						stack_amount = get_cyberpunk_machine_salvage_amount(stack_amount)
					new stack_path(loc, stack_amount)
	LAZYCLEARLIST(component_parts)
	cyberpunk_component_wear = null
	recalculate_cyberpunk_machine_wear()
	cyberpunk_last_deconstructor = null

	//drop everything inside us. we do this last to give machines a chance
	//to handle their contents before we dump them
	dump_contents()

/**
 * Spawns a frame where this machine is. If the machine was not disassmbled, the
 * frame is spawned damaged. If the frame couldn't exist on this turf, it's smashed
 * down to metal sheets.
 *
 * Arguments:
 * * disassembled - If FALSE, the machine was destroyed instead of disassembled and the frame spawns at reduced integrity.
 */
/obj/machinery/proc/spawn_frame(disassembled)
	var/obj/structure/frame/machine/new_frame = new /obj/structure/frame/machine(loc)

	new_frame.state = FRAME_STATE_WIRED

	// If the new frame shouldn't be able to fit here due to the turf being blocked, spawn the frame deconstructed.
	if(isturf(loc))
		var/turf/machine_turf = loc
		// We're spawning a frame before this machine is qdeleted, so we want to ignore it. We've also just spawned a new frame, so ignore that too.
		if(machine_turf.is_blocked_turf(TRUE, source_atom = new_frame, ignore_atoms = list(src)))
			new_frame.deconstruct(disassembled)
			return

	new_frame.update_appearance(UPDATE_ICON_STATE)
	. = new_frame
	new_frame.set_anchored(anchored)
	if(!disassembled)
		new_frame.update_integrity(new_frame.max_integrity * 0.5) //the frame is already half broken
	transfer_fingerprints_to(new_frame)

//CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery/proc/get_cyberpunk_machine_wear_multiplier()
	var/wear_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		wear_multiplier *= module.wear_multiplier
	return max(0.1, wear_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_power_multiplier()
	var/power_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		power_multiplier *= module.power_usage_multiplier
	return max(0.1, power_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_repair_multiplier()
	var/repair_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		repair_multiplier *= module.repair_multiplier
	return max(0.1, repair_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_tool_time_multiplier()
	var/tool_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		tool_multiplier *= module.tool_time_multiplier
	return max(0.1, tool_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_salvage_multiplier()
	var/salvage_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		salvage_multiplier *= module.salvage_multiplier
	return max(0.1, salvage_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_chem_speed_multiplier()
	var/chem_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		chem_multiplier *= module.chem_speed_multiplier
	return max(0.1, chem_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_chem_cost_multiplier()
	var/chem_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		chem_multiplier *= module.chem_cost_multiplier
	return max(0.1, chem_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_vending_stock_multiplier()
	var/vending_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		vending_multiplier *= module.vending_stock_multiplier
	return max(0.1, vending_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_apc_efficiency_multiplier()
	var/apc_multiplier = 1
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		apc_multiplier *= module.apc_efficiency_multiplier
	return max(0.1, apc_multiplier)

/obj/machinery/proc/get_cyberpunk_machine_salvage_amount(base_amount)
	return max(1, round(base_amount * get_cyberpunk_machine_salvage_multiplier()))

/obj/machinery/proc/get_cyberpunk_wearable_components()
	var/list/wearable_components = list()
	if(!component_parts)
		return wearable_components
	for(var/component in component_parts)
		wearable_components += component
	return wearable_components

/obj/machinery/proc/get_cyberpunk_component_name(component)
	if(istype(component, /datum/stock_part))
		var/datum/stock_part/stock_part = component
		return stock_part.name()
	if(istype(component, /obj/item))
		var/obj/item/item = component
		return item.name
	return "[component]"

/obj/machinery/proc/get_cyberpunk_component_type(component)
	if(istype(component, /datum/stock_part))
		return "[component]"
	if(istype(component, /obj/item))
		var/obj/item/item = component
		return "[item.type]"
	return "[component]"

/obj/machinery/proc/get_cyberpunk_component_wear(component)
	if(!cyberpunk_component_wear)
		return 0
	return cyberpunk_component_wear[component] || 0

/obj/machinery/proc/prune_cyberpunk_component_wear()
	if(!cyberpunk_component_wear)
		return
	var/list/wearable_components = get_cyberpunk_wearable_components()
	for(var/component in cyberpunk_component_wear)
		if(!(component in wearable_components))
			cyberpunk_component_wear -= component
	if(!length(cyberpunk_component_wear))
		cyberpunk_component_wear = null

/obj/machinery/proc/recalculate_cyberpunk_machine_wear()
	prune_cyberpunk_component_wear()
	var/highest_wear = 0
	if(!cyberpunk_component_wear)
		cyberpunk_machine_wear = highest_wear
		return highest_wear
	for(var/component in cyberpunk_component_wear)
		highest_wear = max(highest_wear, cyberpunk_component_wear[component])
	cyberpunk_machine_wear = highest_wear
	return highest_wear

/obj/machinery/proc/get_most_worn_cyberpunk_component()
	prune_cyberpunk_component_wear()
	var/best_component
	var/highest_wear = -1
	for(var/component in get_cyberpunk_wearable_components())
		var/component_wear = get_cyberpunk_component_wear(component)
		if(component_wear <= highest_wear)
			continue
		highest_wear = component_wear
		best_component = component
	return best_component

/obj/machinery/proc/get_least_worn_cyberpunk_component()
	prune_cyberpunk_component_wear()
	var/best_component
	var/lowest_wear = INFINITY
	for(var/component in get_cyberpunk_wearable_components())
		var/component_wear = get_cyberpunk_component_wear(component)
		if(component_wear >= lowest_wear)
			continue
		lowest_wear = component_wear
		best_component = component
	return best_component

/obj/machinery/proc/get_cyberpunk_failure_name()
	switch(cyberpunk_machine_failure_state)
		if("offline")
			return "offline"
		if("short")
			return "short circuit"
		if("jammed")
			return "jammed actuator"
		if("network")
			return "network loss"
		if("unsafe")
			return "unsafe mode"
	return "none"

/obj/machinery/proc/pick_cyberpunk_failure_state(source = null)
	if(source == "emp")
		return pick("offline", "short", "network")
	if(source == "hack" || source == "sabotage")
		return pick("network", "unsafe", "jammed")
	return pick("offline", "short", "jammed", "network", "unsafe")

/obj/machinery/proc/set_cyberpunk_failure_state(new_state, mob/living/user = null)
	if(cyberpunk_machine_failure_state == new_state)
		return FALSE
	cyberpunk_machine_failure_state = new_state
	cyberpunk_last_failure_actor = user
	if(new_state in list("offline", "jammed", "unsafe"))
		set_machine_stat(machine_stat | BROKEN)
	update_appearance()
	return TRUE

/obj/machinery/proc/clear_cyberpunk_failure_state()
	if(!cyberpunk_machine_failure_state)
		return FALSE
	cyberpunk_machine_failure_state = null
	cyberpunk_last_failure_actor = null
	if(cyberpunk_machine_wear < cyberpunk_machine_wear_limit)
		set_machine_stat(machine_stat & ~BROKEN)
	update_appearance()
	return TRUE

/obj/machinery/proc/trigger_cyberpunk_machine_failure(source = null, mob/living/user = null)
	if(cyberpunk_machine_failure_state)
		return FALSE
	var/failure_state = pick_cyberpunk_failure_state(source)
	if(!failure_state)
		return FALSE
	set_cyberpunk_failure_state(failure_state, user)
	if(user && prob(user.get_cyberpunk_machine_failure_mask_chance(src)))
		return TRUE
	visible_message(span_warning("[src] malfunctions: [get_cyberpunk_failure_name()]."))
	return TRUE

/obj/machinery/proc/handle_cyberpunk_machine_failure_interaction(mob/living/user)
	if(!cyberpunk_machine_failure_state)
		return FALSE
	switch(cyberpunk_machine_failure_state)
		if("short", "unsafe")
			var/shock_chance = round(cyberpunk_machine_failure_shock_chance * user.get_cyberpunk_machine_shock_multiplier(src))
			if(powered() && prob(shock_chance))
				shock(user, 100)
				return TRUE
		if("jammed")
			balloon_alert(user, "jammed")
			return TRUE
		if("offline")
			if(!panel_open)
				balloon_alert(user, "offline")
				return TRUE
	return FALSE

/obj/machinery/proc/apply_cyberpunk_machine_wear(amount = 1, source = null, mob/living/user = null)
	if(amount <= 0 || (resistance_flags & INDESTRUCTIBLE))
		return FALSE
	var/adjusted_amount = max(0, amount * cyberpunk_machine_wear_rate_multiplier * get_cyberpunk_machine_wear_multiplier())
	if(!adjusted_amount)
		return FALSE
	var/old_wear = recalculate_cyberpunk_machine_wear()
	var/target_component = get_least_worn_cyberpunk_component()
	if(target_component)
		LAZYINITLIST(cyberpunk_component_wear)
		cyberpunk_component_wear[target_component] = min(cyberpunk_machine_wear_limit, get_cyberpunk_component_wear(target_component) + adjusted_amount)
	else
		cyberpunk_machine_wear = min(cyberpunk_machine_wear_limit, cyberpunk_machine_wear + adjusted_amount)
	var/new_wear = target_component ? recalculate_cyberpunk_machine_wear() : cyberpunk_machine_wear
	if(uses_integrity && new_wear >= cyberpunk_machine_wear_damage_threshold && get_integrity() > 1)
		take_damage(min(get_integrity() - 1, max(1, round(adjusted_amount))), BURN, ENERGY, FALSE)
	if(new_wear >= cyberpunk_machine_wear_limit)
		trigger_cyberpunk_machine_failure(source, user)
	return new_wear != old_wear

/obj/machinery/proc/repair_cyberpunk_machine_wear(amount = 1, mob/living/user = null)
	if(amount <= 0)
		return FALSE
	var/old_wear = recalculate_cyberpunk_machine_wear()
	if(old_wear <= 0)
		return FALSE
	var/adjusted_amount = amount * get_cyberpunk_machine_repair_multiplier()
	var/target_component = get_most_worn_cyberpunk_component()
	if(target_component)
		cyberpunk_component_wear[target_component] = max(0, get_cyberpunk_component_wear(target_component) - adjusted_amount)
		if(cyberpunk_component_wear[target_component] <= 0)
			cyberpunk_component_wear -= target_component
	else
		cyberpunk_machine_wear = max(0, cyberpunk_machine_wear - adjusted_amount)
	var/new_wear = target_component ? recalculate_cyberpunk_machine_wear() : cyberpunk_machine_wear
	if(new_wear < cyberpunk_machine_wear_damage_threshold)
		clear_cyberpunk_failure_state()
	return new_wear != old_wear

/obj/machinery/proc/can_service_cyberpunk_component_with(obj/item/tool)
	return tool?.tool_behaviour in list(TOOL_WRENCH, TOOL_WELDER)

/obj/machinery/proc/service_cyberpunk_component(component, mob/living/user, obj/item/tool)
	if(!panel_open)
		to_chat(user, span_warning("Open the maintenance panel before servicing machine components."))
		return FALSE
	if(!can_service_cyberpunk_component_with(tool))
		to_chat(user, span_warning("Hold a wrench or welding tool to service machine components."))
		return FALSE
	if(!cyberpunk_component_wear || !cyberpunk_component_wear[component])
		return FALSE

	var/service_amount = user.get_cyberpunk_machine_service_amount(src, 10)
	var/service_delay = 2 SECONDS * user.get_cyberpunk_structure_time_multiplier(src, "repair") * tool.toolspeed * get_cyberpunk_machine_tool_time_multiplier()
	var/service_fuel_cost = tool.tool_behaviour == TOOL_WELDER ? 1 : 0
	if(!tool.tool_start_check(user, amount = service_fuel_cost))
		return FALSE
	tool.play_tool_sound(src, 40)
	if(service_delay && !do_after(user, service_delay, target = src))
		return FALSE
	if(service_fuel_cost && !tool.use(service_fuel_cost))
		return FALSE
	if(service_delay >= MIN_TOOL_SOUND_DELAY)
		tool.play_tool_sound(src, 40)

	cyberpunk_component_wear[component] = max(0, cyberpunk_component_wear[component] - (service_amount * get_cyberpunk_machine_repair_multiplier()))
	if(cyberpunk_component_wear[component] <= 0)
		cyberpunk_component_wear -= component
	recalculate_cyberpunk_machine_wear()
	if(cyberpunk_machine_wear < cyberpunk_machine_wear_damage_threshold)
		clear_cyberpunk_failure_state()
	to_chat(user, span_notice("You service [get_cyberpunk_component_name(component)] in [src]."))
	return TRUE

/obj/machinery/proc/can_install_cyberpunk_module(datum/cyberpunk_machine_module/module, mob/living/user)
	if(!module || length(cyberpunk_machine_modules) >= cyberpunk_machine_module_slots)
		return FALSE
	for(var/datum/cyberpunk_machine_module/installed_module as anything in cyberpunk_machine_modules)
		if(installed_module.id == module.id)
			return FALSE
	return module.can_install(src, user)

/obj/machinery/proc/install_cyberpunk_module(datum/cyberpunk_machine_module/module, mob/living/user, use_delay = FALSE)
	if(!can_install_cyberpunk_module(module, user))
		return FALSE
	if(use_delay)
		var/install_delay = 2 SECONDS
		if(user)
			install_delay *= user.get_cyberpunk_machine_module_time_multiplier(src)
		if(install_delay && !do_after(user, install_delay, target = src))
			return FALSE
	LAZYADD(cyberpunk_machine_modules, module)
	module.on_install(src, user)
	return TRUE

/obj/machinery/proc/extract_cyberpunk_module(module_id, mob/living/user)
	for(var/datum/cyberpunk_machine_module/module as anything in cyberpunk_machine_modules)
		if(module.id != module_id)
			continue
		module.on_remove(src, user)
		cyberpunk_machine_modules -= module
		return module
	return null

/obj/machinery/proc/remove_cyberpunk_module(module_id, mob/living/user)
	var/datum/cyberpunk_machine_module/module = extract_cyberpunk_module(module_id, user)
	if(module)
		qdel(module)
		return TRUE
	return FALSE

/obj/machinery/proc/open_cyberpunk_module_interface(mob/living/user)
	if(!istype(user))
		return FALSE
	if(QDELETED(cyberpunk_module_ui))
		cyberpunk_module_ui = null
	if(!cyberpunk_module_ui)
		cyberpunk_module_ui = new(src)
	cyberpunk_module_ui.ui_interact(user)
	return TRUE

/datum/cyberpunk_machine_module_interface
	var/obj/machinery/machine

/datum/cyberpunk_machine_module_interface/New(obj/machinery/new_machine)
	. = ..()
	machine = new_machine

/datum/cyberpunk_machine_module_interface/Destroy(force)
	machine = null
	return ..()

/datum/cyberpunk_machine_module_interface/ui_state(mob/user)
	return GLOB.physical_state

/datum/cyberpunk_machine_module_interface/ui_interact(mob/user, datum/tgui/ui)
	if(!machine || QDELETED(machine))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkMachineModules", "Machine modules")
		ui.open()

/datum/cyberpunk_machine_module_interface/proc/module_ui_data(datum/cyberpunk_machine_module/module)
	return list(
		"id" = module.id,
		"name" = module.name,
		"description" = module.description,
		"manufacturer" = module.manufacturer,
		"type" = "[module.type]",
		"power_usage_multiplier" = module.power_usage_multiplier,
		"wear_multiplier" = module.wear_multiplier,
		"tool_time_multiplier" = module.tool_time_multiplier,
		"repair_multiplier" = module.repair_multiplier,
		"salvage_multiplier" = module.salvage_multiplier,
		"integrity_bonus" = module.integrity_bonus,
		"chem_speed_multiplier" = module.chem_speed_multiplier,
		"chem_cost_multiplier" = module.chem_cost_multiplier,
		"vending_stock_multiplier" = module.vending_stock_multiplier,
		"apc_efficiency_multiplier" = module.apc_efficiency_multiplier,
	)

/datum/cyberpunk_machine_module_interface/ui_data(mob/user)
	var/list/data = list()
	if(!machine || QDELETED(machine))
		return data
	machine.recalculate_cyberpunk_machine_wear()
	data["machine"] = list(
		"name" = machine.name,
		"type" = "[machine.type]",
		"panel_open" = machine.panel_open,
		"wear" = round(machine.cyberpunk_machine_wear),
		"wear_limit" = machine.cyberpunk_machine_wear_limit,
		"wear_rate_multiplier" = machine.cyberpunk_machine_wear_rate_multiplier,
		"failure_state" = machine.get_cyberpunk_failure_name(),
		"module_slots" = machine.cyberpunk_machine_module_slots,
		"module_count" = length(machine.cyberpunk_machine_modules),
		"power_multiplier" = machine.get_cyberpunk_machine_power_multiplier(),
		"wear_multiplier" = machine.get_cyberpunk_machine_wear_multiplier(),
		"tool_time_multiplier" = machine.get_cyberpunk_machine_tool_time_multiplier(),
		"repair_multiplier" = machine.get_cyberpunk_machine_repair_multiplier(),
		"salvage_multiplier" = machine.get_cyberpunk_machine_salvage_multiplier(),
		"chem_speed_multiplier" = machine.get_cyberpunk_machine_chem_speed_multiplier(),
		"chem_cost_multiplier" = machine.get_cyberpunk_machine_chem_cost_multiplier(),
		"vending_stock_multiplier" = machine.get_cyberpunk_machine_vending_stock_multiplier(),
		"apc_efficiency_multiplier" = machine.get_cyberpunk_machine_apc_efficiency_multiplier(),
	)
	data["installed_modules"] = list()
	for(var/datum/cyberpunk_machine_module/module as anything in machine.cyberpunk_machine_modules)
		data["installed_modules"] += list(module_ui_data(module))
	data["catalog"] = list()
	for(var/module_type in cyberpunk_machine_module_catalog())
		var/datum/cyberpunk_machine_module/module = new module_type
		data["catalog"] += list(module_ui_data(module))
		qdel(module)
	data["components"] = list()
	var/component_index = 1
	for(var/component in machine.get_cyberpunk_wearable_components())
		var/component_wear = machine.get_cyberpunk_component_wear(component)
		data["components"] += list(list(
			"index" = component_index,
			"name" = machine.get_cyberpunk_component_name(component),
			"type" = machine.get_cyberpunk_component_type(component),
			"wear" = round(component_wear),
			"wear_limit" = machine.cyberpunk_machine_wear_limit,
		))
		component_index++
	var/mob/living/living_user = istype(user, /mob/living) ? user : null
	var/obj/item/held_item = istype(living_user) ? living_user.get_active_held_item() : null
	data["service_tool_ready"] = machine.panel_open && machine.can_service_cyberpunk_component_with(held_item)
	if(istype(held_item, /obj/item/cyberpunk_machine_module))
		var/obj/item/cyberpunk_machine_module/held_module_item = held_item
		var/datum/cyberpunk_machine_module/held_module = held_module_item.create_module_datum()
		data["held_module"] = module_ui_data(held_module)
		qdel(held_module)
	else
		data["held_module"] = null
	return data

/datum/cyberpunk_machine_module_interface/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!ui || ui.status != UI_INTERACTIVE)
		return TRUE
	if(!machine || QDELETED(machine))
		return TRUE
	var/mob/living/user = istype(ui.user, /mob/living) ? ui.user : null
	if(!istype(user) || !in_range(machine, user))
		return TRUE
	switch(action)
		if("install_held")
			if(!machine.panel_open)
				to_chat(user, span_warning("Open the maintenance panel before installing a machine module."))
				return TRUE
			var/obj/item/held_item = user.get_active_held_item()
			var/obj/item/cyberpunk_machine_module/held_module_item = held_item
			if(!istype(held_module_item))
				return TRUE
			var/datum/cyberpunk_machine_module/module = held_module_item.create_module_datum()
			if(machine.install_cyberpunk_module(module, user, TRUE))
				to_chat(user, span_notice("You install [module.name] into [machine]."))
				qdel(held_module_item)
			else
				to_chat(user, span_warning("This machine cannot accept that module."))
				qdel(module)
			return TRUE
		if("remove_module")
			if(!machine.panel_open)
				to_chat(user, span_warning("Open the maintenance panel before removing a machine module."))
				return TRUE
			var/datum/cyberpunk_machine_module/module = machine.extract_cyberpunk_module(params["module_id"], user)
			if(!module)
				return TRUE
			var/item_type = module.module_item_type
			var/obj/item/module_item = new item_type(machine.drop_location())
			user.put_in_hands(module_item)
			to_chat(user, span_notice("You remove [module.name] from [machine]."))
			qdel(module)
			return TRUE
		if("repair_component")
			var/component_index = text2num(params["component_index"])
			var/list/components = machine.get_cyberpunk_wearable_components()
			if(component_index < 1 || component_index > length(components))
				return TRUE
			var/component = components[component_index]
			if(!machine.cyberpunk_component_wear || !machine.cyberpunk_component_wear[component])
				return TRUE
			machine.service_cyberpunk_component(component, user, user.get_active_held_item())
			return TRUE
	return TRUE

//CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery/atom_break(damage_flag)
	. = ..()
	if(!(machine_stat & BROKEN))
		set_machine_stat(machine_stat | BROKEN)
		SEND_SIGNAL(src, COMSIG_MACHINERY_BROKEN, damage_flag)
		update_appearance()
		return TRUE

/obj/machinery/contents_explosion(severity, target)
	if(!occupant)
		return

	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += occupant
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += occupant
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += occupant

/obj/machinery/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == occupant)
		set_occupant(null)
		update_appearance()

	// The circuit should also be in component parts, so don't early return.
	if(gone == circuit)
		circuit = null
	if((gone in component_parts) && !QDELETED(src))
		component_parts -= gone
		if(cyberpunk_component_wear)
			cyberpunk_component_wear -= gone
			recalculate_cyberpunk_machine_wear()
		// It would be unusual for a component_part to be qdel'd ordinarily.
		deconstruct(FALSE)

/**
 * This should be called before mass qdeling components to make space for replacements.
 * If not done, things will go awry as Exited() destroys the machine when it detects
 * even a single component exiting the atom.
 */
/obj/machinery/proc/clear_components()
	if(!component_parts)
		return
	var/list/old_components = component_parts
	circuit = null
	component_parts = null
	cyberpunk_component_wear = null
	recalculate_cyberpunk_machine_wear()
	for(var/atom/atom_part in old_components)
		qdel(atom_part)

/**
 * Default method of opening a machine's maintenance panel with a screwdriver
 *
 * * user - The mob using the screwdriver
 * * screwdriver - The screwdriver being used to open the panel.
 * You do not have to assert the screwdriver is a screwdriver, it is checked for you.
 *
 * Returns NONE on failure
 * Returns ITEM_INTERACT_SUCCESS on success
 */
/obj/machinery/proc/default_deconstruction_screwdriver(mob/user, obj/item/screwdriver)
	if(screwdriver.tool_behaviour != TOOL_SCREWDRIVER)
		return NONE

	screwdriver.play_tool_sound(src, 50)
	toggle_panel_open()
	balloon_alert(user, "РїР°РЅРµР»СЊ РѕР±СЃР»СѓР¶РёРІР°РЅРёСЏ [panel_open ? "РѕС‚РєСЂС‹С‚Р°" : "Р·Р°РєСЂС‹С‚Р°"]")
	return ITEM_INTERACT_SUCCESS

/**
 * Default method of rotating a machine with a wrench
 * Requires panel to be opened to work.
 *
 * * user - The mob using the wrench
 * * wrench - The wrench being used to rotate the machine
 * You do not have to assert the wrench is a wrench, it is checked for you.
 *
 * Returns NONE on failure
 * Returns ITEM_INTERACT_SUCCESS on success
 */
/obj/machinery/proc/default_change_direction_wrench(mob/user, obj/item/wrench)
	if(!panel_open || wrench.tool_behaviour != TOOL_WRENCH)
		return NONE

	wrench.play_tool_sound(src, 50)
	setDir(turn(dir,-90))
	to_chat(user, span_notice("Р’С‹ РїРѕРІРѕСЂР°С‡РёРІР°РµС‚Рµ [declent_ru(ACCUSATIVE)]."))
	SEND_SIGNAL(src, COMSIG_MACHINERY_DEFAULT_ROTATE_WRENCH, user, wrench)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/proc/exchange_parts(mob/user, obj/item/storage/part_replacer/replacer_tool)
	if(!istype(replacer_tool) || !component_parts)
		return FALSE

	var/works_from_distance = istype(replacer_tool, /obj/item/storage/part_replacer/bluespace)
	if(!panel_open && !works_from_distance)
		to_chat(user, display_parts(user))
		return FALSE

	var/obj/item/circuitboard/machine/machine_board = locate(/obj/item/circuitboard/machine) in component_parts
	if(works_from_distance)
		to_chat(user, display_parts(user))
	if(!machine_board)
		return FALSE
	/**
	 * sorting is very important especially because we are breaking out when required part is found in the inner for loop
	 * if the rped first picked up a tier 3 part AND THEN a tier 4 part
	 * tier 3 would be installed and the loop would break and check for the next required component thus
	 * completly ignoring the tier 4 component inside
	 * we also ignore stack components inside the RPED cause we dont exchange that
	 */
	var/shouldplaysound = FALSE
	var/list/part_list = replacer_tool.get_sorted_parts(ignore_stacks = TRUE)
	if(!part_list.len)
		return FALSE
	for(var/primary_part_base in component_parts)
		//we exchanged all we could time to bail
		if(!part_list.len)
			break

		var/current_rating
		var/required_type

		//we dont exchange circuitboards cause thats dumb
		if(istype(primary_part_base, /obj/item/circuitboard))
			continue
		else if(istype(primary_part_base, /datum/stock_part))
			var/datum/stock_part/primary_stock_part = primary_part_base
			current_rating = primary_stock_part.tier
			required_type = primary_stock_part.physical_object_base_type
		else
			var/obj/item/primary_stock_part_item = primary_part_base
			current_rating = primary_stock_part_item.get_part_rating()
			for(var/design_type in machine_board.req_components)
				if(ispath(primary_stock_part_item.type, design_type))
					required_type = design_type
					break

		for(var/obj/item/secondary_part in part_list)
			if(!istype(secondary_part, required_type))
				continue
			// If it's a corrupt or rigged cell, attempting to send it through Bluespace could have unforeseen consequences.
			if(istype(secondary_part, /obj/item/stock_parts/power_store/cell) && works_from_distance)
				var/obj/item/stock_parts/power_store/cell/checked_cell = secondary_part
				// If it's rigged or corrupted, max the charge. Then explode it.
				if(checked_cell.try_explode(max_charge = TRUE))
					break
			if(secondary_part.get_part_rating() > current_rating)
				//store name of part incase we qdel it below
				var/secondary_part_name = secondary_part.declent_ru(ACCUSATIVE)
				if(replacer_tool.atom_storage.attempt_remove(secondary_part, src))
					if (istype(primary_part_base, /datum/stock_part))
						var/stock_part_datum = GLOB.stock_part_datums_per_object[secondary_part.type]
						if (isnull(stock_part_datum))
							CRASH("[secondary_part] ([secondary_part.type]) did not have a stock part datum (was trying to find [primary_part_base])")
						component_parts += stock_part_datum
						part_list -= secondary_part //have to manually remove cause we are no longer refering replacer_tool.contents
						qdel(secondary_part)
					else
						component_parts += secondary_part
						secondary_part.forceMove(src)
						part_list -= secondary_part //have to manually remove cause we are no longer refering replacer_tool.contents

				component_parts -= primary_part_base
				if(cyberpunk_component_wear)
					cyberpunk_component_wear -= primary_part_base
					recalculate_cyberpunk_machine_wear()

				var/obj/physical_part
				if (istype(primary_part_base, /datum/stock_part))
					var/datum/stock_part/stock_part_datum = primary_part_base
					var/physical_object_type = stock_part_datum.physical_object_type
					physical_part = new physical_object_type
				else
					physical_part = primary_part_base

				replacer_tool.atom_storage.attempt_insert(physical_part, user, TRUE, force = STORAGE_SOFT_LOCKED)
				to_chat(user, span_notice("[capitalize(physical_part.declent_ru(NOMINATIVE))] Р·Р°РјРµРЅСЏРµС‚СЃСЏ РЅР° [secondary_part_name]."))
				shouldplaysound = TRUE //Only play the sound when parts are actually replaced!
				break

	RefreshParts()

	if(shouldplaysound)
		replacer_tool.play_rped_effect()
	return TRUE

/obj/machinery/proc/display_parts(mob/user)
	var/list/part_count = list()

	for(var/component_part in component_parts)
		var/obj/item/component_ref

		if (istype(component_part, /datum/stock_part))
			var/datum/stock_part/stock_part = component_part
			component_ref = stock_part.physical_object_reference
		else
			component_ref = component_part
			for(var/obj/item/counted_part in part_count)
				//e.g. 2 beakers though they have the same type are still 2 different objects so component_ref wont keep them unique so we look for that type ourselves and increment it
				if(istype(counted_part, component_ref.type))
					part_count[counted_part]++
					component_ref = null
					break
			//looks like we already counted an type of this obj reference, time to bail
			if(!component_ref)
				continue

		if(part_count[component_ref])
			part_count[component_ref]++
			continue
		part_count[component_ref] = 1

		// we infer the required stack stuff inside the machine from the circuitboards requested components
		if(istype(component_ref, /obj/item/circuitboard/machine))
			var/obj/item/circuitboard/machine/board = component_ref
			for(var/component in board.req_components)
				if(!ispath(component, /obj/item/stack))
					continue
				part_count[component] = board.req_components[component]


	var/text = span_notice("Р’РЅСѓС‚СЂРё РёРјРµСЋС‚СЃСЏ СЃР»РµРґСѓСЋС‰РёРµ РєРѕРјРїРѕРЅРµРЅС‚С‹:")
	for(var/component_part in part_count)
		var/part_name
		var/icon/html_icon
		var/icon_state
		//infer name & icon of part. stacks are just type paths so we have to get their initial values
		if(ispath(component_part, /obj/item/stack))
			var/obj/item/stack/stack_ref = component_part
			part_name = declent_ru_initial(stack_ref::name, NOMINATIVE, stack_ref::singular_name)
			html_icon = initial(stack_ref.icon)
			icon_state = initial(stack_ref.icon_state)
		else
			var/obj/item/part = component_part
			part_name = part.declent_ru(NOMINATIVE)
			html_icon = part.icon
			icon_state = part.icon_state
		//merge icon & name into text
		text += span_notice("[icon2html(html_icon, user, icon_state)] [part_count[component_part]] [part_name].")

	return text

/obj/machinery/examine(mob/user)
	. = ..()
	if(machine_stat & BROKEN)
		. += span_notice("Р’С‹РіР»СЏРґРёС‚ СЃР»РѕРјР°РЅРѕ Рё РЅРµС„СѓРЅРєС†РёРѕРЅР°Р»СЊРЅРѕ.")
	if(!(resistance_flags & INDESTRUCTIBLE))
		var/healthpercent = (atom_integrity/max_integrity) * 100
		switch(healthpercent)
			if(50 to 99)
				. += "РРјРµРµС‚ РЅРµР·РЅР°С‡РёС‚РµР»СЊРЅС‹Рµ РїРѕРІСЂРµР¶РґРµРЅРёСЏ."
			if(25 to 50)
				. += "РРјРµРµС‚ Р·РЅР°С‡РёС‚РµР»СЊРЅС‹Рµ РїРѕРІСЂРµР¶РґРµРЅРёСЏ."
			if(0 to 25)
				. += span_warning("Р Р°Р·РІР°Р»РёРІР°РµС‚СЃСЏ РЅР° С‡Р°СЃС‚Рё!")

/obj/machinery/examine_descriptor(mob/user)
	return "РјР°С€РёРЅР°"

/obj/machinery/examine_more(mob/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER) && component_parts)
		. += display_parts(user)

//called on machinery construction (i.e from frame to machinery) but not on initialization
/obj/machinery/proc/on_construction(mob/user)
	return

/**
 * called on deconstruction before the final deletion
 * Arguments
 *
 * * disassembled - if TRUE means we used tools to deconstruct it, FALSE means it got destroyed by other means
 */
/obj/machinery/proc/on_deconstruction(disassembled)
	PROTECTED_PROC(TRUE)
	return

/obj/machinery/zap_act(power, zap_flags)
	if(prob(85) && (zap_flags & ZAP_MACHINE_EXPLOSIVE) && !(resistance_flags & INDESTRUCTIBLE))
		explosion(src, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, flame_range = 2, adminlog = TRUE, smoke = FALSE)
	else if(zap_flags & ZAP_OBJ_DAMAGE)
		take_damage(power * 2.5e-4, BURN, ENERGY)
		if(prob(40))
			emp_act(EMP_LIGHT)
		power -= power * 5e-4
	return ..()

/obj/machinery/proc/adjust_item_drop_location(atom/movable/dropped_atom) // Adjust item drop location to a 3x3 grid inside the tile, returns slot id from 0 to 8
	var/md5 = md5(dropped_atom.name) // Oh, and it's deterministic too. A specific item will always drop from the same slot.
	for (var/i in 1 to 32)
		. += hex2num(md5[i])
	. = . % 9
	dropped_atom.pixel_x = -8 + ((.%3)*8)
	dropped_atom.pixel_y = -8 + (round( . / 3)*8)

/obj/machinery/rust_heretic_act(rust_strength)
	var/damage = 500 + rust_strength * 200
	take_damage(damage, BRUTE, BOMB, 1)

/obj/machinery/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, occupant))
		set_occupant(vval)
		datum_flags |= DF_VAR_EDITED
		return TRUE
	if(vname == NAMEOF(src, machine_stat))
		set_machine_stat(vval)
		datum_flags |= DF_VAR_EDITED
		return TRUE

	return ..()

/**
 * Alerts the AI that a hack is in progress.
 *
 * Sends all AIs a message that a hack is occurring.  Specifically used for space ninja tampering as this proc was originally in the ninja files.
 * However, the proc may also be used elsewhere.
 */
/obj/machinery/proc/AI_notify_hack()
	var/alertstr = span_userdanger("РЎРµС‚РµРІР°СЏ С‚СЂРµРІРѕРіР°: РћР±РЅР°СЂСѓР¶РµРЅР° РїРѕРїС‹С‚РєР° РІР·Р»РѕРјР°[get_area(src)?" РІ [get_area_name(src, TRUE)]":". РќРµРІРѕР·РјРѕР¶РЅРѕ РѕРїСЂРµРґРµР»РёС‚СЊ РјРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёРµ"].")
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		to_chat(AI, alertstr)

/obj/machinery/proc/update_last_used(mob/user)
	if(isliving(user))
		var/mob/living/living_user = user
		if(world.time > last_used_time)
			living_user.apply_cyberpunk_machine_wear(src, cyberpunk_machine_wear_per_use, "use")
		last_used_time = world.time
		last_user_mobtype = user.type

/// Called if this machine is supposed to be a sabotage machine objective.
/obj/machinery/proc/add_as_sabotage_target()
	return

// CYBERPUNK BUILD - rebuild and delete before release
/obj/machinery/cyberpunk_wardrobe
	name = "wardrobe"
	desc = "A city wardrobe terminal. It stores modular clothing visuals and material signatures for later extraction."
	icon = 'icons/obj/machines/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/cyberpunk_wardrobe/ui_interact(mob/user, datum/tgui/ui)
	var/datum/cyberpunk_style_designer_ui/interface = new("wardrobe")
	interface.ui_interact(user, ui)

/obj/machinery/cyberpunk_wardrobe/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/machinery/cyberpunk_wardrobe/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	var/obj/item/clothing/clothing = weapon
	if(!istype(clothing))
		return ..()
	var/mob/living/living_user = user
	if(!istype(living_user))
		return ..()
	if(!clothing.cyberpunk_is_modular_clothing())
		to_chat(user, span_warning("[src] refuses non-modular or unique clothing."))
		return TRUE
	if(weapon != living_user.get_active_held_item())
		to_chat(user, span_warning("Hold [weapon] in your active hand before storing it."))
		return TRUE
	to_chat(user, span_notice(living_user.cyberpunk_store_active_clothing_in_wardrobe()))
	return TRUE
// CYBERPUNK BUILD - rebuild and delete before release
