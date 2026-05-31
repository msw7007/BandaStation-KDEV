#define RESOURCE_QUALITY_NONE 0
#define RESOURCE_QUALITY_DISGUSTING 1
#define RESOURCE_QUALITY_BAD 2
#define RESOURCE_QUALITY_AVERAGE 3
#define RESOURCE_QUALITY_GOOD 4
#define RESOURCE_QUALITY_EXCELLENT 5

GLOBAL_LIST_INIT(resource_quality_labels, list(
	RESOURCE_QUALITY_DISGUSTING = "отвратительное",
	RESOURCE_QUALITY_BAD = "плохое",
	RESOURCE_QUALITY_AVERAGE = "среднее",
	RESOURCE_QUALITY_GOOD = "хорошее",
	RESOURCE_QUALITY_EXCELLENT = "отличное",
))

/// Drives both economy (ore points / smelting) and item stats (tool speed, armor).
/// 1.0 = average, so average-quality items behave exactly like vanilla.
GLOBAL_LIST_INIT(resource_quality_multipliers, list(
	RESOURCE_QUALITY_DISGUSTING = 0.5,
	RESOURCE_QUALITY_BAD = 0.75,
	RESOURCE_QUALITY_AVERAGE = 1.0,
	RESOURCE_QUALITY_GOOD = 1.25,
	RESOURCE_QUALITY_EXCELLENT = 1.5,
))

GLOBAL_LIST_INIT(resource_quality_spawn_weights, list(
	RESOURCE_QUALITY_DISGUSTING = 5,
	RESOURCE_QUALITY_BAD = 20,
	RESOURCE_QUALITY_AVERAGE = 50,
	RESOURCE_QUALITY_GOOD = 20,
	RESOURCE_QUALITY_EXCELLENT = 5,
))

/proc/get_resource_quality_multiplier(quality)
	return GLOB.resource_quality_multipliers[quality] || 1.0

/proc/get_resource_quality_label(quality)
	return GLOB.resource_quality_labels[quality] || GLOB.resource_quality_labels[RESOURCE_QUALITY_AVERAGE]

/proc/pick_random_resource_quality()
	return pick_weight(GLOB.resource_quality_spawn_weights)
