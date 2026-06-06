// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type Employee = {
  key: string;
  name: string;
  wage: number;
  access: Record<string, BooleanLike>;
};

type StockEntry = {
  name: string;
  amount: number;
};

type Delivery = {
  id: number;
  item: string;
  amount: number;
  source: string;
  destination: string;
  cost: number;
  status: string;
  eta: string;
};

type Business = {
  id: number;
  name: string;
  direction: string;
  legal: BooleanLike;
  registeredTo: string;
  sizeClass: string;
  businessArea: string;
  owner: string;
  accountId: number;
  balance: number;
  debt: number;
  taxDebt: number;
  taxPaid: number;
  taxRate: number;
  premises: {
    valid: BooleanLike;
    validation: string;
  };
  warehouse: {
    enabled: BooleanLike;
    autoRestock: BooleanLike;
    surplusPercent: number;
    markupPercent: number;
    unloadZone: string;
    buyLinks: string;
    sellLinks: string;
    valid: BooleanLike;
    unloadValid: BooleanLike;
    validation: string;
  };
  employees: Employee[];
  stock: StockEntry[];
  deliveries: Delivery[];
  savedObjects: number;
  savedAt?: string;
  loadedThisRound: BooleanLike;
  canSaveLoad: BooleanLike;
  canFinance: BooleanLike;
  canStock: BooleanLike;
  canStaff: BooleanLike;
  canContracts: BooleanLike;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  hasNeural: BooleanLike;
  terminalSize: string;
  terminalAnchored: BooleanLike;
  businesses: Business[];
  business?: Business;
};

const accessLabels = [
  { key: 'terminal', label: 'Terminal' },
  { key: 'finance', label: 'Finance' },
  { key: 'stock', label: 'Stock' },
  { key: 'staff', label: 'Staff' },
  { key: 'contracts', label: 'Contracts' },
];

export const NtosBusinessTerminal = () => {
  const { act, data } = useBackend<Data>();
  const {
    accountName,
    accountBalance = 0,
    hasNeural,
    terminalSize,
    businesses = [],
    business,
  } = data;

  return (
    <NtosWindow width={820} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Business terminal">
          <LabeledList>
            <LabeledList.Item label="ID account">
              {accountName || 'No ID account'}
            </LabeledList.Item>
            <LabeledList.Item label="Personal balance">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Neural link">
              {hasNeural ? 'online' : 'required for creation/save/load'}
            </LabeledList.Item>
            <LabeledList.Item label="Premises">
              {terminalSize === 'program'
                ? 'business area required'
                : '17x17 business area'}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <BusinessCreation disabled={!hasNeural} />

        <Section title={`Accessible businesses (${businesses.length})`}>
          {!businesses.length ? (
            <Box className="CyberpunkPanel__Muted">No linked businesses.</Box>
          ) : (
            <Stack wrap>
              {businesses.map((entry) => (
                <Stack.Item key={entry.id}>
                  <Button
                    icon="building"
                    selected={business?.id === entry.id}
                    onClick={() => act('select', { id: entry.id })}
                  >
                    #{entry.id} {entry.name}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        {!!business && <BusinessPanel business={business} />}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const BusinessCreation = (props: { disabled: boolean }) => {
  const { act } = useBackend<Data>();
  const [name, setName] = useState('');
  const [direction, setDirection] = useState('general trade');
  const [registeredTo, setRegisteredTo] = useState('city');
  const [legal, setLegal] = useState(true);

  return (
    <Collapsible title="Create business">
      <Stack vertical>
        <Stack.Item>
          <Input fluid placeholder="Business name" value={name} onChange={setName} />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Business direction"
            value={direction}
            onChange={setDirection}
          />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Registration authority"
            value={registeredTo}
            onChange={setRegisteredTo}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox checked={legal} onClick={() => setLegal(!legal)}>
            Legal registration
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="file-signature"
            disabled={props.disabled}
            onClick={() =>
              act('create', {
                name,
                direction,
                registered_to: registeredTo,
                legal: legal ? 1 : 0,
              })
            }
          >
            Bind to neural interface
          </Button>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const BusinessPanel = (props: { business: Business }) => {
  const { business } = props;
  return (
    <>
      <BusinessSummary business={business} />
      <BusinessSettings business={business} />
      <BusinessFinance business={business} />
      <BusinessWarehouse business={business} />
      <BusinessStaff business={business} />
      <BusinessSnapshot business={business} />
    </>
  );
};

const BusinessSummary = (props: { business: Business }) => {
  const { business } = props;
  return (
    <Section title={`#${business.id} ${business.name}`}>
      <LabeledList>
        <LabeledList.Item label="Owner">{business.owner}</LabeledList.Item>
        <LabeledList.Item label="Direction">
          {business.direction}
        </LabeledList.Item>
        <LabeledList.Item label="Legality">
          {business.legal ? `legal / ${business.registeredTo}` : 'off-ledger'}
        </LabeledList.Item>
        <LabeledList.Item label="Business area">
          {business.businessArea} / {business.sizeClass}
        </LabeledList.Item>
        <LabeledList.Item label="Business account">
          #{business.accountId} / {formatMoney(business.balance)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Debt">
          {formatMoney(business.debt)} cr
        </LabeledList.Item>
        <LabeledList.Item label="Tax">
          debt {formatMoney(business.taxDebt)} cr / paid{' '}
          {formatMoney(business.taxPaid)} cr / {business.taxRate}%
        </LabeledList.Item>
        <LabeledList.Item label="Premises">
          {business.premises.valid ? 'valid' : 'invalid'} -{' '}
          {business.premises.validation}
        </LabeledList.Item>
        <LabeledList.Item label="Rights">
          finance {business.canFinance ? 'yes' : 'no'}, stock{' '}
          {business.canStock ? 'yes' : 'no'}, staff{' '}
          {business.canStaff ? 'yes' : 'no'}, contracts{' '}
          {business.canContracts ? 'yes' : 'no'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const BusinessSettings = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  const [name, setName] = useState(business.name);
  const [direction, setDirection] = useState(business.direction);
  const [registeredTo, setRegisteredTo] = useState(business.registeredTo);
  const [legal, setLegal] = useState(!!business.legal);

  return (
    <Collapsible title="Settings">
      <Stack vertical>
        <Stack.Item>
          <Input fluid value={name} onChange={setName} />
        </Stack.Item>
        <Stack.Item>
          <Input fluid value={direction} onChange={setDirection} />
        </Stack.Item>
        <Stack.Item>
          <Input fluid value={registeredTo} onChange={setRegisteredTo} />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox checked={legal} onClick={() => setLegal(!legal)}>
            Legal
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="save"
            onClick={() =>
              act('set_settings', {
                id: business.id,
                name,
                direction,
                registered_to: registeredTo,
                legal: legal ? 1 : 0,
              })
            }
          >
            Apply settings
          </Button>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const BusinessFinance = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  const [amount, setAmount] = useState(100);

  return (
    <Collapsible title="Finance">
      <Stack align="center">
        <Stack.Item>
          Amount{' '}
          <NumberInput
            value={amount}
            minValue={1}
            maxValue={100000}
            step={10}
            onChange={setAmount}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="arrow-down"
            disabled={!business.canFinance}
            onClick={() => act('deposit', { id: business.id, amount })}
          >
            Deposit
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="arrow-up"
            disabled={!business.canFinance}
            onClick={() => act('withdraw', { id: business.id, amount })}
          >
            Withdraw
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="landmark"
            disabled={!business.canFinance || business.taxDebt <= 0}
            onClick={() => act('pay_taxes', { id: business.id, amount })}
          >
            Pay tax
          </Button>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const BusinessWarehouse = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  const [enabled, setEnabled] = useState(!!business.warehouse.enabled);
  const [autoRestock, setAutoRestock] = useState(!!business.warehouse.autoRestock);
  const [surplus, setSurplus] = useState(business.warehouse.surplusPercent || 0);
  const [markup, setMarkup] = useState(business.warehouse.markupPercent || 0);
  const [unloadZone, setUnloadZone] = useState(business.warehouse.unloadZone || 'unset');
  const [buyLinks, setBuyLinks] = useState(business.warehouse.buyLinks || '');
  const [sellLinks, setSellLinks] = useState(business.warehouse.sellLinks || '');
  const [item, setItem] = useState('goods');
  const [source, setSource] = useState('external supplier');
  const [amount, setAmount] = useState(1);

  return (
    <Collapsible title="Warehouse and logistics">
      <Stack vertical>
        <Stack.Item>
          <Stack wrap>
            <Stack.Item>
              <Button.Checkbox
                checked={enabled}
                disabled={!business.canStock}
                onClick={() => setEnabled(!enabled)}
              >
                Warehouse enabled
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={autoRestock}
                disabled={!business.canStock}
                onClick={() => setAutoRestock(!autoRestock)}
              >
                Auto restock
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              Surplus{' '}
              <NumberInput
                value={surplus}
                minValue={0}
                maxValue={100}
                step={5}
                onChange={setSurplus}
              />
            </Stack.Item>
            <Stack.Item>
              Markup{' '}
              <NumberInput
                value={markup}
                minValue={-100}
                maxValue={500}
                step={5}
                onChange={setMarkup}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Input fluid value={unloadZone} onChange={setUnloadZone} />
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Buy links: business ids or names, comma-separated"
                value={buyLinks}
                onChange={setBuyLinks}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Sell links: business ids or names, comma-separated"
                value={sellLinks}
                onChange={setSellLinks}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Premises validator">
              {business.premises.valid ? 'valid' : 'invalid'} -{' '}
              {business.premises.validation}
            </LabeledList.Item>
            <LabeledList.Item label="Warehouse validator">
              {business.warehouse.valid ? 'valid' : 'invalid'} -{' '}
              {business.warehouse.validation}
            </LabeledList.Item>
            <LabeledList.Item label="Unload zone">
              {business.warehouse.unloadValid ? 'valid 3x3' : 'not valid'}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="ruler-combined"
            disabled={!business.canStock}
            onClick={() => act('validate_premises', { id: business.id })}
          >
            Validate premises
          </Button>
          <Button
            icon="clipboard-check"
            disabled={!business.canStock}
            onClick={() => act('validate_warehouse', { id: business.id })}
          >
            Validate warehouse
          </Button>
          <Button
            icon="warehouse"
            disabled={!business.canStock}
            onClick={() =>
              act('set_warehouse', {
                id: business.id,
                enabled: enabled ? 1 : 0,
                auto_restock: autoRestock ? 1 : 0,
                surplus_percent: surplus,
                markup_percent: markup,
                unload_zone: unloadZone,
                buy_links: buyLinks,
                sell_links: sellLinks,
              })
            }
          >
            Apply warehouse
          </Button>
          <Button
            icon="cash-register"
            disabled={!business.canStock}
            onClick={() => act('link_vendors', { id: business.id })}
          >
            Link area vendors
          </Button>
          <Button
            icon="industry"
            disabled={!business.canStock}
            onClick={() => act('link_production', { id: business.id })}
          >
            Link production
          </Button>
          <Button
            icon="boxes-stacked"
            disabled={!business.canStock || !business.warehouse.valid}
            onClick={() => act('restock_vendors', { id: business.id })}
          >
            Restock vendors
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Input fluid value={item} onChange={setItem} />
            </Stack.Item>
            <Stack.Item grow>
              <Input fluid value={source} onChange={setSource} />
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                value={amount}
                minValue={1}
                maxValue={1000}
                step={1}
                onChange={setAmount}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="paper-plane"
                disabled={
                  !business.canStock ||
                  !business.warehouse.enabled ||
                  !business.warehouse.valid
                }
                onClick={() =>
                  act('request_delivery', {
                    id: business.id,
                    item,
                    source,
                    amount,
                  })
                }
              >
                Request AVI
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Table>
            <Table.Row header>
              <Table.Cell>Stock</Table.Cell>
              <Table.Cell collapsing>Amount</Table.Cell>
            </Table.Row>
            {business.stock.map((stock) => (
              <Table.Row key={stock.name}>
                <Table.Cell>{stock.name}</Table.Cell>
                <Table.Cell>{stock.amount}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Stack.Item>
        <Stack.Item>
          <Table>
            <Table.Row header>
              <Table.Cell>Delivery</Table.Cell>
              <Table.Cell collapsing>Cost</Table.Cell>
              <Table.Cell>Status</Table.Cell>
              <Table.Cell collapsing>ETA</Table.Cell>
            </Table.Row>
            {business.deliveries.map((delivery) => (
              <Table.Row key={delivery.id}>
                <Table.Cell>
                  #{delivery.id} {delivery.amount}x {delivery.item} from{' '}
                  {delivery.source}
                </Table.Cell>
                <Table.Cell>{formatMoney(delivery.cost)} cr</Table.Cell>
                <Table.Cell>{delivery.status}</Table.Cell>
                <Table.Cell>{delivery.eta}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Stack.Item>
      </Stack>
    </Collapsible>
  );
};

const BusinessStaff = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  const [name, setName] = useState('');
  const [wage, setWage] = useState(0);

  return (
    <Collapsible title="Staff and access">
      <Stack vertical>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Input fluid placeholder="Character name" value={name} onChange={setName} />
            </Stack.Item>
            <Stack.Item>
              Wage{' '}
              <NumberInput
                value={wage}
                minValue={0}
                maxValue={100000}
                step={10}
                onChange={setWage}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="user-plus"
                disabled={!business.canStaff}
                onClick={() => act('add_employee', { id: business.id, name, wage })}
              >
                Hire
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        {business.employees.map((employee) => (
          <Section
            key={employee.key}
            title={employee.name}
            buttons={
              <Button.Confirm
                icon="user-times"
                disabled={!business.canStaff}
                onClick={() =>
                  act('remove_employee', {
                    id: business.id,
                    employee: employee.key,
                  })
                }
              >
                Remove
              </Button.Confirm>
            }
          >
            <Stack vertical>
              <Stack.Item>
                <Stack align="center">
                  <Stack.Item>Wage</Stack.Item>
                  <Stack.Item>
                    <NumberInput
                      value={employee.wage}
                      minValue={0}
                      maxValue={100000}
                      step={10}
                      onChange={(value) =>
                        act('set_employee_wage', {
                          id: business.id,
                          employee: employee.key,
                          wage: value,
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item>
                <Stack wrap>
                  {accessLabels.map((access) => (
                    <Stack.Item key={access.key}>
                      <Button.Checkbox
                        checked={!!employee.access?.[access.key]}
                        disabled={!business.canStaff}
                        onClick={() =>
                          act('toggle_employee_access', {
                            id: business.id,
                            employee: employee.key,
                            access: access.key,
                          })
                        }
                      >
                        {access.label}
                      </Button.Checkbox>
                    </Stack.Item>
                  ))}
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        ))}
      </Stack>
    </Collapsible>
  );
};

const BusinessSnapshot = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;

  return (
    <Collapsible title="Save and load">
      <LabeledList>
        <LabeledList.Item label="Saved objects">
          {business.savedObjects}
        </LabeledList.Item>
        <LabeledList.Item label="Saved age">
          {business.savedAt || 'not saved'}
        </LabeledList.Item>
        <LabeledList.Item label="Loaded this round">
          {business.loadedThisRound ? 'yes' : 'no'}
        </LabeledList.Item>
      </LabeledList>
      <Stack mt={1}>
        <Stack.Item>
          <Button
            icon="save"
            disabled={!business.canSaveLoad}
            onClick={() => act('save', { id: business.id })}
          >
            Save snapshot
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button.Confirm
            icon="download"
            disabled={!business.canSaveLoad || business.loadedThisRound}
            onClick={() => act('load', { id: business.id })}
          >
            Load once
          </Button.Confirm>
        </Stack.Item>
      </Stack>
      <Collapsible title="History">
        {(business.history || []).map((entry, index) => (
          <Box key={index} className="CyberpunkPanel__Muted">
            {entry}
          </Box>
        ))}
      </Collapsible>
    </Collapsible>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
