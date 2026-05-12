/obj/item/organ/appearance_feature
	name = "appearance feature"
	zone = BODY_ZONE_CHEST
	organ_flags = ORGAN_ORGANIC | ORGAN_EXTERNAL
	visual = TRUE
	useable = FALSE
	var/preference_size = 1
	var/sprite_sheet_key = "default"

/obj/item/organ/appearance_feature/proc/set_preference_size(new_size)
	preference_size = clamp(round(new_size, 1), 0, 4)
	sprite_sheet_key = "size_[preference_size]"
	name = "[initial(name)] ([sprite_sheet_key])"

/obj/item/organ/appearance_feature/breasts
	name = "breasts"
	slot = ORGAN_SLOT_EXTERNAL_BREASTS
	zone = BODY_ZONE_CHEST

/obj/item/organ/appearance_feature/penis
	name = "penis"
	slot = ORGAN_SLOT_EXTERNAL_PENIS
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/appearance_feature/testicles
	name = "testicles"
	slot = ORGAN_SLOT_EXTERNAL_TESTICLES
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/appearance_feature/butt
	name = "butt"
	slot = ORGAN_SLOT_EXTERNAL_BUTT
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/appearance_feature/belly
	name = "belly"
	slot = ORGAN_SLOT_EXTERNAL_BELLY
	zone = BODY_ZONE_CHEST

/obj/item/organ/appearance_feature/vagina
	name = "vagina"
	slot = ORGAN_SLOT_EXTERNAL_VAGINA
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/appearance_feature/anus
	name = "anus"
	slot = ORGAN_SLOT_EXTERNAL_ANUS
	zone = BODY_ZONE_PRECISE_GROIN

/mob/living/carbon/human/proc/set_appearance_organ(organ_slot, organ_type, size = 1, enabled = TRUE)
	var/list/appearance_organs = dna.features["appearance_organs"]
	if(!islist(appearance_organs))
		appearance_organs = list()
		dna.features["appearance_organs"] = appearance_organs

	appearance_organs[organ_slot] = list(
		"enabled" = enabled,
		"size" = size,
	)

	var/obj/item/organ/appearance_feature/existing_organ = get_organ_slot(organ_slot)
	if(!enabled)
		if(existing_organ)
			existing_organ.Remove(src, special = TRUE)
			qdel(existing_organ)
			update_body_parts()
		return

	if(!istype(existing_organ, organ_type))
		if(existing_organ)
			existing_organ.Remove(src, special = TRUE)
			qdel(existing_organ)
		existing_organ = new organ_type
		existing_organ.Insert(src, special = TRUE, movement_flags = DELETE_IF_REPLACED)

	existing_organ.set_preference_size(size)
	update_body_parts()
