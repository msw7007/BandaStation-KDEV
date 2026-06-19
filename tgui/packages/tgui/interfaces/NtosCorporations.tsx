// CYBERPUNK BUILD - rebuild and delete before release
import type { ReactNode } from 'react';
import { useState } from 'react';
import { Box, Button, Input, LabeledList, Stack, Table } from 'tgui-core/components';
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

type GovernmentTaxMonitor = {
  businesses: {
    id: number;
    name: string;
    owner: string;
    legal: BooleanLike;
    taxDebt: number;
    taxPaid: number;
    balance: number;
    area: string;
  }[];
  corporations: {
    id: string;
    name: string;
    taxDebt: number;
    taxPaid: number;
    balance: number;
  }[];
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

const tabs = [
  ['state', 'Состояния'],
  ['services', 'Услуги'],
  ['research', 'Изучение и реверс'],
  ['edicts', 'Эдикты'],
  ['contracts', 'Контракты'],
];

const contractTypes = [
  ['delivery', 'Delivery'],
  ['repair', 'Repair'],
  ['build', 'Build'],
  ['mining', 'Mining'],
  ['sabotage', 'Sabotage'],
];

export const NtosCorporations = () => {
  const { act, data } = useBackend<Data>();
  const { accountName, accountBalance = 0, corporations = [], selected } = data;
  const visibleCorporation = selected || corporations[0];
  const [activeTab, setActiveTab] = useState('state');
  const [dataType, setDataType] = useState('general');
  const [amount, setAmount] = useState('10');

  return (
    <NtosWindow width={980} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide CorporateInterface">
        <div className="StyleGuide__header CorporateInterface__header">
          <div>
            <div className="CorporateInterface__eyebrow">CORPORATE REGISTRY</div>
            <h1>Corporations</h1>
          </div>
          <div className="CorporateInterface__account">
            <span>{accountName || 'No ID account'}</span>
            <b>{formatMoney(accountBalance)} cr</b>
            <em>{corporations.length} entities</em>
          </div>
        </div>

        <div className="CorporateInterface__layout">
          <aside className="StyleGuide__blockShell CorporateInterface__side">
            <div className="StyleGuide__blockTitle">Entities</div>
            <div className="CorporateInterface__entityList">
              {!corporations.length ? (
                <div className="StyleGuide__placeholder">No corporations.</div>
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
                  Corporate registry has no initialized entities.
                </div>
              </div>
            ) : (
              <>
                <CorporationSummary corporation={visibleCorporation} />
                <div className="StyleGuide__topTabs CorporateInterface__tabs">
                  {tabs.map(([id, label]) => (
                    <button
                      key={id}
                      type="button"
                      className={activeTab === id ? 'active' : ''}
                      onClick={() => setActiveTab(id)}
                    >
                      {label}
                    </button>
                  ))}
                </div>
                <CorporateTab
                  activeTab={activeTab}
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
      <div>
        <div className="StyleGuide__blockTitle">{corporation.name}</div>
        <p>{corporation.group}</p>
      </div>
      <div className="CorporateInterface__summaryGrid">
        <span>Direction</span>
        <b>{corporation.direction}</b>
        <span>Combat</span>
        <b>{corporation.combatDoctrine}</b>
        <span>Subsidiaries</span>
        <b>
          {(corporation.subsidiaries || [])
            .map((subsidiary) => subsidiary.name)
            .join(', ') || 'none'}
        </b>
      </div>
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
    default:
      return <StateTab corporation={props.corporation} />;
  }
}

function StateTab(props: { corporation: Corporation }) {
  const { corporation } = props;

  return (
    <div className="CorporateInterface__tabGrid">
      <MetricPanel title="State">
        <LabeledList>
          <LabeledList.Item label="Level">{corporation.level}/5</LabeledList.Item>
          <LabeledList.Item label="Experience">
            {corporation.experience}
            {corporation.nextLevelAt ? ` / ${corporation.nextLevelAt}` : ''}
          </LabeledList.Item>
          <LabeledList.Item label="Research">
            {corporation.researchPoints} RP
          </LabeledList.Item>
          <LabeledList.Item label="Subscribers">
            {corporation.subscribers || 0}
          </LabeledList.Item>
          <LabeledList.Item label="Foreign tech">
            {corporation.foreignTechBonus || 0}% discount
          </LabeledList.Item>
        </LabeledList>
      </MetricPanel>

      <MetricPanel title="Finance">
        <LabeledList>
          <LabeledList.Item label="Account">#{corporation.accountId}</LabeledList.Item>
          <LabeledList.Item label="Funds">
            {formatMoney(corporation.balance)} cr
          </LabeledList.Item>
          <LabeledList.Item label="Debt">
            {formatMoney(corporation.debt)} cr
          </LabeledList.Item>
          <LabeledList.Item label="Tax debt">
            {formatMoney(corporation.taxDebt || 0)} cr
          </LabeledList.Item>
          <LabeledList.Item label="Tax paid">
            {formatMoney(corporation.taxPaid || 0)} cr
          </LabeledList.Item>
        </LabeledList>
      </MetricPanel>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Subsidiaries</div>
        {!corporation.subsidiaries?.length ? (
          <div className="StyleGuide__placeholder">No subsidiaries.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Focus</Table.Cell>
              <Table.Cell collapsing>Manufacturer</Table.Cell>
              <Table.Cell collapsing>Data</Table.Cell>
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

      <HistoryPanel corporation={corporation} />
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
      <MetricPanel title="Service state">
        <LabeledList>
          <LabeledList.Item label="Subscription">
            {formatMoney(corporation.subscriptionCost || 0)} cr
          </LabeledList.Item>
          <LabeledList.Item label="Enabled">
            {enabledServices.length
              ? enabledServices.map((service) => service.label).join(', ')
              : 'No active service edict'}
          </LabeledList.Item>
          <LabeledList.Item label="Mode">
            {corporation.serviceAutoEnabled ? 'automatic' : 'queued'}
          </LabeledList.Item>
        </LabeledList>
        <div className="CorporateInterface__actions">
          <Button
            icon="id-card"
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-light"
            onClick={() =>
              act('subscribe', {
                corporation_id: corporation.id,
              })
            }
          >
            Subscribe
          </Button>
          <Button
            icon={corporation.serviceAutoEnabled ? 'toggle-on' : 'toggle-off'}
            className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
            onClick={() =>
              act('toggle_service_auto', {
                corporation_id: corporation.id,
              })
            }
          >
            Auto services
          </Button>
        </div>
      </MetricPanel>

      <div className="StyleGuide__blockShell">
        <div className="StyleGuide__blockTitle">Catalogue</div>
        {!services.length ? (
          <div className="StyleGuide__placeholder">
            This corporation has no service catalogue yet.
          </div>
        ) : (
          <div className="CorporateInterface__cardGrid">
            {services.map((service) => (
              <div
                key={service.id}
                className={[
                  'StyleGuide__dataCard',
                  service.enabled
                    ? 'StyleGuide__dataCard--enabled'
                    : 'StyleGuide__dataCard--disabled',
                ].join(' ')}
              >
                <b>{service.label}</b>
                <span>{service.description}</span>
                <Button
                  icon={service.icon || 'circle'}
                  disabled={!service.enabled}
                  className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                  onClick={() =>
                    act('request_service', {
                      corporation_id: corporation.id,
                      service_id: service.id,
                    })
                  }
                >
                  {service.enabled ? 'Request' : 'Locked'}
                </Button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Queue</div>
        {!corporation.serviceRequests?.length ? (
          <div className="StyleGuide__placeholder">No service requests.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Service</Table.Cell>
              <Table.Cell>Customer</Table.Cell>
              <Table.Cell>Status</Table.Cell>
              <Table.Cell collapsing>Cost</Table.Cell>
              <Table.Cell collapsing>Age</Table.Cell>
              <Table.Cell collapsing>Actions</Table.Cell>
            </Table.Row>
            {corporation.serviceRequests.map((request) => (
              <Table.Row key={request.id}>
                <Table.Cell>{request.service}</Table.Cell>
                <Table.Cell>{request.customer}</Table.Cell>
                <Table.Cell>{request.status}</Table.Cell>
                <Table.Cell>{formatMoney(request.cost)} cr</Table.Cell>
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
        <div className="StyleGuide__blockTitle">Vendors</div>
        {!corporation.vendors?.length ? (
          <div className="StyleGuide__placeholder">
            No registered corporate vending machines.
          </div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Vendor</Table.Cell>
              <Table.Cell>Area</Table.Cell>
              <Table.Cell collapsing>Sales</Table.Cell>
              <Table.Cell collapsing>Revenue</Table.Cell>
              <Table.Cell>Last product</Table.Cell>
            </Table.Row>
            {corporation.vendors.map((vendor, index) => (
              <Table.Row key={`${vendor.name}-${index}`}>
                <Table.Cell>{vendor.name}</Table.Cell>
                <Table.Cell>{vendor.area}</Table.Cell>
                <Table.Cell>{vendor.sales || 0}</Table.Cell>
                <Table.Cell>{formatMoney(vendor.revenue || 0)} cr</Table.Cell>
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

  return (
    <div className="CorporateInterface__tabGrid">
      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Research data</div>
        <Stack mb={1}>
          <Stack.Item grow>
            <Input fluid value={dataType} placeholder="data type" onChange={setDataType} />
          </Stack.Item>
          <Stack.Item width="90px">
            <Input fluid value={amount} placeholder="amount" onChange={setAmount} />
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
              Test data
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
              Exchange
            </Button>
          </Stack.Item>
        </Stack>
        {!corporation.researchData?.length ? (
          <div className="StyleGuide__placeholder">No stored data.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Type</Table.Cell>
              <Table.Cell collapsing>Amount</Table.Cell>
              <Table.Cell collapsing>Actions</Table.Cell>
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
                    Convert
                  </Button>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>

      <div className="StyleGuide__blockShell CorporateInterface__wide">
        <div className="StyleGuide__blockTitle">Technologies</div>
        <div className="CorporateInterface__cardGrid">
          {(corporation.technologies || []).map((technology) => (
            <div
              key={technology.id}
              className={[
                'StyleGuide__dataCard',
                technology.unlocked
                  ? 'StyleGuide__dataCard--enabled'
                  : 'StyleGuide__dataCard--disabled',
              ].join(' ')}
            >
              <b>
                T{technology.tier} {technology.name}
              </b>
              <span>{technology.description}</span>
              <small>
                {technology.cost} RP
                {technology.discount ? `, discount ${technology.discount} RP` : ''}
                {corporation.foreignTechBonus
                  ? `, foreign ${corporation.foreignTechBonus}%`
                  : ''}
                {technology.prereq ? `, requires ${technology.prereq}` : ''}
              </small>
              <Button
                icon={technology.unlocked ? 'check' : 'microscope'}
                disabled={!!technology.unlocked || !technology.canUnlock}
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                onClick={() =>
                  act('unlock_technology', {
                    corporation_id: corporation.id,
                    technology_id: technology.id,
                  })
                }
              >
                {technology.unlocked ? 'Open' : 'Research'}
              </Button>
            </div>
          ))}
        </div>
      </div>

      <ForeignTechnologyPanel corporation={corporation} />
    </div>
  );
}

function ForeignTechnologyPanel(props: { corporation: Corporation }) {
  const { act } = useBackend<Data>();
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">Reverse engineering</div>
      {!corporation.stolenTechnologies?.length &&
      !corporation.stolenProgress?.length ? (
        <div className="StyleGuide__placeholder">No foreign technology records.</div>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Technology</Table.Cell>
            <Table.Cell>Source</Table.Cell>
            <Table.Cell>Progress</Table.Cell>
          </Table.Row>
          {(corporation.stolenTechnologies || []).map((entry) => (
            <Table.Row key={`stolen-${entry.id}`}>
              <Table.Cell>{entry.name || entry.id}</Table.Cell>
              <Table.Cell>{entry.sourceName || entry.source}</Table.Cell>
              <Table.Cell>copied</Table.Cell>
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
    <div className="StyleGuide__blockShell">
      <div className="StyleGuide__blockTitle">Edicts</div>
      {!corporation.edicts?.length ? (
        <div className="StyleGuide__placeholder">No edicts for this entity yet.</div>
      ) : (
        <div className="CorporateInterface__cardGrid">
          {corporation.edicts.map((edict) => (
            <div
              key={edict.id}
              className={[
                'StyleGuide__dataCard',
                edict.active
                  ? 'StyleGuide__dataCard--enabled'
                  : 'StyleGuide__dataCard--disabled',
              ].join(' ')}
            >
              <b>
                L{edict.level} {edict.name}
              </b>
              <span>{edict.description}</span>
              <Button
                icon={edict.active ? 'check' : 'gavel'}
                disabled={!!edict.active || !!edict.locked}
                className="StyleGuide__cutButton StyleGuide__cutButton--red-dark"
                onClick={() =>
                  act('choose_edict', {
                    corporation_id: corporation.id,
                    edict_id: edict.id,
                  })
                }
              >
                {edict.active ? 'Active' : 'Choose'}
              </Button>
            </div>
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
        <div className="StyleGuide__blockTitle">Contract pool</div>
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
            Pay taxes
          </Button>
        </div>
        {!corporation.contracts?.length ? (
          <div className="StyleGuide__placeholder">No corporate contracts.</div>
        ) : (
          <Table>
            <Table.Row header>
              <Table.Cell>Contract</Table.Cell>
              <Table.Cell>Type</Table.Cell>
              <Table.Cell>Status</Table.Cell>
              <Table.Cell collapsing>Payment</Table.Cell>
              <Table.Cell collapsing>Deadline</Table.Cell>
            </Table.Row>
            {corporation.contracts.map((contract) => (
              <Table.Row key={contract.id}>
                <Table.Cell>{contract.title}</Table.Cell>
                <Table.Cell>{contract.type}</Table.Cell>
                <Table.Cell>{contract.status}</Table.Cell>
                <Table.Cell>{formatMoney(contract.payment)} cr</Table.Cell>
                <Table.Cell>{contract.deadline}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </div>

      {!!corporation.taxMonitor && <TaxMonitorPanel corporation={corporation} />}
    </div>
  );
}

function TaxMonitorPanel(props: { corporation: Corporation }) {
  const { corporation } = props;

  return (
    <div className="StyleGuide__blockShell CorporateInterface__wide">
      <div className="StyleGuide__blockTitle">Government tax monitor</div>
      <Box className="CorporateInterface__subTitle">Businesses</Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Business</Table.Cell>
          <Table.Cell>Owner</Table.Cell>
          <Table.Cell>Area</Table.Cell>
          <Table.Cell collapsing>Debt</Table.Cell>
          <Table.Cell collapsing>Paid</Table.Cell>
        </Table.Row>
        {(corporation.taxMonitor?.businesses || []).map((business) => (
          <Table.Row key={business.id}>
            <Table.Cell>{business.name}</Table.Cell>
            <Table.Cell>{business.owner}</Table.Cell>
            <Table.Cell>{business.area}</Table.Cell>
            <Table.Cell>{formatMoney(business.taxDebt || 0)} cr</Table.Cell>
            <Table.Cell>{formatMoney(business.taxPaid || 0)} cr</Table.Cell>
          </Table.Row>
        ))}
      </Table>
      <Box className="CorporateInterface__subTitle">Corporations</Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Corporation</Table.Cell>
          <Table.Cell collapsing>Debt</Table.Cell>
          <Table.Cell collapsing>Paid</Table.Cell>
          <Table.Cell collapsing>Balance</Table.Cell>
        </Table.Row>
        {(corporation.taxMonitor?.corporations || []).map((entry) => (
          <Table.Row key={entry.id}>
            <Table.Cell>{entry.name}</Table.Cell>
            <Table.Cell>{formatMoney(entry.taxDebt || 0)} cr</Table.Cell>
            <Table.Cell>{formatMoney(entry.taxPaid || 0)} cr</Table.Cell>
            <Table.Cell>{formatMoney(entry.balance || 0)} cr</Table.Cell>
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
      <div className="StyleGuide__blockTitle">History</div>
      {!corporation.history?.length ? (
        <div className="StyleGuide__placeholder">No records.</div>
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
