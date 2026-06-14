// CP13 energy economy bridge. This stores imported/generated corporate energy
// separately from TG powernets so collectors can sell power across the city.

/datum/cyberpunk_corporation
	var/cyberpunk_energy_reserve = 0
	var/cyberpunk_energy_reserve_limit = 250 MEGA JOULES
	var/cyberpunk_energy_price_per_kj = 1

/datum/cyberpunk_corporation/proc/add_cyberpunk_energy(amount, source = "energy input")
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	var/old_reserve = cyberpunk_energy_reserve
	cyberpunk_energy_reserve = clamp(cyberpunk_energy_reserve + amount, 0, cyberpunk_energy_reserve_limit)
	var/added = cyberpunk_energy_reserve - old_reserve
	if(added)
		add_history("[source]: +[round(added / (1 KILO JOULES))] kJ energy reserve")
	return added

/datum/cyberpunk_corporation/proc/use_cyberpunk_energy(amount, source = "energy output")
	amount = max(0, round(amount))
	if(!amount)
		return 0
	var/used = min(cyberpunk_energy_reserve, amount)
	cyberpunk_energy_reserve -= used
	if(used)
		add_history("[source]: -[round(used / (1 KILO JOULES))] kJ energy reserve")
	return used

/datum/cyberpunk_corporation/proc/get_cyberpunk_energy_price(amount)
	amount = max(0, round(amount))
	if(!amount)
		return 0
	return max(1, round((amount / (1 KILO JOULES)) * cyberpunk_energy_price_per_kj))

/datum/cyberpunk_corporation/proc/charge_cyberpunk_energy_customer(account_id, amount, source = "energy sale")
	var/datum/bank_account/customer = SSeconomy.bank_accounts_by_id["[account_id]"]
	var/cost = get_cyberpunk_energy_price(amount)
	if(!cost)
		return TRUE
	if(!customer || !customer.adjust_money(-cost, "[name] [source]"))
		return FALSE
	add_funds(cost, source)
	return TRUE
