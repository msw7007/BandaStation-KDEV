import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type PcApp = {
  id: string;
  name: string;
  category: string;
  status: string;
  description: string;
};

type PcData = {
  userName: string;
  accountName?: string;
  accountBalance: number;
  hasNeuralInterface: BooleanLike;
  accessCard?: string;
  memoryKeys: number;
  apps: PcApp[];
  activity: string[];
};

export const CyberpunkPcInterface = () => {
  const { act, data } = useBackend<PcData>();
  const apps = data.apps || [];
  const categories = Array.from(new Set(apps.map((app) => app.category)));
  const [category, setCategory] = useState(categories[0] || 'Work');
  const shownApps = apps.filter((app) => app.category === category);
  const [selectedId, setSelectedId] = useState('');
  const selected =
    apps.find((app) => app.id === selectedId && app.category === category) ||
    shownApps[0] ||
    apps[0];

  return (
    <Window title="PC Interface" width={760} height={540}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="City Workstation">
          <Stack>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <LabeledList>
                <LabeledList.Item label="User">{data.userName}</LabeledList.Item>
                <LabeledList.Item label="ID account">
                  {data.accountName || 'none'}
                </LabeledList.Item>
                <LabeledList.Item label="Balance">
                  {data.accountBalance || 0} cr
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <LabeledList>
                <LabeledList.Item label="Access card">
                  {data.accessCard || 'none'}
                </LabeledList.Item>
                <LabeledList.Item label="Neural link">
                  {data.hasNeuralInterface ? 'detected' : 'none'}
                </LabeledList.Item>
                <LabeledList.Item label="Memory keys">
                  {data.memoryKeys || 0}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>

        <Tabs>
          {categories.map((entry) => (
            <Tabs.Tab
              key={entry}
              selected={category === entry}
              onClick={() => setCategory(entry)}
            >
              {entry}
            </Tabs.Tab>
          ))}
        </Tabs>

        <Stack>
          <Stack.Item width="36%">
            <Section title="Apps">
              {shownApps.map((app) => (
                <Button
                  key={app.id}
                  fluid
                  selected={selected?.id === app.id}
                  onClick={() => setSelectedId(app.id)}
                >
                  <Stack>
                    <Stack.Item grow>{app.name}</Stack.Item>
                    <Stack.Item>
                      <Box color={app.status === 'ready' ? 'good' : 'label'}>
                        {app.status}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Button>
              ))}
              {!shownApps.length && (
                <Box className="CyberpunkPanel__Muted">No apps in this category.</Box>
              )}
            </Section>

            <Section title="Activity">
              {(data.activity || []).map((entry, index) => (
                <Box key={index} className="CyberpunkPanel__Mono CyberpunkPanel__Small">
                  {entry}
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            {selected ? (
              <Section
                title={selected.name}
                buttons={
                  <Button
                    icon="play"
                    disabled={
                      selected.status !== 'ready' && selected.status !== 'program'
                    }
                    onClick={() => act('open_app', { app: selected.id })}
                  >
                    Open
                  </Button>
                }
              >
                <Box className="CyberpunkPanel__Card">
                  <Box className="CyberpunkPanel__Title">{selected.name}</Box>
                  <Box mt={0.5}>{selected.description}</Box>
                  <Box mt={1} className="CyberpunkPanel__Muted">
                    Category: {selected.category} | Status: {selected.status}
                  </Box>
                </Box>
                {selected.status !== 'ready' && selected.status !== 'program' && (
                  <NoticeBox mt={1}>
                    This entry is listed to show the build surface, but its
                    dedicated terminal or app is not routed through this shell yet.
                  </NoticeBox>
                )}
              </Section>
            ) : (
              <Section title="Apps">
                <Box className="CyberpunkPanel__Muted">No apps indexed.</Box>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
