/mob/living
	see_invisible = SEE_INVISIBLE_LIVING
	abstract_type = /mob/living
	hud_possible = list(HEALTH_HUD,STATUS_HUD,BLOOD_HUD,ANTAG_HUD)
	pressure_resistance = 10
	hud_type = /datum/hud/living
	interaction_flags_click = ALLOW_RESTING
	interaction_flags_mouse_drop = ALLOW_RESTING

	///Tracks the scale of the mob transformation matrix in relation to its identity. Use update_transform(resize) to change it.
	var/current_size = RESIZE_DEFAULT_SIZE
	///How the mob transformation matrix is scaled on init.
	var/initial_size = RESIZE_DEFAULT_SIZE

	var/lastattacker = null
	var/lastattackerckey = null

	//Health and life related vars
	/// Maximum health that should be possible.
	var/maxHealth = MAX_LIVING_HEALTH
	/// The mob's current health.
	var/health = MAX_LIVING_HEALTH

	/// Maximum active stamina pool.
	var/max_stamina = STAMINA_DEFAULT
	/// Active stamina pool spent by long actions, combat defenses, attacks and running.
	var/stamina = STAMINA_DEFAULT
	///Stamina damage, or exhaustion. You recover it slowly naturally, and are knocked down if it gets too high. Holodeck and hallucinations deal this.
	var/staminaloss = 0

	//Damage related vars, NOTE: THESE SHOULD ONLY BE MODIFIED BY PROCS
	///Brutal damage caused by brute force (punching, being clubbed by a toolbox ect... this also accounts for pressure damage)
	var/bruteloss = 0
	///Oxygen depravation damage (no air in lungs)
	var/oxyloss = 0
	///Toxic damage caused by being poisoned or radiated
	var/toxloss = 0
	///Burn damage caused by being way too hot, too cold or burnt.
	var/fireloss = 0

	/// The movement intent of the mob (run/wal)
	var/move_intent = MOVE_INTENT_RUN
	/// Last player-input sprint direction, used to break sprinting on sharp reversals.
	var/last_sprint_dir = NONE
	/// Prevents overlapping manual jumps.
	var/currently_jumping = FALSE
	/// Current cyberpunk vertical movement state.
	var/vertical_state = VERTICAL_STATE_NONE
	/// world.time when the current vertical state should expire.
	var/vertical_state_until = 0
	/// Stoppable timer for current vertical state expiration.
	var/vertical_state_timer = TIMER_ID_NULL
	/// Stoppable repeating timer for vertical state stamina drain.
	var/vertical_stamina_timer = TIMER_ID_NULL
	/// How many z-falls are chained in the current fall sequence.
	var/vertical_fall_chain = 0
	/// world.time of the last fall sequence update.
	var/vertical_last_fall_time = 0
	/// Lets a delayed recovery fall continue once without scheduling another recovery window.
	var/vertical_ignore_next_fall_delay = FALSE
	/// Turf the mob is currently holding/climbing against.
	var/turf/vertical_anchor_turf
	/// Direction from the mob turf to vertical_anchor_turf.
	var/vertical_anchor_dir = NONE
	/// Pixel offset currently applied to press the mob against vertical_anchor_turf.
	var/vertical_anchor_pixel_x = 0
	/// Pixel offset currently applied to press the mob against vertical_anchor_turf.
	var/vertical_anchor_pixel_y = 0

	/// Cyberpunk NPC dialog/trade/services profile. Null keeps normal mob interactions.
	var/datum/cyberpunk_npc_profile/cyberpunk_npc_profile
	/// Round-local loadout items that were bought but not assigned to an equip/bag slot.
	var/list/cyberpunk_round_wardrobe_items

	/// Rate at which fire stacks should decay from this mob
	var/fire_stack_decay_rate = -0.05

	/// when the mob goes from "normal" to crit
	var/crit_threshold = HEALTH_THRESHOLD_CRIT
	///When the mob enters hard critical state and is fully incapacitated.
	var/hardcrit_threshold = HEALTH_THRESHOLD_FULLCRIT

	//Damage dealing vars! These are meaningless outside of specific instances where it's checked and defined.
	/// Lower bound of damage done by unarmed melee attacks. Mob code is a mess, only works where this is checked for.
	var/melee_damage_lower = 0
	/// Upper bound of damage done by unarmed melee attacks. Please ensure you check the xyz_defenses.dm for the mobs in question to see if it uses this or hardcoded values.
	var/melee_damage_upper = 0

	/// Generic bitflags for boolean conditions at the [/mob/living] level. Keep this for inherent traits of living types, instead of runtime-changeable ones.
	var/living_flags = NONE

	/// Flags that determine the potential of a mob to perform certain actions. Do not change this directly.
	var/mobility_flags = MOBILITY_FLAGS_DEFAULT

	var/resting = FALSE

	/// Variable to track the body position of a mob, regardgless of the actual angle of rotation (usually matching it, but not necessarily).
	var/body_position = STANDING_UP
	/// Number of degrees of rotation of a mob. 0 means no rotation, up-side facing NORTH. 90 means up-side rotated to face EAST, and so on.
	VAR_PROTECTED/lying_angle = 0
	/// Value of lying lying_angle before last change. TODO: Remove the need for this.
	var/lying_prev = 0
	/// Does the mob rotate when lying
	var/rotate_on_lying = FALSE
	///Used by the resist verb, likely used to prevent players from bypassing next_move by logging in/out.
	var/last_special = 0

	///A message sent when the mob dies, with the *deathgasp emote
	var/death_message = ""
	///A sound sent when the mob dies, with the *deathgasp emote
	var/death_sound

	/// Helper vars for quick access to firestacks, these should be updated every time firestacks are adjusted
	var/on_fire = FALSE
	var/fire_stacks = 0

	/**
	  * Allows mobs to move through dense areas without restriction. For instance, in space or out of holder objects.
	  *
	  * FALSE is off, [INCORPOREAL_MOVE_BASIC] is normal, [INCORPOREAL_MOVE_SHADOW] is for ninjas
	  * and [INCORPOREAL_MOVE_JAUNT] is blocked by holy water/salt
	  */
	var/incorporeal_move = FALSE

	/// Lazylist of all quirks the mob has. These are not singletons
	var/list/quirks
	/// Lazylist of all typepaths of personalities the mob has.
	var/list/personalities

	/// Lazylist of surgery speed modifiers - id to number - 2 = 2x faster, 0.5x = 0.5x slower
	var/list/mob_surgery_speed_mods

	/// Used by [living/Bump()][/mob/living/proc/Bump] and [living/PushAM()][/mob/living/proc/PushAM] to prevent potential infinite loop.
	var/now_pushing = null

	///The mob's latest time-of-death
	var/timeofdeath = 0
	///The mob's latest time-of-death, as a station timestamp instead of world.time
	var/station_timestamp_timeofdeath

	/// Sets AI behavior that allows mobs to target and dismember limbs with their basic attack.
	var/limb_destroyer = 0

	var/mob_size = MOB_SIZE_HUMAN
	/// List of biotypes the mob belongs to. Used by diseases and reagents mainly.
	var/mob_biotypes = MOB_ORGANIC
	/// The type of respiration the mob is capable of doing. Used by adjust_oxy_loss.
	var/mob_respiration_type = RESPIRATION_OXYGEN
	///more or less efficiency to metabolize helpful/harmful reagents and regulate body temperature..
	var/metabolism_efficiency = 1
	///does the mob have distinct limbs?(arms,legs, chest,head)
	var/has_limbs = FALSE

	///How many legs does this mob have by default. This shouldn't change at runtime.
	var/default_num_legs = 2
	///How many legs does this mob currently have. Should only be changed through set_num_legs()
	var/num_legs = 2
	///How many usable legs this mob currently has. Should only be changed through set_usable_legs()
	var/usable_legs = 2

	///How many hands does this mob have by default. This shouldn't change at runtime.
	var/default_num_hands = 2
	///How many hands hands does this mob currently have. Should only be changed through set_num_hands()
	var/num_hands = 2
	///How many usable hands does this mob currently have. Should only be changed through set_usable_hands()
	var/usable_hands = 2

	var/list/pipes_shown = list()
	var/last_played_vent = 0
	/// The last direction we moved in a vent. Used to make holding two directions feel nice
	var/last_vent_dir = 0
	/// Cell tracker datum we use to manage the pipes around us, for faster ventcrawling
	/// Should only exist if you're in a pipe
	var/datum/cell_tracker/pipetracker
	/// Cooldown for welded vent movement messages to prevent spam
	COOLDOWN_DECLARE(welded_vent_message_cd)

	var/smoke_delay = 0 ///used to prevent spam with smoke reagent reaction on mob.

	///what icon the mob uses for speechbubbles
	var/bubble_icon = "default"
	///if this exists AND the normal sprite is bigger than 32x32, this is the replacement icon state (because health doll size limitations). the icon will always be screen_gen.dmi
	var/health_doll_icon

	var/last_bumped = 0
	///if a mob's name should be appended with an id when created e.g. Mob (666)
	var/unique_name = FALSE
	///the id a mob gets when it's created
	var/identifier = 0

	///these will be yielded from butchering with a probability chance equal to the butcher item's effectiveness
	var/list/butcher_results = null
	///these will always be yielded from butchering
	var/list/guaranteed_butcher_results = null
	///effectiveness prob. is modified negatively by this amount; positive numbers make it more difficult, negative ones make it easier
	var/butcher_difficulty = 0

	/// How much blood the mob currently has.
	/// Don't read directly, use get_blood_volume() and get_blood_volume(apply_modifiers = TRUE).
	/// Don't write directly either, use set_blood_volume() and adjust_blood_volume().
	/// Also don't initialize this. Initialize default_blood_volume instead.
	var/blood_volume = 0
	/// The default blood volume of the mob. Used primarily for healing bloodloss.
	var/default_blood_volume = 0
	/// Lazylist of blood volume modifiers. These multiply blood volume when get_blood_volume(apply_modifiers = TRUE) is used.
	/// Use set_blood_volume_modifier(multiplier, source) and remove_blood_volume_modifier(source) to modify this.
	var/list/blood_volume_modifiers = null

	///a list of all status effects the mob has
	var/list/status_effects
	/// Active Cyberpunk buff/debuff effects keyed by effect id.
	var/list/cyberpunk_status_effects
	var/list/implants = null

	///used for database logging
	var/last_words

	///whether this can be picked up and held.
	var/can_be_held = FALSE
	/// The w_class of the holder when held.
	var/held_w_class = WEIGHT_CLASS_NORMAL
	///if it can be held, can it be equipped to any slots? (think pAI's on head)
	var/worn_slot_flags = NONE

	var/ventcrawl_layer = PIPING_LAYER_DEFAULT
	var/losebreath = 0

	//List of active diseases
	/// list of all diseases in a mob
	var/list/diseases
	var/list/disease_resistances

	///Whether the mob is slowed down when dragging another prone mob
	var/slowed_by_drag = TRUE

	/// List of changes to body temperature, used by desease symtoms like fever
	var/list/body_temp_changes = list()

	//this stuff is here to make it simple for admins to mess with custom held sprites
	///left hand icon for holding mobs
	var/icon/held_lh = 'icons/mob/inhands/pets_held_lh.dmi'
	///right hand icon for holding mobs
	var/icon/held_rh = 'icons/mob/inhands/pets_held_rh.dmi'
	///what it looks like when the mob is held on your head
	var/icon/head_icon = 'icons/mob/clothing/head/pets_head.dmi'
	/// icon_state for holding mobs.
	var/held_state = ""
	/// Typepath of the holder created when we're picked up
	var/inhand_holder_type = /obj/item/mob_holder

	///If combat mode is on or not
	var/combat_mode = FALSE

	/// Is this mob allowed to be buckled/unbuckled to/from things?
	var/can_buckle_to = TRUE

	///The height offset of a mob's maptext due to their current size.
	var/body_maptext_height_offset = 0

	/// FOV view that is applied from either nativeness or traits
	var/fov_view
	/// Lazy list of FOV traits that will apply a FOV view when handled.
	var/list/fov_traits
	/// Directional FOV used by theft, rear attacks and other code-only awareness checks.
	var/code_fov_angle = 360
	/// Whether this mob is actively listening through nearby obstructions.
	var/listening_intently = FALSE
	/// Recent attackers keyed by ckey/name for Style perk XP sharing exclusions.
	var/list/cyberpunk_recent_style_attackers
	/// Current Cyberpunk cohort membership.
	var/datum/cyberpunk_cohort/cyberpunk_cohort
	/// Temporary acrobatics speed bonus expiry.
	var/cyberpunk_acrobatics_speed_until = 0
	/// Cooldown for Weakness Analysis critical hits.
	var/cyberpunk_last_weakness_crit = 0
	/// Whether the defensive action key is currently held for Space+click controls.
	var/cyberpunk_defensive_action_held = FALSE
	/// Last defensive action selected by Space+click controls.
	var/cyberpunk_last_defensive_action = "parry"
	/// Active parry window expiry.
	var/cyberpunk_parry_until = 0
	/// Active dodge window expiry.
	var/cyberpunk_dodge_until = 0
	/// Body zone currently controlled by this mob's active grab.
	var/cyberpunk_grab_zone = BODY_ZONE_CHEST
	/// Cooldown before this mob can attempt another Cyberpunk grab after a failed upgrade.
	var/cyberpunk_grab_next_attempt = 0
	/// Current durability of this mob's active grab.
	var/cyberpunk_grab_durability = 0
	/// Maximum durability of this mob's active grab at the current grab state.
	var/cyberpunk_grab_max_durability = 0
	/// Cooldown before this mob can resist their current grab again.
	var/cyberpunk_next_grab_resist = 0
	/// Current forced wrestling launch direction.
	var/cyberpunk_wrestling_launch_dir = NONE
	/// World time while this mob can be elbow-checked out of a wrestling launch.
	var/cyberpunk_wrestling_launch_until = 0
	/// Whether the current wrestling launch already rebounded from a wall.
	var/cyberpunk_wrestling_launch_rebounded = FALSE
	/// Cyberpunk carry presentation mode consumed by the human riding component.
	var/cyberpunk_carry_mode
	/// Hand placeholder used while holding a grabbed target.
	var/obj/item/cyberpunk_grab_hold/cyberpunk_grab_hold_item
	/// Second hand placeholder used for two-handed grabs.
	var/obj/item/cyberpunk_grab_hold/cyberpunk_grab_power_hold_item
	/// Current basic Cyberpunk combat intent, switched by 2/3 or mouse wheel.
	var/cyberpunk_combat_intent = "slash"
	/// Whether this mob has manually extended their view to inspect distant targets.
	var/focused_look = FALSE
	/// Whether active listening was started by holding Shift+MMB on self.
	var/cyberpunk_shift_middle_listening = FALSE
	/// Shift+MMB hold start time for entering active listening.
	var/cyberpunk_shift_middle_listen_started = 0
	/// Target captured for Shift+MMB hold activation.
	var/datum/weakref/cyberpunk_shift_middle_listen_ref
	///what multiplicative slowdown we get from turfs currently.
	var/current_turf_slowdown = 0

	/// Direction that this mob is looking at, used for the look_up and look_down procs
	var/looking_vertically = NONE
	///looking holder we use for look_up and look_down. we use this over resetting to the turf because we want to glide
	var/atom/movable/looking_holder/looking_holder
	/// Whether stealth mode is active for this mob.
	var/stealth_mode = FALSE
	/// Whether this mob is hugging nearby solid cover.
	var/wall_hugging = FALSE
	/// Whether wall-hug enabled stealth and should disable it when wall-hug ends.
	var/wall_hug_started_stealth = FALSE
	/// Current chameleon strength from stealth, 0-100.
	var/chameleon = 0
	/// Upper chameleon cap while hidden under furniture.
	var/chameleon_cap = STEALTH_CHAMELEON_MAX
	/// Furniture currently hiding this mob during stealth mode.
	var/atom/movable/stealth_cover
	/// Flat bonus provided by future demons/implants to chameleon checks.
	var/chameleon_bonus = 0
	/// Flat bonus provided by future demons/implants to chameleon change speed.
	var/chameleon_speed_bonus = 0
	/// True if a future demon marks this mob as a camera glitch.
	var/camera_glitch_trail = FALSE
	/// True if a future demon removes this mob from camera feeds.
	var/camera_erased = FALSE

	/// Living mob's mood datum
	var/datum/mood/mob_mood

	// Multiple imaginary friends!
	/// Contains the owner and all imaginary friend mobs if they exist, otherwise null
	var/list/imaginary_group = null

	/// What our current gravity state is. Used to avoid duplicate animates and such
	var/gravity_state = null

	/// How long it takes to return to 0 stam
	var/stamina_regen_time = 10 SECONDS
	/// Last world.time when active stamina was spent.
	var/last_stamina_spend = 0
	var/stamina_regen_accumulator = 0
	var/energy_regen_accumulator = 0
	var/satiation_drain_accumulator = 0
	var/hydration_drain_accumulator = 0
	var/tireness_drain_accumulator = 0
	var/tireness_recovery_accumulator = 0
	var/style_update_accumulator = 0
	var/sleep_deprivation_energy_drain_accumulator = 0
	var/tireness_sleep_grace_until = 0
	var/time_at_min_mood = 0
	var/last_control_loss = 0
	var/last_cyberpsychosis_time = 0
	var/last_combat_time = 0

	/// Lazylists of pixel offsets this mob is currently using
	/// Modify this via add_offsets and remove_offsets,
	/// NOT directly (and definitely avoid modifying offsets directly)
	VAR_PRIVATE/list/offsets

	/// Lazylist of martial arts this mob knows
	/// First element is the current martial art - any other elements are "saved" for if they unlearn the first one
	/// Reference handling is done by the martial arts themselves
	var/list/datum/martial_art/martial_arts

	/// how many tiles can this mob reach with their hands? 1 tile is adjacent.
	var/reach_length = 1

	/// Lazy assoc list of currently applied fishing difficulty modifiers keyed to their source
	var/list/fishing_difficulty_mods_by_source

	/// When less than or equal to  this distance (but not adjacent), this mob can hear parts of distant whispers, but not the entire message.
	/// When greater than this distance, this mob cannot hear anything of a whisper.
	var/eavesdrop_range = EAVESDROP_EXTRA_RANGE
