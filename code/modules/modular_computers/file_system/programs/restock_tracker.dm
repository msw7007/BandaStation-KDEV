/datum/computer_file/program/restock_tracker
	filename = "restockapp"
	filedesc = "NT Restock Tracker"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "restock"
	extended_desc = "Сеть Nanotrasen IoT, в которой перечислены все торговые автоматы, находящиеся на станции, и насколько хорошо укомплектован каждый из них. Прибыльно!"
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = "cash-register"
	tgui_id = "NtosRestock"

/datum/computer_file/program/restock_tracker/ui_data()
	var/list/data = list()
	var/list/vending_list = list()
	var/id_increment = 1
	for(var/obj/machinery/vending/vendor as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
		if(vendor.all_products_free)
			continue
		var/list/total_legal_stock = vendor.total_stock(contrabrand = FALSE)
		if((!total_legal_stock[2] || (total_legal_stock[1] >= total_legal_stock[2])) && !vendor.credits_contained)
			continue
		vending_list += list(list(
			"name" = vendor.name,
			"location" = get_area_name(vendor),
			"credits" = vendor.credits_contained,
			"percentage" = (total_legal_stock[1] / total_legal_stock[2]) * 100,
			"id" = id_increment,
		))
		id_increment++
	data["vending_list"] = vending_list
	return data

//CYBERPUNK BUILD - rebuild and delete before release
/datum/computer_file/program/contracts
	filename = "contracts"
	filedesc = "Contracts"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "A public and private contract board for paid work, deposits, deadlines, and completion tracking."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 6
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContracts"
	/// Direct contract id loaded by the user. Used for private/illegal contracts that are not listed publicly.
	var/direct_contract_id

/datum/computer_file/program/contracts/ui_data(mob/user)
	return cyberpunk_contracts_ui_data(user, direct_contract_id)

/datum/computer_file/program/contracts/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "direct_lookup")
		direct_contract_id = params["id"]
		return TRUE
	return cyberpunk_contracts_ui_act(action, params, ui.user)

/datum/computer_file/program/contract_registry
	filename = "contractregistry"
	filedesc = "Contract Registry"
	downloader_category = PROGRAM_CATEGORY_SECURITY
	program_open_overlay = "generic"
	extended_desc = "A legal contract registry. Criminal and off-ledger contracts are not indexed."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContractRegistry"

/datum/computer_file/program/contract_registry/ui_data(mob/user)
	return cyberpunk_contract_registry_ui_data(user)

/datum/computer_file/program/contract_pool
	filename = "contractpool"
	filedesc = "Contract Pool"
	downloader_category = PROGRAM_CATEGORY_SUPPLY
	program_open_overlay = "generic"
	extended_desc = "Corporate pool contracts. These jobs are public offers and can be taken by any contractor."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 4
	program_icon = FA_ICON_FILE_CONTRACT
	tgui_id = "NtosContractPool"

/datum/computer_file/program/contract_pool/ui_data(mob/user)
	return cyberpunk_contract_pool_ui_data(user)

/datum/computer_file/program/contract_pool/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_pool_ui_act(action, params, ui.user)

/datum/computer_file/program/cyberpunk_pc_interface
	filename = "cityshell"
	filedesc = "City Shell"
	downloader_category = PROGRAM_CATEGORY_DEVICE
	program_open_overlay = "generic"
	extended_desc = "A city workstation shell for contracts, corporate systems, network cracking, mail, and local services."
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	can_run_on_flags = PROGRAM_ALL
	size = 6
	program_icon = "desktop"
	tgui_id = "CyberpunkPcInterface"

/datum/computer_file/program/cyberpunk_pc_interface/ui_data(mob/user)
	return cyberpunk_pc_interface_ui_data(user)

/datum/computer_file/program/cyberpunk_pc_interface/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_pc_interface_ui_act(action, params, ui.user)

//CYBERPUNK BUILD - rebuild and delete before release
/datum/cyberpunk_contracts_verb_ui
	var/direct_contract_id

/datum/cyberpunk_contracts_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contracts_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContracts", "Contracts")
		ui.open()

/datum/cyberpunk_contracts_verb_ui/ui_data(mob/user)
	return cyberpunk_contracts_ui_data(user, direct_contract_id)

/datum/cyberpunk_contracts_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "direct_lookup")
		direct_contract_id = params["id"]
		return TRUE
	return cyberpunk_contracts_ui_act(action, params, ui.user)

/datum/cyberpunk_contract_registry_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_registry_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractRegistry", "Contract Registry")
		ui.open()

/datum/cyberpunk_contract_registry_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_registry_ui_data(user)

/datum/cyberpunk_contract_pool_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_pool_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractPool", "Contract Pool")
		ui.open()

/datum/cyberpunk_contract_pool_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_pool_ui_data(user)

/datum/cyberpunk_contract_pool_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_pool_ui_act(action, params, ui.user)

/datum/cyberpunk_contract_offer_verb_ui
	var/contract_id

/datum/cyberpunk_contract_offer_verb_ui/New(new_contract_id)
	. = ..()
	contract_id = new_contract_id

/datum/cyberpunk_contract_offer_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_contract_offer_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosContractOffer", "Contract Offer")
		ui.open()

/datum/cyberpunk_contract_offer_verb_ui/ui_data(mob/user)
	return cyberpunk_contract_offer_ui_data(user, contract_id)

/datum/cyberpunk_contract_offer_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_contract_offer_ui_act(action, params, ui.user, contract_id)

/datum/cyberpunk_skill_interface_verb_ui
	var/diagnostic_access = FALSE

/datum/cyberpunk_skill_interface_verb_ui/New(new_diagnostic_access = FALSE)
	. = ..()
	diagnostic_access = new_diagnostic_access

/datum/cyberpunk_skill_interface_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_skill_interface_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		if(user.client?.prefs && !user.client.prefs.character_preview_view)
			user.client.prefs.create_character_preview_view(user)
		ui = new(user, src, "CyberpunkSkillInterface", "Skill Interface")
		ui.open()
		user.client?.prefs?.character_preview_view?.display_to(user, ui.window)

/datum/cyberpunk_skill_interface_verb_ui/ui_data(mob/user)
	return cyberpunk_skill_interface_ui_data(user, diagnostic_access)

/datum/cyberpunk_skill_interface_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_skill_interface_ui_act(action, params, ui.user, diagnostic_access)

/datum/cyberpunk_pc_interface_verb_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/cyberpunk_pc_interface_verb_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkPcInterface", "PC Interface")
		ui.open()

/datum/cyberpunk_pc_interface_verb_ui/ui_data(mob/user)
	return cyberpunk_pc_interface_ui_data(user)

/datum/cyberpunk_pc_interface_verb_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return cyberpunk_pc_interface_ui_act(action, params, ui.user)

/mob/living/verb/open_cyberpunk_contracts()
	set name = "Контракты"
	set desc = "Временно открыть приложение контрактов без КПК."
	set category = "IC"

	var/datum/cyberpunk_contracts_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_contract_registry()
	set name = "Реестр контрактов"
	set desc = "Временно открыть легальный реестр контрактов без КПК."
	set category = "IC"

	var/datum/cyberpunk_contract_registry_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_contract_pool()
	set name = "Contract Pool"
	set desc = "Temporarily open corporate pool contracts without a PDA."
	set category = "IC"

	var/datum/cyberpunk_contract_pool_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_corporations()
	set name = "Corporate Interface"
	set desc = "Temporarily open the corporate research and decisions interface."
	set category = "IC"

	var/datum/cyberpunk_corporations_verb_ui/interface = new
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_neurolink_interface()
	set name = "Skill Interface"
	set desc = "Open your neural skill interface."
	set category = "IC"

	if(!has_neural_implant())
		to_chat(src, span_warning("You need a functional neural interface or a diagnostic analysis machine."))
		return

	var/datum/cyberpunk_skill_interface_verb_ui/interface = new(FALSE)
	interface.ui_interact(src)

/mob/living/verb/open_cyberpunk_pc_interface()
	set name = "PC Interface"
	set desc = "Open the city personal computer interface shell."
	set category = "IC"

	var/datum/cyberpunk_pc_interface_verb_ui/interface = new
	interface.ui_interact(src)

/obj/machinery/computer/diagnostic_analysis
	name = "diagnostic analysis machine"
	desc = "A medical-grade diagnostic station that can inspect and tune a patient's skill interface without a neural implant."
	icon_screen = "medcomp"
	icon_keyboard = "med_key"
	light_color = LIGHT_COLOR_CYAN
	circuit = null
	cyberpunk_public_access = TRUE

/obj/machinery/computer/diagnostic_analysis/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/diagnostic_analysis/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	var/datum/cyberpunk_skill_interface_verb_ui/interface = new(TRUE)
	interface.ui_interact(user)

/mob/living/verb/create_diagnostic_analysis_machine()
	set name = "Create Diagnostic Analysis Machine"
	set desc = "Temporarily create a diagnostic analysis machine for testing."
	set category = "IC"

	new /obj/machinery/computer/diagnostic_analysis(get_turf(src))

/obj/machinery/computer/apartment_terminal
	name = "apartment terminal"
	desc = "A residential persistence terminal. It binds an apartment area to a neural interface owner."
	icon_screen = "supply"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE
	circuit = null
	var/apartment_id
	cyberpunk_public_access = TRUE

/obj/machinery/computer/apartment_terminal/Destroy()
	var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.get_cyberpunk_apartment(apartment_id)
	if(apartment?.terminal == src)
		apartment.terminal = null
	return ..()

/obj/machinery/computer/apartment_terminal/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/computer/apartment_terminal/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NtosApartmentTerminal", name)
		ui.open()

/obj/machinery/computer/apartment_terminal/ui_data(mob/user)
	return cyberpunk_apartment_terminal_ui_data(user, apartment_id, src)

/obj/machinery/computer/apartment_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "select")
		apartment_id = params["id"]
		return TRUE
	return cyberpunk_apartment_terminal_ui_act(action, params, ui.user, src, apartment_id)

/mob/living/verb/create_cyberpunk_apartment_terminal()
	set name = "Create Apartment Terminal"
	set desc = "Temporarily create an apartment persistence terminal for testing."
	set category = "IC"

	new /obj/machinery/computer/apartment_terminal(get_turf(src))

//CYBERPUNK BUILD - rebuild and delete before release

/proc/cyberpunk_skill_interface_ui_data(mob/user, diagnostic_access = FALSE)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/mind/user_mind = user?.mind
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = living_user?.get_neural_interface()
	var/has_neural = living_user?.has_neural_implant() || FALSE
	var/access_granted = has_neural || diagnostic_access
	user_mind?.recalculate_character_skill_point_pools()

	var/obj/item/card/id/access_card = living_user?.get_cyberpunk_access_card()
	data["userName"] = user?.name || "unknown"
	data["hasNeuralInterface"] = has_neural
	data["diagnosticAccess"] = !!diagnostic_access
	data["accessGranted"] = access_granted
	data["implantEnabled"] = neural_interface?.skill_interface_enabled || FALSE
	data["accessCard"] = access_card?.name
	data["memoryKeys"] = length(living_user?.cyberpunk_crypto_memory)
	data["levelPoints"] = user_mind?.level_points || 0
	data["skillPoints"] = user_mind?.skill_points || 0
	data["professionalSkillPoints"] = user_mind?.professional_skill_points || 0
	data["weaponSkillPoints"] = user_mind?.weapon_skill_points || 0
	data["unconvertedExperience"] = user_mind?.unconverted_general_experience || 0
	data["generalExperienceMax"] = ATTRIBUTE_LEVEL_POINT_EXPERIENCE
	data["attributes"] = cyberpunk_skill_interface_build_attributes(user_mind)
	data["skills"] = cyberpunk_skill_interface_build_skills(user_mind, access_granted)
	data["skillchips"] = cyberpunk_skill_interface_build_skillchips(living_user)
	data["implantMetrics"] = cyberpunk_skill_interface_build_implant_metrics(living_user, user_mind)
	data["implants"] = cyberpunk_skill_interface_build_implants(living_user)
	data["characterPreviewView"] = user?.client?.prefs?.character_preview_view?.assigned_map
	return data

/proc/cyberpunk_skill_interface_build_attributes(datum/mind/user_mind)
	var/list/attributes = list()
	for(var/attribute_id in ATTRIBUTE_ALL)
		attributes[attribute_id] = list(
			"value" = user_mind?.get_attribute_value(attribute_id) || ATTRIBUTE_DEFAULT,
			"min" = ATTRIBUTE_MINIMUM,
			"max" = ATTRIBUTE_MAXIMUM,
			"super_threshold" = ATTRIBUTE_SUPER_THRESHOLD,
			"editable" = FALSE,
			"disabled_reason" = "Runtime skill interface cannot alter base attributes.",
		)
	return attributes

/proc/cyberpunk_skill_interface_build_skills(datum/mind/user_mind, can_edit = FALSE)
	var/list/skills = list()
	for(var/skill_type in GLOB.skill_types)
		var/datum/skill/skill_path = skill_type
		if(initial(skill_path.abstract_type) == skill_type)
			continue
		var/datum/skill/skill_datum = GetSkillRef(skill_type)
		if(!skill_datum || !skill_datum.is_character_skill())
			continue
		var/list/perks = list()
		var/list/runtime_perks = list()
		if(skill_datum.uses_perks())
			for(var/perk_index in 1 to length(skill_datum.perks))
				var/datum/skill_perk/perk = skill_datum.get_perk(perk_index)
				var/perk_rank = user_mind?.get_character_perk_rank(skill_type, perk_index) || 0
				var/independent_perk = !skill_datum.requires_sequential_perks
				var/can_increase = can_edit && (user_mind?.can_set_character_perk_rank(skill_type, perk_index, perk_rank + 1, FALSE, independent_perk) || FALSE)
				var/can_decrease = can_edit && (user_mind?.can_set_character_perk_rank(skill_type, perk_index, perk_rank - 1, FALSE, independent_perk) || FALSE)
				perks += list(perk?.get_static_data() || list(
					"index" = perk_index,
					"name" = "Perk",
					"description" = "",
					"rank_descriptions" = list(),
					"max_rank" = skill_datum.max_perk_rank,
				))
				runtime_perks["[perk_index]"] = list(
					"rank" = perk_rank,
					"can_increase" = can_increase,
					"can_decrease" = can_decrease,
				)
		var/level = user_mind?.get_character_skill_level(skill_type) || CHARACTER_SKILL_LEVEL_NONE
		var/list/entry = list(
			"id" = "[skill_type]",
			"name" = skill_datum.name,
			"title" = skill_datum.title,
			"description" = skill_datum.desc,
			"kind" = skill_datum.skill_kind,
			"attributeId" = skill_datum.attribute_id,
			"attribute_id" = skill_datum.attribute_id,
			"level" = level,
			"levelName" = SSskills.character_level_names[clamp(level + 1, 1, length(SSskills.character_level_names))],
			"maxLevel" = skill_datum.max_character_level,
			"max_character_level" = skill_datum.max_character_level,
			"max_perk_rank" = skill_datum.max_perk_rank,
			"point_pool" = skill_datum.point_pool,
			"requires_sequential_perks" = skill_datum.requires_sequential_perks,
			"giga_perk_name" = skill_datum.giga_perk_name,
			"giga_perk_desc" = skill_datum.giga_perk_desc,
			"spentPoints" = user_mind?.get_character_skill_spent_points(skill_type) || 0,
			"spent_points" = user_mind?.get_character_skill_spent_points(skill_type) || 0,
			"convertedExperience" = user_mind?.converted_skill_experience[skill_type] || 0,
			"pendingExperience" = user_mind?.pending_skill_experience[skill_type] || 0,
			"experienceGoal" = ATTRIBUTE_LEVEL_POINT_EXPERIENCE,
			"perks" = perks,
			"canIncrease" = can_edit && user_mind?.can_pay_character_skill_points(skill_type, 1) && level < skill_datum.max_character_level,
			"canDecrease" = can_edit && level > CHARACTER_SKILL_LEVEL_NONE,
			"can_increase" = can_edit && user_mind?.can_pay_character_skill_points(skill_type, 1) && level < skill_datum.max_character_level,
			"can_decrease" = can_edit && level > CHARACTER_SKILL_LEVEL_NONE,
			"editable" = can_edit && !!user_mind,
			"disabled_reason" = can_edit ? null : "Neural interface or diagnostic access required.",
			"runtime_perks" = runtime_perks,
			"weaponDamageBonus" = skill_datum.weapon_damage_bonus_per_level,
			"weaponCooldownReduction" = skill_datum.weapon_cooldown_reduction_per_level,
			"weaponDefenseBreakBonus" = skill_datum.weapon_defense_break_bonus_per_level,
			"weapon_damage_bonus_per_level" = skill_datum.weapon_damage_bonus_per_level,
			"weapon_cooldown_reduction_per_level" = skill_datum.weapon_cooldown_reduction_per_level,
			"weapon_defense_break_bonus_per_level" = skill_datum.weapon_defense_break_bonus_per_level,
		)
		skills += list(entry)
	return skills

/proc/cyberpunk_skill_interface_build_skillchips(mob/living/living_user)
	var/list/chips = list()
	var/obj/item/organ/brain/chippy_brain = living_user?.get_organ_by_type(/obj/item/organ/brain)
	for(var/obj/item/skillchip/skillchip as anything in chippy_brain?.skillchips)
		chips += list(list(
			"name" = skillchip.name,
			"ref" = REF(skillchip),
		))
	return chips

/proc/cyberpunk_skill_interface_build_implant_metrics(mob/living/living_user, datum/mind/user_mind)
	var/chromity_max = CHROMITY_DEFAULT
	var/compatibility_bonus = user_mind?.get_character_perk_effectiveness(SKILL_COMPATIBILITY, 2) || 0
	if(compatibility_bonus > 0)
		chromity_max += round(CHROMITY_DEFAULT * (compatibility_bonus / 100))
	var/ice_chromity_penalty = living_user?.get_neural_ice_chromity_penalty() || 0
	var/chromity_used = ice_chromity_penalty
	var/mob/living/carbon/carbon_user = iscarbon(living_user) ? living_user : null
	for(var/obj/item/organ/organ as anything in carbon_user?.organs)
		var/obj/item/organ/cyberimp/implant = organ
		if(!istype(implant))
			continue
		chromity_used += implant.chromity_overheat
	return list(
		"chromity" = max(0, chromity_max - chromity_used),
		"chromityMax" = chromity_max,
		"chromityUsed" = chromity_used,
		"iceChromityPenalty" = ice_chromity_penalty,
		"overheat" = living_user?.chromity_overheat || 0,
		"overheatFloor" = living_user?.get_chromity_overheat_floor() || 0,
	)

/proc/cyberpunk_skill_interface_implant_body_part(obj/item/organ/cyberimp/implant)
	if(!implant)
		return "torso"
	switch(implant.slot)
		if(ORGAN_SLOT_RIGHT_ARM_AUG)
			return "right_arm"
		if(ORGAN_SLOT_LEFT_ARM_AUG)
			return "left_arm"
		if(ORGAN_SLOT_RIGHT_LEG_AUG)
			return "right_leg"
		if(ORGAN_SLOT_LEFT_LEG_AUG)
			return "left_leg"
		if(ORGAN_SLOT_SPINE, ORGAN_SLOT_HEART, ORGAN_SLOT_LUNGS, ORGAN_SLOT_STOMACH, ORGAN_SLOT_LIVER, ORGAN_SLOT_BELLY_AUG, ORGAN_SLOT_CHEST_AUG)
			return "torso"
		if(ORGAN_SLOT_NECK_AUG, ORGAN_SLOT_NEURAL_IMPLANT, ORGAN_SLOT_OS, ORGAN_SLOT_BRAIN, ORGAN_SLOT_EYES, ORGAN_SLOT_EARS, ORGAN_SLOT_TONGUE, ORGAN_SLOT_EYELID_AUG)
			return "head"
	switch(implant.zone)
		if(BODY_ZONE_R_ARM)
			return "right_arm"
		if(BODY_ZONE_L_ARM)
			return "left_arm"
		if(BODY_ZONE_R_LEG)
			return "right_leg"
		if(BODY_ZONE_L_LEG)
			return "left_leg"
		if(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_PRECISE_NECK)
			return "head"
	return "torso"

/proc/cyberpunk_skill_interface_build_implants(mob/living/living_user)
	var/list/implants = list()
	var/mob/living/carbon/carbon_user = iscarbon(living_user) ? living_user : null
	for(var/obj/item/organ/organ as anything in carbon_user?.organs)
		var/obj/item/organ/cyberimp/implant = organ
		if(!istype(implant))
			continue
		var/is_neural_interface = istype(implant, /obj/item/organ/cyberimp/brain/neural_interface)
		implants += list(list(
			"ref" = REF(implant),
			"name" = implant.name,
			"description" = implant.desc,
			"slot" = implant.slot,
			"bodyPart" = cyberpunk_skill_interface_implant_body_part(implant),
			"tier" = implant.implant_tier,
			"corp" = implant.corp_manufacturer,
			"chromity" = implant.chromity_overheat,
			"activeOverheat" = implant.chromity_active_overheat_floor,
			"damage" = round(implant.damage, 0.1),
			"maxHealth" = round(implant.maxHealth, 0.1),
			"functional" = implant.is_implant_functional(),
			"toggleable" = implant.can_skill_interface_toggle(),
			"active" = implant.get_skill_interface_active(),
			"isNeuralInterface" = is_neural_interface,
		))
	return implants

/proc/cyberpunk_skill_interface_ui_act(action, list/params, mob/user, diagnostic_access = FALSE)
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/mind/user_mind = user?.mind
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = living_user?.get_neural_interface()
	var/has_neural = living_user?.has_neural_implant() || FALSE
	var/access_granted = has_neural || diagnostic_access
	if(!access_granted)
		return FALSE
	switch(action)
		if("toggle_implant")
			return FALSE
		if("toggle_cyberimp")
			if(!living_user || !has_neural)
				return FALSE
			var/obj/item/organ/cyberimp/implant = locate(params["ref"])
			if(!istype(implant))
				return FALSE
			return implant.skill_interface_toggle(living_user)
		if("sync_card")
			if(!living_user || !neural_interface)
				return FALSE
			var/result = living_user.sync_cyberpunk_access_card_to_neural_interface()
			to_chat(living_user, span_notice(result))
			return TRUE
		if("install_skillchip")
			if(!living_user || !neural_interface)
				return FALSE
			var/obj/item/held_item = living_user.get_active_held_item()
			var/obj/item/skillchip/skillchip = held_item
			if(!istype(skillchip))
				to_chat(living_user, span_warning("Hold a skillchip in your active hand."))
				return FALSE
			neural_interface.insert_skillchip(skillchip)
			return TRUE
		if("remove_skillchip")
			if(!living_user || !neural_interface)
				return FALSE
			var/obj/item/organ/brain/chippy_brain = living_user.get_organ_by_type(/obj/item/organ/brain)
			if(!chippy_brain)
				return FALSE
			neural_interface.remove_skillchip(chippy_brain)
			return TRUE
		if("adjust_perk")
			if(!user_mind)
				return FALSE
			var/skill_type = text2path(params["skill"])
			if(!ispath(skill_type, /datum/skill))
				return FALSE
			var/raw_perk_index = params["perkIndex"]
			var/raw_delta = params["delta"]
			var/perk_index = round(text2num("[raw_perk_index]") || 0)
			var/delta = round(text2num("[raw_delta]") || 0)
			if(!perk_index || !delta)
				return FALSE
			var/datum/skill/skill_datum = GetSkillRef(skill_type)
			if(!skill_datum || !skill_datum.uses_perks())
				return FALSE
			var/independent_perk = !skill_datum.requires_sequential_perks
			return user_mind.adjust_character_perk_rank(skill_type, perk_index, delta, FALSE, independent_perk)
		if("adjust_skill_level")
			if(!user_mind)
				return FALSE
			var/skill_type = text2path(params["skill"])
			if(!ispath(skill_type, /datum/skill))
				return FALSE
			var/raw_delta = params["delta"]
			var/delta = round(text2num("[raw_delta]") || 0)
			if(!delta)
				return FALSE
			var/datum/skill/skill_datum = GetSkillRef(skill_type)
			if(!skill_datum || skill_datum.skill_kind != CHARACTER_SKILL_KIND_WEAPON)
				return FALSE
			return user_mind.adjust_character_skill_level(skill_type, delta)
	return FALSE

/proc/cyberpunk_pc_interface_ui_data(mob/user)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	var/obj/item/card/id/access_card = living_user?.get_cyberpunk_access_card()
	data["userName"] = user?.name || "unknown"
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["hasNeuralInterface"] = living_user?.has_neural_implant() || FALSE
	data["accessCard"] = access_card?.name
	data["memoryKeys"] = length(living_user?.cyberpunk_crypto_memory)
	data["apps"] = list(
		list("id" = "contracts", "name" = "Contracts", "category" = "Work", "status" = "ready", "description" = "Create, accept, and track contracts."),
		list("id" = "registry", "name" = "Contract Registry", "category" = "Work", "status" = "ready", "description" = "Legal contract history and public records."),
		list("id" = "pool", "name" = "Contract Pool", "category" = "Corporate", "status" = "ready", "description" = "Corporate pool jobs paid from corp budgets."),
		list("id" = "corporations", "name" = "Corporations", "category" = "Corporate", "status" = "ready", "description" = "Research, edicts, services, and budgets."),
		list("id" = "appcracker", "name" = "App Cracker", "category" = "Net", "status" = "program", "description" = "Command-line access to nearby cyberspace nodes."),
		list("id" = "mail", "name" = "Mail", "category" = "City", "status" = "planned", "description" = "Terminal mail, cargo pickup, and delivery notices."),
		list("id" = "business", "name" = "Business", "category" = "City", "status" = "terminal", "description" = "Business management is routed through business terminals."),
		list("id" = "files", "name" = "Files", "category" = "System", "status" = "local", "description" = "Local file system and inserted disks."),
	)
	data["activity"] = list(
		"City shell mounted.",
		"NTNet route accepted.",
		"Local app index synchronized.",
	)
	return data

/proc/cyberpunk_pc_interface_ui_act(action, list/params, mob/user)
	switch(action)
		if("open_app")
			var/app_id = params["app"]
			switch(app_id)
				if("contracts")
					var/datum/cyberpunk_contracts_verb_ui/interface = new
					interface.ui_interact(user)
					return TRUE
				if("registry")
					var/datum/cyberpunk_contract_registry_verb_ui/interface = new
					interface.ui_interact(user)
					return TRUE
				if("pool")
					var/datum/cyberpunk_contract_pool_verb_ui/interface = new
					interface.ui_interact(user)
					return TRUE
				if("corporations")
					var/datum/cyberpunk_corporations_verb_ui/interface = new
					interface.ui_interact(user)
					return TRUE
			to_chat(user, span_notice("This app is installed as a computer program or awaits a dedicated terminal."))
			return TRUE
	return FALSE

/proc/cyberpunk_contracts_ui_data(mob/user, direct_contract_id = null)
	SSeconomy.ensure_cyberpunk_contract_pool_seeded()
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	var/user_character_key = SSeconomy.get_cyberpunk_contract_character_key(living_user, account)
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["userStats"] = SSeconomy.get_cyberpunk_contract_stats(user_character_key)
	data["contracts"] = list()
	data["offeredContracts"] = list()
	data["ownedContracts"] = list()
	data["acceptedContracts"] = list()
	data["directContract"] = null
	data["terminalOptions"] = SSeconomy.get_cyberpunk_contract_terminal_options()
	data["fundingOptions"] = list(list(
		"id" = 0,
		"name" = "Personal account",
		"balance" = account?.account_balance || 0,
	))
	for(var/datum/cyberpunk_business/business as anything in SScyberpunk_property.get_cyberpunk_businesses_for_user(living_user))
		if(!business?.has_access(living_user, CYBERPUNK_BUSINESS_ACCESS_CONTRACTS))
			continue
		var/datum/bank_account/business_account = business.get_account()
		data["fundingOptions"] += list(list(
			"id" = business.id,
			"name" = business.name,
			"balance" = business_account?.account_balance || 0,
		))
	for(var/contract_id in SSeconomy.cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = SSeconomy.cyberpunk_contracts[contract_id]
		if(!contract || !contract.can_view(living_user))
			continue
		var/list/contract_data = contract.to_ui_data(living_user, TRUE)
		if(contract.creator_character_key == user_character_key || contract.can_manage(living_user))
			data["ownedContracts"] += list(contract_data)
		if(contract.contractor_character_key == user_character_key)
			data["acceptedContracts"] += list(contract_data)
		if(contract.assigned_contractor_key == user_character_key && contract.status == "offered")
			data["offeredContracts"] += list(contract_data)
		if(contract.public_contract && contract.legal && contract.status == "created")
			data["contracts"] += list(contract_data)
	var/datum/cyberpunk_contract/direct_contract = SSeconomy.get_cyberpunk_contract(direct_contract_id)
	if(direct_contract?.can_direct_lookup(living_user, direct_contract_id))
		data["directContract"] = direct_contract.to_ui_data(living_user, TRUE)
	else
		for(var/contract_key in SSeconomy.cyberpunk_contracts)
			var/datum/cyberpunk_contract/private_contract = SSeconomy.cyberpunk_contracts[contract_key]
			if(private_contract?.can_direct_lookup(living_user, direct_contract_id))
				data["directContract"] = private_contract.to_ui_data(living_user, TRUE)
				break
	return data

/proc/cyberpunk_contract_pool_ui_data(mob/user)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["contracts"] = list()
	for(var/datum/cyberpunk_contract/contract as anything in SSeconomy.get_cyberpunk_contract_pool())
		if(!contract || !contract.can_view(living_user))
			continue
		data["contracts"] += list(contract.to_ui_data(living_user, TRUE))
	return data

/proc/cyberpunk_contract_offer_ui_data(mob/user, contract_id)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/cyberpunk_contract/contract = SSeconomy.get_cyberpunk_contract(contract_id)
	data["contract"] = contract?.can_view(living_user) ? contract.to_ui_data(living_user, TRUE) : null
	return data

/proc/cyberpunk_apartment_terminal_ui_data(mob/user, selected_apartment_id = null, obj/machinery/computer/apartment_terminal/terminal = null)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	var/datum/bank_account/account = living_user?.get_bank_account()
	data["accountName"] = account?.account_holder
	data["accountBalance"] = account?.account_balance || 0
	data["hasNeural"] = living_user?.has_neural_implant() || FALSE
	data["terminalAnchored"] = terminal?.anchored || FALSE
	data["apartments"] = list()
	for(var/datum/cyberpunk_apartment/apartment as anything in SScyberpunk_property.get_cyberpunk_apartments_for_user(living_user))
		data["apartments"] += list(apartment.to_ui_data(living_user, FALSE))
	var/datum/cyberpunk_apartment/selected = SScyberpunk_property.get_cyberpunk_apartment(selected_apartment_id)
	if(!selected?.can_view(living_user))
		selected = null
	if(!selected && length(data["apartments"]))
		var/list/first_apartment = data["apartments"][1]
		selected = SScyberpunk_property.get_cyberpunk_apartment(first_apartment["id"])
	data["apartment"] = selected?.to_ui_data(living_user, TRUE)
	return data

/proc/cyberpunk_contract_registry_ui_data(mob/user)
	var/list/data = list()
	var/mob/living/living_user = isliving(user) ? user : null
	data["contracts"] = list()
	data["activeCount"] = 0
	data["completedCount"] = 0
	data["failedCount"] = 0
	data["taxRate"] = 5
	for(var/contract_id in SSeconomy.cyberpunk_contracts)
		var/datum/cyberpunk_contract/contract = SSeconomy.cyberpunk_contracts[contract_id]
		if(!contract || !contract.legal)
			continue
		if(contract.status in list("created", "accepted"))
			data["activeCount"]++
		else if(contract.status == "completed")
			data["completedCount"]++
		else if(contract.status == "failed")
			data["failedCount"]++
		data["contracts"] += list(contract.to_ui_data(living_user, TRUE))
	return data

/proc/cyberpunk_contracts_ui_act(action, list/params, mob/user)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract
	if(params && params["id"])
		contract = SSeconomy.get_cyberpunk_contract(params["id"])

	switch(action)
		if("create")
			var/datum/cyberpunk_contract/new_contract = SSeconomy.create_cyberpunk_contract(living_user, params)
			if(!new_contract)
				to_chat(living_user, span_warning("Contract creation failed. Check your ID account and reserved payment."))
				return TRUE
			to_chat(living_user, span_notice("Contract #[new_contract.id] created."))
			return TRUE
		if("accept")
			if(contract?.accept(living_user))
				to_chat(living_user, span_notice("Contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this contract."))
			return TRUE
		if("refuse_offer")
			if(contract?.refuse_offer(living_user))
				to_chat(living_user, span_notice("Contract offer refused."))
			else
				to_chat(living_user, span_warning("Unable to refuse this contract offer."))
			return TRUE
		if("cancel")
			if(contract?.cancel(living_user))
				to_chat(living_user, span_notice("Contract cancelled."))
			else
				to_chat(living_user, span_warning("Unable to cancel this contract."))
			return TRUE
		if("abandon")
			if(contract?.can_act_as_contractor(living_user) && contract.fail("contractor abandoned contract"))
				to_chat(living_user, span_notice("Contract abandoned."))
			else
				to_chat(living_user, span_warning("Unable to abandon this contract."))
			return TRUE
		if("creator_complete")
			if(contract?.can_manage(living_user) && contract.complete("creator confirmed completion"))
				to_chat(living_user, span_notice("Contract completed."))
			else
				to_chat(living_user, span_warning("Unable to complete this contract."))
			return TRUE
		if("submit_held")
			if(contract?.submit_held_item(living_user))
				to_chat(living_user, span_notice("Submission recorded."))
			else
				to_chat(living_user, span_warning("Held item does not satisfy this contract."))
			return TRUE
		if("mark_held")
			if(contract?.mark_held_item(living_user))
				to_chat(living_user, span_notice("Held item marked as contract cargo."))
			else
				to_chat(living_user, span_warning("Unable to mark held item for this contract."))
			return TRUE
		if("check_target")
			if(contract?.check_nearby_target(living_user))
				to_chat(living_user, span_notice("Contract target check recorded."))
			else
				to_chat(living_user, span_warning("No nearby target satisfies this contract."))
			return TRUE
	return FALSE

/proc/cyberpunk_contract_pool_ui_act(action, list/params, mob/user)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract = params && params["id"] ? SSeconomy.get_cyberpunk_contract(params["id"]) : null
	switch(action)
		if("accept")
			if(contract?.pool_contract && contract.accept(living_user))
				to_chat(living_user, span_notice("Pool contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this pool contract."))
			return TRUE
	return FALSE

/proc/cyberpunk_contract_offer_ui_act(action, list/params, mob/user, contract_id)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/datum/cyberpunk_contract/contract = SSeconomy.get_cyberpunk_contract(contract_id)
	switch(action)
		if("accept")
			if(contract?.accept(living_user))
				to_chat(living_user, span_notice("Contract accepted."))
			else
				to_chat(living_user, span_warning("Unable to accept this contract offer."))
			return TRUE
		if("refuse_offer")
			if(contract?.refuse_offer(living_user))
				to_chat(living_user, span_notice("Contract offer refused."))
			else
				to_chat(living_user, span_warning("Unable to refuse this contract offer."))
			return TRUE
	return FALSE

/proc/cyberpunk_apartment_terminal_ui_act(action, list/params, mob/user, obj/machinery/computer/apartment_terminal/terminal = null, selected_apartment_id = null)
	var/mob/living/living_user = isliving(user) ? user : null
	if(!living_user)
		return FALSE
	var/requested_apartment_id = params && params["id"] ? params["id"] : selected_apartment_id
	var/datum/cyberpunk_apartment/apartment = SScyberpunk_property.get_cyberpunk_apartment(requested_apartment_id)
	switch(action)
		if("create")
			var/datum/cyberpunk_apartment/new_apartment = SScyberpunk_property.create_cyberpunk_apartment(living_user, terminal, params)
			if(!new_apartment)
				to_chat(living_user, span_warning("Apartment binding failed. A functional neural interface and a terminal inside dormitory apartment area are required."))
			else
				to_chat(living_user, span_notice("Apartment #[new_apartment.id] linked to your neural interface."))
			return TRUE
		if("save")
			if(apartment?.save_apartment(living_user))
				to_chat(living_user, span_notice("Apartment snapshot saved."))
			else
				to_chat(living_user, span_warning("Unable to save apartment. Only the neural owner can save."))
			return TRUE
		if("load")
			if(apartment?.load_apartment(living_user))
				to_chat(living_user, span_notice("Apartment snapshot loaded."))
			else
				to_chat(living_user, span_warning("Unable to load apartment. Only one owner load is allowed per round."))
			return TRUE
	return FALSE
//CYBERPUNK BUILD - rebuild and delete before release
