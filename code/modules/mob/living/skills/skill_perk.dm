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

	/// Percent bonus this perk contributes to checks for its skill.
	var/check_bonus = 0

	/// Percent bonus this perk contributes to future skill experience gains.
	var/experience_bonus = 0

	/// Percent bonus this perk contributes to work/crafting/action speed.
	var/work_speed_bonus = 0

	/// Percent bonus this perk contributes to result quality/reliability.
	var/quality_bonus = 0

/proc/cy_skill_perk_trait(skill_type, level)
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(!skill)
		return null

	return "cy_skill_perk_[skill.id]_[clamp(round(level), CY_SKILL_MINIMUM_LEVEL, skill.max_level)]"

/datum/cy_skill_perk/proc/on_gain(mob/living/owner)
	var/perk_trait = cy_skill_perk_trait(skill_type, level)
	if(perk_trait)
		ADD_TRAIT(owner, perk_trait, CY_SKILL_PERK_TRAIT)
	return

/datum/cy_skill_perk/proc/on_loss(mob/living/owner)
	var/perk_trait = cy_skill_perk_trait(skill_type, level)
	if(perk_trait)
		REMOVE_TRAIT(owner, perk_trait, CY_SKILL_PERK_TRAIT)
	return

/datum/cy_skill_perk/proc/modify_check_chance(chance)
	return chance + check_bonus

/datum/cy_skill_perk/proc/modify_experience_gain(experience)
	return experience * (1 + (experience_bonus / 100))

/datum/cy_skill_perk/proc/modify_work_speed_modifier(modifier)
	return modifier + work_speed_bonus

/datum/cy_skill_perk/proc/modify_quality_modifier(modifier)
	return modifier + quality_bonus

/datum/cy_skill_perk/proc/get_effect_summary()
	var/list/parts = list()
	if(check_bonus)
		parts += "+[check_bonus]% skill checks"
	if(experience_bonus)
		parts += "+[experience_bonus]% skill experience"
	if(work_speed_bonus)
		parts += "+[work_speed_bonus]% work speed"
	if(quality_bonus)
		parts += "+[quality_bonus]% result quality"

	if(!length(parts))
		return "Unlocks the next skill rank."

	return english_list(parts)

/datum/cy_skill_perk/proc/apply_skill_context()
	return

/proc/cy_generic_skill_perk_for_level(level)
	switch(level)
		if(1)
			return /datum/cy_skill_perk/generic/level_1
		if(2)
			return /datum/cy_skill_perk/generic/level_2
		if(3)
			return /datum/cy_skill_perk/generic/level_3
		if(4)
			return /datum/cy_skill_perk/generic/level_4
		if(5)
			return /datum/cy_skill_perk/generic/level_5
		if(6)
			return /datum/cy_skill_perk/generic/level_6

	return /datum/cy_skill_perk/generic/level_1

/datum/cy_skill_perk/generic
	name = "Skill perk"
	id = "skill_perk"
	desc = "A generic character setup perk backing a skill level."

/datum/cy_skill_perk/generic/New()
	. = ..()
	check_bonus = level * CY_SKILL_PERK_CHECK_BONUS_PER_LEVEL
	experience_bonus = level * CY_SKILL_PERK_EXPERIENCE_BONUS_PER_LEVEL
	work_speed_bonus = level * CY_SKILL_PERK_WORK_SPEED_BONUS_PER_LEVEL
	quality_bonus = level * CY_SKILL_PERK_QUALITY_BONUS_PER_LEVEL
	desc = get_effect_summary()

/datum/cy_skill_perk/generic/level_1
	name = "Initiate"
	id = "level_1"
	level = 1

/datum/cy_skill_perk/generic/level_2
	name = "Operator"
	id = "level_2"
	level = 2

/datum/cy_skill_perk/generic/level_3
	name = "Specialist"
	id = "level_3"
	level = 3

/datum/cy_skill_perk/generic/level_4
	name = "Expert"
	id = "level_4"
	level = 4

/datum/cy_skill_perk/generic/level_5
	name = "Professional"
	id = "level_5"
	level = 5

/datum/cy_skill_perk/generic/level_6
	name = "Master"
	id = "level_6"
	level = 6

/datum/cy_skill_perk/professional
	name = "Professional perk"
	id = "professional_perk"
	desc = "A profession-focused skill perk."

/datum/cy_skill_perk/professional/New()
	. = ..()
	desc = get_effect_summary()

/datum/cy_skill_perk/professional/apply_skill_context()
	. = ..()
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(skill)
		name = "[skill.name] [level]"
	desc = cy_professional_perk_effect(skill_type, level) || get_effect_summary()

/datum/cy_skill_perk/professional/apprentice
	name = "Apprentice practice"
	id = "professional_apprentice"
	level = 1
	experience_bonus = 5
	work_speed_bonus = 2

/datum/cy_skill_perk/professional/journeyman
	name = "Journeyman rhythm"
	id = "professional_journeyman"
	level = 2
	experience_bonus = 5
	work_speed_bonus = 4

/datum/cy_skill_perk/professional/reliable
	name = "Reliable hands"
	id = "professional_reliable"
	level = 3
	check_bonus = 4
	quality_bonus = 5

/datum/cy_skill_perk/professional/specialist
	name = "Specialist workflow"
	id = "professional_specialist"
	level = 4
	work_speed_bonus = 6
	quality_bonus = 5

/datum/cy_skill_perk/professional/expert
	name = "Expert standards"
	id = "professional_expert"
	level = 5
	check_bonus = 6
	quality_bonus = 10

/datum/cy_skill_perk/professional/master
	name = "Master craft"
	id = "professional_master"
	level = 6
	check_bonus = 8
	experience_bonus = 10
	work_speed_bonus = 8
	quality_bonus = 15

// Stat-linked perk shells. Runtime effects are keyed by the trait granted for skill_type + level.
/datum/cy_skill_perk/stat_linked
	name = "Prepared stat perk"
	id = "stat_linked_prepared"
	desc = "Prepared stat-linked perk hook. Not assigned to any skill tree yet."
	var/stat_path
	var/skill_path

/datum/cy_skill_perk/stat_linked/New()
	. = ..()
	desc = get_effect_summary()

/datum/cy_skill_perk/stat_linked/get_effect_summary()
	return ..()

/datum/cy_skill_perk/stat_linked/apply_skill_context()
	. = ..()
	var/datum/cy_skill/skill = get_cy_skill_datum(skill_type)
	if(skill)
		name = "[skill.name] [level]"
	desc = cy_stat_linked_perk_effect(skill_type, level) || get_effect_summary()

/datum/cy_skill_perk/stat_linked/level_1
	name = "Stat practice"
	id = "stat_linked_1"
	level = 1
	check_bonus = 2
	experience_bonus = 2

/datum/cy_skill_perk/stat_linked/level_2
	name = "Stat routine"
	id = "stat_linked_2"
	level = 2
	check_bonus = 3
	work_speed_bonus = 2

/datum/cy_skill_perk/stat_linked/level_3
	name = "Stat discipline"
	id = "stat_linked_3"
	level = 3
	check_bonus = 4
	experience_bonus = 4
	work_speed_bonus = 3

/datum/cy_skill_perk/stat_linked/level_4
	name = "Stat specialization"
	id = "stat_linked_4"
	level = 4
	check_bonus = 5
	work_speed_bonus = 5
	quality_bonus = 2

/datum/cy_skill_perk/stat_linked/level_5
	name = "Stat expertise"
	id = "stat_linked_5"
	level = 5
	check_bonus = 7
	experience_bonus = 6
	work_speed_bonus = 6
	quality_bonus = 3

/datum/cy_skill_perk/stat_linked/level_6
	name = "Stat mastery"
	id = "stat_linked_6"
	level = 6
	check_bonus = 10
	experience_bonus = 8
	work_speed_bonus = 8
	quality_bonus = 5

/datum/cy_skill_perk/stat_linked/strength/power_melee
	name = "Power melee stat hook"
	id = "stat_power_melee_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/power_melee

/datum/cy_skill_perk/stat_linked/strength/heavy_weapons
	name = "Heavy weapons stat hook"
	id = "stat_heavy_weapons_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/heavy_weapons

/datum/cy_skill_perk/stat_linked/strength/grappling
	name = "Grappling stat hook"
	id = "stat_grappling_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/grappling

/datum/cy_skill_perk/stat_linked/strength/toughness
	name = "Toughness stat hook"
	id = "stat_toughness_hook"
	stat_path = /datum/cy_stat/strength
	skill_path = /datum/cy_skill/strength/toughness

/datum/cy_skill_perk/stat_linked/dexterity/fast_melee
	name = "Fast melee stat hook"
	id = "stat_fast_melee_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/fast_melee

/datum/cy_skill_perk/stat_linked/dexterity/light_weapons
	name = "Light weapons stat hook"
	id = "stat_light_weapons_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/light_weapons

/datum/cy_skill_perk/stat_linked/dexterity/acrobatics
	name = "Acrobatics stat hook"
	id = "stat_acrobatics_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/acrobatics

/datum/cy_skill_perk/stat_linked/dexterity/evasion
	name = "Evasion stat hook"
	id = "stat_evasion_hook"
	stat_path = /datum/cy_stat/dexterity
	skill_path = /datum/cy_skill/dexterity/evasion

/datum/cy_skill_perk/stat_linked/perception/precise_melee
	name = "Precise melee stat hook"
	id = "stat_precise_melee_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/precise_melee

/datum/cy_skill_perk/stat_linked/perception/throwing
	name = "Throwing stat hook"
	id = "stat_throwing_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/throwing

/datum/cy_skill_perk/stat_linked/perception/weakspot_analysis
	name = "Weakspot analysis stat hook"
	id = "stat_weakspot_analysis_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/weakspot_analysis

/datum/cy_skill_perk/stat_linked/perception/concentration
	name = "Concentration stat hook"
	id = "stat_concentration_hook"
	stat_path = /datum/cy_stat/perception
	skill_path = /datum/cy_skill/perception/concentration

/datum/cy_skill_perk/stat_linked/intelligence/improved_code
	name = "Improved code stat hook"
	id = "stat_improved_code_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/improved_code

/datum/cy_skill_perk/stat_linked/intelligence/fast_code
	name = "Fast code stat hook"
	id = "stat_fast_code_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/fast_code

/datum/cy_skill_perk/stat_linked/intelligence/hacking
	name = "Hacking stat hook"
	id = "stat_hacking_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/hacking

/datum/cy_skill_perk/stat_linked/intelligence/composure
	name = "Composure stat hook"
	id = "stat_intelligence_composure_hook"
	stat_path = /datum/cy_stat/intelligence
	skill_path = /datum/cy_skill/intelligence/composure

/datum/cy_skill_perk/stat_linked/spirit/survival
	name = "Survival stat hook"
	id = "stat_survival_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/survival

/datum/cy_skill_perk/stat_linked/spirit/endurance
	name = "Endurance stat hook"
	id = "stat_spirit_endurance_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/endurance

/datum/cy_skill_perk/stat_linked/spirit/athletics
	name = "Athletics stat hook"
	id = "stat_athletics_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/athletics

/datum/cy_skill_perk/stat_linked/spirit/compatibility
	name = "Compatibility stat hook"
	id = "stat_compatibility_hook"
	stat_path = /datum/cy_stat/spirit
	skill_path = /datum/cy_skill/spirit/compatibility

/datum/cy_skill_perk/stat_linked/charisma/stealth
	name = "Stealth stat hook"
	id = "stat_stealth_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/stealth

/datum/cy_skill_perk/stat_linked/charisma/theft
	name = "Theft stat hook"
	id = "stat_theft_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/theft

/datum/cy_skill_perk/stat_linked/charisma/inspiration
	name = "Inspiration stat hook"
	id = "stat_inspiration_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/inspiration

/datum/cy_skill_perk/stat_linked/charisma/style
	name = "Style stat hook"
	id = "stat_style_hook"
	stat_path = /datum/cy_stat/charisma
	skill_path = /datum/cy_skill/charisma/style

/proc/cy_professional_perk_effect(skill_type, level)
	var/list/effects
	switch(skill_type)
		if(/datum/cy_skill/professional/medicine)
			effects = list("No visual examine penalty; no surgery failure penalty.", "+20% base surgery success, +15% surgery step speed.", "Advanced surgeries unlocked at 50% failure risk; +20% surgery step speed.", "+30% total surgery success, self-surgery allowed, infection chance -25%.", "Specialized surgeries unlocked; +20% base surgery success; environment no longer affects infection chance.", "Environment no longer affects surgery speed or failure chance; all tool compatibility +30%.")
		if(/datum/cy_skill/professional/chemistry)
			effects = list("Reaction tick instability reduced to 2% random acidity/temperature drift.", "Can identify simple chemicals; no untrained penalty.", "Reaction temperature drift -5%, reaction speed +5%.", "Can identify compound chemicals by smell; reaction speed +5%.", "Can examine chemical purity; starting temperature drift -5%.", "Critical mass explosion delayed by 10%; all chemicals gain +25% purity and effectiveness.")
		if(/datum/cy_skill/professional/electricity)
			effects = list("No rubber-glove shock penalty.", "Electric shock paralysis is 2 seconds shorter.", "Live wire shock chance is reduced to 50%.", "50% chance to avoid shock when grabbing or holding an electrocuted person.", "Signal types are highlighted when dismantling protected panels.", "Shock chance is reduced by 50% even without insulation.")
		if(/datum/cy_skill/professional/construction)
			effects = list("No construction/repair time and structure health penalty.", "Repair time -20%, construction speed +20%.", "Built structure health +20%.", "Attacks against structures deal +100% structure damage.", "Can reinforce structures for extra resources; 30% chance not to consume construction resource.", "Deconstructing structures has 30% chance to drop extra material.")
		if(/datum/cy_skill/professional/invention)
			effects = list("No item creation/repair time and item health penalty.", "Creation explosion chance reduced from 20% to 0%.", "Disassembly speed +30%, assembly speed +10%.", "Can reconfigure an item without dismantling it.", "Assembly speed +30%, created item health +30%.", "4% chance to create a copy without spending resources; disassembly speed +40%.")
		if(/datum/cy_skill/professional/analysis)
			effects = list("No analysis time penalty and no result skip penalty.", "Analysis speed +25%.", "Destroying an analyzed object has 20% chance to produce its material.", "Material chance rises to 50%; analysis speed +25%.", "Analyzed items can satisfy crafting ingredient requirements when their composition matches.", "20% chance to extract technology/blueprint from analyzed structures or items.")
		if(/datum/cy_skill/professional/mining)
			effects = list("No mining time penalty and no extra empty-yield penalty.", "Mining time -25%; pick use pulls you to the mined tile; drill starts faster.", "2% chance to turn empty yield into resource; 10% chance to duplicate mined resource.", "Can see ore richness; rich ore improves empty-yield conversion.", "+1% base empty-to-resource chance; resource duplication chance rises to 25%.", "Mining speed reduced to 25% of base time; drills and picks do not break; drill primes instantly and uses 25% less energy.")
		if(/datum/cy_skill/professional/cooking)
			effects = list("No cooking time and burn penalty; spoil penalty remains.", "Cooking time becomes 75%; 15% chance for level-1 positive food effect.", "Compatible ingredients can raise positive effect up to level 3 or spoil the food.", "Examine food composition, spoilage and effect strength; compatible ingredients reduce spoil chance by 30%.", "10% chance not to consume a cooking resource; positive food effect gains at least +1 level.", "Cooking time becomes 20%; successful prep has 30% chance to release level-1 effect gas.")
		if(/datum/cy_skill/professional/gardening)
			effects = list("No seed-ruin penalty.", "Plant germination speed +15%.", "Can see possible mutation paths for the examined plant.", "Watering and feeding effectiveness +25%.", "Harvesting leaf, fruit or stem has 20% chance to create an extra copy.", "Expected mutations show fruit/leaf/stem reagent contents in advance.")
		if(/datum/cy_skill/professional/music)
			effects = list("Instrument play creates weak mood effect around the performer.", "Instrument play creates strong mood effect around the performer.", "Can apply buffs to cohort members.", "Instrument can be used as a melee weapon.", "Can apply debuffs to non-cohort listeners.", "Can deal and heal damage with music.")
	if(level >= 1 && level <= length(effects))
		return effects[level]
	return null

/proc/cy_stat_linked_perk_effect(skill_type, level)
	var/list/effects
	switch(skill_type)
		if(/datum/cy_skill/strength/power_melee)
			effects = list("No -10% untrained punch-force penalty.", "+50% strength value when calculating hand/implant punch force.", "On hit or parry, deal extra equipment pressure equal to 25% strength.", "On hit, 25% chance to stagger the target.", "Hitting a staggered target has 50% chance to stun.", "Hitting a stunned target has 50% chance to uppercut and knock down.")
		if(/datum/cy_skill/strength/heavy_weapons)
			effects = list("No -30% movement speed penalty while holding weapons.", "Melee weapon and butt hits add +50% strength to force.", "20% chance to break enemy parry and deal direct damage with weapon hits.", "Firearm deviation -30%; melee weapon stamina cost -20%.", "Weapon hits, including throws, gain +20% chance for tier-2 critical wound.", "Heavy firearm movement deviation reduced to 10%; melee weapons have 10% chance to knock down.")
		if(/datum/cy_skill/strength/grappling)
			effects = list("No +25% self-fall chance on failed grab.", "Can grab with both hands for power moves.", "Two-handed grabs add +50% strength to grappling level.", "Grab use and grab strengthening cost less stamina.", "One-handed grab can pain-lock; two-handed grab can knock down and throw farther.", "One-handed grabs gain strength; body throws farther; two-handed grabbed target is staggered.")
		if(/datum/cy_skill/strength/toughness)
			effects = list("No +10% incoming damage penalty.", "Internal organ health +20%.", "Stagger duration -50%.", "Limb critical-wound thresholds +20%.", "Incoming grabs automatically lose 20% strength.", "Character takes 20% less damage.")
		if(/datum/cy_skill/dexterity/fast_melee)
			effects = list("No -10% untrained attack-speed penalty.", "+50% dexterity value when calculating hand/implant attack cooldown.", "25% chance for a free kick after a normal punch.", "25% chance to counter-kick after successful dodge or parry.", "After a successful kick, hand attack cooldown is reduced by 50%.", "Normal hits have 25% and kicks have 10% chance to briefly stun.")
		if(/datum/cy_skill/dexterity/light_weapons)
			effects = list("No -30% reload speed and +20% energy-use penalty.", "Melee/butt attack cooldown adds +50% dexterity.", "25% chance for a free repeat shot or strike.", "Hip-fire while running has no accuracy/spread penalty.", "Reload and weapon swap do not start cooldown for non-two-handed weapons.", "Can attack and shoot during other long actions.")
		if(/datum/cy_skill/dexterity/acrobatics)
			effects = list("Sprint-jump unlocked.", "Long climb and vault actions are 25% shorter.", "Jump can weaken grabs; jump/climb stamina cost -20%.", "After acrobatics, gain +15% movement speed for 30 seconds.", "+20% movement speed; sprint-jump no longer overshoots extra distance.", "Acrobatics are instant; can jump between Z-levels without fall damage.")
		if(/datum/cy_skill/dexterity/evasion)
			effects = list("No +10% balance-loss chance after successful dodge.", "Successful dodge stamina cost -20%, failed dodge cost -10%.", "Dodge success chance +15%.", "50% chance that a dodged grab makes the attacker grab themselves.", "Can dodge unseen attackers; successful dodge does not move the dodger.", "Successful dodge has 20% chance to hide you from attacker for 1 second; can dodge throws and shots.")
		if(/datum/cy_skill/perception/precise_melee)
			effects = list("No -10% untrained hit accuracy penalty.", "+50% perception value when calculating hand/implant accuracy.", "Hand hit has 30% chance to apply extra pain.", "Leg hits have 50% chance to slow; arm hits have 20% chance to disable the arm briefly.", "Head hits have 30% chance to disorient.", "Limb proc chances +10%; torso hits can immobilize.")
		if(/datum/cy_skill/perception/throwing)
			effects = list("No -50% untrained throw accuracy penalty.", "Throw accuracy +20%.", "Aimed throw bonus works +5 tiles farther.", "Aimed throw/charge time -25%.", "25% chance that thrown ammo is not spent or thrown weapon is not damaged.", "Aimed throw can be activated while moving.")
		if(/datum/cy_skill/perception/weakspot_analysis)
			effects = list("No +20% untrained critical-hit failure chance.", "10% chance that hit becomes empowered and final damage +20%.", "Unprotected-zone hits have 50% chance to become crushing and apply or upgrade tier-1 critical wound.", "Any critical wound inflicted immobilizes the target for 2 seconds.", "Empowered/crushing hits have 30% chance to ignore covering armor.", "Crushing head hit has 25% chance to paralyze for 2 seconds.")
		if(/datum/cy_skill/perception/concentration)
			effects = list("No +10% weapon loss or parry-failure chance.", "Parry success chance +15%.", "20% chance that parrying weapon is not damaged.", "Dual-weapon parry no longer has -15% penalty.", "Parrying opens enemy defense; next hit is guaranteed.", "Clinch uses both strength and perception to decide weapon throw distance.")
		if(/datum/cy_skill/intelligence/improved_code)
			effects = list("No -20% demon power penalty.", "Demon power +30%.", "Extra demon preparation adds up to +25% effectiveness after buffs.", "+20% chance to apply accompanying negative effect with a demon.", "Demon critical success chance +25%.", "Negative-effect chances and demon damage +50%.")
		if(/datum/cy_skill/intelligence/fast_code)
			effects = list("No -10% demon preparation speed penalty.", "Demon preparation speed +20%.", "Activated demon recovery time -30%.", "After successful demon use, 25% chance next demon preparation is 50% shorter.", "After failed demon use, 30% chance demon cooldown resets.", "Demon use has 25% chance to make next demon instant.")
		if(/datum/cy_skill/intelligence/hacking)
			effects = list("No +10% hacking-chain break penalty.", "Hacking-chain break chance -25%.", "Hacking timer +30%.", "Remote hacking unlocked.", "On failure, 50% chance alarm does not trigger.", "Successful hack has 10% chance to grant instant-hack charge.")
		if(/datum/cy_skill/intelligence/composure)
			effects = list("No +10% repeated negative-status chance.", "Negative status duration -20%.", "On negative status, 10% chance to gain +10% movement for 5 seconds.", "Each negative effect loses 20% of effect and becomes 5% slowdown.", "Negative effect efficiency -25%.", "Can fully block a negative effect on cooldown.")
		if(/datum/cy_skill/spirit/survival)
			effects = list("No +20% hunger/thirst/sleep rate penalty.", "Food, water and sleep effectiveness +20%.", "Sleepiness no longer slows the character.", "Hunger and thirst advance 25% slower.", "Hunger and thirst penalties work at only 50% when reducing stats.", "Health and organs regenerate by themselves.")
		if(/datum/cy_skill/spirit/endurance)
			effects = list("No -20% pain-collapse threshold penalty.", "Pain-collapse threshold +30%.", "20% chance to ignore pain from received damage.", "Stagger and disorientation duration -50%.", "Pain collapse becomes 2-second immobilize instead.", "Pain does not affect the character.")
		if(/datum/cy_skill/spirit/athletics)
			effects = list("No +10% stamina cost penalty for running or combat.", "Stamina reserve +20%.", "Carrying heavy things no longer slows movement.", "+20% sprint speed while stamina reserve is above 80%.", "Each reserve point restores 2-3 stamina if stamina is below 60%.", "Stamina regeneration delay -70%.")
		if(/datum/cy_skill/spirit/compatibility)
			effects = list("No +20% implant pain and 1% overload-per-minute penalty.", "Implant reserve before pain +30%.", "Implant overload effects -50%.", "Implant effectiveness and power +30%.", "Implant overload or reserve overflow causes slowdown instead of pain.", "Implants do not cause pain.")
		if(/datum/cy_skill/charisma/stealth)
			effects = list("No shadow-chameleon untrained penalty.", "Can move in shadow without losing 20% chameleon.", "Chameleon strengthens to 60%.", "Required light level for chameleon is reduced by 50%; stealth movement is faster.", "Stealth attacks gain x1.5 multiplier.", "Chameleon reaches 90% in shadow and 70% in light; can run in stealth.")
		if(/datum/cy_skill/charisma/theft)
			effects = list("No automatic theft message to everyone in 1 tile.", "50% chance victim misses theft message in shadow; 25% in light.", "Victim does not see theft attempt if perception is below triple theft level.", "Theft is instant.", "Theft is possible while moving.", "Can steal all equipment slots.")
		if(/datum/cy_skill/charisma/inspiration)
			effects = list("Training/music effects are no longer reduced to 50%.", "Can choose a cohort affected by effects; max 2 people.", "Effectiveness +25%; cohort size 3.", "Protection timer for cohort members +20%; cohort size 4.", "Cohort mood gains +20% of maximum from effects; cohort size 6.", "Affected characters do not lose consciousness; cohort size 8.")
		if(/datum/cy_skill/charisma/style)
			effects = list("No 10% mood-loss chance from being watched or mirrored.", "Observers gain +30% mood when looking at you.", "Can see a person's general mood.", "If someone repeats your non-combat interaction, they gain +20% mood for 2 minutes and need growth is reduced by 50%.", "Critical hits give observers mood and +25% damage if you have not damaged them in 10 minutes.", "When dealing damage, you can blind the target for 2 seconds; can see mood reasons.")
	if(level >= 1 && level <= length(effects))
		return effects[level]
	return null
