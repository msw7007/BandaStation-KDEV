GLOBAL_LIST_INIT(skill_types, valid_subtypesof(/datum/skill))

/datum/skill_perk
	var/datum/skill/owner
	var/index = 0
	var/name = "Perk"
	var/desc = ""
	var/max_rank = 1

/datum/skill_perk/New(datum/skill/new_owner, new_index, new_name, new_desc, new_max_rank)
	. = ..()
	owner = new_owner
	index = new_index
	name = new_name
	desc = new_desc
	max_rank = new_max_rank

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
	return perks?[index]

/datum/skill/proc/get_perk_power_multiplier(rank)
	if(rank <= 0)
		return 0
	var/list/multipliers = skill_kind == CHARACTER_SKILL_KIND_PROFESSIONAL ? CHARACTER_PROFESSIONAL_PERK_POWER_MULTIPLIERS : CHARACTER_PHYSICAL_PERK_POWER_MULTIPLIERS
	return multipliers[clamp(rank, 1, length(multipliers))]

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
			perks[i] = new /datum/skill_perk(src, i, perk_definition[1], perk_definition[2], max_perk_rank)
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
