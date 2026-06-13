// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type TerminalContract = {
  id: number;
  title: string;
  type: string;
  target: string;
  progress: string;
  compatible: BooleanLike;
};

type TerminalMail = {
  id: number;
  label: string;
  sender: string;
  item: string;
  contractId?: number;
  source: string;
};

type Data = {
  terminal: string;
  online: BooleanLike;
  hasRelay: BooleanLike;
  heldItem?: string;
  contracts: TerminalContract[];
  mail: TerminalMail[];
};

export const CyberpunkContractTerminal = () => {
  const { act, data } = useBackend<Data>();
  const {
    terminal,
    online,
    hasRelay,
    heldItem,
    contracts = [],
    mail = [],
  } = data;
  const [recipient, setRecipient] = useState('');

  return (
    <Window width={620} height={560} theme="ntos_darkmode">
      <Window.Content scrollable className="CyberpunkPanel">
        <Section
          title="Contract terminal"
          buttons={
            !!hasRelay && (
              <Button icon="network-wired" onClick={() => act('relay')}>
                Cyberspace relay
              </Button>
            )
          }
        >
          <LabeledList>
            <LabeledList.Item label="Endpoint">
              {terminal || 'unknown'}
            </LabeledList.Item>
            <LabeledList.Item label="Status">
              {online ? 'online' : 'offline'}
            </LabeledList.Item>
            <LabeledList.Item label="Held item">
              {heldItem || 'empty hands'}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Cargo actions">
          <Stack>
            <Stack.Item grow>
              <Button
                fluid
                icon="box"
                disabled={!heldItem || !online}
                onClick={() => act('submit_held')}
              >
                Submit held contract cargo
              </Button>
            </Stack.Item>
          </Stack>
          <Stack mt={1}>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Recipient character name"
                value={recipient}
                onChange={setRecipient}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="paper-plane"
                disabled={!heldItem || !recipient || !online}
                onClick={() => act('send_mail', { recipient })}
              >
                Send held item
              </Button>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title={`Incoming mail (${mail.length})`}>
          {!mail.length ? (
            <Box className="CyberpunkPanel__Muted">No mail for this ID.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Item</Table.Cell>
                <Table.Cell>Sender</Table.Cell>
                <Table.Cell>Source</Table.Cell>
                <Table.Cell collapsing />
              </Table.Row>
              {mail.map((entry) => (
                <Table.Row key={entry.id}>
                  <Table.Cell>{entry.item || entry.label}</Table.Cell>
                  <Table.Cell>{entry.sender}</Table.Cell>
                  <Table.Cell>{entry.source}</Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      icon="inbox"
                      disabled={!online}
                      onClick={() => act('claim_mail', { id: entry.id })}
                    >
                      Claim
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        <Section title={`Compatible contracts (${contracts.length})`}>
          {!contracts.length ? (
            <Box className="CyberpunkPanel__Muted">
              No accepted contracts match this terminal.
            </Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>ID</Table.Cell>
                <Table.Cell>Title</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Target</Table.Cell>
                <Table.Cell collapsing>Progress</Table.Cell>
              </Table.Row>
              {contracts.map((contract) => (
                <Table.Row key={contract.id}>
                  <Table.Cell collapsing>#{contract.id}</Table.Cell>
                  <Table.Cell>{contract.title}</Table.Cell>
                  <Table.Cell>{contract.type}</Table.Cell>
                  <Table.Cell>{contract.target}</Table.Cell>
                  <Table.Cell collapsing>{contract.progress}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
