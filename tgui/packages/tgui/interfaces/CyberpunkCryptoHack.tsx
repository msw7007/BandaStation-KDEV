// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import { Box, Button, Input, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CryptoOption = {
  index: number;
  text: string;
  selected: BooleanLike;
  wrongHint: BooleanLike;
  result?: string;
};

type CryptoColumn = {
  index: number;
  selectedIndex: number;
  options: CryptoOption[];
};

type CryptoHackData = {
  targetName: string;
  keyName: string;
  owner: string;
  testKey: string;
  maskedKey: string;
  selectedCode: string;
  hackingSkill: number;
  intelligence: number;
  columns: CryptoColumn[];
  aligned: BooleanLike;
  revealTimer: number;
  revealDelay: number;
  revealedCount: number;
  lastErrorCount: number;
};

export const CyberpunkCryptoHack = () => {
  const { act, data } = useBackend<CryptoHackData>();
  const {
    targetName,
    keyName,
    owner,
    testKey,
    maskedKey,
    selectedCode,
    hackingSkill,
    intelligence,
    columns = [],
    aligned,
    revealTimer,
    revealDelay,
    revealedCount,
    lastErrorCount,
  } = data;
  const [code, setCode] = useState('');

  const getSegmentClass = (option: CryptoOption) =>
    'CyberpunkPanel__CryptoSegment' +
    (option.result === 'correct'
      ? ' CyberpunkPanel__CryptoSegment--correct'
      : '') +
    (option.result === 'wrong'
      ? ' CyberpunkPanel__CryptoSegment--wrong'
      : '') +
    (!option.result && option.selected
      ? ' CyberpunkPanel__CryptoSegment--selected'
      : '') +
    (!option.result && !option.selected && option.wrongHint
      ? ' CyberpunkPanel__CryptoSegment--wrong'
      : '');

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
                Reveal in {revealTimer}s
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box className="CyberpunkPanel__Metric">
                {revealedCount}/20 / {revealDelay}s
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
              <Box className="CyberpunkPanel__Muted">Selected output</Box>
              <Box className="CyberpunkPanel__CryptoKey">{selectedCode}</Box>
            </Stack.Item>
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
              Confirm key
            </Button>
          }
        >
          {!!lastErrorCount && (
            <Box className="CyberpunkPanel__Muted" mb={1}>
              Last check rejected {lastErrorCount} segment
              {lastErrorCount === 1 ? '' : 's'}.
            </Box>
          )}
          <Box className="CyberpunkPanel__CryptoGrid">
            {columns.map((column) => (
              <Box key={column.index} className="CyberpunkPanel__CryptoColumn">
                <Stack vertical>
                  <Stack.Item>
                    <Box className="CyberpunkPanel__Title" textAlign="center">
                      Column {column.index}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    {column.options.map((option) => (
                      <Button
                        fluid
                        key={option.index}
                        className={getSegmentClass(option)}
                        onClick={() =>
                          act('select_segment', {
                            column: column.index,
                            option: option.index,
                          })
                        }
                      >
                        {option.text}
                      </Button>
                    ))}
                  </Stack.Item>
                </Stack>
              </Box>
            ))}
          </Box>
        </Section>

        <Section title="Manual key input">
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
