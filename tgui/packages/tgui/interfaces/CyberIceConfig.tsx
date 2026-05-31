import { useState } from 'react';

import { Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CyberIceConfigData = {
  missing?: boolean;
  patient_name: string;
  timer: number;
  size: number;
  sequence: number;
  reserve: number;
  total: number;
  level: number;
  chromity_penalty: number;
  effective_chromity: number;
  current_reserve: number;
  max_reserve: number;
  timer_seconds: number;
  grid_size: number;
  sequence_length: number;
};

const cy = {
  bg: '#05080d',
  panel: '#0b141a',
  panelSoft: '#101b22',
  red: '#ff334a',
  redDark: '#4a0b13',
  cyan: '#18d8ff',
  cyanSoft: '#0b5f73',
  text: '#d7e7ee',
  muted: '#78909a',
};

export const CyberIceConfig = () => {
  const { act, data } = useBackend<CyberIceConfigData>();
  const [draft, setDraft] = useState({
    timer: data.timer || 0,
    size: data.size || 0,
    sequence: data.sequence || 0,
    reserve: data.reserve || 0,
  });

  if (data.missing) {
    return (
      <Window title="Neural ICE tuning" width={440} height={240}>
        <Window.Content style={{ background: cy.bg, color: cy.text }}>
          <Section title="NEURAL ICE" style={{ background: cy.panel }}>
            Neural interface is missing.
          </Section>
        </Window.Content>
      </Window>
    );
  }

  const total = draft.timer + draft.size + draft.sequence + draft.reserve;
  const valid = total === data.total;
  const adjust = (key: keyof typeof draft, delta: number) => {
    setDraft({
      ...draft,
      [key]: Math.max(0, draft[key] + delta),
    });
  };

  return (
    <Window title="Neural ICE tuning" width={520} height={470}>
      <Window.Content style={{ background: cy.bg, color: cy.text }}>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title="ICE SUMMARY"
              style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}
            >
              <LabeledList>
                <LabeledList.Item label="Patient">
                  {data.patient_name || 'unknown'}
                </LabeledList.Item>
                <LabeledList.Item label="Points">
                  <span style={{ color: valid ? cy.cyan : cy.red }}>
                    {total}/{data.total}
                  </span>
                </LabeledList.Item>
                <LabeledList.Item label="Level">{data.level}</LabeledList.Item>
                <LabeledList.Item label="Chromity loss">
                  <span style={{ color: cy.red }}>-{data.chromity_penalty}</span>
                </LabeledList.Item>
                <LabeledList.Item label="Effective chromity">
                  {data.effective_chromity}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section
              title="DISTRIBUTION"
              style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}
            >
              <IceRow
                label="Timer"
                value={draft.timer}
                description={`Detection timer: ${Math.round(data.timer_seconds)}s`}
                onMinus={() => adjust('timer', -1)}
                onPlus={() => adjust('timer', 1)}
              />
              <IceRow
                label="Size"
                value={draft.size}
                description={`Grid: ${data.grid_size}x${data.grid_size}`}
                onMinus={() => adjust('size', -1)}
                onPlus={() => adjust('size', 1)}
              />
              <IceRow
                label="Sequence"
                value={draft.sequence}
                description={`Sequence length: ${data.sequence_length}`}
                onMinus={() => adjust('sequence', -1)}
                onPlus={() => adjust('sequence', 1)}
              />
              <IceRow
                label="Reserve"
                value={draft.reserve}
                description={`Reserve: ${data.current_reserve}/${data.max_reserve}`}
                onMinus={() => adjust('reserve', -1)}
                onPlus={() => adjust('reserve', 1)}
              />
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Button
                  fluid
                  color={valid ? 'cyan' : 'red'}
                  disabled={!valid}
                  onClick={() => act('set_distribution', draft)}
                >
                  Apply ICE tuning
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button color="transparent" icon="rotate" onClick={() => act('restore')}>
                  Restore reserve
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const IceRow = (props: {
  label: string;
  value: number;
  description: string;
  onMinus: () => void;
  onPlus: () => void;
}) => (
  <div
    style={{
      display: 'grid',
      gridTemplateColumns: '100px 32px 48px 32px 1fr',
      gap: '6px',
      alignItems: 'center',
      marginBottom: '8px',
      padding: '7px',
      border: `1px solid ${cy.cyanSoft}`,
      background: cy.panelSoft,
    }}
  >
    <div style={{ color: cy.cyan, fontWeight: 800 }}>{props.label}</div>
    <Button icon="minus" onClick={props.onMinus} />
    <div style={{ textAlign: 'center', fontWeight: 800 }}>{props.value}</div>
    <Button icon="plus" onClick={props.onPlus} />
    <div style={{ color: cy.muted }}>{props.description}</div>
  </div>
);
