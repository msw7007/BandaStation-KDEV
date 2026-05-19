import { Box, Button, LabeledList, Section, Table } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type BusinessData = {
  has_zone: boolean;
  zone_size: string;
  zone: Record<string, unknown>;
  can_manage: boolean;
  business?: {
    business_id: string;
    name: string;
    business_type: string;
    legal_status: string;
    owner_ckey: string;
    account_balance: number;
    tax_debt: number;
    risk_score: number;
    employees: string[];
    employee_wages: Record<string, number>;
    permissions: Record<string, string>;
    corporate_storage_permissions: Record<string, string[]>;
  };
  warehouses: Warehouse[];
};

type Warehouse = {
  ref: string;
  name: string;
  corporation_id?: string;
  allow_business_fallback: boolean;
  allowed_item_types: string[];
  items: { name: string; type: string; quality: string }[];
};

export const CyberpunkBusinessTerminal = () => {
  const { act, data } = useBackend<BusinessData>();
  const business = data.business;

  return (
    <Window width={820} height={700}>
      <Window.Content scrollable>
        <Section
          title="Business"
          buttons={
            <>
              <Button icon="plus" disabled={!data.has_zone || !!business} onClick={() => act('create')}>
                Create
              </Button>
              <Button icon="save" disabled={!data.can_manage} onClick={() => act('save')}>
                Save
              </Button>
              <Button icon="download" disabled={!data.can_manage} onClick={() => act('load')}>
                Load
              </Button>
              <Button icon="coins" disabled={!data.can_manage} onClick={() => act('pay_tax')}>
                Pay tax
              </Button>
            </>
          }
        >
          {!business ? (
            <Box color="label">Free {data.zone_size || 'unknown'} business zone.</Box>
          ) : (
            <LabeledList>
              <LabeledList.Item label="Name">{business.name}</LabeledList.Item>
              <LabeledList.Item label="ID">{business.business_id}</LabeledList.Item>
              <LabeledList.Item label="Direction">{business.business_type}</LabeledList.Item>
              <LabeledList.Item label="Status">{business.legal_status}</LabeledList.Item>
              <LabeledList.Item label="Balance">{business.account_balance}</LabeledList.Item>
              <LabeledList.Item label="Tax debt">{business.tax_debt}</LabeledList.Item>
              <LabeledList.Item label="Risk">{business.risk_score}%</LabeledList.Item>
            </LabeledList>
          )}
        </Section>

        {!!business && (
          <Section
            title="Employees"
            buttons={
              <Button icon="user-plus" disabled={!data.can_manage} onClick={() => act('add_employee')}>
                Add
              </Button>
            }
          >
            <Table>
              <Table.Row header>
                <Table.Cell>Ckey</Table.Cell>
                <Table.Cell>Wage</Table.Cell>
                <Table.Cell>Permission</Table.Cell>
                <Table.Cell />
              </Table.Row>
              {(business.employees || []).map((ckey) => (
                <Table.Row key={ckey}>
                  <Table.Cell>{ckey}</Table.Cell>
                  <Table.Cell>{business.employee_wages?.[ckey] || 0}</Table.Cell>
                  <Table.Cell>{business.permissions?.[ckey] || 'worker'}</Table.Cell>
                  <Table.Cell collapsing>
                    <Button icon="trash" disabled={!data.can_manage} onClick={() => act('remove_employee', { ckey })} />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}

        {!!business && (
          <Section
            title="Corporate Warehouse Permissions"
            buttons={
              <Button icon="plus" disabled={!data.can_manage} onClick={() => act('add_corp_item')}>
                Add rule
              </Button>
            }
          >
            <Table>
              <Table.Row header>
                <Table.Cell>Corporation</Table.Cell>
                <Table.Cell>Allowed item path</Table.Cell>
                <Table.Cell>Unload to business fallback</Table.Cell>
              </Table.Row>
              {Object.entries(business.corporate_storage_permissions || {}).flatMap(([corporation_id, itemTypes]) =>
                itemTypes.map((item_type) => (
                  <Table.Row key={`${corporation_id}-${item_type}`}>
                    <Table.Cell>{corporation_id}</Table.Cell>
                    <Table.Cell>{item_type}</Table.Cell>
                    <Table.Cell>
                      <Button
                        selected
                        icon="toggle-on"
                        disabled={!data.can_manage}
                        onClick={() => act('toggle_corp_item', { corporation_id, item_type, allowed: true })}
                      >
                        Allowed
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                )),
              )}
            </Table>
          </Section>
        )}

        {!!business && (
          <Section title="Warehouses">
            {(data.warehouses || []).map((warehouse) => (
              <Section key={warehouse.ref} title={`${warehouse.name} ${warehouse.corporation_id || 'business'}`} level={2}>
                <LabeledList>
                  <LabeledList.Item label="Fallback">{warehouse.allow_business_fallback ? 'yes' : 'no'}</LabeledList.Item>
                  <LabeledList.Item label="Allowed">{warehouse.allowed_item_types?.join(', ') || 'any'}</LabeledList.Item>
                </LabeledList>
                <Table>
                  <Table.Row header>
                    <Table.Cell>Item</Table.Cell>
                    <Table.Cell>Type</Table.Cell>
                    <Table.Cell>Quality</Table.Cell>
                  </Table.Row>
                  {(warehouse.items || []).map((item, index) => (
                    <Table.Row key={`${item.type}-${index}`}>
                      <Table.Cell>{item.name}</Table.Cell>
                      <Table.Cell>{item.type}</Table.Cell>
                      <Table.Cell>{item.quality}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Section>
            ))}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
