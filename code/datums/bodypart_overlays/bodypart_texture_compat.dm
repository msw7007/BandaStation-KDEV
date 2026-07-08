// Compatibility shim for upstream bodypart texture APIs restored during modularization.

/datum/bodypart_overlay
	var/offset_location = NO_MODIFY

/datum/bodypart_texture

/datum/bodypart_texture/proc/can_texture_bodypart(obj/item/bodypart/bodypart_owner)
	return TRUE

/datum/bodypart_texture/proc/modify_bodypart_appearance(datum/appearance)
	return

/datum/bodypart_overlay/proc/icon_render_key(obj/item/bodypart/limb)
	return generate_icon_cache(limb)
