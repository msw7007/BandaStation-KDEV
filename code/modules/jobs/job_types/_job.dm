/datum/job
	/// The name of the job , used for preferences, bans and more. Make sure you know what you're doing before changing this.
	var/title = "NOPE"

	/// The description of the job, used for preferences menu.
	/// Keep it short and useful. Avoid in-jokes, these are for new players.
	var/description

	/// Innate skill levels unlocked at roundstart. Based on config.jobs_have_minimal_access config setting, for example with a skeleton crew. Format is list(/datum/skill/foo = SKILL_EXP_NOVICE) with exp as an integer or as per code/_DEFINES/skills.dm
	var/list/skills
	/// Innate skill levels unlocked at roundstart. Based on config.jobs_have_minimal_access config setting, for example with a full crew. Format is list(/datum/skill/foo = SKILL_EXP_NOVICE) with exp as an integer or as per code/_DEFINES/skills.dm
	var/list/minimal_skills

	/// Tells the given channels that the given mob is the new department head. See communications.dm for valid channels.
	var/head_announce

	/// Bitflags for the job
	var/auto_deadmin_role_flags = NONE

	/// Players will be allowed to spawn in as jobs that are set to "Station"
	var/faction = FACTION_NONE

	/// How many players can be this job
	var/total_positions = 0

	/// How many players can spawn in as this job
	var/spawn_positions = 0

	/// How many players have this job
	var/current_positions = 0

	/// Supervisors, who this person answers to directly
	var/supervisors = ""

	/// What kind of mob type joining players with this job as their assigned role are spawned as.
	var/spawn_type = /mob/living/carbon/human

	/// If this is set to 1, a text is printed to the player when jobs are assigned, telling him that he should let admins know that he has to disconnect.
	var/req_admin_notify

	/// If you have the use_age_restriction_for_jobs config option enabled and the database set up, this option will add a requirement for players to be at least minimal_player_age days old. (meaning they first signed in at least that many days before.)
	var/minimal_player_age = 0

	var/datum/outfit/outfit = null

	/// The job's outfit that will be assigned for plasmamen.
	var/datum/outfit/plasmaman/plasmaman_outfit = null

	/// Minutes of experience-time required to play in this job. The type is determined by [exp_required_type] and [exp_required_type_department] depending on configs.
	var/exp_requirements = 0
	/// Experience required to play this job, if the config is enabled, and `exp_required_type_department` is not enabled with the proper config.
	var/exp_required_type = ""
	/// Department experience required to play this job, if the config is enabled.
	var/exp_required_type_department = ""
	/// Experience type granted by playing in this job.
	var/exp_granted_type = ""

	///How much money does this crew member make in a single paycheck? Note that passive paychecks are capped to PAYCHECK_CREW in regular gameplay after roundstart.
	var/paycheck = PAYCHECK_CREW
	///Which department does this paycheck pay from?
	var/paycheck_department = ACCOUNT_CIV

	/// Traits added to the mind of the mob assigned this job
	var/list/mind_traits

	///Lazylist of traits added to the liver of the mob assigned this job (used for the classic "cops heal from donuts" reaction, among others)
	var/list/liver_traits = null

	var/display_order = JOB_DISPLAY_ORDER_DEFAULT

	///What types of bounty tasks can this job receive past the default? TODO, move to id trims.
	var/bounty_types = CIV_JOB_BASIC

	/// Goodies that can be received via the mail system.
	// this is a weighted list.
	/// Keep the _job definition for this empty and use /obj/item/mail to define general gifts.
	var/list/mail_goodies = list()

	/// If this job's mail goodies compete with generic goodies.
	var/exclusive_mail_goodies = FALSE

	/// Bitfield of departments this job belongs to. These get setup when adding the job into the department, on job datum creation.
	var/departments_bitflags = NONE

	/// If specified, this department will be used for the preferences menu.
	var/datum/job_department/department_for_prefs = null

	/// Lazy list with the departments this job belongs to.
	/// Required to be set for playable jobs.
	/// The first department will be used in the preferences menu,
	/// unless department_for_prefs is set.
	var/list/departments_list = null

	/// Should this job be allowed to be picked for the bureaucratic error event?
	var/allow_bureaucratic_error = TRUE

	///Is this job affected by weird spawns like the ones from station traits
	var/random_spawns_possible = TRUE

	/// List of family heirlooms this job can get with the family heirloom quirk. List of types.
	var/list/family_heirlooms

	/// All values = (JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_BOLD_SELECT_TEXT | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN | JOB_CANNOT_OPEN_SLOTS | JOB_HEAD_OF_STAFF)
	var/job_flags = NONE

	/// Multiplier for general usage of the voice of god.
	var/voice_of_god_power = 1
	/// Multiplier for the silence command of the voice of god.
	var/voice_of_god_silence_power = 1

	/// String. If set to a non-empty one, it will be the key for the policy text value to show this role on spawn.
	var/policy_index = ""

	/// RPG job names, for the memes
	var/rpg_title

	/// Alternate titles to register as pointing to this job.
	var/list/alternate_titles

	var/human_authority = JOB_AUTHORITY_NON_HUMANS_ALLOWED

	/// String key to track any variables we want to tie to this job in config, so we can avoid using the job title. We CAPITALIZE it in order to ensure it's unique and resistant to trivial formatting changes.
	/// You'll probably break someone's config if you change this, so it's best to not to.
	var/config_tag = ""

	/// custom ringtone for this job
	var/job_tone

	/// Minimal character age for this job
	var/required_character_age

	/// If set, look for a policy with this instead of the job title
	var/policy_override

	/// How desensitized this job is to seeing death as a base - applied with the job
	var/desensitized_base = 1.0

	/// Cyberpunk role block metadata. This is a gameplay/readability layer over the TG job.
	var/cyberpunk_role_group
	var/cyberpunk_role_class
	var/cyberpunk_corporation_id
	var/list/cyberpunk_role_accesses
	var/list/cyberpunk_role_tasks
	var/list/cyberpunk_role_bonuses
	var/cyberpunk_bonus_credits = 0
	var/cyberpunk_role_attribute_points = 0
	var/list/cyberpunk_role_attribute_point_limits
	var/cyberpunk_role_professional_skill_points = 0
	var/cyberpunk_role_weapon_skill_points = 0
	var/cyberpunk_allow_custom_title = FALSE
	var/cyberpunk_standalone_role = FALSE

/datum/job/New()
	. = ..()
	var/new_spawn_positions = CHECK_MAP_JOB_CHANGE(title, "spawn_positions")
	if(isnum(new_spawn_positions))
		spawn_positions = new_spawn_positions
	var/new_total_positions = CHECK_MAP_JOB_CHANGE(title, "total_positions")
	if(isnum(new_total_positions))
		total_positions = new_total_positions
	//CYBERPUNK BUILD - rebuild and delete before release
	// The cyberpunk role tree is now the only player-facing roundstart job set.
	// Keep legacy TG jobs as data/outfit providers, but remove them from normal
	// assignment until the upstream job tree is fully deleted.
	if((job_flags & JOB_NEW_PLAYER_JOINABLE) && !istype(src, /datum/job/cyberpunk))
		job_flags &= ~(JOB_NEW_PLAYER_JOINABLE|JOB_REOPEN_ON_ROUNDSTART_LOSS|JOB_CAN_BE_INTERN)
		spawn_positions = 0
		total_positions = 0
	//CYBERPUNK BUILD - rebuild and delete before release

/// Executes after the mob has been spawned in the map. Client might not be yet in the mob, and is thus a separate variable.
/datum/job/proc/after_spawn(mob/living/spawned, client/player_client)
	SHOULD_CALL_PARENT(TRUE)
	if(length(mind_traits))
		spawned.mind.add_traits(mind_traits, JOB_TRAIT)

	spawned.mind.desensitized_level = clamp(desensitized_base, DESENSITIZED_MINIMUM, spawned.mind.desensitized_level)

	var/obj/item/organ/liver/liver = spawned.get_organ_slot(ORGAN_SLOT_LIVER)
	if(liver && length(liver_traits))
		liver.add_traits(liver_traits, JOB_TRAIT)

	if(!ishuman(spawned))
		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_SPAWN, src, spawned, player_client)
		return

	var/mob/living/carbon/human/spawned_human = spawned
	var/list/roundstart_experience

	if(player_client)
		for(var/obj/item/organ/our_organ in spawned_human.organs)
			ADD_TRAIT(our_organ, TRAIT_CLIENT_STARTING_ORGAN, ROUNDSTART_TRAIT)

	if(!config) //Needed for robots.
		roundstart_experience = minimal_skills

	if(CONFIG_GET(flag/jobs_have_minimal_access))
		roundstart_experience = minimal_skills
	else
		roundstart_experience = skills

	if(roundstart_experience)
		for(var/i in roundstart_experience)
			spawned_human.mind.adjust_experience(i, roundstart_experience[i], TRUE)

	if(player_client)
		spawned_human.apply_cyberpunk_fortitude_starting_organs()

	apply_cyberpunk_role_grants(spawned_human)
	player_client?.prefs?.apply_character_role_setup_to_human(spawned_human, src)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_SPAWN, src, spawned, player_client)

/datum/job/proc/cyberpunk_classification()
	var/tag = config_tag || uppertext(replacetext(title, " ", "_"))
	switch(tag)
		if("CAPTAIN")
			return list("city", "government", null, list("government:all"), 500)
		if("HEAD_OF_PERSONNEL", "MAGISTRATE", "NANOTRASEN_REPRESENTATIVE", "LAWYER")
			return list("city", "council", null, list("city:council"), 250)
		if("HEAD_OF_SECURITY", "WARDEN", "DETECTIVE", "SECURITY_OFFICER", "BLUESHIELD")
			return list("city", "officer", null, list("city:police"), 150)
		if("CHIEF_MEDICAL_OFFICER")
			return list("corporate", "representative", "benn", list("corp:benn", "corp:heads"), 300)
		if("RESEARCH_DIRECTOR")
			return list("corporate", "representative", "benn", list("corp:benn", "corp:heads"), 300)
		if("MEDICAL_DOCTOR", "CHEMIST", "PARAMEDIC", "CORONER", "GENETICIST", "PSYCHOLOGIST", "SCIENTIST")
			return list("corporate", "specialist-ripper", "benn", list("corp:benn"), 120)
		if("CHIEF_ENGINEER")
			return list("corporate", "representative", "ryaznov", list("corp:ryaznov", "corp:heads"), 300)
		if("STATION_ENGINEER", "ATMOSPHERIC_TECHNICIAN", "ROBOTICIST", "SHAFT_MINER")
			return list("corporate", "specialist-engineer", "ryaznov", list("corp:ryaznov"), 120)
		if("QUARTERMASTER")
			return list("corporate", "representative", "starlight", list("corp:starlight", "corp:heads"), 300)
		if("CARGO_TECHNICIAN", "EXPLORER")
			return list("corporate", "specialist-logist", "starlight", list("corp:starlight"), 120)
		if("BITRUNNER")
			return list("mercenary", "netrunner", null, list(), 80)
		if("PRISONER")
			return list("antagonist", "criminal", null, list(), 0)
		if("AI", "CYBORG")
			return list("city", "synthetic", null, list(), 0)
	return list("city", "worker", null, list(), 60)

/datum/job/proc/get_cyberpunk_role_group()
	if(cyberpunk_role_group)
		return cyberpunk_role_group
	var/list/classification = cyberpunk_classification()
	return classification[1]

/datum/job/proc/get_cyberpunk_role_class()
	if(cyberpunk_role_class)
		return cyberpunk_role_class
	var/list/classification = cyberpunk_classification()
	return classification[2]

/datum/job/proc/get_cyberpunk_corporation_id()
	if(cyberpunk_corporation_id)
		return cyberpunk_corporation_id
	var/list/classification = cyberpunk_classification()
	return classification[3]

/datum/job/proc/get_cyberpunk_role_accesses()
	if(cyberpunk_role_accesses)
		return cyberpunk_role_accesses.Copy()
	var/list/classification = cyberpunk_classification()
	var/list/accesses = classification[4]
	return islist(accesses) ? accesses.Copy() : list()

/datum/job/proc/get_cyberpunk_bonus_credits()
	if(cyberpunk_bonus_credits)
		return cyberpunk_bonus_credits
	var/list/classification = cyberpunk_classification()
	return classification[5] || 0

/datum/job/proc/get_cyberpunk_role_attribute_point_limits()
	if(cyberpunk_role_attribute_point_limits)
		return cyberpunk_role_attribute_point_limits.Copy()
	return list()

/datum/job/proc/get_cyberpunk_role_attribute_points()
	var/total = cyberpunk_role_attribute_points
	if(cyberpunk_role_attribute_point_limits)
		for(var/attribute_id in cyberpunk_role_attribute_point_limits)
			total += max(0, round(cyberpunk_role_attribute_point_limits[attribute_id] || 0))
	return total

/datum/job/proc/get_cyberpunk_role_tasks()
	if(cyberpunk_role_tasks)
		return cyberpunk_role_tasks.Copy()
	switch(get_cyberpunk_role_class())
		if("worker")
			return list("Free work", "Business setup", "City services", "Contract work")
		if("council")
			return list("City decisions", "Emergency funding", "Corporate negotiations", "Police direction")
		if("officer")
			return list("Patrol", "Illegal activity suppression", "Witness protection", "Government security")
		if("intern")
			return list("Learn corporate routines", "Request access from employees", "Low-risk assignments")
		if("agent")
			return list("Corporate security", "Sabotage", "Kidnapping", "Cargo interception")
		if("specialist-ripper")
			return list("Medicine", "Chemistry", "Implants", "Biotech services")
		if("specialist-engineer")
			return list("Construction", "Repairs", "Equipment production", "Exosuit and ore work")
		if("specialist-logist")
			return list("Logistics", "Vehicle work", "Cargo movement", "Wreck and foreign tech scans")
		if("representative")
			return list("Corporate development", "Profit routing", "Contracts", "Staff direction")
		if("netrunner")
			return list("Cyberspace contracts", "Data recovery", "Network support")
		if("criminal")
			return list("Illegal work", "Conflict generation", "Gray economy")
		if("synthetic")
			return list("Station support", "Remote monitoring", "Service automation")
	return list("Contract work", "City support")

/datum/job/proc/get_cyberpunk_role_bonuses()
	if(cyberpunk_role_bonuses)
		return cyberpunk_role_bonuses.Copy()
	var/list/bonuses = list()
	var/group = get_cyberpunk_role_group()
	var/role_class = get_cyberpunk_role_class()
	var/corp_id = get_cyberpunk_corporation_id()
	if(corp_id)
		bonuses += "Corporate comms and [corp_id] cryptokey access"
	switch(group)
		if("city")
			bonuses += "City identity and service standing"
		if("corporate")
			bonuses += "Corporate task routing"
		if("mercenary")
			bonuses += "Flexible contract routing"
		if("antagonist")
			bonuses += "Criminal/hostile objective routing"
	switch(role_class)
		if("representative")
			bonuses += "Corporate heads access"
		if("government")
			bonuses += "Government master access"
		if("officer")
			bonuses += "Police cryptokey access"
	var/bonus_credits = get_cyberpunk_bonus_credits()
	if(bonus_credits > 0)
		bonuses += "[bonus_credits] credits starting role bonus"
	return bonuses

/datum/job/proc/apply_cyberpunk_role_grants(mob/living/spawned)
	if(!istype(spawned))
		return
	var/list/accesses = get_cyberpunk_role_accesses()
	if(length(accesses))
		var/obj/item/card/id/id_card = spawned.get_idcard(FALSE)
		for(var/access_id in accesses)
			var/datum/cyberpunk_crypto_key/access_key = create_cyberpunk_crypto_access_key(access_id)
			if(!access_key)
				continue
			spawned.remember_cyberpunk_crypto_key(access_key)
			id_card?.store_cyberpunk_crypto_access(access_id)
	var/bonus_credits = get_cyberpunk_bonus_credits()
	if(bonus_credits > 0)
		var/datum/bank_account/account = spawned.get_bank_account()
		account?.adjust_money(bonus_credits, "Role starting bonus: [title]")

/datum/job/proc/cyberpunk_serialize_role_data()
	return list(
		"group" = get_cyberpunk_role_group(),
		"role_class" = get_cyberpunk_role_class(),
		"corporation" = get_cyberpunk_corporation_id(),
		"accesses" = get_cyberpunk_role_accesses(),
		"tasks" = get_cyberpunk_role_tasks(),
		"bonuses" = get_cyberpunk_role_bonuses(),
		"bonus_credits" = get_cyberpunk_bonus_credits(),
		"attribute_points" = get_cyberpunk_role_attribute_points(),
		"attribute_point_limits" = get_cyberpunk_role_attribute_point_limits(),
		"professional_skill_points" = cyberpunk_role_professional_skill_points,
		"weapon_skill_points" = cyberpunk_role_weapon_skill_points,
		"custom_title" = cyberpunk_allow_custom_title,
		"standalone" = cyberpunk_standalone_role,
	)

/// Standalone cyberpunk role layer. These roles are not wrappers around TG jobs;
/// old jobs can be removed later without removing this tree.
/datum/job/cyberpunk
	faction = FACTION_STATION
	total_positions = 10
	spawn_positions = 10
	supervisors = "city and contract law"
	exp_granted_type = EXP_TYPE_CREW
	outfit = /datum/outfit/job/assistant
	plasmaman_outfit = /datum/outfit/plasmaman
	paycheck = PAYCHECK_LOWER
	paycheck_department = ACCOUNT_CIV
	display_order = 1000
	department_for_prefs = /datum/job_department/assistant
	job_flags = NONE
	cyberpunk_role_group = "city"
	cyberpunk_role_class = "worker"
	cyberpunk_bonus_credits = 60
	cyberpunk_standalone_role = TRUE
	allow_bureaucratic_error = FALSE
	random_spawns_possible = TRUE

/datum/job/cyberpunk/city_worker
	title = "City Worker"
	description = "Free city labor: contracts, service work, business setup, and local jobs."
	config_tag = "CYBERPUNK_CITY_WORKER"
	total_positions = -1
	spawn_positions = -1
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/assistant
	cyberpunk_role_group = "city"
	cyberpunk_role_class = "worker"
	cyberpunk_bonus_credits = 60
	cyberpunk_role_professional_skill_points = 6
	cyberpunk_allow_custom_title = TRUE

/datum/job/cyberpunk/councilor
	title = "Council Member"
	description = "City administration role: disputes, permits, funding, and public contracts."
	config_tag = "CYBERPUNK_COUNCIL_MEMBER"
	total_positions = 4
	spawn_positions = 4
	department_for_prefs = /datum/job_department/captain
	departments_list = list(/datum/job_department/command)
	outfit = /datum/outfit/job/hop
	paycheck = PAYCHECK_COMMAND
	cyberpunk_role_group = "city"
	cyberpunk_role_class = "council"
	cyberpunk_role_accesses = list("city:council")
	cyberpunk_bonus_credits = 250
	cyberpunk_role_professional_skill_points = 6
	job_flags = STATION_JOB_FLAGS | JOB_BOLD_SELECT_TEXT | JOB_CANNOT_OPEN_SLOTS | JOB_ANTAG_PROTECTED

/datum/job/cyberpunk/government
	title = "Government Officer"
	description = "Government authority with master city access and oversight over legal systems."
	config_tag = "CYBERPUNK_GOVERNMENT_OFFICER"
	total_positions = 1
	spawn_positions = 1
	department_for_prefs = /datum/job_department/captain
	departments_list = list(/datum/job_department/command)
	outfit = /datum/outfit/job/captain
	paycheck = PAYCHECK_COMMAND
	cyberpunk_role_group = "city"
	cyberpunk_role_class = "government"
	cyberpunk_role_accesses = list("government:all", "city:council", "city:police", "corp:heads")
	cyberpunk_bonus_credits = 500
	job_flags = STATION_JOB_FLAGS | HEAD_OF_STAFF_JOB_FLAGS | JOB_ANTAG_PROTECTED

/datum/job/cyberpunk/police_officer
	title = "Police Officer"
	description = "Public enforcement role: patrols, illegal activity, arrests, and evidence handling."
	config_tag = "CYBERPUNK_POLICE_OFFICER"
	total_positions = 8
	spawn_positions = 8
	department_for_prefs = /datum/job_department/security
	departments_list = list(/datum/job_department/security)
	outfit = /datum/outfit/job/security
	paycheck_department = ACCOUNT_SEC
	cyberpunk_role_group = "city"
	cyberpunk_role_class = "officer"
	cyberpunk_role_accesses = list("city:police")
	cyberpunk_bonus_credits = 150
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_STRENGTH = 1)
	cyberpunk_role_weapon_skill_points = 6
	job_flags = STATION_JOB_FLAGS | JOB_ANTAG_PROTECTED

/datum/job/cyberpunk/corporate
	job_flags = NONE
	department_for_prefs = /datum/job_department/service
	departments_list = list(/datum/job_department/service)
	cyberpunk_role_group = "corporate"
	cyberpunk_bonus_credits = 80
	supervisors = "corporate chain of command"

/datum/job/cyberpunk/corporate/intern
	title = "Corporate Intern"
	description = "Entry corporate role without starting keys. Learn the chain and request access from staff."
	config_tag = "CYBERPUNK_CORPORATE_INTERN"
	total_positions = 9
	spawn_positions = 9
	job_flags = NONE
	cyberpunk_role_class = "intern"
	cyberpunk_role_tasks = list("Learn corporate routines", "Request keys from employees", "Take low-risk work")

/datum/job/cyberpunk/corporate/benn_intern
	title = "Benn Intern"
	description = "Benn entry role: biotech errands, clinic support, implant paperwork, and supervised corporate work."
	config_tag = "CYBERPUNK_BENN_INTERN"
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/medical
	departments_list = list(/datum/job_department/medical)
	cyberpunk_corporation_id = "benn"

/datum/job/cyberpunk/corporate/ryaznov_intern
	title = "Ryaznov Intern"
	description = "Ryaznov entry role: workshop support, construction errands, component hauling, and supervised repair work."
	config_tag = "CYBERPUNK_RYAZNOV_INTERN"
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/engineering
	departments_list = list(/datum/job_department/engineering)
	cyberpunk_corporation_id = "ryaznov"

/datum/job/cyberpunk/corporate/starlight_intern
	title = "Starlight Intern"
	description = "Starlight entry role: cargo paperwork, delivery support, garage errands, and supervised logistics work."
	config_tag = "CYBERPUNK_STARLIGHT_INTERN"
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/cargo
	departments_list = list(/datum/job_department/cargo)
	cyberpunk_corporation_id = "starlight"

/datum/job/cyberpunk/corporate/agent
	title = "Corporate Agent"
	description = "Corporate field role: security, sabotage, retrieval, intimidation, and sensitive contracts."
	config_tag = "CYBERPUNK_CORPORATE_AGENT"
	total_positions = 6
	spawn_positions = 6
	job_flags = NONE
	outfit = /datum/outfit/job/security
	cyberpunk_role_class = "agent"
	cyberpunk_role_tasks = list("Corporate security", "Sabotage", "Retrieval", "Sensitive contracts")
	cyberpunk_role_weapon_skill_points = 4

/datum/job/cyberpunk/corporate/benn_agent
	title = "Benn Agent"
	description = "Benn field role: protect medical assets, recover biotech property, and handle sensitive corporate contracts."
	config_tag = "CYBERPUNK_BENN_AGENT"
	job_flags = STATION_JOB_FLAGS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/medical
	departments_list = list(/datum/job_department/medical)
	cyberpunk_corporation_id = "benn"
	cyberpunk_role_accesses = list("corp:benn")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_PERCEPTION = 2)

/datum/job/cyberpunk/corporate/ryaznov_agent
	title = "Ryaznov Agent"
	description = "Ryaznov field role: protect engineering assets, recover hardware, and handle sensitive corporate contracts."
	config_tag = "CYBERPUNK_RYAZNOV_AGENT"
	job_flags = STATION_JOB_FLAGS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/engineering
	departments_list = list(/datum/job_department/engineering)
	cyberpunk_corporation_id = "ryaznov"
	cyberpunk_role_accesses = list("corp:ryaznov")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_STRENGTH = 2)

/datum/job/cyberpunk/corporate/starlight_agent
	title = "Starlight Agent"
	description = "Starlight field role: protect shipments, recover vehicles and cargo, and handle sensitive corporate contracts."
	config_tag = "CYBERPUNK_STARLIGHT_AGENT"
	job_flags = STATION_JOB_FLAGS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/cargo
	departments_list = list(/datum/job_department/cargo)
	cyberpunk_corporation_id = "starlight"
	cyberpunk_role_accesses = list("corp:starlight")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_DEXTERITY = 2)

/datum/job/cyberpunk/corporate/benn_ripper
	title = "Benn Ripper Specialist"
	description = "Benn specialist: medicine, chemistry, implants, biotech, and patient services."
	config_tag = "CYBERPUNK_BENN_RIPPER_SPECIALIST"
	total_positions = 6
	spawn_positions = 6
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/medical
	departments_list = list(/datum/job_department/medical)
	outfit = /datum/outfit/job/doctor
	paycheck_department = ACCOUNT_MED
	cyberpunk_role_class = "specialist-ripper"
	cyberpunk_corporation_id = "benn"
	cyberpunk_role_accesses = list("corp:benn")
	cyberpunk_bonus_credits = 120
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_INTELLIGENCE = 2)
	cyberpunk_role_professional_skill_points = 8

/datum/job/cyberpunk/corporate/ryaznov_engineer
	title = "Ryaznov Engineering Specialist"
	description = "Ryaznov specialist: construction, repairs, fabrication, power, and heavy equipment."
	config_tag = "CYBERPUNK_RYAZNOV_ENGINEERING_SPECIALIST"
	total_positions = 6
	spawn_positions = 6
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/engineering
	departments_list = list(/datum/job_department/engineering)
	outfit = /datum/outfit/job/engineer
	paycheck_department = ACCOUNT_ENG
	cyberpunk_role_class = "specialist-engineer"
	cyberpunk_corporation_id = "ryaznov"
	cyberpunk_role_accesses = list("corp:ryaznov")
	cyberpunk_bonus_credits = 120
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_SPIRIT = 2)
	cyberpunk_role_professional_skill_points = 8

/datum/job/cyberpunk/corporate/starlight_logist
	title = "Starlight Logistics Specialist"
	description = "Starlight specialist: vehicles, delivery, cargo routing, wreck recovery, and scans."
	config_tag = "CYBERPUNK_STARLIGHT_LOGISTICS_SPECIALIST"
	total_positions = 6
	spawn_positions = 6
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/cargo
	departments_list = list(/datum/job_department/cargo)
	outfit = /datum/outfit/job/cargo_tech
	paycheck_department = ACCOUNT_CAR
	cyberpunk_role_class = "specialist-logist"
	cyberpunk_corporation_id = "starlight"
	cyberpunk_role_accesses = list("corp:starlight")
	cyberpunk_bonus_credits = 120
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_CHARISMA = 2)
	cyberpunk_role_professional_skill_points = 8

/datum/job/cyberpunk/corporate/representative
	title = "Corporate Representative"
	description = "Corporate leadership role: contracts, staff direction, company profit, and negotiations."
	config_tag = "CYBERPUNK_CORPORATE_REPRESENTATIVE"
	total_positions = 1
	spawn_positions = 1
	paycheck = PAYCHECK_COMMAND
	cyberpunk_role_class = "representative"
	cyberpunk_bonus_credits = 300
	job_flags = NONE

/datum/job/cyberpunk/corporate/benn_representative
	title = "Benn Representative"
	description = "Benn leadership role: direct biotech staff, negotiate contracts, and manage corporate medical interests."
	config_tag = "CYBERPUNK_BENN_REPRESENTATIVE"
	job_flags = STATION_JOB_FLAGS | JOB_BOLD_SELECT_TEXT | JOB_CANNOT_OPEN_SLOTS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/medical
	departments_list = list(/datum/job_department/medical, /datum/job_department/command)
	outfit = /datum/outfit/job/cmo
	paycheck_department = ACCOUNT_MED
	cyberpunk_corporation_id = "benn"
	cyberpunk_role_accesses = list("corp:benn", "corp:heads")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_PERCEPTION = 1, ATTRIBUTE_INTELLIGENCE = 1)

/datum/job/cyberpunk/corporate/ryaznov_representative
	title = "Ryaznov Representative"
	description = "Ryaznov leadership role: direct engineering staff, negotiate contracts, and manage industrial interests."
	config_tag = "CYBERPUNK_RYAZNOV_REPRESENTATIVE"
	job_flags = STATION_JOB_FLAGS | JOB_BOLD_SELECT_TEXT | JOB_CANNOT_OPEN_SLOTS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/engineering
	departments_list = list(/datum/job_department/engineering, /datum/job_department/command)
	outfit = /datum/outfit/job/ce
	paycheck_department = ACCOUNT_ENG
	cyberpunk_corporation_id = "ryaznov"
	cyberpunk_role_accesses = list("corp:ryaznov", "corp:heads")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_STRENGTH = 1, ATTRIBUTE_SPIRIT = 1)

/datum/job/cyberpunk/corporate/starlight_representative
	title = "Starlight Representative"
	description = "Starlight leadership role: direct logistics staff, negotiate contracts, and manage delivery interests."
	config_tag = "CYBERPUNK_STARLIGHT_REPRESENTATIVE"
	job_flags = STATION_JOB_FLAGS | JOB_BOLD_SELECT_TEXT | JOB_CANNOT_OPEN_SLOTS | JOB_ANTAG_PROTECTED
	department_for_prefs = /datum/job_department/cargo
	departments_list = list(/datum/job_department/cargo, /datum/job_department/command)
	outfit = /datum/outfit/job/quartermaster
	paycheck_department = ACCOUNT_CAR
	cyberpunk_corporation_id = "starlight"
	cyberpunk_role_accesses = list("corp:starlight", "corp:heads")
	cyberpunk_role_attribute_point_limits = list(ATTRIBUTE_DEXTERITY = 1, ATTRIBUTE_CHARISMA = 1)

/datum/job/cyberpunk/mercenary
	title = "Mercenary"
	description = "Independent contractor for public, private, and gray work."
	config_tag = "CYBERPUNK_MERCENARY"
	total_positions = -1
	spawn_positions = -1
	job_flags = STATION_JOB_FLAGS
	department_for_prefs = /datum/job_department/assistant
	departments_list = list(/datum/job_department/assistant)
	cyberpunk_role_group = "mercenary"
	cyberpunk_role_class = "mercenary"
	cyberpunk_bonus_credits = 80
	cyberpunk_role_professional_skill_points = 4
	cyberpunk_role_weapon_skill_points = 2
	cyberpunk_allow_custom_title = TRUE
	supervisors = "active contracts"

/datum/job/cyberpunk/netrunner
	title = "Netrunner"
	description = "Independent cyberspace specialist for data, demons, ICE and network contracts."
	config_tag = "CYBERPUNK_NETRUNNER"
	total_positions = 0
	spawn_positions = 0
	job_flags = NONE
	department_for_prefs = /datum/job_department/science
	departments_list = list(/datum/job_department/science)
	outfit = /datum/outfit/job/bitrunner
	paycheck_department = ACCOUNT_SCI
	cyberpunk_role_group = "mercenary"
	cyberpunk_role_class = "netrunner"
	cyberpunk_bonus_credits = 80
	cyberpunk_standalone_role = FALSE

/datum/job/cyberpunk/criminal_contractor
	title = "Criminal Contractor"
	description = "Illegal economy role: gray contracts, theft, sabotage, and district violence."
	config_tag = "CYBERPUNK_CRIMINAL_CONTRACTOR"
	total_positions = 6
	spawn_positions = 6
	department_for_prefs = /datum/job_department/security
	departments_list = list(/datum/job_department/security)
	outfit = /datum/outfit/job/prisoner
	paycheck = PAYCHECK_LOWER
	paycheck_department = ACCOUNT_CIV
	cyberpunk_role_group = "antagonist"
	cyberpunk_role_class = "criminal"
	cyberpunk_bonus_credits = 0
	job_flags = STATION_JOB_FLAGS | JOB_CANNOT_OPEN_SLOTS | JOB_ANTAG_PROTECTED

/// Return the outfit to use
/datum/job/proc/get_outfit(consistent)
	return outfit

/// Announce that this job as joined the round to all crew members.
/// Note the joining mob has no client at this point.
/datum/job/proc/announce_job(mob/living/joining_mob)
	if(head_announce)
		announce_head(joining_mob, list(head_announce))


//Used for a special check of whether to allow a client to latejoin as this job.
/datum/job/proc/special_check_latejoin(client/latejoin)
	return TRUE


/mob/living/proc/on_job_equipping(datum/job/equipping, client/player_client)
	return

#define VERY_LATE_ARRIVAL_TOAST_PROB 20

/mob/living/carbon/human/on_job_equipping(datum/job/equipping, client/player_client)
	if(equipping.paycheck_department)
		var/datum/bank_account/bank_account = new(real_name, equipping, dna.species.payday_modifier)
		bank_account.payday(STARTING_PAYCHECKS, free = TRUE)
		account_id = bank_account.account_id
		bank_account.replaceable = FALSE
		add_mob_memory(/datum/memory/key/account, remembered_id = account_id)

	dress_up_as_job(
		equipping = equipping,
		visual_only = FALSE,
		player_client = player_client,
		consistent = FALSE,
	)

	if(EMERGENCY_PAST_POINT_OF_NO_RETURN && prob(VERY_LATE_ARRIVAL_TOAST_PROB))
		equip_to_slot_or_del(new /obj/item/food/griddle_toast(src), ITEM_SLOT_MASK)

#undef VERY_LATE_ARRIVAL_TOAST_PROB

/mob/living/proc/dress_up_as_job(datum/job/equipping, visual_only = FALSE, client/player_client, consistent = FALSE)
	return

/mob/living/carbon/human/dress_up_as_job(datum/job/equipping, visual_only = FALSE, client/player_client, consistent = FALSE)
	dna.species.pre_equip_species_outfit(equipping, src, visual_only)
	equip_outfit_and_loadout(equipping.get_outfit(consistent), player_client?.prefs, visual_only)

/datum/job/proc/announce_head(mob/living/carbon/human/human, channels) //tells the given channel that the given mob is the new department head. See communications.dm for valid channels.
	if(human)
		//timer because these should come after the captain announcement
		SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_addtimer), CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(aas_config_announce), /datum/aas_config_entry/newhead, list("PERSON" = human.real_name, "RANK" = human.job), null, channels, null, TRUE), 1))

//If the configuration option is set to require players to be logged as old enough to play certain jobs, then this proc checks that they are, otherwise it just returns 1
/datum/job/proc/player_old_enough(client/player)
	if(!player || !available_in_days(player))
		return TRUE //Available in 0 days = available right now = player is old enough to play.
	return FALSE


/datum/job/proc/available_in_days(client/player)
	if(!player)
		return 0

	if(!CONFIG_GET(flag/use_age_restriction_for_jobs))
		return 0

	//Without a database connection we can't get a player's age so we'll assume they're old enough for all jobs
	if(!SSdbcore.Connect())
		return 0

	// If they have been exempted from date availability checks, we assume they are old enough for all jobs.
	// This is only added whenever an admin manually ticks the box for this player.
	if(player.prefs?.db_flags & DB_FLAG_EXEMPT)
		return 0

	// As of the time of writing this comment, verifying database connection isn't "solved". Sometimes rust-g will report a
	// connection mid-shift despite the database dying.
	// If the client age is -1, it means that no code path has overwritten it. Even first time connections get it set to 0,
	// so it's a pretty good indication of a database issue. We'll again just assume they're old enough for all jobs.
	if(player.player_age == -1)
		return 0

	if(!isnum(minimal_player_age))
		return 0

	return max(0, minimal_player_age - player.player_age)

/datum/job/proc/config_check()
	return TRUE

/**
 * # map_check
 *
 * Checks the map config for job changes
 * If they have 0 spawn and total positions in the config, the job is entirely removed from occupations prefs for the round.
 */
/datum/job/proc/map_check()
	var/available_roundstart = TRUE
	var/available_latejoin = TRUE

	var/edited_spawn_positions = CHECK_MAP_JOB_CHANGE(title, "spawn_positions")
	if(!isnull(edited_spawn_positions) && (edited_spawn_positions == 0))
		available_roundstart = FALSE
	var/edited_total_positions = CHECK_MAP_JOB_CHANGE(title, "total_positions")
	if(!isnull(edited_total_positions) && (edited_total_positions == 0))
		available_latejoin = FALSE

	if(!available_roundstart && !available_latejoin) //map config disabled the job
		return FALSE

	return TRUE

/// Gets the message that shows up when spawning as this job
/datum/job/proc/get_spawn_message()
	SHOULD_NOT_OVERRIDE(TRUE)
	return boxed_message(span_infoplain(jointext(get_spawn_message_information(), "\n&bull; ")))

/// Returns a list of strings that correspond to chat messages sent to this mob when they join the round.
/datum/job/proc/get_spawn_message_information()
	SHOULD_CALL_PARENT(TRUE)
	var/list/info = list()
	info += "<b>Ваша роль на станции: [job_title_ru(title)].</b>\n"
	var/related_policy = get_policy(policy_override || title)
	var/radio_info = get_radio_information()
	if(related_policy)
		info += related_policy
	if(supervisors)
		info += "Вы отвечаете непосредственно перед [supervisors]. Особые обстоятельства могут изменить это."
	if(radio_info)
		info += radio_info
	if(req_admin_notify)
		info += "<b>Вы играете на роли, важной для игрового процесса. \
			Если вы отключаетесь, пожалуйста, предупредите администрацию через F1 - Adminhelp.</b>"
	if(CONFIG_GET(number/minimal_access_threshold))
		info += span_boldnotice("Поскольку эта станция изначально была укомплектована \
			[CONFIG_GET(flag/jobs_have_minimal_access) ? "полным составом, вы будете снабжены только самым необходимым для работы" : "частично, то к вашей ID-карте может быть добавлен дополнительный доступ"]\
			.")

	return info

/// Returns information pertaining to this job's radio.
/datum/job/proc/get_radio_information()
	if(job_flags & JOB_CREW_MEMBER)
		return "<b>Для общения в радиоканале вашего отдела используйте префикс :h. Чтобы узнать все доступные каналы осмотрите наушник.</b>"

/datum/outfit/job
	name = "Standard Gear"

	var/jobtype = null

	uniform = /obj/item/clothing/under/color/grey
	id = /obj/item/card/id/advanced
	ears = /obj/item/radio/headset
	belt = /obj/item/modular_computer/pda
	back = /obj/item/storage/backpack
	shoes = /obj/item/clothing/shoes/sneakers/black
	box = /obj/item/storage/box/survival

	preload = TRUE // These are used by the prefs ui, and also just kinda could use the extra help at roundstart

	var/backpack = /obj/item/storage/backpack
	var/satchel = /obj/item/storage/backpack/satchel
	var/duffelbag = /obj/item/storage/backpack/duffelbag
	var/messenger = /obj/item/storage/backpack/messenger

	var/pda_slot = ITEM_SLOT_BELT

/datum/outfit/job/pre_equip(mob/living/carbon/human/H, visuals_only = FALSE)
	if(ispath(back, /obj/item/storage/backpack))
		switch(H.backpack)
			if(GBACKPACK)
				back = /obj/item/storage/backpack //Grey backpack
			if(GSATCHEL)
				back = /obj/item/storage/backpack/satchel //Grey satchel
			if(GDUFFELBAG)
				back = /obj/item/storage/backpack/duffelbag //Grey Duffel bag
			if(LSATCHEL)
				back = /obj/item/storage/backpack/satchel/leather //Leather Satchel
			if(GMESSENGER)
				back = /obj/item/storage/backpack/messenger //Grey messenger bag
			if(DSATCHEL)
				back = satchel //Department satchel
			if(DDUFFELBAG)
				back = duffelbag //Department duffel bag
			if(DMESSENGER)
				back = messenger //Department messenger bag
			else
				back = backpack //Department backpack

	//converts the uniform string into the path we'll wear, whether it's the skirt or regular variant
	var/holder
	if(H.jumpsuit_style == PREF_SKIRT)
		holder = "[uniform]/skirt"
		if(!text2path(holder))
			holder = "[uniform]"
	else
		holder = "[uniform]"
	uniform = text2path(holder)

	var/client/client = GLOB.directory[ckey(H.mind?.key)]

	if(client?.is_veteran() && client?.prefs.read_preference(/datum/preference/toggle/playtime_reward_cloak))
		neck = /obj/item/clothing/neck/cloak/skill_reward/playing

/datum/outfit/job/post_equip(mob/living/carbon/human/equipped, visuals_only = FALSE)
	if(visuals_only)
		return

	var/datum/job/equipped_job = SSjob.get_job_type(jobtype)

	if(!equipped_job)
		equipped_job = SSjob.get_job(equipped.job)

	var/obj/item/card/id/card = equipped.wear_id

	if(istype(card))
		ADD_TRAIT(card, TRAIT_JOB_FIRST_ID_CARD, ROUNDSTART_TRAIT)
		shuffle_inplace(card.access) // Shuffle access list to make NTNet passkeys less predictable
		card.registered_name = equipped.real_name

		if(equipped.age)
			card.registered_age = equipped.age

		card.update_label()
		card.update_icon()
		var/datum/bank_account/account = SSeconomy.bank_accounts_by_id["[equipped.account_id]"]

		if(account && account.account_id == equipped.account_id)
			card.set_account(account)

		equipped.update_ID_card()

	if(!pda_slot) //This job outfit doesn't have a PDA.
		return

	var/obj/item/modular_computer/pda/pda = equipped.get_item_by_slot(pda_slot)
	if(pda && !istype(pda)) //we found something but it isn't a PDA, check if it's inside it instead.
		pda = locate() in pda

	if(!istype(pda)) //We couldn't find a PDA at all.
		stack_trace("pda_slot was set but we couldn't find a PDA!")
		return

	pda.imprint_id(equipped.real_name, equipped_job?.title || equipped.job)
	pda.update_ringtone(equipped_job?.job_tone)
	pda.UpdateDisplay()

	var/client/equipped_client = GLOB.directory[ckey(equipped.mind?.key)]

	if(equipped_client)
		pda.update_pda_prefs(equipped_client)

/datum/outfit/job/get_chameleon_disguise_info()
	var/list/types = ..()
	types -= /obj/item/storage/backpack //otherwise this will override the actual backpacks
	types += backpack
	types += satchel
	types += duffelbag
	return types

/datum/outfit/job/get_types_to_preload()
	var/list/preload = ..()
	preload += backpack
	preload += satchel
	preload += duffelbag
	preload += /obj/item/storage/backpack/satchel/leather
	var/skirtpath = "[uniform]/skirt"
	preload += text2path(skirtpath)
	return preload

/// An overridable getter for more dynamic goodies.
/datum/job/proc/get_mail_goodies(mob/recipient)
	return mail_goodies


/datum/job/proc/award_service(client/winner, award)
	return


/datum/job/proc/get_captaincy_announcement(mob/living/captain)
	return "В связи с острой нехваткой персонала, недавно назначенный исполняющий обязанности капитана [captain.real_name] на борту!"


/// Returns an atom where the mob should spawn in.
/datum/job/proc/get_roundstart_spawn_point()
	if(random_spawns_possible)
		if(HAS_TRAIT(SSstation, STATION_TRAIT_LATE_ARRIVALS))
			return get_latejoin_spawn_point()
		if(HAS_TRAIT(SSstation, STATION_TRAIT_RANDOM_ARRIVALS))
			return get_safe_random_station_turf(typesof(/area/station/hallway)) || get_latejoin_spawn_point()
		if(HAS_TRAIT(SSstation, STATION_TRAIT_HANGOVER))
			var/obj/effect/landmark/start/hangover_spawn_point
			for(var/obj/effect/landmark/start/hangover/hangover_landmark in GLOB.start_landmarks_list)
				hangover_spawn_point = hangover_landmark
				if(hangover_landmark.used) //so we can revert to spawning them on top of eachother if something goes wrong
					continue
				hangover_landmark.used = TRUE
				break
			return hangover_spawn_point || get_latejoin_spawn_point()
	if(length(GLOB.jobspawn_overrides[title]))
		return pick(GLOB.jobspawn_overrides[title])
	var/obj/effect/landmark/start/spawn_point = get_default_roundstart_spawn_point()
	if(!spawn_point)
		spawn_point = get_generic_roundstart_spawn_point()
	if(!spawn_point) //if there isn't any roundstart spawnpoint send them to latejoin, if there's no latejoin go yell at your mapper
		return get_latejoin_spawn_point()
	return spawn_point


/// Handles finding and picking a valid roundstart effect landmark spawn point, in case no uncommon different spawning events occur.
/datum/job/proc/get_default_roundstart_spawn_point()
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.name != title)
			continue
		. = spawn_point
		if(spawn_point.used) //so we can revert to spawning them on top of eachother if something goes wrong
			continue
		spawn_point.used = TRUE
		break
	if(!.)
		log_mapping("Job [title] ([type]) couldn't find a round start spawn point.")

/// Returns a generic roundstart spawn point when a map does not define one for this job.
/datum/job/proc/get_generic_roundstart_spawn_point()
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.type != /obj/effect/landmark/start)
			continue
		. = spawn_point
		if(spawn_point.used)
			continue
		spawn_point.used = TRUE
		break
	if(.)
		log_mapping("Job [title] ([type]) is using a generic round start spawn point because no job-specific spawn point exists.")

/// Finds a valid latejoin spawn point, checking for events and special conditions.
/datum/job/proc/get_latejoin_spawn_point()
	if(length(GLOB.jobspawn_overrides[title])) //We're doing something special today.
		return pick(GLOB.jobspawn_overrides[title])
	if(length(SSjob.latejoin_trackers))
		return pick(SSjob.latejoin_trackers)
	return SSjob.get_last_resort_spawn_points()


/// Spawns the mob to be played as, taking into account preferences and the desired spawn point.
/datum/job/proc/get_spawn_mob(client/player_client, atom/spawn_point)
	var/mob/living/spawn_instance
	if(ispath(spawn_type, /mob/living/silicon/ai))
		// This is unfortunately necessary because of snowflake AI init code. To be refactored.
		spawn_instance = new spawn_type(get_turf(spawn_point), null, player_client.mob, TRUE)
	else
		spawn_instance = spawn_point.JoinPlayerHere(spawn_type, TRUE)
	spawn_instance.apply_prefs_job(player_client, src)
	if(!player_client)
		qdel(spawn_instance)
		return // Disconnected while checking for the appearance ban.
	return spawn_instance


/// Applies the preference options to the spawning mob, taking the job into account. Assumes the client has the proper mind.
/mob/living/proc/apply_prefs_job(client/player_client, datum/job/job)


/mob/living/carbon/human/apply_prefs_job(client/player_client, datum/job/job)
	var/fully_randomize = GLOB.current_anonymous_theme || player_client.prefs.should_be_random_hardcore(job, player_client.mob.mind) || is_banned_from(player_client.ckey, "Appearance")
	if(!player_client)
		return // Disconnected while checking for the appearance ban.

	var/human_authority_setting = CONFIG_GET(string/human_authority)
	var/require_human = FALSE

	// If the job in question is a head of staff,
	// check the config to see if we should force the player onto a human character or not
	if(job.job_flags & JOB_HEAD_OF_STAFF)
		switch(human_authority_setting)

			// If non-humans are the norm and jobs must be forced to be only for humans
			// then we only force the player to be a human if the job exclusively allows humans
			if(HUMAN_AUTHORITY_HUMAN_WHITELIST)
				require_human = job.human_authority == JOB_AUTHORITY_HUMANS_ONLY

			// If humans are the norm and jobs must be allowed to be played by non-humans
			// then we only force the player to be a human if the job doesn't allow for non-humans to play it
			if(HUMAN_AUTHORITY_NON_HUMAN_WHITELIST)
				require_human = job.human_authority != JOB_AUTHORITY_NON_HUMANS_ALLOWED

			// If humans are the norm and there is no chance that a non-human can be a head of staff
			// always return true, since there is no chance that a non-human can be a head of staff.
			if(HUMAN_AUTHORITY_ENFORCED)
				require_human = TRUE

	src.job = job.title

	var/randomise_job_slot = player_client.prefs.set_assigned_slot(job.title, player_client.mob?.mind?.late_joiner) // BANDASTATION ADDITION - Pref Job Slots
	if(fully_randomize || randomise_job_slot)  // BANDASTATION EDIT - Pref Job Slots - OLD: if(fully_randomize)
		player_client.prefs.apply_prefs_to(src)

		if(require_human)
			randomize_human_appearance(~RANDOMIZE_SPECIES)
		else
			randomize_human_appearance()

		if (require_human)
			set_species(/datum/species/human)
			dna.species.roundstart_changed = TRUE

		if(GLOB.current_anonymous_theme)
			fully_replace_character_name(null, GLOB.current_anonymous_theme.anonymous_name(src))
	else
		var/is_antag = (player_client.mob.mind in GLOB.pre_setup_antags)
		if(require_human)
			player_client.prefs.randomise["species"] = FALSE
		player_client.prefs.safe_transfer_prefs_to(src, TRUE, is_antag)
		if(require_human && !ishumanbasic(src))
			set_species(/datum/species/human)
			dna.species.roundstart_changed = TRUE
			apply_pref_name(/datum/preference/name/backup_human, player_client)
		if(CONFIG_GET(flag/force_random_names))
			real_name = generate_random_name_species_based(
				player_client.prefs.read_preference(/datum/preference/choiced/gender),
				TRUE,
				player_client.prefs.read_preference(/datum/preference/choiced/species),
			)
	dna.update_dna_identity()
	updateappearance()

/mob/living/silicon/ai/apply_prefs_job(client/player_client, datum/job/job)
	if(GLOB.current_anonymous_theme)
		fully_replace_character_name(real_name, GLOB.current_anonymous_theme.anonymous_ai_name(TRUE))
		return
	apply_pref_name(/datum/preference/name/ai, player_client) // This proc already checks if the player is appearance banned.
	set_core_display_icon(null, player_client)
	apply_pref_emote_display(player_client)
	apply_pref_hologram_display(player_client)

/mob/living/silicon/robot/apply_prefs_job(client/player_client, datum/job/job)
	if(mmi)
		var/organic_name
		if(GLOB.current_anonymous_theme)
			organic_name = GLOB.current_anonymous_theme.anonymous_name(src)
		else if(player_client.prefs.read_preference(/datum/preference/choiced/random_name) == RANDOM_ENABLED || CONFIG_GET(flag/force_random_names) || is_banned_from(player_client.ckey, "Appearance"))
			if(!player_client)
				return // Disconnected while checking the appearance ban.

			organic_name = generate_random_name_species_based(
				player_client.prefs.read_preference(/datum/preference/choiced/gender),
				TRUE,
				player_client.prefs.read_preference(/datum/preference/choiced/species),
			)
		else
			if(!player_client)
				return // Disconnected while checking the appearance ban.
			organic_name = player_client.prefs.read_preference(/datum/preference/name/real_name)

		mmi.name = "[initial(mmi.name)]: [organic_name]"
		if(mmi.brain)
			mmi.brain.name = "[organic_name]'s brain"
		if(mmi.brainmob)
			mmi.brainmob.real_name = organic_name //the name of the brain inside the cyborg is the robotized human's name.
			mmi.brainmob.name = organic_name
	// If this checks fails, then the name will have been handled during initialization.
	if(!GLOB.current_anonymous_theme && player_client.prefs.read_preference(/datum/preference/name/cyborg) != DEFAULT_CYBORG_NAME)
		apply_pref_name(/datum/preference/name/cyborg, player_client)

/**
 * Called after a successful roundstart spawn.
 * Client is not yet in the mob.
 * This happens after after_spawn()
 */
/datum/job/proc/after_roundstart_spawn(mob/living/spawning, client/player_client)
	SHOULD_CALL_PARENT(TRUE)


/**
 * Called after a successful latejoin spawn.
 * Client is in the mob.
 * This happens after after_spawn()
 */
/datum/job/proc/after_latejoin_spawn(mob/living/spawning)
	SHOULD_CALL_PARENT(TRUE)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN, src, spawning)

/// Called when a mob that has this job is admin respawned
/datum/job/proc/on_respawn(mob/new_character)
	SSjob.equip_rank(new_character, new_character.mind.assigned_role, new_character.client)

/// This proc may be called when someone of this job is made into a traitor to create custom objectives related to the job.
/datum/job/proc/generate_traitor_objective()
	return null

/// Returns a large (due to cropping) icon of this job's sechud icon state.
/datum/job/proc/get_lobby_icon() as /icon
	var/datum/outfit/job_outfit = outfit
	if(!job_outfit || !job_outfit::id_trim)
		CRASH("[src.type] has no job outfit but isn't overwriting get_lobby_icon().")
	var/datum/id_trim/job_trim = job_outfit::id_trim
	var/icon_state = job_trim::sechud_icon_state
	if(!icon_state || icon_state == SECHUD_UNKNOWN)
		CRASH("[src.type] has no job icon state.")

	return icon('icons/mob/huds/hud.dmi', icon_state)
