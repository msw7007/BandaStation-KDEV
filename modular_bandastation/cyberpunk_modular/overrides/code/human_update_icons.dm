// Cyberpunk human visual overrides kept outside core to reduce upstream merge conflicts.

/// Returns a list of all underclothing overlays to be applied to the mob.
/// Extends upstream preference overlays with wearable underwear clothing slots.
/mob/living/carbon/human/get_underwear_overlays()
	. = list()
	if(HAS_TRAIT(src, TRAIT_HUSK) || HAS_TRAIT(src, TRAIT_INVISIBLE_MAN) || HAS_TRAIT(src, TRAIT_NO_UNDERWEAR))
		return .

	if(wear_underwear)
		var/mutable_appearance/worn_underwear_overlay = wear_underwear.make_underwear_appearance(src)
		if(worn_underwear_overlay)
			. += worn_underwear_overlay
	else if(underwear)
		var/datum/sprite_accessory/clothing/underwear/undie_accessory = SSaccessories.underwear_list[underwear]
		var/mutable_appearance/pref_underwear_overlay = undie_accessory?.make_appearance(underwear_color, physique, bodyshape)
		if(pref_underwear_overlay)
			. += pref_underwear_overlay

	if(wear_undershirt)
		var/mutable_appearance/worn_shirt_overlay = wear_undershirt.make_underwear_appearance(src)
		if(worn_shirt_overlay)
			. += worn_shirt_overlay
	else if(undershirt)
		var/datum/sprite_accessory/clothing/undershirt/shirt_accessory = SSaccessories.undershirt_list[undershirt]
		var/mutable_appearance/pref_shirt_overlay = shirt_accessory?.make_appearance(null, physique, bodyshape)
		if(pref_shirt_overlay)
			. += pref_shirt_overlay

	if(wear_tights && num_legs >= 2 && !(bodyshape & BODYSHAPE_DIGITIGRADE))
		var/mutable_appearance/worn_socks_overlay = wear_tights.make_underwear_appearance(src)
		if(worn_socks_overlay)
			. += worn_socks_overlay
	else if(socks && num_legs >= 2 && !(bodyshape & BODYSHAPE_DIGITIGRADE))
		var/datum/sprite_accessory/clothing/socks/sock_accessory = SSaccessories.socks_list[socks]
		var/mutable_appearance/pref_socks_overlay = sock_accessory?.make_appearance(null, physique, bodyshape)
		if(pref_socks_overlay)
			. += pref_socks_overlay
