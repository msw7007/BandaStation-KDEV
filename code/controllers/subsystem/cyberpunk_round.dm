SUBSYSTEM_DEF(cyberpunk_round)
	name = "Cyberpunk Round"
	wait = 1 MINUTES
	runlevels = RUNLEVEL_GAME
	//CYBERPUNK BUILD - rebuild and delete before release
	/// Real time budget of one cyberpunk city day.
	var/cyberpunk_round_real_day = 30 MINUTES
	/// Development/test switch: one day phase lasts five real minutes, so one full day lasts twenty.
	var/cyberpunk_round_fast_day_enabled = FALSE
	/// Real time budget of one in-game day phase when accelerated time is enabled.
	var/cyberpunk_round_fast_phase_duration = 5 MINUTES
	/// Real time budget of the base cyberpunk round.
	var/cyberpunk_round_real_duration = 210 MINUTES
	/// Delay before the storyteller starts applying regular pressure.
	var/cyberpunk_round_main_flow_delay = 15 MINUTES
	/// In-game day where late-round escalation starts.
	var/cyberpunk_round_escalation_day = 6
	/// Extra in-game days granted when players vote to continue.
	var/cyberpunk_round_extension_days = 2
	/// Maximum number of automatic player-voted extensions.
	var/cyberpunk_round_max_extensions = 1
	/// Number of extensions already applied this round.
	var/cyberpunk_round_extensions_used = 0
	/// Current in-game minute of the day, 0-1439.
	var/cyberpunk_round_ingame_minutes = 0
	/// Minimum time between snapshot rebuilds.
	var/cyberpunk_round_snapshot_interval = 1 MINUTES
	/// Minimum time between expensive infrastructure rebuilds.
	var/cyberpunk_round_infrastructure_interval = 5 MINUTES
	/// Minimum time between storyteller pulses.
	var/cyberpunk_round_storyteller_interval = 2 MINUTES
	/// Minimum time between storyteller executions.
	var/cyberpunk_storyteller_min_event_gap = 4 MINUTES
	/// Minimum time between attempts to seed a new long-running story arc.
	var/cyberpunk_storyteller_arc_seed_interval = 8 MINUTES
	/// Maximum number of simultaneous story arcs.
	var/cyberpunk_storyteller_max_active_arcs = 3
	/// Last arc seed world time.
	var/cyberpunk_storyteller_last_arc_seed_at = 0
	/// Incremental id for generated story arcs.
	var/cyberpunk_storyteller_next_arc_id = 1
	/// World time when the cyberpunk round clock started.
	var/cyberpunk_round_started_at = 0
	/// Last snapshot build world time.
	var/cyberpunk_round_last_snapshot_at = 0
	/// Last storyteller pulse world time.
	var/cyberpunk_round_last_storyteller_at = 0
	/// Current in-game day, 1-based.
	var/cyberpunk_round_day = 1
	/// Current round phase id.
	var/cyberpunk_round_phase = "preparation"
	/// Current round phase display name.
	var/cyberpunk_round_phase_name = "Preparation"
	/// Current round stage.
	var/cyberpunk_round_stage = "preparation"
	/// Current measured city pressure.
	var/cyberpunk_round_chaos = 0
	/// Expected pressure for this point of the round.
	var/cyberpunk_round_expected_chaos = 0
	/// Acceptable pressure deviation for this point of the round.
	var/cyberpunk_round_chaos_tolerance = 10
	/// Current endround state.
	var/cyberpunk_round_end_state = "inactive"
	/// World time when the endround vote was started.
	var/cyberpunk_round_end_vote_started_at = 0
	/// Whether the roundstart city report has been announced.
	var/cyberpunk_round_start_report_announced = FALSE
	/// Whether catastrophic auto-evac has already been requested.
	var/cyberpunk_round_catastrophic_evac_requested = FALSE
	/// Whether final summary has already been handed to blackbox feedback this round.
	var/cyberpunk_round_summary_recorded = FALSE
	/// Whether previous summary JSON has been loaded for start reports.
	var/cyberpunk_round_previous_summary_loaded = FALSE
	/// Last generated round summary.
	var/list/cyberpunk_round_last_summary = list()
	/// Last round summary loaded from data/cyberpunk_round_summary.json.
	var/list/cyberpunk_round_previous_summary = list()
	/// Per-admin UI payload tab. Used to avoid shipping heavy storyteller payloads when a tab is closed.
	var/list/cyberpunk_round_ui_payload_tabs = list()
	/// Last city snapshot used by the storyteller.
	var/list/cyberpunk_round_last_snapshot = list()
	/// Last expensive infrastructure metrics bundle.
	var/list/cyberpunk_round_last_infrastructure = list()
	/// Last infrastructure metrics build world time.
	var/cyberpunk_round_last_infrastructure_at = 0
	/// World time before which full round metrics should not run after round start.
	var/cyberpunk_round_heavy_metrics_defer_until = 0
	/// Storyteller pressure curve generated from the active profile.
	var/list/cyberpunk_storyteller_curve = list()
	/// Current coarse event plan generated from the active curve.
	var/list/cyberpunk_storyteller_round_plan = list()
	/// Storyteller event history. These are draft hooks until real event executors are wired.
	var/list/cyberpunk_round_event_history = list()
	/// Active storyteller hooks.
	var/list/cyberpunk_round_active_events = list()
	/// Recent event type cooldowns.
	var/list/cyberpunk_round_recent_event_types = list()
	/// Current storyteller candidate pool.
	var/list/cyberpunk_round_storyteller_candidates = list()
	/// Active multi-pulse story arcs that drive event/ruleset choices.
	var/list/cyberpunk_storyteller_active_arcs = list()
	/// Last use time by story theme.
	var/list/cyberpunk_storyteller_topic_memory = list()
	/// Last use time by faction/source.
	var/list/cyberpunk_storyteller_faction_memory = list()
	/// Last use time by district.
	var/list/cyberpunk_storyteller_district_memory = list()
	/// World time of the last actual storyteller execution.
	var/cyberpunk_storyteller_last_executed_at = 0
	/// Storyteller may directly execute old event/ruleset backends.
	var/cyberpunk_storyteller_auto_execute = TRUE
	/// Active storyteller profile id.
	var/cyberpunk_storyteller_profile = "balanced"
	/// Storyteller profile options.
	var/list/cyberpunk_storyteller_profile_options = list()
	/// Concrete SSevents package registry.
	var/list/cyberpunk_storyteller_event_packages = list()
	/// Concrete SSdynamic midround package registry.
	var/list/cyberpunk_storyteller_dynamic_packages = list()
	/// Deferred SSevents requests waiting for storyteller planning.
	var/cyberpunk_storyteller_event_request_pressure = 0
	/// Deferred SSdynamic requests waiting for storyteller planning.
	var/cyberpunk_storyteller_dynamic_request_pressure = 0
	/// Admin/story deferred concrete package ids waiting for the next storyteller pulse.
	var/list/cyberpunk_storyteller_deferred_package_ids = list()
	/// Storyteller owns automatic SSevents rolls.
	var/cyberpunk_storyteller_random_events_enabled = TRUE
	/// Storyteller owns automatic dynamic ruleset rolls.
	var/cyberpunk_storyteller_dynamic_rules_enabled = TRUE
	/// Whether round phases project daylight onto open-sky turfs.
	var/cyberpunk_daylight_enabled = TRUE
	/// Sparse daylight source spacing. One light source per N turfs.
	var/cyberpunk_daylight_stride = 4
	/// Last daylight phase applied to the world.
	var/cyberpunk_daylight_last_phase
	/// Last smooth daylight update bucket.
	var/cyberpunk_daylight_last_bucket = -1
	/// Last smooth daylight power pushed into open-sky sources.
	var/cyberpunk_daylight_current_power = 0
	/// Last smooth daylight range pushed into open-sky sources.
	var/cyberpunk_daylight_current_range = 0
	/// Last smooth daylight color pushed into open-sky sources.
	var/cyberpunk_daylight_current_color = "#ffffff"
	/// World time before which daylight source generation should not run after round start.
	var/cyberpunk_daylight_defer_until = 0
	/// Sparse daylight source objects keyed by turf coordinate.
	var/list/cyberpunk_daylight_sources = list()
	/// Daylight strength per phase.
	var/list/cyberpunk_daylight_power_by_phase = list("night" = 0.08, "morning" = 0.45, "day" = 0.85, "evening" = 0.35)
	/// Daylight radius per phase.
	var/list/cyberpunk_daylight_range_by_phase = list("night" = 1, "morning" = 3, "day" = 4, "evening" = 3)
	/// Daylight color per phase.
	var/list/cyberpunk_daylight_color_by_phase = list("night" = "#1a2540", "morning" = "#ffd08a", "day" = "#fff6d6", "evening" = "#e07a55")
	//CYBERPUNK BUILD - rebuild and delete before release

/datum/controller/subsystem/cyberpunk_round/Recover()
	cyberpunk_round_started_at = SScyberpunk_round.cyberpunk_round_started_at
	cyberpunk_round_last_snapshot_at = SScyberpunk_round.cyberpunk_round_last_snapshot_at
	cyberpunk_round_last_storyteller_at = SScyberpunk_round.cyberpunk_round_last_storyteller_at
	cyberpunk_round_day = SScyberpunk_round.cyberpunk_round_day
	cyberpunk_round_extensions_used = SScyberpunk_round.cyberpunk_round_extensions_used
	cyberpunk_round_phase = SScyberpunk_round.cyberpunk_round_phase
	cyberpunk_round_phase_name = SScyberpunk_round.cyberpunk_round_phase_name
	cyberpunk_round_ingame_minutes = SScyberpunk_round.cyberpunk_round_ingame_minutes
	cyberpunk_round_stage = SScyberpunk_round.cyberpunk_round_stage
	cyberpunk_round_chaos = SScyberpunk_round.cyberpunk_round_chaos
	cyberpunk_round_expected_chaos = SScyberpunk_round.cyberpunk_round_expected_chaos
	cyberpunk_round_chaos_tolerance = SScyberpunk_round.cyberpunk_round_chaos_tolerance
	cyberpunk_round_end_state = SScyberpunk_round.cyberpunk_round_end_state
	cyberpunk_round_end_vote_started_at = SScyberpunk_round.cyberpunk_round_end_vote_started_at
	cyberpunk_round_start_report_announced = SScyberpunk_round.cyberpunk_round_start_report_announced
	cyberpunk_round_catastrophic_evac_requested = SScyberpunk_round.cyberpunk_round_catastrophic_evac_requested
	cyberpunk_round_summary_recorded = SScyberpunk_round.cyberpunk_round_summary_recorded
	cyberpunk_round_previous_summary_loaded = SScyberpunk_round.cyberpunk_round_previous_summary_loaded
	cyberpunk_round_last_summary = SScyberpunk_round.cyberpunk_round_last_summary
	cyberpunk_round_previous_summary = SScyberpunk_round.cyberpunk_round_previous_summary
	cyberpunk_round_ui_payload_tabs = SScyberpunk_round.cyberpunk_round_ui_payload_tabs
	cyberpunk_round_last_snapshot = SScyberpunk_round.cyberpunk_round_last_snapshot
	cyberpunk_round_last_infrastructure = SScyberpunk_round.cyberpunk_round_last_infrastructure
	cyberpunk_round_last_infrastructure_at = SScyberpunk_round.cyberpunk_round_last_infrastructure_at
	cyberpunk_round_heavy_metrics_defer_until = SScyberpunk_round.cyberpunk_round_heavy_metrics_defer_until
	cyberpunk_storyteller_curve = SScyberpunk_round.cyberpunk_storyteller_curve
	cyberpunk_storyteller_round_plan = SScyberpunk_round.cyberpunk_storyteller_round_plan
	cyberpunk_round_event_history = SScyberpunk_round.cyberpunk_round_event_history
	cyberpunk_round_active_events = SScyberpunk_round.cyberpunk_round_active_events
	cyberpunk_round_recent_event_types = SScyberpunk_round.cyberpunk_round_recent_event_types
	cyberpunk_round_storyteller_candidates = SScyberpunk_round.cyberpunk_round_storyteller_candidates
	cyberpunk_storyteller_active_arcs = SScyberpunk_round.cyberpunk_storyteller_active_arcs
	cyberpunk_storyteller_topic_memory = SScyberpunk_round.cyberpunk_storyteller_topic_memory
	cyberpunk_storyteller_faction_memory = SScyberpunk_round.cyberpunk_storyteller_faction_memory
	cyberpunk_storyteller_district_memory = SScyberpunk_round.cyberpunk_storyteller_district_memory
	cyberpunk_storyteller_last_arc_seed_at = SScyberpunk_round.cyberpunk_storyteller_last_arc_seed_at
	cyberpunk_storyteller_next_arc_id = SScyberpunk_round.cyberpunk_storyteller_next_arc_id
	cyberpunk_storyteller_last_executed_at = SScyberpunk_round.cyberpunk_storyteller_last_executed_at
	cyberpunk_storyteller_auto_execute = SScyberpunk_round.cyberpunk_storyteller_auto_execute
	cyberpunk_storyteller_profile = SScyberpunk_round.cyberpunk_storyteller_profile
	cyberpunk_storyteller_profile_options = SScyberpunk_round.cyberpunk_storyteller_profile_options
	cyberpunk_storyteller_event_packages = SScyberpunk_round.cyberpunk_storyteller_event_packages
	cyberpunk_storyteller_dynamic_packages = SScyberpunk_round.cyberpunk_storyteller_dynamic_packages
	cyberpunk_storyteller_event_request_pressure = SScyberpunk_round.cyberpunk_storyteller_event_request_pressure
	cyberpunk_storyteller_dynamic_request_pressure = SScyberpunk_round.cyberpunk_storyteller_dynamic_request_pressure
	cyberpunk_storyteller_deferred_package_ids = SScyberpunk_round.cyberpunk_storyteller_deferred_package_ids
	cyberpunk_storyteller_random_events_enabled = SScyberpunk_round.cyberpunk_storyteller_random_events_enabled
	cyberpunk_storyteller_dynamic_rules_enabled = SScyberpunk_round.cyberpunk_storyteller_dynamic_rules_enabled
	cyberpunk_round_fast_day_enabled = SScyberpunk_round.cyberpunk_round_fast_day_enabled
	cyberpunk_round_real_day = SScyberpunk_round.cyberpunk_round_real_day
	cyberpunk_round_real_duration = SScyberpunk_round.cyberpunk_round_real_duration
	cyberpunk_daylight_enabled = SScyberpunk_round.cyberpunk_daylight_enabled
	cyberpunk_daylight_last_phase = null
	cyberpunk_daylight_last_bucket = -1
	cyberpunk_daylight_current_power = SScyberpunk_round.cyberpunk_daylight_current_power
	cyberpunk_daylight_current_range = SScyberpunk_round.cyberpunk_daylight_current_range
	cyberpunk_daylight_current_color = SScyberpunk_round.cyberpunk_daylight_current_color
	cyberpunk_daylight_defer_until = SScyberpunk_round.cyberpunk_daylight_defer_until
	cyberpunk_daylight_sources = list()

/datum/controller/subsystem/cyberpunk_round/fire(resumed = 0)
	process_cyberpunk_round()

/datum/controller/subsystem/cyberpunk_round/Shutdown()
	record_cyberpunk_round_summary("shutdown")
	return ..()

/datum/controller/subsystem/cyberpunk_round/proc/process_cyberpunk_round()
	if(!SSticker || !SSticker.IsRoundInProgress())
		return
	if(!cyberpunk_round_started_at)
		start_cyberpunk_round_clock()
	update_cyberpunk_round_clock()
	if(world.time >= cyberpunk_daylight_defer_until)
		update_cyberpunk_daylight()
	if(world.time < cyberpunk_round_heavy_metrics_defer_until)
		return
	if(!cyberpunk_round_last_snapshot_at || world.time >= cyberpunk_round_last_snapshot_at + cyberpunk_round_snapshot_interval)
		cyberpunk_round_last_snapshot = build_cyberpunk_round_snapshot()
		cyberpunk_round_last_snapshot_at = world.time
	if(!cyberpunk_round_last_storyteller_at || world.time >= cyberpunk_round_last_storyteller_at + cyberpunk_round_storyteller_interval)
		cyberpunk_storyteller_pulse()
		cyberpunk_round_last_storyteller_at = world.time
	cyberpunk_round_process_endround()

/datum/controller/subsystem/cyberpunk_round/proc/start_cyberpunk_round_clock()
	cyberpunk_round_started_at = SSticker ? (SSticker.round_start_time || world.time) : world.time
	SScyberpunk_corporations?.ensure_cyberpunk_corporations_seeded()
	SSeconomy?.ensure_cyberpunk_corporate_contracts_seeded()
	cyberpunk_round_last_snapshot_at = 0
	cyberpunk_round_last_infrastructure = cyberpunk_round_empty_infrastructure_metrics()
	cyberpunk_round_last_infrastructure_at = 0
	cyberpunk_round_heavy_metrics_defer_until = world.time + 45 SECONDS
	cyberpunk_round_last_storyteller_at = 0
	cyberpunk_round_event_history = list()
	cyberpunk_round_active_events = list()
	cyberpunk_round_recent_event_types = list()
	cyberpunk_round_storyteller_candidates = list()
	cyberpunk_storyteller_active_arcs = list()
	cyberpunk_storyteller_topic_memory = list()
	cyberpunk_storyteller_faction_memory = list()
	cyberpunk_storyteller_district_memory = list()
	cyberpunk_storyteller_last_executed_at = 0
	cyberpunk_storyteller_last_arc_seed_at = 0
	cyberpunk_storyteller_next_arc_id = 1
	cyberpunk_storyteller_event_request_pressure = 0
	cyberpunk_storyteller_dynamic_request_pressure = 0
	cyberpunk_storyteller_deferred_package_ids = list()
	cyberpunk_round_extensions_used = 0
	cyberpunk_round_end_state = "active"
	cyberpunk_round_end_vote_started_at = 0
	cyberpunk_round_start_report_announced = FALSE
	cyberpunk_round_catastrophic_evac_requested = FALSE
	cyberpunk_round_summary_recorded = FALSE
	cyberpunk_round_last_summary = list()
	cyberpunk_daylight_defer_until = world.time + 90 SECONDS
	cyberpunk_daylight_last_phase = null
	ensure_cyberpunk_storyteller_config()
	cyberpunk_storyteller_rebuild_round_plan()
	record_cyberpunk_round_event("round_clock_started", "city", "city", 0, "Cyberpunk round clock started.", "completed")
	addtimer(CALLBACK(src, PROC_REF(cyberpunk_round_send_start_report)), 45 SECONDS)

/datum/controller/subsystem/cyberpunk_round/proc/set_cyberpunk_round_fast_day_mode(enabled)
	cyberpunk_round_fast_day_enabled = !!enabled
	cyberpunk_round_real_day = cyberpunk_round_fast_day_enabled ? max(cyberpunk_round_fast_phase_duration * 4, 1 MINUTES) : initial(cyberpunk_round_real_day)
	cyberpunk_round_real_duration = cyberpunk_round_real_day * (7 + (cyberpunk_round_extensions_used * cyberpunk_round_extension_days))
	cyberpunk_storyteller_curve = cyberpunk_storyteller_build_curve()
	cyberpunk_storyteller_rebuild_round_plan()
	cyberpunk_daylight_last_phase = null
	cyberpunk_daylight_last_bucket = -1
	update_cyberpunk_round_clock()
	update_cyberpunk_daylight()
	var/mode_text = cyberpunk_round_fast_day_enabled ? "enabled" : "disabled"
	var/phase_duration = cyberpunk_round_fast_day_enabled ? cyberpunk_round_fast_phase_duration : round(initial(cyberpunk_round_real_day) / 4)
	record_cyberpunk_round_event("fast_day_mode", "city", "city", cyberpunk_round_chaos, "Fast day mode [mode_text]. Phase length: [phase_duration].", "completed")

/datum/controller/subsystem/cyberpunk_round/proc/ensure_cyberpunk_storyteller_config()
	if(!length(cyberpunk_storyteller_profile_options))
		cyberpunk_storyteller_profile_options = list(
			"balanced" = build_cyberpunk_storyteller_profile("balanced", "Balanced", 1, 1, 0.85, 1, 1, 85, 1, 1, 1, 1, 1),
			"street" = build_cyberpunk_storyteller_profile("street", "Street Soft", 1.35, 0.75, 0.35, 1.3, 1.4, 70, 0.7, 1.2, 1.2, 0.85, 0.75),
			"escalation" = build_cyberpunk_storyteller_profile("escalation", "Escalation", 0.9, 1.25, 1.45, 0.65, 0.75, 95, 1.4, 0.9, 1.15, 1.25, 1.35),
		)
	if(!cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile])
		cyberpunk_storyteller_profile = "balanced"
	if(!length(cyberpunk_storyteller_event_packages))
		cyberpunk_storyteller_event_packages = list(
			build_cyberpunk_storyteller_event_package("aurora", "Aurora Caelus", "Aurora Caelus", 55, list("recovery", "city"), -4, 0, null, "city", "temporary", 12 MINUTES),
			build_cyberpunk_storyteller_event_package("major_space_dust", "Major Space Dust", "Major Space Dust", 40, list("city", "security"), 6, 15 MINUTES, null, "city", "temporary", 14 MINUTES),
			build_cyberpunk_storyteller_event_package("meteor_normal", "Meteor Wave: Normal", "Meteor Wave: Normal", 45, list("city", "security"), 12, 25 MINUTES, null, "city", "temporary", 18 MINUTES),
			build_cyberpunk_storyteller_event_package("meteor_threatening", "Meteor Wave: Threatening", "Meteor Wave: Threatening", 55, list("escalation", "security"), 20, 35 MINUTES, null, "city", "temporary", 22 MINUTES),
			build_cyberpunk_storyteller_event_package("meteor_catastrophic", "Meteor Wave: Catastrophic", "Meteor Wave: Catastrophic", 25, list("escalation"), 34, 45 MINUTES, null, "city", "temporary", 35 MINUTES),
			build_cyberpunk_storyteller_event_package("ion_storm", "Ion Storm", "Ion Storm", 35, list("corporate", "security", "network"), 8, 10 MINUTES, null, "network", "temporary", 12 MINUTES),
			build_cyberpunk_storyteller_event_package("communications_blackout", "Communications Blackout", "Communications Blackout", 35, list("corporate", "security", "network"), 10, 10 MINUTES, null, "network", "temporary", 14 MINUTES),
			build_cyberpunk_storyteller_event_package("market_crash", "Market Crash", "Market Crash", 40, list("economy", "corporate"), 4, 0, null, "city", "instant", 18 MINUTES),
			build_cyberpunk_storyteller_event_package("grid_check", "Grid Check", "Grid Check", 30, list("city", "recovery"), 3, 0, null, "city", "temporary", 12 MINUTES),
			build_cyberpunk_storyteller_event_package("radiation_storm", "Radiation Storm", "Radiation Storm", 25, list("security", "escalation"), 18, 20 MINUTES, null, "city", "temporary", 24 MINUTES),
			build_cyberpunk_storyteller_event_package("mass_hallucination", "Mass Hallucination", "Mass Hallucination", 30, list("city", "security"), 10, 10 MINUTES, null, "city", "temporary", 16 MINUTES),
		)
	if(!length(cyberpunk_storyteller_dynamic_packages))
		cyberpunk_storyteller_dynamic_packages = list(
			build_cyberpunk_storyteller_dynamic_package("pirates_light", "Light Pirates", /datum/dynamic_ruleset/midround/pirates, "dynamic_light", 45, list("corporate", "contracts", "city"), 14, 15 MINUTES, null, "external", "long", 24 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("abductors", "Abductors", /datum/dynamic_ruleset/midround/from_ghosts/abductors, "dynamic_light", 35, list("corporate", "security"), 12, 20 MINUTES, null, "external", "long", 24 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("revenant", "Revenant", /datum/dynamic_ruleset/midround/from_ghosts/revenant, "dynamic_light", 35, list("security", "city"), 10, 15 MINUTES, null, "local", "long", 20 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("nightmare", "Nightmare", /datum/dynamic_ruleset/midround/from_ghosts/nightmare, "dynamic_light", 25, list("security", "escalation"), 13, 25 MINUTES, null, "local", "long", 24 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("blood_worms", "Blood Worm Infestation", /datum/dynamic_ruleset/midround/from_ghosts/blood_worms, "dynamic_light", 25, list("escalation", "city"), 16, 25 MINUTES, null, "local", "long", 26 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("pirates_heavy", "Heavy Pirates", /datum/dynamic_ruleset/midround/pirates/heavy, "dynamic_heavy", 45, list("corporate", "contracts", "escalation"), 24, 35 MINUTES, null, "external", "long", 35 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("spiders", "Spiders", /datum/dynamic_ruleset/midround/spiders, "dynamic_heavy", 35, list("escalation", "security"), 26, 35 MINUTES, null, "local", "long", 35 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("blob", "Blob", /datum/dynamic_ruleset/midround/from_ghosts/blob, "dynamic_heavy", 35, list("escalation", "security"), 30, 45 MINUTES, null, "city", "long", 40 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("xenomorph", "Alien Infestation", /datum/dynamic_ruleset/midround/from_ghosts/xenomorph, "dynamic_heavy", 35, list("escalation", "security"), 30, 45 MINUTES, null, "city", "long", 40 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("nukies", "Midround Nukeops", /datum/dynamic_ruleset/midround/from_ghosts/nukies, "dynamic_heavy", 25, list("escalation", "corporate"), 36, 60 MINUTES, null, "external", "long", 50 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("wizard", "Midround Wizard", /datum/dynamic_ruleset/midround/from_ghosts/wizard, "dynamic_heavy", 20, list("escalation", "city"), 30, 60 MINUTES, null, "city", "long", 45 MINUTES),
			build_cyberpunk_storyteller_dynamic_package("space_dragon", "Space Dragon", /datum/dynamic_ruleset/midround/from_ghosts/space_dragon, "dynamic_heavy", 20, list("escalation"), 34, 60 MINUTES, null, "external", "long", 50 MINUTES),
		)
	if(!length(cyberpunk_storyteller_curve))
		cyberpunk_storyteller_curve = cyberpunk_storyteller_build_curve()

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_profile(id, name, event_weight, dynamic_light_weight, dynamic_heavy_weight, recovery_weight, gap_multiplier, max_chaos, combat_weight, economy_weight, network_weight, corporate_weight, escalation_speed)
	return list(
		"id" = id,
		"name" = name,
		"event_weight" = event_weight,
		"dynamic_light_weight" = dynamic_light_weight,
		"dynamic_heavy_weight" = dynamic_heavy_weight,
		"recovery_weight" = recovery_weight,
		"gap_multiplier" = gap_multiplier,
		"max_chaos" = max_chaos,
		"combat_weight" = combat_weight,
		"economy_weight" = economy_weight,
		"network_weight" = network_weight,
		"corporate_weight" = corporate_weight,
		"escalation_speed" = escalation_speed,
	)

/*
 * CP13 storyteller package contract.
 *
 * The storyteller core does not hardcode event content. It builds candidate hooks from packages, scores them against
 * current city metrics, then executes one through cyberpunk_storyteller_execute_candidate().
 * This block is the coder guide for adding new round events before a richer CP13-native event datum layer exists.
 *
 * Shared package fields:
 * - id: stable cooldown/memory key.
 * - name: readable UI/history name.
 * - kind: "event" for SSevents, "dynamic" for SSdynamic midround rulesets.
 * - source: backend label for UI/debugging.
 * - weight: base package weight before profile, memory, phase, and pressure multipliers.
 * - tags: story themes used by profiles and arc selection. Common tags: city, recovery, economy, contracts,
 *   corporate, network, security, escalation.
 * - chaos: projected pressure delta. Recovery packages may be negative.
 * - min_time/max_time: elapsed round time gates.
 * - scale: target scope, such as city, district, network, external, or local.
 * - duration: instant, temporary, or long. This is metadata for UI/history and later CP13 event executors.
 * - cooldown: package-specific cooldown after successful execution.
 * - conditions: optional list of /datum/cyberpunk_story_event_condition paths. The package is hidden until all pass.
 *
 * How to add a temporary SSevents-backed package:
 * 1. Make sure an old TG /datum/round_event_control exists in SSevents.events_by_name.
 * 2. Add build_cyberpunk_storyteller_event_package() to ensure_cyberpunk_storyteller_config().
 * 3. Pick tags that describe why the event exists: city, recovery, economy, contracts, corporate, network, security,
 *    escalation.
 * 4. Set chaos to projected pressure delta. Negative chaos means recovery/stabilization.
 * 5. Use min_time/max_time/cooldown/conditions to avoid event-specific switch logic in the storyteller core.
 *
 * How to add a temporary SSdynamic-backed package:
 * 1. Make sure ruleset_path is a /datum/dynamic_ruleset/midround subtype.
 * 2. Add build_cyberpunk_storyteller_dynamic_package() to ensure_cyberpunk_storyteller_config().
 * 3. executor must be "dynamic_light" or "dynamic_heavy"; this is also used by round-plan pressure.
 * 4. The package will be rejected if a temporary ruleset cannot pass can_be_selected().
 *
 * What makes the storyteller check packages:
 * - cyberpunk_round_stage must be past start/preparation.
 * - cyberpunk_storyteller_auto_execute controls whether selected candidates are actually fired.
 * - cyberpunk_storyteller_random_events_enabled gates SSevents packages.
 * - cyberpunk_storyteller_dynamic_rules_enabled gates SSdynamic packages.
 * - cyberpunk_storyteller_event_request_pressure can be raised by admins/debug bridges and adds event candidates.
 * - cyberpunk_storyteller_dynamic_request_pressure can be raised by admins/debug bridges and adds ruleset candidates.
 * - cyberpunk_round_expected_chaos, cyberpunk_round_chaos, cyberpunk_round_chaos_tolerance, and the active profile
 *   decide whether a package is too hot for the current round curve.
 * - cyberpunk_round_recent_event_types and package cooldown prevent repeated package/type spam.
 * - cyberpunk_storyteller_topic_memory, faction_memory, and district_memory reduce repeated themes/factions/districts.
 *
 * Snapshot values currently intended for package conditions and scoring:
 * - population: living_players, dead_players, critical_players, open_critical_roles.
 * - antagonist pressure: active_antags, living_antags, antag_objective_progress, antag_total_funds,
 *   antag_average_health, antag_group_count, antag_group_pressure, antag_groups.
 * - contracts/economy: accepted_contracts, completed_contracts, failed_contracts, illegal_contracts, businesses,
 *   business_tax_debt, business_warehouse_stock, corporation_count, corporation_funds, corporation_influence.
 * - districts/infrastructure: districts, dangerous_districts, district_violence, district_critical_events,
 *   broken_machines, unpowered_machines, apc_offline, powernet_deficit.
 * - network: cyber_nodes, cyber_nodes_breached, cyber_nodes_weak, cyber_net_data.
 *
 * Recommended CP13-native event path later:
 * - Add a dedicated /datum/cyberpunk_story_event subtype with validate(), start(), tick(), complete(), fail().
 * - Store target district/faction/scale/duration on that datum.
 * - Keep build_cyberpunk_storyteller_candidate(), package fields, and condition datums unchanged.
 * - Replace only the backend-specific branch inside cyberpunk_storyteller_execute_candidate().
 *
 * Event packages:
 * - event_name must match SSevents.events_by_name.
 * - availability is checked by cyberpunk_storyteller_package_available().
 * - execution calls SSevents.TriggerEvent().
 *
 * Dynamic packages:
 * - ruleset_path must be a /datum/dynamic_ruleset/midround subtype.
 * - executor is "dynamic_light" or "dynamic_heavy" and drives round-plan preference.
 * - availability creates a temporary ruleset and calls can_be_selected().
 * - execution calls SSdynamic.force_run_midround().
 *
 * CP13-native events should use the same candidate fields first, then replace the backend-specific execution branch
 * with a dedicated datum executor instead of adding switch(contract-type)-style logic into the scorer.
 */
/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_event_package(id, name, event_name, weight, list/tags, chaos = 5, min_time = 0, max_time = null, scale = "city", duration = "instant", cooldown = 10 MINUTES, list/conditions = null)
	return list(
		"id" = id,
		"name" = name,
		"kind" = "event",
		"source" = "SSevents",
		"event_name" = event_name,
		"weight" = weight,
		"tags" = tags || list(),
		"chaos" = chaos,
		"min_time" = min_time,
		"max_time" = max_time,
		"scale" = scale,
		"duration" = duration,
		"cooldown" = cooldown,
		"conditions" = conditions || list(),
	)

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_dynamic_package(id, name, ruleset_path, executor, weight, list/tags, chaos = 15, min_time = 15 MINUTES, max_time = null, scale = "external", duration = "temporary", cooldown = 20 MINUTES, list/conditions = null)
	return list(
		"id" = id,
		"name" = name,
		"kind" = "dynamic",
		"source" = "SSdynamic",
		"ruleset_path" = ruleset_path,
		"executor" = executor,
		"weight" = weight,
		"tags" = tags || list(),
		"chaos" = chaos,
		"min_time" = min_time,
		"max_time" = max_time,
		"scale" = scale,
		"duration" = duration,
		"cooldown" = cooldown,
		"conditions" = conditions || list(),
	)

/datum/cyberpunk_story_event_condition
	/// Stable condition id for UI/debug output.
	var/id = "condition"
	/// Human-readable coder-facing description.
	var/description = "Generic storyteller condition."
	/// Failure text used in debug/status data.
	var/failure_reason = "condition failed"
	/// Optional threshold. Subtypes decide what it means.
	var/required_value = 0

/datum/cyberpunk_story_event_condition/proc/is_met(list/snapshot, list/candidate, list/package)
	return TRUE

/datum/cyberpunk_story_event_condition/proc/describe()
	return description

/datum/cyberpunk_story_event_condition/proc/fail_reason()
	return failure_reason

/datum/cyberpunk_story_event_condition/min_living_players
	id = "min_living_players"
	description = "Requires at least one living player."
	failure_reason = "not enough living players"
	required_value = 1

/datum/cyberpunk_story_event_condition/min_living_players/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["living_players"] || 0) >= required_value

/datum/cyberpunk_story_event_condition/min_chaos
	id = "min_chaos"
	description = "Requires elevated city pressure."
	failure_reason = "city pressure is too low"
	required_value = 20

/datum/cyberpunk_story_event_condition/min_chaos/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["chaos"] || SScyberpunk_round?.cyberpunk_round_chaos || 0) >= required_value

/datum/cyberpunk_story_event_condition/max_chaos
	id = "max_chaos"
	description = "Requires city pressure below a ceiling."
	failure_reason = "city pressure is too high"
	required_value = 80

/datum/cyberpunk_story_event_condition/max_chaos/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["chaos"] || SScyberpunk_round?.cyberpunk_round_chaos || 0) <= required_value

/datum/cyberpunk_story_event_condition/corporate_field
	id = "corporate_field"
	description = "Requires enough active corporations."
	failure_reason = "not enough corporations"
	required_value = 3

/datum/cyberpunk_story_event_condition/corporate_field/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["corporation_count"] || 0) >= required_value

/datum/cyberpunk_story_event_condition/network_field
	id = "network_field"
	description = "Requires at least one cyber network node."
	failure_reason = "no cyber network nodes found"
	required_value = 1

/datum/cyberpunk_story_event_condition/network_field/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["cyber_nodes"] || 0) >= required_value

/datum/cyberpunk_story_event_condition/dangerous_district
	id = "dangerous_district"
	description = "Requires at least one dangerous district."
	failure_reason = "no dangerous district pressure"
	required_value = 1

/datum/cyberpunk_story_event_condition/dangerous_district/is_met(list/snapshot, list/candidate, list/package)
	return (snapshot?["dangerous_districts"] || 0) >= required_value

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_build_curve()
	var/list/profile = cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile] || cyberpunk_storyteller_profile_options["balanced"]
	var/escalation_speed = profile ? (profile["escalation_speed"] || 1) : 1
	var/max_chaos = profile ? (profile["max_chaos"] || 85) : 85
	return list(
		build_cyberpunk_storyteller_curve_point(0, 5, 8, FALSE),
		build_cyberpunk_storyteller_curve_point(cyberpunk_round_main_flow_delay, 12, 10, FALSE),
		build_cyberpunk_storyteller_curve_point(60 MINUTES, round(26 * escalation_speed), 12, FALSE),
		build_cyberpunk_storyteller_curve_point(120 MINUTES, round(42 * escalation_speed), 14, FALSE),
		build_cyberpunk_storyteller_curve_point((cyberpunk_round_escalation_day - 1) * cyberpunk_round_real_day, min(round(58 * escalation_speed), max_chaos), 16, TRUE),
		build_cyberpunk_storyteller_curve_point(cyberpunk_round_real_duration, min(max_chaos, 75), 18, TRUE),
	)

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_curve_point(time, expected_chaos, tolerance, force_chaos)
	return list(
		"time" = time,
		"expected_chaos" = clamp(expected_chaos, 0, 100),
		"tolerance" = tolerance,
		"force_chaos" = force_chaos,
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_rebuild_round_plan()
	ensure_cyberpunk_storyteller_config()
	cyberpunk_storyteller_round_plan = list()
	for(var/list/point as anything in cyberpunk_storyteller_curve)
		var/plan_executor = "event"
		var/expected = point["expected_chaos"] || 0
		if(expected >= 60)
			plan_executor = "dynamic_heavy"
		else if(expected >= 35)
			plan_executor = "dynamic_light"
		cyberpunk_storyteller_round_plan += list(list(
			"time" = point["time"],
			"expected_chaos" = expected,
			"tolerance" = point["tolerance"],
			"force_chaos" = point["force_chaos"],
			"preferred_executor" = plan_executor,
		))

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_elapsed()
	if(!cyberpunk_round_started_at)
		return 0
	return max(world.time - cyberpunk_round_started_at, 0)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_send_start_report()
	if(cyberpunk_round_start_report_announced || !SSticker?.IsRoundInProgress())
		return
	cyberpunk_round_start_report_announced = TRUE
	load_cyberpunk_round_previous_summary()
	var/list/snapshot = cyberpunk_round_last_snapshot
	if(!length(snapshot))
		snapshot = build_cyberpunk_round_snapshot(FALSE)
	var/report = cyberpunk_round_build_start_report(snapshot)
	priority_announce(report, "Bright City Morning Report", SSstation.announcer.get_rand_report_sound(), sender_override = "Starlight City Network")
	record_cyberpunk_round_event("start_report", "city_report", "city", cyberpunk_round_chaos, report, "completed")

/datum/controller/subsystem/cyberpunk_round/proc/load_cyberpunk_round_previous_summary()
	if(cyberpunk_round_previous_summary_loaded)
		return cyberpunk_round_previous_summary
	cyberpunk_round_previous_summary_loaded = TRUE
	var/summary_path = "data/cyberpunk_round_summary.json"
	if(!fexists(summary_path))
		cyberpunk_round_previous_summary = list()
		return cyberpunk_round_previous_summary
	var/raw_summary = file2text(summary_path)
	if(!length(raw_summary))
		cyberpunk_round_previous_summary = list()
		return cyberpunk_round_previous_summary
	var/list/decoded_summary = json_decode(raw_summary)
	cyberpunk_round_previous_summary = islist(decoded_summary) ? decoded_summary : list()
	return cyberpunk_round_previous_summary

/datum/controller/subsystem/cyberpunk_round/proc/save_cyberpunk_round_summary(list/summary)
	if(!length(summary))
		return FALSE
	var/list/file_data = list(
		"version" = 1,
		"saved_at" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"summary" = summary,
		"history" = cyberpunk_round_event_history.Copy(),
	)
	var/json_file = file("data/cyberpunk_round_summary.json")
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data, JSON_PRETTY_PRINT))
	return TRUE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_previous_news_line()
	var/list/file_data = load_cyberpunk_round_previous_summary()
	var/list/summary = islist(file_data) ? file_data["summary"] : null
	if(!length(summary))
		return ""
	return " Вчерашний городской индекс завершился на [summary["chaos"] || 0] при плане [summary["expected_chaos"] || 0]; погибших [summary["dead_players"] || 0], активных антагонистических групп [summary["antag_group_count"] || 0], закрытых контрактов [summary["completed_contracts"] || 0]."

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_russian_cop_word(amount)
	amount = abs(round(amount))
	var/last_two = amount % 100
	if(last_two >= 11 && last_two <= 14)
		return "копов"
	switch(amount % 10)
		if(1)
			return "коп"
		if(2 to 4)
			return "копа"
	return "копов"

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_report_place(list/snapshot, fallback = "городская подстанция")
	var/list/districts = islist(snapshot) ? snapshot["districts"] : null
	if(!length(districts))
		return fallback
	var/list/selected = pick(districts)
	return selected?["name"] || fallback

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_build_start_report(list/snapshot)
	var/dead = snapshot["dead_players"] || 0
	var/dead_security = snapshot["dead_security_players"] || 0
	var/hacked_place = cyberpunk_round_report_place(snapshot, "городская подстанция")
	var/cyberpsycho_place = cyberpunk_round_report_place(snapshot, "старый жилой сектор")
	var/base_report = "Доброе утро, Брайт-Сити! Вчерашний подсчет трупов закончился на крепкой [dead]очке. Спонсоры десятки - неутихающие войны банд по всем районам и очередные благородные решения наших корпораций. Минус [dead_security] [cyberpunk_round_russian_cop_word(dead_security)], так что все готовтесь - правительство по этому поводу ни сделает нихрена. А вот [hacked_place] вчера отрубило свет. Очевидно Нетраннеры решили порезвится в сети. В [cyberpsycho_place] Бэнь отскребает от асльфата очередную жертву киберпсиха. И как обычно, в пустошах без перемен. С вами была ваша любимая Старлайт и я, ведущая Кершни. Добро пожаловать в новый день в городе мечты."
	return "[base_report][cyberpunk_round_previous_news_line()]"

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_build_summary(list/snapshot, reason = "status")
	if(!snapshot || !length(snapshot))
		snapshot = build_cyberpunk_round_snapshot()
	var/list/summary = list(
		"reason" = reason,
		"clock" = cyberpunk_round_clock_text(),
		"elapsed" = cyberpunk_round_elapsed(),
		"day" = cyberpunk_round_day,
		"stage" = cyberpunk_round_stage,
		"chaos" = cyberpunk_round_chaos,
		"expected_chaos" = cyberpunk_round_expected_chaos,
		"living_players" = snapshot["living_players"] || 0,
		"dead_players" = snapshot["dead_players"] || 0,
		"critical_players" = snapshot["critical_players"] || 0,
		"active_antags" = snapshot["active_antags"] || 0,
		"living_antags" = snapshot["living_antags"] || 0,
		"dead_antags" = snapshot["dead_antags"] || 0,
		"antag_objective_progress" = snapshot["antag_objective_progress"] || 0,
		"antag_total_funds" = snapshot["antag_total_funds"] || 0,
		"antag_average_health" = snapshot["antag_average_health"] || 0,
		"antag_group_count" = snapshot["antag_group_count"] || 0,
		"antag_group_pressure" = snapshot["antag_group_pressure"] || 0,
		"antag_faction_resource_pressure" = snapshot["antag_faction_resource_pressure"] || 0,
		"completed_contracts" = snapshot["completed_contracts"] || 0,
		"failed_contracts" = snapshot["failed_contracts"] || 0,
		"businesses" = snapshot["businesses"] || 0,
		"business_tax_debt" = snapshot["business_tax_debt"] || 0,
		"corporation_count" = snapshot["corporation_count"] || 0,
		"history_size" = length(cyberpunk_round_event_history),
	)
	cyberpunk_round_last_summary = summary
	return summary

/datum/controller/subsystem/cyberpunk_round/proc/record_cyberpunk_round_summary(reason = "status", list/snapshot = null)
	if(cyberpunk_round_summary_recorded && reason != "status")
		return cyberpunk_round_last_summary
	var/list/summary = cyberpunk_round_build_summary(snapshot, reason)
	if(!length(summary))
		return summary
	if(reason != "status")
		cyberpunk_round_summary_recorded = TRUE
	SSblackbox?.record_feedback("associative", "cyberpunk_round_summary", 1, summary)
	if(reason != "status")
		save_cyberpunk_round_summary(summary)
		record_cyberpunk_round_event("round_summary", "endround", "city", cyberpunk_round_chaos, "Round summary recorded: [reason].", "completed")
	return summary

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_process_endround()
	if(!SSticker || !SSticker.IsRoundInProgress())
		return
	var/list/snapshot = cyberpunk_round_last_snapshot
	if(!length(snapshot))
		snapshot = build_cyberpunk_round_snapshot()
	cyberpunk_round_consider_catastrophic_evac(snapshot)
	if(cyberpunk_round_elapsed() < cyberpunk_round_real_duration)
		return
	if(cyberpunk_round_end_state == "active")
		cyberpunk_round_start_completion_vote(snapshot)
		return
	if(cyberpunk_round_end_state == "vote")
		cyberpunk_round_resolve_completion_vote(snapshot)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_start_completion_vote(list/snapshot)
	if(cyberpunk_round_extensions_used >= cyberpunk_round_max_extensions)
		cyberpunk_round_end_state = "ending"
		SSticker.force_ending = FORCE_END_ROUND
		record_cyberpunk_round_summary("base_duration_complete", snapshot)
		record_cyberpunk_round_event("round_completion", "endround", "city", cyberpunk_round_chaos, "Base round duration expired; no extensions remain.", "completed")
		return
	cyberpunk_round_end_state = "vote"
	cyberpunk_round_end_vote_started_at = world.time
	cyberpunk_round_build_summary(snapshot, "completion_vote")
	if(SSvote)
		INVOKE_ASYNC(SSvote, TYPE_PROC_REF(/datum/controller/subsystem/vote, initiate_vote), /datum/vote/restart_vote, "City Clock", null, TRUE)
		record_cyberpunk_round_event("completion_vote", "endround", "city", cyberpunk_round_chaos, "Base round duration expired; restart/continue vote started.", "deferred")
	else
		record_cyberpunk_round_event("completion_vote_unavailable", "endround", "city", cyberpunk_round_chaos, "Base round duration expired; vote subsystem unavailable, extending by policy.", "blocked")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_resolve_completion_vote(list/snapshot)
	if(SSticker.force_ending)
		cyberpunk_round_end_state = "ending"
		record_cyberpunk_round_summary("vote_restart", snapshot)
		record_cyberpunk_round_event("completion_vote_restart", "endround", "city", cyberpunk_round_chaos, "Restart/end vote passed; ticker is ending the round.", "completed")
		return
	var/vote_window = CONFIG_GET(number/vote_period) + 5 SECONDS
	if(world.time < cyberpunk_round_end_vote_started_at + vote_window)
		return
	cyberpunk_round_extensions_used++
	cyberpunk_round_real_duration += cyberpunk_round_extension_days * cyberpunk_round_real_day
	cyberpunk_round_end_state = "active"
	cyberpunk_round_build_summary(snapshot, "vote_continue")
	record_cyberpunk_round_event("round_extended", "endround", "city", cyberpunk_round_chaos, "Continue vote accepted or no restart force was produced; round extended by [cyberpunk_round_extension_days] city days.", "completed")
	priority_announce("City clock extension accepted. Round operations continue for [cyberpunk_round_extension_days] additional city days.", "City Clock", SSstation.announcer.get_rand_report_sound(), sender_override = "Starlight City Network")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_consider_catastrophic_evac(list/snapshot)
	if(cyberpunk_round_catastrophic_evac_requested || cyberpunk_round_elapsed() < cyberpunk_round_main_flow_delay)
		return
	if(cyberpunk_round_chaos < 98)
		return
	var/living_players = snapshot["living_players"] || 0
	var/dead_players = snapshot["dead_players"] || 0
	if(living_players > 0 && dead_players < max(round((living_players + dead_players) * 0.5), 3))
		return
	if(!SSshuttle || !SSshuttle.emergency)
		return
	var/can_evac = SSshuttle.canEvac()
	if(can_evac != TRUE)
		return
	cyberpunk_round_catastrophic_evac_requested = TRUE
	cyberpunk_round_end_state = "evacuation"
	record_cyberpunk_round_summary("catastrophic_evac", snapshot)
	SSshuttle.call_evac_shuttle("City systems report catastrophic failure: pressure has exceeded survivable limits.", null)
	record_cyberpunk_round_event("catastrophic_evac", "endround", "city", cyberpunk_round_chaos, "Catastrophic city pressure requested evacuation shuttle.", "executed")

/datum/controller/subsystem/cyberpunk_round/proc/update_cyberpunk_round_clock()
	ensure_cyberpunk_storyteller_config()
	var/elapsed = cyberpunk_round_elapsed()
	var/day_index = FLOOR(elapsed / max(cyberpunk_round_real_day, 1), 1)
	cyberpunk_round_day = max(day_index + 1, 1)
	var/day_elapsed = elapsed % max(cyberpunk_round_real_day, 1)
	cyberpunk_round_ingame_minutes = FLOOR((day_elapsed * 1440) / max(cyberpunk_round_real_day, 1), 1)
	var/hour = FLOOR(cyberpunk_round_ingame_minutes / 60, 1)
	if(hour < 6)
		cyberpunk_round_phase = "night"
		cyberpunk_round_phase_name = "Night"
	else if(hour < 12)
		cyberpunk_round_phase = "morning"
		cyberpunk_round_phase_name = "Morning"
	else if(hour < 18)
		cyberpunk_round_phase = "day"
		cyberpunk_round_phase_name = "Day"
	else
		cyberpunk_round_phase = "evening"
		cyberpunk_round_phase_name = "Evening"
	if(elapsed < cyberpunk_round_main_flow_delay)
		cyberpunk_round_stage = "start"
	else if(elapsed >= cyberpunk_round_real_duration)
		cyberpunk_round_stage = "finish"
	else if(cyberpunk_round_day >= cyberpunk_round_escalation_day)
		cyberpunk_round_stage = "escalation"
	else
		cyberpunk_round_stage = "main"
	var/list/curve_point = cyberpunk_storyteller_curve_state(elapsed)
	cyberpunk_round_expected_chaos = curve_point["expected_chaos"]
	cyberpunk_round_chaos_tolerance = curve_point["tolerance"]

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_curve_state(elapsed)
	ensure_cyberpunk_storyteller_config()
	if(!length(cyberpunk_storyteller_curve))
		return build_cyberpunk_storyteller_curve_point(elapsed, 0, 10, FALSE)
	var/list/previous_point = cyberpunk_storyteller_curve[1]
	for(var/list/point as anything in cyberpunk_storyteller_curve)
		if((point["time"] || 0) > elapsed)
			var/previous_time = previous_point["time"] || 0
			var/current_time = point["time"] || previous_time
			var/segment_progress = current_time > previous_time ? clamp((elapsed - previous_time) / (current_time - previous_time), 0, 1) : 0
			return build_cyberpunk_storyteller_curve_point(
				elapsed,
				round((previous_point["expected_chaos"] || 0) + (((point["expected_chaos"] || 0) - (previous_point["expected_chaos"] || 0)) * segment_progress)),
				round((previous_point["tolerance"] || 10) + (((point["tolerance"] || 10) - (previous_point["tolerance"] || 10)) * segment_progress)),
				(previous_point["force_chaos"] || point["force_chaos"]),
			)
		previous_point = point
	return previous_point

/datum/controller/subsystem/cyberpunk_round/proc/update_cyberpunk_daylight()
	if(!cyberpunk_daylight_enabled)
		clear_cyberpunk_daylight()
		return
	var/daylight_bucket = FLOOR(cyberpunk_round_ingame_minutes / 15, 1)
	if(cyberpunk_daylight_last_phase == cyberpunk_round_phase && cyberpunk_daylight_last_bucket == daylight_bucket && length(cyberpunk_daylight_sources))
		return
	ensure_cyberpunk_daylight_sources()
	apply_cyberpunk_daylight()
	cyberpunk_daylight_last_phase = cyberpunk_round_phase
	cyberpunk_daylight_last_bucket = daylight_bucket

/datum/controller/subsystem/cyberpunk_round/proc/ensure_cyberpunk_daylight_sources()
	if(length(cyberpunk_daylight_sources))
		return
	var/stride = max(cyberpunk_daylight_stride, 1)
	for(var/turf/source_turf as anything in world)
		CHECK_TICK
		if(!isopenturf(source_turf))
			continue
		if(is_space_or_openspace(source_turf))
			continue
		if((source_turf.x % stride) || (source_turf.y % stride))
			continue
		if(!cyberpunk_turf_has_open_sky(source_turf))
			continue
		var/key = "[source_turf.x],[source_turf.y],[source_turf.z]"
		cyberpunk_daylight_sources[key] = new /obj/effect/cyberpunk_daylight_source(source_turf)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_turf_has_open_sky(turf/source_turf)
	if(!source_turf)
		return FALSE
	var/turf/check_turf = source_turf
	for(var/step in 1 to 64)
		var/turf/above = GET_TURF_ABOVE(check_turf)
		if(!above)
			return TRUE
		if(!is_space_or_openspace(above))
			return FALSE
		check_turf = above
	return TRUE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_daylight_anchor_for_minute(target_minute)
	if(target_minute < 360)
		return list("minute" = 0, "phase" = "night")
	if(target_minute < 720)
		return list("minute" = 360, "phase" = "morning")
	if(target_minute < 1080)
		return list("minute" = 720, "phase" = "day")
	return list("minute" = 1080, "phase" = "evening")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_daylight_next_anchor_for_minute(target_minute)
	if(target_minute < 360)
		return list("minute" = 360, "phase" = "morning")
	if(target_minute < 720)
		return list("minute" = 720, "phase" = "day")
	if(target_minute < 1080)
		return list("minute" = 1080, "phase" = "evening")
	return list("minute" = 1440, "phase" = "night")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_daylight_value_for_phase(phase_id, list/source_values)
	return source_values[phase_id] || source_values["day"] || 0

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_daylight_current_values()
	var/list/current_anchor = cyberpunk_daylight_anchor_for_minute(cyberpunk_round_ingame_minutes)
	var/list/next_anchor = cyberpunk_daylight_next_anchor_for_minute(cyberpunk_round_ingame_minutes)
	var/current_minute = current_anchor["minute"] || 0
	var/next_minute = next_anchor["minute"] || current_minute
	var/progress = next_minute > current_minute ? clamp((cyberpunk_round_ingame_minutes - current_minute) / (next_minute - current_minute), 0, 1) : 0
	var/current_phase = current_anchor["phase"]
	var/next_phase = next_anchor["phase"]
	var/current_power = cyberpunk_daylight_value_for_phase(current_phase, cyberpunk_daylight_power_by_phase)
	var/next_power = cyberpunk_daylight_value_for_phase(next_phase, cyberpunk_daylight_power_by_phase)
	var/current_range = cyberpunk_daylight_value_for_phase(current_phase, cyberpunk_daylight_range_by_phase)
	var/next_range = cyberpunk_daylight_value_for_phase(next_phase, cyberpunk_daylight_range_by_phase)
	var/current_color = cyberpunk_daylight_color_by_phase[current_phase] || "#ffffff"
	var/next_color = cyberpunk_daylight_color_by_phase[next_phase] || current_color
	return list(
		"power" = round(LERP(current_power, next_power, progress), 0.01),
		"range" = round(LERP(current_range, next_range, progress), 0.1),
		"color" = BlendRGB(current_color, next_color, progress),
	)

/datum/controller/subsystem/cyberpunk_round/proc/apply_cyberpunk_daylight()
	var/list/daylight_values = cyberpunk_daylight_current_values()
	var/light_range = daylight_values["range"] || 0
	var/light_power = daylight_values["power"] || 0
	var/light_color = daylight_values["color"] || "#ffffff"
	cyberpunk_daylight_current_range = light_range
	cyberpunk_daylight_current_power = light_power
	cyberpunk_daylight_current_color = light_color
	var/list/deleted_sources = list()
	for(var/source_key in cyberpunk_daylight_sources)
		CHECK_TICK
		var/obj/effect/cyberpunk_daylight_source/daylight_source = cyberpunk_daylight_sources[source_key]
		if(QDELETED(daylight_source))
			deleted_sources += source_key
			continue
		daylight_source.set_light(light_range, light_power, light_color)
	for(var/source_key in deleted_sources)
		cyberpunk_daylight_sources -= source_key

/datum/controller/subsystem/cyberpunk_round/proc/clear_cyberpunk_daylight()
	for(var/source_key in cyberpunk_daylight_sources)
		CHECK_TICK
		var/obj/effect/cyberpunk_daylight_source/daylight_source = cyberpunk_daylight_sources[source_key]
		qdel(daylight_source)
	cyberpunk_daylight_sources = list()
	cyberpunk_daylight_last_phase = null
	cyberpunk_daylight_last_bucket = -1
	cyberpunk_daylight_current_power = 0
	cyberpunk_daylight_current_range = 0

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_clock_text()
	var/hour = FLOOR(cyberpunk_round_ingame_minutes / 60, 1)
	var/minute = cyberpunk_round_ingame_minutes % 60
	var/hour_text = hour < 10 ? "0[hour]" : "[hour]"
	var/minute_text = minute < 10 ? "0[minute]" : "[minute]"
	return "Day [cyberpunk_round_day], [hour_text]:[minute_text] ([cyberpunk_round_phase_name])"

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_round_snapshot(include_infrastructure = TRUE)
	update_cyberpunk_round_clock()
	var/player_count = 0
	var/living_players = 0
	var/dead_players = 0
	var/dead_security_players = 0
	var/critical_players = 0
	var/total_player_damage = 0
	var/security_players = 0
	var/command_players = 0
	var/medical_players = 0
	var/engineering_players = 0
	var/specialist_players = 0
	for(var/client/player_client as anything in GLOB.clients)
		var/mob/living/living_player = player_client.mob
		if(!istype(living_player))
			continue
		player_count++
		if(living_player.stat == DEAD)
			dead_players++
		else
			living_players++
		if(living_player.stat == SOFT_CRIT || living_player.stat == HARD_CRIT)
			critical_players++
		total_player_damage += max((living_player.maxHealth || 100) - living_player.health, 0)
		var/datum/job/player_job = living_player.mind?.assigned_role
		if(player_job)
			if(player_job.departments_bitflags & DEPARTMENT_BITFLAG_SECURITY)
				security_players++
				if(living_player.stat == DEAD)
					dead_security_players++
			if(player_job.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND)
				command_players++
			if(player_job.departments_bitflags & DEPARTMENT_BITFLAG_MEDICAL)
				medical_players++
			if(player_job.departments_bitflags & DEPARTMENT_BITFLAG_ENGINEERING)
				engineering_players++
			if(!(player_job.departments_bitflags & (DEPARTMENT_BITFLAG_SECURITY|DEPARTMENT_BITFLAG_COMMAND|DEPARTMENT_BITFLAG_MEDICAL|DEPARTMENT_BITFLAG_ENGINEERING)))
				specialist_players++

	var/open_critical_roles = 0
	var/open_security_roles = 0
	var/open_medical_roles = 0
	var/open_engineering_roles = 0
	var/list/role_distribution = list()
	if(SSjob)
		for(var/datum/job/job as anything in SSjob.joinable_occupations)
			var/open_positions = max((job.total_positions || 0) - (job.current_positions || 0), 0)
			if(job.total_positions > 0)
				role_distribution += list(list(
					"name" = job.title,
					"current" = job.current_positions,
					"total" = job.total_positions,
					"open" = open_positions,
					"department_flags" = job.departments_bitflags,
				))
			if(!(job.departments_bitflags & (DEPARTMENT_BITFLAG_COMMAND|DEPARTMENT_BITFLAG_SECURITY|DEPARTMENT_BITFLAG_MEDICAL|DEPARTMENT_BITFLAG_ENGINEERING)))
				continue
			open_critical_roles += open_positions
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_SECURITY)
				open_security_roles += open_positions
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_MEDICAL)
				open_medical_roles += open_positions
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_ENGINEERING)
				open_engineering_roles += open_positions

	var/active_antags = 0
	var/living_antags = 0
	var/dead_antags = 0
	var/antag_objectives_total = 0
	var/antag_objectives_completed = 0
	var/antag_total_funds = 0
	var/antag_total_health_percent = 0
	var/antag_health_records = 0
	var/antag_faction_resource_pressure = 0
	var/list/antag_records = list()
	var/list/antag_group_records_by_id = list()
	for(var/datum/antagonist/antag as anything in GLOB.antagonists)
		if(!antag.owner)
			continue
		active_antags++
		var/mob/living/antag_body = antag.owner.current
		var/antag_alive = istype(antag_body) && antag_body.stat != DEAD
		var/antag_health_percent = 0
		var/antag_funds = 0
		if(antag_alive)
			living_antags++
			antag_health_percent = antag_body.maxHealth ? clamp(round((antag_body.health / antag_body.maxHealth) * 100), 0, 100) : 0
			antag_total_health_percent += antag_health_percent
			antag_health_records++
			var/datum/bank_account/antag_account = antag_body.get_bank_account()
			antag_funds = antag_account ? antag_account.account_balance : 0
			antag_total_funds += antag_funds
		else
			dead_antags++
		var/objectives_total = length(antag.objectives)
		var/objectives_completed = 0
		for(var/datum/objective/objective as anything in antag.objectives)
			if(objective?.check_completion())
				objectives_completed++
		antag_objectives_total += objectives_total
		antag_objectives_completed += objectives_completed
		var/datum/team/antag_team = antag.get_team()
		var/group_id = antag_team ? "team_[REF(antag_team)]" : "category_[antag.roundend_category || antag.name || antag.type]"
		var/list/group_record = antag_group_records_by_id[group_id]
		if(!group_record)
			group_record = list(
				"id" = group_id,
				"name" = antag_team ? antag_team.name : (antag.roundend_category || antag.name || "[antag.type]"),
				"category" = antag.roundend_category || antag.name,
				"team" = !isnull(antag_team),
				"members" = 0,
				"living" = 0,
				"dead" = 0,
				"funds" = 0,
				"objectives_total" = 0,
				"objectives_completed" = 0,
				"health_total" = 0,
				"health_records" = 0,
				"faction_resources" = list(),
				"faction_resource_total" = 0,
			)
			var/datum/cyberpunk_faction_resources/faction_resources = antag.get_cyberpunk_faction_resources()
			if(faction_resources)
				var/list/resource_snapshot = faction_resources.to_snapshot()
				group_record["faction_resources"] = resource_snapshot
				group_record["faction_resource_total"] = resource_snapshot["total"] || 0
			antag_group_records_by_id[group_id] = group_record
		group_record["members"]++
		if(antag_alive)
			group_record["living"]++
			group_record["health_total"] += antag_health_percent
			group_record["health_records"]++
		else
			group_record["dead"]++
		group_record["funds"] += antag_funds
		group_record["objectives_total"] += objectives_total
		group_record["objectives_completed"] += objectives_completed
		antag_records += list(list(
			"name" = antag.name,
			"category" = antag.roundend_category,
			"alive" = antag_alive,
			"health_percent" = antag_health_percent,
			"funds" = antag_funds,
			"objective_count" = objectives_total,
			"objectives_completed" = objectives_completed,
			"objective_progress" = objectives_total ? round((objectives_completed / objectives_total) * 100) : 0,
		))
	var/antag_objective_progress = antag_objectives_total ? round((antag_objectives_completed / antag_objectives_total) * 100) : 0
	var/antag_average_health = antag_health_records ? round(antag_total_health_percent / antag_health_records) : 0
	var/list/antag_group_records = list()
	var/antag_group_pressure = 0
	for(var/group_id in antag_group_records_by_id)
		var/list/group_record = antag_group_records_by_id[group_id]
		var/group_objectives_total = group_record["objectives_total"] || 0
		var/group_health_records = group_record["health_records"] || 0
		var/group_living = group_record["living"] || 0
		var/group_funds = group_record["funds"] || 0
		var/group_progress = group_objectives_total ? round(((group_record["objectives_completed"] || 0) / group_objectives_total) * 100) : 0
		var/group_average_health = group_health_records ? round((group_record["health_total"] || 0) / group_health_records) : 0
		var/group_threat = (group_living * 8) + min(round(group_funds / 750), 20) + min(round(group_progress / 5), 20)
		group_threat += min(round((group_record["faction_resource_total"] || 0) / 25), 20)
		if(group_living && group_average_health <= 25)
			group_threat = max(group_threat - 5, 0)
		group_record["objective_progress"] = group_progress
		group_record["average_health"] = group_average_health
		group_record["threat"] = group_threat
		antag_group_pressure += group_threat
		antag_faction_resource_pressure += group_record["faction_resource_total"] || 0
		antag_group_records += list(group_record)

	var/created_contracts = 0
	var/offered_contracts = 0
	var/accepted_contracts = 0
	var/completed_contracts = 0
	var/failed_contracts = 0
	var/cancelled_contracts = 0
	var/public_contracts = 0
	var/illegal_contracts = 0
	var/list/contracts = SSeconomy?.cyberpunk_contracts || list()
	for(var/contract_id in contracts)
		var/datum/cyberpunk_contract/contract = contracts[contract_id]
		if(!contract)
			continue
		switch(contract.status)
			if("created")
				created_contracts++
			if("offered")
				offered_contracts++
			if("accepted")
				accepted_contracts++
			if("completed")
				completed_contracts++
			if("failed")
				failed_contracts++
			if("cancelled")
				cancelled_contracts++
		if(contract.public_contract)
			public_contracts++
		if(!contract.legal)
			illegal_contracts++

	var/legal_businesses = 0
	var/illegal_businesses = 0
	var/business_tax_debt = 0
	var/business_tax_paid = 0
	var/business_employee_count = 0
	var/business_warehouse_stock = 0
	var/valid_business_premises = 0
	var/list/businesses = SScyberpunk_property?.cyberpunk_businesses || list()
	for(var/business_id in businesses)
		var/datum/cyberpunk_business/business = businesses[business_id]
		if(!business)
			continue
		if(business.legal)
			legal_businesses++
		else
			illegal_businesses++
		business_tax_debt += business.tax_debt
		business_tax_paid += business.tax_paid
		business_employee_count += length(business.employees)
		if(business.premises_valid)
			valid_business_premises++
		for(var/stock_key in business.warehouse_stock)
			business_warehouse_stock += business.warehouse_stock[stock_key]

	var/list/corporation_records = list()
	var/corporation_funds = 0
	var/corporation_influence = 0
	var/list/corporations = SScyberpunk_corporations?.cyberpunk_corporations || list()
	for(var/corporation_id in corporations)
		var/datum/cyberpunk_corporation/corporation = corporations[corporation_id]
		if(!corporation)
			continue
		var/datum/bank_account/corporation_account = corporation.get_account()
		corporation_funds += corporation_account ? corporation_account.account_balance : 0
		corporation_influence += corporation.influence
		corporation_records += list(list(
			"id" = corporation.id,
			"name" = corporation.name,
			"level" = corporation.level,
			"research" = corporation.research_points,
			"influence" = corporation.influence,
			"funds" = corporation_account ? corporation_account.account_balance : 0,
			"active_edicts" = length(corporation.active_edicts),
		))

	var/list/infrastructure = include_infrastructure ? cyberpunk_round_get_infrastructure_metrics() : cyberpunk_round_light_infrastructure_metrics()

	return list(
		"clock" = cyberpunk_round_clock_text(),
		"world_time" = world.time,
		"elapsed" = cyberpunk_round_elapsed(),
		"day" = cyberpunk_round_day,
		"phase" = cyberpunk_round_phase,
		"phase_name" = cyberpunk_round_phase_name,
		"ingame_minutes" = cyberpunk_round_ingame_minutes,
		"stage" = cyberpunk_round_stage,
		"expected_chaos" = cyberpunk_round_expected_chaos,
		"chaos" = cyberpunk_round_chaos,
		"player_count" = player_count,
		"living_players" = living_players,
		"dead_players" = dead_players,
		"dead_security_players" = dead_security_players,
		"critical_players" = critical_players,
		"total_player_damage" = total_player_damage,
		"security_players" = security_players,
		"command_players" = command_players,
		"medical_players" = medical_players,
		"engineering_players" = engineering_players,
		"specialist_players" = specialist_players,
		"open_critical_roles" = open_critical_roles,
		"open_security_roles" = open_security_roles,
		"open_medical_roles" = open_medical_roles,
		"open_engineering_roles" = open_engineering_roles,
		"role_distribution" = role_distribution,
		"active_antags" = active_antags,
		"living_antags" = living_antags,
		"dead_antags" = dead_antags,
		"antag_objectives_total" = antag_objectives_total,
		"antag_objectives_completed" = antag_objectives_completed,
		"antag_objective_progress" = antag_objective_progress,
		"antag_total_funds" = antag_total_funds,
		"antag_average_health" = antag_average_health,
		"antag_group_count" = length(antag_group_records),
		"antag_group_pressure" = antag_group_pressure,
		"antag_faction_resource_pressure" = antag_faction_resource_pressure,
		"antag_groups" = antag_group_records,
		"antags" = antag_records,
		"created_contracts" = created_contracts,
		"offered_contracts" = offered_contracts,
		"accepted_contracts" = accepted_contracts,
		"completed_contracts" = completed_contracts,
		"failed_contracts" = failed_contracts,
		"cancelled_contracts" = cancelled_contracts,
		"public_contracts" = public_contracts,
		"illegal_contracts" = illegal_contracts,
		"businesses" = length(businesses),
		"legal_businesses" = legal_businesses,
		"illegal_businesses" = illegal_businesses,
		"apartments" = length(SScyberpunk_property?.cyberpunk_apartments),
		"business_deliveries" = length(SScyberpunk_property?.cyberpunk_business_deliveries),
		"business_tax_debt" = business_tax_debt,
		"business_tax_paid" = business_tax_paid,
		"business_employee_count" = business_employee_count,
		"business_warehouse_stock" = business_warehouse_stock,
		"valid_business_premises" = valid_business_premises,
		"corporation_count" = length(corporations),
		"corporation_funds" = corporation_funds,
		"corporation_influence" = corporation_influence,
		"corporations" = corporation_records,
		"district_count" = infrastructure["district_count"],
		"districts" = infrastructure["districts"],
		"damaged_districts" = infrastructure["damaged_districts"],
		"dangerous_districts" = infrastructure["dangerous_districts"],
		"district_violence" = infrastructure["district_violence"],
		"district_damage_taken" = infrastructure["district_damage_taken"],
		"district_critical_events" = infrastructure["district_critical_events"],
		"district_turfs" = infrastructure["district_turfs"],
		"open_space_turfs" = infrastructure["open_space_turfs"],
		"dense_turfs" = infrastructure["dense_turfs"],
		"machines_total" = infrastructure["machines_total"],
		"broken_machines" = infrastructure["broken_machines"],
		"unpowered_machines" = infrastructure["unpowered_machines"],
		"damaged_objects" = infrastructure["damaged_objects"],
		"apc_total" = infrastructure["apc_total"],
		"apc_offline" = infrastructure["apc_offline"],
		"apc_low_charge" = infrastructure["apc_low_charge"],
		"telecomms_total" = infrastructure["telecomms_total"],
		"telecomms_offline" = infrastructure["telecomms_offline"],
		"powernet_count" = infrastructure["powernet_count"],
		"powernet_available" = infrastructure["powernet_available"],
		"powernet_load" = infrastructure["powernet_load"],
		"powernet_deficit" = infrastructure["powernet_deficit"],
		"cyber_network_objects" = infrastructure["cyber_network_objects"],
		"cyber_nodes" = infrastructure["cyber_nodes"],
		"cyber_nodes_breached" = infrastructure["cyber_nodes_breached"],
		"cyber_nodes_weak" = infrastructure["cyber_nodes_weak"],
		"cyber_net_data" = infrastructure["cyber_net_data"],
		"active_events" = length(cyberpunk_round_active_events),
		"history_size" = length(cyberpunk_round_event_history),
		"daylight_phase" = cyberpunk_round_phase,
		"daylight_sources" = length(cyberpunk_daylight_sources),
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_get_infrastructure_metrics()
	if(length(cyberpunk_round_last_infrastructure) && world.time < cyberpunk_round_last_infrastructure_at + cyberpunk_round_infrastructure_interval)
		return cyberpunk_round_last_infrastructure
	cyberpunk_round_last_infrastructure = cyberpunk_round_build_infrastructure_metrics()
	cyberpunk_round_last_infrastructure_at = world.time
	return cyberpunk_round_last_infrastructure

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_empty_infrastructure_metrics()
	return list(
		"district_count" = 0,
		"districts" = list(),
		"damaged_districts" = 0,
		"dangerous_districts" = 0,
		"district_violence" = 0,
		"district_damage_taken" = 0,
		"district_critical_events" = 0,
		"district_turfs" = 0,
		"open_space_turfs" = 0,
		"dense_turfs" = 0,
		"machines_total" = 0,
		"broken_machines" = 0,
		"unpowered_machines" = 0,
		"damaged_objects" = 0,
		"apc_total" = 0,
		"apc_offline" = 0,
		"apc_low_charge" = 0,
		"telecomms_total" = 0,
		"telecomms_offline" = 0,
		"powernet_count" = 0,
		"powernet_available" = 0,
		"powernet_load" = 0,
		"powernet_deficit" = 0,
		"cyber_network_objects" = 0,
		"cyber_nodes" = 0,
		"cyber_nodes_breached" = 0,
		"cyber_nodes_weak" = 0,
		"cyber_net_data" = 0,
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_light_infrastructure_metrics()
	if(length(cyberpunk_round_last_infrastructure))
		return cyberpunk_round_last_infrastructure
	return cyberpunk_round_empty_infrastructure_metrics()

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_build_infrastructure_metrics()
	var/list/result = cyberpunk_round_empty_infrastructure_metrics()
	var/list/districts = list()
	if(length(GLOB.the_station_areas))
		for(var/area_type as anything in GLOB.the_station_areas)
			CHECK_TICK
			var/area/station_area = GLOB.areas_by_type[area_type]
			if(!station_area)
				continue
			var/list/district = cyberpunk_round_build_area_district_metrics(station_area)
			if(!district || !(district["turfs"] || 0))
				continue
			result["district_count"]++
			result["district_turfs"] += district["turfs"] || 0
			result["open_space_turfs"] += district["open_space_turfs"] || 0
			result["dense_turfs"] += district["dense_turfs"] || 0
			result["machines_total"] += district["machines_total"] || 0
			result["broken_machines"] += district["broken_machines"] || 0
			result["unpowered_machines"] += district["unpowered_machines"] || 0
			result["damaged_objects"] += district["damaged_objects"] || 0
			result["district_violence"] += district["violence_score"] || 0
			result["district_damage_taken"] += district["violence_damage"] || 0
			result["district_critical_events"] += district["critical_events"] || 0
			result["apc_total"] += district["apc_total"] || 0
			result["apc_offline"] += district["apc_offline"] || 0
			result["apc_low_charge"] += district["apc_low_charge"] || 0
			if((district["pressure"] || 0) >= 10)
				result["damaged_districts"]++
			if((district["danger"] || 0) >= 30)
				result["dangerous_districts"]++
			cyberpunk_round_insert_district_metric(districts, district, 12)
	result["districts"] = districts

	for(var/obj/machinery/telecomms/telecom_machine as anything in GLOB.telecomm_machines)
		CHECK_TICK
		if(!telecom_machine)
			continue
		result["telecomms_total"]++
		if(telecom_machine.machine_stat & (BROKEN|NOPOWER))
			result["telecomms_offline"]++

	if(SSmachines)
		for(var/datum/powernet/powernet as anything in SSmachines.powernets)
			CHECK_TICK
			if(!powernet)
				continue
			result["powernet_count"]++
			result["powernet_available"] += powernet.avail
			result["powernet_load"] += powernet.load
			if(powernet.load > powernet.avail)
				result["powernet_deficit"] += powernet.load - powernet.avail

	var/list/cyber_objects = collect_all_cyberspace_network_objects()
	result["cyber_network_objects"] = length(cyber_objects)
	var/list/datum/cyberspace_node/cyber_nodes = build_cyberspace_nodes_from_candidates(cyber_objects)
	result["cyber_nodes"] = length(cyber_nodes)
	for(var/datum/cyberspace_node/node as anything in cyber_nodes)
		CHECK_TICK
		if(!node)
			continue
		var/integrity_percent = node.get_protection_integrity_percent()
		result["cyber_net_data"] += node.net_data
		if(integrity_percent <= 0)
			result["cyber_nodes_breached"]++
		else if(integrity_percent <= 35)
			result["cyber_nodes_weak"]++
		qdel(node)
	return result

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_build_area_district_metrics(area/station_area)
	var/list/district = list(
		"id" = station_area.cyberpunk_district_id || "[station_area.type]",
		"name" = station_area.cyberpunk_district_name || station_area.name,
		"type" = "[station_area.type]",
		"kind" = station_area.cyberpunk_district_kind,
		"index" = station_area.cyberpunk_district_index,
		"tags" = station_area.cyberpunk_world_tags?.Copy() || list(),
		"owner" = station_area.cyberpunk_world_owner,
		"violence_control" = station_area.cyberpunk_violence_control,
		"base_danger" = station_area.cyberpunk_district_base_danger,
		"turfs" = 0,
		"open_space_turfs" = 0,
		"dense_turfs" = 0,
		"machines_total" = 0,
		"broken_machines" = 0,
		"unpowered_machines" = 0,
		"damaged_objects" = 0,
		"apc_total" = 0,
		"apc_offline" = 0,
		"apc_low_charge" = 0,
		"violence_score" = 0,
		"violence_damage" = station_area.cyberpunk_round_damage_taken,
		"critical_events" = station_area.cyberpunk_round_critical_events,
		"last_violence_age" = station_area.cyberpunk_round_last_violence_at ? max(world.time - station_area.cyberpunk_round_last_violence_at, 0) : null,
		"danger" = 0,
		"pressure" = 0,
	)
	for(var/turf/station_turf as anything in station_area.get_turfs_from_all_zlevels())
		CHECK_TICK
		if(!station_turf)
			continue
		district["turfs"]++
		if(is_space_or_openspace(station_turf))
			district["open_space_turfs"]++
		if(station_turf.density)
			district["dense_turfs"]++
		for(var/obj/machinery/machine in station_turf)
			district["machines_total"]++
			if(machine.machine_stat & BROKEN)
				district["broken_machines"]++
			if(machine.machine_stat & NOPOWER)
				district["unpowered_machines"]++
			if(machine.max_integrity > 0 && machine.get_integrity() < machine.max_integrity)
				district["damaged_objects"]++
			if(istype(machine, /obj/machinery/power/apc))
				var/obj/machinery/power/apc/apc = machine
				district["apc_total"]++
				if(!apc.operating || (apc.machine_stat & (BROKEN|NOPOWER)))
					district["apc_offline"]++
				if(!apc.cell || apc.cell.percent() <= 25)
					district["apc_low_charge"]++
		for(var/obj/structure/structure in station_turf)
			if(structure.max_integrity > 0 && structure.get_integrity() < structure.max_integrity)
				district["damaged_objects"]++
	var/violence_decay = station_area.cyberpunk_round_last_violence_at ? max(round((world.time - station_area.cyberpunk_round_last_violence_at) / (5 MINUTES)), 0) : 0
	district["violence_score"] = max((station_area.cyberpunk_round_violence_score || 0) - violence_decay, 0)
	var/turf_count = max(district["turfs"] || 0, 1)
	var/infrastructure_pressure = round(((district["open_space_turfs"] || 0) / turf_count) * 60) + ((district["broken_machines"] || 0) * 3) + ((district["unpowered_machines"] || 0) * 2) + ((district["apc_offline"] || 0) * 8) + ((district["apc_low_charge"] || 0) * 4) + min((district["damaged_objects"] || 0), 25)
	district["pressure"] = min(100, infrastructure_pressure + round((district["violence_score"] || 0) * 1.5) + (district["base_danger"] || 0))
	district["danger"] = min(100, round((district["pressure"] || 0) * 0.65) + round((district["violence_score"] || 0) * 2) + (district["base_danger"] || 0))
	return district

/datum/controller/subsystem/cyberpunk_round/proc/record_cyberpunk_district_violence(atom/location, level = 1, reason = "violence", damage_amount = 0)
	var/area/current_area = get_area(location)
	if(!current_area)
		return FALSE
	var/severity = clamp(round(level || 1), 1, 10)
	var/previous_report = current_area.cyberpunk_round_last_violence_at
	current_area.cyberpunk_round_violence_score = min((current_area.cyberpunk_round_violence_score || 0) + severity, 100)
	current_area.cyberpunk_round_damage_taken += max(round(damage_amount || 0), 0)
	if(severity >= 3)
		current_area.cyberpunk_round_critical_events++
	current_area.cyberpunk_round_last_violence_at = world.time
	if(severity >= 3 && (!previous_report || world.time >= previous_report + 30 SECONDS))
		var/district_id = current_area.cyberpunk_district_id || "[current_area.type]"
		record_cyberpunk_round_event("district_violence", "district", district_id, cyberpunk_round_chaos, "[reason] reported in [current_area.name] at severity [severity].", "observed")
	return TRUE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_insert_district_metric(list/districts, list/district, max_count)
	if(!districts || !district)
		return
	var/inserted = FALSE
	for(var/index in 1 to length(districts))
		var/list/other = districts[index]
		if((district["pressure"] || 0) > (other["pressure"] || 0))
			districts.Insert(index, list(district))
			inserted = TRUE
			break
	if(!inserted)
		districts += list(district)
	if(length(districts) > max_count)
		districts.Cut(max_count + 1)

/datum/controller/subsystem/cyberpunk_round/proc/calculate_cyberpunk_round_chaos(list/snapshot)
	if(!snapshot)
		return cyberpunk_round_chaos
	var/pressure = 0
	pressure += (snapshot["accepted_contracts"] || 0) * 2
	pressure += (snapshot["offered_contracts"] || 0)
	pressure += (snapshot["failed_contracts"] || 0) * 5
	pressure += (snapshot["illegal_contracts"] || 0) * 2
	pressure += (snapshot["dead_players"] || 0) * 8
	pressure += (snapshot["critical_players"] || 0) * 4
	pressure += min(round((snapshot["total_player_damage"] || 0) / 100), 20)
	pressure += (snapshot["living_antags"] || 0) * 5
	pressure += min(round((snapshot["antag_total_funds"] || 0) / 1000), 15)
	pressure += min(round((snapshot["antag_objective_progress"] || 0) / 10), 10)
	pressure += min(round((snapshot["antag_group_pressure"] || 0) / 8), 20)
	pressure += min(round((snapshot["antag_faction_resource_pressure"] || 0) / 100), 10)
	if((snapshot["active_antags"] || 0) && (snapshot["antag_average_health"] || 0) <= 25)
		pressure -= 4
	pressure += min(snapshot["open_critical_roles"] || 0, 12)
	pressure += min(round((snapshot["business_warehouse_stock"] || 0) / 100), 10)
	pressure += min(round((snapshot["business_tax_debt"] || 0) / 1000), 20)
	pressure += min(round((snapshot["corporation_influence"] || 0) / 50), 15)
	pressure += min(round((snapshot["open_space_turfs"] || 0) / 20), 18)
	pressure += min(round((snapshot["broken_machines"] || 0) / 3), 18)
	pressure += min(round((snapshot["unpowered_machines"] || 0) / 5), 15)
	pressure += min((snapshot["apc_offline"] || 0) * 2, 16)
	pressure += min(round((snapshot["telecomms_offline"] || 0) * 3), 15)
	pressure += min(round((snapshot["powernet_deficit"] || 0) / 10000), 20)
	pressure += min((snapshot["cyber_nodes_breached"] || 0) * 4, 16)
	pressure += min((snapshot["cyber_nodes_weak"] || 0) * 2, 12)
	pressure += min((snapshot["damaged_districts"] || 0) * 3, 18)
	pressure += min((snapshot["dangerous_districts"] || 0) * 4, 20)
	pressure += min(round((snapshot["district_violence"] || 0) / 2), 20)
	pressure += min(snapshot["district_critical_events"] || 0, 12)
	pressure += length(cyberpunk_round_active_events) * 4
	if(cyberpunk_round_stage == "escalation")
		pressure += 15
	else if(cyberpunk_round_stage == "finish")
		pressure += 25
	return clamp(round((cyberpunk_round_chaos * 0.65) + (pressure * 0.35)), 0, 100)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_pulse()
	ensure_cyberpunk_storyteller_config()
	var/list/snapshot = cyberpunk_round_last_snapshot
	if(!snapshot || !length(snapshot))
		snapshot = build_cyberpunk_round_snapshot()
	cyberpunk_round_chaos = calculate_cyberpunk_round_chaos(snapshot)
	cyberpunk_storyteller_seed_arcs(snapshot)
	cyberpunk_round_storyteller_candidates = build_cyberpunk_storyteller_candidates(snapshot)
	if(cyberpunk_round_stage == "start" || cyberpunk_round_stage == "preparation")
		return
	if(!cyberpunk_storyteller_auto_execute)
		return
	var/list/selected_candidate = cyberpunk_storyteller_select_candidate(cyberpunk_round_storyteller_candidates)
	if(selected_candidate)
		cyberpunk_storyteller_execute_candidate(selected_candidate)

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_candidates(list/snapshot)
	ensure_cyberpunk_storyteller_config()
	var/list/candidates = list()
	var/chaos_delta = cyberpunk_round_chaos - cyberpunk_round_expected_chaos
	var/target_district = cyberpunk_storyteller_hot_district(snapshot)
	for(var/package_id in cyberpunk_storyteller_deferred_package_ids.Copy())
		var/list/package = cyberpunk_storyteller_find_package(package_id)
		if(!package)
			cyberpunk_storyteller_deferred_package_ids -= package_id
			continue
		var/executor = cyberpunk_storyteller_package_executor(package)
		var/theme = length(package["tags"]) ? package["tags"][1] : package["kind"]
		candidates += list(build_cyberpunk_storyteller_candidate("deferred_[package["id"]]", theme, executor, "Deferred admin/story package request.", 95, theme, package["scale"] || "city", target_district, null, null, package))
	if(chaos_delta >= 20)
		cyberpunk_storyteller_add_package_candidates(candidates, "recovery_window", "recovery", "event", "City pressure is above plan; prefer recovery, local service, and stabilization hooks.", 75, "recovery", "city", target_district)
	else if(chaos_delta <= -15)
		if((snapshot["accepted_contracts"] || 0) > (snapshot["completed_contracts"] || 0))
			cyberpunk_storyteller_add_package_candidates(candidates, "contract_pressure", "logistics", "event", "Contract activity is low-pressure; queue logistic or delivery prompts.", 60, "contracts", "city", target_district)
		else if((snapshot["corporation_count"] || 0) >= 3)
			cyberpunk_storyteller_add_package_candidates(candidates, "corporate_probe", "corporate", "dynamic_light", "Corporate field is available; queue a soft dynamic corporate conflict hook.", 55, "corporate", "corporations", target_district)
		else
			cyberpunk_storyteller_add_package_candidates(candidates, "market_opportunity", "economic", "event", "Economy can accept a low-risk opportunity hook.", 45, "economy", "city", target_district)
	else if(cyberpunk_round_stage == "escalation")
		cyberpunk_storyteller_add_package_candidates(candidates, "late_round_pressure", "escalation", "dynamic_heavy", "Escalation day reached; queue a heavier city, corporate, network, or criminal hook.", 85, "escalation", "city", target_district)
	else
		cyberpunk_storyteller_add_package_candidates(candidates, "city_maintenance", "city", "event", "Main flow pulse; keep light city prompts available.", 30, "city", "city", target_district)
	if(cyberpunk_storyteller_event_request_pressure > 0)
		cyberpunk_storyteller_add_package_candidates(candidates, "random_event_request", "system_event", "event", "SSevents requested a random event. Storyteller will release a concrete event package.", 45 + cyberpunk_storyteller_event_request_pressure * 8, "city", "city", target_district)
	if(cyberpunk_storyteller_dynamic_request_pressure > 0)
		var/executor = (cyberpunk_round_stage == "escalation" || cyberpunk_round_chaos >= cyberpunk_round_expected_chaos + 10) ? "dynamic_heavy" : "dynamic_light"
		cyberpunk_storyteller_add_package_candidates(candidates, "dynamic_midround_request", "dynamic_rule", executor, "SSdynamic requested a midround ruleset. Storyteller will release a concrete midround package.", 50 + cyberpunk_storyteller_dynamic_request_pressure * 10, "security", "city", target_district)
	candidates += cyberpunk_storyteller_build_arc_candidates()
	return candidates

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_hot_district(list/snapshot)
	var/list/districts = islist(snapshot) ? snapshot["districts"] : null
	if(!length(districts))
		return "city"
	var/list/top_district = districts[1]
	return top_district?["id"] || "city"

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_add_package_candidates(list/candidates, event_name, event_type, executor, details, priority, theme = null, faction = null, district = "city", arc_id = null, arc_step = null)
	var/added = FALSE
	for(var/list/package as anything in cyberpunk_storyteller_packages_for_executor(executor))
		if(!cyberpunk_storyteller_package_matches_theme(package, theme || event_type))
			continue
		var/list/candidate = build_cyberpunk_storyteller_candidate(event_name, event_type, executor, details, priority, theme, faction, district, arc_id, arc_step, package)
		candidates += list(candidate)
		added = TRUE
	if(!added)
		candidates += list(build_cyberpunk_storyteller_candidate(event_name, event_type, executor, details, priority, theme, faction, district, arc_id, arc_step))

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_packages_for_executor(executor)
	var/list/packages = list()
	if(executor == "event")
		return cyberpunk_storyteller_event_packages.Copy()
	for(var/list/package as anything in cyberpunk_storyteller_dynamic_packages)
		if(package["executor"] == executor)
			packages += list(package)
	return packages

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_find_package(package_id)
	ensure_cyberpunk_storyteller_config()
	for(var/list/package as anything in cyberpunk_storyteller_event_packages)
		if(package["id"] == package_id)
			return package
	for(var/list/package as anything in cyberpunk_storyteller_dynamic_packages)
		if(package["id"] == package_id)
			return package
	return null

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_executor(list/package)
	if(!package)
		return null
	if(package["kind"] == "event")
		return "event"
	return package["executor"]

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_matches_theme(list/package, theme)
	if(!package)
		return FALSE
	var/list/tags = package["tags"]
	if(!length(tags))
		return TRUE
	if(theme in tags)
		return TRUE
	if("city" in tags && (theme == "system_event" || theme == "dynamic_rule" || theme == "story_arc"))
		return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_status(list/package, list/candidate = null, list/snapshot = null)
	var/list/result = list(
		"ready" = FALSE,
		"reason" = "missing package",
	)
	if(!package)
		return result
	var/elapsed = cyberpunk_round_elapsed()
	if(elapsed < (package["min_time"] || 0))
		result["reason"] = "too early: [DisplayTimeText((package["min_time"] || 0) - elapsed)] remaining"
		return result
	if(!isnull(package["max_time"]) && elapsed > package["max_time"])
		result["reason"] = "too late: max time passed"
		return result
	var/recent_time = cyberpunk_round_recent_event_types[package["id"]]
	if(recent_time && world.time < recent_time + (package["cooldown"] || 10 MINUTES))
		result["reason"] = "cooldown: [DisplayTimeText((recent_time + (package["cooldown"] || 10 MINUTES)) - world.time)] remaining"
		return result
	var/condition_reason = cyberpunk_storyteller_package_condition_failure(package, candidate, snapshot)
	if(condition_reason)
		result["reason"] = condition_reason
		return result
	switch(package["kind"])
		if("event")
			if(!cyberpunk_storyteller_random_events_enabled || isnull(SSevents))
				result["reason"] = "SSevents backend disabled"
				return result
			var/event_name = package["event_name"]
			var/datum/round_event_control/event_control = SSevents.events_by_name[event_name]
			if(!event_control)
				result["reason"] = "missing SSevents control: [event_name]"
				return result
			var/players_amt = get_active_player_count(alive_check = TRUE, afk_check = TRUE, human_check = TRUE)
			if(!event_control.can_spawn_event(players_amt))
				result["reason"] = "event can_spawn_event() rejected current state"
				return result
		if("dynamic")
			if(!cyberpunk_storyteller_dynamic_rules_enabled || isnull(SSdynamic))
				result["reason"] = "SSdynamic backend disabled"
				return result
			var/ruleset_path = package["ruleset_path"]
			if(!ispath(ruleset_path, /datum/dynamic_ruleset/midround))
				result["reason"] = "invalid midround ruleset path"
				return result
			var/datum/dynamic_ruleset/midround/ruleset = new ruleset_path(SSdynamic.dynamic_config)
			var/can_select = ruleset.can_be_selected()
			qdel(ruleset)
			if(!can_select)
				result["reason"] = "ruleset can_be_selected() rejected current state"
				return result
		else
			result["reason"] = "unknown package kind"
			return result
	result["ready"] = TRUE
	result["reason"] = "ready"
	return result

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_candidate(event_name, event_type, executor, details, priority, theme = null, faction = null, district = "city", arc_id = null, arc_step = null, list/package = null)
	var/package_id = package ? package["id"] : null
	var/package_name = package ? package["name"] : null
	var/package_kind = package ? package["kind"] : null
	var/package_source = package ? package["source"] : null
	var/package_chaos = package ? package["chaos"] : null
	var/package_scale = package ? package["scale"] : null
	var/package_duration = package ? package["duration"] : null
	return list(
		"name" = event_name,
		"type" = event_type,
		"executor" = executor,
		"theme" = theme || event_type,
		"faction" = faction || "city",
		"district" = district || "city",
		"package" = package,
		"package_id" = package_id,
		"package_name" = package_name,
		"package_kind" = package_kind,
		"package_source" = package_source,
		"package_chaos" = package_chaos,
		"package_scale" = package_scale,
		"package_duration" = package_duration,
		"package_conditions" = cyberpunk_storyteller_package_condition_descriptions(package),
		"arc_id" = arc_id,
		"arc_step" = arc_step,
		"priority" = priority,
		"details" = details,
		"ready" = cyberpunk_storyteller_can_execute_candidate(list("type" = event_type, "executor" = executor, "package" = package, "district" = district)),
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_seed_arcs(list/snapshot)
	if(cyberpunk_round_stage == "start" || cyberpunk_round_stage == "preparation")
		return
	if(cyberpunk_storyteller_last_arc_seed_at && world.time < cyberpunk_storyteller_last_arc_seed_at + cyberpunk_storyteller_arc_seed_interval)
		return
	if(length(cyberpunk_storyteller_active_arcs) >= cyberpunk_storyteller_max_active_arcs)
		return
	var/list/arc_options = list()
	if((snapshot["accepted_contracts"] || 0) || (snapshot["offered_contracts"] || 0))
		arc_options += list(build_cyberpunk_storyteller_arc("contracts", "Contract pressure", "city", "city", 45 + (snapshot["accepted_contracts"] || 0) * 4))
	if(snapshot["business_tax_debt"] > 0)
		arc_options += list(build_cyberpunk_storyteller_arc("economy", "Tax debt pressure", "government", "city", 50 + min(round(snapshot["business_tax_debt"] / 1000), 25)))
	if(snapshot["corporation_count"] >= 3)
		arc_options += list(build_cyberpunk_storyteller_arc("corporate", "Corporate maneuver", "corporations", "city", 45 + min(snapshot["corporation_count"] * 5, 25)))
	if(cyberpunk_round_expected_chaos > cyberpunk_round_chaos + 10)
		arc_options += list(build_cyberpunk_storyteller_arc("security", "Low-tension escalation", "city", "city", 55))
	if(!length(arc_options))
		arc_options += list(build_cyberpunk_storyteller_arc("city", "City routine", "city", "city", 25))
	var/list/selected_arc = cyberpunk_storyteller_select_arc_seed(arc_options)
	if(!selected_arc)
		return
	cyberpunk_storyteller_active_arcs += list(selected_arc)
	cyberpunk_storyteller_last_arc_seed_at = world.time

/datum/controller/subsystem/cyberpunk_round/proc/build_cyberpunk_storyteller_arc(theme, name, faction, district, priority)
	var/arc_id = cyberpunk_storyteller_next_arc_id
	cyberpunk_storyteller_next_arc_id++
	return list(
		"id" = arc_id,
		"name" = name,
		"theme" = theme,
		"faction" = faction,
		"district" = district,
		"step" = 1,
		"max_steps" = 3,
		"heat" = clamp(priority, 10, 100),
		"priority" = priority,
		"created_at" = world.time,
		"next_at" = world.time,
		"status" = "active",
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_select_arc_seed(list/arc_options)
	if(!length(arc_options))
		return null
	var/list/eligible_arcs = list()
	var/total_weight = 0
	for(var/list/arc as anything in arc_options)
		if(cyberpunk_storyteller_has_active_arc(arc["theme"]))
			continue
		eligible_arcs += list(arc)
		total_weight += max(arc["priority"] || 1, 1)
	if(!length(eligible_arcs))
		return null
	var/roll = rand(1, total_weight)
	var/current_weight = 0
	for(var/list/arc as anything in eligible_arcs)
		current_weight += max(arc["priority"] || 1, 1)
		if(roll <= current_weight)
			return arc
	return eligible_arcs[length(eligible_arcs)]

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_has_active_arc(theme)
	for(var/list/arc as anything in cyberpunk_storyteller_active_arcs)
		if(arc["status"] == "active" && arc["theme"] == theme)
			return TRUE
	return FALSE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_build_arc_candidates()
	var/list/candidates = list()
	for(var/list/arc as anything in cyberpunk_storyteller_active_arcs)
		if(arc["status"] != "active")
			continue
		if(world.time < (arc["next_at"] || 0))
			continue
		var/executor = "event"
		var/step = arc["step"] || 1
		var/heat = arc["heat"] || 0
		if(step >= 3 || heat >= 75)
			executor = "dynamic_heavy"
		else if(step >= 2 || heat >= 55)
			executor = "dynamic_light"
		var/arc_id = arc["id"]
		var/arc_name = arc["name"]
		var/arc_theme = arc["theme"]
		var/arc_max_steps = arc["max_steps"]
		var/details = "Arc [arc_id] step [step]/[arc_max_steps]: [arc_name]."
		cyberpunk_storyteller_add_package_candidates(
			candidates,
			"arc_[arc_theme]_[step]",
			"story_arc",
			executor,
			details,
			arc["priority"] + step * 8,
			arc_theme,
			arc["faction"],
			arc["district"],
			arc_id,
			step,
		)
	return candidates

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_select_candidate(list/candidates)
	if(!length(candidates))
		return null
	var/list/eligible_candidates = list()
	var/total_weight = 0
	for(var/list/candidate as anything in candidates)
		if(!cyberpunk_storyteller_can_execute_candidate(candidate))
			continue
		var/score = cyberpunk_storyteller_score_candidate(candidate)
		candidate["score"] = score
		eligible_candidates += list(candidate)
		total_weight += score
	if(!length(eligible_candidates) || total_weight <= 0)
		return null
	var/roll = rand(1, total_weight)
	var/current_weight = 0
	for(var/list/candidate as anything in eligible_candidates)
		current_weight += max(candidate["score"] || candidate["priority"] || 1, 1)
		if(roll <= current_weight)
			return candidate
	return eligible_candidates[length(eligible_candidates)]

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_score_candidate(list/candidate)
	var/score = max(candidate["priority"] || 1, 1)
	var/theme = candidate["theme"] || candidate["type"]
	var/faction = candidate["faction"] || "city"
	var/district = candidate["district"] || "city"
	var/list/package = candidate["package"]
	var/list/profile = cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile] || cyberpunk_storyteller_profile_options["balanced"]
	if(package)
		score += package["weight"] || 0
	score = cyberpunk_storyteller_apply_memory_score(score, cyberpunk_storyteller_topic_memory[theme])
	score = cyberpunk_storyteller_apply_memory_score(score, cyberpunk_storyteller_faction_memory[faction], 0.75)
	score = cyberpunk_storyteller_apply_memory_score(score, cyberpunk_storyteller_district_memory[district], 0.85)
	switch(candidate["executor"])
		if("event")
			score *= profile ? (profile["event_weight"] || 1) : 1
		if("dynamic_light")
			score *= profile ? (profile["dynamic_light_weight"] || 1) : 1
		if("dynamic_heavy")
			score *= profile ? (profile["dynamic_heavy_weight"] || 1) : 1
	if(package)
		score *= cyberpunk_storyteller_profile_tag_multiplier(profile, package)
	if(theme == "recovery")
		score *= profile ? (profile["recovery_weight"] || 1) : 1
	if(cyberpunk_storyteller_last_executed_at)
		var/gap_age = world.time - cyberpunk_storyteller_last_executed_at
		if(gap_age < cyberpunk_storyteller_min_event_gap * (profile ? (profile["gap_multiplier"] || 1) : 1))
			score *= 0.5
	if(candidate["executor"] == "dynamic_heavy")
		if(cyberpunk_round_stage != "escalation")
			score *= 0.65
		if(cyberpunk_round_chaos > cyberpunk_round_expected_chaos + 15)
			score *= 0.5
	if(cyberpunk_round_phase == "night" && (theme == "security" || theme == "contracts" || theme == "dynamic_rule"))
		score *= 1.2
	if(cyberpunk_round_phase == "day" && (theme == "corporate" || theme == "economy"))
		score *= 1.15
	if(cyberpunk_round_expected_chaos > cyberpunk_round_chaos + 10)
		score *= 1.2
	else if(cyberpunk_round_chaos > cyberpunk_round_expected_chaos + 10 && theme == "recovery")
		score *= 1.4
	return max(round(score), 1)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_profile_tag_multiplier(list/profile, list/package)
	if(!profile || !package)
		return 1
	var/multiplier = 1
	var/list/tags = package["tags"]
	if(("security" in tags) || ("escalation" in tags))
		multiplier *= profile["combat_weight"] || 1
	if(("economy" in tags) || ("contracts" in tags))
		multiplier *= profile["economy_weight"] || 1
	if("network" in tags)
		multiplier *= profile["network_weight"] || 1
	if("corporate" in tags)
		multiplier *= profile["corporate_weight"] || 1
	return multiplier

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_apply_memory_score(score, last_time, repeated_multiplier = 0.55)
	if(!last_time)
		return score
	var/age = world.time - last_time
	if(age < 12 MINUTES)
		return score * repeated_multiplier
	if(age > 30 MINUTES)
		return score * 1.1
	return score

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_can_execute_candidate(list/candidate)
	if(!candidate || cyberpunk_round_stage == "start" || cyberpunk_round_stage == "preparation")
		return FALSE
	var/list/profile = cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile] || cyberpunk_storyteller_profile_options["balanced"]
	var/min_gap = cyberpunk_storyteller_min_event_gap * (profile ? (profile["gap_multiplier"] || 1) : 1)
	if(cyberpunk_storyteller_last_executed_at && world.time < cyberpunk_storyteller_last_executed_at + min_gap)
		return FALSE
	var/event_type = candidate["type"]
	var/recent_time = cyberpunk_round_recent_event_types[event_type]
	if(recent_time && world.time < recent_time + 10 MINUTES)
		return FALSE
	var/list/package = candidate["package"]
	if(package)
		return cyberpunk_storyteller_package_available(package, candidate, cyberpunk_round_last_snapshot) && cyberpunk_storyteller_package_fits_pressure(candidate, package)
	return FALSE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_condition_descriptions(list/package)
	var/list/result = list()
	if(!package)
		return result
	for(var/condition_path as anything in package["conditions"])
		if(!ispath(condition_path, /datum/cyberpunk_story_event_condition))
			continue
		var/datum/cyberpunk_story_event_condition/condition = new condition_path()
		result += list(list(
			"id" = condition.id,
			"description" = condition.describe(),
			"failure_reason" = condition.fail_reason(),
			"required_value" = condition.required_value,
		))
		qdel(condition)
	return result

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_conditions_met(list/package, list/candidate, list/snapshot)
	return isnull(cyberpunk_storyteller_package_condition_failure(package, candidate, snapshot))

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_condition_failure(list/package, list/candidate, list/snapshot)
	if(!package)
		return "missing package"
	var/list/conditions = package["conditions"]
	if(!length(conditions))
		return null
	if(!length(snapshot))
		snapshot = cyberpunk_round_last_snapshot
	if(!length(snapshot))
		snapshot = build_cyberpunk_round_snapshot(FALSE)
	for(var/condition_path as anything in conditions)
		if(!ispath(condition_path, /datum/cyberpunk_story_event_condition))
			continue
		var/datum/cyberpunk_story_event_condition/condition = new condition_path()
		var/passed = condition.is_met(snapshot, candidate, package)
		var/fail_reason = condition.fail_reason()
		qdel(condition)
		if(!passed)
			return fail_reason || "condition failed"
	return null

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_available(list/package, list/candidate = null, list/snapshot = null)
	var/list/status = cyberpunk_storyteller_package_status(package, candidate, snapshot)
	return !!status["ready"]

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_fits_pressure(list/candidate, list/package)
	var/package_chaos = package["chaos"] || 0
	var/list/curve_point = cyberpunk_storyteller_curve_state(cyberpunk_round_elapsed())
	var/force_chaos = curve_point["force_chaos"]
	var/projected_chaos = cyberpunk_round_chaos + package_chaos
	var/allowed_chaos = (curve_point["expected_chaos"] || cyberpunk_round_expected_chaos) + (curve_point["tolerance"] || cyberpunk_round_chaos_tolerance)
	var/list/profile = cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile] || cyberpunk_storyteller_profile_options["balanced"]
	if(profile)
		allowed_chaos = min(allowed_chaos, profile["max_chaos"] || allowed_chaos)
	if(candidate["theme"] == "recovery")
		return TRUE
	if(projected_chaos > allowed_chaos && !force_chaos)
		return FALSE
	if(cyberpunk_round_chaos > allowed_chaos && package_chaos > 6)
		return FALSE
	return TRUE

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_execute_candidate(list/candidate)
	if(!cyberpunk_storyteller_can_execute_candidate(candidate))
		return FALSE
	var/success = FALSE
	var/list/package = candidate["package"]
	if(package)
		switch(package["kind"])
			if("event")
				var/datum/round_event_control/event_control = SSevents.events_by_name[package["event_name"]]
				if(event_control)
					var/event_result = SSevents.TriggerEvent(event_control)
					success = (event_result == EVENT_READY || isnull(event_result))
					cyberpunk_storyteller_event_request_pressure = max(cyberpunk_storyteller_event_request_pressure - 1, 0)
			if("dynamic")
				var/ruleset_path = package["ruleset_path"]
				if(ispath(ruleset_path, /datum/dynamic_ruleset/midround))
					success = SSdynamic.force_run_midround(ruleset_path, null, FALSE)
					cyberpunk_storyteller_dynamic_request_pressure = max(cyberpunk_storyteller_dynamic_request_pressure - 1, 0)
	var/status = success ? "executed" : "blocked"
	if(success)
		cyberpunk_storyteller_last_executed_at = world.time
		cyberpunk_round_recent_event_types[candidate["type"]] = world.time
		if(candidate["package_id"])
			cyberpunk_round_recent_event_types[candidate["package_id"]] = world.time
	cyberpunk_storyteller_record_memory(candidate)
	cyberpunk_storyteller_update_arc_after_execution(candidate, success)
	record_cyberpunk_round_event(candidate["name"], candidate["type"], candidate["district"] || "city", cyberpunk_round_chaos, candidate["details"], status, candidate)
	return success

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_record_memory(list/candidate)
	var/theme = candidate["theme"] || candidate["type"]
	var/faction = candidate["faction"] || "city"
	var/district = candidate["district"] || "city"
	if(theme)
		cyberpunk_storyteller_topic_memory[theme] = world.time
	if(faction)
		cyberpunk_storyteller_faction_memory[faction] = world.time
	if(district)
		cyberpunk_storyteller_district_memory[district] = world.time

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_update_arc_after_execution(list/candidate, success)
	var/arc_id = candidate["arc_id"]
	if(!arc_id)
		return
	for(var/list/arc as anything in cyberpunk_storyteller_active_arcs)
		if(arc["id"] != arc_id)
			continue
		if(!success)
			arc["next_at"] = world.time + 2 MINUTES
			arc["heat"] = max((arc["heat"] || 0) - 5, 0)
			return
		arc["step"] = (arc["step"] || 1) + 1
		arc["heat"] = min((arc["heat"] || 0) + 8, 100)
		arc["next_at"] = world.time + rand(3 MINUTES, 7 MINUTES)
		if((arc["step"] || 1) > (arc["max_steps"] || 3))
			arc["status"] = "completed"
			cyberpunk_storyteller_active_arcs -= arc
		return

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_controls_random_events()
	return cyberpunk_storyteller_random_events_enabled

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_controls_dynamic_rules()
	return cyberpunk_storyteller_dynamic_rules_enabled

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_consider_random_event()
	if(!cyberpunk_storyteller_random_events_enabled)
		return FALSE
	cyberpunk_storyteller_event_request_pressure = min(cyberpunk_storyteller_event_request_pressure + 1, 5)
	return cyberpunk_storyteller_record_deferred_hook("random_event_request", "system_event", "SSevents random event roll deferred to storyteller.")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_consider_dynamic_rules()
	if(!cyberpunk_storyteller_dynamic_rules_enabled)
		return FALSE
	cyberpunk_storyteller_dynamic_request_pressure = min(cyberpunk_storyteller_dynamic_request_pressure + 1, 5)
	return cyberpunk_storyteller_record_deferred_hook("dynamic_midround_request", "dynamic_rule", "SSdynamic midround ruleset roll deferred to storyteller.")

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_pick_roundstart_rulesets(list/antag_candidates)
	if(!cyberpunk_storyteller_dynamic_rules_enabled)
		return null
	cyberpunk_storyteller_record_deferred_hook("dynamic_roundstart_request", "dynamic_rule", "SSdynamic roundstart ruleset selection observed by storyteller. Candidates: [length(antag_candidates)].")
	return null

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_record_deferred_hook(event_name, event_type, details)
	var/recent_time = cyberpunk_round_recent_event_types[event_name]
	if(recent_time && world.time < recent_time + 5 MINUTES)
		return TRUE
	cyberpunk_round_recent_event_types[event_name] = world.time
	record_cyberpunk_round_event(event_name, event_type, "city", cyberpunk_round_chaos, details, "deferred")
	return TRUE

/datum/controller/subsystem/cyberpunk_round/proc/record_cyberpunk_round_event(event_name, event_type, district, chaos_value, details, status = "draft", list/candidate = null)
	var/list/record = list(
		"id" = length(cyberpunk_round_event_history) + 1,
		"time" = world.time,
		"clock" = cyberpunk_round_clock_text(),
		"name" = event_name,
		"type" = event_type,
		"theme" = candidate ? (candidate["theme"] || event_type) : event_type,
		"faction" = candidate ? (candidate["faction"] || "city") : "city",
		"district" = district,
		"package_id" = candidate ? candidate["package_id"] : null,
		"package_name" = candidate ? candidate["package_name"] : null,
		"package_kind" = candidate ? candidate["package_kind"] : null,
		"package_source" = candidate ? candidate["package_source"] : null,
		"package_chaos" = candidate ? candidate["package_chaos"] : null,
		"package_scale" = candidate ? candidate["package_scale"] : null,
		"package_duration" = candidate ? candidate["package_duration"] : null,
		"arc_id" = candidate ? candidate["arc_id"] : null,
		"arc_step" = candidate ? candidate["arc_step"] : null,
		"score" = candidate ? candidate["score"] : null,
		"chaos" = chaos_value,
		"status" = status,
		"details" = details,
	)
	cyberpunk_round_event_history += list(record)
	var/excess = length(cyberpunk_round_event_history) - 80
	if(excess > 0)
		cyberpunk_round_event_history.Cut(1, excess + 1)
	return record

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_memory_rows(list/memory)
	var/list/rows = list()
	if(!memory)
		return rows
	for(var/memory_key in memory)
		var/last_time = memory[memory_key]
		rows += list(list(
			"name" = memory_key,
			"age" = max(world.time - last_time, 0),
		))
	return rows

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_memory_data()
	return list(
		"themes" = cyberpunk_storyteller_memory_rows(cyberpunk_storyteller_topic_memory),
		"factions" = cyberpunk_storyteller_memory_rows(cyberpunk_storyteller_faction_memory),
		"districts" = cyberpunk_storyteller_memory_rows(cyberpunk_storyteller_district_memory),
	)

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_profile_rows()
	ensure_cyberpunk_storyteller_config()
	var/list/rows = list()
	for(var/profile_id in cyberpunk_storyteller_profile_options)
		var/list/profile = cyberpunk_storyteller_profile_options[profile_id]
		rows += list(list(
			"id" = profile["id"],
			"name" = profile["name"],
			"event_weight" = profile["event_weight"],
			"dynamic_light_weight" = profile["dynamic_light_weight"],
			"dynamic_heavy_weight" = profile["dynamic_heavy_weight"],
			"recovery_weight" = profile["recovery_weight"],
			"gap_multiplier" = profile["gap_multiplier"],
			"max_chaos" = profile["max_chaos"],
			"combat_weight" = profile["combat_weight"],
			"economy_weight" = profile["economy_weight"],
			"network_weight" = profile["network_weight"],
			"corporate_weight" = profile["corporate_weight"],
			"escalation_speed" = profile["escalation_speed"],
		))
	return rows

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_storyteller_package_rows(list/snapshot)
	ensure_cyberpunk_storyteller_config()
	var/list/rows = list()
	for(var/list/package as anything in cyberpunk_storyteller_event_packages + cyberpunk_storyteller_dynamic_packages)
		var/executor = cyberpunk_storyteller_package_executor(package)
		var/theme = length(package["tags"]) ? package["tags"][1] : package["kind"]
		var/list/candidate = build_cyberpunk_storyteller_candidate("package_preview_[package["id"]]", theme, executor, "Package readiness preview.", package["weight"] || 0, theme, package["scale"] || "city", cyberpunk_storyteller_hot_district(snapshot), null, null, package)
		var/list/status = cyberpunk_storyteller_package_status(package, candidate, snapshot)
		if(status["ready"] && !cyberpunk_storyteller_can_execute_candidate(candidate))
			status["ready"] = FALSE
			status["reason"] = "storyteller gap, recent type cooldown, or chaos pressure blocks release"
		rows += list(list(
			"id" = package["id"],
			"name" = package["name"],
			"kind" = package["kind"],
			"source" = package["source"],
			"executor" = executor,
			"event_name" = package["event_name"],
			"ruleset_path" = "[package["ruleset_path"]]",
			"weight" = package["weight"],
			"tags" = package["tags"],
			"chaos" = package["chaos"],
			"min_time" = package["min_time"],
			"max_time" = package["max_time"],
			"scale" = package["scale"],
			"duration" = package["duration"],
			"cooldown" = package["cooldown"],
			"conditions" = cyberpunk_storyteller_package_condition_descriptions(package),
			"ready" = status["ready"],
			"reason" = status["reason"],
			"queued" = (package["id"] in cyberpunk_storyteller_deferred_package_ids),
		))
	return rows

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_payload_tab_for(mob/user)
	var/tab = user?.ckey ? cyberpunk_round_ui_payload_tabs[user.ckey] : null
	return tab || "snapshot"

/datum/controller/subsystem/cyberpunk_round/proc/cyberpunk_round_status_data(mob/user)
	ensure_cyberpunk_storyteller_config()
	if(!length(cyberpunk_storyteller_round_plan))
		cyberpunk_storyteller_rebuild_round_plan()
	if(SSticker && SSticker.IsRoundInProgress())
		if(!cyberpunk_round_started_at)
			start_cyberpunk_round_clock()
		update_cyberpunk_round_clock()
	if(!length(cyberpunk_round_last_snapshot) || world.time >= cyberpunk_round_last_snapshot_at + cyberpunk_round_snapshot_interval)
		cyberpunk_round_last_snapshot = build_cyberpunk_round_snapshot(FALSE)
		cyberpunk_round_last_snapshot_at = world.time
	var/list/profile = cyberpunk_storyteller_profile_options[cyberpunk_storyteller_profile] || cyberpunk_storyteller_profile_options["balanced"]
	var/min_gap = cyberpunk_storyteller_min_event_gap * (profile ? (profile["gap_multiplier"] || 1) : 1)
	var/payload_tab = cyberpunk_round_payload_tab_for(user)
	var/list/data = list(
		"can_admin" = !!user?.client?.holder,
		"payload_tab" = payload_tab,
		"clock" = cyberpunk_round_clock_text(),
		"stage" = cyberpunk_round_stage,
		"end_state" = cyberpunk_round_end_state,
		"phase" = cyberpunk_round_phase_name,
		"phase_id" = cyberpunk_round_phase,
		"day" = cyberpunk_round_day,
		"ingame_minutes" = cyberpunk_round_ingame_minutes,
		"extensions_used" = cyberpunk_round_extensions_used,
		"max_extensions" = cyberpunk_round_max_extensions,
		"extension_days" = cyberpunk_round_extension_days,
		"start_report_announced" = cyberpunk_round_start_report_announced,
		"catastrophic_evac_requested" = cyberpunk_round_catastrophic_evac_requested,
		"chaos" = cyberpunk_round_chaos,
		"expected_chaos" = cyberpunk_round_expected_chaos,
		"chaos_tolerance" = cyberpunk_round_chaos_tolerance,
		"random_events_enabled" = cyberpunk_storyteller_random_events_enabled,
		"dynamic_rules_enabled" = cyberpunk_storyteller_dynamic_rules_enabled,
		"auto_execute" = cyberpunk_storyteller_auto_execute,
		"storyteller_profile" = cyberpunk_storyteller_profile,
		"storyteller_profiles" = cyberpunk_storyteller_profile_rows(),
		"daylight_enabled" = cyberpunk_daylight_enabled,
		"fast_day_enabled" = cyberpunk_round_fast_day_enabled,
		"fast_phase_duration" = cyberpunk_round_fast_phase_duration,
		"real_day_duration" = cyberpunk_round_real_day,
		"event_pressure" = cyberpunk_storyteller_event_request_pressure,
		"dynamic_pressure" = cyberpunk_storyteller_dynamic_request_pressure,
		"next_pulse" = max((cyberpunk_round_last_storyteller_at + cyberpunk_round_storyteller_interval) - world.time, 0),
		"next_execute" = max((cyberpunk_storyteller_last_executed_at + min_gap) - world.time, 0),
		"daylight_sources" = length(cyberpunk_daylight_sources),
		"daylight_power" = cyberpunk_daylight_current_power,
		"daylight_range" = cyberpunk_daylight_current_range,
		"daylight_color" = cyberpunk_daylight_current_color,
		"snapshot_summary" = list(
			"living_players" = cyberpunk_round_last_snapshot["living_players"] || 0,
			"dead_players" = cyberpunk_round_last_snapshot["dead_players"] || 0,
			"critical_players" = cyberpunk_round_last_snapshot["critical_players"] || 0,
			"living_antags" = cyberpunk_round_last_snapshot["living_antags"] || 0,
			"antag_group_count" = cyberpunk_round_last_snapshot["antag_group_count"] || 0,
			"antag_group_pressure" = cyberpunk_round_last_snapshot["antag_group_pressure"] || 0,
			"accepted_contracts" = cyberpunk_round_last_snapshot["accepted_contracts"] || 0,
			"dangerous_districts" = cyberpunk_round_last_snapshot["dangerous_districts"] || 0,
			"district_violence" = cyberpunk_round_last_snapshot["district_violence"] || 0,
			"cyber_nodes_breached" = cyberpunk_round_last_snapshot["cyber_nodes_breached"] || 0,
		),
		"round_summary" = cyberpunk_round_last_summary.Copy(),
	)
	switch(payload_tab)
		if("snapshot")
			data["snapshot"] = cyberpunk_round_last_snapshot
		if("story")
			data["candidates"] = cyberpunk_round_storyteller_candidates.Copy()
			data["active_arcs"] = cyberpunk_storyteller_active_arcs.Copy()
			data["storyteller_curve"] = cyberpunk_storyteller_curve.Copy()
			data["round_plan"] = cyberpunk_storyteller_round_plan.Copy()
			data["memory"] = cyberpunk_storyteller_memory_data()
		if("payloads")
			data["packages"] = cyberpunk_storyteller_package_rows(cyberpunk_round_last_snapshot)
			data["deferred_packages"] = cyberpunk_storyteller_deferred_package_ids.Copy()
		if("history")
			data["history"] = cyberpunk_round_event_history.Copy()
	return data

/datum/controller/subsystem/cyberpunk_round/ui_state(mob/user)
	return GLOB.always_state

/datum/controller/subsystem/cyberpunk_round/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CyberpunkRound", "Round Storyteller")
		ui.open()

/datum/controller/subsystem/cyberpunk_round/ui_data(mob/user)
	return cyberpunk_round_status_data(user)

/datum/controller/subsystem/cyberpunk_round/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!user?.client?.holder)
		return FALSE
	switch(action)
		if("pulse")
			cyberpunk_storyteller_pulse()
			return TRUE
		if("toggle_auto_execute")
			cyberpunk_storyteller_auto_execute = !cyberpunk_storyteller_auto_execute
			return TRUE
		if("toggle_random_events")
			cyberpunk_storyteller_random_events_enabled = !cyberpunk_storyteller_random_events_enabled
			return TRUE
		if("toggle_dynamic_rules")
			cyberpunk_storyteller_dynamic_rules_enabled = !cyberpunk_storyteller_dynamic_rules_enabled
			return TRUE
		if("set_profile")
			ensure_cyberpunk_storyteller_config()
			var/profile_id = params["profile"]
			if(!cyberpunk_storyteller_profile_options[profile_id])
				return FALSE
			cyberpunk_storyteller_profile = profile_id
			cyberpunk_storyteller_curve = cyberpunk_storyteller_build_curve()
			cyberpunk_storyteller_rebuild_round_plan()
			cyberpunk_round_storyteller_candidates = build_cyberpunk_storyteller_candidates(cyberpunk_round_last_snapshot || build_cyberpunk_round_snapshot(FALSE))
			return TRUE
		if("toggle_daylight")
			cyberpunk_daylight_enabled = !cyberpunk_daylight_enabled
			if(!cyberpunk_daylight_enabled)
				clear_cyberpunk_daylight()
			else
				cyberpunk_daylight_last_phase = null
				cyberpunk_daylight_last_bucket = -1
				update_cyberpunk_daylight()
			return TRUE
		if("toggle_fast_day")
			set_cyberpunk_round_fast_day_mode(!cyberpunk_round_fast_day_enabled)
			return TRUE
		if("set_payload_tab")
			var/tab = params["tab"]
			if(!(tab in list("snapshot", "story", "payloads", "history")))
				return FALSE
			if(user.ckey)
				cyberpunk_round_ui_payload_tabs[user.ckey] = tab
			return TRUE
		if("execute_candidate")
			var/index = text2num(params["index"])
			if(index < 1 || index > length(cyberpunk_round_storyteller_candidates))
				return FALSE
			var/list/candidate = cyberpunk_round_storyteller_candidates[index]
			cyberpunk_storyteller_execute_candidate(candidate)
			return TRUE
		if("defer_package")
			var/package_id = params["package_id"]
			var/list/package = cyberpunk_storyteller_find_package(package_id)
			if(!package)
				return FALSE
			if(!(package_id in cyberpunk_storyteller_deferred_package_ids))
				cyberpunk_storyteller_deferred_package_ids += package_id
			record_cyberpunk_round_event("defer_[package_id]", "storyteller_package", "city", cyberpunk_round_chaos, "Package [package["name"]] deferred by [key_name(user)].", "deferred")
			return TRUE
		if("execute_package")
			var/package_id = params["package_id"]
			var/list/package = cyberpunk_storyteller_find_package(package_id)
			if(!package)
				return FALSE
			var/executor = cyberpunk_storyteller_package_executor(package)
			var/theme = length(package["tags"]) ? package["tags"][1] : package["kind"]
			var/list/candidate = build_cyberpunk_storyteller_candidate("manual_[package["id"]]", theme, executor, "Manual package execution.", 100, theme, package["scale"] || "city", cyberpunk_storyteller_hot_district(cyberpunk_round_last_snapshot), null, null, package)
			var/success = cyberpunk_storyteller_execute_candidate(candidate)
			if(success)
				cyberpunk_storyteller_deferred_package_ids -= package_id
			return success
	return FALSE

ADMIN_VERB(cyberpunk_round_control, R_ADMIN, "Cyberpunk Round Control", "Open the CP13 storyteller and round control panel.", ADMIN_CATEGORY_GAME)
	if(!SScyberpunk_round || !user.mob)
		return
	SScyberpunk_round.ui_interact(user.mob)
	BLACKBOX_LOG_ADMIN_VERB("Cyberpunk Round Control")

/mob/living/verb/cyberpunk_round_status()
	set name = "Round Status"
	set category = "IC"
	if(!SScyberpunk_round)
		return
	SScyberpunk_round.ui_interact(src)

/obj/effect/cyberpunk_daylight_source
	name = "daylight"
	icon = null
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
