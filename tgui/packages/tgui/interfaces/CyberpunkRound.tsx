// CYBERPUNK BUILD - rebuild and delete before release
import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Snapshot = {
  player_count: number;
  living_players: number;
  dead_players: number;
  critical_players: number;
  total_player_damage: number;
  security_players: number;
  command_players: number;
  medical_players: number;
  engineering_players: number;
  specialist_players: number;
  open_critical_roles: number;
  open_security_roles: number;
  open_medical_roles: number;
  open_engineering_roles: number;
  active_antags: number;
  living_antags: number;
  dead_antags: number;
  created_contracts: number;
  offered_contracts: number;
  accepted_contracts: number;
  completed_contracts: number;
  failed_contracts: number;
  illegal_contracts: number;
  businesses: number;
  legal_businesses: number;
  illegal_businesses: number;
  apartments: number;
  business_deliveries: number;
  business_tax_debt: number;
  business_tax_paid: number;
  business_employee_count: number;
  business_warehouse_stock: number;
  valid_business_premises: number;
  corporation_count: number;
  corporation_funds: number;
  corporation_influence: number;
  district_count: number;
  districts: DistrictRecord[];
  damaged_districts: number;
  district_turfs: number;
  open_space_turfs: number;
  dense_turfs: number;
  machines_total: number;
  broken_machines: number;
  unpowered_machines: number;
  damaged_objects: number;
  apc_total: number;
  apc_offline: number;
  apc_low_charge: number;
  telecomms_total: number;
  telecomms_offline: number;
  powernet_count: number;
  powernet_available: number;
  powernet_load: number;
  powernet_deficit: number;
  cyber_network_objects: number;
  cyber_nodes: number;
  cyber_nodes_breached: number;
  cyber_nodes_weak: number;
  cyber_net_data: number;
};

type DistrictRecord = {
  id: string;
  name: string;
  type: string;
  turfs: number;
  open_space_turfs: number;
  dense_turfs: number;
  machines_total: number;
  broken_machines: number;
  unpowered_machines: number;
  damaged_objects: number;
  apc_total: number;
  apc_offline: number;
  apc_low_charge: number;
  pressure: number;
};

type Candidate = {
  name: string;
  type: string;
  theme: string;
  faction: string;
  executor: string;
  district: string;
  package_id?: string;
  package_name?: string;
  package_kind?: string;
  package_source?: string;
  package_chaos?: number;
  package_scale?: string;
  package_duration?: string;
  priority: number;
  score: number;
  arc_id?: number;
  arc_step?: number;
  details: string;
  ready: BooleanLike;
};

type StoryArc = {
  id: number;
  name: string;
  theme: string;
  faction: string;
  district: string;
  step: number;
  max_steps: number;
  heat: number;
  priority: number;
  status: string;
};

type MemoryRecord = {
  name: string;
  age: number;
};

type StoryMemory = {
  themes: MemoryRecord[];
  factions: MemoryRecord[];
  districts: MemoryRecord[];
};

type StoryProfile = {
  id: string;
  name: string;
  event_weight: number;
  dynamic_light_weight: number;
  dynamic_heavy_weight: number;
  recovery_weight: number;
  gap_multiplier: number;
  max_chaos: number;
  combat_weight: number;
  economy_weight: number;
  network_weight: number;
  corporate_weight: number;
  escalation_speed: number;
};

type CurvePoint = {
  time: number;
  expected_chaos: number;
  tolerance: number;
  force_chaos: BooleanLike;
};

type RoundPlanPoint = CurvePoint & {
  preferred_executor: string;
};

type RoundSummary = {
  reason?: string;
  clock?: string;
  day?: number;
  stage?: string;
  chaos?: number;
  expected_chaos?: number;
  living_players?: number;
  dead_players?: number;
  critical_players?: number;
  active_antags?: number;
  completed_contracts?: number;
  failed_contracts?: number;
  businesses?: number;
  business_tax_debt?: number;
  corporation_count?: number;
  history_size?: number;
};

type HistoryRecord = {
  id: number;
  clock: string;
  name: string;
  type: string;
  theme: string;
  faction: string;
  district: string;
  package_id?: string;
  package_name?: string;
  package_kind?: string;
  package_source?: string;
  package_chaos?: number;
  package_scale?: string;
  package_duration?: string;
  arc_id?: number;
  arc_step?: number;
  score?: number;
  chaos: number;
  status: string;
  details: string;
};

type Data = {
  can_admin: BooleanLike;
  clock: string;
  stage: string;
  end_state: string;
  phase: string;
  phase_id: string;
  day: number;
  extensions_used: number;
  max_extensions: number;
  extension_days: number;
  start_report_announced: BooleanLike;
  catastrophic_evac_requested: BooleanLike;
  chaos: number;
  expected_chaos: number;
  chaos_tolerance: number;
  random_events_enabled: BooleanLike;
  dynamic_rules_enabled: BooleanLike;
  auto_execute: BooleanLike;
  storyteller_profile: string;
  storyteller_profiles: StoryProfile[];
  daylight_enabled: BooleanLike;
  event_pressure: number;
  dynamic_pressure: number;
  next_pulse: number;
  next_execute: number;
  daylight_sources: number;
  daylight_power: number;
  daylight_range: number;
  snapshot: Snapshot;
  candidates: Candidate[];
  active_arcs: StoryArc[];
  storyteller_curve: CurvePoint[];
  round_plan: RoundPlanPoint[];
  round_summary: RoundSummary;
  memory: StoryMemory;
  history: HistoryRecord[];
};

const ticksToSeconds = (ticks: number | undefined) =>
  `${Math.ceil((ticks || 0) / 10)}s`;

const statusColor = (status: string) => {
  if (status === 'executed' || status === 'completed') {
    return 'good';
  }
  if (status === 'blocked' || status === 'failed') {
    return 'bad';
  }
  return 'average';
};

export const CyberpunkRound = () => {
  const { act, data } = useBackend<Data>();
  const snapshot = data.snapshot || ({} as Snapshot);
  const districts = snapshot.districts || [];
  const candidates = data.candidates || [];
  const activeArcs = data.active_arcs || [];
  const roundPlan = data.round_plan || [];
  const roundSummary = data.round_summary || {};
  const memory = data.memory || ({} as StoryMemory);
  const history = (data.history || []).slice().reverse().slice(0, 24);
  const profiles = data.storyteller_profiles || [];
  const currentProfile =
    profiles.find((profile) => profile.id === data.storyteller_profile) ||
    profiles[0];
  const canAdmin = !!data.can_admin;

  return (
    <Window width={940} height={760}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Round Flow">
          <Stack align="flex-start">
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Clock">{data.clock}</LabeledList.Item>
                <LabeledList.Item label="Stage">{data.stage}</LabeledList.Item>
                <LabeledList.Item label="End state">
                  {data.end_state || 'inactive'}
                </LabeledList.Item>
                <LabeledList.Item label="Phase">{data.phase}</LabeledList.Item>
                <LabeledList.Item label="Chaos">
                  {data.chaos}/{data.expected_chaos} +/-{' '}
                  {data.chaos_tolerance || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Next pulse">
                  {ticksToSeconds(data.next_pulse)}
                </LabeledList.Item>
                <LabeledList.Item label="Next release">
                  {ticksToSeconds(data.next_execute)}
                </LabeledList.Item>
                <LabeledList.Item label="Extensions">
                  {data.extensions_used || 0}/{data.max_extensions || 0} x{' '}
                  {data.extension_days || 0} days
                </LabeledList.Item>
                <LabeledList.Item label="Profile">
                  {currentProfile?.name || data.storyteller_profile || 'unknown'}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item width="260px">
              <Button.Checkbox
                fluid
                checked={!!data.auto_execute}
                disabled={!canAdmin}
                onClick={() => act('toggle_auto_execute')}
              >
                Storyteller auto execute
              </Button.Checkbox>
              <Button.Checkbox
                fluid
                checked={!!data.random_events_enabled}
                disabled={!canAdmin}
                onClick={() => act('toggle_random_events')}
              >
                Own SSevents rolls
              </Button.Checkbox>
              <Button.Checkbox
                fluid
                checked={!!data.dynamic_rules_enabled}
                disabled={!canAdmin}
                onClick={() => act('toggle_dynamic_rules')}
              >
                Own dynamic rules
              </Button.Checkbox>
              <Button.Checkbox
                fluid
                checked={!!data.daylight_enabled}
                disabled={!canAdmin}
                onClick={() => act('toggle_daylight')}
              >
                Day phases lighting
              </Button.Checkbox>
              <Button fluid disabled={!canAdmin} onClick={() => act('pulse')}>
                Force storyteller pulse
              </Button>
            </Stack.Item>
          </Stack>
          {!!profiles.length && (
            <Box mt={1}>
              <Stack wrap>
                {profiles.map((profile) => (
                  <Stack.Item key={profile.id}>
                    <Button
                      selected={profile.id === data.storyteller_profile}
                      disabled={!canAdmin}
                      onClick={() =>
                        act('set_profile', { profile: profile.id })
                      }
                    >
                      {profile.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
              {currentProfile && (
                <Box color="label" mt={0.5}>
                  event {currentProfile.event_weight}, light{' '}
                  {currentProfile.dynamic_light_weight}, heavy{' '}
                  {currentProfile.dynamic_heavy_weight}, recovery{' '}
                  {currentProfile.recovery_weight}, gap{' '}
                  {currentProfile.gap_multiplier}, cap{' '}
                  {currentProfile.max_chaos}
                </Box>
              )}
            </Box>
          )}
        </Section>

        <Stack align="stretch">
          <Stack.Item grow>
            <Section title="City Snapshot">
              <LabeledList>
                <LabeledList.Item label="Players">
                  {snapshot.living_players || 0} living /{' '}
                  {snapshot.dead_players || 0} dead /{' '}
                  {snapshot.critical_players || 0} crit
                </LabeledList.Item>
                <LabeledList.Item label="Roles">
                  sec {snapshot.security_players || 0}, cmd{' '}
                  {snapshot.command_players || 0}, med{' '}
                  {snapshot.medical_players || 0}, eng{' '}
                  {snapshot.engineering_players || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Open critical">
                  {snapshot.open_critical_roles || 0} total, sec{' '}
                  {snapshot.open_security_roles || 0}, med{' '}
                  {snapshot.open_medical_roles || 0}, eng{' '}
                  {snapshot.open_engineering_roles || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Antags">
                  {snapshot.living_antags || 0} living /{' '}
                  {snapshot.dead_antags || 0} dead
                </LabeledList.Item>
                <LabeledList.Item label="Contracts">
                  {snapshot.accepted_contracts || 0} accepted,{' '}
                  {snapshot.completed_contracts || 0} completed,{' '}
                  {snapshot.failed_contracts || 0} failed
                </LabeledList.Item>
                <LabeledList.Item label="Businesses">
                  {snapshot.businesses || 0} total,{' '}
                  {snapshot.legal_businesses || 0} legal,{' '}
                  {snapshot.illegal_businesses || 0} illegal
                </LabeledList.Item>
                <LabeledList.Item label="Tax debt">
                  {snapshot.business_tax_debt || 0} cr debt /{' '}
                  {snapshot.business_tax_paid || 0} paid
                </LabeledList.Item>
                <LabeledList.Item label="Business ops">
                  {snapshot.business_employee_count || 0} employees,{' '}
                  {snapshot.business_warehouse_stock || 0} stock,{' '}
                  {snapshot.valid_business_premises || 0} valid premises
                </LabeledList.Item>
                <LabeledList.Item label="Corporations">
                  {snapshot.corporation_count || 0}, funds{' '}
                  {snapshot.corporation_funds || 0}, influence{' '}
                  {snapshot.corporation_influence || 0}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section title="Daylight">
              <LabeledList>
                <LabeledList.Item label="Phase">{data.phase_id}</LabeledList.Item>
                <LabeledList.Item label="Open-sky sources">
                  {data.daylight_sources || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Light">
                  range {data.daylight_range || 0}, power{' '}
                  {data.daylight_power || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Requests">
                  events {data.event_pressure || 0}, dynamic{' '}
                  {data.dynamic_pressure || 0}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>

        <Stack align="stretch">
          <Stack.Item grow>
            <Section title="Infrastructure">
              <LabeledList>
                <LabeledList.Item label="Districts">
                  {snapshot.district_count || 0} tracked,{' '}
                  {snapshot.damaged_districts || 0} pressured
                </LabeledList.Item>
                <LabeledList.Item label="Destruction">
                  {snapshot.open_space_turfs || 0} open-space turfs,{' '}
                  {snapshot.damaged_objects || 0} damaged objects
                </LabeledList.Item>
                <LabeledList.Item label="Machines">
                  {snapshot.machines_total || 0} total,{' '}
                  {snapshot.broken_machines || 0} broken,{' '}
                  {snapshot.unpowered_machines || 0} unpowered
                </LabeledList.Item>
                <LabeledList.Item label="APC">
                  {snapshot.apc_total || 0} total,{' '}
                  {snapshot.apc_offline || 0} offline,{' '}
                  {snapshot.apc_low_charge || 0} low charge
                </LabeledList.Item>
                <LabeledList.Item label="Power grid">
                  {snapshot.powernet_count || 0} nets, load{' '}
                  {snapshot.powernet_load || 0}, avail{' '}
                  {snapshot.powernet_available || 0}, deficit{' '}
                  {snapshot.powernet_deficit || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Network">
                  telecomms {snapshot.telecomms_offline || 0}/
                  {snapshot.telecomms_total || 0} offline, cyber nodes{' '}
                  {snapshot.cyber_nodes_breached || 0} breached /{' '}
                  {snapshot.cyber_nodes_weak || 0} weak /{' '}
                  {snapshot.cyber_nodes || 0} total
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section title="Area Districts">
              {!districts.length ? (
                <Box color="label">No station areas tracked.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Area</Table.Cell>
                    <Table.Cell collapsing>Pressure</Table.Cell>
                    <Table.Cell collapsing>Damage</Table.Cell>
                    <Table.Cell collapsing>Machines</Table.Cell>
                    <Table.Cell collapsing>APC</Table.Cell>
                  </Table.Row>
                  {districts.slice(0, 8).map((district) => (
                    <Table.Row key={district.id}>
                      <Table.Cell>
                        <Box bold>{district.name || district.id}</Box>
                        <Box color="label">{district.type}</Box>
                      </Table.Cell>
                      <Table.Cell collapsing>{district.pressure || 0}</Table.Cell>
                      <Table.Cell collapsing>
                        {district.open_space_turfs || 0} open,{' '}
                        {district.damaged_objects || 0} obj
                      </Table.Cell>
                      <Table.Cell collapsing>
                        {district.broken_machines || 0} broken,{' '}
                        {district.unpowered_machines || 0} off
                      </Table.Cell>
                      <Table.Cell collapsing>
                        {district.apc_offline || 0} off,{' '}
                        {district.apc_low_charge || 0} low
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </Stack.Item>
        </Stack>

        <Section title="Endround Core">
          <LabeledList>
            <LabeledList.Item label="Start report">
              {data.start_report_announced ? 'sent' : 'pending'}
            </LabeledList.Item>
            <LabeledList.Item label="Catastrophic evac">
              {data.catastrophic_evac_requested ? 'requested' : 'not requested'}
            </LabeledList.Item>
            <LabeledList.Item label="Last summary">
              {roundSummary.reason || 'none'}
            </LabeledList.Item>
            {!!roundSummary.reason && (
              <LabeledList.Item label="Summary metrics">
                day {roundSummary.day || 0}, chaos {roundSummary.chaos || 0}/
                {roundSummary.expected_chaos || 0}, players{' '}
                {roundSummary.living_players || 0} living /{' '}
                {roundSummary.dead_players || 0} dead, antags{' '}
                {roundSummary.active_antags || 0}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>

        <Section title="Story Plan">
          {!roundPlan.length ? (
            <Box color="label">No curve points.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>Time</Table.Cell>
                <Table.Cell collapsing>Chaos</Table.Cell>
                <Table.Cell collapsing>Window</Table.Cell>
                <Table.Cell>Preferred</Table.Cell>
                <Table.Cell collapsing>Force</Table.Cell>
              </Table.Row>
              {roundPlan.map((point, index) => (
                <Table.Row key={`${point.time}-${index}`}>
                  <Table.Cell collapsing>{ticksToSeconds(point.time)}</Table.Cell>
                  <Table.Cell collapsing>{point.expected_chaos}</Table.Cell>
                  <Table.Cell collapsing>+/- {point.tolerance}</Table.Cell>
                  <Table.Cell>{point.preferred_executor}</Table.Cell>
                  <Table.Cell collapsing color={point.force_chaos ? 'good' : 'label'}>
                    {point.force_chaos ? 'yes' : 'no'}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        <Stack align="stretch">
          <Stack.Item grow>
            <Section title="Active Story Arcs">
              {!activeArcs.length ? (
                <Box color="label">No active arcs.</Box>
              ) : (
                <Table>
                  <Table.Row header>
                    <Table.Cell collapsing>ID</Table.Cell>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell collapsing>Theme</Table.Cell>
                    <Table.Cell collapsing>Step</Table.Cell>
                    <Table.Cell collapsing>Heat</Table.Cell>
                  </Table.Row>
                  {activeArcs.map((arc) => (
                    <Table.Row key={arc.id}>
                      <Table.Cell collapsing>#{arc.id}</Table.Cell>
                      <Table.Cell>
                        <Box bold>{arc.name}</Box>
                        <Box color="label">
                          {arc.faction} / {arc.district} / {arc.status}
                        </Box>
                      </Table.Cell>
                      <Table.Cell collapsing>{arc.theme}</Table.Cell>
                      <Table.Cell collapsing>
                        {arc.step}/{arc.max_steps}
                      </Table.Cell>
                      <Table.Cell collapsing>{arc.heat}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Story Memory">
              <LabeledList>
                <LabeledList.Item label="Themes">
                  {(memory.themes || [])
                    .slice(0, 5)
                    .map((record) => `${record.name} ${ticksToSeconds(record.age)}`)
                    .join(', ') || 'none'}
                </LabeledList.Item>
                <LabeledList.Item label="Factions">
                  {(memory.factions || [])
                    .slice(0, 5)
                    .map((record) => `${record.name} ${ticksToSeconds(record.age)}`)
                    .join(', ') || 'none'}
                </LabeledList.Item>
                <LabeledList.Item label="Districts">
                  {(memory.districts || [])
                    .slice(0, 5)
                    .map((record) => `${record.name} ${ticksToSeconds(record.age)}`)
                    .join(', ') || 'none'}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>

        <Section title="Story Pool">
          {!candidates.length ? (
            <Box color="label">No candidates.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Executor</Table.Cell>
                <Table.Cell>Package</Table.Cell>
                <Table.Cell collapsing>Priority</Table.Cell>
                <Table.Cell collapsing>Score</Table.Cell>
                <Table.Cell collapsing>Ready</Table.Cell>
                <Table.Cell collapsing />
              </Table.Row>
              {candidates.map((candidate, index) => (
                <Table.Row key={`${candidate.name}-${index}`}>
                  <Table.Cell>
                    <Box bold>{candidate.name}</Box>
                    <Box color="label">
                      {candidate.theme || candidate.type} /{' '}
                      {candidate.faction || 'city'}
                      {candidate.arc_id
                        ? ` / arc #${candidate.arc_id}.${candidate.arc_step}`
                        : ''}
                    </Box>
                    <Box color="label">{candidate.details}</Box>
                  </Table.Cell>
                  <Table.Cell>{candidate.type}</Table.Cell>
                  <Table.Cell>{candidate.executor}</Table.Cell>
                  <Table.Cell>
                    <Box>{candidate.package_name || '-'}</Box>
                    {!!candidate.package_source && (
                      <Box color="label">
                        {candidate.package_source} / {candidate.package_kind}
                      </Box>
                    )}
                    {!!candidate.package_name && (
                      <Box color="label">
                        chaos {candidate.package_chaos || 0} /{' '}
                        {candidate.package_scale || 'n/a'} /{' '}
                        {candidate.package_duration || 'n/a'}
                      </Box>
                    )}
                  </Table.Cell>
                  <Table.Cell collapsing>{candidate.priority}</Table.Cell>
                  <Table.Cell collapsing>{candidate.score || '-'}</Table.Cell>
                  <Table.Cell collapsing color={candidate.ready ? 'good' : 'bad'}>
                    {candidate.ready ? 'yes' : 'no'}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      disabled={!canAdmin || !candidate.ready}
                      onClick={() =>
                        act('execute_candidate', { index: index + 1 })
                      }
                    >
                      Execute
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        <Section title="History">
          {!history.length ? (
            <Box color="label">No records.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>ID</Table.Cell>
                <Table.Cell collapsing>Clock</Table.Cell>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell collapsing>Type</Table.Cell>
                <Table.Cell collapsing>Package</Table.Cell>
                <Table.Cell collapsing>Chaos</Table.Cell>
                <Table.Cell collapsing>Status</Table.Cell>
              </Table.Row>
              {history.map((record) => (
                <Table.Row key={record.id}>
                  <Table.Cell collapsing>#{record.id}</Table.Cell>
                  <Table.Cell collapsing>{record.clock}</Table.Cell>
                  <Table.Cell>
                    <Box bold>{record.name}</Box>
                    <Box color="label">
                      {record.theme || record.type} / {record.faction || 'city'}
                      {record.arc_id
                        ? ` / arc #${record.arc_id}.${record.arc_step}`
                        : ''}
                      {record.score ? ` / score ${record.score}` : ''}
                    </Box>
                    <Box color="label">{record.details}</Box>
                  </Table.Cell>
                  <Table.Cell collapsing>{record.type}</Table.Cell>
                  <Table.Cell collapsing>
                    <Box>{record.package_name || '-'}</Box>
                    {!!record.package_source && (
                      <Box color="label">{record.package_source}</Box>
                    )}
                    {!!record.package_name && (
                      <Box color="label">
                        chaos {record.package_chaos || 0} /{' '}
                        {record.package_scale || 'n/a'}
                      </Box>
                    )}
                  </Table.Cell>
                  <Table.Cell collapsing>{record.chaos}</Table.Cell>
                  <Table.Cell collapsing color={statusColor(record.status)}>
                    {record.status}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
