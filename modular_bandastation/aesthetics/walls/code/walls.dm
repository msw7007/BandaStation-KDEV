// MARK: Falsewalls
/obj/structure/falsewall
	icon = 'modular_bandastation/aesthetics/walls/icons/false_walls.dmi'
	base_icon_state = "wall"
	icon_state = "wall-open"
	fake_icon = 'icons/turf/walls/32x40wall.dmi'

/obj/structure/falsewall/reinforced
	icon_state = "reinforced_wall-open"
	base_icon_state = "reinforced_wall"
	icon = 'modular_bandastation/aesthetics/walls/icons/false_walls.dmi'
	fake_icon = 'icons/turf/walls/32x40reinforced_wall.dmi'

/obj/structure/falsewall/uranium
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/gold
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/silver
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/diamond
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/plasma
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/bananium
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/sandstone
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/wood
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/bamboo
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/iron
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/abductor
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/titanium
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/plastitanium
	icon = 'icons/turf/walls/false_walls.dmi'

/obj/structure/falsewall/material
	icon = 'icons/turf/walls/false_walls.dmi'

// MARK: Cyberpunk interior walls
#define CYBERPUNK_INTERIOR_WALL_UNDERLAY_MASKS 'modular_bandastation/aesthetics/walls/icons/interior_wall_underlay_masks.dmi'
#define CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_ICON 'icons/turf/floors.dmi'
#define CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_STATE "plating"

/proc/cyberpunk_interior_wall_underlay_icon(turf/center)
	var/static/list/icon_cache = list()
	var/static/list/cardinal_masks = list(
		"[NORTH]" = "north",
		"[EAST]" = "east",
		"[SOUTH]" = "south",
		"[WEST]" = "west",
	)

	var/cache_key = ""
	var/list/source_data = list()
	for(var/direction_text as anything in cardinal_masks)
		var/direction = text2num(direction_text)
		var/turf/source_turf = get_step(center, direction)
		var/source_icon = CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_ICON
		var/source_icon_state = CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_STATE
		var/source_dir = SOUTH
		if(isopenturf(source_turf))
			source_icon = source_turf.icon
			source_icon_state = source_turf.icon_state
			source_dir = source_turf.dir
		source_data[direction_text] = list(source_icon, source_icon_state, source_dir)
		cache_key += "[direction_text]=[source_icon]|[source_icon_state]|[source_dir];"

	var/icon/cached_icon = icon_cache[cache_key]
	if(cached_icon)
		return cached_icon

	var/icon/result_icon = icon('icons/effects/effects.dmi', "nothing")
	for(var/direction_text as anything in cardinal_masks)
		var/list/data = source_data[direction_text]
		var/icon/source_part = icon(data[1], data[2], data[3], 1)
		source_part.Blend(icon(CYBERPUNK_INTERIOR_WALL_UNDERLAY_MASKS, cardinal_masks[direction_text]), ICON_MULTIPLY)
		result_icon.Blend(source_part, ICON_OVERLAY)

	icon_cache[cache_key] = result_icon
	return result_icon

/turf/closed/wall/cyberpunk
	name = "city wall"
	desc = "A compact interior city wall."

/turf/closed/wall/cyberpunk/interior
	name = "city interior wall"
	var/mutable_appearance/cyberpunk_neighbor_floor_underlay

/turf/closed/wall/cyberpunk/interior/Initialize(mapload)
	. = ..()
	update_cyberpunk_neighbor_floor_underlay()

/turf/closed/wall/cyberpunk/interior/Destroy()
	clear_cyberpunk_neighbor_floor_underlay()
	return ..()

/turf/closed/wall/cyberpunk/interior/smooth_icon()
	. = ..()
	update_cyberpunk_neighbor_floor_underlay()

/turf/closed/wall/cyberpunk/interior/proc/clear_cyberpunk_neighbor_floor_underlay()
	if(!cyberpunk_neighbor_floor_underlay)
		return
	underlays -= cyberpunk_neighbor_floor_underlay
	cyberpunk_neighbor_floor_underlay = null

/turf/closed/wall/cyberpunk/interior/proc/update_cyberpunk_neighbor_floor_underlay()
	clear_cyberpunk_neighbor_floor_underlay()
	cyberpunk_neighbor_floor_underlay = mutable_appearance(cyberpunk_interior_wall_underlay_icon(src), "", LOW_FLOOR_LAYER, src, FLOOR_PLANE)
	underlays += cyberpunk_neighbor_floor_underlay

#undef CYBERPUNK_INTERIOR_WALL_UNDERLAY_MASKS
#undef CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_ICON
#undef CYBERPUNK_INTERIOR_WALL_FALLBACK_FLOOR_STATE
