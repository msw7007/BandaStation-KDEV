#define NITRILE_GLOVES_MULTIPLIER 0.5
///multiplies the time of do_after by NITRILE_GLOVES_MULTIPLIER if the user has the TRAIT_FASTMED
#define CHEM_INTERACT_DELAY(delay, user) ((delay) * ((user).get_cyberpunk_medical_treatment_time_multiplier()) * (HAS_TRAIT(user, TRAIT_FASTMED) ? NITRILE_GLOVES_MULTIPLIER : 1))
