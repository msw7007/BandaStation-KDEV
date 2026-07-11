import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Contract = {
  id: number;
  title: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  contractor?: string;
  payment: number;
  deposit: number;
  deadline: string;
  canAccept: BooleanLike;
  canRefuse: BooleanLike;
  canAct: BooleanLike;
};

type Stats = {
  accepted: number;
  completed: number;
  failed: number;
  open: number;
  success_percent: number;
};

type Data = {
  contracts: Contract[];
  stats?: Stats;
};

export const CyberpunkContractPhone = () => {
  const { act, data } = useBackend<Data>();
  const { contracts = [], stats } = data;

  return (
    <Window width={680} height={560} theme="ntos_darkmode">
      <Window.Content scrollable>
        <Section title="Contract Work">
          <LabeledList>
            <LabeledList.Item label="Open">
              {stats?.open ?? 0}
            </LabeledList.Item>
            <LabeledList.Item label="Completed">
              {stats?.completed ?? 0}
            </LabeledList.Item>
            <LabeledList.Item label="Success">
              {stats?.success_percent ?? 0}%
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title={`Contracts (${contracts.length})`}>
          {!contracts.length ? (
            <Box color="label">No visible contracts.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>ID</Table.Cell>
                <Table.Cell>Job</Table.Cell>
                <Table.Cell>Target</Table.Cell>
                <Table.Cell collapsing>Pay</Table.Cell>
                <Table.Cell collapsing>Due</Table.Cell>
                <Table.Cell collapsing />
              </Table.Row>
              {contracts.map((contract) => (
                <Table.Row key={contract.id}>
                  <Table.Cell collapsing>#{contract.id}</Table.Cell>
                  <Table.Cell>
                    <Stack vertical>
                      <Stack.Item>{contract.title}</Stack.Item>
                      <Stack.Item color="label">
                        {contract.type} / {contract.status} / {contract.creator}
                      </Stack.Item>
                    </Stack>
                  </Table.Cell>
                  <Table.Cell>{contract.target}</Table.Cell>
                  <Table.Cell collapsing>{contract.payment}</Table.Cell>
                  <Table.Cell collapsing>{contract.deadline}</Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      icon="check"
                      disabled={!contract.canAccept}
                      onClick={() => act('accept', { id: contract.id })}
                    />
                    <Button
                      icon="xmark"
                      disabled={!contract.canRefuse}
                      onClick={() => act('refuse', { id: contract.id })}
                    />
                    <Button
                      icon="location-crosshairs"
                      disabled={!contract.canAct}
                      onClick={() => act('check', { id: contract.id })}
                    />
                    <Button
                      icon="file-shield"
                      onClick={() => act('disclose', { id: contract.id })}
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
