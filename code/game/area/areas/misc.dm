// Areas that don't fit any of the other files, or only serve one purpose.

/area/space
	icon_state = "space"
	requires_power = TRUE
	always_unpowered = TRUE
	static_lighting = FALSE
	base_lighting_alpha = 255
	base_lighting_color = COLOR_STARLIGHT
	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE
	outdoors = TRUE
	ambience_index = AMBIENCE_SPACE
	flags_1 = CAN_BE_DIRTY_1
	sound_environment = SOUND_AREA_SPACE
	ambient_buzz = null //Space is deafeningly quiet
	allow_shuttle_docking = TRUE

/area/space/nearstation
	icon_state = "space_near"
	static_lighting = TRUE
	base_lighting_alpha = 0
	base_lighting_color = null

/area/misc/start
	name = "start area"
	icon_state = "start"
	requires_power = FALSE
	static_lighting = FALSE
	base_lighting_alpha = 255
	default_gravity = STANDARD_GRAVITY
	ambient_buzz = null

/area/misc/testroom
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY
	// Mobs should be able to see inside the testroom
	static_lighting = FALSE
	base_lighting_alpha = 255
	name = "Test Room"
	icon_state = "test_room"

/area
	/// City AI uses this to decide whether violence should trigger a broad security response.
	var/cyberpunk_safe_zone = FALSE
	/// CP13 world tags used by the storyteller, contracts, NPCs and map tooling.
	var/list/cyberpunk_world_tags
	/// Optional owner key for corporate/government territory logic.
	var/cyberpunk_world_owner
	/// Coarse violence response: none, weak, normal, high.
	var/cyberpunk_violence_control = "normal"
	/// Stable CP13 district id used by the storyteller and city systems.
	var/cyberpunk_district_id
	/// Display name for CP13 district analytics. Defaults to area name.
	var/cyberpunk_district_name
	/// Coarse district kind: district, safe, security, wasteland, corporate, etc.
	var/cyberpunk_district_kind = "generic"
	/// Numeric district bucket. The city core expects 1-9 until final map names are assigned.
	var/cyberpunk_district_index = 0
	/// Grid direction inside a city z-level: nw, n, ne, w, c, e, sw, s, se.
	var/cyberpunk_district_direction
	/// Passive danger added to storyteller district pressure.
	var/cyberpunk_district_base_danger = 0
	/// Round-local violence score reported by city AI and combat hooks.
	var/cyberpunk_round_violence_score = 0
	/// Round-local damage amount associated with violent incidents in this area.
	var/cyberpunk_round_damage_taken = 0
	/// Round-local severe incident counter.
	var/cyberpunk_round_critical_events = 0
	/// World time of last recorded violent incident.
	var/cyberpunk_round_last_violence_at = 0

/area/cyberpunk
	name = "Киберпанк"
	icon_state = "test_room"
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY
	static_lighting = FALSE
	base_lighting_alpha = 255
	outdoors = TRUE
	ambient_buzz = null
	cyberpunk_district_id = "cyberpunk"
	cyberpunk_district_name = "Киберпанк"
	cyberpunk_district_kind = "world"

/area/cyberpunk/city
	name = "Брайт-Сити"
	cyberpunk_district_id = "city"
	cyberpunk_district_name = "Брайт-Сити"
	cyberpunk_district_kind = "city"

/area/cyberpunk/city/safe
	name = "Безопасная зона"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "safe"
	cyberpunk_district_name = "Безопасная зона"
	cyberpunk_district_kind = "safe"
	cyberpunk_violence_control = "high"

/area/cyberpunk/city/security
	name = "Городская безопасность"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "security"
	cyberpunk_district_name = "Городская безопасность"
	cyberpunk_district_kind = "security"
	cyberpunk_world_tags = list("government")
	cyberpunk_world_owner = "government"
	cyberpunk_violence_control = "high"

/area/cyberpunk/city/wasteland
	name = "Пустошь"
	cyberpunk_district_id = "wasteland"
	cyberpunk_district_name = "Пустошь"
	cyberpunk_district_kind = "wasteland"
	cyberpunk_district_base_danger = 20
	cyberpunk_violence_control = "none"

/area/cyberpunk/city/district
	name = "Городской район"
	cyberpunk_district_kind = "district"
	cyberpunk_district_base_danger = 8

/area/cyberpunk/city/district/district_01
	name = "Аква Квин"
	cyberpunk_district_id = "aqua_queen"
	cyberpunk_district_name = "Аква Квин"
	cyberpunk_district_kind = "marine"
	cyberpunk_district_index = 1
	cyberpunk_district_direction = "nw"
	cyberpunk_district_base_danger = 7

/area/cyberpunk/city/district/district_02
	name = "Нортфилд"
	cyberpunk_district_id = "northfield"
	cyberpunk_district_name = "Нортфилд"
	cyberpunk_district_kind = "port"
	cyberpunk_district_index = 2
	cyberpunk_district_direction = "n"
	cyberpunk_district_base_danger = 9

/area/cyberpunk/city/district/district_03
	name = "Чейсвинд"
	cyberpunk_district_id = "chasewind"
	cyberpunk_district_name = "Чейсвинд"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 3
	cyberpunk_district_direction = "ne"
	cyberpunk_district_base_danger = 18

/area/cyberpunk/city/district/district_04
	name = "Гранд Плаза"
	cyberpunk_district_id = "grand_plaza"
	cyberpunk_district_name = "Гранд Плаза"
	cyberpunk_district_kind = "government"
	cyberpunk_district_index = 4
	cyberpunk_district_direction = "w"
	cyberpunk_district_base_danger = 4

/area/cyberpunk/city/district/district_05
	name = "Даунтаун"
	cyberpunk_district_id = "downtown"
	cyberpunk_district_name = "Даунтаун"
	cyberpunk_district_kind = "residential"
	cyberpunk_district_index = 5
	cyberpunk_district_direction = "c"
	cyberpunk_district_base_danger = 6

/area/cyberpunk/city/district/district_06
	name = "Истбук"
	cyberpunk_district_id = "eastbook"
	cyberpunk_district_name = "Истбук"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 6
	cyberpunk_district_direction = "e"
	cyberpunk_district_base_danger = 18

/area/cyberpunk/city/district/district_07
	name = "Чайна-таун"
	cyberpunk_district_id = "chinatown"
	cyberpunk_district_name = "Чайна-таун"
	cyberpunk_district_kind = "ben"
	cyberpunk_district_index = 7
	cyberpunk_district_direction = "sw"
	cyberpunk_district_base_danger = 10

/area/cyberpunk/city/district/district_08
	name = "Блайтфорт"
	cyberpunk_district_id = "blightfort"
	cyberpunk_district_name = "Блайтфорт"
	cyberpunk_district_kind = "slums"
	cyberpunk_district_index = 8
	cyberpunk_district_direction = "s"
	cyberpunk_district_base_danger = 18

/area/cyberpunk/city/district/district_09
	name = "Веллрок"
	cyberpunk_district_id = "wellrock"
	cyberpunk_district_name = "Веллрок"
	cyberpunk_district_kind = "industrial"
	cyberpunk_district_index = 9
	cyberpunk_district_direction = "se"
	cyberpunk_district_base_danger = 12

/area/cyberpunk/city/metro
	name = "Метро"
	outdoors = FALSE
	static_lighting = TRUE
	base_lighting_alpha = 0
	base_lighting_color = null
	cyberpunk_district_id = "metro"
	cyberpunk_district_name = "Метро"
	cyberpunk_district_kind = "metro"
	cyberpunk_world_tags = list("metro", "underground")
	cyberpunk_district_base_danger = 8

/area/cyberpunk/city/road
	name = "Дорога"
	cyberpunk_district_id = "road"
	cyberpunk_district_name = "Дорога"
	cyberpunk_district_kind = "road"
	cyberpunk_world_tags = list("road")
	cyberpunk_district_base_danger = 6

/area/cyberpunk/city/canals
	name = "Каналы"
	cyberpunk_district_id = "canals"
	cyberpunk_district_name = "Каналы"
	cyberpunk_district_kind = "canals"
	cyberpunk_world_tags = list("canals", "underground")
	cyberpunk_district_base_danger = 12

/area/cyberpunk/city/warehouse
	name = "Склад"
	cyberpunk_district_id = "warehouse"
	cyberpunk_district_name = "Склад"
	cyberpunk_district_kind = "warehouse"
	cyberpunk_world_tags = list("warehouse")
	cyberpunk_district_base_danger = 10

/area/cyberpunk/city/corporate
	name = "Корпоративная территория"
	cyberpunk_district_id = "corporate"
	cyberpunk_district_name = "Корпоративная территория"
	cyberpunk_district_kind = "corporate"
	cyberpunk_world_tags = list("corporate")
	cyberpunk_violence_control = "high"
	cyberpunk_district_base_danger = 5

/area/cyberpunk/city/corporate/benn
	name = "Территория Бэнь"
	cyberpunk_district_id = "benn"
	cyberpunk_district_name = "Территория Бэнь"
	cyberpunk_world_owner = "benn"

/area/cyberpunk/city/corporate/ryaznov
	name = "Территория Рязнова"
	cyberpunk_district_id = "ryaznov"
	cyberpunk_district_name = "Территория Рязнова"
	cyberpunk_world_owner = "ryaznov"

/area/cyberpunk/city/corporate/starlight
	name = "Территория Старлайт"
	cyberpunk_district_id = "starlight"
	cyberpunk_district_name = "Территория Старлайт"
	cyberpunk_world_owner = "starlight"

/area/cyberpunk/city/government
	name = "Правительство"
	cyberpunk_safe_zone = TRUE
	cyberpunk_district_id = "government"
	cyberpunk_district_name = "Правительство"
	cyberpunk_district_kind = "government"
	cyberpunk_world_tags = list("government")
	cyberpunk_world_owner = "government"
	cyberpunk_violence_control = "high"
	cyberpunk_district_base_danger = 3

/area/cyberpunk/city/roof
	name = "Крыша"
	cyberpunk_district_id = "roof"
	cyberpunk_district_name = "Крыша"
	cyberpunk_district_kind = "roof"
	cyberpunk_world_tags = list("roof")
	cyberpunk_district_base_danger = 11

/area/cyberpunk/city/underground
	name = "Подземелье"
	cyberpunk_district_id = "underground"
	cyberpunk_district_name = "Подземелье"
	cyberpunk_district_kind = "underground"
	cyberpunk_world_tags = list("underground")
	cyberpunk_violence_control = "weak"
	cyberpunk_district_base_danger = 14

/area/cyberpunk/debug/test_ground
	name = "КП тестовый полигон"
	cyberpunk_district_id = "test_ground"
	cyberpunk_district_name = "КП тестовый полигон"
	cyberpunk_district_kind = "debug"

/area/misc/testroom/gateway_room
	name = "Gateway Room"
	icon = 'icons/area/areas_station.dmi'
	icon_state = "gateway"
