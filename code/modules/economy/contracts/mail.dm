//CYBERPUNK BUILD - rebuild and delete before release

/datum/cyberpunk_contract_mail
	var/id = 0
	var/sender_name = "unknown"
	var/recipient_name = "unknown"
	var/recipient_key
	var/obj/item/item
	var/contract_id = 0
	var/source_terminal = "unknown terminal"
	var/sent_at = 0


/datum/cyberpunk_contract_mail/proc/to_label()
	return "#[id] [item?.name || "missing item"] from [sender_name]"


/datum/cyberpunk_contract_mail/proc/can_receive(mob/living/user)
	if(!user || !item)
		return FALSE
	var/user_key = ckey(user.real_name || user.name)
	return user_key == recipient_key


/datum/controller/subsystem/economy/proc/create_cyberpunk_contract_mail(mob/living/sender, obj/machinery/vending/terminal, obj/item/item, recipient_name, contract_id = 0, already_stored = FALSE)
	if(!sender || !terminal || !item)
		return null
	recipient_name = reject_bad_text(recipient_name, max_length = 64, ascii_only = FALSE)
	if(!recipient_name)
		return null
	if(!already_stored && !sender.transferItemToLoc(item, terminal))
		return null
	var/datum/cyberpunk_contract_mail/mail = new
	mail.id = next_cyberpunk_contract_mail_id++
	mail.sender_name = sender.real_name || sender.name
	mail.recipient_name = recipient_name
	mail.recipient_key = ckey(recipient_name)
	mail.item = item
	mail.contract_id = contract_id
	mail.source_terminal = terminal.get_cyberpunk_contract_terminal_label()
	mail.sent_at = world.time
	cyberpunk_contract_mail["[mail.id]"] = mail
	if(contract_id)
		var/datum/cyberpunk_contract/contract = get_cyberpunk_contract(contract_id)
		contract?.add_history("[item.name] routed to [recipient_name] through [mail.source_terminal]")
	return mail


/datum/controller/subsystem/economy/proc/get_cyberpunk_contract_mail_for(mob/living/user)
	var/list/available = list()
	for(var/mail_id in cyberpunk_contract_mail)
		var/datum/cyberpunk_contract_mail/mail = cyberpunk_contract_mail[mail_id]
		if(mail?.can_receive(user))
			available += mail
	return available


/datum/controller/subsystem/economy/proc/claim_cyberpunk_contract_mail(mob/living/user, datum/cyberpunk_contract_mail/mail)
	if(!mail?.can_receive(user))
		return FALSE
	if(!user.put_in_hands(mail.item))
		mail.item.forceMove(get_turf(user))
	to_chat(user, span_notice("You claim [mail.item] from contract mail #[mail.id]."))
	if(mail.contract_id)
		var/datum/cyberpunk_contract/contract = get_cyberpunk_contract(mail.contract_id)
		contract?.add_history("[user.real_name || user.name] claimed [mail.item.name] from terminal mail")
	cyberpunk_contract_mail -= "[mail.id]"
	qdel(mail)
	return TRUE
