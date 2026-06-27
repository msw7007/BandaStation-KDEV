/atom/movable/screen/escape_menu/details
	screen_loc = "EAST:-175,NORTH:-40"
	maptext_height = 100
	maptext_width = 200

/atom/movable/screen/escape_menu/details/proc/update_text(client/client_owner)
	var/new_maptext = {"
		<span style='text-align: right; line-height: 0.7; color: #18d8ff'>
			<span style='color: #ff334a'>ROUND</span> [GLOB.round_id || "Unset"]<br />
			<span style='color: #ff334a'>TIME</span> [server_timestamp(format = "hh:mm:ss", ic_time = TRUE, twelve_hour_clock = client_owner.prefs.read_preference(/datum/preference/toggle/twelve_hour))]<br />
			<span style='color: #ff334a'>SHIFT</span> [(SSticker.round_start_time == 0) ? "Pre-Game" : round_timestamp()]<br />
			<span style='color: #ff334a'>MAP</span> [SSmapping.current_map.return_map_name(webmap_included = TRUE) || "Loading..."]<br />
			<span style='color: #ff334a'>TD</span> [round(SStime_track.time_dilation_current, 1)]%<br />
		</span>
	"}

	maptext = MAPTEXT(new_maptext)
