// ============================================================================
// Lightweight atmospherics: defines, constants, flags.
// ============================================================================

/// Maximum simultaneous gas clouds in the world. Newly-spawned clouds beyond
/// this cap are silently dropped to keep CPU bounded.
#define LIGHTWEIGHT_ATMOS_MAX_CLOUDS 600

/// Below this amount, a cloud is removed.
#define LIGHTWEIGHT_ATMOS_CLOUD_FLOOR 0.5

/// Density behaviour of a gas effect along the Z-axis.
#define GAS_DENSITY_LIGHT    -1   // rises (prefers up)
#define GAS_DENSITY_NEUTRAL   0   // stays
#define GAS_DENSITY_HEAVY     1   // sinks (prefers down)

/// Filter tags — masks/internals match these against a gas effect's
/// `filter_tags` list to decide whether they neutralise the effect.
#define GAS_FILTER_PARTICLE  "particle"   // smoke, dust, aerosols
#define GAS_FILTER_TOXIC     "toxic"      // tox, plasma fumes
#define GAS_FILTER_CO2       "co2"
#define GAS_FILTER_N2O       "n2o"
#define GAS_FILTER_CHEMICAL  "chemical"
#define GAS_FILTER_HEAT      "heat"       // burning hot air
#define GAS_FILTER_COLD      "cold"
#define GAS_FILTER_ANY       "any"        // catch-all (full hazmat / sealed suit)

/// Per-tick effects can ramp up; this is the upper bound on `amount`
/// contribution to mob damage per single tick, regardless of how large the cloud is.
#define GAS_EFFECT_PER_TICK_MAX 50

/// Clothing flag: this suit/mask/helmet supplies its own breathable air
/// (rebreather, scuba, sealed hazmat). Wearer ignores environment + gas clouds.
#define BREATHES_UNDERWATER (1<<29)

/// Trait applied when a mob is connected to working internals.
#define TRAIT_INTERNAL_BREATHER "internal_breather"
/// Trait flagged on a mob currently holding its breath underwater.
#define TRAIT_HOLDING_BREATH "holding_breath"

/// Breath environment categories returned by `get_breath_environment()`.
#define BREATH_ENV_NORMAL    "normal"
#define BREATH_ENV_VACUUM    "vacuum"
#define BREATH_ENV_WATER     "water"
#define BREATH_ENV_INTERNALS "internals"

/// Default time (seconds) a healthy mob can hold its breath underwater.
#define HOLDING_BREATH_DEFAULT_SECONDS 30

/// How many breaths a single "standard" tank holds before going empty.
/// Replaces molar arithmetic with a flat counter.
#define TANK_DEFAULT_BREATH_CAPACITY 100
