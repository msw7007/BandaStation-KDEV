/datum/body_modification/implants
	name = "Implants"
	abstract_type = /datum/body_modification/implants
	modification_kind = "organ"
	chromity_cost = 5
	var/obj/item/organ/replacement_organ = null

/datum/body_modification/implants/New()
	. = ..()
	if(!replacement_organ)
		return

	var/replacement_slot = initial(replacement_organ.slot)
	var/replacement_zone = initial(replacement_organ.zone)
	if(isnull(slot_id))
		slot_id = replacement_slot
	if(isnull(body_zone))
		body_zone = replacement_zone
	if(isnull(body_part))
		body_part = body_zone_to_character_setup_part(body_zone)
	if(isnull(icon))
		icon = initial(replacement_organ.icon)
	if(isnull(icon_state))
		icon_state = initial(replacement_organ.icon_state)
	if(!chromity_cost)
		chromity_cost = max(1, initial(replacement_organ.chromity_overheat) || 5)

/datum/body_modification/implants/robotic
	name = "Robotic implants"
	abstract_type = /datum/body_modification/implants/robotic

/datum/body_modification/implants/apply_to_human(mob/living/carbon/target, additional_params)
	. = ..()
	if(!.)
		return

	var/obj/item/organ/organ_to_apply = new replacement_organ
	if(chromity_cost && organ_to_apply.chromity_overheat <= 0)
		organ_to_apply.chromity_overheat = chromity_cost
	organ_to_apply.replace_into(target)
	return TRUE

/datum/body_modification/implants/robotic/eyes
	abstract_type = /datum/body_modification/implants/robotic/eyes
	key = "robotic_eyes"
	name = "Робо-глаза"
	category = "Органы"
	replacement_organ = /obj/item/organ/eyes/robotic/basic

/datum/body_modification/implants/robotic/tongue
	key = "robotic_tongue"
	name = "Робо-язык"
	category = "Органы"
	replacement_organ = /obj/item/organ/tongue/robot

/datum/body_modification/implants/robotic/brain
	key = "cybernetic_brain"
	name = "Кибернетический мозг"
	category = "Органы"
	replacement_organ = /obj/item/organ/brain/cybernetic

/datum/body_modification/implants/robotic/ears
	key = "cybernetic_ears"
	name = "Кибернетические уши"
	category = "Органы"
	replacement_organ = /obj/item/organ/ears/cybernetic

/datum/body_modification/implants/robotic/liver
	key = "cybernetic_liver"
	name = "Кибернетическая печень"
	category = "Органы"
	replacement_organ = /obj/item/organ/liver/cybernetic

/datum/body_modification/implants/robotic/lungs
	key = "cybernetic_lungs"
	name = "Кибернетические лёгкие"
	category = "Органы"
	replacement_organ = /obj/item/organ/lungs/cybernetic

/datum/body_modification/implants/robotic/stomach
	key = "cybernetic_stomach"
	name = "Кибернетический желудок"
	category = "Органы"
	replacement_organ = /obj/item/organ/stomach/cybernetic

/datum/body_modification/implants/robotic/heart
	key = "cybernetic_heart"
	name = "Кибернетическое сердце"
	category = "Органы"
	replacement_organ = /obj/item/organ/heart/cybernetic

/datum/body_modification/dynamic_organ_replacement
	abstract_type = /datum/body_modification/dynamic_organ_replacement
	category = "Органы"
	modification_kind = "organ"
	var/obj/item/organ/replacement_organ = null
	var/replacement_description = null

/datum/body_modification/dynamic_organ_replacement/New(obj/item/organ/organ_type)
	abstract_type = null
	replacement_organ = organ_type
	slot_id = initial(organ_type.slot)
	body_zone = initial(organ_type.zone)
	body_part = body_zone_to_character_setup_part(body_zone)
	key = "organ_[slot_id]_[replacetext("[organ_type]", "/", "_")]"
	name = initial(organ_type.name)
	icon = initial(organ_type.icon)
	icon_state = initial(organ_type.icon_state)
	replacement_description = initial(organ_type.desc)
	chromity_cost = max(1, initial(organ_type.chromity_overheat) || 5)
	return ..()

/datum/body_modification/dynamic_organ_replacement/get_description()
	if(length(replacement_description))
		return replacement_description
	return ..()

/datum/body_modification/dynamic_organ_replacement/preference_value_valid(value)
	return islist(value)

/datum/body_modification/dynamic_organ_replacement/default_preference_value(params)
	return list()

/datum/body_modification/dynamic_organ_replacement/ui_params_valid(params)
	return TRUE

/datum/body_modification/dynamic_organ_replacement/handle_ui_params(params)
	return list()

/datum/body_modification/dynamic_organ_replacement/apply_to_human(mob/living/carbon/target, additional_params)
	. = ..()
	if(!.)
		return

	var/obj/item/organ/organ_to_apply = new replacement_organ
	if(chromity_cost && organ_to_apply.chromity_overheat <= 0)
		organ_to_apply.chromity_overheat = chromity_cost
	organ_to_apply.replace_into(target)
	return TRUE

/datum/body_modification/cybernetic_implant
	abstract_type = /datum/body_modification/cybernetic_implant
	category = "Импланты"
	modification_kind = "implant"
	var/obj/item/organ/cyberimp/implant_type = null
	var/implant_description = null

/datum/body_modification/cybernetic_implant/New(obj/item/organ/cyberimp/implant_type, target_slot, target_zone)
	abstract_type = null
	src.implant_type = implant_type
	slot_id = target_slot
	body_zone = target_zone
	body_part = body_zone_to_character_setup_part(body_zone)
	key = "cyberimp_[target_slot]_[replacetext("[implant_type]", "/", "_")]"
	name = initial(implant_type.name)
	icon = initial(implant_type.icon)
	icon_state = initial(implant_type.icon_state)
	implant_description = initial(implant_type.desc)
	grade = null
	tier = null
	chromity_cost = max(1, initial(implant_type.chromity_overheat) || 5)
	return ..()

/datum/body_modification/cybernetic_implant/get_description()
	var/description = implant_description
	if(length(description))
		return description
	return ..()

/datum/body_modification/cybernetic_implant/preference_value_valid(value)
	return islist(value)

/datum/body_modification/cybernetic_implant/default_preference_value(params)
	return list()

/datum/body_modification/cybernetic_implant/ui_params_valid(params)
	return TRUE

/datum/body_modification/cybernetic_implant/handle_ui_params(params)
	return list()

/datum/body_modification/cybernetic_implant/apply_to_human(mob/living/carbon/target, additional_params)
	. = ..()
	if(!.)
		return

	var/obj/item/organ/cyberimp/implant = new implant_type()
	implant.slot = slot_id
	implant.zone = body_zone
	implant.replace_into(target)
	return TRUE
