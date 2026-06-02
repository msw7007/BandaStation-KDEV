// CYBERPUNK BUILD - rebuild and delete before release
import { Box, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type TemporaryInterfaceData = {
  mode?: string;
  title?: string;
  userName?: string;
  status?: string;
};

export const CyberpunkTemporaryInterface = () => {
  const { data } = useBackend<TemporaryInterfaceData>();
  const title = data.title || 'Temporary Interface';
  const isNeurolink = data.mode === 'neurolink';

  return (
    <Window title={title} width={620} height={430}>
      <Window.Content scrollable className="CyberpunkPanel">
        <Section title={title}>
          <Stack>
            <Stack.Item grow>
              <Box className="CyberpunkPanel__Metric">
                <LabeledList>
                  <LabeledList.Item label="User">
                    {data.userName || 'unknown'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Mode">
                    {isNeurolink ? 'Neurolink' : 'Personal computer'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Status">
                    {data.status || 'temporary development entrypoint'}
                  </LabeledList.Item>
                </LabeledList>
              </Box>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title={isNeurolink ? 'Neurolink Bus' : 'PC Shell'}>
          <Box className="CyberpunkPanel__Card">
            <Box className="CyberpunkPanel__Title">
              {isNeurolink ? 'Neural runtime bridge' : 'Local workstation shell'}
            </Box>
            <Box mt={0.5}>
              {isNeurolink
                ? 'Reserved IC entrypoint for memory, cryptokeys, contracts, corp access, and direct implant services.'
                : 'Reserved IC entrypoint for computer-side apps before the PDA, laptop, and neurointerface split is finalized.'}
            </Box>
          </Box>
          <Box className="CyberpunkPanel__Card CyberpunkPanel__Card--red">
            <Box className="CyberpunkPanel__Title">Pending routing</Box>
            <Box mt={0.5} className="CyberpunkPanel__Muted">
              This shell intentionally has no production actions yet. It keeps the IC
              verb path stable while corps, business, and access flows are moved into
              their final interfaces.
            </Box>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
// CYBERPUNK BUILD - rebuild and delete before release
