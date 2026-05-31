#define PLANT_FORM_PLANT "растение"
#define PLANT_FORM_TREE "дерево"
#define PLANT_FORM_UNDERGROUND "подземное"

#define SEED_OVERFLOW_TOXIC_PER_CYCLE 2
#define SEED_UNDERFLOW_HEALTH_PENALTY 1
#define PLANT_FORM_TREE_BONUS_YIELD 1
/// Extra water/nutrient a fully-grown plant draws each cycle on top of the tray's base drain.
#define MATURE_EXTRA_WATER_DRAIN 2
#define MATURE_EXTRA_NUTRI_DRAIN 0.5
/// Health a starved (under-fertilised) plant claws back when also dry — slowed metabolism = slower wilting.
#define STARVED_WILT_RELIEF 0.5

/obj/item/seeds
	var/min_water = 5
	var/max_water = 200
	var/min_nutri = 0
	var/max_nutri = 100
	var/plant_form = PLANT_FORM_PLANT
	/// Mind of whoever is mid-harvest, so getYield() can apply their gardening bonus. Cleared right after.
	var/tmp/datum/mind/harvesting_mind

/datum/component/seed_requirements
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Last tray age we acted on, so we run once per growth cycle instead of every process tick.
	var/last_seen_age = -1

/datum/component/seed_requirements/Initialize()
	if(!istype(parent, /obj/item/seeds))
		return COMPONENT_INCOMPATIBLE

/datum/component/seed_requirements/RegisterWithParent()
	RegisterSignal(parent, COMSIG_SEED_ON_GROW, PROC_REF(on_grow))

/datum/component/seed_requirements/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_SEED_ON_GROW)

/datum/component/seed_requirements/proc/on_grow(datum/source, obj/machinery/hydroponics/tray)
	SIGNAL_HANDLER
	if(tray.age == last_seen_age) // the grow signal fires every tick; only act when a cycle actually advanced
		return
	last_seen_age = tray.age
	var/obj/item/seeds/seed = parent

	if(tray.age >= seed.maturation) // grown plants are thirstier and hungrier
		tray.adjust_waterlevel(-MATURE_EXTRA_WATER_DRAIN)
		tray.reagents?.remove_all(MATURE_EXTRA_NUTRI_DRAIN)

	if(tray.waterlevel < seed.min_water)
		tray.adjust_plant_health(-SEED_UNDERFLOW_HEALTH_PENALTY)
	else if(tray.waterlevel > seed.max_water)
		tray.adjust_toxic(SEED_OVERFLOW_TOXIC_PER_CYCLE)

	var/nutri_volume = tray.reagents?.total_volume || 0
	if(nutri_volume < seed.min_nutri)
		tray.adjust_plant_health(-SEED_UNDERFLOW_HEALTH_PENALTY)
		if(tray.waterlevel <= 10) // starved = slow metabolism, so dryness wilts it more slowly
			tray.adjust_plant_health(STARVED_WILT_RELIEF)
	else if(nutri_volume > seed.max_nutri)
		tray.adjust_toxic(SEED_OVERFLOW_TOXIC_PER_CYCLE)

/obj/machinery/hydroponics/set_seed(obj/item/seeds/new_seed, delete_old_seed = TRUE)
	. = ..()
	if(new_seed)
		new_seed.AddComponent(/datum/component/seed_requirements)

/obj/item/seeds/examine(mob/user)
	. = ..()
	. += span_notice("Тип: [plant_form].")
	. += span_notice("Вода: [min_water]–[max_water]. Удобрения: [min_nutri]–[max_nutri].")

/obj/item/seeds/harvest(mob/user)
	if(plant_form == PLANT_FORM_UNDERGROUND)
		var/obj/item/held = user?.get_active_held_item()
		if(!held || held.tool_behaviour != TOOL_SHOVEL)
			to_chat(user, span_warning("Нужна лопата, чтобы выкопать [name]."))
			return list()
	harvesting_mind = user?.mind
	harvesting_mind?.adjust_experience(/datum/skill/gardening, SKILL_XP_GARDENING_PER_HARVEST * max(getYield(), 1))
	. = ..()
	harvesting_mind = null

/obj/item/seeds/getYield()
	. = ..()
	if(. <= 0)
		return
	if(plant_form == PLANT_FORM_TREE)
		. += PLANT_FORM_TREE_BONUS_YIELD
	if(!harvesting_mind)
		return
	var/level = harvesting_mind.get_skill_level(/datum/skill/gardening)
	if(level >= SKILL_LEVEL_LEGENDARY)
		. += 2
	else if(level >= SKILL_LEVEL_JOURNEYMAN)
		. += 1
