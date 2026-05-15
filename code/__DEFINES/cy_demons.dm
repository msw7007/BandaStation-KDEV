/// Generic demon contexts. Demons are modular active abilities, not netspace-owned objects.
#define CY_DEMON_CONTEXT_PHYSICAL "physical"
#define CY_DEMON_CONTEXT_NETSPACE "netspace"

/// Demon module categories.
#define CY_DEMON_MODULE_EFFECT "effect"
#define CY_DEMON_MODULE_PAYLOAD "payload"
#define CY_DEMON_MODULE_MODIFIER "modifier"
#define CY_DEMON_MODULE_SECURITY "security"

/// Demon effect families.
#define CY_DEMON_EFFECT_BREACH "breach"
#define CY_DEMON_EFFECT_PING "ping"
#define CY_DEMON_EFFECT_WALL "wall"
#define CY_DEMON_EFFECT_CONTROL "control"
#define CY_DEMON_EFFECT_STATUS "status"

#define CY_DEMON_CAST_TRACE_PREPARE "demon prepare"
#define CY_DEMON_CAST_TRACE_FIRE "demon fired"
#define CY_DEMON_CAST_TRACE_FAIL "demon failed"

#define CY_DEMON_DEFAULT_PREP_TIME (2 SECONDS)
#define CY_DEMON_DEFAULT_COOLDOWN (6 SECONDS)
#define CY_DEMON_DEFAULT_PHYSICAL_RANGE 6
#define CY_DEMON_DEFAULT_NET_RANGE 8
#define CY_DEMON_DEFAULT_POWER 10

#define CY_DEMON_UPGRADE_POWER "power"
#define CY_DEMON_UPGRADE_RANGE "range"
#define CY_DEMON_UPGRADE_SPEED "speed"
#define CY_DEMON_UPGRADE_STEALTH "stealth"

#define CY_DEMON_CAST_CANCELLED -1
#define CY_DEMON_CAST_RUNNING 0
#define CY_DEMON_CAST_FINISHED 1
