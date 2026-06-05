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
		if(!adjust_money(-amount, "Прочее: Оплата долга"))
			return 0
	else
		add_log_to_history(-amount, "Прочее: Взыскание долгов")
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
		var/reason_to = "Перевод: От [from.account_holder]"
		var/reason_from = "Перевод: [account_holder]"

		if(IS_DEPARTMENTAL_ACCOUNT(from))
			reason_to = "Нанотрейзен: Зарплата"
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
/datum/bank_account/proc/payday(amount_of_paychecks, free = FALSE, skippable = FALSE, event = "Выплата зарплаты")
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
		adjust_money(money_to_transfer, "Нанотрейзен: Оплата смены")
		SSblackbox.record_feedback("amount", "free_income", money_to_transfer)
		SSeconomy.station_target += money_to_transfer
		log_econ("[money_to_transfer][MONEY_NAME] were given to [src.account_holder]'s account from income.")
		return TRUE
	var/datum/bank_account/department_account = SSeconomy.get_dep_account(account_job.paycheck_department)
	if(isnull(department_account))
		bank_card_talk("ОШИБКА: [event] отменена. Не удалось связаться со счётом отдела.")
		return FALSE
	if(!transfer_money(department_account, money_to_transfer))
		bank_card_talk("ОШИБКА: [event] отменена. Средств отдела недостаточно.")
		return FALSE
	bank_card_talk("[event] успешна. На аккаунте теперь [account_balance][MONEY_SYMBOL].")
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

#define CYBERPUNK_CONTRACT_CREATED "created"
#define CYBERPUNK_CONTRACT_OFFERED "offered"
#define CYBERPUNK_CONTRACT_ACCEPTED "accepted"
#define CYBERPUNK_CONTRACT_COMPLETED "completed"
#define CYBERPUNK_CONTRACT_FAILED "failed"
#define CYBERPUNK_CONTRACT_CANCELLED "cancelled"

#define CYBERPUNK_CONTRACT_DELIVERY "delivery"
#define CYBERPUNK_CONTRACT_REPAIR "repair"
#define CYBERPUNK_CONTRACT_BUILD "build"
#define CYBERPUNK_CONTRACT_GUARD "guard"
#define CYBERPUNK_CONTRACT_MINING "mining"
#define CYBERPUNK_CONTRACT_SABOTAGE "sabotage"
#define CYBERPUNK_CONTRACT_ELIMINATION "elimination"

#define CYBERPUNK_CONTRACT_TAX_RATE 0.05

//CYBERPUNK BUILD - rebuild and delete before release
#define CYBERPUNK_CORP_BENN "benn"
#define CYBERPUNK_CORP_RYAZNOV "ryaznov"
#define CYBERPUNK_CORP_STARLIGHT "starlight"
#define CYBERPUNK_CORP_GOVERNMENT "government"
#define CYBERPUNK_CORP_STARTING_BUDGET 15000
#define CYBERPUNK_CORP_RESEARCH_TO_CREDITS 50
#define CYBERPUNK_CORP_LEVEL_STEP 100

/datum/controller/subsystem/economy/proc/get_cyberpunk_corporation(corporation_id)
	ensure_cyberpunk_corporations_seeded()
	return cyberpunk_corporations[cyberpunk_normalize_corporation_id(corporation_id)]

/datum/controller/subsystem/economy/proc/cyberpunk_normalize_corporation_id(corporation_id)
	var/corp_id = lowertext(trim("[corporation_id]"))
	switch(corp_id)
		if("benn", "ben", "bэн", "бэнь")
			return CYBERPUNK_CORP_BENN
		if("ryaznov", "riaznov", "рязнов")
			return CYBERPUNK_CORP_RYAZNOV
		if("starlight", "старлайт")
			return CYBERPUNK_CORP_STARLIGHT
		if("government", "gov", "nanotrasen", "правительство")
			return CYBERPUNK_CORP_GOVERNMENT
	return corp_id

/datum/controller/subsystem/economy/proc/get_cyberpunk_public_corporation_names(include_government = FALSE)
	ensure_cyberpunk_corporations_seeded()
	var/list/names = list()
	for(var/corporation_id in cyberpunk_corporations)
		var/datum/cyberpunk_corporation/corporation = cyberpunk_corporations[corporation_id]
		if(corporation.hidden && !include_government)
			continue
		names += corporation.name
	return names

/datum/controller/subsystem/economy/proc/ensure_cyberpunk_corporations_seeded()
	if(cyberpunk_corporations_seeded)
		return
	cyberpunk_corporations_seeded = TRUE
	create_cyberpunk_corporation(CYBERPUNK_CORP_BENN)
	create_cyberpunk_corporation(CYBERPUNK_CORP_RYAZNOV)
	create_cyberpunk_corporation(CYBERPUNK_CORP_STARLIGHT)
	create_cyberpunk_corporation(CYBERPUNK_CORP_GOVERNMENT)

/datum/controller/subsystem/economy/proc/create_cyberpunk_corporation(corporation_id)
	corporation_id = cyberpunk_normalize_corporation_id(corporation_id)
	if(cyberpunk_corporations[corporation_id])
		return cyberpunk_corporations[corporation_id]
	var/datum/cyberpunk_corporation/corporation = new(corporation_id)
	corporation.ensure_account()
	cyberpunk_corporations[corporation_id] = corporation
	return corporation

/datum/controller/subsystem/economy/proc/record_cyberpunk_corporate_activity(corporation_id, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	if(!corporation)
		return FALSE
	if(data_amount)
		corporation.add_data(data_type, data_amount, source)
	if(credit_amount)
		corporation.add_funds(credit_amount, source)
	return TRUE

/datum/controller/subsystem/economy/proc/cyberpunk_corporation_id_from_manufacturer(manufacturer)
	var/manufacturer_id = cyberpunk_normalize_corporation_id(manufacturer)
	if(cyberpunk_corporations[manufacturer_id])
		return manufacturer_id
	var/manufacturer_text = lowertext(trim("[manufacturer]"))
	if(findtext(manufacturer_text, "benn") || findtext(manufacturer_text, "ben"))
		return CYBERPUNK_CORP_BENN
	if(findtext(manufacturer_text, "ryaznov") || findtext(manufacturer_text, "riaznov"))
		return CYBERPUNK_CORP_RYAZNOV
	if(findtext(manufacturer_text, "starlight"))
		return CYBERPUNK_CORP_STARLIGHT
	if(findtext(manufacturer_text, "government") || findtext(manufacturer_text, "nanotrasen"))
		return CYBERPUNK_CORP_GOVERNMENT
	return null

/datum/controller/subsystem/economy/proc/cyberpunk_corporation_has_edict(corporation_id, edict_id)
	var/datum/cyberpunk_corporation/corporation = get_cyberpunk_corporation(corporation_id)
	return corporation?.has_edict(edict_id)

/datum/controller/subsystem/economy/proc/cyberpunk_manufacturer_has_edict(manufacturer, edict_id)
	return cyberpunk_corporation_has_edict(cyberpunk_corporation_id_from_manufacturer(manufacturer), edict_id)

/datum/controller/subsystem/economy/proc/record_cyberpunk_manufacturer_activity(manufacturer, data_type = "general", data_amount = 0, credit_amount = 0, source = "activity")
	return record_cyberpunk_corporate_activity(cyberpunk_corporation_id_from_manufacturer(manufacturer), data_type, data_amount, credit_amount, source)

/datum/controller/subsystem/economy/proc/cyberpunk_corporate_edict_multiplier(manufacturer, list/edict_ids, default_multiplier = 1, active_multiplier = 1.1)
	var/corporation_id = cyberpunk_corporation_id_from_manufacturer(manufacturer)
	if(!corporation_id)
		return default_multiplier
	for(var/edict_id in edict_ids)
		if(cyberpunk_corporation_has_edict(corporation_id, edict_id))
			return active_multiplier
	return default_multiplier

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
			subsidiaries = list("Benn Bio", "Benn Clinic", "Benn Shadow")
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
			subsidiaries = list("Ryaznov Works", "Ryaznov Energy", "Ryaznov Defense")
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
			subsidiaries = list("Starlight Logistics", "Starlight Transit", "Starlight Market")
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
			subsidiaries = list("Council", "Police", "City Treasury")
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

/datum/cyberpunk_corporation/proc/add_data(data_type, amount, source = "activity")
	data_type = lowertext(trim("[data_type]")) || "general"
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	research_data[data_type] = (research_data[data_type] || 0) + amount
	research_points += amount
	experience += amount
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

/datum/cyberpunk_corporation/proc/unlock_technology(technology_id)
	var/list/technology = get_technology(technology_id)
	if(!technology || unlocked_technologies[technology_id])
		return FALSE
	var/prereq = technology["prereq"]
	if(prereq && !unlocked_technologies[prereq])
		return FALSE
	var/cost = round((technology["cost"] || 0) * (1 - get_foreign_technology_bonus()))
	if(research_points < cost)
		return FALSE
	research_points -= cost
	unlocked_technologies[technology_id] = TRUE
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
		technology_records += list(list(
			"id" = technology_id,
			"name" = technology["name"],
			"tier" = technology["tier"],
			"cost" = technology["cost"],
			"prereq" = prereq,
			"description" = technology["description"],
			"unlocked" = !!unlocked_technologies[technology_id],
			"canUnlock" = !unlocked_technologies[technology_id] && (!prereq || unlocked_technologies[prereq]) && research_points >= (technology["cost"] || 0),
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
	return list(
		"id" = id,
		"name" = name,
		"group" = group,
		"direction" = direction,
		"combatDoctrine" = combat_doctrine,
		"hidden" = hidden,
		"subsidiaries" = subsidiaries,
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
	SSeconomy.ensure_cyberpunk_corporations_seeded()
	var/mob/living/living_user = isliving(user) ? user : null
	var/list/corporations = list()
	var/locked_id = SSeconomy.cyberpunk_normalize_corporation_id(locked_corporation_id)
	var/selected_id = SSeconomy.cyberpunk_normalize_corporation_id(selected_corporation_id)
	if(locked_id && selected_id != locked_id)
		selected_id = locked_id
	var/datum/cyberpunk_corporation/selected_corporation
	for(var/corporation_id in SSeconomy.cyberpunk_corporations)
		if(locked_id && corporation_id != locked_id)
			continue
		var/datum/cyberpunk_corporation/corporation = SSeconomy.cyberpunk_corporations[corporation_id]
		var/list/corporation_data = corporation.to_ui_data(TRUE)
		if(!corporation_data)
			continue
		corporations += list(corporation_data)
		if(corporation.id == selected_id)
			selected_corporation = corporation
	if(!selected_corporation && length(corporations))
		var/list/first_corporation = corporations[1]
		selected_corporation = SSeconomy.cyberpunk_corporations[first_corporation["id"]]
	var/datum/bank_account/user_account = living_user?.get_bank_account()
	return list(
		"accountName" = user_account?.account_holder,
		"accountBalance" = user_account?.account_balance || 0,
		"corporations" = corporations,
		"selected" = selected_corporation?.to_ui_data(TRUE),
	)

/proc/cyberpunk_corporations_ui_act(action, list/params, mob/user)
	var/datum/cyberpunk_corporation/corporation = SSeconomy.get_cyberpunk_corporation(params && params["corporation_id"])
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
			var/datum/cyberpunk_corporation/victim = SSeconomy.get_cyberpunk_corporation(params["target_corporation_id"])
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
	var/datum/cyberpunk_corporation/corporation = SSeconomy.get_cyberpunk_corporation(corporation_id)
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
	SSeconomy.record_cyberpunk_corporate_activity(corporation_id, "bio", 2, 0, "Benn service completed: [service_id]")
	return TRUE

/proc/cyberpunk_complete_ryaznov_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SSeconomy.get_cyberpunk_corporation(corporation_id)
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
		SSeconomy.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov salvage service completed")
		to_chat(user, span_notice("Ryaznov salvage service delivers an industrial pack."))
		return TRUE
	if(service_id == "power")
		for(var/obj/machinery/nearby_machine in range(1, user))
			nearby_machine.repair_cyberpunk_machine_wear(repair_amount, user)
		SSeconomy.record_cyberpunk_corporate_activity(corporation_id, "engineering", 2, 0, "Ryaznov power service completed")
		to_chat(user, span_notice("Ryaznov power tuning refreshes nearby machinery components."))
		return TRUE
	if(!repair_target)
		to_chat(user, span_warning("Ryaznov field service finds no damaged nearby object."))
		return FALSE
	var/applied_repair = repair_target.repair_damage(repair_amount)
	var/obj/machinery/repaired_machine = repair_target
	if(istype(repaired_machine))
		repaired_machine.repair_cyberpunk_machine_wear(repair_amount, user)
	SSeconomy.record_cyberpunk_corporate_activity(corporation_id, "engineering", max(1, round(applied_repair / 10)), 0, "Ryaznov service completed: [service_id]")
	to_chat(user, span_notice("Ryaznov field service repairs [repair_target] by [applied_repair] integrity."))
	return TRUE

/proc/cyberpunk_complete_starlight_service(datum/weakref/user_ref, corporation_id, service_id)
	var/mob/living/user = user_ref?.resolve()
	if(!user || QDELETED(user))
		return FALSE
	var/datum/cyberpunk_corporation/corporation = SSeconomy.get_cyberpunk_corporation(corporation_id)
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
	SSeconomy.record_cyberpunk_corporate_activity(corporation_id, "market", 2, 0, "Starlight service completed: [service_id]")
	return TRUE

/datum/mood_event/starlight_influence
	description = "Starlight's feed is keeping my pace tuned."
	mood_change = 2
	timeout = 3 MINUTES

/datum/controller/subsystem/economy/proc/get_cyberpunk_contract(contract_id)
	return cyberpunk_contracts["[contract_id]"]

/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_character_key(mob/living/person, datum/bank_account/account)
	var/name = account?.account_holder || person?.real_name || person?.name
	return ckey(name)

/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_stats(ckey)
	ckey = ckey(ckey)
	if(!ckey)
		return list("created" = 0, "accepted" = 0, "completed" = 0, "failed" = 0, "cancelled" = 0)
	if(!cyberpunk_contract_stats[ckey])
		cyberpunk_contract_stats[ckey] = list("created" = 0, "accepted" = 0, "completed" = 0, "failed" = 0, "cancelled" = 0)
	return cyberpunk_contract_stats[ckey]

/datum/controller/subsystem/economy/proc/adjust_cyberpunk_contract_stat(ckey, stat_key, amount = 1)
	var/list/stats = get_cyberpunk_contract_stats(ckey)
	stats[stat_key] = (stats[stat_key] || 0) + amount

/datum/controller/subsystem/economy/proc/find_cyberpunk_contract_person(character_name)
	var/character_key = ckey(character_name)
	if(!character_key)
		return null
	for(var/mob/living/person as anything in GLOB.player_list)
		if(get_cyberpunk_contract_character_key(person, person.get_bank_account()) == character_key)
			return person
	return null

/datum/controller/subsystem/economy/proc/ensure_cyberpunk_contract_pool_seeded()
	if(cyberpunk_contract_pool_seeded)
		return
	cyberpunk_contract_pool_seeded = TRUE
	var/list/corporations = get_cyberpunk_public_corporation_names()
	for(var/corporation in corporations)
		var/contract_count = rand(3, 4)
		for(var/i in 1 to contract_count)
			create_cyberpunk_generated_pool_contract(corporation)

/datum/controller/subsystem/economy/proc/create_cyberpunk_generated_pool_contract(corporation)
	var/contract_type = pick(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_REPAIR, CYBERPUNK_CONTRACT_BUILD, CYBERPUNK_CONTRACT_MINING, CYBERPUNK_CONTRACT_SABOTAGE)
	var/target = "work order"
	var/description = "Corporate pool work order. Details are intentionally brief for the first production pass."
	var/required_amount = 1
	var/required_percent = 75
	switch(contract_type)
		if(CYBERPUNK_CONTRACT_DELIVERY)
			target = pick("sealed packet", "data disk", "medical crate", "machine component")
			description = "Deliver the marked cargo to the corporate representative."
		if(CYBERPUNK_CONTRACT_REPAIR)
			target = pick("door", "machine", "terminal", "generator")
			description = "Restore the target above the required integrity threshold."
			required_percent = rand(65, 90)
		if(CYBERPUNK_CONTRACT_BUILD)
			target = pick("barricade", "table", "window", "structure")
			description = "Build the requested structure in the assigned area."
		if(CYBERPUNK_CONTRACT_MINING)
			target = pick("ore", "glass", "metal", "plasma")
			description = "Submit the requested resource stack."
			required_amount = rand(3, 8)
		if(CYBERPUNK_CONTRACT_SABOTAGE)
			target = pick("door", "camera", "terminal", "machine")
			description = "Damage or disable the target to the required threshold."
			required_percent = rand(0, 40)

	var/datum/cyberpunk_contract/contract = new
	contract.id = next_cyberpunk_contract_id++
	contract.title = "[corporation] pool job #[contract.id]"
	contract.description = description
	contract.contract_type = contract_type
	contract.target_text = target
	contract.creator_name = corporation
	contract.creator_character_key = ckey("corp-[corporation]")
	contract.payment = rand(150, 650)
	contract.deposit = rand(0, 2) ? 0 : rand(25, 100)
	contract.penalty = rand(0, 2) ? 0 : rand(25, 100)
	contract.escrow_payment = contract.payment
	contract.legal = TRUE
	contract.public_contract = TRUE
	contract.pool_contract = TRUE
	contract.pool_corporation = corporation
	contract.generated_pool_contract = TRUE
	contract.required_amount = required_amount
	contract.required_percent = required_percent
	contract.due_time = world.time + rand(35, 90) MINUTES
	contract.created_at = world.time
	contract.add_history("generated by [corporation] corporate pool; [contract.payment][MONEY_SYMBOL] reserved")
	cyberpunk_contracts["[contract.id]"] = contract
	addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/cyberpunk_contract, timeout_check)), contract.due_time - world.time, TIMER_STOPPABLE)
	return contract

/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_pool()
	ensure_cyberpunk_contract_pool_seeded()
	var/list/contracts = list()
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(contract?.pool_contract && contract.status == CYBERPUNK_CONTRACT_CREATED)
			contracts += contract
	return contracts

/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_repair(mob/living/user, atom/target)
	if(!user || !target || target.max_integrity <= 0)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_REPAIR)
			continue
		if(!contract.matches_target(target))
			continue
		if(target.get_integrity_percentage() * 100 < contract.required_percent)
			continue
		contract.add_history("[user.real_name || user.name] repaired [target] to contract threshold")
		if(!contract.creator_confirm_required)
			contract.complete("repair threshold reached")
		return TRUE
	return FALSE

/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_sabotage(mob/living/user, atom/target)
	if(!user || !target || target.max_integrity <= 0)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_SABOTAGE)
			continue
		if(!contract.matches_target(target))
			continue
		if(target.get_integrity_percentage() * 100 > contract.required_percent)
			continue
		contract.add_history("[user.real_name || user.name] sabotaged [target] to contract threshold")
		if(!contract.creator_confirm_required)
			contract.complete("sabotage threshold reached")
		return TRUE
	return FALSE

/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_construction(mob/living/user, atom/target)
	if(!user || !target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract?.can_act_as_contractor(user) || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_BUILD)
			continue
		if(!contract.matches_target(target))
			continue
		contract.add_history("[user.real_name || user.name] constructed [target]")
		if(!contract.creator_confirm_required)
			contract.complete("construction target built")
		return TRUE
	return FALSE

/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_elimination(mob/living/target)
	if(!target)
		return FALSE
	for(var/contract_id in cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = cyberpunk_contracts[contract_id]
		if(!contract || contract.status != CYBERPUNK_CONTRACT_ACCEPTED || contract.contract_type != CYBERPUNK_CONTRACT_ELIMINATION)
			continue
		if(contract.contractor_ckey != target.lastattackerckey)
			continue
		if(contract.target_text && !findtext(lowertext(target.real_name || target.name), lowertext(contract.target_text)))
			continue
		if(target.stat != DEAD && target.health > HEALTH_THRESHOLD_CRIT)
			continue
		contract.add_history("[target.real_name || target.name] was eliminated by [contract.contractor_name]")
		if(!contract.creator_confirm_required)
			contract.complete("target incapacitated")
		return TRUE
	return FALSE

/datum/controller/subsystem/economy/proc/record_cyberpunk_contract_item_in_hands(mob/living/holder, obj/item/item)
	if(!holder || !item?.cyberpunk_contract_id)
		return FALSE
	var/datum/cyberpunk_contract/contract = get_cyberpunk_contract(item.cyberpunk_contract_id)
	return contract?.record_delivery_contact(item, holder)

/datum/controller/subsystem/economy/proc/create_cyberpunk_contract(mob/living/creator, list/params)
	var/datum/bank_account/creator_account = creator?.get_bank_account()
	if(!creator_account)
		return null

	var/payment = max(0, round(text2num(params["payment"])))
	var/deposit = max(0, round(text2num(params["deposit"])))
	var/penalty = max(0, round(text2num(params["penalty"])))
	var/is_legal = text2num(params["legal"]) ? TRUE : FALSE
	if(payment <= 0 || !creator_account.has_money(payment))
		return null

	var/contract_type = params["contract_type"] || CYBERPUNK_CONTRACT_DELIVERY
	var/static/list/valid_contract_types = list(
		CYBERPUNK_CONTRACT_DELIVERY,
		CYBERPUNK_CONTRACT_REPAIR,
		CYBERPUNK_CONTRACT_BUILD,
		CYBERPUNK_CONTRACT_GUARD,
		CYBERPUNK_CONTRACT_MINING,
		CYBERPUNK_CONTRACT_SABOTAGE,
		CYBERPUNK_CONTRACT_ELIMINATION,
	)
	if(!(contract_type in valid_contract_types))
		contract_type = CYBERPUNK_CONTRACT_DELIVERY

	var/title = reject_bad_text(params["title"], max_length = 48, ascii_only = FALSE)
	var/target = reject_bad_text(params["target"], max_length = 64, ascii_only = FALSE)
	var/description = reject_bad_text(params["description"], max_length = 240, ascii_only = FALSE)
	var/assigned_contractor = reject_bad_text(params["assigned_contractor"], max_length = 64, ascii_only = FALSE)
	var/pool_contract = text2num(params["pool_contract"]) ? TRUE : FALSE
	var/pool_corporation = reject_bad_text(params["pool_corporation"], max_length = 64, ascii_only = FALSE)
	if(!title)
		title = "Contract #[next_cyberpunk_contract_id]"
	if(!target)
		target = "unspecified target"

	var/escrow_reason = is_legal ? "Legal contract escrow: [title]" : "Off-ledger contract escrow: [title]"
	if(!creator_account.adjust_money(-payment, escrow_reason))
		return null

	var/datum/cyberpunk_contract/contract = new
	contract.id = next_cyberpunk_contract_id++
	contract.title = title
	contract.description = description
	contract.contract_type = contract_type
	contract.target_text = target
	contract.creator_ckey = creator.ckey
	contract.creator_name = creator.real_name || creator.name
	contract.creator_account_id = creator_account.account_id
	contract.creator_character_key = get_cyberpunk_contract_character_key(creator, creator_account)
	contract.assigned_contractor_name = assigned_contractor
	contract.assigned_contractor_key = ckey(assigned_contractor)
	contract.payment = payment
	contract.deposit = deposit
	contract.penalty = penalty
	contract.escrow_payment = payment
	contract.legal = is_legal
	contract.public_contract = text2num(params["public_contract"]) ? TRUE : FALSE
	contract.pool_contract = pool_contract
	contract.pool_corporation = pool_corporation
	contract.creator_confirm_required = text2num(params["creator_confirm_required"]) ? TRUE : FALSE
	contract.required_amount = max(1, round(text2num(params["required_amount"]) || 1))
	contract.required_percent = clamp(round(text2num(params["required_percent"]) || 75), 0, 100)
	contract.due_time = world.time + clamp(round(text2num(params["duration_minutes"]) || 30), 1, 180) MINUTES
	contract.created_at = world.time
	contract.add_history("created by [contract.creator_name]; [payment][MONEY_SYMBOL] reserved")
	if(assigned_contractor)
		contract.add_history("assigned contractor: [assigned_contractor]")
		contract.status = CYBERPUNK_CONTRACT_OFFERED
	if(pool_contract)
		contract.public_contract = TRUE
		contract.add_history("published into contract pool[pool_corporation ? " for [pool_corporation]" : ""]")
	cyberpunk_contracts["[contract.id]"] = contract
	adjust_cyberpunk_contract_stat(contract.creator_character_key, "created")
	addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/cyberpunk_contract, timeout_check)), contract.due_time - world.time, TIMER_STOPPABLE)
	if(assigned_contractor)
		contract.notify_assigned_contractor()
	return contract

/datum/cyberpunk_contract
	var/id = 0
	var/title = "Contract"
	var/description = ""
	var/contract_type = CYBERPUNK_CONTRACT_DELIVERY
	var/target_text = ""
	var/status = CYBERPUNK_CONTRACT_CREATED
	var/creator_ckey
	var/creator_name
	var/creator_character_key
	var/creator_account_id
	var/contractor_ckey
	var/contractor_name
	var/contractor_character_key
	var/contractor_account_id
	var/assigned_contractor_name
	var/assigned_contractor_key
	var/payment = 0
	var/deposit = 0
	var/penalty = 0
	var/escrow_payment = 0
	var/escrow_deposit = 0
	var/legal = TRUE
	var/public_contract = TRUE
	var/pool_contract = FALSE
	var/pool_corporation
	var/generated_pool_contract = FALSE
	var/creator_confirm_required = FALSE
	var/created_at = 0
	var/accepted_at = 0
	var/due_time = 0
	var/required_amount = 1
	var/delivered_amount = 0
	var/required_percent = 75
	var/tax_paid = 0
	var/list/history = list()
	var/list/obj/item/delivery_items = list()
	var/mob/living/tracked_creator

/datum/cyberpunk_contract/proc/get_creator_account()
	return SSeconomy.bank_accounts_by_id["[creator_account_id]"]

/datum/cyberpunk_contract/proc/get_contractor_account()
	return SSeconomy.bank_accounts_by_id["[contractor_account_id]"]

/datum/cyberpunk_contract/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_contract/proc/user_character_key(mob/living/user)
	return SSeconomy.get_cyberpunk_contract_character_key(user, user?.get_bank_account())

/datum/cyberpunk_contract/proc/can_view(mob/living/user)
	if(public_contract && legal)
		return TRUE
	var/character_key = user_character_key(user)
	if(character_key == creator_character_key || character_key == contractor_character_key || character_key == assigned_contractor_key)
		return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/can_manage(mob/living/user)
	return user_character_key(user) == creator_character_key

/datum/cyberpunk_contract/proc/can_act_as_contractor(mob/living/user)
	return user_character_key(user) == contractor_character_key

/datum/cyberpunk_contract/proc/can_accept(mob/living/user)
	if(!(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED)) || !user || can_manage(user))
		return FALSE
	if(!assigned_contractor_key)
		return TRUE
	return user_character_key(user) == assigned_contractor_key

/datum/cyberpunk_contract/proc/can_refuse(mob/living/user)
	return status == CYBERPUNK_CONTRACT_OFFERED && user_character_key(user) == assigned_contractor_key

/datum/cyberpunk_contract/proc/refuse_offer(mob/living/user)
	if(!can_refuse(user))
		return FALSE
	add_history("[user.real_name || user.name] refused assigned offer")
	assigned_contractor_name = null
	assigned_contractor_key = null
	status = CYBERPUNK_CONTRACT_CREATED
	return TRUE

/datum/cyberpunk_contract/proc/notify_assigned_contractor()
	var/mob/living/target = SSeconomy.find_cyberpunk_contract_person(assigned_contractor_name)
	if(!target)
		return FALSE
	to_chat(target, span_notice("You received contract offer #[id]: [title]."))
	var/datum/cyberpunk_contract_offer_verb_ui/interface = new(id)
	interface.ui_interact(target)
	return TRUE

/datum/cyberpunk_contract/proc/matches_target(atom/target)
	if(!target)
		return FALSE
	if(!target_text)
		return TRUE
	var/normalized_target = lowertext(target_text)
	return findtext(lowertext(target.name), normalized_target) || findtext(lowertext("[target.type]"), normalized_target)

/datum/cyberpunk_contract/proc/accept(mob/living/user)
	if(!can_accept(user))
		return FALSE
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		return FALSE
	if(deposit > 0 && !account.adjust_money(-deposit, "Contract deposit: [title]"))
		return FALSE
	contractor_ckey = user.ckey
	contractor_name = user.real_name || user.name
	contractor_character_key = SSeconomy.get_cyberpunk_contract_character_key(user, account)
	contractor_account_id = account.account_id
	escrow_deposit = deposit
	status = CYBERPUNK_CONTRACT_ACCEPTED
	accepted_at = world.time
	add_history("accepted by [contractor_name]; deposit [deposit][MONEY_SYMBOL]")
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "accepted")
	return TRUE

/datum/cyberpunk_contract/proc/cancel(mob/living/user)
	if(!can_manage(user) || !(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED)))
		return FALSE
	var/datum/bank_account/creator_account = get_creator_account()
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(escrow_payment > 0)
		creator_account?.adjust_money(escrow_payment, "Contract cancelled: [title]")
		escrow_payment = 0
	if(escrow_deposit > 0)
		contractor_account?.adjust_money(escrow_deposit, "Contract deposit returned: [title]")
		escrow_deposit = 0
	if(status == CYBERPUNK_CONTRACT_ACCEPTED && penalty > 0 && creator_account?.adjust_money(-penalty, "Contract cancellation penalty: [title]"))
		contractor_account?.adjust_money(penalty, "Contract cancellation penalty: [title]")
	status = CYBERPUNK_CONTRACT_CANCELLED
	add_history("cancelled by [user.real_name || user.name]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(creator_character_key, "cancelled")
	return TRUE

/datum/cyberpunk_contract/proc/fail(reason = "failure")
	if(!(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED)))
		return FALSE
	var/datum/bank_account/creator_account = get_creator_account()
	if(escrow_payment > 0)
		creator_account?.adjust_money(escrow_payment, "Contract failed: [title]")
		escrow_payment = 0
	if(escrow_deposit > 0)
		creator_account?.adjust_money(escrow_deposit, "Contract failed deposit: [title]")
		escrow_deposit = 0
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(penalty > 0 && contractor_account?.adjust_money(-penalty, "Contract failure penalty: [title]"))
		creator_account?.adjust_money(penalty, "Contract failure penalty: [title]")
	status = CYBERPUNK_CONTRACT_FAILED
	add_history("failed: [reason]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "failed")
	return TRUE

/datum/cyberpunk_contract/proc/complete(reason = "completion")
	if(status != CYBERPUNK_CONTRACT_ACCEPTED)
		return FALSE
	var/datum/bank_account/contractor_account = get_contractor_account()
	if(!contractor_account)
		return FALSE
	var/payout = escrow_payment
	if(legal)
		var/tax = round(payout * CYBERPUNK_CONTRACT_TAX_RATE)
		if(tax > 0)
			SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(tax, "Contract tax: [title]")
			tax_paid += tax
			payout -= tax
	var/payout_reason = legal ? "Legal contract payout #[id]: [title]; tax [tax_paid][MONEY_SYMBOL]" : "Off-ledger contract payout #[id]: [title]; no tax"
	contractor_account.adjust_money(payout, payout_reason)
	log_econ("Contract #[id] [legal ? "legal" : "off-ledger"] payout [payout][MONEY_NAME] to [contractor_account.account_holder]; tax [tax_paid][MONEY_NAME].")
	escrow_payment = 0
	if(escrow_deposit > 0)
		contractor_account.adjust_money(escrow_deposit, "Contract deposit returned: [title]")
		escrow_deposit = 0
	status = CYBERPUNK_CONTRACT_COMPLETED
	add_history("completed: [reason]")
	if(pool_corporation)
		var/data_type = contract_type == CYBERPUNK_CONTRACT_DELIVERY ? "market" : contract_type
		SSeconomy.record_cyberpunk_corporate_activity(pool_corporation, data_type, max(1, round(payment / 100)), max(1, round(payment * 0.02)), "contract completed #[id]")
	clear_delivery_tracking()
	SSeconomy.adjust_cyberpunk_contract_stat(contractor_character_key, "completed")
	return TRUE

/datum/cyberpunk_contract/proc/timeout_check()
	if(status in list(CYBERPUNK_CONTRACT_CREATED, CYBERPUNK_CONTRACT_OFFERED, CYBERPUNK_CONTRACT_ACCEPTED))
		fail("deadline expired")

/datum/cyberpunk_contract/proc/submit_held_item(mob/living/user)
	if(!can_act_as_contractor(user) || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_MINING)))
		return FALSE
	var/obj/item/held = user.get_active_held_item()
	if(!held)
		return FALSE
	if(held.cyberpunk_contract_id != id && target_text && !findtext(lowertext(held.name), lowertext(target_text)) && !findtext(lowertext("[held.type]"), lowertext(target_text)))
		return FALSE
	if(contract_type == CYBERPUNK_CONTRACT_DELIVERY)
		return record_delivery_contact(held, user)
	var/submitted_name = held.name
	var/amount = 1
	if(isstack(held))
		var/obj/item/stack/stack = held
		amount = min(stack.amount, required_amount - delivered_amount)
		stack.use(amount)
	else
		qdel(held)
	delivered_amount += amount
	add_history("[user.real_name || user.name] submitted [amount]x [submitted_name]")
	if(delivered_amount >= required_amount && !creator_confirm_required)
		return complete("submitted required cargo")
	return TRUE

/datum/cyberpunk_contract/proc/mark_held_item(mob/living/user)
	if(!can_act_as_contractor(user) || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY, CYBERPUNK_CONTRACT_MINING)))
		return FALSE
	var/obj/item/held = user.get_active_held_item()
	if(!held)
		return FALSE
	held.cyberpunk_contract_id = id
	add_history("[user.real_name || user.name] marked [held.name] as contract cargo")
	track_delivery_item(held)
	record_delivery_contact(held, user)
	return TRUE

/datum/cyberpunk_contract/proc/track_delivery_item(obj/item/item)
	if(!item || !(contract_type in list(CYBERPUNK_CONTRACT_DELIVERY)))
		return
	if(!(item in delivery_items))
		delivery_items += item
		RegisterSignal(item, COMSIG_MOVABLE_MOVED, PROC_REF(on_delivery_item_moved))
		RegisterSignal(item, COMSIG_QDELETING, PROC_REF(on_delivery_item_deleted))
	var/mob/living/creator = find_creator_mob()
	if(creator && creator != tracked_creator)
		if(tracked_creator)
			UnregisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED)
		tracked_creator = creator
		RegisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED, PROC_REF(on_delivery_creator_moved))

/datum/cyberpunk_contract/proc/clear_delivery_tracking()
	for(var/obj/item/item as anything in delivery_items)
		UnregisterSignal(item, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
	delivery_items.Cut()
	if(tracked_creator)
		UnregisterSignal(tracked_creator, COMSIG_MOVABLE_MOVED)
		tracked_creator = null

/datum/cyberpunk_contract/proc/find_creator_mob()
	for(var/mob/living/person as anything in GLOB.player_list)
		if(user_character_key(person) == creator_character_key)
			return person
	return null

/datum/cyberpunk_contract/proc/record_delivery_contact(obj/item/item, mob/living/holder)
	if(status != CYBERPUNK_CONTRACT_ACCEPTED || contract_type != CYBERPUNK_CONTRACT_DELIVERY || !item || item.cyberpunk_contract_id != id)
		return FALSE
	var/mob/living/creator = holder && user_character_key(holder) == creator_character_key ? holder : find_creator_mob()
	if(!creator)
		return FALSE
	if(get_dist(get_turf(creator), get_turf(item)) > 1)
		return FALSE
	delivered_amount = max(delivered_amount, required_amount)
	add_history("[item.name] reached creator [creator.real_name || creator.name]")
	if(!creator_confirm_required)
		return complete("cargo delivered to creator")
	return TRUE

/datum/cyberpunk_contract/proc/on_delivery_item_moved(obj/item/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	record_delivery_contact(source)

/datum/cyberpunk_contract/proc/on_delivery_creator_moved(mob/living/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	for(var/obj/item/item as anything in delivery_items)
		record_delivery_contact(item, source)

/datum/cyberpunk_contract/proc/on_delivery_item_deleted(obj/item/source)
	SIGNAL_HANDLER
	delivery_items -= source

/datum/cyberpunk_contract/proc/check_nearby_target(mob/living/user)
	if(!can_act_as_contractor(user))
		return FALSE
	switch(contract_type)
		if(CYBERPUNK_CONTRACT_REPAIR)
			for(var/atom/target in view(1, user))
				if(!matches_target(target))
					continue
				if(target.max_integrity <= 0)
					continue
				if(target.get_integrity_percentage() * 100 >= required_percent)
					add_history("[user.real_name || user.name] verified repair on [target]")
					if(!creator_confirm_required)
						return complete("repair threshold reached")
					return TRUE
		if(CYBERPUNK_CONTRACT_SABOTAGE)
			for(var/atom/target in view(1, user))
				if(!matches_target(target))
					continue
				if(target.max_integrity <= 0)
					continue
				if(target.get_integrity_percentage() * 100 <= required_percent)
					add_history("[user.real_name || user.name] verified sabotage on [target]")
					if(!creator_confirm_required)
						return complete("sabotage threshold reached")
					return TRUE
		if(CYBERPUNK_CONTRACT_BUILD)
			for(var/atom/target in view(1, user))
				if(!matches_target(target))
					continue
				add_history("[user.real_name || user.name] verified construction of [target]")
				if(!creator_confirm_required)
					return complete("construction target present")
				return TRUE
		if(CYBERPUNK_CONTRACT_ELIMINATION)
			for(var/mob/living/target in GLOB.player_list)
				if(target_text && !findtext(lowertext(target.real_name || target.name), lowertext(target_text)))
					continue
				if(target.stat == DEAD || target.health <= HEALTH_THRESHOLD_CRIT)
					add_history("[user.real_name || user.name] verified elimination of [target.real_name || target.name]")
					if(!creator_confirm_required)
						return complete("target incapacitated")
					return TRUE
	return FALSE

/datum/cyberpunk_contract/proc/to_ui_data(mob/living/user, include_history = FALSE)
	var/list/stats = contractor_character_key ? SSeconomy.get_cyberpunk_contract_stats(contractor_character_key) : null
	return list(
		"id" = id,
		"title" = title,
		"description" = description,
		"type" = contract_type,
		"target" = target_text,
		"status" = status,
		"creator" = creator_name,
		"contractor" = contractor_name,
		"assignedContractor" = assigned_contractor_name,
		"pool" = pool_contract,
		"corporation" = pool_corporation,
		"generated" = generated_pool_contract,
		"payment" = payment,
		"deposit" = deposit,
		"penalty" = penalty,
		"legal" = legal,
		"public" = public_contract,
		"taxPaid" = tax_paid,
		"creatorConfirmRequired" = creator_confirm_required,
		"requiredAmount" = required_amount,
		"deliveredAmount" = delivered_amount,
		"requiredPercent" = required_percent,
		"deadline" = due_time > world.time ? DisplayTimeText(due_time - world.time) : "expired",
		"canAccept" = can_accept(user),
		"canRefuse" = can_refuse(user),
		"canManage" = can_manage(user),
		"canAct" = can_act_as_contractor(user),
		"contractorStats" = stats,
		"history" = include_history ? history : null,
	)
//CYBERPUNK BUILD - rebuild and delete before release

#undef CYBERPUNK_CONTRACT_TAX_RATE
#undef CYBERPUNK_CONTRACT_ELIMINATION
#undef CYBERPUNK_CONTRACT_SABOTAGE
#undef CYBERPUNK_CONTRACT_MINING
#undef CYBERPUNK_CONTRACT_GUARD
#undef CYBERPUNK_CONTRACT_BUILD
#undef CYBERPUNK_CONTRACT_REPAIR
#undef CYBERPUNK_CONTRACT_DELIVERY
#undef CYBERPUNK_CONTRACT_CANCELLED
#undef CYBERPUNK_CONTRACT_FAILED
#undef CYBERPUNK_CONTRACT_COMPLETED
#undef CYBERPUNK_CONTRACT_ACCEPTED
#undef CYBERPUNK_CONTRACT_OFFERED
#undef CYBERPUNK_CONTRACT_CREATED

#define CYBERPUNK_BUSINESS_ACCESS_TERMINAL "terminal"
#define CYBERPUNK_BUSINESS_ACCESS_FINANCE "finance"
#define CYBERPUNK_BUSINESS_ACCESS_STOCK "stock"
#define CYBERPUNK_BUSINESS_ACCESS_STAFF "staff"
#define CYBERPUNK_BUSINESS_ACCESS_CONTRACTS "contracts"

#define CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST 10
#define CYBERPUNK_BUSINESS_TAX_RATE 0.05

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
			if(thing == active_terminal || ismob(thing))
				continue
			if(!(isitem(thing) || istype(thing, /obj/machinery) || istype(thing, /obj/structure)))
				continue
			var/list/entry = list(
				"type" = "[thing.type]",
				"name" = thing.name,
				"x" = area_turf.x - center.x,
				"y" = area_turf.y - center.y,
				"z" = area_turf.z - center.z,
				"dir" = thing.dir,
				"pixel_x" = thing.pixel_x,
				"pixel_y" = thing.pixel_y,
			)
			var/obj/item/clothing/clothing = thing
			if(istype(clothing) && islist(clothing.cyberpunk_custom_design_data))
				entry["clothing_design"] = clothing.cyberpunk_custom_design_data.Copy()
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
			var/atom/movable/restored_atom = new movable_path(target)
			restored_atom.name = entry["name"] || restored_atom.name
			restored_atom.dir = entry["dir"] || SOUTH
			restored_atom.pixel_x = entry["pixel_x"] || 0
			restored_atom.pixel_y = entry["pixel_y"] || 0
			var/obj/item/clothing/clothing = restored_atom
			if(istype(clothing) && islist(entry["clothing_design"]))
				clothing.cyberpunk_apply_design(entry["clothing_design"])
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

/proc/cyberpunk_grant_persistent_access(mob/living/user, datum/cyberpunk_crypto_key/access_key)
	if(!user || !access_key)
		return FALSE
	user.remember_cyberpunk_crypto_key(access_key)
	var/obj/item/card/id/card = user.get_cyberpunk_access_card()
	if(card)
		card.store_cyberpunk_crypto_key(access_key)
	return TRUE

/datum/controller/subsystem/economy/proc/get_cyberpunk_business(business_id)
	return cyberpunk_businesses["[business_id]"]

/datum/controller/subsystem/economy/proc/get_cyberpunk_apartment(apartment_id)
	return cyberpunk_apartments["[apartment_id]"]

/datum/controller/subsystem/economy/proc/get_cyberpunk_business_key(mob/living/person, datum/bank_account/account)
	return get_cyberpunk_contract_character_key(person, account)

/datum/controller/subsystem/economy/proc/get_cyberpunk_businesses_for_user(mob/living/user)
	var/list/businesses = list()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(business?.can_view(user))
			businesses += business
	return businesses

/datum/controller/subsystem/economy/proc/get_cyberpunk_apartments_for_user(mob/living/user)
	var/list/apartments = list()
	for(var/apartment_id in cyberpunk_apartments)
		var/datum/cyberpunk_apartment/apartment = cyberpunk_apartments[apartment_id]
		if(apartment?.can_view(user))
			apartments += apartment
	return apartments

/datum/controller/subsystem/economy/proc/find_cyberpunk_business_supplier(datum/cyberpunk_business/requester, item_label, amount, source_label)
	item_label = reject_bad_text(item_label, max_length = 48, ascii_only = FALSE)
	if(!requester || !item_label)
		return null
	amount = max(1, round(amount))
	var/source_key = lowertext("[source_label]")
	var/datum/cyberpunk_business/best_supplier
	var/best_price = INFINITY
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/supplier = cyberpunk_businesses[business_id]
		if(!supplier || supplier == requester || !supplier.warehouse_enabled)
			continue
		if(source_key && source_key != "external supplier" && source_key != "auto")
			if(source_key != lowertext("[supplier.id]") && source_key != lowertext(supplier.name))
				continue
		if(supplier.get_stock_amount(item_label) < amount)
			continue
		var/unit_price = supplier.get_stock_price(item_label)
		if(unit_price < best_price)
			best_price = unit_price
			best_supplier = supplier
	return best_supplier

/datum/controller/subsystem/economy/proc/create_cyberpunk_business(mob/living/owner, obj/machinery/computer/business_terminal/terminal, list/params)
	if(!owner || !terminal)
		return null
	if(!owner.has_neural_implant())
		return null
	var/area/business_area = get_area(terminal)
	if(!istype(business_area, /area/station/service/business))
		return null
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/existing_business = cyberpunk_businesses[business_id]
		if(existing_business?.get_business_area() == business_area)
			return null
	var/datum/bank_account/owner_account = owner.get_bank_account()
	var/name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE)
	if(!name)
		name = "[owner.real_name || owner.name]'s business"
	var/datum/bank_account/business_account = new /datum/bank_account("[name] account", null, 1, TRUE)
	var/datum/cyberpunk_business/business = new
	business.id = next_cyberpunk_business_id++
	business.name = name
	business.direction = reject_bad_text(params["direction"], max_length = 64, ascii_only = FALSE) || "general trade"
	business.legal = text2num(params["legal"]) ? TRUE : FALSE
	business.size_class = "17x17"
	business.owner_ckey = owner.ckey
	business.owner_name = owner.real_name || owner.name
	business.owner_character_key = get_cyberpunk_business_key(owner, owner_account)
	business.account_id = business_account.account_id
	business.terminal = terminal
	business.business_area_type = business_area.type
	business.hydrate_from_persistent(owner)
	business.add_history("created by [business.owner_name] at [business_area.name]")
	cyberpunk_businesses["[business.id]"] = business
	terminal.business_id = business.id
	business.apply_generated_access(owner)
	return business

/datum/controller/subsystem/economy/proc/create_cyberpunk_apartment(mob/living/owner, obj/machinery/computer/apartment_terminal/terminal, list/params)
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

/datum/controller/subsystem/economy/proc/create_cyberpunk_business_delivery(datum/cyberpunk_business/business, item_label, amount, source_label = "external supplier", destination_label = "business warehouse")
	if(!business)
		return null
	item_label = reject_bad_text(item_label, max_length = 48, ascii_only = FALSE)
	if(!item_label)
		return null
	amount = clamp(round(amount), 1, 1000)
	var/datum/cyberpunk_business/supplier = find_cyberpunk_business_supplier(business, item_label, amount, source_label)
	var/unit_cost = supplier ? supplier.get_stock_price(item_label) : CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST
	var/total_cost = max(0, round(unit_cost * amount))
	if(total_cost && !business.charge(total_cost, "Business delivery #[next_cyberpunk_business_delivery_id]: [amount]x [item_label]"))
		return null
	if(supplier)
		var/supplied = supplier.consume_stock(item_label, amount)
		if(supplied < amount)
			return null
		supplier.record_income(total_cost, "Business supply sale to [business.name]: [amount]x [item_label]")
	var/datum/cyberpunk_business_delivery/delivery = new
	delivery.id = next_cyberpunk_business_delivery_id++
	delivery.business_id = business.id
	delivery.source_business_id = supplier?.id || 0
	delivery.item_label = item_label
	delivery.amount = amount
	delivery.source_label = supplier ? supplier.name : (reject_bad_text(source_label, max_length = 48, ascii_only = FALSE) || "external supplier")
	delivery.destination_label = reject_bad_text(destination_label, max_length = 48, ascii_only = FALSE) || "business warehouse"
	delivery.cost = total_cost
	delivery.created_at = world.time
	delivery.arrival_time = world.time + 2 MINUTES
	cyberpunk_business_deliveries["[delivery.id]"] = delivery
	business.deliveries += delivery
	business.add_history("delivery #[delivery.id] requested: [amount]x [item_label] from [delivery.source_label]; cost [total_cost][MONEY_SYMBOL]")
	record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "market", max(1, round(amount / 2)), max(0, round(total_cost * 0.03)), "business delivery #[delivery.id]")
	if(cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_cargo_tracking"))
		record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", 1, 0, "cargo tracking: delivery #[delivery.id]")
	if(cyberpunk_corporation_has_edict(CYBERPUNK_CORP_STARLIGHT, "starlight_log_observation"))
		record_cyberpunk_corporate_activity(CYBERPUNK_CORP_STARLIGHT, "route", max(1, round(amount / 4)), 0, "log observation: delivery #[delivery.id]")
	addtimer(CALLBACK(delivery, TYPE_PROC_REF(/datum/cyberpunk_business_delivery, complete_delivery)), 2 MINUTES, TIMER_STOPPABLE)
	return delivery

/datum/cyberpunk_business
	var/id = 0
	var/name = "Business"
	var/direction = "general trade"
	var/legal = TRUE
	var/registered_to = "city"
	var/size_class = "small"
	var/owner_ckey
	var/owner_name
	var/owner_character_key
	var/account_id
	var/access_id
	var/obj/machinery/computer/business_terminal/terminal
	var/business_area_type
	var/list/employees = list()
	var/list/warehouse_stock = list()
	var/warehouse_enabled = FALSE
	var/warehouse_auto_restock = FALSE
	var/warehouse_surplus_percent = 0
	var/warehouse_markup_percent = 0
	var/warehouse_unload_zone = "unset"
	var/list/warehouse_buy_links = list()
	var/list/warehouse_sell_links = list()
	var/premises_valid = FALSE
	var/premises_validation = "not checked"
	var/warehouse_valid = FALSE
	var/warehouse_validation = "not checked"
	var/unload_zone_valid = FALSE
	var/tax_debt = 0
	var/tax_paid = 0
	var/list/datum/cyberpunk_business_delivery/deliveries = list()
	var/list/saved_snapshot = list()
	var/saved_at = 0
	var/loaded_this_round = FALSE
	var/list/history = list()

/datum/cyberpunk_business/proc/get_account()
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/datum/cyberpunk_business/proc/user_key(mob/living/user)
	return SSeconomy.get_cyberpunk_business_key(user, user?.get_bank_account())

/datum/cyberpunk_business/proc/add_history(message)
	LAZYADD(history, "[round_timestamp()] - [message]")

/datum/cyberpunk_business/proc/get_business_area()
	RETURN_TYPE(/area)
	var/area/current_area = terminal ? get_area(terminal) : null
	if(istype(current_area, /area/station/service/business))
		return current_area
	if(business_area_type)
		var/area/stored_area = GLOB.areas_by_type[business_area_type]
		if(stored_area)
			return stored_area
	return null

/datum/cyberpunk_business/proc/get_business_turfs()
	var/area/business_area = get_business_area()
	if(!business_area)
		return list()
	return cyberpunk_area_turfs(business_area)

/datum/cyberpunk_business/proc/persistent_record_id()
	return "[owner_character_key]:[business_area_type]"

/datum/cyberpunk_business/proc/get_access_id()
	if(!access_id)
		access_id = cyberpunk_persistent_access_id("business", owner_character_key, business_area_type)
	return access_id

/datum/cyberpunk_business/proc/get_access_key()
	if(!SSid_access)
		return null
	return SSid_access.register_cyberpunk_crypto_access_key(get_access_id(), "[name] business access", name)

/datum/cyberpunk_business/proc/apply_generated_access(mob/living/owner)
	var/datum/cyberpunk_crypto_key/access_key = get_access_key()
	if(!access_key)
		return FALSE
	terminal?.add_cyberpunk_crypto_key(access_key)
	cyberpunk_grant_persistent_access(owner, access_key)
	add_history("business cryptokey access refreshed")
	return TRUE

/datum/cyberpunk_business/proc/to_persistent_record()
	var/datum/bank_account/account = get_account()
	return list(
		"id" = persistent_record_id(),
		"name" = name,
		"owner_key" = owner_character_key,
		"area_type" = "[business_area_type]",
		"saved_at" = world.realtime,
		"snapshot" = saved_snapshot,
		"meta" = list(
			"direction" = direction,
			"legal" = legal,
			"registered_to" = registered_to,
			"account_balance" = account?.account_balance || 0,
			"tax_debt" = tax_debt,
			"tax_paid" = tax_paid,
			"access_id" = get_access_id(),
			"warehouse_stock" = warehouse_stock.Copy(),
			"warehouse_enabled" = warehouse_enabled,
			"warehouse_auto_restock" = warehouse_auto_restock,
			"warehouse_surplus_percent" = warehouse_surplus_percent,
			"warehouse_markup_percent" = warehouse_markup_percent,
			"warehouse_unload_zone" = warehouse_unload_zone,
			"employees" = employees.Copy(),
		),
	)

/datum/cyberpunk_business/proc/hydrate_from_persistent(mob/living/user)
	var/list/record = user?.cyberpunk_find_persistent_area_record(/datum/preference/cyberpunk_business_records, persistent_record_id())
	if(!islist(record))
		return FALSE
	var/list/meta = record["meta"]
	name = record["name"] || name
	if(islist(meta))
		direction = meta["direction"] || direction
		legal = !!meta["legal"]
		registered_to = meta["registered_to"] || registered_to
		access_id = meta["access_id"] || access_id
		tax_debt = max(0, round(meta["tax_debt"] || tax_debt))
		tax_paid = max(0, round(meta["tax_paid"] || tax_paid))
		var/list/persistent_stock = meta["warehouse_stock"]
		if(islist(persistent_stock))
			warehouse_stock = persistent_stock.Copy()
		warehouse_enabled = !!meta["warehouse_enabled"]
		warehouse_auto_restock = !!meta["warehouse_auto_restock"]
		warehouse_surplus_percent = clamp(round(meta["warehouse_surplus_percent"] || 0), 0, 100)
		warehouse_markup_percent = clamp(round(meta["warehouse_markup_percent"] || 0), -100, 500)
		warehouse_unload_zone = meta["warehouse_unload_zone"] || warehouse_unload_zone
		var/list/persistent_employees = meta["employees"]
		if(islist(persistent_employees))
			employees = persistent_employees.Copy()
		var/datum/bank_account/account = get_account()
		if(account && isnum(meta["account_balance"]))
			account.account_balance = max(0, round(meta["account_balance"]))
	if(islist(record["snapshot"]))
		saved_snapshot = record["snapshot"]
		saved_at = world.time
	add_history("persistent business record loaded")
	return TRUE

/datum/cyberpunk_business/proc/contains_atom(atom/checked)
	var/area/business_area = get_business_area()
	return !!(business_area && checked && get_area(checked) == business_area)

/datum/cyberpunk_business/proc/can_view(mob/living/user)
	var/key = user_key(user)
	return key == owner_character_key || !!employees[key]

/datum/cyberpunk_business/proc/is_owner(mob/living/user)
	return user_key(user) == owner_character_key

/datum/cyberpunk_business/proc/has_access(mob/living/user, access_key)
	if(is_owner(user))
		return TRUE
	var/key = user_key(user)
	var/list/employee = employees[key]
	if(!employee)
		return FALSE
	var/list/access = employee["access"]
	return !!(access && access[access_key])

/datum/cyberpunk_business/proc/can_save_load(mob/living/user)
	return is_owner(user) && user.has_neural_implant()

/datum/cyberpunk_business/proc/get_stock_key(item_label)
	var/needle = lowertext("[item_label]")
	for(var/stock_name in warehouse_stock)
		if(lowertext("[stock_name]") == needle)
			return stock_name
	return null

/datum/cyberpunk_business/proc/get_stock_amount(item_label)
	var/stock_key = get_stock_key(item_label)
	return stock_key ? (warehouse_stock[stock_key] || 0) : 0

/datum/cyberpunk_business/proc/add_stock(item_label, amount)
	item_label = reject_bad_text(item_label, max_length = 64, ascii_only = FALSE)
	if(!item_label)
		return 0
	amount = max(0, round(amount))
	if(!amount)
		return 0
	var/stock_key = get_stock_key(item_label) || item_label
	warehouse_stock[stock_key] = (warehouse_stock[stock_key] || 0) + amount
	return amount

/datum/cyberpunk_business/proc/consume_stock(item_label, amount)
	amount = max(0, round(amount))
	var/stock_key = get_stock_key(item_label)
	if(!stock_key || !amount)
		return 0
	var/taken = min(warehouse_stock[stock_key] || 0, amount)
	warehouse_stock[stock_key] -= taken
	if(warehouse_stock[stock_key] <= 0)
		warehouse_stock -= stock_key
	return taken

/datum/cyberpunk_business/proc/get_stock_price(item_label)
	var/base_price = CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST
	return max(1, round(base_price * (100 + warehouse_markup_percent) / 100))

/datum/cyberpunk_business/proc/charge(amount, reason, allow_debt = TRUE)
	amount = max(0, round(amount))
	if(!amount)
		return TRUE
	var/datum/bank_account/account = get_account()
	if(!account)
		return FALSE
	if(account.adjust_money(-amount, reason))
		return TRUE
	if(!allow_debt)
		return FALSE
	var/available = max(0, account.account_balance)
	if(available)
		account.adjust_money(-available, reason)
	var/debt = amount - available
	account.account_debt += debt
	account.add_log_to_history(-debt, "[reason]; debt")
	add_history("debt increased by [debt][MONEY_SYMBOL]: [reason]")
	log_econ("Business #[id] [name] debt increased by [debt][MONEY_NAME]: [reason]")
	return TRUE

/datum/cyberpunk_business/proc/record_income(amount, reason, taxable = TRUE)
	amount = max(0, round(amount))
	var/datum/bank_account/account = get_account()
	if(!account || !amount)
		return FALSE
	account.adjust_money(amount, reason)
	if(legal && taxable)
		var/tax = round(amount * CYBERPUNK_BUSINESS_TAX_RATE)
		if(tax > 0)
			tax_debt += tax
			add_history("tax debt increased by [tax][MONEY_SYMBOL]: [reason]")
	log_econ("Business #[id] [legal ? "legal" : "off-ledger"] income [amount][MONEY_NAME]: [reason]; tax debt [tax_debt][MONEY_NAME].")
	return TRUE

/datum/cyberpunk_business/proc/pay_taxes(mob/living/user, amount = 0)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = round(amount || tax_debt)
	amount = clamp(amount, 0, tax_debt)
	if(amount <= 0)
		return FALSE
	var/datum/bank_account/account = get_account()
	if(!account || !account.adjust_money(-amount, "Business tax payment: [name]"))
		return FALSE
	SSeconomy.get_dep_account(ACCOUNT_CIV)?.adjust_money(amount, "Business tax: [name]")
	tax_debt -= amount
	tax_paid += amount
	add_history("[user.real_name || user.name] paid [amount][MONEY_SYMBOL] tax")
	log_econ("Business #[id] [name] paid [amount][MONEY_NAME] tax.")
	return TRUE

/datum/cyberpunk_business/proc/validate_premises(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL) || !terminal)
		return FALSE
	var/area/business_area = get_business_area()
	if(!istype(business_area, /area/station/service/business))
		premises_valid = FALSE
		premises_validation = "failed: terminal is outside a business area"
	else
		var/turf_count = length(get_business_turfs())
		premises_valid = turf_count <= 17 * 17
		premises_validation = premises_valid ? "ok: [business_area.name], [turf_count]/289 tiles" : "failed: [business_area.name] is larger than 17x17 ([turf_count]/289 tiles)"
	add_history("[user.real_name || user.name] validated premises: [premises_validation]")
	return premises_valid

/datum/cyberpunk_business/proc/validate_unload_zone()
	if(!terminal)
		return FALSE
	var/turf/center = get_turf(terminal)
	if(!center)
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	for(var/dx in -1 to 1)
		for(var/dy in -1 to 1)
			var/turf/check = locate(center.x + dx, center.y + dy, center.z)
			if(!check || get_area(check) != business_area || isclosedturf(check) || isspaceturf(check))
				return FALSE
	return TRUE

/datum/cyberpunk_business/proc/validate_warehouse(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	if(!warehouse_enabled)
		warehouse_valid = FALSE
		unload_zone_valid = FALSE
		warehouse_validation = "failed: warehouse disabled"
		add_history("[user.real_name || user.name] validated warehouse: [warehouse_validation]")
		return FALSE
	var/area/business_area = get_business_area()
	unload_zone_valid = validate_unload_zone()
	warehouse_valid = premises_valid && !!business_area && unload_zone_valid
	if(warehouse_valid)
		warehouse_validation = "ok: [business_area.name] and terminal-centered 3x3 unload area"
	else if(!premises_valid || !business_area)
		warehouse_validation = "failed: business area is not valid"
	else
		warehouse_validation = "failed: terminal-centered 3x3 unload area is blocked or outside business area"
	add_history("[user.real_name || user.name] validated warehouse: [warehouse_validation]")
	return warehouse_valid

/datum/cyberpunk_business/proc/set_settings(mob/living/user, list/params)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_TERMINAL))
		return FALSE
	name = reject_bad_text(params["name"], max_length = 48, ascii_only = FALSE) || name
	direction = reject_bad_text(params["direction"], max_length = 64, ascii_only = FALSE) || direction
	if(is_owner(user))
		legal = text2num(params["legal"]) ? TRUE : FALSE
	registered_to = reject_bad_text(params["registered_to"], max_length = 48, ascii_only = FALSE) || registered_to
	add_history("[user.real_name || user.name] updated business settings")
	return TRUE

/datum/cyberpunk_business/proc/set_warehouse(mob/living/user, list/params)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK))
		return FALSE
	warehouse_enabled = text2num(params["enabled"]) ? TRUE : FALSE
	warehouse_auto_restock = text2num(params["auto_restock"]) ? TRUE : FALSE
	warehouse_surplus_percent = clamp(round(text2num(params["surplus_percent"]) || 0), 0, 100)
	warehouse_markup_percent = clamp(round(text2num(params["markup_percent"]) || 0), -100, 500)
	warehouse_unload_zone = reject_bad_text(params["unload_zone"], max_length = 64, ascii_only = FALSE) || warehouse_unload_zone
	add_history("[user.real_name || user.name] updated warehouse settings")
	return TRUE

/datum/cyberpunk_business/proc/add_employee(mob/living/user, employee_name, wage = 0)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_name = reject_bad_text(employee_name, max_length = 64, ascii_only = FALSE)
	var/key = ckey(employee_name)
	if(!key || key == owner_character_key)
		return FALSE
	employees[key] = list(
		"name" = employee_name,
		"wage" = max(0, round(wage)),
		"access" = list(
			CYBERPUNK_BUSINESS_ACCESS_TERMINAL = TRUE,
			CYBERPUNK_BUSINESS_ACCESS_FINANCE = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STOCK = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_STAFF = FALSE,
			CYBERPUNK_BUSINESS_ACCESS_CONTRACTS = legal,
		),
	)
	add_history("[user.real_name || user.name] hired [employee_name]")
	return TRUE

/datum/cyberpunk_business/proc/remove_employee(mob/living/user, employee_key)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	if(!employees[employee_key])
		return FALSE
	var/list/employee = employees[employee_key]
	add_history("[user.real_name || user.name] removed [employee["name"]]")
	employees -= employee_key
	return TRUE

/datum/cyberpunk_business/proc/set_employee_wage(mob/living/user, employee_key, wage)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	var/list/employee = employees[employee_key]
	if(!employee)
		return FALSE
	employee["wage"] = max(0, round(wage))
	add_history("[user.real_name || user.name] set [employee["name"]]'s wage to [employee["wage"]][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/toggle_employee_access(mob/living/user, employee_key, access_key)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF))
		return FALSE
	employee_key = ckey(employee_key)
	var/list/employee = employees[employee_key]
	if(!employee)
		return FALSE
	if(!(access_key in list(CYBERPUNK_BUSINESS_ACCESS_TERMINAL, CYBERPUNK_BUSINESS_ACCESS_FINANCE, CYBERPUNK_BUSINESS_ACCESS_STOCK, CYBERPUNK_BUSINESS_ACCESS_STAFF, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS)))
		return FALSE
	if(access_key == CYBERPUNK_BUSINESS_ACCESS_CONTRACTS && !legal)
		return FALSE
	var/list/access = employee["access"]
	access[access_key] = !access[access_key]
	add_history("[user.real_name || user.name] toggled [access_key] for [employee["name"]]")
	return TRUE

/datum/cyberpunk_business/proc/deposit(mob/living/user, amount)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = max(0, round(amount))
	var/datum/bank_account/user_account = user.get_bank_account()
	var/datum/bank_account/business_account = get_account()
	if(!user_account || !business_account || amount <= 0)
		return FALSE
	if(!business_account.transfer_money(user_account, amount, "Business deposit: [name]"))
		return FALSE
	add_history("[user.real_name || user.name] deposited [amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/withdraw(mob/living/user, amount)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE))
		return FALSE
	amount = max(0, round(amount))
	var/datum/bank_account/user_account = user.get_bank_account()
	var/datum/bank_account/business_account = get_account()
	if(!user_account || !business_account || amount <= 0)
		return FALSE
	if(!user_account.transfer_money(business_account, amount, "Business withdrawal: [name]"))
		return FALSE
	add_history("[user.real_name || user.name] withdrew [amount][MONEY_SYMBOL]")
	return TRUE

/datum/cyberpunk_business/proc/save_business(mob/living/user)
	if(!can_save_load(user) || !terminal)
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	saved_snapshot = cyberpunk_persistent_area_capture(business_area, terminal)
	saved_at = world.time
	user.cyberpunk_store_persistent_area_record(/datum/preference/cyberpunk_business_records, to_persistent_record())
	add_history("[user.real_name || user.name] saved [length(saved_snapshot["movables"])] object(s) and [length(saved_snapshot["turfs"])] turf(s)")
	return TRUE

/datum/cyberpunk_business/proc/load_business(mob/living/user)
	if(!can_save_load(user) || !terminal || loaded_this_round || !length(saved_snapshot))
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	var/restored = cyberpunk_persistent_area_restore(business_area, terminal, saved_snapshot)
	loaded_this_round = TRUE
	apply_generated_access(user)
	add_history("[user.real_name || user.name] loaded [restored] object(s); area overwritten")
	return TRUE

/datum/cyberpunk_business/proc/request_delivery(mob/living/user, item_label, amount, source_label)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !warehouse_enabled || !warehouse_valid)
		return FALSE
	return !!SSeconomy.create_cyberpunk_business_delivery(src, item_label, amount, source_label)

/datum/cyberpunk_business/proc/link_nearby_vendors(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal)
		return FALSE
	var/linked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/vending/vendor in business_turf.contents)
			vendor.cyberpunk_business_id = id
			vendor.cyberpunk_business_auto_restock = warehouse_auto_restock
			vendor.cyberpunk_business_markup_percent = warehouse_markup_percent
			linked++
	if(linked)
		add_history("[user.real_name || user.name] linked [linked] vendor(s) inside business area")
	return linked > 0

/datum/cyberpunk_business/proc/restock_linked_vendors(mob/living/user)
	if(!has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK) || !terminal || !warehouse_enabled || !warehouse_valid)
		return FALSE
	var/restocked = 0
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/obj/machinery/vending/vendor in business_turf.contents)
			if(vendor.cyberpunk_business_id != id)
				continue
			restocked += vendor.cyberpunk_business_restock_from_warehouse()
	if(restocked)
		add_history("[user.real_name || user.name] restocked linked vendors with [restocked] item(s)")
	return restocked > 0

/datum/cyberpunk_business/proc/to_ui_data(mob/living/user, include_history = FALSE)
	var/datum/bank_account/account = get_account()
	var/list/employee_records = list()
	for(var/employee_key in employees)
		var/list/employee = employees[employee_key]
		var/list/access = employee["access"]
		employee_records += list(list(
			"key" = employee_key,
			"name" = employee["name"],
			"wage" = employee["wage"],
			"access" = access,
		))
	var/list/stock_records = list()
	for(var/stock_name in warehouse_stock)
		stock_records += list(list("name" = stock_name, "amount" = warehouse_stock[stock_name]))
	var/list/delivery_records = list()
	for(var/datum/cyberpunk_business_delivery/delivery as anything in deliveries)
		delivery_records += list(delivery.to_ui_data())
	return list(
		"id" = id,
		"name" = name,
		"direction" = direction,
		"legal" = legal,
		"registeredTo" = registered_to,
		"sizeClass" = size_class,
		"owner" = owner_name,
		"accountId" = account_id,
		"balance" = account?.account_balance || 0,
		"businessArea" = get_business_area()?.name || "none",
		"warehouse" = list(
			"enabled" = warehouse_enabled,
			"autoRestock" = warehouse_auto_restock,
			"surplusPercent" = warehouse_surplus_percent,
			"markupPercent" = warehouse_markup_percent,
			"unloadZone" = warehouse_unload_zone,
			"valid" = warehouse_valid,
			"unloadValid" = unload_zone_valid,
			"validation" = warehouse_validation,
		),
		"premises" = list(
			"valid" = premises_valid,
			"validation" = premises_validation,
		),
		"debt" = account?.account_debt || 0,
		"taxDebt" = tax_debt,
		"taxPaid" = tax_paid,
		"taxRate" = round(CYBERPUNK_BUSINESS_TAX_RATE * 100),
		"employees" = employee_records,
		"stock" = stock_records,
		"deliveries" = delivery_records,
		"savedObjects" = islist(saved_snapshot) && islist(saved_snapshot["movables"]) ? length(saved_snapshot["movables"]) : 0,
		"savedAt" = saved_at ? DisplayTimeText(world.time - saved_at) : null,
		"loadedThisRound" = loaded_this_round,
		"canSaveLoad" = can_save_load(user),
		"canFinance" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE),
		"canStock" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK),
		"canStaff" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF),
		"canContracts" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS) && legal,
		"history" = include_history ? history : null,
	)

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
	return SSeconomy.get_cyberpunk_business_key(user, user?.get_bank_account())

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

/datum/cyberpunk_business_delivery
	var/id = 0
	var/business_id = 0
	var/item_label = "goods"
	var/amount = 1
	var/source_label = "external supplier"
	var/source_business_id = 0
	var/destination_label = "business warehouse"
	var/cost = 0
	var/status = "enroute"
	var/created_at = 0
	var/arrival_time = 0

/datum/cyberpunk_business_delivery/proc/complete_delivery()
	if(status != "enroute")
		return FALSE
	var/datum/cyberpunk_business/business = SSeconomy.get_cyberpunk_business(business_id)
	if(!business)
		return FALSE
	status = "completed"
	business.add_stock(item_label, amount)
	business.add_history("delivery #[id] arrived: [amount]x [item_label]; cost [cost][MONEY_SYMBOL]")
	if(business.terminal)
		business.terminal.say("Delivery #[id] arrived: [amount]x [item_label].")
	return TRUE

/datum/cyberpunk_business_delivery/proc/to_ui_data()
	return list(
		"id" = id,
		"item" = item_label,
		"amount" = amount,
		"source" = source_label,
		"destination" = destination_label,
		"cost" = cost,
		"status" = status,
		"eta" = status == "enroute" && arrival_time > world.time ? DisplayTimeText(arrival_time - world.time) : "arrived",
	)
//CYBERPUNK BUILD - rebuild and delete before release

#undef CYBERPUNK_BUSINESS_TAX_RATE
#undef CYBERPUNK_BUSINESS_EXTERNAL_UNIT_COST
#undef CYBERPUNK_BUSINESS_ACCESS_CONTRACTS
#undef CYBERPUNK_BUSINESS_ACCESS_STAFF
#undef CYBERPUNK_BUSINESS_ACCESS_STOCK
#undef CYBERPUNK_BUSINESS_ACCESS_FINANCE
#undef CYBERPUNK_BUSINESS_ACCESS_TERMINAL
#undef DUMPTIME
#undef NO_MY_MONEY
