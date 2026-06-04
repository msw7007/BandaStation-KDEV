// CYBERPUNK BUILD - rebuild and delete before release
import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type DialogOption = {
  id: string;
  label: string;
  text: string;
};

type ServiceOption = {
  id: string;
  name: string;
  description: string;
  price: number;
  available: boolean;
  items?: {
    name: string;
    integrity: number;
    maxIntegrity: number;
  }[];
};

type NpcDialogData = {
  npcName: string;
  title: string;
  faction: string;
  greeting: string;
  selectedText: string;
  lastMessage?: string;
  balance: number;
  canTrade: boolean;
  dialogOptions: DialogOption[];
  services: ServiceOption[];
};

export const CyberpunkNpcDialog = () => {
  const { act, data } = useBackend<NpcDialogData>();

  return (
    <Window title={`Talk: ${data.npcName || 'NPC'}`} width={620} height={520}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Contact">
          <Stack>
            <Stack.Item grow className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Title">{data.npcName}</Box>
              <Box className="CyberpunkPanel__Muted">
                {data.title} / {data.faction}
              </Box>
            </Stack.Item>
            <Stack.Item className="CyberpunkPanel__Metric">
              <Box className="CyberpunkPanel__Muted">Balance</Box>
              <Box className="CyberpunkPanel__Title">{data.balance || 0} cr</Box>
            </Stack.Item>
          </Stack>
          {!!data.lastMessage && (
            <Box mt={1} className="CyberpunkPanel__Card">
              {data.lastMessage}
            </Box>
          )}
        </Section>

        <Stack align="stretch">
          <Stack.Item width="38%">
            <Section title="Dialog">
              {data.dialogOptions?.length ? (
                data.dialogOptions.map((option) => (
                  <Button
                    fluid
                    key={option.id}
                    icon="comment"
                    mb={0.5}
                    onClick={() => act('select_dialog', { id: option.id })}
                  >
                    {option.label}
                  </Button>
                ))
              ) : (
                <Box className="CyberpunkPanel__Muted">No dialog topics.</Box>
              )}
              {data.canTrade && (
                <Button
                  fluid
                  icon="cart-shopping"
                  color="cyan"
                  mt={1}
                  onClick={() => act('trade')}
                >
                  Buy / sell
                </Button>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section title="Response">
              <Box className="CyberpunkPanel__Card">
                {data.selectedText || data.greeting || '...'}
              </Box>
            </Section>

            <Section title="Services">
              {data.services?.length ? (
                data.services.map((service) => (
                  <Box key={service.id} className="CyberpunkPanel__Card">
                    <Stack align="center">
                      <Stack.Item grow>
                        <Box className="CyberpunkPanel__Title">
                          {service.name}
                        </Box>
                        <Box className="CyberpunkPanel__Muted">
                          {service.description}
                        </Box>
                        {!!service.items?.length && (
                          <LabeledList mt={1}>
                            {service.items.map((item) => (
                              <LabeledList.Item
                                key={`${item.name}-${item.integrity}`}
                                label={item.name}
                              >
                                {item.integrity}/{item.maxIntegrity}
                              </LabeledList.Item>
                            ))}
                          </LabeledList>
                        )}
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="hand-holding-medical"
                          disabled={!service.available}
                          onClick={() => act('service', { id: service.id })}
                        >
                          {service.price > 0 ? `${service.price} cr` : 'Use'}
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Box>
                ))
              ) : (
                <Box className="CyberpunkPanel__Muted">No services.</Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
