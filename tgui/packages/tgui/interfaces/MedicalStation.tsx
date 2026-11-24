import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  mode: string;
  enabled: boolean;
  patient?: string;
  scanning: boolean;
  report?: string;
  reportName?: string;
  reportTime?: string;
  fuel: number;
};

export const MedicalStation = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Window width={650} height={650}>
      <Window.Content scrollable>
        <Section title="Пациент">
          <LabeledList>
            <LabeledList.Item label="Имя">
              {data.patient || 'Пациент отсутствует'}
            </LabeledList.Item>
            {data.mode === 'cryostasis' && (
              <LabeledList.Item label="Криостилан">
                {data.fuel.toFixed(2)} ед.
              </LabeledList.Item>
            )}
          </LabeledList>
          <Stack mt={1}>
            {data.mode !== 'diagnostic' && (
              <Stack.Item>
                <Button selected={data.enabled} onClick={() => act('toggle')}>
                  {data.enabled ? 'Выключить' : 'Включить'}
                </Button>
              </Stack.Item>
            )}
            <Stack.Item>
              <Button disabled={!data.patient} onClick={() => act('eject')}>
                Освободить пациента
              </Button>
            </Stack.Item>
            {data.mode === 'diagnostic' && (
              <Stack.Item>
                <Button
                  disabled={!data.patient || data.scanning}
                  onClick={() => act('scan')}
                >
                  {data.scanning ? 'Исследование…' : 'Начать исследование'}
                </Button>
              </Stack.Item>
            )}
          </Stack>
        </Section>
        {data.report && (
          <Section title={`${data.reportName} — ${data.reportTime}`}>
            <Button icon="print" onClick={() => act('print')}>
              Печать
            </Button>
            <Button icon="file-medical" onClick={() => act('record')}>
              В медицинскую карту
            </Button>
            <Box mt={1} preserveWhitespace>
              {data.report}
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
