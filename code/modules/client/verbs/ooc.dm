GLOBAL_VAR_INIT(OOC_COLOR, null)//If this is null, use the CSS for OOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_ooc_colour, "#002eb8")

///talking in OOC uses this
/client/verb/ooc(msg as text)
	set name = VERB_OOC

	if(GLOB.say_disabled) //This is here to try to identify lag problems
		to_chat(usr, span_danger("Общение было заблокировано администрацией."))
		return

	var/client_initalized = VALIDATE_CLIENT_INITIALIZATION(src)
	if(isnull(mob) || !client_initalized)
		if(!client_initalized)
			unvalidated_client_error() // we only want to throw this warning message when it's directly related to client failure.

		to_chat(usr, span_warning("Failed to send your OOC message. You attempted to send the following message:\n[span_big(msg)]"))
		return

	if(isnull(holder))
		if(!GLOB.ooc_allowed)
			to_chat(src, span_danger("OOC is globally muted."))
			return
		if(!GLOB.dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, span_danger("OOC for dead mobs has been turned off."))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_danger("You cannot use OOC (muted)."))
			return
	if(is_banned_from(ckey, "OOC"))
		to_chat(src, span_danger("You have been banned from OOC."))
		return
	if(QDELETED(src))
		return

	msg = trim(copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN))
	var/raw_msg = msg

	var/list/filter_result = is_ooc_filtered(msg)
	if (!CAN_BYPASS_FILTER(usr) && filter_result)
		REPORT_CHAT_FILTER_TO_USER(usr, filter_result)
		log_filter("OOC", msg, filter_result)
		return

	// Protect filter bypassers from themselves.
	// Demote hard filter results to soft filter results if necessary due to the danger of accidentally speaking in OOC.
	var/list/soft_filter_result = filter_result || is_soft_ooc_filtered(msg)

	if (soft_filter_result)
		if(tgui_alert(usr,"Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". \"[soft_filter_result[CHAT_FILTER_INDEX_REASON]]\", Are you sure you want to say it?", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[html_encode(msg)]\"")
		log_admin_private("[key_name(usr)] has passed the soft filter for \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\" they may be using a disallowed term. Message: \"[msg]\"")

	if(!msg)
		return

	msg = emoji_parse(msg)

	if(SSticker.HasRoundStarted() && ((msg[1] in list(".",";",":","#")) || findtext_char(msg, "say", 1, 5)))
		if(tgui_alert(usr,"Your message \"[raw_msg]\" looks like it was meant for in game communication, say it in OOC?", "Meant for OOC?", list("Yes", "No")) != "Yes")
			return

	if(!holder)
		if(handle_spam_prevention(msg,MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, span_boldannounce("Advertising other servers is not allowed."))
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return

	if(!(get_chat_toggles(src) & CHAT_OOC))
		to_chat(src, span_danger("You have OOC muted."))
		return

	mob.log_talk(raw_msg, LOG_OOC)
	// BANDASTATION CHAT BADGES REPLACE START
	var/keyname = get_ooc_badged_name()
	/*
	var/keyname = key
	if(prefs.unlock_content)
		if(prefs.toggles & MEMBER_PUBLIC)
			keyname = "<font color='[prefs.read_preference(/datum/preference/color/ooc_color) || GLOB.normal_ooc_colour]'>[icon2html('icons/ui/chat/member_content.dmi', world, "blag")][keyname]</font>"
	if(prefs.hearted)
		var/datum/asset/spritesheet_batched/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
		keyname = "[sheet.icon_tag("emoji-heart")][keyname]"
	*/
	// BANDASTATION CHAT BADGES REPLACE END
	//The linkify span classes and linkify=TRUE below make ooc text get clickable chat href links if you pass in something resembling a url
	for(var/client/receiver as anything in GLOB.clients)
		if(!receiver.prefs) // Client being created or deleted. Despite all, this can be null.
			continue
		if(!(get_chat_toggles(receiver) & CHAT_OOC))
			continue
		if(holder?.fakekey in receiver.prefs.ignoring)
			continue
		var/avoid_highlight = receiver == src
		if(holder)
			if(!holder.fakekey || receiver.holder)
				if(check_rights_for(src, R_ADMIN))
					var/ooc_color = ooc_colour ? ooc_colour : prefs.read_preference(/datum/preference/color/ooc_color)
					to_chat(receiver, span_adminooc("[CONFIG_GET(flag/allow_admin_ooccolor) && ooc_color ? "<font color=[ooc_color]>" :"" ][span_prefix("OOC:")] <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]</span>"), avoid_highlighting = avoid_highlight)
				else
					to_chat(receiver, span_adminobserverooc(span_prefix("OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)
			else
				if(GLOB.OOC_COLOR)
					to_chat(receiver, "<span class='oocplain'><font color='[GLOB.OOC_COLOR]'><b>[span_prefix("OOC:")] <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]</span></b></font></span>", avoid_highlighting = avoid_highlight)
				else
					to_chat(receiver, span_ooc(span_prefix("OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)

		else if(!(key in receiver.prefs.ignoring))
			if(ooc_colour)
				to_chat(receiver, "<span class='oocplain'><font color='[ooc_colour]'><b>[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span></b></font></span>", avoid_highlighting = avoid_highlight)
			else if(GLOB.OOC_COLOR)
				to_chat(receiver, "<span class='oocplain'><font color='[GLOB.OOC_COLOR]'><b>[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span></b></font></span>", avoid_highlighting = avoid_highlight)
			else
				to_chat(receiver, span_ooc(span_prefix("OOC:</span> <EM>[keyname]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)


/proc/toggle_ooc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling ooc
		if(toggle != GLOB.ooc_allowed)
			GLOB.ooc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		GLOB.ooc_allowed = !GLOB.ooc_allowed
	to_chat(world, "<span class='oocplain'><B>The OOC channel has been globally [GLOB.ooc_allowed ? "enabled" : "disabled"].</B></span>")

/proc/toggle_dooc(toggle = null)
	if(toggle != null)
		if(toggle != GLOB.dooc_allowed)
			GLOB.dooc_allowed = toggle
		else
			return
	else
		GLOB.dooc_allowed = !GLOB.dooc_allowed

/client/proc/set_ooc()
	set name = "Set Player OOC Color"
	set desc = "Modifies player OOC Color"
	set category = "Server"
	if(IsAdminAdvancedProcCall())
		return

ADMIN_VERB(set_ooc_color, R_FUN, "Set Player OOC Color", "Modifies the global OOC color.", ADMIN_CATEGORY_SERVER)
	var/newColor = tgui_color_picker(user, "Please select the new player OOC color.", "OOC color")
	if(isnull(newColor))
		return
	var/new_color = sanitize_color(newColor)
	message_admins("[key_name_admin(user)] has set the players' ooc color to [new_color].")
	log_admin("[key_name_admin(user)] has set the player ooc color to [new_color].")
	GLOB.OOC_COLOR = new_color

/client/proc/reset_ooc()
	set name = "Reset Player OOC Color"
	set desc = "Returns player OOC Color to default"
	set category = "Server"
	if(IsAdminAdvancedProcCall())
		return

ADMIN_VERB(reset_ooc_color, R_FUN, "Reset Player OOC Color", "Returns player OOC color to default.", ADMIN_CATEGORY_SERVER)
	if(tgui_alert(user, "Are you sure you want to reset the OOC color of all players?", "Reset Player OOC Color", list("Yes", "No")) != "Yes")
		return
	message_admins("[key_name_admin(user)] has reset the players' ooc color.")
	log_admin("[key_name_admin(user)] has reset player ooc color.")
	GLOB.OOC_COLOR = null

//Checks admin notice
/client/verb/admin_notice()
	set name = "Adminnotice"
	set category = "Admin"
	set desc = "Check the admin notice if it has been set"

	if(GLOB.admin_notice)
		to_chat(src, "[span_boldnotice("Admin Notice:")]\n \t [GLOB.admin_notice]")
	else
		to_chat(src, span_notice("There are no admin notices at the moment."))

/client/verb/motd()
	set name = "MOTD"
	set category = "OOC"
	set desc ="Check the Message of the Day"

	var/motd = global.config.motd
	if(motd)
		to_chat(src, "<span class='infoplain'><div class=\"motd\">[motd]</div></span>", handle_whitespace=FALSE)
	else
		to_chat(src, span_notice("The Message of the Day has not been set."))

/client/verb/codex()
	set name = "КОДЕКС"
	set category = "OOC"
	set desc = "Открыть внутреннюю энциклопедию"

	if(!mob)
		return
	var/static/datum/codex/codex = new
	codex.ui_interact(mob)

/datum/codex
	var/static/list/codex_entries

/datum/codex/ui_state()
	return GLOB.always_state

/datum/codex/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Codex", "КОДЕКС")
		ui.open()

/datum/codex/ui_static_data(mob/user)
	return list(
		"blocks" = get_codex_entries(),
	)

/datum/codex/proc/get_codex_entries()
	if(codex_entries)
		return codex_entries

	codex_entries = list(
		list(
			"id" = "general_controls",
			"title" = "Общее управление",
			"items" = list(
				list(
					"id" = "general_mouse",
					"title" = "Мышь",
					"sections" = list(
						list(
							"title" = "Базовые клики",
							"body" = "- **LMB** — базовое действие: взять предмет, снять, открутить, использовать основной интеракт.\n- **RMB** — вторичное действие: дать, поставить, прикрутить, использовать вторичный интеракт.\n- **MMB** — специальное действие или подготовка/выпуск выбранного демона.\n- **X** — только сменить активную руку.\n\n**Эффект:** вне боя эти клики сначала ищут специальное действие объекта, затем падают в обычные интеракты."
						),
						list(
							"title" = "Модификаторы",
							"body" = "- **Shift+LMB** — рассмотреть человека или объект; на краю — посмотреть вниз.\n- **Shift+RMB** — открыть контекстное меню.\n- **Shift+MMB** — присмотреться вдаль; на персонаже — посмотреть наверх или прислушаться при удержании.\n- **Alt+LMB** — дополнительное базовое действие.\n- **Alt+RMB** — дополнительное вторичное действие.\n- **Alt+MMB** — изучить груду.\n- **Ctrl+LMB** — захват или усиление захвата.\n- **Ctrl+RMB** — указать на цель.\n- **Ctrl+MMB** — снять указание.\n\n**Эффект:** Alt-действия тратят больше стамины, если переходят в боевой альтернативный удар."
						),
						list(
							"title" = "Речь и OOC",
							"body" = "- **T** — говорить.\n- **Shift+T** — шепот.\n- **Y** — гарнитурное сообщение.\n- **L** — локальный OOC.\n- **O** — общий OOC.\n- **TAB** — переключить режим/канал речи персонажа.\n\n**Эффект:** TAB меняет то, как персонаж говорит, без открытия отдельного окна."
						),
						list(
							"title" = "Прочие клавиши",
							"body" = "- **Shift** — бег, пока клавиша удерживается.\n- **C** — бросить перенос.\n- **R** — приготовиться бросать.\n- **M** — действие.\n- **Q** — активация предмета в руке.\n- **Z** — уронить из рук.\n- **1-4 / F** — переключить боевой интент.\n- **Shift+Alt+H** — сдаться.\n\n**Эффект:** бег расходует стамину за движение; при истощении персонаж замедляется и может сорваться с бега."
						),
						list(
							"title" = "Выбор зоны",
							"body" = "- **Numpad1** — правая нога.\n- **Numpad2** — пах.\n- **Numpad3** — левая нога.\n- **Numpad4** — правая рука.\n- **Numpad5** — торс/грудь.\n- **Numpad6** — левая рука.\n- **Numpad7** — цикл нос/рот.\n- **Numpad8** — цикл голова/шея.\n- **Numpad9** — цикл глаза/уши.\n\n**Эффект:** выбранная зона влияет на удары, операции и специальные захваты. Для захватов за торс выбранная зона определяет, какой точный прием будет выполнен."
						),
					),
				),
				list(
					"id" = "general_movement",
					"title" = "Перемещение",
					"sections" = list(
						list(
							"title" = "Ходьба и бег",
							"body" = "- **Клавиши движения** — ходьба в выбранном направлении.\n- **Shift** — бег, пока клавиша удерживается.\n\n**Эффект:** ходьба не имеет прямой цены стамины за шаг. Бег расходует стамину за движение; при низкой стамине персонаж замедляется, при истощении срывается с бега, а столкновение с плотной преградой на бегу сбивает с ног."
						),
						list(
							"title" = "Прыжок",
							"body" = "- **Shift+J** — прыгнуть вперед по направлению взгляда.\n\n**Эффект:** прыжок требует стоять, не быть пристегнутым, не быть обездвиженным и иметь достаточно стамины. Обычный прыжок летит до двух клеток, беговой прыжок — до трех. Прыжок может перелетать climbable-преграды; при прокачанной акробатике может перелетать плотные живые цели. Столкновение при прыжке отбрасывает назад, если есть место, и сбивает с ног."
						),
						list(
							"title" = "Перелезание",
							"body" = "- **Перетянуть себя на climbable-объект** — перелезть или залезть на него.\n\n**Эффект:** перелезание преодолевает объект на текущей плоскости: стол, заборчик, рейлинг или похожую преграду. Оно запускает действие с задержкой, тратит стамину перед началом и ускоряется акробатикой. Это не вертикальное лазание."
						),
						list(
							"title" = "Вертикаль",
							"body" = "- **Move Upwards** — двигаться вверх по Z-уровню.\n- **Move Down** — двигаться вниз по Z-уровню.\n\n**Эффект:** если на тайле есть лестница, используется она. Иначе проверяется обычный Z-переход с короткой задержкой. При висении или карабканье вдоль вертикальной опоры движение вверх, вниз и вдоль опоры требует валидную соседнюю опору, свободную целевую клетку и задержку, уменьшаемую акробатикой."
						),
					),
				),
			),
		),
		list(
			"id" = "combat_controls",
			"title" = "Боевое управление",
			"items" = list(
				list(
					"id" = "combat_attacks",
					"title" = "Атаки",
					"sections" = list(
						list(
							"title" = "Обычные удары",
							"body" = "- **LMB** — удар предметом или рукой, интент slash.\n- **Зажать LMB** — charged chop.\n- **RMB** — удар предметом, интент stab; без оружия — толкание.\n- **Зажать RMB** — пинок.\n- **MMB** — специальное действие или демон.\n\n**Эффект:** обычные атаки проходят через текущую систему защиты цели: уклонение, парирование, блок и броню."
						),
						list(
							"title" = "Обход защиты",
							"body" = "- **Alt+LMB** — быстрый удар: готовится для обхода уклонения.\n- **Alt+RMB** — хитрый удар: готовится для обхода парирования.\n\n**Эффект:** если цель пытается соответствующую защиту, атака прерывает ее попытку. Такие удары расходуют больше стамины."
						),
						list(
							"title" = "Пинок",
							"body" = "- **Зажать RMB** в боевом режиме без оружия — пинок.\n\n**Эффект:** пинок толкает цель и пошатывает самого пинающего. Если цель уже пошатывается, успешный пинок роняет ее. При силе **10+** успешный пинок запускает цель на две клетки."
						),
					),
				),
				list(
					"id" = "combat_defense",
					"title" = "Защита",
					"sections" = list(
						list(
							"title" = "Повтор защиты",
							"body" = "- **Space** — повторить последнее защитное действие.\n\n**Эффект:** повтор запускается только после отжатия клавиши, чтобы удержание Space не сжигало стамину повторными срабатываниями."
						),
						list(
							"title" = "Парирование",
							"body" = "- **Space+LMB** — подготовить парирование.\n\n**Эффект:** парирование блокирует часть входящих атак. Против него предназначен хитрый удар через **Alt+RMB**."
						),
						list(
							"title" = "Уклонение",
							"body" = "- **Space+RMB** — подготовить уклонение.\n\n**Эффект:** при успехе урон и эффект атаки полностью игнорируются. Персонаж мгновенно смещается на свободную соседнюю клетку рядом с атакующим: сначала в сторону от линии атаки, затем от противника, затем в любую доступную соседнюю клетку. Направление взгляда при этом не меняется. Против уклонения предназначен быстрый удар через **Alt+LMB**."
						),
					),
				),
			),
		),
		list(
			"id" = "grapples",
			"title" = "Захваты",
			"items" = list(
				list(
					"id" = "grapple_basics",
					"title" = "База захвата",
					"sections" = list(
						list(
							"title" = "Взять и усилить",
							"body" = "- **Ctrl+LMB** по цели — взять в захват.\n- **Ctrl+LMB** по удерживаемой цели — усилить захват.\n\n**Эффект:** усиленный хват считается агро-хватом. Зона захвата сохраняется отдельно от выбранной зоны тела."
						),
						list(
							"title" = "Указать",
							"body" = "- **Ctrl+RMB** — указать на цель.\n- **Ctrl+MMB** — снять указание.\n\n**Эффект:** указание используется для команд боевой кукле и обычного point-to. Повторное указание по кукле переключает ее атаку."
						),
						list(
							"title" = "Две цели",
							"body" = "- При удержании одной цели **RMB** по другой живой цели — ударить их лбами.\n\n**Эффект:** обе цели получают удар головой, стамина-урон и пошатывание. Доступно всегда при агро-хвате."
						),
					),
				),
				list(
					"id" = "aggressive_grab",
					"title" = "Агро-хват",
					"sections" = list(
						list(
							"title" = "Правило зон",
							"body" = "- **RMB** по удерживаемой цели в агро-хвате — выполнить особый прием выбранной зоны.\n\n**Эффект:** если вы держите конкретную зону, выбранная зона должна совпадать с ней. Если держите торс, выбранная зона определяет эффект. Пример: агро-хват за ногу + выбрана нога дает подсечку; агро-хват за торс + выбрана нога тоже дает подсечку; агро-хват за ногу + выбрана рука ничего не делает."
						),
						list(
							"title" = "Конечности",
							"body" = "- Выбрана **нога** — подсечка, цель падает.\n- Выбрана **рука** — залом, цель роняет предмет.\n\n**Эффект:** эти приемы требуют второго перка точного стиля или full unlock."
						),
						list(
							"title" = "Голова",
							"body" = "- Выбрана **голова** — сжать для боли.\n- Выбраны **глаза** — тыкнуть для ослепления.\n- Выбраны **уши** — тыкнуть для глухоты.\n- Выбран **рот** — потянуть язык для боли.\n- Выбрана **шея** — прием по шее; если доступен силовой прием, **RMB** с выбранной шеей выполняет удар позвоночником об колено.\n\n**Эффект:** точные приемы головы требуют второго перка точного стиля или full unlock; перелом/удар позвоночником требует второго перка силового стиля или full unlock."
						),
						list(
							"title" = "Торс",
							"body" = "- Выбран **торс** — попытка взять на руки при агро-хвате.\n- **RMB** по пустому пространству при агро-хвате — рестлинг-запуск, если доступен второй перк захватов или full unlock.\n- **RMB** по стулу, столу или кровати при удержании конечности — ударить удерживаемой конечностью мебель.\n\n**Эффект:** мебельный удар доступен всегда. Рестлинг-запуск требует второго перка захватов или full unlock."
						),
					),
				),
				list(
					"id" = "two_handed_grab",
					"title" = "Хват двумя руками",
					"sections" = list(
						list(
							"title" = "Двуручный хват",
							"body" = "- Два обычных хвата одной цели — хват двумя руками.\n- Из хвата двумя руками можно кидать человека без требования держать шею.\n\n**Эффект:** цель удерживается обеими руками. Часть приемов требует конкретной выбранной зоны."
						),
						list(
							"title" = "Шея",
							"body" = "- **LMB** при хвате за шею — душить, доступно всегда.\n- **RMB** при выбранной шее — ударить позвоночником об колено, если доступен второй перк силового стиля или full unlock.\n- **MMB** также пытается выполнить удар позвоночником об колено.\n\n**Эффект:** цель получает стан и стамина-урон; применивший получает пошатывание, и есть высокий шанс отпустить захват."
						),
						list(
							"title" = "Суплекс",
							"body" = "- **RMB** по удерживаемой цели при двуручном хвате за торс и выбранном торсе — немецкий суплекс.\n\n**Эффект:** цель бросается за спину атакующего, падает и получает стамина-урон. Живой щит вынесен на RMB-перетаскивание и не конфликтует с этим кликом."
						),
						list(
							"title" = "Обрушение",
							"body" = "- **RMB** при двуручном хвате за шею без выбранной шеи — обрушить цель на землю за собой, развернувшись.\n\n**Эффект:** оба падают, цель получает урон и стамина-урон. Требует второго перка захватов или full unlock."
						),
					),
				),
			),
		),
		list(
			"id" = "dragging",
			"title" = "Перетаскивания",
			"items" = list(
				list(
					"id" = "normal_dragging",
					"title" = "Обычные",
					"sections" = list(
						list(
							"title" = "На себя",
							"body" = "- **Перетянуть себя LMB** — сесть или пристегнуться.\n- **Перетянуть на себя RMB** — предложить понести человека на руках или плече.\n- **Перетянуть себя RMB** — попросить человека понести вас.\n- **Перетянуть себя MMB** — ERP.\n\n**Эффект:** эти действия не являются боевыми приемами захвата сами по себе."
						),
						list(
							"title" = "Живой щит",
							"body" = "- При агро-хвате **RMB-перетаскивание удерживаемой цели на себя** — сделать живой щит.\n\n**Эффект:** цель закрепляется на персонаже стоя и занимает руку через offhand-захват, пока ее не отпустят."
						),
					),
				),
				list(
					"id" = "stealth_dragging",
					"title" = "Скрытность",
					"sections" = list(
						list(
							"title" = "Прижаться к стене",
							"body" = "- **Перетянуть себя на тайл LMB** — вжаться в стену.\n\n**Эффект:** в скрытности повышает хамелеон, замедляет движение и сбрасывает бег. Если рядом в направлении опоры продолжается стена, персонаж движется вдоль нее; при упоре может сменить сторону зацепа."
						),
						list(
							"title" = "Под мебель",
							"body" = "- В скрытности и лежа **перетянуть себя на стул, стол или кровать** — залезть под мебель.\n\n**Эффект:** персонаж прячется под спрайт и получает хамелеон. Для стеклянных столов скрытное залезание обходит механику ломания."
						),
					),
				),
				list(
					"id" = "combat_dragging",
					"title" = "Боевые",
					"sections" = list(
						list(
							"title" = "В мебель",
							"body" = "- В бою **перетянуть человека на стул, стол или кровать** — швырнуть туда человека.\n\n**Эффект:** цель получает жесткое столкновение, падение или стамина-урон в зависимости от объекта и состояния захвата."
						),
						list(
							"title" = "Перелезание",
							"body" = "- Перетянуть себя на climbable-объект — перелезть или залезть на него.\n\n**Эффект:** перелезание преодолевает объект на текущей плоскости: стол, заборчик или похожую преграду. Это не вертикальное лазание."
						),
					),
				),
			),
		),
		list(
			"id" = "medicine_cp13",
			"title" = "Медицина CP13",
			"items" = list(
				list(
					"id" = "medicine_health",
					"title" = "Здоровье",
					"sections" = list(
						list(
							"title" = "Общее состояние",
							"body" = "- У живых мобов есть **Health** и **Max Health**. Обычный человек стартует со 100/100.\n- Health считается поверх накопленных типов повреждений: blunt/brute, burn/fire, toxin, oxygen, brain и stamina.\n- Статус цели меняется отдельно: conscious, soft crit, unconscious или dead.\n\n**Эффект:** проценты здоровья в сканере — это быстрый индикатор, но причина плохого состояния всегда лежит в конкретных повреждениях, органах, крови, дыхании, боли или температуре."
						),
						list(
							"title" = "Типы урона",
							"body" = "- **Brute / blunt, pierce, slash** — физический урон по телу и зонам.\n- **Burn / heat, cold, acid** — термический и кислотный урон.\n- **Toxin** — отравления и химические повреждения.\n- **Oxygen** — удушье, кровопотеря, проблемы дыхания.\n- **Brain** — повреждение мозга и нейронагрузка.\n- **Stamina** — стресс и боевое истощение, обычно роняет раньше, чем убивает.\n\n**Эффект:** лечение подбирается по причине. Общая полоска здоровья не заменяет лечение крови, органов, ран и реагентов."
						),
						list(
							"title" = "Кукла здоровья",
							"body" = "- Медицинский HUD и кукла здоровья обновляются при изменении здоровья и статуса.\n- У отдельных мобов может быть свой `health_doll_icon`, но базовая логика одна: показать состояние тела и предупредить о критическом статусе.\n- Кукла не является полным диагнозом и не показывает всю глубину CP13-повреждений.\n\n**Эффект:** используйте куклу как быстрый визуальный сигнал, а не как замену сканеру. Для точного диагноза нужен health analyzer или медицинская программа."
						),
					),
				),
				list(
					"id" = "medicine_scanning",
					"title" = "Сканирование",
					"sections" = list(
						list(
							"title" = "Базовый скан",
							"body" = "- Health Analyzer в CP13 вызывает `cyberpunk_healthscan`.\n- Базовый отчет показывает статус, Health/Max Health, brute, burn, toxin, oxygen, отсутствие мозгового сигнала и stamina stress.\n- Для карбонов дополнительно выводятся physical BLUNT/PIERCE/SLASH, thermal HEAT/COLD/ACID, oxygenation, blood pressure, pain и infection.\n\n**Эффект:** если пациент жив, но быстро падает, смотрите не только Health: низкая кислородность, давление, боль, инфекция и кровопотеря могут быть главной проблемой."
						),
						list(
							"title" = "Глубина скана",
							"body" = "- **Basic** — общий отчет по состоянию.\n- **Advanced** — зоны тела, отсутствующие конечности, повреждения, боль, инфекции, травмы и органы.\n- **Bioscanner** — раны, подробные значения органов и химический отчет.\n\n**Эффект:** глубина скана может повышаться навыками и доступом. Чем выше глубина, тем меньше приходится гадать по симптомам."
						),
						list(
							"title" = "Органы и раны",
							"body" = "- Advanced-скан перечисляет органы с integrity, efficiency и флагом FAILING.\n- Bioscanner показывает боль, damage/maxHealth, wounds и реагенты.\n- Проколы легких выводятся отдельно.\n\n**Эффект:** при нормальном общем Health пациент все еще может умирать от отказа органа, прокола легких, химии или глубокой раны."
						),
					),
				),
				list(
					"id" = "medicine_cp13_branch_logic",
					"title" = "Логика медицины CP13",
					"sections" = list(
						list(
							"title" = "Health и пороги",
							"body" = "- У человека базовый MaxHealth обычно равен 100, но состояние карбона теперь определяется не одной полосой Health, а отдельными накопителями физического, кислородного и токсического урона.\n- Физический крит: 100 physical damage переводит в softcrit, 200 physical damage — в hardcrit/потерю сознания, 300 physical damage — смерть.\n- Кислород: 70 oxy loss валит с ног, 120 oxy loss считается oxygen hardcrit, 200 oxy loss убивает.\n- Токсины: 100 toxin damage — softcrit, 200 toxin damage — hardcrit, 300 toxin damage — смерть.\n- Chemical loss из медицинских сводок убран: химия теперь проявляется через реагенты, токсины, органы и системные эффекты.\n\n**Эффект:** пациент может выглядеть не смертельно по общей полосе, но быть в критическом состоянии из-за кислорода, токсинов, крови, давления, боли, инфекции или отказа органа."
						),
						list(
							"title" = "Кровь и оксигенация",
							"body" = "- Целевая оксигенация карбона складывается из доли крови от нормы, эффективности легких, доставки сердца, кровяного давления и системного множителя.\n- Норма крови для расчета — 560 единиц. Потеря крови режет транспорт кислорода, даже если легкие целы.\n- В hardcrit запускается обрушение циркуляции: за 60 секунд доставка кислорода сердцем падает до тяжелого состояния.\n- Низкая оксигенация поднимает oxy loss; при росте oxy loss тело получает замедление, доходя до полного медицинского штрафа к 70 oxy loss.\n\n**Эффект:** лечить удушье только кислородом недостаточно, если проблема в крови, сердце, давлении или пробитых легких."
						),
						list(
							"title" = "Раны, боль и инфекция",
							"body" = "- Физический урон делится на BLUNT, PIERCE и SLASH. Термический урон делится на HEAT, COLD и ACID.\n- Органы получают повреждения через травмы тела и собственные обработчики. Импланты как органы не восстанавливаются естественно так же, как живая ткань.\n- Инфекция хранится по частям тела. Выше 50 она начинает давать токсический урон, с 60 может мешать конечности, а при 100 распространяется на другие части тела.\n- Базовое лечение снижает инфекцию ограниченно, хирургическая обработка раны способна снять более глубокое заражение.\n- Боль влияет на хирургию: каждые 5 боли добавляют шанс провала операции.\n\n**Эффект:** медицинский план должен смотреть не только на тип урона, но и на раны, боль, инфекцию, органы и путь попадания веществ."
						),
						list(
							"title" = "Диагностика",
							"body" = "- Health Analyzer вызывает CP13-скан и показывает Health/MaxHealth, brute, burn, toxin, oxygen, brain signal, stamina, физические/термические компоненты, оксигенацию, давление, боль и инфекцию.\n- Advanced-скан раскрывает зоны тела, отсутствующие конечности, боль, инфекции, травмы и органы.\n- Bioscanner дает более глубокие сведения по ранам, органам и химическому состоянию.\n- Medical Kiosk показывает состояние тела и органов отдельными вкладками: кислород, давление, боль, инфекция, физический и термический урон.\n\n**Эффект:** кукла здоровья — только быстрый визуальный сигнал. Полный диагноз требует сканера, киоска, биосканера или ручного осмотра."
						),
					),
				),
				list(
					"id" = "medicine_cp13_implant_gene_logic",
					"title" = "Импланты, гены и нейросеть",
					"sections" = list(
						list(
							"title" = "Работа имплантов",
							"body" = "- CP13-импланты как органы проверяют владельца, смерть владельца, поломку, EMP-статус, временное отключение и наличие нейроимпланта, если конкретный имплант требует нейроинтерфейс.\n- Пассивные импланты могут работать без нейроинтерфейса. Активный хром и legacy-импланты с флагом neural interface требуют рабочий мозг и нейросвязь.\n- EMP отключает требующие нейроинтерфейс импланты на 1 минуту. Перегрев может отключать имплант на 30 секунд.\n- Внешние импланты принимают 75% входящего урона конечности, а конечность получает оставшиеся 25%. Если имплант сломан или отключен, защита не работает.\n- Ремонт импланта сбрасывает повреждения и перенастраивает его. Перенастройка снимает EMP/временное отключение без полного ремонта.\n\n**Эффект:** вопрос не только в том, вставлен ли имплант. Он должен быть цел, включен, совместим с мозгом и не заблокирован EMP, перегревом или отсутствием нейроинтерфейса."
						),
						list(
							"title" = "Слоты и установка",
							"body" = "- Система рассчитана на установку имплантов в конечности, позвоночник, сердце, легкие, желудок, печень, живот, грудь, шею, череп, мозг, глаза, уши, язык, челюсть, веки и слот нейроинтерфейса.\n- Внутренние импланты проходят через манипуляции органов. Внешние импланты и особенности тела проходят через отдельные хирургические действия.\n- Стальные, биотические и иные пассивные протезы могут не иметь перегрева и не требовать нейроинтерфейс, если это задано их флагами.\n\n**Эффект:** слот, тип импланта и его флаги важнее общей фразы \"есть хром\". Один имплант может быть простой заменой ткани, другой — активным сетевым устройством."
						),
						list(
							"title" = "Хромит и перегрев",
							"body" = "- Chromity — безопасная емкость тела под хром. Chromity Overheat — текущая нагрузка от имплантов, сетевых эффектов и активных способностей.\n- Если overheat выше effective chromity, система может выдать боль, временно отключить импланты, ошибочно активировать хром или нанести урон мозгу.\n- Охлаждение, холодовые эффекты и профильные медикаменты могут снижать перегрев. Иммуноподавляющие препараты также используются в связке с гуманоидностью и переносимостью хрома.\n- Effective chromity режется гуманоидностью: от 90 до 40 гуманоидности множитель падает линейно, на 40 и ниже емкость по гуманоидности становится нулевой.\n\n**Эффект:** генетика напрямую ограничивает безопасный объем хрома. Чем ниже гуманоидность, тем опаснее любой активный имплант."
						),
						list(
							"title" = "Гуманоидность и ДНК",
							"body" = "- CP13 использует существующие TG/Banda `/datum/dna`, `/datum/mutation`, DNA console, scanner, injector, chromosomes и infuser, а не отдельную параллельную генетику.\n- Базовая гуманоидность — 100. На эффективное значение влияют постоянный генетический штраф, нагрузка мутаций, временная стабилизация и совместимость биотеха.\n- DNA infuser тратит гуманоидность на органические, видовые и биомодификационные изменения. Стоимость записи не ниже `(tier + 1) * 5`.\n- Advanced DNA injector ограничен максимальной нагрузкой гуманоидности 50.\n- Genetic damage может оставлять постоянный шрам гуманоидности. Иммуноподавление временно дает стабилизирующий буфер и замедляет его спад.\n\n**Эффект:** косметические и слабые изменения дешевле, но сильные мутации, инфузии и органические переделки постепенно съедают способность тела оставаться человеком и переносить хром."
						),
						list(
							"title" = "Вицероид и опухоль",
							"body" = "- При падении эффективной гуманоидности до нуля тело может пройти forced humanoidity collapse и породить вицероида.\n- Вицероид имеет 260 здоровья, враждебен, атакует органические цели и проглатывает цели в softcrit, сне или бессознательном состоянии.\n- Проглоченная живая цель обычно умирает внутри вицероида. За каждую жертву вицероид получает +25 maxHealth и лечится на 50.\n- Исходное тело при превращении не убивается сразу: оно поглощается как origin и остается бессознательным 10 минут.\n- При гибели вицероида проглоченные тела выпускаются. Origin-тело и жертвы, пробывшие внутри 15 минут, получают genetic tumor.\n- Опухоль после спячки 10 минут растет 2 минуты до следующего превращения; стадия тяжести пересчитывается с интервалом 5 минут. Пока носитель мертв или находится внутри вицероида, рост не идет.\n\n**Эффект:** генетическая опухоль — это отложенный цикл повторного коллапса, а вицероид — активная угроза, которая переносит проблему на новых носителей."
						),
						list(
							"title" = "Нейроинтерфейс",
							"body" = "- Нейроинтерфейс занимает `ORGAN_SLOT_NEURAL_IMPLANT` и работает только при живом, не отказавшем мозге.\n- Он является связью между мозгом, skillchip bridge, хромом, ICE, корпоративными ключами и сетевыми проверками.\n- ICE дает штраф к effective chromity. Легальный ключ может обходить ICE, иначе открывается hack session против защиты интерфейса.\n- CQC-имплант и другие legacy-импланты с `requires_neural_interface` не активируются без нейроинтерфейса.\n- Интерфейс навыков теперь опирается на доступы и очки: может показывать эффективные максимумы, суперпороги, атрибуты, перки, skill points и перевод level points в skill points.\n\n**Эффект:** нейроинтерфейс — это не украшение, а центральное условие для активного хрома, скиллчипов, сетевой защиты и части боевых возможностей."
						),
					),
				),
				list(
					"id" = "medicine_implants",
					"title" = "Импланты",
					"sections" = list(
						list(
							"title" = "Киберимпланты",
							"body" = "- CP13-киберимпланты — это органы `/obj/item/organ/cyberimp`.\n- У имплантов есть слот, tier, manufacturer, состояние damage/maxHealth и базовая `chromity_overheat`.\n- Большинство имплантов требуют функциональный нейроинтерфейс, кроме самого нейроинтерфейса.\n\n**Эффект:** поврежденный или отключенный имплант может перестать отвечать. Медицинская диагностика имплантов смотрит функциональность, tier, корпорацию, хромит-нагрузку и активность."
						),
						list(
							"title" = "Хромит",
							"body" = "- **Chromity** — безопасная емкость тела под хром.\n- **Chromity Overheat** — текущий перегрев от имплантов, сетевых эффектов и активных способностей.\n- **Overheat floor** — минимальный перегрев, который поддерживают активные импланты.\n- Effective chromity повышается совместимостью и духом, меняется гуманоидностью и снижается ICE-штрафом нейроинтерфейса.\n\n**Эффект:** когда overheat выше effective chromity, нейроинтерфейс может давать боль мозга, отключать импланты, ошибочно активировать хром или наносить brain damage."
						),
						list(
							"title" = "Киберпсихоз",
							"body" = "- Киберпсихоз проверяется при низком mood и перегреве выше доли effective chromity.\n- При срабатывании персонаж получает brain damage, hallucination, jitter, confusion и временную потерю контроля.\n- Тело включает combat mode, получает иммунитет к стану и сну, ищет ближайшую живую цель и может само переключать активные импланты.\n\n**Эффект:** высокий хром без контроля настроения и перегрева превращает медицинскую проблему в боевую угрозу."
						),
					),
				),
				list(
					"id" = "medicine_neural_interface",
					"title" = "Нейроинтерфейс",
					"sections" = list(
						list(
							"title" = "Условие работы",
							"body" = "- Нейроинтерфейс занимает слот `ORGAN_SLOT_NEURAL_IMPLANT`.\n- Он функционален только при живом мозге: мозг должен существовать, не быть failing и иметь damage ниже maxHealth.\n- Сам нейроинтерфейс имеет `chromity_overheat = 0` и способен саморемонтироваться, превращая ремонт в боль.\n\n**Эффект:** без живого мозга и рабочего нейроинтерфейса тело не считается валидной сетевой целью и большинство хрома не должно работать штатно."
						),
						list(
							"title" = "ICE и ключи",
							"body" = "- Нейроинтерфейс генерирует cryptographic key и хранит личный datum ICE.\n- Корпоративный производитель переводит ICE в corporate model; independent использует basic.\n- Легальный ключ может обойти ICE, иначе открывается hack session против ICE.\n- ICE дает chromity penalty, который вычитается из effective chromity.\n\n**Эффект:** чем тяжелее защита интерфейса, тем дороже она для хромит-емкости тела. Корпоративные эдикты могут смягчать штрафы и таймеры."
						),
						list(
							"title" = "Скиллчипы",
							"body" = "- Действие нейроинтерфейса открывает neural skillchip bridge.\n- Если в активной руке есть skillchip, интерфейс пытается вставить и активировать его.\n- Если рука пустая, интерфейс предлагает вынуть установленный skillchip из мозга.\n\n**Эффект:** нейроинтерфейс является мостом между мозгом, навыками, хромом, памятью и сетью, а не просто еще одним имплантом."
						),
					),
				),
				list(
					"id" = "medicine_genes",
					"title" = "Гены",
					"sections" = list(
						list(
							"title" = "ДНК и гуманоидность",
							"body" = "- У карбонов ДНК участвует в CP13-стабилизации гуманоидности во время life processing.\n- Гуманоидность влияет на effective chromity через `get_humanoidity_chromity_multiplier`.\n- В киберпространстве уже зарезервированы payload-типы `mutation` и `gene_sequence` для будущего генетического обмена данными.\n\n**Эффект:** генетика в CP13 связана не только с внешностью: она влияет на переносимость хрома и подготовлена к сетевым данным мутаций."
						),
						list(
							"title" = "Генетическая опухоль",
							"body" = "- `genetic tumor` — органическая опухоль в голове, оставленная visceroid collapse.\n- Она вставляется как орган, процессится в SSobj, имеет dormancy, growth и severity stage до 3.\n- Пока носитель мертв, опухоль не растет. Внутри visceroid она тоже не прогрессирует.\n- Когда growth достигает порога, у человека запускается принудительный humanoidity collapse.\n\n**Эффект:** генетическая опухоль — отложенная угроза, а не обычная рана. Ее надо искать как органическую проблему головы до завершения роста."
						),
						list(
							"title" = "Стабилизация",
							"body" = "- Основная безопасная работа с генетикой сейчас идет через гуманоидность, совместимость, временную стабилизацию и снижение нагрузки мутаций.\n- Генетическая опухоль не является обычной раной: она находится в органном слоте, обрабатывается как отдельный органический риск и после роста запускает forced humanoidity collapse.\n- Рост опухоли не идет, пока носитель мертв или находится внутри вицероида.\n\n**Эффект:** если нужно остановить цикл коллапса, лечить надо причину потери гуманоидности и саму опухоль как органическую проблему, а не просто закрывать симптомы."
						),
					),
				),
				list(
					"id" = "medicine_combat_doll",
					"title" = "Боевая кукла",
					"sections" = list(
						list(
							"title" = "Создание",
							"body" = "- IC-verb **Боевая кукла** доступен живому персонажу.\n- Команда удаляет старую куклу клиента и создает новую перед персонажем или у его ног.\n- Кукла привязывается к владельцу и слушает его указание.\n\n**Эффект:** это тренировочная цель для проверки атак и защит, а не медицинский пациент."
						),
						list(
							"title" = "Управление",
							"body" = "- **Указать на куклу** — запустить или остановить ее цикл атаки.\n- **Обнять/кликнуть рукой без боевого режима** — переключить режим.\n- Кукла подходит к владельцу, смотрит на него и выполняет выбранный режим раз в короткий цикл.\n\n**Эффект:** используйте ее для проверки stab/slash, charged pierce/chop, обхода parry/dodge, dodge и parry."
						),
						list(
							"title" = "Режимы",
							"body" = "- Простые удары: stab.\n- Charged pierce.\n- Простые удары: slash.\n- Charged chop.\n- Хитрый удар против парирования.\n- Быстрый удар против уклонения.\n- Уклонение.\n- Парирование.\n\n**Эффект:** кукла помогает проверить боевую медицину на практике: какие травмы оставляют разные атаки, что видно на сканере и как быстро цель теряет stamina или здоровье."
						),
					),
				),
			),
		),
		list(
			"id" = "kp13_objects",
			"title" = "КП13: Объекты",
			"items" = list(
				list(
					"id" = "kp13_structures",
					"title" = "Структуры",
					"sections" = list(
						list(
							"title" = "Роль",
							"body" = "- **Структуры** — размещаемые объекты мира: мебель, барьеры, станции обслуживания, медицинские установки, свет, контейнеры и похожие стационарные точки.\n- Легкая мобильная структура может быть сложена в предмет, перенесена в инвентаре и снова разложена.\n- Тяжелая структура не предназначена для переноски в руках: ее надо ставить, двигать как объект мира или фиксировать инструментом.\n\n**Эффект:** структуры закрывают физическое оформление сцены и дают профессиям точки работы, а не являются просто декором."
						),
						list(
							"title" = "Складные структуры",
							"body" = "- Реализованы складные варианты: столик, печь, микроволновка, концертная колонка JBL-типа, мехстанция, барьеры, биосканеры, операционные столы, каталки, кресла-каталки, лампы, хим-диспенсеры, бензиновый генератор, холодильник и стазис-кровать.\n- Старые переносные объекты переведены в ту же категорию, если они работают как структура после раскладки.\n- Складной предмет не требует батареи сам по себе: питание нужно только самой рабочей машине, если ее логика этого требует.\n\n**Эффект:** складные структуры дают быстрый полевой сетап без модульности и поэтому не заменяют полноценные стационарные версии."
						),
						list(
							"title" = "Контекст и навыки",
							"body" = "- Контекстные подсказки показывают доступные действия: закрепить, открепить, разложить, сложить, разобрать или обслужить.\n- Действия с инструментами и фиксацией выдают опыт по профессиональным навыкам: строительство, изобретательство, электрика, медицина или химия в зависимости от категории структуры.\n- Унификация идет через категорию структуры, а не через копирование отдельных проверок в каждый объект.\n\n**Эффект:** игрок должен понимать действие из подсказки, а профессия получает опыт за реальные точки своей работы."
						),
					),
				),
				list(
					"id" = "kp13_machinery",
					"title" = "Механизмы",
					"sections" = list(
						list(
							"title" = "База механизма",
							"body" = "- **Механизм** — рабочая машина с состоянием, панелью, обслуживанием, диагностикой, питанием и возможными модулями.\n- Машина может иметь слоты под механизмы, принимать совместимые модули, показывать статус и учитывать износ.\n- Панель открывается инструментом, после чего доступны установка, снятие, ремонт и проверка.\n\n**Эффект:** механизмы должны быть обслуживаемыми объектами, а не черными ящиками с одним кликом."
						),
						list(
							"title" = "Модули",
							"body" = "- Общие модули дают резерв питания, буфер износа, усиленную раму, сервисную шину и утилизацию.\n- Специализированные модули работают для химии, производства, медицины, безопасности, сетевых машин, дверей, зарядников, камер, турелей, торговых автоматов и генераторов.\n- У техники тоже есть слоты под механизмы, но лимит зависит от корпуса и ходовой части.\n\n**Эффект:** модульность усиливает стационарки и технику точечно, без превращения каждого складного предмета в модульную копию."
						),
						list(
							"title" = "Питание и генераторы",
							"body" = "- Энергосистема поддерживает обычные, бензиновые и более тяжелые КП13-генераторы.\n- Бензиновый генератор работает как обычный генератор, но требует горючее через топливную логику.\n- Состояние, нагрев, износ и качество обслуживания влияют на полезный выход.\n\n**Эффект:** генератор является источником инфраструктуры, а топливо и обслуживание становятся частью игры."
						),
						list(
							"title" = "Сбои, EMAG и навыки",
							"body" = "- Сбои и EMAG используют общую логику машинного состояния: машина может терять эффективность, отключаться, бить током, работать нестабильно или переходить в вредное поведение.\n- Отдельный сбой нужен только там, где машине есть что уникально сломать; иначе используется базовая деградация.\n- Диагностика, ремонт, взлом, модульная работа и обслуживание выдают опыт электрики, изобретательства, взлома, анализа или строительства.\n\n**Эффект:** система не плодит искусственные одинаковые поломки, но дает уникальное поведение там, где оно оправдано."
						),
					),
				),
				list(
					"id" = "kp13_vehicles",
					"title" = "Техника",
					"sections" = list(
						list(
							"title" = "Два класса транспорта",
							"body" = "- Простые средства передвижения — каталки, кресла, самокаты, животные и похожие тайловые объекты.\n- **КП13-техника** — машины с попиксельным движением, частями, повреждениями, топливом, пассажирами и вождением.\n- Внутренние тестовые машины на карте переведены на базовую КП13-машину, чтобы не путать тестовый корень с рабочей техникой.\n\n**Эффект:** не каждый транспорт обязан быть КП13-техникой, но киберпанк-машины играют по расширенным правилам."
						),
						list(
							"title" = "Части",
							"body" = "- Машина собирается из корпуса, ходовой части и двигателя.\n- Корпус задает массу, здоровье, места, груз и лимит механизмов. Ходовая задает сцепление, маневр и формат движения. Двигатель задает ускорение, ресурс и тип топлива или батареи.\n- Части имеют состояние, ремонтируются и могут ухудшать итоговые характеристики.\n\n**Эффект:** скорость и живучесть зависят не от одного числа, а от набора деталей и их состояния."
						),
						list(
							"title" = "Вождение и векторы",
							"body" = "- Ввод игрока задает желаемое направление.\n- `forward` — нос машины. Он поворачивается постепенно и является главным направлением наведения.\n- `velocity` — фактическая скорость и направление движения. При заносе машина может ехать не туда же, куда смотрит нос.\n- `grip` — направление сцепления. Разница между `forward`, `velocity` и `grip` дает скольжение.\n- Если нажать против носа, машина сначала тормозит. После остановки она может ехать назад с пониженной скоростью.\n\n**Эффект:** управление абсолютное по клавишам, но машина остается машиной: поворот, торможение, задний ход и занос не телепортируют нос мгновенно."
						),
						list(
							"title" = "Визуал",
							"body" = "- Текущий рабочий отладочный спрайт — один северный спрайт с прямоугольником и стрелкой.\n- Вид спрайта фиксирован в одном направлении, а поворот задается плавной 360-градусной матрицей.\n- Стрелка показывает нос машины, чтобы было понятно, где forward и где задний ход.\n\n**Эффект:** механика вождения читается по одному понятному направлению, без четырехсторонней путаницы."
						),
						list(
							"title" = "Пассажиры, столкновения и опыт",
							"body" = "- Пассажир может высунуться наружу специальной кнопкой: он остается на технике, но считается открытой целью и может вести огонь.\n- Если урон приходит по машине, он может попасть по высунувшимся пассажирам; при нескольких целях распределяется между ними.\n- Столкновение с живым существом не должно выбрасывать водителя. Живую цель отбрасывает пропорционально скорости.\n- Сильный удар о плотную преграду может выбросить водителя только выше повышенного порога.\n- Водитель получает опыт вождения за движение с интервалом, сниженным относительно редких профессиональных действий.\n\n**Эффект:** техника поддерживает боевую посадку, аварии, рискованные столкновения и прокачку за регулярное использование."
						),
					),
				),
			),
		),
		list(
			"id" = "items",
			"title" = "Предметы",
			"items" = list(
				list(
					"id" = "items_basics",
					"title" = "Базовый предмет",
					"sections" = list(
						list(
							"title" = "Состояние",
							"body" = "- У переносимых предметов есть состояние, прочность, качество, производитель, размер и базовая стоимость.\n- Износ, повреждения и испорченность доведены до общей шкалы состояния и влияют на цену, диагностику и пригодность вещи.\n- Базовые предметы получают полный набор данных, чтобы лут, торговля, контракты и инвентарь работали от одного описания."
						),
						list(
							"title" = "Качество и стоимость",
							"body" = "- Качество усиливает или ослабляет базовую ценность предмета и используется вместе с состоянием, редкостью, материалами и легальностью.\n- Стоимость не является только числом продажи: по ней сверяются рынки, торговцы, черный рынок, контракты и награды.\n- Производитель, навыки и перки могут менять эффективность, обслуживание, проверку или ценность предмета там, где это поддержано конкретной механикой."
						),
					),
				),
				list(
					"id" = "items_tiers",
					"title" = "Редкость и T1-T3",
					"sections" = list(
						list(
							"title" = "Тиры",
							"body" = "- **T1** - обычные вещи. Они чаще всего встречаются в луте, продаже и генерации.\n- **T2** - более редкие вещи с лучшими параметрами, ценой или качеством.\n- **T3** - редчайшие вещи. Они появляются редко и должны ощущаться как ценная находка.\n- Для оружия и защиты тир учитывает их базу, качество, материалы, состояние и боевую ценность."
						),
						list(
							"title" = "Лут",
							"body" = "- Лутгенераторы данжей и приключений используют редкость предмета при выборе награды.\n- T1 выпадает чаще всего, T2 заметно реже, T3 имеет минимальный шанс.\n- Испорченные, изношенные и поврежденные варианты могут выпадать отдельно от идеального состояния и влиять на итоговую стоимость."
						),
					),
				),
				list(
					"id" = "items_markets",
					"title" = "Продажа и рынки",
					"sections" = list(
						list(
							"title" = "Датумы продажи",
							"body" = "- Покупка предметов переведена на датумы продажи: один источник задает предмет, цену, наличие, запас, редкость и правила появления.\n- Магазины, торговцы, вендеры и черный рынок цепляются к этим данным, а не держат отдельные ручные списки поведения.\n- Цена продажи строится от предмета и его торгового профиля, поэтому состояние, качество и редкость сохраняют смысл."
						),
						list(
							"title" = "Ротация",
							"body" = "- Набор товаров меняется раз в игровые сутки, сейчас это 30 минут реального времени.\n- Черный рынок может выдать T3 с низким шансом, T2 с шансом выше, T1 чаще всего.\n- Обычные магазины и вендеры имеют более низкие шансы на редкие вещи, поэтому редкая продажа должна оставаться событием."
						),
					),
				),
				list(
					"id" = "items_contracts",
					"title" = "Контракты",
					"sections" = list(
						list(
							"title" = "Предмет в контракте",
							"body" = "- Когда игрок создает контракт доставки, он выбирает конкретную вещь из того, что у него есть.\n- Система резервирует выбранный предмет как цель контракта, а не генерирует абстрактную замену.\n- Сгенерированные контракты используют T1 как базу и могут редко выбрать T2. T3 в обычную генерацию контрактов не входит."
						),
					),
				),
				list(
					"id" = "items_inventory",
					"title" = "Инвентарь",
					"sections" = list(
						list(
							"title" = "Сетка",
							"body" = "- Инвентарь использует существующий экран контейнера: отдельный новый экран не нужен.\n- У контейнеров есть ширина и высота сетки, у предметов - занимаемый размер.\n- Перетаскивание в свободную клетку пытается положить предмет именно туда; если места не хватает, размещение отклоняется."
						),
						list(
							"title" = "Поворот",
							"body" = "- ПКМ по предмету в открытом контейнере поворачивает его размер в сетке.\n- Если после поворота предмет не помещается, поворот отменяется.\n- При изменении базового размера предмета сетка пересчитывается; вещи, которые больше не помещаются, вываливаются наружу."
						),
					),
				),
			),
		),
		list(
			"id" = "production",
			"title" = "Производство",
			"items" = list(
				list(
					"id" = "production_food",
					"title" = "Еда",
					"sections" = list(
						list(
							"title" = "Идея блюда",
							"body" = "- Еда строится вокруг блюда-основы и дополнений к нему.\n- Блюдо создается из ингредиентов через кухонные инструменты: ножи, доски, духовки, грили, микроволновки, процессоры и похожее оборудование.\n- Готовую еду можно дополнять другой едой: дополнение накладывается на основу, хранится вместе с блюдом и учитывается при итоговом качестве.\n\n**Эффект:** кухня работает не только как список рецептов, а как цепочка обработки ингредиентов и сборки блюда."
						),
						list(
							"title" = "Качество",
							"body" = "- У ингредиентов и еды есть уровни качества: disgusting, bad, average, good, excellent.\n- Еда наследует качество продуктов и операций, из которых она была получена.\n- Итоговое качество блюда считается по среднему качеству основы и добавленных частей.\n- Обработка и готовка могут поднимать качество и усиливать эффекты, если блюдо собрано из подходящих ингредиентов.\n\n**Эффект:** хороший продукт и правильная обработка дают более полезную еду, а плохие ингредиенты тянут весь результат вниз."
						),
						list(
							"title" = "Совместимость ингредиентов",
							"body" = "- Любые пищевые связки допустимы, но противоположные вкусы и свойства ухудшают качество.\n- Система сравнивает пищевые типы и дополнительные свойства ингредиентов, чтобы оценить, насколько они подходят друг другу.\n- Несовместимость не запрещает эксперимент, но снижает итог и может сделать блюдо неприятным.\n\n**Эффект:** игрок может собрать странное блюдо, но качественный результат требует сочетаемых основ и добавок."
						),
						list(
							"title" = "Порча",
							"body" = "- Еда и ингредиенты, которые лежат вне холодных зон или холодильников, со временем теряют качество.\n- Порча переводит продукт в низкие уровни качества и может сделать употребление опасным.\n- Испорченная еда дает токсичный вклад и может вызвать рвоту.\n\n**Эффект:** хранение еды важно: холодильники и холодные зоны защищают качество, а оставленная на жаре еда деградирует."
						),
						list(
							"title" = "Пример: сосиска с рисом",
							"body" = "- Мясо пропускается через процессор и превращается в фарш или сырой мясной шар.\n- Мясную массу можно вытянуть в сосиску и пожарить на сковороде.\n- Рис проходит свою цепочку: сухой рис, влажный рис, рисовый шар.\n- Рисовый шар добавляется к сосиске как дополнение.\n- Качество готового блюда определяется средним качеством сосиски, риса и их совместимостью.\n\n**Эффект:** рецепт описывает производственную цепочку, а не одно мгновенное действие."
						),
					),
				),
				list(
					"id" = "production_botany",
					"title" = "Ботаника",
					"sections" = list(
						list(
							"title" = "Грядки и посадка",
							"body" = "- Растения выращиваются на почвенных грядках в земле, пустошах и трущобах либо в гидропонных лотках.\n- Грядку можно создать граблями. Те же грабли убирают сорняки.\n- Лопата используется, чтобы выкопать семена и часть плодов, особенно подземные культуры.\n- Плоды можно использовать как ингредиенты или извлекать из них семена.\n\n**Эффект:** ботаника должна работать не только в стационарных лотках, но и через полевые грядки."
						),
						list(
							"title" = "Вода и удобрения",
							"body" = "- Растения требуют воду и удобрения.\n- Удобрения можно покупать или производить переработкой пищевых продуктов, включая фрукты.\n- Удобрения влияют на скорость роста и плодовитость, вода поддерживает сам рост.\n- После созревания расход воды и удобрений увеличивается.\n- Без воды растение увядает. При низком удобрении рост замедляется, а увядание становится слабее из-за сниженного обмена.\n- Избыток воды или удобрений повреждает почву.\n- У каждого вида есть оптимальные минимумы и максимумы воды и удобрения.\n\n**Эффект:** уход за растением - это удержание ресурсов в рабочем диапазоне, а не простое заливание максимумом."
						),
						list(
							"title" = "Семена",
							"body" = "- Семя хранит оптимальный минимум и максимум воды.\n- Семя хранит оптимальный минимум и максимум удобрения.\n- Семя задает тип плодоношения: дерево с несколькими плодами, растение с одним плодом или подземная культура, которую надо выкапывать.\n- Семя определяет производимый плод, эффекты плода и качество плода.\n\n**Эффект:** семена являются носителем агрономических правил, результата урожая и качества."
						),
						list(
							"title" = "Анализаторы и генная мешалка",
							"body" = "- Семена можно собирать, анализировать и передавать данные между анализатором и генной мешалкой.\n- Генная мешалка позволяет прививать гены растений и химикатов, вызывая мутации.\n- Мутационный потенциал не постоянен: он выше у исходного семени и падает с каждым поколением.\n- При мутации плод может получить дополнительное свойство.\n- Шанс мутации повышается добавлением свойств в мешалке, но за одну операцию в семя можно вложить не больше 10 очков эффектов.\n- Эффекты имеют стоимость в очках.\n\n**Эффект:** селекция строится на ограниченном генетическом бюджете и деградации потенциала по поколениям."
						),
						list(
							"title" = "Риски мутаций",
							"body" = "- Слишком высокая мутационная нагрузка вызывает негативные мутации.\n- Негативные результаты включают опасные варианты вроде цветка-убийцы или живого томата.\n- Химикаты могут повышать мутацию.\n- Мутация снижает качество плода.\n- Качество можно поднять, потратив генетические очки.\n\n**Эффект:** сильная селекция дает новые свойства, но рискует качеством и безопасностью культуры."
						),
						list(
							"title" = "Пчелы и навыки",
							"body" = "- Пчелы ускоряют рост растений.\n- Вне улья пчелы агрессивны.\n- Укус пчелы вводит воспалительный яд.\n- Ботанические навыки усиливают работу с посадкой, ростом, поливом, сбором и мутациями растений.\n\n**Эффект:** пчелы полезны для фермы, но требуют контроля, а навыки повышают надежность ботаники."
						),
					),
				),
				list(
					"id" = "production_resources",
					"title" = "Ресурсы",
					"sections" = list(
						list(
							"title" = "Сущность ресурса",
							"body" = "- Ресурсы - это сущности, нужные для крафта и переработки.\n- Ресурсом считается любой предмет, участвующий в крафте, а также руды и обработанное сырье.\n- Ресурсы могут поступать через добычу, переработку, покупку или доставку, потому что город имеет порт.\n\n**Эффект:** экономика производства опирается на конкретные материальные входы, а не только на абстрактную валюту."
						),
						list(
							"title" = "Руды и плавка",
							"body" = "- Руды перерабатываются на рудных заводах в обработанную руду.\n- Качество руды определяет количество рудных единиц.\n- Металлы, компоненты и камни требуют разное количество единиц для плавки в драгоценные камни, компоненты, слитки или листы.\n- Можно потратить меньше единиц и получить худший продукт либо больше единиц и получить лучший продукт.\n\n**Эффект:** качество сырья и объем вложения напрямую меняют итоговый материал."
						),
						list(
							"title" = "Качество компонентов",
							"body" = "- Качество компонента влияет на характеристики результата крафта.\n- Плохой инструмент может работать заметно хуже: например, плохой гаечный ключ примерно на 40% медленнее.\n- Отличный защитный материал может дать сильный бонус: например, отличный кевлар примерно на 50% лучше отвратительного.\n\n**Эффект:** ресурсная цепочка сохраняет качество от сырья до готового предмета."
						),
						list(
							"title" = "Покупка и доставка",
							"body" = "- Ресурсы можно покупать и доставлять извне.\n- Городской порт объясняет регулярную доставку материалов, компонентов и обработанного сырья.\n- Рынки и контракты могут использовать качество, редкость и состояние ресурса при продаже.\n\n**Эффект:** производство не ограничено только добычей на карте, но доставка имеет экономический смысл."
						),
						list(
							"title" = "Переработка мусора",
							"body" = "- Альтернативный источник ресурсов - переработка мусора.\n- Из достаточного количества мусора можно получать базовые и продвинутые предметы.\n- Пример: стеклянный мусор может быть переработан в цепочку вплоть до алмазов, если хватает объема и технологий.\n\n**Эффект:** мусор становится запасным ресурсным контуром для города."
						),
						list(
							"title" = "Деконструкторы",
							"body" = "- Улучшенные деконструкторы могут давать шанс получить сложные ресурсы вместо простых.\n- Шанс и доступ к сложному выходу зависят от корпоративных решений, улучшений машины и установленных модулей.\n\n**Эффект:** апгрейды переработки открывают более глубокое восстановление материалов из предметов."
						),
					),
				),
			),
		),
		list(
			"id" = "network",
			"title" = "Сеть",
			"items" = list(
				list(
					"id" = "network_empty",
					"title" = "Пусто",
					"sections" = list(
						list(
							"title" = "Нет данных",
							"body" = "Раздел зарезервирован под сетевые механики."
						),
					),
				),
			),
		),
	)
	return codex_entries

/client/proc/self_notes()
	set name = "View Admin Remarks"
	set category = "OOC"
	set desc = "View the notes that admins have written about you"

	if(!CONFIG_GET(flag/see_own_notes))
		to_chat(usr, span_notice("Sorry, that function is not enabled on this server."))
		return

	browse_messages(null, usr.ckey, null, TRUE)

/client/proc/self_playtime()
	set name = "View tracked playtime"
	set category = "OOC"
	set desc = "View the amount of playtime for roles the server has tracked."

	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, span_notice("Sorry, tracking is currently disabled."))
		return

	new /datum/job_report_menu(src, usr)

// Ignore verb
/client/verb/select_ignore()
	set name = "Ignore"
	set category = "OOC"
	set desc ="Ignore a player's messages on the OOC channel"

	// Make a list to choose players from
	var/list/players = list()

	// Use keys and fakekeys for the same purpose
	var/displayed_key = ""

	// Try to add every player who's online to the list
	for(var/client/C in GLOB.clients)
		// Don't add ourself
		if(C == src)
			continue

		// Don't add players we've already ignored if they're not using a fakekey
		if((C.key in prefs.ignoring) && !C.holder?.fakekey)
			continue

		// Don't add players using a fakekey we've already ignored
		if(C.holder?.fakekey in prefs.ignoring)
			continue

		// Use the player's fakekey if they're using one
		if(C.holder?.fakekey)
			displayed_key = C.holder.fakekey

		// Use the player's key if they're not using a fakekey
		else
			displayed_key = C.key

		// Check if both we and the player are ghosts and they're not using a fakekey
		if(isobserver(mob) && isobserver(C.mob) && !C.holder?.fakekey)
			// Show us if the player is a ghost or not after their displayed key
			// Add the player's displayed key to the list
			players["[displayed_key](ghost)"] = displayed_key

		// Add the player's displayed key to the list if we or the player aren't a ghost or they're using a fakekey
		else
			players[displayed_key] = displayed_key

	// Check if the list is empty
	if(!length(players))
		// Express that there are no players we can ignore in chat
		to_chat(src, span_infoplain("There are no other players you can ignore!"))

		// Stop running
		return

	// Sort the list
	players = sort_list(players)

	// Request the player to ignore
	var/selection = tgui_input_list(src, "Select a player", "Ignore", players)

	// Stop running if we didn't receieve a valid selection
	if(isnull(selection) || !(selection in players))
		return

	// Store the selected player
	selection = players[selection]

	// Check if the selected player is on our ignore list
	if(selection in prefs.ignoring)
		// Express that the selected player is already on our ignore list in chat
		to_chat(src, span_infoplain("You are already ignoring [selection]!"))

		// Stop running
		return

	// Add the selected player to our ignore list
	prefs.ignoring.Add(selection)

	// Save our preferences
	prefs.save_preferences()

	// Express that we've ignored the selected player in chat
	to_chat(src, span_infoplain("You are now ignoring [selection] on the OOC channel."))

// Unignore verb
/client/verb/select_unignore()
	set name = "Unignore"
	set category = "OOC"
	set desc = "Stop ignoring a player's messages on the OOC channel"

	// Check if we've ignored any players
	if(!length(prefs.ignoring))
		// Express that we haven't ignored any players in chat
		to_chat(src, span_infoplain("You haven't ignored any players!"))

		// Stop running
		return

	// Request the player to unignore
	var/selection = tgui_input_list(src, "Select a player", "Unignore", prefs.ignoring)

	// Stop running if we didn't receive a selection
	if(isnull(selection))
		return

	// Check if the selected player is not on our ignore list
	if(!(selection in prefs.ignoring))
		// Express that the selected player is not on our ignore list in chat
		to_chat(src, span_infoplain("You are not ignoring [selection]!"))

		// Stop running
		return

	// Remove the selected player from our ignore list
	prefs.ignoring.Remove(selection)

	// Save our preferences
	prefs.save_preferences()

	// Express that we've unignored the selected player in chat
	to_chat(src, span_infoplain("You are no longer ignoring [selection] on the OOC channel."))

/client/proc/show_previous_roundend_report()
	set name = "Your Last Round"
	set category = "OOC"
	set desc = "View the last round end report you've seen"

	SSticker.show_roundend_report(src, report_type = PERSONAL_LAST_ROUND)

/client/proc/show_servers_last_roundend_report()
	set name = "Server's Last Round"
	set category = "OOC"
	set desc = "View the last round end report from this server"

	SSticker.show_roundend_report(src, report_type = SERVER_LAST_ROUND)

/client/verb/fit_viewport()
	set name = "Fit Viewport"
	set category = "Special" // BANDASTATION REPLACEMENT: Original: "OOC"
	set desc = "Fit the width of the map window to match the viewport"

	// Fetch aspect ratio
	var/view_size = getviewsize(view)
	var/aspect_ratio = view_size[1] / view_size[2]

	// Calculate desired pixel width using window size and aspect ratio
	var/list/sizes = params2list(winget(src, "[SKIN_MAINWINDOW_SPLIT];[SKIN_MAPWINDOW]", "size"))

	// Client closed the window? Some other error? This is unexpected behaviour, let's
	// CRASH with some info.
	if(!sizes["[SKIN_MAPWINDOW].size"])
		CRASH("sizes does not contain mapwindow.size key. This means a winget failed to return what we wanted. --- sizes var: [sizes] --- sizes length: [length(sizes)]")

	var/list/map_size = splittext(sizes["[SKIN_MAPWINDOW].size"], "x")

	var/split_size = splittext(sizes["[SKIN_MAINWINDOW_SPLIT].size"], "x")
	var/split_width = text2num(split_size[1])

	// Window is minimized, we can't get proper data so return to avoid division by 0
	if (!split_width)
		return

	// Gets the type of zoom we're currently using from our view datum
	// If it's 0 we do our pixel calculations based off the size of the mapwindow
	// If it's not, we already know how big we want our window to be, since zoom is the exact pixel ratio of the map
	var/zoom_value = src.view_size?.zoom || 0

	var/desired_width = 0
	if(zoom_value)
		desired_width = round(view_size[1] * zoom_value * ICON_SIZE_X)
	else

		// Looks like we expect mapwindow.size to be "ixj" where i and j are numbers.
		// If we don't get our expected 2 outputs, let's give some useful error info.
		if(length(map_size) != 2)
			CRASH("map_size of incorrect length --- map_size var: [map_size] --- map_size length: [length(map_size)]")
		var/height = text2num(map_size[2])
		desired_width = round(height * aspect_ratio)

	if (text2num(map_size[1]) == desired_width)
		// Nothing to do
		return

	// Avoid auto-resizing the statpanel and chat into nothing.
	desired_width = min(desired_width, split_width - 300)

	// Calculate and apply a best estimate
	// +4 pixels are for the width of the splitter's handle
	var/pct = 100 * (desired_width + 4) / split_width
	winset(src, SKIN_MAINWINDOW_SPLIT, "splitter=[pct]")

	// Apply an ever-lowering offset until we finish or fail
	var/delta
	for(var/safety in 1 to 10)
		var/after_size = winget(src, SKIN_MAPWINDOW, "size")
		map_size = splittext(after_size, "x")
		var/got_width = text2num(map_size[1])

		if (got_width == desired_width)
			// success
			return
		else if (isnull(delta))
			// calculate a probable delta value based on the difference
			delta = 100 * (desired_width - got_width) / split_width
		else if ((delta > 0 && got_width > desired_width) || (delta < 0 && got_width < desired_width))
			// if we overshot, halve the delta and reverse direction
			delta = -delta/2

		pct += delta
		winset(src, SKIN_MAINWINDOW_SPLIT, "splitter=[pct]")

/// Attempt to automatically fit the viewport, assuming the user wants it
/client/proc/attempt_auto_fit_viewport()
	if (!prefs?.read_preference(/datum/preference/toggle/auto_fit_viewport))
		return
	// No need to attempt to fit the viewport on non-initialized clients as they'll auto-fit viewport right before finishing init
	if(fully_created)
		INVOKE_ASYNC(src, VERB_REF(fit_viewport))

/client/verb/policy()
	set name = "Show Policy"
	set desc = "Show special server rules related to your current character."
	set category = null // BANDASTATION REPLACEMENT: Original: "OOC"

	//Collect keywords
	var/list/keywords = mob.get_policy_keywords()
	var/header = get_policy(POLICY_VERB_HEADER)
	var/list/policytext = list(header)
	var/anything = FALSE
	for(var/keyword in keywords)
		var/p = get_policy(keyword)
		if(p)
			policytext += p
			policytext += "<hr>"
			anything = TRUE
	if(!anything)
		policytext += "No related rules found."

	var/datum/browser/browser = new(usr, "policy", "Server Policy", 600, 500)
	browser.set_content(policytext.Join(""))
	browser.open()

/client/verb/fix_stat_panel()
	set name = "Fix Stat Panel"
	set hidden = TRUE

	init_verbs()

/client/proc/export_preferences()
	set name = "Export Preferences"
	set desc = "Export your current preferences to a file."
	set category = "Special" // BANDASTATION REPLACEMENT: Original: "OOC"

	ASSERT(prefs, "User attempted to export preferences while preferences were null!") // what the fuck

	prefs.savefile.export_json_to_client(usr, ckey)

/client/verb/map_vote_tally_count()
	set name = "Show Map Vote Tallies"
	set desc = "View the current map vote tally counts."
	set category = "OOC" // BANDASTATION REPLACEMENT: Original: "Server"
	to_chat(mob, SSmap_vote.tally_printout)


/client/verb/linkforumaccount()
	set category = null // BANDASTATION REPLACEMENT: Original: "OOC"
	set name = "Link Forum Account"
	set desc = "Validates your byond account to your forum account. Required to post on the forums."

	var/uri = CONFIG_GET(string/forum_link_uri)
	if(!uri)
		to_chat(src, span_warning("This feature is disabled."))
		return

	if (!SSdbcore.Connect())
		to_chat(src, span_danger("No connection to the database."))
		return

	if  (is_guest_key(ckey))
		to_chat(src, span_danger("Guests can not link accounts."))
		return

	var/token = generate_account_link_token()

	var/datum/db_query/query_set_token = SSdbcore.NewQuery("INSERT INTO phpbb.tg_byond_oauth_tokens (`token`, `key`) VALUES (:token, :key)", list("token" = token, "key" = key))
	if(!query_set_token.Execute())
		to_chat(src, span_danger("Failed to insert account link token into database, please try again later."))
		qdel(query_set_token)
		return

	qdel(query_set_token)

	to_chat(src, "Now opening a window to login to your forum account, your account will automatically be linked the moment you log in. If this window doesn't load, Please go to <a href=\"[uri]?token=[token]\">[uri]?token=[token]</a> - This link will expire in 30 minutes.")
	src << link("[uri]?token=[token]")

/client/proc/generate_account_link_token()
	var/static/entropychain
	if (!entropychain)
		if (fexists("data/entropychain.txt"))
			entropychain = file2text("entropychain.txt")
		else
			entropychain = "LOL THERE IS NO ENTROPY #HEATDEATH"
	else if (prob(rand(1,15)))
		text2file("data/entropychain.txt", entropychain)

	var/datum/db_query/query_get_token = SSdbcore.NewQuery("SELECT [random_string()], [random_string()]", list(random_string_args(entropychain), random_string_args(entropychain)))

	if(!query_get_token.Execute())
		to_chat(src, span_danger("Failed to get random string token from database. (Error #1)"))
		qdel(query_get_token)
		return

	if(!query_get_token.NextRow())
		to_chat(src, span_danger("Could not locate your token in the database. (Error #2)"))
		qdel(query_get_token)
		return

	entropychain = "[query_get_token.item[2]]"
	return query_get_token.item[1]


/client/proc/random_string()
	return "SHA2(CONCAT(RAND(),UUID(),?,RAND(),UUID()), 512)"

/client/proc/random_string_args(entropychain)
	return "[entropychain][GUID()][rand()*rand(999999)][world.time][GUID()][rand()*rand(999999)][world.timeofday][GUID()][rand()*rand(999999)][world.realtime][GUID()][rand()*rand(999999)][time2text(world.timeofday)][GUID()][rand()*rand(999999)][world.tick_usage][computer_id][address][ckey][key][GUID()][rand()*rand(999999)]"
