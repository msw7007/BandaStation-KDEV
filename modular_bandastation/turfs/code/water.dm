/turf/open/water/no_fishing
	fishing_datum = null // There's no fish in it

/turf/open/water/alternative
	desc = "Прозрачная вода."
	icon = 'modular_bandastation/turfs/icons/water.dmi'
	icon_state = "water"
	base_icon_state = "water"
	baseturfs = /turf/open/water/alternative

/turf/open/water/alternative/no_fishing
	fishing_datum = null // There's no fish in it

/turf/open/water/alternative/deep
	name = "deep water"
	desc = "Deep water. You can swim here, but staying under for too long is dangerous."
	immerse_overlay = "immerse_deep"
	is_swimming_tile = TRUE
	baseturfs = /turf/open/water/alternative/deep

/turf/open/water/alternative/deep/no_fishing
	fishing_datum = null // There's no fish in it

/turf/open/water/alternative/muddy
	desc = "Очень старая стоячая вода. Туда страшно даже ногу опустить."
	icon_state = "water_sewer"
	base_icon_state = "water_sewer"
	baseturfs = /turf/open/water/alternative/muddy

/turf/open/water/alternative/muddy/no_fishing
	fishing_datum = null // There's no fish in it

/turf/open/water/alternative/muddy/deep
	name = "deep muddy water"
	desc = "Deep stagnant water. Swimming here is exhausting."
	immerse_overlay = "immerse_deep"
	is_swimming_tile = TRUE
	baseturfs = /turf/open/water/alternative/muddy/deep

/turf/open/water/alternative/muddy/deep/no_fishing
	fishing_datum = null // There's no fish in it
