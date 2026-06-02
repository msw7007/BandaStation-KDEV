// CYBERPUNK BUILD - rebuild and delete before release
import {
  Box,
  Button,
  Collapsible,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type Contract = {
  id: number;
  title: string;
  description: string;
  type: string;
  target: string;
  status: string;
  creator: string;
  assignedContractor?: string;
  payment: number;
  deposit: number;
  penalty: number;
  legal: BooleanLike;
  pool: BooleanLike;
  corporation?: string;
  deadline: string;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  canAccept: BooleanLike;
  canRefuse: BooleanLike;
  history?: string[];
};

type Data = {
  contract?: Contract;
};

export const NtosContractOffer = () => {
  const { act, data } = useBackend<Data>();
  const { contract } = data;

  return (
    <NtosWindow width={560} height={520}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        {!contract ? (
          <Section title="Contract offer">
            <Box className="CyberpunkPanel__Muted">
              This offer is no longer available.
            </Box>
          </Section>
        ) : (
          <Section
            title={`#${contract.id} ${contract.title}`}
            buttons={
              <Stack>
                <Stack.Item>
                  <Button
                    icon="handshake"
                    disabled={!contract.canAccept}
                    onClick={() => act('accept')}
                  >
                    Accept
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="times"
                    color="bad"
                    disabled={!contract.canRefuse}
                    onClick={() => act('refuse_offer')}
                  >
                    Refuse
                  </Button>
                </Stack.Item>
              </Stack>
            }
          >
            <LabeledList>
              <LabeledList.Item label="Status">
                {contract.status}
              </LabeledList.Item>
              <LabeledList.Item label="Type">{contract.type}</LabeledList.Item>
              <LabeledList.Item label="Target">
                {contract.target}
              </LabeledList.Item>
              <LabeledList.Item label="Creator">
                {contract.creator}
              </LabeledList.Item>
              <LabeledList.Item label="Assigned">
                {contract.assignedContractor || 'open'}
              </LabeledList.Item>
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
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
