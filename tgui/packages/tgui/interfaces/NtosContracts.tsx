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
  open?: number;
  success_percent?: number;
};

type TerminalOption = {
  label: string;
  name: string;
  area: string;
  x: number;
  y: number;
  z: number;
};

type FundingOption = {
  id: number;
  name: string;
  balance: number;
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
  directAccessCode?: string;
  requiredAmount: number;
  deliveredAmount: number;
  requiredPercent: number;
  conditions?: ContractCondition[];
  deadline: string;
  canAccept: BooleanLike;
  canRefuse: BooleanLike;
  canManage: BooleanLike;
  canAct: BooleanLike;
  contractorStats?: ContractStats;
  history?: string[];
};

type ContractCondition = {
  id: string;
  name: string;
  description?: string;
  target?: string;
  targetArea?: string;
  targetX?: number;
  targetY?: number;
  targetZ?: number;
  targetRadius?: number;
  requiredAmount?: number;
  deliveredAmount?: number;
  requiredPercent?: number;
  minimumQuality?: number;
  minimumRarity?: number;
  destinationKind?: string;
  destination?: string;
  sabotageMode?: string;
  partialPayment?: BooleanLike;
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
  terminalOptions?: TerminalOption[];
  fundingOptions?: FundingOption[];
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
                {userStats?.completed || 0} / F {userStats?.failed || 0} / O{' '}
                {userStats?.open || 0} / {userStats?.success_percent || 0}%
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
  const [contractId, setContractId] = useState('');
  return (
    <Section title="Direct contract access">
      <Stack align="center">
        <Stack.Item grow>
          <Input
            fluid
            placeholder="Contract ID or private access code"
            value={contractId}
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
  const { act, data } = useBackend<Data>();
  const terminalOptions = data.terminalOptions || [];
  const fundingOptions = data.fundingOptions || [];
  const [fundingBusinessId, setFundingBusinessId] = useState(0);
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
  const [targetArea, setTargetArea] = useState('');
  const [targetX, setTargetX] = useState(0);
  const [targetY, setTargetY] = useState(0);
  const [targetZ, setTargetZ] = useState(0);
  const [targetRadius, setTargetRadius] = useState(0);
  const [minimumQuality, setMinimumQuality] = useState(0);
  const [minimumRarity, setMinimumRarity] = useState(0);
  const [destinationKind, setDestinationKind] = useState('creator');
  const [destination, setDestination] = useState('');
  const [sabotageMode, setSabotageMode] = useState('damage');
  const [legal, setLegal] = useState(true);
  const [isPublic, setPublic] = useState(true);
  const [poolContract, setPoolContract] = useState(false);
  const [poolCorporation, setPoolCorporation] = useState('');
  const [creatorConfirm, setCreatorConfirm] = useState(false);
  const [reserveHeld, setReserveHeld] = useState(false);
  const [partialGuardPayment, setPartialGuardPayment] = useState(false);
  const terminalDropdownOptions = terminalOptions.map((terminal) => ({
    value: terminal.label,
    displayText: `${terminal.name} / ${terminal.area} / ${terminal.x}:${terminal.y}:${terminal.z}`,
  }));

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
            {!!fundingOptions.length && (
              <Stack mb={1} wrap>
                {fundingOptions.map((option) => (
                  <Stack.Item key={option.id}>
                    <Button
                      selected={fundingBusinessId === option.id}
                      onClick={() => setFundingBusinessId(option.id)}
                    >
                      {option.name} ({formatMoney(option.balance)} cr)
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            )}
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
          <Section title="Condition">
            <Stack vertical>
              <Stack.Item>
                <Input
                  fluid
                  placeholder="Target area (optional)"
                  value={targetArea}
                  onChange={setTargetArea}
                />
              </Stack.Item>
              <Stack.Item>
                <Table>
                  <Table.Row>
                    <Table.Cell>X</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={targetX} minValue={0} maxValue={999} step={1} onChange={setTargetX} />
                    </Table.Cell>
                    <Table.Cell>Y</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={targetY} minValue={0} maxValue={999} step={1} onChange={setTargetY} />
                    </Table.Cell>
                    <Table.Cell>Z</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={targetZ} minValue={0} maxValue={50} step={1} onChange={setTargetZ} />
                    </Table.Cell>
                    <Table.Cell>Radius</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={targetRadius} minValue={0} maxValue={20} step={1} onChange={setTargetRadius} />
                    </Table.Cell>
                  </Table.Row>
                  <Table.Row>
                    <Table.Cell>Min quality</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={minimumQuality} minValue={0} maxValue={100} step={1} onChange={setMinimumQuality} />
                    </Table.Cell>
                    <Table.Cell>Min rarity</Table.Cell>
                    <Table.Cell>
                      <NumberInput value={minimumRarity} minValue={0} maxValue={10} step={1} onChange={setMinimumRarity} />
                    </Table.Cell>
                    <Table.Cell>Delivery</Table.Cell>
                    <Table.Cell>
                      <Dropdown
                        selected={destinationKind}
                        options={['creator', 'recipient', 'terminal', 'coordinates']}
                        onSelected={setDestinationKind}
                      />
                    </Table.Cell>
                    <Table.Cell>Sabotage</Table.Cell>
                    <Table.Cell>
                      <Dropdown
                        selected={sabotageMode}
                        options={['damage', 'disabled', 'unpowered', 'broken', 'hacked', 'emagged', 'destroyed']}
                        onSelected={setSabotageMode}
                      />
                    </Table.Cell>
                  </Table.Row>
                </Table>
              </Stack.Item>
              <Stack.Item>
                <Input
                  fluid
                  placeholder="Recipient, terminal, or destination label"
                  value={destination}
                  onChange={setDestination}
                />
              </Stack.Item>
              {!!terminalDropdownOptions.length && destinationKind === 'terminal' && (
                <Stack.Item>
                  <Dropdown
                    selected={destination}
                    options={terminalDropdownOptions}
                    onSelected={setDestination}
                  />
                </Stack.Item>
              )}
            </Stack>
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
              <Stack.Item>
                <Button.Checkbox checked={reserveHeld} onClick={() => setReserveHeld(!reserveHeld)}>
                  Reserve held cargo
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox checked={partialGuardPayment} onClick={() => setPartialGuardPayment(!partialGuardPayment)}>
                  Guard partial payout
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
                target_area: targetArea,
                target_x: targetX,
                target_y: targetY,
                target_z: targetZ,
                target_radius: targetRadius,
                minimum_quality: minimumQuality,
                minimum_rarity: minimumRarity,
                destination_kind: destinationKind,
                destination,
                sabotage_mode: sabotageMode,
                legal: legal ? 1 : 0,
                public_contract: isPublic ? 1 : 0,
                pool_contract: poolContract ? 1 : 0,
                pool_corporation: poolCorporation,
                creator_confirm_required: creatorConfirm ? 1 : 0,
                reserve_held: reserveHeld ? 1 : 0,
                partial_guard_payment: partialGuardPayment ? 1 : 0,
                funding_business_id: fundingBusinessId,
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
        {!!contract.directAccessCode && (
          <LabeledList.Item label="Private access">
            {contract.directAccessCode}
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Deadline">{contract.deadline}</LabeledList.Item>
        <LabeledList.Item label="Requirement">
          {contract.deliveredAmount}/{contract.requiredAmount}, threshold{' '}
          {contract.requiredPercent}%
        </LabeledList.Item>
      </LabeledList>
      {!!contract.conditions?.length && (
        <Box mt={1}>
          {contract.conditions.map((condition, index) => (
            <Box key={`${condition.id}-${index}`} className="CyberpunkPanel__Muted">
              {condition.name}: {condition.deliveredAmount || 0}/
              {condition.requiredAmount || 1}
              {!!condition.requiredPercent && `, threshold ${condition.requiredPercent}%`}
              {!!condition.targetArea && `, area ${condition.targetArea}`}
              {!!condition.targetX && !!condition.targetY && `, coords ${condition.targetX}:${condition.targetY}:${condition.targetZ || 0}`}
              {!!condition.minimumQuality && `, quality ${condition.minimumQuality}+`}
              {!!condition.minimumRarity && `, rarity ${condition.minimumRarity}+`}
              {!!condition.destinationKind && `, destination ${condition.destination || condition.destinationKind}`}
              {!!condition.sabotageMode && `, mode ${condition.sabotageMode}`}
              {!!condition.partialPayment && ', partial guard payout'}
            </Box>
          ))}
        </Box>
      )}
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
