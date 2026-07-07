import {
  Box,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';

type BusinessRegistryEntry = {
  id: number;
  name: string;
  direction: string;
  registeredTo: string;
  owner: string;
  area: string;
  taxDebt: number;
  taxPaid: number;
  taxRate: number;
  status: string;
};

type Data = {
  accountName?: string;
  businesses: BusinessRegistryEntry[];
};

export const NtosBusinessRegistry = () => {
  const { data } = useBackend<Data>();
  const { accountName, businesses = [] } = data;

  return (
    <NtosWindow width={760} height={560}>
      <NtosWindow.Content scrollable className="CyberpunkPanel">
        <Section title="City business registry">
          <LabeledList>
            <LabeledList.Item label="Viewer">
              {accountName || 'public terminal'}
            </LabeledList.Item>
            <LabeledList.Item label="Registered businesses">
              {businesses.length}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Legal businesses">
          {!businesses.length ? (
            <Box className="CyberpunkPanel__Muted">
              No legal businesses are registered in the city.
            </Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell collapsing>ID</Table.Cell>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Direction</Table.Cell>
                <Table.Cell>Area</Table.Cell>
                <Table.Cell>Status</Table.Cell>
              </Table.Row>
              {businesses.map((business) => (
                <Table.Row key={business.id}>
                  <Table.Cell>#{business.id}</Table.Cell>
                  <Table.Cell>
                    <Stack vertical>
                      <Stack.Item>{business.name}</Stack.Item>
                      <Stack.Item className="CyberpunkPanel__Muted">
                        {business.owner} / {business.registeredTo}
                      </Stack.Item>
                    </Stack>
                  </Table.Cell>
                  <Table.Cell>{business.direction}</Table.Cell>
                  <Table.Cell>{business.area}</Table.Cell>
                  <Table.Cell>
                    {business.status} / tax {business.taxRate}% / debt{' '}
                    {formatMoney(business.taxDebt)} cr / paid{' '}
                    {formatMoney(business.taxPaid)} cr
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
