import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const bin = process.env.BYOND_BIN || resolve(root, '../../bin');
const source = (
  await readFile(join(root, 'code/modules/instruments/songs/_song.dm'), 'utf8')
).replaceAll('\r\n', '\n');

// Run the production procedures against an injected clock and silent sound stubs.
function procedure(header) {
  const start = source.indexOf(`${header}\n`);
  if (start < 0) throw new Error(`Procedure missing: ${header}`);
  const next = source.indexOf('\n/datum/', start + header.length);
  return source
    .slice(start, next < 0 ? undefined : next)
    .replaceAll('world.time', 'test_clock');
}

const harness = `
#define SECONDS * 10
#define PROCESS_KILL 99
#define STOP_PLAYING 1
#define COMSIG_INSTRUMENT_REPEAT "repeat"

var/global/failures = 0

/proc/check(condition, message)
\tif(!condition)
\t\tfailures++
\t\tworld.log << "FAIL: [message]"

/proc/SEND_SIGNAL(datum/source, signal, value)
\treturn

/datum/proc/process(wait)
\treturn

/datum/song
\tvar/playing = TRUE
\tvar/playback_mode = "midi"
\tvar/list/compiled_chords = list()
\tvar/current_chord = 1
\tvar/next_chord_time = 0
\tvar/last_process_time = 0
\tvar/bpm = 120
\tvar/repeat = 0
\tvar/auto_repeat = FALSE
\tvar/parent
\tvar/music_player
\tvar/test_clock = 0
\tvar/end_time = -1
\tvar/list/played = list()
\tvar/decay_calls = 0
\tvar/decay_elapsed = 0
\tproc/should_stop_playing(player)
\t\treturn 0
\tproc/play_chord(list/chord)
\t\tplayed += list(list("time" = test_clock, "key" = chord[1]))
\tproc/stop_playing(finished)
\t\tplaying = FALSE
\t\tend_time = test_clock
\tproc/process_file_playing()
\t\treturn
\tproc/process_sequence()
\t\treturn
\tproc/process_sequence_voices()
\t\treturn
\tproc/process_decay(elapsed)
\t\tdecay_calls++
\t\tdecay_elapsed += elapsed
\tproc/fill(count, division)
\t\tfor(var/i in 1 to count)
\t\t\tcompiled_chords += list(list(i, division))

${procedure('/datum/song/proc/process_song(wait)')}
${procedure('/datum/song/proc/tempodiv_to_delay(tempodiv)')}
${procedure('/datum/song/process(wait)')}

/world/New()
\tvar/datum/song/fraction = new
\tfraction.bpm = 137
\tcheck(abs(fraction.tempodiv_to_delay(3) - 600 / 137 / 3) < 0.0001, "Fractional duration was rounded")
\tfraction.bpm = 1200
\tcheck(abs(fraction.tempodiv_to_delay(8) - 0.0625) < 0.0001, "Short note was clamped to a tick")
\tcheck(fraction.tempodiv_to_delay(0) == 0.5, "Zero division is not sanitized")
\tcheck(fraction.tempodiv_to_delay(-8) == 0.5, "Negative division is not sanitized")

\tvar/datum/song/regular = new
\tregular.fill(100, 4)
\tfor(var/frame in 0 to 250)
\t\tregular.test_clock = frame * 0.5
\t\tregular.process_song(0.5)
\tcheck(length(regular.played) == 100, "Regular playback lost notes")
\tfor(var/i in 1 to length(regular.played))
\t\tvar/list/note = regular.played[i]
\t\tvar/deadline = (i - 1) * 1.25
\t\tcheck(note["time"] >= deadline && note["time"] < deadline + 0.5001, "Regular rhythm drifted at note [i]")
\tcheck(regular.end_time == 125, "Final note duration was cut short")

\tvar/datum/song/stall = new
\tstall.fill(16, 8)
\tstall.process_song(0.5)
\tstall.test_clock = 5
\tstall.process_song(5)
\tcheck(length(stall.played) == 5, "Catch-up exceeded four chords per call")
\tcheck(stall.next_chord_time == 3.125, "Overdue time was discarded")
\tstall.process_song(0)
\tcheck(length(stall.played) == 9 && stall.next_chord_time == 5.625, "Backlog did not resume in order")
\tstall.process_song(0)
\tcheck(length(stall.played) == 9, "A future note played early")

\tvar/datum/song/ending = new
\tending.fill(1, 1)
\tending.process_song(0.5)
\tcheck(ending.playing, "A one-note song stopped immediately")
\tending.test_clock = 4.5
\tending.process_song(0.5)
\tcheck(ending.playing, "Final note stopped before its deadline")
\tending.test_clock = 5
\tending.process_song(0.5)
\tcheck(!ending.playing && ending.end_time == 5, "Final note did not stop on its deadline")

\tvar/datum/song/repeated = new
\trepeated.fill(2, 1)
\trepeated.repeat = 1
\tfor(var/i in 0 to 4)
\t\trepeated.test_clock = i * 5
\t\trepeated.process_song(5)
\tcheck(length(repeated.played) == 4 && !repeated.playing && repeated.end_time == 20, "Repeat timing is incorrect")

\tvar/datum/song/looped = new
\tlooped.fill(2, 1)
\tlooped.auto_repeat = TRUE
\tfor(var/i in 0 to 4)
\t\tlooped.test_clock = i * 5
\t\tlooped.process_song(5)
\tcheck(length(looped.played) == 5 && looped.playing, "Loop stopped or introduced a gap")

\tvar/datum/song/decay = new
\tdecay.fill(100, 4)
\tdecay.last_process_time = 1
\tdecay.test_clock = 6.5
\tdecay.process(0.5)
\tcheck(decay.decay_calls == 1 && decay.decay_elapsed == 5.5, "Decay did not use actual elapsed time exactly once")

\tif(failures)
\t\tworld.log << "NOTES_TIMING_FAILED: [failures]"
\telse
\t\tworld.log << "NOTES_TIMING_OK: 7 cases"
\tshutdown()
`;

const directory = await mkdtemp(join(tmpdir(), 'cp13-notes-timing-'));
const project = join(directory, 'notes_timing.dme');
const log = join(directory, 'test.log');
await writeFile(project, harness);
const compile = spawnSync(join(bin, 'dm.exe'), [project], {
  cwd: directory,
  encoding: 'utf8',
  windowsHide: true,
  timeout: 30000,
});
if (compile.error || compile.status !== 0)
  throw new Error(
    `${compile.error || ''}\n${compile.stdout}\n${compile.stderr}\nHarness: ${directory}`,
  );
if (!process.argv.includes('--run')) {
  console.log(
    `Harness compiled. Use --run to execute isolated timing tests.\nHarness: ${directory}`,
  );
  process.exit(0);
}
const run = spawnSync(
  join(bin, 'DreamDaemon.exe'),
  [
    join(directory, 'notes_timing.dmb'),
    '-invisible',
    '-trusted',
    '-close',
    '-log',
    log,
  ],
  { cwd: directory, encoding: 'utf8', windowsHide: true, timeout: 15000 },
);
const output = await readFile(log, 'utf8').catch(
  () => `${run.stdout || ''}\n${run.stderr || ''}`,
);
// DreamDaemon's intentional shutdown can return nonzero on Windows.
if (
  run.error ||
  !output.includes('NOTES_TIMING_OK:') ||
  output.includes('FAIL:')
)
  throw new Error(
    `${run.error || `Exit: ${run.status}`}\n${output}\nHarness: ${directory}`,
  );
console.log(output.trim());
console.log(`Harness: ${directory}`);
