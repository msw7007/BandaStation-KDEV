/// Cyberpunk city role groups.
/datum/job_department/cy_residents
	department_name = DEPARTMENT_CY_RESIDENTS
	department_bitflags = DEPARTMENT_BITFLAG_CY_RESIDENTS
	department_head = /datum/job/cy_council_member
	department_experience_type = EXP_TYPE_CREW
	display_order = 11
	label_class = "service"
	ui_color = "#70a5c7"
	nation_prefixes = list("Civic", "Metro", "Urban", "Council")
	department_access = list()

/datum/job_department/cy_corporate
	department_name = DEPARTMENT_CY_CORPORATE
	department_bitflags = DEPARTMENT_BITFLAG_CY_CORPORATE
	department_head = /datum/job/cy_ben_representative
	department_experience_type = EXP_TYPE_CREW
	display_order = 12
	label_class = "science"
	ui_color = "#a47fd4"
	nation_prefixes = list("Ben", "Ryaz", "Star", "Corp")
	department_access = list()

/datum/job_department/cy_outsourcers
	department_name = DEPARTMENT_CY_OUTSOURCERS
	department_bitflags = DEPARTMENT_BITFLAG_CY_OUTSOURCERS
	department_head = /datum/job/cy_mercenary
	department_experience_type = EXP_TYPE_CREW
	display_order = 13
	label_class = "supply"
	ui_color = "#caa56a"
	nation_prefixes = list("Wast", "Dust", "Route", "Free")
	department_access = list()

/datum/job_department/cy_antagonists
	department_name = DEPARTMENT_CY_ANTAGONISTS
	department_bitflags = DEPARTMENT_BITFLAG_CY_ANTAGONISTS
	department_head = /datum/job/cy_gang_member
	department_experience_type = EXP_TYPE_ANTAG
	display_order = 14
	label_class = "security"
	ui_color = "#c45c66"
	nation_prefixes = list("Red", "Ash", "Gang", "Ruin")
	department_access = list()
