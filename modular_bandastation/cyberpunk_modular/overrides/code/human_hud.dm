/datum/hud
	var/list/default_inventory_slots = null

/datum/hud/proc/update_inventory_slot(slot_id, ...)
	if(isnull(mymob))
		return
	if(slot_id == ITEM_SLOT_HANDS)
		var/held_index = length(args) >= 2 ? args[2] : null
		if(!isnull(held_index))
			var/atom/movable/screen/inventory/hand/held_location = hand_slots?[held_index]
			held_location?.update_appearance()
		return
	var/atom/movable/screen/inventory/inv = inv_slots?[TOBITSHIFT(slot_id) + 1]
	inv?.update_appearance()

/datum/hud/human
	inventory_slots = /datum/inventory_slot/human

/datum/hud/human/hidden_inventory_update(mob/viewer)
	if(!mymob)
		return
	var/mob/living/carbon/human/H = mymob

	var/mob/screenmob = viewer || H

	if(screenmob.hud_used.inventory_shown && screenmob.hud_used.hud_shown)
		if(H.shoes)
			H.shoes.screen_loc = ui_shoes
			screenmob.client.screen += H.shoes
		if(H.gloves)
			H.gloves.screen_loc = ui_gloves
			screenmob.client.screen += H.gloves
		if(H.ears)
			H.ears.screen_loc = ui_ears
			screenmob.client.screen += H.ears
		if(H.glasses)
			H.glasses.screen_loc = ui_glasses
			screenmob.client.screen += H.glasses
		if(H.w_uniform)
			H.w_uniform.screen_loc = ui_iclothing
			screenmob.client.screen += H.w_uniform
		if(H.wear_suit)
			H.wear_suit.screen_loc = ui_oclothing
			screenmob.client.screen += H.wear_suit
		if(H.wear_mask)
			H.wear_mask.screen_loc = ui_mask
			screenmob.client.screen += H.wear_mask
		if(H.wear_neck)
			H.wear_neck.screen_loc = ui_neck
			screenmob.client.screen += H.wear_neck
		if(H.head)
			H.head.screen_loc = ui_head
			screenmob.client.screen += H.head
		if(H.wear_undershirt)
			H.wear_undershirt.screen_loc = ui_undershirt
			screenmob.client.screen += H.wear_undershirt
		if(H.wear_underwear)
			H.wear_underwear.screen_loc = ui_underwear
			screenmob.client.screen += H.wear_underwear
		if(H.wear_tights)
			H.wear_tights.screen_loc = ui_tights
			screenmob.client.screen += H.wear_tights
		if(H.wear_shoulder_l)
			H.wear_shoulder_l.screen_loc = ui_shoulder_l
			screenmob.client.screen += H.wear_shoulder_l
		if(H.wear_shoulder_r)
			H.wear_shoulder_r.screen_loc = ui_shoulder_r
			screenmob.client.screen += H.wear_shoulder_r
		if(H.wear_finger)
			H.wear_finger.screen_loc = ui_finger
			screenmob.client.screen += H.wear_finger
		if(H.wear_bracers)
			H.wear_bracers.screen_loc = ui_bracers
			screenmob.client.screen += H.wear_bracers
		if(H.wear_pants)
			H.wear_pants.screen_loc = ui_pants
			screenmob.client.screen += H.wear_pants
		if(H.wear_chest)
			H.wear_chest.screen_loc = ui_chest
			screenmob.client.screen += H.wear_chest
	else
		if(H.shoes)
			screenmob.client.screen -= H.shoes
		if(H.gloves)
			screenmob.client.screen -= H.gloves
		if(H.ears)
			screenmob.client.screen -= H.ears
		if(H.glasses)
			screenmob.client.screen -= H.glasses
		if(H.w_uniform)
			screenmob.client.screen -= H.w_uniform
		if(H.wear_suit)
			screenmob.client.screen -= H.wear_suit
		if(H.wear_mask)
			screenmob.client.screen -= H.wear_mask
		if(H.wear_neck)
			screenmob.client.screen -= H.wear_neck
		if(H.head)
			screenmob.client.screen -= H.head
		if(H.wear_undershirt)
			screenmob.client.screen -= H.wear_undershirt
		if(H.wear_underwear)
			screenmob.client.screen -= H.wear_underwear
		if(H.wear_tights)
			screenmob.client.screen -= H.wear_tights
		if(H.wear_shoulder_l)
			screenmob.client.screen -= H.wear_shoulder_l
		if(H.wear_shoulder_r)
			screenmob.client.screen -= H.wear_shoulder_r
		if(H.wear_finger)
			screenmob.client.screen -= H.wear_finger
		if(H.wear_bracers)
			screenmob.client.screen -= H.wear_bracers
		if(H.wear_pants)
			screenmob.client.screen -= H.wear_pants
		if(H.wear_chest)
			screenmob.client.screen -= H.wear_chest

/datum/hud/human/persistent_inventory_update(mob/viewer)
	if(!mymob)
		return
	..()
	var/mob/living/carbon/human/H = mymob

	var/mob/screenmob = viewer || H

	if(screenmob.hud_used)
		if(screenmob.hud_used.hud_shown)
			if(H.s_store)
				H.s_store.screen_loc = ui_sstore1
				screenmob.client.screen += H.s_store
			if(H.wear_id)
				H.wear_id.screen_loc = ui_id
				screenmob.client.screen += H.wear_id
			if(H.belt)
				H.belt.screen_loc = ui_belt
				screenmob.client.screen += H.belt
			if(H.back)
				H.back.screen_loc = ui_back
				screenmob.client.screen += H.back
			if(H.l_store)
				H.l_store.screen_loc = ui_storage1
				screenmob.client.screen += H.l_store
			if(H.r_store)
				H.r_store.screen_loc = ui_storage2
				screenmob.client.screen += H.r_store
		else
			if(H.s_store)
				screenmob.client.screen -= H.s_store
			if(H.wear_id)
				screenmob.client.screen -= H.wear_id
			if(H.belt)
				screenmob.client.screen -= H.belt
			if(H.back)
				screenmob.client.screen -= H.back
			if(H.l_store)
				screenmob.client.screen -= H.l_store
			if(H.r_store)
				screenmob.client.screen -= H.r_store

	if(hud_version != HUD_STYLE_NOHUD)
		for(var/obj/item/I in H.held_items)
			I.screen_loc = ui_hand_position(H.get_held_index_of_item(I))
			screenmob.client.screen += I
	else
		for(var/obj/item/I in H.held_items)
			I.screen_loc = null
			screenmob.client.screen -= I

/datum/inventory_slot/human/undershirt
	name = "undershirt"
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = ui_undershirt
	slot_id = ITEM_SLOT_UNDERSHIRT
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/underwear
	name = "underwear"
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = ui_underwear
	slot_id = ITEM_SLOT_UNDERWEAR
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/tights
	name = "socks"
	icon_state = "shoes"
	icon_full = "template"
	screen_loc = ui_tights
	slot_id = ITEM_SLOT_TIGHTS
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/shoulder_left
	name = "left shoulder"
	icon_state = "back"
	icon_full = "template_small"
	screen_loc = ui_shoulder_l
	slot_id = ITEM_SLOT_SHOULDER_LEFT
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/shoulder_right
	name = "right shoulder"
	icon_state = "back"
	icon_full = "template_small"
	screen_loc = ui_shoulder_r
	slot_id = ITEM_SLOT_SHOULDER_RIGHT
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/finger
	name = "finger"
	icon_state = "gloves"
	icon_full = "template"
	screen_loc = ui_finger
	slot_id = ITEM_SLOT_FINGER
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/bracers
	name = "bracers"
	icon_state = "gloves"
	icon_full = "template"
	screen_loc = ui_bracers
	slot_id = ITEM_SLOT_BRACERS
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/pants
	name = "pants"
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = ui_pants
	slot_id = ITEM_SLOT_PANTS
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

/datum/inventory_slot/human/chest
	name = "chest"
	icon_state = "id"
	icon_full = "template_small"
	screen_loc = ui_chest
	slot_id = ITEM_SLOT_CHEST
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY
