//CYBERPUNK CORPORATIONS - corporate bank account.
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
