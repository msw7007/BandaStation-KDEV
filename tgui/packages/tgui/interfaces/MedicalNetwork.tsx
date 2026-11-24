import { Box, Button, Section, Table } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  endpoints: { name: string; patient: string; status: string }[];
  sensors: { name: string; status: string }[];
  events: {
    patient: string;
    author: string;
    action: string;
    device: string;
    time: string;
  }[];
};

export const MedicalNetwork = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Window width={800} height={700}>
      <Window.Content scrollable>
        <Section title="Оборудование">
          <Table>
            {data.endpoints?.map((node, index) => (
              <Table.Row key={index}>
                <Table.Cell>{node.name}</Table.Cell>
                <Table.Cell>{node.patient}</Table.Cell>
                <Table.Cell>{node.status}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
        <Section
          title="Датчики экипажа: уровень 3"
          buttons={
            <Button onClick={() => act('records')}>
              Обновить медицинские карты
            </Button>
          }
        >
          {data.sensors?.map((sensor, index) => (
            <Box key={index}>
              {sensor.name}: {sensor.status}
            </Box>
          ))}
        </Section>
        <Section title="Журнал помощи">
          {data.events
            ?.slice()
            .reverse()
            .map((event, index) => (
              <Box key={index} mb={1}>
                {event.time} — {event.patient}: {event.action}
                <Box color="label">
                  {event.author} · {event.device}
                </Box>
              </Box>
            ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
