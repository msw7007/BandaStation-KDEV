// CYBERPUNK BUILD - rebuild and delete before release
import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  Section,
  Stack,
  Table,
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

export const NtosCorporations = () => {
  const { act, data } = useBackend<Data>();
  const { accountName, accountBalance = 0, corporations = [], selected } = data;
  const [dataType, setDataType] = useState('general');
  const [amount, setAmount] = useState('10');

  return (
    <NtosWindow width={900} height={760}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="Corporate registry">
          <LabeledList>
            <LabeledList.Item label="ID account">
              {accountName || 'No ID account'}
            </LabeledList.Item>
            <LabeledList.Item label="Balance">
              {formatMoney(accountBalance)} cr
            </LabeledList.Item>
            <LabeledList.Item label="Corporations">
              {corporations.length}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Stack align="stretch">
          <Stack.Item width="235px">
            <Section title="Entities">
              {!corporations.length ? (
                <Box className="CyberpunkPanel__Muted">No corporations.</Box>
              ) : (
                corporations.map((corporation) => (
                  <Button
                    key={corporation.id}
                    fluid
                    selected={selected?.id === corporation.id}
                    color={corporation.hidden ? 'red' : undefined}
                    onClick={() =>
                      act('select', { corporation_id: corporation.id })
                    }
                  >
                    {corporation.name}
                  </Button>
                ))
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            {!selected ? (
              <Section title="Corporation">
                <Box className="CyberpunkPanel__Muted">
                  Select a corporation.
                </Box>
              </Section>
            ) : (
              <CorporateDetails
                corporation={selected}
                corporations={corporations}
                dataType={dataType}
                amount={amount}
                setDataType={setDataType}
                setAmount={setAmount}
              />
            )}
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const CorporateDetails = (props: {
  corporation: Corporation;
  corporations: Corporation[];
  dataType: string;
  amount: string;
  setDataType: (value: string) => void;
  setAmount: (value: string) => void;
}) => {
  const { act } = useBackend<Data>();
  const {
    corporation,
    dataType,
    amount,
    setDataType,
    setAmount,
  } = props;
  const amountNumber = Number(amount) || 0;
  const services = corporation.services || [];
  const enabledServices = services.filter((service) => service.enabled);

  return (
    <>
      <Section title={corporation.name}>
        <LabeledList>
          <LabeledList.Item label="Group">{corporation.group}</LabeledList.Item>
          <LabeledList.Item label="Direction">
            {corporation.direction}
          </LabeledList.Item>
          <LabeledList.Item label="Combat">
            {corporation.combatDoctrine}
          </LabeledList.Item>
          <LabeledList.Item label="Subsidiaries">
            {(corporation.subsidiaries || [])
              .map((subsidiary) => subsidiary.name)
              .join(', ') || 'none'}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Subsidiaries">
        {!corporation.subsidiaries?.length ? (
          <Box className="CyberpunkPanel__Muted">No subsidiaries.</Box>
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
      </Section>

      <Section title="State">
        <Stack>
          <Stack.Item grow>
            <Box className="CyberpunkPanel__Metric">
              <LabeledList>
                <LabeledList.Item label="Level">
                  {corporation.level}/5
                </LabeledList.Item>
                <LabeledList.Item label="Experience">
                  {corporation.experience}
                  {corporation.nextLevelAt
                    ? ` / ${corporation.nextLevelAt}`
                    : ''}
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
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box className="CyberpunkPanel__Metric">
              <LabeledList>
                <LabeledList.Item label="Account">
                  #{corporation.accountId}
                </LabeledList.Item>
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
            </Box>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Services">
        <Stack>
          <Stack.Item grow>
            <Box className="CyberpunkPanel__Metric">
              <LabeledList>
                <LabeledList.Item label="Subscription">
                  {formatMoney(corporation.subscriptionCost || 0)} cr
                </LabeledList.Item>
                <LabeledList.Item label="Enabled services">
                  {enabledServices.length
                    ? enabledServices.map((service) => service.label).join(', ')
                    : 'No active service edict'}
                </LabeledList.Item>
                <LabeledList.Item label="Mode">
                  {corporation.serviceAutoEnabled ? 'automatic' : 'queued'}
                </LabeledList.Item>
              </LabeledList>
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="id-card"
              onClick={() =>
                act('subscribe', {
                  corporation_id: corporation.id,
                })
              }
            >
              Subscribe
            </Button>
            <Button
              ml={1}
              icon={corporation.serviceAutoEnabled ? 'toggle-on' : 'toggle-off'}
              onClick={() =>
                act('toggle_service_auto', {
                  corporation_id: corporation.id,
                })
              }
            >
              Auto services
            </Button>
          </Stack.Item>
        </Stack>
        {!!services.length && (
          <Stack mt={1} wrap align="stretch">
            {services.map((service) => (
              <Stack.Item key={service.id} width="48%">
                <Box className="CyberpunkPanel__Card" height="100%">
                  <Stack vertical fill>
                    <Stack.Item grow>
                      <Box className="CyberpunkPanel__Title">
                        {service.label}
                      </Box>
                      <Box className="CyberpunkPanel__Muted">
                        {service.description}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        fluid
                        icon={service.icon || 'circle'}
                        disabled={!service.enabled}
                        onClick={() =>
                          act('request_service', {
                            corporation_id: corporation.id,
                            service_id: service.id,
                          })
                        }
                      >
                        {service.enabled ? 'Request' : 'Locked by edict'}
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Box>
              </Stack.Item>
            ))}
          </Stack>
        )}
        {!services.length && (
          <Box mt={1} className="CyberpunkPanel__Muted">
            This corporation has no service catalogue yet.
          </Box>
        )}
      </Section>

      <Section title="Service queue">
        {!corporation.serviceRequests?.length ? (
          <Box className="CyberpunkPanel__Muted">No service requests.</Box>
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
      </Section>

      <Section title="Corporate vendors">
        {!corporation.vendors?.length ? (
          <Box className="CyberpunkPanel__Muted">
            No registered corporate vending machines.
          </Box>
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
      </Section>

      <Section title="Corporate contracts">
        <Stack mb={1} wrap>
          {[
            ['delivery', 'Delivery'],
            ['repair', 'Repair'],
            ['build', 'Build'],
            ['mining', 'Mining'],
            ['sabotage', 'Sabotage'],
          ].map(([type, label]) => (
            <Stack.Item key={type}>
              <Button
                icon="file-signature"
                onClick={() =>
                  act('create_pool_contract', {
                    corporation_id: corporation.id,
                    contract_type: type,
                  })
                }
              >
                {label}
              </Button>
            </Stack.Item>
          ))}
          <Stack.Item>
            <Button
              icon="coins"
              disabled={!corporation.taxDebt}
              onClick={() =>
                act('pay_corporate_taxes', {
                  corporation_id: corporation.id,
                  amount: corporation.taxDebt || 0,
                })
              }
            >
              Pay taxes
            </Button>
          </Stack.Item>
        </Stack>
        {!corporation.contracts?.length ? (
          <Box className="CyberpunkPanel__Muted">No corporate contracts.</Box>
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
      </Section>

      {!!corporation.taxMonitor && (
        <Section title="Government tax monitor">
          <Box className="CyberpunkPanel__Title">Businesses</Box>
          <Table>
            <Table.Row header>
              <Table.Cell>Business</Table.Cell>
              <Table.Cell>Owner</Table.Cell>
              <Table.Cell>Area</Table.Cell>
              <Table.Cell collapsing>Debt</Table.Cell>
              <Table.Cell collapsing>Paid</Table.Cell>
            </Table.Row>
            {(corporation.taxMonitor.businesses || []).map((business) => (
              <Table.Row key={business.id}>
                <Table.Cell>{business.name}</Table.Cell>
                <Table.Cell>{business.owner}</Table.Cell>
                <Table.Cell>{business.area}</Table.Cell>
                <Table.Cell>{formatMoney(business.taxDebt || 0)} cr</Table.Cell>
                <Table.Cell>{formatMoney(business.taxPaid || 0)} cr</Table.Cell>
              </Table.Row>
            ))}
          </Table>
          <Box mt={1} className="CyberpunkPanel__Title">
            Corporations
          </Box>
          <Table>
            <Table.Row header>
              <Table.Cell>Corporation</Table.Cell>
              <Table.Cell collapsing>Debt</Table.Cell>
              <Table.Cell collapsing>Paid</Table.Cell>
              <Table.Cell collapsing>Balance</Table.Cell>
            </Table.Row>
            {(corporation.taxMonitor.corporations || []).map((entry) => (
              <Table.Row key={entry.id}>
                <Table.Cell>{entry.name}</Table.Cell>
                <Table.Cell>{formatMoney(entry.taxDebt || 0)} cr</Table.Cell>
                <Table.Cell>{formatMoney(entry.taxPaid || 0)} cr</Table.Cell>
                <Table.Cell>{formatMoney(entry.balance || 0)} cr</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      )}

      <Section title="Research data">
        <Stack mb={1}>
          <Stack.Item grow>
            <Input
              fluid
              value={dataType}
              placeholder="data type"
              onChange={setDataType}
            />
          </Stack.Item>
          <Stack.Item width="90px">
            <Input
              fluid
              value={amount}
              placeholder="amount"
              onChange={setAmount}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="plus"
              disabled={!amountNumber}
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
        </Stack>
        {!corporation.researchData?.length ? (
          <Box className="CyberpunkPanel__Muted">No stored data.</Box>
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
        <Button
          mt={1}
          icon="coins"
          disabled={!corporation.researchPoints}
          onClick={() =>
            act('exchange_research', {
              corporation_id: corporation.id,
              amount: Math.min(10, corporation.researchPoints),
            })
          }
        >
          Exchange 10 RP to funds
        </Button>
      </Section>

      <Section title="Technologies">
        {corporation.technologies.map((technology) => (
          <Box key={technology.id} className="CyberpunkPanel__Card">
            <Stack align="center">
              <Stack.Item grow>
                <Box className="CyberpunkPanel__Title">
                  T{technology.tier} {technology.name}
                </Box>
                <Box>{technology.description}</Box>
                <Box className="CyberpunkPanel__Muted CyberpunkPanel__Small">
                  Cost {technology.cost} RP
                  {technology.discount
                    ? `, activity discount ${technology.discount} RP`
                    : ''}
                  {corporation.foreignTechBonus
                    ? `, foreign tech discount ${corporation.foreignTechBonus}%`
                    : ''}
                  {technology.prereq ? `, requires ${technology.prereq}` : ''}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={technology.unlocked ? 'check' : 'microscope'}
                  color={technology.unlocked ? 'green' : undefined}
                  disabled={!!technology.unlocked || !technology.canUnlock}
                  onClick={() =>
                    act('unlock_technology', {
                      corporation_id: corporation.id,
                      technology_id: technology.id,
                    })
                  }
                >
                  {technology.unlocked ? 'Open' : 'Research'}
                </Button>
              </Stack.Item>
            </Stack>
          </Box>
        ))}
      </Section>

      <Section title="Corporate decisions">
        {!corporation.edicts?.length ? (
          <Box className="CyberpunkPanel__Muted">
            No edicts for this entity yet.
          </Box>
        ) : (
          corporation.edicts.map((edict) => (
            <Box key={edict.id} className="CyberpunkPanel__Card">
              <Stack align="center">
                <Stack.Item grow>
                  <Box className="CyberpunkPanel__Title">
                    L{edict.level} {edict.name}
                  </Box>
                  <Box>{edict.description}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon={edict.active ? 'check' : 'gavel'}
                    color={edict.active ? 'green' : undefined}
                    disabled={!!edict.active || !!edict.locked}
                    onClick={() =>
                      act('choose_edict', {
                        corporation_id: corporation.id,
                        edict_id: edict.id,
                      })
                    }
                  >
                    {edict.active ? 'Active' : 'Choose'}
                  </Button>
                </Stack.Item>
              </Stack>
            </Box>
          ))
        )}
      </Section>

      <Section title="Foreign technology">
        <Box mb={1} className="CyberpunkPanel__Muted">
          Foreign technologies are acquired through network theft and reverse
          engineering. Copied records reduce future research costs by{' '}
          {corporation.foreignTechBonus || 0}%.
        </Box>
        {!corporation.stolenTechnologies?.length &&
        !corporation.stolenProgress?.length ? (
          <Box className="CyberpunkPanel__Muted">
            No foreign technology records.
          </Box>
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
                        disabled={
                          corporation.researchPoints <
                          20
                        }
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
      </Section>

      <Collapsible title="History">
        {(corporation.history || []).map((entry, index) => (
          <Box key={index} className="CyberpunkPanel__Mono CyberpunkPanel__Small">
            {entry}
          </Box>
        ))}
      </Collapsible>
    </>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
