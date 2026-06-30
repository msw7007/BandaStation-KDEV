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
