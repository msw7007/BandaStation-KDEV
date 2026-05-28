import { Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type IceCell = {
  index: number;
  value: string;
  row: number;
  column: number;
  selected: boolean;
  hinted: boolean;
};

type IceSequence = {
  values: string[];
  completed: boolean;
  progress: number;
};

type CyberIceHackData = {
  grid_size: number;
  cells: IceCell[];
  sequences: IceSequence[];
  selected_values: string[];
  completed_sequences: string[][];
  alarm_risk: number;
  alarm_chance: number;
  alarm_reduction: number;
  next_axis?: string;
  time_left?: number;
  hacking_skill: number;
  reserve: number;
  max_reserve: number;
  alarm: boolean;
  breached: boolean;
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

export const CyberIceHack = () => {
  const { act, data } = useBackend<CyberIceHackData>();
  const gridSize = Math.max(5, data.grid_size || 5);
  const gridGap = gridSize >= 9 ? 3 : gridSize >= 7 ? 4 : 6;
  const gridFontSize = gridSize >= 9 ? 15 : gridSize >= 7 ? 18 : 24;

  return (
    <Window title="ICE breach" width={820} height={620}>
      <Window.Content
        style={{
          background: cy.bg,
          color: cy.text,
        }}
      >
        <Stack fill>
          <Stack.Item grow>
            <Section
              title="ICE GRID"
              buttons={
                <>
                  <Button color="transparent" icon="check" onClick={() => act('confirm')}>
                    Submit
                  </Button>
                  <Button color="transparent" icon="rotate-left" onClick={() => act('reset')}>
                    Reset
                  </Button>
                </>
              }
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: `repeat(${gridSize}, minmax(0, 1fr))`,
                  gap: `${gridGap}px`,
                  justifyContent: 'center',
                  width: '100%',
                  maxWidth: '100%',
                  padding: '10px',
                }}
              >
                {data.cells.map((cell) => {
                  const isSelected = cell.selected;
                  return (
                    <button
                      key={cell.index}
                      disabled={data.breached}
                      onClick={() => act('select', { index: cell.index })}
                      style={{
                        aspectRatio: '1 / 1',
                        minWidth: 0,
                        minHeight: 0,
                        width: '100%',
                        padding: 0,
                        border: `1px solid ${isSelected ? cy.cyan : cy.cyanSoft}`,
                        background: isSelected
                          ? 'rgba(24, 216, 255, 0.22)'
                          : 'rgba(11, 95, 115, 0.13)',
                        boxShadow: isSelected
                          ? `0 0 10px ${cy.cyanSoft}`
                          : `inset 0 0 8px rgba(24, 216, 255, 0.08)`,
                        color: isSelected ? cy.cyan : cy.text,
                        cursor: data.breached ? 'default' : 'pointer',
                        fontFamily: 'monospace',
                        fontSize: `${gridFontSize}px`,
                        fontWeight: 800,
                        lineHeight: '1',
                        textAlign: 'center',
                      }}
                    >
                      {cell.value}
                    </button>
                  );
                })}
              </div>
            </Section>
          </Stack.Item>

          <Stack.Item width="270px">
            <Section
              title="STATUS"
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <LabeledList>
                <LabeledList.Item label="Запас">
                  {data.reserve}/{data.max_reserve}
                </LabeledList.Item>
                <LabeledList.Item label="Взлом">{data.hacking_skill}</LabeledList.Item>
                <LabeledList.Item label="Срез">
                  <span style={{ color: data.alarm_reduction ? cy.cyan : cy.muted }}>
                    {data.alarm_reduction || 0}%
                  </span>
                </LabeledList.Item>
                <LabeledList.Item label="Риск">
                  <span style={{ color: data.alarm_chance ? cy.red : cy.cyan }}>
                    {data.alarm_chance || 0}%
                  </span>
                </LabeledList.Item>
                <LabeledList.Item label="Next">
                  {data.next_axis || 'initial'}
                </LabeledList.Item>
                <LabeledList.Item label="Timer">
                  {data.time_left === null || data.time_left === undefined
                    ? 'infinite'
                    : `${Math.ceil(data.time_left)}s`}
                </LabeledList.Item>
                <LabeledList.Item label="Alarm">
                  <span style={{ color: data.alarm ? cy.red : cy.cyan }}>
                    {data.alarm ? 'triggered' : 'clear'}
                  </span>
                </LabeledList.Item>
                <LabeledList.Item label="State">
                  <span style={{ color: data.breached ? cy.cyan : cy.text }}>
                    {data.breached ? 'breached' : 'protected'}
                  </span>
                </LabeledList.Item>
              </LabeledList>
            </Section>

            <Section
              title="SEQUENCES"
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <Stack vertical>
                {data.sequences.map((sequence, index) => (
                  <Stack.Item key={index}>
                    <div
                      style={{
                        border: `1px solid ${sequence.completed ? cy.cyan : cy.redDark}`,
                        background: sequence.completed
                          ? 'rgba(24, 216, 255, 0.12)'
                          : 'rgba(5, 8, 13, 0.75)',
                        color: sequence.completed ? cy.cyan : cy.text,
                        padding: '7px',
                        fontFamily: 'monospace',
                        fontSize: '14px',
                        letterSpacing: '0',
                        wordBreak: 'break-word',
                      }}
                    >
                      {sequence.values.map((value, valueIndex) => (
                        <span
                          key={`${index}-${valueIndex}`}
                          style={{
                            color:
                              sequence.completed || valueIndex < sequence.progress
                                ? cy.cyan
                                : cy.text,
                            fontWeight:
                              sequence.completed || valueIndex < sequence.progress
                                ? 800
                                : 500,
                          }}
                        >
                          {value}
                          {valueIndex < sequence.values.length - 1 ? ' -> ' : ''}
                        </span>
                      ))}
                    </div>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>

            <Section
              title="BUFFER"
              style={{
                background: cy.panel,
                border: `1px solid ${cy.redDark}`,
              }}
            >
              <div
                style={{
                  background: cy.panelSoft,
                  border: `1px solid ${cy.cyanSoft}`,
                  color: data.selected_values.length ? cy.cyan : cy.muted,
                  fontFamily: 'monospace',
                  fontSize: '14px',
                  minHeight: '34px',
                  padding: '8px',
                  wordBreak: 'break-word',
                }}
              >
                {data.selected_values.length
                  ? data.selected_values.join(' -> ')
                  : 'No input'}
                {!!data.completed_sequences?.length && (
                  <div
                    style={{
                      borderTop: `1px solid ${cy.cyanSoft}`,
                      color: cy.text,
                      marginTop: '8px',
                      paddingTop: '8px',
                    }}
                  >
                    {data.completed_sequences.map((sequence, index) => (
                      <div key={index} style={{ color: cy.cyan }}>
                        {sequence.join(' -> ')}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
