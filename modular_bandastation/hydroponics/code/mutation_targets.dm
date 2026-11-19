#define MUTATION_TARGET_FRUIT "плод"
#define MUTATION_TARGET_LEAF "лист"
#define MUTATION_TARGET_STEM "стебель"

#define NEGATIVE_PLANT_INSTABILITY_THRESHOLD 80
#define NEGATIVE_PLANT_TOXIN_PER_BITE 1.5

/datum/plant_gene/trait
	var/mutation_target = MUTATION_TARGET_FRUIT

/datum/plant_gene/trait/plant_type
	mutation_target = MUTATION_TARGET_STEM

/datum/plant_gene/trait/tox_resistance
	mutation_target = MUTATION_TARGET_LEAF

#define CP_PLANT_GENE_BUDGET 10

/obj/item/seeds
	var/cyberpunk_mutation_potential = 100
	var/cyberpunk_gene_points_spent = 0

/obj/item/seeds/proc/cyberpunk_capture_genetics()
	var/list/gene_records = list()
	for(var/datum/plant_gene/gene in genes)
		var/list/record = list("type" = "[gene.type]", "flags" = gene.mutability_flags)
		var/datum/plant_gene/reagent/reagent_gene = gene
		var/datum/plant_gene/trait/trait_gene = gene
		if(istype(reagent_gene))
			record["reagent"] = "[reagent_gene.reagent_id]"
			record["rate"] = reagent_gene.rate
		else if(istype(trait_gene))
			record["rate"] = trait_gene.rate
		gene_records += list(record)
	return list(
		"potential" = cyberpunk_mutation_potential,
		"spent" = cyberpunk_gene_points_spent,
		"instability" = instability,
		"genes" = gene_records,
	)

/obj/item/seeds/proc/cyberpunk_restore_genetics(list/state)
	if(!islist(state["genes"]))
		return
	for(var/datum/plant_gene/old_gene in genes)
		old_gene.on_removed(src)
	QDEL_LIST(genes)
	for(var/list/record as anything in state["genes"])
		var/gene_type = text2path("[record["type"]]")
		if(!ispath(gene_type, /datum/plant_gene))
			continue
		var/datum/plant_gene/gene
		if(ispath(gene_type, /datum/plant_gene/reagent))
			var/reagent_path = text2path("[record["reagent"]]")
			if(!ispath(reagent_path, /datum/reagent))
				continue
			gene = new gene_type(reagent_path, record["rate"])
		else
			gene = new gene_type
			var/datum/plant_gene/trait/trait = gene
			if(istype(trait) && isnum(record["rate"]))
				trait.rate = record["rate"]
		gene.mutability_flags = record["flags"]
		genes += gene
		gene.on_new_seed(src)
	reagents_from_genes()
	cyberpunk_mutation_potential = clamp(round(state["potential"]), 0, 100)
	cyberpunk_gene_points_spent = clamp(round(state["spent"]), 0, CP_PLANT_GENE_BUDGET)
	set_instability(state["instability"])

/obj/item/plant_analyzer
	var/list/datum/plant_gene/trait/cyberpunk_gene_sample = list()

/obj/item/plant_analyzer/proc/cyberpunk_capture_gene_sample(obj/item/seeds/seed, mob/user)
	QDEL_LIST(cyberpunk_gene_sample)
	for(var/datum/plant_gene/trait/gene in seed.genes)
		if(gene.mutability_flags & PLANT_GENE_MUTATABLE)
			cyberpunk_gene_sample += gene.Copy()
	if(length(cyberpunk_gene_sample))
		to_chat(user, span_notice("Данные генов растения сохранены. Их можно передать в генный смешиватель."))

/obj/machinery/cyberpunk_plant_gene_mixer
	name = "генный смешиватель"
	desc = "Принимает семена и данные с анализатора растений. Нажми рукой, чтобы выбрать ген или извлечь семена."
	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "dnamod"
	base_icon_state = "dnamod"
	circuit = null
	density = TRUE
	anchored = TRUE
	var/obj/item/seeds/loaded_seed
	var/list/datum/plant_gene/trait/donor_genes = list()
	var/mixing = FALSE

/obj/machinery/cyberpunk_plant_gene_mixer/Destroy()
	QDEL_LIST(donor_genes)
	QDEL_NULL(loaded_seed)
	return ..()

/obj/machinery/cyberpunk_plant_gene_mixer/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_operational || mixing)
		return ITEM_INTERACT_BLOCKING
	var/obj/item/plant_analyzer/analyzer = tool
	if(istype(analyzer))
		if(!length(analyzer.cyberpunk_gene_sample))
			to_chat(user, span_warning("В анализаторе нет данных генов. Сначала просканируй образец."))
			return ITEM_INTERACT_BLOCKING
		QDEL_LIST(donor_genes)
		for(var/datum/plant_gene/trait/gene as anything in analyzer.cyberpunk_gene_sample)
			donor_genes += gene.Copy()
		to_chat(user, span_notice("Данные переданы в смешиватель."))
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/seeds))
		if(loaded_seed || !user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_BLOCKING
		loaded_seed = tool
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/machinery/cyberpunk_plant_gene_mixer/attack_hand(mob/user, list/modifiers)
	ui_interact(user)
	return TRUE

/obj/machinery/cyberpunk_plant_gene_mixer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkPlantGeneMixer", name)
		ui.open()

/obj/machinery/cyberpunk_plant_gene_mixer/proc/gene_cost(datum/plant_gene/trait/gene, multiplier)
	return max(1, round((istype(gene, /datum/plant_gene/trait/plant_type) ? 5 : 3) * multiplier))

/obj/machinery/cyberpunk_plant_gene_mixer/ui_data(mob/user)
	var/edict_multiplier = cyberpunk_property_edict_multiplier(src, CYBERPUNK_CORP_BENN, "benn_gene_combo", 0.75)
	var/remaining = CP_PLANT_GENE_BUDGET - (loaded_seed?.cyberpunk_gene_points_spent || 0)
	var/list/options = list()
	for(var/datum/plant_gene/trait/gene as anything in donor_genes)
		var/cost = gene_cost(gene, edict_multiplier)
		options += list(list(
			"id" = REF(gene),
			"name" = gene.get_name(),
			"description" = gene.description,
			"target" = gene.mutation_target,
			"cost" = cost,
			"compatible" = !!loaded_seed && !loaded_seed.get_gene(gene.type) && gene.can_add(loaded_seed) && cost <= remaining,
		))
	return list(
		"seed" = loaded_seed?.name,
		"potential" = loaded_seed?.cyberpunk_mutation_potential,
		"remaining" = max(0, remaining),
		"duration" = 4 * edict_multiplier,
		"edictActive" = edict_multiplier < 1,
		"powered" = is_operational,
		"mixing" = mixing,
		"genes" = options,
	)

/obj/machinery/cyberpunk_plant_gene_mixer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/operator = ui.user
	var/obj/item/seeds/seed = loaded_seed
	if(!istype(operator) || !Adjacent(operator) || QDELETED(seed) || mixing || !is_operational)
		return FALSE
	if(action == "eject")
		loaded_seed = null
		if(!operator.put_in_hands(seed))
			seed.forceMove(drop_location())
		return TRUE
	if(action != "mix" || !istext(params["gene"]))
		return FALSE
	var/datum/plant_gene/trait/donor = locate(params["gene"]) in donor_genes
	if(!istype(donor) || QDELETED(donor) || seed.get_gene(donor.type) || !donor.can_add(seed))
		return FALSE
	var/edict_multiplier = cyberpunk_property_edict_multiplier(src, CYBERPUNK_CORP_BENN, "benn_gene_combo", 0.75)
	var/cost = gene_cost(donor, edict_multiplier)
	if(seed.cyberpunk_gene_points_spent + cost > CP_PLANT_GENE_BUDGET)
		return FALSE
	mixing = TRUE
	SStgui.update_uis(src)
	var/completed = do_after(operator, (4 SECONDS) * edict_multiplier, src)
	if(QDELETED(src))
		return TRUE
	mixing = FALSE
	if(!completed || QDELETED(seed) || seed != loaded_seed || QDELETED(donor) || !is_operational)
		return TRUE
	if(!prob(seed.cyberpunk_mutation_potential))
		seed.adjust_instability(3)
		to_chat(operator, span_warning("Ген не закрепился. Нестабильность немного выросла."))
		return TRUE
	var/datum/plant_gene/trait/installed = donor.Copy()
	seed.genes += installed
	installed.on_new_seed(seed)
	seed.reagents_from_genes()
	seed.cyberpunk_gene_points_spent += cost
	seed.adjust_instability(cost * 4)
	to_chat(operator, span_notice("Ген [installed.get_name()] закрепился. Потрачено [cost] очк."))
	return TRUE

#undef CP_PLANT_GENE_BUDGET
