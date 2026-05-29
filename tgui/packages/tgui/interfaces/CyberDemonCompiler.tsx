import { useState } from 'react';
import type { ReactNode } from 'react';

import { Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Demon = {
  index: number;
  id?: string;
  name: string;
  description: string;
  effect: string;
  power: number;
  cast_time: number;
  duration: number;
  specials: string[];
  memory: number;
  manufacturer: string;
  net_data_cost: number;
  psychic_damage: number;
};

type Choice = {
  id: string;
  name: string;
};

type Storage = {
  present: boolean;
  name: string;
  used_memory: number;
  memory_capacity: number;
  free_memory: number;
  cooldown?: number;
  demons: Demon[];
};

type CyberDemonCompilerData = {
  net_data: number;
  catalog: Demon[];
  effects: Choice[];
  specials: Choice[];
  deck: Storage;
  disk: Storage;
  terminal: {
    present: boolean;
    name: string;
    cooldown: number;
  };
  limits: {
    max_specials: number;
    max_custom_memory: number;
    disk_memory: number;
  };
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
  green: '#42d77d',
};

const fieldStyle = {
  width: '100%',
  minHeight: '22px',
  background: cy.panelSoft,
  border: `1px solid ${cy.cyanSoft}`,
  color: cy.text,
  padding: '3px 6px',
};

const labelStyle = {
  color: cy.cyan,
  fontSize: '11px',
  fontWeight: 700,
  marginBottom: '3px',
  textTransform: 'uppercase' as const,
};

const cardStyle = {
  background: 'rgba(5, 8, 13, 0.72)',
  border: `1px solid ${cy.redDark}`,
  marginBottom: '6px',
  padding: '7px',
};

const calcMemory = (power: number, castTime: number, duration: number, specials: string[]) =>
  Math.max(1, Math.min(99, 1 + Math.round(power / 10) + Math.round(castTime / 10) + Math.round(duration / 60) + specials.length));

const clampNumber = (value: string, min: number, max: number, fallback: number) => {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, parsed));
};

export const CyberDemonCompiler = () => {
  const { act, data } = useBackend<CyberDemonCompilerData>();
  const firstEffect = data.effects?.[0]?.id || 'damage';
  const [name, setName] = useState('Custom demon');
  const [effect, setEffect] = useState(firstEffect);
  const [power, setPower] = useState(10);
  const [castTime, setCastTime] = useState(2);
  const [duration, setDuration] = useState(0);
  const [manufacturer, setManufacturer] = useState('Independent');
  const [specials, setSpecials] = useState<string[]>([]);

  const maxSpecials = data.limits?.max_specials || 2;
  const memory = calcMemory(power, castTime, duration, specials);
  const netDataCost = Math.max(1, memory + specials.length);
  const overCustomLimit = memory > (data.limits?.max_custom_memory || 8);
  const deckBusy = !!data.deck?.cooldown;
  const terminalBusy = !!data.terminal?.cooldown;
  const hasCompiler = !!data.deck?.present || !!data.terminal?.present;
  const compileBlocked = overCustomLimit || netDataCost > (data.net_data || 0);
  const deckTargetBlocked = compileBlocked || deckBusy || terminalBusy;
  const diskTargetBlocked = compileBlocked || !hasCompiler || (data.terminal?.present ? terminalBusy : deckBusy);

  const toggleSpecial = (id: string) => {
    if (specials.includes(id)) {
      setSpecials(specials.filter((special) => special !== id));
      return;
    }
    if (specials.length < maxSpecials) {
      setSpecials([...specials, id]);
    }
  };

  const compileCustom = (target: 'deck' | 'disk') =>
    act('compile_custom', {
      target,
      name,
      effect,
      power,
      cast_time: castTime,
      duration,
      manufacturer,
      specials,
    });

  return (
    <Window title="Demon Compiler" width={980} height={660}>
      <Window.Content style={{ background: cy.bg, color: cy.text }}>
        <Stack fill>
          <Stack.Item width="34%">
            <Section title="ASSEMBLE DEMON" style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}>
              <Stack vertical>
                <Stack.Item>
                  <div style={labelStyle}>Name</div>
                  <input value={name} onChange={(event) => setName(event.currentTarget.value)} style={fieldStyle} />
                </Stack.Item>
                <Stack.Item>
                  <div style={labelStyle}>Effect</div>
                  <select value={effect} onChange={(event) => setEffect(event.currentTarget.value)} style={fieldStyle}>
                    {data.effects?.map((choice) => (
                      <option key={choice.id} value={choice.id}>
                        {choice.name}
                      </option>
                    ))}
                  </select>
                </Stack.Item>
                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      <div style={labelStyle}>Power</div>
                      <input
                        type="number"
                        min={1}
                        max={100}
                        value={power}
                        onChange={(event) => setPower(clampNumber(event.currentTarget.value, 1, 100, power))}
                        style={fieldStyle}
                      />
                    </Stack.Item>
                    <Stack.Item grow>
                      <div style={labelStyle}>Cast, sec</div>
                      <input
                        type="number"
                        min={1}
                        max={30}
                        value={castTime}
                        onChange={(event) => setCastTime(clampNumber(event.currentTarget.value, 1, 30, castTime))}
                        style={fieldStyle}
                      />
                    </Stack.Item>
                    <Stack.Item grow>
                      <div style={labelStyle}>Duration, sec</div>
                      <input
                        type="number"
                        min={0}
                        max={300}
                        value={duration}
                        onChange={(event) => setDuration(clampNumber(event.currentTarget.value, 0, 300, duration))}
                        style={fieldStyle}
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <div style={labelStyle}>Manufacturer</div>
                  <input value={manufacturer} onChange={(event) => setManufacturer(event.currentTarget.value)} style={fieldStyle} />
                </Stack.Item>
                <Stack.Item>
                  <div style={labelStyle}>Special effects {specials.length}/{maxSpecials}</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px' }}>
                    {data.specials?.map((choice) => {
                      const selected = specials.includes(choice.id);
                      return (
                        <Button
                          key={choice.id}
                          fluid
                          selected={selected}
                          disabled={!selected && specials.length >= maxSpecials}
                          onClick={() => toggleSpecial(choice.id)}
                        >
                          {choice.name}
                        </Button>
                      );
                    })}
                  </div>
                </Stack.Item>
                <Stack.Item>
                  <div style={{ ...cardStyle, borderColor: overCustomLimit ? cy.red : cy.cyanSoft }}>
                    <b style={{ color: cy.cyan }}>Preview</b>
                    <div>Memory: {memory}/{data.limits?.max_custom_memory || 8}</div>
                    <div>Net-data: {netDataCost}</div>
                    <div>Psychic damage: {2 + Math.round(memory / 3)}</div>
                    <div>Physical world: -10% effect power</div>
                    {overCustomLimit && <div style={{ color: cy.red }}>Custom demon cannot exceed {data.limits?.max_custom_memory || 8} memory.</div>}
                    {netDataCost > (data.net_data || 0) && <div style={{ color: cy.red }}>Not enough net-data.</div>}
                  </div>
                </Stack.Item>
                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      <Button
                        fluid
                        color="green"
                        icon="download"
                        disabled={!data.deck?.present || deckTargetBlocked || memory > (data.deck?.free_memory || 0)}
                        onClick={() => compileCustom('deck')}
                      >
                        Compile to deck
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        fluid
                        color="green"
                        icon="save"
                        disabled={!data.disk?.present || diskTargetBlocked || memory > (data.disk?.free_memory || 0)}
                        onClick={() => compileCustom('disk')}
                      >
                        Compile to disk
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item width="28%">
            <Section title="STOCK DEMONS" style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}>
              <Stack vertical>
                {data.catalog?.map((demon) => (
                  <Stack.Item key={demon.id}>
                    <DemonCard demon={demon}>
                      <Button
                        icon="download"
                        disabled={!data.deck?.present || demon.memory > (data.deck?.free_memory || 0) || demon.net_data_cost > data.net_data || deckBusy || terminalBusy}
                        onClick={() => act('compile_stock', { target: 'deck', id: demon.id })}
                      >
                        Deck
                      </Button>
                      <Button
                        icon="save"
                        disabled={
                          !data.disk?.present ||
                          !hasCompiler ||
                          demon.memory > (data.disk?.free_memory || 0) ||
                          demon.net_data_cost > data.net_data ||
                          (data.terminal?.present ? terminalBusy : deckBusy)
                        }
                        onClick={() => act('compile_stock', { target: 'disk', id: demon.id })}
                      >
                        Disk
                      </Button>
                    </DemonCard>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section title="STORAGE" style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}>
              <div style={labelStyle}>Net-data: {data.net_data || 0}</div>
              {data.terminal?.present && (
                <div style={{ ...cardStyle, borderColor: data.terminal.cooldown ? cy.red : cy.cyanSoft }}>
                  Terminal: {data.terminal.name} {data.terminal.cooldown ? `(${data.terminal.cooldown}s cooldown)` : '(ready)'}
                </div>
              )}
              <StoragePanel
                title="Cyberdeck"
                storage={data.deck}
                emptyText="No cyberdeck found."
                renderActions={(demon) => (
                  <>
                    <Button icon="save" disabled={!data.disk?.present || demon.memory > (data.disk?.free_memory || 0)} onClick={() => act('copy_to_disk', { index: demon.index })}>
                      Copy
                    </Button>
                    <Button icon="trash" color="red" onClick={() => act('delete_deck', { index: demon.index })} />
                  </>
                )}
              />
              <StoragePanel
                title="Demon disk"
                storage={data.disk}
                emptyText="No demon disk found."
                renderActions={(demon) => (
                  <>
                    <Button icon="download" disabled={!data.deck?.present || demon.memory > (data.deck?.free_memory || 0)} onClick={() => act('load_from_disk', { index: demon.index })}>
                      Load
                    </Button>
                    <Button icon="trash" color="red" onClick={() => act('delete_disk', { index: demon.index })} />
                  </>
                )}
              />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const DemonCard = (props: { demon: Demon; children?: ReactNode }) => {
  const { demon, children } = props;
  return (
    <div style={cardStyle}>
      <Stack align="center">
        <Stack.Item grow>
          <div style={{ color: cy.cyan, fontWeight: 800 }}>{demon.name}</div>
          <div style={{ color: cy.muted, fontSize: '11px' }}>{demon.description}</div>
          <div style={{ color: cy.text, fontSize: '11px' }}>
            {demon.effect} | power {demon.power} | {demon.memory} memory | {demon.net_data_cost} data
          </div>
        </Stack.Item>
        {children && <Stack.Item>{children}</Stack.Item>}
      </Stack>
    </div>
  );
};

const StoragePanel = (props: {
  title: string;
  storage: Storage;
  emptyText: string;
  renderActions: (demon: Demon) => ReactNode;
}) => {
  const { title, storage, emptyText, renderActions } = props;
  return (
    <div style={{ marginTop: '8px' }}>
      <div style={labelStyle}>
        {title}: {storage?.present ? `${storage.used_memory}/${storage.memory_capacity}` : emptyText}
      </div>
      {storage?.present && !storage.demons?.length && <div style={{ color: cy.muted, fontStyle: 'italic' }}>Empty.</div>}
      {storage?.present &&
        storage.demons?.map((demon) => (
          <DemonCard key={demon.index} demon={demon}>
            {renderActions(demon)}
          </DemonCard>
        ))}
    </div>
  );
};
