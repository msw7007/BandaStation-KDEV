#ifndef HEAR_HEARD
#define HEAR_HEARD (1<<0)
#endif

#ifndef HEAR_UNDERSTOOD
#define HEAR_UNDERSTOOD (1<<1)
#endif

#ifndef MODE_TTS_IDENTIFIER
#define MODE_TTS_IDENTIFIER "tts_identifier"
#endif

#ifndef ORGAN_SLOT_BREATHING_TUBE
#define ORGAN_SLOT_BREATHING_TUBE ORGAN_SLOT_NECK_AUG
#endif

#ifndef ORGAN_SLOT_BRAIN_CEREBELLUM
#define ORGAN_SLOT_BRAIN_CEREBELLUM ORGAN_SLOT_OS
#endif

#ifndef ORGAN_SLOT_BRAIN_CNS
#define ORGAN_SLOT_BRAIN_CNS ORGAN_SLOT_OS
#endif

#ifndef ORGAN_SLOT_BRAIN_HIPPOCAMPUS
#define ORGAN_SLOT_BRAIN_HIPPOCAMPUS ORGAN_SLOT_OS
#endif

#ifndef ENTIRE_BODY
#define ENTIRE_BODY "entire body"
#endif

#ifndef bodyshapes_with_variations
#define bodyshapes_with_variations BODYSHAPE_DIGITIGRADE
#endif

#ifndef GRAB_NECK
#define GRAB_NECK GRAB_TWOHANDED
#endif

#ifndef COMPONENT_BLOCK_RESIST
#define COMPONENT_BLOCK_RESIST (1<<0)
#endif

#ifndef COMSIG_MOVABLE_GRABBED_RESISTING
#define COMSIG_MOVABLE_GRABBED_RESISTING "movable_grabbed_resisting"
#endif

#ifndef GRAB_STAT_EFFECTIVE_STATE
#define GRAB_STAT_EFFECTIVE_STATE 1
#endif

#ifndef GRAB_STAT_FAIL_DAMAGE
#define GRAB_STAT_FAIL_DAMAGE 2
#endif

#ifndef GRAB_STAT_ESCAPE_CHANCE
#define GRAB_STAT_ESCAPE_CHANCE 3
#endif

#ifndef COMSIG_BODYPART_UPDATED
#define COMSIG_BODYPART_UPDATED "bodypart_updated"
#endif

#ifndef MUTATION_SOURCE_TIMED_INJECTOR
#define MUTATION_SOURCE_TIMED_INJECTOR "timed_injector"
#endif

#ifndef FEATURE_HUMAN_TATTOO_COLOR
#define FEATURE_HUMAN_TATTOO_COLOR "human_tattoo_color"
#endif

#ifndef FEATURE_HUMAN_TATTOO_HEAD_1
#define FEATURE_HUMAN_TATTOO_HEAD_1 "human_tattoo_head_1"
#define FEATURE_HUMAN_TATTOO_HEAD_2 "human_tattoo_head_2"
#define FEATURE_HUMAN_TATTOO_HEAD_3 "human_tattoo_head_3"
#define FEATURE_HUMAN_TATTOO_HEAD_4 "human_tattoo_head_4"
#define FEATURE_HUMAN_TATTOO_HEAD_5 "human_tattoo_head_5"
#define FEATURE_HUMAN_TATTOO_HEAD_6 "human_tattoo_head_6"
#define FEATURE_HUMAN_TATTOO_CHEST_1 "human_tattoo_chest_1"
#define FEATURE_HUMAN_TATTOO_CHEST_2 "human_tattoo_chest_2"
#define FEATURE_HUMAN_TATTOO_CHEST_3 "human_tattoo_chest_3"
#define FEATURE_HUMAN_TATTOO_CHEST_4 "human_tattoo_chest_4"
#define FEATURE_HUMAN_TATTOO_CHEST_5 "human_tattoo_chest_5"
#define FEATURE_HUMAN_TATTOO_CHEST_6 "human_tattoo_chest_6"
#define FEATURE_HUMAN_TATTOO_L_ARM_1 "human_tattoo_l_arm_1"
#define FEATURE_HUMAN_TATTOO_L_ARM_2 "human_tattoo_l_arm_2"
#define FEATURE_HUMAN_TATTOO_L_ARM_3 "human_tattoo_l_arm_3"
#define FEATURE_HUMAN_TATTOO_L_ARM_4 "human_tattoo_l_arm_4"
#define FEATURE_HUMAN_TATTOO_L_ARM_5 "human_tattoo_l_arm_5"
#define FEATURE_HUMAN_TATTOO_L_ARM_6 "human_tattoo_l_arm_6"
#define FEATURE_HUMAN_TATTOO_R_ARM_1 "human_tattoo_r_arm_1"
#define FEATURE_HUMAN_TATTOO_R_ARM_2 "human_tattoo_r_arm_2"
#define FEATURE_HUMAN_TATTOO_R_ARM_3 "human_tattoo_r_arm_3"
#define FEATURE_HUMAN_TATTOO_R_ARM_4 "human_tattoo_r_arm_4"
#define FEATURE_HUMAN_TATTOO_R_ARM_5 "human_tattoo_r_arm_5"
#define FEATURE_HUMAN_TATTOO_R_ARM_6 "human_tattoo_r_arm_6"
#define FEATURE_HUMAN_TATTOO_L_LEG_1 "human_tattoo_l_leg_1"
#define FEATURE_HUMAN_TATTOO_L_LEG_2 "human_tattoo_l_leg_2"
#define FEATURE_HUMAN_TATTOO_L_LEG_3 "human_tattoo_l_leg_3"
#define FEATURE_HUMAN_TATTOO_L_LEG_4 "human_tattoo_l_leg_4"
#define FEATURE_HUMAN_TATTOO_L_LEG_5 "human_tattoo_l_leg_5"
#define FEATURE_HUMAN_TATTOO_L_LEG_6 "human_tattoo_l_leg_6"
#define FEATURE_HUMAN_TATTOO_R_LEG_1 "human_tattoo_r_leg_1"
#define FEATURE_HUMAN_TATTOO_R_LEG_2 "human_tattoo_r_leg_2"
#define FEATURE_HUMAN_TATTOO_R_LEG_3 "human_tattoo_r_leg_3"
#define FEATURE_HUMAN_TATTOO_R_LEG_4 "human_tattoo_r_leg_4"
#define FEATURE_HUMAN_TATTOO_R_LEG_5 "human_tattoo_r_leg_5"
#define FEATURE_HUMAN_TATTOO_R_LEG_6 "human_tattoo_r_leg_6"
#endif

#ifndef HUMANOIDITY_DEFAULT
#define HUMANOIDITY_DEFAULT 100
#define HUMANOIDITY_CHROMITY_START 90
#define HUMANOIDITY_CHROMITY_ZERO 40
#define HUMANOIDITY_COLLAPSE_THRESHOLD 0
#define DNA_INFUSER_BASE_HUMANOIDITY_COST 5
#define VISCEROID_CONTAINMENT_TUMOR_TIME (15 MINUTES)
#define GENETIC_TUMOR_DORMANT_TIME (10 MINUTES)
#define GENETIC_TUMOR_GROWTH_TIME (2 MINUTES)
#define GENETIC_TUMOR_SEVERITY_INTERVAL (5 MINUTES)
#endif

#ifndef ORGAN_SLOT_BELLY_AUG
#define ORGAN_SLOT_BELLY_AUG "belly_device"
#define ORGAN_SLOT_CHEST_AUG "chest_device"
#define ORGAN_SLOT_NECK_AUG "neck_device"
#define ORGAN_SLOT_NEURAL_IMPLANT "neural_implant"
#define ORGAN_SLOT_OS "os_device"
#define CYBERPUNK_OS_SLOT_CAPACITY 1
#define ORGAN_SLOT_RIGHT_LEG_AUG "r_leg_device"
#define ORGAN_SLOT_LEFT_LEG_AUG "l_leg_device"
#define ORGAN_SLOT_EYELID_AUG "eyelid_device"
#endif

#ifndef POSITIVE_INSTABILITY_MINOR
#define POSITIVE_INSTABILITY_MINOR HUMANOIDITY_LOAD_MINOR
#endif

#ifndef POSITIVE_INSTABILITY_MODERATE
#define POSITIVE_INSTABILITY_MODERATE HUMANOIDITY_LOAD_MODERATE
#endif

#ifndef POSITIVE_INSTABILITY_MAJOR
#define POSITIVE_INSTABILITY_MAJOR HUMANOIDITY_LOAD_MAJOR
#endif

#ifndef NEGATIVE_STABILITY_MAJOR
#define NEGATIVE_STABILITY_MAJOR HUMANOIDITY_RECOVERY_MAJOR
#endif
