// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  LabeledList,
  Section,
  Table,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type RegistryContract = {
  id: number;
  title: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  contractor?: string;
  assignedContractor?: string;
  payment: number;
  deposit: number;
  penalty: number;
  taxPaid: number;
  public: BooleanLike;
  deadline: string;
  history?: string[];
};

type Data = {
  contracts: RegistryContract[];
  activeCount: number;
  completedCount: number;
  failedCount: number;
  taxRate: number;
};

export const NtosContractRegistry = () => {
  const { data } = useBackend<Data>();
  const {
    contracts = [],
    activeCount = 0,
    completedCount = 0,
    failedCount = 0,
    taxRate = 0,
  } = data;
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const selectedContract =
    contracts.find((contract) => contract.id === selectedId) || contracts[0];

  return (
    <NtosWindow width={780} height={620}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Legal contract registry">
          <Table>
            <Table.Row header>
              <Table.Cell>Indexed</Table.Cell>
              <Table.Cell>Active</Table.Cell>
              <Table.Cell>Completed</Table.Cell>
              <Table.Cell>Failed</Table.Cell>
              <Table.Cell>Legal tax</Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.Cell>{contracts.length}</Table.Cell>
              <Table.Cell>{activeCount}</Table.Cell>
              <Table.Cell>{completedCount}</Table.Cell>
              <Table.Cell>{failedCount}</Table.Cell>
              <Table.Cell>{taxRate}%</Table.Cell>
            </Table.Row>
          </Table>
        </Section>
        <Section title="Records">
          {!contracts.length ? (
            <Box className="CyberpunkPanel__Muted">
              No legal contracts are indexed.
            </Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>ID</Table.Cell>
                <Table.Cell>Title</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Target</Table.Cell>
                <Table.Cell>Parties</Table.Cell>
                <Table.Cell collapsing>Payment</Table.Cell>
              </Table.Row>
              {contracts.map((contract) => (
                <Table.Row key={contract.id} className={selectedContract?.id === contract.id ? 'Table__row--selected' : undefined}>
                  <Table.Cell>#{contract.id}</Table.Cell>
                  <Table.Cell>
                    <Button fluid onClick={() => setSelectedId(contract.id)}>
                      {contract.title}
                    </Button>
                  </Table.Cell>
                  <Table.Cell>{contract.type}</Table.Cell>
                  <Table.Cell>{contract.status}</Table.Cell>
                  <Table.Cell>{contract.target}</Table.Cell>
                  <Table.Cell>
                    {contract.creator}
                    {!!contract.contractor && ` -> ${contract.contractor}`}
                  </Table.Cell>
                  <Table.Cell>{formatMoney(contract.payment)} cr</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
        {!!selectedContract && (
          <Section title={`Record #${selectedContract.id}: ${selectedContract.title}`}>
            <LabeledList>
              <LabeledList.Item label="Deadline">
                {selectedContract.deadline}
              </LabeledList.Item>
              <LabeledList.Item label="Public">
                {selectedContract.public ? 'yes' : 'no'}
              </LabeledList.Item>
              <LabeledList.Item label="Deposit">
                {formatMoney(selectedContract.deposit)} cr
              </LabeledList.Item>
              <LabeledList.Item label="Penalty">
                {formatMoney(selectedContract.penalty)} cr
              </LabeledList.Item>
              <LabeledList.Item label="Tax paid">
                {formatMoney(selectedContract.taxPaid || 0)} cr
              </LabeledList.Item>
              <LabeledList.Item label="Assigned">
                {selectedContract.assignedContractor || 'open'}
              </LabeledList.Item>
            </LabeledList>
            <Collapsible title="History">
              {(selectedContract.history || []).map((entry, index) => (
                <Box key={index} className="CyberpunkPanel__Muted">
                  {entry}
                </Box>
              ))}
            </Collapsible>
          </Section>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
