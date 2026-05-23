/datum/modpack/lightweight_atmos
	name = "Lightweight Atmospherics"
	desc = "Replaces heavy LINDA gas simulation with cheap gas-effect clouds. Normal turfs are breathable by default; dangerous gas comes from grenades, chems, fire, etc., as transient cloud objects processed by SSgas_effects."
	author = "Kagelite"

/datum/modpack/lightweight_atmos/pre_initialize()
	. = ..()

/datum/modpack/lightweight_atmos/initialize()
	. = ..()

/datum/modpack/lightweight_atmos/post_initialize()
	. = ..()
