import { Box, Button, LabeledList, Section, Table } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Contract = {
  contract_id: string;
  name: string;
  contract_type: string;
  status: string;
  legality: string;
  visibility: string;
  customer_business_id?: string;
  performer_business_id?: string;
  payment_amount: number;
  deposit_amount: number;
  reserved_tax: number;
  service_fee: number;
  due_time: number;
  event_log: string[];
};

type ContractData = {
  grey_unlocked: boolean;
  contracts: Contract[];
  ledger: Contract[];
  businesses: { business_id: string; name: string }[];
};

export const CyberpunkContractTerminal = () => {
  const { act, data } = useBackend<ContractData>();

  return (
    <Window width={900} height={720}>
      <Window.Content scrollable>
        <Section
          title="Contracts"
          buttons={
            <>
              <Button icon="plus" disabled={!data.businesses?.length} onClick={() => act('create')}>
                Create
              </Button>
              <Button icon="key" selected={data.grey_unlocked} onClick={() => act('unlock_grey')}>
                Grey pool
              </Button>
            </>
          }
        >
          {!data.businesses?.length && <Box color="bad">No managed business account available for reserves.</Box>}
          <Table>
            <Table.Row header>
              <Table.Cell>ID</Table.Cell>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Type</Table.Cell>
              <Table.Cell>Status</Table.Cell>
              <Table.Cell>Visibility</Table.Cell>
              <Table.Cell>Pay</Table.Cell>
              <Table.Cell>Deposit</Table.Cell>
              <Table.Cell />
            </Table.Row>
            {(data.contracts || []).map((contract) => (
              <Table.Row key={contract.contract_id}>
                <Table.Cell>{contract.contract_id}</Table.Cell>
                <Table.Cell>{contract.name}</Table.Cell>
                <Table.Cell>{contract.contract_type}</Table.Cell>
                <Table.Cell>{contract.status}</Table.Cell>
                <Table.Cell>{contract.visibility}/{contract.legality}</Table.Cell>
                <Table.Cell>{contract.payment_amount}</Table.Cell>
                <Table.Cell>{contract.deposit_amount}</Table.Cell>
                <Table.Cell collapsing>
                  <Button icon="handshake" disabled={contract.status !== 'open'} onClick={() => act('accept', { contract_id: contract.contract_id })} />
                  <Button icon="rotate" disabled={contract.status !== 'active'} onClick={() => act('process', { contract_id: contract.contract_id })} />
                  <Button icon="ban" onClick={() => act('cancel', { contract_id: contract.contract_id })} />
                  <Button icon="scale-balanced" onClick={() => act('dispute', { contract_id: contract.contract_id })} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>

        <Section title="Selected Business Accounts">
          <Table>
            {(data.businesses || []).map((business) => (
              <Table.Row key={business.business_id}>
                <Table.Cell>{business.business_id}</Table.Cell>
                <Table.Cell>{business.name}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>

        <Section title="Ledger">
          {(data.ledger || []).slice(-12).map((contract) => (
            <Section key={`${contract.contract_id}-${contract.status}`} title={`${contract.contract_id}: ${contract.name}`} level={2}>
              <LabeledList>
                <LabeledList.Item label="Type">{contract.contract_type}</LabeledList.Item>
                <LabeledList.Item label="Status">{contract.status}</LabeledList.Item>
                <LabeledList.Item label="Payment">{contract.payment_amount}</LabeledList.Item>
              </LabeledList>
              <Box color="label">{contract.event_log?.join(' | ')}</Box>
            </Section>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
