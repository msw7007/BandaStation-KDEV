import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const CyberpunkVehicle = () => {
  const { act, data } = useBackend();
  const {
    name,
    integrity,
    maxIntegrity,
    fuel,
    maxFuel,
    resourceType,
    speed,
    maxSpeed,
    surfaceGrip,
    drift,
    occupants,
    maxOccupants,
    mechanisms,
    mechanismSlots,
    mechanismData = [],
    parts = [],
    vectors = {},
  } = data;

  return (
    <Window width={560} height={520}>
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title={name}>
              <LabeledList>
                <LabeledList.Item label="Hull">
                  <ProgressBar
                    minValue={0}
                    maxValue={maxIntegrity}
                    value={integrity}
                    ranges={{
                      good: [maxIntegrity * 0.6, maxIntegrity],
                      average: [maxIntegrity * 0.25, maxIntegrity * 0.6],
                      bad: [0, maxIntegrity * 0.25],
                    }}
                  >
                    {integrity} / {maxIntegrity}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Resource">
                  <ProgressBar
                    minValue={0}
                    maxValue={maxFuel}
                    value={fuel}
                    ranges={{
                      good: [maxFuel * 0.5, maxFuel],
                      average: [maxFuel * 0.15, maxFuel * 0.5],
                      bad: [0, maxFuel * 0.15],
                    }}
                  >
                    {resourceType}: {fuel} / {maxFuel}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Speed">
                  {speed} / {maxSpeed} px/s {drift ? '(drift)' : ''}
                </LabeledList.Item>
                <LabeledList.Item label="Surface grip">
                  {surfaceGrip}
                </LabeledList.Item>
                <LabeledList.Item label="Occupants">
                  {occupants} / {maxOccupants}
                </LabeledList.Item>
                <LabeledList.Item label="Mechanisms">
                  {mechanisms} / {mechanismSlots}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Vector state">
              <Table>
                <Table.Row header>
                  <Table.Cell>Vector</Table.Cell>
                  <Table.Cell collapsing>X</Table.Cell>
                  <Table.Cell collapsing>Y</Table.Cell>
                </Table.Row>
                {['control', 'directed', 'movement', 'grip'].map((key) => (
                  <Table.Row key={key}>
                    <Table.Cell>{key}</Table.Cell>
                    <Table.Cell>{vectors[key]?.x ?? 0}</Table.Cell>
                    <Table.Cell>{vectors[key]?.y ?? 0}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Starlight parts">
              {parts.map((part) => (
                <Box key={part.category} mb={1}>
                  <LabeledList>
                    <LabeledList.Item label={part.name}>
                      <ProgressBar
                        minValue={0}
                        maxValue={part.maxHealth}
                        value={part.health}
                        ranges={{
                          good: [part.maxHealth * 0.6, part.maxHealth],
                          average: [part.maxHealth * 0.25, part.maxHealth * 0.6],
                          bad: [0, part.maxHealth * 0.25],
                        }}
                      >
                        {part.health} / {part.maxHealth}
                      </ProgressBar>
                    </LabeledList.Item>
                    <LabeledList.Item label="Manufacturer">
                      {part.manufacturer}
                    </LabeledList.Item>
                    <LabeledList.Item label="Effect">
                      {part.effect}
                    </LabeledList.Item>
                  </LabeledList>
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Mounted mechanisms">
              {!mechanismData.length && (
                <Box color="label">No mechanisms mounted.</Box>
              )}
              {!!mechanismData.length && (
                <Table>
                  <Table.Row header>
                    <Table.Cell>Name</Table.Cell>
                    <Table.Cell collapsing>Integrity</Table.Cell>
                    <Table.Cell collapsing />
                  </Table.Row>
                  {mechanismData.map((mechanism) => (
                    <Table.Row key={mechanism.index}>
                      <Table.Cell>{mechanism.name}</Table.Cell>
                      <Table.Cell>
                        {mechanism.integrity} / {mechanism.maxIntegrity}
                      </Table.Cell>
                      <Table.Cell>
                        <Button
                          icon="eject"
                          tooltip="Eject mechanism"
                          onClick={() =>
                            act('ejectMechanism', { index: mechanism.index })
                          }
                        />
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
