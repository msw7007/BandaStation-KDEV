//Contains generic skillchips that are fairly short and simple

/obj/item/skillchip/wine_taster
	name = "WINE skillchip"
	desc = "Wine.Is.Not.Equal version 5."
	auto_traits = list(TRAIT_WINE_TASTER)
	skill_name = "Wine Tasting"
	skill_description = "Recognize wine vintage from taste alone. Never again lack an opinion when presented with an unknown drink."
	skill_icon = "wine-bottle"
	activate_message = span_notice("You recall wine taste.")
	deactivate_message = span_notice("Your memories of wine evaporate.")

/obj/item/skillchip/bonsai
	name = "Hedge 3 skillchip"
	desc = "\"Learn how to trim hedges and potted plants into new shapes. Third edition.\""
	auto_traits = list(TRAIT_BONSAI)
	skill_name = "Hedgetrimming"
	skill_description = "Trim hedges and potted plants into marvelous new shapes with any old knife. Not applicable to plastic plants."
	skill_icon = "spa"
	activate_message = span_notice("Your mind is filled with plant arrangments.")
	deactivate_message = span_notice("You can't remember what a hedge looks like anymore.")

/obj/item/skillchip/light_remover
	name = "N16H7M4R3 skillchip"
	desc = "A skillchip about safe lightbulb removal. Whoever came up with that awful name should be fired."
	auto_traits = list(TRAIT_LIGHTBULB_REMOVER)
	skill_name = "Lightbulb Removing"
	skill_description = "Stop failing taking out lightbulbs today, no gloves needed!"
	skill_icon = "lightbulb"
	activate_message = span_notice("Your feel like your pain receptors are less sensitive to hot objects.")
	deactivate_message = span_notice("You feel like hot objects could stop you again...")

/obj/item/skillchip/entrails_reader
	name = "3NTR41LS skillchip"
	auto_traits = list(TRAIT_ENTRAILS_READER)
	skill_name = "Entrails Reader"
	skill_description = "Be able to learn about a person's life, by looking at their internal organs. Not to be confused with looking into the future."
	skill_icon = "lungs"
	activate_message = span_notice("You feel that you know a lot about interpreting organs.")
	deactivate_message = span_notice("Knowledge of liver damage, heart strain and lung scars fades from your mind.")

/obj/item/skillchip/appraiser
	name = "GENUINE ID Appraisal Now! skillchip"
	desc = "The name couldn't be any more desperate and self-explainatory, by skillchip naming standards."
	auto_traits = list(TRAIT_ID_APPRAISER)
	skill_name = "ID Appraisal"
	skill_description = "Appraise an ID and see if it's issued from centcom, or just a cruddy station-printed one."
	skill_icon = "magnifying-glass"
	activate_message = span_notice("You feel that you can recognize special, minute details on ID cards.")
	deactivate_message = span_notice("Was there something special about certain IDs?")

/obj/item/skillchip/sabrage
	name = "Le S48R4G3 skillchip"
	desc = "A skillchip faintly smelling of alcohol. Best used in conjuction with a sabre or otherwise a sharp blade."
	auto_traits = list(TRAIT_SABRAGE_PRO)
	skill_name = "Sabrage Proficiency"
	skill_description = "Grants the user knowledge of the intricate structure of a champagne bottle's structural weakness at the neck, \
	improving their proficiency at being a show-off at officer parties."
	skill_icon = "bottle-droplet"
	activate_message = span_notice("You feel a new understanding of champagne bottles and methods on how to remove their corks.")
	deactivate_message = span_notice("The knowledge of the subtle physics residing inside champagne bottles fades from your mind.")

/obj/item/skillchip/chefs_kiss
	name = "K1SS skillchip"
	desc = "This skillchip faintly smells of apple pie, how lovely. Consult a dietician before use."
	auto_traits = list(TRAIT_CHEF_KISS)
	skill_name = "Chef's Kiss"
	skill_description = "Allows you to kiss food you've created to make them with love."
	skill_icon = "cookie"
	activate_message = span_notice("You recall learning from your grandmother how they baked their cookies with love.")
	deactivate_message = span_notice("You forget all memories imparted upon you by your grandmother. Were they even your real grandma?")

/obj/item/skillchip/intj
	name = "Integrated Intuitive Thinking and Judging skillchip"
	auto_traits = list(TRAIT_REMOTE_TASTING)
	skill_name = "Mental Flavour Calculus"
	skill_description = "When examining food, you can experience the flavours just as well as if you were eating it."
	skill_icon = FA_ICON_DRUMSTICK_BITE
	activate_message = span_notice("You think of your favourite food and realise that you can rotate its flavour in your mind.")
	deactivate_message = span_notice("You feel your food-based mind palace crumbling...")

/obj/item/skillchip/drunken_brawler
	name = "F0RC3 4DD1CT10N skillchip"
	desc = "A skillchip reeking of alcohol, said to improve one's fighting prowess while inebriated, as if that will save you from liver cirrhosis."
	auto_traits = list(TRAIT_DRUNKEN_BRAWLER)
	skill_name = "Drunken Unarmed Proficiency"
	skill_description = "When intoxicated, you gain increased unarmed effectiveness."
	skill_icon = "wine-bottle"
	activate_message = span_notice("You honestly could do with a drink. Never know when someone might try and jump you around here.")
	deactivate_message = span_notice("You suddenly feel a lot safer going around the station sober... ")
