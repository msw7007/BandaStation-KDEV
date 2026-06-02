// CYBERPUNK BUILD - rebuild and delete before release
import {
  Box,
  Button,
  Collapsible,
  LabeledList,
  Section,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type PoolContract = {
  id: number;
  title: string;
  description: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  payment: number;
  deposit: number;
  penalty: number;
  legal: BooleanLike;
  pool: BooleanLike;
  corporation?: string;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  deadline: string;
  canAccept: BooleanLike;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  contracts: PoolContract[];
};

export const NtosContractPool = () => {
  const { data } = useBackend<Data>();
  const { accountName, accountBalance = 0, contracts = [] } = data;

  return (
    <NtosWindow width={700} height={640}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Corporate contract pool">
          <LabeledList>
            <LabeledList.Item label="ID account">
              {accountName || 'No ID account'}
            </LabeledList.Item>
            <LabeledList.Item label="Balance">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Available">
              {contracts.length}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Pool offers">
          {!contracts.length ? (
            <Box className="CyberpunkPanel__Muted">
              No pool contracts are available.
            </Box>
          ) : (
            contracts.map((contract) => (
              <PoolContractCard key={contract.id} contract={contract} />
            ))
          )}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const PoolContractCard = (props: { contract: PoolContract }) => {
  const { act } = useBackend<Data>();
  const { contract } = props;
  return (
    <Section
      title={`#${contract.id} ${contract.title}`}
      buttons={
        <Button
          icon="handshake"
          disabled={!contract.canAccept}
          onClick={() => act('accept', { id: contract.id })}
        >
          Take
        </Button>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Corporation">
          {contract.corporation || contract.creator}
        </LabeledList.Item>
        <LabeledList.Item label="Type">{contract.type}</LabeledList.Item>
        <LabeledList.Item label="Target">{contract.target}</LabeledList.Item>
        <LabeledList.Item label="Payment">
          {formatMoney(contract.payment)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Deposit">
          {formatMoney(contract.deposit)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Penalty">
          {formatMoney(contract.penalty)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Deadline">
          {contract.deadline}
        </LabeledList.Item>
        <LabeledList.Item label="Requirement">
          {contract.deliveredAmount}/{contract.requiredAmount}, threshold{' '}
          {contract.requiredPercent}%
        </LabeledList.Item>
      </LabeledList>
      {!!contract.description && <Box mt={1}>{contract.description}</Box>}
      <Collapsible title="History">
        {(contract.history || []).map((entry, index) => (
          <Box key={index} className="CyberpunkPanel__Muted">
            {entry}
          </Box>
        ))}
      </Collapsible>
    </Section>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
