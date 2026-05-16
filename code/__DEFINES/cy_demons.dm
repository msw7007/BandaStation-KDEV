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

#define CY_DEMON_SPECIAL_MASS "mass"
#define CY_DEMON_SPECIAL_SPREAD "spread"
#define CY_DEMON_SPECIAL_JUMP "jump"
#define CY_DEMON_SPECIAL_STEALTH "stealth"
#define CY_DEMON_SPECIAL_EMI "emi"
#define CY_DEMON_EFFECT_REAPER "reaper"
#define CY_DEMON_EFFECT_COLLECTOR "collector"

#define CY_DEMON_UPGRADE_MASS "mass"
#define CY_DEMON_UPGRADE_SPREAD "spread"
#define CY_DEMON_UPGRADE_JUMP "jump"
#define CY_DEMON_UPGRADE_EMI "emi"
#define CY_DEMON_UPGRADE_BLOCK_KEY "block_key"
#define CY_DEMON_UPGRADE_EFFECT_KEY "effect_key"
#ifndef CY_DEMON_MASS_RADIUS
#define CY_DEMON_MASS_RADIUS 2
#endif
#ifndef CY_DEMON_JUMP_RANGE
#define CY_DEMON_JUMP_RANGE 4
#endif
