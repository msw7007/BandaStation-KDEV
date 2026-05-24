/obj/item/clothing/mask/proc/get_filter_tags()
	return null

/obj/item/clothing/mask/consume_filter(datum/gas_mixture/breath)
	return breath

/obj/item/clothing/mask/gas
	var/list/filter_tags_when_loaded = list(
		GAS_FILTER_PARTICLE,
		GAS_FILTER_TOXIC,
		GAS_FILTER_CHEMICAL,
		GAS_FILTER_ACID,
	)

/obj/item/clothing/mask/gas/get_filter_tags()
	if(has_filter && length(gas_filters))
		return filter_tags_when_loaded
	return null

/obj/item/clothing/mask/gas/sechailer
	filter_tags_when_loaded = list(
		GAS_FILTER_PARTICLE,
		GAS_FILTER_TOXIC,
		GAS_FILTER_CHEMICAL,
		GAS_FILTER_ACID,
		GAS_FILTER_CO2,
		GAS_FILTER_N2O,
	)
