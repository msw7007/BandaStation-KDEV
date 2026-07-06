import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  name: string;
  kind: string;
  active: BooleanLike;
  anchored: BooleanLike;
  connected: BooleanLike;
  can_generate: BooleanLike;
  output: string;
  base_output: string;
  power_output: number;
  heat: number;
  heat_ratio: number;
  safe_heat: number;
  critical_heat: number;
  wear: number;
  wear_ratio: number;
  max_wear: number;
  integrity: number;
  max_integrity: number;
  integrity_ratio: number;
  corp: string;
  technology: string | null;
  special: SpecialData;
};

type RodData = {
  index: number;
  integrity: number;
  integrity_ratio: number;
  rating: number;
  depth: number;
};

type SpecialData = {
  kind?: string;
  authorized?: BooleanLike;
  authorized_by?: string | null;
  credits_per_tick?: number;
  corporation?: string;
  corporation_id?: string;
  provider?: string;
  provider_id?: string;
  reserve_kj?: number;
  reserve_limit_kj?: number;
  customer_account_id?: string | null;
  estimated_price?: number;
  input_level?: string;
  wheels?: number;
  max_wheels?: number;
  shaft_rating?: number;
  motor_rating?: number;
  rotation?: number;
  rotation_ratio?: number;
  max_rotation?: number;
  hot_units?: number;
  cold_units?: number;
  max_units?: number;
  hot_ratio?: number;
  cold_ratio?: number;
  hot_temperature?: number;
  cold_temperature?: number;
  delta?: number;
  fuel?: number;
  max_fuel?: number;
  fuel_ratio?: number;
  reaction_rate?: number;
  meltdown_started?: BooleanLike;
  rods?: RodData[];
  instability?: number;
  instability_ratio?: number;
  biomass?: number;
  max_biomass?: number;
  biomass_ratio?: number;
  portal_size?: number;
  portal_ratio?: number;
  containment?: number;
  containment_ratio?: number;
};

type ActFn = (action: string, params?: Record<string, unknown>) => void;

const corpOptions = [
  ['benn', 'Benn'],
  ['ryaznov', 'Ryaznov'],
  ['starlight', 'Starlight'],
  ['government', 'Government'],
];

const barRanges = {
  good: [-Infinity, 0.5],
  average: [0.5, 0.8],
  bad: [0.8, Infinity],
};

const inverseBarRanges = {
  bad: [-Infinity, 0.25],
  average: [0.25, 0.55],
  good: [0.55, Infinity],
};

export const CyberpunkPowerSource = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    active,
    anchored,
    connected,
    can_generate,
    output,
    base_output,
    power_output,
    heat,
    heat_ratio,
    safe_heat,
    critical_heat,
    wear,
    wear_ratio,
    max_wear,
    integrity,
    max_integrity,
    integrity_ratio,
    corp,
    technology,
    special = {},
  } = data;

  return (
    <Window width={760} height={560}>
      <Window.Content scrollable>
        {!anchored && <NoticeBox warning>Machine is not anchored.</NoticeBox>}
        {!connected && <NoticeBox danger>No powernet connection.</NoticeBox>}
        <Stack>
          <Stack.Item width="46%">
            <Section
              title="Power"
              buttons={
                <Button
                  icon={active ? 'power-off' : 'power-off'}
                  selected={active}
                  disabled={!anchored}
                  onClick={() => act('toggle')}
                >
                  {active ? 'Online' : 'Offline'}
                </Button>
              }
            >
              <LabeledList>
                <LabeledList.Item label="State">
                  <Box color={can_generate ? 'good' : 'bad'}>
                    {can_generate ? 'ready' : 'blocked'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Current output">
                  {output}
                </LabeledList.Item>
                <LabeledList.Item label="Base output">
                  {base_output}
                </LabeledList.Item>
                <LabeledList.Item label="Output ratio">
                  <Button icon="minus" onClick={() => act('adjust_output', { delta: -0.25 })} />
                  <NumberInput
                    animated
                    value={power_output}
                    minValue={0.25}
                    maxValue={4}
                    step={0.25}
                    width="58px"
                    onChange={(value) => act('set_output', { value })}
                  />
                  <Button icon="plus" onClick={() => act('adjust_output', { delta: 0.25 })} />
                </LabeledList.Item>
                <LabeledList.Item label="Manufacturer">{corp}</LabeledList.Item>
                <LabeledList.Item label="Technology">
                  {technology || 'basic'}
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section title="Condition">
              <LabeledList>
                <LabeledList.Item label={`Heat (${heat} C)`}>
                  <ProgressBar value={heat_ratio} ranges={barRanges} />
                  <Box color="label" mt={0.5}>
                    safe {safe_heat} C / critical {critical_heat} C
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label={`Wear (${wear}/${max_wear})`}>
                  <ProgressBar value={wear_ratio} ranges={barRanges} />
                </LabeledList.Item>
                <LabeledList.Item label={`Integrity (${integrity}/${max_integrity})`}>
                  <ProgressBar value={integrity_ratio} ranges={inverseBarRanges} />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <SpecialPanel special={special} act={act} />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SpecialPanel = ({
  special,
  act,
}: {
  special: SpecialData;
  act: ActFn;
}) => {
  switch (special.kind) {
    case 'government_import':
      return (
        <Section title="Government Import">
          <LabeledList>
            <LabeledList.Item label="Authorization">
              {special.authorized ? special.authorized_by || 'authorized' : 'missing'}
            </LabeledList.Item>
            <LabeledList.Item label="Billing">
              {special.credits_per_tick} cr/tick
            </LabeledList.Item>
          </LabeledList>
          <Button icon="id-card" color="bad" onClick={() => act('clear_auth')}>
            Clear Authorization
          </Button>
        </Section>
      );
    case 'corporate_uplink':
      return (
        <Section title="Corporate Uplink">
          <CorporationSelector
            selected={special.corporation_id}
            action="set_corporation"
            act={act}
          />
          <LabeledList>
            <LabeledList.Item label="Reserve">
              {special.reserve_kj}/{special.reserve_limit_kj} kJ
            </LabeledList.Item>
            <LabeledList.Item label="Input">
              <Button icon="minus" onClick={() => act('adjust_input', { delta: -5000 })} />
              {special.input_level}
              <Button icon="plus" onClick={() => act('adjust_input', { delta: 5000 })} />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      );
    case 'corporate_collector':
      return (
        <Section title="Corporate Collector">
          <CorporationSelector
            selected={special.provider_id}
            action="set_provider"
            act={act}
          />
          <LabeledList>
            <LabeledList.Item label="Reserve">
              {special.reserve_kj}/{special.reserve_limit_kj} kJ
            </LabeledList.Item>
            <LabeledList.Item label="Customer">
              {special.customer_account_id || 'not linked'}
            </LabeledList.Item>
            <LabeledList.Item label="Estimated tick price">
              {special.estimated_price || 0} cr
            </LabeledList.Item>
          </LabeledList>
          <Button icon="unlink" color="bad" onClick={() => act('clear_account')}>
            Clear Account
          </Button>
        </Section>
      );
    case 'kinetic':
      return (
        <Section title="Kinetic Train">
          <LabeledList>
            <LabeledList.Item label="Wheels">
              {special.wheels}/{special.max_wheels}
            </LabeledList.Item>
            <LabeledList.Item label="Shaft">{special.shaft_rating}</LabeledList.Item>
            <LabeledList.Item label="Motor">{special.motor_rating}</LabeledList.Item>
            <LabeledList.Item label={`Rotation (${special.rotation}/${special.max_rotation})`}>
              <ProgressBar value={special.rotation_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
          </LabeledList>
          <Button icon="rotate-right" onClick={() => act('spin_up')}>
            Manual Spin-up
          </Button>
        </Section>
      );
    case 'chemical_teg':
      return (
        <Section title="Chemical TEG">
          <LabeledList>
            <LabeledList.Item label={`Hot feed (${special.hot_units}/${special.max_units})`}>
              <ProgressBar value={special.hot_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
            <LabeledList.Item label={`Cold feed (${special.cold_units}/${special.max_units})`}>
              <ProgressBar value={special.cold_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
            <LabeledList.Item label="Temperature">
              {special.hot_temperature} C / {special.cold_temperature} C
            </LabeledList.Item>
            <LabeledList.Item label="Delta">{special.delta} K</LabeledList.Item>
          </LabeledList>
          <Button icon="trash" onClick={() => act('purge_hot')}>
            Purge Hot
          </Button>
          <Button icon="trash" onClick={() => act('purge_cold')}>
            Purge Cold
          </Button>
          <Button icon="biohazard" color="bad" onClick={() => act('purge_all')}>
            Purge All
          </Button>
        </Section>
      );
    case 'gasoline':
      return (
        <Section title="Gasoline Generator">
          <LabeledList>
            <LabeledList.Item label={`Fuel (${special.fuel}/${special.max_fuel})`}>
              <ProgressBar value={special.fuel_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
          </LabeledList>
          <Button icon="trash" color="bad" onClick={() => act('purge_fuel')}>
            Purge Fuel
          </Button>
        </Section>
      );
    case 'nuclear':
      return (
        <Section title="Nuclear Block">
          <LabeledList>
            <LabeledList.Item label={`Fuel (${special.fuel}/${special.max_fuel})`}>
              <ProgressBar value={special.fuel_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
            <LabeledList.Item label="Reaction rate">
              <Button icon="minus" onClick={() => act('adjust_reaction_rate', { delta: -0.25 })} />
              <NumberInput
                animated
                value={special.reaction_rate || 1}
                minValue={0.25}
                maxValue={3}
                step={0.25}
                width="58px"
                onChange={(value) => act('set_reaction_rate', { value })}
              />
              <Button icon="plus" onClick={() => act('adjust_reaction_rate', { delta: 0.25 })} />
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            {(special.rods || []).map((rod) => (
              <Box key={rod.index} mb={1}>
                <Box bold>
                  Rod #{rod.index} x{rod.rating} depth {rod.depth}
                </Box>
                <ProgressBar value={rod.integrity_ratio} ranges={inverseBarRanges} />
                <Button mt={0.5} onClick={() => act('set_rod_depth', { slot: rod.index, depth: 0 })}>
                  0
                </Button>
                <Button mt={0.5} onClick={() => act('set_rod_depth', { slot: rod.index, depth: 1 })}>
                  1
                </Button>
                <Button mt={0.5} onClick={() => act('set_rod_depth', { slot: rod.index, depth: 2 })}>
                  2
                </Button>
                <Button mt={0.5} onClick={() => act('set_rod_depth', { slot: rod.index, depth: 3 })}>
                  3
                </Button>
              </Box>
            ))}
          </Box>
          <Button icon="warning" color="bad" onClick={() => act('scram')}>
            SCRAM
          </Button>
        </Section>
      );
    case 'cold_fusion':
      return (
        <Section title="Cold Fusion">
          <LabeledList>
            <LabeledList.Item label={`Instability (${special.instability})`}>
              <ProgressBar value={special.instability_ratio || 0} ranges={barRanges} />
            </LabeledList.Item>
          </LabeledList>
          <Button icon="snowflake" onClick={() => act('stabilize')}>
            Stabilize
          </Button>
        </Section>
      );
    case 'bioreactor':
      return (
        <Section title="Bioreactor">
          <LabeledList>
            <LabeledList.Item label={`Biomass (${special.biomass}/${special.max_biomass})`}>
              <ProgressBar value={special.biomass_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
          </LabeledList>
          <Button icon="trash" color="bad" onClick={() => act('purge_biomass')}>
            Purge Biomass
          </Button>
        </Section>
      );
    case 'energy_portal':
      return (
        <Section title="Energy Portal">
          <LabeledList>
            <LabeledList.Item label={`Portal size (${special.portal_size})`}>
              <ProgressBar value={special.portal_ratio || 0} ranges={barRanges} />
            </LabeledList.Item>
            <LabeledList.Item label={`Containment (${special.containment})`}>
              <ProgressBar value={special.containment_ratio || 0} ranges={inverseBarRanges} />
            </LabeledList.Item>
          </LabeledList>
          <Button icon="compress" onClick={() => act('tighten_containment')}>
            Tighten Containment
          </Button>
        </Section>
      );
    default:
      return <Section title="Reactor">No dedicated controls.</Section>;
  }
};

const CorporationSelector = ({
  selected,
  action,
  act,
}: {
  selected?: string;
  action: 'set_provider' | 'set_corporation';
  act: ActFn;
}) => (
  <Box mb={1}>
    {corpOptions.map(([id, label]) => (
      <Button
        key={id}
        selected={selected === id}
        onClick={() => act(action, { [action === 'set_provider' ? 'provider' : 'corporation']: id })}
      >
        {label}
      </Button>
    ))}
  </Box>
);
