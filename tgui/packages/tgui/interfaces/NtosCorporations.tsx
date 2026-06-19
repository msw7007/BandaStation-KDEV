// CYBERPUNK BUILD - rebuild and delete before release
import type { ReactNode } from 'react';
import { useState } from 'react';
import {
  Box,
  Button,
  Icon,
  Input,
  LabeledList,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type CorporateData = {
  type: string;
  amount: number;
};

type CorporateTechnology = {
  id: string;
  name: string;
  tier: number;
  cost: number;
  baseCost: number;
  discount: number;
  prereq?: string;
  prereqIds: string[];
  unlockIds: string[];
  dataType: string;
  description: string;
  unlocked: BooleanLike;
  canUnlock: BooleanLike;
};

type CorporateSubsidiary = {
  id: string;
  name: string;
  manufacturer: string;
  focus: string;
  dataType: string;
};

type CorporateEdict = {
  id: string;
  name: string;
  level: number;
  description: string;
  active: BooleanLike;
  locked: BooleanLike;
};

type CorporateService = {
  id: string;
  label: string;
  description: string;
  icon: string;
  enabled: BooleanLike;
};

type CorporateServiceRequest = {
  id: number;
  service: string;
  customer: string;
  cost: number;
  status: string;
  age: string;
};

type CorporateContract = {
  id: number;
  title: string;
  type: string;
  target: string;
  status: string;
  payment: number;
  deadline: string;
};

type CorporateVendor = {
  name: string;
  area: string;
  sales: number;
  revenue: number;
  lastProduct?: string;
};

type CorporateProfitRecord = {
  source: string;
  kind: string;
  count: number;
  gross: number;
  net: number;
  tax: number;
  lastAmount: number;
  lastNet: number;
  lastTax: number;
  lastSeen?: string;
};

type GovernmentTaxMonitor = {
  businesses: {
    id: number;
    name: string;
    owner: string;
    legal: BooleanLike;
    taxDebt: number;
    taxPaid: number;
    balance: number;
    debt: number;
    area: string;
    taxRate: number;
    overdue: BooleanLike;
  }[];
  corporations: {
    id: string;
    name: string;
    taxDebt: number;
    taxPaid: number;
    balance: number;
    debt: number;
    taxRate: number;
    overdue: BooleanLike;
  }[];
  accounts: {
    id: number;
    name: string;
    balance: number;
    debt: number;
  }[];
  housing: {
    areaKey: string;
    area: string;
    rent: number;
    apartments: number;
  }[];
  businessDefaultTaxRate: number;
};

type Corporation = {
  id: string;
  name: string;
  group: string;
  direction: string;
  combatDoctrine: string;
  hidden: BooleanLike;
  subsidiaries: CorporateSubsidiary[];
  level: number;
  experience: number;
  nextLevelAt?: number;
  researchPoints: number;
  influence: number;
  accountId: number;
  balance: number;
  debt: number;
  taxDebt: number;
  taxPaid: number;
  serviceAutoEnabled: BooleanLike;
  researchData: CorporateData[];
  technologies: CorporateTechnology[];
  edicts: CorporateEdict[];
  subscribers: number;
  subscriptionCost: number;
  serviceMedical: BooleanLike;
  serviceTechnical: BooleanLike;
  serviceDelivery: BooleanLike;
  services: CorporateService[];
  serviceRequests: CorporateServiceRequest[];
  contracts: CorporateContract[];
  vendors: CorporateVendor[];
  profitRecords: CorporateProfitRecord[];
  taxMonitor?: GovernmentTaxMonitor;
  foreignTechBonus: number;
  stolenTechnologies: {
    id: string;
    name: string;
    source: string;
    sourceName: string;
  }[];
  stolenProgress: {
    id: string;
    name: string;
    source: string;
    sourceName: string;
    progress: number;
  }[];
  history: string[];
};

type Data = {
  accountName?: string;
  accountBalance: number;
  corporations: Corporation[];
  selected?: Corporation;
};

const displayTabs = [
  ['state', 'Состояния'],
  ['services', 'Услуги'],
  ['research', 'Изучение и реверс'],
  ['edicts', 'Эдикты'],
  ['contracts', 'Контракты'],
];

const displayGovernmentTabs = [
  ['state', 'Состояния'],
  ['taxes', 'Налоги'],
  ['contracts', 'Контракты'],
];
const contractTypes = [
  ['delivery', 'Доставка'],
  ['repair', 'Ремонт'],
  ['build', 'Стройка'],
  ['mining', 'Добыча'],
  ['sabotage', 'Саботаж'],
];

export const NtosCorporations = () => {
  const { act, data } = useBackend<Data>();
  const { accountName, accountBalance = 0, corporations = [], selected } = data;
  const visibleCorporation = selected || corporations[0];
  const [activeTab, setActiveTab] = useState('state');
  const [dataType, setDataType] = useState('general');
  const [amount, setAmount] = useState('10');
  const availableTabs =
    visibleCorporation?.id === 'government' ? displayGovernmentTabs : displayTabs;
  const activeCorporationTab = availableTabs.some(([id]) => id === activeTab)
    ? activeTab
    : 'state';

  return (
    <NtosWindow width={980} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide CorporateInterface">
        <div className="StyleGuide__header CorporateInterface__header">
          <div>
            <div className="CorporateInterface__eyebrow">КОРПОРАТИВНЫЙ РЕЕСТР</div>
            <h1>Корпорации</h1>
          </div>
          <div className="CorporateInterface__account">
            <span>{accountName || 'Нет ID-счета'}</span>
            <b>{formatCredits(accountBalance)}</b>
            <em>{corporations.length} сущн.</em>
          </div>
        </div>

        <div className="CorporateInterface__layout">
          <aside className="StyleGuide__blockShell CorporateInterface__side">
            <div className="StyleGuide__blockTitle">Сущности</div>
            <div className="CorporateInterface__entityList">
              {!corporations.length ? (
                <div className="StyleGuide__placeholder">Корпораций нет.</div>
              ) : (
                corporations.map((corporation) => (
                  <button
                      key={corporation.id}
                      type="button"
                      className={[
                        'CorporateInterface__entityButton',
                      visibleCorporation?.id === corporation.id && 'active',
                      corporation.hidden && 'restricted',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={() =>
                      act('select', { corporation_id: corporation.id })
                    }
                  >
                    <span>{corporation.name}</span>
                    <small>{corporation.group}</small>
                  </button>
                ))
              )}
            </div>
          </aside>

          <main className="CorporateInterface__main">
            {!visibleCorporation ? (
              <div className="StyleGuide__blockShell">
                <div className="StyleGuide__placeholder">
                  В корпоративном реестре нет активных сущностей.
                </div>
              </div>
            ) : (
              <>
                <CorporationSummary corporation={visibleCorporation} />
                <div className="StyleGuide__topTabs CorporateInterface__tabs">
                  {availableTabs.map(([id, label]) => (
                    <button
                      key={id}
                      type="button"
                      className={activeCorporationTab === id ? 'active' : ''}
                      onClick={() => setActiveTab(id)}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <CorporateTab
                  activeTab={activeCorporationTab}
                  corporation={visibleCorporation}
                  dataType={dataType}
                  amount={amount}
                  setDataType={setDataType}
                  setAmount={setAmount}
                />
              </>
            )}
          </main>
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

function CorporationSummary(props: { corporation: Corporation }) {
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__summary">
      <div className="StyleGuide__blockTitle">{corporation.name}</div>
    </div>
  );
}

function CorporateTab(props: {
  activeTab: string;
  corporation: Corporation;
  dataType: string;
  amount: string;
  setDataType: (value: string) => void;
  setAmount: (value: string) => void;
}) {
  switch (props.activeTab) {
    case 'services':
      return <ServicesTab corporation={props.corporation} />;
    case 'research':
      return (
        <ResearchTab
          corporation={props.corporation}
          dataType={props.dataType}
          amount={props.amount}
          setDataType={props.setDataType}
          setAmount={props.setAmount}
        />
      );
    case 'edicts':
      return <EdictsTab corporation={props.corporation} />;
    case 'contracts':
      return <ContractsTab corporation={props.corporation} />;
    case 'taxes':
      return <GovernmentTaxesTab corporation={props.corporation} />;
    default:
      return <StateTab corporation={props.corporation} />;
  }
}

function StateTab(props: { corporation: Corporation }) {
  const { corporation } = props;
  if (corporation.id === 'government') {
    return <GovernmentStateTab corporation={corporation} />;
  }

  return (
    <div className="CorporateInterface__tabGrid">
      <MetricPanel title="Состояние">
        <LabeledList>
          <LabeledList.Item label="Уровень">{corporation.level}/5</LabeledList.Item>
          <LabeledList.Item label="Опыт">
            {corporation.experience}
            {corporation.nextLevelAt ? ` / ${corporation.nextLevelAt}` : ''}
          </LabeledList.Item>
          <LabeledList.Item label="Исследования">
            {corporation.researchPoints} RP
          </LabeledList.Item>
          <LabeledList.Item label="Подписчики">
            {corporation.subscribers || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Чужие технологии">
            скидка {corporation.foreignTechBonus || 0}%
          </LabeledList.Item>
        </LabeledList>
      </MetricPanel>

      <MetricPanel title="Финансы">
        <LabeledList>
          <LabeledList.Item label="Счет">#{corporation.accountId}</LabeledList.Item>
          <LabeledList.Item label="Средства">
            <MoneyValue amount={corporation.balance} />
          </LabeledList.Item>
          <LabeledList.Item label="Долг">
            {formatCredits(corporation.debt)}
          </LabeledList.Item>
          <LabeledList.Item label="Долг по налогам">
            {formatCredits(corporation.taxDebt || 0)}
          </LabeledList.Item>
          <LabeledList.Item label="Налогов уплачено">
            {formatCredits(corporation.taxPaid || 0)}
          </LabeledList.Item>
        </LabeledList>
      </MetricPanel>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Дочерние структуры</div>
        {!corporation.subsidiaries?.length ? (
          <div className="StyleGuide__placeholder">Дочерних структур нет.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Название</Table.Cell>
              <Table.Cell>Фокус</Table.Cell>
              <Table.Cell collapsing>Производитель</Table.Cell>
              <Table.Cell collapsing>Данные</Table.Cell>
            </Table.Row>
            {corporation.subsidiaries.map((subsidiary) => (
              <Table.Row key={subsidiary.id}>
                <Table.Cell>{subsidiary.name}</Table.Cell>
                <Table.Cell>{subsidiary.focus}</Table.Cell>
                <Table.Cell>{subsidiary.manufacturer}</Table.Cell>
                <Table.Cell>{subsidiary.dataType}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>

      <ProfitPanel corporation={corporation} />

      <HistoryPanel corporation={corporation} />
    </div>
  );
}

function GovernmentStateTab(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;
  const monitor = corporation.taxMonitor;
  const transferOptions = getTransferOptions(monitor);
  const [sourceAccount, setSourceAccount] = useState('');
  const [targetAccount, setTargetAccount] = useState('');
  const [transferAmount, setTransferAmount] = useState('100');
  const selectedSource = transferOptions.some((option) => option.value === sourceAccount)
    ? sourceAccount
    : transferOptions[0]?.value || '';
  const selectedTarget = transferOptions.some((option) => option.value === targetAccount)
    ? targetAccount
    : transferOptions[1]?.value || transferOptions[0]?.value || '';
  const sourceRef = parseTransferRef(selectedSource);
  const targetRef = parseTransferRef(selectedTarget);

  return (
    <div className="CorporateInterface__tabGrid">
      <MetricPanel title="Финансы правительства">
        <LabeledList>
          <LabeledList.Item label="Городской счет">#{corporation.accountId}</LabeledList.Item>
          <LabeledList.Item label="Средства">
            {formatCredits(corporation.balance)}
          </LabeledList.Item>
          <LabeledList.Item label="Корпораций под учетом">
            {monitor?.corporations?.length || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Бизнесов под учетом">
            {monitor?.businesses?.length || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Счетов под учетом">
            {monitor?.accounts?.length || 0}
          </LabeledList.Item>
        </LabeledList>
      </MetricPanel>

      <div className="StyleGuide__blockShell">
        <div className="StyleGuide__blockTitle">Принудительный перевод</div>
        <div className="CorporateInterface__transferGrid">
          <label className="CorporateInterface__field CorporateInterface__field--wide">
            <span>От кого</span>
            <CorporateDropdown
              selected={selectedSource}
              options={transferOptions}
              onSelected={setSourceAccount}
              displayText={transferLabel(transferOptions, selectedSource)}
            />
          </label>
          <label className="CorporateInterface__field CorporateInterface__field--wide">
            <span>Куда</span>
            <CorporateDropdown
              selected={selectedTarget}
              options={transferOptions}
              onSelected={setTargetAccount}
              displayText={transferLabel(transferOptions, selectedTarget)}
            />
          </label>
          <label className="CorporateInterface__field">
            <span>Сколько</span>
            <Input value={transferAmount} placeholder="сумма" onChange={setTransferAmount} />
          </label>
          <Button
            icon="right-left"
            className="StyleGuide__cutButton StyleGuide__cutButton--red-dark CorporateInterface__compactButton"
            disabled={!sourceRef.kind || !targetRef.kind || selectedSource === selectedTarget}
            onClick={() =>
              act('government_transfer', {
                corporation_id: corporation.id,
                source_kind: sourceRef.kind,
                source_id: sourceRef.id,
                target_kind: targetRef.kind,
                target_id: targetRef.id,
                amount: Number(transferAmount) || 0,
              })
            }
          >
            Перевод
          </Button>
        </div>
        <div className="CorporateInterface__hint">
          Выберите активные счета источника и получателя.
        </div>
      </div>

      <ProfitPanel corporation={corporation} />

      <GovernmentTaxMonitorPanel corporation={corporation} />
    </div>
  );
}

function getTransferOptions(monitor?: GovernmentTaxMonitor) {
  const options: { value: string; displayText: string }[] = [
    {
      value: 'civil:',
      displayText: 'Городской счет',
    },
  ];
  for (const corporation of monitor?.corporations || []) {
    options.push({
      value: `corporation:${corporation.id}`,
      displayText: `${corporation.name} / ${formatCredits(corporation.balance || 0)}`,
    });
  }
  for (const business of monitor?.businesses || []) {
    options.push({
      value: `business:${business.id}`,
      displayText: `${business.name} / ${formatCredits(business.balance || 0)}`,
    });
  }
  for (const account of monitor?.accounts || []) {
    options.push({
      value: `account:${account.id}`,
      displayText: `#${account.id} / ${account.name} / ${formatCredits(account.balance || 0)}`,
    });
  }
  return options;
}

function parseTransferRef(value: string) {
  const [kind = '', id = ''] = value.split(':');
  return { kind, id };
}

function transferLabel(
  options: { value: string; displayText: string }[],
  value: string,
) {
  return options.find((option) => option.value === value)?.displayText || value;
}

function CorporateDropdown(props: {
  options: { value: string; displayText: string }[];
  selected: string;
  displayText: string;
  onSelected: (value: string) => void;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div
      className="StyleGuide__dropdown CorporateInterface__dropdown"
      onMouseDown={(event) => event.stopPropagation()}
    >
      <button
        type="button"
        className="StyleGuide__dropdownControl"
        onClick={() => setOpen(!open)}
      >
        <span>{props.displayText || '-'}</span>
        <Icon name={open ? 'angle-up' : 'angle-down'} />
      </button>
      {open && (
        <div className="StyleGuide__dropdownMenu">
          {props.options.map((option) => (
            <button
              key={option.value}
              type="button"
              className={props.selected === option.value ? 'selected' : ''}
              onClick={() => {
                props.onSelected(option.value);
                setOpen(false);
              }}
            >
              {option.displayText}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ServicesTab(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;
  const services = corporation.services || [];
  const enabledServices = services.filter((service) => service.enabled);

  return (
    <div className="CorporateInterface__tabGrid">
      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Состояние услуг</div>
        <LabeledList>
          <LabeledList.Item label="Цена подписчика">
            {formatCredits(corporation.subscriptionCost || 0)}
          </LabeledList.Item>
          <LabeledList.Item label="Включено">
            {enabledServices.length
              ? enabledServices.map((service) => service.label).join(', ')
              : 'Нет активного эдикта услуг'}
          </LabeledList.Item>
          <LabeledList.Item label="Режим">
            {corporation.serviceAutoEnabled ? 'автоматический' : 'очередь'}
          </LabeledList.Item>
        </LabeledList>
        <div className="CorporateInterface__serviceControls">
          <button
            type="button"
            className="CorporateInterface__serviceToggle"
            onClick={() =>
              act('toggle_service_auto', {
                corporation_id: corporation.id,
              })
            }
          >
            {corporation.serviceAutoEnabled ? 'Автоуслуги: вкл.' : 'Автоуслуги: выкл.'}
          </button>
        </div>
        <div className="CorporateInterface__subTitle">Каталог</div>
        {!services.length ? (
          <div className="StyleGuide__placeholder">
            У этой корпорации пока нет каталога услуг.
          </div>
        ) : (
          <div className="CorporateInterface__serviceRow">
            {services.map((service) => (
              <Tooltip key={service.id} content={service.description} position="bottom">
                <button
                  type="button"
                  className={[
                    'CorporateInterface__serviceOption',
                    service.enabled ? 'available' : 'locked',
                  ].join(' ')}
                >
                  <b>{service.label}</b>
                  <span>{service.enabled ? 'Доступно' : 'Закрыто'}</span>
                </button>
              </Tooltip>
            ))}
          </div>
        )}
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Очередь</div>
        {!corporation.serviceRequests?.length ? (
          <div className="StyleGuide__placeholder">Заявок на услуги нет.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Услуга</Table.Cell>
              <Table.Cell>Клиент</Table.Cell>
              <Table.Cell>Статус</Table.Cell>
              <Table.Cell collapsing>Цена</Table.Cell>
              <Table.Cell collapsing>Возраст</Table.Cell>
              <Table.Cell collapsing>Действия</Table.Cell>
            </Table.Row>
            {corporation.serviceRequests.map((request) => (
              <Table.Row key={request.id}>
                <Table.Cell>{request.service}</Table.Cell>
                <Table.Cell>{request.customer}</Table.Cell>
                <Table.Cell>{formatStatus(request.status)}</Table.Cell>
                <Table.Cell>{formatCredits(request.cost)}</Table.Cell>
                <Table.Cell>{request.age}</Table.Cell>
                <Table.Cell>
                  <Button
                    icon="check"
                    disabled={request.status !== 'created'}
                    onClick={() =>
                      act('complete_service_request', {
                        corporation_id: corporation.id,
                        request_id: request.id,
                      })
                    }
                  />
                  <Button
                    icon="xmark"
                    disabled={request.status !== 'created'}
                    onClick={() =>
                      act('cancel_service_request', {
                        corporation_id: corporation.id,
                        request_id: request.id,
                      })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Автоматы</div>
        {!corporation.vendors?.length ? (
          <div className="StyleGuide__placeholder">
            Зарегистрированных корпоративных автоматов нет.
          </div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Автомат</Table.Cell>
              <Table.Cell>Зона</Table.Cell>
              <Table.Cell collapsing>Продажи</Table.Cell>
              <Table.Cell collapsing>Выручка</Table.Cell>
              <Table.Cell>Последний товар</Table.Cell>
            </Table.Row>
            {corporation.vendors.map((vendor, index) => (
              <Table.Row key={`${vendor.name}-${index}`}>
                <Table.Cell>{vendor.name}</Table.Cell>
                <Table.Cell>{vendor.area}</Table.Cell>
                <Table.Cell>{vendor.sales || 0}</Table.Cell>
                <Table.Cell>{formatCredits(vendor.revenue || 0)}</Table.Cell>
                <Table.Cell>{vendor.lastProduct || '-'}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>
    </div>
  );
}

function ResearchTab(props: {
  corporation: Corporation;
  dataType: string;
  amount: string;
  setDataType: (value: string) => void;
  setAmount: (value: string) => void;
}) {
  const { act } = useBackend<Data>();
  const { corporation, dataType, amount, setDataType, setAmount } = props;
  const amountNumber = Number(amount) || 0;
  const [technologyView, setTechnologyView] = useState('available');

  return (
    <div className="CorporateInterface__tabGrid">
      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Исследовательские данные</div>
        <Stack mb={1}>
          <Stack.Item grow>
            <Input fluid value={dataType} placeholder="тип данных" onChange={setDataType} />
          </Stack.Item>
          <Stack.Item width="90px">
            <Input fluid value={amount} placeholder="кол-во" onChange={setAmount} />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="plus"
              disabled={!amountNumber}
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-light"
              onClick={() =>
                act('test_activity', {
                  corporation_id: corporation.id,
                  data_type: dataType,
                  amount: amountNumber,
                })
              }
            >
              Тест данных
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="coins"
              disabled={!corporation.researchPoints}
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              onClick={() =>
                act('exchange_research', {
                  corporation_id: corporation.id,
                  amount: Math.min(10, corporation.researchPoints),
                })
              }
            >
              Обмен
            </Button>
          </Stack.Item>
        </Stack>
        {!corporation.researchData?.length ? (
          <div className="StyleGuide__placeholder">Сохраненных данных нет.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Тип</Table.Cell>
              <Table.Cell collapsing>Кол-во</Table.Cell>
              <Table.Cell collapsing>Действия</Table.Cell>
            </Table.Row>
            {corporation.researchData.map((entry) => (
              <Table.Row key={entry.type}>
                <Table.Cell>{entry.type}</Table.Cell>
                <Table.Cell>{entry.amount}</Table.Cell>
                <Table.Cell>
                  <Button
                    icon="flask"
                    onClick={() =>
                      act('convert_data', {
                        corporation_id: corporation.id,
                        data_type: entry.type,
                        amount: entry.amount,
                      })
                    }
                  >
                    Конвертировать
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Технологические узлы</div>
        <CorporateTechnologyWeb
          corporation={corporation}
          activeView={technologyView}
          setActiveView={setTechnologyView}
        />
      </div>

      <ForeignTechnologyPanel corporation={corporation} />
    </div>
  );
}

function CorporateTechnologyWeb(props: {
  corporation: Corporation;
  activeView: string;
  setActiveView: (value: string) => void;
}) {
  const { act } = useBackend<Data>();
  const { corporation, activeView, setActiveView } = props;
  const technologies = corporation.technologies || [];
  const technologyById = Object.fromEntries(
    technologies.map((technology) => [technology.id, technology]),
  );
  const visibleTechnologies = technologies.filter((technology) => {
    const prereqDone = (technology.prereqIds || []).every(
      (id) => !!technologyById[id]?.unlocked,
    );
    if (activeView === 'researched') {
      return !!technology.unlocked;
    }
    if (activeView === 'future') {
      return !technology.unlocked && !prereqDone;
    }
    return !technology.unlocked && prereqDone;
  });

  return (
    <div className="CorporateInterface__techWeb">
      <div className="CorporateInterface__techWebHeader">
        <div>
          <b>{corporation.researchPoints} RP</b>
          <span>
            Бонус реверса чужих технологий: скидка {corporation.foreignTechBonus || 0}%
          </span>
        </div>
        <div className="CorporateInterface__techFilters">
          {[
            ['available', 'Доступно'],
            ['researched', 'Изучено'],
            ['future', 'Будущее'],
          ].map(([id, label]) => (
            <button
              key={id}
              type="button"
              className={activeView === id ? 'active' : ''}
              onClick={() => setActiveView(id)}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {!visibleTechnologies.length ? (
        <div className="StyleGuide__placeholder">
          В этом режиме нет технологических узлов.
        </div>
      ) : (
        <div className="CorporateInterface__nodeGrid">
          {visibleTechnologies.map((technology) => (
            <CorporateTechnologyNode
              key={technology.id}
              corporation={corporation}
              technology={technology}
              technologyById={technologyById}
              onResearch={() =>
                act('unlock_technology', {
                  corporation_id: corporation.id,
                  technology_id: technology.id,
                })
              }
            />
          ))}
        </div>
      )}
    </div>
  );
}

function CorporateTechnologyNode(props: {
  corporation: Corporation;
  technology: CorporateTechnology;
  technologyById: Record<string, CorporateTechnology>;
  onResearch: () => void;
}) {
  const { corporation, technology, technologyById, onResearch } = props;
  const prereqs = (technology.prereqIds || [])
    .map((id) => technologyById[id]?.name || id)
    .join(', ');
  const unlocks = (technology.unlockIds || [])
    .map((id) => technologyById[id]?.name || id)
    .join(', ');
  const prereqDone = (technology.prereqIds || []).every(
    (id) => !!technologyById[id]?.unlocked,
  );
  const progressValue = technology.cost
    ? Math.min(1, corporation.researchPoints / technology.cost)
    : 1;
  const descriptionTooltip = [
    technology.description,
    unlocks ? `Открывает: ${unlocks}` : '',
  ]
    .filter(Boolean)
    .join('\n');

  return (
    <div
      className={[
        'CorporateInterface__techNode',
        technology.unlocked && 'researched',
        !technology.unlocked && prereqDone && 'available',
        !technology.unlocked && !prereqDone && 'future',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <div className="CorporateInterface__techNodeBody">
        <div className="CorporateInterface__techNodeMeter">
          <span style={{ height: `${Math.round(progressValue * 100)}%` }} />
        </div>
        <div className="CorporateInterface__techNodeContent">
          <Tooltip content={descriptionTooltip} position="bottom">
            <div className="CorporateInterface__techNodeTitle">
              <span>T{technology.tier}</span>
              <b>{technology.name}</b>
            </div>
          </Tooltip>
          <div className="CorporateInterface__techNodeMeta">
            <span>Данные: {technology.dataType || 'общие'}</span>
            {!!technology.discount && <span>Скидка: {technology.discount} RP</span>}
            {!!prereqs && <span>Требует: {prereqs}</span>}
          </div>
        </div>
        <Tooltip content={unlocks || 'Прямых открытий нет'} position="left">
          <Button
            icon={technology.unlocked ? 'check' : 'lightbulb'}
            disabled={!!technology.unlocked || !technology.canUnlock}
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={onResearch}
          >
            {technology.unlocked ? 'Готово' : 'Изучить'}
          </Button>
        </Tooltip>
      </div>
      <div className="CorporateInterface__techNodeCost">
        RP {Math.min(corporation.researchPoints, technology.cost)}/{technology.cost}
      </div>
    </div>
  );
}

function ForeignTechnologyPanel(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">Реверс-инжиниринг</div>
      {!corporation.stolenTechnologies?.length &&
      !corporation.stolenProgress?.length ? (
        <div className="StyleGuide__placeholder">Записей чужих технологий нет.</div>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Технология</Table.Cell>
            <Table.Cell>Источник</Table.Cell>
            <Table.Cell>Прогресс</Table.Cell>
          </Table.Row>
          {(corporation.stolenTechnologies || []).map((entry) => (
            <Table.Row key={`stolen-${entry.id}`}>
              <Table.Cell>{entry.name || entry.id}</Table.Cell>
              <Table.Cell>{entry.sourceName || entry.source}</Table.Cell>
              <Table.Cell>скопировано</Table.Cell>
            </Table.Row>
          ))}
          {(corporation.stolenProgress || []).map((entry) => (
            <Table.Row key={`progress-${entry.source}-${entry.id}`}>
              <Table.Cell>{entry.name || entry.id}</Table.Cell>
              <Table.Cell>{entry.sourceName || entry.source}</Table.Cell>
              <Table.Cell>
                <Stack align="center">
                  <Stack.Item grow>{entry.progress}%</Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="flask"
                      disabled={corporation.researchPoints < 20}
                      onClick={() =>
                        act('invest_foreign_tech', {
                          corporation_id: corporation.id,
                          source: entry.source,
                          technology_id: entry.id,
                          points: 20,
                        })
                      }
                    >
                      +1%
                    </Button>
                  </Stack.Item>
                </Stack>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </div>
  );
}

function EdictsTab(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">Эдикты</div>
      {!corporation.edicts?.length ? (
        <div className="StyleGuide__placeholder">Эдиктов для этой сущности пока нет.</div>
      ) : (
        <div className="CorporateInterface__edictGrid">
          {corporation.edicts.map((edict) => (
            <Tooltip key={edict.id} content={edict.description} position="bottom">
              <button
                type="button"
                disabled={!!edict.active || !!edict.locked}
                className={[
                  'CorporateInterface__edictSwitch',
                  edict.active && 'active',
                  edict.locked && 'locked',
                ]
                  .filter(Boolean)
                  .join(' ')}
                onClick={() =>
                  act('choose_edict', {
                    corporation_id: corporation.id,
                    edict_id: edict.id,
                  })
                }
              >
                <span>L{edict.level}</span>
                <b>{edict.name}</b>
              </button>
            </Tooltip>
          ))}
        </div>
      )}
    </div>
  );
}

function ContractsTab(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;

  return (
    <div className="CorporateInterface__tabGrid">
      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Пул контрактов</div>
        <div className="CorporateInterface__actions">
          {contractTypes.map(([type, label]) => (
            <Button
              key={type}
              icon="file-signature"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              onClick={() =>
                act('create_pool_contract', {
                  corporation_id: corporation.id,
                  contract_type: type,
                })
              }
            >
              {label}
            </Button>
          ))}
          {corporation.id !== 'government' && (
            <Button
              icon="coins"
              disabled={!corporation.taxDebt}
              className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
              onClick={() =>
                act('pay_corporate_taxes', {
                  corporation_id: corporation.id,
                  amount: corporation.taxDebt || 0,
                })
              }
            >
              Оплатить налоги
            </Button>
          )}
        </div>
        {!corporation.contracts?.length ? (
          <div className="StyleGuide__placeholder">Корпоративных контрактов нет.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Контракт</Table.Cell>
              <Table.Cell>Тип</Table.Cell>
              <Table.Cell>Статус</Table.Cell>
              <Table.Cell collapsing>Оплата</Table.Cell>
              <Table.Cell collapsing>Срок</Table.Cell>
            </Table.Row>
            {corporation.contracts.map((contract) => (
              <Table.Row key={contract.id}>
                <Table.Cell>{contract.title}</Table.Cell>
                <Table.Cell>{formatContractType(contract.type)}</Table.Cell>
                <Table.Cell>{formatStatus(contract.status)}</Table.Cell>
                <Table.Cell>{formatCredits(contract.payment)}</Table.Cell>
                <Table.Cell>{compactDeadline(contract.deadline)}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>
    </div>
  );
}

function GovernmentTaxesTab(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;
  const monitor = corporation.taxMonitor;
  const corporationOptions = (monitor?.corporations || []).map((entry) => ({
    value: entry.id,
    displayText: `${entry.name} / ${entry.taxRate || 0}%`,
  }));
  const businessOptions = (monitor?.businesses || []).map((entry) => ({
    value: String(entry.id),
    displayText: `${entry.name} / ${entry.taxRate || 0}%`,
  }));
  const housingOptions = (monitor?.housing || []).map((entry) => ({
    value: entry.areaKey,
    displayText: `${entry.area} / ${formatCredits(entry.rent || 0)}`,
  }));
  const [selectedCorporation, setSelectedCorporation] = useState('');
  const [corporationTax, setCorporationTax] = useState('');
  const [selectedBusiness, setSelectedBusiness] = useState('');
  const [businessTax, setBusinessTax] = useState('');
  const [defaultBusinessTax, setDefaultBusinessTax] = useState(
    String(monitor?.businessDefaultTaxRate || 0),
  );
  const [selectedHousing, setSelectedHousing] = useState('');
  const [housingRent, setHousingRent] = useState('');
  const activeCorporation =
    corporationOptions.find((option) => option.value === selectedCorporation)
      ?.value || corporationOptions[0]?.value || '';
  const activeBusiness =
    businessOptions.find((option) => option.value === selectedBusiness)?.value ||
    businessOptions[0]?.value ||
    '';
  const activeHousing =
    housingOptions.find((option) => option.value === selectedHousing)?.value ||
    housingOptions[0]?.value ||
    '';
  const corporationEntry = monitor?.corporations?.find(
    (entry) => entry.id === activeCorporation,
  );
  const businessEntry = monitor?.businesses?.find(
    (entry) => String(entry.id) === activeBusiness,
  );
  const housingEntry = monitor?.housing?.find(
    (entry) => entry.areaKey === activeHousing,
  );

  return (
    <div className="CorporateInterface__tabGrid">
      <div className="StyleGuide__blockShell">
        <div className="StyleGuide__blockTitle">Налог корпораций</div>
        <div className="CorporateInterface__taxControl">
          <label className="CorporateInterface__field">
            <span>Корпорация</span>
            <CorporateDropdown
              selected={activeCorporation}
              options={corporationOptions}
              onSelected={setSelectedCorporation}
              displayText={
                corporationOptions.find((option) => option.value === activeCorporation)
                  ?.displayText || 'Корпораций нет'
              }
            />
          </label>
          <label className="CorporateInterface__field">
            <span>Процент</span>
            <Input
              value={corporationTax}
              placeholder={`${corporationEntry?.taxRate || 0}%`}
              onChange={setCorporationTax}
            />
          </label>
          <div className="CorporateInterface__taxButtonRow">
            <Button
              icon="percent"
              disabled={!activeCorporation}
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark CorporateInterface__compactButton"
              onClick={() =>
                act('set_tax_setting', {
                  corporation_id: corporation.id,
                  kind: 'corporation',
                  target: activeCorporation,
                  value: Number(corporationTax || corporationEntry?.taxRate || 0),
                })
              }
            >
              Сохранить
            </Button>
          </div>
        </div>
      </div>

      <div className="StyleGuide__blockShell">
        <div className="StyleGuide__blockTitle">Налог бизнесов</div>
        <div className="CorporateInterface__taxControl">
          <label className="CorporateInterface__field">
            <span>Бизнес</span>
            <CorporateDropdown
              selected={activeBusiness}
              options={businessOptions}
              onSelected={setSelectedBusiness}
              displayText={
                businessOptions.find((option) => option.value === activeBusiness)
                  ?.displayText || 'Бизнесов нет'
              }
            />
          </label>
          <label className="CorporateInterface__field">
            <span>Процент</span>
            <Input
              value={businessTax}
              placeholder={`${businessEntry?.taxRate || monitor?.businessDefaultTaxRate || 0}%`}
              onChange={setBusinessTax}
            />
          </label>
          <div className="CorporateInterface__taxButtonRow">
            <Button
              icon="percent"
              disabled={!activeBusiness}
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark CorporateInterface__compactButton"
              onClick={() =>
                act('set_tax_setting', {
                  corporation_id: corporation.id,
                  kind: 'business',
                  target: activeBusiness,
                  value: Number(businessTax || businessEntry?.taxRate || 0),
                })
              }
            >
              Сохранить
            </Button>
          </div>
        </div>
        <div className="CorporateInterface__taxControl CorporateInterface__taxControl--inline">
          <label className="CorporateInterface__field">
            <span>По умолчанию</span>
            <Input value={defaultBusinessTax} onChange={setDefaultBusinessTax} />
          </label>
          <div className="CorporateInterface__taxButtonRow">
            <Button
              icon="percent"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark CorporateInterface__compactButton"
              onClick={() =>
                act('set_tax_setting', {
                  corporation_id: corporation.id,
                  kind: 'business_default',
                  target: '',
                  value: Number(defaultBusinessTax) || 0,
                })
              }
            >
              Сохранить
            </Button>
          </div>
        </div>
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Аренда жилья</div>
        <div className="CorporateInterface__taxControl CorporateInterface__taxControl--housing">
          <label className="CorporateInterface__field">
            <span>Район</span>
            <CorporateDropdown
              selected={activeHousing}
              options={housingOptions}
              onSelected={setSelectedHousing}
              displayText={
                housingOptions.find((option) => option.value === activeHousing)
                  ?.displayText || 'Арендуемого жилья нет'
              }
            />
          </label>
          <label className="CorporateInterface__field">
            <span>Плата</span>
            <Input
              value={housingRent}
              placeholder={formatCredits(housingEntry?.rent || 0)}
              onChange={setHousingRent}
            />
          </label>
          <div className="CorporateInterface__taxButtonRow">
            <Button
              icon="coins"
              disabled={!activeHousing}
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark CorporateInterface__compactButton"
              onClick={() =>
                act('set_tax_setting', {
                  corporation_id: corporation.id,
                  kind: 'housing',
                  target: activeHousing,
                  value: Number(housingRent || housingEntry?.rent || 0),
                })
              }
            >
              Сохранить
            </Button>
            <Button
              icon="receipt"
              disabled={!activeHousing}
              className="StyleGuide__cutButton StyleGuide__cutButton--red-dark CorporateInterface__compactButton"
              onClick={() =>
                act('charge_housing_rent', {
                  corporation_id: corporation.id,
                  area_key: activeHousing,
                })
              }
            >
              Списать
            </Button>
          </div>
        </div>
        {!monitor?.housing?.length ? (
          <div className="StyleGuide__placeholder">Записей арендуемого жилья нет.</div>
        ) : (
          <Table className="CorporateInterface__taxTable">
            <Table.Row header>
              <Table.Cell className="CorporateInterface__nameCell">Район</Table.Cell>
              <Table.Cell className="CorporateInterface__centerCell">Квартиры</Table.Cell>
              <Table.Cell className="CorporateInterface__moneyCell">Аренда</Table.Cell>
            </Table.Row>
            {monitor.housing.map((entry) => (
              <Table.Row key={entry.areaKey}>
                <Table.Cell className="CorporateInterface__nameCell">
                  {entry.area}
                </Table.Cell>
                <Table.Cell className="CorporateInterface__centerCell">
                  {entry.apartments || 0}
                </Table.Cell>
                <MoneyCell amount={entry.rent || 0} />
              </Table.Row>
            ))}
          </Table>
        )}
      </div>
    </div>
  );
}

function compactDeadline(deadline: string) {
  if (!deadline || deadline === 'expired') {
    return deadline === 'expired' ? 'истек' : '-';
  }
  const parts = deadline.match(/\d+/g)?.map(Number) || [];
  if (!parts.length) {
    return deadline;
  }
  const pad = (value: number) => String(value).padStart(2, '0');
  if (parts.length >= 4) {
    return `${parts[0]}д ${parts[1]}:${pad(parts[2])}:${pad(parts[3])}`;
  }
  if (parts.length === 3) {
    return `${parts[0]}:${pad(parts[1])}:${pad(parts[2])}`;
  }
  if (parts.length === 2) {
    return `${parts[0]}:${pad(parts[1])}`;
  }
  return `0:${pad(parts[0])}`;
}

function formatCredits(amount: number) {
  return `${formatMoney(amount)} кр`;
}

function formatStatus(status: string) {
  const statuses: Record<string, string> = {
    created: 'создан',
    active: 'активен',
    completed: 'завершен',
    cancelled: 'отменен',
    failed: 'провален',
    paid: 'оплачен',
    overdue: 'просрочен',
  };
  return statuses[status] || status || '-';
}

function formatContractType(type: string) {
  return contractTypes.find(([id]) => id === type)?.[1] || type || '-';
}

function formatProfitKind(kind: string) {
  if (kind === 'income') {
    return 'доход';
  }
  if (kind === 'expense') {
    return 'расход';
  }
  return kind || '-';
}

function formatProfitSource(source: string) {
  const sources: Record<string, string> = {
    'activity': 'активность',
    'corporate vending fee': 'комиссия корпоративных автоматов',
    'emergency power import': 'аварийный импорт энергии',
    'energy collector sale': 'продажа энергии с платных генераторов',
    'energy sale': 'продажа энергии',
    'research exchange': 'обмен исследований',
  };
  if (source?.startsWith('service:')) {
    return `услуга: ${source.replace('service:', '').trim()}`;
  }
  if (source?.startsWith('subscription:')) {
    return `подписка: ${source.replace('subscription:', '').trim()}`;
  }
  return sources[source] || source || '-';
}

function MoneyValue(props: { amount: number }) {
  return (
    <span className="CorporateInterface__moneyValue">
      {formatCredits(props.amount)}
    </span>
  );
}

function MoneyCell(props: { amount: number }) {
  return (
    <Table.Cell className="CorporateInterface__moneyCell">
      <MoneyValue amount={props.amount} />
    </Table.Cell>
  );
}

function ProfitPanel(props: { corporation: Corporation }) {
  const { corporation } = props;
  const records = corporation.profitRecords || [];

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">Прибыль</div>
      {!records.length ? (
        <div className="StyleGuide__placeholder">Записей прибыли нет.</div>
      ) : (
        <Table className="CorporateInterface__taxTable">
          <Table.Row header>
            <Table.Cell className="CorporateInterface__nameCell">Источник</Table.Cell>
            <Table.Cell className="CorporateInterface__centerCell">Тип</Table.Cell>
            <Table.Cell className="CorporateInterface__centerCell">Кол-во</Table.Cell>
            <Table.Cell className="CorporateInterface__moneyCell">Всего</Table.Cell>
            <Table.Cell className="CorporateInterface__moneyCell">Чистыми</Table.Cell>
            <Table.Cell className="CorporateInterface__moneyCell">Налог</Table.Cell>
            <Table.Cell className="CorporateInterface__nameCell">Последнее</Table.Cell>
          </Table.Row>
          {records.map((record) => (
            <Table.Row key={`${record.kind}-${record.source}`}>
              <Table.Cell className="CorporateInterface__nameCell">
                {formatProfitSource(record.source)}
              </Table.Cell>
              <Table.Cell className="CorporateInterface__centerCell">
                {formatProfitKind(record.kind)}
              </Table.Cell>
              <Table.Cell className="CorporateInterface__centerCell">
                {record.count || 0}
              </Table.Cell>
              <MoneyCell amount={record.gross || 0} />
              <MoneyCell amount={record.net || 0} />
              <MoneyCell amount={record.tax || 0} />
              <Table.Cell className="CorporateInterface__nameCell">
                {record.lastSeen || '-'}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </div>
  );
}

function GovernmentTaxMonitorPanel(props: { corporation: Corporation }) {
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide CorporateInterface__taxMonitor">
      <div className="StyleGuide__blockTitle">Налоговый монитор правительства</div>
      <Box className="CorporateInterface__subTitle">Бизнесы</Box>
      <Table className="CorporateInterface__taxTable">
        <Table.Row header>
          <Table.Cell className="CorporateInterface__nameCell">Бизнес</Table.Cell>
          <Table.Cell className="CorporateInterface__nameCell">Владелец</Table.Cell>
          <Table.Cell className="CorporateInterface__nameCell">Зона</Table.Cell>
          <Table.Cell className="CorporateInterface__centerCell">Ставка</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Долг</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Уплачено</Table.Cell>
          <Table.Cell className="CorporateInterface__centerCell">Просрочка</Table.Cell>
        </Table.Row>
        {(corporation.taxMonitor?.businesses || []).map((business) => (
          <Table.Row key={business.id}>
            <Table.Cell className="CorporateInterface__nameCell">{business.name}</Table.Cell>
            <Table.Cell className="CorporateInterface__nameCell">{business.owner}</Table.Cell>
            <Table.Cell className="CorporateInterface__nameCell">{business.area}</Table.Cell>
            <Table.Cell className="CorporateInterface__centerCell">{business.taxRate || 0}%</Table.Cell>
            <MoneyCell amount={business.taxDebt || 0} />
            <MoneyCell amount={business.taxPaid || 0} />
            <Table.Cell className="CorporateInterface__centerCell">
              {business.overdue ? 'да' : 'нет'}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
      <Box className="CorporateInterface__subTitle">Корпорации</Box>
      <Table className="CorporateInterface__taxTable">
        <Table.Row header>
          <Table.Cell className="CorporateInterface__nameCell">Корпорация</Table.Cell>
          <Table.Cell className="CorporateInterface__centerCell">Ставка</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Долг</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Уплачено</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Баланс</Table.Cell>
          <Table.Cell className="CorporateInterface__centerCell">Просрочка</Table.Cell>
        </Table.Row>
        {(corporation.taxMonitor?.corporations || []).map((entry) => (
          <Table.Row key={entry.id}>
            <Table.Cell className="CorporateInterface__nameCell">{entry.name}</Table.Cell>
            <Table.Cell className="CorporateInterface__centerCell">{entry.taxRate || 0}%</Table.Cell>
            <MoneyCell amount={entry.taxDebt || 0} />
            <MoneyCell amount={entry.taxPaid || 0} />
            <MoneyCell amount={entry.balance || 0} />
            <Table.Cell className="CorporateInterface__centerCell">
              {entry.overdue ? 'да' : 'нет'}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
      <Box className="CorporateInterface__subTitle">Счета</Box>
      <Table className="CorporateInterface__taxTable">
        <Table.Row header>
          <Table.Cell className="CorporateInterface__idCell">ID</Table.Cell>
          <Table.Cell className="CorporateInterface__nameCell">Владелец</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Баланс</Table.Cell>
          <Table.Cell className="CorporateInterface__moneyCell">Долг</Table.Cell>
        </Table.Row>
        {(corporation.taxMonitor?.accounts || []).map((entry) => (
          <Table.Row key={entry.id}>
            <Table.Cell className="CorporateInterface__idCell">{entry.id}</Table.Cell>
            <Table.Cell className="CorporateInterface__nameCell">{entry.name}</Table.Cell>
            <MoneyCell amount={entry.balance || 0} />
            <MoneyCell amount={entry.debt || 0} />
          </Table.Row>
        ))}
      </Table>
    </div>
  );
}

function HistoryPanel(props: { corporation: Corporation }) {
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">История</div>
      {!corporation.history?.length ? (
        <div className="StyleGuide__placeholder">Записей нет.</div>
      ) : (
        <div className="CorporateInterface__history">
          {corporation.history.map((entry, index) => (
            <span key={index}>{entry}</span>
          ))}
        </div>
      )}
    </div>
  );
}

function MetricPanel(props: { title: string; children: ReactNode }) {
  return (
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">{props.title}</div>
      <div className="StyleGuide__blockMetrics">{props.children}</div>
    </div>
  );
}
