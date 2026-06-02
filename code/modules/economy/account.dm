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
	var/static/list/corporations = list(
		"Benn",
		"Ryaznov",
		"Starlight",
		"Nanotrasen",
	)
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
/datum/controller/subsystem/economy/proc/get_cyberpunk_business(business_id)
	return cyberpunk_businesses["[business_id]"]

/datum/controller/subsystem/economy/proc/get_cyberpunk_business_key(mob/living/person, datum/bank_account/account)
	return get_cyberpunk_contract_character_key(person, account)

/datum/controller/subsystem/economy/proc/get_cyberpunk_businesses_for_user(mob/living/user)
	var/list/businesses = list()
	for(var/business_id in cyberpunk_businesses)
		var/datum/cyberpunk_business/business = cyberpunk_businesses[business_id]
		if(business?.can_view(user))
			businesses += business
	return businesses

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
	business.size_class = istype(business_area, /area/station/service/business/medium) ? "medium" : "small"
	business.owner_ckey = owner.ckey
	business.owner_name = owner.real_name || owner.name
	business.owner_character_key = get_cyberpunk_business_key(owner, owner_account)
	business.account_id = business_account.account_id
	business.terminal = terminal
	business.business_area_type = business_area.type
	business.add_history("created by [business.owner_name] at [business_area.name]")
	cyberpunk_businesses["[business.id]"] = business
	terminal.business_id = business.id
	return business

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
	var/list/turfs = list()
	for(var/list/zlevel_turfs as anything in business_area.get_zlevel_turf_lists())
		turfs += zlevel_turfs
	return turfs

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
	else if(size_class == "medium" && !istype(business_area, /area/station/service/business/medium))
		premises_valid = FALSE
		premises_validation = "failed: medium business is not inside a medium business area"
	else if(size_class == "small" && !istype(business_area, /area/station/service/business/small))
		premises_valid = FALSE
		premises_validation = "failed: small business is not inside a small business area"
	else
		premises_valid = TRUE
		premises_validation = "ok: [business_area.name]"
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
	saved_snapshot = list()
	var/turf/center = get_turf(terminal)
	if(!center)
		return FALSE
	for(var/turf/business_turf as anything in get_business_turfs())
		for(var/atom/movable/thing as anything in business_turf.contents)
			if(thing == terminal || ismob(thing))
				continue
			if(!(isitem(thing) || istype(thing, /obj/machinery) || istype(thing, /obj/structure)))
				continue
			var/turf/thing_turf = get_turf(thing)
			if(!thing_turf)
				continue
			saved_snapshot += list(list(
				"type" = thing.type,
				"name" = thing.name,
				"x" = thing_turf.x - center.x,
				"y" = thing_turf.y - center.y,
				"dir" = thing.dir,
			))
	saved_at = world.time
	add_history("[user.real_name || user.name] saved [length(saved_snapshot)] object(s)")
	return TRUE

/datum/cyberpunk_business/proc/load_business(mob/living/user)
	if(!can_save_load(user) || !terminal || loaded_this_round || !length(saved_snapshot))
		return FALSE
	var/turf/center = get_turf(terminal)
	if(!center)
		return FALSE
	var/area/business_area = get_business_area()
	if(!business_area)
		return FALSE
	var/restored = 0
	for(var/list/entry as anything in saved_snapshot)
		var/path = entry["type"]
		if(!ispath(path))
			continue
		var/turf/target = locate(clamp(center.x + (entry["x"] || 0), 1, world.maxx), clamp(center.y + (entry["y"] || 0), 1, world.maxy), center.z)
		if(!target || get_area(target) != business_area)
			continue
		var/atom/movable/restored_atom = new path(target)
		restored_atom.dir = entry["dir"] || SOUTH
		restored++
	loaded_this_round = TRUE
	add_history("[user.real_name || user.name] loaded [restored] object(s)")
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
		"savedObjects" = length(saved_snapshot),
		"savedAt" = saved_at ? DisplayTimeText(world.time - saved_at) : null,
		"loadedThisRound" = loaded_this_round,
		"canSaveLoad" = can_save_load(user),
		"canFinance" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_FINANCE),
		"canStock" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STOCK),
		"canStaff" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_STAFF),
		"canContracts" = has_access(user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS) && legal,
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
