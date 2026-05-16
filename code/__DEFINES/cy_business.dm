/// Cyberpunk business and contract core defines.
#define CY_BUSINESS_SIZE_SMALL "small"
#define CY_BUSINESS_SIZE_MEDIUM "medium"

#define CY_BUSINESS_LEGAL "legal"
#define CY_BUSINESS_ILLEGAL "illegal"
#define CY_BUSINESS_FRONT "front"

#define CY_BUSINESS_RISK_LOW 10
#define CY_BUSINESS_RISK_MEDIUM 35
#define CY_BUSINESS_RISK_HIGH 70

#define CY_CONTRACT_STATUS_CREATED "created"
#define CY_CONTRACT_STATUS_OPEN "open"
#define CY_CONTRACT_STATUS_ACCEPTED "accepted"
#define CY_CONTRACT_STATUS_ACTIVE "active"
#define CY_CONTRACT_STATUS_COMPLETED "completed"
#define CY_CONTRACT_STATUS_FAILED "failed"
#define CY_CONTRACT_STATUS_DISPUTED "disputed"
#define CY_CONTRACT_STATUS_CLOSED "closed"
#define CY_CONTRACT_STATUS_CANCELLED "cancelled"

#define CY_CONTRACT_LEGAL "legal"
#define CY_CONTRACT_ILLEGAL "illegal"

#define CY_CONTRACT_PUBLIC "public"
#define CY_CONTRACT_CORPORATE "corporate"
#define CY_CONTRACT_PRIVATE "private"
#define CY_CONTRACT_GREY "grey"

#define CY_CONTRACT_DELIVERY "delivery"
#define CY_CONTRACT_PROCUREMENT "procurement"
#define CY_CONTRACT_REPAIR "repair"
#define CY_CONTRACT_CONSTRUCTION "construction"
#define CY_CONTRACT_GUARD "guard"
#define CY_CONTRACT_ESCORT "escort"
#define CY_CONTRACT_EVACUATION "evacuation"
#define CY_CONTRACT_MINING "mining"
#define CY_CONTRACT_SABOTAGE "sabotage"
#define CY_CONTRACT_ELIMINATION "elimination"
#define CY_CONTRACT_RECON "recon"

#define CY_CONTRACT_CONFIRM_DELIVERED "delivered"
#define CY_CONTRACT_CONFIRM_RESTORED "restored"
#define CY_CONTRACT_CONFIRM_BUILT "built"
#define CY_CONTRACT_CONFIRM_ALIVE "alive"
#define CY_CONTRACT_CONFIRM_REACHED "reached"
#define CY_CONTRACT_CONFIRM_DAMAGED "damaged"
#define CY_CONTRACT_CONFIRM_NEUTRALIZED "neutralized"
#define CY_CONTRACT_CONFIRM_SCANNED "scanned"

#define CY_CONTRACT_DEFAULT_SERVICE_FEE 25
#define CY_CONTRACT_DEFAULT_TAX_PERCENT 10
#define CY_BUSINESS_DEFAULT_TAX_DUE 250
#define CY_BUSINESS_SAVE_ROOT "data/cy_businesses"

#define CY_BUSINESS_CAN_PERSIST_OBJECT(thing) (istype(thing, /obj) && !QDELETED(thing))
