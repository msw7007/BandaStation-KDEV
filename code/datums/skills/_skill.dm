GLOBAL_LIST_INIT(skill_types, valid_subtypesof(/datum/skill))

/datum/skill_perk
	var/datum/skill/owner
	var/index = 0
	var/name = "Perk"
	var/desc = ""
	var/max_rank = 1
	/// Optional rank-specific descriptions. If unset, desc is scaled through owner perk multipliers.
	var/list/rank_descriptions

/datum/skill_perk/New(datum/skill/new_owner, new_index, new_name, new_desc, new_max_rank, list/new_rank_descriptions = null)
	. = ..()
	owner = new_owner
	index = normalize_rank(new_index)
	name = new_name
	desc = new_desc
	max_rank = max(normalize_rank(new_max_rank), 1)
	rank_descriptions = new_rank_descriptions

/datum/skill_perk/proc/normalize_rank(value)
	if(!isnum(value))
		value = text2num("[value]")
	return round(value || 0)

/datum/skill_perk/proc/get_description(rank = 1)
	rank = clamp(normalize_rank(rank), 1, max_rank)
	if(length(rank_descriptions))
		if(rank <= length(rank_descriptions))
			var/rank_description = rank_descriptions[rank]
			if(rank_description)
				return rank_description
		return desc
	return owner ? owner.scale_perk_description(desc, owner.get_perk_power_multiplier(rank)) : desc

/datum/skill_perk/proc/get_rank_descriptions()
	var/list/descriptions = list()
	for(var/rank in 1 to max_rank)
		descriptions += get_description(rank)
	return descriptions

/datum/skill_perk/proc/get_rank(datum/mind/mind)
	if(!mind || !owner)
		return 0
	return mind.get_character_perk_rank(owner.type, index)

/datum/skill_perk/proc/has_rank(datum/mind/mind, required_rank = 1)
	return get_rank(mind) >= normalize_rank(required_rank)

/datum/skill_perk/proc/get_effectiveness(datum/mind/mind)
	if(!owner)
		return 0
	return owner.get_perk_power_multiplier(get_rank(mind))

/datum/skill_perk/proc/passes_check(datum/mind/mind, required_rank = 1, probability = 100)
	if(!has_rank(mind, required_rank))
		return FALSE
	return prob(clamp(probability, 0, 100))

/datum/skill_perk/proc/get_check_result(datum/mind/mind, required_rank = 1, probability = 100)
	var/current_rank = get_rank(mind)
	var/effectiveness = owner ? owner.get_perk_power_multiplier(current_rank) : 0
	var/has_required_rank = current_rank >= normalize_rank(required_rank)
	return list(
		"has_perk" = has_required_rank,
		"rank" = current_rank,
		"required_rank" = normalize_rank(required_rank),
		"effectiveness" = effectiveness,
		"description" = get_description(max(current_rank, normalize_rank(required_rank))),
		"passed" = has_required_rank && prob(clamp(probability, 0, 100)),
	)

/datum/skill_perk/proc/can_set_rank(datum/mind/mind, new_rank, free = FALSE, allow_sequence_break = FALSE)
	if(!mind || !owner)
		return FALSE
	if(index < 1 || index > length(owner.perks))
		return FALSE
	new_rank = normalize_rank(new_rank)
	if(new_rank < 0 || new_rank > max_rank)
		return FALSE

	var/old_rank = get_rank(mind)
	var/point_delta = new_rank - old_rank
	if(!mind.can_pay_character_skill_points(owner.type, point_delta, free))
		return FALSE

	if(!allow_sequence_break && owner.requires_sequential_perks)
		if(new_rank > 0)
			if(index > 1)
				for(var/previous_index in 1 to index - 1)
					if(mind.get_character_perk_rank(owner.type, previous_index) <= 0)
						return FALSE
		else
			if(index < length(owner.perks))
				for(var/later_index in index + 1 to length(owner.perks))
					if(mind.get_character_perk_rank(owner.type, later_index) > 0)
						return FALSE
	return TRUE

/datum/skill_perk/proc/set_rank(datum/mind/mind, new_rank, free = FALSE, allow_sequence_break = FALSE)
	new_rank = normalize_rank(new_rank)
	if(!can_set_rank(mind, new_rank, free, allow_sequence_break))
		return FALSE
	var/old_rank = get_rank(mind)
	var/list/perk_ranks = mind.get_character_perk_list(owner.type)
	var/perk_key = mind.get_character_perk_key(index)
	if(new_rank <= 0)
		perk_ranks -= perk_key
	else
		perk_ranks[perk_key] = new_rank
	mind.pay_character_skill_points(owner.type, new_rank - old_rank, free)
	return TRUE

/datum/skill_perk/proc/adjust_rank(datum/mind/mind, amount = 1, free = FALSE, allow_sequence_break = FALSE)
	amount = normalize_rank(amount)
	return set_rank(mind, get_rank(mind) + amount, free, allow_sequence_break)

/datum/skill
	abstract_type = /datum/skill
	var/name = "Skilling"
	var/title = "Skiller"
	var/desc = "the art of doing things"
	/// Attribute id used by Cyberpunk character checks.
	var/attribute_id
	/// Legacy tg skills use experience; Cyberpunk skills use perks or direct levels.
	var/skill_kind = CHARACTER_SKILL_KIND_LEGACY
	/// Point pool used when buying this skill's perks/levels.
	var/point_pool = CHARACTER_SKILL_POOL_NONE
	/// Maximum Cyberpunk skill level. Legacy skills keep SKILL_EXP_LIST.
	var/max_character_level = 0
	/// Maximum rank per perk. Physical is 3, professional is 4.
	var/max_perk_rank = 0
	/// Whether later perks require every previous perk to be known.
	var/requires_sequential_perks = FALSE
	/// Display-only giga perk metadata for the parent attribute.
	var/giga_perk_name
	var/giga_perk_desc
	/// Perk descriptors as list(list(name, desc), ...). Built into /datum/skill_perk instances in New().
	var/list/perk_definitions
	/// Runtime perk datums.
	var/list/perks
	/// Weapon skill static bonuses per level.
	var/weapon_damage_bonus_per_level = 0
	var/weapon_cooldown_reduction_per_level = 0
	var/weapon_defense_break_bonus_per_level = 0
	///Dictionary of modifier type - list of modifiers (indexed by level). 7 entries in each list for all 7 skill levels.
	var/modifiers = list(SKILL_SPEED_MODIFIER = list(1, 1, 1, 1, 1, 1, 1)) //Dictionary of modifier type - list of modifiers (indexed by level). 7 entries in each list for all 7 skill levels.
	///List Path pointing to the skill item reward that will appear when a user finishes leveling up a skill
	var/skill_item_path
	///List associating different messages that appear on level up with different levels
	var/list/levelUpMessages = list()
	///List associating different messages that appear on level up with different levels
	var/list/levelDownMessages = list()

/datum/skill/proc/get_skill_modifier(modifier, level)
	return modifiers[modifier][level] //Levels range from 1 (None) to 7 (Legendary)

/datum/skill/proc/is_character_skill()
	return skill_kind != CHARACTER_SKILL_KIND_LEGACY

/datum/skill/proc/uses_perks()
	return max_perk_rank > 0

/datum/skill/proc/get_perk(index)
	if(!isnum(index))
		index = text2num("[index]")
	index = round(index || 0)
	return perks?[index]

/datum/skill/proc/get_perk_power_multiplier(rank)
	if(!isnum(rank))
		rank = text2num("[rank]")
	rank = round(rank || 0)
	if(rank <= 0)
		return 0
	var/list/multipliers = skill_kind == CHARACTER_SKILL_KIND_PROFESSIONAL ? CHARACTER_PROFESSIONAL_PERK_POWER_MULTIPLIERS : CHARACTER_PHYSICAL_PERK_POWER_MULTIPLIERS
	return multipliers[clamp(rank, 1, length(multipliers))]

/datum/skill/proc/format_scaled_perk_percent(raw_value, multiplier)
	var/has_plus = findtext(raw_value, "+") == 1
	var/scaled = text2num(replacetext(raw_value, ",", ".")) * multiplier
	var/rounded = round(scaled, 0.1)
	var/formatted = "[rounded]"
	if(round(rounded) == rounded)
		formatted = "[round(rounded)]"
	if(has_plus && rounded > 0)
		formatted = "+[formatted]"
	return "[replacetext(formatted, ".", ",")]%"

/datum/skill/proc/scale_perk_description(description, multiplier)
	if(!description)
		return "Нет описания эффекта."
	var/regex/percent_pattern = regex(@"([+-]?\d+(?:[.,]\d+)?)%", "g")
	var/output = ""
	var/search_from = 1
	var/found_any = FALSE
	var/match_start
	while((match_start = percent_pattern.Find(description, search_from)))
		found_any = TRUE
		var/match_end = match_start + length(percent_pattern.match)
		output += copytext(description, search_from, match_start)
		output += format_scaled_perk_percent(percent_pattern.group[1], multiplier)
		search_from = match_end
	output += copytext(description, search_from)
	if(found_any)
		return output
	if(multiplier != 1)
		return "[description] ([round(multiplier * 100)]% эффективности)"
	return description

/**
 * new: sets up some lists.
 *
 *Can't happen in the datum's definition because these lists are not constant expressions
 */
/datum/skill/New()
	. = ..()
	if(length(perk_definitions))
		perks = list()
		for(var/i in 1 to length(perk_definitions))
			var/list/perk_definition = perk_definitions[i]
			if(length(perk_definition) < 2)
				continue
			var/list/perk_rank_descriptions
			if(length(perk_definition) >= 3)
				perk_rank_descriptions = perk_definition[3]
			perks += new /datum/skill_perk(src, i, perk_definition[1], perk_definition[2], max_perk_rank, perk_rank_descriptions)
	levelUpMessages = list(span_nicegreen("What the hell is [name]? Tell an admin if you see this message."), //This first index shouldn't ever really be used
	span_nicegreen("I'm starting to figure out what [name] really is!"),
	span_nicegreen("I'm getting a little better at [name]!"),
	span_nicegreen("I'm getting much better at [name]!"),
	span_nicegreen("I feel like I've become quite proficient at [name]!"),
	span_nicegreen("After lots of practice, I've begun to truly understand the intricacies and surprising depth behind [name]. I now consider myself a master [title]."),
	span_nicegreen("Through incredible determination and effort, I've reached the peak of my [name] abiltities. I'm finally able to consider myself a legendary [title]!") )
	levelDownMessages = list(span_nicegreen("I have somehow completely lost all understanding of [name]. Please tell an admin if you see this."),
	span_nicegreen("I'm starting to forget what [name] really even is. I need more practice..."),
	span_nicegreen("I'm getting a little worse at [name]. I'll need to keep practicing to get better at it..."),
	span_nicegreen("I'm getting a little worse at [name]..."),
	span_nicegreen("I'm losing my [name] expertise ...."),
	span_nicegreen("I feel like I'm losing my mastery of [name]."),
	span_nicegreen("I feel as though my legendary [name] skills have deteriorated. I'll need more intense training to recover my lost skills.") )

/**
 * level_gained: Gives skill levelup messages to the user
 *
 * Only fires if the xp gain isn't silent, so only really useful for messages.
 * Arguments:
 * * mind - The mind that you'll want to send messages
 * * new_level - The newly gained level. Can check the actual level to give different messages at different levels, see defines in skills.dm
 * * old_level - Similar to the above, but the level you had before levelling up.
 * * silent - Silences the announcement if TRUE
 */
/datum/skill/proc/level_gained(datum/mind/mind, new_level, old_level, silent)
	if(silent)
		return
	to_chat(mind.current, levelUpMessages[new_level]) //new_level will be a value from 1 to 6, so we get appropriate message from the 6-element levelUpMessages list
/**
 * level_lost: See level_gained, same idea but fires on skill level-down
 */
/datum/skill/proc/level_lost(datum/mind/mind, new_level, old_level, silent)
	if(silent)
		return
	to_chat(mind.current, levelDownMessages[old_level]) //old_level will be a value from 1 to 6, so we get appropriate message from the 6-element levelUpMessages list

/**
 * try_skill_reward: Checks to see if a user is eligable for a tangible reward for reaching a certain skill level
 *
 * Currently gives the user a special cloak when they reach a legendary level at any given skill
 * Arguments:
 * * mind - The mind that you'll want to send messages and rewards to
 * * new_level - The current level of the user. Used to check if it meets the requirements for a reward
 */
/datum/skill/proc/try_skill_reward(datum/mind/mind, new_level)
	if (new_level != SKILL_LEVEL_LEGENDARY)
		return
	if (!ispath(skill_item_path))
		to_chat(mind.current, span_nicegreen("My legendary [name] skill is quite impressive, though it seems the Professional [title] Association doesn't have any status symbols to commemorate my abilities with. I should let Centcom know of this travesty, maybe they can do something about it."))
		return
	if (LAZYFIND(mind.skills_rewarded, src.type))
		to_chat(mind.current, span_nicegreen("It seems the Professional [title] Association won't send me another status symbol."))
		return
	podspawn(list(
		"target" = get_turf(mind.current),
		"path" = /obj/structure/closet/supplypod/teleporter, // BANDASTATION EDIT - Original: "style" = /datum/pod_style/advanced,
		"spawn" = skill_item_path,
		"delays" = list(POD_TRANSIT = 150, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
	))
	to_chat(mind.current, span_nicegreen("My legendary skill has attracted the attention of the Professional [title] Association. It seems they are sending me a status symbol to commemorate my abilities."))
	LAZYADD(mind.skills_rewarded, src.type)
