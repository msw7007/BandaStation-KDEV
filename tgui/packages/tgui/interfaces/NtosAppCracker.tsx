import { useState } from 'react';
import { Box, Button, Input, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type AppCrackerData = {
  log: string[];
  connected: BooleanLike;
  connectedName: string;
  connectedDns: string;
  selected: BooleanLike;
  selectedName: string;
  selectedDns: string;
  cracking: BooleanLike;
  nextCrack: number;
  integrity: number;
};

export const NtosAppCracker = () => {
  const { act, data } = useBackend<AppCrackerData>();
  const {
    log = [],
    connected,
    connectedName,
    connectedDns,
    selected,
    selectedName,
    selectedDns,
    cracking,
    nextCrack,
    integrity,
  } = data;
  const [command, setCommand] = useState('');

  const submit = (value = command) => {
    const trimmed = value.trim();
    if (!trimmed) {
      return;
    }
    act('submit', { command: trimmed });
    setCommand('');
  };

  return (
    <NtosWindow width={760} height={560}>
      <NtosWindow.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title="App Cracker"
              buttons={
                <Button icon="trash" onClick={() => act('clear')}>
                  Clear
                </Button>
              }
            >
              <Stack>
                <Stack.Item grow>
                  <Box color="label">NODE</Box>
                  <Box>
                    {connected ? `${connectedDns} ${connectedName}` : 'none'}
                  </Box>
                </Stack.Item>
                <Stack.Item grow>
                  <Box color="label">OBJECT</Box>
                  <Box>
                    {selected ? `${selectedDns} ${selectedName}` : 'none'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box color="label">ICE</Box>
                  <Box>{connected ? `${integrity}%` : '-'}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Box color="label">CRACK</Box>
                  <Box color={cracking ? 'orange' : 'good'}>
                    {cracking ? `${nextCrack}s` : 'idle'}
                  </Box>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable title="Terminal">
              <Box
                style={{
                  fontFamily: 'monospace',
                  whiteSpace: 'pre-wrap',
                  lineHeight: '1.35',
                }}
              >
                {log.map((line, index) => (
                  <Box key={index} color={line.includes('ERR') ? 'bad' : line.includes('TRACE') ? 'orange' : undefined}>
                    {line}
                  </Box>
                ))}
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item grow>
                  <Input
                    autoFocus
                    fluid
                    value={command}
                    placeholder="help"
                    onChange={(value: string) => setCommand(value)}
                    onEnter={(value: string) => submit(value)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button icon="terminal" onClick={() => submit()}>
                    Run
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
