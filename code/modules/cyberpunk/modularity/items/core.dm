// CYBERPUNK MODULARITY - moved out of code/game/objects/items.dm for architecture clarity.

/obj/item/proc/normalize_cyberpunk_item_baseline()
	cyberpunk_quality = clamp(round(cyberpunk_quality || 100), 1, 200)
	normalize_cyberpunk_inventory_footprint()
	if(!cyberpunk_base_price)
		cyberpunk_base_price = get_cyberpunk_estimated_base_price()
	normalize_cyberpunk_item_tier_and_rarity()
	if(uses_integrity && cyberpunk_spoil_behavior == "tg" && !istype(src, /obj/item/stack))
		cyberpunk_spoil_behavior = "broken"
	if(uses_integrity && cyberpunk_active_wear <= 0 && is_cyberpunk_wear_tracked_item())
		cyberpunk_active_wear = get_cyberpunk_default_active_wear()
	if(uses_integrity && cyberpunk_passive_wear <= 0 && is_cyberpunk_passive_wear_item())
		cyberpunk_passive_wear = 0.01
	if(uses_integrity && cyberpunk_passive_wear > 0 && !length(cyberpunk_storage_conditions))
		cyberpunk_storage_conditions = list("dry", "room_temp")
	if(!get_cyberpunk_manufacturer())
		set_cyberpunk_manufacturer("independent")

/obj/item/proc/normalize_cyberpunk_inventory_footprint(force_auto = FALSE)
	if(force_auto && cyberpunk_grid_auto_sized)
		cyberpunk_grid_width = null
		cyberpunk_grid_height = null
	if(cyberpunk_grid_width && cyberpunk_grid_height)
		return
	cyberpunk_grid_auto_sized = TRUE
	if(istype(src, /obj/item/cyberpunk_item_module))
		cyberpunk_grid_width = 1
		cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/ammo_casing))
		cyberpunk_grid_width = 1
		cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/ammo_box/magazine))
		if(w_class >= WEIGHT_CLASS_BULKY)
			cyberpunk_grid_width = 2
			cyberpunk_grid_height = 2
		else
			cyberpunk_grid_width = 1
			cyberpunk_grid_height = 2
	else if(istype(src, /obj/item/ammo_box))
		cyberpunk_grid_width = 2
		cyberpunk_grid_height = 2
	else if(istype(src, /obj/item/gun))
		if(w_class >= WEIGHT_CLASS_HUGE)
			cyberpunk_grid_width = 5
			cyberpunk_grid_height = 2
		else if(w_class >= WEIGHT_CLASS_BULKY)
			cyberpunk_grid_width = 4
			cyberpunk_grid_height = 2
		else if(w_class >= WEIGHT_CLASS_NORMAL)
			cyberpunk_grid_width = 3
			cyberpunk_grid_height = 1
		else
			cyberpunk_grid_width = 2
			cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/melee) || istype(src, /obj/item/knife))
		if(w_class >= WEIGHT_CLASS_BULKY)
			cyberpunk_grid_width = 4
			cyberpunk_grid_height = 1
		else if(w_class >= WEIGHT_CLASS_NORMAL)
			cyberpunk_grid_width = 3
			cyberpunk_grid_height = 1
		else
			cyberpunk_grid_width = 2
			cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/clothing/suit))
		cyberpunk_grid_width = 3
		cyberpunk_grid_height = 4
	else if(istype(src, /obj/item/clothing/under))
		cyberpunk_grid_width = 2
		cyberpunk_grid_height = 3
	else if(istype(src, /obj/item/clothing/head) || istype(src, /obj/item/clothing/mask))
		cyberpunk_grid_width = 2
		cyberpunk_grid_height = 2
	else if(istype(src, /obj/item/clothing/shoes) || istype(src, /obj/item/clothing/gloves) || istype(src, /obj/item/clothing/glasses) || istype(src, /obj/item/clothing/neck))
		cyberpunk_grid_width = 2
		cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/storage/backpack/duffelbag))
		cyberpunk_grid_width = 4
		cyberpunk_grid_height = 3
	else if(istype(src, /obj/item/storage/backpack/satchel) || istype(src, /obj/item/storage/backpack/messenger))
		cyberpunk_grid_width = 3
		cyberpunk_grid_height = 3
	else if(istype(src, /obj/item/storage/backpack))
		cyberpunk_grid_width = 3
		cyberpunk_grid_height = 4
	else if(istype(src, /obj/item/storage/belt))
		cyberpunk_grid_width = 3
		cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/storage/toolbox) || istype(src, /obj/item/storage/briefcase) || istype(src, /obj/item/storage/box))
		cyberpunk_grid_width = 3
		cyberpunk_grid_height = 2
	else if(istype(src, /obj/item/reagent_containers))
		if(w_class >= WEIGHT_CLASS_NORMAL)
			cyberpunk_grid_width = 2
			cyberpunk_grid_height = 2
		else
			cyberpunk_grid_width = 1
			cyberpunk_grid_height = 2
	else if(istype(src, /obj/item/stack))
		cyberpunk_grid_width = 1
		cyberpunk_grid_height = 1
	else if(istype(src, /obj/item/organ) || istype(src, /obj/item/implant))
		cyberpunk_grid_width = 1
		cyberpunk_grid_height = 1
	else
		cyberpunk_grid_auto_sized = FALSE

/obj/item/proc/normalize_cyberpunk_item_tier_and_rarity()
	var/explicit_tier = cyberpunk_item_tier > 0
	cyberpunk_item_tier = get_cyberpunk_item_tier()
	if(is_cyberpunk_tiered_weapon_or_armor(explicit_tier))
		var/tier_rarity = get_cyberpunk_rarity_for_tier(cyberpunk_item_tier)
		if(tier_rarity)
			cyberpunk_rarity = tier_rarity
			return
	if(cyberpunk_rarity == "common" && cyberpunk_base_price >= 600)
		cyberpunk_rarity = "epic"
	else if(cyberpunk_rarity == "common" && cyberpunk_base_price >= 300)
		cyberpunk_rarity = "rare"
	else if(cyberpunk_rarity == "common" && cyberpunk_base_price >= 120)
		cyberpunk_rarity = "uncommon"

/obj/item/proc/is_cyberpunk_tiered_weapon_or_armor(explicit_tier = FALSE)
	return explicit_tier || ("module_tier" in vars) || cyberpunk_weapon_form || cyberpunk_equipment_form || istype(src, /obj/item/gun) || (force > 0 || throwforce > 0) || (istype(src, /obj/item/clothing) && get_armor().has_any_armor())

/obj/item/proc/get_cyberpunk_rarity_for_tier(tier)
	switch(tier)
		if(1)
			return "common"
		if(2)
			return "rare"
		if(3)
			return "legendary"
	return null

/obj/item/proc/get_cyberpunk_item_tier()
	if(cyberpunk_item_tier > 0)
		return clamp(round(cyberpunk_item_tier), 1, 3)
	var/derived_tier = 1
	if(("module_tier" in vars) && isnum(vars["module_tier"]))
		derived_tier = max(derived_tier, vars["module_tier"])
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(module)
			derived_tier = max(derived_tier, module.module_tier)
	if(length(cyberpunk_initial_module_types))
		for(var/module_type in cyberpunk_initial_module_types)
			if(!ispath(module_type, /datum/cyberpunk_item_module))
				continue
			var/datum/cyberpunk_item_module/module = module_type
			derived_tier = max(derived_tier, initial(module.module_tier))
	if(cyberpunk_weapon_form)
		derived_tier = max(derived_tier, get_cyberpunk_weapon_frame_tier())
	else if(istype(src, /obj/item/gun) || force > 0 || throwforce > 0)
		derived_tier = max(derived_tier, get_cyberpunk_weapon_stat_tier())
	if(cyberpunk_equipment_form)
		derived_tier = max(derived_tier, get_cyberpunk_equipment_frame_tier())
	else if(istype(src, /obj/item/clothing) && get_armor().has_any_armor())
		derived_tier = max(derived_tier, get_cyberpunk_armor_stat_tier())
	return clamp(round(derived_tier), 1, 3)

/datum/cyberpunk_sale_entry
	/// Item type sold by this entry.
	var/item_type
	/// Logical sale source: vendor, shop, vendor_hidden or black_market.
	var/source_id = "vendor"
	/// Whether this entry is sold from a premium/hidden slot.
	var/premium = FALSE
	/// Derived item tier used for price, availability and stock caps.
	var/tier = 1
	/// Derived rarity used for diagnostics/UI.
	var/rarity = "common"
	/// Baseline price before local vendor/economy overrides.
	var/base_price = 1

/datum/cyberpunk_sale_entry/proc/setup(item_type, source_id = "vendor", premium = FALSE)
	src.item_type = item_type
	src.source_id = source_id || "vendor"
	src.premium = premium
	tier = get_cyberpunk_item_tier_for_type(item_type)
	rarity = get_cyberpunk_effective_rarity_for_type(item_type)
	base_price = get_cyberpunk_estimated_base_price_for_type(item_type)
	return src

/datum/cyberpunk_sale_entry/proc/get_source_price_multiplier()
	switch(source_id)
		if("black_market")
			return 1.7
		if("vendor_hidden")
			return 1.45
		if("shop")
			return 1.15
	return 1

/datum/cyberpunk_sale_entry/proc/get_tier_price_multiplier()
	switch(tier)
		if(2)
			return 1.8
		if(3)
			return 4
	return 1

/datum/cyberpunk_sale_entry/proc/get_price(default_price = 25, extra_price = 50, inflation_value = 1, premium = FALSE)
	if(!ispath(item_type, /obj/item))
		return max(1, round(default_price))
	var/obj/item/item = item_type
	var/custom_price = round((initial(item.custom_price) || 0) * inflation_value)
	var/premium_custom_price = round((initial(item.custom_premium_price) || 0) * inflation_value)
	var/price
	if(premium)
		if(!premium_custom_price && custom_price)
			price = extra_price + custom_price
		else
			price = premium_custom_price || extra_price
	else
		price = custom_price || default_price
	price = max(price, round(base_price * inflation_value))
	price = round(price * get_tier_price_multiplier() * get_source_price_multiplier())
	return max(1, price)

/datum/cyberpunk_sale_entry/proc/get_availability_chance()
	switch(source_id)
		if("black_market")
			switch(tier)
				if(3)
					return 8
				if(2)
					return 32
			return 72
		if("vendor_hidden")
			switch(tier)
				if(3)
					return 3
				if(2)
					return 12
			return 35
		if("shop")
			switch(tier)
				if(3)
					return 4
				if(2)
					return 16
			return 42
	switch(tier)
		if(3)
			return 2
		if(2)
			return 10
	return 30

/datum/cyberpunk_sale_entry/proc/roll_available()
	return prob(get_availability_chance())

/datum/cyberpunk_sale_entry/proc/get_rotated_stock_amount(base_amount)
	if(base_amount <= 0 || !roll_available())
		return 0
	var/stock_cap = max(1, base_amount)
	switch(tier)
		if(3)
			stock_cap = min(stock_cap, 1)
		if(2)
			stock_cap = min(stock_cap, 2)
	return rand(1, stock_cap)

/datum/cyberpunk_sale_entry/proc/get_market_stock_max(base_stock_max)
	var/stock_cap = max(1, base_stock_max)
	switch(tier)
		if(3)
			return 1
		if(2)
			return min(stock_cap, 2)
	return stock_cap

/proc/get_cyberpunk_sale_entry_for_type(item_type, source_id = "vendor", premium = FALSE)
	if(!ispath(item_type, /obj/item))
		return null
	var/obj/item/item = item_type
	var/sale_entry_type = initial(item.cyberpunk_sale_entry_type) || /datum/cyberpunk_sale_entry
	if(!ispath(sale_entry_type, /datum/cyberpunk_sale_entry))
		sale_entry_type = /datum/cyberpunk_sale_entry
	var/datum/cyberpunk_sale_entry/entry = new sale_entry_type
	return entry.setup(item_type, source_id, premium)

/proc/get_cyberpunk_sale_availability_for_type(item_type, source_id = "vendor", premium = FALSE)
	var/datum/cyberpunk_sale_entry/entry = get_cyberpunk_sale_entry_for_type(item_type, source_id, premium)
	if(!entry)
		return 100
	. = entry.get_availability_chance()
	qdel(entry)

/proc/get_cyberpunk_sale_price_for_type(item_type, source_id = "vendor", premium = FALSE, default_price = 25, extra_price = 50, inflation_value = 1)
	var/datum/cyberpunk_sale_entry/entry = get_cyberpunk_sale_entry_for_type(item_type, source_id, premium)
	if(!entry)
		return max(1, round(default_price))
	. = entry.get_price(default_price, extra_price, inflation_value, premium)
	qdel(entry)

/obj/item/proc/get_cyberpunk_weapon_frame_tier()
	var/tier = 1
	switch(cyberpunk_weapon_material)
		if("ceramic", "plasteel")
			tier = max(tier, 2)
		if("composite")
			tier = max(tier, 3)
	switch(get_cyberpunk_effective_weapon_form())
		if("sniper", "lmg", "rocket", "plasma")
			tier = max(tier, 3)
		if("rifle", "shotgun", "assault", "laser", "energy")
			tier = max(tier, 2)
	return max(tier, get_cyberpunk_weapon_stat_tier())

/obj/item/proc/get_cyberpunk_weapon_stat_tier()
	var/tier = 1
	var/weapon_score = max(force, throwforce) + armour_penetration * 0.5 + block_chance * 0.25
	var/obj/item/gun/gun = src
	if(istype(gun))
		weapon_score += 18
		weapon_score += max(0, gun.projectile_damage_multiplier - 1) * 80
		weapon_score += gun.projectile_wound_bonus
		weapon_score += max(0, 10 - gun.fire_delay)
		weapon_score += max(0, 8 - gun.spread) * 0.5
	if(weapon_score >= 45)
		tier = 3
	else if(weapon_score >= 25)
		tier = 2
	return tier

/obj/item/proc/get_cyberpunk_equipment_frame_tier()
	var/tier = 1
	switch(cyberpunk_equipment_material)
		if("ceramic", "plasteel")
			tier = max(tier, 2)
		if("composite")
			tier = max(tier, 3)
	switch(cyberpunk_equipment_form)
		if("suit")
			tier = max(tier, 2)
		if("rig", "exosuit")
			tier = max(tier, 3)
	return max(tier, get_cyberpunk_armor_stat_tier())

/obj/item/proc/get_cyberpunk_armor_stat_tier()
	var/tier = 1
	var/armor_score = 0
	var/list/armor_values = get_armor().get_rating_list()
	for(var/armor_key in armor_values)
		armor_score += max(0, armor_values[armor_key])
	if(armor_score >= 180)
		tier = 3
	else if(armor_score >= 80)
		tier = 2
	return tier

/obj/item/proc/get_cyberpunk_estimated_base_price()
	var/base_price = custom_price || 0
	if(base_price > 0)
		return round(base_price)

	base_price = max(1, w_class) * 25
	var/material_market_value = get_cyberpunk_material_market_value()
	if(material_market_value > 0)
		base_price = max(base_price, round(material_market_value * 0.05))
	if(uses_integrity)
		base_price += round(max_integrity * 0.35)
	if(force > 0)
		base_price += round(force * 8)
	if(throwforce > force)
		base_price += round((throwforce - force) * 4)
	if(block_chance > 0)
		base_price += round(block_chance * 2)
	if(armour_penetration > 0)
		base_price += round(armour_penetration * 4)
	if(tool_behaviour)
		base_price += 60
	if(istype(src, /obj/item/gun))
		base_price += 250
	if(istype(src, /obj/item/clothing) && get_armor().has_any_armor())
		base_price += 100
	if(length(cyberpunk_module_slots) || cyberpunk_equipment_form || cyberpunk_weapon_form)
		base_price += 150
	return max(1, round(base_price))

/obj/item/proc/is_cyberpunk_engineering_tool()
	return tool_behaviour in list(TOOL_CROWBAR, TOOL_MULTITOOL, TOOL_SCREWDRIVER, TOOL_WIRECUTTER, TOOL_WRENCH, TOOL_WELDER, TOOL_ANALYZER, TOOL_RUSTSCRAPER)

/obj/item/proc/is_cyberpunk_medical_tool()
	return tool_behaviour in list(TOOL_RETRACTOR, TOOL_HEMOSTAT, TOOL_CAUTERY, TOOL_DRILL, TOOL_SCALPEL, TOOL_SAW, TOOL_BONESET, TOOL_BLOODFILTER)

/obj/item/proc/get_cyberpunk_item_work_skill()
	if(is_cyberpunk_medical_tool())
		return SKILL_SURGERY
	if(tool_behaviour in list(TOOL_WELDER, TOOL_MULTITOOL, TOOL_SCREWDRIVER, TOOL_WIRECUTTER, TOOL_ANALYZER))
		return SKILL_ELECTRICS
	if(tool_behaviour in list(TOOL_CROWBAR, TOOL_WRENCH, TOOL_RUSTSCRAPER))
		return SKILL_CONSTRUCTION
	if(tool_behaviour in list(TOOL_MINING, TOOL_SHOVEL))
		return SKILL_MINING
	if(tool_behaviour in list(TOOL_KNIFE, TOOL_ROLLINGPIN))
		return SKILL_COOKING
	if(cyberpunk_equipment_form || cyberpunk_weapon_form || length(cyberpunk_module_slots))
		return SKILL_INVENTION
	if(istype(src, /obj/item/gun) || force > 0 || throwforce > 0)
		return get_cyberpunk_weapon_skill()
	return null

/proc/get_cyberpunk_skill_display_name(skill_path)
	switch(skill_path)
		if(SKILL_SURGERY)
			return "Surgery"
		if(SKILL_CHEMISTRY)
			return "Chemistry"
		if(SKILL_ELECTRICS)
			return "Electrics"
		if(SKILL_CONSTRUCTION)
			return "Construction"
		if(SKILL_INVENTION)
			return "Invention"
		if(SKILL_ANALYSIS)
			return "Analysis"
		if(SKILL_MINING)
			return "Mining"
		if(SKILL_COOKING)
			return "Cooking"
		if(SKILL_LIGHT_RANGED)
			return "Light ranged"
		if(SKILL_MEDIUM_RANGED)
			return "Medium ranged"
		if(SKILL_HEAVY_RANGED)
			return "Heavy ranged"
		if(SKILL_LIGHT_PIERCING)
			return "Light piercing"
		if(SKILL_HEAVY_PIERCING)
			return "Heavy piercing"
		if(SKILL_LIGHT_SLASHING)
			return "Light slashing"
		if(SKILL_HEAVY_SLASHING)
			return "Heavy slashing"
		if(SKILL_LIGHT_BLUNT)
			return "Light blunt"
		if(SKILL_HEAVY_BLUNT)
			return "Heavy blunt"
		if(SKILL_CHOPPING)
			return "Chopping"
	return "[skill_path]"

/obj/item/proc/is_cyberpunk_wear_tracked_item()
	if(istype(src, /obj/item/stack))
		return FALSE
	return force > 0 || throwforce > 0 || block_chance > 0 || armour_penetration > 0 || tool_behaviour || istype(src, /obj/item/gun) || istype(src, /obj/item/clothing)

/obj/item/proc/is_cyberpunk_passive_wear_item()
	return istype(src, /obj/item/gun) || istype(src, /obj/item/clothing) || tool_behaviour || cyberpunk_equipment_form || cyberpunk_weapon_form

/obj/item/proc/get_cyberpunk_default_active_wear()
	var/wear = 0.25
	if(tool_behaviour)
		wear = max(wear, 0.5)
	if(force > 0 || throwforce > 0)
		wear = max(wear, 0.25 + max(force, throwforce) * 0.03)
	if(istype(src, /obj/item/gun))
		wear = max(wear, 0.75)
	if(istype(src, /obj/item/clothing) && get_armor().has_any_armor())
		wear = max(wear, 0.5)
	if(w_class >= WEIGHT_CLASS_BULKY)
		wear += 0.25
	return round(wear, 0.1)

/obj/item/proc/add_cyberpunk_condition_tag(condition_tag)
	if(!condition_tag)
		return FALSE
	LAZYADD(cyberpunk_condition_tags, condition_tag)
	return TRUE

/obj/item/proc/remove_cyberpunk_condition_tag(condition_tag)
	if(!condition_tag || !length(cyberpunk_condition_tags))
		return FALSE
	cyberpunk_condition_tags -= condition_tag
	if(!length(cyberpunk_condition_tags))
		cyberpunk_condition_tags = null
	return TRUE

/obj/item/proc/has_cyberpunk_condition_tag(condition_tag)
	return condition_tag && (condition_tag in cyberpunk_condition_tags)

/obj/item/proc/get_cyberpunk_condition_tags()
	var/list/tags = list()
	if(length(cyberpunk_condition_tags))
		tags += cyberpunk_condition_tags
	if(cyberpunk_broken)
		tags += "broken"
	else if(uses_integrity && max_integrity > 0 && get_integrity_percentage() < 0.75)
		tags += "damaged"
	else
		tags += "intact"
	if(("charges" in vars) && isnum(vars["charges"]))
		tags += (vars["charges"] > 0) ? "charged" : "discharged"
	if(("locked" in vars) && vars["locked"])
		tags += "locked"
	return tags

/obj/item/proc/get_cyberpunk_material_report()
	var/list/report = list()
	if(!length(custom_materials))
		report += "standard"
		return report
	for(var/material_key in custom_materials)
		var/datum/material/material = SSmaterials.get_material(material_key)
		if(!material)
			continue
		report += "[material.name] [round(custom_materials[material_key])]"
	return report

/obj/item/proc/get_cyberpunk_material_market_value()
	var/material_value = 0
	if(!length(custom_materials))
		return material_value
	for(var/material_key in custom_materials)
		var/datum/material/material = SSmaterials.get_material(material_key)
		if(!material)
			continue
		material_value += custom_materials[material_key] * material.value_per_unit
	return material_value

/obj/item/proc/get_cyberpunk_material_value_multiplier()
	if(!length(custom_materials))
		return 1
	var/total_amount = 0
	var/weighted_integrity = 0
	var/weighted_hardness = 0
	var/weighted_chemical = 0
	var/weighted_thermal = 0
	for(var/material_key in custom_materials)
		var/datum/material/material = SSmaterials.get_material(material_key)
		if(!material)
			continue
		var/material_amount = custom_materials[material_key]
		total_amount += material_amount
		weighted_integrity += material.get_property(MATERIAL_INTEGRITY) * material_amount
		weighted_hardness += material.get_property(MATERIAL_HARDNESS) * material_amount
		weighted_chemical += material.get_property(MATERIAL_CHEMICAL) * material_amount
		weighted_thermal += material.get_property(MATERIAL_THERMAL) * material_amount
	if(total_amount <= 0)
		return 1
	var/material_score = ((weighted_integrity / total_amount) + (weighted_hardness / total_amount) + (weighted_chemical / total_amount) + (weighted_thermal / total_amount)) / 4
	return clamp(0.75 + material_score * 0.05, 0.75, 1.5)

/obj/item/proc/get_cyberpunk_rarity_price_multiplier()
	switch(cyberpunk_rarity)
		if("trash")
			return 0.35
		if("common")
			return 1
		if("uncommon")
			return 1.25
		if("rare")
			return 1.75
		if("epic")
			return 2.5
		if("legendary")
			return 4
	return 1

/obj/item/proc/get_cyberpunk_legality_price_multiplier()
	switch(cyberpunk_legality)
		if("restricted")
			return 1.25
		if("illegal")
			return 1.6
		if("contraband")
			return 2
	return 1

/obj/item/proc/can_cyberpunk_spawn_in_source(source_id)
	return cyberpunk_rarity_allows_source(cyberpunk_rarity, source_id)

/proc/cyberpunk_rarity_allows_source(rarity, source_id)
	switch(source_id)
		if("shop", "vendor", "warehouse", "craft")
			return rarity in list("trash", "common", "uncommon")
		if("contract", "wasteland", "dungeon")
			return rarity in list("common", "uncommon", "rare", "epic")
		if("corporation", "research")
			return rarity in list("uncommon", "rare", "epic", "legendary")
		if("black_market")
			return rarity in list("rare", "epic", "legendary", "illegal", "contraband")
	return TRUE

/obj/item/proc/get_cyberpunk_item_condition_percent()
	update_cyberpunk_passive_wear()
	if(cyberpunk_broken)
		return 0
	if(!uses_integrity || max_integrity <= 0)
		return 100
	return clamp(round((get_integrity() / max_integrity) * 100), 0, 100)

/obj/item/proc/get_cyberpunk_spoil_threshold_percent()
	if(!uses_integrity)
		return 0
	return clamp(round(cyberpunk_repair_threshold * 100), 0, 100)

/obj/item/proc/get_cyberpunk_rarity_weight()
	switch(cyberpunk_rarity)
		if("trash")
			return 200
		if("common")
			return 100
		if("uncommon")
			return 45
		if("rare")
			return 18
		if("epic")
			return 6
		if("legendary")
			return 1
	return 100

/obj/item/proc/get_cyberpunk_storage_condition_tags()
	var/list/conditions = list("dry", "room_temp")
	if(item_flags & IN_STORAGE)
		conditions += "stored"
	if(ismob(loc))
		conditions += "carried"
	if(istype(loc, /obj/item/storage))
		conditions += "stored"
	return conditions

/obj/item/proc/get_cyberpunk_missing_storage_conditions()
	var/list/missing = list()
	if(!length(cyberpunk_storage_conditions))
		return missing
	var/list/current_conditions = get_cyberpunk_storage_condition_tags()
	for(var/required_condition in cyberpunk_storage_conditions)
		if(!(required_condition in current_conditions))
			missing += required_condition
	return missing

/obj/item/proc/get_cyberpunk_passive_wear_multiplier()
	var/list/missing = get_cyberpunk_missing_storage_conditions()
	if(!length(missing))
		return 1
	return 1 + length(missing) * 0.5

/obj/item/proc/update_cyberpunk_passive_wear()
	if(cyberpunk_passive_wear <= 0 || !uses_integrity || (resistance_flags & INDESTRUCTIBLE) || cyberpunk_broken)
		return FALSE
	if(!cyberpunk_last_condition_update)
		cyberpunk_last_condition_update = world.time
		return FALSE
	if(world.time - cyberpunk_last_repaired < 5 MINUTES)
		return FALSE
	var/elapsed = world.time - cyberpunk_last_condition_update
	if(elapsed < 1 MINUTES)
		return FALSE
	var/wear_amount = (elapsed / (1 MINUTES)) * cyberpunk_passive_wear * get_cyberpunk_passive_wear_multiplier()
	if(wear_amount < 0.1)
		return FALSE
	cyberpunk_last_condition_update = world.time
	take_damage(round(wear_amount, 0.1), BRUTE, CONSUME, FALSE)
	if(uses_integrity && get_integrity() <= max(1, max_integrity * cyberpunk_repair_threshold))
		cyberpunk_broken = TRUE
	return TRUE

/proc/get_cyberpunk_item_rarity_weight_for_type(item_type)
	if(!ispath(item_type, /obj/item))
		return 100
	switch(get_cyberpunk_effective_rarity_for_type(item_type))
		if("trash")
			return 200
		if("common")
			return 100
		if("uncommon")
			return 45
		if("rare")
			return 18
		if("epic")
			return 6
		if("legendary")
			return 1
	return 100

/proc/get_cyberpunk_effective_rarity_for_type(item_type)
	if(!ispath(item_type, /obj/item))
		return "common"
	var/obj/item/item = item_type
	var/rarity = initial(item.cyberpunk_rarity) || "common"
	if(rarity != "common")
		return rarity
	var/static_tier = get_cyberpunk_item_tier_for_type(item_type)
	var/item_name = lowertext(initial(item.name) || "")
	if(static_tier > 1 || ispath(item_type, /obj/item/gun) || ispath(item_type, /obj/item/clothing) || initial(item.force) > 0 || initial(item.throwforce) > 0 || findtext(item_name, "t2") || findtext(item_name, "t3"))
		var/tier_rarity = get_cyberpunk_rarity_for_tier_static(static_tier)
		return tier_rarity
	var/base_price = get_cyberpunk_estimated_base_price_for_type(item_type)
	if(base_price >= 600)
		return "epic"
	if(base_price >= 300)
		return "rare"
	if(base_price >= 120)
		return "uncommon"
	return rarity

/proc/get_cyberpunk_rarity_for_tier_static(tier)
	switch(tier)
		if(1)
			return "common"
		if(2)
			return "rare"
		if(3)
			return "legendary"
	return null

/proc/get_cyberpunk_item_tier_for_type(item_type)
	if(!ispath(item_type, /obj/item))
		return 1
	var/obj/item/item = item_type
	var/explicit_tier = initial(item.cyberpunk_item_tier)
	if(explicit_tier > 0)
		return clamp(round(explicit_tier), 1, 3)
	var/item_name = lowertext(initial(item.name) || "")
	if(findtext(item_name, "t3"))
		return 3
	if(findtext(item_name, "t2"))
		return 2
	var/tier = 1
	var/weapon_score = max(initial(item.force), initial(item.throwforce)) + initial(item.armour_penetration) * 0.5 + initial(item.block_chance) * 0.25
	if(ispath(item_type, /obj/item/gun))
		weapon_score += 18
	if(weapon_score >= 45)
		tier = 3
	else if(weapon_score >= 25)
		tier = 2
	if(ispath(item_type, /obj/item/clothing))
		var/base_price = get_cyberpunk_estimated_base_price_for_type(item_type)
		if(base_price >= 600)
			tier = max(tier, 3)
		else if(base_price >= 300)
			tier = max(tier, 2)
	return tier

/proc/get_cyberpunk_estimated_base_price_for_type(item_type)
	if(!ispath(item_type, /obj/item))
		return 1
	var/obj/item/item = item_type
	var/base_price = initial(item.cyberpunk_base_price) || initial(item.custom_price) || 0
	if(base_price > 0)
		return round(base_price)
	base_price = max(1, initial(item.w_class)) * 25
	if(initial(item.uses_integrity))
		base_price += round(initial(item.max_integrity) * 0.35)
	if(initial(item.force) > 0)
		base_price += round(initial(item.force) * 8)
	if(initial(item.throwforce) > initial(item.force))
		base_price += round((initial(item.throwforce) - initial(item.force)) * 4)
	if(initial(item.block_chance) > 0)
		base_price += round(initial(item.block_chance) * 2)
	if(initial(item.armour_penetration) > 0)
		base_price += round(initial(item.armour_penetration) * 4)
	if(initial(item.tool_behaviour))
		base_price += 60
	if(ispath(item_type, /obj/item/gun))
		base_price += 250
	if(ispath(item_type, /obj/item/clothing))
		base_price += 100
	if(length(initial(item.cyberpunk_module_slots)) || initial(item.cyberpunk_equipment_form) || initial(item.cyberpunk_weapon_form))
		base_price += 150
	return max(1, round(base_price))

/proc/build_cyberpunk_loot_weight_table(list/item_types)
	var/list/weighted_items = list()
	for(var/item_type in item_types)
		var/explicit_weight = item_types[item_type]
		weighted_items[item_type] = explicit_weight || get_cyberpunk_item_rarity_weight_for_type(item_type)
	return weighted_items

/obj/item/proc/get_cyberpunk_price(mob/living/buyer)
	update_cyberpunk_passive_wear()
	var/base_price = cyberpunk_base_price || custom_price || 0
	if(base_price <= 0)
		base_price = get_cyberpunk_estimated_base_price()
	var/quality_multiplier = max(0.1, cyberpunk_quality * 0.01)
	var/condition_multiplier = 1
	if(cyberpunk_broken)
		condition_multiplier = 0.15
	else if(uses_integrity && max_integrity)
		condition_multiplier = clamp(get_integrity() / max_integrity, 0.15, 1)
	var/material_multiplier = get_cyberpunk_material_value_multiplier()
	var/rarity_multiplier = get_cyberpunk_rarity_price_multiplier()
	var/legality_multiplier = get_cyberpunk_legality_price_multiplier()
	var/synergy_multiplier = get_cyberpunk_synergy_multiplier(buyer)
	return round(base_price * quality_multiplier * condition_multiplier * material_multiplier * rarity_multiplier * legality_multiplier * synergy_multiplier)

/obj/item/proc/get_cyberpunk_guard_value()
	if(!isnull(cyberpunk_guard_value))
		return cyberpunk_guard_value
	return max(0, block_chance + (w_class * 2))

/obj/item/proc/get_cyberpunk_weapon_profile_name()
	if(istype(src, /obj/item/gun))
		return "ranged"
	var/item_sharpness = get_sharpness()
	if((item_sharpness & SHARP_POINTY) && (item_sharpness & SHARP_EDGED))
		return "mixed blade"
	if(item_sharpness & SHARP_POINTY)
		return "pierce"
	if(item_sharpness & SHARP_EDGED)
		return "slash"
	return "blunt"

/obj/item/proc/get_cyberpunk_damage_entries()
	if(length(cyberpunk_damage_profile))
		return cyberpunk_damage_profile
	var/item_sharpness = get_sharpness()
	if(item_sharpness & SHARP_POINTY)
		return list(BODYPART_DAMAGE_PIERCE = 1)
	if(item_sharpness & SHARP_EDGED)
		return list(BODYPART_DAMAGE_SLASH = 1)
	if(damtype == BURN)
		return list(BODYPART_DAMAGE_HEAT = 1)
	return list(BODYPART_DAMAGE_BLUNT = 1)

/obj/item/proc/get_primary_cyberpunk_damage_key()
	var/list/damage_entries = get_cyberpunk_damage_entries()
	var/primary_key = BODYPART_DAMAGE_BLUNT
	var/primary_weight = -INFINITY
	for(var/damage_key in damage_entries)
		var/damage_weight = damage_entries[damage_key]
		if(damage_weight > primary_weight)
			primary_key = damage_key
			primary_weight = damage_weight
	return primary_key

/obj/item/proc/get_cyberpunk_damage_type(type_key)
	switch(type_key)
		if("pierce", BODYPART_DAMAGE_PIERCE)
			return BRUTE
		if("slash", BODYPART_DAMAGE_SLASH)
			return BRUTE
		if("heat", BODYPART_DAMAGE_HEAT)
			return BURN
		if("cold", BODYPART_DAMAGE_COLD)
			return BURN
		if("acid", BODYPART_DAMAGE_ACID)
			return BURN
	return BRUTE

/obj/item/proc/get_cyberpunk_damage_armor_flag(type_key)
	switch(type_key)
		if("pierce", BODYPART_DAMAGE_PIERCE)
			return BULLET
		if("slash", BODYPART_DAMAGE_SLASH)
			return MELEE
		if("heat", BODYPART_DAMAGE_HEAT)
			return FIRE
		if("cold", BODYPART_DAMAGE_COLD)
			return FIRE
		if("acid", BODYPART_DAMAGE_ACID)
			return ACID
	return MELEE

/obj/item/proc/get_cyberpunk_damage_brute_type(type_key)
	switch(type_key)
		if("pierce", BODYPART_DAMAGE_PIERCE)
			return BODYPART_DAMAGE_PIERCE
		if("slash", BODYPART_DAMAGE_SLASH)
			return BODYPART_DAMAGE_SLASH
	return BODYPART_DAMAGE_BLUNT

/obj/item/proc/get_cyberpunk_damage_burn_type(type_key)
	switch(type_key)
		if("cold", BODYPART_DAMAGE_COLD)
			return BODYPART_DAMAGE_COLD
		if("acid", BODYPART_DAMAGE_ACID)
			return BODYPART_DAMAGE_ACID
	return BODYPART_DAMAGE_HEAT

/obj/item/proc/get_cyberpunk_damage_sharpness(type_key)
	switch(type_key)
		if("pierce", BODYPART_DAMAGE_PIERCE)
			return SHARP_POINTY
		if("slash", BODYPART_DAMAGE_SLASH)
			return SHARP_EDGED
	return get_sharpness()

/obj/item/proc/get_cyberpunk_armor_report()
	var/list/report = list()
	if(cyberpunk_broken)
		return report
	var/list/armor_keys = list(MELEE, BULLET, LASER, ENERGY, FIRE, ACID)
	for(var/armor_key in armor_keys)
		var/rating = get_armor_rating(armor_key)
		if(rating)
			report += "[armor_key] [rating]"
	return report

/obj/item/proc/get_cyberpunk_module_report()
	var/list/report = list()
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(!module)
			continue
		report += "[module.name] T[module.module_tier] ([module.module_slot], [module.manufacturer][module.has_active_ability() ? ", active: [module.active_ability_name]" : ""])"
	if(length(cyberpunk_module_slots))
		var/list/slot_report = list()
		for(var/slot_id in cyberpunk_module_slots)
			slot_report += "[slot_id] [get_cyberpunk_installed_module_count(slot_id)]/[cyberpunk_module_slots[slot_id]]"
		report += "slots: [slot_report.Join(", ")]"
	return report

/obj/item/proc/select_cyberpunk_module(mob/user, active_only = FALSE, force_menu = FALSE)
	if(!length(cyberpunk_modules))
		return null
	if(!force_menu && length(cyberpunk_modules) == 1 && (!active_only || cyberpunk_modules[1]?.has_active_ability()))
		return cyberpunk_modules[1]
	var/list/choices = list()
	var/list/module_by_choice = list()
	for(var/i in 1 to length(cyberpunk_modules))
		var/datum/cyberpunk_item_module/module = cyberpunk_modules[i]
		if(!module)
			continue
		if(active_only && !module.has_active_ability())
			continue
		var/choice_name = "[i]. [module.name] T[module.module_tier]"
		choices[choice_name] = image(icon = 'icons/obj/devices/circuitry_n_data.dmi', icon_state = "component")
		module_by_choice[choice_name] = module
	if(!length(choices))
		return null
	var/pick = show_radial_menu(user, src, choices, radius = 36, require_near = TRUE, tooltips = TRUE)
	return module_by_choice[pick]

/obj/item/proc/can_hand_remove_cyberpunk_modules(mob/user)
	if(!user || !length(cyberpunk_modules))
		return FALSE
	if(is_cyberpunk_modular_weapon())
		return !cyberpunk_weapon_assembled
	return !!cyberpunk_equipment_form

/obj/item/proc/get_cyberpunk_module_item_type(datum/cyberpunk_item_module/module)
	if(!module)
		return null
	var/fallback_type
	for(var/module_item_type in subtypesof(/obj/item/cyberpunk_item_module))
		var/obj/item/cyberpunk_item_module/module_item = new module_item_type(null)
		if(module_item.module_datum_type != module.type)
			qdel(module_item)
			continue
		if(module_item.module_tier == module.module_tier)
			qdel(module_item)
			return module_item_type
		if(!fallback_type)
			fallback_type = module_item_type
		qdel(module_item)
	return fallback_type

/obj/item/proc/eject_cyberpunk_module(datum/cyberpunk_item_module/module, mob/living/user)
	if(!(module in cyberpunk_modules))
		return FALSE
	var/module_item_type = get_cyberpunk_module_item_type(module)
	if(!module_item_type)
		return FALSE
	var/module_name = module.name
	var/obj/item/cyberpunk_item_module/module_item = new module_item_type(get_turf(src))
	module_item.cyberpunk_manufacturer = module.manufacturer
	module_item.module_tier = module.module_tier
	module_item.module_variant = module.module_variant
	clear_cyberpunk_module_active(module)
	LAZYREMOVE(cyberpunk_modules, module)
	module.on_remove(src, user)
	qdel(module)
	if(user && !user.put_in_hands(module_item))
		module_item.forceMove(drop_location())
	if(is_cyberpunk_modular_weapon() && length(get_missing_cyberpunk_weapon_modules()))
		cyberpunk_weapon_assembled = FALSE
	if(cyberpunk_weapon_form)
		recalculate_cyberpunk_weapon_stats()
	else if(cyberpunk_equipment_form)
		recalculate_cyberpunk_equipment_stats()
	to_chat(user, span_notice("You remove [module_name] from [src]."))
	return TRUE

/obj/item/proc/hand_remove_cyberpunk_module(mob/living/user)
	if(!can_hand_remove_cyberpunk_modules(user))
		return FALSE
	var/datum/cyberpunk_item_module/module = select_cyberpunk_module(user, FALSE, TRUE)
	if(!module)
		return TRUE
	return eject_cyberpunk_module(module, user)

/obj/item/proc/show_cyberpunk_modular_radial(mob/user)
	if(!cyberpunk_equipment_form && !cyberpunk_weapon_form && !length(cyberpunk_modules))
		return FALSE
	var/list/options = list(
		"Inspect modules" = image(icon = 'icons/obj/devices/circuitry_n_data.dmi', icon_state = "component"),
		"Show stats" = image(icon = 'icons/obj/devices/scanner.dmi', icon_state = "scanmode"),
	)
	var/has_active = FALSE
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(module?.has_active_ability())
			has_active = TRUE
			break
	if(has_active)
		options["Activate module"] = image(icon = 'icons/obj/devices/circuitry_n_data.dmi', icon_state = "integrated_circuit")
	if(cyberpunk_weapon_form)
		options["Weapon state"] = image(icon = 'icons/obj/weapons/guns/projectiles.dmi', icon_state = "revolver")
	if(cyberpunk_equipment_form)
		options["Protection"] = image(icon = 'icons/obj/clothing/suits/armor.dmi', icon_state = "armor")
	var/choice = show_radial_menu(user, src, options, radius = 42, require_near = TRUE, tooltips = TRUE)
	switch(choice)
		if("Inspect modules")
			var/datum/cyberpunk_item_module/picked_module = select_cyberpunk_module(user)
			if(!picked_module)
				to_chat(user, span_notice("[src] has no installed modules."))
				return TRUE
			to_chat(user, span_notice("[picked_module.name] T[picked_module.module_tier]: slot [picked_module.module_slot], manufacturer [picked_module.manufacturer], effect scale [round(picked_module.get_effective_scale() * 100)]%[picked_module.has_active_ability() ? ", active: [picked_module.active_ability_name]" : ""]."))
			return TRUE
		if("Show stats")
			var/list/diagnostics = get_cyberpunk_diagnostic_data(user)
			if(length(diagnostics))
				to_chat(user, span_notice(diagnostics.Join("<br>")))
			else
				to_chat(user, span_notice("[src] has no modular diagnostics."))
			return TRUE
		if("Activate module")
			var/datum/cyberpunk_item_module/active_module = select_cyberpunk_module(user, TRUE)
			var/mob/living/living_user = user
			if(!active_module || !istype(living_user))
				return TRUE
			active_module.activate(src, living_user)
			return TRUE
		if("Weapon state")
			var/list/missing_modules = get_missing_cyberpunk_weapon_modules()
			to_chat(user, span_notice("[src]: [cyberpunk_weapon_assembled ? "assembled" : "unassembled"] [get_cyberpunk_effective_weapon_form()], material [get_cyberpunk_weapon_material_name()][length(missing_modules) ? ", missing [missing_modules.Join(", ")]" : ""]."))
			return TRUE
		if("Protection")
			var/list/armor_report = get_cyberpunk_armor_report()
			to_chat(user, span_notice("[src]: [cyberpunk_equipment_form], material [get_cyberpunk_equipment_material_name()], protection [length(armor_report) ? armor_report.Join(", ") : "none"]."))
			return TRUE
	return TRUE

/obj/item/proc/get_cyberpunk_installed_module_count(slot_id)
	var/count = 0
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(module?.module_slot == slot_id)
			count++
	return count

/obj/item/proc/is_cyberpunk_modular_weapon()
	return !!cyberpunk_weapon_form

/obj/item/proc/get_cyberpunk_effective_weapon_form()
	if(!cyberpunk_weapon_form)
		return null
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(module.weapon_form_override)
			return module.weapon_form_override
	return cyberpunk_weapon_form

/obj/item/proc/get_cyberpunk_weapon_form_label()
	switch(get_cyberpunk_effective_weapon_form())
		if("physical_melee")
			return "physical melee base"
		if("energy_melee")
			return "energy melee base"
		if("knife")
			return "knife"
		if("club")
			return "club"
		if("twohand_sword")
			return "two-handed sword"
		if("twohand_hammer")
			return "two-handed hammer"
		if("axe")
			return "axe"
		if("twohand_axe")
			return "two-handed axe"
		if("rapier")
			return "rapier"
		if("spear")
			return "spear"
		if("staff")
			return "staff"
		if("ballistic")
			return "ballistic firearm"
		if("energy")
			return "energy weapon"
		if("revolver")
			return "revolver"
		if("pistol")
			return "pistol"
		if("smg")
			return "SMG"
		if("rifle")
			return "rifle"
		if("shotgun")
			return "shotgun"
		if("sniper")
			return "sniper rifle"
		if("assault")
			return "assault rifle"
		if("lmg")
			return "machine gun"
		if("rocket")
			return "rocket launcher"
		if("laser")
			return "laser weapon"
		if("plasma")
			return "plasma weapon"
	return "[get_cyberpunk_effective_weapon_form()]"

/obj/item/proc/update_cyberpunk_weapon_identity()
	if(!is_cyberpunk_modular_weapon())
		return
	if(!cyberpunk_weapon_base_name)
		cyberpunk_weapon_base_name = initial(name)
	if(!cyberpunk_weapon_base_desc)
		cyberpunk_weapon_base_desc = initial(desc)
	var/form_label = get_cyberpunk_weapon_form_label()
	var/material_label = get_cyberpunk_weapon_material_name()
	name = "[material_label] modular [form_label]"
	desc = "[cyberpunk_weapon_base_desc] Its current main module configures it as a [form_label]."

/obj/item/proc/is_cyberpunk_on_table()
	return !!(locate(/obj/structure/table) in get_turf(src))

/obj/item/proc/can_accept_cyberpunk_module(datum/cyberpunk_item_module/module)
	if(!module)
		return FALSE
	if(is_cyberpunk_modular_weapon() && cyberpunk_weapon_assembled && !(module.module_slot in list("sight", "underbarrel")))
		return FALSE
	if(!length(cyberpunk_module_slots))
		return TRUE
	var/slot_limit = cyberpunk_module_slots[module.module_slot]
	if(!slot_limit)
		return FALSE
	if(get_cyberpunk_module_to_replace(module))
		return TRUE
	return get_cyberpunk_installed_module_count(module.module_slot) < slot_limit

/obj/item/proc/get_cyberpunk_module_to_replace(datum/cyberpunk_item_module/new_module)
	if(!new_module || !length(cyberpunk_modules))
		return null
	if(!length(cyberpunk_module_slots))
		return null
	var/slot_limit = cyberpunk_module_slots[new_module.module_slot]
	if(!slot_limit || get_cyberpunk_installed_module_count(new_module.module_slot) < slot_limit)
		return null
	for(var/datum/cyberpunk_item_module/installed_module as anything in cyberpunk_modules)
		if(installed_module.module_slot != new_module.module_slot)
			continue
		return installed_module
	return null

/obj/item/proc/get_missing_cyberpunk_weapon_modules()
	var/list/missing = list()
	for(var/slot_id in cyberpunk_weapon_required_slots)
		var/needed = cyberpunk_weapon_required_slots[slot_id]
		if(get_cyberpunk_installed_module_count(slot_id) < needed)
			missing += "[slot_id] [get_cyberpunk_installed_module_count(slot_id)]/[needed]"
	return missing

/obj/item/proc/can_use_cyberpunk_weapon(mob/living/user)
	if(!is_cyberpunk_modular_weapon() || cyberpunk_weapon_assembled)
		return TRUE
	if(user)
		to_chat(user, span_warning("[src] is not assembled yet. Lock its modules with a wrench while it rests on a table."))
	return FALSE

/obj/item/proc/get_cyberpunk_weapon_material_name()
	switch(cyberpunk_weapon_material)
		if("polymer")
			return "polymer"
		if("ceramic")
			return "ceramic"
		if("plasteel")
			return "plasteel"
		if("composite")
			return "smart composite"
	return "steel"

/obj/item/proc/apply_cyberpunk_weapon_material_stats()
	switch(cyberpunk_weapon_material)
		if("polymer")
			w_class = max(WEIGHT_CLASS_TINY, w_class - 1)
			force *= 0.9
			throwforce *= 0.9
			attack_speed *= 0.9
			if(uses_integrity)
				modify_max_integrity(max(1, round(max_integrity * 0.85)), FALSE)
			var/obj/item/gun/polymer_gun = src
			if(istype(polymer_gun))
				polymer_gun.fire_delay = round(polymer_gun.fire_delay * 0.9)
				polymer_gun.spread += 2
		if("ceramic")
			armour_penetration += 4
			force *= 1.05
			throwforce *= 1.05
			if(uses_integrity)
				modify_max_integrity(max(1, round(max_integrity * 0.9)), FALSE)
			var/obj/item/gun/ceramic_gun = src
			if(istype(ceramic_gun))
				ceramic_gun.projectile_wound_bonus += 2
				ceramic_gun.spread += 1
		if("plasteel")
			w_class = min(WEIGHT_CLASS_GIGANTIC, w_class + 1)
			force *= 1.15
			throwforce *= 1.15
			armour_penetration += 2
			if(uses_integrity)
				modify_max_integrity(max(1, round(max_integrity * 1.25)), FALSE)
			var/obj/item/gun/plasteel_gun = src
			if(istype(plasteel_gun))
				plasteel_gun.projectile_damage_multiplier += 0.08
				plasteel_gun.fire_delay = round(plasteel_gun.fire_delay * 1.05)
		if("composite")
			force *= 1.05
			throwforce *= 1.05
			attack_speed *= 0.95
			armour_penetration += 2
			if(uses_integrity)
				modify_max_integrity(max(1, round(max_integrity * 1.1)), FALSE)
			if(cyberpunk_module_slots)
				cyberpunk_module_slots["utility"] = (cyberpunk_module_slots["utility"] || 0) + 1
			var/obj/item/gun/composite_gun = src
			if(istype(composite_gun))
				composite_gun.spread = max(0, composite_gun.spread - 2)
				composite_gun.projectile_speed_multiplier += 0.05

/obj/item/proc/apply_cyberpunk_weapon_resource_quality()
	var/quality = vars["resource_quality"]
	if(!quality)
		return
	var/quality_multiplier = get_resource_quality_multiplier(quality)
	if(quality_multiplier == 1)
		return
	force *= quality_multiplier
	throwforce *= quality_multiplier
	armour_penetration = round(armour_penetration * quality_multiplier)
	if(uses_integrity)
		modify_max_integrity(max(1, round(max_integrity * quality_multiplier)), FALSE)
	var/obj/item/gun/gun = src
	if(!istype(gun))
		return
	gun.projectile_damage_multiplier *= quality_multiplier
	gun.projectile_wound_bonus = round(gun.projectile_wound_bonus * quality_multiplier)
	gun.projectile_speed_multiplier *= max(0.25, sqrt(quality_multiplier))
	gun.fire_delay = max(1, round(gun.fire_delay / max(0.25, sqrt(quality_multiplier))))
	gun.spread = max(0, round(gun.spread / max(0.25, quality_multiplier)))

/obj/item/proc/capture_cyberpunk_weapon_baseline()
	if(cyberpunk_weapon_baseline_ready)
		return
	cyberpunk_base_force = force
	cyberpunk_base_throwforce = throwforce
	cyberpunk_base_attack_speed = attack_speed
	cyberpunk_base_armour_penetration = armour_penetration
	cyberpunk_base_w_class = w_class
	if(uses_integrity)
		cyberpunk_base_max_integrity = max_integrity
	var/obj/item/gun/gun = src
	if(istype(gun))
		cyberpunk_base_fire_delay = gun.fire_delay
		cyberpunk_base_spread = gun.spread
		cyberpunk_base_projectile_damage_multiplier = gun.projectile_damage_multiplier
		cyberpunk_base_projectile_wound_bonus = gun.projectile_wound_bonus
		cyberpunk_base_projectile_speed_multiplier = gun.projectile_speed_multiplier
		if("accepted_magazine_type" in gun.vars)
			cyberpunk_base_accepted_magazine_type = gun.vars["accepted_magazine_type"]
		if("spawn_magazine_type" in gun.vars)
			cyberpunk_base_spawn_magazine_type = gun.vars["spawn_magazine_type"]
		if("ammo_type" in gun.vars)
			cyberpunk_base_ammo_type = gun.vars["ammo_type"]
		if("caliber" in gun.vars)
			cyberpunk_base_caliber = gun.vars["caliber"]
	cyberpunk_weapon_baseline_ready = TRUE

/obj/item/proc/recalculate_cyberpunk_weapon_stats()
	if(!is_cyberpunk_modular_weapon())
		return
	capture_cyberpunk_weapon_baseline()
	force = cyberpunk_base_force
	throwforce = cyberpunk_base_throwforce
	attack_speed = cyberpunk_base_attack_speed
	armour_penetration = cyberpunk_base_armour_penetration
	w_class = cyberpunk_base_w_class
	cyberpunk_damage_profile = null
	cyberpunk_melee_module_burn_damage = 0
	cyberpunk_melee_module_stamina_damage = 0
	cyberpunk_melee_module_shock_chance = 0
	cyberpunk_module_slots = cyberpunk_base_module_slots?.Copy() || cyberpunk_module_slots?.Copy() || list()
	if(uses_integrity)
		modify_max_integrity(max(1, cyberpunk_base_max_integrity), FALSE)
	var/obj/item/gun/gun = src
	if(istype(gun))
		gun.fire_delay = cyberpunk_base_fire_delay
		gun.spread = cyberpunk_base_spread
		gun.projectile_damage_multiplier = cyberpunk_base_projectile_damage_multiplier || 1
		gun.projectile_wound_bonus = cyberpunk_base_projectile_wound_bonus
		gun.projectile_speed_multiplier = cyberpunk_base_projectile_speed_multiplier || 1
		if("accepted_magazine_type" in gun.vars)
			gun.vars["accepted_magazine_type"] = cyberpunk_base_accepted_magazine_type
		if("spawn_magazine_type" in gun.vars)
			gun.vars["spawn_magazine_type"] = cyberpunk_base_spawn_magazine_type
		if("ammo_type" in gun.vars)
			gun.vars["ammo_type"] = cyberpunk_base_ammo_type
		if("caliber" in gun.vars)
			gun.vars["caliber"] = cyberpunk_base_caliber
	apply_cyberpunk_weapon_material_stats()
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		module.apply_weapon_stats(src)
	apply_cyberpunk_weapon_resource_quality()
	update_cyberpunk_weapon_identity()
	normalize_cyberpunk_item_tier_and_rarity()

/obj/item/proc/setup_cyberpunk_weapon(form_id, list/base_slots, list/required_slots, assembled = FALSE, material_id = "steel")
	cyberpunk_weapon_form = form_id
	cyberpunk_weapon_material = material_id || "steel"
	cyberpunk_weapon_assembled = assembled
	cyberpunk_base_module_slots = base_slots?.Copy() || list()
	cyberpunk_module_slots = cyberpunk_base_module_slots.Copy()
	cyberpunk_weapon_required_slots = required_slots?.Copy() || list()
	cyberpunk_weapon_base_name ||= initial(name)
	cyberpunk_weapon_base_desc ||= initial(desc)
	recalculate_cyberpunk_weapon_stats()
	if(length(cyberpunk_initial_module_types) && !length(cyberpunk_modules))
		for(var/module_type in cyberpunk_initial_module_types)
			var/datum/cyberpunk_item_module/module = new module_type
			module.manufacturer = get_cyberpunk_manufacturer()
			if(!can_accept_cyberpunk_module(module))
				qdel(module)
				continue
			LAZYADD(cyberpunk_modules, module)
		recalculate_cyberpunk_weapon_stats()
	normalize_cyberpunk_item_tier_and_rarity()

/obj/item/proc/assemble_cyberpunk_weapon(mob/living/user)
	if(!is_cyberpunk_modular_weapon())
		return FALSE
	if(!is_cyberpunk_on_table())
		to_chat(user, span_warning("Put [src] on a table before locking its frame."))
		return TRUE
	if(cyberpunk_weapon_assembled)
		if(!do_after(user, 2 SECONDS, target = src))
			return TRUE
		cyberpunk_weapon_assembled = FALSE
		to_chat(user, span_notice("You unlock [src]'s frame. Its modules can now be changed."))
		return TRUE
	var/list/missing = get_missing_cyberpunk_weapon_modules()
	if(length(missing))
		to_chat(user, span_warning("[src] is missing required modules: [missing.Join(", ")]."))
		return TRUE
	if(!do_after(user, 3 SECONDS, target = src))
		return TRUE
	cyberpunk_weapon_assembled = TRUE
	recalculate_cyberpunk_weapon_stats()
	to_chat(user, span_notice("You lock [src]'s frame into a working [get_cyberpunk_effective_weapon_form()]."))
	return TRUE

/obj/item/proc/remove_cyberpunk_weapon_module_with_tool(mob/living/user)
	if(!length(cyberpunk_modules))
		return FALSE
	if(!is_cyberpunk_on_table())
		to_chat(user, span_warning("Put [src] on a table before removing weapon modules."))
		return TRUE
	var/datum/cyberpunk_item_module/module = select_cyberpunk_module(user)
	if(!module)
		return TRUE
	var/remove_delay = 2 SECONDS * (user ? user.get_cyberpunk_item_module_time_multiplier(src) : 1)
	if(!do_after(user, remove_delay, target = src))
		return TRUE
	var/module_name = module.name
	if(remove_cyberpunk_module(module, user))
		if(length(get_missing_cyberpunk_weapon_modules()))
			cyberpunk_weapon_assembled = FALSE
		recalculate_cyberpunk_weapon_stats()
		to_chat(user, span_notice("You remove [module_name] from [src]."))
	return TRUE

/obj/item/proc/can_cyberpunk_weapon_hold_melee_coating()
	return is_cyberpunk_modular_weapon() && cyberpunk_weapon_assembled && !istype(src, /obj/item/gun)

/obj/item/proc/apply_cyberpunk_melee_coating_from(obj/item/reagent_containers/container, mob/living/user)
	if(!can_cyberpunk_weapon_hold_melee_coating())
		return FALSE
	if(!container?.reagents?.total_volume || !container.is_open_container())
		return FALSE
	if(!cyberpunk_melee_coating)
		cyberpunk_melee_coating = new /datum/reagents(10, INJECTABLE)
		cyberpunk_melee_coating.my_atom = src
	var/free_volume = cyberpunk_melee_coating.maximum_volume - cyberpunk_melee_coating.total_volume
	if(free_volume <= 0)
		to_chat(user, span_warning("[src]'s edge is already fully coated."))
		return TRUE
	var/transferred = container.reagents.trans_to(cyberpunk_melee_coating, min(10, free_volume), transferred_by = user)
	if(transferred <= 0)
		return FALSE
	cyberpunk_melee_coating_charges = min(10, cyberpunk_melee_coating_charges + round(transferred))
	to_chat(user, span_notice("You coat [src] with [round(transferred)]u of reagents. It has [cyberpunk_melee_coating_charges] injection hit(s)."))
	return TRUE

/obj/item/proc/inject_cyberpunk_melee_coating(mob/living/target, mob/living/user)
	if(!can_cyberpunk_weapon_hold_melee_coating() || !target?.reagents || !cyberpunk_melee_coating?.total_volume || cyberpunk_melee_coating_charges <= 0)
		return FALSE
	var/transferred = cyberpunk_melee_coating.trans_to(target, min(1, cyberpunk_melee_coating.total_volume), transferred_by = user, methods = INJECT)
	if(transferred <= 0)
		return FALSE
	cyberpunk_melee_coating_charges--
	to_chat(user, span_notice("[src] injects its coating into [target]. [cyberpunk_melee_coating_charges] hit(s) remain."))
	if(cyberpunk_melee_coating_charges <= 0 || cyberpunk_melee_coating.total_volume <= 0)
		qdel(cyberpunk_melee_coating)
		cyberpunk_melee_coating = null
		cyberpunk_melee_coating_charges = 0
	return TRUE

/obj/item/proc/apply_cyberpunk_melee_module_effects(mob/living/target, mob/living/user)
	if(!can_cyberpunk_weapon_hold_melee_coating() || !target || !user)
		return FALSE
	var/applied = FALSE
	if(cyberpunk_melee_module_burn_damage > 0)
		target.apply_damage(cyberpunk_melee_module_burn_damage, BURN, user.zone_selected, attacking_item = src, burn_type = BODYPART_DAMAGE_HEAT)
		applied = TRUE
	if(cyberpunk_melee_module_stamina_damage > 0)
		target.apply_damage(cyberpunk_melee_module_stamina_damage, STAMINA, user.zone_selected, attacking_item = src)
		applied = TRUE
	if(cyberpunk_melee_module_shock_chance > 0 && prob(cyberpunk_melee_module_shock_chance))
		target.adjust_staggered_up_to(2 SECONDS, 6 SECONDS)
		to_chat(user, span_notice("[src]'s shock coating makes [target.declent_ru(ACCUSATIVE)] stagger."))
		applied = TRUE
	return applied

/obj/item/proc/get_cyberpunk_equipment_material_name()
	switch(cyberpunk_equipment_material)
		if("fabric")
			return "ballistic fabric"
		if("wood")
			return "laminated wood"
		if("ceramic")
			return "ceramic"
		if("plasteel")
			return "plasteel"
		if("composite")
			return "smart composite"
	return cyberpunk_equipment_material || "standard"

/obj/item/proc/get_cyberpunk_equipment_material_armor()
	switch(cyberpunk_equipment_material)
		if("fabric")
			return list(MELEE = 5, BULLET = 10, LASER = 3, ENERGY = 5, FIRE = 7, ACID = 4, WOUND = 2)
		if("wood")
			return list(MELEE = 10, BULLET = 4, LASER = 2, ENERGY = 2, FIRE = -15, ACID = 1, WOUND = 2)
		if("ceramic")
			return list(MELEE = 7, BULLET = 18, LASER = 16, ENERGY = 8, FIRE = 12, ACID = 5, WOUND = 6)
		if("plasteel")
			return list(MELEE = 18, BULLET = 16, LASER = 8, ENERGY = 10, FIRE = 14, ACID = 10, WOUND = 8)
		if("composite")
			return list(MELEE = 12, BULLET = 14, LASER = 12, ENERGY = 16, FIRE = 10, ACID = 9, WOUND = 5)
	return list(MELEE = 10, BULLET = 10, LASER = 5, ENERGY = 5, FIRE = 5, ACID = 5)

/obj/item/proc/get_cyberpunk_equipment_material_weight_delta()
	switch(cyberpunk_equipment_material)
		if("fabric")
			return -1
		if("wood")
			return 0
		if("ceramic")
			return 1
		if("plasteel")
			return 2
		if("composite")
			return 0
	return 0

/obj/item/proc/get_cyberpunk_equipment_material_integrity_delta()
	switch(cyberpunk_equipment_material)
		if("fabric")
			return -20
		if("wood")
			return -10
		if("ceramic")
			return 25
		if("plasteel")
			return 70
		if("composite")
			return 30
	return 0

/obj/item/proc/get_cyberpunk_equipment_material_slot_delta()
	switch(cyberpunk_equipment_material)
		if("fabric")
			return list("lining" = 1, "utility" = 1)
		if("wood")
			return list("utility" = 1)
		if("ceramic")
			return list("plate" = 1)
		if("plasteel")
			return list("plate" = 1, "active" = 1)
		if("composite")
			return list("mobility" = 1, "utility" = 1)
	return list()

/obj/item/proc/apply_cyberpunk_equipment_resource_quality(list/final_armor, list/final_values)
	var/quality = vars["resource_quality"]
	if(!quality)
		return
	var/quality_multiplier = get_resource_quality_multiplier(quality)
	if(quality_multiplier == 1)
		return
	for(var/armor_key in final_armor)
		final_armor[armor_key] = round(final_armor[armor_key] * quality_multiplier)
	final_values["integrity"] = max(1, round(final_values["integrity"] * quality_multiplier))
	final_values["weight"] += round((1 - quality_multiplier) * 2)
	if(!isnull(final_values["slowdown"]))
		final_values["slowdown"] = max(0, final_values["slowdown"] * max(0.25, 2 - quality_multiplier))

/obj/item/proc/capture_cyberpunk_modular_baseline()
	if(cyberpunk_modular_baseline_ready)
		return
	cyberpunk_base_armor_values = get_armor().get_rating_list()
	cyberpunk_base_w_class = w_class
	cyberpunk_base_max_integrity = max_integrity
	if("slowdown" in vars)
		cyberpunk_base_slowdown = vars["slowdown"]
	cyberpunk_modular_baseline_ready = TRUE

/obj/item/proc/recalculate_cyberpunk_equipment_stats()
	if(!cyberpunk_equipment_form)
		return
	capture_cyberpunk_modular_baseline()
	var/list/final_armor = cyberpunk_base_armor_values?.Copy() || list()
	var/list/material_armor = get_cyberpunk_equipment_material_armor()
	for(var/armor_key in material_armor)
		final_armor[armor_key] = (final_armor[armor_key] || 0) + material_armor[armor_key]
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(!module || !length(module.armor_delta))
			continue
		var/module_scale = module.get_effective_scale()
		for(var/armor_key in module.armor_delta)
			final_armor[armor_key] = (final_armor[armor_key] || 0) + round(module.armor_delta[armor_key] * module_scale)
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_active_module_armor)
		var/list/active_armor = cyberpunk_active_module_armor[module]
		for(var/armor_key in active_armor)
			final_armor[armor_key] = (final_armor[armor_key] || 0) + active_armor[armor_key]
	set_armor(get_armor_by_type(/datum/armor/none).generate_new_with_modifiers(final_armor))

	var/final_weight = (isnull(cyberpunk_base_w_class) ? w_class : cyberpunk_base_w_class) + get_cyberpunk_equipment_material_weight_delta()
	var/final_integrity = (cyberpunk_base_max_integrity || max_integrity) + get_cyberpunk_equipment_material_integrity_delta()
	var/final_slowdown = isnull(cyberpunk_base_slowdown) ? null : cyberpunk_base_slowdown
	cyberpunk_module_slots = cyberpunk_base_module_slots?.Copy() || cyberpunk_module_slots?.Copy() || list()
	var/list/slot_delta = get_cyberpunk_equipment_material_slot_delta()
	for(var/slot_id in slot_delta)
		cyberpunk_module_slots[slot_id] = max(0, (cyberpunk_module_slots[slot_id] || 0) + slot_delta[slot_id])
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(!module)
			continue
		var/module_scale = module.get_effective_scale()
		final_weight += round(module.weight_delta * module_scale)
		final_integrity += round(module.integrity_delta * module_scale)
		if(!isnull(final_slowdown))
			final_slowdown += module.slowdown_delta * module_scale
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_active_module_slowdown)
		if(!isnull(final_slowdown))
			final_slowdown += cyberpunk_active_module_slowdown[module]
	var/list/final_values = list(
		"weight" = final_weight,
		"integrity" = final_integrity,
		"slowdown" = final_slowdown,
	)
	apply_cyberpunk_equipment_resource_quality(final_armor, final_values)
	final_weight = final_values["weight"]
	final_integrity = final_values["integrity"]
	final_slowdown = final_values["slowdown"]
	w_class = clamp(final_weight, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(uses_integrity)
		modify_max_integrity(max(1, final_integrity), FALSE)
	if(!isnull(final_slowdown) && ("slowdown" in vars))
		vars["slowdown"] = max(0, final_slowdown)
	normalize_cyberpunk_item_tier_and_rarity()

/obj/item/proc/setup_cyberpunk_equipment(form_id, material_id, list/base_slots)
	cyberpunk_equipment_form = form_id
	cyberpunk_equipment_material = material_id
	cyberpunk_base_module_slots = base_slots?.Copy() || list()
	cyberpunk_module_slots = cyberpunk_base_module_slots.Copy()
	recalculate_cyberpunk_equipment_stats()
	if(length(cyberpunk_initial_module_types) && !length(cyberpunk_modules))
		for(var/module_type in cyberpunk_initial_module_types)
			var/datum/cyberpunk_item_module/module = new module_type
			module.manufacturer = get_cyberpunk_manufacturer()
			if(!can_accept_cyberpunk_module(module))
				qdel(module)
				continue
			LAZYADD(cyberpunk_modules, module)
		recalculate_cyberpunk_equipment_stats()
	normalize_cyberpunk_item_tier_and_rarity()

/obj/item/proc/set_cyberpunk_equipment_material(material_id)
	if(!cyberpunk_equipment_form || !material_id)
		return
	cyberpunk_equipment_material = material_id
	recalculate_cyberpunk_equipment_stats()
	name = "[get_cyberpunk_equipment_material_name()] [cyberpunk_equipment_form]"

/obj/item/click_alt_secondary(mob/user)
	if(!cyberpunk_equipment_form && !cyberpunk_weapon_form && !length(cyberpunk_modules))
		return ..()
	return show_cyberpunk_modular_radial(user) ? CLICK_ACTION_SUCCESS : CLICK_ACTION_BLOCKING

/obj/item/proc/add_cyberpunk_module_active(datum/cyberpunk_item_module/module, list/armor_delta, slowdown_delta, duration)
	if(!module)
		return
	if(length(armor_delta))
		LAZYSET(cyberpunk_active_module_armor, module, armor_delta)
	if(slowdown_delta)
		LAZYSET(cyberpunk_active_module_slowdown, module, slowdown_delta)
	recalculate_cyberpunk_equipment_stats()
	if(duration > 0)
		addtimer(CALLBACK(src, PROC_REF(clear_cyberpunk_module_active), module), duration, TIMER_STOPPABLE)

/obj/item/proc/clear_cyberpunk_module_active(datum/cyberpunk_item_module/module)
	if(module)
		cyberpunk_active_module_armor -= module
		cyberpunk_active_module_slowdown -= module
	else
		cyberpunk_active_module_armor = null
		cyberpunk_active_module_slowdown = null
	recalculate_cyberpunk_equipment_stats()

/obj/item/proc/apply_cyberpunk_active_wear(mob/living/user, atom/target)
	if(cyberpunk_active_wear <= 0 || !uses_integrity || (resistance_flags & INDESTRUCTIBLE) || cyberpunk_broken)
		return FALSE
	var/wear_amount = cyberpunk_active_wear
	var/kowalski = get_cyberpunk_base_effect_strength(user, "kowalski")
	if(kowalski > 0)
		wear_amount *= max(0.1, 1 - 0.25 * kowalski)
	take_damage(max(0, round(wear_amount, 0.1)), BRUTE, CONSUME, FALSE)
	if(uses_integrity && get_integrity() <= max(1, max_integrity * cyberpunk_repair_threshold))
		cyberpunk_broken = TRUE
	return TRUE

/obj/item/proc/repair_cyberpunk_item(amount, mob/living/user)
	if(!uses_integrity)
		return 0
	. = repair_damage(amount)
	if(. > 0)
		cyberpunk_last_repaired = world.time
		cyberpunk_last_condition_update = world.time
		if(cyberpunk_broken && get_integrity() >= max(1, max_integrity * cyberpunk_repair_threshold))
			cyberpunk_broken = FALSE
	return .

//CYBERPUNK BUILD - rebuild and delete before release
/obj/item/welder_act(mob/living/user, obj/item/tool)
	if(!uses_integrity || get_integrity() >= max_integrity)
		return ..()
	var/repair_amount = user ? user.get_cyberpunk_item_repair_amount(src, 20) : 20
	var/repair_delay = 2 SECONDS * (user ? user.get_cyberpunk_item_repair_time_multiplier(src) : 1)
	if(!do_after(user, repair_delay, target = src))
		return ITEM_INTERACT_BLOCKING
	var/repaired = repair_cyberpunk_item(repair_amount, user)
	if(repaired > 0)
		to_chat(user, span_notice("You repair [src] by [repaired] integrity."))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/wrench_act(mob/living/user, obj/item/tool)
	if(is_cyberpunk_modular_weapon())
		return assemble_cyberpunk_weapon(user) ? ITEM_INTERACT_SUCCESS : ..()
	if(!length(cyberpunk_modules))
		return ..()
	var/datum/cyberpunk_item_module/module = select_cyberpunk_module(user)
	if(!module)
		return ITEM_INTERACT_BLOCKING
	var/remove_delay = 2 SECONDS * (user ? user.get_cyberpunk_item_module_time_multiplier(src) : 1)
	if(!do_after(user, remove_delay, target = src))
		return ITEM_INTERACT_BLOCKING
	var/module_name = module.name
	if(remove_cyberpunk_module(module, user))
		to_chat(user, span_notice("You remove [module_name] from [src]."))
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/screwdriver_act(mob/living/user, obj/item/tool)
	if(is_cyberpunk_modular_weapon())
		return remove_cyberpunk_weapon_module_with_tool(user) ? ITEM_INTERACT_SUCCESS : ..()
	return ..()

/obj/item/atom_break(damage_flag)
	. = ..()
	cyberpunk_broken = TRUE

/obj/item/atom_fix()
	. = ..()
	if(uses_integrity && get_integrity() >= max(1, max_integrity * cyberpunk_repair_threshold))
		cyberpunk_broken = FALSE

/obj/item/atom_destruction(damage_flag)
	if(cyberpunk_spoil_result_type)
		new cyberpunk_spoil_result_type(drop_location())
		qdel(src)
		return
	switch(cyberpunk_spoil_behavior)
		if("broken")
			cyberpunk_broken = TRUE
			update_integrity(max(1, max_integrity * cyberpunk_repair_threshold * 0.5))
			update_appearance()
			return
		if("delete")
			qdel(src)
			return
		if("emergency")
			if(cyberpunk_emergency_breakdown(damage_flag))
				return
	return ..()

/obj/item/proc/cyberpunk_emergency_breakdown(damage_flag)
	return FALSE

/obj/item/get_armor_rating(damage_type)
	if(cyberpunk_broken)
		return 0
	var/rating = ..()
	var/mob/living/wearer = loc
	if(istype(wearer))
		rating = round(rating * get_cyberpunk_synergy_multiplier(wearer))
	return rating

/obj/item/proc/install_cyberpunk_module(datum/cyberpunk_item_module/module, mob/living/user)
	if(!module || !module.can_install(src, user))
		return FALSE
	var/datum/cyberpunk_item_module/replaced_module = get_cyberpunk_module_to_replace(module)
	if(replaced_module)
		var/replaced_name = replaced_module.name
		remove_cyberpunk_module(replaced_module, user)
		if(user)
			to_chat(user, span_notice("You replace [replaced_name] in [src]."))
	LAZYADD(cyberpunk_modules, module)
	module.on_install(src, user)
	normalize_cyberpunk_item_tier_and_rarity()
	return TRUE

/obj/item/proc/remove_cyberpunk_module(datum/cyberpunk_item_module/module, mob/living/user)
	if(!(module in cyberpunk_modules))
		return FALSE
	clear_cyberpunk_module_active(module)
	LAZYREMOVE(cyberpunk_modules, module)
	module.on_remove(src, user)
	qdel(module)
	normalize_cyberpunk_item_tier_and_rarity()
	return TRUE
