/datum/cy_skill_perk/professional/music
	skill_type = /datum/cy_skill/professional/music

/datum/cy_skill_perk/professional/music/level_1
	id = "music_1"
	level = 1
	name = "Music 1"
	desc_template = "Instrument play creates weak mood effect around the performer."
	effects = list(
		"level" = 1,
	)

/datum/cy_skill_perk/professional/music/level_2
	id = "music_2"
	level = 2
	name = "Music 2"
	desc_template = "Instrument play creates strong mood effect around the performer for {value_1} seconds."
	effects = list(
		"level" = 2,
		"value_1" = 8
	)

/datum/cy_skill_perk/professional/music/level_3
	id = "music_3"
	level = 3
	name = "Music 3"
	desc_template = "Can apply buffs to cohort members, restoring {value_1} stamina per tick before cohort multiplier."
	effects = list(
		"level" = 3,
		"value_1" = 1
	)

/datum/cy_skill_perk/professional/music/level_4
	id = "music_4"
	level = 4
	name = "Music 4"
	desc_template = "Instrument can be used as a melee weapon with at least {value_1} force."
	effects = list(
		"level" = 4,
		"value_1" = 15
	)

/datum/cy_skill_perk/professional/music/level_5
	id = "music_5"
	level = 5
	name = "Music 5"
	desc_template = "Can apply debuffs to non-cohort listeners: {value_1}% chance for up to {value_2} seconds of confusion."
	effects = list(
		"level" = 5,
		"value_1" = 3,
		"value_2" = 3
	)

/datum/cy_skill_perk/professional/music/level_6
	id = "music_6"
	level = 6
	name = "Music 6"
	desc_template = "Can deal and heal damage with music: heals {value_1} pain for cohort, {value_2}% chance to deal {value_3} stamina damage to others."
	effects = list(
		"level" = 6,
		"value_1" = 1,
		"value_2" = 2,
		"value_3" = 2
	)
