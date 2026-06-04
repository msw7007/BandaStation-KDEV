// CYBERPUNK BUILD - rebuild and delete before release
import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type TradeItem = {
  id: string;
  name: string;
  description: string;
  category: string;
  buyPrice: number;
  sellPrice: number;
  stock: number;
};

type SellableItem = {
  ref: string;
  name: string;
  price: number;
};

type NpcTradeData = {
  npcName: string;
  title: string;
  faction: string;
  lastMessage?: string;
  balance: number;
  items: TradeItem[];
  sellable: SellableItem[];
};

const categoryLabel = (category: string) => {
  const labels = {
    weapons: 'Weapons',
    food: 'Ready food',
    ingredients: 'Ingredients',
    water: 'Water',
    cigarettes: 'Cigarettes',
    toys: 'Toys',
    equipment: 'Equipment',
    implants: 'Implants',
    modules: 'Modules',
    parts: 'Machine parts',
  };
  return labels[category] || category || 'Misc';
};

export const CyberpunkNpcTrade = () => {
  const { act, data } = useBackend<NpcTradeData>();
  const categories = Array.from(
    new Set((data.items || []).map((item) => item.category || 'misc')),
  );

  return (
    <Window title={`Trade: ${data.npcName || 'NPC'}`} width={700} height={620}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title="Trader">
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
            <Stack.Item>
              <Button icon="comments" onClick={() => act('dialog')}>
                Dialog
              </Button>
            </Stack.Item>
          </Stack>
          {!!data.lastMessage && (
            <Box mt={1} className="CyberpunkPanel__Card">
              {data.lastMessage}
            </Box>
          )}
        </Section>

        <Stack align="stretch">
          <Stack.Item grow>
            <Section title="Buy">
              {categories.length ? (
                categories.map((category) => (
                  <Box key={category} mb={1}>
                    <Box className="CyberpunkPanel__Title" mb={0.5}>
                      {categoryLabel(category)}
                    </Box>
                    {(data.items || [])
                      .filter((item) => (item.category || 'misc') === category)
                      .map((item) => (
                        <Box key={item.id} className="CyberpunkPanel__Card">
                          <Stack align="center">
                            <Stack.Item grow>
                              <Box className="CyberpunkPanel__Title">
                                {item.name}
                              </Box>
                              <Box className="CyberpunkPanel__Muted">
                                {item.description}
                              </Box>
                              <Box className="CyberpunkPanel__Small">
                                Stock:{' '}
                                {item.stock < 0 ? 'unlimited' : item.stock}
                              </Box>
                            </Stack.Item>
                            <Stack.Item>
                              <Button
                                icon="cart-plus"
                                disabled={item.stock === 0}
                                onClick={() => act('buy', { id: item.id })}
                              >
                                {item.buyPrice} cr
                              </Button>
                            </Stack.Item>
                          </Stack>
                        </Box>
                      ))}
                  </Box>
                ))
              ) : (
                <Box className="CyberpunkPanel__Muted">No stock.</Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item width="35%">
            <Section title="Sell held items">
              {data.sellable?.length ? (
                data.sellable.map((item) => (
                  <Box key={item.ref} className="CyberpunkPanel__Card">
                    <Box className="CyberpunkPanel__Title">{item.name}</Box>
                    <Button
                      fluid
                      icon="coins"
                      mt={0.5}
                      onClick={() => act('sell', { ref: item.ref })}
                    >
                      Sell for {item.price} cr
                    </Button>
                  </Box>
                ))
              ) : (
                <Box className="CyberpunkPanel__Muted">
                  Hold an item this trader buys.
                </Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
