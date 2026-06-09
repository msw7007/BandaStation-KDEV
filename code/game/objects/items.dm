/// Anything you can pick up and hold.
/obj/item
	name = "item"
	icon = 'icons/obj/anomaly.dmi'
	abstract_type = /obj/item
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	burning_particles = /particles/smoke/burning/small
	pass_flags_self = PASSITEM
	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT

	/* !!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!

		IF YOU ADD MORE ICON CRAP TO THIS
		ENSURE YOU ALSO ADD THE NEW VARS TO CHAMELEON ITEM_ACTION'S update_item() PROC (/datum/action/item_action/chameleon/change/proc/update_item())
		WASHING MASHINE'S dye_item() PROC (/obj/item/proc/dye_item())
		AND ALSO TO THE CHANGELING PROFILE DISGUISE SYSTEMS (/datum/changeling_profile / /datum/antagonist/changeling/proc/create_profile() / /proc/changeling_transform())

		!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!! */

	///icon state for inhand overlays.
	var/inhand_icon_state = null
	///Icon file for left hand inhand overlays
	var/lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	///Icon file for right inhand overlays
	var/righthand_file = 'icons/mob/inhands/items_righthand.dmi'

	/// Angle of the icon, used for piercing and slashing attack animations, clockwise from *east-facing* sprites
	var/icon_angle = 0
	///icon file for an alternate attack icon
	var/attack_icon
	///icon state for an alternate attack icon
	var/attack_icon_state

	///Icon file for mob worn overlays.
	var/icon/worn_icon
	///Icon state for mob worn overlays, if null the normal icon_state will be used.
	var/worn_icon_state
	///Icon state for the belt overlay, if null the normal icon_state will be used.
	var/inside_belt_icon_state
	///Forced mob worn layer instead of the standard preferred size.
	var/alternate_worn_layer
	///The config type to use for greyscaled worn sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_worn
	///The config type to use for greyscaled left inhand sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_inhand_left
	///The config type to use for greyscaled right inhand sprites. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_inhand_right
	///The config type to use for greyscaled belt overlays. Both this and greyscale_colors must be assigned to work.
	var/greyscale_config_belt

	/* !!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!

		IF YOU ADD MORE ICON CRAP TO THIS
		ENSURE YOU ALSO ADD THE NEW VARS TO CHAMELEON ITEM_ACTION'S update_item() PROC (/datum/action/item_action/chameleon/change/proc/update_item())
		WASHING MASHINE'S dye_item() PROC (/obj/item/proc/dye_item())
		AND ALSO TO THE CHANGELING PROFILE DISGUISE SYSTEMS (/datum/changeling_profile / /datum/antagonist/changeling/proc/create_profile() / /proc/changeling_transform())

		!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!! */

	///Dimensions of the icon file used when this item is worn, eg: hats.dmi (32x32 sprite, 64x64 sprite, etc.). Allows inhands/worn sprites to be of any size, but still centered on a mob properly
	var/worn_x_dimension = 32
	///Dimensions of the icon file used when this item is worn, eg: hats.dmi (32x32 sprite, 64x64 sprite, etc.). Allows inhands/worn sprites to be of any size, but still centered on a mob properly
	var/worn_y_dimension = 32
	///Same as for [worn_x_dimension][/obj/item/var/worn_x_dimension] but for inhands, uses the lefthand_ and righthand_ file vars
	var/inhand_x_dimension = 32
	///Same as for [worn_y_dimension][/obj/item/var/worn_y_dimension] but for inhands, uses the lefthand_ and righthand_ file vars
	var/inhand_y_dimension = 32
	/// Worn overlay will be shifted by this along y axis
	var/worn_y_offset = 0

	max_integrity = 200

	obj_flags = NONE
	///Item flags for the item
	var/item_flags = NONE
	/// Temporary Style perk XP bonus left on the item after a styled action.
	var/cyberpunk_style_xp_bonus_until = 0
	/// Percent XP bonus granted while the temporary Style status is active.
	var/cyberpunk_style_xp_bonus = 0
	/// Name of the character whose style status is currently imprinted on the item.
	var/cyberpunk_style_status_owner

	///Sound played when you hit something with the item
	var/hitsound
	///Played when the item is used, for example tools
	var/usesound
	///Played when item is used for long progress
	var/operating_sound
	///Used when yate into a mob
	var/mob_throw_hit_sound
	///Sound used when equipping the item into a valid slot
	var/equip_sound
	///Sound uses when picking the item up (into your hands)
	var/pickup_sound
	///Sound uses when dropping the item, or when its thrown if a thrown sound isn't specified.
	var/drop_sound
	///Sound used on impact when the item is thrown.
	var/throw_drop_sound
	///Do the drop and pickup sounds vary?
	var/sound_vary = FALSE
	///Whether or not we use stealthy audio levels for this item's attack sounds
	var/stealthy_audio = FALSE
	///Sound which is produced when blocking an attack
	var/block_sound

	///How large is the object, used for stuff like whether it can fit in backpacks or not
	var/w_class = WEIGHT_CLASS_NORMAL
	///This is used to determine on which slots an item can fit.
	var/slot_flags = NONE
	pass_flags = PASSTABLE
	pressure_resistance = 4
	/// This var exists as a weird proxy "owner" ref
	/// It's used in a few places. Stop using it, and optimially replace all uses please
	var/obj/item/master = null

	///Price of an item in a vending machine, overriding the base vending machine price. Define in terms of paycheck defines as opposed to raw numbers.
	var/custom_price
	///Price of an item in a vending machine, overriding the premium vending machine price. Define in terms of paycheck defines as opposed to raw numbers.
	var/custom_premium_price
	/// Cyberpunk 13 item manufacturer. Existing subtypes that already expose corp_manufacturer are read through helper procs.
	var/cyberpunk_manufacturer = "independent"
	/// General execution quality. 100 is a normal factory-grade item.
	var/cyberpunk_quality = 100
	/// IC availability band used by shops, contracts, loot and black market systems.
	var/cyberpunk_rarity = "common"
	/// Legal status hook for future markets/security scans.
	var/cyberpunk_legality = "legal"
	/// Baseline economic price before vending overrides and local economy modifiers.
	var/cyberpunk_base_price = 0
	/// How much integrity this item loses when it is actively used.
	var/cyberpunk_active_wear = 0
	/// Passive wear applied by future storage/condition processors. Starts after five minutes from creation or repair.
	var/cyberpunk_passive_wear = 0
	/// Optional storage condition tags. A missing required condition lets passive wear systems tick this item down.
	var/list/cyberpunk_storage_conditions
	/// Integrity fraction needed before a broken item becomes functional again.
	var/cyberpunk_repair_threshold = 0.4
	/// What happens at zero integrity: "tg" keeps normal TG destruction, "broken" keeps the item, "delete" deletes, "emergency" lets subtypes provide behavior.
	var/cyberpunk_spoil_behavior = "tg"
	//CYBERPUNK BUILD - rebuild and delete before release
	/// Runtime broken flag for Cyberpunk item effects. Existing TG subtype-specific broken flags still work independently.
	var/cyberpunk_broken = FALSE
	/// Last time the item was created or repaired, used by passive wear systems.
	var/cyberpunk_last_repaired = 0
	/// Optional explicit inventory grid footprint. Null means derive from w_class.
	var/cyberpunk_grid_width
	var/cyberpunk_grid_height
	/// Current inventory-grid rotation metadata. Full 2D inventory will consume this later.
	var/cyberpunk_grid_rotated = FALSE
	/// Current 1-based position inside a Cyberpunk storage grid.
	var/cyberpunk_grid_x
	var/cyberpunk_grid_y
	/// Optional explicit weapon skill path. Null falls back to TG gun/sharpness/weight heuristics.
	var/cyberpunk_weapon_skill
	/// Guard value used by parry/block math. Null means derive from block chance and weight.
	var/cyberpunk_guard_value
	/// Cyberpunk damage profile weights. Keys: blunt, pierce, slash, heat, cold, acid.
	var/list/cyberpunk_damage_profile
	/// Melee profile table for stab/pierce/slash/chop style attacks. Values are assoc lists with force/penetration/cooldown.
	var/list/cyberpunk_melee_profiles
	/// Armor profile aliases for Cyberpunk damage names over TG armor flags.
	var/list/cyberpunk_armor_profile
	/// Installed Cyberpunk item module datums.
	var/list/datum/cyberpunk_item_module/cyberpunk_modules
	/// Modular equipment form id, for example vest, helmet, bracers or boots.
	var/cyberpunk_equipment_form
	/// Modular equipment material id. Used to rebuild protection, weight and module slots.
	var/cyberpunk_equipment_material
	/// Maximum module count by module slot id.
	var/list/cyberpunk_module_slots
	/// Base module slot count before material modifiers.
	var/list/cyberpunk_base_module_slots
	/// Initial armor ratings captured before modular equipment recalculation.
	var/list/cyberpunk_base_armor_values
	/// Initial item weight class captured before modular equipment recalculation.
	var/cyberpunk_base_w_class
	/// Initial item max integrity captured before modular equipment recalculation.
	var/cyberpunk_base_max_integrity
	/// Initial clothing slowdown captured before modular equipment recalculation.
	var/cyberpunk_base_slowdown
	/// Whether baseline modular stats were already captured.
	var/cyberpunk_modular_baseline_ready = FALSE
	/// Module datum paths installed during modular equipment setup.
	var/list/cyberpunk_initial_module_types
	/// Temporary armor bonuses from active Cyberpunk modules, keyed by installed module datum.
	var/list/cyberpunk_active_module_armor
	/// Temporary slowdown deltas from active Cyberpunk modules, keyed by installed module datum.
	var/list/cyberpunk_active_module_slowdown
	/// Modular weapon form id. Empty means this item is not a Cyberpunk weapon frame.
	var/cyberpunk_weapon_form
	/// Core material of a modular weapon frame.
	var/cyberpunk_weapon_material = "steel"
	/// Whether a modular weapon frame has been locked into a usable weapon.
	var/cyberpunk_weapon_assembled = TRUE
	/// Required module slots before the weapon can be assembled.
	var/list/cyberpunk_weapon_required_slots
	/// Baseline weapon stats captured before modular weapon recalculation.
	var/cyberpunk_base_force
	var/cyberpunk_base_throwforce
	var/cyberpunk_base_attack_speed
	var/cyberpunk_base_armour_penetration
	var/cyberpunk_base_fire_delay
	var/cyberpunk_base_spread
	var/cyberpunk_base_projectile_damage_multiplier
	var/cyberpunk_base_projectile_wound_bonus
	var/cyberpunk_base_projectile_speed_multiplier
	var/cyberpunk_base_accepted_magazine_type
	var/cyberpunk_base_spawn_magazine_type
	var/cyberpunk_base_ammo_type
	var/cyberpunk_base_caliber
	/// Whether baseline modular weapon stats were already captured.
	var/cyberpunk_weapon_baseline_ready = FALSE
	/// Reagent holder for one-shot melee coating.
	var/datum/reagents/cyberpunk_melee_coating
	/// Remaining successful hits that inject the coating.
	var/cyberpunk_melee_coating_charges = 0
	/// Extra burn damage applied by installed melee coating modules on successful hits.
	var/cyberpunk_melee_module_burn_damage = 0
	/// Extra stamina damage applied by installed melee coating modules on successful hits.
	var/cyberpunk_melee_module_stamina_damage = 0
	/// Chance for installed shock coating modules to stagger a living target on hit.
	var/cyberpunk_melee_module_shock_chance = 0
	/// Round-local contract id attached to this item as cargo evidence.
	var/cyberpunk_contract_id
	//CYBERPUNK BUILD - rebuild and delete before release
	///Whether spessmen with an ID with an age below AGE_MINOR (20 by default) can buy this item
	var/age_restricted = FALSE

	///flags which determine which body parts are protected from heat. [See here][HEAD]
	var/heat_protection = 0
	///flags which determine which body parts are protected from cold. [See here][HEAD]
	var/cold_protection = 0
	///Set this variable to determine up to which temperature (IN KELVIN) the item protects against heat damage. Keep at null to disable protection. Only protects areas set by heat_protection flags
	var/max_heat_protection_temperature
	///Set this variable to determine down to which temperature (IN KELVIN) the item protects against cold damage. 0 is NOT an acceptable number due to if(varname) tests!! Keep at null to disable protection. Only protects areas set by cold_protection flags
	var/min_cold_protection_temperature

	///list of /datum/action's that this item has.
	var/list/datum/action/actions
	///list of paths of action datums to give to the item on New().
	var/list/actions_types
	///Slot flags in which this item grants actions. If null, defaults to the item's slot flags (so actions are granted when worn)
	var/action_slots = null

	//Since any item can now be a piece of clothing, this has to be put here so all items share it.
	///This flag is used to determine when items in someone's inventory cover others. IE helmets making it so you can't see glasses, etc.
	var/flags_inv
	///you can see someone's mask through their transparent visor, but you can't reach it
	var/transparent_protection = NONE
	///Path of type /datum/hair_mask to apply to hair when this item is worn
	///Used by certain hats to give the appearance of squishing down tall hairstyles without hiding the hair completely
	var/hair_mask = null

	///flags for what should be done when you click on the item, default is picking it up
	var/interaction_flags_item = INTERACT_ITEM_ATTACK_HAND_PICKUP

	///What body parts are covered by the clothing when you wear it
	var/body_parts_covered = 0
	/// for electrical admittance/conductance (electrocution checks and shit)
	var/siemens_coefficient = 1
	/// How much clothing is slowing you down. Negative values speeds you up
	var/slowdown = 0
	///percentage of armour effectiveness to remove
	var/armour_penetration = 0
	///Whether or not our object doubles the value of affecting armour
	var/weak_against_armour = FALSE
	/// The click cooldown given after attacking. Lower numbers means faster attacks
	var/attack_speed = CLICK_CD_MELEE
	/// The click cooldown on secondary attacks. Lower numbers mean faster attacks. Will use attack_speed if undefined.
	var/secondary_attack_speed
	///In deciseconds, how long an item takes to equip; counts only for normal clothing slots, not pockets etc.
	var/equip_delay_self = 0 SECONDS
	///In deciseconds, how long an item takes to put on another person
	var/equip_delay_other = 2 SECONDS
	///In deciseconds, how long an item takes to remove from another person
	var/strip_delay = 4 SECONDS
	///How long it takes to resist out of the item (cuffs and such)
	var/breakouttime = 0

	///Used in [atom/proc/attackby] to say how something was attacked `"[x] has been [z.attack_verb] by [y] with [z]"`
	var/list/attack_verb_continuous
	var/list/attack_verb_simple
	///list() of species types, if a species cannot put items in a certain slot, but species type is in list, it will be able to wear that item
	var/list/species_exception = null
	///This is a bitfield that defines what variations exist for bodyparts like Digi legs. See: code\_DEFINES\inventory.dm
	var/supports_variations_flags = NONE

	///Items can by default thrown up to 10 tiles by TK users
	tk_throw_range = 10

	///the icon to indicate this object is being dragged
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	/// Does it embed and if yes, what kind of embed
	var/embed_type
	/// Stores embedding data
	VAR_PROTECTED/datum/embedding/embed_data

	///for flags such as [GLASSESCOVERSEYES]
	var/flags_cover = NONE
	var/heat = 0
	/// All items with sharpness of SHARP_EDGED or higher will automatically get the butchering component.
	var/sharpness = NONE

	///How a tool acts when you use it on something, such as wirecutters cutting wires while multitools measure power
	var/tool_behaviour = null

	///How fast does the tool work
	var/toolspeed = 1

	///Chance of blocking incoming attack
	var/block_chance = 0
	///Effect of blocking
	var/block_effect = /obj/effect/temp_visual/block
	var/hit_reaction_chance = 0 //If you want to have something unrelated to blocking/armour piercing etc. Maybe not needed, but trying to think ahead/allow more freedom
	///In tiles, how far this weapon can reach; 1 for adjacent, which is default
	var/reach = 1

	///The list of slots by priority. equip_to_appropriate_slot() uses this list. Doesn't matter if a mob type doesn't have a slot. For default list, see [/mob/proc/equip_to_appropriate_slot]
	var/list/slot_equipment_priority = null

	///Reference to the datum that determines whether dogs can wear the item: Needs to be in /obj/item because corgis can wear a lot of non-clothing items
	var/datum/dog_fashion/dog_fashion = null

	//Tooltip vars
	///string form of an item's force. Edit this var only to set a custom force string
	var/force_string
	var/last_force_string_check = 0
	var/tip_timer

	///Determines who can shoot this
	var/trigger_guard = TRIGGER_GUARD_NONE

	///Used as the dye color source in the washing machine only (at the moment). Can be a hex color or a key corresponding to a registry entry, see washing_machine.dm
	var/dye_color
	///Whether the item is unaffected by standard dying.
	var/undyeable = FALSE
	///What dye registry should be looked at when dying this item; see washing_machine.dm
	var/dying_key

	/// Used in obj/item/examine to give additional notes on what the weapon does, separate from the predetermined output variables
	var/offensive_notes
	/// Used in obj/item/examine to determines whether or not to detail an item's statistics even if it does not meet the force requirements
	var/override_notes = FALSE
	/// Used if we want to have a custom verb text for throwing. "John Spaceman flicks the ciggerate" for example.
	var/throw_verb

	/// A lazylist used for applying fantasy values, contains the actual modification applied to a variable.
	var/list/fantasy_modifications = null

	/// Do we apply a click cooldown when resisting this object if it is restraining them?
	var/resist_cooldown = CLICK_CD_BREAKOUT

/obj/item/Initialize(mapload)
	if(attack_verb_continuous)
		attack_verb_continuous = string_list(attack_verb_continuous)
	if(attack_verb_simple)
		attack_verb_simple = string_list(attack_verb_simple)
	if(species_exception)
		species_exception = string_list(species_exception)

	if(sharpness && force > 5) //give sharp objects butchering functionality, for consistency
		AddComponent(/datum/component/butchering, speed = 8 SECONDS * toolspeed)

	if(!greyscale_config && greyscale_colors && (greyscale_config_worn || greyscale_config_belt || greyscale_config_inhand_right || greyscale_config_inhand_left))
		update_greyscale()

	. = ..()
	cyberpunk_last_repaired = world.time

	// Handle adding item associated actions
	for(var/path in actions_types)
		add_item_action(path)
	actions_types = null

	if(force_string)
		item_flags |= FORCE_STRING_OVERRIDE

	if(!hitsound)
		if(damtype == BURN)
			hitsound = 'sound/items/tools/welder.ogg'
		if(damtype == BRUTE)
			hitsound = SFX_SWING_HIT

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_ITEM, src)

/obj/item/Destroy(force)
	// This var exists as a weird proxy "owner" ref
	// It's used in a few places. Stop using it, and optimially replace all uses please
	master = null
	if(ismob(loc))
		var/mob/m = loc
		m.temporarilyRemoveItemFromInventory(src, TRUE)

	// Handle cleaning up our actions list
	for(var/datum/action/action as anything in actions)
		remove_item_action(action)

	return ..()

/obj/item/click_ctrl(mob/user)
	SHOULD_NOT_OVERRIDE(TRUE)

	//If the item is on the ground & not anchored we allow the player to drag it
	. = item_ctrl_click(user)
	if(. & CLICK_ACTION_ANY)
		return (isturf(loc) && !anchored) ? NONE : . //allow the object to get dragged on the floor

/// Subtypes only override this proc for ctrl click purposes. obeys same principles as ctrl_click()
/obj/item/proc/item_ctrl_click(mob/user)
	SHOULD_CALL_PARENT(FALSE)
	return NONE

/// Called when an action associated with our item is deleted
/obj/item/proc/on_action_deleted(datum/source)
	SIGNAL_HANDLER

	if(!(source in actions))
		CRASH("An action ([source.type]) was deleted that was associated with an item ([src]), but was not found in the item's actions list.")

	LAZYREMOVE(actions, source)

/// Adds an item action to our list of item actions.
/// Item actions are actions linked to our item, that are granted to mobs who equip us.
/// This also ensures that the actions are properly tracked in the actions list and removed if they're deleted.
/// Can be be passed a typepath of an action or an instance of an action.
/obj/item/proc/add_item_action(action_or_action_type)

	var/datum/action/action
	if(ispath(action_or_action_type, /datum/action))
		action = new action_or_action_type(src)
	else if(istype(action_or_action_type, /datum/action))
		action = action_or_action_type
	else
		CRASH("item add_item_action got a type or instance of something that wasn't an action.")

	LAZYADD(actions, action)
	RegisterSignal(action, COMSIG_QDELETING, PROC_REF(on_action_deleted))
	grant_action_to_bearer(action)
	return action

/// Grant the action to anyone who has this item equipped to an appropriate slot
/obj/item/proc/grant_action_to_bearer(datum/action/action)
	if(!ismob(loc))
		return
	var/mob/holder = loc
	give_item_action(action, holder, holder.get_slot_by_item(src))

/// Removes an instance of an action from our list of item actions.
/obj/item/proc/remove_item_action(datum/action/action)
	if(!action)
		return

	UnregisterSignal(action, COMSIG_QDELETING)
	LAZYREMOVE(actions, action)
	qdel(action)

/// Called if this item is supposed to be a steal objective item objective.
/obj/item/proc/add_stealing_item_objective()
	return

/// Adds the weapon_description element, which shows the 'warning label' for especially dangerous objects. Override this for item types with special notes.
/obj/item/proc/add_weapon_description()
	AddElement(/datum/element/weapon_description)

/**
 * Checks if an item is allowed to be used on an atom/target
 * Returns TRUE if allowed.
 *
 * Args:
 * target_self - Whether we will check if we (src) are in target, preventing people from using items on themselves.
 * not_inside - Whether target (or target's loc) has to be a turf.
 */
/obj/item/proc/check_allowed_items(atom/target, not_inside = FALSE, target_self = FALSE)
	if(!target_self && (src in target))
		return FALSE
	if(not_inside && !isturf(target.loc) && !isturf(target))
		return FALSE
	return TRUE

/obj/item/blob_act(obj/structure/blob/B)
	if(B && B.loc == loc)
		atom_destruction(MELEE)

/**Makes cool stuff happen when you suicide with an item
 *
 *Outputs a creative message and then return the damagetype done
 * Arguments:
 * * user: The mob that is suiciding
 */
/obj/item/proc/suicide_act(mob/living/user)
	return

/obj/item/set_greyscale(list/colors, new_config, new_worn_config, new_inhand_left, new_inhand_right)
	if(new_worn_config)
		greyscale_config_worn = new_worn_config
	if(new_inhand_left)
		greyscale_config_inhand_left = new_inhand_left
	if(new_inhand_right)
		greyscale_config_inhand_right = new_inhand_right
	return ..()

/// Checks if this atom uses the GAGS system and if so updates the worn and inhand icons
/obj/item/update_greyscale()
	. = ..()
	if(!greyscale_colors)
		return
	if(greyscale_config_worn)
		worn_icon = SSgreyscale.GetColoredIconByType(greyscale_config_worn, greyscale_colors)
	if(greyscale_config_inhand_left)
		lefthand_file = SSgreyscale.GetColoredIconByType(greyscale_config_inhand_left, greyscale_colors)
	if(greyscale_config_inhand_right)
		righthand_file = SSgreyscale.GetColoredIconByType(greyscale_config_inhand_right, greyscale_colors)

/obj/item/verb/move_to_top()
	set name = "Move To Top"
	set category = null // BANDASTATION REPLACEMENT: Original: "Object"
	set src in oview(1)

	if(!isturf(loc) || usr.stat != CONSCIOUS || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED) || anchored)
		return

	if(isliving(usr))
		var/mob/living/L = usr
		if(!(L.mobility_flags & MOBILITY_PICKUP))
			return

	var/turf/T = loc
	abstract_move(null)
	forceMove(T)

/obj/item/examine_tags(mob/user)
	var/list/parent_tags = ..()
	parent_tags.Insert(1, weight_class_to_text(w_class)) // To make size display first, otherwise it looks goofy
	. = parent_tags
	.[weight_class_to_text(w_class)] = weight_class_to_tooltip(w_class)

	if(item_flags & CRUEL_IMPLEMENT)
		.[span_red("morbid")] = "It seems quite practical for particularly morbid procedures and experiments."

	if (siemens_coefficient == 0)
		.["изолирующий"] = "Предмет изготовлен из прочного изолятора и блокирует проходящее через него электричество!"
	else if (siemens_coefficient <= 0.5)
		.["частично изолирующий"] = "Предмет изготовлен из плохого изолятора, который гасит (но не полностью блокирует) проходящее через него электричество."

/obj/item/examine_descriptor(mob/user)
	return "предмет"

/obj/item/examine(mob/user)
	// lazily initialize the weapon description element if it hasn't been already
	if(!(item_flags & WEAPON_DESCRIPTION_INITIALIZED))
		add_weapon_description()
		item_flags |= WEAPON_DESCRIPTION_INITIALIZED
	return ..()

/obj/item/examine_more(mob/user)
	. = ..()
	var/list/cyberpunk_report = get_cyberpunk_item_report(user)
	if(length(cyberpunk_report))
		. += cyberpunk_report
	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER))
		. += research_scan(user)

/obj/item/proc/get_cyberpunk_item_report(mob/user)
	var/list/report = list()
	var/mob/living/living_user = user
	var/analysis_depth = istype(living_user) ? living_user.get_cyberpunk_item_analysis_depth(src) : 0
	if(analysis_depth <= 0 && !is_cyberpunk_recently_analyzed() && !cyberpunk_equipment_form)
		return report

	report += span_notice("Item condition: [get_cyberpunk_item_condition_name()].")
	var/item_manufacturer = get_cyberpunk_manufacturer()
	if(item_manufacturer && item_manufacturer != "independent")
		report += span_notice("Manufacturer: [item_manufacturer].")
	if(analysis_depth >= 1)
		report += span_notice("Quality: [cyberpunk_quality]%. Rarity: [cyberpunk_rarity].")
		var/list/footprint = get_cyberpunk_grid_footprint()
		report += span_notice("Inventory footprint: [footprint[1]]x[footprint[2]][cyberpunk_grid_rotated ? " rotated" : ""].")
	if(analysis_depth >= 2 && uses_integrity)
		report += span_notice("Integrity: [round(get_integrity())]/[max_integrity] ([round(get_integrity_percentage() * 100)]%). Repair threshold: [round(cyberpunk_repair_threshold * 100)]%.")
	if(analysis_depth >= 2 && (force || cyberpunk_guard_value || length(cyberpunk_damage_profile)))
		report += span_notice("Weapon profile: [get_cyberpunk_weapon_profile_name()]. Guard value: [get_cyberpunk_guard_value()].")
	if(cyberpunk_equipment_form)
		report += span_notice("Equipment form: [cyberpunk_equipment_form]. Material: [get_cyberpunk_equipment_material_name()].")
		var/list/module_report = get_cyberpunk_module_report()
		if(length(module_report))
			report += span_notice("Installed modules: [module_report.Join("; ")].")
		else
			report += span_notice("Installed modules: none.")
	if(cyberpunk_weapon_form)
		report += span_notice("Weapon frame: [cyberpunk_weapon_form]. Material: [get_cyberpunk_weapon_material_name()]. State: [cyberpunk_weapon_assembled ? "assembled" : "unassembled"].")
		var/list/missing_modules = get_missing_cyberpunk_weapon_modules()
		if(length(missing_modules))
			report += span_notice("Missing required modules: [missing_modules.Join(", ")].")
		var/list/module_report = get_cyberpunk_module_report()
		report += span_notice("Installed modules: [length(module_report) ? module_report.Join("; ") : "none"].")
		if(cyberpunk_melee_coating?.total_volume)
			report += span_notice("Chemical coating: [round(cyberpunk_melee_coating.total_volume)]u, [cyberpunk_melee_coating_charges] hit(s) left.")
	if(analysis_depth >= 3 || cyberpunk_equipment_form)
		var/list/armor_report = get_cyberpunk_armor_report()
		if(length(armor_report))
			report += span_notice("Protection: [armor_report.Join(", ")].")
		if(cyberpunk_active_wear || cyberpunk_passive_wear)
			report += span_notice("Wear: active [cyberpunk_active_wear], passive [cyberpunk_passive_wear].")
	return report

/obj/item/get_cyberpunk_diagnostic_data(mob/living/user)
	var/list/diagnostics = list()
	diagnostics += "Category: item."
	diagnostics += "Condition: [get_cyberpunk_item_condition_name()]."
	var/item_manufacturer = get_cyberpunk_manufacturer()
	if(item_manufacturer && item_manufacturer != "independent")
		diagnostics += "Manufacturer: [item_manufacturer]."
	diagnostics += "Quality: [cyberpunk_quality]%. Rarity: [cyberpunk_rarity]."
	if(uses_integrity)
		diagnostics += "Integrity: [round(get_integrity())]/[max_integrity] ([round(get_integrity_percentage() * 100)]%)."
	var/list/footprint = get_cyberpunk_grid_footprint()
	diagnostics += "Inventory footprint: [footprint[1]]x[footprint[2]][cyberpunk_grid_rotated ? " rotated" : ""]."
	if(force || cyberpunk_guard_value || length(cyberpunk_damage_profile))
		diagnostics += "Weapon profile: [get_cyberpunk_weapon_profile_name()]. Guard value: [get_cyberpunk_guard_value()]."
	if(cyberpunk_equipment_form)
		diagnostics += "Equipment form: [cyberpunk_equipment_form]. Material: [get_cyberpunk_equipment_material_name()]."
		var/list/module_report = get_cyberpunk_module_report()
		diagnostics += "Installed modules: [length(module_report) ? module_report.Join("; ") : "none"]."
	if(cyberpunk_weapon_form)
		diagnostics += "Weapon frame: [cyberpunk_weapon_form]. Material: [get_cyberpunk_weapon_material_name()]. State: [cyberpunk_weapon_assembled ? "assembled" : "unassembled"]."
		var/list/module_report = get_cyberpunk_module_report()
		diagnostics += "Installed modules: [length(module_report) ? module_report.Join("; ") : "none"]."
	var/list/armor_report = get_cyberpunk_armor_report()
	if(length(armor_report))
		diagnostics += "Protection: [armor_report.Join(", ")]."
	return diagnostics

/obj/item/proc/get_cyberpunk_item_condition_name()
	if(cyberpunk_broken || (uses_integrity && get_integrity() <= max(1, max_integrity * cyberpunk_repair_threshold)))
		return "broken"
	if(uses_integrity && get_integrity() < max_integrity)
		return "damaged"
	return "intact"

/obj/item/proc/get_cyberpunk_grid_footprint()
	var/grid_width = cyberpunk_grid_width
	var/grid_height = cyberpunk_grid_height
	if(!grid_width || !grid_height)
		switch(w_class)
			if(WEIGHT_CLASS_TINY)
				grid_width = 1
				grid_height = 1
			if(WEIGHT_CLASS_SMALL)
				grid_width = 1
				grid_height = 2
			if(WEIGHT_CLASS_NORMAL)
				grid_width = 2
				grid_height = 2
			if(WEIGHT_CLASS_BULKY)
				grid_width = 3
				grid_height = 4
			else
				grid_width = 4
				grid_height = 4
	if(cyberpunk_grid_rotated)
		return list(grid_height, grid_width)
	return list(grid_width, grid_height)

/obj/item/proc/rotate_cyberpunk_grid_footprint()
	cyberpunk_grid_rotated = !cyberpunk_grid_rotated
	return cyberpunk_grid_rotated

/obj/item/verb/rotate_cyberpunk_inventory_footprint()
	set name = "Rotate inventory footprint"
	set category = null
	set src in usr

	if(!(item_flags & IN_STORAGE))
		return
	rotate_cyberpunk_grid_footprint()
	cyberpunk_grid_x = null
	cyberpunk_grid_y = null
	var/datum/storage/storage = loc?.atom_storage
	if(storage)
		storage.reflow_cyberpunk_grid()
		storage.refresh_views()
	to_chat(usr, span_notice("You rotate [src]'s storage footprint."))

/obj/item/proc/set_cyberpunk_creator(mob/living/creator)
	if(!istype(creator))
		return
	var/manufacturer = creator.get_neural_manufacturer()
	if(manufacturer)
		set_cyberpunk_manufacturer(manufacturer)

/obj/item/proc/get_cyberpunk_manufacturer()
	if("corp_manufacturer" in vars)
		return vars["corp_manufacturer"] || "independent"
	return cyberpunk_manufacturer

/obj/item/proc/set_cyberpunk_manufacturer(manufacturer)
	if("corp_manufacturer" in vars)
		vars["corp_manufacturer"] = manufacturer
	else
		cyberpunk_manufacturer = manufacturer

/obj/item/proc/get_cyberpunk_synergy_multiplier(mob/living/user)
	if(!istype(user))
		return 1
	var/best_multiplier = user.get_corporate_synergy_multiplier(get_cyberpunk_manufacturer())
	for(var/datum/cyberpunk_item_module/module as anything in cyberpunk_modules)
		if(!module?.manufacturer || module.manufacturer == "independent")
			continue
		best_multiplier = max(best_multiplier, user.get_corporate_synergy_multiplier(module.manufacturer))
	return best_multiplier

/obj/item/proc/get_cyberpunk_base_effect_strength(mob/living/user, manufacturer_id)
	if(!istype(user) || !manufacturer_id)
		return 0
	var/normalized_manufacturer = cyberpunk_normalize_manufacturer_id(get_cyberpunk_manufacturer())
	if(normalized_manufacturer != manufacturer_id)
		return 0
	var/synergy = user.get_corporate_synergy_multiplier(normalized_manufacturer)
	if(synergy >= 1.09)
		return 1
	if(synergy >= 1.04)
		return 0.5
	return 0

/obj/item/proc/apply_cyberpunk_manufacturer_melee_pre(mob/living/user, list/modifiers, list/attack_modifiers)
	if(!istype(user))
		return
	var/sun_yon = get_cyberpunk_base_effect_strength(user, "sun_yon")
	if(sun_yon > 0)
		var/item_sharpness = get_sharpness()
		if(item_sharpness & (SHARP_POINTY|SHARP_EDGED))
			modifiers["cyberpunk_manufacturer_armor_penetration"] = (modifiers["cyberpunk_manufacturer_armor_penetration"] || 0) + round(8 * sun_yon)
	var/ishikawa = get_cyberpunk_base_effect_strength(user, "ishikawa")
	if(ishikawa > 0)
		attack_modifiers[SILENCE_HITSOUND] = TRUE
	var/tesla = get_cyberpunk_base_effect_strength(user, "tesla_science")
	if(tesla > 0)
		MODIFY_ATTACK_FORCE_MULTIPLIER(attack_modifiers, 1 + (0.1 * tesla))

/obj/item/proc/apply_cyberpunk_manufacturer_melee_post(mob/living/target, mob/living/user, damage_hint = 0)
	if(!istype(target) || !istype(user) || damage_hint <= 0)
		return FALSE
	var/applied = FALSE
	var/blackrock = get_cyberpunk_base_effect_strength(user, "blackrock_investigate")
	if(blackrock > 0)
		target.adjust_staggered_up_to(round(2 SECONDS * blackrock), 6 SECONDS)
		applied = TRUE
	var/samanthas = get_cyberpunk_base_effect_strength(user, "samanthas_keir")
	if(samanthas > 0)
		target.adjust_mood(-max(1, round(2 * samanthas)))
		applied = TRUE
	var/trans_travel = get_cyberpunk_base_effect_strength(user, "trans_travel")
	if(trans_travel > 0 && prob(20 * trans_travel))
		apply_cyberpunk_trans_travel_extra_melee(target, user, max(1, damage_hint * 0.35))
		applied = TRUE
	var/tyazhmarsh = get_cyberpunk_base_effect_strength(user, "tyazhmarsh")
	if(tyazhmarsh > 0)
		apply_cyberpunk_tyazhmarsh_melee_zone(target, user, max(1, damage_hint * 0.35))
		applied = TRUE
	return applied

/obj/item/proc/apply_cyberpunk_trans_travel_extra_melee(mob/living/target, mob/living/user, damage)
	var/mob/living/extra_target
	for(var/mob/living/nearby in orange(3, target))
		if(nearby == user || nearby == target || nearby.stat == DEAD)
			continue
		if(!extra_target || get_dist(target, nearby) < get_dist(target, extra_target))
			extra_target = nearby
	if(!extra_target)
		return FALSE
	var/zone = user.zone_selected || BODY_ZONE_CHEST
	extra_target.apply_damage(damage, damtype, zone, attacking_item = src, sharpness = get_sharpness(), brute_type = get_cyberpunk_damage_brute_type(null))
	user.visible_message(span_warning("[capitalize(src.declent_ru(NOMINATIVE))] catches [extra_target.declent_ru(ACCUSATIVE)] in a follow-through strike!"))
	return TRUE

/obj/item/proc/apply_cyberpunk_tyazhmarsh_melee_zone(mob/living/target, mob/living/user, damage)
	var/list/zone_targets = list()
	var/forward_dir = get_dir(user, target) || user.dir
	var/turf/forward_turf = get_step(target, forward_dir)
	for(var/mob/living/nearby in orange(3, target))
		if(nearby == user || nearby == target || nearby.stat == DEAD)
			continue
		if(get_turf(nearby) == forward_turf || get_dist(target, nearby) <= 1)
			zone_targets += nearby
	if(!length(zone_targets))
		return FALSE
	for(var/mob/living/zone_target as anything in zone_targets)
		zone_target.apply_damage(damage, damtype, user.zone_selected || BODY_ZONE_CHEST, attacking_item = src, sharpness = get_sharpness(), brute_type = get_cyberpunk_damage_brute_type(null))
	user.visible_message(span_warning("[capitalize(src.declent_ru(NOMINATIVE))] sweeps through nearby targets!"))
	return TRUE

/obj/item/proc/apply_cyberpunk_manufacturer_projectile_hit(mob/living/target, mob/living/user, obj/projectile/projectile, blocked = 0)
	if(!istype(target) || !istype(user) || !projectile)
		return FALSE
	var/applied = FALSE
	var/ishikawa = get_cyberpunk_base_effect_strength(user, "ishikawa")
	if(ishikawa > 0)
		projectile.cyberpunk_hide_wound_source = TRUE
		applied = TRUE
	var/tesla = get_cyberpunk_base_effect_strength(user, "tesla_science")
	if(tesla > 0)
		projectile.damage *= 1 + (0.1 * tesla)
		applied = TRUE
	var/sun_yon = get_cyberpunk_base_effect_strength(user, "sun_yon")
	if(sun_yon > 0)
		projectile.armour_penetration += round(5 * sun_yon)
		applied = TRUE
	var/kowalski = get_cyberpunk_base_effect_strength(user, "kowalski")
	if(kowalski > 0)
		projectile.wound_bonus += round(3 * kowalski)
		applied = TRUE
	var/blackrock = get_cyberpunk_base_effect_strength(user, "blackrock_investigate")
	if(blackrock > 0)
		target.adjust_staggered_up_to(round(2 SECONDS * blackrock), 6 SECONDS)
		applied = TRUE
	var/samanthas = get_cyberpunk_base_effect_strength(user, "samanthas_keir")
	if(samanthas > 0)
		target.adjust_mood(-max(1, round(2 * samanthas)))
		applied = TRUE
	var/tyazhmarsh = get_cyberpunk_base_effect_strength(user, "tyazhmarsh")
	if(tyazhmarsh > 0 && projectile.damage > 0)
		apply_cyberpunk_tyazhmarsh_projectile_aoe(target, user, projectile, tyazhmarsh)
		applied = TRUE
	var/trans_travel = get_cyberpunk_base_effect_strength(user, "trans_travel")
	if(trans_travel > 0 && projectile.damage > 0 && prob(20 * trans_travel))
		target.apply_damage(max(1, projectile.damage * 0.35), projectile.damage_type, projectile.def_zone || BODY_ZONE_CHEST, min(ARMOR_MAX_BLOCK, blocked), attacking_item = src, sharpness = projectile.sharpness)
		applied = TRUE
	return applied

/obj/item/proc/apply_cyberpunk_tyazhmarsh_projectile_aoe(mob/living/direct_target, mob/living/user, obj/projectile/projectile, effect_strength)
	var/turf/hit_turf = get_turf(direct_target)
	if(!hit_turf)
		return FALSE
	var/damage = max(1, round(projectile.damage * 0.35 * effect_strength))
	var/applied = FALSE
	for(var/mob/living/nearby in range(1, hit_turf))
		if(nearby == direct_target || nearby == user || nearby.stat == DEAD)
			continue
		if(nearby.has_cyberpunk_active_defense_manufacturer("tyazhmarsh"))
			to_chat(nearby, span_notice("Your Tyazhmarsh protection absorbs the blast wave."))
			continue
		nearby.apply_damage(damage, projectile.damage_type, BODY_ZONE_CHEST, spread_damage = TRUE, wound_bonus = CANT_WOUND, attacking_item = src, sharpness = projectile.sharpness)
		applied = TRUE
	if(applied)
		visible_message(span_warning("[capitalize(src.declent_ru(NOMINATIVE))]'s impact blooms into a short-radius blast!"))
	return applied

/mob/living/proc/get_cyberpunk_active_defense_effect_strength(manufacturer_id)
	if(!manufacturer_id)
		return 0
	var/list/slots_to_check = list(
		ITEM_SLOT_HEAD,
		ITEM_SLOT_EYES,
		ITEM_SLOT_MASK,
		ITEM_SLOT_NECK,
		ITEM_SLOT_OCLOTHING,
		ITEM_SLOT_ICLOTHING,
		ITEM_SLOT_GLOVES,
		ITEM_SLOT_BRACERS,
		ITEM_SLOT_FEET,
		ITEM_SLOT_PANTS,
		ITEM_SLOT_CHEST,
	)
	var/best_strength = 0
	for(var/slot_id in slots_to_check)
		var/obj/item/equipped = get_item_by_slot(slot_id)
		if(!equipped)
			continue
		best_strength = max(best_strength, equipped.get_cyberpunk_base_effect_strength(src, manufacturer_id))
	return best_strength

/mob/living/proc/has_cyberpunk_active_defense_manufacturer(manufacturer_id)
	return get_cyberpunk_active_defense_effect_strength(manufacturer_id) > 0

/mob/living/proc/get_cyberpunk_defense_armor_bonus(attack_flag)
	var/bonus = 0
	bonus += round(5 * get_cyberpunk_active_defense_effect_strength("sun_yon"))
	bonus += round(4 * get_cyberpunk_active_defense_effect_strength("ishikawa"))
	bonus += round(3 * get_cyberpunk_active_defense_effect_strength("ho_shi"))
	bonus += round(8 * get_cyberpunk_active_defense_effect_strength("kowalski"))
	bonus += round(5 * get_cyberpunk_active_defense_effect_strength("tesla_science"))
	bonus += round(4 * get_cyberpunk_active_defense_effect_strength("blackrock_investigate"))
	bonus += round(4 * get_cyberpunk_active_defense_effect_strength("samanthas_keir"))
	if(attack_flag == LASER || attack_flag == ENERGY)
		bonus += round(5 * get_cyberpunk_active_defense_effect_strength("tesla_science"))
	if(attack_flag == STAMINA)
		bonus += round(8 * get_cyberpunk_active_defense_effect_strength("blackrock_investigate"))
	return bonus

/mob/living/proc/get_cyberpunk_defense_damage_multiplier(damagetype)
	var/multiplier = 1
	var/sun_yon = get_cyberpunk_active_defense_effect_strength("sun_yon")
	if(sun_yon > 0)
		multiplier *= 1 - 0.04 * sun_yon
	var/ishikawa = get_cyberpunk_active_defense_effect_strength("ishikawa")
	if(ishikawa > 0 && (stealth_mode || chameleon > 0))
		multiplier *= 1 - 0.08 * ishikawa
	var/ho_shi = get_cyberpunk_active_defense_effect_strength("ho_shi")
	if(ho_shi > 0)
		multiplier *= 1 - 0.03 * ho_shi
	var/kowalski = get_cyberpunk_active_defense_effect_strength("kowalski")
	if(kowalski > 0)
		multiplier *= 1 - 0.06 * kowalski
	var/tesla = get_cyberpunk_active_defense_effect_strength("tesla_science")
	if(tesla > 0 && damagetype == BURN)
		multiplier *= 1 - 0.08 * tesla
	var/blackrock = get_cyberpunk_active_defense_effect_strength("blackrock_investigate")
	if(blackrock > 0 && damagetype == STAMINA)
		multiplier *= 1 - 0.12 * blackrock
	var/samanthas = get_cyberpunk_active_defense_effect_strength("samanthas_keir")
	if(samanthas > 0 && damagetype == BRAIN)
		multiplier *= 1 - 0.15 * samanthas
	return max(0.1, multiplier)

/mob/living/proc/try_cyberpunk_trans_travel_defense_teleport(atom/attacker)
	var/effect_strength = get_cyberpunk_active_defense_effect_strength("trans_travel")
	if(effect_strength <= 0 || world.time < cyberpunk_next_trans_travel_defense)
		return FALSE
	var/list/options = list()
	for(var/turf/open/open_turf in orange(4, src))
		if(open_turf.density || locate(/mob/living) in open_turf)
			continue
		options += open_turf
	if(!length(options))
		return FALSE
	cyberpunk_next_trans_travel_defense = world.time + 10 SECONDS
	var/turf/destination = pick(options)
	visible_message(span_warning("[capitalize(declent_ru(NOMINATIVE))]'s Trans Travel protection snaps [ru_p_them()] away from the hit!"))
	forceMove(destination)
	return TRUE

/obj/item/proc/get_cyberpunk_price(mob/living/buyer)
	var/base_price = cyberpunk_base_price || custom_price || 0
	if(base_price <= 0)
		base_price = max(1, w_class) * 10
	var/quality_multiplier = max(0.1, cyberpunk_quality * 0.01)
	var/condition_multiplier = 1
	if(cyberpunk_broken)
		condition_multiplier = 0.15
	else if(uses_integrity && max_integrity)
		condition_multiplier = clamp(get_integrity() / max_integrity, 0.15, 1)
	var/synergy_multiplier = get_cyberpunk_synergy_multiplier(buyer)
	return round(base_price * quality_multiplier * condition_multiplier * synergy_multiplier)

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

/obj/item/proc/select_cyberpunk_module(mob/user, active_only = FALSE)
	if(!length(cyberpunk_modules))
		return null
	if(length(cyberpunk_modules) == 1 && (!active_only || cyberpunk_modules[1]?.has_active_ability()))
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
	return get_cyberpunk_installed_module_count(module.module_slot) < slot_limit

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

/obj/item/proc/setup_cyberpunk_weapon(form_id, list/base_slots, list/required_slots, assembled = FALSE, material_id = "steel")
	cyberpunk_weapon_form = form_id
	cyberpunk_weapon_material = material_id || "steel"
	cyberpunk_weapon_assembled = assembled
	cyberpunk_base_module_slots = base_slots?.Copy() || list()
	cyberpunk_module_slots = cyberpunk_base_module_slots.Copy()
	cyberpunk_weapon_required_slots = required_slots?.Copy() || list()
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
	w_class = clamp(final_weight, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(uses_integrity)
		modify_max_integrity(max(1, final_integrity), FALSE)
	if(!isnull(final_slowdown) && ("slowdown" in vars))
		vars["slowdown"] = max(0, final_slowdown)

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
	return TRUE

/obj/item/proc/repair_cyberpunk_item(amount, mob/living/user)
	if(!uses_integrity)
		return 0
	. = repair_damage(amount)
	if(. > 0)
		cyberpunk_last_repaired = world.time
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
	LAZYADD(cyberpunk_modules, module)
	module.on_install(src, user)
	return TRUE

/obj/item/proc/remove_cyberpunk_module(datum/cyberpunk_item_module/module, mob/living/user)
	if(!(module in cyberpunk_modules))
		return FALSE
	clear_cyberpunk_module_active(module)
	LAZYREMOVE(cyberpunk_modules, module)
	module.on_remove(src, user)
	qdel(module)
	return TRUE

/obj/item/cyberpunk_item_module
	name = "item module"
	desc = "A modular Cyberpunk 13 item component. Use it on a weapon or protective item to install it."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "component"
	w_class = WEIGHT_CLASS_SMALL
	cyberpunk_manufacturer = "Starlight"
	var/module_datum_type = /datum/cyberpunk_item_module
	var/module_tier = 1
	var/module_variant = "standard"

/obj/item/cyberpunk_item_module/proc/get_module_variant_name()
	switch(module_variant)
		if("lightweight")
			return "Lightweight"
		if("reinforced")
			return "Reinforced"
		if("precision")
			return "Precision"
	return "Standard"

/obj/item/cyberpunk_item_module/proc/cycle_module_variant(mob/user)
	switch(module_variant)
		if("standard")
			module_variant = "lightweight"
		if("lightweight")
			module_variant = "reinforced"
		if("reinforced")
			module_variant = "precision"
		else
			module_variant = "standard"
	to_chat(user, span_notice("[src] variant set to [get_module_variant_name()]."))

/obj/item/cyberpunk_item_module/attack_self(mob/user, modifiers)
	cycle_module_variant(user)
	return TRUE

/obj/item/cyberpunk_item_module/proc/create_module_datum()
	var/datum/cyberpunk_item_module/module = new module_datum_type
	module.manufacturer = get_cyberpunk_manufacturer()
	module.module_tier = module_tier
	module.module_variant = module_variant
	module.apply_cyberpunk_module_variant()
	return module

/obj/item/cyberpunk_item_module/examine(mob/user)
	. = ..()
	var/datum/cyberpunk_item_module/module = new module_datum_type
	module.module_tier = module_tier
	module.module_variant = module_variant
	module.apply_cyberpunk_module_variant()
	. += span_notice("Manufacturer: [get_cyberpunk_manufacturer()].")
	. += span_notice("Tier: [module_tier]. Variant: [get_module_variant_name()]. Slot: [module.module_slot]. Effect scale: [round(module.get_effective_scale() * 100)]%.")
	. += span_notice("Use in hand before installation to cycle Standard, Lightweight, Reinforced and Precision variants.")
	if(module.has_active_ability())
		. += span_notice("Active ability: [module.active_ability_name]. [module.active_ability_description]")
	qdel(module)

/obj/item/cyberpunk_item_module/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/item/target_item = interacting_with
	if(!istype(target_item) || target_item == src)
		return NONE
	var/datum/cyberpunk_item_module/module = create_module_datum()
	var/install_delay = 2 SECONDS * (user ? user.get_cyberpunk_item_module_time_multiplier(target_item) : 1)
	if(!do_after(user, install_delay, target = target_item))
		qdel(module)
		return ITEM_INTERACT_BLOCKING
	if(!target_item.install_cyberpunk_module(module, user))
		if(target_item.is_cyberpunk_modular_weapon() && target_item.cyberpunk_weapon_assembled && !(module.module_slot in list("sight", "underbarrel")))
			to_chat(user, span_warning("Unlock [target_item]'s frame with a wrench on a table before changing its internal weapon modules."))
		else
			to_chat(user, span_warning("[name] does not fit into [target_item]."))
		qdel(module)
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You install [name] into [target_item]."))
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/cyberpunk_item_module/melee_core
	name = "melee core"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/melee_core

/obj/item/cyberpunk_item_module/melee_core/t2
	name = "melee core T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_core/t3
	name = "melee core T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_blade
	name = "blade element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_blade

/obj/item/cyberpunk_item_module/melee_blade/t2
	name = "blade element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_blade/t3
	name = "blade element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_knife_element
	name = "knife attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_knife_element

/obj/item/cyberpunk_item_module/melee_knife_element/t2
	name = "knife attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_knife_element/t3
	name = "knife attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_club_element
	name = "club attacking element"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/melee_club_element

/obj/item/cyberpunk_item_module/melee_club_element/t2
	name = "club attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_club_element/t3
	name = "club attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_twohand_sword_element
	name = "two-handed sword attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_twohand_sword_element

/obj/item/cyberpunk_item_module/melee_twohand_sword_element/t2
	name = "two-handed sword attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_twohand_sword_element/t3
	name = "two-handed sword attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_twohand_hammer_element
	name = "two-handed hammer attacking element"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/melee_twohand_hammer_element

/obj/item/cyberpunk_item_module/melee_twohand_hammer_element/t2
	name = "two-handed hammer attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_twohand_hammer_element/t3
	name = "two-handed hammer attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_axe_element
	name = "axe attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_axe_element

/obj/item/cyberpunk_item_module/melee_axe_element/t2
	name = "axe attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_axe_element/t3
	name = "axe attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_twohand_axe_element
	name = "two-handed axe attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_twohand_axe_element

/obj/item/cyberpunk_item_module/melee_twohand_axe_element/t2
	name = "two-handed axe attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_twohand_axe_element/t3
	name = "two-handed axe attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_rapier_element
	name = "rapier attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_rapier_element

/obj/item/cyberpunk_item_module/melee_rapier_element/t2
	name = "rapier attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_rapier_element/t3
	name = "rapier attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_spear_element
	name = "spear attacking element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_spear_element

/obj/item/cyberpunk_item_module/melee_spear_element/t2
	name = "spear attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_spear_element/t3
	name = "spear attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_staff_element
	name = "staff attacking element"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/melee_staff_element

/obj/item/cyberpunk_item_module/melee_staff_element/t2
	name = "staff attacking element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_staff_element/t3
	name = "staff attacking element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_spike
	name = "spike element"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/melee_spike

/obj/item/cyberpunk_item_module/melee_spike/t2
	name = "spike element T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_spike/t3
	name = "spike element T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/melee_head
	name = "weighted head"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/melee_head

/obj/item/cyberpunk_item_module/melee_head/t2
	name = "weighted head T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/melee_head/t3
	name = "weighted head T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/guard
	name = "weapon guard"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_item_module/guard

/obj/item/cyberpunk_item_module/guard/t2
	name = "weapon guard T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/guard/t3
	name = "weapon guard T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/balancer
	name = "weapon balancer"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/balancer

/obj/item/cyberpunk_item_module/balancer/t2
	name = "weapon balancer T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/balancer/t3
	name = "weapon balancer T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/shock_coating
	name = "shock weapon coating"
	icon_state = "capacitor"
	module_datum_type = /datum/cyberpunk_item_module/shock_coating

/obj/item/cyberpunk_item_module/shock_coating/t2
	name = "shock weapon coating T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/shock_coating/t3
	name = "shock weapon coating T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/thermal_coating
	name = "thermal weapon coating"
	icon_state = "capacitor"
	module_datum_type = /datum/cyberpunk_item_module/thermal_coating

/obj/item/cyberpunk_item_module/thermal_coating/t2
	name = "thermal weapon coating T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/thermal_coating/t3
	name = "thermal weapon coating T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/serrated_coating
	name = "serrated weapon coating"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/serrated_coating

/obj/item/cyberpunk_item_module/serrated_coating/t2
	name = "serrated weapon coating T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/serrated_coating/t3
	name = "serrated weapon coating T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/firearm_core
	name = "firearm core"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/firearm_core

/obj/item/cyberpunk_item_module/firearm_core/t2
	name = "firearm core T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/firearm_core/t3
	name = "firearm core T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/heavy_barrel
	name = "heavy barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/heavy_barrel

/obj/item/cyberpunk_item_module/heavy_barrel/t2
	name = "heavy barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/heavy_barrel/t3
	name = "heavy barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/long_barrel
	name = "long barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/long_barrel

/obj/item/cyberpunk_item_module/long_barrel/t2
	name = "long barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/long_barrel/t3
	name = "long barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/revolver_barrel
	name = "revolver barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/revolver_barrel

/obj/item/cyberpunk_item_module/revolver_barrel/t2
	name = "revolver barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/revolver_barrel/t3
	name = "revolver barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/pistol_barrel
	name = "pistol barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/pistol_barrel

/obj/item/cyberpunk_item_module/pistol_barrel/t2
	name = "pistol barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/pistol_barrel/t3
	name = "pistol barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/smg_barrel
	name = "SMG barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/smg_barrel

/obj/item/cyberpunk_item_module/smg_barrel/t2
	name = "SMG barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/smg_barrel/t3
	name = "SMG barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/rifle_barrel
	name = "rifle barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/rifle_barrel

/obj/item/cyberpunk_item_module/rifle_barrel/t2
	name = "rifle barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/rifle_barrel/t3
	name = "rifle barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/shotgun_barrel
	name = "shotgun barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/shotgun_barrel

/obj/item/cyberpunk_item_module/shotgun_barrel/t2
	name = "shotgun barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/shotgun_barrel/t3
	name = "shotgun barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/sniper_barrel
	name = "sniper barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/sniper_barrel

/obj/item/cyberpunk_item_module/sniper_barrel/t2
	name = "sniper barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/sniper_barrel/t3
	name = "sniper barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/assault_barrel
	name = "assault barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/assault_barrel

/obj/item/cyberpunk_item_module/assault_barrel/t2
	name = "assault barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/assault_barrel/t3
	name = "assault barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/lmg_barrel
	name = "machine gun barrel"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/lmg_barrel

/obj/item/cyberpunk_item_module/lmg_barrel/t2
	name = "machine gun barrel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/lmg_barrel/t3
	name = "machine gun barrel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/rocket_barrel
	name = "launcher tube"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/rocket_barrel

/obj/item/cyberpunk_item_module/rocket_barrel/t2
	name = "launcher tube T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/rocket_barrel/t3
	name = "launcher tube T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/cylinder_50
	name = ".50 revolver cylinder"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/cylinder_50

/obj/item/cyberpunk_item_module/cylinder_50/t2
	name = ".50 revolver cylinder T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/cylinder_50/t3
	name = ".50 revolver cylinder T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/cylinder_357
	name = ".357 revolver cylinder"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/cylinder_357

/obj/item/cyberpunk_item_module/cylinder_357/t2
	name = ".357 revolver cylinder T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/cylinder_357/t3
	name = ".357 revolver cylinder T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/pistol_magwell_9mm
	name = "9mm pistol magwell"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/pistol_magwell_9mm

/obj/item/cyberpunk_item_module/pistol_magwell_9mm/t2
	name = "9mm pistol magwell T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/pistol_magwell_9mm/t3
	name = "9mm pistol magwell T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/pistol_magwell_10mm
	name = "10mm pistol magwell"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/pistol_magwell_10mm

/obj/item/cyberpunk_item_module/pistol_magwell_10mm/t2
	name = "10mm pistol magwell T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/pistol_magwell_10mm/t3
	name = "10mm pistol magwell T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/smg_magwell_9mm
	name = "9mm SMG magwell"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/smg_magwell_9mm

/obj/item/cyberpunk_item_module/smg_magwell_9mm/t2
	name = "9mm SMG magwell T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/smg_magwell_9mm/t3
	name = "9mm SMG magwell T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/rifle_magwell_223
	name = ".223 rifle magwell"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/rifle_magwell_223

/obj/item/cyberpunk_item_module/rifle_magwell_223/t2
	name = ".223 rifle magwell T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/rifle_magwell_223/t3
	name = ".223 rifle magwell T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/shotgun_tube
	name = "shotgun tube"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/shotgun_tube

/obj/item/cyberpunk_item_module/shotgun_tube/t2
	name = "shotgun tube T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/shotgun_tube/t3
	name = "shotgun tube T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/sniper_chamber
	name = "sniper chamber"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/sniper_chamber

/obj/item/cyberpunk_item_module/sniper_chamber/t2
	name = "sniper chamber T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/sniper_chamber/t3
	name = "sniper chamber T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/assault_magwell_223
	name = ".223 assault magwell"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/assault_magwell_223

/obj/item/cyberpunk_item_module/assault_magwell_223/t2
	name = ".223 assault magwell T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/assault_magwell_223/t3
	name = ".223 assault magwell T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/lmg_feed_223
	name = ".223 belt feed"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/lmg_feed_223

/obj/item/cyberpunk_item_module/lmg_feed_223/t2
	name = ".223 belt feed T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/lmg_feed_223/t3
	name = ".223 belt feed T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/rocket_tube
	name = "rocket launch tube"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/rocket_tube

/obj/item/cyberpunk_item_module/rocket_tube/t2
	name = "rocket launch tube T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/rocket_tube/t3
	name = "rocket launch tube T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/laser_emitter
	name = "laser emitter"
	icon_state = "power_mod"
	module_datum_type = /datum/cyberpunk_item_module/laser_emitter

/obj/item/cyberpunk_item_module/laser_emitter/t2
	name = "laser emitter T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/laser_emitter/t3
	name = "laser emitter T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/plasma_emitter
	name = "plasma emitter"
	icon_state = "power_mod"
	module_datum_type = /datum/cyberpunk_item_module/plasma_emitter

/obj/item/cyberpunk_item_module/plasma_emitter/t2
	name = "plasma emitter T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/plasma_emitter/t3
	name = "plasma emitter T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/precision_receiver
	name = "precision receiver"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_item_module/precision_receiver

/obj/item/cyberpunk_item_module/precision_receiver/t2
	name = "precision receiver T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/precision_receiver/t3
	name = "precision receiver T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/damage_trigger
	name = "overpressure trigger"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/damage_trigger

/obj/item/cyberpunk_item_module/damage_trigger/t2
	name = "overpressure trigger T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/damage_trigger/t3
	name = "overpressure trigger T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/speed_trigger
	name = "short-reset trigger"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/speed_trigger

/obj/item/cyberpunk_item_module/speed_trigger/t2
	name = "short-reset trigger T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/speed_trigger/t3
	name = "short-reset trigger T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/reflex_sight
	name = "reflex sight"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_item_module/reflex_sight

/obj/item/cyberpunk_item_module/reflex_sight/t2
	name = "reflex sight T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/reflex_sight/t3
	name = "reflex sight T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/tactical_light
	name = "tactical light"
	icon_state = "power_mod"
	module_datum_type = /datum/cyberpunk_item_module/tactical_light

/obj/item/cyberpunk_item_module/tactical_light/t2
	name = "tactical light T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/tactical_light/t3
	name = "tactical light T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/armor_plate
	name = "armor plate"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/armor_plate

/obj/item/cyberpunk_item_module/armor_plate/t2
	name = "armor plate T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/armor_plate/t3
	name = "armor plate T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/armor_lining
	name = "protective lining"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/armor_lining

/obj/item/cyberpunk_item_module/armor_lining/t2
	name = "protective lining T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/armor_lining/t3
	name = "protective lining T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/weight_reducer
	name = "lightweight frame"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/weight_reducer

/obj/item/cyberpunk_item_module/weight_reducer/t2
	name = "lightweight frame T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/weight_reducer/t3
	name = "lightweight frame T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/mobility_servo
	name = "mobility servo"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/mobility_servo

/obj/item/cyberpunk_item_module/mobility_servo/t2
	name = "mobility servo T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/mobility_servo/t3
	name = "mobility servo T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/reactive_hardener
	name = "reactive hardener"
	icon_state = "circuit_board"
	module_datum_type = /datum/cyberpunk_item_module/reactive_hardener

/obj/item/cyberpunk_item_module/reactive_hardener/t2
	name = "reactive hardener T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/reactive_hardener/t3
	name = "reactive hardener T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/impact_gel
	name = "impact gel"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/impact_gel

/obj/item/cyberpunk_item_module/impact_gel/t2
	name = "impact gel T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/impact_gel/t3
	name = "impact gel T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/ballistic_weave
	name = "ballistic weave"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/ballistic_weave

/obj/item/cyberpunk_item_module/ballistic_weave/t2
	name = "ballistic weave T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/ballistic_weave/t3
	name = "ballistic weave T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/ablative_mesh
	name = "ablative mesh"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/ablative_mesh

/obj/item/cyberpunk_item_module/ablative_mesh/t2
	name = "ablative mesh T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/ablative_mesh/t3
	name = "ablative mesh T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/insulation_lining
	name = "insulation lining"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/insulation_lining

/obj/item/cyberpunk_item_module/insulation_lining/t2
	name = "insulation lining T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/insulation_lining/t3
	name = "insulation lining T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/chemseal_lining
	name = "chemseal lining"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/chemseal_lining

/obj/item/cyberpunk_item_module/chemseal_lining/t2
	name = "chemseal lining T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/chemseal_lining/t3
	name = "chemseal lining T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/sensor_bus
	name = "sensor bus"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/sensor_bus

/obj/item/cyberpunk_item_module/sensor_bus/t2
	name = "sensor bus T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/sensor_bus/t3
	name = "sensor bus T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/blast_padding
	name = "blast padding"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/blast_padding

/obj/item/cyberpunk_item_module/blast_padding/t2
	name = "blast padding T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/blast_padding/t3
	name = "blast padding T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/trauma_mesh
	name = "trauma mesh"
	icon_state = "component"
	module_datum_type = /datum/cyberpunk_item_module/trauma_mesh

/obj/item/cyberpunk_item_module/trauma_mesh/t2
	name = "trauma mesh T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/trauma_mesh/t3
	name = "trauma mesh T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/deflection_laminate
	name = "deflection laminate"
	icon_state = "cell_con"
	module_datum_type = /datum/cyberpunk_item_module/deflection_laminate

/obj/item/cyberpunk_item_module/deflection_laminate/t2
	name = "deflection laminate T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/deflection_laminate/t3
	name = "deflection laminate T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/grounding_bus
	name = "grounding bus"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/grounding_bus

/obj/item/cyberpunk_item_module/grounding_bus/t2
	name = "grounding bus T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/grounding_bus/t3
	name = "grounding bus T3"
	module_tier = 3

/obj/item/cyberpunk_item_module/medfoam_injector
	name = "medfoam injector"
	icon_state = "integrated_circuit"
	module_datum_type = /datum/cyberpunk_item_module/medfoam_injector

/obj/item/cyberpunk_item_module/medfoam_injector/t2
	name = "medfoam injector T2"
	module_tier = 2

/obj/item/cyberpunk_item_module/medfoam_injector/t3
	name = "medfoam injector T3"
	module_tier = 3

/obj/item/ammo_box/magazine/internal/cylinder/cyberpunk_50
	name = ".50 revolver cylinder"
	ammo_type = /obj/item/ammo_casing/a50ae
	caliber = CALIBER_50AE
	max_ammo = 5

/datum/cyberpunk_item_module
	var/name = "item module"
	var/manufacturer = "independent"
	var/quality = 100
	var/module_slot = "utility"
	var/module_tier = 1
	var/weight_delta = 0
	var/integrity_delta = 0
	var/slowdown_delta = 0
	var/force_multiplier = 1
	var/attack_speed_multiplier = 1
	var/armour_penetration_delta = 0
	var/guard_delta = 0
	var/list/armor_delta
	var/applied_weight_delta = 0
	var/applied_integrity_delta = 0
	var/applied_force_multiplier = 1
	var/applied_attack_speed_multiplier = 1
	var/applied_armour_penetration_delta = 0
	var/applied_guard_delta = 0
	var/list/previous_damage_profile
	var/active_ability_name
	var/active_ability_description
	var/active_cooldown = 30 SECONDS
	var/active_duration = 8 SECONDS
	var/list/active_armor_delta
	var/active_slowdown_delta = 0
	var/active_stamina_restore = 0
	var/active_brute_heal = 0
	var/active_burn_heal = 0
	var/active_extinguish = FALSE
	var/active_next_use = 0
	var/gun_spread_delta = 0
	var/gun_fire_delay_multiplier = 1
	var/gun_projectile_damage_multiplier_delta = 0
	var/gun_projectile_wound_bonus_delta = 0
	var/gun_projectile_speed_multiplier_delta = 0
	var/gun_magazine_type
	var/gun_ammo_type
	var/list/gun_energy_ammo_types
	var/gun_caliber
	var/weapon_form_override
	var/list/allowed_weapon_forms
	var/list/melee_damage_profile
	var/melee_stamina_damage_delta = 0
	var/melee_burn_damage_delta = 0
	var/melee_shock_chance_delta = 0
	var/module_variant = "standard"

/datum/cyberpunk_item_module/proc/get_effective_scale()
	return 1 + max(0, module_tier - 1) * 0.15

/datum/cyberpunk_item_module/proc/apply_cyberpunk_module_variant()
	switch(module_variant)
		if("lightweight")
			weight_delta -= 1
			integrity_delta -= 5
			force_multiplier = 1 + ((force_multiplier - 1) * 0.85)
			attack_speed_multiplier *= 0.92
			gun_fire_delay_multiplier *= 0.92
			gun_spread_delta += 1
			fit_armor_delta_modifier(-2)
			if(active_cooldown)
				active_cooldown = round(active_cooldown * 0.9)
		if("reinforced")
			weight_delta += 1
			integrity_delta += 20
			force_multiplier *= 1.06
			attack_speed_multiplier *= 1.08
			gun_fire_delay_multiplier *= 1.08
			guard_delta += 5
			melee_stamina_damage_delta += 2
			fit_armor_delta_modifier(3)
			if(active_duration)
				active_duration = round(active_duration * 1.15)
		if("precision")
			armour_penetration_delta += 4
			gun_spread_delta -= 4
			gun_projectile_speed_multiplier_delta += 0.05
			guard_delta += 2
			force_multiplier *= 0.98
			gun_fire_delay_multiplier *= 1.03
			melee_shock_chance_delta += 4

/datum/cyberpunk_item_module/proc/fit_armor_delta_modifier(amount)
	if(!amount)
		return
	if(!length(armor_delta))
		if(module_slot in list("plate", "lining", "shell", "visor", "guard"))
			armor_delta = list(MELEE = amount, BULLET = amount, LASER = amount)
		return
	for(var/armor_key in armor_delta)
		armor_delta[armor_key] += amount

/datum/cyberpunk_item_module/proc/has_active_ability()
	return !!active_ability_name

/datum/cyberpunk_item_module/proc/get_active_cooldown()
	return max(1 SECONDS, round(active_cooldown / get_effective_scale()))

/datum/cyberpunk_item_module/proc/get_active_duration()
	return max(1 SECONDS, round(active_duration * get_effective_scale()))

/datum/cyberpunk_item_module/proc/activate(obj/item/equipment, mob/living/user)
	if(!has_active_ability() || !equipment || !user)
		return FALSE
	if(world.time < active_next_use)
		to_chat(user, span_warning("[active_ability_name] is recharging for [DisplayTimeText(active_next_use - world.time, round_seconds_to = 1)]."))
		return FALSE
	if(!(equipment in user.get_all_contents()))
		to_chat(user, span_warning("You need to wear or hold [equipment] to activate [active_ability_name]."))
		return FALSE
	var/effect_scale = get_effective_scale()
	var/list/scaled_armor = list()
	for(var/armor_key in active_armor_delta)
		scaled_armor[armor_key] = round(active_armor_delta[armor_key] * effect_scale)
	var/scaled_slowdown = active_slowdown_delta ? active_slowdown_delta * effect_scale : 0
	if(length(scaled_armor) || scaled_slowdown)
		equipment.add_cyberpunk_module_active(src, scaled_armor, scaled_slowdown, get_active_duration())
	if(active_stamina_restore)
		user.adjust_stamina_loss(-round(active_stamina_restore * effect_scale), forced = TRUE)
	if(active_brute_heal)
		user.adjust_brute_loss(-round(active_brute_heal * effect_scale), forced = TRUE)
	if(active_burn_heal)
		user.adjust_fire_loss(-round(active_burn_heal * effect_scale), forced = TRUE)
	if(active_extinguish)
		user.extinguish_mob()
		user.adjust_fire_stacks(-round(4 * effect_scale))
	active_next_use = world.time + get_active_cooldown()
	user.visible_message(span_notice("[user] activates [active_ability_name] on [equipment]."), span_notice("You activate [active_ability_name] on [equipment]. [active_ability_description]"))
	return TRUE

/datum/cyberpunk_item_module/proc/can_install(obj/item/target, mob/living/user)
	if(length(allowed_weapon_forms) && target?.cyberpunk_weapon_form && !(target.get_cyberpunk_effective_weapon_form() in allowed_weapon_forms))
		return FALSE
	return istype(target) && target.can_accept_cyberpunk_module(src)

/datum/cyberpunk_item_module/proc/apply_weapon_stats(obj/item/target)
	if(!target)
		return
	var/effect_scale = get_effective_scale()
	if(weight_delta)
		target.w_class = clamp(target.w_class + round(weight_delta * effect_scale), WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(force_multiplier != 1)
		target.force *= 1 + ((force_multiplier - 1) * effect_scale)
	if(attack_speed_multiplier != 1)
		target.attack_speed *= 1 + ((attack_speed_multiplier - 1) * effect_scale)
	if(armour_penetration_delta)
		target.armour_penetration += round(armour_penetration_delta * effect_scale)
	if(guard_delta)
		target.cyberpunk_guard_value = target.get_cyberpunk_guard_value() + round(guard_delta * effect_scale)
	if(length(melee_damage_profile))
		target.cyberpunk_damage_profile = melee_damage_profile.Copy()
	if(melee_stamina_damage_delta)
		target.cyberpunk_melee_module_stamina_damage += round(melee_stamina_damage_delta * effect_scale)
	if(melee_burn_damage_delta)
		target.cyberpunk_melee_module_burn_damage += round(melee_burn_damage_delta * effect_scale)
	if(melee_shock_chance_delta)
		target.cyberpunk_melee_module_shock_chance += round(melee_shock_chance_delta * effect_scale)
	var/obj/item/gun/gun = target
	if(istype(gun))
		if(gun_spread_delta)
			gun.spread = max(0, gun.spread + round(gun_spread_delta * effect_scale))
		if(gun_fire_delay_multiplier != 1)
			gun.fire_delay = max(0, round(gun.fire_delay * (1 + ((gun_fire_delay_multiplier - 1) * effect_scale))))
		if(gun_projectile_damage_multiplier_delta)
			gun.projectile_damage_multiplier += gun_projectile_damage_multiplier_delta * effect_scale
		if(gun_projectile_wound_bonus_delta)
			gun.projectile_wound_bonus += round(gun_projectile_wound_bonus_delta * effect_scale)
		if(gun_projectile_speed_multiplier_delta)
			gun.projectile_speed_multiplier += gun_projectile_speed_multiplier_delta * effect_scale
		if(gun_magazine_type && ("accepted_magazine_type" in gun.vars))
			gun.vars["accepted_magazine_type"] = gun_magazine_type
		if(gun_magazine_type && ("spawn_magazine_type" in gun.vars))
			gun.vars["spawn_magazine_type"] = gun_magazine_type
		if(gun_ammo_type && ("ammo_type" in gun.vars))
			gun.vars["ammo_type"] = gun_ammo_type
		if(length(gun_energy_ammo_types) && ("ammo_type" in gun.vars))
			gun.vars["ammo_type"] = gun_energy_ammo_types.Copy()
		if(gun_caliber && ("caliber" in gun.vars))
			gun.vars["caliber"] = gun_caliber
		var/obj/item/gun/energy/energy_gun = target
		if(istype(energy_gun) && length(gun_energy_ammo_types))
			energy_gun.select = 1
			energy_gun.update_ammo_types()
			energy_gun.recharge_newshot(TRUE)
			energy_gun.update_appearance()

/datum/cyberpunk_item_module/proc/on_install(obj/item/target, mob/living/user)
	if(!target)
		return
	target.cyberpunk_quality = max(target.cyberpunk_quality, quality)
	if(target.cyberpunk_equipment_form)
		target.recalculate_cyberpunk_equipment_stats()
		return
	if(target.cyberpunk_weapon_form)
		target.recalculate_cyberpunk_weapon_stats()
		return
	var/effect_scale = get_effective_scale()
	if(weight_delta)
		applied_weight_delta = round(weight_delta * effect_scale)
		target.w_class = clamp(target.w_class + applied_weight_delta, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(integrity_delta && target.uses_integrity)
		applied_integrity_delta = round(integrity_delta * effect_scale)
		target.modify_max_integrity(max(1, target.max_integrity + applied_integrity_delta), FALSE)
	if(force_multiplier != 1)
		applied_force_multiplier = 1 + ((force_multiplier - 1) * effect_scale)
		target.force *= applied_force_multiplier
	if(attack_speed_multiplier != 1)
		applied_attack_speed_multiplier = 1 + ((attack_speed_multiplier - 1) * effect_scale)
		target.attack_speed *= applied_attack_speed_multiplier
	if(armour_penetration_delta)
		applied_armour_penetration_delta = round(armour_penetration_delta * effect_scale)
		target.armour_penetration += applied_armour_penetration_delta
	if(guard_delta)
		applied_guard_delta = round(guard_delta * effect_scale)
		target.cyberpunk_guard_value = target.get_cyberpunk_guard_value() + applied_guard_delta
	if(length(armor_delta))
		var/datum/armor/current_armor = target.get_armor()
		var/list/scaled_armor_delta = list()
		for(var/armor_key in armor_delta)
			scaled_armor_delta[armor_key] = round(armor_delta[armor_key] * effect_scale)
		target.set_armor(current_armor.generate_new_with_modifiers(scaled_armor_delta))

/datum/cyberpunk_item_module/proc/on_remove(obj/item/target, mob/living/user)
	if(!target)
		return
	if(target.cyberpunk_equipment_form)
		target.recalculate_cyberpunk_equipment_stats()
		return
	if(target.cyberpunk_weapon_form)
		target.recalculate_cyberpunk_weapon_stats()
		return
	if(applied_weight_delta)
		target.w_class = clamp(target.w_class - applied_weight_delta, WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(applied_integrity_delta && target.uses_integrity)
		target.modify_max_integrity(max(1, target.max_integrity - applied_integrity_delta), FALSE)
	if(applied_force_multiplier != 1)
		target.force /= applied_force_multiplier
	if(applied_attack_speed_multiplier != 1)
		target.attack_speed /= applied_attack_speed_multiplier
	if(applied_armour_penetration_delta)
		target.armour_penetration -= applied_armour_penetration_delta
	if(applied_guard_delta)
		target.cyberpunk_guard_value = max(0, target.get_cyberpunk_guard_value() - applied_guard_delta)
	if(length(armor_delta))
		var/datum/armor/current_armor = target.get_armor()
		var/list/inverse_armor_delta = list()
		for(var/armor_key in armor_delta)
			inverse_armor_delta[armor_key] = -armor_delta[armor_key]
		target.set_armor(current_armor.generate_new_with_modifiers(inverse_armor_delta))

/datum/cyberpunk_item_module/melee_core
	name = "melee core"
	module_slot = "core"
	integrity_delta = 20

/datum/cyberpunk_item_module/melee_core/t2
	name = "melee core T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_core/t3
	name = "melee core T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_blade
	name = "blade element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "twohand_sword", "axe", "twohand_axe")
	weapon_form_override = "knife"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 1)
	force_multiplier = 1.15
	armour_penetration_delta = 5

/datum/cyberpunk_item_module/melee_blade/t2
	name = "blade element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_blade/t3
	name = "blade element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_blade/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_blade/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_spike
	name = "spike element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "rapier", "spear")
	weapon_form_override = "rapier"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 1)
	force_multiplier = 1.05
	armour_penetration_delta = 10

/datum/cyberpunk_item_module/melee_spike/t2
	name = "spike element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_spike/t3
	name = "spike element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_spike/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_spike/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_head
	name = "weighted head"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "club", "twohand_hammer", "staff")
	weapon_form_override = "club"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.2
	attack_speed_multiplier = 1.1

/datum/cyberpunk_item_module/melee_head/t2
	name = "weighted head T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_head/t3
	name = "weighted head T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_head/on_install(obj/item/target, mob/living/user)
	previous_damage_profile = target.cyberpunk_damage_profile?.Copy()
	. = ..()
	target.cyberpunk_damage_profile = melee_damage_profile.Copy()

/datum/cyberpunk_item_module/melee_head/on_remove(obj/item/target, mob/living/user)
	. = ..()
	target.cyberpunk_damage_profile = previous_damage_profile?.Copy()

/datum/cyberpunk_item_module/melee_knife_element
	name = "knife attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife")
	weapon_form_override = "knife"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.65, BODYPART_DAMAGE_PIERCE = 0.35)
	force_multiplier = 1.08
	attack_speed_multiplier = 0.9
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/melee_knife_element/t2
	name = "knife attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_knife_element/t3
	name = "knife attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_club_element
	name = "club attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "club")
	weapon_form_override = "club"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.2
	attack_speed_multiplier = 1.08
	guard_delta = 6

/datum/cyberpunk_item_module/melee_club_element/t2
	name = "club attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_club_element/t3
	name = "club attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_sword_element
	name = "two-handed sword attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_sword")
	weapon_form_override = "twohand_sword"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.75, BODYPART_DAMAGE_PIERCE = 0.25)
	weight_delta = 2
	force_multiplier = 1.35
	attack_speed_multiplier = 1.18
	armour_penetration_delta = 8
	guard_delta = 12

/datum/cyberpunk_item_module/melee_twohand_sword_element/t2
	name = "two-handed sword attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_sword_element/t3
	name = "two-handed sword attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_hammer_element
	name = "two-handed hammer attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_hammer")
	weapon_form_override = "twohand_hammer"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 3
	force_multiplier = 1.55
	attack_speed_multiplier = 1.35
	armour_penetration_delta = 12
	guard_delta = 8

/datum/cyberpunk_item_module/melee_twohand_hammer_element/t2
	name = "two-handed hammer attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_hammer_element/t3
	name = "two-handed hammer attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_axe_element
	name = "axe attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "axe")
	weapon_form_override = "axe"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.85, BODYPART_DAMAGE_BLUNT = 0.15)
	weight_delta = 1
	force_multiplier = 1.25
	attack_speed_multiplier = 1.1
	armour_penetration_delta = 6

/datum/cyberpunk_item_module/melee_axe_element/t2
	name = "axe attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_axe_element/t3
	name = "axe attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_twohand_axe_element
	name = "two-handed axe attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "twohand_axe")
	weapon_form_override = "twohand_axe"
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.8, BODYPART_DAMAGE_BLUNT = 0.2)
	weight_delta = 3
	force_multiplier = 1.48
	attack_speed_multiplier = 1.3
	armour_penetration_delta = 10
	guard_delta = 6

/datum/cyberpunk_item_module/melee_twohand_axe_element/t2
	name = "two-handed axe attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_twohand_axe_element/t3
	name = "two-handed axe attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_rapier_element
	name = "rapier attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "rapier")
	weapon_form_override = "rapier"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 0.9, BODYPART_DAMAGE_SLASH = 0.1)
	force_multiplier = 1.02
	attack_speed_multiplier = 0.85
	armour_penetration_delta = 14
	guard_delta = 5

/datum/cyberpunk_item_module/melee_rapier_element/t2
	name = "rapier attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_rapier_element/t3
	name = "rapier attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_spear_element
	name = "spear attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "spear")
	weapon_form_override = "spear"
	melee_damage_profile = list(BODYPART_DAMAGE_PIERCE = 0.75, BODYPART_DAMAGE_BLUNT = 0.25)
	weight_delta = 2
	force_multiplier = 1.22
	attack_speed_multiplier = 1.05
	armour_penetration_delta = 12
	guard_delta = 10

/datum/cyberpunk_item_module/melee_spear_element/t2
	name = "spear attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_spear_element/t3
	name = "spear attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/melee_staff_element
	name = "staff attacking element"
	module_slot = "element"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "staff")
	weapon_form_override = "staff"
	melee_damage_profile = list(BODYPART_DAMAGE_BLUNT = 1)
	weight_delta = 1
	force_multiplier = 1.12
	attack_speed_multiplier = 0.95
	guard_delta = 18

/datum/cyberpunk_item_module/melee_staff_element/t2
	name = "staff attacking element T2"
	module_tier = 2

/datum/cyberpunk_item_module/melee_staff_element/t3
	name = "staff attacking element T3"
	module_tier = 3

/datum/cyberpunk_item_module/guard
	name = "guard"
	module_slot = "guard"
	guard_delta = 15
	weight_delta = 1

/datum/cyberpunk_item_module/guard/t2
	name = "guard T2"
	module_tier = 2

/datum/cyberpunk_item_module/guard/t3
	name = "guard T3"
	module_tier = 3

/datum/cyberpunk_item_module/balancer
	name = "balancer"
	module_slot = "balance"
	attack_speed_multiplier = 0.9
	guard_delta = 5

/datum/cyberpunk_item_module/balancer/t2
	name = "balancer T2"
	module_tier = 2

/datum/cyberpunk_item_module/balancer/t3
	name = "balancer T3"
	module_tier = 3

/datum/cyberpunk_item_module/shock_coating
	name = "shock weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "club", "twohand_sword", "twohand_hammer", "axe", "twohand_axe", "rapier", "spear", "staff")
	melee_stamina_damage_delta = 8
	melee_shock_chance_delta = 18
	armour_penetration_delta = 2

/datum/cyberpunk_item_module/shock_coating/t2
	name = "shock weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/shock_coating/t3
	name = "shock weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/thermal_coating
	name = "thermal weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "club", "twohand_sword", "twohand_hammer", "axe", "twohand_axe", "rapier", "spear", "staff")
	melee_damage_profile = list(BODYPART_DAMAGE_HEAT = 0.35, BODYPART_DAMAGE_SLASH = 0.65)
	melee_burn_damage_delta = 4
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/thermal_coating/t2
	name = "thermal weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/thermal_coating/t3
	name = "thermal weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/serrated_coating
	name = "serrated weapon coating"
	module_slot = "coating"
	allowed_weapon_forms = list("physical_melee", "energy_melee", "knife", "twohand_sword", "axe", "twohand_axe", "rapier", "spear")
	force_multiplier = 1.08
	armour_penetration_delta = 3
	melee_damage_profile = list(BODYPART_DAMAGE_SLASH = 0.8, BODYPART_DAMAGE_PIERCE = 0.2)

/datum/cyberpunk_item_module/serrated_coating/t2
	name = "serrated weapon coating T2"
	module_tier = 2

/datum/cyberpunk_item_module/serrated_coating/t3
	name = "serrated weapon coating T3"
	module_tier = 3

/datum/cyberpunk_item_module/firearm_core
	name = "firearm core"
	module_slot = "core"
	integrity_delta = 15
	guard_delta = 5

/datum/cyberpunk_item_module/firearm_core/t2
	name = "firearm core T2"
	module_tier = 2

/datum/cyberpunk_item_module/firearm_core/t3
	name = "firearm core T3"
	module_tier = 3

/datum/cyberpunk_item_module/heavy_barrel
	name = "heavy barrel"
	module_slot = "barrel"
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.12
	gun_projectile_wound_bonus_delta = 4
	gun_spread_delta = 3
	gun_fire_delay_multiplier = 1.1

/datum/cyberpunk_item_module/heavy_barrel/t2
	name = "heavy barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/heavy_barrel/t3
	name = "heavy barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/long_barrel
	name = "long barrel"
	module_slot = "barrel"
	weight_delta = 1
	gun_spread_delta = -5
	gun_projectile_speed_multiplier_delta = 0.12
	gun_fire_delay_multiplier = 1.05

/datum/cyberpunk_item_module/long_barrel/t2
	name = "long barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/long_barrel/t3
	name = "long barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/revolver_barrel
	name = "revolver barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "revolver")
	weapon_form_override = "revolver"
	gun_spread_delta = -2

/datum/cyberpunk_item_module/revolver_barrel/t2
	name = "revolver barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/revolver_barrel/t3
	name = "revolver barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_barrel
	name = "pistol barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "pistol")
	weapon_form_override = "pistol"
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/pistol_barrel/t2
	name = "pistol barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_barrel/t3
	name = "pistol barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/smg_barrel
	name = "SMG barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "smg")
	weapon_form_override = "smg"
	gun_fire_delay_multiplier = 0.9
	gun_spread_delta = 3

/datum/cyberpunk_item_module/smg_barrel/t2
	name = "SMG barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/smg_barrel/t3
	name = "SMG barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/rifle_barrel
	name = "rifle barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "rifle")
	weapon_form_override = "rifle"
	weight_delta = 1
	gun_spread_delta = -4
	gun_projectile_speed_multiplier_delta = 0.05

/datum/cyberpunk_item_module/rifle_barrel/t2
	name = "rifle barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/rifle_barrel/t3
	name = "rifle barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/shotgun_barrel
	name = "shotgun barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "shotgun")
	weapon_form_override = "shotgun"
	weight_delta = 1
	gun_spread_delta = 8
	gun_projectile_wound_bonus_delta = 4

/datum/cyberpunk_item_module/shotgun_barrel/t2
	name = "shotgun barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/shotgun_barrel/t3
	name = "shotgun barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/sniper_barrel
	name = "sniper barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "sniper")
	weapon_form_override = "sniper"
	weight_delta = 2
	gun_spread_delta = -12
	gun_fire_delay_multiplier = 1.2
	gun_projectile_speed_multiplier_delta = 0.15

/datum/cyberpunk_item_module/sniper_barrel/t2
	name = "sniper barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/sniper_barrel/t3
	name = "sniper barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/assault_barrel
	name = "assault barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "assault")
	weapon_form_override = "assault"
	weight_delta = 1
	gun_spread_delta = 2
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/assault_barrel/t2
	name = "assault barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/assault_barrel/t3
	name = "assault barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/lmg_barrel
	name = "machine gun barrel"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "lmg")
	weapon_form_override = "lmg"
	weight_delta = 2
	gun_spread_delta = 6
	gun_fire_delay_multiplier = 0.85

/datum/cyberpunk_item_module/lmg_barrel/t2
	name = "machine gun barrel T2"
	module_tier = 2

/datum/cyberpunk_item_module/lmg_barrel/t3
	name = "machine gun barrel T3"
	module_tier = 3

/datum/cyberpunk_item_module/rocket_barrel
	name = "launcher tube"
	module_slot = "barrel"
	allowed_weapon_forms = list("ballistic", "rocket")
	weapon_form_override = "rocket"
	weight_delta = 3
	gun_fire_delay_multiplier = 1.15

/datum/cyberpunk_item_module/rocket_barrel/t2
	name = "launcher tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/rocket_barrel/t3
	name = "launcher tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/cylinder_50
	name = ".50 revolver cylinder"
	module_slot = "action"
	allowed_weapon_forms = list("revolver")
	weight_delta = 1
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder/cyberpunk_50
	gun_ammo_type = /obj/item/ammo_casing/a50ae
	gun_caliber = CALIBER_50AE
	gun_fire_delay_multiplier = 1.25
	gun_projectile_damage_multiplier_delta = 0.2
	gun_projectile_wound_bonus_delta = 6

/datum/cyberpunk_item_module/cylinder_50/t2
	name = ".50 revolver cylinder T2"
	module_tier = 2

/datum/cyberpunk_item_module/cylinder_50/t3
	name = ".50 revolver cylinder T3"
	module_tier = 3

/datum/cyberpunk_item_module/cylinder_357
	name = ".357 revolver cylinder"
	module_slot = "action"
	allowed_weapon_forms = list("revolver")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/cylinder
	gun_ammo_type = /obj/item/ammo_casing/c357
	gun_caliber = CALIBER_357
	gun_projectile_damage_multiplier_delta = 0.05

/datum/cyberpunk_item_module/cylinder_357/t2
	name = ".357 revolver cylinder T2"
	module_tier = 2

/datum/cyberpunk_item_module/cylinder_357/t3
	name = ".357 revolver cylinder T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_magwell_9mm
	name = "9mm pistol magwell"
	module_slot = "action"
	allowed_weapon_forms = list("pistol")
	gun_magazine_type = /obj/item/ammo_box/magazine/m9mm
	gun_ammo_type = /obj/item/ammo_casing/c9mm
	gun_caliber = CALIBER_9MM
	gun_projectile_damage_multiplier_delta = -0.05
	gun_fire_delay_multiplier = 0.9

/datum/cyberpunk_item_module/pistol_magwell_9mm/t2
	name = "9mm pistol magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_magwell_9mm/t3
	name = "9mm pistol magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/pistol_magwell_10mm
	name = "10mm pistol magwell"
	module_slot = "action"
	allowed_weapon_forms = list("pistol")
	gun_magazine_type = /obj/item/ammo_box/magazine/m10mm
	gun_ammo_type = /obj/item/ammo_casing/c10mm
	gun_caliber = CALIBER_10MM
	gun_projectile_damage_multiplier_delta = 0.05
	gun_fire_delay_multiplier = 1.05

/datum/cyberpunk_item_module/pistol_magwell_10mm/t2
	name = "10mm pistol magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/pistol_magwell_10mm/t3
	name = "10mm pistol magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/smg_magwell_9mm
	name = "9mm SMG magwell"
	module_slot = "action"
	allowed_weapon_forms = list("smg")
	gun_magazine_type = /obj/item/ammo_box/magazine/smgm9mm
	gun_ammo_type = /obj/item/ammo_casing/c9mm
	gun_caliber = CALIBER_9MM
	gun_fire_delay_multiplier = 0.85
	gun_spread_delta = 3

/datum/cyberpunk_item_module/smg_magwell_9mm/t2
	name = "9mm SMG magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/smg_magwell_9mm/t3
	name = "9mm SMG magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/rifle_magwell_223
	name = ".223 rifle magwell"
	module_slot = "action"
	allowed_weapon_forms = list("rifle")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.12
	gun_projectile_speed_multiplier_delta = 0.1
	gun_fire_delay_multiplier = 1.15

/datum/cyberpunk_item_module/rifle_magwell_223/t2
	name = ".223 rifle magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/rifle_magwell_223/t3
	name = ".223 rifle magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/shotgun_tube
	name = "shotgun tube"
	module_slot = "action"
	allowed_weapon_forms = list("shotgun")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/shot/lethal
	gun_ammo_type = /obj/item/ammo_casing/shotgun
	gun_caliber = CALIBER_SHOTGUN
	weight_delta = 1
	gun_spread_delta = 10
	gun_fire_delay_multiplier = 1.2
	gun_projectile_wound_bonus_delta = 5

/datum/cyberpunk_item_module/shotgun_tube/t2
	name = "shotgun tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/shotgun_tube/t3
	name = "shotgun tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/sniper_chamber
	name = "sniper chamber"
	module_slot = "action"
	allowed_weapon_forms = list("sniper")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 1
	gun_spread_delta = -10
	gun_fire_delay_multiplier = 1.35
	gun_projectile_damage_multiplier_delta = 0.22
	gun_projectile_wound_bonus_delta = 8
	gun_projectile_speed_multiplier_delta = 0.18

/datum/cyberpunk_item_module/sniper_chamber/t2
	name = "sniper chamber T2"
	module_tier = 2

/datum/cyberpunk_item_module/sniper_chamber/t3
	name = "sniper chamber T3"
	module_tier = 3

/datum/cyberpunk_item_module/assault_magwell_223
	name = ".223 assault magwell"
	module_slot = "action"
	allowed_weapon_forms = list("assault")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	gun_fire_delay_multiplier = 0.95
	gun_spread_delta = 4
	gun_projectile_damage_multiplier_delta = 0.04

/datum/cyberpunk_item_module/assault_magwell_223/t2
	name = ".223 assault magwell T2"
	module_tier = 2

/datum/cyberpunk_item_module/assault_magwell_223/t3
	name = ".223 assault magwell T3"
	module_tier = 3

/datum/cyberpunk_item_module/lmg_feed_223
	name = ".223 belt feed"
	module_slot = "action"
	allowed_weapon_forms = list("lmg")
	gun_magazine_type = /obj/item/ammo_box/magazine/m223
	gun_ammo_type = /obj/item/ammo_casing/a223
	gun_caliber = CALIBER_A223
	weight_delta = 2
	gun_fire_delay_multiplier = 0.8
	gun_spread_delta = 8
	gun_projectile_damage_multiplier_delta = -0.05

/datum/cyberpunk_item_module/lmg_feed_223/t2
	name = ".223 belt feed T2"
	module_tier = 2

/datum/cyberpunk_item_module/lmg_feed_223/t3
	name = ".223 belt feed T3"
	module_tier = 3

/datum/cyberpunk_item_module/rocket_tube
	name = "rocket launch tube"
	module_slot = "action"
	allowed_weapon_forms = list("rocket")
	gun_magazine_type = /obj/item/ammo_box/magazine/internal/rocketlauncher
	gun_ammo_type = /obj/item/ammo_casing/rocket
	weight_delta = 3
	gun_fire_delay_multiplier = 1.25
	gun_projectile_damage_multiplier_delta = 0.1

/datum/cyberpunk_item_module/rocket_tube/t2
	name = "rocket launch tube T2"
	module_tier = 2

/datum/cyberpunk_item_module/rocket_tube/t3
	name = "rocket launch tube T3"
	module_tier = 3

/datum/cyberpunk_item_module/laser_emitter
	name = "laser emitter"
	module_slot = "barrel"
	allowed_weapon_forms = list("energy", "laser")
	weapon_form_override = "laser"
	gun_energy_ammo_types = list(/obj/item/ammo_casing/energy/lasergun)
	gun_projectile_speed_multiplier_delta = 0.08
	gun_fire_delay_multiplier = 0.95

/datum/cyberpunk_item_module/laser_emitter/t2
	name = "laser emitter T2"
	module_tier = 2

/datum/cyberpunk_item_module/laser_emitter/t3
	name = "laser emitter T3"
	module_tier = 3

/datum/cyberpunk_item_module/plasma_emitter
	name = "plasma emitter"
	module_slot = "barrel"
	allowed_weapon_forms = list("energy", "plasma")
	weapon_form_override = "plasma"
	gun_energy_ammo_types = list(/obj/item/ammo_casing/energy/plasma)
	weight_delta = 1
	gun_projectile_damage_multiplier_delta = 0.16
	gun_projectile_wound_bonus_delta = 6
	gun_fire_delay_multiplier = 1.2

/datum/cyberpunk_item_module/plasma_emitter/t2
	name = "plasma emitter T2"
	module_tier = 2

/datum/cyberpunk_item_module/plasma_emitter/t3
	name = "plasma emitter T3"
	module_tier = 3

/datum/cyberpunk_item_module/precision_receiver
	name = "precision receiver"
	module_slot = "receiver"
	gun_spread_delta = -8
	gun_projectile_speed_multiplier_delta = 0.08
	armour_penetration_delta = 4

/datum/cyberpunk_item_module/precision_receiver/t2
	name = "precision receiver T2"
	module_tier = 2

/datum/cyberpunk_item_module/precision_receiver/t3
	name = "precision receiver T3"
	module_tier = 3

/datum/cyberpunk_item_module/damage_trigger
	name = "overpressure trigger"
	module_slot = "trigger"
	gun_projectile_damage_multiplier_delta = 0.1
	gun_fire_delay_multiplier = 1.08

/datum/cyberpunk_item_module/damage_trigger/t2
	name = "overpressure trigger T2"
	module_tier = 2

/datum/cyberpunk_item_module/damage_trigger/t3
	name = "overpressure trigger T3"
	module_tier = 3

/datum/cyberpunk_item_module/speed_trigger
	name = "short-reset trigger"
	module_slot = "trigger"
	gun_fire_delay_multiplier = 0.85
	gun_spread_delta = 2

/datum/cyberpunk_item_module/speed_trigger/t2
	name = "short-reset trigger T2"
	module_tier = 2

/datum/cyberpunk_item_module/speed_trigger/t3
	name = "short-reset trigger T3"
	module_tier = 3

/datum/cyberpunk_item_module/reflex_sight
	name = "reflex sight"
	module_slot = "sight"
	weight_delta = 0
	gun_spread_delta = -6

/datum/cyberpunk_item_module/reflex_sight/t2
	name = "reflex sight T2"
	module_tier = 2

/datum/cyberpunk_item_module/reflex_sight/t3
	name = "reflex sight T3"
	module_tier = 3

/datum/cyberpunk_item_module/tactical_light
	name = "tactical light"
	module_slot = "underbarrel"
	weight_delta = 1
	gun_spread_delta = -2
	active_ability_name = "weapon light"
	active_ability_description = "The underslung light floods the target area."
	active_cooldown = 12 SECONDS
	active_duration = 6 SECONDS

/datum/cyberpunk_item_module/tactical_light/t2
	name = "tactical light T2"
	module_tier = 2

/datum/cyberpunk_item_module/tactical_light/t3
	name = "tactical light T3"
	module_tier = 3

/datum/cyberpunk_item_module/armor_plate
	name = "armor plate"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 25
	armor_delta = list(MELEE = 8, BULLET = 8)

/datum/cyberpunk_item_module/armor_plate/t2
	name = "armor plate T2"
	module_tier = 2

/datum/cyberpunk_item_module/armor_plate/t3
	name = "armor plate T3"
	module_tier = 3

/datum/cyberpunk_item_module/armor_lining
	name = "protective lining"
	module_slot = "lining"
	integrity_delta = 10
	armor_delta = list(FIRE = 8, ACID = 5, WOUND = 3)

/datum/cyberpunk_item_module/armor_lining/t2
	name = "protective lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/armor_lining/t3
	name = "protective lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/weight_reducer
	name = "lightweight frame"
	module_slot = "utility"
	weight_delta = -1
	integrity_delta = -5
	armor_delta = list(MELEE = -2, BULLET = -2)

/datum/cyberpunk_item_module/weight_reducer/t2
	name = "lightweight frame T2"
	module_tier = 2

/datum/cyberpunk_item_module/weight_reducer/t3
	name = "lightweight frame T3"
	module_tier = 3

/datum/cyberpunk_item_module/mobility_servo
	name = "mobility servo"
	module_slot = "mobility"
	weight_delta = 0
	slowdown_delta = -0.15
	integrity_delta = 5
	armor_delta = list(ENERGY = 4)
	active_ability_name = "servo burst"
	active_ability_description = "The mobility frame dumps reserve torque into your limbs."
	active_cooldown = 24 SECONDS
	active_duration = 6 SECONDS
	active_slowdown_delta = -0.2
	active_stamina_restore = 12

/datum/cyberpunk_item_module/mobility_servo/t2
	name = "mobility servo T2"
	module_tier = 2

/datum/cyberpunk_item_module/mobility_servo/t3
	name = "mobility servo T3"
	module_tier = 3

/datum/cyberpunk_item_module/reactive_hardener
	name = "reactive hardener"
	module_slot = "active"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(MELEE = 6, BULLET = 6, LASER = 6, ENERGY = 6, WOUND = 4)
	active_ability_name = "reactive hardening"
	active_ability_description = "The plating locks into a short defensive state."
	active_cooldown = 45 SECONDS
	active_duration = 10 SECONDS
	active_armor_delta = list(MELEE = 14, BULLET = 14, LASER = 14, ENERGY = 14, BOMB = 8, WOUND = 8)

/datum/cyberpunk_item_module/reactive_hardener/t2
	name = "reactive hardener T2"
	module_tier = 2

/datum/cyberpunk_item_module/reactive_hardener/t3
	name = "reactive hardener T3"
	module_tier = 3

/datum/cyberpunk_item_module/impact_gel
	name = "impact gel"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 20
	armor_delta = list(MELEE = 12, BOMB = 8, WOUND = 8)

/datum/cyberpunk_item_module/impact_gel/t2
	name = "impact gel T2"
	module_tier = 2

/datum/cyberpunk_item_module/impact_gel/t3
	name = "impact gel T3"
	module_tier = 3

/datum/cyberpunk_item_module/ballistic_weave
	name = "ballistic weave"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(BULLET = 14, MELEE = 4, WOUND = 5)

/datum/cyberpunk_item_module/ballistic_weave/t2
	name = "ballistic weave T2"
	module_tier = 2

/datum/cyberpunk_item_module/ballistic_weave/t3
	name = "ballistic weave T3"
	module_tier = 3

/datum/cyberpunk_item_module/ablative_mesh
	name = "ablative mesh"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 15
	armor_delta = list(LASER = 14, ENERGY = 8, FIRE = 4)

/datum/cyberpunk_item_module/ablative_mesh/t2
	name = "ablative mesh T2"
	module_tier = 2

/datum/cyberpunk_item_module/ablative_mesh/t3
	name = "ablative mesh T3"
	module_tier = 3

/datum/cyberpunk_item_module/insulation_lining
	name = "insulation lining"
	module_slot = "lining"
	integrity_delta = 8
	armor_delta = list(ENERGY = 10, FIRE = 8)
	active_ability_name = "thermal dump"
	active_ability_description = "The lining vents heat and stabilizes energy insulation."
	active_cooldown = 35 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(ENERGY = 12, FIRE = 16, LASER = 6)
	active_extinguish = TRUE

/datum/cyberpunk_item_module/insulation_lining/t2
	name = "insulation lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/insulation_lining/t3
	name = "insulation lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/chemseal_lining
	name = "chemseal lining"
	module_slot = "lining"
	integrity_delta = 8
	armor_delta = list(ACID = 14, BIO = 12)
	active_ability_name = "seal purge"
	active_ability_description = "The lining purges contaminants and seals vulnerable seams."
	active_cooldown = 40 SECONDS
	active_duration = 10 SECONDS
	active_armor_delta = list(ACID = 18, BIO = 18, FIRE = 6)

/datum/cyberpunk_item_module/chemseal_lining/t2
	name = "chemseal lining T2"
	module_tier = 2

/datum/cyberpunk_item_module/chemseal_lining/t3
	name = "chemseal lining T3"
	module_tier = 3

/datum/cyberpunk_item_module/sensor_bus
	name = "sensor bus"
	module_slot = "utility"
	weight_delta = 0
	integrity_delta = 5
	armor_delta = list(ENERGY = 2)
	active_ability_name = "threat scan"
	active_ability_description = "The bus predicts incoming angles and tightens defensive timing."
	active_cooldown = 30 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(MELEE = 5, BULLET = 5, LASER = 5, ENERGY = 5, WOUND = 5)

/datum/cyberpunk_item_module/blast_padding
	name = "blast padding"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 18
	armor_delta = list(BOMB = 16, MELEE = 5, FIRE = 5, WOUND = 4)

/datum/cyberpunk_item_module/blast_padding/t2
	name = "blast padding T2"
	module_tier = 2

/datum/cyberpunk_item_module/blast_padding/t3
	name = "blast padding T3"
	module_tier = 3

/datum/cyberpunk_item_module/trauma_mesh
	name = "trauma mesh"
	module_slot = "lining"
	integrity_delta = 12
	armor_delta = list(WOUND = 14, MELEE = 5, BULLET = 5)

/datum/cyberpunk_item_module/trauma_mesh/t2
	name = "trauma mesh T2"
	module_tier = 2

/datum/cyberpunk_item_module/trauma_mesh/t3
	name = "trauma mesh T3"
	module_tier = 3

/datum/cyberpunk_item_module/deflection_laminate
	name = "deflection laminate"
	module_slot = "plate"
	weight_delta = 1
	integrity_delta = 18
	armor_delta = list(LASER = 10, BULLET = 8, ENERGY = 6)

/datum/cyberpunk_item_module/deflection_laminate/t2
	name = "deflection laminate T2"
	module_tier = 2

/datum/cyberpunk_item_module/deflection_laminate/t3
	name = "deflection laminate T3"
	module_tier = 3

/datum/cyberpunk_item_module/grounding_bus
	name = "grounding bus"
	module_slot = "utility"
	integrity_delta = 6
	armor_delta = list(ENERGY = 10, LASER = 4)
	active_ability_name = "grounding pulse"
	active_ability_description = "The bus shunts hostile charge through a short grounding loop."
	active_cooldown = 32 SECONDS
	active_duration = 8 SECONDS
	active_armor_delta = list(ENERGY = 18, LASER = 8)
	active_stamina_restore = 6

/datum/cyberpunk_item_module/grounding_bus/t2
	name = "grounding bus T2"
	module_tier = 2

/datum/cyberpunk_item_module/grounding_bus/t3
	name = "grounding bus T3"
	module_tier = 3

/datum/cyberpunk_item_module/medfoam_injector
	name = "medfoam injector"
	module_slot = "active"
	weight_delta = 1
	integrity_delta = 8
	armor_delta = list(WOUND = 4, BIO = 4)
	active_ability_name = "medfoam release"
	active_ability_description = "The injector floods inner pads with emergency foam."
	active_cooldown = 60 SECONDS
	active_duration = 6 SECONDS
	active_armor_delta = list(WOUND = 10, MELEE = 5, BULLET = 5)
	active_brute_heal = 6
	active_burn_heal = 4

/datum/cyberpunk_item_module/medfoam_injector/t2
	name = "medfoam injector T2"
	module_tier = 2

/datum/cyberpunk_item_module/medfoam_injector/t3
	name = "medfoam injector T3"
	module_tier = 3

/datum/cyberpunk_item_module/sensor_bus/t2
	name = "sensor bus T2"
	module_tier = 2

/datum/cyberpunk_item_module/sensor_bus/t3
	name = "sensor bus T3"
	module_tier = 3

/datum/design/cyberpunk_item_module
	name = "Starlight Item Module"
	desc = "A Starlight modular component shell for Cyberpunk 13 weapons and protective equipment."
	id = "starlight_item_module"
	build_type = PROTOLATHE | AUTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
//CYBERPUNK BUILD - rebuild and delete before release
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/cyberpunk_item_module/melee_core
	name = "Starlight Melee Core"
	id = "starlight_melee_core"
	build_path = /obj/item/cyberpunk_item_module/melee_core

/datum/design/cyberpunk_item_module/melee_blade
	name = "Starlight Blade Element"
	id = "starlight_blade_element"
	build_path = /obj/item/cyberpunk_item_module/melee_blade

/datum/design/cyberpunk_item_module/melee_spike
	name = "Starlight Spike Element"
	id = "starlight_spike_element"
	build_path = /obj/item/cyberpunk_item_module/melee_spike

/datum/design/cyberpunk_item_module/melee_head
	name = "Starlight Weighted Head"
	id = "starlight_weighted_head"
	build_path = /obj/item/cyberpunk_item_module/melee_head

/datum/design/cyberpunk_item_module/guard
	name = "Starlight Weapon Guard"
	id = "starlight_weapon_guard"
	build_path = /obj/item/cyberpunk_item_module/guard

/datum/design/cyberpunk_item_module/balancer
	name = "Starlight Weapon Balancer"
	id = "starlight_weapon_balancer"
	build_path = /obj/item/cyberpunk_item_module/balancer

/datum/design/cyberpunk_item_module/melee_knife_element
	name = "Starlight Knife Attacking Element"
	id = "starlight_knife_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_knife_element

/datum/design/cyberpunk_item_module/melee_club_element
	name = "Starlight Club Attacking Element"
	id = "starlight_club_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_club_element

/datum/design/cyberpunk_item_module/melee_twohand_sword_element
	name = "Starlight Two-Handed Sword Attacking Element"
	id = "starlight_twohand_sword_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_sword_element

/datum/design/cyberpunk_item_module/melee_twohand_hammer_element
	name = "Starlight Two-Handed Hammer Attacking Element"
	id = "starlight_twohand_hammer_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_hammer_element

/datum/design/cyberpunk_item_module/melee_axe_element
	name = "Starlight Axe Attacking Element"
	id = "starlight_axe_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_axe_element

/datum/design/cyberpunk_item_module/melee_twohand_axe_element
	name = "Starlight Two-Handed Axe Attacking Element"
	id = "starlight_twohand_axe_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_twohand_axe_element

/datum/design/cyberpunk_item_module/melee_rapier_element
	name = "Starlight Rapier Attacking Element"
	id = "starlight_rapier_attacking_element"
	build_path = /obj/item/cyberpunk_item_module/melee_rapier_element

/datum/design/cyberpunk_item_module/melee_spear_element
	name = "Starlight Spear Attacking Element"
	id = "starlight_spear_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_spear_element

/datum/design/cyberpunk_item_module/melee_staff_element
	name = "Starlight Staff Attacking Element"
	id = "starlight_staff_attacking_element"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/melee_staff_element

/datum/design/cyberpunk_item_module/shock_coating
	name = "Starlight Shock Weapon Coating"
	id = "starlight_shock_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shock_coating

/datum/design/cyberpunk_item_module/thermal_coating
	name = "Starlight Thermal Weapon Coating"
	id = "starlight_thermal_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/thermal_coating

/datum/design/cyberpunk_item_module/serrated_coating
	name = "Starlight Serrated Weapon Coating"
	id = "starlight_serrated_weapon_coating"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/serrated_coating

/datum/design/cyberpunk_item_module/firearm_core
	name = "Starlight Firearm Core"
	id = "starlight_firearm_core"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/firearm_core

/datum/design/cyberpunk_item_module/heavy_barrel
	name = "Starlight Heavy Barrel"
	id = "starlight_heavy_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel

/datum/design/cyberpunk_item_module/long_barrel
	name = "Starlight Long Barrel"
	id = "starlight_long_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/long_barrel

/datum/design/cyberpunk_item_module/revolver_barrel
	name = "Starlight Revolver Barrel"
	id = "starlight_revolver_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel

/datum/design/cyberpunk_item_module/pistol_barrel
	name = "Starlight Pistol Barrel"
	id = "starlight_pistol_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel

/datum/design/cyberpunk_item_module/smg_barrel
	name = "Starlight SMG Barrel"
	id = "starlight_smg_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/smg_barrel

/datum/design/cyberpunk_item_module/rifle_barrel
	name = "Starlight Rifle Barrel"
	id = "starlight_rifle_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel

/datum/design/cyberpunk_item_module/shotgun_barrel
	name = "Starlight Shotgun Barrel"
	id = "starlight_shotgun_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel

/datum/design/cyberpunk_item_module/sniper_barrel
	name = "Starlight Sniper Barrel"
	id = "starlight_sniper_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel

/datum/design/cyberpunk_item_module/assault_barrel
	name = "Starlight Assault Barrel"
	id = "starlight_assault_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/assault_barrel

/datum/design/cyberpunk_item_module/lmg_barrel
	name = "Starlight Machine Gun Barrel"
	id = "starlight_lmg_barrel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel

/datum/design/cyberpunk_item_module/rocket_barrel
	name = "Starlight Launcher Tube"
	id = "starlight_launcher_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel

/datum/design/cyberpunk_item_module/cylinder_50
	name = "Starlight .50 Cylinder"
	id = "starlight_cylinder_50"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/cylinder_50

/datum/design/cyberpunk_item_module/cylinder_357
	name = "Starlight .357 Cylinder"
	id = "starlight_cylinder_357"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/cylinder_357

/datum/design/cyberpunk_item_module/pistol_magwell_9mm
	name = "Starlight 9mm Pistol Magwell"
	id = "starlight_pistol_magwell_9mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm

/datum/design/cyberpunk_item_module/pistol_magwell_10mm
	name = "Starlight 10mm Pistol Magwell"
	id = "starlight_pistol_magwell_10mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm

/datum/design/cyberpunk_item_module/smg_magwell_9mm
	name = "Starlight 9mm SMG Magwell"
	id = "starlight_smg_magwell_9mm"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm

/datum/design/cyberpunk_item_module/rifle_magwell_223
	name = "Starlight .223 Rifle Magwell"
	id = "starlight_rifle_magwell_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223

/datum/design/cyberpunk_item_module/shotgun_tube
	name = "Starlight Shotgun Tube"
	id = "starlight_shotgun_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube

/datum/design/cyberpunk_item_module/sniper_chamber
	name = "Starlight Sniper Chamber"
	id = "starlight_sniper_chamber"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber

/datum/design/cyberpunk_item_module/assault_magwell_223
	name = "Starlight .223 Assault Magwell"
	id = "starlight_assault_magwell_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223

/datum/design/cyberpunk_item_module/lmg_feed_223
	name = "Starlight .223 Belt Feed"
	id = "starlight_lmg_feed_223"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223

/datum/design/cyberpunk_item_module/rocket_tube
	name = "Starlight Rocket Launch Tube"
	id = "starlight_rocket_tube"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/rocket_tube

/datum/design/cyberpunk_item_module/laser_emitter
	name = "Starlight Laser Emitter"
	id = "starlight_laser_emitter"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/laser_emitter

/datum/design/cyberpunk_item_module/plasma_emitter
	name = "Starlight Plasma Emitter"
	id = "starlight_plasma_emitter"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter

/datum/design/cyberpunk_item_module/precision_receiver
	name = "Starlight Precision Receiver"
	id = "starlight_precision_receiver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/precision_receiver

/datum/design/cyberpunk_item_module/damage_trigger
	name = "Starlight Overpressure Trigger"
	id = "starlight_damage_trigger"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/damage_trigger

/datum/design/cyberpunk_item_module/speed_trigger
	name = "Starlight Short-Reset Trigger"
	id = "starlight_speed_trigger"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/speed_trigger

/datum/design/cyberpunk_item_module/reflex_sight
	name = "Starlight Reflex Sight"
	id = "starlight_reflex_sight"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/reflex_sight

/datum/design/cyberpunk_item_module/tactical_light
	name = "Starlight Tactical Light"
	id = "starlight_tactical_light"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/tactical_light

/datum/design/cyberpunk_item_module/firearm_core/t2
	name = "Starlight Firearm Core T2"
	id = "starlight_firearm_core_t2"
	build_path = /obj/item/cyberpunk_item_module/firearm_core/t2

/datum/design/cyberpunk_item_module/firearm_core/t3
	name = "Starlight Firearm Core T3"
	id = "starlight_firearm_core_t3"
	build_path = /obj/item/cyberpunk_item_module/firearm_core/t3

/datum/design/cyberpunk_item_module/heavy_barrel/t2
	name = "Starlight Heavy Barrel T2"
	id = "starlight_heavy_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel/t2

/datum/design/cyberpunk_item_module/heavy_barrel/t3
	name = "Starlight Heavy Barrel T3"
	id = "starlight_heavy_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/heavy_barrel/t3

/datum/design/cyberpunk_item_module/long_barrel/t2
	name = "Starlight Long Barrel T2"
	id = "starlight_long_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/long_barrel/t2

/datum/design/cyberpunk_item_module/long_barrel/t3
	name = "Starlight Long Barrel T3"
	id = "starlight_long_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/long_barrel/t3

/datum/design/cyberpunk_item_module/cylinder_50/t2
	name = "Starlight .50 Cylinder T2"
	id = "starlight_cylinder_50_t2"
	build_path = /obj/item/cyberpunk_item_module/cylinder_50/t2

/datum/design/cyberpunk_item_module/cylinder_50/t3
	name = "Starlight .50 Cylinder T3"
	id = "starlight_cylinder_50_t3"
	build_path = /obj/item/cyberpunk_item_module/cylinder_50/t3

/datum/design/cyberpunk_item_module/cylinder_357/t2
	name = "Starlight .357 Cylinder T2"
	id = "starlight_cylinder_357_t2"
	build_path = /obj/item/cyberpunk_item_module/cylinder_357/t2

/datum/design/cyberpunk_item_module/cylinder_357/t3
	name = "Starlight .357 Cylinder T3"
	id = "starlight_cylinder_357_t3"
	build_path = /obj/item/cyberpunk_item_module/cylinder_357/t3

/datum/design/cyberpunk_item_module/pistol_magwell_9mm/t2
	name = "Starlight 9mm Pistol Magwell T2"
	id = "starlight_pistol_magwell_9mm_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm/t2

/datum/design/cyberpunk_item_module/pistol_magwell_9mm/t3
	name = "Starlight 9mm Pistol Magwell T3"
	id = "starlight_pistol_magwell_9mm_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_9mm/t3

/datum/design/cyberpunk_item_module/pistol_magwell_10mm/t2
	name = "Starlight 10mm Pistol Magwell T2"
	id = "starlight_pistol_magwell_10mm_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm/t2

/datum/design/cyberpunk_item_module/pistol_magwell_10mm/t3
	name = "Starlight 10mm Pistol Magwell T3"
	id = "starlight_pistol_magwell_10mm_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_magwell_10mm/t3

/datum/design/cyberpunk_item_module/smg_magwell_9mm/t2
	name = "Starlight 9mm SMG Magwell T2"
	id = "starlight_smg_magwell_9mm_t2"
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm/t2

/datum/design/cyberpunk_item_module/smg_magwell_9mm/t3
	name = "Starlight 9mm SMG Magwell T3"
	id = "starlight_smg_magwell_9mm_t3"
	build_path = /obj/item/cyberpunk_item_module/smg_magwell_9mm/t3

/datum/design/cyberpunk_item_module/rifle_magwell_223/t2
	name = "Starlight .223 Rifle Magwell T2"
	id = "starlight_rifle_magwell_223_t2"
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223/t2

/datum/design/cyberpunk_item_module/rifle_magwell_223/t3
	name = "Starlight .223 Rifle Magwell T3"
	id = "starlight_rifle_magwell_223_t3"
	build_path = /obj/item/cyberpunk_item_module/rifle_magwell_223/t3

/datum/design/cyberpunk_item_module/precision_receiver/t2
	name = "Starlight Precision Receiver T2"
	id = "starlight_precision_receiver_t2"
	build_path = /obj/item/cyberpunk_item_module/precision_receiver/t2

/datum/design/cyberpunk_item_module/precision_receiver/t3
	name = "Starlight Precision Receiver T3"
	id = "starlight_precision_receiver_t3"
	build_path = /obj/item/cyberpunk_item_module/precision_receiver/t3

/datum/design/cyberpunk_item_module/damage_trigger/t2
	name = "Starlight Overpressure Trigger T2"
	id = "starlight_damage_trigger_t2"
	build_path = /obj/item/cyberpunk_item_module/damage_trigger/t2

/datum/design/cyberpunk_item_module/damage_trigger/t3
	name = "Starlight Overpressure Trigger T3"
	id = "starlight_damage_trigger_t3"
	build_path = /obj/item/cyberpunk_item_module/damage_trigger/t3

/datum/design/cyberpunk_item_module/speed_trigger/t2
	name = "Starlight Short-Reset Trigger T2"
	id = "starlight_speed_trigger_t2"
	build_path = /obj/item/cyberpunk_item_module/speed_trigger/t2

/datum/design/cyberpunk_item_module/speed_trigger/t3
	name = "Starlight Short-Reset Trigger T3"
	id = "starlight_speed_trigger_t3"
	build_path = /obj/item/cyberpunk_item_module/speed_trigger/t3

/datum/design/cyberpunk_item_module/reflex_sight/t2
	name = "Starlight Reflex Sight T2"
	id = "starlight_reflex_sight_t2"
	build_path = /obj/item/cyberpunk_item_module/reflex_sight/t2

/datum/design/cyberpunk_item_module/reflex_sight/t3
	name = "Starlight Reflex Sight T3"
	id = "starlight_reflex_sight_t3"
	build_path = /obj/item/cyberpunk_item_module/reflex_sight/t3

/datum/design/cyberpunk_item_module/tactical_light/t2
	name = "Starlight Tactical Light T2"
	id = "starlight_tactical_light_t2"
	build_path = /obj/item/cyberpunk_item_module/tactical_light/t2

/datum/design/cyberpunk_item_module/tactical_light/t3
	name = "Starlight Tactical Light T3"
	id = "starlight_tactical_light_t3"
	build_path = /obj/item/cyberpunk_item_module/tactical_light/t3

/datum/design/cyberpunk_item_module/revolver_barrel/t2
	name = "Starlight Revolver Barrel T2"
	id = "starlight_revolver_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel/t2

/datum/design/cyberpunk_item_module/revolver_barrel/t3
	name = "Starlight Revolver Barrel T3"
	id = "starlight_revolver_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/revolver_barrel/t3

/datum/design/cyberpunk_item_module/pistol_barrel/t2
	name = "Starlight Pistol Barrel T2"
	id = "starlight_pistol_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel/t2

/datum/design/cyberpunk_item_module/pistol_barrel/t3
	name = "Starlight Pistol Barrel T3"
	id = "starlight_pistol_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/pistol_barrel/t3

/datum/design/cyberpunk_item_module/smg_barrel/t2
	name = "Starlight SMG Barrel T2"
	id = "starlight_smg_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/smg_barrel/t2

/datum/design/cyberpunk_item_module/smg_barrel/t3
	name = "Starlight SMG Barrel T3"
	id = "starlight_smg_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/smg_barrel/t3

/datum/design/cyberpunk_item_module/rifle_barrel/t2
	name = "Starlight Rifle Barrel T2"
	id = "starlight_rifle_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel/t2

/datum/design/cyberpunk_item_module/rifle_barrel/t3
	name = "Starlight Rifle Barrel T3"
	id = "starlight_rifle_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/rifle_barrel/t3

/datum/design/cyberpunk_item_module/shotgun_barrel/t2
	name = "Starlight Shotgun Barrel T2"
	id = "starlight_shotgun_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel/t2

/datum/design/cyberpunk_item_module/shotgun_barrel/t3
	name = "Starlight Shotgun Barrel T3"
	id = "starlight_shotgun_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/shotgun_barrel/t3

/datum/design/cyberpunk_item_module/sniper_barrel/t2
	name = "Starlight Sniper Barrel T2"
	id = "starlight_sniper_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel/t2

/datum/design/cyberpunk_item_module/sniper_barrel/t3
	name = "Starlight Sniper Barrel T3"
	id = "starlight_sniper_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/sniper_barrel/t3

/datum/design/cyberpunk_item_module/assault_barrel/t2
	name = "Starlight Assault Barrel T2"
	id = "starlight_assault_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/assault_barrel/t2

/datum/design/cyberpunk_item_module/assault_barrel/t3
	name = "Starlight Assault Barrel T3"
	id = "starlight_assault_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/assault_barrel/t3

/datum/design/cyberpunk_item_module/lmg_barrel/t2
	name = "Starlight Machine Gun Barrel T2"
	id = "starlight_lmg_barrel_t2"
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel/t2

/datum/design/cyberpunk_item_module/lmg_barrel/t3
	name = "Starlight Machine Gun Barrel T3"
	id = "starlight_lmg_barrel_t3"
	build_path = /obj/item/cyberpunk_item_module/lmg_barrel/t3

/datum/design/cyberpunk_item_module/rocket_barrel/t2
	name = "Starlight Launcher Tube T2"
	id = "starlight_launcher_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel/t2

/datum/design/cyberpunk_item_module/rocket_barrel/t3
	name = "Starlight Launcher Tube T3"
	id = "starlight_launcher_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/rocket_barrel/t3

/datum/design/cyberpunk_item_module/shotgun_tube/t2
	name = "Starlight Shotgun Tube T2"
	id = "starlight_shotgun_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube/t2

/datum/design/cyberpunk_item_module/shotgun_tube/t3
	name = "Starlight Shotgun Tube T3"
	id = "starlight_shotgun_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/shotgun_tube/t3

/datum/design/cyberpunk_item_module/sniper_chamber/t2
	name = "Starlight Sniper Chamber T2"
	id = "starlight_sniper_chamber_t2"
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber/t2

/datum/design/cyberpunk_item_module/sniper_chamber/t3
	name = "Starlight Sniper Chamber T3"
	id = "starlight_sniper_chamber_t3"
	build_path = /obj/item/cyberpunk_item_module/sniper_chamber/t3

/datum/design/cyberpunk_item_module/assault_magwell_223/t2
	name = "Starlight .223 Assault Magwell T2"
	id = "starlight_assault_magwell_223_t2"
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223/t2

/datum/design/cyberpunk_item_module/assault_magwell_223/t3
	name = "Starlight .223 Assault Magwell T3"
	id = "starlight_assault_magwell_223_t3"
	build_path = /obj/item/cyberpunk_item_module/assault_magwell_223/t3

/datum/design/cyberpunk_item_module/lmg_feed_223/t2
	name = "Starlight .223 Belt Feed T2"
	id = "starlight_lmg_feed_223_t2"
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223/t2

/datum/design/cyberpunk_item_module/lmg_feed_223/t3
	name = "Starlight .223 Belt Feed T3"
	id = "starlight_lmg_feed_223_t3"
	build_path = /obj/item/cyberpunk_item_module/lmg_feed_223/t3

/datum/design/cyberpunk_item_module/rocket_tube/t2
	name = "Starlight Rocket Launch Tube T2"
	id = "starlight_rocket_tube_t2"
	build_path = /obj/item/cyberpunk_item_module/rocket_tube/t2

/datum/design/cyberpunk_item_module/rocket_tube/t3
	name = "Starlight Rocket Launch Tube T3"
	id = "starlight_rocket_tube_t3"
	build_path = /obj/item/cyberpunk_item_module/rocket_tube/t3

/datum/design/cyberpunk_item_module/laser_emitter/t2
	name = "Starlight Laser Emitter T2"
	id = "starlight_laser_emitter_t2"
	build_path = /obj/item/cyberpunk_item_module/laser_emitter/t2

/datum/design/cyberpunk_item_module/laser_emitter/t3
	name = "Starlight Laser Emitter T3"
	id = "starlight_laser_emitter_t3"
	build_path = /obj/item/cyberpunk_item_module/laser_emitter/t3

/datum/design/cyberpunk_item_module/plasma_emitter/t2
	name = "Starlight Plasma Emitter T2"
	id = "starlight_plasma_emitter_t2"
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter/t2

/datum/design/cyberpunk_item_module/plasma_emitter/t3
	name = "Starlight Plasma Emitter T3"
	id = "starlight_plasma_emitter_t3"
	build_path = /obj/item/cyberpunk_item_module/plasma_emitter/t3

/datum/design/cyberpunk_weapon
	name = "Cyberpunk Modular Weapon"
	desc = "A Cyberpunk 13 modular weapon frame."
	id = "cyberpunk_weapon"
	build_type = PROTOLATHE | AUTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_ENGINEERING)
//CYBERPUNK BUILD - rebuild and delete before release
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/cyberpunk_weapon/revolver_frame
	name = "Modular Revolver Frame"
	id = "cyberpunk_revolver_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk

/datum/design/cyberpunk_weapon/knife_frame
	name = "Modular Physical Melee Base"
	id = "cyberpunk_knife_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk

/datum/design/cyberpunk_weapon/energy_melee_base
	name = "Modular Energy Melee Base"
	id = "cyberpunk_energy_melee_base"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/energy

/datum/design/cyberpunk_weapon/pistol_frame
	name = "Modular Pistol Frame"
	id = "cyberpunk_pistol_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk

/datum/design/cyberpunk_weapon/smg_frame
	name = "Modular Ballistic Weapon Base"
	id = "cyberpunk_smg_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk

/datum/design/cyberpunk_weapon/rifle_frame
	name = "Modular Rifle Frame"
	id = "cyberpunk_rifle_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk

/datum/design/cyberpunk_weapon/shotgun_frame
	name = "Modular Shotgun Frame"
	id = "cyberpunk_shotgun_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/shotgun/cyberpunk

/datum/design/cyberpunk_weapon/sniper_frame
	name = "Modular Sniper Frame"
	id = "cyberpunk_sniper_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/rifle/boltaction/cyberpunk

/datum/design/cyberpunk_weapon/assault_frame
	name = "Modular Assault Rifle Frame"
	id = "cyberpunk_assault_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/ar/cyberpunk

/datum/design/cyberpunk_weapon/lmg_frame
	name = "Modular Machine Gun Frame"
	id = "cyberpunk_lmg_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/l6_saw/cyberpunk

/datum/design/cyberpunk_weapon/rocket_frame
	name = "Modular Rocket Launcher Frame"
	id = "cyberpunk_rocket_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 14, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rocketlauncher/cyberpunk

/datum/design/cyberpunk_weapon/energy_frame
	name = "Modular Energy Weapon Base"
	id = "cyberpunk_energy_frame"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/energy/laser/cyberpunk

/datum/design/cyberpunk_weapon/revolver_frame_polymer
	name = "Polymer Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/polymer

/datum/design/cyberpunk_weapon/revolver_frame_ceramic
	name = "Ceramic Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/revolver_frame_plasteel
	name = "Plasteel Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/revolver_frame_composite
	name = "Composite Modular Revolver Frame"
	id = "cyberpunk_revolver_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/composite

/datum/design/cyberpunk_weapon/knife_frame_polymer
	name = "Polymer Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/polymer

/datum/design/cyberpunk_weapon/knife_frame_ceramic
	name = "Ceramic Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/knife_frame_plasteel
	name = "Plasteel Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/knife_frame_composite
	name = "Composite Modular Physical Melee Base"
	id = "cyberpunk_knife_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/composite

/datum/design/cyberpunk_weapon/pistol_frame_polymer
	name = "Polymer Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/polymer

/datum/design/cyberpunk_weapon/pistol_frame_ceramic
	name = "Ceramic Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/pistol_frame_plasteel
	name = "Plasteel Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/pistol_frame_composite
	name = "Composite Modular Pistol Frame"
	id = "cyberpunk_pistol_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/composite

/datum/design/cyberpunk_weapon/smg_frame_polymer
	name = "Polymer Modular SMG Frame"
	id = "cyberpunk_smg_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/polymer

/datum/design/cyberpunk_weapon/smg_frame_ceramic
	name = "Ceramic Modular SMG Frame"
	id = "cyberpunk_smg_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/smg_frame_plasteel
	name = "Plasteel Modular SMG Frame"
	id = "cyberpunk_smg_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/smg_frame_composite
	name = "Composite Modular SMG Frame"
	id = "cyberpunk_smg_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/composite

/datum/design/cyberpunk_weapon/rifle_frame_polymer
	name = "Polymer Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_polymer"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 8, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/polymer

/datum/design/cyberpunk_weapon/rifle_frame_ceramic
	name = "Ceramic Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_ceramic"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/ceramic

/datum/design/cyberpunk_weapon/rifle_frame_plasteel
	name = "Plasteel Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/plasteel

/datum/design/cyberpunk_weapon/rifle_frame_composite
	name = "Composite Modular Rifle Frame"
	id = "cyberpunk_rifle_frame_composite"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/composite

/datum/design/cyberpunk_weapon/sentinel_revolver
	name = "Sentinel Modular Revolver"
	id = "cyberpunk_sentinel_revolver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/sentinel

/datum/design/cyberpunk_weapon/bruiser_revolver
	name = "Bruiser Modular Revolver"
	id = "cyberpunk_bruiser_revolver"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/revolver/cyberpunk/bruiser

/datum/design/cyberpunk_weapon/sidearm_pistol
	name = "Sidearm Modular Pistol"
	id = "cyberpunk_sidearm_pistol"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/sidearm

/datum/design/cyberpunk_weapon/handcannon_pistol
	name = "Handcannon Modular Pistol"
	id = "cyberpunk_handcannon_pistol"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/pistol/cyberpunk/handcannon

/datum/design/cyberpunk_weapon/sprinter_smg
	name = "Sprinter Modular SMG"
	id = "cyberpunk_sprinter_smg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/sprinter

/datum/design/cyberpunk_weapon/breacher_smg
	name = "Breacher Modular SMG"
	id = "cyberpunk_breacher_smg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/proto/cyberpunk/breacher

/datum/design/cyberpunk_weapon/marksman_rifle
	name = "Marksman Modular Rifle"
	id = "cyberpunk_marksman_rifle"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/marksman

/datum/design/cyberpunk_weapon/patrol_rifle
	name = "Patrol Modular Rifle"
	id = "cyberpunk_patrol_rifle"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 11, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/cyberpunk/patrol

/datum/design/cyberpunk_weapon/room_clearer_shotgun
	name = "Room-Clearer Modular Shotgun"
	id = "cyberpunk_room_clearer_shotgun"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/shotgun/cyberpunk/room_clearer

/datum/design/cyberpunk_weapon/longwatch_sniper
	name = "Longwatch Modular Sniper"
	id = "cyberpunk_longwatch_sniper"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 13, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/rifle/boltaction/cyberpunk/longwatch

/datum/design/cyberpunk_weapon/streetline_assault
	name = "Streetline Modular Assault Rifle"
	id = "cyberpunk_streetline_assault"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/ar/cyberpunk/streetline

/datum/design/cyberpunk_weapon/suppressor_lmg
	name = "Suppressor Modular LMG"
	id = "cyberpunk_suppressor_lmg"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 16, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/gun/ballistic/automatic/l6_saw/cyberpunk/suppressor

/datum/design/cyberpunk_weapon/punchline_launcher
	name = "Punchline Modular Rocket Launcher"
	id = "cyberpunk_punchline_launcher"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 18, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 5, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/ballistic/rocketlauncher/cyberpunk/punchline

/datum/design/cyberpunk_weapon/radiant_laser
	name = "Radiant Modular Laser"
	id = "cyberpunk_radiant_laser"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 11, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/gun/energy/laser/cyberpunk/radiant

/datum/design/cyberpunk_weapon/plasma_arc
	name = "Plasma Arc Modular Projector"
	id = "cyberpunk_plasma_arc"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 12, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plasma = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/gun/energy/laser/cyberpunk/plasma

/datum/design/cyberpunk_weapon/razor_knife
	name = "Razor Modular Knife"
	id = "cyberpunk_razor_knife"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/razor

/datum/design/cyberpunk_weapon/puncture_knife
	name = "Puncture Modular Knife"
	id = "cyberpunk_puncture_knife"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/puncture

/datum/design/cyberpunk_weapon/breaker_club
	name = "Breaker Modular Club"
	id = "cyberpunk_breaker_club"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/club

/datum/design/cyberpunk_weapon/linebreaker_sword
	name = "Linebreaker Modular Two-Handed Sword"
	id = "cyberpunk_linebreaker_sword"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_sword

/datum/design/cyberpunk_weapon/piledriver_hammer
	name = "Pile-Driver Modular Two-Handed Hammer"
	id = "cyberpunk_piledriver_hammer"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_hammer

/datum/design/cyberpunk_weapon/streetcutter_axe
	name = "Street-Cutter Modular Axe"
	id = "cyberpunk_streetcutter_axe"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/axe

/datum/design/cyberpunk_weapon/gatecrack_axe
	name = "Gatecrack Modular Two-Handed Axe"
	id = "cyberpunk_gatecrack_axe"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 9, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/twohand_axe

/datum/design/cyberpunk_weapon/needlepoint_rapier
	name = "Needlepoint Modular Rapier"
	id = "cyberpunk_needlepoint_rapier"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/rapier

/datum/design/cyberpunk_weapon/longreach_spear
	name = "Longreach Modular Spear"
	id = "cyberpunk_longreach_spear"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/spear

/datum/design/cyberpunk_weapon/crowdline_staff
	name = "Crowdline Modular Staff"
	id = "cyberpunk_crowdline_staff"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/knife/cyberpunk/staff

/datum/design/cyberpunk_weapon/hotline_energy_blade
	name = "Hotline Modular Energy Blade"
	id = "cyberpunk_hotline_energy_blade"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plasma = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/energy_blade

/datum/design/cyberpunk_weapon/crowdline_shock_staff
	name = "Crowdline Modular Shock Staff"
	id = "cyberpunk_crowdline_shock_staff"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/knife/cyberpunk/shock_staff

/datum/design/cyberpunk_item_module/armor_plate
	name = "Starlight Armor Plate"
	id = "starlight_armor_plate"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_plate

/datum/design/cyberpunk_item_module/armor_lining
	name = "Starlight Protective Lining"
	id = "starlight_protective_lining"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_lining

/datum/design/cyberpunk_item_module/armor_plate/t2
	name = "Starlight Armor Plate T2"
	id = "starlight_armor_plate_t2"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_plate/t2

/datum/design/cyberpunk_item_module/armor_plate/t3
	name = "Starlight Armor Plate T3"
	id = "starlight_armor_plate_t3"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 6, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_plate/t3

/datum/design/cyberpunk_item_module/armor_lining/t2
	name = "Starlight Protective Lining T2"
	id = "starlight_protective_lining_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_lining/t2

/datum/design/cyberpunk_item_module/armor_lining/t3
	name = "Starlight Protective Lining T3"
	id = "starlight_protective_lining_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/armor_lining/t3

/datum/design/cyberpunk_item_module/weight_reducer
	name = "Starlight Lightweight Frame"
	id = "starlight_lightweight_frame"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/weight_reducer

/datum/design/cyberpunk_item_module/weight_reducer/t2
	name = "Starlight Lightweight Frame T2"
	id = "starlight_lightweight_frame_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/weight_reducer/t2

/datum/design/cyberpunk_item_module/weight_reducer/t3
	name = "Starlight Lightweight Frame T3"
	id = "starlight_lightweight_frame_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/weight_reducer/t3

/datum/design/cyberpunk_item_module/mobility_servo
	name = "Starlight Mobility Servo"
	id = "starlight_mobility_servo"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/mobility_servo

/datum/design/cyberpunk_item_module/mobility_servo/t2
	name = "Starlight Mobility Servo T2"
	id = "starlight_mobility_servo_t2"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/mobility_servo/t2

/datum/design/cyberpunk_item_module/mobility_servo/t3
	name = "Starlight Mobility Servo T3"
	id = "starlight_mobility_servo_t3"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/mobility_servo/t3

/datum/design/cyberpunk_item_module/reactive_hardener
	name = "Starlight Reactive Hardener"
	id = "starlight_reactive_hardener"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/reactive_hardener

/datum/design/cyberpunk_item_module/reactive_hardener/t2
	name = "Starlight Reactive Hardener T2"
	id = "starlight_reactive_hardener_t2"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/reactive_hardener/t2

/datum/design/cyberpunk_item_module/reactive_hardener/t3
	name = "Starlight Reactive Hardener T3"
	id = "starlight_reactive_hardener_t3"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/reactive_hardener/t3

/datum/design/cyberpunk_item_module/impact_gel
	name = "Starlight Impact Gel"
	id = "starlight_impact_gel"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/impact_gel

/datum/design/cyberpunk_item_module/impact_gel/t2
	name = "Starlight Impact Gel T2"
	id = "starlight_impact_gel_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/impact_gel/t2

/datum/design/cyberpunk_item_module/impact_gel/t3
	name = "Starlight Impact Gel T3"
	id = "starlight_impact_gel_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/impact_gel/t3

/datum/design/cyberpunk_item_module/ballistic_weave
	name = "Starlight Ballistic Weave"
	id = "starlight_ballistic_weave"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/ballistic_weave

/datum/design/cyberpunk_item_module/ballistic_weave/t2
	name = "Starlight Ballistic Weave T2"
	id = "starlight_ballistic_weave_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/ballistic_weave/t2

/datum/design/cyberpunk_item_module/ballistic_weave/t3
	name = "Starlight Ballistic Weave T3"
	id = "starlight_ballistic_weave_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/ballistic_weave/t3

/datum/design/cyberpunk_item_module/ablative_mesh
	name = "Starlight Ablative Mesh"
	id = "starlight_ablative_mesh"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/ablative_mesh

/datum/design/cyberpunk_item_module/ablative_mesh/t2
	name = "Starlight Ablative Mesh T2"
	id = "starlight_ablative_mesh_t2"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/ablative_mesh/t2

/datum/design/cyberpunk_item_module/ablative_mesh/t3
	name = "Starlight Ablative Mesh T3"
	id = "starlight_ablative_mesh_t3"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/ablative_mesh/t3

/datum/design/cyberpunk_item_module/insulation_lining
	name = "Starlight Insulation Lining"
	id = "starlight_insulation_lining"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/insulation_lining

/datum/design/cyberpunk_item_module/insulation_lining/t2
	name = "Starlight Insulation Lining T2"
	id = "starlight_insulation_lining_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/insulation_lining/t2

/datum/design/cyberpunk_item_module/insulation_lining/t3
	name = "Starlight Insulation Lining T3"
	id = "starlight_insulation_lining_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/insulation_lining/t3

/datum/design/cyberpunk_item_module/chemseal_lining
	name = "Starlight Chemseal Lining"
	id = "starlight_chemseal_lining"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/chemseal_lining

/datum/design/cyberpunk_item_module/chemseal_lining/t2
	name = "Starlight Chemseal Lining T2"
	id = "starlight_chemseal_lining_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/chemseal_lining/t2

/datum/design/cyberpunk_item_module/chemseal_lining/t3
	name = "Starlight Chemseal Lining T3"
	id = "starlight_chemseal_lining_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/chemseal_lining/t3

/datum/design/cyberpunk_item_module/sensor_bus
	name = "Starlight Sensor Bus"
	id = "starlight_sensor_bus"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/sensor_bus

/datum/design/cyberpunk_item_module/sensor_bus/t2
	name = "Starlight Sensor Bus T2"
	id = "starlight_sensor_bus_t2"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/cyberpunk_item_module/sensor_bus/t2

/datum/design/cyberpunk_item_module/sensor_bus/t3
	name = "Starlight Sensor Bus T3"
	id = "starlight_sensor_bus_t3"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/sensor_bus/t3

/datum/design/cyberpunk_item_module/blast_padding
	name = "Starlight Blast Padding"
	id = "starlight_blast_padding"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/blast_padding

/datum/design/cyberpunk_item_module/blast_padding/t2
	name = "Starlight Blast Padding T2"
	id = "starlight_blast_padding_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/blast_padding/t2

/datum/design/cyberpunk_item_module/blast_padding/t3
	name = "Starlight Blast Padding T3"
	id = "starlight_blast_padding_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/blast_padding/t3

/datum/design/cyberpunk_item_module/trauma_mesh
	name = "Starlight Trauma Mesh"
	id = "starlight_trauma_mesh"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/trauma_mesh

/datum/design/cyberpunk_item_module/trauma_mesh/t2
	name = "Starlight Trauma Mesh T2"
	id = "starlight_trauma_mesh_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/trauma_mesh/t2

/datum/design/cyberpunk_item_module/trauma_mesh/t3
	name = "Starlight Trauma Mesh T3"
	id = "starlight_trauma_mesh_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/trauma_mesh/t3

/datum/design/cyberpunk_item_module/deflection_laminate
	name = "Starlight Deflection Laminate"
	id = "starlight_deflection_laminate"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/deflection_laminate

/datum/design/cyberpunk_item_module/deflection_laminate/t2
	name = "Starlight Deflection Laminate T2"
	id = "starlight_deflection_laminate_t2"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/deflection_laminate/t2

/datum/design/cyberpunk_item_module/deflection_laminate/t3
	name = "Starlight Deflection Laminate T3"
	id = "starlight_deflection_laminate_t3"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/deflection_laminate/t3

/datum/design/cyberpunk_item_module/grounding_bus
	name = "Starlight Grounding Bus"
	id = "starlight_grounding_bus"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/grounding_bus

/datum/design/cyberpunk_item_module/grounding_bus/t2
	name = "Starlight Grounding Bus T2"
	id = "starlight_grounding_bus_t2"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/grounding_bus/t2

/datum/design/cyberpunk_item_module/grounding_bus/t3
	name = "Starlight Grounding Bus T3"
	id = "starlight_grounding_bus_t3"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/grounding_bus/t3

/datum/design/cyberpunk_item_module/medfoam_injector
	name = "Starlight Medfoam Injector"
	id = "starlight_medfoam_injector"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/medfoam_injector

/datum/design/cyberpunk_item_module/medfoam_injector/t2
	name = "Starlight Medfoam Injector T2"
	id = "starlight_medfoam_injector_t2"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/medfoam_injector/t2

/datum/design/cyberpunk_item_module/medfoam_injector/t3
	name = "Starlight Medfoam Injector T3"
	id = "starlight_medfoam_injector_t3"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/gold = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/cyberpunk_item_module/medfoam_injector/t3

/datum/design/cyberpunk_modular_equipment
	name = "Cyberpunk Modular Equipment"
	desc = "A modular equipment shell. The fabricator asks for a material before printing; protection is rebuilt from form, material, manufacturer and installed module tiers."
	id = "cyberpunk_modular_equipment"
	build_type = PROTOLATHE | AUTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk
	category = list(RND_CATEGORY_EQUIPMENT + RND_SUBCATEGORY_EQUIPMENT_SECURITY)
//CYBERPUNK BUILD - rebuild and delete before release
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY | DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_SCIENCE

/datum/design/cyberpunk_modular_equipment/vest
	name = "Modular Vest Shell"
	id = "cyberpunk_vest_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/helmet
	name = "Modular Helmet Shell"
	id = "cyberpunk_helmet_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/bracers
	name = "Modular Bracers Shell"
	id = "cyberpunk_bracers_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/boots
	name = "Modular Boots Shell"
	id = "cyberpunk_boots_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/suit
	name = "Modular Armor Suit Shell"
	id = "cyberpunk_suit_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/gloves
	name = "Modular Gloves Shell"
	id = "cyberpunk_gloves_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/mask
	name = "Modular Mask Shell"
	id = "cyberpunk_mask_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk
	cyberpunk_material_options = list("fabric", "wood", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/visor
	name = "Modular Visor Shell"
	id = "cyberpunk_visor_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/glasses/cyberpunk
	cyberpunk_material_options = list("fabric", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/collar
	name = "Modular Collar Shell"
	id = "cyberpunk_collar_shell"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk
	cyberpunk_material_options = list("fabric", "ceramic", "plasteel", "composite")

/datum/design/cyberpunk_modular_equipment/vest_fabric
	name = "Modular Vest - Ballistic Fabric"
	id = "cyberpunk_vest_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk

/datum/design/cyberpunk_modular_equipment/vest_wood
	name = "Modular Vest - Laminated Wood"
	id = "cyberpunk_vest_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/vest_ceramic
	name = "Modular Vest - Ceramic"
	id = "cyberpunk_vest_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/vest_plasteel
	name = "Modular Vest - Plasteel"
	id = "cyberpunk_vest_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/vest_composite
	name = "Modular Vest - Smart Composite"
	id = "cyberpunk_vest_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/helmet_fabric
	name = "Modular Helmet - Ballistic Fabric"
	id = "cyberpunk_helmet_fabric"
	build_path = /obj/item/clothing/head/helmet/cyberpunk

/datum/design/cyberpunk_modular_equipment/helmet_wood
	name = "Modular Helmet - Laminated Wood"
	id = "cyberpunk_helmet_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/helmet_ceramic
	name = "Modular Helmet - Ceramic"
	id = "cyberpunk_helmet_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/helmet_plasteel
	name = "Modular Helmet - Plasteel"
	id = "cyberpunk_helmet_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/helmet_composite
	name = "Modular Helmet - Smart Composite"
	id = "cyberpunk_helmet_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/bracers_fabric
	name = "Modular Bracers - Ballistic Fabric"
	id = "cyberpunk_bracers_fabric"
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk

/datum/design/cyberpunk_modular_equipment/bracers_wood
	name = "Modular Bracers - Laminated Wood"
	id = "cyberpunk_bracers_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/bracers_ceramic
	name = "Modular Bracers - Ceramic"
	id = "cyberpunk_bracers_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/bracers_plasteel
	name = "Modular Bracers - Plasteel"
	id = "cyberpunk_bracers_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/bracers_composite
	name = "Modular Bracers - Smart Composite"
	id = "cyberpunk_bracers_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/boots_fabric
	name = "Modular Boots - Ballistic Fabric"
	id = "cyberpunk_boots_fabric"
	build_path = /obj/item/clothing/shoes/cyberpunk

/datum/design/cyberpunk_modular_equipment/boots_wood
	name = "Modular Boots - Laminated Wood"
	id = "cyberpunk_boots_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/boots_ceramic
	name = "Modular Boots - Ceramic"
	id = "cyberpunk_boots_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/boots_plasteel
	name = "Modular Boots - Plasteel"
	id = "cyberpunk_boots_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/boots_composite
	name = "Modular Boots - Smart Composite"
	id = "cyberpunk_boots_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/suit_fabric
	name = "Modular Armor Suit - Ballistic Fabric"
	id = "cyberpunk_suit_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk

/datum/design/cyberpunk_modular_equipment/suit_wood
	name = "Modular Armor Suit - Laminated Wood"
	id = "cyberpunk_suit_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 8, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/suit_ceramic
	name = "Modular Armor Suit - Ceramic"
	id = "cyberpunk_suit_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 7, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/suit_plasteel
	name = "Modular Armor Suit - Plasteel"
	id = "cyberpunk_suit_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 8, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/suit_composite
	name = "Modular Armor Suit - Smart Composite"
	id = "cyberpunk_suit_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/gloves_fabric
	name = "Modular Gloves - Ballistic Fabric"
	id = "cyberpunk_gloves_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk

/datum/design/cyberpunk_modular_equipment/gloves_wood
	name = "Modular Gloves - Laminated Wood"
	id = "cyberpunk_gloves_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/gloves_ceramic
	name = "Modular Gloves - Ceramic"
	id = "cyberpunk_gloves_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/gloves_plasteel
	name = "Modular Gloves - Plasteel"
	id = "cyberpunk_gloves_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/gloves_composite
	name = "Modular Gloves - Smart Composite"
	id = "cyberpunk_gloves_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/mask_fabric
	name = "Modular Mask - Ballistic Fabric"
	id = "cyberpunk_mask_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk

/datum/design/cyberpunk_modular_equipment/mask_wood
	name = "Modular Mask - Laminated Wood"
	id = "cyberpunk_mask_wood"
	materials = list(/datum/material/wood = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk/wood

/datum/design/cyberpunk_modular_equipment/mask_ceramic
	name = "Modular Mask - Ceramic"
	id = "cyberpunk_mask_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/mask_plasteel
	name = "Modular Mask - Plasteel"
	id = "cyberpunk_mask_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/mask_composite
	name = "Modular Mask - Smart Composite"
	id = "cyberpunk_mask_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/visor_fabric
	name = "Modular Visor - Ballistic Fabric"
	id = "cyberpunk_visor_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/glasses/cyberpunk

/datum/design/cyberpunk_modular_equipment/visor_ceramic
	name = "Modular Visor - Ceramic"
	id = "cyberpunk_visor_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/visor_plasteel
	name = "Modular Visor - Plasteel"
	id = "cyberpunk_visor_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/visor_composite
	name = "Modular Visor - Smart Composite"
	id = "cyberpunk_visor_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/collar_fabric
	name = "Modular Collar - Ballistic Fabric"
	id = "cyberpunk_collar_fabric"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk

/datum/design/cyberpunk_modular_equipment/collar_ceramic
	name = "Modular Collar - Ceramic"
	id = "cyberpunk_collar_ceramic"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk/ceramic

/datum/design/cyberpunk_modular_equipment/collar_plasteel
	name = "Modular Collar - Plasteel"
	id = "cyberpunk_collar_plasteel"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk/plasteel

/datum/design/cyberpunk_modular_equipment/collar_composite
	name = "Modular Collar - Smart Composite"
	id = "cyberpunk_collar_composite"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/titanium = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk/composite

/datum/design/cyberpunk_modular_equipment/preset_benn_light_vest
	name = "Preset - Benn Stealth Vest"
	id = "cyberpunk_preset_benn_light_vest"
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/benn_light

/datum/design/cyberpunk_modular_equipment/preset_ryaznov_assault_vest
	name = "Preset - Ryaznov Assault Vest"
	id = "cyberpunk_preset_ryaznov_assault_vest"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/glass = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/ryaznov_heavy

/datum/design/cyberpunk_modular_equipment/preset_starlight_skirmisher_vest
	name = "Preset - Starlight Skirmisher Vest"
	id = "cyberpunk_preset_starlight_skirmisher_vest"
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/starlight_skirmisher

/datum/design/cyberpunk_modular_equipment/preset_ryaznov_bulwark
	name = "Preset - Ryaznov Bulwark Suit"
	id = "cyberpunk_preset_ryaznov_bulwark"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 10, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/ryaznov_bulwark

/datum/design/cyberpunk_modular_equipment/preset_benn_mirage
	name = "Preset - Benn Mirage Suit"
	id = "cyberpunk_preset_benn_mirage"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/benn_mirage

/datum/design/cyberpunk_modular_equipment/preset_starlight_response
	name = "Preset - Starlight Response Suit"
	id = "cyberpunk_preset_starlight_response"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/starlight_response

/datum/design/cyberpunk_modular_equipment/preset_benn_optic
	name = "Preset - Benn Optic Visor"
	id = "cyberpunk_preset_benn_optic"
	build_path = /obj/item/clothing/glasses/cyberpunk/benn_optic

/datum/design/cyberpunk_modular_equipment/preset_starlight_filter_mask
	name = "Preset - Starlight Filter Mask"
	id = "cyberpunk_preset_starlight_filter_mask"
	build_path = /obj/item/clothing/mask/cyberpunk/starlight_filter

/datum/design/cyberpunk_modular_equipment/preset_ryaznov_guard_collar
	name = "Preset - Ryaznov Guard Collar"
	id = "cyberpunk_preset_ryaznov_guard_collar"
	build_path = /obj/item/clothing/neck/cyberpunk/ryaznov_guard

/datum/design/cyberpunk_modular_equipment/preset_benn_grip_gloves
	name = "Preset - Benn Grip Gloves"
	id = "cyberpunk_preset_benn_grip_gloves"
	build_path = /obj/item/clothing/gloves/cyberpunk/benn_grip

/datum/design/cyberpunk_modular_equipment/preset_ryaznov_knuckle_gloves
	name = "Preset - Ryaznov Knuckle Gloves"
	id = "cyberpunk_preset_ryaznov_knuckle_gloves"
	build_path = /obj/item/clothing/gloves/cyberpunk/ryaznov_knuckle

/datum/design/cyberpunk_modular_equipment/preset_street_guard_vest
	name = "Preset - Street Guard Vest"
	id = "cyberpunk_preset_street_guard_vest"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 5, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/street_guard

/datum/design/cyberpunk_modular_equipment/preset_runner_vest
	name = "Preset - Runner Vest"
	id = "cyberpunk_preset_runner_vest"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 6, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/runner

/datum/design/cyberpunk_modular_equipment/preset_blast_vest
	name = "Preset - Blast Vest"
	id = "cyberpunk_preset_blast_vest"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 7, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/blast

/datum/design/cyberpunk_modular_equipment/preset_anti_energy_vest
	name = "Preset - Anti-Energy Vest"
	id = "cyberpunk_preset_anti_energy_vest"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 5, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/vest/cyberpunk/anti_energy

/datum/design/cyberpunk_modular_equipment/preset_breacher_suit
	name = "Preset - Breacher Suit"
	id = "cyberpunk_preset_breacher_suit"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 11, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/breacher

/datum/design/cyberpunk_modular_equipment/preset_firebreak_suit
	name = "Preset - Firebreak Suit"
	id = "cyberpunk_preset_firebreak_suit"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 8, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 5, /datum/material/silver = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/firebreak

/datum/design/cyberpunk_modular_equipment/preset_patrol_suit
	name = "Preset - Patrol Suit"
	id = "cyberpunk_preset_patrol_suit"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 8, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/clothing/suit/armor/cyberpunk/patrol

/datum/design/cyberpunk_modular_equipment/preset_patrol_helmet
	name = "Preset - Patrol Helmet"
	id = "cyberpunk_preset_patrol_helmet"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/patrol

/datum/design/cyberpunk_modular_equipment/preset_breacher_helmet
	name = "Preset - Breacher Helmet"
	id = "cyberpunk_preset_breacher_helmet"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/breacher

/datum/design/cyberpunk_modular_equipment/preset_anti_energy_helmet
	name = "Preset - Anti-Energy Helmet"
	id = "cyberpunk_preset_anti_energy_helmet"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/head/helmet/cyberpunk/anti_energy

/datum/design/cyberpunk_modular_equipment/preset_runner_boots
	name = "Preset - Runner Boots"
	id = "cyberpunk_preset_runner_boots"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/runner

/datum/design/cyberpunk_modular_equipment/preset_patrol_boots
	name = "Preset - Patrol Boots"
	id = "cyberpunk_preset_patrol_boots"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/patrol

/datum/design/cyberpunk_modular_equipment/preset_sealed_boots
	name = "Preset - Sealed Boots"
	id = "cyberpunk_preset_sealed_boots"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/shoes/cyberpunk/sealed

/datum/design/cyberpunk_modular_equipment/preset_tech_gloves
	name = "Preset - Tech Gloves"
	id = "cyberpunk_preset_tech_gloves"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/tech

/datum/design/cyberpunk_modular_equipment/preset_patrol_gloves
	name = "Preset - Patrol Gloves"
	id = "cyberpunk_preset_patrol_gloves"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/cyberpunk/patrol

/datum/design/cyberpunk_modular_equipment/preset_guard_bracers
	name = "Preset - Guard Bracers"
	id = "cyberpunk_preset_guard_bracers"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/iron = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/guard

/datum/design/cyberpunk_modular_equipment/preset_bulwark_bracers
	name = "Preset - Bulwark Bracers"
	id = "cyberpunk_preset_bulwark_bracers"
	materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 5, /datum/material/titanium = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/gloves/bracer/cyberpunk/bulwark

/datum/design/cyberpunk_modular_equipment/preset_sealed_mask
	name = "Preset - Sealed Mask"
	id = "cyberpunk_preset_sealed_mask"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/mask/cyberpunk/sealed

/datum/design/cyberpunk_modular_equipment/preset_street_mask
	name = "Preset - Street Mask"
	id = "cyberpunk_preset_street_mask"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 3, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/clothing/mask/cyberpunk/street

/datum/design/cyberpunk_modular_equipment/preset_threat_visor
	name = "Preset - Threat-Scan Visor"
	id = "cyberpunk_preset_threat_visor"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/cyberpunk/threat

/datum/design/cyberpunk_modular_equipment/preset_industrial_visor
	name = "Preset - Industrial Visor"
	id = "cyberpunk_preset_industrial_visor"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 4, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/glasses/cyberpunk/industrial

/datum/design/cyberpunk_modular_equipment/preset_sealed_collar
	name = "Preset - Sealed Collar"
	id = "cyberpunk_preset_sealed_collar"
	materials = list(/datum/material/plastic = SMALL_MATERIAL_AMOUNT * 4, /datum/material/glass = SMALL_MATERIAL_AMOUNT * 3, /datum/material/silver = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk/sealed

/datum/design/cyberpunk_modular_equipment/preset_patrol_collar
	name = "Preset - Patrol Collar"
	id = "cyberpunk_preset_patrol_collar"
	materials = list(/datum/material/glass = SMALL_MATERIAL_AMOUNT * 2, /datum/material/plastic = SMALL_MATERIAL_AMOUNT * 2, /datum/material/iron = SMALL_MATERIAL_AMOUNT)
	build_path = /obj/item/clothing/neck/cyberpunk/patrol

/obj/item/proc/research_scan(mob/user)
	/// Research prospects, including boostable nodes and point values. Deliver to a console to know whether the boosts have already been used.
	var/list/research_msg = list("<font color='purple'>Research prospects:</font> ")
	///Separator between the items on the list
	var/sep = ""
	///Nodes that can be boosted
	var/list/boostable_nodes = techweb_item_unlock_check(src)
	if (boostable_nodes)
		for(var/id in boostable_nodes)
			var/datum/techweb_node/node = SSresearch.techweb_node_by_id(id)
			if(!node)
				continue
			research_msg += sep
			research_msg += node.display_name
			sep = ", "
	var/list/points = techweb_item_point_check(src)
	if (length(points))
		sep = ", "
		research_msg += techweb_point_display_generic(points)

	if (!sep) // nothing was shown
		research_msg += "None"

	// Extractable materials. Only shows the names, not the amounts.
	research_msg += ".<br><font color='purple'>Extractable materials:</font> "
	if (length(custom_materials))
		sep = ""
		for(var/mat in custom_materials)
			research_msg += sep
			research_msg += CallMaterialName(mat)
			sep = ", "
	else
		research_msg += "None"
	research_msg += "."
	return research_msg.Join()

/obj/item/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	add_fingerprint(usr)
	return ..()

/obj/item/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_ADD_FANTASY_AFFIX])
		if(!check_rights(R_FUN))
			return
		//gathering all affixes that make sense for this item
		var/list/prefixes = list()
		var/list/suffixes = list()
		for(var/datum/fantasy_affix/affix_choice as anything in subtypesof(/datum/fantasy_affix))
			affix_choice = new affix_choice()
			if(!affix_choice.validate(src))
				qdel(affix_choice)
			else
				if(affix_choice.placement & AFFIX_PREFIX)
					prefixes[affix_choice.name] = affix_choice
				else
					suffixes[affix_choice.name] = affix_choice
		//making it more presentable here
		var/list/affixes = list("---PREFIXES---")
		affixes.Add(prefixes)
		affixes.Add("---SUFFIXES---")
		affixes.Add(suffixes)
		//admin picks, cleanup the ones we didn't do and handle chosen
		var/picked_affix_name = tgui_input_list(usr, "Affix to add to [src]", "Enchant [src]", affixes)
		if(isnull(picked_affix_name))
			return
		if(!affixes[picked_affix_name] || QDELETED(src))
			return
		var/datum/fantasy_affix/affix = affixes[picked_affix_name]
		affixes.Remove(affix)
		var/fantasy_quality = 0
		if(affix.alignment & AFFIX_GOOD)
			fantasy_quality++
		else
			fantasy_quality--
		//name gets changed by the component so i want to store it for feedback later
		var/before_name = name
		//naming these vars that i'm putting into the fantasy component to make it more readable
		var/canFail = FALSE
		var/announce = FALSE
		//Apply fantasy with affix. failing this should never happen, but if it does it should not be silent.
		if(AddComponent(/datum/component/fantasy, fantasy_quality, list(affix), canFail, announce) == COMPONENT_INCOMPATIBLE)
			to_chat(usr, span_warning("Fantasy component not compatible with [src]."))
			CRASH("fantasy component incompatible with object of type: [type]")
		to_chat(usr, span_notice("[before_name] now has [picked_affix_name]!"))
		log_admin("[key_name(usr)] has added [picked_affix_name] fantasy affix to [before_name]")
		message_admins(span_notice("[key_name(usr)] has added [picked_affix_name] fantasy affix to [before_name]"))

/obj/item/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(. || !user || anchored)
		return
	return attempt_pickup(user)

/obj/item/proc/attempt_pickup(mob/living/user, skip_grav = FALSE)
	. = TRUE

	if(!(interaction_flags_item & INTERACT_ITEM_ATTACK_HAND_PICKUP)) //See if we're supposed to auto pickup.
		return

	if(!(user.mobility_flags & MOBILITY_PICKUP))
		return

	if(!skip_grav)
		//Heavy gravity makes picking up things very slow.
		var/grav = user.has_gravity()
		if(grav > STANDARD_GRAVITY)
			var/grav_power = min(3,grav - STANDARD_GRAVITY)
			to_chat(user,span_notice("You start picking up [src]..."))
			if(!do_after(user, 30 * grav_power, src))
				return

	//If the item is in a storage item, take it out
	var/outside_storage = !loc.atom_storage
	var/turf/storage_turf
	if(loc.atom_storage)
		//We want the pickup animation to play even if we're moving the item between movables. Unless the mob is not located on a turf.
		if(isturf(user.loc))
			storage_turf = get_turf(loc)
		if(!loc.atom_storage.remove_single(user, src, user, silent = TRUE))
			return
	if(QDELETED(src)) //moving it out of the storage destroyed it.
		return

	if(storage_turf)
		do_pickup_animation(user, storage_turf)

	if(throwing)
		throwing.finalize(FALSE)
	if(loc == user && outside_storage)
		if(!can_mob_unequip(user) || !user.temporarilyRemoveItemFromInventory(src))
			return

	. = FALSE
	pickup(user)
	add_fingerprint(user)
	if(!user.put_in_active_hand(src, ignore_animation = !outside_storage))
		user.dropItemToGround(src)
		return TRUE

/// Called when a mob is manually attempting to unequip the item
/// Returning FALSE will prevent the unequip from happening
/obj/item/proc/can_mob_unequip(mob/user)
	return TRUE

/obj/item/attack_paw(mob/user, list/modifiers)
	. = ..()
	if(. || !user || anchored)
		return
	return attempt_pickup(user)

/obj/item/attack_alien(mob/user, list/modifiers)
	var/mob/living/carbon/alien/ayy = user

	if(!ayy.can_hold_items(src))
		if(src in ayy.contents) // To stop Aliens having items stuck in their pockets
			ayy.dropItemToGround(src)
		to_chat(user, span_warning("Your claws aren't capable of such fine manipulation!"))
		return
	attack_paw(ayy, modifiers)

/obj/item/attack_robot(mob/living/silicon/robot/user)
	if(!istype(loc, /obj/item/robot_model))
		return
	if(user.low_power_mode) //can't equip modules with an empty cell.
		return
	user.activate_module(src)

// afterattack() and attack() prototypes moved to _onclick/item_attack.dm for consistency

/obj/item/proc/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(SEND_SIGNAL(src, COMSIG_ITEM_HIT_REACT, owner, hitby, attack_text, final_block_chance, damage, attack_type, damage_type) & COMPONENT_HIT_REACTION_BLOCK)
		return TRUE

	if(prob(final_block_chance))
		owner.visible_message(span_danger("[capitalize(owner.declent_ru(NOMINATIVE))] блокирует [attack_text] с помощью [declent_ru(GENITIVE)]!"))
		var/owner_turf = get_turf(owner)
		new block_effect(owner_turf, COLOR_YELLOW)
		playsound(src, block_sound, BLOCK_SOUND_VOLUME, vary = TRUE)
		return TRUE

/**
 * Handles someone talking INTO an item
 *
 * Commonly used by someone holding it and using .r or .l
 * Also used by radios
 *
 * * speaker - the atom that is doing the talking
 * * message - the message being spoken
 * * channel - the channel the message is being spoken on, only really used for radios
 * * spans - the spans of the message
 * * language - the language the message is in
 * * message_mods - any message mods that should be applied to the message
 *
 * Return a flag that modifies the original message
 */
/obj/item/proc/talk_into(atom/movable/speaker, message, channel, list/spans, datum/language/language, list/message_mods)
	return SEND_SIGNAL(src, COMSIG_ITEM_TALK_INTO, speaker, message, channel, spans, language, message_mods) || (ITALICS|REDUCE_RANGE)

/* sound procs, made so they can be overriden on subtypes */

/// executed when this item is thrown and hits a mob
/obj/item/proc/mob_throw_hit_sound_chain(target, volume)
	if(play_mob_throw_hit_sound(target, volume))
		return TRUE
	if(play_hit_sound(target, volume))
		return TRUE
	playsound(target, 'sound/items/weapons/throwtap.ogg', volume, TRUE, -1)
	return TRUE

/// executed when this item is thrown and lands on a turf
/obj/item/proc/throw_drop_sound_chain(volume)
	if(play_throw_drop_sound(volume))
		return TRUE
	if(play_drop_sound(volume))
		return TRUE
	return FALSE

/obj/item/proc/sound_chain(sound_to_play, volume = HALFWAY_SOUND_VOLUME, target = src)
	if(sound_to_play)
		playsound(target, sound_to_play, volume, sound_vary, ignore_walls = FALSE)
		return TRUE
	return FALSE

/// plays the pickup sound of this item.
/obj/item/proc/play_pickup_sound(volume = PICKUP_SOUND_VOLUME)
	return sound_chain(pickup_sound, volume)

/// plays the drop sound
/obj/item/proc/play_drop_sound(volume = DROP_SOUND_VOLUME)
	return sound_chain(drop_sound, volume)

/// plays the throw drop sound
/obj/item/proc/play_throw_drop_sound(volume = YEET_SOUND_VOLUME)
	return sound_chain(throw_drop_sound, volume)

/// plays the mob throw hit sound
/obj/item/proc/play_mob_throw_hit_sound(target, volume = DROP_SOUND_VOLUME)
	return sound_chain(mob_throw_hit_sound, volume, target)

/// plays when a mob is hit with this item
/obj/item/proc/play_hit_sound(target, volume = HALFWAY_SOUND_VOLUME)
	return sound_chain(hitsound, volume, target)

/obj/item/proc/play_equip_sound(volume = EQUIP_SOUND_VOLUME)
	return sound_chain(equip_sound, volume)

/* sound procs over */

/// Called when a mob drops an item.
/obj/item/proc/dropped(mob/user, silent = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	// Remove any item actions we temporary gave out.
	for(var/datum/action/action_item_has as anything in actions)
		action_item_has.Remove(user)

	if(item_flags & DROPDEL && !QDELETED(src))
		qdel(src)
	UnregisterSignal(src, list(SIGNAL_ADDTRAIT(TRAIT_NO_WORN_ICON), SIGNAL_REMOVETRAIT(TRAIT_NO_WORN_ICON)))
	SEND_SIGNAL(src, COMSIG_ITEM_DROPPED, user)
	SEND_SIGNAL(user, COMSIG_MOB_DROPPED_ITEM, src)
	if(!silent && drop_sound)
		play_drop_sound(DROP_SOUND_VOLUME)

/// called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_PICKUP, user)
	SEND_SIGNAL(user, COMSIG_LIVING_PICKED_UP_ITEM, src)

/// called when "found" in pockets and storage items. Returns 1 if the search should end.
/obj/item/proc/on_found(mob/finder)
	return

/**
 * Called after an item is placed in an equipment slot. Runs equipped(), then sends a signal.
 * This should be called last or near-to-last, after all other inventory code stuff is handled.
 *
 * Arguments:
 * * user is mob that equipped it
 * * slot uses the slot_X defines found in setup.dm for items that can be placed in multiple slots
 * * initial is used to indicate whether or not this is the initial equipment (job datums etc) or just a player doing it
 */
/obj/item/proc/on_equipped(mob/user, slot, initial = FALSE)
	SHOULD_NOT_OVERRIDE(TRUE)
	equipped(user, slot, initial)
	if(SEND_SIGNAL(src, COMSIG_ITEM_POST_EQUIPPED, user, slot) & COMPONENT_EQUIPPED_FAILED)
		return FALSE
	return TRUE

/**
 * To be overwritten to only perform visual tasks;
 * this is directly called instead of `equipped` on visual-only features like human dummies equipping outfits.
 *
 * This separation exists to prevent things like the monkey sentience helmet from
 * polling ghosts while it's just being equipped as a visual preview for a dummy.
 */
/obj/item/proc/visual_equipped(mob/user, slot, initial = FALSE)
	return TRUE

/**
 * Called by on_equipped. Don't call this directly, we want the ITEM_POST_EQUIPPED signal to be sent after everything else.
 *
 * Note that hands count as slots.
 *
 * Arguments:
 * * user is mob that equipped it
 * * slot uses the slot_X defines found in setup.dm for items that can be placed in multiple slots
 * * initial is used to indicate whether or not this is the initial equipment (job datums etc) or just a player doing it
 */
/obj/item/proc/equipped(mob/user, slot, initial = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)
	visual_equipped(user, slot, initial)
	SEND_SIGNAL(src, COMSIG_ITEM_EQUIPPED, user, slot)
	SEND_SIGNAL(user, COMSIG_MOB_EQUIPPED_ITEM, src, slot)

	// Give out actions our item has to people who equip it.
	for(var/datum/action/action as anything in actions)
		give_item_action(action, user, slot)

	RegisterSignals(src, list(SIGNAL_ADDTRAIT(TRAIT_NO_WORN_ICON), SIGNAL_REMOVETRAIT(TRAIT_NO_WORN_ICON)), PROC_REF(update_slot_icon), override = TRUE)

	if(!initial && (slot_flags & slot) && (play_equip_sound()))
		return

	if(slot & ITEM_SLOT_HANDS)
		play_pickup_sound()

/// Gives one of our item actions to a mob, when equipped to a certain slot
/obj/item/proc/give_item_action(datum/action/action, mob/to_who, slot)
	// Some items only give their actions buttons when in a specific slot.
	if(!item_action_slot_check(slot, to_who, action) || SEND_SIGNAL(src, COMSIG_ITEM_UI_ACTION_SLOT_CHECKED, to_who, action, slot) & COMPONENT_ITEM_ACTION_SLOT_INVALID)
		// There is a chance we still have our item action currently,
		// and are moving it from a "valid slot" to an "invalid slot".
		// So call Remove() here regardless, even if excessive.
		action.Remove(to_who)
		return

	action.Grant(to_who)

/// Sometimes we only want to grant the item's action if it's equipped in a specific slot.
/obj/item/proc/item_action_slot_check(slot, mob/user, datum/action/action)
	if(!slot) // Equipped into storage
		return FALSE
	if(slot & (ITEM_SLOT_HANDCUFFED|ITEM_SLOT_LEGCUFFED)) // These aren't true slots, so avoid granting actions there
		return FALSE
	if(!isnull(action_slots))
		return (slot & action_slots)
	else if (slot_flags)
		return (slot & slot_flags)
	return TRUE

/**
 *the mob M is attempting to equip this item into the slot passed through as 'slot'. Return 1 if it can do this and 0 if it can't.
 *if this is being done by a mob other than M, it will include the mob equipper, who is trying to equip the item to mob M. equipper will be null otherwise.
 *If you are making custom procs but would like to retain partial or complete functionality of this one, include a 'return ..()' to where you want this to happen.
 * Arguments:
 * * disable_warning to TRUE if you wish it to not give you text outputs.
 * * slot is the slot we are trying to equip to
 * * bypass_equip_delay_self for whether we want to bypass the equip delay
 * * ignore_equipped ignores any already equipped items in that slot
 * * indirect_action allows inserting into "soft locked" bags, things that can be easily opened by the owner
 */
/obj/item/proc/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, ignore_equipped = FALSE, indirect_action = FALSE)
	if(!M)
		return FALSE

	return M.can_equip(src, slot, disable_warning, bypass_equip_delay_self, ignore_equipped, indirect_action = indirect_action)

/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = null // BANDASTATION REPLACEMENT: Original: "Object"
	set name = "Pick up"

	if(usr.incapacitated || !Adjacent(usr))
		return

	if(isliving(usr))
		var/mob/living/L = usr
		if(!(L.mobility_flags & MOBILITY_PICKUP))
			return

	if(usr.get_active_held_item() == null) // Let me know if this has any problems -Yota
		usr.UnarmedAttack(src, TRUE)

/**
 *This proc is executed when someone clicks the on-screen UI button.
 *The default action is attack_self().
 *Checks before we get to here are: mob is alive, mob is not restrained, stunned, asleep, resting, laying, item is on the mob.
 */
/obj/item/proc/ui_action_click(mob/user, actiontype)
	if(SEND_SIGNAL(src, COMSIG_ITEM_UI_ACTION_CLICK, user, actiontype) & COMPONENT_ACTION_HANDLED)
		return

	attack_self(user)

///This proc determines if and at what an object will reflect energy projectiles if it's in l_hand,r_hand or wear_suit
/obj/item/proc/IsReflect(def_zone)
	return FALSE

/obj/item/singularity_pull(atom/singularity, current_size)
	..()
	if(current_size >= STAGE_FOUR)
		throw_at(singularity, 14, 3, spin=0)
	else
		return

/obj/item/on_exit_storage(datum/storage/master_storage)
	. = ..()
	do_drop_animation(master_storage.parent)

/obj/item/pre_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	get_embed() // Ensure that embedding is lazyloaded before we impact the target, if we can have it
	var/impact_flags = ..()
	if(w_class < WEIGHT_CLASS_BULKY)
		impact_flags |= COMPONENT_MOVABLE_IMPACT_FLIP_HITPUSH
	if(!(impact_flags & COMPONENT_MOVABLE_IMPACT_NEVERMIND) && get_temperature() && isliving(hit_atom))
		var/mob/living/victim = hit_atom
		victim.ignite_mob()
	return impact_flags

/obj/item/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()

	if(!isliving(hit_atom)) //Living mobs handle hit sounds differently.
		throw_drop_sound_chain(YEET_SOUND_VOLUME)
		return

	if(.) //it's been caught.
		return

	var/volume = get_volume_by_throwforce_and_or_w_class()
	if(!volume)
		return
	if (throwforce > 0 || HAS_TRAIT(src, TRAIT_CUSTOM_TAP_SOUND))
		mob_throw_hit_sound_chain(hit_atom, volume)
	else
		playsound(hit_atom, 'sound/items/weapons/throwtap.ogg', volume, TRUE, -1)

/obj/item/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	if(HAS_TRAIT(src, TRAIT_NODROP))
		return
	callback = CALLBACK(src, PROC_REF(after_throw), callback) //replace their callback with our own
	. = ..(target, range, speed, thrower, spin, diagonals_first, callback, force, gentle, quickstart = quickstart)

/obj/item/proc/after_throw(datum/callback/callback)
	if (callback) //call the original callback
		. = callback.Invoke()
	item_flags &= ~IN_INVENTORY
	if(!pixel_y && !pixel_x && !(item_flags & NO_PIXEL_RANDOM_DROP))
		pixel_x = rand(-8,8)
		pixel_y = rand(-8,8)

/// Takes the location to move the item to, and optionally the mob doing the removing
/// If no mob is provided, we'll pass in the location, assuming it is a mob
/// Please use this if you're going to snowflake an item out of a obj/item/storage
/obj/item/proc/remove_item_from_storage(atom/newLoc, mob/removing)
	if(!newLoc)
		return FALSE
	if(!removing)
		if(ismob(newLoc))
			removing = newLoc
		else
			stack_trace("Tried to remove an item and place it into [newLoc] without implicitly or explicitly passing in a mob doing the removing")
			return
	if(loc.atom_storage)
		return loc.atom_storage.remove_single(removing, src, newLoc, silent = TRUE)
	return FALSE

/// Returns the icon used for overlaying the object on a belt
/obj/item/proc/get_belt_overlay()
	var/icon_state_to_use = inside_belt_icon_state || icon_state
	if(greyscale_config_belt && greyscale_colors)
		return mutable_appearance(SSgreyscale.GetColoredIconByType(greyscale_config_belt, greyscale_colors), icon_state_to_use)
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', icon_state_to_use)

/**
 * Extend this to give the item an appearance when placed in a surgical tray. Uses an icon state in `medicart.dmi`.
 * * tray_extended - If true, the surgical tray the item is placed on is in "table mode"
 */
/obj/item/proc/get_surgery_tool_overlay(tray_extended)
	return null

/obj/item/proc/update_slot_icon()
	SIGNAL_HANDLER
	if(!ismob(loc) || QDELETED(loc))
		return
	var/mob/owner = loc
	owner.update_clothing(slot_flags | owner.get_slot_by_item(src))

///Returns the temperature of src. If you want to know if an item is hot use this proc.
/obj/item/proc/get_temperature()
	if(resistance_flags & ON_FIRE)
		return max(heat, BURNING_ITEM_MINIMUM_TEMPERATURE)
	return heat

///Returns the sharpness of src. If you want to get the sharpness of an item use this.
/obj/item/proc/get_sharpness()
	return sharpness

/obj/item/proc/get_dismember_sound()
	if(damtype == BURN)
		. = SFX_SEAR
	else
		. = SFX_DESECRATION

/// Creates an ignition hotspot if item is lit and located on turf, in mask, or in hand
/obj/item/proc/open_flame(flame_heat=700)
	var/turf/location = loc
	if(ismob(location))
		var/mob/pyromanic = location
		var/success = FALSE
		if(src == pyromanic.get_item_by_slot(ITEM_SLOT_MASK) || (src in pyromanic.held_items))
			success = TRUE
		if(success)
			location = get_turf(pyromanic)
	if(isturf(location))
		location.hotspot_expose(flame_heat, 5)

/// If an object can successfully be used as a fire starter it will return a message
/obj/item/proc/ignition_effect(atom/A, mob/user)
	if(get_temperature() >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		. = span_notice("[user] lights [A] with [src].")
	else
		. = ""

/obj/item/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	return SEND_SIGNAL(src, COMSIG_ATOM_HITBY, AM, skipcatch, hitpush, blocked, throwingdatum)

/obj/item/attack_hulk(mob/living/carbon/human/user)
	return FALSE

/obj/item/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if (obj_flags & CAN_BE_HIT)
		return ..()
	return 0

/obj/item/burn()
	if(!QDELETED(src))
		var/turf/T = get_turf(src)
		var/ash_type = /obj/effect/decal/cleanable/ash
		if(w_class == WEIGHT_CLASS_HUGE || w_class == WEIGHT_CLASS_GIGANTIC)
			ash_type = /obj/effect/decal/cleanable/ash/large
		var/obj/effect/decal/cleanable/ash/A = new ash_type(T)
		A.desc += "\nLooks like this used to be \an [name] some time ago."
		..()

/obj/item/acid_melt()
	if(!QDELETED(src))
		var/turf/T = get_turf(src)
		var/obj/effect/decal/cleanable/molten_object/MO = new(T)
		MO.pixel_x = rand(-16,16)
		MO.pixel_y = rand(-16,16)
		MO.desc = "Looks like this was \an [src] some time ago."
		..()

/obj/item/proc/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	SHOULD_CALL_PARENT(TRUE)

	return SEND_SIGNAL(src, COMSIG_ITEM_MICROWAVE_ACT, microwave_source, microwaver, randomize_pixel_offset)

///Used to check for extra requirements for blending(grinding or juicing) an object
/obj/item/proc/blend_requirements(atom/movable/grinder, mob/living/user)
	return TRUE

///Returns a reagent list containing the reagents this item produces when ground up in a grinder
/obj/item/proc/grind_results()
	RETURN_TYPE(/list/datum/reagent)
	if (!length(custom_materials) || (material_flags & MATERIAL_NO_REAGENTS))
		return null

	. = list()
	for (var/mat_id, amount in custom_materials)
		var/datum/material/material = SSmaterials.get_material(mat_id)
		if (!material.material_reagent)
			continue
		if (!islist(material.material_reagent))
			.[material.material_reagent] = .[material.material_reagent] + amount * MATERIAL_REAGENTS_PER_SHEET / SHEET_MATERIAL_AMOUNT
			continue
		for (var/reagent_type in material.material_reagent)
			.[reagent_type] = .[reagent_type] + amount * material.material_reagent[reagent_type] / length(material.material_reagent) * MATERIAL_REAGENTS_PER_SHEET / SHEET_MATERIAL_AMOUNT
	return .

///Called BEFORE the object is ground up - use this to change grind results based on conditions. Return "-1" to prevent the grinding from occurring
/obj/item/proc/on_grind()
	PROTECTED_PROC(TRUE)

	return SEND_SIGNAL(src, COMSIG_ITEM_ON_GRIND)

///Grind item, adding grind_results to item's reagents and transfering to target_holder if specified
/obj/item/proc/grind(datum/reagents/target_holder, mob/user, atom/movable/grinder = loc)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = FALSE
	if(on_grind() == -1 || target_holder.holder_full())
		return

	. = grind_atom(target_holder, user)

	//reccursive grinding to get all them juices
	var/result
	for(var/obj/item/ingredient as anything in get_all_contents_type(/obj/item))
		if(ingredient == src)
			continue

		result = ingredient.grind(target_holder, user)
		if(!.)
			. = result

	if(. && istype(grinder))
		return grinder.blended(src, grinded = TRUE)

///Subtypes override his proc for custom grinding
/obj/item/proc/grind_atom(datum/reagents/target_holder, mob/user)
	PROTECTED_PROC(TRUE)

	var/list/datum/reagent/grind_reagents = grind_results()

	. = FALSE
	if(length(grind_reagents))
		target_holder.add_reagent_list(grind_reagents)
		. = TRUE
	if(reagents?.trans_to(target_holder, reagents.total_volume, transferred_by = user))
		. = TRUE

///Returns A reagent the nutriments are converted into when the item is juiced.
/obj/item/proc/juice_typepath()
	RETURN_TYPE(/datum/reagent)

	return null

///Called BEFORE the object is ground up - use this to change grind results based on conditions. Return "-1" to prevent the grinding from occurring
/obj/item/proc/on_juice()
	PROTECTED_PROC(TRUE)

	if(!juice_typepath())
		return -1

	return SEND_SIGNAL(src, COMSIG_ITEM_ON_JUICE)

///Juice item, converting nutriments into juice_typepath and transfering to target_holder if specified
/obj/item/proc/juice(datum/reagents/target_holder, mob/user, atom/movable/juicer = loc)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = FALSE
	if(on_juice() == -1 || !reagents?.total_volume)
		return

	. = juice_atom(target_holder, user)

	//reccursive juicing to get all them juices
	var/result
	for(var/obj/item/ingredient as anything in get_all_contents_type(/obj/item))
		if(ingredient == src)
			continue

		result = ingredient.juice(target_holder, user)
		if(!.)
			. = result

	if(. && istype(juicer))
		return juicer.blended(src, grinded = FALSE)

///Subtypes override his proc for custom juicing
/obj/item/proc/juice_atom(datum/reagents/target_holder, mob/user)
	PROTECTED_PROC(TRUE)

	. = FALSE

	var/juice_result = juice_typepath()

	if(ispath(juice_result))
		reagents.convert_reagent(/datum/reagent/consumable/nutriment, juice_result, include_source_subtypes = FALSE)
		reagents.convert_reagent(/datum/reagent/consumable/nutriment/vitamin, juice_result, include_source_subtypes = FALSE)
		. = TRUE

	if(!QDELETED(target_holder))
		reagents.trans_to(target_holder, reagents.total_volume, transferred_by = user)

///What should The atom that blended an object do with it afterwards? Default behaviour is to delete it
/atom/movable/proc/blended(obj/item/blended_item, grinded)
	qdel(blended_item)

	return TRUE

/obj/item/proc/set_force_string()
	switch(force)
		if(0 to 4)
			force_string = "very low"
		if(4 to 7)
			force_string = "low"
		if(7 to 10)
			force_string = "medium"
		if(10 to 11)
			force_string = "high"
		if(11 to 20) //12 is the force of a toolbox
			force_string = "robust"
		if(20 to 25)
			force_string = "very robust"
		else
			force_string = "exceptionally robust"
	last_force_string_check = force

/obj/item/proc/openTip(location, control, params, user)
	if(last_force_string_check != force && !(item_flags & FORCE_STRING_OVERRIDE))
		set_force_string()
	if(!(item_flags & FORCE_STRING_OVERRIDE))
		openToolTip(user, src, params, title = get_tip_name(), content = "[desc]<br>[force ? "<b>Force:</b> [force_string]" : ""]", theme = "")
	else
		openToolTip(user, src, params, title = get_tip_name(), content = "[desc]<br><b>Force:</b> [force_string]", theme = "")

/obj/item/MouseEntered(location, control, params)
	. = ..()
	if(((get(src, /mob) == usr) || loc?.atom_storage || (item_flags & IN_STORAGE)) && !QDELETED(src)) //nullspace exists.
		var/mob/living/L = usr
		if(usr.client.prefs.read_preference(/datum/preference/toggle/enable_tooltips))
			var/timedelay = usr.client.prefs.read_preference(/datum/preference/numeric/tooltip_delay) / 100
			tip_timer = addtimer(CALLBACK(src, PROC_REF(openTip), location, control, params, usr), timedelay, TIMER_STOPPABLE)//timer takes delay in deciseconds, but the pref is in milliseconds. dividing by 100 converts it.
		if(usr.client.prefs.read_preference(/datum/preference/toggle/item_outlines))
			if(istype(L) && L.incapacitated)
				apply_outline(COLOR_RED_GRAY) //if they're dead or handcuffed, let's show the outline as red to indicate that they can't interact with that right now
			else
				apply_outline() //if the player's alive and well we send the command with no color set, so it uses the theme's color

/obj/item/base_mouse_drop_handler(atom/over, src_location, over_location, params)
	SHOULD_NOT_OVERRIDE(TRUE)

	. = ..()

	remove_filter(HOVER_OUTLINE_FILTER) //get rid of the hover effect in case the mouse exit isn't called if someone drags and drops an item and somthing goes wrong

/obj/item/MouseExited()
	deltimer(tip_timer) //delete any in-progress timer if the mouse is moved off the item before it finishes
	closeToolTip(usr)
	remove_filter(HOVER_OUTLINE_FILTER)

/obj/item/proc/apply_outline(outline_color = null)
	if(((get(src, /mob) != usr) && !loc?.atom_storage && !(item_flags & IN_STORAGE)) || QDELETED(src) || isobserver(usr)) //cancel if the item isn't in an inventory, is being deleted, or if the person hovering is a ghost (so that people spectating you don't randomly make your items glow)
		return FALSE
	var/theme = LOWER_TEXT(usr.client?.prefs?.read_preference(/datum/preference/choiced/ui_style))
	if(!outline_color) //if we weren't provided with a color, take the theme's color
		switch(theme) //yeah it kinda has to be this way
			if("midnight")
				outline_color = COLOR_THEME_MIDNIGHT
			if("plasmafire")
				outline_color = COLOR_THEME_PLASMAFIRE
			if("retro")
				outline_color = COLOR_THEME_RETRO //just as garish as the rest of this theme
			if("slimecore")
				outline_color = COLOR_THEME_SLIMECORE
			if("operative")
				outline_color = COLOR_THEME_OPERATIVE
			if("clockwork")
				outline_color = COLOR_THEME_CLOCKWORK
			if("glass")
				outline_color = COLOR_THEME_GLASS
			if("trasen-knox")
				outline_color = COLOR_THEME_TRASENKNOX
			if("detective")
				outline_color = COLOR_THEME_DETECTIVE
			else //this should never happen, hopefully
				outline_color = COLOR_WHITE
	if(color)
		outline_color = COLOR_WHITE //if the item is recolored then the outline will be too, let's make the outline white so it becomes the same color instead of some ugly mix of the theme and the tint

	add_filter(HOVER_OUTLINE_FILTER, 1, list("type" = "outline", "size" = 1, "color" = outline_color))

/// Called when a mob tries to use the item as a tool. Handles most checks.
/obj/item/proc/use_tool(atom/target, mob/living/user, delay, amount=0, volume=0, datum/callback/extra_checks)
	// No delay means there is no start message, and no reason to call tool_start_check before use_tool.
	// Run the start check here so we wouldn't have to call it manually.
	if(!delay && !tool_start_check(user, amount))
		return

	var/skill_modifier = 1

	if(tool_behaviour == TOOL_MINING)
		if(user.mind)
			skill_modifier = user.mind.get_skill_modifier(/datum/skill/mining, SKILL_SPEED_MODIFIER)

			if(user.mind.get_skill_level(/datum/skill/mining) >= SKILL_LEVEL_JOURNEYMAN && prob(user.mind.get_skill_modifier(/datum/skill/mining, SKILL_PROBS_MODIFIER))) // we check if the skill level is greater than Journeyman and then we check for the probality for that specific level.
				mineral_scan_pulse(get_turf(user), SKILL_LEVEL_JOURNEYMAN - 2, scanner = src) //SKILL_LEVEL_JOURNEYMAN = 3 So to get range of 1+ we have to subtract 2 from it,.

	delay *= toolspeed * skill_modifier
	var/cyberpunk_action = "work"
	if(delay && target && istype(user) && target.is_cyberpunk_structure_target())
		switch(tool_behaviour)
			if(TOOL_WELDER)
				cyberpunk_action = target.is_cyberpunk_repair_target() ? "repair" : "dismantle"
			if(TOOL_CROWBAR, TOOL_SCREWDRIVER, TOOL_WRENCH, TOOL_WIRECUTTER)
				cyberpunk_action = "dismantle"
		delay *= user.get_cyberpunk_structure_time_multiplier(target, cyberpunk_action)
		var/obj/machinery/target_machine = target
		if(istype(target_machine))
			delay *= target_machine.get_cyberpunk_machine_tool_time_multiplier()


	// Play tool sound at the beginning of tool usage.
	play_tool_sound(target, volume)

	if(delay)
		// Create a callback with checks that would be called every tick by do_after.
		var/datum/callback/tool_check = CALLBACK(src, PROC_REF(tool_check_callback), user, amount, extra_checks)

		if(delay >= MIN_TOOL_OPERATING_DELAY)
			play_tool_operating_sound(target, volume)

		if(!do_after(user, delay, target=target, extra_checks=tool_check))
			return
	else
		// Invoke the extra checks once, just in case.
		if(extra_checks && !extra_checks.Invoke())
			return

	// Use tool's fuel, stack sheets or charges if amount is set.
	if(amount && !use(amount))
		return

	// Play tool sound at the end of tool usage,
	// but only if the delay between the beginning and the end is not too small
	if(delay >= MIN_TOOL_SOUND_DELAY)
		play_tool_sound(target, volume)

	if(cyberpunk_action == "dismantle")
		var/obj/target_object = target
		if(istype(target_object))
			target_object.cyberpunk_last_deconstructor = user

	return TRUE

/// Called before [obj/item/proc/use_tool] if there is a delay, or by [obj/item/proc/use_tool] if there isn't. Only ever used by welding tools and stacks, so it's not added on any other [obj/item/proc/use_tool] checks.
/obj/item/proc/tool_start_check(mob/living/user, amount=0, heat_required=0)
	. = tool_use_check(user, amount, heat_required)
	if(.)
		SEND_SIGNAL(src, COMSIG_TOOL_START_USE, user)

/// A check called by [/obj/item/proc/tool_start_check] once, and by use_tool on every tick of delay.
/obj/item/proc/tool_use_check(mob/living/user, amount, heat_required)
	return !amount

/// Generic use proc. Depending on the item, it uses up fuel, charges, sheets, etc. Returns TRUE on success, FALSE on failure.
/obj/item/proc/use(used)
	return !used

/// Plays item's usesound, if any.
/obj/item/proc/play_tool_sound(atom/target, volume=50)
	if(target && usesound && volume)
		var/played_sound = usesound

		if(islist(usesound))
			played_sound = pick(usesound)

		playsound(target, played_sound, volume, TRUE)

///Play item's operating sound
/obj/item/proc/play_tool_operating_sound(atom/target, volume=50)
	if(target && operating_sound && volume)
		var/played_sound = operating_sound

		if(islist(operating_sound))
			played_sound = pick(operating_sound)

		if(!TIMER_COOLDOWN_FINISHED(src, COOLDOWN_TOOL_SOUND))
			return
		playsound(target, played_sound, volume, TRUE)
		TIMER_COOLDOWN_START(src, COOLDOWN_TOOL_SOUND, 4 SECONDS) //based on our longest sound clip

/// Used in a callback that is passed by use_tool into do_after call. Do not override, do not call manually.
/obj/item/proc/tool_check_callback(mob/living/user, amount, datum/callback/extra_checks)
	SHOULD_NOT_OVERRIDE(TRUE)
	. = tool_use_check(user, amount) && (!extra_checks || extra_checks.Invoke())
	if(.)
		SEND_SIGNAL(src, COMSIG_TOOL_IN_USE, user)

/// Returns a numeric value for sorting items used as parts in machines, so they can be replaced by the rped
/obj/item/proc/get_part_rating()
	return 0

/**
 * this proc override makes sure that even if DoUnEquip is not properly called through the appropriate channels,
 * it'll still be called if we find that the item has the IN_INVENTORY flag.
 *
 * THIS IS BY NO MEAN AN EXCUSE TO KNOWINGLY AVOID CALLING THE RIGHT PROCS FOR INVENTORY MANAGEMENT,
 * BUT A FALLBACK IN THE CASE WE MISTAKINGLY DON'T, TO MAKE SURE THINGS WORK AS INTENDED SINCE
 * INVENTORY MANAGEMENT HAS A LOT MORE TO IT THAN JUST CALLING A PROC OR TWO MANUALLY.
 */
/obj/item/doMove(atom/destination)
	if (!(item_flags & IN_INVENTORY))
		return ..()

	if(!ismob(loc))
		stack_trace("[src] had the IN_INVENTORY flag but the location was not a mob!")
		item_flags &= ~IN_INVENTORY
		return ..()

	var/mob/owner = loc
	// This should remove the IN_INVENTORY flag. Otherwise we'll end up having a loop
	owner.transferItemToLoc(src, destination, force = TRUE, silent = TRUE, animated = FALSE)

/obj/item/proc/canStrip(mob/stripper, mob/owner)
	SHOULD_BE_PURE(TRUE)
	return !HAS_TRAIT(src, TRAIT_NODROP) && !(item_flags & ABSTRACT)

/obj/item/proc/doStrip(mob/stripper, mob/owner)
	return owner.dropItemToGround(src)

///Called by the carbon throw_item() proc. Returns null if the item negates the throw, or a reference to the thing to suffer the throw else.
/obj/item/proc/on_thrown(mob/living/carbon/user, atom/target)
	if((item_flags & ABSTRACT) || HAS_TRAIT(src, TRAIT_NODROP))
		return
	user.dropItemToGround(src, silent = TRUE)
	if(throwforce && (HAS_TRAIT(user, TRAIT_PACIFISM)) || HAS_TRAIT(user, TRAIT_NO_THROWING))
		to_chat(user, span_notice("You set [src] down gently on the ground."))
		return
	return src

/// How many different types of mats will be counted in a bite?
#define MAX_MATS_PER_BITE 2

/*
 * On accidental consumption: when you somehow end up eating an item accidentally (currently, this is used for when items are hidden in food like bread or cake)
 *
 * The base proc will check if the item is sharp and has a decent force.
 * Then, it checks the item's mat datums for the effects it applies afterwards.
 * Then, it checks tiny items.
 * After all that, it returns TRUE if the item is set to be discovered. Otherwise, it returns FALSE.
 *
 * This works similarly to /suicide_act: if you want an item to have a unique interaction, go to that item
 * and give it an /on_accidental_consumption proc override. For a simple example of this, check out the nuke disk.
 *
 * Arguments
 * * M - the mob accidentally consuming the item
 * * user - the mob feeding M the item - usually, it's the same as M
 * * source_item - the item that held the item being consumed - bread, cake, etc
 * * discover_after - if the item will be discovered after being chomped (FALSE will usually mean it was swallowed, TRUE will usually mean it was bitten into and discovered)
 */
/obj/item/proc/on_accidental_consumption(mob/living/carbon/victim, mob/living/carbon/user, obj/item/source_item, discover_after = TRUE)
	if(get_sharpness() && force >= 5) //if we've got something sharp with a decent force (ie, not plastic)
		INVOKE_ASYNC(victim, TYPE_PROC_REF(/mob, emote), "scream")
		victim.visible_message(span_warning("[victim] looks like [victim.p_theyve()] just bit something they shouldn't have!"), \
							span_boldwarning("OH GOD! Was that a crunch? That didn't feel good at all!!"))

		victim.apply_damage(max(15, force), BRUTE, BODY_ZONE_HEAD, wound_bonus = 10, sharpness = TRUE)
		victim.losebreath += 2
		if(force_embed(victim, BODY_ZONE_CHEST)) //and if it embeds successfully in their chest, cause a lot of pain
			victim.apply_damage(max(25, force*1.5), BRUTE, BODY_ZONE_CHEST, wound_bonus = 7, sharpness = TRUE)
			victim.losebreath += 6
			discover_after = FALSE
		if(QDELETED(src)) // in case trying to embed it caused its deletion (say, if it's DROPDEL)
			return
		source_item?.reagents?.add_reagent(/datum/reagent/blood, 2)
		return discover_after

	if(custom_materials?.len) //if we've got materials, let's see what's in it
		// How many mats have we found? You can only be affected by two material datums by default
		var/found_mats = 0
		// How much of each material is in it? Used to determine if the glass should break
		var/total_material_amount = 0

		for(var/mats in custom_materials)
			total_material_amount += custom_materials[mats]
			if(found_mats >= MAX_MATS_PER_BITE)
				continue //continue instead of break so we can finish adding up all the mats to the total

			var/datum/material/discovered_mat = mats
			if(discovered_mat.on_accidental_mat_consumption(victim, source_item))
				found_mats++

		//if there's glass in it and the glass is more than 60% of the item, then we can shatter it
		if(custom_materials[SSmaterials.get_material(/datum/material/glass)] >= total_material_amount * 0.60)
			if(prob(66)) //66% chance to break it
				// The glass shard that is spawned into the source item
				var/obj/item/shard/broken_glass = new /obj/item/shard(loc)
				broken_glass.name = "broken [name]"
				broken_glass.desc = "This used to be \a [name], but it sure isn't anymore."
				playsound(victim, SFX_SHATTER, 25, TRUE)
				qdel(src)
				if(QDELETED(source_item))
					broken_glass.on_accidental_consumption(victim, user)
			else //33% chance to just "crack" it (play a sound) and leave it in the bread
				playsound(victim, SFX_SHATTER, 15, TRUE)
			discover_after = FALSE

		victim.adjust_disgust(33)
		victim.visible_message(span_warning("[victim] looks like [victim.p_theyve()] just bitten into something hard."), \
						span_warning("Eugh! Did I just bite into something?"))
		return discover_after

	if(w_class > WEIGHT_CLASS_TINY) //small items like soap or toys that don't have mat datums
		to_chat(victim, span_warning("[source_item? "Something strange was in \the [source_item]..." : "I just bit something strange..."] "))
		return discover_after

	var/obj/item/organ/stomach/stomach = victim.get_organ_by_type(/obj/item/organ/stomach)
	if (stomach?.consume_thing(src))
		victim.losebreath += 2
		to_chat(victim, span_warning("You swallow hard. [source_item? "Something small was in \the [source_item]..." : ""]"))
		return FALSE

	// victim's chest (for cavity implanting the item)
	var/obj/item/bodypart/chest/victim_cavity = victim.get_bodypart(BODY_ZONE_CHEST)
	if(victim_cavity.cavity_item)
		victim.vomit(vomit_flags = (MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM), lost_nutrition = 5, distance = 0)
		forceMove(drop_location())
		to_chat(victim, span_warning("You vomit up a [name]! [source_item? "Was that in \the [source_item]?" : ""]"))
		return FALSE

	victim.transferItemToLoc(src, victim, TRUE)
	victim.losebreath += 2
	to_chat(victim, span_warning("You swallow hard. [source_item? "Something small was in \the [source_item]..." : ""]"))
	return FALSE

#undef MAX_MATS_PER_BITE

/**
 * Updates all action buttons associated with this item
 *
 * Arguments:
 * * update_flags - Which flags of the action should we update
 * * force - Force buttons update even if the given button icon state has not changed
 */
/obj/item/proc/update_item_action_buttons(update_flags = ALL, force = FALSE)
	for(var/datum/action/current_action as anything in actions)
		current_action.build_all_button_icons(update_flags, force)

// Update icons if this is being carried by a mob
/obj/item/wash(clean_types)
	. = ..()
	if(!.) // we don't need mob updates when the item was already clean
		return
	if(ismob(loc))
		var/mob/mob_loc = loc
		mob_loc.update_clothing(slot_flags)

/// Called on [/datum/element/openspace_item_click_handler/proc/on_afterattack]. Check the relative file for information.
/obj/item/proc/handle_openspace_click(turf/target, mob/user, list/modifiers)
	stack_trace("Undefined handle_openspace_click() behaviour. Ascertain the openspace_item_click_handler element has been attached to the right item and that its proc override doesn't call parent.")

/**
 * * An interrupt for offering an item to other people, called mainly from [/mob/living/proc/give], in case you want to run your own offer behavior instead.
 *
 * * Return TRUE if you want to interrupt the offer.
 *
 * * Arguments:
 * * offerer - The living mob offering the item.
 * * offered - The living mob being offered the item.
 */
/obj/item/proc/on_offered(mob/living/offerer, mob/living/offered)
	if(!offered) // item has just been offered to anyone around
		if(!(HAS_TRAIT(offerer, TRAIT_CAN_HOLD_ITEMS)))
			return TRUE
	else if(!(HAS_TRAIT(offerer, TRAIT_CAN_HOLD_ITEMS) && HAS_TRAIT(offered, TRAIT_CAN_HOLD_ITEMS)))
		return TRUE // both must be able to hold items for this to make sense
	if(SEND_SIGNAL(src, COMSIG_ITEM_OFFERING, offerer) & COMPONENT_OFFER_INTERRUPT)
		return TRUE

/**
 * * An interrupt for someone trying to accept an offered item, called mainly from [/mob/living/proc/take], in case you want to run your own take behavior instead.
 *
 * * Return TRUE if you want to interrupt the taking.
 *
 * * Arguments:
 * * offerer - the living mob offering the item
 * * taker - the living mob trying to accept the offer
 */
/obj/item/proc/on_offer_taken(mob/living/offerer, mob/living/taker)
	if(!(HAS_TRAIT(offerer, TRAIT_CAN_HOLD_ITEMS) && HAS_TRAIT(taker, TRAIT_CAN_HOLD_ITEMS)))
		return TRUE // both must be able to hold items for this to make sense
	if(SEND_SIGNAL(src, COMSIG_ITEM_OFFER_TAKEN, offerer, taker) & COMPONENT_OFFER_INTERRUPT)
		return TRUE

/// Special stuff you want to do when an outfit equips this item.
/obj/item/proc/on_outfit_equip(mob/living/carbon/human/outfit_wearer, visuals_only, item_slot)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_EQUIPPED_AS_OUTFIT, outfit_wearer, visuals_only, item_slot)

/obj/item/proc/do_pickup_animation(atom/target, turf/source)
	if(!source)
		if(!istype(loc, /turf))
			return
		source = loc
	SEND_SIGNAL(src, COMSIG_ITEM_BEFORE_PICKUP_ANIMATION)
	var/image/pickup_animation = image(icon = src)
	SET_PLANE(pickup_animation, GAME_PLANE, source)
	pickup_animation.transform.Scale(0.75)
	pickup_animation.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

	var/direction = get_dir(source, target)
	var/to_x = target.base_pixel_x + target.base_pixel_w
	var/to_y = target.base_pixel_y + target.base_pixel_z

	if(direction & NORTH)
		to_y += 32
	else if(direction & SOUTH)
		to_y -= 32
	if(direction & EAST)
		to_x += 32
	else if(direction & WEST)
		to_x -= 32
	if(!direction)
		to_y += 10
		pickup_animation.pixel_x += 6 * (prob(50) ? 1 : -1) //6 to the right or left, helps break up the straight upward move

	var/atom/movable/flick_visual/pickup = source.flick_overlay_view(pickup_animation, 0.4 SECONDS)
	var/matrix/animation_matrix = new(pickup.transform)
	animation_matrix.Turn(pick(-30, 30))
	animation_matrix.Scale(0.65)

	animate(pickup, alpha = 175, pixel_x = to_x, pixel_y = to_y, time = 0.3 SECONDS, transform = animation_matrix, easing = CUBIC_EASING)
	animate(alpha = 0, transform = matrix().Scale(0.7), time = 0.1 SECONDS)

/obj/item/proc/do_drop_animation(atom/moving_from)
	if(!istype(loc, /turf))
		return

	if(!istype(moving_from))
		return

	SEND_SIGNAL(src, COMSIG_ITEM_BEFORE_DROP_ANIMATION)
	var/turf/current_turf = get_turf(src)
	var/direction = get_dir(moving_from, current_turf)
	var/from_x = moving_from.base_pixel_x
	var/from_y = moving_from.base_pixel_y

	if(direction & NORTH)
		from_y -= 32
	else if(direction & SOUTH)
		from_y += 32
	if(direction & EAST)
		from_x -= 32
	else if(direction & WEST)
		from_x += 32
	if(!direction)
		from_y += 10
		from_x += 6 * (prob(50) ? 1 : -1) //6 to the right or left, helps break up the straight upward move

	//We're moving from these chords to our current ones
	var/old_x = pixel_x
	var/old_y = pixel_y
	var/old_alpha = alpha
	var/matrix/old_transform = transform
	var/matrix/animation_matrix = new(old_transform)
	animation_matrix.Turn(pick(-30, 30))
	animation_matrix.Scale(0.7) // Shrink to start, end up normal sized

	pixel_x = from_x
	pixel_y = from_y
	alpha = 0
	transform = animation_matrix

	SEND_SIGNAL(src, COMSIG_ATOM_TEMPORARY_ANIMATION_START, 3)
	// This is instant on byond's end, but to our clients this looks like a quick drop
	animate(src, alpha = old_alpha, pixel_x = old_x, pixel_y = old_y, transform = old_transform, time = 3, easing = CUBIC_EASING)

/atom/movable/proc/do_item_attack_animation(atom/attacked_atom, visual_effect_icon, obj/item/used_item, animation_type)
	if (!visual_effect_icon)
		if (used_item)
			used_item.animate_attack(src, attacked_atom, animation_type)
		return

	var/image/attack_image = image(icon = 'icons/effects/effects.dmi', icon_state = visual_effect_icon)
	attack_image.plane = attacked_atom.plane + 1
	// Scale the icon.
	attack_image.transform *= 0.4
	// The icon should not rotate.
	attack_image.appearance_flags = APPEARANCE_UI
	var/atom/movable/flick_visual/attack = attacked_atom.flick_overlay_view(attack_image, 1 SECONDS)
	var/matrix/copy_transform = new(transform)
	animate(attack, alpha = 175, transform = copy_transform.Scale(0.75), time = 0.3 SECONDS)
	animate(time = 0.1 SECONDS)
	animate(alpha = 0, time = 0.3 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)

/obj/item/proc/animate_attack(atom/movable/attacker, atom/attacked_atom, animation_type)
	var/list/image_override = list()
	var/list/animation_override = list()
	var/used_icon_angle = icon_angle
	var/list/angle_override = list()
	SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_ANIMATION, attacker, attacked_atom, animation_type, image_override, animation_override, angle_override)
	var/image/attack_image = null
	if (!length(image_override))
		attack_image = isnull(attack_icon) ? image(icon = src) : image(icon = attack_icon, icon_state = attack_icon_state)
	else
		attack_image = image_override[1]

	if (length(animation_override))
		animation_type = animation_override[1]
	else if (!animation_type)
		switch (get_sharpness())
			if (SHARP_EDGED)
				animation_type = ATTACK_ANIMATION_SLASH
			if (SHARP_POINTY)
				animation_type = ATTACK_ANIMATION_PIERCE
			else
				animation_type = ATTACK_ANIMATION_BLUNT

	if (length(angle_override))
		used_icon_angle = angle_override[1]

	attack_image.plane = attacked_atom.plane + 1
	attack_image.pixel_w = attacker.base_pixel_x + attacker.base_pixel_w - attacked_atom.base_pixel_x - attacked_atom.base_pixel_w
	attack_image.pixel_z = attacker.base_pixel_y + attacker.base_pixel_z - attacked_atom.base_pixel_y - attacked_atom.base_pixel_z
	// Scale the icon.
	attack_image.transform *= 0.5
	// The icon should not rotate.
	attack_image.appearance_flags = APPEARANCE_UI

	var/atom/movable/flick_visual/attack = attacked_atom.flick_overlay_view(attack_image, 1 SECONDS)
	var/matrix/copy_transform = new(attacker.transform)
	var/x_sign = 0
	var/y_sign = 0
	var/direction = get_dir(attacker, attacked_atom)
	if (direction & NORTH)
		y_sign = -1
	else if (direction & SOUTH)
		y_sign = 1

	if (direction & EAST)
		x_sign = -1
	else if (direction & WEST)
		x_sign = 1

	// Attacking self, or something on the same turf as us
	if (!direction)
		y_sign = 1
		// Not a fan of this, but its the "cleanest" way to animate this
		x_sign = 0.25 * (prob(50) ? 1 : -1)
		// For piercing attacks
		direction = SOUTH

	// And animate the attack!
	switch (animation_type)
		if (ATTACK_ANIMATION_BLUNT)
			attack.pixel_x = 14 * x_sign
			attack.pixel_y = 12 * y_sign
			animate(attack, alpha = 175, transform = copy_transform.Scale(0.75), pixel_x = 4 * x_sign, pixel_y = 3 * y_sign, time = 0.2 SECONDS)
			animate(time = 0.1 SECONDS)
			animate(alpha = 0, time = 0.1 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)

		if (ATTACK_ANIMATION_PIERCE)
			var/attack_angle = dir2angle(direction) + rand(-7, 7)
			// Deducting 90 because we're assuming that icon_angle of 0 means an east-facing sprite
			var/anim_angle = attack_angle - 90 - used_icon_angle
			var/angle_mult = 1
			if (x_sign && y_sign)
				angle_mult = 1.4
			attack.pixel_x = 22 * x_sign * angle_mult
			attack.pixel_y = 18 * y_sign * angle_mult
			attack.transform = attack.transform.Turn(anim_angle)
			copy_transform = copy_transform.Turn(anim_angle)
			animate(
				attack,
				pixel_x = (22 * x_sign - 12 * sin(attack_angle)) * angle_mult,
				pixel_y = (18 * y_sign - 8 * cos(attack_angle)) * angle_mult,
				time = 0.1 SECONDS,
				easing = CUBIC_EASING|EASE_IN,
			)
			animate(
				attack,
				alpha = 175,
				transform = copy_transform.Scale(0.75),
				pixel_x = (22 * x_sign + 26 * sin(attack_angle)) * angle_mult,
				pixel_y = (18 * y_sign + 22 * cos(attack_angle)) * angle_mult,
				time = 0.3 SECONDS,
				easing = CUBIC_EASING|EASE_OUT,
			)
			animate(
				alpha = 0,
				pixel_x = -3 * -(x_sign + sin(attack_angle)),
				pixel_y = -2 * -(y_sign + cos(attack_angle)),
				time = 0.1 SECONDS,
				easing = CIRCULAR_EASING|EASE_OUT
			)

		if (ATTACK_ANIMATION_SLASH)
			attack.pixel_x = 18 * x_sign
			attack.pixel_y = 14 * y_sign
			var/x_rot_sign = 0
			var/y_rot_sign = 0
			var/attack_dir = (prob(50) ? 1 : -1)
			var/anim_angle = dir2angle(direction) - 90 - used_icon_angle

			if (x_sign)
				y_rot_sign = attack_dir
			if (y_sign)
				x_rot_sign = attack_dir

			// Animations are flipped, so flip us too!
			if (x_sign > 0 || y_sign < 0)
				attack_dir *= -1

			// We're swinging diagonally, use separate logic
			var/anim_dir = attack_dir
			if (x_sign && y_sign)
				if (attack_dir < 0)
					x_rot_sign = -x_sign * 1.4
					y_rot_sign = 0
				else
					x_rot_sign = 0
					y_rot_sign = -y_sign * 1.4

				// Flip us if we've been flipped *unless* we're flipped due to both axis
				if ((x_sign < 0 && y_sign > 0) || (x_sign > 0 && y_sign < 0))
					anim_dir *= -1

			attack.pixel_x += 10 * x_rot_sign
			attack.pixel_y += 8 * y_rot_sign
			attack.transform = attack.transform.Turn(anim_angle - 45 * anim_dir)
			copy_transform = copy_transform.Scale(0.75)
			animate(attack, alpha = 175, time = 0.3 SECONDS, flags = ANIMATION_PARALLEL)
			animate(time = 0.1 SECONDS)
			animate(alpha = 0, time = 0.1 SECONDS, easing = CIRCULAR_EASING|EASE_OUT)

			animate(attack, transform = copy_transform.Turn(anim_angle + 45 * anim_dir), time = 0.3 SECONDS, flags = ANIMATION_PARALLEL)

			var/x_return = 10 * -x_rot_sign
			var/y_return = 8 * -y_rot_sign

			if (!x_rot_sign)
				x_return = 18 * x_sign
			if (!y_rot_sign)
				y_return = 14 * y_sign

			var/angle_mult = 1
			if (x_sign && y_sign)
				angle_mult = 1.4
				if (attack_dir > 0)
					x_return = 8 * x_sign
					y_return = 14 * y_sign
				else
					x_return = 18 * x_sign
					y_return = 6 * y_sign

			animate(attack, pixel_x = 4 * x_sign * angle_mult, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
			animate(pixel_x = x_return, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_OUT)

			animate(attack, pixel_y = 3 * y_sign * angle_mult, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
			animate(pixel_y = y_return, time = 0.2 SECONDS, easing = CIRCULAR_EASING | EASE_OUT)

/// Common proc used by painting tools like spraycans and palettes that can access the entire 24 bits color space.
/obj/item/proc/pick_painting_tool_color(mob/user, default_color)
	var/chosen_color = tgui_color_picker(user, "Выберите новый цвет", "[src]", default_color)
	if(!chosen_color || QDELETED(src) || IS_DEAD_OR_INCAP(user) || !user.is_holding(src))
		return
	set_painting_tool_color(chosen_color)

/obj/item/proc/set_painting_tool_color(chosen_color)
	SEND_SIGNAL(src, COMSIG_PAINTING_TOOL_SET_COLOR, chosen_color)

/**
 * Returns null if this object cannot be used to interact with physical writing mediums such as paper.
 * Returns a list of key attributes for this object interacting with paper otherwise.
 */
/obj/item/proc/get_writing_implement_details()
	return null

/**
 * When called on an item, and given a body targeting zone, this will return TRUE if the item slot matches the target zone, and FALSE otherwise.
 * Currently supports the jumpsuit, outersuit, backpack, belt, gloves, hat, ears, neck, mask, eyes, and feet slots. All other slots will auto return FALSE.
 */
/obj/item/proc/compare_zone_to_item_slot(zone)
	switch(slot_flags)
		if(ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING, ITEM_SLOT_BACK)
			return (zone == BODY_ZONE_CHEST)
		if(ITEM_SLOT_BELT)
			return (zone == BODY_ZONE_PRECISE_GROIN)
		if(ITEM_SLOT_GLOVES)
			return (zone == BODY_ZONE_R_ARM || zone == BODY_ZONE_L_ARM)
		if(ITEM_SLOT_HEAD, ITEM_SLOT_EARS, ITEM_SLOT_NECK)
			return (zone == BODY_ZONE_HEAD)
		if(ITEM_SLOT_MASK)
			return (zone == BODY_ZONE_PRECISE_MOUTH)
		if(ITEM_SLOT_EYES)
			return (zone == BODY_ZONE_PRECISE_EYES)
		if(ITEM_SLOT_FEET)
			return (zone == BODY_ZONE_L_LEG || zone == BODY_ZONE_R_LEG)
	return FALSE

/**
 * This proc calls at the begining of anytime an item is being equiped to a target by another mob.
 * It handles initial messages, AFK stripping, and initial logging.
 */
/obj/item/proc/item_start_equip(atom/target, obj/item/equipping, mob/user, show_visible_message = TRUE)

	if(show_visible_message)
		if(HAS_TRAIT(equipping, TRAIT_DANGEROUS_OBJECT))
			target.visible_message(
				span_danger("[capitalize(user.declent_ru(NOMINATIVE))] пытается экипировать [equipping.declent_ru(ACCUSATIVE)] на [target.declent_ru(ACCUSATIVE)]."),
				span_userdanger("[capitalize(user.declent_ru(NOMINATIVE))] пытается экипировать на вас [equipping.declent_ru(ACCUSATIVE)]."),
				ignored_mobs = user,
			)

		else
			target.visible_message(
				span_notice("[capitalize(user.declent_ru(NOMINATIVE))] пытается экипировать [equipping.declent_ru(ACCUSATIVE)] на [target.declent_ru(ACCUSATIVE)]."),
				span_notice("[capitalize(user.declent_ru(NOMINATIVE))] пытается экипировать на вас [equipping.declent_ru(ACCUSATIVE)]."),
				ignored_mobs = user,
			)

		if(ishuman(target))
			var/mob/living/carbon/human/victim_human = target
			if(victim_human.key && !victim_human.client) // AKA braindead
				if(victim_human.stat <= SOFT_CRIT && LAZYLEN(victim_human.afk_thefts) <= AFK_THEFT_MAX_MESSAGES)
					var/list/new_entry = list(list(user.name, "пытался экипировать на вас [equipping.declent_ru(ACCUSATIVE)]", world.time))
					LAZYADD(victim_human.afk_thefts, new_entry)

			else if(victim_human.is_blind())
				to_chat(target, span_userdanger("Вы чувствуете, как кто-то пытается что-то экипировать на вас."))
	user.do_item_attack_animation(target, used_item = equipping, animation_type = ATTACK_ANIMATION_BLUNT)

	to_chat(user, span_notice("Вы пытаетесь экипировать [equipping.declent_ru(ACCUSATIVE)] на [target.declent_ru(PREPOSITIONAL)]..."))

	user.log_message("is putting [equipping] on [key_name(target)]", LOG_ATTACK, color="red")
	target.log_message("is having [equipping] put on them by [key_name(user)]", LOG_VICTIM, color="orange", log_globally=FALSE)

/obj/item/update_atom_colour()
	. = ..()
	update_slot_icon()

/// Modifies the fantasy variable
/obj/item/proc/modify_fantasy_variable(variable_key, value, bonus, minimum = 0)
	var/result = LAZYACCESS(fantasy_modifications, variable_key)
	if(!isnull(result))
		if(HAS_TRAIT(src, TRAIT_INNATELY_FANTASTICAL_ITEM))
			return result // we are immune to your foul magicks you inferior wizard, we keep our bonuses

		stack_trace("modify_fantasy_variable was called twice for the same key '[variable_key]' on type '[type]' before reset_fantasy_variable could be called!")

	var/intended_target = value + bonus
	value = max(minimum, intended_target)

	var/difference = intended_target - value
	var/modified_amount = bonus - difference
	LAZYSET(fantasy_modifications, variable_key, modified_amount)
	return value

/// Returns the original fantasy variable value
/obj/item/proc/reset_fantasy_variable(variable_key, current_value)
	var/modification = LAZYACCESS(fantasy_modifications, variable_key)

	if(isnum(modification) && HAS_TRAIT(src, TRAIT_INNATELY_FANTASTICAL_ITEM))
		return modification // we are immune to your foul magicks you inferior wizard, we keep our bonuses the way they are

	LAZYREMOVE(fantasy_modifications, variable_key)
	if(isnull(modification))
		return current_value

	return current_value - modification

/obj/item/proc/apply_fantasy_bonuses(bonus)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_ITEM_APPLY_FANTASY_BONUSES, bonus)
	force = modify_fantasy_variable("force", force, bonus)
	throwforce = modify_fantasy_variable("throwforce", throwforce, bonus)
	wound_bonus = modify_fantasy_variable("wound_bonus", wound_bonus, bonus)
	exposed_wound_bonus = modify_fantasy_variable("exposed_wound_bonus", exposed_wound_bonus, bonus)
	toolspeed = modify_fantasy_variable("toolspeed", toolspeed, -bonus/10, minimum = 0.1)

/obj/item/proc/remove_fantasy_bonuses(bonus)
	SHOULD_CALL_PARENT(TRUE)
	force = reset_fantasy_variable("force", force)
	throwforce = reset_fantasy_variable("throwforce", throwforce)
	wound_bonus = reset_fantasy_variable("wound_bonus", wound_bonus)
	exposed_wound_bonus = reset_fantasy_variable("exposed_wound_bonus", exposed_wound_bonus)
	toolspeed = reset_fantasy_variable("toolspeed", toolspeed)
	SEND_SIGNAL(src, COMSIG_ITEM_REMOVE_FANTASY_BONUSES, bonus)

//automatically finds tool behavior if there is only one. requires an extension of the proc if a tool has multiple behaviors
/obj/item/proc/get_all_tool_behaviours()
	if (!isnull(tool_behaviour))
		return list(tool_behaviour)
	return null

/obj/item/animate_atom_living(mob/living/owner)
	return new /mob/living/basic/mimic/copy(drop_location(), src, owner)

/**
 * Used to update the weight class of the item in a way that other atoms can react to the change.
 *
 * Arguments:
 * * new_w_class - The new weight class of the item.
 *
 * Returns:
 * * TRUE if weight class was successfully updated
 * * FALSE otherwise
 */
/obj/item/proc/update_weight_class(new_w_class)
	if(w_class == new_w_class)
		return FALSE

	var/old_w_class = w_class
	w_class = new_w_class
	SEND_SIGNAL(src, COMSIG_ITEM_WEIGHT_CLASS_CHANGED, old_w_class, new_w_class)
	if(!isnull(loc))
		SEND_SIGNAL(loc, COMSIG_ATOM_CONTENTS_WEIGHT_CLASS_CHANGED, src, old_w_class, new_w_class)
	return TRUE

/**
 * Used to determine if an item should be considered contraband by N-spect scanners or scanner gates.
 * Returns true when an item has the contraband trait, or is included in the traitor uplink.
 */
/obj/item/proc/is_contraband()
	if(HAS_TRAIT(src, TRAIT_CONTRABAND))
		return TRUE
	for(var/datum/uplink_item/traitor_item as anything in SStraitor.uplink_items)
		if(istype(src, traitor_item.item))
			if(!(traitor_item.uplink_item_flags & SYNDIE_TRIPS_CONTRABAND))
				return FALSE
			return TRUE
	return FALSE

/obj/item/apply_main_material_effects(datum/material/main_material, amount, multiplier)
	. = ..()
	if (material_flags & MATERIAL_GREYSCALE)
		var/main_mat_type = main_material.type
		var/worn_path = get_material_greyscale_config(main_mat_type, greyscale_config_worn)
		var/lefthand_path = get_material_greyscale_config(main_mat_type, greyscale_config_inhand_left)
		var/righthand_path = get_material_greyscale_config(main_mat_type, greyscale_config_inhand_right)
		set_greyscale(
			new_worn_config = worn_path,
			new_inhand_left = lefthand_path,
			new_inhand_right = righthand_path
		)

	if ((material_flags & MATERIAL_AFFECT_STATISTICS) && !(material_flags & MATERIAL_NO_SLOWDOWN))
		var/flexibility = main_material.get_property(MATERIAL_FLEXIBILITY)
		// If the item applies slowdown only when worn, poor flexibility will increase our slowdown
		if (!(item_flags & SLOWS_WHILE_IN_HAND) && flexibility < 6)
			slowdown = max(slowdown >= 0 ? 0 : slowdown, slowdown + (flexibility - 6) * 0.025 * multiplier)

	if (!main_material.item_sound_override)
		return

	hitsound = main_material.item_sound_override
	usesound = main_material.item_sound_override
	mob_throw_hit_sound = main_material.item_sound_override
	equip_sound = main_material.item_sound_override
	pickup_sound = main_material.item_sound_override
	drop_sound = main_material.item_sound_override

/obj/item/remove_main_material_effects(datum/material/main_material, amount, multiplier)
	. = ..()
	if (material_flags & MATERIAL_GREYSCALE)
		set_greyscale(
			new_worn_config = initial(greyscale_config_worn),
			new_inhand_left = initial(greyscale_config_inhand_left),
			new_inhand_right = initial(greyscale_config_inhand_right)
		)

	if ((material_flags & MATERIAL_AFFECT_STATISTICS) && !(material_flags & MATERIAL_NO_SLOWDOWN))
		var/flexibility = main_material.get_property(MATERIAL_FLEXIBILITY)
		// If the item applies slowdown only when worn, poor flexibility will increase our slowdown
		if (!(item_flags & SLOWS_WHILE_IN_HAND) && flexibility < 6)
			slowdown = min(initial(slowdown), slowdown - (flexibility - 6) * 0.025 * multiplier)

	if (!main_material.item_sound_override)
		return

	hitsound = initial(hitsound)
	usesound = initial(usesound)
	mob_throw_hit_sound = initial(mob_throw_hit_sound)
	equip_sound = initial(equip_sound)
	pickup_sound = initial(pickup_sound)
	drop_sound = initial(drop_sound)

/obj/item/apply_single_mat_effect(datum/material/material, mat_amount, multiplier)
	. = ..()
	if (!(material_flags & MATERIAL_AFFECT_STATISTICS))
		return

	var/siemens_modifier = material.get_property(MATERIAL_INSULATION)
	// Cannot use the base formula as it would make any item with glass not conduct electricity
	if (siemens_modifier > 1)
		siemens_coefficient *= 1 + (siemens_modifier - 1) * multiplier
	else
		siemens_coefficient *= max(0, 1 - (1 - siemens_modifier) * multiplier)

	if (siemens_coefficient == 0)
		obj_flags &= ~CONDUCTS_ELECTRICITY

	if (!(material_flags & MATERIAL_NO_SLOWDOWN))
		change_material_slowdown(material, mat_amount, multiplier)

/obj/item/remove_single_mat_effect(datum/material/material, mat_amount, multiplier)
	. = ..()
	if (!(material_flags & MATERIAL_AFFECT_STATISTICS))
		return

	var/siemens_modifier = material.get_property(MATERIAL_INSULATION)
	// Cannot use the base formula as it would make any item with glass not conduct electricity
	if (siemens_modifier > 1)
		siemens_coefficient /= 1 + (siemens_modifier - 1) * multiplier
	else
		var/used_mult = 1 - (1 - siemens_modifier) * multiplier
		if (used_mult > 0) // Perfect insulators need to be restored in finalize
			siemens_coefficient /= used_mult

	if (siemens_coefficient > 0 && (initial(obj_flags) & CONDUCTS_ELECTRICITY) && !(obj_flags & CONDUCTS_ELECTRICITY))
		obj_flags |= CONDUCTS_ELECTRICITY

	if (!(material_flags & MATERIAL_NO_SLOWDOWN))
		change_material_slowdown(material, mat_amount, multiplier, removing = TRUE)

/obj/item/proc/change_material_slowdown(datum/material/material, mat_amount, multiplier, removing = FALSE)
	// Density above 6 adds slowdown, density below 3 can reduce existing slowdown
	var/density = material.get_property(MATERIAL_DENSITY)
	var/slowdown_change = 0

	if (density > 6)
		slowdown_change = (density - 6) * MATERIAL_DENSITY_SLOWDOWN * mat_amount / SHEET_MATERIAL_AMOUNT
	else if (density < 4)
		slowdown_change = (4 - density) * -MATERIAL_DENSITY_SLOWDOWN * mat_amount / SHEET_MATERIAL_AMOUNT

	if (!removing)
		// Slowdown cannot be reduced below 0 if the item slows you down, or at all if the item speeds you up
		if (slowdown_change)
			slowdown = max(slowdown >= 0 ? 0 : slowdown, slowdown + slowdown_change * multiplier)
		return

	if (slowdown_change > 0)
		slowdown -= slowdown_change * multiplier
	else if (slowdown_change < 0)
		// Not guaranteed to be correct if something modified our slowdown buuuut about as good as we can get
		slowdown = min(initial(slowdown), slowdown - slowdown_change * multiplier)

/obj/item/finalize_remove_material_effects(list/materials)
	. = ..()
	if (!(material_flags & MATERIAL_AFFECT_STATISTICS) || initial(siemens_coefficient) == 0 || siemens_coefficient != 0)
		return
	// If we were made from an insulator we cannot restore via division
	siemens_coefficient = initial(siemens_coefficient)
	if (siemens_coefficient > 0 && (initial(obj_flags) & CONDUCTS_ELECTRICITY) && !(obj_flags & CONDUCTS_ELECTRICITY))
		obj_flags |= CONDUCTS_ELECTRICITY

/obj/item/change_material_strength(datum/material/material, mat_amount, multiplier, remove = FALSE)
	var/force_mod = get_material_force_modifier(material)
	var/throwforce_mod = get_material_throwforce_modifier(material)

	if (!remove)
		force *= GET_MATERIAL_MODIFIER(force_mod, multiplier)
		throwforce *= GET_MATERIAL_MODIFIER(throwforce_mod, multiplier)
	else
		force /= GET_MATERIAL_MODIFIER(force_mod, multiplier)
		throwforce /= GET_MATERIAL_MODIFIER(throwforce_mod, multiplier)

/// Returns a force multiplier from a material for a given sharpness
/obj/item/proc/get_material_force_modifier(datum/material/material, item_sharpness = get_sharpness())
	var/density = material.get_property(MATERIAL_DENSITY)
	var/hardness = material.get_property(MATERIAL_HARDNESS)
	var/flexibility = material.get_property(MATERIAL_FLEXIBILITY)
	var/force_mod = 1
	switch (item_sharpness)
		if (NONE)
			// Blunt items are really hurt by all the flexing
			force_mod = (1 + (density - 4) * 0.1) / (1 + flexibility * 0.1)

		if (SHARP_EDGED)
			// Sharp items don't care about density and need high hardness to get a real bonus, but can tolerate (and benefit from) some flex
			force_mod = 1 + (hardness - 4) * 0.1

			// Peaks out at 20% at flexibility of 1, drops off up to -80% at 10
			if (flexibility < 2)
				force_mod *= 1 + (1 - abs(1 - flexibility)) * 0.2
			else
				force_mod *= 1 - (flexibility - 2) * 0.1

		if (SHARP_POINTY)
			// Pointy items care about both density and hardness
			force_mod = 1 + MATERIAL_PROPERTY_DIVERGENCE(density, 4, 6) * 0.05 + (hardness - 4) * 0.1
			// But are not affected by flexibility until higher values, although they don't benefit from it either
			if (flexibility > 4)
				force_mod *= (1 - (flexibility - 4) * 0.2)

	// Just for sanity in case something breaks
	force_mod = round(clamp(force_mod, MATERIAL_MIN_FORCE_MULTIPLIER, MATERIAL_MAX_FORCE_MULTIPLIER), 0.01)
	return force_mod

/// Returns a force multiplier from a material for a given sharpness
/obj/item/proc/get_material_throwforce_modifier(datum/material/material, item_sharpness = get_sharpness())
	var/density = material.get_property(MATERIAL_DENSITY)
	var/hardness = material.get_property(MATERIAL_HARDNESS)
	var/flexibility = material.get_property(MATERIAL_FLEXIBILITY)
	var/throwforce_mod = 1
	switch (item_sharpness)
		if (NONE)
			// Blunt items are really hurt by all the flexing
			throwforce_mod = 1 + (density - 4) * 0.1 - flexibility * 0.1

		if (SHARP_EDGED)
			// Sharp items don't care about density and need high hardness to get a real bonus, but can tolerate (and benefit from) some flex
			throwforce_mod = 1 + (hardness - 4) * 0.1

			// Peaks out at 20% at flexibility of 1, drops off up to -80% at 10
			if (flexibility < 2)
				throwforce_mod += (1 - abs(1 - flexibility)) * 0.2
			else
				throwforce_mod -= (flexibility - 2) * 0.1

		if (SHARP_POINTY)
			// Pointy items care about both density and hardness
			throwforce_mod = 1 + MATERIAL_PROPERTY_DIVERGENCE(density, 4, 6) * 0.05 * 0.05 + (hardness - 4) * 0.1
			// But are not affected by flexibility until higher values, although they don't benefit from it either
			if (flexibility > 4)
				throwforce_mod -= (flexibility - 4) * 0.2

	// Just for sanity in case something breaks
	throwforce_mod = round(clamp(throwforce_mod, MATERIAL_MIN_FORCE_MULTIPLIER, MATERIAL_MAX_FORCE_MULTIPLIER), 0.01)
	return throwforce_mod

/**
 * Returns the atom(either itself or an internal module) that will interact/attack the target on behalf of us
 * For example an object can have different `tool_behaviours` (e.g borg omni tool) but will return an internal reference of that tool to attack for us
 * You can use it for general purpose polymorphism if you need a proxy atom to interact in a specific way
 * with a target on behalf on this atom
 *
 * Currently used only in the object melee attack chain but can be used anywhere else or even moved up to the atom level if required
 */
/obj/item/proc/get_proxy_attacker_for(atom/target, mob/user)
	RETURN_TYPE(/obj/item)

	return src

/// Checks if the bait is liked by the fish type or not. Returns a multiplier that affects the chance of catching it.
/obj/item/proc/check_bait(obj/item/fish/fish)
	if(HAS_TRAIT(src, TRAIT_OMNI_BAIT))
		return 1
	var/catch_multiplier = 1

	var/list/properties = SSfishing.fish_properties[isfish(fish) ? fish.type : fish]
	//Bait matching likes doubles the chance
	var/list/fav_bait = properties[FISH_PROPERTIES_FAV_BAIT]
	for(var/bait_identifer in fav_bait)
		if(is_matching_bait(src, bait_identifer))
			catch_multiplier *= 2
	//Bait matching dislikes
	var/list/disliked_bait = properties[FISH_PROPERTIES_BAD_BAIT]
	for(var/bait_identifer in disliked_bait)
		if(is_matching_bait(src, bait_identifer))
			catch_multiplier *= 0.5
	return catch_multiplier

/// Helper proc that checks if a bait matches identifier from fav/disliked bait list
/proc/is_matching_bait(obj/item/bait, identifier)
	if(ispath(identifier)) //Just a path
		return istype(bait, identifier)
	if(!islist(identifier))
		return HAS_TRAIT(bait, identifier)
	var/list/special_identifier = identifier
	switch(special_identifier[FISH_BAIT_TYPE])
		if(FISH_BAIT_FOODTYPE)
			var/datum/component/edible/edible = bait.GetComponent(/datum/component/edible)
			return edible?.foodtypes & special_identifier[FISH_BAIT_VALUE]
		if(FISH_BAIT_REAGENT)
			return bait.reagents?.has_reagent(special_identifier[FISH_BAIT_VALUE], special_identifier[FISH_BAIT_AMOUNT], check_subtypes = TRUE)
		else
			CRASH("Unknown bait identifier in fish favourite/disliked list")

/obj/item/vv_get_header()
	. = ..()
	. += {"
		<br><font size='1'>
			DAMTYPE: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=damtype' id='damtype'>[uppertext(damtype)]</a>
			FORCE: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=force' id='force'>[force]</a>
			WOUND: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=wound' id='wound'>[wound_bonus]</a>
			BARE WOUND: <font size='1'><a href='byond://?_src_=vars;[HrefToken()];item_to_tweak=[REF(src)];var_tweak=bare wound' id='bare wound'>[exposed_wound_bonus]</a>
		</font>
	"}

/// Fetches, or lazyloads, our embedding datum
/obj/item/proc/get_embed()
	RETURN_TYPE(/datum/embedding)
	// Something may call this during qdeleting, which would cause a harddel
	if (QDELETED(src))
		return null
	if (embed_data)
		return embed_data
	if (embed_type)
		embed_data = new embed_type(src)
	return embed_data

/// Sets our embedding datum to a different one. Can also take types
/obj/item/proc/set_embed(datum/embedding/new_embed)
	if (new_embed == embed_data)
		return

	// Needs to be QDELETED as embed data uses this to clean itself up from its parent (us)
	if (!QDELETED(embed_data))
		qdel(embed_data)

	if (ispath(new_embed))
		new_embed = new new_embed(src)

	embed_data = new_embed
	SEND_SIGNAL(src, COMSIG_ITEM_EMBEDDING_UPDATE)

/// Embed ourselves into an object if we possess embedding data
/obj/item/proc/force_embed(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	if (!istype(victim))
		return FALSE

	if (!istype(target_limb))
		target_limb = victim.get_bodypart(target_limb) || victim.get_bodypart()

	return get_embed()?.embed_into(victim, target_limb)

/// Checks if user can insert a valid container into the chemistry machine.
/obj/item/proc/can_insert_container(mob/living/user, obj/machinery/chem_machine)
	return is_chem_container() && chem_machine.can_interact(user) && user.can_perform_action(chem_machine, ALLOW_SILICON_REACH | FORBID_TELEKINESIS_REACH)

/// Checks if this container is valid for use with chemistry machinery.
/obj/item/proc/is_chem_container()
	return FALSE
