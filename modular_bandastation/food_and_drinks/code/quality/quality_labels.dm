#define FOOD_QUALITY_TIER_DISGUSTING "отвратительное"
#define FOOD_QUALITY_TIER_BAD "плохое"
#define FOOD_QUALITY_TIER_AVERAGE "среднее"
#define FOOD_QUALITY_TIER_GOOD "хорошее"
#define FOOD_QUALITY_TIER_EXCELLENT "отличное"

/proc/food_quality_5tier(quality)
	if(quality < 0)
		return FOOD_QUALITY_TIER_DISGUSTING
	if(quality == 0)
		return FOOD_QUALITY_TIER_BAD
	if(quality <= FOOD_QUALITY_NICE)
		return FOOD_QUALITY_TIER_AVERAGE
	if(quality <= FOOD_QUALITY_VERYGOOD)
		return FOOD_QUALITY_TIER_GOOD
	return FOOD_QUALITY_TIER_EXCELLENT
