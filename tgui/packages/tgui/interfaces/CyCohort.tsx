import { Button, Section, Stack, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CohortEntry = {
  ref: string;
  name: string;
  status?: string;
};

type Data = {
  limit: number;
  count: number;
  members: CohortEntry[];
  candidates: CohortEntry[];
};

export const CyCohort = () => {
  const { act, data } = useBackend<Data>();
  const { limit = 1, count = 0, members = [], candidates = [] } = data;

  return (
    <Window title="Cohort" width={440} height={520}>
      <Window.Content scrollable>
        <Section title={`Members ${count}/${limit}`}>
          <Table>
            {members.map((member) => (
              <Table.Row key={member.ref}>
                <Table.Cell>{member.name}</Table.Cell>
                <Table.Cell collapsing>{member.status}</Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    icon="minus"
                    onClick={() => act('remove', { ref: member.ref })}
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section title="Nearby">
          <Stack vertical>
            {candidates.map((candidate) => (
              <Stack.Item key={candidate.ref}>
                <Button
                  fluid
                  icon="plus"
                  disabled={count >= limit}
                  onClick={() => act('add', { ref: candidate.ref })}
                >
                  {candidate.name}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
