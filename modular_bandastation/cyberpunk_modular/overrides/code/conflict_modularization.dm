// Conflict-prone core customizations kept in the late modular overlay.

/datum/keybinding/mob/activate_inhand
	hotkey_keys = list("Q")

/datum/keybinding/mob/drop_item
	hotkey_keys = list("Z")

/datum/keybinding/mob/target/head_cycle
	full_name = "Выбрать голову/шею"
	description = "Выбрать голову или шею как цель. Каждое нажатие циклирует между ними. Влияет на то, куда вы ударяете, или где вы проводите операции."

/datum/keybinding/mob/target/eyes
	hotkey_keys = list("Numpad9")
	full_name = "Выбрать глаза/уши"
	description = "Выбрать глаза или уши как цель. Каждое нажатие циклирует между ними. Влияет на то, куда вы ударяете, или где вы проводите операции."

/datum/keybinding/mob/target/mouth
	hotkey_keys = list("Numpad7")
	full_name = "Выбрать нос/рот"
	description = "Выбрать нос или рот как цель. Каждое нажатие циклирует между ними. Влияет на то, куда вы ударяете, или где вы проводите операции."

/datum/keybinding/living/view_pet_data
	hotkey_keys = list("V")
	name = "view_pet_commands"
	full_name = "Просмотр команд питомцев"
	description = "Удерживайте, чтобы увидеть все команды, которые вы можете дать своим питомцам!"
	keybind_signal = COMSIG_KB_LIVING_VIEW_PET_COMMANDS

// Lightweight atmos does not use normal pipenet distribution loops, so the
// upstream atmos connectivity map test is not meaningful for this fork mode.
/datum/unit_test/atmospherics_sanity
	abstract_type = /datum/unit_test/atmospherics_sanity

/obj/item/skillchip/useless_adapter
	abstract_type = /obj/item/skillchip/useless_adapter

/obj/item/skillchip/disk_verifier
	abstract_type = /obj/item/skillchip/disk_verifier

/obj/item/skillchip/brainwashing
	abstract_type = /obj/item/skillchip/brainwashing

/obj/item/skillchip/master_angler
	abstract_type = /obj/item/skillchip/master_angler

/datum/action/cooldown/fishing_tip
	abstract_type = /datum/action/cooldown/fishing_tip

/obj/item/skillchip/disposals
	abstract_type = /obj/item/skillchip/disposals
