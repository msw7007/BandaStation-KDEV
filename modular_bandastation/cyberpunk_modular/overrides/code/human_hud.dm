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

/datum/inventory_slot/human/pants
	name = "pants"
	icon_state = "uniform"
	icon_full = "template"
	screen_loc = ui_pants
	slot_id = ITEM_SLOT_PANTS
	screen_group = HUD_GROUP_TOGGLEABLE_INVENTORY

#define CP13_HUD_GLYPHS 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/glyphs_16x16.dmi'
#define CP13_HUD_LARGE_GLYPHS 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/glyphs_32x32.dmi'
#define CP13_HUD_MOVEMENT 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/movement_32x16.dmi'
#define CP13_HUD_FRAME16 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_16x16.dmi'
#define CP13_HUD_FRAME32 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_32x32.dmi'
#define CP13_HUD_FRAME_WIDE 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_32x16.dmi'
#define CP13_HUD_STATUS 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_16x32.dmi'
#define CP13_HUD_FLOOR 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/floor_16x32.dmi'
#define CP13_HUD_HANDS 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/hands_32x32.dmi'
#define CP13_HUD_INVENTORY 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/inventory_32x32.dmi'
#define CP13_HUD_ACTION_FRAME 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_24x16.dmi'
#define CP13_HUD_STATUS_CARDS 'modular_bandastation/cyberpunk_modular/cyberpunk/icons/hud/cp13/frames_24x32.dmi'
#define CP13_HUD_CARD_WIDTH 24
#define CP13_HUD_CARD_GAP 2
#define CP13_HUD_STATUS_LIMIT 8

/datum/hud/human
	var/cp13_underwear_shown = FALSE
	var/datum/emote_panel/cp13_emote_panel
	/// Real alerts mapped to their owned compact cards; no empty placeholders.
	var/list/cp13_status_cards = list()

/atom/movable/screen
	var/cp13_frame_file
	var/cp13_frame_state
	var/cp13_frame_hovered = FALSE
	var/atom/movable/screen/cp13_button_frame/cp13_frame

/atom/movable/screen/Destroy()
	QDEL_NULL(cp13_frame)
	return ..()

/atom/movable/screen/cp13_button_frame
	name = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/cp13_button_frame/Destroy()
	get_mob()?.canon_client?.screen -= src
	invisibility = INVISIBILITY_ABSTRACT
	return ..()

/datum/hud/human/Destroy()
	QDEL_NULL(cp13_emote_panel)
	for(var/key in cp13_status_cards.Copy())
		qdel(cp13_status_cards[key])
	cp13_status_cards = null
	return ..()

/atom/movable/screen/proc/cp13_set_art(icon_file, state, frame_file = CP13_HUD_FRAME16, frame_state = "idle")
	// `in` binds below assignment in DM; without parentheses every resource is truthy.
	var/is_frame = (icon_file in list(CP13_HUD_FRAME16, CP13_HUD_FRAME32, CP13_HUD_FRAME_WIDE, CP13_HUD_STATUS))
	icon = icon_file
	icon_state = state
	if(is_frame)
		// Tint the frame, not maptext or the equipped item in vis_contents.
		icon = null
		frame_file = icon_file
		frame_state = state
	color = null
	cp13_frame_file = frame_file
	cp13_frame_state = frame_state
	if(!is_frame && mouse_opacity != MOUSE_OPACITY_TRANSPARENT)
		mouse_opacity = MOUSE_OPACITY_OPAQUE
	cp13_refresh_frame()

/atom/movable/screen/proc/cp13_refresh_frame()
	underlays = null
	if(!cp13_frame_file)
		QDEL_NULL(cp13_frame)
		return
	var/state = cp13_frame_state
	if(cp13_frame_hovered && state in list("idle", "outline", "grid"))
		state = "hover"
	if(isnull(icon))
		QDEL_NULL(cp13_frame)
		underlays = list(mutable_appearance(cp13_frame_file, state, appearance_flags = APPEARANCE_UI))
		return
	// Frame-only screen objects render independently of the glyph's appearance.
	// Defer during Initialize: the factory has not assigned the HUD group yet.
	if(!hud || !hud_group_key)
		return
	if(!cp13_frame)
		cp13_frame = hud.add_screen_object(/atom/movable/screen/cp13_button_frame, "cp13_frame:[REF(src)]", hud_group_key)
	else if(cp13_frame.hud_group_key != hud_group_key)
		hud.screen_groups?[cp13_frame.hud_group_key] -= cp13_frame
		LAZYOR(hud.screen_groups[hud_group_key], cp13_frame)
		cp13_frame.hud_group_key = hud_group_key
	cp13_frame.icon = cp13_frame_file
	cp13_frame.icon_state = state
	cp13_frame.screen_loc = screen_loc
	cp13_frame.plane = plane
	cp13_frame.layer = layer - 0.01
	cp13_frame.invisibility = invisibility

/atom/movable/screen/MouseEntered(location, control, params)
	. = ..()
	if(cp13_frame_file && mouse_opacity != MOUSE_OPACITY_TRANSPARENT && usr == get_mob())
		cp13_frame_hovered = TRUE
		cp13_refresh_frame()

/atom/movable/screen/MouseExited(location, control, params)
	. = ..()
	if(cp13_frame_hovered)
		cp13_frame_hovered = FALSE
		cp13_refresh_frame()

// Apply after the shared factory assigns ui_style, including late-created controls.
/datum/hud/human/add_screen_object(atom/movable/screen/new_object, hud_key, group_key = HUD_GROUP_STATIC, ui_icon, ui_loc, update_screen = FALSE)
	if(new_object == /atom/movable/screen/inventory)
		new_object = /atom/movable/screen/inventory/cp13
	else if(new_object == /atom/movable/screen/inventory/hand)
		new_object = /atom/movable/screen/inventory/hand/cp13
	else if(hud_key == HUD_MOB_PALETTE_UP)
		new_object = /atom/movable/screen/palette_scroll/cp13/up
	else if(hud_key == HUD_MOB_PALETTE_DOWN)
		new_object = /atom/movable/screen/palette_scroll/cp13/down
	else if(hud_key == HUD_MOB_TOGGLE_PALETTE)
		new_object = /atom/movable/screen/button_palette/cp13
	else if(hud_key == HUD_MOB_INTENTS)
		new_object = /atom/movable/screen/combattoggle/cp13
	else if(hud_key == HUD_MOB_MEMORIES)
		new_object = /atom/movable/screen/memories/cp13
	// Publish only after the glyph and its frame have both been registered.
	. = ..(new_object, hud_key, group_key, ui_icon, ui_loc, FALSE)
	var/atom/movable/screen/button = .
	switch(hud_key)
		if(HUD_MOB_LANGUAGE_MENU)
			button.cp13_set_art(CP13_HUD_GLYPHS, "language")
			button.screen_loc = "EAST:10,SOUTH+2:21"
		if(HUD_MOB_CRAFTING_MENU)
			button.cp13_set_art(CP13_HUD_GLYPHS, "craft")
			button.screen_loc = "EAST:10,SOUTH+2:5"
		if(HUD_MOB_NAVIGATE_MENU)
			button.cp13_set_art(CP13_HUD_GLYPHS, "navigate")
			button.screen_loc = "EAST:10,SOUTH:21"
		if(HUD_MOB_AREA_CREATOR)
			button.cp13_set_art(CP13_HUD_GLYPHS, "area_create")
			button.screen_loc = "EAST:10,SOUTH:5"
		if(HUD_MOB_THROW)
			button.cp13_set_art(CP13_HUD_GLYPHS, mymob.throw_mode ? "act_throw_on" : "act_throw")
		if(HUD_MOB_FLOOR_CHANGER)
			button.cp13_set_art(CP13_HUD_FLOOR, "floor_change_v", CP13_HUD_STATUS, "split")
		if(HUD_MOB_MEMORIES)
			button.cp13_set_art(CP13_HUD_GLYPHS, "memories")
		if(HUD_MOB_RESIST)
			button.cp13_set_art(CP13_HUD_GLYPHS, "resist")
		if(HUD_MOB_SLEEP)
			button.cp13_set_art(CP13_HUD_GLYPHS, "sleep")
			button.maptext_width = 16
			button.maptext_height = 16
		if(HUD_MOB_MOVE_INTENT, HUD_MOB_REST)
			button.update_appearance()
		if(HUD_MOB_MOOD)
			button.screen_loc = "EAST:2,SOUTH+3:5"
		if(HUD_MOB_INTENTS)
			button.update_appearance()
	if(button.cp13_frame_file)
		button.cp13_refresh_frame()
	if(update_screen)
		show_hud(hud_version)

/datum/hud/human/initialize_screen_objects()
	. = ..()
	remove_screen_object(HUD_HUMAN_TOGGLE_INVENTORY, update = FALSE)
	add_screen_object(/atom/movable/screen/human/toggle/cp13, HUD_HUMAN_TOGGLE_INVENTORY, HUD_GROUP_STATIC)
	remove_screen_object(HUD_MOB_DROP, update = FALSE)
	add_screen_object(/atom/movable/screen/drop/cp13, HUD_MOB_DROP, HUD_GROUP_STATIC)
	remove_screen_object(HUD_MOB_PULL, update = FALSE)
	add_screen_object(/atom/movable/screen/cp13_emotes, "cp13_emotes", HUD_GROUP_STATIC)
	add_screen_object(/atom/movable/screen/cp13_underwear, "cp13_underwear", HUD_GROUP_TOGGLEABLE_INVENTORY)
	add_screen_object(/atom/movable/screen/cp13_accessories, "cp13_accessories", HUD_GROUP_TOGGLEABLE_INVENTORY)
	cp13_position_controls()

/datum/hud/human/build_hand_slots(update_hud = FALSE)
	. = ..()
	cp13_position_controls()

/datum/hud/human/proc/cp13_position_controls()
	var/list/positions = list(
		HUD_MOB_REST = "WEST+1:6,SOUTH:21",
		HUD_MOB_MOVE_INTENT = "WEST+1:6,SOUTH:5",
		HUD_MOB_FLOOR_CHANGER = "WEST+2:6,SOUTH:5",
		HUD_MOB_THROW = "CENTER-1:16,SOUTH+1:5",
		HUD_MOB_SWAPHAND_2 = "CENTER-1:0,SOUTH+1:5",
		HUD_MOB_INTENTS = "CENTER:0,SOUTH+1:5",
		HUD_MOB_DROP = "CENTER+1:0,SOUTH+1:5",
		HUD_MOB_RESIST = "CENTER+1:16,SOUTH+1:5",
		HUD_MOB_MEMORIES = "EAST:10,SOUTH+1:21",
		HUD_MOB_SLEEP = "CENTER:0,SOUTH+1:23",
		HUD_MOB_LANGUAGE_MENU = "EAST:10,SOUTH+2:21",
		HUD_MOB_CRAFTING_MENU = "EAST:10,SOUTH+2:5",
		HUD_MOB_NAVIGATE_MENU = "EAST:10,SOUTH:21",
		HUD_MOB_AREA_CREATOR = "EAST:10,SOUTH:5",
		HUD_MOB_HEALTHDOLL = "EAST-1:2,SOUTH+1:21",
		HUD_MOB_ZONE_SELECTOR = "EAST-1:2,SOUTH:5",
		HUD_MOB_HEALTH = "EAST-1:2,SOUTH+3:5",
		HUD_MOB_STAMINA = "EAST-1:2,SOUTH+2:21",
		HUD_MOB_MOOD = "EAST:2,SOUTH+3:5",
		HUD_MOB_SPACESUIT = "EAST-2:0,SOUTH+3:5",
		HUD_MOB_HUNGER = "EAST-2:0,SOUTH+2:5",
	)
	for(var/key in positions)
		var/atom/movable/screen/button = screen_objects[key]
		if(button)
			button.screen_loc = positions[key]
	var/atom/movable/screen/combattoggle/combat = screen_objects[HUD_MOB_INTENTS]
	if(combat)
		combat.default_screen_location = combat.screen_loc
		combat.update_appearance()
	var/atom/movable/screen/palette = screen_objects[HUD_MOB_TOGGLE_PALETTE]
	if(palette)
		palette.screen_loc = null
	var/atom/movable/screen/swap = screen_objects[HUD_MOB_SWAPHAND_2]
	if(swap)
		swap.cp13_set_art(CP13_HUD_GLYPHS, "swap")
		swap.maptext = ""
	for(var/key in screen_objects.Copy())
		var/atom/movable/screen/control = screen_objects[key]
		if(control.cp13_frame_file)
			control.cp13_refresh_frame()

/datum/hud/human/create_inventory_slots()
	. = ..()
	var/list/positions = list(
		"[ITEM_SLOT_EYES]" = list("WEST:6,SOUTH+6:5", "glasses"),
		"[ITEM_SLOT_HEAD]" = list("WEST+1:6,SOUTH+6:5", "head"),
		"[ITEM_SLOT_EARS]" = list("WEST+2:6,SOUTH+6:5", "ears"),
		"[ITEM_SLOT_MASK]" = list("WEST:6,SOUTH+5:5", "mask"),
		"[ITEM_SLOT_OCLOTHING]" = list("WEST+1:6,SOUTH+5:5", "suit"),
		"[ITEM_SLOT_NECK]" = list("WEST+2:6,SOUTH+5:5", "neck"),
		"[ITEM_SLOT_SHOULDER_RIGHT]" = list("WEST:6,SOUTH+4:5", "shoulder_right"),
		"[ITEM_SLOT_ICLOTHING]" = list("WEST+1:6,SOUTH+4:5", "uniform"),
		"[ITEM_SLOT_SHOULDER_LEFT]" = list("WEST+2:6,SOUTH+4:5", "shoulder_left"),
		"[ITEM_SLOT_GLOVES]" = list("WEST:6,SOUTH+3:5", "gloves"),
		"[ITEM_SLOT_BELT]" = list("WEST+1:6,SOUTH+3:5", "belt"),
		"[ITEM_SLOT_PANTS]" = list("WEST:6,SOUTH+2:5", "pants"),
		"[ITEM_SLOT_FEET]" = list("WEST+1:6,SOUTH+2:5", "shoes"),
		"[ITEM_SLOT_UNDERSHIRT]" = list("WEST+3:6,SOUTH+4:5", "undershirt"),
		"[ITEM_SLOT_UNDERWEAR]" = list("WEST+3:6,SOUTH+3:5", "underwear"),
		"[ITEM_SLOT_TIGHTS]" = list("WEST+3:6,SOUTH+2:5", "tights"),
		"[ITEM_SLOT_LPOCKET]" = list("CENTER-2:16,SOUTH:5", "pocket"),
		"[ITEM_SLOT_RPOCKET]" = list("CENTER+1:16,SOUTH:5", "pocket"),
		"[ITEM_SLOT_BACK]" = list("WEST:6,SOUTH+7:5", "back"),
		"[ITEM_SLOT_ID]" = list("WEST+1:6,SOUTH+7:5", "id"),
		"[ITEM_SLOT_SUITSTORE]" = list("WEST+2:6,SOUTH+7:5", "suit_storage"),
	)
	for(var/slot_key in positions)
		var/atom/movable/screen/inventory/slot = screen_objects[HUD_KEY_ITEM_SLOT(text2num(slot_key))]
		if(!slot)
			continue
		if(slot.slot_id in list(ITEM_SLOT_BACK, ITEM_SLOT_ID, ITEM_SLOT_SUITSTORE))
			screen_groups[slot.hud_group_key] -= slot
			screen_groups[HUD_GROUP_TOGGLEABLE_INVENTORY] |= slot
			slot.hud_group_key = HUD_GROUP_TOGGLEABLE_INVENTORY
		var/list/slot_settings = positions[slot_key]
		slot.icon = CP13_HUD_INVENTORY
		slot.icon_empty = slot_settings[2]
		slot.icon_full = "occupied"
		slot.screen_loc = slot_settings[1]
		slot.update_appearance()

/datum/hud/human/show_hud(version = 0, mob/viewmob)
	. = ..()
	if(.)
		cp13_position_controls()
		cp13_refresh_underwear(viewmob || mymob)
		if(hud_version == HUD_STYLE_REDUCED)
			var/mob/viewer = viewmob || mymob
			for(var/index in 1 to length(mymob.held_items))
				var/atom/movable/screen/hand = screen_objects[HUD_KEY_HAND_SLOT(index)]
				if(hand?.cp13_frame)
					viewer.client.screen |= hand.cp13_frame

/datum/hud/human/proc/cp13_refresh_underwear(mob/viewer)
	if(!viewer?.client)
		return
	for(var/slot_id in list(ITEM_SLOT_UNDERSHIRT, ITEM_SLOT_UNDERWEAR, ITEM_SLOT_TIGHTS))
		var/atom/movable/screen/slot = screen_objects[HUD_KEY_ITEM_SLOT(slot_id)]
		if(hud_version == HUD_STYLE_STANDARD && inventory_shown && cp13_underwear_shown)
			viewer.client.screen |= slot
			if(slot?.cp13_frame)
				viewer.client.screen |= slot.cp13_frame
		else
			viewer.client.screen -= slot
			if(slot?.cp13_frame)
				viewer.client.screen -= slot.cp13_frame

/datum/hud/human/build_action_groups()
	listed_actions = new /datum/action_group/listed/cp13(src)
	palette_actions = new /datum/action_group/palette/cp13(src)
	floating_actions = list()
	for(var/datum/action/action as anything in mymob.actions)
		var/atom/movable/screen/movable/action_button/button = action.viewers[src]
		if(!button)
			action.ShowTo(mymob)
		else
			position_action(button, button.location)
	listed_actions.refresh_actions()

/datum/hud/human/proc/cp13_action_location(index)
	if(index < 1 || index > 8)
		return null
	var/column = (index - 1) % 2
	var/row = round(((index - 1) % 4) / 2)
	var/stride = CP13_HUD_CARD_WIDTH + CP13_HUD_CARD_GAP
	var/offset_x = index <= 4 ? -48 - 2 * stride : 80 + CP13_HUD_CARD_GAP
	return "CENTER:[offset_x + column * stride],SOUTH:[5 + row * (16 + CP13_HUD_CARD_GAP)]"

/datum/hud/human/position_action(atom/movable/screen/movable/action_button/button, position)
	. = ..()
	button?.cp13_fit()

/datum/hud/human/get_action_buttons_icons()
	. = ..()
	.["bg_icon"] = CP13_HUD_FRAME32
	.["bg_state"] = "idle"
	.["bg_state_active"] = "active"

/datum/hud/human/get_ui_alert_placement(index)
	. = ..()
	if(.)
		return "EAST-[index]:28,NORTH-2:5"

/// Presentation-only classification. Neutral/unknown alerts retain native placement.
/datum/hud/human/proc/cp13_status_kind(atom/movable/screen/alert/alert)
	var/static/list/buff_types = typecacheof(list(
		/atom/movable/screen/alert/status_effect/his_grace,
		/atom/movable/screen/alert/status_effect/wish_granters_gift,
		/atom/movable/screen/alert/status_effect/blooddrunk,
		/atom/movable/screen/alert/status_effect/fleshmend,
		/atom/movable/screen/alert/status_effect/exercised,
		/atom/movable/screen/alert/status_effect/regenerative_core,
		/atom/movable/screen/alert/status_effect/lightningorb,
		/atom/movable/screen/alert/status_effect/nest_sustenance,
		/atom/movable/screen/alert/status_effect/radiation_immunity,
		/atom/movable/screen/alert/status_effect/shadow_regeneration,
		/atom/movable/screen/alert/status_effect/temporary_xray,
		/atom/movable/screen/alert/status_effect/food,
		/atom/movable/screen/alert/status_effect/shockimmune,
		/atom/movable/screen/alert/status_effect/ashstorm_immune,
		/atom/movable/screen/alert/status_effect/determined,
	))
	var/static/list/debuff_types = typecacheof(list(
		/atom/movable/screen/alert/status_effect/cursed,
		/atom/movable/screen/alert/status_effect/decloning,
		/atom/movable/screen/alert/status_effect/asleep,
		/atom/movable/screen/alert/status_effect/stasis,
		/atom/movable/screen/alert/status_effect/his_wrath,
		/atom/movable/screen/alert/status_effect/trance,
		/atom/movable/screen/alert/status_effect/convulsing,
		/atom/movable/screen/alert/status_effect/dna_melt,
		/atom/movable/screen/alert/status_effect/go_away,
		/atom/movable/screen/alert/status_effect/ants,
		/atom/movable/screen/alert/status_effect/freezing_blast,
		/atom/movable/screen/alert/status_effect/discoordinated,
		/atom/movable/screen/alert/status_effect/midas_blight,
		/atom/movable/screen/alert/status_effect/designated_target,
		/atom/movable/screen/alert/status_effect/drunk,
		/atom/movable/screen/alert/status_effect/high,
		/atom/movable/screen/alert/status_effect/hooked,
		/atom/movable/screen/alert/status_effect/gravity_sickness,
		/atom/movable/screen/alert/status_effect/blind,
		/atom/movable/screen/alert/status_effect/tower_of_babel,
		/atom/movable/screen/alert/status_effect/slime_leech,
		/atom/movable/screen/alert/status_effect/terrified,
		/atom/movable/screen/alert/status_effect/slimed,
		/atom/movable/screen/alert/status_effect/strandling,
		/atom/movable/screen/alert/status_effect/woozy,
		/atom/movable/screen/alert/status_effect/high_blood_pressure,
		/atom/movable/screen/alert/status_effect/seizure,
		/atom/movable/screen/alert/status_effect/stoned,
		/atom/movable/screen/alert/status_effect/limp,
		/atom/movable/screen/alert/status_effect/mute,
	))
	if(is_type_in_typecache(alert, buff_types))
		return "buff"
	if(is_type_in_typecache(alert, debuff_types))
		return "debuff"
	return null

/datum/hud/human/proc/cp13_status_location(kind, index)
	if(index < 1 || index > CP13_HUD_STATUS_LIMIT)
		return null
	var/offset = (index - 1) * (CP13_HUD_CARD_WIDTH + CP13_HUD_CARD_GAP)
	return kind == "buff" ? "WEST:[6 + offset],NORTH:0" : "EAST:[32 - 6 - CP13_HUD_CARD_WIDTH - offset],NORTH:0"

/// Synchronize on native alert events/show_hud, never on a processing loop.
/datum/hud/human/proc/cp13_sync_status_cards()
	if(QDELING(src) || !mymob)
		return
	var/list/counts = list("buff" = 0, "debuff" = 0)
	var/list/seen = list()
	for(var/category in mymob.alerts)
		var/atom/movable/screen/alert/alert = mymob.alerts[category]
		if(QDELETED(alert))
			continue
		var/kind = cp13_status_kind(alert)
		if(!kind || counts[kind] >= CP13_HUD_STATUS_LIMIT)
			continue
		counts[kind] += 1
		var/key = REF(alert)
		seen += key
		var/atom/movable/screen/cp13_status_card/card = cp13_status_cards[key]
		if(!card)
			card = add_screen_object(/atom/movable/screen/cp13_status_card, "cp13_status:[key]", HUD_GROUP_INFO)
			cp13_status_cards[key] = card
			card.bind_alert(alert)
		card.icon_state = kind
		card.screen_loc = cp13_status_location(kind, counts[kind])
		card.update_appearance()
	for(var/key in cp13_status_cards.Copy())
		if(!(key in seen))
			qdel(cp13_status_cards[key])

/datum/hud/human/reorganize_alerts(mob/viewmob)
	cp13_sync_status_cards()
	. = ..()
	var/mob/viewer = viewmob || mymob
	if(!viewer?.client)
		return
	var/regular_index = 0
	for(var/category in mymob.alerts)
		var/atom/movable/screen/alert/alert = mymob.alerts[category]
		var/atom/movable/screen/cp13_status_card/card = cp13_status_cards[REF(alert)]
		if(card)
			viewer.client.screen -= alert
			if(hud_version == HUD_STYLE_STANDARD)
				viewer.client.screen |= card
			else
				viewer.client.screen -= card
		else
			// Neutral alerts and overflow keep native behavior without gaps.
			alert.screen_loc = get_ui_alert_placement(++regular_index)

/atom/movable/screen/cp13_status_card
	icon = CP13_HUD_STATUS_CARDS
	icon_state = "buff"
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	var/datum/weakref/alert_ref
	var/source_key

/atom/movable/screen/cp13_status_card/proc/bind_alert(atom/movable/screen/alert/alert)
	alert_ref = WEAKREF(alert)
	source_key = REF(alert)
	RegisterSignal(alert, COMSIG_QDELETING, PROC_REF(on_alert_deleted))
	RegisterSignal(alert, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_alert_updated))

/atom/movable/screen/cp13_status_card/Destroy()
	var/atom/movable/screen/alert/alert = alert_ref?.resolve()
	if(alert)
		UnregisterSignal(alert, list(COMSIG_QDELETING, COMSIG_ATOM_UPDATED_ICON))
	var/datum/hud/human/owner_hud = hud
	owner_hud?.cp13_status_cards -= source_key
	var/mob/owner = owner_hud?.mymob
	owner?.client?.screen -= src
	for(var/mob/viewer as anything in owner?.observers)
		viewer.client?.screen -= src
	alert_ref = null
	source_key = null
	return ..()

/atom/movable/screen/cp13_status_card/proc/on_alert_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/atom/movable/screen/cp13_status_card/proc/on_alert_updated(datum/source)
	SIGNAL_HANDLER
	update_appearance()

/atom/movable/screen/cp13_status_card/update_overlays()
	. = ..()
	var/atom/movable/screen/alert/alert = alert_ref?.resolve()
	if(!alert)
		return
	var/mutable_appearance/glyph
	if(alert.overlay_state)
		glyph = mutable_appearance(alert.overlay_icon, alert.overlay_state)
	else
		glyph = new(alert)
		glyph.underlays = null
	glyph.maptext = ""
	glyph.appearance_flags = APPEARANCE_UI|KEEP_TOGETHER
	glyph.layer = FLOAT_LAYER
	glyph.plane = FLOAT_PLANE
	var/list/dimensions = get_icon_dimensions(glyph.icon)
	var/width = dimensions["width"] || 32
	var/height = dimensions["height"] || 32
	var/scale = min(20 / width, 24 / height)
	glyph.pixel_x = 0
	glyph.pixel_y = 0
	glyph.transform = matrix(scale, 0, (CP13_HUD_CARD_WIDTH - width) / 2, 0, scale, (32 - height) / 2)
	. += glyph

/atom/movable/screen/cp13_status_card/MouseEntered(location, control, params)
	. = ..()
	var/atom/movable/screen/alert/status_effect/alert = alert_ref?.resolve()
	if(!alert)
		return
	var/details = alert.desc
	if(alert.attached_effect?.duration > 0)
		details += "<br>Осталось: [round(alert.attached_effect.duration / 10, 1)] с."
	openToolTip(usr, src, params, title = alert.name, content = details, theme = alert.alerttooltipstyle)

/atom/movable/screen/cp13_status_card/MouseExited()
	closeToolTip(usr)

/atom/movable/screen/cp13_status_card/Click(location, control, params)
	. = ..()
	if(usr == get_mob())
		var/atom/movable/screen/alert/alert = alert_ref?.resolve()
		alert?.Click(location, control, params)

/atom/movable/screen/inventory/cp13/update_icon_state()
	. = ..()
	if(icon_full == "occupied")
		cp13_set_art(CP13_HUD_INVENTORY, icon_state, CP13_HUD_FRAME32)

/atom/movable/screen/inventory/hand/cp13/update_icon_state()
	. = ..()
	if(held_index)
		var/mob/owner = get_mob()
		cp13_set_art(CP13_HUD_HANDS, "hand_[owner.held_index_to_dir(held_index)]", CP13_HUD_FRAME32, owner.active_hand_index == held_index ? "active" : "idle")

/atom/movable/screen/inventory/hand/cp13/update_overlays()
	. = ..()
	if(held_index && cp13_frame_file)
		var/mob/owner = get_mob()
		cp13_frame_state = owner.active_hand_index == held_index ? "active" : "idle"
		cp13_refresh_frame()

/atom/movable/screen/combattoggle/cp13
	icon = CP13_HUD_MOVEMENT
	icon_state = "fight"

/atom/movable/screen/combattoggle/cp13/update_icon_state()
	. = ..()
	var/mob/living/owner = get_mob()
	cp13_set_art(CP13_HUD_MOVEMENT, owner?.combat_mode ? "fight_active" : "fight", CP13_HUD_FRAME_WIDE, owner?.combat_mode ? "combat" : "idle")
	maptext = ""

/atom/movable/screen/memories/cp13
	desc = "Right-click to show or hide abilities."

/atom/movable/screen/memories/cp13/Click(location, control, params)
	if(usr != get_mob())
		return
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		var/datum/hud/human/owner_hud = hud
		var/atom/movable/screen/button_palette/palette = owner_hud.screen_objects[HUD_MOB_TOGGLE_PALETTE]
		palette.set_expanded(!palette.expanded)
		return
	return ..()

/atom/movable/screen/human/toggle/cp13
	name = "Equipment"
	screen_loc = "WEST:6,SOUTH:5"
	maptext_width = 32
	maptext_height = 32

/atom/movable/screen/human/toggle/cp13/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_appearance()

/atom/movable/screen/human/toggle/cp13/update_icon_state()
	. = ..()
	cp13_set_art(CP13_HUD_LARGE_GLYPHS, "equipment", CP13_HUD_FRAME32, hud?.inventory_shown ? "active" : "idle")

/atom/movable/screen/human/toggle/cp13/Click(location, control, params)
	. = ..()
	var/datum/hud/human/owner_hud = hud
	owner_hud?.cp13_refresh_underwear(usr)

/atom/movable/screen/cp13_underwear
	name = "Underwear"
	icon = CP13_HUD_FRAME32
	icon_state = "idle"
	screen_loc = "WEST+2:6,SOUTH+2:5"
	maptext_width = 32
	maptext_height = 32
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/cp13_underwear/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	cp13_set_art(CP13_HUD_LARGE_GLYPHS, "underwear", CP13_HUD_FRAME32)

/atom/movable/screen/cp13_underwear/Click(location, control, params)
	var/datum/hud/human/owner_hud = hud
	if(!istype(owner_hud) || usr != owner_hud.mymob)
		return
	owner_hud.cp13_underwear_shown = !owner_hud.cp13_underwear_shown
	cp13_set_art(CP13_HUD_LARGE_GLYPHS, "underwear", CP13_HUD_FRAME32, owner_hud.cp13_underwear_shown ? "active" : "idle")
	owner_hud.cp13_refresh_underwear(usr)

/atom/movable/screen/cp13_accessories
	name = "Hand accessories"
	icon = CP13_HUD_FRAME32
	icon_state = "idle"
	screen_loc = "WEST+2:6,SOUTH+3:5"
	maptext_width = 32
	maptext_height = 32
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/cp13_accessories/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	cp13_set_art(CP13_HUD_LARGE_GLYPHS, "accessories", CP13_HUD_FRAME32)

/atom/movable/screen/cp13_accessories/Click(location, control, params)
	var/mob/living/carbon/human/owner = get_mob()
	if(usr != owner || !istype(owner) || owner.incapacitated)
		return
	if(owner.gloves)
		owner.gloves.show_cyberpunk_modular_radial(owner)

/atom/movable/screen/drop/cp13
	icon = CP13_HUD_GLYPHS
	icon_state = "drop"

/atom/movable/screen/drop/cp13/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	cp13_set_art(CP13_HUD_GLYPHS, "drop")

/atom/movable/screen/drop/cp13/Click(location, control, params)
	if(usr != get_mob() || usr.stat != CONSCIOUS)
		return
	var/list/modifiers = params2list(params)
	if(usr.pulling && (!usr.get_active_held_item() || LAZYACCESS(modifiers, RIGHT_CLICK)))
		usr.stop_pulling()
		return
	return ..()

/atom/movable/screen/mov_intent/update_icon_state()
	. = ..()
	var/mob/living/carbon/human/owner = get_mob()
	if(!istype(owner))
		return
	var/body = owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL) ? "anthro" : "human"
	cp13_set_art(CP13_HUD_MOVEMENT, "[owner.move_intent == MOVE_INTENT_RUN ? "run" : "walk"]_[body]", CP13_HUD_FRAME_WIDE)

/atom/movable/screen/rest/update_icon_state()
	. = ..()
	var/mob/living/carbon/human/owner = get_mob()
	if(!istype(owner))
		return
	var/body = owner.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL) ? "anthro" : "human"
	cp13_set_art(CP13_HUD_MOVEMENT, "rest_[body]", CP13_HUD_FRAME_WIDE, owner.resting ? "active" : "idle")

/atom/movable/screen/cp13_emotes
	name = "Emotes"
	icon = CP13_HUD_GLYPHS
	icon_state = "emote"
	screen_loc = "EAST:10,SOUTH+1:5"
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/cp13_emotes/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	cp13_set_art(CP13_HUD_GLYPHS, "emote")

/atom/movable/screen/cp13_emotes/Click(location, control, params)
	var/datum/hud/human/owner_hud = hud
	if(!istype(owner_hud) || usr != owner_hud.mymob)
		return
	owner_hud.cp13_emote_panel ||= new
	owner_hud.cp13_emote_panel.ui_interact(usr)

/atom/movable/screen/movable/action_button
	var/cp13_signal_registered = FALSE
	var/cp13_hovered = FALSE
	var/cp13_scale = 0.5
	var/cp13_content_width = 32
	var/cp13_content_height = 32

/atom/movable/screen/movable/action_button/Destroy()
	if(cp13_signal_registered && linked_action)
		UnregisterSignal(linked_action, COMSIG_ACTION_OVERLAY_APPLY)
	return ..()

/atom/movable/screen/movable/action_button/proc/cp13_fit()
	if(!linked_action)
		return
	if(!cp13_signal_registered)
		RegisterSignal(linked_action, COMSIG_ACTION_OVERLAY_APPLY, PROC_REF(cp13_action_updated))
		cp13_signal_registered = TRUE
	var/list/dimensions = icon ? get_icon_dimensions(icon) : list("width" = 32, "height" = 32)
	var/base_width = dimensions["width"] || 32
	var/base_height = dimensions["height"] || 32
	cp13_content_width = base_width
	cp13_content_height = base_height
	// Item actions put the target appearance in an overlay, not in button.icon.
	if(isnull(linked_action.button_icon_state) && isatom(linked_action.target))
		var/atom/target_atom = linked_action.target
		if(target_atom.icon)
			var/list/target_size = get_icon_dimensions(target_atom.icon)
			cp13_content_width = max(cp13_content_width, target_size["width"])
			cp13_content_height = max(cp13_content_height, target_size["height"])
	cp13_scale = 16 / max(cp13_content_width, cp13_content_height)
	// Item overlays may carry RESET_TRANSFORM: compose them before fitting the button.
	appearance_flags |= KEEP_TOGETHER
	var/offset_x = (CP13_HUD_CARD_WIDTH - base_width - (cp13_content_width - base_width) * cp13_scale) / 2
	var/offset_y = (16 - base_height - (cp13_content_height - base_height) * cp13_scale) / 2
	// Screen objects ignore pixel_x/y. Translate around the source center in the matrix.
	transform = matrix(cp13_scale, 0, offset_x, 0, cp13_scale, offset_y)
	pixel_x = 0
	pixel_y = 0
	cp13_action_frame()

/atom/movable/screen/movable/action_button/proc/cp13_action_updated(datum/source, atom/movable/screen/movable/action_button/button, force)
	SIGNAL_HANDLER
	if(button == src)
		cp13_fit()

/atom/movable/screen/movable/action_button/proc/cp13_action_frame()
	var/state = linked_action?.is_action_active(src) ? "active" : (cp13_hovered ? "hover" : "idle")
	var/image/frame = image(icon = CP13_HUD_ACTION_FRAME, icon_state = state, layer = layer - 0.01)
	frame.plane = plane
	frame.appearance_flags = APPEARANCE_UI|KEEP_APART
	// RESET_TRANSFORM keeps both scale and centering translation off the frame.
	underlays = list(frame)

/atom/movable/screen/movable/action_button/MouseEntered(location, control, params)
	. = ..()
	if(cp13_signal_registered)
		cp13_hovered = TRUE
		cp13_action_frame()

/atom/movable/screen/movable/action_button/MouseExited(location, control, params)
	. = ..()
	if(cp13_signal_registered)
		cp13_hovered = FALSE
		cp13_action_frame()

/datum/action_group/listed/cp13
	column_max = 8
	max_rows = 1

/datum/action_group/listed/cp13/ButtonNumberToScreenCoords(number, landing = FALSE)
	var/datum/hud/human/owner_hud = owner
	if(number < 8)
		return owner_hud.cp13_action_location(number + 1)
	var/datum/action_group/palette/cp13/overflow = owner.palette_actions
	return overflow?.cp13_overflow_location(number - 8)

/datum/action_group/listed/cp13/refresh_actions()
	if(!owner || QDELING(owner))
		return
	. = ..()
	for(var/atom/movable/screen/movable/action_button/button as anything in actions)
		button.cp13_fit()
	if(landing)
		landing.transform = matrix(0.5, 0, -4, 0, 0.5, -8)
		landing.pixel_x = 0
		landing.pixel_y = 0

/datum/action_group/palette/cp13
	column_max = 8
	max_rows = 3

/datum/action_group/palette/cp13/proc/cp13_overflow_location(number)
	var/atom/movable/screen/button_palette/palette = owner.screen_objects[HUD_MOB_TOGGLE_PALETTE]
	if(!palette.expanded)
		return null
	var/row = round(number / column_max) - row_offset
	if(row < 0 || row >= max_rows)
		return null
	return "CENTER:[-104 + (number % column_max) * (CP13_HUD_CARD_WIDTH + CP13_HUD_CARD_GAP)],SOUTH+2:[8 + row * (16 + CP13_HUD_CARD_GAP)]"

/datum/action_group/palette/cp13/ButtonNumberToScreenCoords(number, landing = FALSE)
	return cp13_overflow_location(max(0, length(owner.listed_actions.actions) - 8) + number)

/datum/action_group/palette/cp13/refresh_actions()
	if(!owner || QDELING(owner))
		return
	var/datum/action_group/listed/listed = owner.listed_actions
	var/listed_overflow = max(0, length(listed.actions) - 8)
	var/count = listed_overflow + length(actions)
	row_offset = clamp(row_offset, 0, max(0, ROUND_UP(count / column_max) - max_rows))
	var/atom/movable/screen/button_palette/palette = owner.screen_objects[HUD_MOB_TOGGLE_PALETTE]
	palette.screen_loc = null
	for(var/index in 9 to length(listed.actions))
		var/atom/movable/screen/movable/action_button/button = listed.actions[index]
		button.screen_loc = cp13_overflow_location(index - 9)
	for(var/index in 1 to length(actions))
		var/atom/movable/screen/movable/action_button/button = actions[index]
		button.screen_loc = ButtonNumberToScreenCoords(index - 1)
		button.cp13_fit()
	if(landing)
		landing.screen_loc = ButtonNumberToScreenCoords(length(actions), TRUE)
		landing.transform = matrix(0.5, 0, -4, 0, 0.5, -8)
		landing.pixel_x = 0
		landing.pixel_y = 0
	var/atom/movable/screen/up = owner.screen_objects[HUD_MOB_PALETTE_UP]
	var/atom/movable/screen/down = owner.screen_objects[HUD_MOB_PALETTE_DOWN]
	up.screen_loc = palette.expanded && count > column_max * max_rows ? "CENTER:-104,SOUTH+4:0" : null
	down.screen_loc = palette.expanded && count > column_max * max_rows ? "CENTER:86,SOUTH+4:0" : null

/datum/action_group/palette/cp13/check_against_view()
	refresh_actions()

/atom/movable/screen/palette_scroll/cp13/refresh_owner()
	. = ..()
	cp13_set_art(CP13_HUD_GLYPHS, scroll_direction < 0 ? "arrow_up" : "arrow_down")

/atom/movable/screen/palette_scroll/cp13/up
	name = "Scroll Up"
	scroll_direction = -1

/atom/movable/screen/palette_scroll/cp13/down
	name = "Scroll Down"
	scroll_direction = 1

/atom/movable/screen/button_palette/cp13/set_expanded(new_expanded)
	var/datum/action_group/our_group = our_hud.palette_actions
	if(!length(our_group.actions) && length(our_hud.listed_actions.actions) <= 8)
		new_expanded = FALSE
	if(expanded == new_expanded)
		return
	expanded = new_expanded
	our_group.refresh_actions()
	update_appearance()
	if(!usr?.client)
		return
	if(expanded)
		RegisterSignal(usr.client, COMSIG_CLIENT_CLICK, PROC_REF(clicked_while_open))
	else
		UnregisterSignal(usr.client, COMSIG_CLIENT_CLICK)
	closeToolTip(usr)

/atom/movable/screen/button_palette/cp13/clicked_while_open(datum/source, atom/target, atom/location, control, params, mob/user)
	if(target == our_hud.screen_objects[HUD_MOB_MEMORIES])
		return
	return ..()

/atom/movable/screen/button_palette/refresh_owner()
	. = ..()
	if(istype(our_hud, /datum/hud/human))
		maptext_width = 16
		maptext_height = 16
		maptext = ""
		screen_loc = null
		update_appearance()

/atom/movable/screen/button_palette/update_icon_state()
	. = ..()
	if(istype(our_hud, /datum/hud/human))
		cp13_set_art(CP13_HUD_FRAME16, expanded ? "active" : "idle", null)

/atom/movable/screen/button_palette/disable_landing()
	. = ..()
	if(istype(our_hud, /datum/hud/human))
		invisibility = INVISIBILITY_ABSTRACT

#ifdef UNIT_TESTS
/datum/unit_test/cp13_screentip_bounds/Run()
	var/mob/living/carbon/human/consistent/human = allocate(__IMPLIED_TYPE__)
	var/mob/dead/observer/ghost = allocate(__IMPLIED_TYPE__)
	var/datum/hud/human/human_hud = allocate(/datum/hud/human, human)
	var/datum/hud/ghost/ghost_hud = allocate(/datum/hud/ghost, ghost)
	for(var/datum/hud/owner_hud as anything in list(human_hud, ghost_hud))
		var/atom/movable/screen/screentip/tip = owner_hud.screentip_text
		for(var/view in list("15x15", "23x15", "17x17", "15x15"))
			tip.update_view(null, view)
			var/view_width = view_to_pixels(view)[1]
			if(tip.screen_loc != "WEST,NORTH" || tip.maptext_x <= 0 || tip.maptext_width + 2 * tip.maptext_x != view_width)
				return Fail("[owner_hud.type] screentip must remain centered with equal margins after resizing to [view]", __FILE__, __LINE__)

#ifdef CP13_HUD_TEST
/datum/unit_test/cp13_action_bar
	test_flags = UNIT_TEST_FOCUS
#endif

/datum/unit_test/cp13_action_bar/Run()
	var/mob/living/carbon/human/consistent/dummy = allocate(__IMPLIED_TYPE__)
	for(var/datum/action/existing as anything in dummy.actions?.Copy())
		existing.Remove(dummy)
	dummy.set_hud_used(new /datum/hud/human(dummy))
	// create_mob_hud() normally emits this after assigning hud_used.
	SEND_SIGNAL(dummy, COMSIG_MOB_HUD_CREATED)
	var/datum/hud/human/owner_hud = dummy.hud_used
	for(var/slot_id in owner_hud.inventory_slots)
		if(slot_id == ITEM_SLOT_HANDS)
			continue
		var/datum/inventory_slot/slot_data = owner_hud.inventory_slots[slot_id]
		var/atom/movable/screen/inventory/slot = slot_data.get_screen_slot(owner_hud)
		if(slot?.icon != CP13_HUD_INVENTORY || !icon_exists(slot.icon, slot.icon_empty))
			return Fail("Inventory slot [slot_id] has no purpose silhouette", __FILE__, __LINE__)
		if(!slot.cp13_frame || slot.cp13_frame.hud_group_key != slot.hud_group_key)
			return Fail("Inventory slot [slot_id] must share visibility with its frame", __FILE__, __LINE__)
	var/atom/movable/screen/inventory/eyes_slot = owner_hud.screen_objects[HUD_KEY_ITEM_SLOT(ITEM_SLOT_EYES)]
	var/atom/movable/screen/original_frame = eyes_slot.cp13_frame
	var/obj/item/clothing/glasses/sunglasses/test_glasses = allocate(__IMPLIED_TYPE__)
	if(!dummy.equip_to_slot_if_possible(test_glasses, ITEM_SLOT_EYES))
		return Fail("Could not equip the inventory silhouette test item", __FILE__, __LINE__)
	owner_hud.inventory_update(dummy)
	if(eyes_slot.icon_state != "occupied" || !(test_glasses in eyes_slot.vis_contents) || eyes_slot.cp13_frame != original_frame)
		return Fail("Equipping must clear the silhouette, show the item and retain its frame", __FILE__, __LINE__)
	dummy.dropItemToGround(test_glasses)
	owner_hud.inventory_update(dummy)
	if(eyes_slot.icon_state != eyes_slot.icon_empty || length(eyes_slot.vis_contents) || eyes_slot.cp13_frame != original_frame)
		return Fail("Unequipping must restore the silhouette without replacing its frame", __FILE__, __LINE__)
	for(var/index in 1 to 2)
		var/atom/movable/screen/inventory/hand/hand = owner_hud.screen_objects[HUD_KEY_HAND_SLOT(index)]
		log_test("CP13 hand [index]: [hand?.type], icon=[hand?.icon], state=[hand?.icon_state], frame=[hand?.cp13_frame], loc=[hand?.screen_loc]")
		if(!istype(hand, /atom/movable/screen/inventory/hand/cp13))
			return Fail("The human HUD factory did not create the CP13 hand subtype", __FILE__, __LINE__)
		for(var/update in 1 to 3)
			owner_hud.inventory_update(dummy)
			var/expected_state = "hand_[dummy.held_index_to_dir(index)]"
			if(hand.icon != CP13_HUD_HANDS || hand.icon_state != expected_state || !icon_exists(hand.icon, hand.icon_state))
				return Fail("Hand [index] lost its glyph after inventory update [update]: [hand.icon], [hand.icon_state]", __FILE__, __LINE__)
	for(var/key in list(
		HUD_KEY_HAND_SLOT(1), HUD_KEY_HAND_SLOT(2), HUD_HUMAN_TOGGLE_INVENTORY,
		HUD_MOB_REST, HUD_MOB_MOVE_INTENT, HUD_MOB_FLOOR_CHANGER,
		HUD_MOB_SWAPHAND_2, HUD_MOB_THROW, HUD_MOB_DROP, HUD_MOB_RESIST,
		HUD_MOB_LANGUAGE_MENU, HUD_MOB_CRAFTING_MENU, HUD_MOB_MEMORIES,
		"cp13_emotes", HUD_MOB_NAVIGATE_MENU, HUD_MOB_AREA_CREATOR,
		"cp13_accessories", "cp13_underwear",
	))
		var/atom/movable/screen/control = owner_hud.screen_objects[key]
		var/atom/movable/screen/frame = control?.cp13_frame
		if(!frame || owner_hud.screen_objects[frame.hud_key] != frame)
			return Fail("Glyph controls must have a registered frame screen object: [key]", __FILE__, __LINE__)
		if(frame.plane != control.plane || frame.layer >= control.layer || frame.screen_loc != control.screen_loc)
			return Fail("Control frame must render directly below its glyph on the HUD plane: [key]", __FILE__, __LINE__)
		if(frame.hud_group_key != control.hud_group_key || !(frame in owner_hud.screen_groups[control.hud_group_key]))
			return Fail("Control and frame must share HUD visibility: [key]", __FILE__, __LINE__)
		if(frame.mouse_opacity != MOUSE_OPACITY_TRANSPARENT || control.mouse_opacity != MOUSE_OPACITY_OPAQUE)
			return Fail("The frame must not intercept clicks; the button must expose its whole cell: [key]", __FILE__, __LINE__)
		control.cp13_frame_hovered = TRUE
		control.cp13_refresh_frame()
		if(frame != control.cp13_frame)
			return Fail("Hover must reuse the registered frame object: [key]", __FILE__, __LINE__)
		control.cp13_frame_hovered = FALSE
		control.cp13_refresh_frame()
	var/list/test_actions = list()
	for(var/index in 1 to 9)
		var/datum/action/action = new(dummy)
		action.name = "CP13 action [index]"
		action.Grant(dummy)
		test_actions += action
		var/atom/movable/screen/movable/action_button/button = action.viewers[owner_hud]
		if(!button.cp13_signal_registered)
			return Fail("Native action must participate in automatic scaling", __FILE__, __LINE__)
		var/matrix/fitted = button.transform
		if(fitted.c != -4 || fitted.f != -8 || button.pixel_x || button.pixel_y)
			return Fail("Screen action centering must use matrix translation, not ignored pixel offsets", __FILE__, __LINE__)
		var/mutable_appearance/frame = new(button.underlays[1])
		if(frame.plane != button.plane || (frame.appearance_flags & (RESET_TRANSFORM|KEEP_APART)) != (RESET_TRANSFORM|KEEP_APART))
			return Fail("Action frame must stay unscaled on the HUD plane", __FILE__, __LINE__)
		if(index <= 8)
			if(button.screen_loc != owner_hud.cp13_action_location(index))
				return Fail("Action must occupy its native quick slot", __FILE__, __LINE__)
		else
			if(!isnull(button.screen_loc))
				return Fail("Overflow must stay hidden until expanded", __FILE__, __LINE__)
	var/datum/action/scale_action = test_actions[2]
	var/atom/movable/screen/movable/action_button/scale_button = scale_action.viewers[owner_hud]
	var/icon/wide = icon('icons/hud/screen_gen.dmi', "template")
	wide.Scale(64, 32)
	scale_button.icon = wide
	scale_button.cp13_fit()
	if(scale_button.cp13_scale != 0.25)
		return Fail("Wide icons must fit the same 16-pixel slot", __FILE__, __LINE__)
	var/matrix/wide_fit = scale_button.transform
	if(wide_fit.c != -20 || wide_fit.f != -8)
		return Fail("Wide source canvas must be centered inside its 24x16-pixel cell", __FILE__, __LINE__)
	scale_action.build_button_icon(scale_button, UPDATE_BUTTON_ICON, TRUE)
	var/atom/movable/screen/button_palette/palette = owner_hud.screen_objects[HUD_MOB_TOGGLE_PALETTE]
	palette.set_expanded(TRUE)
	var/datum/action/ninth = test_actions[9]
	var/atom/movable/screen/movable/action_button/ninth_button = ninth.viewers[owner_hud]
	if(isnull(ninth_button.screen_loc))
		return Fail("Listed overflow must open even with an empty native palette", __FILE__, __LINE__)
	var/datum/action/first = test_actions[1]
	first.Remove(dummy)
	var/datum/action/second = test_actions[2]
	var/atom/movable/screen/movable/action_button/second_button = second.viewers[owner_hud]
	if(second_button.screen_loc != owner_hud.cp13_action_location(1))
		return Fail("Removing an action must close the gap", __FILE__, __LINE__)
	for(var/datum/action/action as anything in test_actions)
		qdel(action)
	if(length(owner_hud.listed_actions.actions))
		return Fail("Removing the last action must clear the action group", __FILE__, __LINE__)
	for(var/index in 1 to 8)
		if(owner_hud.screen_objects["cp13_quick_[index]"])
			return Fail("Empty action slots must not create placeholder screen objects", __FILE__, __LINE__)
	var/list/left_pocket = screen_loc_to_offset(owner_hud.screen_objects[HUD_KEY_ITEM_SLOT(ITEM_SLOT_LPOCKET)].screen_loc, "15x15")
	var/list/right_pocket = screen_loc_to_offset(owner_hud.screen_objects[HUD_KEY_ITEM_SLOT(ITEM_SLOT_RPOCKET)].screen_loc, "15x15")
	for(var/index in 1 to 8)
		var/list/position = screen_loc_to_offset(owner_hud.cp13_action_location(index), "15x15")
		if(index <= 4 && position[1] + 24 > left_pocket[1] - 2)
			return Fail("Expanded action cards must retain a gutter before the left pocket", __FILE__, __LINE__)
		if(index > 4 && position[1] < right_pocket[1] + 32 + 2)
			return Fail("Expanded action cards must retain a gutter after the right pocket", __FILE__, __LINE__)
	owner_hud.cp13_sync_status_cards()
	if(length(owner_hud.cp13_status_cards))
		return Fail("No status effects must mean no status cards", __FILE__, __LINE__)
	var/list/test_effects = list()
	for(var/index in 1 to 17)
		var/datum/status_effect/effect = dummy.apply_status_effect(/datum/status_effect/cp13_hud_layout_test, index, index <= 9)
		test_effects += effect
	owner_hud.cp13_sync_status_cards()
	if(length(owner_hud.cp13_status_cards) != 16)
		return Fail("The HUD must support eight buff and eight debuff cards", __FILE__, __LINE__)
	for(var/kind in list("buff", "debuff"))
		var/list/previous_position
		for(var/index in 1 to 8)
			var/datum/status_effect/effect = test_effects[kind == "buff" ? index : index + 9]
			var/atom/movable/screen/cp13_status_card/card = owner_hud.cp13_status_cards[REF(effect.linked_alert)]
			if(!card || card.icon_state != kind || !length(card.overlays))
				return Fail("Live effects must create a correctly classified card with its real glyph", __FILE__, __LINE__)
			var/icon/card_image = icon(card.icon, card.icon_state)
			if(card_image.Width() != 24 || card_image.Height() != 32)
				return Fail("Status cards must be exactly 24x32", __FILE__, __LINE__)
			var/list/position = screen_loc_to_offset(card.screen_loc, "15x15")
			if(previous_position && abs(position[1] - previous_position[1]) != 26)
				return Fail("Adjacent status cards must have a two-pixel gutter", __FILE__, __LINE__)
			previous_position = position
	var/datum/status_effect/overflow_effect = test_effects[9]
	if(owner_hud.cp13_status_cards[REF(overflow_effect.linked_alert)])
		return Fail("Ninth buff must remain a native alert instead of overflowing the compact row", __FILE__, __LINE__)
	var/datum/status_effect/first_effect = test_effects[1]
	var/atom/movable/screen/cp13_status_card/first_card = owner_hud.cp13_status_cards[REF(first_effect.linked_alert)]
	qdel(first_effect)
	owner_hud.cp13_sync_status_cards()
	if(!QDELETED(first_card) || !owner_hud.cp13_status_cards[REF(overflow_effect.linked_alert)])
		return Fail("Removing an effect must delete its card and promote the next real effect", __FILE__, __LINE__)
	for(var/datum/status_effect/effect as anything in test_effects)
		if(!QDELETED(effect))
			qdel(effect)
	owner_hud.cp13_sync_status_cards()
	if(length(owner_hud.cp13_status_cards))
		return Fail("Removing all effects must remove every status card", __FILE__, __LINE__)

/datum/status_effect/cp13_hud_layout_test
	id = "cp13_hud_layout_test"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_MULTIPLE

/datum/status_effect/cp13_hud_layout_test/on_creation(mob/living/new_owner, index, beneficial)
	id = "cp13_hud_layout_test_[index]"
	alert_type = beneficial ? /atom/movable/screen/alert/status_effect/exercised : /atom/movable/screen/alert/status_effect/woozy
	return ..()
#endif

#undef CP13_HUD_GLYPHS
#undef CP13_HUD_LARGE_GLYPHS
#undef CP13_HUD_MOVEMENT
#undef CP13_HUD_FRAME16
#undef CP13_HUD_FRAME32
#undef CP13_HUD_FRAME_WIDE
#undef CP13_HUD_STATUS
#undef CP13_HUD_FLOOR
#undef CP13_HUD_HANDS
#undef CP13_HUD_INVENTORY
#undef CP13_HUD_ACTION_FRAME
#undef CP13_HUD_STATUS_CARDS
#undef CP13_HUD_CARD_WIDTH
#undef CP13_HUD_CARD_GAP
#undef CP13_HUD_STATUS_LIMIT
