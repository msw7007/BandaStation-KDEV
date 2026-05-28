// Cyberpunk 13 cyberspace: cyberspace hostile programs.
// Split from cyberimp internals; keep gameplay logic out of organ item definitions.

/mob/living/basic/cyberspace_alternative
	name = "alternative"
	desc = "An aggressive Veil program, shaped like a yellow animal imprint."
	icon = 'icons/mob/nonhuman-player/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	color = "#ffd447"
	alpha = 190
	health = 45
	maxHealth = 45
	melee_damage_lower = 6
	melee_damage_upper = 12
	obj_damage = 10
	mob_biotypes = MOB_ROBOTIC
	basic_mob_flags = DEL_ON_DEATH
	faction = list(FACTION_HOSTILE)
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile

/mob/living/basic/cyberspace_alternative/death(gibbed)
	if(!gibbed && prob(35))
		new /obj/item/cyberspace_storage/reward(drop_location())
	return ..()
