//CYBERPUNK CORPORATIONS - Benn edicts.
/obj/structure/sign/departments/science/cyberpunk_test_gene_edict
	name = "Переключатель тестового эдикта Бэнь"
	desc = "Нажми рукой, чтобы включить или выключить «Генную комбинаторику». Сравни стоимость одного и того же гена на двух свежих пачках пшеницы."

/obj/structure/sign/departments/science/cyberpunk_test_gene_edict/examine(mob/user)
	. = ..()
	var/active = SScyberpunk_corporations.cyberpunk_corporation_has_edict(CYBERPUNK_CORP_BENN, "benn_gene_combo")
	. += span_notice("Генная комбинаторика: [active ? "включена" : "выключена"].")

/obj/structure/sign/departments/science/cyberpunk_test_gene_edict/attack_hand(mob/user, list/modifiers)
	if(SSmapping.current_map?.map_name != "Cyberpunk Test" || !isliving(user) || !Adjacent(user))
		return ..()
	var/datum/cyberpunk_corporation/corporation = SScyberpunk_corporations.get_cyberpunk_corporation(CYBERPUNK_CORP_BENN)
	if(!corporation)
		return TRUE
	var/active = corporation.active_edicts["4"]
	if(active && active != "benn_gene_combo")
		to_chat(user, span_warning("У Бэнь уже выбран другой эдикт 4-го уровня."))
		return TRUE
	if(active)
		corporation.active_edicts -= "4"
	else
		corporation.active_edicts["4"] = "benn_gene_combo"
	balloon_alert(user, active ? "эдикт выключен" : "эдикт включён")
	return TRUE

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
		list("id" = "benn_gene_combo", "name" = "Gene Combinatorics", "level" = 4, "description" = "On Benn property, DNA console delays and plant gene mixing time and point costs are reduced."),
		list("id" = "benn_chem_tuning", "name" = "Chemical Tuning", "level" = 4, "description" = "Benn chemical plants work faster on Benn property."),
		list("id" = "benn_med_observation", "name" = "Medical Observation", "level" = 5, "description" = "Benn vendors can dispatch paid treatment drones to wounded citizens."),
		list("id" = "benn_dna_storage", "name" = "DNA Storage", "level" = 5, "description" = "Benn vendors, drones, and clinical revivals add research and copy recognizable foreign technology. Recovering nonemployees yields more data."),
		list("id" = "benn_chem_guardians", "name" = "Chemical Guardians", "level" = 5, "description" = "Threats near Benn infrastructure can trigger acidic defensive drones.")
	)
