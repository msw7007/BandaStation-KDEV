import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Slider,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Turbine = {
  name: string;
  tier: number;
  rpm: number;
  target: number;
  condition: number;
  capacity: number;
  generation: number;
  consumption: number;
  powered: boolean;
  manual: boolean;
};

type Data = {
  nominalRate: number;
  maxRpm: number;
  ventTemperature: number;
  baseFlow: number;
  powered: boolean;
  panel: boolean;
  rate: number;
  targetRate: number;
  chain: boolean;
  rods: number;
  fuel: number;
  emitters: number;
  temperature: number;
  targetTemperature: number;
  gross: number;
  consumption: number;
  net: number;
  heat: number;
  cooling: number;
  coolant: number;
  capacity: number;
  efficiency: number;
  flow: number;
  fuelMultiplier: number;
  wearMultiplier: number;
  ambientTemperature: number;
  pressure: number;
  circulation: number;
  turbines: Turbine[];
  beakers: {
    index: number;
    installed: boolean;
    name: string | null;
    capacity: number;
    volume: number;
    temperature: number | null;
    contents: string;
  }[];
};

const fixed = (value: number, places = 0) => value.toFixed(places);
const power = (watts: number) => `${fixed(watts / 1000, 1)} kW`;

export function NuclearPowerBlock() {
  const { act, data } = useBackend<Data>();
  return (
    <Window width={660} height={750}>
      <Window.Content scrollable>
        {!data.powered && <NoticeBox>Control power unavailable</NoticeBox>}
        {data.rate > data.nominalRate && (
          <NoticeBox>Elevated reaction</NoticeBox>
        )}
        {data.temperature >= data.ventTemperature * 0.8 && (
          <NoticeBox danger>Core overheating</NoticeBox>
        )}
        {(data.coolant <= 0 || data.coolant < data.capacity * 0.2) && (
          <NoticeBox>Low coolant</NoticeBox>
        )}
        {data.flow > data.baseFlow + 0.01 && (
          <NoticeBox>High coolant consumption</NoticeBox>
        )}
        {data.circulation < 0.5 && (
          <NoticeBox>Low circulation pressure</NoticeBox>
        )}
        <Section title="Core">
          <Stack>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Reaction / target">
                  {fixed(data.rate, 1)} / {fixed(data.targetRate, 1)}
                  <Box inline ml={1} color={data.chain ? 'orange' : 'label'}>
                    {data.chain ? 'Chain reaction' : 'Subcritical'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Fuel">
                  <ProgressBar value={data.fuel}>
                    {fixed(data.fuel * 100, 1)}%
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Impacting emitters">
                  {data.emitters}
                </LabeledList.Item>
                <LabeledList.Item label="Rod insertion">
                  <Slider
                    value={data.rods}
                    minValue={0}
                    maxValue={100}
                    step={1}
                    unit="%"
                    disabled={!data.powered}
                    onChange={(_, value) => act('rods', { value })}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Chamber">
                  <ProgressBar
                    value={Math.min(1, data.temperature / data.ventTemperature)}
                    color={
                      data.temperature >= data.ventTemperature * 0.8
                        ? 'bad'
                        : 'average'
                    }
                  >
                    {fixed(data.temperature)} K
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Thermal target">
                  <ProgressBar
                    value={Math.min(
                      1,
                      data.targetTemperature / data.ventTemperature,
                    )}
                    color={
                      data.targetTemperature >= data.ventTemperature * 0.8
                        ? 'bad'
                        : 'average'
                    }
                  >
                    {fixed(data.targetTemperature)} K
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Heating / cooling">
                  {fixed(data.heat, 1)} / {fixed(data.cooling, 1)} K/s
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Electrical output">
          <Stack justify="space-between">
            <Stack.Item>Gross: {power(data.gross)}</Stack.Item>
            <Stack.Item>Internal: {power(data.consumption)}</Stack.Item>
            <Stack.Item>Net: {power(data.net)}</Stack.Item>
          </Stack>
        </Section>
        <Section title="Turbines">
          <Table>
            <Table.Row header>
              <Table.Cell>Turbine</Table.Cell>
              <Table.Cell>RPM / target</Table.Cell>
              <Table.Cell>Condition</Table.Cell>
              <Table.Cell>Output / available</Table.Cell>
            </Table.Row>
            {data.turbines.map((turbine, index) => (
              <Table.Row key={turbine.name}>
                <Table.Cell>
                  {turbine.name} / T{turbine.tier}
                  <Box color={turbine.condition <= 0 ? 'bad' : 'label'}>
                    {turbine.condition <= 0
                      ? 'Failed'
                      : turbine.manual
                        ? 'Manual'
                        : turbine.powered
                          ? 'Driven'
                          : 'Coasting'}
                  </Box>
                </Table.Cell>
                <Table.Cell>
                  {fixed(turbine.rpm, 1)}% /{' '}
                  <NumberInput
                    width="65px"
                    value={turbine.target}
                    minValue={0}
                    maxValue={data.maxRpm}
                    step={1}
                    unit="%"
                    disabled={!data.powered || turbine.condition <= 0}
                    onChange={(value) =>
                      act('rpm', { index: index + 1, value })
                    }
                  />
                </Table.Cell>
                <Table.Cell>
                  <ProgressBar value={turbine.condition / 100}>
                    {fixed(turbine.condition, 1)}%
                  </ProgressBar>
                  {turbine.condition > 0 && turbine.condition <= 50 && (
                    <Box color="orange">Service due</Box>
                  )}
                  {turbine.rpm > 100 && <Box color="orange">Overclocked</Box>}
                </Table.Cell>
                <Table.Cell>
                  {power(turbine.generation)} / {power(turbine.capacity)}
                  <Box color="label">Motor: {power(turbine.consumption)}</Box>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section title="Coolant and environment">
          {data.beakers.map((beaker) => (
            <Stack key={beaker.index} align="center" mb={1}>
              <Stack.Item grow>
                <Stack justify="space-between" mb={0.5}>
                  <Stack.Item>
                    Beaker {beaker.index}: {beaker.name || 'Empty slot'}
                  </Stack.Item>
                  <Stack.Item>
                    {beaker.temperature !== null &&
                      `${fixed(beaker.temperature, 1)} K`}
                  </Stack.Item>
                </Stack>
                <ProgressBar
                  value={beaker.capacity ? beaker.volume / beaker.capacity : 0}
                >
                  {beaker.installed
                    ? `${fixed(beaker.volume, 1)} / ${beaker.capacity} u`
                    : 'No beaker'}
                </ProgressBar>
                <Box color="label" mt={0.5}>
                  {beaker.contents || (beaker.installed ? 'Empty' : '')}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="eject"
                  tooltip="Eject beaker"
                  disabled={!data.panel || !beaker.installed}
                  onClick={() => act('ejectBeaker', { index: beaker.index })}
                />
              </Stack.Item>
            </Stack>
          ))}
          <Stack mt={1}>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Efficiency">
                  {fixed(data.efficiency * 100, 1)}%
                </LabeledList.Item>
                <LabeledList.Item label="Flow">
                  {fixed(data.flow, 2)} u/min
                </LabeledList.Item>
                <LabeledList.Item label="Fuel / wear penalty">
                  x{fixed(data.fuelMultiplier, 2)} / x
                  {fixed(data.wearMultiplier, 2)}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Room">
                  {fixed(data.ambientTemperature, 1)} K
                </LabeledList.Item>
                <LabeledList.Item label="Pressure">
                  {fixed(data.pressure, 1)} kPa
                </LabeledList.Item>
                <LabeledList.Item label="Circulation">
                  {fixed(data.circulation * 100)}%
                </LabeledList.Item>
                <LabeledList.Item label="Service panel">
                  {data.panel ? 'Open' : 'Closed'}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}
