import { useState } from 'react';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import type { BooleanLike } from 'tgui-core/react';
import '../styles/interfaces/CyberpunkPanel.scss';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Icon,
  Input,
  Knob,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

type InstrumentData = { name: string; id: string };
type LineData = { line_count: number; line_text: string };
type LoadedFileTrack = {
  name: string;
  length?: string | null;
  length_seconds: number;
  selected?: BooleanLike;
};

type Data = {
  using_instrument: string;

  note_shift_min: number;
  note_shift_max: number;
  note_shift: number;
  octaves: number;

  sustain_modes: string[];
  sustain_mode: string;
  sustain_mode_button: string;
  sustain_mode_duration: number;
  sustain_mode_min: number;
  sustain_mode_max: number;
  sustain_indefinitely: BooleanLike;

  instrument_ready: BooleanLike;

  volume: number;
  min_volume: number;
  max_volume: number;
  volume_dropoff_threshold: number;

  playing: BooleanLike;
  max_repeats: number;
  repeat: number;
  midi_start_delay_ticks: number;
  midi_start_pending: BooleanLike;
  auto_repeat: BooleanLike;
  playback_mode: string;
  file_track_name?: string | null;
  file_track_length?: string | null;
  file_track_length_seconds: number;
  can_load_file_tracks: BooleanLike;
  preset_file_tracks: string[];
  loaded_file_tracks: LoadedFileTrack[];

  bpm: number;
  lines: LineData[];

  can_switch_instrument: BooleanLike;
  possible_instruments: InstrumentData[];

  max_line_chars: number;
  max_lines: number;

  group_prepare_pending?: BooleanLike;
  group_prepare_seconds?: number;
};

export function InstrumentEditor220() {
  const [showHelp, setShowHelp] = useState(false);
  const [tab, setTab] = useState<'main' | 'library'>('main');
  return (
    <Window width={560} height={460}>
      <Window.Content scrollable className="CyberpunkPanel">
        <TopBar showHelp={showHelp} setShowHelp={setShowHelp} />
        <Tabs>
          <Tabs.Tab
            icon="music"
            selected={tab === 'main'}
            onClick={() => setTab('main')}
          >
            Instrument
          </Tabs.Tab>
          <Tabs.Tab
            icon="compact-disc"
            selected={tab === 'library'}
            onClick={() => setTab('library')}
          >
            Library
          </Tabs.Tab>
        </Tabs>
        {showHelp && <HelpInline />}
        {tab === 'main' && (
          <>
            <MainPanel />
            <MusicEditor />
          </>
        )}
        {tab === 'library' && <LibraryPanel />}
      </Window.Content>
    </Window>
  );
};

type TopBarProps = {
  showHelp: boolean;
  setShowHelp: (v: boolean) => void;
};

function TopBar(props: TopBarProps) {
  const { act, data } = useBackend<Data>();
  const {
    playing,
    instrument_ready,
    repeat,
    max_repeats,
    auto_repeat,
    midi_start_pending,
    group_prepare_pending,
    group_prepare_seconds,
    lines,
    file_track_name,
    file_track_length,
  } = data;
  const { showHelp, setShowHelp } = props;

  return (
    <Section>
      <Stack align="center" justify="space-between">
        <Stack.Item>
          <Stack align="center">
            <Stack.Item>
              <Button
                icon={playing || midi_start_pending ? 'stop' : group_prepare_pending ? 'clock' : 'play'}
                color={playing || midi_start_pending ? 'average' : group_prepare_pending ? 'yellow' : 'good'}
                onClick={() => act('play_music')}
              >
                {playing || midi_start_pending ? 'Stop' : group_prepare_pending ? 'Prepare' : 'Start'}
              </Button>
            </Stack.Item>
            <Stack.Item ml={1}>
              <Icon
                name={instrument_ready ? 'check-circle' : 'exclamation-triangle'}
                color={instrument_ready ? 'good' : 'bad'}
                mr={0.5}
              />
              {instrument_ready ? 'Ready' : 'Definition Error'}
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack align="center">
            <Stack.Item>
              <Button
                icon={auto_repeat ? 'repeat' : 'rotate-right'}
                color={auto_repeat ? 'good' : 'default'}
                selected={!!auto_repeat}
                onClick={() => act('set_auto_repeat', { enabled: !auto_repeat })}
              >
                {auto_repeat ? 'Loop ON' : 'Loop'}
              </Button>
            </Stack.Item>
            <Stack.Item ml={1}>
              Repeats:
              <NumberInput
                ml={0.5}
                step={1}
                minValue={0}
                maxValue={max_repeats}
                value={repeat}
                onChange={(v) => act('set_repeat_amount', { amount: v })}
              />
            </Stack.Item>
            <Stack.Item ml={1}>
              <Button icon="question" onClick={() => setShowHelp(!showHelp)}>
                Help
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>

      {lines.length === 0 && !file_track_name && (
        <Box mt={1} color="average">
          Load or type a song below to enable playback.
        </Box>
      )}
      {!!file_track_name && (
        <Box mt={1} className="CyberpunkPanel__Muted">
          Loaded file: {file_track_name} ({file_track_length})
        </Box>
      )}
      {!!group_prepare_pending && (
        <Box mt={1} color="average">
          Group invite pending: choose a track and press Prepare ({group_prepare_seconds}s).
        </Box>
      )}
    </Section>
  );
};

const HelpInline = () => {
  const { data } = useBackend<Data>();
  const { max_line_chars, max_lines } = data;

  return (
    <Section fitted>
      <Box mt={0.5} mb={0.5}>
        <b>Help</b>
      </Box>
      <Box>
        Lines are a series of chords separated by commas (,), each chord has notes
        separated by hyphens (-).<br />
        Notes default to natural in octave 3; accidentals/octaves persist:
        <i> C,C4,C,C3</i> → <i>C3,C4,C4,C3</i>.<br />
        Chords: <i>A-C#,Cn-E,E-G#,Gn-B</i>; pause with empty chord: <i>C,E,,C,G</i>.<br />
        Change chord length via <i>/x</i>: <i>C,G/2,E/4</i>. Example:
        <i> E-E4/4,F#/2,G#/8,B/8,E3-E4/4</i>.<br />
        Max line length: {max_line_chars}. Max lines: {max_lines}.
      </Box>
    </Section>
  );
};

const MainPanel = () => {
  return (
    <Section>
      <Stack>
        <Stack.Item grow basis="50%">
          <LeftColumn />
        </Stack.Item>
        <Stack.Item grow basis="50%">
          <RightKnobs />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const LibraryPanel = () => {
  const { act, data } = useBackend<Data>();
  const {
    playing,
    file_track_name,
    file_track_length,
    file_track_length_seconds,
    can_load_file_tracks,
    preset_file_tracks = [],
    loaded_file_tracks = [],
    volume,
    min_volume,
    max_volume,
  } = data;
  const volVal = Math.max(0, Math.min(100, volume));
  const handleVolume = (...args: any[]) => {
    let value: number | undefined;
    if (typeof args[1] === 'number') value = args[1];
    else if (typeof args[0] === 'number') value = args[0];
    else if (args[0]?.target?.value != null) value = Number(args[0].target.value);
    else if (args[0]?.currentTarget?.value != null) value = Number(args[0].currentTarget.value);
    if (typeof value === 'number' && !Number.isNaN(value)) {
      act('set_volume', {
        amount: Math.max(min_volume, Math.min(max_volume, Math.round(value))),
      });
    }
  };
  const commitLength = (value: string) => {
    const seconds = Number(value);
    if (!Number.isNaN(seconds)) {
      act('set_file_track_length', {
        seconds: Math.max(1, Math.min(1800, Math.round(seconds))),
      });
    }
  };

  return (
    <Section title="Track Library">
      <Stack>
        <Stack.Item grow basis="50%">
          <Section title="Loaded Tracks">
            <Button
              fluid
              icon="folder-open"
              disabled={!!playing || !can_load_file_tracks}
              tooltip={
                can_load_file_tracks
                  ? 'Load an OGG file'
                  : 'Requires Music skill 2'
              }
              onClick={() => act('import_file_song')}
            >
              Load OGG
            </Button>
            {loaded_file_tracks.length === 0 ? (
              <Box mt={1} className="CyberpunkPanel__Muted">
                No OGG tracks loaded.
              </Box>
            ) : (
              loaded_file_tracks.map((track) => (
                <Button
                  key={track.name}
                  fluid
                  mb={0.5}
                  mt={0.5}
                  selected={!!track.selected}
                  onClick={() => act('select_loaded_file_track', { track: track.name })}
                >
                  <Box
                    title={track.name}
                    style={{
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {track.name}
                  </Box>
                </Button>
              ))
            )}
            <Box mt={1} className="CyberpunkPanel__Muted">
              Prepared presets: {preset_file_tracks.length || 0}
            </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow basis="50%">
          <Section title="Loaded Track">
            {file_track_name ? (
              <>
                <Box className="CyberpunkPanel__Title">{file_track_name}</Box>
                <Box mt={0.5} className="CyberpunkPanel__Muted">
                  Detected: {file_track_length}
                </Box>
                <Stack align="center" mt={1}>
                  <Stack.Item>Length:</Stack.Item>
                  <Stack.Item>
                    <Input
                      width="5rem"
                      value={`${file_track_length_seconds}`}
                      disabled={!!playing}
                      onBlur={commitLength}
                      onEnter={commitLength}
                    />
                  </Stack.Item>
                  <Stack.Item>sec</Stack.Item>
                </Stack>
              </>
            ) : (
              <Box className="CyberpunkPanel__Muted">
                No OGG loaded.
              </Box>
            )}

            <Stack align="center" mt={1.5}>
              <Stack.Item grow textAlign="center">
                <Knob
                  size={1.8}
                  value={volVal}
                  minValue={0}
                  maxValue={100}
                  step={1}
                  stepPixelSize={6}
                  onChange={handleVolume}
                  onDrag={handleVolume}
                />
                <Box mt={0.3}>
                  Volume <Box as="span" color="label">({volVal}%)</Box>
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const LeftColumn = () => {
  const { act, data } = useBackend<Data>();
  const {
    using_instrument,
    can_switch_instrument,
    possible_instruments = [],
    sustain_modes,
    sustain_mode,
    sustain_indefinitely,
    midi_start_delay_ticks,
  } = data;

  const instrument_id_by_name = (name: string) =>
    possible_instruments.find((i) => i.name === name)?.id;

  return (
    <Section title="Instrument">
      <Box>
        Using:
        <Dropdown
          ml={1}
          width="100%"
          selected={using_instrument}
          disabled={!can_switch_instrument}
          options={possible_instruments.map((i) => i.name)}
          onSelected={(v) =>
            act('change_instrument', {
              new_instrument: instrument_id_by_name(v as string),
            })
          }
        />
      </Box>

      <Box mt={1}>Mode:</Box>
      <Dropdown
        width="100%"
        selected={sustain_mode}
        options={sustain_modes}
        onSelected={(v) => act('set_sustain_mode', { new_mode: v })}
      />
      <Box mt={0.5}>
        <Button
          fluid
          selected={!!sustain_indefinitely}
          onClick={() => act('toggle_sustain_hold_indefinitely')}
        >
          {sustain_indefinitely ? 'Hold last note' : 'No hold'}
        </Button>
      </Box>

      <Stack align="center" mt={1}>
        <Stack.Item className="CyberpunkPanel__Muted">
          MIDI delay:
        </Stack.Item>
        <Stack.Item grow>
          <Input
            width="100%"
            value={`${midi_start_delay_ticks}`}
            onBlur={(value) => act('set_midi_start_delay', { amount: Number(value) })}
            onEnter={(value) => act('set_midi_start_delay', { amount: Number(value) })}
          />
        </Stack.Item>
        <Stack.Item>ticks</Stack.Item>
      </Stack>
    </Section>
  );
};

const RightKnobs = () => {
  const { act, data } = useBackend<Data>();
  const {
    volume, max_volume,
    volume_dropoff_threshold,
    note_shift,
    sustain_mode_duration,
  } = data;

  const VOL_MAX = 100;
  const DROP_MIN = 0;
  const DROP_MAX = 100;
  const PITCH_MIN = -100;
  const PITCH_MAX = 100;
  const SUSTAIN_MIN = 0;
  const SUSTAIN_MAX = 5;

  const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v));
  const r0 = (v: number) => Math.round(v);
  const r1 = (v: number) => Math.round(v * 10) / 10;

  const volVal = clamp(volume, 0, VOL_MAX);
  const dropVal = clamp(volume_dropoff_threshold, DROP_MIN, DROP_MAX);
  const pitchVal = clamp(note_shift, PITCH_MIN, PITCH_MAX);
  const sustainVal = clamp(sustain_mode_duration, SUSTAIN_MIN, SUSTAIN_MAX);

  const volLabel = `${r0(volVal)}%`;
  const dropLabel = `${r0(dropVal)}`;
  const pitchLabel = `${pitchVal > 0 ? '+' : ''}${r0(pitchVal)}`;
  const sustainLabel = `${r1(sustainVal).toFixed(1)}s`;

  // Универсальный адаптер под любые сигнатуры Knob
  const asKnobHandler =
    (cb: (value: number) => void) =>
    // даём тайпинги через any, чтобы не бодаться с разными версиями типов
    (...args: any[]) => {
      // варианты: (value), (event), (event, value)
      let value: number | undefined;

      if (typeof args[1] === 'number') value = args[1];
      else if (typeof args[0] === 'number') value = args[0];
      else if (args[0]?.target?.value != null) value = Number(args[0].target.value);
      else if (args[0]?.currentTarget?.value != null) value = Number(args[0].currentTarget.value);

      if (typeof value === 'number' && !Number.isNaN(value)) cb(value);
    };

  return (
    <Section title="Amp">
      <Stack>
        <Stack.Item grow basis="50%" textAlign="center">
          <Knob
            size={1.8}
            value={volVal}
            minValue={0}
            maxValue={VOL_MAX}
            step={1}
            stepPixelSize={6}
            // поддержим и onChange, и onDrag — что бы ни ожидал Knob
            onChange={asKnobHandler((v) => act('set_volume', { amount: clamp(r0(v), 0, max_volume) }))}
            onDrag={asKnobHandler((v) => act('set_volume', { amount: clamp(r0(v), 0, max_volume) }))}
          />
          <Box mt={0.3}>
            Volume <Box as="span" color="label">({volLabel})</Box>
          </Box>
        </Stack.Item>

        <Stack.Item grow basis="50%" textAlign="center">
          <Knob
            size={1.8}
            value={dropVal}
            minValue={DROP_MIN}
            maxValue={DROP_MAX}
            step={1}
            stepPixelSize={6}
            onChange={asKnobHandler((v) => act('set_dropoff_volume', { amount: r0(v) }))}
            onDrag={asKnobHandler((v) => act('set_dropoff_volume', { amount: r0(v) }))}
          />
          <Box mt={0.3}>
            Dropoff <Box as="span" color="label">({dropLabel})</Box>
          </Box>
        </Stack.Item>
      </Stack>

      <Stack mt={1}>
        <Stack.Item grow basis="50%" textAlign="center">
          <Knob
            size={1.8}
            value={pitchVal}
            minValue={PITCH_MIN}
            maxValue={PITCH_MAX}
            step={1}
            stepPixelSize={6}
            onChange={asKnobHandler((v) => act('set_note_shift', { amount: r0(v) }))}
            onDrag={asKnobHandler((v) => act('set_note_shift', { amount: r0(v) }))}
          />
          <Box mt={0.3}>
            Pitch <Box as="span" color="label">({pitchLabel})</Box>
          </Box>
        </Stack.Item>

        <Stack.Item grow basis="50%" textAlign="center">
          <Knob
            size={1.8}
            value={sustainVal}
            minValue={SUSTAIN_MIN}
            maxValue={SUSTAIN_MAX}
            step={0.1}
            stepPixelSize={5}
            onChange={asKnobHandler((v) => act('edit_sustain_mode', { amount: r1(v) }))}
            onDrag={asKnobHandler((v) => act('edit_sustain_mode', { amount: r1(v) }))}
          />
          <Box mt={0.3}>
            Sustain <Box as="span" color="label">({sustainLabel})</Box>
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MusicEditor = () => {
  const { act, data } = useBackend<Data>();
  const { bpm, lines } = data;

  return (
    <Collapsible open title="Music Editor" icon="pencil">
      <Section>
        <Stack align="center">
          <Stack.Item>
            <Button onClick={() => act('start_new_song')}>Start a New Song</Button>
          </Stack.Item>
          <Stack.Item ml={1}>
            <Button onClick={() => act('import_song')}>Import a Song</Button>
          </Stack.Item>
          <Stack.Item grow />
          <Stack.Item>
            Tempo:
            <Button ml={1} onClick={() => act('tempo_big_step', { tempo_change: 'decrease_speed' })}>--</Button>
            <Button ml={0.5} onClick={() => act('tempo', { tempo_change: 'decrease_speed' })}>-</Button>
            <NumberInput
              ml={0.5}
              step={1}
              minValue={1}
              maxValue={999}
              value={bpm}
              onChange={(v) => act('set_bpm_slider', { amount: v })}
            />
            <Button ml={0.5} onClick={() => act('tempo', { tempo_change: 'increase_speed' })}>+</Button>
            <Button ml={0.5} onClick={() => act('tempo_big_step', { tempo_change: 'increase_speed' })}>++</Button>
          </Stack.Item>
        </Stack>

        <Box mt={1}>
          {lines.map((line, index) => (
            <Box key={index} fontSize="11px" mb={0.5}>
              <Stack align="center">
                <Stack.Item>Line {index}:</Stack.Item>
                <Stack.Item ml={1}>
                  <Button onClick={() => act('modify_line', { line_editing: line.line_count })}>Edit</Button>
                </Stack.Item>
                <Stack.Item ml={1}>
                  <Button color="bad" onClick={() => act('delete_line', { line_deleted: line.line_count })}>X</Button>
                </Stack.Item>
                <Stack.Item grow ml={1}>
                  <Box opacity={0.9}>{line.line_text}</Box>
                </Stack.Item>
              </Stack>
            </Box>
          ))}
        </Box>

        <Box mt={1}>
          <Button icon="plus" onClick={() => act('add_new_line')}>Add Line</Button>
        </Box>
      </Section>
    </Collapsible>
  );
};
