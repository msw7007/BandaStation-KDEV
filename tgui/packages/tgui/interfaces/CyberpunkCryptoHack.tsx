// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import { Box, Button, Input, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CryptoOption = {
  index: number;
  text: string;
  active: BooleanLike;
  wrongHint: BooleanLike;
};

type CryptoColumn = {
  index: number;
  direction: string;
  current: string;
  correctIndex: number;
  options: CryptoOption[];
};

type CryptoHackData = {
  targetName: string;
  keyName: string;
  owner: string;
  testKey: string;
  maskedKey: string;
  hackingSkill: number;
  intelligence: number;
  columns: CryptoColumn[];
  aligned: BooleanLike;
  nextRotation: number;
};

export const CyberpunkCryptoHack = () => {
  const { act, data } = useBackend<CryptoHackData>();
  const {
    targetName,
    keyName,
    owner,
    testKey,
    maskedKey,
    hackingSkill,
    intelligence,
    columns = [],
    aligned,
    nextRotation,
  } = data;
  const [code, setCode] = useState('');

  return (
    <Window width={760} height={640}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Cryptokey breach">
          <Stack>
            <Stack.Item grow>
              <Box className="CyberpunkPanel__Metric">
                <Box className="CyberpunkPanel__Title">{targetName}</Box>
                <Box className="CyberpunkPanel__Muted">
                  {keyName} / {owner}
                </Box>
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box className="CyberpunkPanel__Metric">
                Hack {hackingSkill} / INT {intelligence}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box className="CyberpunkPanel__Metric">
                Shift in {nextRotation}s
              </Box>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="Key image">
          <Stack vertical>
            <Stack.Item>
              <Box className="CyberpunkPanel__Muted">Skill mask</Box>
              <Box className="CyberpunkPanel__CryptoKey">{maskedKey}</Box>
            </Stack.Item>
            {/* CYBERPUNK BUILD - rebuild and delete before release */}
            <Stack.Item>
              <Box className="CyberpunkPanel__Muted">Test output</Box>
              <Box className="CyberpunkPanel__CryptoKey">{testKey}</Box>
            </Stack.Item>
            {/* CYBERPUNK BUILD - rebuild and delete before release */}
          </Stack>
        </Section>

        <Section
          title="Column resolver"
          buttons={
            <Button
              color={aligned ? 'green' : undefined}
              onClick={() => act('attempt_alignment')}
            >
              Commit alignment
            </Button>
          }
        >
          <Box className="CyberpunkPanel__CryptoGrid">
            {columns.map((column) => (
              <Box key={column.index} className="CyberpunkPanel__CryptoColumn">
                <Stack vertical>
                  <Stack.Item>
                    <Button
                      fluid
                      icon={column.direction === 'down' ? 'arrow-down' : 'arrow-up'}
                      onClick={() =>
                        act('flip_column', { column: column.index })
                      }
                    >
                      {column.direction}
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Box className="CyberpunkPanel__Title" textAlign="center">
                      {column.current}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    {column.options.map((option) => (
                      <Box
                        key={option.index}
                        className={
                          'CyberpunkPanel__CryptoSegment' +
                          (option.active
                            ? ' CyberpunkPanel__CryptoSegment--active'
                            : '') +
                          (option.wrongHint
                            ? ' CyberpunkPanel__CryptoSegment--wrong'
                            : '')
                        }
                      >
                        {option.text}
                      </Box>
                    ))}
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Box>
        </Section>

        <Section title="One-use manual input">
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                value={code}
                placeholder="20-character cryptokey"
                onChange={(value: string) => setCode(value)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button onClick={() => act('submit_code', { code })}>
                Activate once
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
