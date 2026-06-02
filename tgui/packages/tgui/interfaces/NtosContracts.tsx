// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type ContractStats = {
  created: number;
  accepted: number;
  completed: number;
  failed: number;
  cancelled: number;
};

type Contract = {
  id: number;
  title: string;
  description: string;
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
  legal: BooleanLike;
  public: BooleanLike;
  creatorConfirmRequired: BooleanLike;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  deadline: string;
  canAccept: BooleanLike;
  canManage: BooleanLike;
  canAct: BooleanLike;
  contractorStats?: ContractStats;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  userStats: ContractStats;
  contracts: Contract[];
  ownedContracts: Contract[];
  acceptedContracts: Contract[];
  directContract?: Contract;
};

const contractTypes = [
  { value: 'delivery', displayText: 'Delivery' },
  { value: 'repair', displayText: 'Repair' },
  { value: 'build', displayText: 'Construction' },
  { value: 'guard', displayText: 'Guard' },
  { value: 'mining', displayText: 'Mining' },
  { value: 'sabotage', displayText: 'Sabotage' },
  { value: 'elimination', displayText: 'Elimination' },
];

export const NtosContracts = () => {
  const { data } = useBackend<Data>();
  const {
    accountName,
    accountBalance,
    userStats,
    contracts = [],
    ownedContracts = [],
    acceptedContracts = [],
    directContract,
  } = data;

  return (
    <NtosWindow width={720} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Account">
          <LabeledList>
            <LabeledList.Item label="ID account">
              {accountName || 'No ID account'}
            </LabeledList.Item>
            <LabeledList.Item label="Balance">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Stats">
              Created {userStats?.created || 0}, accepted{' '}
              {userStats?.accepted || 0}, completed{' '}
              {userStats?.completed || 0}, failed {userStats?.failed || 0}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <ContractCreation disabled={!accountName} />
        <DirectContract contract={directContract} />
        <ContractList title="Public contracts" contracts={contracts} />
        <ContractList title="Accepted contracts" contracts={acceptedContracts} />
        <ContractList title="My contracts" contracts={ownedContracts} />
      </NtosWindow.Content>
    </NtosWindow>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release

const DirectContract = (props: { contract?: Contract }) => {
  const { act } = useBackend<Data>();
  const [contractId, setContractId] = useState(1);
  return (
    <Section title="Direct contract access">
      <Stack align="center">
        <Stack.Item>
          Contract #
          <NumberInput
            value={contractId}
            minValue={1}
            maxValue={999999}
            step={1}
            onChange={setContractId}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="search"
            onClick={() => act('direct_lookup', { id: contractId })}
          >
            Open
          </Button>
        </Stack.Item>
      </Stack>
      {!!props.contract && <ContractCard contract={props.contract} />}
    </Section>
  );
};

const ContractCreation = (props: { disabled: boolean }) => {
  const { act } = useBackend<Data>();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [target, setTarget] = useState('');
  const [assignedContractor, setAssignedContractor] = useState('');
  const [contractType, setContractType] = useState('delivery');
  const [payment, setPayment] = useState(100);
  const [deposit, setDeposit] = useState(0);
  const [penalty, setPenalty] = useState(0);
  const [duration, setDuration] = useState(30);
  const [requiredAmount, setRequiredAmount] = useState(1);
  const [requiredPercent, setRequiredPercent] = useState(75);
  const [legal, setLegal] = useState(true);
  const [isPublic, setPublic] = useState(true);
  const [creatorConfirm, setCreatorConfirm] = useState(false);

  return (
    <Collapsible title="Create contract">
      <Stack vertical>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Title"
                value={title}
                onChange={setTitle}
              />
            </Stack.Item>
            <Stack.Item width="180px">
              <Dropdown
                selected={contractType}
                options={contractTypes}
                onSelected={setContractType}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Target name, item name, object name, or type hint"
            value={target}
            onChange={setTarget}
          />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Assigned contractor name (optional)"
            value={assignedContractor}
            onChange={setAssignedContractor}
          />
        </Stack.Item>
        <Stack.Item>
          <TextArea
            height="60px"
            placeholder="Description"
            value={description}
            onChange={setDescription}
          />
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              Pay{' '}
              <NumberInput
                value={payment}
                minValue={1}
                maxValue={100000}
                step={10}
                onChange={setPayment}
              />
            </Stack.Item>
            <Stack.Item>
              Deposit{' '}
              <NumberInput
                value={deposit}
                minValue={0}
                maxValue={100000}
                step={10}
                onChange={setDeposit}
              />
            </Stack.Item>
            <Stack.Item>
              Penalty{' '}
              <NumberInput
                value={penalty}
                minValue={0}
                maxValue={100000}
                step={10}
                onChange={setPenalty}
              />
            </Stack.Item>
            <Stack.Item>
              Minutes{' '}
              <NumberInput
                value={duration}
                minValue={1}
                maxValue={180}
                step={5}
                onChange={setDuration}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              Amount{' '}
              <NumberInput
                value={requiredAmount}
                minValue={1}
                maxValue={1000}
                step={1}
                onChange={setRequiredAmount}
              />
            </Stack.Item>
            <Stack.Item>
              Percent{' '}
              <NumberInput
                value={requiredPercent}
                minValue={0}
                maxValue={100}
                step={5}
                onChange={setRequiredPercent}
              />
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox checked={legal} onClick={() => setLegal(!legal)}>
                Legal
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={isPublic}
                onClick={() => setPublic(!isPublic)}
              >
                Public
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={creatorConfirm}
                onClick={() => setCreatorConfirm(!creatorConfirm)}
              >
                Manual confirm
              </Button.Checkbox>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="file-signature"
            disabled={props.disabled}
            onClick={() =>
              act('create', {
                title,
                description,
                target,
                assigned_contractor: assignedContractor,
                contract_type: contractType,
                payment,
                deposit,
                penalty,
                duration_minutes: duration,
                required_amount: requiredAmount,
                required_percent: requiredPercent,
                legal: legal ? 1 : 0,
                public_contract: isPublic ? 1 : 0,
                creator_confirm_required: creatorConfirm ? 1 : 0,
              })
            }
          >
            Reserve payment and publish
          </Button>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const ContractList = (props: { title: string; contracts: Contract[] }) => {
  const { contracts = [] } = props;
  return (
    <Section title={`${props.title} (${contracts.length})`}>
      {!contracts.length ? (
        <Box className="CyberpunkPanel__Muted">No contracts.</Box>
      ) : (
        contracts.map((contract) => (
          <ContractCard key={contract.id} contract={contract} />
        ))
      )}
    </Section>
  );
};

const ContractCard = (props: { contract: Contract }) => {
  const { act } = useBackend<Data>();
  const { contract } = props;
  return (
    <Section
      title={`#${contract.id} ${contract.title}`}
      buttons={
        <>
          {!!contract.canAccept && (
            <Button
              icon="handshake"
              onClick={() => act('accept', { id: contract.id })}
            >
              Accept
            </Button>
          )}
          {!!contract.canAct && (
            <>
              <Button
                icon="tag"
                onClick={() => act('mark_held', { id: contract.id })}
              >
                Mark held
              </Button>
              <Button
                icon="box"
                onClick={() => act('submit_held', { id: contract.id })}
              >
                Submit held
              </Button>
              <Button
                icon="search"
                onClick={() => act('check_target', { id: contract.id })}
              >
                Check target
              </Button>
              <Button.Confirm
                icon="ban"
                onClick={() => act('abandon', { id: contract.id })}
              >
                Abandon
              </Button.Confirm>
            </>
          )}
          {!!contract.canManage && (
            <>
              <Button
                icon="check"
                onClick={() => act('creator_complete', { id: contract.id })}
              >
                Confirm
              </Button>
              <Button.Confirm
                icon="times"
                onClick={() => act('cancel', { id: contract.id })}
              >
                Cancel
              </Button.Confirm>
            </>
          )}
        </>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Status">{contract.status}</LabeledList.Item>
        <LabeledList.Item label="Type">{contract.type}</LabeledList.Item>
        <LabeledList.Item label="Target">{contract.target}</LabeledList.Item>
        <LabeledList.Item label="Creator">{contract.creator}</LabeledList.Item>
        <LabeledList.Item label="Assigned">
          {contract.assignedContractor || 'any contractor'}
        </LabeledList.Item>
        <LabeledList.Item label="Contractor">
          {contract.contractor || 'none'}
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
        <LabeledList.Item label="Tax paid">
          {formatMoney(contract.taxPaid || 0)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Deadline">{contract.deadline}</LabeledList.Item>
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
