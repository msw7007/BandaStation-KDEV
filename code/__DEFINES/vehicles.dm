//Vehicle control flags. control flags describe access to actions in a vehicle.

///controls the vehicles movement
#define VEHICLE_CONTROL_DRIVE (1<<0)
///Can't leave vehicle voluntarily, has to resist.
#define VEHICLE_CONTROL_KIDNAPPED (1<<1)
///melee attacks/shoves a vehicle may have
#define VEHICLE_CONTROL_MELEE (1<<2)
///using equipment/weapons on the vehicle
#define VEHICLE_CONTROL_EQUIPMENT (1<<3)
///changing around settings and the like.
#define VEHICLE_CONTROL_SETTINGS (1<<4)

///ez define for giving a single pilot mech all the flags it needs.
#define FULL_MECHA_CONTROL ALL

//Ridden vehicle flags

/// Does our vehicle require arms to operate? Also used for piggybacking on humans to reserve arms on the rider
#define RIDER_NEEDS_ARMS   (1<<0)
// As above but only used for riding cyborgs, and only reserves 1 arm instead of 2
#define RIDER_NEEDS_ARM (1<<1)
/// Do we need legs to ride this (checks against TRAIT_FLOORED)
#define RIDER_NEEDS_LEGS   (1<<2)
/// If the rider is disabled or loses their needed limbs, do they fall off?
#define UNBUCKLE_DISABLED_RIDER (1<<3)
// For fireman carries, the carrying human needs an arm
#define CARRIER_NEEDS_ARM (1<<4)
// This rider must be our friend
#define JUST_FRIEND_RIDERS (1<<5)


///Flags relating to our AI controller when ridden
//do we halt planning while ridden?
#define RIDING_PAUSE_AI_PLANNING (1<<0)
//do we halt movement while ridden?
#define RIDING_PAUSE_AI_MOVEMENT (1<<1)
//car_traits flags
///Will this car kidnap people by ramming into them?
#define CAN_KIDNAP (1<<0)

#define CLOWN_CANNON_INACTIVE 0
#define CLOWN_CANNON_BUSY 1
#define CLOWN_CANNON_READY 2

//Vim defines
///cooldown between uses of the sound maker
#define VIM_SOUND_COOLDOWN (1 SECONDS)
///how much vim heals per weld
#define VIM_HEAL_AMOUNT 20

// Cyberpunk vehicle core.
#define CY_VEHICLE_BODY_INTERNAL "internal"
#define CY_VEHICLE_BODY_EXTERNAL "external"
#define CY_VEHICLE_BODY_PLATFORM "platform"

#define CY_VEHICLE_CLASS_CIVILIAN "civilian"
#define CY_VEHICLE_CLASS_MODIFIED "modified"
#define CY_VEHICLE_CLASS_COMBAT "combat"

#define CY_VEHICLE_ENGINE_FUEL "fuel"
#define CY_VEHICLE_ENGINE_ENERGY "energy"
#define CY_VEHICLE_ENGINE_BATTERY "battery"

#define CY_VEHICLE_DRIVE_WHEEL "wheel"
#define CY_VEHICLE_DRIVE_TRACK "track"
#define CY_VEHICLE_DRIVE_FLIGHT "flight"

#define CY_VEHICLE_PART_DRIVE "drive"
#define CY_VEHICLE_PART_SUSPENSION "suspension"
#define CY_VEHICLE_PART_HULL "hull"
#define CY_VEHICLE_PART_ENGINE "engine"

#define CY_VEHICLE_MAX_DRIVE_PARTS 6
#define CY_VEHICLE_MIN_DRIVE_PARTS 2
#define CY_VEHICLE_TILE_PIXELS 32
#define CY_VEHICLE_HALF_TILE_PIXELS 16
#define CY_VEHICLE_RECENTER_PIXELS CY_VEHICLE_HALF_TILE_PIXELS
#define CY_VEHICLE_INPUT_LINGER 3

#define CY_VEHICLE_SPEED_SCALE 16
#define CY_VEHICLE_ACCEL_SCALE 80
#define CY_VEHICLE_BRAKE_SCALE 80
#define CY_VEHICLE_TURN_SCALE 4
#define CY_VEHICLE_DRAG_SCALE 4
