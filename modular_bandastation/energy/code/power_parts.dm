/obj/item/cyberpunk_power_part
	name = "reactor part"
	desc = "A city reactor component."
	icon = 'icons/obj/devices/stock_parts.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	var/part_rating = 1

/obj/item/cyberpunk_power_part/kinetic_wheel
	name = "kinetic reactor wheel"
	desc = "A flywheel for a kinetic reactor. More wheels increase output and shaft load."
	icon_state = "matter_bin"

/obj/item/cyberpunk_power_part/kinetic_shaft
	name = "kinetic reactor shaft"
	desc = "A torque shaft for a kinetic reactor. Better shafts tolerate more wheels."
	icon_state = "micro_laser"

/obj/item/cyberpunk_power_part/kinetic_shaft/advanced
	name = "reinforced kinetic reactor shaft"
	part_rating = 2

/obj/item/cyberpunk_power_part/kinetic_motor
	name = "kinetic reactor motor"
	desc = "A generator motor for a kinetic reactor. Better motors convert rotation more efficiently."
	icon_state = "capacitor"

/obj/item/cyberpunk_power_part/kinetic_motor/advanced
	name = "high-efficiency kinetic reactor motor"
	part_rating = 2
