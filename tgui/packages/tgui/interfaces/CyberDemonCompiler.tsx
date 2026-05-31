import { useState } from 'react';
import type { ReactNode } from 'react';

import { Button, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Demon = {
  index: number;
  name: string;
  description: string;
  effect: string;
  power: number;
  cast_time: number;
  duration: number;
  activation_delay: number;
  frequency: number;
  stamina_cost: number;
  target_attribute: string;
  target_skill: string;
  specials: string[];
  memory: number;
  manufacturer: string;
  net_data_cost: number;
  psychic_damage: number;
  cooldown: number;
  prebuilt: boolean;
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
  effects: Choice[];
  specials: Choice[];
  manufacturers: string[];
  attributes: Choice[];
  skills: Choice[];
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

const clampNumber = (value: string, min: number, max: number, fallback: number) => {
  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, parsed));
};

const choiceNameById = (choices: Choice[] | undefined, id: string) =>
  choices?.find((choice) => choice.id === id)?.name || choices?.[0]?.name || '';

const choiceIdByName = (choices: Choice[] | undefined, name: string) =>
  choices?.find((choice) => choice.name === name)?.id || choices?.[0]?.id || '';

const calcMemory = (
  power: number,
  castTime: number,
  duration: number,
  activationDelay: number,
  frequency: number,
  specials: string[],
  effect: string,
) => {
  let memory = 1 + Math.round(Math.abs(power) / 10);
  memory += Math.round(duration);
  memory += Math.round(Math.max(0, frequency - 1) * 0.2);
  memory -= Math.round(activationDelay);
  memory -= Math.round(castTime);
  if (['attribute', 'skill', 'move_speed', 'interaction_speed', 'blind', 'deaf', 'silence', 'block_implants', 'block_demons'].includes(effect)) {
    memory += 1;
  }
  for (const special of specials) {
    if (special === 'stealth') {
      memory += 1;
    } else if (special === 'emp_heavy') {
      memory += 3;
    } else {
      memory += 2;
    }
  }
  return Math.max(1, Math.min(99, memory));
};

export const CyberDemonCompiler = () => {
  const { act, data } = useBackend<CyberDemonCompilerData>();
  const firstEffect = data.effects?.[0]?.id || 'burn';
  const firstAttribute = data.attributes?.[0]?.id || 'strength';
  const firstSkill = data.skills?.[0]?.id || '/datum/skill/physical/intelligence/hacking';
  const [name, setName] = useState('Custom demon');
  const [effect, setEffect] = useState(firstEffect);
  const [power, setPower] = useState(10);
  const [staminaCost, setStaminaCost] = useState(10);
  const [duration, setDuration] = useState(0);
  const [frequency, setFrequency] = useState(1);
  const [activationDelay, setActivationDelay] = useState(0);
  const [castTime, setCastTime] = useState(2);
  const [manufacturer, setManufacturer] = useState('Independent');
  const [targetAttribute, setTargetAttribute] = useState(firstAttribute);
  const [targetSkill, setTargetSkill] = useState(firstSkill);
  const [specials, setSpecials] = useState<string[]>([]);

  const maxSpecials = data.limits?.max_specials || 2;
  const manufacturerOptions = data.manufacturers?.length ? data.manufacturers : ['Independent'];
  const effectOptions = data.effects?.map((choice) => choice.name) || [];
  const attributeOptions = data.attributes?.map((choice) => choice.name) || [];
  const skillOptions = data.skills?.map((choice) => choice.name) || [];
  const memory = calcMemory(power, castTime, duration, activationDelay, frequency, specials, effect);
  const netDataCost = Math.max(1, memory + specials.length);
  const overCustomLimit = memory > (data.limits?.max_custom_memory || 8);
  const deckBusy = !!data.deck?.cooldown;
  const terminalBusy = !!data.terminal?.cooldown;
  const hasCompiler = !!data.deck?.present || !!data.terminal?.present;
  const deckTargetBlocked = overCustomLimit || netDataCost > (data.net_data || 0) || deckBusy || terminalBusy;
  const diskTargetBlocked = !hasCompiler || netDataCost > (data.net_data || 0) || (data.terminal?.present ? terminalBusy : deckBusy);

  const toggleSpecial = (id: string) => {
    if (specials.includes(id)) {
      setSpecials(specials.filter((special) => special !== id));
      return;
    }
    if (specials.length < maxSpecials) {
      setSpecials([...specials, id]);
    }
  };

  const loadTemplate = (demon: Demon) => {
    const templateEffect = data.effects?.some((choice) => choice.id === demon.effect) ? demon.effect : firstEffect;
    setName(`${demon.name} copy`);
    setEffect(templateEffect);
    setPower(demon.power);
    setStaminaCost(demon.stamina_cost || 10);
    setDuration(demon.duration || 0);
    setFrequency(demon.frequency || 1);
    setActivationDelay(demon.activation_delay || 0);
    setCastTime(demon.cast_time || 1);
    setManufacturer(demon.manufacturer || 'Independent');
    setTargetAttribute(demon.target_attribute || firstAttribute);
    setTargetSkill(demon.target_skill || firstSkill);
    setSpecials(demon.specials || []);
  };

  const compileCustom = (target: 'deck' | 'disk') =>
    act('compile_custom', {
      target,
      name,
      effect,
      power,
      stamina_cost: staminaCost,
      duration,
      frequency,
      activation_delay: activationDelay,
      cast_time: castTime,
      manufacturer,
      target_attribute: targetAttribute,
      target_skill: targetSkill,
      specials,
    });

  return (
    <Window title="Demon Compiler" width={1040} height={700}>
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
                  <Dropdown
                    options={effectOptions}
                    selected={choiceNameById(data.effects, effect)}
                    onSelected={(value) => setEffect(choiceIdByName(data.effects, value))}
                    width="100%"
                  />
                </Stack.Item>
                {effect === 'attribute' && (
                  <Stack.Item>
                    <div style={labelStyle}>Target attribute</div>
                    <Dropdown
                      options={attributeOptions}
                      selected={choiceNameById(data.attributes, targetAttribute)}
                      onSelected={(value) => setTargetAttribute(choiceIdByName(data.attributes, value))}
                      width="100%"
                    />
                  </Stack.Item>
                )}
                {effect === 'skill' && (
                  <Stack.Item>
                    <div style={labelStyle}>Target skill</div>
                    <Dropdown
                      options={skillOptions}
                      selected={choiceNameById(data.skills, targetSkill)}
                      onSelected={(value) => setTargetSkill(choiceIdByName(data.skills, value))}
                      width="100%"
                    />
                  </Stack.Item>
                )}
                <Stack.Item>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '6px' }}>
                    <NumberField label="Power" value={power} min={-100} max={100} onChange={setPower} />
                    <NumberField label="Stamina cost" value={staminaCost} min={0} max={100} onChange={setStaminaCost} />
                    <NumberField label="Duration, sec" value={duration} min={0} max={300} onChange={setDuration} />
                    <NumberField label="Frequency, /sec" value={frequency} min={1} max={10} onChange={setFrequency} />
                    <NumberField label="Activation, sec" value={activationDelay} min={0} max={120} onChange={setActivationDelay} />
                    <NumberField label="Cast, sec" value={castTime} min={0} max={60} onChange={setCastTime} />
                  </div>
                </Stack.Item>
                <Stack.Item>
                  <div style={labelStyle}>Manufacturer</div>
                  <Dropdown options={manufacturerOptions} selected={manufacturer} onSelected={setManufacturer} searchInput width="100%" />
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
                    <div>Memory: {memory}/{data.limits?.max_custom_memory || 8} deck limit</div>
                    <div>Net-data: {netDataCost}</div>
                    <div>Psychic damage: {2 + Math.round(memory / 3)}</div>
                    <div>Physical world: -10% effect power</div>
                    {overCustomLimit && <div style={{ color: cy.red }}>Too large for deck use. Disk storage is still possible.</div>}
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
                        Save to deck
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
                        Write to disk
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item width="31%">
            <Section title="DISK CONTENTS" style={{ background: cy.panel, border: `1px solid ${cy.redDark}` }}>
              <StorageHeader storage={data.disk} emptyText="No demon disk found." />
              <div style={{ maxHeight: '585px', overflowY: 'auto', paddingRight: '4px' }}>
                {data.disk?.present && !data.disk.demons?.length && <div style={{ color: cy.muted, fontStyle: 'italic' }}>Disk is empty.</div>}
                {data.disk?.present &&
                  data.disk.demons?.map((demon) => (
                    <DemonCard key={demon.index} demon={demon}>
                      <Button icon="copy" onClick={() => loadTemplate(demon)}>
                        Develop copy
                      </Button>
                      <Button
                        icon="download"
                        disabled={!data.deck?.present || demon.memory > (data.deck?.free_memory || 0)}
                        onClick={() => act('load_from_disk', { index: demon.index })}
                      >
                        Deck
                      </Button>
                      <Button icon="trash" color="red" disabled={demon.prebuilt} onClick={() => act('delete_disk', { index: demon.index })} />
                    </DemonCard>
                  ))}
              </div>
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
                    <Button
                      icon="save"
                      disabled={demon.prebuilt || !data.disk?.present || demon.memory > (data.disk?.free_memory || 0)}
                      onClick={() => act('copy_to_disk', { index: demon.index })}
                    >
                      Disk
                    </Button>
                    <Button icon="trash" color="red" disabled={demon.prebuilt} onClick={() => act('delete_deck', { index: demon.index })} />
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

const NumberField = (props: {
  label: string;
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
}) => {
  const { label, value, min, max, onChange } = props;
  return (
    <div>
      <div style={labelStyle}>{label}</div>
      <input
        type="number"
        min={min}
        max={max}
        value={value}
        onChange={(event) => onChange(clampNumber(event.currentTarget.value, min, max, value))}
        style={fieldStyle}
      />
    </div>
  );
};

const DemonCard = (props: { demon: Demon; children?: ReactNode }) => {
  const { demon, children } = props;
  return (
    <div style={cardStyle}>
      <Stack align="center">
        <Stack.Item grow>
          <div style={{ color: cy.cyan, fontWeight: 800 }}>
            {demon.name} {demon.prebuilt ? <span style={{ color: cy.red }}>[prebuilt]</span> : ''}
          </div>
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

const StorageHeader = (props: { storage: Storage; emptyText: string }) => {
  const { storage, emptyText } = props;
  return (
    <div style={labelStyle}>
      {storage?.present ? `${storage.name}: ${storage.used_memory}/${storage.memory_capacity} memory` : emptyText}
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
