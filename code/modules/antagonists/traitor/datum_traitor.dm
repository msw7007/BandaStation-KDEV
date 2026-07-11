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
	var/list/sabotaged_refs = list()
	var/damage_score = 0

/datum/team/cyberpunk_anarchists/proc/record_sabotage(atom/target, amount = 250)
	if(!target)
		return FALSE
	var/target_ref = REF(target)
	if(target_ref in sabotaged_refs)
		return FALSE
	sabotaged_refs += target_ref
	damage_score += amount
	get_cyberpunk_faction_resources().add_resource("influence", amount)
	return TRUE

/datum/team/cyberpunk_liberation_army
	name = "Liberation Army"
	var/list/established_cells = list()

/datum/team/cyberpunk_data_cult
	name = "Data Cult"
	var/list/harvested_refs = list()

/datum/team/cyberpunk_star_swarm
	name = "Starlight Swarm"
	var/list/pylon_refs = list()

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
	var/last_synced_account_balance = 0

/datum/antagonist/cyberpunk/bandit/create_team(datum/team/new_team)
	if(istype(new_team, /datum/team/cyberpunk_gang))
		gang = new_team
		return
	var/static/list/gangs
	if(!gangs)
		gangs = list(
			new /datum/team/cyberpunk_gang(null, "Chrome Rats"),
			new /datum/team/cyberpunk_gang(null, "Red Line"),
			new /datum/team/cyberpunk_gang(null, "Null Saints"),
		)
	gang = pick(gangs)

/datum/antagonist/cyberpunk/bandit/get_team()
	return gang

/datum/antagonist/cyberpunk/bandit/on_gain()
	. = ..()
	var/obj/item/cyberpunk_black_market_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	owner.current.put_in_hands(chip)
	var/datum/bank_account/account = owner.current.get_bank_account()
	last_synced_account_balance = account?.account_balance || 0
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

/datum/antagonist/cyberpunk/bandit/proc/sync_dirty_money(mob/living/user)
	var/datum/bank_account/account = user.get_bank_account()
	if(!account)
		to_chat(user, span_warning("No bank account found."))
		return FALSE
	var/new_money = max(account.account_balance - last_synced_account_balance, 0)
	last_synced_account_balance = account.account_balance
	if(!new_money)
		to_chat(user, span_warning("No new money to launder into gang progress."))
		return FALSE
	add_progress(new_money, "dirty money")
	gang?.get_cyberpunk_faction_resources().add_resource("funds", new_money)
	return TRUE

/datum/antagonist/cyberpunk/bandit/proc/show_gang_status(mob/living/user)
	var/list/member_names = list()
	for(var/datum/mind/member as anything in gang?.members)
		member_names += member.name
	to_chat(user, span_notice("Gang: [gang?.gang_name || "none"]. Members: [length(member_names) ? member_names.Join(", ") : "none"]. Funds progress: [progress_points]/[progress_goal]."))

/datum/antagonist/cyberpunk/bandit/proc/configure_gang(mob/living/user)
	var/list/options = list("Chrome Rats", "Red Line", "Null Saints", "Create custom gang", "Cancel")
	var/choice = tgui_input_list(user, "Choose or create a gang.", "Gang Setup", options)
	if(!choice || choice == "Cancel")
		return FALSE
	if(choice == "Create custom gang")
		var/custom_name = tgui_input_text(user, "Gang name", "Gang Setup", gang?.gang_name || "Free gang", max_length = 32)
		if(!custom_name)
			return FALSE
		gang = new /datum/team/cyberpunk_gang(null, custom_name)
	else
		gang = new /datum/team/cyberpunk_gang(null, choice)
	gang.add_member(owner)
	to_chat(user, span_notice("Gang set to [gang.gang_name]."))
	return TRUE

/datum/antagonist/cyberpunk/corporate_spy
	name = "Corporate Spy"
	pref_flag = ROLE_CYBERPUNK_CORPORATE_SPY
	antag_hud_name = "traitor"
	progress_goal = 300
	var/real_corporation_id
	var/cover_corporation_id
	var/next_task_refresh = 0
	var/current_task_day = 0
	var/completed_tasks_today = 0
	var/list/spy_tasks = list()

/datum/antagonist/cyberpunk/corporate_spy/on_gain()
	pick_corporations()
	refresh_tasks()
	. = ..()
	var/obj/item/cyberpunk_spy_uplink_chip/chip = new(get_turf(owner.current))
	chip.owner_ref = WEAKREF(src)
	owner.current.put_in_hands(chip)

/datum/antagonist/cyberpunk/corporate_spy/proc/pick_corporations()
	var/list/corporations = list("benn", "ryaznov", "starlight")
	cover_corporation_id = owner.assigned_role?.get_cyberpunk_corporation_id()
	real_corporation_id = pick(corporations - cover_corporation_id)
	if(!real_corporation_id)
		real_corporation_id = pick(corporations)

/datum/antagonist/cyberpunk/corporate_spy/proc/refresh_tasks()
	current_task_day = SScyberpunk_round?.cyberpunk_round_day || current_task_day || 1
	completed_tasks_today = 0
	spy_tasks = list(
		"Disable one important asset of [cover_corporation_id || "your cover corporation"].",
		"Steal or photograph a research item.",
		"Remove one useful employee from work without revealing yourself.",
	)
	next_task_refresh = world.time + 30 MINUTES

/datum/antagonist/cyberpunk/corporate_spy/proc/complete_task(mob/living/user)
	var/day_now = SScyberpunk_round?.cyberpunk_round_day || current_task_day || 1
	if(day_now != current_task_day || world.time >= next_task_refresh)
		refresh_tasks()
	if(completed_tasks_today >= length(spy_tasks))
		to_chat(user, span_warning("No remaining spy tasks in today's packet."))
		return FALSE
	completed_tasks_today++
	add_progress(25, "spy task")
	SScyberpunk_corporations?.record_cyberpunk_corporate_activity(real_corporation_id, "espionage", 25, 0, "Corporate spy task")
	to_chat(user, span_notice("Task uploaded to [real_corporation_id]. Remaining today: [max(length(spy_tasks) - completed_tasks_today, 0)]."))
	return TRUE

/datum/antagonist/cyberpunk/corporate_spy/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("You are secretly working for [real_corporation_id]. Your cover corporation is [cover_corporation_id || "unknown"]. Use the spy chip to review and upload tasks."))

/datum/antagonist/cyberpunk/anarchist
	name = "Anarchist"
	pref_flag = ROLE_CYBERPUNK_ANARCHIST
	antag_hud_name = "rev"
	progress_goal = 10000
	var/datum/team/cyberpunk_anarchists/anarchist_team

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

/datum/antagonist/cyberpunk/anarchist/proc/convert_target(mob/living/user, mob/living/target)
	if(!target?.mind || target.stat == DEAD)
		return FALSE
	if(target.mind.has_antag_datum(/datum/antagonist/cyberpunk/anarchist))
		to_chat(user, span_warning("[target] is already with you."))
		return FALSE
	if(!target.has_neural_implant())
		to_chat(user, span_warning("[target] has no functional neural interface."))
		return FALSE
	user.visible_message(span_warning("[user] starts a silent neural overwrite on [target]."), span_notice("You start the two minute overwrite. Do not move."))
	if(!do_after(user, 2 MINUTES, target = target))
		to_chat(user, span_warning("The overwrite was interrupted."))
		return FALSE
	var/datum/antagonist/cyberpunk/anarchist/new_anarchist = new()
	new_anarchist.silent = TRUE
	target.mind.add_antag_datum(new_anarchist, anarchist_team)
	to_chat(target, span_userdanger("The city hierarchy becomes intolerable. You are an anarchist now."))
	add_progress(100, "recruitment")
	return TRUE

/datum/antagonist/cyberpunk/anarchist/proc/mark_sabotage(mob/living/user, obj/target)
	if(!target)
		return FALSE
	if(REF(target) in anarchist_team.sabotaged_refs)
		to_chat(user, span_warning("[target] is already counted."))
		return FALSE
	user.visible_message(span_warning("[user] tampers with [target]."), span_notice("You start marking sabotage. Hold still."))
	if(!do_after(user, 10 SECONDS, target = target))
		to_chat(user, span_warning("Sabotage marking interrupted."))
		return FALSE
	if(!anarchist_team.record_sabotage(target))
		to_chat(user, span_warning("[target] is already counted."))
		return FALSE
	add_progress(250, "sabotage")
	to_chat(user, span_notice("Sabotage logged. Team damage score: [anarchist_team.damage_score]."))
	return TRUE

/datum/antagonist/cyberpunk/anarchist/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("Damage corporations and government. Anarchists see each other. Use the chip to recruit neural-interface users: two minutes, interrupted by movement."))

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

/datum/antagonist/cyberpunk/major/benn_shifter
	name = "Benn Shifter"
	pref_flag = ROLE_CYBERPUNK_BENN_SHIFTER
	progress_goal = 6
	chip_name = "viral phenotype key"
	chip_desc = "A Benn covert infection controller."
	primary_action = "Seed infection"
	primary_points = 1
	primary_delay = 15 SECONDS
	primary_reason = "infection"
	primary_target_prompt = "Choose a nearby living victim."
	role_briefing = "Seed infections into living victims. After 15 minutes, untreated victims convert into new shifters. You can also rend victims and regenerate."
	var/list/infected_refs = list()

/datum/antagonist/cyberpunk/major/benn_shifter/get_chip_options(mob/living/user)
	return list(primary_action, "Rend victim", "Regenerate", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/benn_shifter/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Rend victim")
			return direct_damage(user, choose_living_target(user, 1, "Choose nearby victim."), 25, BRUTE, "rend")
		if("Regenerate")
			user.heal_ordered_damage(20, list(BRUTE, BURN, TOX, OXY))
			to_chat(user, span_notice("Your unstable tissue knits itself together."))
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/benn_shifter/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user && nearby.stat != DEAD)
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/benn_shifter/perform_primary_action(mob/living/user)
	var/list/targets = get_primary_targets(user)
	var/mob/living/target = tgui_input_list(user, primary_target_prompt, name, targets)
	if(!target)
		return FALSE
	var/target_ref = REF(target)
	if(target_ref in infected_refs)
		to_chat(user, span_warning("[target] is already infected."))
		return FALSE
	user.visible_message(span_warning("[user] injects something into [target]."), span_notice("You start seeding the infection. Hold still."))
	if(!do_after(user, primary_delay, target = target))
		to_chat(user, span_warning("The infection was interrupted."))
		return FALSE
	infected_refs += target_ref
	add_progress(primary_points, primary_reason)
	to_chat(target, span_userdanger("Something cold spreads under your skin."))
	addtimer(CALLBACK(src, PROC_REF(finish_infection), WEAKREF(target)), 15 MINUTES)
	return TRUE

/datum/antagonist/cyberpunk/major/benn_shifter/proc/finish_infection(datum/weakref/target_ref)
	var/mob/living/target = target_ref?.resolve()
	if(!target?.mind || target.stat == DEAD)
		return FALSE
	if(target.mind.has_antag_datum(/datum/antagonist/cyberpunk/major/benn_shifter))
		return FALSE
	var/datum/antagonist/cyberpunk/major/benn_shifter/new_shifter = new()
	new_shifter.silent = TRUE
	target.mind.add_antag_datum(new_shifter)
	to_chat(target, span_userdanger("The infection finishes rewriting you. You are part of the Benn strain now."))
	return TRUE

/datum/antagonist/cyberpunk/major/benn_shifter/extra_roundend_report()
	return "[..()]<br>Seeded infections: [length(infected_refs)]."

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

/datum/antagonist/cyberpunk/major/benn_prototype/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user)
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/benn_prototype/get_chip_options(mob/living/user)
	return list(primary_action, "Unlock mutation", "Use mutation", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/benn_prototype/handle_chip_option(mob/living/user, choice)
	if(choice == "Unlock mutation")
		return unlock_mutation(user)
	if(choice == "Use mutation")
		return use_mutation(user)
	return ..()

/datum/antagonist/cyberpunk/major/benn_prototype/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		dna_points++
		to_chat(user, span_notice("DNA point gained. Available: [dna_points]."))

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
			return direct_damage(user, choose_living_target(user, 1, "Choose claw target."), 35, BRUTE, "claws")
		if("whip")
			return direct_damage(user, choose_living_target(user, 4, "Choose whip target."), 20, STAMINA, "whip")
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
	add_progress(1, "mutation")
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
	primary_target_prompt = "Choose nearby biomass or infrastructure."
	role_briefing = "Assimilate biomass, grow flesh, spawn blobbernauts, and reach critical mass. Critical mass starts a two-minute nuclear purge countdown."

/datum/antagonist/cyberpunk/major/benn_evolutionary/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		new /obj/structure/cyberpunk_flesh_growth(get_turf(user))

/datum/antagonist/cyberpunk/major/benn_evolutionary/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("A Benn evolutionary mass has reached critical growth. Nuclear purge impact in two minutes.", "City Threat Monitor", sender_override = "Starlight City Network")
	addtimer(CALLBACK(src, PROC_REF(evolutionary_nuclear_strike)), 2 MINUTES)

/datum/antagonist/cyberpunk/major/benn_evolutionary/proc/evolutionary_nuclear_strike()
	var/turf/strike_turf = get_turf(owner?.current)
	if(!strike_turf)
		return FALSE
	priority_announce("Nuclear purge impact confirmed.", "City Threat Monitor", sender_override = "Starlight City Network")
	explosion(strike_turf, devastation_range = 8, heavy_impact_range = 16, light_impact_range = 32, flame_range = 24, flash_range = 32, ignorecap = TRUE, explosion_cause = owner?.current)
	return TRUE

/datum/antagonist/cyberpunk/major/benn_evolutionary/get_chip_options(mob/living/user)
	return list(primary_action, "Grow flesh ring", "Spawn blobbernaut", "Call blobbernaut ghost", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/benn_evolutionary/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Grow flesh ring")
			for(var/turf/open/open_turf in range(1, user))
				new /obj/structure/cyberpunk_flesh_growth(open_turf)
			add_progress(6, "flesh ring")
			return TRUE
		if("Spawn blobbernaut")
			return spawn_antag_asset(user, /mob/living/basic/blob_minion/blobbernaut/independent, "blobbernaut", 5)
		if("Call blobbernaut ghost")
			return summon_ghost_asset(user, /mob/living/basic/blob_minion/blobbernaut/independent, "Benn blobbernaut", 5)
	return ..()

/datum/antagonist/cyberpunk/major/wild_iskin
	name = "Wild ISKIN"
	pref_flag = ROLE_CYBERPUNK_WILD_ISKIN
	progress_goal = 20
	chip_name = "wild iskin trace"
	chip_desc = "A local trace for network predation."
	primary_action = "Devour node"
	primary_points = 1
	primary_delay = 10 SECONDS
	primary_reason = "node"
	primary_target_prompt = "Choose nearby machinery."
	role_briefing = "Devour machinery as network nodes, create shrouds, burn neural-interface targets, and call trace demons."

/datum/antagonist/cyberpunk/major/wild_iskin/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/machinery/nearby in view(1, user))
		targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/wild_iskin/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		new /obj/structure/cyberpunk_network_shroud(get_turf(user))

/datum/antagonist/cyberpunk/major/wild_iskin/get_chip_options(mob/living/user)
	return list(primary_action, "Burn neural target", "Spawn trace demon", "Call trace ghost", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/wild_iskin/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Burn neural target")
			var/mob/living/target = choose_living_target(user, 4, "Choose neural target.")
			if(!target?.has_neural_implant())
				to_chat(user, span_warning("Target has no neural interface."))
				return FALSE
			return direct_damage(user, target, 25, BURN, "neural burn")
		if("Spawn trace demon")
			return spawn_antag_asset(user, /mob/living/basic/cyberspace_alternative, "trace demon", 2)
		if("Call trace ghost")
			return summon_ghost_asset(user, /mob/living/basic/cyberspace_alternative, "wild ISKIN trace demon", 2)
	return ..()

/datum/antagonist/cyberpunk/major/rogue_ai
	name = "Rogue AI"
	pref_flag = ROLE_CYBERPUNK_ROGUE_AI
	progress_goal = 70
	chip_name = "rogue ai command shard"
	chip_desc = "A shard of a broken city intelligence."
	primary_action = "Subvert system"
	primary_points = 2
	primary_delay = 10 SECONDS
	primary_reason = "subversion"
	primary_target_prompt = "Choose nearby machinery or neural target."
	role_briefing = "Subvert machinery and neural targets. You can hijack drones, call ghost drones, and immobilize neural-interface victims."

/datum/antagonist/cyberpunk/major/rogue_ai/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/machinery/nearby in view(1, user))
		targets += nearby
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user && nearby.has_neural_implant())
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/rogue_ai/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		SScyberpunk_round?.record_cyberpunk_district_violence(get_area_name(get_turf(user), TRUE), 1, "rogue ai subversion")

/datum/antagonist/cyberpunk/major/rogue_ai/get_chip_options(mob/living/user)
	return list(primary_action, "Hijack drone", "Call ghost drone", "Neural command", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/rogue_ai/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Hijack drone")
			return spawn_antag_asset(user, /mob/living/basic/drone/syndrone, "hijacked drone", 3)
		if("Call ghost drone")
			return summon_ghost_asset(user, /mob/living/basic/drone/syndrone, "rogue AI drone", 3)
		if("Neural command")
			var/mob/living/target = choose_living_target(user, 4, "Choose neural target.")
			if(!target?.has_neural_implant())
				to_chat(user, span_warning("Target has no neural interface."))
				return FALSE
			target.Immobilize(5 SECONDS)
			return direct_damage(user, target, 20, STAMINA, "neural command")
	return ..()

/datum/antagonist/cyberpunk/major/rogue_ai/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("A rogue city intelligence has reached mass subversion threshold.", "City Network", sender_override = "Starlight City Network")
	for(var/mob/living/nearby in view(7, owner?.current))
		if(nearby.has_neural_implant())
			nearby.Immobilize(10 SECONDS)

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

/datum/antagonist/cyberpunk/major/combat_synthetic/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/machinery/nearby in view(1, user))
		targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/combat_synthetic/get_chip_options(mob/living/user)
	return list(primary_action, "Unlock combat mode", "Use combat mode", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/combat_synthetic/handle_chip_option(mob/living/user, choice)
	if(choice == "Unlock combat mode")
		return unlock_combat_mode(user)
	if(choice == "Use combat mode")
		return use_combat_mode(user)
	return ..()

/datum/antagonist/cyberpunk/major/combat_synthetic/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		energy_points++
		to_chat(user, span_notice("Stored synthetic energy: [energy_points]."))

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
			return direct_damage(user, choose_living_target(user, 1, "Choose strike target."), 45, BRUTE, "overcharge")
		if("ballistic calculation")
			new /obj/item/gun/ballistic/automatic/pistol/cyberpunk/handcannon(get_turf(user))
		if("damage dampening")
			user.heal_ordered_damage(40, list(BRUTE, BURN))
	add_progress(3, "combat mode")
	return TRUE

/datum/antagonist/cyberpunk/major/combat_synthetic/extra_roundend_report()
	return "[..()]<br>Stored energy: [energy_points]. Combat modes: [length(combat_modes) ? combat_modes.Join(", ") : "none"]."

/datum/antagonist/cyberpunk/major/starlight_swarm
	name = "Starlight Swarm"
	pref_flag = ROLE_CYBERPUNK_STARLIGHT_SWARM
	progress_goal = 10000
	chip_name = "photon swarm core"
	chip_desc = "A Starlight energy swarm anchor."
	primary_action = "Harvest energy"
	primary_points = 100
	primary_delay = 8 SECONDS
	primary_reason = "energy"
	primary_target_prompt = "Choose nearby victim or power source."
	role_briefing = "Harvest energy, place pylons, fight in photon form, place photon turrets, and call swarm ghosts."
	team_type = /datum/team/cyberpunk_star_swarm

/datum/antagonist/cyberpunk/major/starlight_swarm/get_chip_options(mob/living/user)
	return list(primary_action, "Place pylon", "Photon form", "Place photon turret", "Call swarm ghost", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/starlight_swarm/handle_chip_option(mob/living/user, choice)
	if(choice == "Place pylon")
		return place_pylon(user)
	if(choice == "Photon form")
		return direct_damage(user, choose_living_target(user, 1, "Choose photon target."), 30, BURN, "photon form")
	if(choice == "Place photon turret")
		return spawn_antag_asset(user, /obj/structure/cyberpunk_photon_turret, "photon turret", 500)
	if(choice == "Call swarm ghost")
		return summon_ghost_asset(user, /mob/living/basic/cyberspace_alternative, "Starlight swarm wisp", 250)
	return ..()

/datum/antagonist/cyberpunk/major/starlight_swarm/proc/place_pylon(mob/living/user)
	var/datum/team/cyberpunk_star_swarm/swarm_team = get_team()
	var/turf/location = get_turf(user)
	var/location_ref = REF(location)
	if(location_ref in swarm_team.pylon_refs)
		to_chat(user, span_warning("A pylon is already anchored here."))
		return FALSE
	if(!do_after(user, 15 SECONDS, target = user))
		to_chat(user, span_warning("Pylon placement interrupted."))
		return FALSE
	swarm_team.pylon_refs += location_ref
	new /obj/structure/cyberpunk_swarm_pylon(location)
	add_progress(250, "pylon")
	return TRUE

/datum/antagonist/cyberpunk/major/starlight_swarm/extra_roundend_report()
	var/datum/team/cyberpunk_star_swarm/swarm_team = get_team()
	return "[..()]<br>Pylons placed: [length(swarm_team?.pylon_refs)]."

/datum/antagonist/cyberpunk/major/starlight_swarm/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("A Starlight energy swarm has accumulated a critical clean-energy reserve.", "City Threat Monitor", sender_override = "Starlight City Network")
	for(var/obj/structure/cyberpunk_swarm_pylon/pylon in world)
		new /obj/structure/cyberpunk_photon_turret(get_turf(pylon))

/datum/antagonist/cyberpunk/major/transformer
	name = "Transformer"
	pref_flag = ROLE_CYBERPUNK_TRANSFORMER
	progress_goal = 5
	chip_name = "transformer spark"
	chip_desc = "A machine-awakening spark."
	primary_action = "Awaken machine"
	primary_points = 1
	primary_delay = 15 SECONDS
	primary_reason = "awakening"
	primary_target_prompt = "Choose nearby machinery or vehicle."
	role_briefing = "Awaken machines. After five awakenings, place an autossembler; use weapon forms and call machine ghosts."
	var/awakened_count = 0

/datum/antagonist/cyberpunk/major/transformer/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/nearby in view(1, user))
		if(istype(nearby, /obj/machinery) || istype(nearby, /obj/vehicle))
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/transformer/get_chip_options(mob/living/user)
	var/list/options = list(primary_action)
	if(awakened_count >= 5)
		options += "Place autossembler"
	options += "Transform weapon"
	options += "Call machine ghost"
	options += "Status"
	options += "Cancel"
	return options

/datum/antagonist/cyberpunk/major/transformer/handle_chip_option(mob/living/user, choice)
	if(choice == "Place autossembler")
		return place_autossembler(user)
	if(choice == "Transform weapon")
		var/chosen = tgui_input_list(user, "Choose integrated weapon.", "Transformer Weapon", list("laser", "ion", "plasma", "Cancel"))
		if(!chosen || chosen == "Cancel")
			return FALSE
		switch(chosen)
			if("laser")
				new /obj/item/gun/energy/laser/cyberpunk/radiant(get_turf(user))
			if("ion")
				new /obj/item/grenade/empgrenade(get_turf(user))
			if("plasma")
				new /obj/item/gun/energy/laser/cyberpunk/plasma(get_turf(user))
		add_progress(1, "weapon")
		return TRUE
	if(choice == "Call machine ghost")
		return summon_ghost_asset(user, /mob/living/basic/drone/syndrone, "awakened transformer machine", 1)
	return ..()

/datum/antagonist/cyberpunk/major/transformer/perform_primary_action(mob/living/user)
	. = ..()
	if(.)
		awakened_count++
		new /obj/structure/cyberpunk_awakened_machine(get_turf(user))

/datum/antagonist/cyberpunk/major/transformer/proc/place_autossembler(mob/living/user)
	if(!do_after(user, 20 SECONDS, target = user))
		to_chat(user, span_warning("Autossembler placement interrupted."))
		return FALSE
	new /obj/structure/cyberpunk_autossembler(get_turf(user))
	add_progress(2, "autossembler")
	return TRUE

/datum/antagonist/cyberpunk/major/transformer/extra_roundend_report()
	return "[..()]<br>Machines awakened: [awakened_count]."

/datum/antagonist/cyberpunk/major/broker
	name = "Broker"
	pref_flag = ROLE_CYBERPUNK_BROKER
	progress_goal = 3
	chip_name = "broker anchor key"
	chip_desc = "A dimensional anchor authorizer."
	primary_action = "Place anchor"
	primary_points = 1
	primary_delay = 20 SECONDS
	primary_reason = "anchor"
	primary_target_prompt = "Choose nearby anchor point."
	role_briefing = "Place three breach anchors. Use nanite breaches, call nanite ghosts, and deploy broker mech weapons."
	var/list/anchor_refs = list()

/datum/antagonist/cyberpunk/major/broker/perform_primary_action(mob/living/user)
	var/turf/location = get_turf(user)
	var/location_ref = REF(location)
	if(location_ref in anchor_refs)
		to_chat(user, span_warning("An anchor is already placed here."))
		return FALSE
	if(!do_after(user, primary_delay, target = user))
		to_chat(user, span_warning("Anchor placement interrupted."))
		return FALSE
	anchor_refs += location_ref
	new /obj/structure/cyberpunk_broker_anchor(location)
	add_progress(primary_points, primary_reason)
	if(progress_points >= progress_goal)
		priority_announce("Three hostile breach anchors are active. Expect nanite incursions.", "City Threat Monitor", sender_override = "Starlight City Network")
	return TRUE

/datum/antagonist/cyberpunk/major/broker/extra_roundend_report()
	return "[..()]<br>Breach anchors: [length(anchor_refs)]/3."

/datum/antagonist/cyberpunk/major/broker/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("Broker breach anchors are stable. Nanite resistance wave incoming.", "City Threat Monitor", sender_override = "Starlight City Network")
	for(var/obj/structure/cyberpunk_broker_anchor/anchor in world)
		for(var/i in 1 to 3)
			new /mob/living/basic/blob_minion/spore/independent(get_turf(anchor))

/datum/antagonist/cyberpunk/major/broker/get_chip_options(mob/living/user)
	return list(primary_action, "Nanite breach", "Call nanite ghost", "Mech weapon", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/broker/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Nanite breach")
			for(var/i in 1 to 3)
				new /mob/living/basic/blob_minion/spore/independent(get_turf(user))
			add_progress(1, "nanites")
			return TRUE
		if("Call nanite ghost")
			return summon_ghost_asset(user, /mob/living/basic/blob_minion/spore/independent, "Broker nanite", 1)
		if("Mech weapon")
			var/chosen = tgui_input_list(user, "Choose broker weapon.", "Broker Arsenal", list("energy sword", "beam gun", "shield pulse", "Cancel"))
			if(!chosen || chosen == "Cancel")
				return FALSE
			switch(chosen)
				if("energy sword")
					new /obj/item/knife/cyberpunk/energy_blade(get_turf(user))
				if("beam gun")
					new /obj/item/gun/energy/laser/cyberpunk/plasma(get_turf(user))
				if("shield pulse")
					user.heal_ordered_damage(60, list(BRUTE, BURN))
			add_progress(1, "mech weapon")
			return TRUE
	return ..()

/datum/antagonist/cyberpunk/major/liberation_army
	name = "Liberation Army"
	pref_flag = ROLE_CYBERPUNK_LIBERATION_ARMY
	progress_goal = 10000
	chip_name = "liberation field tablet"
	chip_desc = "A field tablet for cells, factories, and sabotage accounting."
	primary_action = "Establish cell"
	primary_points = 500
	primary_delay = 20 SECONDS
	primary_reason = "cell"
	primary_target_prompt = "Choose nearby structure for a cell."
	role_briefing = "Build GLA-lite cells, factories, barracks, arms plants, black servers, and tunnel links. Reach the damage threshold to unlock the final bomb-truck phase."
	team_type = /datum/team/cyberpunk_liberation_army

/datum/antagonist/cyberpunk/major/liberation_army/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/structure/nearby in view(1, user))
		targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/liberation_army/perform_primary_action(mob/living/user)
	var/datum/team/cyberpunk_liberation_army/army = get_team()
	var/turf/location = get_turf(user)
	var/location_ref = REF(location)
	if(location_ref in army.established_cells)
		to_chat(user, span_warning("A cell is already established here."))
		return FALSE
	. = ..()
	if(.)
		army.established_cells += location_ref
		new /obj/structure/cyberpunk_liberation_cell(location)

/datum/antagonist/cyberpunk/major/liberation_army/get_chip_options(mob/living/user)
	return list(primary_action, "Build factory", "Build barracks", "Build arms plant", "Build black server", "Build tunnel", "Call volunteer fighter", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/liberation_army/handle_chip_option(mob/living/user, choice)
	switch(choice)
		if("Build factory")
			return build_asset(user, /obj/structure/cyberpunk_liberation_factory, 700, "factory")
		if("Build barracks")
			return build_asset(user, /obj/structure/cyberpunk_liberation_barracks, 500, "barracks")
		if("Build arms plant")
			return build_asset(user, /obj/structure/cyberpunk_liberation_arms_plant, 500, "arms plant")
		if("Build black server")
			return build_asset(user, /obj/structure/cyberpunk_liberation_black_server, 400, "black server")
		if("Build tunnel")
			return build_asset(user, /obj/structure/cyberpunk_liberation_tunnel, 250, "tunnel")
		if("Call volunteer fighter")
			return summon_ghost_asset(user, /mob/living/simple_animal/hostile/asteroid, "Liberation Army volunteer", 500)
	return ..()

/datum/antagonist/cyberpunk/major/liberation_army/proc/build_asset(mob/living/user, asset_type, points, reason)
	if(!action_ready(user, "build_[asset_type]", 45 SECONDS))
		return FALSE
	if(!do_after(user, 20 SECONDS, target = user))
		to_chat(user, span_warning("Construction interrupted."))
		return FALSE
	new asset_type(get_turf(user))
	add_progress(points, reason)
	get_team()?.get_cyberpunk_faction_resources().add_resource("supplies", points)
	return TRUE

/datum/antagonist/cyberpunk/major/liberation_army/extra_roundend_report()
	var/datum/team/cyberpunk_liberation_army/army = get_team()
	return "[..()]<br>Established cells: [length(army?.established_cells)]."

/datum/antagonist/cyberpunk/major/liberation_army/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("Liberation Army damage threshold reached. Final bomb-truck phase authorized.", "City Threat Monitor", sender_override = "Starlight City Network")
	var/turf/drop_turf = get_turf(owner?.current)
	if(drop_turf)
		new /obj/vehicle/ridden/atv(drop_turf)
		new /obj/item/grenade/c4/x4(drop_turf)
		new /obj/item/gun/ballistic/rocketlauncher/cyberpunk(drop_turf)

/datum/antagonist/cyberpunk/major/data_cult
	name = "Data Cult"
	pref_flag = ROLE_CYBERPUNK_DATA_CULT
	progress_goal = 5000
	chip_name = "data cult cipher"
	chip_desc = "A sci-fi cult cipher powered by stolen data."
	primary_action = "Harvest data"
	primary_points = 250
	primary_delay = 10 SECONDS
	primary_reason = "data"
	primary_target_prompt = "Choose nearby data source."
	role_briefing = "Harvest machinery and neural-interface users for data. Induct neural targets and reach critical stolen-data threshold."
	team_type = /datum/team/cyberpunk_data_cult

/datum/antagonist/cyberpunk/major/data_cult/get_primary_targets(mob/living/user)
	var/list/targets = list()
	for(var/obj/machinery/nearby in view(1, user))
		targets += nearby
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user && nearby.has_neural_implant())
			targets += nearby
	return targets

/datum/antagonist/cyberpunk/major/data_cult/get_chip_options(mob/living/user)
	return list(primary_action, "Induct neural target", "Status", "Cancel")

/datum/antagonist/cyberpunk/major/data_cult/handle_chip_option(mob/living/user, choice)
	if(choice == "Induct neural target")
		return induct_target(user)
	return ..()

/datum/antagonist/cyberpunk/major/data_cult/perform_primary_action(mob/living/user)
	var/datum/team/cyberpunk_data_cult/cult_team = get_team()
	var/list/targets = get_primary_targets(user)
	var/atom/target = tgui_input_list(user, primary_target_prompt, name, targets)
	if(!target)
		return FALSE
	var/target_ref = REF(target)
	if(target_ref in cult_team.harvested_refs)
		to_chat(user, span_warning("[target] is already harvested."))
		return FALSE
	user.visible_message(span_warning("[user] runs a cipher through [target]."), span_notice("You begin harvesting data. Hold still."))
	if(!do_after(user, primary_delay, target = target))
		to_chat(user, span_warning("Harvest interrupted."))
		return FALSE
	cult_team.harvested_refs += target_ref
	add_progress(primary_points, primary_reason)
	cult_team.get_cyberpunk_faction_resources().add_resource("influence", primary_points * 2)
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/proc/induct_target(mob/living/user)
	var/list/targets = list()
	for(var/mob/living/nearby in view(1, user))
		if(nearby != user && nearby.mind && nearby.has_neural_implant() && !nearby.mind.has_antag_datum(/datum/antagonist/cyberpunk/major/data_cult))
			targets += nearby
	var/mob/living/target = tgui_input_list(user, "Choose neural target.", "Data Cult Induction", targets)
	if(!target)
		return FALSE
	if(!do_after(user, 30 SECONDS, target = target))
		to_chat(user, span_warning("Induction interrupted."))
		return FALSE
	var/datum/antagonist/cyberpunk/major/data_cult/new_cultist = new()
	new_cultist.silent = TRUE
	target.mind.add_antag_datum(new_cultist, get_team())
	add_progress(500, "induction")
	to_chat(target, span_userdanger("The Data Cult opens inside your neural interface."))
	return TRUE

/datum/antagonist/cyberpunk/major/data_cult/extra_roundend_report()
	var/datum/team/cyberpunk_data_cult/cult_team = get_team()
	return "[..()]<br>Harvested sources: [length(cult_team?.harvested_refs)]."

/datum/antagonist/cyberpunk/major/data_cult/on_goal_completed(reason = "progress")
	. = ..()
	priority_announce("A Data Cult has reached a critical stolen-data threshold.", "City Network", sender_override = "Starlight City Network")
	for(var/mob/living/nearby in view(5, owner?.current))
		if(nearby.has_neural_implant())
			nearby.apply_damage(20, BRAIN)

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
	var/next_fire_at = 0

/obj/structure/cyberpunk_photon_turret/attack_hand(mob/living/user, list/modifiers)
	. = ..()
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
	next_fire_at = world.time + 20 SECONDS
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
	name = "autossembler"
	desc = "A crude autossembler for awakened machines."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk5"
	density = TRUE
	var/next_assembly_at = 0

/obj/structure/cyberpunk_autossembler/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(world.time < next_assembly_at)
		to_chat(user, span_warning("[src] is assembling for [DisplayTimeText(next_assembly_at - world.time)]."))
		return
	var/choice = tgui_input_list(user, "Choose assembly.", "Autossembler", list("speedbike", "repair drone", "Cancel"))
	if(choice == "speedbike")
		new /obj/vehicle/ridden/speedbike(get_turf(src))
	if(choice == "repair drone")
		new /mob/living/basic/bot/repairbot(get_turf(src))
	if(choice && choice != "Cancel")
		next_assembly_at = world.time + 45 SECONDS

/obj/structure/cyberpunk_broker_anchor
	name = "broker breach anchor"
	desc = "A hostile breach anchor humming with nanite pressure."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk6"
	density = TRUE

/obj/structure/cyberpunk_liberation_factory
	name = "liberation vehicle factory marker"
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "datadisk7"
	density = TRUE
	var/next_production_at = 0

/obj/structure/cyberpunk_liberation_factory/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(world.time < next_production_at)
		to_chat(user, span_warning("[src] is producing for [DisplayTimeText(next_production_at - world.time)]."))
		return
	var/choice = tgui_input_list(user, "Build GLA-lite vehicle.", "Vehicle Factory", list("rocket buggy", "technical", "bomb truck", "Cancel"))
	switch(choice)
		if("rocket buggy")
			new /obj/vehicle/ridden/atv(get_turf(src))
			new /obj/item/gun/ballistic/rocketlauncher/cyberpunk(get_turf(src))
		if("technical")
			new /obj/vehicle/ridden/atv(get_turf(src))
			new /obj/item/gun/ballistic/automatic/ar/cyberpunk/streetline(get_turf(src))
		if("bomb truck")
			new /obj/vehicle/ridden/atv(get_turf(src))
			new /obj/item/grenade/c4(get_turf(src))
	if(choice && choice != "Cancel")
		next_production_at = world.time + 90 SECONDS

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

/obj/item/cyberpunk_black_market_chip/proc/get_market_actions()
	return list(
		list("id" = "sync", "label" = "Sync dirty money", "description" = "Move held illegal cash into your account."),
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
		new item_path(drop_turf)
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

	var/list/tasks = list()
	for(var/task in spy.spy_tasks)
		tasks += list(list("text" = task))

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
	data["actions"] = list(list("id" = "upload", "label" = "Upload completion", "description" = "Mark one current task complete and send research credit to your true employer."))
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
	data["actions"] = list(
		list("id" = "recruit", "label" = "Recruit neural target", "description" = "Choose a nearby neural-interface user. Takes two minutes, interrupted by movement."),
		list("id" = "sabotage", "label" = "Mark sabotage", "description" = "Choose a nearby machine or structure. Takes ten seconds."),
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
			if(action_id == "sabotage")
				var/list/sabotage_targets = list()
				for(var/obj/nearby in view(1, user))
					if(istype(nearby, /obj/machinery) || istype(nearby, /obj/structure))
						sabotage_targets += nearby
				var/obj/sabotage_target = tgui_input_list(user, "Choose a nearby machine or structure.", "Anarchist Sabotage", sabotage_targets)
				if(sabotage_target)
					anarchist.mark_sabotage(user, sabotage_target)
				return TRUE
			if(action_id == "recruit")
				var/list/targets = list()
				for(var/mob/living/nearby in view(1, user))
					if(nearby == user || !nearby.mind)
						continue
					targets += nearby
				var/mob/living/target = tgui_input_list(user, "Choose a target to recruit.", "Anarchist Recruitment", targets)
				if(target)
					anarchist.convert_target(user, target)
				return TRUE
		if("refresh")
			return TRUE
