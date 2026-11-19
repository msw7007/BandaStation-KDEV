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
  itemType?: string;
  canWithdraw?: BooleanLike;
  price: number;
  basePrice?: number;
};

type Delivery = {
  id: number;
  item: string;
  amount: number;
  source: string;
  destination: string;
  cost: number;
  status: string;
  aiCourierStatus?: string;
  eta: string;
};

type WarehouseOption = {
  id: number;
  name: string;
  label: string;
  stock: number;
  canBuy: BooleanLike;
  canSell: BooleanLike;
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
    hasUnloadZone: BooleanLike;
    buyLinks: string;
    sellLinks: string;
    valid: BooleanLike;
    unloadValid: BooleanLike;
    validation: string;
  };
  employees: Employee[];
  pendingEmployees: Employee[];
  stock: StockEntry[];
  deliveries: Delivery[];
  savedObjects: number;
  savedAt?: string;
  loadedThisRound: BooleanLike;
  canSaveLoad: BooleanLike;
  canRestore: BooleanLike;
  canFinance: BooleanLike;
  canStock: BooleanLike;
  canStaff: BooleanLike;
  canContracts: BooleanLike;
  canAcceptEmployment: BooleanLike;
  history?: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  hasNeural: BooleanLike;
  terminalSize: string;
  terminalAnchored: BooleanLike;
  terminalArea: string;
  terminalBusinessArea: BooleanLike;
  businesses: Business[];
  business?: Business;
  warehouseOptions?: WarehouseOption[];
  testBench?: BooleanLike;
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
    terminalArea,
    terminalBusinessArea,
    businesses = [],
    business,
  } = data;

  return (
    <NtosWindow width={820} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Бизнес-терминал">
          <LabeledList>
            <LabeledList.Item label="Счёт на ID">
              {accountName || 'Счёт не найден'}
            </LabeledList.Item>
            <LabeledList.Item label="Личные средства">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Нейроинтерфейс">
              {hasNeural ? 'подключён' : 'требуется для регистрации и сейвлоада'}
            </LabeledList.Item>
            <LabeledList.Item label="Помещение">
              {terminalSize === 'program'
                ? 'нужен стационарный терминал в помещении'
                : `${terminalArea} / ${
                    terminalBusinessArea
                      ? 'торговое помещение'
                      : 'вне торговой зоны'
                  }`}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        {data.testBench ? (
          <Section
            title="Тестовый стенд"
            buttons={
              <Button
                icon="play"
                tooltip="Регистрирует местный бизнес, связывает площадку с автоматом и пополняет счета."
                onClick={() => act('prepare_test_bench')}
              >
                Подготовить стенд
              </Button>
            }
          >
            {business?.warehouse.valid
              ? 'Стенд готов. Образцы лежат на полу возле белого квадрата.'
              : 'Нажми «Подготовить стенд», чтобы начать. Понадобится ID со счётом.'}
          </Section>
        ) : (
          <>
          {terminalSize !== 'program' && (
            <BusinessCreation
              disabled={!hasNeural}
              terminalBusinessArea={!!terminalBusinessArea}
            />
          )}
          <Section title={`Доступные предприятия (${businesses.length})`}>
          {!businesses.length ? (
            <Box className="CyberpunkPanel__Muted">Доступных предприятий пока нет.</Box>
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
          </>
        )}

        {!!business && (data.testBench
          ? <TestBusinessBench business={business} />
          : <BusinessPanel business={business} />)}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const TestBusinessBench = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  const id = business.id;
  const canStock = !!business.canStock && !!business.warehouse.valid;
  return (
    <>
      <Section title="Склад и автомат">
        <Stack>
          <Stack.Item>
            <Button
              icon="box"
              disabled={!canStock}
              tooltip="Принимает свободно лежащие предметы с пола вокруг белого квадрата. Предметы в руках, на теле и в сумках остаются у владельцев."
              onClick={() => act('absorb_warehouse_items', { id })}
            >
              Сдать с пола 3×3
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="cash-register"
              disabled={!canStock}
              tooltip="Перекладывает со склада в автомат только совместимые с ним товары. Одежду и другие предметы можно забрать через выдачу."
              onClick={() => act('restock_vendors', { id })}
            >
              Загрузить автомат
            </Button>
          </Stack.Item>
        </Stack>
        {!business.stock.length && <Box mt={1}>На складе пусто.</Box>}
        <Table>
          {business.stock.map((stock) => (
            <Table.Row key={stock.name}>
              <Table.Cell>{stock.name}</Table.Cell>
              <Table.Cell collapsing>{stock.amount} шт.</Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="box-open"
                  disabled={!canStock || !stock.canWithdraw}
                  tooltip="Кладёт одну штуку на белый квадрат. Встань рядом с ним."
                  onClick={() => act('withdraw_warehouse_item', { id, item: stock.name, amount: 1 })}
                >
                  Выдать на площадку
                </Button>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
      <Section title="Налог с продажи">
        <LabeledList>
          <LabeledList.Item
            label="К уплате"
            buttons={
              <Button
                icon="landmark"
                disabled={!business.canFinance || business.taxDebt <= 0}
                tooltip="Оплачивает весь долг со счёта бизнеса."
                onClick={() => act('pay_taxes', { id, amount: business.taxDebt })}
              >
                Уплатить налог
              </Button>
            }
          >
            {formatMoney(business.taxDebt)} кр.
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <BusinessSnapshot business={business} />
      <Collapsible title="Дополнительные настройки">
        <BusinessSettings business={business} />
        <BusinessFinance business={business} />
        <BusinessWarehouse business={business} />
        <BusinessStaff business={business} />
      </Collapsible>
    </>
  );
};

const BusinessCreation = (props: {
  disabled: boolean;
  terminalBusinessArea: boolean;
}) => {
  const { act } = useBackend<Data>();
  const [name, setName] = useState('');
  const [direction, setDirection] = useState('general trade');
  const [registeredTo, setRegisteredTo] = useState('city');
  const [legal, setLegal] = useState(true);

  return (
    <Collapsible title="Зарегистрировать предприятие">
      <Stack vertical>
        <Stack.Item>
          <Input fluid placeholder="Название предприятия" value={name} onChange={setName} />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Направление деятельности"
            value={direction}
            onChange={setDirection}
          />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            placeholder="Орган регистрации"
            value={registeredTo}
            onChange={setRegisteredTo}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox checked={legal} onClick={() => setLegal(!legal)}>
            Легальная регистрация
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="file-signature"
            disabled={props.disabled || (legal && !props.terminalBusinessArea)}
            onClick={() =>
              act('create', {
                name,
                direction,
                registered_to: registeredTo,
                legal: legal ? 1 : 0,
              })
            }
          >
            Зарегистрировать на нейроинтерфейс
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
      {!!business.canAcceptEmployment && <BusinessInvite business={business} />}
      <BusinessSettings business={business} />
      <BusinessFinance business={business} />
      <BusinessWarehouse business={business} />
      <BusinessStaff business={business} />
      <BusinessSnapshot business={business} />
    </>
  );
};

const BusinessInvite = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;
  return (
    <Section
      title="Employment invite"
      buttons={
        <Button
          icon="user-check"
          onClick={() => act('accept_employee_invite', { id: business.id })}
        >
          Accept
        </Button>
      }
    >
      You have a pending invite to work for {business.name}.
    </Section>
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
  const { act, data } = useBackend<Data>();
  const { business } = props;
  const warehouseOptions = data.warehouseOptions || [];
  const [enabled, setEnabled] = useState(!!business.warehouse.enabled);
  const [autoRestock, setAutoRestock] = useState(!!business.warehouse.autoRestock);
  const [surplus, setSurplus] = useState(business.warehouse.surplusPercent || 0);
  const [markup, setMarkup] = useState(business.warehouse.markupPercent || 0);
  const [unloadZone, setUnloadZone] = useState(business.warehouse.unloadZone || 'unset');
  const [buyLinks, setBuyLinks] = useState(business.warehouse.buyLinks || '');
  const [sellLinks, setSellLinks] = useState(business.warehouse.sellLinks || '');
  const [item, setItem] = useState('goods');
  const [source, setSource] = useState('auto');
  const [amount, setAmount] = useState(1);
  const [prices, setPrices] = useState<Record<string, number>>({});
  const [buyer, setBuyer] = useState('civilian');
  const [adjustment, setAdjustment] = useState(0);
  const appendLink = (current: string, option: WarehouseOption) => {
    const existing = current
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean);
    const next = `${option.id}`;
    if (!existing.includes(next) && !existing.includes(option.name)) {
      existing.push(next);
    }
    return existing.join(', ');
  };

  return (
    <Collapsible title="Склад и доставки">
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
        {!!warehouseOptions.length && (
          <Stack.Item>
            <Section title="Доступные поставщики и покупатели">
              <Stack wrap>
                {warehouseOptions.map((option) => (
                  <Stack.Item key={option.id}>
                    <Button
                      icon="arrow-down"
                      disabled={!business.canStock || !option.canBuy}
                      tooltip={`Add ${option.label} as buy source. Stock entries: ${option.stock}`}
                      onClick={() => setBuyLinks(appendLink(buyLinks, option))}
                    >
                      Buy {option.label}
                    </Button>
                    <Button
                      icon="arrow-up"
                      disabled={!business.canStock || !option.canSell}
                      tooltip={`Add ${option.label} as sell destination. Stock entries: ${option.stock}`}
                      onClick={() => setSellLinks(appendLink(sellLinks, option))}
                    >
                      Sell
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
        )}
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
              {business.warehouse.hasUnloadZone ? business.warehouse.unloadZone : 'not linked'} /{' '}
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
            icon="map-marker-alt"
            disabled={!business.canStock}
            onClick={() => act('deploy_unload_zone', { id: business.id })}
          >
            Разметить площадку здесь
          </Button>
          <Button
            icon="clipboard-check"
            disabled={!business.canStock}
            onClick={() => act('validate_warehouse', { id: business.id })}
          >
            Проверить склад
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
            Применить настройки склада
          </Button>
          <Button
            icon="cash-register"
            disabled={!business.canStock}
            onClick={() => act('link_vendors', { id: business.id })}
          >
            Привязать автоматы помещения
          </Button>
          <Button
            icon="industry"
            disabled={!business.canStock}
            onClick={() => act('link_production', { id: business.id })}
          >
            Привязать производство
          </Button>
          <Button
            icon="boxes-stacked"
            disabled={!business.canStock || !business.warehouse.valid}
            onClick={() => act('restock_vendors', { id: business.id })}
          >
            Загрузить автоматы
          </Button>
          <Button
            icon="hand-holding-box"
            disabled={!business.canStock || !business.warehouse.valid}
            onClick={() => act('deposit_warehouse_item', { id: business.id })}
          >
            Сдать предмет из руки
          </Button>
          <Button
            icon="magnet"
            disabled={!business.canStock || !business.warehouse.valid}
            onClick={() => act('absorb_warehouse_items', { id: business.id })}
          >
            Сдать с пола 3×3
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
                Заказать доставку
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Table>
            <Table.Row header>
              <Table.Cell>Остатки</Table.Cell>
              <Table.Cell collapsing>Количество</Table.Cell>
              <Table.Cell>Цена за штуку</Table.Cell>
              <Table.Cell collapsing>Выдача</Table.Cell>
            </Table.Row>
            {business.stock.map((stock) => (
              <Table.Row key={stock.name}>
                <Table.Cell>{stock.name}</Table.Cell>
                <Table.Cell>{stock.amount}</Table.Cell>
                <Table.Cell>
                  <NumberInput
                    value={prices[stock.name] ?? stock.basePrice ?? 0}
                    minValue={0}
                    maxValue={1000000}
                    step={1}
                    disabled={!business.canFinance}
                    onChange={(price) =>
                      setPrices({ ...prices, [stock.name]: price })
                    }
                  />
                  <Button
                    disabled={!business.canFinance}
                    tooltip={`Civilian quote: ${formatMoney(stock.price)} cr. Set 0 for the default.`}
                    onClick={() =>
                      act('set_trade_price', {
                        id: business.id,
                        item: stock.name,
                        price: prices[stock.name] ?? stock.basePrice ?? 0,
                      })
                    }
                  >
                    Установить цену
                  </Button>
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    icon="box-open"
                    disabled={!business.canStock || !business.warehouse.valid || !stock.canWithdraw}
                    onClick={() =>
                      act('withdraw_warehouse_item', {
                        id: business.id,
                        item: stock.name,
                        amount: 1,
                      })
                    }
                  >
                    Выдать на площадку
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                value={buyer}
                placeholder="civilian, benn, ryaznov, starlight, or business ID"
                onChange={setBuyer}
              />
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                value={adjustment}
                minValue={-99}
                maxValue={500}
                step={1}
                unit="%"
                onChange={setAdjustment}
              />
              <Button
                disabled={!business.canFinance}
                onClick={() =>
                  act('set_buyer_adjustment', { id: business.id, buyer, adjustment })
                }
              >
                Set buyer adjustment
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Table>
            <Table.Row header>
              <Table.Cell>Delivery</Table.Cell>
              <Table.Cell collapsing>Cost</Table.Cell>
              <Table.Cell>Status</Table.Cell>
              <Table.Cell>Courier</Table.Cell>
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
                <Table.Cell>{delivery.aiCourierStatus || 'not requested'}</Table.Cell>
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
        {!!business.pendingEmployees?.length && (
          <Section title="Pending invites">
            {business.pendingEmployees.map((employee) => (
              <Stack key={employee.key} align="center">
                <Stack.Item grow>
                  {employee.name} / wage {employee.wage} cr
                </Stack.Item>
                <Stack.Item>
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
                    Cancel
                  </Button.Confirm>
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        )}
      </Stack>
    </Collapsible>
  );
};

const BusinessSnapshot = (props: { business: Business }) => {
  const { act } = useBackend<Data>();
  const { business } = props;

  return (
    <Collapsible title="Сохранение и загрузка">
      <LabeledList>
        <LabeledList.Item label="Объектов в снимке">
          {business.savedObjects}
        </LabeledList.Item>
        <LabeledList.Item label="Время сохранения">
          {business.savedAt || 'нет снимка'}
        </LabeledList.Item>
        <LabeledList.Item label="Загружено в этом раунде">
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
            Сохранить снимок
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button.Confirm
            icon="download"
            disabled={!business.canRestore}
            tooltip="Загрузить снимок можно один раз в следующем раунде."
            onClick={() => act('load', { id: business.id })}
          >
            Загрузить снимок
          </Button.Confirm>
        </Stack.Item>
      </Stack>
      <Collapsible title="История">
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
