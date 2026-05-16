// CyberPunk agriculture genetics bridge: analyzer/mixer data contract.

/obj/item/cy_gene_data_disk
	name = "gene data disk"
	desc = "Stores analyzed seed gene data for transfer between botanical machines."
	icon = 'icons/obj/devices/floppy_disks.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_TINY
	var/list/stored_gene_data

/obj/item/cy_gene_data_disk/examine(mob/user)
	. = ..()
	if(stored_gene_data)
		. += span_notice("The disk contains [length(stored_gene_data)] gene records.")

/obj/item/plant_analyzer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	var/obj/item/seeds/seed = target
	if(!istype(seed) || !proximity_flag)
		return
	var/list/data = seed.cy_export_gene_data()
	to_chat(user, span_notice("Water optimum: [data["water_min"]]-[data["water_max"]]. Nutrient optimum: [data["nutrient_min"]]-[data["nutrient_max"]]. Crop type: [data["crop_type"]]. Quality: [cy_quality_name(data["quality"])]."))

/obj/machinery/cy_seed_mixer
	name = "gene mixer"
	desc = "A compact machine for transferring limited botanical gene data into seeds."
	icon = 'icons/obj/machines/biogenerator.dmi'
	icon_state = "biogenerator"
	density = TRUE
	var/list/stored_gene_data

/obj/machinery/cy_seed_mixer/examine(mob/user)
	. = ..()
	if(stored_gene_data)
		. += span_notice("Stored gene records: [length(stored_gene_data)].")

/obj/machinery/cy_seed_mixer/attackby(obj/item/item, mob/user, params)
	var/obj/item/seeds/seed = item
	if(istype(seed))
		if(stored_gene_data)
			if(seed.cy_import_gene_data(stored_gene_data))
				user.balloon_alert(user, "genes inserted")
			else
				user.balloon_alert(user, "too unstable")
			return
		stored_gene_data = seed.cy_export_gene_data()
		user.balloon_alert(user, "genes scanned")
		return
	var/obj/item/cy_gene_data_disk/disk = item
	if(istype(disk))
		if(stored_gene_data && !disk.stored_gene_data)
			disk.stored_gene_data = stored_gene_data.Copy()
			user.balloon_alert(user, "data written")
		else if(disk.stored_gene_data)
			stored_gene_data = disk.stored_gene_data.Copy()
			user.balloon_alert(user, "data loaded")
		return
	return ..()
