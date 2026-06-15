// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Metric = {
  label: string;
  value: number;
  max: number;
  color: string;
};

type ShowcaseRow = {
  name: string;
  type: string;
  state: string;
  owner: string;
};

type ShowcaseData = {
  last_action: string;
  user_name: string;
  metrics: Metric[];
  rows: ShowcaseRow[];
  tabs: string[];
};

export const CyberpunkUiShowcase = () => {
  const { act, data } = useBackend<ShowcaseData>();
  const [tab, setTab] = useState('Status');
  const [input, setInput] = useState('');
  const [amount, setAmount] = useState(25);
  const [dropdown, setDropdown] = useState('empty');
  const [enabled, setEnabled] = useState(false);
  const tabs = data.tabs || ['Status', 'Actions', 'Records', 'Style'];
  const metrics = data.metrics || [];
  const rows = data.rows || [];

  return (
    <Window title="CP13 UI Showcase" width={760} height={560}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section
          title="Build Interface Palette"
          buttons={
            <Button icon="rotate" onClick={() => act('refresh')}>
              Ping
            </Button>
          }
        >
          <Stack>
            <Stack.Item grow>
              <NoticeBox info>
                Пустая витрина CP13 UI: элементы, состояния и компоновка для
                будущих экранов билда.
              </NoticeBox>
            </Stack.Item>
            <Stack.Item>
              <Box className="CyberpunkPanel__Metric">
                <Icon name="user" /> {data.user_name || 'unknown'}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>

        <Tabs>
          {tabs.map((entry) => (
            <Tabs.Tab
              key={entry}
              selected={tab === entry}
              onClick={() => setTab(entry)}
            >
              {entry}
            </Tabs.Tab>
          ))}
        </Tabs>

        {tab === 'Status' && (
          <Stack>
            <Stack.Item width="50%">
              <Section title="Metrics">
                <LabeledList>
                  {metrics.map((metric) => (
                    <LabeledList.Item key={metric.label} label={metric.label}>
                      <ProgressBar
                        value={metric.value}
                        minValue={0}
                        maxValue={metric.max}
                        ranges={{
                          good: [metric.max * 0.7, metric.max],
                          average: [metric.max * 0.35, metric.max * 0.7],
                          bad: [0, metric.max * 0.35],
                        }}
                      >
                        {metric.value}/{metric.max}
                      </ProgressBar>
                    </LabeledList.Item>
                  ))}
                </LabeledList>
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section title="State">
                <LabeledList>
                  <LabeledList.Item label="Last action">
                    {data.last_action || 'none'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Mode">stub</LabeledList.Item>
                  <LabeledList.Item label="Access">admin preview</LabeledList.Item>
                  <LabeledList.Item label="Payload">empty</LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
          </Stack>
        )}

        {tab === 'Actions' && (
          <Section title="Controls">
            <Stack vertical>
              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Input
                      fluid
                      placeholder="Empty text input"
                      value={input}
                      onChange={setInput}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Dropdown
                      width="160px"
                      selected={dropdown}
                      options={[
                        { displayText: 'Empty', value: 'empty' },
                        { displayText: 'Draft', value: 'draft' },
                        { displayText: 'Locked', value: 'locked' },
                      ]}
                      onSelected={setDropdown}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <NumberInput
                      width="55px"
                      value={amount}
                      minValue={0}
                      maxValue={100}
                      step={5}
                      onChange={(value) => setAmount(value)}
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item>
                <Button icon="play" onClick={() => act('primary')}>
                  Primary
                </Button>
                <Button icon="wrench" onClick={() => act('secondary')}>
                  Secondary
                </Button>
                <Button.Confirm
                  icon="triangle-exclamation"
                  color="bad"
                  onClick={() => act('danger')}
                >
                  Danger
                </Button.Confirm>
                <Button.Checkbox
                  checked={enabled}
                  onClick={() => setEnabled(!enabled)}
                >
                  Toggle
                </Button.Checkbox>
              </Stack.Item>
            </Stack>
          </Section>
        )}

        {tab === 'Records' && (
          <Section title="Empty Records">
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>State</Table.Cell>
                <Table.Cell>Owner</Table.Cell>
              </Table.Row>
              {rows.map((row) => (
                <Table.Row key={row.name}>
                  <Table.Cell bold>{row.name}</Table.Cell>
                  <Table.Cell>{row.type}</Table.Cell>
                  <Table.Cell>{row.state}</Table.Cell>
                  <Table.Cell>{row.owner}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}

        {tab === 'Style' && (
          <Section title="Layout Samples">
            <Stack>
              <Stack.Item grow>
                <Box className="CyberpunkPanel__Card">
                  <Box className="CyberpunkPanel__Title">Neutral card</Box>
                  <Box className="CyberpunkPanel__Muted">
                    Empty card shell for upcoming CP13 screens.
                  </Box>
                </Box>
              </Stack.Item>
              <Stack.Item grow>
                <Box className="CyberpunkPanel__Card CyberpunkPanel__Card--red">
                  <Box className="CyberpunkPanel__Title">Alert card</Box>
                  <Box className="CyberpunkPanel__Muted">
                    Reserved for risky actions and unavailable hooks.
                  </Box>
                </Box>
              </Stack.Item>
            </Stack>
            <Collapsible title="Collapsed detail block">
              <Box className="CyberpunkPanel__Card">
                Empty expandable body. Use for logs, condition breakdowns, and
                advanced settings.
              </Box>
            </Collapsible>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
