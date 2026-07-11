// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
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

type CityAIRecord = {
  ref: string;
  name: string;
  type: string;
  managed: BooleanLike;
  role: string;
  capabilities: number;
  task: string;
  state: string;
  successCondition: string;
  failureCondition: string;
  cargoType: string;
  cargoAmount: number;
  goapAction: string;
  goapPlan: string;
  phantom: string;
  phantomHealth: string;
  phantomRisk: string;
  zMethod: string;
  proxy: string;
  location: string;
  target: string;
  threat: string;
  health: number;
};

type Data = {
  ai: CityAIRecord[];
  trafficNodes: number;
  trafficLights: number;
  trafficVehicles: number;
  cityVendorsEnabled: BooleanLike;
  vendorCount: number;
  openVendors: number;
  safeZone: BooleanLike;
  userLocation: string;
};

const orderButtons = [
  ['threat', 'Threat'],
  ['repair', 'Repair'],
  ['evacuate', 'Evacuate'],
  ['escort', 'Escort'],
  ['deliver', 'Deliver'],
  ['avi_delivery', 'Starlight Delivery'],
  ['patrol', 'Patrol'],
] as const;

export const CyberpunkCityAI = () => {
  const { act, data } = useBackend<Data>();
  const {
    ai = [],
    trafficNodes = 0,
    trafficLights = 0,
    trafficVehicles = 0,
    cityVendorsEnabled,
    vendorCount = 0,
    openVendors = 0,
    safeZone,
    userLocation,
  } = data;
  const [selected, setSelected] = useState('auto');
  const selectedAI = ai.find((entry) => entry.ref === selected);

  return (
    <Window width={980} height={620} theme="cyberpunk">
      <Window.Content scrollable>
        <Section
          title="AI Debug Command"
          buttons={
            <Stack>
              <Stack.Item>
                <Button
                  icon="store"
                  selected={cityVendorsEnabled}
                  color={cityVendorsEnabled ? 'good' : 'bad'}
                  onClick={() => act('toggle_vendors')}
                >
                  Vendors {cityVendorsEnabled ? 'On' : 'Off'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button icon="sync" onClick={() => act('refresh')}>
                  Refresh
                </Button>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Operator">{userLocation}</LabeledList.Item>
                <LabeledList.Item label="Zone">
                  <Box color={safeZone ? 'good' : 'average'}>
                    {safeZone ? 'safe response' : 'local response'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Selected">
                  {selectedAI
                    ? `${selectedAI.name} / ${selectedAI.role}`
                    : 'Auto dispatch'}
                </LabeledList.Item>
                <LabeledList.Item label="Traffic">
                  {trafficNodes} nodes / {trafficLights} lights /{' '}
                  {trafficVehicles} cars
                </LabeledList.Item>
                <LabeledList.Item label="Vendors">
                  {openVendors} open / {vendorCount} total
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <Button
                selected={selected === 'auto'}
                onClick={() => setSelected('auto')}
              >
                Auto
              </Button>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="Orders">
          <Stack wrap>
            {orderButtons.map(([action, label]) => (
              <Stack.Item key={action}>
                <Button
                  icon="location-arrow"
                  onClick={() => act(action, { ai: selected })}
                >
                  {label}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
          <Box mt={1} color="label">
            Orders use the selected AI. Auto dispatch picks an available matching
            city NPC; unprofiled AI is listed for debugging.
          </Box>
        </Section>

        <Section title={`Active AI (${ai.length})`}>
          <Table>
            <Table.Row header>
              <Table.Cell collapsing />
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Managed</Table.Cell>
              <Table.Cell>Role</Table.Cell>
              <Table.Cell>Task</Table.Cell>
              <Table.Cell>State</Table.Cell>
              <Table.Cell>Conditions</Table.Cell>
              <Table.Cell>Cargo</Table.Cell>
              <Table.Cell>GOAP</Table.Cell>
              <Table.Cell>Plan</Table.Cell>
              <Table.Cell>Phantom</Table.Cell>
              <Table.Cell>Profile</Table.Cell>
              <Table.Cell>HP</Table.Cell>
              <Table.Cell>Location</Table.Cell>
              <Table.Cell>Target</Table.Cell>
              <Table.Cell>Threat</Table.Cell>
              <Table.Cell>Type</Table.Cell>
            </Table.Row>
            {ai.map((entry) => (
              <Table.Row key={entry.ref} selected={selected === entry.ref}>
                <Table.Cell collapsing>
                  <Button
                    compact
                    selected={selected === entry.ref}
                    onClick={() => setSelected(entry.ref)}
                  >
                    Select
                  </Button>
                </Table.Cell>
                <Table.Cell bold>{entry.name}</Table.Cell>
                <Table.Cell color={entry.managed ? 'good' : 'label'}>
                  {entry.managed ? 'city' : 'debug'}
                </Table.Cell>
                <Table.Cell>{entry.role}</Table.Cell>
                <Table.Cell>{entry.task}</Table.Cell>
                <Table.Cell>{entry.state}</Table.Cell>
                <Table.Cell>
                  {entry.successCondition} / {entry.failureCondition}
                </Table.Cell>
                <Table.Cell>
                  {entry.cargoType}
                  {entry.cargoAmount ? ` x${entry.cargoAmount}` : ''}
                </Table.Cell>
                <Table.Cell>{entry.goapAction}</Table.Cell>
                <Table.Cell>{entry.goapPlan}</Table.Cell>
                <Table.Cell>{entry.phantom}</Table.Cell>
                <Table.Cell>
                  {entry.phantomHealth} / {entry.phantomRisk} / {entry.zMethod} /{' '}
                  {entry.proxy}
                </Table.Cell>
                <Table.Cell color={entry.health <= 20 ? 'bad' : 'good'}>
                  {entry.health}%
                </Table.Cell>
                <Table.Cell>{entry.location}</Table.Cell>
                <Table.Cell>{entry.target}</Table.Cell>
                <Table.Cell color={entry.threat !== '-' ? 'bad' : undefined}>
                  {entry.threat}
                </Table.Cell>
                <Table.Cell color="label">{entry.type}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
