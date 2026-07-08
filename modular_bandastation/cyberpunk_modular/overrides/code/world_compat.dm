// Compatibility vars for upstream code restored into core during modularization.

/area
	var/tacmap_color
	var/skip_minimap_rendering = FALSE

/turf
	var/tacmap_color
	var/skip_minimap_rendering = FALSE

/turf/closed
	appearance_flags = LONG_GLIDE
	/// Suffix used by diagonal bitmask smoothing states.
	var/diagonal_smoothing_suffix = "diagonal"

/turf/closed/examine_descriptor(mob/user)
	return "стена"

/turf/closed/add_large_wall_overlay(wall_icon, wall_state)
	var/static/mutable_appearance/wall_overlay = mutable_appearance('icons/turf/mining.dmi', "rock", appearance_flags = RESET_TRANSFORM)
	wall_overlay.plane = MUTATE_PLANE(WALL_PLANE, src)
	overlays += wall_overlay

/turf/open/space
	force_no_gravity = FALSE
	skip_minimap_rendering = FALSE

/area/station/science
	tacmap_color = null

/area/station/science/ordnance/bomb
	area_flags = BLOBS_ALLOWED | CULT_PERMITTED
	skip_minimap_rendering = FALSE

/area/station/science/ordnance/bomb/planet
	area_flags = /area/station/science/ordnance/bomb::area_flags
