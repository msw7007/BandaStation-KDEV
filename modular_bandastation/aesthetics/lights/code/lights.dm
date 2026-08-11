/obj/machinery/light
	icon = MAP_SWITCH('modular_bandastation/aesthetics/lights/icons/lighting.dmi', 'modular_bandastation/objects/icons/obj/structures/light.dmi')
	overlay_icon = 'modular_bandastation/aesthetics/lights/icons/lighting_overlay.dmi'
	bulb_colour = "#FFF7F2"
	bulb_power = 0.8
	nightshift_light_power = 0.6

/obj/machinery/light/small
	icon = MAP_SWITCH('icons/obj/lighting.dmi', 'modular_bandastation/objects/icons/obj/structures/light.dmi')

/obj/machinery/light/floor
	icon = MAP_SWITCH('icons/obj/lighting.dmi', 'modular_bandastation/objects/icons/obj/structures/light.dmi')
	overlay_icon = 'icons/obj/lighting_overlay.dmi'

/obj/structure/light_construct
	icon = 'modular_bandastation/aesthetics/lights/icons/lighting.dmi'

/obj/structure/light_construct/small
	icon = 'icons/obj/lighting.dmi'

/obj/structure/light_construct/floor
	icon = 'icons/obj/lighting.dmi'

/obj/item/wallframe/light_fixture
	icon = 'modular_bandastation/aesthetics/lights/icons/lighting.dmi'

/obj/item/wallframe/light_fixture/small
	icon = 'icons/obj/lighting.dmi'

// MARK: Cyberpunk lanterns
/obj/machinery/light/cyberpunk_lantern
	name = "city lantern"
	desc = "A compact wall-mounted city lantern."
	icon = 'modular_bandastation/objects/icons/obj/structures/lanterns.dmi'
	icon_state = "lantern_1_on"
	base_state = "lantern_1"
	overlay_icon = null
	on = TRUE
	brightness = 5
	nightshift_brightness = 4
	fire_brightness = 5
	bulb_power = 0.9
	bulb_colour = "#5fd8ff"
	nightshift_light_color = "#75b7ff"
	fire_colour = "#ff4e4e"
	light_angle = 170
	light_type = /obj/item/light/bulb
	fitting = "lantern bulb"

/obj/machinery/light/cyberpunk_lantern/update_icon_state()
	. = ..()
	icon_state = "[base_state]_[on && status == LIGHT_OK ? "on" : "off"]"

/obj/machinery/light/cyberpunk_lantern/update_overlays()
	. = ..()
	return list()

/obj/machinery/light/cyberpunk_lantern/off
	icon_state = "lantern_1_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_2
	icon_state = "lantern_2_on"
	base_state = "lantern_2"

/obj/machinery/light/cyberpunk_lantern/variant_2/off
	icon_state = "lantern_2_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_3
	icon_state = "lantern_3_on"
	base_state = "lantern_3"

/obj/machinery/light/cyberpunk_lantern/variant_3/off
	icon_state = "lantern_3_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_4
	icon_state = "lantern_4_on"
	base_state = "lantern_4"

/obj/machinery/light/cyberpunk_lantern/variant_4/off
	icon_state = "lantern_4_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_5
	icon_state = "lantern_5_on"
	base_state = "lantern_5"

/obj/machinery/light/cyberpunk_lantern/variant_5/off
	icon_state = "lantern_5_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_6
	icon_state = "lantern_6_on"
	base_state = "lantern_6"

/obj/machinery/light/cyberpunk_lantern/variant_6/off
	icon_state = "lantern_6_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_7
	icon_state = "lantern_7_on"
	base_state = "lantern_7"

/obj/machinery/light/cyberpunk_lantern/variant_7/off
	icon_state = "lantern_7_off"
	on = FALSE

/obj/machinery/light/cyberpunk_lantern/variant_8
	icon_state = "lantern_8_on"
	base_state = "lantern_8"

/obj/machinery/light/cyberpunk_lantern/variant_8/off
	icon_state = "lantern_8_off"
	on = FALSE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_2, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_2/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_3, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_3/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_4, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_4/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_5, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_5/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_6, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_6/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_7, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_7/off, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_8, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/light/cyberpunk_lantern/variant_8/off, 0)
