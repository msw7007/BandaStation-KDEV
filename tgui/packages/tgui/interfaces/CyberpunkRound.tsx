// CYBERPUNK BUILD - rebuild and delete before release
import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SnapshotSummary = {
  living_players: number;
  dead_players: number;
  critical_players: number;
  living_antags: number;
  antag_group_count: number;
  antag_group_pressure: number;
  accepted_contracts: number;
  dangerous_districts: number;
  district_violence: number;
  cyber_nodes_breached: number;
};

type Snapshot = SnapshotSummary & {
  security_players: number;
  command_players: number;
  medical_players: number;
  engineering_players: number;
  open_critical_roles: number;
  open_security_roles: number;
  open_medical_roles: number;
  open_engineering_roles: number;
  active_antags: number;
  dead_antags: number;
  antag_objective_progress: number;
  antag_total_funds: number;
  antag_average_health: number;
  antag_faction_resource_pressure: number;
  created_contracts: number;
  offered_contracts: number;
  completed_contracts: number;
  failed_contracts: number;
  illegal_contracts: number;
  businesses: number;
  legal_businesses: number;
  illegal_businesses: number;
  business_tax_debt: number;
  business_tax_paid: number;
  business_employee_count: number;
  business_warehouse_stock: number;
  corporation_count: number;
  corporation_funds: number;
  corporation_influence: number;
  district_count: number;
  damaged_districts: number;
  district_damage_taken: number;
  district_critical_events: number;
  machines_total: number;
  broken_machines: number;
  unpowered_machines: number;
  damaged_objects: number;
  apc_total: number;
  apc_offline: number;
  apc_low_charge: number;
  powernet_count: number;
  powernet_available: number;
  powernet_load: number;
  powernet_deficit: number;
  telecomms_total: number;
  telecomms_offline: number;
  cyber_nodes: number;
  cyber_nodes_weak: number;
  cyber_net_data: number;
  districts: DistrictRecord[];
  antag_groups: AntagGroup[];
};

type DistrictRecord = {
  id: string;
  name: string;
  type: string;
  kind: string;
  pressure: number;
  danger: number;
  violence_score: number;
  violence_damage: number;
  critical_events: number;
  broken_machines: number;
  unpowered_machines: number;
  damaged_objects: number;
  apc_offline: number;
  apc_low_charge: number;
};

type FactionResources = {
  influence: number;
  funds: number;
  manpower: number;
  supplies: number;
  total: number;
};

type AntagGroup = {
  id: string;
  name: string;
  category: string;
  team: BooleanLike;
  members: number;
  living: number;
  dead: number;
  funds: number;
  objective_progress: number;
  average_health: number;
  threat: number;
  faction_resource_total: number;
  faction_resources?: FactionResources;
};

type ConditionRecord = {
  id: string;
  description: string;
  failure_reason: string;
  required_value: number;
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
  package_conditions?: ConditionRecord[];
  priority: number;
  score: number;
  arc_id?: number;
  arc_step?: number;
  details: string;
  ready: BooleanLike;
};

type PackageRecord = {
  id: string;
  name: string;
  kind: string;
  source: string;
  executor: string;
  event_name?: string;
  ruleset_path?: string;
  weight: number;
  tags: string[];
  chaos: number;
  min_time: number;
  max_time?: number;
  scale: string;
  duration: string;
  cooldown: number;
  conditions: ConditionRecord[];
  ready: BooleanLike;
  reason: string;
  queued: BooleanLike;
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
};

type RoundPlanPoint = {
  time: number;
  expected_chaos: number;
  tolerance: number;
  force_chaos: BooleanLike;
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
  active_antags?: number;
  antag_group_count?: number;
  completed_contracts?: number;
  failed_contracts?: number;
};

type HistoryRecord = {
  id: number;
  clock: string;
  name: string;
  type: string;
  theme: string;
  faction: string;
  district: string;
  package_name?: string;
  package_source?: string;
  package_chaos?: number;
  arc_id?: number;
  arc_step?: number;
  score?: number;
  chaos: number;
  status: string;
  details: string;
};

type Data = {
  can_admin: BooleanLike;
  payload_tab: string;
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
  fast_day_enabled: BooleanLike;
  fast_phase_duration: number;
  real_day_duration: number;
  event_pressure: number;
  dynamic_pressure: number;
  next_pulse: number;
  next_execute: number;
  daylight_sources: number;
  daylight_power: number;
  daylight_range: number;
  daylight_color: string;
  snapshot_summary: SnapshotSummary;
  snapshot?: Snapshot;
  candidates?: Candidate[];
  packages?: PackageRecord[];
  active_arcs?: StoryArc[];
  round_plan?: RoundPlanPoint[];
  round_summary: RoundSummary;
  memory?: StoryMemory;
  history?: HistoryRecord[];
};

const ticksToSeconds = (ticks: number | undefined) =>
  `${Math.ceil((ticks || 0) / 10)}s`;

const statusColor = (status: string) => {
  if (status === 'executed' || status === 'completed' || status === 'ready') {
    return 'good';
  }
  if (status === 'blocked' || status === 'failed') {
    return 'bad';
  }
  return 'average';
};

const packageBackend = (pack: PackageRecord) =>
  pack.kind === 'event' ? pack.event_name || 'event' : pack.ruleset_path || 'ruleset';

export const CyberpunkRound = () => {
  const { act, data } = useBackend<Data>();
  const canAdmin = !!data.can_admin;
  const tab = data.payload_tab || 'snapshot';
  const summary = data.snapshot_summary || ({} as SnapshotSummary);
  const snapshot = data.snapshot || ({} as Snapshot);
  const profiles = data.storyteller_profiles || [];
  const currentProfile =
    profiles.find((profile) => profile.id === data.storyteller_profile) ||
    profiles[0];

  const setTab = (nextTab: string) => act('set_payload_tab', { tab: nextTab });

  return (
    <Window width={980} height={760}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Round Flow">
          <Stack align="flex-start">
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Clock">{data.clock}</LabeledList.Item>
                <LabeledList.Item label="Stage">{data.stage}</LabeledList.Item>
                <LabeledList.Item label="Phase">{data.phase}</LabeledList.Item>
                <LabeledList.Item label="Chaos">
                  {data.chaos}/{data.expected_chaos} +/- {data.chaos_tolerance}
                </LabeledList.Item>
                <LabeledList.Item label="Population">
                  {summary.living_players || 0} living / {summary.dead_players || 0}{' '}
                  dead / {summary.critical_players || 0} crit
                </LabeledList.Item>
                <LabeledList.Item label="Pressure">
                  antags {summary.living_antags || 0}, groups{' '}
                  {summary.antag_group_count || 0}, contracts{' '}
                  {summary.accepted_contracts || 0}, districts{' '}
                  {summary.dangerous_districts || 0}, net breaches{' '}
                  {summary.cyber_nodes_breached || 0}
                </LabeledList.Item>
                <LabeledList.Item label="Timing">
                  pulse {ticksToSeconds(data.next_pulse)}, release{' '}
                  {ticksToSeconds(data.next_execute)}
                </LabeledList.Item>
                <LabeledList.Item label="Profile">
                  {currentProfile?.name || data.storyteller_profile || 'unknown'}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item width="270px">
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
                Event backend enabled
              </Button.Checkbox>
              <Button.Checkbox
                fluid
                checked={!!data.dynamic_rules_enabled}
                disabled={!canAdmin}
                onClick={() => act('toggle_dynamic_rules')}
              >
                Dynamic backend enabled
              </Button.Checkbox>
              <Button.Checkbox
                fluid
                checked={!!data.fast_day_enabled}
                disabled={!canAdmin}
                onClick={() => act('toggle_fast_day')}
              >
                Fast day test mode
              </Button.Checkbox>
              <Button fluid disabled={!canAdmin} onClick={() => act('pulse')}>
                Force storyteller pulse
              </Button>
            </Stack.Item>
          </Stack>
          {!!profiles.length && (
            <Stack mt={1} wrap>
              {profiles.map((profile) => (
                <Stack.Item key={profile.id}>
                  <Button
                    selected={profile.id === data.storyteller_profile}
                    disabled={!canAdmin}
                    onClick={() => act('set_profile', { profile: profile.id })}
                  >
                    {profile.name}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        <Tabs>
          <Tabs.Tab selected={tab === 'snapshot'} onClick={() => setTab('snapshot')}>
            Snapshot
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'story'} onClick={() => setTab('story')}>
            Story
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'payloads'} onClick={() => setTab('payloads')}>
            Payloads
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 'history'} onClick={() => setTab('history')}>
            History
          </Tabs.Tab>
        </Tabs>

        {tab === 'snapshot' && <SnapshotTab snapshot={snapshot} data={data} />}
        {tab === 'story' && (
          <StoryTab
            act={act}
            canAdmin={canAdmin}
            candidates={data.candidates || []}
            activeArcs={data.active_arcs || []}
            roundPlan={data.round_plan || []}
            memory={data.memory || ({} as StoryMemory)}
          />
        )}
        {tab === 'payloads' && (
          <PayloadTab
            act={act}
            canAdmin={canAdmin}
            packages={data.packages || []}
          />
        )}
        {tab === 'history' && (
          <HistoryTab
            history={(data.history || []).slice().reverse()}
            summary={data.round_summary || {}}
          />
        )}
      </Window.Content>
    </Window>
  );
};

const SnapshotTab = ({ snapshot, data }: { snapshot: Snapshot; data: Data }) => {
  const districts = snapshot.districts || [];
  const antagGroups = snapshot.antag_groups || [];
  return (
    <>
      <Stack align="stretch">
        <Stack.Item grow>
          <Section title="City Snapshot">
            <LabeledList>
              <LabeledList.Item label="Players">
                {snapshot.living_players || 0} living / {snapshot.dead_players || 0}{' '}
                dead / {snapshot.critical_players || 0} crit
              </LabeledList.Item>
              <LabeledList.Item label="Roles">
                sec {snapshot.security_players || 0}, cmd{' '}
                {snapshot.command_players || 0}, med {snapshot.medical_players || 0},
                eng {snapshot.engineering_players || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Open roles">
                {snapshot.open_critical_roles || 0} critical, sec{' '}
                {snapshot.open_security_roles || 0}, med{' '}
                {snapshot.open_medical_roles || 0}, eng{' '}
                {snapshot.open_engineering_roles || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Antags">
                {snapshot.living_antags || 0} living / {snapshot.dead_antags || 0}{' '}
                dead, objective {snapshot.antag_objective_progress || 0}%, funds{' '}
                {snapshot.antag_total_funds || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Faction resources">
                pressure {snapshot.antag_faction_resource_pressure || 0}, groups{' '}
                {snapshot.antag_group_count || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Contracts">
                {snapshot.accepted_contracts || 0} accepted,{' '}
                {snapshot.completed_contracts || 0} done,{' '}
                {snapshot.failed_contracts || 0} failed,{' '}
                {snapshot.illegal_contracts || 0} illegal
              </LabeledList.Item>
              <LabeledList.Item label="Business">
                {snapshot.businesses || 0} total, debt{' '}
                {snapshot.business_tax_debt || 0}, stock{' '}
                {snapshot.business_warehouse_stock || 0}
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
          <Section title="Infrastructure">
            <LabeledList>
              <LabeledList.Item label="Districts">
                {snapshot.district_count || 0} tracked,{' '}
                {snapshot.damaged_districts || 0} pressured,{' '}
                {snapshot.dangerous_districts || 0} dangerous
              </LabeledList.Item>
              <LabeledList.Item label="Violence">
                score {snapshot.district_violence || 0}, severe{' '}
                {snapshot.district_critical_events || 0}, damage{' '}
                {snapshot.district_damage_taken || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Machines">
                {snapshot.machines_total || 0} total,{' '}
                {snapshot.broken_machines || 0} broken,{' '}
                {snapshot.unpowered_machines || 0} unpowered
              </LabeledList.Item>
              <LabeledList.Item label="APC">
                {snapshot.apc_offline || 0}/{snapshot.apc_total || 0} offline,{' '}
                {snapshot.apc_low_charge || 0} low
              </LabeledList.Item>
              <LabeledList.Item label="Power">
                nets {snapshot.powernet_count || 0}, load{' '}
                {snapshot.powernet_load || 0}, avail{' '}
                {snapshot.powernet_available || 0}, deficit{' '}
                {snapshot.powernet_deficit || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Network">
                telecomms {snapshot.telecomms_offline || 0}/
                {snapshot.telecomms_total || 0} offline, cyber{' '}
                {snapshot.cyber_nodes_breached || 0} breached /{' '}
                {snapshot.cyber_nodes_weak || 0} weak /{' '}
                {snapshot.cyber_nodes || 0} total
              </LabeledList.Item>
              <LabeledList.Item label="Daylight">
                sources {data.daylight_sources || 0}, range{' '}
                {data.daylight_range || 0}, power {data.daylight_power || 0},{' '}
                color {data.daylight_color || '-'}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>
      </Stack>

      <Section title="Antagonist Groups">
        {!antagGroups.length ? (
          <Box color="label">No tracked groups.</Box>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Group</Table.Cell>
              <Table.Cell collapsing>Members</Table.Cell>
              <Table.Cell collapsing>Objectives</Table.Cell>
              <Table.Cell collapsing>Health</Table.Cell>
              <Table.Cell collapsing>Resources</Table.Cell>
              <Table.Cell collapsing>Threat</Table.Cell>
            </Table.Row>
            {antagGroups.map((group) => (
              <Table.Row key={group.id}>
                <Table.Cell>
                  <Box bold>{group.name}</Box>
                  <Box color="label">{group.team ? 'team' : group.category}</Box>
                </Table.Cell>
                <Table.Cell collapsing>
                  {group.living}/{group.members} live
                </Table.Cell>
                <Table.Cell collapsing>{group.objective_progress || 0}%</Table.Cell>
                <Table.Cell collapsing>{group.average_health || 0}%</Table.Cell>
                <Table.Cell collapsing>
                  {group.faction_resource_total || 0}
                </Table.Cell>
                <Table.Cell collapsing>{group.threat || 0}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </Section>

      <Section title="Districts">
        {!districts.length ? (
          <Box color="label">No district payload loaded.</Box>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Area</Table.Cell>
              <Table.Cell collapsing>Pressure</Table.Cell>
              <Table.Cell collapsing>Danger</Table.Cell>
              <Table.Cell collapsing>Violence</Table.Cell>
              <Table.Cell collapsing>Machines</Table.Cell>
              <Table.Cell collapsing>APC</Table.Cell>
            </Table.Row>
            {districts.slice(0, 12).map((district) => (
              <Table.Row key={district.id}>
                <Table.Cell>
                  <Box bold>{district.name || district.id}</Box>
                  <Box color="label">
                    {district.kind || 'area'} / {district.type}
                  </Box>
                </Table.Cell>
                <Table.Cell collapsing>{district.pressure || 0}</Table.Cell>
                <Table.Cell collapsing>{district.danger || 0}</Table.Cell>
                <Table.Cell collapsing>
                  {district.violence_score || 0} / severe{' '}
                  {district.critical_events || 0}
                </Table.Cell>
                <Table.Cell collapsing>
                  {district.broken_machines || 0} broken,{' '}
                  {district.unpowered_machines || 0} off
                </Table.Cell>
                <Table.Cell collapsing>
                  {district.apc_offline || 0} off, {district.apc_low_charge || 0}{' '}
                  low
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </Section>
    </>
  );
};

const StoryTab = ({
  act,
  canAdmin,
  candidates,
  activeArcs,
  roundPlan,
  memory,
}: {
  act: (action: string, params?: Record<string, unknown>) => void;
  canAdmin: boolean;
  candidates: Candidate[];
  activeArcs: StoryArc[];
  roundPlan: RoundPlanPoint[];
  memory: StoryMemory;
}) => (
  <>
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
        <Section title="Active Arcs">
          {!activeArcs.length ? (
            <Box color="label">No active arcs.</Box>
          ) : (
            <Table>
              {activeArcs.map((arc) => (
                <Table.Row key={arc.id}>
                  <Table.Cell>
                    <Box bold>#{arc.id} {arc.name}</Box>
                    <Box color="label">
                      {arc.theme} / {arc.faction} / {arc.district}
                    </Box>
                  </Table.Cell>
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
        <Section title="Memory">
          <LabeledList>
            <LabeledList.Item label="Themes">
              {(memory.themes || []).map((r) => `${r.name} ${ticksToSeconds(r.age)}`).join(', ') || 'none'}
            </LabeledList.Item>
            <LabeledList.Item label="Factions">
              {(memory.factions || []).map((r) => `${r.name} ${ticksToSeconds(r.age)}`).join(', ') || 'none'}
            </LabeledList.Item>
            <LabeledList.Item label="Districts">
              {(memory.districts || []).map((r) => `${r.name} ${ticksToSeconds(r.age)}`).join(', ') || 'none'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
    </Stack>

    <Section title="Current Candidate Pool">
      {!candidates.length ? (
        <Box color="label">No candidates. Force a pulse or defer a payload.</Box>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Candidate</Table.Cell>
            <Table.Cell collapsing>Package</Table.Cell>
            <Table.Cell collapsing>Score</Table.Cell>
            <Table.Cell collapsing>Ready</Table.Cell>
            <Table.Cell collapsing />
          </Table.Row>
          {candidates.map((candidate, index) => (
            <Table.Row key={`${candidate.name}-${index}`}>
              <Table.Cell>
                <Box bold>{candidate.name}</Box>
                <Box color="label">
                  {candidate.type} / {candidate.executor} / {candidate.theme} /{' '}
                  {candidate.faction}
                </Box>
                <Box color="label">{candidate.details}</Box>
              </Table.Cell>
              <Table.Cell collapsing>
                <Box>{candidate.package_name || '-'}</Box>
                {!!candidate.package_name && (
                  <Box color="label">
                    {candidate.package_source} / chaos{' '}
                    {candidate.package_chaos || 0}
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell collapsing>
                {candidate.score || candidate.priority || 0}
              </Table.Cell>
              <Table.Cell collapsing color={candidate.ready ? 'good' : 'bad'}>
                {candidate.ready ? 'yes' : 'no'}
              </Table.Cell>
              <Table.Cell collapsing>
                <Button
                  disabled={!canAdmin || !candidate.ready}
                  onClick={() => act('execute_candidate', { index: index + 1 })}
                >
                  Now
                </Button>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  </>
);

const PayloadTab = ({
  act,
  canAdmin,
  packages,
}: {
  act: (action: string, params?: Record<string, unknown>) => void;
  canAdmin: boolean;
  packages: PackageRecord[];
}) => (
  <Section title="Event And Ruleset Payloads">
    {!packages.length ? (
      <Box color="label">No payloads loaded.</Box>
    ) : (
      <Table>
        <Table.Row header>
          <Table.Cell>Payload</Table.Cell>
          <Table.Cell collapsing>Backend</Table.Cell>
          <Table.Cell collapsing>Window</Table.Cell>
          <Table.Cell>Activation</Table.Cell>
          <Table.Cell collapsing />
          <Table.Cell collapsing />
        </Table.Row>
        {packages.map((pack) => (
          <Table.Row key={pack.id}>
            <Table.Cell>
              <Box bold>{pack.name}</Box>
              <Box color="label">
                {pack.id} / {pack.tags?.join(', ') || 'no tags'}
              </Box>
              <Box color="label">
                chaos {pack.chaos || 0}, weight {pack.weight || 0},{' '}
                {pack.scale || 'city'} / {pack.duration || 'instant'}
              </Box>
              {!!pack.conditions?.length && (
                <Box color="label">
                  conditions:{' '}
                  {pack.conditions
                    .map((condition) => condition.id || condition.description)
                    .join(', ')}
                </Box>
              )}
            </Table.Cell>
            <Table.Cell collapsing>
              <Box>{pack.source}</Box>
              <Box color="label">{packageBackend(pack)}</Box>
            </Table.Cell>
            <Table.Cell collapsing>
              <Box>min {ticksToSeconds(pack.min_time)}</Box>
              <Box color="label">
                max {pack.max_time ? ticksToSeconds(pack.max_time) : '-'}
              </Box>
              <Box color="label">cd {ticksToSeconds(pack.cooldown)}</Box>
            </Table.Cell>
            <Table.Cell>
              <Box color={pack.ready ? 'good' : 'bad'}>
                {pack.ready ? 'available now' : 'blocked'}
              </Box>
              <Box color="label">{pack.reason || '-'}</Box>
              {!!pack.queued && <Box color="average">deferred for pulse</Box>}
            </Table.Cell>
            <Table.Cell collapsing>
              <Button
                disabled={!canAdmin}
                selected={!!pack.queued}
                onClick={() => act('defer_package', { package_id: pack.id })}
              >
                Defer
              </Button>
            </Table.Cell>
            <Table.Cell collapsing>
              <Button
                color="red"
                disabled={!canAdmin || !pack.ready}
                onClick={() => act('execute_package', { package_id: pack.id })}
              >
                Now
              </Button>
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    )}
  </Section>
);

const HistoryTab = ({
  history,
  summary,
}: {
  history: HistoryRecord[];
  summary: RoundSummary;
}) => (
  <>
    <Section title="Endround Summary">
      <LabeledList>
        <LabeledList.Item label="Last summary">
          {summary.reason || 'none'}
        </LabeledList.Item>
        {!!summary.reason && (
          <LabeledList.Item label="Metrics">
            day {summary.day || 0}, chaos {summary.chaos || 0}/
            {summary.expected_chaos || 0}, players{' '}
            {summary.living_players || 0} living / {summary.dead_players || 0}{' '}
            dead, antags {summary.active_antags || 0}, groups{' '}
            {summary.antag_group_count || 0}, contracts{' '}
            {summary.completed_contracts || 0}/{summary.failed_contracts || 0}
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
    <Section title="History">
      {!history.length ? (
        <Box color="label">No records.</Box>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell collapsing>ID</Table.Cell>
            <Table.Cell collapsing>Clock</Table.Cell>
            <Table.Cell>Record</Table.Cell>
            <Table.Cell collapsing>Package</Table.Cell>
            <Table.Cell collapsing>Status</Table.Cell>
          </Table.Row>
          {history.slice(0, 48).map((record) => (
            <Table.Row key={record.id}>
              <Table.Cell collapsing>#{record.id}</Table.Cell>
              <Table.Cell collapsing>{record.clock}</Table.Cell>
              <Table.Cell>
                <Box bold>{record.name}</Box>
                <Box color="label">
                  {record.type} / {record.theme} / {record.faction} /{' '}
                  {record.district}
                  {record.arc_id
                    ? ` / arc #${record.arc_id}.${record.arc_step}`
                    : ''}
                  {record.score ? ` / score ${record.score}` : ''}
                </Box>
                <Box color="label">{record.details}</Box>
              </Table.Cell>
              <Table.Cell collapsing>
                <Box>{record.package_name || '-'}</Box>
                {!!record.package_source && (
                  <Box color="label">{record.package_source}</Box>
                )}
              </Table.Cell>
              <Table.Cell collapsing color={statusColor(record.status)}>
                {record.status}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  </>
);
