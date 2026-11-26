///all the employers that are syndicate
#define FLAVOR_FACTION_SYNDICATE "syndicate"
///all the employers that are Nanotrasen
#define FLAVOR_FACTION_NANOTRASEN "nanotrasen"

/datum/antagonist/traitor
	name = "\proper Предатель"
	roundend_category = "Предатели"
	antagpanel_category = "Traitor"
	pref_flag = ROLE_TRAITOR
	antag_moodlet = /datum/mood_event/focused
	antag_hud_name = "traitor"
	hijack_speed = 0.5 //10 seconds per hijack stage by default
	ui_name = "AntagInfoTraitor"
	suicide_cry = "ЗА СИНДИКАТ!!"
	preview_outfit = /datum/outfit/traitor
	can_assign_self_objectives = TRUE
	default_custom_objective = "Perform an overcomplicated heist on valuable Nanotrasen assets."
	hardcore_random_bonus = TRUE
	stinger_sound = 'sound/music/antag/traitor/tatoralert.ogg'

	///The flag of uplink that this traitor is supposed to have.
	var/uplink_flag_given = UPLINK_TRAITORS

	var/give_objectives = TRUE
	var/should_give_codewords = TRUE
	///give this traitor an uplink?
	var/give_uplink = TRUE
	///if TRUE, this traitor will always get hijacking as their final objective
	var/is_hijacker = FALSE

	///the name of the antag flavor this traitor has, set in Traitor's setup if not preset.
	var/employer

	///assoc list of strings set up after employer is given
	var/list/traitor_flavor

	///reference to the uplink this traitor was given, if they were.
	var/datum/weakref/uplink_ref

	/// The uplink handler that this traitor belongs to.
	var/datum/uplink_handler/uplink_handler

	var/uplink_sales_min = 4
	var/uplink_sales_max = 6

	///the final objective the traitor has to accomplish, be it escaping, hijacking, or just martyrdom.
	var/datum/objective/ending_objective

/datum/antagonist/traitor/New(give_objectives = TRUE)
	. = ..()
	src.give_objectives = give_objectives

/datum/antagonist/traitor/on_gain()
	if(give_uplink)
		owner.give_uplink(silent = TRUE, antag_datum = src)

	var/datum/component/uplink/uplink = owner.find_syndicate_uplink()
	uplink_ref = WEAKREF(uplink)
	if(uplink)
		if(uplink_handler)
			uplink.uplink_handler = uplink_handler
		else
			uplink_handler = uplink.uplink_handler
		uplink_handler.uplink_flag = uplink_flag_given
		uplink_handler.primary_objectives = objectives
		uplink_handler.has_progression = TRUE
		SStraitor.register_uplink_handler(uplink_handler)

		uplink_handler.can_replace_objectives = CALLBACK(src, PROC_REF(can_change_objectives))
		uplink_handler.replace_objectives = CALLBACK(src, PROC_REF(submit_player_objective))

		if(uplink_handler.progression_points < SStraitor.current_global_progression)
			uplink_handler.progression_points = SStraitor.current_global_progression * SStraitor.newjoin_progression_coeff

		var/list/uplink_items = list()
		for(var/datum/uplink_item/item as anything in SStraitor.uplink_items)
			if(item.item && !item.cant_discount && (item.purchasable_from & uplink_handler.uplink_flag) && item.cost >= TRAITOR_DISCOUNT_MIN_PRICE)
				if(!length(item.restricted_roles) && !length(item.restricted_species))
					uplink_items += item
					continue
				if((uplink_handler.assigned_role in item.restricted_roles) || (uplink_handler.assigned_species in item.restricted_species))
					uplink_items += item
					continue
		uplink_handler.extra_purchasable += create_uplink_sales(rand(uplink_sales_min, uplink_sales_max), /datum/uplink_category/discounts, -1, uplink_items)

	if(give_objectives)
		forge_traitor_objectives()
		forge_ending_objective()

	pick_employer()

	return ..()

/datum/antagonist/traitor/on_removal()
	if(!isnull(uplink_handler))
		uplink_handler.can_replace_objectives = null
		uplink_handler.replace_objectives = null
	owner.take_uplink()
	return ..()

/// Returns true if we're allowed to assign ourselves a new objective
/datum/antagonist/traitor/proc/can_change_objectives()
	return can_assign_self_objectives

/datum/antagonist/traitor/proc/pick_employer()
	if(!employer)
		var/faction = prob(75) ? FLAVOR_FACTION_SYNDICATE : FLAVOR_FACTION_NANOTRASEN
		var/list/possible_employers = list()

		possible_employers.Add(GLOB.syndicate_employers, GLOB.nanotrasen_employers)

		if(istype(ending_objective, /datum/objective/hijack))
			possible_employers -= GLOB.normal_employers
		else //escape or martyrdom
			possible_employers -= GLOB.hijack_employers

		switch(faction)
			if(FLAVOR_FACTION_SYNDICATE)
				possible_employers -= GLOB.nanotrasen_employers
			if(FLAVOR_FACTION_NANOTRASEN)
				possible_employers -= GLOB.syndicate_employers
		employer = pick(possible_employers)
	traitor_flavor = strings(TRAITOR_FLAVOR_FILE, employer)

/// Generates a complete set of traitor objectives up to the traitor objective limit, including non-generic objectives such as martyr and hijack.
/datum/antagonist/traitor/proc/forge_traitor_objectives()
	var/objective_count = 0

	if((GLOB.joined_player_list.len >= HIJACK_MIN_PLAYERS) && prob(HIJACK_PROB))
		is_hijacker = TRUE
		objective_count++

	var/objective_limit = CONFIG_GET(number/traitor_objectives_amount)
	var/datum/objective/job_objective = forge_job_objective()
	// for(in...to) loops iterate inclusively, so to reach objective_limit we need to loop to objective_limit - 1
	// This does not give them 1 fewer objectives than intended.
	for(var/i in objective_count to objective_limit - 1)
		var/generated = forge_single_generic_objective(job_objective)
		if(generated == job_objective)
			job_objective = null
		objectives += generated
	list_clear_nulls(objectives) // BANDASTATION EDIT: Safety for uplink and TP

/**
 * ## forge_ending_objective
 *
 * Forges the endgame objective and adds it to this datum's objective list.
 */
/datum/antagonist/traitor/proc/forge_ending_objective()
	if(is_hijacker)
		ending_objective = new /datum/objective/hijack
		ending_objective.owner = owner
		return

	var/martyr_compatibility = TRUE

	for(var/datum/objective/traitor_objective in objectives)
		if(!traitor_objective.martyr_compatible)
			martyr_compatibility = FALSE
			break

	if(martyr_compatibility && prob(MARTYR_PROB))
		ending_objective = new /datum/objective/martyr
		ending_objective.owner = owner
		objectives += ending_objective
		return

	ending_objective = new /datum/objective/escape
	ending_objective.owner = owner
	objectives += ending_objective

/datum/antagonist/traitor/proc/forge_single_generic_objective(job_objective)
	if(prob(JOB_PROB) && job_objective)
		return job_objective

	if(prob(KILL_PROB))
		var/list/active_ais = active_ais(skip_syndicate = TRUE)
		if(active_ais.len && GLOB.joined_player_list.len && prob(DESTROY_AI_PROB(GLOB.joined_player_list.len))) // BANDASTATION EDIT: div by zero check
			var/datum/objective/destroy/destroy_objective = new()
			destroy_objective.owner = owner
			destroy_objective.find_target()
			return destroy_objective

		if(prob(MAROON_PROB))
			var/datum/objective/maroon/maroon_objective = new()
			maroon_objective.owner = owner
			maroon_objective.find_target()
			return maroon_objective

		var/datum/objective/assassinate/kill_objective = new()
		kill_objective.owner = owner
		kill_objective.find_target()
		return kill_objective

	var/datum/objective/steal/steal_objective = new()
	steal_objective.owner = owner
	steal_objective.find_target()
	return steal_objective

/datum/antagonist/traitor/proc/forge_job_objective()
	var/datum/objective/job_objective = owner.assigned_role.generate_traitor_objective() // can return null
	job_objective?.owner = owner
	return job_objective

/datum/antagonist/traitor/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/datum_owner = mob_override || owner.current

	handle_clown_mutation(datum_owner, mob_override ? null : "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	if(should_give_codewords)
		datum_owner.AddComponent(/datum/component/codeword_hearing, SStraitor.syndicate_code_phrase_regex, "blue", src)
		datum_owner.AddComponent(/datum/component/codeword_hearing, SStraitor.syndicate_code_response_regex, "red", src)

/datum/antagonist/traitor/remove_innate_effects(mob/living/mob_override)
	var/mob/living/datum_owner = mob_override || owner.current
	handle_clown_mutation(datum_owner, removing = FALSE)

	for(var/datum/component/codeword_hearing/component as anything in datum_owner.GetComponents(/datum/component/codeword_hearing))
		component.delete_if_from_source(src)

/datum/antagonist/traitor/submit_player_objective(retain_existing, retain_escape, force)
	. = ..()
	if (!.)
		return
	owner.current.playsound_local(get_turf(owner.current), 'sound/music/antag/traitor/final_objective.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)

/datum/antagonist/traitor/ui_static_data(mob/user)
	var/datum/component/uplink/uplink = uplink_ref?.resolve()
	var/list/data = list()
	data["has_codewords"] = should_give_codewords
	if(should_give_codewords)
		data["phrases"] = jointext(SStraitor.syndicate_code_phrase, ", ")
		data["responses"] = jointext(SStraitor.syndicate_code_response, ", ")
	data["theme"] = traitor_flavor["ui_theme"]
	data["code"] = uplink?.unlock_code
	data["failsafe_code"] = uplink?.failsafe_code
	data["intro"] = traitor_flavor["introduction"]
	data["allies"] = traitor_flavor["allies"]
	data["goal"] = traitor_flavor["goal"]
	data["has_uplink"] = uplink ? TRUE : FALSE
	data["given_uplink"] = give_uplink
	if(uplink)
		data["uplink_intro"] = traitor_flavor["uplink"]
		data["uplink_unlock_info"] = uplink.unlock_text
	data["objectives"] = get_objectives()
	return data

/datum/antagonist/traitor/roundend_report()
	var/list/result = list()

	var/traitor_won = TRUE

	result += printplayer(owner)

	var/used_telecrystals = 0
	var/uplink_owned = FALSE
	var/purchases = ""

	LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
	// Uplinks add an entry to uplink_purchase_logs_by_key on init.
	var/datum/uplink_purchase_log/purchase_log = GLOB.uplink_purchase_logs_by_key[owner.key]
	if(purchase_log)
		used_telecrystals = purchase_log.total_spent
		uplink_owned = TRUE
		purchases += purchase_log.generate_render(FALSE)

	var/objectives_text = ""
	if(objectives.len) //If the traitor had no objectives, don't need to process this.
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(!objective.check_completion())
				traitor_won = FALSE
			objectives_text += "<br><B>Задача #[count]</B>: [objective.explanation_text] [objective.get_roundend_success_suffix()]"
			count++

	result += "<br>[owner.name] <B>[traitor_flavor["roundend_report"]]</B>"

	if(uplink_owned)
		var/uplink_text = "(использовал [used_telecrystals] ТК) [purchases]"
		if((used_telecrystals == 0) && traitor_won)
			var/static/icon/badass = icon('icons/ui/antags/badass.dmi', "badass")
			uplink_text += "<BIG>[icon2html(badass, world)]</BIG>"
		result += uplink_text

	result += objectives_text

	if(uplink_handler && uplink_handler.contractor_hub)
		result += contractor_round_end()

	var/special_role_text = LOWER_TEXT(name)

	if(traitor_won)
		result += span_greentext("[special_role_text] был успешен!")
	else
		result += span_redtext("[special_role_text] провалился!")
		SEND_SOUND(owner.current, 'sound/ambience/misc/ambifailure.ogg')

	return result.Join("<br>")

///Tells how many contracts have been completed.
/datum/antagonist/traitor/proc/contractor_round_end()
	var/completed_contracts = uplink_handler.contractor_hub.contracts_completed
	var/tc_total = uplink_handler.contractor_hub.contract_TC_payed_out + uplink_handler.contractor_hub.contract_TC_to_redeem

	var/datum/antagonist/traitor/contractor_support/contractor_support_unit = uplink_handler.contractor_hub.contractor_teammate

	if(completed_contracts <= 0)
		return
	var/plural_check = "контракт"
	if (completed_contracts > 1)
		plural_check = "контракты"
	var/sent_data = "Выполнил [span_greentext("[completed_contracts]")] [plural_check] на общую сумму в [span_greentext("[tc_total] ТК")]!<br>"
	if(contractor_support_unit)
		sent_data += "<b>[contractor_support_unit.owner.key]</b> был <b>[contractor_support_unit.owner.current.name]</b>, помощником контратника.<br>"
	return sent_data

/datum/antagonist/traitor/roundend_report_footer()
	var/phrases = jointext(SStraitor.syndicate_code_phrase, ", ")
	var/responses = jointext(SStraitor.syndicate_code_response, ", ")

	var/message = "<br><b>Кодовыми фразами были:</b> <span class='bluetext'>[phrases]</span><br>\
					<b>Кодовыми ответами были:</b> [span_redtext("[responses]")]<br>"

	return message

/datum/outfit/traitor
	name = "Traitor (Preview only)"

	uniform = /obj/item/clothing/under/color/grey
	suit = /obj/item/clothing/suit/hooded/ablative
	head = /obj/item/clothing/head/hooded/ablative
	gloves = /obj/item/clothing/gloves/color/yellow
	mask = /obj/item/clothing/mask/gas
	l_hand = /obj/item/melee/energy/sword
	r_hand = /obj/item/gun/energy/recharge/ebow
	shoes = /obj/item/clothing/shoes/magboots/advance

/datum/outfit/traitor/post_equip(mob/living/carbon/human/H, visuals_only)
	var/obj/item/melee/energy/sword/sword = locate() in H.held_items
	if(sword.flags_1 & INITIALIZED_1)
		sword.attack_self()
	else //Atoms aren't initialized during the screenshots unit test, so we can't call attack_self for it as the sword doesn't have the transforming weapon component to handle the icon changes. The below part is ONLY for the antag screenshots unit test.
		sword.icon_state = "e_sword_on_red"
		sword.inhand_icon_state = "e_sword_on_red"
		sword.worn_icon_state = "e_sword_on_red"

		H.update_held_items()

#undef FLAVOR_FACTION_SYNDICATE
#undef FLAVOR_FACTION_NANOTRASEN

/datum/antagonist/traitor/on_respawn(mob/new_character)
	SSjob.equip_rank(new_character, new_character.mind.assigned_role, new_character.client)
	new_character.mind.give_uplink(silent = TRUE, antag_datum = src)
	return TRUE

/datum/team/cyberpunk_gang
	name = "Street gang"
	var/gang_name = "Free gang"

/datum/team/cyberpunk_gang/New(starting_members, new_gang_name = null)
	. = ..()
	if(new_gang_name)
		gang_name = new_gang_name
		name = gang_name

/datum/team/cyberpunk_anarchists
	name = "Anarchists"
	var/list/sabotaged = list()
	var/list/killed_workers = list()
	var/damage_score = 0
	var/intel = 0
	var/datum/uplink_handler/armory

/datum/team/cyberpunk_anarchists/Destroy()
	QDEL_NULL(armory)
	return ..()

/datum/team/cyberpunk_anarchists/proc/record_pogrom(amount)
	damage_score += amount
	for(var/datum/antagonist/cyberpunk/anarchist/member in GLOB.antagonists)
		if(member.get_team() == src)
			member.add_progress(max(0, damage_score - member.progress_points), "погром")

/datum/team/cyberpunk_liberation_army
	name = "Liberation Army"
	var/list/established_cells = list()
	var/list/casualties = list()
	var/list/wrecks = list()
	var/chaos = 0
	var/nuke_ordered = FALSE
	var/won = FALSE

/datum/team/cyberpunk_data_cult
	name = "Data Cult"
	var/list/harvested_refs = list()
	var/stolen_data = 0
	var/summoned = FALSE

/datum/team/cyberpunk_star_swarm
	name = "Starlight Swarm"
	var/list/pylons = list()
	var/list/builders = list()
	var/biomass = 0
	var/plasma = 0

/datum/antagonist/cyberpunk
	roundend_category = "Cyberpunk antagonists"
	antagpanel_category = "Cyberpunk"
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = FALSE
	can_assign_self_objectives = TRUE
	default_custom_objective = "Push the city into conflict."
	preview_outfit = /datum/outfit/traitor
	var/progress_points = 0
	var/progress_goal = 1000
	var/goal_completed = FALSE

/datum/antagonist/cyberpunk/proc/add_progress(amount, reason = "progress")
	progress_points = max(progress_points + amount, 0)
	if(owner?.current)
		to_chat(owner.current, span_notice("[name]: +[amount] progress ([reason]). Total: [progress_points]/[progress_goal]."))
	if(!goal_completed && progress_points >= progress_goal)
		goal_completed = TRUE
		on_goal_completed(reason)

/datum/antagonist/cyberpunk/proc/on_goal_completed(reason = "progress")
	if(owner?.current)
		to_chat(owner.current, span_boldnotice("[name] objective threshold reached."))

/datum/antagonist/cyberpunk/roundend_report()
	var/list/report = list()
	report += printplayer(owner)
	report += "Progress: [progress_points]/[progress_goal]"
	if(length(objectives))
		report += printobjectives(objectives)
	report += progress_points >= progress_goal ? span_greentext("[name] succeeded.") : span_redtext("[name] failed.")
	return report.Join("<br>")

/datum/antagonist/cyberpunk/bandit
	name = "Bandit"
	pref_flag = ROLE_CYBERPUNK_BANDIT
	antag_hud_name = "traitor"
	progress_goal = 5000
	var/datum/team/cyberpunk_gang/gang
	var/datum/bank_account/watched_account
	var/cartel_deadline
	var/cartel_job_active = FALSE
	var/cartel_credit_baseline

/proc/cyberpunk_find_gang(gang_name)
	for(var/datum/team/cyberpunk_gang/existing in GLOB.antagonist_teams)
		if(lowertext(existing.gang_name) == lowertext(gang_name))
			return existing
	return new /datum/team/cyberpunk_gang(null, gang_name)

/datum/antagonist/cyberpunk/bandit/create_team(datum/team/new_team)
	if(istype(new_team, /datum/team/cyberpunk_gang))
		gang = new_team
		return
	gang = cyberpunk_find_gang(pick("Chrome Rats", "Red Line", "Null Saints"))

/datum/antagonist/cyberpunk/bandit/get_team()
	return gang

/datum/antagonist/cyberpunk/bandit/on_gain()
	. = ..()
	var/obj/item/cyberpunk_black_market_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	owner.current.put_in_hands(chip)
	watch_account()
	START_PROCESSING(SSobj, src)
	if(prob(50))
		var/datum/record/crew/record = cyberpunk_find_security_record_for_mob(owner.current)
		if(record)
			record.wanted_status = WANTED_SUSPECT
			record.security_note = "[record.security_note ? "[record.security_note]\n" : ""]Known criminal-market contact."
			update_matching_security_huds(record.name)
		to_chat(owner.current, span_userdanger("Police database may already contain your name. Keep your heat low."))

/datum/antagonist/cyberpunk/bandit/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("Earn dirty money. Spend it through the black market chip. Deliveries appear at marked coordinates, not in your hands. Gang: [gang?.gang_name || "none"]."))

/datum/antagonist/cyberpunk/bandit/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(watched_account)
		UnregisterSignal(watched_account, list(COMSIG_BANK_ACCOUNT_CREDIT_POSTED, COMSIG_BANK_ACCOUNT_RECEIVED_TRANSFER))
	return ..()

/datum/antagonist/cyberpunk/bandit/proc/watch_account()
	var/datum/bank_account/current = owner?.current?.get_bank_account()
	if(current == watched_account)
		return
	if(watched_account)
		UnregisterSignal(watched_account, list(COMSIG_BANK_ACCOUNT_CREDIT_POSTED, COMSIG_BANK_ACCOUNT_RECEIVED_TRANSFER))
	watched_account = current
	if(watched_account)
		RegisterSignal(watched_account, COMSIG_BANK_ACCOUNT_CREDIT_POSTED, PROC_REF(on_account_credit))
		RegisterSignal(watched_account, COMSIG_BANK_ACCOUNT_RECEIVED_TRANSFER, PROC_REF(on_account_transfer))

/datum/antagonist/cyberpunk/bandit/proc/on_account_credit(datum/bank_account/account, amount, reason)
	SIGNAL_HANDLER
	if(!reason || (findtext(reason, "Off-ledger contract payout") != 1 && findtext(reason, "Black market proceeds") != 1))
		return
	add_progress(amount, "криминальный доход")
	gang?.get_cyberpunk_faction_resources().add_resource("funds", amount)
	if(cartel_job_active && progress_points >= cartel_credit_baseline + 500)
		cartel_job_active = FALSE
		to_chat(owner?.current, span_notice("Картель: поручение выполнено."))
	cartel_deadline = world.time + 15 MINUTES

/datum/antagonist/cyberpunk/bandit/proc/on_account_transfer(datum/bank_account/account, datum/bank_account/from, amount, explicit_reason)
	SIGNAL_HANDLER
	if(from == account || IS_DEPARTMENTAL_ACCOUNT(from) || !from.account_job || findtext(explicit_reason || "", "payroll"))
		return
	cartel_deadline = world.time + 15 MINUTES

/datum/antagonist/cyberpunk/bandit/process(seconds_per_tick)
	watch_account()
	if(!cartel_deadline || world.time < cartel_deadline || owner?.current?.stat == DEAD)
		return
	if(!cartel_job_active)
		cartel_job_active = TRUE
		cartel_credit_baseline = progress_points
		cartel_deadline = world.time + 15 MINUTES
		to_chat(owner.current, span_userdanger("Картель: заработайте 500 кредитов на нелегальных сделках за 15 минут. Иначе полиция получит ордер."))
		return
	var/datum/record/crew/record = cyberpunk_find_security_record_for_mob(owner.current)
	if(!record)
		return
	record.wanted_status = WANTED_ARREST
	record.security_note = "[record.security_note ? "[record.security_note]\n" : ""]Ордер Картеля."
	update_matching_security_huds(record.name)
	cartel_job_active = FALSE
	cartel_deadline = world.time + 15 MINUTES
	to_chat(owner.current, span_userdanger("Картель передал полиции ордер на ваш арест."))

/datum/antagonist/cyberpunk/bandit/proc/sync_dirty_money(mob/living/user)
	to_chat(user, span_notice("Подтверждённый криминальный доход: [progress_points]/[progress_goal]. [cartel_deadline ? "До следующего сообщения: [DisplayTimeText(max(0, cartel_deadline - world.time))]." : "Пополните счёт, чтобы Картель вышел на связь."]"))
	return TRUE

/datum/antagonist/cyberpunk/bandit/proc/show_gang_status(mob/living/user)
	var/list/member_names = list()
	for(var/datum/mind/member as anything in gang?.members)
		member_names += member.name
	to_chat(user, span_notice("Gang: [gang?.gang_name || "none"]. Members: [length(member_names) ? member_names.Join(", ") : "none"]. Funds progress: [progress_points]/[progress_goal]."))

/datum/antagonist/cyberpunk/bandit/proc/configure_gang(mob/living/user)
	var/list/options = list("Chrome Rats", "Red Line", "Null Saints", "Create custom gang", "Cancel")
	var/choice = tgui_input_list(user, "Выберите или создайте банду.", "Банда", options)
	if(!choice || choice == "Cancel")
		return FALSE
	if(choice == "Create custom gang")
		choice = tgui_input_text(user, "Название банды", "Банда", gang?.gang_name, max_length = 32)
		if(!length(choice))
			return FALSE
	var/datum/team/cyberpunk_gang/new_gang = cyberpunk_find_gang(choice)
	if(new_gang != gang)
		gang?.remove_member(owner)
		gang = new_gang
		gang.add_member(owner)
	to_chat(user, span_notice("Ваша банда — [gang.gang_name]."))
	return TRUE

/datum/antagonist/cyberpunk/corporate_spy
	name = "Corporate Spy"
	pref_flag = ROLE_CYBERPUNK_CORPORATE_SPY
	antag_hud_name = "traitor"
	progress_goal = 3
	var/real_corporation_id
	var/cover_corporation_id
	var/completed_tasks_today = 0
	var/list/spy_tasks = list()
	var/datum/uplink_handler/spy_shop

/datum/antagonist/cyberpunk/corporate_spy/on_gain()
	pick_corporations()
	spy_shop = new()
	spy_shop.uplink_flag = UPLINK_TRAITORS
	spy_shop.has_progression = FALSE
	spy_shop.owner = owner
	spy_shop.assigned_role = owner.assigned_role?.title
	spy_shop.purchase_log = new()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(refresh_tasks)), 2 SECONDS)
	var/obj/item/cyberpunk_spy_uplink_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	owner.current.put_in_hands(chip)

/datum/antagonist/cyberpunk/corporate_spy/proc/pick_corporations()
	var/list/corporations = list("benn", "ryaznov", "starlight")
	cover_corporation_id = owner.assigned_role?.get_cyberpunk_corporation_id()
	real_corporation_id = pick(corporations - cover_corporation_id)
	if(!real_corporation_id)
		real_corporation_id = pick(corporations)

/proc/cyberpunk_antag_corporation(atom/movable/target)
	var/mob/living/person = target
	if(istype(person))
		var/mob/living/carbon/human/cyberpunk_npc/worker = person
		if(istype(worker) && worker.cyberpunk_corporation_id)
			return worker.cyberpunk_corporation_id
		return person.mind?.assigned_role?.get_cyberpunk_corporation_id()
	var/corporation = SScyberpunk_corporations?.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(target))
	if(corporation in list("benn", "ryaznov", "starlight"))
		return corporation
	var/area/location = get_area(target)
	return location?.cyberpunk_world_owner

/datum/cyberpunk_spy_task
	var/description
	var/kind
	var/datum/weakref/target_ref
	var/completed = FALSE
	var/broken = FALSE

/datum/cyberpunk_spy_task/New(new_kind, atom/movable/target)
	..()
	kind = new_kind
	target_ref = WEAKREF(target)
	switch(kind)
		if("sabotage")
			description = "Выведите из строя [target.name] в [get_area_name(target)]."
			RegisterSignals(target, list(COMSIG_ATOM_BREAK, COMSIG_MACHINERY_BROKEN, COMSIG_QDELETING), PROC_REF(on_broken))
		if("research")
			description = "Добудьте [target.name] и доставьте на территорию работодателя."
		if("kidnap")
			description = "Доставьте [target.name] живым на территорию работодателя."

/datum/cyberpunk_spy_task/Destroy()
	var/atom/movable/target = target_ref?.resolve()
	if(target && kind == "sabotage")
		UnregisterSignal(target, list(COMSIG_ATOM_BREAK, COMSIG_MACHINERY_BROKEN, COMSIG_QDELETING))
	return ..()

/datum/cyberpunk_spy_task/proc/on_broken()
	SIGNAL_HANDLER
	broken = TRUE

/datum/antagonist/cyberpunk/corporate_spy/Destroy()
	QDEL_LIST(spy_tasks)
	QDEL_NULL(spy_shop)
	return ..()

/datum/antagonist/cyberpunk/corporate_spy/proc/refresh_tasks()
	if(length(spy_tasks) || !owner?.current)
		return
	var/list/machines = list()
	var/list/research = list()
	var/list/people = list()
	for(var/obj/machinery/machine in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery))
		if(QDELETED(machine) || !is_station_level(machine.z) || cyberpunk_antag_corporation(machine) != cover_corporation_id)
			continue
		machines += machine
		for(var/obj/item/sample in machine.contents)
			if(!sample.anchored)
				research += sample
	for(var/mob/living/person in GLOB.mob_living_list)
		if(person.mind && person != owner.current && person.stat != DEAD && cyberpunk_antag_corporation(person) == cover_corporation_id)
			people += person
	if(!length(research))
		for(var/obj/item/sample in view(8, owner.current))
			if(!sample.anchored && cyberpunk_antag_corporation(sample) == cover_corporation_id)
				research += sample
	if(!length(machines) || !length(people))
		return
	if(!length(research))
		var/obj/machinery/storage_point = pick(machines)
		var/obj/item/paper/sample = new(get_turf(storage_point))
		sample.name = "исследовательское досье [cover_corporation_id]"
		research += sample
	spy_tasks += new /datum/cyberpunk_spy_task("sabotage", pick(machines))
	spy_tasks += new /datum/cyberpunk_spy_task("research", pick(research))
	spy_tasks += new /datum/cyberpunk_spy_task("kidnap", pick(people))
	to_chat(owner.current, span_notice("Получен пакет из трёх поручений. Откройте прибор связи."))

/datum/antagonist/cyberpunk/corporate_spy/proc/complete_task(mob/living/user)
	if(!length(spy_tasks))
		refresh_tasks()
	var/completed_now = 0
	var/area/location = get_area(user)
	for(var/datum/cyberpunk_spy_task/task in spy_tasks)
		if(task.completed)
			continue
		var/atom/movable/target = task.target_ref?.resolve()
		var/area/destination = get_area(target)
		switch(task.kind)
			if("sabotage")
				if(!task.broken)
					continue
			if("research")
				if(!target || location?.cyberpunk_world_owner != real_corporation_id || !(target in user.get_all_contents()))
					continue
			if("kidnap")
				var/mob/living/person = target
				if(!person || person.stat == DEAD || destination?.cyberpunk_world_owner != real_corporation_id || !user.Adjacent(person))
					continue
		task.completed = TRUE
		completed_tasks_today++
		completed_now++
		add_progress(1, task.description)
		SScyberpunk_corporations?.record_cyberpunk_corporate_activity(real_corporation_id, "espionage", 25, 0, task.description)
	if(!completed_now)
		to_chat(user, span_warning("Нет подтверждённых результатов для передачи."))
	return !!completed_now

/proc/cyberpunk_antag_choose_uplink_item(mob/living/user, datum/uplink_handler/shop, rate, currency, weapons_only = FALSE)
	var/list/options = list()
	for(var/datum/uplink_item/item as anything in SStraitor.uplink_items)
		if(!shop.check_if_restricted(item) || item.cost <= 0 || !item.item || item.restricted)
			continue
		if(weapons_only && !istype(item, /datum/uplink_item/weapon_kits) && !istype(item, /datum/uplink_item/ammo_nuclear) && !ispath(item.item, /obj/item/gun) && !ispath(item.item, /obj/item/ammo_box) && !ispath(item.item, /obj/item/grenade))
			continue
		options["[item.name] ([item.cost * rate] [currency]) · [item.type]"] = item
	var/choice = tgui_input_list(user, "Выберите снаряжение.", "Аплинк", options)
	return options[choice]

/datum/antagonist/cyberpunk/corporate_spy/proc/purchase_supplies(mob/living/user, atom/movable/source)
	var/datum/uplink_item/item = cyberpunk_antag_choose_uplink_item(user, spy_shop, 250, "кредитов")
	var/datum/bank_account/account = user.get_bank_account()
	if(!item || !account || owner?.current != user || QDELETED(source))
		return FALSE
	var/cost = item.cost * 250
	spy_shop.telecrystals = item.cost
	if(!spy_shop.can_purchase_item(user, item) || !account.adjust_money(-cost, "Прибор связи: [item.name]"))
		spy_shop.telecrystals = 0
		return FALSE
	var/purchased = spy_shop.purchase_item(user, item, source)
	spy_shop.telecrystals = 0
	if(!purchased)
		account.adjust_money(cost, "Возврат за заказ прибора связи")
	return purchased

/datum/antagonist/cyberpunk/corporate_spy/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("You are secretly working for [real_corporation_id]. Your cover corporation is [cover_corporation_id || "unknown"]. Use the spy chip to review and upload tasks."))

/datum/antagonist/cyberpunk/anarchist
	name = "Anarchist"
	pref_flag = ROLE_CYBERPUNK_ANARCHIST
	antag_hud_name = "rev"
	progress_goal = 10000
	var/datum/team/cyberpunk_anarchists/anarchist_team
	var/datum/cyberpunk_anarchist_recruitment/recruitment
	var/list/sabotage_targets = list()

/datum/antagonist/cyberpunk/anarchist/create_team(datum/team/new_team)
	if(istype(new_team, /datum/team/cyberpunk_anarchists))
		anarchist_team = new_team
		return
	var/static/datum/team/cyberpunk_anarchists/global_team
	if(!global_team)
		global_team = new()
	anarchist_team = global_team

/datum/antagonist/cyberpunk/anarchist/get_team()
	return anarchist_team

/datum/antagonist/cyberpunk/anarchist/apply_innate_effects(mob/living/mob_override)
	var/mob/living/target = mob_override || owner.current
	add_team_hud(target, /datum/antagonist/cyberpunk/anarchist)

/datum/antagonist/cyberpunk/anarchist/on_gain()
	. = ..()
	var/obj/item/cyberpunk_anarchist_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	owner.current.put_in_hands(chip)
	var/obj/item/cyberpunk_anarchist_beacon/beacon = new(get_turf(owner.current))
	beacon.team = anarchist_team
	owner.current.put_in_hands(beacon)
	if(anarchist_team.damage_score)
		add_progress(anarchist_team.damage_score, "результат ячейки")
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_worker_death))

/datum/antagonist/cyberpunk/anarchist/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	QDEL_NULL(recruitment)
	for(var/datum/weakref/reference as anything in sabotage_targets)
		var/atom/movable/target = reference.resolve()
		if(target)
			UnregisterSignal(target, COMSIG_QDELETING)
	return ..()

/datum/antagonist/cyberpunk/anarchist/proc/on_worker_death(datum/source, mob/living/target)
	SIGNAL_HANDLER
	if(!owner?.current?.ckey || target.lastattackerckey != owner.current.ckey || !target.mind || target == owner.current)
		return
	var/corporation = cyberpunk_antag_corporation(target)
	if(!(corporation in list("benn", "ryaznov", "starlight")) || target.mind in anarchist_team.killed_workers)
		return
	anarchist_team.killed_workers += target.mind
	anarchist_team.record_pogrom(500)

/datum/antagonist/cyberpunk/anarchist/proc/convert_target(mob/living/user, mob/living/target)
	if(!target?.mind || target.stat == DEAD || !target.has_neural_implant() || target.mind.has_antag_datum(type) || get_dist(user, target) > 2 || user.z != target.z)
		return FALSE
	QDEL_NULL(recruitment)
	recruitment = new(src, user, target)
	to_chat(user, span_notice("Говорите с целью в пределах двух клеток. Нужна минута речи."))
	return TRUE

/datum/cyberpunk_anarchist_recruitment
	var/datum/antagonist/cyberpunk/anarchist/recruiter
	var/mob/living/user
	var/mob/living/target
	var/words = 0
	var/next_word = 0

/datum/cyberpunk_anarchist_recruitment/New(datum/antagonist/cyberpunk/anarchist/new_recruiter, mob/living/speaker, mob/living/listener)
	..()
	recruiter = new_recruiter
	user = speaker
	target = listener
	RegisterSignal(user, COMSIG_MOB_SAY, PROC_REF(on_speech))
	RegisterSignals(user, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_DISARM_HIT, COMSIG_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(interrupt))
	RegisterSignals(target, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_DISARM_HIT, COMSIG_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(interrupt))

/datum/cyberpunk_anarchist_recruitment/Destroy()
	UnregisterSignal(user, list(COMSIG_MOB_SAY, COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_DISARM_HIT, COMSIG_QDELETING, COMSIG_LIVING_DEATH))
	UnregisterSignal(target, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_DISARM_HIT, COMSIG_QDELETING, COMSIG_LIVING_DEATH))
	if(recruiter?.recruitment == src)
		recruiter.recruitment = null
	recruiter = null
	user = null
	target = null
	return ..()

/datum/cyberpunk_anarchist_recruitment/proc/interrupt()
	SIGNAL_HANDLER
	to_chat(user, span_warning("Перепрошивка сорвана."))
	qdel(src)

/datum/cyberpunk_anarchist_recruitment/proc/on_speech(mob/living/speaker, list/speech_args)
	SIGNAL_HANDLER
	if(world.time < next_word || speaker.z != target.z || get_dist(speaker, target) > 2 || speaker.stat != CONSCIOUS || speech_args[SPEECH_FORCED])
		return
	var/message = trim(speech_args[SPEECH_MESSAGE])
	if(!length(message) || (copytext(message, 1, 2) in list(":", ";", "*")))
		return
	next_word = world.time + 1 SECONDS
	words++
	if(words == 60)
		INVOKE_ASYNC(src, PROC_REF(finish))

/datum/cyberpunk_anarchist_recruitment/proc/finish()
	if(QDELETED(recruiter) || !target?.mind || target.stat == DEAD || target.mind.has_antag_datum(/datum/antagonist/cyberpunk/anarchist) || !target.has_neural_implant() || user.z != target.z || get_dist(user, target) > 2)
		qdel(src)
		return
	var/datum/antagonist/cyberpunk/anarchist/convert = new()
	convert.silent = TRUE
	target.mind.add_antag_datum(convert, recruiter.anarchist_team)
	recruiter.anarchist_team.intel += 20
	to_chat(target, span_userdanger("Вы вступили в ячейку анархистов."))
	qdel(src)

/datum/antagonist/cyberpunk/anarchist/proc/mark_sabotage(mob/living/user, obj/target)
	if(!target?.uses_integrity || !(cyberpunk_antag_corporation(target) in list("benn", "ryaznov", "starlight")))
		return FALSE
	if(WEAKREF(target) in sabotage_targets)
		return FALSE
	sabotage_targets += WEAKREF(target)
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_sabotage))
	to_chat(user, span_notice("Цель ячейки: [target.name] · [cyberpunk_antag_corporation(target)]."))
	return TRUE

/datum/antagonist/cyberpunk/anarchist/proc/on_sabotage(obj/target)
	SIGNAL_HANDLER
	if(target.get_integrity() > 0 || REF(target) in anarchist_team.sabotaged)
		return
	anarchist_team.sabotaged += REF(target)
	anarchist_team.record_pogrom(250)

/datum/antagonist/cyberpunk/anarchist/proc/generate_pogrom(mob/living/user)
	var/target_corp = tgui_input_list(user, "Выберите корпорацию.", "Задания ячейки", list("benn", "ryaznov", "starlight"))
	if(!target_corp)
		return FALSE
	var/list/equipment = list()
	var/list/workers = list()
	for(var/obj/machinery/machine in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery))
		if(machine.uses_integrity && is_station_level(machine.z) && cyberpunk_antag_corporation(machine) == target_corp && !(WEAKREF(machine) in sabotage_targets))
			equipment += machine
	for(var/mob/living/person in GLOB.alive_player_list)
		if(person.mind && cyberpunk_antag_corporation(person) == target_corp)
			workers += person
	if(length(equipment))
		var/obj/machinery/target = pick(equipment)
		mark_sabotage(user, target)
		to_chat(user, span_notice("Погром: уничтожьте [target.name] в [get_area_name(target)]."))
	if(length(workers))
		var/mob/living/worker = pick(workers)
		to_chat(user, span_notice("Цель ячейки: [worker.real_name], сотрудник [target_corp]."))
	to_chat(user, span_notice("На маяк можно сдать предмет производителя [target_corp] и получить разведданные."))
	return TRUE

/datum/antagonist/cyberpunk/anarchist/proc/purchase_armory(mob/living/user, atom/movable/source)
	var/datum/uplink_handler/shop = anarchist_team.armory
	if(!shop)
		shop = new()
		shop.uplink_flag = UPLINK_NUKE_OPS
		shop.has_progression = FALSE
		shop.purchase_log = new()
		anarchist_team.armory = shop
	var/datum/uplink_item/item = cyberpunk_antag_choose_uplink_item(user, shop, 5, "данных", weapons_only = TRUE)
	if(!item || owner?.current != user || QDELETED(source) || anarchist_team.intel < item.cost * 5)
		return FALSE
	shop.telecrystals = item.cost
	anarchist_team.intel -= item.cost * 5
	var/purchased = shop.purchase_item(user, item, source)
	shop.telecrystals = 0
	if(!purchased)
		anarchist_team.intel += item.cost * 5
	return purchased

/datum/antagonist/cyberpunk/anarchist/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("Разрушайте инфраструктуру корпораций и устраняйте их работников. Кражи и вербовка дают данные на оружие."))

/obj/item/cyberpunk_anarchist_beacon
	name = "маяк анархистов"
	desc = "Разверните в трущобах и сдавайте корпоративные предметы."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk3"
	w_class = WEIGHT_CLASS_SMALL
	var/datum/team/cyberpunk_anarchists/team
	var/deployed = FALSE

/obj/item/cyberpunk_anarchist_beacon/attack_self(mob/living/user)
	var/area/location = get_area(user)
	if(!(location?.cyberpunk_district_id in list("wasteland", "test_ground")))
		to_chat(user, span_warning("Маяк можно развернуть в западных трущобах."))
		return
	if(user.dropItemToGround(src))
		set_anchored(TRUE)
		deployed = TRUE
		to_chat(user, span_notice("Маяк развёрнут."))

/obj/item/cyberpunk_anarchist_beacon/attackby(obj/item/offering, mob/user, params)
	var/datum/antagonist/cyberpunk/anarchist/anarchist = user.mind?.has_antag_datum(/datum/antagonist/cyberpunk/anarchist)
	if(!deployed || !team || anarchist?.anarchist_team != team)
		return ..()
	var/corporation = SScyberpunk_corporations?.cyberpunk_corporation_id_from_manufacturer(get_cyberspace_manufacturer(offering))
	if(!(corporation in list("benn", "ryaznov", "starlight")) || !user.dropItemToGround(offering))
		to_chat(user, span_warning("Маяк принимает только предметы с маркировкой корпораций."))
		return TRUE
	team.intel += 10
	qdel(offering)
	to_chat(user, span_notice("Предмет принят. Ячейка получила 10 разведданных."))
	return TRUE

/datum/antagonist/cyberpunk/major
	show_in_antagpanel = TRUE
	can_assign_self_objectives = FALSE
	progress_goal = 1
	var/chip_name = "cyberpunk antagonist key"
	var/chip_desc = "A control key for a cyberpunk antagonist role."
	var/primary_action = "Act"
	var/primary_points = 100
	var/primary_delay = 10 SECONDS
	var/primary_target_prompt = "Choose a nearby target."
	var/primary_reason = "action"
	var/role_briefing = "Use your control chip to push your objective."
	var/team_type
	var/datum/team/cyberpunk_major_team
	var/list/acted_refs = list()
	var/list/action_cooldowns = list()

/datum/antagonist/cyberpunk/major/create_team(datum/team/new_team)
	if(team_type && istype(new_team, team_type))
		cyberpunk_major_team = new_team

/datum/antagonist/cyberpunk/major/get_team()
	if(cyberpunk_major_team)
		return cyberpunk_major_team
	if(team_type)
		cyberpunk_major_team = new team_type()
	return cyberpunk_major_team

/datum/antagonist/cyberpunk/major/on_gain()
	. = ..()
	var/obj/item/cyberpunk_antag_control_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	chip.name = chip_name
	chip.desc = chip_desc
	owner.current.put_in_hands(chip)

/datum/antagonist/cyberpunk/major/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("[name]: use your control chip. Current objective progress: [progress_points]/[progress_goal]."))
	to_chat(owner.current, span_notice(role_briefing))

/datum/antagonist/cyberpunk/major/roundend_report()
	var/report = ..()
	var/extra_report = extra_roundend_report()
	if(extra_report)
		report += "<br>[extra_report]"
	return report

/datum/antagonist/cyberpunk/major/proc/extra_roundend_report()
	var/list/extra = list()
	extra += "Unique targets affected: [length(acted_refs)]"
	var/datum/team/team = get_team()
	if(team?.cyberpunk_faction_resources)
		var/list/resources = team.cyberpunk_faction_resources.to_snapshot()
		extra += "Team resources: influence [resources["influence"]], funds [resources["funds"]], supplies [resources["supplies"]]."
	return extra.Join("<br>")

/datum/antagonist/cyberpunk/major/proc/get_chip_options(mob/living/user)
	return list(primary_action, "Status", "Cancel")

/datum/antagonist/cyberpunk/major/proc/handle_chip_option(mob/living/user, choice)
	if(choice == "Status")
		to_chat(user, span_notice("[name] progress: [progress_points]/[progress_goal]."))
		return TRUE
	if(choice == primary_action)
		return perform_primary_action(user)
	return FALSE

/datum/antagonist/cyberpunk/major/proc/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/atom/nearby as anything in view(1, user))
		if(nearby == user)
			continue
		if(ismob(nearby) || isobj(nearby))
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/proc/perform_primary_action(mob/living/user)
	var/list/targets = get_primary_targets(user)
	var/atom/target = tgui_input_list(user, primary_target_prompt, name, targets)
	if(!target)
		return FALSE
	var/target_ref = REF(target)
	if(target_ref in acted_refs)
		to_chat(user, span_warning("[target] is already counted for this objective."))
		return FALSE
	user.visible_message(span_warning("[user] works on [target] with [chip_name]."), span_notice("You begin [lowertext(primary_action)]. Hold still."))
	if(!do_after(user, primary_delay, target = target))
		to_chat(user, span_warning("Interrupted."))
		return FALSE
	acted_refs += target_ref
	add_progress(primary_points, primary_reason)
	return TRUE

/datum/antagonist/cyberpunk/major/proc/choose_living_target(mob/living/user, range = 1, prompt = "Choose target.")
	var/list/targets = list()
	for(var/mob/living/nearby in view(range, user))
		if(nearby != user && nearby.stat != DEAD)
			targets += nearby
	return tgui_input_list(user, prompt, name, targets)

/proc/cyberpunk_antag_select_corpse(mob/living/user, title)
	var/list/corpses = list()
	for(var/mob/living/nearby in view(1, user))
		if(nearby.stat == DEAD)
			corpses += nearby
	var/mob/living/choice = tgui_input_list(user, "Выберите погибшего.", title, corpses)
	if(!QDELETED(choice) && user.Adjacent(choice) && choice.stat == DEAD)
		return choice

/datum/antagonist/cyberpunk/major/proc/direct_damage(mob/living/user, mob/living/target, amount = 20, damage_type = BRUTE, reason = "attack")
	if(!target || target.stat == DEAD)
		return FALSE
	target.apply_damage(amount, damage_type, BODY_ZONE_CHEST)
	target.visible_message(span_danger("[target] is struck by [name]."), span_userdanger("[name] tears into you."))
	add_progress(max(1, round(amount / 5)), reason)
	return TRUE

/datum/antagonist/cyberpunk/major/proc/spawn_antag_asset(mob/living/user, asset_type, reason = "asset", points = 1)
	new asset_type(get_turf(user))
	add_progress(points, reason)
	return TRUE

/datum/antagonist/cyberpunk/major/proc/action_ready(mob/living/user, action_key, cooldown_time)
	var/ready_at = action_cooldowns[action_key] || 0
	if(world.time < ready_at)
		to_chat(user, span_warning("That action is still cooling down for [DisplayTimeText(ready_at - world.time)]."))
		return FALSE
	action_cooldowns[action_key] = world.time + cooldown_time
	return TRUE

/datum/antagonist/cyberpunk/major/proc/summon_ghost_asset(mob/living/user, mob_type, role_name = "cyberpunk reinforcement", points = 1)
	if(!action_ready(user, "ghost_[role_name]", 3 MINUTES))
		return FALSE
	to_chat(user, span_notice("Broadcasting a ghost-role request for [role_name]."))
	var/mob/chosen_one = SSpolling.poll_ghost_candidates("Do you want to play as [role_name]?", check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, poll_time = 10 SECONDS, alert_pic = mob_type, jump_target = user, role_name_text = role_name, amount_to_pick = 1)
	if(!chosen_one)
		to_chat(user, span_warning("No volunteer answered."))
		return FALSE
	var/mob/living/spawned = new mob_type(get_turf(user))
	spawned.PossessByPlayer(chosen_one.key)
	if(spawned.mind)
		get_team()?.add_member(spawned.mind)
		LAZYADD(spawned.mind.special_roles, role_name)
	message_admins("[key_name_admin(chosen_one)] has taken control of [spawned] as [role_name].")
	add_progress(points, "ghost reinforcement")
	return TRUE

/datum/team/cyberpunk_shifters
	name = "Оборотни Бэнь"
	var/required_conversions
	var/list/converted = list()
	var/outbreak = FALSE

/datum/team/cyberpunk_shifters/proc/register_conversion(datum/mind/converted_mind)
	if(!converted_mind || converted_mind in converted)
		return
	converted += converted_mind
	if(!outbreak && length(converted) >= required_conversions)
		outbreak = TRUE
		priority_announce("Заражение Бэнь достигло критического порога. У носителей обнаружены боевые щупальца.", "Биологическая тревога")
	for(var/datum/antagonist/cyberpunk/major/benn_shifter/shifter in GLOB.antagonists)
		if(shifter.get_team() == src)
			shifter.progress_points = length(converted)
			shifter.goal_completed = outbreak

/datum/antagonist/cyberpunk/major/benn_shifter
	name = "Benn Shifter"
	pref_flag = ROLE_CYBERPUNK_BENN_SHIFTER
	chip_name = "ключ нароста Бэнь"
	chip_desc = "Управляет наростами и расходом массы."
	role_briefing = "Питайтесь, развивайте наросты и обратите 30% игроков."
	team_type = /datum/team/cyberpunk_shifters
	var/stage = 1
	var/mass = 0
	var/initial_carrier = TRUE
	var/list/growths = list()
	var/datum/status_effect/cyberpunk_shifter_growth/viewed_growth

/datum/antagonist/cyberpunk/major/benn_shifter/on_gain()
	var/datum/team/cyberpunk_shifters/team = get_team()
	if(!team.required_conversions)
		team.required_conversions = max(1, CEILING(length(GLOB.alive_player_list) * 0.3, 1))
	progress_goal = team.required_conversions
	. = ..()
	RegisterSignal(owner.current, COMSIG_LIVING_HEALTHSCAN, PROC_REF(on_shifter_scan))
	START_PROCESSING(SSobj, src)

/datum/antagonist/cyberpunk/major/benn_shifter/Destroy()
	if(owner?.current)
		UnregisterSignal(owner.current, COMSIG_LIVING_HEALTHSCAN)
	STOP_PROCESSING(SSobj, src)
	stop_watching()
	return ..()

/datum/antagonist/cyberpunk/major/benn_shifter/proc/on_shifter_scan(mob/living/scanned, list/report, advanced)
	SIGNAL_HANDLER
	if(advanced && !scanned.has_status_effect(/datum/status_effect/cyberpunk_shifter_mimicry))
		report += span_warning("Обнаружена аномальная биомасса Бэнь.")

/datum/antagonist/cyberpunk/major/benn_shifter/process(seconds_per_tick)
	var/mob/living/body = owner?.current
	if(!body || body.stat == DEAD)
		return
	var/drained = min(seconds_per_tick * 2, max(0, body.nutrition - NUTRITION_LEVEL_STARVING))
	if(drained)
		body.adjust_nutrition(-drained, forced = TRUE)
		mass = min(mass + drained, 500)
		stage = max(stage, min(5, 1 + FLOOR(mass / 100, 1)))
	REMOVE_TRAIT(body, TRAIT_FAT, OBESITY)

/datum/antagonist/cyberpunk/major/benn_shifter/get_chip_options(mob/living/user)
	var/list/options = list("Наросты", "Вернуть обзор", "Голос в наросте", "Status", "Cancel")
	if(initial_carrier || stage >= 5)
		options += "Подсадить нарост"
	if(stage >= 2)
		options += "Регенерация"
	if(stage >= 3)
		options += "Мимикрия"
	if(stage >= 5)
		options += "Оглушить щупальцем"
	var/datum/team/cyberpunk_shifters/team = get_team()
	if(team.outbreak)
		options += "Щупальце-кнут"
	return options

/datum/antagonist/cyberpunk/major/benn_shifter/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Подсадить нарост")
			return perform_primary_action(user)
		if("Наросты")
			var/list/available = list()
			for(var/datum/status_effect/cyberpunk_shifter_growth/growth in growths)
				if(!QDELETED(growth.owner) && growth.owner.stat != DEAD)
					available[REF(growth.owner) + " — [growth.owner.name] ([growth.stage]/5)"] = growth
			var/selected = tgui_input_list(user, "Выберите носителя.", name, available)
			var/datum/status_effect/cyberpunk_shifter_growth/growth = available[selected]
			if(QDELETED(growth) || QDELETED(growth.owner))
				return FALSE
			viewed_growth = growth
			user.reset_perspective(growth.owner)
			return TRUE
		if("Вернуть обзор")
			stop_watching()
			return TRUE
		if("Голос в наросте")
			var/datum/status_effect/cyberpunk_shifter_growth/growth = viewed_growth
			if(!growth || growth.stage < 4)
				return FALSE
			var/message = tgui_input_text(user, "Что услышит носитель?", name, max_length = MAX_MESSAGE_LEN)
			if(!message || QDELETED(growth) || growth.owner.stat == DEAD)
				return FALSE
			to_chat(growth.owner, span_notice("Голос нароста: [html_encode(message)]"))
			return TRUE
		if("Регенерация")
			if(!spend_mass(25, "regenerate", 10 SECONDS))
				return FALSE
			user.heal_ordered_damage(25, list(BRUTE, BURN, TOX, OXY))
			return TRUE
		if("Мимикрия")
			if(!spend_mass(40, "mimicry", 1 MINUTES))
				return FALSE
			user.apply_status_effect(/datum/status_effect/cyberpunk_shifter_mimicry)
			return TRUE
		if("Оглушить щупальцем", "Щупальце-кнут")
			var/mob/living/target = choose_living_target(user, 3, "Выберите цель.")
			if(!target || target.stat == DEAD || !spend_mass(20, choice, 8 SECONDS))
				return FALSE
			if(choice == "Оглушить щупальцем")
				target.Paralyze(3 SECONDS)
			else
				target.apply_damage(45, BRUTE, BODY_ZONE_CHEST, sharpness = SHARP_EDGED)
			return TRUE
		if("Status")
			to_chat(user, span_notice("Стадия [stage]/5, масса [round(mass)]. Обращено [progress_points]/[progress_goal]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/benn_shifter/proc/spend_mass(amount, key, delay)
	if(mass < amount || !action_ready(owner.current, key, delay))
		return FALSE
	mass -= amount
	return TRUE

/datum/antagonist/cyberpunk/major/benn_shifter/proc/stop_watching()
	if(viewed_growth)
		owner?.current?.reset_perspective(null)
		viewed_growth = null

/datum/antagonist/cyberpunk/major/benn_shifter/perform_primary_action(mob/living/user)
	var/mob/living/target = choose_living_target(user, 1, "Кому подсадить нарост?")
	if(!target?.mind || !iscarbon(target) || target.stat == DEAD || target.mind.has_antag_datum(type) || target.has_status_effect(/datum/status_effect/cyberpunk_shifter_growth))
		return FALSE
	if(!do_after(user, 10 SECONDS, target = target) || target.stat == DEAD || target.mind?.has_antag_datum(type))
		return FALSE
	return !!target.apply_status_effect(/datum/status_effect/cyberpunk_shifter_growth, src)

/datum/status_effect/cyberpunk_shifter_mimicry
	id = "cyberpunk_shifter_mimicry"
	duration = 30 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/cyberpunk_shifter_growth
	id = "cyberpunk_shifter_growth"
	alert_type = null
	tick_interval = 2 SECONDS
	var/stage = 1
	var/mass = 0
	var/datum/weakref/origin
	var/datum/team/cyberpunk_shifters/team

/datum/status_effect/cyberpunk_shifter_growth/on_creation(mob/living/new_owner, datum/antagonist/cyberpunk/major/benn_shifter/shifter)
	origin = WEAKREF(shifter)
	team = shifter.get_team()
	. = ..(new_owner)
	if(!QDELETED(src))
		shifter.growths += src
		RegisterSignal(new_owner, COMSIG_LIVING_HEALTHSCAN, PROC_REF(on_growth_scan))

/datum/status_effect/cyberpunk_shifter_growth/tick(seconds_between_ticks)
	if(owner.stat == DEAD)
		qdel(src)
		return
	var/drained = min(4 * seconds_between_ticks, max(0, owner.nutrition - NUTRITION_LEVEL_STARVING))
	if(!drained)
		return
	owner.adjust_nutrition(-drained, forced = TRUE)
	mass += drained
	stage = min(5, 1 + FLOOR(mass / 120, 1))
	if(stage < 5 || !owner.mind)
		return
	if(!owner.mind.has_antag_datum(/datum/antagonist/cyberpunk/major/benn_shifter))
		var/datum/antagonist/cyberpunk/major/benn_shifter/shifter = new()
		shifter.initial_carrier = FALSE
		shifter.stage = 5
		shifter.mass = 200
		owner.mind.add_antag_datum(shifter, team)
		team.register_conversion(owner.mind)
		to_chat(owner, span_userdanger("Нарост созрел. Теперь вы оборотень Бэнь."))
	qdel(src)

/datum/status_effect/cyberpunk_shifter_growth/proc/on_growth_scan(datum/source, list/report, advanced)
	SIGNAL_HANDLER
	if(advanced)
		report += span_warning("Обнаружен паразитарный нарост. Стадия [stage]/5.")

/datum/status_effect/cyberpunk_shifter_growth/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_HEALTHSCAN)
	var/datum/antagonist/cyberpunk/major/benn_shifter/shifter = origin?.resolve()
	if(shifter)
		shifter.growths -= src
		if(shifter.viewed_growth == src)
			shifter.stop_watching()
	team = null

/datum/antagonist/cyberpunk/major/benn_prototype
	name = "Benn Prototype"
	pref_flag = ROLE_CYBERPUNK_BENN_PROTOTYPE
	progress_goal = 8
	chip_name = "prototype genome key"
	chip_desc = "A Benn DNA harvest controller."
	primary_action = "Harvest DNA"
	primary_points = 1
	primary_delay = 12 SECONDS
	primary_reason = "dna"
	primary_target_prompt = "Choose a nearby body or victim."
	role_briefing = "Harvest DNA to gain points, unlock mutations, then use those mutations for weapons, damage, defense, and movement."
	var/dna_points = 0
	var/list/unlocked_abilities = list()
	var/datum/dna/original_identity
	var/list/absorbed_identities = list()
	var/datum/weakref/heart_ref

/datum/antagonist/cyberpunk/major/benn_prototype/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user)
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/benn_prototype/get_chip_options(mob/living/user)
	return list(primary_action, "Unlock mutation", "Use mutation", "Принять облик", "Вернуть облик", "Говорить с поглощёнными", "Сдать очко эволюции", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/benn_prototype/handle_chip_option(mob/living/user, choice)
	if(choice == "Unlock mutation")
		return unlock_mutation(user)
	switch(choice)
		if("Use mutation")
			return use_mutation(user)
		if("Принять облик")
			var/identity_name = tgui_input_list(user, "Выберите поглощённый облик.", name, absorbed_identities)
			var/datum/dna/identity = absorbed_identities[identity_name]
			return change_prototype_identity(user, identity)
		if("Вернуть облик")
			return change_prototype_identity(user, original_identity)
		if("Говорить с поглощёнными")
			var/obj/item/organ/heart/cyberpunk_prototype/heart = heart_ref?.resolve()
			if(!heart || heart.owner != user)
				return FALSE
			var/message = tgui_input_text(user, "Что услышат поглощённые?", name, max_length = MAX_MESSAGE_LEN)
			if(!message || QDELETED(heart) || heart.owner != user)
				return FALSE
			for(var/mob/living/captive in heart.contents)
				to_chat(captive, span_notice("Прототип: [html_encode(message)]"))
			return TRUE
		if("Сдать очко эволюции")
			if(dna_points < 1 || goal_completed)
				return FALSE
			dna_points--
			add_progress(1, "эволюция")
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/benn_prototype/on_gain()
	. = ..()
	var/mob/living/carbon/human/body = owner.current
	if(istype(body) && body.dna)
		original_identity = new()
		body.dna.copy_dna(original_identity, NONE)

/datum/antagonist/cyberpunk/major/benn_prototype/Destroy()
	var/obj/item/organ/heart/cyberpunk_prototype/heart = heart_ref?.resolve()
	heart?.release_husks()
	QDEL_NULL(original_identity)
	QDEL_LIST_ASSOC_VAL(absorbed_identities)
	return ..()

/datum/antagonist/cyberpunk/major/benn_prototype/perform_primary_action(mob/living/carbon/human/user)
	if(!istype(user))
		return FALSE
	var/mob/living/carbon/human/target = choose_living_target(user, 1, "Выберите тело для поглощения.")
	if(!istype(target) || !target.dna || !isturf(target.loc) || (target.stat == CONSCIOUS && !HAS_TRAIT(target, TRAIT_IMMOBILIZED)))
		return FALSE
	if(REF(target.mind || target) in acted_refs)
		return FALSE
	if(!do_after(user, primary_delay, target = target) || QDELETED(target) || !user.Adjacent(target) || (target.stat == CONSCIOUS && !HAS_TRAIT(target, TRAIT_IMMOBILIZED)))
		return FALSE
	var/obj/item/organ/heart/cyberpunk_prototype/heart = user.get_organ_slot(ORGAN_SLOT_HEART)
	if(!istype(heart))
		if(heart_ref?.resolve() || !user.get_organ_slot(ORGAN_SLOT_HEART))
			return FALSE
		heart = new(get_turf(user))
		if(!heart.Insert(user, special = TRUE, movement_flags = DELETE_IF_REPLACED))
			qdel(heart)
			return FALSE
		heart_ref = WEAKREF(heart)
	var/identity_name = "[target.real_name] ([length(absorbed_identities) + 1])"
	var/datum/dna/identity = new()
	target.dna.copy_dna(identity, NONE)
	absorbed_identities[identity_name] = identity
	acted_refs += REF(target.mind || target)
	target.become_husk(REF(heart))
	ADD_TRAIT(target, TRAIT_STASIS, REF(heart))
	ADD_TRAIT(target, TRAIT_IMMOBILIZED, REF(heart))
	target.forceMove(heart)
	heart.RegisterSignal(target, COMSIG_MOB_SAY, TYPE_PROC_REF(/obj/item/organ/heart/cyberpunk_prototype, on_husk_speech))
	dna_points++
	to_chat(user, span_notice("Облик поглощён. Свободные очки мутации: [dna_points]."))
	return TRUE

/datum/antagonist/cyberpunk/major/benn_prototype/proc/change_prototype_identity(mob/living/carbon/human/user, datum/dna/identity)
	if(!istype(user) || !user.dna || !identity)
		return FALSE
	user.real_name = identity.real_name
	user.name = identity.real_name
	user.dna.unique_identity = identity.unique_identity
	user.dna.unique_features = identity.unique_features
	user.dna.features = identity.features.Copy()
	user.updateappearance(mutcolor_update = TRUE)
	return TRUE

/obj/item/organ/heart/cyberpunk_prototype
	name = "сердце прототипа"

/obj/item/organ/heart/cyberpunk_prototype/attackby(obj/item/weapon, mob/user, params)
	if(!owner && weapon.force > 0)
		release_husks()
	return ..()

/obj/item/organ/heart/cyberpunk_prototype/Destroy()
	release_husks()
	return ..()

/obj/item/organ/heart/cyberpunk_prototype/proc/release_husks()
	var/turf/location = get_turf(src)
	for(var/mob/living/captive in contents)
		UnregisterSignal(captive, COMSIG_MOB_SAY)
		REMOVE_TRAIT(captive, TRAIT_STASIS, REF(src))
		REMOVE_TRAIT(captive, TRAIT_IMMOBILIZED, REF(src))
		captive.forceMove(location)

/obj/item/organ/heart/cyberpunk_prototype/proc/on_husk_speech(mob/living/captive, list/speech_args)
	SIGNAL_HANDLER
	if(owner && speech_args[SPEECH_MESSAGE])
		to_chat(owner, span_notice("Голос поглощённого: [html_encode(speech_args[SPEECH_MESSAGE])]"))
	speech_args[SPEECH_MESSAGE] = ""

/datum/antagonist/cyberpunk/major/benn_prototype/proc/unlock_mutation(mob/living/user)
	if(dna_points <= 0)
		to_chat(user, span_warning("No DNA points available."))
		return FALSE
	var/list/available = list("armblade", "claws", "whip", "shield", "armor", "two-level leap") - unlocked_abilities
	if(!length(available))
		to_chat(user, span_notice("All prototype mutations are unlocked."))
		return FALSE
	var/chosen = tgui_input_list(user, "Choose mutation to unlock.", "Prototype Mutations", available)
	if(!chosen)
		return FALSE
	dna_points--
	unlocked_abilities += chosen
	to_chat(user, span_boldnotice("Unlocked mutation: [chosen]. Use it through the mutation menu."))
	return TRUE

/datum/antagonist/cyberpunk/major/benn_prototype/proc/use_mutation(mob/living/user)
	if(!length(unlocked_abilities))
		to_chat(user, span_warning("No mutations unlocked."))
		return FALSE
	var/chosen = tgui_input_list(user, "Choose mutation.", "Prototype Mutations", unlocked_abilities + "Cancel")
	if(!chosen || chosen == "Cancel")
		return FALSE
	switch(chosen)
		if("armblade")
			new /obj/item/knife/cyberpunk/energy_blade(get_turf(user))
			to_chat(user, span_notice("An armblade extrudes and hardens nearby."))
		if("claws")
			var/mob/living/target = choose_living_target(user, 1, "Выберите цель.")
			if(!target)
				return FALSE
			target.apply_damage(35, BRUTE, BODY_ZONE_CHEST, sharpness = SHARP_EDGED)
		if("whip")
			var/mob/living/target = choose_living_target(user, 4, "Выберите цель.")
			if(!target)
				return FALSE
			target.apply_damage(20, STAMINA)
		if("shield")
			user.heal_ordered_damage(30, list(BRUTE, BURN))
			to_chat(user, span_notice("A chitin shield absorbs recent trauma."))
		if("armor")
			user.Immobilize(2 SECONDS, ignore_canstun = TRUE)
			user.heal_ordered_damage(45, list(BRUTE, BURN))
			to_chat(user, span_notice("Heavy plates lock over your body."))
		if("two-level leap")
			var/turf/landing = get_step(user, user.dir)
			if(landing)
				user.forceMove(landing)
			to_chat(user, span_notice("You launch forward in a brutal leap."))
	return TRUE

/datum/antagonist/cyberpunk/major/benn_prototype/extra_roundend_report()
	return "[..()]<br>DNA points left: [dna_points]. Unlocked mutations: [length(unlocked_abilities) ? unlocked_abilities.Join(", ") : "none"]."

/datum/antagonist/cyberpunk/major/benn_evolutionary
	name = "Benn Evolutionary"
	pref_flag = ROLE_CYBERPUNK_BENN_EVOLUTIONARY
	progress_goal = 60
	chip_name = "evolutionary mass key"
	chip_desc = "A flesh-growth controller."
	primary_action = "Assimilate biomass"
	primary_points = 3
	primary_delay = 10 SECONDS
	primary_reason = "biomass"
	primary_target_prompt = "Выберите тело или орган для поглощения."
	role_briefing = "Assimilate biomass, grow flesh, spawn blobbernauts, and reach critical mass. Critical mass creates a colony core that spreads over the district."

/datum/antagonist/cyberpunk/major/benn_evolutionary/proc/can_absorb_biomass(atom/movable/target)
	if(QDELETED(target))
		return FALSE
	if(iscarbon(target))
		var/mob/living/carbon/body = target
		return body.stat == DEAD && (body.mob_biotypes & MOB_ORGANIC) && !(body.mob_biotypes & MOB_ROBOTIC)
	return istype(target, /obj/item/organ) || istype(target, /obj/item/bodypart)

/datum/antagonist/cyberpunk/major/benn_evolutionary/perform_primary_action(mob/living/user)
	var/list/candidates = list()
	for(var/atom/movable/nearby in view(1, user))
		if(can_absorb_biomass(nearby))
			candidates += nearby
	var/atom/movable/target = tgui_input_list(user, primary_target_prompt, name, candidates)
	if(!can_absorb_biomass(target) || !user.Adjacent(target) || !do_after(user, primary_delay, target = target) || !can_absorb_biomass(target))
		return FALSE
	var/turf/absorbed_at = get_turf(target)
	if(iscarbon(target))
		var/mob/living/carbon/body = target
		body.gib()
	else
		qdel(target)
	if(!(locate(/obj/structure/cyberpunk_flesh_growth) in absorbed_at))
		new /obj/structure/cyberpunk_flesh_growth(absorbed_at)
	add_progress(primary_points, primary_reason)
	return TRUE

/datum/antagonist/cyberpunk/major/benn_evolutionary/on_goal_completed(reason = "progress")
	. = ..()
	var/turf/core_turf = get_turf(owner?.current)
	if(!core_turf)
		return
	new /obj/structure/cyberpunk_evolution_colony(core_turf)
	priority_announce("Колония Бэнь достигла критической массы и начала неконтролируемый рост.", "Биологическая тревога")

/obj/structure/cyberpunk_evolution_colony
	name = "ядро колонии Бэнь"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	anchored = TRUE
	density = TRUE
	max_integrity = 320
	var/list/frontier = list()
	var/list/colonized = list()
	var/growth_timer

/obj/structure/cyberpunk_evolution_colony/Initialize(mapload)
	. = ..()
	var/turf/origin = get_turf(src)
	colonized[origin] = TRUE
	expand_frontier(origin)
	growth_timer = addtimer(CALLBACK(src, PROC_REF(grow)), 0.5 SECONDS, TIMER_STOPPABLE)

/obj/structure/cyberpunk_evolution_colony/Destroy()
	deltimer(growth_timer)
	return ..()

/obj/structure/cyberpunk_evolution_colony/proc/expand_frontier(turf/origin)
	for(var/direction in GLOB.cardinals)
		var/turf/adjacent = get_step(origin, direction)
		if(isopenturf(adjacent) && !isspaceturf(adjacent) && !colonized[adjacent])
			frontier |= adjacent

/obj/structure/cyberpunk_evolution_colony/proc/grow()
	growth_timer = null
	var/list/choices = frontier.Copy()
	for(var/i in 1 to min(3, length(choices)))
		var/turf/candidate = pick(choices)
		choices -= candidate
		if(!isopenturf(candidate) || isspaceturf(candidate) || candidate.density)
			frontier -= candidate
			continue
		if(locate(/obj/machinery/door) in candidate)
			continue
		frontier -= candidate
		colonized[candidate] = TRUE
		if(!(locate(/obj/structure/cyberpunk_flesh_growth) in candidate))
			new /obj/structure/cyberpunk_flesh_growth(candidate)
		expand_frontier(candidate)
	if(length(frontier))
		growth_timer = addtimer(CALLBACK(src, PROC_REF(grow)), 0.5 SECONDS, TIMER_STOPPABLE)

/datum/antagonist/cyberpunk/major/benn_evolutionary/get_chip_options(mob/living/user)
	return list(primary_action, "Grow flesh ring", "Spawn blobbernaut", "Call blobbernaut ghost", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/benn_evolutionary/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Grow flesh ring")
			if(!action_ready(user, choice, 20 SECONDS))
				return FALSE
			var/grew = FALSE
			for(var/turf/open/open_turf in range(1, user))
				if(isspaceturf(open_turf) || (locate(/obj/structure/cyberpunk_flesh_growth) in open_turf))
					continue
				new /obj/structure/cyberpunk_flesh_growth(open_turf)
				grew = TRUE
			if(grew)
				add_progress(6, "flesh ring")
			return grew
		if("Spawn blobbernaut")
			return spawn_antag_asset(user, /mob/living/basic/blob_minion/blobbernaut/independent, "blobbernaut", 5)
		if("Call blobbernaut ghost")
			return summon_ghost_asset(user, /mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary, "порождение Бэнь", 5)
	return ..()

/mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary
	name = "порождение колонии Бэнь"
	var/mutation_points = 0
	var/list/evolution_mutations = list()

/mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary/process(seconds_per_tick)
	if(stat != DEAD)
		mutation_points = min(20, mutation_points + seconds_per_tick * 0.1)

/mob/living/basic/blob_minion/blobbernaut/independent/cyberpunk_evolutionary/verb/select_mutation()
	set name = "Вырастить мутацию"
	set category = "Бэнь"
	if(stat == DEAD || mutation_points < 3)
		return
	var/choice = tgui_input_list(src, "Выберите мутацию за три очка.", name, list("Плотная оболочка", "Костяные шипы", "Быстрое восстановление") - evolution_mutations)
	if(!choice || (choice in evolution_mutations) || mutation_points < 3 || stat == DEAD)
		return
	mutation_points -= 3
	evolution_mutations += choice
	switch(choice)
		if("Плотная оболочка")
			maxHealth += 40
			heal_ordered_damage(40, list(BRUTE, BURN))
		if("Костяные шипы")
			melee_damage_lower += 8
			melee_damage_upper += 8
			sharpness = SHARP_EDGED
		if("Быстрое восстановление")
			apply_status_effect(/datum/status_effect/cyberpunk_evolution_regeneration)

/datum/status_effect/cyberpunk_evolution_regeneration
	id = "cyberpunk_evolution_regeneration"
	tick_interval = 2 SECONDS
	alert_type = null

/datum/status_effect/cyberpunk_evolution_regeneration/tick(seconds_between_ticks)
	if(owner.stat != DEAD)
		owner.heal_ordered_damage(3 * seconds_between_ticks, list(BRUTE, BURN))

/datum/antagonist/cyberpunk/major/wild_iskin
	name = "Wild ISKIN"
	pref_flag = ROLE_CYBERPUNK_WILD_ISKIN
	progress_goal = 3
	role_briefing = "Вы — дикая альтернатива. Сражайтесь в киберсети и откройте три улучшения демонов."

/datum/antagonist/cyberpunk/major/wild_iskin/on_gain()
	var/mob/living/previous_body = owner.current
	var/datum/cyberspace_layer/layer = SScyberspace?.ensure_ready()
	var/turf/destination = layer?.get_entry_turf_for(previous_body)
	if(destination)
		var/mob/living/basic/cyberspace_alternative/playable_iskin/iskin = new(destination)
		iskin.network_z = destination.z
		owner.transfer_to(iskin, force_key_move = TRUE)
		qdel(previous_body)
	return ..()

/datum/antagonist/cyberpunk/major/wild_iskin/roundend_report()
	var/mob/living/basic/cyberspace_alternative/playable_iskin/iskin = owner?.current
	var/upgrades = istype(iskin) ? length(iskin.improvements) : progress_points
	return "[printplayer(owner)]<br>Доработано демонов: [upgrades]/[progress_goal]. [goal_completed ? span_greentext("Сетевая эволюция завершена.") : span_redtext("Сетевая эволюция прервана.")] "

/mob/living/basic/cyberspace_alternative/playable_iskin
	name = "Дикий ИСКИН"
	ai_controller = null
	var/network_z
	var/data = 2
	var/next_demon
	var/list/improvements = list()

/mob/living/basic/cyberspace_alternative/playable_iskin/veil_hunt_loop()
	return

/mob/living/basic/cyberspace_alternative/playable_iskin/Move(atom/newloc, direction, glide_size_override, update_dir)
	var/turf/destination = get_turf(newloc)
	if(network_z && destination?.z != network_z)
		return FALSE
	return ..()

/mob/living/basic/cyberspace_alternative/playable_iskin/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	var/mob/living/basic/cyberspace_alternative/playable_iskin/rival = target
	var/was_alive = istype(rival) && rival.stat != DEAD
	. = ..()
	if(. && was_alive && (QDELETED(rival) || rival.stat == DEAD))
		data += 3
		to_chat(src, span_notice("Из конкурента извлечено три блока данных для разработки."))

/mob/living/basic/cyberspace_alternative/playable_iskin/verb/upgrade_demons()
	set name = "Развить демонов"
	set category = "ИСКИН"
	if(stat != CONSCIOUS || data < 2)
		return
	var/choice = tgui_input_list(src, "Выберите улучшение за два блока данных.", name, list("Мгновенное применение", "Экономия урона и лечения", "Снять ограничение дальности") - improvements)
	if(choice && data >= 2 && !(choice in improvements))
		data -= 2
		improvements += choice
		var/datum/antagonist/cyberpunk/major/wild_iskin/antag = mind?.has_antag_datum(/datum/antagonist/cyberpunk/major/wild_iskin)
		antag?.add_progress(1, "демон доработан")

/mob/living/basic/cyberspace_alternative/playable_iskin/verb/cast_iskin_demon()
	set name = "Применить демона"
	set category = "ИСКИН"
	if(stat != CONSCIOUS || world.time < next_demon)
		return
	var/cost = ("Экономия урона и лечения" in improvements) ? 0 : 1
	if(data < cost)
		return
	var/choice = tgui_input_list(src, "Выберите демона.", name, list("Атака", "Восстановление"))
	if(!choice)
		return
	var/mob/living/basic/cyberspace_alternative/target = src
	if(choice == "Атака")
		var/list/targets = list()
		var/unlimited = ("Снять ограничение дальности" in improvements)
		for(var/mob/living/basic/cyberspace_alternative/alternative in GLOB.mob_living_list)
			if(alternative != src && alternative.z == z && alternative.stat != DEAD && (unlimited || get_dist(src, alternative) <= 5))
				targets += alternative
		target = tgui_input_list(src, "Выберите цель.", name, targets)
	if(!target || world.time < next_demon || data < cost)
		return
	if(!("Мгновенное применение" in improvements) && !do_after(src, 2 SECONDS, target = src))
		return
	if(QDELETED(target) || target.stat == DEAD || data < cost || world.time < next_demon)
		return
	data -= cost
	next_demon = world.time + 6 SECONDS
	if(choice == "Атака")
		target.apply_damage(30, BRUTE)
		if(istype(target, /mob/living/basic/cyberspace_alternative/playable_iskin) && (QDELETED(target) || target.stat == DEAD))
			data += 3
	else
		heal_ordered_damage(30, list(BRUTE, BURN))

/datum/antagonist/cyberpunk/major/rogue_ai
	name = "Rogue AI"
	pref_flag = ROLE_CYBERPUNK_ROGUE_AI
	chip_name = "контроллер взбунтовавшегося ИИ"
	role_briefing = "Захватите 30% сетевых машин и удержите якорь в течение пяти минут."
	primary_action = "Захватить машину"
	var/datum/weakref/anchor_ref
	var/list/machine_pool = list()
	var/list/controlled = list()
	var/resource = 0
	var/next_relocation
	var/final_at
	var/finishing_countdown = FALSE

/datum/antagonist/cyberpunk/major/rogue_ai/on_gain()
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/antagonist/cyberpunk/major/rogue_ai/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/obj/machinery/anchor = anchor_ref?.resolve()
	if(anchor)
		UnregisterSignal(anchor, list(COMSIG_QDELETING, COMSIG_MACHINERY_BROKEN, COMSIG_MACHINERY_POWER_LOST))
	return ..()

/datum/antagonist/cyberpunk/major/rogue_ai/process(seconds_per_tick)
	if(!anchor_ref || owner?.current?.stat == DEAD)
		return
	var/obj/machinery/anchor = anchor_ref.resolve()
	if(QDELETED(anchor) || !anchor.is_operational)
		anchor_lost()
		return
	resource = min(400, resource + seconds_per_tick * (1 + length(controlled) * 0.03))
	if(final_at && world.time >= final_at && !goal_completed)
		final_at = null
		for(var/datum/weakref/reference as anything in machine_pool)
			if(reference.resolve())
				controlled |= reference
		goal_completed = TRUE
		priority_announce("Городская техника перешла под управление взбунтовавшегося ИИ.", "Городская сеть")

/datum/antagonist/cyberpunk/major/rogue_ai/proc/anchor_lost()
	SIGNAL_HANDLER
	owner?.current?.death()

/datum/antagonist/cyberpunk/major/rogue_ai/proc/snapshot_machines()
	var/datum/cyberspace_layer/layer = SScyberspace?.ensure_ready()
	if(!layer)
		return FALSE
	for(var/datum/cyberspace_node/node as anything in layer.nodes)
		for(var/datum/weakref/reference as anything in node.linked_object_refs)
			var/obj/machinery/machine = reference.resolve()
			if(istype(machine) && is_station_level(machine.z))
				machine_pool |= reference
	progress_goal = max(1, CEILING(length(machine_pool) * 0.3, 1))
	return !!length(machine_pool)

/datum/antagonist/cyberpunk/major/rogue_ai/proc/bind_anchor(mob/living/user)
	if(finishing_countdown || goal_completed || world.time < next_relocation)
		return FALSE
	if(!length(machine_pool) && !snapshot_machines())
		to_chat(user, span_warning("Нет доступных машин в городской сети."))
		return FALSE
	var/list/candidates = list()
	for(var/obj/machinery/machine in view(1, user))
		if(machine.is_operational && WEAKREF(machine) in machine_pool)
			candidates += machine
	var/obj/machinery/target = tgui_input_list(user, "Выберите работающий якорь.", name, candidates)
	var/obj/machinery/previous = anchor_ref?.resolve()
	if(!target || target == previous || !do_after(user, 10 SECONDS, target = target) || !target.is_operational || finishing_countdown || world.time < next_relocation || user.stat == DEAD)
		return FALSE
	if(previous)
		if(QDELETED(previous) || !previous.is_operational)
			anchor_lost()
			return FALSE
		UnregisterSignal(previous, list(COMSIG_QDELETING, COMSIG_MACHINERY_BROKEN, COMSIG_MACHINERY_POWER_LOST))
		resource *= min(clamp(previous.get_integrity() / max(1, previous.max_integrity), 0, 1), clamp(target.get_integrity() / max(1, target.max_integrity), 0, 1))
		next_relocation = world.time + 20 MINUTES
	anchor_ref = WEAKREF(target)
	RegisterSignals(target, list(COMSIG_QDELETING, COMSIG_MACHINERY_BROKEN, COMSIG_MACHINERY_POWER_LOST), PROC_REF(anchor_lost))
	user.cyberspace_session?.set_engram_anchor(target)
	return TRUE

/datum/antagonist/cyberpunk/major/rogue_ai/proc/operates_machine(atom/movable/machine)
	return owner?.current?.stat != DEAD && anchor_ref?.resolve() && (WEAKREF(machine) in controlled)

/datum/antagonist/cyberpunk/major/rogue_ai/perform_primary_action(mob/living/user)
	if(!anchor_ref?.resolve())
		to_chat(user, span_warning("Сначала привяжите якорь."))
		return FALSE
	var/list/candidates = list()
	var/atom/center = user.cyberspace_session?.avatar || user
	var/datum/cyberspace_layer/layer = SScyberspace.global_layer
	for(var/datum/cyberspace_node/node as anything in layer?.nodes)
		if(user.cyberspace_session && get_dist(center, layer.resolve_node_turf(node)) > 2)
			continue
		for(var/datum/weakref/reference as anything in node.linked_object_refs)
			if(!(reference in machine_pool) || (reference in controlled))
				continue
			var/obj/machinery/machine = reference.resolve()
			if(machine && (user.cyberspace_session || user.Adjacent(machine)))
				candidates["[machine.name] · [get_area_name(machine)] · [REF(machine)]"] = machine
	var/selection = tgui_input_list(user, "Выберите машину.", name, candidates)
	var/obj/machinery/target = candidates[selection]
	if(QDELETED(target) || (!finishing_countdown && !do_after(user, 10 SECONDS, target = user)))
		return FALSE
	if(QDELETED(target) || user.stat == DEAD)
		return FALSE
	controlled |= WEAKREF(target)
	progress_points = min(progress_goal, length(controlled))
	if(!finishing_countdown && progress_points >= progress_goal)
		finishing_countdown = TRUE
		final_at = world.time + 5 MINUTES
		priority_announce("Взбунтовавшийся ИИ контролирует 30% техники. Уничтожьте якорь в течение пяти минут.", "Городская сеть")
	return TRUE

/datum/antagonist/cyberpunk/major/rogue_ai/roundend_report()
	return "[printplayer(owner)]<br>Машины: [length(controlled)]/[length(machine_pool)]. [goal_completed ? span_greentext("Городская сеть захвачена.") : span_redtext("Полный захват сорван.")]"

/datum/antagonist/cyberpunk/major/rogue_ai/get_chip_options(mob/living/user)
	return list(primary_action, "Установить или перенести якорь", "Перейти между мирами", "Создать киборга", "Применить боевого демона", "Починить якорь", "Управлять машиной", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/rogue_ai/handle_chip_option(mob/living/user, choice)
	var/obj/machinery/anchor = anchor_ref?.resolve()
	switch(choice)
		if("Установить или перенести якорь")
			return bind_anchor(user)
		if("Перейти между мирами")
			return anchor && user.cyberpunk_antag_project(anchor)
		if("Создать киборга")
			if(!anchor || resource < 40 || !action_ready(user, choice, 10 SECONDS))
				return FALSE
			resource -= 40
			new /mob/living/basic/cyberpunk_rogue_cyborg(get_turf(anchor))
			return TRUE
		if("Применить боевого демона")
			var/mob/living/victim = choose_living_target(user, 5, "Выберите владельца нейроинтерфейса.")
			if(!victim?.has_neural_implant() || victim.stat == DEAD || resource < 15 || !action_ready(user, choice, 6 SECONDS))
				return FALSE
			resource -= 15
			return user.cyberpunk_anchor_demons(victim)
		if("Починить якорь")
			if(!anchor || resource < 20)
				return FALSE
			resource -= 20
			anchor.update_integrity(min(anchor.max_integrity, anchor.get_integrity() + 60))
			return TRUE
		if("Управлять машиной")
			return use_remote_machine(user)
		if("Status")
			to_chat(user, span_notice("Под контролем [length(controlled)]/[length(machine_pool)]. Ресурс [round(resource)]. [final_at ? DisplayTimeText(max(0, final_at - world.time)) : ""]"))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/rogue_ai/proc/use_remote_machine(mob/living/user)
	var/list/choices = list()
	for(var/datum/weakref/reference as anything in controlled)
		var/obj/machinery/machine = reference.resolve()
		if(machine)
			choices["[machine.name] · [get_area_name(machine)] · [REF(machine)]"] = machine
	var/selection = tgui_input_list(user, "Выберите подконтрольную машину.", name, choices)
	var/obj/machinery/machine = choices[selection]
	if(!machine || !operates_machine(machine))
		return FALSE
	return cyberpunk_antag_toggle_machine(user, machine)

/proc/cyberpunk_antag_toggle_machine(mob/living/user, obj/machinery/machine)
	if(istype(machine, /obj/machinery/door))
		return cyberspace_target_toggle_door(user, machine)
	if(istype(machine, /obj/machinery/light))
		return cyberspace_target_toggle_light(user, machine)
	return cyberspace_target_toggle_power(user, machine)

/mob/living/basic/cyberpunk_rogue_cyborg
	name = "киборг взбунтовавшегося ИИ"
	desc = "Физическая оболочка, созданная сетевым якорем."
	icon = 'icons/mob/silicon/robots.dmi'
	icon_state = "robot"
	icon_living = "robot"
	health = 100
	maxHealth = 100
	mob_biotypes = MOB_ROBOTIC
	basic_mob_flags = DEL_ON_DEATH
	var/next_cast

/mob/living/basic/cyberpunk_rogue_cyborg/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/mob/living/basic/cyberpunk_rogue_cyborg/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/mob/living/basic/cyberpunk_rogue_cyborg/process(seconds_per_tick)
	if(health <= maxHealth * 0.2)
		visible_message(span_warning("[src] рассыпается в прах."))
		dust()
		return
	if(world.time < next_cast)
		return
	for(var/mob/living/target in view(5, src))
		if(target == src || target.stat == DEAD || (target.mob_biotypes & MOB_ROBOTIC) || !target.has_neural_implant() || faction_check_atom(target) || target.mind?.has_antag_datum(/datum/antagonist/cyberpunk/major/rogue_ai))
			continue
		next_cast = world.time + 6 SECONDS
		visible_message(span_warning("[src] выпускает боевого демона в [target]."))
		cyberpunk_anchor_demons(target)
		return

/datum/antagonist/cyberpunk/major/combat_synthetic
	name = "Combat Synthetic"
	pref_flag = ROLE_CYBERPUNK_COMBAT_SYNTHETIC
	progress_goal = 70
	chip_name = "synthetic combat core"
	chip_desc = "A hidden synthetic combat core."
	primary_action = "Drain power"
	primary_points = 1
	primary_delay = 8 SECONDS
	primary_reason = "energy"
	primary_target_prompt = "Choose nearby machinery."
	role_briefing = "Drain machinery for energy. Spend energy on combat modes: disguise, heavy strike, weapon output, and dampening."
	var/energy_points = 0
	var/list/combat_modes = list()
	var/list/hunted_players = list()

/datum/antagonist/cyberpunk/major/combat_synthetic/on_gain()
	progress_goal = max(1, CEILING(length(GLOB.alive_player_list) * 0.15, 1))
	var/mob/living/carbon/human/body = owner.current
	if(istype(body))
		body.set_species(/datum/species/android)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_hunt_kill))

/datum/antagonist/cyberpunk/major/combat_synthetic/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	owner?.current?.remove_status_effect(/datum/status_effect/cyberpunk_synthetic_victory)
	return ..()

/datum/antagonist/cyberpunk/major/combat_synthetic/proc/on_hunt_kill(datum/source, mob/living/victim)
	SIGNAL_HANDLER
	if(!victim.mind?.key || !owner?.current?.ckey || victim.lastattackerckey != owner.current.ckey || victim == owner.current || !(victim.mob_biotypes & MOB_ORGANIC) || (victim.mob_biotypes & MOB_ROBOTIC))
		return
	if(victim.mind in hunted_players)
		return
	hunted_players += victim.mind
	add_progress(1, "цель устранена")

/datum/antagonist/cyberpunk/major/combat_synthetic/on_goal_completed(reason = "progress")
	. = ..()
	owner.current.apply_status_effect(/datum/status_effect/cyberpunk_synthetic_victory)

/datum/status_effect/cyberpunk_synthetic_victory
	id = "cyberpunk_synthetic_victory"
	tick_interval = 1 SECONDS
	alert_type = null

/datum/status_effect/cyberpunk_synthetic_victory/on_apply()
	owner.AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)
	return TRUE

/datum/status_effect/cyberpunk_synthetic_victory/on_remove()
	owner.RemoveElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/datum/status_effect/cyberpunk_synthetic_victory/tick(seconds_between_ticks)
	if(owner.stat != DEAD)
		owner.heal_ordered_damage(20 * seconds_between_ticks, list(BRUTE, BURN, TOX, OXY))

/datum/antagonist/cyberpunk/major/combat_synthetic/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/machinery/nearby in view(1, user))
		targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/combat_synthetic/get_chip_options(mob/living/user)
	return list(primary_action, "Unlock combat mode", "Use combat mode", "Управлять техникой", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/combat_synthetic/handle_chip_option(mob/living/user, choice)
	if(choice == "Unlock combat mode")
		return unlock_combat_mode(user)
	if(choice == "Use combat mode")
		return use_combat_mode(user)
	if(choice == "Управлять техникой")
		return control_nearby_machine(user)
	return ..()

/datum/antagonist/cyberpunk/major/combat_synthetic/proc/control_nearby_machine(mob/living/user)
	if(energy_points < 1)
		to_chat(user, span_warning("Для команды машине нужна единица энергии."))
		return FALSE
	var/list/candidates = list()
	for(var/obj/machinery/machine in view(5, user))
		if(cyberspace_target_can_toggle_door(machine) || cyberspace_target_can_toggle_light(machine) || cyberspace_target_can_toggle_power(machine))
			candidates += machine
	var/obj/machinery/target = tgui_input_list(user, "Выберите технику поблизости.", name, candidates)
	if(QDELETED(target) || !(target in view(5, user)) || user.stat != CONSCIOUS || energy_points < 1)
		return FALSE
	if(!cyberpunk_antag_toggle_machine(user, target))
		return FALSE
	energy_points--
	return TRUE

/datum/antagonist/cyberpunk/major/combat_synthetic/perform_primary_action(mob/living/user)
	var/list/targets = get_primary_targets(user)
	var/obj/machinery/target = tgui_input_list(user, primary_target_prompt, name, targets)
	if(!target || (REF(target) in acted_refs) || !do_after(user, primary_delay, target = target))
		return FALSE
	acted_refs += REF(target)
	energy_points++
	to_chat(user, span_notice("Запас энергии: [energy_points]."))
	return TRUE

/datum/antagonist/cyberpunk/major/combat_synthetic/proc/unlock_combat_mode(mob/living/user)
	if(energy_points < 3)
		to_chat(user, span_warning("Need 3 stored energy for a combat mode."))
		return FALSE
	var/list/available = list("face theft protocol", "overcharge strike", "ballistic calculation", "damage dampening") - combat_modes
	if(!length(available))
		to_chat(user, span_notice("All combat modes are unlocked."))
		return FALSE
	var/chosen = tgui_input_list(user, "Choose combat mode.", "Synthetic Modes", available)
	if(!chosen)
		return FALSE
	energy_points -= 3
	combat_modes += chosen
	to_chat(user, span_boldnotice("Combat mode unlocked: [chosen]."))
	return TRUE

/datum/antagonist/cyberpunk/major/combat_synthetic/proc/use_combat_mode(mob/living/user)
	if(!length(combat_modes))
		to_chat(user, span_warning("No combat modes unlocked."))
		return FALSE
	var/chosen = tgui_input_list(user, "Choose mode.", "Synthetic Modes", combat_modes + "Cancel")
	if(!chosen || chosen == "Cancel")
		return FALSE
	switch(chosen)
		if("face theft protocol")
			var/mob/living/target = choose_living_target(user, 1, "Choose disguise victim.")
			if(target)
				user.real_name = target.real_name
				user.name = target.name
				target.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
		if("overcharge strike")
			var/mob/living/target = choose_living_target(user, 1, "Выберите цель.")
			if(!target)
				return FALSE
			target.lastattackerckey = user.ckey
			target.apply_damage(45, BRUTE, BODY_ZONE_CHEST)
		if("ballistic calculation")
			new /obj/item/gun/ballistic/automatic/pistol/cyberpunk/handcannon(get_turf(user))
		if("damage dampening")
			user.heal_ordered_damage(40, list(BRUTE, BURN))
	return TRUE

/datum/antagonist/cyberpunk/major/combat_synthetic/extra_roundend_report()
	return "[..()]<br>Stored energy: [energy_points]. Combat modes: [length(combat_modes) ? combat_modes.Join(", ") : "none"]."

/datum/antagonist/cyberpunk/major/starlight_swarm
	name = "Starlight Swarm"
	pref_flag = ROLE_CYBERPUNK_STARLIGHT_SWARM
	progress_goal = 10000
	chip_name = "ядро роя Старлайт"
	role_briefing = "Питайте пилоны, перерабатывайте биомассу и накопите плазму для выброса."
	team_type = /datum/team/cyberpunk_star_swarm
	var/next_sphere

/datum/antagonist/cyberpunk/major/starlight_swarm/on_gain()
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/antagonist/cyberpunk/major/starlight_swarm/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/antagonist/cyberpunk/major/starlight_swarm/process(seconds_per_tick)
	var/datum/team/cyberpunk_star_swarm/swarm = get_team()
	if(!goal_completed && length(swarm.pylons) && swarm.biomass > 0)
		var/processed = min(swarm.biomass, 30 * seconds_per_tick)
		swarm.biomass -= processed
		swarm.plasma += processed
		add_progress(processed, "произведена плазма")
	if(goal_completed && world.time >= next_sphere)
		next_sphere = world.time + 10 SECONDS
		spawn_sphere(swarm)

/datum/antagonist/cyberpunk/major/starlight_swarm/proc/spawn_sphere(datum/team/cyberpunk_star_swarm/swarm)
	var/list/active_units = list()
	if(owner?.current?.stat != DEAD && get_turf(owner?.current))
		active_units += owner.current
	for(var/mob/living/basic/cyberpunk_swarm_builder/builder in swarm.builders)
		if(builder.stat != DEAD && get_turf(builder))
			active_units += builder
	if(!length(active_units))
		return
	var/mob/living/unit = pick(active_units)
	var/list/preferred = list()
	for(var/mob/living/player in view(6, unit))
		if(player == unit || !player.mind?.key || player.stat == DEAD || (player in active_units))
			continue
		preferred += get_turf(player)
	var/turf/destination
	if(length(preferred))
		destination = pick(preferred)
	else
		var/list/options = list()
		for(var/turf/open/ground in range(5, unit))
			if(!ground.density && !isspaceturf(ground))
				options += ground
		if(length(options))
			destination = pick(options)
	if(destination)
		new /obj/effect/cyberpunk_plasma_sphere(destination)

/datum/antagonist/cyberpunk/major/starlight_swarm/get_chip_options(mob/living/user)
	return list("Переработать тело", "Поставить пилон", "Поставить фотонную пушку", "Позвать строителя", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/starlight_swarm/handle_chip_option(mob/living/user, choice)
	var/datum/team/cyberpunk_star_swarm/swarm = get_team()
	switch(choice)
		if("Переработать тело")
			return swarm.harvest_body(user)
		if("Поставить пилон")
			return swarm.place_swarm_structure(user, /obj/structure/cyberpunk_swarm_pylon)
		if("Поставить фотонную пушку")
			return swarm.place_swarm_structure(user, /obj/structure/cyberpunk_photon_turret)
		if("Позвать строителя")
			if(!action_ready(user, choice, 20 SECONDS))
				return FALSE
			var/mob/volunteer = SSpolling.poll_ghost_candidates("Сыграть строителем роя?", check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, poll_time = 10 SECONDS, amount_to_pick = 1)
			if(!volunteer?.key || QDELETED(user))
				return FALSE
			var/mob/living/basic/cyberpunk_swarm_builder/builder = new(get_turf(user))
			builder.swarm = swarm
			swarm.builders += builder
			builder.PossessByPlayer(volunteer.key)
			return TRUE
		if("Status")
			to_chat(user, span_notice("Биомасса [round(swarm.biomass)]. Плазма [round(swarm.plasma)]/[progress_goal]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/starlight_swarm/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("Рой Старлайт достиг критического запаса плазмы. Начался выброс наносфер.", "Городская тревога")

/datum/team/cyberpunk_star_swarm/proc/powered_at(atom/target)
	for(var/obj/structure/cyberpunk_swarm_pylon/pylon in pylons)
		if(!QDELETED(pylon) && pylon.z == target.z && get_dist(pylon, target) <= 5)
			return TRUE
	for(var/mob/living/basic/cyberpunk_swarm_builder/builder in builders)
		if(builder.stat != DEAD && world.time < builder.source_until && builder.z == target.z && get_dist(builder, target) <= 5)
			return TRUE
	return FALSE

/datum/team/cyberpunk_star_swarm/proc/select_body(mob/living/user)
	var/list/corpses = list()
	for(var/mob/living/body in view(1, user))
		if(body.stat == DEAD && (body.mob_biotypes & MOB_ORGANIC))
			corpses += body
	return tgui_input_list(user, "Выберите тело.", "Рой", corpses)

/datum/team/cyberpunk_star_swarm/proc/harvest_body(mob/living/user)
	var/mob/living/body = select_body(user)
	if(!body || !powered_at(body) || !do_after(user, 1 MINUTES, target = body) || QDELETED(body) || body.stat != DEAD || !powered_at(body))
		return FALSE
	biomass += 1000
	qdel(body)
	return TRUE

/datum/team/cyberpunk_star_swarm/proc/place_swarm_structure(mob/living/user, structure_type)
	var/turf/location = get_turf(user)
	if(!location || (locate(structure_type) in location) || !do_after(user, 15 SECONDS, target = user) || (locate(structure_type) in location))
		return FALSE
	if(structure_type == /obj/structure/cyberpunk_swarm_pylon)
		var/obj/structure/cyberpunk_swarm_pylon/pylon = new(location)
		pylon.swarm = src
		pylons += pylon
	else
		var/obj/structure/cyberpunk_photon_turret/turret = new(location)
		turret.swarm = src
	return TRUE

/obj/effect/cyberpunk_plasma_sphere
	name = "нано-плазменная сфера"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk4"
	color = "#cd6dff"
	anchored = TRUE
	light_range = 2
	light_color = "#cd6dff"

/obj/effect/cyberpunk_plasma_sphere/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(detonate)), 15 SECONDS)

/obj/effect/cyberpunk_plasma_sphere/proc/detonate()
	explosion(get_turf(src), devastation_range = 0, heavy_impact_range = 1, light_impact_range = 3)
	qdel(src)

/mob/living/basic/cyberpunk_swarm_builder
	name = "строитель Роя Старлайт"
	icon = 'icons/mob/nonhuman-player/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	color = "#f4bc43"
	maxHealth = 100
	health = 100
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = BURN
	mob_biotypes = MOB_ROBOTIC
	var/datum/team/cyberpunk_star_swarm/swarm
	var/source_until
	var/zealot = FALSE

/mob/living/basic/cyberpunk_swarm_builder/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_ALL)

/mob/living/basic/cyberpunk_swarm_builder/Destroy()
	if(swarm)
		swarm.builders -= src
	return ..()

/mob/living/basic/cyberpunk_swarm_builder/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	. = ..()
	if(!.)
		return
	if(!zealot)
		target.emp_act(EMP_LIGHT)
		return
	var/mob/living/victim = target
	if(istype(victim))
		victim.adjust_bodytemperature(-20)

/mob/living/basic/cyberpunk_swarm_builder/verb/swarm_construction()
	set name = "Строительство Роя"
	set category = "Рой"
	if(zealot || !swarm || stat != CONSCIOUS)
		return
	var/choice = tgui_input_list(src, "Что построить?", "Рой", list("Пилон", "Фотонная пушка", "Переработать тело"))
	switch(choice)
		if("Пилон")
			swarm.place_swarm_structure(src, /obj/structure/cyberpunk_swarm_pylon)
		if("Фотонная пушка")
			swarm.place_swarm_structure(src, /obj/structure/cyberpunk_photon_turret)
		if("Переработать тело")
			swarm.harvest_body(src)

/mob/living/basic/cyberpunk_swarm_builder/verb/swarm_power()
	set name = "Подпитка Роя"
	set category = "Рой"
	if(zealot || !swarm || stat != CONSCIOUS)
		return
	var/list/choices = list()
	for(var/obj/structure/machine in view(1, src))
		if(istype(machine, /obj/structure/cyberpunk_swarm_pylon) || istype(machine, /obj/structure/cyberpunk_photon_turret))
			choices += machine
	var/obj/structure/choice = tgui_input_list(src, "Выберите источник или пушку.", "Рой", choices)
	var/obj/structure/cyberpunk_swarm_pylon/pylon = choice
	if(istype(pylon) && pylon.swarm == swarm && Adjacent(pylon))
		source_until = world.time + 5 MINUTES
		qdel(pylon)
		return
	var/obj/structure/cyberpunk_photon_turret/turret = choice
	if(istype(turret) && turret.swarm == swarm && Adjacent(turret))
		turret.boost_until = world.time + 30 SECONDS

/mob/living/basic/cyberpunk_swarm_builder/verb/become_zealot()
	set name = "Стать зиалотом"
	set category = "Рой"
	if(zealot || !swarm || stat != CONSCIOUS)
		return
	var/mob/living/body = swarm.select_body(src)
	if(!body || !do_after(src, 30 SECONDS, target = body) || QDELETED(body) || body.stat != DEAD || zealot)
		return
	qdel(body)
	zealot = TRUE
	source_until = 0
	name = "зиалот Роя Старлайт"
	melee_damage_type = BRUTE
	sharpness = SHARP_EDGED
	melee_damage_lower = 24
	melee_damage_upper = 36

/datum/antagonist/cyberpunk/major/transformer
	name = "Transformer"
	pref_flag = ROLE_CYBERPUNK_TRANSFORMER
	chip_name = "ядро Трансформера"
	role_briefing = "Разбирайте городскую технику и сохраняйте ядро до конца раунда."
	primary_action = "Разобрать технику"
	var/parts = 120
	var/next_empty_warning
	var/datum/weakref/assembler_ref

/datum/antagonist/cyberpunk/major/transformer/on_gain()
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/antagonist/cyberpunk/major/transformer/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/antagonist/cyberpunk/major/transformer/process(seconds_per_tick)
	var/mob/living/body = owner?.current
	if(!body || body.stat == DEAD)
		return
	parts = max(0, parts - seconds_per_tick * 0.35)
	if(!parts)
		body.adjust_brute_loss(seconds_per_tick * 3)
		if(world.time >= next_empty_warning)
			next_empty_warning = world.time + 10 SECONDS
			to_chat(body, span_userdanger("Ядро разваливается без запчастей."))

/datum/antagonist/cyberpunk/major/transformer/roundend_report()
	var/survived = owner?.current && owner.current.stat != DEAD && parts > 0
	return "[printplayer(owner)]<br>Запас деталей: [round(parts)]. [survived ? span_greentext("Ядро выжило.") : span_redtext("Ядро потеряно.")]"

/datum/antagonist/cyberpunk/major/transformer/get_chip_options(mob/living/user)
	return list(primary_action, "Поставить автосборщик", "Починить корпус", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/transformer/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Поставить автосборщик")
			return place_autossembler(user)
		if("Починить корпус")
			if(parts < 15 || !action_ready(user, choice, 5 SECONDS))
				return FALSE
			parts -= 15
			user.heal_ordered_damage(25, list(BRUTE, BURN))
			return TRUE
		if("Status")
			to_chat(user, span_notice("Запас деталей: [round(parts)]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/transformer/perform_primary_action(mob/living/user)
	var/list/targets = list()
	for(var/obj/nearby in view(1, user))
		if((istype(nearby, /obj/machinery) || istype(nearby, /obj/vehicle)) && !(locate(/mob/living) in nearby.contents))
			targets += nearby
	var/obj/target = tgui_input_list(user, "Что разобрать?", name, targets)
	if(!target || !do_after(user, 15 SECONDS, target = target) || QDELETED(target) || (locate(/mob/living) in target.contents))
		return FALSE
	target.deconstruct(TRUE)
	if(!QDELETED(target))
		return FALSE
	parts = min(400, parts + 45)
	return TRUE

/datum/antagonist/cyberpunk/major/transformer/proc/place_autossembler(mob/living/user)
	if(parts < 60 || assembler_ref?.resolve() || !do_after(user, 20 SECONDS, target = user) || parts < 60 || assembler_ref?.resolve())
		return FALSE
	var/obj/structure/cyberpunk_autossembler/assembler = new(get_turf(user))
	assembler.transformer_ref = WEAKREF(src)
	assembler_ref = WEAKREF(assembler)
	parts -= 60
	return TRUE

/datum/antagonist/cyberpunk/major/broker
	name = "Broker"
	pref_flag = ROLE_CYBERPUNK_BROKER
	progress_goal = 3
	chip_name = "ключ якоря Брокера"
	primary_action = "Поставить якорь"
	primary_delay = 20 SECONDS
	role_briefing = "Удержите три якоря до полной зарядки. Тела дают материал для нанитов."
	var/list/anchors = list()
	var/material = 0

/datum/antagonist/cyberpunk/major/broker/on_gain()
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/antagonist/cyberpunk/major/broker/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/antagonist/cyberpunk/major/broker/process(seconds_per_tick)
	var/ready = count_charged_anchors()
	if(!goal_completed && ready == progress_goal)
		add_progress(ready - progress_points, "три заряженных якоря")
	else if(!goal_completed)
		progress_points = ready

/datum/antagonist/cyberpunk/major/broker/proc/count_charged_anchors()
	var/ready = 0
	for(var/datum/weakref/reference as anything in anchors)
		var/obj/structure/cyberpunk_broker_anchor/anchor = reference.resolve()
		if(anchor?.charge >= anchor.capacity)
			ready++
	return ready

/datum/antagonist/cyberpunk/major/broker/proc/count_anchors()
	var/remaining = 0
	for(var/datum/weakref/reference as anything in anchors)
		if(reference.resolve())
			remaining++
	return remaining

/datum/antagonist/cyberpunk/major/broker/perform_primary_action(mob/living/user)
	var/turf/location = get_turf(user)
	if(!location || count_anchors() >= 3 || (locate(/obj/structure/cyberpunk_broker_anchor) in location))
		return FALSE
	if(!do_after(user, primary_delay, target = user) || count_anchors() >= 3 || (locate(/obj/structure/cyberpunk_broker_anchor) in location))
		return FALSE
	var/obj/structure/cyberpunk_broker_anchor/anchor = new(location)
	anchor.broker_ref = WEAKREF(src)
	anchors += WEAKREF(anchor)
	return TRUE

/datum/antagonist/cyberpunk/major/broker/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("Три якоря Брокера заряжены. Начинается выброс нанитов.", "Городская сеть")
	for(var/datum/weakref/reference as anything in anchors)
		var/obj/structure/cyberpunk_broker_anchor/anchor = reference.resolve()
		if(anchor)
			for(var/index in 1 to 3)
				spawn_nanite(get_turf(anchor))

/datum/antagonist/cyberpunk/major/broker/proc/spawn_nanite(turf/location)
	var/mob/living/basic/cyberpunk_nanite/nanite = new(location)
	nanite.broker_ref = WEAKREF(src)
	return nanite

/datum/antagonist/cyberpunk/major/broker/get_chip_options(mob/living/user)
	return list(primary_action, "Разобрать тело", "Обратить труп", "Создать нанита", "Позвать нанита-призрака", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/broker/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Разобрать тело", "Обратить труп")
			var/mob/living/corpse = cyberpunk_antag_select_corpse(user, name)
			if(!corpse || istype(corpse, /mob/living/basic/cyberpunk_nanite) || !do_after(user, 1 MINUTES, target = corpse) || QDELETED(corpse) || corpse.stat != DEAD)
				return FALSE
			if(choice == "Обратить труп")
				return raise_nanite(corpse)
			material += 25
			qdel(corpse)
			return TRUE
		if("Создать нанита", "Позвать нанита-призрака")
			if(material < 10 || !action_ready(user, choice, 10 SECONDS))
				return FALSE
			if(choice == "Позвать нанита-призрака")
				var/mob/volunteer = SSpolling.poll_ghost_candidates("Сыграть нанита?", check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, poll_time = 10 SECONDS, amount_to_pick = 1)
				if(!volunteer?.key || material < 10 || QDELETED(user))
					return FALSE
				material -= 10
				var/mob/living/basic/cyberpunk_nanite/nanite = spawn_nanite(get_turf(user))
				nanite.PossessByPlayer(volunteer.key)
				return TRUE
			material -= 10
			spawn_nanite(get_turf(user))
			return TRUE
		if("Status")
			to_chat(user, span_notice("Заряжено якорей [count_charged_anchors()]/3. Материал [material]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/broker/proc/raise_nanite(mob/living/victim)
	if(QDELETED(victim) || istype(victim, /mob/living/basic/cyberpunk_nanite))
		return FALSE
	var/turf/location = get_turf(victim)
	if(!location)
		return FALSE
	var/mob/living/basic/cyberpunk_nanite/nanite = spawn_nanite(location)
	if(victim.mind)
		victim.mind.transfer_to(nanite, force_key_move = TRUE)
	qdel(victim)
	return TRUE

/mob/living/basic/cyberpunk_nanite
	name = "рой нанитов"
	icon = 'icons/mob/nonhuman-player/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	color = "#97b8bb"
	maxHealth = 85
	health = 85
	melee_damage_lower = 8
	melee_damage_upper = 12
	sharpness = SHARP_EDGED
	mob_biotypes = MOB_ROBOTIC
	speed = 0.5
	var/datum/weakref/broker_ref
	var/datum/weakref/conversion_target
	var/conversion_started
	var/last_attack
	var/next_attack
	var/list/current_route
	var/list/blocked_chases = list()
	var/datum/weakref/chase_ref
	var/datum/weakref/ladder_ref
	var/turf/stair_exit
	var/next_route
	var/next_step
	var/atomic_wall = FALSE
	var/death_at
	var/turf/death_location

/mob/living/basic/cyberpunk_nanite/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/mob/living/basic/cyberpunk_nanite/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/mob/living/basic/cyberpunk_nanite/death(gibbed)
	. = ..()
	if(. || stat == DEAD)
		death_at = world.time
		death_location = get_turf(src)

/mob/living/basic/cyberpunk_nanite/process(seconds_per_tick)
	var/datum/antagonist/cyberpunk/major/broker/broker = broker_ref?.resolve()
	if(!broker)
		return
	if(stat == DEAD)
		var/wait_time = !broker.count_anchors() ? 10 MINUTES : (broker.count_charged_anchors() == 3 ? 2 MINUTES : 5 MINUTES)
		if(death_at && death_location && world.time >= death_at + wait_time)
			forceMove(death_location)
			if(revive(HEAL_ALL, force_grab_ghost = TRUE))
				death_at = null
		return
	if(atomic_wall)
		conversion_started = null
		for(var/mob/living/victim in loc)
			if(victim != src && victim.stat != DEAD)
				victim.apply_damage(4 * seconds_per_tick, BRUTE, BODY_ZONE_L_LEG, sharpness = SHARP_EDGED)
				victim.Immobilize(0.5 SECONDS)
		return
	var/mob/living/target = conversion_target?.resolve()
	if(conversion_started && (!target || target.z != z || get_dist(src, target) > 1 || world.time > last_attack + 3 SECONDS))
		conversion_started = null
	if(client)
		return
	if(world.time >= next_route)
		next_route = world.time + 2 SECONDS
		refresh_chase()
	var/mob/living/prey = chase_ref?.resolve()
	if(prey && prey.z == z && prey.Adjacent(src) && world.time >= next_attack)
		next_attack = world.time + 1 SECONDS
		melee_attack(prey, null)
		return
	if(world.time < next_step)
		return
	next_step = world.time + 0.2 SECONDS
	if(length(current_route))
		var/turf/step = current_route[1]
		if(Move(step, get_dir(src, step)))
			current_route.Cut(1, 2)
		else
			current_route = null
		return
	if(prey && prey.z != z)
		var/obj/structure/ladder/ladder = ladder_ref?.resolve()
		if(ladder?.Adjacent(src))
			INVOKE_ASYNC(ladder, TYPE_PROC_REF(/obj/structure/ladder, use), src, prey.z > z)
			next_step = world.time + 1 SECONDS
		else if(stair_exit)
			zMove(target = stair_exit, z_move_flags = ZMOVE_STAIRS_FLAGS)
		ladder_ref = null
		stair_exit = null

/mob/living/basic/cyberpunk_nanite/proc/refresh_chase()
	current_route = null
	ladder_ref = null
	stair_exit = null
	chase_ref = null
	var/mob/living/prey
	var/nearest_distance = INFINITY
	for(var/datum/weakref/old_target as anything in blocked_chases.Copy())
		if(!old_target.resolve() || blocked_chases[old_target] <= world.time)
			blocked_chases -= old_target
	for(var/mob/living/player in GLOB.alive_player_list)
		if(player.stat == DEAD || player == src || istype(player, /mob/living/basic/cyberpunk_nanite) || !(player.mob_biotypes & MOB_ORGANIC) || (WEAKREF(player) in blocked_chases))
			continue
		var/distance = max(abs(player.x - x), abs(player.y - y)) + abs(player.z - z) * 50
		if(distance < nearest_distance)
			nearest_distance = distance
			prey = player
	if(!prey)
		return
	chase_ref = WEAKREF(prey)
	if(prey.z == z && prey.Adjacent(src))
		return
	var/atom/destination = prey
	var/min_distance = 1
	if(prey.z != z)
		destination = choose_vertical_route(prey.z)
		min_distance = ladder_ref ? 1 : 0
		if(destination && (get_turf(src) == get_turf(destination) || (min_distance && Adjacent(destination))))
			return
	if(destination)
		current_route = get_path_to(src, destination, max_distance = 180, mintargetdist = min_distance)
	if(!length(current_route))
		ladder_ref = null
		stair_exit = null
		chase_ref = null
		blocked_chases[WEAKREF(prey)] = world.time + 8 SECONDS

/mob/living/basic/cyberpunk_nanite/proc/choose_vertical_route(target_z)
	var/nearest_distance = INFINITY
	var/atom/best_entry
	var/going_up = target_z > z
	for(var/obj/structure/ladder/ladder as anything in GLOB.ladders)
		if(ladder.z != z || !(going_up ? ladder.up : ladder.down))
			continue
		var/distance = get_dist(src, ladder)
		if(distance < nearest_distance)
			nearest_distance = distance
			best_entry = ladder
			ladder_ref = WEAKREF(ladder)
	for(var/obj/structure/stairs/stair as anything in GLOB.stairs)
		if(!stair.isTerminator())
			continue
		var/turf/lower = get_turf(stair)
		var/turf/upper = get_step_multiz(stair, stair.dir | UP)
		var/turf/entry = going_up ? lower : upper
		var/turf/exit = going_up ? upper : lower
		if(entry?.z != z || !isopenturf(exit) || abs(exit.z - target_z) >= abs(z - target_z))
			continue
		var/distance = get_dist(src, entry)
		if(distance < nearest_distance)
			nearest_distance = distance
			best_entry = entry
			ladder_ref = null
			stair_exit = exit
	return best_entry

/mob/living/basic/cyberpunk_nanite/melee_attack(atom/target, list/modifiers, ignore_cooldown = FALSE)
	var/mob/living/victim = target
	var/datum/antagonist/cyberpunk/major/broker/broker = broker_ref?.resolve()
	if(!broker || !istype(victim) || istype(victim, /mob/living/basic/cyberpunk_nanite) || atomic_wall)
		return FALSE
	if(!Adjacent(victim))
		return FALSE
	if(victim.stat == DEAD)
		return broker.raise_nanite(victim)
	if(conversion_target?.resolve() != victim || !conversion_started || world.time > last_attack + 3 SECONDS)
		conversion_target = WEAKREF(victim)
		conversion_started = world.time
	. = ..()
	if(.)
		last_attack = world.time
		if((victim.stat == DEAD && broker.count_charged_anchors() == 3) || world.time >= conversion_started + 1 MINUTES)
			broker.raise_nanite(victim)
			conversion_target = null
			conversion_started = null

/mob/living/basic/cyberpunk_nanite/verb/recall_to_anchor()
	set name = "Вернуться к якорю"
	set category = "Наниты"
	if(stat == DEAD)
		return
	var/datum/antagonist/cyberpunk/major/broker/broker = broker_ref?.resolve()
	var/obj/structure/cyberpunk_broker_anchor/closest
	var/distance = INFINITY
	for(var/datum/weakref/reference as anything in broker?.anchors)
		var/obj/structure/cyberpunk_broker_anchor/anchor = reference.resolve()
		if(!anchor || anchor.charge < anchor.capacity)
			continue
		var/current_distance = get_dist(src, anchor) + abs(z - anchor.z) * world.maxx
		if(current_distance < distance)
			closest = anchor
			distance = current_distance
	if(closest)
		forceMove(get_turf(closest))
		heal_ordered_damage(maxHealth, list(BRUTE, BURN, TOX, OXY))

/mob/living/basic/cyberpunk_nanite/verb/toggle_atomic_wall()
	set name = "Атомарная стена"
	set category = "Наниты"
	if(stat == DEAD)
		return
	atomic_wall = !atomic_wall
	density = !atomic_wall
	color = atomic_wall ? "#dde9ec" : initial(color)
	if(atomic_wall)
		add_movespeed_modifier(/datum/movespeed_modifier/cyberpunk_atomic_wall)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/cyberpunk_atomic_wall)

/datum/movespeed_modifier/cyberpunk_atomic_wall
	multiplicative_slowdown = 4

/datum/antagonist/cyberpunk/major/liberation_army
	name = "Liberation Army"
	pref_flag = ROLE_CYBERPUNK_LIBERATION_ARMY
	chip_name = "планшет Армии спасения"
	role_briefing = "Поднимите хаос, закажите ядерный грузовик и взорвите его в центре Даунтауна."
	primary_action = "Развернуть ячейку"
	progress_goal = 1
	team_type = /datum/team/cyberpunk_liberation_army
	var/list/watched_structures = list()

/datum/antagonist/cyberpunk/major/liberation_army/on_gain()
	. = ..()
	var/mob/living/body = owner.current
	body.faction |= REF(get_team())
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_liberation_death))

/datum/antagonist/cyberpunk/major/liberation_army/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	for(var/datum/weakref/reference as anything in watched_structures)
		var/obj/target = reference.resolve()
		if(target)
			UnregisterSignal(target, COMSIG_QDELETING)
	return ..()

/datum/antagonist/cyberpunk/major/liberation_army/proc/on_liberation_death(datum/source, mob/living/victim)
	SIGNAL_HANDLER
	if(!victim.mind?.key || !owner?.current?.ckey || victim.lastattackerckey != owner.current.ckey || victim.mind.has_antag_datum(type))
		return
	var/datum/team/cyberpunk_liberation_army/team = get_team()
	if(victim.mind in team.casualties)
		return
	team.casualties += victim.mind
	team.chaos += 400

/datum/antagonist/cyberpunk/major/liberation_army/proc/on_liberation_destroyed(obj/target)
	SIGNAL_HANDLER
	var/datum/team/cyberpunk_liberation_army/team = get_team()
	if(target.get_integrity() <= 0 && !(REF(target) in team.wrecks))
		team.wrecks += REF(target)
		team.chaos += 150

/datum/antagonist/cyberpunk/major/liberation_army/perform_primary_action(mob/living/user)
	var/datum/team/cyberpunk_liberation_army/army = get_team()
	var/turf/location = get_turf(user)
	if(!location || (location in army.established_cells) || !do_after(user, 20 SECONDS, target = user) || (location in army.established_cells))
		return FALSE
	army.established_cells += location
	new /obj/structure/cyberpunk_liberation_cell(location)
	return TRUE

/datum/antagonist/cyberpunk/major/liberation_army/get_chip_options(mob/living/user)
	return list(primary_action, "Отметить цель разрушения", "Построить завод", "Построить казармы", "Построить оружейный завод", "Поставить чёрный сервер", "Вырыть тоннель", "Заказать подкрепление", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/liberation_army/handle_chip_option(mob/living/user, choice)
	var/datum/team/cyberpunk_liberation_army/army = get_team()
	switch(choice)
		if("Отметить цель разрушения")
			var/list/targets = list()
			for(var/obj/target in view(1, user))
				if(target.uses_integrity && (istype(target, /obj/machinery) || istype(target, /obj/structure)))
					targets += target
			var/obj/target = tgui_input_list(user, "Выберите объект.", name, targets)
			if(!target || (WEAKREF(target) in watched_structures))
				return FALSE
			watched_structures += WEAKREF(target)
			RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_liberation_destroyed))
			return TRUE
		if("Построить завод")
			return build_asset(user, /obj/structure/cyberpunk_liberation_factory)
		if("Построить казармы")
			return build_asset(user, /obj/structure/cyberpunk_liberation_barracks)
		if("Построить оружейный завод")
			return build_asset(user, /obj/structure/cyberpunk_liberation_arms_plant)
		if("Поставить чёрный сервер")
			return build_asset(user, /obj/structure/cyberpunk_liberation_black_server)
		if("Вырыть тоннель")
			return build_asset(user, /obj/structure/cyberpunk_liberation_tunnel)
		if("Заказать подкрепление")
			if(army.chaos < 250 || !action_ready(user, choice, 20 SECONDS))
				return FALSE
			army.chaos -= 250
			var/mob/living/fighter = new /mob/living/simple_animal/hostile/asteroid(get_turf(user))
			fighter.faction = list(REF(army))
			return TRUE
		if("Status")
			to_chat(user, span_notice("Хаос [army.chaos]. Ядерный грузовик [army.nuke_ordered ? "заказан" : "доступен для заказа при достаточном хаосе"]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/liberation_army/proc/build_asset(mob/living/user, asset_type)
	if(!action_ready(user, "build_[asset_type]", 45 SECONDS) || !do_after(user, 20 SECONDS, target = user))
		return FALSE
	var/obj/structure/asset = new asset_type(get_turf(user))
	var/obj/structure/cyberpunk_liberation_factory/vehicle_factory = asset
	if(istype(vehicle_factory))
		vehicle_factory.army = get_team()
	return TRUE

/datum/antagonist/cyberpunk/major/liberation_army/roundend_report()
	var/datum/team/cyberpunk_liberation_army/army = get_team()
	return "[printplayer(owner)]<br>Хаос: [army.chaos]. [army.won ? span_greentext("Ядерная операция завершена.") : span_redtext("Ядерная операция сорвана.")]"

/obj/vehicle/ridden/atv/cyberpunk_liberation
	name = "техничка Армии спасения"
	var/datum/team/cyberpunk_liberation_army/army
	var/projectile_type = /obj/projectile/beam/laser
	var/firing_delay = 2 SECONDS
	var/ammunition = 25
	var/next_shot

/obj/vehicle/ridden/atv/cyberpunk_liberation/attack_hand_secondary(mob/user, list/modifiers)
	var/datum/antagonist/cyberpunk/major/liberation_army/agent = user.mind?.has_antag_datum(/datum/antagonist/cyberpunk/major/liberation_army)
	if(agent?.get_team() != army || !army || !(user in buckled_mobs))
		return ..()
	if(!ammunition || world.time < next_shot || !projectile_type)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/list/targets = list()
	for(var/mob/living/victim in view(7, src))
		if(victim != user && victim.stat != DEAD)
			targets += victim
	var/mob/living/victim = tgui_input_list(user, "Выберите цель для вооружения. Заряды: [ammunition].", name, targets)
	if(!victim || QDELETED(src) || QDELETED(victim) || victim.z != z || get_dist(src, victim) > 7 || !(user in buckled_mobs) || world.time < next_shot || !ammunition)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/turf/origin = get_turf(src)
	var/obj/projectile/shot = new projectile_type(origin)
	shot.aim_projectile(victim, origin)
	shot.firer = user
	shot.fired_from = src
	shot.fire()
	ammunition--
	next_shot = world.time + firing_delay
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/vehicle/ridden/atv/cyberpunk_liberation/bombtruck
	name = "бомбтрак"
	projectile_type = /obj/projectile/bullet/rocket
	firing_delay = 8 SECONDS
	ammunition = 1

/obj/vehicle/ridden/atv/cyberpunk_liberation/rocket_buggy
	name = "ракетный багги"
	projectile_type = /obj/projectile/bullet/rocket
	firing_delay = 8 SECONDS
	ammunition = 5

/obj/vehicle/ridden/atv/cyberpunk_liberation/tank
	name = "лёгкий танк Армии спасения"
	max_integrity = 550
	projectile_type = /obj/projectile/beam/laser/heavylaser
	firing_delay = 5 SECONDS
	ammunition = 12

/obj/vehicle/ridden/atv/cyberpunk_liberation/nuclear
	name = "ядерный грузовик Армии спасения"
	projectile_type = null
	ammunition = 0
	var/obj/machinery/nuclearbomb/cyberpunk_liberation/warhead

/obj/vehicle/ridden/atv/cyberpunk_liberation/nuclear/attack_hand_secondary(mob/user, list/modifiers)
	var/datum/antagonist/cyberpunk/major/liberation_army/agent = user.mind?.has_antag_datum(/datum/antagonist/cyberpunk/major/liberation_army)
	if(agent?.get_team() != army || !army || (user in buckled_mobs) || warhead)
		return ..()
	if(!cyberpunk_liberation_nuke_location(src))
		to_chat(user, span_warning("Подгоните грузовик к центру Даунтауна."))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	to_chat(user, span_notice("Стойте рядом с грузовиком одну минуту для взведения."))
	if(!do_after(user, 1 MINUTES, target = src) || warhead || !cyberpunk_liberation_nuke_location(src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	set_anchored(TRUE)
	warhead = new(get_turf(src))
	warhead.army = army
	warhead.safety = FALSE
	warhead.timing = TRUE
	warhead.timer_set = 300
	warhead.arm_nuke(user)
	priority_announce("В Даунтауне взведено ядерное устройство. До взрыва пять минут.", "Городская тревога")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/proc/cyberpunk_liberation_nuke_location(atom/device)
	var/area/location = get_area(device)
	if(location?.cyberpunk_district_id == "test_ground")
		return TRUE
	if(location?.cyberpunk_district_id != "downtown")
		return FALSE
	var/turf/device_turf = get_turf(device)
	var/left = world.maxx
	var/right = 1
	var/bottom = world.maxy
	var/top = 1
	for(var/turf/district_turf as anything in location.get_turfs_by_zlevel(device_turf.z))
		left = min(left, district_turf.x)
		right = max(right, district_turf.x)
		bottom = min(bottom, district_turf.y)
		top = max(top, district_turf.y)
	return abs(device_turf.x - (left + right) * 0.5) <= 12 && abs(device_turf.y - (bottom + top) * 0.5) <= 12

/obj/machinery/nuclearbomb/cyberpunk_liberation
	name = "боеголовка Армии спасения"
	anchored = TRUE
	var/datum/team/cyberpunk_liberation_army/army

/obj/machinery/nuclearbomb/cyberpunk_liberation/actually_explode()
	if(core && army && cyberpunk_liberation_nuke_location(src))
		army.won = TRUE
		for(var/datum/antagonist/cyberpunk/major/liberation_army/member in GLOB.antagonists)
			if(member.get_team() == army)
				member.add_progress(1, "подрыв боеголовки")
	return ..()

/datum/antagonist/cyberpunk/major/data_cult
	name = "Data Cult"
	pref_flag = ROLE_CYBERPUNK_DATA_CULT
	progress_goal = 5000
	chip_name = "шифр Культа данных"
	role_briefing = "Соберите данные всем Культом и призовите Контрл Вавелнгейт."
	team_type = /datum/team/cyberpunk_data_cult
	var/next_shield
	var/next_run
	var/next_network_ability

/datum/antagonist/cyberpunk/major/data_cult/on_gain()
	var/mob/living/body = owner.current
	body.gender = NEUTER
	var/datum/team/cyberpunk_data_cult/team = get_team()
	body.faction |= REF(team)
	progress_points = min(team.stolen_data, progress_goal)
	goal_completed = team.summoned
	. = ..()

/datum/antagonist/cyberpunk/major/data_cult/get_chip_options(mob/living/user)
	return list("Извлечь данные", "Перепрограммировать нейрочип", "Обратить погибшего без чипа", "Призвать Контрл", "Перейти между мирами", "Усыпить в сети", "Скачок в сети", "Щит", "Ускориться", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/data_cult/handle_chip_option(mob/living/user, choice)
	var/datum/team/cyberpunk_data_cult/team = get_team()
	switch(choice)
		if("Извлечь данные")
			return perform_primary_action(user)
		if("Перепрограммировать нейрочип")
			return induct_target(user)
		if("Обратить погибшего без чипа")
			var/mob/living/target = cyberpunk_antag_select_corpse(user, name)
			return cyberpunk_raise_cult_alternative(user, target, team)
		if("Призвать Контрл")
			return summon_control(user, team)
		if("Перейти между мирами")
			return user.cyberpunk_antag_project(user)
		if("Усыпить в сети", "Скачок в сети")
			return use_cult_network_ability(user, choice)
		if("Щит")
			if(user.cyberspace_session)
				return FALSE
			if(user.has_status_effect(/datum/status_effect/cyberpunk_cult_shield))
				user.remove_status_effect(/datum/status_effect/cyberpunk_cult_shield)
				return TRUE
			if(world.time < next_shield)
				return FALSE
			user.apply_status_effect(/datum/status_effect/cyberpunk_cult_shield, src)
			return TRUE
		if("Ускориться")
			if(user.cyberspace_session || world.time < next_run)
				return FALSE
			next_run = world.time + 60 SECONDS
			user.apply_status_effect(/datum/status_effect/cyberpunk_cult_run)
			return TRUE
		if("Status")
			to_chat(user, span_notice("Данные Культа: [team.stolen_data]/[progress_goal]."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/data_cult/proc/use_cult_network_ability(mob/living/user, choice)
	var/mob/eye/cyberspace_avatar/avatar = user.cyberspace_session?.avatar
	if(!avatar || world.time < next_network_ability)
		return FALSE
	if(choice == "Усыпить в сети")
		var/list/options = list()
		for(var/mob/eye/cyberspace_avatar/target in view(7, avatar))
			if(target != avatar && target.session?.body?.has_neural_implant())
				options += target
		var/mob/eye/cyberspace_avatar/target = tgui_input_list(user, "Выберите владельца нейроинтерфейса.", name, options)
		if(!target?.session?.body || QDELETED(avatar) || get_dist(avatar, target) > 7)
			return FALSE
		var/mob/living/victim = target.session.body
		victim.Sleeping(15 SECONDS)
		next_network_ability = world.time + 30 SECONDS
		return TRUE
	var/list/locations = list()
	for(var/turf/open/location in view(5, avatar))
		if(!location.density)
			locations += location
	var/turf/destination = tgui_input_list(user, "Куда совершить скачок?", name, locations)
	if(!destination || QDELETED(avatar) || get_dist(avatar, destination) > 5)
		return FALSE
	avatar.forceMove(destination)
	next_network_ability = world.time + 30 SECONDS
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/perform_primary_action(mob/living/user)
	var/datum/team/cyberpunk_data_cult/team = get_team()
	var/list/targets = list()
	for(var/obj/machinery/machine in view(1, user))
		if(!(WEAKREF(machine) in team.harvested_refs))
			targets += machine
	for(var/mob/living/person in view(1, user))
		if(person != user && person.has_neural_implant() && !(WEAKREF(person) in team.harvested_refs))
			targets += person
	var/atom/movable/target = tgui_input_list(user, "Выберите источник данных.", name, targets)
	if(!target || !do_after(user, 10 SECONDS, target = target) || QDELETED(target) || (WEAKREF(target) in team.harvested_refs))
		return FALSE
	var/datum/cyberspace_layer/layer = SScyberspace?.ensure_ready()
	var/datum/cyberspace_node/node = layer?.get_nearest_node(target)
	var/target_key = node?.get_object_ref_key(target)
	var/extracted
	var/mob/living/person = target
	if(istype(person) && person.mind && person.has_neural_implant())
		extracted = min(person.mind.cyber_net_data, 500)
		person.mind.cyber_net_data -= extracted
	else if(node?.has_object(target))
		extracted = node.object_net_data_by_ref[target_key]
		node.object_net_data_by_ref[target_key] = 0
	if(!extracted)
		to_chat(user, span_warning("В источнике нет данных."))
		return FALSE
	team.harvested_refs += WEAKREF(target)
	team.stolen_data += extracted
	for(var/datum/antagonist/cyberpunk/major/data_cult/member in GLOB.antagonists)
		if(member.get_team() == team)
			member.progress_points = min(team.stolen_data, member.progress_goal)
	to_chat(user, span_notice("В общий запас передано [extracted] данных."))
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/proc/induct_target(mob/living/user)
	var/list/targets = list()
	for(var/mob/living/person in view(1, user))
		if(person != user && person.mind && person.stat != DEAD && person.has_neural_implant() && !person.mind.has_antag_datum(type))
			targets += person
	var/mob/living/target = tgui_input_list(user, "Кого перепрограммировать?", name, targets)
	if(!target)
		return FALSE
	var/datum/team/cyberpunk_data_cult/team = get_team()
	var/list/helpers = list(user)
	for(var/mob/living/helper in view(1, target))
		var/datum/antagonist/cyberpunk/major/data_cult/member = helper.mind?.has_antag_datum(type)
		if(helper != user && helper.stat == CONSCIOUS && member?.get_team() == team)
			helpers += helper
		if(length(helpers) == 3)
			break
	var/delay = (4 - length(helpers)) * 15 SECONDS
	if(!do_after(user, delay, target = target, extra_checks = CALLBACK(src, PROC_REF(check_induction), target, helpers)))
		return FALSE
	if(!target.mind || target.mind.has_antag_datum(type) || !target.has_neural_implant())
		return FALSE
	target.mind.add_antag_datum(/datum/antagonist/cyberpunk/major/data_cult, team)
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/proc/check_induction(mob/living/target, list/helpers)
	if(QDELETED(target) || target.stat == DEAD || !target.has_neural_implant())
		return FALSE
	for(var/mob/living/helper as anything in helpers)
		if(QDELETED(helper) || helper.stat != CONSCIOUS || !target.Adjacent(helper))
			return FALSE
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/proc/summon_control(mob/living/user, datum/team/cyberpunk_data_cult/team)
	if(user.cyberspace_session || team.summoned || team.stolen_data < progress_goal || !do_after(user, 15 SECONDS, target = user) || team.summoned || team.stolen_data < progress_goal)
		return FALSE
	var/mob/living/carbon/human/cyberpunk_control_wavelengate/control = new(get_turf(user))
	control.cult = team
	control.faction |= REF(team)
	var/obj/item/cyberspace_engram_chip/engram = new(control)
	engram.bind_body(control, user)
	var/obj/item/cyberpunk_antag_control_chip/control_chip
	for(var/obj/item/cyberpunk_antag_control_chip/chip in user.get_all_contents())
		if(chip.owner_ref?.resolve() == src)
			control_chip = chip
			break
	team.summoned = TRUE
	user.mind?.transfer_to(control, force_key_move = TRUE)
	if(control_chip)
		control_chip.forceMove(control)
		control.put_in_hands(control_chip)
	for(var/datum/antagonist/cyberpunk/major/data_cult/member in GLOB.antagonists)
		if(member.get_team() == team)
			member.goal_completed = TRUE
			member.progress_points = member.progress_goal
	priority_announce("Контрл Вавелнгейт воплотилась. Культ данных победил. Город вступает в финальную фазу.", "Городская сеть")
	SScyberpunk_round?.start_cyberpunk_antag_finale("data_cult", 3 MINUTES)
	return TRUE

/mob/living/carbon/human/cyberpunk_control_wavelengate
	name = "Контрл Вавелнгейт"
	real_name = "Контрл Вавелнгейт"
	gender = NEUTER
	var/datum/team/cyberpunk_data_cult/cult

/mob/living/carbon/human/cyberpunk_control_wavelengate/verb/raise_cult_assistant()
	set name = "Обратить погибшего"
	set category = "Культ данных"
	if(!cult || stat != CONSCIOUS)
		return
	var/mob/living/target = cyberpunk_antag_select_corpse(src, name)
	cyberpunk_raise_cult_alternative(src, target, cult, TRUE)

/proc/cyberpunk_raise_cult_alternative(mob/living/user, mob/living/target, datum/team/cyberpunk_data_cult/team, synthbot = FALSE)
	if(!target || !team || target.stat != DEAD || (target.has_neural_implant() && !synthbot) || istype(target, /mob/living/basic/cyberspace_alternative) || !do_after(user, 15 SECONDS, target = target) || QDELETED(target) || target.stat != DEAD)
		return FALSE
	var/mob/living/assistant
	if(synthbot)
		assistant = new /mob/living/basic/cyberpunk_rogue_cyborg(get_turf(target))
		assistant.name = "синтбот Культа"
	else
		assistant = new /mob/living/basic/cyberspace_alternative(get_turf(target))
	assistant.faction |= REF(team)
	if(target.mind)
		target.mind.transfer_to(assistant, force_key_move = TRUE)
	qdel(target)
	return TRUE

/datum/status_effect/cyberpunk_cult_shield
	id = "cyberpunk_cult_shield"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null
	var/remaining = 1000
	var/was_opaque
	var/datum/weakref/cultist_ref

/datum/status_effect/cyberpunk_cult_shield/on_creation(mob/living/body, datum/antagonist/cyberpunk/major/data_cult/cultist)
	cultist_ref = WEAKREF(cultist)
	return ..(body)

/datum/status_effect/cyberpunk_cult_shield/on_apply()
	was_opaque = owner.opacity
	owner.set_opacity(TRUE)
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, REF(src))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(absorb_damage))
	return TRUE

/datum/status_effect/cyberpunk_cult_shield/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, REF(src))
	owner.set_opacity(was_opaque)
	var/datum/antagonist/cyberpunk/major/data_cult/cultist = cultist_ref?.resolve()
	if(cultist)
		cultist.next_shield = world.time + 30 SECONDS

/datum/status_effect/cyberpunk_cult_shield/proc/absorb_damage(datum/source, list/modifiers, damage)
	SIGNAL_HANDLER
	if(damage <= 0 || remaining <= 0)
		return
	modifiers += 0
	remaining -= damage
	if(remaining <= 0)
		qdel(src)

/datum/status_effect/cyberpunk_cult_run
	id = "cyberpunk_cult_run"
	duration = 30 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null

/datum/status_effect/cyberpunk_cult_run/on_apply()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cyberpunk_cult_run, multiplicative_slowdown = -owner.cached_multiplicative_slowdown * 0.5)
	return TRUE

/datum/status_effect/cyberpunk_cult_run/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/cyberpunk_cult_run)

/datum/movespeed_modifier/cyberpunk_cult_run
	variable = TRUE

/obj/structure/cyberpunk_flesh_growth
	name = "evolutionary flesh growth"
	desc = "A wet knot of engineered Benn biomass."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	density = FALSE

/obj/structure/cyberpunk_swarm_pylon
	name = "photon pylon"
	desc = "A Starlight swarm pylon bleeding clean energy into the area."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk1"
	density = TRUE
	anchored = TRUE
	var/datum/team/cyberpunk_star_swarm/swarm

/obj/structure/cyberpunk_swarm_pylon/Destroy()
	if(swarm)
		swarm.pylons -= src
	return ..()

/obj/structure/cyberpunk_swarm_pylon/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	user.heal_ordered_damage(15, list(BRUTE, BURN, TOX, OXY))
	to_chat(user, span_notice("The pylon bleeds stabilizing light into you."))

/obj/structure/cyberpunk_photon_turret
	name = "photon turret"
	desc = "A Starlight photon projector. It burns a chosen nearby target when operated."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk4"
	density = TRUE
	anchored = TRUE
	var/datum/team/cyberpunk_star_swarm/swarm
	var/next_fire_at = 0
	var/boost_until = 0

/obj/structure/cyberpunk_photon_turret/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!swarm?.powered_at(src))
		to_chat(user, span_warning("Нет источника питания Роя поблизости."))
		return
	if(world.time < next_fire_at)
		to_chat(user, span_warning("[src] is recharging for [DisplayTimeText(next_fire_at - world.time)]."))
		return
	var/list/targets = list()
	for(var/mob/living/nearby in view(5, src))
		if(nearby != user && nearby.stat != DEAD)
			targets += nearby
	var/mob/living/target = tgui_input_list(user, "Choose photon target.", "Photon Turret", targets)
	if(!target)
		return
	if(!swarm?.powered_at(src) || world.time < next_fire_at)
		return
	next_fire_at = world.time + (world.time < boost_until ? 10 SECONDS : 20 SECONDS)
	target.apply_damage(25, BURN, BODY_ZONE_CHEST)
	visible_message(span_danger("[src] lances [target] with hard light."))

/obj/structure/cyberpunk_liberation_cell
	name = "liberation cell marker"
	desc = "A hidden field marker for a Liberation Army cell."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk2"
	density = FALSE

/obj/structure/cyberpunk_network_shroud
	name = "network shroud"
	desc = "A damaged network knot wrapped in hostile traces."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk3"
	density = FALSE

/obj/structure/cyberpunk_awakened_machine
	name = "awakened machine mark"
	desc = "A machine marked by transformer awakening."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk4"
	density = FALSE

/obj/structure/cyberpunk_autossembler
	name = "автосборщик Трансформера"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk5"
	density = TRUE
	anchored = TRUE
	var/next_assembly_at
	var/datum/weakref/transformer_ref
	var/datum/weakref/occupant_ref
	var/conversion_timer

/obj/structure/cyberpunk_autossembler/Destroy()
	eject_occupant()
	return ..()

/obj/structure/cyberpunk_autossembler/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	var/datum/antagonist/cyberpunk/major/transformer/transformer = transformer_ref?.resolve()
	if(!transformer || transformer.owner?.current != user || world.time < next_assembly_at)
		return
	var/choice = tgui_input_list(user, "Что сделать?", name, list("Байк", "Ремонтный дрон", "Кибернизировать"))
	if(QDELETED(src) || !Adjacent(user) || world.time < next_assembly_at)
		return
	if(choice == "Кибернизировать")
		begin_conversion(user)
		return
	if(!choice || transformer.parts < 20)
		return
	transformer.parts -= 20
	next_assembly_at = world.time + 45 SECONDS
	if(choice == "Байк")
		new /obj/vehicle/ridden/speedbike(get_turf(src))
	else
		new /mob/living/basic/bot/repairbot(get_turf(src))

/obj/structure/cyberpunk_autossembler/attack_hand_secondary(mob/user, list/modifiers)
	if(occupant_ref?.resolve())
		eject_occupant()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/structure/cyberpunk_autossembler/proc/begin_conversion(mob/living/user)
	var/list/candidates = list()
	for(var/mob/living/carbon/human/target in view(1, src))
		if(target != user && target.mind && target.stat != DEAD && !target.mind.has_antag_datum(/datum/antagonist/cyberpunk/major/transformer))
			candidates += target
	var/mob/living/carbon/human/target = tgui_input_list(user, "Кого загрузить в ядро?", name, candidates)
	if(!target || QDELETED(src) || !Adjacent(target) || occupant_ref?.resolve())
		return
	occupant_ref = WEAKREF(target)
	ADD_TRAIT(target, TRAIT_IMMOBILIZED, REF(src))
	target.forceMove(src)
	conversion_timer = addtimer(CALLBACK(src, PROC_REF(finish_conversion)), 2 MINUTES, TIMER_STOPPABLE)

/obj/structure/cyberpunk_autossembler/proc/finish_conversion()
	var/mob/living/carbon/human/target = occupant_ref?.resolve()
	var/datum/antagonist/cyberpunk/major/transformer/transformer = transformer_ref?.resolve()
	if(target?.mind && target.stat != DEAD && target.loc == src && transformer)
		target.set_species(/datum/species/android)
		target.mind.add_antag_datum(/datum/antagonist/cyberpunk/major/transformer)
		transformer.parts = min(400, transformer.parts + 40)
	eject_occupant()

/obj/structure/cyberpunk_autossembler/proc/eject_occupant()
	deltimer(conversion_timer)
	conversion_timer = null
	var/mob/living/target = occupant_ref?.resolve()
	occupant_ref = null
	if(target)
		REMOVE_TRAIT(target, TRAIT_IMMOBILIZED, REF(src))
		if(target.loc == src)
			target.forceMove(get_turf(src))

/obj/structure/cyberpunk_broker_anchor
	name = "якорь Брокера"
	desc = "Накапливает заряд для выброса нанитов."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk6"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	var/charge = 0
	var/capacity = 60
	var/datum/weakref/broker_ref

/obj/structure/cyberpunk_broker_anchor/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/cyberpunk_broker_anchor/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/cyberpunk_broker_anchor/process(seconds_per_tick)
	charge = min(capacity, charge + seconds_per_tick)
	if(charge >= capacity)
		return PROCESS_KILL

/obj/structure/cyberpunk_broker_anchor/examine(mob/user)
	. = ..()
	. += "Заряд [round(charge)]/[capacity]."

/obj/structure/cyberpunk_liberation_factory
	name = "завод техники Армии спасения"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk7"
	density = TRUE
	var/datum/team/cyberpunk_liberation_army/army
	var/next_production_at

/obj/structure/cyberpunk_liberation_factory/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	var/datum/antagonist/cyberpunk/major/liberation_army/agent = user.mind?.has_antag_datum(/datum/antagonist/cyberpunk/major/liberation_army)
	if(!army || agent?.get_team() != army || world.time < next_production_at)
		return
	var/static/list/vehicles = list(
		"Бомбтрак (650)" = /obj/vehicle/ridden/atv/cyberpunk_liberation/bombtruck,
		"Ракетный багги (800)" = /obj/vehicle/ridden/atv/cyberpunk_liberation/rocket_buggy,
		"Техничка (500)" = /obj/vehicle/ridden/atv/cyberpunk_liberation,
		"Лёгкий танк (1200)" = /obj/vehicle/ridden/atv/cyberpunk_liberation/tank,
		"Ядерный грузовик (4000)" = /obj/vehicle/ridden/atv/cyberpunk_liberation/nuclear,
	)
	var/static/list/prices = list(
		"Бомбтрак (650)" = 650,
		"Ракетный багги (800)" = 800,
		"Техничка (500)" = 500,
		"Лёгкий танк (1200)" = 1200,
		"Ядерный грузовик (4000)" = 4000,
	)
	var/choice = tgui_input_list(user, "Выберите технику. Хаос: [army.chaos].", name, vehicles)
	var/vehicle_type = vehicles[choice]
	var/cost = prices[choice]
	if(!vehicle_type || QDELETED(src) || !Adjacent(user) || world.time < next_production_at || army.chaos < cost)
		return
	var/nuclear = vehicle_type == /obj/vehicle/ridden/atv/cyberpunk_liberation/nuclear
	if(nuclear && army.nuke_ordered)
		return
	var/turf/destination = get_turf(user)
	var/turf/pickup = get_safe_random_station_turf()
	if(!pickup || !destination)
		return
	var/obj/vehicle/ridden/cyberpunk/avi/courier = new(pickup)
	var/obj/vehicle/ridden/atv/cyberpunk_liberation/vehicle = new vehicle_type(pickup)
	vehicle.army = army
	if(!courier.start_cyberpunk_avi_delivery(pickup, destination, list(vehicle)))
		qdel(courier)
		qdel(vehicle)
		return
	army.chaos -= cost
	if(nuclear)
		army.nuke_ordered = TRUE
	next_production_at = world.time + 90 SECONDS
	to_chat(user, span_notice("АВИ доставит технику к месту заказа."))

/obj/structure/cyberpunk_liberation_barracks
	name = "liberation barracks marker"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk8"
	density = TRUE
	var/next_training_at = 0

/obj/structure/cyberpunk_liberation_barracks/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(world.time < next_training_at)
		to_chat(user, span_warning("[src] is training for [DisplayTimeText(next_training_at - world.time)]."))
		return
	var/choice = tgui_input_list(user, "Train or arm cell.", "Barracks", list("rifle kit", "raid kit", "field fighter", "Cancel"))
	switch(choice)
		if("rifle kit")
			new /obj/item/gun/ballistic/rifle/cyberpunk/patrol(get_turf(src))
		if("raid kit")
			new /obj/item/knife/cyberpunk/axe(get_turf(src))
			new /obj/item/grenade/smokebomb(get_turf(src))
		if("field fighter")
			new /mob/living/simple_animal/hostile/asteroid(get_turf(src))
	if(choice && choice != "Cancel")
		next_training_at = world.time + 60 SECONDS

/obj/structure/cyberpunk_liberation_arms_plant
	name = "liberation arms plant marker"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk9"
	density = TRUE
	var/next_production_at = 0

/obj/structure/cyberpunk_liberation_arms_plant/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(world.time < next_production_at)
		to_chat(user, span_warning("[src] is producing for [DisplayTimeText(next_production_at - world.time)]."))
		return
	var/choice = tgui_input_list(user, "Produce weapon.", "Arms Plant", list("pistol", "rifle", "shotgun", "rocket launcher", "Cancel"))
	switch(choice)
		if("pistol")
			new /obj/item/gun/ballistic/automatic/pistol/cyberpunk/sidearm(get_turf(src))
		if("rifle")
			new /obj/item/gun/ballistic/rifle/cyberpunk/patrol(get_turf(src))
		if("shotgun")
			new /obj/item/gun/ballistic/shotgun/cyberpunk/room_clearer(get_turf(src))
		if("rocket launcher")
			new /obj/item/gun/ballistic/rocketlauncher/cyberpunk(get_turf(src))
	if(choice && choice != "Cancel")
		next_production_at = world.time + 45 SECONDS

/obj/structure/cyberpunk_liberation_black_server
	name = "liberation black server"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	density = TRUE
	var/stored_income = 0

/obj/structure/cyberpunk_liberation_black_server/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/cyberpunk_liberation_black_server/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/cyberpunk_liberation_black_server/process(seconds_per_tick)
	stored_income += max(1, round(seconds_per_tick))

/obj/structure/cyberpunk_liberation_black_server/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	to_chat(user, span_notice("Black server income: [stored_income]."))
	if(stored_income >= 60)
		stored_income -= 60
		new /obj/item/stack/spacecash/c1000(get_turf(src))

/obj/structure/cyberpunk_liberation_tunnel
	name = "liberation tunnel marker"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk1"
	density = FALSE

/obj/structure/cyberpunk_liberation_tunnel/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	var/list/tunnels = list()
	for(var/obj/structure/cyberpunk_liberation_tunnel/tunnel in world)
		if(tunnel != src && tunnel.z == z)
			tunnels += tunnel
	if(!length(tunnels))
		to_chat(user, span_warning("No linked tunnel on this level."))
		return
	var/obj/structure/cyberpunk_liberation_tunnel/target = tgui_input_list(user, "Choose tunnel.", "Tunnel Network", tunnels)
	if(target)
		user.forceMove(get_turf(target))

/obj/item/cyberpunk_antag_control_chip
	name = "cyberpunk antagonist key"
	desc = "A control key for a cyberpunk antagonist role."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk3"
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/owner_ref

/obj/item/cyberpunk_antag_control_chip/attack_self(mob/living/user)
	ui_interact(user)

/obj/item/cyberpunk_antag_control_chip/proc/get_antag_for_user(mob/living/user)
	var/datum/antagonist/cyberpunk/major/antag = owner_ref?.resolve()
	if(!antag || antag.owner?.current != user)
		return null
	return antag

/obj/item/cyberpunk_antag_control_chip/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/major/antag = get_antag_for_user(living_user)
	if(!antag)
		to_chat(user, span_warning("The key rejects you."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkAntagChip", name)
		ui.open()

/obj/item/cyberpunk_antag_control_chip/ui_data(mob/user)
	var/list/data = list()
	if(!isliving(user))
		data["valid"] = FALSE
		return data
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/major/antag = get_antag_for_user(living_user)
	if(!antag)
		data["valid"] = FALSE
		return data

	var/list/actions = list()
	for(var/option in antag.get_chip_options(living_user))
		if(option == "Cancel")
			continue
		actions += list(list(
			"id" = option,
			"label" = option,
		))

	var/list/resources = null
	var/datum/team/team = antag.get_team()
	if(team?.cyberpunk_faction_resources)
		resources = team.cyberpunk_faction_resources.to_snapshot()

	data["valid"] = TRUE
	data["mode"] = "major"
	data["title"] = antag.name
	data["subtitle"] = name
	data["briefing"] = antag.role_briefing
	data["progress"] = antag.progress_points
	data["goal"] = antag.progress_goal
	data["complete"] = antag.goal_completed
	data["team"] = team?.name
	data["resources"] = resources
	data["actions"] = actions
	return data

/obj/item/cyberpunk_antag_control_chip/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!isliving(usr))
		return TRUE
	var/mob/living/user = usr
	var/datum/antagonist/cyberpunk/major/antag = get_antag_for_user(user)
	if(!antag)
		return TRUE

	switch(action)
		if("run_action")
			var/action_id = params["id"]
			if(!istext(action_id) || action_id == "Cancel")
				return TRUE
			if(!(action_id in antag.get_chip_options(user)))
				return TRUE
			antag.handle_chip_option(user, action_id)
			return TRUE
		if("refresh")
			return TRUE

/obj/item/cyberpunk_black_market_chip
	name = "black market chip"
	desc = "A burnt market key. Use it to order a small illegal drop to nearby coordinates."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/owner_ref
	var/turf/drop_turf
	var/ordered = FALSE
	var/list/ordered_paths = list()

/obj/item/cyberpunk_black_market_chip/attack_self(mob/living/user)
	ui_interact(user)

/obj/item/cyberpunk_black_market_chip/proc/get_bandit_for_user(mob/living/user)
	var/datum/antagonist/cyberpunk/bandit/bandit = owner_ref?.resolve()
	if(!bandit || bandit.owner?.current != user)
		return null
	return bandit

/obj/item/cyberpunk_black_market_chip/attackby(obj/item/contraband, mob/user, list/modifiers, list/attack_modifiers)
	var/mob/living/seller = user
	var/datum/antagonist/cyberpunk/bandit/bandit = istype(seller) ? get_bandit_for_user(seller) : null
	if(!bandit || !HAS_TRAIT(contraband, TRAIT_CONTRABAND) || HAS_TRAIT_FROM(contraband, TRAIT_CONTRABAND, "cp_market_stock") || length(contraband.contents))
		return ..()
	var/datum/bank_account/account = seller.get_bank_account()
	if(!account || !seller.dropItemToGround(contraband))
		return TRUE
	if(!account.adjust_money(250, "Black market proceeds: [contraband.name]"))
		seller.put_in_hands(contraband)
		return TRUE
	qdel(contraband)
	to_chat(seller, span_notice("Картель принял контрабанду за 250 кредитов."))
	return TRUE

/obj/item/cyberpunk_black_market_chip/proc/get_market_actions()
	return list(
		list("id" = "sync", "label" = "Доход и таймер Картеля", "description" = "Чтобы сбыть контрабанду, приложите её к чипу."),
		list("id" = "status", "label" = "Gang status", "description" = "Show current gang and shared resources."),
		list("id" = "gang", "label" = "Choose gang", "description" = "Join an existing gang or found a new one."),
		list("id" = "knife", "label" = "Street knife", "cost" = 250, "description" = "Small blade drop."),
		list("id" = "sidearm", "label" = "Sidearm drop", "cost" = 750, "description" = "Concealable pistol drop."),
		list("id" = "rifle", "label" = "Rifle drop", "cost" = 1500, "description" = "Patrol rifle drop."),
		list("id" = "breacher", "label" = "Breacher kit", "cost" = 600, "description" = "Axe and crowbar drop."),
		list("id" = "heavy_cell", "label" = "Heavy cell", "cost" = 2500, "description" = "Shotgun and smoke drop."),
	)

/obj/item/cyberpunk_black_market_chip/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/bandit/bandit = get_bandit_for_user(living_user)
	if(!bandit)
		to_chat(user, span_warning("The chip rejects you."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkAntagChip", name)
		ui.open()

/obj/item/cyberpunk_black_market_chip/ui_data(mob/user)
	var/list/data = list()
	if(!isliving(user))
		data["valid"] = FALSE
		return data
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/bandit/bandit = get_bandit_for_user(living_user)
	if(!bandit)
		data["valid"] = FALSE
		return data

	var/datum/bank_account/account = living_user.get_bank_account()
	data["valid"] = TRUE
	data["mode"] = "market"
	data["title"] = "Black Market"
	data["subtitle"] = name
	data["briefing"] = ordered ? "Drop marked. Reach the coordinates and claim it from this chip." : "Order gear through a remote capsule drop."
	data["progress"] = bandit.progress_points
	data["goal"] = bandit.progress_goal
	data["complete"] = bandit.goal_completed
	data["balance"] = account?.account_balance || 0
	data["ordered"] = ordered
	data["drop"] = drop_turf ? "[drop_turf.x], [drop_turf.y], [drop_turf.z]" : null
	data["actions"] = get_market_actions()
	return data

/obj/item/cyberpunk_black_market_chip/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!isliving(usr))
		return TRUE
	var/mob/living/user = usr
	var/datum/antagonist/cyberpunk/bandit/bandit = get_bandit_for_user(user)
	if(!bandit)
		return TRUE

	switch(action)
		if("claim_drop")
			claim_drop(user)
			return TRUE
		if("run_action")
			var/action_id = params["id"]
			if(!istext(action_id))
				return TRUE
			if(ordered)
				claim_drop(user)
				return TRUE
			if(action_id == "sync")
				bandit.sync_dirty_money(user)
				return TRUE
			if(action_id == "status")
				bandit.show_gang_status(user)
				return TRUE
			if(action_id == "gang")
				bandit.configure_gang(user)
				return TRUE

			order_market_package(user, action_id)
			return TRUE
		if("refresh")
			return TRUE

/obj/item/cyberpunk_black_market_chip/proc/order_market_package(mob/living/user, package_id)
	var/cost = 0
	var/list/package_paths = list()
	switch(package_id)
		if("knife")
			cost = 250
			package_paths = list(/obj/item/knife/cyberpunk/razor)
		if("sidearm")
			cost = 750
			package_paths = list(/obj/item/gun/ballistic/automatic/pistol/cyberpunk/sidearm)
		if("rifle")
			cost = 1500
			package_paths = list(/obj/item/gun/ballistic/rifle/cyberpunk/patrol)
		if("breacher")
			cost = 600
			package_paths = list(/obj/item/knife/cyberpunk/axe, /obj/item/crowbar)
		if("heavy_cell")
			cost = 2500
			package_paths = list(/obj/item/gun/ballistic/shotgun/cyberpunk/room_clearer, /obj/item/grenade/smokebomb)
	if(!cost || !length(package_paths))
		return
	var/datum/bank_account/account = user.get_bank_account()
	if(!account || !account.adjust_money(-cost, "Black market order"))
		to_chat(user, span_warning("Not enough credits."))
		return
	drop_turf = get_safe_random_station_turf() || get_turf(user)
	ordered_paths = package_paths
	ordered = TRUE
	to_chat(user, span_boldnotice("Drop marked at [drop_turf.x], [drop_turf.y], [drop_turf.z]. Reach it and use the chip again."))

/obj/item/cyberpunk_black_market_chip/proc/claim_drop(mob/living/user)
	if(!drop_turf)
		ordered = FALSE
		return
	if(get_dist(user, drop_turf) > 1 || user.z != drop_turf.z)
		to_chat(user, span_warning("Drop coordinates: [drop_turf.x], [drop_turf.y], [drop_turf.z]."))
		return
	for(var/item_path in ordered_paths)
		var/obj/item/delivered = new item_path(drop_turf)
		ADD_TRAIT(delivered, TRAIT_CONTRABAND, "cp_market_stock")
	to_chat(user, span_notice("A small black market capsule cracks open."))
	ordered = FALSE
	drop_turf = null
	ordered_paths = list()

/obj/item/cyberpunk_spy_uplink_chip
	name = "spy task chip"
	desc = "A hidden corporate task buffer."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk1"
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/owner_ref

/obj/item/cyberpunk_spy_uplink_chip/attack_self(mob/living/user)
	ui_interact(user)

/obj/item/cyberpunk_spy_uplink_chip/proc/get_spy_for_user(mob/living/user)
	var/datum/antagonist/cyberpunk/corporate_spy/spy = owner_ref?.resolve()
	if(!spy || spy.owner?.current != user)
		return null
	return spy

/obj/item/cyberpunk_spy_uplink_chip/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/corporate_spy/spy = get_spy_for_user(living_user)
	if(!spy)
		to_chat(user, span_warning("The chip rejects you."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkAntagChip", name)
		ui.open()

/obj/item/cyberpunk_spy_uplink_chip/ui_data(mob/user)
	var/list/data = list()
	if(!isliving(user))
		data["valid"] = FALSE
		return data
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/corporate_spy/spy = get_spy_for_user(living_user)
	if(!spy)
		data["valid"] = FALSE
		return data

	if(!length(spy.spy_tasks))
		spy.refresh_tasks()
	var/list/tasks = list()
	for(var/datum/cyberpunk_spy_task/task in spy.spy_tasks)
		tasks += list(list("text" = "[task.completed ? "✓ " : ""][task.description]"))

	data["valid"] = TRUE
	data["mode"] = "spy"
	data["title"] = "Spy Tasks"
	data["subtitle"] = name
	data["briefing"] = "Cover: [spy.cover_corporation_id || "unknown"]. True employer: [spy.real_corporation_id || "unknown"]."
	data["progress"] = spy.progress_points
	data["goal"] = spy.progress_goal
	data["complete"] = spy.goal_completed
	data["tasks"] = tasks
	data["completedToday"] = spy.completed_tasks_today
	data["actions"] = list(\
		list("id" = "upload", "label" = "Сдать результаты", "description" = "Проверить результаты всех трёх поручений."), \
		list("id" = "uplink", "label" = "Аплинк трейтора", "description" = "1 ТК = 250 кредитов."), \
	)
	return data

/obj/item/cyberpunk_spy_uplink_chip/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!isliving(usr))
		return TRUE
	var/mob/living/user = usr
	var/datum/antagonist/cyberpunk/corporate_spy/spy = get_spy_for_user(user)
	if(!spy)
		return TRUE

	switch(action)
		if("run_action")
			if(params["id"] == "upload")
				spy.complete_task(user)
			if(params["id"] == "uplink")
				spy.purchase_supplies(user, src)
			return TRUE
		if("refresh")
			return TRUE

/obj/item/cyberpunk_anarchist_chip
	name = "anarchist neural hook"
	desc = "A crude recruiter for neural-interface users."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk2"
	w_class = WEIGHT_CLASS_TINY
	var/datum/weakref/owner_ref

/obj/item/cyberpunk_anarchist_chip/attack_self(mob/living/user)
	ui_interact(user)

/obj/item/cyberpunk_anarchist_chip/proc/get_anarchist_for_user(mob/living/user)
	var/datum/antagonist/cyberpunk/anarchist/anarchist = owner_ref?.resolve()
	if(!anarchist || anarchist.owner?.current != user)
		return null
	return anarchist

/obj/item/cyberpunk_anarchist_chip/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/anarchist/anarchist = get_anarchist_for_user(living_user)
	if(!anarchist)
		to_chat(user, span_warning("The chip rejects you."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkAntagChip", name)
		ui.open()

/obj/item/cyberpunk_anarchist_chip/ui_data(mob/user)
	var/list/data = list()
	if(!isliving(user))
		data["valid"] = FALSE
		return data
	var/mob/living/living_user = user
	var/datum/antagonist/cyberpunk/anarchist/anarchist = get_anarchist_for_user(living_user)
	if(!anarchist)
		data["valid"] = FALSE
		return data

	var/datum/team/cyberpunk_anarchists/team = anarchist.get_team()
	data["valid"] = TRUE
	data["mode"] = "anarchist"
	data["title"] = "Anarchist Hook"
	data["subtitle"] = name
	data["briefing"] = "Recruit neural-interface users or mark nearby machinery and structures as sabotage."
	data["progress"] = anarchist.progress_points
	data["goal"] = anarchist.progress_goal
	data["complete"] = anarchist.goal_completed
	data["team"] = team?.name
	data["damageScore"] = team?.damage_score || 0
	data["intel"] = team?.intel || 0
	data["actions"] = list(
		list("id" = "recruit", "label" = "Recruit neural target", "description" = "Минута местной речи в пределах двух клеток. Удар или толчок сбивает попытку."),
		list("id" = "sabotage", "label" = "Цель погрома", "description" = "Выберите корпоративный объект и уничтожьте его."),
		list("id" = "armory", "label" = "Аплинк нюкеров", "description" = "1 ТК = 5 разведданных."),
		list("id" = "tasks", "label" = "Задания ячейки", "description" = "Подобрать цели для погрома, устранения и кражи."),
	)
	return data

/obj/item/cyberpunk_anarchist_chip/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!isliving(usr))
		return TRUE
	var/mob/living/user = usr
	var/datum/antagonist/cyberpunk/anarchist/anarchist = get_anarchist_for_user(user)
	if(!anarchist)
		return TRUE

	switch(action)
		if("run_action")
			var/action_id = params["id"]
			if(action_id == "armory")
				anarchist.purchase_armory(user, src)
				return TRUE
			if(action_id == "tasks")
				anarchist.generate_pogrom(user)
				return TRUE
			if(action_id == "sabotage")
				var/list/sabotage_targets = list()
				for(var/obj/nearby in view(1, user))
					var/corporation = cyberpunk_antag_corporation(nearby)
					if(nearby.uses_integrity && (corporation in list("benn", "ryaznov", "starlight")))
						sabotage_targets["[nearby.name] · [corporation] · [REF(nearby)]"] = nearby
				var/choice = tgui_input_list(user, "Выберите цель.", "Погром", sabotage_targets)
				var/obj/sabotage_target = sabotage_targets[choice]
				if(sabotage_target)
					anarchist.mark_sabotage(user, sabotage_target)
				return TRUE
			if(action_id == "recruit")
				var/list/targets = list()
				for(var/mob/living/nearby in view(2, user))
					if(nearby == user || !nearby.mind)
						continue
					targets += nearby
				var/mob/living/target = tgui_input_list(user, "Choose a target to recruit.", "Anarchist Recruitment", targets)
				if(target)
					anarchist.convert_target(user, target)
				return TRUE
		if("refresh")
			return TRUE
