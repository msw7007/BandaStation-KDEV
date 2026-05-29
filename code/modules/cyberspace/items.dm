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

/datum/cyberspace_demon
	var/demon_name = "blank demon"
	var/description = "An unfinished network ability."
	var/effect = CYBER_DEMON_EFFECT_DAMAGE
	var/effect_power = 1
	var/cast_time = 2 SECONDS
	var/duration = 0
	var/list/special_effects = list()
	var/memory_cost = 1
	var/manufacturer = "Independent"
	var/prebuilt = FALSE
	var/net_data_cost = 0
	var/psychic_damage = CYBER_DEMON_DEFAULT_PSYCHIC_DAMAGE

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
	return new_demon

/datum/cyberspace_demon/proc/get_effective_power(physical_world = FALSE)
	var/power = effect_power
	if(physical_world)
		power *= CYBER_DEMON_PHYSICAL_WORLD_MULTIPLIER
	return max(0, round(power))

/datum/cyberspace_demon/proc/get_net_data_cost()
	if(net_data_cost)
		return net_data_cost
	return max(0, round(memory_cost + (effect_power / 5) + length(special_effects)))

/datum/cyberspace_demon/proc/can_compile(mob/living/user, obj/item/clothing/gloves/cyberdeck/deck, obj/machinery/cyberdemon_terminal/terminal)
	if(!prebuilt && memory_cost > CYBER_DEMON_MAX_COMPILED_MEMORY)
		to_chat(user, span_warning("[demon_name] requires [memory_cost] memory and cannot be compiled as a custom demon."))
		return FALSE
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
	if(!user?.mind || !deck || !can_compile(user, deck, terminal))
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
	if(!prebuilt && memory_cost > CYBER_DEMON_MAX_COMPILED_MEMORY)
		to_chat(user, span_warning("[demon_name] requires [memory_cost] memory and cannot be compiled as a custom demon."))
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
	var/physical_world = !caster.is_projected_into_cyberspace()
	var/current_power = get_effective_power(physical_world)
	to_chat(caster, span_notice("You start preparing [demon_name]."))
	if(!do_after(caster, cast_time, target = target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM, hidden = TRUE))
		to_chat(caster, span_warning("[demon_name] fizzles before activation."))
		return FALSE
	apply_psychic_damage(caster)
	return apply_effect(caster, target, current_power, physical_world)

/datum/cyberspace_demon/proc/apply_psychic_damage(mob/living/caster)
	if(psychic_damage <= 0 || !caster)
		return
	caster.adjust_organ_loss(ORGAN_SLOT_BRAIN, psychic_damage)

/datum/cyberspace_demon/proc/apply_effect(mob/living/caster, atom/target, current_power, physical_world)
	switch(effect)
		if(CYBER_DEMON_EFFECT_DAMAGE)
			var/mob/living/living_target = target
			if(istype(living_target))
				living_target.adjust_organ_loss(ORGAN_SLOT_BRAIN, current_power)
				to_chat(caster, span_notice("[demon_name] burns [target]'s neural pattern for [current_power]."))
				return TRUE
			var/obj/effect/cyberspace_wall_shell/wall = target
			if(istype(wall))
				return wall.take_wall_damage(current_power)
		if(CYBER_DEMON_EFFECT_HEAL)
			var/mob/living/living_target = target
			if(istype(living_target))
				living_target.adjust_organ_loss(ORGAN_SLOT_BRAIN, -current_power)
				to_chat(caster, span_notice("[demon_name] stabilizes [target]'s neural pattern for [current_power]."))
				return TRUE
		if(CYBER_DEMON_EFFECT_WALL)
			var/turf/target_turf = get_turf(target)
			if(!target_turf)
				return FALSE
			var/obj/effect/cyberspace_wall_shell/wall = locate(/obj/effect/cyberspace_wall_shell) in target_turf
			if(!wall)
				wall = new(target_turf, new /datum/cyberspace_wall())
			wall.build_wall(current_power)
			to_chat(caster, span_notice("[demon_name] raises a cyberspace wall to [wall.wall_data?.build_progress || 0]%."))
			return TRUE
		if(CYBER_DEMON_EFFECT_CRYPTOKEY)
			var/obj/effect/cyberspace_node_shell/node_shell = target
			if(!istype(node_shell) || !node_shell.node)
				to_chat(caster, span_warning("[demon_name] needs a cyberspace node target."))
				return FALSE
			for(var/datum/cyberspace_cryptokey/cryptokey as anything in node_shell.node.cryptokeys)
				caster.mind?.remember_cyber_cryptokey(cryptokey)
			to_chat(caster, span_notice("[demon_name] copies node cryptokeys into memory."))
			return TRUE
		if(CYBER_DEMON_EFFECT_EMP)
			target.emp_act(EMP_HEAVY)
			to_chat(caster, span_notice("[demon_name] shorts [target]."))
			return TRUE
		if(CYBER_DEMON_EFFECT_MOVEMENT)
			var/turf/target_turf = get_turf(target)
			if(target_turf)
				caster.forceMove(target_turf)
				to_chat(caster, span_notice("[demon_name] moves you through the network."))
				return TRUE
		if(CYBER_DEMON_EFFECT_BUFF, CYBER_DEMON_EFFECT_DEBUFF)
			to_chat(caster, span_notice("[demon_name] applies a temporary [effect] with power [current_power] for [round(duration / 10)] seconds."))
			return TRUE
	return FALSE

/datum/cyberspace_demon/proc/get_summary()
	return "[demon_name] ([memory_cost] memory, [get_net_data_cost()] net-data): [description]"

/datum/cyberspace_demon/custom
	demon_name = "Custom demon"
	description = "A custom compiled demon."

/datum/cyberspace_demon/needle
	demon_name = "Needle"
	description = "A compact attack demon that damages a target neural pattern."
	effect = CYBER_DEMON_EFFECT_DAMAGE
	effect_power = 8
	cast_time = 2 SECONDS
	memory_cost = 2
	net_data_cost = 1

/datum/cyberspace_demon/stitch
	demon_name = "Stitch"
	description = "A stabilization demon that reduces light neural damage."
	effect = CYBER_DEMON_EFFECT_HEAL
	effect_power = 6
	cast_time = 2 SECONDS
	memory_cost = 2
	net_data_cost = 1

/datum/cyberspace_demon/wall
	demon_name = "Wall"
	description = "Builds or reinforces a cyberspace barrier."
	effect = CYBER_DEMON_EFFECT_WALL
	effect_power = 25
	cast_time = 3 SECONDS
	duration = 30 SECONDS
	memory_cost = 3
	net_data_cost = 2

/datum/cyberspace_demon/collector
	demon_name = "Collector"
	description = "Copies cryptographic keys from a breached node."
	effect = CYBER_DEMON_EFFECT_CRYPTOKEY
	effect_power = 1
	cast_time = 3 SECONDS
	memory_cost = 4
	net_data_cost = 3

/datum/cyberspace_demon/short
	demon_name = "Short"
	description = "Triggers an EMP-like network fault on the target."
	effect = CYBER_DEMON_EFFECT_EMP
	effect_power = 1
	cast_time = 4 SECONDS
	memory_cost = 4
	net_data_cost = 4
	special_effects = list(CYBER_DEMON_SPECIAL_EMP)

/datum/cyberspace_demon/blink
	demon_name = "Blink"
	description = "Moves the user to the target point."
	effect = CYBER_DEMON_EFFECT_MOVEMENT
	effect_power = 1
	cast_time = 1.5 SECONDS
	memory_cost = 3
	net_data_cost = 2

/proc/get_cyberdemon_catalog()
	return list(
		"Needle" = /datum/cyberspace_demon/needle,
		"Stitch" = /datum/cyberspace_demon/stitch,
		"Wall" = /datum/cyberspace_demon/wall,
		"Collector" = /datum/cyberspace_demon/collector,
		"Short" = /datum/cyberspace_demon/short,
		"Blink" = /datum/cyberspace_demon/blink,
	)

/proc/get_cyberdemon_effect_choices()
	return list(
		"Damage" = CYBER_DEMON_EFFECT_DAMAGE,
		"Heal" = CYBER_DEMON_EFFECT_HEAL,
		"Wall" = CYBER_DEMON_EFFECT_WALL,
		"Cryptokey collector" = CYBER_DEMON_EFFECT_CRYPTOKEY,
		"Movement" = CYBER_DEMON_EFFECT_MOVEMENT,
		"Buff" = CYBER_DEMON_EFFECT_BUFF,
		"Debuff" = CYBER_DEMON_EFFECT_DEBUFF,
		"EMP" = CYBER_DEMON_EFFECT_EMP,
	)

/proc/get_cyberdemon_special_choices()
	return list(
		"Mass" = CYBER_DEMON_SPECIAL_MASS,
		"Spread" = CYBER_DEMON_SPECIAL_SPREAD,
		"Jump" = CYBER_DEMON_SPECIAL_JUMP,
		"Stealth" = CYBER_DEMON_SPECIAL_STEALTH,
		"EMP on trigger" = CYBER_DEMON_SPECIAL_EMP,
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
	var/raw_manufacturer = params["manufacturer"]
	var/power = clamp(text2num("[raw_power]") || 1, 1, 100)
	var/cast_seconds = clamp(text2num("[raw_cast_time]") || 1, 1, 30)
	var/duration_seconds = clamp(text2num("[raw_duration]") || 0, 0, 300)
	var/manufacturer = copytext_char(trim("[raw_manufacturer]"), 1, 33)
	if(!length(manufacturer))
		manufacturer = "Independent"

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
	new_demon.special_effects = specials
	new_demon.memory_cost = calculate_custom_cyberdemon_memory(power, cast_seconds, duration_seconds, specials)
	new_demon.net_data_cost = calculate_custom_cyberdemon_net_data_cost(new_demon.memory_cost, specials)
	new_demon.psychic_damage = CYBER_DEMON_DEFAULT_PSYCHIC_DAMAGE + round(new_demon.memory_cost / 3)
	new_demon.manufacturer = manufacturer
	return new_demon

/proc/calculate_custom_cyberdemon_memory(power, cast_seconds, duration_seconds, list/specials)
	return clamp(1 + round(power / 10) + round(cast_seconds / 10) + round(duration_seconds / 60) + length(specials), 1, 99)

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

/proc/cyberdemon_storage_ui_data(obj/item/clothing/gloves/cyberdeck/deck, obj/item/cyberdemon_disk/disk, obj/machinery/cyberdemon_terminal/terminal, mob/user)
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
			"present" = !!terminal,
			"name" = terminal?.name,
			"cooldown" = terminal ? max(0, round((terminal.compile_cooldown_until - world.time) / 10)) : 0,
		),
		"limits" = list(
			"max_specials" = CYBER_DEMON_MAX_SPECIAL_EFFECTS,
			"max_custom_memory" = CYBER_DEMON_MAX_COMPILED_MEMORY,
			"disk_memory" = CYBER_DEMON_DISK_MEMORY,
		),
	)

/proc/cyberdemon_compiler_static_data()
	return list(
		"catalog" = cyberdemon_catalog_ui_data(),
		"effects" = cyberdemon_effects_ui_data(),
		"specials" = cyberdemon_specials_ui_data(),
	)

/proc/delete_cyberdemon_from_list(list/demons, index, mob/user, source_name)
	index = text2num("[index]")
	if(index < 1 || index > length(demons))
		return FALSE
	var/datum/cyberspace_demon/demon = demons[index]
	if(!demon)
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
			var/demon_type = get_cyberdemon_type_from_id(params["id"])
			if(!demon_type)
				return TRUE
			var/datum/cyberspace_demon/demon = new demon_type
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

/obj/item/clothing/gloves/cyberdeck/Destroy(force)
	QDEL_LIST(demons)
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
	if(!user?.mind || !can_compile(user))
		return FALSE
	var/list/catalog = get_cyberdemon_catalog()
	var/choice = tgui_input_list(user, "Compile a demon. Net-data: [user.mind.cyber_net_data]. Memory: [get_used_memory()]/[memory_capacity].", name, catalog)
	if(!choice)
		return FALSE
	var/demon_type = catalog[choice]
	var/datum/cyberspace_demon/demon = new demon_type
	return demon.compile_to_deck(user, src, terminal)

/obj/item/clothing/gloves/cyberdeck/proc/delete_demon(mob/user)
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
		return FALSE
	demons -= demon
	to_chat(user, span_notice("You delete [demon.demon_name] from [src]."))
	qdel(demon)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/proc/find_held_demon_disk(mob/user)
	var/obj/item/cyberdemon_disk/disk = locate(/obj/item/cyberdemon_disk) in user.held_items
	if(!disk)
		disk = locate(/obj/item/cyberdemon_disk) in user.contents
	return disk

/obj/item/clothing/gloves/cyberdeck/proc/copy_demon_to_disk(mob/user)
	var/obj/item/cyberdemon_disk/disk = find_held_demon_disk(user)
	if(!disk)
		to_chat(user, span_warning("You need a demon disk."))
		return FALSE
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
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
	return cyberdemon_storage_ui_data(src, find_held_cyberdemon_disk(user), null, user)

/obj/item/clothing/gloves/cyberdeck/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, src, find_held_cyberdemon_disk(ui.user), null)

/obj/item/clothing/gloves/cyberdeck/attack_self(mob/living/user, modifiers)
	if(!istype(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/item/clothing/gloves/cyberdeck/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(user) || !target || target == src)
		return
	var/datum/cyberspace_demon/demon = choose_demon(user)
	if(!demon)
		return
	demon.apply(user, target, src)

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
	if(.)
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

/obj/machinery/cyberdemon_terminal/proc/can_compile(mob/user)
	if(world.time < compile_cooldown_until)
		to_chat(user, span_warning("[src] is cooling down for [DisplayTimeText(compile_cooldown_until - world.time)]."))
		return FALSE
	return TRUE

/obj/machinery/cyberdemon_terminal/proc/start_compile_cooldown()
	compile_cooldown_until = world.time + CYBER_TERMINAL_COMPILE_COOLDOWN

/obj/machinery/cyberdemon_terminal/attack_hand(mob/living/user, list/modifiers)
	if(!istype(user))
		return ..()
	ui_interact(user)
	return TRUE

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
	return cyberdemon_storage_ui_data(find_held_cyberdeck(user), find_held_cyberdemon_disk(user), src, user)

/obj/machinery/cyberdemon_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return handle_cyberdemon_compiler_action(action, params, ui.user, find_held_cyberdeck(ui.user), find_held_cyberdemon_disk(ui.user), src)
