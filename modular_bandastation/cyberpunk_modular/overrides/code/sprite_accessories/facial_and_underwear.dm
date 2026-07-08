// Split from the old core code/datums/sprite_accessories.dm monolith for modular conflict isolation.
/////////////////////////////
// Facial Hair Definitions //
/////////////////////////////

/datum/sprite_accessory/facial_hair
	icon = 'icons/mob/human/human_face.dmi'
	gender = MALE // barf (unless you're a dorf, dorfs dig chix w/ beards :P)
	em_block = TRUE

// please make sure they're sorted alphabetically and categorized

/datum/sprite_accessory/facial_hair/abe
	name = "Beard (Abraham Lincoln)"
	icon_state = "facial_abe"

/datum/sprite_accessory/facial_hair/brokenman
	name = "Beard (Broken Man)"
	icon_state = "facial_brokenman"
	natural_spawn = FALSE

/datum/sprite_accessory/facial_hair/chinstrap
	name = "Beard (Chinstrap)"
	icon_state = "facial_chin"

/datum/sprite_accessory/facial_hair/dwarf
	name = "Beard (Dwarf)"
	icon_state = "facial_dwarf"

/datum/sprite_accessory/facial_hair/fullbeard
	name = "Beard (Full)"
	icon_state = "facial_fullbeard"

/datum/sprite_accessory/facial_hair/croppedfullbeard
	name = "Beard (Cropped Fullbeard)"
	icon_state = "facial_croppedfullbeard"

/datum/sprite_accessory/facial_hair/gt
	name = "Beard (Goatee)"
	icon_state = "facial_gt"

/datum/sprite_accessory/facial_hair/hip
	name = "Beard (Hipster)"
	icon_state = "facial_hip"

/datum/sprite_accessory/facial_hair/jensen
	name = "Beard (Jensen)"
	icon_state = "facial_jensen"

/datum/sprite_accessory/facial_hair/neckbeard
	name = "Beard (Neckbeard)"
	icon_state = "facial_neckbeard"

/datum/sprite_accessory/facial_hair/vlongbeard
	name = "Beard (Very Long)"
	icon_state = "facial_wise"

/datum/sprite_accessory/facial_hair/muttonmus
	name = "Beard (Muttonmus)"
	icon_state = "facial_muttonmus"

/datum/sprite_accessory/facial_hair/martialartist
	name = "Beard (Martial Artist)"
	icon_state = "facial_martialartist"
	natural_spawn = FALSE

/datum/sprite_accessory/facial_hair/chinlessbeard
	name = "Beard (Chinless Beard)"
	icon_state = "facial_chinlessbeard"

/datum/sprite_accessory/facial_hair/moonshiner
	name = "Beard (Moonshiner)"
	icon_state = "facial_moonshiner"

/datum/sprite_accessory/facial_hair/longbeard
	name = "Beard (Long)"
	icon_state = "facial_longbeard"

/datum/sprite_accessory/facial_hair/volaju
	name = "Beard (Volaju)"
	icon_state = "facial_volaju"

/datum/sprite_accessory/facial_hair/threeoclock
	name = "Beard (Three o Clock Shadow)"
	icon_state = "facial_3oclock"

/datum/sprite_accessory/facial_hair/fiveoclock
	name = "Beard (Five o Clock Shadow)"
	icon_state = "facial_fiveoclock"

/datum/sprite_accessory/facial_hair/fiveoclockm
	name = "Beard (Five o Clock Moustache)"
	icon_state = "facial_5oclockmoustache"

/datum/sprite_accessory/facial_hair/sevenoclock
	name = "Beard (Seven o Clock Shadow)"
	icon_state = "facial_7oclock"

/datum/sprite_accessory/facial_hair/sevenoclockm
	name = "Beard (Seven o Clock Moustache)"
	icon_state = "facial_7oclockmoustache"

/datum/sprite_accessory/facial_hair/moustache
	name = "Moustache"
	icon_state = "facial_moustache"

/datum/sprite_accessory/facial_hair/pencilstache
	name = "Moustache (Pencilstache)"
	icon_state = "facial_pencilstache"

/datum/sprite_accessory/facial_hair/smallstache
	name = "Moustache (Smallstache)"
	icon_state = "facial_smallstache"

/datum/sprite_accessory/facial_hair/walrus
	name = "Moustache (Walrus)"
	icon_state = "facial_walrus"

/datum/sprite_accessory/facial_hair/fu
	name = "Moustache (Fu Manchu)"
	icon_state = "facial_fumanchu"

/datum/sprite_accessory/facial_hair/hogan
	name = "Moustache (Hulk Hogan)"
	icon_state = "facial_hogan" //-Neek

/datum/sprite_accessory/facial_hair/selleck
	name = "Moustache (Selleck)"
	icon_state = "facial_selleck"

/datum/sprite_accessory/facial_hair/chaplin
	name = "Moustache (Square)"
	icon_state = "facial_chaplin"

/datum/sprite_accessory/facial_hair/vandyke
	name = "Moustache (Van Dyke)"
	icon_state = "facial_vandyke"

/datum/sprite_accessory/facial_hair/watson
	name = "Moustache (Watson)"
	icon_state = "facial_watson"

/datum/sprite_accessory/facial_hair/handlebar
	name = "Moustache (Handlebar)"
	icon_state = "facial_handlebar"

/datum/sprite_accessory/facial_hair/handlebar2
	name = "Moustache (Handlebar 2)"
	icon_state = "facial_handlebar2"

/datum/sprite_accessory/facial_hair/elvis
	name = "Sideburns (Elvis)"
	icon_state = "facial_elvis"

/datum/sprite_accessory/facial_hair/mutton
	name = "Sideburns (Mutton Chops)"
	icon_state = "facial_mutton"

/datum/sprite_accessory/facial_hair/sideburn
	name = "Sideburns"
	icon_state = "facial_sideburn"

/datum/sprite_accessory/facial_hair/shaved
	name = "Shaved"
	icon_state = SPRITE_ACCESSORY_NONE
	gender = NEUTER

/datum/sprite_accessory/clothing
	abstract_type = /datum/sprite_accessory/clothing
	/// Allows you to specify a greyscale config
	var/greyscale_config
	/// Icon state in the digitigrade template file to use if the wearer is digitigrade.
	/// If null, no special digitigrade handling is done.
	var/digi_icon_state
	/// Color pallete for static colored underwear, like hearts.
	/// Used so greyscale copies can have the same palette.
	var/greyscale_colors = "#FFFFFF#FFFFFF#FFFFFF"
	/// The layer this sprite accessory should render on
	var/layer = BODY_LAYER
	/// What kind of gender shaping this sprite accessory should use (in case your sprite gets a weird missing pixel in the center)
	var/female_sprite_flags = FEMALE_UNIFORM_FULL

/// Override to return a different icon state given a bodytype or physique
/datum/sprite_accessory/clothing/proc/get_icon_state(physique, bodyshape)
	return icon_state

/**
 * Generate an appearance from this clothing datum
 *
 * * color - if this is NOT a statically colored clothing article and NOT gags, uses this color.
 * * physique - physique of the wearer (male or female)
 * * bodyshape - bodyshape of the wearer (humanoid, digitigrade, etc)
 */
/datum/sprite_accessory/clothing/proc/make_appearance(color = COLOR_WHITE, physique = MALE, bodyshape = BODYSHAPE_HUMANOID)
	var/static/list/cached_icons = list()
	var/use_female = physique == FEMALE && female_sprite_flags
	var/use_digi = digi_icon_state && (bodyshape & BODYSHAPE_DIGITIGRADE)
	var/female_sprite_flags_to_use = female_sprite_flags
	var/icon_state_to_use = get_icon_state(physique, bodyshape)
	if(use_digi && female_sprite_flags_to_use)
		female_sprite_flags_to_use = FEMALE_UNIFORM_TOP_ONLY // No bottom gender shaping for the digi legs

	var/key = "[icon_state_to_use]-[greyscale_config || "ng"]-[use_female]-[use_digi]-[greyscale_colors]"
	var/mutable_appearance/result
	if(cached_icons[key]) // it's already cached
		result = mutable_appearance(icon(cached_icons[key]))

	else if(greyscale_config || use_female || use_digi) // icon ops ahead
		var/icon/created = icon(greyscale_config ? SSgreyscale.GetColoredIconByType(greyscale_config, greyscale_colors) : icon, icon_state_to_use)
		if(use_female)
			created = wear_female_version(icon_state_to_use, icon, female_sprite_flags_to_use)
		if(use_digi)
			var/icon/replacement = icon(SSgreyscale.GetColoredIconByType(/datum/greyscale_config/digitigrade_underwear, greyscale_colors), digi_icon_state)
			created = replace_icon_legs(created, replacement)

		cached_icons[key] = fcopy_rsc(created)
		result = mutable_appearance(created)

	else // no caching necessary
		result = mutable_appearance(icon, icon_state)

	result.layer = -layer
	result.color = use_static ? null : color

	return result


///////////////////////////
// Underwear Definitions //
///////////////////////////

/datum/sprite_accessory/clothing/underwear
	icon = 'icons/mob/clothing/underwear.dmi'
	use_static = FALSE
	em_block = TRUE
	abstract_type = /datum/sprite_accessory/clothing/underwear

//MALE UNDERWEAR
/datum/sprite_accessory/clothing/underwear/nude
	name = "Nude"
	icon_state = null
	gender = NEUTER

/datum/sprite_accessory/clothing/underwear/nude/make_appearance(mob/living/carbon/human/for_who)
	return

/datum/sprite_accessory/clothing/underwear/male_briefs
	name = "Briefs"
	icon_state = "male_briefs"
	gender = MALE

/datum/sprite_accessory/clothing/underwear/male_boxers
	name = "Boxers"
	icon_state = "male_boxers"
	gender = MALE
	digi_icon_state = "boxers"

/datum/sprite_accessory/clothing/underwear/male_stripe
	name = "Striped Boxers"
	icon_state = "male_stripe"
	gender = MALE
	digi_icon_state = "boxers_stripe"

/datum/sprite_accessory/clothing/underwear/male_midway
	name = "Midway Boxers"
	icon_state = "male_midway"
	gender = MALE
	digi_icon_state = "midway"

/datum/sprite_accessory/clothing/underwear/male_longjohns
	name = "Long Johns"
	icon_state = "male_longjohns"
	gender = MALE
	digi_icon_state = "longjohns"

/datum/sprite_accessory/clothing/underwear/male_kinky
	name = "Jockstrap"
	icon_state = "male_kinky"
	gender = MALE

/datum/sprite_accessory/clothing/underwear/male_mankini
	name = "Mankini"
	icon_state = "male_mankini"
	gender = MALE

/datum/sprite_accessory/clothing/underwear/male_hearts
	name = "Hearts Boxers"
	icon_state = "male_hearts"
	gender = MALE
	use_static = TRUE
	digi_icon_state = "boxers_stripe_threecolor"
	greyscale_colors = "#D62626#EEEEEE#D62626#"

/datum/sprite_accessory/clothing/underwear/male_commie
	name = "Commie Boxers"
	icon_state = "male_commie"
	gender = MALE
	use_static = TRUE
	digi_icon_state = "boxers_stripe_twocolor"
	greyscale_colors = "#D62626#D1B62C#D62626"

/datum/sprite_accessory/clothing/underwear/male_usastripe
	name = "Freedom Boxers"
	icon_state = "male_assblastusa"
	gender = MALE
	use_static = TRUE
	digi_icon_state = "boxers_stripe_threecolor"
	greyscale_colors = "#D62626#EEEEEE#2E26D6"

/datum/sprite_accessory/clothing/underwear/male_uk
	name = "UK Boxers"
	icon_state = "male_uk"
	gender = MALE
	use_static = TRUE
	digi_icon_state = "boxers_stripe_threecolor"
	greyscale_colors = "#D62626#EEEEEE#2E26D6"

//FEMALE UNDERWEAR
/datum/sprite_accessory/clothing/underwear/female_bikini
	name = "Bikini"
	icon_state = "female_bikini"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/female_lace
	name = "Lace Bikini"
	icon_state = "female_lace"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/female_bralette
	name = "Bralette w/ Boyshorts"
	icon_state = "female_bralette"
	gender = FEMALE
	digi_icon_state = "short_short"

/datum/sprite_accessory/clothing/underwear/female_sport
	name = "Sports Bra w/ Boyshorts"
	icon_state = "female_sport"
	gender = FEMALE
	digi_icon_state = "short"

/datum/sprite_accessory/clothing/underwear/female_thong
	name = "Thong"
	icon_state = "female_thong"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/female_strapless
	name = "Strapless Bikini"
	icon_state = "female_strapless"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/female_babydoll
	name = "Babydoll"
	icon_state = "female_babydoll"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/swimsuit_onepiece
	name = "One-Piece Swimsuit"
	icon_state = "swim_onepiece"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/swimsuit_strapless_onepiece
	name = "Strapless One-Piece Swimsuit"
	icon_state = "swim_strapless_onepiece"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/swimsuit_twopiece
	name = "Two-Piece Swimsuit"
	icon_state = "swim_twopiece"
	gender = FEMALE
	digi_icon_state = "short_short"

/datum/sprite_accessory/clothing/underwear/swimsuit_strapless_twopiece
	name = "Strapless Two-Piece Swimsuit"
	icon_state = "swim_strapless_twopiece"
	gender = FEMALE
	digi_icon_state = "short_short"

/datum/sprite_accessory/clothing/underwear/swimsuit_stripe
	name = "Strapless Striped Swimsuit"
	icon_state = "swim_stripe"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/swimsuit_halter
	name = "Halter Swimsuit"
	icon_state = "swim_halter"
	gender = FEMALE

/datum/sprite_accessory/clothing/underwear/female_white_neko
	name = "Neko Bikini (White)"
	icon_state = "female_neko_white"
	gender = FEMALE
	use_static = TRUE

/datum/sprite_accessory/clothing/underwear/female_black_neko
	name = "Neko Bikini (Black)"
	icon_state = "female_neko_black"
	gender = FEMALE
	use_static = TRUE

/datum/sprite_accessory/clothing/underwear/female_commie
	name = "Commie Bikini"
	icon_state = "female_commie"
	gender = FEMALE
	use_static = TRUE

/datum/sprite_accessory/clothing/underwear/female_usastripe
	name = "Freedom Bikini"
	icon_state = "female_assblastusa"
	gender = FEMALE
	use_static = TRUE

/datum/sprite_accessory/clothing/underwear/female_uk
	name = "UK Bikini"
	icon_state = "female_uk"
	gender = FEMALE
	use_static = TRUE

/datum/sprite_accessory/clothing/underwear/female_kinky
	name = "Lingerie"
	icon_state = "female_kinky"
	gender = FEMALE
	use_static = TRUE

