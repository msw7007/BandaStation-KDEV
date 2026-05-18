/*ALL DEFINES RELATED TO INVENTORY OBJECTS, MANAGEMENT, ETC, GO HERE*/

//ITEM INVENTORY WEIGHT, FOR w_class
/// Usually items smaller then a human hand, (e.g. playing cards, lighter, scalpel, coins/holochips)
#define WEIGHT_CLASS_TINY 1
/// Pockets can hold small and tiny items, (e.g. flashlight, multitool, grenades, GPS device)
#define WEIGHT_CLASS_SMALL 2
/// Standard backpacks can carry tiny, small & normal items, (e.g. fire extinguisher, stun baton, gas mask, metal sheets)
#define WEIGHT_CLASS_NORMAL 3
/// Items that can be wielded or equipped but not stored in an inventory, (e.g. defibrillator, backpack, space suits)
#define WEIGHT_CLASS_BULKY 4
/// Usually represents objects that require two hands to operate, (e.g. shotgun, two-handed melee weapons)
#define WEIGHT_CLASS_HUGE 5
/// Essentially means it cannot be picked up or placed in an inventory, (e.g. mech parts, safe)
#define WEIGHT_CLASS_GIGANTIC 6

/// Weight class that can fit in pockets
#define POCKET_WEIGHT_CLASS WEIGHT_CLASS_SMALL

//Inventory depth: limits how many nested storage items you can access directly.
//1: stuff in mob, 2: stuff in backpack, 3: stuff in box in backpack, etc
#define REACH_DEPTH_SELF 1
/// A storage depth ontop of SELF. REACH_DEPTH_STORAGE(1) would allow an item inside of a backpack you are carrying.
#define REACH_DEPTH_STORAGE(level) (level + REACH_DEPTH_SELF)

//ITEM INVENTORY SLOT BITMASKS
/// Suit slot (armors, costumes, space suits, etc.)
#define ITEM_SLOT_OCLOTHING (1<<0)
/// Jumpsuit slot
#define ITEM_SLOT_ICLOTHING (1<<1)
/// Glove slot
#define ITEM_SLOT_GLOVES (1<<2)
/// Glasses slot
#define ITEM_SLOT_EYES (1<<3)
/// Ear slot (radios, earmuffs)
#define ITEM_SLOT_EARS (1<<4)
/// Mask slot
#define ITEM_SLOT_MASK (1<<5)
/// Head slot (helmets, hats, etc.)
#define ITEM_SLOT_HEAD (1<<6)
/// Shoe slot
#define ITEM_SLOT_FEET (1<<7)
/// ID slot
#define ITEM_SLOT_ID (1<<8)
/// Belt slot
#define ITEM_SLOT_BELT (1<<9)
/// Back slot
#define ITEM_SLOT_BACK (1<<10)
/// Dextrous simplemob "hands" (used for Drones and Dextrous Guardians)
#define ITEM_SLOT_DEX_STORAGE (1<<11)
/// Neck slot (ties, bedsheets, scarves)
#define ITEM_SLOT_NECK (1<<12)
/// A character's hand slots
#define ITEM_SLOT_HANDS (1<<13)
/// Suit Storage slot
#define ITEM_SLOT_SUITSTORE (1<<14)
/// Left Pocket slot
#define ITEM_SLOT_LPOCKET (1<<15)
/// Right Pocket slot
#define ITEM_SLOT_RPOCKET (1<<16)
/// Handcuff slot
#define ITEM_SLOT_HANDCUFFED (1<<17)
/// Legcuff slot (bolas, beartraps)
#define ITEM_SLOT_LEGCUFFED (1<<18)

/// Total amount of slots
#define SLOTS_AMT 19 // Keep this up to date!

///Inventory slots that can be blacklisted by a species from being equipped into
DEFINE_BITFIELD(no_equip_flags, list(
	"EXOSUIT" = ITEM_SLOT_OCLOTHING,
	"JUMPSUIT" = ITEM_SLOT_ICLOTHING,
	"GLOVES" = ITEM_SLOT_GLOVES,
	"GLASSES" = ITEM_SLOT_EYES,
	"EARPIECES" = ITEM_SLOT_EARS,
	"MASKS" = ITEM_SLOT_MASK,
	"HATS" = ITEM_SLOT_HEAD,
	"SHOES" = ITEM_SLOT_FEET,
	"BACKPACKS" = ITEM_SLOT_BACK,
	"TIES" = ITEM_SLOT_NECK,
))

//SLOT GROUP HELPERS
#define ITEM_SLOT_POCKETS (ITEM_SLOT_LPOCKET|ITEM_SLOT_RPOCKET)
/// Slots that are physically on you
#define ITEM_SLOT_ON_BODY (ITEM_SLOT_ICLOTHING | ITEM_SLOT_OCLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_EYES | ITEM_SLOT_EARS | \
	ITEM_SLOT_MASK | ITEM_SLOT_HEAD | ITEM_SLOT_FEET | ITEM_SLOT_ID | ITEM_SLOT_BELT | ITEM_SLOT_BACK | ITEM_SLOT_NECK )

//Bit flags for the flags_inv variable, which determine when a piece of clothing hides another. IE a helmet hiding glasses.
//Make sure to update obscured_slots if you add more.
#define HIDEGLOVES (1<<0)
#define HIDESUITSTORAGE (1<<1)
#define HIDEJUMPSUIT (1<<2) //these first four are only used in exterior suits
#define HIDESHOES (1<<3)
#define HIDEMASK (1<<4) //these next seven are only used in masks and headgear.
#define HIDEEARS (1<<5) // (ears means headsets and such)
#define HIDEEYES (1<<6) // Whether eyes and glasses are hidden
#define HIDEFACE (1<<7) // Whether we appear as unknown.
#define HIDEHAIR (1<<8)
#define HIDEFACIALHAIR (1<<9)
#define HIDENECK (1<<10)
/// for wigs, only obscures the headgear
#define HIDEHEADGEAR (1<<11)
///for lizard snouts, because some HIDEFACE clothes don't actually conceal that portion of the head.
#define HIDESNOUT (1<<12)
///hides mutant/moth wings, does not apply to functional wings
#define HIDEMUTWINGS (1<<13)
///hides belts and riggings
#define HIDEBELT (1<<14)
///hides antennae
#define HIDEANTENNAE (1<<15)

//Bitflags for hair appendage zones
#define HAIR_APPENDAGE_FRONT (1<<0)
#define HAIR_APPENDAGE_LEFT (1<<1)
#define HAIR_APPENDAGE_RIGHT (1<<2)
#define HAIR_APPENDAGE_REAR (1<<3)
#define HAIR_APPENDAGE_TOP (1<<4)
#define HAIR_APPENDAGE_HANGING_FRONT (1<<5)
#define HAIR_APPENDAGE_HANGING_REAR (1<<6)
#define HAIR_APPENDAGE_ALL (HAIR_APPENDAGE_FRONT|HAIR_APPENDAGE_LEFT|HAIR_APPENDAGE_RIGHT|HAIR_APPENDAGE_REAR|HAIR_APPENDAGE_TOP|HAIR_APPENDAGE_HANGING_FRONT|HAIR_APPENDAGE_HANGING_REAR)

//bitflags for clothing coverage - also used for limbs
#define CHEST (1<<0)
#define GROIN (1<<1)
#define HEAD (1<<2)
#define LEG_LEFT (1<<3)
#define LEG_RIGHT (1<<4)
#define LEGS (LEG_LEFT | LEG_RIGHT)
#define FOOT_LEFT (1<<5)
#define FOOT_RIGHT (1<<6)
#define FEET (FOOT_LEFT | FOOT_RIGHT)
#define ARM_LEFT (1<<7)
#define ARM_RIGHT (1<<8)
#define ARMS (ARM_LEFT | ARM_RIGHT)
#define HAND_LEFT (1<<9)
#define HAND_RIGHT (1<<10)
#define HANDS (HAND_LEFT | HAND_RIGHT)
#define NECK (1<<11)
#define FULL_BODY ALL

//defines for the index of hands
#define LEFT_HANDS 1
#define RIGHT_HANDS 2
/// Checks if the value is "right" - same as ISEVEN, but used primarily for hand or foot index contexts
#define IS_RIGHT_INDEX(value) (value % 2 == 0)
/// Checks if the value is "left" - same as ISODD, but used primarily for hand or foot index contexts
#define IS_LEFT_INDEX(value) (value % 2 != 0)

//flags for female outfits: How much the game can safely "take off" the uniform without it looking weird
/// For when there's simply no need for a female version of this uniform.
#define NO_FEMALE_UNIFORM 0
/// For the game to take off everything, disregards other flags.
#define FEMALE_UNIFORM_FULL (1<<0)
/// For when you really need to avoid the game cutting off that one pixel between the legs, to avoid the comeback of the infamous "dixel".
#define FEMALE_UNIFORM_TOP_ONLY (1<<1)
/// For when you don't want the "breast" effect to be applied (the one that cuts two pixels in the middle of the front of the uniform when facing east or west).
#define FEMALE_UNIFORM_NO_BREASTS (1<<2)

// BANDASTATION EDIT START - more masks for female clothing
/// Tgstation stores its masks there
#define FEMALE_MASK_ICON_DEFAULT 'icons/mob/clothing/under/masking_helpers.dmi'
/// Bandastation stores its masks there
#define FEMALE_MASK_ICON_MODULAR 'modular_bandastation/mobs/icons/clothing/masking_helpers.dmi'

// Icon states stored in FEMALE_MASK_ICON_MODULAR
#define FEMALE_MASK_TURTLENECK "female_turtleneck"
#define FEMALE_MASK_RUS_ARMY "female_rus_army"

// Flags for /datum/female_uniform::mask_flags

/// This mask is always applied when suit is adjusted
#define FEMALE_MASK_APPLY_ON_ADJUSTED (1<<0)
// BANDASTATION EDIT END

//flags for alternate styles: These are hard sprited so don't set this if you didn't put the effort in
#define NORMAL_STYLE 0
#define ALT_STYLE 1
#define DIGITIGRADE_STYLE 2

//Flags (actual flags, fucker ^) for /obj/item/var/supports_variations_flags
/// Has a sprite for digitigrade legs specifically.
#define CLOTHING_DIGITIGRADE_VARIATION (1<<0)
/// The sprite works fine for digitigrade legs as-is.
#define CLOTHING_DIGITIGRADE_VARIATION_NO_NEW_ICON (1<<1)
/// Auto-generates the leg portion of the sprite with GAGS
#define CLOTHING_DIGITIGRADE_MASK (1<<2)

/// All variation flags which render "correctly" on a digitigrade leg setup
#define DIGITIGRADE_VARIATIONS (CLOTHING_DIGITIGRADE_VARIATION|CLOTHING_DIGITIGRADE_VARIATION_NO_NEW_ICON|CLOTHING_DIGITIGRADE_MASK)

//flags for covering body parts
#define GLASSESCOVERSEYES (1<<0)
#define MASKCOVERSEYES (1<<1) // get rid of some of the other stupidness in these flags
#define HEADCOVERSEYES (1<<2) // feel free to realloc these numbers for other purposes
#define MASKCOVERSMOUTH (1<<3) // on other items, these are just for mask/head
#define HEADCOVERSMOUTH (1<<4)
#define PEPPERPROOF (1<<5) //protects against pepperspray
#define EARS_COVERED (1<<6)
#define ALLOW_SURGERY_THROUGH (1<<7) //item will not obstruct body part access, such as for surgery, despite covering the body part

#define TINT_MILD 1.5 //Threshold of tint level to apply mild tint overlay
#define TINT_DARKENED 2 //Threshold of tint level to apply weld mask overlay
#define TINT_BLIND 3 //Threshold of tint level to obscure vision fully

// defines for AFK theft
/// How many messages you can remember while logged out before you stop remembering new ones
#define AFK_THEFT_MAX_MESSAGES 10
/// If someone logs back in and there are entries older than this, just tell them they can't remember who it was or when
#define AFK_THEFT_FORGET_DETAILS_TIME (5 MINUTES)
/// The index of the entry in 'afk_thefts' with the person's visible name at the time
#define AFK_THEFT_NAME 1
/// The index of the entry in 'afk_thefts' with the text
#define AFK_THEFT_MESSAGE 2
/// The index of the entry in 'afk_thefts' with the time it happened
#define AFK_THEFT_TIME 3

/// A list of things that any suit storage can hold
/// Should consist of ubiquitous, non-specialized items
/// or items that are meant to be "suit storage agnostic" as
/// a benefit, which of the time of this commit only applies
/// to the captain's jetpack, here
GLOBAL_LIST_INIT(any_suit_storage, typecacheof(list(
	/obj/item/clipboard,
	/obj/item/flashlight,
	/obj/item/tank/internals/emergency_oxygen,
	/obj/item/tank/internals/plasmaman,
	/obj/item/lighter,
	/obj/item/pen,
	/obj/item/modular_computer/pda,
	/obj/item/toy/plush,
	/obj/item/radio,
	/obj/item/storage/bag/books,
	/obj/item/storage/fancy/cigarettes,
	/obj/item/tank/jetpack/captain,
	/obj/item/stack/spacecash,
	/obj/item/storage/wallet,
	/obj/item/folder,
	/obj/item/storage/box/matches,
	/obj/item/cigarette,
	/obj/item/gun/energy/laser/bluetag,
	/obj/item/gun/energy/laser/redtag,
	/obj/item/storage/belt/holster,
	/obj/item/storage/belt/sheath
)))

//Allowed equipment lists for security vests.

GLOBAL_LIST_INIT(detective_vest_allowed, list(
	/obj/item/detective_scanner,
	/obj/item/flashlight,
	/obj/item/gun/ballistic,
	/obj/item/gun/energy,
	/obj/item/lighter,
	/obj/item/melee/baton,
	/obj/item/reagent_containers/spray/pepper,
	/obj/item/restraints/handcuffs,
	/obj/item/storage/fancy/cigarettes,
	/obj/item/taperecorder,
	/obj/item/tank/internals/emergency_oxygen,
	/obj/item/tank/internals/plasmaman,
	/obj/item/storage/belt/holster/detective,
	/obj/item/storage/belt/holster/nukie,
	/obj/item/storage/belt/holster/energy,
	/obj/item/gun/ballistic/shotgun/automatic/combat/compact,
))

GLOBAL_LIST_INIT(security_vest_allowed, list(
	/obj/item/flashlight,
	/obj/item/gun/ballistic,
	/obj/item/gun/energy,
	/obj/item/knife/combat,
	/obj/item/melee/baton,
	/obj/item/reagent_containers/spray/pepper,
	/obj/item/restraints/handcuffs,
	/obj/item/tank/internals/emergency_oxygen,
	/obj/item/tank/internals/plasmaman,
	/obj/item/storage/belt/holster/detective,
	/obj/item/storage/belt/holster/nukie,
	/obj/item/storage/belt/holster/energy,
	/obj/item/gun/ballistic/shotgun/automatic/combat/compact,
	/obj/item/pen/red/security,
))

GLOBAL_LIST_INIT(security_wintercoat_allowed, list(
	/obj/item/gun/ballistic,
	/obj/item/gun/energy,
	/obj/item/melee/baton,
	/obj/item/reagent_containers/spray/pepper,
	/obj/item/restraints/handcuffs,
	/obj/item/storage/belt/holster/detective,
	/obj/item/storage/belt/holster/nukie,
	/obj/item/storage/belt/holster/energy,
	/obj/item/gun/ballistic/shotgun/automatic/combat/compact,
))

//Allowed list for all chaplain suits (except the honkmother robe)

GLOBAL_LIST_INIT(chaplain_suit_allowed, list(
	/obj/item/book/bible,
	/obj/item/nullrod,
	/obj/item/reagent_containers/cup/glass/bottle/holywater,
	/obj/item/storage/fancy/candle_box,
	/obj/item/flashlight/flare/candle,
	/obj/item/tank/internals/emergency_oxygen,
	/obj/item/tank/internals/plasmaman,
	/obj/item/gun/ballistic/bow/divine,
	/obj/item/gun/ballistic/revolver/chaplain,
	/obj/item/toy/plush/carpplushie/nullrod,
	/obj/item/melee/energy/sword/nullrod,
))

//Allowed list for all mining suits

GLOBAL_LIST_INIT(mining_suit_allowed, list(
	/obj/item/t_scanner/adv_mining_scanner,
	/obj/item/melee/cleaving_saw,
	/obj/item/climbing_hook,
	/obj/item/flashlight,
	/obj/item/grapple_gun,
	/obj/item/tank/internals,
	/obj/item/gun/energy/recharge/kinetic_accelerator,
	/obj/item/kinetic_crusher,
	/obj/item/knife,
	/obj/item/mining_scanner,
	/obj/item/organ/monster_core,
	/obj/item/storage/bag/ore,
	/obj/item/pickaxe,
	/obj/item/resonator,
	/obj/item/spear,
	/obj/item/gun/ballistic/bow/ashenbow,
))

// Allowed list for personal carry firearms and holsters

GLOBAL_LIST_INIT(personal_carry_allowed, list(
	/obj/item/storage/belt/holster,
	/obj/item/gun/ballistic/automatic/pistol,
	/obj/item/gun/ballistic/revolver,
	/obj/item/gun/energy/disabler/smoothbore,
))

/// Allowed list for improvised firearms

GLOBAL_LIST_INIT(improvised_firearm_allowed, list(
	/obj/item/gun/ballistic/rifle/boltaction/pipegun,
	/obj/item/gun/energy/laser/musket,
	/obj/item/gun/energy/disabler/smoothbore,
))

/// List of all "tools" that can fit into belts or work from toolboxes

GLOBAL_LIST_INIT(tool_items, list(
	/obj/item/airlock_painter,
	/obj/item/analyzer,
	/obj/item/assembly/signaler,
	/obj/item/construction/rcd,
	/obj/item/construction/rld,
	/obj/item/construction/rtd,
	/obj/item/crowbar,
	/obj/item/extinguisher/mini,
	/obj/item/flashlight,
	/obj/item/forcefield_projector,
	/obj/item/geiger_counter,
	/obj/item/holosign_creator/atmos,
	/obj/item/holosign_creator/engineering,
	/obj/item/inducer,
	/obj/item/lightreplacer,
	/obj/item/multitool,
	/obj/item/pipe_dispenser,
	/obj/item/pipe_painter,
	/obj/item/plunger,
	/obj/item/radio,
	/obj/item/screwdriver,
	/obj/item/stack/cable_coil,
	/obj/item/t_scanner,
	/obj/item/weldingtool,
	/obj/item/wirecutters,
	/obj/item/wrench,
	/obj/item/spess_knife,
))

// Keys for equip_in_one_of_slots, if you add new ones update the assoc lists in equip_in_one_of_slots
/// Items placed into the left pocket.
#define LOCATION_LPOCKET "в левом кармане"
/// Items placed into the right pocket
#define LOCATION_RPOCKET "в правом кармане"
/// Items placed into the backpack.
#define LOCATION_BACKPACK "в сумке"
/// Items placed into the hands.
#define LOCATION_HANDS "в руках"
/// Items placed in the glove slot.
#define LOCATION_GLOVES "на руках"
/// Items placed in the eye/glasses slot.
#define LOCATION_EYES "на глазах"
/// Items placed in the mask slot.
#define LOCATION_MASK "на лице"
/// Items placed on the head/hat slot.
#define LOCATION_HEAD "на голове"
/// Items placed in the neck slot.
#define LOCATION_NECK "на шее"
/// Items placed in the id slot
#define LOCATION_ID "в кармашке ID карты"

// CyberPunk item core categories. These map directly onto existing w_class values.
#define CY_ITEM_KIND_PREFAB "prefab"
#define CY_ITEM_KIND_MODULAR "modular"

// CyberPunk quality core used by food, botany, resources and crafted components.
#define CY_QUALITY_DISGUSTING 1
#define CY_QUALITY_BAD 2
#define CY_QUALITY_AVERAGE 3
#define CY_QUALITY_GOOD 4
#define CY_QUALITY_EXCELLENT 5

#define CY_CROP_PLANT "plant"
#define CY_CROP_TREE "tree"
#define CY_CROP_UNDERGROUND "underground"

#define CY_FLAVOR_SWEET "sweet"
#define CY_FLAVOR_SALTY "salty"
#define CY_FLAVOR_SOUR "sour"
#define CY_FLAVOR_BITTER "bitter"
#define CY_FLAVOR_UMAMI "umami"
#define CY_FLAVOR_SPICY "spicy"
#define CY_FLAVOR_FATTY "fatty"
#define CY_FLAVOR_FRESH "fresh"

#define CY_FOOD_ROOM_QUALITY_DECAY_TIME (10 MINUTES)
#define CY_FOOD_REFRIGERATED_QUALITY_DECAY_TIME (60 MINUTES)
#define CY_RESOURCE_MIN_UNITS 0.5
#define CY_RESOURCE_MAX_UNITS 1.5
#define CY_SEED_MAX_EFFECT_POINTS 10
#define CY_SEED_DANGEROUS_MUTATION_THRESHOLD 80

#define CY_ITEM_FUNCTION_ACTIVE "active"
#define CY_ITEM_FUNCTION_PROTECTIVE "protective"

#define CY_ITEM_MARKET_CIVILIAN "civilian"
#define CY_ITEM_MARKET_CONTROLLED "controlled"
#define CY_ITEM_MARKET_BLACK "black_market"

#define CY_ITEM_STYLE_TAG_NEUTRAL "neutral"
#define CY_ITEM_STYLE_TAG_CORPORATE "corporate"
#define CY_ITEM_STYLE_TAG_STREET "street"
#define CY_ITEM_STYLE_TAG_COMBAT "combat"
#define CY_ITEM_STYLE_TAG_LUXURY "luxury"

#define CY_ITEM_SIZE_TINY WEIGHT_CLASS_TINY
#define CY_ITEM_SIZE_SMALL WEIGHT_CLASS_SMALL
#define CY_ITEM_SIZE_MEDIUM WEIGHT_CLASS_NORMAL
#define CY_ITEM_SIZE_LARGE WEIGHT_CLASS_BULKY
#define CY_ITEM_SIZE_HUGE WEIGHT_CLASS_HUGE
#define CY_ITEM_SIZE_GIGANTIC WEIGHT_CLASS_GIGANTIC

#define CY_ITEM_INTENT_SLASH "slash"
#define CY_ITEM_INTENT_CHOP "chop"
#define CY_ITEM_INTENT_STAB "stab"
#define CY_ITEM_INTENT_PIERCE "pierce"
#define CY_ITEM_ATTACK_INTENTS list(CY_ITEM_INTENT_SLASH, CY_ITEM_INTENT_CHOP, CY_ITEM_INTENT_STAB, CY_ITEM_INTENT_PIERCE)

#define CY_MODULE_SLOT_MELEE_HANDLE "melee_handle"
#define CY_MODULE_SLOT_RANGED_HANDLE "ranged_handle"
#define CY_MODULE_SLOT_CLASSIC_CORE "classic_core"
#define CY_MODULE_SLOT_ENERGY_CONVERTER "energy_converter"
#define CY_MODULE_SLOT_ATTACKING_ELEMENT "attacking_element"
#define CY_MODULE_SLOT_ATTACKING_COATING "attacking_coating"
#define CY_MODULE_SLOT_BALANCER "balancer"
#define CY_MODULE_SLOT_GUARD "guard"
#define CY_MODULE_SLOT_BARREL "barrel"
#define CY_MODULE_SLOT_TRIGGER "trigger"
#define CY_MODULE_SLOT_MATRIX "matrix"
#define CY_MODULE_SLOT_MAGAZINE "magazine"
#define CY_MODULE_SLOT_RECEIVER "receiver"
#define CY_MODULE_SLOT_EXTRA "extra"

#define CY_MODULE_SLOT_EQUIPMENT_BASE "equipment_base"
#define CY_MODULE_SLOT_EQUIPMENT_MATERIAL "equipment_material"
#define CY_MODULE_SLOT_EQUIPMENT_PLATE "equipment_plate"
#define CY_MODULE_SLOT_EQUIPMENT_LINING "equipment_lining"
#define CY_MODULE_SLOT_EQUIPMENT_ACTIVE "equipment_active"
#define CY_MODULE_SLOT_RIG_CONNECTOR "rig_connector"

#define CY_STRUCTURE_MOBILITY_MOBILE "mobile"
#define CY_STRUCTURE_MOBILITY_FOLDABLE "foldable"
#define CY_STRUCTURE_MOBILITY_FIXED "fixed"

#define CY_CONSTRUCTION_STAGE_NONE 0
#define CY_CONSTRUCTION_STAGE_FRAME_WRENCHED 1
#define CY_CONSTRUCTION_STAGE_FRAME_WELDED 2
#define CY_CONSTRUCTION_STAGE_COMPONENTS_LOADED 3
#define CY_CONSTRUCTION_STAGE_COMPLETE 4

#define CY_MACHINE_STATE_WORKING "working"
#define CY_MACHINE_STATE_DEGRADED "degraded"
#define CY_MACHINE_STATE_BROKEN "broken"
#define CY_MACHINE_STATE_HACKED "hacked"
#define CY_MACHINE_STATE_DISABLED "disabled"
#define CY_MACHINE_STATE_EMPED "emped"
