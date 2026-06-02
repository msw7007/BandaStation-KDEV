// CYBERPUNK BUILD - rebuild and delete before release
import {
  Box,
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

  return (
    <NtosWindow width={780} height={620}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Legal contract registry">
          <LabeledList>
            <LabeledList.Item label="Indexed contracts">
              {contracts.length}
            </LabeledList.Item>
            <LabeledList.Item label="Active">{activeCount}</LabeledList.Item>
            <LabeledList.Item label="Completed">
              {completedCount}
            </LabeledList.Item>
            <LabeledList.Item label="Failed">{failedCount}</LabeledList.Item>
            <LabeledList.Item label="Legal tax">{taxRate}%</LabeledList.Item>
          </LabeledList>
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
                <Table.Row key={contract.id}>
                  <Table.Cell>#{contract.id}</Table.Cell>
                  <Table.Cell>
                    <Collapsible title={contract.title}>
                      <LabeledList>
                        <LabeledList.Item label="Deadline">
                          {contract.deadline}
                        </LabeledList.Item>
                        <LabeledList.Item label="Public">
                          {contract.public ? 'yes' : 'no'}
                        </LabeledList.Item>
                        <LabeledList.Item label="Deposit">
                          {formatMoney(contract.deposit)} cr
                        </LabeledList.Item>
                        <LabeledList.Item label="Penalty">
                          {formatMoney(contract.penalty)} cr
                        </LabeledList.Item>
                        <LabeledList.Item label="Tax paid">
                          {formatMoney(contract.taxPaid || 0)} cr
                        </LabeledList.Item>
                        <LabeledList.Item label="Assigned">
                          {contract.assignedContractor || 'open'}
                        </LabeledList.Item>
                      </LabeledList>
                      <Collapsible title="History">
                        {(contract.history || []).map((entry, index) => (
                          <Box key={index} className="CyberpunkPanel__Muted">
                            {entry}
                          </Box>
                        ))}
                      </Collapsible>
                    </Collapsible>
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
      </NtosWindow.Content>
    </NtosWindow>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
