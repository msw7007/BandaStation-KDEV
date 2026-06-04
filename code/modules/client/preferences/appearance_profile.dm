#define BODY_SHAPE_AVERAGE "average"
#define BODY_SHAPE_LEAN "lean"
#define BODY_SHAPE_STOCKY "stocky"
#define BODY_SHAPE_SOFT "soft"
#define BODY_SHAPE_ANGULAR "angular"
#define CORP_ALIGN_NONE "none"
#define CORP_ALIGN_BENN "benn"
#define CORP_ALIGN_RYAZNOV "ryaznov"
#define CORP_ALIGN_STARLIGHT "starlight"
#define CORP_ALIGN_SUN_YON "sun_yon"
#define CORP_ALIGN_ISHIKAWA "ishikawa"
#define CORP_ALIGN_HO_SHI "ho_shi"
#define CORP_ALIGN_KOWALSKI "kowalski"
#define CORP_ALIGN_TYAZHMARSH "tyazhmarsh"
#define CORP_ALIGN_TESLA_SCIENCE "tesla_science"
#define CORP_ALIGN_BLACKROCK_INVESTIGATE "blackrock_investigate"
#define CORP_ALIGN_TRANS_TRAVEL "trans_travel"
#define CORP_ALIGN_SAMANTHAS_KEIR "samanthas_keir"
#define CYBERPUNK_VISUAL_DESIGN_MAX_RECORDS 24
#define CYBERPUNK_VISUAL_DESIGN_MAX_PAYLOAD 65535
#define CYBERPUNK_PERSISTENT_AREA_MAX_RECORDS 8

#define CORP_GROUP_BEN "ben"
#define CORP_GROUP_RYAZNOV "ryaznov"
#define CORP_GROUP_STARLIGHT "starlight"
#define CORP_SYNERGY_EXACT 1.1
#define CORP_SYNERGY_GROUP 1.05

/proc/body_descriptor_choices()
	return list(
		"scarred",
		"clean",
		"wiry",
		"heavy",
		"elegant",
		"tired",
		"nervous",
		"calm",
		"augmented",
		"unremarkable",
	)

/proc/incognito_adjective_choices()
	return list("unknown", "masked", "hooded", "armored", "quiet", "rough", "slender", "broad")

/proc/incognito_noun_choices()
	return list("figure", "stranger", "person", "silhouette", "operator", "worker", "merc")

/proc/voice_adjective_choices()
	return list("unknown", "raspy", "soft", "sharp", "low", "cold", "warm", "metallic")

/proc/voice_noun_choices()
	return list("voice", "speaker", "whisper", "tone", "accent", "murmur")

/proc/corp_align_choices()
	return list(
		CORP_ALIGN_BENN = "Benn Conglomerate",
		CORP_ALIGN_RYAZNOV = "Ryaznov Union",
		CORP_ALIGN_STARLIGHT = "Starlight Combine",
		CORP_ALIGN_NONE = "Независимый",
		CORP_ALIGN_SUN_YON = "Сан Йон Корпорейшн",
		CORP_ALIGN_ISHIKAWA = "Ишикава Индастриз",
		CORP_ALIGN_HO_SHI = "Хо Ши Текнолоджис",
		CORP_ALIGN_KOWALSKI = "Ковальски и Ко",
		CORP_ALIGN_TYAZHMARSH = "ТяжМарш Продакшен",
		CORP_ALIGN_TESLA_SCIENCE = "Тесла Саенс",
		CORP_ALIGN_BLACKROCK_INVESTIGATE = "Блэкрок Инвестигейт",
		CORP_ALIGN_TRANS_TRAVEL = "Транс Трэвел",
		CORP_ALIGN_SAMANTHAS_KEIR = "Самантас Кеир",
	)

/proc/cyberpunk_neural_interface_choices()
	var/list/all_choices = corp_align_choices()
	var/list/choices = list()
	for(var/manufacturer_id in all_choices)
		if(manufacturer_id == CORP_ALIGN_NONE)
			continue
		choices[manufacturer_id] = all_choices[manufacturer_id]
	return choices

/proc/cyberpunk_sanitize_visual_design_record(list/record)
	if(!islist(record))
		return null

	var/list/sanitized = list()
	sanitized["id"] = copytext_char("[record["id"] || "[world.realtime]-[rand(1000, 9999)]"]", 1, 64)
	sanitized["name"] = copytext_char(trim("[record["name"] || "custom design"]"), 1, MAX_NAME_LEN)
	sanitized["kind"] = copytext_char(trim("[record["kind"] || "generic"]"), 1, 32)
	sanitized["base"] = copytext_char(trim("[record["base"] || ""]"), 1, MAX_NAME_LEN)
	sanitized["type_path"] = copytext_char(trim("[record["type_path"] || ""]"), 1, 180)
	sanitized["target_ref"] = copytext_char(trim("[record["target_ref"] || ""]"), 1, 64)
	sanitized["icon_state"] = copytext_char(trim("[record["icon_state"] || ""]"), 1, 96)
	sanitized["worn_icon_state"] = copytext_char(trim("[record["worn_icon_state"] || ""]"), 1, 96)
	sanitized["greyscale_colors"] = copytext_char(trim("[record["greyscale_colors"] || ""]"), 1, 256)
	sanitized["material_signature"] = copytext_char(trim("[record["material_signature"] || ""]"), 1, 512)
	sanitized["created_at"] = isnum(record["created_at"]) ? record["created_at"] : world.realtime

	var/list/directions = list()
	if(islist(record["directions"]))
		for(var/direction_key in list("north", "south", "east", "west"))
			directions[direction_key] = copytext_char("[record["directions"][direction_key] || ""]", 1, CYBERPUNK_VISUAL_DESIGN_MAX_PAYLOAD)
	else
		for(var/direction_key in list("north", "south", "east", "west"))
			directions[direction_key] = ""
	sanitized["directions"] = directions
	sanitized["item_icon"] = copytext_char("[record["item_icon"] || ""]", 1, CYBERPUNK_VISUAL_DESIGN_MAX_PAYLOAD)
	return sanitized

/proc/cyberpunk_sanitize_visual_design_records(value, max_records = CYBERPUNK_VISUAL_DESIGN_MAX_RECORDS)
	var/list/result = list()
	if(!islist(value))
		return result

	for(var/entry in value)
		var/list/sanitized = cyberpunk_sanitize_visual_design_record(entry)
		if(!sanitized)
			continue
		result += list(sanitized)
		if(length(result) >= max_records)
			break
	return result

/proc/cyberpunk_sanitize_persistent_area_records(value, max_records = CYBERPUNK_PERSISTENT_AREA_MAX_RECORDS)
	var/list/result = list()
	if(!islist(value))
		return result
	for(var/entry in value)
		if(!islist(entry))
			continue
		var/list/record = entry
		var/list/sanitized = list()
		sanitized["id"] = copytext_char("[record["id"] || "[world.realtime]-[rand(1000, 9999)]"]", 1, 96)
		sanitized["name"] = copytext_char(trim("[record["name"] || "persistent area"]"), 1, MAX_NAME_LEN)
		sanitized["owner_key"] = copytext_char(trim("[record["owner_key"] || ""]"), 1, 96)
		sanitized["area_type"] = copytext_char(trim("[record["area_type"] || ""]"), 1, 180)
		sanitized["saved_at"] = isnum(record["saved_at"]) ? record["saved_at"] : world.realtime
		sanitized["snapshot"] = islist(record["snapshot"]) ? record["snapshot"] : list()
		sanitized["meta"] = islist(record["meta"]) ? record["meta"] : list()
		result += list(sanitized)
		if(length(result) >= max_records)
			break
	return result

/proc/cyberpunk_major_corp_for_manufacturer(manufacturer)
	manufacturer = cyberpunk_normalize_manufacturer_id(manufacturer)
	switch(manufacturer)
		if(CORP_ALIGN_BENN)
			return CORP_GROUP_BEN
		if(CORP_ALIGN_RYAZNOV)
			return CORP_GROUP_RYAZNOV
		if(CORP_ALIGN_STARLIGHT)
			return CORP_GROUP_STARLIGHT
		if("benn_bio", "benn_clinic", "benn_shadow")
			return CORP_GROUP_BEN
		if("ryaznov_works", "ryaznov_energy", "ryaznov_defense")
			return CORP_GROUP_RYAZNOV
		if("starlight_logistics", "starlight_transit", "starlight_market")
			return CORP_GROUP_STARLIGHT
		if(CORP_ALIGN_SUN_YON, CORP_ALIGN_ISHIKAWA, CORP_ALIGN_HO_SHI)
			return CORP_GROUP_BEN
		if(CORP_ALIGN_KOWALSKI, CORP_ALIGN_TYAZHMARSH, CORP_ALIGN_TESLA_SCIENCE)
			return CORP_GROUP_RYAZNOV
		if(CORP_ALIGN_BLACKROCK_INVESTIGATE, CORP_ALIGN_TRANS_TRAVEL, CORP_ALIGN_SAMANTHAS_KEIR)
			return CORP_GROUP_STARLIGHT
	return null

/proc/cyberpunk_normalize_manufacturer_id(manufacturer)
	if(!manufacturer)
		return CORP_ALIGN_NONE
	var/normalized = lowertext(trim("[manufacturer]"))
	if(normalized == "independent")
		return CORP_ALIGN_NONE
	switch(normalized)
		if("benn", "ben", "benn conglomerate", "бэнь")
			return CORP_ALIGN_BENN
		if("benn bio")
			return "benn_bio"
		if("benn clinic")
			return "benn_clinic"
		if("benn shadow")
			return "benn_shadow"
		if("ryaznov", "riaznov", "ryaznov union", "рязнов")
			return CORP_ALIGN_RYAZNOV
		if("ryaznov works")
			return "ryaznov_works"
		if("ryaznov energy")
			return "ryaznov_energy"
		if("ryaznov defense")
			return "ryaznov_defense"
		if("starlight", "starlight combine", "старлайт")
			return CORP_ALIGN_STARLIGHT
		if("starlight logistics")
			return "starlight_logistics"
		if("starlight transit")
			return "starlight_transit"
		if("starlight market")
			return "starlight_market"
	var/list/choices = corp_align_choices()
	if(normalized in choices)
		return normalized
	for(var/manufacturer_id in choices)
		if(lowertext(choices[manufacturer_id]) == normalized)
			return manufacturer_id
	return normalized

/proc/cyberpunk_corporate_synergy_multiplier(neural_manufacturer, equipment_manufacturer)
	neural_manufacturer = cyberpunk_normalize_manufacturer_id(neural_manufacturer)
	equipment_manufacturer = cyberpunk_normalize_manufacturer_id(equipment_manufacturer)
	if(!neural_manufacturer || !equipment_manufacturer || neural_manufacturer == CORP_ALIGN_NONE || equipment_manufacturer == CORP_ALIGN_NONE)
		return 1
	if(neural_manufacturer == equipment_manufacturer)
		return CORP_SYNERGY_EXACT
	var/neural_group = cyberpunk_major_corp_for_manufacturer(neural_manufacturer)
	if(neural_group && neural_group == cyberpunk_major_corp_for_manufacturer(equipment_manufacturer))
		return CORP_SYNERGY_GROUP
	return 1

/proc/cyberpunk_manufacturer_info(manufacturer)
	manufacturer = cyberpunk_normalize_manufacturer_id(manufacturer)
	var/list/choices = corp_align_choices()
	var/list/info = list(
		"id" = manufacturer,
		"display_name" = choices[manufacturer] || manufacturer,
		"major" = cyberpunk_major_corp_for_manufacturer(manufacturer),
	)
	switch(manufacturer)
		if(CORP_ALIGN_SUN_YON)
			info["specialization"] = "Точность"
			info["energy_weapons"] = "Дальнее оружие имеет меньший разброс, рукопашное имеет выше пробитие."
			info["classic_weapons"] = "Меньше разброс у огнестрела, выше пробитие колющего и режущего оружия."
			info["demons"] = "Выше точность и эффективность одиночных демонов по одной цели."
			info["implants"] = "Импланты стабилизации, прицеливания, дальности взгляда и богомолы."
			info["defense"] = "Локальная защита уязвимых зон, лучше держит точечные попадания."
		if(CORP_ALIGN_ISHIKAWA)
			info["specialization"] = "Скрытность"
			info["energy_weapons"] = "Дальнее оружие не оставляет следов, рукопашное может принимать форму предметов."
			info["classic_weapons"] = "Оружие сложнее обнаружить детекторами."
			info["demons"] = "Применение демонов значительно снижает местоположение источника сигнала."
			info["implants"] = "Импланты маскировки, подавления шума, скрытия внешности, обманки и нити."
			info["defense"] = "Защита ускоряет скрытность и поиск сигнатур вокруг."
		if(CORP_ALIGN_HO_SHI)
			info["specialization"] = "Скорость"
			info["energy_weapons"] = "Дальнее оружие скорострельнее, рукопашное быстрее совершает удар."
			info["classic_weapons"] = "Сниженный вес, ускоряющие детали, оружие быстрее проводит атаку."
			info["demons"] = "Повышена скорость активации демона, ниже задержка между применениями."
			info["implants"] = "Импланты ускорения, джетпаков, крюк-кошка и буст рефлексов."
			info["defense"] = "Ускоряющая движение защита, позволяет планировать с высот."
		if(CORP_ALIGN_KOWALSKI)
			info["specialization"] = "Надёжность"
			info["energy_weapons"] = "Оружие расходует меньше энергии и дольше изнашивается."
			info["classic_weapons"] = "Оружие дольше изнашивается и не разрушается от эксплуатации."
			info["demons"] = "Демоны стабильнее, меньше шанс провала или ослабления."
			info["implants"] = "Импланты легче переносят перегрузку, слабее штрафы несовместимости, щит."
			info["defense"] = "Стабильная защита без условий, меньше потеря прочности при уроне."
		if(CORP_ALIGN_TYAZHMARSH)
			info["specialization"] = "Поражаемость"
			info["energy_weapons"] = "Дальнее оружие наносит АОЕ, ближнее оружие наносит клив."
			info["classic_weapons"] = "Дальнее оружие наносит АОЕ, защищено от АОЕ, ближнее наносит конус."
			info["demons"] = "Демоны работают по группе и способны перескакивать на другие цели."
			info["implants"] = "Взрывной удар, ручная ракетница, дробовик, защитный кожух."
			info["defense"] = "Поглощает АОЕ как прямой урон и поглощает урон от мелких снарядов."
		if(CORP_ALIGN_TESLA_SCIENCE)
			info["specialization"] = "Сила"
			info["energy_weapons"] = "Оружие наносит увеличенный урон."
			info["classic_weapons"] = "Оружие наносит увеличенный урон."
			info["demons"] = "Демоны сильнее по эффекту."
			info["implants"] = "Рывки, броски, скачки, тяжелые руки и имплант устойчивости."
			info["defense"] = "Энергетический щит, щиты поглощения и репульса, перевод урона в огонь."
		if(CORP_ALIGN_BLACKROCK_INVESTIGATE)
			info["specialization"] = "Контроль"
			info["energy_weapons"] = "Замедление от урона оружием, дебаффы при защите с оружием."
			info["classic_weapons"] = "Контроль от урона оружием, замедление при защите."
			info["demons"] = "Эффективность дебаффов увеличивается, демоны остановки."
			info["implants"] = "Импланты сопротивления разным формам контроля."
			info["defense"] = "Защитные одежды снижают время под контролем."
		if(CORP_ALIGN_TRANS_TRAVEL)
			info["specialization"] = "Массовость"
			info["energy_weapons"] = "Дальнее оружие имеет шанс дополнительного выстрела, ближнее - дополнительного удара."
			info["classic_weapons"] = "Дальнее оружие имеет шанс не потратить снаряд."
			info["demons"] = "Демоны проще распространяются на несколько союзников или врагов."
			info["implants"] = "Телепортация, вызов, реколл и распространение эффектов."
			info["defense"] = "Телепортирует от атакующего, за спину атакующему, скрывает и подменяет."
		if(CORP_ALIGN_SAMANTHAS_KEIR)
			info["specialization"] = "Влияние"
			info["energy_weapons"] = "Энергетическое оружие при попадании снижает защиту цели."
			info["classic_weapons"] = "Классическое оружие при попадании снижает психику цели."
			info["demons"] = "Демоны усиливают психическое воздействие."
			info["implants"] = "Импланты воздействия на психику, социализацию и эмоции."
			info["defense"] = "Защита от психического воздействия и сканирования эмоций."
	return info

/datum/preference/numeric/sprite_size
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_size"
	minimum = 0.85
	maximum = 1.15
	step = 0.01

/datum/preference/numeric/sprite_size/create_default_value()
	return 1

/datum/preference/numeric/sprite_size/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_size = value
	target.apply_preference_sprite_scale()

/datum/preference/numeric/sprite_height
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_height"
	minimum = 0.9
	maximum = 1.1
	step = 0.01

/datum/preference/numeric/sprite_height/create_default_value()
	return 1

/datum/preference/numeric/sprite_height/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_height = value
	target.apply_preference_sprite_scale()

/datum/preference/numeric/sprite_width
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "sprite_width"
	minimum = 0.9
	maximum = 1.1
	step = 0.01

/datum/preference/numeric/sprite_width/create_default_value()
	return 1

/datum/preference/numeric/sprite_width/apply_to_human(mob/living/carbon/human/target, value)
	target.preference_sprite_width = value
	target.apply_preference_sprite_scale()

/datum/preference/choiced/body_shape
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "body_shape"

/datum/preference/choiced/body_shape/init_possible_values()
	return list(BODY_SHAPE_AVERAGE, BODY_SHAPE_LEAN, BODY_SHAPE_STOCKY, BODY_SHAPE_SOFT, BODY_SHAPE_ANGULAR)

/datum/preference/choiced/body_shape/create_default_value()
	return BODY_SHAPE_AVERAGE

/datum/preference/choiced/body_shape/apply_to_human(mob/living/carbon/human/target, value)
	target.body_shape = value

/datum/preference/choiced/appearance_descriptor
	abstract_type = /datum/preference/choiced/appearance_descriptor
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	randomize_by_default = FALSE
	should_update_preview = FALSE
	var/descriptor_index = 1

/datum/preference/choiced/appearance_descriptor/init_possible_values()
	return body_descriptor_choices()

/datum/preference/choiced/appearance_descriptor/create_default_value()
	return "unremarkable"

/datum/preference/choiced/appearance_descriptor/apply_to_human(mob/living/carbon/human/target, value)
	LAZYINITLIST(target.appearance_descriptors)
	target.appearance_descriptors.len = max(target.appearance_descriptors.len, 4)
	target.appearance_descriptors[descriptor_index] = value

/datum/preference/choiced/appearance_descriptor/one
	savefile_key = "appearance_descriptor_1"
	descriptor_index = 1

/datum/preference/choiced/appearance_descriptor/two
	savefile_key = "appearance_descriptor_2"
	descriptor_index = 2

/datum/preference/choiced/appearance_descriptor/three
	savefile_key = "appearance_descriptor_3"
	descriptor_index = 3

/datum/preference/choiced/appearance_descriptor/four
	savefile_key = "appearance_descriptor_4"
	descriptor_index = 4

/datum/preference/text/flavor_text
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "flavor_text"
	maximum_value_length = 1024
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/text/flavor_text/apply_to_human(mob/living/carbon/human/target, value)
	target.flavor_text = value

/datum/preference/choiced/incognito_adjective
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "incognito_adjective"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/incognito_adjective/init_possible_values()
	return incognito_adjective_choices()

/datum/preference/choiced/incognito_adjective/create_default_value()
	return "unknown"

/datum/preference/choiced/incognito_adjective/apply_to_human(mob/living/carbon/human/target, value)
	target.incognito_adjective = value

/datum/preference/choiced/incognito_noun
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "incognito_noun"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/incognito_noun/init_possible_values()
	return incognito_noun_choices()

/datum/preference/choiced/incognito_noun/create_default_value()
	return "figure"

/datum/preference/choiced/incognito_noun/apply_to_human(mob/living/carbon/human/target, value)
	target.incognito_noun = value

/datum/preference/choiced/voice_adjective
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_adjective"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/voice_adjective/init_possible_values()
	return voice_adjective_choices()

/datum/preference/choiced/voice_adjective/create_default_value()
	return "unknown"

/datum/preference/choiced/voice_adjective/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_adjective = value

/datum/preference/choiced/voice_noun
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_noun"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/voice_noun/init_possible_values()
	return voice_noun_choices()

/datum/preference/choiced/voice_noun/create_default_value()
	return "voice"

/datum/preference/choiced/voice_noun/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_noun = value

/datum/preference/color/voice_color
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "voice_color"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/color/voice_color/create_default_value()
	return "c8c8c8"

/datum/preference/color/voice_color/apply_to_human(mob/living/carbon/human/target, value)
	target.voice_color = "#[value]"

/datum/preference/choiced/corp_align
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_identifier = PREFERENCE_CHARACTER
	savefile_key = "corp_align"
	randomize_by_default = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/corp_align/init_possible_values()
	return assoc_to_keys(corp_align_choices())

/datum/preference/choiced/corp_align/create_default_value()
	return CORP_ALIGN_NONE

/datum/preference/choiced/corp_align/compile_constant_data()
	var/list/data = ..()
	data[CHOICED_PREFERENCE_DISPLAY_NAMES] = corp_align_choices()
	return data

/datum/preference/choiced/corp_align/apply_to_human(mob/living/carbon/human/target, value)
	target.corp_align = value == CORP_ALIGN_NONE ? null : value
	var/obj/item/organ/cyberimp/brain/neural_interface/neural_interface = target.get_organ_slot(ORGAN_SLOT_NEURAL_IMPLANT)
	if(istype(neural_interface))
		neural_interface.corp_manufacturer = value == CORP_ALIGN_NONE ? initial(neural_interface.corp_manufacturer) : value
		neural_interface.refresh_ice_model()

/datum/preference/cyberpunk_custom_hair_designs
	savefile_key = "cyberpunk_custom_hair_designs"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_PRE_SPECIES
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/cyberpunk_custom_hair_designs/deserialize(input, datum/preferences/preferences)
	return cyberpunk_sanitize_visual_design_records(input)

/datum/preference/cyberpunk_custom_hair_designs/create_default_value()
	return list()

/datum/preference/cyberpunk_custom_hair_designs/apply_to_human(mob/living/carbon/human/target, value)
	cyberpunk_register_custom_hair_designs(value)

/datum/preference/cyberpunk_custom_hair_designs/is_valid(value, datum/preferences/preferences)
	return islist(value)

/datum/preference/cyberpunk_wardrobe_designs
	savefile_key = "cyberpunk_wardrobe_designs"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_LOADOUT
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/cyberpunk_wardrobe_designs/deserialize(input, datum/preferences/preferences)
	return cyberpunk_sanitize_visual_design_records(input)

/datum/preference/cyberpunk_wardrobe_designs/create_default_value()
	return list()

/datum/preference/cyberpunk_wardrobe_designs/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/cyberpunk_wardrobe_designs/is_valid(value, datum/preferences/preferences)
	return islist(value)

/datum/preference/cyberpunk_business_records
	savefile_key = "cyberpunk_business_records"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_LOADOUT
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/cyberpunk_business_records/deserialize(input, datum/preferences/preferences)
	return cyberpunk_sanitize_persistent_area_records(input)

/datum/preference/cyberpunk_business_records/create_default_value()
	return list()

/datum/preference/cyberpunk_business_records/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/cyberpunk_business_records/is_valid(value, datum/preferences/preferences)
	return islist(value)

/datum/preference/cyberpunk_apartment_records
	savefile_key = "cyberpunk_apartment_records"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	priority = PREFERENCE_PRIORITY_LOADOUT
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/cyberpunk_apartment_records/deserialize(input, datum/preferences/preferences)
	return cyberpunk_sanitize_persistent_area_records(input)

/datum/preference/cyberpunk_apartment_records/create_default_value()
	return list()

/datum/preference/cyberpunk_apartment_records/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/cyberpunk_apartment_records/is_valid(value, datum/preferences/preferences)
	return islist(value)

#undef BODY_SHAPE_AVERAGE
#undef BODY_SHAPE_LEAN
#undef BODY_SHAPE_STOCKY
#undef BODY_SHAPE_SOFT
#undef BODY_SHAPE_ANGULAR
#undef CORP_ALIGN_NONE
#undef CORP_ALIGN_SUN_YON
#undef CORP_ALIGN_ISHIKAWA
#undef CORP_ALIGN_HO_SHI
#undef CORP_ALIGN_KOWALSKI
#undef CORP_ALIGN_TYAZHMARSH
#undef CORP_ALIGN_TESLA_SCIENCE
#undef CORP_ALIGN_BLACKROCK_INVESTIGATE
#undef CORP_ALIGN_TRANS_TRAVEL
#undef CORP_ALIGN_SAMANTHAS_KEIR
#undef CYBERPUNK_PERSISTENT_AREA_MAX_RECORDS
#undef CYBERPUNK_VISUAL_DESIGN_MAX_RECORDS
#undef CYBERPUNK_VISUAL_DESIGN_MAX_PAYLOAD
#undef CORP_GROUP_BEN
#undef CORP_GROUP_RYAZNOV
#undef CORP_GROUP_STARLIGHT
#undef CORP_SYNERGY_EXACT
#undef CORP_SYNERGY_GROUP
