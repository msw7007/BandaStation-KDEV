/atom/movable/screen/screentip
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// The text field spans the view. Anchor its left edge, not its midpoint.
	screen_loc = "WEST,NORTH"
	maptext_x = 8
	maptext_height = 480
	maptext_width = 464
	maptext = ""
	layer = SCREENTIP_LAYER //Added to make screentips appear above action buttons (and other /atom/movable/screen objects)

/atom/movable/screen/screentip/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_view()

/atom/movable/screen/screentip/proc/update_view(datum/source, view)
	SIGNAL_HANDLER
	view ||= hud?.mymob.canon_client?.view_size?.getView()
	if(!view) //Might not have been initialized by now
		return
	maptext_width = max(1, view_to_pixels(view)[1] - 2 * maptext_x)
