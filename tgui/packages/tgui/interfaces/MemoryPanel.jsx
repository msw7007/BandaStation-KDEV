// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
  Table,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const STORY_VALUE_KEY = -1;

const entryTypes = [
  { value: 'note', displayText: 'Note' },
  { value: 'key', displayText: 'Cryptokey' },
];

const MemoryQuality = (props) => {
  const { quality } = props;
  if (quality === STORY_VALUE_KEY) {
    return <Button icon="key" color="transparent" tooltip="Key memory" />;
  }
  return <Button icon="brain" color="transparent" tooltip="Memory" />;
};

export const MemoryPanel = () => {
  const { act, data } = useBackend();
  const memories = data.memories || [];
  const notes = data.notes || [];
  const cryptokeys = data.cryptokeys || [];
  const identityMemories = data.identityMemories || [];
  const [entryType, setEntryType] = useState('note');
  const [noteText, setNoteText] = useState('');
  const [keyName, setKeyName] = useState('');
  const [keyOwner, setKeyOwner] = useState('');
  const [keyCode, setKeyCode] = useState('');

  return (
    <Window title="Memory" width={700} height={620}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Add information">
          <Stack vertical>
            <Stack.Item>
              <Stack>
                <Stack.Item width="160px">
                  <Dropdown
                    selected={entryType}
                    options={entryTypes}
                    onSelected={setEntryType}
                  />
                </Stack.Item>
                <Stack.Item grow>
                  <Box className="CyberpunkPanel__Muted">
                    Store character-known information in this body memory.
                  </Box>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            {entryType === 'note' ? (
              <>
                <Stack.Item>
                  <TextArea
                    height="70px"
                    fluid
                    placeholder="Memory note"
                    value={noteText}
                    onChange={setNoteText}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="plus"
                    disabled={!noteText}
                    onClick={() => {
                      act('add_note', { text: noteText });
                      setNoteText('');
                    }}
                  >
                    Add note
                  </Button>
                </Stack.Item>
              </>
            ) : (
              <>
                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        placeholder="Key name"
                        value={keyName}
                        onChange={setKeyName}
                      />
                    </Stack.Item>
                    <Stack.Item grow>
                      <Input
                        fluid
                        placeholder="Owner"
                        value={keyOwner}
                        onChange={setKeyOwner}
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Input
                    fluid
                    placeholder="20-character cryptokey"
                    value={keyCode}
                    onChange={setKeyCode}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="key"
                    disabled={keyCode.length !== 20}
                    onClick={() => {
                      act('add_key', {
                        name: keyName,
                        owner: keyOwner,
                        code: keyCode,
                      });
                      setKeyName('');
                      setKeyOwner('');
                      setKeyCode('');
                    }}
                  >
                    Add cryptokey
                  </Button>
                </Stack.Item>
              </>
            )}
          </Stack>
        </Section>

        <Section title={`Notes (${notes.length})`}>
          {!notes.length ? (
            <Box className="CyberpunkPanel__Muted">No manual notes.</Box>
          ) : (
            <Stack vertical>
              {notes.map((note, index) => (
                <Stack.Item key={index}>
                  <Box className="CyberpunkPanel__Card">{note.text}</Box>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        <Section title={`Cryptokeys (${cryptokeys.length})`}>
          {!cryptokeys.length ? (
            <Box className="CyberpunkPanel__Muted">No cryptokeys in memory.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Owner</Table.Cell>
                <Table.Cell>Code</Table.Cell>
              </Table.Row>
              {cryptokeys.map((key, index) => (
                <Table.Row key={`${key.code}-${index}`}>
                  <Table.Cell>{key.name}</Table.Cell>
                  <Table.Cell>{key.owner}</Table.Cell>
                  <Table.Cell className="CyberpunkPanel__Mono">
                    {key.code}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        <Section title={`Observed identities (${identityMemories.length})`}>
          {!identityMemories.length ? (
            <Box className="CyberpunkPanel__Muted">No examined identities.</Box>
          ) : (
            <Stack vertical>
              {identityMemories.map((identity, index) => (
                <Stack.Item key={`${identity.name}-${identity.last_seen_time}-${index}`}>
                  <Box className="CyberpunkPanel__Card">
                    <Stack vertical>
                      <Stack.Item>
                        <Stack>
                          <Stack.Item grow>
                            <Box bold>{identity.name}</Box>
                          </Stack.Item>
                          <Stack.Item className="CyberpunkPanel__Muted">
                            {identity.area} / {identity.last_seen}
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                      <Stack.Item>
                        <Box>{identity.snapshot}</Box>
                      </Stack.Item>
                    </Stack>
                  </Box>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        <Section title={`Memories (${memories.length})`}>
          {!memories.length ? (
            <Box className="CyberpunkPanel__Muted">No notable memories.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>Kind</Table.Cell>
                <Table.Cell>Name</Table.Cell>
              </Table.Row>
              {memories.map((memory) => (
                <Table.Row key={memory.name}>
                  <Table.Cell collapsing>
                    <MemoryQuality quality={memory.quality} />
                  </Table.Cell>
                  <Table.Cell>{memory.name}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
