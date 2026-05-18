/// Number of paychecks jobs start with at the creation of a new bank account for a player (So at shift-start or game join, but not a blank new account.)
#define STARTING_PAYCHECKS 5
/// How much mail the Economy SS will create per minute, regardless of firing time.
#define MAX_MAIL_PER_MINUTE 3
/// Probability of using letters of envelope sprites on all letters.
#define FULL_CRATE_LETTER_ODDS 70

//Current Paycheck values. Altering these changes both the cost of items meant for each paygrade, as well as the passive/starting income of each job.
///Default paygrade for the Unassigned Job/Unpaid job assignments.
#define PAYCHECK_ZERO 0
///Paygrade for Prisoners and Assistants.
#define PAYCHECK_LOWER 25
///Paygrade for all regular crew not belonging to PAYGRADE_LOWER or PAYGRADE_COMMAND.
#define PAYCHECK_CREW 50
///Paygrade for Heads of Staff.
#define PAYCHECK_COMMAND 100



#define STATION_TARGET_BUFFER 25

///The coefficient for the amount of dosh that's collected everytime some is earned or received.
#define DEBT_COLLECTION_COEFF 0.75

#define MAX_GRANT_DPT 500

//What should vending machines charge when you buy something in-department.
#define DEPARTMENT_DISCOUNT 0.2

//the amount of credits collected by the vending machines that can be redeemed when restocking it.
#define VENDING_CREDITS_COLLECTION_AMOUNT 0.2

#define ACCOUNT_CIV "CIV"
#define ACCOUNT_CIV_NAME "Гражданский бюджет"
#define ACCOUNT_ENG "ENG"
#define ACCOUNT_ENG_NAME "Инженерный бюджет"
#define ACCOUNT_SCI "SCI"
#define ACCOUNT_SCI_NAME "Научный бюджет"
#define ACCOUNT_MED "MED"
#define ACCOUNT_MED_NAME "Медицинский бюджет"
#define ACCOUNT_SRV "SRV"
#define ACCOUNT_SRV_NAME "Бюджет обслуживания"
#define ACCOUNT_CAR "CAR"
#define ACCOUNT_CAR_NAME "Бюджет снабжения"
#define ACCOUNT_SEC "SEC"
#define ACCOUNT_SEC_NAME "Оборонный бюджет"

#define IS_DEPARTMENTAL_CARD(card) (card in SSeconomy.dep_cards)
#define IS_DEPARTMENTAL_ACCOUNT(account) (account in SSeconomy.departmental_accounts)

#define NO_FREEBIES "commies go home"

/// The special account ID for admins using debug cards.
#define ADMIN_ACCOUNT_ID "ADMIN!"

//Defines that set what kind of civilian bounties should be applied mid-round.
#define CIV_JOB_BASIC 1
#define CIV_JOB_ROBO 2
#define CIV_JOB_CHEF 3
#define CIV_JOB_SEC 4
#define CIV_JOB_DRINK 5
#define CIV_JOB_CHEM 6
#define CIV_JOB_VIRO 7
#define CIV_JOB_SCI 8
#define CIV_JOB_ENG 9
#define CIV_JOB_MINE 10
#define CIV_JOB_MED 11
#define CIV_JOB_GROW 12
#define CIV_JOB_ATMOS 13
#define CIV_JOB_BITRUN 14
#define CIV_JOB_RANDOM 15

#define MAXIMUM_BOUNTY_JOBS 14 //Should be equal to the highest numbered non-random job above.

//These defines are to be used to with the payment component, determines which lines will be used during a transaction. If in doubt, go with clinical.
#define PAYMENT_CLINICAL "clinical"
#define PAYMENT_FRIENDLY "friendly"
#define PAYMENT_ANGRY "angry"
#define PAYMENT_VENDING "vending"

#define MARKET_TREND_UPWARD 1
#define MARKET_TREND_DOWNWARD -1
#define MARKET_TREND_STABLE 0

#define MARKET_EVENT_PROBABILITY 8 //Probability of a market event firing, in percent. Fires once per material, every stock market tick.
/// How much of the total value of a bounty cube does the player receive when the cube is exported?
#define BOUNTY_CUT_STANDARD 0.3

// Fair warning that these defines at present are not used in all tgui, static descriptions, or any varible names or comments
/// The symbol for the default type of money used in the code.
#define MONEY_SYMBOL "¢"
/// The name for the default type of money used in the code.
#define MONEY_NAME "¢"
#define MONEY_NAME_SINGULAR "¢"
#define MONEY_NAME_CAPITALIZED "¢"
// Due to the ways macros work, I cant just directly use credit\s.
// You will need to verify there is no loose use cases of credit\s.
// As of present there is none left floating around.
#define MONEY_NAME_AUTOPURAL(amount) "¢"

#define MONEY_MINING_SYMBOL "mp"
#define MONEY_BITRUNNING_SYMBOL "np"

//Mood event from minor slot events like winning/losing a few bits.
#define SLOTS_MOOD_CATEGORY "slots"


// Cyberpunk city economy core
#define CY_ACCOUNT_GOVERNMENT "government"
#define CY_ACCOUNT_BEN "ben_conglomerate"
#define CY_ACCOUNT_RYAZNOV "ryaznov_union"
#define CY_ACCOUNT_STARLIGHT "starlight_group"
#define CY_ACCOUNT_CIV_MARKET "civilian_market"
#define CY_ACCOUNT_EXPORT_POOL "export_pool"
#define CY_ACCOUNT_BLACK_MARKET "black_market"

#define CY_CITY_GOVERNMENT_STARTING_BALANCE 50000
#define CY_CITY_GOVERNMENT_STARTING_BUDGET 25000
#define CY_CITY_CORP_STARTING_BALANCE 40000
#define CY_CITY_CORP_STARTING_BUDGET 20000
#define CY_CITY_MARKET_STARTING_BALANCE 15000
#define CY_CITY_MARKET_STARTING_BUDGET 5000
#define CY_CITY_EXPORT_POOL_STARTING_BALANCE 100000
#define CY_CITY_EXPORT_POOL_STARTING_BUDGET 100000
#define CY_CITY_BLACK_MARKET_STARTING_BALANCE 10000
#define CY_CITY_BLACK_MARKET_STARTING_BUDGET 10000

#define CY_ECON_VISIBILITY_BANK "bank"
#define CY_ECON_VISIBILITY_CASH "cash"
#define CY_ECON_VISIBILITY_SHADOW "shadow"
#define CY_ECON_VISIBILITY_RESTRICTED "restricted"

#define CY_ECON_CHANNEL_BANK "bank"
#define CY_ECON_CHANNEL_CASH "cash"
#define CY_ECON_CHANNEL_VENDOR "vendor"
#define CY_ECON_CHANNEL_EXPORT "export"
#define CY_ECON_CHANNEL_LOAN "loan"
#define CY_ECON_CHANNEL_FINE "fine"
#define CY_ECON_CHANNEL_CONTRACT "contract"
#define CY_ECON_CHANNEL_NETLOG "netlog"

#define CY_TAX_NONE "none"
#define CY_TAX_VENDOR "vendor"
#define CY_TAX_SERVICE "service"
#define CY_TAX_CONTRACT "contract"
#define CY_TAX_TRANSFER "transfer"
#define CY_TAX_LOAN "loan"

#define CY_CITY_VENDOR_TAX_RATE 0.08
#define CY_CITY_SERVICE_TAX_RATE 0.06
#define CY_CITY_CONTRACT_TAX_RATE 0.1
#define CY_CITY_TRANSFER_TAX_RATE 0.02
#define CY_CITY_LOAN_FEE_RATE 0.01

#define CY_CITY_DEFAULT_PRICE_MULTIPLIER 1.6
#define CY_CITY_MIN_PRICE_MULTIPLIER 0.75
#define CY_CITY_SUPPLY_PRICE_DIVISOR 50000
#define CY_CITY_LEDGER_MAX_ENTRIES 2000
#define CY_CITY_FORENSIC_MAX_TRACES 1000

#define CY_SUPPLY_GENERAL "general"

#define CY_LOAN_ACTIVE "active"
#define CY_LOAN_PAID "paid"
#define CY_LOAN_DEFAULTED "defaulted"
#define CY_LOAN_VOID "void"

#define CY_CRIME_SEVERITY_MINOR 1
#define CY_CRIME_SEVERITY_MEDIUM 2
#define CY_CRIME_SEVERITY_MAJOR 3

#define CY_WARRANT_NONE 0
#define CY_WARRANT_FINE 1
#define CY_WARRANT_INVESTIGATION 2
#define CY_WARRANT_ARREST 3
#define CY_WARRANT_KILL 4
#define CY_WARRANT_CLEARED 5

#define CY_LAW_ASSAULT "assault"
#define CY_LAW_THEFT "theft"
#define CY_LAW_SABOTAGE "sabotage"
#define CY_LAW_MURDER "murder"
#define CY_LAW_NETCRIME "netcrime"
#define CY_LAW_TRESPASS "trespass"
#define CY_LAW_CONTROLLED_ITEM "controlled_item"

#define CY_SECURITY_ZONE_WILDS 0
#define CY_SECURITY_ZONE_LOW 1
#define CY_SECURITY_ZONE_PUBLIC 2
#define CY_SECURITY_ZONE_SECURE 3
#define CY_SECURITY_ZONE_CORPORATE 4

#define CY_STORY_PRESSURE_VIOLENCE "violence"
#define CY_STORY_PRESSURE_ECONOMY "economy"
#define CY_STORY_PRESSURE_CORPORATE "corporate"
#define CY_STORY_PRESSURE_BLACK_MARKET "black_market"
#define CY_STORY_PRESSURE_RESCUE "rescue"
#define CY_STORY_PRESSURE_LAW "law"

#define CY_STORY_ENDING_STABILITY "stability"
#define CY_STORY_ENDING_CORPORATE "corporate_capture"
#define CY_STORY_ENDING_BLACK_MARKET "black_market"
#define CY_STORY_ENDING_COLLAPSE "collapse"
#define CY_STORY_ENDING_SURVIVAL "survival"

#define CY_POLICE_DB_ACCESS "police_database"
#define CY_BOUNTY_HUNTER_ACCESS "bounty_hunter_database"
#define CY_GOVERNMENT_LEDGER_ACCESS "government_ledger"
