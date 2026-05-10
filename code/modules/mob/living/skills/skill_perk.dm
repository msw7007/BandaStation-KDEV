/datum/cy_skill_perk
	/// Player-facing name.
	var/name = "Unknown perk"

	/// Short machine-readable id for logs/save/UI.
	var/id = "unknown"

	/// Description for later UI.
	var/desc = ""

	/// Skill level this perk belongs to.
	var/level = CY_SKILL_LEVEL_UNTRAINED

	/// Skill typepath this perk belongs to. Optional, but useful for UI/logs.
	var/skill_type = null

/datum/cy_skill_perk/proc/on_gain(mob/living/owner)
	return

/datum/cy_skill_perk/proc/on_loss(mob/living/owner)
	return
