#define DUMPTIME 3000
///Amount of money you need to lose to get the negative moodlet.
#define NO_MY_MONEY 10000

/datum/bank_account
	///Name listed on the account, reflected on the ID card.
	var/account_holder = "Rusty Venture"
	///How many credits are currently held in the bank account.
	var/account_balance = 0
	///How many mining points (shaft miner credits) is held in the bank account, used for mining vendors.
	var/mining_points = 0
	/// Points for bit runner's vendor. Awarded for completing virtual domains.
	var/bitrunning_points = 0
	///Debt. If higher than 0, A portion of the credits is earned (or the whole debt, whichever is lower) will go toward paying it off.
	var/account_debt = 0
	///If there are things effecting how much income a player will get, it's reflected here 1 is standard for humans.
	var/payday_modifier
	///The job datum of the account owner.
	var/datum/job/account_job
	///List of the physical ID card objects that are associated with this bank_account
	var/list/bank_cards
	///Should this ID be added to the global list of accounts? If true, will be subject to station-bound economy effects as well as income.
	var/add_to_accounts = TRUE
	///The Unique ID number code associated with the owner's bank account, assigned at round start.
	var/account_id
	///Amount of money that's been crabbed, if you lose enough from one series of CRAB-17's, you get a negative moodlet.
	var/money_crabbed
	///Is there a CRAB 17 on the station draining funds? Prevents manual fund transfer. pink levels are rising
	var/being_dumped = FALSE
	///Reference to the current civilian bounty that the account is working on.
	var/datum/bounty/civilian_bounty
	///If player is currently picking a civilian bounty to do, these options are held here to prevent soft-resetting through the UI.
	var/list/datum/bounty/bounties
	///Can this account be replaced? Set to true for default IDs not recognized by the station.
	var/replaceable = FALSE
	///Cooldown timer on replacing a civilain bounty. Bounties can only be replaced once every 5 minutes.
	COOLDOWN_DECLARE(bounty_timer)
	///A special semi-tandom token for tranfering money from NT pay app
	var/pay_token
	///List with a transaction history for NT pay app
	var/list/transaction_history
	///A lazylist of coupons redeemed with the Coupon Master pda app associated with this account.
	var/list/redeemed_coupons
	/// How many paychecks to skip when payday is called.
	var/paydays_to_skip = 0

/datum/bank_account/New(newname, job, modifier = 1, player_account = TRUE)
	account_holder = newname
	account_job = job
	payday_modifier = modifier
	add_to_accounts = player_account
	setup_unique_account_id()
	update_account_job_lists(job)
	pay_token = uppertext("[copytext_char(newname, 1, 2)][copytext_char(newname, -1)]-[random_capital_letter()]-[rand(1111,9999)]") // BANDASTATION EDIT - _char

/datum/bank_account/Destroy()
	if(add_to_accounts)
		SSeconomy.bank_accounts_by_id -= "[account_id]"
		SSeconomy.bank_accounts_by_job[account_job.type] -= src
	QDEL_LIST(redeemed_coupons)
	return ..()

/**
 * Proc guarantees the account_id possesses a unique number.
 * If it doesn't, it tries to find a unique alternative.
 * It then adds it to the `SSeconomy.bank_accounts_by_id` global list.
 */
/datum/bank_account/proc/setup_unique_account_id()
	if (!add_to_accounts)
		return
	if(account_id && !SSeconomy.bank_accounts_by_id["[account_id]"])
		SSeconomy.bank_accounts_by_id["[account_id]"] = src
		return //Already unique
	for(var/i in 1 to 1000)
		account_id = rand(111111, 999999)
		if(!SSeconomy.bank_accounts_by_id["[account_id]"])
			break
	if(SSeconomy.bank_accounts_by_id["[account_id]"])
		stack_trace("Unable to find a unique account ID, substituting currently existing account of id [account_id].")
	SSeconomy.bank_accounts_by_id["[account_id]"] = src

/**
 * Proc places this account into the right place in the `SSeconomy.bank_accounts_by_job` list, if needed.
 * If an old job is given, it removes it from its previous place first.
 */
/datum/bank_account/proc/update_account_job_lists(datum/job/new_job, datum/job/old_job)
	if(!add_to_accounts)
		return

	if(old_job)
		SSeconomy.bank_accounts_by_job[old_job.type] -= src
	if(new_job)
		LAZYADD(SSeconomy.bank_accounts_by_job[new_job.type], src)

/datum/bank_account/vv_edit_var(var_name, var_value) // just so you don't have to do it manually
	var/old_id = account_id
	var/datum/job/old_job = account_job
	var/old_balance = account_balance
	. = ..()
	switch(var_name)
		if(NAMEOF(src, account_id))
			if(add_to_accounts)
				SSeconomy.bank_accounts_by_id -= "[old_id]"
				setup_unique_account_id()
		if(NAMEOF(src, account_job))
			update_account_job_lists(account_job, old_job)
		if(NAMEOF(src, add_to_accounts))
			if(add_to_accounts)
				setup_unique_account_id()
				update_account_job_lists(account_job)
			else
				SSeconomy.bank_accounts_by_id -= "[account_id]"
				SSeconomy.bank_accounts_by_job[account_job.type] -= src
		if(NAMEOF(src, account_balance))
			add_log_to_history(var_value - old_balance, "Nanotrasen: Moderator Action")

/**
 * Sets the bank_account to behave as though a CRAB-17 event is happening.
 */
/datum/bank_account/proc/dumpeet()
	being_dumped = TRUE
	money_crabbed = 0

/**
 * Stops the dumping of the bank account.
 */
/datum/bank_account/proc/stop_dump()
	being_dumped = FALSE
	if(money_crabbed < NO_MY_MONEY)
		return
	for(var/obj/card as anything in bank_cards)
		var/mob/living/card_holder = recursive_loc_check(card, /mob/living)
		if(!isliving(card_holder)) //If on a mob
			continue
		//overwrite the slots event.
		card_holder.add_mood_event(SLOTS_MOOD_CATEGORY, /datum/mood_event/slots/all_gone)

/**
 * Returns TRUE if a bank account has more than or equal to the amount, amt.
 * Otherwise returns false.
 * Arguments:
 * * amount - the quantity of credits that will be reconciled with the account balance.
 */
/datum/bank_account/proc/has_money(amount)
	return account_balance >= amount

/**
 * Adjusts the balance of a bank_account as well as sanitizes the numerical input.
 * Arguments:
 * * amount - the quantity of credits that will be written off if the value is negative, or added if it is positive.
 * * reason - the reason for the appearance or loss of money
 */
/datum/bank_account/proc/adjust_money(amount, reason)
	if((amount < 0 && has_money(-amount)) || amount > 0)
		var/debt_collected = 0
		if(account_debt > 0 && amount > 0)
			debt_collected = min(ceil(amount*DEBT_COLLECTION_COEFF), account_debt)
		account_balance += amount - debt_collected
		if(reason)
			add_log_to_history(amount, reason)
		if(debt_collected)
			pay_debt(debt_collected, FALSE)
		return TRUE
	return FALSE

///Called when a portion of a debt is to be paid. It'll return the amount of credits put forwards to extinguish the debt.
/datum/bank_account/proc/pay_debt(amount, is_payment = TRUE)
	var/amount_to_pay = min(amount, account_debt)
	if(is_payment)
		if(!adjust_money(-amount, "РџСЂРѕС‡РµРµ: РћРїР»Р°С‚Р° РґРѕР»РіР°"))
			return 0
	else
		add_log_to_history(-amount, "РџСЂРѕС‡РµРµ: Р’Р·С‹СЃРєР°РЅРёРµ РґРѕР»РіРѕРІ")
	log_econ("[amount_to_pay][MONEY_NAME] were removed from [account_holder]'s bank account to pay a debt of [account_debt]")
	account_debt -= amount_to_pay
	SEND_SIGNAL(src, COMSIG_BANK_ACCOUNT_DEBT_PAID)
	return amount_to_pay

/**
 * Performs a transfer of credits to the bank_account datum from another bank account.
 * Arguments:
 * * datum/bank_account/from - The bank account that is sending the credits to this bank_account datum.
 * * amount - the quantity of credits that are being moved between bank_account datums.
 * * transfer_reason - override for adjust_money reason. Use if no default reason(Transfer to/from Name Surname).
 */
/datum/bank_account/proc/transfer_money(datum/bank_account/from, amount, transfer_reason)
	if(from.has_money(amount))
		var/reason_to = "РџРµСЂРµРІРѕРґ: РћС‚ [from.account_holder]"
		var/reason_from = "РџРµСЂРµРІРѕРґ: [account_holder]"

		if(IS_DEPARTMENTAL_ACCOUNT(from))
			reason_to = "РќР°РЅРѕС‚СЂРµР№Р·РµРЅ: Р—Р°СЂРїР»Р°С‚Р°"
			reason_from = ""

		if(transfer_reason)
			reason_to = IS_DEPARTMENTAL_ACCOUNT(src) ? "" : transfer_reason
			reason_from = transfer_reason

		adjust_money(amount, reason_to)
		from.adjust_money(-amount, reason_from)
		SSblackbox.record_feedback("amount", "credits_transferred", amount)
		log_econ("[amount][MONEY_NAME] were transferred from [from.account_holder]'s account to [src.account_holder]")
		return TRUE
	return FALSE

/**
 * This proc handles passive income gain for players, using their job's paycheck value.
 * Funds are taken from the parent department account to hand out to players. This can result in payment brown-outs if too many people are in one department.
 * Arguments:
 * * amount_of_paychecks - literally the number of salaries, 1 for issuing one salary, 5 for issuing five salaries.
 * * free - issuance of free funds, if TRUE then takes funds from the void, if FALSE (default) tries to send from the department's account.
 * * skippable - if TRUE, this proc may pay out nothing if the account has paydays_to_skip
 * * event - the name of the event that is being processed, used for bank card messages.
 */
/datum/bank_account/proc/payday(amount_of_paychecks, free = FALSE, skippable = FALSE, event = "Р’С‹РїР»Р°С‚Р° Р·Р°СЂРїР»Р°С‚С‹")
	if(!account_job)
		return FALSE

	if(skippable && !free)
		while(paydays_to_skip > 0 && amount_of_paychecks > 0)
			amount_of_paychecks -= 1
			paydays_to_skip -= 1

	if(amount_of_paychecks <= 0)
		return FALSE

	var/money_to_transfer = round(account_job.paycheck * payday_modifier * amount_of_paychecks)
	if(amount_of_paychecks == 1)
		money_to_transfer = clamp(money_to_transfer, 0, PAYCHECK_CREW) //We want to limit single, passive paychecks to regular crew income.
	if(free)
		adjust_money(money_to_transfer, "РќР°РЅРѕС‚СЂРµР№Р·РµРЅ: РћРїР»Р°С‚Р° СЃРјРµРЅС‹")
		SSblackbox.record_feedback("amount", "free_income", money_to_transfer)
		SSeconomy.station_target += money_to_transfer
		log_econ("[money_to_transfer][MONEY_NAME] were given to [src.account_holder]'s account from income.")
		return TRUE
	var/datum/bank_account/department_account = SSeconomy.get_dep_account(account_job.paycheck_department)
	if(isnull(department_account))
		bank_card_talk("РћРЁРР‘РљРђ: [event] РѕС‚РјРµРЅРµРЅР°. РќРµ СѓРґР°Р»РѕСЃСЊ СЃРІСЏР·Р°С‚СЊСЃСЏ СЃРѕ СЃС‡С‘С‚РѕРј РѕС‚РґРµР»Р°.")
		return FALSE
	if(!transfer_money(department_account, money_to_transfer))
		bank_card_talk("РћРЁРР‘РљРђ: [event] РѕС‚РјРµРЅРµРЅР°. РЎСЂРµРґСЃС‚РІ РѕС‚РґРµР»Р° РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ.")
		return FALSE
	bank_card_talk("[event] СѓСЃРїРµС€РЅР°. РќР° Р°РєРєР°СѓРЅС‚Рµ С‚РµРїРµСЂСЊ [account_balance][MONEY_SYMBOL].")
	return TRUE

/**
 * This sends a local chat message to the owner of a bank account, on all ID cards registered to the bank_account.
 * If not held, sends out a message to all nearby players.
 * Arguments:
 * * message - text that will be sent to listeners after the id card icon
 * * force - if TRUE ignore checks on client and client prefernces.
 */
/datum/bank_account/proc/bank_card_talk(message, force)
	if(!message || !LAZYLEN(bank_cards))
		return
	for(var/obj/card in bank_cards)
		var/icon_source = card
		if(isidcard(card))
			var/obj/item/card/id/id_card = card
			icon_source = id_card.get_cached_flat_icon()
		var/mob/card_holder = recursive_loc_check(card, /mob)
		if(ismob(card_holder)) //If on a mob
			if(!card_holder.client || (!(get_chat_toggles(card_holder.client) & CHAT_BANKCARD) && !force))
				return

			if(!HAS_TRAIT(card_holder, TRAIT_DEAF))
				card_holder.playsound_local(get_turf(card_holder), 'sound/machines/beep/twobeep_high.ogg', 50, TRUE)
				to_chat(card_holder, "[icon2html(icon_source, card_holder)] [span_notice("[message]")]")
		else if(isturf(card.loc)) //If on the ground
			var/turf/card_location = card.loc
			for(var/mob/potential_hearer in hearers(1,card_location))
				if(!potential_hearer.client || (!(get_chat_toggles(potential_hearer.client) & CHAT_BANKCARD) && !force))
					continue
				if(!HAS_TRAIT(potential_hearer, TRAIT_DEAF))
					potential_hearer.playsound_local(card_location, 'sound/machines/beep/twobeep_high.ogg', 50, TRUE)
					to_chat(potential_hearer, "[icon2html(icon_source, potential_hearer)] [span_notice("[message]")]")
		else
			var/atom/sound_atom
			for(var/mob/potential_hearer in card.loc) //If inside a container with other mobs (e.g. locker)
				if(!potential_hearer.client || (!(get_chat_toggles(potential_hearer.client) & CHAT_BANKCARD) && !force))
					continue
				if(!sound_atom)
					sound_atom = card.drop_location() //in case we're inside a bodybag in a crate or something. doing this here to only process it if there's a valid mob who can hear the sound.
				if(!HAS_TRAIT(potential_hearer, TRAIT_DEAF))
					potential_hearer.playsound_local(get_turf(sound_atom), 'sound/machines/beep/twobeep_high.ogg', 50, TRUE)
					to_chat(potential_hearer, "[icon2html(icon_source, potential_hearer)] [span_notice("[message]")]")

/**
 * Returns a string with the civilian bounty's description on it.
 */
/datum/bank_account/proc/bounty_text()
	if(!civilian_bounty)
		return FALSE
	return civilian_bounty.description


/**
 * Returns the required item count, or required chemical units required to submit a bounty.
 */
/datum/bank_account/proc/bounty_num()
	return civilian_bounty?.print_required() || "N/A"

/**
 * Produces the value of the account's civilian bounty reward, if able.
 */
/datum/bank_account/proc/bounty_value()
	return civilian_bounty?.get_bounty_reward() || 0

/datum/bank_account/proc/set_bounty(datum/bounty/new_bounty, obj/item/id_card)
	if(civilian_bounty)
		reset_bounty(id_card)

	civilian_bounty = new_bounty
	civilian_bounty.on_selected(id_card)

/**
 * Performs house-cleaning on variables when a civilian bounty is replaced, or, when a bounty is claimed.
 */
/datum/bank_account/proc/reset_bounty(obj/item/id_card)
	if(civilian_bounty)
		civilian_bounty.on_reset(id_card)
		civilian_bounty = null

	COOLDOWN_RESET(src, bounty_timer)

/datum/bank_account/department
	account_holder = "Guild Credit Agency"
	var/department_id = "REPLACE_ME"
	add_to_accounts = FALSE

/datum/bank_account/department/New(dep_id, budget, player_account = FALSE)
	department_id = dep_id
	account_balance = budget
	account_holder = SSeconomy.department_accounts[dep_id]
	SSeconomy.departmental_accounts += src

/datum/bank_account/department/adjust_money(amount, reason)
	. = ..()

	SSblackbox.record_feedback("amount", "[department_id]_balance", account_balance, world.time) //Provides the cargo balance alongside a timestamp for comparison afterwards.
	if(department_id != ACCOUNT_CAR)
		return

	// If we're under (or equal) 3 crates woth of money (600?) in the cargo department, we unlock the scrapheap, which gives us a buncha money. Useful in an emergency?
	if(account_balance >= CARGO_CRATE_VALUE * 3)
		return
	// We only allow people to actually buy the shuttle once the round gets going - otherwise you'd just be able to do it roundstart (Not really intended)
	var/minimum_allowed_purchase_time = (CONFIG_GET(number/shuttle_refuel_delay) * 0.6)
	if((world.time - SSticker.round_start_time) > minimum_allowed_purchase_time)
		SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_SCRAPHEAP] = TRUE
	else
		SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_SCRAPHEAP] = FALSE

/datum/bank_account/remote // Bank account not belonging to the local station
	add_to_accounts = FALSE

/**
 * Add log to transactions history. Deletes the oldest log when the history has more than 20 entries.
 * Main format: Category: Reason in Reason. Example: Vending: Machinery Using
 * Arguments:
 * * adjusted_money - How much was added, negative values removing cash.
 * * reason - The reason of interact with balance, for example, "Bought chips" or "Payday".
 */
/datum/bank_account/proc/add_log_to_history(adjusted_money, reason)
	if(LAZYLEN(transaction_history) >= 20)
		transaction_history.Cut(1,2)

	LAZYADD(transaction_history, list(list(
		"adjusted_money" = adjusted_money,
		"reason" = reason,
	)))

/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_apartment(apartment_id)
	return cyberpunk_apartments["[apartment_id]"]

/datum/controller/subsystem/cyberpunk_property/proc/get_cyberpunk_apartments_for_user(mob/living/user)
	var/list/apartments = list()
	for(var/apartment_id in cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = cyberpunk_apartments[apartment_id]
		if(apartment?.can_view(user))
			apartments += apartment
	return apartments

/datum/controller/subsystem/cyberpunk_property/proc/create_cyberpunk_apartment(mob/living/owner, obj/machinery/computer/apartment_terminal/terminal, list/params)
	if(!owner || !terminal)
		return null
	if(!owner.has_neural_implant())
		return null
	var/area/apartment_area = get_area(terminal)
	if(!cyberpunk_is_apartment_area(apartment_area))
		return null
	for(var/apartment_id in cyberpunk_apartments)
		var/datum/cyberpunk_apartment/existing_apartment = cyberpunk_apartments[apartment_id]
		if(existing_apartment?.get_apartment_area() == apartment_area)
			return null
	var/datum/bank_account/owner_account = owner.get_bank_account()
	var/name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE)
	if(!name)
		name = "[owner.real_name || owner.name]'s apartment"
	var/datum/cyberpunk_apartment/apartment = new
	apartment.id = next_cyberpunk_apartment_id++
	apartment.name = name
	apartment.owner_ckey = owner.ckey
	apartment.owner_name = owner.real_name || owner.name
	apartment.owner_character_key = get_cyberpunk_business_key(owner, owner_account)
	apartment.terminal = terminal
	apartment.apartment_area_type = apartment_area.type
	apartment.hydrate_from_persistent(owner)
	apartment.add_history("created by [apartment.owner_name] at [apartment_area.name]")
	cyberpunk_apartments["[apartment.id]"] = apartment
	terminal.apartment_id = apartment.id
	apartment.apply_generated_access(owner)
	return apartment

/datum/cyberpunk_apartment
	var/id = 0
	var/name = "Apartment"
	var/owner_ckey
	var/owner_name
	var/owner_character_key
	var/obj/machinery/computer/apartment_terminal/terminal
	var/apartment_area_type
	var/access_id
	var/list/saved_snapshot = list()
	var/saved_at = 0
	var/loaded_this_round = FALSE
	var/list/history = list()

/datum/cyberpunk_apartment/proc/user_key(mob/living/user)
	return SScyberpunk_property.get_cyberpunk_business_key(user, user?.get_bank_account())

/datum/cyberpunk_apartment/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_apartment/proc/get_apartment_area()
	RETURN_TYPE(/area)
	var/area/current_area = terminal ? get_area(terminal) : null
	if(cyberpunk_is_apartment_area(current_area))
		return current_area
	if(apartment_area_type)
		var/area/stored_area = GLOB.areas_by_type[apartment_area_type]
		if(stored_area)
			return stored_area
	return null

/datum/cyberpunk_apartment/proc/get_apartment_turfs()
	var/area/apartment_area = get_apartment_area()
	if(!apartment_area)
		return list()
	return cyberpunk_area_turfs(apartment_area)

/datum/cyberpunk_apartment/proc/can_view(mob/living/user)
	return user_key(user) == owner_character_key

/datum/cyberpunk_apartment/proc/can_save_load(mob/living/user)
	return can_view(user) && user.has_neural_implant()

/datum/cyberpunk_apartment/proc/persistent_record_id()
	return "[owner_character_key]:[apartment_area_type]"

/datum/cyberpunk_apartment/proc/get_access_id()
	if(!access_id)
		access_id = cyberpunk_persistent_access_id("apartment", owner_character_key, apartment_area_type)
	return access_id

/datum/cyberpunk_apartment/proc/get_access_key()
	if(!SSid_access)
		return null
	return SSid_access.register_cyberpunk_crypto_access_key(get_access_id(), "[name] apartment access", name)

/datum/cyberpunk_apartment/proc/apply_generated_access(mob/living/owner)
	var/datum/cyberpunk_crypto_key/access_key = get_access_key()
	if(!access_key)
		return FALSE
	terminal?.add_cyberpunk_crypto_key(access_key)
	for(var/turf/apartment_turf as anything in get_apartment_turfs())
		for(var/obj/machinery/door/door in apartment_turf.contents)
			door.add_cyberpunk_crypto_key(access_key)
	cyberpunk_grant_persistent_access(owner, access_key)
	add_history("apartment cryptokey access refreshed")
	return TRUE

/datum/cyberpunk_apartment/proc/to_persistent_record()
	return list(
		"id" = persistent_record_id(),
		"name" = name,
		"owner_key" = owner_character_key,
		"area_type" = "[apartment_area_type]",
		"saved_at" = world.realtime,
		"snapshot" = saved_snapshot,
		"meta" = list(
			"access_id" = get_access_id(),
		),
	)

/datum/cyberpunk_apartment/proc/hydrate_from_persistent(mob/living/user)
	var/list/record = user?.cyberpunk_find_persistent_area_record(/datum/preference/cyberpunk_apartment_records, persistent_record_id())
	if(!islist(record))
		return FALSE
	name = record["name"] || name
	var/list/meta = record["meta"]
	if(islist(meta))
		access_id = meta["access_id"] || access_id
	if(islist(record["snapshot"]))
		saved_snapshot = record["snapshot"]
		saved_at = world.time
	add_history("persistent apartment record loaded")
	return TRUE

/datum/cyberpunk_apartment/proc/save_apartment(mob/living/user)
	if(!can_save_load(user) || !terminal)
		return FALSE
	var/area/apartment_area = get_apartment_area()
	if(!apartment_area)
		return FALSE
	saved_snapshot = cyberpunk_persistent_area_capture(apartment_area, terminal)
	saved_at = world.time
	user.cyberpunk_store_persistent_area_record(/datum/preference/cyberpunk_apartment_records, to_persistent_record())
	add_history("[user.real_name || user.name] saved [length(saved_snapshot["movables"])] object(s) and [length(saved_snapshot["turfs"])] turf(s)")
	return TRUE

/datum/cyberpunk_apartment/proc/load_apartment(mob/living/user)
	if(!can_save_load(user) || !terminal || loaded_this_round || !length(saved_snapshot))
		return FALSE
	var/area/apartment_area = get_apartment_area()
	if(!apartment_area)
		return FALSE
	var/restored = cyberpunk_persistent_area_restore(apartment_area, terminal, saved_snapshot)
	loaded_this_round = TRUE
	apply_generated_access(user)
	add_history("[user.real_name || user.name] loaded [restored] object(s); area overwritten")
	return TRUE

/datum/cyberpunk_apartment/proc/to_ui_data(mob/living/user, include_history = FALSE)
	return list(
		"id" = id,
		"name" = name,
		"owner" = owner_name,
		"apartmentArea" = get_apartment_area()?.name || "none",
		"tileCount" = length(get_apartment_turfs()),
		"savedObjects" = islist(saved_snapshot) && islist(saved_snapshot["movables"]) ? length(saved_snapshot["movables"]) : 0,
		"savedAt" = saved_at ? DisplayTimeText(world.time - saved_at) : null,
		"loadedThisRound" = loaded_this_round,
		"canSaveLoad" = can_save_load(user),
		"history" = include_history ? history : null,
	)

#undef DUMPTIME
#undef NO_MY_MONEY
