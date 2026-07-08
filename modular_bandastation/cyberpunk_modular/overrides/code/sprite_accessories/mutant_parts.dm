// Split from the old core code/datums/sprite_accessories.dm monolith for modular conflict isolation.
//////////.//////////////////
// MutantParts Definitions //
/////////////////////////////

/datum/sprite_accessory/lizard_markings
	icon = 'icons/mob/human/species/lizard/lizard_markings.dmi'

/datum/sprite_accessory/lizard_markings/dtiger
	name = "Dark Tiger Body"
	icon_state = "dtiger"
	gender_specific = TRUE

/datum/sprite_accessory/lizard_markings/ltiger
	name = "Light Tiger Body"
	icon_state = "ltiger"
	gender_specific = TRUE

/datum/sprite_accessory/lizard_markings/lbelly
	name = "Light Belly"
	icon_state = "lbelly"
	gender_specific = TRUE

/datum/sprite_accessory/human_tattoo
	icon = 'icons/mob/human/species/lizard/lizard_markings.dmi'
	color_src = TRUE
	gender_specific = TRUE

/datum/sprite_accessory/human_tattoo/circuit
	name = "Circuit Tattoo"
	icon_state = "dtiger"

/datum/sprite_accessory/human_tattoo/tribal
	name = "Tribal Tattoo"
	icon_state = "ltiger"

/datum/sprite_accessory/human_tattoo/torso
	name = "Torso Tattoo"
	icon_state = "lbelly"

/datum/sprite_accessory/tails
	em_block = TRUE

///Used for fish-infused tails, which come in different flavors.
/datum/sprite_accessory/tails/fish
	icon = 'icons/mob/human/fish_features.dmi'
	color_src = TRUE

/datum/sprite_accessory/tails/fish/simple
	name = "Simple"
	icon_state = "simple"

/datum/sprite_accessory/tails/fish/crescent
	name = "Crescent"
	icon_state = "crescent"

/datum/sprite_accessory/tails/fish/long
	name = "Long"
	icon_state = "long"
	center = TRUE
	dimension_x = 38

/datum/sprite_accessory/tails/fish/shark
	name = "Shark"
	icon_state = "shark"

/datum/sprite_accessory/tails/fish/chonky
	name = "Chonky"
	icon_state = "chonky"
	center = TRUE
	dimension_x = 36

/datum/sprite_accessory/tails/lizard
	icon = 'icons/mob/human/species/lizard/lizard_tails.dmi'
	spine_key = SPINE_KEY_LIZARD

/datum/sprite_accessory/tails/lizard/none
	name = SPRITE_ACCESSORY_NONE
	icon_state = "none"
	natural_spawn = FALSE

/datum/sprite_accessory/tails/lizard/smooth
	name = "Smooth"
	icon_state = "smooth"

/datum/sprite_accessory/tails/lizard/dtiger
	name = "Dark Tiger"
	icon_state = "dtiger"

/datum/sprite_accessory/tails/lizard/ltiger
	name = "Light Tiger"
	icon_state = "ltiger"

/datum/sprite_accessory/tails/lizard/spikes
	name = "Spikes"
	icon_state = "spikes"

/datum/sprite_accessory/tails/lizard/short
	name = "Short"
	icon_state = "short"
	spine_key = NONE

/datum/sprite_accessory/tails/felinid/cat
	name = "Cat"
	icon = 'icons/mob/human/cat_features.dmi'
	icon_state = "default"
	color_src = HAIR_COLOR

/datum/sprite_accessory/tails/monkey

/datum/sprite_accessory/tails/monkey/none
	name = SPRITE_ACCESSORY_NONE
	icon_state = "none"
	natural_spawn = FALSE

/datum/sprite_accessory/tails/monkey/default
	name = "Monkey"
	icon = 'icons/mob/human/species/monkey/monkey_tail.dmi'
	icon_state = "default"
	color_src = FALSE

/datum/sprite_accessory/tails/xeno
	icon_state = "default"
	color_src = FALSE
	center = TRUE

/datum/sprite_accessory/tails/xeno/default
	name = "Xeno"
	icon = 'icons/mob/human/species/alien/tail_xenomorph.dmi'
	dimension_x = 40

/datum/sprite_accessory/tails/xeno/queen
	name = "Xeno Queen"
	icon = 'icons/mob/human/species/alien/tail_xenomorph_queen.dmi'
	dimension_x = 64

/datum/sprite_accessory/pod_hair
	icon = 'icons/mob/human/species/podperson_hair.dmi'
	em_block = TRUE

/datum/sprite_accessory/pod_hair/ivy
	name = "Ivy"
	icon_state = "ivy"

/datum/sprite_accessory/pod_hair/cabbage
	name = "Cabbage"
	icon_state = "cabbage"

/datum/sprite_accessory/pod_hair/spinach
	name = "Spinach"
	icon_state = "spinach"

/datum/sprite_accessory/pod_hair/prayer
	name = "Prayer"
	icon_state = "prayer"

/datum/sprite_accessory/pod_hair/vine
	name = "Vine"
	icon_state = "vine"

/datum/sprite_accessory/pod_hair/shrub
	name = "Shrub"
	icon_state = "shrub"

/datum/sprite_accessory/pod_hair/rose
	name = "Rose"
	icon_state = "rose"

/datum/sprite_accessory/pod_hair/orchid
	name = "Orchid"
	icon_state = "orchid"

/datum/sprite_accessory/pod_hair/fig
	name = "Fig"
	icon_state = "fig"

/datum/sprite_accessory/pod_hair/hibiscus
	name = "Hibiscus"
	icon_state = "hibiscus"

/datum/sprite_accessory/snouts
	icon = 'icons/mob/human/species/lizard/lizard_misc.dmi'
	em_block = TRUE

/datum/sprite_accessory/snouts/sharp
	name = "Sharp"
	icon_state = "sharp"

/datum/sprite_accessory/snouts/round
	name = "Round"
	icon_state = "round"

/datum/sprite_accessory/snouts/sharplight
	name = "Sharp + Light"
	icon_state = "sharplight"

/datum/sprite_accessory/snouts/roundlight
	name = "Round + Light"
	icon_state = "roundlight"

/datum/sprite_accessory/horns
	icon = 'icons/mob/human/species/lizard/lizard_misc.dmi'
	em_block = TRUE

/datum/sprite_accessory/horns/simple
	name = "Simple"
	icon_state = "simple"

/datum/sprite_accessory/horns/short
	name = "Short"
	icon_state = "short"

/datum/sprite_accessory/horns/curled
	name = "Curled"
	icon_state = "curled"

/datum/sprite_accessory/horns/ram
	name = "Ram"
	icon_state = "ram"

/datum/sprite_accessory/horns/angler
	name = "Angeler"
	icon_state = "angler"

/datum/sprite_accessory/ears
	icon = 'icons/mob/human/cat_features.dmi'
	em_block = TRUE

/datum/sprite_accessory/ears/cat
	name = "Cat"
	icon_state = "cat"
	color_src = HAIR_COLOR

/datum/sprite_accessory/ears/cat/big
	name = "Big"
	icon_state = "big"

/datum/sprite_accessory/ears/cat/miqo
	name = "Coeurl"
	icon_state = "miqo"

/datum/sprite_accessory/ears/cat/fold
	name = "Fold"
	icon_state = "fold"

/datum/sprite_accessory/ears/cat/lynx
	name = "Lynx"
	icon_state = "lynx"

/datum/sprite_accessory/ears/cat/round
	name = "Round"
	icon_state = "round"

/datum/sprite_accessory/ears/cat/cybernetic
	name = "Cybernetic"
	icon_state = "cyber"
	locked = TRUE

/datum/sprite_accessory/ears/fox
	icon = 'icons/mob/human/fox_features.dmi'
	name = "Fox"
	icon_state = "fox"
	color_src = HAIR_COLOR
	locked = TRUE

/datum/sprite_accessory/wings
	icon = 'icons/mob/human/species/wings.dmi'
	em_block = TRUE

/datum/sprite_accessory/wings_open
	icon = 'icons/mob/human/species/wings.dmi'
	em_block = TRUE

/datum/sprite_accessory/wings/angel
	name = "Angel"
	icon_state = "angel"
	color_src = FALSE
	dimension_x = 46
	center = TRUE
	dimension_y = 34
	locked = TRUE

/datum/sprite_accessory/wings_open/angel
	name = "Angel"
	icon_state = "angel"
	color_src = FALSE
	dimension_x = 46
	center = TRUE
	dimension_y = 34

/datum/sprite_accessory/wings/dragon
	name = "Dragon"
	icon_state = "dragon"
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/dragon
	name = "Dragon"
	icon_state = "dragon"
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/megamoth
	name = "Megamoth"
	icon_state = "megamoth"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/megamoth
	name = "Megamoth"
	icon_state = "megamoth"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/mothra
	name = "Mothra"
	icon_state = "mothra"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/mothra
	name = "Mothra"
	icon_state = "mothra"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/skeleton
	name = "Skeleton"
	icon_state = "skele"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/skeleton
	name = "Skeleton"
	icon_state = "skele"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/robotic
	name = "Robotic"
	icon_state = "robotic"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/robotic
	name = "Robotic"
	icon_state = "robotic"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/fly
	name = "Fly"
	icon_state = "fly"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/fly
	name = "Fly"
	icon_state = "fly"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/slime
	name = "Slime"
	icon_state = "slime"
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/slime
	name = "Slime"
	icon_state = "slime"
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/frills
	icon = 'icons/mob/human/species/lizard/lizard_misc.dmi'

/datum/sprite_accessory/frills/simple
	name = "Simple"
	icon_state = "simple"

/datum/sprite_accessory/frills/short
	name = "Short"
	icon_state = "short"

/datum/sprite_accessory/frills/aquatic
	name = "Aquatic"
	icon_state = "aqua"

/datum/sprite_accessory/spines
	icon = 'icons/mob/human/species/lizard/lizard_spines.dmi'
	em_block = TRUE

/datum/sprite_accessory/tail_spines
	icon = 'icons/mob/human/species/lizard/lizard_spines.dmi'
	em_block = TRUE

/datum/sprite_accessory/spines/short
	name = "Short"
	icon_state = "short"

/datum/sprite_accessory/tail_spines/short
	name = "Short"
	icon_state = "short"

/datum/sprite_accessory/spines/shortmeme
	name = "Short + Membrane"
	icon_state = "shortmeme"

/datum/sprite_accessory/tail_spines/shortmeme
	name = "Short + Membrane"
	icon_state = "shortmeme"

/datum/sprite_accessory/spines/long
	name = "Long"
	icon_state = "long"

/datum/sprite_accessory/tail_spines/long
	name = "Long"
	icon_state = "long"

/datum/sprite_accessory/spines/longmeme
	name = "Long + Membrane"
	icon_state = "longmeme"

/datum/sprite_accessory/tail_spines/longmeme
	name = "Long + Membrane"
	icon_state = "longmeme"

/datum/sprite_accessory/spines/aquatic
	name = "Aquatic"
	icon_state = "aqua"

/datum/sprite_accessory/tail_spines/aquatic
	name = "Aquatic"
	icon_state = "aqua"

/datum/sprite_accessory/caps
	icon = 'icons/mob/human/species/mush_cap.dmi'
	color_src = HAIR_COLOR
	em_block = TRUE

/datum/sprite_accessory/caps/round
	name = "Round"
	icon_state = "round"

/datum/sprite_accessory/moth_wings
	icon = 'icons/mob/human/species/moth/moth_wings.dmi'
	color_src = null
	em_block = TRUE

/datum/sprite_accessory/moth_wings/plain
	name = "Plain"
	icon_state = "plain"

/datum/sprite_accessory/moth_wings/monarch
	name = "Monarch"
	icon_state = "monarch"

/datum/sprite_accessory/moth_wings/luna
	name = "Luna"
	icon_state = "luna"

/datum/sprite_accessory/moth_wings/atlas
	name = "Atlas"
	icon_state = "atlas"

/datum/sprite_accessory/moth_wings/reddish
	name = "Reddish"
	icon_state = "redish"

/datum/sprite_accessory/moth_wings/royal
	name = "Royal"
	icon_state = "royal"

/datum/sprite_accessory/moth_wings/gothic
	name = "Gothic"
	icon_state = "gothic"

/datum/sprite_accessory/moth_wings/lovers
	name = "Lovers"
	icon_state = "lovers"

/datum/sprite_accessory/moth_wings/whitefly
	name = "White Fly"
	icon_state = "whitefly"

/datum/sprite_accessory/moth_wings/burnt_off
	name = "Burnt Off"
	icon_state = "burnt_off"
	locked = TRUE

/datum/sprite_accessory/moth_wings/firewatch
	name = "Firewatch"
	icon_state = "firewatch"

/datum/sprite_accessory/moth_wings/deathhead
	name = "Deathshead"
	icon_state = "deathhead"

/datum/sprite_accessory/moth_wings/poison
	name = "Poison"
	icon_state = "poison"

/datum/sprite_accessory/moth_wings/ragged
	name = "Ragged"
	icon_state = "ragged"

/datum/sprite_accessory/moth_wings/moonfly
	name = "Moon Fly"
	icon_state = "moonfly"

/datum/sprite_accessory/moth_wings/snow
	name = "Snow"
	icon_state = "snow"

/datum/sprite_accessory/moth_wings/oakworm
	name = "Oak Worm"
	icon_state = "oakworm"

/datum/sprite_accessory/moth_wings/jungle
	name = "Jungle"
	icon_state = "jungle"

/datum/sprite_accessory/moth_wings/witchwing
	name = "Witch Wing"
	icon_state = "witchwing"

/datum/sprite_accessory/moth_wings/rosy
	name = "Rosy"
	icon_state = "rosy"

/datum/sprite_accessory/moth_wings/feathery
	name = "Feathery"
	icon_state = "feathery"

/datum/sprite_accessory/moth_wings/brown
	name = "Brown"
	icon_state = "brown"

/datum/sprite_accessory/moth_wings/plasmafire
	name = "Plasmafire"
	icon_state = "plasmafire"

/datum/sprite_accessory/moth_wings/moffra
	name = "Moffra"
	icon_state = "moffra"

/datum/sprite_accessory/moth_wings/lightbearer
	name = "Lightbearer"
	icon_state = "lightbearer"

/datum/sprite_accessory/moth_wings/dipped
	name = "Dipped"
	icon_state = "dipped"

/datum/sprite_accessory/moth_antennae //Finally splitting the sprite
	icon = 'icons/mob/human/species/moth/moth_antennae.dmi'
	color_src = null

/datum/sprite_accessory/moth_antennae/plain
	name = "Plain"
	icon_state = "plain"

/datum/sprite_accessory/moth_antennae/reddish
	name = "Reddish"
	icon_state = "reddish"

/datum/sprite_accessory/moth_antennae/royal
	name = "Royal"
	icon_state = "royal"

/datum/sprite_accessory/moth_antennae/gothic
	name = "Gothic"
	icon_state = "gothic"

/datum/sprite_accessory/moth_antennae/whitefly
	name = "White Fly"
	icon_state = "whitefly"

/datum/sprite_accessory/moth_antennae/lovers
	name = "Lovers"
	icon_state = "lovers"

/datum/sprite_accessory/moth_antennae/burnt_off
	name = "Burnt Off"
	icon_state = "burnt_off"

/datum/sprite_accessory/moth_antennae/firewatch
	name = "Firewatch"
	icon_state = "firewatch"

/datum/sprite_accessory/moth_antennae/deathhead
	name = "Deathshead"
	icon_state = "deathhead"

/datum/sprite_accessory/moth_antennae/poison
	name = "Poison"
	icon_state = "poison"

/datum/sprite_accessory/moth_antennae/ragged
	name = "Ragged"
	icon_state = "ragged"

/datum/sprite_accessory/moth_antennae/moonfly
	name = "Moon Fly"
	icon_state = "moonfly"

/datum/sprite_accessory/moth_antennae/oakworm
	name = "Oak Worm"
	icon_state = "oakworm"

/datum/sprite_accessory/moth_antennae/jungle
	name = "Jungle"
	icon_state = "jungle"

/datum/sprite_accessory/moth_antennae/witchwing
	name = "Witch Wing"
	icon_state = "witchwing"

/datum/sprite_accessory/moth_antennae/regal
	name = "Regal"
	icon_state = "regal"
/datum/sprite_accessory/moth_antennae/rosy
	name = "Rosy"
	icon_state = "rosy"

/datum/sprite_accessory/moth_antennae/feathery
	name = "Feathery"
	icon_state = "feathery"

/datum/sprite_accessory/moth_antennae/brown
	name = "Brown"
	icon_state = "brown"

/datum/sprite_accessory/moth_antennae/plasmafire
	name = "Plasmafire"
	icon_state = "plasmafire"

/datum/sprite_accessory/moth_antennae/moffra
	name = "Moffra"
	icon_state = "moffra"

/datum/sprite_accessory/moth_antennae/lightbearer
	name = "Lightbearer"
	icon_state = "lightbearer"

/datum/sprite_accessory/moth_antennae/dipped
	name = "Dipped"
	icon_state = "dipped"

/datum/sprite_accessory/moth_markings // the markings that moths can have. finally something other than the boring tan
	icon = 'icons/mob/human/species/moth/moth_markings.dmi'
	color_src = null

/datum/sprite_accessory/moth_markings/reddish
	name = "Reddish"
	icon_state = "reddish"

/datum/sprite_accessory/moth_markings/royal
	name = "Royal"
	icon_state = "royal"

/datum/sprite_accessory/moth_markings/gothic
	name = "Gothic"
	icon_state = "gothic"

/datum/sprite_accessory/moth_markings/whitefly
	name = "White Fly"
	icon_state = "whitefly"

/datum/sprite_accessory/moth_markings/lovers
	name = "Lovers"
	icon_state = "lovers"

/datum/sprite_accessory/moth_markings/burnt_off
	name = "Burnt Off"
	icon_state = "burnt_off"

/datum/sprite_accessory/moth_markings/firewatch
	name = "Firewatch"
	icon_state = "firewatch"

/datum/sprite_accessory/moth_markings/deathhead
	name = "Deathshead"
	icon_state = "deathhead"

/datum/sprite_accessory/moth_markings/poison
	name = "Poison"
	icon_state = "poison"

/datum/sprite_accessory/moth_markings/ragged
	name = "Ragged"
	icon_state = "ragged"

/datum/sprite_accessory/moth_markings/moonfly
	name = "Moon Fly"
	icon_state = "moonfly"

/datum/sprite_accessory/moth_markings/oakworm
	name = "Oak Worm"
	icon_state = "oakworm"

/datum/sprite_accessory/moth_markings/jungle
	name = "Jungle"
	icon_state = "jungle"

/datum/sprite_accessory/moth_markings/witchwing
	name = "Witch Wing"
	icon_state = "witchwing"

/datum/sprite_accessory/moth_markings/lightbearer
	name = "Lightbearer"
	icon_state = "lightbearer"

/datum/sprite_accessory/moth_markings/dipped
	name = "Dipped"
	icon_state = "dipped"
