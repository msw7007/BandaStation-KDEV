import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  targets: { id: string; name: string; planet: boolean }[];
  selected: string | null;
  charge: number;
  required: number;
  charging: boolean;
  busy: boolean;
  cooldown: number;
  status: string;
  ready: boolean;
};

export const ShuttleManeuver = () => {
  const { act, data } = useBackend<Data>();
  const target = data.targets.find((site) => site.id === data.selected);
  return (
    <Window width={390} height={310}>
      <Window.Content>
        <Section title="Positioning Drive">
          <ProgressBar
            value={
              data.required > 0 ? Math.min(1, data.charge / data.required) : 0
            }
          >
            {Math.round(data.charge / 1000)} /{' '}
            {Math.round(data.required / 1000)} kJ
          </ProgressBar>
          <Stack mt={1}>
            <Stack.Item grow>
              <Button
                icon="bolt"
                selected={data.charging}
                onClick={() => act('charge')}
              >
                Charging
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="ban"
                disabled={!data.busy}
                onClick={() => act('cancel')}
              >
                Cancel
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Destination">
          <Dropdown
            width="100%"
            selected={data.selected}
            options={data.targets.map((site) => ({
              value: site.id,
              displayText: site.name,
            }))}
            disabled={data.busy}
            onSelected={(id) => act('select', { id })}
          />
          <LabeledList>
            <LabeledList.Item label="Status">{data.status}</LabeledList.Item>
            <LabeledList.Item label="Collision limit">
              {target?.planet ? 'Planetary crash landing' : '20%'}
            </LabeledList.Item>
            <LabeledList.Item label="Cooldown">
              {Math.ceil(data.cooldown)} s
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            <Button
              fluid
              icon="crosshairs"
              disabled={
                !target ||
                !data.ready ||
                data.busy ||
                data.cooldown > 0 ||
                data.charge < data.required
              }
              onClick={() => act('aim')}
            >
              Target Landing
            </Button>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
