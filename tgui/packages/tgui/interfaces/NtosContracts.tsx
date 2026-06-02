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
  Table,
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
  pool: BooleanLike;
  corporation?: string;
  generated: BooleanLike;
  creatorConfirmRequired: BooleanLike;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  deadline: string;
  canAccept: BooleanLike;
  canRefuse: BooleanLike;
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
  offeredContracts: Contract[];
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
    offeredContracts = [],
    ownedContracts = [],
    acceptedContracts = [],
    directContract,
  } = data;
  const [tab, setTab] = useState('accepted');

  return (
    <NtosWindow width={820} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Account">
          <Stack>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Muted">ID account</Box>
              <Box className="CyberpunkPanel__Title">
                {accountName || 'No ID account'}
              </Box>
            </Stack.Item>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Muted">Balance</Box>
              <Box className="CyberpunkPanel__Title">
                {formatMoney(accountBalance)} cr
              </Box>
            </Stack.Item>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Muted">Stats</Box>
              <Box>
                C {userStats?.created || 0} / A {userStats?.accepted || 0} / D{' '}
                {userStats?.completed || 0} / F {userStats?.failed || 0}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Contracts">
          <Stack>
            <Stack.Item>
              <Button selected={tab === 'accepted'} onClick={() => setTab('accepted')}>
                Accepted
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button selected={tab === 'board'} onClick={() => setTab('board')}>
                Board
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button selected={tab === 'create'} onClick={() => setTab('create')}>
                Create
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
        {tab === 'accepted' && (
          <>
            <ContractList title="Incoming offers" contracts={offeredContracts} />
            <ContractList title="Accepted contracts" contracts={acceptedContracts} />
            <ContractList title="My contracts" contracts={ownedContracts} />
          </>
        )}
        {tab === 'board' && (
          <>
            <DirectContract contract={directContract} />
            <ContractList title="Public contracts" contracts={contracts} />
          </>
        )}
        {tab === 'create' && <ContractCreation disabled={!accountName} />}
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
      {!!props.contract && (
        <Section title={`#${props.contract.id} ${props.contract.title}`}>
          <ContractDetails contract={props.contract} />
        </Section>
      )}
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
  const [poolContract, setPoolContract] = useState(false);
  const [poolCorporation, setPoolCorporation] = useState('');
  const [creatorConfirm, setCreatorConfirm] = useState(false);

  return (
    <Section title="Create contract">
      <Stack vertical>
        <Stack.Item>
          <Section title="Core">
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
                  <Stack.Item width="190px">
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
                  height="70px"
                  placeholder="Description"
                  value={description}
                  onChange={setDescription}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        <Stack.Item>
          <Section title="Terms">
            <Table>
              <Table.Row>
                <Table.Cell>Payment</Table.Cell>
                <Table.Cell>
                  <NumberInput value={payment} minValue={1} maxValue={100000} step={10} onChange={setPayment} />
                </Table.Cell>
                <Table.Cell>Deposit</Table.Cell>
                <Table.Cell>
                  <NumberInput value={deposit} minValue={0} maxValue={100000} step={10} onChange={setDeposit} />
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>Penalty</Table.Cell>
                <Table.Cell>
                  <NumberInput value={penalty} minValue={0} maxValue={100000} step={10} onChange={setPenalty} />
                </Table.Cell>
                <Table.Cell>Minutes</Table.Cell>
                <Table.Cell>
                  <NumberInput value={duration} minValue={1} maxValue={180} step={5} onChange={setDuration} />
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>Amount</Table.Cell>
                <Table.Cell>
                  <NumberInput value={requiredAmount} minValue={1} maxValue={1000} step={1} onChange={setRequiredAmount} />
                </Table.Cell>
                <Table.Cell>Percent</Table.Cell>
                <Table.Cell>
                  <NumberInput value={requiredPercent} minValue={0} maxValue={100} step={5} onChange={setRequiredPercent} />
                </Table.Cell>
              </Table.Row>
            </Table>
          </Section>
        </Stack.Item>
        <Stack.Item>
          <Section title="Visibility">
            <Stack wrap>
              <Stack.Item>
                <Button.Checkbox checked={legal} onClick={() => setLegal(!legal)}>
                  Legal
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox checked={isPublic} onClick={() => setPublic(!isPublic)}>
                  Public
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox checked={poolContract} onClick={() => setPoolContract(!poolContract)}>
                  Pool
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox checked={creatorConfirm} onClick={() => setCreatorConfirm(!creatorConfirm)}>
                  Manual confirm
                </Button.Checkbox>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        {!!poolContract && (
          <Stack.Item>
            <Input
              fluid
              placeholder="Pool corporation/source label"
              value={poolCorporation}
              onChange={setPoolCorporation}
            />
          </Stack.Item>
        )}
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
                pool_contract: poolContract ? 1 : 0,
                pool_corporation: poolCorporation,
                creator_confirm_required: creatorConfirm ? 1 : 0,
              })
            }
          >
            Reserve payment and publish
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ContractList = (props: { title: string; contracts: Contract[] }) => {
  const { contracts = [] } = props;
  return (
    <Section title={`${props.title} (${contracts.length})`}>
      {!contracts.length ? (
        <Box className="CyberpunkPanel__Muted">No contracts.</Box>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell collapsing>ID</Table.Cell>
            <Table.Cell>Title</Table.Cell>
            <Table.Cell>Type</Table.Cell>
            <Table.Cell>Status</Table.Cell>
            <Table.Cell>Target</Table.Cell>
            <Table.Cell>Contractor</Table.Cell>
            <Table.Cell collapsing>Pay</Table.Cell>
          </Table.Row>
          {contracts.map((contract) => (
            <Table.Row key={contract.id}>
              <Table.Cell collapsing>#{contract.id}</Table.Cell>
              <Table.Cell>
                <Collapsible title={contract.title}>
                  <ContractDetails contract={contract} />
                </Collapsible>
              </Table.Cell>
              <Table.Cell>{contract.type}</Table.Cell>
              <Table.Cell>{contract.status}</Table.Cell>
              <Table.Cell>{contract.target}</Table.Cell>
              <Table.Cell>
                {contract.contractor || contract.assignedContractor || 'open'}
              </Table.Cell>
              <Table.Cell collapsing>
                {formatMoney(contract.payment)} cr
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const ContractDetails = (props: { contract: Contract }) => {
  const { contract } = props;
  return (
    <>
      <ContractActions contract={contract} />
      <LabeledList>
        <LabeledList.Item label="Status">{contract.status}</LabeledList.Item>
        <LabeledList.Item label="Type">{contract.type}</LabeledList.Item>
        <LabeledList.Item label="Target">{contract.target}</LabeledList.Item>
        <LabeledList.Item label="Creator">{contract.creator}</LabeledList.Item>
        <LabeledList.Item label="Source">
          {contract.pool
            ? `pool${contract.corporation ? ` / ${contract.corporation}` : ''}`
            : contract.legal
              ? 'legal'
              : 'off-ledger'}
        </LabeledList.Item>
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
    </>
  );
};

const ContractActions = (props: { contract: Contract }) => {
  const { act } = useBackend<Data>();
  const { contract } = props;
  return (
    <Stack wrap>
      {!!contract.canAccept && (
        <Stack.Item>
          <Button icon="handshake" onClick={() => act('accept', { id: contract.id })}>
            Accept
          </Button>
        </Stack.Item>
      )}
      {!!contract.canRefuse && (
        <Stack.Item>
          <Button icon="times" color="bad" onClick={() => act('refuse_offer', { id: contract.id })}>
            Refuse
          </Button>
        </Stack.Item>
      )}
      {!!contract.canAct && (
        <>
          <Stack.Item>
            <Button icon="tag" onClick={() => act('mark_held', { id: contract.id })}>
              Mark held
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button icon="box" onClick={() => act('submit_held', { id: contract.id })}>
              Submit held
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button icon="search" onClick={() => act('check_target', { id: contract.id })}>
              Check target
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm icon="ban" onClick={() => act('abandon', { id: contract.id })}>
              Abandon
            </Button.Confirm>
          </Stack.Item>
        </>
      )}
      {!!contract.canManage && (
        <>
          <Stack.Item>
            <Button icon="check" onClick={() => act('creator_complete', { id: contract.id })}>
              Confirm
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm icon="times" onClick={() => act('cancel', { id: contract.id })}>
              Cancel
            </Button.Confirm>
          </Stack.Item>
        </>
      )}
    </Stack>
  );
};
