
// Skill levels
#define SKILL_LEVEL_NONE 1
#define SKILL_LEVEL_NOVICE 2
#define SKILL_LEVEL_APPRENTICE 3
#define SKILL_LEVEL_JOURNEYMAN 4
#define SKILL_LEVEL_EXPERT 5
#define SKILL_LEVEL_MASTER 6
#define SKILL_LEVEL_LEGENDARY 7

#define SKILL_LVL 1
#define SKILL_EXP 2

// Level experience requirements
#define SKILL_EXP_NONE 0
#define SKILL_EXP_NOVICE 100
#define SKILL_EXP_APPRENTICE 250
#define SKILL_EXP_JOURNEYMAN 500
#define SKILL_EXP_EXPERT 900
#define SKILL_EXP_MASTER 1500
#define SKILL_EXP_LEGENDARY 2500

//Allows us to get EXP from level, or level from EXP
#define SKILL_EXP_LIST list(SKILL_EXP_NONE, SKILL_EXP_NOVICE, SKILL_EXP_APPRENTICE, SKILL_EXP_JOURNEYMAN, SKILL_EXP_EXPERT, SKILL_EXP_MASTER, SKILL_EXP_LEGENDARY)

//Skill modifier types
///ideally added/subtracted in speed calculations to make you do stuff faster
#define SKILL_SPEED_MODIFIER "skill_speed_modifier"
///ideally added/subtracted where beneficial in prob(x) calls
#define SKILL_PROBS_MODIFIER "skill_probability_modifier"
///ideally added/subtracted where beneficial in rand(x,y) calls
#define SKILL_RANDS_MODIFIER "skill_randomness_modifier"
///ideally for addittive operations
#define SKILL_VALUE_MODIFIER "skill_value_modifier"

// Gets the reference for the skill type that was given
#define GetSkillRef(A) (SSskills.all_skills[A])

//number defines
#define CLEAN_SKILL_BEAUTY_ADJUSTMENT -15//It's a denominator so no 0. Higher number = less cleaning xp per cleanable. Negative value means cleanables with negative beauty give xp.
#define CLEAN_SKILL_GENERIC_WASH_XP 1.5//Value. Higher number = more XP when cleaning non-cleanables (walls/floors/lips)
///The multiplier of the extra experience given by the fishing minigame based on difficulty. At the default difficulty of 15, the bonus will be of 21%.
#define FISHING_SKILL_DIFFIULTY_EXP_MULT 0.015
///How much exp one would gain per spent playing the fishing minigame at minimum difficulty. the time is multiplied by 0.1 because deciseconds...
#define FISHING_SKILL_EXP_PER_SECOND (SKILL_EXP_LEGENDARY / (15 MINUTES * 0.1))

///The base modifier a boulder's size grants to the mining skill.
#define MINING_SKILL_BOULDER_SIZE_XP 10

///The base modifier for how much experience is earned from misc athletics interactions
#define ATHLETICS_SKILL_MISC_EXP 5

// Skillchip categories
//Various skillchip categories. Use these when setting which categories a skillchip restricts being paired with
//while using the SKILLCHIP_RESTRICTED_CATEGORIES flag
#define SKILLCHIP_CATEGORY_GENERAL "general"
#define SKILLCHIP_CATEGORY_JOB "job"

// Cyberpunk character skill model.
#define CHARACTER_SKILL_LEVEL_NONE 0
#define CHARACTER_SKILL_LEVEL_NOVICE 1
#define CHARACTER_SKILL_LEVEL_SKILLED 2
#define CHARACTER_SKILL_LEVEL_TRAINED 3
#define CHARACTER_SKILL_LEVEL_EXPERT 4
#define CHARACTER_SKILL_LEVEL_PROFESSIONAL 5
#define CHARACTER_SKILL_LEVEL_MASTER 6

#define CHARACTER_SKILL_CHECK_MINIMUM 1
#define CHARACTER_SKILL_CHECK_MAXIMUM 99

#define CHARACTER_SKILL_KIND_LEGACY "legacy"
#define CHARACTER_SKILL_KIND_PHYSICAL "physical"
#define CHARACTER_SKILL_KIND_PROFESSIONAL "professional"
#define CHARACTER_SKILL_KIND_WEAPON "weapon"

#define CHARACTER_SKILL_POOL_NONE "none"
#define CHARACTER_SKILL_POOL_ATTRIBUTE "attribute"
#define CHARACTER_SKILL_POOL_SKILL "skill"

#define PHYSICAL_SKILL_MAX_LEVEL 6
#define PHYSICAL_PERK_MAX_RANK 3
#define PROFESSIONAL_SKILL_MAX_LEVEL 5
#define PROFESSIONAL_PERK_MAX_RANK 4
#define WEAPON_SKILL_MAX_LEVEL 5
#define PROFESSIONAL_SKILL_POINTS_DEFAULT 6
#define WEAPON_SKILL_POINTS_DEFAULT 8

#define CHARACTER_PHYSICAL_PERK_POWER_MULTIPLIERS list(1, 1.5, 2)
#define CHARACTER_PROFESSIONAL_PERK_POWER_MULTIPLIERS list(1, 2, 3, 4)

#define CHARACTER_SKILL_LEVEL_NAMES list("None", "Beginner", "Skilled", "Trained", "Expert", "Professional", "Master")

// Physical skills.
#define SKILL_POWER_UNARMED /datum/skill/physical/strength/power_unarmed
#define SKILL_HEAVY_WEAPON /datum/skill/physical/strength/heavy_weapon
#define SKILL_GRAPPLING /datum/skill/physical/strength/grappling
#define SKILL_FORTITUDE /datum/skill/physical/strength/fortitude
#define SKILL_FAST_UNARMED /datum/skill/physical/dexterity/fast_unarmed
#define SKILL_LIGHT_WEAPON /datum/skill/physical/dexterity/light_weapon
#define SKILL_ACROBATICS /datum/skill/physical/dexterity/acrobatics
#define SKILL_EVASION /datum/skill/physical/dexterity/evasion
#define SKILL_PRECISE_UNARMED /datum/skill/physical/perception/precise_unarmed
#define SKILL_PRECISE_WEAPON /datum/skill/physical/perception/precise_weapon
#define SKILL_WEAKNESS_ANALYSIS /datum/skill/physical/perception/weakness_analysis
#define SKILL_CONCENTRATION /datum/skill/physical/perception/concentration
#define SKILL_ENHANCED_CODE /datum/skill/physical/intelligence/enhanced_code
#define SKILL_FAST_CODE /datum/skill/physical/intelligence/fast_code
#define SKILL_HACKING /datum/skill/physical/intelligence/hacking
#define SKILL_NEUTRALIZATION /datum/skill/physical/intelligence/neutralization
#define SKILL_SURVIVAL /datum/skill/physical/spirit/survival
#define SKILL_ENDURANCE /datum/skill/physical/spirit/endurance
#define SKILL_ATHLETICS /datum/skill/physical/spirit/athletics
#define SKILL_COMPATIBILITY /datum/skill/physical/spirit/compatibility
#define SKILL_STEALTH /datum/skill/physical/charisma/stealth
#define SKILL_THEFT /datum/skill/physical/charisma/theft
#define SKILL_INSPIRATION /datum/skill/physical/charisma/inspiration
#define SKILL_STYLE /datum/skill/physical/charisma/style

// Professional skills.
#define SKILL_SURGERY /datum/skill/professional/surgery
#define SKILL_CHEMISTRY /datum/skill/professional/chemistry
#define SKILL_ELECTRICS /datum/skill/professional/electrics
#define SKILL_CONSTRUCTION /datum/skill/professional/construction
#define SKILL_INVENTION /datum/skill/professional/invention
#define SKILL_ANALYSIS /datum/skill/professional/analysis
#define SKILL_MINING /datum/skill/professional/mining
#define SKILL_DRIVING /datum/skill/professional/driving
#define SKILL_COOKING /datum/skill/professional/cooking
#define SKILL_GARDENING /datum/skill/professional/gardening
#define SKILL_MUSIC /datum/skill/professional/music

// Weapon skills.
#define SKILL_DAGGERS /datum/skill/weapon/daggers
#define SKILL_LIGHT_SLASHING /datum/skill/weapon/light_slashing
#define SKILL_LIGHT_BLUNT /datum/skill/weapon/light_blunt
#define SKILL_POLEARMS /datum/skill/weapon/polearms
#define SKILL_LIGHT_RANGED /datum/skill/weapon/light_ranged
#define SKILL_HEAVY_SLASHING /datum/skill/weapon/heavy_slashing
#define SKILL_HEAVY_BLUNT /datum/skill/weapon/heavy_blunt
#define SKILL_CHOPPING /datum/skill/weapon/chopping
#define SKILL_HEAVY_RANGED /datum/skill/weapon/heavy_ranged
#define SKILL_MEDIUM_RANGED /datum/skill/weapon/medium_ranged
#define SKILL_LIGHT_PIERCING /datum/skill/weapon/light_piercing
#define SKILL_HEAVY_PIERCING /datum/skill/weapon/heavy_piercing
#define SKILL_PRECISE_RANGED /datum/skill/weapon/precise_ranged
