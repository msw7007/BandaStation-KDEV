// Cyberpunk 13 cyberspace: ICE datums and hacking session.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/datum/cyber_ice
	/// Firewall model. It fixes total ICE level; tuning only redistributes points.
	var/model = CYBER_ICE_MODEL_BASIC
	/// Human-readable firewall model label for UI.
	var/model_name = "Basic ICE"
	/// V ice: detection timer pressure.
	var/timer_points = NEURAL_INTERFACE_DEFAULT_ICE_STAT
	/// B ice: hacking grid size pressure.
	var/size_points = NEURAL_INTERFACE_DEFAULT_ICE_STAT
	/// A ice: required sequence length pressure.
	var/sequence_points = NEURAL_INTERFACE_DEFAULT_ICE_STAT
	/// Protection reserve pressure.
	var/reserve_points = NEURAL_INTERFACE_DEFAULT_ICE_STAT
	/// Current reserve left before this ice is considered breached.
	var/current_reserve
	/// Whether this ice has raised an alarm during the current attack window.
	var/alarm_triggered = FALSE

/datum/cyber_ice/New()
	. = ..()
	current_reserve = get_max_reserve()

/datum/cyber_ice/proc/configure_model(new_model)
	switch(new_model)
		if(CYBER_ICE_MODEL_MK2)
			model = CYBER_ICE_MODEL_MK2
			model_name = "MK2 civilian ICE"
			set_even_distribution(12)
		if(CYBER_ICE_MODEL_CORPORATE)
			model = CYBER_ICE_MODEL_CORPORATE
			model_name = "Corporate reinforced ICE"
			set_even_distribution(16)
		if(CYBER_ICE_MODEL_IMPROVED)
			model = CYBER_ICE_MODEL_IMPROVED
			model_name = "Improved ICE"
			set_even_distribution(20)
		else
			model = CYBER_ICE_MODEL_BASIC
			model_name = "Basic ICE"
			set_even_distribution(8)
	current_reserve = get_max_reserve()
	return TRUE

/datum/cyber_ice/proc/get_total_points()
	return max(0, timer_points + size_points + sequence_points + reserve_points)

/datum/cyber_ice/proc/get_level()
	return FLOOR(get_total_points() / 4, 1)

/datum/cyber_ice/proc/get_chromity_penalty()
	return get_total_points()

/datum/cyber_ice/proc/get_timer_duration(hacking_skill = 0, infinite_timer = FALSE)
	if(infinite_timer)
		return INFINITY
	return max(NEURAL_INTERFACE_MIN_TIMER, NEURAL_INTERFACE_BASE_TIMER - (timer_points * NEURAL_INTERFACE_TIMER_STEP) + (hacking_skill * NEURAL_INTERFACE_HACKING_TIMER_STEP))

/datum/cyber_ice/proc/get_node_timer_duration(object_count, hacking_skill = 0)
	return max(NEURAL_INTERFACE_MIN_TIMER, ((max(0, object_count - 10)) SECONDS) - (timer_points * NEURAL_INTERFACE_TIMER_STEP) + (hacking_skill * NEURAL_INTERFACE_HACKING_TIMER_STEP))

/datum/cyber_ice/proc/get_grid_size(hacking_skill = 0, is_node = FALSE)
	var/reduction = is_node ? 0 : hacking_skill
	return clamp(NEURAL_INTERFACE_MIN_GRID + size_points - reduction, NEURAL_INTERFACE_MIN_GRID, NEURAL_INTERFACE_MAX_GRID)

/datum/cyber_ice/proc/get_node_grid_size(object_count)
	var/grid_size = max(NEURAL_INTERFACE_MIN_GRID, round(sqrt(max(1, object_count))))
	while(grid_size * grid_size < object_count)
		grid_size++
	return clamp(grid_size, NEURAL_INTERFACE_MIN_GRID, NEURAL_INTERFACE_MAX_GRID)

/datum/cyber_ice/proc/get_sequence_length(hacking_skill = 0, grid_size = NEURAL_INTERFACE_MIN_GRID)
	var/max_cells = grid_size * grid_size
	return clamp(NEURAL_INTERFACE_MIN_SEQUENCE + sequence_points - hacking_skill, NEURAL_INTERFACE_MIN_SEQUENCE, min(NEURAL_INTERFACE_MAX_SEQUENCE, max_cells))

/datum/cyber_ice/proc/get_node_sequence_length(object_count, hacking_skill = 0)
	var/grid_size = get_node_grid_size(object_count)
	var/max_cells = grid_size * grid_size
	return clamp(round(sqrt(max(1, object_count)) * 1.5) - hacking_skill, NEURAL_INTERFACE_MIN_SEQUENCE, min(NEURAL_INTERFACE_MAX_SEQUENCE, max_cells))

/datum/cyber_ice/proc/get_max_reserve()
	return clamp(NEURAL_INTERFACE_BASE_RESERVE + (get_level() * NEURAL_INTERFACE_RESERVE_PER_LEVEL), 0, NEURAL_INTERFACE_MAX_RESERVE)

/datum/cyber_ice/proc/set_distribution(timer, size, sequence, reserve, max_points = 0)
	timer = max(0, round(timer))
	size = max(0, round(size))
	sequence = max(0, round(sequence))
	reserve = max(0, round(reserve))
	if(max_points && (timer + size + sequence + reserve) > max_points)
		return FALSE
	timer_points = timer
	size_points = size
	sequence_points = sequence
	reserve_points = reserve
	current_reserve = min(current_reserve || get_max_reserve(), get_max_reserve())
	return TRUE

/datum/cyber_ice/proc/set_even_distribution(total_points)
	total_points = max(0, round(total_points))
	var/base_points = FLOOR(total_points / 4, 1)
	var/remainder = total_points - (base_points * 4)
	return set_distribution(
		base_points + (remainder >= 1),
		base_points + (remainder >= 2),
		base_points + (remainder >= 3),
		base_points,
		total_points,
	)

/datum/cyber_ice/proc/apply_reserve_damage(amount)
	if(amount <= 0)
		return 0
	var/old_reserve = current_reserve
	current_reserve = max(0, current_reserve - amount)
	return old_reserve - current_reserve

/datum/cyber_ice/proc/is_breached()
	return current_reserve <= 0

/datum/cyber_ice/proc/restore_reserve(amount)
	if(amount <= 0)
		return 0
	var/old_reserve = current_reserve
	current_reserve = min(get_max_reserve(), current_reserve + amount)
	return current_reserve - old_reserve

/datum/cyber_ice/proc/reset_alarm()
	alarm_triggered = FALSE

/datum/cyber_ice/proc/trigger_alarm(mob/living/source, atom/target, reason = "bad sequence")
	if(alarm_triggered)
		return FALSE
	alarm_triggered = TRUE
	if(source)
		to_chat(source, span_warning("ICE alarm triggered: [reason]."))
	if(target)
		target.visible_message(span_warning("[target] reports: intrusion detected."))
	if(source && target)
		source.visible_message(span_danger("A red intrusion ping links [source] to [target]."), span_danger("A red intrusion ping exposes your connection to [target]."))
		source.Beam(target, icon_state = "rped_upgrade", time = 2 SECONDS, beam_color = "#ff334a")
	return TRUE

/datum/cyber_ice/proc/get_attack_timer(hacking_skill = 0, is_node = FALSE, object_count = 0, infinite_timer = FALSE)
	if(is_node)
		return get_node_timer_duration(object_count, hacking_skill)
	return get_timer_duration(hacking_skill, infinite_timer)

/datum/cyber_ice/proc/get_attack_grid_size(hacking_skill = 0, is_node = FALSE, object_count = 0)
	if(is_node)
		return get_node_grid_size(object_count)
	return get_grid_size(hacking_skill)

/datum/cyber_ice/proc/get_attack_sequence_length(hacking_skill = 0, grid_size = NEURAL_INTERFACE_MIN_GRID, is_node = FALSE, object_count = 0)
	if(is_node)
		return get_node_sequence_length(object_count, hacking_skill)
	return get_sequence_length(hacking_skill, grid_size)

/datum/cyber_ice_configurator
	/// Neural interface being configured.
	var/datum/weakref/interface_ref
	/// Patient body that owns the interface.
	var/datum/weakref/patient_ref

/datum/cyber_ice_configurator/New(obj/item/organ/cyberimp/brain/neural_interface/interface, mob/living/patient)
	. = ..()
	if(interface)
		interface_ref = WEAKREF(interface)
	if(patient)
		patient_ref = WEAKREF(patient)

/datum/cyber_ice_configurator/proc/get_interface() as /obj/item/organ/cyberimp/brain/neural_interface
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = interface_ref?.resolve()
	return istype(interface) ? interface : null

/datum/cyber_ice_configurator/proc/get_patient() as /mob/living
	var/mob/living/patient = patient_ref?.resolve()
	return istype(patient) ? patient : null

/datum/cyber_ice_configurator/ui_state(mob/user)
	return GLOB.always_state

/datum/cyber_ice_configurator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberIceConfig", "Neural ICE tuning")
		ui.open()

/datum/cyber_ice_configurator/ui_close(mob/user)
	qdel(src)

/datum/cyber_ice_configurator/ui_data(mob/user)
	var/list/data = list()
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = get_interface()
	var/mob/living/patient = get_patient()
	if(!interface)
		data["missing"] = TRUE
		return data
	var/datum/cyber_ice/ice = interface.get_ice()
	data["patient_name"] = patient?.real_name || patient?.name || "unknown"
	data["model"] = ice.model
	data["model_name"] = ice.model_name
	data["timer"] = ice.timer_points
	data["size"] = ice.size_points
	data["sequence"] = ice.sequence_points
	data["reserve"] = ice.reserve_points
	data["total"] = ice.get_total_points()
	data["level"] = ice.get_level()
	data["chromity_penalty"] = ice.get_chromity_penalty()
	data["effective_chromity"] = patient?.get_effective_chromity() || 0
	data["max_reserve"] = ice.get_max_reserve()
	data["current_reserve"] = ice.current_reserve
	data["timer_seconds"] = ice.get_timer_duration(0) / 10
	data["grid_size"] = ice.get_grid_size(0)
	data["sequence_length"] = ice.get_sequence_length(0, ice.get_grid_size(0))
	return data

/datum/cyber_ice_configurator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		return
	var/obj/item/organ/cyberimp/brain/neural_interface/interface = get_interface()
	if(!interface)
		return FALSE
	var/datum/cyber_ice/ice = interface.get_ice()
	switch(action)
		if("set_distribution")
			var/timer = text2num("[params["timer"]]")
			var/size = text2num("[params["size"]]")
			var/sequence = text2num("[params["sequence"]]")
			var/reserve = text2num("[params["reserve"]]")
			var/total_points = ice.get_total_points()
			if(round(timer) + round(size) + round(sequence) + round(reserve) != total_points)
				to_chat(ui.user, span_warning("ICE configuration rejected: point total must remain [total_points]."))
				return TRUE
			if(!interface.set_ice_distribution(timer, size, sequence, reserve))
				to_chat(ui.user, span_warning("ICE configuration rejected."))
				return TRUE
			to_chat(ui.user, span_notice("Neural ICE redistributed. Effective chromity is now [round(get_patient()?.get_effective_chromity() || 0, 0.1)]."))
			SStgui.update_uis(src)
			return TRUE
		if("restore")
			ice.restore_reserve(ice.get_max_reserve())
			ice.reset_alarm()
			to_chat(ui.user, span_notice("Neural ICE reserve restored and alarm state cleared."))
			SStgui.update_uis(src)
			return TRUE
		if("set_model")
			var/model = params["model"]
			if(!(model in list(CYBER_ICE_MODEL_BASIC, CYBER_ICE_MODEL_MK2, CYBER_ICE_MODEL_CORPORATE, CYBER_ICE_MODEL_IMPROVED)))
				return TRUE
			interface.set_ice_model(model)
			to_chat(ui.user, span_notice("Neural ICE model changed. Retune the distribution if needed."))
			SStgui.update_uis(src)
			return TRUE
	return FALSE

/datum/cyber_ice/proc/generate_hex_pool()
	var/list/pool = list()
	var/list/generated_values = list()
	while(length(pool) < CYBER_ICE_HEX_POOL_SIZE)
		var/generated = generate_hex_number()
		if(generated_values[generated])
			continue
		generated_values[generated] = TRUE
		pool += generated
	return pool

/datum/cyber_ice/proc/generate_hex_number()
	var/static/list/hex_symbols = list("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
	var/generated = ""
	for(var/symbol_index in 1 to 2)
		generated += pick(hex_symbols)
	return generated

/datum/cyber_ice/proc/generate_grid_values(grid_size, list/hex_pool)
	var/list/grid_values = list()
	var/cell_count = grid_size * grid_size
	for(var/cell_index in 1 to cell_count)
		grid_values += pick(hex_pool)
	return grid_values

/datum/cyber_ice/proc/generate_sequences(list/grid_values, sequence_length, sequence_count, grid_size = NEURAL_INTERFACE_MIN_GRID)
	var/list/generated_sequences = list()
	if(!length(grid_values))
		return generated_sequences
	sequence_length = clamp(round(sequence_length), 1, length(grid_values))
	sequence_count = clamp(round(sequence_count), 1, CYBER_ICE_MAX_SEQUENCE_COUNT)
	for(var/sequence_index in 1 to sequence_count)
		var/list/sequence = list()
		var/list/used_indexes = list()
		var/current_index = rand(1, length(grid_values))
		var/next_axis = "vertical"
		for(var/value_index in 1 to sequence_length)
			sequence += grid_values[current_index]
			used_indexes += "[current_index]"
			if(value_index >= sequence_length)
				break
			var/list/next_indexes = get_trace_indexes(current_index, grid_size, next_axis, used_indexes)
			if(!length(next_indexes))
				next_indexes = get_trace_indexes(current_index, grid_size, next_axis, list())
			current_index = pick(next_indexes)
			next_axis = next_axis == "vertical" ? "horizontal" : "vertical"
		generated_sequences += list(sequence)
	return generated_sequences

/datum/cyber_ice/proc/get_trace_indexes(current_index, grid_size, axis, list/excluded_indexes)
	var/list/trace_indexes = list()
	var/current_row = CEILING(current_index / grid_size, 1)
	var/current_column = ((current_index - 1) % grid_size) + 1
	for(var/candidate_index in 1 to grid_size * grid_size)
		if("[candidate_index]" in excluded_indexes)
			continue
		var/candidate_row = CEILING(candidate_index / grid_size, 1)
		var/candidate_column = ((candidate_index - 1) % grid_size) + 1
		if(axis == "vertical" && candidate_column == current_column)
			trace_indexes += candidate_index
		else if(axis == "horizontal" && candidate_row == current_row)
			trace_indexes += candidate_index
	return trace_indexes

/datum/cyber_ice/proc/get_sequence_count_for_skill(hacking_skill)
	return clamp(max(1, round(hacking_skill)), 1, CYBER_ICE_MAX_SEQUENCE_COUNT)

/datum/cyber_ice/proc/get_sequence_damage(completed_sequences, hacking_skill)
	completed_sequences = max(0, round(completed_sequences))
	if(completed_sequences <= 0)
		return 0
	return completed_sequences * max(1, round(hacking_skill))

/datum/cyber_ice/proc/get_ui_summary(hacking_skill = 0, is_node = FALSE, object_count = 0)
	var/grid_size = get_attack_grid_size(hacking_skill, is_node, object_count)
	return list(
		"model" = model,
		"model_name" = model_name,
		"timer" = get_attack_timer(hacking_skill, is_node, object_count),
		"grid_size" = grid_size,
		"sequence_length" = get_attack_sequence_length(hacking_skill, grid_size, is_node, object_count),
		"sequence_count" = get_sequence_count_for_skill(hacking_skill),
		"reserve" = current_reserve,
		"max_reserve" = get_max_reserve(),
		"timer_points" = timer_points,
		"size_points" = size_points,
		"sequence_points" = sequence_points,
		"reserve_points" = reserve_points,
		"total_points" = get_total_points(),
		"level" = get_level(),
		"breached" = is_breached(),
		"alarm" = alarm_triggered,
	)

/datum/cyber_ice_hack_session
	/// Actor performing this intrusion.
	var/mob/living/hacker
	/// ICE being attacked.
	var/datum/cyber_ice/ice
	/// Physical or virtual thing represented by this ICE.
	var/atom/target
	var/hacking_skill = 0
	var/is_node = FALSE
	var/object_count = 0
	var/grid_size = NEURAL_INTERFACE_MIN_GRID
	var/sequence_length = NEURAL_INTERFACE_MIN_SEQUENCE
	var/sequence_count = 1
	var/time_limit = 0
	var/started_at = 0
	var/list/hex_pool = list()
	var/list/grid_values = list()
	var/list/sequences = list()
	var/list/selected_indexes = list()
	var/list/selected_values = list()
	var/list/completed_sequence_indexes = list()
	var/list/completed_sequences = list()
	var/list/sequence_progress = list()
	var/list/decoy_indexes = list()
	var/alarm_risk = 0
	var/last_index = 0
	/// null before first click, then "vertical" and "horizontal" alternate.
	var/next_axis
	var/closed = FALSE

/datum/cyber_ice_hack_session/New(mob/living/hacker, datum/cyber_ice/ice, atom/target, hacking_skill = 0, is_node = FALSE, object_count = 0)
	. = ..()
	src.hacker = hacker
	src.ice = ice
	src.target = target
	src.hacking_skill = max(0, round(hacking_skill))
	src.is_node = is_node
	src.object_count = max(0, round(object_count))
	build_session()

/datum/cyber_ice_hack_session/Destroy(force)
	hacker = null
	ice = null
	target = null
	hex_pool = null
	grid_values = null
	sequences = null
	selected_indexes = null
	selected_values = null
	completed_sequence_indexes = null
	completed_sequences = null
	sequence_progress = null
	decoy_indexes = null
	return ..()

/datum/cyber_ice_hack_session/proc/build_session()
	if(!ice)
		return
	ice.reset_alarm()
	grid_size = ice.get_attack_grid_size(hacking_skill, is_node, object_count)
	sequence_length = ice.get_attack_sequence_length(hacking_skill, grid_size, is_node, object_count)
	sequence_count = ice.get_sequence_count_for_skill(hacking_skill)
	time_limit = ice.get_attack_timer(hacking_skill, is_node, object_count)
	started_at = world.time
	hex_pool = ice.generate_hex_pool()
	grid_values = ice.generate_grid_values(grid_size, hex_pool)
	generate_new_sequences()
	if(time_limit && time_limit < INFINITY)
		addtimer(CALLBACK(src, PROC_REF(check_time_alarm)), time_limit)

/datum/cyber_ice_hack_session/proc/generate_new_sequences()
	sequences = ice.generate_sequences(grid_values, sequence_length, sequence_count, grid_size)
	completed_sequence_indexes = list()
	completed_sequences = list()
	sequence_progress = list()
	for(var/sequence_index in 1 to length(sequences))
		sequence_progress["[sequence_index]"] = 0
	generate_decoy_indexes()
	alarm_risk = 0
	reset_selection(FALSE)

/datum/cyber_ice_hack_session/proc/generate_decoy_indexes()
	decoy_indexes = list()
	var/list/candidate_indexes = list()
	for(var/cell_index in 1 to length(grid_values))
		if(value_exists_in_any_sequence(grid_values[cell_index]))
			continue
		candidate_indexes += cell_index
	var/decoy_count = min(length(candidate_indexes), max(1, round(length(grid_values) * 0.08)))
	for(var/decoy_number in 1 to decoy_count)
		var/cell_index = pick_n_take(candidate_indexes)
		decoy_indexes += "[cell_index]"

/datum/cyber_ice_hack_session/proc/remaining_time()
	if(!time_limit || time_limit >= INFINITY)
		return null
	return max(0, (started_at + time_limit - world.time) / (1 SECONDS))

/datum/cyber_ice_hack_session/proc/check_time_alarm()
	if(closed || !ice || ice.is_breached())
		return
	if(remaining_time() <= 0)
		ice.trigger_alarm(hacker, target, "connection timer expired")
		SStgui.update_uis(src)

/datum/cyber_ice_hack_session/proc/select_cell(cell_index)
	if(closed || !ice || ice.is_breached())
		return FALSE
	var/time_remaining = remaining_time()
	if(!isnull(time_remaining) && time_remaining <= 0)
		ice.trigger_alarm(hacker, target, "connection timer expired")
	cell_index = text2num("[cell_index]")
	if(isnull(cell_index))
		return FALSE
	cell_index = round(cell_index)
	if(cell_index < 1 || cell_index > length(grid_values))
		return FALSE
	if("[cell_index]" in selected_indexes)
		return FALSE
	if(last_index && !is_valid_next_cell(cell_index))
		ice.trigger_alarm(hacker, target, "invalid trace direction")
		return TRUE
	var/selected_value = grid_values[cell_index]
	selected_indexes += "[cell_index]"
	selected_values += selected_value
	last_index = cell_index
	next_axis = next_axis == "vertical" ? "horizontal" : "vertical"
	if(length(selected_values) == 1)
		next_axis = "horizontal"
	var/advanced_sequences = advance_sequences_with_value(selected_value)
	if(!advanced_sequences)
		roll_noise_alarm(cell_index)
	SStgui.update_uis(src)
	return TRUE

/datum/cyber_ice_hack_session/proc/is_valid_next_cell(cell_index)
	var/last_row = CEILING(last_index / grid_size, 1)
	var/last_column = ((last_index - 1) % grid_size) + 1
	var/new_row = CEILING(cell_index / grid_size, 1)
	var/new_column = ((cell_index - 1) % grid_size) + 1
	if(next_axis == "vertical")
		return new_column == last_column
	if(next_axis == "horizontal")
		return new_row == last_row
	return TRUE

/datum/cyber_ice_hack_session/proc/value_is_in_any_sequence(value)
	for(var/sequence_index in 1 to length(sequences))
		if(is_sequence_index_completed(sequence_index))
			continue
		var/list/sequence = sequences[sequence_index]
		if(value in sequence)
			return TRUE
	return FALSE

/datum/cyber_ice_hack_session/proc/value_exists_in_any_sequence(value)
	for(var/list/sequence as anything in sequences)
		if(value in sequence)
			return TRUE
	return FALSE

/datum/cyber_ice_hack_session/proc/get_completed_sequence_count()
	return length(completed_sequence_indexes)

/datum/cyber_ice_hack_session/proc/is_sequence_index_completed(sequence_index)
	return "[sequence_index]" in completed_sequence_indexes

/datum/cyber_ice_hack_session/proc/advance_sequences_with_value(value)
	var/advanced = 0
	for(var/sequence_index in 1 to length(sequences))
		if(is_sequence_index_completed(sequence_index))
			continue
		var/list/sequence = sequences[sequence_index]
		var/progress_key = "[sequence_index]"
		var/current_progress = sequence_progress[progress_key] || 0
		if(current_progress >= length(sequence))
			continue
		if(value != sequence[current_progress + 1])
			continue
		current_progress++
		sequence_progress[progress_key] = current_progress
		advanced++
		if(current_progress < length(sequence))
			continue
		completed_sequence_indexes += "[sequence_index]"
		completed_sequences += list(sequence.Copy())
	return advanced

/datum/cyber_ice_hack_session/proc/sequence_is_completed(sequence_index)
	if(is_sequence_index_completed(sequence_index))
		return TRUE
	return FALSE

/datum/cyber_ice_hack_session/proc/roll_noise_alarm(cell_index)
	var/alarm_chance = 100
	var/reason = "decoy number selected"
	if(!("[cell_index]" in decoy_indexes))
		alarm_risk = min(100, alarm_risk + CYBER_ICE_NOISE_ALARM_STEP)
		alarm_chance = alarm_risk
		reason = "foreign number selected"
	alarm_chance = clamp(alarm_chance - get_alarm_chance_reduction(), 0, 100)
	if(prob(alarm_chance))
		ice.trigger_alarm(hacker, target, reason)

/datum/cyber_ice_hack_session/proc/get_alarm_chance_reduction()
	var/reduction = hacking_skill * CYBER_ICE_HACKING_ALARM_REDUCTION
	if(hacker?.mind)
		reduction += round(hacker.mind.get_character_skill_check_value(SKILL_HACKING) / CYBER_ICE_HACKING_CHECK_ALARM_REDUCTION_DIVISOR)
		reduction += round(hacker.mind.get_character_perk_effectiveness(SKILL_HACKING, 1))
	return clamp(reduction, 0, 100)

/datum/cyber_ice_hack_session/proc/get_current_alarm_chance()
	return clamp(alarm_risk - get_alarm_chance_reduction(), 0, 100)

/datum/cyber_ice_hack_session/proc/confirm_sequences()
	if(closed || !ice || ice.is_breached())
		return FALSE
	var/completed_sequences = get_completed_sequence_count()
	if(completed_sequences <= 0)
		ice.trigger_alarm(hacker, target, "no valid sequence submitted")
		reset_selection(FALSE)
		SStgui.update_uis(src)
		return TRUE
	var/damage = ice.get_sequence_damage(completed_sequences, hacking_skill)
	var/damage_bonus = hacker?.mind?.get_character_perk_effectiveness(SKILL_HACKING, 2) || 0
	if(damage_bonus > 0)
		damage += round(damage * (damage_bonus / 100))
	ice.apply_reserve_damage(damage)
	if(hacker)
		to_chat(hacker, span_notice("ICE reserve reduced by [damage]."))
	if(ice.is_breached() && hacker)
		to_chat(hacker, span_notice("ICE breached."))
	SStgui.close_uis(src)
	qdel(src)
	return TRUE

/datum/cyber_ice_hack_session/proc/reset_selection(update_ui = TRUE)
	selected_indexes = list()
	selected_values = list()
	last_index = 0
	next_axis = null
	if(update_ui)
		SStgui.update_uis(src)

/datum/cyber_ice_hack_session/proc/grid_ui_data()
	var/list/cells = list()
	for(var/cell_index in 1 to length(grid_values))
		var/value = grid_values[cell_index]
		cells += list(list(
			"index" = cell_index,
			"value" = value,
			"row" = CEILING(cell_index / grid_size, 1),
			"column" = ((cell_index - 1) % grid_size) + 1,
			"selected" = ("[cell_index]" in selected_indexes),
			"hinted" = FALSE,
		))
	return cells

/datum/cyber_ice_hack_session/proc/sequences_ui_data()
	var/list/sequence_data = list()
	for(var/sequence_index in 1 to length(sequences))
		var/list/sequence = sequences[sequence_index]
		sequence_data += list(list(
			"values" = sequence,
			"completed" = sequence_is_completed(sequence_index),
			"progress" = sequence_progress["[sequence_index]"] || 0,
		))
	return sequence_data

/datum/cyber_ice_hack_session/ui_state(mob/user)
	return GLOB.always_state

/datum/cyber_ice_hack_session/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberIceHack", "ICE breach")
		ui.open()

/datum/cyber_ice_hack_session/ui_close(mob/user)
	closed = TRUE
	qdel(src)

/datum/cyber_ice_hack_session/ui_data(mob/user)
	return list(
		"grid_size" = grid_size,
		"cells" = grid_ui_data(),
		"sequences" = sequences_ui_data(),
		"selected_values" = selected_values,
		"completed_sequences" = completed_sequences,
		"alarm_risk" = alarm_risk,
		"alarm_chance" = get_current_alarm_chance(),
		"alarm_reduction" = get_alarm_chance_reduction(),
		"next_axis" = next_axis,
		"time_left" = remaining_time(),
		"hacking_skill" = hacking_skill,
		"reserve" = ice?.current_reserve || 0,
		"max_reserve" = ice?.get_max_reserve() || 0,
		"alarm" = ice?.alarm_triggered || FALSE,
		"breached" = ice?.is_breached() || FALSE,
	)

/datum/cyber_ice_hack_session/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return .
	switch(action)
		if("select")
			return select_cell(params["index"])
		if("confirm")
			return confirm_sequences()
		if("reset")
			reset_selection()
			return TRUE
	return FALSE

/proc/create_cyber_node_ice(object_count, manufacturer_diversity_bonus = 0)
	var/datum/cyber_ice/node_ice = new()
	var/base_points = max(4, round(max(1, object_count)))
	node_ice.set_even_distribution(max(4, round(base_points * (1 + max(0, manufacturer_diversity_bonus)))))
	return node_ice

/datum/cyberspace_cryptokey
	/// Shared digital key. Objects of the same type/manufacturer/area resolve to the same key.
	var/key
	var/object_type
	var/area_type
	var/manufacturer = "independent"
	var/list/rights = list("view", "use", "control", "settings")

/datum/cyberspace_cryptokey/New(atom/movable/target)
	. = ..()
	if(!target)
		return
	object_type = target.type
	var/area/target_area = get_area(target)
	area_type = target_area?.type
	manufacturer = get_cyberspace_manufacturer(target)
	key = uppertext(copytext(md5("[manufacturer]|[object_type]|[area_type]"), 1, 17))

/datum/cyberspace_cryptokey/proc/matches(datum/cyberspace_cryptokey/other_key)
	return !isnull(other_key) && key == other_key.key
