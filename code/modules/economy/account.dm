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

//CYBERPUNK BUILD - rebuild and delete before release
/datum/bank_account/cyberpunk_corporation
	add_to_accounts = FALSE

/datum/bank_account/cyberpunk_corporation/New(newname)
	account_holder = newname
	payday_modifier = 1
	setup_cyberpunk_account_id()
	pay_token = uppertext("[copytext_char(newname, 1, 2)][copytext_char(newname, -1)]-[random_capital_letter()]-[rand(1111,9999)]")

/datum/bank_account/cyberpunk_corporation/Destroy()
	SSeconomy.bank_accounts_by_id -= "[account_id]"
	return ..()

/datum/bank_account/cyberpunk_corporation/proc/setup_cyberpunk_account_id()
	for(var/i in 1 to 1000)
		account_id = rand(111111, 999999)
		if(!SSeconomy.bank_accounts_by_id["[account_id]"])
			break
	if(SSeconomy.bank_accounts_by_id["[account_id]"])
		stack_trace("Unable to find a unique cyberpunk corporation account ID, substituting currently existing account of id [account_id].")
	SSeconomy.bank_accounts_by_id["[account_id]"] = src
//CYBERPUNK BUILD - rebuild and delete before release

//CYBERPUNK BUILD - rebuild and delete before release
#define CYBERPUNK_CORP_BENN "benn"
#define CYBERPUNK_CORP_RYAZNOV "ryaznov"
#define CYBERPUNK_CORP_STARLIGHT "starlight"
#define CYBERPUNK_CORP_GOVERNMENT "government"
#define CYBERPUNK_CORP_STARTING_BUDGET 15000
#define CYBERPUNK_CORP_RESEARCH_TO_CREDITS 50
#define CYBERPUNK_CORP_LEVEL_STEP 100

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_corporation(corporation_id)
	ensure_cyberpunk_corporations_seeded()
	return cyberpunk_corporations[cyberpunk_normalize_corporation_id(corporation_id)]

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_normalize_corporation_id(corporation_id)
	var/corp_id = lowertext(trim("[corporation_id]"))
	switch(corp_id)
		if("benn", "ben", "bСЌРЅ", "Р±СЌРЅСЊ")
			return CYBERPUNK_CORP_BENN
		if("ryaznov", "riaznov", "СЂСЏР·РЅРѕРІ")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight", "СЃС‚Р°СЂР»Р°Р№С‚")
			return CYBERPUNK_CORP_STARLIGHT
		if("government", "gov", "nanotrasen", "РїСЂР°РІРёС‚РµР»СЊСЃС‚РІРѕ")
			return CYBERPUNK_CORP_GOVERNMENT
	return corp_id

/datum/controller/subsystem/cyberpunk_corporations/proc/get_cyberpunk_public_corporation_names(include_government = FALSE)
	ensure_cyberpunk_corporations_seeded()
	var/list/names = list()
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation.hidden && !include_government)
			continue
		names += corporation.name
	return names

/datum/controller/subsystem/cyberpunk_corporations/proc/ensure_cyberpunk_corporations_seeded()
	if(cyberpunk_corporations_seeded)
		return
	cyberpunk_corporations_seeded = TRUE
	create_cyberpunk_corporation(CYBERPUNK_CORP_BENN)
	create_cyberpunk_corporation(CYBERPUNK_CORP_RYAZNOV)
	create_cyberpunk_corporation(CYBERPUNK_CORP_STARLIGHT)
	create_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)

/datum/controller/subsystem/cyberpunk_corporations/proc/create_cyberpunk_corporation(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	if(cyberpunk_corporations[corporation_id])
		return cyberpunk_corporations[corporation_id]
	var/datum/cyberpunk_corporation/corporation = new(corporation_id)
	corporation.ensure_account()
	cyberpunk_corporations[corporation_id] = corporation
	return corporation

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_corporate_activity(corporation_id, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	if(data_amount)
		corporation.add_data(data_type, data_amount, source)
	if(credit_amount)
		corporation.add_funds(credit_amount, source)
	return TRUE

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_id_from_manufacturer(manufacturer)
	var/manufacturer_id = cyberpunk_normalize_corporation_id(manufacturer)
	if(cyberpunk_corporations[manufacturer_id])
		return manufacturer_id
	var/manufacturer_group = cyberpunk_major_corp_for_manufacturer(manufacturer)
	switch(manufacturer_group)
		if("ben")
			return CYBERPUNK_CORP_BENN
		if("ryaznov")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight")
			return CYBERPUNK_CORP_STARLIGHT
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation?.get_subsidiary_by_manufacturer(manufacturer_text))
			return corporation_id
	if(findtext(manufacturer_text, "benn") || findtext(manufacturer_text, "ben"))
		return CYBERPUNK_CORP_BENN
	if(findtext(manufacturer_text, "ryaznov") || findtext(manufacturer_text, "riaznov"))
		return CYBERPUNK_CORP_RYAZNOV
	if(findtext(manufacturer_text, "starlight"))
		return CYBERPUNK_CORP_STARLIGHT
	if(findtext(manufacturer_text, "government") || findtext(manufacturer_text, "nanotrasen"))
		return CYBERPUNK_CORP_GOVERNMENT
	return null

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporation_has_edict(corporation_id, edict_id)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	return corporation?.has_edict(edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_manufacturer_has_edict(manufacturer, edict_id)
	return cyberpunk_corporation_has_edict(cyberpunk_corporation_id_from_manufacturer(manufacturer), edict_id)

/datum/controller/subsystem/cyberpunk_corporations/proc/record_cyberpunk_manufacturer_activity(manufacturer, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	return record_cyberpunk_corporate_activity(cyberpunk_corporation_id_from_manufacturer(manufacturer), data_type, data_amount, credit_amount, source)

/datum/controller/subsystem/cyberpunk_corporations/proc/cyberpunk_corporate_edict_multiplier(manufacturer, list/edict_ids, default_multiplier = 1, active_multiplier = 1.1)
	var/corporation_id = cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return default_multiplier
	for(var/edict_id in edict_ids)
		if(cyberpunk_corporation_has_edict(corporation_id, edict_id))
			return active_multiplier
	return default_multiplier

/datum/cyberpunk_corporate_subsidiary
	var/id = ""
	var/name = ""
	var/parent_id = ""
	var/manufacturer = ""
	var/focus = ""
	var/data_type = "general"

/datum/cyberpunk_corporate_subsidiary/New(parent_id, subsidiary_id, subsidiary_name, subsidiary_manufacturer, subsidiary_focus, subsidiary_data_type)
	. = ..()
	src.parent_id = parent_id
	id = subsidiary_id
	name = subsidiary_name
	manufacturer = subsidiary_manufacturer || subsidiary_name
	focus = subsidiary_focus
	data_type = subsidiary_data_type || "general"

/datum/cyberpunk_corporate_subsidiary/proc/matches_manufacturer(manufacturer_text)
	manufacturer_text = lowertext(trim("[manufacturer_text]"))
	if(!manufacturer_text)
		return FALSE
	return findtext(manufacturer_text, lowertext(name)) || findtext(manufacturer_text, lowertext(manufacturer)) || findtext(manufacturer_text, lowertext(id))

/datum/cyberpunk_corporate_subsidiary/proc/to_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"manufacturer" = manufacturer,
		"focus" = focus,
		"dataType" = data_type,
	)

/datum/cyberpunk_corporation
	var/id = ""
	var/name = "Corporation"
	var/group = ""
	var/direction = ""
	var/combat_doctrine = ""
	var/hidden = FALSE
	var/account_id
	var/level = 1
	var/experience = 0
	var/research_points = 0
	var/influence = 0
	var/list/subsidiaries = list()
	var/list/research_data = list()
	var/list/unlocked_technologies = list()
	var/list/active_edicts = list()
	var/list/subscribers = list()
	var/list/stolen_technology_progress = list()
	var/list/stolen_technologies = list()
	var/list/technology_discount_points = list()
	var/list/technologies = list()
	var/list/edicts = list()
	var/list/history = list()

/datum/cyberpunk_corporation/New(corporation_id)
	. = ..()
	id = corporation_id
	setup_profile()
	add_history("corporation initialized")

/datum/cyberpunk_corporation/proc/setup_profile()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			name = "Benn Conglomerate"
			group = "Asian medical and genetic group"
			direction = "Medicine, genetics, chemistry, stealth, precision, speed."
			combat_doctrine = "Hidden and precise strikes, blade damage, poison, acceleration, stealth."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "sun_yon", "Sun Yon Corporation", "Sun Yon", "Precision systems and ranged weapon modules.", "precision"),
				new /datum/cyberpunk_corporate_subsidiary(id, "ishikawa", "Ishikawa Industries", "Ishikawa", "Stealth systems and covert equipment.", "stealth"),
				new /datum/cyberpunk_corporate_subsidiary(id, "ho_shi", "Ho Shi Technologies", "Ho Shi", "Speed, reflex and acceleration modules.", "speed"),
			)
			technologies = list(
				list("id" = "benn_medtech", "name" = "Medical service lattice", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Medical kiosks, analyzers, insurance goods, and treatment automation."),
				list("id" = "benn_genetics", "name" = "Genetic stabilization", "tier" = 2, "cost" = 45, "prereq" = "benn_medtech", "description" = "Genetic consoles, infusers, stabilizers, and mutation rollback support."),
				list("id" = "benn_chemistry", "name" = "Combat chemistry", "tier" = 3, "cost" = 65, "prereq" = "benn_genetics", "description" = "Composite reagents, toxins, acid mixtures, and chemical demon payloads."),
				list("id" = "benn_stealthware", "name" = "Stealthware implants", "tier" = 4, "cost" = 85, "prereq" = "benn_chemistry", "description" = "Stealth, speed, precision and surgical implant branches."),
				list("id" = "benn_bioarchive", "name" = "DNA archive", "tier" = 5, "cost" = 110, "prereq" = "benn_stealthware", "description" = "Bio-data storage, foreign technology scanning, and recovery research.")
			)
			edicts = cyberpunk_benn_edicts()
		if(CYBERPUNK_CORP_RYAZNOV)
			name = "Ryaznov Union"
			group = "European infrastructure and industry group"
			direction = "Construction, repair, robotics, energy, heavy machinery, industrial production."
			combat_doctrine = "Open force, reliability, armor, area damage, impact and thermal weapons."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "kowalski", "Kowalski & Co", "Kowalski", "Industrial tooling and heavy classic weapons.", "engineering"),
				new /datum/cyberpunk_corporate_subsidiary(id, "tyazhmarsh", "Tyazhmarsh Production", "Tyazhmarsh", "Armor, heavy machinery and reinforced frames.", "defense"),
				new /datum/cyberpunk_corporate_subsidiary(id, "tesla_science", "Tesla Science", "Tesla Science", "Energy, power and shield modules.", "power"),
			)
			technologies = list(
				list("id" = "ryaznov_tools", "name" = "Industrial toolchain", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Engineering tools, analyzers, repair stations, and construction gear."),
				list("id" = "ryaznov_fortification", "name" = "Fortification grid", "tier" = 2, "cost" = 45, "prereq" = "ryaznov_tools", "description" = "Barriers, shields, barricades, plating, and reinforced structures."),
				list("id" = "ryaznov_power", "name" = "Power and shield systems", "tier" = 3, "cost" = 65, "prereq" = "ryaznov_fortification", "description" = "Generators, shield emitters, chargers, and emergency energy modules."),
				list("id" = "ryaznov_robotics", "name" = "Robotic industry", "tier" = 4, "cost" = 85, "prereq" = "ryaznov_power", "description" = "Drones, turrets, mech docks, exoskeletons, and mobile workshops."),
				list("id" = "ryaznov_blueprints", "name" = "Blueprint archive", "tier" = 5, "cost" = 110, "prereq" = "ryaznov_robotics", "description" = "Engineering data archive and foreign technology reverse engineering.")
			)
			edicts = cyberpunk_ryaznov_edicts()
		if(CYBERPUNK_CORP_STARLIGHT)
			name = "Starlight Combine"
			group = "North American logistics and mass production group"
			direction = "Goods, transport, delivery, contracts, vending, teleport nodes, social influence."
			combat_doctrine = "Control, mass pressure, speed, buffs, debuffs, teleportation, positional manipulation."
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "blackrock_investigate", "Blackrock Investigate", "Blackrock", "Data collection, investigation and suppression modules.", "intel"),
				new /datum/cyberpunk_corporate_subsidiary(id, "trans_travel", "Trans Travel", "Trans Travel", "Routing, movement and delivery systems.", "route"),
				new /datum/cyberpunk_corporate_subsidiary(id, "samanthas_keir", "Samantha's Keir", "Samantha's Keir", "Social influence, advertising and market pressure.", "social"),
			)
			technologies = list(
				list("id" = "starlight_market", "name" = "Market routing", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Contracts, vending, subscriptions, and stock telemetry."),
				list("id" = "starlight_delivery", "name" = "Delivery network", "tier" = 2, "cost" = 45, "prereq" = "starlight_market", "description" = "Cargo drones, delivery beacons, route data, and business logistics."),
				list("id" = "starlight_vehicle", "name" = "Transport platforms", "tier" = 3, "cost" = 65, "prereq" = "starlight_delivery", "description" = "Ground and air vehicles, route registration, and cargo movement."),
				list("id" = "starlight_phase", "name" = "Phase logistics", "tier" = 4, "cost" = 85, "prereq" = "starlight_vehicle", "description" = "Teleportation, recall, phase suits, and blink delivery."),
				list("id" = "starlight_route_archive", "name" = "Route archive", "tier" = 5, "cost" = 110, "prereq" = "starlight_phase", "description" = "Market intelligence, foreign tech scanning, and route optimization.")
			)
			edicts = cyberpunk_starlight_edicts()
		if(CYBERPUNK_CORP_GOVERNMENT)
			name = "City Government"
			group = "Hidden council corporation"
			direction = "Taxes, city stability, laws, emergency modes, police support."
			combat_doctrine = "Police operations, cameras, emergency armories, council voting keys."
			hidden = TRUE
			subsidiaries = list(
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_council", "Council", "City Council", "Votes, laws, emergency decrees.", "civic", 1, 1, 1),
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_police", "Police", "City Police", "Public order and emergency enforcement.", "security", 1, 1, 1),
				new /datum/cyberpunk_corporate_subsidiary(id, "gov_treasury", "City Treasury", "City Treasury", "Taxes, debt, registered finance.", "finance", 1, 1, 1),
			)
			technologies = list(
				list("id" = "gov_tax", "name" = "Tax registry", "tier" = 1, "cost" = 25, "prereq" = null, "description" = "Legal transaction tracking, tax records, and debt oversight."),
				list("id" = "gov_cameras", "name" = "City surveillance", "tier" = 2, "cost" = 45, "prereq" = "gov_tax", "description" = "Camera monitoring, evidence routing, and public order data."),
				list("id" = "gov_council", "name" = "Council voting keys", "tier" = 3, "cost" = 65, "prereq" = "gov_cameras", "description" = "Council votes, emergency state confirmation, and formal decrees."),
				list("id" = "gov_armory", "name" = "Emergency armory", "tier" = 4, "cost" = 85, "prereq" = "gov_council", "description" = "Special police warehouse and emergency combat kit authorization."),
				list("id" = "gov_city_directive", "name" = "City directive", "tier" = 5, "cost" = 110, "prereq" = "gov_armory", "description" = "City-wide corporate action approval and suppression hooks.")
			)
			edicts = list()

/datum/cyberpunk_corporation/proc/ensure_account()
	if(account_id && SSeconomy.bank_accounts_by_id["[account_id]"])
		return SSeconomy.bank_accounts_by_id["[account_id]"]
	var/datum/bank_account/account = new /datum/bank_account/cyberpunk_corporation("[name] corporate account")
	account.adjust_money(CYBERPUNK_CORP_STARTING_BUDGET, "Corporate starting budget")
	account_id = account.account_id
	return account

/datum/cyberpunk_corporation/proc/get_account()
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/datum/cyberpunk_corporation/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_corporation/proc/get_subsidiary_by_manufacturer(manufacturer)
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	if(!manufacturer_text)
		return null
	for(var/datum/cyberpunk_corporate_subsidiary/subsidiary as anything in subsidiaries)
		if(subsidiary.matches_manufacturer(manufacturer_text))
			return subsidiary
	return null

/datum/cyberpunk_corporation/proc/technology_matches_data_type(list/technology, data_type)
	if(!islist(technology) || !data_type)
		return FALSE
	var/technology_id = technology["id"]
	var/technology_name = technology["name"]
	var/technology_description = technology["description"]
	var/search_text = lowertext("[technology_id] [technology_name] [technology_description]")
	switch(data_type)
		if("bio", "medical", "genetic", "chemistry", "stealth")
			return findtext(search_text, "benn") || findtext(search_text, "med") || findtext(search_text, "gene") || findtext(search_text, "chem") || findtext(search_text, "bio") || findtext(search_text, "stealth")
		if("engineering", "power", "defense", "repair", "salvage")
			return findtext(search_text, "ryaznov") || findtext(search_text, "tool") || findtext(search_text, "fort") || findtext(search_text, "power") || findtext(search_text, "robot") || findtext(search_text, "blueprint")
		if("market", "route", "social", "delivery", "supply")
			return findtext(search_text, "starlight") || findtext(search_text, "market") || findtext(search_text, "delivery") || findtext(search_text, "vehicle") || findtext(search_text, "phase") || findtext(search_text, "route")
	return findtext(search_text, data_type)

/datum/cyberpunk_corporation/proc/apply_technology_discounts(data_type, amount, source = "activity")
	if(!amount)
		return FALSE
	var/applied = FALSE
	for(var/list/technology as anything in technologies)
		var/technology_id = technology["id"]
		if(unlocked_technologies[technology_id] || !technology_matches_data_type(technology, data_type))
			continue
		var/max_discount = round((technology["cost"] || 0) * 0.35)
		if(max_discount <= 0)
			continue
		var/current_discount = technology_discount_points[technology_id] || 0
		var/add_discount = min(max_discount - current_discount, max(1, round(amount / 3)))
		if(add_discount <= 0)
			continue
		technology_discount_points[technology_id] = current_discount + add_discount
		applied = TRUE
	if(applied)
		add_history("[source]: [data_type] activity reduced matching technology costs")
	return applied

/datum/cyberpunk_corporation/proc/add_data(data_type, amount, source = "activity")
	data_type = lowertext(trim("[data_type]")) || "general"
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	if(has_edict("[id]_self_analysis") || has_edict("[id]_self_diagnostics") || has_edict("[id]_self_statistics"))
		amount = max(1, round(amount * 1.25))
	research_data[data_type] = (research_data[data_type] || 0) + amount
	research_points += amount
	experience += amount
	apply_technology_discounts(data_type, amount, source)
	update_level()
	add_history("[source]: +[amount] [data_type] data, +[amount] RP")
	return TRUE

/datum/cyberpunk_corporation/proc/add_funds(amount, source = "activity")
	amount = round(amount)
	if(!amount)
		return FALSE
	var/datum/bank_account/account = ensure_account()
	account.adjust_money(amount, "Corporate funds: [source]")
	var/amount_prefix = amount >= 0 ? "+" : ""
	add_history("[source]: [amount_prefix][amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/update_level()
	level = clamp(1 + FLOOR(experience / CYBERPUNK_CORP_LEVEL_STEP, 1), 1, 5)

/datum/cyberpunk_corporation/proc/exchange_data_to_research(data_type, amount)
	data_type = lowertext(trim("[data_type]")) || "general"
	amount = clamp(round(amount), 0, research_data[data_type] || 0)
	if(!amount)
		return FALSE
	research_data[data_type] -= amount
	if(research_data[data_type] <= 0)
		research_data -= data_type
	research_points += amount
	experience += amount
	update_level()
	add_history("converted [amount] [data_type] data to research")
	return TRUE

/datum/cyberpunk_corporation/proc/exchange_research_to_funds(points)
	points = clamp(round(points), 0, research_points)
	if(!points)
		return FALSE
	research_points -= points
	add_funds(points * CYBERPUNK_CORP_RESEARCH_TO_CREDITS, "research exchange")
	add_history("converted [points] RP to [points * CYBERPUNK_CORP_RESEARCH_TO_CREDITS][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_corporation/proc/get_technology(technology_id)
	for(var/list/technology as anything in technologies)
		if(technology["id"] == technology_id)
			return technology
	return null

/datum/cyberpunk_corporation/proc/get_foreign_technology_bonus()
	return min(0.25, length(stolen_technologies) * 0.05)

/datum/cyberpunk_corporation/proc/get_technology_cost(list/technology)
	if(!islist(technology))
		return 0
	var/technology_id = technology["id"]
	var/base_cost = technology["cost"] || 0
	var/activity_discount = min(technology_discount_points[technology_id] || 0, round(base_cost * 0.35))
	return max(0, round((base_cost - activity_discount) * (1 - get_foreign_technology_bonus())))

/datum/cyberpunk_corporation/proc/unlock_technology(technology_id)
	var/list/technology = get_technology(technology_id)
	if(!technology || unlocked_technologies[technology_id])
		return FALSE
	var/prereq = technology["prereq"]
	if(prereq && !unlocked_technologies[prereq])
		return FALSE
	var/cost = get_technology_cost(technology)
	if(research_points < cost)
		return FALSE
	research_points -= cost
	unlocked_technologies[technology_id] = TRUE
	technology_discount_points -= technology_id
	var/technology_name = technology["name"]
	add_history("unlocked technology: [technology_name]")
	return TRUE

/datum/cyberpunk_corporation/proc/choose_edict(edict_id)
	for(var/list/edict as anything in edicts)
		if(edict["id"] != edict_id)
			continue
		var/edict_level = edict["level"] || 1
		if(level < edict_level || active_edicts["[edict_level]"])
			return FALSE
		active_edicts["[edict_level]"] = edict_id
		var/edict_name = edict["name"]
		add_history("activated level [edict_level] edict: [edict_name]")
		return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/has_edict(edict_id)
	for(var/level_key in active_edicts)
		if(active_edicts[level_key] == edict_id)
			return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/has_technology(technology_id)
	return !!unlocked_technologies[technology_id]

/datum/cyberpunk_corporation/proc/subscribe(mob/living/user)
	if(!user)
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(user, user.get_bank_account())
	if(!character_key)
		return FALSE
	if(subscribers[character_key])
		return TRUE
	var/cost = get_subscription_cost()
	var/datum/bank_account/user_account = user.get_bank_account()
	if(cost && (!user_account || !user_account.adjust_money(-cost, "[name] subscription")))
		return FALSE
	subscribers[character_key] = user.real_name || user.name
	add_funds(cost, "subscription: [user.real_name || user.name]")
	add_data(get_primary_data_type(), 2, "subscription")
	add_history("[user.real_name || user.name] subscribed")
	return TRUE

/datum/cyberpunk_corporation/proc/is_subscribed(mob/living/user)
	if(!user)
		return FALSE
	var/character_key = SSeconomy.get_cyberpunk_contract_character_key(user, user.get_bank_account())
	return !!subscribers[character_key]

/datum/cyberpunk_corporation/proc/get_subscription_cost()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return 150
		if(CYBERPUNK_CORP_RYAZNOV)
			return 125
		if(CYBERPUNK_CORP_STARLIGHT)
			return 100
	return 0

/datum/cyberpunk_corporation/proc/get_primary_data_type()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			return "bio"
		if(CYBERPUNK_CORP_RYAZNOV)
			return "engineering"
		if(CYBERPUNK_CORP_STARLIGHT)
			return "market"
		if(CYBERPUNK_CORP_GOVERNMENT)
			return "civic"
	return "general"

/datum/cyberpunk_corporation/proc/get_service_cost(service_id, mob/living/user)
	var/subscribed = is_subscribed(user)
	switch(service_id)
		if("medical")
			return subscribed ? 75 : 150
		if("body")
			return subscribed ? 90 : 180
		if("stealth")
			return subscribed ? 60 : 130
		if("chemistry")
			return subscribed ? 70 : 140
		if("technical")
			return subscribed ? 60 : 125
		if("salvage")
			return subscribed ? 45 : 95
		if("fortify")
			return subscribed ? 80 : 160
		if("power")
			return subscribed ? 70 : 145
		if("delivery")
			return subscribed ? 40 : 100
		if("return")
			return 0
		if("transport")
			return subscribed ? 85 : 170
		if("influence")
			return subscribed ? 50 : 110
	return 0

/datum/cyberpunk_corporation/proc/can_request_service(service_id)
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			if(service_id == "medical")
				return has_edict("benn_med_help") || has_edict("benn_med_observation") || has_edict("benn_med_insurance")
			if(service_id == "body")
				return has_edict("benn_gene_combo") || has_edict("benn_dna_storage")
			if(service_id == "stealth")
				return has_edict("benn_chem_recycling")
			if(service_id == "chemistry")
				return has_edict("benn_chem_synthesis") || has_edict("benn_chem_tuning")
		if(CYBERPUNK_CORP_RYAZNOV)
			if(service_id == "technical")
				return has_edict("ryaznov_field_support") || has_edict("ryaznov_tech_observation") || has_edict("ryaznov_tech_contract")
			if(service_id == "salvage")
				return has_edict("ryaznov_salvage_program") || has_edict("ryaznov_blueprint_archive")
			if(service_id == "fortify")
				return has_edict("ryaznov_mass_repair") || has_edict("ryaznov_blueprint_tuning")
			if(service_id == "power")
				return has_edict("ryaznov_power_tuning") || has_edict("ryaznov_field_support")
		if(CYBERPUNK_CORP_STARLIGHT)
			if(service_id == "delivery")
				return has_edict("starlight_log_help") || has_edict("starlight_cargo_tracking") || has_edict("starlight_trade_subscription")
			if(service_id == "return")
				return has_edict("starlight_return_program")
			if(service_id == "transport")
				return has_edict("starlight_trade_analysis") || has_edict("starlight_log_help")
			if(service_id == "influence")
				return has_edict("starlight_aggressive_ads")
	return FALSE

/datum/cyberpunk_corporation/proc/get_available_services_ui()
	var/list/services = list()
	switch(id)
		if(CYBERPUNK_CORP_BENN)
			services += cyberpunk_service_ui_entry("medical", "Medical aid", "Remote treatment and medical telemetry.", "truck-medical", can_request_service("medical"))
			services += cyberpunk_service_ui_entry("body", "Body stabilization", "Genetic stability and body retuning support.", "dna", can_request_service("body"))
			services += cyberpunk_service_ui_entry("stealth", "Stealth conditioning", "Short tactical stamina and signature support.", "user-ninja", can_request_service("stealth"))
			services += cyberpunk_service_ui_entry("chemistry", "Chemistry kit", "Combat chemistry starter delivery.", "flask", can_request_service("chemistry"))
		if(CYBERPUNK_CORP_RYAZNOV)
			services += cyberpunk_service_ui_entry("technical", "Technical support", "Nearby machine and structure repair.", "screwdriver-wrench", can_request_service("technical"))
			services += cyberpunk_service_ui_entry("salvage", "Salvage pack", "Industrial material and salvage delivery.", "recycle", can_request_service("salvage"))
			services += cyberpunk_service_ui_entry("fortify", "Field fortify", "Broad nearby integrity patch.", "shield", can_request_service("fortify"))
			services += cyberpunk_service_ui_entry("power", "Power tune", "Nearby machinery wear and power tuning.", "bolt", can_request_service("power"))
		if(CYBERPUNK_CORP_STARLIGHT)
			services += cyberpunk_service_ui_entry("delivery", "Delivery pack", "Courier pack to hands or turf.", "box", can_request_service("delivery"))
			services += cyberpunk_service_ui_entry("return", "Return program", "Sell a held non-Starlight item back into logistics.", "rotate-left", can_request_service("return"))
			services += cyberpunk_service_ui_entry("transport", "Transport ping", "Short tactical relocation request.", "location-arrow", can_request_service("transport"))
			services += cyberpunk_service_ui_entry("influence", "Influence pulse", "Mood and market telemetry pulse.", "bullhorn", can_request_service("influence"))
	return services

/proc/cyberpunk_service_ui_entry(service_id, label, description, icon, enabled = FALSE)
	return list(list(
		"id" = service_id,
		"label" = label,
		"description" = description,
		"icon" = icon,
		"enabled" = enabled,
	))

/datum/cyberpunk_corporation/proc/request_service(mob/living/user, service_id)
	if(!can_request_service(service_id) || !user)
		return FALSE
	var/cost = get_service_cost(service_id, user)
	var/datum/bank_account/user_account = user.get_bank_account()
	if(cost && (!user_account || !user_account.adjust_money(-cost, "[name] service: [service_id]")))
		return FALSE
	add_funds(cost, "service: [service_id]")
	add_data(get_primary_data_type(), is_subscribed(user) ? 4 : 2, "service request")
	add_history("[user.real_name || user.name] requested [service_id] service")
	switch(service_id)
		if("medical")
			to_chat(user, span_notice("Benn medical support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("body")
			to_chat(user, span_notice("Benn body stabilization has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("stealth")
			to_chat(user, span_notice("Benn stealth conditioning has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("chemistry")
			to_chat(user, span_notice("Benn chemistry kit has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_benn_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("technical")
			to_chat(user, span_notice("Ryaznov technical support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("salvage")
			to_chat(user, span_notice("Ryaznov salvage support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("fortify")
			to_chat(user, span_notice("Ryaznov fortification support has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("power")
			to_chat(user, span_notice("Ryaznov power tuning has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_ryaznov_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("delivery")
			to_chat(user, span_notice("Starlight delivery has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("return")
			to_chat(user, span_notice("Starlight return program has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("transport")
			to_chat(user, span_notice("Starlight transport ping has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
		if("influence")
			to_chat(user, span_notice("Starlight influence pulse has accepted your request. ETA 30 seconds."))
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberpunk_complete_starlight_service), WEAKREF(user), id, service_id), 30 SECONDS, TIMER_STOPPABLE)
	return TRUE

/datum/cyberpunk_corporation/proc/steal_technology_from(datum/cyberpunk_corporation/victim, amount = 10, source = "technology theft")
	if(!victim || victim == src)
		return FALSE
	amount = max(1, round(amount))
	var/list/candidate
	for(var/list/technology as anything in victim.technologies)
		var/technology_id = technology["id"]
		if(victim.unlocked_technologies[technology_id] && !stolen_technologies[technology_id])
			candidate = technology
			break
	if(!candidate)
		return FALSE
	var/technology_id = candidate["id"]
	var/technology_name = candidate["name"]
	var/technology_cost = candidate["cost"] || 50
	stolen_technology_progress[technology_id] = (stolen_technology_progress[technology_id] || 0) + amount
	add_history("[source]: scanned [amount] points of [victim.name] technology [technology_name]")
	if(stolen_technology_progress[technology_id] >= technology_cost)
		stolen_technologies[technology_id] = victim.id
		stolen_technology_progress -= technology_id
		add_history("stole foreign technology: [technology_name] from [victim.name]")
		return TRUE
	return FALSE

/datum/cyberpunk_corporation/proc/to_ui_data(include_hidden = FALSE)
	if(hidden && !include_hidden)
		return null
	var/datum/bank_account/account = ensure_account()
	var/list/data_records = list()
	for(var/data_type in research_data)
		data_records += list(list("type" = data_type, "amount" = research_data[data_type]))
	var/list/technology_records = list()
	for(var/list/technology as anything in technologies)
		var/technology_id = technology["id"]
		var/prereq = technology["prereq"]
		var/base_cost = technology["cost"] || 0
		var/current_cost = get_technology_cost(technology)
		technology_records += list(list(
			"id" = technology_id,
			"name" = technology["name"],
			"tier" = technology["tier"],
			"cost" = current_cost,
			"baseCost" = base_cost,
			"discount" = max(0, base_cost - current_cost),
			"prereq" = prereq,
			"description" = technology["description"],
			"unlocked" = !!unlocked_technologies[technology_id],
			"canUnlock" = !unlocked_technologies[technology_id] && (!prereq || unlocked_technologies[prereq]) && research_points >= current_cost,
		))
	var/list/edict_records = list()
	for(var/list/edict as anything in edicts)
		var/edict_level = edict["level"] || 1
		var/edict_id = edict["id"]
		edict_records += list(list(
			"id" = edict_id,
			"name" = edict["name"],
			"level" = edict_level,
			"description" = edict["description"],
			"active" = active_edicts["[edict_level]"] == edict_id,
			"locked" = level < edict_level || (active_edicts["[edict_level]"] && active_edicts["[edict_level]"] != edict_id),
		))
	var/list/stolen_records = list()
	for(var/technology_id in stolen_technologies)
		var/victim_id = stolen_technologies[technology_id]
		stolen_records += list(list("id" = technology_id, "source" = victim_id))
	var/list/stolen_progress_records = list()
	for(var/technology_id in stolen_technology_progress)
		stolen_progress_records += list(list("id" = technology_id, "progress" = stolen_technology_progress[technology_id]))
	var/list/subsidiary_records = list()
	for(var/datum/cyberpunk_corporate_subsidiary/subsidiary as anything in subsidiaries)
		subsidiary_records += list(subsidiary.to_ui_data())
	return list(
		"id" = id,
		"name" = name,
		"group" = group,
		"direction" = direction,
		"combatDoctrine" = combat_doctrine,
		"hidden" = hidden,
		"subsidiaries" = subsidiary_records,
		"level" = level,
		"experience" = experience,
		"nextLevelAt" = level < 5 ? level * CYBERPUNK_CORP_LEVEL_STEP : null,
		"researchPoints" = research_points,
		"influence" = influence,
		"accountId" = account.account_id,
		"balance" = account.account_balance,
		"debt" = account.account_debt,
		"researchData" = data_records,
		"technologies" = technology_records,
		"edicts" = edict_records,
		"activeEdicts" = active_edicts,
		"subscribers" = length(subscribers),
		"subscriptionCost" = get_subscription_cost(),
		"serviceMedical" = can_request_service("medical"),
		"serviceTechnical" = can_request_service("technical"),
		"serviceDelivery" = can_request_service("delivery"),
		"services" = get_available_services_ui(),
		"foreignTechBonus" = round(get_foreign_technology_bonus() * 100),
		"stolenTechnologies" = stolen_records,
		"stolenProgress" = stolen_progress_records,
		"history" = history,
	)

/proc/cyberpunk_benn_edicts()
	return list(
		list("id" = "benn_med_insurance", "name" = "Med-Insurance", "level" = 1, "description" = "Citizens may buy Benn medical insurance; insured users get broader medical vending access."),
		list("id" = "benn_self_analysis", "name" = "Self-Analysis", "level" = 1, "description" = "Analysis, treatment, surgery, and Benn medical purchases generate bio-data."),
		list("id" = "benn_supply_cert", "name" = "Supply Certification", "level" = 1, "description" = "Benn medical vendors use larger and higher-quality stock profiles."),
		list("id" = "benn_med_report", "name" = "Medical Analysis", "level" = 2, "description" = "Benn vendors may provide health summaries; insured users get full reports."),
		list("id" = "benn_gene_registry", "name" = "Gene Registry", "level" = 2, "description" = "Benn services collect genetic data for research and profit."),
		list("id" = "benn_chem_synthesis", "name" = "Chem Synthesis", "level" = 2, "description" = "Benn vendors may sell compound reagent components."),
		list("id" = "benn_med_tracking", "name" = "Medical Tracking", "level" = 3, "description" = "Severe body damage can trigger Benn response tracking and insured stasis support."),
		list("id" = "benn_donor_program", "name" = "Donor Program", "level" = 3, "description" = "Organ and bodypart recycling yields research data."),
		list("id" = "benn_chem_recycling", "name" = "Chemical Recycling", "level" = 3, "description" = "Benn offensive demons may add toxin or acid pressure; hostile medical network protection is reduced."),
		list("id" = "benn_med_help", "name" = "Medical Help", "level" = 4, "description" = "Benn vendors may provide direct paid autodoctor and drone aid."),
		list("id" = "benn_gene_combo", "name" = "Gene Combinatorics", "level" = 4, "description" = "Gene unlock and retuning costs and times are reduced."),
		list("id" = "benn_chem_tuning", "name" = "Chemical Tuning", "level" = 4, "description" = "Benn chemical plants work faster on Benn property."),
		list("id" = "benn_med_observation", "name" = "Medical Observation", "level" = 5, "description" = "Benn vendors can dispatch paid treatment drones to wounded citizens."),
		list("id" = "benn_dna_storage", "name" = "DNA Storage", "level" = 5, "description" = "Benn services provide extra research and slow foreign tech scanning."),
		list("id" = "benn_chem_guardians", "name" = "Chemical Guardians", "level" = 5, "description" = "Threats near Benn infrastructure can trigger acidic defensive drones.")
	)

/proc/cyberpunk_ryaznov_edicts()
	return list(
		list("id" = "ryaznov_tech_contract", "name" = "Tech Contract", "level" = 1, "description" = "Citizens and businesses may sign Ryaznov service contracts."),
		list("id" = "ryaznov_self_diagnostics", "name" = "Self-Diagnostics", "level" = 1, "description" = "Repairs, construction, and Ryaznov purchases generate engineering data."),
		list("id" = "ryaznov_supply_cert", "name" = "Supply Certification", "level" = 1, "description" = "Ryaznov vending and service terminals use larger industrial stocks."),
		list("id" = "ryaznov_industrial_analysis", "name" = "Industrial Analysis", "level" = 2, "description" = "Ryaznov terminals can report structural, machine, and power state."),
		list("id" = "ryaznov_route_registry", "name" = "Infrastructure Registry", "level" = 2, "description" = "Serviced machines and structures produce infrastructure research data."),
		list("id" = "ryaznov_mass_repair", "name" = "Mass Repair", "level" = 2, "description" = "Field repair kits and stations receive broader support hooks."),
		list("id" = "ryaznov_tech_tracking", "name" = "Tech Tracking", "level" = 3, "description" = "Ryaznov infrastructure can track damaged structures and machines."),
		list("id" = "ryaznov_salvage_program", "name" = "Salvage Program", "level" = 3, "description" = "Machine recycling and heavy wreck analysis yield research data."),
		list("id" = "ryaznov_overload_loop", "name" = "Overload Loop", "level" = 3, "description" = "Ryaznov offensive demons can add heat, impact, or shield pressure."),
		list("id" = "ryaznov_field_support", "name" = "Field Support", "level" = 4, "description" = "Ryaznov terminals may provide paid field repair support."),
		list("id" = "ryaznov_blueprint_tuning", "name" = "Blueprint Tuning", "level" = 4, "description" = "Construction and reinforcement work faster on Ryaznov property."),
		list("id" = "ryaznov_power_tuning", "name" = "Power Tuning", "level" = 4, "description" = "Power and shield infrastructure works better on Ryaznov property."),
		list("id" = "ryaznov_tech_observation", "name" = "Tech Observation", "level" = 5, "description" = "Ryaznov terminals can dispatch paid repair drones."),
		list("id" = "ryaznov_blueprint_archive", "name" = "Blueprint Archive", "level" = 5, "description" = "Repair, recycling, and heavy tech work scan foreign technologies."),
		list("id" = "ryaznov_shield_guardians", "name" = "Shield Guardians", "level" = 5, "description" = "Threats near Ryaznov infrastructure can trigger shield and turret drones.")
	)

/proc/cyberpunk_starlight_edicts()
	return list(
		list("id" = "starlight_trade_subscription", "name" = "Trade Subscription", "level" = 1, "description" = "Citizens and businesses may subscribe for faster Starlight delivery and direct pool hand-ins."),
		list("id" = "starlight_self_statistics", "name" = "Self-Statistics", "level" = 1, "description" = "Purchases, deliveries, contracts, sales, and Starlight vending generate market data."),
		list("id" = "starlight_supply_cert", "name" = "Supply Certification", "level" = 1, "description" = "Starlight vendors use larger and more frequent stock support."),
		list("id" = "starlight_trade_analysis", "name" = "Trade Analysis", "level" = 2, "description" = "Citizens may order goods to coordinates or beacons."),
		list("id" = "starlight_route_registry", "name" = "Route Registry", "level" = 2, "description" = "Starlight vehicles generate exploitation route data."),
		list("id" = "starlight_return_program", "name" = "Return Program", "level" = 2, "description" = "Non-Starlight goods may be returned for credits."),
		list("id" = "starlight_cargo_tracking", "name" = "Cargo Tracking", "level" = 3, "description" = "Starlight orders can be routed to drone beacons."),
		list("id" = "starlight_aggressive_ads", "name" = "Aggressive Advertising", "level" = 3, "description" = "Starlight infrastructure emits mood influence and market data collection waves."),
		list("id" = "starlight_suppression_loop", "name" = "Suppression Circuit", "level" = 3, "description" = "Starlight offensive systems can add control, psychic, or slowing effects."),
		list("id" = "starlight_log_help", "name" = "Logistics Help", "level" = 4, "description" = "Citizens may use cargo drones for coordinate movement and item delivery."),
		list("id" = "starlight_mass_production", "name" = "Mass Production", "level" = 4, "description" = "Assembly and production are faster on Starlight property, with copy chances."),
		list("id" = "starlight_phase_tuning", "name" = "Phase Tuning", "level" = 4, "description" = "Teleport and shimmer equipment works better on Starlight property."),
		list("id" = "starlight_log_observation", "name" = "Log Observation", "level" = 5, "description" = "Starlight cargo receives tracking beacons visible to buyers."),
		list("id" = "starlight_route_archive", "name" = "Route Archive", "level" = 5, "description" = "Transport and drone hauling provide research and foreign tech scanning."),
		list("id" = "starlight_phase_guardians", "name" = "Phase Guardians", "level" = 5, "description" = "Threats near Starlight infrastructure can trigger phase defense drones.")
	)

/proc/cyberpunk_corporations_ui_data(mob/user, selected_corporation_id = null, locked_corporation_id = null)
	SScyberpunk_corporations.ensure_cyberpunk_corporations_seeded()
	var/mob/living/living_user = isliving(user) ? user : null
	var/list/corporations = list()
	var/locked_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(locked_corporation_id)
	var/selected_id = SScyberpunk_corporations.cyberpunk_normalize_corporation_id(selected_corporation_id)
	if(locked_id && selected_id != locked_id)
		selected_id = locked_id
	var/datum/cyberpunk_corporation/selected_corporation
	for(var/corporation_id in SScyberpunk_corporations.cyberpunk_corporations)
		if(locked_id && corporation_id != locked_id)
			continue
		var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.cyberpunk_corporations[corporation_id]
		var/list/corporation_data = corporation.to_ui_data(TRUE)
		if(!corporation_data)
			continue
		corporations += list(corporation_data)
		if(corporation.id == selected_id)
			selected_corporation = corporation
	if(!selected_corporation && length(corporations))
		var/list/first_corporation = corporations[1]
		selected_corporation = SScyberpunk_corporations.cyberpunk_corporations[first_corporation["id"]]
	var/datum/bank_account/user_account = living_user?.get_bank_account()
	return list(
		"accountName" = user_account?.account_holder,
		"accountBalance" = user_account?.account_balance || 0,
		"corporations" = corporations,
		"selected" = selected_corporation?.to_ui_data(TRUE),
	)

/proc/cyberpunk_corporations_ui_act(action, list/params, mob/user)
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(params && params["corporation_id"])
	if(!corporation)
		return FALSE
	var/mob/living/living_user = isliving(user) ? user : null
	switch(action)
		if("select")
			return TRUE
		if("unlock_technology")
			if(corporation.unlock_technology(params["technology_id"]))
				to_chat(user, span_notice("[corporation.name] unlocked a technology."))
			else
				to_chat(user, span_warning("Unable to unlock this technology."))
			return TRUE
		if("choose_edict")
			if(corporation.choose_edict(params["edict_id"]))
				to_chat(user, span_notice("[corporation.name] activated a corporate decision."))
			else
				to_chat(user, span_warning("Unable to activate this corporate decision."))
			return TRUE
		if("convert_data")
			if(corporation.exchange_data_to_research(params["data_type"], text2num(params["amount"])))
				to_chat(user, span_notice("[corporation.name] converted data to research."))
			else
				to_chat(user, span_warning("Unable to convert this data."))
			return TRUE
		if("exchange_research")
			if(corporation.exchange_research_to_funds(text2num(params["amount"])))
				to_chat(user, span_notice("[corporation.name] exchanged research for funds."))
			else
				to_chat(user, span_warning("Unable to exchange research."))
			return TRUE
		if("subscribe")
			if(corporation.subscribe(living_user))
				to_chat(user, span_notice("Subscription registered with [corporation.name]."))
			else
				to_chat(user, span_warning("Unable to register subscription."))
			return TRUE
		if("request_service")
			if(corporation.request_service(living_user, params["service_id"]))
				to_chat(user, span_notice("Service request sent to [corporation.name]."))
			else
				to_chat(user, span_warning("Unable to request this service."))
			return TRUE
		if("steal_technology")
			var/datum/cyberpunk_corporation/victim = SScyberpunk_corporations.get_cyberpunk_corporation(params["target_corporation_id"])
			var/theft_amount = clamp(round(text2num(params["amount"]) || 10), 1, 100)
			var/source_name = user?.name || "system"
			if(corporation.steal_technology_from(victim, theft_amount, "[source_name] tech theft"))
				to_chat(user, span_notice("[corporation.name] copied a foreign technology."))
			else
				to_chat(user, span_warning("Technology theft made progress or found no unlocked target."))
			return TRUE
		if("test_activity")
			var/data_type = reject_bad_text(params["data_type"], max_length = 32, ascii_only = TRUE) || "general"
			var/amount = clamp(round(text2num(params["amount"]) || 10), 1, 1000)
			var/test_source_name = user?.name || "system"
			corporation.add_data(data_type, amount, "[test_source_name] test activity")
			return TRUE
	return FALSE

/proc/cyberpunk_complete_benn_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	switch(service_id)
		if("medical")
			var/heal_amount = corporation?.is_subscribed(user) ? 60 : 35
			user.heal_ordered_damage(heal_amount, list(BRUTE, BURN, TOX, OXY))
			to_chat(user, span_notice("Benn remote medical service completes treatment protocol."))
		if("body")
			var/mob/living/carbon/carbon_user = user
			if(istype(carbon_user) && carbon_user.dna)
				carbon_user.dna.adjust_humanoidity_stabilized_bonus(corporation?.is_subscribed(user) ? 12 : 7)
			user.adjust_stamina_loss(-25)
			to_chat(user, span_notice("Benn body stabilization raises your genetic stability buffer."))
		if("stealth")
			user.adjust_stamina_loss(-45)
			to_chat(user, span_notice("Benn stealth conditioning clears fatigue and dampens your network profile."))
		if("chemistry")
			var/obj/item/storage/box/package = new(get_turf(user))
			package.name = "Benn chemistry kit"
			if(hascall(package, "set_cyberpunk_manufacturer"))
				call(package, "set_cyberpunk_manufacturer")("Benn")
			if(!user.put_in_hands(package))
				package.forceMove(get_turf(user))
			to_chat(user, span_notice("Benn chemical support delivers a compact chemistry kit."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "bio", 2, 0, "Benn service completed: [service_id]")
	return TRUE

/proc/cyberpunk_complete_ryaznov_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	var/repair_amount = corporation?.is_subscribed(user) ? 80 : 45
	if(service_id == "fortify")
		repair_amount *= 0.5
	var/atom/repair_target
	for(var/atom/candidate as anything in range(1, user))
		if(candidate == user || candidate.max_integrity <= 0 || candidate.get_integrity() >= candidate.max_integrity)
			continue
		repair_target = candidate
		break
	if(service_id == "salvage")
		var/obj/item/storage/box/package = new(get_turf(user))
		package.name = "Ryaznov salvage pack"
		if(hascall(package, "set_cyberpunk_manufacturer"))
			call(package, "set_cyberpunk_manufacturer")("Ryaznov")
		if(!user.put_in_hands(package))
			package.forceMove(get_turf(user))
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov salvage service completed")
		to_chat(user, span_notice("Ryaznov salvage service delivers an industrial pack."))
		return TRUE
	if(service_id == "power")
		for(var/obj/machinery/nearby_machine in range(1, user))
			nearby_machine.repair_cyberpunk_machine_wear(repair_amount, user)
		SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov power service completed")
		to_chat(user, span_notice("Ryaznov power tuning refreshes nearby machinery components."))
		return TRUE
	if(!repair_target)
		to_chat(user, span_warning("Ryaznov field service finds no damaged nearby object."))
		return FALSE
	var/applied_repair = repair_target.repair_damage(repair_amount)
	var/obj/machinery/repaired_machine = repair_target
	if(istype(repaired_machine))
		repaired_machine.repair_cyberpunk_machine_wear(repair_amount, user)
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "engineering", max(1, round(applied_repair / 10)), 0, "Ryaznov service completed: [service_id]")
	to_chat(user, span_notice("Ryaznov field service repairs [repair_target] by [applied_repair] integrity."))
	return TRUE

/proc/cyberpunk_complete_starlight_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(corporation_id)
	switch(service_id)
		if("delivery")
			var/obj/item/storage/box/package = new(get_turf(user))
			package.name = "Starlight delivery pack"
			if(hascall(package, "set_cyberpunk_manufacturer"))
				call(package, "set_cyberpunk_manufacturer")("Starlight")
			if(!user.put_in_hands(package))
				package.forceMove(get_turf(user))
			to_chat(user, span_notice("Starlight drone delivery arrives."))
		if("return")
			var/obj/item/held_item = user.get_active_held_item()
			if(!held_item)
				to_chat(user, span_warning("Starlight return program needs an active held item."))
				return FALSE
			var/return_value = max(1, round(held_item.get_cyberpunk_price(user) * (corporation?.is_subscribed(user) ? 0.6 : 0.4)))
			var/datum/bank_account/user_account = user.get_bank_account()
			user_account?.adjust_money(return_value, "Starlight return program")
			qdel(held_item)
			to_chat(user, span_notice("Starlight return program credits [return_value][MONEY_SYMBOL]."))
		if("transport")
			var/turf/destination = get_step(get_turf(user), user.dir || SOUTH)
			if(destination && !destination.is_blocked_turf(source_atom = user))
				user.forceMove(destination)
			user.adjust_stamina_loss(-20)
			to_chat(user, span_notice("Starlight transport ping shifts your position."))
		if("influence")
			user.adjust_stamina_loss(-35)
			user.add_mood_event("starlight_influence", /datum/mood_event/starlight_influence)
			to_chat(user, span_notice("Starlight influence pulse stabilizes your tempo."))
	SScyberpunk_corporations.record_cyberpunk_corporate_activity(corporation_id, "market", 2, 0, "Starlight service completed: [service_id]")
	return TRUE

/datum/mood_event/starlight_influence
	description = "Starlight's feed is keeping my pace tuned."
	mood_change = 2
	timeout = 3 MINUTES



//CYBERPUNK BUILD - rebuild and delete before release
/proc/cyberpunk_area_turfs(area/target_area)
	var/list/turfs = list()
	if(!target_area)
		return turfs
	for(var/list/zlevel_turfs as anything in target_area.get_zlevel_turf_lists())
		turfs += zlevel_turfs
	return turfs

/proc/cyberpunk_is_apartment_area(area/target_area)
	return istype(target_area, /area/station/commons/dorms/persistent_apartment) || istype(target_area, /area/station/commons/dorms/apartment1) || istype(target_area, /area/station/commons/dorms/apartment2)

/proc/cyberpunk_persistent_read_var(datum/source, var_name, fallback = null)
	if(!source || !(var_name in source.vars))
		return fallback
	return source.vars[var_name]

/proc/cyberpunk_persistent_write_var(datum/target, var_name, value)
	if(!target || !(var_name in target.vars))
		return FALSE
	target.vars[var_name] = value
	return TRUE

/proc/cyberpunk_persistent_capture_reagents(atom/movable/thing)
	var/list/reagent_records = list()
	if(!thing?.reagents)
		return reagent_records
	for(var/datum/reagent/reagent as anything in thing.reagents.reagent_list)
		reagent_records += list(list(
			"type" = "[reagent.type]",
			"volume" = reagent.volume,
		))
	return reagent_records

/proc/cyberpunk_persistent_capture_movable(atom/movable/thing, turf/base_turf, turf/center, obj/machinery/active_terminal, depth = 0)
	if(!thing || thing == active_terminal || ismob(thing))
		return null
	if(!(isitem(thing) || istype(thing, /obj/machinery) || istype(thing, /obj/structure)))
		return null
	var/list/req_access = cyberpunk_persistent_read_var(thing, "req_access")
	var/list/req_one_access = cyberpunk_persistent_read_var(thing, "req_one_access")
	var/list/entry = list(
		"type" = "[thing.type]",
		"name" = thing.name,
		"desc" = thing.desc,
		"x" = base_turf.x - center.x,
		"y" = base_turf.y - center.y,
		"z" = base_turf.z - center.z,
		"dir" = thing.dir,
		"pixel_x" = thing.pixel_x,
		"pixel_y" = thing.pixel_y,
		"pixel_z" = thing.pixel_z,
		"anchored" = thing.anchored,
		"density" = thing.density,
		"opacity" = thing.opacity,
		"alpha" = thing.alpha,
		"color" = thing.color,
		"icon_state" = thing.icon_state,
		"base_icon_state" = cyberpunk_persistent_read_var(thing, "base_icon_state"),
		"integrity" = cyberpunk_persistent_read_var(thing, "atom_integrity"),
		"max_integrity" = cyberpunk_persistent_read_var(thing, "max_integrity"),
		"machine_stat" = cyberpunk_persistent_read_var(thing, "machine_stat"),
		"manufacturer" = cyberpunk_persistent_read_var(thing, "manufacturer"),
		"corp_manufacturer" = cyberpunk_persistent_read_var(thing, "corp_manufacturer"),
		"req_access" = islist(req_access) ? req_access.Copy() : null,
		"req_one_access" = islist(req_one_access) ? req_one_access.Copy() : null,
	)
	var/list/reagent_records = cyberpunk_persistent_capture_reagents(thing)
	if(length(reagent_records))
		entry["reagents"] = reagent_records
	var/obj/item/clothing/clothing = thing
	if(istype(clothing) && islist(clothing.cyberpunk_custom_design_data))
		entry["clothing_design"] = clothing.cyberpunk_custom_design_data.Copy()
	if(depth < 3 && length(thing.contents))
		var/list/content_records = list()
		for(var/atom/movable/content as anything in thing.contents)
			var/list/content_entry = cyberpunk_persistent_capture_movable(content, base_turf, center, active_terminal, depth + 1)
			if(content_entry)
				content_records += list(content_entry)
		if(length(content_records))
			entry["contents"] = content_records
	return entry

/proc/cyberpunk_persistent_restore_movable(list/entry, atom/location, area/target_area, turf/center, obj/machinery/active_terminal)
	if(!islist(entry) || !location)
		return null
	var/movable_path = text2path("[entry["type"]]")
	if(!ispath(movable_path, /atom/movable))
		return null
	var/turf/target_turf = isturf(location) ? location : get_turf(location)
	if(!target_turf || get_area(target_turf) != target_area)
		return null
	var/atom/movable/restored_atom = new movable_path(location)
	if(restored_atom == active_terminal)
		return null
	restored_atom.name = entry["name"] || restored_atom.name
	restored_atom.desc = entry["desc"] || restored_atom.desc
	restored_atom.dir = entry["dir"] || SOUTH
	restored_atom.pixel_x = entry["pixel_x"] || 0
	restored_atom.pixel_y = entry["pixel_y"] || 0
	restored_atom.pixel_z = entry["pixel_z"] || 0
	restored_atom.anchored = !!entry["anchored"]
	restored_atom.density = !!entry["density"]
	restored_atom.opacity = !!entry["opacity"]
	restored_atom.alpha = isnum(entry["alpha"]) ? entry["alpha"] : restored_atom.alpha
	restored_atom.color = entry["color"] || restored_atom.color
	if(entry["icon_state"])
		restored_atom.icon_state = entry["icon_state"]
	cyberpunk_persistent_write_var(restored_atom, "base_icon_state", entry["base_icon_state"])
	cyberpunk_persistent_write_var(restored_atom, "atom_integrity", entry["integrity"])
	cyberpunk_persistent_write_var(restored_atom, "max_integrity", entry["max_integrity"])
	cyberpunk_persistent_write_var(restored_atom, "machine_stat", entry["machine_stat"])
	cyberpunk_persistent_write_var(restored_atom, "manufacturer", entry["manufacturer"])
	cyberpunk_persistent_write_var(restored_atom, "corp_manufacturer", entry["corp_manufacturer"])
	var/list/req_access = entry["req_access"]
	if(islist(req_access))
		cyberpunk_persistent_write_var(restored_atom, "req_access", req_access.Copy())
	var/list/req_one_access = entry["req_one_access"]
	if(islist(req_one_access))
		cyberpunk_persistent_write_var(restored_atom, "req_one_access", req_one_access.Copy())
	if(restored_atom.reagents && islist(entry["reagents"]))
		restored_atom.reagents.clear_reagents()
		for(var/list/reagent_entry as anything in entry["reagents"])
			var/reagent_path = text2path("[reagent_entry["type"]]")
			var/volume = max(0, reagent_entry["volume"] || 0)
			if(ispath(reagent_path, /datum/reagent) && volume)
				restored_atom.reagents.add_reagent(reagent_path, volume)
	var/obj/item/clothing/clothing = restored_atom
	if(istype(clothing) && islist(entry["clothing_design"]))
		clothing.cyberpunk_apply_design(entry["clothing_design"])
	if(islist(entry["contents"]))
		for(var/list/content_entry as anything in entry["contents"])
			cyberpunk_persistent_restore_movable(content_entry, restored_atom, target_area, center, active_terminal)
	return restored_atom

/proc/cyberpunk_persistent_area_capture(area/target_area, obj/machinery/active_terminal)
	var/list/snapshot = list(
		"turfs" = list(),
		"movables" = list(),
	)
	var/turf/center = get_turf(active_terminal)
	if(!target_area || !center)
		return snapshot
	for(var/turf/area_turf as anything in cyberpunk_area_turfs(target_area))
		snapshot["turfs"] += list(list(
			"type" = "[area_turf.type]",
			"x" = area_turf.x - center.x,
			"y" = area_turf.y - center.y,
			"z" = area_turf.z - center.z,
		))
		for(var/atom/movable/thing as anything in area_turf.contents)
			var/list/entry = cyberpunk_persistent_capture_movable(thing, area_turf, center, active_terminal)
			if(entry)
				snapshot["movables"] += list(entry)
	return snapshot

/proc/cyberpunk_persistent_area_restore(area/target_area, obj/machinery/active_terminal, list/snapshot)
	if(!target_area || !active_terminal || !islist(snapshot))
		return 0
	var/turf/center = get_turf(active_terminal)
	if(!center)
		return 0
	for(var/turf/area_turf as anything in cyberpunk_area_turfs(target_area))
		for(var/atom/movable/thing as anything in area_turf.contents)
			if(thing == active_terminal || ismob(thing))
				continue
			qdel(thing)
	var/list/turf_entries = snapshot["turfs"]
	if(islist(turf_entries))
		for(var/list/entry as anything in turf_entries)
			var/turf_path = text2path("[entry["type"]]")
			if(!ispath(turf_path, /turf))
				continue
			var/turf/target = locate(clamp(center.x + (entry["x"] || 0), 1, world.maxx), clamp(center.y + (entry["y"] || 0), 1, world.maxy), clamp(center.z + (entry["z"] || 0), 1, world.maxz))
			if(!target || get_area(target) != target_area)
				continue
			target.ChangeTurf(turf_path, null, CHANGETURF_INHERIT_AIR)
	var/restored = 0
	var/list/movable_entries = snapshot["movables"]
	if(islist(movable_entries))
		for(var/list/entry as anything in movable_entries)
			var/movable_path = text2path("[entry["type"]]")
			if(!ispath(movable_path, /atom/movable))
				continue
			var/turf/target = locate(clamp(center.x + (entry["x"] || 0), 1, world.maxx), clamp(center.y + (entry["y"] || 0), 1, world.maxy), clamp(center.z + (entry["z"] || 0), 1, world.maxz))
			if(!target || get_area(target) != target_area)
				continue
			if(cyberpunk_persistent_restore_movable(entry, target, target_area, center, active_terminal))
				restored++
	return restored

/mob/living/proc/cyberpunk_read_persistent_area_records(preference_type)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return list()
	return preferences.read_preference(preference_type) || list()

/mob/living/proc/cyberpunk_write_persistent_area_records(preference_type, list/records)
	var/datum/preferences/preferences = cyberpunk_prefs()
	if(!preferences)
		return FALSE
	if(!preferences.write_preference(GLOB.preference_entries[preference_type], records))
		return FALSE
	preferences.recently_updated_keys |= preference_type
	preferences.save_character()
	preferences.save_preferences()
	return TRUE

/mob/living/proc/cyberpunk_store_persistent_area_record(preference_type, list/record)
	if(!islist(record) || !record["id"])
		return FALSE
	var/list/result = list()
	for(var/list/existing as anything in cyberpunk_read_persistent_area_records(preference_type))
		if(existing["id"] == record["id"])
			continue
		result += list(existing)
	result = list(record) + result
	return cyberpunk_write_persistent_area_records(preference_type, result)

/mob/living/proc/cyberpunk_find_persistent_area_record(preference_type, record_id)
	if(!record_id)
		return null
	for(var/list/record as anything in cyberpunk_read_persistent_area_records(preference_type))
		if(record["id"] == record_id)
			return record
	return null

/proc/cyberpunk_persistent_access_id(kind, owner_character_key, area_type)
	return "persistent:[kind]:[owner_character_key]:[area_type]"

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
