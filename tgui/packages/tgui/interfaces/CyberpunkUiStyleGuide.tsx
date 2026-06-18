import type { CSSProperties, MouseEvent as ReactMouseEvent, ReactNode } from 'react';
import { useState } from 'react';
import {
  Box,
  Icon,
  Input,
  Knob,
  LabeledList,
  NumberInput,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  CyberPanel,
  CyberSectionHeader,
} from './PreferencesMenu/CharacterSetup/components/CyberPanel';

type UiStyleGuideData = {
  user_name: string;
  build_label: string;
};

type CutButtonTone = 'cyan-dark' | 'cyan-light' | 'red-dark' | 'red-light';

function ElementNumber(props: { value: number }) {
  return <span className="StyleGuide__elementNumber">{props.value}</span>;
}

function CutButton(props: {
  children: ReactNode;
  icon?: string;
  tone: CutButtonTone;
  disabled?: boolean;
  onClick?: () => void;
}) {
  return (
    <button
      className={`StyleGuide__cutButton StyleGuide__cutButton--${props.tone}`}
      disabled={props.disabled}
      onClick={props.onClick}
    >
      {!!props.icon && <Icon name={props.icon} />}
      <span>{props.children}</span>
    </button>
  );
}

function BinarySwitch(props: {
  label: string;
  checked: boolean;
  variant?: 'compact' | 'tabs';
  onClick: () => void;
}) {
  return (
    <button
      className={[
        'StyleGuide__switch',
        props.checked && 'active',
        props.variant === 'tabs' && 'StyleGuide__switch--tabs',
      ]
        .filter(Boolean)
        .join(' ')}
      onClick={props.onClick}
    >
      <span>{props.label}</span>
      <span className="StyleGuide__switchMark" />
    </button>
  );
}

function TextUnderlineSwitch(props: {
  value: string;
  options: [string, string][];
  className?: string;
  onChange: (value: string) => void;
}) {
  return (
    <div
      className={['StyleGuide__textSwitch', props.className]
        .filter(Boolean)
        .join(' ')}
    >
      {props.options.map(([id, label]) => (
        <button
          key={id}
          className={props.value === id ? 'active' : ''}
          onClick={() => props.onChange(id)}
        >
          <span>{label}</span>
        </button>
      ))}
    </div>
  );
}

function StyleGuideDropdown(props: {
  options: string[];
  selected: string;
  onSelected: (value: string) => void;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div
      className="StyleGuide__dropdown"
      onMouseDown={(event) => event.stopPropagation()}
    >
      <button
        type="button"
        className="StyleGuide__dropdownControl"
        onClick={() => setOpen(!open)}
      >
        <span>{props.selected}</span>
        <Icon name={open ? 'angle-up' : 'angle-down'} />
      </button>
      {open && (
        <div className="StyleGuide__dropdownMenu">
          {props.options.map((option) => (
            <button
              key={option}
              type="button"
              className={props.selected === option ? 'selected' : ''}
              onClick={() => {
                props.onSelected(option);
                setOpen(false);
              }}
            >
              {option}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function StyleGuideDropdownStepper(props: {
  options: string[];
  selected: string;
  onSelected: (value: string) => void;
}) {
  const currentIndex = props.options.indexOf(props.selected);
  const step = (direction: -1 | 1) => {
    const safeIndex = currentIndex >= 0 ? currentIndex : 0;
    const nextIndex =
      (safeIndex + direction + props.options.length) % props.options.length;
    props.onSelected(props.options[nextIndex]);
  };

  return (
    <div className="StyleGuide__dropdownStepper">
      <button type="button" onClick={() => step(-1)}>
        -
      </button>
      <StyleGuideDropdown
        options={props.options}
        selected={props.selected}
        onSelected={props.onSelected}
      />
      <button type="button" onClick={() => step(1)}>
        +
      </button>
    </div>
  );
}

function StyleGuideDragField(props: {
  label: string;
  value: number;
  onChange: (value: number) => void;
}) {
  const startDrag = (event: ReactMouseEvent<HTMLDivElement, MouseEvent>) => {
    event.preventDefault();
    event.stopPropagation();

    const rect = event.currentTarget.getBoundingClientRect();
    const updateValue = (clientX: number) => {
      const nextValue = Math.round(((clientX - rect.left) / rect.width) * 100);
      props.onChange(Math.max(0, Math.min(100, nextValue)));
    };
    const onMove = (moveEvent: MouseEvent) => updateValue(moveEvent.clientX);
    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    };

    updateValue(event.clientX);
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  return (
    <div
      className="StyleGuide__dragField"
      onMouseDown={startDrag}
      title="Hold LMB and drag inside the field."
    >
      <div
        className="StyleGuide__dragFieldHandle"
        style={{ left: `${props.value}%` }}
      />
      <div className="StyleGuide__dragFieldContent">
        <span>{props.label}</span>
        <b>{props.value}/100</b>
      </div>
    </div>
  );
}

function ThinProgress(props: {
  value: number;
  label: string;
  text: string;
  hover?: boolean;
}) {
  const track = (
    <div className="StyleGuide__thinProgressTrack">
      <div style={{ width: `${props.value}%` }} />
    </div>
  );

  return (
    <div
      className={[
        'StyleGuide__thinProgress',
        props.hover && 'StyleGuide__thinProgress--hover',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {!props.hover && (
        <div className="StyleGuide__thinProgressMeta">
          <span>{props.label}</span>
          <b>{props.value}/100</b>
        </div>
      )}
      {props.hover ? <Tooltip content={props.text}>{track}</Tooltip> : track}
      {props.hover ? (
        <Tooltip content={props.text}>
          <div className="StyleGuide__trapezoidNote StyleGuide__trapezoidNote--meta">
            <span>{props.label}</span>
            <b>{props.value}/100</b>
          </div>
        </Tooltip>
      ) : (
        <div className="StyleGuide__trapezoidNote">{props.text}</div>
      )}
    </div>
  );
}

function SegmentProgress(props: {
  label: string;
  value: number;
  max: number;
  color?: 'cyan' | 'red';
}) {
  return (
    <div className="StyleGuide__segmentProgress">
      <div className="StyleGuide__thinProgressMeta">
        <span>{props.label}</span>
        <b>
          {props.value}/{props.max}
        </b>
      </div>
      <div
        className="StyleGuide__segments"
        style={{ gridTemplateColumns: `repeat(${props.max}, minmax(0, 1fr))` }}
      >
        {Array.from({ length: props.max }, (_value, index) => (
          <span
            key={index}
            className={[
              index < props.value && 'filled',
              props.color === 'red' && index < props.value && 'warning',
            ]
              .filter(Boolean)
              .join(' ')}
          />
        ))}
      </div>
    </div>
  );
}

function OutputBlock() {
  return (
    <div className="StyleGuide__blockShell StyleGuide__outputShell">
      <LabeledList>
        <LabeledList.Item label="Access">public debug</LabeledList.Item>
        <LabeledList.Item label="Integrity">
          <span className="StyleGuide__stateBad">100%</span>
        </LabeledList.Item>
        <LabeledList.Item label="Connection">
          <span className="StyleGuide__stateGood">linked</span>
        </LabeledList.Item>
      </LabeledList>
      <Table>
        <Table.Row header>
          <Table.Cell>Element</Table.Cell>
          <Table.Cell>Status</Table.Cell>
        </Table.Row>
        {['Button', 'Input', 'Progress', 'Panel'].map((name, index) => (
          <Table.Row key={name} className="candystripe">
            <Table.Cell>{name}</Table.Cell>
            <Table.Cell>{index % 2 ? 'passive' : 'active'}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </div>
  );
}

export const CyberpunkUiStyleGuide = () => {
  const { data } = useBackend<UiStyleGuideData>();
  const [tab, setTab] = useState('controls');
  const [mainSwitch, setMainSwitch] = useState(true);
  const [tabSwitch, setTabSwitch] = useState('medium');
  const [topSwitch, setTopSwitch] = useState('info');
  const [textSwitch, setTextSwitch] = useState('route');
  const [field, setField] = useState('Reference input');
  const [dangerField, setDangerField] = useState('Warning input');
  const [dropdown, setDropdown] = useState('Primary');
  const [numberValue, setNumberValue] = useState(42);
  const [stepperValue, setStepperValue] = useState(18);
  const [knobValue, setKnobValue] = useState(35);
  const [digitalKnobValue, setDigitalKnobValue] = useState(64);
  const [dataCardToggles, setDataCardToggles] = useState<Record<string, boolean>>({
    Cyberdeck: true,
    'Neural Trace': false,
    'Corporate Module': true,
  });
  const dropdownOptions = ['Primary', 'Secondary', 'Disabled', 'Warning'];
  const startDigitalKnobDrag = (
    event: ReactMouseEvent<HTMLDivElement, MouseEvent>,
  ) => {
    event.preventDefault();
    event.stopPropagation();

    const startX = event.clientX;
    const startValue = digitalKnobValue;
    const onMove = (moveEvent: MouseEvent) => {
      const delta = Math.round((moveEvent.clientX - startX) / 2);
      setDigitalKnobValue(Math.max(0, Math.min(100, startValue + delta)));
    };
    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    };

    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  const inputsPanel = (title: string, subtitle: string) => (
    <CyberPanel
      className="StyleGuide__dataInputPanel"
      title={title}
      subtitle={subtitle}
      scrollable
    >
      <CyberSectionHeader>Form controls</CyberSectionHeader>
      <div className="StyleGuide__dataControls">
        <div className="StyleGuide__numberedControl">
          <ElementNumber value={1} />
          <div className="StyleGuide__fieldSample">
            <span>Text input</span>
            <div className="StyleGuide__inputVariants">
              <Input
                className="StyleGuide__textInput StyleGuide__textInput--cyan"
                fluid
                value={field}
                onChange={setField}
              />
              <Input
                className="StyleGuide__textInput StyleGuide__textInput--red"
                fluid
                value={dangerField}
                onChange={setDangerField}
              />
            </div>
          </div>
        </div>

        <div className="StyleGuide__numberedControl">
          <ElementNumber value={2} />
          <div className="StyleGuide__fieldSample">
            <span>Dropdown</span>
            <StyleGuideDropdown
              options={dropdownOptions}
              selected={dropdown}
              onSelected={setDropdown}
            />
          </div>
        </div>

        <div className="StyleGuide__numberedControl">
          <ElementNumber value={3} />
          <div className="StyleGuide__fieldSample">
            <span>Drag numeric</span>
            <StyleGuideDragField
              label="Numeric value"
              value={numberValue}
              onChange={setNumberValue}
            />
          </div>
        </div>

        <div className="StyleGuide__numberedControl">
          <ElementNumber value={4} />
          <div className="StyleGuide__fieldSample">
            <span>Stepper field</span>
            <div className="StyleGuide__stepperField">
              <button
                type="button"
                onClick={() => setStepperValue(Math.max(0, stepperValue - 1))}
              >
                -
              </button>
              <Input
                fluid
                value={String(stepperValue)}
                onChange={(value) => setStepperValue(Number(value) || 0)}
              />
              <button
                type="button"
                onClick={() => setStepperValue(Math.min(100, stepperValue + 1))}
              >
                +
              </button>
            </div>
          </div>
        </div>

        <div className="StyleGuide__numberedControl">
          <ElementNumber value={5} />
          <div className="StyleGuide__fieldSample">
            <span>Dropdown stepper</span>
            <StyleGuideDropdownStepper
              options={dropdownOptions}
              selected={dropdown}
              onSelected={setDropdown}
            />
          </div>
        </div>

        <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
          <ElementNumber value={6} />
          <div className="StyleGuide__fieldSample">
            <span>Color button</span>
            <button type="button" className="StyleGuide__colorButton">
              <i style={{ backgroundColor: '#f02c42' }} />
              <span>Choose color</span>
            </button>
          </div>
        </div>

        <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
          <ElementNumber value={7} />
          <div className="StyleGuide__fieldSample">
            <span>Knobs</span>
            <div
              className="StyleGuide__knobGrid"
              onMouseDown={(event) => event.stopPropagation()}
            >
              <Box textAlign="center">
                <Knob
                  size={2}
                  value={knobValue}
                  minValue={0}
                  maxValue={100}
                  animated={false}
                  onChange={(_event, value) => setKnobValue(value)}
                />
                <Box mt={1}>Amp {knobValue}%</Box>
              </Box>
              <Box
                className="StyleGuide__digitalKnob"
                textAlign="center"
                onMouseDown={startDigitalKnobDrag}
              >
                <div
                  className="StyleGuide__digitalKnobDial"
                  style={
                    {
                      '--sg-knob-value': `${digitalKnobValue}%`,
                    } as CSSProperties
                  }
                >
                  <span />
                </div>
                <div className="StyleGuide__digitalReadout">
                  Digital {digitalKnobValue}
                  <span>%</span>
                </div>
              </Box>
            </div>
          </div>
        </div>
      </div>
    </CyberPanel>
  );

  const wholeBlockPanel = (title: string, subtitle: string) => (
    <CyberPanel
      className="StyleGuide__blockPanel"
      title={title}
      subtitle={subtitle}
    >
      <div className="StyleGuide__blockShell StyleGuide__blockShell--compact">
        <div className="StyleGuide__blockTitle">
          <Icon name="layer-group" />
          <span>Panel composition sample</span>
        </div>
        <div className="StyleGuide__blockMetrics">
          <span>User: {data.user_name || 'Unknown'}</span>
          <span>Layout: column + block</span>
          <span>State: reference</span>
        </div>
        <Box className="StyleGuide__placeholder">
          Whole blocks may stay compact. They do not need to fill the entire
          right column when the following output panel needs its own visual
          weight.
        </Box>
      </div>
    </CyberPanel>
  );

  const statesBlockPanel = (title: string, subtitle: string) => (
    <CyberPanel title={title} subtitle={subtitle}>
      <div className="StyleGuide__blockShell">
        <CyberSectionHeader>Empty and disabled</CyberSectionHeader>
        <Box color="label">No entries found. This is how an empty panel should read.</Box>
        <CutButton icon="ban" tone="cyan-dark" disabled>
          Disabled full-width action
        </CutButton>
        <CyberSectionHeader>Dense rows</CyberSectionHeader>
        {['Cyberdeck', 'Neural Trace', 'Corporate Module'].map((name) => {
          const enabled = dataCardToggles[name];
          return (
            <div
              key={name}
              className={[
                'StyleGuide__dataCard',
                enabled
                  ? 'StyleGuide__dataCard--enabled'
                  : 'StyleGuide__dataCard--disabled',
              ].join(' ')}
            >
              <div>
                <b>{name}</b>
                <span>Compact card with two-line data.</span>
              </div>
              <CutButton
                icon="power-off"
                tone={enabled ? 'cyan-dark' : 'red-dark'}
                onClick={() =>
                  setDataCardToggles((current) => ({
                    ...current,
                    [name]: !enabled,
                  }))
                }
              >
                {enabled ? 'On' : 'Off'}
              </CutButton>
            </div>
          );
        })}
      </div>
    </CyberPanel>
  );

  return (
    <Window title="TGUI Style Guide" width={980} height={760}>
      <Window.Content scrollable>
        <main className="CharacterSetup StyleGuide">
          <header className="CharacterSetup__header StyleGuide__header">
            <div className="CharacterSetup__brand">
              <Icon name="circle-dot" />
              <div>
                <h1>TGUI STYLE GUIDE</h1>
                <span>{data.build_label || 'Cyberpunk UI reference'}</span>
              </div>
            </div>
          </header>

          <div className="StyleGuide__topTabs">
            {[
              ['controls', 'Controls', 'sliders'],
              ['data', 'Data', 'table'],
            ].map(([id, label, icon]) => (
              <button
                key={id}
                className={tab === id ? 'active' : ''}
                onClick={() => setTab(id)}
              >
                <Icon name={icon} />
                <span>{label}</span>
              </button>
            ))}
          </div>

          <div className="StyleGuide__layout">
            {tab === 'controls' && (
              <>
                <CyberPanel
                  className="StyleGuide__leftPanel"
                  title="A. Element Column"
                  subtitle="Buttons, switches and bars"
                  scrollable
                >
                  <CyberSectionHeader>Button tones</CyberSectionHeader>
                  <div className="StyleGuide__buttonGrid">
                    <div className="StyleGuide__numberedControl">
                      <ElementNumber value={1} />
                      <CutButton icon="check" tone="cyan-dark">
                        Confirm off
                      </CutButton>
                    </div>
                    <div className="StyleGuide__numberedControl">
                      <ElementNumber value={2} />
                      <CutButton icon="check" tone="cyan-light">
                        Confirm on
                      </CutButton>
                    </div>
                    <div className="StyleGuide__numberedControl">
                      <ElementNumber value={3} />
                      <CutButton icon="xmark" tone="red-dark">
                        Cancel
                      </CutButton>
                    </div>
                    <div className="StyleGuide__numberedControl">
                      <ElementNumber value={4} />
                      <CutButton icon="power-off" tone="red-light">
                        Shutdown
                      </CutButton>
                    </div>
                  </div>

                  <CyberSectionHeader>Switches</CyberSectionHeader>
                  <Stack vertical>
                    <Stack.Item>
                      <div className="StyleGuide__numberedControl">
                        <ElementNumber value={1} />
                        <BinarySwitch
                          label={mainSwitch ? 'Implant enabled' : 'Implant disabled'}
                          checked={mainSwitch}
                          onClick={() => setMainSwitch(!mainSwitch)}
                        />
                      </div>
                    </Stack.Item>
                    <Stack.Item>
                      <div className="StyleGuide__numberedSwitchRow">
                        <ElementNumber value={2} />
                        <div className="StyleGuide__tabSwitch">
                          {[
                            ['low', 'Low'],
                            ['medium', 'Medium'],
                            ['high', 'High'],
                            ['off', 'Off'],
                          ].map(([id, label]) => (
                            <BinarySwitch
                              key={id}
                              label={label}
                              checked={tabSwitch === id}
                              variant="tabs"
                              onClick={() => setTabSwitch(id)}
                            />
                          ))}
                        </div>
                      </div>
                    </Stack.Item>
                    <Stack.Item>
                      <div className="StyleGuide__numberedSwitchRow">
                        <ElementNumber value={3} />
                        <TextUnderlineSwitch
                          value={textSwitch}
                          onChange={setTextSwitch}
                          options={[
                            ['route', 'Route'],
                            ['signal', 'Signal'],
                            ['memory', 'Memory'],
                          ]}
                        />
                      </div>
                    </Stack.Item>
                    <Stack.Item>
                      <div className="StyleGuide__numberedSwitchRow">
                        <ElementNumber value={5} />
                        <TextUnderlineSwitch
                          value={textSwitch}
                          className="StyleGuide__textSwitch--redInactive"
                          onChange={setTextSwitch}
                          options={[
                            ['route', 'Route'],
                            ['signal', 'Signal'],
                            ['memory', 'Memory'],
                          ]}
                        />
                      </div>
                    </Stack.Item>
                    <Stack.Item>
                      <div className="StyleGuide__numberedSwitchRow">
                        <ElementNumber value={4} />
                        <div className="StyleGuide__topTabSwitch">
                          {[
                            ['info', 'Information', 'user'],
                            ['traits', 'Traits', 'heart'],
                            ['bio', 'Biometrics', 'person-running'],
                            ['gear', 'Equipment', 'briefcase'],
                          ].map(([id, label, icon]) => (
                            <button
                              key={id}
                              className={topSwitch === id ? 'active' : ''}
                              onClick={() => setTopSwitch(id)}
                            >
                              <Icon name={icon} />
                              <span>{label}</span>
                            </button>
                          ))}
                        </div>
                      </div>
                    </Stack.Item>
                  </Stack>

                  <CyberSectionHeader>Thin bars</CyberSectionHeader>
                  <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
                    <ElementNumber value={1} />
                    <ThinProgress
                      label="Experience"
                      value={68}
                      text="Description sits in a trapezoid under the thin fill line."
                    />
                  </div>
                  <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
                    <ElementNumber value={2} />
                    <ThinProgress
                      label="Reservoir"
                      value={31}
                      hover
                      text="This second thin bar keeps only title and value visible. Description appears on hover."
                    />
                  </div>

                  <CyberSectionHeader>Segment bars</CyberSectionHeader>
                  <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
                    <ElementNumber value={3} />
                    <SegmentProgress
                      label="Role priority"
                      value={3}
                      max={5}
                      color="cyan"
                    />
                  </div>
                  <div className="StyleGuide__numberedControl StyleGuide__numberedControl--block">
                    <ElementNumber value={4} />
                    <SegmentProgress
                      label="System risk"
                      value={4}
                      max={6}
                      color="red"
                    />
                  </div>

                  <CyberSectionHeader>Icon buttons</CyberSectionHeader>
                  <div className="StyleGuide__iconButtonGrid">
                    {[
                      ['red', 'wrench'],
                      ['cyan', 'microchip'],
                      ['yellow', 'flask'],
                      ['green', 'leaf'],
                    ].map(([tone, icon]) => (
                      <button
                        key={tone}
                        className={`StyleGuide__iconButton StyleGuide__iconButton--${tone}`}
                        type="button"
                      >
                        <Icon name={icon} />
                      </button>
                    ))}
                  </div>
                  <div className="StyleGuide__iconButtonRowCompact">
                    {[
                      ['red', 'trash'],
                      ['cyan', 'bolt'],
                    ].map(([tone, icon]) => (
                      <button
                        key={tone}
                        className={`StyleGuide__iconButton StyleGuide__iconButton--${tone} StyleGuide__iconButton--compact`}
                        type="button"
                      >
                        <Icon name={icon} />
                      </button>
                    ))}
                  </div>
                  <div className="StyleGuide__iconButtonGrid StyleGuide__iconButtonGrid--large">
                    {[
                      ['red', 'wrench'],
                      ['cyan', 'microchip'],
                      ['yellow', 'flask'],
                      ['green', 'leaf'],
                    ].map(([tone, icon]) => (
                      <button
                        key={tone}
                        className={`StyleGuide__iconButton StyleGuide__iconButton--large StyleGuide__iconButton--${tone}`}
                        type="button"
                      >
                        <Icon name={icon} />
                      </button>
                    ))}
                  </div>
                  <div className="StyleGuide__iconButtonRowCompact StyleGuide__iconButtonRowCompact--large">
                    {[
                      ['red', 'trash'],
                      ['cyan', 'bolt'],
                    ].map(([tone, icon]) => (
                      <button
                        key={tone}
                        className={`StyleGuide__iconButton StyleGuide__iconButton--large StyleGuide__iconButton--compact StyleGuide__iconButton--${tone}`}
                        type="button"
                      >
                        <Icon name={icon} />
                      </button>
                    ))}
                  </div>
                </CyberPanel>

                <div className="StyleGuide__rightStack">
                  {inputsPanel('B. Inputs', 'Restored field samples')}

                  <CyberPanel
                    className="StyleGuide__blockPanel"
                    title="C. Output"
                    subtitle="Data and table output"
                  >
                    <OutputBlock />
                  </CyberPanel>
                </div>
              </>
            )}

            {tab === 'data' && (
              <>
                {wholeBlockPanel('A. Whole Block', 'Large container, spacing and field samples')}
                {statesBlockPanel('B. States', 'Empty state, disabled action and dense rows')}
              </>
            )}
          </div>
        </main>
      </Window.Content>
    </Window>
  );
};
