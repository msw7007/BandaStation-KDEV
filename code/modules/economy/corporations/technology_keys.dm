//CYBERPUNK CORPORATIONS - technology archive keys, server storage, and reverse engineering.

/datum/cyberpunk_technology_key
	var/source_corporation_id
	var/source_corporation_name
	var/technology_id
	var/technology_name
	var/key_code
	var/created_at = 0
	var/created_by = "unknown"

/datum/cyberpunk_technology_key/New(datum/cyberpunk_corporation/source_corporation, list/technology, mob/user)
	. = ..()
	if(!source_corporation || !islist(technology))
		return
	source_corporation_id = source_corporation.id
	source_corporation_name = source_corporation.name
	technology_id = technology["id"]
	technology_name = technology["name"]
	created_at = world.time
	created_by = user?.real_name || user?.name || "network"
	key_code = uppertext(copytext(md5("corptech|[source_corporation_id]|[technology_id]|[created_by]|[world.time]|[rand()]"), 1, 16))

/datum/cyberpunk_technology_key/proc/is_valid()
	return !!(source_corporation_id && technology_id && key_code)

/datum/cyberpunk_technology_key/proc/to_memory_data()
	return list(
		"cyberpunk_kind" = "corporate_technology_key",
		"source_corporation_id" = source_corporation_id,
		"source_corporation_name" = source_corporation_name,
		"technology_id" = technology_id,
		"technology_name" = technology_name,
		"key_code" = key_code,
		"created_by" = created_by,
		"created_at" = created_at,
	)

/datum/cyberpunk_technology_key/proc/to_ui_data()
	return list(
		"sourceCorporationId" = source_corporation_id,
		"sourceCorporationName" = source_corporation_name,
		"technologyId" = technology_id,
		"technologyName" = technology_name,
		"keyCode" = key_code,
		"createdBy" = created_by,
	)

/proc/cyberpunk_technology_key_from_data(list/key_data)
	if(!islist(key_data))
		return null
	var/source_id = key_data["source_corporation_id"] || key_data["sourceCorporationId"]
	var/technology_id = key_data["technology_id"] || key_data["technologyId"]
	var/key_code = key_data["key_code"] || key_data["keyCode"]
	if(!source_id || !technology_id || !key_code)
		return null
	var/datum/cyberpunk_technology_key/key = new()
	key.source_corporation_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(source_id)
	key.source_corporation_name = key_data["source_corporation_name"] || key_data["sourceCorporationName"] || key.source_corporation_id
	key.technology_id = technology_id
	key.technology_name = key_data["technology_name"] || key_data["technologyName"] || technology_id
	key.key_code = key_code
	key.created_by = key_data["created_by"] || key_data["createdBy"] || "unknown"
	key.created_at = key_data["created_at"] || key_data["createdAt"] || 0
	return key

/mob/proc/remember_cyberpunk_technology_key(datum/cyberpunk_technology_key/key)
	if(!key?.is_valid())
		return FALSE
	return remember_data("technology_key:[key.key_code]", key.to_memory_data())

/datum/cyberpunk_data_payload/technology_key
	payload_type = CYBERPUNK_DATA_PAYLOAD_TECHNOLOGY_KEY

/datum/cyberpunk_data_payload/technology_key/New(datum/cyberpunk_technology_key/key)
	. = ..()
	if(!key?.is_valid())
		return
	payload_id = key.key_code
	payload_name = "[key.source_corporation_name] technology key: [key.technology_name]"
	payload_data = key.to_memory_data()

/obj/item/cyberdemon_disk/proc/store_cyberpunk_technology_key(datum/cyberpunk_technology_key/key, mob/user)
	if(!key?.is_valid())
		return FALSE
	for(var/datum/cyberpunk_data_payload/payload as anything in get_data_payloads(CYBERPUNK_DATA_PAYLOAD_TECHNOLOGY_KEY))
		if(payload.payload_id == key.key_code)
			to_chat(user, span_warning("[src] already stores this technology key."))
			return FALSE
	add_data_payload(new /datum/cyberpunk_data_payload/technology_key(key))
	to_chat(user, span_notice("You write [key.technology_name] technology key to [src]."))
	return TRUE

/obj/item/cyberdemon_disk/proc/get_cyberpunk_technology_keys()
	var/list/keys = list()
	for(var/datum/cyberpunk_data_payload/payload as anything in get_data_payloads(CYBERPUNK_DATA_PAYLOAD_TECHNOLOGY_KEY))
		var/datum/cyberpunk_technology_key/key = cyberpunk_technology_key_from_data(payload.payload_data)
		if(key)
			keys += key
	return keys

/obj/item/cyberdemon_disk/proc/get_cyberpunk_technology_keys_ui()
	var/list/records = list()
	for(var/datum/cyberpunk_technology_key/key as anything in get_cyberpunk_technology_keys())
		records += list(key.to_ui_data())
	return records

/datum/cyberpunk_corporation/proc/get_unlocked_technology_records()
	var/list/records = list()
	for(var/list/technology as anything in technologies)
		var/technology_id = technology["id"]
		if(!unlocked_technologies[technology_id])
			continue
		records += list(list(
			"id" = technology_id,
			"name" = technology["name"],
			"tier" = technology["tier"],
			"description" = technology["description"],
		))
	return records

/datum/cyberpunk_corporation/proc/create_technology_key(technology_id, mob/user)
	var/list/technology = get_technology(technology_id)
	if(!technology || !unlocked_technologies[technology_id])
		return null
	var/datum/cyberpunk_technology_key/key = new(src, technology, user)
	add_history("[user?.real_name || user?.name || "network"] exported technology key: [technology["name"]]")
	return key

/datum/cyberpunk_corporation/proc/get_foreign_progress_key(source_corporation_id, technology_id)
	source_corporation_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(source_corporation_id)
	return "[source_corporation_id]:[technology_id]"

/datum/cyberpunk_corporation/proc/add_foreign_technology_progress(source_corporation_id, technology_id, progress, source = "foreign technology scan")
	source_corporation_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(source_corporation_id)
	if(!source_corporation_id || !technology_id || source_corporation_id == id)
		return FALSE
	var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_corporation_id)
	var/list/technology = source_corporation?.get_technology(technology_id)
	if(!technology || !source_corporation.unlocked_technologies[technology_id])
		return FALSE
	if(stolen_technologies[technology_id])
		return TRUE
	var/progress_key = get_foreign_progress_key(source_corporation_id, technology_id)
	progress = max(0, round(progress))
	stolen_technology_progress[progress_key] = min(100, (stolen_technology_progress[progress_key] || 0) + progress)
	add_history("[source]: [source_corporation.name] [technology["name"]] progress [stolen_technology_progress[progress_key]]%")
	if(stolen_technology_progress[progress_key] >= 100)
		stolen_technologies[technology_id] = source_corporation_id
		stolen_technology_progress -= progress_key
		add_history("copied foreign technology: [technology["name"]] from [source_corporation.name]")
		SScyberpunk_corporations.refresh_cyberpunk_corporate_fabricators(id)
		return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/apply_technology_key(datum/cyberpunk_technology_key/key, source = "technology key upload")
	if(!key?.is_valid())
		return FALSE
	var/source_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(key.source_corporation_id)
	var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
	if(!source_corporation?.unlocked_technologies[key.technology_id])
		return FALSE
	if(source_id == id)
		unlocked_technologies[key.technology_id] = TRUE
		add_history("[source]: restored own technology key [key.technology_name]")
		SScyberpunk_corporations.refresh_cyberpunk_corporate_fabricators(id)
		return TRUE
	return add_foreign_technology_progress(source_id, key.technology_id, 100, source)

/datum/cyberpunk_corporation/proc/invest_research_into_foreign_technology(source_corporation_id, technology_id, points)
	points = max(0, round(points))
	if(points < CYBERPUNK_CORP_RESEARCH_TO_FOREIGN_PROGRESS_COST || research_points < points)
		return FALSE
	var/progress = FLOOR(points / CYBERPUNK_CORP_RESEARCH_TO_FOREIGN_PROGRESS_COST, 1)
	if(progress <= 0)
		return FALSE
	research_points -= progress * CYBERPUNK_CORP_RESEARCH_TO_FOREIGN_PROGRESS_COST
	return add_foreign_technology_progress(source_corporation_id, technology_id, progress, "research assimilation")

/datum/cyberpunk_corporation/proc/get_stolen_technologies_ui()
	var/list/stolen_records = list()
	for(var/technology_id in stolen_technologies)
		var/source_id = stolen_technologies[technology_id]
		var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
		var/list/technology = source_corporation?.get_technology(technology_id)
		stolen_records += list(list(
			"id" = technology_id,
			"name" = technology?["name"] || technology_id,
			"source" = source_id,
			"sourceName" = source_corporation?.name || source_id,
		))
	return stolen_records

/datum/cyberpunk_corporation/proc/get_stolen_progress_ui()
	var/list/progress_records = list()
	for(var/progress_key in stolen_technology_progress)
		var/list/key_parts = splittext("[progress_key]", ":")
		var/source_id = length(key_parts) >= 2 ? key_parts[1] : null
		var/technology_id = length(key_parts) >= 2 ? key_parts[2] : progress_key
		var/datum/cyberpunk_corporation/source_corporation = SScyberpunk_corporations.get_cyberpunk_corporation(source_id)
		var/list/technology = source_corporation?.get_technology(technology_id)
		progress_records += list(list(
			"id" = technology_id,
			"name" = technology?["name"] || technology_id,
			"source" = source_id || "foreign",
			"sourceName" = source_corporation?.name || source_id || "foreign",
			"progress" = stolen_technology_progress[progress_key],
		))
	return progress_records

/datum/cyberpunk_corporation/proc/steal_technology_from(datum/cyberpunk_corporation/victim, amount = 10, source = "technology theft")
	if(!victim || victim == src)
		return FALSE
	amount = max(1, round(amount))
	for(var/list/technology as anything in victim.technologies)
		var/technology_id = technology["id"]
		if(victim.unlocked_technologies[technology_id] && !stolen_technologies[technology_id])
			return add_foreign_technology_progress(victim.id, technology_id, amount, source)
	return FALSE

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_reverse_engineering(target_corporation_id, atom/movable/source_item, source = "reverse engineering")
	var/datum/cyberpunk_corporation/target_corporation = get_cyberpunk_corporation(target_corporation_id)
	if(!target_corporation || !source_item)
		return FALSE
	var/source_corporation_id = cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(source_item))
	if(!source_corporation_id || source_corporation_id == target_corporation.id)
		return FALSE
	var/datum/cyberpunk_corporation/source_corporation = get_cyberpunk_corporation(source_corporation_id)
	if(!source_corporation)
		return FALSE
	for(var/list/technology as anything in source_corporation.technologies)
		var/technology_id = technology["id"]
		if(!source_corporation.unlocked_technologies[technology_id] || target_corporation.stolen_technologies[technology_id])
			continue
		var/progress = prob(CYBERPUNK_CORP_REVERSE_BREAKTHROUGH_CHANCE) ? 100 : CYBERPUNK_CORP_REVERSE_PROGRESS
		if(target_corporation.has_edict("ryaznov_blueprint_archive"))
			progress += 10
		if(source_corporation.has_edict("benn_dna_storage"))
			progress = max(1, round(progress * 0.75))
		return target_corporation.add_foreign_technology_progress(source_corporation_id, technology_id, progress, "[source]: [source_item]")
	return FALSE

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporation_by_techweb(datum/techweb/techweb)
	return get_cyberpunk_corporation(cyberpunk_corporation_id_from_manufacturer(techweb?.organization))

/obj/machinery/rnd/server
	var/obj/item/cyberdemon_disk/inserted_corporate_data_disk
	var/corporate_technology_download_busy = FALSE

/obj/machinery/rnd/server/attack_hand(mob/user, list/modifiers)
	var/mob/living/living_user = user
	if(length(cyberpunk_crypto_keys) && (!istype(living_user) || !has_cyberpunk_crypto_access(living_user)))
		to_chat(user, span_warning("[src] rejects your corporate cryptokey handshake."))
		return TRUE
	ui_interact(user)
	return TRUE

/obj/machinery/rnd/server/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/cyberdemon_disk))
		return insert_corporate_data_disk(attacking_item, user)
	return ..()

/obj/machinery/rnd/server/click_alt(mob/user)
	if(eject_corporate_data_disk(user))
		return CLICK_ACTION_SUCCESS
	return ..()

/obj/machinery/rnd/server/proc/insert_corporate_data_disk(obj/item/cyberdemon_disk/disk, mob/user)
	if(!disk || inserted_corporate_data_disk == disk)
		return FALSE
	if(inserted_corporate_data_disk)
		eject_corporate_data_disk(user)
	if(user && !user.transferItemToLoc(disk, src))
		return FALSE
	inserted_corporate_data_disk = disk
	to_chat(user, span_notice("You insert [disk] into [src]."))
	SStgui.update_uis(src)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/rnd/server/proc/eject_corporate_data_disk(mob/user)
	if(!inserted_corporate_data_disk)
		to_chat(user, span_warning("[src] has no data disk inserted."))
		return FALSE
	var/obj/item/cyberdemon_disk/disk = inserted_corporate_data_disk
	inserted_corporate_data_disk = null
	disk.forceMove(drop_location())
	user?.put_in_hands(disk)
	to_chat(user, span_notice("You eject [disk] from [src]."))
	SStgui.update_uis(src)
	return TRUE

/obj/machinery/rnd/server/proc/get_cyberpunk_corporation()
	return SScyberpunk_corporations.get_cyberpunk_corporation(SScyberpunk_corporations.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(src)))

/obj/machinery/rnd/server/proc/get_corporate_technology_download_time(mob/living/user)
	var/hacking_level = user?.get_cyber_hacking_skill() || 0
	return max(CYBERPUNK_CORP_TECH_KEY_DOWNLOAD_MIN_TIME, CYBERPUNK_CORP_TECH_KEY_DOWNLOAD_TIME - (hacking_level * CYBERPUNK_CORP_TECH_KEY_HACKING_STEP))

/obj/machinery/rnd/server/proc/download_corporate_technology_key(mob/living/user, technology_id, to_disk = FALSE)
	if(corporate_technology_download_busy)
		to_chat(user, span_warning("[src] is already transferring a research node."))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation()
	if(!corporation)
		to_chat(user, span_warning("[src] has no corporate archive bound."))
		return FALSE
	var/list/technology = corporation.get_technology(technology_id)
	if(!technology || !corporation.unlocked_technologies[technology_id])
		to_chat(user, span_warning("Archive node is locked or missing."))
		return FALSE
	if(to_disk && !inserted_corporate_data_disk)
		to_chat(user, span_warning("[src] needs an inserted data disk for this transfer."))
		return FALSE
	var/download_time = get_corporate_technology_download_time(user)
	if(corporation.has_edict("benn_dna_storage"))
		download_time = round(download_time * 1.25)
	to_chat(user, span_notice("You start downloading one research node: [technology["name"]]."))
	corporate_technology_download_busy = TRUE
	if(to_disk)
		addtimer(CALLBACK(src, PROC_REF(finish_corporate_technology_disk_download), WEAKREF(user), corporation.id, technology_id, inserted_corporate_data_disk), download_time, TIMER_STOPPABLE)
		return TRUE
	var/timed_flags = IGNORE_HELD_ITEM
	if(!user.is_projected_into_cyberspace())
		timed_flags |= IGNORE_USER_LOC_CHANGE
	if(!do_after(user, download_time, target = src, timed_action_flags = timed_flags))
		corporate_technology_download_busy = FALSE
		to_chat(user, span_warning("Research node download interrupted."))
		return FALSE
	corporate_technology_download_busy = FALSE
	var/datum/cyberpunk_technology_key/key = corporation.create_technology_key(technology_id, user)
	if(!key)
		return FALSE
	if(to_disk)
		return inserted_corporate_data_disk.store_cyberpunk_technology_key(key, user)
	user.remember_cyberpunk_technology_key(key)
	to_chat(user, span_notice("You cache [technology["name"]] technology key in memory: [key.key_code]."))
	return TRUE

/obj/machinery/rnd/server/proc/finish_corporate_technology_disk_download(datum/weakref/user_ref, corporation_id, technology_id, obj/item/cyberdemon_disk/target_disk)
	corporate_technology_download_busy = FALSE
	if(QDELETED(src) || QDELETED(target_disk) || inserted_corporate_data_disk != target_disk)
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/mob/living/user = user_ref?.resolve()
	var/datum/cyberpunk_technology_key/key = corporation?.create_technology_key(technology_id, user)
	if(!key)
		return FALSE
	var/success = target_disk.store_cyberpunk_technology_key(key, user)
	if(success && !user)
		audible_message(span_notice("[src] writes a research node to [target_disk]."))
	return success

/obj/machinery/rnd/server/proc/upload_corporate_technology_key(mob/living/user, key_code)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation()
	if(!corporation || !inserted_corporate_data_disk)
		return FALSE
	for(var/datum/cyberpunk_technology_key/key as anything in inserted_corporate_data_disk.get_cyberpunk_technology_keys())
		if(key.key_code != key_code)
			continue
		if(corporation.apply_technology_key(key, "[user?.real_name || user?.name || "server"] disk upload"))
			to_chat(user, span_notice("[src] accepts [key.technology_name] technology key."))
			return TRUE
	to_chat(user, span_warning("[src] rejects the selected technology key."))
	return FALSE

/obj/machinery/rnd/server/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/rnd/server/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkCorporateResearchServer", name)
		ui.open()

/obj/machinery/rnd/server/ui_data(mob/user)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation()
	var/list/data = list(
		"serverName" = name,
		"manufacturer" = get_cyberspace_manufacturer(src),
		"status" = get_status_text(),
		"working" = working,
		"corporation" = null,
		"disk" = null,
	)
	if(corporation)
		data["corporation"] = list(
			"id" = corporation.id,
			"name" = corporation.name,
			"technologies" = corporation.get_unlocked_technology_records(),
		)
	if(inserted_corporate_data_disk)
		data["disk"] = list(
			"name" = inserted_corporate_data_disk.name,
			"technologyKeys" = inserted_corporate_data_disk.get_cyberpunk_technology_keys_ui(),
			"netData" = inserted_corporate_data_disk.stored_net_data,
		)
	return data

/obj/machinery/rnd/server/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	if(!istype(user))
		return FALSE
	switch(action)
		if("download_memory")
			INVOKE_ASYNC(src, PROC_REF(download_corporate_technology_key), user, params["technology_id"], FALSE)
			return TRUE
		if("download_disk")
			INVOKE_ASYNC(src, PROC_REF(download_corporate_technology_key), user, params["technology_id"], TRUE)
			return TRUE
		if("upload_disk_key")
			return upload_corporate_technology_key(user, params["key_code"])
		if("eject_disk")
			return eject_corporate_data_disk(user)
	return FALSE
